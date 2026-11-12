local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local category = addon.SettingsLayout.rootUI
local section = addon.functions.SettingsClassicUtilityBlock(L["rangeDisplayName"], "range", 200, "rangeDisplay")
addon.functions.SettingsCreateCheckbox(category, {
	var = "rangeDisplayEnabled", order = 210, text = L["rangeDisplayEnabled"], desc = L["rangeDisplayDescription"],
	newTagID = "rangeDisplayEnabled", parentSection = section,
	func = function(value)
		addon.db.rangeDisplayEnabled = value == true
		addon.RangeDisplay:Refresh()
	end,
})
addon.functions.SettingsCreateText(category, L["rangeDisplayEditModeHint"], { parentSection = section, order = 220 })
