local I = _G.EnhanceQoL.Items
local P = I.internal
local F = { pending = {}, pendingCount = 0, failures = {}, serial = 0, failureOrder = {}, failureNext = 1, baseCache = {}, baseOrder = {}, baseNext = 1, missing = {}, missingOrder = {}, missingNext = 1 }
P.facts = F
local baseNames = { "name", "link", "quality", "baseItemLevel", "minLevel", "itemType", "itemSubtype", "maxStack", "equipSlot", "icon", "sellPrice", "classID", "subclassID", "bindType", "expansionID", "setID", "isReagent", "itemDescription" }
local subclassifiers = { isPotion = 1, isElixir = 2, isFlask = 3, isFoodAndDrink = 5, isBandage = 7 }
function I.NormalizeItem(item)
	if not P.Safe(item) then return nil end
	if type(item) == "number" then item = { itemID = item }
	elseif type(item) == "string" then
		local id = tonumber(item:match("item:(%d+)") or item:match("^%d+$"))
		item = { itemID = id, link = item:find("item:", 1, true) and item or nil }
	end
	if type(item) ~= "table" then return nil end
	local id = item.itemID
	if not P.Safe(id) then return nil end
	if id == nil and P.Safe(item.link or item.itemLink) and type(item.link or item.itemLink) == "string" then id = tonumber((item.link or item.itemLink):match("item:(%d+)")) end
	if not P.Number(id) or id <= 0 or id % 1 ~= 0 then return nil end
	local result = P.Copy(item); result.itemID = id
	if result.link == nil then result.link = result.itemLink end
	if result.link ~= nil and type(result.link) ~= "string" then result.link = nil end
	return result
end
local function validValue(field, value)
	if not P.Safe(value) then return false end
	if field.type == "number" then return P.Number(value) end
	if field.type == "set" then return type(value) == "table" end
	return type(value) == field.type
end
local function lookup(values, field)
	if type(values) ~= "table" then return nil end
	local value = values[field.name]
	if not P.Safe(value) or value ~= nil then return value end
	for _, alias in ipairs(field.aliases) do
		value = values[alias]
		if not P.Safe(value) or value ~= nil then return value end
	end
end
local function call(fn, ...)
	if type(fn) ~= "function" then return nil, "unsupported" end
	local ok, value = pcall(fn, ...)
	if not ok or not P.Safe(value) then return nil, "missing" end
	return value, value ~= nil and "known" or "missing"
end
local function base(state)
	if state.base then return state.base end
	local cached = F.baseCache[state.reference]
	if cached then state.base, state.baseStatus = cached.values, "known"; return cached.values end
	local values = {}
	state.base = values
	local fn = P.Native("GetItemInfo")
	if type(fn) ~= "function" then state.baseStatus = "unsupported"; return values end
	local results = { pcall(fn, state.reference) }
	if not results[1] then state.baseStatus = "missing"; return values end
	for index, name in ipairs(baseNames) do
		if P.Safe(results[index + 1]) then values[name] = results[index + 1] end
	end
	state.baseStatus = values.name ~= nil and "known" or (F.pending[state.item.itemID] and "pending" or "missing")
	if state.baseStatus ~= "known" and not F.missing[state.item.itemID] then
		local evicted = F.missingOrder[F.missingNext]
		if evicted and F.missing[evicted.itemID] == evicted then F.missing[evicted.itemID] = nil end
		local entry = { itemID = state.item.itemID }
		F.missingOrder[F.missingNext] = entry
		F.missingNext = F.missingNext % 1024 + 1
		F.missing[state.item.itemID] = entry
	end
	if state.baseStatus == "known" then
		F.missing[state.item.itemID] = nil
		local evicted = F.baseOrder[F.baseNext]
		if evicted then F.baseCache[evicted] = nil end
		F.baseOrder[F.baseNext] = state.reference; F.baseNext = F.baseNext % 1024 + 1
		F.baseCache[state.reference] = { itemID = state.item.itemID, values = values }
	end
	return values
end
local function current(context)
	if context.offline then return false end
	if context.ownerID and _G.UnitGUID and context.ownerID ~= _G.UnitGUID("player") and context.viewerID ~= _G.UnitGUID("player") then return false end
	return true
