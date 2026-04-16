local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Reminder = addon.ClassBuffReminder

local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not (cat and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end

local DB_ENABLED = "classBuffReminderEnabled"
local DB_SHOW_PARTY = "classBuffReminderShowParty"
local DB_SHOW_RAID = "classBuffReminderShowRaid"
local DB_SHOW_SOLO = "classBuffReminderShowSolo"
local DB_HIDE_IN_RESTED_AREA = "classBuffReminderHideInRestedArea"
local DB_ONLY_OUT_OF_COMBAT = "classBuffReminderOnlyOutOfCombat"
local DB_ROLE_FILTER_ENABLED = "classBuffReminderRoleFilterEnabled"
local DB_ROLE_FILTER_CONTEXT = "classBuffReminderRoleFilterContext"
local DB_HIDE_FOR_HEALER = "classBuffReminderHideForHealer"
local DB_HIDE_FOR_TANK = "classBuffReminderHideForTank"
local DB_HIDE_FOR_DAMAGER = "classBuffReminderHideForDamager"
local DB_HIDE_FOR_NONE = "classBuffReminderHideForNoRole"
local DB_SHOW_IF_ONLY_PROVIDER = "classBuffReminderShowIfOnlyProvider"
local DB_GLOW = "classBuffReminderGlow"
local DB_GLOW_STYLE = "classBuffReminderGlowStyle"
local DB_GLOW_INSET = "classBuffReminderGlowInset"
local DB_GLOW_COLOR = "classBuffReminderGlowColor"
local DB_SOUND_ON_MISSING = "classBuffReminderSoundOnMissing"
local DB_MISSING_SOUND = "classBuffReminderMissingSound"
local DB_DISPLAY_MODE = "classBuffReminderDisplayMode"
local DB_GROWTH_DIRECTION = "classBuffReminderGrowthDirection"
local DB_GROWTH_FROM_CENTER = "classBuffReminderGrowthFromCenter"
local DB_TRACK_FLASKS = "classBuffReminderTrackFlasks"
local DB_TRACK_FLASKS_CONTENT = "classBuffReminderTrackFlasksContent"
local DB_TRACK_FLASKS_INSTANCE_ONLY = "classBuffReminderTrackFlasksInstanceOnly"
local DB_TRACK_FOOD = "classBuffReminderTrackFood"
local DB_TRACK_FOOD_CONTENT = "classBuffReminderTrackFoodContent"
local DB_TRACK_FOOD_INSTANCE_ONLY = "classBuffReminderTrackFoodInstanceOnly"
local DB_TRACK_WEAPON_BUFFS = "classBuffReminderTrackWeaponBuffs"
local DB_TRACK_WEAPON_BUFFS_CONTENT = "classBuffReminderTrackWeaponBuffsContent"
local DB_TRACK_WEAPON_BUFFS_INSTANCE_ONLY = "classBuffReminderTrackWeaponBuffsInstanceOnly"
local DB_SCALE = "classBuffReminderScale"
local DB_ICON_SIZE = "classBuffReminderIconSize"
local DB_FONT_SIZE = "classBuffReminderFontSize"
local DB_ICON_GAP = "classBuffReminderIconGap"
local DB_BORDER_ENABLED = "classBuffReminderBorderEnabled"
local DB_BORDER_TEXTURE = "classBuffReminderBorderTexture"
local DB_BORDER_SIZE = "classBuffReminderBorderSize"
local DB_BORDER_OFFSET = "classBuffReminderBorderOffset"
local DB_BORDER_COLOR = "classBuffReminderBorderColor"
local DB_XY_TEXT_SIZE = "classBuffReminderXYTextSize"
local DB_XY_TEXT_OUTLINE = "classBuffReminderXYTextOutline"
local DB_XY_TEXT_COLOR = "classBuffReminderXYTextColor"
local DB_XY_TEXT_OFFSET_X = "classBuffReminderXYTextOffsetX"
local DB_XY_TEXT_OFFSET_Y = "classBuffReminderXYTextOffsetY"
local LEGACY_DB_SOUND_DEBUG_TRACE = "classBuffReminderSoundDebugTrace"
local LEGACY_DB_SHOW_ICON = "classBuffReminderShowIcon"
local LEGACY_DB_ONLY_WHEN_MISSING = "classBuffReminderOnlyWhenMissing"

local function createDefaultTrackingContentSelection()
	if Reminder and Reminder.CreateDefaultTrackingContentSelection then return Reminder.CreateDefaultTrackingContentSelection() end
	return {
		partyMythic = true,
		raidNormal = true,
		raidHeroic = true,
		raidMythic = true,
	}
end

local function copySelection(selection)
	local copy = {}
	if type(selection) ~= "table" then return copy end
	for key, selected in pairs(selection) do
		if selected == true then copy[key] = true end
	end
	return copy
end

local defaults = (Reminder and Reminder.defaults)
	or {
		enabled = false,
		showParty = true,
		showRaid = true,
		showSolo = false,
		hideInRestedArea = false,
		onlyOutOfCombat = false,
		roleFilterEnabled = false,
		roleFilterContext = "RAID_ONLY",
		hideForHealer = false,
		hideForTank = false,
		hideForDamager = false,
		hideForNoRole = false,
		showIfOnlyProvider = true,
		glow = true,
		glowStyle = "MARCHING_ANTS",
		glowInset = 0,
		glowColor = { r = 0.95, g = 0.95, b = 0.2, a = 1 },
		soundOnMissing = false,
		missingSound = "",
		displayMode = "ICON_ONLY",
		growthDirection = "RIGHT",
		growthFromCenter = false,
		trackFlasks = false,
		trackFlasksContent = createDefaultTrackingContentSelection(),
		trackFlasksInstanceOnly = false,
		trackFood = false,
		trackFoodContent = createDefaultTrackingContentSelection(),
		trackFoodInstanceOnly = false,
		trackWeaponBuffs = false,
		trackWeaponBuffsContent = createDefaultTrackingContentSelection(),
		trackWeaponBuffsInstanceOnly = false,
		scale = 1,
		iconSize = 64,
		fontSize = 13,
		iconGap = 6,
		borderEnabled = false,
		borderTexture = "DEFAULT",
		borderSize = 1,
		borderOffset = 0,
		borderColor = { r = 1, g = 1, b = 1, a = 1 },
		xyTextSize = 13,
		xyTextOutline = "OUTLINE",
		xyTextColor = { r = 1, g = 1, b = 1, a = 1 },
		xyTextOffsetX = 0,
		xyTextOffsetY = 0,
	}
if defaults.glowStyle == nil then defaults.glowStyle = "MARCHING_ANTS" end
if defaults.glowInset == nil then defaults.glowInset = 0 end
if type(defaults.glowColor) ~= "table" then defaults.glowColor = { r = 0.95, g = 0.95, b = 0.2, a = 1 } end
if defaults.hideInRestedArea == nil then defaults.hideInRestedArea = false end
if defaults.onlyOutOfCombat == nil then defaults.onlyOutOfCombat = false end
if defaults.roleFilterEnabled == nil then defaults.roleFilterEnabled = false end
if defaults.roleFilterContext == nil then defaults.roleFilterContext = "RAID_ONLY" end
if defaults.hideForHealer == nil then defaults.hideForHealer = false end
if defaults.hideForTank == nil then defaults.hideForTank = false end
if defaults.hideForDamager == nil then defaults.hideForDamager = false end
if defaults.hideForNoRole == nil then defaults.hideForNoRole = false end
if defaults.showIfOnlyProvider == nil then defaults.showIfOnlyProvider = true end
if defaults.trackFlasks == nil then defaults.trackFlasks = false end
if type(defaults.trackFlasksContent) ~= "table" then defaults.trackFlasksContent = createDefaultTrackingContentSelection() end
if defaults.trackFood == nil then defaults.trackFood = false end
if type(defaults.trackFoodContent) ~= "table" then defaults.trackFoodContent = createDefaultTrackingContentSelection() end
if defaults.trackWeaponBuffs == nil then defaults.trackWeaponBuffs = false end
if type(defaults.trackWeaponBuffsContent) ~= "table" then defaults.trackWeaponBuffsContent = createDefaultTrackingContentSelection() end
if defaults.borderEnabled == nil then defaults.borderEnabled = false end
if defaults.borderTexture == nil or defaults.borderTexture == "" then defaults.borderTexture = "DEFAULT" end
if defaults.borderSize == nil then defaults.borderSize = 1 end
if defaults.borderOffset == nil then defaults.borderOffset = 0 end
if type(defaults.borderColor) ~= "table" then defaults.borderColor = { r = 1, g = 1, b = 1, a = 1 } end

local function refreshReminder()
	if Reminder and Reminder.OnSettingChanged then Reminder:OnSettingChanged() end
end

local function normalizeRoleFilterContext(value)
	if Reminder and Reminder.NormalizeRoleFilterContext then return Reminder.NormalizeRoleFilterContext(value) end
	if value == "ANY_GROUP" then return "ANY_GROUP" end
	if value == "PARTY_ONLY" then return "PARTY_ONLY" end
	return "RAID_ONLY"
end

local function getTrackingContentOptions()
	if Reminder and Reminder.GetTrackingContentOptions then return Reminder:GetTrackingContentOptions() end
	return {}
end

local function getReminderSelection(getterName, fallback)
	if Reminder and getterName and Reminder[getterName] then return Reminder[getterName](Reminder) end
	return copySelection(fallback)
end

local function setReminderSelection(setterName, dbKey, selection)
	if Reminder and setterName and Reminder[setterName] then
		Reminder[setterName](Reminder, selection)
		return
	end
	if addon.db then addon.db[dbKey] = copySelection(selection) end
	refreshReminder()
end

local function openFlaskSettings()
	if addon.functions and addon.functions.OpenFlaskMacroSettings then
		addon.functions.OpenFlaskMacroSettings()
		return
	end

	if not (Settings and Settings.OpenToCategory) then return end
	local gameplayCategory = addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY
	if not gameplayCategory then return end

	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0, 0) end
		return
	end

	Settings.OpenToCategory(gameplayCategory:GetID(), L["Flask Macro"] or "Flask Macro")
