local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.FocusInterruptTracker = addon.Aura.FocusInterruptTracker or {}
local Tracker = addon.Aura.FocusInterruptTracker

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local LSM = LibStub("LibSharedMedia-3.0", true)

local UIParent = _G.UIParent
local CreateFrame = _G.CreateFrame
local STANDARD_TEXT_FONT = _G.STANDARD_TEXT_FONT
local NONE = _G.NONE
local DEFAULT = _G.DEFAULT or "Default"
local PlaySound = _G.PlaySound
local PlaySoundFile = _G.PlaySoundFile
local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
local issecretvalue = _G.issecretvalue

local DB_KEY = "focusInterruptTracker"
local EDITMODE_ID = "focusInterruptTracker"
Tracker.dynamicAnchorId = "tracker:focusInterrupt"
local DEFAULT_PREVIEW_TEXT = "INTERRUPT"
local DEFAULT_PREVIEW_ICON = 132938
local DEFAULT_SETTINGS_MAX_HEIGHT = 900
local FOCUS_GLOW_KEY = "EQOL_FOCUS_INTERRUPT"

local GLOW_STYLE_OPTIONS = {
	{ value = "BLIZZARD", labelKey = "Blizzard", fallback = "Blizzard" },
	{ value = "FLASH", labelKey = "Flash", fallback = "Flash" },
	{ value = "MARCHING_ANTS", labelKey = "Marching ants", fallback = "Marching ants" },
	{ value = "PIXEL", labelKey = "Pixel", fallback = "Pixel" },
	{ value = "PULSING", labelKey = "Pulsing", fallback = "Pulsing" },
}
local GLOW_INSET_MIN = -100
local GLOW_INSET_MAX = 100
local GLOW_PIXEL_COUNT_MIN = 1
local GLOW_PIXEL_COUNT_MAX = 32
local GLOW_PIXEL_SPEED_MIN = 0.05
local GLOW_PIXEL_SPEED_MAX = 2
local GLOW_THICKNESS_MIN = 1
local GLOW_THICKNESS_MAX = 10

local GetSpellCooldownInfo = (C_Spell and C_Spell.GetSpellCooldown) or _G.GetSpellCooldown

local function IsSpellKnown(spellId, includeOverrides)
	if not spellId then return false end
	if C_SpellBook then
		local spellBank = Enum and Enum.SpellBookSpellBank
		local playerBank = (spellBank and spellBank.Player) or 0
		local petBank = (spellBank and spellBank.Pet) or 1
		if C_SpellBook.IsSpellKnownOrInSpellBook then
			if C_SpellBook.IsSpellKnownOrInSpellBook(spellId, playerBank, includeOverrides) then return true end
			if C_SpellBook.IsSpellKnownOrInSpellBook(spellId, petBank, includeOverrides) then return true end
			return false
		end
		if C_SpellBook.IsSpellInSpellBook then
			if C_SpellBook.IsSpellInSpellBook(spellId, playerBank, includeOverrides) then return true end
			if C_SpellBook.IsSpellInSpellBook(spellId, petBank, includeOverrides) then return true end
			return false
		end
	end
	return false
end

local ANCHOR_POINTS = {
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

local VALID_ANCHOR_POINTS = {}
for i = 1, #ANCHOR_POINTS do
	VALID_ANCHOR_POINTS[ANCHOR_POINTS[i]] = true
end

local OUTLINE_OPTIONS = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true) or {
	{ value = "NONE", label = NONE },
	{ value = "OUTLINE", label = L["Outline"] or "Outline" },
}
local VALID_OUTLINES = {}
for i = 1, #OUTLINE_OPTIONS do
	local option = OUTLINE_OPTIONS[i]
	if option and option.value then VALID_OUTLINES[option.value] = true end
end

local DISPLAY_MODES = {
	TEXT = true,
	ICON = true,
}

local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local VALID_STRATA = {}
for i = 1, #STRATA_ORDER do
	VALID_STRATA[STRATA_ORDER[i]] = true
end

local EXTERNAL_ANCHOR_ADDONS = {
	ElvUI = true,
	MidnightSimpleUnitFrames = true,
	UnhaltedUnitFrames = true,
}

local CLASS_INTERRUPT_SPELLS = {
	DEATHKNIGHT = { 47528 },
	DEMONHUNTER = { 183752 },
	DRUID = { 106839, 78675 },
	EVOKER = { 351338 },
	HUNTER = { 147362, 187707 },
	MAGE = { 2139 },
	MONK = { 116705 },
	PALADIN = { 31935, 96231 },
	PRIEST = { 15487 },
	ROGUE = { 1766 },
	SHAMAN = { 57994 },
	WARLOCK = { 132409, 119910, 119914, 19647 },
	WARRIOR = { 6552 },
}

local ALL_INTERRUPT_SPELLS = {}
for _, spellList in pairs(CLASS_INTERRUPT_SPELLS) do
	for i = 1, #spellList do
		local spellId = tonumber(spellList[i])
		if spellId then ALL_INTERRUPT_SPELLS[spellId] = true end
	end
end

local AUTO_ANCHOR_OPTIONS = {
	{
		value = "AUTO",
		label = L["FocusInterruptTrackerAnchorAuto"] or "Auto focus frame",
	},
	{
		value = "UIParent",
		label = "UIParent",
	},
	{
		value = "EQOLUFFocusFrame",
		label = L["FocusInterruptTrackerAnchorEQOL"] or "EQOL: Focus Frame",
	},
	{
		value = "FocusFrame",
		label = L["FocusInterruptTrackerAnchorBlizzard"] or "Blizzard: Focus Frame",
	},
	{
		value = "ElvUF_Focus",
		label = L["FocusInterruptTrackerAnchorElvUI"] or "ElvUI: Focus Frame",
		addonName = "ElvUI",
	},
	{
		value = "MSUF_focus",
		label = L["FocusInterruptTrackerAnchorMSUF"] or "MSUF: Focus Frame",
		addonName = "MidnightSimpleUnitFrames",
	},
	{
		value = "UUF_Focus",
		label = L["FocusInterruptTrackerAnchorUUF"] or "UUF: Focus Frame",
		addonName = "UnhaltedUnitFrames",
	},
}

Tracker.defaults = Tracker.defaults
	or {
		version = 1,
		enabled = false,
		displayMode = "TEXT",
		text = DEFAULT_PREVIEW_TEXT,
		textFont = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__",
		textSize = 24,
		textOutline = "THICKOUTLINE",
		textColor = { 1, 0.15, 0.15, 1 },
		iconSize = 28,
		customIcon = nil,
		glow = {
			enabled = false,
			style = "MARCHING_ANTS",
			color = { 1, 0.15, 0.15, 1 },
			inset = 0,
			pixelBorder = false,
			pixelCount = 8,
			pixelSpeed = 0.25,
			thickness = 2,
		},
		background = {
			enabled = false,
			color = { 0, 0, 0, 0.35 },
		},
		sound = {
			enabled = false,
			file = "",
		},
		border = {
			enabled = false,
			texture = "DEFAULT",
			size = 1,
			offset = 0,
			color = { 0, 0, 0, 0.9 },
		},
		anchor = {
			point = "TOP",
			relativePoint = "BOTTOM",
			relativeFrame = "AUTO",
			x = 0,
			y = -10,
		},
		strata = "HIGH",
	}

local defaults = Tracker.defaults
local state = Tracker._state or {}
Tracker._state = state

local function copyValue(value)
	if type(value) ~= "table" then return value end
	if addon.functions and addon.functions.copyTable then return addon.functions.copyTable(value) end
	return CopyTable(value)
end

local function mergeDefaults(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then return end
	for key, value in pairs(source) do
		if target[key] == nil then
			target[key] = copyValue(value)
		elseif type(target[key]) == "table" and type(value) == "table" then
			mergeDefaults(target[key], value)
		end
	end
end

local function trimString(value)
	if type(value) ~= "string" then return nil end
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	if value == "" then return nil end
	return value
end

local function normalizeAnchorPoint(value, fallback)
	local point = type(value) == "string" and string.upper(value) or nil
	if point and VALID_ANCHOR_POINTS[point] then return point end
	local fallbackPoint = type(fallback) == "string" and string.upper(fallback) or "CENTER"
	if VALID_ANCHOR_POINTS[fallbackPoint] then return fallbackPoint end
	return "CENTER"
end

local function normalizeOutline(value, fallback)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, fallback or defaults.textOutline or "NONE", true)
	end
	local outline = type(value) == "string" and string.upper(value) or nil
	if outline and VALID_OUTLINES[outline] then return outline end
	local fallbackOutline = type(fallback) == "string" and string.upper(fallback) or "NONE"
	if VALID_OUTLINES[fallbackOutline] then return fallbackOutline end
	return "NONE"
