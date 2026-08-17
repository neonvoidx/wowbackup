local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local CooldownPanels = addon.Aura and addon.Aura.CooldownPanels
if not CooldownPanels then return end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Helper = CooldownPanels.helper
local C_Spell = C_Spell

local AuraPresets = {
	definitions = {},
	defensivePresetKeys = {},
}
CooldownPanels.AuraPresets = AuraPresets

local defensiveSourceCatalog = addon.Aura.DefensiveAuraPresets

AuraPresets.defensivePresetKeyAliases = {
	DEFENSIVE_444741 = "DEFENSIVE_48707",
	DEFENSIVE_120954 = "DEFENSIVE_115203",
	DEFENSIVE_403876 = "DEFENSIVE_498",
	DEFENSIVE_1277297 = "DEFENSIVE_190456",
	DEFENSIVE_1309794 = "DEFENSIVE_1022",
}

AuraPresets.catalog = {
	quick = {
		{
			key = "POWER_INFUSION",
			spellIDs = { 10060 },
			labelSpellID = 10060,
			iconSpellID = 10060,
		},
		{
			key = "BLOODLUST",
			spellIDs = {
				2825,
				32182,
				80353,
				90355,
				160452,
				244639,
				264667,
				381301,
				390386,
				441076,
				444257,
			},
			labelSpellIDs = { 2825, 32182 },
			iconSpellID = 2825,
		},
		{
			key = "THREAT_REDIRECTION",
			spellIDs = { 34477, 57934 },
			labelKey = "CooldownPanelAuraPresetThreatRedirection",
			iconSpellID = 34477,
		},
	},
	-- Cooldown Panels only needs the derived preset-key view. Keep the shared
	-- source catalog immutable for Group Frames and other consumers.
	defensives = {
		externals = { presetKeys = {} },
		raidArea = { presetKeys = {} },
		classes = {},
	},
	trinkets = { presetKeys = {} },
	potions = { presetKeys = {} },
}