end

local function openFoodSettings()
	if addon.functions and addon.functions.OpenBuffFoodMacroSettings then
		addon.functions.OpenBuffFoodMacroSettings()
		return
	end

	if not (Settings and Settings.OpenToCategory) then return end
	local gameplayCategory = addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY
	if not gameplayCategory then return end

	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0, 0) end
		return
	end

	Settings.OpenToCategory(gameplayCategory:GetID(), L["Buff Food Macro"] or "Buff Food Macro")
end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Class Buff Reminder"] or "Class Buff Reminder",
	newTagID = "ClassBuffReminder",
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateText(cat, L["ClassBuffReminderDesc"] or "Shows how many group members are missing the class buff your class can provide.", {
	parentSection = expandable,
})

addon.functions.SettingsCreateText(cat, "|cffffd700" .. (L["ClassBuffReminderEditModeHint"] or "Use Edit Mode to position the reminder.") .. "|r", {
	parentSection = expandable,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB_ENABLED,
	text = L["ClassBuffReminderEnable"] or "Enable class buff reminder",
	func = function(value)
		addon.db[DB_ENABLED] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB_HIDE_IN_RESTED_AREA,
	text = L["ClassBuffReminderHideInRestedArea"] or "Don't show in rested areas",
	desc = L["ClassBuffReminderHideInRestedAreaDesc"] or "Suppresses the entire reminder while you are in a rested area.",
	func = function(value)
		addon.db[DB_HIDE_IN_RESTED_AREA] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateText(cat, L["ClassBuffReminderFlaskSharedHint"] or "Flask preferences are shared with Flask Macro (Gameplay -> Macros & Consumables).", {
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(cat, {
	var = "classBuffReminderOpenFlaskSettings",
	text = L["ClassBuffReminderOpenFlaskSettings"] or "Open Flask settings",
	desc = L["ClassBuffReminderOpenFlaskSettingsDesc"] or "Jumps to Gameplay -> Macros & Consumables and focuses Flask Macro settings.",
	func = openFlaskSettings,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(cat, {
	var = "classBuffReminderOpenFoodSettings",
	text = L["ClassBuffReminderOpenFoodSettings"] or "Open Food settings",
	desc = L["ClassBuffReminderOpenFoodSettingsDesc"] or "Jumps to Gameplay -> Macros & Consumables and focuses Buff Food Macro settings.",
	func = openFoodSettings,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionFlasks"] or "Flasks", {
	parentSection = expandable,
})

local flaskTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB_TRACK_FLASKS,
	text = L["ClassBuffReminderTrackFlasks"] or "Track missing flask buff",
	desc = L["ClassBuffReminderTrackFlasksDesc"] or "Shows a flask reminder only when a matching flask is available in your bags.",
	func = function(value)
		addon.db[DB_TRACK_FLASKS] = value == true
		if Reminder and Reminder.InvalidateFlaskCache then Reminder:InvalidateFlaskCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB_TRACK_FLASKS_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetFlaskTrackingContentSelection", defaults.trackFlasksContent) end,
	setSelection = function(selection) setReminderSelection("SetFlaskTrackingContentSelection", DB_TRACK_FLASKS_CONTENT, selection) end,
	default = defaults.trackFlasksContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = flaskTracking and flaskTracking.element,
	parentCheck = function() return addon.db and addon.db[DB_TRACK_FLASKS] == true end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionFood"] or "Food", {
	parentSection = expandable,
})

local foodTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB_TRACK_FOOD,
	text = L["ClassBuffReminderTrackFood"] or "Track missing food buff",
	desc = L["ClassBuffReminderTrackFoodDesc"] or "Shows a food reminder only when a matching buff food is available in your bags.",
	func = function(value)
		addon.db[DB_TRACK_FOOD] = value == true
		if Reminder and Reminder.InvalidateFoodCache then Reminder:InvalidateFoodCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB_TRACK_FOOD_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetFoodTrackingContentSelection", defaults.trackFoodContent) end,
	setSelection = function(selection) setReminderSelection("SetFoodTrackingContentSelection", DB_TRACK_FOOD_CONTENT, selection) end,
	default = defaults.trackFoodContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = foodTracking and foodTracking.element,
	parentCheck = function() return addon.db and addon.db[DB_TRACK_FOOD] == true end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionWeaponBuffs"] or "Weapon Buffs", {
	parentSection = expandable,
})

local weaponTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB_TRACK_WEAPON_BUFFS,
	text = L["ClassBuffReminderTrackWeaponBuffs"] or "Track missing weapon oil/stone",
	desc = L["ClassBuffReminderTrackWeaponBuffsDesc"] or "Shows a weapon buff reminder only when a supported oil, stone, or similar temporary weapon buff item is available in your bags.",
	func = function(value)
		addon.db[DB_TRACK_WEAPON_BUFFS] = value == true
		if Reminder and Reminder.InvalidateWeaponBuffCache then Reminder:InvalidateWeaponBuffCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB_TRACK_WEAPON_BUFFS_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetWeaponBuffTrackingContentSelection", defaults.trackWeaponBuffsContent) end,
	setSelection = function(selection) setReminderSelection("SetWeaponBuffTrackingContentSelection", DB_TRACK_WEAPON_BUFFS_CONTENT, selection) end,
	default = defaults.trackWeaponBuffsContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = weaponTracking and weaponTracking.element,
	parentCheck = function() return addon.db and addon.db[DB_TRACK_WEAPON_BUFFS] == true end,
	parentSection = expandable,
})

