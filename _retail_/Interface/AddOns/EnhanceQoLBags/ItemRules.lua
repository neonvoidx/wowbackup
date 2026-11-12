local addon = _G.EnhanceQoL
addon.Bags = addon.Bags or {}
local M = { version = 1, listeners = {}, snapshots = {}, requested = {}, requestedCount = 0 }
addon.Bags.ItemRules = M
function addon.GetCategoryFilterContext() return { consumer = "bags", mode = "category" } end

local function copy(value)
	if _G.issecretvalue and _G.issecretvalue(value) then return nil end
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function categoryQuery(query)
	if type(query) == "string" and query:match("^%s*$") then return { constant = false } end
	if type(query) ~= "table" then return query end
	local result = copy(query)
	local children = result.all or result.any
	if type(children) == "table" then
		if #children == 0 then return { constant = false } end
		for index, child in ipairs(children) do children[index] = categoryQuery(child) end
	end
	if result["not"] then result["not"] = categoryQuery(result["not"]) end
	return result
end
local function engine() return addon.Items end
local function failure(code) return { code = code, message = code, readOnly = true } end
local function supported(compiled, service)
	if not service.GetCapabilities then return true end
	local capabilities = service.GetCapabilities(addon.GetCategoryFilterContext())
	for _, field in ipairs(compiled.fields or {}) do
		local capability = capabilities.fields and capabilities.fields[field]
		if capability and capability.supported == false then
			local err = failure("unsupported_field")
			err.field, err.args = field, { field = field }
			return false, err
		end
	end
	return true
