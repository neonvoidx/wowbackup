-- luacheck: globals LOOT_SPECIALIZATION
local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cDataPanel = addon.SettingsLayout.rootUI
local dataPanelGroupID = "interface-panels-map-datapanel"
local dataPanelGroupTitle = L["DataPanel"]

local expandable = addon.functions.SettingsCreateExpandableSection(cDataPanel, {
	name = L["DataPanel"],
	description = L["configCenterPageDescDataPanels"]
		or "Configure compact data panels, tooltip hints and modifier-based context menus.",
	newTagID = "DataPanel",
	iconKey = "data",
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateHeadline(cDataPanel, {
	name = _G.SETTINGS or "Settings",
	parentSection = expandable,
	groupID = dataPanelGroupID,
	groupTitle = dataPanelGroupTitle,
	order = 1,
})

addon.functions.SettingsCreateText(cDataPanel, L["DataPanelEditModeHint"], {
	parentSection = expandable,
	groupID = dataPanelGroupID,
	groupTitle = dataPanelGroupTitle,
	order = 1,
})

local data = {
	var = "Show options tooltip hint",
	text = L["Show options tooltip hint"],
	desc = L["DataPanelShowOptionsTooltipHintDesc"] or "Shows a short right-click options hint in DataPanel tooltips when a stream has configurable options.",
	order = 10,
	get = function() return addon.DataPanel.ShouldShowOptionsHint and addon.DataPanel.ShouldShowOptionsHint() or false end,
	func = function(key)
		addon.db["chatShowLootCurrencyIcons"] = key
		if addon.DataPanel.SetShowOptionsHint then
			addon.DataPanel.SetShowOptionsHint(key and true or false)
			for name in pairs(addon.DataHub.streams) do
				addon.DataHub:RequestUpdate(name)
			end
		end
	end,
	default = false,
	parentSection = expandable,
	groupID = dataPanelGroupID,
	groupTitle = dataPanelGroupTitle,
}

addon.functions.SettingsCreateCheckbox(cDataPanel, data)

data = {
	list = {
		NONE = NONE,
		SHIFT = SHIFT_KEY_TEXT,
		CTRL = CTRL_KEY_TEXT,
		ALT = ALT_KEY_TEXT,
	},
	text = L["Context menu modifier"],
	desc = L["DataPanelContextMenuModifierDesc"] or "Choose which modifier key must be held before right-click opens DataPanel context menus. None allows normal right-click access.",
	order = 20,
	get = function() return addon.DataPanel.GetMenuModifier and addon.DataPanel.GetMenuModifier() or "NONE" end,
	set = function(value)
		if addon.DataPanel.SetMenuModifier then addon.DataPanel.SetMenuModifier(value) end
	end,
	default = "",
	var = "Context menu modifier",
	parentSection = expandable,
	groupID = dataPanelGroupID,
	groupTitle = dataPanelGroupTitle,
}

addon.functions.SettingsCreateDropdown(cDataPanel, data)

data = {
	id = "DataPanelAddPanel",
	text = L["Add Panel"],
	desc = L["DataPanelAddPanelDesc"] or "Create a new DataPanel. After creation, configure placement, size and streams in Edit Mode.",
	buttonText = L["SettingsDataPanelCreate"] or L["Add Panel"],
	order = 30,
	func = function() StaticPopup_Show("EQOL_CREATE_DATAPANEL") end,
	parentSection = expandable,
	groupID = dataPanelGroupID,
	groupTitle = dataPanelGroupTitle,
}
addon.functions.SettingsCreateButton(cDataPanel, data)

local datapanel = {}

datapanel.normalColor = function()
	local r, g, b = 1, 0.82, 0
	if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then r, g, b = NORMAL_FONT_COLOR:GetRGB() end
	return { r = r, g = g, b = b, a = 1 }
end

datapanel.whiteColor = function() return { r = 1, g = 1, b = 1, a = 1 } end

function datapanel.copyColor(color)
	color = type(color) == "table" and color or datapanel.normalColor()
	return { r = color.r or 1, g = color.g or 1, b = color.b or 1, a = color.a or 1 }
end

function datapanel.defaultValue(value)
	if type(value) == "function" then return value() end
	if type(value) == "table" then return datapanel.copyColor(value) end
	return value
end

function datapanel.getDB(dbKey, defaults)
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel[dbKey] = addon.db.datapanel[dbKey] or {}
	local db = addon.db.datapanel[dbKey]
	for key, value in pairs(defaults or {}) do
		if db[key] == nil then db[key] = datapanel.defaultValue(value) end
	end
	return db
end

function datapanel.requestUpdate(streamID)
	if streamID == "markbar" then
		if addon.MarkBarOptions and addon.MarkBarOptions.RequestUpdates then
			addon.MarkBarOptions.RequestUpdates()
		elseif addon.DataHub then
			addon.DataHub:RequestUpdate("markbar_target")
			addon.DataHub:RequestUpdate("markbar_world")
			addon.DataHub:RequestUpdate("markbar_util")
		end
	elseif addon.DataHub then
		addon.DataHub:RequestUpdate(streamID)
	end
end

datapanel.markBarDefaults = { showTargets = true, showWorld = true, showUtility = true, iconSize = 14 }

datapanel.statDisplayLabels = {
	percent = L["StatDisplayModePercent"] or "Percent",
	rating = L["StatDisplayModeRating"] or "Rating",
	both = L["StatDisplayModeBoth"] or "Rating + Percent",
}

datapanel.statDisplayOrder = { "percent", "rating", "both" }
datapanel.statDisplayModes = { percent = true, rating = true, both = true }
datapanel.statDefaultColors = {
	primary = { r = 1, g = 0.82, b = 0, a = 1 },
	haste = { r = 0.31, g = 0.86, b = 0.43, a = 1 },
	mastery = { r = 0.62, g = 0.56, b = 1, a = 1 },
	crit = { r = 1, g = 0.36, b = 0.28, a = 1 },
	lifesteal = { r = 0.35, g = 0.85, b = 0.88, a = 1 },
	block = { r = 0.95, g = 0.67, b = 0.25, a = 1 },
	parry = { r = 0.86, g = 0.52, b = 1, a = 1 },
	dodge = { r = 0.58, g = 0.95, b = 0.42, a = 1 },
	avoidance = { r = 0.48, g = 0.72, b = 1, a = 1 },
	speed = { r = 0.38, g = 0.92, b = 1, a = 1 },
}
datapanel.secondaryStats = {
	{ key = "haste", label = STAT_HASTE or "Haste", supportsMode = true },
	{ key = "mastery", label = STAT_MASTERY or "Mastery", supportsMode = true, supportsSecondaryPercent = true },
	{ key = "crit", label = STAT_CRITICAL_STRIKE or "Crit", supportsMode = true },
	{ key = "lifesteal", label = STAT_LIFESTEAL or "Leech", supportsMode = true },
	{ key = "block", label = STAT_BLOCK or "Block", supportsMode = true },
	{ key = "parry", label = STAT_PARRY or "Parry", supportsMode = true },
	{ key = "dodge", label = STAT_DODGE or "Dodge", supportsMode = true },
	{ key = "avoidance", label = STAT_AVOIDANCE or "Avoidance", supportsMode = true },
	{ key = "speed", label = STAT_SPEED or "Speed", supportsMode = true },
}

function datapanel.normalizeStatMode(value)
	return datapanel.statDisplayModes[value] and value or "percent"
end

function datapanel.getStatsDefaultColor(key)
	return datapanel.copyColor(datapanel.statDefaultColors[key] or datapanel.normalColor())
end

function datapanel.isStatsDefaultWhite(color)
	return type(color) == "table" and color.r == 1 and color.g == 1 and color.b == 1 and (color.a == nil or color.a == 1)
end

function datapanel.getPrimaryStatName()
	local primaryIndex
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecializationInfo then
		local spec = C_SpecializationInfo.GetSpecialization()
		if spec then primaryIndex = select(6, C_SpecializationInfo.GetSpecializationInfo(spec, false, false, nil, UnitSex and UnitSex("player"))) end
	end
	if primaryIndex == LE_UNIT_STAT_STRENGTH then return ITEM_MOD_STRENGTH_SHORT or PRIMARY or "Primary" end
	if primaryIndex == LE_UNIT_STAT_AGILITY then return ITEM_MOD_AGILITY_SHORT or PRIMARY or "Primary" end
	if primaryIndex == LE_UNIT_STAT_INTELLECT then return ITEM_MOD_INTELLECT_SHORT or PRIMARY or "Primary" end
	return PRIMARY or "Primary"
end

function datapanel.ensureStatsEntry(key, supportsMode, supportsSecondaryPercent)
	local db = datapanel.getDB("stats", { fontSize = 14, vertical = false })
	db[key] = type(db[key]) == "table" and db[key] or {}
	local entry = db[key]
	if entry.enabled == nil then entry.enabled = true end
	if supportsMode then
		if entry.mode == nil and entry.rating ~= nil then
			entry.mode = entry.rating and "rating" or "percent"
		end
		entry.mode = datapanel.normalizeStatMode(entry.mode)
	else
		entry.mode = nil
	end
	entry.rating = nil
	if supportsSecondaryPercent then
		if entry.showSecondaryPercent == nil then entry.showSecondaryPercent = true end
	else
		entry.showSecondaryPercent = nil
	end
	if type(entry.color) ~= "table" or datapanel.isStatsDefaultWhite(entry.color) then
		entry.color = datapanel.getStatsDefaultColor(key)
	end
	return entry
end

function datapanel.getStatsEntryValue(key, field, defaultValue, supportsMode, supportsSecondaryPercent)
	local entry = datapanel.ensureStatsEntry(key, supportsMode, supportsSecondaryPercent)
	if entry[field] == nil then return defaultValue end
	return entry[field]
end

function datapanel.isStatsEntryEnabled(key, supportsMode, supportsSecondaryPercent)
	return datapanel.getStatsEntryValue(key, "enabled", true, supportsMode, supportsSecondaryPercent) == true
end

function datapanel.setStatsEntryValue(key, field, value, supportsMode, supportsSecondaryPercent)
	local entry = datapanel.ensureStatsEntry(key, supportsMode, supportsSecondaryPercent)
	if field == "enabled" or field == "showSecondaryPercent" then
		entry[field] = value and true or false
	elseif field == "mode" then
		entry[field] = datapanel.normalizeStatMode(value)
	else
		entry[field] = value
	end
	datapanel.requestUpdate("stats")
end

function datapanel.getStatsEntryColor(key, supportsMode, supportsSecondaryPercent)
	local color = datapanel.ensureStatsEntry(key, supportsMode, supportsSecondaryPercent).color
	return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

function datapanel.setStatsEntryColor(key, supportsMode, supportsSecondaryPercent, _, r, g, b, a)
	local entry = datapanel.ensureStatsEntry(key, supportsMode, supportsSecondaryPercent)
	entry.color = { r = r, g = g, b = b, a = a or 1 }
	datapanel.requestUpdate("stats")
end

function datapanel.addStatsControls(controls, key, label, supportsMode, supportsSecondaryPercent)
	local function isEnabled()
		return datapanel.isStatsEntryEnabled(key, supportsMode, supportsSecondaryPercent)
	end
	controls[#controls + 1] = {
		type = "sectionheader",
		text = label,
	}
	controls[#controls + 1] = {
		key = key .. "_enabled",
		text = SHOW or "Show",
		default = true,
		get = function() return datapanel.getStatsEntryValue(key, "enabled", true, supportsMode, supportsSecondaryPercent) == true end,
		set = function(value) datapanel.setStatsEntryValue(key, "enabled", value, supportsMode, supportsSecondaryPercent) end,
		refreshOnChange = true,
	}
	if supportsMode then
		controls[#controls + 1] = {
			type = "dropdown",
			key = key .. "_mode",
			text = DISPLAY_MODE or "Display mode",
			list = datapanel.statDisplayLabels,
			listOrder = datapanel.statDisplayOrder,
			default = "percent",
			get = function() return datapanel.getStatsEntryValue(key, "mode", "percent", supportsMode, supportsSecondaryPercent) end,
			set = function(value) datapanel.setStatsEntryValue(key, "mode", value, supportsMode, supportsSecondaryPercent) end,
			isEnabled = isEnabled,
		}
	end
	if supportsSecondaryPercent then
		controls[#controls + 1] = {
			key = key .. "_showSecondaryPercent",
			text = L["StatDisplayShowSecondaryPercent"] or "Show second percent value",
			default = true,
			get = function() return datapanel.getStatsEntryValue(key, "showSecondaryPercent", true, supportsMode, supportsSecondaryPercent) == true end,
			set = function(value) datapanel.setStatsEntryValue(key, "showSecondaryPercent", value, supportsMode, supportsSecondaryPercent) end,
			isEnabled = isEnabled,
		}
	end
	controls[#controls + 1] = {
		type = "color",
		key = key .. "_color",
		text = COLOR or "Color",
		default = function() return datapanel.getStatsDefaultColor(key) end,
		getColor = function() return datapanel.getStatsEntryColor(key, supportsMode, supportsSecondaryPercent) end,
		setColor = function(...) datapanel.setStatsEntryColor(key, supportsMode, supportsSecondaryPercent, ...) end,
		isEnabled = isEnabled,
	}
end

function datapanel.createStatsControls()
	local controls = { datapanel.fontSlider, { key = "vertical", text = L["Display vertically"] or "Display vertically", default = false } }
	datapanel.addStatsControls(controls, "primary", datapanel.getPrimaryStatName(), false, false)
	for _, stat in ipairs(datapanel.secondaryStats) do
		datapanel.addStatsControls(controls, stat.key, stat.label, stat.supportsMode, stat.supportsSecondaryPercent)
	end
	return controls
end

function datapanel.getValue(dbKey, defaults, key)
	return datapanel.getDB(dbKey, defaults)[key]
end

function datapanel.setValue(streamID, dbKey, defaults, key, value, normalize)
	local db = datapanel.getDB(dbKey, defaults)
	db[key] = normalize and normalize(value, db) or value
	datapanel.requestUpdate(streamID)
end

function datapanel.isGoldCustomColorEnabled()
	return datapanel.getValue("gold", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isDurabilityCustomColorEnabled()
	return datapanel.getValue("durability", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isEquipmentSetsCustomColorEnabled()
	return datapanel.getValue("equipmentsets", { useTextColor = false }, "useTextColor") == true
end

function datapanel.normalizeEquipmentSetsClassColor(value, db)
	value = value and true or false
	if value then db.useTextColor = false end
	return value
end

function datapanel.normalizeEquipmentSetsCustomColor(value, db)
	value = value and true or false
	if value then db.useClassColor = false end
	return value
end

function datapanel.isFriendsCustomColorEnabled()
	return datapanel.getValue("friends", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isPlayerNameCustomColorEnabled()
	return datapanel.getValue("playername", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isPlayerNameFactionColorEnabled()
	local db = datapanel.getDB("playername", { showRealm = false, useFactionColor = false, separateRealmColor = false, realmUseFactionColor = true })
	return db.useFactionColor == true or (db.showRealm == true and db.separateRealmColor == true and db.realmUseFactionColor == true)
end

function datapanel.isPlayerNameSeparateRealmColorEnabled()
	local db = datapanel.getDB("playername", { showRealm = false, separateRealmColor = false })
	return db.showRealm == true and db.separateRealmColor == true
end

function datapanel.isPlayerNameRealmCustomColorEnabled()
	local db = datapanel.getDB("playername", { showRealm = false, separateRealmColor = false, realmUseTextColor = false })
	return db.showRealm == true and db.separateRealmColor == true and db.realmUseTextColor == true
end

function datapanel.normalizePlayerNameClassColor(value, db)
	value = value and true or false
	if value then
		db.useFactionColor = false
		db.useTextColor = false
	end
	return value
end

function datapanel.normalizePlayerNameFactionColor(value, db)
	value = value and true or false
	if value then
		db.useClassColor = false
		db.useTextColor = false
	end
	return value
end

function datapanel.normalizePlayerNameCustomColor(value, db)
	value = value and true or false
	if value then
		db.useClassColor = false
		db.useFactionColor = false
	end
	return value
end

function datapanel.normalizePlayerNameRealmClassColor(value, db)
	value = value and true or false
	if value then
		db.realmUseFactionColor = false
		db.realmUseTextColor = false
	end
	return value
end

function datapanel.normalizePlayerNameRealmFactionColor(value, db)
	value = value and true or false
	if value then
		db.realmUseClassColor = false
		db.realmUseTextColor = false
	end
	return value
end

function datapanel.normalizePlayerNameRealmCustomColor(value, db)
	value = value and true or false
	if value then
		db.realmUseClassColor = false
		db.realmUseFactionColor = false
	end
	return value
end

function datapanel.isLatencyCustomColorEnabled()
	return datapanel.getValue("latency", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isTimeCustomColorEnabled()
	return datapanel.getValue("time", { useClassColor = false }, "useClassColor") ~= true
end

function datapanel.normalizeTimeClassColor(value, db)
	value = value and true or false
	return value
end

function datapanel.isFriendsSplitDisplayEnabled()
	return datapanel.getValue("friends", { splitDisplay = false }, "splitDisplay") == true
end

function datapanel.normalizeFriendsClassColor(value, db)
	value = value and true or false
	if value then db.useTextColor = false end
	return value
end

function datapanel.normalizeFriendsCustomColor(value, db)
	value = value and true or false
	if value then db.useClassColor = false end
	return value
end

datapanel.currencyFormatOptions = {
	full = L["CurrencyFormatFull"] or "Full (13,343)",
	short0 = L["CurrencyFormatShort0"] or "Short (13k)",
	short1 = L["CurrencyFormatShort1"] or "Short (13.3k)",
	short2 = L["CurrencyFormatShort2"] or "Short (13.34k)",
	short3 = L["CurrencyFormatShort3"] or "Short (13.343k)",
}
datapanel.currencyFormatOrder = { "full", "short0", "short1", "short2", "short3" }
datapanel.currencyDefaults = { ids = {}, currencyOptions = {}, includeBlizzardTracked = false, useTextColor = false }
datapanel.microBarDefaults = { displayMode = "menu", iconSize = 14, iconGap = 5, equalButtonSize = false, buttonBackdrop = false, buttonBorder = true, buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 }, buttonSize = 20 }

function datapanel.isCurrencyCustomColorEnabled()
	return datapanel.getValue("currency", datapanel.currencyDefaults, "useTextColor") == true
end

function datapanel.isVolumeCustomColorEnabled()
	return datapanel.getValue("volume", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isTalentCustomColorEnabled()
	return datapanel.getValue("talent", { useTextColor = false }, "useTextColor") == true
end

function datapanel.isTalentPrefixCustomColorEnabled()
	return datapanel.getValue("talent", { usePrefixColor = false }, "usePrefixColor") == true
end

function datapanel.getMicroBarDB()
	local db = datapanel.getDB("microbar", datapanel.microBarDefaults)
	if type(db.hiddenEntries) ~= "table" then db.hiddenEntries = {} end
	return db
end

function datapanel.isMicroBarButtonBorderEnabled()
	return datapanel.getValue("microbar", { buttonBorder = true }, "buttonBorder") == true
end

function datapanel.isMicroBarButtonSizingEnabled()
	local db = datapanel.getMicroBarDB()
	return db.equalButtonSize == true or db.buttonBackdrop == true or db.buttonBorder == true
end

function datapanel.getMicroBarVisibleIconOptions()
	if addon.MicroBarOptions and addon.MicroBarOptions.GetVisibleEntryOptions then
		return addon.MicroBarOptions.GetVisibleEntryOptions()
	end
	return {}
end

function datapanel.isMicroBarIconVisible(entryID)
	if addon.MicroBarOptions and addon.MicroBarOptions.IsEntryVisible then
		return addon.MicroBarOptions.IsEntryVisible(entryID)
	end
	return datapanel.getMicroBarDB().hiddenEntries[entryID] ~= true
end

function datapanel.setMicroBarIconVisible(entryID, visible)
	if addon.MicroBarOptions and addon.MicroBarOptions.SetEntryVisible then
		addon.MicroBarOptions.SetEntryVisible(entryID, visible)
		return
	end
	local db = datapanel.getMicroBarDB()
	if visible then
		db.hiddenEntries[entryID] = nil
	else
		db.hiddenEntries[entryID] = true
	end
	datapanel.requestUpdate("microbar")
end

function datapanel.isPetTrackerIconShown()
	return datapanel.getValue("pettracker", { showIcon = true }, "showIcon") == true
end

function datapanel.isPetTrackerBlinkEnabled()
	return datapanel.getValue("pettracker", { blinkEnabled = false }, "blinkEnabled") == true
end

function datapanel.isClassBuffPetPassiveIgnored()
	return addon.db and addon.db.classBuffReminderIgnorePetPassive == true
end

function datapanel.setClassBuffPetPassiveIgnored(value)
	if addon.db then addon.db.classBuffReminderIgnorePetPassive = value and true or false end
	if addon.ClassBuffReminder and addon.ClassBuffReminder.RequestUpdate then addon.ClassBuffReminder:RequestUpdate(true, 0, true) end
	datapanel.requestUpdate("pettracker")
end

function datapanel.isClassBuffPetDefensiveIgnored()
	return addon.db and addon.db.classBuffReminderIgnorePetDefensive == true
end

function datapanel.setClassBuffPetDefensiveIgnored(value)
	if addon.db then addon.db.classBuffReminderIgnorePetDefensive = value and true or false end
	if addon.ClassBuffReminder and addon.ClassBuffReminder.RequestUpdate then addon.ClassBuffReminder:RequestUpdate(true, 0, true) end
	datapanel.requestUpdate("pettracker")
end

function datapanel.resetPetTrackerBlink(value)
	if addon.PetTrackerOptions and addon.PetTrackerOptions.ResetBlink then addon.PetTrackerOptions.ResetBlink() end
	return value
end

function datapanel.normalizeCurrencyTracked(value)
	if addon.DataPanelCurrency and addon.DataPanelCurrency.MarkTrackedDirty then addon.DataPanelCurrency.MarkTrackedDirty() end
	return value and true or false
end

function datapanel.getCurrencyDB()
	local db = datapanel.getDB("currency", datapanel.currencyDefaults)
	db.ids = type(db.ids) == "table" and db.ids or {}
	db.currencyOptions = type(db.currencyOptions) == "table" and db.currencyOptions or {}
	return db
end

function datapanel.getCurrencyInfo(currencyID)
	currencyID = tonumber(currencyID)
	if not currencyID or currencyID <= 0 or not C_CurrencyInfo then return nil end
	if C_CurrencyInfo.GetCurrencyInfo then
		local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
		if info and info.name then return info end
	end
	if C_CurrencyInfo.GetBasicCurrencyInfo then
		return C_CurrencyInfo.GetBasicCurrencyInfo(currencyID)
	end
	return nil
end

function datapanel.getCurrencyFormatKey(options)
	options = type(options) == "table" and options or {}
	if options.mode == "short" then
		local decimals = math.max(0, math.min(3, math.floor((tonumber(options.decimals) or 0) + 0.5)))
		return "short" .. decimals
	end
	return "full"
end

function datapanel.setCurrencyFormat(currencyID, formatKey)
	local db = datapanel.getCurrencyDB()
	currencyID = tonumber(currencyID)
	if not currencyID then return end
	db.currencyOptions[currencyID] = db.currencyOptions[currencyID] or {}
	local options = db.currencyOptions[currencyID]
	if formatKey == "short0" or formatKey == "short1" or formatKey == "short2" or formatKey == "short3" then
		options.mode = "short"
		options.decimals = tonumber(formatKey:match("short(%d)")) or 0
	else
		options.mode = "full"
		options.decimals = 0
	end
	datapanel.requestUpdate("currency")
end

function datapanel.getCurrencyEntries()
	local entries = {}
	local db = datapanel.getCurrencyDB()
	for index, currencyID in ipairs(db.ids) do
		local info = datapanel.getCurrencyInfo(currencyID) or {}
		entries[#entries + 1] = {
			index = index,
			currencyID = currencyID,
			name = info.name or ("ID " .. tostring(currencyID)),
			iconFileID = info.iconFileID or info.icon,
			formatKey = datapanel.getCurrencyFormatKey(db.currencyOptions[currencyID]),
		}
	end
	return entries
end

function datapanel.addCurrencyEntry(text)
	local currencyID = tonumber(text)
	local info = datapanel.getCurrencyInfo(currencyID)
	if not info then return end
	local db = datapanel.getCurrencyDB()
	for _, existing in ipairs(db.ids) do
		if existing == currencyID then return end
	end
	db.ids[#db.ids + 1] = currencyID
	if addon.DataPanelCurrency and addon.DataPanelCurrency.MarkTrackedDirty then addon.DataPanelCurrency.MarkTrackedDirty() end
	datapanel.requestUpdate("currency")
end

function datapanel.removeCurrencyEntry(currencyID)
	currencyID = tonumber(currencyID)
	if not currencyID then return end
	local db = datapanel.getCurrencyDB()
	for index, existing in ipairs(db.ids) do
		if existing == currencyID then
			table.remove(db.ids, index)
			db.currencyOptions[currencyID] = nil
			if addon.DataPanelCurrency and addon.DataPanelCurrency.MarkTrackedDirty then addon.DataPanelCurrency.MarkTrackedDirty() end
			datapanel.requestUpdate("currency")
			return
		end
	end
end

function datapanel.moveCurrencyEntry(fromIndex, toIndex)
	local db = datapanel.getCurrencyDB()
	fromIndex = tonumber(fromIndex)
	toIndex = tonumber(toIndex)
	if not fromIndex or not toIndex or fromIndex == toIndex or fromIndex < 1 or toIndex < 1 or fromIndex > #db.ids or toIndex > #db.ids then return end
	local id = table.remove(db.ids, fromIndex)
	table.insert(db.ids, toIndex, id)
	if addon.DataPanelCurrency and addon.DataPanelCurrency.MarkTrackedDirty then addon.DataPanelCurrency.MarkTrackedDirty() end
	datapanel.requestUpdate("currency")
end

function datapanel.createSlider(section, stream, control, order)
	local updateID = control.updateID or stream.updateID or stream.id
	return addon.functions.SettingsCreateSlider(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		min = control.min,
		max = control.max,
		step = control.step or 1,
		default = control.default,
		get = function() return datapanel.getValue(stream.dbKey, stream.defaults, control.key) end,
		set = function(value) datapanel.setValue(updateID, stream.dbKey, stream.defaults, control.key, value, control.normalize) end,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
		refreshOnChange = control.refreshOnChange,
		order = order,
	})
end

function datapanel.createCheckbox(section, stream, control, order)
	local updateID = control.updateID or stream.updateID or stream.id
	return addon.functions.SettingsCreateCheckbox(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		default = control.default,
		get = control.get or function() return datapanel.getValue(stream.dbKey, stream.defaults, control.key) == true end,
		func = control.set or function(value) datapanel.setValue(updateID, stream.dbKey, stream.defaults, control.key, value and true or false, control.normalize) end,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
		refreshOnChange = control.refreshOnChange,
		order = order,
	})
end

function datapanel.createDropdown(section, stream, control, order)
	local updateID = control.updateID or stream.updateID or stream.id
	return addon.functions.SettingsCreateDropdown(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		list = control.list,
		listFunc = control.listFunc,
		default = control.default,
		get = control.get or function() return datapanel.getValue(stream.dbKey, stream.defaults, control.key) end,
		set = control.set or function(value) datapanel.setValue(updateID, stream.dbKey, stream.defaults, control.key, value, control.normalize) end,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
		refreshOnChange = control.refreshOnChange,
		orderList = control.orderList or control.listOrder,
		order = control.order or order,
	})
end

function datapanel.createInput(section, stream, control, order)
	local updateID = control.updateID or stream.updateID or stream.id
	return addon.functions.SettingsCreateInput(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		default = control.default or "",
		get = function() return datapanel.getValue(stream.dbKey, stream.defaults, control.key) or "" end,
		set = function(value) datapanel.setValue(updateID, stream.dbKey, stream.defaults, control.key, value or "", control.normalize) end,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
		refreshOnChange = control.refreshOnChange,
		order = order,
	})
end

function datapanel.createColor(section, stream, control, order)
	local updateID = control.updateID or stream.updateID or stream.id
	return addon.functions.SettingsCreateColorPicker(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		default = control.default,
		getColor = control.getColor or function()
			local color = datapanel.getValue(stream.dbKey, stream.defaults, control.key) or datapanel.defaultValue(control.default)
			return color.r or 1, color.g or 1, color.b or 1, color.a or 1
		end,
		setColor = control.setColor or function(_, r, g, b, a)
			datapanel.setValue(updateID, stream.dbKey, stream.defaults, control.key, { r = r, g = g, b = b, a = a or 1 }, control.normalize)
		end,
		getDefaultColor = function()
			local color = datapanel.defaultValue(control.default)
			return color.r or 1, color.g or 1, color.b or 1, color.a or 1
		end,
		hasOpacity = control.hasOpacity,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
		refreshOnChange = control.refreshOnChange,
		order = order,
	})
end

function datapanel.createReorderList(section, stream, control, order)
	return addon.functions.SettingsCreateReorderList(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. (control.key or control.id or "list"),
		text = control.text,
		desc = control.desc,
		getEntries = control.getEntries,
		addEntry = control.addEntry,
		removeEntry = control.removeEntry,
		moveEntry = control.moveEntry,
		setEntryFormat = control.setEntryFormat,
		formatOptions = control.formatOptions,
		formatOrder = control.formatOrder,
		addPopupTitle = control.addPopupTitle,
		addPopupText = control.addPopupText,
		addButtonText = control.addButtonText,
		emptyText = control.emptyText,
		numeric = control.numeric,
		maxChars = control.maxChars,
		rowHeight = control.rowHeight,
		refreshOnChange = control.refreshOnChange,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		order = order,
	})
end

function datapanel.createMultiDropdown(section, stream, control, order)
	return addon.functions.SettingsCreateMultiDropdown(cDataPanel, {
		var = "DataPanel_" .. stream.dbKey .. "_" .. control.key,
		text = control.text,
		desc = control.desc,
		options = control.options,
		list = control.list,
		optionfunc = control.optionfunc,
		listFunc = control.listFunc,
		orderList = control.orderList or control.listOrder,
		order = control.order or order,
		menuHeight = control.menuHeight,
		customDefaultText = control.customDefaultText,
		isSelectedFunc = control.isSelectedFunc,
		setSelectedFunc = control.setSelectedFunc,
		getSelection = control.getSelection,
		setSelection = control.setSelection,
		storage = control.storage,
		refreshOnChange = control.refreshOnChange,
		parentSection = section,
		groupID = stream.groupID,
		groupTitle = dataPanelGroupTitle,
		parentCheck = control.parentCheck,
		isEnabled = control.isEnabled,
	})
end

function datapanel.createControl(section, stream, control, order)
	if control.type == "slider" then
		return datapanel.createSlider(section, stream, control, order)
	elseif control.type == "dropdown" then
		return datapanel.createDropdown(section, stream, control, order)
	elseif control.type == "multidropdown" then
		return datapanel.createMultiDropdown(section, stream, control, order)
	elseif control.type == "input" then
		return datapanel.createInput(section, stream, control, order)
	elseif control.type == "color" then
		return datapanel.createColor(section, stream, control, order)
	elseif control.type == "sectionheader" then
		return addon.functions.SettingsCreateSectionHeader(cDataPanel, control.text, {
			parentSection = section,
			groupID = stream.groupID,
			groupTitle = dataPanelGroupTitle,
			order = control.order or order,
		})
	elseif control.type == "reorderlist" then
		return datapanel.createReorderList(section, stream, control, order)
	else
		return datapanel.createCheckbox(section, stream, control, order)
	end
end

function datapanel.createStreamSection(stream, order)
	stream.groupID = dataPanelGroupID
	addon.functions.SettingsCreateSectionHeader(cDataPanel, stream.title, {
		parentSection = expandable,
		groupID = dataPanelGroupID,
		groupTitle = dataPanelGroupTitle,
		order = order,
	})
	for index, control in ipairs(stream.controls or {}) do
		datapanel.createControl(expandable, stream, control, order + (index * 10))
	end
end

datapanel.fontSlider = { type = "slider", key = "fontSize", text = FONT_SIZE, min = 8, max = 32, step = 1, default = 14 }
datapanel.textColor = { type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor }
datapanel.useTextColor = { key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false }
datapanel.hideIcon = { key = "hideIcon", text = L["Hide icon"] or "Hide icon", default = false }
datapanel.showIcon = { key = "showIcon", text = L["Show icon"] or "Show icon", default = true }
datapanel.allianceColor = function() return { r = 0.345, g = 0.702, b = 1, a = 1 } end
datapanel.hordeColor = function() return { r = 1, g = 0.267, b = 0.267, a = 1 } end

datapanel.streams = {
	{
		id = "gold",
		dbKey = "gold",
		title = WORLD_QUEST_REWARD_FILTERS_GOLD,
		defaults = { fontSize = 14, displayMode = "character", leftClickAction = "toggleDisplay", showSilverCopper = false, useTextColor = false, textColor = datapanel.normalColor },
		controls = {
			datapanel.fontSlider,
			{ type = "dropdown", key = "displayMode", text = L["goldPanelDisplay"] or "Gold display", list = { character = CHARACTER, warband = L["warbandGold"] or "Warband gold" }, default = "character", normalize = function(value) return value == "warband" and "warband" or "character" end },
			{ type = "dropdown", key = "leftClickAction", text = L["Left-click action"] or "Left-click action", list = { toggleDisplay = L["goldPanelLeftClickToggleDisplay"] or "Toggle gold display", openBags = L["goldPanelLeftClickOpenBags"] or "Open bags" }, default = "toggleDisplay", normalize = function(value) return value == "openBags" and "openBags" or "toggleDisplay" end },
			{ key = "showSilverCopper", text = L["goldPanelShowSilverCopper"] or "Show silver and copper", default = false },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isGoldCustomColorEnabled },
		},
	},
	{
		id = "time",
		dbKey = "time",
		title = L["Time"] or "Time",
		defaults = { fontSize = 14, displayMode = "server", use24Hour = true, showSeconds = false, leftClickAction = "clock", useClassColor = false, timeColor = datapanel.normalColor, showLockouts = true },
		controls = {
			datapanel.fontSlider,
			{ type = "dropdown", key = "displayMode", text = L["Time display"] or "Time display", list = { server = L["Server time"] or "Server time", localTime = L["Local time"] or "Local time", both = L["Server + Local"] or "Server + Local" }, default = "server" },
			{ key = "use24Hour", text = L["24-hour format"] or "24-hour format", default = true },
			{ key = "showSeconds", text = L["Show seconds"] or "Show seconds", default = false },
			{ type = "dropdown", key = "leftClickAction", text = L["Left-click action"] or "Left-click action", list = { clock = L["Time left-click opens stopwatch"] or "Open stopwatch", calendar = L["Time left-click opens calendar"] or "Open calendar" }, default = "clock", normalize = function(value) return value == "calendar" and "calendar" or "clock" end },
			{ key = "useClassColor", text = L["timeUseClassColor"] or "Use class color", default = false, normalize = datapanel.normalizeTimeClassColor, refreshOnChange = true },
			{ type = "color", key = "timeColor", text = L["Time color"] or "Time color", default = datapanel.normalColor, isEnabled = datapanel.isTimeCustomColorEnabled },
			{ key = "showLockouts", text = L["timeShowLockouts"] or "Show saved instances in tooltip", default = true },
		},
	},
	{
		id = "bagspace",
		dbKey = "bagspace",
		title = L["Bag Space"] or "Bag Space",
		defaults = { fontSize = 14, displayMode = "freeMax", ignoreComponentsBag = false, hideIcon = false, textColor = datapanel.normalColor },
		controls = {
			datapanel.fontSlider,
			{ type = "dropdown", key = "displayMode", text = L["bagSpaceDisplay"] or "Bag space display", list = { freeMax = L["bagSpaceDisplayFreeMax"] or "Free/Max", currentMax = L["Current/Max"] or "Current/Max", free = L["bagSpaceDisplayFree"] or "Free" }, default = "freeMax" },
			{ key = "ignoreComponentsBag", text = L["bagSpaceIgnoreComponentsBag"] or "Ignore components bag", default = false },
			datapanel.hideIcon,
			datapanel.textColor,
		},
	},
	{
		id = "coordinates",
		dbKey = "coordinates",
		title = L["Coordinates"] or "Coordinates",
		defaults = { fontSize = 14, updateInterval = 0.2, decimals = 2, hideInInstance = true },
		controls = {
			datapanel.fontSlider,
			{ type = "slider", key = "updateInterval", text = L["Coordinates update interval (s)"] or "Coordinates update interval (s)", min = 0.1, max = 1, step = 0.05, default = 0.2 },
			{ type = "slider", key = "decimals", text = L["squareMinimapStatsCoordinatesDecimals"] or "Precision (decimals)", min = 0, max = 2, step = 1, default = 2, normalize = function(value) return math.max(0, math.min(2, math.floor((tonumber(value) or 2) + 0.5))) end },
			{ key = "hideInInstance", text = L["Hide coordinates in instances"] or "Hide coordinates in instances", default = true },
		},
	},
	{
		id = "combat_time",
		dbKey = "combatTime",
		title = L["Combat time"] or "Combat time",
		defaults = { fontSize = 14, showBoss = true, showLabels = true, stack = false, bossOnTop = false },
		controls = {
			datapanel.fontSlider,
			{ key = "showBoss", text = L["combatTimeShowBoss"] or "Show boss timer", default = true },
			{ key = "showLabels", text = L["combatTimeShowLabels"] or "Show labels", default = true },
			{ key = "stack", text = L["combatTimeStacked"] or "Stack timers", default = false },
			{ key = "bossOnTop", text = L["combatTimeBossOnTop"] or "Boss timer on top", default = false },
		},
	},
	{
		id = "difficulty",
		dbKey = "difficulty",
		title = LFG_LIST_DIFFICULTY,
		defaults = { fontSize = 14 },
		controls = { datapanel.fontSlider },
	},
	{
		id = "durability",
		dbKey = "durability",
		title = DURABILITY,
		defaults = { fontSize = 13, showIcon = true, showCritical = true, useTextColor = false, textColor = datapanel.normalColor, highColor = { r = 0, g = 1, b = 0, a = 1 }, midColor = { r = 1, g = 1, b = 0, a = 1 }, lowColor = { r = 1, g = 0, b = 0, a = 1 } },
		controls = {
			{ type = "slider", key = "fontSize", text = FONT_SIZE, min = 8, max = 32, step = 1, default = 13 },
			datapanel.showIcon,
			{ key = "showCritical", text = L["durabilityShowCritical"] or "Show critical warning", default = true },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isDurabilityCustomColorEnabled },
			{ type = "color", key = "highColor", text = L["durabilityHighColor"] or "High durability color", default = { r = 0, g = 1, b = 0, a = 1 }, isEnabled = datapanel.isDurabilityCustomColorEnabled },
			{ type = "color", key = "midColor", text = L["durabilityMidColor"] or "Medium durability color", default = { r = 1, g = 1, b = 0, a = 1 }, isEnabled = datapanel.isDurabilityCustomColorEnabled },
			{ type = "color", key = "lowColor", text = L["durabilityLowColor"] or "Low durability color", default = { r = 1, g = 0, b = 0, a = 1 }, isEnabled = datapanel.isDurabilityCustomColorEnabled },
		},
	},
	{
		id = "itemlevel",
		dbKey = "itemlevel",
		title = ITEM_UPGRADE_STAT_AVERAGE_ITEM_LEVEL,
		defaults = { fontSize = 14, showAverage = true },
		controls = { datapanel.fontSlider, { key = "showAverage", text = L["itemLevelShowAverage"] or "Show average item level", default = true } },
	},
	{
		id = "realm",
		dbKey = "realm",
		title = L["Realm"] or "Realm",
		defaults = { fontSize = 14, textColor = datapanel.normalColor },
		controls = { datapanel.fontSlider, datapanel.textColor },
	},
	{
		id = "playername",
		dbKey = "playername",
		title = (PLAYER or "Player") .. " " .. (NAME or "Name"),
		defaults = { fontSize = 14, showRealm = false, useClassColor = true, useFactionColor = false, useTextColor = false, textColor = datapanel.normalColor, allianceColor = datapanel.allianceColor, hordeColor = datapanel.hordeColor, separateRealmColor = false, realmUseClassColor = false, realmUseFactionColor = true, realmUseTextColor = false, realmTextColor = datapanel.normalColor },
		controls = {
			datapanel.fontSlider,
			{ key = "showRealm", text = (SHOW or "Show") .. " " .. (L["Realm"] or "Realm"), default = false, refreshOnChange = true },
			{ key = "useClassColor", text = L["Use class color"] or "Use class color", default = true, normalize = datapanel.normalizePlayerNameClassColor, refreshOnChange = true },
			{ key = "useFactionColor", text = L["DataPanelUseFactionTextColor"] or "Use faction text color", default = false, normalize = datapanel.normalizePlayerNameFactionColor, refreshOnChange = true },
			{ type = "color", key = "allianceColor", text = L["DataPanelAllianceTextColor"] or "Alliance text color", default = datapanel.allianceColor, isEnabled = datapanel.isPlayerNameFactionColorEnabled },
			{ type = "color", key = "hordeColor", text = L["DataPanelHordeTextColor"] or "Horde text color", default = datapanel.hordeColor, isEnabled = datapanel.isPlayerNameFactionColorEnabled },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, normalize = datapanel.normalizePlayerNameCustomColor, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isPlayerNameCustomColorEnabled },
			{ key = "separateRealmColor", text = L["DataPanelPlayerNameSeparateRealmColor"] or "Color realm separately", default = false, refreshOnChange = true },
			{ key = "realmUseClassColor", text = (L["Realm"] or "Realm") .. " - " .. (L["Use class color"] or "Use class color"), default = false, normalize = datapanel.normalizePlayerNameRealmClassColor, refreshOnChange = true, isEnabled = datapanel.isPlayerNameSeparateRealmColorEnabled },
			{ key = "realmUseFactionColor", text = (L["Realm"] or "Realm") .. " - " .. (L["DataPanelUseFactionTextColor"] or "Use faction text color"), default = true, normalize = datapanel.normalizePlayerNameRealmFactionColor, refreshOnChange = true, isEnabled = datapanel.isPlayerNameSeparateRealmColorEnabled },
			{ key = "realmUseTextColor", text = (L["Realm"] or "Realm") .. " - " .. (L["Use custom text color"] or "Use custom text color"), default = false, normalize = datapanel.normalizePlayerNameRealmCustomColor, refreshOnChange = true, isEnabled = datapanel.isPlayerNameSeparateRealmColorEnabled },
			{ type = "color", key = "realmTextColor", text = L["DataPanelRealmTextColor"] or "Realm text color", default = datapanel.normalColor, isEnabled = datapanel.isPlayerNameRealmCustomColorEnabled },
		},
	},
	{
		id = "volume",
		dbKey = "volume",
		title = MASTER_VOLUME or "Master Volume",
		defaults = { fontSize = 14, step = 0.05, activeStream = "master", iconOnly = false, useTextColor = false, textColor = datapanel.normalColor },
		controls = {
			datapanel.fontSlider,
			{ key = "iconOnly", text = L["volumeIconOnly"] or "Icon only", default = false },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isVolumeCustomColorEnabled },
		},
	},
	{
		id = "location",
		dbKey = "location",
		title = L["Location"] or "Location",
		defaults = { fontSize = 14, showSubzone = true, useZoneColor = true },
		controls = { datapanel.fontSlider, { key = "showSubzone", text = L["locationShowSubzone"] or "Show subzone", default = true }, { key = "useZoneColor", text = L["locationUseZoneColor"] or "Use zone color", default = true } },
	},
	{
		id = "hearthstone",
		dbKey = "hearthstone",
		title = L["Hearthstone"] or "Hearthstone",
		defaults = { fontSize = 14, hideIcon = false, textColor = datapanel.normalColor },
		controls = { datapanel.fontSlider, datapanel.hideIcon, datapanel.textColor },
	},
	{
		id = "equipmentsets",
		dbKey = "equipmentsets",
		title = L["Equipment Sets"] or "Equipment Sets",
		defaults = { fontSize = 14, useClassColor = true, useTextColor = false, textColor = datapanel.normalColor },
		controls = {
			datapanel.fontSlider,
			{ key = "useClassColor", text = L["Use class color"] or "Use class color", default = true, normalize = datapanel.normalizeEquipmentSetsClassColor, refreshOnChange = true },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, normalize = datapanel.normalizeEquipmentSetsCustomColor, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isEquipmentSetsCustomColorEnabled },
		},
	},
	{
		id = "lootspec",
		dbKey = "lootspec",
		title = SELECT_LOOT_SPECIALIZATION or LOOT_SPECIALIZATION or "Loot Specialization",
		defaults = { prefix = "", fontSize = 14, hidePrefix = false, hideIcon = false, truncateSpecName = false },
		controls = { { type = "input", key = "prefix", text = L["Prefix"] or "Prefix", default = "" }, { key = "hidePrefix", text = L["Hide prefix"] or "Hide prefix", default = false }, datapanel.fontSlider, datapanel.hideIcon, { key = "truncateSpecName", text = L["Truncate loot spec"] or "Truncate loot spec", default = false } },
	},
	{
		id = "mythickey",
		dbKey = "mythickey",
		title = L["Mythic+ Key"] or "Mythic+ Key",
		defaults = { prefix = "", fontSize = 14, hideIcon = false },
		controls = { { type = "input", key = "prefix", text = L["Prefix"] or "Prefix", default = "" }, datapanel.fontSlider, datapanel.hideIcon },
	},
	{
		id = "mythicrating",
		dbKey = "mythicrating",
		title = L["Mythic+ Rating"] or "Mythic+ Rating",
		defaults = { fontSize = 14 },
		controls = { datapanel.fontSlider },
	},
	{
		id = "friends",
		dbKey = "friends",
		title = FRIENDS,
		defaults = { fontSize = 13, useClassColor = false, useTextColor = false, textColor = datapanel.whiteColor, splitDisplay = false, splitDisplayInline = false },
		controls = {
			{ type = "slider", key = "fontSize", text = FONT_SIZE, min = 8, max = 32, step = 1, default = 13 },
			{ key = "useClassColor", text = L["DataPanelUseClassTextColor"] or "Use class text color", default = false, normalize = datapanel.normalizeFriendsClassColor, refreshOnChange = true },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, normalize = datapanel.normalizeFriendsCustomColor, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.whiteColor, isEnabled = datapanel.isFriendsCustomColorEnabled },
			{ key = "splitDisplay", text = L["Friends/Guild display"] or "Show friends + guild", default = false, refreshOnChange = true },
			{ key = "splitDisplayInline", text = L["Friends/Guild display single line"] or "Single-line layout", default = false, isEnabled = datapanel.isFriendsSplitDisplayEnabled },
		},
	},
	{
		id = "currency",
		dbKey = "currency",
		title = CURRENCY,
		defaults = { fontSize = 14, tooltipPerCurrency = true, showDescription = false, includeBlizzardTracked = false, useTextColor = false, textColor = datapanel.normalColor, ids = {}, currencyOptions = {} },
		controls = {
			datapanel.fontSlider,
			{ key = "tooltipPerCurrency", text = L["Per-currency tooltips"] or "Per-currency tooltips", default = true },
			{ key = "showDescription", text = L["Show description in tooltip"] or "Show description in tooltip", default = false },
			{ key = "includeBlizzardTracked", text = L["dataPanelCurrencyIncludeBlizzardTracked"] or "Include Blizzard tracked currencies", default = false, normalize = datapanel.normalizeCurrencyTracked },
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isCurrencyCustomColorEnabled },
			{ type = "reorderlist", key = "currencies", text = L["settingsTrackedCurrencies"] or "Tracked currencies", desc = L["settingsTrackedCurrenciesHint"] or "", getEntries = datapanel.getCurrencyEntries, addEntry = datapanel.addCurrencyEntry, removeEntry = datapanel.removeCurrencyEntry, moveEntry = datapanel.moveCurrencyEntry, setEntryFormat = datapanel.setCurrencyFormat, formatOptions = datapanel.currencyFormatOptions, formatOrder = datapanel.currencyFormatOrder, addPopupTitle = L["settingsTrackedCurrencyAddPlaceholder"] or "Currency ID", addPopupText = L["settingsTrackedCurrencyAddPlaceholder"] or "Currency ID", addButtonText = ADD, emptyText = L["settingsTrackedCurrenciesEmpty"] or "No tracked currencies yet.", numeric = true, maxChars = 7, refreshOnChange = true },
		},
	},
	{
		id = "talent",
		dbKey = "talent",
		title = TALENTS,
		defaults = { prefix = (TALENTS or "Talents") .. ":", fontSize = 14, hideIcon = false, useTextColor = false, usePrefixColor = false, textColor = datapanel.whiteColor, prefixColor = { r = 0.75, g = 0.75, b = 0.75, a = 1 } },
		controls = {
			{ type = "input", key = "prefix", text = L["Prefix"] or "Prefix", default = (TALENTS or "Talents") .. ":" },
			datapanel.fontSlider,
			datapanel.hideIcon,
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.whiteColor, isEnabled = datapanel.isTalentCustomColorEnabled },
			{ key = "usePrefixColor", text = L["Talent use prefix color"] or "Use custom prefix color", default = false, refreshOnChange = true },
			{ type = "color", key = "prefixColor", text = L["Talent prefix color"] or "Prefix color", default = { r = 0.75, g = 0.75, b = 0.75, a = 1 }, isEnabled = datapanel.isTalentPrefixCustomColorEnabled },
		},
	},
	{
		id = "pettracker",
		dbKey = "pettracker",
		title = L["Pet Tracker"] or "Pet Tracker",
		defaults = { fontSize = 14, textColor = datapanel.normalColor, showIcon = true, hideWhileRested = false, layoutMode = "inline", blinkEnabled = false, blinkRate = 0.7 },
		controls = {
			{ type = "slider", key = "fontSize", text = FONT_SIZE, min = 8, max = 120, step = 1, default = 14 },
			datapanel.textColor,
			{ key = "showIcon", text = L["Show icon"] or "Show icon", default = true, refreshOnChange = true },
			{ type = "dropdown", key = "layoutMode", text = L["petTrackerLayout"] or "Reminder layout", list = { inline = L["petTrackerLayoutInline"] or "Icon left of text", textAbove = L["petTrackerLayoutTextAbove"] or "Text above icon", textBelow = L["petTrackerLayoutTextBelow"] or "Text below icon" }, default = "inline", normalize = function(value) return (value == "textAbove" or value == "textBelow") and value or "inline" end, isEnabled = datapanel.isPetTrackerIconShown },
			{ key = "hideWhileRested", text = L["petTrackerHideWhileRested"] or "Hide while rested", default = false },
			{ key = "ignorePetPassive", text = L["ClassBuffReminderIgnorePetPassive"] or "Ignore passive pet stance", default = false, get = datapanel.isClassBuffPetPassiveIgnored, set = datapanel.setClassBuffPetPassiveIgnored },
			{ key = "ignorePetDefensive", text = L["ClassBuffReminderIgnorePetDefensive"] or "Ignore defensive pet stance", default = false, get = datapanel.isClassBuffPetDefensiveIgnored, set = datapanel.setClassBuffPetDefensiveIgnored },
			{ key = "blinkEnabled", text = L["Blink"] or "Blink", default = false, refreshOnChange = true, normalize = datapanel.resetPetTrackerBlink },
			{ type = "slider", key = "blinkRate", text = L["Blink rate (s)"] or "Blink rate (s)", min = 0.2, max = 2, step = 0.05, default = 0.7, isEnabled = datapanel.isPetTrackerBlinkEnabled, normalize = datapanel.resetPetTrackerBlink },
		},
	},
	{
		id = "latency",
		dbKey = "latency",
		title = L["Latency"] or "Latency",
		defaults = { fontSize = 14, displayMode = "both", useTextColor = false, textColor = datapanel.normalColor, fpsInterval = 0.25, pingInterval = 1, fpsSmoothWindow = 0.75, pingMode = "max", showCpuTooltip = true, cpuTooltipEntries = 8, pingThresholdLow = 50, pingThresholdMid = 150, pingColorLow = { r = 0, g = 1, b = 0, a = 1 }, pingColorMid = { r = 1, g = 0.65, b = 0, a = 1 }, pingColorHigh = { r = 1, g = 0, b = 0, a = 1 } },
		controls = {
			datapanel.fontSlider,
			{ key = "useTextColor", text = L["Use custom text color"] or "Use custom text color", default = false, refreshOnChange = true },
			{ type = "color", key = "textColor", text = L["Text color"] or "Text color", default = datapanel.normalColor, isEnabled = datapanel.isLatencyCustomColorEnabled },
			{ type = "dropdown", key = "displayMode", text = L["latencyPanelDisplay"] or "Panel display", list = { both = L["latencyPanelDisplayBoth"] or "FPS + Latency", ping = L["latencyPanelDisplayPing"] or "Latency only", fps = L["latencyPanelDisplayFPS"] or "FPS only" }, default = "both" },
			{ key = "showCpuTooltip", text = L["latencyShowCpuTooltip"] or "Show AddOn CPU usage in tooltip", default = true },
			{ type = "slider", key = "cpuTooltipEntries", text = L["latencyCpuTooltipEntries"] or "AddOn tooltip entries", min = 1, max = 20, step = 1, default = 8 },
			{ type = "slider", key = "fpsInterval", text = L["FPS update interval (s)"] or "FPS update interval (s)", min = 0.1, max = 1, step = 0.05, default = 0.25 },
			{ type = "slider", key = "fpsSmoothWindow", text = L["FPS smoothing window (s)"] or "FPS smoothing window (s)", min = 0, max = 1.5, step = 0.05, default = 0.75 },
			{ type = "slider", key = "pingInterval", text = L["Ping update interval (s)"] or "Ping update interval (s)", min = 0.5, max = 3, step = 0.25, default = 1 },
			{ type = "dropdown", key = "pingMode", text = L["Ping display"] or "Ping display", list = { max = L["Max(home, world)"] or "Max(home, world)", split = L["Home + World"] or "Home + World", split_vertical = L["Home + World (vertical)"] or "Home + World (vertical)", home = _G["HOME"] or "Home", world = _G["WORLD"] or "World" }, default = "max" },
			{ type = "slider", key = "pingThresholdLow", text = L["Low threshold (ms)"] or "Low threshold (ms)", min = 0, max = 1000, step = 1, default = 50, normalize = function(value, db) value = math.floor((tonumber(value) or 50) + 0.5); if db.pingThresholdMid and db.pingThresholdMid < value then db.pingThresholdMid = value end; return value end },
			{ type = "slider", key = "pingThresholdMid", text = L["latencyPingMidThreshold"] or "Mid threshold (ms)", min = 0, max = 1000, step = 1, default = 150, normalize = function(value, db) value = math.floor((tonumber(value) or 150) + 0.5); if db.pingThresholdLow and db.pingThresholdLow > value then db.pingThresholdLow = value end; return value end },
			{ type = "color", key = "pingColorLow", text = L["latencyPingLowColor"] or "Low ping color", default = { r = 0, g = 1, b = 0, a = 1 } },
			{ type = "color", key = "pingColorMid", text = L["latencyPingMidColor"] or "Mid ping color", default = { r = 1, g = 0.65, b = 0, a = 1 } },
			{ type = "color", key = "pingColorHigh", text = L["latencyPingHighColor"] or "High ping color", default = { r = 1, g = 0, b = 0, a = 1 } },
		},
	},
	{
		id = "microbar",
		dbKey = "microbar",
		title = L["Micro Bar"] or "Micro Bar",
		defaults = datapanel.microBarDefaults,
		controls = {
			{ type = "dropdown", key = "displayMode", text = DISPLAY_MODE, list = { menu = L["MicroBarDisplayModeMenu"] or "Show as menu", inline = L["MicroBarDisplayModeInline"] or "Show icons in DataPanel" }, default = "menu", normalize = function(value) return value == "inline" and "inline" or "menu" end },
			{ type = "slider", key = "iconSize", text = L["Icon size"] or "Icon size", min = 10, max = 60, step = 1, default = 14, normalize = function(value) return math.max(10, math.min(60, math.floor((tonumber(value) or 14) + 0.5))) end },
			{ type = "slider", key = "iconGap", text = L["Icon gap"] or "Icon gap", min = 0, max = 16, step = 1, default = 5, normalize = function(value) return math.max(0, math.min(16, math.floor((tonumber(value) or 5) + 0.5))) end },
			{ key = "equalButtonSize", text = L["MicroBarEqualButtons"] or "Use equal button size", default = false, refreshOnChange = true },
			{ key = "buttonBackdrop", text = L["MicroBarButtonBackdrop"] or "Show button backdrop", default = false, refreshOnChange = true },
			{ key = "buttonBorder", text = L["Show button border"] or "Show button border", default = true, refreshOnChange = true },
			{ type = "color", key = "buttonBorderColor", text = L["MicroBarButtonBorderColor"] or "Button border color", default = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 }, hasOpacity = true, isEnabled = datapanel.isMicroBarButtonBorderEnabled },
			{ type = "slider", key = "buttonSize", text = L["MicroBarButtonSize"] or "Button size", min = 14, max = 40, step = 1, default = 20, normalize = function(value) return math.max(14, math.min(40, math.floor((tonumber(value) or 20) + 0.5))) end, isEnabled = datapanel.isMicroBarButtonSizingEnabled },
			{ type = "multidropdown", key = "visibleIcons", text = L["MicroBarVisibleEntries"] or "Visible icons", listFunc = datapanel.getMicroBarVisibleIconOptions, storage = false, isSelectedFunc = datapanel.isMicroBarIconVisible, setSelectedFunc = datapanel.setMicroBarIconVisible, customDefaultText = NONE or "None", menuHeight = 320 },
		},
	},
	{
		id = "stats",
		dbKey = "stats",
		title = PET_BATTLE_STATS_LABEL,
		defaults = { fontSize = 14, vertical = false },
		controls = datapanel.createStatsControls(),
	},
	{
		id = "mail",
		dbKey = "mail",
		title = L["Mail"] or "Mail",
		defaults = { fontSize = 14 },
		controls = { datapanel.fontSlider },
	},
	{
		id = "markbar_target",
		dbKey = "markbar",
		groupKey = "markbar_target",
		updateID = "markbar",
		title = L["MarkBarTargets"] or "Mark Bar: Target Icons",
		defaults = datapanel.markBarDefaults,
		controls = {
			{ key = "showTargets", text = SHOW or L["MarkBarTargets"] or "Mark Bar: Target Icons", default = true },
			{ type = "slider", key = "iconSize", text = L["Icon size"] or "Icon size", min = 10, max = 18, step = 1, default = 14, normalize = function(value) return math.max(10, math.min(18, math.floor((tonumber(value) or 14) + 0.5))) end },
		},
	},
	{
		id = "markbar_world",
		dbKey = "markbar",
		groupKey = "markbar_world",
		updateID = "markbar",
		title = L["MarkBarWorld"] or "Mark Bar: World Markers",
		defaults = datapanel.markBarDefaults,
		controls = { { key = "showWorld", text = SHOW or L["MarkBarWorld"] or "Mark Bar: World Markers", default = true } },
	},
	{
		id = "markbar_util",
		dbKey = "markbar",
		groupKey = "markbar_util",
		updateID = "markbar",
		title = L["MarkBarUtility"] or "Mark Bar: Pings + Checks",
		defaults = datapanel.markBarDefaults,
		controls = { { key = "showUtility", text = SHOW or L["MarkBarUtility"] or "Mark Bar: Pings + Checks", default = true } },
	},
}

table.sort(datapanel.streams, function(left, right)
	local leftTitle = tostring(left.title or left.dbKey or "")
	local rightTitle = tostring(right.title or right.dbKey or "")
	if leftTitle ~= rightTitle then return leftTitle < rightTitle end
	return tostring(left.dbKey or "") < tostring(right.dbKey or "")
end)

for index, stream in ipairs(datapanel.streams) do
	datapanel.createStreamSection(stream, 1000 + (index * 100))
end
----- REGION END

function addon.functions.initDataPanel()
	StaticPopupDialogs["EQOL_CREATE_DATAPANEL"] = StaticPopupDialogs["EQOL_CREATE_DATAPANEL"]
		or {
			text = L["Panel Name"],
			hasEditBox = true,
			button1 = YES,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self, data)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if editBox then
					editBox:SetText(data or "")
					editBox:SetFocus()
					editBox:HighlightText()
				end
			end,
			OnAccept = function(self)
				local id = self:GetEditBox():GetText()
				if id and id ~= "" then addon.DataPanel.Create(id) end
			end,
		}
end

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