end
local function derived(field, state, resolve)
	local name = field.name
	local first, status = resolve(field.dependencies[1])
	if status ~= "known" then return nil, status end
	if name == "isEquipment" then return first ~= "" and first ~= "INVTYPE_NON_EQUIP_IGNORE", "known" end
	if name == "isConsumable" then return first == 0, "known" end
	if name == "isRecipe" then return first == 9, "known" end
	if name == "isQuest" then return first == 12, "known" end
	if name == "isJunkQuality" then return first == 0, "known" end
	if name == "isStackable" then return first > 1, "known" end
	if name == "isBoE" then return first == 2, "known" end
	if name == "isBoP" then return first == 1, "known" end
	if name == "isBoU" then return first == 3, "known" end
	if name == "isPet" and type(state.item.link) == "string" and state.item.link:find("battlepet:", 1, true) then return true, "known" end
	local second, secondStatus = resolve("subclassID")
	if secondStatus ~= "known" then return nil, secondStatus end
	if name == "subClassKey" then return tostring(first) .. ":" .. tostring(second), "known" end
	if name == "isPet" then return first == 17 or (first == 15 and second == 2), "known" end
	return first == 0 and second == subclassifiers[name], "known"
end
local function collection(state, resolve)
	if not current(state.context) then return nil, "missing" end
	local toy, toyStatus = resolve("isToy")
	if toy then return call(_G.PlayerHasToy, state.item.itemID) end
	local journal = _G.C_MountJournal
	if journal and journal.GetMountFromItem then
		local mount = call(journal.GetMountFromItem, state.item.itemID)
		if mount and journal.GetMountInfoByID then
			local values = { pcall(journal.GetMountInfoByID, mount) }
			if values[1] and P.Safe(values[12]) and type(values[12]) == "boolean" then return values[12], "known" end
			return nil, "missing"
		end
	end
	local species = state.item.link and tonumber(state.item.link:match("battlepet:(%d+)"))
	if species and _G.C_PetJournal then
		local count, status = call(_G.C_PetJournal.GetNumCollectedInfo, species)
		if P.Number(count) then return count > 0, "known" end
		return nil, status
	end
	local equipment = resolve("isEquipment")
	if equipment and _G.C_TransmogCollection then return call(_G.C_TransmogCollection.PlayerHasTransmogByItemInfo, state.reference) end
	return nil, toyStatus == "unsupported" and not journal and not _G.C_PetJournal and not _G.C_TransmogCollection and "unsupported" or "missing"
end
local function nativeValue(field, state, resolve)
	if field.source == "base" then
		local values = base(state)
		return values[field.name], values[field.name] ~= nil and "known" or state.baseStatus == "pending" and "pending" or state.baseStatus == "unsupported" and "unsupported" or "missing"
	elseif field.source == "itemLevel" then
		if not current(state.context) then return nil, "missing" end
		local fn = P.Native("GetDetailedItemLevelInfo")
		if fn then return call(fn, state.reference) end
		return base(state).baseItemLevel, state.baseStatus
	elseif field.source == "stats" then
		if state.stats == nil then
			state.stats, state.statsStatus = call(P.Native("GetItemStats"), state.reference)
			if type(state.stats) ~= "table" then state.stats = false end
		end
		if not state.stats then return nil, state.statsStatus end
		if field.name == "sockets" or field.name == "isSocketed" then
			local total = 0
			for key, value in pairs(state.stats) do
				if not P.Safe(key) or not P.Safe(value) then return nil, "missing" end
				if type(key) == "string" and key:find("EMPTY_SOCKET_", 1, true) == 1 and P.Number(value) then total = total + value end
			end
			if field.name == "isSocketed" then return total > 0, "known" end
			return total, "known"
		end
		local value = state.stats[field.statKey]
		if not P.Safe(value) then return nil, "missing" end
		return value or 0, "known"
	elseif field.source == "derived" then return derived(field, state, resolve)
	elseif field.source == "native" then
		if field.scope == "character" and not current(state.context) then return nil, "missing" end
		return call(P.Native(field.api), field.name == "isKeystone" and state.item.itemID or state.reference)
	elseif field.source == "toy" or field.source == "mount" then
		local api = field.source == "toy" and _G.C_ToyBox or _G.C_MountJournal
		local fn = api and (field.source == "toy" and api.GetToyInfo or api.GetMountFromItem)
		if type(fn) ~= "function" then return nil, "unsupported" end
		local ok, result = pcall(fn, state.item.itemID)
		if not ok or not P.Safe(result) then return nil, "missing" end
		return result ~= nil and result ~= false and result ~= 0, "known"
	elseif field.source == "collection" then return collection(state, resolve)
	elseif field.source == "reference" then
		if field.name == "equippedAverage" then
			local supplied = state.context.equippedAverage
			if supplied == nil then supplied = state.context.equippedAverageItemLevel end
			if supplied ~= nil then return supplied, "known" end
			if not current(state.context) then return nil, "missing" end
			if not _G.GetAverageItemLevel then return nil, "unsupported" end
			local ok, _, equipped = pcall(_G.GetAverageItemLevel)
			return ok and equipped or nil, ok and equipped ~= nil and "known" or "missing"
		end
		if state.context.player and state.context.player.level ~= nil then return state.context.player.level, "known" end
		if not current(state.context) then return nil, "missing" end
		return call(_G.UnitLevel, "player")
	end
	if P.ResolveExtra then return P.ResolveExtra(field, state, resolve) end
	return nil, "missing"
