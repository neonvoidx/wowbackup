local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

local CP = addon.Aura.CooldownPanels
local Helper = CP.helper
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Shared = addon.EntryPicker
local Picker = Shared:Create("CooldownPanels", { idTypes = { "SPELL", "CDM_AURA", "ITEM" } })
CP.AddEntryPicker = Picker
Picker.showAddedEntries = true

Picker.categories = {
	{ id = "ALL", label = L["CooldownPanelPickerAll"] },
	{ id = "SPELLS", label = _G.SPELLS or CP:GetEntryTypeLabel("SPELL") },
	{ id = "UTILITY", label = L["CooldownPanelTrinketEffectUtility"] },
	{ id = "DEFENSIVES", label = L["CooldownPanelPickerPersonalDefensives"] },
	{ id = "RAID", label = L["CooldownPanelPickerRaidDefensives"] },
	{ id = "AURAS", label = CP:GetEntryTypeLabel("CDM_AURA") },
	{ id = "SPECIAL", label = L["CooldownPanelPickerSpecial"] },
	{ id = "RACIALS", label = L["CooldownPanelAddRacials"] },
	{ id = "SLOTS", label = CP:GetEntryTypeLabel("SLOT") },
	{ id = "STANCES", label = CP:GetStanceTypeLabel() },
	{ id = "TOTEMS", label = L["CooldownPanelTotems"] },
	{ id = "MACROS", label = L["Macros"] },
	{ id = "ID", label = L["CooldownPanelPickerByID"] },
}

function Picker:GetTarget(id) return CP:GetPanel(id) end
function Picker:GetTypeLabel(kind) return CP:GetEntryTypeLabel(kind) end
function Picker:NotifyPanelChanged(panelId)
	if tostring(panelId) == tostring(self.targetId) then self:QueueRefresh() end
end

Picker.specialDescriptions = {
	BLOODLUST = "CooldownPanelPickerBloodlustTooltip",
	TIME_SPIRAL = "CooldownPanelPickerTimeSpiralTooltip",
	TRINKET_UPTIME = "CooldownPanelPickerTrinketTooltip",
	COMBAT_POTION = "CooldownPanelPickerPotionTooltip",
	THREAT_REDIRECTION = "CooldownPanelPickerThreatTooltip",
}