end

local function resolveFontFlags(style, fallback)
	if addon.functions and addon.functions.ResolveFontStyle then
		local _, flags = addon.functions.ResolveFontStyle(style, fallback)
		return flags
	end
	if addon.functions and addon.functions.GetFontFlagsForStyle then
		local flags = addon.functions.GetFontFlagsForStyle(style, fallback)
		if type(flags) == "string" then return flags end
	end
	local outline = normalizeOutline(style, fallback or defaults.textOutline or "NONE")
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = normalizeOutline(fallback or defaults.textOutline or "NONE", "NONE") end
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = "NONE" end
	if outline == "NONE" then return "" end
	return outline
end

local function normalizeDisplayMode(value, fallback)
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode and DISPLAY_MODES[mode] then return mode end
	local fallbackMode = type(fallback) == "string" and string.upper(fallback) or "TEXT"
	if DISPLAY_MODES[fallbackMode] then return fallbackMode end
	return "TEXT"
end

local function normalizeGlowStyle(value, fallback, displayMode)
	local normalized = type(value) == "string" and string.upper(value) or nil
	if displayMode == "TEXT" and normalized ~= "PIXEL" and normalized ~= "PULSING" then normalized = nil end
	for i = 1, #GLOW_STYLE_OPTIONS do
		local option = GLOW_STYLE_OPTIONS[i]
		if option.value == normalized and (displayMode ~= "TEXT" or option.value == "PIXEL" or option.value == "PULSING") then return normalized end
	end
	fallback = type(fallback) == "string" and string.upper(fallback) or "MARCHING_ANTS"
	if displayMode == "TEXT" and fallback ~= "PIXEL" and fallback ~= "PULSING" then fallback = "PULSING" end
	for i = 1, #GLOW_STYLE_OPTIONS do
		if GLOW_STYLE_OPTIONS[i].value == fallback then return fallback end
	end
	return "MARCHING_ANTS"
end

local function normalizeStrata(value, fallback)
	local strata = type(value) == "string" and string.upper(value) or nil
	if strata and VALID_STRATA[strata] then return strata end
	local fallbackStrata = type(fallback) == "string" and string.upper(fallback) or "HIGH"
	if VALID_STRATA[fallbackStrata] then return fallbackStrata end
	return "HIGH"
end

local function clampNumber(value, minValue, maxValue, fallback)
	value = tonumber(value)
	if value == nil then value = fallback end
	value = tonumber(value) or 0
	if minValue ~= nil and value < minValue then value = minValue end
	if maxValue ~= nil and value > maxValue then value = maxValue end
	return value
end

local function clampInt(value, minValue, maxValue, fallback)
	return math.floor(clampNumber(value, minValue, maxValue, fallback) + 0.5)
end

local function normalizeColor(value, fallback)
	local color = type(value) == "table" and value or fallback or { 1, 1, 1, 1 }
	local r = color.r or color[1] or 1
	local g = color.g or color[2] or 1
	local b = color.b or color[3] or 1
	local a = color.a or color[4]
	if a == nil then a = 1 end
	return {
		clampNumber(r, 0, 1, 1),
		clampNumber(g, 0, 1, 1),
		clampNumber(b, 0, 1, 1),
		clampNumber(a, 0, 1, 1),
	}
end

local function normalizeCustomIcon(value)
	if value == nil then return nil end
	if type(value) == "number" then
		if value > 0 then return math.floor(value + 0.5) end
		return nil
	end
	local text = trimString(tostring(value))
	if not text then return nil end
	local numeric = tonumber(text)
	if numeric and numeric > 0 then return math.floor(numeric + 0.5) end
	return text
end

local function isLikelyFilePath(value)
	if type(value) ~= "string" or value == "" then return false end
	return value:find("/", 1, true) ~= nil or value:find("\\", 1, true) ~= nil
end

local function resolveBorderTexture(value)
	if value == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if not value or value == "" or value == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	if LSM and LSM.Fetch then
		local texture = LSM:Fetch("border", value, true)
		if texture then return texture end
	end
	if isLikelyFilePath(value) then return value end
	return "Interface\\Buttons\\WHITE8x8"
end

local function getFontOptions()
	local options = {}
	local globalKey = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or defaults.textFont
	local globalLabel = addon.functions and addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or "Use global font config"
	options[#options + 1] = {
		value = globalKey,
		label = globalLabel,
	}

	local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("font") or {}
	for i = 1, #mediaOptions do
		options[#options + 1] = {
			value = mediaOptions[i].value,
			label = mediaOptions[i].label,
		}
	end

	return options
end

local function getBorderOptions()
	local options = {
		{ value = "DEFAULT", label = DEFAULT },
		{ value = "SOLID", label = "Solid" },
	}
	local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("border") or {}
	for i = 1, #mediaOptions do
		options[#options + 1] = {
			value = mediaOptions[i].value,
			label = mediaOptions[i].label,
		}
	end
	return options
end

local function isEQOLFocusEnabled()
	if addon.functions and addon.functions.IsEQoLUnitFrameEnabled then return addon.functions.IsEQoLUnitFrameEnabled("focus") end
	local frames = addon.db and addon.db.ufFrames
	local focus = frames and frames.focus
	return focus and focus.enabled == true or false
end

local function hasAnchorFrame(option)
	if not option then return false end
	if option.value == "AUTO" or option.value == "UIParent" then return true end
	if option.addonName and IsAddOnLoaded and not IsAddOnLoaded(option.addonName) then return false end
	if option.value == "EQOLUFFocusFrame" and not isEQOLFocusEnabled() and not _G.EQOLUFFocusFrame then return false end
	return _G[option.value] ~= nil
end

local function getResolvedAutoAnchorTarget()
	local preferred = { "EQOLUFFocusFrame", "ElvUF_Focus", "MSUF_focus", "UUF_Focus", "FocusFrame" }
	for i = 1, #preferred do
		local key = preferred[i]
		if key == "EQOLUFFocusFrame" then
			if isEQOLFocusEnabled() and _G[key] then return key end
		elseif _G[key] then
			return key
		end
	end
	if _G.FocusFrame then return "FocusFrame" end
	return "UIParent"
end

function Tracker:GetConfig()
	addon.db = addon.db or {}
	local cfg = addon.db[DB_KEY]
	if type(cfg) ~= "table" then
		cfg = copyValue(defaults)
		addon.db[DB_KEY] = cfg
	end

	mergeDefaults(cfg, defaults)
	cfg.anchor = type(cfg.anchor) == "table" and cfg.anchor or {}
	cfg.background = type(cfg.background) == "table" and cfg.background or {}
	cfg.sound = type(cfg.sound) == "table" and cfg.sound or {}
	cfg.border = type(cfg.border) == "table" and cfg.border or {}
	mergeDefaults(cfg.anchor, defaults.anchor)
	mergeDefaults(cfg.background, defaults.background)
	mergeDefaults(cfg.sound, defaults.sound)
	mergeDefaults(cfg.border, defaults.border)

	cfg.enabled = cfg.enabled == true
	cfg.displayMode = normalizeDisplayMode(cfg.displayMode, defaults.displayMode)
	cfg.text = trimString(cfg.text) or DEFAULT_PREVIEW_TEXT
	cfg.textFont = cfg.textFont or defaults.textFont
	cfg.textSize = clampInt(cfg.textSize, 8, 96, defaults.textSize)
	cfg.textOutline = normalizeOutline(cfg.textOutline, defaults.textOutline)
	cfg.textColor = normalizeColor(cfg.textColor, defaults.textColor)
	cfg.iconSize = clampInt(cfg.iconSize, 8, 128, defaults.iconSize)
	cfg.customIcon = normalizeCustomIcon(cfg.customIcon)
	cfg.glow = type(cfg.glow) == "table" and cfg.glow or {}
	mergeDefaults(cfg.glow, defaults.glow)
	cfg.glow.enabled = cfg.glow.enabled == true
	cfg.glow.style = normalizeGlowStyle(cfg.glow.style, defaults.glow.style, cfg.displayMode)
	cfg.glow.color = normalizeColor(cfg.glow.color, defaults.glow.color)
	cfg.glow.inset = clampInt(cfg.glow.inset, GLOW_INSET_MIN, GLOW_INSET_MAX, defaults.glow.inset)
	cfg.glow.pixelBorder = cfg.glow.pixelBorder == true
	cfg.glow.pixelCount = clampInt(cfg.glow.pixelCount, GLOW_PIXEL_COUNT_MIN, GLOW_PIXEL_COUNT_MAX, defaults.glow.pixelCount)
	cfg.glow.pixelSpeed = clampNumber(cfg.glow.pixelSpeed, GLOW_PIXEL_SPEED_MIN, GLOW_PIXEL_SPEED_MAX, defaults.glow.pixelSpeed)
	cfg.glow.thickness = clampInt(cfg.glow.thickness, GLOW_THICKNESS_MIN, GLOW_THICKNESS_MAX, defaults.glow.thickness)
	cfg.background.enabled = cfg.background.enabled == true
	cfg.background.color = normalizeColor(cfg.background.color, defaults.background.color)
	cfg.sound.enabled = cfg.sound.enabled == true
	cfg.sound.file = trimString(cfg.sound.file) or ""
	cfg.border.enabled = cfg.border.enabled == true
	cfg.border.texture = cfg.border.texture or defaults.border.texture
	cfg.border.size = clampInt(cfg.border.size, 1, 32, defaults.border.size)
	cfg.border.offset = clampInt(cfg.border.offset, -20, 20, defaults.border.offset)
	cfg.border.color = normalizeColor(cfg.border.color, defaults.border.color)
	cfg.anchor.point = normalizeAnchorPoint(cfg.anchor.point, defaults.anchor.point)
	cfg.anchor.relativePoint = normalizeAnchorPoint(cfg.anchor.relativePoint, defaults.anchor.relativePoint)
	cfg.anchor.relativeFrame = trimString(cfg.anchor.relativeFrame) or defaults.anchor.relativeFrame
	cfg.anchor.x = clampInt(cfg.anchor.x, -4096, 4096, defaults.anchor.x)
	cfg.anchor.y = clampInt(cfg.anchor.y, -4096, 4096, defaults.anchor.y)
	cfg.strata = normalizeStrata(cfg.strata, defaults.strata)

	return cfg