function addon.functions.initClassBuffReminder()
	if not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue

	init(DB_ENABLED, defaults.enabled)
	init(DB_SHOW_PARTY, defaults.showParty)
	init(DB_SHOW_RAID, defaults.showRaid)
	init(DB_SHOW_SOLO, defaults.showSolo)
	init(DB_HIDE_IN_RESTED_AREA, defaults.hideInRestedArea)
	init(DB_ONLY_OUT_OF_COMBAT, defaults.onlyOutOfCombat)
	init(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled)
	init(DB_ROLE_FILTER_CONTEXT, normalizeRoleFilterContext(defaults.roleFilterContext))
	init(DB_HIDE_FOR_HEALER, defaults.hideForHealer)
	init(DB_HIDE_FOR_TANK, defaults.hideForTank)
	init(DB_HIDE_FOR_DAMAGER, defaults.hideForDamager)
	init(DB_HIDE_FOR_NONE, defaults.hideForNoRole)
	init(DB_SHOW_IF_ONLY_PROVIDER, defaults.showIfOnlyProvider)
	init(DB_GLOW, defaults.glow)
	init(DB_GLOW_STYLE, defaults.glowStyle)
	init(DB_GLOW_INSET, defaults.glowInset)
	init(DB_GLOW_COLOR, defaults.glowColor)
	init(DB_SOUND_ON_MISSING, defaults.soundOnMissing)
	init(DB_MISSING_SOUND, defaults.missingSound)
	init(DB_DISPLAY_MODE, defaults.displayMode)
	init(DB_GROWTH_DIRECTION, defaults.growthDirection)
	init(DB_GROWTH_FROM_CENTER, defaults.growthFromCenter)
	init(DB_TRACK_FLASKS, defaults.trackFlasks)
	init(DB_TRACK_FOOD, defaults.trackFood)
	init(DB_TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs)
	init(DB_SCALE, defaults.scale)
	init(DB_ICON_SIZE, defaults.iconSize)
	init(DB_FONT_SIZE, defaults.fontSize)
	init(DB_ICON_GAP, defaults.iconGap)
	init(DB_BORDER_ENABLED, defaults.borderEnabled)
	init(DB_BORDER_TEXTURE, defaults.borderTexture)
	init(DB_BORDER_SIZE, defaults.borderSize)
	init(DB_BORDER_OFFSET, defaults.borderOffset)
	init(DB_BORDER_COLOR, defaults.borderColor)
	init(DB_XY_TEXT_SIZE, defaults.xyTextSize)
	init(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)
	init(DB_XY_TEXT_COLOR, defaults.xyTextColor)
	init(DB_XY_TEXT_OFFSET_X, defaults.xyTextOffsetX)
	init(DB_XY_TEXT_OFFSET_Y, defaults.xyTextOffsetY)
	if addon.db then
		addon.db[DB_TRACK_FLASKS_CONTENT] = getReminderSelection("GetFlaskTrackingContentSelection", defaults.trackFlasksContent)
		addon.db[DB_TRACK_FOOD_CONTENT] = getReminderSelection("GetFoodTrackingContentSelection", defaults.trackFoodContent)
		addon.db[DB_TRACK_WEAPON_BUFFS_CONTENT] = getReminderSelection("GetWeaponBuffTrackingContentSelection", defaults.trackWeaponBuffsContent)
	end
	if addon.db then addon.db[LEGACY_DB_SOUND_DEBUG_TRACE] = nil end
	if addon.db then addon.db[LEGACY_DB_SHOW_ICON] = nil end
	if addon.db then addon.db[LEGACY_DB_ONLY_WHEN_MISSING] = nil end

	refreshReminder()
end
