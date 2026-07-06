-- Overachiever2: Search Engine Test
-- Run these commands in-game to test the search functionality
-- This file is for testing only and can be deleted in production

--[[

QUICK START TESTS:
==================

1. Test basic search by name:
   /run Overachiever2_TestSearch_ByName("realm first")

2. Test search by ID:
   /run Overachiever2_TestSearch_ByID(457)

3. Test full search (like the Search tab will use):
   /run Overachiever2_TestSearch_Full("reputation", "exalted")

4. Test achievement list generation:
   /run Overachiever2_TestSearch_Lists()

5. Test multi-field search:
   /run Overachiever2_TestSearch_MultiField("heroic")

6. Test description search:
   /run Overachiever2_TestSearch_Description("glory")

7. Test performance (scan all achievements):
   /run Overachiever2_TestSearch_Performance()

--]]

local OA2 = Overachiever2

-- Helper function to print colored results
local function PrintResult(msg, color)
    color = color or "00ff00"
    print("|cff" .. color .. msg .. "|r")
end

-- Test 1: Search by name
function Overachiever2_TestSearch_ByName(query)
    PrintResult("=== Testing Search by Name: '" .. query .. "' ===", "ffff00")

    local start = debugprofilestop()
    local list = OA2.GetAllAchievementIDs()
    local results = OA2.SearchAchievementByNameOrID(list, query, false)
    local elapsed = debugprofilestop() - start

    PrintResult(string.format("Found %d achievements in %.2fms", #results, elapsed))

    for i = 1, math.min(10, #results) do
        local id, name = GetAchievementInfo(results[i])
        print(string.format("  [%d] %s", id, name))
    end

    if #results > 10 then
        PrintResult(string.format("  ... and %d more", #results - 10), "888888")
    end
end

-- Test 2: Search by ID
function Overachiever2_TestSearch_ByID(id)
    PrintResult("=== Testing Search by ID: " .. id .. " ===", "ffff00")

    local achID, name, points, completed, month, day, year, description, flags, icon, rewardText = GetAchievementInfo(id)

    if achID then
        print(string.format("  ID: %d", achID))
        print(string.format("  Name: %s", name))
        print(string.format("  Points: %d", points))
        print(string.format("  Completed: %s", tostring(completed)))
        print(string.format("  Description: %s", description))
        if rewardText and rewardText ~= "" then
            print(string.format("  Reward: %s", rewardText))
        end
    else
        PrintResult("  Achievement not found!", "ff0000")
    end
end

-- Test 3: Full search (all fields)
function Overachiever2_TestSearch_Full(nameQuery, descQuery)
    PrintResult("=== Testing Full Search ===", "ffff00")
    PrintResult(string.format("  Name: '%s'", nameQuery or ""), "ffffff")
    PrintResult(string.format("  Description: '%s'", descQuery or ""), "ffffff")

    local start = debugprofilestop()

    OA2.StartFullSearch(
        false,              -- excludeHidden
        nil,                -- achType (nil = all)
        false,              -- strictCase
        nameQuery or "",    -- nameOrID
        descQuery or "",    -- desc
        "",                 -- criteria
        "",                 -- reward
        "",                 -- any
        function(results)
            local elapsed = debugprofilestop() - start
            PrintResult(string.format("Found %d achievements in %.2fms", #results, elapsed))

            for i = 1, math.min(10, #results) do
                local id, name = GetAchievementInfo(results[i])
                print(string.format("  [%d] %s", id, name))
            end

            if #results > 10 then
                PrintResult(string.format("  ... and %d more", #results - 10), "888888")
            end
        end
    )
end

-- Test 4: Achievement lists
function Overachiever2_TestSearch_Lists()
    PrintResult("=== Testing Achievement List Generation ===", "ffff00")

    local start = debugprofilestop()

    local all = OA2.GetAllAchievementIDs()
    local t1 = debugprofilestop() - start

    local personal = OA2.GetPersonalAchievementIDs()
    local t2 = debugprofilestop() - start - t1

    local guild = OA2.GetGuildAchievementIDs()
    local t3 = debugprofilestop() - start - t1 - t2

    local standard = OA2.GetStandardAchievementIDs()
    local t4 = debugprofilestop() - start - t1 - t2 - t3

    print(string.format("  All Achievements: %d (%.2fms)", #all, t1))
    print(string.format("  Personal: %d (%.2fms)", #personal, t2))
    print(string.format("  Guild: %d (%.2fms)", #guild, t3))
    print(string.format("  Standard: %d (%.2fms)", #standard, t4))

    PrintResult(string.format("Total time: %.2fms", debugprofilestop() - start))

    -- Show first 5 from each list
    PrintResult("\nFirst 5 achievements:", "ffffff")
    for i = 1, math.min(5, #all) do
        local id, name = GetAchievementInfo(all[i])
        print(string.format("  [%d] %s", id, name))
    end
end

-- Test 5: Multi-field search
function Overachiever2_TestSearch_MultiField(query)
    PrintResult("=== Testing Multi-Field Search: '" .. query .. "' ===", "ffff00")
    PrintResult("(Searches name, description, reward, and criteria)", "ffffff")

    local start = debugprofilestop()
    local list = OA2.GetAllAchievementIDs()

    OA2.SearchMultiField(list, query, false, function(results)
        local elapsed = debugprofilestop() - start
        PrintResult(string.format("Found %d achievements in %.2fms", #results, elapsed))

        for i = 1, math.min(10, #results) do
            local id, name = GetAchievementInfo(results[i])
            print(string.format("  [%d] %s", id, name))
        end

        if #results > 10 then
            PrintResult(string.format("  ... and %d more", #results - 10), "888888")
        end
    end)
end

-- Test 6: Description search
function Overachiever2_TestSearch_Description(query)
    PrintResult("=== Testing Description Search: '" .. query .. "' ===", "ffff00")

    local start = debugprofilestop()
    local list = OA2.GetAllAchievementIDs()
    local results = OA2.SearchAchievementField(list, 8, query, false) -- 8 = description
    local elapsed = debugprofilestop() - start

    PrintResult(string.format("Found %d achievements in %.2fms", #results, elapsed))

    for i = 1, math.min(10, #results) do
        local id, name, points, completed, month, day, year, description = GetAchievementInfo(results[i])
        print(string.format("  [%d] %s", id, name))
        print(string.format("      %s", description))
    end

    if #results > 10 then
        PrintResult(string.format("  ... and %d more", #results - 10), "888888")
    end
end

-- Test 7: Performance test
function Overachiever2_TestSearch_Performance()
    PrintResult("=== Performance Test ===", "ffff00")
    PrintResult("Generating achievement lists...", "ffffff")

    -- Clear cache to test fresh generation
    OA2.ClearAchievementListCache()

    local start = debugprofilestop()
    local all = OA2.GetAllAchievementIDs()
    local genTime = debugprofilestop() - start

    PrintResult(string.format("Generated %d achievements in %.2fms", #all, genTime))

    -- Test cached access
    start = debugprofilestop()
    all = OA2.GetAllAchievementIDs()
    local cacheTime = debugprofilestop() - start

    PrintResult(string.format("Cached access: %.2fms (%.1fx faster)", cacheTime, genTime / cacheTime))

    -- Test simple search
    start = debugprofilestop()
    local results = OA2.SearchAchievementByNameOrID(all, "glory", false)
    local searchTime = debugprofilestop() - start

    PrintResult(string.format("Name search 'glory': %d results in %.2fms", #results, searchTime))

    -- Test criteria search (most expensive)
    start = debugprofilestop()
    results = OA2.SearchAchievementCriteria(all, "exalted", false)
    local critTime = debugprofilestop() - start

    PrintResult(string.format("Criteria search 'exalted': %d results in %.2fms", #results, critTime))
end

-- print("|cff00ff00Overachiever2 Search Engine Test Loaded!|r")
-- print("Type |cffffffff/run Overachiever2_TestSearch_Lists()|r to test")
