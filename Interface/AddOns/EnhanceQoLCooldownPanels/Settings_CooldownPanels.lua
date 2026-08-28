local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not (cat and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Cooldown Panels"] or "Cooldown Panels",
	description = L["configCenterPageDescCooldownPanels"]
		or "Create and manage custom cooldown panels, then edit tracked abilities, layout and visibility in the panel editor.",
	newTagID = "CooldownPanels",
	iconKey = "cooldownpanels",
	modernCategory = "suites",
	expanded = false,
	colorizeTitle = false,
})

local function withCooldownPanels(action)
	local panels = addon.Aura and addon.Aura.CooldownPanels
	if not panels then return end
	action(panels)
end

local function openEditorExclusively(panels)
	if not panels then return end
	local editorFrame
	if panels.OpenPreferredEditor then
		editorFrame = panels:OpenPreferredEditor()
	elseif panels.OpenBlizzardEditor then
		editorFrame = panels:OpenBlizzardEditor()
	elseif panels.OpenEditor then
		editorFrame = panels:OpenEditor()
	end
	if editorFrame and addon.functions.HideConfigCenterUntilFrameHidden then
		addon.functions.HideConfigCenterUntilFrameHidden(editorFrame)
	end
end

addon.functions.SettingsCreateButton(cat, {
	text = L["CooldownPanelOpenEditor"] or "Open Cooldown Panel Editor",
	func = function()
		withCooldownPanels(function(panels)
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(cat, {
	text = L["Add Panel"] or "Add Panel",
	func = function()
		withCooldownPanels(function(panels)
			local panelId = panels:CreatePanel(L["CooldownPanelNewPanel"] or "New Panel")
			if panelId then panels:SelectPanel(panelId) end
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})

local function registerAuraPresetTrackingSettings()
	local panels = addon.Aura and addon.Aura.CooldownPanels
	local presets = panels and panels.AuraPresets
	if not (presets and presets.GetCombinedExclusions and presets.AddCombinedExclusions and presets.RemoveCombinedExclusion) then return end

	addon.functions.SettingsCreateHeadline(cat, L["CooldownPanelAuraPresetTracking"] or "Automatic aura tracking", {
		parentSection = expandable,
	})

	local refreshQueued = false
	local function queueRuntimeRefresh()
		if refreshQueued then return end
		refreshQueued = true
		C_Timer.After(0, function()
			refreshQueued = false
			if panels.RefreshAllPanels then panels:RefreshAllPanels(true) end
		end)
	end

	local function getTypeLabel(row)
		local types = {}
		if row.presetKeys.TRINKET_UPTIME then types[#types + 1] = L["CooldownPanelAuraPresetTypeTrinket"] or "Trinket" end
		if row.presetKeys.COMBAT_POTION then types[#types + 1] = L["CooldownPanelAuraPresetTypePotion"] or "Combat potion" end
		return table.concat(types, " / ")
	end

	addon.functions.SettingsCreateCustom(cat, {
		id = "CooldownPanelAuraPresetExclusions",
		var = "CooldownPanelAuraPresetExclusions",
		text = L["CooldownPanelAuraPresetExclusions"] or "Excluded automatic auras",
		desc = L["CooldownPanelAuraPresetExclusionsDesc"],
		newTagID = "CooldownPanelAuraPresetExclusions",
		parentSection = expandable,
		getHeight = function() return 82 + (#presets:GetCombinedExclusions() * 28) end,
		render = function(parent, _, _, state)
			local frame = CreateFrame("Frame", nil, parent)
			frame:SetAllPoints()
			local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
			input:SetPoint("TOPLEFT", 8, -4)
			input:SetPoint("TOPRIGHT", -112, -4)
			input:SetHeight(24)
			input:SetAutoFocus(false)
			input:SetTextInsets(8, 8, 0, 0)
			input.Instructions = input:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
			input.Instructions:SetPoint("LEFT", 8, 0)
			input.Instructions:SetText(L["CooldownPanelAuraPresetExclusionsPlaceholder"] or "Spell ID")
			input:SetScript("OnTextChanged", function(self) self.Instructions:SetShown(self:GetText() == "") end)

			local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			addButton:SetPoint("LEFT", input, "RIGHT", 8, 0)
			addButton:SetSize(88, 24)
			addButton:SetText(_G.ADD or "Add")
			local function addValue()
				local changed, matched = presets:AddCombinedExclusions(input:GetText())
				if matched == 0 then
					input:SetTextColor(1, 0.25, 0.25)
					return
				end
				input:SetText("")
				input:SetTextColor(1, 1, 1)
				if changed then queueRuntimeRefresh() end
				if state and state.RequestLayout then state:RequestLayout() end
			end
			addButton:SetScript("OnClick", addValue)
			input:SetScript("OnEnterPressed", function(self) addValue(); self:ClearFocus() end)
			input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

			local header = CreateFrame("Frame", nil, frame)
			header:SetPoint("TOPLEFT", 4, -36)
			header:SetPoint("TOPRIGHT", -4, -36)
			header:SetHeight(22)
			header.background = header:CreateTexture(nil, "BACKGROUND")
			header.background:SetAllPoints()
			header.background:SetColorTexture(0.08, 0.08, 0.08, 0.55)
			local function addHeader(text, point, x)
				local label = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
				label:SetPoint(point, x, 0)
				label:SetText(text)
				return label
			end
			addHeader(_G.NAME or "Name", "LEFT", 8)
			addHeader("ID", "CENTER", 80)
			addHeader(_G.TYPE or "Type", "RIGHT", -112)

			local rows = presets:GetCombinedExclusions()
			for i = 1, #rows do
				local rowData = rows[i]
				local row = CreateFrame("Frame", nil, frame)
				row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -((i - 1) * 28))
				row:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -((i - 1) * 28))
				row:SetHeight(28)
				local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
				name:SetPoint("LEFT", 8, 0)
				name:SetWidth(260)
				name:SetJustifyH("LEFT")
				name:SetText(rowData.name)
				local id = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
				id:SetPoint("CENTER", 80, 0)
				id:SetText(rowData.spellID)
				local typeLabel = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
				typeLabel:SetPoint("RIGHT", -112, 0)
				typeLabel:SetText(getTypeLabel(rowData))
				local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				remove:SetPoint("RIGHT", -4, 0)
				remove:SetSize(88, 22)
				remove:SetText(_G.REMOVE or "Remove")
				remove:SetScript("OnClick", function()
					if presets:RemoveCombinedExclusion(rowData.spellID) then queueRuntimeRefresh() end
					if state and state.RequestLayout then state:RequestLayout() end
				end)
			end
			return frame
		end,
		trackCustomized = false,
	})
end

registerAuraPresetTrackingSettings()