function Picker:BuildCatalog()
	local catalog, seen = {}, {}
	local presets = CP.AuraPresets
	local function append(row)
		if seen[row.key] then return end
		seen[row.key] = true
		row.name = row.name or tostring(row.value or row.key)
		row.search = self.NormalizeSearch(table.concat({ row.name, tostring(row.value or ""), row.description or "", row.searchIDs or "", self:GetClassLabel(row.classTag) or "" }, " "))
		catalog[#catalog + 1] = row
	end
	local function preset(key, category, classTag)
		local definition = presets and presets:GetDefinition(key)
		if not definition then return end
		append({ key = "preset:" .. key, kind = "PRESET", value = key, category = category, classTag = classTag,
			name = presets:GetDisplayName(key), icon = presets:GetIcon(key), spellID = definition.primarySpellID, tooltipSpellID = definition.labelSpellID or definition.primarySpellID,
			tooltipDescription = self.specialDescriptions[key] and L[self.specialDescriptions[key]],
			description = category == "SPECIAL" and L["CooldownPanelPickerCombined"] or CP:GetEntryTypeLabel("CDM_AURA") })
	end
	if presets then
		for _, definition in ipairs(presets.catalog.quick or {}) do
			preset(definition.key, #(definition.spellIDs or {}) > 1 and "SPECIAL" or "AURAS")
		end
		for _, groupKey in ipairs({ "externals", "raidArea" }) do
			for _, key in ipairs(((presets.catalog.defensives or {})[groupKey] or {}).presetKeys or {}) do preset(key, "RAID") end
		end
		for _, group in ipairs((presets.catalog.defensives or {}).classes or {}) do
			for _, key in ipairs(group.presetKeys or {}) do preset(key, "DEFENSIVES", group.classTag) end
		end
		for _, key in ipairs(presets.defensivePresetKeys or {}) do preset(key, "DEFENSIVES") end
		for _, group in ipairs({ "trinkets", "potions" }) do
			for _, key in ipairs((presets.catalog[group] or {}).presetKeys or {}) do preset(key, "SPECIAL") end
		end
		for _, definition in ipairs(presets.spellCooldownPresets or {}) do
			local spellID = definition.spellID
			local labelID = definition.labelSpellID or spellID
			local duration = definition.duration
			if definition.talentDuration and Helper.ResolveCustomCooldownTalentDuration then
				duration = Helper.ResolveCustomCooldownTalentDuration({ customCooldownDurationTalentEnabled = true,
					customCooldownDurationTalentSpellID = definition.talentDuration.spellID,
					customCooldownDurationTalentDuration = definition.talentDuration.duration }, duration)
			end
			append({ key = "internal:" .. spellID, kind = "INTERNAL", value = spellID, category = definition.category or "UTILITY", classTag = definition.classTag,
				name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(labelID),
				icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(labelID), tooltipSpellID = labelID, trackingID = spellID, definition = definition,
				description = string.format(L["CooldownPanelPickerInternalCooldown"], duration) })
		end
	end
	self:IndexPlayerSpells(append)
	if CP.AuraContainers then self:IndexCDMAuras(append) end
	for _, slot in ipairs(CP:GetSlotMenuEntries()) do
		append({ key = "slot:" .. slot.id, kind = "SLOT", value = slot.id, category = "SLOTS", name = slot.label,
			icon = GetInventoryItemTexture and GetInventoryItemTexture("player", slot.id), description = CP:GetEntryTypeLabel("SLOT") })
	end
	if GetTotemDuration then
		append({ key = "totem:all", kind = "TOTEMS_ALL", category = "TOTEMS", name = L["CooldownPanelAllTotems"], icon = Helper.TOTEM_PREVIEW_ICON, description = L["CooldownPanelTotemSlotHint"] })
		for slot = 1, (_G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4) do
			append({ key = "totem:" .. slot, kind = "TOTEM", value = slot, category = "TOTEMS", name = string.format(L["CooldownPanelTotemSlot"], slot), icon = Helper.TOTEM_PREVIEW_ICON, description = L["CooldownPanelTotemSlotHint"] })
		end
	end
	for _, group in ipairs(CP:GetStanceMenuEntries() or {}) do
		for _, stance in ipairs(group.entries or {}) do
			append({ key = "stance:" .. stance.id, kind = "STANCE", value = stance.id, category = "STANCES", classTag = group.classTag,
				name = stance.label, icon = stance.icon, description = CP:GetStanceTypeLabel() })
		end
	end
	for _, racial in ipairs(CP:GetPlayerRacialSpellEntries() or {}) do
		append({ key = "racial:" .. racial.spellID, kind = "RACIAL", value = racial.spellID, racialSlot = racial.racialSlot, category = "RACIALS",
			name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(racial.spellID), icon = racial.icon, description = L["CooldownPanelAddRacial"] })
	end
	if CP.Potions then
		for _, resource in ipairs({ "health", "mana", "bandage" }) do
			local definition = CP.Potions:GetDefinition(resource)
			if definition then
				append({ key = "potion:" .. resource, kind = "ITEM", value = definition.itemID, category = "SLOTS", name = L[definition.labelKey],
					icon = definition.icon, overrides = { potionResource = resource, showWhenEmpty = false }, description = CP:GetEntryTypeLabel("ITEM") })
			end
		end
	end
	self:AppendSource("MACRO", append)
	catalog = self:MergeCatalog(catalog)
	table.sort(catalog, function(a, b)
		local left, right = self.NormalizeSearch(a.name), self.NormalizeSearch(b.name)
		if left ~= right then return left < right end
		return a.key < b.key
	end)
	self.catalog = catalog
	return catalog
end

function Picker:MergeCatalog(catalog)
	local identities, merged = {}, {}
	for _, row in ipairs(catalog) do
		local identity, priority = row.key, 1
		if row.kind == "PRESET" and row.category ~= "SPECIAL" and row.spellID then
			local id = CP.GetCanonicalSpellRankID and CP:GetCanonicalSpellRankID(row.spellID) or row.spellID
			identity, priority = "aura:" .. id .. ":player", 3
		elseif row.kind == "CDM_AURA" then
			local family = CP.GetSpellRankFamily and CP:GetSpellRankFamily(row.value)
			local baseID = CP.GetCanonicalSpellRankID and CP:GetCanonicalSpellRankID(row.value) or row.value
			identity = "aura:" .. baseID .. ":" .. ((row.overrides or {}).auraUnit or "player")
			if family then for _, id in ipairs(family) do row.search = row.search .. " " .. id end end
		elseif row.kind == "SPELL" or row.kind == "INTERNAL" or row.kind == "RACIAL" then
			local id = CP.NormalizePersistentSpellID and CP:NormalizePersistentSpellID(row.value) or row.value
			identity = "spell:" .. tostring(id)
			priority = row.kind == "INTERNAL" and 3 or row.kind == "RACIAL" and 2 or 1
		end
		local old = identities[identity]
		if not old then
			row.priority = priority
			row.categories = { [row.category] = true }
			identities[identity] = row
			merged[#merged + 1] = row
		else
			old.categories[row.category] = true
			old.search = old.search .. " " .. row.search
			if old.kind == "CDM_AURA" and row.kind == "CDM_AURA" then
				local overrides, ids = {}, {}
				for key, value in pairs(old.overrides) do overrides[key] = value end
				for _, id in ipairs(old.overrides.cdmAuraOverlaySpellIDs) do ids[#ids + 1] = id end
				overrides.cdmAuraOverlaySpellIDs = ids
				old.overrides = overrides
				local seenIDs = {}
				for _, id in ipairs(ids) do seenIDs[id] = true end
				for _, id in ipairs(row.overrides.cdmAuraOverlaySpellIDs) do
					if not seenIDs[id] then seenIDs[id] = true; ids[#ids + 1] = id end
				end
			end
			if priority > old.priority then
				local categories, search = old.categories, old.search
				for key in pairs(old) do old[key] = nil end
				for key, value in pairs(row) do old[key] = value end
				old.categories, old.search, old.priority = categories, search, priority
			end
		end
	end
	return merged
end

function Picker:IsAdded(row)
	local panel = CP:GetPanel(self.targetId)
	if not panel then return true end
	if row.kind == "TOTEMS_ALL" then
		for slot = 1, (_G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4) do
			if not CP:FindEntryByValue(self.targetId, "TOTEM", slot) then return false end
		end
		return true
	end
	if row.kind == "PRESET" then return CP.AuraPresets:FindEntry(panel, row.value) ~= nil end
	if row.kind == "MACRO" then
		for _, entry in pairs(panel.entries or {}) do
			if entry.type == "MACRO" and tonumber(entry.macroID) == row.value then return true end
		end
		return false
	end
	local entryType = (row.kind == "INTERNAL" or row.kind == "RACIAL") and "SPELL" or row.kind
	return CP:FindEntryByValue(self.targetId, entryType, row.value, row.overrides) ~= nil
end

function Picker:Add(row)
	if not self:CanEdit() or not CP:GetPanel(self.targetId) or self:IsAdded(row) then return false end
	local added
	if row.kind == "TOTEMS_ALL" then
		added = CP:AddAllTotemEntries(self.targetId)
	elseif row.kind == "PRESET" then
		local stats = CP.AuraPresets:AddPreset(self.targetId, row.value)
		added = stats and (stats.added > 0 or stats.adopted > 0)
	elseif row.kind == "INTERNAL" then
		added = CP.AuraPresets:AddSpellCooldownPreset(self.targetId, row.value)
	elseif row.kind == "RACIAL" then
		added = CP:AddPlayerRacialEntry(self.targetId, row.value, row.racialSlot)
	elseif row.kind == "MACRO" then
		-- A macro can move or disappear while the picker is open. Refresh its
		-- identity on every add so a stale row cannot select a different macro.
		local currentName = GetMacroInfo and GetMacroInfo(row.value)
		if currentName ~= row.name then Shared:InvalidateSources({ "MACRO" }); self:Refresh(); return false end
		added = CP:AddEntrySafe(self.targetId, row.kind, row.value, { macroName = currentName })
	else
		local overrides = row.overrides
		if row.kind == "STANCE" then overrides = CP:GetStanceDefaultOverrides() end
		added = CP:AddEntrySafe(self.targetId, row.kind, row.value, overrides)
	end
	if added then
		CP:RefreshEditor()
		if CP.BlizzardEditor and CP.BlizzardEditor.RefreshPanel then CP.BlizzardEditor:RefreshPanel(self.targetId) end
	end
	self:Refresh()
	if self.frame then self.frame.status:SetText(added and string.format(L["CooldownPanelPickerAdded"], row.name) or L["CooldownPanelPickerAddFailed"]) end
	return added and true or false
end

function Picker:AddByID()
	if not self:CanEdit() then return false end
	local frame = self.frame
	local value = tonumber(frame.idInput:GetText())
	if not value or value <= 0 or value ~= math.floor(value) then frame.status:SetText(L["CooldownPanelPickerInvalidID"]); return false end
	local added = CP:AddEntrySafe(self.targetId, self.idType or "SPELL", value)
	if added then
		frame.idInput:SetText("")
		CP:RefreshEditor()
		if CP.BlizzardEditor and CP.BlizzardEditor.RefreshPanel then CP.BlizzardEditor:RefreshPanel(self.targetId) end
		frame.status:SetText(string.format(L["CooldownPanelPickerAdded"], tostring(value)))
	else
		frame.status:SetText(L["CooldownPanelPickerAddFailed"])
	end
	return added and true or false
end

function Picker:AppendTooltip(data)
	if data.kind == "RACIAL" then GameTooltip:AddLine(L["CooldownPanelPickerRacialTooltip"], 0.88, 0.87, 0.80, true) end
	if data.kind == "INTERNAL" then
		local definition = data.definition
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["CooldownPanelCustomDurationOnCooldown"], 1, 0.82, 0.40, true)
		GameTooltip:AddLine(data.description, 0.88, 0.87, 0.80, true)
		if definition.talentDuration then
			local talent = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(definition.talentDuration.spellID) or tostring(definition.talentDuration.spellID)
			GameTooltip:AddDoubleLine(talent, string.format(L["CooldownPanelPickerInternalCooldown"], definition.talentDuration.duration))
		end
		GameTooltip:AddDoubleLine(L["CooldownPanelActivationOverlayReverse"], definition.activationOverlayReverse and L["Enabled"] or L["Off"])
		GameTooltip:AddDoubleLine(L["CooldownPanelActivationOverlayDesaturate"], definition.activationOverlayDesaturate ~= false and L["Enabled"] or L["Off"])
	end
end

function CP:ShowAddEntryDialog(panelId) return Picker:Open(panelId) end
