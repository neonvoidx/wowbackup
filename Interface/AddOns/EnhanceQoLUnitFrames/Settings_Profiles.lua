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
	name = L["Healer Buff Placement"] or "Buff Placement",
	configPageKey = "ProfilesHBP",
	description = L["configCenterPageCardDescProfilesHealerBuffPlacement"],
	iconAtlas = "UI-LFG-RoleIcon-Healer",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesHBP",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "hbpExport",
	text = L["Export Healer Buff Placement"] or "Export Buff Placement",
	func = function()
		local code, reason = tools.ExportHBP()
		if not code then
			print("|cff00ff98Enhance QoL|r: " .. tostring(tools.DataExportErrorMessage(reason)))
			return
		end
		tools.ShowExportCodeDialog("EQOL_HBP_EXPORT", L["Export Healer Buff Placement"] or "Export Buff Placement", code)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "hbpImport",
	text = L["Import Healer Buff Placement"] or "Import Buff Placement",
	func = function()
		tools.ShowImportCodeDialog(
			"EQOL_HBP_IMPORT",
			L["Import Healer Buff Placement"] or "Import Buff Placement",
			L["HBPImportConfirm"] or "Importing will overwrite your Buff Placement settings.",
			tools.ImportHBP,
			L["HBPImportSuccess"] or "Buff Placement imported.",
			false
		)
	end,
	parentSection = expandable,
})
