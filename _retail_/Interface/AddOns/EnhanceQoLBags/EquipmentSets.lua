-- luacheck: globals C_EventUtils C_EquipmentSet EquipmentManager_GetLocationData EquipmentManager_UnpackLocation
local addon = _G.EnhanceQoL
local Sets = {}
addon.Bags.EquipmentSets = Sets

function Sets.IsSupported()
	return not (addon.variables and addon.variables.isTBC)
		and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs and C_EquipmentSet.GetEquipmentSetInfo
		and C_EquipmentSet.GetItemLocations
		and (EquipmentManager_GetLocationData or EquipmentManager_UnpackLocation) and true or false
end

function Sets.IsEnabled()
	return Sets.IsSupported() and addon.GetSettings().autoEquipmentSetCategories == true
end

function Sets.GetOptions()
	local options = {}
	if not Sets.IsSupported() then return options end
	local ids = C_EquipmentSet.GetEquipmentSetIDs() or {}
	table.sort(ids)
	for _, id in ipairs(ids) do
		local name = C_EquipmentSet.GetEquipmentSetInfo(id)
		if name then options[#options + 1] = { value = id, label = name } end
	end
	return options
end

function Sets.GetMembership(bagID, slotID)
	if not Sets.IsSupported() then return nil end
	if not Sets.slots then
		Sets.slots = {}
		for _, option in ipairs(Sets.GetOptions()) do
			for _, location in pairs(C_EquipmentSet.GetItemLocations(option.value) or {}) do
				local data
				if EquipmentManager_GetLocationData then
					data = EquipmentManager_GetLocationData(location)
				else
					local _, _, bags, slot, bag = EquipmentManager_UnpackLocation(location)
					data = { isBags = bags, bag = bag, slot = slot }
				end
				if data.isBags and data.bag ~= nil and data.slot then
					local key = data.bag .. ":" .. data.slot
					Sets.slots[key] = Sets.slots[key] or {}
					Sets.slots[key][option.value] = true
				end
			end
		end
	end
	return Sets.slots[tostring(bagID) .. ":" .. tostring(slotID)]
end

-- Generated entries use the normal category model; only their membership and name
-- belong to the equipment manager. Inactive entries retain their presentation.
function Sets.SyncCategories(modeState, categories, groups)
	local options = Sets.IsEnabled() and Sets.GetOptions() or {}
	local active, existing = {}, {}
	for _, option in ipairs(options) do active[option.value] = option end
	modeState.inactiveEquipmentSetCategories = type(modeState.inactiveEquipmentSetCategories) == "table" and modeState.inactiveEquipmentSetCategories or {}
	local inactive = modeState.inactiveEquipmentSetCategories
	for index = #categories, 1, -1 do
		local category = categories[index]
		if category.automaticEquipmentSetID ~= nil then
			local id = category.automaticEquipmentSetID
			if active[id] and not existing[id] then
				existing[id] = category
			else
				inactive[tostring(id)] = category
				table.remove(categories, index)
			end
		end
	end
	if #options > 0 and not modeState.equipmentSetGroupInitialized then
		local found
		for _, group in ipairs(groups) do if group.id == "equipmentSets" then found = true; break end end
		if not found then
			groups[#groups + 1] = {
				id = "equipmentSets", name = addon.L["basicPresetCategoryEquipmentSets"] or "Equipment Sets",
				color = { 0.55, 0.8, 1 }, sortOrder = 0,
			}
		end
		modeState.equipmentSetGroupInitialized = true
	end
	local defaultGroup
	for _, group in ipairs(groups) do if group.id == "equipmentSets" then defaultGroup = group.id; break end end
	for index, option in ipairs(options) do
		local key = tostring(option.value)
		local category = existing[option.value] or inactive[key]
		if not existing[option.value] then
			category = category or {
				color = { 0.55, 0.8, 1 }, sortOrder = index, sortMode = "itemLevel", groupID = defaultGroup,
			}
			categories[#categories + 1] = category
		end
		inactive[key] = nil
		category.id = "equipmentSet:" .. key
		category.automaticEquipmentSetID = option.value
		category.name = option.label
		category.itemIDs = {}
		category.itemFilter = nil
		category.ruleTree = { nodeType = "group", operator = "OR", children = {
			{ nodeType = "rule", field = "equipmentSetIDs", operator = "EQUALS", value = option.value },
		} }
	end
end

function Sets.ConfigureMatching(compiled, categories)
	compiled.equipmentSets = {}
	for _, category in ipairs(categories) do
		if category.automaticEquipmentSetID ~= nil then
			compiled.contextUsage.isEquipmentSet = true
			compiled.contextUsage.equipmentSetIDs = true
			compiled.equipmentSets[#compiled.equipmentSets + 1] = { value = category.automaticEquipmentSetID, id = category.id }
		end
	end
	-- Display order never changes the deterministic winner for shared items.
	table.sort(compiled.equipmentSets, function(a, b) return a.value < b.value end)
end

function Sets.Match(compiled, context)
	if not compiled.equipmentSets then return nil end
	local membership = context.equipmentSetIDs
	for _, option in ipairs(compiled.equipmentSets) do
		if membership and membership[option.value] then return option.id end
	end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYERBANKSLOTS_CHANGED", "EQUIPMENT_SETS_CHANGED", "PLAYER_ENTERING_WORLD", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BANK_TABS_CHANGED" }) do
	if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
end
events:SetScript("OnEvent", function(_, event)
	Sets.slots = nil
	Sets.revision = (Sets.revision or 0) + 1
	if event == "EQUIPMENT_SETS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
		if addon.MarkCategoryModeStateDirty then addon.MarkCategoryModeStateDirty() end
		if addon.RefreshSettingsFrame then addon.RefreshSettingsFrame() end
	end
end)
