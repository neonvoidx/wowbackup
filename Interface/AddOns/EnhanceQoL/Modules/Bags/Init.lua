-- luacheck: globals C_Bank C_Container C_EquipmentSet
local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

addon.name = addonName
addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}
addon.Bags.Core = addon.Bags.Core or {}
addon.functions = addon.functions or {}

function addon.Bags.IsEnabled()
	return addon.db and addon.db.enableBagsModule == true
end

function addon.Bags.functions.Enable()
	if addon.InitializeSavedVariables then
		addon.InitializeSavedVariables()
	end
	if addon.Bags.functions.EnableMain then
		addon.Bags.functions.EnableMain()
	end
	if addon.Bags.functions.EnableBank and (addon.GetUseIntegratedBank == nil or addon.GetUseIntegratedBank()) then
		addon.Bags.functions.EnableBank()
	elseif addon.Bags.functions.RestoreDefaultBankFrames then
		addon.Bags.functions.RestoreDefaultBankFrames()
	end
end

function addon.Bags.functions.Disable()
	if addon.Bags.functions.HideFrame then
		addon.Bags.functions.HideFrame()
	end
	if addon.Bags.functions.HideBankFrame then
		addon.Bags.functions.HideBankFrame()
	end
end

addon.DB = addon.DB or {}
addon.DB.frame = addon.DB.frame or {}
addon.DB.settings = addon.DB.settings or {}
addon.DB.moneyTracker = addon.DB.moneyTracker or {}
addon.DB.warbandGold = addon.DB.warbandGold or 0
addon.savedVariablesLoaded = addon.savedVariablesLoaded or false
addon.savedVariablesAreNew = addon.savedVariablesAreNew or false

local CATEGORY_MODE_DEFAULTS = {
	customCategories = {},
	customGroups = {},
	hiddenBuiltInCategories = {},
	nextCustomCategoryID = 0,
	nextCustomGroupID = 0,
	nextCustomCategoryNodeID = 0,
	nextCustomCategorySortOrder = 0,
	presetVersionApplied = 0,
}

local INTEGRATED_DEFAULTS_VERSION = 2
local TEXT_ELEMENT_INHERIT_KEY = "__inherit__"
local TEXT_ELEMENT_ORDER = {
	"categoryHeader",
	"subcategoryHeader",
	"overlays",
	"stackCount",
}
local TEXT_ELEMENT_DEFINITIONS = {
	categoryHeader = {
		labelKey = "settingsTextElementCategoryHeader",
		size = 16,
	},
	subcategoryHeader = {
		labelKey = "settingsTextElementSubcategoryHeader",
		size = 16,
	},
	overlays = {
		labelKey = "settingsTextElementOverlays",
		size = 13,
	},
	stackCount = {
		labelKey = "settingsTextElementStackCount",
		size = 13,
	},
}
local STACK_COUNT_ANCHOR_ORDER = {
	"TOPLEFT",
	"TOP",
	"TOPRIGHT",
	"LEFT",
	"CENTER",
	"RIGHT",
	"BOTTOMLEFT",
	"BOTTOM",
	"BOTTOMRIGHT",
}
local STACK_COUNT_ANCHOR_LOOKUP = {}
for _, anchorID in ipairs(STACK_COUNT_ANCHOR_ORDER) do
	STACK_COUNT_ANCHOR_LOOKUP[anchorID] = true
end

local defaultSettings = {
	manualVisible = false,
	oneBagMode = false,
	oneBagFreeSlotsAtEnd = false,
	showCategories = true,
	compactCategoryLayout = true,
	compactCategoryGap = 8,
	categoryTreeView = false,
	categoryTreeIndent = 14,
	showCloseButton = true,
	clearNewItemsOnHeaderClick = false,
	rememberLastBankTab = true,
	useIntegratedBank = true,
	combineFreeSlots = true,
	showFreeSlots = true,
	combineUnstackableItems = true,
	outerPadding = 10,
	headerPadding = 0,
	outsideHeaderPadding = 0,
	outsideFooterPadding = 10,
	insideHorizontalPadding = 10,
	insideTopPadding = 10,
	insideBottomPadding = 0,
	itemScale = 100,
	maxColumns = 10,
	showGold = true,
	showCurrencies = true,
	showFooterSlotSummary = false,
	moneyFormat = "symbols",
	freeSlotDisplayMode = "icons",
	freeSlotNormalColor = { 0.18, 0.12, 0.06 },
	freeSlotReagentColor = { 0.36, 0.27, 0.08 },
	footerSummaryPadding = 0,
	skinPreset = "default",
	iconShape = "default",
	frameBackground = "parchment",
	frameBorderOffset = 0,
	frameBorderSize = 1,
	frameBorderTexture = "__skin__",
	frameBackgroundColor = { 0.03, 0.03, 0.04 },
	frameBackgroundOpacity = 100,
	showWatchedCurrencies = true,
	showTrackedCurrencyCharacterBreakdown = false,
	trackedCurrencyTooltipTotalPosition = "top",
	trackedCurrencyTooltipNameColorMode = "class",
	trackedCurrencyTooltipCountColorMode = "default",
	activeCategoryMode = "basic",
	modeOnboardingComplete = false,
	categoryModes = {
		basic = CATEGORY_MODE_DEFAULTS,
		advanced = CATEGORY_MODE_DEFAULTS,
	},
	collapsedSections = {},
	trackedCurrencyIDs = {},
	textAppearance = {
		font = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__",
		size = 15,
		overlaySize = 15,
		outline = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__",
		subcategoryFullLabels = true,
		elements = {
			categoryHeader = {
				font = TEXT_ELEMENT_INHERIT_KEY,
				size = TEXT_ELEMENT_DEFINITIONS.categoryHeader.size,
				case = "default",
				outline = TEXT_ELEMENT_INHERIT_KEY,
			},
			subcategoryHeader = {
				font = TEXT_ELEMENT_INHERIT_KEY,
				size = TEXT_ELEMENT_DEFINITIONS.subcategoryHeader.size,
				case = "default",
				outline = TEXT_ELEMENT_INHERIT_KEY,
			},
			overlays = {
				font = TEXT_ELEMENT_INHERIT_KEY,
				size = TEXT_ELEMENT_DEFINITIONS.overlays.size,
				case = "default",
				outline = TEXT_ELEMENT_INHERIT_KEY,
			},
			stackCount = {
				font = TEXT_ELEMENT_INHERIT_KEY,
				size = TEXT_ELEMENT_DEFINITIONS.stackCount.size,
				case = "default",
				outline = TEXT_ELEMENT_INHERIT_KEY,
				anchor = "BOTTOMRIGHT",
			},
		},
	},
}

local TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_OPTIONS = {
	{
		value = "top",
		labelKey = "settingsTrackedCurrencyTooltipTotalTop",
	},
	{
		value = "bottom",
		labelKey = "settingsTrackedCurrencyTooltipTotalBottom",
	},
}

local TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_LOOKUP = {}
for _, option in ipairs(TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_OPTIONS) do
	TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_LOOKUP[option.value] = option
end

local TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_OPTIONS = {
	{
		value = "default",
		labelKey = "settingsTrackedCurrencyTooltipColorDefault",
	},
	{
		value = "class",
		labelKey = "settingsTrackedCurrencyTooltipColorClass",
	},
}

local TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_LOOKUP = {}
for _, option in ipairs(TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_OPTIONS) do
	TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_LOOKUP[option.value] = option
end

local TEXT_CASE_OPTIONS = {
	{
		value = "default",
		labelKey = "settingsTextCaseDefault",
	},
	{
		value = "lower",
		labelKey = "settingsTextCaseLower",
	},
	{
		value = "upper",
		labelKey = "settingsTextCaseUpper",
	},
}

local TEXT_CASE_LOOKUP = {}
for _, option in ipairs(TEXT_CASE_OPTIONS) do
	TEXT_CASE_LOOKUP[option.value] = option
end

local MONEY_FORMAT_OPTIONS = {
	{
		value = "symbols",
		labelKey = "settingsMoneyFormatSymbols",
	},
	{
		value = "letters",
		labelKey = "settingsMoneyFormatLetters",
	},
}