end

function Tracker:IsEnabled()
	local cfg = self:GetConfig()
	return cfg.enabled == true
end

function Tracker:ResolveAnchorTarget()
	local cfg = self:GetConfig()
	local target = cfg.anchor.relativeFrame
	if target == "AUTO" then target = getResolvedAutoAnchorTarget() end
	if target == nil or target == "" then target = "UIParent" end
	if target ~= "UIParent" and not _G[target] then
		if cfg.anchor.relativeFrame == "AUTO" then
			target = getResolvedAutoAnchorTarget()
		end
		if target ~= "UIParent" and not _G[target] then target = "UIParent" end
	end
	return target
end

function Tracker:ResolveAnchorFrame()
	local target = self:ResolveAnchorTarget()
	if target == "UIParent" then return UIParent end
	return _G[target] or UIParent
end

function Tracker:AnchorUsesUIParent()
	return self:ResolveAnchorTarget() == "UIParent"
end

function Tracker:GetDynamicAnchorWinner()
	return addon.DynamicAnchors and addon.DynamicAnchors:GetSimpleFrameWinner(self.dynamicAnchorId) or nil
end

function Tracker:ApplyDynamicAnchor()
	local frame = state.frame
	if not frame then return false end
	local winner = self:GetDynamicAnchorWinner()
	if not (winner and winner.frame) then return false end
	local placement = winner.placement or {}
	local point = placement.point or "CENTER"
	local relativePoint = placement.relativePoint or point
	frame:ClearAllPoints()
	frame:SetPoint(point, winner.frame, relativePoint, tonumber(placement.x) or 0, tonumber(placement.y) or 0)
	return true
end

function Tracker:BuildLayoutRecordFromProfile()
	local cfg = self:GetConfig()
	return {
		point = cfg.anchor.point,
		relativePoint = cfg.anchor.relativePoint,
		x = cfg.anchor.x,
		y = cfg.anchor.y,
		anchorTarget = cfg.anchor.relativeFrame,
		displayMode = cfg.displayMode,
		text = cfg.text,
		textFont = cfg.textFont,
		textSize = cfg.textSize,
		textOutline = cfg.textOutline,
		textColor = copyValue(cfg.textColor),
		iconSize = cfg.iconSize,
		customIcon = cfg.customIcon,
		glowEnabled = cfg.glow.enabled,
		glowStyle = cfg.glow.style,
		glowColor = copyValue(cfg.glow.color),
		glowInset = cfg.glow.inset,
		glowPixelBorder = cfg.glow.pixelBorder,
		glowPixelCount = cfg.glow.pixelCount,
		glowPixelSpeed = cfg.glow.pixelSpeed,
		glowThickness = cfg.glow.thickness,
		backgroundEnabled = cfg.background.enabled,
		backgroundColor = copyValue(cfg.background.color),
		borderEnabled = cfg.border.enabled,
		borderTexture = cfg.border.texture,
		borderSize = cfg.border.size,
		borderOffset = cfg.border.offset,
		borderColor = copyValue(cfg.border.color),
		strata = cfg.strata,
	}
end

local function colorKey(color)
	if type(color) ~= "table" then return "" end
	return tostring(color[1] or color.r or "") .. ":" .. tostring(color[2] or color.g or "") .. ":" .. tostring(color[3] or color.b or "") .. ":" .. tostring(color[4] or color.a or "")
end

local function buildLayoutKey(cfg)
	if type(cfg) ~= "table" then return "" end
	local anchor = cfg.anchor or defaults.anchor
	local background = cfg.background or defaults.background
	local border = cfg.border or defaults.border
	local glow = cfg.glow or defaults.glow
	local fontVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	return table.concat({
		tostring(anchor.point),
		tostring(anchor.relativePoint),
		tostring(anchor.relativeFrame),
		tostring(anchor.x),
		tostring(anchor.y),
		tostring(cfg.strata),
		tostring(cfg.displayMode),
		tostring(cfg.text),
		tostring(cfg.textFont),
		tostring(cfg.textSize),
		tostring(cfg.textOutline),
		colorKey(cfg.textColor),
		tostring(cfg.iconSize),
		tostring(cfg.customIcon),
		tostring(glow.enabled),
		tostring(glow.style),
		colorKey(glow.color),
		tostring(glow.inset),
		tostring(glow.pixelBorder),
		tostring(glow.pixelCount),
		tostring(glow.pixelSpeed),
		tostring(glow.thickness),
		tostring(background.enabled),
		colorKey(background.color),
		tostring(border.enabled),
		tostring(border.texture),
		tostring(border.size),
		tostring(border.offset),
		colorKey(border.color),
		tostring(fontVersion),
		tostring(state.interruptSpellId or ""),
	}, "|")
end

function Tracker:InvalidateLayout()
	state.layoutKey = nil
	state.layoutDirty = true
end

local function seedEditModeRecordFromProfile(record)
	if type(record) ~= "table" then return end
	local source = Tracker:BuildLayoutRecordFromProfile()
	for key, value in pairs(source) do
		record[key] = value
	end
end

function Tracker:ResolveTextFont()
	local cfg = self:GetConfig()
	local fallback = (addon.functions and addon.functions.GetLocaleDefaultFontFace and addon.functions.GetLocaleDefaultFontFace()) or addon.variables.defaultFont or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(cfg.textFont, fallback) end
	return fallback
end

local function isSafeNumber(value)
	if type(value) ~= "number" then return false end
	if issecretvalue and issecretvalue(value) then return false end
	return value == value
end

local function resolveConfiguredSound(value)
	local soundKey = trimString(value)
	if not soundKey then return nil, nil end

	local numeric = tonumber(soundKey)
	if numeric and numeric > 0 then return numeric, "kit" end

	local soundHash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("sound")
	if type(soundHash) == "table" then
		local file = soundHash[soundKey]
		if type(file) == "string" and file ~= "" then return file, "file" end
	end

	if LSM and LSM.Fetch then
		local file = LSM:Fetch("sound", soundKey, true)
		if type(file) == "string" and file ~= "" then return file, "file" end
	end

	if isLikelyFilePath(soundKey) then return soundKey, "file" end

	return nil, nil
end

local function playConfiguredSound(value)
	local resolved, kind = resolveConfiguredSound(value)
	if not resolved or not kind then return end
	if kind == "kit" then
		if PlaySound then PlaySound(resolved, "Master") end
		return
	end
	if PlaySoundFile then PlaySoundFile(resolved, "Master") end
end

local function applyNonInterruptibleAlpha(target, notInterruptible)
	if not target then return end
	if target.SetAlphaFromBoolean then
		target:SetAlphaFromBoolean(notInterruptible, 0, 1)
	elseif target.SetAlpha then
		if type(notInterruptible) == "boolean" then
			target:SetAlpha(notInterruptible and 0 or 1)
		else
			target:SetAlpha(1)
		end
	end
end

local function isSpellCooldownInfoActive(cooldownIsActive, cooldownEnabled, startTime, duration)
	if not (issecretvalue and issecretvalue(cooldownIsActive)) and type(cooldownIsActive) == "boolean" then return cooldownIsActive end
	if cooldownEnabled == false then return false end
	if not isSafeNumber(startTime) or not isSafeNumber(duration) then return false end
	if duration <= 0 or startTime <= 0 then return false end
	if not GetTime then return false end
	return (startTime + duration) > GetTime()
