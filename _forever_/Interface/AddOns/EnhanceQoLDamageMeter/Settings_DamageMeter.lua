local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local cChar = addon.SettingsLayout.rootGAMEPLAY

local damageMeterSection = addon.SettingsLayout.suitesDamageMeterSection
if not damageMeterSection then
	damageMeterSection = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["damageMeterTitle"] or "Damage Meter",
		configPageKey = "DamageMeter",
		description = L["damageMeterEditModeHint"],
		iconAtlas = "icons_64x64_damage",
		modernCategory = "gameplay",
		modernOnly = true,
		expanded = false,
		colorizeTitle = false,
		newTagID = "damageMeterEnabled",
	})
	addon.SettingsLayout.suitesDamageMeterSection = damageMeterSection
end

addon.functions.SettingsCreateCheckbox(cChar, {
	var = "damageMeterEnabled",
	text = L["damageMeterEnabled"],
	desc = L["damageMeterEditModeHint"],
	func = function(value)
		addon.db["damageMeterEnabled"] = value == true
		if addon.DamageMeter and addon.DamageMeter.UpdateEventState then addon.DamageMeter:UpdateEventState() end
	end,
	parentSection = damageMeterSection,
})

addon.functions.SettingsCreateInlineHint(cChar, L["damageMeterEditModeHint"], {
	id = "damageMeter.editModeHint",
	parentSection = damageMeterSection,
})
