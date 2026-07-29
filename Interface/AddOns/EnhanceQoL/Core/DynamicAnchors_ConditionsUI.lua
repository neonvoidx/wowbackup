local _, addon = ...

local DynamicAnchors = addon.DynamicAnchors
if not DynamicAnchors then return end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local ROW_HEIGHT = 38
local ROW_GAP = 5
local INDENT = 18

local function flatNodes(root, depth, result)
	result = result or {}
	if type(root) ~= "table" then return result end
	result[#result + 1] = { node = root, depth = depth or 0 }
	for _, child in ipairs(root.children or {}) do flatNodes(child, (depth or 0) + 1, result) end
	return result
end

function DynamicAnchors:GetConditionEditorHeight(candidate)
	local root = self:EnsureCandidateConditionRoot(candidate)
	return 20 + (#flatNodes(root, 0) * (ROW_HEIGHT + ROW_GAP))
end

local function button(parent, width)
	local frame = CreateFrame("Button", nil, parent, "BackdropTemplate")
	frame:SetSize(width, 28)
	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.Text:SetPoint("LEFT", frame, "LEFT", 10, 0)
	frame.Text:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
	frame.Text:SetJustifyH("CENTER")
	frame.Text:SetWordWrap(false)
	frame.SetText = function(self, value) self.Text:SetText(value or "") end
	local settingsUI = addon.LibSettingsDesigner and addon.LibSettingsDesigner.UI
	if settingsUI and settingsUI.ApplyFlatButtonVisual then
		frame._eqolOwner = parent
		frame._eqolNormalBg = settingsUI.ThemeColors.buttonBg
		frame._eqolNormalBorder = settingsUI.ThemeColors.buttonBorder
		frame._eqolBorderStyleKey = "button"
		settingsUI.ApplyFlatButtonVisual(frame)
		frame:SetScript("OnLeave", function(self) settingsUI.ApplyFlatButtonVisual(self) end)
	end
	return frame
end

local function menu(owner, entries)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		for _, entry in ipairs(entries) do
			if entry.divider then
				root:CreateDivider()
			else
				root:CreateButton(entry.label, function(data)
					if data and type(data.action) == "function" then data.action() end
				end, entry)
			end
		end
	end)
end

local function multiMenu(owner, entries, currentValues, onChanged)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
	local selected = {}
	for _, value in ipairs(type(currentValues) == "table" and currentValues or { currentValues }) do selected[value] = true end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		for _, entry in ipairs(entries) do
			root:CreateCheckbox(entry.label, function(data)
				return selected[data.value] == true
			end, function(data)
				selected[data.value] = not selected[data.value]
				local values = {}
				for _, option in ipairs(entries) do if selected[option.value] then values[#values + 1] = option.value end end
				onChanged(values)
			end, entry)
		end
	end)
end

local function classIcon(token)
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
	if not coords then return "" end
	return ("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:14:14:0:-1:256:256:%d:%d:%d:%d|t "):format(
		math.floor(coords[1] * 256 + 0.5), math.floor(coords[2] * 256 + 0.5),
		math.floor(coords[3] * 256 + 0.5), math.floor(coords[4] * 256 + 0.5)
	)
end

local function roleIcon(role)
	local atlas = _G.GetIconForRole and _G.GetIconForRole(role, false)
	return atlas and CreateAtlasMarkup and (CreateAtlasMarkup(atlas, 14, 14, 0, -1) .. " ") or ""
end

local function classEntries(callback)
	local values = {}
	for classID = 1, (GetNumClasses and GetNumClasses() or 13) do
		local name, token = GetClassInfo(classID)
		if token then values[#values + 1] = { name = name or token, value = token } end
	end
	table.sort(values, function(a, b) return tostring(a.name) < tostring(b.name) end)
	local entries = {}
	for _, value in ipairs(values) do
		entries[#entries + 1] = { value = value.value, label = classIcon(value.value) .. value.name, action = callback and function() callback(value.value) end or nil }
	end
	return entries
end

local function specEntries(callback)
	local classes = {}
	for classID = 1, (GetNumClasses and GetNumClasses() or 13) do
		local className = GetClassInfo(classID)
		local specs = {}
		local count = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID and C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 4
		for index = 1, count do
			local specID, name, _, icon = GetSpecializationInfoForClassID(classID, index)
			if specID and name then specs[#specs + 1] = { id = specID, name = name, icon = icon } end
		end
		table.sort(specs, function(a, b) return tostring(a.name) < tostring(b.name) end)
		if #specs > 0 then classes[#classes + 1] = { name = className or tostring(classID), specs = specs } end
	end
	table.sort(classes, function(a, b) return tostring(a.name) < tostring(b.name) end)
	local entries = {}
	for _, class in ipairs(classes) do
		for _, spec in ipairs(class.specs) do
			local icon = spec.icon and ("|T%d:14:14:0:-1|t "):format(spec.icon) or ""
			entries[#entries + 1] = { value = spec.id, label = icon .. class.name .. " - " .. spec.name, action = callback and function() callback(spec.id) end or nil }
		end
	end
	return entries
end

local function conditionLabel(node)
	if (node.conditionType == "CLASS" or node.conditionType == "SPEC" or node.conditionType == "ROLE") and type(node.value) == "table" then
		if #node.value == 0 then return _G.NONE end
		if #node.value > 1 then return (L["Dynamic Anchor Selected"]):format(#node.value) end
		local copy = { conditionType = node.conditionType, value = node.value[1] }
		return conditionLabel(copy)
	end
	if node.conditionType == "CLASS" then
		for classID = 1, (GetNumClasses and GetNumClasses() or 13) do
			local name, token = GetClassInfo(classID)
			if token == node.value then return classIcon(token) .. (name or token) end
		end
		return node.value or _G.NONE
	elseif node.conditionType == "SPEC" then
		local name, icon
		if GetSpecializationInfoByID then
			local _, specName, _, specIcon = GetSpecializationInfoByID(tonumber(node.value) or 0)
			name, icon = specName, specIcon
		end
		return (icon and ("|T%d:14:14:0:-1|t "):format(icon) or "") .. (name or tostring(node.value or 0))
	elseif node.conditionType == "ROLE" then
		local label = node.value == "TANK" and (_G.TANK or "Tank") or node.value == "HEALER" and (_G.HEALER or "Healer") or node.value == "DAMAGER" and (_G.DAMAGER or "Damage") or _G.NONE
		return node.value and (roleIcon(node.value) .. label) or label
	end
	return tostring(node.value or 0)
end

function DynamicAnchors:RenderConditionEditor(parent, candidate, onChanged, onMutate)
	local root = self:EnsureCandidateConditionRoot(candidate)
	local rows = flatNodes(root, 0)
	local frames = {}
	local function changed(rebuild)
		if type(onChanged) == "function" then onChanged(rebuild ~= false) end
	end
	local function delayedChanged()
		if C_Timer and C_Timer.After then C_Timer.After(0, function() changed(true) end) else changed(true) end
	end
	local function mutate(action, nodeId, value)
		if type(onMutate) == "function" then return onMutate(action, nodeId, value) end
		local node = self:FindConditionNode(candidate, nodeId)
		if action == "ADD_CONDITION" then return self:AddConditionNode(candidate, nodeId, value) end
		if action == "ADD_GROUP" then return self:AddConditionGroup(candidate, nodeId, value) end
		if action == "REMOVE" then return self:RemoveConditionNode(candidate, nodeId) end
		if not node then return nil end
		if action == "GROUP_OPERATOR" then node.operator = value
		elseif action == "TYPE" then
			node.conditionType, node.value = value, value == "TALENT" and 0 or ""
			node.operator = value == "TALENT" and "KNOWN" or (value == "CLASS" or value == "SPEC" or value == "ROLE") and "ANY_OF" or "IS"
		elseif action == "OPERATOR" then node.operator = value
		elseif action == "VALUE" then node.value = value end
		return node
	end

	for index, item in ipairs(rows) do
		local node, depth = item.node, item.depth
		local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", depth * INDENT, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
		row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
		row:SetHeight(ROW_HEIGHT)
		row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
		row:SetBackdropColor(0.16, 0.18, 0.21, depth == 0 and 0.78 or 0.64)
		frames[#frames + 1] = row

		local accent = row:CreateTexture(nil, "ARTWORK")
		accent:SetColorTexture(node.nodeType == "group" and 0.95 or 0.25, node.nodeType == "group" and 0.72 or 0.62, 0.12, 1)
		accent:SetPoint("TOPLEFT", row, "TOPLEFT")
		accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT")
		accent:SetWidth(3)

		if node.nodeType == "group" then
			local mode = button(row, 180)
			mode:SetPoint("LEFT", row, "LEFT", 10, 0)
			mode:SetText(node.operator == "OR" and L["Dynamic Anchor Match Any"] or L["Dynamic Anchor Match All"])
			mode:SetScript("OnClick", function()
				mutate("GROUP_OPERATOR", node.id, node.operator == "OR" and "AND" or "OR")
				changed(true)
			end)
			local add = button(row, 52)
			add:SetPoint("RIGHT", row, "RIGHT", node == root and -8 or -82, 0)
			add:SetText("+")
			add:SetScript("OnClick", function(owner)
				menu(owner, {
					{ label = L["Dynamic Anchor Condition Class"], action = function() mutate("ADD_CONDITION", node.id, "CLASS") delayedChanged() end },
					{ label = L["Dynamic Anchor Condition Specialization"], action = function() mutate("ADD_CONDITION", node.id, "SPEC") delayedChanged() end },
					{ label = L["Dynamic Anchor Condition Role"], action = function() mutate("ADD_CONDITION", node.id, "ROLE") delayedChanged() end },
					{ label = L["Dynamic Anchor Condition Talent"], action = function() mutate("ADD_CONDITION", node.id, "TALENT") delayedChanged() end },
					{ divider = true },
					{ label = L["Dynamic Anchor Add And Group"], action = function() mutate("ADD_GROUP", node.id, "AND") delayedChanged() end },
					{ label = L["Dynamic Anchor Add Or Group"], action = function() mutate("ADD_GROUP", node.id, "OR") delayedChanged() end },
				})
			end)
			if node ~= root then
				local remove = button(row, 82)
				remove:SetPoint("RIGHT", row, "RIGHT", -8, 0)
				remove:SetText(_G.REMOVE)
				remove:SetScript("OnClick", function() mutate("REMOVE", node.id) changed(true) end)
			end
		else
			local typeButton = button(row, 150)
			typeButton:SetPoint("LEFT", row, "LEFT", 10, 0)
			local labels = { CLASS = L["Dynamic Anchor Condition Class"], SPEC = L["Dynamic Anchor Condition Specialization"], ROLE = L["Dynamic Anchor Condition Role"], TALENT = L["Dynamic Anchor Condition Talent"] }
			typeButton:SetText(labels[node.conditionType])
			typeButton:SetScript("OnClick", function(owner)
				local entries = {}
				for _, conditionType in ipairs({ "CLASS", "SPEC", "ROLE", "TALENT" }) do
					local value = conditionType
					entries[#entries + 1] = { label = labels[value], action = function()
						mutate("TYPE", node.id, value)
						delayedChanged()
					end }
				end
				menu(owner, entries)
			end)

			local operator = button(row, 132)
			operator:SetPoint("LEFT", typeButton, "RIGHT", 8, 0)
			local multiple = node.conditionType == "CLASS" or node.conditionType == "SPEC" or node.conditionType == "ROLE"
			operator:SetText(node.conditionType == "TALENT" and (node.operator == "NOT_KNOWN" and L["Dynamic Anchor Talent Not Known"] or L["Dynamic Anchor Talent Known"]) or (multiple and (node.operator == "NOT_ANY_OF" and L["Dynamic Anchor Operator Is Not Any Of"] or L["Dynamic Anchor Operator Is Any Of"]) or (node.operator == "IS_NOT" and L["Dynamic Anchor Operator Is Not"] or L["Dynamic Anchor Operator Is"])))
			operator:SetScript("OnClick", function()
				if node.conditionType == "TALENT" then mutate("OPERATOR", node.id, node.operator == "NOT_KNOWN" and "KNOWN" or "NOT_KNOWN")
				elseif multiple then mutate("OPERATOR", node.id, node.operator == "NOT_ANY_OF" and "ANY_OF" or "NOT_ANY_OF")
				else mutate("OPERATOR", node.id, node.operator == "IS_NOT" and "IS" or "IS_NOT") end
				changed(true)
			end)

			local remove = button(row, 82)
			remove:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			remove:SetText(_G.REMOVE)
			remove:SetScript("OnClick", function() mutate("REMOVE", node.id) changed(true) end)

			if node.conditionType == "TALENT" then
				local input = CreateFrame("EditBox", nil, row, "BackdropTemplate")
				input:SetAutoFocus(false)
				input:SetNumeric(true)
				input:SetFontObject("GameFontHighlightSmall")
				input:SetTextInsets(10, 10, 0, 0)
				input:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
				input:SetBackdropColor(0.015, 0.02, 0.028, 0.96)
				input:SetBackdropBorderColor(0.25, 0.28, 0.33, 0.85)
				input:SetPoint("LEFT", operator, "RIGHT", 8, 0)
				input:SetPoint("RIGHT", remove, "LEFT", -10, 0)
				input:SetHeight(28)
				input:SetText(tostring(node.value or 0))
				local function commit()
					mutate("VALUE", node.id, tonumber(input:GetText()) or 0)
					changed(false)
				end
				input:SetScript("OnEnterPressed", function(self) commit() self:ClearFocus() end)
				input:SetScript("OnEditFocusLost", commit)
			else
				local valueButton = button(row, 220)
				valueButton:SetPoint("LEFT", operator, "RIGHT", 8, 0)
				valueButton:SetPoint("RIGHT", remove, "LEFT", -8, 0)
				valueButton:SetText(conditionLabel(node))
				valueButton:SetScript("OnClick", function(owner)
					local entries
					if node.conditionType == "CLASS" then
						entries = classEntries()
						multiMenu(owner, entries, node.value, function(values)
							mutate("VALUE", node.id, values)
							valueButton:SetText(#values > 1 and (L["Dynamic Anchor Selected"]):format(#values) or conditionLabel({ conditionType = "CLASS", value = values }))
							changed(false)
						end)
						return
					elseif node.conditionType == "SPEC" then
						entries = specEntries()
						multiMenu(owner, entries, node.value, function(values)
							mutate("VALUE", node.id, values)
							valueButton:SetText(#values > 1 and (L["Dynamic Anchor Selected"]):format(#values) or conditionLabel({ conditionType = "SPEC", value = values }))
							changed(false)
						end)
						return
					else
						entries = {
							{ value = "TANK", label = roleIcon("TANK") .. (_G.TANK or "Tank") },
							{ value = "HEALER", label = roleIcon("HEALER") .. (_G.HEALER or "Healer") },
							{ value = "DAMAGER", label = roleIcon("DAMAGER") .. (_G.DAMAGER or "Damage") },
						}
						multiMenu(owner, entries, node.value, function(values)
							mutate("VALUE", node.id, values)
							valueButton:SetText(#values > 1 and (L["Dynamic Anchor Selected"]):format(#values) or conditionLabel({ conditionType = "ROLE", value = values }))
							changed(false)
						end)
						return
					end
				end)
			end
		end
	end

	return {
		Release = function()
			for _, frame in ipairs(frames) do frame:Hide() frame:SetParent(nil) end
		end,
	}
end