end

local function querySpellCooldown(spellId)
	if not spellId or not GetSpellCooldownInfo then
		return {
			isEnabled = false,
			isOnGCD = nil,
			isActive = false,
		}
	end

	local a, b, c, d = GetSpellCooldownInfo(spellId)
	if type(a) == "table" then
		return {
			isEnabled = a.isEnabled,
			isOnGCD = a.isOnGCD,
			isActive = a.isActive == true,
		}
	end

	local startTime = a or 0
	local duration = b or 0
	local isEnabled = c
	return {
		isEnabled = isEnabled,
		isOnGCD = nil,
		isActive = isSpellCooldownInfoActive(nil, isEnabled, startTime, duration),
	}
end

local function buildInterruptCandidates(classTag, specId)
	if classTag == "DRUID" then
		if specId == 102 then return { 78675, 106839 } end
		return { 106839, 78675 }
	end
	if classTag == "HUNTER" then
		if specId == 255 then return { 187707, 147362 } end
		return { 147362, 187707 }
	end
	return copyValue(CLASS_INTERRUPT_SPELLS[classTag] or {})
end

function Tracker:RebuildInterruptSpellCache()
	local classTag = select(2, UnitClass("player"))
	if type(classTag) ~= "string" or classTag == "" then
		state.interruptSpellCacheKey = nil
		state.interruptSpellCacheDirty = false
		state.interruptSpellId = nil
		return nil
	end

	local specId
	if GetSpecialization and GetSpecializationInfo then
		local specIndex = GetSpecialization()
		if specIndex then specId = GetSpecializationInfo(specIndex) end
	end

	local cacheKey = tostring(classTag) .. ":" .. tostring(specId or "")
	local candidates = buildInterruptCandidates(classTag, specId)
	for i = 1, #candidates do
		local spellId = tonumber(candidates[i])
		if spellId and IsSpellKnown(spellId, true) then
			state.interruptSpellCacheKey = cacheKey
			state.interruptSpellCacheDirty = false
			state.interruptSpellId = spellId
			return spellId
		end
	end

	state.interruptSpellCacheKey = cacheKey
	state.interruptSpellCacheDirty = false
	state.interruptSpellId = nil
	return nil
end

function Tracker:ResolveInterruptSpell()
	if state.interruptSpellCacheDirty == true or state.interruptSpellCacheKey == nil then return self:RebuildInterruptSpellCache() end
	return state.interruptSpellId
end

function Tracker:InvalidateInterruptSpellCache()
	state.interruptSpellCacheKey = nil
	state.interruptSpellCacheDirty = true
	state.interruptSpellId = nil
	self:InvalidateLayout()
end

function Tracker:RefreshInterruptSpellCache()
	self:InvalidateInterruptSpellCache()
	return self:RebuildInterruptSpellCache()
end

function Tracker:IsInterruptSpell(spellId)
	spellId = tonumber(spellId)
	return spellId and ALL_INTERRUPT_SPELLS[spellId] == true or false
end

function Tracker:GetTrackedSpellCooldown()
	local spellId = state.interruptSpellId
	if state.interruptSpellCacheDirty == true or state.interruptSpellCacheKey == nil then spellId = self:RebuildInterruptSpellCache() end
	if not spellId then return nil end
	local cooldown = querySpellCooldown(spellId)
	cooldown.spellId = spellId
	return cooldown
end

function Tracker:GetInterruptSpellCooldown(spellId)
	spellId = tonumber(spellId)
	if not self:IsInterruptSpell(spellId) then return nil end
	local cooldown = querySpellCooldown(spellId)
	cooldown.spellId = spellId
	return cooldown
end

function Tracker:IsTrackedSpellReady(cooldown)
	if type(cooldown) ~= "table" or not cooldown.spellId then return false end
	if cooldown.isEnabled == false then return false end
	if cooldown.isActive == true then return false end
	return true
end

function Tracker:IsInterruptSpellReady(spellId)
	return self:IsTrackedSpellReady(self:GetInterruptSpellCooldown(spellId))
end

function Tracker:HasHostileFocus()
	if not UnitExists or UnitExists("focus") ~= true then return false end
	if UnitCanAttack then return UnitCanAttack("player", "focus") == true end
	if UnitIsFriend then return UnitIsFriend("player", "focus") ~= true end
	return true
end

function Tracker:HasHostileUnit(unit)
	unit = unit or "focus"
	if not UnitExists or UnitExists(unit) ~= true then return false end
	if UnitCanAttack then return UnitCanAttack("player", unit) == true end
	if UnitIsFriend then return UnitIsFriend("player", unit) ~= true end
	return true
end

function Tracker:GetUnitInterruptibleCast(unit)
	unit = unit or "focus"
	if not self:HasHostileUnit(unit) then return nil end

	local name, _, _, _, _, _, castId, notInterruptible, spellId = UnitCastingInfo(unit)
	if name then
		return {
			hasCast = true,
			spellId = spellId,
			rawNotInterruptible = notInterruptible,
			castId = castId,
		}
	end

	name, _, _, _, _, _, notInterruptible, spellId = UnitChannelInfo(unit)
	if name then
		return {
			hasCast = true,
			spellId = spellId,
			rawNotInterruptible = notInterruptible,
		}
	end

	return nil
end

function Tracker:GetFocusInterruptibleCast()
	return self:GetUnitInterruptibleCast("focus")
end

function Tracker:GetTargetInterruptibleCast()
	return self:GetUnitInterruptibleCast("target")
end

function Tracker:ResolveDisplayIcon(spellId)
	local cfg = self:GetConfig()
	local customIcon = normalizeCustomIcon(cfg.customIcon)
	if customIcon ~= nil then return customIcon end
	if spellId and C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellId)
		if texture then return texture end
	end
	if spellId and GetSpellTexture then
		local texture = GetSpellTexture(spellId)
		if texture then return texture end
	end
	return DEFAULT_PREVIEW_ICON
end

local function applyTexture(texture, value)
	if not texture then return end
	if type(value) == "string" and value:match("^atlas:") then
		texture:SetTexture(nil)
		texture:SetAtlas(value:sub(7), true)
		return
	end
	texture:SetAtlas(nil)
	texture:SetTexture(value)
end

function Tracker:EnsureFrame()
	if state.frame then return state.frame end

	local frame = CreateFrame("Frame", "EQOLFocusInterruptTracker", UIParent)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(false)

	frame.editBg = frame:CreateTexture(nil, "BACKGROUND")
	frame.editBg:SetAllPoints(frame)
	frame.editBg:SetColorTexture(0, 0, 0, 0.35)
	frame.editBg:Hide()

	frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	frame.bg:SetAllPoints(frame)
	frame.bg:Hide()

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)
	frame.border:Hide()

	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.text:SetJustifyH("CENTER")
	frame.text:SetJustifyV("MIDDLE")
	frame.text:SetWordWrap(false)

	state.frame = frame
	return frame
end

