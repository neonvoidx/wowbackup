local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Reminder = addon.ClassBuffReminder

local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not (cat and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end

local DB = {
	ENABLED = "classBuffReminderEnabled",
	SHOW_PARTY = "classBuffReminderShowParty",
	SHOW_RAID = "classBuffReminderShowRaid",
	SHOW_SOLO = "classBuffReminderShowSolo",
	HIDE_IN_RESTED_AREA = "classBuffReminderHideInRestedArea",
	ONLY_OUT_OF_COMBAT = "classBuffReminderOnlyOutOfCombat",
	ROLE_FILTER_ENABLED = "classBuffReminderRoleFilterEnabled",
	ROLE_FILTER_CONTEXT = "classBuffReminderRoleFilterContext",
	HIDE_FOR_HEALER = "classBuffReminderHideForHealer",
	HIDE_FOR_TANK = "classBuffReminderHideForTank",
	HIDE_FOR_DAMAGER = "classBuffReminderHideForDamager",
	HIDE_FOR_NONE = "classBuffReminderHideForNoRole",
	SHOW_IF_ONLY_PROVIDER = "classBuffReminderShowIfOnlyProvider",
	GLOW = "classBuffReminderGlow",
	GLOW_STYLE = "classBuffReminderGlowStyle",
	GLOW_INSET = "classBuffReminderGlowInset",
	GLOW_COLOR = "classBuffReminderGlowColor",
	SOUND_ON_MISSING = "classBuffReminderSoundOnMissing",
	MISSING_SOUND = "classBuffReminderMissingSound",
	DISPLAY_MODE = "classBuffReminderDisplayMode",
	GROWTH_DIRECTION = "classBuffReminderGrowthDirection",
	GROWTH_FROM_CENTER = "classBuffReminderGrowthFromCenter",
	ICON_SHAPE = "classBuffReminderIconShape",
	ICON_ZOOM = "classBuffReminderIconZoom",
	TRACK_FLASKS = "classBuffReminderTrackFlasks",
	TRACK_FLASKS_CONTENT = "classBuffReminderTrackFlasksContent",
	TRACK_FLASKS_INSTANCE_ONLY = "classBuffReminderTrackFlasksInstanceOnly",
	TRACK_FOOD = "classBuffReminderTrackFood",
	TRACK_FOOD_CONTENT = "classBuffReminderTrackFoodContent",
	TRACK_FOOD_INSTANCE_ONLY = "classBuffReminderTrackFoodInstanceOnly",
	TRACK_WEAPON_BUFFS = "classBuffReminderTrackWeaponBuffs",
	TRACK_WEAPON_BUFFS_CONTENT = "classBuffReminderTrackWeaponBuffsContent",
	TRACK_WEAPON_BUFFS_INSTANCE_ONLY = "classBuffReminderTrackWeaponBuffsInstanceOnly",
	EXPIRATION_WARNING_MINUTES = "classBuffReminderExpirationWarningMinutes",
	TRACK_PETS = "classBuffReminderTrackPets",
	TRACK_PETS_CONTENT = "classBuffReminderTrackPetsContent",
	TRACK_PETS_INSTANCE_ONLY = "classBuffReminderTrackPetsInstanceOnly",
	IGNORE_PET_DEFENSIVE = "classBuffReminderIgnorePetDefensive",
	IGNORE_PET_PASSIVE = "classBuffReminderIgnorePetPassive",
	HIDE_PET_REMINDER_TEXT = "classBuffReminderHidePetReminderText",
	SCALE = "classBuffReminderScale",
	ICON_SIZE = "classBuffReminderIconSize",
	FONT_SIZE = "classBuffReminderFontSize",
	ICON_GAP = "classBuffReminderIconGap",
	BORDER_ENABLED = "classBuffReminderBorderEnabled",
	BORDER_TEXTURE = "classBuffReminderBorderTexture",
	BORDER_SIZE = "classBuffReminderBorderSize",
	BORDER_OFFSET = "classBuffReminderBorderOffset",
	BORDER_COLOR = "classBuffReminderBorderColor",
	XY_TEXT_SIZE = "classBuffReminderXYTextSize",
	XY_TEXT_OUTLINE = "classBuffReminderXYTextOutline",
	XY_TEXT_COLOR = "classBuffReminderXYTextColor",
	XY_TEXT_OFFSET_X = "classBuffReminderXYTextOffsetX",
	XY_TEXT_OFFSET_Y = "classBuffReminderXYTextOffsetY",
	LEGACY_SOUND_DEBUG_TRACE = "classBuffReminderSoundDebugTrace",
	LEGACY_SHOW_ICON = "classBuffReminderShowIcon",
	LEGACY_ONLY_WHEN_MISSING = "classBuffReminderOnlyWhenMissing",
}

local EXPIRATION_WARNING_MINUTES_MIN = 0
local EXPIRATION_WARNING_MINUTES_MAX = 60

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
		iconShape = "DEFAULT",
		iconZoom = 0,
		trackFlasks = false,
		trackFlasksContent = createDefaultTrackingContentSelection(),
		trackFlasksInstanceOnly = false,
		trackFood = false,
		trackFoodContent = createDefaultTrackingContentSelection(),
		trackFoodInstanceOnly = false,
		trackWeaponBuffs = false,
		trackWeaponBuffsContent = createDefaultTrackingContentSelection(),
		trackWeaponBuffsInstanceOnly = false,
		expirationWarningMinutes = 0,
		trackPets = false,
		trackPetsContent = createDefaultTrackingContentSelection(),
		trackPetsInstanceOnly = false,
		ignorePetDefensive = false,
		ignorePetPassive = false,
		hidePetReminderText = false,
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
if defaults.expirationWarningMinutes == nil then defaults.expirationWarningMinutes = 0 end
if defaults.trackPets == nil then defaults.trackPets = false end
if type(defaults.trackPetsContent) ~= "table" then defaults.trackPetsContent = createDefaultTrackingContentSelection() end
if defaults.ignorePetDefensive == nil then defaults.ignorePetDefensive = false end
if defaults.ignorePetPassive == nil then defaults.ignorePetPassive = false end
if defaults.borderEnabled == nil then defaults.borderEnabled = false end
if defaults.borderTexture == nil or defaults.borderTexture == "" then defaults.borderTexture = "DEFAULT" end
if defaults.borderSize == nil then defaults.borderSize = 1 end
if defaults.borderOffset == nil then defaults.borderOffset = 0 end
if type(defaults.borderColor) ~= "table" then defaults.borderColor = { r = 1, g = 1, b = 1, a = 1 } end

local function refreshReminder()
	if Reminder and Reminder.OnSettingChanged then Reminder:OnSettingChanged() end
end

local function normalizeExpirationWarningMinutes(value)
	if Reminder and Reminder.NormalizeExpirationWarningMinutes then return Reminder:NormalizeExpirationWarningMinutes(value) end
	local minutes = math.floor((tonumber(value) or defaults.expirationWarningMinutes or 0) + 0.5)
	if minutes < EXPIRATION_WARNING_MINUTES_MIN then minutes = EXPIRATION_WARNING_MINUTES_MIN end
	if minutes > EXPIRATION_WARNING_MINUTES_MAX then minutes = EXPIRATION_WARNING_MINUTES_MAX end
	return minutes
end

local function formatExpirationWarningMinutes(value)
	local minutes = normalizeExpirationWarningMinutes(value)
	if minutes <= 0 then return L["ClassBuffReminderExpirationWarningOff"] or "Missing only" end
	return string.format(L["ClassBuffReminderExpirationWarningMinutesFmt"] or "%d min", minutes)
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

	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0, 0) end
		return
	end

	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter("gameplay.macrosconsumables", "flaskMacroEnabled") end
