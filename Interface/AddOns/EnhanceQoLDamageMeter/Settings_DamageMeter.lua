local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local cChar = nil

local damageMeterSection = addon.SettingsLayout.suitesDamageMeterSection
if not damageMeterSection then
	damageMeterSection = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["damageMeterTitle"] or "Damage Meter",
		configPageKey = "DamageMeter",
		description = L["damageMeterEditModeHint"],
		iconAtlas = "icons_64x64_damage",
		modernCategory = "gameplay",
		modernOnly = true,
		expanded = false,
		colorizeTitle = false,
		newTagID = "damageMeterEnabled",
	})
	addon.SettingsLayout.suitesDamageMeterSection = damageMeterSection
end

local damageMeterEnable = addon.functions.SettingsCreateCheckbox(cChar, {
	var = "damageMeterEnabled",
	text = L["damageMeterEnabled"],
	desc = L["damageMeterEditModeHint"],
	func = function(value)
		addon.db["damageMeterEnabled"] = value == true
		if addon.DamageMeter and addon.DamageMeter.UpdateEventState then addon.DamageMeter:UpdateEventState() end
	end,
	parentSection = damageMeterSection,
})

local function isDamageMeterEnabled() return damageMeterEnable and damageMeterEnable.setting and damageMeterEnable.setting:GetValue() == true end

addon.functions.SettingsCreateSlider(cChar, {
	var = "damageMeterUpdateRate",
	text = L["damageMeterUpdateRate"],
	desc = L["damageMeterUpdateRateDesc"],
	min = 0.01,
	max = 5,
	step = 0.01,
	default = 0.1,
	formatter = function(value) return string.format("%.2f", tonumber(value) or 0.1) end,
	get = function() return (addon.db and addon.db["damageMeterUpdateRate"]) or 0.1 end,
	set = function(value)
		addon.db["damageMeterUpdateRate"] = value
		if addon.DamageMeter and addon.DamageMeter.ScheduleRefresh then addon.DamageMeter:ScheduleRefresh() end
	end,
	parent = true,
	element = damageMeterEnable.element,
	parentCheck = isDamageMeterEnabled,
	parentSection = damageMeterSection,
})

addon.functions.SettingsCreateCheckbox(cChar, {
	var = "damageMeterEditModeSample",
	text = L["damageMeterEditModeSample"],
	desc = L["damageMeterEditModeSampleDesc"],
	func = function(value)
		addon.db["damageMeterEditModeSample"] = value == true
		if addon.DamageMeter and addon.DamageMeter.Refresh then addon.DamageMeter:Refresh() end
	end,
	parent = true,
	element = damageMeterEnable.element,
	parentCheck = isDamageMeterEnabled,
	parentSection = damageMeterSection,
})