function Tracker:ApplyLayoutData(data)
	local cfg = self:GetConfig()
	local record = type(data) == "table" and data or {}

	if record.point ~= nil then cfg.anchor.point = normalizeAnchorPoint(record.point, cfg.anchor.point) end
	if record.relativePoint ~= nil then cfg.anchor.relativePoint = normalizeAnchorPoint(record.relativePoint, cfg.anchor.relativePoint) end
	if record.x ~= nil then cfg.anchor.x = clampInt(record.x, -4096, 4096, cfg.anchor.x) end
	if record.y ~= nil then cfg.anchor.y = clampInt(record.y, -4096, 4096, cfg.anchor.y) end
	if record.anchorTarget ~= nil then cfg.anchor.relativeFrame = trimString(record.anchorTarget) or "AUTO" end

	if record.displayMode ~= nil then cfg.displayMode = normalizeDisplayMode(record.displayMode, cfg.displayMode) end
	if record.text ~= nil then cfg.text = trimString(record.text) or DEFAULT_PREVIEW_TEXT end
	if record.textFont ~= nil then cfg.textFont = record.textFont or defaults.textFont end
	if record.textSize ~= nil then cfg.textSize = clampInt(record.textSize, 8, 96, cfg.textSize) end
	if record.textOutline ~= nil then cfg.textOutline = normalizeOutline(record.textOutline, cfg.textOutline) end
	if record.textColor ~= nil then cfg.textColor = normalizeColor(record.textColor, cfg.textColor) end

	if record.iconSize ~= nil then cfg.iconSize = clampInt(record.iconSize, 8, 128, cfg.iconSize) end
	if record.customIcon ~= nil then cfg.customIcon = normalizeCustomIcon(record.customIcon) end
	if record.glowEnabled ~= nil then cfg.glow.enabled = record.glowEnabled == true end
	if record.glowStyle ~= nil then cfg.glow.style = normalizeGlowStyle(record.glowStyle, cfg.glow.style, cfg.displayMode) end
	if record.glowColor ~= nil then cfg.glow.color = normalizeColor(record.glowColor, cfg.glow.color) end
	if record.glowInset ~= nil then cfg.glow.inset = clampInt(record.glowInset, GLOW_INSET_MIN, GLOW_INSET_MAX, cfg.glow.inset) end
	if record.glowPixelBorder ~= nil then cfg.glow.pixelBorder = record.glowPixelBorder == true end
	if record.glowPixelCount ~= nil then cfg.glow.pixelCount = clampInt(record.glowPixelCount, GLOW_PIXEL_COUNT_MIN, GLOW_PIXEL_COUNT_MAX, cfg.glow.pixelCount) end
	if record.glowPixelSpeed ~= nil then cfg.glow.pixelSpeed = clampNumber(record.glowPixelSpeed, GLOW_PIXEL_SPEED_MIN, GLOW_PIXEL_SPEED_MAX, cfg.glow.pixelSpeed) end
	if record.glowThickness ~= nil then cfg.glow.thickness = clampInt(record.glowThickness, GLOW_THICKNESS_MIN, GLOW_THICKNESS_MAX, cfg.glow.thickness) end
	cfg.glow.style = normalizeGlowStyle(cfg.glow.style, cfg.glow.style, cfg.displayMode)

	if record.backgroundEnabled ~= nil then cfg.background.enabled = record.backgroundEnabled == true end
	if record.backgroundColor ~= nil then cfg.background.color = normalizeColor(record.backgroundColor, cfg.background.color) end

	if record.borderEnabled ~= nil then cfg.border.enabled = record.borderEnabled == true end
	if record.borderTexture ~= nil then cfg.border.texture = record.borderTexture or defaults.border.texture end
	if record.borderSize ~= nil then cfg.border.size = clampInt(record.borderSize, 1, 32, cfg.border.size) end
	if record.borderOffset ~= nil then cfg.border.offset = clampInt(record.borderOffset, -20, 20, cfg.border.offset) end
	if record.borderColor ~= nil then cfg.border.color = normalizeColor(record.borderColor, cfg.border.color) end

	if record.strata ~= nil then cfg.strata = normalizeStrata(record.strata, cfg.strata) end

	local frame = state.frame
	if not frame then return end

	frame:SetFrameStrata(cfg.strata)
	if not self:ApplyDynamicAnchor() then
		frame:ClearAllPoints()
		frame:SetPoint(cfg.anchor.point, self:ResolveAnchorFrame(), cfg.anchor.relativePoint, cfg.anchor.x, cfg.anchor.y)
	end

	frame.border:SetFrameStrata(frame:GetFrameStrata())
	frame.border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)

	local displayMode = cfg.displayMode
	local isText = displayMode == "TEXT"
	local previewSpell = self:ResolveInterruptSpell()
	local previewText = cfg.text or DEFAULT_PREVIEW_TEXT
	local width, height

	if isText then
		local fontPath = self:ResolveTextFont()
		local fontStyleChoice = normalizeOutline(cfg.textOutline, defaults.textOutline)
		local fontOutline = resolveFontFlags(fontStyleChoice, defaults.textOutline)
		local ok = false
		if addon.functions and addon.functions.ApplyFontString then
			ok = addon.functions.ApplyFontString(frame.text, fontPath, cfg.textSize, fontStyleChoice, STANDARD_TEXT_FONT, defaults.textOutline)
		else
			ok = frame.text:SetFont(fontPath, cfg.textSize, fontOutline)
			if ok == false then ok = frame.text:SetFont(STANDARD_TEXT_FONT, cfg.textSize, fontOutline) end
		end
		if ok == false then frame.text:SetFont(STANDARD_TEXT_FONT, cfg.textSize, fontOutline) end
		if addon.functions and addon.functions.ApplyFontStyleShadow then
			addon.functions.ApplyFontStyleShadow(frame.text, fontStyleChoice, defaults.textOutline)
		end
		local color = normalizeColor(cfg.textColor, defaults.textColor)
		frame.text:SetTextColor(color[1], color[2], color[3], color[4])
		frame.text:SetText(previewText)
		frame.text:Show()
		frame.icon:Hide()
		frame.border:Hide()
		width = math.max(math.floor((frame.text:GetStringWidth() or 0) + 14 + 0.5), 48)
		height = math.max(math.floor((frame.text:GetStringHeight() or 0) + 10 + 0.5), 20)
	else
		applyTexture(frame.icon, self:ResolveDisplayIcon(previewSpell))
		frame.icon:SetSize(cfg.iconSize, cfg.iconSize)
		frame.icon:Show()
		frame.text:Hide()
		width = cfg.iconSize
		height = cfg.iconSize

		if cfg.border.enabled then
			frame.border:SetBackdrop({
				edgeFile = resolveBorderTexture(cfg.border.texture),
				edgeSize = cfg.border.size,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			local borderColor = normalizeColor(cfg.border.color, defaults.border.color)
			frame.border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
			frame.border:SetBackdropColor(0, 0, 0, 0)
			frame.border:ClearAllPoints()
			frame.border:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -cfg.border.offset, cfg.border.offset)
			frame.border:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", cfg.border.offset, -cfg.border.offset)
			frame.border:Show()
		else
			frame.border:SetBackdrop(nil)
			frame.border:Hide()
		end
	end

	frame:SetSize(width, height)
	if state.glowVisible then self:UpdateGlow(true) end
	if cfg.background.enabled then
		local bgColor = normalizeColor(cfg.background.color, defaults.background.color)
		frame.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
		frame.bg:Show()
	else
		frame.bg:Hide()
	end
	frame.editBg:SetShown(state.previewing == true)
	state.layoutKey = buildLayoutKey(cfg)
	state.layoutDirty = false
end

function Tracker:UpdateGlow(visible)
	local frame = state.frame
	local cfg = self:GetConfig()
	local glow = cfg and cfg.glow
	if not (visible and frame and glow and glow.enabled and addon.Glow and addon.Glow.Start and addon.Glow.Stop) then
		if frame and addon.Glow and addon.Glow.Stop then addon.Glow.Stop(frame, FOCUS_GLOW_KEY, true) end
		state.glowVisible = false
		state.glowStyle = nil
		state.glowColorKey = nil
		state.glowOptionsKey = nil
		return
	end

	local currentColorKey = colorKey(glow.color)
	local currentOptionsKey = table.concat({ tostring(glow.inset), tostring(glow.pixelBorder), tostring(glow.pixelCount), tostring(glow.pixelSpeed), tostring(glow.thickness) }, ":")
	if state.glowVisible and state.glowStyle == glow.style and state.glowColorKey == currentColorKey and state.glowOptionsKey == currentOptionsKey and (not addon.Glow.IsActive or addon.Glow.IsActive(frame, FOCUS_GLOW_KEY)) then return end
	addon.Glow.Start(frame, FOCUS_GLOW_KEY, glow.style, {
		color = glow.color,
		inset = glow.inset,
		border = glow.pixelBorder,
		count = glow.pixelCount,
		frequency = glow.pixelSpeed,
		thickness = glow.thickness,
	})
	state.glowVisible = true
	state.glowStyle = glow.style
	state.glowColorKey = currentColorKey
	state.glowOptionsKey = currentOptionsKey
end

local function glowStyleUsesThickness(style)
	return style == "PIXEL" or style == "PULSING" or style == "MARCHING_ANTS" or style == "FLASH"
end

local function isPixelGlowStyle()
	return Tracker:GetConfig().glow.style == "PIXEL"
end

local function isGlowThicknessStyle()
	return glowStyleUsesThickness(Tracker:GetConfig().glow.style)
end

function Tracker:EnsureLayoutApplied()
	local frame = state.frame
	if not frame then return end
	local cfg = self:GetConfig()
	local key = buildLayoutKey(cfg)
	if state.layoutDirty ~= true and state.layoutKey == key then return end
	self:ApplyLayoutData()
end

local function refreshEditModeFrame()
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

local function refreshEditModeSettingValues()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
		addon.EditModeLib.internal:RefreshSettingValues()
	end
end

local function syncEditModeValue(field, value)
	if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, field, value, nil, true) end
end

