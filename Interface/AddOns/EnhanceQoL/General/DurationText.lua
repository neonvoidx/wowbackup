local addonName, addon = ...

addon.DurationText = addon.DurationText or {}
addon.functions = addon.functions or {}

local DurationText = addon.DurationText
local EMPTY_TABLE = {}
local DEFAULT_PROFILE_KEY = "MINIMAL"
local BUILTIN_COOLDOWN_STYLE_MIGRATION_FLAG = "builtinCooldownStyleMigrationV1"
local BINDING_UPDATE_INTERVAL = 0.1
local MIN_INTERVAL = "SECONDS"
local MAX_INTERVAL = "DAYS"
local MAX_COLOR_BREAKPOINTS = 5
local DEFAULT_TEXT_COLOR = { r = 1, g = 1, b = 1, a = 1 }

DurationText.defaults = {
	colorBreakpointCount = 0,
	colorBreakpoints = {},
	expiredText = "",
	millisecondsThreshold = 0,
	zeroDurationText = "",
}
DurationText.defaultProfileKey = DEFAULT_PROFILE_KEY
DurationText.profileOrder = { DEFAULT_PROFILE_KEY, "PRECISE" }
DurationText.protectedProfileKeys = {
	MINIMAL = true,
	PRECISE = true,
}
DurationText.profileDefaults = {
	MINIMAL = {
		colorBreakpointCount = 0,
		colorBreakpoints = {},
		expiredText = "",
		millisecondsThreshold = 0,
		zeroDurationText = "",
	},
	PRECISE = {
		colorBreakpointCount = 0,
		colorBreakpoints = {},
		expiredText = "",
		millisecondsThreshold = 6,
		zeroDurationText = "",
	},
}

local INTERVAL_FALLBACK = {
	SECONDS = 0,
	MINUTES = 1,
	HOURS = 2,
	DAYS = 3,
}
local ABBREVIATION_FALLBACK = {
	NONE = 0,
	TRUNCATE = 1,
	ONE_LETTER = 2,
}
local WHITESPACE_FALLBACK = {
	PRESERVE = 0,
	STRIP = 1,
	STRIP_IGNORE_LOCALE = 2,
}
local ROUNDING_FALLBACK = {
	DOWN = 2,
	NEAREST = 0,
	UP = 1,
}
local DURATION_TEXT_BINDING_PROPERTIES = {
	ElapsedDuration = 2,
	ElapsedPercent = 3,
	EndTime = 6,
	RemainingDuration = 0,
	RemainingPercent = 1,
	StartTime = 5,
	TotalDuration = 4,
}
local DURATION_TEXT_BINDING_PROPERTY_ALIASES = {
	ELAPSED = "ElapsedDuration",
	ELAPSEDDURATION = "ElapsedDuration",
	ELAPSEDPERCENT = "ElapsedPercent",
	END = "EndTime",
	ENDTIME = "EndTime",
	PERCENT = "RemainingPercent",
	REMAINING = "RemainingDuration",
	REMAININGDURATION = "RemainingDuration",
	REMAININGPERCENT = "RemainingPercent",
	START = "StartTime",
	STARTTIME = "StartTime",
	TOTAL = "TotalDuration",
	TOTALDURATION = "TotalDuration",
}

local function copyDefaultTable(source)
	local target = {}
	for key, value in pairs(source or EMPTY_TABLE) do
		if type(value) == "table" then
			target[key] = copyDefaultTable(value)
		else
			target[key] = value
		end
	end
	return target
end

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local function roundNumber(value, fallback)
	value = tonumber(value)
	if not value then return fallback end
	return math.floor(value + 0.5)
end

local function normalizeColor(color, fallback)
	fallback = fallback or DEFAULT_TEXT_COLOR
	if type(color) ~= "table" then color = EMPTY_TABLE end
	return {
		r = clamp(color.r or color[1] or fallback.r or fallback[1] or 1, 0, 1),
		g = clamp(color.g or color[2] or fallback.g or fallback[2] or 1, 0, 1),
		b = clamp(color.b or color[3] or fallback.b or fallback[3] or 1, 0, 1),
		a = clamp(color.a or color[4] or fallback.a or fallback[4] or 1, 0, 1),
	}
end

local function normalizeColorBreakpoints(profile)
	local breakpoints = type(profile.colorBreakpoints) == "table" and profile.colorBreakpoints or {}
	local normalized = {}
	local count = roundNumber(profile.colorBreakpointCount, 0)
	count = clamp(count, 0, MAX_COLOR_BREAKPOINTS)
	for i = 1, MAX_COLOR_BREAKPOINTS do
		local breakpoint = type(breakpoints[i]) == "table" and breakpoints[i] or EMPTY_TABLE
		normalized[i] = {
			seconds = clamp(breakpoint.seconds or i * 5, 1, 3600),
			color = normalizeColor(breakpoint.color, DEFAULT_TEXT_COLOR),
		}
	end
	profile.colorBreakpointCount = count
	profile.colorBreakpoints = normalized
end

local function trimProfileName(name)
	if type(name) ~= "string" then return nil end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then return nil end
	return name
end

local function isConfigKey(key)
	return DurationText.defaults[key] ~= nil
end

