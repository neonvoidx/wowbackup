local I = _G.EnhanceQoL.Items
local P = I.internal
local Q = { compiled = setmetatable({}, { __mode = "k" }), maxDepth = 24, maxNodes = 256, globs = setmetatable({}, { __mode = "k" }) }
P.query = Q
local aliases = { EQUALS = "=", NOT_EQUALS = "!=", LESS_THAN = "<", LESS_OR_EQUAL = "<=", GREATER_THAN = ">", GREATER_OR_EQUAL = ">=", IN = "in", CONTAINS = "contains", ["=="] = "=" }
local function errorAt(code, token, args) return P.Error(code, type(token) == "table" and token.position or token, args) end
local function scalar(field, value)
	if not P.Safe(value) then return nil, "secret_value" end
	if type(value) == "string" then
		for _, option in ipairs((P.EnumOptions and P.EnumOptions(field)) or field.valueOptions or {}) do
			if (option.token and option.token:lower() == value:lower()) or (option.label and option.label:lower() == value:lower()) then value = option.value; break end
		end
	end
	if field.type == "number" then
		if not P.Number(value) then return nil, "expected_number" end
	elseif field.type == "boolean" then
		if type(value) ~= "boolean" then return nil, "expected_boolean" end
	elseif field.type == "string" then
		if type(value) ~= "string" then return nil, "expected_text" end
		if #value > 512 then return nil, "value_too_long" end
	elseif field.type == "set" then
		if type(value) ~= "string" and not P.Number(value) then return nil, "expected_set_value" end
		if type(value) == "string" and #value > 512 then return nil, "value_too_long" end
	end
	return value
end
local function dense(list, limit)
	if type(list) ~= "table" or getmetatable(list) ~= nil then return false end
	local length = #list
	if length > limit then return false end
	for key in pairs(list) do if not P.Number(key) or key < 1 or key > length or key % 1 ~= 0 then return false end end
	for index = 1, length do if list[index] == nil then return false end end
	return true
