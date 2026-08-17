local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local cTooltip = addon.SettingsLayout.rootUI

local expandable = addon.functions.SettingsCreateExpandableSection(cTooltip, {
	name = L["Tooltip"],
	description = L["configCenterTooltipDesc"] or "Customize tooltip content, IDs, icons, realms and visibility.",
	configPageID = "interface.tooltips",
	searchtags = { "tooltip", "item id", "spell id", "npc id", "realm", "guild" },
	newTagID = "Tooltip",
	iconKey = "tooltip",
	expanded = false,
	colorizeTitle = false,
})

local modifierList = {
	SHIFT = SHIFT_KEY_TEXT,
	ALT = ALT_KEY_TEXT,
	CTRL = CTRL_KEY_TEXT,
}
local modifierListOrder = { "SHIFT", "ALT", "CTRL" }
local tooltipGroupGeneral = "general"
local tooltipGroupItems = "items"
local tooltipGroupSpells = "spells"
local tooltipGroupUnits = "units"
local tooltipTabGeneral = L["TooltipTabGeneral"]
local tooltipTabItems = L["TooltipTabItems"]
local tooltipTabSpells = L["TooltipTabSpells"]
local tooltipTabUnits = L["TooltipTabUnits"]

addon.functions.SettingsCreateHeadline(cTooltip, {
	name = tooltipTabGeneral,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
	order = 1,
})

addon.functions.SettingsCreateSectionHeader(cTooltip, _G.SETTINGS or "Settings", {
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
	order = 1,
})

addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipIDRequireModifier",
	text = L["TooltipIDRequireModifier"],
	desc = L["TooltipIDRequireModifierDesc"],
	func = function(value) addon.db["TooltipIDRequireModifier"] = value and true or false end,
	default = false,
	order = 1,
	parentSection = expandable,
})

