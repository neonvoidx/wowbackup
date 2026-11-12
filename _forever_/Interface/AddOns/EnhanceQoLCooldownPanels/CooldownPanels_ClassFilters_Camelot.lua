local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local CooldownPanels = addon.Aura.CooldownPanels
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local classes = {
	[1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST",
	[6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [10] = "MONK",
	[11] = "DRUID", [12] = "DEMONHUNTER", [13] = "EVOKER",
}
local playableClasses = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }
local legacySpecClasses = {
	[71] = 1, [72] = 1, [73] = 1,
	[65] = 2, [66] = 2, [70] = 2,
	[253] = 3, [254] = 3, [255] = 3,
	[259] = 4, [260] = 4, [261] = 4,
	[256] = 5, [257] = 5, [258] = 5,
	[250] = 6, [251] = 6, [252] = 6,
	[262] = 7, [263] = 7, [264] = 7,
	[62] = 8, [63] = 8, [64] = 8,
	[265] = 9, [266] = 9, [267] = 9,
	[268] = 10, [269] = 10, [270] = 10,
	[102] = 11, [103] = 11, [104] = 11, [105] = 11,
	[577] = 12, [581] = 12, [1480] = 12,
	[1467] = 13, [1468] = 13, [1473] = 13,
}

local function className(classID)
	if not classes[classID] then return UNKNOWN end
	local info = C_CreatureInfo and C_CreatureInfo.GetClassInfo and C_CreatureInfo.GetClassInfo(classID)
	if info and info.className then return info.className end
	local token = classes[classID]
	return token and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] or UNKNOWN
end

local function hasSelection(filter)
	for _, selected in pairs(filter or {}) do
		if selected == true then return true end
	end
	return false
end

function CooldownPanels:GetPanelClassFilter(panel)
	if not panel then return nil end
	if panel.foreverUseSpecFilter == true then
		local talents = self:GetForeverTalentFilter(panel)
		if not hasSelection(talents) then return nil end
		local filter = {}
		for _, classID in ipairs(playableClasses) do
			local groups = addon.functions and addon.functions.GetForeverTalentGroups and addon.functions.GetForeverTalentGroups(classID) or {}
			for _, group in ipairs(groups) do
				if talents[group.groupID] == true or talents[tostring(group.groupID)] == true then filter[classID] = true end
			end
		end
		return next(filter) and filter or { [0] = true }
	end
	-- An explicit empty class filter means all classes, even on imported panels.
	if type(panel.classFilter) == "table" then return hasSelection(panel.classFilter) and panel.classFilter or nil end
	-- Preserve Retail specialization settings for import/export compatibility.
	-- Non-Forever and unknown assignments must not become unrestricted panels.
	if type(panel.specFilter) ~= "table" then return nil end
	local filter = {}
	for specID, selected in pairs(panel.specFilter) do
		if selected == true then filter[legacySpecClasses[tonumber(specID)] or 0] = true end
	end
	return next(filter) and filter or nil
end

function CooldownPanels:HasPanelClassFilter(panel) return self:GetPanelClassFilter(panel) ~= nil end

function CooldownPanels:PanelAllowsClass(panel, classID)
	local filter = self:GetPanelClassFilter(panel)
	if not filter then return true end
	classID = tonumber(classID) or select(3, UnitClass("player"))
	return classID ~= nil and (filter[classID] == true or filter[tostring(classID)] == true)
end

function CooldownPanels:SpellGroupMemberAllowsClass(member, classID)
	classID = tonumber(classID) or select(3, UnitClass("player"))
	if member.classID then return tonumber(member.classID) == classID end
	if type(member.specIDs) ~= "table" or #member.specIDs == 0 then return true end
	for _, specID in ipairs(member.specIDs) do
		if classID and legacySpecClasses[tonumber(specID)] == classID then return true end
	end
	return false
end

