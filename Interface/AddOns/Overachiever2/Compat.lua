-- Overachiever2: Compatibility Layer

local _, ns = ...

local Utils = Overachiever2.Utils

-- Modern API aliases
ns.GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

-- Safe wrapper for GetAchievementInfo that doesn't throw errors
-- tonumber() strips "secret number" taint wrappers (WoW 12.0+).
ns.GetAchievementInfo = function(id)
    local ok, achID, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = pcall(GetAchievementInfo, id)
    if ok then
        return achID, name, tonumber(points), completed, tonumber(month), tonumber(day), tonumber(year), description, tonumber(flags), icon, rewardText, isGuild, wasEarnedByMe, earnedBy
    end
    if Utils.IsDebugMode() then
        print(Utils.RedText("OA2: GetAchievementInfo failed:") .. " achID=" .. tostring(id))
    end
    return nil
end

-- Safe wrapper for GetAchievementNumCriteria that doesn't throw errors
ns.GetAchievementNumCriteria = function(id)
    local ok, numCriteria = pcall(GetAchievementNumCriteria, id)
    if ok then
        return tonumber(numCriteria)
    end
    if Utils.IsDebugMode() then
        print(Utils.RedText("OA2: GetAchievementNumCriteria failed:") .. " achID=" .. tostring(id))
    end
    return 0
end

-- Safe wrapper for GetAchievementCriteriaInfo that doesn't throw errors
-- tonumber() strips "secret number" taint wrappers (WoW 12.0+) to prevent
-- LayoutFrame comparison errors when values are passed to tooltip widgets.
ns.GetAchievementCriteriaInfo = function(achievementID, index)
    local ok, criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString = pcall(GetAchievementCriteriaInfo, achievementID, index)
    if ok then
        return criteriaString, tonumber(criteriaType), completed, tonumber(quantity), tonumber(reqQuantity), charName, tonumber(flags), tonumber(assetID), quantityString
    end
    if Utils.IsDebugMode() then
        print(Utils.RedText("OA2: GetAchievementCriteriaInfo failed:") .. " achID=" .. tostring(achievementID) .. ", index=" .. tostring(index))
    end
    return nil
end

-- Safe wrapper for GetAchievementCriteriaInfoByID that doesn't throw errors
ns.GetAchievementCriteriaInfoByID = function(achievementID, criteriaID)
    local ok, criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString = pcall(GetAchievementCriteriaInfoByID, achievementID, criteriaID)
    if ok then
        return criteriaString, tonumber(criteriaType), completed, tonumber(quantity), tonumber(reqQuantity), charName, tonumber(flags), tonumber(assetID), quantityString
    end
    if Utils.IsDebugMode() then
        print(Utils.RedText("OA2: GetAchievementCriteriaInfoByID failed:") .. " achID=" .. tostring(achievementID) .. ", critID=" .. tostring(criteriaID))
    end
    return nil
end