end
local function validate(node, depth, seen, count, fields)
	if not P.Safe(node) then return P.Error("secret_value") end
	if type(node) ~= "table" or getmetatable(node) ~= nil then return P.Error("invalid_node") end
	if seen[node] then return P.Error("cyclic_query") end
	if depth > Q.maxDepth then return P.Error("query_too_deep") end
	count.value = count.value + 1
	if count.value > Q.maxNodes then return P.Error("too_many_nodes") end
	for key, value in pairs(node) do if not P.Safe(key) or not P.Safe(value) then return P.Error("secret_value") end end
	local shapes = (node.all ~= nil and 1 or 0) + (node.any ~= nil and 1 or 0) + (node["not"] ~= nil and 1 or 0) + (node.field ~= nil and 1 or 0) + (node.constant ~= nil and 1 or 0)
	if shapes ~= 1 then return P.Error("invalid_node") end
	local allowed = { all = true, any = true, ["not"] = true, field = true, op = true, value = true, constant = true, schemaVersion = true }
	for key in pairs(node) do if not allowed[key] then return P.Error("unknown_property", 1, { property = key }) end end
	if node.schemaVersion ~= nil and node.schemaVersion ~= 1 then return P.Error("unsupported_schema") end
	seen[node] = true
	local result
	if node.constant ~= nil then
		if type(node.constant) ~= "boolean" then return P.Error("expected_boolean") end
		result = { constant = node.constant }
	elseif node.all ~= nil or node.any ~= nil then
		local key = node.all ~= nil and "all" or "any"
		if not dense(node[key], Q.maxNodes) then return P.Error("invalid_list") end
		result = { [key] = {} }
		for _, child in ipairs(node[key]) do
			local valid, issue = validate(child, depth + 1, seen, count, fields)
			if not valid then return nil, issue end
			result[key][#result[key] + 1] = valid
		end
	elseif node["not"] ~= nil then
		local child, issue = validate(node["not"], depth + 1, seen, count, fields)
		if not child then return nil, issue end
		result = { ["not"] = child }
	else
		local canonical = P.Canonical(node.field)
		if not canonical then return P.Error("unknown_field", 1, { field = node.field }) end
		local field = I.fields[canonical]
		local op = node.op or "="
		if not P.Safe(op) or type(op) ~= "string" then return P.Error("invalid_operator") end
		op = aliases[op] or op:lower()
		local allowedOp = false
		for _, candidate in ipairs(field.operators) do if candidate == op then allowedOp = true end end
		if not allowedOp then return P.Error("invalid_operator", 1, { field = canonical, operator = op }) end
		local value, issue
		if op == "exists" or op == "present" then
			value = node.value
			if value == nil then value = true end
			if type(value) ~= "boolean" then return P.Error("expected_boolean") end
		elseif op == "in" or op == "between" then
			if not dense(node.value, 64) or #node.value == 0 or (op == "between" and #node.value ~= 2) then return P.Error("invalid_list") end
			value = {}
			for _, entry in ipairs(node.value) do
				local valid, problem = scalar(field, entry)
				if valid == nil then return P.Error(problem) end
				value[#value + 1] = valid
			end
			if op == "between" and value[1] > value[2] then return P.Error("invalid_range") end
		elseif type(node.value) == "table" then
			if field.type ~= "number" or (op ~= "=" and op ~= "!=" and op ~= "<" and op ~= "<=" and op ~= ">" and op ~= ">=") then return P.Error("invalid_reference") end
			if getmetatable(node.value) ~= nil then return P.Error("invalid_reference") end
			for key in pairs(node.value) do if key ~= "ref" and key ~= "offset" then return P.Error("invalid_reference") end end
			local ref = P.Canonical(node.value.ref)
			if ref ~= "equippedAverage" and ref ~= "player.level" then return P.Error("invalid_reference") end
			local offset = node.value.offset or 0
			if not P.Number(offset) or math.abs(offset) > 1000000 then return P.Error("invalid_offset") end
			value = { ref = ref, offset = offset }; fields[ref] = true
		else
			value, issue = scalar(field, node.value)
			if value == nil then return P.Error(issue) end
		end
		result = { field = canonical, op = op, value = value }; fields[canonical] = true
	end
	seen[node] = nil
	return result
end
function Q.Lex(text)
	if not P.Safe(text) or type(text) ~= "string" then return P.Error("expected_text") end
	if #text > 4096 then return P.Error("query_too_long", 4097) end
	local out, position = {}, 1
	while position <= #text do
		local start, ch = position, text:sub(position, position)
		local token
		if ch:match("%s") then position = position + 1
		elseif ch == '"' or ch == "'" then
			local quote, buffer = ch, {}; position = position + 1
			while position <= #text and text:sub(position, position) ~= quote do
				ch = text:sub(position, position)
				if ch == "\\" then
					position = position + 1; ch = text:sub(position, position)
					if ch ~= quote and ch ~= "\\" then return P.Error("invalid_escape", position) end
				end
				buffer[#buffer + 1] = ch; position = position + 1
			end
			if position > #text then return P.Error("unclosed_string", start) end
			position = position + 1; token = { kind = "string", value = table.concat(buffer) }
		elseif ch == "(" or ch == ")" or ch == "," or ch == ":" or ch == "+" then
			position = position + 1; token = { kind = ch, value = ch }
		elseif ch == "&" or ch == "|" then position = position + 1; token = { kind = ch == "&" and "and" or "or" }
		elseif ch == "!" and text:sub(position + 1, position + 1) ~= "=" then position = position + 1; token = { kind = "not" }
		elseif ch == "<" or ch == ">" or ch == "=" or ch == "!" then
			local op = ch; position = position + 1
			if text:sub(position, position) == "=" then op = op .. "="; position = position + 1 end
			if op == "!" then return P.Error("invalid_operator", start) end
			token = { kind = "compare", value = op == "==" and "=" or op }
		elseif ch == "-" and not text:sub(position + 1, position + 1):match("%d") then
			position = position + 1; token = { kind = "-", value = "-" }
		else
			while position <= #text do
				local nextChar = text:sub(position, position)
				if nextChar:match("[%s%(%),:&|<>=!+\"']") then
					if not (nextChar == "+" and text:sub(position - 1, position - 1):match("[eE]") and text:sub(start, position - 2):match("^%-?%d+%.?%d*$") and text:sub(position + 1, position + 1):match("%d")) then break end
				end
				position = position + 1
			end
			if position == start then return P.Error("unexpected_token", start) end
			local word = text:sub(start, position - 1)
			local keyword = ({ ["and"] = true, ["or"] = true, ["not"] = true, ["in"] = true, between = true, contains = true, matches = true, present = true, has = true, exists = true })[word:lower()]
			token = { kind = keyword and word:lower() or "word", value = word }
		end
		if token then token.position, token.ending = start, position - 1; out[#out + 1] = token end
		if #out > 512 then return P.Error("too_many_tokens", start) end
	end
	out[#out + 1] = { kind = "end", position = #text + 1, ending = #text }
	return out
end
local function parseText(text)
	if type(text) == "string" then
		local id = tonumber(text:match("^%s*|c%x+|Hitem:(%d+)[^|]*|h.-|h|r%s*$") or text:match("^%s*|Hitem:(%d+)[^|]*|h.-|h%s*$") or text:match("^%s*item:(%d+)[%d:%-]*%s*$"))
		if id then return { field = "itemID", op = "=", value = id } end
	end
	local tokens, issue = Q.Lex(text)
	if not tokens then return nil, issue end
	local cursor, depth = 1, 0
	local parseOr, parseAnd, unary
	local function consume() local token = tokens[cursor]; cursor = cursor + 1; return token end
	local function literal(field)
		local token = consume()
		if token.kind ~= "word" and token.kind ~= "string" then return errorAt("expected_value", token) end
		local ref = token.kind == "word" and P.Canonical(token.value)
		if field.type == "number" and (ref == "equippedAverage" or ref == "player.level") then
			local offset = 0
			if tokens[cursor].kind == "+" or tokens[cursor].kind == "-" then
				local sign = consume().kind == "+" and 1 or -1
				local number = consume(); offset = tonumber(number.value)
				if number.kind ~= "word" or not P.Number(offset) or offset < 0 then return errorAt("invalid_offset", number) end
				offset = offset * sign
			elseif tokens[cursor].kind == "word" and tokens[cursor].value:match("^%-%d") then
				offset = tonumber(consume().value)
				if not P.Number(offset) then return errorAt("invalid_offset", tokens[cursor - 1]) end
			end
			return { ref = ref, offset = offset }
		end
		local value = token.value
		if token.kind == "word" then
			if field.type == "boolean" then
				if value:lower() == "true" then value = true elseif value:lower() == "false" then value = false end
			elseif field.type == "number" then value = tonumber(value) or value
			elseif field.type == "set" then value = tonumber(value) or value end
		end
		local valid, problem = scalar(field, value)
		if valid ~= nil and field.name == "subClassKey" and not valid:match("^%d+:%d+$") then return errorAt("unknown_enum", token) end
		if valid == nil then return errorAt(problem, token, { field = field.name }) end
		return valid
	end
	unary = function()
		depth = depth + 1
		if depth > Q.maxDepth then return errorAt("query_too_deep", tokens[cursor]) end
		local token, node, problem = consume()
		if token.kind == "not" then
			local child; child, problem = unary(); if child then node = { ["not"] = child } end
		elseif token.kind == "has" then
			local target = consume()
			local canonical = target.kind == "word" and P.Canonical(target.value)
			local field = canonical and I.fields[canonical]
			if not field then return errorAt("unknown_field", target, { field = target.value }) end
			if not field.statKey then return errorAt("invalid_operator", target, { field = canonical, operator = "has" }) end
			node = { field = canonical, op = "present", value = true }
		elseif token.kind == "(" then
			node, problem = parseOr()
			if node and tokens[cursor].kind ~= ")" then return errorAt("expected_close", tokens[cursor]) end
			if node then consume() end
		elseif token.kind == "word" or token.kind == "string" then
			local canonical = token.kind == "word" and P.Canonical(token.value)
			local field = canonical and I.fields[canonical]
			local nextKind = tokens[cursor].kind
			if nextKind == "compare" or nextKind == ":" or nextKind == "in" or nextKind == "between" or nextKind == "contains" or nextKind == "matches" or nextKind == "present" or nextKind == "has" or nextKind == "exists" then
				if not field then return errorAt("unknown_field", token, { field = token.value }) end
				local operator = consume()
				local op = operator.kind == "compare" and operator.value or operator.kind
				if op == ":" then op = field.type == "string" and "contains" or "=" end
				local value
				if op == "in" then
					if tokens[cursor].kind ~= "(" then return errorAt("expected_open", tokens[cursor]) end
					consume(); value = {}
					while true do
						local entry; entry, problem = literal(field)
						if entry == nil then break end
						value[#value + 1] = entry
						if tokens[cursor].kind == ")" then consume(); break end
						if tokens[cursor].kind ~= "," then return errorAt("expected_comma", tokens[cursor]) end
						consume()
					end
				elseif op == "between" then
					local first, second; first, problem = literal(field)
					if first ~= nil then
						if tokens[cursor].kind ~= "and" then return errorAt("expected_and", tokens[cursor]) end
						consume(); second, problem = literal(field)
						if second ~= nil then value = { first, second } end
					end
				elseif op == "exists" then value = true
				elseif op == "present" then value, problem = literal({ type = "boolean" })
				else value, problem = literal(field) end
				if not problem then node = { field = canonical, op = op, value = value } end
			elseif field and field.type == "boolean" then node = { field = canonical, op = "=", value = true }
			elseif token.kind == "word" and (token.value:lower() == "true" or token.value:lower() == "false") then node = { constant = token.value:lower() == "true" }
			elseif token.kind == "word" and tonumber(token.value) then node = { field = "itemID", op = "=", value = tonumber(token.value) }
			else node = { field = "name", op = token.kind == "word" and token.value:find("*", 1, true) and "matches" or "contains", value = token.value } end
		else return errorAt("expected_expression", token) end
		depth = depth - 1
		return node, problem
	end
	parseAnd = function()
		local left, problem = unary()
		if not left then return nil, problem end
		local children = { left }
		while tokens[cursor].kind ~= "end" and tokens[cursor].kind ~= ")" and tokens[cursor].kind ~= "or" do
			if tokens[cursor].kind == "and" then consume() end
			local right; right, problem = unary(); if not right then return nil, problem end
			children[#children + 1] = right
		end
		return #children == 1 and left or { all = children }
	end
	parseOr = function()
		local left, problem = parseAnd()
		if not left then return nil, problem end
		local children = { left }
		while tokens[cursor].kind == "or" do
			consume(); local right; right, problem = parseAnd(); if not right then return nil, problem end
			children[#children + 1] = right
		end
		return #children == 1 and left or { any = children }
	end
	if tokens[1].kind == "end" then return { constant = false } end
	local tree, problem = parseOr()
	if not tree then return nil, problem end
	if tokens[cursor].kind ~= "end" then return errorAt("unexpected_token", tokens[cursor]) end
	return tree
end
function I.Compile(query)
	if not P.Safe(query) then return P.Error("secret_value") end
	if type(query) == "table" and Q.compiled[query] then return query end
	local tree, issue = query
	if type(query) == "string" then tree, issue = parseText(query); if not tree then return nil, issue end end
	local fields = {}
	tree, issue = validate(tree, 1, {}, { value = 0 }, fields)
	if not tree then return nil, issue end
	if Q.FormatRaw and #Q.FormatRaw(tree) > 4096 then return P.Error("query_too_long", 4097) end
	local names = {}; for name in pairs(fields) do names[#names + 1] = name end; table.sort(names)
	local function prepare(node)
		if node.all or node.any then for _, child in ipairs(node.all or node.any) do prepare(child) end
		elseif node["not"] then prepare(node["not"])
		elseif node.op == "matches" then
			local value = node.value:lower()
			local glob = { leading = value:sub(1, 1) == "*", trailing = value:sub(-1) == "*" }
			for part in value:gmatch("[^*]+") do glob[#glob + 1] = part end
			Q.globs[node] = glob
		end
	end
	prepare(tree)
	local compiled = { ast = P.Copy(tree), fields = P.Copy(names), schemaVersion = 1 }
	Q.compiled[compiled] = { ast = tree, fields = names }
	return compiled
end
function I.Parse(text)
	local compiled, issue = I.Compile(text)
	if not compiled then return nil, issue end
	return P.Copy(compiled.ast)
end
local function quote(value)
	if type(value) == "string" then return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"' end
	if type(value) == "table" then
		local offset = value.offset or 0
		return value.ref .. (offset == 0 and "" or offset > 0 and " + " .. tostring(offset) or " - " .. tostring(-offset))
	end
	return tostring(value)
end
local function formatValue(field, value)
	if I.ExpressionValue and type(value) ~= "table" then
		local readable, token = I.ExpressionValue(field, value)
		return token and readable or quote(readable)
	end
	return quote(value)
end
local function format(node)
	if node.constant ~= nil then return node.constant and "true" or "false" end
	if node.all or node.any then
		local list, parts = node.all or node.any, {}
		if #list == 0 then return node.all and "true" or "false" end
		for _, child in ipairs(list) do parts[#parts + 1] = format(child) end
		return "(" .. table.concat(parts, node.all and " AND " or " OR ") .. ")"
	end
	if node["not"] then return "NOT (" .. format(node["not"]) .. ")" end
	local field = I.fields[node.field]
	local name = field.expressionName or node.field
	if node.op == "present" then return node.value and "HAS " .. node.field or "NOT (HAS " .. node.field .. ")" end
	if node.op == "exists" then return node.value and name .. " EXISTS" or "NOT (" .. name .. " EXISTS)" end
	if node.op == "in" then
		local values = {}; for _, value in ipairs(node.value) do values[#values + 1] = formatValue(field, value) end
		return name .. " IN (" .. table.concat(values, ", ") .. ")"
	end
	if node.op == "between" then return name .. " BETWEEN " .. quote(node.value[1]) .. " AND " .. quote(node.value[2]) end
	return name .. " " .. node.op .. " " .. ((node.op == "=" or node.op == "!=") and formatValue(field, node.value) or quote(node.value))
end
Q.FormatRaw = format
function I.Format(query)
	local compiled, issue = I.Compile(query)
	if not compiled then return nil, issue end
	local text = format(Q.compiled[compiled].ast)
	local valid, problem = I.Compile(text)
	if not valid then return nil, problem end
	return text
end
local function evaluate(node, facts, statuses)
	if node.constant ~= nil then return node.constant end
	if node["not"] then local value = evaluate(node["not"], facts, statuses); if value == nil then return nil end; return not value end
	if node.all or node.any then
		local unknown = false
		for _, child in ipairs(node.all or node.any) do
			local value = evaluate(child, facts, statuses)
			if node.all and value == false then return false end
			if node.any and value == true then return true end
			if value == nil then unknown = true end
		end
		if unknown then return nil end
		return node.all ~= nil
	end
	local actual, status = facts[node.field], statuses[node.field]
	if not P.Safe(actual) or not P.Safe(status) then return nil end
	if status == nil then status = actual ~= nil and "known" or "missing" end
	if node.op == "exists" then
		if status == "pending" or status == "unsupported" then return nil end
		return (status == "known" and actual ~= nil) == node.value
	end
	if status ~= "known" or actual == nil then return nil end
	if node.op == "present" then
		if not P.Number(actual) then return nil end
		return (actual > 0) == node.value
	end
	local expected = node.value
	if type(expected) == "table" and expected.ref then
		local reference, referenceStatus = facts[expected.ref], statuses[expected.ref]
		if not P.Number(reference) or not P.Safe(referenceStatus) or (referenceStatus ~= nil and referenceStatus ~= "known") then return nil end
		expected = reference + expected.offset
		if not P.Number(expected) then return nil end
	end
	if node.op == "has" or (node.op == "contains" and I.fields[node.field].type == "set") then
		if type(actual) ~= "table" then return nil end
		local direct = actual[expected]
		if not P.Safe(direct) then return nil end
		if direct == true then return true end
		for _, value in ipairs(actual) do
			if not P.Safe(value) then return nil end
			if node.op == "contains" and I.fields[node.field].textSet and type(value) == "string" and type(expected) == "string" then
				if value:lower():find(expected:lower(), 1, true) then return true end
			elseif value == expected then return true end
		end
		return false
	end
	if node.op == "in" then
		if type(actual) ~= I.fields[node.field].type then return nil end
		for _, value in ipairs(expected) do if actual == value then return true end end
		return false
	end
	if node.op == "between" then
		if not P.Number(actual) then return nil end
		return actual >= expected[1] and actual <= expected[2]
	end
	if type(actual) ~= type(expected) then return nil end
	if type(actual) == "number" and not P.Number(actual) then return nil end
	if node.op == "matches" then
		local glob, value, position = Q.globs[node], actual:lower(), 1
		for index, part in ipairs(glob) do
			local first, last
			if index == #glob and not glob.trailing then
				first, last = #value - #part + 1, #value
				if first < position or value:sub(first) ~= part then return false end
			else first, last = value:find(part, position, true) end
			if not first or (index == 1 and not glob.leading and first ~= 1) then return false end
			position = last + 1
		end
		return #glob > 0 or glob.leading or value == ""
	end
	if node.op == "contains" then return actual:lower():find(expected:lower(), 1, true) ~= nil end
	if node.op == "=" then return actual == expected elseif node.op == "!=" then return actual ~= expected end
	if node.op == "<" then return actual < expected elseif node.op == "<=" then return actual <= expected end
	if node.op == ">" then return actual > expected elseif node.op == ">=" then return actual >= expected end
	return nil
end
function I.Evaluate(query, facts, statuses)
	local compiled, issue = I.Compile(query)
	if not compiled then return nil, issue end
	if type(facts) ~= "table" or (statuses ~= nil and type(statuses) ~= "table") then return P.Error("invalid_facts") end
	return evaluate(Q.compiled[compiled].ast, facts, statuses or {})
end
function I.MatchSnapshot(query, items, context)
	local compiled, issue = I.Compile(query)
	if not compiled then return nil, issue end
	if not dense(items, 10000) then return P.Error("invalid_snapshot") end
	local result = { matches = {}, unresolved = {}, total = #items, revision = P.revision }
	for index, item in ipairs(items) do
		local facts, statuses = I.Get(item, Q.compiled[compiled].fields, context)
		local matches = I.Evaluate(compiled, facts, statuses)
		local entry = { index = index, item = item, facts = facts, statuses = statuses }
		if matches == true then result.matches[#result.matches + 1] = entry
		elseif matches == nil then result.unresolved[#result.unresolved + 1] = entry end
	end
	return result
end
