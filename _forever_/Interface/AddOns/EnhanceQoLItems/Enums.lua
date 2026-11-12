local I = _G.EnhanceQoL.Items
local P = I.internal
local E = { cache = {} }
local classTokens = { [0] = 'consumable', [1] = 'container', [2] = 'weapon', [3] = 'gem', [4] = 'armor', [5] = 'reagent', [7] = 'tradegoods', [8] = 'enhancement', [9] = 'recipe', [11] = 'quiver', [12] = 'quest', [13] = 'key', [15] = 'miscellaneous', [16] = 'glyph', [17] = 'battlepet', [18] = 'token', [19] = 'profession', [20] = 'housing' }
local armorTokens = { [0] = 'miscellaneous', [1] = 'cloth', [2] = 'leather', [3] = 'mail', [4] = 'plate', [6] = 'shield', [7] = 'libram', [8] = 'idol', [9] = 'totem', [10] = 'sigil', [11] = 'relic' }
local slots = { 'INVTYPE_HEAD', 'INVTYPE_NECK', 'INVTYPE_SHOULDER', 'INVTYPE_CHEST', 'INVTYPE_ROBE', 'INVTYPE_WAIST', 'INVTYPE_LEGS', 'INVTYPE_FEET', 'INVTYPE_WRIST', 'INVTYPE_HAND', 'INVTYPE_FINGER', 'INVTYPE_TRINKET', 'INVTYPE_CLOAK', 'INVTYPE_WEAPON', 'INVTYPE_SHIELD', 'INVTYPE_2HWEAPON', 'INVTYPE_WEAPONMAINHAND', 'INVTYPE_WEAPONOFFHAND', 'INVTYPE_HOLDABLE', 'INVTYPE_RANGED', 'INVTYPE_RANGEDRIGHT', 'INVTYPE_TABARD', 'INVTYPE_BODY', 'INVTYPE_BAG' }
function P.Flavor(context)
	local variables = _G.EnhanceQoL.variables or {}
	return type(context) == 'table' and context.flavor or (variables.isTBC and 'tbc' or variables.isForever and 'forever' or 'retail')
end
local function nativeLabel(fn, ...)
	if type(fn) ~= 'function' then return nil end
	local ok, label = pcall(fn, ...)
	return ok and P.Safe(label) and type(label) == 'string' and label ~= '' and label or nil
end
local function build(flavor)
	if E.cache[flavor] then return E.cache[flavor] end
	local out = { classID = {}, subclassID = {}, subClassKey = {}, bindType = {}, equipSlot = {}, expansionID = {} }
	local classInfo, subclassInfo = P.Native('GetItemClassInfo'), P.Native('GetItemSubClassInfo')
	local classIDs = {}; for id in pairs(classTokens) do if flavor == 'retail' or id <= 15 then classIDs[#classIDs + 1] = id end end
	table.sort(classIDs)
	for _, id in ipairs(classIDs) do
		local label = nativeLabel(classInfo, id)
		if label then
			out.classID[#out.classID + 1] = { value = id, token = classTokens[id], label = label }
			for sub = 0, 64 do
				local subLabel = nativeLabel(subclassInfo, id, sub)
				if subLabel and not (id == 2 and sub == 17) then
					local token = id == 4 and armorTokens[sub] or nil
					local entry = { value = id .. ':' .. sub, label = label .. ': ' .. subLabel, groupLabel = label, classID = id, subclassID = sub, token = token }
					out.subClassKey[#out.subClassKey + 1] = entry
					out.subclassID[#out.subclassID + 1] = { value = sub, label = entry.label, groupLabel = label, classID = id }
				end
			end
		end
	end
	local bindings = { { 0, 'NONE', 'none' }, { 1, 'ITEM_BIND_ON_PICKUP', 'bop' }, { 2, 'ITEM_BIND_ON_EQUIP', 'boe' }, { 3, 'ITEM_BIND_ON_USE', 'bou' }, { 4, 'ITEM_BIND_QUEST', 'quest' } }
	if flavor == 'retail' then
		bindings[#bindings + 1] = { 7, 'BIND_TO_ACCOUNT', 'warbound' }
		bindings[#bindings + 1] = { 8, 'BIND_TO_BNETACCOUNT', 'account' }
		bindings[#bindings + 1] = { 9, 'BIND_TO_ACCOUNT_UNTIL_EQUIP', 'warboundUntilEquip' }
	end
	for _, entry in ipairs(bindings) do
		local label = _G[entry[2]]
		if type(label) == 'string' then out.bindType[#out.bindType + 1] = { value = entry[1], token = entry[3], label = label } end
	end
	for _, slot in ipairs(slots) do
		local label = _G[slot]
		if type(label) == 'string' then out.equipSlot[#out.equipSlot + 1] = { value = slot, label = label .. ' (' .. slot:gsub('INVTYPE_', '') .. ')' } end
	end
	if flavor ~= 'forever' then
		local maxExpansion = flavor == 'tbc' and 1 or _G.LE_EXPANSION_LEVEL_CURRENT or 0
		for id = 0, math.min(maxExpansion, 30) do
			local label = nativeLabel(_G.GetExpansionName, id) or _G['EXPANSION_NAME' .. id]
			if type(label) == 'string' then out.expansionID[#out.expansionID + 1] = { value = id, label = label } end
		end
	end
	E.cache[flavor] = out
	return out
end
function P.Describe(field, context)
	local entry = P.Copy(field)
	local options = build(P.Flavor(context))[field.name]
	if options then entry.valueOptions = P.Copy(options) end
	entry.supported, entry.reason = P.Capability(field, context)
	return entry
end
-- Stable tokens are independent of localized UI labels and the active client.
I.fields.subClassKey.valueOptions = {}
for id, token in pairs(armorTokens) do I.fields.subClassKey.valueOptions[#I.fields.subClassKey.valueOptions + 1] = { value = '4:' .. id, token = token } end
I.fields.bindType.valueOptions = { { value = 0, token = 'none' }, { value = 1, token = 'bop' }, { value = 2, token = 'boe' }, { value = 3, token = 'bou' }, { value = 4, token = 'quest' }, { value = 7, token = 'warbound' }, { value = 8, token = 'account' }, { value = 9, token = 'warboundUntilEquip' } }

function P.EnumOptions(field)
	local native = build(P.Flavor())[field.name]
	if not native or #native == 0 then return field.valueOptions end
	local options = {}
	for _, option in ipairs(native) do options[#options + 1] = option end
	for _, option in ipairs(field.valueOptions or {}) do options[#options + 1] = option end
	return options
end
-- Display labels are resolved only when parsing/formatting; evaluation keeps native IDs.
function I.ExpressionValue(field, value)
	for _, option in ipairs(P.EnumOptions(field) or {}) do
		if option.value == value then return option.token or option.label or value, option.token ~= nil end
	end
	return value, false
end