addon.functions.SettingsCreateDropdown(cTooltip, {
	var = "TooltipIDModifier",
	text = L["TooltipIDModifier"],
	list = modifierList,
	order = modifierListOrder,
	get = function() return addon.db["TooltipIDModifier"] or "ALT" end,
	set = function(value) addon.db["TooltipIDModifier"] = value end,
	default = "ALT",
	order = 2,
	parent = true,
	element = addon.SettingsLayout.elements["TooltipIDRequireModifier"] and addon.SettingsLayout.elements["TooltipIDRequireModifier"].element,
	parentCheck = function()
		return addon.SettingsLayout.elements["TooltipIDRequireModifier"]
			and addon.SettingsLayout.elements["TooltipIDRequireModifier"].setting
			and addon.SettingsLayout.elements["TooltipIDRequireModifier"].setting:GetValue() == true
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cTooltip, {
	name = tooltipTabSpells,
	parentSection = expandable,
	groupID = tooltipGroupSpells,
	order = 30,
})

local data = {
	list = { [1] = L["TooltipOFF"], [2] = L["TooltipON"] },
	text = L["TooltipBuffHideType"],
	get = function() return addon.db.TooltipBuffHideType or 1 end,
	set = function(key)
		addon.db.TooltipBuffHideType = key
		if addon.functions.RefreshNativeAuraTooltipPolicy then addon.functions.RefreshNativeAuraTooltipPolicy() end
	end,
	default = 1,
	var = "TooltipBuffHideType",
	type = Settings.VarType.Number,
	parentSection = expandable,
	groupID = tooltipGroupSpells,
	order = 10,
}
addon.functions.SettingsCreateDropdown(cTooltip, data)

data = {
	{
		var = "TooltipBuffHideInCombat",
		text = L["TooltipHideInCombat"],
		func = function(v)
			addon.db["TooltipBuffHideInCombat"] = v
			if addon.functions.RefreshNativeAuraTooltipPolicy then addon.functions.RefreshNativeAuraTooltipPolicy() end
		end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipBuffHideType"]
				and addon.SettingsLayout.elements["TooltipBuffHideType"].setting
				and addon.SettingsLayout.elements["TooltipBuffHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipBuffHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 20,
	},
	{
		var = "TooltipBuffHideInDungeon",
		text = L["TooltipHideInDungeon"],
		func = function(v)
			addon.db["TooltipBuffHideInDungeon"] = v
			if addon.functions.RefreshNativeAuraTooltipPolicy then addon.functions.RefreshNativeAuraTooltipPolicy() end
		end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipBuffHideType"]
				and addon.SettingsLayout.elements["TooltipBuffHideType"].setting
				and addon.SettingsLayout.elements["TooltipBuffHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipBuffHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 30,
	},
}
addon.functions.SettingsCreateCheckboxes(cTooltip, data)

addon.functions.SettingsCreateHeadline(cTooltip, {
	name = tooltipTabItems,
	parentSection = expandable,
	groupID = tooltipGroupItems,
	order = 20,
})

addon.functions.SettingsCreateSectionHeader(cTooltip, AUCTION_HOUSE_HEADER_ITEM, {
	parentSection = expandable,
	groupID = tooltipGroupItems,
	order = 10,
})

data = {
	list = { [1] = L["TooltipOFF"], [2] = L["TooltipON"] },
	text = L["TooltipItemHideType"],
	get = function() return addon.db.TooltipItemHideType or 1 end,
	set = function(key) addon.db.TooltipItemHideType = key end,
	default = 1,
	var = "TooltipItemHideType",
	type = Settings.VarType.Number,
	parentSection = expandable,
	groupID = tooltipGroupItems,
	order = 20,
}
addon.functions.SettingsCreateDropdown(cTooltip, data)

data = {
	{
		var = "TooltipItemHideInCombat",
		text = L["TooltipHideInCombat"],
		func = function(v) addon.db["TooltipItemHideInCombat"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipItemHideType"]
				and addon.SettingsLayout.elements["TooltipItemHideType"].setting
				and addon.SettingsLayout.elements["TooltipItemHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipItemHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupItems,
		order = 30,
	},
	{
		var = "TooltipItemHideInDungeon",
		text = L["TooltipHideInDungeon"],
		func = function(v) addon.db["TooltipItemHideInDungeon"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipItemHideType"]
				and addon.SettingsLayout.elements["TooltipItemHideType"].setting
				and addon.SettingsLayout.elements["TooltipItemHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipItemHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupItems,
		order = 40,
	},
}

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

data = {

	{
		var = "TooltipShowItemID",
		text = L["TooltipShowItemID"],
			func = function(v) addon.db["TooltipShowItemID"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 50,
		},
		{
			var = "TooltipShowItemIcon",
		text = L["TooltipShowItemIcon"],
		func = function(v) addon.db["TooltipShowItemIcon"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 60,
			children = {

			{
				var = "TooltipItemIconSize",
				text = L["TooltipItemIconSize"],
				get = function() return addon.db and addon.db["TooltipItemIconSize"] or 16 end,
				set = function(v) addon.db["TooltipItemIconSize"] = v end,
				min = 10,
				max = 30,
				step = 1,
				default = 16,
				sType = "slider",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipShowItemIcon"]
						and addon.SettingsLayout.elements["TooltipShowItemIcon"].setting
						and addon.SettingsLayout.elements["TooltipShowItemIcon"].setting:GetValue() == true
				end,
					element = addon.SettingsLayout.elements["TooltipShowItemIcon"] and addon.SettingsLayout.elements["TooltipShowItemIcon"].element,
					parentSection = expandable,
					groupID = tooltipGroupItems,
				},
			},
		},
	{
		var = "TooltipShowTempEnchant",
		text = L["TooltipShowTempEnchant"],
		desc = L["TooltipShowTempEnchantDesc"],
		func = function(v) addon.db["TooltipShowTempEnchant"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 70,
		},
		{
			var = "TooltipShowItemCount",
		text = L["TooltipShowItemCount"],
		func = function(v) addon.db["TooltipShowItemCount"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 80,
		},
		{
			var = "TooltipShowSeperateItemCount",
		text = L["TooltipShowSeperateItemCount"],
		func = function(v) addon.db["TooltipShowSeperateItemCount"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 90,
		},
		{
			var = "TooltipHousingAutoPreview",
		text = L["TooltipHousingAutoPreview"],
		desc = L["TooltipHousingAutoPreviewDesc"],
		func = function(v) addon.db["TooltipHousingAutoPreview"] = v end,
			default = false,
			type = Settings.VarType.Boolean,
			parentSection = expandable,
			groupID = tooltipGroupItems,
			order = 100,
		},
}

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

data = {
	list = { [1] = L["TooltipOFF"], [2] = L["TooltipON"] },
	text = L["TooltipSpellHideType"],
	get = function() return addon.db.TooltipSpellHideType or 1 end,
	set = function(key) addon.db.TooltipSpellHideType = key end,
	default = 1,
	var = "TooltipSpellHideType",
	type = Settings.VarType.Number,
	parentSection = expandable,
	groupID = tooltipGroupSpells,
	order = 100,
}
addon.functions.SettingsCreateDropdown(cTooltip, data)

data = {
	{
		var = "TooltipSpellHideInCombat",
		text = L["TooltipHideInCombat"],
		func = function(v) addon.db["TooltipSpellHideInCombat"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipSpellHideType"]
				and addon.SettingsLayout.elements["TooltipSpellHideType"].setting
				and addon.SettingsLayout.elements["TooltipSpellHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipSpellHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 110,
	},
	{
		var = "TooltipSpellHideInDungeon",
		text = L["TooltipHideInDungeon"],
		func = function(v) addon.db["TooltipSpellHideInDungeon"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipSpellHideType"]
				and addon.SettingsLayout.elements["TooltipSpellHideType"].setting
				and addon.SettingsLayout.elements["TooltipSpellHideType"].setting:GetValue() == 2
		end,
		element = addon.SettingsLayout.elements["TooltipSpellHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 120,
	},
	{
		var = "TooltipShowSpellID",
		text = L["TooltipShowSpellID"],
		func = function(v)
			addon.db["TooltipShowSpellID"] = v
			if v and addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.RequestNativeAuraSpellIDs then
				addon.Tooltip.functions.RequestNativeAuraSpellIDs()
			end
		end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 130,
	},
	{
		var = "TooltipShowSpellIcon",
		text = L["TooltipShowSpellIcon"],
		func = function(v) addon.db["TooltipShowSpellIcon"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 140,
	},
	{
		var = "TooltipShowSpellIconInline",
		text = L["TooltipShowSpellIconInline"],
		func = function(v) addon.db["TooltipShowSpellIconInline"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupSpells,
		order = 150,
	},
}

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

-- Quest

addon.functions.SettingsCreateHeadline(cTooltip, {
	name = LOOT_JOURNAL_LEGENDARIES_SOURCE_QUEST,
	parentSection = expandable,
})

data = {
	{
		var = "TooltipShowQuestID",
		text = L["TooltipShowQuestID"],
		func = function(v) addon.db["TooltipShowQuestID"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
	},
	{
		var = "TooltipShowQuestIDInQuestLog",
		text = L["TooltipShowQuestIDInQuestLog"],
		func = function(v)
			addon.db["TooltipShowQuestIDInQuestLog"] = v
			if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.UpdateQuestIDInQuestLog then addon.Tooltip.functions.UpdateQuestIDInQuestLog() end
		end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
	},
}
table.sort(data, function(a, b) return a.text < b.text end)

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

-- Unit

addon.functions.SettingsCreateHeadline(cTooltip, {
	name = tooltipTabUnits,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 50,
})

data = {
	list = { [1] = _G.NONE, [2] = L["Enemies"], [3] = L["Friendly"], [4] = _G.STATUS_TEXT_BOTH },
	text = L["TooltipUnitHideType"],
	get = function() return addon.db.TooltipUnitHideType or 1 end,
	set = function(key) addon.db.TooltipUnitHideType = key end,
	default = 1,
	var = "TooltipUnitHideType",
	type = Settings.VarType.Number,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 10,
}
addon.functions.SettingsCreateDropdown(cTooltip, data)

data = {
	{
		var = "TooltipUnitHideInCombat",
		text = L["TooltipHideInCombat"],
		func = function(v) addon.db["TooltipUnitHideInCombat"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipUnitHideType"]
				and addon.SettingsLayout.elements["TooltipUnitHideType"].setting
				and addon.SettingsLayout.elements["TooltipUnitHideType"].setting:GetValue() > 1
		end,
		element = addon.SettingsLayout.elements["TooltipUnitHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 20,
	},
	{
		var = "TooltipUnitHideInDungeon",
		text = L["TooltipHideInDungeon"],
		func = function(v) addon.db["TooltipUnitHideInDungeon"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parent = true,
		parentCheck = function()
			return addon.SettingsLayout.elements["TooltipUnitHideType"]
				and addon.SettingsLayout.elements["TooltipUnitHideType"].setting
				and addon.SettingsLayout.elements["TooltipUnitHideType"].setting:GetValue() > 1
		end,
		element = addon.SettingsLayout.elements["TooltipUnitHideType"].element,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 30,
	},
}

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

data = {
	{
		var = "TooltipUnitHideHealthBar",
		text = L["TooltipUnitHideHealthBar"],
		func = function(v) addon.db["TooltipUnitHideHealthBar"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 40,
	},
	{
		var = "TooltipUnitHideRightClickInstruction",
		text = L["TooltipUnitHideRightClickInstruction"]:format(UNIT_POPUP_RIGHT_CLICK),
		func = function(v) addon.db["TooltipUnitHideRightClickInstruction"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 50,
	},
	{
		var = "TooltipHideFaction",
		text = L["TooltipHideFaction"],
		func = function(v) addon.db["TooltipHideFaction"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 60,
	},
	{
		var = "TooltipHidePVP",
		text = L["TooltipHidePVP"],
		func = function(v) addon.db["TooltipHidePVP"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 70,
	},
	{
		var = "TooltipUnitShowTargetOfTarget",
		text = L["TooltipShowTargetOfTarget"],
		func = function(v) addon.db["TooltipUnitShowTargetOfTarget"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 180,
		children = {
			{
				var = "TooltipTargetOfTargetRealmMode",
				text = L["TooltipTargetOfTargetRealmMode"],
				order = 181,
				list = {
					SHOW = L["TooltipTargetOfTargetRealmModeShow"],
					HIDE = L["TooltipTargetOfTargetRealmModeHide"],
					STAR = L["TooltipTargetOfTargetRealmModeStar"],
				},
				orderList = { "SHOW", "HIDE", "STAR" },
				get = function() return addon.db["TooltipTargetOfTargetRealmMode"] or "SHOW" end,
				set = function(value) addon.db["TooltipTargetOfTargetRealmMode"] = value ~= "SHOW" and value or nil end,
				default = "SHOW",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"]
						and addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"].setting
						and addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"].setting:GetValue() == true
				end,
				sType = "dropdown",
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
			{
				var = "TooltipTargetOfTargetColorMode",
				text = L["TooltipTargetOfTargetColorMode"],
				order = 182,
				list = {
					DEFAULT = L["TooltipTargetOfTargetColorModeDefault"],
					UNIT = L["TooltipTargetOfTargetColorModeUnit"],
				},
				orderList = { "DEFAULT", "UNIT" },
				get = function() return addon.db["TooltipTargetOfTargetColorMode"] or "DEFAULT" end,
				set = function(value) addon.db["TooltipTargetOfTargetColorMode"] = value ~= "DEFAULT" and value or nil end,
				default = "DEFAULT",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"]
						and addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"].setting
						and addon.SettingsLayout.elements["TooltipUnitShowTargetOfTarget"].setting:GetValue() == true
				end,
				sType = "dropdown",
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
		},
	},
	{
		var = "TooltipUnitShowMount",
		text = L["TooltipShowMount"],
		func = function(v) addon.db["TooltipUnitShowMount"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 190,
	},
	{
		var = "TooltipShowRealmInfo",
		text = L["TooltipShowRealmInfo"],
		desc = L["TooltipShowRealmInfoDesc"],
		func = function(v) addon.db["TooltipShowRealmInfo"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 150,
		children = {
			{
				var = "TooltipRealmInfoFields",
				text = L["TooltipRealmFields"],
				desc = L["TooltipRealmFieldsDesc"],
				order = 151,
				options = {
					{ value = "connected", text = L["TooltipRealmShowConnected"] },
					{ value = "language", text = L["TooltipRealmShowLanguage"] },
					{ value = "timezone", text = L["TooltipRealmShowTimezone"] },
					{ value = "type", text = L["TooltipRealmShowType"] },
				},
				getSelection = function()
					if type(addon.db["TooltipRealmInfoFields"]) ~= "table" then addon.db["TooltipRealmInfoFields"] = { language = true, type = true, connected = true } end
					return addon.db["TooltipRealmInfoFields"]
				end,
				setSelection = function(selection) addon.db["TooltipRealmInfoFields"] = type(selection) == "table" and selection or {} end,
				sType = "multidropdown",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipShowRealmInfo"]
						and addon.SettingsLayout.elements["TooltipShowRealmInfo"].setting
						and addon.SettingsLayout.elements["TooltipShowRealmInfo"].setting:GetValue() == true
				end,
				element = addon.SettingsLayout.elements["TooltipShowRealmInfo"] and addon.SettingsLayout.elements["TooltipShowRealmInfo"].element,
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
			{
				var = "TooltipRealmLFGDisplay",
				text = L["TooltipRealmLFGDisplay"],
				desc = L["TooltipRealmLFGDisplayDesc"],
				order = 152,
				options = {
					{ value = "tooltip", text = L["TooltipRealmLFGTooltip"] },
					{ value = "listingFlag", text = L["TooltipRealmLFGListingFlag"] },
				},
				getSelection = function()
					if type(addon.db["TooltipRealmLFGDisplay"]) ~= "table" then addon.db["TooltipRealmLFGDisplay"] = { tooltip = true, listingFlag = true } end
					return addon.db["TooltipRealmLFGDisplay"]
				end,
				setSelection = function(selection) addon.db["TooltipRealmLFGDisplay"] = type(selection) == "table" and selection or {} end,
				sType = "multidropdown",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipShowRealmInfo"]
						and addon.SettingsLayout.elements["TooltipShowRealmInfo"].setting
						and addon.SettingsLayout.elements["TooltipShowRealmInfo"].setting:GetValue() == true
				end,
				element = addon.SettingsLayout.elements["TooltipShowRealmInfo"] and addon.SettingsLayout.elements["TooltipShowRealmInfo"].element,
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
		},
	},
	{
		var = "TooltipShowGuildRank",
		text = L["TooltipShowGuildRank"],
		func = function(v) addon.db["TooltipShowGuildRank"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 140,
		children = {
			{
				var = "TooltipGuildRankColor",
				text = L["TooltipGuildRankColor"],
				order = 141,
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipShowGuildRank"]
						and addon.SettingsLayout.elements["TooltipShowGuildRank"].setting
						and addon.SettingsLayout.elements["TooltipShowGuildRank"].setting:GetValue() == true
				end,
				colorizeLabel = true,
				sType = "colorpicker",
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
		},
	},
	{
		var = "TooltipColorGuildName",
		text = L["TooltipColorGuildName"],
		func = function(v) addon.db["TooltipColorGuildName"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupUnits,
		order = 120,
		children = {
			{
				var = "TooltipGuildNameColor",
				text = L["TooltipGuildNameColor"],
				order = 121,
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["TooltipColorGuildName"]
						and addon.SettingsLayout.elements["TooltipColorGuildName"].setting
						and addon.SettingsLayout.elements["TooltipColorGuildName"].setting:GetValue() == true
				end,
				colorizeLabel = true,
				sType = "colorpicker",
				parentSection = expandable,
				groupID = tooltipGroupUnits,
			},
		},
	},
}

addon.functions.SettingsCreateCheckboxes(cTooltip, data)

local guildRankToggle = addon.SettingsLayout.elements["TooltipShowGuildRank"]

-- Player

addon.functions.SettingsCreateSectionHeader(cTooltip, PLAYER, {
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 100,
})

local function TooltipPlayerHasMythicDetails() return addon.db["TooltipShowMythicScore"] and true or false end

local function TooltipPlayerHasInspectDetails() return (addon.db["TooltipUnitShowSpec"] or addon.db["TooltipUnitShowItemLevel"]) and true or false end

local function BuildTooltipPlayerDetailOptions()
	return {
		{ value = "mythic", text = L["TooltipShowMythicScore"]:format(DUNGEON_SCORE) },
		{ value = "spec", text = L["TooltipUnitShowSpec"] },
		{ value = "ilvl", text = L["TooltipUnitShowItemLevel"] },
		{ value = "classColor", text = L["TooltipShowClassColor"] },
	}
end

local function IsTooltipPlayerDetailSelected(key)
	if not key then return false end
	if key == "mythic" then return addon.db["TooltipShowMythicScore"] and true or false end
	if key == "spec" then return (addon.db["TooltipUnitShowSpec"] and true or false) end
	if key == "ilvl" then return (addon.db["TooltipUnitShowItemLevel"] and true or false) end
	if key == "classColor" then return addon.db["TooltipShowClassColor"] and true or false end
	return false
end

local function SetTooltipPlayerDetailSelected(key, shouldSelect)
	if not key then return end
	local enabled = shouldSelect and true or false

	if key == "mythic" then
		addon.db["TooltipShowMythicScore"] = enabled
	elseif key == "spec" then
		addon.db["TooltipUnitShowSpec"] = enabled
	elseif key == "ilvl" then
		addon.db["TooltipUnitShowItemLevel"] = enabled
	elseif key == "classColor" then
		addon.db["TooltipShowClassColor"] = enabled
	else
		return
	end

	if (key == "spec" or key == "ilvl") and addon.functions.UpdateInspectEventRegistration then addon.functions.UpdateInspectEventRegistration() end
end

local function BuildMythicScorePartsOptions()
	return {
		{ value = "score", text = DUNGEON_SCORE },
		{ value = "best", text = L["BestMythic+run"] },
		{ value = "dungeons", text = L["SeasonDungeons"] or "Season dungeons" },
	}
end

local function IsMythicScorePartSelected(key)
	local parts = addon.db["TooltipMythicScoreParts"] or {}
	return parts[key] and true or false
end

local function SetMythicScorePartSelected(key, shouldSelect)
	if not key then return end
	addon.db["TooltipMythicScoreParts"] = addon.db["TooltipMythicScoreParts"] or { score = true, best = true, dungeons = true }
	if shouldSelect then
		addon.db["TooltipMythicScoreParts"][key] = true
	else
		addon.db["TooltipMythicScoreParts"][key] = nil
	end
end

addon.functions.SettingsCreateMultiDropdown(cTooltip, {
	var = "TooltipPlayerDetailsLabel",
	storage = false,
	text = L["TooltipPlayerDetailsLabel"],
	options = BuildTooltipPlayerDetailOptions(),
	optionfunc = BuildTooltipPlayerDetailOptions,
	isSelectedFunc = IsTooltipPlayerDetailSelected,
	setSelectedFunc = SetTooltipPlayerDetailSelected,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 110,
})

local playerDetailsElement = addon.SettingsLayout.elements["TooltipPlayerDetailsLabel"]
local playerDetailsInitializer = playerDetailsElement and playerDetailsElement.initializer

addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipMythicScoreRequireModifier",
	text = L["TooltipMythicScoreRequireModifier"]:format(DUNGEON_SCORE),
	func = function(value) addon.db["TooltipMythicScoreRequireModifier"] = value and true or false end,
	default = false,
	parent = true,
	element = playerDetailsInitializer,
	parentCheck = TooltipPlayerHasMythicDetails,
	notify = "TooltipPlayerDetailsLabel",
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 160,
})

addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipUnitInspectRequireModifier",
	text = L["TooltipUnitInspectRequireModifier"],
	func = function(value)
		addon.db["TooltipUnitInspectRequireModifier"] = value and true or false
		if addon.functions.UpdateInspectEventRegistration then addon.functions.UpdateInspectEventRegistration() end
	end,
	default = false,
	parent = true,
	element = playerDetailsInitializer,
	parentCheck = TooltipPlayerHasInspectDetails,
	notify = "TooltipPlayerDetailsLabel",
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 170,
})

addon.functions.SettingsCreateDropdown(cTooltip, {
	var = "TooltipMythicScoreModifier",
	text = MODIFIERS_COLON,
	list = modifierList,
	order = modifierListOrder,
	get = function() return addon.db["TooltipMythicScoreModifier"] or "SHIFT" end,
	set = function(value) addon.db["TooltipMythicScoreModifier"] = value end,
	default = "SHIFT",
	parent = true,
	element = playerDetailsInitializer,
	parentCheck = function()
		return (
			addon.SettingsLayout.elements["TooltipUnitInspectRequireModifier"]
				and addon.SettingsLayout.elements["TooltipUnitInspectRequireModifier"].setting
				and addon.SettingsLayout.elements["TooltipUnitInspectRequireModifier"].setting:GetValue() == true
				and (addon.db["TooltipUnitShowSpec"] or addon.db["TooltipUnitShowItemLevel"])
			or addon.SettingsLayout.elements["TooltipMythicScoreRequireModifier"]
				and addon.SettingsLayout.elements["TooltipMythicScoreRequireModifier"].setting
				and addon.SettingsLayout.elements["TooltipMythicScoreRequireModifier"].setting:GetValue() == true
				and addon.db["TooltipShowMythicScore"]
		)
	end,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 175,
})

addon.functions.SettingsCreateMultiDropdown(cTooltip, {
	var = "TooltipMythicScoreParts",
	text = L["MythicScorePartsLabel"] or "Mythic+ details to show",
	options = BuildMythicScorePartsOptions(),
	optionfunc = BuildMythicScorePartsOptions,
	isSelectedFunc = IsMythicScorePartSelected,
	setSelectedFunc = SetMythicScorePartSelected,
	parent = true,
	element = playerDetailsInitializer,
	parentCheck = TooltipPlayerHasMythicDetails,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 165,
})

addon.functions.SettingsCreateSectionHeader(cTooltip, {
	name = L["TooltipUnitNPCGroup"],
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 200,
})

addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipShowNPCID",
	text = L["TooltipShowNPCID"],
	func = function(value) addon.db["TooltipShowNPCID"] = value and true or false end,
	default = false,
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 210,
})
addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipShowNPCWowheadLink",
	text = L["TooltipShowNPCWowheadLink"],
	func = function(value) addon.db["TooltipShowNPCWowheadLink"] = value and true or false end,
	default = false,
	desc = L["TooltipShowNPCWowheadLink_desc"],
	parentSection = expandable,
	groupID = tooltipGroupUnits,
	order = 220,
})

addon.functions.SettingsCreateSectionHeader(cTooltip, GENERAL, {
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
	order = 20,
})

addon.functions.SettingsCreateCheckbox(cTooltip, {
	var = "TooltipHideOverrideEnabled",
	text = L["TooltipHideOverride"],
	func = function(value)
		addon.db["TooltipHideOverrideEnabled"] = value and true or false
		if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.InitState then addon.Tooltip.functions.InitState() end
	end,
	default = false,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
})

local overrideModifierList = {
	SHIFT = SHIFT_KEY_TEXT,
	ALT = ALT_KEY_TEXT,
	CTRL = CTRL_KEY_TEXT,
}
local overrideModifierListOrder = { "SHIFT", "ALT", "CTRL" }

addon.functions.SettingsCreateDropdown(cTooltip, {
	var = "TooltipHideOverrideModifier",
	text = MODIFIERS_COLON,
	list = overrideModifierList,
	order = overrideModifierListOrder,
	get = function() return addon.db["TooltipHideOverrideModifier"] or "CTRL" end,
	set = function(value)
		addon.db["TooltipHideOverrideModifier"] = value
		if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.InitState then addon.Tooltip.functions.InitState() end
	end,
	default = "CTRL",
	parent = true,
	element = addon.SettingsLayout.elements["TooltipHideOverrideEnabled"] and addon.SettingsLayout.elements["TooltipHideOverrideEnabled"].element,
	parentCheck = function()
		return addon.SettingsLayout.elements["TooltipHideOverrideEnabled"]
			and addon.SettingsLayout.elements["TooltipHideOverrideEnabled"].setting
			and addon.SettingsLayout.elements["TooltipHideOverrideEnabled"].setting:GetValue() == true
	end,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
})

data = {
	list = { [1] = DEFAULT, [2] = L["CursorCenter"], [3] = L["CursorLeft"], [4] = L["CursorRight"] },
	text = L["TooltipAnchorType"],
	get = function() return addon.db.TooltipAnchorType or 1 end,
	set = function(key)
		addon.db.TooltipAnchorType = key
		if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.InitState then addon.Tooltip.functions.InitState() end
	end,
	default = 1,
	var = "TooltipAnchorType",
	type = Settings.VarType.Number,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
}
addon.functions.SettingsCreateDropdown(cTooltip, data)

data = {
	var = "TooltipAnchorOffsetX",
	text = L["TooltipAnchorOffsetX"],
	get = function() return addon.db and addon.db.TooltipAnchorOffsetX or 0 end,
	set = function(v) addon.db["TooltipAnchorOffsetX"] = v end,
	parentCheck = function()
		return addon.SettingsLayout.elements["TooltipAnchorType"]
			and addon.SettingsLayout.elements["TooltipAnchorType"].setting
			and addon.SettingsLayout.elements["TooltipAnchorType"].setting:GetValue() > 2
	end,
	min = -300,
	max = 300,
	step = 1,
	parent = true,
	element = addon.SettingsLayout.elements["TooltipAnchorType"].element,
	default = 0,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
}
addon.functions.SettingsCreateSlider(cTooltip, data)

data = {
	var = "TooltipAnchorOffsetY",
	text = L["TooltipAnchorOffsetY"],
	get = function() return addon.db and addon.db.TooltipAnchorOffsetY or 0 end,
	set = function(v) addon.db["TooltipAnchorOffsetY"] = v end,
	parentCheck = function()
		return addon.SettingsLayout.elements["TooltipAnchorType"]
			and addon.SettingsLayout.elements["TooltipAnchorType"].setting
			and addon.SettingsLayout.elements["TooltipAnchorType"].setting:GetValue() > 2
	end,
	min = -300,
	max = 300,
	step = 1,
	parent = true,
	element = addon.SettingsLayout.elements["TooltipAnchorType"].element,
	default = 0,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
}
addon.functions.SettingsCreateSlider(cTooltip, data)

addon.functions.SettingsCreateSlider(cTooltip, {
	var = "TooltipScale",
	text = L["TooltipScale"],
	get = function() return addon.db and addon.db["TooltipScale"] or 1 end,
	set = function(v)
		addon.db["TooltipScale"] = v
		if addon.Tooltip and addon.Tooltip.ApplyScale then addon.Tooltip.ApplyScale() end
	end,
	min = 0.5,
	max = 1.5,
	step = 0.05,
	default = 1,
	parentSection = expandable,
	groupID = tooltipGroupGeneral,
})

addon.functions.SettingsCreateSectionHeader(cTooltip, {
	name = CURRENCY,
	parentSection = expandable,
	groupID = tooltipGroupItems,
	order = 200,
})
data = {
	{
		var = "TooltipShowCurrencyAccountWide",
		text = L["TooltipShowCurrencyAccountWide"],
		func = function(v) addon.db["TooltipShowCurrencyAccountWide"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupItems,
		order = 210,
	},
	{
		var = "TooltipShowCurrencyID",
		text = L["TooltipShowCurrencyID"],
		func = function(v) addon.db["TooltipShowCurrencyID"] = v end,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = expandable,
		groupID = tooltipGroupItems,
		order = 220,
	},
}
addon.functions.SettingsCreateCheckboxes(cTooltip, data)

----- REGION END

function addon.functions.initTooltip() end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
