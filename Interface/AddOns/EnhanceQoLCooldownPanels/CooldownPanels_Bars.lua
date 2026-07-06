local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CooldownPanels = addon.Aura.CooldownPanels
local Helper = CooldownPanels.helper or {}
local Api = Helper.Api or {}
local Pixel = addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFramesHelper and addon.Aura.UF.GroupFramesHelper.Pixel or nil
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local LSM = LibStub("LibSharedMedia-3.0", true)

CooldownPanels.Bars = CooldownPanels.Bars or {}
local Bars = CooldownPanels.Bars
if Bars._eqolSupplementLoaded == true then return end
Bars._eqolSupplementLoaded = true
Bars.STANDALONE_STACKS_SECTION_ID = Bars.STANDALONE_STACKS_SECTION_ID or "eqolCooldownPanelStandaloneBarStacks"

Bars.GetGlobalFontStyleKey = Bars.GetGlobalFontStyleKey
	or function()
		if addon.functions and addon.functions.GetGlobalFontStyleConfigKey then return addon.functions.GetGlobalFontStyleConfigKey() end
		return "__EQOL_GLOBAL_FONT_STYLE__"
	end

local CreateFrame = CreateFrame
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local tonumber = tonumber
local tostring = tostring
local type = type
local ipairs = ipairs
local pairs = pairs
local format = string.format
local CooldownFrame_Clear = _G.CooldownFrame_Clear
local floor = math.floor
local min = math.min
local max = math.max
local next = next
local strfind = string.find
local unpack = (table and rawget(table, "unpack")) or unpack
local wipe = table.wipe or function(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

local function getEditor()
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime["editor"]
	return runtime and runtime.editor or nil
end

local getRuntimeState
local buildBarState
local layoutBarFrame

Bars.DISPLAY_MODE = Bars.DISPLAY_MODE or {
	BUTTON = "BUTTON",
	BAR = "BAR",
}

Bars.BAR_MODE = Bars.BAR_MODE or {
	COOLDOWN = "COOLDOWN",
	CHARGES = "CHARGES",
	STACKS = "STACKS",
}

Bars.TEXT_ANCHOR = Bars.TEXT_ANCHOR or {
	AUTO = "AUTO",
	LEFT = "LEFT",
	RIGHT = "RIGHT",
	CENTER = "CENTER",
	TOP = "TOP",
	BOTTOM = "BOTTOM",
}

Bars.DEFAULTS = Bars.DEFAULTS
	or {
		displayMode = Bars.DISPLAY_MODE.BUTTON,
		barMode = Bars.BAR_MODE.COOLDOWN,
		barSpan = 2,
		barWidth = 0,
		barHeight = 26,
		barTexture = "SOLID",
		barColor = { 0.98, 0.74, 0.22, 0.96 },
		barBackgroundColor = { 0.05, 0.05, 0.05, 0.82 },
		barBorderEnabled = true,
		barBorderColor = { 0.85, 0.85, 0.85, 0.90 },
		barBorderTexture = "DEFAULT",
		barBorderOffset = 0,
		barBorderSize = 1,
		barOffsetX = 0,
		barOffsetY = 0,
		barOrientation = "HORIZONTAL",
		barReverseFill = false,
		barSegmentDirection = "HORIZONTAL",
		barSegmentReverse = false,
		barProcGlowColor = { 0.35, 0.75, 1.00, 0.95 },
		barShowIcon = true,
		barShowLabel = true,
		barShowValueText = true,
		barShowChargeDuration = false,
		barShowStackText = true,
		barIconSize = 18,
		barIconPosition = "LEFT",
		barIconOffsetX = 0,
		barIconOffsetY = 0,
		barChargesSegmented = false,
		barChargesGap = 2,
		barStacksSegmented = false,
		barStackSeparatedOffset = 0,
		barStackDividerColor = { 0.10, 0.10, 0.10, 0.95 },
		barStackDividerThickness = 1,
		barStackMax = 10,
		barStackAnchor = "AUTO",
		barStackFont = "",
		barStackOffsetX = 0,
		barStackOffsetY = 0,
		barStackSize = 11,
		barStackStyle = Bars.GetGlobalFontStyleKey(),
		barStackColor = { 1.00, 1.00, 1.00, 0.95 },
		barLabelAnchor = "AUTO",
		barLabelFont = "",
		barLabelOffsetX = 0,
		barLabelOffsetY = 0,
		barLabelSize = 11,
		barLabelStyle = Bars.GetGlobalFontStyleKey(),
		barLabelColor = { 1.00, 1.00, 1.00, 0.95 },
		barValueAnchor = "AUTO",
		barValueFont = "",
		barValueOffsetX = 0,
		barValueOffsetY = 0,
		barValueSize = 11,
		barValueStyle = Bars.GetGlobalFontStyleKey(),
		barValueColor = { 1.00, 0.95, 0.75, 0.95 },
		barDurationTextProfile = "MINIMAL",
	}

Bars.COLORS = Bars.COLORS
	or {
		COOLDOWN = { 0.98, 0.74, 0.22, 0.96 },
		CHARGES = { 0.24, 0.64, 1.00, 0.96 },
		STACKS = { 0.30, 0.88, 0.46, 0.96 },
		Background = { 0.05, 0.05, 0.05, 0.82 },
		Border = { 0.85, 0.85, 0.85, 0.90 },
		Label = { 1.00, 1.00, 1.00, 0.95 },
		Value = { 1.00, 0.95, 0.75, 0.95 },
		Reserved = { 0.95, 0.82, 0.25, 0.80 },
	}

local BAR_TEXTURE_DEFAULT = "DEFAULT"
local BAR_BORDER_TEXTURE_DEFAULT = "DEFAULT"
local BAR_HEIGHT_MIN = 5
local BAR_HEIGHT_MAX = 2000
local BAR_WIDTH_MIN = 5
local BAR_WIDTH_MAX = 2000
local BAR_BORDER_SIZE_MIN = 0
local BAR_BORDER_SIZE_MAX = 64
local BAR_BORDER_OFFSET_MIN = -64
local BAR_BORDER_OFFSET_MAX = 64
local BAR_OFFSET_MIN = -2000
local BAR_OFFSET_MAX = 2000
local BAR_ICON_SIZE_MIN = 8
local BAR_ICON_SIZE_MAX = 128
local BAR_ICON_POSITION_LEFT = "LEFT"
local BAR_ICON_POSITION_RIGHT = "RIGHT"
local BAR_ICON_POSITION_TOP = "TOP"
local BAR_ICON_POSITION_BOTTOM = "BOTTOM"
local BAR_ORIENTATION_HORIZONTAL = "HORIZONTAL"
local BAR_ORIENTATION_VERTICAL = "VERTICAL"
local BAR_CHARGES_GAP_MIN = 0
local BAR_CHARGES_GAP_MAX = 2000
local BAR_STACK_DIVIDER_THICKNESS_MIN = 1
local BAR_STACK_DIVIDER_THICKNESS_MAX = 10
local BAR_FONT_SIZE_MIN = 6
local BAR_FONT_SIZE_MAX = 64
local BAR_TEXTURE_MENU_HEIGHT = 220
local cdp = {
	BAR_STATUS_INTERPOLATION_IMMEDIATE = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0,
	BAR_STATUS_TIMER_DIRECTION_ELAPSED = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime or 0,
	BAR_STATUS_TIMER_DIRECTION_REMAINING = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime or 1,
}
local getBarColor
local normalizeBarEntry
local refreshPanelContext
local refreshStandaloneEntryDialogForBars
local inferChargeBaseCount
local getDisplayedCharges
local getChargeBarProgress
local getChargeBarValueText
local sweepChargeDurationObjects
local setStatusBarImmediateValue
local setStatusBarTimerDuration
local getChargeSegmentDescriptors
local setBooleanAlpha
local shouldShowChargeSegmentFill
local refreshChargeBarRuntimeState

local function getSettingType()
	local lib = addon.EditModeLib or (addon.EditMode and addon.EditMode.lib)
	return lib and lib.SettingType or nil
end

local function normalizeId(value) return tonumber(value) end
local function isSecretValue(value) return Api.issecretvalue and Api.issecretvalue(value) end
local function hasTextValue(value)
	if type(value) ~= "string" then return false end
	if isSecretValue(value) then return true end
	return value ~= ""
end

local function getTextValue(value)
	if type(value) ~= "string" then return nil end
	if isSecretValue(value) then return value end
	if value ~= "" then return value end
	return nil
end

Bars.DEFAULT_TEXT_RGBA = Bars.DEFAULT_TEXT_RGBA or { 1, 1, 1, 1 }

function Bars.GetPlainNumber(value)
	if type(value) ~= "number" or isSecretValue(value) then return nil end
	if value ~= value or value == math.huge or value == -math.huge then return nil end
	return value
end

function Bars.ResolvePlainRGBA(value, fallback)
	fallback = fallback or Bars.DEFAULT_TEXT_RGBA
	if type(value) ~= "table" or isSecretValue(value) then return fallback[1], fallback[2], fallback[3], fallback[4] end
	local r = Bars.GetPlainNumber(value[1] or value.r)
	local g = Bars.GetPlainNumber(value[2] or value.g)
	local b = Bars.GetPlainNumber(value[3] or value.b)
	local a = Bars.GetPlainNumber(value[4] or value.a)
	return r or fallback[1] or 1, g or fallback[2] or 1, b or fallback[3] or 1, a or fallback[4] or 1
end

local function getOppositeTimerDirection(direction)
	if direction == cdp.BAR_STATUS_TIMER_DIRECTION_REMAINING then return cdp.BAR_STATUS_TIMER_DIRECTION_ELAPSED end
	return cdp.BAR_STATUS_TIMER_DIRECTION_REMAINING
end

local function safeNumber(value)
	if type(value) == "number" and not isSecretValue(value) then
		if value ~= value or value == math.huge or value == -math.huge then return nil end
		return value
	end
	if type(value) == "string" then
		if isSecretValue(value) then return nil end
		if value == "" then return nil end
		local numeric = tonumber(value)
		if numeric ~= nil and numeric == numeric and numeric ~= math.huge and numeric ~= -math.huge then return numeric end
	end
	return nil
end

local function isSafeLessThan(a, b)
	local lhs = safeNumber(a)
	local rhs = safeNumber(b)
	if not (lhs and rhs) then return false end
	return lhs < rhs
end

local function isLikelyFilePath(value)
	if not hasTextValue(value) or isSecretValue(value) then return false end
	return strfind(value, "[/\\]") ~= nil
end

local function clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function getStoredBoolean(entry, field, fallback)
	if type(entry) == "table" and type(entry[field]) == "boolean" then return entry[field] == true end
	return fallback == true
end

local function getCellKey(column, row) return tostring(column) .. ":" .. tostring(row) end

local function pixelSnap(value, effectiveScale)
	value = tonumber(value) or 0
	if Pixel and Pixel.Round then return Pixel.Round(value, effectiveScale) end
	local _, screenHeight = GetPhysicalScreenSize()
	local scale = effectiveScale
	if type(scale) ~= "number" then
		if scale and scale.GetEffectiveScale then
			scale = scale:GetEffectiveScale()
		elseif UIParent and UIParent.GetEffectiveScale then
			scale = UIParent:GetEffectiveScale()
		else
			scale = 1
		end
	end
	if screenHeight and screenHeight > 0 and scale and scale > 0 then
		local pixelMultiplier = (768 / screenHeight) / scale
		return floor((value / pixelMultiplier) + 0.5) * pixelMultiplier
	end
	return floor(value + 0.5)
end

local function durationToText(value)
	local seconds = safeNumber(value)
	if not seconds then return nil end
	if seconds < 0 then seconds = 0 end
	if seconds < 10 then return format("%.1f", seconds) end
	return format("%.0f", seconds)
end

local function getCooldownText(icon)
	local cooldown = icon and icon.cooldown or nil
	if not (cooldown and cooldown.GetCountdownFontString) then return nil end
	local fontString = cooldown:GetCountdownFontString()
	if not fontString or not fontString.GetText then return nil end
	local text = fontString:GetText()
	return getTextValue(text)
end

Bars.GetCooldownValueText = function(icon, durationObject, startTime, duration, rate)
	local remaining = nil
	if durationObject and durationObject.GetRemainingDuration then remaining = safeNumber(durationObject.GetRemainingDuration(durationObject, Api.DurationModifierRealTime)) end
	if remaining ~= nil then return durationToText(remaining) end
	local start = safeNumber(startTime)
	local total = safeNumber(duration)
	if not (start and total and total > 0) then return getCooldownText(icon) end
	local now = (Api.GetTime and Api.GetTime()) or GetTime()
	local modifier = safeNumber(rate) or 1
	local text = durationToText(max(0, total - ((now - start) * modifier)))
	if text ~= nil then return text end
	return getCooldownText(icon)
end

Bars.GetChargeDurationTextSource = function(state)
	if type(state) ~= "table" then return nil end
	local phase = state.renderChargePhase or state.chargePhase
	if phase == "EMPTY" and state.cooldownDurationObject ~= nil then
		return state.cooldownDurationObject, state.cooldownStart, state.cooldownDuration, state.cooldownRate, 1
	end
	if phase == "PARTIAL" and state.deferChargeTimerHandoff ~= true and state.chargeInfoActive == true and state.chargeDurationObject ~= nil then
		return state.chargeDurationObject, state.rechargeStart, state.rechargeDuration, state.rechargeRate, 2
	end
	if state.chargeDurationObject ~= nil then
		local maxCharges = safeNumber(state.maxCharges)
		local currentCharges = safeNumber(state.currentCharges) or inferChargeBaseCount(state, maxCharges)
		local segmentIndex = currentCharges and maxCharges and currentCharges < maxCharges and min(max(floor(currentCharges) + 1, 1), maxCharges) or nil
		return state.chargeDurationObject, state.rechargeStart, state.rechargeDuration, state.rechargeRate, segmentIndex
	end
	if state.cooldownDurationObject ~= nil and state.cooldownGCD ~= true then
		return state.cooldownDurationObject, state.cooldownStart, state.cooldownDuration, state.cooldownRate, 1
	end
	local rechargeStart = safeNumber(state.rechargeStart)
	local rechargeDuration = safeNumber(state.rechargeDuration)
	if rechargeStart and rechargeDuration and rechargeDuration > 0 then
		local maxCharges = safeNumber(state.maxCharges)
		local currentCharges = safeNumber(state.currentCharges) or inferChargeBaseCount(state, maxCharges)
		local segmentIndex = currentCharges and maxCharges and currentCharges < maxCharges and min(max(floor(currentCharges) + 1, 1), maxCharges) or nil
		return nil, rechargeStart, rechargeDuration, state.rechargeRate, segmentIndex
	end
	return nil
end

Bars.UpdateChargeDurationTextState = function(state)
	if type(state) ~= "table" then return nil end
	state.chargeDurationTextActive = nil
	state.chargeDurationTextObject = nil
	state.chargeDurationTextStart = nil
	state.chargeDurationTextDuration = nil
	state.chargeDurationTextRate = nil
	state.chargeDurationTextSegmentIndex = nil
	state.chargeDurationTextNative = nil

	local durationObject, startTime, duration, rate, segmentIndex = Bars.GetChargeDurationTextSource(state)
	if not durationObject then
		local text = Bars.GetCooldownValueText(nil, nil, startTime, duration, rate)
		if not hasTextValue(text) then return nil end
		state.chargeDurationTextActive = true
		state.chargeDurationTextStart = safeNumber(startTime)
		state.chargeDurationTextDuration = safeNumber(duration)
		state.chargeDurationTextRate = safeNumber(rate) or 1
		state.chargeDurationTextSegmentIndex = safeNumber(segmentIndex)
		return text
	end

	state.chargeDurationTextActive = true
	state.chargeDurationTextNative = true
	state.chargeDurationTextObject = durationObject
	state.chargeDurationTextSegmentIndex = safeNumber(segmentIndex)
	return nil
end

Bars.GetLiveBarValueText = function(state)
	if type(state) ~= "table" or state.showValueText ~= true then return nil end
	if state.mode == Bars.BAR_MODE.CHARGES then
		if state.showChargeDuration ~= true or state.chargeDurationTextActive ~= true then return nil end
		if state.chargeDurationTextNative == true then return nil end
		return Bars.GetCooldownValueText(nil, state.chargeDurationTextObject, state.chargeDurationTextStart, state.chargeDurationTextDuration, state.chargeDurationTextRate)
	end
	if state.mode ~= Bars.BAR_MODE.COOLDOWN or state.cooldownVisibilityActive ~= true then return nil end
	if state.chargeDurationTextNative == true then return nil end
	return Bars.GetCooldownValueText(state.icon, state.fillDurationObject, state.startTime, state.duration, state.rate)
end

Bars.UseNativeDurationValueText = Bars.UseNativeDurationValueText or function(state, durationObject)
	if not (state and durationObject) then return end
	state.valueTextIsChargeDuration = true
	state.chargeDurationTextActive = true
	state.chargeDurationTextNative = true
	state.chargeDurationTextObject = durationObject
	state.chargeDurationTextSegmentIndex = nil
end

Bars.ResolveStackDisplay = function(panelId, entryId, resolvedType, icon, runtimeData)
	local displayText = nil
	local rawValue = nil
	if resolvedType == "CDM_AURA" then
		rawValue = runtimeData and (runtimeData.rawApplications or runtimeData.cdmAuraRawApplications) or nil
		displayText = Helper.NormalizeDisplayCount and Helper.NormalizeDisplayCount(runtimeData and runtimeData.stackCount or nil) or getTextValue(runtimeData and runtimeData.stackCount or nil)
	else
		local entryKey = Helper.GetEntryKey(panelId, entryId)
		local shared = CooldownPanels.runtime
		rawValue = shared and shared.actionDisplayCounts and shared.actionDisplayCounts[entryKey] or nil
		displayText = Helper.NormalizeDisplayCount and Helper.NormalizeDisplayCount(rawValue) or getTextValue(rawValue)
		if displayText == nil and icon and icon.count and icon.count.GetText then
			displayText = Helper.NormalizeDisplayCount and Helper.NormalizeDisplayCount(icon.count:GetText()) or getTextValue(icon.count:GetText())
		end
	end

	local entryKey = Helper.GetEntryKey(panelId, entryId)
	CooldownPanels.runtime = CooldownPanels.runtime or {}
	CooldownPanels.runtime.cooldownPanelBars = CooldownPanels.runtime.cooldownPanelBars
		or {
			activeBars = setmetatable({}, { __mode = "k" }),
			stackMaxByEntryKey = {},
			chargeMaxByEntryKey = {},
			chargeLastNonGCDCooldownActiveByEntryKey = {},
			chargeLastNonGCDCooldownDurationByEntryKey = {},
			chargePhaseByEntryKey = {},
		}
	local runtime = CooldownPanels.runtime.cooldownPanelBars
	runtime.stackValueByEntryKey = runtime.stackValueByEntryKey or {}
	local cachedNumeric = runtime.stackValueByEntryKey[entryKey]
	local numericValue = resolvedType == "CDM_AURA" and safeNumber(rawValue) or (safeNumber(rawValue) or safeNumber(displayText))
	if numericValue ~= nil then
		runtime.stackValueByEntryKey[entryKey] = numericValue
		cachedNumeric = numericValue
	elseif resolvedType == "CDM_AURA" and not (runtimeData and runtimeData.active == true) then
		runtime.stackValueByEntryKey[entryKey] = nil
		cachedNumeric = nil
	elseif displayText == nil and resolvedType == "CDM_AURA" and runtimeData and runtimeData.active == true then
		displayText = "1"
		runtime.stackValueByEntryKey[entryKey] = 1
		cachedNumeric = 1
	end
	return displayText, cachedNumeric, rawValue
end

local function getDefaultBarColorForMode(mode)
	local r, g, b, a = getBarColor(mode)
	return { r, g, b, a }
end

local function normalizeBarTexture(value, fallback)
	local texture = getTextValue(value)
	if texture then return texture end
	texture = getTextValue(fallback)
	if texture then return texture end
	return BAR_TEXTURE_DEFAULT
end

local function normalizeBarBorderTexture(value, fallback)
	local texture = getTextValue(value)
	if texture then return texture end
	texture = getTextValue(fallback)
	if texture then return texture end
	return BAR_BORDER_TEXTURE_DEFAULT
end

local function normalizeBarHeight(value, fallback) return Helper.ClampInt(value, BAR_HEIGHT_MIN, BAR_HEIGHT_MAX, fallback or Bars.DEFAULTS.barHeight) end

local function normalizeBarWidth(value, fallback) return Helper.ClampInt(value, 0, BAR_WIDTH_MAX, fallback or Bars.DEFAULTS.barWidth) end

local function normalizeBarBorderSize(value, fallback) return Helper.ClampInt(value, BAR_BORDER_SIZE_MIN, BAR_BORDER_SIZE_MAX, fallback or Bars.DEFAULTS.barBorderSize) end

local function normalizeBarBorderOffset(value, fallback) return Helper.ClampInt(value, BAR_BORDER_OFFSET_MIN, BAR_BORDER_OFFSET_MAX, fallback or 0) end

local function normalizeBarOffset(value, fallback) return Helper.ClampInt(value, BAR_OFFSET_MIN, BAR_OFFSET_MAX, fallback or 0) end

local function normalizeBarOrientation(value, fallback)
	local orientation = type(value) == "string" and string.upper(value) or nil
	if orientation == BAR_ORIENTATION_VERTICAL then return BAR_ORIENTATION_VERTICAL end
	if orientation == BAR_ORIENTATION_HORIZONTAL then return BAR_ORIENTATION_HORIZONTAL end
	return fallback or Bars.DEFAULTS.barOrientation
end

local function normalizeBarSegmentDirection(value, fallback)
	local direction = type(value) == "string" and string.upper(value) or nil
	if direction == BAR_ORIENTATION_VERTICAL then return BAR_ORIENTATION_VERTICAL end
	if direction == BAR_ORIENTATION_HORIZONTAL then return BAR_ORIENTATION_HORIZONTAL end
	return fallback or Bars.DEFAULTS.barSegmentDirection
end

local function normalizeBarIconPosition(value, fallback)
	local position = type(value) == "string" and string.upper(value) or nil
	if position == BAR_ICON_POSITION_TOP then return BAR_ICON_POSITION_TOP end
	if position == BAR_ICON_POSITION_BOTTOM then return BAR_ICON_POSITION_BOTTOM end
	if position == BAR_ICON_POSITION_RIGHT then return BAR_ICON_POSITION_RIGHT end
	if position == BAR_ICON_POSITION_LEFT then return BAR_ICON_POSITION_LEFT end
	return fallback or Bars.DEFAULTS.barIconPosition
end

local function normalizeBarIconSize(value, fallback) return Helper.ClampInt(value, 0, BAR_ICON_SIZE_MAX, fallback or 0) end

local function normalizeBarIconOffset(value, fallback)
	local range = Helper.OFFSET_RANGE or 500
	return Helper.ClampInt(value, -range, range, fallback or 0)
end

local function normalizeBarChargesGap(value, fallback) return Helper.ClampInt(value, BAR_CHARGES_GAP_MIN, BAR_CHARGES_GAP_MAX, fallback or Bars.DEFAULTS.barChargesGap) end

Bars.NormalizeBarStackMax = function(value, fallback) return Helper.ClampInt(value, 1, 1000, fallback or Bars.DEFAULTS.barStackMax) end

local function normalizeBarFont(value, fallback)
	if type(value) == "string" then return value end
	if type(fallback) == "string" then return fallback end
	return ""
end

Bars.NormalizeTextAnchor = function(value, fallback)
	local anchor = type(value) == "string" and string.upper(value) or nil
	if anchor == Bars.TEXT_ANCHOR.LEFT then return Bars.TEXT_ANCHOR.LEFT end
	if anchor == Bars.TEXT_ANCHOR.RIGHT then return Bars.TEXT_ANCHOR.RIGHT end
	if anchor == Bars.TEXT_ANCHOR.CENTER then return Bars.TEXT_ANCHOR.CENTER end
	if anchor == Bars.TEXT_ANCHOR.TOP then return Bars.TEXT_ANCHOR.TOP end
	if anchor == Bars.TEXT_ANCHOR.BOTTOM then return Bars.TEXT_ANCHOR.BOTTOM end
	if anchor == Bars.TEXT_ANCHOR.AUTO then return Bars.TEXT_ANCHOR.AUTO end
	return fallback or Bars.TEXT_ANCHOR.AUTO
end

Bars.GetResolvedTextAnchor = function(anchor, orientation, role)
	anchor = Bars.NormalizeTextAnchor(anchor, Bars.TEXT_ANCHOR.AUTO)
	if anchor ~= Bars.TEXT_ANCHOR.AUTO then return anchor end
	if orientation == BAR_ORIENTATION_VERTICAL then return role == "LABEL" and Bars.TEXT_ANCHOR.TOP or Bars.TEXT_ANCHOR.BOTTOM end
	return role == "LABEL" and Bars.TEXT_ANCHOR.LEFT or Bars.TEXT_ANCHOR.RIGHT
end

Bars.GetTextAnchorConfig = function(anchor, orientation, role)
	local resolvedAnchor = Bars.GetResolvedTextAnchor(anchor, orientation, role)
	if resolvedAnchor == Bars.TEXT_ANCHOR.LEFT then return "LEFT", "LEFT", "LEFT" end
	if resolvedAnchor == Bars.TEXT_ANCHOR.RIGHT then return "RIGHT", "RIGHT", "RIGHT" end
	if resolvedAnchor == Bars.TEXT_ANCHOR.TOP then return "TOP", "TOP", "CENTER" end
	if resolvedAnchor == Bars.TEXT_ANCHOR.BOTTOM then return "BOTTOM", "BOTTOM", "CENTER" end
	return "CENTER", "CENTER", "CENTER"
end

Bars.AppendStandaloneSettingsById = function(destination, source, id)
	if not (destination and source and id) then return end
	for _, setting in ipairs(source) do
		if setting.id == id then destination[#destination + 1] = setting end
	end
end

Bars.AppendStandaloneSettingsByParent = function(destination, source, parentId)
	if not (destination and source and parentId) then return end
	for _, setting in ipairs(source) do
		if setting.parentId == parentId then destination[#destination + 1] = setting end
	end
end

Bars.ApplyNewBarStyleDefaults = function(entry)
	if type(entry) ~= "table" then return end
	if entry.barTexture == nil or normalizeBarTexture(entry.barTexture, BAR_TEXTURE_DEFAULT) == BAR_TEXTURE_DEFAULT then entry.barTexture = Bars.DEFAULTS.barTexture end
	if safeNumber(entry.barIconSize) == nil or safeNumber(entry.barIconSize) <= 0 then entry.barIconSize = Bars.DEFAULTS.barIconSize end
	if entry.barBorderEnabled == nil then entry.barBorderEnabled = Bars.DEFAULTS.barBorderEnabled end
	if entry.barShowChargeDuration == nil then entry.barShowChargeDuration = Bars.DEFAULTS.barShowChargeDuration end
	if entry.barShowStackText == nil then entry.barShowStackText = Bars.DEFAULTS.barShowStackText end
	if entry.barStacksSegmented == nil then entry.barStacksSegmented = Bars.DEFAULTS.barStacksSegmented end
	if entry.barStackDividerColor == nil then entry.barStackDividerColor = Bars.DEFAULTS.barStackDividerColor end
	if entry.barStackDividerThickness == nil then entry.barStackDividerThickness = Bars.DEFAULTS.barStackDividerThickness end
	if entry.barStackSeparatedOffset == nil then entry.barStackSeparatedOffset = Bars.DEFAULTS.barStackSeparatedOffset end
	if entry.barStackMax == nil then entry.barStackMax = Bars.DEFAULTS.barStackMax end
	if entry.barStackAnchor == nil then entry.barStackAnchor = Bars.DEFAULTS.barStackAnchor end
	if entry.barStackOffsetX == nil then entry.barStackOffsetX = Bars.DEFAULTS.barStackOffsetX end
	if entry.barStackOffsetY == nil then entry.barStackOffsetY = Bars.DEFAULTS.barStackOffsetY end
	if entry.barLabelAnchor == nil then entry.barLabelAnchor = Bars.DEFAULTS.barLabelAnchor end
	if entry.barLabelOffsetX == nil then entry.barLabelOffsetX = Bars.DEFAULTS.barLabelOffsetX end
	if entry.barLabelOffsetY == nil then entry.barLabelOffsetY = Bars.DEFAULTS.barLabelOffsetY end
	if entry.barValueAnchor == nil then entry.barValueAnchor = Bars.DEFAULTS.barValueAnchor end
	if entry.barValueOffsetX == nil then entry.barValueOffsetX = Bars.DEFAULTS.barValueOffsetX end
	if entry.barValueOffsetY == nil then entry.barValueOffsetY = Bars.DEFAULTS.barValueOffsetY end
end

local function normalizeBarFontSize(value, fallback) return Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, fallback or 11) end
local function normalizeBarStackDividerThickness(value, fallback)
	return Helper.ClampInt(value, BAR_STACK_DIVIDER_THICKNESS_MIN, BAR_STACK_DIVIDER_THICKNESS_MAX, fallback or Bars.DEFAULTS.barStackDividerThickness or 1)
end

local function normalizeBarFontStyle(value, fallback) return Helper.NormalizeFontStyleChoice(value, fallback or Bars.GetGlobalFontStyleKey()) end
Bars.NormalizeDurationTextProfile = function(value, fallback)
	local durationText = addon.DurationText
	if durationText and durationText.GetProfileKey then return durationText:GetProfileKey(value or fallback or Bars.DEFAULTS.barDurationTextProfile) end
	if type(value) == "string" and value ~= "" then return value end
	return fallback or Bars.DEFAULTS.barDurationTextProfile
end
Bars.GetPanelDurationTextProfile = function(panel)
	if panel and panel.layout and panel.layout.durationTextProfile ~= nil then return Bars.NormalizeDurationTextProfile(panel.layout.durationTextProfile, Bars.DEFAULTS.barDurationTextProfile) end
	return Bars.NormalizeDurationTextProfile(panel and panel.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile)
end
Bars.GetEntryDurationTextProfile = function(entry, panel)
	if entry and entry.barDurationTextProfile ~= nil then return Bars.NormalizeDurationTextProfile(entry.barDurationTextProfile, Bars.GetPanelDurationTextProfile(panel)) end
	return Bars.GetPanelDurationTextProfile(panel)
end

Bars.MigrateLegacyBarFontStyleDefault = Bars.MigrateLegacyBarFontStyleDefault
	or function(value)
		local globalStyle = Bars.GetGlobalFontStyleKey()
		if value == nil or value == "" then return globalStyle end
		value = normalizeBarFontStyle(value, globalStyle)
		if value == "OUTLINE" then return globalStyle end
		return value
	end

Bars.NormalizeRootBarDefaults = Bars.NormalizeRootBarDefaults
	or function(root)
		local entryDefaults = root and root.defaults and root.defaults.entry
		if type(entryDefaults) ~= "table" then return end
		entryDefaults.barStackStyle = Bars.MigrateLegacyBarFontStyleDefault(entryDefaults.barStackStyle)
		entryDefaults.barLabelStyle = Bars.MigrateLegacyBarFontStyleDefault(entryDefaults.barLabelStyle)
		entryDefaults.barValueStyle = Bars.MigrateLegacyBarFontStyleDefault(entryDefaults.barValueStyle)
	end

Bars._eqolOriginalNormalizeRoot = Bars._eqolOriginalNormalizeRoot or Helper.NormalizeRoot
if Bars._eqolOriginalNormalizeRoot then
	Helper.NormalizeRoot = function(root, ...)
		local result = Bars._eqolOriginalNormalizeRoot(root, ...)
		Bars.NormalizeRootBarDefaults(root)
		return result
	end
end

local function resolveBarTexture(value)
	local texture = normalizeBarTexture(value, BAR_TEXTURE_DEFAULT)
	if texture == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if texture == BAR_TEXTURE_DEFAULT then return "Interface\\TargetingFrame\\UI-StatusBar" end
	if LSM and LSM.Fetch then
		local fetched = LSM:Fetch("statusbar", texture, true)
		if hasTextValue(fetched) then return fetched end
	end
	if isLikelyFilePath(texture) then return texture end
	return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function resolveBarBorderTexture(value)
	local key = normalizeBarBorderTexture(value, BAR_BORDER_TEXTURE_DEFAULT)
	local ufHelper = addon.Aura and addon.Aura.UFHelper
	if ufHelper and ufHelper.resolveBorderTexture then return ufHelper.resolveBorderTexture(key) end
	if not hasTextValue(key) or isSecretValue(key) or key == BAR_BORDER_TEXTURE_DEFAULT then return "Interface\\Buttons\\WHITE8x8" end
	if LSM and LSM.Fetch then
		local fetched = LSM:Fetch("border", key, true)
		if hasTextValue(fetched) then return fetched end
	end
	if isLikelyFilePath(key) then return key end
	return "Interface\\Buttons\\WHITE8x8"
end

local function getBarTextureOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local key = tostring(value or ""):lower()
		if key == "" or seen[key] then return end
		seen[key] = true
		list[#list + 1] = {
			value = value,
			label = label or value,
		}
	end
	add(BAR_TEXTURE_DEFAULT, _G.DEFAULT or "Default")
	add("SOLID", "Solid")
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("statusbar") or {}
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("statusbar") or {}
	for index = 1, #names do
		local name = names[index]
		local path = hash[name]
		if hasTextValue(path) then add(name, tostring(name)) end
	end
	return list
end

local function getBarBorderTextureOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local key = tostring(value or ""):lower()
		if key == "" or seen[key] then return end
		seen[key] = true
		list[#list + 1] = {
			value = value,
			label = label or value,
		}
	end
	add(BAR_BORDER_TEXTURE_DEFAULT, _G.DEFAULT or "Default")
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or {}
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("border") or {}
	for index = 1, #names do
		local name = names[index]
		local path = hash[name]
		if hasTextValue(path) then add(name, tostring(name)) end
	end
	return list
end

local function getBarEntry(panelId, entryId)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	local entry = panel and panel.entries and panel.entries[entryId] or nil
	return panel, entry
end

Bars.IsBarDisplayModeValue = function(value)
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == Bars.DISPLAY_MODE.BAR then return true end
	if mode == Bars.DISPLAY_MODE.BUTTON then return false end
	return Bars.DEFAULTS.displayMode == Bars.DISPLAY_MODE.BAR
end

local function mutateBarEntry(panelId, entryId, mutator, reopenDialog)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel, entry = getBarEntry(panelId, entryId)
	if not (panel and entry) then return nil, nil end
	local wasBar = Bars.IsBarDisplayModeValue(entry.displayMode)
	if type(mutator) == "function" then mutator(entry, panel) end
	normalizeBarEntry(entry)
	local isBar = Bars.IsBarDisplayModeValue(entry.displayMode)
	if type(entry._eqolBarsStaticVersion) ~= "number" then entry._eqolBarsStaticVersion = 0 end
	entry._eqolBarsStaticVersion = entry._eqolBarsStaticVersion + 1
	if Bars._eqolBarColorCache then Bars._eqolBarColorCache[entry] = nil end
	Bars.MarkReservationCacheDirty(panel)
	if wasBar ~= isBar and CooldownPanels.RebuildSpellIndex then
		CooldownPanels:RebuildSpellIndex()
	end
	refreshPanelContext(panelId)
	refreshStandaloneEntryDialogForBars(panelId, entryId, reopenDialog == true)
	return panel, entry
end

Bars.HandleEntryStylePaste = function(panelId, entryId, entry, wasBar)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel = panelId and CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if not (panel and entry) then return false end
	normalizeBarEntry(entry)
	local isBar = Bars.IsBarDisplayModeValue(entry.displayMode)
	if type(entry._eqolBarsStaticVersion) ~= "number" then entry._eqolBarsStaticVersion = 0 end
	entry._eqolBarsStaticVersion = entry._eqolBarsStaticVersion + 1
	if Bars._eqolBarColorCache then Bars._eqolBarColorCache[entry] = nil end
	Bars.MarkReservationCacheDirty(panel)
	if wasBar ~= isBar and CooldownPanels.RebuildSpellIndex then CooldownPanels:RebuildSpellIndex() end
	return true
end

Bars._eqolBarColorCache = Bars._eqolBarColorCache or setmetatable({}, { __mode = "k" })

function Bars.GetCachedEntryColor(entry, field, fallback)
	if not entry then return Helper.NormalizeColor(nil, fallback) end
	local colorCache = Bars._eqolBarColorCache
	local cache = colorCache[entry]
	if not cache then
		cache = {}
		colorCache[entry] = cache
	end
	local rawValue = entry[field]
	local cached = cache[field]
	if cached and cached.rawValue == rawValue then return cached.color end
	local color = Helper.NormalizeColor(rawValue, fallback)
	cache[field] = { rawValue = rawValue, color = color }
	return color
end

local function getBarModeColor(entry, mode) return Bars.GetCachedEntryColor(entry, "barColor", getDefaultBarColorForMode(mode)) end

local function getBarTextureSelection(entry)
	local texture = entry and entry.barTexture or nil
	return normalizeBarTexture(texture, Bars.DEFAULTS.barTexture)
end

local function getEntryBarModeLabel(mode)
	if mode == Bars.BAR_MODE.CHARGES then return L["Charges"] or "Charges" end
	if mode == Bars.BAR_MODE.STACKS then return L["Stacks"] or "Stacks" end
	return L["Cooldown"] or "Cooldown"
end

local function normalizeDisplayMode(value, fallback)
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == Bars.DISPLAY_MODE.BAR then return Bars.DISPLAY_MODE.BAR end
	if mode == Bars.DISPLAY_MODE.BUTTON then return Bars.DISPLAY_MODE.BUTTON end
	return fallback or Bars.DEFAULTS.displayMode
end

local function normalizeBarMode(value, fallback)
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == Bars.BAR_MODE.CHARGES then return Bars.BAR_MODE.CHARGES end
	if mode == Bars.BAR_MODE.STACKS then return Bars.BAR_MODE.STACKS end
	if mode == Bars.BAR_MODE.COOLDOWN then return Bars.BAR_MODE.COOLDOWN end
	return fallback or Bars.DEFAULTS.barMode
end

local function normalizeBarSpan(value, fallback)
	local span = tonumber(value)
	return clamp(floor((span or fallback or Bars.DEFAULTS.barSpan) + 0.5), 1, 4)
end

getRuntimeState = function()
	CooldownPanels.runtime = CooldownPanels.runtime or {}
	CooldownPanels.runtime.cooldownPanelBars = CooldownPanels.runtime.cooldownPanelBars
		or {
			activeBars = setmetatable({}, { __mode = "k" }),
			stackMaxByEntryKey = {},
			chargeMaxByEntryKey = {},
			chargeLastNonGCDCooldownActiveByEntryKey = {},
			chargeLastNonGCDCooldownDurationByEntryKey = {},
			chargePhaseByEntryKey = {},
			chargeEmptyDurationObjectByEntryKey = {},
			pendingChargeTimerHandoffByEntryKey = {},
			pendingChargeTimerHandoffRefreshByEntryKey = {},
		}
	return CooldownPanels.runtime.cooldownPanelBars
end

local function getEntryResolvedType(entry)
	if not entry then return nil, nil end
	local resolvedType = entry.type
	local macro = nil
	if resolvedType == "MACRO" and CooldownPanels.ResolveMacroEntry then
		macro = CooldownPanels.ResolveMacroEntry(entry)
		resolvedType = macro and macro.kind or resolvedType
	end
	return resolvedType, macro
end

local function supportsBarMode(entry, mode)
	if not entry then return false end
	local resolvedType = getEntryResolvedType(entry)
	if mode == Bars.BAR_MODE.CHARGES then return entry.type == "SPELL" end
	if mode == Bars.BAR_MODE.STACKS then return entry.type == "SPELL" or resolvedType == "CDM_AURA" end
	return resolvedType == "SPELL" or resolvedType == "ITEM" or entry.type == "MACRO" or resolvedType == "CDM_AURA"
end

Bars.FocusStandaloneSection = function(panelId, entryId, targetGroupId)
	if not (CooldownPanels and CooldownPanels.FocusLayoutEntryStandaloneSettingsGroup) then return false end
	return CooldownPanels:FocusLayoutEntryStandaloneSettingsGroup(panelId, entryId, targetGroupId)
end

Bars.EntryHasQuickSetups = function(panelId, entryId)
	local _, entry = getBarEntry(panelId, entryId)
	return Bars.IsBarDisplayModeValue(entry and entry.displayMode)
		and (supportsBarMode(entry, Bars.BAR_MODE.CHARGES) or supportsBarMode(entry, Bars.BAR_MODE.STACKS))
end

Bars.ApplySegmentChargesQuickSetup = function(panelId, entryId)
	local _, entry = getBarEntry(panelId, entryId)
	if not supportsBarMode(entry, Bars.BAR_MODE.CHARGES) then return false end
	mutateBarEntry(panelId, entryId, function(target)
		target.displayMode = Bars.DISPLAY_MODE.BAR
		target.barMode = Bars.BAR_MODE.CHARGES
		Bars.ApplyNewBarStyleDefaults(target)
		if type(target.barColor) ~= "table" then target.barColor = getDefaultBarColorForMode(target.barMode) end
		target.barWidth = 200
		target.barShowIcon = false
		target.barShowLabel = false
		target.barChargesSegmented = true
		target.barChargesGap = 2
		target.barShowValueText = false
		target.barShowChargeDuration = true
		target.barValueAnchor = Bars.TEXT_ANCHOR.CENTER
		target.barValueOffsetX = 0
		target.barValueOffsetY = 0
		target.barValueSize = 14
	end, true)
	return true
end

Bars.ApplySegmentStacksQuickSetup = function(panelId, entryId)
	local _, entry = getBarEntry(panelId, entryId)
	if not supportsBarMode(entry, Bars.BAR_MODE.STACKS) then return false end
	Bars.FocusStandaloneSection(panelId, entryId, Bars.STANDALONE_STACKS_SECTION_ID)
	mutateBarEntry(panelId, entryId, function(target)
		target.displayMode = Bars.DISPLAY_MODE.BAR
		target.barMode = Bars.BAR_MODE.STACKS
		Bars.ApplyNewBarStyleDefaults(target)
		if type(target.barColor) ~= "table" then target.barColor = getDefaultBarColorForMode(target.barMode) end
		target.barWidth = 200
		target.barShowIcon = false
		target.barShowLabel = false
		target.barStacksSegmented = true
		target.barStackMax = 4
		target.barStackSeparatedOffset = 4
		target.barStackDividerColor = { 0.10, 0.10, 0.10, 0 }
		target.barShowStackText = false
	end, true)
	return true
end

Bars.AppendQuickSetupMenu = function(rootDescription, panelId, entryId)
	if not rootDescription or not Bars.EntryHasQuickSetups(panelId, entryId) then return false end
	local _, entry = getBarEntry(panelId, entryId)
	if supportsBarMode(entry, Bars.BAR_MODE.CHARGES) then
		rootDescription:CreateButton(L["CooldownPanelBarChargesSegmented"] or "Segment charges", function()
			Bars.ApplySegmentChargesQuickSetup(panelId, entryId)
		end)
	end
	if supportsBarMode(entry, Bars.BAR_MODE.STACKS) then
		rootDescription:CreateButton(L["CooldownPanelBarStacksSegmented"] or "Segment stacks", function()
			Bars.ApplySegmentStacksQuickSetup(panelId, entryId)
		end)
	end
	return true
end

local function shouldAutoEnableShowStacks(entry)
	return supportsBarMode(entry, Bars.BAR_MODE.STACKS)
		and normalizeDisplayMode(entry and entry.displayMode, Bars.DEFAULTS.displayMode) == Bars.DISPLAY_MODE.BAR
		and normalizeBarMode(entry and entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
end

Bars.ShouldEntryShowStacks = function(entry, resolvedType)
	if resolvedType ~= "SPELL" and resolvedType ~= "CDM_AURA" then return false end
	return shouldAutoEnableShowStacks(entry) or getStoredBoolean(entry, "showStacks", false)
end

local function isBarProcGlowActive(resolvedType, spellId)
	if resolvedType ~= "SPELL" or not spellId then return false end
	local runtime = CooldownPanels.runtime
	local overlayGlowSpells = runtime and runtime.overlayGlowSpells or nil
	return overlayGlowSpells and overlayGlowSpells[spellId] == true or false
end

normalizeBarEntry = function(entry)
	if type(entry) ~= "table" then return end
	entry.displayMode = normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode)
	entry.barMode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
	entry.barSpan = normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan)
	entry.barWidth = normalizeBarWidth(entry.barWidth, Bars.DEFAULTS.barWidth)
	entry.barHeight = normalizeBarHeight(entry.barHeight, Bars.DEFAULTS.barHeight)
	entry.barTexture = normalizeBarTexture(entry.barTexture, Bars.DEFAULTS.barTexture)
	entry.barColor = Helper.NormalizeColor(entry.barColor, getDefaultBarColorForMode(entry.barMode))
	entry.barBackgroundColor = Helper.NormalizeColor(entry.barBackgroundColor, Bars.DEFAULTS.barBackgroundColor)
	entry.barBorderEnabled = getStoredBoolean(entry, "barBorderEnabled", Bars.DEFAULTS.barBorderEnabled)
	entry.barBorderColor = Helper.NormalizeColor(entry.barBorderColor, Bars.DEFAULTS.barBorderColor)
	entry.barBorderTexture = normalizeBarBorderTexture(entry.barBorderTexture, Bars.DEFAULTS.barBorderTexture)
	entry.barBorderOffset = normalizeBarBorderOffset(entry.barBorderOffset, Bars.DEFAULTS.barBorderOffset)
	entry.barBorderSize = normalizeBarBorderSize(entry.barBorderSize, Bars.DEFAULTS.barBorderSize)
	entry.barOffsetX = normalizeBarOffset(entry.barOffsetX, Bars.DEFAULTS.barOffsetX)
	entry.barOffsetY = normalizeBarOffset(entry.barOffsetY, Bars.DEFAULTS.barOffsetY)
	entry.barOrientation = normalizeBarOrientation(entry.barOrientation, Bars.DEFAULTS.barOrientation)
	entry.barReverseFill = getStoredBoolean(entry, "barReverseFill", Bars.DEFAULTS.barReverseFill)
	entry.barSegmentDirection = normalizeBarSegmentDirection(entry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection)
	entry.barSegmentReverse = getStoredBoolean(entry, "barSegmentReverse", Bars.DEFAULTS.barSegmentReverse)
	entry.barProcGlowColor = Helper.NormalizeColor(entry.barProcGlowColor, Bars.DEFAULTS.barProcGlowColor)
	entry.barShowIcon = getStoredBoolean(entry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
	entry.barShowLabel = getStoredBoolean(entry, "barShowLabel", Bars.DEFAULTS.barShowLabel)
	entry.barShowValueText = getStoredBoolean(entry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
	entry.barShowChargeDuration = getStoredBoolean(entry, "barShowChargeDuration", Bars.DEFAULTS.barShowChargeDuration)
	entry.barShowStackText = getStoredBoolean(entry, "barShowStackText", Bars.DEFAULTS.barShowStackText)
	entry.barIconSize = normalizeBarIconSize(entry.barIconSize, Bars.DEFAULTS.barIconSize)
	if entry.barIconSize <= 0 then entry.barIconSize = Bars.DEFAULTS.barIconSize end
	entry.barIconPosition = normalizeBarIconPosition(entry.barIconPosition, Bars.DEFAULTS.barIconPosition)
	entry.barIconOffsetX = normalizeBarIconOffset(entry.barIconOffsetX, Bars.DEFAULTS.barIconOffsetX)
	entry.barIconOffsetY = normalizeBarIconOffset(entry.barIconOffsetY, Bars.DEFAULTS.barIconOffsetY)
	entry.barChargesSegmented = getStoredBoolean(entry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
	entry.barChargesGap = normalizeBarChargesGap(entry.barChargesGap, Bars.DEFAULTS.barChargesGap)
	entry.barStacksSegmented = getStoredBoolean(entry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
	entry.barStackSeparatedOffset = normalizeBarChargesGap(entry.barStackSeparatedOffset, Bars.DEFAULTS.barStackSeparatedOffset)
	entry.barStackDividerColor = Helper.NormalizeColor(entry.barStackDividerColor, Bars.DEFAULTS.barStackDividerColor)
	entry.barStackDividerThickness = normalizeBarStackDividerThickness(entry.barStackDividerThickness, Bars.DEFAULTS.barStackDividerThickness)
	entry.barStackMax = Bars.NormalizeBarStackMax(entry.barStackMax, Bars.DEFAULTS.barStackMax)
	entry.barStackAnchor = Bars.NormalizeTextAnchor(entry.barStackAnchor, Bars.DEFAULTS.barStackAnchor)
	entry.barStackFont = normalizeBarFont(entry.barStackFont, Bars.DEFAULTS.barStackFont)
	entry.barStackOffsetX = normalizeBarOffset(entry.barStackOffsetX, Bars.DEFAULTS.barStackOffsetX)
	entry.barStackOffsetY = normalizeBarOffset(entry.barStackOffsetY, Bars.DEFAULTS.barStackOffsetY)
	entry.barStackSize = normalizeBarFontSize(entry.barStackSize, Bars.DEFAULTS.barStackSize)
	entry.barStackStyle = normalizeBarFontStyle(entry.barStackStyle, Bars.DEFAULTS.barStackStyle)
	entry.barStackColor = Helper.NormalizeColor(entry.barStackColor, Bars.DEFAULTS.barStackColor)
	entry.barLabelAnchor = Bars.NormalizeTextAnchor(entry.barLabelAnchor, Bars.DEFAULTS.barLabelAnchor)
	entry.barLabelFont = normalizeBarFont(entry.barLabelFont, Bars.DEFAULTS.barLabelFont)
	entry.barLabelOffsetX = normalizeBarOffset(entry.barLabelOffsetX, Bars.DEFAULTS.barLabelOffsetX)
	entry.barLabelOffsetY = normalizeBarOffset(entry.barLabelOffsetY, Bars.DEFAULTS.barLabelOffsetY)
	entry.barLabelSize = normalizeBarFontSize(entry.barLabelSize, Bars.DEFAULTS.barLabelSize)
	entry.barLabelStyle = normalizeBarFontStyle(entry.barLabelStyle, Bars.DEFAULTS.barLabelStyle)
	entry.barLabelColor = Helper.NormalizeColor(entry.barLabelColor, Bars.DEFAULTS.barLabelColor)
	entry.barValueAnchor = Bars.NormalizeTextAnchor(entry.barValueAnchor, Bars.DEFAULTS.barValueAnchor)
	entry.barValueFont = normalizeBarFont(entry.barValueFont, Bars.DEFAULTS.barValueFont)
	entry.barValueOffsetX = normalizeBarOffset(entry.barValueOffsetX, Bars.DEFAULTS.barValueOffsetX)
	entry.barValueOffsetY = normalizeBarOffset(entry.barValueOffsetY, Bars.DEFAULTS.barValueOffsetY)
	entry.barValueSize = normalizeBarFontSize(entry.barValueSize, Bars.DEFAULTS.barValueSize)
	entry.barValueStyle = normalizeBarFontStyle(entry.barValueStyle, Bars.DEFAULTS.barValueStyle)
	entry.barValueColor = Helper.NormalizeColor(entry.barValueColor, Bars.DEFAULTS.barValueColor)
	if entry.barDurationTextProfile ~= nil then entry.barDurationTextProfile = Bars.NormalizeDurationTextProfile(entry.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile) end
	if shouldAutoEnableShowStacks(entry) then entry.showStacks = true end
	if entry.displayMode == Bars.DISPLAY_MODE.BAR and not supportsBarMode(entry, entry.barMode) then
		entry.barMode = Bars.BAR_MODE.COOLDOWN
		if not supportsBarMode(entry, entry.barMode) then entry.displayMode = Bars.DISPLAY_MODE.BUTTON end
	end
end

local function getEntryLabel(entry)
	if not entry then return nil end
	if CooldownPanels.GetEntryStandaloneTitle then
		local title = CooldownPanels:GetEntryStandaloneTitle(entry)
		if hasTextValue(title) then return title:match("^(.*)%s%-%s.+$") or title end
	end
	local resolvedType, macro = getEntryResolvedType(entry)
	if resolvedType == "SPELL" then
		local spellId = tonumber((macro and macro.spellID) or entry.spellID)
		if spellId then
			if Api.GetSpellInfoFn then
				local name = Api.GetSpellInfoFn(spellId)
				if hasTextValue(name) then return name end
			end
			if C_Spell and C_Spell.GetSpellInfo then
				local info = C_Spell.GetSpellInfo(spellId)
				local name = type(info) == "table" and info.name or info
				if hasTextValue(name) then return name end
			end
			if GetSpellInfo then
				local name = GetSpellInfo(spellId)
				if hasTextValue(name) then return name end
			end
		end
	elseif resolvedType == "ITEM" then
		local itemId = tonumber((macro and macro.itemID) or entry.itemID)
		if itemId then
			if C_Item and C_Item.GetItemNameByID then
				local name = C_Item.GetItemNameByID(itemId)
				if hasTextValue(name) then return name end
			end
			if GetItemInfo then
				local name = GetItemInfo(itemId)
				if hasTextValue(name) then return name end
			end
		end
	elseif resolvedType == "CDM_AURA" and CooldownPanels.CDMAuras and CooldownPanels.CDMAuras.GetEntryName then
		return CooldownPanels.CDMAuras:GetEntryName(entry)
	elseif entry.type == "MACRO" then
		if Api.GetMacroInfo then
			local macroId = tonumber(entry.macroID)
			if macroId then
				local name = Api.GetMacroInfo(macroId)
				if hasTextValue(name) then return name end
			end
		end
		if hasTextValue(entry.macroName) then return entry.macroName end
	end
	return nil
end

local function getSlotIndexByEntryId(cache)
	local map = cache and cache._eqolBarsSlotIndexByEntryId or nil
	if map then return map end
	map = {}
	if cache and type(cache.slotEntryIds) == "table" then
		for slotIndex = 1, cache.slotCount or #cache.slotEntryIds do
			local entryId = cache.slotEntryIds[slotIndex]
			if entryId ~= nil and map[entryId] == nil then map[entryId] = slotIndex end
		end
	end
	cache._eqolBarsSlotIndexByEntryId = map
	return map
end

local function getAnchorCellFromCache(cache, entryId, entry)
	if not (cache and entryId and entry) then return nil end
	local column = Helper.NormalizeSlotCoordinate(entry.slotColumn)
	local row = Helper.NormalizeSlotCoordinate(entry.slotRow)
	if column and row then return column, row end
	local slotIndex = getSlotIndexByEntryId(cache)[entryId]
	local columns = cache.boundsColumns or 0
	if slotIndex and columns > 0 then return ((slotIndex - 1) % columns) + 1, floor((slotIndex - 1) / columns) + 1 end
	return nil
end

local function getEntryBaseSlotSize(panel, entry)
	local layout = panel and panel.layout or nil
	local layoutSize = Helper.ClampInt(layout and layout.iconSize, 12, 128, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.iconSize or 36)
	if entry and entry.iconSizeUseGlobal == false then return Helper.ClampInt(entry.iconSize, 12, 128, layoutSize) end
	return layoutSize
end

Bars.GetEntryChargeSegmentCountHint = function(entry, fallback)
	local count = nil
	if type(entry) == "table" then
		local spellId = tonumber(entry.spellID)
		if spellId and Api.GetOverrideSpell then
			local overrideId = Api.GetOverrideSpell(spellId)
			if type(overrideId) == "number" and overrideId > 0 then spellId = overrideId end
		end
		local chargesInfo = spellId and CooldownPanels.GetCachedSpellChargesInfo and CooldownPanels:GetCachedSpellChargesInfo(spellId) or nil
		count = safeNumber(chargesInfo and chargesInfo.maxCharges)
	end
	count = count or safeNumber(fallback)
	if not (count and count > 1) then count = 3 end
	return clamp(floor(count + 0.5), 2, 20)
end

local function getDesiredBarSpan(panel, entry)
	if not entry then return 1 end
	local configuredWidth = normalizeBarWidth(entry.barWidth, Bars.DEFAULTS.barWidth)
	local configuredSpan = normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan)
	local offsetX = normalizeBarOffset(entry.barOffsetX, Bars.DEFAULTS.barOffsetX)
	local slotSize = getEntryBaseSlotSize(panel, entry)
	local spacing = Helper.ClampInt(panel and panel.layout and panel.layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2)
	local cellWidth = max(1, slotSize + spacing)
	local bodyWidth = configuredWidth and configuredWidth > 0 and configuredWidth or max(slotSize, (slotSize * configuredSpan) + (max(configuredSpan - 1, 0) * spacing))
	if normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES and getStoredBoolean(entry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented) then
		local reservationSegments = Bars.GetEntryChargeSegmentCountHint(entry, 3)
		if normalizeBarSegmentDirection(entry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection) == BAR_ORIENTATION_HORIZONTAL then
			bodyWidth = (bodyWidth * reservationSegments) + (normalizeBarChargesGap(entry.barChargesGap, Bars.DEFAULTS.barChargesGap) * (reservationSegments - 1))
		end
	end
	local rightExtent = max(slotSize, max(0, offsetX) + bodyWidth)
	return max(1, floor((rightExtent + cellWidth - 1) / cellWidth))
end

local function getHorizontalSegmentReservationColumns(panel, entry, anchorColumn, maxEndColumn)
	if not (panel and entry and anchorColumn and maxEndColumn) then return nil, nil end
	local mode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
	local configuredWidth = normalizeBarWidth(entry.barWidth, Bars.DEFAULTS.barWidth)
	local configuredSpan = normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan)
	local slotSize = getEntryBaseSlotSize(panel, entry)
	local spacing = Helper.ClampInt(panel and panel.layout and panel.layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2)
	local cellWidth = max(1, slotSize + spacing)
	local gap = normalizeBarChargesGap(entry.barChargesGap, Bars.DEFAULTS.barChargesGap)
	local offsetX = normalizeBarOffset(entry.barOffsetX, Bars.DEFAULTS.barOffsetX)
	local segmentedHorizontal = mode == Bars.BAR_MODE.CHARGES
		and getStoredBoolean(entry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented) == true
		and normalizeBarSegmentDirection(entry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection) == BAR_ORIENTATION_HORIZONTAL
	local bodyWidth = configuredWidth and configuredWidth > 0 and configuredWidth or max(slotSize, (slotSize * configuredSpan) + (max(configuredSpan - 1, 0) * spacing))
	local columns = {}
	local seen = {}

	local function addColumn(column)
		if column and column >= 1 and column <= maxEndColumn and seen[column] ~= true then
			seen[column] = true
			columns[#columns + 1] = column
		end
	end

	local function addPixelRange(startPixel, endPixel)
		local startOffset = floor(startPixel / cellWidth) + 1
		local endOffset = floor(max(startPixel, endPixel - 1) / cellWidth) + 1
		for offset = startOffset, endOffset do
			addColumn(anchorColumn + offset - 1)
		end
	end

	local visualSpan
	if segmentedHorizontal then
		local reservationSegments = Bars.GetEntryChargeSegmentCountHint(entry, 3)
		for segmentIndex = 1, reservationSegments do
			local segmentStart = offsetX + ((segmentIndex - 1) * (bodyWidth + gap))
			addPixelRange(segmentStart, segmentStart + bodyWidth)
		end
		visualSpan = max(1, floor((max(slotSize, max(0, offsetX) + (bodyWidth * reservationSegments) + (gap * (reservationSegments - 1))) + cellWidth - 1) / cellWidth))
	else
		addPixelRange(offsetX, offsetX + bodyWidth)
		visualSpan = max(1, floor((max(slotSize, max(0, offsetX) + bodyWidth) + cellWidth - 1) / cellWidth))
	end

	if #columns == 0 then return nil, visualSpan end
	table.sort(columns)
	return columns, visualSpan
end

local function getBaseOccupantAtCell(cache, entry, column, row)
	if not (cache and entry and column and row) then return nil end
	local key = getCellKey(column, row)
	local groupId = Helper.NormalizeFixedGroupId(entry.fixedGroupId)
	if groupId and cache.groupById then
		local group = cache.groupById[groupId]
		if group and CooldownPanels.IsFixedGroupStatic and CooldownPanels:IsFixedGroupStatic(group) then
			local cells = cache.entryAtStaticGroupCell and cache.entryAtStaticGroupCell[group.id] or nil
			return cells and cells[key] or nil
		end
		return nil
	end
	return cache.entryAtUngroupedCell and cache.entryAtUngroupedCell[key] or nil
end

local function getReservationSignature(panel)
	local buffer = {}
	local layout = panel and panel.layout or nil
	buffer[#buffer + 1] = tostring(Helper.ClampInt(layout and layout.iconSize, 12, 128, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.iconSize or 36))
	buffer[#buffer + 1] = tostring(Helper.ClampInt(layout and layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2))
	for _, entryId in ipairs(panel and panel.order or {}) do
		local entry = panel.entries and panel.entries[entryId] or nil
		if entry then
			local displayMode = normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode)
			local barMode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
			local segmentedCharges = getStoredBoolean(entry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
			buffer[#buffer + 1] = tostring(entryId)
			buffer[#buffer + 1] = displayMode
			buffer[#buffer + 1] = barMode
			buffer[#buffer + 1] = tostring(normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan))
			buffer[#buffer + 1] = tostring(normalizeBarWidth(entry.barWidth, Bars.DEFAULTS.barWidth))
			buffer[#buffer + 1] = tostring(normalizeBarOffset(entry.barOffsetX, Bars.DEFAULTS.barOffsetX))
			buffer[#buffer + 1] = tostring(segmentedCharges)
			if displayMode == Bars.DISPLAY_MODE.BAR and barMode == Bars.BAR_MODE.CHARGES and segmentedCharges == true then
				buffer[#buffer + 1] = tostring(Bars.GetEntryChargeSegmentCountHint(entry, 3))
			else
				buffer[#buffer + 1] = ""
			end
			buffer[#buffer + 1] = tostring(normalizeBarChargesGap(entry.barChargesGap, Bars.DEFAULTS.barChargesGap))
			buffer[#buffer + 1] = tostring(normalizeBarSegmentDirection(entry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection))
			buffer[#buffer + 1] = tostring(Helper.NormalizeFixedGroupId(entry.fixedGroupId) or "")
			buffer[#buffer + 1] = tostring(Helper.NormalizeSlotCoordinate(entry.slotColumn) or "")
			buffer[#buffer + 1] = tostring(Helper.NormalizeSlotCoordinate(entry.slotRow) or "")
		end
	end
	return table.concat(buffer, "|")
end

Bars.MarkReservationCacheDirty = function(panel)
	if type(panel) ~= "table" then return end
	panel._eqolBarsReservationDirty = true
end

local function augmentFixedLayoutCache(panel, cache)
	if not (panel and cache and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout)) then return cache end
	if
		panel._eqolBarsReservationDirty ~= true
		and cache._eqolBarsReservedOwnerByCell
		and cache._eqolBarsReservedOwnerByIndex
		and cache._eqolBarsEffectiveSpanByEntryId
		and cache._eqolBarsAnchorCellByEntryId
	then
		return cache
	end
	local signature = getReservationSignature(panel)
	if
		panel._eqolBarsReservationDirty ~= true
		and cache._eqolBarsReservationSignature == signature
		and cache._eqolBarsReservedOwnerByCell
		and cache._eqolBarsReservedOwnerByIndex
		and cache._eqolBarsEffectiveSpanByEntryId
		and cache._eqolBarsAnchorCellByEntryId
	then
		return cache
	end

	local reservedOwnerByCell = cache._eqolBarsReservedOwnerByCell or {}
	local reservedOwnerByIndex = cache._eqolBarsReservedOwnerByIndex or {}
	local effectiveSpanByEntryId = cache._eqolBarsEffectiveSpanByEntryId or {}
	local anchorCellByEntryId = cache._eqolBarsAnchorCellByEntryId or {}

	wipe(reservedOwnerByCell)
	wipe(reservedOwnerByIndex)
	wipe(effectiveSpanByEntryId)
	wipe(anchorCellByEntryId)
	cache._eqolBarsSlotIndexByEntryId = nil
	getSlotIndexByEntryId(cache)

	local boundsColumns = cache.boundsColumns or 0
	for _, entryId in ipairs(panel.order or {}) do
		local entry = panel.entries and panel.entries[entryId] or nil
		if entry and normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) == Bars.DISPLAY_MODE.BAR then
			local mode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
			if supportsBarMode(entry, mode) then
				local column, row = getAnchorCellFromCache(cache, entryId, entry)
				local effectiveSpan = 1
				if column and row then
					anchorCellByEntryId[entryId] = { column = column, row = row }
					local maxEndColumn = boundsColumns
					local groupId = Helper.NormalizeFixedGroupId(entry.fixedGroupId)
					if groupId and cache.groupById then
						local group = cache.groupById[groupId]
						if group then
							if CooldownPanels.IsFixedGroupStatic and CooldownPanels:IsFixedGroupStatic(group) and row >= group.row and row <= (group.row + group.rows - 1) then
								maxEndColumn = min(maxEndColumn, group.column + group.columns - 1)
							else
								maxEndColumn = column
							end
						end
					end
					local wantedSpan = getDesiredBarSpan(panel, entry)
					local reservedColumns, visualSpan = getHorizontalSegmentReservationColumns(panel, entry, column, maxEndColumn)
					if reservedColumns then
						effectiveSpan = min(maxEndColumn - column + 1, visualSpan or wantedSpan or 1)
						for index = 1, #reservedColumns do
							local reservedColumn = reservedColumns[index]
							if reservedColumn ~= column then
								local occupantId = getBaseOccupantAtCell(cache, entry, reservedColumn, row)
								local reservedKey = getCellKey(reservedColumn, row)
								local reservedOwner = reservedOwnerByCell[reservedKey]
								if not ((occupantId and occupantId ~= entryId) or (reservedOwner and reservedOwner ~= entryId)) then
									reservedOwnerByCell[reservedKey] = entryId
									if boundsColumns > 0 then reservedOwnerByIndex[((row - 1) * boundsColumns) + reservedColumn] = entryId end
								end
							end
						end
					elseif maxEndColumn > column and wantedSpan > 1 then
						for candidateColumn = column + 1, min(maxEndColumn, column + wantedSpan - 1) do
							local occupantId = getBaseOccupantAtCell(cache, entry, candidateColumn, row)
							local reservedKey = getCellKey(candidateColumn, row)
							local reservedOwner = reservedOwnerByCell[reservedKey]
							if (occupantId and occupantId ~= entryId) or (reservedOwner and reservedOwner ~= entryId) then break end
							effectiveSpan = effectiveSpan + 1
						end
						for reservedColumn = column + 1, column + effectiveSpan - 1 do
							local reservedKey = getCellKey(reservedColumn, row)
							reservedOwnerByCell[reservedKey] = entryId
							if boundsColumns > 0 then reservedOwnerByIndex[((row - 1) * boundsColumns) + reservedColumn] = entryId end
						end
					end
				end
				effectiveSpanByEntryId[entryId] = effectiveSpan
			end
		end
	end

	cache._eqolBarsReservationSignature = signature
	cache._eqolBarsReservedOwnerByCell = reservedOwnerByCell
	cache._eqolBarsReservedOwnerByIndex = reservedOwnerByIndex
	cache._eqolBarsEffectiveSpanByEntryId = effectiveSpanByEntryId
	cache._eqolBarsAnchorCellByEntryId = anchorCellByEntryId
	panel._eqolBarsReservationDirty = false
	return cache
end

local function getReservedOwnerForCell(panel, column, row, skipEntryId, cache)
	column = Helper.NormalizeSlotCoordinate(column)
	row = Helper.NormalizeSlotCoordinate(row)
	if not (panel and column and row) then return nil end
	cache = cache or (Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil)
	cache = augmentFixedLayoutCache(panel, cache)
	local ownerId = cache and cache._eqolBarsReservedOwnerByCell and cache._eqolBarsReservedOwnerByCell[getCellKey(column, row)] or nil
	if ownerId and ownerId ~= skipEntryId then return ownerId, panel.entries and panel.entries[ownerId] or nil end
	return nil
end

local function isAnchorCell(panel, entryId, column, row, cache)
	column = Helper.NormalizeSlotCoordinate(column)
	row = Helper.NormalizeSlotCoordinate(row)
	entryId = normalizeId(entryId)
	if not (panel and entryId and column and row) then return false end
	cache = cache or (Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil)
	cache = augmentFixedLayoutCache(panel, cache)
	local anchor = cache and cache._eqolBarsAnchorCellByEntryId and cache._eqolBarsAnchorCellByEntryId[entryId] or nil
	return anchor and anchor.column == column and anchor.row == row or false
end

local function getEffectiveBarSpan(panel, entryId, cache)
	local panelEntryId = normalizeId(entryId)
	if not (panel and panelEntryId) then return 1 end
	cache = cache or (Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil)
	cache = augmentFixedLayoutCache(panel, cache)
	return cache and cache._eqolBarsEffectiveSpanByEntryId and cache._eqolBarsEffectiveSpanByEntryId[panelEntryId] or 1
end

getBarColor = function(mode)
	local color = Bars.COLORS[mode] or Bars.COLORS.COOLDOWN
	return color[1], color[2], color[3], color[4]
end

local function ensureBarUpdater() return nil end

local function trackBarAnimation(barFrame) return end

local function stopBarAnimation(barFrame)
	local runtime = getRuntimeState()
	if runtime.activeBars then runtime.activeBars[barFrame] = nil end
	if Bars.updateFrame and Bars.updateFrame.Hide then Bars.updateFrame:Hide() end
end

local function applyStatusBarTexture(statusBar, texturePath)
	if not statusBar then return end
	local resolvedTexture = texturePath or "Interface\\TargetingFrame\\UI-StatusBar"
	if statusBar._eqolStatusBarTexturePath ~= resolvedTexture then
		statusBar:SetStatusBarTexture(resolvedTexture)
		statusBar._eqolStatusBarTexturePath = resolvedTexture
	end
	local texture = statusBar:GetStatusBarTexture()
	if texture ~= statusBar._eqolStatusBarTexture then
		if texture and texture.SetSnapToPixelGrid then
			texture:SetSnapToPixelGrid(false)
			texture:SetTexelSnappingBias(0)
		end
		statusBar._eqolStatusBarTexture = texture
	end
end

local function applyStatusBarOrientation(statusBar, orientation)
	if not (statusBar and statusBar.SetOrientation) then return end
	local resolvedOrientation = type(orientation) == "string" and string.upper(orientation) or nil
	if resolvedOrientation ~= BAR_ORIENTATION_VERTICAL then resolvedOrientation = BAR_ORIENTATION_HORIZONTAL end
	if statusBar._eqolOrientation ~= resolvedOrientation then
		statusBar:SetOrientation(resolvedOrientation)
		statusBar._eqolOrientation = resolvedOrientation
	end
end

local function applyBackdropFrame(frame, edgeFile, edgeSize)
	if not frame then return end
	local resolvedEdge = hasTextValue(edgeFile) and not isSecretValue(edgeFile) and edgeFile or "Interface\\Buttons\\WHITE8x8"
	local resolvedSize = max(edgeSize or 0, 1)
	local signature = resolvedEdge .. "|" .. tostring(edgeSize or 0)
	if frame._eqolBackdropSignature == signature then return end
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = resolvedEdge,
		edgeSize = resolvedSize,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frame._eqolBackdropSignature = signature
end

Bars.GetBarFillInset = function(borderSize, effectiveScale, width, height)
	return 0
end

Bars.ApplyBarIconBorder = function(barFrame, showIcon, borderTexturePath, borderSize, borderOffset, borderColor)
	if not (barFrame and barFrame.iconBorder and barFrame.iconHolder) then return end
	if showIcon and borderSize > 0 and barFrame.iconHolder:IsShown() then
		local border = barFrame.iconBorder
		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", barFrame.iconHolder, "TOPLEFT", -borderOffset, borderOffset)
		border:SetPoint("BOTTOMRIGHT", barFrame.iconHolder, "BOTTOMRIGHT", borderOffset, -borderOffset)
		applyBackdropFrame(border, borderTexturePath, borderSize)
		border:SetBackdropColor(0, 0, 0, 0)
		border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
		border:Show()
	else
		barFrame.iconBorder:Hide()
	end
end

local function ensureBarSegment(frame, index)
	frame.segments = frame.segments or {}
	local segment = frame.segments[index]
	if segment then return segment end
	segment = CreateFrame("Frame", nil, frame.body, "BackdropTemplate")
	segment:SetClampedToScreen(false)
	segment:SetMovable(false)
	segment:EnableMouse(false)
	if segment.SetClipsChildren then
		segment:SetClipsChildren(true)
	end
	segment.fill = CreateFrame("StatusBar", nil, segment)
	segment.fill:SetPoint("TOPLEFT", segment, "TOPLEFT", 0, 0)
	segment.fill:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", 0, 0)
	segment.fill:SetMinMaxValues(0, 1)
	segment.fill:SetValue(0)
	applyStatusBarTexture(segment.fill, "Interface\\TargetingFrame\\UI-StatusBar")
	segment.fillBg = segment.fill:CreateTexture(nil, "BACKGROUND")
	segment.fillBg:SetAllPoints(segment.fill)
	segment.fillBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	segment.fillBg:SetVertexColor(0, 0, 0, 0.35)
	segment.borderOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	segment.borderOverlay:SetClampedToScreen(false)
	segment.borderOverlay:SetMovable(false)
	segment.borderOverlay:EnableMouse(false)
	segment.hitHandle = CreateFrame("Button", nil, segment)
	segment.hitHandle:SetAllPoints(segment)
	segment.hitHandle:EnableMouse(false)
	segment.hitHandle:Hide()
	segment:Hide()
	frame.segments[index] = segment
	return segment
end

Bars.EnsureChargeSegmentTracker = function(frame)
	if not frame then return nil end
	if frame.chargeSegmentTracker then return frame.chargeSegmentTracker, frame.chargeSegmentRefresh end
	local parent = frame.body or frame
	local tracker = CreateFrame("StatusBar", nil, parent)
	tracker:SetMinMaxValues(0, 1)
	tracker:SetValue(0)
	tracker:SetAlpha(0)
	tracker:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	applyStatusBarTexture(tracker, "Interface\\TargetingFrame\\UI-StatusBar")
	applyStatusBarOrientation(tracker, BAR_ORIENTATION_HORIZONTAL)

	local refresh = CreateFrame("Frame", nil, parent)
	refresh:SetClampedToScreen(false)
	refresh:SetMovable(false)
	refresh:EnableMouse(false)
	if refresh.SetClipsChildren then refresh:SetClipsChildren(true) end
	refresh.fill = CreateFrame("StatusBar", nil, refresh)
	refresh.fill:SetPoint("TOPLEFT", refresh, "TOPLEFT", 0, 0)
	refresh.fill:SetPoint("BOTTOMRIGHT", refresh, "BOTTOMRIGHT", 0, 0)
	refresh.fill:SetMinMaxValues(0, 1)
	refresh.fill:SetValue(0)
	applyStatusBarTexture(refresh.fill, "Interface\\TargetingFrame\\UI-StatusBar")
	applyStatusBarOrientation(refresh.fill, BAR_ORIENTATION_HORIZONTAL)
	refresh:Hide()

	frame.chargeSegmentTracker = tracker
	frame.chargeSegmentRefresh = refresh
	return tracker, refresh
end

Bars.HideChargeSegmentTracker = function(frame)
	if not frame then return end
	frame._eqolChargeSegmentRefreshTextAnchor = nil
	local tracker = frame.chargeSegmentTracker
	if tracker then
		tracker:SetValue(0)
		tracker:Hide()
	end
	local refresh = frame.chargeSegmentRefresh
	if refresh then
		if refresh.fill then setStatusBarImmediateValue(refresh.fill, 0) end
		refresh:Hide()
	end
end

Bars.EnsureBarDivider = function(frame, index)
	if not frame then return nil end
	frame.stackDividers = frame.stackDividers or {}
	local divider = frame.stackDividers[index]
	if divider then return divider end
	local parent = frame.dividerOverlay or frame.body or frame
	divider = parent:CreateTexture(nil, "ARTWORK")
	divider:SetTexture("Interface\\Buttons\\WHITE8x8")
	if divider.SetTexelSnappingBias then
		divider:SetTexelSnappingBias(0)
		divider:SetSnapToPixelGrid(false)
	end
	divider:Hide()
	frame.stackDividers[index] = divider
	return divider
end

Bars.HideUnusedBarDividers = function(frame, firstIndex)
	if not frame then return end
	if frame.dividerOverlay then frame.dividerOverlay:Hide() end
	if not frame.stackDividers then return end
	for index = firstIndex or 1, #frame.stackDividers do
		local divider = frame.stackDividers[index]
		if divider then divider:Hide() end
	end
end

Bars.LayoutStackDividers = function(frame, orientation, stackMax, bodyWidth, bodyHeight, color, effectiveScale, dividerThickness)
	if not (frame and frame.dividerOverlay) then return end
	local resolvedMax = Helper.ClampInt(stackMax, 1, 1000, 1)
	local dividerCount = max(0, resolvedMax - 1)
	if dividerCount <= 0 then
		Bars.HideUnusedBarDividers(frame, 1)
		return
	end

	local axisSize = orientation == BAR_ORIENTATION_VERTICAL and bodyHeight or bodyWidth
	local maxVisibleDividers = max(0, floor(axisSize / 3) - 1)
	if maxVisibleDividers <= 0 then
		Bars.HideUnusedBarDividers(frame, 1)
		return
	end

	local step = max(1, math.ceil(dividerCount / maxVisibleDividers))
	local dividerColor = Helper.NormalizeColor(color, Bars.DEFAULTS.barStackDividerColor)
	local dividerAlpha = min(1, max(dividerColor[4] or 1, 0))
	local requestedThickness = normalizeBarStackDividerThickness(dividerThickness, Bars.DEFAULTS.barStackDividerThickness)
	local dividerThicknessPixels = max(pixelSnap(requestedThickness, effectiveScale), 1)
	local overlayLeft = frame.dividerOverlay.GetLeft and frame.dividerOverlay:GetLeft() or nil
	local overlayTop = frame.dividerOverlay.GetTop and frame.dividerOverlay:GetTop() or nil
	local visibleIndex = 1

	for boundary = 1, dividerCount, step do
		local rawOffset = (axisSize * boundary) / resolvedMax
		local divider = Bars.EnsureBarDivider(frame, visibleIndex)
		local offset = nil
		divider:ClearAllPoints()
		divider:SetColorTexture(dividerColor[1], dividerColor[2], dividerColor[3], dividerAlpha)
		if orientation == BAR_ORIENTATION_VERTICAL then
			offset = overlayTop and (pixelSnap(overlayTop - rawOffset, effectiveScale) - overlayTop) or -pixelSnap(rawOffset, effectiveScale)
			local appliedOffset = -offset
			if appliedOffset > 0 and appliedOffset < axisSize then
				divider:SetPoint("TOPLEFT", frame.dividerOverlay, "TOPLEFT", 0, offset)
				divider:SetPoint("TOPRIGHT", frame.dividerOverlay, "TOPRIGHT", 0, offset)
				divider:SetHeight(dividerThicknessPixels)
				divider:Show()
				visibleIndex = visibleIndex + 1
			end
		else
			offset = overlayLeft and (pixelSnap(overlayLeft + rawOffset, effectiveScale) - overlayLeft) or pixelSnap(rawOffset, effectiveScale)
			if offset > 0 and offset < axisSize then
				divider:SetPoint("TOPLEFT", frame.dividerOverlay, "TOPLEFT", offset, 0)
				divider:SetPoint("BOTTOMLEFT", frame.dividerOverlay, "BOTTOMLEFT", offset, 0)
				divider:SetWidth(dividerThicknessPixels)
				divider:Show()
				visibleIndex = visibleIndex + 1
			end
		end
	end

	Bars.HideUnusedBarDividers(frame, visibleIndex)
	if visibleIndex > 1 then frame.dividerOverlay:Show() end
end

local function clearCooldownFrame(frame)
	if not frame then return end
	if frame.Clear then
		frame:Clear()
	elseif CooldownFrame_Clear then
		CooldownFrame_Clear(frame)
	else
		frame:Hide()
	end
	if frame.Hide then frame:Hide() end
	frame._eqolDurationObject = nil
	frame._eqolDurationKey = nil
end

Bars.GuardCooldownVisuals = Bars.GuardCooldownVisuals or function(cooldown)
	if not cooldown then return end
	if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(false) end
	if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
	if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
	cooldown._eqolDrawSwipe = false
	cooldown._eqolDrawEdge = false
	cooldown._eqolDrawBling = false
end

local function ensureBarCooldownGate(frame)
	if frame._eqolCooldownGate then
		Bars.GuardCooldownVisuals(frame._eqolCooldownGate)
		return frame._eqolCooldownGate
	end
	local gate = CreateFrame("Cooldown", nil, frame.body or frame, "CooldownFrameTemplate")
	gate:SetAllPoints(frame.body or frame)
	Bars.GuardCooldownVisuals(gate)
	if gate.SetHideCountdownNumbers then gate:SetHideCountdownNumbers(true) end
	if gate.SetAlpha then gate:SetAlpha(0) end
	if gate.EnableMouse then gate:EnableMouse(false) end
	gate:Hide()
	frame._eqolCooldownGate = gate
	return gate
end

local function setCooldownFrameDuration(frame, durationObject, cacheKey)
	if not frame then return false end
	if durationObject and frame.SetCooldownFromDurationObject then
		local appliedKey = cacheKey or durationObject
		if frame._eqolDurationKey ~= appliedKey or frame._eqolDurationObject ~= durationObject then
			clearCooldownFrame(frame)
			frame:SetCooldownFromDurationObject(durationObject)
			frame._eqolDurationObject = durationObject
			frame._eqolDurationKey = appliedKey
		end
		return true
	end
	if frame._eqolDurationObject ~= nil then clearCooldownFrame(frame) end
	frame._eqolDurationKey = nil
	return false
end

Bars.RequestChargeBarPanelRefresh = function(panelId)
	if not (CooldownPanels and panelId) then return end
	if CooldownPanels.RequestPanelRefresh then
		CooldownPanels:RequestPanelRefresh(panelId)
	elseif CooldownPanels.RefreshPanel then
		CooldownPanels:RefreshPanel(panelId)
	end
end

Bars.InvalidateChargeBarSpellCaches = function(spellId)
	spellId = safeNumber(spellId)
	if not (spellId and CooldownPanels and CooldownPanels.InvalidateSpellQueryCaches) then return end
	CooldownPanels:InvalidateSpellQueryCaches("info", spellId)
	CooldownPanels:InvalidateSpellQueryCaches("duration", spellId)
	CooldownPanels:InvalidateSpellQueryCaches("charges", spellId)
	CooldownPanels:InvalidateSpellQueryCaches("chargeDuration", spellId)
	local overrideSpellId = Api.GetOverrideSpell and safeNumber(Api.GetOverrideSpell(spellId)) or nil
	if overrideSpellId and overrideSpellId ~= spellId then
		CooldownPanels:InvalidateSpellQueryCaches("info", overrideSpellId)
		CooldownPanels:InvalidateSpellQueryCaches("duration", overrideSpellId)
		CooldownPanels:InvalidateSpellQueryCaches("charges", overrideSpellId)
		CooldownPanels:InvalidateSpellQueryCaches("chargeDuration", overrideSpellId)
	end
end

Bars.OnChargeGateCooldownDone = function(self)
	if not self then return end
	Bars.InvalidateChargeBarSpellCaches(self._eqolSpellId)
	Bars.RequestChargeBarPanelRefresh(self._eqolPanelId)
end

Bars.ClearChargeGateCooldown = function(barFrame)
	local gate = barFrame and barFrame._eqolCooldownGate or nil
	if not gate then return end
	if gate.SetScript then gate:SetScript("OnCooldownDone", nil) end
	gate._eqolPanelId = nil
	gate._eqolEntryId = nil
	gate._eqolSpellId = nil
	clearCooldownFrame(gate)
end

Bars.ScheduleChargeTimerHandoffRefresh = function(state)
	if not (state and state.panelId) then return end
	local panelId = state.panelId
	local spellId = state.spellId
	local entryKey = state.entryKey or state.entryId
	if not entryKey then
		Bars.RequestChargeBarPanelRefresh(panelId)
		return
	end
	local runtime = getRuntimeState()
	local pending = runtime.pendingChargeTimerHandoffRefreshByEntryKey or {}
	runtime.pendingChargeTimerHandoffRefreshByEntryKey = pending
	if pending[entryKey] == true then return end
	pending[entryKey] = true

	local function refresh()
		local activeRuntime = getRuntimeState()
		local activePending = activeRuntime.pendingChargeTimerHandoffRefreshByEntryKey
		if activePending then activePending[entryKey] = nil end
		Bars.InvalidateChargeBarSpellCaches(spellId)
		Bars.RequestChargeBarPanelRefresh(panelId)
	end

	RunNextFrame(refresh)
end

local function hideUnusedBarSegments(frame, firstIndex)
	if not (frame and frame.segments) then return end
	for index = firstIndex or 1, #frame.segments do
		local segment = frame.segments[index]
		if segment then
			if segment.borderOverlay then segment.borderOverlay:Hide() end
			segment:Hide()
		end
	end
end

local function ensureBarFrame(icon)
	if icon._eqolBarsFrame then return icon._eqolBarsFrame end
	local parent = (icon.slotAnchor and icon.slotAnchor:GetParent()) or icon:GetParent() or UIParent
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetClampedToScreen(false)
	frame:SetMovable(false)
	frame:EnableMouse(false)

	frame.body = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.body:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	if frame.body.SetClipsChildren then
		frame.body:SetClipsChildren(true)
	end
	applyBackdropFrame(frame.body, "Interface\\Buttons\\WHITE8x8", 1)
	frame.body:SetBackdropColor(unpack(Bars.COLORS.Background))
	frame.body:SetBackdropBorderColor(unpack(Bars.COLORS.Border))
	frame.borderOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.borderOverlay:SetClampedToScreen(false)
	frame.borderOverlay:SetMovable(false)
	frame.borderOverlay:EnableMouse(false)

	frame.fill = CreateFrame("StatusBar", nil, frame.body)
	frame.fill:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 0, 0)
	frame.fill:SetPoint("BOTTOMRIGHT", frame.body, "BOTTOMRIGHT", 0, 0)
	frame.fill:SetMinMaxValues(0, 1)
	frame.fill:SetValue(0)
	applyStatusBarTexture(frame.fill, "Interface\\TargetingFrame\\UI-StatusBar")

	frame.fillBg = frame.fill:CreateTexture(nil, "BACKGROUND")
	frame.fillBg:SetAllPoints(frame.fill)
	frame.fillBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	frame.fillBg:SetVertexColor(0, 0, 0, 0.35)
	frame.inactiveDurationFill = frame.fill:CreateTexture(nil, "OVERLAY")
	frame.inactiveDurationFill:SetAllPoints(frame.fill)
	frame.inactiveDurationFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.inactiveDurationFill:SetVertexColor(0.30, 0.88, 0.46, 1)
	frame.inactiveDurationFill:SetAlpha(0)
	frame.dividerOverlay = CreateFrame("Frame", nil, frame.body)
	frame.dividerOverlay:SetAllPoints(frame.body)
	frame.dividerOverlay:EnableMouse(false)
	frame.dividerOverlay:Hide()

	frame.iconOverlay = CreateFrame("Frame", nil, frame)
	frame.iconOverlay:SetAllPoints(frame)
	frame.iconOverlay:EnableMouse(false)

	frame.iconHolder = CreateFrame("Frame", nil, frame.iconOverlay)
	frame.iconHolder:SetClampedToScreen(false)
	frame.iconHolder:SetMovable(false)
	frame.iconHolder:EnableMouse(false)
	frame.iconHolder:Hide()

	frame.icon = frame.iconHolder:CreateTexture(nil, "OVERLAY")
	frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	frame.icon:Hide()

	frame.iconBorder = CreateFrame("Frame", nil, frame.iconHolder, "BackdropTemplate")
	frame.iconBorder:SetClampedToScreen(false)
	frame.iconBorder:SetMovable(false)
	frame.iconBorder:EnableMouse(false)
	frame.iconBorder:Hide()

	frame.textOverlay = CreateFrame("Frame", nil, frame)
	frame.textOverlay:SetAllPoints(frame)
	frame.textOverlay:EnableMouse(false)

	frame.hitHandle = CreateFrame("Button", nil, frame)
	frame.hitHandle:SetAllPoints(frame)
	frame.hitHandle:SetFrameStrata(frame:GetFrameStrata() or parent:GetFrameStrata())
	frame.hitHandle:SetFrameLevel((frame:GetFrameLevel() or parent:GetFrameLevel()) + 20)
	frame.hitHandle:EnableMouse(false)
	frame.hitHandle:Hide()

	frame.label = frame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.label:SetJustifyH("LEFT")
	frame.label:SetTextColor(unpack(Bars.COLORS.Label))
	frame.label:SetShadowOffset(1, -1)
	frame.label:Hide()

	frame.value = frame.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.value:SetJustifyH("RIGHT")
	frame.value:SetTextColor(unpack(Bars.COLORS.Value))
	frame.value:SetShadowOffset(1, -1)
	frame.value:Hide()

	frame.stackCount = frame.textOverlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	frame.stackCount:SetJustifyH("RIGHT")
	frame.stackCount:SetTextColor(unpack(Bars.COLORS.Label))
	frame.stackCount:SetShadowOffset(1, -1)
	frame.stackCount:Hide()

	frame.segments = {}
	frame.stackDividers = {}
	frame._eqolBarState = nil
	frame._eqolSegmentCount = 0
	frame:Hide()
	icon._eqolBarsFrame = frame
	return frame
end

Bars.HideForwardHitHandle = function(hitHandle)
	if not hitHandle then return end
	if hitHandle._eqolBarsFreeMoveActive == true then
		hitHandle._eqolBarsFreeMoveActive = nil
		Bars.StopFreeMove(false)
	end
	hitHandle:EnableMouse(false)
	hitHandle:Hide()
	hitHandle._eqolForwardHandle = nil
	hitHandle._eqolBarsBarFrame = nil
	hitHandle._eqolBarsIcon = nil
end

Bars.InvokeForwardHitHandleScript = function(hitHandle, scriptName, ...)
	local handle = hitHandle and hitHandle._eqolForwardHandle or nil
	local script = handle and handle.GetScript and handle:GetScript(scriptName) or nil
	if script then return script(handle, ...) end
	return nil
end

Bars.OnForwardHitHandleEnter = function(hitHandle) Bars.InvokeForwardHitHandleScript(hitHandle, "OnEnter") end

Bars.OnForwardHitHandleLeave = function(hitHandle) Bars.InvokeForwardHitHandleScript(hitHandle, "OnLeave") end

Bars.OnForwardHitHandleReceiveDrag = function(hitHandle) Bars.InvokeForwardHitHandleScript(hitHandle, "OnReceiveDrag") end

Bars.OnForwardHitHandleMouseUp = function(hitHandle, button) Bars.InvokeForwardHitHandleScript(hitHandle, "OnMouseUp", button) end

Bars.OnForwardHitHandleDragStart = function(hitHandle)
	if IsShiftKeyDown and IsShiftKeyDown() then
		Bars.InvokeForwardHitHandleScript(hitHandle, "OnDragStart")
		return
	end
	hitHandle._eqolBarsFreeMoveActive = Bars.StartFreeMove(hitHandle, hitHandle._eqolBarsBarFrame, hitHandle._eqolBarsIcon) == true
	if hitHandle._eqolBarsFreeMoveActive ~= true then Bars.InvokeForwardHitHandleScript(hitHandle, "OnDragStart") end
end

Bars.OnForwardHitHandleDragStop = function(hitHandle)
	if hitHandle._eqolBarsFreeMoveActive == true then
		hitHandle._eqolBarsFreeMoveActive = nil
		Bars.StopFreeMove(true)
		return
	end
	Bars.InvokeForwardHitHandleScript(hitHandle, "OnDragStop")
end

Bars.InstallForwardHitHandleScripts = function(hitHandle)
	if not hitHandle or hitHandle._eqolBarsForwardScriptsInstalled == true then return end
	hitHandle:SetScript("OnEnter", Bars.OnForwardHitHandleEnter)
	hitHandle:SetScript("OnLeave", Bars.OnForwardHitHandleLeave)
	hitHandle:SetScript("OnDragStart", Bars.OnForwardHitHandleDragStart)
	hitHandle:SetScript("OnDragStop", Bars.OnForwardHitHandleDragStop)
	hitHandle:SetScript("OnReceiveDrag", Bars.OnForwardHitHandleReceiveDrag)
	hitHandle:SetScript("OnMouseUp", Bars.OnForwardHitHandleMouseUp)
	hitHandle._eqolBarsForwardScriptsInstalled = true
end

Bars.ConfigureForwardHitHandle = function(hitHandle, anchorFrame, forwardHandle)
	if not (hitHandle and anchorFrame and forwardHandle and forwardHandle.IsShown and forwardHandle:IsShown()) then
		Bars.HideForwardHitHandle(hitHandle)
		return
	end
	hitHandle:ClearAllPoints()
	hitHandle:SetAllPoints(anchorFrame)
	hitHandle:SetFrameStrata(anchorFrame:GetFrameStrata())
	hitHandle:SetFrameLevel(anchorFrame:GetFrameLevel() + 20)
	hitHandle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	hitHandle:RegisterForDrag("LeftButton")
	Bars.InstallForwardHitHandleScripts(hitHandle)
	hitHandle._eqolForwardHandle = forwardHandle
	hitHandle:EnableMouse(true)
	hitHandle:Show()
end

Bars.StopFreeMove = function(commit)
	local runtime = getRuntimeState()
	local move = runtime and runtime.barFreeMove or nil
	if not move then return false end
	if move.hitHandle and move.hitHandle.SetScript then move.hitHandle:SetScript("OnUpdate", nil) end
	if move.barFrame and move.anchorFrame then
		move.barFrame:ClearAllPoints()
		move.barFrame:SetPoint(
			move.anchorPoint or "LEFT",
			move.anchorFrame,
			move.relativePoint or move.anchorPoint or "LEFT",
			(move.anchorBaseX or 0) + (move.currentOffsetX or move.startOffsetX or 0),
			(move.anchorBaseY or 0) + (move.currentOffsetY or move.startOffsetY or 0)
		)
	end
	runtime.barFreeMove = nil
	if commit == true and move.panelId and move.entryId then
		local targetOffsetX = normalizeBarOffset(move.currentOffsetX, move.startOffsetX or Bars.DEFAULTS.barOffsetX)
		local targetOffsetY = normalizeBarOffset(move.currentOffsetY, move.startOffsetY or Bars.DEFAULTS.barOffsetY)
		if targetOffsetX ~= move.startOffsetX or targetOffsetY ~= move.startOffsetY then
			mutateBarEntry(move.panelId, move.entryId, function(entry)
				entry.barOffsetX = targetOffsetX
				entry.barOffsetY = targetOffsetY
			end)
			return true
		end
	end
	return false
end

Bars.StartFreeMove = function(hitHandle, barFrame, icon)
	local state = barFrame and barFrame._eqolBarState or nil
	local panelId = state and normalizeId(state.panelId) or nil
	local entryId = state and normalizeId(state.entryId) or nil
	if not (hitHandle and barFrame and icon and panelId and entryId) then return false end
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if not (panel and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout)) then return false end
	if not (CooldownPanels.IsPanelLayoutEditActive and CooldownPanels:IsPanelLayoutEditActive(panelId)) then return false end
	local cursorX, cursorY = nil, nil
	if CooldownPanels.GetCursorPositionOnUIParent then
		cursorX, cursorY = CooldownPanels:GetCursorPositionOnUIParent()
	end
	if not (cursorX and cursorY) then return false end
	local runtime = getRuntimeState()
	runtime.barFreeMove = {
		hitHandle = hitHandle,
		barFrame = barFrame,
		anchorFrame = barFrame._eqolAnchorFrame or icon.slotAnchor or icon,
		anchorPoint = barFrame._eqolAnchorPoint or "LEFT",
		relativePoint = barFrame._eqolAnchorRelativePoint or barFrame._eqolAnchorPoint or "LEFT",
		anchorBaseX = barFrame._eqolAnchorBaseX or 0,
		anchorBaseY = barFrame._eqolAnchorBaseY or 0,
		panelId = panelId,
		entryId = entryId,
		startCursorX = cursorX,
		startCursorY = cursorY,
		startOffsetX = normalizeBarOffset(state.barOffsetX, Bars.DEFAULTS.barOffsetX),
		startOffsetY = normalizeBarOffset(state.barOffsetY, Bars.DEFAULTS.barOffsetY),
		currentOffsetX = normalizeBarOffset(state.barOffsetX, Bars.DEFAULTS.barOffsetX),
		currentOffsetY = normalizeBarOffset(state.barOffsetY, Bars.DEFAULTS.barOffsetY),
	}
	hitHandle:SetScript("OnUpdate", function(self)
		local activeRuntime = getRuntimeState()
		local move = activeRuntime and activeRuntime.barFreeMove or nil
		if not move or move.hitHandle ~= self then
			self:SetScript("OnUpdate", nil)
			return
		end
		local currentCursorX, currentCursorY = nil, nil
		if CooldownPanels.GetCursorPositionOnUIParent then
			currentCursorX, currentCursorY = CooldownPanels:GetCursorPositionOnUIParent()
		end
		if not (currentCursorX and currentCursorY) then return end
		move.currentOffsetX = normalizeBarOffset(move.startOffsetX + (currentCursorX - move.startCursorX), move.startOffsetX)
		move.currentOffsetY = normalizeBarOffset(move.startOffsetY + (currentCursorY - move.startCursorY), move.startOffsetY)
		if move.barFrame and move.anchorFrame then
			move.barFrame:ClearAllPoints()
			move.barFrame:SetPoint(
				move.anchorPoint or "LEFT",
				move.anchorFrame,
				move.relativePoint or move.anchorPoint or "LEFT",
				(move.anchorBaseX or 0) + move.currentOffsetX,
				(move.anchorBaseY or 0) + move.currentOffsetY
			)
			if move.barFrame._eqolBarState then
				move.barFrame._eqolBarState.barOffsetX = move.currentOffsetX
				move.barFrame._eqolBarState.barOffsetY = move.currentOffsetY
			end
		end
	end)
	return true
end

Bars.ConfigureFreeMoveHandle = function(hitHandle, barFrame, icon)
	if not hitHandle then return end
	Bars.InstallForwardHitHandleScripts(hitHandle)
	hitHandle._eqolBarsBarFrame = barFrame
	hitHandle._eqolBarsIcon = icon
end

Bars.GetEditorGridCell = function(panelId, column, row)
	panelId = normalizeId(panelId)
	column = Helper.NormalizeSlotCoordinate(column)
	row = Helper.NormalizeSlotCoordinate(row)
	if not (panelId and column and row) then return nil end
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[panelId] or nil
	local frame = runtime and runtime.frame or nil
	local grid = frame and frame.editGrid or nil
	local cells = grid and grid.cells or nil
	if not cells then return nil end
	for index = 1, #cells do
		local cell = cells[index]
		if cell and cell.IsShown and cell:IsShown() and Helper.NormalizeSlotCoordinate(cell._eqolLayoutSlotColumn) == column and Helper.NormalizeSlotCoordinate(cell._eqolLayoutSlotRow) == row then
			return cell
		end
	end
	return nil
end

local function hideBarHitHandle(barFrame)
	if not barFrame then return end
	Bars.HideForwardHitHandle(barFrame.hitHandle)
	if barFrame.segments then
		for index = 1, #barFrame.segments do
			local segment = barFrame.segments[index]
			if segment and segment.hitHandle then Bars.HideForwardHitHandle(segment.hitHandle) end
		end
	end
end

local function applyFontStringStyle(fontString, fontValue, sizeValue, styleValue, colorValue, fallbackPath, fallbackSize, fallbackStyle)
	if not fontString then return end
	local fontPath = Helper.ResolveFontPath(fontValue, fallbackPath)
	local fontSize = normalizeBarFontSize(sizeValue, fallbackSize)
	local fontStyleChoice = normalizeBarFontStyle(styleValue, fallbackStyle)
	local fontStyle = Helper.NormalizeFontStyle(fontStyleChoice, fallbackStyle) or ""
	if
		fontString.SetFont
		and (
			fontString._eqolBarsFontPath ~= fontPath
			or fontString._eqolBarsFontSize ~= fontSize
			or fontString._eqolBarsFontStyle ~= fontStyle
			or fontString._eqolBarsFontFallbackPath ~= fallbackPath
		)
	then
		local applied
		if Helper.SetFont then
			applied = Helper.SetFont(fontString, fontPath, fontSize, fontStyle, fallbackPath)
		else
			applied = fontString:SetFont(fontPath, fontSize, fontStyle)
		end
		if applied == false then
			fontString:SetFont(STANDARD_TEXT_FONT, fontSize, fontStyle)
			fontString._eqolBarsFontPath = nil
			fontString._eqolBarsFontSize = nil
			fontString._eqolBarsFontStyle = nil
			fontString._eqolBarsFontFallbackPath = nil
		else
			fontString._eqolBarsFontPath = fontPath
			fontString._eqolBarsFontSize = fontSize
			fontString._eqolBarsFontStyle = fontStyle
			fontString._eqolBarsFontFallbackPath = fallbackPath
		end
	end
	local colorR, colorG, colorB, colorA = Bars.ResolvePlainRGBA(colorValue, Bars.DEFAULT_TEXT_RGBA)
	if
		fontString.SetTextColor
		and (
			fontString._eqolBarsFontColorR ~= colorR
			or fontString._eqolBarsFontColorG ~= colorG
			or fontString._eqolBarsFontColorB ~= colorB
			or fontString._eqolBarsFontColorA ~= colorA
		)
	then
		fontString:SetTextColor(colorR, colorG, colorB, colorA)
		fontString._eqolBarsFontColorR = colorR
		fontString._eqolBarsFontColorG = colorG
		fontString._eqolBarsFontColorB = colorB
		fontString._eqolBarsFontColorA = colorA
	end
	if
		addon.functions
		and addon.functions.ApplyFontStyleShadow
		and (
			fontString._eqolBarsFontShadowStyleChoice ~= fontStyleChoice
			or fontString._eqolBarsFontShadowFallbackStyle ~= fallbackStyle
		)
	then
		addon.functions.ApplyFontStyleShadow(fontString, fontStyleChoice, fallbackStyle)
		fontString._eqolBarsFontShadowStyleChoice = fontStyleChoice
		fontString._eqolBarsFontShadowFallbackStyle = fallbackStyle
	end
end

Bars.EnsureChargeDurationCountdown = function(barFrame)
	if not barFrame then return nil end
	if barFrame._eqolChargeDurationCountdown then return barFrame._eqolChargeDurationCountdown end
	local parent = barFrame.textOverlay or barFrame
	local cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
	Bars.GuardCooldownVisuals(cooldown)
	if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
	if cooldown.SetAlpha then cooldown:SetAlpha(1) end
	if cooldown.EnableMouse then cooldown:EnableMouse(false) end
	cooldown:Hide()
	barFrame._eqolChargeDurationCountdown = cooldown
	return cooldown
end

Bars.ClearChargeDurationCountdown = function(barFrame)
	if not barFrame then return end
	if addon.functions and addon.functions.ReleaseDurationTextBinding then addon.functions.ReleaseDurationTextBinding(barFrame, "valueDuration", true) end
	local cooldown = barFrame._eqolChargeDurationCountdown
	if not cooldown then return end
	clearCooldownFrame(cooldown)
	local fontString = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString() or nil
	if fontString then
		fontString:SetText("")
		fontString:Hide()
	end
end

Bars.ApplyValueDurationTextBinding = function(
	barFrame,
	state,
	relativeFrame,
	orientation,
	textWidth,
	fontPath,
	fontSize,
	fontStyle,
	fontColor,
	defaultFontPath,
	defaultFontSize,
	defaultFontStyle,
	anchor,
	offsetX,
	offsetY
)
	if not (barFrame and state and state.chargeDurationTextObject and barFrame.value and addon.functions and addon.functions.BindDurationText) then
		return Bars.ApplyChargeDurationCountdown(
			barFrame,
			state,
			relativeFrame,
			orientation,
			fontPath,
			fontSize,
			fontStyle,
			fontColor,
			defaultFontPath,
			defaultFontSize,
			defaultFontStyle,
			anchor,
			offsetX,
			offsetY
		)
	end

	Bars.ClearChargeDurationCountdown(barFrame)
	applyFontStringStyle(barFrame.value, fontPath, fontSize, fontStyle, fontColor, defaultFontPath, defaultFontSize, defaultFontStyle)
	local resolvedAnchor = Bars.GetResolvedTextAnchor(anchor, orientation, "VALUE")
	local point, relativePoint, justifyH = Bars.GetTextAnchorConfig(anchor, orientation, "VALUE")
	local anchorFrame = relativeFrame or barFrame.textOverlay
	local insetX = pixelSnap(offsetX or 0, barFrame and barFrame.textOverlay or barFrame)
	local insetY = pixelSnap(offsetY or 0, barFrame and barFrame.textOverlay or barFrame)
	local justifyV = "MIDDLE"
	local textInset = 4
	local anchorPoint = point
	local anchorRelativePoint = relativePoint
	local anchorOffsetX = insetX
	local anchorOffsetY = insetY
	if resolvedAnchor == Bars.TEXT_ANCHOR.LEFT then
		anchorPoint = "LEFT"
		anchorRelativePoint = "LEFT"
		anchorOffsetX = textInset + insetX
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.RIGHT then
		anchorPoint = "RIGHT"
		anchorRelativePoint = "RIGHT"
		anchorOffsetX = -textInset + insetX
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.TOP then
		anchorOffsetY = insetY - textInset
		justifyV = "TOP"
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.BOTTOM then
		anchorOffsetY = insetY + textInset
		justifyV = "BOTTOM"
	end

	if barFrame.value.SetWordWrap then barFrame.value:SetWordWrap(false) end
	if barFrame.value.SetNonSpaceWrap then barFrame.value:SetNonSpaceWrap(false) end
	if barFrame.value.SetMaxLines then barFrame.value:SetMaxLines(1) end
	barFrame.value:SetWidth(pixelSnap(max(24, textWidth or 0), barFrame and barFrame.textOverlay or barFrame))
	barFrame.value:ClearAllPoints()
	barFrame.value:SetPoint(anchorPoint, anchorFrame, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
	barFrame.value:SetJustifyH(justifyH)
	if barFrame.value.SetJustifyV then barFrame.value:SetJustifyV(justifyV) end
	barFrame.value:Show()

	local ok = addon.functions.BindDurationText(barFrame.value, state.chargeDurationTextObject, {
		owner = barFrame,
		key = "valueDuration",
		clearText = true,
		profileKey = state.durationTextProfile,
	})
	if not ok then
		return Bars.ApplyChargeDurationCountdown(
			barFrame,
			state,
			relativeFrame,
			orientation,
			fontPath,
			fontSize,
			fontStyle,
			fontColor,
			defaultFontPath,
			defaultFontSize,
			defaultFontStyle,
			anchor,
			offsetX,
			offsetY
		)
	end
	return true
end

Bars.ApplyChargeDurationCountdown = function(
	barFrame,
	state,
	relativeFrame,
	orientation,
	fontPath,
	fontSize,
	fontStyle,
	fontColor,
	defaultFontPath,
	defaultFontSize,
	defaultFontStyle,
	anchor,
	offsetX,
	offsetY
)
	if not (barFrame and state and state.chargeDurationTextObject) then
		Bars.ClearChargeDurationCountdown(barFrame)
		return false
	end

	local cooldown = Bars.EnsureChargeDurationCountdown(barFrame)
	if not cooldown then return false end
	local anchorFrame = relativeFrame or barFrame.textOverlay or barFrame.body or barFrame
	cooldown:SetParent(barFrame.textOverlay or barFrame)
	cooldown:ClearAllPoints()
	cooldown:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, 0)
	cooldown:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
	cooldown:SetFrameStrata((barFrame.textOverlay and barFrame.textOverlay:GetFrameStrata()) or barFrame:GetFrameStrata())
	cooldown:SetFrameLevel(((barFrame.textOverlay and barFrame.textOverlay:GetFrameLevel()) or barFrame:GetFrameLevel()) + 1)
	Bars.GuardCooldownVisuals(cooldown)
	if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
	if cooldown.SetAlpha then cooldown:SetAlpha(1) end

	local durationKey = table.concat({
		"charge-duration-text",
		tostring(state.entryKey or state.entryId or "nil"),
		tostring(state.chargeDurationTextSegmentIndex or "nil"),
		tostring(state.renderChargePhase or state.chargePhase or "nil"),
	}, ":")
	if not setCooldownFrameDuration(cooldown, state.chargeDurationTextObject, durationKey) then
		Bars.ClearChargeDurationCountdown(barFrame)
		return false
	end

	local fontString = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString() or nil
	if fontString then
		applyFontStringStyle(fontString, fontPath, fontSize, fontStyle, fontColor, defaultFontPath, defaultFontSize, defaultFontStyle)
		local resolvedAnchor = Bars.GetResolvedTextAnchor(anchor, orientation, "VALUE")
		local point, relativePoint, justifyH = Bars.GetTextAnchorConfig(anchor, orientation, "VALUE")
		local insetX = pixelSnap(offsetX or 0, barFrame and barFrame.textOverlay or barFrame)
		local insetY = pixelSnap(offsetY or 0, barFrame and barFrame.textOverlay or barFrame)
		local justifyV = "MIDDLE"
		local textInset = 4

		fontString:ClearAllPoints()
		if fontString.SetWordWrap then fontString:SetWordWrap(false) end
		if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(false) end
		if fontString.SetMaxLines then fontString:SetMaxLines(1) end
		fontString:SetWidth(0)
		if resolvedAnchor == Bars.TEXT_ANCHOR.LEFT then
			fontString:SetPoint("LEFT", cooldown, "LEFT", textInset + insetX, insetY)
		elseif resolvedAnchor == Bars.TEXT_ANCHOR.RIGHT then
			fontString:SetPoint("RIGHT", cooldown, "RIGHT", -textInset + insetX, insetY)
		elseif resolvedAnchor == Bars.TEXT_ANCHOR.TOP then
			justifyV = "TOP"
			fontString:SetPoint(point, cooldown, relativePoint, insetX, insetY - textInset)
		elseif resolvedAnchor == Bars.TEXT_ANCHOR.BOTTOM then
			justifyV = "BOTTOM"
			fontString:SetPoint(point, cooldown, relativePoint, insetX, insetY + textInset)
		else
			fontString:SetPoint(point, cooldown, relativePoint, insetX, insetY)
		end
		fontString:SetJustifyH(justifyH)
		if fontString.SetJustifyV then fontString:SetJustifyV(justifyV) end
		fontString:Show()
	end
	cooldown:Show()
	return true
end

local function ensureModeButton(icon)
	if icon._eqolBarsModeButton then return icon._eqolBarsModeButton end
	local parent = icon.layoutHandle or icon.slotAnchor or icon
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(24, 12)
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	button:SetBackdropColor(0, 0, 0, 0.80)
	button:SetBackdropBorderColor(0.95, 0.82, 0.25, 0.95)
	button:SetFrameStrata(parent:GetFrameStrata() or icon:GetFrameStrata())
	button:SetFrameLevel((parent:GetFrameLevel() or icon:GetFrameLevel()) + 50)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.text:SetPoint("CENTER")
	button.text:SetTextColor(1, 0.90, 0.30, 1)
	button:Hide()
	icon._eqolBarsModeButton = button
	return button
end

local function hideBarPresentation(icon)
	local barFrame = icon and icon._eqolBarsFrame or nil
	if barFrame then
		local runtime = getRuntimeState()
		local move = runtime and runtime.barFreeMove or nil
		if move and move.barFrame == barFrame then Bars.StopFreeMove(false) end
		stopBarAnimation(barFrame)
		barFrame._eqolBarState = nil
		Bars.ClearBarValueTextUpdater(barFrame)
		Bars.ClearChargeDurationCountdown(barFrame)
		Bars.ClearChargeGateCooldown(barFrame)
		hideBarHitHandle(barFrame)
		barFrame:Hide()
	end
	if not icon then return end
	icon._eqolBarsReservedOwnerId = nil
	icon._eqolBarsReservedSlot = nil
end

local function hideEditorBarDragPreview(editor)
	if not (editor and editor.dragIcon) then return end
	local dragIcon = editor.dragIcon
	local previewFrame = dragIcon._eqolBarsFrame
	if previewFrame then
		local runtime = getRuntimeState()
		local move = runtime and runtime.barFreeMove or nil
		if move and move.barFrame == previewFrame then Bars.StopFreeMove(false) end
		stopBarAnimation(previewFrame)
		previewFrame._eqolBarState = nil
		Bars.ClearBarValueTextUpdater(previewFrame)
		Bars.ClearChargeDurationCountdown(previewFrame)
		Bars.ClearChargeGateCooldown(previewFrame)
		previewFrame:Hide()
	end
	if dragIcon.texture then
		dragIcon.texture:SetAlpha(1)
		dragIcon.texture:Show()
	end
	if editor._eqolBarsDragSourceFrame then editor._eqolBarsDragSourceFrame:SetAlpha(editor._eqolBarsDragSourceAlpha or 1) end
	if editor._eqolBarsDragIconWidth and editor._eqolBarsDragIconHeight then dragIcon:SetSize(editor._eqolBarsDragIconWidth, editor._eqolBarsDragIconHeight) end
	editor._eqolBarsDragSourceFrame = nil
	editor._eqolBarsDragSourceAlpha = nil
	editor._eqolBarsDragIconWidth = nil
	editor._eqolBarsDragIconHeight = nil
	dragIcon._eqolBaseSlotSize = nil
end

Bars.ClearBarValueTextUpdater = function(barFrame, preserveDurationBinding)
	if not barFrame then return end
	barFrame._eqolValueTextDynamic = nil
	barFrame._eqolValueTextElapsed = nil
	if preserveDurationBinding ~= true and addon.functions and addon.functions.ReleaseDurationTextBinding then addon.functions.ReleaseDurationTextBinding(barFrame, "valueDuration", true) end
	if barFrame:GetScript("OnUpdate") then barFrame:SetScript("OnUpdate", nil) end
end

function Bars.OnBarValueTextUpdate(self, elapsed)
	if not (self and self._eqolValueTextDynamic and self._eqolBarState and self.value) then return end
	self._eqolValueTextElapsed = (self._eqolValueTextElapsed or 0) + (elapsed or 0)
	if self._eqolValueTextElapsed < 0.05 then return end
	self._eqolValueTextElapsed = 0
	local text = Bars.GetLiveBarValueText(self._eqolBarState)
	if hasTextValue(text) then
		self.value:SetText(text)
		self.value:SetWidth(0)
		local stringWidth = safeNumber(self.value.GetStringWidth and self.value:GetStringWidth() or nil)
		if stringWidth and stringWidth > 0 then
			self.value:SetWidth(pixelSnap(max(1, stringWidth + 2), self.value.GetParent and self.value:GetParent() or nil))
		end
		if self.value.Show and self.value.IsShown and not self.value:IsShown() then self.value:Show() end
	else
		self.value:SetText("")
		self.value:SetWidth(0)
	end
end

Bars.ConfigureBarValueTextUpdater = function(barFrame, state)
	if not barFrame then return end
	local useDynamicText = state and state.preview ~= true and state.showValueText == true
		and (
			(state.mode == Bars.BAR_MODE.COOLDOWN and state.cooldownVisibilityActive == true and state.chargeDurationTextNative ~= true)
			or (
				state.mode == Bars.BAR_MODE.CHARGES
				and state.showChargeDuration == true
				and state.chargeDurationTextActive == true
				and state.chargeDurationTextNative ~= true
			)
		)
	if useDynamicText ~= true then
		local preserveDurationBinding = state
			and state.showValueText == true
			and state.valueTextIsChargeDuration == true
			and state.chargeDurationTextNative == true
			and state.chargeDurationTextObject ~= nil
		Bars.ClearBarValueTextUpdater(barFrame, preserveDurationBinding == true)
		return
	end

	barFrame._eqolValueTextDynamic = true
	barFrame._eqolValueTextElapsed = 0
	local initialText = Bars.GetLiveBarValueText(state)
	if barFrame.value then
		if hasTextValue(initialText) then
			barFrame.value:SetText(initialText)
			barFrame.value:SetWidth(0)
			local stringWidth = safeNumber(barFrame.value.GetStringWidth and barFrame.value:GetStringWidth() or nil)
			if stringWidth and stringWidth > 0 then
				barFrame.value:SetWidth(pixelSnap(max(1, stringWidth + 2), barFrame.value.GetParent and barFrame.value:GetParent() or nil))
			end
			barFrame.value:Show()
		else
			barFrame.value:SetText("")
			barFrame.value:SetWidth(0)
		end
	end
	barFrame:SetScript("OnUpdate", Bars.OnBarValueTextUpdate)
end

local function showEditorBarDragPreview(panelId, panel, entryId, entry, sourceIcon)
	if not (entry and sourceIcon and panel) then return end
	local editor = getEditor and getEditor() or nil
	if not (editor and editor.dragIcon) then return end
	local state = buildBarState(panelId, entryId, entry, sourceIcon, true) or buildBarState(panelId, entryId, entry, sourceIcon, false)
	if not state then return end
	local dragIcon = editor.dragIcon
	if not editor._eqolBarsDragIconWidth or not editor._eqolBarsDragIconHeight then
		editor._eqolBarsDragIconWidth, editor._eqolBarsDragIconHeight = dragIcon:GetSize()
	end
	dragIcon._eqolBaseSlotSize = safeNumber(sourceIcon._eqolBaseSlotSize) or (sourceIcon.GetWidth and sourceIcon:GetWidth()) or 36
	local previewFrame = ensureBarFrame(dragIcon)
	layoutBarFrame(previewFrame, dragIcon, getEffectiveBarSpan(panel, entryId), panel.layout, state)
	stopBarAnimation(previewFrame)
	if dragIcon.texture then
		dragIcon.texture:SetAlpha(0)
		dragIcon.texture:Hide()
	end
	local previewWidth, previewHeight = previewFrame:GetSize()
	if previewWidth and previewHeight then dragIcon:SetSize(previewWidth, previewHeight) end
	if sourceIcon._eqolBarsFrame then
		editor._eqolBarsDragSourceFrame = sourceIcon._eqolBarsFrame
		editor._eqolBarsDragSourceAlpha = sourceIcon._eqolBarsFrame:GetAlpha()
		sourceIcon._eqolBarsFrame:SetAlpha(0.35)
	end
end

local function configureBarDragPreview(panelId, panel, icon, actualEntryId, slotColumn, slotRow, cache)
	local handle = icon and icon.layoutHandle or nil
	if not (handle and panel and actualEntryId) then return end
	if not (Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout)) then return end
	if not isAnchorCell(panel, actualEntryId, slotColumn, slotRow, cache) then return end
	local entry = panel.entries and panel.entries[actualEntryId] or nil
	if not entry or normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) ~= Bars.DISPLAY_MODE.BAR then return end
	local originalStart = handle:GetScript("OnDragStart")
	local originalStop = handle:GetScript("OnDragStop")
	if originalStart then handle:SetScript("OnDragStart", function(self, ...)
		originalStart(self, ...)
		showEditorBarDragPreview(panelId, panel, actualEntryId, entry, icon)
	end) end
	if originalStop then
		handle:SetScript("OnDragStop", function(self, ...)
			hideEditorBarDragPreview(getEditor and getEditor() or nil)
			originalStop(self, ...)
			hideEditorBarDragPreview(getEditor and getEditor() or nil)
		end)
	end
end

Bars.ClearAssistedHighlightPresentation = Bars.ClearAssistedHighlightPresentation
	or function(icon)
		if not icon then return end
		icon._eqolAssistedHighlightShown = nil
		local highlight = icon._eqolAssistedHighlight
		if not highlight then return end
		if highlight.SetAlpha then highlight:SetAlpha(0) end
		if highlight.Anim and highlight.Anim.IsPlaying and highlight.Anim:IsPlaying() then highlight.Anim:Stop() end
	end

Bars.ClearSuppressedIconPresentation = Bars.ClearSuppressedIconPresentation
	or function(icon)
		if not icon then return end
		if icon.border then icon.border:Hide() end
		if icon.blizzardIconOverlay then icon.blizzardIconOverlay:Hide() end
		if icon.rangeOverlay then icon.rangeOverlay:Hide() end
		if icon.previewBling then icon.previewBling:Hide() end
		if icon.previewSoundBorder then icon.previewSoundBorder:Hide() end
		if icon.previewGlowBorder then icon.previewGlowBorder:Hide() end
		if icon.editorGhostTexture then icon.editorGhostTexture:Hide() end
		Bars.ClearAssistedHighlightPresentation(icon)
	end

Bars.SuppressNativeIconOverlay = Bars.SuppressNativeIconOverlay
	or function(icon)
		if not icon then return end
		if icon.overlay then icon.overlay:Hide() end
		if icon.blizzardIconOverlay then icon.blizzardIconOverlay:Hide() end
	end

Bars.RestoreNativeIconOverlay = Bars.RestoreNativeIconOverlay
	or function(icon)
		if icon and icon.overlay then icon.overlay:Show() end
	end

local function applyReservedGhost(icon, ownerEntry, slotColumn, slotRow)
	if not icon then return end
	if icon.texture then
		icon.texture:SetShown(false)
		icon.texture:SetAlpha(0)
	end
	if icon.cooldown then icon.cooldown:Hide() end
	Bars.GuardCooldownVisuals(icon.cooldown)
	if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then icon.cooldown:SetHideCountdownNumbers(true) end
	if icon.count then
		if icon.count.SetText then icon.count:SetText("") end
		icon.count:Hide()
	end
	if icon.charges then
		if icon.charges.SetText then icon.charges:SetText("") end
		icon.charges:Hide()
	end
	if icon.keybind then icon.keybind:Hide() end
	if icon.stateTexture then icon.stateTexture:Hide() end
	if icon.stateTextureSecond then icon.stateTextureSecond:Hide() end
	Bars.ClearSuppressedIconPresentation(icon)
	Bars.SuppressNativeIconOverlay(icon)
	if icon.staticText then
		icon.staticText:SetText("")
		icon.staticText:Hide()
	end
	icon._eqolBarsReservedSlot = true
	icon._eqolPreviewCellColumn = slotColumn
	icon._eqolPreviewCellRow = slotRow
end

local function applyNativeSuppression(icon)
	if not icon then return end
	if icon.texture then
		icon.texture:SetShown(false)
		icon.texture:SetAlpha(0)
	end
	if icon.cooldown then
		Bars.GuardCooldownVisuals(icon.cooldown)
		if icon.cooldown.SetHideCountdownNumbers then icon.cooldown:SetHideCountdownNumbers(true) end
		if icon.cooldown.SetAlpha then icon.cooldown:SetAlpha(0) end
		if icon.cooldown.Show then icon.cooldown:Show() end
	end
	if icon.count then icon.count:Hide() end
	if icon.charges then icon.charges:Hide() end
	if icon.keybind then icon.keybind:Hide() end
	if icon.stateTexture then icon.stateTexture:Hide() end
	if icon.stateTextureSecond then icon.stateTextureSecond:Hide() end
	if icon.staticText then icon.staticText:Hide() end
	CooldownPanels.HidePreviewGlowBorder(icon)
	CooldownPanels.StopAllIconGlows(icon)
	Bars.ClearSuppressedIconPresentation(icon)
	Bars.SuppressNativeIconOverlay(icon)
end

local function getStackSessionMax(entryKey, observedValue, preview)
	local runtime = getRuntimeState()
	local maxByKey = runtime.stackMaxByEntryKey or {}
	runtime.stackMaxByEntryKey = maxByKey
	local currentMax = maxByKey[entryKey]
	local observed = safeNumber(observedValue)
	if observed then
		local baseline = preview and 5 or 3
		currentMax = max(currentMax or baseline, observed)
		maxByKey[entryKey] = currentMax
	end
	return currentMax or (preview and 5 or 3)
end

local function getResolvedSpellId(entry, macro)
	local spellId = tonumber((macro and macro.spellID) or entry.spellID)
	if not spellId then return nil end
	-- Match CooldownPanels runtime behavior: spell cooldown/charge APIs should use
	-- the effective override spell, not the known-variant remap table.
	if Api.GetOverrideSpell then
		local overrideId = Api.GetOverrideSpell(spellId)
		if type(overrideId) == "number" and overrideId > 0 then return overrideId end
	end
	return spellId
end

local function getResolvedItemId(entry, macro)
	local itemId = tonumber((macro and macro.itemID) or entry.itemID)
	if not itemId then return nil end
	if CooldownPanels.ResolveEntryItemID then itemId = CooldownPanels.ResolveEntryItemID(entry, itemId) end
	return itemId
end

local function getCooldownProgress(startTime, duration, rate)
	local start = safeNumber(startTime)
	local total = safeNumber(duration)
	if not (start and total and total > 0) then return nil end
	local now = (Api.GetTime and Api.GetTime()) or GetTime()
	local modifier = safeNumber(rate) or 1
	return clamp(((now - start) * modifier) / total, 0, 1)
end

Bars.IsSpellCooldownActiveForBars = Bars.IsSpellCooldownActiveForBars or function(cooldownIsActive, cooldownEnabled, startTime, duration)
	if CooldownPanels.IsSpellCooldownInfoActive then return CooldownPanels.IsSpellCooldownInfoActive(cooldownIsActive, cooldownEnabled, startTime, duration) end
	if cooldownEnabled == false or cooldownEnabled == 0 then return false end
	local start = safeNumber(startTime)
	local total = safeNumber(duration)
	if not (start and total and start > 0 and total > 0) then return false end
	local now = (Api.GetTime and Api.GetTime()) or GetTime()
	return (start + total) > now
end

local function getDurationObjectRemaining(durationObject)
	if not (durationObject and durationObject.GetRemainingDuration) then return nil end
	return safeNumber(durationObject.GetRemainingDuration(durationObject, Api.DurationModifierRealTime))
end

local function getDurationObjectTotal(durationObject)
	if not (durationObject and durationObject.GetTotalDuration) then return nil end
	return safeNumber(durationObject.GetTotalDuration(durationObject, Api.DurationModifierRealTime))
end

local function getDurationObjectElapsedProgress(durationObject)
	local remaining = getDurationObjectRemaining(durationObject)
	local total = getDurationObjectTotal(durationObject)
	if not (remaining and total and total > 0) then return nil end
	return clamp(1 - (remaining / total), 0, 1)
end

setBooleanAlpha = function(target, condition, onAlpha, offAlpha)
	if not target then return end
	if target.SetAlphaFromBoolean then
		target:SetAlphaFromBoolean(condition, onAlpha, offAlpha)
	elseif target.SetAlpha then
		if isSecretValue(condition) then
			target:SetAlpha(offAlpha or 0)
		else
			target:SetAlpha(condition and (onAlpha or 1) or (offAlpha or 0))
		end
	end
end

shouldShowChargeSegmentFill = function(state, index)
	if type(index) ~= "number" or index <= 1 then return true end
	if type(state) ~= "table" then return true end
	if state.lastNonGCDCooldownActive ~= true then return true end
	local cooldownDurationObject = state.lastNonGCDCooldownDurationObject
	if not cooldownDurationObject then return false end
	if cooldownDurationObject.IsZero then return cooldownDurationObject:IsZero() end
	local remaining = getDurationObjectRemaining(cooldownDurationObject)
	if remaining == nil then return false end
	return remaining <= 0
end

sweepChargeDurationObjects = function(state)
	if type(state) ~= "table" then return end
	local chargeRemaining = getDurationObjectRemaining(state.chargeDurationObject)
	if chargeRemaining ~= nil and chargeRemaining <= 0 then state.chargeDurationObject = nil end
	local cooldownRemaining = getDurationObjectRemaining(state.cooldownDurationObject)
	if cooldownRemaining ~= nil and cooldownRemaining <= 0 then state.cooldownDurationObject = nil end
end

setStatusBarImmediateValue = function(statusBar, value)
	if not statusBar then return end
	if statusBar.SetMinMaxValues then statusBar:SetMinMaxValues(0, 1, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE) end
	if statusBar.SetValue then statusBar:SetValue(clamp(value or 0, 0, 1), cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE) end
	if statusBar.SetToTargetValue then statusBar:SetToTargetValue() end
	statusBar._eqolTimerDurationObject = nil
	statusBar._eqolTimerDurationKey = nil
	statusBar._eqolTimerDirection = nil
end

Bars.SetStatusBarRangedValue = function(statusBar, value, maxValue)
	if not statusBar then return end
	local resolvedMax = safeNumber(maxValue) or 1
	if resolvedMax < 1 then
		resolvedMax = 1
	elseif resolvedMax > 3.402823e+38 then
		resolvedMax = 3.402823e+38
	end

	if value == nil then value = 0 end
	if statusBar.SetMinMaxValues then statusBar:SetMinMaxValues(0, resolvedMax, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE) end
	if statusBar.SetValue then statusBar:SetValue(value or 0, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE) end
	if statusBar.SetToTargetValue then statusBar:SetToTargetValue() end
	statusBar._eqolTimerDurationObject = nil
	statusBar._eqolTimerDurationKey = nil
	statusBar._eqolTimerDirection = nil
end

setStatusBarTimerDuration = function(statusBar, durationObject, cacheKey, direction)
	if not (statusBar and durationObject and statusBar.SetTimerDuration) then return false end
	local appliedKey = cacheKey or durationObject
	local appliedDirection = direction or cdp.BAR_STATUS_TIMER_DIRECTION_ELAPSED
	if statusBar._eqolTimerDurationKey ~= appliedKey or statusBar._eqolTimerDirection ~= appliedDirection or statusBar._eqolTimerDurationObject ~= durationObject then
		if statusBar.SetMinMaxValues then statusBar:SetMinMaxValues(0, 1, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE) end
		statusBar:SetTimerDuration(durationObject, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE, appliedDirection)
		statusBar._eqolTimerDurationObject = durationObject
		statusBar._eqolTimerDurationKey = appliedKey
		statusBar._eqolTimerDirection = appliedDirection
	end
	return true
end

inferChargeBaseCount = function(state, maxCharges)
	if type(state) ~= "table" then return nil end
	local numericMax = safeNumber(maxCharges)
	if not (numericMax and numericMax > 0) then return nil end
	if state.cooldownDurationObject ~= nil and state.cooldownGCD ~= true then return 0 end
	if state.chargeDurationObject ~= nil then return max(numericMax - 1, 0) end
	return numericMax
end

getDisplayedCharges = function(icon) return safeNumber(icon and icon.charges and icon.charges.GetText and icon.charges:GetText()) end

local function getChargeSessionMax(entryKey, observedMax, observedCurrent, hasRecharge, preview)
	local runtime = getRuntimeState()
	local maxByKey = runtime.chargeMaxByEntryKey or {}
	runtime.chargeMaxByEntryKey = maxByKey
	local currentMax = maxByKey[entryKey]
	local safeObservedMax = safeNumber(observedMax)
	if safeObservedMax and safeObservedMax > 0 then
		if entryKey ~= nil then
			if currentMax ~= nil and currentMax ~= safeObservedMax then
				if runtime.chargePhaseByEntryKey then runtime.chargePhaseByEntryKey[entryKey] = nil end
				if runtime.chargeEmptyDurationObjectByEntryKey then runtime.chargeEmptyDurationObjectByEntryKey[entryKey] = nil end
				if runtime.pendingChargeTimerHandoffByEntryKey then runtime.pendingChargeTimerHandoffByEntryKey[entryKey] = nil end
				if runtime.pendingChargeTimerHandoffRefreshByEntryKey then runtime.pendingChargeTimerHandoffRefreshByEntryKey[entryKey] = nil end
				if runtime.chargeLastNonGCDCooldownActiveByEntryKey then runtime.chargeLastNonGCDCooldownActiveByEntryKey[entryKey] = nil end
				if runtime.chargeLastNonGCDCooldownDurationByEntryKey then runtime.chargeLastNonGCDCooldownDurationByEntryKey[entryKey] = nil end
			end
			maxByKey[entryKey] = safeObservedMax
		end
		return safeObservedMax
	end
	local safeObservedCurrent = safeNumber(observedCurrent)
	if currentMax and currentMax > 0 then return currentMax end
	local fallback = preview and 3 or 1
	if hasRecharge then
		fallback = max(fallback, 2)
		if safeObservedCurrent then fallback = max(fallback, safeObservedCurrent + 1) end
	end
	if safeObservedCurrent then fallback = max(fallback, safeObservedCurrent) end
	return fallback
end

local function getChargeCooldownCache(entryKey)
	local runtime = getRuntimeState()
	local activeByKey = runtime.chargeLastNonGCDCooldownActiveByEntryKey or {}
	local durationByKey = runtime.chargeLastNonGCDCooldownDurationByEntryKey or {}
	runtime.chargeLastNonGCDCooldownActiveByEntryKey = activeByKey
	runtime.chargeLastNonGCDCooldownDurationByEntryKey = durationByKey
	if not entryKey then return activeByKey, durationByKey, false, nil end
	return activeByKey, durationByKey, activeByKey[entryKey] == true, durationByKey[entryKey]
end

Bars._eqolRuntimeReuseUtil = Bars._eqolRuntimeReuseUtil or {}

function Bars._eqolRuntimeReuseUtil.GetBarRuntimeData(icon, runtimeDataOverride, resolvedType, preview)
	if preview == true then return nil end
	local runtimeData = type(runtimeDataOverride) == "table" and runtimeDataOverride or (icon and type(icon._eqolRuntimeData) == "table" and icon._eqolRuntimeData or nil)
	if type(runtimeData) ~= "table" then return nil end
	if resolvedType and runtimeData.resolvedType and runtimeData.resolvedType ~= resolvedType then return nil end
	return runtimeData
end

function Bars._eqolRuntimeReuseUtil.HasCooldownRuntimeData(runtimeData, ignoreGCD)
	if type(runtimeData) ~= "table" then return false end
	if ignoreGCD == true and runtimeData.cooldownIgnoreGCD ~= true then return false end
	return runtimeData.cooldownEnabled ~= nil
		or runtimeData.cooldownIsActive ~= nil
		or runtimeData.cooldownDurationObject ~= nil
		or runtimeData.cooldownGCD == true
		or (safeNumber(runtimeData.cooldownDuration) or 0) > 0
end

function Bars._eqolRuntimeReuseUtil.HasChargeRuntimeData(runtimeData)
	if type(runtimeData) ~= "table" then return false end
	return type(runtimeData.chargesInfo) == "table" or runtimeData.chargeDurationObject ~= nil or Bars._eqolRuntimeReuseUtil.HasCooldownRuntimeData(runtimeData)
end

refreshChargeBarRuntimeState = function(state, icon, runtimeData)
	if type(state) ~= "table" then return state end
	local spellId = safeNumber(state.spellId)
	if not spellId then return state end
	local runtimeReuseUtil = Bars._eqolRuntimeReuseUtil
	local reusableRuntimeData = runtimeReuseUtil.HasChargeRuntimeData(runtimeData) and runtimeData or nil
	local reusableRawCooldownRuntimeData = runtimeReuseUtil.HasCooldownRuntimeData(reusableRuntimeData)
			and reusableRuntimeData.cooldownIgnoreGCD ~= true
			and reusableRuntimeData
		or nil
	local reusableNonGCDCooldownRuntimeData = runtimeReuseUtil.HasCooldownRuntimeData(reusableRuntimeData, true) and reusableRuntimeData or nil

	local chargesInfo = reusableRuntimeData and reusableRuntimeData.chargesInfo or (CooldownPanels.GetCachedSpellChargesInfo and CooldownPanels:GetCachedSpellChargesInfo(spellId) or nil)
	local chargeDurationObject = reusableRuntimeData and reusableRuntimeData.chargeDurationObject
		or (CooldownPanels.GetCachedSpellChargeDurationObject and CooldownPanels:GetCachedSpellChargeDurationObject(spellId) or nil)
	local rawCooldownDurationObject = reusableNonGCDCooldownRuntimeData and reusableNonGCDCooldownRuntimeData.cooldownDurationObject
		or (CooldownPanels.GetCachedSpellCooldownDurationObject and CooldownPanels:GetCachedSpellCooldownDurationObject(spellId, true) or nil)
	local cooldownDurationObject = rawCooldownDurationObject
	local cooldownRemaining = getDurationObjectRemaining(cooldownDurationObject)

	local cooldownStart, cooldownDuration, cooldownEnabled, cooldownRate, cooldownGCD, cooldownIsActive = 0, 0, false, 1, nil, false
	if reusableRawCooldownRuntimeData then
		cooldownStart = reusableRawCooldownRuntimeData.cooldownStart
		cooldownDuration = reusableRawCooldownRuntimeData.cooldownDuration
		cooldownEnabled = reusableRawCooldownRuntimeData.cooldownEnabled
		cooldownRate = reusableRawCooldownRuntimeData.cooldownRate
		cooldownGCD = reusableRawCooldownRuntimeData.cooldownGCD
		cooldownIsActive = reusableRawCooldownRuntimeData.cooldownIsActive
	elseif CooldownPanels.GetCachedSpellCooldownInfo then
		cooldownStart, cooldownDuration, cooldownEnabled, cooldownRate, cooldownGCD, cooldownIsActive =
			CooldownPanels:GetCachedSpellCooldownInfo(spellId, false)
	end
	local chargeApiIsActive = nil
	if type(chargesInfo) == "table" and not (Api.issecretvalue and Api.issecretvalue(chargesInfo.isActive)) and type(chargesInfo.isActive) == "boolean" then
		chargeApiIsActive = chargesInfo.isActive
	end
	local cooldownApiIsActive = Bars.IsSpellCooldownActiveForBars(cooldownIsActive, cooldownEnabled, cooldownStart, cooldownDuration)
	local chargeInfoActive = chargeApiIsActive == true

	local displayedCharges = chargesInfo and safeNumber(chargesInfo.currentCharges) or getDisplayedCharges(icon)
	if displayedCharges ~= nil then state.currentCharges = displayedCharges end
	if type(chargesInfo) == "table" then
		state.rawCurrentCharges = chargesInfo.currentCharges
		state.rawMaxCharges = chargesInfo.maxCharges
	else
		state.rawCurrentCharges = nil
		state.rawMaxCharges = nil
	end

	local runtime = getRuntimeState()
	local phaseByKey = runtime.chargePhaseByEntryKey or {}
	local chargeEmptyDurationObjectByEntryKey = runtime.chargeEmptyDurationObjectByEntryKey or {}
	local pendingChargeTimerHandoffByEntryKey = runtime.pendingChargeTimerHandoffByEntryKey or {}
	runtime.chargePhaseByEntryKey = phaseByKey
	runtime.chargeEmptyDurationObjectByEntryKey = chargeEmptyDurationObjectByEntryKey
	runtime.pendingChargeTimerHandoffByEntryKey = pendingChargeTimerHandoffByEntryKey
	local entryKey = state.entryKey
	local activeByKey, durationByKey, cachedCooldownActive, cachedCooldownDurationObject = getChargeCooldownCache(entryKey)
	state.previousChargePhase = entryKey and phaseByKey[entryKey] or nil
	local cachedCooldownActiveBefore = cachedCooldownActive == true
	local cachedCooldownDurationBefore = cachedCooldownDurationObject ~= nil
	local nonGCDCooldownActive = cooldownApiIsActive == true and cooldownGCD ~= true
	local gcdCooldownActive = cooldownApiIsActive == true and cooldownGCD == true
	if entryKey and cooldownGCD ~= true then
		cachedCooldownActive = nonGCDCooldownActive == true
		cachedCooldownDurationObject = cachedCooldownActive and cooldownDurationObject or nil
		activeByKey[entryKey] = cachedCooldownActive
		durationByKey[entryKey] = cachedCooldownDurationObject
	end

	local rechargeActive = chargeApiIsActive == true
	local chargeTimerActive = chargeApiIsActive == true
	local lastChargeDepleted = cachedCooldownActive == true
	local maxCharges = chargesInfo and safeNumber(chargesInfo.maxCharges) or safeNumber(state.maxCharges)
	local hasRecharge = rechargeActive == true or lastChargeDepleted == true
	maxCharges = getChargeSessionMax(entryKey, maxCharges, displayedCharges, hasRecharge, false)
	local chargePhase = nil
	local chargeDurationObjectRefreshed = false
	local renderChargePhase = nil
	local freezeChargeRender = false
	if maxCharges == 2 then
		local chargePhaseIsEmpty = cooldownApiIsActive == true and cooldownGCD ~= true
		local chargePhaseIsPartial = chargeApiIsActive == true
		local chargePhaseIsFull = chargeApiIsActive == false
		if chargePhaseIsEmpty then
			chargePhase = "EMPTY"
		elseif chargePhaseIsPartial then
			chargePhase = "PARTIAL"
		elseif chargePhaseIsFull then
			chargePhase = "FULL"
		end
		if chargePhase == nil then
			freezeChargeRender = true
			chargePhase = state.previousChargePhase
			renderChargePhase = state.previousChargePhase
		else
			rechargeActive = chargePhase == "PARTIAL" and chargeApiIsActive == true
			lastChargeDepleted = chargePhase == "EMPTY"
			if lastChargeDepleted == true then
				cachedCooldownActive = true
				cachedCooldownDurationObject = cooldownDurationObject
			elseif chargePhase == "PARTIAL" then
				cachedCooldownActive = false
				cachedCooldownDurationObject = nil
			elseif chargePhase == "FULL" then
				cachedCooldownActive = false
				cachedCooldownDurationObject = nil
			end
			if entryKey then
				activeByKey[entryKey] = cachedCooldownActive
				durationByKey[entryKey] = cachedCooldownDurationObject
				phaseByKey[entryKey] = chargePhase
			end
		end
	end
	chargeInfoActive = rechargeActive == true
	renderChargePhase = renderChargePhase or chargePhase
	local deferChargeTimerHandoff = false
	local pendingChargeTimerHandoff = entryKey and pendingChargeTimerHandoffByEntryKey[entryKey] == true or false
	if entryKey and freezeChargeRender ~= true then
		local previousEmptyDurationObject = chargeEmptyDurationObjectByEntryKey[entryKey]
		if chargePhase == "EMPTY" and cooldownDurationObject ~= nil then
			chargeEmptyDurationObjectByEntryKey[entryKey] = cooldownDurationObject
		elseif chargePhase == "PARTIAL" and chargeInfoActive == true then
			if previousEmptyDurationObject ~= nil and previousEmptyDurationObject == chargeDurationObject then
				renderChargePhase = "EMPTY"
			else
				chargeEmptyDurationObjectByEntryKey[entryKey] = nil
			end
		else
			chargeEmptyDurationObjectByEntryKey[entryKey] = nil
		end
		if chargePhase == "PARTIAL" and chargeInfoActive == true then
			if state.previousChargePhase == "EMPTY" then
				pendingChargeTimerHandoffByEntryKey[entryKey] = true
				deferChargeTimerHandoff = true
			elseif pendingChargeTimerHandoff == true then
				pendingChargeTimerHandoffByEntryKey[entryKey] = nil
			end
		else
			pendingChargeTimerHandoffByEntryKey[entryKey] = nil
		end
	end
	if freezeChargeRender ~= true and chargeTimerActive == true and state.previousChargePhase == "EMPTY" and chargePhase == "PARTIAL" and C_Spell and C_Spell.GetSpellChargeDuration then
		local freshChargeDurationObject = C_Spell.GetSpellChargeDuration(spellId)
		if freshChargeDurationObject ~= nil then
			chargeDurationObject = freshChargeDurationObject
			chargeDurationObjectRefreshed = true
		end
	end

	local rechargeStart = chargesInfo and safeNumber(chargesInfo.cooldownStartTime) or nil
	local rechargeDuration = chargesInfo and safeNumber(chargesInfo.cooldownDuration) or nil
	local rechargeRate = chargesInfo and (safeNumber(chargesInfo.chargeModRate) or 1) or 1
	if chargeTimerActive ~= true then
		chargeDurationObject = nil
		rechargeStart = nil
		rechargeDuration = nil
	end
	local rechargeProgress = getDurationObjectElapsedProgress(chargeDurationObject)
	if rechargeProgress == nil and cachedCooldownActive ~= true and cooldownGCD ~= true then rechargeProgress = getDurationObjectElapsedProgress(cooldownDurationObject) end
	if rechargeProgress == nil and displayedCharges and maxCharges and rechargeStart and rechargeDuration and rechargeDuration > 0 and isSafeLessThan(displayedCharges, maxCharges) then
		local now = (Api.GetTime and Api.GetTime()) or GetTime()
		rechargeProgress = clamp((now - rechargeStart) * rechargeRate / rechargeDuration, 0, 1)
	end

	state.chargesInfo = chargesInfo
	state.chargeInfoActive = rechargeActive == true
	state.maxCharges = maxCharges
	state.chargeDurationObject = chargeTimerActive == true and chargeDurationObject or nil
	state.rawCooldownDurationObject = rawCooldownDurationObject
	state.cooldownDurationObject = lastChargeDepleted == true and cachedCooldownDurationObject or nil
	state.cooldownRemaining = cooldownRemaining
	state.cooldownEnabled = cooldownEnabled
	state.cooldownGCD = cooldownGCD == true
	state.cooldownIsActive = cooldownApiIsActive == true
	state.cooldownInfoActive = cachedCooldownActive == true
	state.lastNonGCDCooldownActive = cachedCooldownActive == true
	state.lastNonGCDCooldownDurationObject = cachedCooldownDurationObject
	state.chargeDurationObjectRefreshed = chargeDurationObjectRefreshed == true
	state.deferChargeTimerHandoff = deferChargeTimerHandoff == true
	state.freezeChargeRender = freezeChargeRender == true
	state.chargePhase = chargePhase
	state.renderChargePhase = renderChargePhase
	state.cooldownStart = safeNumber(cooldownStart)
	state.cooldownDuration = safeNumber(cooldownDuration)
	state.cooldownRate = safeNumber(cooldownRate) or 1
	state.rechargeStart = rechargeStart
	state.rechargeDuration = rechargeDuration
	state.rechargeRate = rechargeRate
	state.rechargeProgress = rechargeProgress or 0
	state.animate = state.chargeInfoActive == true or state.lastNonGCDCooldownActive == true or ((rechargeStart and rechargeDuration and rechargeDuration > 0) and true or false)
	return state
end

getChargeBarProgress = function(state)
	if type(state) ~= "table" then return 0 end
	sweepChargeDurationObjects(state)
	local maxCharges = safeNumber(state.maxCharges)
	local renderPhase = state.renderChargePhase or state.chargePhase
	if maxCharges == 2 and type(renderPhase) == "string" then
		local phase = renderPhase
		if phase == "FULL" then return 1 end
		if phase == "PARTIAL" then
			local rechargeProgress = getDurationObjectElapsedProgress(state.chargeDurationObject)
			if rechargeProgress == nil then
				local rechargeStart = safeNumber(state.rechargeStart)
				local rechargeDuration = safeNumber(state.rechargeDuration)
				if rechargeStart and rechargeDuration and rechargeDuration > 0 then
					local now = (Api.GetTime and Api.GetTime()) or GetTime()
					local rechargeRate = safeNumber(state.rechargeRate) or 1
					rechargeProgress = clamp(((now - rechargeStart) * rechargeRate) / rechargeDuration, 0, 1)
				end
			end
			return clamp((1 + clamp(rechargeProgress or 0, 0, 1)) / 2, 0, 1)
		end
		if phase == "EMPTY" then
			local cooldownProgress = getDurationObjectElapsedProgress(state.cooldownDurationObject)
			if cooldownProgress == nil then cooldownProgress = getCooldownProgress(state.cooldownStart, state.cooldownDuration, state.cooldownRate) end
			return clamp(clamp(cooldownProgress or 0, 0, 1) / 2, 0, 1)
		end
	end
	local currentCharges = safeNumber(state.currentCharges)
	local baseCharges = currentCharges
	if baseCharges == nil then baseCharges = inferChargeBaseCount(state, maxCharges) end
	local rechargeProgress = getDurationObjectElapsedProgress(state.chargeDurationObject)
	if rechargeProgress == nil and state.cooldownGCD ~= true then rechargeProgress = getDurationObjectElapsedProgress(state.cooldownDurationObject) end
	if rechargeProgress == nil then
		local rechargeStart = safeNumber(state.rechargeStart)
		local rechargeDuration = safeNumber(state.rechargeDuration)
		if rechargeStart and rechargeDuration and rechargeDuration > 0 then
			local now = (Api.GetTime and Api.GetTime()) or GetTime()
			local rechargeRate = safeNumber(state.rechargeRate) or 1
			rechargeProgress = clamp(((now - rechargeStart) * rechargeRate) / rechargeDuration, 0, 1)
		else
			rechargeProgress = clamp(safeNumber(state.rechargeProgress) or 0, 0, 1)
		end
	end
	state.rechargeProgress = rechargeProgress
	if baseCharges and maxCharges and maxCharges > 0 then
		local progress = baseCharges / maxCharges
		if rechargeProgress > 0 and baseCharges < maxCharges then progress = (baseCharges + rechargeProgress) / maxCharges end
		return clamp(progress, 0, 1)
	end
	if rechargeProgress > 0 and maxCharges and maxCharges > 0 then
		local inferredBase = inferChargeBaseCount(state, maxCharges) or 0
		return clamp((inferredBase + rechargeProgress) / maxCharges, 0, 1)
	end
	if rechargeProgress > 0 then return clamp(rechargeProgress, 0, 1) end
	if baseCharges and baseCharges > 0 then return 1 end
	return (state.chargeInfoActive == true or state.cooldownGCD == true) and 1 or 0
end

getChargeBarValueText = function(icon, currentCharges, maxCharges)
	local current = safeNumber(currentCharges)
	local maximum = safeNumber(maxCharges)
	if not (current and maximum) or maximum <= 0 then return nil end
	local roundedMaximum = floor(maximum)
	if roundedMaximum <= 0 then return nil end
	local roundedCurrent = floor(current)
	if roundedCurrent < 0 then roundedCurrent = 0 end
	if roundedCurrent > roundedMaximum then roundedCurrent = roundedMaximum end
	return format("%d/%d", roundedCurrent, roundedMaximum)
end

getChargeSegmentDescriptors = function(state, segmentCount)
	local descriptors = {}
	segmentCount = clamp(tonumber(segmentCount) or safeNumber(state and state.maxCharges) or 1, 1, 20)
	for index = 1, segmentCount do
		descriptors[index] = { value = 0, durationObject = nil }
	end
	if type(state) ~= "table" then return descriptors end

	sweepChargeDurationObjects(state)
	if segmentCount == 2 then
		local phase = state.renderChargePhase or state.chargePhase
		descriptors[1].value = 1
		descriptors[2].value = 1
		if phase == "EMPTY" then
			descriptors[1].value = 0
			descriptors[2].value = 0
			if state.cooldownDurationObject ~= nil then descriptors[1].durationObject = state.cooldownDurationObject end
		elseif phase == "PARTIAL" then
			descriptors[1].value = 1
			descriptors[2].value = 0
			if state.chargeInfoActive == true and state.chargeDurationObject ~= nil then descriptors[2].durationObject = state.chargeDurationObject end
		else
			if state.chargeInfoActive == true and state.chargeDurationObject ~= nil then descriptors[2].durationObject = state.chargeDurationObject end
		end
		return descriptors
	end

	local maxCharges = safeNumber(state.maxCharges) or segmentCount
	local currentCharges = safeNumber(state.currentCharges)
	if currentCharges == nil then currentCharges = inferChargeBaseCount(state, maxCharges) end
	currentCharges = clamp(currentCharges or 0, 0, segmentCount)

	local hasCooldownTimer = state.cooldownDurationObject ~= nil and state.cooldownGCD ~= true
	local hasChargeTimer = state.chargeDurationObject ~= nil

	for index = 1, segmentCount do
		local descriptor = descriptors[index]
		if index <= currentCharges then
			descriptor.value = 1
		elseif index == (currentCharges + 1) and currentCharges < segmentCount and hasChargeTimer then
			descriptor.durationObject = state.chargeDurationObject
		elseif index == 1 and currentCharges <= 0 and hasCooldownTimer then
			descriptor.durationObject = state.cooldownDurationObject
		else
			descriptor.value = 0
		end
	end

	return descriptors
end

Bars.GetBarStaticState = function(entry, panel, mode, resolvedType, resolvedSpellId, label, staticVersion, staticGeneration, labelGeneration)
	if not entry then return nil end
	staticVersion = staticVersion or entry._eqolBarsStaticVersion or 0
	staticGeneration = staticGeneration or 0
	labelGeneration = labelGeneration or 0
	local mediaGeneration = addon.functions and addon.functions.GetLSMMediaVersion and addon.functions.GetLSMMediaVersion() or 0
	local durationTextProfile = Bars.GetEntryDurationTextProfile(entry, panel)
	local state = entry._eqolBarsStaticState
	if
		state
		and state.version == staticVersion
		and state.staticGeneration == staticGeneration
		and state.labelGeneration == labelGeneration
		and state.mediaGeneration == mediaGeneration
		and state.mode == mode
		and state.resolvedType == resolvedType
		and state.resolvedSpellId == resolvedSpellId
		and state.label == label
		and state.durationTextProfile == durationTextProfile
	then
		return state
	end

	state = state or {}
	entry._eqolBarsStaticState = state
	state.version = staticVersion
	state.staticGeneration = staticGeneration
	state.labelGeneration = labelGeneration
	state.mediaGeneration = mediaGeneration
	state.mode = mode
	state.durationTextProfile = durationTextProfile
	state.resolvedType = resolvedType
	state.resolvedSpellId = resolvedSpellId
	state.label = label
	state.showIcon = getStoredBoolean(entry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
	state.showLabel = getStoredBoolean(entry, "barShowLabel", Bars.DEFAULTS.barShowLabel)
	state.showStackText = getStoredBoolean(entry, "barShowStackText", Bars.DEFAULTS.barShowStackText)
		and (
			mode == Bars.BAR_MODE.STACKS
			or (mode == Bars.BAR_MODE.COOLDOWN and resolvedType == "CDM_AURA" and Bars.ShouldEntryShowStacks(entry, resolvedType))
		)
	state.showStacks = Bars.ShouldEntryShowStacks(entry, resolvedType)
	state.configuredSpan = normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan)
	state.barWidth = normalizeBarWidth(entry.barWidth, Bars.DEFAULTS.barWidth)
	state.barHeight = normalizeBarHeight(entry.barHeight, Bars.DEFAULTS.barHeight)
	state.barOffsetX = normalizeBarOffset(entry.barOffsetX, Bars.DEFAULTS.barOffsetX)
	state.barOffsetY = normalizeBarOffset(entry.barOffsetY, Bars.DEFAULTS.barOffsetY)
	state.orientation = normalizeBarOrientation(entry.barOrientation, Bars.DEFAULTS.barOrientation)
	state.reverseFill = mode == Bars.BAR_MODE.COOLDOWN and getStoredBoolean(entry, "barReverseFill", Bars.DEFAULTS.barReverseFill)
	state.segmentDirection = normalizeBarSegmentDirection(entry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection)
	state.segmentReverse = getStoredBoolean(entry, "barSegmentReverse", Bars.DEFAULTS.barSegmentReverse)
	state.barTexture = resolveBarTexture(entry.barTexture)
	state.fillColor = getBarModeColor(entry, mode)
	state.backgroundColor = Bars.GetCachedEntryColor(entry, "barBackgroundColor", Bars.DEFAULTS.barBackgroundColor)
	state.borderEnabled = getStoredBoolean(entry, "barBorderEnabled", Bars.DEFAULTS.barBorderEnabled)
	state.borderColor = Bars.GetCachedEntryColor(entry, "barBorderColor", Bars.DEFAULTS.barBorderColor)
	state.procGlowColor = Bars.GetCachedEntryColor(entry, "barProcGlowColor", Bars.DEFAULTS.barProcGlowColor)
	state.borderTexture = resolveBarBorderTexture(entry.barBorderTexture)
	state.borderOffset = normalizeBarBorderOffset(entry.barBorderOffset, Bars.DEFAULTS.barBorderOffset)
	state.borderSize = normalizeBarBorderSize(entry.barBorderSize, Bars.DEFAULTS.barBorderSize)
	state.iconSize = normalizeBarIconSize(entry.barIconSize, Bars.DEFAULTS.barIconSize)
	state.iconPosition = normalizeBarIconPosition(entry.barIconPosition, Bars.DEFAULTS.barIconPosition)
	state.iconOffsetX = normalizeBarIconOffset(entry.barIconOffsetX, Bars.DEFAULTS.barIconOffsetX)
	state.iconOffsetY = normalizeBarIconOffset(entry.barIconOffsetY, Bars.DEFAULTS.barIconOffsetY)
	state.segmentedCharges = mode == Bars.BAR_MODE.CHARGES and getStoredBoolean(entry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
	state.chargesGap = normalizeBarChargesGap(entry.barChargesGap, Bars.DEFAULTS.barChargesGap)
	state.segmentedStacks = mode == Bars.BAR_MODE.STACKS and getStoredBoolean(entry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
	state.stackSeparatedOffset = normalizeBarChargesGap(entry.barStackSeparatedOffset, Bars.DEFAULTS.barStackSeparatedOffset)
	state.stackDividerColor = Bars.GetCachedEntryColor(entry, "barStackDividerColor", Bars.DEFAULTS.barStackDividerColor)
	state.stackDividerThickness = normalizeBarStackDividerThickness(entry.barStackDividerThickness, Bars.DEFAULTS.barStackDividerThickness)
	state.stackMax = Bars.NormalizeBarStackMax(entry.barStackMax, Bars.DEFAULTS.barStackMax)
	state.stackAnchor = Bars.NormalizeTextAnchor(entry.barStackAnchor, Bars.DEFAULTS.barStackAnchor)
	state.stackFont = normalizeBarFont(entry.barStackFont, Bars.DEFAULTS.barStackFont)
	state.stackOffsetX = normalizeBarOffset(entry.barStackOffsetX, Bars.DEFAULTS.barStackOffsetX)
	state.stackOffsetY = normalizeBarOffset(entry.barStackOffsetY, Bars.DEFAULTS.barStackOffsetY)
	state.stackSize = normalizeBarFontSize(entry.barStackSize, Bars.DEFAULTS.barStackSize)
	state.stackStyle = normalizeBarFontStyle(entry.barStackStyle, Bars.DEFAULTS.barStackStyle)
	state.stackColor = Bars.GetCachedEntryColor(entry, "barStackColor", Bars.DEFAULTS.barStackColor)
	state.labelAnchor = Bars.NormalizeTextAnchor(entry.barLabelAnchor, Bars.DEFAULTS.barLabelAnchor)
	state.labelFont = normalizeBarFont(entry.barLabelFont, Bars.DEFAULTS.barLabelFont)
	state.labelOffsetX = normalizeBarOffset(entry.barLabelOffsetX, Bars.DEFAULTS.barLabelOffsetX)
	state.labelOffsetY = normalizeBarOffset(entry.barLabelOffsetY, Bars.DEFAULTS.barLabelOffsetY)
	state.labelSize = normalizeBarFontSize(entry.barLabelSize, Bars.DEFAULTS.barLabelSize)
	state.labelStyle = normalizeBarFontStyle(entry.barLabelStyle, Bars.DEFAULTS.barLabelStyle)
	state.labelColor = Bars.GetCachedEntryColor(entry, "barLabelColor", Bars.DEFAULTS.barLabelColor)
	state.valueAnchor = Bars.NormalizeTextAnchor(entry.barValueAnchor, Bars.DEFAULTS.barValueAnchor)
	state.valueFont = normalizeBarFont(entry.barValueFont, Bars.DEFAULTS.barValueFont)
	state.valueOffsetX = normalizeBarOffset(entry.barValueOffsetX, Bars.DEFAULTS.barValueOffsetX)
	state.valueOffsetY = normalizeBarOffset(entry.barValueOffsetY, Bars.DEFAULTS.barValueOffsetY)
	state.valueSize = normalizeBarFontSize(entry.barValueSize, Bars.DEFAULTS.barValueSize)
	state.valueStyle = normalizeBarFontStyle(entry.barValueStyle, Bars.DEFAULTS.barValueStyle)
	state.valueColor = Bars.GetCachedEntryColor(entry, "barValueColor", Bars.DEFAULTS.barValueColor)
	state.durationTextProfile = durationTextProfile
	state.spellId = resolvedSpellId
	return state
end

Bars.ResetBarRuntimeState = function(state)
	if not state then return end
	state.stackDisplayText = nil
	state.progress = 1
	state.fillDurationObject = nil
	state.timerDirection = cdp.BAR_STATUS_TIMER_DIRECTION_ELAPSED
	state.stackFillValue = nil
	state.stackFillMax = nil
	state.valueText = nil
	state.valueTextIsChargeDuration = nil
	state.animate = false
	state.cooldownVisibilityActive = false
	state.startTime = nil
	state.duration = nil
	state.rate = nil
	state.chargesInfo = nil
	state.chargeInfoActive = nil
	state.cooldownDurationObject = nil
	state.chargeDurationObject = nil
	state.inactiveDurationCondition = nil
	state.hasInactiveDurationCondition = nil
	state.rawCooldownDurationObject = nil
	state.cooldownRemaining = nil
	state.cooldownEnabled = nil
	state.cooldownGCD = nil
	state.cooldownIsActive = nil
	state.cooldownInfoActive = nil
	state.currentCharges = nil
	state.maxCharges = nil
	state.rawCurrentCharges = nil
	state.rawMaxCharges = nil
	state.rechargeProgress = nil
	state.lastNonGCDCooldownActive = nil
	state.lastNonGCDCooldownDurationObject = nil
	state.chargeDurationObjectRefreshed = nil
	state.deferChargeTimerHandoff = nil
	state.freezeChargeRender = nil
	state.previousChargePhase = nil
	state.chargePhase = nil
	state.renderChargePhase = nil
	state.cooldownStart = nil
	state.cooldownDuration = nil
	state.cooldownRate = nil
	state.rechargeStart = nil
	state.rechargeDuration = nil
	state.rechargeRate = nil
	state.chargeDurationTextActive = nil
	state.chargeDurationTextObject = nil
	state.chargeDurationTextStart = nil
	state.chargeDurationTextDuration = nil
	state.chargeDurationTextRate = nil
	state.chargeDurationTextSegmentIndex = nil
	state.chargeDurationTextNative = nil
end

buildBarState = function(panelId, entryId, entry, icon, preview, runtimeDataOverride)
	if not entry then return nil end
	local displayMode = normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode)
	if displayMode ~= Bars.DISPLAY_MODE.BAR then return nil end

	local mode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
	if not supportsBarMode(entry, mode) then return nil end

	local panel = panelId and CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	local panelLayout = panel and panel.layout or nil
	local hideOnCooldown, showOnCooldown = CooldownPanels.ResolveEntryCooldownVisibility and CooldownPanels:ResolveEntryCooldownVisibility(panelLayout, entry) or false, false
	local resolvedType, macro = getEntryResolvedType(entry)
	local runtimeReuseUtil = Bars._eqolRuntimeReuseUtil
	local reusableRuntimeData = runtimeReuseUtil.GetBarRuntimeData(icon, runtimeDataOverride, resolvedType, preview)
	local resolvedSpellId = resolvedType == "SPELL" and getResolvedSpellId(entry, macro) or nil
	local layoutEditActive = panelId and CooldownPanels.IsPanelLayoutEditActive and CooldownPanels:IsPanelLayoutEditActive(panelId) or false
	local staticVersion = entry._eqolBarsStaticVersion or 0
	local staticGeneration = CooldownPanels.runtime and CooldownPanels.runtime.barStaticGeneration or 0
	local labelGeneration = CooldownPanels.runtime and CooldownPanels.runtime.barLabelGeneration or 0
	local label = entry._eqolBarsCachedLabel
	if
		entry._eqolBarsCachedLabelGeneration ~= labelGeneration
		or entry._eqolBarsCachedLabelVersion ~= staticVersion
		or entry._eqolBarsCachedLabelType ~= entry.type
		or entry._eqolBarsCachedLabelSpellID ~= entry.spellID
		or entry._eqolBarsCachedLabelItemID ~= entry.itemID
		or entry._eqolBarsCachedLabelSlotID ~= entry.slotID
		or entry._eqolBarsCachedLabelCooldownID ~= entry.cooldownID
		or entry._eqolBarsCachedLabelBuffName ~= entry.buffName
		or entry._eqolBarsCachedLabelMacroID ~= entry.macroID
		or entry._eqolBarsCachedLabelMacroName ~= entry.macroName
		or entry._eqolBarsCachedLabelStanceID ~= (entry.stanceID or entry.stanceId)
		or entry._eqolBarsCachedLabelStanceKey ~= entry.stanceKey
		or entry._eqolBarsCachedLabelStanceClass ~= (entry.stanceClass or entry.classTag)
	then
		label = getEntryLabel(entry)
		entry._eqolBarsCachedLabel = label
		entry._eqolBarsCachedLabelGeneration = labelGeneration
		entry._eqolBarsCachedLabelVersion = staticVersion
		entry._eqolBarsCachedLabelType = entry.type
		entry._eqolBarsCachedLabelSpellID = entry.spellID
		entry._eqolBarsCachedLabelItemID = entry.itemID
		entry._eqolBarsCachedLabelSlotID = entry.slotID
		entry._eqolBarsCachedLabelCooldownID = entry.cooldownID
		entry._eqolBarsCachedLabelBuffName = entry.buffName
		entry._eqolBarsCachedLabelMacroID = entry.macroID
		entry._eqolBarsCachedLabelMacroName = entry.macroName
		entry._eqolBarsCachedLabelStanceID = entry.stanceID or entry.stanceId
		entry._eqolBarsCachedLabelStanceKey = entry.stanceKey
		entry._eqolBarsCachedLabelStanceClass = entry.stanceClass or entry.classTag
	end
	local texture = icon and icon.texture and icon.texture.GetTexture and icon.texture:GetTexture() or nil
	local progress = 1
	local valueText = nil
	local animate = false
	local cooldownValueVisible = false
	local cooldownVisibilityActive = false
	local runtimeData = nil
	local entryKey = entry._eqolBarsCachedEntryKey
	if entry._eqolBarsCachedEntryKeyPanelId ~= panelId or entry._eqolBarsCachedEntryKeyEntryId ~= entryId then
		entryKey = Helper.GetEntryKey(panelId, entryId)
		entry._eqolBarsCachedEntryKey = entryKey
		entry._eqolBarsCachedEntryKeyPanelId = panelId
		entry._eqolBarsCachedEntryKeyEntryId = entryId
	end
	local barsRuntime = getRuntimeState()
	local showChargeDuration = mode == Bars.BAR_MODE.CHARGES and getStoredBoolean(entry, "barShowChargeDuration", Bars.DEFAULTS.barShowChargeDuration) or false
	local showValueText = mode ~= Bars.BAR_MODE.STACKS and getStoredBoolean(entry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
	local showChargeCount = mode == Bars.BAR_MODE.CHARGES and showValueText == true or false
	if showChargeDuration then showValueText = true end
	local staticState = Bars.GetBarStaticState(entry, panel, mode, resolvedType, resolvedSpellId, label, staticVersion, staticGeneration, labelGeneration)
	local state = icon and icon._eqolBarsRuntimeState or nil
	if not state then
		state = {}
		if icon then icon._eqolBarsRuntimeState = state end
	end
	Bars.ResetBarRuntimeState(state)
	state.mode = mode
	state.label = staticState and staticState.label or label
	state.texture = texture
	state.preview = preview == true
	state.showIcon = staticState and staticState.showIcon or false
	state.showLabel = staticState and staticState.showLabel or false
	state.showValueText = showValueText
	state.showChargeDuration = showChargeDuration
	state.showChargeCount = showChargeCount
	state.showStackText = staticState and staticState.showStackText or false
	state.showStacks = staticState and staticState.showStacks or false
	state.stackDisplayText = nil
	state.progress = 1
	state.icon = icon
	state.panelId = panelId
	state.entryId = entryId
	state.fillDurationObject = nil
	state.timerDirection = cdp.BAR_STATUS_TIMER_DIRECTION_ELAPSED
	state.stackFillValue = nil
	state.stackFillMax = nil
	state.entryKey = entryKey
	state.configuredSpan = staticState and staticState.configuredSpan or Bars.DEFAULTS.barSpan
	state.barWidth = staticState and staticState.barWidth or Bars.DEFAULTS.barWidth
	state.barHeight = staticState and staticState.barHeight or Bars.DEFAULTS.barHeight
	state.barOffsetX = staticState and staticState.barOffsetX or 0
	state.barOffsetY = staticState and staticState.barOffsetY or 0
	state.orientation = staticState and staticState.orientation or Bars.DEFAULTS.barOrientation
	state.reverseFill = staticState and staticState.reverseFill or false
	state.segmentDirection = staticState and staticState.segmentDirection or Bars.DEFAULTS.barSegmentDirection
	state.segmentReverse = staticState and staticState.segmentReverse or false
	state.barTexture = staticState and staticState.barTexture or BAR_TEXTURE_DEFAULT
	state.fillColor = staticState and staticState.fillColor or getDefaultBarColorForMode(mode)
	state.backgroundColor = staticState and staticState.backgroundColor or Bars.DEFAULTS.barBackgroundColor
	state.borderEnabled = staticState and staticState.borderEnabled or false
	state.borderColor = staticState and staticState.borderColor or Bars.DEFAULTS.barBorderColor
	state.procGlowColor = staticState and staticState.procGlowColor or Bars.DEFAULTS.barProcGlowColor
	state.procGlowActive = isBarProcGlowActive(resolvedType, resolvedSpellId)
	state.borderTexture = staticState and staticState.borderTexture or nil
	state.borderOffset = staticState and staticState.borderOffset or 0
	state.borderSize = staticState and staticState.borderSize or 0
	state.iconSize = staticState and staticState.iconSize or Bars.DEFAULTS.barIconSize
	state.iconPosition = staticState and staticState.iconPosition or Bars.DEFAULTS.barIconPosition
	state.iconOffsetX = staticState and staticState.iconOffsetX or 0
	state.iconOffsetY = staticState and staticState.iconOffsetY or 0
	state.segmentedCharges = staticState and staticState.segmentedCharges or false
	state.chargesGap = staticState and staticState.chargesGap or 0
	state.segmentedStacks = staticState and staticState.segmentedStacks or false
	state.stackSeparatedOffset = staticState and staticState.stackSeparatedOffset or 0
	state.stackDividerColor = staticState and staticState.stackDividerColor or Bars.DEFAULTS.barStackDividerColor
	state.stackDividerThickness = staticState and staticState.stackDividerThickness or Bars.DEFAULTS.barStackDividerThickness
	state.stackMax = staticState and staticState.stackMax or Bars.DEFAULTS.barStackMax
	state.stackAnchor = staticState and staticState.stackAnchor or Bars.DEFAULTS.barStackAnchor
	state.stackFont = staticState and staticState.stackFont or Bars.DEFAULTS.barStackFont
	state.stackOffsetX = staticState and staticState.stackOffsetX or 0
	state.stackOffsetY = staticState and staticState.stackOffsetY or 0
	state.stackSize = staticState and staticState.stackSize or Bars.DEFAULTS.barStackSize
	state.stackStyle = staticState and staticState.stackStyle or Bars.DEFAULTS.barStackStyle
	state.stackColor = staticState and staticState.stackColor or Bars.DEFAULTS.barStackColor
	state.labelAnchor = staticState and staticState.labelAnchor or Bars.DEFAULTS.barLabelAnchor
	state.labelFont = staticState and staticState.labelFont or Bars.DEFAULTS.barLabelFont
	state.labelOffsetX = staticState and staticState.labelOffsetX or 0
	state.labelOffsetY = staticState and staticState.labelOffsetY or 0
	state.labelSize = staticState and staticState.labelSize or Bars.DEFAULTS.barLabelSize
	state.labelStyle = staticState and staticState.labelStyle or Bars.DEFAULTS.barLabelStyle
	state.labelColor = staticState and staticState.labelColor or Bars.DEFAULTS.barLabelColor
	state.valueAnchor = staticState and staticState.valueAnchor or Bars.DEFAULTS.barValueAnchor
	state.valueFont = staticState and staticState.valueFont or Bars.DEFAULTS.barValueFont
	state.valueOffsetX = staticState and staticState.valueOffsetX or 0
	state.valueOffsetY = staticState and staticState.valueOffsetY or 0
	state.valueSize = staticState and staticState.valueSize or Bars.DEFAULTS.barValueSize
	state.valueStyle = staticState and staticState.valueStyle or Bars.DEFAULTS.barValueStyle
	state.valueColor = staticState and staticState.valueColor or Bars.DEFAULTS.barValueColor
	state.durationTextProfile = staticState and staticState.durationTextProfile or Bars.DEFAULTS.barDurationTextProfile
	state.spellId = staticState and staticState.spellId or resolvedSpellId
	state.hideOnCooldown = hideOnCooldown == true
	state.showOnCooldown = showOnCooldown == true
	state.visible = true

	if preview then
		if mode == Bars.BAR_MODE.COOLDOWN then
			state.progress = 0.42
			state.valueText = getCooldownText(icon) or "12.4"
		elseif mode == Bars.BAR_MODE.CHARGES then
			local currentCharges = safeNumber(icon and icon.charges and icon.charges.GetText and icon.charges:GetText())
			local previewMaxCharges = Bars.GetEntryChargeSegmentCountHint(entry, currentCharges and max(currentCharges, 2) or 3)
			state.currentCharges = currentCharges or 1
			state.maxCharges = state.segmentedCharges == true and previewMaxCharges or max(state.currentCharges or 0, 3)
			state.rawCurrentCharges = state.currentCharges
			state.rawMaxCharges = state.maxCharges
			state.rechargeProgress = 0.48
			state.progress = clamp((state.currentCharges or 0) / state.maxCharges, 0, 1)
			if state.currentCharges < state.maxCharges then state.progress = clamp((state.currentCharges + state.rechargeProgress) / state.maxCharges, 0, 1) end
			if state.showChargeDuration == true then
				state.valueText = "12.4"
				state.valueTextIsChargeDuration = true
				state.chargeDurationTextActive = true
				state.chargeDurationTextSegmentIndex = state.segmentedCharges == true and 2 or nil
			else
				state.valueText = format("%d/%d", state.currentCharges or 0, state.maxCharges)
				if state.showChargeCount ~= true then state.valueText = nil end
			end
		else
			local stackDisplayText, stackValue = Bars.ResolveStackDisplay(panelId, entryId, resolvedType, icon, nil)
			state.stackDisplayText = stackDisplayText or tostring(stackValue or min(max(1, state.stackMax or Bars.DEFAULTS.barStackMax), 2))
			local stackMax = max(1, state.stackMax or Bars.DEFAULTS.barStackMax)
			state.progress = clamp((stackValue or min(stackMax, 2)) / max(stackMax, 1), 0, 1)
			state.stackFillValue = stackValue or min(stackMax, 2)
			state.stackFillMax = stackMax
		end
		if state.showStackText and not (Helper.HasDisplayCount and Helper.HasDisplayCount(state.stackDisplayText)) then state.stackDisplayText = resolvedType == "CDM_AURA" and "2" or "3" end
		return state
	end

	if mode == Bars.BAR_MODE.COOLDOWN then
		if resolvedType == "SPELL" then
			local spellId = resolvedSpellId
			if spellId and CooldownPanels.GetCachedSpellCooldownInfo then
				local reusableCooldownRuntimeData = reusableRuntimeData and reusableRuntimeData.customCooldownDurationActive == true and reusableRuntimeData
					or runtimeReuseUtil.HasCooldownRuntimeData(reusableRuntimeData, true) and reusableRuntimeData
					or nil
				local durationObject = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownDurationObject or nil
				local startTime = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownStart or nil
				local duration = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownDuration or nil
				local enabled = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownEnabled or nil
				local rate = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownRate or nil
				local cooldownGCD = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownGCD or nil
				local isActive = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownIsActive or nil
				if not reusableCooldownRuntimeData then
					durationObject = CooldownPanels.GetCachedSpellCooldownDurationObject and CooldownPanels:GetCachedSpellCooldownDurationObject(spellId, true) or nil
					startTime, duration, enabled, rate, cooldownGCD, isActive = CooldownPanels:GetCachedSpellCooldownInfo(spellId, true)
				end
				local cooldownActive = Bars.IsSpellCooldownActiveForBars(isActive, enabled, startTime, duration) and cooldownGCD ~= true
				if cooldownActive then
					progress = getDurationObjectElapsedProgress(durationObject) or getCooldownProgress(startTime, duration, rate) or 0
					valueText = Bars.GetCooldownValueText(icon, durationObject, startTime, duration, rate)
					animate = progress < 1 or durationObject ~= nil
					cooldownValueVisible = valueText ~= nil or durationObject ~= nil
					cooldownVisibilityActive = true
					state.startTime = safeNumber(startTime)
					state.duration = safeNumber(duration)
					state.rate = safeNumber(rate) or 1
					state.fillDurationObject = durationObject
					Bars.UseNativeDurationValueText(state, durationObject)
				else
					progress = 1
				end
			end
		elseif resolvedType == "ITEM" or resolvedType == "MACRO" then
			local itemId = getResolvedItemId(entry, macro)
			if itemId then
				local reusableCooldownRuntimeData = reusableRuntimeData and reusableRuntimeData.customCooldownDurationActive == true and reusableRuntimeData or nil
				local durationObject = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownDurationObject or nil
				local startTime = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownStart or nil
				local duration = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownDuration or nil
				local enabled = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownEnabled or nil
				local rate = reusableCooldownRuntimeData and reusableCooldownRuntimeData.cooldownRate or 1
				if not reusableCooldownRuntimeData and Api.GetItemCooldownFn then
					startTime, duration, enabled = Api.GetItemCooldownFn(itemId)
				end
				local cooldownActive = enabled ~= false and enabled ~= 0 and ((durationObject ~= nil) or (safeNumber(duration) and safeNumber(duration) > 0))
				if cooldownActive then
					progress = getDurationObjectElapsedProgress(durationObject) or getCooldownProgress(startTime, duration, rate) or 0
					valueText = Bars.GetCooldownValueText(icon, durationObject, startTime, duration, rate)
					animate = progress < 1 or durationObject ~= nil
					cooldownValueVisible = valueText ~= nil or durationObject ~= nil
					cooldownVisibilityActive = true
					state.startTime = safeNumber(startTime)
					state.duration = safeNumber(duration)
					state.rate = safeNumber(rate) or 1
					state.fillDurationObject = durationObject
					Bars.UseNativeDurationValueText(state, durationObject)
				else
					progress = 1
				end
			end
		elseif resolvedType == "CDM_AURA" then
			runtimeData = reusableRuntimeData
			if not runtimeData and CooldownPanels.CDMAuras and CooldownPanels.CDMAuras.BuildRuntimeData then
				runtimeData = CooldownPanels.CDMAuras:BuildRuntimeData(panelId, entryId, entry, nil, nil)
			end
			if runtimeData and (runtimeData.buffName or runtimeData.cdmAuraLabel) then
				state.label = runtimeData.buffName or runtimeData.cdmAuraLabel
				state.texture = runtimeData.iconTextureID or runtimeData.icon or state.texture
			end
			local durationObject = runtimeData and (runtimeData.cooldownDurationObject or runtimeData.cdmAuraDurationObject) or nil
			local auraActive = runtimeData and ((runtimeData.active == true) or (runtimeData.cdmAuraActive == true)) or false
			local durationActive = runtimeData and (runtimeData.durationActive == true or durationObject ~= nil) or false
			if auraActive ~= true then
				progress = 0
			elseif runtimeData and durationActive and durationObject ~= nil then
				animate = true
				cooldownValueVisible = true
				cooldownVisibilityActive = true
				state.fillDurationObject = durationObject
				if durationObject.IsActive then
					state.inactiveDurationCondition = durationObject:IsActive(Api.DurationModifierRealTime)
					state.hasInactiveDurationCondition = true
				end
				Bars.UseNativeDurationValueText(state, durationObject)
				state.timerDirection = cdp.BAR_STATUS_TIMER_DIRECTION_REMAINING
			elseif runtimeData and auraActive then
				local fallbackProgress = getCooldownProgress(runtimeData.cooldownStart, runtimeData.cooldownDuration, runtimeData.cooldownRate)
				local fallbackRemaining = max(
					0,
					(safeNumber(runtimeData.cooldownDuration) or 0)
						- (((Api.GetTime and Api.GetTime()) or GetTime()) - (safeNumber(runtimeData.cooldownStart) or 0)) * (safeNumber(runtimeData.cooldownRate) or 1)
				)
				progress = fallbackProgress and clamp(1 - fallbackProgress, 0, 1) or 1
				valueText = fallbackProgress and durationToText(fallbackRemaining) or nil
				animate = fallbackProgress ~= nil and fallbackProgress < 1 or false
				cooldownValueVisible = valueText ~= nil
				cooldownVisibilityActive = true
				state.timerDirection = cdp.BAR_STATUS_TIMER_DIRECTION_REMAINING
				state.startTime = safeNumber(runtimeData.cooldownStart)
				state.duration = safeNumber(runtimeData.cooldownDuration)
				state.rate = safeNumber(runtimeData.cooldownRate) or 1
			else
				progress = 1
			end
		end
		if state.showStacks then
			local stackDisplayText = nil
			stackDisplayText = select(1, Bars.ResolveStackDisplay(panelId, entryId, resolvedType, icon, runtimeData))
			state.stackDisplayText = stackDisplayText
		end
	elseif mode == Bars.BAR_MODE.CHARGES then
		local spellId = resolvedSpellId
		if spellId and CooldownPanels.GetCachedSpellChargesInfo then
			state.entryKey = entryKey
			refreshChargeBarRuntimeState(state, icon, reusableRuntimeData)
			progress = getChargeBarProgress(state)
			valueText = state.showChargeCount == true and getChargeBarValueText(icon, state.currentCharges, state.maxCharges) or nil
			if state.showChargeDuration == true then
				local durationText = Bars.UpdateChargeDurationTextState(state)
				if state.chargeDurationTextActive == true then
					valueText = state.chargeDurationTextNative == true and nil or durationText
					state.valueTextIsChargeDuration = true
				else
					state.valueTextIsChargeDuration = nil
				end
			end
			animate = state.animate == true
			cooldownVisibilityActive = state.lastNonGCDCooldownActive == true
		end
	else
		if resolvedType == "CDM_AURA" then
			runtimeData = reusableRuntimeData
			if not runtimeData and CooldownPanels.CDMAuras and CooldownPanels.CDMAuras.BuildRuntimeData then
				runtimeData = CooldownPanels.CDMAuras:BuildRuntimeData(panelId, entryId, entry, nil, nil)
			end
			if runtimeData and (runtimeData.buffName or runtimeData.cdmAuraLabel) then
				state.label = runtimeData.buffName or runtimeData.cdmAuraLabel
				state.texture = runtimeData.iconTextureID or runtimeData.icon or state.texture
			end
			local stackDisplayText, stackValue, rawStackValue = Bars.ResolveStackDisplay(panelId, entryId, resolvedType, icon, runtimeData)
			state.stackDisplayText = stackDisplayText or (stackValue ~= nil and tostring(stackValue) or nil)
			local stackMax = max(1, state.stackMax or Bars.DEFAULTS.barStackMax)
			state.stackFillValue = rawStackValue
			state.stackFillMax = stackMax
			if stackValue ~= nil then
				progress = clamp(stackValue / stackMax, 0, 1)
			elseif Helper.HasDisplayCount and Helper.HasDisplayCount(stackDisplayText) then
				progress = 0
			else
				progress = 0
			end
		else
			local stackDisplayText, stackValue, rawStackValue = Bars.ResolveStackDisplay(panelId, entryId, resolvedType, icon, nil)
			state.stackDisplayText = stackDisplayText or (stackValue ~= nil and tostring(stackValue) or nil)
			local stackMax = max(1, state.stackMax or Bars.DEFAULTS.barStackMax)
			state.stackFillValue = rawStackValue
			state.stackFillMax = stackMax
			if stackValue and stackMax > 0 then
				progress = clamp(stackValue / stackMax, 0, 1)
			elseif Helper.HasDisplayCount and Helper.HasDisplayCount(stackDisplayText) then
				progress = 0
			else
				progress = 1
			end
		end
	end

	state.progress = progress or 0
	state.cooldownVisibilityActive = cooldownVisibilityActive == true
	if state.showOnCooldown then
		state.visible = state.cooldownVisibilityActive == true
	elseif state.hideOnCooldown then
		state.visible = state.cooldownVisibilityActive ~= true
	else
		state.visible = true
	end
	if mode == Bars.BAR_MODE.COOLDOWN then
		if state.chargeDurationTextNative == true then
			state.valueText = nil
		else
			state.valueText = cooldownValueVisible and (valueText or getCooldownText(icon) or nil) or nil
		end
	elseif mode == Bars.BAR_MODE.STACKS then
		state.valueText = nil
	else
		state.valueText = valueText or nil
	end
	if layoutEditActive and state.showValueText and state.valueText == nil then
		if mode == Bars.BAR_MODE.COOLDOWN then
			state.valueText = "12.4"
		elseif mode == Bars.BAR_MODE.CHARGES then
			if state.showChargeDuration == true then
				state.valueText = "12.4"
				state.valueTextIsChargeDuration = true
				state.chargeDurationTextActive = true
				state.chargeDurationTextSegmentIndex = state.segmentedCharges == true and 2 or nil
			else
				state.valueText = state.segmentedCharges == true and (getChargeBarValueText(icon, 1, state.maxCharges) or "1/2") or "2/3"
			end
		end
	end
	if layoutEditActive and state.showStackText and not (Helper.HasDisplayCount and Helper.HasDisplayCount(state.stackDisplayText)) then
		state.stackDisplayText = resolvedType == "CDM_AURA" and "2" or "3"
	end
	state.animate = animate == true
	return state
end

local function layoutChargeSegmentsIntoBar(
	barFrame,
	icon,
	state,
	segmentCount,
	gap,
	segmentDirection,
	segmentReverse,
	bodyWidth,
	bodyHeight,
	borderTexturePath,
	borderSize,
	borderOffset,
	borderColor,
	backgroundColor,
	fillTexturePath,
	fillColor,
	orientation,
	effectiveScale
)
	Bars.HideUnusedBarDividers(barFrame, 1)
	local segmentAxisSize = segmentDirection == BAR_ORIENTATION_VERTICAL and bodyHeight or bodyWidth
	local totalGapSize = max(segmentCount - 1, 0) * gap
	local segmentPrimarySize = max(1, (segmentAxisSize - totalGapSize) / segmentCount)
	local remainingPixels = 0
	Bars.HideForwardHitHandle(barFrame.hitHandle)
	barFrame.fill:Hide()
	barFrame.fillBg:Hide()
	if barFrame.borderOverlay then barFrame.borderOverlay:Hide() end

	for index = 1, segmentCount do
		local segment = ensureBarSegment(barFrame, index)
		local visualIndex = segmentReverse and (segmentCount - index + 1) or index
		local extraPixel = index <= remainingPixels and 1 or 0
		local primarySize = segmentPrimarySize + extraPixel
		local primaryOffset = (visualIndex - 1) * (segmentPrimarySize + gap) + min(visualIndex - 1, remainingPixels)
		segment:ClearAllPoints()
		if segmentDirection == BAR_ORIENTATION_VERTICAL then
			segment:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", 0, -primaryOffset)
			segment:SetSize(bodyWidth, primarySize)
		else
			segment:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", primaryOffset, 0)
			segment:SetSize(primarySize, bodyHeight)
		end
		local fillInset = Bars.GetBarFillInset(borderSize, effectiveScale, segmentDirection == BAR_ORIENTATION_VERTICAL and bodyWidth or primarySize, segmentDirection == BAR_ORIENTATION_VERTICAL and primarySize or bodyHeight)
		segment:SetFrameStrata(barFrame:GetFrameStrata())
		segment:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 1)
		applyBackdropFrame(segment, "Interface\\Buttons\\WHITE8x8", 1)
		segment:SetBackdropColor(0, 0, 0, 0)
		segment:SetBackdropBorderColor(0, 0, 0, 0)
		applyStatusBarTexture(segment.fill, fillTexturePath)
		applyStatusBarOrientation(segment.fill, orientation)
		segment.fill:SetFrameLevel(segment:GetFrameLevel() + 1)
		segment.fill:ClearAllPoints()
		segment.fill:SetPoint("TOPLEFT", segment, "TOPLEFT", fillInset, -fillInset)
		segment.fill:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", -fillInset, fillInset)
		segment.fillBg:SetTexture(fillTexturePath)
		segment.fillBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
		segment.fill:SetStatusBarColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4])
		if segment.borderOverlay then
			segment.borderOverlay:SetFrameStrata(barFrame:GetFrameStrata())
			segment.borderOverlay:SetFrameLevel(segment:GetFrameLevel() + 2)
			if borderSize > 0 then
				segment.borderOverlay:ClearAllPoints()
				segment.borderOverlay:SetPoint("TOPLEFT", segment, "TOPLEFT", -borderOffset, borderOffset)
				segment.borderOverlay:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", borderOffset, -borderOffset)
				applyBackdropFrame(segment.borderOverlay, borderTexturePath, borderSize)
				segment.borderOverlay:SetBackdropColor(0, 0, 0, 0)
				segment.borderOverlay:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
				segment.borderOverlay:Show()
			else
				segment.borderOverlay:Hide()
			end
		end
		Bars.ConfigureForwardHitHandle(segment.hitHandle, segment, icon and icon.layoutHandle or nil)
		Bars.ConfigureFreeMoveHandle(segment.hitHandle, barFrame, icon)
		segment:Show()
	end

	hideUnusedBarSegments(barFrame, segmentCount + 1)
	barFrame._eqolSegmentCount = segmentCount

	local chargePhase = state.renderChargePhase or state.chargePhase
	local freezeChargeRender = state.freezeChargeRender == true
	local gateDurationObject = nil
	if chargePhase == "EMPTY" then
		gateDurationObject = state.cooldownDurationObject
	elseif chargePhase == "PARTIAL" and state.deferChargeTimerHandoff ~= true and state.chargeInfoActive == true then
		gateDurationObject = state.chargeDurationObject
	elseif chargePhase == nil and state.chargeInfoActive == true then
		gateDurationObject = state.chargeDurationObject
	end

	local canUseAnchoredChargeTracker = freezeChargeRender ~= true and segmentDirection == BAR_ORIENTATION_HORIZONTAL and segmentReverse ~= true
	if canUseAnchoredChargeTracker then
		Bars.ClearChargeGateCooldown(barFrame)
		local tracker, refresh = Bars.EnsureChargeSegmentTracker(barFrame)
		local currentChargesValue = state.rawCurrentCharges
		if currentChargesValue == nil then
			if chargePhase == "EMPTY" then
				currentChargesValue = 0
			elseif chargePhase == "PARTIAL" then
				currentChargesValue = 1
			elseif chargePhase == "FULL" then
				currentChargesValue = segmentCount
			else
				currentChargesValue = state.currentCharges or 0
			end
		end
		if tracker and refresh and refresh.fill then
			local trackerTexture = tracker.GetStatusBarTexture and tracker:GetStatusBarTexture() or nil
			tracker:ClearAllPoints()
			tracker:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", 0, 0)
			tracker:SetSize(max(1, segmentCount * (segmentPrimarySize + gap)), bodyHeight)
			tracker:SetMinMaxValues(0, segmentCount)
			tracker:SetValue(currentChargesValue or 0)
			if tracker.SetToTargetValue then tracker:SetToTargetValue() end
			tracker:Show()

			refresh:ClearAllPoints()
			refresh:SetSize(segmentPrimarySize, bodyHeight)
			if trackerTexture then
				refresh:SetPoint("LEFT", trackerTexture, "RIGHT", 0, 0)
			else
				refresh:SetPoint("LEFT", barFrame.body, "LEFT", 0, 0)
			end
			refresh:SetFrameStrata(barFrame:GetFrameStrata())
			refresh:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 3)
			applyStatusBarTexture(refresh.fill, fillTexturePath)
			applyStatusBarOrientation(refresh.fill, orientation)
			refresh.fill:SetStatusBarColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4])

			if gateDurationObject ~= nil then
				if setStatusBarTimerDuration(
					refresh.fill,
					gateDurationObject,
					table.concat({
						"seg-refresh",
						tostring(state.entryKey or state.entryId or "nil"),
						tostring(chargePhase or "nil"),
						tostring(safeNumber(state.maxCharges) or segmentCount),
					}, ":")
				) then
					barFrame._eqolChargeSegmentRefreshTextAnchor = refresh
					refresh:Show()
				else
					barFrame._eqolChargeSegmentRefreshTextAnchor = nil
					refresh:Hide()
				end
			else
				barFrame._eqolChargeSegmentRefreshTextAnchor = nil
				setStatusBarImmediateValue(refresh.fill, 0)
				refresh:Hide()
				if chargePhase == "PARTIAL" and state.deferChargeTimerHandoff == true then Bars.ScheduleChargeTimerHandoffRefresh(state) end
			end
		end

		for index = 1, segmentCount do
			local segment = barFrame.segments and barFrame.segments[index] or nil
			if segment and segment.fill then
				segment.fill:Show()
				segment.fill:SetMinMaxValues(index - 0.5, index, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE)
				segment.fill:SetValue(currentChargesValue or 0, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE)
				if segment.fill.SetToTargetValue then segment.fill:SetToTargetValue() end
				segment.fill._eqolTimerDurationObject = nil
				segment.fill._eqolTimerDurationKey = nil
				segment.fill._eqolTimerDirection = nil
				local fillTexture = segment.fill.GetStatusBarTexture and segment.fill:GetStatusBarTexture() or nil
				if fillTexture and fillTexture.SetAlpha then fillTexture:SetAlpha(1) end
			end
		end
		return
	end

	barFrame._eqolChargeSegmentRefreshTextAnchor = nil
	Bars.HideChargeSegmentTracker(barFrame)
	local gateCooldown = ensureBarCooldownGate(barFrame)
	local gateCacheKey = table.concat({
		"gate",
		tostring(state.entryKey or state.entryId or "nil"),
		tostring(chargePhase or "nil"),
		tostring(safeNumber(state.maxCharges) or "nil"),
		tostring(gateDurationObject ~= nil),
	}, ":")
	local gateActive = barFrame._eqolChargeGateActive == true
	if freezeChargeRender ~= true then
		if gateDurationObject ~= nil then
			gateCooldown._eqolPanelId = state.panelId
			gateCooldown._eqolEntryId = state.entryId
			gateCooldown._eqolSpellId = state.spellId
			if gateCooldown.SetScript then gateCooldown:SetScript("OnCooldownDone", Bars.OnChargeGateCooldownDone) end
			if setCooldownFrameDuration(gateCooldown, gateDurationObject, gateCacheKey) and gateCooldown.Show then gateCooldown:Show() end
		else
			if gateCooldown.SetScript then gateCooldown:SetScript("OnCooldownDone", nil) end
			gateCooldown._eqolPanelId = nil
			gateCooldown._eqolEntryId = nil
			gateCooldown._eqolSpellId = nil
			setCooldownFrameDuration(gateCooldown, nil, gateCacheKey)
		end
		gateActive = gateDurationObject ~= nil
		local previousGateActive = barFrame._eqolChargeGateActive == true
		if gateActive ~= previousGateActive then
			if gateActive then
				barFrame._eqolSegment1Generation = (barFrame._eqolSegment1Generation or 0) + 1
			else
				barFrame._eqolSegment2Generation = (barFrame._eqolSegment2Generation or 0) + 1
			end
			barFrame._eqolChargeGateActive = gateActive
		end
	end

	for index = 1, segmentCount do
		local segment = barFrame.segments and barFrame.segments[index] or nil
		if segment and segment.fill then
			if freezeChargeRender ~= true and segment.fill.Show then segment.fill:Show() end
			if freezeChargeRender == true then
				-- keep current visual state while runtime waits for handoff
			elseif chargePhase == "EMPTY" then
				if index == 1 and gateDurationObject then
					setStatusBarTimerDuration(
						segment.fill,
						gateDurationObject,
						table.concat({
							"seg1",
							tostring(state.entryKey or state.entryId or "nil"),
							tostring(barFrame._eqolSegment1Generation or 0),
							tostring(chargePhase or "nil"),
						}, ":")
					)
				else
					setStatusBarImmediateValue(segment.fill, 0)
				end
			elseif chargePhase == "PARTIAL" then
				if index == 1 then
					setStatusBarImmediateValue(segment.fill, 1)
				elseif state.deferChargeTimerHandoff == true then
					setStatusBarImmediateValue(segment.fill, 0)
					if segment.fill.Hide then segment.fill:Hide() end
					Bars.ScheduleChargeTimerHandoffRefresh(state)
				elseif state.chargeInfoActive == true and state.chargeDurationObject ~= nil then
					setStatusBarTimerDuration(
						segment.fill,
						state.chargeDurationObject,
						table.concat({
							"seg2",
							tostring(state.entryKey or state.entryId or "nil"),
							tostring(barFrame._eqolSegment2Generation or 0),
							tostring(chargePhase or "nil"),
						}, ":")
					)
				else
					setStatusBarImmediateValue(segment.fill, 0)
				end
			else
				setStatusBarImmediateValue(segment.fill, 1)
			end
			local fillTexture = segment.fill.GetStatusBarTexture and segment.fill:GetStatusBarTexture() or nil
			if freezeChargeRender ~= true and fillTexture and fillTexture.SetAlpha then fillTexture:SetAlpha(1) end
		end
	end
end

Bars.LayoutStackSegmentsIntoBar = function(
	barFrame,
	icon,
	state,
	segmentCount,
	gap,
	segmentDirection,
	bodyWidth,
	bodyHeight,
	borderTexturePath,
	borderSize,
	borderOffset,
	borderColor,
	backgroundColor,
	fillTexturePath,
	fillColor,
	orientation,
	effectiveScale
)
	segmentCount = Bars.NormalizeBarStackMax(segmentCount, Bars.DEFAULTS.barStackMax)
	gap = normalizeBarChargesGap(gap, Bars.DEFAULTS.barStackSeparatedOffset)
	local segmentAxisSize = segmentDirection == BAR_ORIENTATION_VERTICAL and bodyHeight or bodyWidth
	if segmentCount < 2 then
		gap = 0
	else
		local maxGap = max(0, floor((segmentAxisSize - segmentCount) / (segmentCount - 1)))
		if gap > maxGap then gap = maxGap end
	end
	local totalGapSize = max(segmentCount - 1, 0) * gap
	local segmentPrimarySize = max(1, floor((segmentAxisSize - totalGapSize) / segmentCount))
	local remainingPixels = max(0, segmentAxisSize - ((segmentPrimarySize * segmentCount) + totalGapSize))
	Bars.HideForwardHitHandle(barFrame.hitHandle)
	barFrame.fill:Hide()
	barFrame.fillBg:Hide()
	if barFrame.borderOverlay then barFrame.borderOverlay:Hide() end

	local stackValue = state and state.stackFillValue
	if not isSecretValue(stackValue) then
		stackValue = safeNumber(stackValue)
		if stackValue == nil then stackValue = (safeNumber(state and state.progress) or 0) * segmentCount end
	end

	for index = 1, segmentCount do
		local segment = ensureBarSegment(barFrame, index)
		local extraPixel = index <= remainingPixels and 1 or 0
		local primarySize = segmentPrimarySize + extraPixel
		local primaryOffset = (index - 1) * (segmentPrimarySize + gap) + min(index - 1, remainingPixels)
		segment:ClearAllPoints()
		if segmentDirection == BAR_ORIENTATION_VERTICAL then
			segment:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", 0, -primaryOffset)
			segment:SetSize(bodyWidth, primarySize)
		else
			segment:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", primaryOffset, 0)
			segment:SetSize(primarySize, bodyHeight)
		end
		local fillInset = Bars.GetBarFillInset(borderSize, effectiveScale, segmentDirection == BAR_ORIENTATION_VERTICAL and bodyWidth or primarySize, segmentDirection == BAR_ORIENTATION_VERTICAL and primarySize or bodyHeight)
		segment:SetFrameStrata(barFrame:GetFrameStrata())
		segment:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 1)
		applyBackdropFrame(segment, "Interface\\Buttons\\WHITE8x8", 1)
		segment:SetBackdropColor(0, 0, 0, 0)
		segment:SetBackdropBorderColor(0, 0, 0, 0)
		applyStatusBarTexture(segment.fill, fillTexturePath)
		applyStatusBarOrientation(segment.fill, orientation)
		segment.fill:SetFrameLevel(segment:GetFrameLevel() + 1)
		segment.fill:ClearAllPoints()
		segment.fill:SetPoint("TOPLEFT", segment, "TOPLEFT", fillInset, -fillInset)
		segment.fill:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", -fillInset, fillInset)
		segment.fillBg:SetTexture(fillTexturePath)
		segment.fillBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
		segment.fillBg:Show()
		segment.fill:SetStatusBarColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4])
		segment.fill:SetMinMaxValues(index - 1, index, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE)
		segment.fill:SetValue(stackValue or 0, cdp.BAR_STATUS_INTERPOLATION_IMMEDIATE)
		if segment.fill.SetToTargetValue then segment.fill:SetToTargetValue() end
		segment.fill._eqolTimerDurationObject = nil
		segment.fill._eqolTimerDurationKey = nil
		segment.fill._eqolTimerDirection = nil
		segment.fill:Show()
		local fillTexture = segment.fill.GetStatusBarTexture and segment.fill:GetStatusBarTexture() or nil
		if fillTexture and fillTexture.SetAlpha then fillTexture:SetAlpha(1) end
		if segment.borderOverlay then
			segment.borderOverlay:SetFrameStrata(barFrame:GetFrameStrata())
			segment.borderOverlay:SetFrameLevel(segment:GetFrameLevel() + 2)
			if borderSize > 0 then
				segment.borderOverlay:ClearAllPoints()
				segment.borderOverlay:SetPoint("TOPLEFT", segment, "TOPLEFT", -borderOffset, borderOffset)
				segment.borderOverlay:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", borderOffset, -borderOffset)
				applyBackdropFrame(segment.borderOverlay, borderTexturePath, borderSize)
				segment.borderOverlay:SetBackdropColor(0, 0, 0, 0)
				segment.borderOverlay:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
				segment.borderOverlay:Show()
			else
				segment.borderOverlay:Hide()
			end
		end
		Bars.ConfigureForwardHitHandle(segment.hitHandle, segment, icon and icon.layoutHandle or nil)
		Bars.ConfigureFreeMoveHandle(segment.hitHandle, barFrame, icon)
		segment:Show()
	end

	local visibleDividerIndex = 1
	if barFrame.dividerOverlay and gap > 0 and segmentCount > 1 then
		local dividerColor = Helper.NormalizeColor(state and state.stackDividerColor, Bars.DEFAULTS.barStackDividerColor)
		local dividerAlpha = min(1, max(dividerColor[4] or 1, 0))
		local requestedThickness = normalizeBarStackDividerThickness(state and state.stackDividerThickness, Bars.DEFAULTS.barStackDividerThickness)
		local dividerThicknessPixels = min(gap, max(pixelSnap(requestedThickness, effectiveScale), 1))
		if dividerThicknessPixels > 0 then
			local markOffset = floor((gap - dividerThicknessPixels) * 0.5)
			for index = 1, segmentCount - 1 do
				local segment = barFrame.segments and barFrame.segments[index] or nil
				if segment then
					local divider = Bars.EnsureBarDivider(barFrame, visibleDividerIndex)
					divider:ClearAllPoints()
					divider:SetColorTexture(dividerColor[1], dividerColor[2], dividerColor[3], dividerAlpha)
					if segmentDirection == BAR_ORIENTATION_VERTICAL then
						divider:SetPoint("TOPLEFT", segment, "BOTTOMLEFT", 0, -markOffset)
						divider:SetPoint("TOPRIGHT", segment, "BOTTOMRIGHT", 0, -markOffset)
						divider:SetHeight(dividerThicknessPixels)
					else
						divider:SetPoint("TOPLEFT", segment, "TOPRIGHT", markOffset, 0)
						divider:SetPoint("BOTTOMLEFT", segment, "BOTTOMRIGHT", markOffset, 0)
						divider:SetWidth(dividerThicknessPixels)
					end
					divider:Show()
					visibleDividerIndex = visibleDividerIndex + 1
				end
			end
		end
	end
	Bars.HideUnusedBarDividers(barFrame, visibleDividerIndex)
	if visibleDividerIndex > 1 and barFrame.dividerOverlay then barFrame.dividerOverlay:Show() end

	hideUnusedBarSegments(barFrame, segmentCount + 1)
	barFrame._eqolSegmentCount = segmentCount
end

local function layoutBarTextElement(
	barFrame,
	orientation,
	textWidth,
	fontString,
	text,
	role,
	fontPath,
	fontSize,
	fontStyle,
	fontColor,
	defaultFontPath,
	defaultFontSize,
	defaultFontStyle,
	anchor,
	offsetX,
	offsetY,
	relativeFrame
)
	applyFontStringStyle(fontString, fontPath, fontSize, fontStyle, fontColor, defaultFontPath, defaultFontSize, defaultFontStyle)
	local resolvedAnchor = Bars.GetResolvedTextAnchor(anchor, orientation, role)
	local point, relativePoint, justifyH = Bars.GetTextAnchorConfig(anchor, orientation, role)
	local anchorFrame = relativeFrame or barFrame.textOverlay
	local insetX = offsetX or 0
	local insetY = offsetY or 0
	local justifyV = "MIDDLE"
	local textValue = text or ""
	local textInset = 4

	if fontString._eqolBarsTextStaticSetup ~= true then
		if fontString.SetWordWrap then fontString:SetWordWrap(false) end
		if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(false) end
		if fontString.SetMaxLines then fontString:SetMaxLines(1) end
		fontString._eqolBarsTextStaticSetup = true
	end
	fontString:SetWidth(0)
	fontString:SetText(textValue)
	local stringWidth = safeNumber(fontString.GetStringWidth and fontString:GetStringWidth() or nil)
	insetX = pixelSnap(insetX, barFrame and barFrame.textOverlay or barFrame)
	insetY = pixelSnap(insetY, barFrame and barFrame.textOverlay or barFrame)
	if stringWidth and stringWidth > 0 then
		fontString:SetWidth(pixelSnap(max(1, stringWidth + 2), barFrame and barFrame.textOverlay or barFrame))
	end
	local anchorPoint = point
	local anchorRelativePoint = relativePoint
	local anchorOffsetX = insetX
	local anchorOffsetY = insetY
	if resolvedAnchor == Bars.TEXT_ANCHOR.LEFT then
		anchorPoint = "LEFT"
		anchorRelativePoint = "LEFT"
		anchorOffsetX = textInset + insetX
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.RIGHT then
		anchorPoint = "RIGHT"
		anchorRelativePoint = "RIGHT"
		anchorOffsetX = -textInset + insetX
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.TOP then
		anchorOffsetY = insetY - textInset
		justifyV = "TOP"
	elseif resolvedAnchor == Bars.TEXT_ANCHOR.BOTTOM then
		anchorOffsetY = insetY + textInset
		justifyV = "BOTTOM"
	end
	if
		fontString._eqolBarsTextPoint ~= anchorPoint
		or fontString._eqolBarsTextAnchorFrame ~= anchorFrame
		or fontString._eqolBarsTextRelativePoint ~= anchorRelativePoint
		or fontString._eqolBarsTextOffsetX ~= anchorOffsetX
		or fontString._eqolBarsTextOffsetY ~= anchorOffsetY
	then
		fontString:ClearAllPoints()
		fontString:SetPoint(anchorPoint, anchorFrame, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
		fontString._eqolBarsTextPoint = anchorPoint
		fontString._eqolBarsTextAnchorFrame = anchorFrame
		fontString._eqolBarsTextRelativePoint = anchorRelativePoint
		fontString._eqolBarsTextOffsetX = anchorOffsetX
		fontString._eqolBarsTextOffsetY = anchorOffsetY
	end
	if fontString._eqolBarsTextJustifyH ~= justifyH then
		fontString:SetJustifyH(justifyH)
		fontString._eqolBarsTextJustifyH = justifyH
	end
	if fontString.SetJustifyV and fontString._eqolBarsTextJustifyV ~= justifyV then
		fontString:SetJustifyV(justifyV)
		fontString._eqolBarsTextJustifyV = justifyV
	end
	fontString:Show()
end

layoutBarFrame = function(barFrame, icon, span, layout, state)
	if not (barFrame and icon) then return end
	local slotAnchor = icon.slotAnchor or icon
	local slotSize = safeNumber(icon._eqolBaseSlotSize) or slotAnchor:GetWidth() or 36
	local spacing = Helper.ClampInt(layout and layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2)
	local availableWidth = (slotSize * span) + (max(span - 1, 0) * spacing)
	local effectiveScale = slotAnchor.GetEffectiveScale and slotAnchor:GetEffectiveScale() or nil
	local configuredSpan = normalizeBarSpan(state and state.configuredSpan, Bars.DEFAULTS.barSpan)
	local autoWidth = max(slotSize, (slotSize * configuredSpan) + (max(configuredSpan - 1, 0) * spacing))
	local configuredWidth = normalizeBarWidth(state and state.barWidth, Bars.DEFAULTS.barWidth)
	local resolvedWidth = configuredWidth > 0 and max(BAR_WIDTH_MIN, configuredWidth) or min(autoWidth, availableWidth)
	local width = pixelSnap(resolvedWidth, effectiveScale)
	local height = pixelSnap(normalizeBarHeight(state and state.barHeight, max(16, floor(slotSize * 0.72))), effectiveScale)
	local offsetX = pixelSnap(normalizeBarOffset(state and state.barOffsetX, Bars.DEFAULTS.barOffsetX), effectiveScale)
	local offsetY = pixelSnap(normalizeBarOffset(state and state.barOffsetY, Bars.DEFAULTS.barOffsetY), effectiveScale)
	local orientation = normalizeBarOrientation(state and state.orientation, Bars.DEFAULTS.barOrientation)
	local chargeSegmentCount = state.mode == Bars.BAR_MODE.CHARGES and state.segmentedCharges == true and safeNumber(state.maxCharges) or 0
	if chargeSegmentCount then chargeSegmentCount = clamp(floor(chargeSegmentCount), 0, 20) end
	local useChargeSegments = state.mode == Bars.BAR_MODE.CHARGES and state.segmentedCharges == true and chargeSegmentCount and chargeSegmentCount > 1
	local stackSeparatedOffset = normalizeBarChargesGap(state and state.stackSeparatedOffset, Bars.DEFAULTS.barStackSeparatedOffset)
	local useStackSegments = state.mode == Bars.BAR_MODE.STACKS and state.segmentedStacks == true and stackSeparatedOffset > 0
	local useStackDividers = state.mode == Bars.BAR_MODE.STACKS and state.segmentedStacks == true and not useStackSegments
	local segmentCount = useChargeSegments and chargeSegmentCount or 0
	local gap = useChargeSegments and normalizeBarChargesGap(state.chargesGap, Bars.DEFAULTS.barChargesGap) or 0
	local segmentDirection = useChargeSegments and normalizeBarSegmentDirection(state.segmentDirection, Bars.DEFAULTS.barSegmentDirection) or BAR_ORIENTATION_HORIZONTAL
	local segmentReverse = useChargeSegments and state.segmentReverse == true or false
	local stackSegmentCount = useStackSegments and Bars.NormalizeBarStackMax(state.stackFillMax or state.stackMax, Bars.DEFAULTS.barStackMax) or 0

	local borderEnabled = state and state.borderEnabled == true
	local borderSize = borderEnabled and normalizeBarBorderSize(state and state.borderSize, Bars.DEFAULTS.barBorderSize) or 0
	local fillTexturePath = state and state.barTexture or resolveBarTexture(Bars.DEFAULTS.barTexture)
	local borderTexturePath = state and state.borderTexture or resolveBarBorderTexture(Bars.DEFAULTS.barBorderTexture)
	applyStatusBarTexture(barFrame.fill, fillTexturePath)
	applyStatusBarOrientation(barFrame.fill, orientation)
	barFrame.fillBg:SetTexture(fillTexturePath)

	local fillColor = state and state.fillColor or getDefaultBarColorForMode(state and state.mode or Bars.BAR_MODE.COOLDOWN)
	local backgroundColor = state and state.backgroundColor or Bars.DEFAULTS.barBackgroundColor
	local borderColor = state and state.borderColor or Bars.DEFAULTS.barBorderColor
	if state and state.procGlowActive == true then
		fillColor = state.procGlowColor or fillColor
		borderColor = state.procGlowColor or borderColor
	end
	local outerPadding = 2
	local iconSpacing = 4
	local iconSize = state.showIcon and pixelSnap(Bars.DEFAULTS.barIconSize, effectiveScale) or 0
	local configuredIconSize = normalizeBarIconSize(state and state.iconSize, Bars.DEFAULTS.barIconSize)
	if configuredIconSize > 0 then iconSize = pixelSnap(configuredIconSize, effectiveScale) end
	local iconArea = state.showIcon and (iconSize + iconSpacing) or 0
	local iconPosition = normalizeBarIconPosition(state and state.iconPosition, Bars.DEFAULTS.barIconPosition)
	local bodyLeft = outerPadding + ((state.showIcon and iconPosition == BAR_ICON_POSITION_LEFT) and iconArea or 0)
	local bodyRight = outerPadding + ((state.showIcon and iconPosition == BAR_ICON_POSITION_RIGHT) and iconArea or 0)
	local bodyTop = outerPadding + ((state.showIcon and iconPosition == BAR_ICON_POSITION_TOP) and iconArea or 0)
	local bodyBottom = outerPadding + ((state.showIcon and iconPosition == BAR_ICON_POSITION_BOTTOM) and iconArea or 0)
	local bodyWidth = max(1, width)
	local bodyHeight = max(1, height)
	local frameWidth = bodyLeft + bodyWidth + bodyRight
	local frameHeight = bodyTop + bodyHeight + bodyBottom

	if useChargeSegments then
		if segmentDirection == BAR_ORIENTATION_VERTICAL then
			frameHeight = pixelSnap(bodyTop + bodyBottom + (height * segmentCount) + (max(segmentCount - 1, 0) * gap), effectiveScale)
			bodyHeight = max(1, frameHeight - bodyTop - bodyBottom)
		else
			frameWidth = pixelSnap(bodyLeft + bodyRight + (width * segmentCount) + (max(segmentCount - 1, 0) * gap), effectiveScale)
			bodyWidth = max(1, frameWidth - bodyLeft - bodyRight)
		end
	end

	local anchorFrame = slotAnchor
	local anchorPoint = "LEFT"
	local relativePoint = "LEFT"
	local anchorBaseX = 0
	local anchorBaseY = 0
	local stableParent = nil
	if state and state.preview ~= true and state.panelId then
		local panelRuntime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId] or nil
		stableParent = panelRuntime and panelRuntime.frame or nil
	end
	if state and state.panelId and CooldownPanels.IsPanelLayoutEditActive and CooldownPanels:IsPanelLayoutEditActive(state.panelId) then
		local cellColumn = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellColumn or icon._eqolLayoutSlotColumn)
		local cellRow = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellRow or icon._eqolLayoutSlotRow)
		local gridCell = Bars.GetEditorGridCell(state.panelId, cellColumn, cellRow)
		if gridCell then
			anchorFrame = gridCell
			anchorPoint = "TOPLEFT"
			relativePoint = "TOPLEFT"
			anchorBaseY = pixelSnap(-((slotSize - frameHeight) / 2), effectiveScale)
		end
	end

	local parent = stableParent or anchorFrame:GetParent() or slotAnchor:GetParent() or icon:GetParent() or UIParent
	if barFrame:GetParent() ~= parent then barFrame:SetParent(parent) end
	barFrame:ClearAllPoints()
	barFrame:SetPoint(anchorPoint, anchorFrame, relativePoint, pixelSnap(anchorBaseX + offsetX, effectiveScale), pixelSnap(anchorBaseY + offsetY, effectiveScale))
	barFrame._eqolAnchorFrame = anchorFrame
	barFrame._eqolAnchorPoint = anchorPoint
	barFrame._eqolAnchorRelativePoint = relativePoint
	barFrame._eqolAnchorBaseX = anchorBaseX
	barFrame._eqolAnchorBaseY = anchorBaseY
	barFrame:SetFrameStrata((icon.overlay and icon.overlay:GetFrameStrata()) or icon:GetFrameStrata())
	barFrame:SetFrameLevel(((icon.overlay and icon.overlay:GetFrameLevel()) or icon:GetFrameLevel()) + 2)
	if barFrame.body then
		barFrame.body:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.body:SetFrameLevel(barFrame:GetFrameLevel() + 1)
	end
	if barFrame.fill then barFrame.fill:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 1) end
	if barFrame.dividerOverlay then
		barFrame.dividerOverlay:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.dividerOverlay:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 2)
	end
	if barFrame.borderOverlay then
		barFrame.borderOverlay:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.borderOverlay:SetFrameLevel((barFrame.body and barFrame.body:GetFrameLevel() or barFrame:GetFrameLevel()) + 3)
	end
	if barFrame.iconOverlay then
		barFrame.iconOverlay:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.iconOverlay:SetFrameLevel(barFrame:GetFrameLevel() + 5)
	end
	if barFrame.iconHolder then
		barFrame.iconHolder:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.iconHolder:SetFrameLevel((barFrame.iconOverlay and barFrame.iconOverlay:GetFrameLevel()) or (barFrame:GetFrameLevel() + 5))
	end
	if barFrame.iconBorder then
		barFrame.iconBorder:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.iconBorder:SetFrameLevel(((barFrame.iconHolder and barFrame.iconHolder:GetFrameLevel()) or (barFrame:GetFrameLevel() + 5)) + 1)
	end
	if barFrame.textOverlay then
		barFrame.textOverlay:ClearAllPoints()
		barFrame.textOverlay:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", 0, 0)
		barFrame.textOverlay:SetPoint("BOTTOMRIGHT", barFrame.body, "BOTTOMRIGHT", 0, 0)
		barFrame.textOverlay:SetFrameStrata(barFrame:GetFrameStrata())
		barFrame.textOverlay:SetFrameLevel(barFrame:GetFrameLevel() + 6)
	end

	barFrame:SetSize(pixelSnap(frameWidth, effectiveScale), pixelSnap(frameHeight, effectiveScale))

	barFrame.body:ClearAllPoints()
	barFrame.body:SetPoint("TOPLEFT", barFrame, "TOPLEFT", bodyLeft, -bodyTop)
	barFrame.body:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", -bodyRight, bodyBottom)
	applyBackdropFrame(barFrame.body, "Interface\\Buttons\\WHITE8x8", 1)
	barFrame.body:SetBackdropColor(0, 0, 0, 0)
	barFrame.body:SetBackdropBorderColor(0, 0, 0, 0)
	barFrame.fillBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
	local borderOffset = pixelSnap(normalizeBarBorderOffset(state and state.borderOffset, Bars.DEFAULTS.barBorderOffset), effectiveScale)
	local fillInset = Bars.GetBarFillInset(borderSize, effectiveScale, bodyWidth, bodyHeight)
	barFrame.fill:ClearAllPoints()
	barFrame.fill:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", fillInset, -fillInset)
	barFrame.fill:SetPoint("BOTTOMRIGHT", barFrame.body, "BOTTOMRIGHT", -fillInset, fillInset)
	if barFrame.inactiveDurationFill then
		barFrame.inactiveDurationFill:ClearAllPoints()
		barFrame.inactiveDurationFill:SetPoint("TOPLEFT", barFrame.fill, "TOPLEFT", 0, 0)
		barFrame.inactiveDurationFill:SetPoint("BOTTOMRIGHT", barFrame.fill, "BOTTOMRIGHT", 0, 0)
		barFrame.inactiveDurationFill:SetTexture(fillTexturePath)
	end
	if barFrame.dividerOverlay then
		barFrame.dividerOverlay:ClearAllPoints()
		barFrame.dividerOverlay:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", 0, 0)
		barFrame.dividerOverlay:SetPoint("BOTTOMRIGHT", barFrame.body, "BOTTOMRIGHT", 0, 0)
	end
	if barFrame.borderOverlay then
		if borderSize > 0 then
			barFrame.borderOverlay:ClearAllPoints()
			barFrame.borderOverlay:SetPoint("TOPLEFT", barFrame.body, "TOPLEFT", -borderOffset, borderOffset)
			barFrame.borderOverlay:SetPoint("BOTTOMRIGHT", barFrame.body, "BOTTOMRIGHT", borderOffset, -borderOffset)
			applyBackdropFrame(barFrame.borderOverlay, borderTexturePath, borderSize)
			barFrame.borderOverlay:SetBackdropColor(0, 0, 0, 0)
			barFrame.borderOverlay:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
			barFrame.borderOverlay:Show()
		else
			barFrame.borderOverlay:Hide()
		end
	end

	if state.showIcon and state.texture then
		local iconOffsetX = pixelSnap(state.iconOffsetX or 0, effectiveScale)
		local iconOffsetY = pixelSnap(state.iconOffsetY or 0, effectiveScale)
		barFrame.iconHolder:ClearAllPoints()
		if iconPosition == BAR_ICON_POSITION_RIGHT then
			barFrame.iconHolder:SetPoint("RIGHT", barFrame, "RIGHT", pixelSnap(-outerPadding + iconOffsetX, effectiveScale), iconOffsetY)
		elseif iconPosition == BAR_ICON_POSITION_TOP then
			barFrame.iconHolder:SetPoint("TOP", barFrame, "TOP", iconOffsetX, pixelSnap(-outerPadding + iconOffsetY, effectiveScale))
		elseif iconPosition == BAR_ICON_POSITION_BOTTOM then
			barFrame.iconHolder:SetPoint("BOTTOM", barFrame, "BOTTOM", iconOffsetX, pixelSnap(outerPadding + iconOffsetY, effectiveScale))
		else
			barFrame.iconHolder:SetPoint("LEFT", barFrame, "LEFT", pixelSnap(outerPadding + iconOffsetX, effectiveScale), iconOffsetY)
		end
		barFrame.iconHolder:SetSize(iconSize, iconSize)
		barFrame.icon:ClearAllPoints()
		barFrame.icon:SetPoint("TOPLEFT", barFrame.iconHolder, "TOPLEFT", 0, 0)
		barFrame.icon:SetPoint("BOTTOMRIGHT", barFrame.iconHolder, "BOTTOMRIGHT", 0, 0)
		barFrame.icon:SetTexture(state.texture)
		barFrame.iconHolder:Show()
		barFrame.icon:Show()
		Bars.ApplyBarIconBorder(barFrame, borderEnabled == true, borderTexturePath, borderSize, borderOffset, borderColor)
	else
		if barFrame.iconBorder then barFrame.iconBorder:Hide() end
		if barFrame.iconHolder then barFrame.iconHolder:Hide() end
		barFrame.icon:Hide()
	end

	local labelDefaultFontPath, labelDefaultFontSize, labelDefaultFontStyle = Helper.GetCountFontDefaults(icon and icon:GetParent() or nil)
	local valueDefaultFontPath, valueDefaultFontSize, valueDefaultFontStyle = labelDefaultFontPath, labelDefaultFontSize, labelDefaultFontStyle
	if CooldownPanels.GetCooldownFontDefaults then
		valueDefaultFontPath, valueDefaultFontSize, valueDefaultFontStyle = CooldownPanels:GetCooldownFontDefaults(icon and icon:GetParent() or nil)
	end
	if useChargeSegments then
		if barFrame.inactiveDurationFill then barFrame.inactiveDurationFill:SetAlpha(0) end
		layoutChargeSegmentsIntoBar(
			barFrame,
			icon,
			state,
			segmentCount,
			gap,
			segmentDirection,
			segmentReverse,
			bodyWidth,
			bodyHeight,
			borderTexturePath,
			borderSize,
			borderOffset,
			borderColor,
			backgroundColor,
			fillTexturePath,
			fillColor,
			orientation,
			effectiveScale
		)
	elseif useStackSegments then
		if barFrame.inactiveDurationFill then barFrame.inactiveDurationFill:SetAlpha(0) end
		Bars.LayoutStackSegmentsIntoBar(
			barFrame,
			icon,
			state,
			stackSegmentCount,
			stackSeparatedOffset,
			orientation,
			bodyWidth,
			bodyHeight,
			borderTexturePath,
			borderSize,
			borderOffset,
			borderColor,
			backgroundColor,
			fillTexturePath,
			fillColor,
			orientation,
			effectiveScale
		)
	else
		Bars.HideChargeSegmentTracker(barFrame)
		hideUnusedBarSegments(barFrame, 1)
		barFrame._eqolSegmentCount = 0
		barFrame.fill:Show()
		barFrame.fillBg:Show()
		barFrame.fill:SetStatusBarColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4])
		if barFrame.inactiveDurationFill then
			barFrame.inactiveDurationFill:SetVertexColor(fillColor[1], fillColor[2], fillColor[3], 1)
			if state.hasInactiveDurationCondition == true and barFrame.inactiveDurationFill.SetAlphaFromBoolean then
				barFrame.inactiveDurationFill:SetAlphaFromBoolean(state.inactiveDurationCondition, 0, fillColor[4] or 1)
			else
				barFrame.inactiveDurationFill:SetAlpha(0)
			end
		end
		if state.mode == Bars.BAR_MODE.STACKS then
			local ufHelper = addon.Aura and addon.Aura.UFHelper
			if ufHelper and ufHelper.applyStatusBarReverseFill then ufHelper.applyStatusBarReverseFill(barFrame.fill, false) end
			Bars.SetStatusBarRangedValue(barFrame.fill, state.stackFillValue ~= nil and state.stackFillValue or 0, state.stackFillMax or max(1, state.stackMax or Bars.DEFAULTS.barStackMax))
		else
			local reverseFill = state.reverseFill == true
			local usesNativeReverseFill = false
			local ufHelper = addon.Aura and addon.Aura.UFHelper
			if ufHelper and ufHelper.applyStatusBarReverseFill then
				ufHelper.applyStatusBarReverseFill(barFrame.fill, reverseFill)
				usesNativeReverseFill = true
			elseif barFrame.fill.SetFillStyle then
				barFrame.fill:SetFillStyle(
					reverseFill and (Enum and Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Reverse or "REVERSE")
						or (Enum and Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Standard or "STANDARD")
				)
				usesNativeReverseFill = true
			elseif barFrame.fill.SetReverseFill then
				barFrame.fill:SetReverseFill(reverseFill)
				usesNativeReverseFill = true
			end
			local displayProgress = clamp(state.progress or 0, 0, 1)
			local timerDirection = state.timerDirection or cdp.BAR_STATUS_TIMER_DIRECTION_ELAPSED
			if reverseFill and usesNativeReverseFill ~= true then
				displayProgress = clamp(1 - displayProgress, 0, 1)
				timerDirection = getOppositeTimerDirection(timerDirection)
			end
			local timerCacheKey = nil
			if state.fillDurationObject ~= nil then
				timerCacheKey = table.concat({
					"barfill",
					tostring(state.entryKey or state.entryId or "nil"),
					tostring(state.mode or "nil"),
					tostring(timerDirection),
				}, ":")
			end
			if not setStatusBarTimerDuration(barFrame.fill, state.fillDurationObject, timerCacheKey, timerDirection) then
				barFrame.fill:SetMinMaxValues(0, 1)
				setStatusBarImmediateValue(barFrame.fill, displayProgress)
			end
		end
		if useStackDividers then
			Bars.LayoutStackDividers(
				barFrame,
				orientation,
				state.stackFillMax or state.stackMax,
				bodyWidth,
				bodyHeight,
				state.stackDividerColor,
				slotAnchor.GetEffectiveScale and slotAnchor:GetEffectiveScale() or nil,
				state.stackDividerThickness
			)
		else
			Bars.HideUnusedBarDividers(barFrame, 1)
		end
		Bars.ConfigureForwardHitHandle(barFrame.hitHandle, barFrame.body, icon and icon.layoutHandle or nil)
		Bars.ConfigureFreeMoveHandle(barFrame.hitHandle, barFrame, icon)
	end

	local textWidth = max(1, bodyWidth - 8)
	if state.showLabel and state.label then
		layoutBarTextElement(
			barFrame,
			orientation,
			textWidth,
			barFrame.label,
			state.label,
			"LABEL",
			state.labelFont,
			state.labelSize,
			state.labelStyle,
			state.labelColor,
			labelDefaultFontPath,
			labelDefaultFontSize,
			labelDefaultFontStyle,
			state.labelAnchor,
			state.labelOffsetX,
			state.labelOffsetY
		)
	else
		barFrame.label:Hide()
	end
	local valueRelativeFrame = nil
	if useChargeSegments and state.valueTextIsChargeDuration == true then
		valueRelativeFrame = barFrame._eqolChargeSegmentRefreshTextAnchor
		if valueRelativeFrame == nil and state.chargeDurationTextSegmentIndex then
			valueRelativeFrame = barFrame.segments and barFrame.segments[state.chargeDurationTextSegmentIndex] or nil
		end
	end
	if
		state.showValueText
		and state.valueTextIsChargeDuration == true
		and state.chargeDurationTextNative == true
		and state.chargeDurationTextObject
	then
		Bars.ApplyValueDurationTextBinding(
			barFrame,
			state,
			valueRelativeFrame,
			orientation,
			textWidth,
			state.valueFont,
			state.valueSize,
			state.valueStyle,
			state.valueColor,
			valueDefaultFontPath,
			valueDefaultFontSize,
			valueDefaultFontStyle,
			state.valueAnchor,
			state.valueOffsetX,
			state.valueOffsetY
		)
	elseif state.showValueText and state.valueText then
		Bars.ClearChargeDurationCountdown(barFrame)
		layoutBarTextElement(
			barFrame,
			orientation,
			textWidth,
			barFrame.value,
			state.valueText,
			"VALUE",
			state.valueFont,
			state.valueSize,
			state.valueStyle,
			state.valueColor,
			valueDefaultFontPath,
			valueDefaultFontSize,
			valueDefaultFontStyle,
			state.valueAnchor,
			state.valueOffsetX,
			state.valueOffsetY,
			valueRelativeFrame
		)
	else
		Bars.ClearChargeDurationCountdown(barFrame)
		barFrame.value:Hide()
	end
	if state.showStackText and state.stackDisplayText then
		layoutBarTextElement(
			barFrame,
			orientation,
			textWidth,
			barFrame.stackCount,
			state.stackDisplayText,
			"STACK",
			state.stackFont,
			state.stackSize,
			state.stackStyle,
			state.stackColor,
			labelDefaultFontPath,
			labelDefaultFontSize,
			labelDefaultFontStyle,
			state.stackAnchor,
			state.stackOffsetX,
			state.stackOffsetY
		)
	else
		barFrame.stackCount:Hide()
	end
	Bars.ConfigureBarValueTextUpdater(barFrame, state)
	barFrame:SetAlpha(icon:GetAlpha())
	barFrame._eqolBarState = state
	barFrame:Show()
end

refreshPanelContext = function(panelId)
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if not panel then return end
	if Helper.InvalidateFixedLayoutCache then Helper.InvalidateFixedLayoutCache(panel) end
	if CooldownPanels.RefreshPanelForCurrentEditContext then
		CooldownPanels:RefreshPanelForCurrentEditContext(panelId, true)
	else
		if CooldownPanels.RefreshPanel then CooldownPanels:RefreshPanel(panelId) end
		if CooldownPanels.IsEditorOpen and CooldownPanels:IsEditorOpen() and CooldownPanels.RefreshEditor then CooldownPanels:RefreshEditor() end
	end
end

local function updateStandaloneEntryDialogForBars(panelId, entryId)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	if not (panelId and entryId and CooldownPanels.GetLayoutEntryStandaloneMenuState) then return false end
	local state = CooldownPanels:GetLayoutEntryStandaloneMenuState(false)
	local activeDialog = state and state.dialog or nil
	if not (state and activeDialog and normalizeId(state.panelId) == panelId and normalizeId(state.entryId) == entryId) then return false end
	local _, entry = getBarEntry(panelId, entryId)
	local title = entry and CooldownPanels.GetEntryStandaloneTitle and CooldownPanels:GetEntryStandaloneTitle(entry) or nil
	if activeDialog.context and title then activeDialog.context.title = title end
	if activeDialog.Title and title then activeDialog.Title:SetText(title) end
	if activeDialog.UpdateSettings then activeDialog:UpdateSettings() end
	if activeDialog.UpdateButtons then activeDialog:UpdateButtons() end
	if activeDialog.Layout then activeDialog:Layout() end
	return true
end

local function isStandaloneDialogDragActive()
	if type(IsMouseButtonDown) ~= "function" then return false end
	return IsMouseButtonDown("LeftButton") == true
end

local function scheduleStandaloneEntryDialogUpdate(panelId, entryId)
	if not (panelId and entryId) then return end
	Bars._eqolPendingDialogRefresh = Bars._eqolPendingDialogRefresh or {}
	local key = tostring(panelId) .. ":" .. tostring(entryId)
	if Bars._eqolPendingDialogRefresh[key] then return end
	Bars._eqolPendingDialogRefresh[key] = true
	RunNextFrame(function()
		Bars._eqolPendingDialogRefresh[key] = nil
		if isStandaloneDialogDragActive() then
			scheduleStandaloneEntryDialogUpdate(panelId, entryId)
			return
		end
		updateStandaloneEntryDialogForBars(panelId, entryId)
	end)
end

refreshStandaloneEntryDialogForBars = function(panelId, entryId, reopen)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	if not (panelId and entryId and CooldownPanels.GetLayoutEntryStandaloneMenuState and CooldownPanels.HideLayoutEntryStandaloneMenu and CooldownPanels.OpenLayoutEntryStandaloneMenu) then return end
	local state = CooldownPanels:GetLayoutEntryStandaloneMenuState(false)
	if not state or normalizeId(state.panelId) ~= panelId or normalizeId(state.entryId) ~= entryId then return end
	if reopen ~= true then
		scheduleStandaloneEntryDialogUpdate(panelId, entryId)
		return
	end
	local anchorFrame = state.anchorFrame or state.dialog or state.hostFrame
	CooldownPanels:HideLayoutEntryStandaloneMenu(panelId, true)
	RunNextFrame(function()
		if CooldownPanels.IsPanelLayoutEditActive and not CooldownPanels:IsPanelLayoutEditActive(panelId) then return end
		CooldownPanels:OpenLayoutEntryStandaloneMenu(panelId, entryId, anchorFrame)
	end)
end

local function setEntryDisplayMode(panelId, entryId, displayMode, barMode)
	mutateBarEntry(panelId, entryId, function(entry)
		entry.displayMode = normalizeDisplayMode(displayMode, Bars.DEFAULTS.displayMode)
		if entry.displayMode == Bars.DISPLAY_MODE.BAR and barMode then entry.barMode = normalizeBarMode(barMode, entry.barMode or Bars.DEFAULTS.barMode) end
		if entry.displayMode == Bars.DISPLAY_MODE.BAR then
			Bars.ApplyNewBarStyleDefaults(entry)
			if type(entry.barColor) ~= "table" then entry.barColor = getDefaultBarColorForMode(entry.barMode) end
		end
	end, true)
end

local function setEntryBarMode(panelId, entryId, barMode)
	mutateBarEntry(panelId, entryId, function(entry)
		entry.displayMode = Bars.DISPLAY_MODE.BAR
		entry.barMode = normalizeBarMode(barMode, entry.barMode or Bars.DEFAULTS.barMode)
		Bars.ApplyNewBarStyleDefaults(entry)
		if type(entry.barColor) ~= "table" then entry.barColor = getDefaultBarColorForMode(entry.barMode) end
	end)
end

local function setEntryBarWidth(panelId, entryId, width)
	mutateBarEntry(panelId, entryId, function(entry) entry.barWidth = normalizeBarWidth(width, entry.barWidth or Bars.DEFAULTS.barWidth) end)
end

local function setEntryBarSpan(panelId, entryId, span)
	mutateBarEntry(panelId, entryId, function(entry, panel)
		entry.barSpan = normalizeBarSpan(span, entry.barSpan or Bars.DEFAULTS.barSpan)
		local slotSize = getEntryBaseSlotSize(panel, entry)
		local spacing = Helper.ClampInt(panel and panel.layout and panel.layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2)
		entry.barWidth = max(slotSize, (slotSize * entry.barSpan) + (max(entry.barSpan - 1, 0) * spacing))
	end)
end

local function toggleEntryBarFlag(panelId, entryId, field)
	mutateBarEntry(panelId, entryId, function(entry) entry[field] = entry[field] ~= true end)
end

local function setEntryBarBoolean(panelId, entryId, field, value)
	mutateBarEntry(panelId, entryId, function(entry) entry[field] = value == true end)
end

local function setEntryBarField(panelId, entryId, field, value)
	mutateBarEntry(panelId, entryId, function(entry, panel)
		if field == "cdmAuraAlwaysShowUseGlobal" then
			local wasUseGlobal = entry.cdmAuraAlwaysShowUseGlobal ~= false
			entry[field] = value
			if value == false then
				local mode = entry.cdmAuraAlwaysShowMode
				if wasUseGlobal then mode = panel and panel.layout and panel.layout.cdmAuraAlwaysShowMode or mode end
				mode = type(mode) == "string" and string.upper(mode) or nil
				if not (mode == "SHOW" or mode == "DESATURATE" or mode == "DESATURATE_ACTIVE" or mode == "HIDE" or mode == "HIDE_DESATURATE_ACTIVE") then mode = "HIDE" end
				entry.cdmAuraAlwaysShowMode = mode
				entry.alwaysShow = mode ~= "HIDE" and mode ~= "HIDE_DESATURATE_ACTIVE"
			end
		elseif field == "cdmAuraAlwaysShowMode" then
			local mode = type(value) == "string" and string.upper(value) or nil
			if not (mode == "SHOW" or mode == "DESATURATE" or mode == "DESATURATE_ACTIVE" or mode == "HIDE" or mode == "HIDE_DESATURATE_ACTIVE") then mode = "HIDE" end
			entry[field] = mode
			entry.alwaysShow = mode ~= "HIDE" and mode ~= "HIDE_DESATURATE_ACTIVE"
		else
			entry[field] = value
		end
	end)
end

Bars.SetTextAnchorWithFreshOffsets = function(panelId, entryId, anchorField, offsetXField, offsetYField, value, fallback)
	local normalized = Bars.NormalizeTextAnchor(value, fallback)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	mutateBarEntry(panelId, entryId, function(entry)
		entry[anchorField] = normalized
		entry[offsetXField] = 0
		entry[offsetYField] = 0
	end)
end

local function showBarModeMenu(owner, panelId, entryId)
	if not (owner and Api.MenuUtil and Api.MenuUtil.CreateContextMenu) then return end
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	local entry = panel and panel.entries and panel.entries[entryId] or nil
	if not entry then return end
	normalizeBarEntry(entry)

	Api.MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_COOLDOWN_PANEL_BAR_MODE")
		rootDescription:CreateTitle(getEntryLabel(entry) or (L["CooldownPanelBars"] or "Bars"))
		rootDescription:CreateButton(L["CooldownPanelSwitchToButton"] or "Switch to Button", function() setEntryDisplayMode(panelId, entryId, Bars.DISPLAY_MODE.BUTTON) end)
		rootDescription:CreateDivider()
		rootDescription:CreateTitle(L["Mode"] or "Mode")
		rootDescription:CreateRadio(
			getEntryBarModeLabel(Bars.BAR_MODE.COOLDOWN),
			function() return normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN end,
			function() setEntryBarMode(panelId, entryId, Bars.BAR_MODE.COOLDOWN) end
		)
		if supportsBarMode(entry, Bars.BAR_MODE.CHARGES) then
			rootDescription:CreateRadio(
				getEntryBarModeLabel(Bars.BAR_MODE.CHARGES),
				function() return normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES end,
				function() setEntryBarMode(panelId, entryId, Bars.BAR_MODE.CHARGES) end
			)
		end
		if supportsBarMode(entry, Bars.BAR_MODE.STACKS) then
			rootDescription:CreateRadio(
				getEntryBarModeLabel(Bars.BAR_MODE.STACKS),
				function() return normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS end,
				function() setEntryBarMode(panelId, entryId, Bars.BAR_MODE.STACKS) end
			)
		end
		rootDescription:CreateDivider()
		rootDescription:CreateTitle(L["CooldownPanelBarSpan"] or "Span")
		for span = 1, 4 do
			rootDescription:CreateRadio(
				format("%d %s", span, span == 1 and (L["CooldownPanelSlotType"] or "Slot"):lower() or (L["CooldownPanelSlotTypePlural"] or "Slots"):lower()),
				function() return normalizeBarSpan(entry.barSpan, Bars.DEFAULTS.barSpan) == span end,
				function() setEntryBarSpan(panelId, entryId, span) end
			)
		end
		rootDescription:CreateDivider()
		rootDescription:CreateCheckbox(L["Show icon"] or "Show icon", function() return entry.barShowIcon == true end, function() toggleEntryBarFlag(panelId, entryId, "barShowIcon") end)
		rootDescription:CreateCheckbox(
			L["CooldownPanelBarShowLabel"] or "Show label",
			function() return entry.barShowLabel == true end,
			function() toggleEntryBarFlag(panelId, entryId, "barShowLabel") end
		)
		rootDescription:CreateCheckbox(
			L["CooldownPanelBarShowValueText"] or "Show value",
			function() return entry.barShowValueText == true end,
			function() toggleEntryBarFlag(panelId, entryId, "barShowValueText") end
		)
		if normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES then
			rootDescription:CreateCheckbox(
				L["Show duration"] or "Show duration",
				function() return entry.barShowChargeDuration == true end,
				function() toggleEntryBarFlag(panelId, entryId, "barShowChargeDuration") end
			)
		end
	end)
