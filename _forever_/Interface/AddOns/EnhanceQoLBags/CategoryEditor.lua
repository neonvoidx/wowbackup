local addon = _G.EnhanceQoL
local L = addon.L
local E = { context = { consumer = "bags", mode = "category" } }
addon.Bags.CategoryEditor = E
local Panel = {}
Panel.__index = Panel

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function text(key) return L[key] or key end
local function fieldName(field) return field.label or (field.labelKey and L[field.labelKey]) or field.name or field.id end
local function fieldID(field) return field.name or field.id end
local function supported(field)
	return field.supported ~= false and field.available ~= false and field.disabled ~= true and field.availability ~= "unavailable"
end
function E.Context() return addon.GetCategoryFilterContext and addon.GetCategoryFilterContext() or E.context end
local function children(node) return node.all or node.any end
local function operatorLabel(op)
	local key = ({ ["in"] = "In", ["not in"] = "NotIn", contains = "Contains", matches = "Matches", present = "Present", has = "Has", between = "Between", exists = "Exists" })[op]
	return key and text("itemFilterOperator" .. key) or op
end
local function locate(tree, path)
	local node = tree
	for _, key in ipairs(path) do node = node[key] end
	return node
end
local function pathTo(path, key)
	local result = copy(path)
	result[#result + 1] = key
	return result
end
local function replace(tree, path, value)
	if #path == 0 then return value end
	local parent = tree
	for index = 1, #path - 1 do parent = parent[path[index]] end
	parent[path[#path]] = value
	return tree
end
local function button(parent, label, width, callback)
	local control = addon.Bags.SettingsNavigation.CreateButton("Button", nil, parent)
	control:SetSize(width or 100, 24)
	control:SetText(label)
	control:SetScript("OnClick", callback)
	return control
end
local function label(parent, value, font)
	local control = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
	control:SetJustifyH("LEFT")
	control:SetText(value)
	return control
end
local function tooltip(control, title, detail)
	control:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(title)
		if detail then GameTooltip:AddLine(detail, 0.8, 0.8, 0.8, true) end
		GameTooltip:Show()
	end)
	control:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

-- Drafts are detached from SavedVariables. Neither invalid text nor changing
-- categories replaces the last successfully applied rule.
function E.NewDraft(categoryID)
	local draft = addon.CreateCategoryFilterDraft(categoryID)
	return { categoryID = categoryID, ast = copy(draft.ast), source = draft.text or "", error = draft.error,
		readOnly = draft.readOnly, dirty = false, view = "visual" }
end
function E.Validate(draft, source)
	draft.source, draft.dirty = source, true
	local ast, issue = addon.ValidateCategoryItemFilter(source)
	draft.error = issue
	if ast then draft.ast = copy(ast) end
	return ast, issue
end
function E.Apply(draft)
	if draft.readOnly or draft.error then return false, draft.error end
	local ok, issue = addon.SetCategoryItemFilter(draft.categoryID, draft.ast)
	if ok then draft.dirty = false else draft.error = issue end
	return ok, issue
end
function E.Replace(draft, path, value)
	local candidate = replace(copy(draft.ast), path, copy(value))
	local ast, issue = addon.ValidateCategoryItemFilter(candidate)
	if not ast then return false, issue end
	draft.ast, draft.dirty, draft.error = copy(ast), true, nil
	draft.source = addon.Items.Format(ast) or draft.source
	return true
end
function E.Fields()
	return addon.Items.ListFields(E.Context())
end

function Panel:RefreshStatus()
	local draft = self.draft
	if not draft then return end
	if draft.readOnly then self.status:SetText(text("itemFilterReadOnly"))
	elseif draft.error then
		local message = draft.error.message or text("itemFilterInvalid")
		if draft.error.code then message = L["ItemsError_" .. draft.error.code] or message end
		self.status:SetText(text("itemFilterError"):format(draft.error.position or 1, message))
	else self.status:SetText(text(draft.dirty and "itemFilterDraft" or "itemFilterSaved")) end
	self.apply:SetEnabled(draft.dirty and not draft.error and not draft.readOnly)
	self.cancel:SetEnabled(draft.dirty)
	self.visual:SetEnabled(not draft.error and not draft.readOnly)
	self.testButton:SetEnabled(not draft.error and not draft.readOnly)
	self.expression:SetEnabled(not draft.readOnly)
end
function Panel:Change(path, node)
	local ok, issue = E.Replace(self.draft, path, node)
	if not ok then self.draft.error = issue end
	self:Render()
end
function Panel:Add(path, group)
	if not group then
		local anchor = self.visual
		for _, row in ipairs(self.rows) do
			local same = #row.path == #path
			for index, key in ipairs(path) do if row.path[index] ~= key then same = false; break end end
			if same then anchor = row.add; break end
		end
		self:OpenFields(path, anchor, true)
		return
	end
	local node = copy(locate(self.draft.ast, path))
	if not children(node) then node = { all = node.constant == false and {} or { node } } end
	local list = children(node)
	list[#list + 1] = { all = { { field = "quality", op = ">=", value = 2 } } }
	self:Change(path, node)
end
function Panel:Remove(path)
	local tree = copy(self.draft.ast)
	if #path == 0 then return self:Change({}, { constant = false }) end
	local parentPath = copy(path)
	local key = table.remove(parentPath)
	local parent = locate(tree, parentPath)
	if type(key) == "number" then table.remove(parent, key) else parent[key] = nil end
	-- Removing the only child of NOT removes the whole negation.
	if key == "not" then tree = replace(tree, parentPath, { constant = false }) end
	if children(tree) and #children(tree) == 0 then tree = { constant = false } end
	self:Change({}, tree)
end
function Panel:Move(path, direction)
	local tree, parentPath = copy(self.draft.ast), copy(path)
	local index = table.remove(parentPath)
	if type(index) ~= "number" then return end
	local list = locate(tree, parentPath)
	if list[index + direction] then
		list[index], list[index + direction] = list[index + direction], list[index]
		self:Change({}, tree)
	end
end
function Panel:FindField(name)
	if self.renderFields and self.renderFields[name] then return self.renderFields[name] end
	local field = addon.Items.GetField(name, E.Context()) or { name = name, type = "string", supported = false }
	if self.renderFields then self.renderFields[name] = field end
	return field
end
-- Menu leaves produce ordinary staged rules; the search picker is an optional shortcut.
function Panel:CommitCondition(path, adding, condition)
	local target = copy(path)
	if adding then
		local node = copy(locate(self.draft.ast, path))
		if not children(node) then node = { all = node.constant == false and {} or { node } } end
		local list = children(node); list[#list + 1] = condition
		target = pathTo(pathTo(path, node.all and "all" or "any"), #list)
		self:Change(path, node)
	else self:Change(path, condition) end
	for _, row in ipairs(self.rows) do
		local same = #row.path == #target
		for index, key in ipairs(target) do if row.path[index] ~= key then same = false end end
		if same and row.input:IsShown() then row.input:SetFocus(); if row.input.HighlightText then row.input:HighlightText() end end
	end
end
function Panel:OpenFields(path, anchor, adding)
	self:OpenFieldSearch(path, anchor, adding)
end
local function fieldSection(field)
	if field.name == "subClassKey" or field.name == "classID" then return "type" end
	if field.name == "isBound" or field.name == "bindType" or field.name == "isBoE" or field.name == "isBoP" or field.name == "isBoU" then return "binding" end
	local category = field.category or "item"
	return category == "details" and "other" or category
end
function Panel:BrowseSections()
	local groups, seen = {}, {}
	local function add(id, caption)
		if not seen[id] then seen[id] = true; groups[#groups + 1] = { id = id, label = caption } end
	end
	add("all", text("itemFilterBrowseAll"))
	if self.pickerChoices then
		for _, choice in ipairs(self.pickerChoices) do if choice.groupLabel then add(choice.groupLabel, choice.groupLabel) end end
	else
		local names = { item = "InventoryFilterCategoryItem", type = "InventoryFilterCategoryType", stats = "itemFilterAttributes", binding = "InventoryFilterCategoryBinding", collection = "InventoryFilterCategoryCollection", context = "settingsCategoryRuleGroupSmart", other = "InventoryFilterCategoryOther" }
		local available = {}
		for _, field in ipairs(E.Fields()) do if supported(field) and not field.hidden then available[fieldSection(field)] = true end end
		for _, id in ipairs({ "item", "type", "stats", "binding", "collection", "context", "other" }) do if available[id] then add(id, text(names[id])) end end
		for id in pairs(available) do if not names[id] then add(id, text(names.other)) end end
	end
	self.browseGroups = groups
	if not seen[self.browseGroup] then self.browseGroup = "all" end
	self.browseGroupOffset = 0
	self:RenderSections()
end
function Panel:RenderSections()
	for index, button in ipairs(self.sectionRows) do
		local group = self.browseGroups[index + (self.browseGroupOffset or 0)]
		button:SetShown(group ~= nil)
		if group then
			button:SetText((group.id == self.browseGroup and "> " or "") .. group.label)
			button:SetScript("OnClick", function()
				self.browseGroup = group.id
				self.fieldSearch:SetText("")
				self:RenderSections(); self:FilterFields()
			end)
		end
	end
end
function Panel:OpenFieldSearch(path, anchor, adding)
	self.pickerChoices = nil
	self.browseGroup = self.lastFieldSection or "item"
	self.pickerTitle:SetText(text("itemFilterSearchFields"))
	self.pickerBack:Hide()
	self:BrowseSections()
	tooltip(self.fieldSearch, text("itemFilterSearchFields"))
	self.pickerAdding = adding == true
	self.pickerPath, self.pickerAnchor = copy(path), anchor
	self.picker:ClearAllPoints()
	self.picker:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, -18)
	self.picker:SetWidth(560)
	self.picker:Show()
	self.fieldSearch:SetText("")
	self.fieldSearch:SetFocus()
	self:FilterFields()
end
function Panel:PickValues(anchor, choices)
	self.lastFieldSection = not self.pickerChoices and self.browseGroup or self.lastFieldSection
	self.pickerChoices = choices
	self.browseGroup = "all"
	self.pickerBack:Show()
	self:BrowseSections()
	tooltip(self.fieldSearch, text("itemFilterSearchValues"))
	self.picker:ClearAllPoints()
	self.picker:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, -18)
	self.picker:SetWidth(560)
	self.picker:Show()
	self.fieldSearch:SetText("")
	self.fieldSearch:SetFocus()
	self:FilterFields()
end
local function fieldHelp(field)
	local samples = {}
	for index, option in ipairs(field.valueOptions or {}) do
		if index > 5 then break end
		samples[#samples + 1] = option.label or tostring(option.value)
	end
	return #samples > 0 and table.concat(samples, "\n") or field.description
end
function Panel:FilterFields()
	local search = self.fieldSearch:GetText():lower()
	self.pickerFields = {}
	if self.pickerChoices then
		for _, choice in ipairs(self.pickerChoices) do
			if (search ~= "" and choice.label:lower():find(search, 1, true)) or (search == "" and (self.browseGroup == "all" or choice.groupLabel == self.browseGroup)) then self.pickerFields[#self.pickerFields + 1] = choice end
		end
		self.pickerOffset = 0; self:RenderFields(); return
	end
	for _, field in ipairs(E.Fields()) do
		local searchable = fieldName(field) .. " " .. fieldID(field)
		for _, option in ipairs(field.valueOptions or {}) do searchable = searchable .. " " .. (option.label or "") end
		if supported(field) and not field.hidden and ((search ~= "" and searchable:lower():find(search, 1, true)) or (search == "" and (self.browseGroup == "all" or fieldSection(field) == self.browseGroup))) then
			self.pickerFields[#self.pickerFields + 1] = field
		end
	end
	table.sort(self.pickerFields, function(a, b) return fieldName(a) < fieldName(b) end)
	self.pickerOffset = 0
	self:RenderFields()
end
function Panel:RenderFields()
	if self.pickerCount then self.pickerCount:SetText(string.format("%d–%d / %d", #self.pickerFields > 0 and self.pickerOffset + 1 or 0, math.min(#self.pickerFields, self.pickerOffset + 8), #self.pickerFields)) end
	for index = 1, 8 do
		local field, row = self.pickerFields[index + self.pickerOffset], self.fieldRows[index]
		row:SetShown(field ~= nil)
		if field and self.pickerChoices then
			row:SetText((field.checked and "[x] " or "") .. field.label)
			tooltip(row, field.label)
			row:SetScript("OnClick", function()
				self.picker:Hide()
				field.choose()
			end)
		elseif field then
			row:SetText(fieldName(field))
			tooltip(row, fieldName(field), fieldHelp(field))
			row:SetScript("OnClick", function()
				self.pickerTitle:SetText(fieldName(field))
				local kind = field.type
				local value = kind == "boolean" and true or kind == "number" and 0 or ""
				local operation = field.statKey and "present" or field.valueOptions and "=" or kind == "string" and "contains" or kind == "set" and "has" or "="
				if field.statKey then value = true end
				local valid = false
				for _, op in ipairs(field.operators or {}) do if op == operation then valid = true end end
				if not valid then operation = (field.operators or {})[1] or operation end
				local function commit(chosen)
					self.picker:Hide()
					self:CommitCondition(self.pickerPath, self.pickerAdding, { field = fieldID(field), op = operation, value = chosen })
				end
				if field.valueOptions and #field.valueOptions > 0 then
					local choices = {}
					for _, option in ipairs(field.valueOptions) do
						local entry = option
						choices[#choices + 1] = { label = entry.label or entry.token or tostring(entry.value), groupLabel = entry.groupLabel, choose = function() commit(entry.value) end }
					end
					self:PickValues(row, choices)
				elseif field.name == "name" then
					local choices = {}
					for _, op in ipairs({ "contains", "matches", "=" }) do
						choices[#choices + 1] = { label = text(op == "contains" and "itemFilterNameContains" or op == "matches" and "itemFilterNameMatches" or "itemFilterNameExact"), choose = function() operation = op; commit("") end }
					end
					self:PickValues(row, choices)
				else commit(value) end
			end)
		end
	end
end
function Panel:Menu(anchor, choices)
	local function choose(entry) if entry.choose then entry.choose() end end
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(anchor, function(_, root)
			local function populate(parent, entries)
				if parent.SetScrollMode then parent:SetScrollMode(300) end
				for _, entry in ipairs(entries) do
					if entry.children then populate(parent:CreateButton(entry.label), entry.children)
					elseif entry.action then parent:CreateButton(entry.label, function() choose(entry) end)
					elseif entry.multiple then parent:CreateCheckbox(entry.label, function() return entry.checked == true end, function() choose(entry) end)
					else parent:CreateRadio(entry.label, function() return entry.checked == true end, function() choose(entry) end) end
				end
			end
			populate(root, choices)
		end)
	elseif UIDropDownMenu_Initialize then
		if not self.legacyMenu then self.legacyMenu = CreateFrame("Frame", nil, self.frame, "UIDropDownMenuTemplate") end
		UIDropDownMenu_Initialize(self.legacyMenu, function(_, level, menuList)
			level = level or 1
			local entries = level == 1 and choices or menuList or UIDROPDOWNMENU_MENU_VALUE
			for _, entry in ipairs(type(entries) == "table" and entries or {}) do
				local info = UIDropDownMenu_CreateInfo()
				info.text, info.checked = entry.label, entry.checked
				info.hasArrow, info.notCheckable = entry.children ~= nil, entry.children ~= nil or entry.action == true
				info.menuList, info.value = entry.children, entry.children
				info.func = function() choose(entry) end
				info.isNotRadio = entry.multiple
				info.keepShownOnClick = entry.multiple
				UIDropDownMenu_AddButton(info, level)
			end
		end, "MENU")
		ToggleDropDownMenu(1, nil, self.legacyMenu, anchor, 0, 0)
	end
end
function Panel:Operators(path, anchor)
	local node = locate(self.draft.ast, path)
	local field, choices = self:FindField(node.field), {}
	for _, operation in ipairs(field.operators or { "=", "!=" }) do
		local op = type(operation) == "table" and (operation.value or operation.id or operation.op) or operation
		choices[#choices + 1] = { label = operatorLabel(op), checked = node.op == op, choose = function()
			local updated = copy(node)
			updated.op = op
			if node.op == "exists" or node.op == "present" then updated.value = field.type == "boolean" and true or field.type == "number" and 0 or "" end
			if (op == "exists" or op == "present") then updated.value = true
			elseif op == "between" then
				local value = type(updated.value) == "number" and updated.value or 0
				updated.value = { value, value }
			elseif op == "in" or op == "not in" then
				if type(updated.value) ~= "table" then updated.value = { updated.value } end
			elseif type(updated.value) == "table" and not updated.value.ref then updated.value = updated.value[1]
			elseif (node.op == "exists" or node.op == "present") then updated.value = field.type == "boolean" and true or field.type == "number" and 0 or "" end
			self:Change(path, updated)
		end }
	end
	self:Menu(anchor, choices)
end
function Panel:Values(path, anchor)
	local node = locate(self.draft.ast, path)
	local field, values, choices = self:FindField(node.field), {}, {}
	if field.type == "boolean" or (node.op == "exists" or node.op == "present") then values = { { value = true, label = text("itemFilterTrue") }, { value = false, label = text("itemFilterFalse") } }
	elseif field.valueOptions then values = field.valueOptions
	elseif field.values then values = field.values
	elseif node.field == "quality" then
		for quality = 0, 8 do values[#values + 1] = { value = quality, label = _G["ITEM_QUALITY" .. quality .. "_DESC"] or tostring(quality) } end
	end
	for key, entry in pairs(values) do
		local value = entry
		if type(entry) == "table" then value = entry.value; if value == nil then value = entry.id end end
		local caption = type(entry) == "table" and (entry.label or entry.name) or tostring(entry)
		if value == nil then value = key end
		local multiple, checked = node.op == "in" or node.op == "not in", node.value == value
		if multiple then for _, candidate in ipairs(type(node.value) == "table" and node.value or {}) do if candidate == value then checked = true end end end
		choices[#choices + 1] = { label = caption or tostring(value), groupLabel = type(entry) == "table" and entry.groupLabel or nil, checked = checked, multiple = multiple, choose = function()
			local updated = copy(node)
			if node.op == "in" or node.op == "not in" then
				local list, found = copy(type(node.value) == "table" and node.value or { node.value }), false
				for index = #list, 1, -1 do if list[index] == value then table.remove(list, index); found = true end end
				if not found then list[#list + 1] = value end
				updated.value = list
			else updated.value = value end
			self:Change(path, updated)
		end }
	end
	self.pickerPath, self.pickerAdding = copy(path), false
	self.pickerTitle:SetText(fieldName(field))
	if #choices > 8 or field.name == "subClassKey" then self:PickValues(anchor, choices) else self:Menu(anchor, choices) end
end
function Panel:ValueText(node, field)
	local function scalar(value)
		if type(value) == "boolean" then return text(value and "itemFilterTrue" or "itemFilterFalse") end
		field = field or self:FindField(node.field)
		for _, option in ipairs(field.valueOptions or {}) do if option.value == value then return option.label or option.token or tostring(value) end end
		if node.field == "quality" then return _G["ITEM_QUALITY" .. tostring(value) .. "_DESC"] or tostring(value) end
		return tostring(value or "")
	end
	if type(node.value) == "table" then
		if node.value.ref then return "@" .. node.value.ref .. ((node.value.offset or 0) ~= 0 and string.format("%+d", node.value.offset) or "") end
		local parts = {}
		for _, value in ipairs(node.value) do parts[#parts + 1] = scalar(value) end
		return table.concat(parts, ", ")
	end
	return scalar(node.value)
end
function Panel:CommitValue(row)
	if self.rendering or not row.node then return end
	local node, value = copy(row.node), row.input:GetText()
	local field = self:FindField(node.field)
	if node.op == "in" or node.op == "not in" or node.op == "between" then
		local values = {}
		for entry in value:gmatch("[^,]+") do
			local trimmed = entry:match("^%s*(.-)%s*$")
			if field.type == "number" and not tonumber(trimmed) then self.draft.error = { message = text("itemFilterInvalid") }; self:RefreshStatus(); return end
			values[#values + 1] = field.type == "number" and tonumber(trimmed) or trimmed
		end
		node.value = values
	elseif field.type == "number" and not value:match("^@") then
		node.value = tonumber(value)
		if node.value == nil then self.draft.error = { message = text("itemFilterInvalid") }; self:RefreshStatus(); return end
	elseif value:match("^@") then
		local ref, offset = value:match("^@([%w%.]+)([+-]%d+)$")
		node.value = { ref = ref or value:sub(2), offset = tonumber(offset) or 0 }
	else node.value = value end
	local ok, issue = E.Replace(self.draft, row.path, node)
	if not ok then self.draft.error = issue; self:RefreshStatus() else self:Render() end
end

function Panel:AcquireRow(index)
	if self.rows[index] then return self.rows[index] end
	local row = CreateFrame("Frame", nil, self.body)
	row.title = label(row, "")
	row.field = button(row, "", 150, function(selfButton) self:OpenFields(row.path, selfButton) end)
	row.op = button(row, "=", 64, function(selfButton) self:Operators(row.path, selfButton) end)
	row.value = button(row, "", 140, function(selfButton) self:Values(row.path, selfButton) end)
	row.input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	row.input:SetAutoFocus(false)
	row.input:SetScript("OnEnterPressed", function(box) self:CommitValue(row); box:ClearFocus() end)
	row.input:SetScript("OnEditFocusLost", function() self:CommitValue(row) end)
	row.remove = button(row, "×", 24, function() self:Remove(row.path) end)
	tooltip(row.remove, text("itemFilterRemove"))
	row.up = button(row, "↑", 24, function() self:Move(row.path, -1) end)
	row.down = button(row, "↓", 24, function() self:Move(row.path, 1) end)
	tooltip(row.up, text("itemFilterUp")); tooltip(row.down, text("itemFilterDown"))
	row.negate = button(row, "NOT", 44, function() self:Change(row.path, row.node["not"] and row.node["not"] or { ["not"] = copy(row.node) }) end)
	tooltip(row.negate, text("itemFilterNot"))
	row.mode = button(row, "", 180, function()
		local node = row.node
		self:Change(row.path, node.all and { any = copy(node.all) } or { all = copy(node.any) })
	end)
	row.add = button(row, text("itemFilterAdd"), 130, function() self:Add(row.path, false) end)
	row.group = button(row, text("itemFilterAddGroup"), 150, function() self:Add(row.path, true) end)
	row.actions = button(row, "...", 28, function(anchor)
		local choices = {}
		if children(row.node) then choices[#choices + 1] = { label = text("itemFilterAddGroup"), choose = function() self:Add(row.path, true) end } end
		choices[#choices + 1] = { label = text(row.node["not"] and "itemFilterInclude" or "itemFilterNot"), choose = function() self:Change(row.path, row.node["not"] and row.node["not"] or { ["not"] = copy(row.node) }) end }
		if type(row.path[#row.path]) == "number" then
			choices[#choices + 1] = { label = text("itemFilterUp"), choose = function() self:Move(row.path, -1) end }
			choices[#choices + 1] = { label = text("itemFilterDown"), choose = function() self:Move(row.path, 1) end }
		end
		choices[#choices + 1] = { label = text("itemFilterRemove"), choose = function() self:Remove(row.path) end }
		for _, choice in ipairs(choices) do choice.action = true end
		self:Menu(anchor, choices)
	end)
	tooltip(row.actions, _G.OPTIONS or text("itemFilterChoose"))
	self.rows[index] = row
	return row
end
function Panel:RenderNode(node, path, depth, y)
	self.rowIndex = self.rowIndex + 1
	local row = self:AcquireRow(self.rowIndex)
	row.node, row.path = copy(node), copy(path)
	row:Show(); row:ClearAllPoints()
	local indent = math.min(30, depth * 10)
	row:SetPoint("TOPLEFT", self.body, "TOPLEFT", indent, -y)
	row:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, -y)
	local width = math.max(200, (self.body:GetWidth() or 400) - indent)
	for _, key in ipairs({ "title", "field", "op", "value", "input", "mode", "add", "group", "negate", "remove", "up", "down", "actions" }) do row[key]:Hide(); row[key]:ClearAllPoints() end
	row.actions:Show(); row.actions:SetPoint("TOPRIGHT", -2, -2)
	local list = children(node)
	if list then
		row:SetHeight(30)
		row.mode:Show(); row.mode:SetPoint("TOPLEFT", 2, -2); row.mode:SetWidth(width - 38)
		row.mode:SetText(text(node.all and "itemFilterAll" or "itemFilterAny"))
	elseif node["not"] then
		row:SetHeight(28); row.title:Show(); row.title:SetPoint("TOPLEFT", 6, -6); row.title:SetText(text("itemFilterNot"))
	elseif node.constant ~= nil then
		row.actions:SetShown(node.constant == true)
		row.title:Show(); row.title:SetPoint("TOPLEFT", 4, -4); row.title:SetWidth(width - 12)
		row.title:SetText(text(node.constant and "itemFilterAll" or "itemFilterEmpty"))
		local titleHeight = math.max(16, row.title:GetStringHeight())
		row.title:SetHeight(titleHeight)
		row.add:Show(); row.add:SetPoint("TOPLEFT", 2, -titleHeight - 12); row.add:SetWidth(width - 8)
		row:SetHeight(titleHeight + 42)
	else
		local field = self:FindField(node.field)
		local inline = width >= 340
		local fieldWidth = math.floor((width - 44) * 0.30)
		local operatorWidth = math.max(90, math.floor((width - 44) * 0.26))
		row:SetHeight(inline and 28 or 56)
		row.field:Show(); row.field:SetPoint("TOPLEFT", 2, -2); row.field:SetWidth(math.max(76, fieldWidth))
		row.field:SetText(fieldName(field)); tooltip(row.field, fieldName(field), not supported(field) and text("itemFilterUnavailable") or fieldHelp(field))
		row.op:Show(); row.op:SetPoint("LEFT", row.field, "RIGHT", 6, 0); row.op:SetWidth(operatorWidth); row.op:SetText(node.op == "matches" and "~" or operatorLabel(node.op or "=")); tooltip(row.op, operatorLabel(node.op or "="))
		local enum = (node.op == "exists" or node.op == "present") or (node.op ~= "between" and (field.type == "boolean" or field.valueOptions or field.values or node.field == "quality"))
		local value = enum and row.value or row.input
		value:Show(); value:SetHeight(24)
		if inline then value:SetPoint("LEFT", row.op, "RIGHT", 6, 0); value:SetWidth(math.max(100, width - fieldWidth - operatorWidth - 50))
		else value:SetPoint("TOPLEFT", row, "TOPLEFT", enum and 2 or 6, -32); value:SetWidth(width - (enum and 8 or 14)) end
		local caption = node.op == "between" and table.concat(node.value, ", ") or self:ValueText(node, field)
		value:SetText(caption)
		if enum then tooltip(value, caption) end
	end
	y = y + row:GetHeight() + 6
	if list then
		local key = node.all and "all" or "any"
		for index, child in ipairs(list) do y = self:RenderNode(child, pathTo(pathTo(path, key), index), depth + 1, y) end
		row.add:Show(); row.add:SetPoint("TOPLEFT", self.body, "TOPLEFT", indent + 2, -y); row.add:SetWidth(width - 8)
		y = y + 32
	elseif node["not"] then y = self:RenderNode(node["not"], pathTo(path, "not"), depth + 1, y) end
	return y
end
function Panel:RestoreCompletionCursor()
	if self.arrowCursor and self.input:GetText() == self.arrowSource then
		if self.input:GetCursorPosition() ~= self.arrowCursor then
			self.restoringArrow = true; self.input:SetCursorPosition(self.arrowCursor); self.restoringArrow = nil
		end
		return true
	end
end
function Panel:CompletionArrow(key, origin)
	if not self.suggestions:IsShown() or (key ~= "UP" and key ~= "DOWN") then return end
	if (_G.IsAltKeyDown and _G.IsAltKeyDown()) or (_G.IsShiftKeyDown and _G.IsShiftKeyDown()) then return end
	if self.arrowKey == key and self.arrowOrigin and self.arrowOrigin ~= origin then
		self:RestoreCompletionCursor(); self.arrowKey, self.arrowOrigin = nil, nil
		return true
	end
	self.arrowKey, self.arrowOrigin = key, origin
	self.arrowCursor, self.arrowSource = self.completionCursor or self.input:GetCursorPosition(), self.input:GetText()
	self:RestoreCompletionCursor()
	self.completionIndex = math.max(1, math.min(#self.completions, self.completionIndex + (key == "DOWN" and 1 or -1)))
	self:RenderCompletions()
	return true
end
function Panel:DismissCompletions()
	self.completionDismissed, self.completionPendingCursor = true, nil
	self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
	self.suggestions:Hide()
	self:Layout()
end
function Panel:Complete()
	if self.completionDismissed or self.settingText or self.arrowCursor or not self.input:HasFocus() then return end
	local source, cursor = self.input:GetText(), self.input:GetCursorPosition()
	if self.suggestions:IsShown() and self.completionSource == source and self.completionCursor == cursor and self.completionDraft == self.draft then return end
	self.completionSource, self.completionDraft = source, self.draft
	local prefix = source:sub(1, cursor):match("[%w_%.]+$")
	self.completionCursor = cursor
	self.completions = addon.Items.Complete(source, cursor, E.Context())
	if not prefix and not source:sub(1, cursor):match("%s$") and self.completions[1] and self.completions[1].kind ~= "value" then self.completions = {} end
	self.completionIndex = 1
	self:RenderCompletions()
end
function Panel:RenderCompletions()
	local count = math.min(5, #(self.completions or {}))
	self.completionIndex = math.max(1, math.min(#(self.completions or {}), self.completionIndex or 1))
	self.completionOffset = math.max(0, math.min(self.completionOffset or 0, math.max(0, #self.completions - count)))
	if self.completionIndex <= self.completionOffset then self.completionOffset = self.completionIndex - 1 end
	if self.completionIndex > self.completionOffset + count then self.completionOffset = self.completionIndex - count end
	if count > 0 and self.draft.view == "text" and self.input.SetAltArrowKeyMode then
		if self.savedArrowMode == nil then self.savedArrowMode = self.input:GetAltArrowKeyMode() == true end
		self.input:SetAltArrowKeyMode(false)
	end
	self.suggestions:SetShown(count > 0 and self.draft.view == "text")
	local overflow = #(self.completions or {}) > 5
	local popupHeight = count * 27 + 8 + (overflow and 26 or 0)
	self.completionCount:SetShown(overflow)
	self.completionCount:SetText(string.format("%d–%d / %d", self.completionOffset + 1, self.completionOffset + count, #self.completions))
		self.suggestions:ClearAllPoints()
	self.suggestions:SetPoint("TOPLEFT", self.textScroll, "BOTTOMLEFT", 0, -6)
	self.suggestions:SetPoint("RIGHT", self.textScroll, "RIGHT", 0, 0)
	self.suggestions:SetHeight(popupHeight)
	for index = 1, 5 do
		local entryIndex = index + self.completionOffset
		local row, suggestion = self.suggestionRows[index], self.completions and self.completions[entryIndex]
		row.completionIndex = entryIndex
		row:SetShown(index <= count)
		if suggestion then
			row:SetText((entryIndex == self.completionIndex and "> " or "") .. suggestion.label)
			tooltip(row, suggestion.label, suggestion.description)
		end
	end
	self:Layout()
end
function Panel:AcceptCompletion(index)
	if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
	self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
	local completion = self.completions and self.completions[index or self.completionIndex]
	if not completion then return end
	local source = self.input:GetText()
	local first, last = completion.from or self.input:GetCursorPosition(), completion.to or self.input:GetCursorPosition()
	local inserted = completion.insertText or completion.label
	local suffix, advance = source:sub(last + 1), 0
	if suffix:match("^%s") then
		inserted = inserted:gsub("%s+$", "")
		advance = #(suffix:match("^%s+") or "")
	elseif not inserted:match("[%s%(]$") and not suffix:match("^[,%)]") then
		inserted = inserted .. " "
	end
	self.input:SetText(source:sub(1, first) .. inserted .. suffix)
	self.input:SetCursorPosition(first + #inserted + advance)
	self.input:SetFocus()
	self:Complete()
end
-- Preview work is opt-in and coalesced; invalid drafts retain the last result.
function Panel:RefreshTestPreview()
	if not self.testPreview or not self.testPreview:IsShown() or not self.draft then return end
	local draft = self.draft
	if draft.error or draft.readOnly then return end
	local key = self.draftKey .. ":" .. draft.source
	if self.testPreviewKey == key and not self.testPreviewDirty then return end
	local result = addon.PreviewCategoryItemFilter(draft.categoryID, draft.ast)
	if result.error then return end
	self.testPreviewKey, self.testPreviewDirty = key, nil
	self.testMatches, self.testPending = {}, {}
	for _, item in ipairs(result.items) do
		if item.matches then self.testMatches[#self.testMatches + 1] = item end
		if item.pending then self.testPending[item.itemID] = true end
	end
	self.testOffset = math.min(self.testOffset or 0, math.max(0, #self.testMatches - 10))
	self:RenderTestPreview()
end
function Panel:RenderTestPreview()
	local items, offset = self.testMatches or {}, self.testOffset or 0
	self.testEmpty:SetShown(#items == 0)
	self.testCount:SetText(#items > 0 and string.format("%d–%d / %d", offset + 1, math.min(offset + 10, #items), #items) or "0")
	for index, row in ipairs(self.testRows) do
		local item = items[offset + index]
		row:SetShown(item ~= nil)
		if item then
			row.item = item
			row.Icon:SetTexture(item.icon or 134400)
			row:SetText(item.link or item.name or tostring(item.itemID))
		end
	end
	self.testPrevious:SetEnabled(offset > 0)
	self.testNext:SetEnabled(offset + 10 < #items)
end
function Panel:OpenTestPreview()
	if not self.testPreview then
		local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		self.testPreview = frame
		frame:SetSize(310, 360); frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(self.frame:GetFrameLevel() + 20)
		frame:SetClampedToScreen(true); frame:EnableMouse(true)
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame:SetBackdropColor(0.03, 0.05, 0.08, 1); frame:SetBackdropBorderColor(0.3, 0.5, 0.65, 1)
		local title = label(frame, text("itemFilterTestPreview"), "GameFontNormal")
		title:SetPoint("TOPLEFT", 12, -12)
		local close = button(frame, "×", 24, function() frame:Hide() end); close:SetPoint("TOPRIGHT", -6, -6)
		self.testEmpty = label(frame, text("itemFilterTestEmpty")); self.testEmpty:SetPoint("TOPLEFT", 12, -48); self.testEmpty:SetWidth(286)
		self.testRows = {}
		for index = 1, 10 do
			local row = button(frame, "", 286); row:SetPoint("TOPLEFT", 12, -40 - (index - 1) * 28)
			row.Icon = row:CreateTexture(nil, "ARTWORK"); row.Icon:SetSize(24, 24); row.Icon:SetPoint("LEFT", 0, 0)
			local name = row:GetFontString(); name:ClearAllPoints(); name:SetPoint("LEFT", row.Icon, "RIGHT", 6, 0); name:SetPoint("RIGHT", -6, 0); name:SetJustifyH("LEFT")
			row:SetScript("OnEnter", function(control)
				if GameTooltip and control.item and control.item.link then GameTooltip:SetOwner(control, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(control.item.link); GameTooltip:Show() end
			end)
			row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
			self.testRows[index] = row
		end
		self.testCount = label(frame, ""); self.testCount:SetPoint("BOTTOMLEFT", 12, 14)
		self.testPrevious = button(frame, "<", 26, function() self.testOffset = math.max(0, self.testOffset - 10); self:RenderTestPreview() end)
		self.testNext = button(frame, ">", 26, function() self.testOffset = math.min(math.max(0, #self.testMatches - 10), self.testOffset + 10); self:RenderTestPreview() end)
		self.testNext:SetPoint("BOTTOMRIGHT", -10, 8); self.testPrevious:SetPoint("RIGHT", self.testNext, "LEFT", -4, 0)
		frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel", function(_, delta)
			self.testOffset = math.max(0, math.min(math.max(0, #(self.testMatches or {}) - 10), (self.testOffset or 0) - delta * 3)); self:RenderTestPreview()
		end)
		frame:SetScript("OnEvent", function(_, event, itemID)
			if frame:IsShown() and (event == "BAG_UPDATE_DELAYED" or (self.testPending and self.testPending[itemID])) then self.testPreviewDirty = true end
		end)
		frame:RegisterEvent("BAG_UPDATE_DELAYED"); frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		frame:SetScript("OnUpdate", function(_, elapsed)
			self.testElapsed = (self.testElapsed or 0) + elapsed
			if self.testElapsed < 0.3 then return end
			self.testElapsed = 0; self:RefreshTestPreview()
		end)
	end
	local owner = addon.Bags.variables and addon.Bags.variables.settingsState and addon.Bags.variables.settingsState.frame or self.frame
	self.testPreview:ClearAllPoints(); self.testPreview:SetPoint("TOPLEFT", owner, "TOPRIGHT", 10, 0)
	self.testPreview:Show(); self.testPreviewDirty = true
	self:RefreshTestPreview()
end
function Panel:GetHeight() return self.contentHeight or 220 end
function Panel:Layout()
	if self.layingOut or not self.draft then return end
	self.layingOut = true
	local width = math.max(220, self.frame:GetWidth())
	local visual = self.draft.view == "visual" and not self.draft.readOnly
	local _, newlines = (self.draft.source or ""):gsub("\n", "")
	local textHeight = math.max(96, math.min(200, (newlines + 1) * 16 + 24))
	local viewport = visual and math.min(300, math.max(40, self.ruleHeight or 40)) or textHeight
	self.scroll:SetHeight(viewport)
	self.textScroll:SetHeight(textHeight)
	local y = 34 + viewport + 10
	if not visual and self.suggestions:IsShown() then y = y + self.suggestions:GetHeight() + 6 end
	local function place(region, padding)
		region:ClearAllPoints(); region:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -y); region:SetWidth(width - 4)
		local height = math.max(16, region:GetStringHeight())
		region:SetHeight(height); y = y + height + (padding or 8)
	end
	if not visual then place(self.syntax, 10) end
	local statusVisible = self.draft.error ~= nil or self.draft.readOnly
	self.status:SetShown(statusVisible)
	if statusVisible then place(self.status, 8) end
	local actions = self.draft.dirty
	self.apply:SetShown(actions); self.cancel:SetShown(actions)
	if actions then
		self.apply:ClearAllPoints(); self.cancel:ClearAllPoints()
		self.apply:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -y)
		if width >= 300 then self.cancel:SetPoint("LEFT", self.apply, "RIGHT", 8, 0); y = y + 34
		else self.cancel:SetPoint("TOPLEFT", self.apply, "BOTTOMLEFT", 0, -6); y = y + 64 end
	end
	local changed = self.contentHeight ~= y
	self.contentHeight = y
	self.layingOut = nil
	if changed and self.onLayout then self.onLayout(y) end
end
function Panel:Render()
	if not self.draft then return end
	self.rendering = true
	self.renderFields = {}
	self.rowIndex = 0
	local visual = self.draft.view == "visual" and not self.draft.readOnly
	local height = visual and self:RenderNode(self.draft.ast or { constant = false }, {}, 0, 0) or 0
	for index = self.rowIndex + 1, #self.rows do self.rows[index]:Hide() end
	self.ruleHeight = height
	self.body:SetHeight(math.max(1, height))
	self.scroll:SetShown(visual)
	self.textScroll:SetShown(not visual)
	if self.input.SetEnabled then self.input:SetEnabled(not self.draft.readOnly) end
	if not visual and self.input:GetText() ~= self.draft.source then
		if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
		self.settingText = true; self.input:SetText(self.draft.source); self.settingText = nil
	end
	self.syntax:SetShown(not visual)
	for control, active in pairs({ [self.visual] = visual, [self.expression] = not visual }) do
		local texture = control.GetNormalTexture and control:GetNormalTexture()
		if texture then texture:SetVertexColor(active and 0.22 or 0.07, active and 0.26 or 0.1, active and 0.31 or 0.15, 1) end
	end
	self:RefreshStatus(); self:Layout()
	self.renderFields = nil
	self.rendering = false
end
function Panel:Select(categoryID, category)
	if not categoryID then self.frame:Hide(); return end
	if self.database ~= addon.db then self.drafts, self.draft, self.database = {}, nil, addon.db end
	local mode = addon.GetActiveCategoryMode and addon.GetActiveCategoryMode() or "advanced"
	local key = mode .. ":" .. categoryID
	if category and self.drafts[key] and self.drafts[key].categoryRef ~= category then self.drafts[key], self.draft = nil, nil end
	if self.draft and self.draftKey == key then self.frame:Show(); self:Render(); return end
	if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
	self.drafts[key] = self.drafts[key] or E.NewDraft(categoryID)
	self.drafts[key].categoryRef = category
	self.draft, self.draftKey = self.drafts[key], key
	self.picker:Hide(); self.suggestions:Hide()
	self.scroll:SetVerticalScroll(0)
	self.frame:Show(); self:Render()
end

function E.Create(parent, onApplied, onLayout)
	E.serial = (E.serial or 0) + 1
	local self = setmetatable({ rows = {}, drafts = {}, onApplied = onApplied, onLayout = onLayout }, Panel)
	self.frame = CreateFrame("Frame", nil, parent)
	self.frame:SetAllPoints()
	self.visual = button(self.frame, text("itemFilterVisualMode"), 100, function()
		if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
		if self.draft.error then self:RefreshStatus(); return end
		self.picker:Hide(); self.input:ClearFocus(); self.draft.view = "visual"; self.suggestions:Hide(); self:Render()
	end)
	self.visual:SetPoint("TOPLEFT", 0, 0)
	self.expression = button(self.frame, text("itemFilterText"), 100, function() if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end; self.picker:Hide(); self.draft.view = "text"; self:Render() end)
	self.expression:SetPoint("LEFT", self.visual, "RIGHT", 1, 0)
	self.visual:SetHeight(22); self.expression:SetHeight(22)
	self.testButton = button(self.frame, text("itemFilterTestAction"), 64, function() self:OpenTestPreview() end)
	self.testButton:SetPoint("TOPRIGHT", 0, 0); self.testButton:SetHeight(22)
	self.scroll = CreateFrame("ScrollFrame", "EQOLBagsFilterScroll" .. E.serial, self.frame, "UIPanelScrollFrameTemplate")
	self.scroll:SetPoint("TOPLEFT", 0, -34); self.scroll:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -26, -34); self.scroll:SetHeight(40)
	self.body = CreateFrame("Frame", nil, self.scroll); self.body:SetSize(400, 278); self.scroll:SetScrollChild(self.body)
	self.scroll:SetScript("OnSizeChanged", function(frame, width) self.body:SetWidth(width); if self.draft and not self.rendering then self:Render() end end)
	self.textScroll = CreateFrame("ScrollFrame", "EQOLBagsExpressionScroll" .. E.serial, self.frame, "UIPanelScrollFrameTemplate")
	self.textScroll:SetPoint("TOPLEFT", 4, -36); self.textScroll:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -26, -36); self.textScroll:SetHeight(144)
	self.input = CreateFrame("EditBox", nil, self.textScroll)
	self.input:SetMultiLine(true); self.input:SetAutoFocus(false); self.input:SetFontObject(ChatFontNormal)
	self.input:SetSize(360, 224); self.textScroll:SetScrollChild(self.input)
	self.textScroll:SetScript("OnSizeChanged", function(_, width) self.input:SetWidth(width) end)
	self.input:SetScript("OnTextChanged", function(box)
		if self.settingText or not self.draft or self.draft.readOnly then return end
		self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
		self.completionDismissed, self.completionPendingCursor = nil, true
		E.Validate(self.draft, box:GetText()); self:RefreshStatus(); self:Complete(); self:Layout()
	end)
	self.input:SetScript("OnCursorChanged", function(_, _, y, _, height)
		if self.restoringArrow or self:RestoreCompletionCursor() then return end
		self.cursorY = y
		local offset, visible = self.textScroll:GetVerticalScroll(), self.textScroll:GetHeight()
		if -y < offset then self.textScroll:SetVerticalScroll(-y) elseif -y + height > offset + visible then self.textScroll:SetVerticalScroll(-y + height - visible) end
		if self.completionPendingCursor or self.suggestions:IsShown() then self:Complete() end
		self.completionPendingCursor = nil
	end)
	self.input:SetScript("OnKeyDown", function(_, key)
		if self:CompletionArrow(key, "key") then return end
		self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
		if key == "ESCAPE" then self:DismissCompletions() end
	end)
	self.input:SetScript("OnArrowPressed", function(_, key) return self:CompletionArrow(key, "native") end)
	self.input:SetScript("OnKeyUp", function()
		self:RestoreCompletionCursor()
		self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
	end)
	self.input:SetScript("OnTabPressed", function() self:AcceptCompletion() end)
	self.input:SetScript("OnEnterPressed", function()
		if self.suggestions:IsShown() then self:AcceptCompletion() end
	end)
	self.input:SetScript("OnEscapePressed", function() self:DismissCompletions() end)
	self.input:SetScript("OnEditFocusLost", function()
		-- Mouse selection accepts on down; allow its focus restoration before
		-- dismissing the popup for clicks elsewhere or native focus changes.
		if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
		C_Timer.After(0, function() if not self.input:HasFocus() then self.suggestions:Hide() end end)
	end)
	if addon.BufferedPaste then addon.BufferedPaste:Attach(self.input, function() return self.draft and not self.draft.readOnly end) end
	self.syntax = label(self.frame, text("itemFilterSyntax"), "GameFontDisableSmall")
	self.syntax:SetPoint("TOPLEFT", 0, -266); self.syntax:SetPoint("RIGHT", -10, 0); self.syntax:SetHeight(42)
	self.status = label(self.frame, ""); self.status:SetPoint("TOPLEFT", 0, -320); self.status:SetPoint("RIGHT", -4, 0); self.status:SetHeight(44)
	self.apply = button(self.frame, text("itemFilterApply"), 140, function()
		if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
		if E.Apply(self.draft) then if self.onApplied then self.onApplied() end end
		self:Render()
	end)
	self.apply:SetPoint("TOPLEFT", 0, -368)
	self.cancel = button(self.frame, text("itemFilterCancel"), 140, function()
		if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end
		local id, category = self.draft.categoryID, self.draft.categoryRef
		self.drafts[self.draftKey] = nil; self.draft = nil; self:Select(id, category)
	end)
	self.cancel:SetPoint("TOPLEFT", 0, -398)
	self.picker = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); self.picker:SetSize(560, 330)
	self.picker:SetFrameStrata("FULLSCREEN_DIALOG")
	self.picker:EnableMouse(true)
	if self.picker.SetClampedToScreen then self.picker:SetClampedToScreen(true) end; self.picker:SetFrameLevel(self.frame:GetFrameLevel() + 15)
	self.picker:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	self.picker:SetBackdropColor(0.06, 0.09, 0.13, 1); self.picker:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
	self.fieldSearch = CreateFrame("EditBox", nil, self.picker, "InputBoxTemplate"); self.fieldSearch:SetAutoFocus(false); self.fieldSearch:SetHeight(24); self.fieldSearch:SetPoint("TOPLEFT", 10, -36); self.fieldSearch:SetPoint("RIGHT", -34, 0)
	tooltip(self.fieldSearch, text("itemFilterSearchFields")); self.fieldSearch:SetScript("OnTextChanged", function() self:FilterFields() end)
	self.fieldSearch:SetScript("OnEnterPressed", function() if self.pickerFields[1] then self.fieldRows[1]:GetScript("OnClick")(self.fieldRows[1]) end end)
	self.fieldSearch:SetScript("OnEscapePressed", function() self.picker:Hide() end)
	local close = button(self.picker, "×", 24, function() self.picker:Hide() end); close:SetPoint("TOPRIGHT", -4, -8)
	self.pickerTitle = label(self.picker, "", "GameFontNormal")
	self.pickerTitle:SetPoint("TOPLEFT", 86, -12); self.pickerTitle:SetWidth(430)
	self.pickerBack = button(self.picker, _G.BACK or "<", 70, function() self:OpenFieldSearch(self.pickerPath, self.pickerAnchor, self.pickerAdding) end)
	self.pickerBack:SetPoint("TOPLEFT", 8, -6)
	self.sections = CreateFrame("Frame", nil, self.picker)
	self.sections:SetPoint("TOPLEFT", 8, -68); self.sections:SetSize(138, 232)
	self.sectionRows = {}
	for index = 1, 8 do
		local row = button(self.sections, "", 138)
		row:SetPoint("TOPLEFT", 0, -(index - 1) * 29)
		self.sectionRows[index] = row
	end
	self.sections:EnableMouseWheel(true)
	self.sections:SetScript("OnMouseWheel", function(_, delta)
		self.browseGroupOffset = math.max(0, math.min(math.max(0, #self.browseGroups - 8), (self.browseGroupOffset or 0) - delta))
		self:RenderSections()
	end)
	self.fieldRows = {}
	for index = 1, 8 do
		local row = button(self.picker, "", 260); row:SetPoint("TOPLEFT", 154, -68 - ((index - 1) * 29)); row:SetPoint("RIGHT", -8, 0); self.fieldRows[index] = row
	end
	self.pickerCount = label(self.picker, "", "GameFontDisableSmall")
	self.pickerCount:SetPoint("BOTTOMLEFT", 10, 8)
	self.picker:EnableMouseWheel(true); self.picker:SetScript("OnMouseWheel", function(_, delta)
		self.pickerOffset = math.max(0, math.min(math.max(0, #self.pickerFields - 8), self.pickerOffset - delta * 3)); self:RenderFields()
	end)
	self.picker:Hide()
	self.suggestions = CreateFrame("Frame", nil, self.frame, "BackdropTemplate"); self.suggestions:SetFrameLevel(self.frame:GetFrameLevel() + 20)
	self.suggestions:SetPoint("TOPLEFT", self.textScroll, "BOTTOMLEFT", 0, 0); self.suggestions:SetPoint("RIGHT", self.textScroll, "RIGHT", 0, 0); self.suggestions:SetHeight(140)
	self.suggestions:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" }); self.suggestions:SetBackdropColor(0.06, 0.09, 0.13, 1)
	self.suggestionRows = {}
	for index = 1, 5 do
		local row = button(self.suggestions, "", 280)
		row:SetScript("OnMouseDown", function(_, mouseButton) if mouseButton == "LeftButton" then self:AcceptCompletion(row.completionIndex) end end)
		row:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 27)); row:SetPoint("RIGHT", -4, 0); self.suggestionRows[index] = row
	end
	self.completionCount = label(self.suggestions, "", "GameFontDisableSmall")
	self.completionCount:SetPoint("BOTTOMLEFT", 8, 9)
	self.suggestions:SetScript("OnHide", function()
		if self.savedArrowMode ~= nil then self.input:SetAltArrowKeyMode(self.savedArrowMode); self.savedArrowMode = nil end
		self.arrowCursor, self.arrowSource, self.arrowKey, self.arrowOrigin = nil, nil, nil, nil
		self:Layout()
	end)
	self.suggestions:EnableMouseWheel(true)
	self.suggestions:SetScript("OnMouseWheel", function(_, delta)
		self.completionIndex = math.max(1, math.min(#(self.completions or {}), self.completionIndex - delta))
		self:RenderCompletions()
	end)
	self.suggestions:Hide()
	for _, scroll in ipairs({ self.scroll, self.textScroll }) do
		local bar = scroll.ScrollBar or _G[scroll:GetName() .. "ScrollBar"]
		if bar then scroll.ScrollBar = bar; addon.Bags.SettingsNavigation.StyleScrollBar(scroll, bar) end
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", addon.Bags.SettingsNavigation.ScrollMouseWheel)
	end
	self.frame:SetScript("OnHide", function() if addon.BufferedPaste then addon.BufferedPaste:Finish(self.input) end; self.picker:Hide(); self.suggestions:Hide(); if self.testPreview then self.testPreview:Hide() end end)
	return self
end
