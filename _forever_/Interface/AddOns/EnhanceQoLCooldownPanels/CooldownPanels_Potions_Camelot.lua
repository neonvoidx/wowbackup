local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

local CP = addon.Aura.CooldownPanels
local Api = CP.helper.Api
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local P = {
	definitions = {
		health = { itemID = 118, icon = 134829, labelKey = "CooldownPanelBestHealthPotion" },
		mana = { itemID = 2455, icon = 134850, labelKey = "CooldownPanelBestManaPotion" },
		bandage = { itemID = 1251, icon = 133685, labelKey = "CooldownPanelBestBandage", tooltipKey = "CooldownPanelBestBandageTooltip" },
	},
	candidates = { health = {}, mana = {}, bandage = {} },
	candidateIDs = { health = {}, mana = {}, bandage = {} },
	selected = {},
	lastSelected = {},
	maxima = {},
}
CP.Potions = P

local function isSecret(value) return issecretvalue and issecretvalue(value) end

-- Families include combined recovery potions, but never healthstones or mana gems.
for _, item in ipairs(addon.ForeverConsumables and addon.ForeverConsumables.items or {}) do
	if item.category == "bandage" then
		P.candidates.bandage[#P.candidates.bandage + 1] = item
		P.candidateIDs.bandage[#P.candidateIDs.bandage + 1] = item.id
	end
	for _, resource in ipairs({ "health", "mana" }) do
		local category = resource == "health" and "healing_potion" or "mana_potion"
		if item.category == category or item.category == "healing_and_mana_potion" then
			P.candidates[resource][#P.candidates[resource] + 1] = item
			P.candidateIDs[resource][#P.candidateIDs[resource] + 1] = item.id
		end
	end
end

function P:GetDefinition(resource)
	if isSecret(resource) or type(resource) ~= "string" then return nil end
	return self.definitions[resource]
end

function P:GetEntryResource(entry)
	if type(entry) ~= "table" or entry.type ~= "ITEM" then return nil end
	local resource = entry.potionResource
	return self:GetDefinition(resource) and resource or nil
end

function P:GetEntryName(entry)
	local definition = self:GetDefinition(self:GetEntryResource(entry))
	return definition and L[definition.labelKey] or nil
end

function P:GetCandidateIDs(entry)
	local resource = self:GetEntryResource(entry)
	return resource and self.candidateIDs[resource] or nil
end

function P:Invalidate() self.selected = {} end

local function getMaximum(resource)
	local value
	if resource == "health" then
		value = UnitHealthMax and UnitHealthMax("player")
	else
		value = UnitPowerMax and UnitPowerMax("player", 0)
	end
	if not isSecret(value) and type(value) == "number" and value >= 0 and value < math.huge then
		if resource == "mana" or value > 0 then P.maxima[resource] = value end
	end
	-- Keep the last public maximum when combat restricts access to the live value.
	return P.maxima[resource]
end

local function isOwnedAndEligible(item)
	if not addon.ForeverConsumables.IsEligible(item) then return false end
	local count = Api.GetItemCount(item.id, false, false)
	return not isSecret(count) and type(count) == "number" and count > 0
end

local function getRecovery(item, resource, maximum)
	local percent = item[resource .. "Percent"] or 0
	if percent > 0 then
		if maximum == nil then return nil end
		return (item[resource] or 0) + maximum * percent / 100
	end
	return addon.ForeverConsumables.GetRecovery(item, resource)
end

function P:ResolveItemID(entry)
	local resource = self:GetEntryResource(entry)
	if not resource then return nil end
	local cached = self.selected[resource]
	if cached ~= nil then return cached or nil end
	if resource == "bandage" then
		local best = addon.ForeverConsumables.GetBestBandage()
		self.selected[resource] = best and best.id or false
		return best and best.id or nil
	end
	local maximum = getMaximum(resource)
	if resource == "mana" and maximum == 0 then
		self.selected[resource] = false
		return nil
	end
	local best, bestRecovery
	for _, item in ipairs(self.candidates[resource]) do
		if isOwnedAndEligible(item) then
			-- When no public maximum is known, preserve a previously selected carried
			-- potion instead of changing its identity from an unknown percentage value.
			if maximum == nil and item.id == self.lastSelected[resource] then
				best = item
				break
			end
			local recovery = getRecovery(item, resource, maximum)
			if recovery and recovery > 0 then
				if
					not best
					or recovery > bestRecovery
					or (recovery == bestRecovery and (item.requiredLevel or 0) > (best.requiredLevel or 0))
					or (recovery == bestRecovery and (item.requiredLevel or 0) == (best.requiredLevel or 0) and item.id < best.id)
				then
					best, bestRecovery = item, recovery
				end
			end
		end
	end
	self.selected[resource] = best and best.id or false
	if best then
		self.lastSelected[resource] = best.id
		if addon.ForeverConsumables.RequestOwnedItemData then addon.ForeverConsumables.RequestOwnedItemData(best) end
		return best.id
	end
	return nil
end