end

local function configureModeButton(panelId, panel, icon, actualEntryId, mappedEntryId, slotColumn, slotRow)
	if icon and icon._eqolBarsModeButton then icon._eqolBarsModeButton:Hide() end
end

Bars.SuppressIconLayoutHandles = function(icon)
	if not icon then return end
	if icon.layoutHandle and icon.layoutHandle.EnableMouse then icon.layoutHandle:EnableMouse(false) end
	if icon.slotAnchorHandle and icon.slotAnchorHandle.EnableMouse then icon.slotAnchorHandle:EnableMouse(false) end
end

Bars.MarkActiveRuntimeBarIcon = function(runtime, icon, pass)
	if not (runtime and icon and pass) then return end
	runtime._eqolBarsActiveIcons = runtime._eqolBarsActiveIcons or {}
	runtime._eqolBarsActiveIconSet = runtime._eqolBarsActiveIconSet or {}
	icon._eqolBarsTouchedPass = pass
	if runtime._eqolBarsActiveIconSet[icon] == true then return end
	runtime._eqolBarsActiveIconSet[icon] = true
	runtime._eqolBarsActiveIcons[#runtime._eqolBarsActiveIcons + 1] = icon
end

Bars.CleanupStaleRuntimeBarIcons = function(runtime, pass)
	local activeIcons = runtime and runtime._eqolBarsActiveIcons or nil
	if not activeIcons then return end
	local activeIconSet = runtime._eqolBarsActiveIconSet
	for index = #activeIcons, 1, -1 do
		local icon = activeIcons[index]
		if not icon or not pass or icon._eqolBarsTouchedPass ~= pass then
			if icon then
				hideBarPresentation(icon)
				icon._eqolBarsTouchedPass = nil
				if activeIconSet then activeIconSet[icon] = nil end
			end
			activeIcons[index] = activeIcons[#activeIcons]
			activeIcons[#activeIcons] = nil
		end
	end
end

local function applyBarsToPanel(panelId, preview)
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if not panel then return end
	local sharedRuntime = CooldownPanels.runtime
	local runtime = sharedRuntime and sharedRuntime[panelId] or nil
	local frame = runtime and runtime.frame or nil
	if not frame or not frame.icons then return end

	local layoutEditActive = CooldownPanels.IsPanelLayoutEditActive and CooldownPanels:IsPanelLayoutEditActive(panelId) or false
	local effectivePreview = preview == true or layoutEditActive == true
	local barEntryIdsByPanel = sharedRuntime and sharedRuntime.barEntryIdsByPanel or nil
	local barEntryIds = barEntryIdsByPanel and barEntryIdsByPanel[panelId] or nil
	if not effectivePreview and barEntryIdsByPanel and (not barEntryIds or #barEntryIds == 0) then
		Bars.CleanupStaleRuntimeBarIcons(runtime, nil)
		return
	end

	panel.layout = panel.layout or {}
	local fixedLayout = Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) or false
	local cache = fixedLayout and Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil
	local entries = panel.entries or nil
	local boundsColumns = fixedLayout and cache and cache.boundsColumns or 0
	local reservedOwnerByIndex = layoutEditActive and fixedLayout and cache and cache._eqolBarsReservedOwnerByIndex or nil
	local anchorCellByEntryId = fixedLayout and cache and cache._eqolBarsAnchorCellByEntryId or nil
	local effectiveSpanByEntryId = fixedLayout and cache and cache._eqolBarsEffectiveSpanByEntryId or nil

	if not effectivePreview and barEntryIds and runtime.entryToIcon then
		local pass = (runtime._eqolBarsApplyPass or 0) + 1
		runtime._eqolBarsApplyPass = pass
		for index = 1, #barEntryIds do
			local entryId = normalizeId(barEntryIds[index])
			local icon = entryId and runtime.entryToIcon[entryId] or nil
			if icon then
				Bars.MarkActiveRuntimeBarIcon(runtime, icon, pass)
				local slotColumn = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellColumn or icon._eqolLayoutSlotColumn)
				local slotRow = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellRow or icon._eqolLayoutSlotRow)
				local entry = entries and entries[entryId] or nil
				local displayMode = entry and normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) or Bars.DISPLAY_MODE.BUTTON
				local anchorCell = entryId and anchorCellByEntryId and anchorCellByEntryId[entryId] or nil
				local showBar = entry and displayMode == Bars.DISPLAY_MODE.BAR and fixedLayout and anchorCell ~= nil and anchorCell.column == slotColumn and anchorCell.row == slotRow
				local barFrame = icon._eqolBarsFrame

				if showBar then
					icon._eqolBarsReservedOwnerId = nil
					icon._eqolBarsReservedSlot = nil
					if not barFrame then barFrame = ensureBarFrame(icon) end
					local state = buildBarState(panelId, entryId, entry, icon, effectivePreview, icon._eqolRuntimeData)
					local span = entryId and effectiveSpanByEntryId and effectiveSpanByEntryId[entryId] or 1
					applyNativeSuppression(icon)
					if state then
						if state.visible == true then
							layoutBarFrame(barFrame, icon, span, panel.layout, state)
							stopBarAnimation(barFrame)
						else
							hideBarPresentation(icon)
						end
					else
						hideBarPresentation(icon)
					end
				else
					Bars.RestoreNativeIconOverlay(icon)
					if barFrame and barFrame.IsShown and barFrame:IsShown() then
						hideBarPresentation(icon)
					elseif icon._eqolBarsReservedSlot or icon._eqolBarsReservedOwnerId then
						hideBarPresentation(icon)
					else
						icon._eqolBarsReservedOwnerId = nil
						icon._eqolBarsReservedSlot = nil
					end
					if icon and icon.staticText and icon._eqolBarsReservedSlot then icon.staticText:Hide() end
				end
			end
		end
		Bars.CleanupStaleRuntimeBarIcons(runtime, pass)
		return
	end

	for _, icon in ipairs(frame.icons) do
		local entryId = normalizeId(icon.entryId)
		local slotColumn = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellColumn or icon._eqolLayoutSlotColumn)
		local slotRow = Helper.NormalizeSlotCoordinate(icon._eqolPreviewCellRow or icon._eqolLayoutSlotRow)
		local entry = entryId and entries and entries[entryId] or nil
		local displayMode = entry and normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) or Bars.DISPLAY_MODE.BUTTON
		local reservedOwnerId = nil
		if reservedOwnerByIndex and boundsColumns > 0 and not entryId and slotColumn and slotRow then reservedOwnerId = reservedOwnerByIndex[((slotRow - 1) * boundsColumns) + slotColumn] end
		local reservedEntry = reservedOwnerId and entries and entries[reservedOwnerId] or nil
		local anchorCell = entryId and anchorCellByEntryId and anchorCellByEntryId[entryId] or nil
		local showBar = entry and displayMode == Bars.DISPLAY_MODE.BAR and fixedLayout and anchorCell ~= nil and anchorCell.column == slotColumn and anchorCell.row == slotRow
		local showReservedGhost = layoutEditActive and fixedLayout and not entry and reservedOwnerId and reservedEntry
		local barFrame = icon._eqolBarsFrame

		if showBar then
			icon._eqolBarsReservedOwnerId = nil
			icon._eqolBarsReservedSlot = nil
			if not barFrame then barFrame = ensureBarFrame(icon) end
			local state = buildBarState(panelId, entryId, entry, icon, effectivePreview, icon._eqolRuntimeData)
			local span = entryId and effectiveSpanByEntryId and effectiveSpanByEntryId[entryId] or 1
			applyNativeSuppression(icon)
			if state then
				if state.visible == true then
					layoutBarFrame(barFrame, icon, span, panel.layout, state)
					stopBarAnimation(barFrame)
				else
					hideBarPresentation(icon)
				end
			else
				hideBarPresentation(icon)
			end
		elseif showReservedGhost then
			hideBarPresentation(icon)
			applyReservedGhost(icon, reservedEntry, slotColumn, slotRow)
		else
			Bars.RestoreNativeIconOverlay(icon)
			if barFrame and barFrame.IsShown and barFrame:IsShown() then
				hideBarPresentation(icon)
			elseif icon._eqolBarsReservedSlot or icon._eqolBarsReservedOwnerId then
				hideBarPresentation(icon)
			else
				icon._eqolBarsReservedOwnerId = nil
				icon._eqolBarsReservedSlot = nil
			end
			if icon and icon.staticText and icon._eqolBarsReservedSlot then icon.staticText:Hide() end
		end
	end
