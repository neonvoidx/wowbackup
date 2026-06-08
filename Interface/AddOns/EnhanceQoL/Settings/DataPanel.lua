local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cDataPanel = addon.SettingsLayout.rootUI

local expandable = addon.functions.SettingsCreateExpandableSection(cDataPanel, {
	name = L["DataPanel"],
	description = L["configCenterPageDescDataPanels"]
		or "Configure compact data panels, tooltip hints and modifier-based context menus.",
	newTagID = "DataPanel",
	iconKey = "data",
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateHeadline(cDataPanel, {
	name = _G.SETTINGS or "Settings",
	parentSection = expandable,
	groupID = "settings",
	order = 1,
})

addon.functions.SettingsCreateText(cDataPanel, L["DataPanelEditModeHint"], { parentSection = expandable, order = 1 })

local data = {
	var = "Show options tooltip hint",
	text = L["Show options tooltip hint"],
	desc = L["DataPanelShowOptionsTooltipHintDesc"] or "Shows a short right-click options hint in DataPanel tooltips when a stream has configurable options.",
	order = 10,
	get = function() return addon.DataPanel.ShouldShowOptionsHint and addon.DataPanel.ShouldShowOptionsHint() or false end,
	func = function(key)
		addon.db["chatShowLootCurrencyIcons"] = key
		if addon.DataPanel.SetShowOptionsHint then
			addon.DataPanel.SetShowOptionsHint(key and true or false)
			for name in pairs(addon.DataHub.streams) do
				addon.DataHub:RequestUpdate(name)
			end
		end
	end,
	default = false,
	parentSection = expandable,
}

addon.functions.SettingsCreateCheckbox(cDataPanel, data)

data = {
	list = {
		NONE = NONE,
		SHIFT = SHIFT_KEY_TEXT,
		CTRL = CTRL_KEY_TEXT,
		ALT = ALT_KEY_TEXT,
	},
	text = L["Context menu modifier"],
	desc = L["DataPanelContextMenuModifierDesc"] or "Choose which modifier key must be held before right-click opens DataPanel context menus. None allows normal right-click access.",
	order = 20,
	get = function() return addon.DataPanel.GetMenuModifier and addon.DataPanel.GetMenuModifier() or "NONE" end,
	set = function(value)
		if addon.DataPanel.SetMenuModifier then addon.DataPanel.SetMenuModifier(value) end
	end,
	default = "",
	var = "Context menu modifier",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(cDataPanel, data)

data = {
	id = "DataPanelAddPanel",
	text = L["Add Panel"],
	desc = L["DataPanelAddPanelDesc"] or "Create a new DataPanel. After creation, configure placement, size and streams in Edit Mode.",
	buttonText = L["SettingsDataPanelCreate"] or L["Add Panel"],
	order = 30,
	func = function() StaticPopup_Show("EQOL_CREATE_DATAPANEL") end,
	parentSection = expandable,
}
addon.functions.SettingsCreateButton(cDataPanel, data)
----- REGION END

function addon.functions.initDataPanel()
	StaticPopupDialogs["EQOL_CREATE_DATAPANEL"] = StaticPopupDialogs["EQOL_CREATE_DATAPANEL"]
		or {
			text = L["Panel Name"],
			hasEditBox = true,
			button1 = YES,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self, data)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if editBox then
					editBox:SetText(data or "")
					editBox:SetFocus()
					editBox:HighlightText()
				end
			end,
			OnAccept = function(self)
				local id = self:GetEditBox():GetText()
				if id and id ~= "" then addon.DataPanel.Create(id) end
			end,
		}
end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