local function syncEditModeLayoutFromAnchor()
	if not (EditMode and EditMode.GetActiveLayoutName and EditMode.SetValue) then return end

	local cfg = Tracker:GetConfig()
	local anchor = cfg and cfg.anchor
	if not anchor or (anchor.relativeFrame or "UIParent") ~= "UIParent" then return end

	local layout = EditMode:GetActiveLayoutName()
	local point = anchor.point or "CENTER"
	local relativePoint = anchor.relativePoint or point
	local x = anchor.x or 0
	local y = anchor.y or 0

	EditMode:SetValue(EDITMODE_ID, "point", point, layout, true)
	EditMode:SetValue(EDITMODE_ID, "relativePoint", relativePoint, layout, true)
	EditMode:SetValue(EDITMODE_ID, "x", x, layout, true)
	EditMode:SetValue(EDITMODE_ID, "y", y, layout, true)
end

function Tracker:ApplyEditModeSetting(field, value)
	local payload
	local editField = field

	if field == "anchorTarget" then
		payload = { anchorTarget = value }
	elseif field == "point" then
		payload = { point = value }
	elseif field == "relativePoint" then
		payload = { relativePoint = value }
	elseif field == "x" then
		payload = { x = value }
	elseif field == "y" then
		payload = { y = value }
	elseif field == "strata" then
		payload = { strata = value }
	else
		return
	end

	self:ApplyLayoutData(payload)
	syncEditModeLayoutFromAnchor()

	if EditMode and EditMode.SetValue then
		local cfg = self:GetConfig()
		local syncValue = value
		if field == "anchorTarget" then
			syncValue = cfg.anchor.relativeFrame
		elseif field == "point" then
			syncValue = cfg.anchor.point
		elseif field == "relativePoint" then
			syncValue = cfg.anchor.relativePoint
		elseif field == "x" then
			syncValue = cfg.anchor.x
		elseif field == "y" then
			syncValue = cfg.anchor.y
		elseif field == "strata" then
			syncValue = cfg.strata
		end
		EditMode:SetValue(EDITMODE_ID, editField, syncValue, nil, true)
	end

	refreshEditModeSettingValues()
	if field == "anchorTarget" then refreshEditModeFrame() end
end

function Tracker:Refresh()
	if not self:IsEnabled() then
		if state.frame then
			self:UpdateGlow(false)
			state.frame.editBg:Hide()
			state.frame:Hide()
		end
		return
	end

	if state.previewing ~= true and not self:HasHostileFocus() then
		if state.frame then
			self:UpdateGlow(false)
			state.frame:Hide()
		end
		return
	end

	local frame = self:EnsureFrame()
	self:EnsureLayoutApplied()

	local cooldown = self:GetTrackedSpellCooldown()
	local spellReady = self:IsTrackedSpellReady(cooldown)

	if state.previewing then
		frame:SetAlpha(1)
		self:UpdateGlow(true)
		frame:Show()
		return
	end

	if not spellReady then
		self:UpdateGlow(false)
		frame:Hide()
		return
	end

	local focusCast = self:GetFocusInterruptibleCast()
	if not focusCast then
		self:UpdateGlow(false)
		frame:Hide()
		return
	end
	local spellId = cooldown and cooldown.spellId or nil

	if self:GetConfig().displayMode == "ICON" then applyTexture(frame.icon, self:ResolveDisplayIcon(spellId)) end
	applyNonInterruptibleAlpha(frame, focusCast.rawNotInterruptible)
	self:UpdateGlow(true)
	frame:Show()
end

function Tracker:MaybePlayFocusCastSound()
	local cfg = self:GetConfig()
	local soundCfg = cfg and cfg.sound
	if not (cfg and cfg.enabled and soundCfg and soundCfg.enabled and soundCfg.file ~= "") then return end

	if not self:HasHostileFocus() then return end

	local cooldown = self:GetTrackedSpellCooldown()
	if not self:IsTrackedSpellReady(cooldown) then return end

	playConfiguredSound(soundCfg.file)
end

function Tracker:ShowEditModeHint(show)
	state.previewing = show == true
	if not self:IsEnabled() and show ~= true then
		if state.frame then
			state.frame.editBg:Hide()
			state.frame:Hide()
		end
		return
	end

	local frame = self:EnsureFrame()
	self:EnsureLayoutApplied()
	frame.editBg:SetShown(state.previewing == true)
	if state.previewing then
		frame:SetAlpha(1)
		self:UpdateGlow(true)
		frame:Show()
	else
		self:Refresh()
	end
end

function Tracker:EnsureEventFrame()
	if state.eventFrame then return state.eventFrame end

	local eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", function(_, event, ...)
		if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
			local unit = ...
			if unit ~= "focus" then return end
			Tracker:MaybePlayFocusCastSound()
			Tracker:Refresh()
			return
		end

		if event == "SPELL_UPDATE_COOLDOWN" then
			if not Tracker:HasHostileFocus() then return end
			local spellID, baseSpellID = ...
			local trackedSpellID = state.interruptSpellId
			if not trackedSpellID then
				Tracker:Refresh()
				return
			end

			if spellID == trackedSpellID or baseSpellID == trackedSpellID then
				Tracker:Refresh()
			end
			return
		end

		if event == "ADDON_LOADED" then
			local loadedAddon = ...
			if not EXTERNAL_ANCHOR_ADDONS[loadedAddon] then return end
			Tracker:InvalidateLayout()
			Tracker:Refresh()
			return
		end

		if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "UNIT_PET" then
			local unit = ...
			if unit ~= nil and unit ~= "player" then return end
			Tracker:RefreshInterruptSpellCache()
			Tracker:Refresh()
			return
		end

		if event == "SPELLS_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
			or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
			or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
			if event ~= "PLAYER_FOCUS_CHANGED" then Tracker:RefreshInterruptSpellCache() end
			Tracker:Refresh()
			return
		end

		local unit = ...
		if unit ~= "focus" then return end
		Tracker:Refresh()
	end)

	state.eventFrame = eventFrame
	return eventFrame
end

function Tracker:RegisterEvents()
	local frame = self:EnsureEventFrame()
	frame:UnregisterAllEvents()
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	frame:RegisterEvent("SPELLS_CHANGED")
	frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	frame:RegisterUnitEvent("UNIT_PET", "player")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "focus")
	frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "focus")
end

function Tracker:UnregisterEvents()
	if state.eventFrame then state.eventFrame:UnregisterAllEvents() end
end

function Tracker:UnregisterEditMode()
	if not state.editModeRegistered then return end
	if EditMode and EditMode.UnregisterFrame then EditMode:UnregisterFrame(EDITMODE_ID, false) end
	state.editModeRegistered = false
end

