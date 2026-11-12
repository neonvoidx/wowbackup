local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CP = addon.Aura.CooldownPanels
CP.SpellGroups = CP.SpellGroups or {}
local SG = CP.SpellGroups
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local M = { MAX_GROUPS = 200, MAX_MEMBERS = 1000, MAX_IMPORT_MEMBERS = 20000 }

function M.plain(value) return not (_G.issecretvalue and _G.issecretvalue(value)) end
function M.number(value)
	if not M.plain(value) then return nil end
	local number = tonumber(value)
	if number and number > 0 and number < 2147483647 and number == math.floor(number) then return number end
end
function M.key(value) return M.plain(value) and type(value) == "string" and #value > 0 and #value <= 96 and not value:find("[%c]") end
function M.name(value)
	if not (M.plain(value) and type(value) == "string") then return nil end
	value = value:match("^%s*(.-)%s*$")
	if #value == 0 or #value > 128 or value:find("[%c]") then return nil end
	return value
end
function M.array(value, maximum)
	if type(value) ~= "table" or getmetatable(value) then return false end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key > maximum or key ~= math.floor(key) then return false end
		count = count + 1
	end
	return count == #value and count <= maximum
end
function M.copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = M.copy(child) end
	return result
end
function M.spellCanonical(spellID)
	return M.number(CP.GetCanonicalSpellRankID and CP:GetCanonicalSpellRankID(spellID)) or spellID