local MONEY_FORMAT_LOOKUP = {}
for _, option in ipairs(MONEY_FORMAT_OPTIONS) do
	MONEY_FORMAT_LOOKUP[option.value] = option
end

local EQUIPMENT_SET_TEXT_COLORS = {
	{ 0.36, 0.78, 1.00 },
	{ 0.50, 0.86, 0.45 },
	{ 1.00, 0.78, 0.32 },
	{ 1.00, 0.54, 0.42 },
	{ 0.76, 0.62, 1.00 },
	{ 0.42, 0.92, 0.82 },
	{ 1.00, 0.62, 0.86 },
	{ 0.68, 0.84, 1.00 },
	{ 0.86, 0.90, 0.42 },
	{ 0.98, 0.72, 0.52 },
	{ 0.60, 0.74, 1.00 },
	{ 0.72, 1.00, 0.68 },
}

local settingsDefaultsCache = {
	table = nil,
}

local textAppearanceDefaultsCache = {
	table = nil,
}

local resolvedTextAppearanceCache = {
	byElement = {},
}

local function invalidateResolvedTextAppearanceCache()
	resolvedTextAppearanceCache.byElement = {}
end

local function clampTextAppearanceSize(size)
	size = math.floor((tonumber(size) or defaultSettings.textAppearance.size) + 0.5)
	if size < 8 then
		return 8
	elseif size > 24 then
		return 24
	end
	return size
end

local function setResolvedElementSize(appearance, elementID, size)
	local element = appearance and appearance.elements and appearance.elements[elementID] or nil
	if not element then
		return
	end
	element.size = clampTextAppearanceSize(size)
end

local TRACKED_CURRENCY_DATA_REQUEST_THROTTLE = 5
local trackedCurrencyDataRequestState = addon.Bags.variables.trackedCurrencyDataRequestState or {}
addon.Bags.variables.trackedCurrencyDataRequestState = trackedCurrencyDataRequestState

local function applyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			applyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

local function ensureSettingsDefaults(settings)
	if settingsDefaultsCache.table ~= settings then
		applyDefaults(settings, defaultSettings)
		settingsDefaultsCache.table = settings
		textAppearanceDefaultsCache.table = nil
		invalidateResolvedTextAppearanceCache()
	end

	return settings
end

local function ensureTextAppearanceDefaults(appearance)
	if textAppearanceDefaultsCache.table ~= appearance then
		applyDefaults(appearance, defaultSettings.textAppearance)
		local globalFontKey = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or defaultSettings.textAppearance.font
		local globalStyleKey = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or defaultSettings.textAppearance.outline
		if appearance.font == "standard" or appearance.font == "arial" or appearance.font == "morpheus" then
			appearance.font = globalFontKey
		end
		if appearance.outline == nil or appearance.outline == "" then
			appearance.outline = globalStyleKey
		elseif addon.functions and addon.functions.NormalizeFontStyleChoice then
			appearance.outline = addon.functions.NormalizeFontStyleChoice(appearance.outline, globalStyleKey, true)
		end
		appearance.elements = appearance.elements or {}
		for elementID, definition in pairs(TEXT_ELEMENT_DEFINITIONS) do
			local element = appearance.elements[elementID]
			if type(element) ~= "table" then
				element = {}
				appearance.elements[elementID] = element
			end
			if element.font == nil or element.font == "" then
				element.font = TEXT_ELEMENT_INHERIT_KEY
			end
			if element.outline == nil or element.outline == "" then
				element.outline = TEXT_ELEMENT_INHERIT_KEY
			elseif element.outline ~= TEXT_ELEMENT_INHERIT_KEY and addon.functions and addon.functions.NormalizeFontStyleChoice then
				element.outline = addon.functions.NormalizeFontStyleChoice(element.outline, globalStyleKey, true)
			end
			element.size = math.floor((tonumber(element.size) or definition.size or defaultSettings.textAppearance.size) + 0.5)
			if element.size < 8 then
				element.size = 8
			elseif element.size > 24 then
				element.size = 24
			end
			if not TEXT_CASE_LOOKUP[element.case] then
				element.case = "default"
			end
			if elementID == "stackCount" then
				if not STACK_COUNT_ANCHOR_LOOKUP[element.anchor] then
					element.anchor = defaultSettings.textAppearance.elements.stackCount.anchor
				end
			end
		end
		textAppearanceDefaultsCache.table = appearance
		invalidateResolvedTextAppearanceCache()
	end

	return appearance
end

local function applyIntegratedDefaults(settings)
	local version = tonumber(settings.integratedDefaultsVersion) or 0
	if version >= INTEGRATED_DEFAULTS_VERSION then
		return false
	end

	settings.textAppearance = settings.textAppearance or {}
	if settings.textAppearance.font == "standard" or settings.textAppearance.font == "arial" or settings.textAppearance.font == "morpheus" then
		settings.textAppearance.font = defaultSettings.textAppearance.font
	end

	settings.overlayElements = settings.overlayElements or {}
	settings.overlayElements.upgradeTrack = settings.overlayElements.upgradeTrack or {}

	settings.integratedDefaultsVersion = INTEGRATED_DEFAULTS_VERSION
	settingsDefaultsCache.table = nil
	textAppearanceDefaultsCache.table = nil
	invalidateResolvedTextAppearanceCache()
	return true
end

local function ensureMoneyTracker()
	addon.DB = addon.DB or {}
	addon.DB.moneyTracker = addon.DB.moneyTracker or {}
	return addon.DB.moneyTracker
end

local function getCurrentCharacterGUID()
	if type(UnitGUID) ~= "function" then
		return nil
	end

	return UnitGUID("player")
end

function addon.GetSettings()
	if addon.savedVariablesLoaded then
		addon.DB = _G.EnhanceQoLBagsDB or addon.DB or {}
	end

	addon.DB = addon.DB or {}
	addon.DB.frame = addon.DB.frame or {}
	addon.DB.settings = addon.DB.settings or {}
	addon.DB.moneyTracker = addon.DB.moneyTracker or {}
	addon.DB.warbandGold = tonumber(addon.DB.warbandGold) or 0
	return ensureSettingsDefaults(addon.DB.settings)
end

function addon.GetActiveCategoryMode()
	local settings = addon.GetSettings()
	local mode = tostring(settings.activeCategoryMode or defaultSettings.activeCategoryMode)
	if mode ~= "advanced" then
		mode = "basic"
	end
	settings.activeCategoryMode = mode
	return mode
end

function addon.SetActiveCategoryMode(mode)
	mode = tostring(mode or "")
	if mode ~= "advanced" then
		mode = "basic"
	end

	local settings = addon.GetSettings()
	if mode == "basic" and addon.EnsureBasicPresetSeeded then
		addon.EnsureBasicPresetSeeded()
	end
	if mode == "basic" and addon.ApplyBasicOverlayDefaultsIfUnconfigured then
		addon.ApplyBasicOverlayDefaultsIfUnconfigured()
	end
	if settings.activeCategoryMode == mode then
		return false
	end

	settings.activeCategoryMode = mode
	if addon.MarkCategoryModeStateDirty then
		addon.MarkCategoryModeStateDirty()
	end
	return true
end

function addon.IsCategoryModeOnboardingComplete()
	local settings = addon.GetSettings()
	settings.modeOnboardingComplete = settings.modeOnboardingComplete == true
	return settings.modeOnboardingComplete
end

function addon.SetCategoryModeOnboardingComplete(isComplete)
	local settings = addon.GetSettings()
	local normalized = isComplete == true
	if settings.modeOnboardingComplete == normalized then
		return false
	end

	settings.modeOnboardingComplete = normalized
	return true
end

