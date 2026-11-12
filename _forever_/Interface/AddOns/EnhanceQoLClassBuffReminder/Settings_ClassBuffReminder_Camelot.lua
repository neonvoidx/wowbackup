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
	TRACK_GROUP_BUFFS = "classBuffReminderTrackGroupBuffs",
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
	GLOW_USE_CLASS_COLOR = "classBuffReminderGlowUseClassColor",
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
	TRACK_RUNES = "classBuffReminderTrackRunes",
	TRACK_RUNES_CONTENT = "classBuffReminderTrackRunesContent",
	TRACK_HEALTHSTONES = "classBuffReminderTrackHealthstones",
	TRACK_HEALTHSTONES_CONTENT = "classBuffReminderTrackHealthstonesContent",
	TRACK_STANCES = "classBuffReminderTrackStances",
	TRACK_STANCES_CONTENT = "classBuffReminderTrackStancesContent",
	TRACK_GATHERING = "classBuffReminderTrackGathering",
	TRACK_GATHERING_CONTENT = "classBuffReminderTrackGatheringContent",
	EXPIRATION_WARNING_MINUTES = "classBuffReminderExpirationWarningMinutes",
	EXPIRATION_WARNING_MINUTES_MYTHIC_DUNGEON = "classBuffReminderExpirationWarningMinutesMythicDungeon",
	EXPIRATION_WARNING_MINUTES_RAID = "classBuffReminderExpirationWarningMinutesRaid",
	TRACK_PETS = "classBuffReminderTrackPets",
	TRACK_PETS_CONTENT = "classBuffReminderTrackPetsContent",
	TRACK_PETS_INSTANCE_ONLY = "classBuffReminderTrackPetsInstanceOnly",
	PET_HEALTH_REMINDER_ENABLED = "classBuffReminderPetHealthEnabled",
	PET_HEALTH_REMINDER_THRESHOLD = "classBuffReminderPetHealthThreshold",
	-- Retained for imported profile compatibility; not exposed or applied in Forever.
	PET_HEALTH_REMINDER_INFERNAL_BENEFICIARY_ONLY = "classBuffReminderPetHealthInfernalBeneficiaryOnly",
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

local function createAllTrackingContentSelection()
	if Reminder and Reminder.CreateAllTrackingContentSelection then return Reminder.CreateAllTrackingContentSelection() end
	return {
		openWorld = true,
		scenario = true,
		partyFollower = true,
		partyNormal = true,
		partyHeroic = true,
		partyMythic = true,
		partyMythicPlus = true,
		raidLfr = true,
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
		trackGroupBuffs = true,
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
		glowUseClassColor = false,
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
		trackRunes = false,
		trackRunesContent = createDefaultTrackingContentSelection(),
		trackHealthstones = true,
		trackHealthstonesContent = createAllTrackingContentSelection(),
		trackStances = true,
		trackStancesContent = createAllTrackingContentSelection(),
		expirationWarningMinutes = 0,
		expirationWarningMinutesMythicDungeon = 0,
		expirationWarningMinutesRaid = 0,
		trackPets = false,
		trackPetsContent = createDefaultTrackingContentSelection(),
		trackPetsInstanceOnly = false,
		petHealthReminderEnabled = false,
		petHealthReminderThreshold = 30,
		petHealthReminderInfernalBeneficiaryOnly = false,
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
if defaults.glowUseClassColor == nil then defaults.glowUseClassColor = false end
if defaults.trackGroupBuffs == nil then defaults.trackGroupBuffs = true end
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
if defaults.trackRunes == nil then defaults.trackRunes = false end
if type(defaults.trackRunesContent) ~= "table" then defaults.trackRunesContent = createDefaultTrackingContentSelection() end
if defaults.trackHealthstones == nil then defaults.trackHealthstones = true end
if type(defaults.trackHealthstonesContent) ~= "table" then defaults.trackHealthstonesContent = createAllTrackingContentSelection() end
if defaults.trackGathering == nil then defaults.trackGathering = false end
if type(defaults.trackGatheringContent) ~= "table" then defaults.trackGatheringContent = { openWorld = true } end
if defaults.trackStances == nil then defaults.trackStances = true end
if type(defaults.trackStancesContent) ~= "table" then defaults.trackStancesContent = createAllTrackingContentSelection() end
if defaults.expirationWarningMinutes == nil then defaults.expirationWarningMinutes = 0 end
if defaults.expirationWarningMinutesMythicDungeon == nil then defaults.expirationWarningMinutesMythicDungeon = defaults.expirationWarningMinutes end
if defaults.expirationWarningMinutesRaid == nil then defaults.expirationWarningMinutesRaid = defaults.expirationWarningMinutes end
if defaults.trackPets == nil then defaults.trackPets = false end
if type(defaults.trackPetsContent) ~= "table" then defaults.trackPetsContent = createDefaultTrackingContentSelection() end
if defaults.petHealthReminderEnabled == nil then defaults.petHealthReminderEnabled = false end
if defaults.petHealthReminderThreshold == nil then defaults.petHealthReminderThreshold = 30 end
if defaults.petHealthReminderInfernalBeneficiaryOnly == nil then defaults.petHealthReminderInfernalBeneficiaryOnly = false end
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

local function normalizeRoleFilterContext(value)
	if Reminder and Reminder.NormalizeRoleFilterContext then return Reminder.NormalizeRoleFilterContext(value) end
	if value == "ANY_GROUP" then return "ANY_GROUP" end
	if value == "PARTY_ONLY" then return "PARTY_ONLY" end
	return "RAID_ONLY"
end

local function getReminderSelection(getterName, fallback)
	if Reminder and getterName and Reminder[getterName] then return Reminder[getterName](Reminder) end
	return copySelection(fallback)
end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Class Buff Reminder"] or "Class Buff Reminder",
	newTagID = "ClassBuffReminder",
	iconKey = "buff",
	expanded = false,
	colorizeTitle = false,
	modernOnly = true,
})
Reminder.settingsSection = expandable