end

local function openFoodSettings()
	if addon.functions and addon.functions.OpenBuffFoodMacroSettings then
		addon.functions.OpenBuffFoodMacroSettings()
		return
	end

	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0, 0) end
		return
	end

	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter("gameplay.macrosconsumables", "buffFoodMacroEnabled") end
end

local function normalizeIconShape(value)
	if addon.IconShape and addon.IconShape.Normalize then return addon.IconShape.Normalize(value, defaults.iconShape or "DEFAULT") end
	if type(value) == "string" and value ~= "" then return value end
	return defaults.iconShape or "DEFAULT"
end

local function normalizeIconZoom(value)
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then return addon.IconShape.NormalizeIconZoom(value, defaults.iconZoom or 0) end
	value = tonumber(value) or defaults.iconZoom or 0
	if value < 0 then value = 0 end
	if value > 35 then value = 35 end
	return math.floor(value + 0.5)
end

local function getIconShapeOptions()
	if addon.IconShape and addon.IconShape.GetOptions then return addon.IconShape.GetOptions(L) end
	return {
		{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
		{ value = "SQUARE", label = "Square" },
		{ value = "ROUND", label = "Round" },
		{ value = "ROUND_STAR", label = L["settingsIconShapeRoundStar"] or "Round star" },
		{ value = "HEXAGON", label = "Hexagon" },
		{ value = "DIAMOND", label = "Diamond" },
	}
end

local function refreshReminderVisuals()
	if Reminder and Reminder.StopAllGlowTargetsImmediate then
		Reminder:StopAllGlowTargetsImmediate()
	elseif Reminder and Reminder.SetGlowShown then
		Reminder:SetGlowShown(false)
	end
	if Reminder and Reminder.ApplyVisualSettings then Reminder:ApplyVisualSettings() end
	if Reminder and Reminder.RestartGlowAfterVisualChange then Reminder:RestartGlowAfterVisualChange() end
	refreshReminder()
end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Class Buff Reminder"] or "Class Buff Reminder",
	description = L["configCenterPageDescClassBuffReminder"]
		or "Track missing class buffs for your group and connect those reminders with flask and buff food helpers.",
	newTagID = "ClassBuffReminder",
	iconKey = "buff",
	expanded = false,
	colorizeTitle = false,
	modernOnly = true,
})

