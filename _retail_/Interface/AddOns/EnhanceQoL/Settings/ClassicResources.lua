local _, addon = ...
local M = addon.ClassicResources
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local category = addon.SettingsLayout.rootUI
for index, kind in ipairs({ "ammo", "talents" }) do
	local spec = M.reminders[kind]
	local order = 200 + index * 100
	local section = addon.functions.SettingsClassicUtilityBlock(L[spec.title], spec.id, order, spec.id)
	addon.functions.SettingsCreateCheckbox(category, {
		var = "classicResources_" .. spec.flag, text = L[kind == "ammo" and "ammoLowEnabled" or "unspentTalentReminder"],
		default = false, parentSection = section, order = order + 10, refreshOnChange = true,
		newTagID = "classicResources_" .. spec.flag, get = function() return M.Options()[spec.flag] == true end,
		func = function(value) M.Options()[spec.flag] = value == true; M.RequestUpdate() end,
	})
	addon.functions.SettingsCreateText(category, L["classicResourceReminderHint"], { parentSection = section, order = order + 20 })
end