function addon.InitializeSavedVariables()
	local hadSavedVariables = type(_G.EnhanceQoLBagsDB) == "table"
	addon.savedVariablesAreNew = not hadSavedVariables
	addon.DB = _G.EnhanceQoLBagsDB or addon.DB or {}
	_G.EnhanceQoLBagsDB = addon.DB
	addon.DB.frame = addon.DB.frame or {}
	addon.DB.settings = addon.DB.settings or {}
	addon.DB.moneyTracker = addon.DB.moneyTracker or {}
	addon.DB.warbandGold = tonumber(addon.DB.warbandGold) or 0
	ensureSettingsDefaults(addon.DB.settings)
	applyIntegratedDefaults(addon.DB.settings)
	if addon.InitializeCategoryModeSettings then
		addon.InitializeCategoryModeSettings(addon.savedVariablesAreNew)
	end
	addon.savedVariablesLoaded = true
	return addon.DB
end

function addon.GetCurrentCharacterGUID()
	return getCurrentCharacterGUID()
end

function addon.UpdateTrackedCharacterMoney()
	if not addon.savedVariablesLoaded then
		return nil
	end

	local characterGUID = getCurrentCharacterGUID()
	if not characterGUID then
		return nil
	end

	local tracker = ensureMoneyTracker()
	local _, classToken = UnitClass("player")
	tracker[characterGUID] = {
		name = UnitName("player"),
		realm = GetRealmName(),
		class = classToken,
		money = GetMoney() or 0,
		lastSeen = time and time() or 0,
	}

	return tracker[characterGUID]
end

function addon.UpdateWarbandGold()
	if not addon.savedVariablesLoaded then
		return nil
	end

	addon.DB = addon.DB or {}

	local warbandGold = addon.DB.warbandGold or 0
	if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account then
		warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account) or warbandGold
	end

	addon.DB.warbandGold = tonumber(warbandGold) or 0
	return addon.DB.warbandGold
end

function addon.GetWarbandGold()
	addon.DB = addon.DB or {}
	return tonumber(addon.DB.warbandGold) or 0
end

function addon.GetTrackedCharacterGoldEntries()
	local tracker = ensureMoneyTracker()
	local currentGUID = getCurrentCharacterGUID()
	local entries = {}

	for guid, info in pairs(tracker) do
		if type(info) == "table" and tonumber(info.money) ~= nil then
			entries[#entries + 1] = {
				guid = guid,
				name = info.name,
				realm = info.realm,
				class = info.class,
				money = tonumber(info.money) or 0,
				lastSeen = tonumber(info.lastSeen) or 0,
				isCurrent = guid == currentGUID,
			}
		end
	end

	table.sort(entries, function(left, right)
		if left.isCurrent ~= right.isCurrent then
			return left.isCurrent
		end
		if left.money ~= right.money then
			return left.money > right.money
		end

		local leftKey = string.format("%s:%s", tostring(left.name or ""), tostring(left.realm or ""))
		local rightKey = string.format("%s:%s", tostring(right.name or ""), tostring(right.realm or ""))
		return leftKey < rightKey
	end)

	return entries
end

function addon.RemoveTrackedCharacterGoldEntry(characterGUID)
	if not characterGUID or characterGUID == getCurrentCharacterGUID() then
		return false
	end

	local tracker = ensureMoneyTracker()
	if tracker[characterGUID] == nil then
		return false
	end

	tracker[characterGUID] = nil
	return true
end

local function copySequentialList(values)
	local copy = {}
	for index, value in ipairs(values or {}) do
		copy[index] = value
	end
	return copy
end

