local I = _G.EnhanceQoL.Items
local P = I.internal
-- Cursor and replacement ranges use EditBox byte offsets: [from, to).
function I.Complete(text, cursor, context)
	if not P.Safe(text) or type(text) ~= "string" or #text > 4096 then return {} end
	cursor = P.Number(cursor) and math.max(0, math.min(#text, math.floor(cursor))) or #text
	local prefix = text:sub(1, cursor)
	local partial = prefix:match("([%w_%.]*)$") or ""
	local from, ending = cursor - #partial, cursor
	local openQuote, quoteCharacter, escaped
	for index = 1, cursor do
		local ch = text:sub(index, index)
		if escaped then escaped = false
		elseif openQuote and ch == "\\" then escaped = true
		elseif openQuote and ch == quoteCharacter then openQuote = nil
		elseif not openQuote and (ch == '"' or ch == "'") then openQuote, quoteCharacter = index, ch end
	end
	if openQuote then
		from, partial = openQuote - 1, text:sub(openQuote + 1, cursor)
		for index = cursor + 1, #text do
			local ch = text:sub(index, index)
			if escaped then escaped = false
			elseif ch == "\\" then escaped = true
			elseif ch == quoteCharacter then ending = index; break end
		end
	end
	while not openQuote and ending < #text and text:sub(ending + 1, ending + 1):match("[%w_%.]") do ending = ending + 1 end
	local before = text:sub(1, from)
	local tokens = P.query.Lex(before)
	if not tokens then return {} end
	table.remove(tokens)
	local result, seen = {}, {}
	local function add(label, insertion, description, kind, search)
		if #result >= 64 or seen[insertion] then return end
		if partial ~= "" and not ((search or "") .. " " .. label .. " " .. insertion):lower():find(partial:lower(), 1, true) then return end
		seen[insertion] = true
		result[#result + 1] = { label = label, insertText = insertion, from = from, to = ending, description = description and ((_G.EnhanceQoL.L or {})[description] or description) or nil, kind = kind, rank = insertion:lower():sub(1, #partial) == partial:lower() and 0 or 1 }
	end
	local last = tokens[#tokens]
	local field, expectValue, expectOperator
	if last then
		if last.kind == "word" then
			local canonical = P.Canonical(last.value)
			if canonical then field, expectOperator = I.fields[canonical], true end
		end
		if last.kind == "compare" or last.kind == ":" or last.kind == "contains" or last.kind == "matches" or last.kind == "present" or last.kind == "has" or last.kind == "between" then
			local prior = tokens[#tokens - 1]
			field = prior and I.GetField(prior.value, context); expectValue = field ~= nil
		elseif last.kind == "(" or last.kind == "," then
			for index = #tokens - 1, 2, -1 do
				if tokens[index].kind == "in" then field = I.GetField(tokens[index - 1].value, context); expectValue = field ~= nil; break end
				if tokens[index].kind == "and" or tokens[index].kind == "or" or tokens[index].kind == ")" then break end
			end
		elseif last.kind == "and" then
			for index = #tokens - 1, math.max(2, #tokens - 2), -1 do
				if tokens[index].kind == "between" then field = I.GetField(tokens[index - 1].value, context); expectValue = field ~= nil; break end
			end
		end
	end
	if last and last.kind == "has" and not expectValue then
		for _, definition in ipairs(I.ListFields(context)) do
			if definition.supported and definition.statKey then add((_G.EnhanceQoL.L or {})[definition.labelKey] or definition.name, definition.expressionName or definition.name, definition.labelKey, "field", definition.name) end
		end
		return result
	end
	if expectValue then
		if last and last.kind == "present" then add(_G.YES or "true", "true", field.labelKey, "value"); add(_G.NO or "false", "false", field.labelKey, "value")
		elseif field.valueOptions then
			for _, value in ipairs(field.valueOptions) do
				local display = value.label or value.value
				local insertion = value.token or (type(display) == "string" and '"' .. display:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"' or tostring(display))
				add(value.label or insertion, insertion, field.labelKey, "value")
			end
		elseif field.type == "boolean" then add(_G.YES or "true", "true", field.labelKey, "value"); add(_G.NO or "false", "false", field.labelKey, "value")
		elseif field.type == "number" then
			add("0", "0", field.labelKey, "value")
			add("player.level", "player.level", I.fields["player.level"].labelKey, "reference")
			add("equippedAverage", "equippedAverage", I.fields.equippedAverage.labelKey, "reference")
		end
	elseif expectOperator then
		for _, op in ipairs(field.operators) do add(op:upper(), op == "in" and "IN (" or op:upper() .. " ", field.labelKey, "operator") end
	else
		local expressionStart = not last or last.kind == "and" or last.kind == "or" or last.kind == "not" or last.kind == "("
		if expressionStart then
			for _, definition in ipairs(I.ListFields(context)) do
				if definition.supported and not definition.hidden then add((_G.EnhanceQoL.L or {})[definition.labelKey] or definition.name, definition.expressionName or definition.name, definition.labelKey, "field", definition.name) end
			end
			add("NOT", "NOT ", nil, "operator"); add("HAS", "HAS ", nil, "operator")
		else
			add("AND", "AND ", nil, "operator"); add("OR", "OR ", nil, "operator")
		end
	end
	table.sort(result, function(a, b) if a.rank ~= b.rank then return a.rank < b.rank end; return a.label < b.label end)
	return result
end
