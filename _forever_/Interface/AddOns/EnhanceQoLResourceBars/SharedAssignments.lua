local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName] or error(parentAddonName .. " is not loaded")
local ResourceBars = addon.Aura.ResourceBars
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Shared = {
	slots = { "MAIN", "SECONDARY", "TERTIARY" },
	defaultAssignment = ResourceBars.GetSharedAssignmentForClassSpec,
}

function Shared.Context(classTag, form)
	return classTag == "DRUID" and ResourceBars.NormalizeDruidSharedVisibilityForm(form) or "DEFAULT"
end

function Shared.Default(classTag, specIndex, form)
	local info = ResourceBars.GetSharedSpecInfo and ResourceBars.GetSharedSpecInfo(classTag, specIndex)
	local assignment = Shared.defaultAssignment(classTag, specIndex, info)
	if classTag == "DRUID" then return assignment and assignment.druidForms and assignment.druidForms[Shared.Context(classTag, form)] or {} end
	return assignment or {}
end

function ResourceBars.GetSharedAssignmentChoices(classTag, specIndex, form)
	local choices = {}
	local normalized = Shared.Context(classTag, form)
	for _, power in ipairs(ResourceBars.GetClassPowerTypes(classTag)) do
		local supported = ResourceBars.IsBarTypeSupportedForClass(power, classTag, specIndex)
		if classTag == "DRUID" then
			if normalized == "CAT" then supported = power == "MANA" or power == "ENERGY" or power == "COMBO_POINTS"
			elseif normalized == "BEAR" then supported = power == "MANA" or power == "RAGE"
			else supported = supported and (power == "MANA" or power == "LUNAR_POWER") end
		end
		if supported then choices[#choices + 1] = power end
	end
	return choices
end

function Shared.Saved(classTag, specIndex, form)
	local entry = ResourceBars.GetSharedVisibilityEntry(classTag, specIndex, false)
	return type(entry) == "table" and type(entry.assignments) == "table" and entry.assignments[Shared.Context(classTag, form)] or nil
end

function ResourceBars.GetConfiguredSharedAssignment(classTag, specIndex, form)
	local defaults = Shared.Default(classTag, specIndex, form)
	local saved = Shared.Saved(classTag, specIndex, form)
	local result = {}
	if type(saved) ~= "table" then
		for _, slot in ipairs(Shared.slots) do result[slot] = defaults[slot] end
		return result
	end
	local allowed, seen = {}, {}
	for _, power in ipairs(ResourceBars.GetSharedAssignmentChoices(classTag, specIndex, form)) do allowed[power] = true end
	for _, slot in ipairs(Shared.slots) do
		local power = saved[slot]
		if power == nil then power = defaults[slot] end
		if type(power) == "string" and allowed[power] and not seen[power] then
			result[slot] = power
			seen[power] = true
		end
	end
	return result
end

function ResourceBars.SetSharedResourceAssignment(classTag, specIndex, form, slot, power)
	if slot ~= "MAIN" and slot ~= "SECONDARY" and slot ~= "TERTIARY" then return false end
	if power ~= false then
		local valid = false
		for _, choice in ipairs(ResourceBars.GetSharedAssignmentChoices(classTag, specIndex, form)) do
			if choice == power then valid = true end
		end
		if not valid then return false end
	end
	local entry = ResourceBars.GetSharedVisibilityEntry(classTag, specIndex, true)
	if not entry then return false end
	local assignment = ResourceBars.GetConfiguredSharedAssignment(classTag, specIndex, form)
	local previous = assignment[slot]
	for _, other in ipairs(Shared.slots) do
		if other ~= slot and power and assignment[other] == power then assignment[other] = previous end
	end
	assignment[slot] = power
	for _, key in ipairs(Shared.slots) do assignment[key] = assignment[key] or false end
	entry.assignments = type(entry.assignments) == "table" and entry.assignments or {}
	entry.assignments[Shared.Context(classTag, form)] = assignment
	if ResourceBars.InvalidateRuntimeConfigCaches then ResourceBars.InvalidateRuntimeConfigCaches() end
	return true
end

function ResourceBars.ResetSharedResourceAssignment(classTag, specIndex, form)
	local entry = ResourceBars.GetSharedVisibilityEntry(classTag, specIndex, false)
	if entry and type(entry.assignments) == "table" then
		entry.assignments[Shared.Context(classTag, form)] = nil
		if not next(entry.assignments) then entry.assignments = nil end
	end
	if ResourceBars.InvalidateRuntimeConfigCaches then ResourceBars.InvalidateRuntimeConfigCaches() end
end

-- Keep visibility summaries and anchor editors consistent with configured slots.
function ResourceBars.GetSharedAssignmentForClassSpec(classTag, specIndex, specInfo)
	local assignment = Shared.defaultAssignment(classTag, specIndex, specInfo)
	if not assignment then return nil end
	if classTag == "DRUID" then
		for form in pairs(assignment.druidForms or {}) do
			assignment.druidForms[form] = ResourceBars.GetConfiguredSharedAssignment(classTag, specIndex, form)
		end
	elseif type(Shared.Saved(classTag, specIndex)) == "table" then
		assignment = ResourceBars.GetConfiguredSharedAssignment(classTag, specIndex)
	end
	return assignment
end

function ResourceBars.GetSharedSlotPossibleTypes(slot, classTag)
	if slot == "HEALTH" then return { "HEALTH" } end
	if slot ~= "MAIN" and slot ~= "SECONDARY" and slot ~= "TERTIARY" then return {} end
	local class = classTag or addon.variables.unitClass
	local choices = ResourceBars.GetClassPowerTypes(class)
	if slot == "TERTIARY" and #choices < 3 then return {} end
	return choices
end

function ResourceBars.ResolveCustomSharedAssignments(specIndex)
	local class = addon.variables.unitClass
	local spec = specIndex or addon.variables.unitSpec or (ResourceBars.GetClassContext and ResourceBars.GetClassContext())
	local form = class == "DRUID" and ResourceBars.GetCurrentDruidFormKey() or nil
	if type(Shared.Saved(class, spec, form)) ~= "table" then return nil end
	local cache = ResourceBars.GetRuntimeConfigBatchBucket and ResourceBars.GetRuntimeConfigBatchBucket("customSharedAssignments", spec)
	if cache and cache.assignments then return cache.assignments end
	local resolved = { HEALTH = "HEALTH", byType = { HEALTH = "HEALTH" }, order = { "HEALTH" }, secondaryTypes = {} }
	local assignment = ResourceBars.GetConfiguredSharedAssignment(class, spec, form)
	for _, slot in ipairs(Shared.slots) do
		local power = assignment[slot]
		local available = not power or not ResourceBars.IsAuraPowerType(power) or ResourceBars.IsAuraPowerBarTypeAvailable(power)
		if power and available and ResourceBars.IsSharedSlotAllowed(class, spec, slot, form) then
			resolved[slot] = power
			resolved.byType[power] = slot
			resolved.order[#resolved.order + 1] = slot
			if slot ~= "MAIN" then resolved.secondaryTypes[#resolved.secondaryTypes + 1] = power end
		end
	end
	if cache then cache.assignments = resolved end
	return resolved
end

function ResourceBars.IsSharedResourceAssignmentCustomized(classTag, specIndex, form)
	if type(Shared.Saved(classTag, specIndex, form)) ~= "table" then return false end
	local defaults = Shared.Default(classTag, specIndex, form)
	local configured = ResourceBars.GetConfiguredSharedAssignment(classTag, specIndex, form)
	for _, slot in ipairs(Shared.slots) do
		if (configured[slot] or false) ~= (defaults[slot] or false) then return true end
	end
	return false
end

function Shared.IsRowCustomized(row)
	if row.isDruid then
		for _, form in ipairs(ResourceBars.SHARED_VISIBILITY_DRUID_FORMS) do
			if ResourceBars.IsSharedResourceAssignmentCustomized(row.classTag, row.specIndex, form) then return true end
		end
		return false
	end
	return ResourceBars.IsSharedResourceAssignmentCustomized(row.classTag, row.specIndex)
end

function Shared.Mark(label, customized)
	return label .. (customized and " |TInterface\\Buttons\\UI-CheckBox-Check:16:16|t" or "")
end

function Shared.ClassLabel(row, customized)
	return Shared.Mark("|A:classicon-" .. row.classTag .. ":16:16|a " .. (row.className or row.classTag), customized)
end

function Shared.SpecLabel(row)
	local text = row.specName or row.className or row.classTag
	if row.specIcon then text = "|T" .. row.specIcon .. ":16:16:0:0:64:64:4:60:4:60|t " .. text end
	return Shared.Mark(text, Shared.IsRowCustomized(row))
end

function ResourceBars.RenderSharedAssignments(parent, onChange)
	if not parent then return nil end
	local handle = { frames = {} }
	local rows = ResourceBars.BuildSharedVisibilityRows()
	local selected = rows[1]
	local selection = Shared.editorSelection or { classTag = addon.variables.unitClass, specIndex = addon.variables.unitSpec or (ResourceBars.GetClassContext and ResourceBars.GetClassContext()) }
	for _, row in ipairs(rows) do
		if row.classTag == selection.classTag and selection.specIndex == row.specIndex then selected = row end
	end
	if not selected then return handle end
	local form = selection.form or ResourceBars.NormalizeDruidSharedVisibilityForm(ResourceBars.GetCurrentDruidFormKey and ResourceBars.GetCurrentDruidFormKey())
	local buttons, labels = {}, {}
	local formNames = {
		BEAR = L["ResourceBarsSharedVisibilityDruidBear"], CAT = L["ResourceBarsSharedVisibilityDruidCat"],
		MOONKIN = L["ResourceBarsSharedVisibilityDruidMoonkin"], HUMANOID = L["ResourceBarsSharedVisibilityDruidHumanoid"],
	}
	local slotNames = { MAIN = L["AutoEnableMain"], SECONDARY = L["AutoEnableSecondary"], TERTIARY = L["ResourceBarsTertiary"] }
	local function track(frame) handle.frames[#handle.frames + 1] = frame; return frame end
	local function powerLabel(power)
		return power and ((ResourceBars.PowerLabels and ResourceBars.PowerLabels[power]) or _G["POWER_TYPE_" .. power] or _G[power] or power) or _G.NONE
	end
	local title = track(parent:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
	title:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -2)
	title:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -2)
	title:SetJustifyH("LEFT")
	title:SetText(L["ResourceBarsSharedAssignments"])
	local description = track(parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
	description:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -26)
	description:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -26)
	description:SetHeight(48)
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	description:SetWordWrap(true)
	description:SetText(L["ResourceBarsSharedAssignmentsDesc"])
	local function label(text, y)
		local font = track(parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
		font:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y - 78)
		font:SetWidth(155)
		font:SetJustifyH("LEFT")
		font:SetText(text)
		return font
	end
	local function button(y, reset)
		local frame = track(CreateFrame("Button", nil, parent, "BackdropTemplate"))
		local ui = addon.LibSettingsDesigner and addon.LibSettingsDesigner.UI
		local colors = ui and ui.ThemeColors or {}
		frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 170, y - 78)
		frame:SetSize(reset and 200 or math.min(380, math.max(180, (parent:GetWidth() or 620) - 178)), 28)
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame._eqolOwner = parent
		frame._eqolBorderStyleKey = reset and "button" or "dropdownControl"
		frame._eqolNormalBg = (reset and colors.buttonBg or colors.dropdownBg) or { 0.025, 0.034, 0.038, 0.94 }
		frame._eqolNormalBorder = (reset and colors.buttonBorder or colors.dropdownBorder) or { 0.24, 0.29, 0.30, 0.65 }
		frame._eqolHoverBg = (reset and colors.buttonHoverBg or colors.dropdownHoverBg) or { 0.06, 0.09, 0.10, 1 }
		frame._eqolHoverBorder = (reset and colors.buttonHoverBorder or colors.dropdownHoverBorder) or { 0.32, 0.62, 0.55, 0.85 }
		frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		frame.Text:SetPoint("LEFT", frame, "LEFT", 12, 0)
		frame.Text:SetPoint("RIGHT", frame, "RIGHT", reset and -12 or -32, 0)
		frame.Text:SetJustifyH(reset and "CENTER" or "LEFT")
		function frame:SetText(text) self.Text:SetText(text) end
		if not reset then
			frame.Arrow = frame:CreateTexture(nil, "ARTWORK")
			frame.Arrow:SetSize(14, 14)
			frame.Arrow:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
			frame.Arrow:SetTexture("Interface\\AddOns\\EnhanceQoL\\libs\\LibSettingsDesigner\\Assets\\LibSettingsDesigner_DropdownDown.tga")
		end
		local function visual(self, hover)
			local bg = hover and self._eqolHoverBg or self._eqolNormalBg
			local border = hover and self._eqolHoverBorder or self._eqolNormalBorder
			if ui and ui.ApplyFlatButtonVisual then
				local normalBg, normalBorder = self._eqolNormalBg, self._eqolNormalBorder
				self._eqolNormalBg, self._eqolNormalBorder = bg, border
				ui.ApplyFlatButtonVisual(self)
				self._eqolNormalBg, self._eqolNormalBorder = normalBg, normalBorder
			else
				self:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
				self:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
			end
		end
		frame:SetScript("OnEnter", function(self) visual(self, self:IsEnabled()) end)
		frame:SetScript("OnLeave", function(self) visual(self, false) end)
		frame:SetScript("OnEnable", function(self) visual(self, false) end)
		frame:SetScript("OnDisable", function(self) visual(self, false) end)
		visual(frame, false)
		return frame
	end

	local hint
	local function refresh()
		Shared.editorSelection = { classTag = selected.classTag, specIndex = selected.specIndex, form = form }
		buttons.context:SetText(Shared.ClassLabel(selected, not selected.specName and Shared.IsRowCustomized(selected)) .. (selected.specName and (" / " .. Shared.SpecLabel(selected)) or ""))
		buttons.form:SetText(selected.isDruid and Shared.Mark(formNames[form], ResourceBars.IsSharedResourceAssignmentCustomized(selected.classTag, selected.specIndex, form)) or _G.NOT_APPLICABLE or "-")
		buttons.form:SetShown(selected.isDruid == true)
		labels.form:SetShown(selected.isDruid == true)
		local shift = selected.isDruid and 0 or 34
		for i, slot in ipairs(Shared.slots) do
			buttons[slot]:ClearAllPoints()
			buttons[slot]:SetPoint("TOPLEFT", parent, "TOPLEFT", 170, -148 - (i - 1) * 34 + shift)
			labels[slot]:ClearAllPoints()
			labels[slot]:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -154 - (i - 1) * 34 + shift)
		end
		buttons.reset:ClearAllPoints()
		buttons.reset:SetPoint("TOPLEFT", parent, "TOPLEFT", 170, -256 + shift)
		hint:ClearAllPoints()
		hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -290 + shift)
		hint:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -290 + shift)
		local assignment = ResourceBars.GetConfiguredSharedAssignment(selected.classTag, selected.specIndex, form)
		local defaults = Shared.Default(selected.classTag, selected.specIndex, form)
		for _, slot in ipairs(Shared.slots) do
			buttons[slot]:SetText(Shared.Mark(powerLabel(assignment[slot]), (assignment[slot] or false) ~= (defaults[slot] or false)))
		end
	end
	local function changed()
		refresh()
		if onChange then onChange() end
		-- Rebuild the visibility summary after the open resource menu has closed.
		C_Timer.After(0, function()
			local frame = addon.ConfigCenterFrame
			local state = frame and frame._LibSettingsDesignerState
			if frame and frame:IsShown() and state and state.RenderContent then state:RenderContent() end
		end)
	end
	label(L["ResourceBarsSharedVisibilitySpec"], -8)
	buttons.context = button(-2)
	buttons.context:SetScript("OnClick", function(owner)
		MenuUtil.CreateContextMenu(owner, function(_, menu)
			local groups, classCustomized = {}, {}
			for _, row in ipairs(rows) do
				if Shared.IsRowCustomized(row) then classCustomized[row.classTag] = true end
			end
			for _, row in ipairs(rows) do
				local group = menu
				if row.specName then
					group = groups[row.classTag]
					if not group then group = menu:CreateButton(Shared.ClassLabel(row, classCustomized[row.classTag])); groups[row.classTag] = group end
				end
				group:CreateRadio(row.specName and Shared.SpecLabel(row) or Shared.ClassLabel(row, classCustomized[row.classTag]), function() return selected == row end, function() selected = row; refresh() end)
			end
		end)
	end)
	labels.form = label(L["ResourceBarsSharedAssignmentForm"], -42)
	buttons.form = button(-36)
	buttons.form:SetScript("OnClick", function(owner)
		MenuUtil.CreateContextMenu(owner, function(_, menu)
			for _, key in ipairs(ResourceBars.SHARED_VISIBILITY_DRUID_FORMS) do
				menu:CreateRadio(Shared.Mark(formNames[key], ResourceBars.IsSharedResourceAssignmentCustomized(selected.classTag, selected.specIndex, key)), function() return form == key end, function() form = key; refresh() end)
			end
		end)
	end)
	for i, slot in ipairs(Shared.slots) do
		labels[slot] = label(slotNames[slot], -76 - (i - 1) * 34)
		local dropdown = button(-70 - (i - 1) * 34)
		buttons[slot] = dropdown
		dropdown:SetScript("OnClick", function(owner)
			MenuUtil.CreateContextMenu(owner, function(_, menu)
				local assignment = ResourceBars.GetConfiguredSharedAssignment(selected.classTag, selected.specIndex, form)
				menu:CreateRadio(_G.NONE, function() return assignment[slot] == nil end, function()
					ResourceBars.SetSharedResourceAssignment(selected.classTag, selected.specIndex, form, slot, false); changed()
				end)
				for _, power in ipairs(ResourceBars.GetSharedAssignmentChoices(selected.classTag, selected.specIndex, form)) do
					menu:CreateRadio(powerLabel(power), function() return assignment[slot] == power end, function()
						ResourceBars.SetSharedResourceAssignment(selected.classTag, selected.specIndex, form, slot, power); changed()
					end)
				end
			end)
		end)
	end
	buttons.reset = button(-178, true)
	buttons.reset:SetText(_G.RESET_TO_DEFAULT)
	buttons.reset:SetScript("OnClick", function()
		ResourceBars.ResetSharedResourceAssignment(selected.classTag, selected.specIndex, form)
		changed()
	end)
	hint = track(parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
	hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -290)
	hint:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -290)
	hint:SetJustifyH("LEFT")
	hint:SetWordWrap(true)
	hint:SetText(L["ResourceBarsSharedAssignmentsHint"])
	refresh()
	function handle:Release()
		for _, frame in ipairs(self.frames) do frame:Hide(); frame:SetParent(nil) end
		wipe(self.frames)
	end
	return handle
end
