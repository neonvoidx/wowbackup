local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end

local Panels = addon.Aura.CooldownPanels
local SG = Panels.SpellGroups
local Helper = Panels.helper
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Sync = { pending = {} }
SG.Sync = Sync

function Sync:ChangedValue(left, right)
	if _G.issecretvalue and (_G.issecretvalue(left) or _G.issecretvalue(right)) then return true end
	return left ~= right
end

function Sync:Canonical(spellID)
	spellID = Helper.GetPlainPositiveSpellId(spellID)
	if not spellID then return nil end
	return Panels:NormalizePersistentSpellID(spellID, { allowTalentChoiceCanonical = true }) or spellID
end

function Sync:Key(entry, canonicalMap)
	if entry and entry.type == "CDM_AURA" then
		local spellID = Helper.GetPlainPositiveSpellId(entry.auraSpellID or entry.spellID)
		if not spellID then return nil end
		local key = "AURA:" .. spellID
		return key, spellID, key
	end
	if entry and entry.type == "ITEM" then
		local potionResource = Panels.Potions and Panels.Potions:GetEntryResource(entry)
		if potionResource then
			local key = "POTION:" .. potionResource
			return key, entry.itemID, key
		end
		local itemID = Helper.GetPlainPositiveSpellId(entry.itemID)
		if not itemID then return nil end
		local canonical = (Panels.GetCanonicalItemRankID and Panels:GetCanonicalItemRankID(itemID)) or itemID
		local key = "ITEM:" .. canonical
		return key, canonical, key
	end
	local spellID = entry and Helper.GetPlainPositiveSpellId(entry.auraSpellID or entry.spellID)
	local canonical = spellID and canonicalMap and canonicalMap[spellID]
	canonical = canonical or (entry and Helper.GetPlainPositiveSpellId(entry.spellGroupCanonicalSpellID)) or self:Canonical(spellID)
	if not canonical then return nil end
	if Panels.GetCanonicalSpellRankID then canonical = Panels:GetCanonicalSpellRankID(canonical) or canonical end
	return "SPELL:" .. canonical, canonical, "SPELL:" .. canonical
end

function Sync:IsManaged(entry)
	return entry and (entry.spellGroupSyncManaged == true or entry.cdmSyncManaged == true)
end

