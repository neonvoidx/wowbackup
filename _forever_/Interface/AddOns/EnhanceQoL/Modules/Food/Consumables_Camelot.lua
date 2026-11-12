local addon = _G.EnhanceQoL or select(2, ...)
local C = addon.ForeverConsumables

local function isSecret(value) return issecretvalue and issecretvalue(value) end

local function number(value, fallback)
	if isSecret(value) then return fallback or 0 end
	return tonumber(value) or fallback or 0
end

C.byID = {}
C.bandages = {}
for _, entry in ipairs(C.items) do
	C.byID[entry.id] = entry
	if entry.category == "bandage" then C.bandages[#C.bandages + 1] = entry end
end

-- Item IDs and restoration data are local; only carried item data needs loading.
C.requestedItems = {}
function C.GetCount(entry)
	local id = type(entry) == "table" and entry.id or entry
	return number(addon.functions.getFoodBagItemCount(id))
end

function C.RequestOwnedItemData(entry)
	if C.requestedItems[entry.id] or not C_Item or not C_Item.RequestLoadItemDataByID then return end
	C.requestedItems[entry.id] = true
	if not C_Item.IsItemDataCachedByID or not C_Item.IsItemDataCachedByID(entry.id) then C_Item.RequestLoadItemDataByID(entry.id) end
end

function C.IsEligible(entry)
	if not entry then return false end
	local level = UnitLevel("player")
	if isSecret(level) or type(level) ~= "number" then return false end
	if (entry.requiredLevel or 0) > level then return false end
	if entry.requiredSkill then
		local skill = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID and C_SkillInfo.GetSkillLineInfoByID(entry.requiredSkill)
		if isSecret(skill) or type(skill) ~= "table" then return false end
		local rank = skill.rank
		if isSecret(rank) or type(rank) ~= "number" or rank < (entry.requiredSkillRank or 0) then return false end
	end
	return true
end

function C.GetRecovery(entry, resource)
	if not entry then return 0 end
	local value = entry[resource] or 0
	local percent = entry[resource .. "Percent"] or 0
	if percent > 0 then
		local maximum
		if resource == "health" then
			maximum = UnitHealthMax("player")
		else
			maximum = UnitPowerMax("player", 0)
		end
		value = value + number(maximum) * percent / 100
	end
	return value
end

function C.Matches(entry, group)
	local category = entry.category
	if group == "food" then return category == "food" or category == "food_and_drink" end
	if group == "drink" then return category == "drink" or category == "food_and_drink" end
	if group == "mana" then return category == "mana_potion" or category == "healing_and_mana_potion" or category == "mana_gem" end
	return category == group
end

function C.GetCooldown(entry)
	if not C_Item or not C_Item.GetItemCooldown then return 0 end
	local start, duration, enabled = C_Item.GetItemCooldown(entry.id)
	if isSecret(start) or isSecret(duration) or isSecret(enabled) then return math.huge end
	if enabled == 0 then return math.huge end
	start, duration = number(start), number(duration)
	if start <= 0 or duration <= 0 then return 0 end
	return math.max(0, start + duration - GetTime())
end

function C.IsBetter(entry, current, resource, preferMage, remaining, currentRemaining)
	if not current then return true end
	if remaining ~= currentRemaining then return remaining < currentRemaining end
	if preferMage and (entry.isMageFood == true) ~= (current.isMageFood == true) then return entry.isMageFood == true end
	local value, previous = C.GetRecovery(entry, resource), C.GetRecovery(current, resource)
	if value ~= previous then return value > previous end
	if (entry.requiredLevel or 0) ~= (current.requiredLevel or 0) then return (entry.requiredLevel or 0) > (current.requiredLevel or 0) end
	return entry.id < current.id
end

function C.GetBest(group, resource, preferMage)
	local best, bestRemaining
	for _, entry in ipairs(C.items) do
		if C.Matches(entry, group) and C.IsEligible(entry) and C.GetRecovery(entry, resource) > 0 and C.GetCount(entry) > 0 then
			C.RequestOwnedItemData(entry)
			local remaining = C.GetCooldown(entry)
			if remaining < math.huge and C.IsBetter(entry, best, resource, preferMage, remaining, bestRemaining) then
				best, bestRemaining = entry, remaining
			end
		end
	end
	return best
end

function C.GetBestBandage()
	local best
	for _, entry in ipairs(C.bandages) do
		-- Keep macro and panel selection independent of the food macro bag cache.
		local count = C_Item.GetItemCount(entry.id, false, false)
		if not isSecret(count) and type(count) == "number" and count > 0 and C.IsEligible(entry) and C.IsBetter(entry, best, "health", false, 0, 0) then best = entry end
	end
	if best then C.RequestOwnedItemData(best) end
	return best
end

if addon.functions.invalidateFoodTrackedItemIDs then addon.functions.invalidateFoodTrackedItemIDs() end
