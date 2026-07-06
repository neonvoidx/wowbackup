-- Overachiever2: DBNpc Verification Test
-- Tests that all NPC -> Achievement/Criteria entries in DBNpc.lua are valid.
-- Run in-game: /run Overachiever2_TestDBNpc()

local _, ns = ...

function Overachiever2_TestDBNpc()
    local db = ns.DB and ns.DB.Npc
    if not db then
        print("|cffff0000ERROR: ns.DB.Npc not loaded. Make sure DBNpc.lua is loaded first.|r")
        return
    end

    local totalNpcs = 0
    local totalEntries = 0
    local failedEntries = 0
    local failedList = {}

    for npcID, entries in pairs(db) do
        totalNpcs = totalNpcs + 1
        for _, entry in ipairs(entries) do
            totalEntries = totalEntries + 1
            local achID = entry[1]
            local criteriaID = entry[2]

            local name = GetAchievementCriteriaInfoByID(achID, criteriaID)
            if not name or name == "" then
                failedEntries = failedEntries + 1
                if #failedList < 20 then
                    table.insert(failedList, string.format(
                        "  NPC %d: achID=%d, criteriaID=%d", npcID, achID, criteriaID
                    ))
                end
            end
        end
    end

    print("|cffffffff=== DBNpc Verification Results ===|r")
    print(string.format("  Total NPCs: %d", totalNpcs))
    print(string.format("  Total entries: %d", totalEntries))

    if failedEntries == 0 then
        print("|cff00ff00  All entries returned valid names.|r")
    else
        print(string.format("|cffff0000  Failed entries: %d|r", failedEntries))
        print("|cffff0000  First failures:|r")
        for _, line in ipairs(failedList) do
            print("|cffff8800" .. line .. "|r")
        end
        if failedEntries > #failedList then
            print(string.format("|cffff8800  ... and %d more|r", failedEntries - #failedList))
        end
    end
end