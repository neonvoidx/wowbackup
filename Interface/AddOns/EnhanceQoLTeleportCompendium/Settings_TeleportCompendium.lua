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

local partyKeystoneFontOrder = {}
local partyKeystoneBorderOrder = {}

local function refreshPartyKeystoneFrame()
	local functions = addon.MythicPlus and addon.MythicPlus.functions
	if functions and functions.RefreshPartyKeystoneFrame then functions.RefreshPartyKeystoneFrame() end
end

local function updateKeystoneDungeonIndicator()
	local functions = addon.MythicPlus and addon.MythicPlus.functions
	if functions and functions.UpdateKeystoneDungeonIndicator then functions.UpdateKeystoneDungeonIndicator() end
end

local function buildPartyKeystoneFontList()
	local defaultFont = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local map = { [defaultFont] = L["actionBarFontDefault"] or "Blizzard font" }
	local globalKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey()
	if globalKey then map[globalKey] = addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or "Use global font" end
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	local hash = addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font") or {}
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
	end
	local list, order = addon.functions.prepareListForDropdown(map)
	wipe(partyKeystoneFontOrder)
	if globalKey and list[globalKey] then partyKeystoneFontOrder[#partyKeystoneFontOrder + 1] = globalKey end
	for _, key in ipairs(order or {}) do
		if key ~= globalKey then partyKeystoneFontOrder[#partyKeystoneFontOrder + 1] = key end
	end
	return list
end

local function buildPartyKeystoneBorderList()
	local map = { ["Blizzard Tooltip"] = "Blizzard Tooltip" }
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or {}
	for i = 1, #names do
		local name = names[i]
		map[name] = name
	end
	local list, order = addon.functions.prepareListForDropdown(map)
	wipe(partyKeystoneBorderOrder)
	for _, key in ipairs(order or {}) do
		partyKeystoneBorderOrder[#partyKeystoneBorderOrder + 1] = key
	end
	return list
end

local function isPartyKeystoneEnabled() return addon.db and addon.db.groupfinderShowPartyKeystone == true end
local function isPartyKeystoneFixedWidth() return isPartyKeystoneEnabled() and addon.db.partyKeystoneFrameAutoWidth ~= true end
local function isPartyKeystoneBorderEnabled() return isPartyKeystoneEnabled() and addon.db.partyKeystoneFrameBorderEnabled == true end
local function isPartyKeystoneCustomNameColor() return isPartyKeystoneEnabled() and addon.db.partyKeystoneFrameUseClassColor ~= true end

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

	local sectionGroupFinder = addon.SettingsLayout.gameplayGroupFinderSection
	if sectionGroupFinder then
		local groupFinderControlOrder = addon.SettingsLayout.gameplayGroupFinderControlOrder or {}
		local groupFinderData = {
			{
				var = "groupfinderShowDungeonScoreFrame",
				text = L["groupfinderShowDungeonScoreFrame"]:format(DUNGEON_SCORE),
				desc = L["groupfinderShowDungeonScoreFrameDesc"],
				func = function(v)
					addon.db["groupfinderShowDungeonScoreFrame"] = v
					if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.toggleFrame then addon.MythicPlus.functions.toggleFrame() end
				end,
				order = groupFinderControlOrder.groupfinderShowDungeonScoreFrame,
				parentSection = sectionGroupFinder,
			},
		}
		table.sort(groupFinderData, function(a, b) return a.text < b.text end)
		addon.functions.SettingsCreateCheckboxes(cGameplay, groupFinderData)
	end

	if not sectionGroupFinder then return end
	local sectionKeystone = sectionGroupFinder
	addon.functions.SettingsCreateSectionHeader(cGameplay, L["Keystone"], {
		parentSection = sectionKeystone,
		newTagID = "KeystonePartyFrame",
	})

	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "groupfinderShowPartyKeystone",
		text = L["groupfinderShowPartyKeystone"],
		desc = L["groupfinderShowPartyKeystoneDesc"],
		default = false,
		func = function(value)
			addon.db.groupfinderShowPartyKeystone = value == true
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.togglePartyKeystone then addon.MythicPlus.functions.togglePartyKeystone() end
		end,
		parentSection = sectionKeystone,
	})
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneDungeonIndicatorEnabled",
		text = L["keystoneDungeonIndicator"],
		desc = L["keystoneDungeonIndicatorDesc"],
		default = false,
		func = function(value)
			addon.db.partyKeystoneDungeonIndicatorEnabled = value == true
			updateKeystoneDungeonIndicator()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneDungeonIndicatorEnabled",
	})

	addon.functions.SettingsCreateSectionHeader(cGameplay, L["Frame"], {
		parentSection = sectionKeystone,
	})

	local anchorOptions = {
		DEFAULT = _G.DEFAULT or "Default",
		RIGHT = L["Right"],
		LEFT = L["Left"],
		TOP = L["Top"],
	}
	addon.functions.SettingsCreateDropdown(cGameplay, {
		var = "partyKeystoneFrameAnchor",
		text = L["Anchor"],
		list = anchorOptions,
		order = { "DEFAULT", "RIGHT", "LEFT", "TOP" },
		default = "DEFAULT",
		set = function(value)
			addon.db.partyKeystoneFrameAnchor = anchorOptions[value] and value or "DEFAULT"
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameAnchor",
	})
	for _, offset in ipairs({
		{ var = "partyKeystoneFrameOffsetX", text = L["X Offset"] },
		{ var = "partyKeystoneFrameOffsetY", text = L["Y Offset"] },
	}) do
		local offsetVar = offset.var
		local offsetText = offset.text
		addon.functions.SettingsCreateSlider(cGameplay, {
			var = offsetVar,
			text = offsetText,
			min = -500,
			max = 500,
			step = 1,
			default = 0,
			set = function(value)
				addon.db[offsetVar] = tonumber(value) or 0
				refreshPartyKeystoneFrame()
			end,
			parentCheck = isPartyKeystoneEnabled,
			parentSection = sectionKeystone,
			newTagID = offsetVar,
		})
	end
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneFrameAutoWidth",
		text = L["keystoneFrameAutomaticWidth"],
		default = true,
		func = function(value)
			addon.db.partyKeystoneFrameAutoWidth = value == true
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameAutoWidth",
	})
	addon.functions.SettingsCreateSlider(cGameplay, {
		var = "partyKeystoneFrameWidth",
		text = L["Width"],
		min = 160,
		max = 600,
		step = 1,
		default = 200,
		set = function(value)
			addon.db.partyKeystoneFrameWidth = tonumber(value) or 200
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneFixedWidth,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameWidth",
	})
	addon.functions.SettingsCreateSlider(cGameplay, {
		var = "partyKeystoneFrameHeight",
		text = L["Height"],
		min = 36,
		max = 100,
		step = 1,
		default = 50,
		set = function(value)
			addon.db.partyKeystoneFrameHeight = tonumber(value) or 50
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameHeight",
	})
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneFrameShowIcon",
		text = L["Show icon"],
		desc = L["keystoneFrameShowIconDesc"],
		default = true,
		func = function(value)
			addon.db.partyKeystoneFrameShowIcon = value == true
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameShowIcon",
	})
	addon.functions.SettingsCreateSlider(cGameplay, {
		var = "partyKeystoneFrameIconSize",
		text = L["Icon size"],
		min = 16,
		max = 64,
		step = 1,
		default = 30,
		set = function(value)
			addon.db.partyKeystoneFrameIconSize = tonumber(value) or 30
			refreshPartyKeystoneFrame()
		end,
		parentCheck = function() return isPartyKeystoneEnabled() and addon.db.partyKeystoneFrameShowIcon == true end,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameIconSize",
	})

	addon.functions.SettingsCreateSectionHeader(cGameplay, L["Font"], {
		parentSection = sectionKeystone,
	})
	addon.functions.SettingsCreateScrollDropdown(cGameplay, {
		var = "partyKeystoneFrameFont",
		text = L["Font"],
		listFunc = buildPartyKeystoneFontList,
		order = partyKeystoneFontOrder,
		default = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT,
		set = function(value)
			addon.db.partyKeystoneFrameFont = value
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameFont",
	})
	local fontStyleOptions, fontStyleOrder = addon.functions.GetFontStyleOptions and addon.functions.GetFontStyleOptions(true) or {
		NONE = _G.NONE or "None",
		OUTLINE = L["Outline"],
	}, { "NONE", "OUTLINE" }
	addon.functions.SettingsCreateDropdown(cGameplay, {
		var = "partyKeystoneFrameFontStyle",
		text = L["keystoneFrameFontStyle"],
		list = fontStyleOptions,
		order = fontStyleOrder,
		default = "NONE",
		set = function(value)
			addon.db.partyKeystoneFrameFontStyle = value or "NONE"
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameFontStyle",
	})
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneFrameShowRealm",
		text = L["keystoneFrameShowRealm"],
		default = false,
		func = function(value)
			addon.db.partyKeystoneFrameShowRealm = value == true
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameShowRealm",
	})
	for _, textSetting in ipairs({
		{ var = "partyKeystoneFrameLevelFontSize", label = L["Level"] .. " - " .. (_G.FONT_SIZE or "Font size"), default = 16 },
		{ var = "partyKeystoneFrameLocationFontSize", label = L["Location"] .. " - " .. (_G.FONT_SIZE or "Font size"), default = 12 },
		{ var = "partyKeystoneFrameNameFontSize", label = L["Name"] .. " - " .. (_G.FONT_SIZE or "Font size"), default = 12 },
	}) do
		local settingVar = textSetting.var
		local settingLabel = textSetting.label
		local settingDefault = textSetting.default
		addon.functions.SettingsCreateSlider(cGameplay, {
			var = settingVar,
			text = settingLabel,
			min = 8,
			max = 32,
			step = 1,
			default = settingDefault,
			set = function(value)
				addon.db[settingVar] = tonumber(value) or settingDefault
				refreshPartyKeystoneFrame()
			end,
			parentCheck = isPartyKeystoneEnabled,
			parentSection = sectionKeystone,
			newTagID = settingVar,
		})
	end
	for _, colorSetting in ipairs({
		{ var = "partyKeystoneFrameLevelColor", label = L["Level"] .. " - " .. L["Text color"], default = { r = 1, g = 1, b = 1, a = 1 } },
		{ var = "partyKeystoneFrameLocationColor", label = L["Location"] .. " - " .. L["Text color"], default = { r = 1, g = 0.82, b = 0, a = 1 } },
	}) do
		local colorVar = colorSetting.var
		local colorLabel = colorSetting.label
		local colorDefault = colorSetting.default
		addon.functions.SettingsCreateColorPicker(cGameplay, {
			var = colorVar,
			text = colorLabel,
			default = colorDefault,
			hasOpacity = true,
			callback = refreshPartyKeystoneFrame,
			parentCheck = isPartyKeystoneEnabled,
			parentSection = sectionKeystone,
			newTagID = colorVar,
		})
	end
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneFrameUseClassColor",
		text = L["Use class color"],
		default = true,
		func = function(value)
			addon.db.partyKeystoneFrameUseClassColor = value == true
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameUseClassColor",
	})
	addon.functions.SettingsCreateColorPicker(cGameplay, {
		var = "partyKeystoneFrameNameColor",
		text = L["Name"] .. " - " .. L["Text color"],
		default = { r = 1, g = 1, b = 1, a = 1 },
		hasOpacity = true,
		callback = refreshPartyKeystoneFrame,
		parentCheck = isPartyKeystoneCustomNameColor,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameNameColor",
	})

	addon.functions.SettingsCreateSectionHeader(cGameplay, L["Background"], {
		parentSection = sectionKeystone,
	})
	addon.functions.SettingsCreateColorPicker(cGameplay, {
		var = "partyKeystoneFrameBackgroundColor",
		text = L["Background color"],
		default = { r = 0, g = 0, b = 0, a = 0.8 },
		hasOpacity = true,
		callback = refreshPartyKeystoneFrame,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameBackgroundColor",
	})

	addon.functions.SettingsCreateSectionHeader(cGameplay, L["Border"], {
		parentSection = sectionKeystone,
	})
	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "partyKeystoneFrameBorderEnabled",
		text = L["Border"],
		default = false,
		func = function(value)
			addon.db.partyKeystoneFrameBorderEnabled = value == true
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameBorderEnabled",
	})
	addon.functions.SettingsCreateScrollDropdown(cGameplay, {
		var = "partyKeystoneFrameBorderStyle",
		text = L["keystoneFrameBorderStyle"],
		listFunc = buildPartyKeystoneBorderList,
		order = partyKeystoneBorderOrder,
		default = "Blizzard Tooltip",
		set = function(value)
			addon.db.partyKeystoneFrameBorderStyle = value or "Blizzard Tooltip"
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneBorderEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameBorderStyle",
	})
	addon.functions.SettingsCreateSlider(cGameplay, {
		var = "partyKeystoneFrameBorderSize",
		text = L["Border size"],
		min = 1,
		max = 32,
		step = 1,
		default = 16,
		set = function(value)
			addon.db.partyKeystoneFrameBorderSize = tonumber(value) or 16
			refreshPartyKeystoneFrame()
		end,
		parentCheck = isPartyKeystoneBorderEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameBorderSize",
	})
	addon.functions.SettingsCreateColorPicker(cGameplay, {
		var = "partyKeystoneFrameBorderColor",
		text = L["Border color"],
		default = { r = 1, g = 1, b = 1, a = 1 },
		hasOpacity = true,
		callback = refreshPartyKeystoneFrame,
		parentCheck = isPartyKeystoneBorderEnabled,
		parentSection = sectionKeystone,
		newTagID = "partyKeystoneFrameBorderColor",
	})
end

function addon.MythicPlus.functions.InitTeleportCompendiumSettings()
	if addon.MythicPlus.variables.teleportCompendiumSettingsBuilt then return end
	if not addon.db or not addon.functions or not addon.functions.SettingsCreateCheckboxes then return end
	if not addon.SettingsLayout or not addon.SettingsLayout.rootGAMEPLAY then return end
	buildTeleportSettings()
	addon.MythicPlus.variables.teleportCompendiumSettingsBuilt = true
end