end

local originalCreateEntry = Helper.CreateEntry
Helper.CreateEntry = function(entryType, idValue, defaults)
	local entry = originalCreateEntry(entryType, idValue, defaults)
	normalizeBarEntry(entry)
	return entry
end

local originalNormalizeEntry = Helper.NormalizeEntry
Helper.NormalizeEntry = function(entry, defaults)
	originalNormalizeEntry(entry, defaults)
	normalizeBarEntry(entry)
end

local originalGetFixedLayoutCache = Helper.GetFixedLayoutCache
if originalGetFixedLayoutCache then Helper.GetFixedLayoutCache = function(panel) return augmentFixedLayoutCache(panel, originalGetFixedLayoutCache(panel)) end end

Bars._eqolOriginalInvalidateFixedLayoutCache = Bars._eqolOriginalInvalidateFixedLayoutCache or Helper.InvalidateFixedLayoutCache
if Bars._eqolOriginalInvalidateFixedLayoutCache then
	Helper.InvalidateFixedLayoutCache = function(panel, ...)
		Bars.MarkReservationCacheDirty(panel)
		return Bars._eqolOriginalInvalidateFixedLayoutCache(panel, ...)
	end
end

local originalBuildFixedSlotEntryIds = Helper.BuildFixedSlotEntryIds
if originalBuildFixedSlotEntryIds then
	Helper.BuildFixedSlotEntryIds = function(panel, filterFn, includePreviewPadding)
		local slotEntryIds, count, columns, rows = originalBuildFixedSlotEntryIds(panel, filterFn, includePreviewPadding)
		if panel and filterFn == nil and includePreviewPadding ~= true then
			local cache = originalGetFixedLayoutCache and originalGetFixedLayoutCache(panel) or nil
			augmentFixedLayoutCache(panel, cache)
		end
		return slotEntryIds, count, columns, rows
	end
