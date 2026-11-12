local _, addon = ...
local F = {}

-- Forever class talent trees. Group names and icons come from the client.
F.trees = { [1] = 1117, [2] = 1100, [3] = 1091, [4] = 1111, [5] = 1114, [7] = 1082, [8] = 1112, [9] = 1116, [11] = 1089 }

function F.Plain(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

function addon.functions.GetForeverTalentGroups(classID)
	local treeID = F.trees[classID]
	if not treeID or not (C_Traits and C_Traits.GetGroupDisplayInfoByTreeID) then return {} end
	return C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {}
end

function addon.functions.GetForeverPrimaryTalentGroup()
	if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo and C_Traits.GetGroupCurrencyInfo) then return nil end
	local classID = F.Plain(select(3, UnitClass("player")))
	local treeID = classID and F.trees[classID]
	local configID = F.Plain(C_ClassTalents.GetActiveConfigID())
	if not treeID or not configID then return nil end
	if C_Traits.ConfigHasStagedChanges and F.Plain(C_Traits.ConfigHasStagedChanges(configID)) ~= false then return nil end
	if F.cache and F.cache.configID == configID and F.cache.treeID == treeID then return F.cache.groupID end
	local config = C_Traits.GetConfigInfo(configID)
	if not config then return nil end
	local matchesTree = false
	for _, id in ipairs(config.treeIDs or {}) do
		if F.Plain(id) == treeID then matchesTree = true end
	end
	if not matchesTree then return nil end
	local groups, points = {}, {}
	for _, info in ipairs(addon.functions.GetForeverTalentGroups(classID)) do
		local id = F.Plain(info.groupID)
		if not id then return nil end
		groups[#groups + 1], points[id] = id, 0
	end
	if #groups ~= 3 then return nil end
	local infos = C_Traits.GetGroupCurrencyInfo(configID, groups)
	if type(infos) ~= "table" then return nil end
	-- The API omits groups with no spent points.
	for _, info in ipairs(infos) do
		local id = F.Plain(info.traitNodeGroupID)
		if not id or points[id] == nil then return nil end
		local currency = info.currencyInfos and info.currencyInfos[1]
		if not currency then return nil end
		local spent = F.Plain(currency.spent)
		if type(spent) ~= "number" or spent < 0 then return nil end
		points[id] = spent
	end
	local best, bestPoints, tied = nil, 0, false
	for _, id in ipairs(groups) do
		if points[id] > bestPoints then
			best, bestPoints, tied = id, points[id], false
		elseif points[id] == bestPoints then
			tied = true
		end
	end
	if tied then best = nil end
	F.cache = { configID = configID, treeID = treeID, groupID = best }
	return best
end

F.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "SPELLS_CHANGED" }) do
	F.events:RegisterEvent(event)
end
F.events:SetScript("OnEvent", function() F.cache = nil end)