local function normalizeSpellIDs(spellIDs)
	local normalized = {}
	local seen = {}
	for i = 1, #(spellIDs or {}) do
		local spellID = tonumber(spellIDs[i])
		if spellID and spellID > 0 and not seen[spellID] then
			seen[spellID] = true
			normalized[#normalized + 1] = spellID
		end
	end
	return normalized
end

local function normalizeSpellIDsByItemID(values)
	local normalized = {}
	for rawItemID, spellIDs in pairs(type(values) == "table" and values or {}) do
		local itemID = tonumber(rawItemID)
		local itemSpellIDs = normalizeSpellIDs(spellIDs)
		if itemID and itemID > 0 and #itemSpellIDs > 0 then normalized[itemID] = itemSpellIDs end
	end
	return normalized
end

local function normalizeSpellCategories(values)
	local normalized = {}
	for rawSpellID, categories in pairs(type(values) == "table" and values or {}) do
		local spellID = tonumber(rawSpellID)
		if spellID and type(categories) == "table" then
			local entry = { activation = {}, effects = {} }
			for _, dimension in ipairs({ "activation", "effects" }) do
				for i = 1, #(categories[dimension] or {}) do
					local value = tostring(categories[dimension][i] or "")
					if value ~= "" then entry[dimension][value] = true end
				end
			end
			normalized[spellID] = entry
		end
	end
	return normalized
end

local function registerDefinition(definition)
	if type(definition) ~= "table" or type(definition.key) ~= "string" then return nil end
	definition.spellIDs = normalizeSpellIDs(definition.spellIDs)
	if #definition.spellIDs == 0 then return nil end
	definition.primarySpellID = tonumber(definition.primarySpellID) or definition.spellIDs[1]
	definition.iconSpellID = tonumber(definition.iconSpellID) or definition.primarySpellID
	definition.labelSpellID = tonumber(definition.labelSpellID)
	definition.maxFrameCount = math.max(1, math.floor(tonumber(definition.maxFrameCount) or 1))
	definition.spellIDsByItemID = normalizeSpellIDsByItemID(definition.spellIDsByItemID)
	definition.spellCategories = normalizeSpellCategories(definition.spellCategories)
	definition.slotOverlaySpellIDsByItemID = normalizeSpellIDsByItemID(definition.slotOverlaySpellIDsByItemID)
	definition.spellIDSet = {}
	for i = 1, #definition.spellIDs do definition.spellIDSet[definition.spellIDs[i]] = true end
	AuraPresets.definitions[definition.key] = definition
	return definition.key
end

local function registerDefensivePreset(preset)
	local definition = {}
	if type(preset) == "table" then
		for key, value in pairs(preset) do definition[key] = value end
	else
		local spellID = tonumber(preset)
		if not spellID then return nil end
		definition.primarySpellID = spellID
		definition.spellIDs = { spellID }
	end

	local primarySpellID = tonumber(definition.primarySpellID)
	if not primarySpellID and type(definition.spellIDs) == "table" then primarySpellID = tonumber(definition.spellIDs[1]) end
	if not primarySpellID then return nil end
	local sourceSpellIDs = normalizeSpellIDs(definition.spellIDs)
	if #sourceSpellIDs == 0 then sourceSpellIDs[1] = primarySpellID end
	local alternativeSpellIDs = {}
	for i = 1, #sourceSpellIDs do
		local spellID = sourceSpellIDs[i]
		if spellID ~= primarySpellID then alternativeSpellIDs[#alternativeSpellIDs + 1] = spellID end
	end

	local key = "DEFENSIVE_" .. tostring(primarySpellID)
	if AuraPresets.definitions[key] then return key end

	definition.key = key
	definition.primarySpellID = primarySpellID
	-- The primary spell identifies the one visible preset entry. Alternate aura
	-- IDs are initialized into the existing per-entry Alternative aura Spell IDs
	-- field, where they remain visible and user-editable.
	definition.spellIDs = { primarySpellID }
	definition.alternativeSpellIDs = #alternativeSpellIDs > 0 and alternativeSpellIDs or nil
	definition.alternativeSpellIDSignature = definition.alternativeSpellIDs and table.concat(definition.alternativeSpellIDs, ",") or ""
	definition.labelSpellID = tonumber(definition.labelSpellID) or primarySpellID
	definition.iconSpellID = tonumber(definition.iconSpellID) or primarySpellID
	local presetKey = registerDefinition(definition)
	if presetKey then AuraPresets.defensivePresetKeys[#AuraPresets.defensivePresetKeys + 1] = presetKey end
	return presetKey
end

local function registerDefensiveCategory(category)
	local presetKeys = {}
	for i = 1, #category do
		local presetKey = registerDefensivePreset(category[i])
		if presetKey then presetKeys[#presetKeys + 1] = presetKey end
	end
	return presetKeys
end

local function registerGeneratedCategory(categoryKey)
	local presetKeys = AuraPresets.catalog[categoryKey].presetKeys
	local generatedCatalog = CooldownPanels.generatedAuraPresetCatalog
	local definitions = type(generatedCatalog) == "table" and generatedCatalog[categoryKey] or nil
	local seen = {}
	for i = 1, #(definitions or {}) do
		local definition = definitions[i]
		definition.defaultActiveGlow = true
		local presetKey = registerDefinition(definition)
		if presetKey and not seen[presetKey] then
			seen[presetKey] = true
			presetKeys[#presetKeys + 1] = presetKey
		end
	end
	table.sort(presetKeys)
end

for i = 1, #AuraPresets.catalog.quick do
	registerDefinition(AuraPresets.catalog.quick[i])
end

for _, categoryKey in ipairs({ "externals", "raidArea" }) do
	AuraPresets.catalog.defensives[categoryKey].presetKeys = registerDefensiveCategory(defensiveSourceCatalog[categoryKey])
end

for i = 1, #defensiveSourceCatalog.classes do
	local sourceClassData = defensiveSourceCatalog.classes[i]
	AuraPresets.catalog.defensives.classes[#AuraPresets.catalog.defensives.classes + 1] = {
		classTag = sourceClassData.classTag,
		presetKeys = registerDefensiveCategory(sourceClassData.presets),
	}
end

registerGeneratedCategory("trinkets")
registerGeneratedCategory("potions")

function AuraPresets:GetDefinition(presetKey)
	return type(presetKey) == "string" and self.definitions[presetKey] or nil
end

function AuraPresets:GetEntryDefinition(entry)
	return type(entry) == "table" and self:GetDefinition(entry.auraPresetKey) or nil
end

local function mergeSpellIDLists(...)
	local merged = {}
	local seen = {}
	for listIndex = 1, select("#", ...) do
		local values = select(listIndex, ...)
		for i = 1, #(type(values) == "table" and values or {}) do
			local spellID = tonumber(values[i])
			if spellID and spellID > 0 and not seen[spellID] then
				seen[spellID] = true
				merged[#merged + 1] = spellID
			end
		end
	end
	return #merged > 0 and merged or nil
end

function AuraPresets:MigrateDefensivePresetEntries(root)
	if type(root) ~= "table" then return false end
	local changed = false
	local exclusions = type(root.auraPresetExclusions) == "table" and root.auraPresetExclusions or nil
	if exclusions then
		for aliasKey, canonicalKey in pairs(self.defensivePresetKeyAliases) do
			local aliasExclusions = exclusions[aliasKey]
			if type(aliasExclusions) == "table" then
				local canonicalExclusions = type(exclusions[canonicalKey]) == "table" and exclusions[canonicalKey] or {}
				for spellID, excluded in pairs(aliasExclusions) do
					if excluded == true then canonicalExclusions[spellID] = true end
				end
				exclusions[canonicalKey] = canonicalExclusions
			end
			if exclusions[aliasKey] ~= nil then
				exclusions[aliasKey] = nil
				changed = true
			end
		end
		for presetKey in pairs(exclusions) do
			if type(presetKey) == "string" and presetKey:match("^DEFENSIVE_") and not self.definitions[presetKey] then
				exclusions[presetKey] = nil
				changed = true
			end
		end
	end

	for _, panel in pairs(type(root.panels) == "table" and root.panels or {}) do
		if type(panel) == "table" and type(panel.entries) == "table" then
			local canonicalEntries = {}
			for _, entry in pairs(panel.entries) do
				local presetKey = type(entry) == "table" and entry.auraPresetKey or nil
				if type(presetKey) == "string" and presetKey:match("^DEFENSIVE_") and self.definitions[presetKey] then
					canonicalEntries[presetKey] = canonicalEntries[presetKey] or entry
				end
			end

			local removedEntry = false
			for entryId, entry in pairs(panel.entries) do
				local presetKey = type(entry) == "table" and entry.auraPresetKey or nil
				local canonicalKey = type(presetKey) == "string" and self.defensivePresetKeyAliases[presetKey] or nil
				if canonicalKey then
					local canonicalEntry = canonicalEntries[canonicalKey]
					if canonicalEntry and canonicalEntry ~= entry then
						canonicalEntry.cdmAuraOverlaySpellIDs = mergeSpellIDLists(canonicalEntry.cdmAuraOverlaySpellIDs, entry.cdmAuraOverlaySpellIDs)
						panel.entries[entryId] = nil
						removedEntry = true
					else
						entry.auraPresetKey = canonicalKey
						entry.auraPresetAlternativeSpellIDsSignature = nil
						canonicalEntries[canonicalKey] = entry
					end
					changed = true
				elseif type(presetKey) == "string" and presetKey:match("^DEFENSIVE_") and not self.definitions[presetKey] then
					-- Presets removed from the shipped catalog keep their tracked aura and
					-- styling as ordinary custom entries instead of becoming orphaned presets.
					entry.auraPresetKey = nil
					entry.auraPresetAlternativeSpellIDsSignature = nil
					changed = true
				end
			end
			if removedEntry then Helper.SyncOrder(panel.order, panel.entries) end
		end
	end
	return changed
end

AuraPresets.originalNormalizeAll = CooldownPanels.NormalizeAll
function CooldownPanels:NormalizeAll(...)
	local root = self.GetRoot and self:GetRoot() or nil
	AuraPresets:MigrateDefensivePresetEntries(root)
	return AuraPresets.originalNormalizeAll(self, ...)
end

local function getPresetExclusions(presetKey, create)
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	if not root then return nil end
	if type(root.auraPresetExclusions) ~= "table" then
		if not create then return nil end
		root.auraPresetExclusions = {}
	end
	local exclusions = root.auraPresetExclusions[presetKey]
	if type(exclusions) ~= "table" then
		if not create then return nil end
		exclusions = {}
		root.auraPresetExclusions[presetKey] = exclusions
	end
	return exclusions, root.auraPresetExclusions
end

function AuraPresets:IsSpellIDEnabled(presetKey, spellID)
	local definition = self:GetDefinition(presetKey)
	spellID = tonumber(spellID)
	if not (definition and spellID) then return false end
	local exclusions = getPresetExclusions(presetKey, false)
	return not (exclusions and (exclusions[spellID] == true or exclusions[tostring(spellID)] == true))
end

local function invalidateEnabledSpellData(definition)
	definition.enabledSpellIDs = nil
	definition.enabledSpellIDSet = nil
	definition.enabledSpellIDSignature = nil
	definition.enabledSpellCount = nil
	definition.filteredSpellDataCache = nil
end

function AuraPresets:GetPresetExclusionText(presetKey)
	local definition = self:GetDefinition(presetKey)
	if not definition then return "" end
	local exclusions = getPresetExclusions(presetKey, false)
	local spellIDs = {}
	local seen = {}
	for rawSpellID, excluded in pairs(type(exclusions) == "table" and exclusions or {}) do
		local spellID = tonumber(rawSpellID)
		if excluded == true and spellID and spellID > 0 and spellID == math.floor(spellID) and not seen[spellID] then
			seen[spellID] = true
			spellIDs[#spellIDs + 1] = spellID
		end
	end
	table.sort(spellIDs)
	for i = 1, #spellIDs do spellIDs[i] = tostring(spellIDs[i]) end
	return table.concat(spellIDs, ", ")
end

function AuraPresets:SetPresetExclusionText(presetKey, value)
	local definition = self:GetDefinition(presetKey)
	if not definition then return false end
	local normalized = {}
	for candidate in tostring(value or ""):gmatch("[^,%s;]+") do
		local spellID = tonumber(candidate)
		if spellID and spellID > 0 and spellID == math.floor(spellID) then normalized[spellID] = true end
	end
	local current = getPresetExclusions(presetKey, false)
	local changed = false
	for rawSpellID, excluded in pairs(type(current) == "table" and current or {}) do
		local spellID = tonumber(rawSpellID)
		if excluded ~= true or not spellID or normalized[spellID] ~= true then
			changed = true
			break
		end
	end
	if not changed then
		for spellID in pairs(normalized) do
			if not (current and (current[spellID] == true or current[tostring(spellID)] == true)) then
				changed = true
				break
			end
		end
	end
	if not changed then return false end
	local _, allExclusions = getPresetExclusions(presetKey, true)
	allExclusions[presetKey] = next(normalized) and normalized or nil
	invalidateEnabledSpellData(definition)
	return true
end

local TRACKING_PRESET_KEYS = { "TRINKET_UPTIME", "COMBAT_POTION" }

function AuraPresets:GetCombinedExclusions()
	local rowsByID = {}
	for i = 1, #TRACKING_PRESET_KEYS do
		local presetKey = TRACKING_PRESET_KEYS[i]
		local exclusions = getPresetExclusions(presetKey, false)
		for rawSpellID, excluded in pairs(type(exclusions) == "table" and exclusions or {}) do
			local spellID = tonumber(rawSpellID)
			if excluded == true and spellID and spellID > 0 then
				local row = rowsByID[spellID] or { spellID = spellID, presetKeys = {} }
				row.presetKeys[presetKey] = true
				rowsByID[spellID] = row
			end
		end
	end
	local rows = {}
	for _, row in pairs(rowsByID) do
		row.name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(row.spellID) or tostring(row.spellID)
		rows[#rows + 1] = row
	end
	table.sort(rows, function(left, right)
		if left.name ~= right.name then return left.name < right.name end
		return left.spellID < right.spellID
	end)
	return rows
end

function AuraPresets:AddCombinedExclusions(value)
	local changed = false
	local matched = 0
	for candidate in tostring(value or ""):gmatch("[^,%s;]+") do
		local spellID = tonumber(candidate)
		if spellID and spellID > 0 and spellID == math.floor(spellID) then
			for i = 1, #TRACKING_PRESET_KEYS do
				local presetKey = TRACKING_PRESET_KEYS[i]
				local definition = self:GetDefinition(presetKey)
				if definition and definition.spellIDSet[spellID] then
					matched = matched + 1
					local exclusions = getPresetExclusions(presetKey, true)
					if exclusions[spellID] ~= true then
						exclusions[spellID] = true
						invalidateEnabledSpellData(definition)
						changed = true
					end
				end
			end
		end
	end
	return changed, matched
end

function AuraPresets:RemoveCombinedExclusion(spellID)
	spellID = tonumber(spellID)
	if not spellID then return false end
	local changed = false
	for i = 1, #TRACKING_PRESET_KEYS do
		local presetKey = TRACKING_PRESET_KEYS[i]
		local exclusions = getPresetExclusions(presetKey, false)
		if exclusions and (exclusions[spellID] == true or exclusions[tostring(spellID)] == true) then
			exclusions[spellID], exclusions[tostring(spellID)] = nil, nil
			local definition = self:GetDefinition(presetKey)
			if definition then invalidateEnabledSpellData(definition) end
			changed = true
		end
	end
	return changed
end

local function ensureEnabledSpellData(definition)
	if definition.enabledSpellIDs and definition.enabledSpellIDSet and definition.enabledSpellIDSignature then return end
	local exclusions = getPresetExclusions(definition.key, false)
	local spellIDs = {}
	local spellIDSet = {}
	for i = 1, #definition.spellIDs do
		local spellID = definition.spellIDs[i]
		local excluded = exclusions and (exclusions[spellID] == true or exclusions[tostring(spellID)] == true)
		if not excluded then
			spellIDs[#spellIDs + 1] = spellID
			spellIDSet[spellID] = true
		end
	end
	definition.enabledSpellIDs = spellIDs
	definition.enabledSpellIDSet = spellIDSet
	definition.enabledSpellIDSignature = table.concat(spellIDs, ",")
	definition.enabledSpellCount = #spellIDs
end

local function entryPassesSpellTags(definition, entry, spellID)
	local categories = definition.spellCategories[spellID] or {}
	local activationExclusions = type(entry and entry.auraPresetExcludedActivations) == "table" and entry.auraPresetExcludedActivations or nil
	local effectExclusions = type(entry and entry.auraPresetExcludedEffects) == "table" and entry.auraPresetExcludedEffects or nil
	for value in pairs(categories.activation or {}) do
		if activationExclusions and activationExclusions[value] == true then return false end
	end
	for value in pairs(categories.effects or {}) do
		if effectExclusions and effectExclusions[value] == true then return false end
	end
	return true
end

local function filterSignature(values)
	local keys = {}
	for value, excluded in pairs(type(values) == "table" and values or {}) do
		if excluded == true then keys[#keys + 1] = tostring(value) end
	end
	table.sort(keys)
	return table.concat(keys, "+")
end

function AuraPresets:GetEntrySpellData(entry)
	local definition = self:GetEntryDefinition(entry)
	if not definition then return nil end
	ensureEnabledSpellData(definition)
	if definition.key ~= "TRINKET_UPTIME" then return definition.enabledSpellIDs, definition.enabledSpellIDSet, definition.enabledSpellIDSignature end
	local activationExclusions = type(entry.auraPresetExcludedActivations) == "table" and entry.auraPresetExcludedActivations or nil
	local effectExclusions = type(entry.auraPresetExcludedEffects) == "table" and entry.auraPresetExcludedEffects or nil
	if not (activationExclusions and next(activationExclusions)) and not (effectExclusions and next(effectExclusions)) then
		return definition.enabledSpellIDs, definition.enabledSpellIDSet, definition.enabledSpellIDSignature
	end
	local cacheKey = definition.enabledSpellIDSignature .. "|" .. filterSignature(activationExclusions) .. "|" .. filterSignature(effectExclusions)
	definition.filteredSpellDataCache = definition.filteredSpellDataCache or {}
	local cached = definition.filteredSpellDataCache[cacheKey]
	if cached then return cached.spellIDs, cached.spellIDSet, cached.signature end
	local spellIDs, spellIDSet = {}, {}
	for i = 1, #definition.enabledSpellIDs do
		local spellID = definition.enabledSpellIDs[i]
		if entryPassesSpellTags(definition, entry, spellID) then
			spellIDs[#spellIDs + 1] = spellID
			spellIDSet[spellID] = true
		end
	end
	local signature = table.concat(spellIDs, ",")
	definition.filteredSpellDataCache[cacheKey] = { spellIDs = spellIDs, spellIDSet = spellIDSet, signature = signature }
	return spellIDs, spellIDSet, signature
end

function AuraPresets:IsEntryFilterSelected(entry, field, value)
	local exclusions = type(entry) == "table" and type(entry[field]) == "table" and entry[field] or nil
	return not (exclusions and exclusions[value] == true)
end

function AuraPresets:SetEntryFilterSelected(entry, field, value, selected)
	if type(entry) ~= "table" then return false end
	entry[field] = type(entry[field]) == "table" and entry[field] or {}
	if selected == true then
		entry[field][value] = nil
	else
		entry[field][value] = true
	end
	if not next(entry[field]) then entry[field] = nil end
	return true
end

function AuraPresets:GetEntrySpellIDs(entry)
	local spellIDs = self:GetEntrySpellData(entry)
	return spellIDs
end

function AuraPresets:GetItemSpellIDs(presetKey, itemID, entry)
	local definition = self:GetDefinition(presetKey)
	itemID = tonumber(itemID)
	local configured = definition and itemID and definition.spellIDsByItemID and definition.spellIDsByItemID[itemID] or nil
	if not configured then return nil, false end
	configured = definition.slotOverlaySpellIDsByItemID[itemID] or configured
	local spellIDs = {}
	-- This item mapping is also used by ordinary SLOT entries with Aura Overlay.
	-- Global Spell ID exclusions and per-entry tag exclusions apply to both entry kinds.
	for i = 1, #configured do
		local spellID = configured[i]
		if self:IsSpellIDEnabled(presetKey, spellID) and entryPassesSpellTags(definition, entry, spellID) then spellIDs[#spellIDs + 1] = spellID end
	end
	return #spellIDs > 0 and spellIDs or nil, true
end

function AuraPresets:GetPrimarySpellID(presetKey)
	local definition = self:GetDefinition(presetKey)
	return definition and definition.primarySpellID or nil
end

function AuraPresets:GetEntryMaxFrameCount(entry)
	local definition = self:GetEntryDefinition(entry)
	return definition and definition.maxFrameCount or 1
end

function AuraPresets:EntryTracksSpellID(entry, spellID)
	local _, spellIDSet = self:GetEntrySpellData(entry)
	spellID = tonumber(spellID)
	if not spellID then return false end
	if spellIDSet and spellIDSet[spellID] == true then return true end
	for i = 1, #(entry and entry.cdmAuraOverlaySpellIDs or {}) do
		if tonumber(entry.cdmAuraOverlaySpellIDs[i]) == spellID then return true end
	end
	return false
end

local function getSpellName(spellID)
	return spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or nil
end

local function getSpellTexture(spellID)
	return spellID and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID) or nil
end

local function showErrorMessage(message)
	if UIErrorsFrame and message then UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2, 1) end
end

function AuraPresets:GetDisplayName(presetKey)
	local definition = self:GetDefinition(presetKey)
	if not definition then return nil end
	if definition.labelKey then return L[definition.labelKey] or definition.labelKey end
	if type(definition.labelSpellIDs) == "table" then
		local names = {}
		for i = 1, #definition.labelSpellIDs do
			local name = getSpellName(definition.labelSpellIDs[i])
			if name then names[#names + 1] = name end
		end
		if #names > 0 then return table.concat(names, " / ") end
	end
	return getSpellName(definition.labelSpellID or definition.primarySpellID) or tostring(definition.primarySpellID)
end

function AuraPresets:GetIcon(presetKey)
	local definition = self:GetDefinition(presetKey)
	return definition and getSpellTexture(definition.iconSpellID or definition.primarySpellID) or nil
end

function AuraPresets:NormalizeEntry(entry)
	local canonicalKey = type(entry) == "table" and self.defensivePresetKeyAliases[entry.auraPresetKey] or nil
	if canonicalKey then entry.auraPresetKey = canonicalKey end
	local definition = self:GetEntryDefinition(entry)
	if not definition then return false end
	-- These short-lived include filters never shipped. Reset any PTR test values
	-- to the new default-all exclusion model instead of guessing at mixed-tag intent.
	entry.auraPresetActivationFilters = nil
	entry.auraPresetEffectFilters = nil
	if definition.defaultActiveGlow == true and entry.auraPresetActiveGlowInitialized ~= true then
		-- Preserve an explicit per-entry choice on adopted presets. Entries created
		-- before the uptime presets gained their default active glow still inherit
		-- the panel setting and are migrated once to the AuraButton-owned glow.
		if entry.glowReadyUseGlobal ~= false then
			entry.glowReady = true
			entry.glowReadyUseGlobal = false
			entry.glowUseGlobal = false
		end
		entry.auraPresetActiveGlowInitialized = true
	end
	if definition.alternativeSpellIDs and entry.auraPresetAlternativeSpellIDsSignature ~= definition.alternativeSpellIDSignature then
		entry.cdmAuraOverlaySpellIDs = mergeSpellIDLists(definition.alternativeSpellIDs, entry.cdmAuraOverlaySpellIDs)
		entry.auraPresetAlternativeSpellIDsSignature = definition.alternativeSpellIDSignature
	end
	entry.auraSpellID = definition.primarySpellID
	entry.spellID = definition.primarySpellID
	entry.buffName = self:GetDisplayName(definition.key)
	entry.iconTextureID = self:GetIcon(definition.key) or entry.iconTextureID or Helper.PREVIEW_ICON
	return true
end

local function getClassLabel(classTag)
	if _G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE[classTag] then return _G.LOCALIZED_CLASS_NAMES_MALE[classTag] end
	if _G.LOCALIZED_CLASS_NAMES_FEMALE and _G.LOCALIZED_CLASS_NAMES_FEMALE[classTag] then return _G.LOCALIZED_CLASS_NAMES_FEMALE[classTag] end
	return classTag
end

local function formatPresetLabel(presetKey)
	local name = AuraPresets:GetDisplayName(presetKey) or tostring(presetKey)
	local icon = AuraPresets:GetIcon(presetKey) or Helper.PREVIEW_ICON
	return string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", tostring(icon), name)
end

local function buildCandidateSet(definition)
	local candidates = {}
	for i = 1, #definition.spellIDs do candidates[definition.spellIDs[i]] = true end
	for i = 1, #(definition.alternativeSpellIDs or {}) do candidates[definition.alternativeSpellIDs[i]] = true end
	return candidates
end

function AuraPresets:FindEntry(panel, presetKey)
	local definition = self:GetDefinition(presetKey)
	if not (panel and panel.entries and definition) then return nil end
	for entryId, entry in pairs(panel.entries) do
		if entry and entry.type == "CDM_AURA" and entry.auraPresetKey == presetKey then return entryId, entry, false end
	end
	local candidates = buildCandidateSet(definition)
	for entryId, entry in pairs(panel.entries) do
		local spellID = entry and entry.type == "CDM_AURA" and tonumber(entry.auraSpellID or entry.spellID) or nil
		if spellID and candidates[spellID] and entry.auraPresetKey == nil then return entryId, entry, true end
	end
	return nil
end

function AuraPresets:GetMissingPresetKeys(panel, presetKeys)
	local missingKeys = {}
	for i = 1, #(presetKeys or {}) do
		local presetKey = presetKeys[i]
		local entryId, _, canAdopt = self:FindEntry(panel, presetKey)
		if self:GetDefinition(presetKey) and (not entryId or canAdopt) then missingKeys[#missingKeys + 1] = presetKey end
	end
	return missingKeys
end

function AuraPresets:HasAvailablePresets(panelId)
	local panel = CooldownPanels:GetPanel(panelId)
	if not panel then return false end
	for presetKey in pairs(self.definitions) do
		local entryId, _, canAdopt = self:FindEntry(panel, presetKey)
		if not entryId or canAdopt then return true end
	end
	return false
end

local function mergeOverrides(base, extra)
	local merged = {}
	for key, value in pairs(base or {}) do merged[key] = value end
	for key, value in pairs(extra or {}) do merged[key] = value end
	return merged
end

function AuraPresets:AddPresetKeys(panelId, presetKeys)
	local panel = CooldownPanels:GetPanel(panelId)
	local root = CooldownPanels:GetRoot()
	local cdmAuras = CooldownPanels.CDMAuras
	if not (panel and root and cdmAuras and cdmAuras.CreateEntryData) then return nil end
	panel.entries = panel.entries or {}
	panel.order = panel.order or {}

	local stats = { added = 0, adopted = 0, duplicates = 0, invalid = 0, full = 0 }
	for i = 1, #(presetKeys or {}) do
		local presetKey = presetKeys[i]
		local definition = self:GetDefinition(presetKey)
		if not definition then
			stats.invalid = stats.invalid + 1
		else
			local entryId, entry, canAdopt = self:FindEntry(panel, presetKey)
			if entry then
				if canAdopt then
					entry.auraPresetKey = presetKey
					if cdmAuras.NormalizeEntry then
						cdmAuras:NormalizeEntry(entry, root.defaults)
					else
						self:NormalizeEntry(entry)
					end
					stats.adopted = stats.adopted + 1
				else
					stats.duplicates = stats.duplicates + 1
				end
			else
				local fixedOverrides, fixedError = CooldownPanels:ResolveFixedEntryAddOverrides(panel, nil)
				if fixedError then
					stats.full = stats.full + 1
					stats.error = fixedError
					break
				end
				local overrides = mergeOverrides(fixedOverrides, { auraPresetKey = presetKey })
				entry = cdmAuras:CreateEntryData(definition.primarySpellID, overrides, root.defaults)
				if entry then
					entryId = Helper.GetNextNumericId(panel.entries)
					entry.id = entryId
					panel.entries[entryId] = entry
					panel.order[#panel.order + 1] = entryId
					stats.added = stats.added + 1
					Helper.InvalidateFixedLayoutCache(panel)
					if Helper.IsFixedLayout(panel.layout) then Helper.EnsureFixedSlotAssignments(panel) end
				else
					stats.invalid = stats.invalid + 1
				end
			end
		end
	end

	if stats.added > 0 or stats.adopted > 0 then
		Helper.SyncOrder(panel.order, panel.entries)
		if Helper.UpdatePanelEntrySpecFilterState then Helper.UpdatePanelEntrySpecFilterState(panel) end
		Helper.InvalidateFixedLayoutCache(panel)
		if Helper.IsFixedLayout(panel.layout) then Helper.EnsureFixedSlotAssignments(panel) end
		CooldownPanels:RebuildSpellIndex()
		CooldownPanels:RefreshPanel(panelId)
		CooldownPanels:RefreshEditor()
		if CooldownPanels.BlizzardEditor and CooldownPanels.BlizzardEditor.RefreshPanel then CooldownPanels.BlizzardEditor:RefreshPanel(panelId) end
	end
	if stats.error then showErrorMessage(stats.error) end
	return stats
end

function AuraPresets:AddPreset(panelId, presetKey)
	return self:AddPresetKeys(panelId, { presetKey })
end

function AuraPresets:AddAllDefensives(panelId)
	return self:AddPresetKeys(panelId, self.defensivePresetKeys)
end

local function isNameBefore(leftName, rightName, leftTieBreaker, rightTieBreaker)
	leftName = tostring(leftName or "")
	rightName = tostring(rightName or "")
	if strcmputf8i then
		local comparison = strcmputf8i(leftName, rightName)
		if comparison ~= 0 then return comparison < 0 end
	else
		local leftLower = leftName:lower()
		local rightLower = rightName:lower()
		if leftLower ~= rightLower then return leftLower < rightLower end
	end
	return tostring(leftTieBreaker or "") < tostring(rightTieBreaker or "")
end

local function getSortedPresetKeys(presetKeys)
	local sortedKeys = {}
	for i = 1, #(presetKeys or {}) do sortedKeys[i] = presetKeys[i] end
	table.sort(sortedKeys, function(leftKey, rightKey)
		return isNameBefore(AuraPresets:GetDisplayName(leftKey), AuraPresets:GetDisplayName(rightKey), leftKey, rightKey)
	end)
	return sortedKeys
end

local function appendPresetButtons(menu, panelId, presetKeys, sortByName)
	local displayKeys = sortByName and getSortedPresetKeys(presetKeys) or presetKeys or {}
	for i = 1, #displayKeys do
		local presetKey = displayKeys[i]
		menu:CreateButton(formatPresetLabel(presetKey), function()
			AuraPresets:AddPreset(panelId, presetKey)
		end)
	end
end

function AuraPresets:AppendAddMenu(rootDescription, panelId)
	if not (rootDescription and panelId) then return false end
	local panel = CooldownPanels:GetPanel(panelId)
	if not panel then return false end
	local quickPresetKeys = self:GetMissingPresetKeys(panel, { "POWER_INFUSION", "BLOODLUST" })
	local defensivePresetKeys = self:GetMissingPresetKeys(panel, self.defensivePresetKeys)
	local trinketPresetKeys = self:GetMissingPresetKeys(panel, self.catalog.trinkets.presetKeys)
	local potionPresetKeys = self:GetMissingPresetKeys(panel, self.catalog.potions.presetKeys)
	local threatPresetKeys = self:GetMissingPresetKeys(panel, { "THREAT_REDIRECTION" })
	if #quickPresetKeys == 0 and #defensivePresetKeys == 0 and #trinketPresetKeys == 0 and #potionPresetKeys == 0 and #threatPresetKeys == 0 then
		return false
	end

	local quickMenu = rootDescription:CreateButton(L["CooldownPanelAuraPresetQuickAdd"] or "Quick add")
	if not quickMenu then return false end
	appendPresetButtons(quickMenu, panelId, quickPresetKeys)

	if #defensivePresetKeys > 0 then
		local defensivesMenu = quickMenu:CreateButton(L["CooldownPanelAuraPresetDefensives"] or "Defensives")
		if defensivesMenu.SetScrollMode then defensivesMenu:SetScrollMode(340) end
		defensivesMenu:CreateButton(string.format("%s: %s", _G.ADD or "Add", _G.ALL or "All"), function()
			AuraPresets:AddPresetKeys(panelId, defensivePresetKeys)
		end)
		defensivesMenu:CreateDivider()

		local externalPresetKeys = self:GetMissingPresetKeys(panel, self.catalog.defensives.externals.presetKeys)
		if #externalPresetKeys > 0 then
			local externalMenu = defensivesMenu:CreateButton(L["CooldownPanelAuraPresetExternals"] or "Externals")
			externalMenu:CreateButton(string.format("%s: %s", _G.ADD or "Add", _G.ALL or "All"), function()
				AuraPresets:AddPresetKeys(panelId, externalPresetKeys)
			end)
			externalMenu:CreateDivider()
			appendPresetButtons(externalMenu, panelId, externalPresetKeys, true)
		end

		local raidAreaPresetKeys = self:GetMissingPresetKeys(panel, self.catalog.defensives.raidArea.presetKeys)
		if #raidAreaPresetKeys > 0 then
			local raidAreaMenu = defensivesMenu:CreateButton(L["CooldownPanelAuraPresetRaidArea"] or "Raid / area defensives")
			raidAreaMenu:CreateButton(string.format("%s: %s", _G.ADD or "Add", _G.ALL or "All"), function()
				AuraPresets:AddPresetKeys(panelId, raidAreaPresetKeys)
			end)
			raidAreaMenu:CreateDivider()
			appendPresetButtons(raidAreaMenu, panelId, raidAreaPresetKeys, true)
		end

		local sortedClasses = {}
		for i = 1, #self.catalog.defensives.classes do
			local classData = self.catalog.defensives.classes[i]
			local classPresetKeys = self:GetMissingPresetKeys(panel, classData.presetKeys)
			if #classPresetKeys > 0 then sortedClasses[#sortedClasses + 1] = { data = classData, presetKeys = classPresetKeys } end
		end
		table.sort(sortedClasses, function(leftClass, rightClass)
			return isNameBefore(
				getClassLabel(leftClass.data.classTag),
				getClassLabel(rightClass.data.classTag),
				leftClass.data.classTag,
				rightClass.data.classTag
			)
		end)
		if #sortedClasses > 0 then
			local classMenu = defensivesMenu:CreateButton(L["CooldownPanelAuraPresetByClass"] or "By class")
			for i = 1, #sortedClasses do
				local classData = sortedClasses[i].data
				local classPresetKeys = sortedClasses[i].presetKeys
				local classSubmenu = classMenu:CreateButton(getClassLabel(classData.classTag))
				classSubmenu:CreateButton(string.format("%s: %s", _G.ADD or "Add", _G.ALL or "All"), function()
					AuraPresets:AddPresetKeys(panelId, classPresetKeys)
				end)
				classSubmenu:CreateDivider()
				appendPresetButtons(classSubmenu, panelId, classPresetKeys, true)
			end
		end
	end

	appendPresetButtons(quickMenu, panelId, trinketPresetKeys)
	appendPresetButtons(quickMenu, panelId, potionPresetKeys)
	appendPresetButtons(quickMenu, panelId, threatPresetKeys)
	return true
end