end

local originalGetEntryAtUngroupedFixedCell = CooldownPanels.GetEntryAtUngroupedFixedCell
function CooldownPanels:GetEntryAtUngroupedFixedCell(panel, column, row, skipEntryId)
	local ownerId, ownerEntry = getReservedOwnerForCell(panel, column, row, skipEntryId)
	if ownerId then return ownerId, ownerEntry end
	return originalGetEntryAtUngroupedFixedCell(self, panel, column, row, skipEntryId)
end

local originalGetEntryAtStaticGroupCell = CooldownPanels.GetEntryAtStaticGroupCell
function CooldownPanels:GetEntryAtStaticGroupCell(panel, groupId, column, row, skipEntryId)
	local ownerId, ownerEntry = getReservedOwnerForCell(panel, column, row, skipEntryId)
	if ownerId then
		local ownerGroupId = ownerEntry and Helper.NormalizeFixedGroupId(ownerEntry.fixedGroupId) or nil
		if ownerGroupId == Helper.NormalizeFixedGroupId(groupId) then return ownerId, ownerEntry end
	end
	return originalGetEntryAtStaticGroupCell(self, panel, groupId, column, row, skipEntryId)
end

local originalUpdatePreviewIcons = CooldownPanels.UpdatePreviewIcons
function CooldownPanels:UpdatePreviewIcons(panelId, countOverride)
	originalUpdatePreviewIcons(self, panelId, countOverride)
	applyBarsToPanel(panelId, true)
