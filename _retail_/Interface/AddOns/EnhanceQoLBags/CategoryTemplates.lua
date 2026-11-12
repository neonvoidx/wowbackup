local addon = _G.EnhanceQoL
local L = addon.L
local T = {}
addon.Bags.CategoryTemplates = T

local function condition(field, value) return { field = field, op = "=", value = value } end

-- Templates use the same native classification as ordinary item filters.
-- Shared materials stay grouped; this is not a recipe-reagent dependency database.
function T.Definitions()
	local rows = {}
	local forever = addon.variables and addon.variables.isForever and not addon.variables.isTBC
	for _, option in ipairs(addon.GetCategoryRuleValueOptions({ field = "professionGroupKey" }) or {}) do
		if not (forever and (option.value == "inscription" or option.value == "craftingReagents")) then
			local keys = {}
			for subclass = 0, 64 do
				if addon.GetProfessionGroupKeyForItem(7, subclass) == option.value then keys[#keys + 1] = "7:" .. subclass end
			end
			if #keys > 0 then rows[#rows + 1] = { id = "materials:" .. option.value, name = forever and option.value == "miningSmithingEngineeringJewelcrafting" and L["categoryTemplateMetalClassic"] or option.label, kind = "materials", ast = { field = "subClassKey", op = "in", value = keys } } end
		end
	end
	local field = addon.Items and addon.Items.GetField("subClassKey", addon.GetCategoryFilterContext())
	for _, option in ipairs(field and field.valueOptions or {}) do
		if option.classID == 9 and not (forever and option.subclassID > 9) and not (addon.variables.isTBC and option.subclassID > 10) then
			local name = option.label:match(": (.*)$") or option.label
			rows[#rows + 1] = { id = "recipes:" .. option.value, name = name .. " · " .. L["categoryTemplateRecipes"], kind = "recipes", ast = condition("subClassKey", option.value) }
		end
	end
	return rows
end

function T.Preview(rows, selected, snapshot)
	-- Snapshot once per user action, never subscribe to inventory events or poll.
	if not snapshot then
		local result = addon.PreviewCategoryItemFilter("__template_preview", { constant = false })
		snapshot = {}
		for _, row in ipairs(result.items) do snapshot[#snapshot + 1] = row.item end
	end
	local result = {}
	for _, row in ipairs(rows) do
		if selected[row.id] then
			local compiled = addon.Items.Compile(row.ast)
			local preview = { definition = row, count = 0, pending = 0, examples = {} }
			for _, item in ipairs(snapshot) do
				local match = addon.Bags.ItemRules.Evaluate(compiled, item)
				if match == true then
					preview.count = preview.count + 1
					if #preview.examples < 2 then
						local facts = addon.Items.Get(item, { "name" }, addon.GetCategoryFilterContext())
						preview.examples[#preview.examples + 1] = facts.name or tostring(item.itemID)
					end
				elseif match == nil then preview.pending = preview.pending + 1 end
			end
			result[#result + 1] = preview
		end
	end
	return result
end

function T.Apply(rows, selected, owner)
	if addon.GetSettings() ~= owner or addon.GetActiveCategoryMode() ~= "advanced" then return nil end
	local prepared = {}
	for _, row in ipairs(rows) do
		if selected[row.id] then
			local ast = addon.ValidateCategoryItemFilter(row.ast)
			if not ast then return nil end
			prepared[#prepared + 1] = { name = row.name, ast = ast }
		end
	end
	if #prepared == 0 then return nil end
	local group = addon.CreateCustomCategoryGroup()
	addon.SetCustomCategoryGroupName(group.id, L["categoryTemplateTitle"])
	local created = {}
	for _, row in ipairs(prepared) do
		local category = addon.CreateCustomCategory(group.id)
		created[#created + 1] = category.id
		addon.SetCustomCategoryName(category.id, row.name)
		if not addon.SetCategoryItemFilter(category.id, row.ast) then
			for _, id in ipairs(created) do addon.RemoveCustomCategory(id) end
			addon.RemoveCustomCategoryGroup(group.id)
			return nil
		end
	end
	return group
end

function T.Open(parent, onCreated)
	if parent.FilterEditor then parent.FilterEditor.picker:Hide(); parent.FilterEditor.suggestions:Hide() end
	if parent.CategoryTemplateDialog then parent.CategoryTemplateDialog:Reset(); parent.CategoryTemplateDialog:Show(); return end
	local UI = addon.Bags.SettingsNavigation
	local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	parent.CategoryTemplateDialog = frame
	frame:SetSize(620, 530)
	frame:SetPoint("CENTER", parent, "CENTER")
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(parent:GetFrameLevel() + 50)
	frame:EnableMouse(true)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropColor(0.035, 0.045, 0.06, 1)
	frame:SetBackdropBorderColor(0.3, 0.5, 0.65, 1)
	local function label(value, x, y, width, font)
		local text = frame:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
		text:SetPoint("TOPLEFT", x, -y); text:SetWidth(width); text:SetJustifyH("LEFT"); text:SetText(value)
		return text
	end
	local function button(value, x, y, width, callback)
		local control = UI.CreateButton("Button", nil, frame)
		control:SetPoint("TOPLEFT", x, -y); control:SetSize(width, 24); control:SetText(value); control:SetScript("OnClick", callback)
		return control
	end
	label(L["categoryTemplateTitle"], 18, 16, 550, "GameFontNormalLarge")
	local hint = label(L["categoryTemplateHint"], 18, 44, 584)
	local top = 54 + hint:GetStringHeight()
	local rows, selected, owner = T.Definitions(), {}, addon.GetSettings()
	for _, row in ipairs(rows) do selected[row.id] = true end
	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 18, -(top + 36)); scroll:SetPoint("BOTTOMRIGHT", -38, 76)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(554, math.max(1, #rows * 48)); scroll:SetScrollChild(content)
	local widgets = {}
	local apply
	local function refresh()
		local previews = {}
		for _, preview in ipairs(T.Preview(rows, selected)) do previews[preview.definition.id] = preview end
		local count = 0
		for index, row in ipairs(rows) do
			local widget, preview = widgets[index], previews[row.id]
			widget.check:SetChecked(selected[row.id] == true)
			if preview then
				count = count + 1
				widget.detail:SetText(string.format(L["itemFilterPreview"], preview.count, preview.pending) .. (#preview.examples > 0 and "\n" .. table.concat(preview.examples, ", ") or ""))
			else widget.detail:SetText("") end
		end
		apply:SetEnabled(count > 0)
	end
	for index, row in ipairs(rows) do
		local check = UI.CreateCheckbox("CheckButton", nil, content)
		check:SetPoint("TOPLEFT", 0, -(index - 1) * 48)
		local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		title:SetPoint("LEFT", check, "RIGHT", 5, 0); title:SetWidth(510); title:SetJustifyH("LEFT"); title:SetText(row.name)
		local detail = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		detail:SetPoint("TOPLEFT", check, "BOTTOMRIGHT", 5, 1); detail:SetWidth(510); detail:SetJustifyH("LEFT"); detail:SetMaxLines(2)
		widgets[index] = { check = check, detail = detail }
		check:SetScript("OnClick", function(self) selected[row.id] = self:GetChecked() == true; refresh() end)
	end
	for index, kind in ipairs({ "materials", "recipes" }) do
		button(L[kind == "materials" and "categoryTemplateMaterials" or "categoryTemplateRecipes"], 18 + (index - 1) * 180, top, 174, function()
			local all = true
			for _, row in ipairs(rows) do if row.kind == kind and not selected[row.id] then all = false end end
			for _, row in ipairs(rows) do if row.kind == kind then selected[row.id] = not all end end
			refresh()
		end)
	end
	button(_G.REFRESH or L["itemFilterTest"], 380, top, 202, refresh)
	label(L["categoryTemplateFooter"], 18, 462, 584)
	apply = button(L["categoryTemplateCreate"], 18, 494, 280, function()
		local group = T.Apply(rows, selected, owner)
		if group then frame:Hide(); onCreated(group) end
	end)
	button(_G.CANCEL, 310, 494, 292, function() frame:Hide() end)
	function frame:Reset()
		owner = addon.GetSettings()
		refresh()
	end
	refresh()
	frame:Show()
end
