-- luacheck: globals UIParent BackdropTemplateMixin CreateFrame C_ChallengeMode C_ScenarioInfo C_Spell C_Timer CUSTOM_CLASS_COLORS Enum GameTooltip GameTooltip_Hide GetInstanceInfo GetNumGroupMembers GetTime GetWorldElapsedTime GetWorldElapsedTimers InCombatLockdown IsInInstance IsInRaid RAID_CLASS_COLORS SecondsToClock UnitClass UnitClassFromGUID UnitGUID UnitIsDeadOrGhost UnitName UnitNameFromGUID hooksecurefunc issecretvalue IsInGroup GetNumSubgroupMembers LE_PARTY_CATEGORY_INSTANCE
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.MythicPlusTimer = addon.MythicPlus.MythicPlusTimer or {}

local Timer = addon.MythicPlus.MythicPlusTimer
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType

local EDITMODE_ID = "EQOL_MythicPlusTimer"
Timer.dynamicAnchorId = "tracker:mythicPlusTimer"
local DEFAULT_STATUSBAR = "Interface\\TargetingFrame\\UI-StatusBar"
local DEFAULT_BORDER = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local GLOBAL_FONT_KEY = "__EQOL_GLOBAL_FONT__"
local GLOBAL_STYLE_KEY = "__EQOL_GLOBAL_FONT_STYLE__"
local DEFAULT_HEADER_BAR_HEIGHT = 24
local DEFAULT_FOOTER_BAR_HEIGHT = 18
local TICK_INTERVAL = 0.2
local CHALLENGERS_PERIL_AFFIX_ID = 152
local DEATH_ICON_ATLAS = "poi-graveyard-neutral"

Timer.defaults = Timer.defaults
	or {
		enabled = false,
		showDungeon = true,
		dungeonDisplay = "NAME_LEVEL",
		dungeonPlacement = "ROW",
		showAffixes = true,
		showAffixIcons = false,
		affixDisplay = "ICON",
		showTimer = true,
		timerDisplay = "TIME_LEFT",
		showChestTimers = false,
		showDeaths = true,
		deathDisplay = "ICON",
		deathBarMode = "DEATHS",
		deathPlacement = "ROW",
		deathShowTimeLost = true,
		showObjectives = true,
		showObjectiveValues = true,
		hideNonBossObjectives = false,
		showEnemyForces = true,
		showEnemyForcesBar = true,
		enemyForcesValueMode = "DEFAULT",
		showObjectiveBars = true,
		showObjectiveTimes = false,
		showObjectiveBestTimes = true,
		showOnlyInMythicPlus = true,
		visibility = "runOrEditMode",
		updateRate = 0.2,
		tooltip = true,
		layoutMode = "FLOW",
		panelHeight = 106,
		showKeyLevel = false,
		showBestTime = false,
		showBestDelta = true,
		showEnemyPercent = false,
		showPanelTimerBar = true,
		showPanelEnemyBar = true,
		dungeonAnchor = "TOP",
		dungeonOffsetX = 0,
		dungeonOffsetY = 23,
		keyLevelAnchor = "TOPLEFT",
		keyLevelOffsetX = 12,
		keyLevelOffsetY = -12,
		timerAnchor = "LEFT",
		timerOffsetX = 25,
		timerOffsetY = 1,
		chest2Anchor = "TOPLEFT",
		chest2OffsetX = 115,
		chest2OffsetY = -38,
		chest3Anchor = "TOPLEFT",
		chest3OffsetX = 175,
		chest3OffsetY = -38,
		deathsAnchor = "TOPLEFT",
		deathsOffsetX = 25,
		deathsOffsetY = -21,
		enemyPercentAnchor = "TOPLEFT",
		enemyPercentOffsetX = 218,
		enemyPercentOffsetY = -42,
		bestTimeAnchor = "BOTTOMLEFT",
		bestTimeOffsetX = 7,
		bestTimeOffsetY = 5,
		bestTimeColor = { r = 1, g = 1, b = 1, a = 1 },
		panelAffixesAnchor = "TOPRIGHT",
		panelAffixesOffsetX = -20,
		panelAffixesOffsetY = -20,
		panelAffixesFontSize = 18,
		panelAffixIconSize = 16,
		panelDungeonFontSize = 20,
		panelKeyLevelFontSize = 26,
		panelTimerFontSize = 20,
		panelChestFontSize = 12,
		panelChestHideLabels = true,
		panelDeathsFontSize = 16,
		panelDeathIconSize = 12,
		panelEnemyPercentFontSize = 12,
		panelBestTimeFontSize = 12,
		panelObjectivesAnchor = "BOTTOM",
		panelObjectivesGrowth = "DOWN",
		panelObjectivesOffsetX = 0,
		panelObjectivesOffsetY = -23,
		panelObjectivesWidth = 240,
		panelObjectivesFontFace = GLOBAL_FONT_KEY,
		panelObjectivesFontOutline = GLOBAL_STYLE_KEY,
		panelObjectivesFontSize = 13,
		panelObjectivesSpacing = 0,
		panelObjectivesColumnSpacing = 0,
		panelObjectivesInvertColumns = false,
		panelObjectivesAttachToTimerBar = false,
		panelBarWidth = 220,
		panelBarHeight = 8,
		panelTimerBarWidth = 218,
		panelTimerBarHeight = 13,
		panelTimerBarColor = { r = 0.02352941408753395, g = 0.4274510145187378, b = 1, a = 1 },
		panelTimerBarExpiredColor = { r = 1, g = 0.12, b = 0.12, a = 1 },
		panelTimerBarTexture = "",
		panelTimerBarBackgroundTexture = "Solid",
		panelTimerBarBackgroundColor = { r = 0, g = 0, b = 0, a = 0.835936963558197 },
		panelTimerBarBorderEnabled = false,
		panelTimerBarBorderTexture = "None",
		panelTimerBarBorderColor = { r = 0.0470588281750679, g = 0.95686280727386475, b = 1, a = 1 },
		panelTimerBarBorderSize = 5,
		panelTimerBarBorderOffset = 1,
		panelTimerBarBorderSeparateOffset = false,
		panelTimerBarBorderOffsetX = 0,
		panelTimerBarBorderOffsetY = 0,
		panelTimerBarChestMarkers = true,
		panelTimerBarChestMarkerColor = { r = 1, g = 1, b = 1, a = 0.85 },
		panelTimerBarChestMarkerWidth = 1,
		panelTimerBarChestTimeText = true,
		panelTimerBarChestTimeTextOffsetY = 14,
		panelTimerBarChestTimeTextFontSize = 14,
		panelTimerBarChestTimeTextColor = { r = 1, g = 0.6627451181411743, b = 0.03529411926865578, a = 1 },
		panelTimerBarTimeLeftText = false,
		panelTimerBarTimeLeftTextOffsetX = 9,
		panelTimerBarTimeLeftTextOffsetY = 14,
		panelTimerBarTimeLeftTextFontSize = 14,
		panelTimerBarTimeLeftTextColor = { r = 0.2156862914562225, g = 1, b = 0.9568628072738647, a = 1 },
		panelTimerBarFillUp = true,
		panelTimerBarAnchor = "BOTTOM",
		panelTimerBarOffsetX = 0,
		panelTimerBarOffsetY = 16,
		panelTimerBarAttachToHeader = false,
		panelEnemyBarWidth = 249,
		panelEnemyBarHeight = 14,
		panelEnemyBarColor = { r = 0.9490196704864502, g = 0.2039215862751007, b = 0.062745101749897, a = 1 },
		panelEnemyBarTexture = "Blizzard Raid Bar",
		panelEnemyBarBackgroundTexture = "Solid",
		panelEnemyBarBackgroundColor = { r = 0, g = 0, b = 0, a = 0.7656245827674866 },
		panelEnemyBarBorderEnabled = true,
		panelEnemyBarBorderTexture = "EQOL: Midnight white 12px",
		panelEnemyBarBorderColor = { r = 0.6000000238418579, g = 0.4117647409439087, b = 0.2352941334247589, a = 1 },
		panelEnemyBarBorderSize = 9,
		panelEnemyBarBorderOffset = 2,
		panelEnemyBarBorderSeparateOffset = false,
		panelEnemyBarBorderOffsetX = 0,
		panelEnemyBarBorderOffsetY = 0,
		panelEnemyBarAnchor = "BOTTOM",
		panelEnemyBarOffsetX = 0,
		panelEnemyBarOffsetY = -15,
		panelEnemyBarAttachToObjectives = false,
		panelEnemyBarAttachOffsetX = 0,
		panelEnemyBarAttachOffsetY = 0,
		panelEnemyBarTextEnabled = true,
		panelEnemyBarTextMode = "BOTH",
		panelEnemyBarTextAlign = "RIGHT",
		panelEnemyBarText2Enabled = false,
		panelEnemyBarText2Mode = "PERCENT",
		panelEnemyBarText2Align = "LEFT",
		panelEnemyBarTextOffsetY = 0,
		panelEnemyBarTextFontSize = 13,
		panelEnemyBarTextColor = { r = 1, g = 1, b = 1, a = 1 },
		width = 261,
		rowHeight = 18,
		rowSpacing = 3,
		growth = "UP",
		align = "LEFT",
		timerAlign = "INHERIT",
		iconOffsetX = 0,
		iconOffsetY = 0,
		iconGap = 4,
		textOffsetX = 4,
		textOffsetY = 0,
		valueOffsetX = -4,
		valueOffsetY = 0,
		barPosition = "BACKGROUND",
		barHeight = 18,
		barOffsetX = 0,
		barOffsetY = 0,
		barWidthOffset = 0,
		texture = "Blizzard Raid Bar",
		barBackgroundTexture = "",
		barBackgroundColor = { r = 0, g = 0, b = 0, a = 0.45 },
		barBorderEnabled = false,
		barBorderTexture = "",
		barBorderColor = { r = 0, g = 0, b = 0, a = 0.85 },
		barBorderSize = 1,
		barBorderOffset = 0,
		barBorderSeparateOffset = false,
		barBorderOffsetX = 0,
		barBorderOffsetY = 0,
		fontFace = GLOBAL_FONT_KEY,
		fontOutline = GLOBAL_STYLE_KEY,
		fontSize = 12,
		titleFontSize = 15,
		timerFontSize = 18,
		dungeonColor = { r = 1, g = 0.82, b = 0, a = 1 },
		affixColor = { r = 1, g = 1, b = 1, a = 0.88 },
		useGlobalTextColor = false,
		textColor = { r = 1, g = 1, b = 1, a = 1 },
		timerColor = { r = 0.15, g = 1, b = 0.25, a = 1 },
		timerExpiredColor = { r = 1, g = 0.12, b = 0.12, a = 1 },
		chestColor = { r = 0.55, g = 0.85, b = 1, a = 1 },
		deathColor = { r = 1, g = 0.2, b = 0.2, a = 1 },
		objectiveColor = { r = 1, g = 1, b = 1, a = 1 },
		objectiveCompleteColor = { r = 0.55, g = 0.55, b = 0.55, a = 1 },
		objectiveBestDeltaFasterColor = { r = 0.15, g = 1, b = 0.25, a = 1 },
		objectiveBestDeltaSlowerColor = { r = 1, g = 0.25, b = 0.2, a = 1 },
		enemyForcesColor = { r = 0.95, g = 0.55, b = 0.15, a = 1 },
		backdropEnabled = true,
		backdropUseCustomTexture = true,
		backdropCustomTexture = "ChallengeMode-Timer",
		backdropTexture = "EQOL: Astral",
		backdropColor = { r = 0.9568628072738647, g = 0.9686275124549866, b = 1, a = 1 },
		backdropAnchor = "CENTER",
		backdropOffsetX = 0,
		backdropOffsetY = 0,
		backdropSizeOffsetX = 0,
		backdropSizeOffsetY = 0,
		headerBarEnabled = true,
		headerBarUseCustomTexture = true,
		headerBarCustomTexture = "ui-damagemeters-header-bar",
		headerBarTexture = "TWEBA Blizzard",
		headerBarColor = { r = 1, g = 1, b = 1, a = 1 },
		headerBarAnchor = "TOP",
		headerBarOffsetX = 0,
		headerBarOffsetY = -1,
		headerBarSizeOffsetX = 9,
		headerBarSizeOffsetY = 0,
		footerContent = "NONE",
		footerBarEnabled = false,
		footerBarUseCustomTexture = false,
		footerBarCustomTexture = "",
		footerBarTexture = "EQOL: Blizzard cropped",
		footerBarColor = { r = 0, g = 0, b = 0, a = 0.35 },
		footerBarAnchor = "BOTTOM",
		footerBarOffsetX = 0,
		footerBarOffsetY = 0,
		footerBarSizeOffsetX = 0,
		footerBarSizeOffsetY = 0,
		borderEnabled = false,
		borderTexture = "EQOL: Midnight white",
		borderColor = { r = 1, g = 0.82, b = 0, a = 0.8 },
		borderSize = 8,
		borderInset = 0,
		borderSeparateOffset = false,
		borderOffsetX = 0,
		borderOffsetY = 0,
		borderPositionOffsetX = 0,
		borderPositionOffsetY = 0,
	}

local defaults = Timer.defaults

local function copyColor(color)
	color = type(color) == "table" and color or {}
	return {
		r = tonumber(color.r or color[1]) or 1,
		g = tonumber(color.g or color[2]) or 1,
		b = tonumber(color.b or color[3]) or 1,
		a = tonumber(color.a or color[4]) or 1,
	}
end

local function clampNumber(value, minimum, maximum, fallback)
	local number = tonumber(value) or fallback or minimum
	if number < minimum then return minimum end
	if number > maximum then return maximum end
	return number
end

local function getPixelSize()
	return addon.PixelUtil.OnePixel(UIParent)
end

local function snapToPixel(value)
	return addon.PixelUtil.Snap(value, UIParent)
end

local function snapSize(value, minimum)
	return math.max(minimum or getPixelSize(), snapToPixel(value))
end

local function pointOffset(value, minimum, maximum, fallback)
	return snapToPixel(clampNumber(value, minimum, maximum, fallback))
end

local function applyBorderOffset(borderFrame, target, offsetX, offsetY, positionOffsetX, positionOffsetY)
	if not (borderFrame and target) then return end
	local borderOffsetX = snapToPixel(clampNumber(offsetX, -300, 300, 0))
	local borderOffsetY = snapToPixel(clampNumber(offsetY, -300, 300, borderOffsetX))
	local shiftX = pointOffset(positionOffsetX, -1000, 1000, 0)
	local shiftY = pointOffset(positionOffsetY, -1000, 1000, 0)
	borderFrame:ClearAllPoints()
	borderFrame:SetPoint("TOPLEFT", target, "TOPLEFT", -borderOffsetX + shiftX, borderOffsetY + shiftY)
	borderFrame:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", borderOffsetX + shiftX, -borderOffsetY + shiftY)
end

local function getBorderOffsets(getter, prefix, legacyKey)
	local fallbackDefaults = Timer.defaults or {}
	if getter(prefix .. "SeparateOffset") == true then
		local defaultX = fallbackDefaults[prefix .. "OffsetX"] or 0
		local defaultY = fallbackDefaults[prefix .. "OffsetY"] or 0
		return clampNumber(getter(prefix .. "OffsetX"), -300, 300, defaultX), clampNumber(getter(prefix .. "OffsetY"), -300, 300, defaultY)
	end
	local defaultOffset = fallbackDefaults[legacyKey] or fallbackDefaults[prefix .. "Offset"] or 0
	local offset = clampNumber(getter(legacyKey), -300, 300, defaultOffset)
	return offset, offset
end

local function getTimerConfig(create)
	if not addon.db then return nil end
	local config = addon.db.mythicPlusTimer
	if type(config) ~= "table" then
		if not create then return nil end
		config = { layoutMode = "FLOW" }
		addon.db.mythicPlusTimer = config
	end
	return config
end

local function getTimerConfigValue(key, fallback)
	local config = getTimerConfig(false)
	if config and config[key] ~= nil then return config[key] end
	return fallback
end

local function getTimerStoredTable(key, create)
	local config = getTimerConfig(create)
	if config then
		local value = config[key]
		if type(value) == "table" then return value end
		if create then
			value = {}
			config[key] = value
			return value
		end
	end
	return nil
end

local function normalizeColor(value, fallback)
	local color = copyColor(value or fallback)
	color.r = clampNumber(color.r, 0, 1, fallback and fallback.r or 1)
	color.g = clampNumber(color.g, 0, 1, fallback and fallback.g or 1)
	color.b = clampNumber(color.b, 0, 1, fallback and fallback.b or 1)
	color.a = clampNumber(color.a, 0, 1, fallback and fallback.a or 1)
	return color
end

local function setTextColor(fontString, color)
	color = normalizeColor(color, { r = 1, g = 1, b = 1, a = 1 })
	fontString:SetTextColor(color.r, color.g, color.b, color.a)
end

local function colorToHex(color)
	color = normalizeColor(color, { r = 1, g = 1, b = 1, a = 1 })
	return string.format("ff%02x%02x%02x", math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
end

local function wrapColor(text, color)
	return string.format("|c%s%s|r", colorToHex(color), text)
end

local function getGlobalFontKey()
	return addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or GLOBAL_FONT_KEY
end

local function getGlobalStyleKey()
	return addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or GLOBAL_STYLE_KEY
end

local function normalizeFontStyle(value)
	if addon.functions.NormalizeFontStyleChoice then return addon.functions.NormalizeFontStyleChoice(value, getGlobalStyleKey(), true) end
	if value == GLOBAL_STYLE_KEY or value == "NONE" or value == "OUTLINE" or value == "THICKOUTLINE" or value == "MONOCHROME" or value == "MONOCHROMEOUTLINE" then return value end
	return getGlobalStyleKey()
end

local function normalizePoint(value)
	if value == "TOPLEFT" or value == "TOP" or value == "TOPRIGHT" or value == "LEFT" or value == "CENTER" or value == "RIGHT" or value == "BOTTOMLEFT" or value == "BOTTOM" or value == "BOTTOMRIGHT" then return value end
	return "TOPLEFT"
end

local function normalizeHorizontal(value)
	if value == "LEFT" or value == "CENTER" or value == "RIGHT" then return value end
	return "CENTER"
end

local function resolveFontStyle(value)
	if addon.functions.GetFontFlagsForStyle then
		local flags = addon.functions.GetFontFlagsForStyle(value, "OUTLINE")
		if flags == nil or flags == "" or flags == "OUTLINE" or flags == "THICKOUTLINE" or flags == "MONOCHROME" or flags == "MONOCHROMEOUTLINE" then return flags end
		return "OUTLINE"
	end
	value = normalizeFontStyle(value)
	if value == GLOBAL_STYLE_KEY then return addon.db and addon.db.globalFontStyle or "OUTLINE" end
	if value == "NONE" then return "" end
	if value == "" or value == "OUTLINE" or value == "THICKOUTLINE" or value == "MONOCHROME" or value == "MONOCHROMEOUTLINE" then return value end
	return "OUTLINE"
end

local function applyFontString(fontString, fontFace, fontSize, fontStyle)
	if not (fontString and fontString.SetFont) then return false end
	if addon.functions.ApplyFontString then return addon.functions.ApplyFontString(fontString, fontFace, fontSize, fontStyle, DEFAULT_FONT, "OUTLINE") end
	local flags = resolveFontStyle(fontStyle)
	local ok = pcall(fontString.SetFont, fontString, fontFace or DEFAULT_FONT, tonumber(fontSize) or 12, flags)
	if addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, fontStyle, "OUTLINE") end
	return ok
end

local function resolveMedia(mediaType, key, fallback)
	if type(key) == "string" and key ~= "" then
		if addon.functions.ResolveLSMMedia then
			local resolved = addon.functions.ResolveLSMMedia(mediaType, key, fallback, true)
			if resolved then return resolved end
		end
		if LSM and LSM.Fetch then
			local resolved = LSM:Fetch(mediaType, key, true)
			if resolved then return resolved end
		end
	end
	return fallback
end

local function trimTextureInput(value)
	if type(value) ~= "string" then return "" end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getCustomTextureInfo(value)
	value = trimTextureInput(value)
	if value == "" then return nil end
	local textureID = tonumber(value)
	if textureID then return "texture", textureID end
	if _G.C_Texture and _G.C_Texture.GetAtlasInfo and _G.C_Texture.GetAtlasInfo(value) then return "atlas", value end
	return "texture", value
end

local function applyTexture(texture, textureKind, textureValue)
	if not texture then return end
	if texture._eqolMPTTextureKind == textureKind and texture._eqolMPTTextureValue == textureValue then return end
	texture._eqolMPTTextureKind = textureKind
	texture._eqolMPTTextureValue = textureValue
	if textureKind == "atlas" then
		texture:SetAtlas(textureValue)
	else
		texture:SetTexture(textureValue)
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function resolveFont(key)
	if key == GLOBAL_FONT_KEY then key = addon.db and addon.db.globalFontFace or getGlobalFontKey() end
	return resolveMedia("font", key, DEFAULT_FONT)
end

