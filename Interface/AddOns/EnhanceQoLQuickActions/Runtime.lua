local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = _G.LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local QC = addon.QuickCast

QC.MAX_MENUS = 16
QC.DEFAULT_ICON_SIZE = 44
QC.DEFAULT_SPACING = 40
QC.MAX_SPACING = 100
QC.DEFAULT_RADIAL_SPACING_OFFSET = 0
QC.DEFAULT_ICON_SHAPE = "DEFAULT"
QC.DEFAULT_ICON_ZOOM = 0
QC.DEFAULT_ICON_BORDER_COLOR = { 0, 0, 0, 0.8 }
QC.DEFAULT_ICON_BORDER_SIZE = 1
QC.DEFAULT_ICON_BORDER_OFFSET = 0
QC.MIN_ICON_BORDER_SIZE = 1
QC.MAX_ICON_BORDER_SIZE = 64
QC.MIN_ICON_BORDER_OFFSET = -64
QC.MAX_ICON_BORDER_OFFSET = 64
QC.DEFAULT_ICON_BORDER_TEXTURE = "DEFAULT"
QC.DEFAULT_LABEL_ANCHOR = "BOTTOM"
QC.DEFAULT_LABEL_COLOR = { 1, 0.82, 0, 1 }
QC.DEFAULT_LABEL_FONT = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__"
QC.DEFAULT_LABEL_FONT_OUTLINE = addon.functions
	and addon.functions.GetGlobalFontStyleConfigKey
	and addon.functions.GetGlobalFontStyleConfigKey()
	or "__EQOL_GLOBAL_FONT_STYLE__"
QC.DEFAULT_LABEL_FONT_SIZE = 11
QC.DEFAULT_LABEL_CHARACTER_LIMIT = 0
QC.MAX_LABEL_CHARACTER_LIMIT = 50
QC.DEFAULT_LABEL_OFFSET_X = 0
QC.DEFAULT_LABEL_OFFSET_Y = -2
QC.DEFAULT_SHOW_TITLE = false
QC.TITLE_ANCHOR_TOP = "TOP"
QC.TITLE_ANCHOR_CENTER = "CENTER"
QC.TITLE_ANCHOR_BOTTOM = "BOTTOM"
QC.DEFAULT_TITLE_ANCHOR = QC.TITLE_ANCHOR_TOP
QC.DEFAULT_TITLE_COLOR = { 1, 0.82, 0, 1 }
QC.DEFAULT_TITLE_FONT = QC.DEFAULT_LABEL_FONT
QC.DEFAULT_TITLE_FONT_OUTLINE = QC.DEFAULT_LABEL_FONT_OUTLINE
QC.DEFAULT_TITLE_FONT_SIZE = 14
QC.DEFAULT_TITLE_OFFSET_X = 0
QC.DEFAULT_TITLE_OFFSET_Y = 0
QC.DEFAULT_TITLE_USE_CLASS_COLOR = false
QC.MIN_TITLE_FONT_SIZE = 8
QC.MAX_TITLE_FONT_SIZE = 40
QC.MIN_TITLE_OFFSET = -300
QC.MAX_TITLE_OFFSET = 300
QC.TITLE_GAP = 12
QC.DEFAULT_COUNT_ANCHOR = "BOTTOMRIGHT"
QC.DEFAULT_COUNT_COLOR = { 1, 1, 1, 1 }
QC.DEFAULT_COUNT_FONT = QC.DEFAULT_LABEL_FONT
QC.DEFAULT_COUNT_FONT_OUTLINE = QC.DEFAULT_LABEL_FONT_OUTLINE
QC.DEFAULT_COUNT_FONT_SIZE = 12
QC.DEFAULT_COUNT_OFFSET_X = -2
QC.DEFAULT_COUNT_OFFSET_Y = 2
QC.ANIMATION_STYLE_NONE = "NONE"
QC.ANIMATION_STYLE_REDUCED = "REDUCED"
QC.ANIMATION_STYLE_DYNAMIC = "DYNAMIC"
QC.DEFAULT_ANIMATION_STYLE = QC.ANIMATION_STYLE_DYNAMIC
QC.ACTIVATION_MODE_HOLD = "HOLD"
QC.ACTIVATION_MODE_TOGGLE = "TOGGLE"
QC.DEFAULT_ACTIVATION_MODE = QC.ACTIVATION_MODE_HOLD
QC.SELECTION_INDICATOR_LINES = "LINES"
QC.SELECTION_INDICATOR_ARROWS = "ARROWS"
QC.SELECTION_INDICATOR_NONE = "NONE"
QC.DEFAULT_SELECTION_INDICATOR = QC.SELECTION_INDICATOR_ARROWS
QC.DEFAULT_SELECTION_INDICATOR_COLOR = { 1, 0.82, 0.12, 1 }
QC.DEFAULT_SELECTION_ICON_SCALE = 1.5
QC.MIN_SELECTION_ICON_SCALE = 1
QC.MAX_SELECTION_ICON_SCALE = 3
QC.DEFAULT_SELECTION_OVERLAY_ENABLED = false
QC.DEFAULT_UNSELECTED_ICON_ALPHA = 0.74
QC.SELECTION_LINE_PIXELS = 2
QC.SELECTION_LINE_OUTLINE_PIXELS = 4
QC.SELECTION_FRAME_LEVEL_OFFSET = 8
QC.LABEL_MAX_WIDTH = 110
QC.CONFIG_VERSION = 3
QC.DEAD_ZONE = 30
QC.SELECTION_DEAD_ZONE = 45
QC.TRANSMOG_OUTFIT_COOLDOWN_SPELL_ID = 1247613
QC.MAX_OFFSET = 300
QC.MAX_LINEAR_OFFSET = QC.MAX_OFFSET
QC.Animation = {
	OPEN_REDUCED_DURATION = 0.14,
	OPEN_DYNAMIC_DURATION = 0.09,
	OPEN_DYNAMIC_STAGGER_WINDOW = 0.08,
	SELECTION_DURATION = 0.075,
	CLOSE_REDUCED_DURATION = 0.10,
	CLOSE_DYNAMIC_DURATION = 0.12,
}
QC.WORLD_MARKER_ATLAS_INDEX = {
	[1] = 3,
	[2] = 5,
	[3] = 6,
	[4] = 2,
	[5] = 8,
	[6] = 7,
	[7] = 4,
	[8] = 1,
}
QC.RAID_TARGET_ATLAS_INDEX = {
	[1] = 8,
	[2] = 7,
	[3] = 6,
	[4] = 5,
	[5] = 4,
	[6] = 3,
	[7] = 2,
	[8] = 1,
}

QC.EQOL_ACTIONS = {
	auctionMount = {
		iconSpellID = 264058,
		labelKey = "Auction House Mount",
		mountAction = "ah",
	},
	hearthstone = {
		iconItemID = 6948,
		labelKey = "teleportsRandomHearthstoneBinding",
	},
	randomMount = {
		iconSpellID = 150544,
		labelKey = "Random Mount",
		mountAction = "random",
	},
	repairMount = {
		iconSpellID = 122708,
		labelKey = "Repair Mount",
		mountAction = "repair",
	},
}

QC.MANAGED_SOURCE_CURRENT_SEASON = "currentSeasonMPlus"
QC.MANAGED_SOURCE_TELEPORT_FAVORITES = "teleportFavorites"

local TWO_PI = math.pi * 2
local SECURE_BUTTON_NAME = "EQOLQuickCastSecureButton"

function QC:GetMenuMacroText(menuID)
	menuID = tonumber(menuID)
	if not menuID or not self:GetMenu(menuID) then return nil end
	return "/click " .. SECURE_BUTTON_NAME .. " " .. tostring(-menuID)
end

local compiledMenuIDs = {}
local compiledActionCounts = {}
local compiledEntries = {}
local compiledActionButtons = {}
local rebuildPending = false
local managedSourcesDirty = true
local heldMenuID
local spellCooldownActiveCache = {}
local traceState = {
	active = false,
	counts = {},
	eventCounts = {},
	lastRegisteredStateEvents = {},
	spellEventCounts = {},
}

local function clamp(value, minimum, maximum)
	value = tonumber(value) or minimum
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function trim(value)
	if type(value) ~= "string" then return "" end
	return value:match("^%s*(.-)%s*$") or ""
end

local function normalizeColor(value, fallback)
	value = type(value) == "table" and value or fallback
	fallback = type(fallback) == "table" and fallback or { 1, 1, 1, 1 }
	return {
		clamp(value[1] or value.r or fallback[1] or fallback.r or 1, 0, 1),
		clamp(value[2] or value.g or fallback[2] or fallback.g or 1, 0, 1),
		clamp(value[3] or value.b or fallback[3] or fallback.b or 1, 0, 1),
		clamp(value[4] or value.a or fallback[4] or fallback.a or 1, 0, 1),
	}
end

function QC:NormalizeAnimationStyle(value)
	value = type(value) == "string" and value:upper() or nil
	if value == self.ANIMATION_STYLE_NONE or value == self.ANIMATION_STYLE_REDUCED or value == self.ANIMATION_STYLE_DYNAMIC then
		return value
	end
	return self.DEFAULT_ANIMATION_STYLE
end

function QC:NormalizeActivationMode(value)
	value = type(value) == "string" and value:upper() or nil
	if value == self.ACTIVATION_MODE_HOLD or value == self.ACTIVATION_MODE_TOGGLE then return value end
	return self.DEFAULT_ACTIVATION_MODE
end

function QC:NormalizeSelectionIndicator(value)
	value = type(value) == "string" and value:upper() or nil
	if value == "TRIANGLE" then value = self.SELECTION_INDICATOR_ARROWS end
	if value == self.SELECTION_INDICATOR_LINES
		or value == self.SELECTION_INDICATOR_ARROWS
		or value == self.SELECTION_INDICATOR_NONE
	then
		return value
	end
	return self.DEFAULT_SELECTION_INDICATOR
end

local function getConfig()
	addon.db = addon.db or {}
	local config = addon.db.quickCast
	if type(config) ~= "table" then
		config = {}
		addon.db.quickCast = config
	end
	local version = math.floor(tonumber(config.version) or 0)
	if version < 2 then version = 2 end
	config.version = version
	config.nextMenuID = math.max(1, math.floor(tonumber(config.nextMenuID) or 1))
	config.activationMode = QC:NormalizeActivationMode(config.activationMode)
	config.animationStyle = QC:NormalizeAnimationStyle(config.animationStyle)
	config.selectionIndicator = QC:NormalizeSelectionIndicator(config.selectionIndicator)
	config.selectionIndicatorColor = normalizeColor(config.selectionIndicatorColor, QC.DEFAULT_SELECTION_INDICATOR_COLOR)
	config.selectionIconScale = clamp(
		tonumber(config.selectionIconScale) or QC.DEFAULT_SELECTION_ICON_SCALE,
		QC.MIN_SELECTION_ICON_SCALE,
		QC.MAX_SELECTION_ICON_SCALE
	)
	config.selectionOverlayEnabled = config.selectionOverlayEnabled == true
	config.unselectedIconAlpha = clamp(
		tonumber(config.unselectedIconAlpha) or QC.DEFAULT_UNSELECTED_ICON_ALPHA,
		0,
		1
	)
	config.menus = type(config.menus) == "table" and config.menus or {}
	config.order = type(config.order) == "table" and config.order or {}
	return config
end

local function getOrderedMenu(index)
	local config = getConfig()
	local id = config.order[index]
	return id and config.menus[id] or nil
end

local function normalizeSpecFilter(specs)
	local normalizedSpecs = {}
	if type(specs) == "table" then
		for rawSpecID, selected in pairs(specs) do
			local specID = tonumber(rawSpecID)
			if selected and specID and specID > 0 then normalizedSpecs[math.floor(specID)] = true end
		end
	end
	return normalizedSpecs
end

local function normalizeConditions(conditions)
	conditions = type(conditions) == "table" and conditions or {}
	local sourceCooldown = type(conditions.cooldown) == "table" and conditions.cooldown or {}
	local sourceInventory = type(conditions.inventory) == "table" and conditions.inventory or {}
	local useMenu = sourceCooldown.useMenu
	if type(useMenu) ~= "boolean" then useMenu = sourceCooldown.enabled ~= true end
	local useMenuInventory = sourceInventory.useMenu
	if type(useMenuInventory) ~= "boolean" then useMenuInventory = sourceInventory.enabled ~= true end

	return {
		specs = normalizeSpecFilter(conditions.specs),
		cooldown = {
			enabled = sourceCooldown.enabled == true,
			useMenu = useMenu,
		},
		inventory = {
			enabled = sourceInventory.enabled == true,
			useMenu = useMenuInventory,
		},
	}
end

local function normalizeAction(action, entryID)
	if type(action) ~= "table" then return nil end
	local kind = action.kind
	local normalized
	if kind == "spell" then
		local id = tonumber(action.id)
		if id and id > 0 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "item" then
		local id = tonumber(action.id)
		if id and id > 0 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "mount" then
		local id = tonumber(action.id)
		if id and id > 0 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "battlepet" then
		local id = trim(action.id)
		if id ~= "" then normalized = { kind = kind, id = id } end
	elseif kind == "macro" then
		local name = trim(action.name)
		local indexHint = tonumber(action.indexHint)
		if name ~= "" then normalized = { kind = kind, name = name, indexHint = indexHint and math.floor(indexHint) or nil } end
	elseif kind == "worldmarker" or kind == "raidtarget" then
		local id = tonumber(action.id or action.marker)
		local minimum = kind == "worldmarker" and 0 or 1
		if id and id >= minimum and id <= 8 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "equipmentset" then
		local id = tonumber(action.id)
		local ownerGUID = trim(action.ownerGUID)
		if id and id >= 0 and ownerGUID ~= "" then
			normalized = {
				kind = kind,
				id = math.floor(id),
				name = trim(action.name),
				ownerGUID = ownerGUID,
			}
			if normalized.name == "" then normalized.name = nil end
		end
	elseif kind == "outfit" then
		local id = tonumber(action.id)
		if id and id > 0 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "menu" then
		local id = tonumber(action.id)
		if id and id > 0 then normalized = { kind = kind, id = math.floor(id) } end
	elseif kind == "eqol" then
		local id = trim(action.id)
		if QC.EQOL_ACTIONS[id] then normalized = { kind = kind, id = id } end
	end
	if not normalized then return nil end
	normalized.entryID = entryID
	normalized.enabled = action.enabled ~= false
	normalized.showLabel = type(action.showLabel) == "boolean" and action.showLabel or nil
	normalized.customLabel = trim(action.customLabel)
	if normalized.customLabel == "" then normalized.customLabel = nil end
	if type(action.customIcon) == "number" and action.customIcon > 0 then
		normalized.customIcon = math.floor(action.customIcon)
	elseif type(action.customIcon) == "string" and trim(action.customIcon) ~= "" then
		normalized.customIcon = trim(action.customIcon)
	end
	normalized.customIconAtlas = trim(action.customIconAtlas)
	if normalized.customIconAtlas == "" then normalized.customIconAtlas = nil end
	normalized.managedSource = trim(action.managedSource)
	if normalized.managedSource == "" then normalized.managedSource = nil end
	normalized.managedKey = trim(action.managedKey)
	if normalized.managedKey == "" then normalized.managedKey = nil end
	normalized.managedLabel = trim(action.managedLabel)
	if normalized.managedLabel == "" then normalized.managedLabel = nil end
	normalized.conditions = normalizeConditions(action.conditions)
	return normalized
end