addon.functions.SettingsCreateText(cat, L["ClassBuffReminderDesc"] or "Shows how many group members are missing the class buff your class can provide.", {
	parentSection = expandable,
})

addon.functions.SettingsCreateText(cat, "|cffffd700" .. (L["ClassBuffReminderEditModeHint"] or "Use Edit Mode to position the reminder.") .. "|r", {
	parentSection = expandable,
})

addon.functions.SettingsCreateDropdown(cat, {
	var = DB.ICON_SHAPE,
	text = L["settingsIconShapeLabel"] or "Icon shape",
	default = defaults.iconShape or "DEFAULT",
	get = function() return normalizeIconShape(addon.db and addon.db[DB.ICON_SHAPE]) end,
	func = function(value)
		if addon.db then addon.db[DB.ICON_SHAPE] = normalizeIconShape(value) end
		refreshReminderVisuals()
	end,
	optionfunc = getIconShapeOptions,
	parentSection = expandable,
})

addon.functions.SettingsCreateSlider(cat, {
	var = DB.ICON_ZOOM,
	text = L["Icon zoom"] or "Icon zoom",
	min = 0,
	max = 35,
	step = 1,
	default = defaults.iconZoom or 0,
	get = function() return normalizeIconZoom(addon.db and addon.db[DB.ICON_ZOOM]) end,
	func = function(value)
		if addon.db then addon.db[DB.ICON_ZOOM] = normalizeIconZoom(value) end
		refreshReminderVisuals()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.ENABLED,
	text = L["ClassBuffReminderEnable"] or "Enable class buff reminder",
	desc = L["ClassBuffReminderEnableDesc"],
	func = function(value)
		addon.db[DB.ENABLED] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.HIDE_IN_RESTED_AREA,
	text = L["ClassBuffReminderHideInRestedArea"] or "Don't show in rested areas",
	desc = L["ClassBuffReminderHideInRestedAreaDesc"] or "Suppresses the entire reminder while you are in a rested area.",
	func = function(value)
		addon.db[DB.HIDE_IN_RESTED_AREA] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateSlider(cat, {
	var = DB.EXPIRATION_WARNING_MINUTES,
	text = L["ClassBuffReminderExpirationWarningMinutes"] or "Show before expiration",
	desc = L["ClassBuffReminderExpirationWarningMinutesDesc"] or "0 keeps the current behavior. Higher values show the reminder when a tracked buff has this many minutes or less remaining.",
	min = EXPIRATION_WARNING_MINUTES_MIN,
	max = EXPIRATION_WARNING_MINUTES_MAX,
	step = 1,
	default = defaults.expirationWarningMinutes or 0,
	get = function()
		if Reminder and Reminder.GetExpirationWarningMinutes then return Reminder:GetExpirationWarningMinutes() end
		return normalizeExpirationWarningMinutes(addon.db and addon.db[DB.EXPIRATION_WARNING_MINUTES])
	end,
	func = function(value)
		if Reminder and Reminder.SetExpirationWarningMinutes then
			Reminder:SetExpirationWarningMinutes(value)
			return
		end
		if addon.db then addon.db[DB.EXPIRATION_WARNING_MINUTES] = normalizeExpirationWarningMinutes(value) end
		refreshReminder()
	end,
	formatter = formatExpirationWarningMinutes,
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
	var = DB.TRACK_FLASKS,
	text = L["ClassBuffReminderTrackFlasks"] or "Track missing flask buff",
	desc = L["ClassBuffReminderTrackFlasksDesc"] or "Shows a flask reminder only when a matching flask is available in your bags.",
	func = function(value)
		addon.db[DB.TRACK_FLASKS] = value == true
		if Reminder and Reminder.InvalidateFlaskCache then Reminder:InvalidateFlaskCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB.TRACK_FLASKS_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetFlaskTrackingContentSelection", defaults.trackFlasksContent) end,
	setSelection = function(selection) setReminderSelection("SetFlaskTrackingContentSelection", DB.TRACK_FLASKS_CONTENT, selection) end,
	default = defaults.trackFlasksContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = flaskTracking and flaskTracking.element,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_FLASKS] == true end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionFood"] or "Food", {
	parentSection = expandable,
})

local foodTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.TRACK_FOOD,
	text = L["ClassBuffReminderTrackFood"] or "Track missing food buff",
	desc = L["ClassBuffReminderTrackFoodDesc"] or "Shows a food reminder only when a matching buff food is available in your bags.",
	func = function(value)
		addon.db[DB.TRACK_FOOD] = value == true
		if Reminder and Reminder.InvalidateFoodCache then Reminder:InvalidateFoodCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB.TRACK_FOOD_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetFoodTrackingContentSelection", defaults.trackFoodContent) end,
	setSelection = function(selection) setReminderSelection("SetFoodTrackingContentSelection", DB.TRACK_FOOD_CONTENT, selection) end,
	default = defaults.trackFoodContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = foodTracking and foodTracking.element,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_FOOD] == true end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionWeaponBuffs"] or "Weapon Buffs", {
	parentSection = expandable,
})

local weaponTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.TRACK_WEAPON_BUFFS,
	text = L["ClassBuffReminderTrackWeaponBuffs"] or "Track missing weapon oil/stone",
	desc = L["ClassBuffReminderTrackWeaponBuffsDesc"] or "Shows a weapon buff reminder only when a supported oil, stone, or similar temporary weapon buff item is available in your bags.",
	func = function(value)
		addon.db[DB.TRACK_WEAPON_BUFFS] = value == true
		if Reminder and Reminder.InvalidateWeaponBuffCache then Reminder:InvalidateWeaponBuffCache() end
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB.TRACK_WEAPON_BUFFS_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetWeaponBuffTrackingContentSelection", defaults.trackWeaponBuffsContent) end,
	setSelection = function(selection) setReminderSelection("SetWeaponBuffTrackingContentSelection", DB.TRACK_WEAPON_BUFFS_CONTENT, selection) end,
	default = defaults.trackWeaponBuffsContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = weaponTracking and weaponTracking.element,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_WEAPON_BUFFS] == true end,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(cat, L["ClassBuffReminderSectionPets"] or "Pets", {
	parentSection = expandable,
})

local petTracking = addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.TRACK_PETS,
	text = L["ClassBuffReminderTrackPets"] or "Track pet reminders",
	desc = L["ClassBuffReminderTrackPetsDesc"] or "Shows a reminder when your expected pet is missing or set to passive or defensive.",
	func = function(value)
		addon.db[DB.TRACK_PETS] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.IGNORE_PET_PASSIVE,
	text = L["ClassBuffReminderIgnorePetPassive"] or "Ignore passive pet stance",
	desc = L["ClassBuffReminderIgnorePetPassiveDesc"],
	func = function(value)
		addon.db[DB.IGNORE_PET_PASSIVE] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_PETS] == true end,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.IGNORE_PET_DEFENSIVE,
	text = L["ClassBuffReminderIgnorePetDefensive"] or "Ignore defensive pet stance",
	desc = L["ClassBuffReminderIgnorePetDefensiveDesc"],
	func = function(value)
		addon.db[DB.IGNORE_PET_DEFENSIVE] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_PETS] == true end,
})

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.HIDE_PET_REMINDER_TEXT,
	text = L["ClassBuffReminderHidePetReminderText"] or "Hide pet reminder text",
	desc = L["ClassBuffReminderHidePetReminderTextDesc"] or "Hides the small text shown on pet state reminder icons.",
	func = function(value)
		addon.db[DB.HIDE_PET_REMINDER_TEXT] = value == true
		refreshReminder()
	end,
	parentSection = expandable,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_PETS] == true end,
})

addon.functions.SettingsCreateMultiDropdown(cat, {
	var = DB.TRACK_PETS_CONTENT,
	text = L["ClassBuffReminderTrackingContent"] or "Active in content",
	desc = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
	optionfunc = getTrackingContentOptions,
	getSelection = function() return getReminderSelection("GetPetTrackingContentSelection", defaults.trackPetsContent) end,
	setSelection = function(selection) setReminderSelection("SetPetTrackingContentSelection", DB.TRACK_PETS_CONTENT, selection) end,
	default = defaults.trackPetsContent,
	menuHeight = 260,
	hideSummary = true,
	customDefaultText = _G.NONE or "None",
	element = petTracking and petTracking.element,
	parentCheck = function() return addon.db and addon.db[DB.TRACK_PETS] == true end,
	parentSection = expandable,
})