local function buildMediaOptions(mediaType, includeGlobal)
	local options = {}
	if includeGlobal and mediaType == "font" then
		options[#options + 1] = { value = getGlobalFontKey(), label = addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or (L["useGlobalFontConfig"] or "Use global font config") }
	elseif mediaType == "statusbar" or mediaType == "border" then
		options[#options + 1] = { value = "", label = _G.DEFAULT or "Default" }
	end
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType) or {}
	for _, name in ipairs(names) do
		options[#options + 1] = { value = name, label = name }
	end
	return options
end

local function buildStyleOptions()
	if addon.functions.GetFontStyleOptionList then return addon.functions.GetFontStyleOptionList(true) end
	return {
		{ value = getGlobalStyleKey(), label = addon.functions.GetGlobalFontStyleConfigLabel and addon.functions.GetGlobalFontStyleConfigLabel() or (L["useGlobalFontStyleConfig"] or "Use global font styling") },
		{ value = "NONE", label = _G.NONE or "None" },
		{ value = "OUTLINE", label = L["Font outline"] or "Font outline" },
		{ value = "THICKOUTLINE", label = L["Thick outline"] or "Thick outline" },
		{ value = "MONOCHROME", label = "Monochrome" },
		{ value = "MONOCHROMEOUTLINE", label = "Monochrome Outline" },
	}
end

local function secondsToText(seconds)
	seconds = math.floor(math.max(0, tonumber(seconds) or 0))
	local minutes = math.floor(seconds / 60)
	return string.format("%d:%02d", minutes, seconds % 60)
end

local function timeRemainingToText(seconds)
	seconds = tonumber(seconds) or 0
	if seconds >= 0 then return secondsToText(seconds) end
	return "+" .. secondsToText(-seconds)
end

local function secondsToShortText(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	if seconds < 60 then return string.format("%ds", seconds) end
	local minutes = math.floor(seconds / 60)
	local remaining = seconds % 60
	if remaining == 0 then return string.format("%dm", minutes) end
	return string.format("%dm%02ds", minutes, remaining)
end

local function isInMythicPlus()
	if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then return true end
	local _, _, difficultyID = GetInstanceInfo()
	return difficultyID == 8
end

local function getActiveChallengeTimer()
	if not (GetWorldElapsedTimers and GetWorldElapsedTime and Enum and Enum.WorldElapsedTimerTypes) then return nil end
	local timers = { GetWorldElapsedTimers() }
	for index = 1, #timers do
		local timerID = timers[index]
		local ok, _, elapsedTime, timerType = pcall(GetWorldElapsedTime, timerID)
		if ok and timerType == Enum.WorldElapsedTimerTypes.ChallengeMode then return timerID, tonumber(elapsedTime) or 0 end
	end
	return nil
end

local function createDurationObject()
	local durationUtil = _G.C_DurationUtil
	return durationUtil and durationUtil.CreateDuration and durationUtil.CreateDuration() or nil
end

local function getDurationTextBindingProperty(property)
	local enum = _G.Enum and _G.Enum.DurationTextBindingProperty or nil
	if enum and enum[property] ~= nil then return enum[property] end
	if property == "RemainingDuration" then return 0 end
	if property == "ElapsedDuration" then return 2 end
	if property == "TotalDuration" then return 4 end
	return nil
end

local function getNumericRoundingDown()
	local enum = _G.Enum and _G.Enum.NumericRuleFormatRounding or nil
	return enum and enum.Down or 2
end

local function createTimerNumericFormatter()
	local stringUtil = _G.C_StringUtil
	if not (stringUtil and stringUtil.CreateNumericRuleFormatter) then return nil end
	local formatter = stringUtil.CreateNumericRuleFormatter()
	if formatter.ClearBreakpoints then formatter:ClearBreakpoints() end
	local down = getNumericRoundingDown()
	local breakpoints = {
		{
			threshold = 0,
			step = 1,
			rounding = down,
			format = "%d:%02d",
			components = {
				{ div = 60, step = 1, rounding = down },
				{ mod = 60, step = 1, rounding = down },
			},
		},
	}
	if formatter.SetBreakpoints then
		formatter:SetBreakpoints(breakpoints)
	elseif formatter.AddBreakpoint then
		for i = 1, #breakpoints do
			formatter:AddBreakpoint(breakpoints[i])
		end
	end
	return formatter
end

local function getChallengeStartTime(timer, state)
	if state and state.active and timer.timerBaseTime and timer.timerBaseElapsed then return timer.timerBaseTime - timer.timerBaseElapsed end
	local now = GetTime and GetTime() or 0
	return now - (tonumber(state and state.elapsed) or 0)
end

local function getActiveKeystoneInfo()
	local level, affixes, mapID
	if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
		local ok, a, b, c = pcall(C_ChallengeMode.GetActiveKeystoneInfo)
		if ok then
			level = a
			affixes = type(b) == "table" and b or nil
			mapID = c
		end
	end
	if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
		local ok, activeMapID = pcall(C_ChallengeMode.GetActiveChallengeMapID)
		if ok and activeMapID and activeMapID > 0 then mapID = activeMapID end
	end
	return tonumber(level) or 0, affixes or {}, tonumber(mapID)
end

local function getMapInfo(mapID)
	if not (mapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo) then return nil, nil end
	local ok, name, _, timeLimit = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
	if ok then return name, tonumber(timeLimit) end
	return nil, nil
end

local function calculateChestTimers(maxTime, affixes)
	local twoChest = maxTime * 0.8
	local threeChest = maxTime * 0.6
	for _, affixID in ipairs(affixes or {}) do
		if affixID == CHALLENGERS_PERIL_AFFIX_ID then
			local adjusted = maxTime - 90
			twoChest = adjusted * 0.8 + 90
			threeChest = adjusted * 0.6 + 90
			break
		end
	end
	return twoChest, threeChest
end

local function getDeathInfo()
	if C_ChallengeMode and C_ChallengeMode.GetDeathCount then
		local ok, deaths, timeLost = pcall(C_ChallengeMode.GetDeathCount)
		if ok then return tonumber(deaths) or 0, tonumber(timeLost) or 0 end
	end
	return 0, 0
end

local function isSecretValue(value)
	return issecretvalue and issecretvalue(value)
end

local function getCompletionElapsed()
	if not (C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo) then return nil end
	local ok, info = pcall(C_ChallengeMode.GetChallengeCompletionInfo)
	if not ok or type(info) ~= "table" or isSecretValue(info.time) then return nil end
	local completionTime = tonumber(info.time)
	if completionTime and completionTime > 0 then return completionTime / 1000 end
	return nil
end

local function getCompletionInfo()
	if not (C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo) then return nil end
	local ok, info = pcall(C_ChallengeMode.GetChallengeCompletionInfo)
	if ok and type(info) == "table" then return info end
	return nil
end

local function getCompletionNumber(info, key)
	if not (type(info) == "table" and key) then return nil end
	local value = info[key]
	if isSecretValue(value) then return nil end
	return tonumber(value)
end

local function getNameFromUnit(unit)
	if not UnitName then return nil end
	local name, server = UnitName(unit)
	if isSecretValue(name) or isSecretValue(server) then return nil end
	if not name or name == "" then return nil end
	if server and server ~= "" then return name .. "-" .. server end
	return name
end

local function getNameFromGUID(guid)
	if not UnitNameFromGUID then return nil end
	local ok, name, server = pcall(UnitNameFromGUID, guid)
	if not ok or isSecretValue(name) or isSecretValue(server) then return nil end
	if not name or name == "" then return nil end
	if server and server ~= "" then return name .. "-" .. server end
	return name
end

local function getClassFromUnit(unit)
	if not UnitClass then return nil end
	local _, classFile = UnitClass(unit)
	if not isSecretValue(classFile) then return classFile end
	return nil
end

local function getClassFromGUID(guid)
	if not UnitClassFromGUID then return nil end
	local ok, _, classFile = pcall(UnitClassFromGUID, guid)
	if ok and not isSecretValue(classFile) then return classFile end
	return nil
end

local function getCriteriaInfo(index)
	if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
		local ok, info = pcall(C_ScenarioInfo.GetCriteriaInfo, index)
		if ok and type(info) == "table" then return info end
	end
	return nil
end

local function getScenarioInfo()
	if C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo then
		local ok, info = pcall(C_ScenarioInfo.GetScenarioStepInfo)
		if ok and type(info) == "table" then return info end
	end
	return nil
end

local function parseCriteriaQuantityString(value)
	if type(value) ~= "string" or value == "" then return nil end
	local normalized = value:gsub(",", ".")
	local raw = normalized:match("[-+]?%d+%.?%d*") or normalized:match("[-+]?%.%d+")
	return raw and tonumber(raw) or nil
end

local function getWeightedCriteriaProgress(info)
	if not (info and info.isWeightedProgress) then return nil, nil end
	local quantityFromString = parseCriteriaQuantityString(info.quantityString)
	local quantity = quantityFromString or tonumber(info.quantity) or 0
	local total = tonumber(info.totalQuantity) or 0
	local percent
	if quantityFromString and total > 0 then
		percent = quantityFromString / total * 100
	else
		percent = tonumber(info.quantity)
	end
	if percent then percent = math.floor(percent * 100 + 0.5) / 100 end
	return quantity, percent
end

local function getObjectiveData()
	local stepInfo = getScenarioInfo()
	local objectives, enemyForces = {}, nil
	local count = tonumber(stepInfo and stepInfo.numCriteria) or 0
	for index = 1, count do
		local info = getCriteriaInfo(index)
		if info then
			local description = info.description or info.criteriaString or ""
			local quantity = tonumber(info.quantity) or 0
			local total = tonumber(info.totalQuantity) or 0
			local percent
			if info.isWeightedProgress then
				quantity, percent = getWeightedCriteriaProgress(info)
			elseif total > 0 then
				percent = quantity / total * 100
			end
			local objective = {
				text = description,
				quantity = quantity,
				total = total,
				percent = percent,
				completed = info.completed == true,
				isBoss = not info.isWeightedProgress and total == 1,
			}
			if info.isWeightedProgress or description == _G.SCENARIO_CRITERIA_UNKNOWN or tostring(description):lower():find("enemy forces", 1, true) then
				enemyForces = objective
			else
				objectives[#objectives + 1] = objective
			end
		end
	end
	return objectives, enemyForces
end

local function cloneTable(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, entry in pairs(value) do
		copy[key] = cloneTable(entry)
	end
	return copy
end

function Timer:IsEnabled()
	return self:Get("enabled") == true
end

function Timer:Get(key, fallback)
	return getTimerConfigValue(key, fallback == nil and defaults[key] or fallback)
end

function Timer:GetLayoutMode()
	local mode = self:Get("layoutMode")
	if mode == "LIST" or mode == "PANEL" or mode == "FLOW" then return mode end
	return defaults.layoutMode
end

function Timer:Set(key, value)
	if not addon.db or defaults[key] == nil then return end
	local config = getTimerConfig(true)
	config[key] = value
	self.panelBackdropReferenceReady = nil
	self:EnsurePanelBackdropReference()
	if key == "enabled" then
		self:UpdateEventState()
		return
	end
	self:Refresh()
end

-- The footer has one content slot. Selecting deaths there temporarily overrides,
-- but does not discard, the stored row/header preference.
function Timer:GetListFooterContent()
	local content = self:Get("footerContent")
	if content == "TIMER" or content == "DEATHS" or content == "ENEMY_FORCES" then return content end
	return "NONE"
end

function Timer:GetListDeathPlacement()
	if self:GetListFooterContent() == "DEATHS" then return "FOOTER" end
	return self:Get("deathPlacement") == "HEADER" and "HEADER" or "ROW"
end

function Timer:SyncActiveTimerBase(force)
	local timerID, elapsed = getActiveChallengeTimer()
	if not timerID then
		self.activeTimerID = nil
		self.timerBaseElapsed = nil
		self.timerBaseTime = nil
		return nil
	end
	if force or self.activeTimerID ~= timerID or not self.timerBaseElapsed or not self.timerBaseTime then
		self.activeTimerID = timerID
		self.timerBaseElapsed = elapsed or 0
		self.timerBaseTime = GetTime and GetTime() or 0
	end
	return timerID
end

function Timer:ResolveRunState()
	local timerID = self:SyncActiveTimerBase(false)
	local active = timerID ~= nil
	local elapsed = 0
	if active then
		elapsed = (self.timerBaseElapsed or 0) + math.max(0, (GetTime and GetTime() or 0) - (self.timerBaseTime or 0))
		local _, authoritativeElapsed = getActiveChallengeTimer()
		if authoritativeElapsed and math.abs(authoritativeElapsed - elapsed) > 2 then
			self.timerBaseElapsed = authoritativeElapsed
			self.timerBaseTime = GetTime and GetTime() or 0
			elapsed = authoritativeElapsed
		end
		self.lastRunElapsed = elapsed
	elseif self.completedElapsed then
		elapsed = self.completedElapsed
	end
	local level, affixes, mapID = getActiveKeystoneInfo()
	if not active and self.completedInfo then
		level = getCompletionNumber(self.completedInfo, "level") or level
		mapID = getCompletionNumber(self.completedInfo, "mapChallengeModeID") or mapID
	end
	if not active and self.lastRunInfo then
		if not level or level <= 0 then level = tonumber(self.lastRunInfo.level) or level end
		if not mapID then mapID = tonumber(self.lastRunInfo.mapID) end
		if type(affixes) ~= "table" or #affixes == 0 then affixes = self.lastRunInfo.affixes or affixes end
	end
	local mapName, timeLimit = getMapInfo(mapID)
	if (not mapName or mapName == "") and self.lastRunInfo then mapName = self.lastRunInfo.mapName end
	if (not timeLimit or timeLimit <= 0) and self.lastRunInfo then timeLimit = self.lastRunInfo.timeLimit end
	return {
		active = active,
		completed = not active and self.completedElapsed ~= nil,
		timerID = timerID,
		level = level,
		affixes = affixes,
		mapID = mapID,
		mapName = mapName,
		timeLimit = timeLimit or 1800,
		elapsed = math.max(0, elapsed or 0),
	}
end

function Timer:GetPreviewState()
	local now = GetTime and GetTime() or 0
	local elapsed = 520 + (now % 260)
	local enemyPercent = 34 + (now * 8 % 48)
	return {
		active = true,
		preview = true,
		level = 12,
		mapID = 503,
		mapName = L["mythicPlusTimerPreviewDungeon"] or "Ara-Kara, City of Echoes",
		timeLimit = 1800,
		elapsed = elapsed,
		affixNames = { "Fortified", "Entangled", "Bursting" },
		affixIcons = { 136265, 132308, 136214 },
		deaths = 3,
		timeLost = 45,
		deathMembers = {
			{ name = "GroupMember2", class = "MAGE", count = 2 },
			{ name = "GroupMember5", class = "SHAMAN", count = 1 },
		},
		objectives = {
			{ text = L["mythicPlusTimerPreviewObjectiveBosses"] or "Defeat bosses", quantity = 2, total = 4, percent = 50, completed = false, splitTime = 612, bestTime = 580, isBoss = true },
			{ text = L["mythicPlusTimerPreviewObjectiveRescue"] or "Rescue captives", quantity = 6, total = 6, percent = 100, completed = true, splitTime = 494, bestTime = 510 },
			{ text = L["mythicPlusTimerPreviewObjectiveRelics"] or "Recover relics", quantity = 1, total = 3, percent = 33, completed = false },
		},
		enemyForces = { text = L["mythicPlusTimerEnemyForces"] or "Enemy Forces", quantity = math.floor(enemyPercent), total = 100, percent = enemyPercent, completed = false, splitTime = 760, bestTime = 735 },
	}
end

function Timer:BuildState()
	if self:IsInEditMode() and not isInMythicPlus() then return self:GetPreviewState() end
	local state = self:ResolveRunState()
	local objectives, enemyForces = getObjectiveData()
	local deaths, timeLost = getDeathInfo()
	self:ReconcileDeathCount(deaths)
	if state.active then
		self.lastRunInfo = {
			level = state.level,
			affixes = cloneTable(state.affixes),
			mapID = state.mapID,
			mapName = state.mapName,
			timeLimit = state.timeLimit,
		}
		self.lastObjectives = cloneTable(objectives)
		self.lastEnemyForces = cloneTable(enemyForces)
	elseif state.completed then
		if (not objectives or #objectives == 0) and type(self.lastObjectives) == "table" then objectives = cloneTable(self.lastObjectives) end
		if not enemyForces then enemyForces = cloneTable(self.lastEnemyForces) end
		if enemyForces then
			enemyForces.percent = 100
			enemyForces.quantity = enemyForces.total or enemyForces.quantity or 100
			enemyForces.total = enemyForces.total or 100
			enemyForces.completed = true
		else
			enemyForces = { text = L["mythicPlusTimerEnemyForces"] or "Enemy Forces", quantity = 100, total = 100, percent = 100, completed = true }
		end
	end
	state.objectives = objectives
	state.enemyForces = enemyForces
	state.deaths = deaths
	state.timeLost = timeLost
	state.deathMembers = self:GetDeathMembers()
	state.affixNames = {}
	state.affixIcons = {}
	for _, affixID in ipairs(state.affixes or {}) do
		local name
		local icon
		if C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
			local ok, affixName, _, affixIcon = pcall(C_ChallengeMode.GetAffixInfo, affixID)
			if ok then
				name = affixName
				icon = affixIcon
			end
		end
		state.affixNames[#state.affixNames + 1] = name or tostring(affixID)
		state.affixIcons[#state.affixIcons + 1] = icon
	end
	return state
end

function Timer:ResetDeathTracking()
	self.groupMembersByGUID = {}
	self.aliveMembersByGUID = {}
	self.deadMemberGuids = {}
	self.deathDetails = {}
	self.deathCountSeen = 0
end

function Timer:ForEachGroupUnit(callback)
	if type(callback) ~= "function" then return end
	callback("player")
	if IsInRaid and IsInRaid() then
		local count = GetNumGroupMembers and GetNumGroupMembers() or 0
		for index = 1, count do
			callback("raid" .. index)
		end
	elseif IsInGroup and IsInGroup() then
		for index = 1, 4 do
			callback("party" .. index)
		end
	end
end

function Timer:RefreshGroupRoster()
	self.groupMembersByGUID = self.groupMembersByGUID or {}
	self.aliveMembersByGUID = self.aliveMembersByGUID or {}
	self.deadMemberGuids = self.deadMemberGuids or {}
	for guid in pairs(self.groupMembersByGUID) do
		self.groupMembersByGUID[guid] = nil
	end
	self:ForEachGroupUnit(function(unit)
		local guid = UnitGUID and UnitGUID(unit)
		if not guid or isSecretValue(guid) then return end
		self.groupMembersByGUID[guid] = true
		if UnitIsDeadOrGhost and not UnitIsDeadOrGhost(unit) then
			self.aliveMembersByGUID[guid] = {
				name = getNameFromUnit(unit) or getNameFromGUID(guid) or tostring(guid),
				class = getClassFromUnit(unit) or getClassFromGUID(guid),
			}
			self.deadMemberGuids[guid] = nil
		end
	end)
end

function Timer:AddDeathDetail(guid, unit)
	if not guid or isSecretValue(guid) then return end
	self.deadMemberGuids = self.deadMemberGuids or {}
	if self.deadMemberGuids[guid] then return end
	local aliveInfo = self.aliveMembersByGUID and self.aliveMembersByGUID[guid]
	self.deathDetails = self.deathDetails or {}
	self.deathDetails[#self.deathDetails + 1] = {
		time = tonumber(self.lastState and self.lastState.elapsed) or 0,
		name = (unit and getNameFromUnit(unit)) or (aliveInfo and aliveInfo.name) or getNameFromGUID(guid) or tostring(guid),
		class = (unit and getClassFromUnit(unit)) or (aliveInfo and aliveInfo.class) or getClassFromGUID(guid),
	}
	self.deadMemberGuids[guid] = true
	if self.aliveMembersByGUID then self.aliveMembersByGUID[guid] = nil end
	return true
end

function Timer:TrackUnitDied(guid)
	if not guid or isSecretValue(guid) or not isInMythicPlus() then return end
	if not self:SyncActiveTimerBase(false) then return end
	if not self.groupMembersByGUID or not self.groupMembersByGUID[guid] then self:RefreshGroupRoster() end
	if not (self.groupMembersByGUID and self.groupMembersByGUID[guid]) then return end
	return self:AddDeathDetail(guid)
end

function Timer:ReconcileDeathCount(deaths)
	deaths = tonumber(deaths) or 0
	if not self.deathCountSeen then
		self.deathCountSeen = deaths
		self:RefreshGroupRoster()
		return
	end
	if deaths <= self.deathCountSeen then
		self.deathCountSeen = deaths
		self:RefreshGroupRoster()
		return
	end
	local remaining = deaths - self.deathCountSeen
	if not self.aliveMembersByGUID then self:RefreshGroupRoster() end
	self:ForEachGroupUnit(function(unit)
		if remaining <= 0 then return end
		local guid = UnitGUID and UnitGUID(unit)
		if not guid or isSecretValue(guid) then return end
		if self.aliveMembersByGUID and self.aliveMembersByGUID[guid] and UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
			if self:AddDeathDetail(guid, unit) then remaining = remaining - 1 end
		end
	end)
	self.deathCountSeen = deaths
	self:RefreshGroupRoster()
end

function Timer:GetDeathMembers()
	local countTable = {}
	for _, entry in ipairs(self.deathDetails or {}) do
		local name = entry.name or ""
		if name ~= "" then
			local count = countTable[name]
			if not count then
				count = {
					name = name,
					class = entry.class,
					count = 0,
				}
				countTable[name] = count
			end
			count.count = count.count + 1
			count.class = count.class or entry.class
		end
	end
	local result = {}
	for _, entry in pairs(countTable) do
		result[#result + 1] = entry
	end
	table.sort(result, function(left, right)
		if left.count ~= right.count then return left.count > right.count end
		return tostring(left.name or "") < tostring(right.name or "")
	end)
	return result
end

function Timer:GetAffixDisplayText(state)
	local names = state and state.affixNames
	if type(names) ~= "table" or #names == 0 then return "" end
	local mode = self:Get("affixDisplay")
	if mode ~= "ICON" and mode ~= "ICON_TEXT" and mode ~= "TEXT" then
		mode = self:Get("showAffixIcons") and "ICON_TEXT" or "TEXT"
	end
	if mode == "TEXT" then return table.concat(names, " - ") end
	local parts = {}
	for index, name in ipairs(names) do
		local icon = state.affixIcons and state.affixIcons[index]
		if icon then
			parts[#parts + 1] = mode == "ICON" and string.format("|T%s:16:16:0:0|t", tostring(icon)) or string.format("|T%s:14:14:0:0|t %s", tostring(icon), name)
		else
			parts[#parts + 1] = name
		end
	end
	return table.concat(parts, mode == "ICON" and " " or " - ")
end

function Timer:GetSingleAffixDisplayText(state, index, iconSize)
	local name = state and state.affixNames and state.affixNames[index]
	if not name then return "" end
	local icon = state.affixIcons and state.affixIcons[index]
	local mode = self:Get("affixDisplay")
	if mode ~= "ICON" and mode ~= "ICON_TEXT" and mode ~= "TEXT" then mode = self:Get("showAffixIcons") and "ICON_TEXT" or "TEXT" end
	if mode == "TEXT" or not icon then return name end
	iconSize = clampNumber(iconSize, 8, 64, defaults.panelAffixIconSize or 16)
	if mode == "ICON" then return string.format("|T%s:%d:%d:0:0|t", tostring(icon), iconSize, iconSize) end
	return string.format("|T%s:%d:%d:0:0|t %s", tostring(icon), iconSize, iconSize, name)
end

function Timer:GetDeathDisplayText(deaths, iconSize, timeLost)
	deaths = tonumber(deaths) or 0
	local mode = self:Get("deathDisplay")
	iconSize = clampNumber(iconSize, 8, 64, 16)
	local suffix = ""
	if self:Get("deathShowTimeLost") == true and tonumber(timeLost) and tonumber(timeLost) > 0 then suffix = string.format(" (+%s)", secondsToShortText(timeLost)) end
	if mode == "ICON" then return string.format("|A:%s:%d:%d|a %d%s", DEATH_ICON_ATLAS, iconSize, iconSize, deaths, suffix) end
	if mode == "ICON_TEXT" then return string.format("|A:%s:%d:%d|a %d %s%s", DEATH_ICON_ATLAS, iconSize, iconSize, deaths, L["mythicPlusTimerDeaths"] or "Deaths", suffix) end
	return string.format("%d %s%s", deaths, L["mythicPlusTimerDeaths"] or "Deaths", suffix)
end

function Timer:GetTimerDisplayText(state, timeLeft)
	state = state or {}
	local mode = self:Get("timerDisplay")
	local elapsed = tonumber(state.elapsed) or 0
	local total = tonumber(state.timeLimit) or 0
	if state.completed then
		if mode == "TOTAL" then return secondsToText(total) end
		if mode == "TIME_LEFT_TOTAL" or mode == "ELAPSED_TOTAL" then return string.format("%s / %s", secondsToText(elapsed), secondsToText(total)) end
		return secondsToText(elapsed)
	end
	if mode == "TOTAL" then return secondsToText(total) end
	if mode == "TIME_LEFT_TOTAL" then return string.format("%s / %s", timeRemainingToText(timeLeft), secondsToText(total)) end
	if mode == "ELAPSED_TOTAL" then return string.format("%s / %s", secondsToText(elapsed), secondsToText(total)) end
	return timeRemainingToText(timeLeft)
end

function Timer:GetTimerDurationObject(key)
	self.durationObjects = self.durationObjects or {}
	local durationObject = self.durationObjects[key]
	if not durationObject then
		durationObject = createDurationObject()
		self.durationObjects[key] = durationObject
	end
	return durationObject
end

function Timer:UpdateTimerDurationObject(key, startTime, duration)
	startTime = tonumber(startTime)
	duration = tonumber(duration)
	if not (key and startTime and duration and duration > 0) then return nil end
	local durationObject = self:GetTimerDurationObject(key)
	if not (durationObject and durationObject.SetTimeFromStart) then return nil end
	local signature = string.format("%.3f:%.3f", startTime, duration)
	self.durationObjectSignatures = self.durationObjectSignatures or {}
	if self.durationObjectSignatures[key] ~= signature then
		durationObject:SetTimeFromStart(startTime, duration, 1)
		self.durationObjectSignatures[key] = signature
	end
	return durationObject
end

function Timer:GetTimerNumericFormatter()
	if not self.timerNumericFormatter then self.timerNumericFormatter = createTimerNumericFormatter() end
	return self.timerNumericFormatter
end

function Timer:CreateTimerFormatComponent(property)
	local resolvedProperty = getDurationTextBindingProperty(property)
	local formatter = self:GetTimerNumericFormatter()
	if resolvedProperty == nil or not formatter then return nil end
	return {
		property = resolvedProperty,
		formatter = formatter,
	}
end

function Timer:GetDurationTextComponents(mode)
	if mode == "TIME_LEFT_TOTAL" then
		return {
			self:CreateTimerFormatComponent("RemainingDuration"),
			self:CreateTimerFormatComponent("TotalDuration"),
		}
	end
	if mode == "ELAPSED_TOTAL" then
		return {
			self:CreateTimerFormatComponent("ElapsedDuration"),
			self:CreateTimerFormatComponent("TotalDuration"),
		}
	end
	if mode == "TOTAL" then
		return {
			self:CreateTimerFormatComponent("TotalDuration"),
		}
	end
	return {
		self:CreateTimerFormatComponent("RemainingDuration"),
	}
end

function Timer:BindTimerText(fontString, key, durationObject, mode, textFormat)
	if not (fontString and durationObject and addon.functions and addon.functions.BindDurationText) then return false end
	local formatter = self:GetTimerNumericFormatter()
	if not formatter then return false end
	local options = {
		owner = self:EnsureFrame(),
		key = key,
		clearText = false,
		expiredText = "",
		formatter = formatter,
		zeroDurationText = "",
		updateNow = true,
		-- M+ timer text is always m:ss; Duration Text profiles only apply to user-configurable cooldown displays.
		useProfileConfig = false,
	}
	if mode == "TIME_LEFT_TOTAL" or mode == "ELAPSED_TOTAL" then
		local components = self:GetDurationTextComponents(mode)
		if components and components[1] and components[2] then
			options.textFormat = "{} / {}"
			options.components = components
		end
	elseif mode == "TOTAL" then
		local components = self:GetDurationTextComponents("TOTAL")
		if components and components[1] then
			options.textFormat = "{}"
			options.components = components
		end
	elseif textFormat then
		local components = self:GetDurationTextComponents("REMAINING")
		if components and components[1] then
			options.textFormat = textFormat
			options.components = components
		end
	end
	local _, ok = addon.functions.BindDurationText(fontString, durationObject, options)
	return ok == true
end

function Timer:ReleaseTimerTextBinding(key)
	local durationText = addon.DurationText
	if durationText and durationText.ReleaseBinding then durationText:ReleaseBinding(self:EnsureFrame(), key, false) end
end

function Timer:SetBoundTimerText(key, fallbackText, anchorKey, xKey, yKey, color, fontSize, justify, state, duration, mode, textFormat)
	local text = self:SetPanelText(key, fallbackText, anchorKey, xKey, yKey, color, fontSize, justify)
	local bindingKey = "panel-" .. key
	if not (state and state.active) then
		self:ReleaseTimerTextBinding(bindingKey)
		return text
	end
	local elapsed = tonumber(state.elapsed) or 0
	duration = tonumber(duration) or 0
	if duration <= 0 or elapsed >= duration then
		self:ReleaseTimerTextBinding(bindingKey)
		return text
	end
	local durationObject = self:UpdateTimerDurationObject(key, getChallengeStartTime(self, state), duration)
	if not (durationObject and self:BindTimerText(text, bindingKey, durationObject, mode, textFormat)) then self:ReleaseTimerTextBinding(bindingKey) end
	return text
end

local function normalizeDungeonAbbreviation(label, mapName)
	if type(label) ~= "string" or label == "" then return nil end
	if type(mapName) == "string" and mapName ~= "" and label:lower() == mapName:lower() then return nil end
	return label
end

function Timer:GetDungeonAbbreviation(state)
	if not state then return nil end
	local mapID = tonumber(state.mapID)
	local mapLabels = addon.MythicPlus and addon.MythicPlus.variables and addon.MythicPlus.variables.challengeMapID
	if mapID and type(mapLabels) == "table" then
		local label = normalizeDungeonAbbreviation(mapLabels[mapID] or mapLabels[tostring(mapID)], state.mapName)
		if label then return label end
	end
	local compendium = addon.MythicPlus and addon.MythicPlus.variables and addon.MythicPlus.variables.portalCompendium
	if mapID and type(compendium) == "table" then
		for _, section in pairs(compendium) do
			for _, data in pairs(section.spells or {}) do
				if type(data.cId) == "table" and data.cId[mapID] and data.text then
					local label = normalizeDungeonAbbreviation(data.textID and data.textID[mapID] or data.text, state.mapName)
					if label then return label end
				end
			end
		end
	end
	return nil
end

function Timer:GetDungeonDisplayText(state)
	state = state or {}
	local name = state.mapName or (L["mythicPlusTimerUnknownDungeon"] or "Mythic+ Dungeon")
	local short = self:GetDungeonAbbreviation(state) or name
	local level = tonumber(state.level) or 0
	local mode = self:Get("dungeonDisplay")
	if mode == "LEVEL" then return string.format("+%d", level) end
	if mode == "NAME" then return name end
	if mode == "SHORT" then return short end
	if mode == "SHORT_LEVEL" then return string.format("+%d - %s", level, short) end
	return string.format("+%d - %s", level, name)
end

function Timer:EnsureFrame()
	if self.frame then return self.frame end
	local frame = CreateFrame("Frame", "EnhanceQoLMythicPlusTimerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(defaults.width, 120)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame.rows = {}
	frame.panelStyleBounds = CreateFrame("Frame", nil, frame)
	frame.panelStyleBounds:SetAllPoints(frame)
	frame.panelStyleBounds:EnableMouse(false)
	frame.panelBackdropBounds = CreateFrame("Frame", nil, frame)
	frame.panelBackdropBounds:SetAllPoints(frame)
	frame.panelBackdropBounds:EnableMouse(false)
	frame.windowBackground = frame:CreateTexture(nil, "BACKGROUND")
	frame.windowBackground:SetDrawLayer("BACKGROUND", -8)
	frame.windowBackground:Hide()
	frame.decorBars = {}
	frame.decorBars.header = frame:CreateTexture(nil, "BORDER")
	frame.decorBars.header:SetDrawLayer("BORDER", 2)
	frame.decorBars.header:Hide()
	frame.decorBars.footer = frame:CreateTexture(nil, "BORDER")
	frame.decorBars.footer:SetDrawLayer("BORDER", 2)
	frame.decorBars.footer:Hide()
	frame.decorContent = {}
	frame.borderFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	frame.borderFrame:EnableMouse(false)
	frame.borderFrame:Hide()
	frame.panelTextFrame = CreateFrame("Frame", nil, frame)
	frame.panelTextFrame:SetAllPoints(frame)
	frame.panelTextFrame:EnableMouse(false)
	frame.panelTextFrame:SetFrameLevel(frame:GetFrameLevel() + 40)
	frame:Hide()
	self.frame = frame
	return frame
end

function Timer:GetDynamicAnchorWinner()
	return addon.DynamicAnchors and addon.DynamicAnchors:GetSimpleFrameWinner(self.dynamicAnchorId) or nil
end

function Timer:ApplyDynamicAnchor()
	if not self.frame then return false end
	local winner = self:GetDynamicAnchorWinner()
	if not (winner and winner.frame) then return false end
	local placement = winner.placement or {}
	local point = placement.point or "CENTER"
	local relativePoint = placement.relativePoint or point
	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, winner.frame, relativePoint, tonumber(placement.x) or 0, tonumber(placement.y) or 0)
	return true
end

function Timer:EnsureRow(index)
	local frame = self:EnsureFrame()
	if frame.rows[index] then return frame.rows[index] end
	local row = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	row:SetHeight(defaults.rowHeight)
	row:EnableMouse(true)
	row:SetScript("OnEnter", function(rowFrame) Timer:ShowRowTooltip(rowFrame) end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetDrawLayer("ARTWORK", 1)
	row.icon:SetSize(defaults.rowHeight, defaults.rowHeight)
	row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
	row.bar = CreateFrame("StatusBar", nil, row, BackdropTemplateMixin and "BackdropTemplate")
	row.bar:SetFrameLevel(math.max(0, row:GetFrameLevel() - 1))
	row.bar:SetHeight(defaults.rowHeight)
	row.bar:SetMinMaxValues(0, 100)
	row.bar:SetValue(0)
	row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
	row.bar.bg:SetDrawLayer("BACKGROUND", -7)
	row.bar.bg:SetAllPoints()
	row.bar.borderFrame = CreateFrame("Frame", nil, row, BackdropTemplateMixin and "BackdropTemplate")
	row.bar.borderFrame:EnableMouse(false)
	row.bar.borderFrame:Hide()
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.text:SetDrawLayer("OVERLAY", 7)
	row.text:SetJustifyH("LEFT")
	row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.value:SetDrawLayer("OVERLAY", 7)
	row.value:SetJustifyH("RIGHT")
	frame.rows[index] = row
	return row
end

function Timer:EnsureDecorContent(kind)
	local frame = self:EnsureFrame()
	frame.decorContent = frame.decorContent or {}
	if frame.decorContent[kind] then return frame.decorContent[kind] end
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetFrameLevel(frame:GetFrameLevel() + 40)
	holder:EnableMouse(true)
	holder:SetScript("OnEnter", function(holderFrame) Timer:ShowRowTooltip(holderFrame) end)
	holder:SetScript("OnLeave", GameTooltip_Hide)
	holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	holder.text:SetDrawLayer("OVERLAY", 7)
	holder.text:SetJustifyH("LEFT")
	holder.value = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	holder.value:SetDrawLayer("OVERLAY", 7)
	holder.value:SetJustifyH("RIGHT")
	holder:Hide()
	frame.decorContent[kind] = holder
	return holder
end

function Timer:EnsurePanelText(key)
	local frame = self:EnsureFrame()
	frame.panelTexts = frame.panelTexts or {}
	if frame.panelTexts[key] then return frame.panelTexts[key] end
	local parent = frame.panelTextFrame or frame
	local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetDrawLayer("OVERLAY", 7)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	frame.panelTexts[key] = text
	return text
end

function Timer:EnsurePanelHover(key)
	local frame = self:EnsureFrame()
	frame.panelHovers = frame.panelHovers or {}
	if frame.panelHovers[key] then return frame.panelHovers[key] end
	local hover = CreateFrame("Frame", nil, frame)
	hover:EnableMouse(true)
	hover:SetFrameLevel(frame:GetFrameLevel() + 25)
	hover:SetScript("OnEnter", function(hoverFrame) Timer:ShowPanelTooltip(hoverFrame) end)
	hover:SetScript("OnLeave", GameTooltip_Hide)
	frame.panelHovers[key] = hover
	return hover
end

function Timer:EnsurePanelAffix(index)
	local frame = self:EnsureFrame()
	frame.panelAffixes = frame.panelAffixes or {}
	if frame.panelAffixes[index] then return frame.panelAffixes[index] end
	local item = CreateFrame("Frame", nil, frame)
	item:EnableMouse(true)
	item:SetFrameLevel(frame:GetFrameLevel() + 25)
	item:SetScript("OnEnter", function(itemFrame) Timer:ShowPanelTooltip(itemFrame) end)
	item:SetScript("OnLeave", GameTooltip_Hide)
	item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	item.text:SetDrawLayer("OVERLAY", 7)
	item.text:SetJustifyH("LEFT")
	item.text:SetJustifyV("TOP")
	frame.panelAffixes[index] = item
	return item
end

function Timer:EnsurePanelAffixSeparator(index)
	local frame = self:EnsureFrame()
	frame.panelAffixSeparators = frame.panelAffixSeparators or {}
	if frame.panelAffixSeparators[index] then return frame.panelAffixSeparators[index] end
	local item = CreateFrame("Frame", nil, frame)
	item:EnableMouse(false)
	item:SetFrameLevel(frame:GetFrameLevel() + 24)
	item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	item.text:SetDrawLayer("OVERLAY", 7)
	item.text:SetJustifyH("CENTER")
	item.text:SetJustifyV("TOP")
	frame.panelAffixSeparators[index] = item
	return item
end

function Timer:EnsurePanelObjective(index)
	local frame = self:EnsureFrame()
	frame.panelObjectives = frame.panelObjectives or {}
	if frame.panelObjectives[index] then return frame.panelObjectives[index] end
	local item = CreateFrame("Frame", nil, frame)
	item:EnableMouse(true)
	item:SetFrameLevel(frame:GetFrameLevel() + 25)
	item:SetScript("OnEnter", function(itemFrame) Timer:ShowPanelTooltip(itemFrame) end)
	item:SetScript("OnLeave", GameTooltip_Hide)
	item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	item.text:SetDrawLayer("OVERLAY", 7)
	item.text:SetJustifyH("LEFT")
	item.text:SetJustifyV("TOP")
	item.value = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	item.value:SetDrawLayer("OVERLAY", 7)
	item.value:SetJustifyH("RIGHT")
	item.value:SetJustifyV("TOP")
	frame.panelObjectives[index] = item
	return item
end

function Timer:EnsurePanelBar(key)
	local frame = self:EnsureFrame()
	frame.panelBars = frame.panelBars or {}
	if frame.panelBars[key] then return frame.panelBars[key] end
	local bar = CreateFrame("StatusBar", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	bar.eqolBarKey = key
	bar:SetFrameLevel(frame:GetFrameLevel() + 2)
	bar:SetMinMaxValues(0, 100)
	bar:SetValue(0)
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetDrawLayer("BACKGROUND", -7)
	bar.bg:SetAllPoints()
	bar.textFrame = CreateFrame("Frame", nil, frame)
	bar.textFrame:SetFrameLevel(frame:GetFrameLevel() + 40)
	bar.text = bar.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bar.text:SetDrawLayer("OVERLAY", 9)
	bar.text:Hide()
	bar.text2 = bar.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bar.text2:SetDrawLayer("OVERLAY", 9)
	bar.text2:Hide()
	bar.timeLeftText = bar.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bar.timeLeftText:SetDrawLayer("OVERLAY", 9)
	bar.timeLeftText:Hide()
	bar.borderFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	bar.borderFrame:EnableMouse(false)
	bar.borderFrame:Hide()
	bar.chestMarkers = {}
	bar.chestMarkerTexts = {}
	bar.chestMarkerTextFrame = CreateFrame("Frame", nil, frame)
	bar.chestMarkerTextFrame:SetFrameLevel(frame:GetFrameLevel() + 40)
	for index = 1, 2 do
		local marker = bar:CreateTexture(nil, "OVERLAY")
		marker:SetColorTexture(1, 1, 1, 1)
		marker:Hide()
		bar.chestMarkers[index] = marker
		local markerText = bar.chestMarkerTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		markerText:SetDrawLayer("OVERLAY", 9)
		markerText:SetJustifyH("CENTER")
		markerText:Hide()
		bar.chestMarkerTexts[index] = markerText
	end
	frame.panelBars[key] = bar
	return bar
end

function Timer:ReleasePanelTimerBindings()
	if not self.frame then return end
	self:ReleaseTimerTextBinding("panel-timer")
	self:ReleaseTimerTextBinding("panel-chest2")
	self:ReleaseTimerTextBinding("panel-chest3")
	self:ReleaseTimerTextBinding("panel-bar-time-left")
	self:ReleaseTimerTextBinding("panel-bar-panelBarChest2")
	self:ReleaseTimerTextBinding("panel-bar-panelBarChest3")
end

function Timer:HidePanelElements(releaseBindings)
	local frame = self.frame
	if not frame then return end
	for _, text in pairs(frame.panelTexts or {}) do
		text:Hide()
	end
	for _, bar in pairs(frame.panelBars or {}) do
		bar:Hide()
		if bar.borderFrame then bar.borderFrame:Hide() end
		if bar.textFrame then bar.textFrame:Hide() end
		if bar.chestMarkerTextFrame then bar.chestMarkerTextFrame:Hide() end
		if bar.text then bar.text:Hide() end
		if bar.text2 then bar.text2:Hide() end
		if bar.timeLeftText then bar.timeLeftText:Hide() end
		for _, marker in ipairs(bar.chestMarkers or {}) do
			marker:Hide()
		end
		for _, markerText in ipairs(bar.chestMarkerTexts or {}) do
			markerText:Hide()
		end
	end
	for _, hover in pairs(frame.panelHovers or {}) do
		hover:Hide()
	end
	for _, item in pairs(frame.panelAffixes or {}) do
		item:Hide()
	end
	for _, item in pairs(frame.panelAffixSeparators or {}) do
		item:Hide()
	end
	for _, item in pairs(frame.panelObjectives or {}) do
		item:Hide()
	end
	if releaseBindings then
		self:ReleasePanelTimerBindings()
		self.panelBindingsActive = false
	end
end

function Timer:ApplyDecorBar(kind)
	local frame = self:EnsureFrame()
	local texture = frame.decorBars and frame.decorBars[kind]
	if not texture then return end
	local prefix = kind == "footer" and "footerBar" or "headerBar"
	local enabled = self:Get(prefix .. "Enabled") == true
	texture:SetShown(enabled)
	local anchor = normalizePoint(self:Get(prefix .. "Anchor"))
	local baseWidth = frame:GetWidth() or clampNumber(self:Get("width"), 120, 800, defaults.width)
	local baseHeight = kind == "footer" and DEFAULT_FOOTER_BAR_HEIGHT or DEFAULT_HEADER_BAR_HEIGHT
	local width = snapSize(baseWidth + clampNumber(self:Get(prefix .. "SizeOffsetX"), -1000, 1000, defaults[prefix .. "SizeOffsetX"]))
	local height = snapSize(baseHeight + clampNumber(self:Get(prefix .. "SizeOffsetY"), -300, 300, defaults[prefix .. "SizeOffsetY"]))
	local texturePoint = anchor
	local framePoint = anchor
	if kind == "header" then
		if anchor == "TOPLEFT" then
			texturePoint, framePoint = "BOTTOMLEFT", "TOPLEFT"
		elseif anchor == "TOP" then
			texturePoint, framePoint = "BOTTOM", "TOP"
		elseif anchor == "TOPRIGHT" then
			texturePoint, framePoint = "BOTTOMRIGHT", "TOPRIGHT"
		end
	elseif kind == "footer" then
		if anchor == "BOTTOMLEFT" then
			texturePoint, framePoint = "TOPLEFT", "BOTTOMLEFT"
		elseif anchor == "BOTTOM" then
			texturePoint, framePoint = "TOP", "BOTTOM"
		elseif anchor == "BOTTOMRIGHT" then
			texturePoint, framePoint = "TOPRIGHT", "BOTTOMRIGHT"
		end
	end
	texture:ClearAllPoints()
	texture:SetPoint(texturePoint, frame, framePoint, pointOffset(self:Get(prefix .. "OffsetX"), -1000, 1000, defaults[prefix .. "OffsetX"]), pointOffset(self:Get(prefix .. "OffsetY"), -1000, 1000, defaults[prefix .. "OffsetY"]))
	texture:SetSize(width, height)
	if not enabled then return end
	local textureKind, textureValue = getCustomTextureInfo(self:Get(prefix .. "UseCustomTexture") == true and self:Get(prefix .. "CustomTexture") or nil)
	if not textureKind then
		textureKind = "texture"
		textureValue = resolveMedia("statusbar", self:Get(prefix .. "Texture"), DEFAULT_BORDER)
	end
	local color = normalizeColor(self:Get(prefix .. "Color"), defaults[prefix .. "Color"])
	applyTexture(texture, textureKind, textureValue)
	texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

function Timer:GetStyleTarget()
	local frame = self:EnsureFrame()
	if self:Get("layoutMode") == "PANEL" and frame.panelStyleBounds then return frame.panelStyleBounds end
	return frame
end

function Timer:GetBackdropTarget()
	local frame = self:EnsureFrame()
	if self:Get("layoutMode") == "PANEL" and self.panelBackdropReferenceReady and frame.panelBackdropBounds then return frame.panelBackdropBounds end
	return self:GetStyleTarget()
end

function Timer:CapturePanelBackdropReference()
	local frame = self:EnsureFrame()
	local source = frame.panelStyleBounds
	local target = frame.panelBackdropBounds
	if not (source and target) then return false end
	local frameLeft, frameBottom = frame:GetLeft(), frame:GetBottom()
	local sourceLeft, sourceBottom, sourceRight, sourceTop = source:GetLeft(), source:GetBottom(), source:GetRight(), source:GetTop()
	if not (frameLeft and frameBottom and sourceLeft and sourceBottom and sourceRight and sourceTop) then return false end
	target:ClearAllPoints()
	target:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", snapToPixel(sourceLeft - frameLeft), snapToPixel(sourceBottom - frameBottom))
	target:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", snapToPixel(sourceRight - frameLeft), snapToPixel(sourceTop - frameBottom))
	self.panelBackdropReferenceReady = true
	return true
end

function Timer:UpdatePanelStyleBounds()
	local frame = self:EnsureFrame()
	local bounds = frame.panelStyleBounds
	if not bounds then return end
	bounds:ClearAllPoints()
	if self:Get("layoutMode") ~= "PANEL" then
		bounds:SetAllPoints(frame)
		return
	end

	local frameLeft, frameBottom = frame:GetLeft(), frame:GetBottom()
	local frameWidth, frameHeight = frame:GetSize()
	if not (frameLeft and frameBottom and frameWidth and frameHeight) then
		bounds:SetAllPoints(frame)
		return
	end
	local left, bottom, right, top = 0, 0, frameWidth, frameHeight
	local function includeRegion(region)
		if not (region and region.IsShown and region:IsShown()) then return end
		local regionLeft, regionBottom, regionRight, regionTop = region:GetLeft(), region:GetBottom(), region:GetRight(), region:GetTop()
		if not (regionLeft and regionBottom and regionRight and regionTop) then return end
		left = math.min(left, regionLeft - frameLeft)
		bottom = math.min(bottom, regionBottom - frameBottom)
		right = math.max(right, regionRight - frameLeft)
		top = math.max(top, regionTop - frameBottom)
	end
	for _, item in ipairs(frame.panelObjectives or {}) do
		includeRegion(item)
	end
	if self:Get("panelEnemyBarAttachToObjectives") == true then
		includeRegion(frame.panelBars and frame.panelBars.enemy)
	end
	bounds:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", snapToPixel(left), snapToPixel(bottom))
	bounds:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", snapToPixel(right), snapToPixel(top))
end

function Timer:ApplyWindowBackground()
	local frame = self:EnsureFrame()
	local target = self:GetBackdropTarget()
	local texture = frame.windowBackground
	if not texture then return end
	local enabled = self:Get("backdropEnabled") == true
	texture:SetShown(enabled)
	frame:SetBackdrop(nil)
	if not enabled then return end
	local textureKind, textureValue = getCustomTextureInfo(self:Get("backdropUseCustomTexture") == true and self:Get("backdropCustomTexture") or nil)
	if not textureKind then
		textureKind = "texture"
		textureValue = resolveMedia("statusbar", self:Get("backdropTexture"), DEFAULT_BORDER)
	end
	local color = normalizeColor(self:Get("backdropColor"), defaults.backdropColor)
	local anchor = normalizePoint(self:Get("backdropAnchor"))
	local baseWidth = target:GetWidth() or clampNumber(self:Get("width"), 120, 800, defaults.width)
	local baseHeight = target:GetHeight() or 120
	texture:ClearAllPoints()
	texture:SetPoint(anchor, target, anchor, pointOffset(self:Get("backdropOffsetX"), -1000, 1000, defaults.backdropOffsetX), pointOffset(self:Get("backdropOffsetY"), -1000, 1000, defaults.backdropOffsetY))
	texture:SetSize(snapSize(baseWidth + clampNumber(self:Get("backdropSizeOffsetX"), -1000, 1000, defaults.backdropSizeOffsetX)), snapSize(baseHeight + clampNumber(self:Get("backdropSizeOffsetY"), -1000, 1000, defaults.backdropSizeOffsetY)))
	applyTexture(texture, textureKind, textureValue)
	texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

function Timer:ApplyFrameStyle()
	local frame = self:EnsureFrame()
	local styleTarget = self:GetStyleTarget()
	local width = snapSize(clampNumber(self:Get("width"), 120, 800, defaults.width))
	local rowHeight = snapSize(clampNumber(self:Get("rowHeight"), 12, 48, defaults.rowHeight))
	local barHeight = snapSize(clampNumber(self:Get("barHeight"), 1, 96, defaults.barHeight))
	local panelMode = self:Get("layoutMode") == "PANEL"
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(self:Get("fontSize"), 8, 32, defaults.fontSize)
	local texture = resolveMedia("statusbar", self:Get("texture"), DEFAULT_STATUSBAR)
	local bgTexture = resolveMedia("statusbar", self:Get("barBackgroundTexture"), DEFAULT_STATUSBAR)
	local borderTexture = resolveMedia("border", self:Get("borderTexture"), DEFAULT_BORDER)
	local barBorderTexture = resolveMedia("border", self:Get("barBorderTexture"), DEFAULT_BORDER)
	local borderColor = normalizeColor(self:Get("borderColor"), defaults.borderColor)
	local barBorderColor = normalizeColor(self:Get("barBorderColor"), defaults.barBorderColor)
	local barBgColor = normalizeColor(self:Get("barBackgroundColor"), defaults.barBackgroundColor)

	frame:SetScale(1)
	self:ApplyWindowBackground()
	self:ApplyDecorBar("header")
	self:ApplyDecorBar("footer")
	if frame.borderFrame then
		frame.borderFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
		local borderOffsetX, borderOffsetY = getBorderOffsets(function(key) return self:Get(key) end, "border", "borderInset")
			applyBorderOffset(
				frame.borderFrame,
				styleTarget,
			borderOffsetX,
			borderOffsetY,
			clampNumber(self:Get("borderPositionOffsetX"), -1000, 1000, defaults.borderPositionOffsetX),
			clampNumber(self:Get("borderPositionOffsetY"), -1000, 1000, defaults.borderPositionOffsetY)
		)
		if self:Get("borderEnabled") then
			frame.borderFrame:SetBackdrop({
				edgeFile = borderTexture,
				edgeSize = snapSize(clampNumber(self:Get("borderSize"), 1, 32, defaults.borderSize)),
			})
			frame.borderFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
			frame.borderFrame:Show()
		else
			frame.borderFrame:SetBackdrop(nil)
			frame.borderFrame:Hide()
		end
	end
	if frame.panelTextFrame then frame.panelTextFrame:SetFrameLevel(frame:GetFrameLevel() + 40) end

	for _, row in ipairs(frame.rows) do
		row:SetFrameLevel(frame:GetFrameLevel() + 2)
		row.bar:SetFrameLevel(math.max(0, row:GetFrameLevel() - 1))
		row:SetHeight(rowHeight)
		row.icon:SetSize(rowHeight, rowHeight)
		row.bar:SetHeight(barHeight)
		row.bar:SetStatusBarTexture(texture)
		row.bar.bg:SetTexture(bgTexture)
		row.bar.bg:SetVertexColor(barBgColor.r, barBgColor.g, barBgColor.b, barBgColor.a)
		if row.bar.borderFrame then
			row.bar.borderFrame:SetFrameLevel(row.bar:GetFrameLevel() + 10)
			local barBorderOffsetX, barBorderOffsetY = getBorderOffsets(function(key) return self:Get(key) end, "barBorder", "barBorderOffset")
			applyBorderOffset(row.bar.borderFrame, row.bar, barBorderOffsetX, barBorderOffsetY)
		end
		if row.bar:IsShown() and self:Get("barBorderEnabled") then
			if row.bar.borderFrame then
				row.bar.borderFrame:SetBackdrop({
					edgeFile = barBorderTexture,
					edgeSize = snapSize(clampNumber(self:Get("barBorderSize"), 1, 32, defaults.barBorderSize)),
				})
				row.bar.borderFrame:SetBackdropBorderColor(barBorderColor.r, barBorderColor.g, barBorderColor.b, barBorderColor.a)
				row.bar.borderFrame:Show()
			end
			row.bar:SetBackdrop(nil)
		else
			row.bar:SetBackdrop(nil)
			if row.bar.borderFrame then
				row.bar.borderFrame:SetBackdrop(nil)
				row.bar.borderFrame:Hide()
			end
		end
		applyFontString(row.text, font, fontSize, style)
		applyFontString(row.value, font, fontSize, style)
	end
	for _, bar in pairs(frame.panelBars or {}) do
		bar:SetFrameLevel(frame:GetFrameLevel() + 2)
		local prefix = bar.eqolBarKey == "enemy" and "panelEnemyBar" or "panelTimerBar"
		local visibleKey = bar.eqolBarKey == "enemy" and "showPanelEnemyBar" or "showPanelTimerBar"
		local panelTexture = resolveMedia("statusbar", self:Get(prefix .. "Texture") or self:Get("texture"), DEFAULT_STATUSBAR)
		local panelBgTexture = resolveMedia("statusbar", self:Get(prefix .. "BackgroundTexture") or self:Get("barBackgroundTexture"), DEFAULT_STATUSBAR)
		local panelBgColor = normalizeColor(self:Get(prefix .. "BackgroundColor") or self:Get("barBackgroundColor"), defaults[prefix .. "BackgroundColor"] or defaults.barBackgroundColor)
		local panelBorderTexture = resolveMedia("border", self:Get(prefix .. "BorderTexture") or self:Get("barBorderTexture"), DEFAULT_BORDER)
		local panelBorderColor = normalizeColor(self:Get(prefix .. "BorderColor") or self:Get("barBorderColor"), defaults[prefix .. "BorderColor"] or defaults.barBorderColor)
		bar:SetStatusBarTexture(panelTexture)
		bar.bg:SetTexture(panelBgTexture)
		bar.bg:SetVertexColor(panelBgColor.r, panelBgColor.g, panelBgColor.b, panelBgColor.a)
		if bar.borderFrame then
			bar.borderFrame:SetFrameLevel(bar:GetFrameLevel() + 10)
			local panelBorderOffsetX, panelBorderOffsetY = getBorderOffsets(function(key) return self:Get(key) end, prefix .. "Border", prefix .. "BorderOffset")
			applyBorderOffset(bar.borderFrame, bar, panelBorderOffsetX, panelBorderOffsetY)
		end
		if panelMode and self:Get(visibleKey) and self:Get(prefix .. "BorderEnabled") then
			if bar.borderFrame then
				bar.borderFrame:SetBackdrop({
					edgeFile = panelBorderTexture,
					edgeSize = snapSize(clampNumber(self:Get(prefix .. "BorderSize"), 1, 32, defaults[prefix .. "BorderSize"] or defaults.barBorderSize)),
				})
				bar.borderFrame:SetBackdropBorderColor(panelBorderColor.r, panelBorderColor.g, panelBorderColor.b, panelBorderColor.a)
				bar.borderFrame:Show()
			end
			bar:SetBackdrop(nil)
		else
			bar:SetBackdrop(nil)
			if bar.borderFrame then
				bar.borderFrame:SetBackdrop(nil)
				bar.borderFrame:Hide()
			end
		end
	end
	frame:SetWidth(width)
end

function Timer:GetRunKey(state)
	if not state or not state.mapID or not state.level or state.level <= 0 then return nil end
	return tostring(state.mapID), tostring(state.level)
end

function Timer:GetBestTime(state)
	if not addon.db then return nil end
	local mapKey, levelKey = self:GetRunKey(state)
	if not mapKey then return nil end
	local bestTimes = getTimerStoredTable("bestTimes", false)
	return type(bestTimes) == "table" and bestTimes[mapKey] and tonumber(bestTimes[mapKey][levelKey]) or nil
end

local function splitKey(text)
	text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then text = "objective" end
	return text
end

function Timer:GetBestObjectiveTime(state, objectiveText)
	if state and state.preview then return nil end
	if not addon.db then return nil end
	local mapKey, levelKey = self:GetRunKey(state)
	if not mapKey then return nil end
	local best = getTimerStoredTable("bestObjectiveTimes", false)
	best = type(best) == "table" and best[mapKey] and best[mapKey][levelKey]
	return type(best) == "table" and tonumber(best[splitKey(objectiveText)]) or nil
end

function Timer:SetBestObjectiveTime(state, objectiveText, elapsed)
	if not addon.db then return end
	local mapKey, levelKey = self:GetRunKey(state)
	if not mapKey or not elapsed or elapsed <= 0 then return end
	local bestObjectiveTimes = getTimerStoredTable("bestObjectiveTimes", true)
	bestObjectiveTimes[mapKey] = bestObjectiveTimes[mapKey] or {}
	bestObjectiveTimes[mapKey][levelKey] = bestObjectiveTimes[mapKey][levelKey] or {}
	local key = splitKey(objectiveText)
	local current = tonumber(bestObjectiveTimes[mapKey][levelKey][key])
	if not current or elapsed < current then bestObjectiveTimes[mapKey][levelKey][key] = elapsed end
end

function Timer:UpdateObjectiveSplits(state)
	if not state or state.preview or not state.active then return end
	self.objectiveSplits = self.objectiveSplits or {}
	self.objectiveSplitBestTimes = self.objectiveSplitBestTimes or {}
	self.objectiveStates = self.objectiveStates or {}
	for _, objective in ipairs(state.objectives or {}) do
		local key = splitKey(objective.text)
		local objectiveState = self.objectiveStates[key] or {}
		if objective.completed then
			if objectiveState.seen and objectiveState.completed ~= true and not self.objectiveSplits[key] then
				self.objectiveSplitBestTimes[key] = self:GetBestObjectiveTime(state, objective.text)
				self.objectiveSplits[key] = state.elapsed
				self:SetBestObjectiveTime(state, objective.text, state.elapsed)
			end
			objective.splitTime = self.objectiveSplits[key]
			objective.previousBestTime = self.objectiveSplitBestTimes[key]
		else
			objective.splitTime = self.objectiveSplits[key]
			objective.previousBestTime = self.objectiveSplitBestTimes[key]
		end
		objectiveState.seen = true
		objectiveState.completed = objective.completed == true
		self.objectiveStates[key] = objectiveState
	end
	if state.enemyForces then
		local key = splitKey(state.enemyForces.text)
		local objectiveState = self.objectiveStates[key] or {}
		if state.enemyForces.completed and objectiveState.seen and objectiveState.completed ~= true and not self.objectiveSplits[key] then
			self.objectiveSplitBestTimes[key] = self:GetBestObjectiveTime(state, state.enemyForces.text)
			self.objectiveSplits[key] = state.elapsed
			self:SetBestObjectiveTime(state, state.enemyForces.text, state.elapsed)
		end
		state.enemyForces.splitTime = self.objectiveSplits[key]
		state.enemyForces.previousBestTime = self.objectiveSplitBestTimes[key]
		objectiveState.seen = true
		objectiveState.completed = state.enemyForces.completed == true
		self.objectiveStates[key] = objectiveState
	end
end

function Timer:FormatObjectiveDelta(delta)
	local seconds = math.floor(math.abs(tonumber(delta) or 0) + 0.5)
	local sign = (tonumber(delta) or 0) < 0 and "-" or "+"
	local text
	if seconds >= 60 then
		text = string.format("%s%d:%02d", sign, math.floor(seconds / 60), seconds % 60)
	else
		text = string.format("%s%ds", sign, seconds)
	end
	local color = (tonumber(delta) or 0) < 0 and self:Get("objectiveBestDeltaFasterColor") or self:Get("objectiveBestDeltaSlowerColor")
	return wrapColor(text, color)
end

function Timer:FormatObjectiveCount(objective)
	if not (objective and objective.total and objective.total > 0) then return "" end
	return string.format("%d/%d", objective.quantity or 0, objective.total)
end

function Timer:FormatObjectiveTiming(state, objective)
	local valueText = ""
	if self:Get("showObjectiveTimes") and objective.splitTime then
		valueText = secondsToText(objective.splitTime)
		if self:Get("showObjectiveBestTimes") then
			local best = state and state.preview and objective.bestTime or objective.previousBestTime
			if not best and not (state and state.active) then best = self:GetBestObjectiveTime(state, objective.text) end
			if best then valueText = valueText .. " (" .. self:FormatObjectiveDelta(objective.splitTime - best) .. ")" end
		end
	end
	return valueText
end

function Timer:JoinObjectiveValueText(first, second)
	if first == "" then return second or "" end
	if not second or second == "" then return first end
	return first .. " - " .. second
end

function Timer:FormatObjectiveValue(state, objective)
	local countText = self:Get("showObjectiveValues") ~= false and self:FormatObjectiveCount(objective) or ""
	return self:JoinObjectiveValueText(countText, self:FormatObjectiveTiming(state, objective))
end

function Timer:FormatEnemyForcesValue(state, objective, includeTiming, valueMode)
	local percentText = string.format("%.2f%%", tonumber(objective and objective.percent) or 0)
	local mode = valueMode or self:Get("enemyForcesValueMode")
	if mode ~= "BOTH" and mode ~= "PERCENT" and mode ~= "COUNT" then
		local objectiveValue = includeTiming == false and (self:Get("showObjectiveValues") ~= false and self:FormatObjectiveCount(objective) or "")
			or self:FormatObjectiveValue(state, objective)
		return self:JoinObjectiveValueText(percentText, objectiveValue)
	end
	local countText = self:FormatObjectiveCount(objective)
	local primaryText
	if mode == "COUNT" then
		primaryText = countText ~= "" and countText or percentText
	elseif mode == "BOTH" then
		primaryText = self:JoinObjectiveValueText(percentText, countText)
	else
		primaryText = percentText
	end
	if includeTiming == false then return primaryText end
	return self:JoinObjectiveValueText(primaryText, self:FormatObjectiveTiming(state, objective))
end

function Timer:GetPanelEnemyBarTextMode(slot)
	local key = slot == 2 and "panelEnemyBarText2Mode" or "panelEnemyBarTextMode"
	local mode = self:Get(key)
	if mode == "BOTH" or mode == "PERCENT" or mode == "COUNT" then return mode end
	return defaults[key]
end

function Timer:GetPanelEnemyBarAttachOffset(axis)
	local key = "panelEnemyBarAttachOffset" .. axis
	return clampNumber(self:Get(key), -800, 800, defaults[key])
end

function Timer:MigratePanelEnemyBarSettings()
	local config = getTimerConfig(false)
	if not config then return end
	if config.panelEnemyBarTextMode == nil then
		local mode = config.enemyForcesValueMode
		config.panelEnemyBarTextMode = (mode == "BOTH" or mode == "PERCENT" or mode == "COUNT") and mode or defaults.panelEnemyBarTextMode
	end
	if config.panelEnemyBarAttachToObjectives == true then
		if config.panelEnemyBarAttachOffsetX == nil then config.panelEnemyBarAttachOffsetX = clampNumber(config.panelEnemyBarOffsetX, -800, 800, defaults.panelEnemyBarAttachOffsetX) end
		if config.panelEnemyBarAttachOffsetY == nil then config.panelEnemyBarAttachOffsetY = clampNumber(config.panelEnemyBarOffsetY, -800, 800, defaults.panelEnemyBarAttachOffsetY) end
	end
end

function Timer:RecordBestTime()
	if not addon.db then return end
	local state = self.lastState
	if not state or state.preview or not state.elapsed or state.elapsed <= 0 then return end
	local mapKey, levelKey = self:GetRunKey(state)
	if not mapKey then return end
	local bestTimes = getTimerStoredTable("bestTimes", true)
	bestTimes[mapKey] = bestTimes[mapKey] or {}
	local current = tonumber(bestTimes[mapKey][levelKey])
	if not current or state.elapsed < current then bestTimes[mapKey][levelKey] = state.elapsed end
end

function Timer:SetPanelText(key, textValue, anchorKey, xKey, yKey, color, fontSize, justify)
	local text = self:EnsurePanelText(key)
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local anchor = normalizePoint(self:Get(anchorKey))
	text:ClearAllPoints()
	text:SetDrawLayer("OVERLAY", 7)
	text:SetPoint(anchor, self:EnsureFrame(), anchor, pointOffset(self:Get(xKey), -800, 800, defaults[xKey] or 0), pointOffset(self:Get(yKey), -800, 800, defaults[yKey] or 0))
	applyFontString(text, font, clampNumber(fontSize, 8, 56, defaults.fontSize), style)
	text:SetJustifyH(justify or "LEFT")
	text:SetText(textValue or "")
	setTextColor(text, color or defaults.objectiveColor)
	text:Show()
	return text
end

function Timer:SetPanelHoverForText(key, fontString, tooltipType, tooltipData)
	if not fontString then return end
	local hover = self:EnsurePanelHover(key)
	hover.tooltipType = tooltipType
	hover.tooltipData = tooltipData
	hover:ClearAllPoints()
	hover:SetPoint("TOPLEFT", fontString, "TOPLEFT", 0, 0)
	hover:SetSize(snapSize(math.max(12, fontString:GetStringWidth() or 12)), snapSize(math.max(12, fontString:GetStringHeight() or self:Get("fontSize") or 12)))
	hover:Show()
end

function Timer:RenderPanelAffixes(state)
	if not (state and state.affixNames and #state.affixNames > 0) then return end
	local frame = self:EnsureFrame()
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(self:Get("panelAffixesFontSize"), 8, 56, defaults.panelAffixesFontSize)
	local iconSize = clampNumber(self:Get("panelAffixIconSize"), 8, 64, defaults.panelAffixIconSize)
	local anchor = normalizePoint(self:Get("panelAffixesAnchor"))
	local color = normalizeColor(self:Get("affixColor"), defaults.affixColor)
	local x = pointOffset(self:Get("panelAffixesOffsetX"), -800, 800, defaults.panelAffixesOffsetX)
	local y = pointOffset(self:Get("panelAffixesOffsetY"), -800, 800, defaults.panelAffixesOffsetY)
	local mode = self:Get("affixDisplay")
	local gap = mode == "ICON" and 4 or 5
	local growLeft = anchor == "TOPRIGHT" or anchor == "RIGHT" or anchor == "BOTTOMRIGHT"
	local previous
	local lineStart
	local lineWidth = 0
	local separatorIndex = 0
	local maxLineWidth = math.max(80, clampNumber(self:Get("width"), 120, 800, defaults.width) - math.abs(x) * 2 - 12)
	local startIndex = growLeft and #state.affixNames or 1
	local endIndex = growLeft and 1 or #state.affixNames
	local step = growLeft and -1 or 1
	for index = startIndex, endIndex, step do
		local item = self:EnsurePanelAffix(index)
		item.tooltipType = "affix"
		item.tooltipData = { state = state, index = index }
		applyFontString(item.text, font, fontSize, style)
		item.text:SetText(self:GetSingleAffixDisplayText(state, index, iconSize))
		item.text:SetTextColor(color.r, color.g, color.b, color.a)
		item.text:ClearAllPoints()
		item.text:SetWordWrap(mode ~= "ICON")
		item.text:SetNonSpaceWrap(false)
		if mode ~= "ICON" then item.text:SetWidth(maxLineWidth) end
		item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
		item:ClearAllPoints()
		local itemWidth = snapSize(math.max(12, math.min(item.text:GetStringWidth() or 12, maxLineWidth)))
		local itemHeight = snapSize(math.max(12, item.text:GetStringHeight() or fontSize))
		local separator
		local separatorWidth = 0
		if previous and mode == "TEXT" then
			separatorIndex = separatorIndex + 1
			separator = self:EnsurePanelAffixSeparator(separatorIndex)
			applyFontString(separator.text, font, fontSize, style)
			separator.text:SetText("-")
			separator.text:SetTextColor(color.r, color.g, color.b, color.a)
			separator.text:ClearAllPoints()
			separator.text:SetPoint("TOPLEFT", separator, "TOPLEFT", 0, 0)
			separatorWidth = snapSize(math.max(6, separator.text:GetStringWidth() or 6))
			separator:SetSize(separatorWidth, itemHeight)
		end
		local inlineWidth = itemWidth + (separator and (separatorWidth + gap * 2) or gap)
		local shouldWrap = previous and mode ~= "ICON" and (lineWidth + inlineWidth > maxLineWidth)
		if shouldWrap then
			if separator then separator:Hide() end
			if growLeft then
				item:SetPoint("TOPRIGHT", lineStart, "BOTTOMRIGHT", 0, -gap)
			else
				item:SetPoint("TOPLEFT", lineStart, "BOTTOMLEFT", 0, -gap)
			end
			lineStart = item
			lineWidth = itemWidth
		elseif previous then
			if separator then
				separator:ClearAllPoints()
				if growLeft then
					separator:SetPoint("RIGHT", previous, "LEFT", -gap, 0)
					item:SetPoint("RIGHT", separator, "LEFT", -gap, 0)
				else
					separator:SetPoint("LEFT", previous, "RIGHT", gap, 0)
					item:SetPoint("LEFT", separator, "RIGHT", gap, 0)
				end
				separator:Show()
				lineWidth = lineWidth + gap + separatorWidth + gap + itemWidth
			else
				if growLeft then
					item:SetPoint("RIGHT", previous, "LEFT", -gap, 0)
				else
					item:SetPoint("LEFT", previous, "RIGHT", gap, 0)
				end
				lineWidth = lineWidth + gap + itemWidth
			end
		else
			item:SetPoint(anchor, frame, anchor, x, y)
			lineStart = item
			lineWidth = itemWidth
		end
		item:SetSize(itemWidth, itemHeight)
		item:Show()
		previous = item
	end
end

function Timer:RenderPanelObjectives(state)
	local frame = self:EnsureFrame()
	frame.panelObjectiveFirst = nil
	frame.panelObjectiveBottom = nil
	frame.panelObjectivesHeight = nil
	if not (state and state.objectives and #state.objectives > 0) then return 0 end
	local font = resolveFont(self:Get("panelObjectivesFontFace"))
	local style = normalizeFontStyle(self:Get("panelObjectivesFontOutline"))
	local fontSize = clampNumber(self:Get("panelObjectivesFontSize"), 8, 56, defaults.panelObjectivesFontSize)
	local spacing = snapToPixel(clampNumber(self:Get("panelObjectivesSpacing"), 0, 24, defaults.panelObjectivesSpacing))
	local columnOffset = snapToPixel(clampNumber(self:Get("panelObjectivesColumnSpacing"), -200, 200, defaults.panelObjectivesColumnSpacing))
	local x = pointOffset(self:Get("panelObjectivesOffsetX"), -800, 800, defaults.panelObjectivesOffsetX)
	local y = pointOffset(self:Get("panelObjectivesOffsetY"), -800, 800, defaults.panelObjectivesOffsetY)
	local baseRowHeight = snapSize(fontSize + 2)
	local frameWidth = clampNumber(self:Get("width"), 120, 800, defaults.width)
	local width = snapSize(math.max(80, frameWidth - 12))
	local rowsHeight = 0
	local growUp = self:Get("panelObjectivesGrowth") == "UP"
	local anchor = normalizePoint(self:Get("panelObjectivesAnchor"))
	local itemPointSuffix = anchor:find("LEFT", 1, true) and "LEFT" or anchor:find("RIGHT", 1, true) and "RIGHT" or ""
	local invertColumns = self:Get("panelObjectivesInvertColumns") == true
	local hideNonBoss = self:Get("hideNonBossObjectives") == true
	local previous
	local shownIndex = 0
	for index, objective in ipairs(state.objectives) do
		local item = self:EnsurePanelObjective(index)
		if hideNonBoss and objective.isBoss ~= true then
			item:Hide()
		else
			shownIndex = shownIndex + 1
			if shownIndex == 1 then frame.panelObjectiveFirst = item end
		local color = normalizeColor(objective.completed and self:Get("objectiveCompleteColor") or self:Get("objectiveColor"), defaults.objectiveColor)
		local valueText = self:FormatObjectiveValue(state, objective)
		item.tooltipType = "objective"
		item.tooltipData = objective
		item:SetWidth(width)
		applyFontString(item.text, font, fontSize, style)
		item.text:SetText(objective.text or "")
		item.text:SetWordWrap(true)
		item.text:SetNonSpaceWrap(false)
		item.text:SetTextColor(color.r, color.g, color.b, color.a)
		item.text:ClearAllPoints()
		applyFontString(item.value, font, fontSize, style)
		item.value:SetText(valueText)
		item.value:SetWordWrap(false)
		item.value:SetNonSpaceWrap(false)
		if item.value.SetMaxLines then item.value:SetMaxLines(1) end
		item.value:SetTextColor(color.r, color.g, color.b, color.a)
		item.value:ClearAllPoints()
		local columnGap = snapToPixel(4)
		local getValueWidth = item.value.GetUnboundedStringWidth or item.value.GetStringWidth
		local naturalValueWidth = valueText ~= "" and (tonumber(getValueWidth and getValueWidth(item.value)) or 0) or 0
		local minimumLabelWidth = math.max(40, fontSize * 2)
		local maximumValueWidth = math.max(1, math.min(width * 0.65, width - minimumLabelWidth - columnGap))
		local valueWidth = valueText ~= "" and snapSize(math.min(maximumValueWidth, math.max(fontSize * 2, naturalValueWidth + 2))) or 0
		if invertColumns then
			item.text:SetJustifyH("RIGHT")
			item.value:SetJustifyH("LEFT")
			if valueWidth > 0 then
				item.value:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
				item.value:SetWidth(valueWidth)
				item.text:SetPoint("TOPLEFT", item, "TOPLEFT", math.max(0, valueWidth + columnGap + columnOffset), 0)
			else
				item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
			end
			item.text:SetPoint("RIGHT", item, "RIGHT", columnOffset, 0)
		else
			item.text:SetJustifyH("LEFT")
			item.value:SetJustifyH("RIGHT")
			item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
			if valueWidth > 0 then
				item.value:SetPoint("TOPRIGHT", item, "TOPRIGHT", columnOffset, 0)
				item.value:SetWidth(valueWidth)
				item.text:SetPoint("RIGHT", item.value, "LEFT", -columnGap, 0)
			else
				item.text:SetPoint("RIGHT", item, "RIGHT", 0, 0)
			end
		end
		local textHeight = item.text:GetStringHeight() or baseRowHeight
		local valueHeight = item.value:GetStringHeight() or baseRowHeight
		local itemHeight = snapSize(math.max(baseRowHeight, textHeight, valueHeight) + 2)
		item:SetSize(width, itemHeight)
		item:ClearAllPoints()
		if previous then
			if growUp then
				item:SetPoint("BOTTOMLEFT", previous, "TOPLEFT", 0, spacing)
			else
				item:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing)
			end
		else
			if growUp then
				item:SetPoint("BOTTOM" .. itemPointSuffix, frame, anchor, x, y)
			else
				item:SetPoint("TOP" .. itemPointSuffix, frame, anchor, x, y)
			end
		end
		rowsHeight = rowsHeight + itemHeight
		if shownIndex > 1 then rowsHeight = rowsHeight + spacing end
		item:Show()
		previous = item
		end
	end
	for index = #state.objectives + 1, #(frame.panelObjectives or {}) do
		frame.panelObjectives[index]:Hide()
	end
	if shownIndex == 0 then return 0 end
	frame.panelObjectiveBottom = growUp and frame.panelObjectiveFirst or previous
	frame.panelObjectivesHeight = rowsHeight
	if growUp then
		return math.max(0, math.abs(y)) + rowsHeight + 6
	end
	return math.max(0, math.abs(y)) + rowsHeight + 6
end

function Timer:ApplyPanelLinks()
	local frame = self.frame
	if not frame then return end

	local timerBar = frame.panelBars and frame.panelBars.timer
	if not (timerBar and timerBar:IsShown() and self:Get("showPanelTimerBar")) then timerBar = nil end
	if timerBar and self:Get("panelTimerBarAttachToHeader") == true then
		local header = frame.decorBars and frame.decorBars.header
		timerBar:ClearAllPoints()
		if header and header:IsShown() then
			timerBar:SetPoint("TOP", header, "BOTTOM", 0, 0)
		else
			timerBar:SetPoint("TOP", frame, "TOP", 0, 0)
		end
	end

	local firstObjective = frame.panelObjectiveFirst
	if
		firstObjective
		and firstObjective:IsShown()
		and timerBar
		and self:Get("showObjectives")
		and self:Get("panelObjectivesAttachToTimerBar") == true
	then
		firstObjective:ClearAllPoints()
		local x = pointOffset(self:Get("panelObjectivesOffsetX"), -800, 800, defaults.panelObjectivesOffsetX)
		local y = pointOffset(self:Get("panelObjectivesOffsetY"), -800, 800, defaults.panelObjectivesOffsetY)
		if self:Get("panelObjectivesGrowth") == "UP" then
			local rowsHeight = frame.panelObjectivesHeight or 0
			firstObjective:SetPoint("BOTTOM", timerBar, "BOTTOM", x, y - rowsHeight)
		else
			firstObjective:SetPoint("TOP", timerBar, "BOTTOM", x, y)
		end
	end

	local bottomObjective = frame.panelObjectiveBottom
	local enemyBar = frame.panelBars and frame.panelBars.enemy
	if
		bottomObjective
		and bottomObjective:IsShown()
		and enemyBar
		and enemyBar:IsShown()
		and self:Get("showPanelEnemyBar")
		and self:Get("panelEnemyBarAttachToObjectives") == true
	then
		enemyBar:ClearAllPoints()
		enemyBar:SetPoint(
			"TOP",
			bottomObjective,
			"BOTTOM",
			pointOffset(self:GetPanelEnemyBarAttachOffset("X"), -800, 800, defaults.panelEnemyBarAttachOffsetX),
			pointOffset(self:GetPanelEnemyBarAttachOffset("Y"), -800, 800, defaults.panelEnemyBarAttachOffsetY)
		)
	end
end

function Timer:ShouldShowDeathDisplay(state)
	if not self:Get("showDeaths") then return false end
	if state and state.preview then return true end
	return (state and tonumber(state.deaths) or 0) > 0
end

function Timer:ShouldSuppressObjectiveTracker(state, frameShouldShow)
	if not frameShouldShow or not self:IsEnabled() or self:IsInEditMode() then return false end
	if not (state and (state.active or state.completed)) then return false end
	local tracker = _G.ObjectiveTrackerFrame
	return tracker ~= nil
end

function Timer:InstallObjectiveTrackerHook()
	if self.objectiveTrackerHooked then return end
	local tracker = _G.ObjectiveTrackerFrame
	if not (tracker and hooksecurefunc) then return end
	self.objectiveTrackerHooked = true
	hooksecurefunc(tracker, "Show", function()
		if Timer:ShouldSuppressObjectiveTracker(Timer.lastState, Timer.frame and Timer.frame:IsShown()) then tracker:Hide() end
	end)
end

function Timer:ApplyObjectiveTrackerVisibility(state, frameShouldShow)
	self:InstallObjectiveTrackerHook()
	local tracker = _G.ObjectiveTrackerFrame
	if not tracker then return end
	if self:ShouldSuppressObjectiveTracker(state, frameShouldShow) then
		self.objectiveTrackerSuppressed = true
		tracker:Hide()
	elseif self.objectiveTrackerSuppressed then
		self.objectiveTrackerSuppressed = nil
		if not (addon.db and addon.db["mythicPlusEnableObjectiveTracker"]) and tracker.Update then tracker:Update() end
	end
end

function Timer:SetPanelBar(key, value, maxValue, anchorKey, xKey, yKey, color)
	local bar = self:EnsurePanelBar(key)
	local widthKey = key == "enemy" and "panelEnemyBarWidth" or "panelTimerBarWidth"
	local heightKey = key == "enemy" and "panelEnemyBarHeight" or "panelTimerBarHeight"
	local width = snapSize(clampNumber(self:Get(widthKey) or self:Get("panelBarWidth"), 20, 800, defaults[widthKey] or defaults.panelBarWidth))
	local height = snapSize(clampNumber(self:Get(heightKey) or self:Get("panelBarHeight"), 1, 64, defaults[heightKey] or defaults.panelBarHeight))
	local anchor = normalizePoint(self:Get(anchorKey))
	bar:ClearAllPoints()
	bar:SetFrameLevel(self:EnsureFrame():GetFrameLevel() + 2)
	if bar.textFrame then bar.textFrame:SetFrameLevel(self:EnsureFrame():GetFrameLevel() + 40) end
	if bar.chestMarkerTextFrame then bar.chestMarkerTextFrame:SetFrameLevel(self:EnsureFrame():GetFrameLevel() + 40) end
	bar:SetPoint(anchor, self:EnsureFrame(), anchor, pointOffset(self:Get(xKey), -800, 800, defaults[xKey] or 0), pointOffset(self:Get(yKey), -800, 800, defaults[yKey] or 0))
	bar:SetSize(width, height)
	bar:SetMinMaxValues(0, maxValue or 100)
	bar:SetValue(value or 0)
	color = normalizeColor(color, defaults.objectiveColor)
	bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	bar:Show()
end

function Timer:SetPanelEnemyBarTextSlot(slot, state, objective)
	local frame = self.frame
	local bar = frame and frame.panelBars and frame.panelBars.enemy
	local text = bar and (slot == 2 and bar.text2 or bar.text) or nil
	if not text then return end
	local enabledKey = slot == 2 and "panelEnemyBarText2Enabled" or "panelEnemyBarTextEnabled"
	if not self:Get(enabledKey) then
		text:Hide()
		return
	end
	local alignKey = slot == 2 and "panelEnemyBarText2Align" or "panelEnemyBarTextAlign"
	local align = normalizeHorizontal(self:Get(alignKey))
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(self:Get("panelEnemyBarTextFontSize"), 8, 56, defaults.panelEnemyBarTextFontSize)
	local color = normalizeColor(self:Get("panelEnemyBarTextColor"), defaults.panelEnemyBarTextColor)
	local offsetY = pointOffset(self:Get("panelEnemyBarTextOffsetY"), -800, 800, defaults.panelEnemyBarTextOffsetY)
	text:ClearAllPoints()
	applyFontString(text, font, fontSize, style)
	-- The bar's dedicated value mode owns this text. Objective split timing is
	-- still shown in the normal objective list, but must not become a second
	-- value next to Count/Percentage/Both inside the bar.
	text:SetText(self:FormatEnemyForcesValue(state, objective, false, self:GetPanelEnemyBarTextMode(slot)))
	text:SetTextColor(color.r, color.g, color.b, color.a)
	text:SetJustifyH(align)
	if align == "LEFT" then
		text:SetPoint("LEFT", bar, "LEFT", 3, offsetY)
		text:SetPoint("RIGHT", bar, "RIGHT", -3, offsetY)
	elseif align == "RIGHT" then
		text:SetPoint("LEFT", bar, "LEFT", 3, offsetY)
		text:SetPoint("RIGHT", bar, "RIGHT", -3, offsetY)
	else
		text:SetPoint("CENTER", bar, "CENTER", 0, offsetY)
	end
	text:Show()
end

function Timer:SetPanelEnemyBarText(state, objective)
	self:SetPanelEnemyBarTextSlot(1, state, objective)
	self:SetPanelEnemyBarTextSlot(2, state, objective)
end

function Timer:SetPanelTimerBarTimeLeftText(timeLeft, state)
	local frame = self.frame
	local bar = frame and frame.panelBars and frame.panelBars.timer
	if not (bar and bar.timeLeftText) then return end
	if not self:Get("panelTimerBarTimeLeftText") then
		bar.timeLeftText:Hide()
		self:ReleaseTimerTextBinding("panel-bar-time-left")
		return
	end
	local fillUp = self:Get("panelTimerBarFillUp") == true
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(self:Get("panelTimerBarTimeLeftTextFontSize"), 8, 56, defaults.panelTimerBarTimeLeftTextFontSize)
	local color = normalizeColor(self:Get("panelTimerBarTimeLeftTextColor"), defaults.panelTimerBarTimeLeftTextColor)
	local offsetX = pointOffset(self:Get("panelTimerBarTimeLeftTextOffsetX"), -800, 800, defaults.panelTimerBarTimeLeftTextOffsetX)
	local offsetY = pointOffset(self:Get("panelTimerBarTimeLeftTextOffsetY"), -800, 800, defaults.panelTimerBarTimeLeftTextOffsetY)
	local timeLimit = tonumber(state and state.timeLimit) or 0
	local elapsed = tonumber(state and state.elapsed) or 0
	bar.timeLeftText:ClearAllPoints()
	applyFontString(bar.timeLeftText, font, fontSize, style)
	bar.timeLeftText:SetText(secondsToText(math.max(0, tonumber(timeLeft) or 0)))
	bar.timeLeftText:SetTextColor(color.r, color.g, color.b, color.a)
	if fillUp then
		bar.timeLeftText:SetJustifyH("RIGHT")
		bar.timeLeftText:SetPoint("RIGHT", bar, "RIGHT", offsetX, offsetY)
	else
		bar.timeLeftText:SetJustifyH("LEFT")
		bar.timeLeftText:SetPoint("LEFT", bar, "LEFT", offsetX, offsetY)
	end
	if state and state.active and timeLimit > 0 and elapsed < timeLimit then
		local durationObject = self:UpdateTimerDurationObject("panelBarTimeLeft", getChallengeStartTime(self, state), timeLimit)
		if not (durationObject and self:BindTimerText(bar.timeLeftText, "panel-bar-time-left", durationObject, "REMAINING")) then self:ReleaseTimerTextBinding("panel-bar-time-left") end
	else
		self:ReleaseTimerTextBinding("panel-bar-time-left")
	end
	bar.timeLeftText:Show()
end

function Timer:UpdatePanelTimerBarChestMarkers(timeLimit, twoChest, threeChest)
	local frame = self.frame
	local bar = frame and frame.panelBars and frame.panelBars.timer
	if not (bar and bar.chestMarkers) then return end
	local showMarkers = self:Get("panelTimerBarChestMarkers") == true
	local showTexts = self:Get("panelTimerBarChestTimeText") == true
	local function hideMarkerElements()
		for _, marker in ipairs(bar.chestMarkers) do
			marker:Hide()
		end
		for _, markerText in ipairs(bar.chestMarkerTexts or {}) do
			markerText:Hide()
		end
		Timer:ReleaseTimerTextBinding("panel-bar-panelBarChest3")
		Timer:ReleaseTimerTextBinding("panel-bar-panelBarChest2")
	end
	if not showMarkers and not showTexts then
		hideMarkerElements()
		return
	end
	timeLimit = tonumber(timeLimit) or 0
	if timeLimit <= 0 then
		hideMarkerElements()
		return
	end
	local markerColor = normalizeColor(self:Get("panelTimerBarChestMarkerColor"), defaults.panelTimerBarChestMarkerColor)
	local markerWidth = snapSize(clampNumber(self:Get("panelTimerBarChestMarkerWidth"), 1, 12, defaults.panelTimerBarChestMarkerWidth))
	local width = bar:GetWidth() or clampNumber(self:Get("panelTimerBarWidth"), 20, 800, defaults.panelTimerBarWidth)
	local height = bar:GetHeight() or clampNumber(self:Get("panelTimerBarHeight"), 1, 64, defaults.panelTimerBarHeight)
	local elapsed = tonumber(self.lastState and self.lastState.elapsed) or 0
	local threeChestTime = tonumber(threeChest) or 0
	local twoChestTime = tonumber(twoChest) or 0
	local fillUp = self:Get("panelTimerBarFillUp") == true
	local function markerPosition(chestTime)
		local ratio = chestTime / timeLimit
		if not fillUp then ratio = 1 - ratio end
		return width * math.max(0, math.min(1, ratio))
	end
	local positions = {
		markerPosition(threeChestTime),
		markerPosition(twoChestTime),
	}
	local remainingTimes = {
		threeChestTime - elapsed,
		twoChestTime - elapsed,
	}
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(self:Get("panelTimerBarChestTimeTextFontSize"), 8, 56, defaults.panelTimerBarChestTimeTextFontSize)
	local textColor = normalizeColor(self:Get("panelTimerBarChestTimeTextColor"), defaults.panelTimerBarChestTimeTextColor)
	local textOffsetY = pointOffset(self:Get("panelTimerBarChestTimeTextOffsetY"), -800, 800, defaults.panelTimerBarChestTimeTextOffsetY)
	for index, marker in ipairs(bar.chestMarkers) do
		if showMarkers then
			marker:ClearAllPoints()
			marker:SetPoint("LEFT", bar, "LEFT", snapToPixel(positions[index] - markerWidth * 0.5), 0)
			marker:SetSize(markerWidth, snapSize(height))
			marker:SetColorTexture(markerColor.r, markerColor.g, markerColor.b, markerColor.a)
			marker:Show()
		else
			marker:Hide()
		end
		local markerText = bar.chestMarkerTexts and bar.chestMarkerTexts[index]
		if markerText then
			if showTexts and remainingTimes[index] and remainingTimes[index] >= 0 then
				local durationObjectKey = index == 1 and "panelBarChest3" or "panelBarChest2"
				markerText:ClearAllPoints()
				markerText:SetPoint("CENTER", bar, "LEFT", snapToPixel(positions[index]), textOffsetY)
				applyFontString(markerText, font, fontSize, style)
				markerText:SetText(secondsToText(remainingTimes[index]))
				markerText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
					if self.lastState and self.lastState.active then
						local durationObject = self:UpdateTimerDurationObject(durationObjectKey, getChallengeStartTime(self, self.lastState), index == 1 and threeChestTime or twoChestTime)
						if not (durationObject and self:BindTimerText(markerText, "panel-bar-" .. durationObjectKey, durationObject, "REMAINING")) then self:ReleaseTimerTextBinding("panel-bar-" .. durationObjectKey) end
					else
						self:ReleaseTimerTextBinding("panel-bar-" .. durationObjectKey)
					end
					markerText:Show()
				else
					markerText:Hide()
					self:ReleaseTimerTextBinding("panel-bar-" .. (index == 1 and "panelBarChest3" or "panelBarChest2"))
				end
			end
	end
end

function Timer:RenderPanel(state, timeLeft, twoChest, threeChest)
	local panelMode = self:Get("layoutMode") == "PANEL"
	self:HidePanelElements(not panelMode and self.panelBindingsActive == true)
	if not panelMode then return 0 end
	self.panelBindingsActive = true
	local frame = self:EnsureFrame()
	local panelHeight = clampNumber(self:Get("panelHeight"), 24, 300, defaults.panelHeight)
	frame:SetSize(snapSize(clampNumber(self:Get("width"), 120, 800, defaults.width)), snapSize(panelHeight))
	if self:Get("showObjectives") then self:RenderPanelObjectives(state) end
	local best = self:GetBestTime(state)
	if state.preview then best = 1612 end
	local delta = best and state.elapsed and (state.elapsed - best) or nil
	local enemyPercent = tonumber(state.enemyForces and state.enemyForces.percent) or 0
	local elapsed = tonumber(state.elapsed) or 0
	if self:Get("showDungeon") then self:SetPanelText("dungeon", self:GetDungeonDisplayText(state), "dungeonAnchor", "dungeonOffsetX", "dungeonOffsetY", self:Get("dungeonColor"), self:Get("panelDungeonFontSize")) end
	if self:Get("showKeyLevel") then self:SetPanelText("key", tostring(state.level or 0), "keyLevelAnchor", "keyLevelOffsetX", "keyLevelOffsetY", self:Get("dungeonColor"), self:Get("panelKeyLevelFontSize")) end
	if self:Get("showTimer") then
		self:SetBoundTimerText(
			"timer",
			self:GetTimerDisplayText(state, timeLeft),
			"timerAnchor",
			"timerOffsetX",
			"timerOffsetY",
			timeLeft <= 0 and self:Get("timerExpiredColor") or self:Get("timerColor"),
			self:Get("panelTimerFontSize"),
			"CENTER",
			state,
			state.timeLimit,
			self:Get("timerDisplay")
		)
	else
		self:ReleaseTimerTextBinding("panel-timer")
	end
	if self:Get("showChestTimers") then
		local hideChestLabels = self:Get("panelChestHideLabels") == true
		if elapsed <= twoChest then
			self:SetBoundTimerText(
				"chest2",
				hideChestLabels and secondsToText(twoChest - elapsed) or ("+2\n" .. secondsToText(twoChest - elapsed)),
				"chest2Anchor",
				"chest2OffsetX",
				"chest2OffsetY",
				self:Get("chestColor"),
				self:Get("panelChestFontSize"),
				nil,
				state,
				twoChest,
				"REMAINING",
				hideChestLabels and "{}" or "+2\n{}"
			)
		else
			self:ReleaseTimerTextBinding("panel-chest2")
		end
		if elapsed <= threeChest then
			self:SetBoundTimerText(
				"chest3",
				hideChestLabels and secondsToText(threeChest - elapsed) or ("+3\n" .. secondsToText(threeChest - elapsed)),
				"chest3Anchor",
				"chest3OffsetX",
				"chest3OffsetY",
				self:Get("chestColor"),
				self:Get("panelChestFontSize"),
				nil,
				state,
				threeChest,
				"REMAINING",
				hideChestLabels and "{}" or "+3\n{}"
			)
		else
			self:ReleaseTimerTextBinding("panel-chest3")
		end
	else
		self:ReleaseTimerTextBinding("panel-chest2")
		self:ReleaseTimerTextBinding("panel-chest3")
	end
	if self:ShouldShowDeathDisplay(state) then
		local deathText = self:SetPanelText("deaths", self:GetDeathDisplayText(state.deaths, self:Get("panelDeathIconSize"), state.timeLost), "deathsAnchor", "deathsOffsetX", "deathsOffsetY", self:Get("deathColor"), self:Get("panelDeathsFontSize"))
		self:SetPanelHoverForText("deaths", deathText, "deaths", state)
	end
	if self:Get("showEnemyPercent") then self:SetPanelText("enemyPercent", string.format("%.2f%%", enemyPercent), "enemyPercentAnchor", "enemyPercentOffsetX", "enemyPercentOffsetY", self:Get("enemyForcesColor"), self:Get("panelEnemyPercentFontSize")) end
	if self:Get("showBestTime") and best then
		local bestText = secondsToText(best)
		if self:Get("showBestDelta") and delta then bestText = bestText .. string.format(" (%+.0fs)", delta) end
		self:SetPanelText("best", bestText, "bestTimeAnchor", "bestTimeOffsetX", "bestTimeOffsetY", self:Get("bestTimeColor"), self:Get("panelBestTimeFontSize"))
	end
	if self:Get("showAffixes") then self:RenderPanelAffixes(state) end
	if self:Get("showPanelTimerBar") then
		local bar = self:EnsurePanelBar("timer")
		if bar.textFrame then bar.textFrame:Show() end
		if bar.chestMarkerTextFrame then bar.chestMarkerTextFrame:Show() end
		local timerBarValue = self:Get("panelTimerBarFillUp") == true and math.min(state.timeLimit or 1, math.max(0, elapsed)) or math.max(0, timeLeft)
		self:SetPanelBar("timer", timerBarValue, state.timeLimit or 1, "panelTimerBarAnchor", "panelTimerBarOffsetX", "panelTimerBarOffsetY", timeLeft <= 0 and self:Get("panelTimerBarExpiredColor") or self:Get("panelTimerBarColor"))
		self:UpdatePanelTimerBarChestMarkers(state.timeLimit or 0, twoChest, threeChest)
		self:SetPanelTimerBarTimeLeftText(timeLeft, state)
	else
		self:ReleaseTimerTextBinding("panel-bar-time-left")
		self:ReleaseTimerTextBinding("panel-bar-panelBarChest2")
		self:ReleaseTimerTextBinding("panel-bar-panelBarChest3")
	end
	if self:Get("showPanelEnemyBar") then
		local bar = self:EnsurePanelBar("enemy")
		if bar.textFrame then bar.textFrame:Show() end
		self:SetPanelBar("enemy", enemyPercent, 100, "panelEnemyBarAnchor", "panelEnemyBarOffsetX", "panelEnemyBarOffsetY", self:Get("panelEnemyBarColor"))
		self:SetPanelEnemyBarText(state, state.enemyForces)
	end
	self:ApplyPanelLinks()
	self:UpdatePanelStyleBounds()
	if state.preview then self:CapturePanelBackdropReference() end
	self:ApplyFrameStyle()
	return panelHeight
end

function Timer:EnsurePanelBackdropReference()
	if self.panelBackdropReferenceReady or self:GetLayoutMode() ~= "PANEL" then return end
	local frame = self:EnsureFrame()
	local wasShown = frame:IsShown()
	local state = self:GetPreviewState()
	local timeLeft = (state.timeLimit or 0) - (state.elapsed or 0)
	local twoChest, threeChest = calculateChestTimers(state.timeLimit or 0, state.affixes or {})
	self:RenderPanel(state, timeLeft, twoChest, threeChest)
	self:HidePanelElements(true)
	if not wasShown then frame:Hide() end
end

function Timer:HideListDecorContent(activeKinds)
	local frame = self.frame
	if not frame then return end
	for kind, holder in pairs(frame.decorContent or {}) do
		if not (activeKinds and activeKinds[kind]) then
			holder.tooltipType = nil
			holder.tooltipData = nil
			holder:Hide()
			self:ReleaseTimerTextBinding("decor-" .. kind)
		end
	end
end

function Timer:HideListElements()
	local frame = self.frame
	if not frame then return end
	for index, row in ipairs(frame.rows or {}) do
		row:Hide()
		self:ReleaseTimerTextBinding("row-" .. tostring(index))
	end
	self:HideListDecorContent()
end

function Timer:HideAllElements()
	self:HidePanelElements(true)
	self:HideListElements()
	if self.PanelFlow then self.PanelFlow:Hide() end
end

function Timer:SetListDecorContent(kind, data)
	local holder = self:EnsureDecorContent(kind)
	local frame = self:EnsureFrame()
	local target = frame.decorBars and frame.decorBars[kind]
	if not target then return end
	local textOffsetX = pointOffset(self:Get("textOffsetX"), -800, 800, defaults.textOffsetX)
	local textOffsetY = pointOffset(self:Get("textOffsetY"), -800, 800, defaults.textOffsetY)
	local valueOffsetX = pointOffset(self:Get("valueOffsetX"), -800, 800, defaults.valueOffsetX)
	local valueOffsetY = pointOffset(self:Get("valueOffsetY"), -800, 800, defaults.valueOffsetY)
	local align = data.textAlign or self:Get("align")
	if align ~= "CENTER" and align ~= "RIGHT" then align = "LEFT" end
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(data.fontSize or self:Get("fontSize"), 8, 44, defaults.fontSize)
	local valueFontSize = clampNumber(data.valueFontSize or fontSize, 8, 44, fontSize)

	holder:SetFrameLevel(frame:GetFrameLevel() + 40)
	holder:ClearAllPoints()
	holder:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
	holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
	holder.tooltipType = data.tooltipType
	holder.tooltipData = data.tooltipData
	holder:EnableMouse(data.tooltipType ~= nil)
	holder.text:SetText(data.text or "")
	holder.value:SetText(data.valueText or "")
	holder.text:SetJustifyH(align)
	holder.value:SetJustifyH("RIGHT")
	applyFontString(holder.text, font, fontSize, style)
	applyFontString(holder.value, font, valueFontSize, style)
	holder.text:ClearAllPoints()
	holder.text:SetPoint("LEFT", holder, "LEFT", textOffsetX, textOffsetY)
	if data.fullWidthText then
		holder.text:SetPoint("RIGHT", holder, "RIGHT", valueOffsetX, textOffsetY)
		holder.value:Hide()
	else
		local valueWidth = math.max(48, (holder.value:GetStringWidth() or 0) + 8)
		holder.text:SetPoint("RIGHT", holder, "RIGHT", valueOffsetX - valueWidth, textOffsetY)
		holder.value:ClearAllPoints()
		holder.value:SetPoint("LEFT", holder, "RIGHT", valueOffsetX - valueWidth + 4, valueOffsetY)
		holder.value:SetPoint("RIGHT", holder, "RIGHT", valueOffsetX, valueOffsetY)
		holder.value:Show()
	end
	local color = normalizeColor(data.color, defaults.objectiveColor)
	local globalTextColor = self:Get("useGlobalTextColor") and self:Get("textColor") or nil
	setTextColor(holder.text, globalTextColor or data.textColor or color)
	setTextColor(holder.value, globalTextColor or data.valueColor or color)

	local bindingKey = "decor-" .. kind
	local durationBinding = data.durationBinding
	if durationBinding and durationBinding.state and durationBinding.state.active then
		local elapsed = tonumber(durationBinding.state.elapsed) or 0
		local duration = tonumber(durationBinding.duration) or 0
		if duration > 0 and elapsed < duration then
			local durationObject = self:UpdateTimerDurationObject(durationBinding.key, getChallengeStartTime(self, durationBinding.state), duration)
			if not (durationObject and self:BindTimerText(holder.value, bindingKey, durationObject, durationBinding.mode, durationBinding.textFormat)) then self:ReleaseTimerTextBinding(bindingKey) end
		else
			self:ReleaseTimerTextBinding(bindingKey)
		end
	else
		self:ReleaseTimerTextBinding(bindingKey)
	end
	holder:Show()
end

function Timer:SetRow(index, data)
	local row = self:EnsureRow(index)
	local rowHeight = snapSize(clampNumber(self:Get("rowHeight"), 12, 48, defaults.rowHeight))
	local barHeight = snapSize(clampNumber(self:Get("barHeight"), 1, 96, defaults.barHeight))
	local iconGap = pointOffset(self:Get("iconGap"), -50, 100, defaults.iconGap)
	local iconOffsetX = pointOffset(self:Get("iconOffsetX"), -200, 200, defaults.iconOffsetX)
	local iconOffsetY = pointOffset(self:Get("iconOffsetY"), -200, 200, defaults.iconOffsetY)
	local barOffsetX = pointOffset(self:Get("barOffsetX"), -800, 800, defaults.barOffsetX)
	local barOffsetY = pointOffset(self:Get("barOffsetY"), -800, 800, defaults.barOffsetY)
	local barWidthOffset = snapToPixel(clampNumber(self:Get("barWidthOffset"), -400, 400, defaults.barWidthOffset))
	local textOffsetX = pointOffset(self:Get("textOffsetX"), -800, 800, defaults.textOffsetX)
	local textOffsetY = pointOffset(self:Get("textOffsetY"), -800, 800, defaults.textOffsetY)
	local valueOffsetX = pointOffset(self:Get("valueOffsetX"), -800, 800, defaults.valueOffsetX)
	local valueOffsetY = pointOffset(self:Get("valueOffsetY"), -800, 800, defaults.valueOffsetY)
	local barPosition = self:Get("barPosition")
	if barPosition ~= "TOP" and barPosition ~= "BOTTOM" then barPosition = "BACKGROUND" end
	local align = data.textAlign or self:Get("align")
	if align ~= "CENTER" and align ~= "RIGHT" then align = "LEFT" end
	local font = resolveFont(self:Get("fontFace"))
	local style = normalizeFontStyle(self:Get("fontOutline"))
	local fontSize = clampNumber(data.fontSize or self:Get("fontSize"), 8, 44, defaults.fontSize)
	local width = snapSize(clampNumber(self:Get("width"), 120, 800, defaults.width))
	row.tooltipType = data.tooltipType
	row.tooltipData = data.tooltipData
	row:SetHeight(rowHeight)
	row:SetWidth(width)
	row.text:SetText(data.text or "")
	row.value:SetText(data.valueText or "")
	row.text:SetDrawLayer("OVERLAY", 7)
	row.value:SetDrawLayer("OVERLAY", 7)
	row.text:SetJustifyH(align)
	row.value:SetJustifyH("RIGHT")
	applyFontString(row.text, font, fontSize, style)
	applyFontString(row.value, font, fontSize, style)
	row.bar:SetMinMaxValues(0, data.max or 100)
	row.bar:SetValue(data.value or 0)
	row.bar:SetShown(data.hideBar ~= true)
	row.icon:SetShown(data.icon ~= nil)
	if data.icon then row.icon:SetTexture(data.icon) end
	row.icon:ClearAllPoints()
	row.icon:SetPoint("LEFT", row, "LEFT", iconOffsetX, iconOffsetY)
	row.bar:ClearAllPoints()
	row.bar:SetHeight(barHeight)
	local leftAnchor = data.icon and row.icon or row
	local leftPoint = data.icon and "RIGHT" or "LEFT"
	local leftOffset = (data.icon and iconGap or 0) + barOffsetX
	if data.hideBar then
		row.bar:SetPoint("LEFT", row, "LEFT", 0, 0)
	elseif barPosition == "TOP" then
		row.bar:SetPoint("TOPLEFT", leftAnchor, leftPoint, leftOffset, barOffsetY)
		row.bar:SetPoint("TOPRIGHT", row, "TOPRIGHT", barWidthOffset, barOffsetY)
	elseif barPosition == "BOTTOM" then
		row.bar:SetPoint("BOTTOMLEFT", leftAnchor, leftPoint, leftOffset, barOffsetY)
		row.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", barWidthOffset, barOffsetY)
	else
		row.bar:SetPoint("LEFT", leftAnchor, leftPoint, leftOffset, barOffsetY)
		row.bar:SetPoint("RIGHT", row, "RIGHT", barWidthOffset, barOffsetY)
	end
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", row, "LEFT", textOffsetX, textOffsetY)
	row.text:SetPoint("RIGHT", row, "RIGHT", valueOffsetX - 48, textOffsetY)
	row.value:ClearAllPoints()
	row.value:SetPoint("RIGHT", row, "RIGHT", valueOffsetX, valueOffsetY)
	local color = normalizeColor(data.color, defaults.objectiveColor)
	row.bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	local globalTextColor = self:Get("useGlobalTextColor") and self:Get("textColor") or nil
	setTextColor(row.text, globalTextColor or data.textColor or color)
	setTextColor(row.value, globalTextColor or data.valueColor or color)
	local bindingKey = "row-" .. tostring(index)
	local durationBinding = data.durationBinding
	if durationBinding and durationBinding.state and durationBinding.state.active then
		local elapsed = tonumber(durationBinding.state.elapsed) or 0
		local duration = tonumber(durationBinding.duration) or 0
		if duration > 0 and elapsed < duration then
			local durationObject = self:UpdateTimerDurationObject(durationBinding.key, getChallengeStartTime(self, durationBinding.state), duration)
			if not (durationObject and self:BindTimerText(row.value, bindingKey, durationObject, durationBinding.mode, durationBinding.textFormat)) then self:ReleaseTimerTextBinding(bindingKey) end
		else
			self:ReleaseTimerTextBinding(bindingKey)
		end
	else
		self:ReleaseTimerTextBinding(bindingKey)
	end
	row:Show()
end

function Timer:AddAffixTooltipLines(state)
	if not (state and state.affixNames and #state.affixNames > 0) then return end
	for index, name in ipairs(state.affixNames) do
		local description
		local affixID = state.affixes and state.affixes[index]
		if affixID and C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
			local ok, affixName, affixDescription = pcall(C_ChallengeMode.GetAffixInfo, affixID)
			if ok then
				name = affixName or name
				description = affixDescription
			end
		end
		GameTooltip:AddLine(name or "", 1, 0.82, 0)
		if description and description ~= "" then GameTooltip:AddLine(description, 1, 1, 1, true) end
	end
end

function Timer:AddSingleAffixTooltipLine(state, index)
	if not (state and index) then return end
	local name = state.affixNames and state.affixNames[index]
	local description
	local affixID = state.affixes and state.affixes[index]
	if affixID and C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
		local ok, affixName, affixDescription = pcall(C_ChallengeMode.GetAffixInfo, affixID)
		if ok then
			name = affixName or name
			description = affixDescription
		end
	end
	GameTooltip:AddLine(name or "", 1, 0.82, 0)
	if description and description ~= "" then GameTooltip:AddLine(description, 1, 1, 1, true) end
end

function Timer:AddDeathTooltipLines(state)
	if not state then return end
	GameTooltip:AddLine(self:GetDeathDisplayText(state.deaths), 1, 1, 1)
	GameTooltip:AddDoubleLine(L["mythicPlusTimerTimeLost"] or "Time lost", secondsToText(state.timeLost or 0), 1, 0.82, 0, 1, 1, 1)
	if type(state.deathMembers) == "table" and #state.deathMembers > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["mythicPlusTimerDeathsByPlayer"] or "Player deaths", 1, 0.82, 0)
		local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {}
		for _, entry in ipairs(state.deathMembers) do
			local color = entry.class and classColors[entry.class]
			local r, g, b = 1, 1, 1
			if color then
				r = color.r or r
				g = color.g or g
				b = color.b or b
			end
			GameTooltip:AddDoubleLine(entry.name or "", tostring(entry.count or 0), r, g, b, 1, 1, 1)
		end
	end
end

function Timer:ShowRowTooltip(row)
	if not self:Get("tooltip") or not row or not row.tooltipType then return end
	local state = self.lastState or self:BuildState()
	local data = row.tooltipData
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	if row.tooltipType == "affixes" then
		self:AddAffixTooltipLines(data or state)
	elseif row.tooltipType == "deaths" then
		self:AddDeathTooltipLines(data or state)
	elseif row.tooltipType == "objective" and data then
		GameTooltip:AddLine(data.text or "", 1, 1, 1)
		local value = self:FormatObjectiveValue(state, data)
		if value ~= "" then GameTooltip:AddLine(value, 1, 0.82, 0) end
	else
		return
	end
	GameTooltip:Show()
end

function Timer:ShowPanelTooltip(region)
	if not self:Get("tooltip") or not region or not region.tooltipType then return end
	GameTooltip:SetOwner(region, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	if region.tooltipType == "affix" and region.tooltipData then
		self:AddSingleAffixTooltipLine(region.tooltipData.state or self.lastState, region.tooltipData.index)
	elseif region.tooltipType == "deaths" then
		self:AddDeathTooltipLines(region.tooltipData or self.lastState)
	elseif region.tooltipType == "objective" and region.tooltipData then
		local state = self.lastState or self:BuildState()
		GameTooltip:AddLine(region.tooltipData.text or "", 1, 1, 1)
		local value = self:FormatObjectiveValue(state, region.tooltipData)
		if value ~= "" then GameTooltip:AddLine(value, 1, 0.82, 0) end
	else
		return
	end
	GameTooltip:Show()
end

function Timer:LayoutRows(count, panelOffset)
	local frame = self:EnsureFrame()
	local spacing = snapToPixel(clampNumber(self:Get("rowSpacing"), 0, 24, defaults.rowSpacing))
	local growth = self:Get("growth") == "UP" and "UP" or "DOWN"
	local width = snapSize(clampNumber(self:Get("width"), 120, 800, defaults.width))
	local rowHeight = snapSize(clampNumber(self:Get("rowHeight"), 12, 48, defaults.rowHeight))
	panelOffset = snapToPixel(tonumber(panelOffset) or 0)
	local rowsHeight = count > 0 and (count * rowHeight + (count - 1) * spacing) or 0
	local height = panelOffset + rowsHeight
	if height <= 0 then height = rowHeight end
	frame:SetSize(width, snapSize(height))
	self:ApplyFrameStyle()
	for index = 1, #frame.rows do
		local row = frame.rows[index]
		row:ClearAllPoints()
		if index <= count then
			if index == 1 then
				if growth == "UP" then
					row:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
				else
					row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -panelOffset)
				end
			elseif growth == "UP" then
				row:SetPoint("BOTTOMLEFT", frame.rows[index - 1], "TOPLEFT", 0, spacing)
			else
				row:SetPoint("TOPLEFT", frame.rows[index - 1], "BOTTOMLEFT", 0, -spacing)
			end
			row:SetWidth(width)
			row:Show()
		else
			row:Hide()
			self:ReleaseTimerTextBinding("row-" .. tostring(index))
		end
	end
end

function Timer:Refresh()
	if not self.initialized then return end
	local frame = self:EnsureFrame()
	local layoutMode = self:GetLayoutMode()
	if layoutMode ~= "FLOW" then self:ApplyFrameStyle() end
	local enabled = self:IsEnabled()
	local state = self:BuildState()
	self:UpdateObjectiveSplits(state)
	self.lastState = state
	local inEditMode = self:IsInEditMode()
	local inMythicPlus = isInMythicPlus()
	local shouldShow = enabled and (state.active or inMythicPlus or not self:Get("showOnlyInMythicPlus") or inEditMode)
	if not shouldShow then
		self:HideAllElements()
		frame:Hide()
		self:ApplyObjectiveTrackerVisibility(state, false)
		return
	end

	if layoutMode == "FLOW" and self.PanelFlow then
		self:HidePanelElements(true)
		self:HideListElements()
		if frame.windowBackground then frame.windowBackground:Hide() end
		if frame.decorBars then
			if frame.decorBars.header then frame.decorBars.header:Hide() end
			if frame.decorBars.footer then frame.decorBars.footer:Hide() end
		end
		if frame.borderFrame then frame.borderFrame:Hide() end
		local timeLeft = (state.timeLimit or 0) - (state.elapsed or 0)
		local twoChest, threeChest = calculateChestTimers(state.timeLimit or 0, state.affixes or {})
		local flowHeight = self.PanelFlow:Render(state, timeLeft, twoChest, threeChest)
		local flowShown = (tonumber(flowHeight) or 0) > 0
		frame:SetShown(flowShown)
		self:ApplyObjectiveTrackerVisibility(state, flowShown)
		return
	end
	if self.PanelFlow then self.PanelFlow:Hide() end

	local rows = 0
	local timeLeft = (state.timeLimit or 0) - (state.elapsed or 0)
	local twoChest, threeChest = calculateChestTimers(state.timeLimit or 0, state.affixes or {})
	local elapsed = tonumber(state.elapsed) or 0
	local panelOffset = self:RenderPanel(state, timeLeft, twoChest, threeChest)
	if layoutMode == "PANEL" then
		self:HideListDecorContent()
		self:LayoutRows(0, panelOffset)
		local panelShown = panelOffset > 0
		frame:SetShown(panelShown)
		self:ApplyObjectiveTrackerVisibility(state, panelShown)
		return
	end

	local decorContentShown = {}
	local headerEntries = {}
	local footerEntry
	local footerContent = self:GetListFooterContent()
	local deathPlacement = self:GetListDeathPlacement()
	local function addListEntry(kind, data)
		if kind == "DUNGEON" and self:Get("dungeonPlacement") == "HEADER" then
			headerEntries.DUNGEON = data
		elseif kind == "DEATHS" and deathPlacement == "HEADER" then
			headerEntries.DEATHS = data
		elseif footerContent == kind then
			footerEntry = data
		else
			rows = rows + 1
			self:SetRow(rows, data)
		end
	end

	if self:Get("showDungeon") then
		addListEntry("DUNGEON", {
			text = self:GetDungeonDisplayText(state),
			color = self:Get("dungeonColor"),
			fontSize = self:Get("titleFontSize"),
			max = 1,
			value = 1,
		})
	end
	if self:Get("showAffixes") and state.affixNames and #state.affixNames > 0 then
		rows = rows + 1
		self:SetRow(rows, {
			text = self:GetAffixDisplayText(state),
			color = self:Get("affixColor"),
			max = 1,
			value = 1,
			tooltipType = "affixes",
			tooltipData = state,
		})
	end
	if self:Get("showTimer") then
		local timerDisplay = self:Get("timerDisplay")
		local timeLimit = state.timeLimit or 1
		local isElapsedTimer = timerDisplay == "ELAPSED_TOTAL"
		local color = timeLeft <= 0 and self:Get("timerExpiredColor") or self:Get("timerColor")
		local timerAlign = self:Get("timerAlign")
		if timerAlign ~= "LEFT" and timerAlign ~= "CENTER" and timerAlign ~= "RIGHT" then timerAlign = nil end
		addListEntry("TIMER", {
			text = isElapsedTimer and (L["mythicPlusTimerTimeElapsed"] or "Time elapsed") or (L["mythicPlusTimerTimeLeft"] or "Time left"),
			valueText = self:GetTimerDisplayText(state, timeLeft),
			color = color,
			fontSize = self:Get("timerFontSize"),
			textAlign = timerAlign,
			max = timeLimit,
			value = isElapsedTimer and math.min(timeLimit, math.max(0, elapsed)) or math.max(0, timeLeft),
			durationBinding = {
				key = "rowTimer",
				state = state,
				duration = timeLimit,
				mode = timerDisplay,
			},
		})
	end
	if self:Get("showChestTimers") then
		if elapsed <= twoChest then
			rows = rows + 1
			self:SetRow(rows, {
				text = "+2",
				valueText = secondsToText(twoChest - elapsed),
				color = self:Get("chestColor"),
				max = state.timeLimit or 1,
				value = math.max(0, twoChest - elapsed),
				durationBinding = {
					key = "rowChest2",
					state = state,
					duration = twoChest,
					mode = "REMAINING",
				},
			})
		end
		if elapsed <= threeChest then
			rows = rows + 1
			self:SetRow(rows, {
				text = "+3",
				valueText = secondsToText(threeChest - elapsed),
				color = self:Get("chestColor"),
				max = state.timeLimit or 1,
				value = math.max(0, threeChest - elapsed),
				durationBinding = {
					key = "rowChest3",
					state = state,
					duration = threeChest,
					mode = "REMAINING",
				},
			})
		end
	end
	if self:ShouldShowDeathDisplay(state) then
		local showDeathInline = self:Get("deathShowTimeLost") == true
		local deathBarMode = self:Get("deathBarMode")
		local deathBarMax = 10
		local deathBarValue = math.min(deathBarMax, math.max(0, tonumber(state.deaths) or 0))
		if deathBarMode == "TIME_LOST" then
			deathBarMax = math.max(1, tonumber(state.timeLimit) or 0)
			deathBarValue = math.min(deathBarMax, math.max(0, tonumber(state.timeLost) or 0))
		end
		addListEntry("DEATHS", {
			text = self:GetDeathDisplayText(state.deaths, nil, state.timeLost),
			valueText = showDeathInline and "" or string.format("-%s", secondsToText(state.timeLost or 0)),
			color = self:Get("deathColor"),
			fontSize = self:Get("fontSize"),
			max = deathBarMax,
			value = deathBarValue,
			hideBar = deathBarMode == "NONE",
			tooltipType = "deaths",
			tooltipData = state,
		})
	end
	if self:Get("showEnemyForces") and state.enemyForces then
		local percent = tonumber(state.enemyForces.percent) or 0
		addListEntry("ENEMY_FORCES", {
			text = state.enemyForces.text ~= "" and state.enemyForces.text or (L["mythicPlusTimerEnemyForces"] or "Enemy Forces"),
			valueText = self:FormatEnemyForcesValue(state, state.enemyForces),
			color = self:Get("enemyForcesColor"),
			max = 100,
			value = percent,
			hideBar = not self:Get("showEnemyForcesBar"),
		})
	end
	if self:Get("showObjectives") then
		for _, objective in ipairs(state.objectives or {}) do
			rows = rows + 1
			local percent = tonumber(objective.percent)
			self:SetRow(rows, {
				text = objective.text,
				valueText = self:FormatObjectiveValue(state, objective),
				color = objective.completed and self:Get("objectiveCompleteColor") or self:Get("objectiveColor"),
				max = self:Get("showObjectiveBars") and 100 or 1,
				value = self:Get("showObjectiveBars") and (percent or (objective.completed and 100 or 0)) or 1,
				hideBar = not self:Get("showObjectiveBars"),
				tooltipType = "objective",
				tooltipData = objective,
			})
		end
	end

	local dungeonHeader = headerEntries.DUNGEON
	local deathsHeader = headerEntries.DEATHS
	if dungeonHeader and deathsHeader then
		local deathText = deathsHeader.text or ""
		if deathsHeader.valueText and deathsHeader.valueText ~= "" then deathText = deathText .. " " .. deathsHeader.valueText end
		self:SetListDecorContent("header", {
			text = dungeonHeader.text,
			valueText = deathText,
			fontSize = dungeonHeader.fontSize,
			valueFontSize = deathsHeader.fontSize,
			textColor = dungeonHeader.color,
			valueColor = deathsHeader.color,
			tooltipType = deathsHeader.tooltipType,
			tooltipData = deathsHeader.tooltipData,
		})
		decorContentShown.header = true
	elseif dungeonHeader then
		dungeonHeader.fullWidthText = true
		dungeonHeader.textAlign = "CENTER"
		self:SetListDecorContent("header", dungeonHeader)
		decorContentShown.header = true
	elseif deathsHeader then
		self:SetListDecorContent("header", deathsHeader)
		decorContentShown.header = true
	end
	if footerEntry then
		self:SetListDecorContent("footer", footerEntry)
		decorContentShown.footer = true
	end
	self:HideListDecorContent(decorContentShown)
	self:LayoutRows(rows, panelOffset)
	local frameShown = rows > 0 or next(decorContentShown) ~= nil or panelOffset > 0
	frame:SetShown(frameShown)
	self:ApplyObjectiveTrackerVisibility(state, frameShown)
end

function Timer:ShowTooltip()
	if not self:Get("tooltip") then return end
	if self:Get("layoutMode") == "LIST" then return end
	local frame = self.frame
	if not frame then return end
	local state = self:BuildState()
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["mythicPlusTimerTitle"] or "Mythic+ Timer")
	GameTooltip:AddLine(string.format("+%d - %s", state.level or 0, state.mapName or (L["mythicPlusTimerUnknownDungeon"] or "Mythic+ Dungeon")), 1, 1, 1)
	if state.affixNames and #state.affixNames > 0 then
		GameTooltip:AddLine(" ")
		self:AddAffixTooltipLines(state)
	end
	if (state.deaths or 0) > 0 or (state.timeLost or 0) > 0 then
		GameTooltip:AddLine(" ")
		self:AddDeathTooltipLines(state)
	end
	GameTooltip:Show()
end

function Timer:ScheduleTick()
	if self.tickScheduled then return end
	self.tickScheduled = true
	local state = self.lastState
	local interval = (state and state.active) and TICK_INTERVAL or clampNumber(self:Get("updateRate"), 0.1, 5, defaults.updateRate)
	C_Timer.After(interval, function()
		Timer.tickScheduled = nil
		if Timer:IsEnabled() and (isInMythicPlus() or Timer:IsInEditMode()) then
			Timer:Refresh()
			Timer:ScheduleTick()
		end
	end)
end

function Timer:ScheduleRunInfoRefresh()
	if not C_Timer then return end
	C_Timer.After(0.2, function()
		if Timer:IsEnabled() and isInMythicPlus() then Timer:Refresh() end
	end)
	C_Timer.After(1, function()
		if Timer:IsEnabled() and isInMythicPlus() then Timer:Refresh() end
	end)
end

function Timer:RegisterEvents()
	local frame = self.eventFrame
	if not frame or self.eventsRegistered then return end
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:RegisterEvent("WORLD_STATE_TIMER_START")
	frame:RegisterEvent("WORLD_STATE_TIMER_STOP")
	frame:RegisterEvent("CHALLENGE_MODE_START")
	frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
	frame:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
	frame:RegisterEvent("CHALLENGE_MODE_RESET")
	frame:RegisterEvent("SCENARIO_UPDATE")
	frame:RegisterEvent("CRITERIA_UPDATE")
	frame:RegisterEvent("QUEST_LOG_UPDATE")
	frame:RegisterEvent("PLAYER_DEAD")
	frame:RegisterEvent("PLAYER_ALIVE")
	frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	frame:RegisterEvent("UNIT_DIED")
	self.eventsRegistered = true
end

function Timer:UnregisterEvents()
	self:ApplyObjectiveTrackerVisibility(self.lastState, false)
	self:HideAllElements()
	if self.frame then self.frame:Hide() end
end

function Timer:UpdateEventState()
	self:RegisterEvents()
	if self:IsEnabled() then
		self:Refresh()
		self:ScheduleTick()
	else
		self:ApplyObjectiveTrackerVisibility(self.lastState, false)
		self:HideAllElements()
		if self.frame then self.frame:Hide() end
	end
end

function Timer:IsInEditMode()
	return EditMode and EditMode.IsInEditMode and EditMode:IsInEditMode()
end

local function dropdownSetting(name, getter, setter, options, parentId, height, isEnabled, isShown, newTagID)
	return {
		name = name,
		kind = SettingType.Dropdown,
		parentId = parentId,
		height = height or 160,
		isEnabled = isEnabled,
		isShown = isShown,
		newTagID = newTagID,
		get = getter,
		set = function(_, value) setter(value) end,
		generator = function(_, root)
			for _, option in ipairs(type(options) == "function" and options() or options) do
				root:CreateRadio(option.label, function() return getter() == option.value end, function() setter(option.value) end)
			end
		end,
	}
end

local function sliderSetting(name, getter, setter, minValue, maxValue, step, parentId, formatter, isEnabled, isShown)
	return {
		name = name,
		kind = SettingType.Slider,
		parentId = parentId,
		minValue = minValue,
		maxValue = maxValue,
		valueStep = step or 1,
		allowInput = true,
		formatter = formatter,
		isEnabled = isEnabled,
		isShown = isShown,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function checkboxSetting(name, getter, setter, parentId, isEnabled, isShown, newTagID)
	return {
		name = name,
		kind = SettingType.Checkbox,
		parentId = parentId,
		isEnabled = isEnabled,
		isShown = isShown,
		newTagID = newTagID,
		get = getter,
		set = function(_, value) setter(value == true) end,
	}
end

local function inputSetting(name, getter, setter, parentId, isEnabled, tooltip, maxChars, isShown)
	return {
		name = name,
		kind = SettingType.Input,
		parentId = parentId,
		isEnabled = isEnabled,
		isShown = isShown,
		tooltip = tooltip,
		maxChars = maxChars or 128,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function colorSetting(name, getter, setter, default, parentId, isEnabled, isShown)
	return {
		name = name,
		kind = SettingType.Color,
		parentId = parentId,
		default = default,
		hasOpacity = true,
		isEnabled = isEnabled,
		isShown = isShown,
		get = getter,
		set = function(_, value) setter(normalizeColor(value, default)) end,
	}
end

local function divider(parentId)
	return { name = "", kind = SettingType.Divider, parentId = parentId }
end

local function requestSettingsRefresh()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RequestRefreshSettings then addon.EditModeLib.internal:RequestRefreshSettings() end
end

local function orderSettingsByParent(settings)
	local topLevel = {}
	local childrenByParent = {}
	local ordered = {}
	for _, setting in ipairs(settings or {}) do
		if setting.parentId then
			childrenByParent[setting.parentId] = childrenByParent[setting.parentId] or {}
			childrenByParent[setting.parentId][#childrenByParent[setting.parentId] + 1] = setting
		else
			topLevel[#topLevel + 1] = setting
		end
	end
	for _, setting in ipairs(topLevel) do
		ordered[#ordered + 1] = setting
		local id = setting.id or setting.name
		local children = id and childrenByParent[id]
		if children then
			for _, child in ipairs(children) do
				ordered[#ordered + 1] = child
			end
			childrenByParent[id] = nil
		end
	end
	for _, children in pairs(childrenByParent) do
		for _, child in ipairs(children) do
			ordered[#ordered + 1] = child
		end
	end
	return ordered
end

local function applyParentVisibility(settings)
	local byId = {}
	for _, setting in ipairs(settings or {}) do
		local id = setting.id or setting.name
		if id then byId[id] = setting end
	end
	for _, setting in ipairs(settings or {}) do
		local parent = setting.parentId and byId[setting.parentId]
		if parent and parent.isShown then
			local ownIsShown = setting.isShown
			local parentIsShown = parent.isShown
			setting.isShown = function(...)
				local ok, shown = pcall(parentIsShown, ...)
				if ok and shown == false then return false end
				if ownIsShown then
					local ownOk, ownShown = pcall(ownIsShown, ...)
					return not (ownOk and ownShown == false)
				end
				return true
			end
		end
	end
end

function Timer:BuildEditModeSettings()
	if not SettingType then return {} end
	local displayId = "mpt-display"
	local behaviorId = "mpt-behavior"
	local layoutId = "mpt-layout"
	local barId = "mpt-bars"
	local fontId = "mpt-font"
	local colorId = "mpt-colors"
	local backgroundId = "mpt-background"
	local headerId = "mpt-header-bar"
	local footerId = "mpt-footer-bar"
	local borderId = "mpt-border"

	local function get(key) return function() return Timer:Get(key) end end
	local function set(key, normalizer, refreshSettings)
		return function(value)
			if normalizer then value = normalizer(value) end
			Timer:Set(key, value)
			if refreshSettings then requestSettingsRefresh() end
		end
	end
	local function getPanelEnemyBarOffset(axis)
		return function()
			if Timer:Get("panelEnemyBarAttachToObjectives") == true then return Timer:GetPanelEnemyBarAttachOffset(axis) end
			return Timer:Get("panelEnemyBarOffset" .. axis)
		end
	end
	local function setPanelEnemyBarOffset(axis)
		return function(value)
			local key = Timer:Get("panelEnemyBarAttachToObjectives") == true and ("panelEnemyBarAttachOffset" .. axis) or ("panelEnemyBarOffset" .. axis)
			Timer:Set(key, clampNumber(value, -800, 800, defaults[key]))
		end
	end
	local function enabledWhen(key)
		return function() return Timer:Get(key) == true end
	end
	local function enemyBarTextEnabled()
		return Timer:Get("showPanelEnemyBar") == true and (Timer:Get("panelEnemyBarTextEnabled") == true or Timer:Get("panelEnemyBarText2Enabled") == true)
	end
	local function shownWhen(key)
		return function() return Timer:Get(key) == true end
	end
	local function allEnabled(...)
		local keys = { ... }
		return function()
			for _, key in ipairs(keys) do
				if Timer:Get(key) ~= true then return false end
			end
			return true
		end
	end
	local allShown = allEnabled
	local function allEnabledAndNot(disabledKey, ...)
		local keys = { ... }
		return function()
			if Timer:Get(disabledKey) == true then return false end
			for _, key in ipairs(keys) do
				if Timer:Get(key) ~= true then return false end
			end
			return true
		end
	end
	local function objectiveTimesEnabled()
		return Timer:Get("showObjectives") == true and Timer:Get("showObjectiveTimes") == true
	end
	local function isListMode()
		return Timer:GetLayoutMode() == "LIST"
	end
	local function isPanelMode()
		return Timer:GetLayoutMode() == "PANEL"
	end
	local function isLegacyMode()
		return Timer:GetLayoutMode() ~= "FLOW"
	end
	local function deathRowBarEnabled()
		return Timer:Get("showDeaths") == true and Timer:GetListDeathPlacement() == "ROW"
	end
	local function setDeathPlacement(value)
		if value == "FOOTER" then
			Timer:Set("footerContent", "DEATHS")
		else
			value = value == "HEADER" and "HEADER" or "ROW"
			if Timer:GetListFooterContent() == "DEATHS" then Timer:Set("footerContent", "NONE") end
			Timer:Set("deathPlacement", value)
		end
		requestSettingsRefresh()
	end
	local function setFooterContent(value)
		if value ~= "TIMER" and value ~= "DEATHS" and value ~= "ENEMY_FORCES" then value = "NONE" end
		Timer:Set("footerContent", value)
		requestSettingsRefresh()
	end
	local function headerContentEnabled()
		return (Timer:Get("showDungeon") == true and Timer:Get("dungeonPlacement") == "HEADER") or (Timer:Get("showDeaths") == true and Timer:GetListDeathPlacement() == "HEADER")
	end
	local function footerContentEnabled()
		local content = Timer:GetListFooterContent()
		if content == "TIMER" then return Timer:Get("showTimer") == true end
		if content == "DEATHS" then return Timer:Get("showDeaths") == true end
		if content == "ENEMY_FORCES" then return Timer:Get("showEnemyForces") == true end
		return false
	end
	local function oneDecimalSeconds(value)
		return string.format("%.1fs", tonumber(value) or 0)
	end
	local function wholePixels(value)
		return tostring(math.floor((tonumber(value) or 0) + 0.5))
	end
	local function normalizeEnemyForcesValueMode(value)
		if value ~= "BOTH" and value ~= "PERCENT" and value ~= "COUNT" then return "DEFAULT" end
		return value
	end
	local function normalizePanelEnemyForcesValueMode(value)
		if value ~= "BOTH" and value ~= "PERCENT" and value ~= "COUNT" then return "BOTH" end
		return value
	end
	local enemyForcesValueOptions = {
		{ value = "DEFAULT", label = L["Default"] or "Default" },
		{ value = "BOTH", label = _G.STATUS_TEXT_BOTH or "Both" },
		{ value = "PERCENT", label = _G.STATUS_TEXT_PERCENT or "Percentage" },
		{ value = "COUNT", label = L["mythicPlusTimerEnemyForcesCount"] or "Count" },
	}
	local panelEnemyForcesValueOptions = {
		{ value = "BOTH", label = _G.STATUS_TEXT_BOTH or "Both" },
		{ value = "PERCENT", label = _G.STATUS_TEXT_PERCENT or "Percentage" },
		{ value = "COUNT", label = L["mythicPlusTimerEnemyForcesCount"] or "Count" },
	}
	local anchorOptions = {
		{ value = "TOPLEFT", label = "Top left" },
		{ value = "TOP", label = _G.TOP or "Top" },
		{ value = "TOPRIGHT", label = "Top right" },
		{ value = "LEFT", label = _G.LEFT or "Left" },
		{ value = "CENTER", label = _G.CENTER or "Center" },
		{ value = "RIGHT", label = _G.RIGHT or "Right" },
		{ value = "BOTTOMLEFT", label = "Bottom left" },
		{ value = "BOTTOM", label = _G.BOTTOM or "Bottom" },
		{ value = "BOTTOMRIGHT", label = "Bottom right" },
	}
	local function anchorSetting(key, parentId, isShown, name, isEnabled)
		return dropdownSetting(name or L["mythicPlusTimerAnchor"] or "Anchor", get(key), set(key, normalizePoint), anchorOptions, parentId, 220, isEnabled, isShown)
	end
	local function decorBarSettings(kind, sectionId)
		local prefix = kind == "footer" and "footerBar" or "headerBar"
		local enabled = enabledWhen(prefix .. "Enabled")
		local lsmEnabled = function() return Timer:Get(prefix .. "Enabled") == true and Timer:Get(prefix .. "UseCustomTexture") ~= true end
		local customEnabled = function() return Timer:Get(prefix .. "Enabled") == true and Timer:Get(prefix .. "UseCustomTexture") == true end
		local positionEnabled = function()
			if Timer:Get(prefix .. "Enabled") == true then return true end
			if not isListMode() then return false end
			if kind == "header" then return headerContentEnabled() end
			return footerContentEnabled()
		end
		local entries = {
			checkboxSetting(L["mythicPlusTimerShowDecorBackground"] or "Show background", get(prefix .. "Enabled"), set(prefix .. "Enabled", nil, true), sectionId),
			checkboxSetting(L["damageMeterHeaderBackgroundUseCustomTexture"] or "Custom texture", get(prefix .. "UseCustomTexture"), set(prefix .. "UseCustomTexture", nil, true), sectionId, enabled),
			inputSetting(L["damageMeterHeaderBackgroundCustomTexture"] or "Atlas name or texture ID", get(prefix .. "CustomTexture"), set(prefix .. "CustomTexture", trimTextureInput), sectionId, customEnabled, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
			dropdownSetting(L["Texture"] or "Texture", get(prefix .. "Texture"), set(prefix .. "Texture"), function() return buildMediaOptions("statusbar", false) end, sectionId, 260, lsmEnabled),
			colorSetting(L["damageMeterHeaderBackgroundColor"] or "Color", get(prefix .. "Color"), set(prefix .. "Color"), defaults[prefix .. "Color"], sectionId, enabled),
			anchorSetting(prefix .. "Anchor", sectionId, nil, L["Anchor"] or "Anchor", positionEnabled),
			sliderSetting(L["damageMeterHeaderBackgroundSizeOffsetX"] or "Width offset", get(prefix .. "SizeOffsetX"), set(prefix .. "SizeOffsetX", function(value) return clampNumber(value, -1000, 1000, defaults[prefix .. "SizeOffsetX"]) end), -1000, 1000, 1, sectionId, nil, positionEnabled),
			sliderSetting(L["damageMeterHeaderBackgroundSizeOffsetY"] or "Height offset", get(prefix .. "SizeOffsetY"), set(prefix .. "SizeOffsetY", function(value) return clampNumber(value, -300, 300, defaults[prefix .. "SizeOffsetY"]) end), -300, 300, 1, sectionId, nil, positionEnabled),
			sliderSetting(L["Offset X"] or "Offset X", get(prefix .. "OffsetX"), set(prefix .. "OffsetX", function(value) return clampNumber(value, -1000, 1000, defaults[prefix .. "OffsetX"]) end), -1000, 1000, 1, sectionId, nil, positionEnabled),
			sliderSetting(L["Offset Y"] or "Offset Y", get(prefix .. "OffsetY"), set(prefix .. "OffsetY", function(value) return clampNumber(value, -1000, 1000, defaults[prefix .. "OffsetY"]) end), -1000, 1000, 1, sectionId, nil, positionEnabled),
		}
		if kind == "footer" then
			table.insert(entries, 2, dropdownSetting(L["mythicPlusTimerFooterContent"] or "Footer content", function() return Timer:GetListFooterContent() end, setFooterContent, {
				{ value = "NONE", label = _G.NONE or "None" },
				{ value = "TIMER", label = L["mythicPlusTimerFooterTimer"] or "Timer" },
				{ value = "DEATHS", label = L["mythicPlusTimerDeaths"] or "Deaths" },
				{ value = "ENEMY_FORCES", label = L["mythicPlusTimerEnemyForces"] or "Enemy Forces" },
			}, sectionId, 180, nil, isListMode))
		end
		return entries
	end

	local settings = {
		{ name = L["mythicPlusTimerSectionDisplay"] or "Display", kind = SettingType.Collapsible, id = displayId, defaultCollapsed = false, isShown = isListMode },
		checkboxSetting(L["mythicPlusTimerShowDungeon"] or "Show dungeon and level", get("showDungeon"), set("showDungeon"), displayId, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerDungeonDisplay"] or "Dungeon label", get("dungeonDisplay"), set("dungeonDisplay"), {
			{ value = "NAME_LEVEL", label = L["mythicPlusTimerDungeonDisplayNameLevel"] or "Name + level" },
			{ value = "SHORT_LEVEL", label = L["mythicPlusTimerDungeonDisplayShortLevel"] or "Abbreviation + level" },
			{ value = "NAME", label = L["mythicPlusTimerDungeonDisplayName"] or "Name" },
			{ value = "SHORT", label = L["mythicPlusTimerDungeonDisplayShort"] or "Abbreviation" },
			{ value = "LEVEL", label = L["mythicPlusTimerDungeonDisplayLevel"] or "Level" },
		}, displayId, 180, enabledWhen("showDungeon"), isListMode),
		dropdownSetting(L["mythicPlusTimerDungeonPlacement"] or "Dungeon placement", get("dungeonPlacement"), set("dungeonPlacement", function(value) return value == "HEADER" and "HEADER" or "ROW" end, true), {
			{ value = "ROW", label = L["mythicPlusTimerPlacementListRow"] or "List row" },
			{ value = "HEADER", label = L["mythicPlusTimerPlacementHeader"] or "Header" },
		}, displayId, 160, enabledWhen("showDungeon"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowAffixes"] or "Show affixes", get("showAffixes"), set("showAffixes", nil, true), displayId, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerAffixDisplay"] or "Affix display", get("affixDisplay"), set("affixDisplay"), {
			{ value = "ICON_TEXT", label = L["mythicPlusTimerAffixDisplayIconText"] or "Text + icon" },
			{ value = "ICON", label = L["mythicPlusTimerAffixDisplayIcon"] or "Icon" },
			{ value = "TEXT", label = L["mythicPlusTimerAffixDisplayText"] or "Text" },
		}, displayId, 160, enabledWhen("showAffixes"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowTimer"] or "Show timer", get("showTimer"), set("showTimer"), displayId, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerTimerDisplay"] or "Timer display", get("timerDisplay"), set("timerDisplay"), {
			{ value = "TIME_LEFT", label = L["mythicPlusTimerTimerDisplayTimeLeft"] or "Time left" },
			{ value = "TIME_LEFT_TOTAL", label = L["mythicPlusTimerTimerDisplayTimeLeftTotal"] or "Time left / total time" },
			{ value = "ELAPSED_TOTAL", label = L["mythicPlusTimerTimerDisplayElapsedTotal"] or "Time elapsed / total time" },
			{ value = "TOTAL", label = L["mythicPlusTimerTimerDisplayTotal"] or "Total time" },
		}, displayId, 220, enabledWhen("showTimer"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowChestTimers"] or "Show +2/+3 timers", get("showChestTimers"), set("showChestTimers"), displayId, nil, isListMode),
		checkboxSetting(L["mythicPlusTimerShowDeaths"] or "Show deaths", get("showDeaths"), set("showDeaths"), displayId, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerDeathDisplay"] or "Death display", get("deathDisplay"), set("deathDisplay"), {
			{ value = "ICON_TEXT", label = L["mythicPlusTimerAffixDisplayIconText"] or "Text + icon" },
			{ value = "ICON", label = L["mythicPlusTimerAffixDisplayIcon"] or "Icon" },
			{ value = "TEXT", label = L["mythicPlusTimerAffixDisplayText"] or "Text" },
		}, displayId, 160, enabledWhen("showDeaths"), isListMode),
		dropdownSetting(L["mythicPlusTimerDeathPlacement"] or "Deaths placement", function() return Timer:GetListDeathPlacement() end, setDeathPlacement, {
			{ value = "ROW", label = L["mythicPlusTimerPlacementListRow"] or "List row" },
			{ value = "HEADER", label = L["mythicPlusTimerPlacementHeader"] or "Header" },
			{ value = "FOOTER", label = L["mythicPlusTimerPlacementFooter"] or "Footer" },
		}, displayId, 180, enabledWhen("showDeaths"), isListMode),
		dropdownSetting(L["mythicPlusTimerDeathBarMode"] or "Death row bar", get("deathBarMode"), set("deathBarMode", function(value)
			if value ~= "DEATHS" and value ~= "TIME_LOST" then return "NONE" end
			return value
		end), {
			{ value = "NONE", label = _G.NONE or "None" },
			{ value = "DEATHS", label = L["mythicPlusTimerDeathBarModeDeaths"] or "Death count (0-10)" },
			{ value = "TIME_LOST", label = L["mythicPlusTimerDeathBarModeTimeLost"] or "Time lost / time limit" },
		}, displayId, 180, deathRowBarEnabled, isListMode),
		checkboxSetting(L["mythicPlusTimerDeathShowTimeLost"] or "Show time lost with deaths", get("deathShowTimeLost"), set("deathShowTimeLost"), displayId, enabledWhen("showDeaths"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowEnemyForces"] or "Show enemy forces", get("showEnemyForces"), set("showEnemyForces"), displayId, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerEnemyForcesValueDisplay"] or "Enemy Forces value display", get("enemyForcesValueMode"), set("enemyForcesValueMode", normalizeEnemyForcesValueMode), enemyForcesValueOptions, displayId, 180, enabledWhen("showEnemyForces"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowEnemyForcesBar"] or "Show enemy forces bar", get("showEnemyForcesBar"), set("showEnemyForcesBar"), displayId, enabledWhen("showEnemyForces"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowObjectives"] or "Show objectives", get("showObjectives"), set("showObjectives", nil, true), displayId, nil, isListMode),
		checkboxSetting(L["mythicPlusTimerShowObjectiveValues"] or "Show objective values", get("showObjectiveValues"), set("showObjectiveValues", nil, true), displayId, enabledWhen("showObjectives"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowObjectiveBars"] or "Show objective bars", get("showObjectiveBars"), set("showObjectiveBars"), displayId, enabledWhen("showObjectives"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowObjectiveTimes"] or "Show objective times", get("showObjectiveTimes"), set("showObjectiveTimes", nil, true), displayId, enabledWhen("showObjectives"), isListMode),
		checkboxSetting(L["mythicPlusTimerShowObjectiveBestTimes"] or "Show objective best deltas", get("showObjectiveBestTimes"), set("showObjectiveBestTimes"), displayId, objectiveTimesEnabled, isListMode),
		{ name = L["mythicPlusTimerSectionBehavior"] or "Behavior", kind = SettingType.Collapsible, id = behaviorId, defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerOnlyInMythicPlus"] or "Only show in Mythic+", get("showOnlyInMythicPlus"), set("showOnlyInMythicPlus"), behaviorId),
		checkboxSetting(L["mythicPlusTimerTooltip"] or "Show tooltip", get("tooltip"), set("tooltip"), behaviorId),
		checkboxSetting(L["mythicPlusTimerShowBestTime"] or "Show best time", get("showBestTime"), set("showBestTime", nil, true), behaviorId, nil, isLegacyMode),
		checkboxSetting(L["mythicPlusTimerShowBestDelta"] or "Show best time delta", get("showBestDelta"), set("showBestDelta"), behaviorId, enabledWhen("showBestTime"), isLegacyMode),
		sliderSetting(L["mythicPlusTimerUpdateRate"] or "Update rate", get("updateRate"), set("updateRate", function(value) return clampNumber(value, 0.1, 5, defaults.updateRate) end), 0.1, 5, 0.1, behaviorId, oneDecimalSeconds),
		{ name = L["mythicPlusTimerSectionLayout"] or "Layout", kind = SettingType.Collapsible, id = layoutId, defaultCollapsed = true },
		dropdownSetting(L["mythicPlusTimerLayoutMode"] or "Layout mode", get("layoutMode"), set("layoutMode", nil, true), {
			{ value = "LIST", label = L["mythicPlusTimerLayoutList"] or "List" },
			{ value = "PANEL", label = L["mythicPlusTimerLayoutPanel"] or "Panel" },
			{ value = "FLOW", label = L["mythicPlusTimerLayoutFlow"] or "Flow panel" },
		}, layoutId, nil, nil, nil, "mythicPlusTimerFlowLayout"),
		sliderSetting(L["mythicPlusTimerWidth"] or "Width", get("width"), set("width", function(value) return clampNumber(value, 120, 800, defaults.width) end), 120, 800, 0.1, layoutId, nil, nil, isLegacyMode),
		sliderSetting(L["mythicPlusTimerPanelHeight"] or L["Height"] or "Height", get("panelHeight"), set("panelHeight", function(value) return clampNumber(value, 24, 300, defaults.panelHeight) end), 24, 300, 1, layoutId, nil, nil, isPanelMode),
		sliderSetting(L["mythicPlusTimerRowHeight"] or "Row height", get("rowHeight"), set("rowHeight", function(value) return clampNumber(value, 12, 48, defaults.rowHeight) end), 12, 48, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerRowSpacing"] or "Row spacing", get("rowSpacing"), set("rowSpacing", function(value) return clampNumber(value, 0, 24, defaults.rowSpacing) end), 0, 24, 1, layoutId, nil, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerGrowth"] or "Growth direction", get("growth"), set("growth"), { { value = "DOWN", label = L["damageMeterRowsGrowDown"] or "Down" }, { value = "UP", label = L["damageMeterRowsGrowUp"] or "Up" } }, layoutId, nil, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerAlign"] or "Text alignment", get("align"), set("align"), { { value = "LEFT", label = _G.LEFT or "Left" }, { value = "CENTER", label = _G.CENTER or "Center" }, { value = "RIGHT", label = _G.RIGHT or "Right" } }, layoutId, nil, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerTimerLabelAlign"] or "Timer label alignment", get("timerAlign"), set("timerAlign", function(value)
			if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then return "INHERIT" end
			return value
		end), {
			{ value = "INHERIT", label = L["Default"] or "Default" },
			{ value = "LEFT", label = _G.LEFT or "Left" },
			{ value = "CENTER", label = _G.CENTER or "Center" },
			{ value = "RIGHT", label = _G.RIGHT or "Right" },
		}, layoutId, 160, enabledWhen("showTimer"), isListMode),
		sliderSetting(L["mythicPlusTimerTextOffsetX"] or "Label X offset", get("textOffsetX"), set("textOffsetX", function(value) return clampNumber(value, -800, 800, defaults.textOffsetX) end), -800, 800, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerTextOffsetY"] or "Label Y offset", get("textOffsetY"), set("textOffsetY", function(value) return clampNumber(value, -800, 800, defaults.textOffsetY) end), -800, 800, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerValueOffsetX"] or "Value X offset", get("valueOffsetX"), set("valueOffsetX", function(value) return clampNumber(value, -800, 800, defaults.valueOffsetX) end), -800, 800, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerValueOffsetY"] or "Value Y offset", get("valueOffsetY"), set("valueOffsetY", function(value) return clampNumber(value, -800, 800, defaults.valueOffsetY) end), -800, 800, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerIconOffsetX"] or "Icon X offset", get("iconOffsetX"), set("iconOffsetX", function(value) return clampNumber(value, -200, 200, defaults.iconOffsetX) end), -200, 200, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerIconOffsetY"] or "Icon Y offset", get("iconOffsetY"), set("iconOffsetY", function(value) return clampNumber(value, -200, 200, defaults.iconOffsetY) end), -200, 200, 1, layoutId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerIconGap"] or "Icon gap", get("iconGap"), set("iconGap", function(value) return clampNumber(value, -50, 100, defaults.iconGap) end), -50, 100, 1, layoutId, nil, nil, isListMode),
		divider(layoutId),
		{ name = L["mythicPlusTimerPanelDungeonAndKey"] or "Dungeon and key", kind = SettingType.Collapsible, id = "mpt-panel-dungeon-key", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowDungeon"] or "Show dungeon and level", get("showDungeon"), set("showDungeon"), "mpt-panel-dungeon-key"),
		dropdownSetting(L["mythicPlusTimerDungeonDisplay"] or "Dungeon label", get("dungeonDisplay"), set("dungeonDisplay"), {
			{ value = "NAME_LEVEL", label = L["mythicPlusTimerDungeonDisplayNameLevel"] or "Name + level" },
			{ value = "SHORT_LEVEL", label = L["mythicPlusTimerDungeonDisplayShortLevel"] or "Abbreviation + level" },
			{ value = "NAME", label = L["mythicPlusTimerDungeonDisplayName"] or "Name" },
			{ value = "SHORT", label = L["mythicPlusTimerDungeonDisplayShort"] or "Abbreviation" },
			{ value = "LEVEL", label = L["mythicPlusTimerDungeonDisplayLevel"] or "Level" },
		}, "mpt-panel-dungeon-key", 180, enabledWhen("showDungeon")),
		sliderSetting(L["mythicPlusTimerPanelDungeonFontSize"] or L["Text size"] or "Text size", get("panelDungeonFontSize"), set("panelDungeonFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelDungeonFontSize) end), 8, 56, 1, "mpt-panel-dungeon-key", nil, enabledWhen("showDungeon")),
		anchorSetting("dungeonAnchor", "mpt-panel-dungeon-key", nil, L["Anchor"] or "Anchor", enabledWhen("showDungeon")),
		sliderSetting(L["mythicPlusTimerDungeonOffsetX"] or L["Offset X"] or "Offset X", get("dungeonOffsetX"), set("dungeonOffsetX", function(value) return clampNumber(value, -800, 800, defaults.dungeonOffsetX) end), -800, 800, 1, "mpt-panel-dungeon-key"),
		sliderSetting(L["mythicPlusTimerDungeonOffsetY"] or L["Offset Y"] or "Offset Y", get("dungeonOffsetY"), set("dungeonOffsetY", function(value) return clampNumber(value, -800, 800, defaults.dungeonOffsetY) end), -800, 800, 1, "mpt-panel-dungeon-key"),
		checkboxSetting(L["mythicPlusTimerShowStandaloneKeyLevel"] or "Show standalone key level", get("showKeyLevel"), set("showKeyLevel"), "mpt-panel-dungeon-key"),
		sliderSetting(L["mythicPlusTimerPanelKeyLevelFontSize"] or L["Text size"] or "Text size", get("panelKeyLevelFontSize"), set("panelKeyLevelFontSize", function(value) return clampNumber(value, 8, 64, defaults.panelKeyLevelFontSize) end), 8, 64, 1, "mpt-panel-dungeon-key", nil, enabledWhen("showKeyLevel")),
		anchorSetting("keyLevelAnchor", "mpt-panel-dungeon-key", nil, L["Anchor"] or "Anchor", enabledWhen("showKeyLevel")),
		sliderSetting(L["mythicPlusTimerKeyLevelOffsetX"] or L["Offset X"] or "Offset X", get("keyLevelOffsetX"), set("keyLevelOffsetX", function(value) return clampNumber(value, -800, 800, defaults.keyLevelOffsetX) end), -800, 800, 1, "mpt-panel-dungeon-key"),
		sliderSetting(L["mythicPlusTimerKeyLevelOffsetY"] or L["Offset Y"] or "Offset Y", get("keyLevelOffsetY"), set("keyLevelOffsetY", function(value) return clampNumber(value, -800, 800, defaults.keyLevelOffsetY) end), -800, 800, 1, "mpt-panel-dungeon-key"),
		{ name = L["mythicPlusTimerPanelTimerAndTiers"] or "Timer and tiers", kind = SettingType.Collapsible, id = "mpt-panel-time", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowTimer"] or "Show timer", get("showTimer"), set("showTimer"), "mpt-panel-time"),
		dropdownSetting(L["mythicPlusTimerTimerDisplay"] or "Timer display", get("timerDisplay"), set("timerDisplay"), {
			{ value = "TIME_LEFT", label = L["mythicPlusTimerTimerDisplayTimeLeft"] or "Time left" },
			{ value = "TIME_LEFT_TOTAL", label = L["mythicPlusTimerTimerDisplayTimeLeftTotal"] or "Time left / total time" },
			{ value = "ELAPSED_TOTAL", label = L["mythicPlusTimerTimerDisplayElapsedTotal"] or "Time elapsed / total time" },
			{ value = "TOTAL", label = L["mythicPlusTimerTimerDisplayTotal"] or "Total time" },
		}, "mpt-panel-time", 220, enabledWhen("showTimer")),
		sliderSetting(L["mythicPlusTimerPanelTimerFontSize"] or L["Text size"] or "Text size", get("panelTimerFontSize"), set("panelTimerFontSize", function(value) return clampNumber(value, 8, 72, defaults.panelTimerFontSize) end), 8, 72, 1, "mpt-panel-time", nil, enabledWhen("showTimer")),
		anchorSetting("timerAnchor", "mpt-panel-time", nil, L["Anchor"] or "Anchor", enabledWhen("showTimer")),
		sliderSetting(L["mythicPlusTimerTimerOffsetX"] or L["Offset X"] or "Offset X", get("timerOffsetX"), set("timerOffsetX", function(value) return clampNumber(value, -800, 800, defaults.timerOffsetX) end), -800, 800, 1, "mpt-panel-time"),
		sliderSetting(L["mythicPlusTimerTimerOffsetY"] or L["Offset Y"] or "Offset Y", get("timerOffsetY"), set("timerOffsetY", function(value) return clampNumber(value, -800, 800, defaults.timerOffsetY) end), -800, 800, 1, "mpt-panel-time"),
		checkboxSetting(L["mythicPlusTimerShowChestTimers"] or "Show +2/+3 timers", get("showChestTimers"), set("showChestTimers", nil, true), "mpt-panel-time"),
		sliderSetting(L["mythicPlusTimerPanelChestFontSize"] or "+2/+3 font size", get("panelChestFontSize"), set("panelChestFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelChestFontSize) end), 8, 56, 1, "mpt-panel-time", nil, enabledWhen("showChestTimers"), shownWhen("showChestTimers")),
		checkboxSetting(L["mythicPlusTimerPanelChestHideLabels"] or "Hide +2/+3 labels", get("panelChestHideLabels"), set("panelChestHideLabels"), "mpt-panel-time", enabledWhen("showChestTimers"), shownWhen("showChestTimers")),
		anchorSetting("chest2Anchor", "mpt-panel-time", shownWhen("showChestTimers"), L["mythicPlusTimerChest2Anchor"] or "+2 anchor", enabledWhen("showChestTimers")),
		sliderSetting(L["mythicPlusTimerChest2OffsetX"] or "+2 X offset", get("chest2OffsetX"), set("chest2OffsetX", function(value) return clampNumber(value, -800, 800, defaults.chest2OffsetX) end), -800, 800, 1, "mpt-panel-time", nil, nil, shownWhen("showChestTimers")),
		sliderSetting(L["mythicPlusTimerChest2OffsetY"] or "+2 Y offset", get("chest2OffsetY"), set("chest2OffsetY", function(value) return clampNumber(value, -800, 800, defaults.chest2OffsetY) end), -800, 800, 1, "mpt-panel-time", nil, nil, shownWhen("showChestTimers")),
		anchorSetting("chest3Anchor", "mpt-panel-time", shownWhen("showChestTimers"), L["mythicPlusTimerChest3Anchor"] or "+3 anchor", enabledWhen("showChestTimers")),
		sliderSetting(L["mythicPlusTimerChest3OffsetX"] or "+3 X offset", get("chest3OffsetX"), set("chest3OffsetX", function(value) return clampNumber(value, -800, 800, defaults.chest3OffsetX) end), -800, 800, 1, "mpt-panel-time", nil, nil, shownWhen("showChestTimers")),
		sliderSetting(L["mythicPlusTimerChest3OffsetY"] or "+3 Y offset", get("chest3OffsetY"), set("chest3OffsetY", function(value) return clampNumber(value, -800, 800, defaults.chest3OffsetY) end), -800, 800, 1, "mpt-panel-time", nil, nil, shownWhen("showChestTimers")),
		checkboxSetting(L["mythicPlusTimerShowPanelTimerBar"] or "Show panel timer bar", get("showPanelTimerBar"), set("showPanelTimerBar", nil, true), "mpt-panel-time"),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarAttachToHeader"] or "Attach timer bar to dungeon/key header", get("panelTimerBarAttachToHeader"), set("panelTimerBarAttachToHeader", nil, true), "mpt-panel-time", enabledWhen("showPanelTimerBar"), nil, "mythicPlusTimerPanelTimerBarAttachToHeader"),
		sliderSetting(L["mythicPlusTimerPanelTimerBarWidth"] or L["Bar width"] or "Bar width", get("panelTimerBarWidth"), set("panelTimerBarWidth", function(value) return clampNumber(value, 20, 800, defaults.panelTimerBarWidth) end), 20, 800, 0.1, "mpt-panel-time", wholePixels, enabledWhen("showPanelTimerBar")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarHeight"] or L["Bar height"] or "Bar height", get("panelTimerBarHeight"), set("panelTimerBarHeight", function(value) return clampNumber(value, 1, 64, defaults.panelTimerBarHeight) end), 1, 64, 1, "mpt-panel-time", nil, enabledWhen("showPanelTimerBar")),
		colorSetting(L["mythicPlusTimerPanelTimerBarColor"] or L["Color"] or "Color", get("panelTimerBarColor"), set("panelTimerBarColor"), defaults.panelTimerBarColor, "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		colorSetting(L["mythicPlusTimerPanelTimerBarExpiredColor"] or "Expired color", get("panelTimerBarExpiredColor"), set("panelTimerBarExpiredColor"), defaults.panelTimerBarExpiredColor, "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		dropdownSetting(L["mythicPlusTimerPanelTimerBarTexture"] or L["Texture"] or "Texture", get("panelTimerBarTexture"), set("panelTimerBarTexture"), function() return buildMediaOptions("statusbar", false) end, "mpt-panel-time", 260, enabledWhen("showPanelTimerBar")),
		dropdownSetting(L["mythicPlusTimerPanelTimerBarBackgroundTexture"] or L["Background texture"] or "Background texture", get("panelTimerBarBackgroundTexture"), set("panelTimerBarBackgroundTexture"), function() return buildMediaOptions("statusbar", false) end, "mpt-panel-time", 260, enabledWhen("showPanelTimerBar")),
		colorSetting(L["mythicPlusTimerPanelTimerBarBackgroundColor"] or L["Background color"] or "Background color", get("panelTimerBarBackgroundColor"), set("panelTimerBarBackgroundColor"), defaults.panelTimerBarBackgroundColor, "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarBorderEnabled"] or L["Border"] or "Border", get("panelTimerBarBorderEnabled"), set("panelTimerBarBorderEnabled", nil, true), "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		dropdownSetting(L["mythicPlusTimerPanelTimerBarBorderTexture"] or L["Border texture"] or "Border texture", get("panelTimerBarBorderTexture"), set("panelTimerBarBorderTexture"), function() return buildMediaOptions("border", false) end, "mpt-panel-time", 260, allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled")),
		colorSetting(L["mythicPlusTimerPanelTimerBarBorderColor"] or L["Border color"] or "Border color", get("panelTimerBarBorderColor"), set("panelTimerBarBorderColor"), defaults.panelTimerBarBorderColor, "mpt-panel-time", allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarBorderSize"] or L["Border size"] or "Border size", get("panelTimerBarBorderSize"), set("panelTimerBarBorderSize", function(value) return clampNumber(value, 1, 32, defaults.panelTimerBarBorderSize) end), 1, 32, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled")),
		checkboxSetting(L["damageMeterBorderAdvancedOffsets"] or "Separate border offsets", get("panelTimerBarBorderSeparateOffset"), set("panelTimerBarBorderSeparateOffset", nil, true), "mpt-panel-time", allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarBorderOffset"] or L["Border offset"] or "Border offset", get("panelTimerBarBorderOffset"), set("panelTimerBarBorderOffset", function(value) return clampNumber(value, -300, 300, defaults.panelTimerBarBorderOffset) end), -300, 300, 1, "mpt-panel-time", nil, allEnabledAndNot("panelTimerBarBorderSeparateOffset", "showPanelTimerBar", "panelTimerBarBorderEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", get("panelTimerBarBorderOffsetX"), set("panelTimerBarBorderOffsetX", function(value) return clampNumber(value, -300, 300, defaults.panelTimerBarBorderOffsetX) end), -300, 300, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled", "panelTimerBarBorderSeparateOffset")),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", get("panelTimerBarBorderOffsetY"), set("panelTimerBarBorderOffsetY", function(value) return clampNumber(value, -300, 300, defaults.panelTimerBarBorderOffsetY) end), -300, 300, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarBorderEnabled", "panelTimerBarBorderSeparateOffset")),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarChestMarkers"] or "Show +2/+3 markers", get("panelTimerBarChestMarkers"), set("panelTimerBarChestMarkers", nil, true), "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		colorSetting(L["mythicPlusTimerPanelTimerBarChestMarkerColor"] or "+2/+3 marker color", get("panelTimerBarChestMarkerColor"), set("panelTimerBarChestMarkerColor"), defaults.panelTimerBarChestMarkerColor, "mpt-panel-time", allEnabled("showPanelTimerBar", "panelTimerBarChestMarkers")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarChestMarkerWidth"] or "+2/+3 marker width", get("panelTimerBarChestMarkerWidth"), set("panelTimerBarChestMarkerWidth", function(value) return clampNumber(value, 1, 12, defaults.panelTimerBarChestMarkerWidth) end), 1, 12, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarChestMarkers")),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarChestTimeText"] or "Show +2/+3 times on bar", get("panelTimerBarChestTimeText"), set("panelTimerBarChestTimeText", nil, true), "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarChestTimeTextOffsetY"] or "+2/+3 time text Y offset", get("panelTimerBarChestTimeTextOffsetY"), set("panelTimerBarChestTimeTextOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelTimerBarChestTimeTextOffsetY) end), -800, 800, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarChestTimeText")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarChestTimeTextFontSize"] or "+2/+3 time text font size", get("panelTimerBarChestTimeTextFontSize"), set("panelTimerBarChestTimeTextFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelTimerBarChestTimeTextFontSize) end), 8, 56, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarChestTimeText")),
		colorSetting(L["mythicPlusTimerPanelTimerBarChestTimeTextColor"] or "+2/+3 time text color", get("panelTimerBarChestTimeTextColor"), set("panelTimerBarChestTimeTextColor"), defaults.panelTimerBarChestTimeTextColor, "mpt-panel-time", allEnabled("showPanelTimerBar", "panelTimerBarChestTimeText")),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarTimeLeftText"] or "Show time left on bar", get("panelTimerBarTimeLeftText"), set("panelTimerBarTimeLeftText", nil, true), "mpt-panel-time", enabledWhen("showPanelTimerBar"), shownWhen("showPanelTimerBar")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarTimeLeftTextOffsetX"] or "Time left text X offset", get("panelTimerBarTimeLeftTextOffsetX"), set("panelTimerBarTimeLeftTextOffsetX", function(value) return clampNumber(value, -800, 800, defaults.panelTimerBarTimeLeftTextOffsetX) end), -800, 800, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarTimeLeftText"), allShown("showPanelTimerBar", "panelTimerBarTimeLeftText")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarTimeLeftTextOffsetY"] or "Time left text Y offset", get("panelTimerBarTimeLeftTextOffsetY"), set("panelTimerBarTimeLeftTextOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelTimerBarTimeLeftTextOffsetY) end), -800, 800, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarTimeLeftText"), allShown("showPanelTimerBar", "panelTimerBarTimeLeftText")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarTimeLeftTextFontSize"] or "Time left text size", get("panelTimerBarTimeLeftTextFontSize"), set("panelTimerBarTimeLeftTextFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelTimerBarTimeLeftTextFontSize) end), 8, 56, 1, "mpt-panel-time", nil, allEnabled("showPanelTimerBar", "panelTimerBarTimeLeftText"), allShown("showPanelTimerBar", "panelTimerBarTimeLeftText")),
		colorSetting(L["mythicPlusTimerPanelTimerBarTimeLeftTextColor"] or "Time left text color", get("panelTimerBarTimeLeftTextColor"), set("panelTimerBarTimeLeftTextColor"), defaults.panelTimerBarTimeLeftTextColor, "mpt-panel-time", allEnabled("showPanelTimerBar", "panelTimerBarTimeLeftText"), allShown("showPanelTimerBar", "panelTimerBarTimeLeftText")),
		checkboxSetting(L["mythicPlusTimerPanelTimerBarFillUp"] or "Fill timer bar up", get("panelTimerBarFillUp"), set("panelTimerBarFillUp"), "mpt-panel-time", enabledWhen("showPanelTimerBar")),
		anchorSetting("panelTimerBarAnchor", "mpt-panel-time", nil, L["Anchor"] or "Anchor", allEnabledAndNot("panelTimerBarAttachToHeader", "showPanelTimerBar")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarOffsetX"] or L["Offset X"] or "Offset X", get("panelTimerBarOffsetX"), set("panelTimerBarOffsetX", function(value) return clampNumber(value, -800, 800, defaults.panelTimerBarOffsetX) end), -800, 800, 1, "mpt-panel-time", nil, allEnabledAndNot("panelTimerBarAttachToHeader", "showPanelTimerBar")),
		sliderSetting(L["mythicPlusTimerPanelTimerBarOffsetY"] or L["Offset Y"] or "Offset Y", get("panelTimerBarOffsetY"), set("panelTimerBarOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelTimerBarOffsetY) end), -800, 800, 1, "mpt-panel-time", nil, allEnabledAndNot("panelTimerBarAttachToHeader", "showPanelTimerBar")),
		{ name = L["mythicPlusTimerPanelDeaths"] or "Deaths", kind = SettingType.Collapsible, id = "mpt-panel-deaths", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowDeaths"] or "Show deaths", get("showDeaths"), set("showDeaths", nil, true), "mpt-panel-deaths"),
		dropdownSetting(L["mythicPlusTimerDeathDisplay"] or "Death display", get("deathDisplay"), set("deathDisplay"), {
			{ value = "ICON_TEXT", label = L["mythicPlusTimerAffixDisplayIconText"] or "Text + icon" },
			{ value = "ICON", label = L["mythicPlusTimerAffixDisplayIcon"] or "Icon" },
			{ value = "TEXT", label = L["mythicPlusTimerAffixDisplayText"] or "Text" },
		}, "mpt-panel-deaths", 160, enabledWhen("showDeaths")),
		checkboxSetting(L["mythicPlusTimerDeathShowTimeLost"] or "Show time lost with deaths", get("deathShowTimeLost"), set("deathShowTimeLost"), "mpt-panel-deaths", enabledWhen("showDeaths")),
		sliderSetting(L["mythicPlusTimerPanelDeathsFontSize"] or L["Text size"] or "Text size", get("panelDeathsFontSize"), set("panelDeathsFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelDeathsFontSize) end), 8, 56, 1, "mpt-panel-deaths", nil, enabledWhen("showDeaths")),
		sliderSetting(L["mythicPlusTimerPanelDeathIconSize"] or L["Icon size"] or "Icon size", get("panelDeathIconSize"), set("panelDeathIconSize", function(value) return clampNumber(value, 8, 64, defaults.panelDeathIconSize) end), 8, 64, 1, "mpt-panel-deaths", nil, enabledWhen("showDeaths")),
		anchorSetting("deathsAnchor", "mpt-panel-deaths", nil, L["Anchor"] or "Anchor", enabledWhen("showDeaths")),
		sliderSetting(L["mythicPlusTimerDeathsOffsetX"] or L["Offset X"] or "Offset X", get("deathsOffsetX"), set("deathsOffsetX", function(value) return clampNumber(value, -800, 800, defaults.deathsOffsetX) end), -800, 800, 1, "mpt-panel-deaths"),
		sliderSetting(L["mythicPlusTimerDeathsOffsetY"] or L["Offset Y"] or "Offset Y", get("deathsOffsetY"), set("deathsOffsetY", function(value) return clampNumber(value, -800, 800, defaults.deathsOffsetY) end), -800, 800, 1, "mpt-panel-deaths"),
		{ name = L["mythicPlusTimerPanelEnemyForces"] or "Enemy forces", kind = SettingType.Collapsible, id = "mpt-panel-enemy", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowEnemyPercent"] or "Show enemy percent", get("showEnemyPercent"), set("showEnemyPercent", nil, true), "mpt-panel-enemy"),
		sliderSetting(L["mythicPlusTimerPanelEnemyPercentFontSize"] or L["Text size"] or "Text size", get("panelEnemyPercentFontSize"), set("panelEnemyPercentFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelEnemyPercentFontSize) end), 8, 56, 1, "mpt-panel-enemy", nil, enabledWhen("showEnemyPercent")),
		anchorSetting("enemyPercentAnchor", "mpt-panel-enemy", nil, L["Anchor"] or "Anchor", enabledWhen("showEnemyPercent")),
		sliderSetting(L["mythicPlusTimerEnemyPercentOffsetX"] or L["Offset X"] or "Offset X", get("enemyPercentOffsetX"), set("enemyPercentOffsetX", function(value) return clampNumber(value, -800, 800, defaults.enemyPercentOffsetX) end), -800, 800, 1, "mpt-panel-enemy", nil, enabledWhen("showEnemyPercent")),
		sliderSetting(L["mythicPlusTimerEnemyPercentOffsetY"] or L["Offset Y"] or "Offset Y", get("enemyPercentOffsetY"), set("enemyPercentOffsetY", function(value) return clampNumber(value, -800, 800, defaults.enemyPercentOffsetY) end), -800, 800, 1, "mpt-panel-enemy", nil, enabledWhen("showEnemyPercent")),
		checkboxSetting(L["mythicPlusTimerShowPanelEnemyBar"] or "Show panel enemy forces bar", get("showPanelEnemyBar"), set("showPanelEnemyBar", nil, true), "mpt-panel-enemy"),
		checkboxSetting(L["mythicPlusTimerPanelEnemyBarAttachToObjectives"] or "Attach enemy-forces bar to objectives", get("panelEnemyBarAttachToObjectives"), set("panelEnemyBarAttachToObjectives", nil, true), "mpt-panel-enemy", allEnabled("showPanelEnemyBar", "showObjectives"), nil, "mythicPlusTimerPanelEnemyBarAttachToObjectives"),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarWidth"] or L["Bar width"] or "Bar width", get("panelEnemyBarWidth"), set("panelEnemyBarWidth", function(value) return clampNumber(value, 20, 800, defaults.panelEnemyBarWidth) end), 20, 800, 0.1, "mpt-panel-enemy", wholePixels, enabledWhen("showPanelEnemyBar")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarHeight"] or L["Bar height"] or "Bar height", get("panelEnemyBarHeight"), set("panelEnemyBarHeight", function(value) return clampNumber(value, 1, 64, defaults.panelEnemyBarHeight) end), 1, 64, 1, "mpt-panel-enemy", nil, enabledWhen("showPanelEnemyBar")),
		colorSetting(L["mythicPlusTimerPanelEnemyBarColor"] or L["Color"] or "Color", get("panelEnemyBarColor"), set("panelEnemyBarColor"), defaults.panelEnemyBarColor, "mpt-panel-enemy", enabledWhen("showPanelEnemyBar")),
		dropdownSetting(L["mythicPlusTimerPanelEnemyBarTexture"] or L["Texture"] or "Texture", get("panelEnemyBarTexture"), set("panelEnemyBarTexture"), function() return buildMediaOptions("statusbar", false) end, "mpt-panel-enemy", 260, enabledWhen("showPanelEnemyBar")),
		dropdownSetting(L["mythicPlusTimerPanelEnemyBarBackgroundTexture"] or L["Background texture"] or "Background texture", get("panelEnemyBarBackgroundTexture"), set("panelEnemyBarBackgroundTexture"), function() return buildMediaOptions("statusbar", false) end, "mpt-panel-enemy", 260, enabledWhen("showPanelEnemyBar")),
		colorSetting(L["mythicPlusTimerPanelEnemyBarBackgroundColor"] or L["Background color"] or "Background color", get("panelEnemyBarBackgroundColor"), set("panelEnemyBarBackgroundColor"), defaults.panelEnemyBarBackgroundColor, "mpt-panel-enemy", enabledWhen("showPanelEnemyBar")),
		checkboxSetting(L["mythicPlusTimerPanelEnemyBarBorderEnabled"] or L["Border"] or "Border", get("panelEnemyBarBorderEnabled"), set("panelEnemyBarBorderEnabled", nil, true), "mpt-panel-enemy", enabledWhen("showPanelEnemyBar")),
		dropdownSetting(L["mythicPlusTimerPanelEnemyBarBorderTexture"] or L["Border texture"] or "Border texture", get("panelEnemyBarBorderTexture"), set("panelEnemyBarBorderTexture"), function() return buildMediaOptions("border", false) end, "mpt-panel-enemy", 260, allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled")),
		colorSetting(L["mythicPlusTimerPanelEnemyBarBorderColor"] or L["Border color"] or "Border color", get("panelEnemyBarBorderColor"), set("panelEnemyBarBorderColor"), defaults.panelEnemyBarBorderColor, "mpt-panel-enemy", allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarBorderSize"] or L["Border size"] or "Border size", get("panelEnemyBarBorderSize"), set("panelEnemyBarBorderSize", function(value) return clampNumber(value, 1, 32, defaults.panelEnemyBarBorderSize) end), 1, 32, 1, "mpt-panel-enemy", nil, allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled")),
		checkboxSetting(L["damageMeterBorderAdvancedOffsets"] or "Separate border offsets", get("panelEnemyBarBorderSeparateOffset"), set("panelEnemyBarBorderSeparateOffset", nil, true), "mpt-panel-enemy", allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarBorderOffset"] or L["Border offset"] or "Border offset", get("panelEnemyBarBorderOffset"), set("panelEnemyBarBorderOffset", function(value) return clampNumber(value, -300, 300, defaults.panelEnemyBarBorderOffset) end), -300, 300, 1, "mpt-panel-enemy", nil, allEnabledAndNot("panelEnemyBarBorderSeparateOffset", "showPanelEnemyBar", "panelEnemyBarBorderEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", get("panelEnemyBarBorderOffsetX"), set("panelEnemyBarBorderOffsetX", function(value) return clampNumber(value, -300, 300, defaults.panelEnemyBarBorderOffsetX) end), -300, 300, 1, "mpt-panel-enemy", nil, allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled", "panelEnemyBarBorderSeparateOffset")),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", get("panelEnemyBarBorderOffsetY"), set("panelEnemyBarBorderOffsetY", function(value) return clampNumber(value, -300, 300, defaults.panelEnemyBarBorderOffsetY) end), -300, 300, 1, "mpt-panel-enemy", nil, allEnabled("showPanelEnemyBar", "panelEnemyBarBorderEnabled", "panelEnemyBarBorderSeparateOffset")),
		anchorSetting("panelEnemyBarAnchor", "mpt-panel-enemy", nil, L["Anchor"] or "Anchor", allEnabledAndNot("panelEnemyBarAttachToObjectives", "showPanelEnemyBar")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarOffsetX"] or L["Offset X"] or "Offset X", getPanelEnemyBarOffset("X"), setPanelEnemyBarOffset("X"), -800, 800, 1, "mpt-panel-enemy", nil, enabledWhen("showPanelEnemyBar")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarOffsetY"] or L["Offset Y"] or "Offset Y", getPanelEnemyBarOffset("Y"), setPanelEnemyBarOffset("Y"), -800, 800, 1, "mpt-panel-enemy", nil, enabledWhen("showPanelEnemyBar")),
		checkboxSetting((L["Text"] or "Text") .. " 1", get("panelEnemyBarTextEnabled"), set("panelEnemyBarTextEnabled", nil, true), "mpt-panel-enemy", enabledWhen("showPanelEnemyBar")),
		dropdownSetting(L["mythicPlusTimerEnemyForcesValueDisplay"] or "Enemy Forces value display", function() return Timer:GetPanelEnemyBarTextMode(1) end, set("panelEnemyBarTextMode", normalizePanelEnemyForcesValueMode), panelEnemyForcesValueOptions, "mpt-panel-enemy", 180, allEnabled("showPanelEnemyBar", "panelEnemyBarTextEnabled")),
		dropdownSetting(L["mythicPlusTimerPanelEnemyBarTextAlign"] or "Text alignment", get("panelEnemyBarTextAlign"), set("panelEnemyBarTextAlign", normalizeHorizontal), {
			{ value = "LEFT", label = _G.LEFT or "Left" },
			{ value = "CENTER", label = _G.CENTER or "Center" },
			{ value = "RIGHT", label = _G.RIGHT or "Right" },
		}, "mpt-panel-enemy", nil, allEnabled("showPanelEnemyBar", "panelEnemyBarTextEnabled")),
		checkboxSetting((L["Text"] or "Text") .. " 2", get("panelEnemyBarText2Enabled"), set("panelEnemyBarText2Enabled", nil, true), "mpt-panel-enemy", enabledWhen("showPanelEnemyBar"), nil, "mythicPlusTimerPanelEnemyBarSecondText"),
		dropdownSetting(L["mythicPlusTimerEnemyForcesValueDisplay"] or "Enemy Forces value display", get("panelEnemyBarText2Mode"), set("panelEnemyBarText2Mode", normalizePanelEnemyForcesValueMode), panelEnemyForcesValueOptions, "mpt-panel-enemy", 180, allEnabled("showPanelEnemyBar", "panelEnemyBarText2Enabled")),
		dropdownSetting(L["mythicPlusTimerPanelEnemyBarTextAlign"] or "Text alignment", get("panelEnemyBarText2Align"), set("panelEnemyBarText2Align", normalizeHorizontal), {
			{ value = "LEFT", label = _G.LEFT or "Left" },
			{ value = "CENTER", label = _G.CENTER or "Center" },
			{ value = "RIGHT", label = _G.RIGHT or "Right" },
		}, "mpt-panel-enemy", nil, allEnabled("showPanelEnemyBar", "panelEnemyBarText2Enabled")),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarTextOffsetY"] or L["Text Y offset"] or "Text Y offset", get("panelEnemyBarTextOffsetY"), set("panelEnemyBarTextOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelEnemyBarTextOffsetY) end), -800, 800, 1, "mpt-panel-enemy", nil, enemyBarTextEnabled),
		sliderSetting(L["mythicPlusTimerPanelEnemyBarTextFontSize"] or L["Text size"] or "Text size", get("panelEnemyBarTextFontSize"), set("panelEnemyBarTextFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelEnemyBarTextFontSize) end), 8, 56, 1, "mpt-panel-enemy", nil, enemyBarTextEnabled),
		colorSetting(L["mythicPlusTimerPanelEnemyBarTextColor"] or L["Text color"] or "Text color", get("panelEnemyBarTextColor"), set("panelEnemyBarTextColor"), defaults.panelEnemyBarTextColor, "mpt-panel-enemy", enemyBarTextEnabled),
		{ name = L["mythicPlusTimerPanelBestTime"] or "Best time", kind = SettingType.Collapsible, id = "mpt-panel-best", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowBestTime"] or "Show best time", get("showBestTime"), set("showBestTime", nil, true), "mpt-panel-best"),
		checkboxSetting(L["mythicPlusTimerShowBestDelta"] or "Show best time delta", get("showBestDelta"), set("showBestDelta"), "mpt-panel-best", enabledWhen("showBestTime")),
		sliderSetting(L["mythicPlusTimerPanelBestTimeFontSize"] or L["Text size"] or "Text size", get("panelBestTimeFontSize"), set("panelBestTimeFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelBestTimeFontSize) end), 8, 56, 1, "mpt-panel-best", nil, enabledWhen("showBestTime")),
		colorSetting(L["mythicPlusTimerBestTimeColor"] or "Color", get("bestTimeColor"), set("bestTimeColor"), defaults.bestTimeColor, "mpt-panel-best", enabledWhen("showBestTime")),
		anchorSetting("bestTimeAnchor", "mpt-panel-best", nil, L["Anchor"] or "Anchor", enabledWhen("showBestTime")),
		sliderSetting(L["mythicPlusTimerBestTimeOffsetX"] or L["Offset X"] or "Offset X", get("bestTimeOffsetX"), set("bestTimeOffsetX", function(value) return clampNumber(value, -800, 800, defaults.bestTimeOffsetX) end), -800, 800, 1, "mpt-panel-best"),
		sliderSetting(L["mythicPlusTimerBestTimeOffsetY"] or L["Offset Y"] or "Offset Y", get("bestTimeOffsetY"), set("bestTimeOffsetY", function(value) return clampNumber(value, -800, 800, defaults.bestTimeOffsetY) end), -800, 800, 1, "mpt-panel-best"),
		{ name = L["mythicPlusTimerPanelObjectives"] or "Objectives", kind = SettingType.Collapsible, id = "mpt-panel-objectives", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowObjectives"] or "Show objectives", get("showObjectives"), set("showObjectives", nil, true), "mpt-panel-objectives"),
		checkboxSetting(L["mythicPlusTimerPanelObjectivesAttachToTimerBar"] or "Attach objectives to timer bar", get("panelObjectivesAttachToTimerBar"), set("panelObjectivesAttachToTimerBar", nil, true), "mpt-panel-objectives", allEnabled("showObjectives", "showPanelTimerBar"), shownWhen("showObjectives"), "mythicPlusTimerPanelObjectivesAttachToTimerBar"),
		checkboxSetting(L["mythicPlusTimerShowObjectiveValues"] or "Show objective values", get("showObjectiveValues"), set("showObjectiveValues", nil, true), "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		checkboxSetting(L["mythicPlusTimerHideNonBossObjectives"] or "Hide non-boss objectives", get("hideNonBossObjectives"), set("hideNonBossObjectives"), "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		checkboxSetting(L["mythicPlusTimerShowObjectiveTimes"] or "Show objective times", get("showObjectiveTimes"), set("showObjectiveTimes", nil, true), "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		checkboxSetting(L["mythicPlusTimerShowObjectiveBestTimes"] or "Show objective best deltas", get("showObjectiveBestTimes"), set("showObjectiveBestTimes"), "mpt-panel-objectives", objectiveTimesEnabled, objectiveTimesEnabled),
		dropdownSetting(L["mythicPlusTimerFont"] or "Font", get("panelObjectivesFontFace"), set("panelObjectivesFontFace"), function() return buildMediaOptions("font", true) end, "mpt-panel-objectives", 260, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		dropdownSetting(L["mythicPlusTimerFontOutline"] or "Font outline", get("panelObjectivesFontOutline"), set("panelObjectivesFontOutline", normalizeFontStyle), buildStyleOptions, "mpt-panel-objectives", 180, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		sliderSetting(L["mythicPlusTimerPanelObjectivesFontSize"] or L["Text size"] or "Text size", get("panelObjectivesFontSize"), set("panelObjectivesFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelObjectivesFontSize) end), 8, 56, 1, "mpt-panel-objectives", nil, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		sliderSetting(L["mythicPlusTimerPanelObjectivesSpacing"] or "Spacing", get("panelObjectivesSpacing"), set("panelObjectivesSpacing", function(value) return clampNumber(value, 0, 24, defaults.panelObjectivesSpacing) end), 0, 24, 1, "mpt-panel-objectives", nil, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		sliderSetting(L["mythicPlusTimerPanelObjectivesColumnSpacing"] or "Column offset", get("panelObjectivesColumnSpacing"), set("panelObjectivesColumnSpacing", function(value) return clampNumber(value, -200, 200, defaults.panelObjectivesColumnSpacing) end), -200, 200, 1, "mpt-panel-objectives", nil, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		checkboxSetting(L["mythicPlusTimerPanelObjectivesInvertColumns"] or "Invert columns", get("panelObjectivesInvertColumns"), set("panelObjectivesInvertColumns"), "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		colorSetting(L["mythicPlusTimerObjectiveColor"] or "Objective color", get("objectiveColor"), set("objectiveColor"), defaults.objectiveColor, "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		colorSetting(L["mythicPlusTimerObjectiveCompleteColor"] or "Completed objective color", get("objectiveCompleteColor"), set("objectiveCompleteColor"), defaults.objectiveCompleteColor, "mpt-panel-objectives", enabledWhen("showObjectives"), shownWhen("showObjectives")),
		colorSetting(L["mythicPlusTimerObjectiveBestDeltaFasterColor"] or "Faster best delta color", get("objectiveBestDeltaFasterColor"), set("objectiveBestDeltaFasterColor"), defaults.objectiveBestDeltaFasterColor, "mpt-panel-objectives", objectiveTimesEnabled, objectiveTimesEnabled),
		colorSetting(L["mythicPlusTimerObjectiveBestDeltaSlowerColor"] or "Slower best delta color", get("objectiveBestDeltaSlowerColor"), set("objectiveBestDeltaSlowerColor"), defaults.objectiveBestDeltaSlowerColor, "mpt-panel-objectives", objectiveTimesEnabled, objectiveTimesEnabled),
		anchorSetting("panelObjectivesAnchor", "mpt-panel-objectives", shownWhen("showObjectives"), L["mythicPlusTimerPanelObjectivesAnchor"] or L["Anchor"] or "Anchor", allEnabledAndNot("panelObjectivesAttachToTimerBar", "showObjectives")),
		dropdownSetting(L["mythicPlusTimerGrowth"] or "Growth direction", get("panelObjectivesGrowth"), set("panelObjectivesGrowth", function(value) return value == "UP" and "UP" or "DOWN" end), {
			{ value = "DOWN", label = L["damageMeterRowsGrowDown"] or "Down" },
			{ value = "UP", label = L["damageMeterRowsGrowUp"] or "Up" },
		}, "mpt-panel-objectives", 120, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		sliderSetting(L["mythicPlusTimerPanelObjectivesOffsetX"] or L["Offset X"] or "Offset X", get("panelObjectivesOffsetX"), set("panelObjectivesOffsetX", function(value) return clampNumber(value, -800, 800, defaults.panelObjectivesOffsetX) end), -800, 800, 1, "mpt-panel-objectives", nil, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		sliderSetting(L["mythicPlusTimerPanelObjectivesOffsetY"] or L["Offset Y"] or "Offset Y", get("panelObjectivesOffsetY"), set("panelObjectivesOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelObjectivesOffsetY) end), -800, 800, 1, "mpt-panel-objectives", nil, enabledWhen("showObjectives"), shownWhen("showObjectives")),
		{ name = L["mythicPlusTimerPanelAffixes"] or "Affixes", kind = SettingType.Collapsible, id = "mpt-panel-affixes", defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerShowAffixes"] or "Show affixes", get("showAffixes"), set("showAffixes", nil, true), "mpt-panel-affixes"),
		dropdownSetting(L["mythicPlusTimerAffixDisplay"] or "Affix display", get("affixDisplay"), set("affixDisplay"), {
			{ value = "ICON_TEXT", label = L["mythicPlusTimerAffixDisplayIconText"] or "Text + icon" },
			{ value = "ICON", label = L["mythicPlusTimerAffixDisplayIcon"] or "Icon" },
			{ value = "TEXT", label = L["mythicPlusTimerAffixDisplayText"] or "Text" },
		}, "mpt-panel-affixes", 160, enabledWhen("showAffixes")),
		sliderSetting(L["mythicPlusTimerPanelAffixesFontSize"] or L["Text size"] or "Text size", get("panelAffixesFontSize"), set("panelAffixesFontSize", function(value) return clampNumber(value, 8, 56, defaults.panelAffixesFontSize) end), 8, 56, 1, "mpt-panel-affixes", nil, enabledWhen("showAffixes")),
		sliderSetting(L["mythicPlusTimerPanelAffixIconSize"] or L["Icon size"] or "Icon size", get("panelAffixIconSize"), set("panelAffixIconSize", function(value) return clampNumber(value, 8, 64, defaults.panelAffixIconSize) end), 8, 64, 1, "mpt-panel-affixes", nil, enabledWhen("showAffixes")),
		anchorSetting("panelAffixesAnchor", "mpt-panel-affixes", nil, L["Anchor"] or "Anchor", enabledWhen("showAffixes")),
		sliderSetting(L["mythicPlusTimerPanelAffixesOffsetX"] or L["Offset X"] or "Offset X", get("panelAffixesOffsetX"), set("panelAffixesOffsetX", function(value) return clampNumber(value, -800, 800, defaults.panelAffixesOffsetX) end), -800, 800, 1, "mpt-panel-affixes"),
		sliderSetting(L["mythicPlusTimerPanelAffixesOffsetY"] or L["Offset Y"] or "Offset Y", get("panelAffixesOffsetY"), set("panelAffixesOffsetY", function(value) return clampNumber(value, -800, 800, defaults.panelAffixesOffsetY) end), -800, 800, 1, "mpt-panel-affixes"),
		{ name = L["mythicPlusTimerSectionBars"] or "Bars", kind = SettingType.Collapsible, id = barId, defaultCollapsed = true, isShown = isListMode },
		dropdownSetting(L["mythicPlusTimerBarPosition"] or "Bar position", get("barPosition"), set("barPosition"), {
			{ value = "BACKGROUND", label = L["mythicPlusTimerBarPositionBackground"] or "Behind text" },
			{ value = "TOP", label = _G.TOP or "Top" },
			{ value = "BOTTOM", label = _G.BOTTOM or "Bottom" },
		}, barId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerBarHeight"] or "Bar height", get("barHeight"), set("barHeight", function(value) return clampNumber(value, 1, 96, defaults.barHeight) end), 1, 96, 1, barId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerBarOffsetX"] or "Bar X offset", get("barOffsetX"), set("barOffsetX", function(value) return clampNumber(value, -800, 800, defaults.barOffsetX) end), -800, 800, 1, barId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerBarOffsetY"] or "Bar Y offset", get("barOffsetY"), set("barOffsetY", function(value) return clampNumber(value, -800, 800, defaults.barOffsetY) end), -800, 800, 1, barId, nil, nil, isListMode),
		sliderSetting(L["mythicPlusTimerBarWidthOffset"] or "Bar width offset", get("barWidthOffset"), set("barWidthOffset", function(value) return clampNumber(value, -400, 400, defaults.barWidthOffset) end), -400, 400, 0.1, barId, wholePixels, nil, isListMode),
		dropdownSetting(L["mythicPlusTimerTexture"] or "Bar texture", get("texture"), set("texture"), function() return buildMediaOptions("statusbar", false) end, barId, 260),
		dropdownSetting(L["mythicPlusTimerBarBackgroundTexture"] or "Bar background texture", get("barBackgroundTexture"), set("barBackgroundTexture"), function() return buildMediaOptions("statusbar", false) end, barId, 260),
		colorSetting(L["mythicPlusTimerBarBackgroundColor"] or "Bar background color", get("barBackgroundColor"), set("barBackgroundColor"), defaults.barBackgroundColor, barId),
		checkboxSetting(L["mythicPlusTimerBarBorderEnabled"] or "Bar border", get("barBorderEnabled"), set("barBorderEnabled", nil, true), barId),
		dropdownSetting(L["mythicPlusTimerBarBorderTexture"] or "Bar border texture", get("barBorderTexture"), set("barBorderTexture"), function() return buildMediaOptions("border", false) end, barId, 260, enabledWhen("barBorderEnabled")),
		colorSetting(L["mythicPlusTimerBarBorderColor"] or "Bar border color", get("barBorderColor"), set("barBorderColor"), defaults.barBorderColor, barId, enabledWhen("barBorderEnabled")),
		sliderSetting(L["mythicPlusTimerBarBorderSize"] or "Bar border size", get("barBorderSize"), set("barBorderSize", function(value) return clampNumber(value, 1, 32, defaults.barBorderSize) end), 1, 32, 1, barId, nil, enabledWhen("barBorderEnabled")),
		checkboxSetting(L["damageMeterBorderAdvancedOffsets"] or "Separate border offsets", get("barBorderSeparateOffset"), set("barBorderSeparateOffset", nil, true), barId, enabledWhen("barBorderEnabled")),
		sliderSetting(L["mythicPlusTimerBarBorderOffset"] or "Bar border offset", get("barBorderOffset"), set("barBorderOffset", function(value) return clampNumber(value, -300, 300, defaults.barBorderOffset) end), -300, 300, 1, barId, nil, allEnabledAndNot("barBorderSeparateOffset", "barBorderEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", get("barBorderOffsetX"), set("barBorderOffsetX", function(value) return clampNumber(value, -300, 300, defaults.barBorderOffsetX) end), -300, 300, 1, barId, nil, allEnabled("barBorderEnabled", "barBorderSeparateOffset")),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", get("barBorderOffsetY"), set("barBorderOffsetY", function(value) return clampNumber(value, -300, 300, defaults.barBorderOffsetY) end), -300, 300, 1, barId, nil, allEnabled("barBorderEnabled", "barBorderSeparateOffset")),
		{ name = L["mythicPlusTimerSectionFont"] or "Font", kind = SettingType.Collapsible, id = fontId, defaultCollapsed = true },
		dropdownSetting(L["mythicPlusTimerFont"] or "Font", get("fontFace"), set("fontFace"), function() return buildMediaOptions("font", true) end, fontId, 260),
		dropdownSetting(L["mythicPlusTimerFontOutline"] or "Font outline", get("fontOutline"), set("fontOutline", normalizeFontStyle), buildStyleOptions, fontId, 180),
		sliderSetting(L["mythicPlusTimerFontSize"] or "Font size", get("fontSize"), set("fontSize", function(value) return clampNumber(value, 8, 32, defaults.fontSize) end), 8, 32, 1, fontId),
		sliderSetting(L["mythicPlusTimerTitleFontSize"] or "Title font size", get("titleFontSize"), set("titleFontSize", function(value) return clampNumber(value, 8, 40, defaults.titleFontSize) end), 8, 40, 1, fontId),
		sliderSetting(L["mythicPlusTimerTimerFontSize"] or "Timer font size", get("timerFontSize"), set("timerFontSize", function(value) return clampNumber(value, 8, 44, defaults.timerFontSize) end), 8, 44, 1, fontId),
		{ name = L["mythicPlusTimerSectionColors"] or "Colors", kind = SettingType.Collapsible, id = colorId, defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerUseGlobalTextColor"] or "Use global text color", get("useGlobalTextColor"), set("useGlobalTextColor", nil, true), colorId, nil, isListMode),
		colorSetting(L["mythicPlusTimerTextColor"] or "Text color", get("textColor"), set("textColor"), defaults.textColor, colorId, enabledWhen("useGlobalTextColor"), isListMode),
		colorSetting(L["mythicPlusTimerDungeonColor"] or "Dungeon color", get("dungeonColor"), set("dungeonColor"), defaults.dungeonColor, colorId),
		colorSetting(L["mythicPlusTimerAffixColor"] or "Affix color", get("affixColor"), set("affixColor"), defaults.affixColor, colorId),
		colorSetting(L["mythicPlusTimerTimerColor"] or "Timer color", get("timerColor"), set("timerColor"), defaults.timerColor, colorId),
		colorSetting(L["mythicPlusTimerExpiredColor"] or "Expired timer color", get("timerExpiredColor"), set("timerExpiredColor"), defaults.timerExpiredColor, colorId),
		colorSetting(L["mythicPlusTimerChestColor"] or "+2/+3 color", get("chestColor"), set("chestColor"), defaults.chestColor, colorId),
		colorSetting(L["mythicPlusTimerDeathColor"] or "Death color", get("deathColor"), set("deathColor"), defaults.deathColor, colorId),
		colorSetting(L["mythicPlusTimerObjectiveColor"] or "Objective color", get("objectiveColor"), set("objectiveColor"), defaults.objectiveColor, colorId),
		colorSetting(L["mythicPlusTimerObjectiveCompleteColor"] or "Completed objective color", get("objectiveCompleteColor"), set("objectiveCompleteColor"), defaults.objectiveCompleteColor, colorId),
		colorSetting(L["mythicPlusTimerObjectiveBestDeltaFasterColor"] or "Faster best delta color", get("objectiveBestDeltaFasterColor"), set("objectiveBestDeltaFasterColor"), defaults.objectiveBestDeltaFasterColor, colorId),
		colorSetting(L["mythicPlusTimerObjectiveBestDeltaSlowerColor"] or "Slower best delta color", get("objectiveBestDeltaSlowerColor"), set("objectiveBestDeltaSlowerColor"), defaults.objectiveBestDeltaSlowerColor, colorId),
		colorSetting(L["mythicPlusTimerEnemyForcesColor"] or "Enemy forces color", get("enemyForcesColor"), set("enemyForcesColor"), defaults.enemyForcesColor, colorId),
		{ name = L["Background"] or "Background", kind = SettingType.Collapsible, id = backgroundId, defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerBackdropEnabled"] or "Use background", get("backdropEnabled"), set("backdropEnabled", nil, true), backgroundId),
		checkboxSetting(L["damageMeterHeaderBackgroundUseCustomTexture"] or "Custom texture", get("backdropUseCustomTexture"), set("backdropUseCustomTexture", nil, true), backgroundId, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		inputSetting(L["damageMeterHeaderBackgroundCustomTexture"] or "Atlas name or texture ID", get("backdropCustomTexture"), set("backdropCustomTexture", trimTextureInput), backgroundId, allEnabled("backdropEnabled", "backdropUseCustomTexture"), L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160, allShown("backdropEnabled", "backdropUseCustomTexture")),
		dropdownSetting(L["mythicPlusTimerBackdropTexture"] or "Background texture", get("backdropTexture"), set("backdropTexture"), function() return buildMediaOptions("statusbar", false) end, backgroundId, 260, allEnabledAndNot("backdropUseCustomTexture", "backdropEnabled"), allEnabledAndNot("backdropUseCustomTexture", "backdropEnabled")),
		colorSetting(L["mythicPlusTimerBackdropColor"] or "Background color", get("backdropColor"), set("backdropColor"), defaults.backdropColor, backgroundId, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		dropdownSetting(L["Anchor"] or "Anchor", get("backdropAnchor"), set("backdropAnchor", normalizePoint), anchorOptions, backgroundId, 220, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", get("backdropSizeOffsetX"), set("backdropSizeOffsetX", function(value) return clampNumber(value, -1000, 1000, defaults.backdropSizeOffsetX) end), -1000, 1000, 1, backgroundId, nil, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", get("backdropSizeOffsetY"), set("backdropSizeOffsetY", function(value) return clampNumber(value, -1000, 1000, defaults.backdropSizeOffsetY) end), -1000, 1000, 1, backgroundId, nil, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		sliderSetting(L["Offset X"] or "Offset X", get("backdropOffsetX"), set("backdropOffsetX", function(value) return clampNumber(value, -1000, 1000, defaults.backdropOffsetX) end), -1000, 1000, 1, backgroundId, nil, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		sliderSetting(L["Offset Y"] or "Offset Y", get("backdropOffsetY"), set("backdropOffsetY", function(value) return clampNumber(value, -1000, 1000, defaults.backdropOffsetY) end), -1000, 1000, 1, backgroundId, nil, enabledWhen("backdropEnabled"), shownWhen("backdropEnabled")),
		{ name = L["Header"] or "Header", kind = SettingType.Collapsible, id = headerId, defaultCollapsed = true },
		{ name = L["settingsCategoryFooter"] or L["damageMeterFooter"] or "Footer", kind = SettingType.Collapsible, id = footerId, defaultCollapsed = true },
		{ name = L["Border"] or "Border", kind = SettingType.Collapsible, id = borderId, defaultCollapsed = true },
		checkboxSetting(L["mythicPlusTimerBorderEnabled"] or "Use border", get("borderEnabled"), set("borderEnabled", nil, true), borderId),
		dropdownSetting(L["mythicPlusTimerBorderTexture"] or "Border texture", get("borderTexture"), set("borderTexture"), function() return buildMediaOptions("border", false) end, borderId, 260, enabledWhen("borderEnabled")),
		colorSetting(L["mythicPlusTimerBorderColor"] or "Border color", get("borderColor"), set("borderColor"), defaults.borderColor, borderId, enabledWhen("borderEnabled")),
		sliderSetting(L["mythicPlusTimerBorderSize"] or "Border size", get("borderSize"), set("borderSize", function(value) return clampNumber(value, 1, 32, defaults.borderSize) end), 1, 32, 1, borderId, nil, enabledWhen("borderEnabled")),
		checkboxSetting(L["damageMeterBorderAdvancedOffsets"] or "Separate border offsets", get("borderSeparateOffset"), set("borderSeparateOffset", nil, true), borderId, enabledWhen("borderEnabled")),
		sliderSetting(L["mythicPlusTimerBorderInset"] or "Border offset", get("borderInset"), set("borderInset", function(value) return clampNumber(value, -300, 300, defaults.borderInset) end), -300, 300, 1, borderId, nil, allEnabledAndNot("borderSeparateOffset", "borderEnabled")),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", get("borderOffsetX"), set("borderOffsetX", function(value) return clampNumber(value, -300, 300, defaults.borderOffsetX) end), -300, 300, 1, borderId, nil, allEnabled("borderEnabled", "borderSeparateOffset")),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", get("borderOffsetY"), set("borderOffsetY", function(value) return clampNumber(value, -300, 300, defaults.borderOffsetY) end), -300, 300, 1, borderId, nil, allEnabled("borderEnabled", "borderSeparateOffset")),
		sliderSetting(L["Offset X"] or "Offset X", get("borderPositionOffsetX"), set("borderPositionOffsetX", function(value) return clampNumber(value, -1000, 1000, defaults.borderPositionOffsetX) end), -1000, 1000, 1, borderId, nil, enabledWhen("borderEnabled")),
		sliderSetting(L["Offset Y"] or "Offset Y", get("borderPositionOffsetY"), set("borderPositionOffsetY", function(value) return clampNumber(value, -1000, 1000, defaults.borderPositionOffsetY) end), -1000, 1000, 1, borderId, nil, enabledWhen("borderEnabled")),
		divider(borderId),
	}
	for _, setting in ipairs(decorBarSettings("header", headerId)) do
		settings[#settings + 1] = setting
	end
	for _, setting in ipairs(decorBarSettings("footer", footerId)) do
		settings[#settings + 1] = setting
	end
	if Timer.PanelFlow and Timer.PanelFlow.BuildEditModeSettings then
		for _, setting in ipairs(Timer.PanelFlow:BuildEditModeSettings(SettingType)) do settings[#settings + 1] = setting end
	end
	settings = orderSettingsByParent(settings)
	local panelIds = {
		["mpt-panel-dungeon-key"] = true,
		["mpt-panel-time"] = true,
		["mpt-panel-deaths"] = true,
		["mpt-panel-enemy"] = true,
		["mpt-panel-best"] = true,
		["mpt-panel-objectives"] = true,
		["mpt-panel-affixes"] = true,
	}
	for _, setting in ipairs(settings) do
		if panelIds[setting.id] or panelIds[setting.parentId] then setting.isShown = isPanelMode end
	end
	local legacySectionIds = {
		[barId] = true,
		[fontId] = true,
		[colorId] = true,
		[backgroundId] = true,
		[headerId] = true,
		[footerId] = true,
		[borderId] = true,
	}
	for _, setting in ipairs(settings) do
		if legacySectionIds[setting.id] then setting.isShown = isLegacyMode end
	end
	applyParentVisibility(settings)
	return settings
end

function Timer:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end
	local settings = self:BuildEditModeSettings()
	if addon.DynamicAnchors then
		table.insert(settings, 1, {
			name = L["Anchor"] or "Anchor",
			kind = SettingType.Collapsible,
			id = "mythicPlusTimerAnchor",
			defaultCollapsed = false,
		})
		addon.DynamicAnchors:AddEditModeAssignmentSettings(settings, SettingType, {
			consumerId = self.dynamicAnchorId,
			parentId = "mythicPlusTimerAnchor",
			insertAfterId = "mythicPlusTimerAnchor",
			refresh = function(rebuild)
				if rebuild and EditMode and EditMode.RefreshFrame then
					EditMode:RefreshFrame(EDITMODE_ID)
					RunNextFrame(function() Timer:ApplyDynamicAnchor() end)
				else
					Timer:ApplyDynamicAnchor()
				end
			end,
		})
	end
	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["mythicPlusTimerTitle"] or "Mythic+ Timer",
		layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 160 },
		onApply = function()
			Timer:Refresh()
			Timer:ApplyDynamicAnchor()
		end,
		onEnter = function()
			Timer.panelBackdropReferenceReady = nil
			Timer:Refresh()
			if addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(Timer.dynamicAnchorId) then RunNextFrame(function() Timer:ApplyDynamicAnchor() end) end
			Timer:ScheduleTick()
			C_Timer.After(0, requestSettingsRefresh)
			C_Timer.After(0.05, requestSettingsRefresh)
		end,
		onExit = function()
			C_Timer.After(0, function() Timer:Refresh() end)
		end,
		isEnabled = function() return Timer:IsEnabled() end,
		settings = settings,
		showOutsideEditMode = false,
		showReset = true,
		showSettingsReset = false,
		enableOverlayToggle = true,
		relativeTo = function()
			local winner = Timer:GetDynamicAnchorWinner()
			return winner and winner.frame or UIParent
		end,
		allowDrag = function() return not (addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(Timer.dynamicAnchorId)) end,
		collapseExclusive = true,
		settingsMaxHeight = 700,
	})
	self.editModeRegistered = true
end

function Timer:Init()
	if self.initialized then return end
	local config = getTimerConfig(false)
	if config and config.layoutMode == nil then config.layoutMode = "PANEL" end
	self:MigratePanelEnemyBarSettings()
	self.initialized = true
	self.eventFrame = CreateFrame("Frame")
	self.eventFrame:SetScript("OnEvent", function(_, event, ...)
		if not Timer:IsEnabled() then return end
		if event == "WORLD_STATE_TIMER_START" or event == "CHALLENGE_MODE_START" then
			Timer:SyncActiveTimerBase(true)
			Timer.completedElapsed = nil
			Timer.completedInfo = nil
			Timer.lastRunElapsed = nil
			Timer.lastRunInfo = nil
			Timer.lastObjectives = nil
			Timer.lastEnemyForces = nil
			Timer.objectiveSplits = {}
			Timer.objectiveSplitBestTimes = {}
			Timer.objectiveStates = {}
			Timer:ResetDeathTracking()
			Timer:RefreshGroupRoster()
			Timer:ScheduleRunInfoRefresh()
		elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
			Timer:SyncActiveTimerBase(true)
		elseif event == "UNIT_DIED" then
			if Timer:TrackUnitDied(...) then Timer:Refresh() end
			return
		elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_DIFFICULTY_CHANGED" or event == "CHALLENGE_MODE_MAPS_UPDATE" then
			Timer:RefreshGroupRoster()
			if event == "PLAYER_DIFFICULTY_CHANGED" or event == "CHALLENGE_MODE_MAPS_UPDATE" then Timer:ScheduleRunInfoRefresh() end
		elseif event == "WORLD_STATE_TIMER_STOP" or event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
			if event == "CHALLENGE_MODE_COMPLETED" then Timer:RecordBestTime() end
			if event == "CHALLENGE_MODE_RESET" then
				Timer.objectiveSplits = {}
				Timer.objectiveSplitBestTimes = {}
				Timer.objectiveStates = {}
				Timer.completedElapsed = nil
				Timer.completedInfo = nil
				Timer.lastRunElapsed = nil
				Timer.lastRunInfo = nil
				Timer.lastObjectives = nil
				Timer.lastEnemyForces = nil
				Timer:ResetDeathTracking()
			else
				Timer.completedInfo = getCompletionInfo()
				local _, activeElapsed = getActiveChallengeTimer()
				Timer.completedElapsed = getCompletionElapsed() or tonumber(activeElapsed) or tonumber(Timer.lastRunElapsed) or tonumber(Timer.lastState and Timer.lastState.elapsed) or 0
			end
			Timer:SyncActiveTimerBase(true)
		end
		Timer:Refresh()
		Timer:ScheduleTick()
	end)
	if addon.DynamicAnchors then
		addon.DynamicAnchors:RegisterSimpleFrame({
			id = self.dynamicAnchorId,
			owner = "EnhanceQoLDungeonRaid",
			label = L["mythicPlusTimerTitle"] or "Mythic+ Timer",
			menuGroup = "TRACKERS",
			menuGroupLabel = L["Dynamic Anchor Group Trackers"],
			menuGroupOrder = 400,
			getFrame = function() return Timer.frame end,
			isAvailable = function(timerFrame) return Timer:IsEnabled() and timerFrame ~= nil and timerFrame:IsShown() end,
			apply = function() Timer:ApplyDynamicAnchor() end,
		})
	end
	self:RegisterEditMode()
	self:EnsurePanelBackdropReference()
	self:UpdateEventState()
end

function addon.MythicPlus.functions.InitMythicPlusTimer()
	if Timer.Init then Timer:Init() end
end

function addon.MythicPlus.functions.RefreshMythicPlusTimer()
	if Timer.Refresh then Timer:Refresh() end
end

local loader = CreateFrame("Frame")
local function initializeMythicPlusTimer()
	Timer:Init()
end
if IsLoggedIn and IsLoggedIn() then
	initializeMythicPlusTimer()
else
	loader:RegisterEvent("PLAYER_LOGIN")
	loader:SetScript("OnEvent", initializeMythicPlusTimer)
end