end
function I.Get(item, fields, context)
	context = type(context) == "table" and context or {}
	local normalized = I.NormalizeItem(item)
	local facts, statuses, memo, memoStatus = {}, {}, {}, {}
	local state = { item = normalized or {}, context = context }
	state.reference = state.item.link or state.item.itemID
	if type(fields) == "string" then fields = { fields } end
	local function resolve(name)
		local canonical = P.Canonical(name)
		if not canonical then return nil, "unsupported" end
		if memoStatus[canonical] then return memo[canonical], memoStatus[canonical] end
		local field = I.fields[canonical]
		local value, status = lookup(context.observations, field), lookup(context.statuses, field)
		if not P.Safe(value) or not P.Safe(status) then memoStatus[canonical] = "missing"; return nil, "missing" end
		if status == "unknown" then status = "missing" end
		if status ~= nil and status ~= "known" then
			status = (status == "pending" or status == "unsupported") and status or "missing"
			memoStatus[canonical] = status; return nil, status
		end
		if value == nil then value = lookup(normalized or item, field) end
		if not P.Safe(value) then memoStatus[canonical] = "missing"; return nil, "missing" end
		if value ~= nil then
			if validValue(field, value) then value, status = P.Copy(value), "known" else value, status = nil, "missing" end
		elseif field.source == "observation" or field.source == "snapshot" then
			local supported = P.Capability(field, context)
			status = supported and "missing" or "unsupported"
		elseif normalized then
			local supported = P.Capability(field, context)
			if supported then value, status = nativeValue(field, state, resolve) else status = "unsupported" end
			if status == "known" and not validValue(field, value) then value, status = nil, "missing" end
		else status = "missing" end
		memo[canonical], memoStatus[canonical] = value, status or "missing"
		return value, memoStatus[canonical]
	end
	for _, name in ipairs(type(fields) == "table" and fields or {}) do
		local canonical = P.Canonical(name) or name
		local value, status = resolve(name)
		facts[canonical], statuses[canonical] = value, status
		if name ~= canonical then facts[name], statuses[name] = P.Copy(value), status end
	end
	return facts, statuses
