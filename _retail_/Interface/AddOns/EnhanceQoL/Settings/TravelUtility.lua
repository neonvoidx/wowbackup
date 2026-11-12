local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local gameplayCategory = addon.SettingsLayout.rootGAMEPLAY

local summonsExpandable = addon.functions.SettingsCreateExpandableSection(gameplayCategory, {
	name = L["autoAcceptSummon"],
	configPageKey = "AutoAcceptSummons",
	modernCategory = "gameplay",
	modernOnly = true,
	iconKey = "teleports",
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateCheckbox(gameplayCategory, {
	var = "autoAcceptSummon",
	text = L["autoAcceptSummon"],
	desc = L["autoAcceptSummonDesc"],
	type = "CheckBox",
	default = false,
	func = function(value) addon.db.autoAcceptSummon = value == true end,
	parentSection = summonsExpandable,
})
