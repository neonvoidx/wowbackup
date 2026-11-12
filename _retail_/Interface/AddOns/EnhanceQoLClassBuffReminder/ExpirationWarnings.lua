local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Reminder = addon.ClassBuffReminder
local DB_ENABLED = "classBuffReminderExpirationOverridesEnabled"
local DB_CATEGORIES = "classBuffReminderExpirationCategories"

local categories = {
	{ key = "CLASS_BUFFS", label = "ClassBuffReminderSectionClassBuffs" },
	{ key = "POISONS", label = "ClassBuffReminderSectionPoisons" },
	{ key = "FLASK", label = "ClassBuffReminderSectionFlasks", retailOnly = true },
	{ key = "FOOD", label = "ClassBuffReminderSectionFood", retailOnly = true },
	{ key = "RUNES", label = "ClassBuffReminderSectionRunes", retailOnly = true },
	{ key = "WEAPON_BUFFS", label = "ClassBuffReminderSectionWeaponBuffs" },
}
local categoryKeys = {}
for _, category in ipairs(categories) do categoryKeys[category.key] = true end

function Reminder:AreExpirationOverridesEnabled()
	return addon.db and addon.db[DB_ENABLED] == true or false
end

function Reminder:GetExpirationCategorySettings(category)
	local stored = addon.db and addon.db[DB_CATEGORIES]
	local value = type(stored) == "table" and stored[category] or nil
	return type(value) == "table" and value or nil
end

function Reminder:GetExpirationCategoryMode(category)
	local settings = self:GetExpirationCategorySettings(category)
	local mode = settings and settings.mode
	return (mode == "custom" or mode == "off") and mode or "shared"
end

function Reminder:GetExpirationCategoryCustomMinutes(category)
	local settings = self:GetExpirationCategorySettings(category)
	return math.max(1, self:NormalizeExpirationWarningMinutes(settings and settings.minutes or 2))
end

function Reminder:GetCategoryExpirationWarningMinutes(category)
	if self:AreExpirationOverridesEnabled() then
		local mode = self:GetExpirationCategoryMode(category or "CLASS_BUFFS")
		if mode == "off" then return 0 end
		if mode == "custom" then return self:GetExpirationCategoryCustomMinutes(category or "CLASS_BUFFS") end
	end
	return self:GetActiveExpirationWarningMinutes()
end

function Reminder:RefreshExpirationWarnings()
	self:CancelExpirationWarningTimer()
	self:MarkAuraStatesDirty()
	self:InvalidateSelfProviderStatus()
	self:RequestUpdate(true)
end

function Reminder:SetExpirationOverridesEnabled(enabled)
	if not addon.db then return end
	addon.db[DB_ENABLED] = enabled == true
	self:RefreshExpirationWarnings()
end

function Reminder:SetExpirationCategorySetting(category, field, value)
	if not addon.db or not categoryKeys[category] then return end
	if field == "mode" then
		value = (value == "custom" or value == "off") and value or "shared"
	elseif field == "minutes" then
		value = math.max(1, self:NormalizeExpirationWarningMinutes(value))
	else
		return
	end
	if type(addon.db[DB_CATEGORIES]) ~= "table" then addon.db[DB_CATEGORIES] = {} end
	local stored = addon.db[DB_CATEGORIES]
	if type(stored[category]) ~= "table" then stored[category] = {} end
	stored[category][field] = value
	self:RefreshExpirationWarnings()
end

function Reminder:InitializeExpirationCategorySettings()
	if not (addon.functions and addon.functions.InitDBValue) then return end
	addon.functions.InitDBValue(DB_ENABLED, false)
	addon.functions.InitDBValue(DB_CATEGORIES, {})
end