end

local originalUpdateRuntimeIcons = CooldownPanels.UpdateRuntimeIcons
function CooldownPanels:UpdateRuntimeIcons(panelId)
	originalUpdateRuntimeIcons(self, panelId)
	applyBarsToPanel(panelId, false)
end

local originalConfigureEditModePanelIcon = CooldownPanels.ConfigureEditModePanelIcon
function CooldownPanels:ConfigureEditModePanelIcon(panelId, icon, entryId, slotColumn, slotRow)
	local panel = self.GetPanel and self:GetPanel(panelId) or nil
	local fixedLayout = panel and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) or false
	local cache = fixedLayout and Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil
	local mappedEntryId = normalizeId(entryId)
	local reservedOwnerId = nil
	local reservedEntry = nil
	if mappedEntryId == nil and fixedLayout then
		reservedOwnerId = select(1, getReservedOwnerForCell(panel, slotColumn, slotRow, nil, cache))
		if reservedOwnerId then
			reservedEntry = panel and panel.entries and panel.entries[reservedOwnerId] or nil
			mappedEntryId = reservedOwnerId
			icon._eqolBarsReservedOwnerId = reservedOwnerId
			icon._eqolBarsReservedSlot = true
		else
			icon._eqolBarsReservedOwnerId = nil
			icon._eqolBarsReservedSlot = nil
		end
	else
		icon._eqolBarsReservedOwnerId = nil
		icon._eqolBarsReservedSlot = nil
	end
	originalConfigureEditModePanelIcon(self, panelId, icon, mappedEntryId, slotColumn, slotRow)
	local mappedEntry = mappedEntryId and panel and panel.entries and panel.entries[mappedEntryId] or nil
	if
		fixedLayout
		and mappedEntry
		and normalizeDisplayMode(mappedEntry.displayMode, Bars.DEFAULTS.displayMode) == Bars.DISPLAY_MODE.BAR
		and isAnchorCell(panel, mappedEntryId, slotColumn, slotRow, cache)
	then
		Bars.SuppressIconLayoutHandles(icon)
	elseif fixedLayout and normalizeId(entryId) == nil and reservedOwnerId and reservedEntry then
		Bars.SuppressIconLayoutHandles(icon)
	end
	configureModeButton(panelId, panel, icon, normalizeId(entryId), mappedEntryId, slotColumn, slotRow)
	configureBarDragPreview(panelId, panel, icon, normalizeId(entryId), slotColumn, slotRow, cache)
