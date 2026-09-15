local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local tools = addon.ProfileTools
if not tools then return end

local profilesCategory = nil
local expandable = addon.functions.SettingsCreateExpandableSection(profilesCategory, {
	name = L["damageMeterTitle"] or "Damage Meter",
	configPageKey = "ProfilesDamageMeter",
	description = L["configCenterPageCardDescProfilesDamageMeter"],
	iconAtlas = "icons_64x64_damage",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesDamageMeter",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "damageMeterExport",
	text = string.format("%s %s", L["Export"] or "Export", L["damageMeterTitle"] or "Damage Meter"),
	func = function()
		local code, reason = tools.ExportDamageMeter()
		if not code then
			print("|cff00ff98Enhance QoL|r: " .. tostring(tools.DataExportErrorMessage(reason)))
			return
		end
		tools.ShowExportCodeDialog("EQOL_DAMAGE_METER_EXPORT", string.format("%s %s", L["Export"] or "Export", L["damageMeterTitle"] or "Damage Meter"), code)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "damageMeterImport",
	text = string.format("%s %s", L["Import"] or "Import", L["damageMeterTitle"] or "Damage Meter"),
	func = function()
		tools.ShowImportCodeDialog(
			"EQOL_DAMAGE_METER_IMPORT",
			string.format("%s %s", L["Import"] or "Import", L["damageMeterTitle"] or "Damage Meter"),
			L["damageMeterImportConfirm"] or "Importing will overwrite your Damage Meter settings in the active profile.",
			tools.ImportDamageMeter,
			L["damageMeterImportSuccess"] or "Damage Meter settings imported.",
			false
		)
	end,
	parentSection = expandable,
})