function Reminder:Initialize()
	if not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue

	init(DB.ENABLED, defaults.enabled)
	init(DB.SHOW_PARTY, defaults.showParty)
	init(DB.SHOW_RAID, defaults.showRaid)
	init(DB.SHOW_SOLO, defaults.showSolo)
	init(DB.HIDE_IN_RESTED_AREA, defaults.hideInRestedArea)
	init(DB.ONLY_OUT_OF_COMBAT, defaults.onlyOutOfCombat)
	init(DB.ROLE_FILTER_ENABLED, defaults.roleFilterEnabled)
	init(DB.ROLE_FILTER_CONTEXT, normalizeRoleFilterContext(defaults.roleFilterContext))
	init(DB.HIDE_FOR_HEALER, defaults.hideForHealer)
	init(DB.HIDE_FOR_TANK, defaults.hideForTank)
	init(DB.HIDE_FOR_DAMAGER, defaults.hideForDamager)
	init(DB.HIDE_FOR_NONE, defaults.hideForNoRole)
	init(DB.SHOW_IF_ONLY_PROVIDER, defaults.showIfOnlyProvider)
	init(DB.GLOW, defaults.glow)
	init(DB.GLOW_STYLE, defaults.glowStyle)
	init(DB.GLOW_INSET, defaults.glowInset)
	init(DB.GLOW_COLOR, defaults.glowColor)
	init(DB.SOUND_ON_MISSING, defaults.soundOnMissing)
	init(DB.MISSING_SOUND, defaults.missingSound)
	init(DB.DISPLAY_MODE, defaults.displayMode)
	init(DB.GROWTH_DIRECTION, defaults.growthDirection)
	init(DB.GROWTH_FROM_CENTER, defaults.growthFromCenter)
	init(DB.ICON_SHAPE, defaults.iconShape or "DEFAULT")
	init(DB.ICON_ZOOM, defaults.iconZoom or 0)
	init(DB.TRACK_FLASKS, defaults.trackFlasks)
	init(DB.TRACK_FOOD, defaults.trackFood)
	init(DB.TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs)
	init(DB.EXPIRATION_WARNING_MINUTES, defaults.expirationWarningMinutes)
	init(DB.TRACK_PETS, defaults.trackPets)
	init(DB.IGNORE_PET_PASSIVE, defaults.ignorePetPassive)
	init(DB.IGNORE_PET_DEFENSIVE, defaults.ignorePetDefensive)
	init(DB.SCALE, defaults.scale)
	init(DB.ICON_SIZE, defaults.iconSize)
	init(DB.FONT_SIZE, defaults.fontSize)
	init(DB.ICON_GAP, defaults.iconGap)
	init(DB.BORDER_ENABLED, defaults.borderEnabled)
	init(DB.BORDER_TEXTURE, defaults.borderTexture)
	init(DB.BORDER_SIZE, defaults.borderSize)
	init(DB.BORDER_OFFSET, defaults.borderOffset)
	init(DB.BORDER_COLOR, defaults.borderColor)
	init(DB.XY_TEXT_SIZE, defaults.xyTextSize)
	init(DB.XY_TEXT_OUTLINE, defaults.xyTextOutline)
	init(DB.XY_TEXT_COLOR, defaults.xyTextColor)
	init(DB.XY_TEXT_OFFSET_X, defaults.xyTextOffsetX)
	init(DB.XY_TEXT_OFFSET_Y, defaults.xyTextOffsetY)
	if addon.db then
		addon.db[DB.TRACK_FLASKS_CONTENT] = getReminderSelection("GetFlaskTrackingContentSelection", defaults.trackFlasksContent)
		addon.db[DB.TRACK_FOOD_CONTENT] = getReminderSelection("GetFoodTrackingContentSelection", defaults.trackFoodContent)
		addon.db[DB.TRACK_WEAPON_BUFFS_CONTENT] = getReminderSelection("GetWeaponBuffTrackingContentSelection", defaults.trackWeaponBuffsContent)
		addon.db[DB.TRACK_PETS_CONTENT] = getReminderSelection("GetPetTrackingContentSelection", defaults.trackPetsContent)
	end
	if addon.db then addon.db[DB.LEGACY_SOUND_DEBUG_TRACE] = nil end
	if addon.db then addon.db[DB.LEGACY_SHOW_ICON] = nil end
	if addon.db then addon.db[DB.LEGACY_ONLY_WHEN_MISSING] = nil end

	refreshReminder()
end

Reminder:Initialize()