local function normalizeTrackedCurrencyIDs(currencyIDs)
	local normalized = {}
	local seen = {}

	for _, currencyID in ipairs(currencyIDs or {}) do
		currencyID = tonumber(currencyID)
		if currencyID and currencyID > 0 and not seen[currencyID] then
			seen[currencyID] = true
			normalized[#normalized + 1] = currencyID
		end
	end

	return normalized
end

local function areSequentialListsEqual(left, right)
	if #left ~= #right then
		return false
	end

	for index = 1, #left do
		if left[index] ~= right[index] then
			return false
		end
	end

	return true
end

local function normalizeTrackedCurrencyTooltipTotalPosition(value)
	value = tostring(value or defaultSettings.trackedCurrencyTooltipTotalPosition or "")
	if TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_LOOKUP[value] then
		return value
	end
	return defaultSettings.trackedCurrencyTooltipTotalPosition
end

local function normalizeTrackedCurrencyTooltipColorMode(value, fallback)
	value = tostring(value or fallback or "")
	if TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_LOOKUP[value] then
		return value
	end
	return fallback or defaultSettings.trackedCurrencyTooltipCountColorMode or "default"
end

function addon.GetTrackedCurrencyTrackingInfo(currencyID)
	currencyID = tonumber(currencyID)
	if not currencyID or currencyID <= 0 or not C_CurrencyInfo then
		return nil
	end

	if type(C_CurrencyInfo.GetCurrencyInfo) == "function" then
		local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
		if info and info.name then
			return {
				currencyID = currencyID,
				name = info.name,
				description = info.description,
				iconFileID = info.iconFileID or info.icon,
				quality = info.quality,
				quantity = tonumber(info.quantity) or 0,
			}
		end
	end

	if type(C_CurrencyInfo.GetBasicCurrencyInfo) == "function" then
		local info = C_CurrencyInfo.GetBasicCurrencyInfo(currencyID)
		if info and info.name then
			return {
				currencyID = currencyID,
				name = info.name,
				description = info.description,
				iconFileID = info.iconFileID or info.icon,
				quality = info.quality,
				quantity = tonumber(info.actualAmount or info.displayAmount) or 0,
			}
		end
	end

	return nil
end

function addon.GetTrackedCurrencyIDs()
	local settings = addon.GetSettings()
	local normalized = normalizeTrackedCurrencyIDs(settings.trackedCurrencyIDs)
	if not areSequentialListsEqual(settings.trackedCurrencyIDs or {}, normalized) then
		settings.trackedCurrencyIDs = copySequentialList(normalized)
	end

	return copySequentialList(normalized)
end

function addon.SetTrackedCurrencyIDs(currencyIDs)
	local settings = addon.GetSettings()
	local normalized = normalizeTrackedCurrencyIDs(currencyIDs)
	if areSequentialListsEqual(settings.trackedCurrencyIDs or {}, normalized) then
		return false
	end

	settings.trackedCurrencyIDs = copySequentialList(normalized)
	return true
end

function addon.GetTrackedCurrencyEntries()
	local entries = {}
	for index, currencyID in ipairs(addon.GetTrackedCurrencyIDs()) do
		local info = addon.GetTrackedCurrencyTrackingInfo(currencyID) or {}
		entries[#entries + 1] = {
			index = index,
			currencyID = currencyID,
			name = info.name or string.format("ID %d", currencyID),
			description = info.description,
			iconFileID = info.iconFileID,
			quality = info.quality,
			quantity = tonumber(info.quantity) or 0,
		}
	end
	return entries
end

function addon.AddTrackedCurrencyID(currencyID)
	local info = addon.GetTrackedCurrencyTrackingInfo(currencyID)
	if not info then
		return false, "invalid"
	end

	local ids = addon.GetTrackedCurrencyIDs()
	for _, existingCurrencyID in ipairs(ids) do
		if existingCurrencyID == info.currencyID then
			return false, "duplicate", info
		end
	end

	ids[#ids + 1] = info.currencyID
	addon.SetTrackedCurrencyIDs(ids)
	return true, nil, info
end

function addon.RemoveTrackedCurrencyID(currencyID)
	currencyID = tonumber(currencyID)
	if not currencyID or currencyID <= 0 then
		return false
	end

	local ids = addon.GetTrackedCurrencyIDs()
	for index, existingCurrencyID in ipairs(ids) do
		if existingCurrencyID == currencyID then
			table.remove(ids, index)
			addon.SetTrackedCurrencyIDs(ids)
			return true
		end
	end

	return false
end

function addon.MoveTrackedCurrencyIndex(index, delta)
	index = tonumber(index)
	delta = tonumber(delta)
	if not index or not delta or delta == 0 then
		return false
	end

	local ids = addon.GetTrackedCurrencyIDs()
	local targetIndex = index + delta
	if index < 1 or index > #ids or targetIndex < 1 or targetIndex > #ids then
		return false
	end

	ids[index], ids[targetIndex] = ids[targetIndex], ids[index]
	addon.SetTrackedCurrencyIDs(ids)
	return true
end

function addon.GetShowTrackedCurrencyCharacterBreakdown()
	local settings = addon.GetSettings()
	return settings.showTrackedCurrencyCharacterBreakdown == true
end

function addon.SetShowTrackedCurrencyCharacterBreakdown(enabled)
	local settings = addon.GetSettings()
	enabled = not not enabled
	if settings.showTrackedCurrencyCharacterBreakdown == enabled then
		return false
	end

	settings.showTrackedCurrencyCharacterBreakdown = enabled
	return true
end

function addon.GetTrackedCurrencyTooltipTotalPosition()
	local settings = addon.GetSettings()
	settings.trackedCurrencyTooltipTotalPosition = normalizeTrackedCurrencyTooltipTotalPosition(settings.trackedCurrencyTooltipTotalPosition)
	return settings.trackedCurrencyTooltipTotalPosition
end

function addon.SetTrackedCurrencyTooltipTotalPosition(value)
	local settings = addon.GetSettings()
	local normalizedValue = normalizeTrackedCurrencyTooltipTotalPosition(value)
	if settings.trackedCurrencyTooltipTotalPosition == normalizedValue then
		return false
	end

	settings.trackedCurrencyTooltipTotalPosition = normalizedValue
	return true
end

function addon.GetTrackedCurrencyTooltipTotalPositionOptions()
	local options = {}
	for _, option in ipairs(TRACKED_CURRENCY_TOOLTIP_TOTAL_POSITION_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = (addon.L and addon.L[option.labelKey]) or option.labelKey or option.value,
		}
	end
	return options
end

function addon.GetTrackedCurrencyTooltipNameColorMode()
	local settings = addon.GetSettings()
	settings.trackedCurrencyTooltipNameColorMode = normalizeTrackedCurrencyTooltipColorMode(settings.trackedCurrencyTooltipNameColorMode, defaultSettings.trackedCurrencyTooltipNameColorMode)
	return settings.trackedCurrencyTooltipNameColorMode
end

function addon.SetTrackedCurrencyTooltipNameColorMode(value)
	local settings = addon.GetSettings()
	local normalizedValue = normalizeTrackedCurrencyTooltipColorMode(value, defaultSettings.trackedCurrencyTooltipNameColorMode)
	if settings.trackedCurrencyTooltipNameColorMode == normalizedValue then
		return false
	end

	settings.trackedCurrencyTooltipNameColorMode = normalizedValue
	return true
end

function addon.GetTrackedCurrencyTooltipCountColorMode()
	local settings = addon.GetSettings()
	settings.trackedCurrencyTooltipCountColorMode = normalizeTrackedCurrencyTooltipColorMode(settings.trackedCurrencyTooltipCountColorMode, defaultSettings.trackedCurrencyTooltipCountColorMode)
	return settings.trackedCurrencyTooltipCountColorMode
end

function addon.SetTrackedCurrencyTooltipCountColorMode(value)
	local settings = addon.GetSettings()
	local normalizedValue = normalizeTrackedCurrencyTooltipColorMode(value, defaultSettings.trackedCurrencyTooltipCountColorMode)
	if settings.trackedCurrencyTooltipCountColorMode == normalizedValue then
		return false
	end

	settings.trackedCurrencyTooltipCountColorMode = normalizedValue
	return true
end

function addon.GetTrackedCurrencyTooltipColorModeOptions()
	local options = {}
	for _, option in ipairs(TRACKED_CURRENCY_TOOLTIP_COLOR_MODE_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = (addon.L and addon.L[option.labelKey]) or option.labelKey or option.value,
		}
	end
	return options
end

function addon.RequestTrackedCurrencyCharacterData(force)
	if not C_CurrencyInfo or type(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters) ~= "function" then
		return false
	end

	if not force and not addon.GetShowTrackedCurrencyCharacterBreakdown() then
		return false
	end

	local now = type(GetTime) == "function" and GetTime() or 0
	local lastRequestTime = tonumber(trackedCurrencyDataRequestState.lastRequestTime) or 0
	if not force and now > 0 and (now - lastRequestTime) < TRACKED_CURRENCY_DATA_REQUEST_THROTTLE then
		return false
	end

	trackedCurrencyDataRequestState.lastRequestTime = now
	C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
	return true
end

local function getCurrentTrackedCurrencyCharacterEntry(currencyID)
	if not currencyID or not C_CurrencyInfo or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function" then
		return nil
	end

	local currentGUID = getCurrentCharacterGUID()
	if not currentGUID then
		return nil
	end

	local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
	if not info or not info.name then
		return nil
	end

	local _, classToken = UnitClass("player")
	return {
		characterGUID = currentGUID,
		characterName = UnitName("player") or UNKNOWN,
		fullCharacterName = (GetUnitName and GetUnitName("player", true)) or UnitName("player") or UNKNOWN,
		currencyID = currencyID,
		quantity = tonumber(info.quantity) or 0,
		class = classToken,
		isCurrent = true,
	}
end

local function getTrackedCurrencyCharacterClassToken(characterGUID)
	if not characterGUID then
		return nil
	end

	local currentGUID = getCurrentCharacterGUID()
	if currentGUID and characterGUID == currentGUID then
		local _, classToken = UnitClass("player")
		if classToken and classToken ~= "" then
			return classToken
		end
	end

	local tracker = ensureMoneyTracker()
	local trackedEntry = tracker and tracker[characterGUID]
	if trackedEntry and trackedEntry.class and trackedEntry.class ~= "" then
		return trackedEntry.class
	end

	if type(GetPlayerInfoByGUID) == "function" then
		local _, classFile = GetPlayerInfoByGUID(characterGUID)
		if classFile and classFile ~= "" then
			return classFile
		end
	end

	return nil
end

function addon.GetTrackedCurrencyCharacterEntries(currencyID)
	currencyID = tonumber(currencyID)
	if not currencyID or currencyID <= 0 then
		return {}, false, false
	end

	if not addon.GetShowTrackedCurrencyCharacterBreakdown() then
		return {}, false, false
	end

	if not C_CurrencyInfo
		or type(C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters) ~= "function"
		or type(C_CurrencyInfo.IsAccountCharacterCurrencyDataReady) ~= "function"
	then
		return {}, false, false
	end

	local isTransferable = type(C_CurrencyInfo.IsAccountTransferableCurrency) == "function"
		and C_CurrencyInfo.IsAccountTransferableCurrency(currencyID)
	if not isTransferable then
		return {}, true, false
	end

	local isReady = C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()
	if not isReady then
		return {}, false, true
	end

	local currentGUID = getCurrentCharacterGUID()
	local entries = {}
	local seen = {}
	local rosterEntries = C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters(currencyID)
	for _, entry in ipairs(rosterEntries or {}) do
		local characterGUID = entry.characterGUID
		if characterGUID and not seen[characterGUID] then
			seen[characterGUID] = true
			entries[#entries + 1] = {
				characterGUID = characterGUID,
				characterName = entry.characterName,
				fullCharacterName = entry.fullCharacterName,
				currencyID = entry.currencyID,
				quantity = tonumber(entry.quantity) or 0,
				class = getTrackedCurrencyCharacterClassToken(characterGUID),
				isCurrent = characterGUID == currentGUID,
			}
		end
	end

	local currentEntry = getCurrentTrackedCurrencyCharacterEntry(currencyID)
	if currentEntry and not seen[currentEntry.characterGUID] then
		entries[#entries + 1] = currentEntry
	end

	table.sort(entries, function(left, right)
		if left.isCurrent ~= right.isCurrent then
			return left.isCurrent
		end
		if left.quantity ~= right.quantity then
			return left.quantity > right.quantity
		end

		local leftKey = tostring(left.fullCharacterName or left.characterName or "")
		local rightKey = tostring(right.fullCharacterName or right.characterName or "")
		return leftKey < rightKey
	end)

	return entries, true, true
end

local function clampPaddingValue(padding, defaultValue)
	padding = math.floor((tonumber(padding) or defaultValue or 0) + 0.5)
	if padding < 0 then
		padding = 0
	elseif padding > 24 then
		padding = 24
	end

	return padding
end

local function clampCategorySpacingValue(spacing, defaultValue)
	spacing = math.floor((tonumber(spacing) or defaultValue or 0) + 0.5)
	if spacing < 0 then
		spacing = 0
	elseif spacing > 40 then
		spacing = 40
	end

	return spacing
end

local function clampItemScaleValue(scale, defaultValue)
	scale = tonumber(scale) or defaultValue or 100
	scale = math.floor(((scale / 5) + 0.5)) * 5
	if scale < 80 then
		scale = 80
	elseif scale > 160 then
		scale = 160
	end

	return scale
end

local function clampMaxColumnsValue(value, defaultValue)
	value = math.floor((tonumber(value) or defaultValue or 10) + 0.5)
	if value < 4 then
		value = 4
	elseif value > 24 then
		value = 24
	end

	return value
end

local function normalizeBooleanSetting(value, defaultValue)
	if value == nil then
		return not not defaultValue
	end

	return not not value
end

local function getStableStringHash(value)
	local hash = 0
	value = tostring(value or "")
	for index = 1, #value do
		hash = (hash * 33 + value:byte(index)) % 2147483647
	end
	return hash
end

function addon.GetOutsideHeaderPadding()
	local settings = addon.GetSettings()
	settings.outsideHeaderPadding = clampPaddingValue(settings.outsideHeaderPadding, defaultSettings.outsideHeaderPadding)
	return settings.outsideHeaderPadding
end

function addon.SetOutsideHeaderPadding(padding)
	local settings = addon.GetSettings()
	local clampedPadding = clampPaddingValue(padding, defaultSettings.outsideHeaderPadding)
	if settings.outsideHeaderPadding == clampedPadding then
		return false
	end

	settings.outsideHeaderPadding = clampedPadding
	return true
end

function addon.GetOutsideFooterPadding()
	local settings = addon.GetSettings()
	local fallback = math.max(
		tonumber(settings.outsideFooterPadding) or 0,
		tonumber(settings.footerSummaryPadding) or 0,
		tonumber(settings.outerPadding) or defaultSettings.outsideFooterPadding
	)
	settings.outsideFooterPadding = clampPaddingValue(settings.outsideFooterPadding, fallback)
	return settings.outsideFooterPadding
end

function addon.SetOutsideFooterPadding(padding)
	local settings = addon.GetSettings()
	local clampedPadding = clampPaddingValue(padding, defaultSettings.outsideFooterPadding)
	if settings.outsideFooterPadding == clampedPadding then
		return false
	end

	settings.outsideFooterPadding = clampedPadding
	return true
end

function addon.GetInsideHorizontalPadding()
	local settings = addon.GetSettings()
	local fallback = tonumber(settings.outerPadding) or defaultSettings.insideHorizontalPadding
	settings.insideHorizontalPadding = clampPaddingValue(settings.insideHorizontalPadding, fallback)
	return settings.insideHorizontalPadding
end

function addon.SetInsideHorizontalPadding(padding)
	local settings = addon.GetSettings()
	local clampedPadding = clampPaddingValue(padding, defaultSettings.insideHorizontalPadding)
	if settings.insideHorizontalPadding == clampedPadding then
		return false
	end

	settings.insideHorizontalPadding = clampedPadding
	return true
end

function addon.GetInsideTopPadding()
	local settings = addon.GetSettings()
	local fallback = (tonumber(settings.outerPadding) or defaultSettings.insideHorizontalPadding) + (tonumber(settings.headerPadding) or defaultSettings.headerPadding)
	settings.insideTopPadding = clampPaddingValue(settings.insideTopPadding, fallback)
	return settings.insideTopPadding
end

function addon.SetInsideTopPadding(padding)
	local settings = addon.GetSettings()
	local clampedPadding = clampPaddingValue(padding, defaultSettings.insideTopPadding)
	if settings.insideTopPadding == clampedPadding then
		return false
	end

	settings.insideTopPadding = clampedPadding
	return true
end

function addon.GetInsideBottomPadding()
	local settings = addon.GetSettings()
	settings.insideBottomPadding = clampPaddingValue(settings.insideBottomPadding, defaultSettings.insideBottomPadding)
	return settings.insideBottomPadding
end

function addon.SetInsideBottomPadding(padding)
	local settings = addon.GetSettings()
	local clampedPadding = clampPaddingValue(padding, defaultSettings.insideBottomPadding)
	if settings.insideBottomPadding == clampedPadding then
		return false
	end

	settings.insideBottomPadding = clampedPadding
	return true
end

function addon.GetOuterPadding()
	return addon.GetInsideHorizontalPadding()
end

function addon.SetOuterPadding(padding)
	return addon.SetInsideHorizontalPadding(padding)
end

function addon.GetHeaderPadding()
	return addon.GetInsideTopPadding()
end

function addon.SetHeaderPadding(padding)
	return addon.SetInsideTopPadding(padding)
end

function addon.GetFooterSummaryPadding()
	return addon.GetOutsideFooterPadding()
end

function addon.SetFooterSummaryPadding(padding)
	return addon.SetOutsideFooterPadding(padding)
end

function addon.GetFreeSlotDisplayMode()
	local settings = addon.GetSettings()
	local mode = settings.freeSlotDisplayMode
	if mode ~= "colors" and mode ~= "texture" then
		mode = "icons"
	end
	settings.freeSlotDisplayMode = mode
	return mode
end

function addon.SetFreeSlotDisplayMode(mode)
	if mode ~= "colors" and mode ~= "texture" then
		mode = "icons"
	end
	local settings = addon.GetSettings()
	if settings.freeSlotDisplayMode == mode then
		return false
	end
	settings.freeSlotDisplayMode = mode
	return true
end

function addon.GetFreeSlotDisplayModeOptions()
	return {
		{
			value = "icons",
			label = addon.L and addon.L["settingsFreeSlotDisplayIcons"] or "Icons",
		},
		{
			value = "colors",
			label = addon.L and addon.L["settingsFreeSlotDisplayColors"] or "Colored slots",
		},
		{
			value = "texture",
			label = addon.L and addon.L["settingsFreeSlotDisplayTexture"] or "Without icon",
		},
	}
end

local function normalizeFreeSlotColor(color, fallback)
	color = type(color) == "table" and color or fallback
	local r = tonumber(color and color[1]) or fallback[1] or 0
	local g = tonumber(color and color[2]) or fallback[2] or 0
	local b = tonumber(color and color[3]) or fallback[3] or 0
	if r < 0 then r = 0 elseif r > 1 then r = 1 end
	if g < 0 then g = 0 elseif g > 1 then g = 1 end
	if b < 0 then b = 0 elseif b > 1 then b = 1 end
	return { r, g, b }
end

function addon.GetFreeSlotColor(slotType)
	local settings = addon.GetSettings()
	if slotType == "reagent" then
		settings.freeSlotReagentColor = normalizeFreeSlotColor(settings.freeSlotReagentColor, defaultSettings.freeSlotReagentColor)
		return settings.freeSlotReagentColor
	end
	settings.freeSlotNormalColor = normalizeFreeSlotColor(settings.freeSlotNormalColor, defaultSettings.freeSlotNormalColor)
	return settings.freeSlotNormalColor
end

function addon.SetFreeSlotColor(slotType, r, g, b)
	local settings = addon.GetSettings()
	local fallback = slotType == "reagent" and defaultSettings.freeSlotReagentColor or defaultSettings.freeSlotNormalColor
	local color = normalizeFreeSlotColor({ r, g, b }, fallback)
	local key = slotType == "reagent" and "freeSlotReagentColor" or "freeSlotNormalColor"
	local current = addon.GetFreeSlotColor(slotType)
	if math.abs((current[1] or 0) - color[1]) < 0.001
		and math.abs((current[2] or 0) - color[2]) < 0.001
		and math.abs((current[3] or 0) - color[3]) < 0.001
	then
		return false
	end
	settings[key] = color
	return true
end

function addon.GetItemScale()
	local settings = addon.GetSettings()
	settings.itemScale = clampItemScaleValue(settings.itemScale, defaultSettings.itemScale)
	return settings.itemScale
end

function addon.SetItemScale(scale)
	local settings = addon.GetSettings()
	local clampedScale = clampItemScaleValue(scale, defaultSettings.itemScale)
	if settings.itemScale == clampedScale then
		return false
	end

	settings.itemScale = clampedScale
	return true
end

function addon.GetMaxColumns()
	local settings = addon.GetSettings()
	settings.maxColumns = clampMaxColumnsValue(settings.maxColumns, defaultSettings.maxColumns)
	return settings.maxColumns
end

function addon.SetMaxColumns(value)
	local settings = addon.GetSettings()
	local clampedValue = clampMaxColumnsValue(value, defaultSettings.maxColumns)
	if settings.maxColumns == clampedValue then
		return false
	end

	settings.maxColumns = clampedValue
	return true
end

function addon.GetOneBagMode()
	local settings = addon.GetSettings()
	settings.oneBagMode = normalizeBooleanSetting(settings.oneBagMode, defaultSettings.oneBagMode)
	return settings.oneBagMode
end

function addon.SetOneBagMode(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.oneBagMode)
	if settings.oneBagMode == enabled then
		return false
	end

	settings.oneBagMode = enabled
	return true
end

function addon.GetOneBagFreeSlotsAtEnd()
	local settings = addon.GetSettings()
	settings.oneBagFreeSlotsAtEnd = normalizeBooleanSetting(settings.oneBagFreeSlotsAtEnd, defaultSettings.oneBagFreeSlotsAtEnd)
	return settings.oneBagFreeSlotsAtEnd
end

function addon.SetOneBagFreeSlotsAtEnd(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.oneBagFreeSlotsAtEnd)
	if settings.oneBagFreeSlotsAtEnd == enabled then
		return false
	end

	settings.oneBagFreeSlotsAtEnd = enabled
	return true
end

function addon.GetCompactCategoryLayout()
	local settings = addon.GetSettings()
	settings.compactCategoryLayout = normalizeBooleanSetting(settings.compactCategoryLayout, defaultSettings.compactCategoryLayout)
	return settings.compactCategoryLayout
end

function addon.SetCompactCategoryLayout(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.compactCategoryLayout)
	if settings.compactCategoryLayout == enabled then
		return false
	end

	settings.compactCategoryLayout = enabled
	return true
end

function addon.GetCompactCategoryGap()
	local settings = addon.GetSettings()
	settings.compactCategoryGap = clampCategorySpacingValue(settings.compactCategoryGap, defaultSettings.compactCategoryGap)
	return settings.compactCategoryGap
end

function addon.SetCompactCategoryGap(value)
	local settings = addon.GetSettings()
	local clampedValue = clampCategorySpacingValue(value, defaultSettings.compactCategoryGap)
	if settings.compactCategoryGap == clampedValue then
		return false
	end

	settings.compactCategoryGap = clampedValue
	return true
end

function addon.GetCategoryTreeView()
	local settings = addon.GetSettings()
	settings.categoryTreeView = normalizeBooleanSetting(settings.categoryTreeView, defaultSettings.categoryTreeView)
	return settings.categoryTreeView
end

function addon.SetCategoryTreeView(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.categoryTreeView)
	if settings.categoryTreeView == enabled then
		return false
	end

	settings.categoryTreeView = enabled
	return true
end

function addon.GetCategoryTreeIndent()
	local settings = addon.GetSettings()
	settings.categoryTreeIndent = clampCategorySpacingValue(settings.categoryTreeIndent, defaultSettings.categoryTreeIndent)
	return settings.categoryTreeIndent
end

function addon.SetCategoryTreeIndent(value)
	local settings = addon.GetSettings()
	local clampedValue = clampCategorySpacingValue(value, defaultSettings.categoryTreeIndent)
	if settings.categoryTreeIndent == clampedValue then
		return false
	end

	settings.categoryTreeIndent = clampedValue
	return true
end

function addon.GetShowCloseButton()
	local settings = addon.GetSettings()
	settings.showCloseButton = normalizeBooleanSetting(settings.showCloseButton, defaultSettings.showCloseButton)
	return settings.showCloseButton
end

function addon.SetShowCloseButton(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.showCloseButton)
	if settings.showCloseButton == enabled then
		return false
	end

	settings.showCloseButton = enabled
	return true
end

function addon.GetClearNewItemsOnHeaderClick()
	local settings = addon.GetSettings()
	settings.clearNewItemsOnHeaderClick = normalizeBooleanSetting(settings.clearNewItemsOnHeaderClick, defaultSettings.clearNewItemsOnHeaderClick)
	return settings.clearNewItemsOnHeaderClick
end

function addon.SetClearNewItemsOnHeaderClick(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.clearNewItemsOnHeaderClick)
	if settings.clearNewItemsOnHeaderClick == enabled then
		return false
	end

	settings.clearNewItemsOnHeaderClick = enabled
	return true
end

function addon.GetRememberLastBankTab()
	local settings = addon.GetSettings()
	settings.rememberLastBankTab = normalizeBooleanSetting(settings.rememberLastBankTab, defaultSettings.rememberLastBankTab)
	return settings.rememberLastBankTab
end

function addon.SetRememberLastBankTab(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.rememberLastBankTab)
	if settings.rememberLastBankTab == enabled then
		return false
	end

	settings.rememberLastBankTab = enabled
	return true
end

function addon.GetUseIntegratedBank()
	local settings = addon.GetSettings()
	settings.useIntegratedBank = normalizeBooleanSetting(settings.useIntegratedBank, defaultSettings.useIntegratedBank)
	return settings.useIntegratedBank
end

function addon.SetUseIntegratedBank(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.useIntegratedBank)
	if settings.useIntegratedBank == enabled then
		return false
	end

	settings.useIntegratedBank = enabled
	return true
end

function addon.GetEquipmentSetOverlayInfo(bagID, slotID)
	if not (C_Container and C_Container.GetContainerItemEquipmentSetInfo) then
		return nil
	end

	local inEquipmentSet, setList = C_Container.GetContainerItemEquipmentSetInfo(bagID, slotID)
	if not inEquipmentSet then
		return nil
	end

	local firstSetName = type(setList) == "string" and setList:match("^%s*([^,]+)") or nil
	firstSetName = firstSetName and firstSetName:match("^%s*(.-)%s*$") or nil
	local setID = firstSetName and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(firstSetName) or nil
	local texture = setID and C_EquipmentSet.GetEquipmentSetInfo and select(2, C_EquipmentSet.GetEquipmentSetInfo(setID)) or nil
	local colorIndex = ((tonumber(setID) or getStableStringHash(firstSetName or setList or "")) % #EQUIPMENT_SET_TEXT_COLORS) + 1
	local color = EQUIPMENT_SET_TEXT_COLORS[colorIndex] or EQUIPMENT_SET_TEXT_COLORS[1]

	return {
		texture = texture,
		setID = setID,
		setName = firstSetName,
		colorKey = tostring(setID or firstSetName or setList or colorIndex),
		r = color[1],
		g = color[2],
		b = color[3],
	}
end

function addon.GetShowFreeSlots()
	local settings = addon.GetSettings()
	settings.showFreeSlots = normalizeBooleanSetting(settings.showFreeSlots, defaultSettings.showFreeSlots)
	return settings.showFreeSlots
end

function addon.SetShowFreeSlots(enabled)
	local settings = addon.GetSettings()
	enabled = normalizeBooleanSetting(enabled, defaultSettings.showFreeSlots)
	if settings.showFreeSlots == enabled then
		return false
	end

	settings.showFreeSlots = enabled
	return true
end

function addon.GetTextAppearance()
	local settings = addon.GetSettings()
	settings.textAppearance = settings.textAppearance or {}
	return ensureTextAppearanceDefaults(settings.textAppearance)
end

function addon.GetTextFontOptions()
	local options = {}
	local globalFontKey = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or defaultSettings.textAppearance.font
	options[#options + 1] = {
		value = globalFontKey,
		label = addon.functions and addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or "Use global font config",
	}

	local defaultFont = addon.variables and addon.variables.defaultFont or STANDARD_TEXT_FONT
	options[#options + 1] = {
		value = defaultFont,
		label = addon.L and addon.L["actionBarFontDefault"] or "Blizzard font",
	}

	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font") or {}
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" and path ~= defaultFont then
			options[#options + 1] = {
				value = path,
				label = tostring(name),
			}
		end
	end
	return options
end

function addon.GetTextOutlineOptions()
	if addon.functions and addon.functions.GetFontStyleOptionList then
		return addon.functions.GetFontStyleOptionList(true)
	end
	local options = {}
	options[#options + 1] = {
		value = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or defaultSettings.textAppearance.outline,
		label = addon.functions and addon.functions.GetGlobalFontStyleConfigLabel and addon.functions.GetGlobalFontStyleConfigLabel() or "Use global font styling",
	}
	options[#options + 1] = {
		value = "NONE",
		label = _G.NONE or "None",
	}
	options[#options + 1] = {
		value = "OUTLINE",
		label = addon.L and addon.L["Outline"] or "Outline",
	}
	return options
end

function addon.GetTextFontPath(fontID)
	local fallback = addon.variables and addon.variables.defaultFont or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ResolveFontFace then
		return addon.functions.ResolveFontFace(fontID, fallback) or fallback
	end
	return (type(fontID) == "string" and fontID ~= "" and fontID) or fallback
end

function addon.GetTextOutlineFlags(outlineID)
	if addon.functions and addon.functions.GetFontFlagsForStyle then
		return addon.functions.GetFontFlagsForStyle(outlineID, defaultSettings.textAppearance.outline)
	end
	if outlineID == "NONE" then
		return nil
	end
	return outlineID or "OUTLINE"
end

function addon.GetTextElementOptions()
	local options = {}
	for _, elementID in ipairs(TEXT_ELEMENT_ORDER) do
		local definition = TEXT_ELEMENT_DEFINITIONS[elementID]
		options[#options + 1] = {
			value = elementID,
			label = addon.L and addon.L[definition.labelKey] or definition.labelKey or elementID,
		}
	end
	return options
end

function addon.GetTextElementFontOptions()
	local options = {
		{
			value = TEXT_ELEMENT_INHERIT_KEY,
			label = addon.L and addon.L["settingsTextElementUseBaseFont"] or "Use base font",
		},
	}
	local baseOptions = addon.GetTextFontOptions and addon.GetTextFontOptions() or {}
	for _, option in ipairs(baseOptions) do
		options[#options + 1] = option
	end
	return options
end

function addon.GetTextElementOutlineOptions()
	local options = {
		{
			value = TEXT_ELEMENT_INHERIT_KEY,
			label = addon.L and addon.L["settingsTextElementUseBaseOutline"] or "Use base outline",
		},
	}
	local baseOptions = addon.GetTextOutlineOptions and addon.GetTextOutlineOptions() or {}
	for _, option in ipairs(baseOptions) do
		options[#options + 1] = option
	end
	return options
end

function addon.GetTextCaseOptions()
	local options = {}
	for _, option in ipairs(TEXT_CASE_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = addon.L and addon.L[option.labelKey] or option.labelKey or option.value,
		}
	end
	return options
end

function addon.GetTextElementAppearance(elementID)
	if not TEXT_ELEMENT_DEFINITIONS[elementID] then
		return nil
	end
	local appearance = addon.GetTextAppearance()
	appearance.elements = appearance.elements or {}
	if type(appearance.elements[elementID]) ~= "table" then
		appearance.elements[elementID] = {}
		textAppearanceDefaultsCache.table = nil
	end
	return ensureTextAppearanceDefaults(appearance).elements[elementID]
end

function addon.SetTextElementFont(elementID, fontID)
	local element = addon.GetTextElementAppearance(elementID)
	if not element then
		return false
	end
	if type(fontID) ~= "string" or fontID == "" then
		fontID = TEXT_ELEMENT_INHERIT_KEY
	end
	element.font = fontID
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.SetTextElementSize(elementID, size)
	local element = addon.GetTextElementAppearance(elementID)
	if not element then
		return false
	end
	size = clampTextAppearanceSize(tonumber(size) or element.size or defaultSettings.textAppearance.size)
	if tonumber(element.size) == size then
		return false
	end
	element.size = size
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.SetTextElementCase(elementID, caseMode)
	local element = addon.GetTextElementAppearance(elementID)
	if not element then
		return false
	end
	caseMode = TEXT_CASE_LOOKUP[caseMode] and caseMode or "default"
	if element.case == caseMode then
		return false
	end
	element.case = caseMode
	return true
end

function addon.SetTextElementOutline(elementID, outlineID)
	local element = addon.GetTextElementAppearance(elementID)
	if not element then
		return false
	end
	local globalStyleKey = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or defaultSettings.textAppearance.outline
	if outlineID ~= TEXT_ELEMENT_INHERIT_KEY then
		if addon.functions and addon.functions.NormalizeFontStyleChoice then
			outlineID = addon.functions.NormalizeFontStyleChoice(outlineID, globalStyleKey, true)
		elseif type(outlineID) ~= "string" or outlineID == "" then
			outlineID = TEXT_ELEMENT_INHERIT_KEY
		end
	end
	element.outline = outlineID
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.GetStackCountAnchorOptions()
	local options = {}
	local order = addon.GetOverlayAnchorOrder and addon.GetOverlayAnchorOrder() or STACK_COUNT_ANCHOR_ORDER
	for _, anchorID in ipairs(order) do
		if STACK_COUNT_ANCHOR_LOOKUP[anchorID] then
			local anchorInfo = addon.GetOverlayAnchorInfo and addon.GetOverlayAnchorInfo(anchorID) or nil
			options[#options + 1] = {
				value = anchorID,
				label = addon.L and anchorInfo and addon.L[anchorInfo.labelKey] or anchorInfo and anchorInfo.labelKey or anchorID,
			}
		end
	end
	return options
end

function addon.GetStackCountAnchor()
	local element = addon.GetTextElementAppearance("stackCount")
	if not element then
		return defaultSettings.textAppearance.elements.stackCount.anchor
	end
	if not STACK_COUNT_ANCHOR_LOOKUP[element.anchor] then
		element.anchor = defaultSettings.textAppearance.elements.stackCount.anchor
	end
	return element.anchor
end

function addon.SetStackCountAnchor(anchorID)
	if not STACK_COUNT_ANCHOR_LOOKUP[anchorID] then
		return false
	end
	local element = addon.GetTextElementAppearance("stackCount")
	if not element then
		return false
	end
	if element.anchor == anchorID then
		return false
	end
	element.anchor = anchorID
	return true
end

function addon.GetSubcategoryFullLabels()
	local appearance = addon.GetTextAppearance()
	appearance.subcategoryFullLabels = not not appearance.subcategoryFullLabels
	return appearance.subcategoryFullLabels
end

function addon.SetSubcategoryFullLabels(enabled)
	local appearance = addon.GetTextAppearance()
	enabled = not not enabled
	if appearance.subcategoryFullLabels == enabled then
		return false
	end
	appearance.subcategoryFullLabels = enabled
	return true
end

function addon.FormatTextElement(elementID, text)
	if type(text) ~= "string" or not TEXT_ELEMENT_DEFINITIONS[elementID] then
		return text
	end
	local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or nil
	local caseMode = element and element.case or "default"
	if caseMode == "lower" then
		return string.lower(text)
	elseif caseMode == "upper" then
		return string.upper(text)
	end
	return text
end

function addon.GetResolvedTextAppearance(elementID)
	local appearance = addon.GetTextAppearance()
	local basicMode = addon.GetActiveCategoryMode and addon.GetActiveCategoryMode() == "basic"
	local element = (not basicMode and TEXT_ELEMENT_DEFINITIONS[elementID]) and addon.GetTextElementAppearance(elementID) or nil
	local cacheKey = elementID or "__base"
	local cache = resolvedTextAppearanceCache.byElement[cacheKey]
	local baseSize = math.floor((tonumber(appearance.size) or defaultSettings.textAppearance.size) + 0.5)
	local baseOverlaySize = math.floor((tonumber(appearance.overlaySize) or baseSize) + 0.5)
	local fontID = element and element.font ~= TEXT_ELEMENT_INHERIT_KEY and element.font or appearance.font or defaultSettings.textAppearance.font
	local outlineID = element and element.outline ~= TEXT_ELEMENT_INHERIT_KEY and element.outline or appearance.outline or defaultSettings.textAppearance.outline
	local size
	if element then
		size = math.floor((tonumber(element.size) or baseSize) + 0.5)
	elseif elementID == "overlays" or elementID == "stackCount" then
		size = baseOverlaySize
	elseif elementID == "categoryHeader" or elementID == "subcategoryHeader" then
		size = baseSize + 1
	else
		size = baseSize
	end
	local overlaySize = baseOverlaySize
	local globalVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	local fontMediaVersion = addon.functions and addon.functions.GetLSMMediaVersion and addon.functions.GetLSMMediaVersion("font") or 0

	if not cache
		or cache.appearance ~= appearance
		or cache.basicMode ~= basicMode
		or cache.elementID ~= elementID
		or cache.font ~= fontID
		or cache.outline ~= outlineID
		or cache.size ~= size
		or cache.overlaySize ~= overlaySize
		or cache.globalVersion ~= globalVersion
		or cache.fontMediaVersion ~= fontMediaVersion
	then
		cache = {
			appearance = appearance,
			basicMode = basicMode,
			elementID = elementID,
			font = fontID,
			outline = outlineID,
			size = size,
			overlaySize = overlaySize,
			globalVersion = globalVersion,
			fontMediaVersion = fontMediaVersion,
			fontPath = addon.GetTextFontPath(fontID),
			outlineFlags = addon.GetTextOutlineFlags(outlineID),
		}
		resolvedTextAppearanceCache.byElement[cacheKey] = cache
	end

	return cache
end

function addon.SetTextAppearanceFont(fontID)
	if type(fontID) ~= "string" or fontID == "" then
		return false
	end

	local appearance = addon.GetTextAppearance()
	appearance.font = fontID
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.SetTextAppearanceSize(size)
	size = clampTextAppearanceSize(size)

	local appearance = addon.GetTextAppearance()
	local oldSize = clampTextAppearanceSize(tonumber(appearance.size) or defaultSettings.textAppearance.size)
	if tonumber(appearance.size) == size then
		return false
	end
	appearance.size = size
	local sizeDelta = size - oldSize
	setResolvedElementSize(appearance, "categoryHeader", (tonumber(appearance.elements.categoryHeader.size) or TEXT_ELEMENT_DEFINITIONS.categoryHeader.size) + sizeDelta)
	setResolvedElementSize(appearance, "subcategoryHeader", (tonumber(appearance.elements.subcategoryHeader.size) or TEXT_ELEMENT_DEFINITIONS.subcategoryHeader.size) + sizeDelta)
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.GetTextAppearanceOverlaySize()
	local appearance = addon.GetTextAppearance()
	local overlaySize = math.floor((tonumber(appearance.overlaySize) or tonumber(appearance.size) or defaultSettings.textAppearance.size) + 0.5)
	if overlaySize < 8 then
		overlaySize = 8
	elseif overlaySize > 24 then
		overlaySize = 24
	end

	if tonumber(appearance.overlaySize) ~= overlaySize then
		appearance.overlaySize = overlaySize
	end

	return overlaySize
end

function addon.SetTextAppearanceOverlaySize(size)
	size = clampTextAppearanceSize(size)

	local appearance = addon.GetTextAppearance()
	if tonumber(appearance.overlaySize) == size then
		return false
	end

	appearance.overlaySize = size
	setResolvedElementSize(appearance, "overlays", size)
	setResolvedElementSize(appearance, "stackCount", size)
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.SetTextAppearanceOutline(outlineID)
	local globalStyleKey = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or defaultSettings.textAppearance.outline
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		outlineID = addon.functions.NormalizeFontStyleChoice(outlineID, globalStyleKey, true)
	elseif type(outlineID) ~= "string" or outlineID == "" then
		outlineID = globalStyleKey
	end

	local appearance = addon.GetTextAppearance()
	appearance.outline = outlineID
	invalidateResolvedTextAppearanceCache()
	return true
end

function addon.ApplyConfiguredFont(fontString, size, elementID)
	if not fontString or not fontString.SetFont then
		return
	end

	local appearance = addon.GetResolvedTextAppearance(elementID)
	local fontSize = math.floor((tonumber(size) or appearance.size or defaultSettings.textAppearance.size) + 0.5)
	if fontSize < 6 then
		fontSize = 6
	end

	if addon.functions and addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(fontString, appearance.font, fontSize, appearance.outline, defaultSettings.textAppearance.font, defaultSettings.textAppearance.outline)
		return
	end

	fontString:SetFont(appearance.fontPath or STANDARD_TEXT_FONT, fontSize, appearance.outlineFlags or "OUTLINE")
end

function addon.GetMoneyFormatOptions()
	local options = {}
	for _, option in ipairs(MONEY_FORMAT_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = addon.L and addon.L[option.labelKey] or option.labelKey or option.value,
		}
	end
	return options
end

function addon.GetMoneyFormat()
	local settings = addon.GetSettings()
	local format = tostring(settings.moneyFormat or defaultSettings.moneyFormat)
	if not MONEY_FORMAT_LOOKUP[format] then
		format = defaultSettings.moneyFormat
		settings.moneyFormat = format
	end
	return format
end

function addon.SetMoneyFormat(format)
	if not MONEY_FORMAT_LOOKUP[format] then
		return false
	end
	local settings = addon.GetSettings()
	if settings.moneyFormat == format then
		return false
	end
	settings.moneyFormat = format
	return true
end

function addon.Bags.functions.RefreshGlobalFont()
	invalidateResolvedTextAppearanceCache()
	if addon.Bags.functions.RequestLayoutUpdate then
		addon.Bags.functions.RequestLayoutUpdate(false, true)
	end
	if addon.Bags.functions.RequestBankLayoutUpdate then
		addon.Bags.functions.RequestBankLayoutUpdate(false, true)
	end
	if addon.RefreshSettingsFrame then
		addon.RefreshSettingsFrame()
	end
end

local initFrame = addon.Bags.variables.initFrame or CreateFrame("Frame")
addon.Bags.variables.initFrame = initFrame
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_MONEY")
initFrame:RegisterEvent("ACCOUNT_MONEY")
initFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
	if event == "ADDON_LOADED" then
		if loadedAddonName ~= addonName then
			return
		end

		if addon.Bags.IsEnabled and addon.Bags.IsEnabled() then
			addon.InitializeSavedVariables()
		end

		local state = addon.Bags.variables and addon.Bags.variables.state
		if state then
			state.manualVisible = addon.DB and addon.DB.settings and addon.DB.settings.manualVisible
		end

		initFrame:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		if addon.Bags.IsEnabled and addon.Bags.IsEnabled() then
			if addon.Bags.functions and addon.Bags.functions.Enable then
				addon.Bags.functions.Enable()
			end
			addon.UpdateWarbandGold()
			addon.UpdateTrackedCharacterMoney()
			addon.RequestTrackedCurrencyCharacterData(false)
		end
		if addon.Bags.IsEnabled and addon.Bags.IsEnabled() and addon.ShouldShowCategoryModeOnboarding and addon.ShouldShowCategoryModeOnboarding() and addon.OpenCategoryModeOnboarding then
			addon.OpenCategoryModeOnboarding()
		end
		initFrame:UnregisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_MONEY" then
		if addon.Bags.IsEnabled and addon.Bags.IsEnabled() then
			addon.UpdateTrackedCharacterMoney()
		end
	elseif event == "ACCOUNT_MONEY" then
		if addon.Bags.IsEnabled and addon.Bags.IsEnabled() then
			addon.UpdateWarbandGold()
		end
	end
end)

addon.L = addon.L or {}
addon.metadata = addon.metadata or {
	title = "Bags",
	description = "Standalone custom bag window and item grid for Retail.",
}