end

local function normalizeCDMAuraAlwaysShowModeValue(value, fallback)
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == "SHOW" or mode == "DESATURATE" or mode == "DESATURATE_ACTIVE" or mode == "HIDE" or mode == "HIDE_DESATURATE_ACTIVE" then return mode end
	return fallback or "HIDE"
end

local function getStandaloneBarEntry(panelId, entryId)
	local panel, entry = getBarEntry(panelId, entryId)
	if entry then normalizeBarEntry(entry) end
	return panel, entry
end

local function getStandaloneBarFontValue(value)
	if CooldownPanels.GetFontDropdownValue then return CooldownPanels:GetFontDropdownValue(value) end
	if hasTextValue(value) then return value end
	if CooldownPanels.GetGlobalFontConfigKey then return CooldownPanels:GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function getStandaloneBarVisibility(panelId, entryId, field)
	local panel, entry = getStandaloneBarEntry(panelId, entryId)
	local layout = panel and panel.layout or nil
	if entry and entry.cooldownVisibilityUseGlobal == false then return entry[field] == true end
	return layout and layout[field] == true or false
end

local function getStandaloneBarCDMAuraMode(panelId, entryId)
	local panel, entry = getStandaloneBarEntry(panelId, entryId)
	local layout = panel and panel.layout or nil
	local fallback = layout and layout.cdmAuraAlwaysShowMode or "HIDE"
	if entry and entry.cdmAuraAlwaysShowUseGlobal == false then return normalizeCDMAuraAlwaysShowModeValue(entry.cdmAuraAlwaysShowMode, fallback) end
	return normalizeCDMAuraAlwaysShowModeValue(fallback, "HIDE")
