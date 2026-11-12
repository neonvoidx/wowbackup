local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.variables = addon.MythicPlus.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)

local function buildTeleportSettings()
	local cGameplay = addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY
	if not cGameplay then return end

	local sectionTeleports = addon.SettingsLayout.gameplayTeleportsSection
	if not sectionTeleports then
		sectionTeleports = addon.functions.SettingsCreateExpandableSection(cGameplay, {
			name = L["Teleports"],
			expanded = false,
			colorizeTitle = false,
			newTagID = "Teleports",
			iconKey = "teleports",
			modernOnly = true,
		})
		addon.SettingsLayout.gameplayTeleportsSection = sectionTeleports
	end

	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "teleportsWorldMapEnabled",
		text = L["teleportsWorldMapEnabled"],
		desc = L["teleportsWorldMapEnabledDesc"],
		richNotes = { { text = L["teleportsWorldMapHelp"] } },
		func = function(value)
			addon.db.teleportsWorldMapEnabled = value
			addon.MythicPlus.functions.RefreshWorldMapTeleportPanel()
		end,
		parentSection = sectionTeleports,
	})
	addon.functions.SettingsCreateInlineHint(cGameplay, L["teleportsWorldMapSettingsHint"], {
		parentSection = sectionTeleports,
	})
end

function addon.MythicPlus.functions.InitTeleportCompendiumSettings()
	if addon.MythicPlus.variables.teleportCompendiumSettingsBuilt then return end
	if not addon.db or not addon.functions or not addon.functions.SettingsCreateCheckbox then return end
	if not addon.SettingsLayout or not addon.SettingsLayout.rootGAMEPLAY then return end
	buildTeleportSettings()
	addon.MythicPlus.variables.teleportCompendiumSettingsBuilt = true
end
