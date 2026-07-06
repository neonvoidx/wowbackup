-- Overachiever2: Scanner
-- Logic for matching game objects (Items, NPCs) to achievement criteria

local _, ns = ...

-- Helper to get the ID from a GUID
function ns.GetIDFromGUID(guid)
    if not guid then return end
    local unitType, _, _, _, _, id = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        return tonumber(id)
    end
end

-- Resolve DB entries into grouped achievement matches.
-- entries: list of {achID, criteriaID, orderIndex} from the prebuilt DB
-- fallbackName: display name to use when criteria name can't be resolved
local function ResolveAchievements(entries, fallbackName)
    local matches = {}
    for _, entry in ipairs(entries) do
        local achID, criteriaID, orderIndex = entry[1], entry[2], entry[3]

        -- Find or create the match entry for this achievement
        local match
        for _, m in ipairs(matches) do
            if m.achID == achID then
                match = m
                break
            end
        end
        if not match then
            local _, achName, _, achCompleted = ns.GetAchievementInfo(achID)
            if achName then
                match = {
                    achID = achID,
                    achName = achName,
                    achCompleted = achCompleted,
                    criteria = {},
                }
                table.insert(matches, match)
            end
        end

        if match then
            -- Get criteria-specific completion via criteriaID
            local criteriaString, _, critCompleted = ns.GetAchievementCriteriaInfoByID(achID, criteriaID)
            -- Fallback to orderIndex-based lookup for localized name
            -- We skip this fallback if there's only one criteria because it must not be listed in the criteria section
            -- in the achievement item. So `GetAchievementCriteriaInfo` is very likely to return the achievement title.
            local numCriteria = ns.GetAchievementNumCriteria(achID)
            if (not criteriaString or criteriaString == "") and (numCriteria and numCriteria > 1) and orderIndex then
                local tempCritCompleted;
                criteriaString, _, tempCritCompleted = ns.GetAchievementCriteriaInfo(achID, orderIndex)
                -- Overwrite `critCompleted` only when the call succeeded
                if criteriaString then
                    critCompleted = tempCritCompleted
                end
            end
            -- Fallback to provided name if nothing worked
            if (not criteriaString or criteriaString == "") and fallbackName then
                criteriaString = fallbackName
            end
            table.insert(match.criteria, {
                criteriaID = criteriaID,
                criteriaString = criteriaString,
                criteriaCompleted = critCompleted,
            })
        end
    end
    return matches
end

-- Public API: Find achievements related to an Item
function ns.GetItemAchievements(itemID, itemName)
    if not itemID then return {} end
    local entries = ns.DB.Item[itemID]
    if not entries then return {} end
    return ResolveAchievements(entries, itemName)
end

-- Public API: Find achievements related to a Unit (NPC)
function ns.GetUnitAchievements(unit, unitName)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok then return {} end
    local npcID = ns.GetIDFromGUID(guid)
    if not npcID then return {} end
    local entries = ns.DB.Npc[npcID]
    if not entries then return {} end
    return ResolveAchievements(entries, unitName)
end
