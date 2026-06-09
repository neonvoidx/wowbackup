local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}

local ANCHOR_ORDER = {
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

local ANCHOR_OPTIONS = {
	TOPLEFT = {
		id = "TOPLEFT",
		point = "TOPLEFT",
		relativePoint = "TOPLEFT",
		x = 2,
		y = -2,
		dotPoint = "TOPLEFT",
		dotX = 5,
		dotY = -5,
		justifyH = "LEFT",
		justifyV = "TOP",
		labelKey = "settingsAnchorTopLeft",
	},
	TOP = {
		id = "TOP",
		point = "TOP",
		relativePoint = "TOP",
		x = 0,
		y = -2,
		dotPoint = "TOP",
		dotX = 0,
		dotY = -5,
		justifyH = "CENTER",
		justifyV = "TOP",
		labelKey = "settingsAnchorTop",
	},
	TOPRIGHT = {
		id = "TOPRIGHT",
		point = "TOPRIGHT",
		relativePoint = "TOPRIGHT",
		x = -2,
		y = -2,
		dotPoint = "TOPRIGHT",
		dotX = -5,
		dotY = -5,
		justifyH = "RIGHT",
		justifyV = "TOP",
		labelKey = "settingsAnchorTopRight",
	},
	LEFT = {
		id = "LEFT",
		point = "LEFT",
		relativePoint = "LEFT",
		x = 2,
		y = 0,
		dotPoint = "LEFT",
		dotX = 5,
		dotY = 0,
		justifyH = "LEFT",
		justifyV = "MIDDLE",
		labelKey = "settingsAnchorLeft",
	},
	CENTER = {
		id = "CENTER",
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0,
		dotPoint = "CENTER",
		dotX = 0,
		dotY = 0,
		justifyH = "CENTER",
		justifyV = "MIDDLE",
		labelKey = "settingsAnchorCenter",
	},
	RIGHT = {
		id = "RIGHT",
		point = "RIGHT",
		relativePoint = "RIGHT",
		x = -2,
		y = 0,
		dotPoint = "RIGHT",
		dotX = -5,
		dotY = 0,
		justifyH = "RIGHT",
		justifyV = "MIDDLE",
		labelKey = "settingsAnchorRight",
	},
	BOTTOMLEFT = {
		id = "BOTTOMLEFT",
		point = "BOTTOMLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 2,
		y = 2,
		dotPoint = "BOTTOMLEFT",
		dotX = 5,
		dotY = 5,
		justifyH = "LEFT",
		justifyV = "BOTTOM",
		labelKey = "settingsAnchorBottomLeft",
	},
	BOTTOM = {
		id = "BOTTOM",
		point = "BOTTOM",
		relativePoint = "BOTTOM",
		x = 0,
		y = 2,
		dotPoint = "BOTTOM",
		dotX = 0,
		dotY = 5,
		justifyH = "CENTER",
		justifyV = "BOTTOM",
		labelKey = "settingsAnchorBottom",
	},
	BOTTOMRIGHT = {
		id = "BOTTOMRIGHT",
		point = "BOTTOMRIGHT",
		relativePoint = "BOTTOMRIGHT",
		x = -2,
		y = 2,
		dotPoint = "BOTTOMRIGHT",
		dotX = -5,
		dotY = 5,
		justifyH = "RIGHT",
		justifyV = "BOTTOM",
		labelKey = "settingsAnchorBottomRight",
	},
}

local OVERLAY_ELEMENTS = {
	{
		id = "bindStatus",
		frameKey = "BindStatusText",
		labelKey = "settingsOverlayBindStatus",
		descriptionKey = "settingsOverlayBindStatusTooltip",
		defaultAnchor = "BOTTOMRIGHT",
		defaultEnabled = false,
		previewText = "BoE",
		previewColor = { 0.38, 0.82, 1 },
	},
	{
		id = "equipmentSet",
		frameKey = "EquipmentSetIcon",
		textFrameKey = "EquipmentSetText",
		labelKey = "settingsOverlayEquipmentSet",
		descriptionKey = "settingsOverlayEquipmentSetTooltip",
		defaultAnchor = "BOTTOMLEFT",
		defaultEnabled = false,
		supportsDisplayMode = true,
		defaultDisplayMode = "icon",
		previewText = "SET",
		previewColor = { 0.36, 0.78, 1 },
	},
	{
		id = "itemLevel",
		frameKey = "ItemLevelText",
		labelKey = "settingsOverlayItemLevel",
		descriptionKey = "settingsOverlayItemLevelTooltip",
		defaultAnchor = "TOPLEFT",
		defaultEnabled = true,
		supportsColorMode = true,
		defaultColorMode = "rarity",
		defaultCustomColor = { 1, 1, 1 },
		previewText = "278",
		previewColor = { 0.8, 0.34, 1 },
	},
	{
		id = "upgradeTrack",
		frameKey = "ItemUpgradeText",
		labelKey = "settingsOverlayUpgradeTrack",
		descriptionKey = "settingsOverlayUpgradeTrackTooltip",
		defaultAnchor = "TOPRIGHT",
		defaultEnabled = false,
		trackFilter = true,
		previewText = "H (4/6)",
		previewColor = { 0.64, 0.21, 0.93 },
	},
}

local OVERLAY_COLOR_MODE_OPTIONS = {
	{
		value = "rarity",
		labelKey = "settingsOverlayColorModeRarity",
	},
	{
		value = "custom",
		labelKey = "settingsOverlayColorModeCustom",
	},
}

local OVERLAY_DISPLAY_MODE_OPTIONS = {
	{
		value = "icon",
		labelKey = "settingsOverlayDisplayModeIcon",
	},
	{
		value = "text",
		labelKey = "settingsOverlayDisplayModeText",
	},
}

local OVERLAY_ELEMENT_LOOKUP = {}
for _, definition in ipairs(OVERLAY_ELEMENTS) do
	OVERLAY_ELEMENT_LOOKUP[definition.id] = definition
end

local OVERLAY_COLOR_MODE_LOOKUP = {}
for _, option in ipairs(OVERLAY_COLOR_MODE_OPTIONS) do
	OVERLAY_COLOR_MODE_LOOKUP[option.value] = option
end

local OVERLAY_DISPLAY_MODE_LOOKUP = {}
for _, option in ipairs(OVERLAY_DISPLAY_MODE_OPTIONS) do
	OVERLAY_DISPLAY_MODE_LOOKUP[option.value] = option
end

local upgradeTrackOptionsSignatureCache = {
	options = nil,
	signature = nil,
}

local upgradeTrackVisibilityInitializationCache = setmetatable({}, { __mode = "k" })
local overlayConfigVersion = 0
local overlayRuntimeConfigCache
local overlayElementsSettingsTable

local function normalizeColorComponent(value, fallback)
	value = tonumber(value)
	if value == nil then
		value = fallback
	end
	if value == nil then
		value = 1
	end
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

local function normalizeOverlayColorMode(definition, value)
	value = tostring(value or definition.defaultColorMode or "rarity")
	if OVERLAY_COLOR_MODE_LOOKUP[value] then
		return value
	end
	return definition.defaultColorMode or "rarity"
end

local function normalizeOverlayDisplayMode(definition, value)
	value = tostring(value or definition.defaultDisplayMode or "icon")
	if OVERLAY_DISPLAY_MODE_LOOKUP[value] then
		return value
	end
	return definition.defaultDisplayMode or "icon"
end

local function copyColorTable(source, fallback)
	source = type(source) == "table" and source or fallback
	fallback = type(fallback) == "table" and fallback or { 1, 1, 1 }
	return {
		normalizeColorComponent(source and source[1], fallback[1]),
		normalizeColorComponent(source and source[2], fallback[2]),
		normalizeColorComponent(source and source[3], fallback[3]),
	}
end

local function getSettings()
	if addon.GetSettings then
		return addon.GetSettings()
	end

	addon.DB = addon.DB or {}
	addon.DB.settings = addon.DB.settings or {}
	return addon.DB.settings
end

local function invalidateOverlayRuntimeConfig()
	overlayConfigVersion = overlayConfigVersion + 1
	overlayRuntimeConfigCache = nil
end

local function getOverlayElementsSettingsTable()
	local settings = getSettings()
	settings.overlayElements = settings.overlayElements or {}

	if overlayElementsSettingsTable ~= settings.overlayElements then
		overlayElementsSettingsTable = settings.overlayElements
		invalidateOverlayRuntimeConfig()
	end

	return settings.overlayElements
end

local function getUpgradeTrackOptions()
	return addon.GetUpgradeTrackOptions and addon.GetUpgradeTrackOptions() or {}
end

local function getUpgradeTrackOptionsSignature(options)
	if upgradeTrackOptionsSignatureCache.options == options then
		return upgradeTrackOptionsSignatureCache.signature
	end

	local parts = {}
	for index, option in ipairs(options or {}) do
		parts[index] = tostring(option.value)
	end

	local signature = table.concat(parts, "|")
	upgradeTrackOptionsSignatureCache.options = options
	upgradeTrackOptionsSignatureCache.signature = signature
	return signature
end

local function buildDefaultUpgradeTrackVisibility(options)
	local visibility = {}

	for _, option in ipairs(options or {}) do
		visibility[option.value] = true
	end

	return visibility
end

function addon.GetOverlayAnchorOrder()
	return ANCHOR_ORDER
end

function addon.GetOverlayAnchorOptions()
	return ANCHOR_OPTIONS
end

function addon.GetOverlayAnchorInfo(anchorID)
	return ANCHOR_OPTIONS[anchorID] or ANCHOR_OPTIONS.TOPLEFT
end

function addon.GetOverlayElements()
	return OVERLAY_ELEMENTS
end

function addon.GetOverlayElementDefinition(elementID)
	return OVERLAY_ELEMENT_LOOKUP[elementID]
end

function addon.GetOverlayElementSettings(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition then
		return nil
	end

	local overlayElements = getOverlayElementsSettingsTable()

	if type(overlayElements[elementID]) ~= "table" then
		overlayElements[elementID] = {}
	end

	local elementSettings = overlayElements[elementID]
	if type(elementSettings.anchor) ~= "string" or not ANCHOR_OPTIONS[elementSettings.anchor] then
		elementSettings.anchor = definition.defaultAnchor or ANCHOR_ORDER[1]
	end
	if elementSettings.enabled == nil then
		elementSettings.enabled = definition.defaultEnabled ~= false
	end
	if definition.supportsColorMode then
		elementSettings.colorMode = normalizeOverlayColorMode(definition, elementSettings.colorMode)
		elementSettings.customColor = copyColorTable(elementSettings.customColor, definition.defaultCustomColor)
	end
	if definition.supportsDisplayMode then
		elementSettings.displayMode = normalizeOverlayDisplayMode(definition, elementSettings.displayMode)
	end
	if definition.trackFilter then
		local trackOptions = getUpgradeTrackOptions()
		local trackOptionsSignature = getUpgradeTrackOptionsSignature(trackOptions)
		if type(elementSettings.visibleTracks) ~= "table" then
			elementSettings.visibleTracks = buildDefaultUpgradeTrackVisibility(trackOptions)
		end

		if upgradeTrackVisibilityInitializationCache[elementSettings] ~= trackOptionsSignature then
			for _, option in ipairs(trackOptions) do
				if elementSettings.visibleTracks[option.value] == nil then
					elementSettings.visibleTracks[option.value] = true
				end
			end
			upgradeTrackVisibilityInitializationCache[elementSettings] = trackOptionsSignature
		end
	end

	return elementSettings
end

function addon.GetOverlayRuntimeConfig()
	if overlayRuntimeConfigCache then
		return overlayRuntimeConfigCache
	end

	local runtime = {
		version = overlayConfigVersion,
		entries = {},
		byID = {},
	}

	for _, definition in ipairs(OVERLAY_ELEMENTS) do
		local elementSettings = addon.GetOverlayElementSettings(definition.id)
		local isEnabled = definition.defaultEnabled ~= false
		if elementSettings and elementSettings.enabled ~= nil then
			isEnabled = elementSettings.enabled ~= false
		end
		local entry = {
			id = definition.id,
			frameKey = definition.frameKey,
			textFrameKey = definition.textFrameKey,
			enabled = isEnabled,
			anchorInfo = addon.GetOverlayAnchorInfo((elementSettings and elementSettings.anchor) or definition.defaultAnchor),
			colorMode = definition.supportsColorMode and normalizeOverlayColorMode(definition, elementSettings and elementSettings.colorMode) or nil,
			customColor = definition.supportsColorMode and copyColorTable(elementSettings and elementSettings.customColor, definition.defaultCustomColor) or nil,
			displayMode = definition.supportsDisplayMode and normalizeOverlayDisplayMode(definition, elementSettings and elementSettings.displayMode) or nil,
			visibleTracks = elementSettings and elementSettings.visibleTracks or nil,
		}
		runtime.entries[#runtime.entries + 1] = entry
		runtime.byID[definition.id] = entry
	end

	overlayRuntimeConfigCache = runtime
	return overlayRuntimeConfigCache
end

function addon.GetOverlayConfigVersion()
	return overlayConfigVersion
end

function addon.GetOverlayElementAnchor(elementID)
	local settings = addon.GetOverlayElementSettings(elementID)
	return settings and settings.anchor or nil
end

function addon.IsOverlayElementEnabled(elementID)
	local settings = addon.GetOverlayElementSettings(elementID)
	return settings and settings.enabled ~= false or false
end

function addon.SetOverlayElementEnabled(elementID, isEnabled)
	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return false
	end

	isEnabled = not not isEnabled
	if settings.enabled == isEnabled then
		return true
	end

	settings.enabled = not not isEnabled
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.SetOverlayElementAnchor(elementID, anchorID)
	if not addon.GetOverlayElementDefinition(elementID) or not ANCHOR_OPTIONS[anchorID] then
		return false
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return false
	end

	if settings.anchor == anchorID then
		return true
	end

	settings.anchor = anchorID
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.GetOverlayElementDisplayModeOptions(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsDisplayMode then
		return {}
	end

	local options = {}
	for _, option in ipairs(OVERLAY_DISPLAY_MODE_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = (addon.L and addon.L[option.labelKey]) or option.labelKey or option.value,
		}
	end

	return options
end

function addon.GetOverlayElementDisplayMode(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsDisplayMode then
		return nil
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	return settings and normalizeOverlayDisplayMode(definition, settings.displayMode) or definition.defaultDisplayMode or "icon"
end

function addon.SetOverlayElementDisplayMode(elementID, displayMode)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsDisplayMode then
		return false
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return false
	end

	displayMode = normalizeOverlayDisplayMode(definition, displayMode)
	if settings.displayMode == displayMode then
		return true
	end

	settings.displayMode = displayMode
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.GetOverlayElementColorModeOptions(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsColorMode then
		return {}
	end

	local options = {}
	for _, option in ipairs(OVERLAY_COLOR_MODE_OPTIONS) do
		options[#options + 1] = {
			value = option.value,
			label = (addon.L and addon.L[option.labelKey]) or option.labelKey or option.value,
		}
	end

	return options
end

function addon.GetOverlayElementColorMode(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsColorMode then
		return nil
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	return settings and normalizeOverlayColorMode(definition, settings.colorMode) or definition.defaultColorMode or "rarity"
end

function addon.SetOverlayElementColorMode(elementID, colorMode)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsColorMode then
		return false
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return false
	end

	colorMode = normalizeOverlayColorMode(definition, colorMode)
	if settings.colorMode == colorMode then
		return true
	end

	settings.colorMode = colorMode
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.GetOverlayElementCustomColor(elementID)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsColorMode then
		return nil
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return copyColorTable(nil, definition.defaultCustomColor)
	end

	settings.customColor = copyColorTable(settings.customColor, definition.defaultCustomColor)
	return copyColorTable(settings.customColor, definition.defaultCustomColor)
end

function addon.SetOverlayElementCustomColor(elementID, r, g, b)
	local definition = addon.GetOverlayElementDefinition(elementID)
	if not definition or not definition.supportsColorMode then
		return false
	end

	local settings = addon.GetOverlayElementSettings(elementID)
	if not settings then
		return false
	end

	local currentColor = copyColorTable(settings.customColor, definition.defaultCustomColor)
	local newColor = {
		normalizeColorComponent(r, currentColor[1]),
		normalizeColorComponent(g, currentColor[2]),
		normalizeColorComponent(b, currentColor[3]),
	}

	if currentColor[1] == newColor[1] and currentColor[2] == newColor[2] and currentColor[3] == newColor[3] then
		return true
	end

	settings.customColor = newColor
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.IsUpgradeTrackOverlayTrackEnabled(trackKey)
	local canonicalKey = addon.NormalizeUpgradeTrackKey and addon.NormalizeUpgradeTrackKey(nil, trackKey) or trackKey
	if not canonicalKey then
		return false
	end

	local settings = addon.GetOverlayElementSettings("upgradeTrack")
	if not settings or type(settings.visibleTracks) ~= "table" then
		return true
	end

	return settings.visibleTracks[canonicalKey] ~= false
end

function addon.SetUpgradeTrackOverlayTrackEnabled(trackKey, isEnabled)
	local canonicalKey = addon.NormalizeUpgradeTrackKey and addon.NormalizeUpgradeTrackKey(nil, trackKey) or trackKey
	if not canonicalKey then
		return false
	end

	local settings = addon.GetOverlayElementSettings("upgradeTrack")
	if not settings then
		return false
	end

	settings.visibleTracks = settings.visibleTracks or buildDefaultUpgradeTrackVisibility(getUpgradeTrackOptions())
	isEnabled = not not isEnabled
	if settings.visibleTracks[canonicalKey] == isEnabled then
		return true
	end

	settings.visibleTracks[canonicalKey] = isEnabled
	invalidateOverlayRuntimeConfig()
	return true
end

function addon.ApplyBasicOverlayDefaultsIfUnconfigured()
	local settings = getSettings()
	if type(settings.overlayElements) ~= "table" then
		settings.overlayElements = {}
	end

	local itemLevelSettings = settings.overlayElements.itemLevel
	if type(itemLevelSettings) == "table" and itemLevelSettings.anchor ~= nil and itemLevelSettings.enabled ~= nil then
		return false
	end

	if type(itemLevelSettings) ~= "table" then
		itemLevelSettings = {}
		settings.overlayElements.itemLevel = itemLevelSettings
	end

	local changed = false
	if itemLevelSettings.enabled == nil then
		itemLevelSettings.enabled = true
		changed = true
	end
	if itemLevelSettings.anchor == nil then
		itemLevelSettings.anchor = "TOPLEFT"
		changed = true
	end

	if changed then
		invalidateOverlayRuntimeConfig()
	end

	return changed
end