end

local function createBarStandaloneSettingsContext(panelId, entryId)
	local SettingType = getSettingType()
	local panel, entry = getStandaloneBarEntry(panelId, entryId)
	if not (SettingType and panel and entry) then return nil end

	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[normalizeId(panelId)] or nil
	local hostFrame = runtime and runtime.frame or nil
	local labelDefaultFontPath, labelDefaultFontSize, labelDefaultFontStyle = Helper.GetCountFontDefaults(hostFrame)
	local valueDefaultFontPath, valueDefaultFontSize, valueDefaultFontStyle = labelDefaultFontPath, labelDefaultFontSize, labelDefaultFontStyle
	if CooldownPanels.GetCooldownFontDefaults then
		valueDefaultFontPath, valueDefaultFontSize, valueDefaultFontStyle = CooldownPanels:GetCooldownFontDefaults(hostFrame)
	end

	return {
		panelId = panelId,
		entryId = entryId,
		SettingType = SettingType,
		labelDefaultFontPath = labelDefaultFontPath,
		labelDefaultFontSize = labelDefaultFontSize,
		labelDefaultFontStyle = labelDefaultFontStyle,
		valueDefaultFontPath = valueDefaultFontPath,
		valueDefaultFontSize = valueDefaultFontSize,
		valueDefaultFontStyle = valueDefaultFontStyle,
	}
end

local function getStandaloneBarContextPanelEntry(ctx) return getStandaloneBarEntry(ctx.panelId, ctx.entryId) end

local function getStandaloneBarContextEntry(ctx)
	local _, entry = getStandaloneBarContextPanelEntry(ctx)
	return entry
end