function Tracker:RegisterEditMode()
	if state.editModeRegistered or not (EditMode and EditMode.RegisterFrame) then return end

	local frame = self:EnsureFrame()
	local settings
	if SettingType then
		settings = {
			{
				name = L["Background"] or "Background",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerBackground",
				defaultCollapsed = true,
			},
			{
				name = L["Use background"] or "Use background",
				kind = SettingType.Checkbox,
				field = "backgroundEnabled",
				parentId = "focusInterruptTrackerBackground",
				get = function() return Tracker:GetConfig().background.enabled end,
				set = function(_, value) Tracker:ApplyLayoutData({ backgroundEnabled = value == true }) end,
			},
			{
				name = L["Background color"] or "Background color",
				kind = SettingType.Color,
				field = "backgroundColor",
				parentId = "focusInterruptTrackerBackground",
				hasOpacity = true,
				get = function()
					local color = Tracker:GetConfig().background.color
					return { r = color[1], g = color[2], b = color[3], a = color[4] }
				end,
				set = function(_, value) Tracker:ApplyLayoutData({ backgroundColor = value }) end,
				isEnabled = function() return Tracker:GetConfig().background.enabled end,
			},
			{
				name = L["Anchor"] or "Anchor",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerAnchor",
				defaultCollapsed = false,
			},
			{
				name = L["FocusInterruptTrackerAnchorTarget"] or "Anchor target",
				kind = SettingType.Dropdown,
				field = "anchorTarget",
				parentId = "focusInterruptTrackerAnchor",
				height = 180,
				get = function() return Tracker:GetConfig().anchor.relativeFrame end,
				set = function(_, value) Tracker:ApplyEditModeSetting("anchorTarget", value) end,
				generator = function(_, root)
					local current = Tracker:GetConfig().anchor.relativeFrame
					for i = 1, #AUTO_ANCHOR_OPTIONS do
						local option = AUTO_ANCHOR_OPTIONS[i]
						if option.value == current or hasAnchorFrame(option) then
							root:CreateRadio(option.label, function() return Tracker:GetConfig().anchor.relativeFrame == option.value end, function()
								Tracker:ApplyEditModeSetting("anchorTarget", option.value)
							end)
						end
					end
				end,
			},
			{
				name = L["Anchor point"] or "Anchor point",
				kind = SettingType.Dropdown,
				field = "point",
				parentId = "focusInterruptTrackerAnchor",
				height = 180,
				get = function() return Tracker:GetConfig().anchor.point end,
				set = function(_, value) Tracker:ApplyEditModeSetting("point", value) end,
				generator = function(_, root)
					for i = 1, #ANCHOR_POINTS do
						local point = ANCHOR_POINTS[i]
						root:CreateRadio(point, function() return Tracker:GetConfig().anchor.point == point end, function()
							Tracker:ApplyEditModeSetting("point", point)
						end)
					end
				end,
			},
			{
				name = L["Relative point"] or "Relative point",
				kind = SettingType.Dropdown,
				field = "relativePoint",
				parentId = "focusInterruptTrackerAnchor",
				height = 180,
				get = function() return Tracker:GetConfig().anchor.relativePoint end,
				set = function(_, value) Tracker:ApplyEditModeSetting("relativePoint", value) end,
				generator = function(_, root)
					for i = 1, #ANCHOR_POINTS do
						local point = ANCHOR_POINTS[i]
						root:CreateRadio(point, function() return Tracker:GetConfig().anchor.relativePoint == point end, function()
							Tracker:ApplyEditModeSetting("relativePoint", point)
						end)
					end
				end,
			},
			{
				name = L["X Offset"] or "X Offset",
				kind = SettingType.Slider,
				field = "x",
				parentId = "focusInterruptTrackerAnchor",
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().anchor.x end,
				set = function(_, value) Tracker:ApplyEditModeSetting("x", value) end,
			},
			{
				name = L["Y Offset"] or "Y Offset",
				kind = SettingType.Slider,
				field = "y",
				parentId = "focusInterruptTrackerAnchor",
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().anchor.y end,
				set = function(_, value) Tracker:ApplyEditModeSetting("y", value) end,
			},
			{
				name = L["Frame strata"] or "Frame strata",
				kind = SettingType.Dropdown,
				field = "strata",
				parentId = "focusInterruptTrackerAnchor",
				height = 180,
				get = function() return Tracker:GetConfig().strata end,
				set = function(_, value) Tracker:ApplyEditModeSetting("strata", value) end,
				generator = function(_, root)
					for i = 1, #STRATA_ORDER do
						local value = STRATA_ORDER[i]
						root:CreateRadio(value, function() return Tracker:GetConfig().strata == value end, function()
							Tracker:ApplyEditModeSetting("strata", value)
						end)
					end
				end,
			},
			{
				name = L["Display"] or "Display",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerDisplay",
				defaultCollapsed = false,
			},
			{
				name = DISPLAY_MODE,
				kind = SettingType.Dropdown,
				field = "displayMode",
				parentId = "focusInterruptTrackerDisplay",
				height = 120,
				get = function() return Tracker:GetConfig().displayMode end,
				set = function(_, value)
					Tracker:ApplyLayoutData({ displayMode = value })
					syncEditModeValue("displayMode", Tracker:GetConfig().displayMode)
					refreshEditModeFrame()
				end,
				generator = function(_, root)
					root:CreateRadio(LOCALE_TEXT_LABEL, function() return Tracker:GetConfig().displayMode == "TEXT" end, function()
						Tracker:ApplyLayoutData({ displayMode = "TEXT" })
						syncEditModeValue("displayMode", "TEXT")
						refreshEditModeFrame()
					end)
					root:CreateRadio(L["Icon"] or "Icon", function() return Tracker:GetConfig().displayMode == "ICON" end, function()
						Tracker:ApplyLayoutData({ displayMode = "ICON" })
						syncEditModeValue("displayMode", "ICON")
						refreshEditModeFrame()
					end)
				end,
			},
			{
				name = L["Glow effect"] or "Glow effect",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerGlow",
				defaultCollapsed = true,
			},
			{
				name = L["Enable glow"] or "Enable glow",
				kind = SettingType.Checkbox,
				field = "glowEnabled",
				parentId = "focusInterruptTrackerGlow",
				get = function() return Tracker:GetConfig().glow.enabled end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowEnabled = value == true }) end,
			},
			{
				name = L["Glow style"] or "Glow style",
				kind = SettingType.Dropdown,
				field = "glowStyle",
				parentId = "focusInterruptTrackerGlow",
				height = 180,
				get = function() return Tracker:GetConfig().glow.style end,
				set = function(_, value)
					Tracker:ApplyLayoutData({ glowStyle = value })
					syncEditModeValue("glowStyle", Tracker:GetConfig().glow.style)
					refreshEditModeFrame()
				end,
				generator = function(_, root)
					for i = 1, #GLOW_STYLE_OPTIONS do
						local option = GLOW_STYLE_OPTIONS[i]
						if Tracker:GetConfig().displayMode ~= "TEXT" or option.value == "PIXEL" or option.value == "PULSING" then
							local label = L[option.labelKey] or option.fallback
							root:CreateRadio(label, function() return Tracker:GetConfig().glow.style == option.value end, function()
								Tracker:ApplyLayoutData({ glowStyle = option.value })
								syncEditModeValue("glowStyle", Tracker:GetConfig().glow.style)
								refreshEditModeFrame()
							end)
						end
					end
				end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
			},
			{
				name = L["Glow color"] or "Glow color",
				kind = SettingType.Color,
				field = "glowColor",
				parentId = "focusInterruptTrackerGlow",
				hasOpacity = true,
				get = function()
					local color = Tracker:GetConfig().glow.color
					return { r = color[1], g = color[2], b = color[3], a = color[4] }
				end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowColor = value }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
			},
			{
				name = L["Glow inset"] or "Glow inset",
				kind = SettingType.Slider,
				field = "glowInset",
				parentId = "focusInterruptTrackerGlow",
				minValue = GLOW_INSET_MIN,
				maxValue = GLOW_INSET_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().glow.inset end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowInset = value }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
			},
			{
				name = L["CooldownPanelGlowThickness"] or "Glow thickness",
				kind = SettingType.Slider,
				field = "glowThickness",
				parentId = "focusInterruptTrackerGlow",
				minValue = GLOW_THICKNESS_MIN,
				maxValue = GLOW_THICKNESS_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().glow.thickness end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowThickness = value }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
				isShown = isGlowThicknessStyle,
			},
			{
				name = L["CooldownPanelPixelGlowLines"] or "Pixel glow lines",
				kind = SettingType.Slider,
				field = "glowPixelCount",
				parentId = "focusInterruptTrackerGlow",
				minValue = GLOW_PIXEL_COUNT_MIN,
				maxValue = GLOW_PIXEL_COUNT_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().glow.pixelCount end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowPixelCount = value }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
				isShown = isPixelGlowStyle,
			},
			{
				name = L["CooldownPanelPixelGlowSpeed"] or "Pixel glow speed",
				kind = SettingType.Slider,
				field = "glowPixelSpeed",
				parentId = "focusInterruptTrackerGlow",
				minValue = GLOW_PIXEL_SPEED_MIN,
				maxValue = GLOW_PIXEL_SPEED_MAX,
				valueStep = 0.05,
				allowInput = true,
				get = function() return Tracker:GetConfig().glow.pixelSpeed end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowPixelSpeed = value }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
				isShown = isPixelGlowStyle,
			},
			{
				name = L["CooldownPanelPixelGlowBorder"] or "Pixel glow border",
				kind = SettingType.Checkbox,
				field = "glowPixelBorder",
				parentId = "focusInterruptTrackerGlow",
				get = function() return Tracker:GetConfig().glow.pixelBorder end,
				set = function(_, value) Tracker:ApplyLayoutData({ glowPixelBorder = value == true }) end,
				isEnabled = function() return Tracker:GetConfig().glow.enabled end,
				isShown = isPixelGlowStyle,
			},
			{
				name = LOCALE_TEXT_LABEL,
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerText",
				defaultCollapsed = true,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["FocusInterruptTrackerText"] or "Tracker text",
				kind = SettingType.Input,
				field = "text",
				parentId = "focusInterruptTrackerText",
				inputWidth = 220,
				get = function() return Tracker:GetConfig().text end,
				set = function(_, value) Tracker:ApplyLayoutData({ text = value }) end,
				default = DEFAULT_PREVIEW_TEXT,
				maxChars = 32,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["Text font"] or "Text font",
				kind = SettingType.Dropdown,
				field = "textFont",
				parentId = "focusInterruptTrackerText",
				height = 200,
				get = function() return Tracker:GetConfig().textFont end,
				set = function(_, value) Tracker:ApplyLayoutData({ textFont = value }) end,
				generator = function(_, root)
					local options = getFontOptions()
					for i = 1, #options do
						local option = options[i]
						root:CreateRadio(option.label, function() return Tracker:GetConfig().textFont == option.value end, function()
							Tracker:ApplyLayoutData({ textFont = option.value })
						end)
					end
				end,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["Text size"] or "Text size",
				kind = SettingType.Slider,
				field = "textSize",
				parentId = "focusInterruptTrackerText",
				minValue = 8,
				maxValue = 96,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().textSize end,
				set = function(_, value) Tracker:ApplyLayoutData({ textSize = value }) end,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["Font outline"] or "Font outline",
				kind = SettingType.Dropdown,
				field = "textOutline",
				parentId = "focusInterruptTrackerText",
				height = 140,
				get = function() return Tracker:GetConfig().textOutline end,
				set = function(_, value) Tracker:ApplyLayoutData({ textOutline = value }) end,
				generator = function(_, root)
					for i = 1, #OUTLINE_OPTIONS do
						local option = OUTLINE_OPTIONS[i]
						local value = option.value
						local label = option.label or value
						root:CreateRadio(label, function() return Tracker:GetConfig().textOutline == value end, function()
							Tracker:ApplyLayoutData({ textOutline = value })
						end)
					end
				end,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["Text color"] or "Text color",
				kind = SettingType.Color,
				field = "textColor",
				parentId = "focusInterruptTrackerText",
				hasOpacity = true,
				get = function()
					local color = Tracker:GetConfig().textColor
					return { r = color[1], g = color[2], b = color[3], a = color[4] }
				end,
				set = function(_, value) Tracker:ApplyLayoutData({ textColor = value }) end,
				isShown = function() return Tracker:GetConfig().displayMode == "TEXT" end,
			},
			{
				name = L["Icon"] or "Icon",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerIcon",
				defaultCollapsed = true,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Icon size"] or "Icon size",
				kind = SettingType.Slider,
				field = "iconSize",
				parentId = "focusInterruptTrackerIcon",
				minValue = 8,
				maxValue = 128,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().iconSize end,
				set = function(_, value) Tracker:ApplyLayoutData({ iconSize = value }) end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["FocusInterruptTrackerCustomIcon"] or "Custom icon",
				kind = SettingType.Input,
				field = "customIcon",
				parentId = "focusInterruptTrackerIcon",
				inputWidth = 220,
				get = function()
					local value = Tracker:GetConfig().customIcon
					return value and tostring(value) or ""
				end,
				set = function(_, value) Tracker:ApplyLayoutData({ customIcon = value }) end,
				default = "",
				maxChars = 128,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Border"] or "Border",
				kind = SettingType.Collapsible,
				id = "focusInterruptTrackerBorder",
				defaultCollapsed = true,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Use border"] or "Use border",
				kind = SettingType.Checkbox,
				field = "borderEnabled",
				parentId = "focusInterruptTrackerBorder",
				get = function() return Tracker:GetConfig().border.enabled end,
				set = function(_, value) Tracker:ApplyLayoutData({ borderEnabled = value == true }) end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Border texture"] or "Border texture",
				kind = SettingType.Dropdown,
				field = "borderTexture",
				parentId = "focusInterruptTrackerBorder",
				height = 180,
				get = function() return Tracker:GetConfig().border.texture end,
				set = function(_, value) Tracker:ApplyLayoutData({ borderTexture = value }) end,
				generator = function(_, root)
					local options = getBorderOptions()
					for i = 1, #options do
						local option = options[i]
						root:CreateRadio(option.label, function() return Tracker:GetConfig().border.texture == option.value end, function()
							Tracker:ApplyLayoutData({ borderTexture = option.value })
						end)
					end
				end,
				isEnabled = function() return Tracker:GetConfig().border.enabled end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Border size"] or "Border size",
				kind = SettingType.Slider,
				field = "borderSize",
				parentId = "focusInterruptTrackerBorder",
				minValue = 1,
				maxValue = 32,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().border.size end,
				set = function(_, value) Tracker:ApplyLayoutData({ borderSize = value }) end,
				isEnabled = function() return Tracker:GetConfig().border.enabled end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = L["Border offset"] or "Border offset",
				kind = SettingType.Slider,
				field = "borderOffset",
				parentId = "focusInterruptTrackerBorder",
				minValue = -20,
				maxValue = 20,
				valueStep = 1,
				allowInput = true,
				get = function() return Tracker:GetConfig().border.offset end,
				set = function(_, value) Tracker:ApplyLayoutData({ borderOffset = value }) end,
				isEnabled = function() return Tracker:GetConfig().border.enabled end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
			{
				name = EMBLEM_BORDER_COLOR,
				kind = SettingType.Color,
				field = "borderColor",
				parentId = "focusInterruptTrackerBorder",
				hasOpacity = true,
				get = function()
					local color = Tracker:GetConfig().border.color
					return { r = color[1], g = color[2], b = color[3], a = color[4] }
				end,
				set = function(_, value) Tracker:ApplyLayoutData({ borderColor = value }) end,
				isEnabled = function() return Tracker:GetConfig().border.enabled end,
				isShown = function() return Tracker:GetConfig().displayMode == "ICON" end,
			},
		}
		if addon.DynamicAnchors then
			addon.DynamicAnchors:AddEditModeAssignmentSettings(settings, SettingType, {
				consumerId = self.dynamicAnchorId,
				parentId = "focusInterruptTrackerAnchor",
				insertAfterId = "focusInterruptTrackerAnchor",
				refresh = function(rebuild)
					if rebuild and EditMode and EditMode.RefreshFrame then
						EditMode:RefreshFrame(EDITMODE_ID)
						RunNextFrame(function() Tracker:ApplyDynamicAnchor() end)
					else
						Tracker:ApplyDynamicAnchor()
					end
				end,
				staticFields = { anchorTarget = true, point = true, relativePoint = true, x = true, y = true },
			})
		end
	end

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = frame,
		title = L["FocusInterruptTracker"] or "Focus Interrupt Tracker",
		layoutDefaults = self:BuildLayoutRecordFromProfile(),
		onApply = function(_, _, data)
			if not state.editModeHydrated then
				state.editModeHydrated = true
				local record = data or {}
				seedEditModeRecordFromProfile(record)
				Tracker:ApplyLayoutData(record)
				syncEditModeLayoutFromAnchor()
				refreshEditModeSettingValues()
				return
			end
			local record = type(data) == "table" and copyValue(data) or {}
			if not Tracker:AnchorUsesUIParent() then
				record.point = nil
				record.relativePoint = nil
				record.x = nil
				record.y = nil
			end
			Tracker:ApplyLayoutData(record)
			syncEditModeLayoutFromAnchor()
			refreshEditModeSettingValues()
		end,
		onEnter = function()
			Tracker:ShowEditModeHint(true)
			if addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(Tracker.dynamicAnchorId) then RunNextFrame(function() Tracker:ApplyDynamicAnchor() end) end
		end,
		onExit = function() Tracker:ShowEditModeHint(false) end,
		isEnabled = function() return Tracker:IsEnabled() end,
		settings = settings,
		relativeTo = function()
			local winner = Tracker:GetDynamicAnchorWinner()
			return winner and winner.frame or Tracker:ResolveAnchorFrame()
		end,
		allowDrag = function()
			return not (addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(Tracker.dynamicAnchorId)) and Tracker:AnchorUsesUIParent()
		end,
		managePosition = false,
		persistPosition = false,
		settingsMaxHeight = DEFAULT_SETTINGS_MAX_HEIGHT,
		showOutsideEditMode = false,
		collapseExclusive = true,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
	})

	state.editModeRegistered = true
