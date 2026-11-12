local I = _G.EnhanceQoL.Items
local P = I.internal
local function add(name, kind, source, aliases)
	I.fields[name] = { name = name, type = kind, source = source, scope = "variant", category = "details",
		labelKey = "ItemsField" .. name:gsub("^%l", string.upper), aliases = aliases or {},
		operators = kind == "string" and { "=", "!=", "contains", "in", "exists" } or { "has", "contains", "exists" } }
	I.aliases[name:lower()] = name
	for _, alias in ipairs(aliases or {}) do I.aliases[alias:lower()] = name end
end
add("tooltipText", "string", "tooltip", { "tooltip", "text" })
add("tooltipTerms", "set", "tooltip")
add("enchantments", "set", "tooltip", { "enchant" })
add("gemLinks", "set", "gems", { "gems" })
I.fields.tooltipTerms.textSet, I.fields.enchantments.textSet = true, true
for _, name in ipairs({ "isOpenable", "isReadable", "isConjured" }) do I.fields[name].source = "tooltip"; I.fields[name].scope = "variant" end
local patterns = { isOpenable = { "ITEM_OPENABLE" }, isReadable = { "ITEM_READABLE" }, isConjured = { "ITEM_CONJURED" } }
local function matchesFormat(text, template)
	if type(template) ~= "string" or template == "" then return false end
	local pieces, offset = {}, 1
	while true do
		local first, last = template:find("%%[%d%$%.%-]*[sdif]", offset)
		pieces[#pieces + 1] = template:sub(offset, first and first - 1 or #template):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		if not first then break end
		pieces[#pieces + 1] = ".+"; offset = last + 1
	end
	return text:match("^" .. table.concat(pieces) .. "$") ~= nil
end
local function location(state)
	if state.context.offline then return nil end
	local loc = state.context.itemLocation
	if type(loc) ~= "table" then return nil end
	local getID, getLink = P.Native("GetItemID"), P.Native("GetItemLink")
	if type(getID) ~= "function" or type(getLink) ~= "function" then return nil end
	local ok, id = pcall(getID, loc)
	local linked, link = pcall(getLink, loc)
	if not ok or not linked or not P.Safe(id) or not P.Safe(link) then return nil end
	if id ~= state.item.itemID or not state.item.link or link ~= state.item.link then return nil end
	if not P.Safe(loc.bagID) or not P.Safe(loc.slotIndex) or not P.Safe(loc.equipmentSlotIndex) then return nil end
	return loc
end
local function tooltip(state, resolve)
	if state.tooltip then return state.tooltip, state.tooltipStatus end
	state.tooltip = {}
	local api = _G.C_TooltipInfo
	if not api then state.tooltipStatus = "unsupported"; return state.tooltip, state.tooltipStatus end
	local _, nameStatus = resolve("name")
	if nameStatus ~= "known" then state.tooltipStatus = nameStatus; return state.tooltip, nameStatus end
	local loc, ok, data = location(state)
	if loc and loc.bagID ~= nil and api.GetBagItem then ok, data = pcall(api.GetBagItem, loc.bagID, loc.slotIndex)
	elseif loc and loc.equipmentSlotIndex ~= nil and api.GetInventoryItem then ok, data = pcall(api.GetInventoryItem, "player", loc.equipmentSlotIndex)
	elseif api.GetHyperlink then
		local link = state.item.link or resolve("link")
		if type(link) == "string" then ok, data = pcall(api.GetHyperlink, link) end
	end
	if not ok or not P.Safe(data) or type(data) ~= "table" or not P.Safe(data.lines) or type(data.lines) ~= "table" or #data.lines == 0 then state.tooltipStatus = "missing"; return state.tooltip, state.tooltipStatus end
	local terms, enchantments, flags = {}, {}, {}
	local types = _G.Enum and _G.Enum.TooltipDataLineType or {}
	for index, line in ipairs(data.lines) do
		if index > 80 then break end
		if not P.Safe(line) or type(line) ~= "table" or not P.Safe(line.type) then state.tooltipStatus = "missing"; return state.tooltip, state.tooltipStatus end
		for _, side in ipairs({ "leftText", "rightText" }) do
			local text = line[side]
			if not P.Safe(text) then state.tooltipStatus = "missing"; return state.tooltip, state.tooltipStatus end
			if type(text) == "string" and text ~= "" then
				text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):sub(1, 1024)
				terms[#terms + 1] = text
				if types.ItemEnchantmentPermanent and line.type == types.ItemEnchantmentPermanent then enchantments[#enchantments + 1] = text end
				for name, globals in pairs(patterns) do
					for _, global in ipairs(globals) do if matchesFormat(text, _G[global]) then flags[name] = true end end
				end
			end
		end
	end
	state.tooltip = { tooltipText = table.concat(terms, "\n"), tooltipTerms = terms, enchantments = enchantments }
	for name, value in pairs(flags) do state.tooltip[name] = value end
	state.tooltipStatus = "known"
	return state.tooltip, state.tooltipStatus
end
function P.ExtraCapability(field)
	if field.source == "tooltip" then
		if not (_G.C_TooltipInfo and type(_G.C_TooltipInfo.GetHyperlink) == "function") then return false, "unsupported" end
		if field.name == "enchantments" then return _G.Enum and _G.Enum.TooltipDataLineType and _G.Enum.TooltipDataLineType.ItemEnchantmentPermanent ~= nil or false, "tooltip" end
		if patterns[field.name] then
			for _, name in ipairs(patterns[field.name]) do if type(_G[name]) == "string" and _G[name] ~= "" then return true, "tooltip" end end
			return false, "unsupported"
		end
		return true, "tooltip"
	elseif field.source == "gems" then return type(P.Native("GetItemGem")) == "function", "itemData" end
	return false, "unsupported"
end
function P.ResolveExtra(field, state, resolve)
	if field.source == "tooltip" then
		local values, status = tooltip(state, resolve)
		local value = values[field.name]
		-- A missing localized marker does not prove a negative classifier.
		return value, status == "known" and value == nil and "missing" or status
	elseif field.source == "gems" then
		local _, status = resolve("name")
		if status ~= "known" then return nil, status end
		local link = state.item.link or resolve("link")
		if type(link) ~= "string" then return nil, "missing" end
		local gems = {}
		for index = 1, 4 do
			local ok, _, gem = pcall(P.Native("GetItemGem"), link, index)
			if not ok or not P.Safe(gem) then return nil, "missing" end
			if type(gem) == "string" then gems[#gems + 1] = gem
			elseif P.Native("GetItemGemID") then
				local idOK, id = pcall(P.Native("GetItemGemID"), link, index)
				if not idOK or not P.Safe(id) or (P.Number(id) and id > 0) then return nil, "missing" end
			end
		end
		return gems, "known"
	end
	return nil, "unsupported"
end
