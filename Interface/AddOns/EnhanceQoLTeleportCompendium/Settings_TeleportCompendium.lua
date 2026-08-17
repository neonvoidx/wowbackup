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

	local data = {
		{
			var = "teleportFrame",
			text = L["teleportEnabled"],
			desc = L["teleportEnabledDesc"],
			func = function(v)
				addon.db["teleportFrame"] = v
				addon.MythicPlus.functions.toggleFrame()
			end,
		},
		{
			var = "teleportsWorldMapEnabled",
			text = L["teleportsWorldMapEnabled"],
			desc = L["teleportsWorldMapEnabledDesc"],
			richNotes = {
				{ text = L["teleportsWorldMapEnabledDesc"], order = -1000 },
				{
					blocks = {
						{ text = "|cffffd700" .. L["teleportsWorldMapHelp"] .. "|r" },
					},
				},
			},
			func = function(v)
				addon.db["teleportsWorldMapEnabled"] = v
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.RefreshWorldMapTeleportPanel then addon.MythicPlus.functions.RefreshWorldMapTeleportPanel() end
			end,
		},
		{
			var = "teleportsWorldMapShowSeason",
			text = L["teleportsWorldMapShowSeason"],
			desc = L["teleportsWorldMapShowSeasonDesc"],
			func = function(v) addon.db["teleportsWorldMapShowSeason"] = v end,
		},
		{
			var = "portalHideMissing",
			text = L["portalHideMissing"],
			desc = L["portalHideMissingDesc"],
			func = function(v)
				addon.db["portalHideMissing"] = v
				local functions = addon.MythicPlus and addon.MythicPlus.functions
				if functions and functions.NotifyTeleportFavoritesChanged then functions.NotifyTeleportFavoritesChanged() end
			end,
		},
	}
	table.insert(data, {
		text = L["portalShowTooltip"],
		desc = L["portalShowTooltipDesc"],
		var = "portalShowTooltip",
		func = function(value) addon.db["portalShowTooltip"] = value end,
	})
	table.sort(data, function(a, b) return a.text < b.text end)

	local function applyParentSection(entry)
		entry.parentSection = sectionTeleports
		if entry.children then
			for _, child in pairs(entry.children) do
				applyParentSection(child)
			end
		end
	end
	for _, entry in ipairs(data) do
		applyParentSection(entry)
	end
	addon.functions.SettingsCreateCheckboxes(cGameplay, data)

	addon.functions.SettingsCreateMultiDropdown(cGameplay, {
		var = "teleportsPreferredHearthstone",
		text = L["teleportsPreferredHearthstone"],
		desc = L["teleportsPreferredHearthstoneDesc"],
		listFunc = function()
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.GetHearthstoneSelectionOptions then
				return addon.MythicPlus.functions.GetHearthstoneSelectionOptions(true)
			end
			return {}
		end,
		customDefaultText = L["teleportsPreferredHearthstoneRandom"] or "All owned Hearthstones",
		hideSummary = false,
		summary = function(selection)
			if type(selection) ~= "table" or next(selection) == nil then return L["teleportsPreferredHearthstoneRandom"] or "All owned Hearthstones" end
			return nil
		end,
		set = function(selection)
			addon.db["teleportsPreferredHearthstone"] = selection or {}
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setRandomHearthstone then addon.MythicPlus.functions.setRandomHearthstone(true) end
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.RefreshWorldMapTeleportPanel then addon.MythicPlus.functions.RefreshWorldMapTeleportPanel() end
		end,
		parentSection = sectionTeleports,
	})

end

function addon.MythicPlus.functions.InitTeleportCompendiumSettings()
	if addon.MythicPlus.variables.teleportCompendiumSettingsBuilt then return end
	if not addon.db or not addon.functions or not addon.functions.SettingsCreateCheckboxes then return end
	if not addon.SettingsLayout or not addon.SettingsLayout.rootGAMEPLAY then return end
	buildTeleportSettings()
	addon.MythicPlus.variables.teleportCompendiumSettingsBuilt = true
end