end
local function finish(id, success, reason)
	local pending = F.pending[id]
	if not pending then return end
	F.pending[id], F.pendingCount = nil, F.pendingCount - 1
	if not success then
		local evicted = F.failureOrder[F.failureNext]
		if evicted then F.failures[evicted] = nil end
		F.failureOrder[F.failureNext] = id; F.failureNext = F.failureNext % 1024 + 1
		F.failures[id] = P.Now() + 15
	end
	local fieldSet, fields = {}, {}
	for _, request in ipairs(pending.requests) do
		local facts, statuses = I.Get(request.item, request.fields, request.context)
		for name in pairs(statuses) do if not fieldSet[name] then fieldSet[name] = true; fields[#fields + 1] = name end end
		if request.callback then pcall(request.callback, facts, statuses) end
	end
	if success then
		local state = { item = { itemID = id }, reference = id, context = {} }
		base(state)
		if state.baseStatus ~= "known" then
			local evicted = F.failureOrder[F.failureNext]
			if evicted then F.failures[evicted] = nil end
			F.failureOrder[F.failureNext] = id; F.failureNext = F.failureNext % 1024 + 1
			F.failures[id] = P.Now() + 15
		end
	end
	table.sort(fields)
	P.Emit({ itemID = id, fields = fields, reason = reason or "itemData" })
end
function I.Request(item, fields, context, callback)
	local normalized = I.NormalizeItem(item)
	if not normalized then return P.Error("invalid_item") end
	if callback ~= nil and type(callback) ~= "function" then return P.Error("invalid_callback") end
	if type(fields) == "string" then fields = { fields } end
	fields, context = P.Copy(fields or {}), P.Copy(context or {})
	local facts, statuses = I.Get(normalized, fields, context)
	local needed = false
	for name, status in pairs(statuses) do
		local field = I.fields[P.Canonical(name)]
		if (status == "missing" or status == "pending") and field and (field.source == "base" or field.source == "derived" or field.source == "itemLevel" or field.source == "stats" or field.source == "tooltip" or field.source == "gems") then needed = true end
	end
	-- A missing optional stat, tooltip marker or instance fact is not evidence
	-- that native item data needs loading. Re-requesting an already loaded ID
	-- would produce a successful event and the same missing value indefinitely.
	if needed then
		local state = { item = normalized, reference = normalized.link or normalized.itemID, context = context }
		base(state)
		if state.baseStatus == "known" then needed = false end
	end
	local requestAPI = P.Native("RequestLoadItemDataByID")
	if not needed or not requestAPI or (F.failures[normalized.itemID] and F.failures[normalized.itemID] > P.Now()) then
		if callback then pcall(callback, facts, statuses) end
		return true
	end
	local pending = F.pending[normalized.itemID]
	if not pending then
		if F.pendingCount >= 256 then return P.Error("request_limit") end
		pending = { requests = {} }; F.pending[normalized.itemID] = pending; F.pendingCount = F.pendingCount + 1
	end
	if #pending.requests >= 64 then return P.Error("callback_limit") end
	pending.requests[#pending.requests + 1] = { item = normalized, fields = fields, context = context, callback = callback }
	if not pending.started then
		pending.started = true
		local ok = pcall(requestAPI, normalized.itemID)
		if not ok then finish(normalized.itemID, false, "failed")
		elseif _G.C_Timer and _G.C_Timer.After then
			_G.C_Timer.After(15, function() if F.pending[normalized.itemID] == pending then finish(normalized.itemID, false, "timeout") end end)
		end
	end
	return true
end
function P.OnEvent(event, ...)
	if event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
		local id, success = ...
		if P.Safe(id) and P.Safe(success) then
			-- Global item-cache events also come from the character panel, bank and
			-- other consumers. Only complete data this service actually awaited.
			if not F.pending[id] and not F.missing[id] then return end
			F.missing[id] = nil
			for key, entry in pairs(F.baseCache) do if entry.itemID == id then F.baseCache[key] = nil end end
			if success then F.failures[id] = nil end
			if F.pending[id] then finish(id, success == true) else P.Emit({ itemID = id, fields = {}, reason = "itemData" }) end
		end
	else
		-- Item definitions do not change when equipment/collections are opened.
		-- Character-dependent fields are resolved from the caller's fresh context.
		if event == "PLAYER_LEVEL_UP" then F.baseCache, F.baseOrder, F.baseNext = {}, {}, 1 end
		P.Emit({ reason = event, fields = {} })
	end
end
if _G.CreateFrame then
	local frame = _G.CreateFrame("Frame")
	for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "PLAYER_EQUIPMENT_CHANGED", "EQUIPMENT_SETS_CHANGED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_SPECIALIZATION_CHANGED", "TRANSMOG_COLLECTION_UPDATED", "NEW_TOY_ADDED", "COMPANION_LEARNED", "PET_JOURNAL_LIST_UPDATE" }) do pcall(frame.RegisterEvent, frame, event) end
	frame:SetScript("OnEvent", function(_, event, ...) P.OnEvent(event, ...) end)
end