local function appendBarStandaloneAppearanceSettings(settings, ctx)
	local panelId = ctx.panelId
	local entryId = ctx.entryId
	local SettingType = ctx.SettingType

	settings[#settings + 1] = {
		name = L["Display"] or "Display",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBar",
		defaultCollapsed = false,
	}
	settings[#settings + 1] = {
		name = L["Layout"] or "Layout",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarLayout",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["Icon"] or "Icon",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarIcon",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelFillHeader"] or "Fill",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarFill",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["Mode"] or "Mode",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBar",
		height = 140,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode)
		end,
		set = function(_, value) setEntryBarMode(panelId, entryId, value) end,
		generator = function(_, root)
			local currentEntry = getStandaloneBarContextEntry(ctx)
			if not currentEntry then return end
			for _, option in ipairs({
				{ value = Bars.BAR_MODE.COOLDOWN, label = getEntryBarModeLabel(Bars.BAR_MODE.COOLDOWN) },
				{ value = Bars.BAR_MODE.CHARGES, label = getEntryBarModeLabel(Bars.BAR_MODE.CHARGES) },
				{ value = Bars.BAR_MODE.STACKS, label = getEntryBarModeLabel(Bars.BAR_MODE.STACKS) },
			}) do
				if supportsBarMode(currentEntry, option.value) then
					root:CreateRadio(option.label, function()
						local refreshedEntry = getStandaloneBarContextEntry(ctx)
						return normalizeBarMode(refreshedEntry and refreshedEntry.barMode, Bars.DEFAULTS.barMode) == option.value
					end, function() setEntryBarMode(panelId, entryId, option.value) end)
				end
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["Bar width"] or "Bar width",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLayout",
		minValue = BAR_WIDTH_MIN,
		maxValue = BAR_WIDTH_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local panelRef, entryRef = getStandaloneBarContextPanelEntry(ctx)
			local configuredWidth = normalizeBarWidth(entryRef and entryRef.barWidth, Bars.DEFAULTS.barWidth)
			if configuredWidth > 0 then return configuredWidth end
			local slotSize = getEntryBaseSlotSize(panelRef, entryRef)
			local spacing =
				Helper.ClampInt(panelRef and panelRef.layout and panelRef.layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS and Helper.PANEL_LAYOUT_DEFAULTS.spacing or 2)
			local span = normalizeBarSpan(entryRef and entryRef.barSpan, Bars.DEFAULTS.barSpan)
			return max(slotSize, (slotSize * span) + (max(span - 1, 0) * spacing))
		end,
		set = function(_, value) setEntryBarWidth(panelId, entryId, value) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_WIDTH_MIN, BAR_WIDTH_MAX, BAR_WIDTH_MIN)) end,
	}
	settings[#settings + 1] = {
		name = L["Bar height"] or "Bar height",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLayout",
		minValue = BAR_HEIGHT_MIN,
		maxValue = BAR_HEIGHT_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarHeight(currentEntry and currentEntry.barHeight, Bars.DEFAULTS.barHeight)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barHeight", Helper.ClampInt(value, BAR_HEIGHT_MIN, BAR_HEIGHT_MAX, Bars.DEFAULTS.barHeight)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_HEIGHT_MIN, BAR_HEIGHT_MAX, Bars.DEFAULTS.barHeight)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarOrientation"] or "Bar orientation",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarLayout",
		height = 120,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOrientation(currentEntry and currentEntry.barOrientation, Bars.DEFAULTS.barOrientation)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barOrientation", normalizeBarOrientation(value, Bars.DEFAULTS.barOrientation)) end,
		generator = function(_, root)
			for _, option in ipairs({
				{ value = BAR_ORIENTATION_HORIZONTAL, label = L["Horizontal"] or "Horizontal" },
				{ value = BAR_ORIENTATION_VERTICAL, label = L["Vertical"] or "Vertical" },
			}) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarOrientation(currentEntry and currentEntry.barOrientation, Bars.DEFAULTS.barOrientation) == option.value
				end, function() setEntryBarField(panelId, entryId, "barOrientation", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarOffsetX"] or "Bar X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLayout",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barOffsetX, Bars.DEFAULTS.barOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barOffsetX", normalizeBarOffset(value, Bars.DEFAULTS.barOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarOffsetY"] or "Bar Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLayout",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barOffsetY, Bars.DEFAULTS.barOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barOffsetY", normalizeBarOffset(value, Bars.DEFAULTS.barOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["Bar texture"] or "Bar texture",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarFill",
		height = BAR_TEXTURE_MENU_HEIGHT,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getBarTextureSelection(currentEntry)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barTexture", value) end,
		generator = function(_, root)
			for _, option in ipairs(getBarTextureOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return getBarTextureSelection(currentEntry) == option.value
				end, function() setEntryBarField(panelId, entryId, "barTexture", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["Bar color"] or "Bar color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarFill",
		hasOpacity = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = getBarModeColor(currentEntry, normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode))
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value)
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local fallback = getDefaultBarColorForMode(normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode))
			setEntryBarField(panelId, entryId, "barColor", Helper.NormalizeColor(value, fallback))
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarProcGlowColor"] or "Proc glow color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarFill",
		hasOpacity = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barProcGlowColor, Bars.DEFAULTS.barProcGlowColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barProcGlowColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barProcGlowColor)) end,
	}
	settings[#settings + 1] = {
		name = L["Background color"] or "Background color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarFill",
		hasOpacity = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barBackgroundColor, Bars.DEFAULTS.barBackgroundColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barBackgroundColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barBackgroundColor)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarChargesSegmented"] or "Segment charges",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barChargesSegmented", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelSegmentSpacing"] or "Segment spacing",
		tooltip = L["CooldownPanelSegmentSpacingTooltip"],
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		minValue = BAR_CHARGES_GAP_MIN,
		maxValue = BAR_CHARGES_GAP_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarChargesGap(currentEntry and currentEntry.barChargesGap, Bars.DEFAULTS.barChargesGap)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barChargesGap", normalizeBarChargesGap(value, Bars.DEFAULTS.barChargesGap)) end,
		formatter = function(value) return tostring(normalizeBarChargesGap(value, Bars.DEFAULTS.barChargesGap)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarSegmentDirection"] or "Segment direction",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		height = 120,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarSegmentDirection(currentEntry and currentEntry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barSegmentDirection", normalizeBarSegmentDirection(value, Bars.DEFAULTS.barSegmentDirection)) end,
		generator = function(_, root)
			for _, option in ipairs({
				{ value = BAR_ORIENTATION_HORIZONTAL, label = L["Horizontal"] or "Horizontal" },
				{ value = BAR_ORIENTATION_VERTICAL, label = L["Vertical"] or "Vertical" },
			}) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarSegmentDirection(currentEntry and currentEntry.barSegmentDirection, Bars.DEFAULTS.barSegmentDirection) == option.value
				end, function() setEntryBarField(panelId, entryId, "barSegmentDirection", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarSegmentReverse"] or "Reverse segment order",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barChargesSegmented", Bars.DEFAULTS.barChargesSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barSegmentReverse", Bars.DEFAULTS.barSegmentReverse)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barSegmentReverse", value) end,
	}
end

Bars.IsStandaloneBarBorderDisabled = function(ctx)
	local currentEntry = getStandaloneBarContextEntry(ctx)
	return not getStoredBoolean(currentEntry, "barBorderEnabled", Bars.DEFAULTS.barBorderEnabled)
end

Bars.GetBarTextAnchorOptions = function()
	return {
		{ value = Bars.TEXT_ANCHOR.AUTO, label = L["Auto"] or "Auto" },
		{ value = Bars.TEXT_ANCHOR.LEFT, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_LEFT },
		{ value = Bars.TEXT_ANCHOR.RIGHT, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_RIGHT },
		{ value = Bars.TEXT_ANCHOR.CENTER, label = L["Center"] or "Center" },
		{ value = Bars.TEXT_ANCHOR.TOP, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_TOP },
		{ value = Bars.TEXT_ANCHOR.BOTTOM, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_BOTTOM },
	}
end

Bars.AppendBarStandaloneDetailHeaders = function(settings, ctx)
	local SettingType = ctx.SettingType
	settings[#settings + 1] = {
		name = L["Charges"] or "Charges",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarCharges",
		defaultCollapsed = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
	}
	settings[#settings + 1] = {
		name = L["Cooldown"] or (L["Cooldown"] or "Cooldown"),
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarCooldown",
		defaultCollapsed = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
	}
	settings[#settings + 1] = {
		name = L["Stacks"] or (L["Stacks"] or "Stacks"),
		kind = SettingType.Collapsible,
		id = Bars.STANDALONE_STACKS_SECTION_ID,
		defaultCollapsed = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local mode = normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode)
			return supportsBarMode(currentEntry, Bars.BAR_MODE.STACKS) and mode ~= Bars.BAR_MODE.CHARGES
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelHeader"] or "Label",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarLabel",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelValueTextHeader"] or "Value Text",
		tooltip = L["CooldownPanelValueTextHeaderTooltip"],
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarValueText",
		defaultCollapsed = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
	}
end

Bars.AppendBarStandaloneBorderSettings = function(settings, ctx)
	local panelId = ctx.panelId
	local entryId = ctx.entryId
	local SettingType = ctx.SettingType

	settings[#settings + 1] = {
		name = L["Border"] or "Border",
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarBorder",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarBorderEnabled"] or "Enable border",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarBorder",
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barBorderEnabled", Bars.DEFAULTS.barBorderEnabled)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barBorderEnabled", value) end,
	}
	settings[#settings + 1] = {
		name = L["Border size"] or "Border size",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarBorder",
		minValue = BAR_BORDER_SIZE_MIN,
		maxValue = BAR_BORDER_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function() return Bars.IsStandaloneBarBorderDisabled(ctx) end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarBorderSize(currentEntry and currentEntry.barBorderSize, Bars.DEFAULTS.barBorderSize)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barBorderSize", Helper.ClampInt(value, BAR_BORDER_SIZE_MIN, BAR_BORDER_SIZE_MAX, Bars.DEFAULTS.barBorderSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_BORDER_SIZE_MIN, BAR_BORDER_SIZE_MAX, Bars.DEFAULTS.barBorderSize)) end,
	}
	settings[#settings + 1] = {
		name = L["Border offset"] or (L["Border offset"] or "Border offset"),
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarBorder",
		minValue = BAR_BORDER_OFFSET_MIN,
		maxValue = BAR_BORDER_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function() return Bars.IsStandaloneBarBorderDisabled(ctx) end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarBorderOffset(currentEntry and currentEntry.barBorderOffset, Bars.DEFAULTS.barBorderOffset)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barBorderOffset", normalizeBarBorderOffset(value, Bars.DEFAULTS.barBorderOffset)) end,
		formatter = function(value) return tostring(normalizeBarBorderOffset(value, Bars.DEFAULTS.barBorderOffset)) end,
	}
	settings[#settings + 1] = {
		name = L["Border texture"] or "Border texture",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarBorder",
		height = BAR_TEXTURE_MENU_HEIGHT,
		disabled = function() return Bars.IsStandaloneBarBorderDisabled(ctx) end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarBorderTexture(currentEntry and currentEntry.barBorderTexture, Bars.DEFAULTS.barBorderTexture)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barBorderTexture", value) end,
		generator = function(_, root)
			for _, option in ipairs(getBarBorderTextureOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarBorderTexture(currentEntry and currentEntry.barBorderTexture, Bars.DEFAULTS.barBorderTexture) == option.value
				end, function() setEntryBarField(panelId, entryId, "barBorderTexture", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = EMBLEM_BORDER_COLOR,
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarBorder",
		hasOpacity = true,
		disabled = function() return Bars.IsStandaloneBarBorderDisabled(ctx) end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barBorderColor, Bars.DEFAULTS.barBorderColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barBorderColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barBorderColor)) end,
	}
end

Bars.ShouldShowBarValueTextSettings = function(entry)
	if type(entry) ~= "table" then return false end
	local mode = normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode)
	if mode == Bars.BAR_MODE.CHARGES then
		return getStoredBoolean(entry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
			or getStoredBoolean(entry, "barShowChargeDuration", Bars.DEFAULTS.barShowChargeDuration)
	end
	return getStoredBoolean(entry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
end

local function appendBarStandaloneTextSettings(settings, ctx)
	local panelId = ctx.panelId
	local entryId = ctx.entryId
	local SettingType = ctx.SettingType
	local labelDefaultFontPath = ctx.labelDefaultFontPath
	local labelDefaultFontSize = ctx.labelDefaultFontSize
	local labelDefaultFontStyle = ctx.labelDefaultFontStyle
	local valueDefaultFontPath = ctx.valueDefaultFontPath
	local valueDefaultFontSize = ctx.valueDefaultFontSize
	local valueDefaultFontStyle = ctx.valueDefaultFontStyle

	settings[#settings + 1] = {
		name = L["Show icon"] or "Show icon",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarIcon",
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowIcon", value) end,
	}
	settings[#settings + 1] = {
		name = L["Icon size"] or (L["Icon size"] or "Icon size"),
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarIcon",
		minValue = BAR_ICON_SIZE_MIN,
		maxValue = BAR_ICON_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local configuredSize = normalizeBarIconSize(currentEntry and currentEntry.barIconSize, Bars.DEFAULTS.barIconSize)
			if configuredSize > 0 then return configuredSize end
			return Bars.DEFAULTS.barIconSize
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barIconSize", normalizeBarIconSize(value, Bars.DEFAULTS.barIconSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_ICON_SIZE_MIN, BAR_ICON_SIZE_MAX, BAR_ICON_SIZE_MIN)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarIconPosition"] or "Icon position",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarIcon",
		height = 120,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarIconPosition(currentEntry and currentEntry.barIconPosition, Bars.DEFAULTS.barIconPosition)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barIconPosition", normalizeBarIconPosition(value, Bars.DEFAULTS.barIconPosition)) end,
		generator = function(_, root)
			for _, option in ipairs({
				{ value = BAR_ICON_POSITION_LEFT, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_LEFT },
				{ value = BAR_ICON_POSITION_RIGHT, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_RIGHT },
				{ value = BAR_ICON_POSITION_TOP, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_TOP },
				{ value = BAR_ICON_POSITION_BOTTOM, label = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_BOTTOM },
			}) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarIconPosition(currentEntry and currentEntry.barIconPosition, Bars.DEFAULTS.barIconPosition) == option.value
				end, function() setEntryBarField(panelId, entryId, "barIconPosition", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["Icon X"] or "Icon X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarIcon",
		minValue = -(Helper.OFFSET_RANGE or 500),
		maxValue = Helper.OFFSET_RANGE or 500,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarIconOffset(currentEntry and currentEntry.barIconOffsetX, Bars.DEFAULTS.barIconOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barIconOffsetX", normalizeBarIconOffset(value, Bars.DEFAULTS.barIconOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarIconOffset(value, Bars.DEFAULTS.barIconOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["Icon Y"] or "Icon Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarIcon",
		minValue = -(Helper.OFFSET_RANGE or 500),
		maxValue = Helper.OFFSET_RANGE or 500,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barShowIcon", Bars.DEFAULTS.barShowIcon)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarIconOffset(currentEntry and currentEntry.barIconOffsetY, Bars.DEFAULTS.barIconOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barIconOffsetY", normalizeBarIconOffset(value, Bars.DEFAULTS.barIconOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarIconOffset(value, Bars.DEFAULTS.barIconOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarShowLabel"] or "Show label",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowLabel", Bars.DEFAULTS.barShowLabel)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowLabel", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelAnchor"] or "Label anchor",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		height = 160,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barLabelAnchor, Bars.DEFAULTS.barLabelAnchor)
		end,
		set = function(_, value) Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barLabelAnchor", "barLabelOffsetX", "barLabelOffsetY", value, Bars.DEFAULTS.barLabelAnchor) end,
		generator = function(_, root)
			for _, option in ipairs(Bars.GetBarTextAnchorOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barLabelAnchor, Bars.DEFAULTS.barLabelAnchor) == option.value
				end, function() Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barLabelAnchor", "barLabelOffsetX", "barLabelOffsetY", option.value, Bars.DEFAULTS.barLabelAnchor) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelOffsetX"] or "Label X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barLabelOffsetX, Bars.DEFAULTS.barLabelOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelOffsetX", normalizeBarOffset(value, Bars.DEFAULTS.barLabelOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barLabelOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelOffsetY"] or "Label Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barLabelOffsetY, Bars.DEFAULTS.barLabelOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelOffsetY", normalizeBarOffset(value, Bars.DEFAULTS.barLabelOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barLabelOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarShowValueText"] or "Show value",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowValueText", value) end,
	}
	settings[#settings + 1] = {
		name = L["Show duration"] or "Show duration",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowChargeDuration", Bars.DEFAULTS.barShowChargeDuration)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowChargeDuration", value) end,
	}
	settings[#settings + 1] = {
		name = L["durationTextProfile"] or "Duration text profile",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarCharges",
		height = 140,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return currentEntry and currentEntry.barDurationTextProfile ~= nil and Bars.NormalizeDurationTextProfile(currentEntry.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile) or "PANEL_DEFAULT"
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barDurationTextProfile", value == "PANEL_DEFAULT" and nil or Bars.NormalizeDurationTextProfile(value, Bars.DEFAULTS.barDurationTextProfile)) end,
		generator = function(_, root)
			root:CreateRadio(L["durationTextProfilePanelDefault"] or "Panel default", function()
				local currentEntry = getStandaloneBarContextEntry(ctx)
				return not currentEntry or currentEntry.barDurationTextProfile == nil
			end, function() setEntryBarField(panelId, entryId, "barDurationTextProfile", nil) end)
			local durationText = addon.DurationText
			local options = durationText and durationText.GetProfileOptions and durationText:GetProfileOptions() or {}
			for _, option in ipairs(options) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return currentEntry and currentEntry.barDurationTextProfile ~= nil and Bars.NormalizeDurationTextProfile(currentEntry.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile) == option.value or false
				end, function() setEntryBarField(panelId, entryId, "barDurationTextProfile", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarShowValueText"] or "Show value",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCooldown",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowValueText", Bars.DEFAULTS.barShowValueText)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowValueText", value) end,
	}
	settings[#settings + 1] = {
		name = L["durationTextProfile"] or "Duration text profile",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarCooldown",
		height = 140,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return currentEntry and currentEntry.barDurationTextProfile ~= nil and Bars.NormalizeDurationTextProfile(currentEntry.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile) or "PANEL_DEFAULT"
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barDurationTextProfile", value == "PANEL_DEFAULT" and nil or Bars.NormalizeDurationTextProfile(value, Bars.DEFAULTS.barDurationTextProfile)) end,
		generator = function(_, root)
			root:CreateRadio(L["durationTextProfilePanelDefault"] or "Panel default", function()
				local currentEntry = getStandaloneBarContextEntry(ctx)
				return not currentEntry or currentEntry.barDurationTextProfile == nil
			end, function() setEntryBarField(panelId, entryId, "barDurationTextProfile", nil) end)
			local durationText = addon.DurationText
			local options = durationText and durationText.GetProfileOptions and durationText:GetProfileOptions() or {}
			for _, option in ipairs(options) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return currentEntry and currentEntry.barDurationTextProfile ~= nil and Bars.NormalizeDurationTextProfile(currentEntry.barDurationTextProfile, Bars.DEFAULTS.barDurationTextProfile) == option.value or false
				end, function() setEntryBarField(panelId, entryId, "barDurationTextProfile", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarReverseFill"] or "Reverse fill direction",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarCooldown",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barReverseFill", Bars.DEFAULTS.barReverseFill)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barReverseFill", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelShowStacks"] or "Show stack count",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN and supportsBarMode(currentEntry, Bars.BAR_MODE.STACKS)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local resolvedType = currentEntry and getEntryResolvedType(currentEntry) or nil
			return Bars.ShouldEntryShowStacks(currentEntry, resolvedType)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "showStacks", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelShowStacks"] or "Show stack count",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barShowStackText", Bars.DEFAULTS.barShowStackText)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barShowStackText", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackMax"] or "Max stacks",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = 1,
		maxValue = 1000,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.NormalizeBarStackMax(currentEntry and currentEntry.barStackMax, Bars.DEFAULTS.barStackMax)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackMax", Bars.NormalizeBarStackMax(value, Bars.DEFAULTS.barStackMax)) end,
		formatter = function(value) return tostring(Bars.NormalizeBarStackMax(value, Bars.DEFAULTS.barStackMax)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStacksSegmented"] or "Segment stacks",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStoredBoolean(currentEntry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "barStacksSegmented", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelSegmentSpacing"] or "Segment spacing",
		tooltip = L["CooldownPanelSegmentSpacingTooltip"],
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = BAR_CHARGES_GAP_MIN,
		maxValue = BAR_CHARGES_GAP_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarChargesGap(currentEntry and currentEntry.barStackSeparatedOffset, Bars.DEFAULTS.barStackSeparatedOffset)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackSeparatedOffset", normalizeBarChargesGap(value, Bars.DEFAULTS.barStackSeparatedOffset)) end,
		formatter = function(value) return tostring(normalizeBarChargesGap(value, Bars.DEFAULTS.barStackSeparatedOffset)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackDividerColor"] or "Divider color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		hasOpacity = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barStackDividerColor, Bars.DEFAULTS.barStackDividerColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackDividerColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barStackDividerColor)) end,
	}
	settings[#settings + 1] = {
		name = L["Separator thickness"] or "Separator thickness",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = BAR_STACK_DIVIDER_THICKNESS_MIN,
		maxValue = BAR_STACK_DIVIDER_THICKNESS_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.STACKS
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not getStoredBoolean(currentEntry, "barStacksSegmented", Bars.DEFAULTS.barStacksSegmented)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarStackDividerThickness(currentEntry and currentEntry.barStackDividerThickness, Bars.DEFAULTS.barStackDividerThickness)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackDividerThickness", normalizeBarStackDividerThickness(value, Bars.DEFAULTS.barStackDividerThickness)) end,
		formatter = function(value) return tostring(normalizeBarStackDividerThickness(value, Bars.DEFAULTS.barStackDividerThickness)) end,
	}
	settings[#settings + 1] = {
		name = L["Stack anchor"] or "Stack anchor",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		height = 160,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barStackAnchor, Bars.DEFAULTS.barStackAnchor)
		end,
		set = function(_, value) Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barStackAnchor", "barStackOffsetX", "barStackOffsetY", value, Bars.DEFAULTS.barStackAnchor) end,
		generator = function(_, root)
			for _, option in ipairs(Bars.GetBarTextAnchorOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barStackAnchor, Bars.DEFAULTS.barStackAnchor) == option.value
				end, function() Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barStackAnchor", "barStackOffsetX", "barStackOffsetY", option.value, Bars.DEFAULTS.barStackAnchor) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["Stack font"] or "Stack font",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		height = 220,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStandaloneBarFontValue(currentEntry and currentEntry.barStackFont)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackFont", value) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.GetFontOptions(labelDefaultFontPath)) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return getStandaloneBarFontValue(currentEntry and currentEntry.barStackFont) == option.value
				end, function() setEntryBarField(panelId, entryId, "barStackFont", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackStyle"] or "Stack style",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		height = 120,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontStyle(currentEntry and currentEntry.barStackStyle, labelDefaultFontStyle)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackStyle", Helper.NormalizeFontStyleChoice(value, labelDefaultFontStyle)) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.FontStyleOptions) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarFontStyle(currentEntry and currentEntry.barStackStyle, labelDefaultFontStyle) == option.value
				end, function() setEntryBarField(panelId, entryId, "barStackStyle", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["Stack size"] or "Stack size",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = BAR_FONT_SIZE_MIN,
		maxValue = BAR_FONT_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontSize(currentEntry and currentEntry.barStackSize, labelDefaultFontSize)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackSize", Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, labelDefaultFontSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, labelDefaultFontSize)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackColor"] or "Stack color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		hasOpacity = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barStackColor, Bars.DEFAULTS.barStackColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barStackColor)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackOffsetX"] or "Stack X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barStackOffsetX, Bars.DEFAULTS.barStackOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackOffsetX", normalizeBarOffset(value, Bars.DEFAULTS.barStackOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barStackOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarStackOffsetY"] or "Stack Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarStacks",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barStackOffsetY, Bars.DEFAULTS.barStackOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barStackOffsetY", normalizeBarOffset(value, Bars.DEFAULTS.barStackOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barStackOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueAnchor"] or "Value anchor",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 160,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barValueAnchor, Bars.DEFAULTS.barValueAnchor)
		end,
		set = function(_, value) Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barValueAnchor", "barValueOffsetX", "barValueOffsetY", value, Bars.DEFAULTS.barValueAnchor) end,
		generator = function(_, root)
			for _, option in ipairs(Bars.GetBarTextAnchorOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barValueAnchor, Bars.DEFAULTS.barValueAnchor) == option.value
				end, function() Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barValueAnchor", "barValueOffsetX", "barValueOffsetY", option.value, Bars.DEFAULTS.barValueAnchor) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueAnchor"] or "Value anchor",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 160,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barValueAnchor, Bars.DEFAULTS.barValueAnchor)
		end,
		set = function(_, value) Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barValueAnchor", "barValueOffsetX", "barValueOffsetY", value, Bars.DEFAULTS.barValueAnchor) end,
		generator = function(_, root)
			for _, option in ipairs(Bars.GetBarTextAnchorOptions()) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return Bars.NormalizeTextAnchor(currentEntry and currentEntry.barValueAnchor, Bars.DEFAULTS.barValueAnchor) == option.value
				end, function() Bars.SetTextAnchorWithFreshOffsets(panelId, entryId, "barValueAnchor", "barValueOffsetX", "barValueOffsetY", option.value, Bars.DEFAULTS.barValueAnchor) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueOffsetX"] or "Value X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barValueOffsetX, Bars.DEFAULTS.barValueOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueOffsetX", normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueOffsetX"] or "Value X",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barValueOffsetX, Bars.DEFAULTS.barValueOffsetX)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueOffsetX", normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetX)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetX)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueOffsetY"] or "Value Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barValueOffsetY, Bars.DEFAULTS.barValueOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueOffsetY", normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueOffsetY"] or "Value Y",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_OFFSET_MIN,
		maxValue = BAR_OFFSET_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarOffset(currentEntry and currentEntry.barValueOffsetY, Bars.DEFAULTS.barValueOffsetY)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueOffsetY", normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetY)) end,
		formatter = function(value) return tostring(normalizeBarOffset(value, Bars.DEFAULTS.barValueOffsetY)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelFont"] or "Label font",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		height = 220,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStandaloneBarFontValue(currentEntry and currentEntry.barLabelFont)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelFont", value) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.GetFontOptions(labelDefaultFontPath)) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return getStandaloneBarFontValue(currentEntry and currentEntry.barLabelFont) == option.value
				end, function() setEntryBarField(panelId, entryId, "barLabelFont", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelStyle"] or "Label style",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		height = 120,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontStyle(currentEntry and currentEntry.barLabelStyle, labelDefaultFontStyle)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelStyle", Helper.NormalizeFontStyleChoice(value, labelDefaultFontStyle)) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.FontStyleOptions) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarFontStyle(currentEntry and currentEntry.barLabelStyle, labelDefaultFontStyle) == option.value
				end, function() setEntryBarField(panelId, entryId, "barLabelStyle", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelSize"] or "Label size",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		minValue = BAR_FONT_SIZE_MIN,
		maxValue = BAR_FONT_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontSize(currentEntry and currentEntry.barLabelSize, labelDefaultFontSize)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelSize", Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, labelDefaultFontSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, labelDefaultFontSize)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarLabelColor"] or "Label color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarLabel",
		hasOpacity = true,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.barShowLabel == true)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barLabelColor, Bars.DEFAULTS.barLabelColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barLabelColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barLabelColor)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueFont"] or "Value font",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 220,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStandaloneBarFontValue(currentEntry and currentEntry.barValueFont)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueFont", value) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.GetFontOptions(valueDefaultFontPath)) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return getStandaloneBarFontValue(currentEntry and currentEntry.barValueFont) == option.value
				end, function() setEntryBarField(panelId, entryId, "barValueFont", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueFont"] or "Value font",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 220,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getStandaloneBarFontValue(currentEntry and currentEntry.barValueFont)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueFont", value) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.GetFontOptions(valueDefaultFontPath)) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return getStandaloneBarFontValue(currentEntry and currentEntry.barValueFont) == option.value
				end, function() setEntryBarField(panelId, entryId, "barValueFont", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueStyle"] or "Value style",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 120,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontStyle(currentEntry and currentEntry.barValueStyle, valueDefaultFontStyle)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueStyle", Helper.NormalizeFontStyleChoice(value, valueDefaultFontStyle)) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.FontStyleOptions) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarFontStyle(currentEntry and currentEntry.barValueStyle, valueDefaultFontStyle) == option.value
				end, function() setEntryBarField(panelId, entryId, "barValueStyle", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueStyle"] or "Value style",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		height = 120,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontStyle(currentEntry and currentEntry.barValueStyle, valueDefaultFontStyle)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueStyle", Helper.NormalizeFontStyleChoice(value, valueDefaultFontStyle)) end,
		generator = function(_, root)
			for _, option in ipairs(Helper.FontStyleOptions) do
				root:CreateRadio(option.label, function()
					local currentEntry = getStandaloneBarContextEntry(ctx)
					return normalizeBarFontStyle(currentEntry and currentEntry.barValueStyle, valueDefaultFontStyle) == option.value
				end, function() setEntryBarField(panelId, entryId, "barValueStyle", option.value) end)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueSize"] or "Value size",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_FONT_SIZE_MIN,
		maxValue = BAR_FONT_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontSize(currentEntry and currentEntry.barValueSize, valueDefaultFontSize)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueSize", Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, valueDefaultFontSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, valueDefaultFontSize)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueSize"] or "Value size",
		kind = SettingType.Slider,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		minValue = BAR_FONT_SIZE_MIN,
		maxValue = BAR_FONT_SIZE_MAX,
		valueStep = 1,
		allowInput = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarFontSize(currentEntry and currentEntry.barValueSize, valueDefaultFontSize)
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueSize", Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, valueDefaultFontSize)) end,
		formatter = function(value) return tostring(Helper.ClampInt(value, BAR_FONT_SIZE_MIN, BAR_FONT_SIZE_MAX, valueDefaultFontSize)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueColor"] or "Value color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		hasOpacity = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.CHARGES
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barValueColor, Bars.DEFAULTS.barValueColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barValueColor)) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelBarValueColor"] or "Value color",
		kind = SettingType.Color,
		parentId = "eqolCooldownPanelStandaloneBarValueText",
		hasOpacity = true,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return normalizeBarMode(currentEntry and currentEntry.barMode, Bars.DEFAULTS.barMode) == Bars.BAR_MODE.COOLDOWN
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not Bars.ShouldShowBarValueTextSettings(currentEntry)
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			local color = Helper.NormalizeColor(currentEntry and currentEntry.barValueColor, Bars.DEFAULTS.barValueColor)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "barValueColor", Helper.NormalizeColor(value, Bars.DEFAULTS.barValueColor)) end,
	}
end

local function appendBarStandaloneVisibilitySettings(settings, ctx)
	local panelId = ctx.panelId
	local entryId = ctx.entryId
	local SettingType = ctx.SettingType

	settings[#settings + 1] = {
		name = L["Visibility"] or (L["Display"] or "Display"),
		kind = SettingType.Collapsible,
		id = "eqolCooldownPanelStandaloneBarVisibility",
		defaultCollapsed = true,
	}
	settings[#settings + 1] = {
		name = L["Always show"] or "Always show",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) == "ITEM"
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return currentEntry and currentEntry.alwaysShow ~= false or false
		end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "alwaysShow", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelOverwritePanelCDMAuraAlwaysShow"] or "Overwrite panel tracked aura display",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) == "CDM_AURA"
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return currentEntry and currentEntry.cdmAuraAlwaysShowUseGlobal == false or false
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "cdmAuraAlwaysShowUseGlobal", value ~= true) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelCDMAuraAlwaysShowMode"] or "Tracked aura display",
		kind = SettingType.Dropdown,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		height = 180,
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) == "CDM_AURA"
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.cdmAuraAlwaysShowUseGlobal == false)
		end,
		get = function() return getStandaloneBarCDMAuraMode(panelId, entryId) end,
		set = function(_, value) setEntryBarField(panelId, entryId, "cdmAuraAlwaysShowMode", normalizeCDMAuraAlwaysShowModeValue(value, "HIDE")) end,
		generator = function(_, root)
			for _, option in ipairs(CooldownPanels.GetCDMAuraAlwaysShowOptions and CooldownPanels:GetCDMAuraAlwaysShowOptions() or {}) do
				root:CreateRadio(
					option.label,
					function() return getStandaloneBarCDMAuraMode(panelId, entryId) == option.value end,
					function() setEntryBarField(panelId, entryId, "cdmAuraAlwaysShowMode", option.value) end
				)
			end
		end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelOverwriteGlobalDefault"] or "Overwrite global default",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) ~= "CDM_AURA"
		end,
		get = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return currentEntry and currentEntry.cooldownVisibilityUseGlobal == false or false
		end,
		set = function(_, value) setEntryBarField(panelId, entryId, "cooldownVisibilityUseGlobal", value ~= true) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelHideOnCooldown"] or "Hide on cooldown",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) ~= "CDM_AURA"
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.cooldownVisibilityUseGlobal == false)
		end,
		get = function() return getStandaloneBarVisibility(panelId, entryId, "hideOnCooldown") end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "hideOnCooldown", value) end,
	}
	settings[#settings + 1] = {
		name = L["CooldownPanelShowOnCooldown"] or "Show on cooldown",
		kind = SettingType.Checkbox,
		parentId = "eqolCooldownPanelStandaloneBarVisibility",
		isShown = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return getEntryResolvedType(currentEntry) ~= "CDM_AURA"
		end,
		disabled = function()
			local currentEntry = getStandaloneBarContextEntry(ctx)
			return not (currentEntry and currentEntry.cooldownVisibilityUseGlobal == false)
		end,
		get = function() return getStandaloneBarVisibility(panelId, entryId, "showOnCooldown") end,
		set = function(_, value) setEntryBarBoolean(panelId, entryId, "showOnCooldown", value) end,
	}
end

Bars.BuildBarStandaloneSettings = function(panelId, entryId)
	local ctx = createBarStandaloneSettingsContext(panelId, entryId)
	if not ctx then return nil end
	local detailSettings = {}
	local appearanceSettings = {}
	local borderSettings = {}
	local textSettings = {}
	local visibilitySettings = {}
	local settings = {}
	Bars.AppendBarStandaloneDetailHeaders(detailSettings, ctx)
	appendBarStandaloneAppearanceSettings(appearanceSettings, ctx)
	Bars.AppendBarStandaloneBorderSettings(borderSettings, ctx)
	appendBarStandaloneTextSettings(textSettings, ctx)
	appendBarStandaloneVisibilitySettings(visibilitySettings, ctx)

	for _, collection in ipairs({ appearanceSettings, borderSettings, detailSettings, textSettings, visibilitySettings }) do
		for _, setting in ipairs(collection) do
			settings[#settings + 1] = setting
		end
	end
	if CooldownPanels.NormalizeStandaloneSettingsOrder then
		settings = CooldownPanels:NormalizeStandaloneSettingsOrder(settings, {
			"eqolCooldownPanelStandaloneBar",
			"eqolCooldownPanelStandaloneBarLayout",
			"eqolCooldownPanelStandaloneBarIcon",
			"eqolCooldownPanelStandaloneBarFill",
			"eqolCooldownPanelStandaloneBarBorder",
			"eqolCooldownPanelStandaloneBarVisibility",
			"eqolCooldownPanelStandaloneBarCooldown",
			"eqolCooldownPanelStandaloneBarCharges",
			Bars.STANDALONE_STACKS_SECTION_ID,
			"eqolCooldownPanelStandaloneBarValueText",
			"eqolCooldownPanelStandaloneBarLabel",
		})
	end
	return settings
end

Bars.BuildStandaloneDialogButtons = function(panelId, entryId, existingButtons)
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel, entry = getStandaloneBarEntry(panelId, entryId)
	if not (panel and entry and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout)) then return existingButtons end

	local buttons = {}
	local removeButton
	local displayMode = normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode)
	for _, button in ipairs(existingButtons or {}) do
		if type(button) == "table" and button.id == "removeEntry" then
			removeButton = button
		else
			buttons[#buttons + 1] = button
		end
	end
	buttons[#buttons + 1] = {
		text = displayMode == Bars.DISPLAY_MODE.BAR and (L["CooldownPanelSwitchToButton"] or "Switch to Button") or (L["CooldownPanelSwitchToBar"] or "Switch to Bar"),
		layout = "compact",
		click = function()
			if normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) == Bars.DISPLAY_MODE.BAR then
				setEntryDisplayMode(panelId, entryId, Bars.DISPLAY_MODE.BUTTON)
			else
				setEntryDisplayMode(panelId, entryId, Bars.DISPLAY_MODE.BAR, normalizeBarMode(entry.barMode, Bars.DEFAULTS.barMode))
			end
		end,
	}
	if removeButton then
		buttons[#buttons + 1] = removeButton
	end
	return buttons
end

Bars._eqolOriginalOpenLayoutEntryStandaloneMenu = Bars._eqolOriginalOpenLayoutEntryStandaloneMenu or CooldownPanels.OpenLayoutEntryStandaloneMenu
function CooldownPanels:OpenLayoutEntryStandaloneMenu(panelId, entryId, anchorFrame, allowOutsideLayoutEdit)
	local lib = addon.EditModeLib
	if not (lib and lib.ShowStandaloneSettingsDialog) then return Bars._eqolOriginalOpenLayoutEntryStandaloneMenu(self, panelId, entryId, anchorFrame, allowOutsideLayoutEdit) end

	local originalShowStandaloneSettingsDialog = lib.ShowStandaloneSettingsDialog
	lib.ShowStandaloneSettingsDialog = function(editModeLib, frame, options)
		local resolvedOptions = options or {}
		resolvedOptions.buttons = Bars.BuildStandaloneDialogButtons(panelId, entryId, resolvedOptions.buttons)
		local panel, entry = getStandaloneBarEntry(panelId, entryId)
		if panel and entry and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) and normalizeDisplayMode(entry.displayMode, Bars.DEFAULTS.displayMode) == Bars.DISPLAY_MODE.BAR then
			local settings = Bars.BuildBarStandaloneSettings(panelId, entryId)
			if settings then
				resolvedOptions.settings = settings
			end
		end
		return originalShowStandaloneSettingsDialog(editModeLib, frame, resolvedOptions)
	end

	local ok, result = pcall(Bars._eqolOriginalOpenLayoutEntryStandaloneMenu, self, panelId, entryId, anchorFrame, allowOutsideLayoutEdit)
	lib.ShowStandaloneSettingsDialog = originalShowStandaloneSettingsDialog
	if not ok then error(result) end

	local state = self.GetLayoutEntryStandaloneMenuState and self:GetLayoutEntryStandaloneMenuState(false) or nil
	if state and normalizeId(state.panelId) == normalizeId(panelId) and normalizeId(state.entryId) == normalizeId(entryId) then state.anchorFrame = anchorFrame end
	return result
end