end

function Tracker:OnSettingChanged(enabled)
	local cfg = self:GetConfig()
	cfg.enabled = enabled == true

	if cfg.enabled then
		if addon.DynamicAnchors then
			addon.DynamicAnchors:RegisterSimpleFrame({
				id = self.dynamicAnchorId,
				owner = addonName,
				label = L["FocusInterruptTracker"] or "Focus Interrupt Tracker",
				menuGroup = "TRACKERS",
				menuGroupLabel = L["Dynamic Anchor Group Trackers"],
				menuGroupOrder = 400,
				getFrame = function() return state.frame end,
				isAvailable = function(trackerFrame) return Tracker:IsEnabled() and trackerFrame ~= nil and trackerFrame:IsShown() end,
				apply = function() Tracker:ApplyDynamicAnchor() end,
			})
		end
		self:EnsureFrame()
		self:InvalidateLayout()
		self:RefreshInterruptSpellCache()
		self:RegisterEditMode()
		self:RegisterEvents()
		self:Refresh()
	else
		self:UnregisterEvents()
		self:UnregisterEditMode()
		self:UpdateGlow(false)
		state.previewing = false
		state.editModeHydrated = false
		if state.frame then
			state.frame.editBg:Hide()
			state.frame:Hide()
		end
	end

	refreshEditModeFrame()
end

return Tracker
