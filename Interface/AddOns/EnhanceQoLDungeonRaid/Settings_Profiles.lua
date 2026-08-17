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
	name = L["mythicPlusTimerTitle"] or "Mythic+ Timer",
	configPageKey = "ProfilesMythicPlusTimer",
	description = L["configCenterPageCardDescProfilesMythicPlusTimer"] or "Export and import Mythic+ Timer settings for the active profile.",
	iconKey = "dungeons",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesMythicPlusTimer",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "mythicPlusTimerExport",
	text = L["mythicPlusTimerExport"] or "Export Mythic+ Timer",
	func = function()
		local code, reason = tools.ExportMythicPlusTimer()
		if not code then
			print("|cff00ff98Enhance QoL|r: " .. tostring(tools.DataExportErrorMessage(reason)))
			return
		end
		tools.ShowExportCodeDialog("EQOL_MYTHIC_PLUS_TIMER_EXPORT", L["mythicPlusTimerExport"] or "Export Mythic+ Timer", code)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "mythicPlusTimerImport",
	text = L["mythicPlusTimerImport"] or "Import Mythic+ Timer",
	func = function()
		tools.ShowImportCodeDialog(
			"EQOL_MYTHIC_PLUS_TIMER_IMPORT",
			L["mythicPlusTimerImport"] or "Import Mythic+ Timer",
			L["mythicPlusTimerImportConfirm"] or "Importing will overwrite your Mythic+ Timer settings in the active profile.",
			tools.ImportMythicPlusTimer,
			L["mythicPlusTimerImportSuccess"] or "Mythic+ Timer settings imported.",
			false
		)
	end,
	parentSection = expandable,
})