function Sync:NormalizeRankOverrides(panel)
	local bucket = panel.spellGroupEntryOverrides
	if not (Panels.GetCanonicalSpellRankID and type(bucket) == "table") then return end
	local keys = {}
	for key in pairs(bucket) do if type(key) == "string" then keys[#keys + 1] = key end end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local kind, spellID = key:match("^([A-Z]+):(%d+)$")
		if kind == "SPELL" then
			local canonical = Panels:GetCanonicalSpellRankID(tonumber(spellID))
			local canonicalKey = canonical and (kind .. ":" .. canonical)
			if canonicalKey and canonicalKey ~= key and bucket[canonicalKey] == nil then bucket[canonicalKey] = Helper.CopyTableDeep(bucket[key]) end
		end
	end
end

function Sync:SaveOverride(panel, entry, canonicalMap)
	local key = self:Key(entry, canonicalMap)
	if not key then return end
	panel.spellGroupEntryOverrides = panel.spellGroupEntryOverrides or {}
	local saved = Helper.CopyTableDeep(entry)
	for _, field in ipairs({ "id", "type", "spellID", "itemID", "auraSpellID", "cooldownID", "buffName", "iconTextureID", "sourceType", "sourceViewer",
		"cdmSyncManaged", "cdmSyncSource", "cdmSyncKey", "cdmSyncSpecKey", "cdmSyncCooldownID", "spellGroupSyncManaged", "spellGroupCanonicalSpellID", "spellGroupCanonicalItemID" }) do saved[field] = nil end
	panel.spellGroupEntryOverrides[key] = saved
end

function Sync:CollectCDM(panel)
	local source = panel.cdmSyncSource
	if not source then return {} end
	if source == "BUFF_ICON" then
		local auras = Panels.CDMAuras
		if not (auras and auras.ScanTrackedBuffs and _G.BuffIconCooldownViewer) then return nil, "SOURCE_NOT_FOUND" end
		local result = {}
		for _, info in ipairs(auras:ScanTrackedBuffs(true, "icon") or {}) do
			local spellID = Helper.GetPlainPositiveSpellId(info.spellID)
			local cooldownID = Helper.GetPlainPositiveSpellId(info.cooldownID)
			if spellID and cooldownID and info.iconFrame and info.availableSources and info.availableSources.icon then
				result[#result + 1] = { type = "CDM_AURA", spellID = spellID, cooldownID = cooldownID,
					buffName = info.buffName, iconTextureID = info.iconTextureID, sourceType = "icon", sourceViewer = "BuffIconCooldownViewer" }
			end
		end
		return result
	end
	local spells, _, reason = Panels:GetSpellGroupCDMSource(source)
	if reason then return nil, reason end
	local result = {}
	for _, info in ipairs(spells or {}) do
		local spellID = Helper.GetPlainPositiveSpellId(type(info) == "table" and info.spellID or info)
		if spellID then
			result[#result + 1] = { type = "SPELL", spellID = spellID,
				cooldownID = type(info) == "table" and Helper.GetPlainPositiveSpellId(info.cooldownID) or nil }
		end
	end
	return result
end

function Sync:UsesPanel(panel)
	return panel and (panel.spellGroupSyncVersion == 1 or (type(panel.spellGroupIDs) == "table" and #panel.spellGroupIDs > 0))
end

function Sync:PruneBarGroupLinks(panel, refs)
	if type(panel.spellGroupBarGroups) ~= "table" then panel.spellGroupBarGroups = nil; return end
	local selected = {}; for _, id in ipairs(refs or panel.spellGroupIDs or {}) do selected[id] = true end
	for id, side in pairs(panel.spellGroupBarGroups) do
		if not selected[id] or type(side) ~= "number" or side < 1 or side > 4 or side ~= math.floor(side) then panel.spellGroupBarGroups[id] = nil end
	end
	if not next(panel.spellGroupBarGroups) then panel.spellGroupBarGroups = nil end
end
function Sync:BarGroupDestinations(panel, canonicalMap)
	local result, owners, groups = {}, {}, Panels.BarGroups
	if not (groups and groups.Enabled(panel.layout) and type(panel.spellGroupBarGroups) == "table") then return result, owners end
	for _, id in ipairs(panel.spellGroupIDs or {}) do
		local target = panel.spellGroupBarGroups[id]
		if target and groups.Find(panel.layout, target) then
			for _, member in ipairs(SG:ResolveGroups({ id }, canonicalMap)) do
				local key = self:Key(member, canonicalMap)
				if key and not result[key] then result[key], owners[key] = target, id end
			end
		end
	end
	return result, owners
end
function Sync:BarGroupDestination(entry, destinations, canonicalMap)
	local key = self:Key(entry, canonicalMap)
	if key and destinations[key] then return destinations[key] end
	if entry.type == "CDM_AURA" then
		local spell = Helper.GetPlainPositiveSpellId(entry.auraSpellID or entry.spellID)
		local canonical = spell and (canonicalMap[spell] or self:Canonical(spell))
		if canonical and Panels.GetCanonicalSpellRankID then canonical = Panels:GetCanonicalSpellRankID(canonical) or canonical end
		return canonical and destinations["SPELL:" .. canonical]
	end
end

-- Editor locks use the same identities and overlap precedence as reconciliation.
function Sync:GetBarGroupBinding(panel, entry)
	if not (panel and entry and type(panel.spellGroupBarGroups) == "table") then return end
	local canonicalMap = SG:GetCanonicalSpellMap(panel.spellGroupIDs or {})
	local destinations, owners = self:BarGroupDestinations(panel, canonicalMap)
	return self:BarGroupDestination(entry, destinations, canonicalMap), self:BarGroupDestination(entry, owners, canonicalMap)
end

function Sync:Reconcile(panelId)
	local panel = Panels:GetPanel(panelId)
	if not self:UsesPanel(panel) then return end
	if InCombatLockdown() then self.pending[panelId] = true; return nil, "combat" end
	local candidates, reason = self:CollectCDM(panel)
	if not candidates then return nil, reason end
	self:NormalizeRankOverrides(panel)
	panel.spellGroupSyncVersion = 1
	panel.entries, panel.order = panel.entries or {}, panel.order or {}
	Helper.SyncOrder(panel.order, panel.entries)
	local previousOrder = panel.order
	local wanted, seen, manual, available = {}, {}, {}, {}
	local canonicalMap = SG:GetCanonicalSpellMap(panel.spellGroupIDs or {})
	local destinations = self:BarGroupDestinations(panel, canonicalMap)
	local routingChanged = false
	local cdmCount = #candidates
	-- Keep the existing CDM-source precedence over matching spell-group casts.
	-- Explicit aura members have their own identity and can coexist with casts.
	local cdmAuraSpells = {}
	for _, candidate in ipairs(candidates) do
		if candidate.type == "CDM_AURA" then
			local canonical = canonicalMap[candidate.spellID] or self:Canonical(candidate.spellID)
			if Panels.GetCanonicalSpellRankID then canonical = Panels:GetCanonicalSpellRankID(canonical) or canonical end
			if canonical then
				candidate.legacySpellIdentity = "SPELL:" .. canonical
				cdmAuraSpells[candidate.legacySpellIdentity] = true
			end
		end
	end
	for _, member in ipairs(SG:ResolveGroups(panel.spellGroupIDs or {}, canonicalMap)) do
		if member.type == "ITEM" then
			candidates[#candidates + 1] = { type = "ITEM", itemID = member.itemID, useHighestRank = member.useHighestRank,
				spellGroupCanonicalItemID = member.canonicalItemID }
		elseif member.type == "CDM_AURA" then
			candidates[#candidates + 1] = { type = "CDM_AURA", spellID = member.spellID }
		else
			candidates[#candidates + 1] = { type = "SPELL", spellID = member.spellID, spellGroupCanonicalSpellID = member.canonicalSpellID }
		end
	end
	for index, candidate in ipairs(candidates) do
		local key, canonical, identity = self:Key(candidate, canonicalMap)
		if key and not seen[identity] and not (index > cdmCount and candidate.type == "SPELL" and cdmAuraSpells[identity]) then
			candidate.key, candidate.canonical, candidate.identity = key, canonical, identity
			if candidate.type == "SPELL" and Panels.GetCanonicalSpellRankID then candidate.spellID = Panels:GetCanonicalSpellRankID(candidate.spellID) or candidate.spellID end
			candidate.fromCDM = index <= cdmCount
			seen[identity] = true
			wanted[#wanted + 1] = candidate
		end
	end
	local oldManaged, nextEntryId = {}, Helper.GetNextNumericId(panel.entries)
	for _, entryId in ipairs(previousOrder) do
		local entry = panel.entries[entryId]
		local key, _, identity = self:Key(entry, canonicalMap)
		if self:IsManaged(entry) then
			self:SaveOverride(panel, entry, canonicalMap)
			oldManaged[entryId] = entry
			if key and not available[key] then available[key] = entry end
		else
			local destination = self:BarGroupDestination(entry, destinations, canonicalMap)
			if destination and entry.barGroupId ~= destination then entry.barGroupId = destination; routingChanged = true end
			manual[#manual + 1] = entryId
			if identity and (entry.type == "SPELL" or entry.type == "CDM_AURA" or entry.type == "ITEM") then
				seen[identity] = "manual"
			end
			if entry.type == "CDM_AURA" then
				local spellID = Helper.GetPlainPositiveSpellId(entry.auraSpellID or entry.spellID)
				local canonical = spellID and (canonicalMap[spellID] or self:Canonical(spellID))
				if canonical and Panels.GetCanonicalSpellRankID then canonical = Panels:GetCanonicalSpellRankID(canonical) or canonical end
				if canonical then seen["SPELL:" .. canonical] = "manual" end
			end
		end
	end
	-- Allocate managed slots in source order, keeping manual entries and reusing entry IDs.
	-- This also lets an earlier group take a freed slot when a fixed grid is full.
	for id in pairs(oldManaged) do panel.entries[id] = nil end
	panel.order = Helper.CopyTableDeep(manual)
	Helper.InvalidateFixedLayoutCache(panel)
	local added, removed, changed = 0, 0, routingChanged
	for _, candidate in ipairs(wanted) do
		if seen[candidate.identity] ~= "manual" and not (candidate.legacySpellIdentity and seen[candidate.legacySpellIdentity] == "manual") then
			local entry = available[candidate.key]
			local saved = entry or (panel.spellGroupEntryOverrides and panel.spellGroupEntryOverrides[candidate.key])
			if not saved and candidate.fromCDM and candidate.type == "CDM_AURA" then
				-- Older CDM aura overrides used the corresponding cast/rank identity.
				local legacyID = canonicalMap[candidate.spellID] or self:Canonical(candidate.spellID)
				if Panels.GetCanonicalSpellRankID then legacyID = Panels:GetCanonicalSpellRankID(legacyID) or legacyID end
				saved = legacyID and panel.spellGroupEntryOverrides and panel.spellGroupEntryOverrides["AURA:" .. legacyID]
			end
			if not saved and candidate.fromCDM then
				local oldBucket = panel.cdmSyncEntryOverrides and panel.cdmSyncEntryOverrides[panel.cdmSyncSource]
				local oldKey = candidate.type == "CDM_AURA" and candidate.cooldownID or self:Canonical(candidate.spellID)
				saved = oldBucket and oldBucket[tostring(oldKey)]
			end
			local overrides, addError = saved, nil
			if Panels.ResolveFixedEntryAddOverrides then
				overrides, addError = Panels:ResolveFixedEntryAddOverrides(panel, saved)
			elseif Panels.GetFixedEntryAddError then addError = Panels:GetFixedEntryAddError(panel, nil) end
			if not addError then
				if not entry then
					while panel.entries[nextEntryId] or oldManaged[nextEntryId] do nextEntryId = nextEntryId + 1 end
					entry = Helper.CreateEntry(candidate.type, candidate.type == "CDM_AURA" and candidate or candidate.itemID or candidate.spellID, Panels:GetRoot().defaults)
					entry.id = nextEntryId
					nextEntryId, added = nextEntryId + 1, added + 1
					if candidate.type == "ITEM" then entry.useHighestRank = candidate.useHighestRank == true end
				end
				if overrides and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) then
					for _, field in ipairs({ "fixedGroupId", "slotColumn", "slotRow", "slotIndex" }) do
						if entry[field] ~= overrides[field] then changed = true end
						entry[field] = overrides[field]
					end
				end
				if overrides and overrides ~= entry then
					for field, value in pairs(overrides) do
						if field ~= "id" then
							if (field == "slotColumn" or field == "slotRow" or field == "fixedGroupId") and entry[field] ~= value then changed = true end
							entry[field] = Helper.CopyTableDeep(value)
						end
					end
				end
				local destination = self:BarGroupDestination(candidate, destinations, canonicalMap)
				if destination and entry.barGroupId ~= destination then entry.barGroupId = destination; changed = true end
				if entry.spellID ~= candidate.spellID or entry.itemID ~= candidate.itemID or entry.cdmSyncCooldownID ~= (candidate.fromCDM and candidate.cooldownID or nil)
					or entry.cdmSyncSource ~= (candidate.fromCDM and panel.cdmSyncSource or nil) then changed = true end
				entry.spellID, entry.itemID = candidate.spellID, candidate.itemID
				entry.spellGroupCanonicalSpellID = candidate.type ~= "ITEM" and candidate.canonical or nil
				entry.spellGroupCanonicalItemID = candidate.type == "ITEM" and candidate.canonical or nil
				entry.spellGroupSyncManaged = true
				entry.cdmSyncManaged = candidate.fromCDM or nil
				entry.cdmSyncSource = candidate.fromCDM and panel.cdmSyncSource or nil
				entry.cdmSyncKey = candidate.fromCDM and (candidate.type == "CDM_AURA" and tostring(candidate.cooldownID) or candidate.canonical) or nil
				entry.cdmSyncCooldownID = candidate.fromCDM and candidate.cooldownID or nil
				if candidate.type == "CDM_AURA" then
					if entry.auraSpellID ~= candidate.spellID then changed = true end
					entry.auraSpellID = candidate.spellID
					entry.cooldownID = candidate.cooldownID
					if candidate.fromCDM then
						for _, field in ipairs({ "buffName", "iconTextureID", "sourceType", "sourceViewer" }) do
							if self:ChangedValue(entry[field], candidate[field]) then changed = true end
						end
						entry.buffName, entry.iconTextureID = candidate.buffName, candidate.iconTextureID
						entry.sourceType, entry.sourceViewer = candidate.sourceType, candidate.sourceViewer
					end
				end
				panel.entries[entry.id] = entry
				panel.order[#panel.order + 1] = entry.id
				Helper.InvalidateFixedLayoutCache(panel)
			end
		end
	end
	for id in pairs(oldManaged) do if not panel.entries[id] then removed = removed + 1 end end
	if #previousOrder ~= #panel.order then changed = true end
	for index, id in ipairs(panel.order) do if previousOrder[index] ~= id then changed = true; break end end
	if added > 0 or removed > 0 or changed then
		Panels:RebuildSpellIndex()
		Panels:RefreshPanel(panelId)
		if Panels.BlizzardEditor then Panels.BlizzardEditor:RefreshPanel(panelId) end
	end
	return { added = added, removed = removed }
end

function SG:GetReferencingPanels(groupId)
	local root, result = Panels:GetRoot(), {}
	for _, panelId in ipairs(root and root.order or {}) do
		local panel = root.panels[panelId]
		for _, id in ipairs(panel and panel.spellGroupIDs or {}) do
			if id == groupId then result[#result + 1] = { id = panelId, name = panel.name }; break end
		end
	end
	return result
end

function Sync:Request(panelId)
	if panelId then self.pending[panelId] = true
	else
		local root = Panels:GetRoot()
		for id, panel in pairs(root and root.panels or {}) do if self:UsesPanel(panel) then self.pending[id] = true end end
	end
	self:Schedule()
end

function Sync:Schedule()
	if self.queued or InCombatLockdown() then return end
	self.queued = true
	RunNextFrame(function()
		Sync.queued = nil
		if InCombatLockdown() then return end
		local queue = Sync.pending
		Sync.pending = {}
		for id in pairs(queue) do Sync:Reconcile(id) end
		local editor = Panels.SpellGroupsEditor
		if editor and editor.frame and editor.frame:IsShown() then editor:Refresh() end
	end)
end

function SG:NotifyChanged(groupIDs)
	local changed = {}
	for _, id in ipairs(groupIDs or self:GetGroupIDs()) do changed[id] = true end
	local root = Panels:GetRoot()
	for panelId, panel in pairs(root and root.panels or {}) do
		local touched, refs = false, {}
		for _, id in ipairs(panel.spellGroupIDs or {}) do
			if changed[id] then touched = true end
			if self:GetGroup(id) then refs[#refs + 1] = id else touched = true end
		end
		if touched then panel.spellGroupIDs = refs; Sync.pending[panelId] = true end
		Sync:PruneBarGroupLinks(panel)
	end
	Sync:Schedule()
end

function SG:SetPanelGroups(panelId, groupIDs)
	if InCombatLockdown() then return nil, "combat" end
	local panel = Panels:GetPanel(panelId)
	if not panel then return nil, "missing_panel" end
	local refs, seen = {}, {}
	for _, id in ipairs(groupIDs or {}) do
		if self:GetGroup(id) and not seen[id] then refs[#refs + 1] = id; seen[id] = true end
	end
	panel.spellGroupIDs, panel.spellGroupSyncVersion = refs, 1
	Sync:PruneBarGroupLinks(panel, refs)
	if panel.cdmSyncSource then Panels:EnsureCooldownManagerSyncListener() end
	Sync:Request(panelId)
	return true
end

function SG:SetBarGroupGroups(panelId, side, groupIDs)
	if InCombatLockdown() then return nil, "combat" end
	local panel = Panels:GetPanel(panelId)
	local bars = Panels.BarGroups
	if not (panel and bars and bars.Enabled(panel.layout) and bars.Find(panel.layout, side)) then return nil, "missing_panel" end
	local selected, order = {}, {}
	for _, id in ipairs(groupIDs or {}) do if self:GetGroup(id) and not selected[id] then selected[id] = true; order[#order + 1] = id end end
	local bindings, refs, seen = panel.spellGroupBarGroups or {}, {}, {}
	for _, id in ipairs(panel.spellGroupIDs or {}) do
		if bindings[id] ~= side or selected[id] then refs[#refs + 1] = id; seen[id] = true end
		if bindings[id] == side and not selected[id] then bindings[id] = nil end
	end
	for _, id in ipairs(order) do
		bindings[id] = side
		if not seen[id] then refs[#refs + 1] = id; seen[id] = true end
	end
	panel.spellGroupBarGroups = bindings
	return self:SetPanelGroups(panelId, refs)
end

function SG:AppendPanelMenu(root, panelId)
	local panel = Panels:GetPanel(panelId)
	if not panel then return end
	local menu = root:CreateButton(L["CDLSpellGroupsSync"])
	local ids = self:GetGroupIDs()
	if #ids == 0 then menu:CreateTitle(L["CDLSpellGroupsNoGroups"]) end
	for _, id in ipairs(ids) do
		local group = self:GetGroup(id)
		menu:CreateCheckbox(group.name, function()
			for _, linked in ipairs(panel.spellGroupIDs or {}) do if linked == id then return true end end
			return false
		end, function()
			local refs, found = {}, false
			for _, linked in ipairs(panel.spellGroupIDs or {}) do
				if linked == id then found = true else refs[#refs + 1] = linked end
			end
			if not found then refs[#refs + 1] = id end
			SG:SetPanelGroups(panelId, refs)
		end)
	end
	if #(panel.spellGroupIDs or {}) > 1 then
		local orderMenu = menu:CreateButton(L["CDLSpellGroupsSyncOrder"])
		for index, id in ipairs(panel.spellGroupIDs) do
			local group = self:GetGroup(id)
			if group then
				local entry = orderMenu:CreateButton(group.name)
				for _, delta in ipairs({ -1, 1 }) do
					if index + delta >= 1 and index + delta <= #panel.spellGroupIDs then
						entry:CreateButton(L[delta == -1 and "CDLSpellGroupsMoveUp" or "CDLSpellGroupsMoveDown"], function()
							local refs = Helper.CopyTableDeep(panel.spellGroupIDs)
							refs[index], refs[index + delta] = refs[index + delta], refs[index]
							SG:SetPanelGroups(panelId, refs)
						end)
					end
				end
			end
		end
	end
	menu:CreateDivider()
	menu:CreateButton(L["CDLSpellGroupsOpenEditor"], function() Panels:OpenSpellGroupsEditor() end)
end

function SG:ExportGroups(groupIDs)
	return Panels:EncodeSpellGroupsPayload(self:SerializeGroups(groupIDs or self:GetGroupIDs()))
end

function SG:ImportEncodedGroups(encoded)
	if InCombatLockdown() then return nil, "combat" end
	local payload, reason = Panels:DecodeSpellGroupsPayload(encoded)
	if not payload then return nil, reason end
	return self:ImportGroups(payload)
end

function SG:ExportPanelDependencies(panels)
	local ids, seen = {}, {}
	for _, panel in pairs(panels or {}) do
		for _, id in ipairs(panel.spellGroupIDs or {}) do
			if not seen[id] then ids[#ids + 1] = id; seen[id] = true end
		end
	end
	if #ids > 0 then return self:SerializeGroups(ids) end
end

function SG:PreparePanelImport(data)
	if type(data) ~= "table" then return nil, "NO_DATA" end
	local copy = Helper.CopyTableDeep(data)
	local panels = copy.panel and { copy.panel } or copy.panels
	if type(panels) ~= "table" then return copy end
	local hasRefs, count = false, 0
	for _, panel in pairs(panels) do
		if type(panel) ~= "table" then return nil, "invalid_bundle" end
		local refs = panel.spellGroupIDs
		if refs ~= nil then
			if type(refs) ~= "table" or #refs > 200 then return nil, "invalid_bundle" end
			local size, seen = 0, {}
			for key, id in pairs(refs) do
				if type(key) ~= "number" or key < 1 or key > #refs or key ~= math.floor(key) or type(id) ~= "string" or seen[id] then return nil, "invalid_bundle" end
				size, seen[id] = size + 1, true
			end
			if size ~= #refs then return nil, "invalid_bundle" end
			if size > 0 then hasRefs = true end
		end
		local bindings = panel.spellGroupBarGroups
		if bindings ~= nil then
			if type(bindings) ~= "table" then return nil, "invalid_bundle" end
			local linked = {}; for _, id in ipairs(refs or {}) do linked[id] = true end
			for id, side in pairs(bindings) do
				if not linked[id] or type(side) ~= "number" or side < 1 or side > 4 or side ~= math.floor(side) then return nil, "invalid_bundle" end
			end
		end
		count = count + 1
	end
	if not hasRefs then return copy end
	if InCombatLockdown() then return nil, "combat" end
	if type(copy.spellGroups) ~= "table" or type(copy.spellGroups.groups) ~= "table" then return nil, "invalid_bundle" end
	-- Validate panel structures before creating their referenced groups.
	if not copy.panel then
		if type(copy.panelOrder) ~= "table" or #copy.panelOrder ~= count then return nil, "invalid_bundle" end
		local seen = {}
		for _, id in ipairs(copy.panelOrder) do
			if not panels[id] or seen[id] then return nil, "invalid_bundle" end
			seen[id] = true
		end
	end
	for _, panel in pairs(panels) do
		if type(panel.entries) ~= "table" or type(panel.order) ~= "table" then return nil, "invalid_bundle" end
		for _, entry in pairs(panel.entries) do if type(entry) ~= "table" then return nil, "invalid_bundle" end end
		for _, id in ipairs(panel.spellGroupIDs or {}) do
			if not copy.spellGroups.groups[id] then return nil, "invalid_bundle" end
		end
	end
	local mapping, reason = self:ImportGroups(copy.spellGroups)
	if not mapping then return nil, reason end
	for _, panel in pairs(panels) do
		local refs = {}
		for _, id in ipairs(panel.spellGroupIDs or {}) do refs[#refs + 1] = mapping[id] end
		panel.spellGroupIDs = refs
		if panel.spellGroupBarGroups then
			local bindings = {}
			for id, side in pairs(panel.spellGroupBarGroups) do bindings[mapping[id]] = side end
			panel.spellGroupBarGroups = bindings
		end
	end
	return copy
end

Sync.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "PLAYER_REGEN_ENABLED", "ADDON_LOADED" }) do
	if not _G.C_EventUtils or _G.C_EventUtils.IsEventValid(event) then Sync.events:RegisterEvent(event) end
end
Sync.events:RegisterUnitEvent("UNIT_PET", "player")
Sync.events:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name ~= "Blizzard_CooldownViewer" and name ~= "EnhanceQoLCooldownPanels" then return end
	if (event == "SPELLS_CHANGED" or event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD") and Panels.InvalidateLearnedSpellRanks then Panels:InvalidateLearnedSpellRanks() end
	if event ~= "ADDON_LOADED" and event ~= "PLAYER_REGEN_ENABLED" and Panels.InvalidateSpellQueryCaches then Panels:InvalidateSpellQueryCaches() end
	Sync:Request()
end)