end
function M.member(value, key)
	if type(value) ~= "table" or getmetatable(value) then return nil end
	if value.type ~= nil and value.type ~= "SPELL" and value.type ~= "ITEM" and value.type ~= "CDM_AURA" then return nil end
	local isItem = value.type == "ITEM"
	local id = M.number(isItem and value.itemID or value.spellID)
	if not id or (isItem and value.spellID ~= nil) or (not isItem and value.itemID ~= nil) then return nil end
	local result = isItem and { key = key, type = "ITEM", itemID = id } or { key = key, spellID = M.spellCanonical(id) }
	if value.type == "CDM_AURA" then
		-- Aura IDs identify effects, not learned casts or replacement spells.
		result.type, result.spellID = "CDM_AURA", id
		for _, field in ipairs({ "canonicalSpellID", "aliases", "excludeIfKnown", "pet", "dispelKind", "useHighestRank" }) do
			if value[field] ~= nil then return nil end
		end
	end
	if isItem then
		for _, field in ipairs({ "canonicalSpellID", "aliases", "excludeIfKnown", "pet", "dispelKind" }) do if value[field] ~= nil then return nil end end
		if value.useHighestRank ~= nil and type(value.useHighestRank) ~= "boolean" then return nil end
		result.useHighestRank = value.useHighestRank
	elseif value.useHighestRank ~= nil then return nil end
	for _, field in ipairs({ "classID", "canonicalSpellID" }) do
		if value[field] ~= nil then
			result[field] = M.number(value[field])
			if not result[field] or (field == "classID" and result[field] > 30) then return nil end
			if field == "canonicalSpellID" then result[field] = M.spellCanonical(result[field]) end
		end
	end
	for _, field in ipairs({ "specIDs", "aliases", "excludeIfKnown" }) do
		if value[field] ~= nil then
			if not M.array(value[field], 100) then return nil end
			local seen = {}
			result[field] = {}
			for _, id in ipairs(value[field]) do
				id = M.number(id)
				if not id then return nil end
				if not seen[id] then result[field][#result[field] + 1], seen[id] = id, true end
			end
		end
	end
	if value.pet ~= nil and type(value.pet) ~= "boolean" then return nil end
	result.pet = value.pet == true or nil
	if value.dispelKind ~= nil then
		if not M.key(value.dispelKind) then return nil end
		result.dispelKind = value.dispelKind
	end
	return result
end
function M.itemCanonical(itemID)
	return M.number(CP.GetCanonicalItemRankID and CP:GetCanonicalItemRankID(itemID)) or itemID
end
function M.identity(member)
	if member.type == "CDM_AURA" then return "AURA:" .. member.spellID end
	if member.type == "ITEM" then return "ITEM:" .. M.itemCanonical(member.itemID) end
	return "SPELL:" .. M.spellCanonical(member.spellID)
end
function M.preset(id) return SG.Presets and SG.Presets.byID and SG.Presets.byID[id] end
function M.mutable() return not (InCombatLockdown and InCombatLockdown()) end
function M.remove(order, key)
	for i = #order, 1, -1 do if order[i] == key then table.remove(order, i) end end
end
function M.insert(order, key, beforeKey)
	M.remove(order, key)
	if beforeKey then
		for i, current in ipairs(order) do
			if current == beforeKey then table.insert(order, i, key); return end
		end
	end
	order[#order + 1] = key
end
function M.materializeOrder(group)
	local seen = {}
	for _, key in ipairs(group.order) do seen[key] = true end
	for _, member in ipairs(SG:GetMembers(group.id)) do
		if not seen[member.key] then group.order[#group.order + 1], seen[member.key] = member.key, true end
	end
end

function SG:GetRoot()
	if not addon.db then return nil end
	addon.db.cooldownPanels = addon.db.cooldownPanels or {}
	local owner = addon.db.cooldownPanels
	if type(owner.spellGroups) ~= "table" then owner.spellGroups = { version = 1, groups = {}, order = {}, nextID = 1 } end
	local root = owner.spellGroups
	root.groups = type(root.groups) == "table" and root.groups or {}
	root.order = type(root.order) == "table" and root.order or {}
	root.nextID = M.number(root.nextID) or 1
	if M.normalizedRoot ~= root then
		for _, group in pairs(root.groups) do
			if type(group) == "table" and type(group.additions) == "table" then
				for _, member in pairs(group.additions) do
					if type(member) == "table" and member.type ~= "ITEM" and member.type ~= "CDM_AURA" then
						member.spellID = M.spellCanonical(member.spellID)
						if member.canonicalSpellID then member.canonicalSpellID = M.spellCanonical(member.canonicalSpellID) end
					end
				end
			end
		end
		M.normalizedRoot = root
	end
	return root
end
function SG:GetGroup(id)
	local root = self:GetRoot()
	return root and root.groups[id] or nil
end
function SG:GetGroupIDs()
	local root, result = self:GetRoot(), {}
	if root then for _, id in ipairs(root.order) do if root.groups[id] then result[#result + 1] = id end end end
	return result
end
function SG:GetMembers(id)
	local group = self:GetGroup(id)
	if not group then return {} end
	local members, defaults, seen, result = {}, {}, {}, {}
	local preset = M.preset(group.presetID)
	for _, source in ipairs(preset and preset.members or {}) do
		if not group.exclusions[source.key] then
			local member = M.copy(source)
			member.preset, member.presetID = true, group.presetID
			members[member.key], defaults[#defaults + 1] = member, member.key
		end
	end
	for key, source in pairs(group.additions) do members[key] = M.copy(source) end
	local function append(key)
		if members[key] and not seen[key] then result[#result + 1], seen[key] = members[key], true end
	end
	for _, key in ipairs(group.order) do append(key) end
	for _, key in ipairs(defaults) do append(key) end
	local remaining = {}
	for key in pairs(group.additions) do if not seen[key] then remaining[#remaining + 1] = key end end
	table.sort(remaining)
	for _, key in ipairs(remaining) do append(key) end
	return result
end
function SG:NotifyChanged() end
function M.allocate(root, group)
	local id
	repeat
		id = "group:" .. root.nextID
		root.nextID = root.nextID + 1
	until not root.groups[id]
	group.id = id
	root.groups[id], root.order[#root.order + 1] = group, id
	return id
end
function SG:CreateGroup(name, presetID)
	if not M.mutable() then return nil, "combat" end
	local preset = presetID and M.preset(presetID)
	if presetID and not preset then return nil, "invalid_preset" end
	name = M.name(name or (preset and L[preset.nameKey]) or L.CDLSpellGroupsNewGroup)
	if not name then return nil, "invalid_name" end
	local root = self:GetRoot()
	if not root or #root.order >= M.MAX_GROUPS then return nil, "limit" end
	local group = { name = name, presetID = presetID, additions = {}, exclusions = {}, order = {}, nextMemberID = 1 }
	for _, member in ipairs(preset and preset.members or {}) do group.order[#group.order + 1] = member.key end
	local id = M.allocate(root, group)
	self:NotifyChanged({ id })
	return id
end
function SG:RenameGroup(id, name)
	if not M.mutable() then return nil, "combat" end
	local group = self:GetGroup(id)
	if not group then return nil, "missing_group" end
	name = M.name(name)
	if not name then return nil, "invalid_name" end
	group.name = name
	self:NotifyChanged({ id })
	return true
end
function SG:DuplicateGroup(id)
	if not M.mutable() then return nil, "combat" end
	local group, root = self:GetGroup(id), self:GetRoot()
	if not group then return nil, "missing_group" end
	if #root.order >= M.MAX_GROUPS then return nil, "limit" end
	local copy = M.copy(group)
	copy.name = M.name(string.format(L.CDLSpellGroupsCopyName, group.name)) or group.name
	local newID = M.allocate(root, copy)
	self:NotifyChanged({ newID })
	return newID
end
function SG:DeleteGroup(id)
	if not M.mutable() then return nil, "combat" end
	local root = self:GetRoot()
	if not (root and root.groups[id]) then return nil, "missing_group" end
	root.groups[id] = nil
	M.remove(root.order, id)
	self:NotifyChanged({ id })
	return true
end
function SG:ResetPreset(id)
	if not M.mutable() then return nil, "combat" end
	local group = self:GetGroup(id)
	if not group then return nil, "missing_group" end
	local preset = M.preset(group.presetID)
	if not preset then return nil, "invalid_preset" end
	group.additions, group.exclusions, group.order, group.nextMemberID = {}, {}, {}, 1
	for _, member in ipairs(preset.members) do group.order[#group.order + 1] = member.key end
	self:NotifyChanged({ id })
	return true
end
function M.add(group, member, beforeKey)
	local members = SG:GetMembers(group.id)
	if #members >= M.MAX_MEMBERS then return nil, "limit" end
	local identity = M.identity(member)
	for _, current in ipairs(members) do if M.identity(current) == identity then return nil, member.type == "ITEM" and "duplicate_item" or "duplicate_spell" end end
	M.materializeOrder(group)
	local key
	local preset = M.preset(group.presetID)
	for _, source in ipairs(preset and preset.members or {}) do
		if M.identity(source) == identity then key = source.key; group.exclusions[key] = nil; break end
	end
	if not key then
		repeat
			key = "custom:" .. group.nextMemberID
			group.nextMemberID = group.nextMemberID + 1
		until not group.additions[key]
		member.key = key
		group.additions[key] = member
	end
	M.insert(group.order, key, beforeKey)
	return key
end
function SG:AddMember(id, value, beforeKey)
	if not M.mutable() then return nil, "combat" end
	local group = self:GetGroup(id)
	if not group then return nil, "missing_group" end
	local member = M.member(value)
	if not member then return nil, type(value) == "table" and value.type == "ITEM" and "invalid_item" or "invalid_spell" end
	local key, reason = M.add(group, member, beforeKey)
	if key then self:NotifyChanged({ id }) end
	return key, reason
end
function SG:AddSpell(id, spellID, beforeKey)
	return self:AddMember(id, type(spellID) == "table" and spellID or { spellID = spellID }, beforeKey)
end
function SG:AddAura(id, spellID, beforeKey)
	return self:AddMember(id, { type = "CDM_AURA", spellID = spellID }, beforeKey)
end
function SG:AddItem(id, itemID, beforeKey)
	if not M.mutable() then return nil, "combat" end
	itemID = M.number(itemID)
	if not itemID then return nil, "invalid_item" end
	local canonical = M.itemCanonical(itemID)
	return self:AddMember(id, { type = "ITEM", itemID = canonical, useHighestRank = canonical ~= itemID }, beforeKey)
end
function M.find(id, key)
	for _, member in ipairs(SG:GetMembers(id)) do if member.key == key then return member end end
end
function M.removeMember(group, member)
	if member.preset then group.exclusions[member.key] = true else group.additions[member.key] = nil; M.remove(group.order, member.key) end
end
function SG:RemoveSpell(id, key)
	if not M.mutable() then return nil, "combat" end
	local group = self:GetGroup(id)
	if not group then return nil, "missing_group" end
	local member = M.find(id, key)
	if not member then return nil, "missing_member" end
	M.removeMember(group, member)
	self:NotifyChanged({ id })
	return true
end
function M.transfer(sourceID, key, targetID, beforeKey, move)
	if not M.mutable() then return nil, "combat" end
	local source, target = SG:GetGroup(sourceID), SG:GetGroup(targetID)
	if not (source and target) then return nil, "missing_group" end
	local member = M.find(sourceID, key)
	if not member then return nil, "missing_member" end
	if sourceID == targetID then
		if not move then return nil, member.type == "ITEM" and "duplicate_item" or "duplicate_spell" end
		if beforeKey ~= key then M.materializeOrder(source); M.insert(source.order, key, beforeKey) end
		SG:NotifyChanged({ sourceID })
		return key
	end
	local newKey, reason = M.add(target, M.member(member), beforeKey)
	if not newKey then return nil, reason end
	if move then M.removeMember(source, member) end
	SG:NotifyChanged(move and { sourceID, targetID } or { targetID })
	return newKey
end
function SG:MoveSpell(sourceID, key, targetID, beforeKey) return M.transfer(sourceID, key, targetID, beforeKey, true) end
function SG:CopySpell(sourceID, key, targetID, beforeKey) return M.transfer(sourceID, key, targetID, beforeKey, false) end
SG.MoveMember, SG.CopyMember, SG.RemoveMember = SG.MoveSpell, SG.CopySpell, SG.RemoveSpell
function SG:ReorderGroup(id, beforeID)
	if not M.mutable() then return nil, "combat" end
	local root = self:GetRoot()
	if not (root and root.groups[id]) then return nil, "missing_group" end
	if id ~= beforeID then M.insert(root.order, id, beforeID) end
	self:NotifyChanged({ id })
	return true
end

function M.known(spellID, pet)
	local api = CP.helper and CP.helper.Api
	if not pet then return api and api.IsSpellKnown and api.IsSpellKnown(spellID, true) == true or false end
	local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1
	if C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then return C_SpellBook.IsSpellKnownOrInSpellBook(spellID, bank, true) == true end
	return C_SpellBook and C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spellID, bank, true) == true or false
end
function M.player()
	local _, _, classID = UnitClass("player")
	return classID
end
function SG:GetCanonicalSpellMap(groupIDs)
	local map, catalog, selected = {}, {}, {}
	for _, presetID in ipairs(self.Presets and self.Presets.order or {}) do
		local preset = M.preset(presetID)
		for _, member in ipairs(preset and preset.members or {}) do catalog[#catalog + 1] = member end
	end
	for _, groupID in ipairs(groupIDs or {}) do
		for _, member in ipairs(self:GetMembers(groupID)) do selected[#selected + 1] = member end
	end
	local function declare(member)
		if member.type == "ITEM" or member.type == "CDM_AURA" then return end
		local canonical = map[member.spellID] or (member.canonicalSpellID and map[member.canonicalSpellID])
		if not canonical then
			for _, alias in ipairs(member.aliases or {}) do if map[alias] then canonical = map[alias]; break end end
		end
		canonical = canonical or member.canonicalSpellID or (CP.NormalizePersistentSpellID and CP:NormalizePersistentSpellID(member.spellID, { allowTalentChoiceCanonical = true })) or member.spellID
		canonical = M.spellCanonical(canonical)
		map[canonical] = map[canonical] or canonical
		map[member.spellID] = map[member.spellID] or canonical
		local function declareRanks(spellID)
			for _, rankID in ipairs(CP.GetSpellRankFamily and CP:GetSpellRankFamily(spellID) or {}) do map[rankID] = map[rankID] or canonical end
		end
		declareRanks(member.spellID)
		declareRanks(canonical)
		for _, alias in ipairs(member.aliases or {}) do map[alias] = map[alias] or canonical; declareRanks(alias) end
	end
	-- Explicit variants take precedence over separately added primary IDs.
	-- Apply the shipped catalog first so custom records cannot split known identities.
	for _, records in ipairs({ catalog, selected }) do
		for _, member in ipairs(records) do if member.aliases or member.canonicalSpellID then declare(member) end end
		for _, member in ipairs(records) do declare(member) end
	end
	return map
end

function SG:ResolveGroups(groupIDs, canonicalMap)
	canonicalMap = canonicalMap or self:GetCanonicalSpellMap(groupIDs)
	local result, seen = {}, {}
	local classID = M.player()
	for _, groupID in ipairs(groupIDs or {}) do
		for _, member in ipairs(self:GetMembers(groupID)) do
			local matches = CP:SpellGroupMemberAllowsClass(member, classID)
			-- Imported specialization filters fall back to classes without changing stored data.
			if matches and member.preset then
				for _, excludedID in ipairs(member.excludeIfKnown or {}) do if M.known(excludedID) then matches = false; break end end
			end
			if matches and member.type == "CDM_AURA" then
				local identity = M.identity(member)
				if not seen[identity] then
					result[#result + 1] = { key = member.key, type = "CDM_AURA", spellID = member.spellID, groupID = groupID }
					seen[identity] = true
				end
			elseif matches and member.type == "ITEM" then
				local canonical = M.itemCanonical(member.itemID)
				local identity = "ITEM:" .. canonical
				if not seen[identity] then
					result[#result + 1] = { key = member.key, type = "ITEM", itemID = member.itemID, canonicalItemID = canonical,
						useHighestRank = member.useHighestRank == true, groupID = groupID }
					seen[identity] = true
				end
			elseif matches then
				local candidates, used = {}, {}
				local function candidate(id)
					id = M.number(id)
					if id and member.preset then
						-- Skip other catalog abilities, but retain a known base spell
						-- while its button temporarily offers a different follow-up.
						local identity = canonicalMap[member.spellID]
						if canonicalMap[id] and canonicalMap[id] ~= identity then return end
					end
					if id and not used[id] then candidates[#candidates + 1], used[id] = id, true end
				end
				if CP.ResolveLearnedSpellRank then candidate(CP:ResolveLearnedSpellRank(member.spellID, member.pet)) end
				candidate(CP.ResolveTrackedSpellID and CP:ResolveTrackedSpellID(member.spellID))
				candidate(member.spellID)
				for _, id in ipairs(member.aliases or {}) do candidate(CP.ResolveTrackedSpellID and CP:ResolveTrackedSpellID(id)); candidate(id) end
				for _, id in ipairs(CP.GetSpellAliasIDs and CP:GetSpellAliasIDs(member.spellID) or {}) do candidate(id) end
				for _, id in ipairs(candidates) do
					if M.known(id, member.pet) then
						local canonical = canonicalMap[id] or canonicalMap[member.spellID] or member.canonicalSpellID
							or (CP.NormalizePersistentSpellID and CP:NormalizePersistentSpellID(id, { allowTalentChoiceCanonical = true })) or id
						local identity = "SPELL:" .. canonical
						if not seen[identity] then
							result[#result + 1] = { key = member.key, spellID = id, canonicalSpellID = canonical, groupID = groupID }
							seen[identity] = true
						end
						break
					end
				end
			end
		end
	end
	return result
end

function SG:SerializeGroups(groupIDs)
	local bundle = { version = 1, groups = {}, order = {} }
	for _, id in ipairs(groupIDs or self:GetGroupIDs()) do
		local group = self:GetGroup(id)
		if group and not bundle.groups[id] then bundle.groups[id], bundle.order[#bundle.order + 1] = M.copy(group), id end
	end
	return bundle
end
function M.validateGroup(source)
	if type(source) ~= "table" or getmetatable(source) then return nil end
	local name = M.name(source.name)
	if not name or not M.array(source.order, M.MAX_MEMBERS * 2) then return nil end
	if source.presetID ~= nil and not (M.key(source.presetID) and M.preset(source.presetID)) then return nil, "invalid_preset" end
	if type(source.additions) ~= "table" or getmetatable(source.additions) or type(source.exclusions) ~= "table" or getmetatable(source.exclusions) then return nil end
	local group = { name = name, presetID = source.presetID, additions = {}, exclusions = {}, order = {}, nextMemberID = 1 }
	local count, identities = 0, {}
	for key, value in pairs(source.additions) do
		count = count + 1
		if count > M.MAX_MEMBERS or not (M.key(key) and key:match("^custom:%d+$")) then return nil end
		local member = M.member(value, key)
		if not member then return nil end
		local identity = M.identity(member)
		-- Keep legacy rank duplicates and their independent filters on import.
		-- New additions are deduplicated; runtime resolution shares one identity.
		if identities[identity] and (member.type == "ITEM" or member.type == "CDM_AURA" or not (CP.GetSpellRankFamily and CP:GetSpellRankFamily(member.spellID))) then return nil end
		group.additions[key] = member
		identities[identity] = true
		group.nextMemberID = math.max(group.nextMemberID, (M.number(key:match("(%d+)$")) or 0) + 1)
	end
	local excluded = 0
	for key, value in pairs(source.exclusions) do
		excluded = excluded + 1
		if excluded > M.MAX_MEMBERS or not M.key(key) or value ~= true then return nil end
		group.exclusions[key] = true
	end
	local seen = {}
	for _, key in ipairs(source.order) do
		if not M.key(key) or seen[key] then return nil end
		group.order[#group.order + 1], seen[key] = key, true
	end
	return group, nil, count + excluded + #group.order
end
function SG:ImportGroups(bundle)
	if not M.mutable() then return nil, "combat" end
	if type(bundle) ~= "table" or getmetatable(bundle) or bundle.version ~= 1 or not M.array(bundle.order, M.MAX_GROUPS) or type(bundle.groups) ~= "table" or getmetatable(bundle.groups) then
		return nil, "invalid_bundle"
	end
	local root = self:GetRoot()
	if not root or #root.order + #bundle.order > M.MAX_GROUPS then return nil, "limit" end
	local staged, total, count = {}, 0, 0
	for id in pairs(bundle.groups) do count = count + 1; if count > M.MAX_GROUPS or not M.key(id) then return nil, "invalid_bundle" end end
	if count ~= #bundle.order then return nil, "invalid_bundle" end
	for _, id in ipairs(bundle.order) do
		if not M.key(id) or staged[id] then return nil, "invalid_bundle" end
		local group, reason, size = M.validateGroup(bundle.groups[id])
		if not group then return nil, reason or "invalid_bundle" end
		total = total + size
		if total > M.MAX_IMPORT_MEMBERS then return nil, "limit" end
		staged[id] = group
	end
	local mapping, created = {}, {}
	for _, id in ipairs(bundle.order) do mapping[id] = M.allocate(root, staged[id]); created[#created + 1] = mapping[id] end
	if #created > 0 then self:NotifyChanged(created) end
	return mapping
end