local function createProfileStore(defaults)
	local store = {
		activeProfile = DEFAULT_PROFILE_KEY,
		editProfile = DEFAULT_PROFILE_KEY,
		profileNames = {},
		profileOrder = {},
		profiles = {},
	}
	for _, key in ipairs(DurationText.profileOrder) do
		local profileDefaults = defaults and defaults[key] or nil
		store.profiles[key] = copyDefaultTable(profileDefaults)
		store.profileOrder[#store.profileOrder + 1] = key
	end
	return store
end

local function normalizeProfileConfig(profile, defaults)
	if type(profile) ~= "table" then profile = {} end
	defaults = defaults or DurationText.defaults
	for key, value in pairs(defaults) do
		if profile[key] == nil then
			profile[key] = type(value) == "table" and copyDefaultTable(value) or value
		end
	end
	for key, value in pairs(DurationText.defaults) do
		if profile[key] == nil then
			profile[key] = type(value) == "table" and copyDefaultTable(value) or value
		end
	end
	for key in pairs(profile) do
		if not isConfigKey(key) then profile[key] = nil end
	end
	normalizeColorBreakpoints(profile)
	return profile
end

local function normalizeProfileKey(key)
	if type(key) ~= "string" then return nil end
	key = key:gsub("^%s+", ""):gsub("%s+$", ""):upper()
	if key == "" then return nil end
	return key
end

local function profileKeyFromName(name)
	name = trimProfileName(name)
	if not name then return nil end
	return name:upper()
end

local function hasOrderKey(order, key)
	if type(order) ~= "table" then return false end
	for i = 1, #order do
		if order[i] == key then return true end
	end
	return false
end

local function removeOrderKey(order, key)
	if type(order) ~= "table" then return end
	for i = #order, 1, -1 do
		if order[i] == key then table.remove(order, i) end
	end
end

local function appendOrderedKey(order, key)
	if type(order) ~= "table" then return end
	if key and not hasOrderKey(order, key) then order[#order + 1] = key end
end

local function getFirstProfileKey(db, excludedKey)
	if type(db) ~= "table" or type(db.profiles) ~= "table" then return nil end
	for _, key in ipairs(db.profileOrder or EMPTY_TABLE) do
		if key ~= excludedKey and type(db.profiles[key]) == "table" then return key end
	end
	for key, profile in pairs(db.profiles) do
		if key ~= excludedKey and type(profile) == "table" then return key end
	end
	return nil
end

local function profileMatches(value, profileKey)
	return normalizeProfileKey(value) == profileKey
end

local function getUsageLabel(path, key)
	path = tostring(path or "")
	key = tostring(key or "")
	if path:find("^cooldownPanels%.panels%.[^%.]+%.entries%.") then return "durationTextUsageCooldownPanelEntries" end
	if path:find("^cooldownPanels%.panels%.") and key == "durationTextProfile" then return "durationTextUsageCooldownPanelDefaults" end
	if path:find("^cooldownPanels%.panels%.") and key == "barDurationTextProfile" then return "durationTextUsageCooldownPanelDefaults" end
	if key == "skinnerDefaultAuraDurationTextProfile" or key == "skinnerDefaultDebuffAuraDurationTextProfile" then return "durationTextUsageDefaultAuraContainers" end
	if key == "mythicPlusBRTrackerDurationTextProfile" then return "durationTextUsageBRTracker" end
	if key == "mythicPlusBloodlustTrackerDurationTextProfile" then return "durationTextUsageBloodlustTracker" end
	if path:find("^personalResourceBarSettings") then return "durationTextUsageResourceBarsPersonal" end
	if path:find("^globalResourceBarSettings") then return "durationTextUsageResourceBarsGlobal" end
	if path:find("^sharedResourceBarSettings") then return "durationTextUsageResourceBarsShared" end
	if path:find("%.auras%.") and key == "durationTextProfile" then return "durationTextUsageUnitFrameAuras" end
	if key == "barDurationTextProfile" then return "durationTextUsageCooldownPanels" end
	if key == "durationTextProfile" then return "durationTextUsageResourceBars" end
	return path ~= "" and path or key
end

local function addUsage(usages, label)
	usages.count = (usages.count or 0) + 1
	usages.byLabel = usages.byLabel or {}
	usages.order = usages.order or {}
	if not usages.byLabel[label] then usages.order[#usages.order + 1] = label end
	usages.byLabel[label] = (usages.byLabel[label] or 0) + 1
end

local function scanDurationTextProfileFields(root, profileKey, replacementKey, usages)
	if type(root) ~= "table" then return 0 end
	local changed = 0
	local seen = {}
	local function walk(tbl, path)
		if type(tbl) ~= "table" or seen[tbl] then return end
		seen[tbl] = true
		for key, value in pairs(tbl) do
			if tbl == root and key == "durationText" then
				-- The profile definitions themselves are not consumer references.
			elseif
				(
					key == "barDurationTextProfile"
					or key == "durationTextProfile"
					or key == "skinnerDefaultAuraDurationTextProfile"
					or key == "skinnerDefaultDebuffAuraDurationTextProfile"
					or key == "mythicPlusBRTrackerDurationTextProfile"
					or key == "mythicPlusBloodlustTrackerDurationTextProfile"
				) and profileMatches(value, profileKey)
			then
				addUsage(usages, getUsageLabel(path, key))
				if replacementKey then
					tbl[key] = replacementKey
					changed = changed + 1
				end
			elseif type(value) == "table" then
				local childPath = path ~= "" and (path .. "." .. tostring(key)) or tostring(key)
				walk(value, childPath)
			end
		end
	end
	walk(root, "")
	return changed
end

local function migrateBuiltinDurationTextCooldownStyle(db)
	local changed = false
	for _, key in ipairs(DurationText.profileOrder) do
		local profile = db.profiles and db.profiles[key] or nil
		local defaults = DurationText.profileDefaults[key]
		if type(profile) == "table" and defaults then
			for _, field in ipairs({ "millisecondsThreshold" }) do
				if profile[field] ~= defaults[field] then
					profile[field] = defaults[field]
					changed = true
				end
			end
		end
	end
	db[BUILTIN_COOLDOWN_STYLE_MIGRATION_FLAG] = true
	return changed
end

local function normalizeKey(value)
	if type(value) ~= "string" then return nil end
	value = value:gsub("[_%-%s]", ""):upper()
	if value == "ONELETTER" then return "ONE_LETTER" end
	if value == "STRIPIGNORELOCALE" then return "STRIP_IGNORE_LOCALE" end
	return value
end

local function getEnumValue(enumTable, key, fallback)
	if type(key) == "number" then return key end
	key = normalizeKey(key)
	if not key then return nil end
	if enumTable then
		local enumKey = key:gsub("_(%a)", function(letter) return letter end):lower()
		enumKey = enumKey:gsub("^%l", string.upper)
		enumKey = enumKey:gsub("(%l)(%u)", "%1%2")
		if key == "ONE_LETTER" then enumKey = "OneLetter" end
		if key == "STRIP_IGNORE_LOCALE" then enumKey = "StripIgnoreLocale" end
		if key == "SECONDS" then enumKey = "Seconds" end
		if key == "MINUTES" then enumKey = "Minutes" end
		if key == "HOURS" then enumKey = "Hours" end
		if key == "DAYS" then enumKey = "Days" end
		if key == "TRUNCATE" then enumKey = "Truncate" end
		if key == "PRESERVE" then enumKey = "Preserve" end
		if key == "STRIP" then enumKey = "Strip" end
		if key == "NONE" then enumKey = "None" end
		if enumTable[enumKey] ~= nil then return enumTable[enumKey] end
	end
	return fallback and fallback[key] or nil
end

local function getSecondsFormatterAPI()
	local stringUtil = _G.C_StringUtil
	if stringUtil and stringUtil.CreateSecondsFormatter then return stringUtil end
	return nil
end

local function getNumericRuleFormatterAPI()
	local stringUtil = _G.C_StringUtil
	if stringUtil and stringUtil.CreateNumericRuleFormatter then return stringUtil end
	return nil
end

local function getDurationTextBindingAPI()
	local durationUtil = _G.C_DurationUtil
	if durationUtil and durationUtil.CreateDurationTextBinding then return durationUtil end
	return nil
end

local function getDurationTextBindingStore(owner, create)
	if type(owner) ~= "table" then return nil end
	local store = owner._eqolDurationTextBindings
	if not store and create then
		store = {}
		owner._eqolDurationTextBindings = store
	end
	return store
end

local function setDurationTextBindingEnabled(binding, enabled)
	if not binding then return false end
	if binding.SetEnabled then
		binding:SetEnabled(enabled == true)
	elseif enabled == true and binding.Enable then
		binding:Enable()
	elseif binding.Disable then
		binding:Disable()
	end
	return true
end

local function releaseDurationTextBinding(binding, clearText)
	if not binding then return false end
	local fontString = binding.GetFontString and binding:GetFontString() or nil
	if binding.Disable then binding:Disable() end
	if binding.SetToDefaults then binding:SetToDefaults() end
	if clearText and fontString and fontString.SetText then fontString:SetText("") end
	return true
end

function DurationText:InitDB()
	addon.db = addon.db or {}
	addon.dbDefaults = addon.dbDefaults or {}
	local existingDB = addon.db.durationText
	if self.initializedDB == existingDB and type(existingDB) == "table" and type(existingDB.profiles) == "table" and type(addon.dbDefaults.durationText) == "table" then return end

	addon.dbDefaults.durationText = createProfileStore(self.profileDefaults)
	if type(addon.db.durationText) ~= "table" or type(addon.db.durationText.profiles) ~= "table" then addon.db.durationText = createProfileStore(self.profileDefaults) end

	local db = addon.db.durationText
	if type(db.profileNames) ~= "table" then db.profileNames = {} end
	if type(db.profileOrder) ~= "table" then db.profileOrder = {} end
	db.activeProfile = normalizeProfileKey(db.activeProfile) or DEFAULT_PROFILE_KEY
	db.editProfile = normalizeProfileKey(db.editProfile) or db.activeProfile
	for _, key in ipairs(self.profileOrder) do
		if type(db.profiles[key]) ~= "table" then db.profiles[key] = copyDefaultTable(self.profileDefaults[key] or self.defaults) end
		appendOrderedKey(db.profileOrder, key)
	end
	for key, profile in pairs(db.profiles) do
		local normalizedKey = normalizeProfileKey(key)
		if normalizedKey and normalizedKey ~= key then
			db.profiles[normalizedKey] = normalizeProfileConfig(db.profiles[normalizedKey] or profile, self.profileDefaults[normalizedKey])
			if db.profileNames[key] and not db.profileNames[normalizedKey] then db.profileNames[normalizedKey] = db.profileNames[key] end
			db.profileNames[key] = nil
			removeOrderKey(db.profileOrder, key)
			appendOrderedKey(db.profileOrder, normalizedKey)
			db.profiles[key] = nil
		elseif not normalizedKey then
			db.profiles[key] = nil
		else
			db.profiles[key] = normalizeProfileConfig(profile, self.profileDefaults[key])
			appendOrderedKey(db.profileOrder, key)
		end
	end
	for key in pairs(db.profileNames) do
		if not db.profiles[key] then db.profileNames[key] = nil end
	end
	for i = #db.profileOrder, 1, -1 do
		if not db.profiles[db.profileOrder[i]] then table.remove(db.profileOrder, i) end
	end
	if not getFirstProfileKey(db) then
		db.profiles[DEFAULT_PROFILE_KEY] = copyDefaultTable(self.profileDefaults[DEFAULT_PROFILE_KEY] or self.defaults)
		appendOrderedKey(db.profileOrder, DEFAULT_PROFILE_KEY)
	end
	if not db.profiles[db.activeProfile] then db.activeProfile = DEFAULT_PROFILE_KEY end
	if not db.profiles[db.activeProfile] then db.activeProfile = getFirstProfileKey(db) end
	if not db.profiles[db.editProfile] then db.editProfile = db.activeProfile or getFirstProfileKey(db) end
	if db[BUILTIN_COOLDOWN_STYLE_MIGRATION_FLAG] ~= true then
		if migrateBuiltinDurationTextCooldownStyle(db) then self:Invalidate() end
	end
	self.initializedDB = db
end

function DurationText:Invalidate()
	self.formatterCache = {}
	self.version = (self.version or 0) + 1
end

function DurationText:GetProfileKey(profileKey)
	self:InitDB()
	profileKey = normalizeProfileKey(profileKey) or addon.db.durationText.activeProfile or DEFAULT_PROFILE_KEY
	if not addon.db.durationText.profiles[profileKey] then
		profileKey = addon.db.durationText.profiles[DEFAULT_PROFILE_KEY] and DEFAULT_PROFILE_KEY or getFirstProfileKey(addon.db.durationText)
	end
	return profileKey
end

function DurationText:GetProfileConfig(profileKey)
	self:InitDB()
	local key = self:GetProfileKey(profileKey)
	return addon.db.durationText.profiles[key], key
end

function DurationText:GetGlobalConfig()
	return self:GetProfileConfig()
end

function DurationText:GetEffectiveConfig(scopeConfig)
	if type(scopeConfig) == "string" then return self:GetProfileConfig(scopeConfig) end
	local globalConfig = self:GetProfileConfig(type(scopeConfig) == "table" and scopeConfig.profileKey or nil)
	if type(scopeConfig) ~= "table" or scopeConfig.useGlobal ~= false then return globalConfig end
	local effective = {}
	for key, value in pairs(globalConfig) do
		effective[key] = value
	end
	for key, value in pairs(scopeConfig) do
		if key ~= "useGlobal" and key ~= "profileKey" and value ~= nil then effective[key] = value end
	end
	return effective
end

function DurationText:GetProfileLabel(profileKey)
	profileKey = normalizeProfileKey(profileKey) or DEFAULT_PROFILE_KEY
	local db = addon.db and addon.db.durationText or nil
	if db and db.profileNames and db.profileNames[profileKey] then return db.profileNames[profileKey] end
	local L = LibStub and LibStub("AceLocale-3.0"):GetLocale(addonName, true) or nil
	if profileKey == "MINIMAL" then return L and L["durationTextProfileMinimal"] or "Minimal" end
	if profileKey == "PRECISE" then return L and L["durationTextProfilePrecise"] or "Precise" end
	return profileKey
end

function DurationText:GetProfileOptions()
	self:InitDB()
	local options = {}
	for _, key in ipairs(addon.db.durationText.profileOrder or EMPTY_TABLE) do
		if addon.db.durationText.profiles[key] then options[#options + 1] = { value = key, label = self:GetProfileLabel(key) } end
	end
	return options
end

function DurationText:GetProfileDropdownData()
	self:InitDB()
	local list, order = {}, {}
	for _, option in ipairs(self:GetProfileOptions()) do
		list[option.value] = option.label
		order[#order + 1] = option.value
	end
	return list, order
end

function DurationText:IsProfileProtected(profileKey)
	profileKey = normalizeProfileKey(profileKey)
	return profileKey and self.protectedProfileKeys and self.protectedProfileKeys[profileKey] == true or false
end

function DurationText:GetEditProfileKey()
	self:InitDB()
	return self:GetProfileKey(addon.db.durationText.editProfile)
end

function DurationText:SetEditProfileKey(profileKey)
	self:InitDB()
	profileKey = self:GetProfileKey(profileKey)
	addon.db.durationText.editProfile = profileKey
	self:Invalidate()
end

function DurationText:GetProfileValue(profileKey, key)
	local profile = self:GetProfileConfig(profileKey)
	return profile and profile[key] or nil
end

function DurationText:SetProfileValue(profileKey, key, value)
	if not isConfigKey(key) then return end
	local profile = self:GetProfileConfig(profileKey)
	if not profile then return end
	profile[key] = value
	normalizeColorBreakpoints(profile)
	self:Invalidate()
end

function DurationText:ResetProfile(profileKey)
	self:InitDB()
	profileKey = self:GetProfileKey(profileKey)
	addon.db.durationText.profiles[profileKey] = copyDefaultTable(self.profileDefaults[profileKey] or self.defaults)
	self:Invalidate()
end

function DurationText:GetCreateProfileKey(name)
	return profileKeyFromName(name)
end

function DurationText:CreateProfile(name, sourceProfileKey)
	self:InitDB()
	name = trimProfileName(name)
	local profileKey = profileKeyFromName(name)
	if not profileKey then return false, "INVALID_NAME" end
	if addon.db.durationText.profiles[profileKey] then return false, "EXISTS", profileKey end
	local source = sourceProfileKey and self:GetProfileConfig(sourceProfileKey) or nil
	addon.db.durationText.profiles[profileKey] = copyDefaultTable(source or self.defaults)
	addon.db.durationText.profileNames[profileKey] = name
	appendOrderedKey(addon.db.durationText.profileOrder, profileKey)
	addon.db.durationText.editProfile = profileKey
	self:Invalidate()
	return true, profileKey
end

function DurationText:CopyProfile(sourceProfileKey, name)
	return self:CreateProfile(name, sourceProfileKey)
end

function DurationText:GetReplacementProfileKey(profileKey)
	self:InitDB()
	profileKey = self:GetProfileKey(profileKey)
	return getFirstProfileKey(addon.db.durationText, profileKey)
end

function DurationText:GetProfileUsage(profileKey)
	self:InitDB()
	profileKey = self:GetProfileKey(profileKey)
	local usages = { count = 0 }
	scanDurationTextProfileFields(addon.db, profileKey, nil, usages)
	return usages
end

function DurationText:RefreshConsumers()
	local aura = addon.Aura
	local cooldownPanels = aura and aura.CooldownPanels or nil
	if cooldownPanels and cooldownPanels.RefreshAllPanels then cooldownPanels:RefreshAllPanels(true) end
	local resourceBars = aura and aura.ResourceBars or nil
	if resourceBars and resourceBars.QueueRefresh then resourceBars.QueueRefresh(nil, { force = true, structural = true }) elseif resourceBars and resourceBars.Refresh then resourceBars.Refresh() end
	local defaultAuras = addon.DefaultAuraContainers
	if defaultAuras and defaultAuras.functions and defaultAuras.functions.RefreshDefaultAuraIconSkin then defaultAuras.functions.RefreshDefaultAuraIconSkin() end
	local unitFrames = aura and aura.UF or nil
	if unitFrames and unitFrames.Refresh then unitFrames.Refresh() end
	local groupFrames = unitFrames and unitFrames.GroupFrames or nil
	if groupFrames and groupFrames.RefreshChangedUnitButtons then groupFrames:RefreshChangedUnitButtons() end
	local mythicPlus = addon.MythicPlus and addon.MythicPlus.functions
	if mythicPlus then
		if mythicPlus.createBRFrame then mythicPlus.createBRFrame() end
		if mythicPlus.createBloodlustFrame then mythicPlus.createBloodlustFrame() end
		if mythicPlus.refreshBloodlustTracker then mythicPlus.refreshBloodlustTracker(false) end
	end
end

function DurationText:DeleteProfile(profileKey, replacementKey)
	self:InitDB()
	profileKey = self:GetProfileKey(profileKey)
	if self:IsProfileProtected(profileKey) then return false, "PROTECTED_PROFILE" end
	replacementKey = self:GetProfileKey(replacementKey or self:GetReplacementProfileKey(profileKey))
	if profileKey == replacementKey then replacementKey = self:GetReplacementProfileKey(profileKey) end
	if not replacementKey then return false, "LAST_PROFILE" end
	local usages = self:GetProfileUsage(profileKey)
	local changed = scanDurationTextProfileFields(addon.db, profileKey, replacementKey, { count = 0 })
	addon.db.durationText.profiles[profileKey] = nil
	addon.db.durationText.profileNames[profileKey] = nil
	removeOrderKey(addon.db.durationText.profileOrder, profileKey)
	if addon.db.durationText.activeProfile == profileKey then addon.db.durationText.activeProfile = replacementKey end
	if addon.db.durationText.editProfile == profileKey then addon.db.durationText.editProfile = replacementKey end
	self:Invalidate()
	self:RefreshConsumers()
	return true, replacementKey, usages, changed
end

function DurationText:GetIntervalValue(key)
	return getEnumValue(_G.Enum and _G.Enum.SecondsFormatterInterval, key, INTERVAL_FALLBACK)
end

function DurationText:GetAbbreviationValue(key)
	return getEnumValue(_G.Enum and _G.Enum.SecondsFormatterAbbreviation, key, ABBREVIATION_FALLBACK)
end

function DurationText:GetWhitespaceValue(key)
	return getEnumValue(_G.Enum and _G.Enum.SecondsFormatterIntervalWhitespace, key, WHITESPACE_FALLBACK)
end

function DurationText:GetRoundingValue(key)
	return getEnumValue(_G.Enum and _G.Enum.NumericRuleFormatRounding, key, ROUNDING_FALLBACK)
end

function DurationText:GetCacheKey(config)
	config = config or self:GetGlobalConfig()
	local parts = {
		tostring(config.millisecondsThreshold),
		tostring(config.colorBreakpointCount),
	}
	local count = roundNumber(config.colorBreakpointCount, 0)
	count = clamp(count, 0, MAX_COLOR_BREAKPOINTS)
	for i = 1, count do
		local breakpoint = type(config.colorBreakpoints) == "table" and config.colorBreakpoints[i] or nil
		local color = breakpoint and normalizeColor(breakpoint.color, DEFAULT_TEXT_COLOR) or DEFAULT_TEXT_COLOR
		parts[#parts + 1] = table.concat({
			tostring(breakpoint and breakpoint.seconds or ""),
			tostring(color.r),
			tostring(color.g),
			tostring(color.b),
		}, ",")
	end
	return table.concat(parts, "|")
end

function DurationText:GetMaxColorBreakpoints()
	return MAX_COLOR_BREAKPOINTS
end

function DurationText:GetDefaultTextColor()
	return copyDefaultTable(DEFAULT_TEXT_COLOR)
end

function DurationText:GetProfileColorBreakpoint(profileKey, index)
	local profile = self:GetProfileConfig(profileKey)
	index = roundNumber(index, 1)
	if not profile or index < 1 or index > MAX_COLOR_BREAKPOINTS then return nil end
	normalizeColorBreakpoints(profile)
	return profile.colorBreakpoints[index]
end

function DurationText:SetProfileColorBreakpointValue(profileKey, index, field, value)
	local profile = self:GetProfileConfig(profileKey)
	index = roundNumber(index, 1)
	if not profile or index < 1 or index > MAX_COLOR_BREAKPOINTS then return false end
	normalizeColorBreakpoints(profile)
	local breakpoint = profile.colorBreakpoints[index]
	if field == "seconds" then
		local seconds = clamp(value, 1, 3600)
		if breakpoint.seconds == seconds then return false end
		breakpoint.seconds = seconds
	elseif field == "color" then
		local color = normalizeColor(value, DEFAULT_TEXT_COLOR)
		local oldColor = normalizeColor(breakpoint.color, DEFAULT_TEXT_COLOR)
		if oldColor.r == color.r and oldColor.g == color.g and oldColor.b == color.b and oldColor.a == color.a then return false end
		breakpoint.color = color
	else
		return false
	end
	self:Invalidate()
	return true
end

local function colorEscapePrefix(color)
	color = normalizeColor(color, DEFAULT_TEXT_COLOR)
	local r = clamp(color.r, 0, 1)
	local g = clamp(color.g, 0, 1)
	local b = clamp(color.b, 0, 1)
	if r >= 0.999 and g >= 0.999 and b >= 0.999 then return "" end
	return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function formatWithColor(format, color)
	local prefix = colorEscapePrefix(color)
	if prefix == "" then return format end
	return prefix .. format .. "|r"
end

local function collectColorBands(config)
	local count = roundNumber(config and config.colorBreakpointCount, 0)
	count = clamp(count, 0, MAX_COLOR_BREAKPOINTS)
	if count <= 0 or type(config.colorBreakpoints) ~= "table" then return nil end
	local bands = {}
	for i = 1, count do
		local breakpoint = config.colorBreakpoints[i]
		if type(breakpoint) == "table" then
			bands[#bands + 1] = {
				seconds = clamp(breakpoint.seconds, 1, 3600),
				color = normalizeColor(breakpoint.color, DEFAULT_TEXT_COLOR),
			}
		end
	end
	table.sort(bands, function(a, b) return a.seconds < b.seconds end)
	return #bands > 0 and bands or nil
end

local function getColorForThreshold(threshold, bands)
	if not bands then return DEFAULT_TEXT_COLOR end
	for i = 1, #bands do
		if threshold < bands[i].seconds then return bands[i].color end
	end
	return DEFAULT_TEXT_COLOR
end

local function addUniqueThreshold(thresholds, threshold)
	threshold = tonumber(threshold)
	if not threshold or threshold < 0 then return end
	threshold = math.floor(threshold * 10 + 0.5) / 10
	thresholds.seen = thresholds.seen or {}
	if thresholds.seen[threshold] then return end
	thresholds.seen[threshold] = true
	thresholds[#thresholds + 1] = threshold
end

local function createNumericBreakpoint(threshold, decimalThreshold, rounding, color)
	if decimalThreshold and decimalThreshold > 0 and threshold < decimalThreshold then
		return {
			threshold = threshold,
			step = 0.1,
			format = formatWithColor("%.1f", color),
			rounding = rounding.nearest,
		}
	end
	if threshold < 60 then
		return {
			threshold = threshold,
			step = 1,
			format = formatWithColor("%.0f", color),
			rounding = rounding.down,
		}
	end
	return {
		threshold = threshold,
		step = 1,
		rounding = rounding.down,
		format = formatWithColor("%d:%02d", color),
		components = {
			{ div = 60, step = 1, rounding = rounding.down },
			{ mod = 60, step = 1, rounding = rounding.down },
		},
	}
end

function DurationText:CreateSecondsFormatter(config)
	local api = getSecondsFormatterAPI()
	if not api then return nil end
	config = config or self:GetGlobalConfig()
	local formatter = api.CreateSecondsFormatter()
	if formatter.Reset then formatter:Reset() end
	if formatter.SetDefaultAbbreviation then formatter:SetDefaultAbbreviation(self:GetAbbreviationValue("ONE_LETTER")) end
	if formatter.SetMillisecondsThreshold then formatter:SetMillisecondsThreshold(tonumber(config.millisecondsThreshold) or self.defaults.millisecondsThreshold) end
	if formatter.SetApproximationSeconds then formatter:SetApproximationSeconds(0) end
	if formatter.SetDesiredUnitCount then formatter:SetDesiredUnitCount(1) end
	if formatter.SetMinInterval then formatter:SetMinInterval(self:GetIntervalValue(MIN_INTERVAL)) end
	if formatter.SetMaxInterval then formatter:SetMaxInterval(self:GetIntervalValue(MAX_INTERVAL)) end
	if formatter.SetCanRoundUpIntervals then formatter:SetCanRoundUpIntervals(true) end
	if formatter.SetCanRoundUpLastUnit then formatter:SetCanRoundUpLastUnit(false) end
	if formatter.SetConvertToLower then formatter:SetConvertToLower(true) end
	if formatter.SetStripIntervalWhitespace then formatter:SetStripIntervalWhitespace(self:GetWhitespaceValue("STRIP")) end
	return formatter
end

function DurationText:CreateBindingFormatter(config)
	local api = getNumericRuleFormatterAPI()
	if not api then return self:CreateSecondsFormatter(config) end
	config = config or self:GetGlobalConfig()
	local formatter = api.CreateNumericRuleFormatter()
	if formatter.ClearBreakpoints then formatter:ClearBreakpoints() end
	local decimalThreshold = tonumber(config.millisecondsThreshold) or self.defaults.millisecondsThreshold
	local rounding = {
		down = self:GetRoundingValue("DOWN") or 2,
	}
	rounding.nearest = self:GetRoundingValue("NEAREST") or rounding.down
	local colorBands = collectColorBands(config)
	local thresholds = {}
	addUniqueThreshold(thresholds, 0)
	if decimalThreshold and decimalThreshold > 0 then addUniqueThreshold(thresholds, decimalThreshold) end
	addUniqueThreshold(thresholds, 60)
	if colorBands then
		local previous = 0
		for i = 1, #colorBands do
			addUniqueThreshold(thresholds, previous)
			addUniqueThreshold(thresholds, colorBands[i].seconds)
			previous = colorBands[i].seconds
		end
	end
	table.sort(thresholds)
	local breakpoints = {}
	for i = 1, #thresholds do
		local threshold = thresholds[i]
		breakpoints[#breakpoints + 1] = createNumericBreakpoint(threshold, decimalThreshold, rounding, getColorForThreshold(threshold, colorBands))
	end
	if formatter.SetBreakpoints then
		formatter:SetBreakpoints(breakpoints)
	elseif formatter.AddBreakpoint then
		for i = 1, #breakpoints do
			formatter:AddBreakpoint(breakpoints[i])
		end
	end
	return formatter
end

function DurationText:GetSecondsFormatter(config)
	config = config or self:GetGlobalConfig()
	local cacheKey = self:GetCacheKey(config)
	self.formatterCache = self.formatterCache or {}
	if not self.formatterCache[cacheKey] then self.formatterCache[cacheKey] = self:CreateSecondsFormatter(config) end
	return self.formatterCache[cacheKey]
end

function DurationText:GetBindingFormatter(config)
	config = config or self:GetGlobalConfig()
	local cacheKey = "binding|" .. self:GetCacheKey(config)
	self.formatterCache = self.formatterCache or {}
	if not self.formatterCache[cacheKey] then
		self.formatterCache[cacheKey] = self:CreateBindingFormatter(config)
	end
	return self.formatterCache[cacheKey]
end

function DurationText:FormatSeconds(seconds, config, abbreviation)
	config = self:GetEffectiveConfig(config)
	local formatter = self:GetSecondsFormatter(config)
	if formatter and formatter.Format then return formatter:Format(seconds, abbreviation) end
	if formatter and formatter.FormatNumber then return formatter:FormatNumber(seconds or 0) end
	return tostring(seconds or "")
end

function DurationText:IsDurationTextBindingSupported()
	return getDurationTextBindingAPI() ~= nil
end

function DurationText:GetDurationTextBindingProperty(property)
	if type(property) == "number" then return property end
	if type(property) ~= "string" then return nil end
	local normalized = property:gsub("[_%-%s]", ""):upper()
	local key = DURATION_TEXT_BINDING_PROPERTY_ALIASES[normalized] or property
	local enum = _G.Enum and _G.Enum.DurationTextBindingProperty or nil
	if enum and enum[key] ~= nil then return enum[key] end
	return DURATION_TEXT_BINDING_PROPERTIES[key]
end

function DurationText:CreateFormatComponent(property, formatter)
	local resolvedProperty = self:GetDurationTextBindingProperty(property)
	if resolvedProperty == nil or formatter == nil then return nil end
	return {
		property = resolvedProperty,
		formatter = formatter,
	}
end

function DurationText:CreateRemainingDurationComponent(config)
	config = self:GetEffectiveConfig(config)
	local formatter = self:GetBindingFormatter(config)
	return self:CreateFormatComponent("RemainingDuration", formatter)
end

function DurationText:CreateTotalDurationComponent(config)
	config = self:GetEffectiveConfig(config)
	local formatter = self:GetBindingFormatter(config)
	return self:CreateFormatComponent("TotalDuration", formatter)
end

function DurationText:GetBinding(owner, key)
	local store = getDurationTextBindingStore(owner, false)
	return store and store[key or "default"] or nil
end

function DurationText:EnsureBinding(owner, key)
	local durationUtil = getDurationTextBindingAPI()
	if not durationUtil then return nil, false end
	local store = getDurationTextBindingStore(owner, true)
	if not store then return nil, false end
	key = key or "default"
	local binding = store[key]
	if not binding then
		binding = durationUtil.CreateDurationTextBinding()
		store[key] = binding
	end
	return binding, true
end

function DurationText:ReleaseBinding(owner, key, clearText)
	local store = getDurationTextBindingStore(owner, false)
	if not store then return false end
	key = key or "default"
	local binding = store[key]
	store[key] = nil
	return releaseDurationTextBinding(binding, clearText)
end

function DurationText:ReleaseBindings(owner, clearText)
	local store = getDurationTextBindingStore(owner, false)
	if not store then return false end
	for key, binding in pairs(store) do
		releaseDurationTextBinding(binding, clearText)
		store[key] = nil
	end
	return true
end

function DurationText:SetBindingEnabled(owner, key, enabled)
	return setDurationTextBindingEnabled(self:GetBinding(owner, key), enabled == true)
end

function DurationText:UpdateBinding(owner, key)
	local binding = self:GetBinding(owner, key)
	if binding and binding.UpdateFontString then
		binding:UpdateFontString()
		return true
	end
	return false
end

function DurationText:GetBindingState(owner, key)
	local binding = self:GetBinding(owner, key)
	if not binding then return nil end
	return {
		canFormatText = binding.CanFormatText and binding:CanFormatText() or false,
		canUpdateFontString = binding.CanUpdateFontString and binding:CanUpdateFontString() or false,
		duration = binding.GetDuration and binding:GetDuration() or nil,
		enabled = binding.IsEnabled and binding:IsEnabled() or false,
		expiredText = binding.GetExpiredText and binding:GetExpiredText() or nil,
		fontString = binding.GetFontString and binding:GetFontString() or nil,
		hasSecretValues = binding.HasSecretValues and binding:HasSecretValues() or false,
		timeModifier = binding.GetTimeModifier and binding:GetTimeModifier() or nil,
		updateInterval = binding.GetUpdateInterval and binding:GetUpdateInterval() or nil,
		zeroDurationText = binding.GetZeroDurationText and binding:GetZeroDurationText() or nil,
	}
end

function DurationText:ConfigureBinding(owner, key, fontString, durationObject, options)
	options = options or EMPTY_TABLE
	if not (fontString and durationObject) then
		if options.releaseOnMissing ~= false then self:ReleaseBinding(owner, key, options.clearText == true) end
		return nil, false
	end

	local useProfileConfig = options.useProfileConfig ~= false
	local config = useProfileConfig and self:GetEffectiveConfig(options.config or options.profileKey) or EMPTY_TABLE
	local formatter = options.formatter or (useProfileConfig and self:GetBindingFormatter(config)) or nil
	local binding = self:EnsureBinding(owner, key)
	if not binding then return nil, false end
	if options.reset == true and binding.SetToDefaults then binding:SetToDefaults() end
	if binding.SetFontString then binding:SetFontString(fontString) end
	if binding.SetDuration then binding:SetDuration(durationObject) end
	if binding.SetTimeModifier then binding:SetTimeModifier(options.timeModifier or (_G.Enum and _G.Enum.DurationTimeModifier and _G.Enum.DurationTimeModifier.RealTime or 0)) end
	if binding.SetUpdateInterval then binding:SetUpdateInterval(options.updateInterval or BINDING_UPDATE_INTERVAL) end
	if binding.SetZeroDurationText then binding:SetZeroDurationText(options.zeroDurationText ~= nil and options.zeroDurationText or config.zeroDurationText) end
	if binding.SetExpiredText then binding:SetExpiredText(options.expiredText ~= nil and options.expiredText or config.expiredText) end
	if options.textFormat ~= nil and options.components ~= nil and binding.SetTextFormat then
		binding:SetTextFormat(options.textFormat, options.components)
	elseif formatter and binding.SetFormatter then
		binding:SetFormatter(formatter)
	end

	setDurationTextBindingEnabled(binding, options.enabled ~= false)
	if options.updateNow ~= false and binding.UpdateFontString then binding:UpdateFontString() end
	return binding, true
end

function DurationText:BindFontString(fontString, durationObject, options)
	options = options or EMPTY_TABLE
	local owner = options.owner or fontString
	return self:ConfigureBinding(owner, options.key or "default", fontString, durationObject, options)
end

function DurationText:ApplyToCooldownFrame(cooldownFrame, config, options)
	if not cooldownFrame then return false end
	options = options or EMPTY_TABLE
	config = self:GetEffectiveConfig(config)
	if cooldownFrame.SetCountdownFormatter then
		local colorBreakpointCount = roundNumber(config.colorBreakpointCount, 0)
		cooldownFrame:SetCountdownFormatter(colorBreakpointCount > 0 and self:GetBindingFormatter(config) or nil)
	end
	local millisecondsThreshold = tonumber(config.millisecondsThreshold) or 0
	if cooldownFrame.SetCountdownMillisecondsThreshold then cooldownFrame:SetCountdownMillisecondsThreshold(millisecondsThreshold) end
	return true
end

function DurationText:ApplyProfileToCooldownFrame(cooldownFrame, profileKey, options)
	return self:ApplyToCooldownFrame(cooldownFrame, profileKey, options)
end

function DurationText:GetAuraButtonDurationTextOptions(profileKey, options)
	options = options or EMPTY_TABLE
	local config = self:GetEffectiveConfig(profileKey)
	return {
		formatter = options.formatter or self:GetBindingFormatter(config),
		expiredText = options.expiredText ~= nil and options.expiredText or config.expiredText,
		zeroDurationText = options.zeroDurationText ~= nil and options.zeroDurationText or config.zeroDurationText,
		timeModifier = options.timeModifier or (_G.Enum and _G.Enum.DurationTimeModifier and _G.Enum.DurationTimeModifier.RealTime or 0),
		updateInterval = options.updateInterval or BINDING_UPDATE_INTERVAL,
	}
end

function addon.functions.IsDurationTextBindingSupported() return DurationText:IsDurationTextBindingSupported() end
function addon.functions.GetDurationTextBindingProperty(property) return DurationText:GetDurationTextBindingProperty(property) end
function addon.functions.GetDurationTextProfileDropdownData() return DurationText:GetProfileDropdownData() end
function addon.functions.GetDurationTextProfileOptions() return DurationText:GetProfileOptions() end
function addon.functions.GetDurationTextProfileValue(profileKey, key) return DurationText:GetProfileValue(profileKey, key) end
function addon.functions.SetDurationTextProfileValue(profileKey, key, value) return DurationText:SetProfileValue(profileKey, key, value) end
function addon.functions.ResetDurationTextProfile(profileKey) return DurationText:ResetProfile(profileKey) end
function addon.functions.CreateDurationTextProfile(name, sourceProfileKey) return DurationText:CreateProfile(name, sourceProfileKey) end
function addon.functions.CopyDurationTextProfile(sourceProfileKey, name) return DurationText:CopyProfile(sourceProfileKey, name) end
function addon.functions.DeleteDurationTextProfile(profileKey, replacementKey) return DurationText:DeleteProfile(profileKey, replacementKey) end
function addon.functions.GetDurationTextProfileUsage(profileKey) return DurationText:GetProfileUsage(profileKey) end
function addon.functions.CreateDurationTextBindingFormatComponent(property, formatter) return DurationText:CreateFormatComponent(property, formatter) end
function addon.functions.CreateRemainingDurationTextComponent(config) return DurationText:CreateRemainingDurationComponent(config) end
function addon.functions.CreateTotalDurationTextComponent(config) return DurationText:CreateTotalDurationComponent(config) end
function addon.functions.GetDurationTextBinding(owner, key) return DurationText:GetBinding(owner, key) end
function addon.functions.EnsureDurationTextBinding(owner, key) return DurationText:EnsureBinding(owner, key) end
function addon.functions.ReleaseDurationTextBinding(owner, key, clearText) return DurationText:ReleaseBinding(owner, key, clearText) end
function addon.functions.ReleaseDurationTextBindings(owner, clearText) return DurationText:ReleaseBindings(owner, clearText) end
function addon.functions.SetDurationTextBindingEnabled(owner, key, enabled) return DurationText:SetBindingEnabled(owner, key, enabled) end
function addon.functions.UpdateDurationTextBinding(owner, key) return DurationText:UpdateBinding(owner, key) end
function addon.functions.GetDurationTextBindingState(owner, key) return DurationText:GetBindingState(owner, key) end
function addon.functions.ConfigureDurationTextBinding(owner, key, fontString, durationObject, options) return DurationText:ConfigureBinding(owner, key, fontString, durationObject, options) end
function addon.functions.BindDurationText(fontString, durationObject, options) return DurationText:BindFontString(fontString, durationObject, options) end
function addon.functions.ApplyDurationTextProfileToCooldownFrame(cooldownFrame, profileKey, options) return DurationText:ApplyProfileToCooldownFrame(cooldownFrame, profileKey, options) end
function addon.functions.GetAuraButtonDurationTextOptions(profileKey, options) return DurationText:GetAuraButtonDurationTextOptions(profileKey, options) end