local function normalizeMenu(menu, id, migrateGlobalLabelDefaults)
	menu.id = tonumber(id) or tonumber(menu.id)
	menu.name = trim(menu.name)
	if menu.name == "" then menu.name = (L["QuickCast"] or "QuickActions") .. " " .. tostring(menu.id or "") end
	menu.enabled = menu.enabled ~= false
	if menu.layout ~= "horizontal" and menu.layout ~= "vertical" then menu.layout = "radial" end
	menu.hotkey = trim(menu.hotkey)
	if menu.hotkey == "" then menu.hotkey = nil end
	menu.iconSize = clamp(menu.iconSize or QC.DEFAULT_ICON_SIZE, 32, 64)
	menu.spacing = clamp(menu.spacing or QC.DEFAULT_SPACING, 0, QC.MAX_SPACING)
	menu.radialSpacingOffset = clamp(menu.radialSpacingOffset or QC.DEFAULT_RADIAL_SPACING_OFFSET, -100, 300)
	menu.radius = nil
	menu.showLabels = menu.showLabels ~= false
	menu.showTitle = type(menu.showTitle) == "boolean" and menu.showTitle or QC.DEFAULT_SHOW_TITLE
	menu.showTooltips = menu.showTooltips ~= false
	menu.showAtCursor = menu.showAtCursor == true
	menu.hideOnCooldown = menu.hideOnCooldown == true
	menu.hideMissingItems = menu.hideMissingItems == true
	menu.hideOtherSpecs = menu.hideOtherSpecs == true
	menu.specFilter = normalizeSpecFilter(menu.specFilter)
	menu.managedSources = type(menu.managedSources) == "table" and menu.managedSources or {}
	menu.managedSources[QC.MANAGED_SOURCE_CURRENT_SEASON] = menu.managedSources[QC.MANAGED_SOURCE_CURRENT_SEASON] == true or nil
	menu.managedSources[QC.MANAGED_SOURCE_TELEPORT_FAVORITES] = menu.managedSources[QC.MANAGED_SOURCE_TELEPORT_FAVORITES] == true or nil
	local iconShape = addon.IconShape
	menu.iconShape = iconShape and iconShape.Normalize and iconShape.Normalize(menu.iconShape, QC.DEFAULT_ICON_SHAPE) or QC.DEFAULT_ICON_SHAPE
	menu.iconZoom = iconShape and iconShape.NormalizeIconZoom
		and iconShape.NormalizeIconZoom(menu.iconZoom, QC.DEFAULT_ICON_ZOOM)
		or clamp(menu.iconZoom or QC.DEFAULT_ICON_ZOOM, 0, 35)
	menu.iconBorderEnabled = menu.iconBorderEnabled == true
	if menu.iconBorderUseItemQualityColor == nil and type(menu.iconBorderUseIconColor) == "boolean" then
		menu.iconBorderUseItemQualityColor = menu.iconBorderUseIconColor
	end
	menu.iconBorderUseItemQualityColor = menu.iconBorderUseItemQualityColor ~= false
	menu.iconBorderUseIconColor = nil
	menu.iconBorderSize = clamp(menu.iconBorderSize or QC.DEFAULT_ICON_BORDER_SIZE, QC.MIN_ICON_BORDER_SIZE, QC.MAX_ICON_BORDER_SIZE)
	menu.iconBorderOffset = clamp(menu.iconBorderOffset or QC.DEFAULT_ICON_BORDER_OFFSET, QC.MIN_ICON_BORDER_OFFSET, QC.MAX_ICON_BORDER_OFFSET)
	menu.iconBorderColor = normalizeColor(menu.iconBorderColor, QC.DEFAULT_ICON_BORDER_COLOR)
	if iconShape and iconShape.NormalizeBorder then
		menu.iconBorderTexture = iconShape.NormalizeBorder(
			menu.iconBorderTexture,
			QC.DEFAULT_ICON_BORDER_TEXTURE,
			menu.iconShape,
			{ allowNone = true }
		)
	else
		menu.iconBorderTexture = trim(menu.iconBorderTexture)
		if menu.iconBorderTexture == "" then menu.iconBorderTexture = QC.DEFAULT_ICON_BORDER_TEXTURE end
	end
	menu.labelFont = trim(menu.labelFont)
	if migrateGlobalLabelDefaults and menu.labelFont == "Friz Quadrata TT" then menu.labelFont = QC.DEFAULT_LABEL_FONT end
	if menu.labelFont == "" then menu.labelFont = QC.DEFAULT_LABEL_FONT end
	menu.labelFontSize = clamp(menu.labelFontSize or QC.DEFAULT_LABEL_FONT_SIZE, 8, 28)
	local labelFontOutline = trim(menu.labelFontOutline)
	if migrateGlobalLabelDefaults and labelFontOutline:upper() == "OUTLINE" then labelFontOutline = QC.DEFAULT_LABEL_FONT_OUTLINE end
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		labelFontOutline = addon.functions.NormalizeFontStyleChoice(labelFontOutline, QC.DEFAULT_LABEL_FONT_OUTLINE, true)
	else
		labelFontOutline = labelFontOutline:upper()
		if labelFontOutline ~= "NONE"
			and labelFontOutline ~= "OUTLINE"
			and labelFontOutline ~= "THICKOUTLINE"
			and labelFontOutline ~= "MONOCHROME"
			and labelFontOutline ~= "MONOCHROMEOUTLINE"
		then
			labelFontOutline = QC.DEFAULT_LABEL_FONT_OUTLINE
		end
	end
	menu.labelFontOutline = labelFontOutline
	menu.labelColor = normalizeColor(menu.labelColor, QC.DEFAULT_LABEL_COLOR)
	menu.labelCharacterLimit = math.floor(clamp(menu.labelCharacterLimit or QC.DEFAULT_LABEL_CHARACTER_LIMIT, 0, QC.MAX_LABEL_CHARACTER_LIMIT))
	local labelAnchor = trim(menu.labelAnchor):upper()
	if labelAnchor ~= "TOP" and labelAnchor ~= "BOTTOM" and labelAnchor ~= "LEFT" and labelAnchor ~= "RIGHT" and labelAnchor ~= "CENTER" then
		labelAnchor = QC.DEFAULT_LABEL_ANCHOR
	end
	menu.labelAnchor = labelAnchor
	menu.labelOffsetX = clamp(menu.labelOffsetX or QC.DEFAULT_LABEL_OFFSET_X, -100, 100)
	menu.labelOffsetY = clamp(menu.labelOffsetY or QC.DEFAULT_LABEL_OFFSET_Y, -100, 100)
	menu.titleFont = trim(menu.titleFont)
	if migrateGlobalLabelDefaults and menu.titleFont == "Friz Quadrata TT" then menu.titleFont = QC.DEFAULT_TITLE_FONT end
	if menu.titleFont == "" then menu.titleFont = QC.DEFAULT_TITLE_FONT end
	menu.titleFontSize = clamp(menu.titleFontSize or QC.DEFAULT_TITLE_FONT_SIZE, QC.MIN_TITLE_FONT_SIZE, QC.MAX_TITLE_FONT_SIZE)
	labelFontOutline = trim(menu.titleFontOutline)
	if migrateGlobalLabelDefaults and labelFontOutline:upper() == "OUTLINE" then labelFontOutline = QC.DEFAULT_TITLE_FONT_OUTLINE end
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		labelFontOutline = addon.functions.NormalizeFontStyleChoice(labelFontOutline, QC.DEFAULT_TITLE_FONT_OUTLINE, true)
	else
		labelFontOutline = labelFontOutline:upper()
		if labelFontOutline ~= "NONE"
			and labelFontOutline ~= "OUTLINE"
			and labelFontOutline ~= "THICKOUTLINE"
			and labelFontOutline ~= "MONOCHROME"
			and labelFontOutline ~= "MONOCHROMEOUTLINE"
		then
			labelFontOutline = QC.DEFAULT_TITLE_FONT_OUTLINE
		end
	end
	menu.titleFontOutline = labelFontOutline
	menu.titleColor = normalizeColor(menu.titleColor, QC.DEFAULT_TITLE_COLOR)
	menu.titleUseClassColor = menu.titleUseClassColor == true
	local titleAnchor = trim(menu.titleAnchor):upper()
	if titleAnchor ~= QC.TITLE_ANCHOR_TOP
		and titleAnchor ~= QC.TITLE_ANCHOR_CENTER
		and titleAnchor ~= QC.TITLE_ANCHOR_BOTTOM
	then
		titleAnchor = QC.DEFAULT_TITLE_ANCHOR
	end
	menu.titleAnchor = titleAnchor
	menu.titleOffsetX = clamp(menu.titleOffsetX or QC.DEFAULT_TITLE_OFFSET_X, QC.MIN_TITLE_OFFSET, QC.MAX_TITLE_OFFSET)
	menu.titleOffsetY = clamp(menu.titleOffsetY or QC.DEFAULT_TITLE_OFFSET_Y, QC.MIN_TITLE_OFFSET, QC.MAX_TITLE_OFFSET)
	menu.countFont = trim(menu.countFont)
	if migrateGlobalLabelDefaults and menu.countFont == "Friz Quadrata TT" then menu.countFont = QC.DEFAULT_COUNT_FONT end
	if menu.countFont == "" then menu.countFont = QC.DEFAULT_COUNT_FONT end
	menu.countFontSize = clamp(menu.countFontSize or QC.DEFAULT_COUNT_FONT_SIZE, 6, 32)
	local countFontOutline = trim(menu.countFontOutline)
	if migrateGlobalLabelDefaults and countFontOutline:upper() == "OUTLINE" then countFontOutline = QC.DEFAULT_COUNT_FONT_OUTLINE end
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		countFontOutline = addon.functions.NormalizeFontStyleChoice(countFontOutline, QC.DEFAULT_COUNT_FONT_OUTLINE, true)
	else
		countFontOutline = countFontOutline:upper()
		if countFontOutline ~= "NONE"
			and countFontOutline ~= "OUTLINE"
			and countFontOutline ~= "THICKOUTLINE"
			and countFontOutline ~= "MONOCHROME"
			and countFontOutline ~= "MONOCHROMEOUTLINE"
		then
			countFontOutline = QC.DEFAULT_COUNT_FONT_OUTLINE
		end
	end
	menu.countFontOutline = countFontOutline
	menu.countColor = normalizeColor(menu.countColor, QC.DEFAULT_COUNT_COLOR)
	local countAnchor = trim(menu.countAnchor):upper()
	if countAnchor ~= "TOPLEFT"
		and countAnchor ~= "TOP"
		and countAnchor ~= "TOPRIGHT"
		and countAnchor ~= "LEFT"
		and countAnchor ~= "CENTER"
		and countAnchor ~= "RIGHT"
		and countAnchor ~= "BOTTOMLEFT"
		and countAnchor ~= "BOTTOM"
		and countAnchor ~= "BOTTOMRIGHT"
	then
		countAnchor = QC.DEFAULT_COUNT_ANCHOR
	end
	menu.countAnchor = countAnchor
	menu.countOffsetX = clamp(menu.countOffsetX or QC.DEFAULT_COUNT_OFFSET_X, -100, 100)
	menu.countOffsetY = clamp(menu.countOffsetY or QC.DEFAULT_COUNT_OFFSET_Y, -100, 100)

	local anchor = menu.anchor
	local migratedOffsetX = menu.offsetX
	local migratedOffsetY = menu.offsetY
	if anchor ~= "CENTER" and anchor ~= "LEFT" and anchor ~= "RIGHT" and anchor ~= "TOP" and anchor ~= "BOTTOM" then
		local oldPlacement = menu.linearPlacement
		local oldOffset = clamp(menu.linearOffset or 0, 0, 200)
		if menu.layout == "horizontal" then
			if oldPlacement == "positive" then
				anchor = "RIGHT"
				if migratedOffsetX == nil then migratedOffsetX = oldOffset end
			elseif oldPlacement == "negative" then
				anchor = "LEFT"
				if migratedOffsetX == nil then migratedOffsetX = -oldOffset end
			else
				anchor = "CENTER"
			end
		elseif menu.layout == "vertical" then
			if oldPlacement == "positive" then
				anchor = "TOP"
				if migratedOffsetY == nil then migratedOffsetY = oldOffset end
			elseif oldPlacement == "negative" then
				anchor = "BOTTOM"
				if migratedOffsetY == nil then migratedOffsetY = -oldOffset end
			else
				anchor = "CENTER"
			end
		else
			anchor = "CENTER"
		end
	end
	menu.anchor = anchor
	if menu.layout == "horizontal" then
		menu.direction = menu.direction == "LEFT" and "LEFT" or "RIGHT"
	elseif menu.layout == "vertical" then
		menu.direction = menu.direction == "UP" and "UP" or "DOWN"
	else
		menu.direction = nil
	end
	menu.offsetX = clamp(migratedOffsetX or 0, -QC.MAX_OFFSET, QC.MAX_OFFSET)
	menu.offsetY = clamp(migratedOffsetY or 0, -QC.MAX_OFFSET, QC.MAX_OFFSET)
	menu.linearPlacement = nil
	menu.linearOffset = nil

	menu.actions = type(menu.actions) == "table" and menu.actions or {}
	local actions = {}
	local usedEntryIDs = {}
	local nextEntryID = math.max(1, math.floor(tonumber(menu.nextEntryID) or 1))
	for index = 1, #menu.actions do
		local sourceAction = menu.actions[index]
		local entryID = type(sourceAction) == "table" and tonumber(sourceAction.entryID) or nil
		entryID = entryID and entryID > 0 and math.floor(entryID) or nil
		if entryID and usedEntryIDs[entryID] then entryID = nil end
		if not entryID then
			while usedEntryIDs[nextEntryID] do nextEntryID = nextEntryID + 1 end
			entryID = nextEntryID
		end
		local action = normalizeAction(sourceAction, entryID)
		if action then
			usedEntryIDs[entryID] = true
			if nextEntryID <= entryID then nextEntryID = entryID + 1 end
			actions[#actions + 1] = action
		end
	end
	menu.actions = actions
	local defaultEntryID = tonumber(menu.defaultEntryID)
	defaultEntryID = defaultEntryID and defaultEntryID > 0 and math.floor(defaultEntryID) or nil
	local defaultAction
	if defaultEntryID and usedEntryIDs[defaultEntryID] then
		for index = 1, #actions do
			if actions[index].entryID == defaultEntryID then
				defaultAction = actions[index]
				break
			end
		end
	end
	menu.defaultEntryID = defaultAction and defaultAction.kind ~= "menu" and defaultEntryID or nil
	while usedEntryIDs[nextEntryID] do nextEntryID = nextEntryID + 1 end
	menu.nextEntryID = nextEntryID
	return menu
end

function QC:Normalize()
	local config = getConfig()
	local migrateGlobalLabelDefaults = (tonumber(config.version) or 0) < self.CONFIG_VERSION
	local seen = {}
	local order = {}
	for index = 1, #config.order do
		local id = tonumber(config.order[index])
		if id and type(config.menus[id]) == "table" and not seen[id] then
			seen[id] = true
			config.menus[id] = normalizeMenu(config.menus[id], id, migrateGlobalLabelDefaults)
			order[#order + 1] = id
		end
	end
	for rawID, menu in pairs(config.menus) do
		local id = tonumber(rawID)
		if id and type(menu) == "table" and not seen[id] then
			if rawID ~= id then config.menus[rawID] = nil end
			config.menus[id] = normalizeMenu(menu, id, migrateGlobalLabelDefaults)
			seen[id] = true
			order[#order + 1] = id
		end
	end
	local positions = {}
	for index = 1, #config.order do positions[config.order[index]] = index end
	table.sort(order, function(a, b)
		local ai, bi = positions[a], positions[b]
		if ai and bi then return ai < bi end
		if ai then return true end
		if bi then return false end
		return a < b
	end)
	config.order = order
	local highest = 0
	for index = 1, #order do
		if order[index] > highest then highest = order[index] end
	end
	if config.nextMenuID <= highest then config.nextMenuID = highest + 1 end
	config.version = math.max(tonumber(config.version) or 0, self.CONFIG_VERSION)
	return config
end

function QC:GetConfig()
	return getConfig()
end

function QC:GetActivationMode()
	return self:NormalizeActivationMode(self:GetConfig().activationMode)
end

function QC:SetActivationMode(value)
	local mode = self:NormalizeActivationMode(value)
	self:GetConfig().activationMode = mode
	self:QueueSecureRebuild()
	return mode
end

function QC:GetAnimationStyle()
	return self:NormalizeAnimationStyle(self:GetConfig().animationStyle)
end

function QC:SetAnimationStyle(value)
	local style = self:NormalizeAnimationStyle(value)
	self:GetConfig().animationStyle = style
	return style
end

function QC:GetSelectionIndicator()
	return self:NormalizeSelectionIndicator(self:GetConfig().selectionIndicator)
end

function QC:SetSelectionIndicator(value)
	local indicator = self:NormalizeSelectionIndicator(value)
	self:GetConfig().selectionIndicator = indicator
	return indicator
end

function QC:GetSelectionIndicatorColor()
	return self:GetConfig().selectionIndicatorColor
end

function QC:SetSelectionIndicatorColor(r, g, b, a)
	local color = normalizeColor({ r, g, b, a }, self.DEFAULT_SELECTION_INDICATOR_COLOR)
	self:GetConfig().selectionIndicatorColor = color
	return color
end

function QC:GetSelectionIconScale()
	return self:GetConfig().selectionIconScale
end

function QC:SetSelectionIconScale(value)
	local scale = clamp(
		tonumber(value) or self.DEFAULT_SELECTION_ICON_SCALE,
		self.MIN_SELECTION_ICON_SCALE,
		self.MAX_SELECTION_ICON_SCALE
	)
	self:GetConfig().selectionIconScale = scale
	return scale
end

function QC:IsSelectionOverlayEnabled()
	return self:GetConfig().selectionOverlayEnabled == true
end

function QC:SetSelectionOverlayEnabled(enabled)
	enabled = enabled == true
	self:GetConfig().selectionOverlayEnabled = enabled
	return enabled
end

function QC:GetUnselectedIconAlpha()
	return self:GetConfig().unselectedIconAlpha
end

function QC:SetUnselectedIconAlpha(value)
	local alpha = clamp(tonumber(value) or self.DEFAULT_UNSELECTED_ICON_ALPHA, 0, 1)
	self:GetConfig().unselectedIconAlpha = alpha
	return alpha
end

function QC:GetMenu(id)
	id = tonumber(id)
	return id and self:GetConfig().menus[id] or nil
end

function QC:WouldCreateMenuCycle(parentMenuID, childMenuID)
	parentMenuID = tonumber(parentMenuID)
	childMenuID = tonumber(childMenuID)
	if not (parentMenuID and childMenuID) then return true end
	if parentMenuID == childMenuID then return true end
	local config = self:GetConfig()
	if not (config.menus[parentMenuID] and config.menus[childMenuID]) then return true end
	local pending = { childMenuID }
	local visited = {}
	while pending[1] do
		local menuID = table.remove(pending)
		if menuID == parentMenuID then return true end
		if not visited[menuID] then
			visited[menuID] = true
			local menu = config.menus[menuID]
			for index = 1, #(menu and menu.actions or {}) do
				local action = menu.actions[index]
				if action.kind == "menu" and tonumber(action.id) and not visited[tonumber(action.id)] then
					pending[#pending + 1] = tonumber(action.id)
				end
			end
		end
	end
	return false
end

function QC:GetOrderedMenu(index)
	return getOrderedMenu(index)
end

function QC:CreateMenu()
	if _G.InCombatLockdown() then return nil, "combat" end
	local config = self:GetConfig()
	if #config.order >= self.MAX_MENUS then return nil, "limit" end
	local id = config.nextMenuID
	while config.menus[id] do id = id + 1 end
	config.nextMenuID = id + 1
	local menu = normalizeMenu({
		id = id,
		name = (L["QuickCast"] or "QuickActions") .. " " .. tostring(#config.order + 1),
		enabled = true,
		layout = "radial",
		anchor = "CENTER",
		offsetX = 0,
		offsetY = 0,
		showLabels = true,
		showAtCursor = false,
		nextEntryID = 1,
		actions = {},
	}, id)
	config.menus[id] = menu
	config.order[#config.order + 1] = id
	self:QueueSecureRebuild()
	return menu
end

function QC:DeleteMenu(id)
	if _G.InCombatLockdown() then return false end
	local config = self:GetConfig()
	id = tonumber(id)
	if not (id and config.menus[id]) then return false end
	config.menus[id] = nil
	for index = #config.order, 1, -1 do
		if config.order[index] == id then table.remove(config.order, index) end
	end
	self:QueueSecureRebuild()
	return true
end

function QC:MoveAction(menuID, fromIndex, toIndex)
	if _G.InCombatLockdown() then return false end
	local menu = self:GetMenu(menuID)
	fromIndex, toIndex = tonumber(fromIndex), tonumber(toIndex)
	if not (menu and fromIndex and toIndex and menu.actions[fromIndex]) then return false end
	toIndex = clamp(toIndex, 1, #menu.actions)
	if fromIndex == toIndex then return true end
	local action = table.remove(menu.actions, fromIndex)
	table.insert(menu.actions, toIndex, action)
	self:QueueSecureRebuild()
	return true
end

function QC:SetAction(menuID, index, action)
	if _G.InCombatLockdown() then return false end
	local menu = self:GetMenu(menuID)
	index = tonumber(index)
	if not (menu and type(action) == "table") then return false end
	if action.kind == "menu" and self:WouldCreateMenuCycle(menuID, action.id) then return false end
	local entryID
	if index and index >= 1 and index <= #menu.actions then
		entryID = menu.actions[index].entryID
	else
		entryID = tonumber(action.entryID)
		entryID = entryID and entryID > 0 and math.floor(entryID) or nil
		if entryID then
			for actionIndex = 1, #menu.actions do
				if menu.actions[actionIndex].entryID == entryID then
					entryID = nil
					break
				end
			end
		end
		if not entryID then
			entryID = menu.nextEntryID
			menu.nextEntryID = entryID + 1
		end
	end
	action = normalizeAction(action, entryID)
	if not action then return false end
	if index and index >= 1 and index <= #menu.actions then
		menu.actions[index] = action
	else
		menu.actions[#menu.actions + 1] = action
	end
	self:QueueSecureRebuild()
	return true
end

function QC:GetActionIndexByEntryID(menuID, entryID)
	local menu = self:GetMenu(menuID)
	entryID = tonumber(entryID)
	if not (menu and entryID) then return nil end
	for index = 1, #menu.actions do
		if menu.actions[index].entryID == entryID then return index end
	end
	return nil
end

function QC:GetActionByEntryID(menuID, entryID)
	local index = self:GetActionIndexByEntryID(menuID, entryID)
	local menu = index and self:GetMenu(menuID)
	return menu and menu.actions[index] or nil, index
end

function QC:RemoveAction(menuID, index)
	if _G.InCombatLockdown() then return false end
	local menu = self:GetMenu(menuID)
	index = tonumber(index)
	if not (menu and index and menu.actions[index]) then return false end
	local removed = table.remove(menu.actions, index)
	if removed and menu.defaultEntryID == removed.entryID then menu.defaultEntryID = nil end
	self:QueueSecureRebuild()
	return true
end

local function getActionIdentity(action)
	if type(action) ~= "table" then return nil end
	if action.kind == "macro" then return action.name and ("macro:" .. action.name:lower()) or nil end
	if action.kind == "equipmentset" then
		return action.ownerGUID and action.id and ("equipmentset:" .. action.ownerGUID .. ":" .. tostring(action.id)) or nil
	end
	if action.kind and action.id ~= nil then return tostring(action.kind) .. ":" .. tostring(action.id) end
	return nil
end

function QC:AddEQOLAction(menuID, actionID)
	if _G.InCombatLockdown() or not self.EQOL_ACTIONS[actionID] then return false, "invalid" end
	local menu = self:GetMenu(menuID)
	if not menu then return false, "invalid" end
	local identity = "eqol:" .. actionID
	for _, action in ipairs(menu.actions) do
		if getActionIdentity(action) == identity then return true, "exists" end
	end
	if not self:SetAction(menuID, nil, { kind = "eqol", id = actionID }) then return false, "invalid" end
	return true, "added"
end

local function getCurrentSeasonManagedActions()
	local functions = addon.MythicPlus and addon.MythicPlus.functions
	local builder = functions and functions.BuildCurrentSeasonTeleportSection
	if not builder then return nil end
	local section = builder()
	if type(section) ~= "table" or type(section.items) ~= "table" then return {} end
	local actions = {}
	for _, item in ipairs(section.items) do
		local kind, id
		if item.isToy then
			kind, id = "item", tonumber(item.toyID)
		elseif item.isItem then
			kind, id = "item", tonumber(item.itemID)
		else
			kind, id = "spell", tonumber(item.spellID)
		end
		if kind and id and id > 0 then
			local key = kind .. ":" .. tostring(math.floor(id))
			actions[#actions + 1] = {
				kind = kind,
				id = math.floor(id),
				managedSource = QC.MANAGED_SOURCE_CURRENT_SEASON,
				managedKey = key,
				managedLabel = trim(item.text),
			}
		end
	end
	return actions
end

local function getTeleportFavoriteManagedActions()
	local functions = addon.MythicPlus and addon.MythicPlus.functions
	local builder = functions and functions.BuildTeleportCompendiumSections
	if not builder then return nil end
	local sections = builder()
	if type(sections) ~= "table" then return {} end
	local actions = {}
	for _, section in ipairs(sections) do
		for _, item in ipairs(type(section) == "table" and type(section.items) == "table" and section.items or {}) do
			if item.isFavorite == true and item.isRandomHearthstone ~= true then
				local kind, id
				if item.isToy then
					kind, id = "item", tonumber(item.toyID)
				elseif item.isItem then
					kind, id = "item", tonumber(item.itemID)
				else
					kind, id = "spell", tonumber(item.spellID)
				end
				if kind and id and id > 0 then
					id = math.floor(id)
					actions[#actions + 1] = {
						kind = kind,
						id = id,
						managedSource = QC.MANAGED_SOURCE_TELEPORT_FAVORITES,
						managedKey = kind .. ":" .. tostring(id),
						managedLabel = trim(item.text),
					}
				end
			end
		end
	end
	return actions
end

function QC:SyncManagedMenu(menu)
	if type(menu) ~= "table" then return false, 0 end
	local sourceOrder = {
		self.MANAGED_SOURCE_CURRENT_SEASON,
		self.MANAGED_SOURCE_TELEPORT_FAVORITES,
	}
	local sourceBuilders = {
		[self.MANAGED_SOURCE_CURRENT_SEASON] = getCurrentSeasonManagedActions,
		[self.MANAGED_SOURCE_TELEPORT_FAVORITES] = getTeleportFavoriteManagedActions,
	}
	local knownSources = {
		[self.MANAGED_SOURCE_CURRENT_SEASON] = true,
		[self.MANAGED_SOURCE_TELEPORT_FAVORITES] = true,
	}
	local existingBySource = {}
	local existingLists = {}
	local rebuilt = {}
	local identities = {}
	for _, source in ipairs(sourceOrder) do
		existingBySource[source] = {}
		existingLists[source] = {}
	end
	for _, action in ipairs(menu.actions or {}) do
		local source = action.managedSource
		if knownSources[source] then
			local sourceList = existingLists[source]
			sourceList[#sourceList + 1] = action
			existingBySource[source][action.managedKey or getActionIdentity(action) or tostring(#sourceList)] = action
		else
			rebuilt[#rebuilt + 1] = action
			local identity = getActionIdentity(action)
			if identity then identities[identity] = true end
		end
	end

	for _, source in ipairs(sourceOrder) do
		if type(menu.managedSources) == "table" and menu.managedSources[source] == true then
			local desired = sourceBuilders[source]()
			if desired == nil then desired = existingLists[source] end
			for _, sourceAction in ipairs(desired) do
				local identity = getActionIdentity(sourceAction)
				if identity and not identities[identity] then
					local previous = existingBySource[source][sourceAction.managedKey or identity]
					local candidate = previous or sourceAction
					if sourceAction ~= previous then
						candidate.kind = sourceAction.kind
						candidate.id = sourceAction.id
						candidate.managedSource = source
						candidate.managedKey = sourceAction.managedKey
						candidate.managedLabel = sourceAction.managedLabel
					elseif candidate.managedSource == nil then
						candidate.managedSource = source
					end
					if not previous then candidate.conditions = sourceAction.conditions end
					local entryID = tonumber(candidate.entryID)
					if not entryID then
						entryID = menu.nextEntryID
						menu.nextEntryID = entryID + 1
					end
					candidate = normalizeAction(candidate, entryID)
					if candidate then
						rebuilt[#rebuilt + 1] = candidate
						identities[identity] = true
					end
				end
			end
		end
	end
	local changed = #rebuilt ~= #(menu.actions or {})
	if not changed then
		for index = 1, #rebuilt do
			if rebuilt[index] ~= menu.actions[index] then
				changed = true
				break
			end
		end
	end
	menu.actions = rebuilt
	if menu.defaultEntryID then
		local defaultExists = false
		for index = 1, #rebuilt do
			if rebuilt[index].entryID == menu.defaultEntryID then
				defaultExists = true
				break
			end
		end
		if not defaultExists then
			menu.defaultEntryID = nil
			changed = true
		end
	end
	return changed, 0
end

function QC:SyncManagedSources(config)
	config = type(config) == "table" and config or self:GetConfig()
	local changed = false
	for _, menuID in ipairs(config.order or {}) do
		local menu = config.menus and config.menus[menuID]
		local didChange = self:SyncManagedMenu(menu)
		if didChange then changed = true end
	end
	return changed
end

function QC:MarkManagedSourcesDirty()
	managedSourcesDirty = true
end

function QC:QueueManagedSourceSync()
	self:MarkManagedSourcesDirty()
	self:QueueSecureRebuild()
end

function QC:SetManagedSource(menuID, source, enabled)
	if _G.InCombatLockdown()
		or (source ~= self.MANAGED_SOURCE_CURRENT_SEASON and source ~= self.MANAGED_SOURCE_TELEPORT_FAVORITES)
	then
		return false, "invalid"
	end
	local menu = self:GetMenu(menuID)
	if not menu then return false, "invalid" end
	menu.managedSources = type(menu.managedSources) == "table" and menu.managedSources or {}
	menu.managedSources[source] = enabled == true or nil
	self:SyncManagedMenu(menu)
	self:QueueSecureRebuild()
	return true, "updated"
end

local function findMacro(action)
	local getMacroInfo = _G.GetMacroInfo
	if not getMacroInfo then return nil end
	local hint = tonumber(action.indexHint)
	if hint then
		local name, icon, body = getMacroInfo(hint)
		if name == action.name then return hint, name, icon, body end
	end
	local maximum = (_G.MAX_ACCOUNT_MACROS or 120) + (_G.MAX_CHARACTER_MACROS or 18)
	for index = 1, maximum do
		local name, icon, body = getMacroInfo(index)
		if name == action.name then return index, name, icon, body end
	end
	return nil
end

local function getEQOLActionIcon(definition)
	if not definition then return nil end
	if definition.iconSpellID and _G.C_Spell and _G.C_Spell.GetSpellInfo then
		local info = _G.C_Spell.GetSpellInfo(definition.iconSpellID)
		if info and info.iconID then return info.iconID end
	end
	if definition.iconItemID and _G.C_Item then
		if _G.C_Item.GetItemIconByID then
			local icon = _G.C_Item.GetItemIconByID(definition.iconItemID)
			if icon then return icon end
		end
		if _G.C_Item.GetItemInfoInstant then return select(5, _G.C_Item.GetItemInfoInstant(definition.iconItemID)) end
	end
	return nil
end

function QC:ActionBelongsToCurrentCharacter(action)
	if type(action) ~= "table" then return false end
	if action.kind ~= "equipmentset" then return true end
	local currentGUID = _G.UnitGUID and _G.UnitGUID("player")
	if _G.issecretvalue and _G.issecretvalue(currentGUID) then return false end
	return currentGUID ~= nil and action.ownerGUID == currentGUID
end

function QC:ResolveAction(action)
	if type(action) ~= "table" then return nil, nil, false end
	if action.kind == "spell" then
		local info = _G.C_Spell and _G.C_Spell.GetSpellInfo and _G.C_Spell.GetSpellInfo(action.id)
		return info and info.name, info and info.iconID, info ~= nil
	elseif action.kind == "item" then
		local name = _G.C_Item and _G.C_Item.GetItemInfo and _G.C_Item.GetItemInfo(action.id)
		local icon
		if _G.C_Item and _G.C_Item.GetItemInfoInstant then icon = select(5, _G.C_Item.GetItemInfoInstant(action.id)) end
		return name or ("item:" .. tostring(action.id)), icon, icon ~= nil
	elseif action.kind == "mount" then
		if not (_G.C_MountJournal and _G.C_MountJournal.GetMountInfoByID) then return nil, nil, false end
		local name, spellID, icon, _, _, _, _, _, _, _, isCollected = _G.C_MountJournal.GetMountInfoByID(action.id)
		return name or ("mount:" .. tostring(action.id)), icon, name ~= nil and spellID ~= nil and isCollected == true, spellID
	elseif action.kind == "battlepet" then
		if not (_G.C_PetJournal and _G.C_PetJournal.GetPetInfoByPetID) then return nil, nil, false end
		local petInfo = { _G.C_PetJournal.GetPetInfoByPetID(action.id) }
		return petInfo[2] or petInfo[8] or action.id, petInfo[9], petInfo[1] ~= nil
	elseif action.kind == "macro" then
		local index, name, icon = findMacro(action)
		return name or action.name, icon, index ~= nil, index
	elseif action.kind == "worldmarker" and action.id == 0 then
		return _G.CANCEL or "Cancel", nil, true, nil, "common-icon-redx"
	elseif action.kind == "worldmarker" or action.kind == "raidtarget" then
		local markerName = action.kind == "worldmarker"
			and _G["WORLD_MARKER" .. tostring(action.id)]
			or _G["RAID_TARGET_" .. tostring(action.id)]
		markerName = markerName or ("Marker " .. tostring(action.id))
		local prefix
		if action.kind == "worldmarker" then
			prefix = "World Marker"
			if type(_G.WORLD_MARKER) == "string" then
				local ok, formattedPrefix = pcall(string.format, _G.WORLD_MARKER, action.id)
				if ok and type(formattedPrefix) == "string" then prefix = formattedPrefix end
			end
		else
			prefix = _G.TARGET or "Target"
		end
		local atlasIndex = action.kind == "worldmarker"
			and self.WORLD_MARKER_ATLAS_INDEX[action.id]
			or self.RAID_TARGET_ATLAS_INDEX[action.id]
		return prefix .. ": " .. markerName, nil, true, nil, "GM-raidMarker" .. tostring(atlasIndex)
	elseif action.kind == "equipmentset" then
		if not self:ActionBelongsToCurrentCharacter(action) then return action.name, nil, false end
		if not (_G.C_EquipmentSet and _G.C_EquipmentSet.GetEquipmentSetInfo) then return action.name, nil, false end
		local name, icon, setID = _G.C_EquipmentSet.GetEquipmentSetInfo(action.id)
		local secret = _G.issecretvalue
			and (_G.issecretvalue(name) or _G.issecretvalue(icon) or _G.issecretvalue(setID))
		if secret then return action.name, nil, false end
		return name or action.name, icon, name ~= nil and setID ~= nil, name
	elseif action.kind == "outfit" then
		local outfitAPI = _G.C_TransmogOutfitInfo
		if not (outfitAPI and outfitAPI.GetOutfitInfo) then return nil, nil, false end
		local info = outfitAPI.GetOutfitInfo(action.id)
		if type(info) ~= "table" then return nil, nil, false end
		local secret = _G.issecretvalue
			and (
				_G.issecretvalue(info.outfitID)
				or _G.issecretvalue(info.name)
				or _G.issecretvalue(info.icon)
				or _G.issecretvalue(info.isDisabled)
				or _G.issecretvalue(info.playerFacingOutfitIndex)
			)
		if secret then return nil, nil, false end
		local valid = info.outfitID ~= nil and info.playerFacingOutfitIndex ~= nil and info.isDisabled ~= true
		return info.name or ("outfit:" .. tostring(action.id)), info.icon, valid, info.playerFacingOutfitIndex
	elseif action.kind == "menu" then
		local menu = self:GetMenu(action.id)
		if not (menu and menu.enabled ~= false) then return nil, nil, false end
		local preferredAction
		for index = 1, #menu.actions do
			local candidate = menu.actions[index]
			if candidate.entryID == menu.defaultEntryID and candidate.kind ~= "menu" then
				preferredAction = candidate
				break
			end
		end
		if not preferredAction then
			for index = 1, #menu.actions do
				if menu.actions[index].kind ~= "menu" then
					preferredAction = menu.actions[index]
					break
				end
			end
		end
		local icon, iconAtlas
		if preferredAction then
			local _, resolvedIcon, valid, _, resolvedAtlas = self:ResolveAction(preferredAction)
			if valid then
				icon = preferredAction.customIcon or resolvedIcon
				iconAtlas = not preferredAction.customIcon and (preferredAction.customIconAtlas or resolvedAtlas) or nil
			end
		end
		return menu.name, icon or "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga", true, nil, iconAtlas
	elseif action.kind == "eqol" then
		local definition = self.EQOL_ACTIONS[action.id]
		if not definition then return nil, nil, false end
		return L[definition.labelKey] or definition.labelKey, getEQOLActionIcon(definition), true
	end
	return nil, nil, false
end

local function getCurrentSpecID()
	if not (_G.GetSpecialization and _G.GetSpecializationInfo) then return nil end
	local specializationIndex = _G.GetSpecialization()
	if _G.issecretvalue and _G.issecretvalue(specializationIndex) then return nil end
	if not specializationIndex then return nil end
	local specID = _G.GetSpecializationInfo(specializationIndex)
	if _G.issecretvalue and _G.issecretvalue(specID) then return nil end
	if not specID then return nil end
	return tonumber(specID)
end

function QC:GetCurrentSpecID()
	return getCurrentSpecID()
end

local function isSpellKnown(spellID)
	if not spellID then return nil end
	local spellBook = _G.C_SpellBook
	local spellBank = _G.Enum and _G.Enum.SpellBookSpellBank
	local check = spellBook and spellBook.IsSpellKnownOrInSpellBook
	if check and spellBank then
		local unknownResult = false
		local playerResult = check(spellID, spellBank.Player, true)
		if _G.issecretvalue and _G.issecretvalue(playerResult) then
			unknownResult = true
		elseif playerResult then
			return true
		end
		if spellBank.Pet then
			local petResult = check(spellID, spellBank.Pet, true)
			if _G.issecretvalue and _G.issecretvalue(petResult) then
				unknownResult = true
			elseif petResult then
				return true
			end
		end
		return unknownResult and nil or false
	end
	if _G.IsPlayerSpell then
		local known = _G.IsPlayerSpell(spellID)
		if not (_G.issecretvalue and _G.issecretvalue(known)) and known ~= nil then return known == true end
	end
	if _G.IsSpellKnown then
		local known = _G.IsSpellKnown(spellID, true)
		if not (_G.issecretvalue and _G.issecretvalue(known)) and known ~= nil then return known == true end
	end
	return nil
end

local function getSpellCooldownActive(spellID, trustGCDState)
	if not (_G.C_Spell and _G.C_Spell.GetSpellCooldown and spellID) then return nil end
	if _G.C_Spell.GetSpellCooldownDuration then
		local durationObject = _G.C_Spell.GetSpellCooldownDuration(spellID, true)
		local hasSecretValues = durationObject
			and durationObject.HasSecretValues
			and durationObject:HasSecretValues()
		if durationObject and not hasSecretValues and durationObject.IsZero then
			local isZero = durationObject:IsZero()
			if not (_G.issecretvalue and _G.issecretvalue(isZero)) and type(isZero) == "boolean" then
				local active = isZero == false
				spellCooldownActiveCache[spellID] = active
				return active
			end
		end
	end
	local cooldownInfo = _G.C_Spell.GetSpellCooldown(spellID)
	if _G.issecretvalue and _G.issecretvalue(cooldownInfo) then return nil end
	if type(cooldownInfo) ~= "table" then return nil end
	local isActive = cooldownInfo.isActive
	local isOnGCD = cooldownInfo.isOnGCD
	if _G.issecretvalue and (_G.issecretvalue(isActive) or _G.issecretvalue(isOnGCD)) then return nil end
	if isActive == false then
		spellCooldownActiveCache[spellID] = false
		return false
	end
	if trustGCDState then
		local active = isActive == true and isOnGCD ~= true
		spellCooldownActiveCache[spellID] = active
		return active
	end
	return spellCooldownActiveCache[spellID]
end

local function getItemCooldownActive(itemID, trustGCDState)
	if not itemID then return nil end
	local itemCooldownActive
	if _G.C_Item and _G.C_Item.GetItemCooldown then
		local startTime, duration, isEnabled = _G.C_Item.GetItemCooldown(itemID)
		local secret = _G.issecretvalue and (
			_G.issecretvalue(startTime)
			or _G.issecretvalue(duration)
			or _G.issecretvalue(isEnabled)
		)
		if not secret and type(startTime) == "number" and type(duration) == "number" then
			itemCooldownActive = isEnabled ~= false
				and isEnabled ~= 0
				and startTime > 0
				and duration > 0
			if itemCooldownActive then return true end
		end
	end
	if _G.C_Item and _G.C_Item.GetItemSpell then
		local itemSpellID = select(2, _G.C_Item.GetItemSpell(itemID))
		if _G.issecretvalue and _G.issecretvalue(itemSpellID) then return nil end
		if itemSpellID then
			local spellActive = getSpellCooldownActive(itemSpellID, trustGCDState)
			if spellActive ~= nil then return spellActive end
		end
	end
	return itemCooldownActive
end

local function getActionCooldownActive(action, trustGCDState)
	if action.kind == "spell" then return getSpellCooldownActive(action.id, trustGCDState) end
	if action.kind == "item" then return getItemCooldownActive(action.id, trustGCDState) end
	if action.kind == "mount" and _G.C_MountJournal and _G.C_MountJournal.GetMountInfoByID then
		local spellID = select(2, _G.C_MountJournal.GetMountInfoByID(action.id))
		if _G.issecretvalue and _G.issecretvalue(spellID) then return nil end
		return getSpellCooldownActive(spellID, trustGCDState)
	end
	if action.kind == "outfit" then return getSpellCooldownActive(QC.TRANSMOG_OUTFIT_COOLDOWN_SPELL_ID, trustGCDState) end
	if action.kind ~= "macro" then return nil end
	local macroIndex = findMacro(action)
	if not macroIndex then return nil end
	if _G.GetMacroItem then
		local itemName, itemLink = _G.GetMacroItem(macroIndex)
		if _G.issecretvalue and (_G.issecretvalue(itemName) or _G.issecretvalue(itemLink)) then return nil end
		local item = itemLink or itemName
		local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or tonumber(item)
		if not itemID and item and _G.C_Item and _G.C_Item.GetItemInfoInstant then itemID = _G.C_Item.GetItemInfoInstant(item) end
		if itemID then return getItemCooldownActive(itemID, trustGCDState) end
	end
	if _G.GetMacroSpell then
		local spellID = _G.GetMacroSpell(macroIndex)
		if _G.issecretvalue and _G.issecretvalue(spellID) then return nil end
		if spellID then return getSpellCooldownActive(spellID, trustGCDState) end
	end
	return nil
end

local function specFilterAllows(specs, currentSpecID, viewSpecIDs)
	if type(specs) ~= "table" or next(specs) == nil then return true end
	if type(viewSpecIDs) == "table" then
		for rawSpecID, selected in pairs(viewSpecIDs) do
			local specID = tonumber(rawSpecID)
			if selected and specID and specs[specID] == true then return true end
		end
		return false
	end
	return currentSpecID ~= nil and specs[currentSpecID] == true
end

function QC:MenuAllowsSpec(menu, currentSpecID)
	if type(menu) ~= "table" then return false end
	if currentSpecID == nil then currentSpecID = getCurrentSpecID() end
	return specFilterAllows(menu.specFilter, currentSpecID)
end

function QC:GetEffectiveHideOnCooldown(menu, action)
	local enabled = type(menu) == "table" and menu.hideOnCooldown == true
	local cooldown = type(action) == "table"
		and type(action.conditions) == "table"
		and type(action.conditions.cooldown) == "table"
		and action.conditions.cooldown
		or nil
	if cooldown and cooldown.useMenu == false then enabled = cooldown.enabled == true end
	return enabled
end

function QC:GetEffectiveHideMissingItems(menu, action)
	local enabled = type(menu) == "table" and menu.hideMissingItems == true
	local inventory = type(action) == "table"
		and type(action.conditions) == "table"
		and type(action.conditions.inventory) == "table"
		and action.conditions.inventory
		or nil
	if inventory and inventory.useMenu == false then enabled = inventory.enabled == true end
	return enabled
end

function QC:IsOwnedToyAction(action)
	if type(action) ~= "table" or action.kind ~= "item" or not _G.PlayerHasToy then return false end
	local ownsToy = _G.PlayerHasToy(action.id)
	if _G.issecretvalue and _G.issecretvalue(ownsToy) then return false end
	return ownsToy == true
end

local function isItemMissingFromBags(action)
	if type(action) ~= "table" or action.kind ~= "item" or not (_G.C_Item and _G.C_Item.GetItemCount) then return false end
	if QC:IsOwnedToyAction(action) then return false end
	local count = _G.C_Item.GetItemCount(action.id, false, false, false, false)
	if _G.issecretvalue and _G.issecretvalue(count) then return false end
	return type(count) == "number" and count <= 0
end

local function isUnusableToyAction(action)
	if type(action) ~= "table"
		or action.kind ~= "item"
		or not _G.PlayerHasToy
		or not (_G.C_ToyBox and _G.C_ToyBox.IsToyUsable)
	then
		return false
	end
	if not QC:IsOwnedToyAction(action) then return false end
	local usable = _G.C_ToyBox.IsToyUsable(action.id)
	if _G.issecretvalue and _G.issecretvalue(usable) then return false end
	return usable == false
end

local function actionPassesConditions(menu, action, currentSpecID, viewSpecIDs)
	if action.enabled == false then return false end
	if isUnusableToyAction(action) then return false end
	if action.kind == "spell" then
		local known = isSpellKnown(action.id)
		if known == false then return false end
	end
	if QC:GetEffectiveHideMissingItems(menu, action) and isItemMissingFromBags(action) then return false end
	local conditions = action.conditions
	if type(conditions) ~= "table" then return true end

	local specs = conditions.specs
	if not specFilterAllows(specs, currentSpecID, viewSpecIDs) then return false end

	if QC:GetEffectiveHideOnCooldown(menu, action) and getActionCooldownActive(action) == true then return false end
	return true
end

function QC:GetActiveActions(menu, currentSpecID, viewSpecIDs)
	local active = {}
	if type(menu) ~= "table" then return active end
	if currentSpecID == nil then currentSpecID = getCurrentSpecID() end
	for sourceIndex = 1, #menu.actions do
		local action = menu.actions[sourceIndex]
		local linkedMenu = action.kind == "menu" and self:GetMenu(action.id) or nil
		local linkedMenuAllowed = action.kind ~= "menu" or (linkedMenu and self:MenuAllowsSpec(linkedMenu, currentSpecID))
		if
			linkedMenuAllowed
			and self:ActionBelongsToCurrentCharacter(action)
			and actionPassesConditions(menu, action, currentSpecID, viewSpecIDs)
		then
			local name, icon, valid, resolvedValue, iconAtlas = self:ResolveAction(action)
			if valid then
				active[#active + 1] = {
					sourceIndex = sourceIndex,
					action = action,
					name = name,
					icon = icon,
					iconAtlas = iconAtlas,
					resolvedValue = resolvedValue,
				}
			end
		end
	end
	return active
end

function QC:GetCompiledEntries(menuID)
	return compiledEntries[tonumber(menuID)]
end

function QC:GetEffectiveShowLabel(menu, action)
	if type(action) == "table" and type(action.showLabel) == "boolean" then return action.showLabel end
	return type(menu) == "table" and menu.showLabels ~= false
end

local function getMediaPath(mediaType, key, fallback)
	if type(key) == "string" and key ~= "" and key ~= "DEFAULT" then
		local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash(mediaType)
		local path = type(hash) == "table" and hash[key] or nil
		if type(path) == "string" and path ~= "" then return path end
		if key:find("[\\/]") then return key end
	end
	return fallback
end

local function ensureAppearanceBorder(button)
	if button.appearanceBorder then return button.appearanceBorder end
	local visualParent = button.animatedVisual or button
	local border = _G.CreateFrame("Frame", nil, visualParent, "BackdropTemplate")
	border:SetFrameLevel(button:GetFrameLevel() + 3)
	border:EnableMouse(false)
	button.appearanceBorder = border
	return border
end

local function applyCooldownSwipeVisual(owner)
	local button = owner and owner.quickActionsButton or owner
	local shapeOwner = button and button.animatedVisual or owner
	local iconShape = addon.IconShape
	if button and button.cooldown and iconShape and iconShape.ApplyCooldownSwipeVisual then
		iconShape.ApplyCooldownSwipeVisual(button.cooldown, shapeOwner, nil, nil, { customColor = false })
	end
end

local function isValidColorComponent(value)
	if _G.issecretvalue and _G.issecretvalue(value) then return false end
	return type(value) == "number" and value == value and value >= 0 and value <= 1
end

local function isSecretValue(value)
	return _G.issecretvalue and _G.issecretvalue(value) or false
end

function QC:GetDisplayLabel(menu, text)
	if isSecretValue(text) then return text end
	if text == nil then return "?" end
	if type(text) ~= "string" then return text end
	local limit = type(menu) == "table" and tonumber(menu.labelCharacterLimit) or self.DEFAULT_LABEL_CHARACTER_LIMIT
	limit = math.floor(limit or self.DEFAULT_LABEL_CHARACTER_LIMIT)
	if limit <= 0 then return text end
	local length = _G.strlenutf8 and _G.strlenutf8(text) or #text
	if length <= limit then return text end
	if _G.strsubutf8 then return _G.strsubutf8(text, 1, limit) end
	return text:sub(1, limit)
end

local function getButtonBorderColor(button, menu)
	local fallback = menu.iconBorderColor or QC.DEFAULT_ICON_BORDER_COLOR
	if menu.iconBorderUseItemQualityColor == false then return fallback end
	local action = button and button.action
	if type(action) ~= "table" or action.kind ~= "item" then return fallback end
	local itemID = action.id
	if isSecretValue(itemID) then return fallback end
	local itemIDType = type(itemID)
	if itemIDType ~= "number" and itemIDType ~= "string" then return fallback end
	local itemAPI = _G.C_Item
	if not itemAPI
		or type(itemAPI.GetItemQualityByID) ~= "function"
		or type(itemAPI.GetItemQualityColor) ~= "function"
	then
		return fallback
	end
	local qualityOK, quality = pcall(itemAPI.GetItemQualityByID, itemID)
	if not qualityOK or isSecretValue(quality) or type(quality) ~= "number" then return fallback end
	local colorOK, r, g, b = pcall(itemAPI.GetItemQualityColor, quality)
	if not colorOK or not isValidColorComponent(r) or not isValidColorComponent(g) or not isValidColorComponent(b) then return fallback end
	return { r, g, b, fallback[4] or fallback.a or 1 }
end

function QC:ApplyButtonAppearance(button, menu)
	if not (button and type(menu) == "table") then return end
	local iconShape = addon.IconShape
	local animatedVisual = button.animatedVisual or button
	local shape = menu.iconShape or self.DEFAULT_ICON_SHAPE
	if iconShape and iconShape.ApplyFrameShape then
		iconShape.ApplyFrameShape(animatedVisual, shape, {
			textures = { button.icon, button.highlight, button.focus and button.focus.confirmFlash },
			cooldown = button.cooldown,
			iconZoom = menu.iconZoom or self.DEFAULT_ICON_ZOOM,
			maskKey = "_eqolQuickActionsMask",
			textureMaskKey = "_eqolQuickActionsTextureMask",
			textureTexCoordKey = "_eqolQuickActionsTexCoords",
			refreshSwipe = applyCooldownSwipeVisual,
		})
	end

	local border = button.appearanceBorder
	if border then
		if border.SetBackdrop then border:SetBackdrop(nil) end
		if iconShape and iconShape.HideBorderTextures then
			iconShape.HideBorderTextures(border, { texturesKey = "_eqolQuickActionsBorderTextures" })
		end
		border:ClearAllPoints()
		border:SetAllPoints(animatedVisual)
		border:Hide()
	end
	if menu.iconBorderEnabled == true then
		border = border or ensureAppearanceBorder(button)
		local color = getButtonBorderColor(button, menu)
		local borderSize = menu.iconBorderSize or self.DEFAULT_ICON_BORDER_SIZE
		local borderOffset = menu.iconBorderOffset or self.DEFAULT_ICON_BORDER_OFFSET
		if not iconShape or iconShape.IsBackdropBorderCompatible(shape) then
			local edgeFile = getMediaPath("border", menu.iconBorderTexture, "Interface\\Buttons\\WHITE8x8")
			border:ClearAllPoints()
			border:SetPoint("TOPLEFT", animatedVisual, "TOPLEFT", -borderOffset, borderOffset)
			border:SetPoint("BOTTOMRIGHT", animatedVisual, "BOTTOMRIGHT", borderOffset, -borderOffset)
			border:SetBackdrop({ edgeFile = edgeFile, edgeSize = borderSize })
			border:SetBackdropBorderColor(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1)
			border:Show()
		elseif iconShape.ApplyBorder then
			local applied = iconShape.ApplyBorder(border, menu.iconBorderTexture, shape, {
				borderSize = borderSize,
				borderOffset = borderOffset,
				color = color,
				pointFrame = animatedVisual,
				parent = border,
				texturesKey = "_eqolQuickActionsBorderTextures",
				drawLayer = "OVERLAY",
				subLevel = 7,
				fallbackBorderKey = self.DEFAULT_ICON_BORDER_TEXTURE,
			})
			border:SetShown(applied == true)
		end
	end

	if button.label then
		button.label:SetText(self:GetDisplayLabel(menu, button._qaLabelText))
		local fontSize = menu.labelFontSize or self.DEFAULT_LABEL_FONT_SIZE
		local fontStyle = menu.labelFontOutline or self.DEFAULT_LABEL_FONT_OUTLINE
		local functions = addon.functions
		if functions and functions.SetFontWithFallback and functions.GetFontFlagsForStyle then
			local flags = functions.GetFontFlagsForStyle(fontStyle, self.DEFAULT_LABEL_FONT_OUTLINE)
			functions.SetFontWithFallback(button.label, menu.labelFont, fontSize, flags, self.DEFAULT_LABEL_FONT)
			if functions.ApplyFontStyleShadow then functions.ApplyFontStyleShadow(button.label, fontStyle, self.DEFAULT_LABEL_FONT_OUTLINE) end
		else
			local fontPath = getMediaPath("font", menu.labelFont, _G.STANDARD_TEXT_FONT)
			local fontOutline = fontStyle == "NONE" and "" or fontStyle
			if fontPath and button.label.SetFont then
				local applied = button.label:SetFont(fontPath, fontSize, fontOutline)
				if not applied and _G.STANDARD_TEXT_FONT then button.label:SetFont(_G.STANDARD_TEXT_FONT, fontSize, fontOutline) end
			end
		end
		local color = menu.labelColor or self.DEFAULT_LABEL_COLOR
		button.label:SetTextColor(color[1] or 1, color[2] or 0.82, color[3] or 0, color[4] or 1)
		button.label:ClearAllPoints()
		local anchor = menu.labelAnchor or self.DEFAULT_LABEL_ANCHOR
		local offsetX = menu.labelOffsetX or self.DEFAULT_LABEL_OFFSET_X
		local offsetY = menu.labelOffsetY or self.DEFAULT_LABEL_OFFSET_Y
		local labelWidth = self.LABEL_MAX_WIDTH
		button.label:SetWidth(labelWidth)
		local getTextWidth = button.label.GetUnboundedStringWidth or button.label.GetStringWidth
		if (anchor == "LEFT" or anchor == "RIGHT") and getTextWidth then
			local textWidth = getTextWidth(button.label)
			if not isSecretValue(textWidth) and type(textWidth) == "number" then
				button.label:SetWidth(math.max(1, math.min(labelWidth, math.ceil(textWidth + 2))))
			end
		end
		if anchor == "TOP" then
			button.label:SetPoint("BOTTOM", animatedVisual, "TOP", offsetX, offsetY)
			button.label:SetJustifyH("CENTER")
		elseif anchor == "LEFT" then
			button.label:SetPoint("RIGHT", animatedVisual, "LEFT", offsetX, offsetY)
			button.label:SetJustifyH("RIGHT")
		elseif anchor == "RIGHT" then
			button.label:SetPoint("LEFT", animatedVisual, "RIGHT", offsetX, offsetY)
			button.label:SetJustifyH("LEFT")
		elseif anchor == "CENTER" then
			button.label:SetPoint("CENTER", animatedVisual, "CENTER", offsetX, offsetY)
			button.label:SetJustifyH("CENTER")
		else
			button.label:SetPoint("TOP", animatedVisual, "BOTTOM", offsetX, offsetY)
			button.label:SetJustifyH("CENTER")
		end
	end
	if button.count then
		local fontSize = menu.countFontSize or self.DEFAULT_COUNT_FONT_SIZE
		local fontStyle = menu.countFontOutline or self.DEFAULT_COUNT_FONT_OUTLINE
		local functions = addon.functions
		if functions and functions.SetFontWithFallback and functions.GetFontFlagsForStyle then
			local flags = functions.GetFontFlagsForStyle(fontStyle, self.DEFAULT_COUNT_FONT_OUTLINE)
			functions.SetFontWithFallback(button.count, menu.countFont, fontSize, flags, self.DEFAULT_COUNT_FONT)
			if functions.ApplyFontStyleShadow then
				functions.ApplyFontStyleShadow(button.count, fontStyle, self.DEFAULT_COUNT_FONT_OUTLINE)
			end
		else
			local fontPath = getMediaPath("font", menu.countFont, _G.STANDARD_TEXT_FONT)
			local fontOutline = fontStyle == "NONE" and "" or fontStyle
			if fontPath and button.count.SetFont then
				local applied = button.count:SetFont(fontPath, fontSize, fontOutline)
				if not applied and _G.STANDARD_TEXT_FONT then button.count:SetFont(_G.STANDARD_TEXT_FONT, fontSize, fontOutline) end
			end
		end
		local color = menu.countColor or self.DEFAULT_COUNT_COLOR
		button.count:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
		button.count:ClearAllPoints()
		local anchor = menu.countAnchor or self.DEFAULT_COUNT_ANCHOR
		button.count:SetPoint(
			anchor,
			animatedVisual,
			anchor,
			menu.countOffsetX or self.DEFAULT_COUNT_OFFSET_X,
			menu.countOffsetY or self.DEFAULT_COUNT_OFFSET_Y
		)
	end
end

local function getLinearSlot(index, count, direction, forwardDirection)
	if direction == forwardDirection then return index end
	return count - index + 1
end

local function getSplitCoordinate(slot, count, size, spacing, deadZone)
	local pitch = size + spacing
	local negativeCount = math.floor(count / 2)
	local baseOffset = deadZone + size / 2
	if slot <= negativeCount then return -(baseOffset + (negativeCount - slot) * pitch) end
	return baseOffset + (slot - negativeCount - 1) * pitch
end

function QC:GetRadialRadius(menu, count)
	menu = type(menu) == "table" and menu or {}
	count = tonumber(count) or #(menu.actions or {})
	local size = menu.iconSize or self.DEFAULT_ICON_SIZE
	local spacingOffset = menu.radialSpacingOffset or self.DEFAULT_RADIAL_SPACING_OFFSET
	local pitch = math.max(1, size + spacingOffset)
	local centerClearance = self.DEAD_ZONE + size / 2 + spacingOffset
	local radius = math.max(size / 2, centerClearance)
	if count > 1 then
		local chordRadius = pitch / (2 * math.sin(math.pi / count))
		radius = math.max(radius, chordRadius)
	end
	return radius
end

function QC:GetSlotOffset(menu, index, count)
	count = tonumber(count) or #menu.actions
	if count < 1 then return menu.offsetX or 0, menu.offsetY or 0 end
	local size = menu.iconSize or self.DEFAULT_ICON_SIZE
	local offsetX = menu.offsetX or 0
	local offsetY = menu.offsetY or 0
	if menu.layout == "horizontal" then
		local spacing = menu.spacing or self.DEFAULT_SPACING
		local pitch = size + spacing
		local slot = getLinearSlot(index, count, menu.direction, "RIGHT")
		local anchor = menu.anchor or "CENTER"
		local x, y
		if anchor == "LEFT" then
			x = -(self.DEAD_ZONE + size / 2 + (count - slot) * pitch)
			y = 0
		elseif anchor == "RIGHT" then
			x = self.DEAD_ZONE + size / 2 + (slot - 1) * pitch
			y = 0
		elseif anchor == "TOP" or anchor == "BOTTOM" then
			x = (slot - (count + 1) / 2) * pitch
			y = (anchor == "TOP" and 1 or -1) * (self.DEAD_ZONE + size / 2)
		else
			x = getSplitCoordinate(slot, count, size, spacing, self.DEAD_ZONE)
			y = 0
		end
		return x + offsetX, y + offsetY
	elseif menu.layout == "vertical" then
		local spacing = menu.spacing or self.DEFAULT_SPACING
		local pitch = size + spacing
		local slot = getLinearSlot(index, count, menu.direction, "UP")
		local anchor = menu.anchor or "CENTER"
		local x, y
		if anchor == "BOTTOM" then
			x = 0
			y = -(self.DEAD_ZONE + size / 2 + (count - slot) * pitch)
		elseif anchor == "TOP" then
			x = 0
			y = self.DEAD_ZONE + size / 2 + (slot - 1) * pitch
		elseif anchor == "LEFT" or anchor == "RIGHT" then
			x = (anchor == "RIGHT" and 1 or -1) * (self.DEAD_ZONE + size / 2)
			y = (slot - (count + 1) / 2) * pitch
		else
			x = 0
			y = getSplitCoordinate(slot, count, size, spacing, self.DEAD_ZONE)
		end
		return x + offsetX, y + offsetY
	end
	local radius = self:GetRadialRadius(menu, count)
	local angle = TWO_PI * (index - 1) / math.max(1, count)
	return math.sin(angle) * radius + offsetX, math.cos(angle) * radius + offsetY
end

function QC:GetSelectedIndex(menu, deltaX, deltaY, count)
	if not menu then return nil end
	count = tonumber(count) or #(compiledEntries[menu.id] or menu.actions or {})
	if count < 1 then return nil end
	local size = menu.iconSize or self.DEFAULT_ICON_SIZE
	local originDistanceSquared = deltaX * deltaX + deltaY * deltaY
	local selectionDeadZone = self.SELECTION_DEAD_ZONE or self.DEAD_ZONE
	if originDistanceSquared <= selectionDeadZone * selectionDeadZone then return nil end
	if menu.layout == "horizontal" or menu.layout == "vertical" then
		local halfSize = size / 2
		for index = 1, count do
			local offsetX, offsetY = self:GetSlotOffset(menu, index, count)
			if math.abs(deltaX - offsetX) <= halfSize and math.abs(deltaY - offsetY) <= halfSize then return index end
		end
		return nil
	end
	local relativeX = deltaX - (menu.offsetX or 0)
	local relativeY = deltaY - (menu.offsetY or 0)
	local segment = 360 / count
	local angle = (math.deg(math.atan2(relativeX, relativeY)) + segment / 2) % 360
	return math.floor(angle / segment) + 1
end

local visual

local function createVisualButton(parent)
	local button = _G.CreateFrame("Button", nil, parent)
	button:RegisterForClicks("LeftButtonUp")
	button:EnableMouse(false)
	button.animatedVisual = _G.CreateFrame("Frame", nil, button)
	button.animatedVisual:SetPoint("CENTER", button, "CENTER")
	button.animatedVisual:SetSize(1, 1)
	button.animatedVisual:SetFrameLevel(button:GetFrameLevel())
	button.animatedVisual:EnableMouse(false)
	button.animatedVisual.quickActionsButton = button
	button.icon = button.animatedVisual:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.highlight = button.animatedVisual:CreateTexture(nil, "OVERLAY")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(1, 0.82, 0.2, 0.34)
	button.highlight:Hide()
	button.cooldown = _G.CreateFrame("Cooldown", nil, button.animatedVisual, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints()
	button.labelOverlay = _G.CreateFrame("Frame", nil, button.animatedVisual)
	button.labelOverlay:SetAllPoints(button.animatedVisual)
	button.labelOverlay:SetFrameLevel(button:GetFrameLevel() + 4)
	button.labelOverlay:EnableMouse(false)
	button.count = button.labelOverlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.count:SetPoint("BOTTOMRIGHT", button.animatedVisual, "BOTTOMRIGHT", -2, 2)
	button.submenuMarker = button.labelOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
	button.submenuMarker:SetAtlas("common-icon-forwardarrow", false)
	button.submenuMarker:SetPoint("TOPRIGHT", button.animatedVisual, "TOPRIGHT", 3, 3)
	button.submenuMarker:SetSize(16, 16)
	button.submenuMarker:Hide()
	button.label = button.labelOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.label:SetPoint("TOP", button.animatedVisual, "BOTTOM", 0, -2)
	button.label:SetWidth(QC.LABEL_MAX_WIDTH)
	button.label:SetMaxLines(1)
	button.invalid = button.animatedVisual:CreateTexture(nil, "OVERLAY")
	button.invalid:SetAtlas("common-icon-redx")
	button.invalid:SetPoint("CENTER")
	button.invalid:SetSize(22, 22)
	button.invalid:Hide()
	button.focus = _G.CreateFrame("Frame", nil, button)
	button.focus:SetAllPoints(button)
	button.focus:SetFrameLevel(button:GetFrameLevel() + 6)
	button.focus:EnableMouse(false)
	button.focus.markers = {}
	for markerIndex = 1, 4 do
		local marker = button.focus:CreateTexture(nil, "OVERLAY", nil, 7)
		marker:SetColorTexture(1, 1, 1, 1)
		marker:SetBlendMode("ADD")
		button.focus.markers[markerIndex] = marker
	end
	button.focus.arrowOutlines = {}
	button.focus.arrows = {}
	for segmentIndex = 1, 8 do
		local outline = button.focus:CreateLine(nil, "OVERLAY", nil, 6)
		outline:SetBlendMode("BLEND")
		outline:SetThickness(7)
		outline:Hide()
		button.focus.arrowOutlines[segmentIndex] = outline
		local arrow = button.focus:CreateLine(nil, "OVERLAY", nil, 7)
		arrow:SetBlendMode("BLEND")
		arrow:SetThickness(4)
		arrow:Hide()
		button.focus.arrows[segmentIndex] = arrow
	end
	button.focus.confirmFlash = button.animatedVisual:CreateTexture(nil, "OVERLAY", nil, 6)
	button.focus.confirmFlash:SetAllPoints(button.animatedVisual)
	button.focus.confirmFlash:SetColorTexture(1, 0.82, 0.12, 0.55)
	button.focus.confirmFlash:SetBlendMode("ADD")
	button.focus.confirmFlash:Hide()
	button.focus:Hide()
	button:SetScript("OnEnter", function(self)
		if visual and visual.previewMode then
			self.highlight:SetShown(visual.selectionOverlayEnabled == true)
			local menu = visual.menu
			if self.action and menu then QC:ShowActionTooltip(self, self.action, menu, true) end
		end
	end)
	button:SetScript("OnLeave", function(self)
		if visual and visual.previewMode then
			self.highlight:Hide()
			QC:HideActionTooltip(self)
		end
	end)
	button:SetScript("OnClick", function(self)
		if not (visual and visual.previewMode and self.sourceIndex) then return end
		QC:HideActionTooltip(self)
		local editor = QC.Editor
		if editor and editor.SelectAction then editor:SelectAction(self.sourceIndex) end
	end)
	button:Hide()
	return button
end

visual = _G.CreateFrame("Frame", "EQOLQuickCastVisual", _G.UIParent)
visual:SetAllPoints()
visual:SetFrameStrata("FULLSCREEN_DIALOG")
visual:Hide()
visual.buttons = {}
visual.levels = {}
visual.entryMenus = {}
visual.breadcrumbIndices = {}
visual.itemIndices = {}
visual.macroIndices = {}
visual.mountUsabilityIndices = {}
visual.registeredStateEvents = {}
visual.spellCooldownIndices = {}
visual.spellCooldownIndicesByID = {}
visual.spellUsabilityIndices = {}
visual.cursorMarker = _G.CreateFrame("Button", nil, visual)
visual.cursorMarker:SetSize(30, 30)
visual.cursorMarker:RegisterForClicks("LeftButtonUp")
visual.cursorMarker.horizontal = visual.cursorMarker:CreateTexture(nil, "OVERLAY")
visual.cursorMarker.horizontal:SetColorTexture(1, 0.82, 0.12, 0.9)
visual.cursorMarker.horizontal:SetPoint("CENTER")
visual.cursorMarker.horizontal:SetSize(30, 2)
visual.cursorMarker.vertical = visual.cursorMarker:CreateTexture(nil, "OVERLAY")
visual.cursorMarker.vertical:SetColorTexture(1, 0.82, 0.12, 0.9)
visual.cursorMarker.vertical:SetPoint("CENTER")
visual.cursorMarker.vertical:SetSize(2, 30)
visual.cursorMarker:SetScript("OnEnter", function(self)
	self.horizontal:SetColorTexture(1, 1, 1, 1)
	self.vertical:SetColorTexture(1, 1, 1, 1)
end)
visual.cursorMarker:SetScript("OnLeave", function(self)
	self.horizontal:SetColorTexture(1, 0.82, 0.12, 0.9)
	self.vertical:SetColorTexture(1, 0.82, 0.12, 0.9)
end)
visual.cursorMarker:SetScript("OnClick", function()
	if not (visual.previewMode and visual.menuID) then return end
	local editor = QC.Editor
	if editor and editor.SelectMenu then editor:SelectMenu(visual.menuID, true) end
end)
visual.cursorMarker:Hide()

visual.originAnchor = _G.CreateFrame("Frame", nil, visual)
visual.originAnchor:SetSize(1, 1)
visual.selectionOriginAnchor = _G.CreateFrame("Frame", nil, visual)
visual.selectionOriginAnchor:SetSize(1, 1)
visual.defaultIndicator = createVisualButton(visual)
visual.defaultIndicator:SetFrameLevel(visual:GetFrameLevel() + 8)
visual.defaultIndicator.animatedVisual:SetFrameLevel(visual.defaultIndicator:GetFrameLevel())
visual.defaultIndicator.labelOverlay:SetFrameLevel(visual.defaultIndicator:GetFrameLevel() + 4)
visual.defaultIndicator.focus:SetFrameLevel(visual.defaultIndicator:GetFrameLevel() + 6)
visual.defaultIndicator.defaultMarker = visual.defaultIndicator.labelOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
visual.defaultIndicator.defaultMarker:SetAtlas("PetJournal-FavoritesIcon", false)
visual.defaultIndicator.defaultMarker:SetPoint("BOTTOMLEFT", visual.defaultIndicator.animatedVisual, "BOTTOMLEFT", -3, -3)
visual.defaultIndicator.defaultMarker:SetSize(18, 18)
visual.defaultIndicator.defaultMarker:Hide()
visual.defaultIndicator:Hide()
visual.title = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
visual.title:SetJustifyH("CENTER")
visual.title:SetWidth(480)
if visual.title.SetWordWrap then visual.title:SetWordWrap(false) end
if visual.title.SetMaxLines then visual.title:SetMaxLines(1) end
visual.title:Hide()
visual.resonance = visual:CreateTexture(nil, "ARTWORK", nil, 0)
visual.resonance:SetAtlas("ChallengeMode-KeystoneSlotFrameGlow", false)
visual.resonance:SetDesaturated(true)
visual.resonance:SetVertexColor(1, 0.76, 0.12, 1)
visual.resonance:SetBlendMode("ADD")
visual.resonance:Hide()
visual.energyLineLayer = _G.CreateFrame("Frame", nil, visual)
visual.energyLineLayer:SetAllPoints(visual)
visual.energyLineLayer:SetFrameLevel(visual:GetFrameLevel() + 20)
visual.energyLineLayer:EnableMouse(false)
visual.energyLineOutline = visual.energyLineLayer:CreateLine(nil, "ARTWORK", nil, 0)
visual.energyLineOutline:SetColorTexture(0.02, 0.02, 0.02, 1)
visual.energyLineOutline:SetThickness(5)
visual.energyLineOutline:SetBlendMode("BLEND")
visual.energyLineOutline:Hide()
visual.energyLine = visual.energyLineLayer:CreateLine(nil, "ARTWORK", nil, 1)
visual.energyLine:SetColorTexture(1, 0.72, 0.08, 1)
visual.energyLine:SetThickness(2)
visual.energyLine:SetBlendMode("BLEND")
visual.energyLine:Hide()
visual.energyPulse = visual:CreateTexture(nil, "OVERLAY", nil, 7)
visual.energyPulse:SetTexture([[Interface\Cooldown\star4]])
visual.energyPulse:SetVertexColor(1, 0.88, 0.3, 1)
visual.energyPulse:SetBlendMode("ADD")
visual.energyPulse:SetSize(14, 14)
visual.energyPulse:Hide()

function QC:ApplyTitleAppearance(menu)
	local title = visual and visual.title
	if not (title and type(menu) == "table" and menu.showTitle == true) then
		if title then title:Hide() end
		return
	end

	title:SetText(menu.name or "")
	local fontSize = menu.titleFontSize or self.DEFAULT_TITLE_FONT_SIZE
	local fontStyle = menu.titleFontOutline or self.DEFAULT_TITLE_FONT_OUTLINE
	local functions = addon.functions
	if functions and functions.SetFontWithFallback and functions.GetFontFlagsForStyle then
		local flags = functions.GetFontFlagsForStyle(fontStyle, self.DEFAULT_TITLE_FONT_OUTLINE)
		functions.SetFontWithFallback(title, menu.titleFont, fontSize, flags, self.DEFAULT_TITLE_FONT)
		if functions.ApplyFontStyleShadow then functions.ApplyFontStyleShadow(title, fontStyle, self.DEFAULT_TITLE_FONT_OUTLINE) end
	else
		local fontPath = getMediaPath("font", menu.titleFont, _G.STANDARD_TEXT_FONT)
		local fontOutline = fontStyle == "NONE" and "" or fontStyle
		if fontPath and title.SetFont then
			local applied = title:SetFont(fontPath, fontSize, fontOutline)
			if not applied and _G.STANDARD_TEXT_FONT then title:SetFont(_G.STANDARD_TEXT_FONT, fontSize, fontOutline) end
		end
	end
	local color = menu.titleColor or self.DEFAULT_TITLE_COLOR
	if menu.titleUseClassColor == true then
		local classToken = addon.variables and addon.variables.unitClass or select(2, _G.UnitClass("player"))
		local classColors = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
		local classColor = classColors and classColors[classToken]
		if classColor then
			title:SetTextColor(classColor.r or 1, classColor.g or 1, classColor.b or 1, color[4] or 1)
			title:Show()
			return
		end
	end
	title:SetTextColor(color[1] or 1, color[2] or 0.82, color[3] or 0, color[4] or 1)
	title:Show()
end

function QC:PositionTitle(menu, entryCount)
	local title = visual and visual.title
	entryCount = tonumber(entryCount) or 0
	if not (title and type(menu) == "table" and menu.showTitle == true and entryCount > 0) then
		if title then title:Hide() end
		return
	end

	local minimumY, maximumY = math.huge, -math.huge
	for index = 1, entryCount do
		local _, offsetY = self:GetSlotOffset(menu, index, entryCount)
		minimumY = math.min(minimumY, offsetY)
		maximumY = math.max(maximumY, offsetY)
	end
	local anchor = menu.titleAnchor or self.DEFAULT_TITLE_ANCHOR
	local offsetX = menu.titleOffsetX or self.DEFAULT_TITLE_OFFSET_X
	local offsetY = menu.titleOffsetY or self.DEFAULT_TITLE_OFFSET_Y
	title:ClearAllPoints()
	if anchor == self.TITLE_ANCHOR_CENTER then
		title:SetPoint("CENTER", visual.originAnchor, "CENTER", offsetX, offsetY)
	elseif anchor == self.TITLE_ANCHOR_BOTTOM then
		local gap = self.TITLE_GAP
		if menu.showLabels ~= false and menu.labelAnchor == "BOTTOM" then
			gap = gap + (menu.labelFontSize or self.DEFAULT_LABEL_FONT_SIZE)
				+ math.max(0, -(menu.labelOffsetY or self.DEFAULT_LABEL_OFFSET_Y))
		end
		title:SetPoint(
			"TOP",
			visual.originAnchor,
			"CENTER",
			offsetX,
			minimumY - (menu.iconSize or self.DEFAULT_ICON_SIZE) / 2 - gap + offsetY
		)
	else
		local gap = self.TITLE_GAP
		if menu.showLabels ~= false and menu.labelAnchor == "TOP" then
			gap = gap + (menu.labelFontSize or self.DEFAULT_LABEL_FONT_SIZE)
				+ math.max(0, menu.labelOffsetY or self.DEFAULT_LABEL_OFFSET_Y)
		end
		title:SetPoint(
			"BOTTOM",
			visual.originAnchor,
			"CENTER",
			offsetX,
			maximumY + (menu.iconSize or self.DEFAULT_ICON_SIZE) / 2 + gap + offsetY
		)
	end
end

function QC:UpdateDefaultIndicator(active)
	local indicator = visual and visual.defaultIndicator
	if not (indicator and indicator:IsShown()) then return end
	active = active == true
	if visual.defaultIndicatorActive == active then return end
	visual.defaultIndicatorActive = active
	indicator:SetAlpha(active and 1 or 0.65)
	self.Animation:SetButtonScale(indicator, active and 1.08 or 0.88)
	indicator.highlight:SetShown(active)
	indicator.highlight:SetAlpha(active and 0.85 or 0)
	indicator.defaultMarker:SetAlpha(active and 1 or 0.72)
end

function QC:ConfigureDefaultIndicator(menu, entries, previewMode)
	local indicator = visual and visual.defaultIndicator
	if not indicator then return end
	indicator:Hide()
	indicator.action = nil
	visual.defaultIndicatorActive = nil
	visual.defaultIndex = nil
	if previewMode == true or not menu.defaultEntryID then return end
	local defaultEntry
	for index = 1, #entries do
		if entries[index].action.entryID == menu.defaultEntryID then
			visual.defaultIndex = index
			defaultEntry = entries[index]
			break
		end
	end
	if not defaultEntry then return end

	local action = defaultEntry.action
	local indicatorSize = math.max(38, math.min(52, menu.iconSize or self.DEFAULT_ICON_SIZE))
	indicator.action = action
	indicator:SetSize(indicatorSize, indicatorSize)
	indicator.animatedVisual:SetSize(indicatorSize, indicatorSize)
	indicator:ClearAllPoints()
	indicator:SetPoint("CENTER", visual.originAnchor, "CENTER")
	local iconAtlas = not action.customIcon and (action.customIconAtlas or defaultEntry.iconAtlas) or nil
	indicator.icon._eqolQuickActionsTexCoords = nil
	if not iconAtlas then
		indicator.icon:SetTexture(action.customIcon or defaultEntry.icon or 134400)
		indicator.icon:SetTexCoord(0, 1, 0, 1)
	end
	indicator.icon:SetDesaturated(false)
	indicator.highlight:SetColorTexture(1, 0.82, 0.2, 0.34)
	indicator.invalid:Hide()
	indicator.cooldown:Hide()
	indicator.count:Hide()
	indicator.label:Hide()
	indicator.submenuMarker:Hide()
	indicator.focus:Hide()
	indicator.defaultMarker:Show()
	self:ApplyButtonAppearance(indicator, menu)
	if iconAtlas and indicator.icon.SetAtlas then indicator.icon:SetAtlas(iconAtlas, false) end
	indicator.label:Hide()
	indicator.count:Hide()
	indicator.cooldown:Hide()
	indicator:Show()
	self:UpdateDefaultIndicator(true)
end

function QC.Animation:Clamp01(value)
	if value <= 0 then return 0 end
	if value >= 1 then return 1 end
	return value
end

function QC.Animation:EaseOutCubic(value)
	value = self:Clamp01(value)
	local inverse = 1 - value
	return 1 - inverse * inverse * inverse
end

function QC.Animation:Smoothstep(value)
	value = self:Clamp01(value)
	return value * value * (3 - 2 * value)
end

function QC.Animation:SetButtonScale(button, scale)
	if not button then return end
	if button.animatedVisual then
		button.animatedVisual:SetScale(scale or 1)
	else
		button:SetScale(scale or 1)
	end
end

function QC.Animation:SetButtonSelectionLayer(button, selected)
	if not button then return end
	local baseFrameLevel = button:GetFrameLevel()
	selected = selected == true
	if button._qaSelectionLayerRaised == selected and button._qaSelectionLayerBase == baseFrameLevel then return end
	button._qaSelectionLayerRaised = selected
	button._qaSelectionLayerBase = baseFrameLevel
	local offset = selected and QC.SELECTION_FRAME_LEVEL_OFFSET or 0
	if button.animatedVisual then button.animatedVisual:SetFrameLevel(baseFrameLevel + offset) end
	if button.cooldown then button.cooldown:SetFrameLevel(baseFrameLevel + offset + 1) end
	if button.appearanceBorder then button.appearanceBorder:SetFrameLevel(baseFrameLevel + offset + 3) end
	if button.labelOverlay then button.labelOverlay:SetFrameLevel(baseFrameLevel + offset + 4) end
	if button.focus then button.focus:SetFrameLevel(baseFrameLevel + offset + 6) end
end

function QC.Animation:GetButtonScale(button)
	if button and button.animatedVisual then return button.animatedVisual:GetScale() end
	return 1
end

function QC.Animation:GetPhysicalLineThickness(region, pixels)
	local pixelUtil = addon.PixelUtil
	if pixelUtil and pixelUtil.SizeFromPixels then return pixelUtil.SizeFromPixels(region, pixels, 1) end
	return pixels
end

function QC.Animation:GetEnergyLinePoints(button)
	local startX, startY = visual.selectionOriginAnchor:GetCenter()
	local endX, endY
	if button then endX, endY = button:GetCenter() end
	if not (startX and startY and endX and endY) then return nil end
	local deltaX, deltaY = endX - startX, endY - startY
	local maximumDelta = math.max(math.abs(deltaX), math.abs(deltaY))
	if maximumDelta > 0 then
		local halfSize = ((button:GetWidth() or QC.DEFAULT_ICON_SIZE) * self:GetButtonScale(button)) / 2
		local edgeFactor = math.min(1, halfSize / maximumDelta)
		endX = endX - deltaX * edgeFactor
		endY = endY - deltaY * edgeFactor
	end
	local pixelUtil = addon.PixelUtil
	if pixelUtil and pixelUtil.Snap then
		startX = pixelUtil.Snap(startX, _G.UIParent)
		startY = pixelUtil.Snap(startY, _G.UIParent)
		endX = pixelUtil.Snap(endX, _G.UIParent)
		endY = pixelUtil.Snap(endY, _G.UIParent)
	end
	return startX, startY, endX, endY
end

function QC.Animation:SetEnergyLinePoints(line, startX, startY, endX, endY)
	line:ClearAllPoints()
	line:SetStartPoint("BOTTOMLEFT", _G.UIParent, startX, startY)
	line:SetEndPoint("BOTTOMLEFT", _G.UIParent, endX, endY)
end

function QC.Animation:GetOpenDelay(index, entryCount)
	if entryCount <= 1 then return 0 end
	local layout = visual.rootMenu and visual.rootMenu.layout
	local stage, maxStage
	if layout == "horizontal" or layout == "vertical" then
		local minimumDistance = entryCount % 2 == 0 and 0.5 or 0
		stage = math.abs(index - (entryCount + 1) / 2) - minimumDistance
		maxStage = math.floor((entryCount - 1) / 2)
	else
		stage = math.min(index - 1, entryCount - index + 1)
		maxStage = math.floor(entryCount / 2)
	end
	if maxStage <= 0 then return 0 end
	return self:Clamp01(stage / maxStage) * self.OPEN_DYNAMIC_STAGGER_WINDOW
end

function QC.Animation:ResetButton(button)
	if not button then return end
	button:SetAlpha(1)
	button:SetScale(1)
	self:SetButtonSelectionLayer(button, false)
	self:SetButtonScale(button, 1)
	button._qaOpenAlpha = 1
	button._qaOpenScale = 1
	button._qaOpenDelay = 0
	button._qaFocusProgress = 0
	button._qaDimAlpha = 1
	button._qaCloseAlpha = nil
	button._qaCloseScale = nil
	button._qaCloseFocus = nil
	if button.focus then
		button.focus:SetAlpha(1)
		button.focus:Hide()
		button.focus.confirmFlash:SetAlpha(1)
		button.focus.confirmFlash:Hide()
	end
	if button.highlight then
		button.highlight:SetAlpha(1)
		button.highlight:Hide()
	end
end

function QC.Animation:SetFocusVisual(button, progress, alphaMultiplier)
	if not (button and button.focus) then return end
	progress = self:Clamp01(progress or 0)
	if progress <= 0 then
		button.focus.confirmFlash:Hide()
		button.focus:Hide()
		return
	end
	local indicator = visual.selectionIndicator or QC.DEFAULT_SELECTION_INDICATOR
	if indicator == QC.SELECTION_INDICATOR_NONE then
		button.focus:Hide()
		return
	end
	local eased = self:EaseOutCubic(progress)
	local size = button:GetWidth() or QC.DEFAULT_ICON_SIZE
	local visualScale = self:GetButtonScale(button)
	local scaledSize = size * visualScale
	local markerLength = math.max(8, math.floor(scaledSize * 0.26 + 0.5))
	local markerThickness = math.max(1, math.min(2, size / 24))
	local gap = 10 - 6 * eased + (scaledSize - size) / 2
	local markers = button.focus.markers
	local color = visual.selectionIndicatorColor or QC.DEFAULT_SELECTION_INDICATOR_COLOR
	local r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
	if indicator == QC.SELECTION_INDICATOR_LINES then
		for segmentIndex = 1, 8 do
			button.focus.arrowOutlines[segmentIndex]:Hide()
			button.focus.arrows[segmentIndex]:Hide()
		end
		for markerIndex = 1, 4 do
			markers[markerIndex]:ClearAllPoints()
			markers[markerIndex]:SetColorTexture(r, g, b, a)
			markers[markerIndex]:Show()
		end
		markers[1]:SetSize(markerLength, markerThickness)
		markers[1]:SetPoint("BOTTOM", button, "TOP", 0, gap)
		markers[2]:SetSize(markerLength, markerThickness)
		markers[2]:SetPoint("TOP", button, "BOTTOM", 0, -gap)
		markers[3]:SetSize(markerThickness, markerLength)
		markers[3]:SetPoint("RIGHT", button, "LEFT", -gap, 0)
		markers[4]:SetSize(markerThickness, markerLength)
		markers[4]:SetPoint("LEFT", button, "RIGHT", gap, 0)
	else
		for markerIndex = 1, 4 do markers[markerIndex]:Hide() end
		local arrowOutlines = button.focus.arrowOutlines
		local arrows = button.focus.arrows
		local arrowHalfWidth = math.max(5, math.min(8, scaledSize * 0.11))
		local arrowDepth = math.max(6, math.min(10, scaledSize * 0.14))
		local edge = size / 2 + gap
		for segmentIndex = 1, 8 do
			arrowOutlines[segmentIndex]:ClearAllPoints()
			arrowOutlines[segmentIndex]:SetColorTexture(0.02, 0.02, 0.02, a)
			arrowOutlines[segmentIndex]:Show()
			arrows[segmentIndex]:ClearAllPoints()
			arrows[segmentIndex]:SetColorTexture(r, g, b, a)
			arrows[segmentIndex]:Show()
		end
		arrowOutlines[1]:SetStartPoint("CENTER", button, -arrowHalfWidth, edge + arrowDepth)
		arrowOutlines[1]:SetEndPoint("CENTER", button, 0, edge)
		arrowOutlines[2]:SetStartPoint("CENTER", button, arrowHalfWidth, edge + arrowDepth)
		arrowOutlines[2]:SetEndPoint("CENTER", button, 0, edge)
		arrowOutlines[3]:SetStartPoint("CENTER", button, -arrowHalfWidth, -edge - arrowDepth)
		arrowOutlines[3]:SetEndPoint("CENTER", button, 0, -edge)
		arrowOutlines[4]:SetStartPoint("CENTER", button, arrowHalfWidth, -edge - arrowDepth)
		arrowOutlines[4]:SetEndPoint("CENTER", button, 0, -edge)
		arrowOutlines[5]:SetStartPoint("CENTER", button, -edge - arrowDepth, -arrowHalfWidth)
		arrowOutlines[5]:SetEndPoint("CENTER", button, -edge, 0)
		arrowOutlines[6]:SetStartPoint("CENTER", button, -edge - arrowDepth, arrowHalfWidth)
		arrowOutlines[6]:SetEndPoint("CENTER", button, -edge, 0)
		arrowOutlines[7]:SetStartPoint("CENTER", button, edge + arrowDepth, -arrowHalfWidth)
		arrowOutlines[7]:SetEndPoint("CENTER", button, edge, 0)
		arrowOutlines[8]:SetStartPoint("CENTER", button, edge + arrowDepth, arrowHalfWidth)
		arrowOutlines[8]:SetEndPoint("CENTER", button, edge, 0)
		for segmentIndex = 1, 8 do
			local startPoint, relativeTo, startX, startY = arrowOutlines[segmentIndex]:GetStartPoint()
			local endPoint, endRelativeTo, endX, endY = arrowOutlines[segmentIndex]:GetEndPoint()
			arrows[segmentIndex]:SetStartPoint(startPoint, relativeTo, startX, startY)
			arrows[segmentIndex]:SetEndPoint(endPoint, endRelativeTo, endX, endY)
		end
	end
	button.focus:SetAlpha(progress * (alphaMultiplier or 1))
	button.focus:Show()
end

function QC.Animation:HideGlobalEffects()
	visual.resonance:Hide()
	visual.energyLineOutline:Hide()
	visual.energyLine:Hide()
	visual.energyPulse:Hide()
end

function QC.Animation:Interrupt()
	visual.animationPhase = nil
	visual.closeReason = nil
	visual.closeSelectedIndex = nil
	visual.selectionPulseStartedAt = nil
	visual.selectionAnimationSettled = nil
	visual:SetScript("OnUpdate", nil)
	self:HideGlobalEffects()
	for _, button in ipairs(visual.buttons) do self:ResetButton(button) end
end

function QC.Animation:BeginOpen(entryCount)
	local style = QC:GetAnimationStyle()
	visual.animationStyle = style
	visual.selectionIndicator = QC:GetSelectionIndicator()
	visual.selectionIndicatorColor = QC:GetSelectionIndicatorColor()
	visual.selectionIconScale = QC:GetSelectionIconScale()
	visual.selectionOverlayEnabled = QC:IsSelectionOverlayEnabled()
	visual.unselectedIconAlpha = QC:GetUnselectedIconAlpha()
	local indicatorColor = visual.selectionIndicatorColor or QC.DEFAULT_SELECTION_INDICATOR_COLOR
	visual.energyLine:SetColorTexture(
		indicatorColor[1] or 1,
		indicatorColor[2] or 1,
		indicatorColor[3] or 1,
		indicatorColor[4] or 1
	)
	visual.energyLineOutline:SetColorTexture(0.02, 0.02, 0.02, indicatorColor[4] or 1)
	visual.energyLineThickness = self:GetPhysicalLineThickness(visual.energyLine, QC.SELECTION_LINE_PIXELS)
	visual.energyLineOutlineThickness = self:GetPhysicalLineThickness(
		visual.energyLineOutline,
		QC.SELECTION_LINE_OUTLINE_PIXELS
	)
	visual.animationPhase = style == QC.ANIMATION_STYLE_NONE and "active" or "opening"
	visual.openStartedAt = _G.GetTime()
	visual.selectionPulseStartedAt = nil
	visual.selectionAnimationSettled = false
	self:HideGlobalEffects()
	for index = 1, entryCount do
		local button = visual.buttons[index]
		self:ResetButton(button)
		if style == QC.ANIMATION_STYLE_REDUCED then
			button._qaOpenAlpha = 0
			button._qaOpenScale = 0.94
			button:SetAlpha(0)
			self:SetButtonScale(button, 0.94)
		elseif style == QC.ANIMATION_STYLE_DYNAMIC then
			button._qaOpenDelay = self:GetOpenDelay(index, entryCount)
			button._qaOpenAlpha = 0
			button._qaOpenScale = 0.85
			button:SetAlpha(0)
			self:SetButtonScale(button, 0.85)
		end
	end
	if style == QC.ANIMATION_STYLE_DYNAMIC then
		visual.resonance:SetSize(18, 18)
		visual.resonance:SetAlpha(0)
		visual.resonance:Show()
	end
	return style ~= QC.ANIMATION_STYLE_NONE
end

function QC.Animation:UpdateOpen(now, entryCount)
	local style = visual.animationStyle
	if style == QC.ANIMATION_STYLE_NONE then return true end
	local elapsed = now - (visual.openStartedAt or now)
	local duration = style == QC.ANIMATION_STYLE_DYNAMIC and self.OPEN_DYNAMIC_DURATION or self.OPEN_REDUCED_DURATION
	local complete = true
	for index = 1, entryCount do
		local button = visual.buttons[index]
		local progress = self:Clamp01((elapsed - (button._qaOpenDelay or 0)) / duration)
		local eased = self:EaseOutCubic(progress)
		button._qaOpenAlpha = eased
		if style == QC.ANIMATION_STYLE_DYNAMIC then
			if progress < 0.72 then
				local grow = self:EaseOutCubic(progress / 0.72)
				button._qaOpenScale = 0.85 + (1.035 - 0.85) * grow
			else
				local settle = self:Smoothstep((progress - 0.72) / 0.28)
				button._qaOpenScale = 1.035 + (1 - 1.035) * settle
			end
		else
			button._qaOpenScale = 0.94 + 0.06 * eased
		end
		if progress < 1 then complete = false end
	end
	if style == QC.ANIMATION_STYLE_DYNAMIC then
		local waveProgress = self:Clamp01(elapsed / (self.OPEN_DYNAMIC_DURATION + self.OPEN_DYNAMIC_STAGGER_WINDOW))
		local iconSize = visual.rootMenu and visual.rootMenu.iconSize or QC.DEFAULT_ICON_SIZE
		local waveSize = math.max(96, math.min(360, ((visual.maxEntryDistance or 0) + iconSize) * 2))
		local size = 18 + (waveSize - 18) * self:EaseOutCubic(waveProgress)
		visual.resonance:SetSize(size, size)
		visual.resonance:SetAlpha(math.sin(math.pi * waveProgress) * 0.34)
		visual.resonance:SetShown(waveProgress < 1)
	end
	if complete then
		visual.animationPhase = "active"
		visual.resonance:Hide()
	end
	return complete
end

function QC.Animation:SelectionChanged(selectedIndex)
	visual.selectionAnimationSettled = false
	for index = 1, #(visual.entries or {}) do
		local button = visual.buttons[index]
		self:SetButtonSelectionLayer(button, index == selectedIndex or visual.breadcrumbIndices[index] == true)
	end
	if visual.animationStyle == QC.ANIMATION_STYLE_DYNAMIC and selectedIndex then
		visual.selectionPulseStartedAt = _G.GetTime()
	else
		visual.selectionPulseStartedAt = nil
	end
end

function QC.Animation:SetEnergyPulsePosition(button, progress, alpha)
	local startX, startY = visual.selectionOriginAnchor:GetCenter()
	local endX, endY
	if button then
		endX, endY = button:GetCenter()
	end
	if not (startX and startY and endX and endY) then
		visual.energyPulse:Hide()
		return
	end
	visual.energyPulse:ClearAllPoints()
	visual.energyPulse:SetPoint(
		"CENTER",
		_G.UIParent,
		"BOTTOMLEFT",
		startX + (endX - startX) * progress,
		startY + (endY - startY) * progress
	)
	visual.energyPulse:SetAlpha(alpha or 1)
	visual.energyPulse:Show()
end

function QC.Animation:UpdateSelection(now, elapsed, entryCount)
	local style = visual.animationStyle
	local selectedIndex = visual.selectedIndex
	if style == QC.ANIMATION_STYLE_NONE then
		self:HideGlobalEffects()
		for index = 1, entryCount do
			local button = visual.buttons[index]
			local selected = index == selectedIndex
			local breadcrumb = visual.breadcrumbIndices[index] == true
			local focus = selected and 1 or breadcrumb and 0.55 or 0
			button:SetAlpha(button._qaOpenAlpha or 1)
			self:SetButtonScale(
				button,
				(button._qaOpenScale or 1) * (selected and visual.selectionIconScale or breadcrumb and 1.04 or 1)
			)
			button._qaFocusProgress = focus
			button._qaDimAlpha = 1
			button.highlight:SetShown(visual.selectionOverlayEnabled == true and (selected or breadcrumb))
			button.highlight:SetAlpha(selected and 1 or 0.6)
			self:SetFocusVisual(button, focus)
		end
		return true
	end
	local selectionStep = self:Clamp01(elapsed / self.SELECTION_DURATION)
	local selectedScale = visual.selectionIconScale or QC.DEFAULT_SELECTION_ICON_SCALE
	local settled = true
	for index = 1, entryCount do
		local button = visual.buttons[index]
		local selected = index == selectedIndex
		local breadcrumb = visual.breadcrumbIndices[index] == true
		local focusTarget = selected and 1 or breadcrumb and 0.55 or 0
		local focusProgress = button._qaFocusProgress or 0
		if focusProgress < focusTarget then
			focusProgress = math.min(focusTarget, focusProgress + selectionStep)
		elseif focusProgress > focusTarget then
			focusProgress = math.max(focusTarget, focusProgress - selectionStep)
		end
		button._qaFocusProgress = focusProgress
		if focusProgress ~= focusTarget then settled = false end
		local unselectedAlpha = visual.unselectedIconAlpha or QC.DEFAULT_UNSELECTED_ICON_ALPHA
		local dimTarget = selectedIndex and not selected and not breadcrumb and unselectedAlpha or 1
		local dimAlpha = button._qaDimAlpha or 1
		if dimAlpha < dimTarget then
			dimAlpha = math.min(dimTarget, dimAlpha + selectionStep * (1 - unselectedAlpha))
		elseif dimAlpha > dimTarget then
			dimAlpha = math.max(dimTarget, dimAlpha - selectionStep * (1 - unselectedAlpha))
		end
		button._qaDimAlpha = dimAlpha
		if dimAlpha ~= dimTarget then settled = false end
		local targetScale = selected and selectedScale or breadcrumb and 1.04 or 1
		local selectionScale = 1 + (targetScale - 1) * self:EaseOutCubic(focusProgress)
		self:SetButtonScale(button, (button._qaOpenScale or 1) * selectionScale)
		button:SetAlpha((button._qaOpenAlpha or 1) * dimAlpha)
		button.highlight:SetShown(visual.selectionOverlayEnabled == true and (focusTarget > 0 or focusProgress > 0))
		button.highlight:SetAlpha(0.5 + 0.5 * focusProgress)
		self:SetFocusVisual(button, focusProgress)
	end
	if style == QC.ANIMATION_STYLE_DYNAMIC and selectedIndex and visual.buttons[selectedIndex] then
		local selectedButton = visual.buttons[selectedIndex]
		local startX, startY, endX, endY = self:GetEnergyLinePoints(selectedButton)
		if not startX then
			visual.energyLineOutline:Hide()
			visual.energyLine:Hide()
			visual.energyPulse:Hide()
			return settled
		end
		self:SetEnergyLinePoints(visual.energyLineOutline, startX, startY, endX, endY)
		visual.energyLineOutline:SetThickness(
			visual.energyLineOutlineThickness
				or self:GetPhysicalLineThickness(visual.energyLineOutline, QC.SELECTION_LINE_OUTLINE_PIXELS)
		)
		visual.energyLineOutline:SetAlpha(1)
		visual.energyLineOutline:Show()
		self:SetEnergyLinePoints(visual.energyLine, startX, startY, endX, endY)
		visual.energyLine:SetThickness(
			visual.energyLineThickness or self:GetPhysicalLineThickness(visual.energyLine, QC.SELECTION_LINE_PIXELS)
		)
		visual.energyLine:SetAlpha(1)
		visual.energyLine:Show()
		local pulseElapsed = visual.selectionPulseStartedAt and now - visual.selectionPulseStartedAt or math.huge
		if pulseElapsed < 0.16 then
			settled = false
			local pulseProgress = self:Clamp01(pulseElapsed / 0.16)
			self:SetEnergyPulsePosition(selectedButton, self:EaseOutCubic(pulseProgress), math.sin(math.pi * pulseProgress))
		else
			visual.energyPulse:Hide()
		end
	else
		visual.energyLineOutline:Hide()
		visual.energyLine:Hide()
		visual.energyPulse:Hide()
	end
	return settled
end

function QC.Animation:UpdateActive(now, elapsed, entryCount)
	local wasOpening = visual.animationPhase == "opening"
	if wasOpening then self:UpdateOpen(now, entryCount) end
	if wasOpening or visual.selectionAnimationSettled ~= true then
		local selectionSettled = self:UpdateSelection(now, elapsed, entryCount)
		visual.selectionAnimationSettled = visual.animationPhase ~= "opening" and selectionSettled == true
	end
end

function QC.Animation:BeginClose(reason, selectedIndex, entryCount)
	local style = visual.animationStyle or QC:GetAnimationStyle()
	if style == QC.ANIMATION_STYLE_NONE or visual.previewMode then return false end
	if reason ~= "confirm" or not selectedIndex or not visual.buttons[selectedIndex] then
		reason = "cancel"
		selectedIndex = nil
	end
	visual.animationPhase = "closing"
	visual.closeReason = reason
	visual.closeSelectedIndex = selectedIndex
	visual.closeStartedAt = _G.GetTime()
	visual.closeEntryCount = entryCount
	visual.closeDuration = style == QC.ANIMATION_STYLE_DYNAMIC and self.CLOSE_DYNAMIC_DURATION or self.CLOSE_REDUCED_DURATION
	for index = 1, entryCount do
		local button = visual.buttons[index]
		button._qaCloseAlpha = button:GetAlpha()
		button._qaCloseScale = self:GetButtonScale(button)
		button._qaCloseFocus = button._qaFocusProgress or 0
	end
	visual.resonance:Hide()
	return true
end

function QC.Animation:UpdateClose(now)
	local duration = visual.closeDuration or self.CLOSE_REDUCED_DURATION
	local progress = self:Clamp01((now - (visual.closeStartedAt or now)) / duration)
	local eased = self:Smoothstep(progress)
	local selectedIndex = visual.closeSelectedIndex
	local confirm = visual.closeReason == "confirm" and selectedIndex ~= nil
	local entryCount = visual.closeEntryCount or 0
	for index = 1, entryCount do
		local button = visual.buttons[index]
		local startAlpha = button._qaCloseAlpha or 1
		local startScale = button._qaCloseScale or 1
		if confirm and index == selectedIndex then
			local punchTarget = math.max(startScale, 1.18)
			local punch
			if progress < 0.45 then
				punch = startScale + (punchTarget - startScale) * self:EaseOutCubic(progress / 0.45)
			else
				punch = punchTarget + (1.10 - punchTarget) * self:Smoothstep((progress - 0.45) / 0.55)
			end
			local alpha = progress < 0.58 and startAlpha or startAlpha * (1 - self:Clamp01((progress - 0.58) / 0.42))
			self:SetButtonScale(button, punch)
			button:SetAlpha(alpha)
			button.highlight:SetShown(visual.selectionOverlayEnabled == true)
			button.highlight:SetAlpha(alpha)
			self:SetFocusVisual(button, math.max(button._qaCloseFocus or 0, 1 - progress * 0.65), alpha)
			button.focus.confirmFlash:SetAlpha(math.sin(math.pi * progress) * 0.85)
			button.focus.confirmFlash:SetShown(visual.selectionOverlayEnabled == true)
		else
			local fadeProgress = confirm and self:Clamp01(progress / 0.55) or eased
			button:SetAlpha(startAlpha * (1 - fadeProgress))
			self:SetButtonScale(button, startScale * (1 - 0.08 * eased))
			button.highlight:SetAlpha(1 - fadeProgress)
			self:SetFocusVisual(button, (button._qaCloseFocus or 0) * (1 - progress), 1 - fadeProgress)
			button.focus.confirmFlash:Hide()
		end
	end
	if confirm and selectedIndex and visual.animationStyle == QC.ANIMATION_STYLE_DYNAMIC then
		local selectedButton = visual.buttons[selectedIndex]
		local startX, startY, endX, endY = self:GetEnergyLinePoints(selectedButton)
		if not startX then
			visual.energyLineOutline:Hide()
			visual.energyLine:Hide()
			visual.energyPulse:Hide()
			return progress >= 1
		end
		local linePixels = QC.SELECTION_LINE_PIXELS + math.sin(math.pi * progress) * 2
		local lineThickness = self:GetPhysicalLineThickness(visual.energyLine, linePixels)
		local outlineThickness = self:GetPhysicalLineThickness(
			visual.energyLineOutline,
			linePixels + QC.SELECTION_LINE_OUTLINE_PIXELS - QC.SELECTION_LINE_PIXELS
		)
		self:SetEnergyLinePoints(visual.energyLineOutline, startX, startY, endX, endY)
		visual.energyLineOutline:SetThickness(outlineThickness)
		visual.energyLineOutline:SetAlpha(1 - progress)
		visual.energyLineOutline:Show()
		self:SetEnergyLinePoints(visual.energyLine, startX, startY, endX, endY)
		visual.energyLine:SetThickness(lineThickness)
		visual.energyLine:SetAlpha(1 - progress)
		visual.energyLine:Show()
		self:SetEnergyPulsePosition(selectedButton, self:EaseOutCubic(progress), math.sin(math.pi * progress))
	else
		visual.energyLineOutline:Hide()
		visual.energyLine:Hide()
		visual.energyPulse:Hide()
	end
	return progress >= 1
end

function QC.Animation:FinalizeClose()
	QC:HideActionTooltip()
	_G.wipe(visual.levels)
	_G.wipe(visual.entryMenus)
	_G.wipe(visual.breadcrumbIndices)
	visual.rootMenuID = nil
	visual.rootMenu = nil
	visual.activeDepth = nil
	visual.activeFirstIndex = nil
	visual.activeLastIndex = nil
	visual.activeOriginOffsetX = nil
	visual.activeOriginOffsetY = nil
	visual.menuID = nil
	visual.menu = nil
	visual.entries = nil
	visual.previewMode = false
	visual.selectedIndex = nil
	visual.wheelSelectedIndex = nil
	visual.tooltipIndex = nil
	visual.macroEntryCount = 0
	visual.macroElapsed = 0
	visual.cursorScreen = nil
	visual.cursorMarker:Hide()
	visual.defaultIndicator:Hide()
	visual.defaultIndicatorActive = nil
	visual.defaultIndex = nil
	visual.title:Hide()
	visual.originAnchor:ClearAllPoints()
	visual.selectionOriginAnchor:ClearAllPoints()
	visual.animationPhase = nil
	visual.closeReason = nil
	visual.closeSelectedIndex = nil
	visual.closeEntryCount = nil
	visual.selectionPulseStartedAt = nil
	visual.selectionAnimationSettled = nil
	visual:SetScript("OnUpdate", nil)
	if QC.SetVisualStateEventsEnabled then QC:SetVisualStateEventsEnabled(false) end
	self:HideGlobalEffects()
	visual:Hide()
	for _, button in ipairs(visual.buttons) do
		self:ResetButton(button)
		button.sourceIndex = nil
		button.action = nil
		button:EnableMouse(false)
		button:Hide()
	end
end

local function resolveItemID(item)
	if _G.issecretvalue and _G.issecretvalue(item) then return nil end
	if item == nil then return nil end
	if type(item) == "number" then return item > 0 and math.floor(item) or nil end
	if type(item) ~= "string" or item == "" then return nil end
	local itemID = tonumber(item:match("item:(%d+)")) or tonumber(item)
	if not itemID and _G.C_Item and _G.C_Item.GetItemInfoInstant then itemID = _G.C_Item.GetItemInfoInstant(item) end
	return type(itemID) == "number" and itemID > 0 and math.floor(itemID) or nil
end

local function callTooltipMethod(method, tooltip, ...)
	if type(method) ~= "function" then return false end
	local ok, result = pcall(method, tooltip, ...)
	return ok and result ~= false
end

local function setItemTooltip(tooltip, item)
	local itemID = resolveItemID(item)
	if not itemID then return false end
	local ownsToy = _G.PlayerHasToy and _G.PlayerHasToy(itemID)
	if not (_G.issecretvalue and _G.issecretvalue(ownsToy)) and ownsToy and tooltip.SetToyByItemID then
		if callTooltipMethod(tooltip.SetToyByItemID, tooltip, itemID) then return true end
	end
	if tooltip.SetItemByID then return callTooltipMethod(tooltip.SetItemByID, tooltip, itemID) end
	return false
end

function QC:HideActionTooltip(owner)
	local tooltip = _G.GameTooltip
	if not tooltip then return end
	if not owner then
		owner = self.actionTooltipOwner
		if not owner then return end
	end
	local trackedOwner = self.actionTooltipOwner == owner
	if trackedOwner and self.actionBattlePetTooltipShown and _G.BattlePetTooltip then
		_G.BattlePetTooltip:Hide()
	end
	if not tooltip.IsOwned or tooltip:IsOwned(owner) then tooltip:Hide() end
	if trackedOwner then
		self.actionTooltipOwner = nil
		self.actionBattlePetTooltipShown = nil
	end
end

function QC:ShowActionTooltip(owner, action, menu, ignoreMenuSetting)
	local tooltip = _G.GameTooltip
	if not (tooltip and owner and type(action) == "table") then return false end
	if not ignoreMenuSetting and type(menu) == "table" and menu.showTooltips == false then
		self:HideActionTooltip(owner)
		return false
	end
	if self.actionBattlePetTooltipShown and _G.BattlePetTooltip then _G.BattlePetTooltip:Hide() end
	if type(_G.GameTooltip_SetDefaultAnchor) == "function" then
		_G.GameTooltip_SetDefaultAnchor(tooltip, owner)
	else
		tooltip:SetOwner(owner, "ANCHOR_RIGHT")
	end
	self.actionTooltipOwner = owner
	self.actionBattlePetTooltipShown = nil
	tooltip:ClearLines()

	local shown = false
	local battlePetTooltipShown = false
	if action.kind == "spell" and tooltip.SetSpellByID then
		shown = callTooltipMethod(tooltip.SetSpellByID, tooltip, action.id, false)
	elseif action.kind == "item" then
		shown = setItemTooltip(tooltip, action.id)
	elseif action.kind == "mount" and tooltip.SetMountBySpellID and _G.C_MountJournal and _G.C_MountJournal.GetMountInfoByID then
		local spellID = select(2, _G.C_MountJournal.GetMountInfoByID(action.id))
		if not (_G.issecretvalue and _G.issecretvalue(spellID)) and spellID then
			shown = callTooltipMethod(tooltip.SetMountBySpellID, tooltip, spellID)
		end
	elseif action.kind == "outfit" and tooltip.SetOutfit then
		shown = callTooltipMethod(tooltip.SetOutfit, tooltip, action.id)
	elseif action.kind == "macro" then
		local macroIndex = findMacro(action)
		if macroIndex and _G.GetMacroItem then
			local itemName, itemLink = _G.GetMacroItem(macroIndex)
			if not (_G.issecretvalue and (_G.issecretvalue(itemName) or _G.issecretvalue(itemLink))) then
				shown = setItemTooltip(tooltip, itemLink or itemName)
			end
		end
		if not shown then
			local spellID = macroIndex and _G.GetMacroSpell and _G.GetMacroSpell(macroIndex)
			if _G.issecretvalue and _G.issecretvalue(spellID) then spellID = nil end
			if spellID and tooltip.SetSpellByID then shown = callTooltipMethod(tooltip.SetSpellByID, tooltip, spellID, false) end
		end
	elseif action.kind == "battlepet"
		and _G.C_PetJournal
		and _G.C_PetJournal.GetPetInfoByPetID
		and _G.C_PetJournal.GetPetStats
		and _G.BattlePetToolTip_Show
	then
		local infoOK, speciesID, customName, level = pcall(_G.C_PetJournal.GetPetInfoByPetID, action.id)
		local statsOK, _, maxHealth, power, speed, rarity = pcall(_G.C_PetJournal.GetPetStats, action.id)
		local secret = _G.issecretvalue
			and (
				_G.issecretvalue(speciesID)
				or _G.issecretvalue(customName)
				or _G.issecretvalue(level)
				or _G.issecretvalue(maxHealth)
				or _G.issecretvalue(power)
				or _G.issecretvalue(speed)
				or _G.issecretvalue(rarity)
			)
		if infoOK
			and statsOK
			and not secret
			and type(speciesID) == "number"
			and speciesID > 0
			and type(level) == "number"
			and type(maxHealth) == "number"
			and type(power) == "number"
			and type(speed) == "number"
			and type(rarity) == "number"
		then
			battlePetTooltipShown = pcall(_G.BattlePetToolTip_Show, speciesID, level, rarity, maxHealth, power, speed, customName)
			shown = battlePetTooltipShown
		end
	elseif action.kind == "eqol" and action.id == "hearthstone" then
		local functions = addon.MythicPlus and addon.MythicPlus.functions
		local itemID = functions and functions.GetRandomHearthstoneItemID and functions.GetRandomHearthstoneItemID()
		if not (_G.issecretvalue and _G.issecretvalue(itemID)) and itemID ~= nil then shown = setItemTooltip(tooltip, itemID) end
	end

	if not shown then
		local resolvedName = self:ResolveAction(action)
		local name = action.customLabel or action.managedLabel or resolvedName or "?"
		tooltip:SetText(name, 1, 0.82, 0)
		local kindLabel = action.kind == "macro" and (_G.MACRO or "Macro")
			or action.kind == "battlepet" and (_G.BATTLE_PET or "Battle Pet")
			or action.kind == "eqol" and (L["QuickCastEnhanceQoLActions"] or "Enhance QoL")
			or action.kind == "menu" and (L["QuickCastNestedMenu"] or "QuickActions ring")
			or action.kind == "mount" and (_G.MOUNT or "Mount")
			or action.kind == "outfit" and (L["QuickCastOutfits"] or "Outfits")
		if kindLabel then tooltip:AddLine(kindLabel, 0.75, 0.75, 0.75) end
	end
	if battlePetTooltipShown then
		self.actionBattlePetTooltipShown = true
		tooltip:Hide()
		return true
	end
	tooltip:Show()
	return true
end

local function getItemUsability(item)
	local itemID = resolveItemID(item)
	local ownsToy = itemID and _G.PlayerHasToy and _G.PlayerHasToy(itemID)
	if _G.issecretvalue and _G.issecretvalue(ownsToy) then return true end
	if itemID
		and ownsToy
		and _G.C_ToyBox
		and _G.C_ToyBox.IsToyUsable
	then
		return _G.C_ToyBox.IsToyUsable(itemID)
	end
	if _G.C_Item and _G.C_Item.IsUsableItem then return _G.C_Item.IsUsableItem(itemID or item) end
	return true
end

local function getMountUsability(mountID)
	if _G.InCombatLockdown() then return false end
	if _G.C_MountJournal and _G.C_MountJournal.GetMountUsabilityByID then
		return _G.C_MountJournal.GetMountUsabilityByID(mountID, true)
	end
	return true
end

local function getBattlePetUsability(petGUID)
	if _G.InCombatLockdown() then return false end
	if _G.C_PetJournal and _G.C_PetJournal.GetPetSummonInfo then
		return _G.C_PetJournal.GetPetSummonInfo(petGUID)
	end
	if _G.C_PetJournal and _G.C_PetJournal.PetIsSummonable then return _G.C_PetJournal.PetIsSummonable(petGUID) end
	return true
end

local function getActionUsability(action, resolvedValue)
	if action.kind == "spell" then
		local mountID = _G.C_MountJournal
			and _G.C_MountJournal.GetMountFromSpell
			and _G.C_MountJournal.GetMountFromSpell(action.id)
		if mountID then return getMountUsability(mountID) end
		if _G.C_Spell and _G.C_Spell.IsSpellUsable then return _G.C_Spell.IsSpellUsable(action.id) end
	elseif action.kind == "item" then
		return getItemUsability(action.id)
	elseif action.kind == "mount" then
		return getMountUsability(action.id)
	elseif action.kind == "battlepet" then
		return getBattlePetUsability(action.id)
	elseif action.kind == "eqol" then
		if action.id == "hearthstone" then
			local functions = addon.MythicPlus and addon.MythicPlus.functions
			local itemID = functions and functions.GetRandomHearthstoneItemID and functions.GetRandomHearthstoneItemID()
			if _G.issecretvalue and _G.issecretvalue(itemID) then return true end
			if itemID ~= nil then return getItemUsability(itemID) end
			return getItemUsability(6948)
		end
		return not _G.InCombatLockdown()
			and addon.MountActions ~= nil
			and addon.MountActions.PrepareActionButton ~= nil
	elseif action.kind == "macro" then
		local macroIndex = resolvedValue or findMacro(action)
		if macroIndex then
			if _G.GetMacroItem then
				local itemName, itemLink = _G.GetMacroItem(macroIndex)
				if _G.issecretvalue and (_G.issecretvalue(itemName) or _G.issecretvalue(itemLink)) then return true end
				local item = itemLink or itemName
				if item then return getItemUsability(item) end
			end
			local spellID = _G.GetMacroSpell and _G.GetMacroSpell(macroIndex)
			local secretSpellID = _G.issecretvalue and _G.issecretvalue(spellID)
			if not secretSpellID and spellID then
				local mountID = _G.C_MountJournal
					and _G.C_MountJournal.GetMountFromSpell
					and _G.C_MountJournal.GetMountFromSpell(spellID)
				if mountID then return getMountUsability(mountID) end
				if _G.C_Spell and _G.C_Spell.IsSpellUsable then return _G.C_Spell.IsSpellUsable(spellID) end
			end
		end
	end
	return true
end

local function updateUsability(button, action, valid, resolvedValue)
	local usable = valid and getActionUsability(action, resolvedValue)
	if _G.issecretvalue and _G.issecretvalue(usable) then
		button.icon:SetVertexColor(1, 1, 1, 1)
		return
	end
	if usable then
		button.icon:SetVertexColor(1, 1, 1, 1)
	else
		button.icon:SetVertexColor(0.38, 0.38, 0.38, 1)
	end
end

local function setButtonCount(button, count, minimum)
	if _G.issecretvalue and _G.issecretvalue(count) then return false end
	if type(count) ~= "number" or count < (minimum or 0) then return false end
	button.count:SetText(count)
	return true
end

local function updateSpellCharges(button, spellID)
	if not (_G.C_Spell and _G.C_Spell.GetSpellCharges) then return false end
	if _G.issecretvalue and _G.issecretvalue(spellID) then return false end
	if spellID == nil then return false end
	local chargeInfo = _G.C_Spell.GetSpellCharges(spellID)
	if _G.issecretvalue and _G.issecretvalue(chargeInfo) then return false end
	if type(chargeInfo) ~= "table" then return false end
	local currentCharges = chargeInfo.currentCharges
	local maxCharges = chargeInfo.maxCharges
	if _G.issecretvalue and (_G.issecretvalue(currentCharges) or _G.issecretvalue(maxCharges)) then return false end
	if type(maxCharges) ~= "number" or maxCharges <= 1 then return false end
	return setButtonCount(button, currentCharges, 0)
end

local function updateItemCount(button, item)
	if not (_G.C_Item and _G.C_Item.GetItemCount) then return false end
	if _G.issecretvalue and _G.issecretvalue(item) then return false end
	if item == nil then return false end
	local count = _G.C_Item.GetItemCount(item, false, true)
	return setButtonCount(button, count, 2)
end

local function updateItemCooldownAndCount(button, item)
	local itemID = resolveItemID(item)
	if not (itemID and _G.C_Item) then return false end
	local itemCooldownApplied = false
	if _G.C_Item.GetItemCooldown then
		local startTime, duration, isEnabled = _G.C_Item.GetItemCooldown(itemID)
		local secret = _G.issecretvalue and (
			_G.issecretvalue(startTime)
			or _G.issecretvalue(duration)
			or _G.issecretvalue(isEnabled)
		)
		if not secret
			and type(startTime) == "number"
			and type(duration) == "number"
			and isEnabled ~= false
			and isEnabled ~= 0
			and startTime > 0
			and duration > 0
		then
			button.cooldown:SetCooldown(startTime, duration, 1)
			itemCooldownApplied = true
		end
	end
	if not itemCooldownApplied then
		local itemSpellID
		if _G.C_Item.GetItemSpell then itemSpellID = select(2, _G.C_Item.GetItemSpell(itemID)) end
		if _G.issecretvalue and _G.issecretvalue(itemSpellID) then itemSpellID = nil end
		local durationObject = itemSpellID
			and _G.C_Spell
			and _G.C_Spell.GetSpellCooldownDuration
			and _G.C_Spell.GetSpellCooldownDuration(itemSpellID)
		if durationObject and button.cooldown.SetCooldownFromDurationObject then
			button.cooldown:SetCooldownFromDurationObject(durationObject)
		end
	end
	updateItemCount(button, itemID)
	return true
end

local function updateCooldown(button, entry)
	local action = entry and entry.action
	if type(action) ~= "table" then return end
	button.cooldown:Clear()
	button.count:SetText("")
	if action.kind == "spell" and _G.C_Spell and _G.C_Spell.GetSpellCooldownDuration and button.cooldown.SetCooldownFromDurationObject then
		local durationObject = _G.C_Spell.GetSpellCooldownDuration(action.id)
		if durationObject then button.cooldown:SetCooldownFromDurationObject(durationObject) end
		updateSpellCharges(button, action.id)
	elseif action.kind == "item" and _G.C_Item then
		updateItemCooldownAndCount(button, action.id)
	elseif action.kind == "mount"
		and _G.C_MountJournal
		and _G.C_MountJournal.GetMountInfoByID
		and _G.C_Spell
		and _G.C_Spell.GetSpellCooldownDuration
		and button.cooldown.SetCooldownFromDurationObject
	then
		local spellID = select(2, _G.C_MountJournal.GetMountInfoByID(action.id))
		if _G.issecretvalue and _G.issecretvalue(spellID) then spellID = nil end
		local durationObject = spellID and _G.C_Spell.GetSpellCooldownDuration(spellID)
		if durationObject then button.cooldown:SetCooldownFromDurationObject(durationObject) end
	elseif action.kind == "outfit"
		and _G.C_Spell
		and _G.C_Spell.GetSpellCooldownDuration
		and button.cooldown.SetCooldownFromDurationObject
	then
		local durationObject = _G.C_Spell.GetSpellCooldownDuration(QC.TRANSMOG_OUTFIT_COOLDOWN_SPELL_ID)
		if durationObject then button.cooldown:SetCooldownFromDurationObject(durationObject) end
	elseif action.kind == "macro" then
		local macroIndex = entry.resolvedValue
		if _G.issecretvalue and _G.issecretvalue(macroIndex) then macroIndex = nil end
		if type(macroIndex) == "number" then
			local itemHandled = false
			if _G.GetMacroItem then
				local itemName, itemLink = _G.GetMacroItem(macroIndex)
				local secret = _G.issecretvalue and (_G.issecretvalue(itemName) or _G.issecretvalue(itemLink))
				if not secret then itemHandled = updateItemCooldownAndCount(button, itemLink or itemName) end
			end
			if not itemHandled then
				local spellID = _G.GetMacroSpell and _G.GetMacroSpell(macroIndex)
				if _G.issecretvalue and _G.issecretvalue(spellID) then spellID = nil end
				local durationObject = spellID
					and _G.C_Spell
					and _G.C_Spell.GetSpellCooldownDuration
					and _G.C_Spell.GetSpellCooldownDuration(spellID)
				if durationObject and button.cooldown.SetCooldownFromDurationObject then
					button.cooldown:SetCooldownFromDurationObject(durationObject)
				end
				if spellID then updateSpellCharges(button, spellID) end
			end
		end
	end
end

local function refreshVisualActionStates(refreshUsability, refreshCooldown)
	local entries = visual.entries or {}
	if traceState.active then
		local counts = traceState.counts
		counts["refresh.full.calls"] = (counts["refresh.full.calls"] or 0) + 1
		counts["refresh.full.entries"] = (counts["refresh.full.entries"] or 0) + #entries
	end
	for index = 1, #entries do
		local button = visual.buttons[index]
		if button then
			local entry = entries[index]
			local action = entry.action
			if refreshUsability then
				local _, _, valid = QC:ResolveAction(action)
				updateUsability(button, action, valid, entry.resolvedValue)
			end
			if refreshCooldown then updateCooldown(button, entry) end
		end
	end
end

local function refreshVisualEntryIndices(indices, refreshUsability, refreshCooldown)
	if type(indices) ~= "table" then return end
	local entries = visual.entries or {}
	if traceState.active then
		local counts = traceState.counts
		counts["refresh.indexed.calls"] = (counts["refresh.indexed.calls"] or 0) + 1
		counts["refresh.indexed.entries"] = (counts["refresh.indexed.entries"] or 0) + #indices
	end
	for listIndex = 1, #indices do
		local entryIndex = indices[listIndex]
		local button = visual.buttons[entryIndex]
		local entry = entries[entryIndex]
		if button and entry then
			if refreshUsability then updateUsability(button, entry.action, true, entry.resolvedValue) end
			if refreshCooldown then updateCooldown(button, entry) end
		end
	end
end

local function refreshSpellCooldownEntries(spellID, baseSpellID)
	if _G.issecretvalue and _G.issecretvalue(spellID) then
		if traceState.active then
			local counts = traceState.counts
			counts["spellCooldown.secretEvents"] = (counts["spellCooldown.secretEvents"] or 0) + 1
		end
		return
	end
	if traceState.active then
		local spellEventCounts = traceState.spellEventCounts
		local traceSpellID = spellID or 0
		spellEventCounts[traceSpellID] = (spellEventCounts[traceSpellID] or 0) + 1
	end
	if spellID == nil then
		if traceState.active then
			local counts = traceState.counts
			counts["spellCooldown.allEvents"] = (counts["spellCooldown.allEvents"] or 0) + 1
			counts["spellCooldown.entries"] = (counts["spellCooldown.entries"] or 0) + #visual.spellCooldownIndices
		end
		refreshVisualEntryIndices(visual.spellCooldownIndices, false, true)
		return
	end
	local direct = visual.spellCooldownIndicesByID[spellID]
	if direct then refreshVisualEntryIndices(direct, false, true) end
	local refreshed = direct and #direct or 0
	if baseSpellID ~= nil
		and baseSpellID ~= spellID
		and not (_G.issecretvalue and _G.issecretvalue(baseSpellID))
	then
		local base = visual.spellCooldownIndicesByID[baseSpellID]
		if base and base ~= direct then
			refreshVisualEntryIndices(base, false, true)
			refreshed = refreshed + #base
		end
	end
	if traceState.active then
		local counts = traceState.counts
		local key = refreshed > 0 and "spellCooldown.trackedEvents" or "spellCooldown.untrackedEvents"
		counts[key] = (counts[key] or 0) + 1
		counts["spellCooldown.entries"] = (counts["spellCooldown.entries"] or 0) + refreshed
	end
end

local function renderVisual(menu, entries, originX, originY, previewMode)
	QC:HideActionTooltip()
	QC.Animation:Interrupt()
	if traceState.active then
		local counts = traceState.counts
		local key = previewMode and "visual.render.preview" or "visual.render.live"
		counts[key] = (counts[key] or 0) + 1
		counts["visual.render.entries"] = (counts["visual.render.entries"] or 0) + #entries
	end
	_G.wipe(visual.levels)
	_G.wipe(visual.entryMenus)
	_G.wipe(visual.breadcrumbIndices)
	visual.rootMenuID = menu.id
	visual.rootMenu = menu
	visual.activeDepth = 1
	visual.activeFirstIndex = 1
	visual.activeLastIndex = #entries
	visual.activeOriginOffsetX = 0
	visual.activeOriginOffsetY = 0
	visual.menuID = menu.id
	visual.menu = menu
	visual.entries = {}
	visual.levels[1] = {
		menuID = menu.id,
		menu = menu,
		entries = entries,
		firstIndex = 1,
		lastIndex = #entries,
		originOffsetX = 0,
		originOffsetY = 0,
	}
	visual.originX = originX
	visual.originY = originY
	visual.previewMode = previewMode == true
	visual.selectedIndex = nil
	visual.wheelSelectedIndex = nil
	visual.tooltipIndex = nil
	_G.wipe(visual.itemIndices)
	_G.wipe(visual.macroIndices)
	_G.wipe(visual.mountUsabilityIndices)
	_G.wipe(visual.spellCooldownIndices)
	_G.wipe(visual.spellCooldownIndicesByID)
	_G.wipe(visual.spellUsabilityIndices)
	visual.dynamicUsabilityEntryCount = 0
	visual.itemEntryCount = 0
	visual.macroEntryCount = 0
	visual.macroElapsed = 0
	visual.mountUsabilityEntryCount = 0
	visual.spellCooldownEntryCount = 0
	visual.spellUsabilityEntryCount = 0
	visual.maxEntryDistance = 0
	visual:SetFrameStrata(previewMode and "HIGH" or "FULLSCREEN_DIALOG")
	local width, height = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	local screen = _G.C_UI and _G.C_UI.GetUIParent and _G.C_UI.GetUIParent() or _G.UIParent
	local left, bottom, screenWidth, screenHeight = screen:GetRect()
	if left and bottom and screenWidth and screenHeight and screenWidth > 0 and screenHeight > 0 then
		visual.cursorScreen = screen
		visual.cursorLeft = left
		visual.cursorBottom = bottom
		visual.cursorWidth = screenWidth
		visual.cursorHeight = screenHeight
		visual.cursorScale = screen:GetEffectiveScale()
		visual.cursorOriginX = originX * screenWidth
		visual.cursorOriginY = originY * screenHeight
	else
		visual.cursorScreen = nil
	end
	for index = 1, math.max(#entries, #visual.buttons) do
		local entry = entries[index]
		if entry then
			visual.entries[index] = entry
			visual.entryMenus[index] = menu
			local button = visual.buttons[index] or createVisualButton(visual)
			visual.buttons[index] = button
			local action = entry.action
			local name, icon = entry.name, entry.icon
			local offsetX, offsetY = QC:GetSlotOffset(menu, index, #entries)
			visual.maxEntryDistance = math.max(visual.maxEntryDistance, math.sqrt(offsetX * offsetX + offsetY * offsetY))
			button:SetScale(1)
			button:SetSize(menu.iconSize, menu.iconSize)
			button.animatedVisual:SetSize(menu.iconSize, menu.iconSize)
			button:ClearAllPoints()
			button:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width + offsetX, originY * height + offsetY)
			local iconAtlas = not action.customIcon and (action.customIconAtlas or entry.iconAtlas) or nil
			button.icon._eqolQuickActionsTexCoords = nil
			if not iconAtlas then
				button.icon:SetTexture(action.customIcon or icon or 134400)
				button.icon:SetTexCoord(0, 1, 0, 1)
			end
			button.icon:SetDesaturated(false)
			button._qaLabelText = action.customLabel or action.managedLabel or name or "?"
			button.label:SetText(QC:GetDisplayLabel(menu, button._qaLabelText))
			button.label:SetShown(QC:GetEffectiveShowLabel(menu, action))
			button.invalid:Hide()
			button.submenuMarker:SetShown(action.kind == "menu")
			button.highlight:Hide()
			button.sourceIndex = entry.sourceIndex
			button.action = action
			if action.kind == "macro" then
				visual.macroEntryCount = visual.macroEntryCount + 1
				visual.macroIndices[visual.macroEntryCount] = index
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			elseif action.kind == "item" then
				visual.itemEntryCount = visual.itemEntryCount + 1
				visual.itemIndices[visual.itemEntryCount] = index
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			elseif action.kind == "spell" then
				local mountID = _G.C_MountJournal
					and _G.C_MountJournal.GetMountFromSpell
					and _G.C_MountJournal.GetMountFromSpell(action.id)
				if mountID then
					visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
					visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
				else
					visual.spellUsabilityEntryCount = visual.spellUsabilityEntryCount + 1
					visual.spellUsabilityIndices[visual.spellUsabilityEntryCount] = index
				end
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			elseif action.kind == "mount" then
				visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
				visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			elseif action.kind == "eqol" and action.id ~= "hearthstone" then
				visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
				visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			elseif action.kind == "battlepet" or action.kind == "eqol" then
				visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
			end
			local cooldownSpellID
			if action.kind == "spell" then
				cooldownSpellID = action.id
			elseif action.kind == "mount" then
				cooldownSpellID = entry.resolvedValue
			elseif action.kind == "outfit" then
				cooldownSpellID = QC.TRANSMOG_OUTFIT_COOLDOWN_SPELL_ID
			end
			if cooldownSpellID
				and not (_G.issecretvalue and _G.issecretvalue(cooldownSpellID))
			then
				visual.spellCooldownEntryCount = visual.spellCooldownEntryCount + 1
				visual.spellCooldownIndices[visual.spellCooldownEntryCount] = index
				local spellIndices = visual.spellCooldownIndicesByID[cooldownSpellID]
				if not spellIndices then
					spellIndices = {}
					visual.spellCooldownIndicesByID[cooldownSpellID] = spellIndices
				end
				spellIndices[#spellIndices + 1] = index
			end
			button:EnableMouse(previewMode == true)
			QC:ApplyButtonAppearance(button, menu)
			if iconAtlas and button.icon.SetAtlas then button.icon:SetAtlas(iconAtlas, false) end
			updateUsability(button, action, true, entry.resolvedValue)
			updateCooldown(button, entry)
			button:Show()
		else
			local button = visual.buttons[index]
			if button then
				button.sourceIndex = nil
				button.action = nil
				button.submenuMarker:Hide()
				button:EnableMouse(false)
				button:Hide()
			end
		end
	end
	visual.cursorMarker:ClearAllPoints()
	visual.cursorMarker:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	visual.cursorMarker:SetShown(previewMode == true)
	visual.originAnchor:ClearAllPoints()
	visual.originAnchor:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	visual.selectionOriginAnchor:ClearAllPoints()
	visual.selectionOriginAnchor:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	QC:ConfigureDefaultIndicator(menu, entries, previewMode)
	QC:ApplyTitleAppearance(menu)
	QC:PositionTitle(menu, #entries)
	visual.resonance:ClearAllPoints()
	visual.resonance:SetPoint("CENTER", visual.originAnchor, "CENTER")
	local animatedOpen = QC.Animation:BeginOpen(#entries)
	visual:SetScript("OnUpdate", previewMode and animatedOpen and visual.onUpdate or not previewMode and visual.onUpdate or nil)
	if QC.SetVisualStateEventsEnabled then QC:SetVisualStateEventsEnabled(true) end
	if traceState.active then
		traceState.lastItemEntryCount = visual.itemEntryCount
		traceState.lastMacroEntryCount = visual.macroEntryCount
		traceState.lastMenuID = menu.id
		traceState.lastMode = previewMode and "preview" or "live"
		traceState.lastMountUsabilityEntryCount = visual.mountUsabilityEntryCount
		traceState.lastSpellCooldownEntryCount = visual.spellCooldownEntryCount
		traceState.lastSpellUsabilityEntryCount = visual.spellUsabilityEntryCount
	end
	visual:Show()
end

local function rebuildVisualDynamicIndices()
	_G.wipe(visual.itemIndices)
	_G.wipe(visual.macroIndices)
	_G.wipe(visual.mountUsabilityIndices)
	_G.wipe(visual.spellCooldownIndices)
	_G.wipe(visual.spellCooldownIndicesByID)
	_G.wipe(visual.spellUsabilityIndices)
	visual.dynamicUsabilityEntryCount = 0
	visual.itemEntryCount = 0
	visual.macroEntryCount = 0
	visual.mountUsabilityEntryCount = 0
	visual.spellCooldownEntryCount = 0
	visual.spellUsabilityEntryCount = 0
	for index, entry in ipairs(visual.entries or {}) do
		local action = entry.action
		if action.kind == "macro" then
			visual.macroEntryCount = visual.macroEntryCount + 1
			visual.macroIndices[visual.macroEntryCount] = index
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		elseif action.kind == "item" then
			visual.itemEntryCount = visual.itemEntryCount + 1
			visual.itemIndices[visual.itemEntryCount] = index
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		elseif action.kind == "spell" then
			local mountID = _G.C_MountJournal
				and _G.C_MountJournal.GetMountFromSpell
				and _G.C_MountJournal.GetMountFromSpell(action.id)
			if mountID then
				visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
				visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
			else
				visual.spellUsabilityEntryCount = visual.spellUsabilityEntryCount + 1
				visual.spellUsabilityIndices[visual.spellUsabilityEntryCount] = index
			end
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		elseif action.kind == "mount" then
			visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
			visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		elseif action.kind == "eqol" and action.id ~= "hearthstone" then
			visual.mountUsabilityEntryCount = visual.mountUsabilityEntryCount + 1
			visual.mountUsabilityIndices[visual.mountUsabilityEntryCount] = index
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		elseif action.kind == "battlepet" or action.kind == "eqol" then
			visual.dynamicUsabilityEntryCount = visual.dynamicUsabilityEntryCount + 1
		end
		local cooldownSpellID
		if action.kind == "spell" then
			cooldownSpellID = action.id
		elseif action.kind == "mount" then
			cooldownSpellID = entry.resolvedValue
		elseif action.kind == "outfit" then
			cooldownSpellID = QC.TRANSMOG_OUTFIT_COOLDOWN_SPELL_ID
		end
		if cooldownSpellID and not (_G.issecretvalue and _G.issecretvalue(cooldownSpellID)) then
			visual.spellCooldownEntryCount = visual.spellCooldownEntryCount + 1
			visual.spellCooldownIndices[visual.spellCooldownEntryCount] = index
			local spellIndices = visual.spellCooldownIndicesByID[cooldownSpellID]
			if not spellIndices then
				spellIndices = {}
				visual.spellCooldownIndicesByID[cooldownSpellID] = spellIndices
			end
			spellIndices[#spellIndices + 1] = index
		end
	end
	visual.macroElapsed = 0
	if QC.SetVisualStateEventsEnabled then QC:SetVisualStateEventsEnabled(true) end
end

local function rebuildVisualBreadcrumbs()
	_G.wipe(visual.breadcrumbIndices)
	for depth = 2, #(visual.levels or {}) do
		local level = visual.levels[depth]
		if level and level.parentGlobalIndex then visual.breadcrumbIndices[level.parentGlobalIndex] = true end
	end
end

local function configureInlineVisualButton(globalIndex, level, localIndex, entry)
	local menu = level.menu
	local action = entry.action
	local button = visual.buttons[globalIndex] or createVisualButton(visual)
	visual.buttons[globalIndex] = button
	QC.Animation:ResetButton(button)
	local offsetX, offsetY = QC:GetSlotOffset(menu, localIndex, #level.entries)
	local width, height = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	button:SetScale(1)
	button:SetSize(menu.iconSize, menu.iconSize)
	button.animatedVisual:SetSize(menu.iconSize, menu.iconSize)
	button:ClearAllPoints()
	button:SetPoint(
		"CENTER",
		_G.UIParent,
		"BOTTOMLEFT",
		visual.originX * width + level.originOffsetX + offsetX,
		visual.originY * height + level.originOffsetY + offsetY
	)
	local iconAtlas = not action.customIcon and (action.customIconAtlas or entry.iconAtlas) or nil
	button.icon._eqolQuickActionsTexCoords = nil
	if not iconAtlas then
		button.icon:SetTexture(action.customIcon or entry.icon or 134400)
		button.icon:SetTexCoord(0, 1, 0, 1)
	end
	button.icon:SetDesaturated(false)
	button._qaLabelText = action.customLabel or action.managedLabel or entry.name or "?"
	button.label:SetText(QC:GetDisplayLabel(menu, button._qaLabelText))
	button.label:SetShown(QC:GetEffectiveShowLabel(menu, action))
	button.invalid:Hide()
	button.submenuMarker:SetShown(action.kind == "menu")
	button.sourceIndex = entry.sourceIndex
	button.action = action
	button:EnableMouse(false)
	QC:ApplyButtonAppearance(button, menu)
	if iconAtlas and button.icon.SetAtlas then button.icon:SetAtlas(iconAtlas, false) end
	updateUsability(button, action, true, entry.resolvedValue)
	updateCooldown(button, entry)
	button:Show()
	visual.entries[globalIndex] = entry
	visual.entryMenus[globalIndex] = menu
end

local function setVisualActiveLevel(depth)
	local level = visual.levels[depth]
	if not level then return false end
	visual.activeDepth = depth
	visual.activeFirstIndex = level.firstIndex
	visual.activeLastIndex = level.lastIndex
	visual.activeOriginOffsetX = level.originOffsetX
	visual.activeOriginOffsetY = level.originOffsetY
	visual.menuID = level.menuID
	visual.menu = level.menu
	visual.selectedIndex = nil
	visual.wheelSelectedIndex = nil
	if visual.tooltipIndex then QC:HideActionTooltip(visual.buttons[visual.tooltipIndex]) end
	visual.tooltipIndex = nil
	visual.selectionOriginAnchor:ClearAllPoints()
	visual.selectionOriginAnchor:SetPoint(
		"CENTER",
		_G.UIParent,
		"BOTTOMLEFT",
		visual.originX * _G.UIParent:GetWidth() + level.originOffsetX,
		visual.originY * _G.UIParent:GetHeight() + level.originOffsetY
	)
	rebuildVisualBreadcrumbs()
	QC:UpdateDefaultIndicator(false)
	QC.Animation:SelectionChanged(nil)
	visual:SetScript("OnUpdate", visual.onUpdate)
	return true
end

function QC:ActivateInlineVisual(menuID, depth)
	menuID = tonumber(menuID)
	depth = tonumber(depth)
	local level = depth and visual.levels[depth] or nil
	if not (visual:IsShown() and not visual.previewMode and level and level.menuID == menuID) then return false end
	local firstRemovedIndex = level.lastIndex + 1
	for removeDepth = #visual.levels, depth + 1, -1 do
		local removedLevel = visual.levels[removeDepth]
		if removedLevel then firstRemovedIndex = math.min(firstRemovedIndex, removedLevel.firstIndex) end
		visual.levels[removeDepth] = nil
	end
	for index = #(visual.entries or {}), firstRemovedIndex, -1 do
		local button = visual.buttons[index]
		if button then
			self.Animation:ResetButton(button)
			button.sourceIndex = nil
			button.action = nil
			button.submenuMarker:Hide()
			button:EnableMouse(false)
			button:Hide()
		end
		visual.entries[index] = nil
		visual.entryMenus[index] = nil
	end
	setVisualActiveLevel(depth)
	rebuildVisualDynamicIndices()
	return true
end

function QC:ExpandInlineVisual(menuID, depth, originOffsetX, originOffsetY, parentMenuID, parentActionIndex)
	menuID = tonumber(menuID)
	depth = tonumber(depth)
	originOffsetX = tonumber(originOffsetX)
	originOffsetY = tonumber(originOffsetY)
	parentMenuID = tonumber(parentMenuID)
	parentActionIndex = tonumber(parentActionIndex)
	local parentDepth = depth and depth - 1 or nil
	local parentLevel = parentDepth and visual.levels[parentDepth] or nil
	local menu = menuID and self:GetMenu(menuID) or nil
	local entries = menuID and compiledEntries[menuID] or nil
	local menuAlreadyVisible = false
	if parentDepth then
		for previousDepth = 1, parentDepth do
			local previousLevel = visual.levels[previousDepth]
			if previousLevel and previousLevel.menuID == menuID then
				menuAlreadyVisible = true
				break
			end
		end
	end
	if
		not (visual:IsShown() and not visual.previewMode)
		or not (depth and depth > 1 and depth <= self.MAX_MENUS and originOffsetX and originOffsetY)
		or not (parentLevel and parentLevel.menuID == parentMenuID and parentActionIndex)
		or menuAlreadyVisible
		or not (menu and menu.enabled and entries and entries[1])
	then
		return false
	end
	self:ActivateInlineVisual(parentMenuID, parentDepth)
	local firstIndex = #(visual.entries or {}) + 1
	local level = {
		menuID = menuID,
		menu = menu,
		entries = entries,
		firstIndex = firstIndex,
		lastIndex = firstIndex + #entries - 1,
		originOffsetX = originOffsetX,
		originOffsetY = originOffsetY,
		parentGlobalIndex = parentLevel.firstIndex + parentActionIndex - 1,
	}
	visual.levels[depth] = level
	for localIndex, entry in ipairs(entries) do
		configureInlineVisualButton(firstIndex + localIndex - 1, level, localIndex, entry)
	end
	setVisualActiveLevel(depth)
	rebuildVisualDynamicIndices()
	return true
end

function QC:OpenVisual(menuID, originX, originY)
	local menu = self:GetMenu(menuID)
	local entries = menu and compiledEntries[menu.id]
	if not (menu and menu.enabled and entries and entries[1]) then return end
	renderVisual(menu, entries, originX, originY, false)
end

function QC:CloseVisual(reason, selectedIndex)
	local wasShown = visual:IsShown()
	if visual.animationPhase == "closing" then
		if reason == nil then self.Animation:FinalizeClose() end
		return
	end
	if wasShown and traceState.active then
		local counts = traceState.counts
		counts["visual.close"] = (counts["visual.close"] or 0) + 1
	end
	self:HideActionTooltip()
	visual.tooltipIndex = nil
	visual.cursorScreen = nil
	visual.cursorMarker:Hide()
	visual.defaultIndicator:Hide()
	visual.defaultIndicatorActive = nil
	if self.SetVisualStateEventsEnabled then self:SetVisualStateEventsEnabled(false) end
	local entryCount = type(visual.entries) == "table" and #visual.entries or 0
	if wasShown and reason ~= nil and self.Animation:BeginClose(reason, selectedIndex, entryCount) then
		visual:SetScript("OnUpdate", visual.onUpdate)
		return
	end
	self.Animation:FinalizeClose()
end

function QC:StartRuntimeTrace()
	_G.wipe(traceState.counts)
	_G.wipe(traceState.eventCounts)
	_G.wipe(traceState.lastRegisteredStateEvents)
	_G.wipe(traceState.spellEventCounts)
	for event in pairs(visual.registeredStateEvents) do traceState.lastRegisteredStateEvents[event] = true end
	traceState.lastItemEntryCount = nil
	traceState.lastMacroEntryCount = nil
	traceState.lastMenuID = nil
	traceState.lastMode = nil
	traceState.lastMountUsabilityEntryCount = nil
	traceState.lastSpellCooldownEntryCount = nil
	traceState.lastSpellUsabilityEntryCount = nil
	if visual:IsShown() then
		traceState.lastItemEntryCount = visual.itemEntryCount
		traceState.lastMacroEntryCount = visual.macroEntryCount
		traceState.lastMenuID = visual.menuID
		traceState.lastMode = visual.previewMode and "preview" or "live"
		traceState.lastMountUsabilityEntryCount = visual.mountUsabilityEntryCount
		traceState.lastSpellCooldownEntryCount = visual.spellCooldownEntryCount
		traceState.lastSpellUsabilityEntryCount = visual.spellUsabilityEntryCount
	end
	traceState.startedAt = (_G.GetTimePreciseSec or _G.GetTime)()
	traceState.stoppedAt = nil
	traceState.active = true
end

function QC:StopRuntimeTrace()
	if traceState.active then
		traceState.stoppedAt = (_G.GetTimePreciseSec or _G.GetTime)()
		traceState.active = false
	end
end

function QC:BuildRuntimeTraceReport()
	local now = traceState.stoppedAt or (_G.GetTimePreciseSec or _G.GetTime)()
	local startedAt = traceState.startedAt or now
	local lines = {
		"Enhance QoL QuickActions runtime trace",
		("durationSeconds=%.3f"):format(math.max(0, now - startedAt)),
		"traceActive=" .. tostring(traceState.active),
		"visualShown=" .. tostring(visual:IsShown()),
		"visualMode=" .. (visual.previewMode and "preview" or (visual:IsShown() and "live" or "closed")),
		"lastVisualMode=" .. tostring(traceState.lastMode),
		"lastMenuID=" .. tostring(traceState.lastMenuID),
		"lastEntries.items=" .. tostring(traceState.lastItemEntryCount or 0),
		"lastEntries.macros=" .. tostring(traceState.lastMacroEntryCount or 0),
		"lastEntries.mountUsability=" .. tostring(traceState.lastMountUsabilityEntryCount or 0),
		"lastEntries.spellCooldown=" .. tostring(traceState.lastSpellCooldownEntryCount or 0),
		"lastEntries.spellUsability=" .. tostring(traceState.lastSpellUsabilityEntryCount or 0),
		"",
		"[registered visual events observed]",
	}
	local keys = {}
	for event in pairs(traceState.lastRegisteredStateEvents) do keys[#keys + 1] = event end
	table.sort(keys)
	for index = 1, #keys do lines[#lines + 1] = keys[index] end
	if not keys[1] then lines[#lines + 1] = "(none)" end
	_G.wipe(keys)
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[received events]"
	for event in pairs(traceState.eventCounts) do keys[#keys + 1] = event end
	table.sort(keys)
	for index = 1, #keys do
		local event = keys[index]
		lines[#lines + 1] = event .. "=" .. tostring(traceState.eventCounts[event])
	end
	if not keys[1] then lines[#lines + 1] = "(none)" end
	_G.wipe(keys)
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[spell cooldown event IDs]"
	for spellID in pairs(traceState.spellEventCounts) do keys[#keys + 1] = spellID end
	table.sort(keys)
	for index = 1, #keys do
		local spellID = keys[index]
		local label = spellID == 0 and "ALL" or tostring(spellID)
		lines[#lines + 1] = label .. "=" .. tostring(traceState.spellEventCounts[spellID])
	end
	if not keys[1] then lines[#lines + 1] = "(none)" end
	_G.wipe(keys)
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[runtime counters]"
	for key in pairs(traceState.counts) do keys[#keys + 1] = key end
	table.sort(keys)
	for index = 1, #keys do
		local key = keys[index]
		lines[#lines + 1] = key .. "=" .. tostring(traceState.counts[key])
	end
	if not keys[1] then lines[#lines + 1] = "(none)" end
	return table.concat(lines, "\n"), #lines
end

function QC:ShowRuntimeTraceReport()
	local report, lineCount = self:BuildRuntimeTraceReport()
	local frame = _G.EQOLQuickActionsTraceFrame
	if not frame then
		frame = _G.CreateFrame("Frame", "EQOLQuickActionsTraceFrame", _G.UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(760, 540)
		frame:SetPoint("CENTER")
		frame:SetFrameStrata("DIALOG")
		frame:SetToplevel(true)
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		if frame.TitleText then frame.TitleText:SetText(L["QuickCast"] or "QuickActions") end
		frame.scroll = _G.CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		frame.scroll:SetPoint("TOPLEFT", 16, -34)
		frame.scroll:SetPoint("BOTTOMRIGHT", -34, 16)
		frame.editBox = _G.CreateFrame("EditBox", nil, frame.scroll)
		frame.editBox:SetMultiLine(true)
		frame.editBox:SetAutoFocus(false)
		frame.editBox:SetFontObject(_G.ChatFontNormal or _G.GameFontHighlightSmall)
		frame.editBox:SetTextColor(1, 1, 1, 1)
		frame.editBox:SetWidth(690)
		frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		frame.scroll:SetScrollChild(frame.editBox)
	end
	frame.editBox:SetHeight(math.max(480, lineCount * 15))
	frame.editBox:SetText(report)
	frame:Show()
	frame:Raise()
	frame.editBox:SetFocus()
	frame.editBox:HighlightText()
end

function QC:ToggleRuntimeTrace()
	if traceState.active then
		self:StopRuntimeTrace()
		self:ShowRuntimeTraceReport()
		return false
	end
	self:StartRuntimeTrace()
	if _G.DEFAULT_CHAT_FRAME then _G.DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99EQA trace: START|r") end
	return true
end

local function getPreviewOrigin(menu, entryCount)
	local width, height = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	if not width or not height or width <= 0 or height <= 0 then return 0.5, 0.5 end
	local minimumX, maximumX, minimumY, maximumY = 0, 0, 0, 0
	local padding = (menu.iconSize or QC.DEFAULT_ICON_SIZE) / 2 + 18
	for index = 1, entryCount do
		local x, y = QC:GetSlotOffset(menu, index, entryCount)
		minimumX, maximumX = math.min(minimumX, x - padding), math.max(maximumX, x + padding)
		minimumY, maximumY = math.min(minimumY, y - padding), math.max(maximumY, y + padding)
	end
	local targetX, targetY = width * 0.68, height * 0.5
	local margin = 24
	local minimumOriginX = margin - minimumX
	local maximumOriginX = width - margin - maximumX
	local minimumOriginY = margin - minimumY
	local maximumOriginY = height - margin - maximumY
	if minimumOriginX <= maximumOriginX then targetX = clamp(targetX, minimumOriginX, maximumOriginX) end
	if minimumOriginY <= maximumOriginY then targetY = clamp(targetY, minimumOriginY, maximumOriginY) end
	return targetX / width, targetY / height
end

function QC:ShowLayoutPreview(menuID)
	if _G.InCombatLockdown() then return false end
	local menu = self:GetMenu(menuID)
	if not menu then return false end
	self:RebuildSecureState()
	local previewSpecID = self.Editor and self.Editor.GetPreviewSpecID and self.Editor:GetPreviewSpecID() or nil
	local previewSpecIDs = self.Editor and self.Editor.GetPreviewSpecIDs and self.Editor:GetPreviewSpecIDs() or nil
	local entries = self:GetActiveActions(menu, previewSpecID, previewSpecIDs)
	local originX, originY = getPreviewOrigin(menu, #entries)
	renderVisual(menu, entries, originX, originY, true)
	return true
end

function QC:HideLayoutPreview()
	if visual.previewMode then self:CloseVisual() end
end

function QC:RefreshLayoutPreview()
	if not visual.previewMode then return end
	local menu = visual.menuID and self:GetMenu(visual.menuID)
	if not menu then
		self:HideLayoutPreview()
		return
	end
	local previewSpecID = self.Editor and self.Editor.GetPreviewSpecID and self.Editor:GetPreviewSpecID() or nil
	local previewSpecIDs = self.Editor and self.Editor.GetPreviewSpecIDs and self.Editor:GetPreviewSpecIDs() or nil
	local entries = self:GetActiveActions(menu, previewSpecID, previewSpecIDs)
	local originX, originY = getPreviewOrigin(menu, #entries)
	renderVisual(menu, entries, originX, originY, true)
end

function QC:RefreshVisibleMenuLayout(menuID, applyAppearance)
	menuID = tonumber(menuID)
	if not (menuID and visual:IsShown() and visual.rootMenuID == menuID) then return false end
	if not visual.previewMode and visual.activeDepth ~= 1 then return false end
	local menu = self:GetMenu(menuID)
	if not menu then return false end
	local rootLevel = visual.levels[1]
	local entries = rootLevel and rootLevel.entries or {}
	local originX, originY = visual.originX, visual.originY
	if visual.previewMode then originX, originY = getPreviewOrigin(menu, #entries) end
	if type(originX) ~= "number" or type(originY) ~= "number" then return false end
	visual.originX, visual.originY = originX, originY
	local width, height = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	visual.maxEntryDistance = 0
	for index = 1, #entries do
		local button = visual.buttons[index]
		if button then
			local action = entries[index].action
			local offsetX, offsetY = self:GetSlotOffset(menu, index, #entries)
			visual.maxEntryDistance = math.max(visual.maxEntryDistance, math.sqrt(offsetX * offsetX + offsetY * offsetY))
			button:SetSize(menu.iconSize, menu.iconSize)
			button.animatedVisual:SetSize(menu.iconSize, menu.iconSize)
			button:ClearAllPoints()
			button:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width + offsetX, originY * height + offsetY)
			button.label:SetShown(self:GetEffectiveShowLabel(menu, action))
			if applyAppearance then self:ApplyButtonAppearance(button, menu) end
		end
	end
	visual.cursorMarker:ClearAllPoints()
	visual.cursorMarker:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	visual.originAnchor:ClearAllPoints()
	visual.originAnchor:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	visual.selectionOriginAnchor:ClearAllPoints()
	visual.selectionOriginAnchor:SetPoint("CENTER", _G.UIParent, "BOTTOMLEFT", originX * width, originY * height)
	self:ApplyTitleAppearance(menu)
	self:PositionTitle(menu, #entries)
	visual.selectionAnimationSettled = false
	return true
end

function QC:RefreshVisibleMenuAppearance(menuID)
	return self:RefreshVisibleMenuLayout(menuID, true)
end

function QC:RefreshGlobalFont()
	local rootMenu = visual:IsShown() and visual.rootMenu or nil
	if rootMenu then
		for index, entry in ipairs(visual.entries or {}) do
			local button = visual.buttons[index]
			local menu = visual.entryMenus[index]
			if button and button:IsShown() and entry and menu then self:ApplyButtonAppearance(button, menu) end
		end
		self:ApplyTitleAppearance(rootMenu)
	end
	local editor = self.Editor
	if editor and editor.IsOpen and editor:IsOpen() and editor.Refresh then editor:Refresh() end
end

local function getCursorDeltaFromOrigin()
	local screen = visual.cursorScreen
	local left, bottom = visual.cursorLeft, visual.cursorBottom
	local width, height = visual.cursorWidth, visual.cursorHeight
	if not (screen and left and bottom and width and height) or width == 0 or height == 0 then return nil, nil end
	local cursorX, cursorY
	if _G.GetScaledCursorPositionForFrame then
		cursorX, cursorY = _G.GetScaledCursorPositionForFrame(screen)
	else
		cursorX, cursorY = _G.GetCursorPosition()
		local scale = visual.cursorScale
		if not scale or scale == 0 then return nil, nil end
		cursorX, cursorY = cursorX / scale, cursorY / scale
	end
	if not (cursorX and cursorY) then return nil, nil end
	cursorX = cursorX - left
	cursorY = cursorY - bottom
	if cursorX < 0 or cursorX > width or cursorY < 0 or cursorY > height then return nil, nil end
	return cursorX - visual.cursorOriginX, cursorY - visual.cursorOriginY
end

visual.onUpdate = function(self, elapsed)
	if traceState.active then
		local counts = traceState.counts
		counts["visual.onUpdate.calls"] = (counts["visual.onUpdate.calls"] or 0) + 1
	end
	local now = _G.GetTime()
	if self.animationPhase == "closing" then
		if QC.Animation:UpdateClose(now) then QC.Animation:FinalizeClose() end
		return
	end
	local menu = self.menu
	if not menu then
		QC:CloseVisual()
		return
	end
	local entries = self.entries or {}
	if self.previewMode then
		QC.Animation:UpdateActive(now, elapsed, #entries)
		if self.animationPhase == "active" then self:SetScript("OnUpdate", nil) end
		return
	end

	local deltaX, deltaY = getCursorDeltaFromOrigin()
	local activeLevel = self.levels[self.activeDepth or 1]
	if not activeLevel then
		QC:CloseVisual()
		return
	end
	if deltaX and deltaY then
		deltaX = deltaX - (activeLevel.originOffsetX or 0)
		deltaY = deltaY - (activeLevel.originOffsetY or 0)
	end
	local selectionDeadZone = QC.SELECTION_DEAD_ZONE or QC.DEAD_ZONE
	local defaultActive = self.activeDepth == 1
		and deltaX
		and deltaY
		and deltaX * deltaX + deltaY * deltaY <= selectionDeadZone * selectionDeadZone
		or false
	QC:UpdateDefaultIndicator(defaultActive)
	local selectedLocal = tonumber(self.wheelSelectedIndex)
	if not selectedLocal then
		selectedLocal = deltaX and deltaY and QC:GetSelectedIndex(menu, deltaX, deltaY, #activeLevel.entries) or nil
	end
	local selected = selectedLocal and activeLevel.firstIndex + selectedLocal - 1 or nil
	if selected ~= self.selectedIndex then
		if traceState.active then
			local counts = traceState.counts
			counts["visual.selectionChanges"] = (counts["visual.selectionChanges"] or 0) + 1
		end
		if self.tooltipIndex and (self.tooltipIndex ~= selected or menu.showTooltips == false) then
			QC:HideActionTooltip(self.buttons[self.tooltipIndex])
			self.tooltipIndex = nil
		end
		if selected and menu.showTooltips ~= false and self.tooltipIndex ~= selected then
			local button = self.buttons[selected]
			local entry = entries[selected]
			if button and entry and QC:ShowActionTooltip(button, entry.action, menu) then self.tooltipIndex = selected end
		end
		self.selectedIndex = selected
		QC.Animation:SelectionChanged(selected)
		if self.animationStyle == QC.ANIMATION_STYLE_NONE then
			for index = 1, #entries do
				local button = self.buttons[index]
				if button then button.highlight:SetShown(index == selected) end
			end
		end
	end
	QC.Animation:UpdateActive(now, elapsed, #entries)
	if self.macroEntryCount > 0 then
		self.macroElapsed = self.macroElapsed + elapsed
		if self.macroElapsed >= 0.1 then
			self.macroElapsed = 0
			if traceState.active then
				local counts = traceState.counts
				counts["macro.polls"] = (counts["macro.polls"] or 0) + 1
				counts["macro.entries"] = (counts["macro.entries"] or 0) + self.macroEntryCount
			end
			for macroIndex = 1, self.macroEntryCount do
					local entryIndex = self.macroIndices[macroIndex]
					local button = self.buttons[entryIndex]
					local entry = entries[entryIndex]
					if button and entry then
						updateUsability(button, entry.action, true, entry.resolvedValue)
						updateCooldown(button, entry)
					end
				end
			end
		end
end

local bindingOwner = _G.CreateFrame("Frame", "EQOLQuickCastBindingOwner", _G.UIParent, "SecureFrameTemplate")
local secureButton = _G.CreateFrame("Button", SECURE_BUTTON_NAME, _G.UIParent, "SecureActionButtonTemplate,SecureHandlerAttributeTemplate")
secureButton:RegisterForClicks("AnyDown", "AnyUp")
secureButton:SetAttribute("pressAndHoldAction", 1)
secureButton:Hide()

QC.secureHoverFrames = QC.secureHoverFrames or {}
QC.secureWheelFrame = QC.secureWheelFrame
	or _G.CreateFrame("Frame", "EQOLQuickActionsWheelInput", _G.UIParent, "SecureHandlerMouseWheelTemplate")
QC.secureWheelFrame:SetAllPoints(_G.UIParent)
QC.secureWheelFrame:SetFrameStrata("FULLSCREEN_DIALOG")
QC.secureWheelFrame:EnableMouse(true)
if QC.secureWheelFrame.SetPropagateMouseClicks then QC.secureWheelFrame:SetPropagateMouseClicks(true) end
if QC.secureWheelFrame.SetPassThroughButtons then QC.secureWheelFrame:SetPassThroughButtons("LeftButton", "RightButton") end
QC.secureWheelFrame:SetFrameRef("qc-controller", secureButton)
QC.secureWheelFrame:SetAttribute("_onmousewheel", [=[
	local controller = self:GetFrameRef("qc-controller")
	if controller then controller:RunAttribute("qc-wheel", delta) end
]=])
QC.secureWheelFrame:Hide()
secureButton:SetFrameRef("qc-wheel", QC.secureWheelFrame)

secureButton:SetAttribute("qc-wheel", [=[
	local offset = tonumber(...)
	local menuID = tonumber(self:GetAttribute("qc-nav-menu"))
	if not offset or not menuID or not self:GetAttribute("qc-active") then return end
	local count = tonumber(self:GetAttribute("qc-menu-" .. menuID .. "-count")) or 0
	if count < 1 then return end
	local selected = tonumber(self:GetAttribute("qc-wheel-index"))
	if not selected then selected = offset > 0 and 1 or 0 end
	if offset > 0 then
		selected = selected - 1
		if selected < 1 then selected = count end
	else
		selected = selected + 1
		if selected > count then selected = 1 end
	end
	self:SetAttribute("qc-wheel-index", selected)
	self:CallMethod("NotifyQuickCast", "wheel", menuID, selected)
]=])

secureButton:SetAttribute("qc-truncate-ring", [=[
	local keepDepth = tonumber(...) or 0
	local currentDepth = tonumber(self:GetAttribute("qc-path-depth")) or 0
	if keepDepth < 0 then keepDepth = 0 end
	if keepDepth > currentDepth then keepDepth = currentDepth end
	for depth = currentDepth, keepDepth + 1, -1 do
		local menuID = tonumber(self:GetAttribute("qc-path-menu-" .. depth))
		if menuID then
			local count = tonumber(self:GetAttribute("qc-menu-" .. menuID .. "-count")) or 0
			for actionIndex = 1, count do
				local frame = self:GetFrameRef("qc-hover-" .. menuID .. "-" .. actionIndex)
				if frame then frame:Hide() end
			end
		end
		self:SetAttribute("qc-path-menu-" .. depth, nil)
		self:SetAttribute("qc-path-offset-x-" .. depth, nil)
		self:SetAttribute("qc-path-offset-y-" .. depth, nil)
	end
	self:SetAttribute("qc-path-depth", keepDepth > 0 and keepDepth or nil)
	local menuID = keepDepth > 0 and tonumber(self:GetAttribute("qc-path-menu-" .. keepDepth)) or nil
	self:SetAttribute("qc-nav-menu", menuID)
	self:SetAttribute("qc-wheel-index", nil)
]=])

secureButton:SetAttribute("qc-activate-ring", [=[
	local depth = tonumber(...)
	if not depth or depth < 1 or depth > (tonumber(self:GetAttribute("qc-path-depth")) or 0) then return end
	local menuID = tonumber(self:GetAttribute("qc-path-menu-" .. depth))
	if not menuID then return end
	self:RunAttribute("qc-truncate-ring", depth)
	local offsetX = tonumber(self:GetAttribute("qc-path-offset-x-" .. depth)) or 0
	local offsetY = tonumber(self:GetAttribute("qc-path-offset-y-" .. depth)) or 0
	self:CallMethod("NotifyQuickCast", "activate", menuID, depth, offsetX, offsetY)
]=])

secureButton:SetAttribute("qc-open-ring", [=[
	local menuID, notify, depth, parentMenuID, parentActionIndex = ...
	menuID = tonumber(menuID)
	depth = tonumber(depth) or 1
	parentMenuID = tonumber(parentMenuID)
	parentActionIndex = tonumber(parentActionIndex)
	local maximumDepth = tonumber(self:GetAttribute("qc-max-depth")) or 16
	if not menuID or depth < 1 or depth > maximumDepth or not self:GetAttribute("qc-active") then return end
	local count = tonumber(self:GetAttribute("qc-menu-" .. menuID .. "-count")) or 0
	if count < 1 then return end
	local originOffsetX, originOffsetY = 0, 0
	if depth > 1 then
		local parentDepth = depth - 1
		if
			not parentMenuID
			or not parentActionIndex
			or parentMenuID ~= tonumber(self:GetAttribute("qc-path-menu-" .. parentDepth))
		then
			return
		end
		local parentPrefix = "qc-action-" .. parentMenuID .. "-" .. parentActionIndex .. "-"
		local parentActionX = tonumber(self:GetAttribute(parentPrefix .. "x"))
		local parentActionY = tonumber(self:GetAttribute(parentPrefix .. "y"))
		if not parentActionX or not parentActionY then return end
		originOffsetX = (tonumber(self:GetAttribute("qc-path-offset-x-" .. parentDepth)) or 0) + parentActionX
		originOffsetY = (tonumber(self:GetAttribute("qc-path-offset-y-" .. parentDepth)) or 0) + parentActionY
		for pathDepth = 1, parentDepth do
			if tonumber(self:GetAttribute("qc-path-menu-" .. pathDepth)) == menuID then return end
		end
	end
	self:RunAttribute("qc-truncate-ring", depth - 1)
	local screen = self:GetParent()
	local originX = tonumber(self:GetAttribute("qc-origin-x"))
	local originY = tonumber(self:GetAttribute("qc-origin-y"))
	if not screen or not originX or not originY then return end
	local width = screen:GetWidth()
	local height = screen:GetHeight()
	local size = tonumber(self:GetAttribute("qc-menu-" .. menuID .. "-size")) or 44
	self:SetAttribute("qc-path-depth", depth)
	self:SetAttribute("qc-path-menu-" .. depth, menuID)
	self:SetAttribute("qc-path-offset-x-" .. depth, originOffsetX)
	self:SetAttribute("qc-path-offset-y-" .. depth, originOffsetY)
	self:SetAttribute("qc-nav-menu", menuID)
	self:SetAttribute("qc-wheel-index", nil)
	for actionIndex = 1, count do
		local frame = self:GetFrameRef("qc-hover-" .. menuID .. "-" .. actionIndex)
		local prefix = "qc-action-" .. menuID .. "-" .. actionIndex .. "-"
		local actionX = tonumber(self:GetAttribute(prefix .. "x"))
		local actionY = tonumber(self:GetAttribute(prefix .. "y"))
		if frame and actionX and actionY then
			frame:ClearAllPoints()
			frame:SetPoint(
				"CENTER",
				screen,
				"BOTTOMLEFT",
				originX * width + originOffsetX + actionX,
				originY * height + originOffsetY + actionY
			)
			frame:SetWidth(size)
			frame:SetHeight(size)
			frame:SetFrameLevel(depth)
			frame:SetAttribute("qc-depth", depth)
			frame:Show()
		end
	end
	local wheel = self:GetFrameRef("qc-wheel")
	if wheel then wheel:Show() end
	if notify then
		self:CallMethod(
			"NotifyQuickCast",
			"expand",
			menuID,
			depth,
			originOffsetX,
			originOffsetY,
			parentMenuID,
			parentActionIndex
		)
	end
]=])

secureButton:SetAttribute("qc-close-ring", [=[
	self:RunAttribute("qc-truncate-ring", 0)
	local wheel = self:GetFrameRef("qc-wheel")
	if wheel then wheel:Hide() end
]=])

function QC:EnsureSecureHoverFrame(menuID, actionIndex)
	menuID = tonumber(menuID)
	actionIndex = tonumber(actionIndex)
	if not (menuID and actionIndex) then return nil end
	local key = tostring(menuID) .. ":" .. tostring(actionIndex)
	local frame = self.secureHoverFrames[key]
	if not frame then
		frame = _G.CreateFrame(
			"Frame",
			"EQOLQuickActionsHover" .. tostring(menuID) .. "_" .. tostring(actionIndex),
			_G.UIParent,
			"SecureHandlerEnterLeaveTemplate,SecureHandlerMouseWheelTemplate"
		)
		frame:SetFrameStrata("TOOLTIP")
		frame:EnableMouse(true)
		if frame.SetPropagateMouseClicks then frame:SetPropagateMouseClicks(true) end
		if frame.SetPassThroughButtons then frame:SetPassThroughButtons("LeftButton", "RightButton") end
		frame:SetFrameRef("qc-controller", secureButton)
		frame:SetAttribute("_onenter", [=[
			local controller = self:GetFrameRef("qc-controller")
			if not controller then return end
			local menuID = tonumber(self:GetAttribute("qc-menu-id"))
			local depth = tonumber(self:GetAttribute("qc-depth"))
			local actionIndex = tonumber(self:GetAttribute("qc-action-index"))
			if not menuID or not depth or not actionIndex then return end
			if menuID ~= tonumber(controller:GetAttribute("qc-path-menu-" .. depth)) then return end
			local childMenuID = tonumber(self:GetAttribute("qc-submenu-id"))
			if childMenuID then
				local childDepth = depth + 1
				local currentDepth = tonumber(controller:GetAttribute("qc-path-depth")) or 0
				if childMenuID == tonumber(controller:GetAttribute("qc-path-menu-" .. childDepth)) then
					if currentDepth > childDepth then controller:RunAttribute("qc-activate-ring", childDepth) end
				else
					controller:RunAttribute("qc-activate-ring", depth)
					controller:RunAttribute("qc-open-ring", childMenuID, true, childDepth, menuID, actionIndex)
				end
			else
				controller:RunAttribute("qc-activate-ring", depth)
			end
		]=])
		frame:SetAttribute("_onmousewheel", [=[
			local controller = self:GetFrameRef("qc-controller")
			if controller then controller:RunAttribute("qc-wheel", delta) end
		]=])
		frame:Hide()
		self.secureHoverFrames[key] = frame
	end
	frame:SetAttribute("qc-menu-id", menuID)
	frame:SetAttribute("qc-action-index", actionIndex)
	secureButton:SetFrameRef("qc-hover-" .. menuID .. "-" .. actionIndex, frame)
	return frame
end

function secureButton:NotifyQuickCast(state, menuID, valueA, valueB, valueC, valueD, valueE)
	if state == "open" then
		menuID = tonumber(menuID)
		local originX, originY = valueA, valueB
		if not _G.InCombatLockdown() then QC:RefreshSecureMenuTree(menuID) end
		heldMenuID = menuID
		QC:OpenVisual(heldMenuID, originX, originY)
	elseif state == "activate" then
		QC:ActivateInlineVisual(menuID, valueA)
	elseif state == "expand" then
		QC:ExpandInlineVisual(menuID, valueA, valueB, valueC, valueD, valueE)
	elseif state == "wheel" then
		menuID = tonumber(menuID)
		if visual:IsShown() and visual.menuID == menuID then
			visual.wheelSelectedIndex = tonumber(valueA)
			visual.selectionAnimationSettled = false
		end
	else
		heldMenuID = nil
		local selectedIndex
		if state == "confirm" then
			local localIndex = tonumber(valueA)
			local activeLevel = visual.levels[visual.activeDepth or 1]
			if localIndex and activeLevel and activeLevel.menuID == tonumber(menuID) then
				selectedIndex = activeLevel.firstIndex + localIndex - 1
			end
		end
		local closeReason = selectedIndex and selectedIndex >= 1 and "confirm" or "cancel"
		if closeReason == "cancel" then selectedIndex = nil end
		QC:CloseVisual(closeReason, selectedIndex)
		local hasPendingLayout = QC.pendingSecureLayoutRefreshes and next(QC.pendingSecureLayoutRefreshes) ~= nil
		if (rebuildPending or hasPendingLayout) and not _G.InCombatLockdown() and _G.C_Timer and _G.C_Timer.After then
			_G.C_Timer.After(0, function()
				if rebuildPending and not heldMenuID and not _G.InCombatLockdown() then
					QC:RebuildSecureState()
				elseif QC.pendingSecureLayoutRefreshes and not heldMenuID and not _G.InCombatLockdown() then
					local pending = QC.pendingSecureLayoutRefreshes
					QC.pendingSecureLayoutRefreshes = nil
					for pendingMenuID in pairs(pending) do
						QC:QueueSecureLayoutRefresh(pendingMenuID)
					end
				end
			end)
		end
	end
end

secureButton:WrapScript(secureButton, "OnClick", [=[
	if button == "cancel" then
		self:ClearBindings()
		self:RunAttribute("qc-close-ring")
		self:SetAttribute("qc-active", nil)
		self:SetAttribute("qc-toggle-state", nil)
		self:SetAttribute("qc-macro-toggle", nil)
		self:SetAttribute("qc-origin-x", nil)
		self:SetAttribute("qc-origin-y", nil)
		self:SetAttribute("type", nil)
		self:SetAttribute("typerelease", nil)
		self:SetAttribute("spell", nil)
		self:SetAttribute("item", nil)
		self:SetAttribute("macro", nil)
		self:SetAttribute("macrotext", nil)
		self:SetAttribute("clickbutton", nil)
		self:SetAttribute("marker", nil)
		self:SetAttribute("action", nil)
		self:SetAttribute("unit", nil)
		self:SetAttribute("equipmentset", nil)
		self:CallMethod("NotifyQuickCast", "cancel")
		return
	end
	local screen = self:GetParent()
	local menuID = tonumber(button)
	local macroToggle = menuID and menuID < 0
	if macroToggle then menuID = -menuID end
	local activationMode = self:GetAttribute("qc-activation-mode") or "HOLD"
	local activeMenuID = tonumber(self:GetAttribute("qc-active"))
	if macroToggle then
		if down then return false end
		self:SetAttribute("qc-macro-toggle", 1)
		if not activeMenuID then
			down = true
		elseif menuID == activeMenuID and self:GetAttribute("qc-toggle-state") == "armed" then
			self:SetAttribute("qc-toggle-state", "closing")
		end
	end
	local toggleMode = activationMode == "TOGGLE" or self:GetAttribute("qc-macro-toggle")
	if button == "confirm" then
		if down then return false end
		if not toggleMode or not activeMenuID or self:GetAttribute("qc-toggle-state") ~= "armed" then return end
		menuID = activeMenuID
		self:SetAttribute("qc-toggle-state", "closing")
	elseif down then
		self:SetAttribute("type", nil)
		self:SetAttribute("typerelease", nil)
		self:SetAttribute("spell", nil)
		self:SetAttribute("item", nil)
		self:SetAttribute("macro", nil)
		self:SetAttribute("macrotext", nil)
		self:SetAttribute("clickbutton", nil)
		self:SetAttribute("marker", nil)
		self:SetAttribute("action", nil)
		self:SetAttribute("unit", nil)
		self:SetAttribute("equipmentset", nil)
		if not menuID then return end
		if toggleMode and activeMenuID then
			if menuID == activeMenuID and self:GetAttribute("qc-toggle-state") == "armed" then
				self:SetAttribute("qc-toggle-state", "closing")
			end
			return
		end
		local x, y = 0.5, 0.5
		if self:GetAttribute("qc-menu-" .. menuID .. "-show-at-cursor") then
			x, y = screen:GetMousePosition()
			if not x or not y then
				self:SetAttribute("qc-active", nil)
				self:SetAttribute("qc-toggle-state", nil)
				self:SetAttribute("qc-macro-toggle", nil)
				return
			end
		end
		self:ClearBindings()
		self:RunAttribute("qc-truncate-ring", 0)
		self:SetAttribute("qc-active", menuID)
		self:SetAttribute("qc-origin-x", x)
		self:SetAttribute("qc-origin-y", y)
		self:SetAttribute("qc-toggle-state", macroToggle and "armed" or toggleMode and "opening" or nil)
		self:SetAttribute("qc-nav-menu", nil)
		self:SetAttribute("qc-wheel-index", nil)
		local hotkey = self:GetAttribute("qc-menu-" .. menuID .. "-hotkey")
		self:SetBindingClick(true, "ESCAPE", self, "cancel")
		if hotkey ~= "BUTTON2" then self:SetBindingClick(true, "BUTTON2", self, "cancel") end
		if toggleMode and hotkey ~= "BUTTON1" then self:SetBindingClick(true, "BUTTON1", self, "confirm") end
		self:CallMethod("NotifyQuickCast", "open", menuID, x, y)
		local count = self:GetAttribute("qc-menu-" .. menuID .. "-count") or 0
		if count <= 0 then
			self:ClearBindings()
			self:RunAttribute("qc-close-ring")
			self:SetAttribute("qc-active", nil)
			self:SetAttribute("qc-toggle-state", nil)
			self:SetAttribute("qc-macro-toggle", nil)
			self:SetAttribute("qc-origin-x", nil)
			self:SetAttribute("qc-origin-y", nil)
			self:CallMethod("NotifyQuickCast", "cancel", menuID)
			return false
		end
		self:RunAttribute("qc-open-ring", menuID, false, 1)
		return
	end

	if not menuID or menuID ~= self:GetAttribute("qc-active") then return end
	if toggleMode then
		local toggleState = self:GetAttribute("qc-toggle-state")
		if toggleState == "opening" then
			self:SetAttribute("qc-toggle-state", "armed")
			return false
		end
		if toggleState ~= "closing" then return end
	end
	self:ClearBindings()
	local depth = tonumber(self:GetAttribute("qc-path-depth")) or 1
	menuID = tonumber(self:GetAttribute("qc-path-menu-" .. depth)) or tonumber(self:GetAttribute("qc-nav-menu")) or menuID
	local count = self:GetAttribute("qc-menu-" .. menuID .. "-count") or 0
	local layout = self:GetAttribute("qc-menu-" .. menuID .. "-layout")
	local size = self:GetAttribute("qc-menu-" .. menuID .. "-size") or 44
	local deadZone = self:GetAttribute("qc-dead-zone") or 50
	local offsetX = self:GetAttribute("qc-menu-" .. menuID .. "-offset-x") or 0
	local offsetY = self:GetAttribute("qc-menu-" .. menuID .. "-offset-y") or 0
	local originX, originY = self:GetAttribute("qc-origin-x"), self:GetAttribute("qc-origin-y")
	local cursorX, cursorY = screen:GetMousePosition()
	if not originX or not originY or not cursorX or not cursorY then
		self:RunAttribute("qc-close-ring")
		self:SetAttribute("qc-active", nil)
		self:SetAttribute("qc-toggle-state", nil)
		self:SetAttribute("qc-macro-toggle", nil)
		self:SetAttribute("qc-origin-x", nil)
		self:SetAttribute("qc-origin-y", nil)
		self:CallMethod("NotifyQuickCast", "cancel", menuID)
		return
	end
	local deltaX = (cursorX - originX) * screen:GetWidth()
	local deltaY = (cursorY - originY) * screen:GetHeight()
	deltaX = deltaX - (tonumber(self:GetAttribute("qc-path-offset-x-" .. depth)) or 0)
	deltaY = deltaY - (tonumber(self:GetAttribute("qc-path-offset-y-" .. depth)) or 0)
	local originDistanceSquared = deltaX * deltaX + deltaY * deltaY
	local selected = tonumber(self:GetAttribute("qc-wheel-index"))

	if not selected and originDistanceSquared > deadZone * deadZone and (layout == "horizontal" or layout == "vertical") then
		local halfSize = size / 2
		for actionIndex = 1, count do
			local prefix = "qc-action-" .. menuID .. "-" .. actionIndex .. "-"
			local actionX = self:GetAttribute(prefix .. "x")
			local actionY = self:GetAttribute(prefix .. "y")
			if actionX and actionY
				and math.abs(deltaX - actionX) <= halfSize
				and math.abs(deltaY - actionY) <= halfSize
			then
				selected = actionIndex
				break
			end
		end
	elseif not selected and originDistanceSquared > deadZone * deadZone then
		local relativeX = deltaX - offsetX
		local relativeY = deltaY - offsetY
		if count > 0 then
			local segment = 360 / count
			local angle = (math.deg(math.atan2(relativeX, relativeY)) + segment / 2) % 360
			selected = math.floor(angle / segment) + 1
		end
	end
	if depth == 1 and not selected and originDistanceSquared <= deadZone * deadZone then
		selected = tonumber(self:GetAttribute("qc-menu-" .. menuID .. "-default-index"))
	end

	self:SetAttribute("type", nil)
	self:SetAttribute("typerelease", nil)
	self:SetAttribute("spell", nil)
	self:SetAttribute("item", nil)
	self:SetAttribute("macro", nil)
	self:SetAttribute("macrotext", nil)
	self:SetAttribute("clickbutton", nil)
	self:SetAttribute("marker", nil)
	self:SetAttribute("action", nil)
	self:SetAttribute("unit", nil)
	self:SetAttribute("equipmentset", nil)
	local selectedButton
	local submenuID = selected and tonumber(self:GetAttribute("qc-action-" .. menuID .. "-" .. selected .. "-submenu-id"))
	self:RunAttribute("qc-close-ring")
	if selected and not submenuID then
		selectedButton = "qc-" .. menuID .. "-" .. selected
		self:CallMethod("NotifyQuickCast", "confirm", menuID, selected)
	else
		self:CallMethod("NotifyQuickCast", "cancel", menuID)
	end
	return selectedButton, true
]=], [=[
	self:SetAttribute("type", nil)
	self:SetAttribute("typerelease", nil)
	self:SetAttribute("spell", nil)
	self:SetAttribute("item", nil)
	self:SetAttribute("macro", nil)
	self:SetAttribute("macrotext", nil)
	self:SetAttribute("clickbutton", nil)
	self:SetAttribute("marker", nil)
	self:SetAttribute("action", nil)
	self:SetAttribute("unit", nil)
	self:SetAttribute("equipmentset", nil)
	self:SetAttribute("qc-toggle-state", nil)
	self:SetAttribute("qc-macro-toggle", nil)
	self:SetAttribute("qc-origin-x", nil)
	self:SetAttribute("qc-origin-y", nil)
	self:SetAttribute("qc-active", nil)
]=])

local function clearCompiledAttributes()
	if QC.secureWheelFrame then QC.secureWheelFrame:Hide() end
	for _, frame in pairs(QC.secureHoverFrames or {}) do frame:Hide() end
	secureButton:SetAttribute("qc-path-depth", nil)
	secureButton:SetAttribute("qc-nav-menu", nil)
	secureButton:SetAttribute("qc-wheel-index", nil)
	secureButton:SetAttribute("qc-macro-toggle", nil)
	for depth = 1, QC.MAX_MENUS do
		secureButton:SetAttribute("qc-path-menu-" .. depth, nil)
		secureButton:SetAttribute("qc-path-offset-x-" .. depth, nil)
		secureButton:SetAttribute("qc-path-offset-y-" .. depth, nil)
	end
	for menuID in pairs(compiledMenuIDs) do
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-count", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-layout", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-size", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-offset-x", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-offset-y", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-show-at-cursor", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-hotkey", nil)
		secureButton:SetAttribute("qc-menu-" .. menuID .. "-default-index", nil)
	end
	for menuID, count in pairs(compiledActionCounts) do
		for actionIndex = 1, count do
			local prefix = "qc-action-" .. menuID .. "-" .. actionIndex .. "-"
			local selectedButton = "qc-" .. menuID .. "-" .. actionIndex
			secureButton:SetAttribute("typerelease-" .. selectedButton, nil)
			secureButton:SetAttribute("clickbutton-" .. selectedButton, nil)
			secureButton:SetAttribute(prefix .. "x", nil)
			secureButton:SetAttribute(prefix .. "y", nil)
			secureButton:SetAttribute(prefix .. "submenu-id", nil)
		end
	end
	for menuID in pairs(compiledEntries) do compiledEntries[menuID] = nil end
	compiledActionCounts = {}
	compiledMenuIDs = {}
end

local function buildMountMacro(spellID)
	if addon.MountActions and addon.MountActions.BuildMountMacro then
		return addon.MountActions:BuildMountMacro(spellID)
	end
	local spellInfo = _G.C_Spell and _G.C_Spell.GetSpellInfo and _G.C_Spell.GetSpellInfo(spellID)
	local name = spellInfo and spellInfo.name
	if not name or name == "" then return nil end
	local macro = "/cast " .. name
	if addon.variables and addon.variables.unitClass == "DRUID" then macro = "/cancelform [nocombat]\n" .. macro end
	return macro
end

local function clearCompiledActionButton(button)
	button:SetScript("PreClick", nil)
	button._eqolAction = nil
	button:SetAttribute("type", nil)
	button:SetAttribute("type1", nil)
	button:SetAttribute("spell", nil)
	button:SetAttribute("spell1", nil)
	button:SetAttribute("item", nil)
	button:SetAttribute("item1", nil)
	button:SetAttribute("macro", nil)
	button:SetAttribute("macro1", nil)
	button:SetAttribute("macrotext", nil)
	button:SetAttribute("macrotext1", nil)
	button:SetAttribute("clickbutton", nil)
	button:SetAttribute("marker", nil)
	button:SetAttribute("action", nil)
	button:SetAttribute("unit", nil)
	button:SetAttribute("equipmentset", nil)
	button:SetAttribute("outfit-index", nil)
	button:SetAttribute("pressAndHoldAction", nil)
	button:SetAttribute("useOnKeyDown", false)
end

local function prepareEQOLActionButton(button)
	if _G.InCombatLockdown() then return end
	if button._eqolAction == "hearthstone" then
		local functions = addon.MythicPlus and addon.MythicPlus.functions
		local itemID
		if functions and functions.GetRandomHearthstoneItemID then itemID = functions.GetRandomHearthstoneItemID(true) end
		if _G.issecretvalue and _G.issecretvalue(itemID) then itemID = 6948 end
		if itemID == nil or type(itemID) ~= "number" or itemID <= 0 then itemID = 6948 end
		local macro = "/use item:" .. tostring(math.floor(itemID))
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", macro)
		return
	end
	if addon.MountActions and addon.MountActions.PrepareActionButton then
		addon.MountActions:PrepareActionButton(button)
	end
end

local function ensureCompiledActionButton(menuID, entryID)
	local key = tostring(menuID) .. ":" .. tostring(entryID)
	local button = compiledActionButtons[key]
	if button or _G.InCombatLockdown() then return button end
	local name = "EQOLQuickActionsAction" .. tostring(menuID) .. "_" .. tostring(entryID)
	button = _G.CreateFrame("Button", name, _G.UIParent, "SecureActionButtonTemplate")
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("useOnKeyDown", false)
	button:Hide()
	compiledActionButtons[key] = button
	return button
end

local function configureCompiledActionButton(menuID, entry)
	local action = entry and entry.action
	if type(action) ~= "table" then return nil end
	local button = ensureCompiledActionButton(menuID, action.entryID)
	if not button then return nil end
	clearCompiledActionButton(button)
	local kind = action.kind
	if kind == "spell" then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", action.id)
	elseif kind == "item" then
		button:SetAttribute("type", "item")
		button:SetAttribute("item", "item:" .. tostring(action.id))
	elseif kind == "mount" then
		local macro = buildMountMacro(entry.resolvedValue)
		if not macro then return nil end
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", macro)
	elseif kind == "battlepet" then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", (_G.SLASH_SUMMON_BATTLE_PET1 or "/summonpet") .. " " .. (entry.name or action.id))
	elseif kind == "macro" then
		if not entry.resolvedValue then return nil end
		button:SetAttribute("type", "macro")
		button:SetAttribute("macro", entry.resolvedValue)
	elseif kind == "worldmarker" and action.id == 0 then
		button:SetAttribute("type", "stop")
	elseif kind == "worldmarker" or kind == "raidtarget" then
		button:SetAttribute("type", kind)
		button:SetAttribute("marker", action.id)
		button:SetAttribute("action", "toggle")
		if kind == "raidtarget" then button:SetAttribute("unit", "target") end
	elseif kind == "equipmentset" then
		if not entry.resolvedValue then return nil end
		button:SetAttribute("type", "equipmentset")
		button:SetAttribute("equipmentset", entry.resolvedValue)
	elseif kind == "outfit" then
		if entry.resolvedValue == nil then return nil end
		button:SetAttribute("type", "outfit")
		button:SetAttribute("outfit-index", entry.resolvedValue)
		button:SetAttribute("action", "change")
	elseif kind == "eqol" then
		local definition = QC.EQOL_ACTIONS[action.id]
		if not definition then return nil end
		button._eqolAction = action.id == "hearthstone" and "hearthstone" or definition.mountAction
		if not button._eqolAction then return nil end
		button:SetScript("PreClick", prepareEQOLActionButton)
		prepareEQOLActionButton(button)
		if button:GetAttribute("type") == nil then return nil end
	else
		return nil
	end
	return button
end

local function applySecureMenuLayout(menu, entries)
	local menuID = menu.id
	local defaultIndex
	for actionIndex = 1, #entries do
		if entries[actionIndex].action.entryID == menu.defaultEntryID then
			defaultIndex = actionIndex
			break
		end
	end
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-layout", menu.layout)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-size", menu.iconSize)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-offset-x", menu.offsetX)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-offset-y", menu.offsetY)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-show-at-cursor", menu.showAtCursor == true or nil)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-default-index", defaultIndex)
	for actionIndex = 1, #entries do
		local prefix = "qc-action-" .. menuID .. "-" .. actionIndex .. "-"
		local offsetX, offsetY = QC:GetSlotOffset(menu, actionIndex, #entries)
		secureButton:SetAttribute(prefix .. "x", offsetX)
		secureButton:SetAttribute(prefix .. "y", offsetY)
		local action = entries[actionIndex].action
		local submenuID = action.kind == "menu" and tonumber(action.id) or nil
		secureButton:SetAttribute(prefix .. "submenu-id", submenuID)
		local hoverFrame = QC:EnsureSecureHoverFrame(menuID, actionIndex)
		if hoverFrame then hoverFrame:SetAttribute("qc-submenu-id", submenuID) end
	end
end

function QC:RefreshSecureMenuState(menuID)
	if _G.InCombatLockdown() or heldMenuID then return false end
	if traceState.active then
		local counts = traceState.counts
		counts["secure.menuRefresh.calls"] = (counts["secure.menuRefresh.calls"] or 0) + 1
	end
	menuID = tonumber(menuID)
	local config = self:GetConfig()
	if managedSourcesDirty then
		self:SyncManagedSources(config)
		managedSourcesDirty = false
	end
	local menu = menuID and config.menus[menuID] or nil
	if not menu then return false end
	for actionIndex = 1, #menu.actions do
		local action = menu.actions[actionIndex]
		if self:GetEffectiveHideOnCooldown(menu, action) then getActionCooldownActive(action, true) end
	end
	local currentSpecID = getCurrentSpecID()
	local entries = self:GetActiveActions(menu, currentSpecID)
	if traceState.active then
		local counts = traceState.counts
		counts["secure.menuRefresh.actionsScanned"] = (counts["secure.menuRefresh.actionsScanned"] or 0) + #menu.actions
		counts["secure.menuRefresh.entriesCompiled"] = (counts["secure.menuRefresh.entriesCompiled"] or 0) + #entries
	end
	local previousCount = compiledActionCounts[menuID] or 0
	for actionIndex = 1, math.max(previousCount, #entries) do
		local prefix = "qc-action-" .. menuID .. "-" .. actionIndex .. "-"
		local selectedButton = "qc-" .. menuID .. "-" .. actionIndex
		secureButton:SetAttribute("typerelease-" .. selectedButton, nil)
		secureButton:SetAttribute("clickbutton-" .. selectedButton, nil)
		secureButton:SetAttribute(prefix .. "x", nil)
		secureButton:SetAttribute(prefix .. "y", nil)
		secureButton:SetAttribute(prefix .. "submenu-id", nil)
		local hoverFrame = self.secureHoverFrames and self.secureHoverFrames[tostring(menuID) .. ":" .. tostring(actionIndex)]
		if hoverFrame then
			hoverFrame:SetAttribute("qc-submenu-id", nil)
			hoverFrame:Hide()
		end
	end
	compiledEntries[menuID] = entries
	compiledActionCounts[menuID] = #entries
	compiledMenuIDs[menuID] = true
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-count", #entries)
	secureButton:SetAttribute("qc-menu-" .. menuID .. "-hotkey", menu.hotkey)
	applySecureMenuLayout(menu, entries)
	for actionIndex = 1, #entries do
		local delegate = configureCompiledActionButton(menuID, entries[actionIndex])
		local selectedButton = "qc-" .. menuID .. "-" .. actionIndex
		if delegate then
			secureButton:SetAttribute("typerelease-" .. selectedButton, "click")
			secureButton:SetAttribute("clickbutton-" .. selectedButton, delegate)
		end
	end
	return true
end

function QC:RefreshSecureMenuTree(menuID)
	if _G.InCombatLockdown() or heldMenuID then return false end
	menuID = tonumber(menuID)
	if not menuID then return false end
	local pending = { menuID }
	local visited = {}
	local refreshed = false
	while pending[1] do
		local currentMenuID = table.remove(pending)
		if not visited[currentMenuID] then
			visited[currentMenuID] = true
			local menu = self:GetMenu(currentMenuID)
			if menu and menu.enabled ~= false then
				if self:RefreshSecureMenuState(currentMenuID) then refreshed = true end
				for index = 1, #menu.actions do
					local action = menu.actions[index]
					local childMenuID = action.kind == "menu" and tonumber(action.id) or nil
					if childMenuID and not visited[childMenuID] then pending[#pending + 1] = childMenuID end
				end
			end
		end
	end
	return refreshed
end

function QC:RebuildSecureState()
	if _G.InCombatLockdown() or heldMenuID then
		if traceState.active then
			local counts = traceState.counts
			counts["secure.fullRebuild.deferred"] = (counts["secure.fullRebuild.deferred"] or 0) + 1
		end
		rebuildPending = true
		if self.UpdateRegenEventRegistration then self:UpdateRegenEventRegistration() end
		return false
	end
	if traceState.active then
		local counts = traceState.counts
		counts["secure.fullRebuild.calls"] = (counts["secure.fullRebuild.calls"] or 0) + 1
	end
	rebuildPending = false
	self.pendingSecureLayoutRefreshes = nil
	_G.ClearOverrideBindings(bindingOwner)
	clearCompiledAttributes()
	secureButton:SetAttribute("qc-dead-zone", self.SELECTION_DEAD_ZONE)
	secureButton:SetAttribute("qc-max-depth", self.MAX_MENUS)
	local config = self:GetConfig()
	secureButton:SetAttribute("qc-activation-mode", config.activationMode)
	if managedSourcesDirty then
		self:SyncManagedSources(config)
		managedSourcesDirty = false
	end
	local currentSpecID = getCurrentSpecID()
	for orderIndex = 1, #config.order do
		local menu = config.menus[config.order[orderIndex]]
		if menu then
			if traceState.active then
				local counts = traceState.counts
				counts["secure.fullRebuild.actionsScanned"] = (counts["secure.fullRebuild.actionsScanned"] or 0) + #menu.actions
			end
			for actionIndex = 1, #menu.actions do
				local action = menu.actions[actionIndex]
				if self:GetEffectiveHideOnCooldown(menu, action) then getActionCooldownActive(action, true) end
			end
			local menuID = menu.id
			local entries = self:GetActiveActions(menu, currentSpecID)
			if traceState.active then
				local counts = traceState.counts
				counts["secure.fullRebuild.entriesCompiled"] = (counts["secure.fullRebuild.entriesCompiled"] or 0) + #entries
			end
			compiledEntries[menuID] = entries
			if menu.enabled and self:MenuAllowsSpec(menu, currentSpecID) then
				secureButton:SetAttribute("qc-menu-" .. menuID .. "-count", #entries)
				applySecureMenuLayout(menu, entries)
				secureButton:SetAttribute("qc-menu-" .. menuID .. "-hotkey", menu.hotkey)
				compiledMenuIDs[menuID] = true
				compiledActionCounts[menuID] = #entries
				for actionIndex = 1, #entries do
					local entry = entries[actionIndex]
					local delegate = configureCompiledActionButton(menuID, entry)
					local selectedButton = "qc-" .. menuID .. "-" .. actionIndex
					if delegate then
						secureButton:SetAttribute("typerelease-" .. selectedButton, "click")
						secureButton:SetAttribute("clickbutton-" .. selectedButton, delegate)
					else
						secureButton:SetAttribute("typerelease-" .. selectedButton, nil)
						secureButton:SetAttribute("clickbutton-" .. selectedButton, nil)
					end
				end
				if menu.hotkey and menu.hotkey ~= "" then
					_G.SetOverrideBindingClick(bindingOwner, true, menu.hotkey, SECURE_BUTTON_NAME, tostring(menuID))
				end
			end
		end
	end
	if visual.previewMode then self:RefreshLayoutPreview() end
	if self.UpdateRegenEventRegistration then self:UpdateRegenEventRegistration() end
	return true
end

function QC:QueueSecureLayoutRefresh(menuID)
	if _G.InCombatLockdown() or heldMenuID then
		self.pendingSecureLayoutRefreshes = self.pendingSecureLayoutRefreshes or {}
		self.pendingSecureLayoutRefreshes[tonumber(menuID) or menuID] = true
		if self.UpdateRegenEventRegistration then self:UpdateRegenEventRegistration() end
		return false
	end
	menuID = tonumber(menuID)
	local menu = menuID and self:GetMenu(menuID) or nil
	if not menu then return false end
	if compiledMenuIDs[menuID] then applySecureMenuLayout(menu, compiledEntries[menuID] or {}) end
	self:RefreshVisibleMenuLayout(menuID)
	if self.UpdateRegenEventRegistration then self:UpdateRegenEventRegistration() end
	return true
end

function QC:QueueSecureRebuild()
	if traceState.active then
		local counts = traceState.counts
		counts["secure.queueRebuild.calls"] = (counts["secure.queueRebuild.calls"] or 0) + 1
	end
	if _G.InCombatLockdown() or heldMenuID then
		if traceState.active then
			local counts = traceState.counts
			counts["secure.queueRebuild.deferred"] = (counts["secure.queueRebuild.deferred"] or 0) + 1
		end
		rebuildPending = true
		if self.UpdateRegenEventRegistration then self:UpdateRegenEventRegistration() end
		return false
	end
	return self:RebuildSecureState()
end

function QC:IsHotkeyUsedByAnother(menuID, hotkey)
	hotkey = trim(hotkey)
	if hotkey == "" then return false end
	local config = self:GetConfig()
	for index = 1, #config.order do
		local menu = config.menus[config.order[index]]
		if menu and menu.id ~= tonumber(menuID) and menu.hotkey == hotkey then return true, menu.name end
	end
	return false
end

function QC:GetBindingConflict(hotkey)
	if not hotkey or hotkey == "" then return nil end
	local action = _G.GetBindingAction(hotkey)
	if action and action ~= "" and not action:match("^CLICK EQOLQuickCast") then return action end
	return nil
end

local eventFrame = _G.CreateFrame("Frame")
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("TRANSMOG_OUTFITS_CHANGED")
eventFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

local rebuildEvents = {
	PLAYER_LOGIN = true,
	PLAYER_SPECIALIZATION_CHANGED = true,
	TRANSMOG_OUTFITS_CHANGED = true,
}

local managedSourceEvents = {
	CHALLENGE_MODE_MAPS_UPDATE = true,
}

local visualRefreshEvents = {
	PLAYER_REGEN_DISABLED = 1,
	PLAYER_REGEN_ENABLED = 1,
	PLAYER_SPECIALIZATION_CHANGED = 3,
}

local visualStateEvents = {
	BAG_UPDATE = "itemEntryCount",
	BAG_UPDATE_COOLDOWN = "itemEntryCount",
	MOUNT_JOURNAL_USABILITY_CHANGED = "mountUsabilityEntryCount",
	PLAYER_REGEN_DISABLED = "dynamicUsabilityEntryCount",
	PLAYER_REGEN_ENABLED = "dynamicUsabilityEntryCount",
	SPELL_UPDATE_COOLDOWN = "spellCooldownEntryCount",
	SPELL_UPDATE_USABLE = "spellUsabilityEntryCount",
}

function QC:SetVisualStateEventsEnabled(enabled)
	_G.wipe(visual.registeredStateEvents)
	for event, countKey in pairs(visualStateEvents) do
		eventFrame:UnregisterEvent(event)
		local entryCount = visual[countKey] or 0
		if event == "SPELL_UPDATE_COOLDOWN" then entryCount = entryCount + (visual.itemEntryCount or 0) end
		local visualNeedsEvent = enabled and visual.previewMode ~= true and entryCount > 0
		local pendingNeedsRegen = event == "PLAYER_REGEN_ENABLED"
			and (rebuildPending or (self.pendingSecureLayoutRefreshes and next(self.pendingSecureLayoutRefreshes) ~= nil))
		if visualNeedsEvent or pendingNeedsRegen then
			eventFrame:RegisterEvent(event)
			if visualNeedsEvent then
				visual.registeredStateEvents[event] = true
				if traceState.active then traceState.lastRegisteredStateEvents[event] = true end
			end
			if traceState.active and visualNeedsEvent then
				local counts = traceState.counts
				counts["events.dynamicRegistrations"] = (counts["events.dynamicRegistrations"] or 0) + 1
			end
		end
	end
	visual.spellUsabilityPending = false
	visual.spellUsabilityElapsed = 0
	eventFrame:SetScript("OnUpdate", nil)
end

function QC:UpdateRegenEventRegistration()
	local hasPendingLayout = self.pendingSecureLayoutRefreshes and next(self.pendingSecureLayoutRefreshes) ~= nil
	local visibleNeedsRegen = visual:IsShown() and visual.previewMode ~= true and (visual.dynamicUsabilityEntryCount or 0) > 0
	if rebuildPending or hasPendingLayout or visibleNeedsRegen then
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

eventFrame.usabilityOnUpdate = function(self, elapsed)
	if traceState.active then
		local counts = traceState.counts
		counts["spellUsability.onUpdateCalls"] = (counts["spellUsability.onUpdateCalls"] or 0) + 1
	end
	if not visual.spellUsabilityPending or not visual:IsShown() then
		visual.spellUsabilityPending = false
		visual.spellUsabilityElapsed = 0
		self:SetScript("OnUpdate", nil)
		return
	end
	visual.spellUsabilityElapsed = visual.spellUsabilityElapsed + elapsed
	if visual.spellUsabilityElapsed < 0.1 then return end
	visual.spellUsabilityPending = false
	visual.spellUsabilityElapsed = 0
	self:SetScript("OnUpdate", nil)
	if traceState.active then
		local counts = traceState.counts
		counts["spellUsability.flushes"] = (counts["spellUsability.flushes"] or 0) + 1
		counts["spellUsability.entries"] = (counts["spellUsability.entries"] or 0) + #visual.spellUsabilityIndices
	end
	refreshVisualEntryIndices(visual.spellUsabilityIndices, true, false)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if traceState.active then
		local eventCounts = traceState.eventCounts
		eventCounts[event] = (eventCounts[event] or 0) + 1
	end
	if managedSourceEvents[event] then QC:MarkManagedSourcesDirty() end
	local rebuilt = false
	if event == "PLAYER_REGEN_ENABLED" then
		local hasPendingLayout = QC.pendingSecureLayoutRefreshes and next(QC.pendingSecureLayoutRefreshes) ~= nil
		if rebuildPending or hasPendingLayout then rebuilt = QC:QueueSecureRebuild() == true end
	elseif rebuildEvents[event] then
		rebuilt = QC:QueueSecureRebuild() == true
	end
	if not visual:IsShown() or (rebuilt and visual.previewMode) then return end
	if event == "SPELL_UPDATE_COOLDOWN" then
		refreshSpellCooldownEntries(...)
		if visual.itemEntryCount > 0 then
			if traceState.active then
				local counts = traceState.counts
				counts["itemSpellCooldown.entries"] = (counts["itemSpellCooldown.entries"] or 0) + #visual.itemIndices
			end
			refreshVisualEntryIndices(visual.itemIndices, false, true)
		end
		return
	elseif event == "SPELL_UPDATE_USABLE" then
		if not visual.spellUsabilityPending then
			visual.spellUsabilityPending = true
			visual.spellUsabilityElapsed = 0
			eventFrame:SetScript("OnUpdate", eventFrame.usabilityOnUpdate)
			if traceState.active then
				local counts = traceState.counts
				counts["spellUsability.queued"] = (counts["spellUsability.queued"] or 0) + 1
			end
		elseif traceState.active then
			local counts = traceState.counts
			counts["spellUsability.coalesced"] = (counts["spellUsability.coalesced"] or 0) + 1
		end
		return
	elseif event == "BAG_UPDATE_COOLDOWN" then
		if traceState.active then
			local counts = traceState.counts
			counts["bagCooldown.entries"] = (counts["bagCooldown.entries"] or 0) + #visual.itemIndices
		end
		refreshVisualEntryIndices(visual.itemIndices, false, true)
		return
	elseif event == "BAG_UPDATE" then
		if traceState.active then
			local counts = traceState.counts
			counts["bagUpdate.entries"] = (counts["bagUpdate.entries"] or 0) + #visual.itemIndices
		end
		refreshVisualEntryIndices(visual.itemIndices, true, true)
		return
	elseif event == "MOUNT_JOURNAL_USABILITY_CHANGED" then
		if traceState.active then
			local counts = traceState.counts
			counts["mountUsability.entries"] = (counts["mountUsability.entries"] or 0) + #visual.mountUsabilityIndices
		end
		refreshVisualEntryIndices(visual.mountUsabilityIndices, true, false)
		return
	end
	local visualRefresh = visualRefreshEvents[event]
	if visualRefresh then
		refreshVisualActionStates(visualRefresh == 1 or visualRefresh == 3, visualRefresh >= 2)
	end
end)

QC.compiledEntries = compiledEntries
QC:Normalize()
QC:RebuildSecureState()