function Reminder:GetExpirationWarningCategories()
	local result = {}
	for _, category in ipairs(categories) do
		if not (category.retailOnly and self.classicBuffs) then result[#result + 1] = category end
	end
	return result
end

local function modeOptions()
	return {
		{ value = "shared", label = L["ClassBuffReminderExpirationShared"] },
		{ value = "custom", label = L["ClassBuffReminderExpirationCustom"] },
		{ value = "off", label = L["ClassBuffReminderExpirationDisabled"] },
	}
end

local function formatMinutes(value)
	return string.format(L["ClassBuffReminderExpirationWarningMinutesFmt"], value)
end

function Reminder:RegisterExpirationCategorySettings(cat, section)
	addon.functions.SettingsCreateCheckbox(cat, {
		var = DB_ENABLED,
		text = L["ClassBuffReminderExpirationOverrides"],
		desc = L["ClassBuffReminderExpirationOverridesDesc"],
		default = false,
		get = function() return self:AreExpirationOverridesEnabled() end,
		func = function(value) self:SetExpirationOverridesEnabled(value) end,
		parentSection = section,
		newTagID = "ClassBuffReminderExpirationOverrides",
	})
	for _, category in ipairs(self:GetExpirationWarningCategories()) do
		local key = category.key
		local tag = "ClassBuffReminderExpiration" .. key
		addon.functions.SettingsCreateDropdown(cat, {
			var = tag .. "Mode",
			id = tag .. "Mode",
			key = false,
			storage = false,
			text = L[category.label],
			desc = L["ClassBuffReminderExpirationCategoryDesc"],
			default = "shared",
			get = function() return self:GetExpirationCategoryMode(key) end,
			func = function(value) self:SetExpirationCategorySetting(key, "mode", value) end,
			optionfunc = modeOptions,
			parentSection = section,
			visibleWhen = function() return self:AreExpirationOverridesEnabled() end,
			newTagID = tag .. "Mode",
		})
		addon.functions.SettingsCreateSlider(cat, {
			var = tag .. "Minutes",
			id = tag .. "Minutes",
			key = false,
			storage = false,
			text = string.format(L["ClassBuffReminderExpirationCategoryMinutesFmt"], L[category.label]),
			min = 1,
			max = 60,
			step = 1,
			default = 2,
			get = function() return self:GetExpirationCategoryCustomMinutes(key) end,
			func = function(value) self:SetExpirationCategorySetting(key, "minutes", value) end,
			formatter = formatMinutes,
			parentSection = section,
			visibleWhen = function() return self:AreExpirationOverridesEnabled() and self:GetExpirationCategoryMode(key) == "custom" end,
			newTagID = tag .. "Minutes",
		})
	end
end

function Reminder:BuildExpirationCategoryEditModeSettings(SettingType)
	local settings = {
		{
			name = L["ClassBuffReminderExpirationOverrides"],
			kind = SettingType.Collapsible,
			id = "expirationCategories",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderExpirationOverrides"],
			kind = SettingType.Checkbox,
			parentId = "expirationCategories",
			default = false,
			get = function() return self:AreExpirationOverridesEnabled() end,
			set = function(_, value) self:SetExpirationOverridesEnabled(value) end,
			tooltip = L["ClassBuffReminderExpirationOverridesDesc"],
		},
	}
	for _, category in ipairs(self:GetExpirationWarningCategories()) do
		local key = category.key
		settings[#settings + 1] = {
			name = L[category.label],
			kind = SettingType.Dropdown,
			parentId = "expirationCategories",
			default = "shared",
			get = function() return self:GetExpirationCategoryMode(key) end,
			set = function(_, value) self:SetExpirationCategorySetting(key, "mode", value) end,
			values = modeOptions,

			isEnabled = function() return self:AreExpirationOverridesEnabled() end,
			tooltip = L["ClassBuffReminderExpirationCategoryDesc"],
		}
		settings[#settings + 1] = {
			name = string.format(L["ClassBuffReminderExpirationCategoryMinutesFmt"], L[category.label]),
			kind = SettingType.Slider,
			parentId = "expirationCategories",
			default = 2,
			minValue = 1,
			maxValue = 60,
			valueStep = 1,
			get = function() return self:GetExpirationCategoryCustomMinutes(key) end,
			set = function(_, value) self:SetExpirationCategorySetting(key, "minutes", value) end,
			formatter = formatMinutes,
			isEnabled = function() return self:AreExpirationOverridesEnabled() and self:GetExpirationCategoryMode(key) == "custom" end,
		}
	end
	return settings
end