function CooldownPanels:GetPanelClassFilterOptions()
	local options = { { value = "__all", text = ALL_CLASSES or L["All classes"] } }
	for _, classID in ipairs(playableClasses) do
		options[#options + 1] = { value = classID, text = CooldownPanels.helper.GetClassMenuLabel(classes[classID], className(classID)), classFile = classes[classID] }
	end
	return options
end

function CooldownPanels:GetPanelClassFilterLabel(panel)
	local filter = self:GetPanelClassFilter(panel)
	if not filter then return ALL_CLASSES or L["All classes"] end
	local labels, seen = {}, {}
	for classID, selected in pairs(filter) do
		if selected == true then
			local label = className(tonumber(classID))
			if label and not seen[label] then
				labels[#labels + 1] = label
				seen[label] = true
			end
		end
	end
	table.sort(labels)
	return table.concat(labels, ", ")
end

function CooldownPanels:IsPanelClassFilterOptionSelected(panelId, value)
	local filter = self:GetPanelClassFilter(self:GetPanel(panelId))
	if value == "__all" then return filter == nil end
	local classID = tonumber(value)
	return classID ~= nil and filter ~= nil and (filter[classID] == true or filter[tostring(classID)] == true)
end

function CooldownPanels:SetPanelClassFilterOptionSelected(panelId, value, selected)
	local panel = self:GetPanel(panelId)
	if not panel then return end
	if value == "__all" then
		if not selected then return end
		panel.classFilter = {}
	else
		local classID = tonumber(value)
		local playable = false
		for _, id in ipairs(playableClasses) do
			if id == classID then
				playable = true
				break
			end
		end
		if not playable then return end
		local filter = {}
		for id, enabled in pairs(self:GetPanelClassFilter(panel) or {}) do
			if enabled == true then filter[tonumber(id) or id] = true end
		end
		filter[classID] = selected == true or nil
		panel.classFilter = filter
	end
	self:RebuildSpellIndex()
	self:RefreshPanel(panelId)
	self:UpdateCursorAnchorState()
	-- The Edit Mode library defers its own settings refresh until the menu closes.
	if self.BlizzardEditor and self.BlizzardEditor.frame and self.BlizzardEditor.frame:IsShown() then self.BlizzardEditor:Refresh() end
end

function CooldownPanels:GetForeverTalentFilterOptions()
	local options = { { value = "__all", text = L["CooldownPanelSpecAny"] } }
	for _, classID in ipairs(playableClasses) do
		local groups = addon.functions and addon.functions.GetForeverTalentGroups and addon.functions.GetForeverTalentGroups(classID) or {}
		for _, group in ipairs(groups) do
			options[#options + 1] = {
				value = group.groupID,
				text = self.helper.GetClassMenuLabel(classes[classID], className(classID)) .. " - " .. group.displayName,
			}
		end
	end
	return options
end

function CooldownPanels:GetForeverTalentFilter(panel)
	return panel and type(panel.foreverTalentFilter) == "table" and panel.foreverTalentFilter or nil
end

function CooldownPanels:GetForeverTalentFilterLabel(panel)
	local filter = self:GetForeverTalentFilter(panel)
	if not hasSelection(filter) then return L["CooldownPanelSpecAny"] end
	local labels = {}
	for _, option in ipairs(self:GetForeverTalentFilterOptions()) do
		if filter[option.value] == true or filter[tostring(option.value)] == true then labels[#labels + 1] = option.text end
	end
	return #labels > 0 and table.concat(labels, ", ") or UNKNOWN
end

function CooldownPanels:IsForeverTalentFilterOptionSelected(panelId, value)
	local panel = self:GetPanel(panelId)
	local filter = self:GetForeverTalentFilter(panel)
	if value == "__all" then return not hasSelection(filter) end
	return filter ~= nil and (filter[value] == true or filter[tostring(value)] == true)
end

function CooldownPanels:SetForeverTalentFilterOptionSelected(panelId, value, selected)
	local panel = self:GetPanel(panelId)
	if not panel then return end
	if value == "__all" then
		if not selected then return end
		panel.foreverTalentFilter = nil
	else
		local valid = false
		for _, option in ipairs(self:GetForeverTalentFilterOptions()) do
			if option.value == value then valid = true end
		end
		if not valid then return end
		panel.foreverTalentFilter = self:GetForeverTalentFilter(panel) or {}
		panel.foreverTalentFilter[tostring(value)] = nil
		panel.foreverTalentFilter[value] = selected == true or nil
		if not hasSelection(panel.foreverTalentFilter) then panel.foreverTalentFilter = nil end
	end
	self:RebuildSpellIndex()
	self:RefreshPanel(panelId)
	self:UpdateCursorAnchorState()
	-- MultiDropdown refresh remains deferred until its menu closes.
	if self.BlizzardEditor and self.BlizzardEditor.frame and self.BlizzardEditor.frame:IsShown() then self.BlizzardEditor:Refresh() end
end

function CooldownPanels:SetForeverUseSpecFilter(panelId, enabled)
	local panel = self:GetPanel(panelId)
	if not panel then return end
	panel.foreverUseSpecFilter = enabled == true or nil
	self:RebuildSpellIndex()
	self:RefreshPanel(panelId)
	self:UpdateCursorAnchorState()
	if self.BlizzardEditor and self.BlizzardEditor.frame and self.BlizzardEditor.frame:IsShown() then self.BlizzardEditor:Refresh() end
end

function CooldownPanels:PanelAllowsForeverTalent(panel)
	local filter = self:GetForeverTalentFilter(panel)
	if not hasSelection(filter) then return true end
	local id = addon.functions and addon.functions.GetForeverPrimaryTalentGroup and addon.functions.GetForeverPrimaryTalentGroup()
	return id ~= nil and (filter[id] == true or filter[tostring(id)] == true)
end
