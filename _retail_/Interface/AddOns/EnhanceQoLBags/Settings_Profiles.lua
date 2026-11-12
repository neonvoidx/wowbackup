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
	name = L["Bags categories"] or "Bags categories",
	configPageKey = "ProfilesBagsCategories",
	description = L["configCenterPageCardDescBagsCategories"],
	iconKey = "bagscategories",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesBagsCategories",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "bagsCategoriesExport",
	text = L["Export Bags categories"] or "Export Bags categories",
	func = function()
		local code, reason = tools.ExportBagsCategories()
		if not code then
			print("|cff00ff98Enhance QoL|r: " .. tostring(tools.DataExportErrorMessage(reason)))
			return
		end
		tools.ShowExportCodeDialog("EQOL_BAGS_CATEGORIES_EXPORT", L["Export Bags categories"] or "Export Bags categories", code)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "bagsCategoriesImport",
	text = L["Import Bags categories"] or "Import Bags categories",
	func = function()
		tools.ShowImportCodeDialog(
			"EQOL_BAGS_CATEGORIES_IMPORT",
			L["Import Bags categories"] or "Import Bags categories",
			L["BagsCategoriesImportConfirm"] or "Importing will overwrite your Bags categories.",
			tools.ImportBagsCategories,
			L["BagsCategoriesImportSuccess"] or "Bags categories imported.",
			false
		)
	end,
	parentSection = expandable,
})