addon.functions.SettingsCreateCheckbox(cat, {
	var = DB.ENABLED,
	text = L["ClassBuffReminderEnable"] or "Enable class buff reminder",
	desc = L["ClassBuffReminderEnableDesc"],
	func = function(value)
		addon.db[DB.ENABLED] = value == true
		refreshReminder()
	end,
	refreshOnChange = true,
	parentSection = expandable,
})

Reminder:RegisterForeverCampingSettings(cat, expandable)

addon.functions.SettingsCreateText(cat, L["ClassBuffReminderDesc"] or "Shows how many group members are missing the class buff your class can provide.", {
	parentSection = expandable,
})

addon.functions.SettingsCreateInlineHint(cat, L["ClassBuffReminderEditModeHint"], {
	id = "classBuffReminderEditModeHint",
	parentSection = expandable,
})





function Reminder:Initialize()
	if not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue

	init(DB.ENABLED, defaults.enabled)
	init(DB.SHOW_PARTY, defaults.showParty)
	init(DB.SHOW_RAID, defaults.showRaid)
	init(DB.SHOW_SOLO, defaults.showSolo)
	init(DB.TRACK_GROUP_BUFFS, defaults.trackGroupBuffs)
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
	init(DB.GLOW_USE_CLASS_COLOR, defaults.glowUseClassColor)
	init(DB.SOUND_ON_MISSING, defaults.soundOnMissing)
	init(DB.MISSING_SOUND, defaults.missingSound)
	init(DB.DISPLAY_MODE, defaults.displayMode)
	init(DB.GROWTH_DIRECTION, defaults.growthDirection)
	init(DB.GROWTH_FROM_CENTER, defaults.growthFromCenter)
	init(DB.ICON_SHAPE, defaults.iconShape or "DEFAULT")
	init(DB.ICON_ZOOM, defaults.iconZoom or 0)
	init(DB.TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs)
	init("classBuffReminderForeverPlaystyle", "AUTO")
	init(DB.TRACK_HEALTHSTONES, defaults.trackHealthstones)
	init(DB.TRACK_STANCES, defaults.trackStances)
	init(DB.TRACK_GATHERING, defaults.trackGathering)
	init(DB.EXPIRATION_WARNING_MINUTES, defaults.expirationWarningMinutes)
	self:InitializeExpirationCategorySettings()
	if addon.db then
		local inheritedExpirationWarning = normalizeExpirationWarningMinutes(addon.db[DB.EXPIRATION_WARNING_MINUTES])
		if addon.db[DB.EXPIRATION_WARNING_MINUTES_RAID] == nil then addon.db[DB.EXPIRATION_WARNING_MINUTES_RAID] = inheritedExpirationWarning end
	end
	init(DB.EXPIRATION_WARNING_MINUTES_RAID, defaults.expirationWarningMinutesRaid)
	init(DB.TRACK_PETS, defaults.trackPets)
	init(DB.PET_HEALTH_REMINDER_ENABLED, defaults.petHealthReminderEnabled)
	init(DB.PET_HEALTH_REMINDER_THRESHOLD, defaults.petHealthReminderThreshold)
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
		addon.db[DB.TRACK_HEALTHSTONES_CONTENT] = getReminderSelection("GetHealthstoneTrackingContentSelection", defaults.trackHealthstonesContent)
		addon.db[DB.TRACK_WEAPON_BUFFS_CONTENT] = getReminderSelection("GetWeaponBuffTrackingContentSelection", defaults.trackWeaponBuffsContent)
		addon.db[DB.TRACK_STANCES_CONTENT] = getReminderSelection("GetStanceTrackingContentSelection", defaults.trackStancesContent)
		addon.db[DB.TRACK_GATHERING_CONTENT] = getReminderSelection("GetGatheringTrackingContentSelection", defaults.trackGatheringContent)
		addon.db[DB.TRACK_PETS_CONTENT] = getReminderSelection("GetPetTrackingContentSelection", defaults.trackPetsContent)
	end
	if addon.db then addon.db[DB.LEGACY_SOUND_DEBUG_TRACE] = nil end
	if addon.db then addon.db[DB.LEGACY_SHOW_ICON] = nil end
	if addon.db then addon.db[DB.LEGACY_ONLY_WHEN_MISSING] = nil end

	refreshReminder()
end

Reminder:Initialize()