end
local ops = { EQUALS = "=", NOT_EQUALS = "!=", LESS_THAN = "<", LESS_OR_EQUAL = "<=", GREATER_THAN = ">", GREATER_OR_EQUAL = ">=", IN = "in" }
local aliases = { name = "itemName", link = "itemLink", minLevel = "itemMinLevel", maxStack = "itemStackCount", icon = "itemTexture", subclassID = "subClassID", equipSlot = "equipLoc", isReagent = "isCraftingReagent" }
function M.Convert(node)
	if not node then return { constant = false } end
	if node.nodeType == "group" then
		local out = { [node.operator == "AND" and "all" or "any"] = {} }
		local children = out.all or out.any
		for _, child in ipairs(node.children or {}) do
			local ast, err = M.Convert(child)
			if err then return nil, err end
			children[#children + 1] = ast
		end
		if #children == 0 then return { constant = false } end
		return out
	end
	if not node.contextKey then return nil, failure("unsupported_legacy_field") end
	local op = ops[node.operator]
	local value = copy(node.value)
	if node.operator == "IN" and node.valueSet then
		value = {}
		for _, candidate in ipairs(node.value or {}) do
			if not node.valueSet[candidate] then return nil, failure("unsupported_legacy_value") end
			value[#value + 1] = candidate
		end
	end
	if node.contextKey == "equipmentSetIDs" then op = "has" end
	if node.comparisonValueMode == "equippedAverageOffset" then
		op, value = ">=", { ref = "equippedAverage", offset = (node.operator == "AVERAGE_PLUS" and 1 or -1) * node.value }
	end
	if not op then return nil, failure("unsupported_legacy_operator") end
	return { field = node.contextKey, op = op, value = value }
end
function M.Compile(category, legacy, usage)
	local service = engine()
	local ast, err
	if category.itemFilter then
		if type(category.itemFilter) ~= "table" or category.itemFilter.version ~= 1 then return nil, failure("unsupported_filter_version") end
		ast = category.itemFilter.ast
	else ast, err = M.Convert(legacy) end
	if err then return nil, err end
	if not service then return nil, failure("item_service_unavailable") end
	local compiled, issue = service.Compile(ast, addon.GetCategoryFilterContext())
	if not compiled then return nil, issue end
	local available, unavailable = supported(compiled, service)
	if not available then return nil, unavailable end
	for _, field in ipairs(compiled.fields or {}) do
		usage[aliases[field] or field] = true
	end
	-- Relative comparisons require a player snapshot before item evaluation.
	local function visit(node)
		if type(node.value) == "table" and node.value.ref == "equippedAverage" then usage.equippedAverageItemLevel = true end
		for _, child in ipairs(node.all or node.any or {}) do visit(child) end
		if node["not"] then visit(node["not"]) end
	end
	visit(compiled.ast or ast)
	return compiled
end
function M.Notify(payload)
	for _, callback in ipairs(M.listeners) do callback(payload) end
end
function M.Subscribe(callback) M.listeners[#M.listeners + 1] = callback end
function M.Connect(service)
	if not M.subscribed and service.Subscribe then
		M.subscribed = true
		service.Subscribe(function(payload)
			M.requested, M.requestedCount, M.snapshots = {}, 0, {}
			M.Notify(payload)
		end)
	end
end
local metadataMap = {
	itemName = "name", itemLink = "link", itemQuality = "quality", itemLevel = "baseItemLevel", itemMinLevel = "minLevel",
	itemType = "itemType", itemSubType = "itemSubtype", itemStackCount = "maxStack", itemEquipLoc = "equipSlot", itemTexture = "icon",
	sellPrice = "sellPrice", classID = "classID", subclassID = "subclassID", bindType = "bindType", expansionID = "expansionID",
	setID = "setID", isCraftingReagent = "isReagent", itemDescription = "itemDescription",
}
local metadataFields = {}
for _, field in pairs(metadataMap) do metadataFields[#metadataFields + 1] = field end
function M.GetRuleItemInfo(itemRef)
	local service = engine()
	if not service then return nil end
	M.Connect(service)
	local facts, statuses = service.Get(itemRef, metadataFields, addon.GetCategoryFilterContext())
	local result = { loaded = statuses.name == "known", statuses = {} }
	for legacy, canonical in pairs(metadataMap) do
		result[legacy], result.statuses[legacy] = facts[canonical], statuses[canonical]
	end
	return result
end
function M.CaptureContext(context)
	if not context then return end
	local service = engine()
	if service then M.Connect(service) end
	if context.bagID ~= nil and context.slotID ~= nil then M.snapshots[tostring(context.bagID) .. ":" .. tostring(context.slotID)] = copy(context) end
end
function M.Evaluate(compiled, context)
	local service = engine()
	if not service or not compiled then return nil end
	M.Connect(service)
	local item = { itemID = context.itemID, link = context.itemLink or context.link, bagID = context.bagID, slotID = context.slotID,
		count = context.count, isBound = context.isBound }
	local options = addon.GetCategoryFilterContext()
	options.observations = context
	local facts, statuses = service.Get(item, compiled.fields, options)
	local result = service.Evaluate(compiled, facts, statuses)
	local requestKey = tostring(item.link or item.itemID) .. ":" .. tostring(item.bagID) .. ":" .. tostring(item.slotID) .. ":" .. table.concat(compiled.fields or {}, ",")
	if result == nil and service.Request and not M.requested[requestKey] then
		if M.requestedCount >= 2048 then M.requested, M.requestedCount = {}, 0 end
		M.requested[requestKey] = true
		M.requestedCount = M.requestedCount + 1
		service.Request(item, compiled.fields, options)
	end
	return result
end
function M.Install(findCategory, compileLegacy, dirty, categories)
	function addon.ValidateCategoryItemFilter(query)
		local service = engine()
		if not service then return nil, failure("item_service_unavailable") end
		local compiled, err = service.Compile(categoryQuery(query), addon.GetCategoryFilterContext())
		if compiled then
			local available, unavailable = supported(compiled, service)
			if not available then return nil, unavailable end
		end
		return compiled and copy(compiled.ast), err
	end
	function addon.GetCategoryItemFilter(id)
		local category = findCategory(id)
		if not category then return nil, failure("unknown_category") end
		local compiled, err = M.Compile(category, compileLegacy(category.ruleTree, {}), {})
		return compiled and copy(compiled.ast), err
	end
	function addon.SetCategoryItemFilter(id, query)
		local ast, err = addon.ValidateCategoryItemFilter(query)
		if not ast then return false, err end
		local category = findCategory(id)
		if not category then return false, failure("unknown_category") end
		if category.automaticEquipmentSetID ~= nil then return false, failure("read_only_category") end
		category.itemFilter = { version = 1, ast = copy(ast) }
		dirty()
		return true
	end
	function addon.CreateCategoryFilterDraft(id)
		local ast, err = addon.GetCategoryItemFilter(id)
		local service = engine()
		return { ast = ast, text = ast and service and service.Format(ast) or "", error = err, readOnly = err ~= nil, version = 1 }
	end
	function addon.PreviewCategoryItemFilter(id, query, items)
		local ast, err = addon.ValidateCategoryItemFilter(query)
		local out = { items = {}, matchedCount = 0, pendingCount = 0, matches = 0, pending = 0, error = err }
		if not ast then return out end
		local compiled = engine().Compile(ast, addon.GetCategoryFilterContext())
		if not items then
			items = {}
			local api = _G.C_Container
			if api and api.GetContainerNumSlots and api.GetContainerItemInfo then
				local bagIDs = {}
				for bag = 0, (_G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4) do bagIDs[#bagIDs + 1] = bag end
				local keyring = _G.Enum and _G.Enum.BagIndex and _G.Enum.BagIndex.Keyring
				if keyring and _G.GetKeyRingSize then bagIDs[#bagIDs + 1] = keyring end
				for _, bag in ipairs(bagIDs) do
					local count = copy(api.GetContainerNumSlots(bag))
					for slot = 1, type(count) == "number" and count or 0 do
						local info = copy(api.GetContainerItemInfo(bag, slot))
						if type(info) == "table" and type(info.itemID) == "number" then
							local observed = M.snapshots[tostring(bag) .. ":" .. tostring(slot)]
							local unchanged = observed and observed.itemID == info.itemID and observed.itemLink == info.hyperlink
								and observed.count == info.stackCount and observed.isBound == info.isBound and observed.quality == info.quality
							local current = unchanged and copy(observed) or {}
							current.itemID, current.itemLink, current.bagID, current.slotID = info.itemID, info.hyperlink, bag, slot
							current.count, current.isBound, current.isLocked, current.quality = info.stackCount, info.isBound, info.isLocked, info.quality
							current.icon = info.iconFileID
							if api.GetContainerItemQuestInfo then
								local quest = copy(api.GetContainerItemQuestInfo(bag, slot))
								current.isQuestItem, current.questID = quest and quest.isQuestItem, quest and quest.questID
							end
							items[#items + 1] = current
						end
					end
				end
			end
		end
		for _, item in ipairs(items) do
			local match = M.Evaluate(compiled, item)
			local winner = addon.GetMatchingCustomCategoryID(item, { [id] = compiled })
			local winnerName
			for _, category in ipairs(categories()) do if category.id == winner then winnerName = category.name; break end end
			local row = { itemID = item.itemID, link = item.itemLink or item.link, name = item.itemName or item.name, icon = item.icon,
				matches = match, match = match, pending = match == nil, winnerID = winner, categoryID = winner, winnerName = winnerName, overridden = match == true and winner ~= nil and winner ~= id, item = copy(item) }
			out.items[#out.items + 1] = row
			if match == true then out.matchedCount = out.matchedCount + 1 elseif match == nil then out.pendingCount = out.pendingCount + 1 end
		end
		out.matches, out.pending = out.matchedCount, out.pendingCount
		return out
	end
	addon.GetCustomCategoryRuleQuery = addon.GetCategoryItemFilter
	addon.SetCustomCategoryRuleQuery = addon.SetCategoryItemFilter
	addon.ValidateCustomCategoryRuleQuery = addon.ValidateCategoryItemFilter
	addon.GetCustomCategoryRuleDraft = addon.CreateCategoryFilterDraft
	addon.GetCategoryRulePreview = addon.PreviewCategoryItemFilter
end
