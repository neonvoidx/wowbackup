local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.ReputationBar = addon.Aura.ReputationBar or {}
local ReputationBar = addon.Aura.ReputationBar

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local LSM = LibStub("LibSharedMedia-3.0", true)
local BORDER_LABEL = EMBLEM_BORDER
local TEXT_LABEL = LOCALE_TEXT_LABEL

local EDITMODE_ID = "repBar"
local ANCHOR_TARGET_UI = "UIParent"
local ANCHOR_TARGET_PLAYER_CASTBAR = "PLAYER_CASTBAR"
local EQOL_PLAYER_CASTBAR = "EQOLUFPlayerHealthCast"
local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local VALID_ANCHOR_POINTS = {}
for _, point in ipairs(ANCHOR_POINTS) do
	VALID_ANCHOR_POINTS[point] = true
end

local function globalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function globalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

local function globalFontStyleConfigKey()
	if addon.functions and addon.functions.GetGlobalFontStyleConfigKey then return addon.functions.GetGlobalFontStyleConfigKey() end
	return "__EQOL_GLOBAL_FONT_STYLE__"
end

local function defaultFontFace()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
end

ReputationBar.defaults = ReputationBar.defaults
	or {
		width = 260,
		height = 16,
		texture = "DEFAULT",
		color = { r = 0.35, g = 0.85, b = 0.25, a = 1 },
		useStandingColor = true,
		bgEnabled = true,
		bgTexture = "SOLID",
		bgColor = { r = 0, g = 0, b = 0, a = 0.45 },
		borderEnabled = false,
		borderTexture = "DEFAULT",
		borderColor = { r = 0, g = 0, b = 0, a = 0.85 },
		borderSize = 1,
		borderOffset = 0,
		fillDirection = "LEFT",
		anchorRelativeFrame = ANCHOR_TARGET_UI,
		anchorMatchRelativeWidth = false,
		anchorMatchRelativeWidthOffset = 0,
		anchorPoint = "CENTER",
		anchorRelativePoint = "CENTER",
		anchorOffsetX = 0,
		anchorOffsetY = -170,
		textEnabled = true,
			textMode = "CURMAXPERCENT", -- legacy fallback for center
			textLeftMode = "FACTION",
			textCenterMode = "CURMAXPERCENT",
			textRightMode = "STANDING",
			textLeftOffsetX = 4,
			textLeftOffsetY = 0,
			textCenterOffsetX = 0,
			textCenterOffsetY = 0,
			textRightOffsetX = -4,
			textRightOffsetY = 0,
			textSize = 11,
		textFont = globalFontConfigKey(),
		textOutline = globalFontStyleConfigKey(),
		textColor = { r = 1, g = 1, b = 1, a = 1 },
		abbreviateNumbers = false,
		hideInPetBattle = false,
		hideBlizzardTracking = true,
	}

local defaults = ReputationBar.defaults

local DB_ENABLED = "repBarEnabled"
local DB_WIDTH = "repBarWidth"
local DB_HEIGHT = "repBarHeight"
local DB_TEXTURE = "repBarTexture"
local DB_COLOR = "repBarColor"
local DB_USE_STANDING_COLOR = "repBarUseStandingColor"
local DB_BG_ENABLED = "repBarBackgroundEnabled"
local DB_BG_TEXTURE = "repBarBackgroundTexture"
local DB_BG_COLOR = "repBarBackgroundColor"
local DB_BORDER_ENABLED = "repBarBorderEnabled"
local DB_BORDER_TEXTURE = "repBarBorderTexture"
local DB_BORDER_COLOR = "repBarBorderColor"
local DB_BORDER_SIZE = "repBarBorderSize"
local DB_BORDER_OFFSET = "repBarBorderOffset"
local DB_FILL_DIRECTION = "repBarFillDirection"
local DB_ANCHOR_RELATIVE_FRAME = "repBarAnchorTarget"
local DB_ANCHOR_MATCH_WIDTH = "repBarAnchorMatchWidth"
local DB_ANCHOR_MATCH_WIDTH_OFFSET = "repBarAnchorMatchWidthOffset"
local DB_ANCHOR_POINT = "repBarAnchorPoint"
local DB_ANCHOR_RELATIVE_POINT = "repBarAnchorRelativePoint"
local DB_ANCHOR_OFFSET_X = "repBarAnchorOffsetX"
local DB_ANCHOR_OFFSET_Y = "repBarAnchorOffsetY"
local DB_TEXT_ENABLED = "repBarShowText"
local DB_TEXT_MODE = "repBarTextMode" -- legacy fallback
local DB_TEXT_LEFT_MODE = "repBarTextLeftMode"
local DB_TEXT_CENTER_MODE = "repBarTextCenterMode"
local DB_TEXT_RIGHT_MODE = "repBarTextRightMode"
local DB_TEXT_LEFT_OFFSET_X = "repBarTextLeftOffsetX"
local DB_TEXT_LEFT_OFFSET_Y = "repBarTextLeftOffsetY"
local DB_TEXT_CENTER_OFFSET_X = "repBarTextCenterOffsetX"
local DB_TEXT_CENTER_OFFSET_Y = "repBarTextCenterOffsetY"
local DB_TEXT_RIGHT_OFFSET_X = "repBarTextRightOffsetX"
local DB_TEXT_RIGHT_OFFSET_Y = "repBarTextRightOffsetY"
local DB_TEXT_SIZE = "repBarTextSize"
local DB_TEXT_FONT = "repBarTextFont"
local DB_TEXT_OUTLINE = "repBarTextOutline"
local DB_TEXT_COLOR = "repBarTextColor"
local DB_TEXT_ABBREVIATE_NUMBERS = "repBarTextAbbreviateNumbers"
local DB_HIDE_IN_PET_BATTLE = "repBarHideInPetBattle"
local DB_HIDE_BLIZZARD_TRACKING = "repBarHideBlizzardTracking"
local DB_VISIBILITY = "repBarVisibility"
local DB_VISIBILITY_EXPLICIT = "repBarVisibilityExplicit"
local DB_PRESERVED_FACTION_ID = "repBarPreservedFactionID"

local DEFAULT_TEX = "Interface\\TargetingFrame\\UI-StatusBar"
local BAR_SIZE_MIN = 6
local BAR_SIZE_MAX = 2000
local BAR_WIDTH_MAX = 5000
local TEXT_SIZE_MIN = 8
local TEXT_SIZE_MAX = 30
local DEFAULT_SETTINGS_MAX_HEIGHT = 900
local DEFAULT_SETTINGS_SCREEN_MARGIN = 200

local function getCachedMediaNames(mediaType)
	if addon.functions and addon.functions.GetLSMMediaNames then
		local names = addon.functions.GetLSMMediaNames(mediaType)
		if type(names) == "table" then return names end
	end
	return {}
end

local function getCachedMediaHash(mediaType)
	if addon.functions and addon.functions.GetLSMMediaHash then
		local hash = addon.functions.GetLSMMediaHash(mediaType)
		if type(hash) == "table" then return hash end
	end
	return {}
end

local REP_BAR_FRAME_NAME = "EQOL_RepBar"
local REP_BAR_EVENT_FRAME_NAME = "EQOL_RepBarEventDriver"
local registerEditModeCallbacks
local settingsMaxHeightWatcher

local function getValue(key, fallback)
	if not addon.db then return fallback end
	local value = addon.db[key]
	if value == nil then return fallback end
	return value
end

local function shouldHideInPetBattleForRep() return getValue(DB_HIDE_IN_PET_BATTLE, defaults.hideInPetBattle) == true end

local function isPetBattleActive() return C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() == true end

function ReputationBar:GetVisibilityRuntimeConfig()
	local cfg = self._visibilityRuntimeConfig
	if not cfg then
		cfg = {}
		self._visibilityRuntimeConfig = cfg
	end
	cfg.enabled = self:IsEnabled()
	cfg.visibility = addon.db and addon.db[DB_VISIBILITY] or nil
	cfg.visibilityExplicit = addon.db and addon.db[DB_VISIBILITY_EXPLICIT] == true or nil
	cfg.hidePetBattle = addon.db and addon.db[DB_HIDE_IN_PET_BATTLE] ~= nil and addon.db[DB_HIDE_IN_PET_BATTLE] == true or nil
	cfg.hideClientScene = nil
	cfg.hideOutOfCombat = nil
	cfg.hideMounted = nil
	cfg.hideVehicle = nil
	cfg.hideWhenEmpty = nil
	cfg.visibilityFadeStrength = nil
	return cfg
end

function ReputationBar:RegisterVisibilityFrame()
	local rb = addon.Aura and addon.Aura.ResourceBars
	if not (rb and rb.RegisterCustomVisibilityFrame and self.frame) then return end
	rb.RegisterCustomVisibilityFrame("REPUTATION", self.frame, self:GetVisibilityRuntimeConfig())
end

function ReputationBar:ApplyVisibilityPreference(runtimeVisible)
	if self.frame then self.frame._rbDesiredVisible = runtimeVisible == true end
	self:RegisterVisibilityFrame()
	local rb = addon.Aura and addon.Aura.ResourceBars
	if rb and rb.ApplyVisibilityPreference then rb.ApplyVisibilityPreference("repBar") end
end

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local function normalizeColor(value, fallback)
	if type(value) == "table" then
		local r = value.r or value[1] or 1
		local g = value.g or value[2] or 1
		local b = value.b or value[3] or 1
		local a = value.a or value[4]
		return r, g, b, a
	elseif type(value) == "number" then
		return value, value, value
	end
	local d = fallback or defaults.color or {}
	return d.r or 1, d.g or 1, d.b or 1, d.a
end

local function isLikelyFilePath(value)
	if type(value) ~= "string" or value == "" then return false end
	return string.find(value, "[/\\]") ~= nil
end

local function resolveTexture(key)
	if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if not key or key == "" or key == "DEFAULT" then return DEFAULT_TEX end
	if LSM and LSM.Fetch then
		local tex = LSM:Fetch("statusbar", key, true)
		if tex then return tex end
	end
	if isLikelyFilePath(key) then return key end
	return DEFAULT_TEX
end

local function resolveBorderTexture(key)
	if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if not key or key == "" or key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	if LSM and LSM.Fetch then
		local tex = LSM:Fetch("border", key, true)
		if tex then return tex end
	end
	if isLikelyFilePath(key) then return key end
	return "Interface\\Buttons\\WHITE8x8"
end

local function textureOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local lv = tostring(value or ""):lower()
		if lv == "" or seen[lv] then return end
		seen[lv] = true
		list[#list + 1] = { value = value, label = label }
	end

	add("DEFAULT", _G.DEFAULT)
	add("SOLID", "Solid")
	local names = getCachedMediaNames("statusbar")
	local hash = getCachedMediaHash("statusbar")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	return list
end

local function borderOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local lv = tostring(value or ""):lower()
		if lv == "" or seen[lv] then return end
		seen[lv] = true
		list[#list + 1] = { value = value, label = label }
	end

	add("DEFAULT", _G.DEFAULT)
	add("SOLID", "Solid")
	local names = getCachedMediaNames("border")
	local hash = getCachedMediaHash("border")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	return list
end

local function fontOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local lv = tostring(value or ""):lower()
		if lv == "" or seen[lv] then return end
		seen[lv] = true
		list[#list + 1] = { value = value, label = label }
	end

	add(globalFontConfigKey(), globalFontConfigLabel())
	add("DEFAULT", _G.DEFAULT)
	local names = getCachedMediaNames("font")
	local hash = getCachedMediaHash("font")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	local globalKey = globalFontConfigKey()
	for idx, option in ipairs(list) do
		if option.value == globalKey then
			if idx > 1 then
				table.remove(list, idx)
				table.insert(list, 1, option)
			end
			break
		end
	end
	return list
end

local function resolveFontPath(key)
	local defaultFont = defaultFontFace()
	if not key or key == "" or key == "DEFAULT" or key == globalFontConfigKey() then return defaultFont end
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(key, defaultFont) or defaultFont end
	if LSM and LSM.Fetch then
		local font = LSM:Fetch("font", key, true)
		if font then return font end
	end
	if LSM and LSM.HashTable then
		local hash = LSM:HashTable("font") or {}
		for _, fontPath in pairs(hash) do
			if fontPath == key then return key end
		end
	end
	return defaultFont
end

local function setFontWithFallback(fontString, fontPath, size, outline)
	if not (fontString and fontString.SetFont and fontPath) then return false end
	if addon.functions and addon.functions.SetFontWithFallback then return addon.functions.SetFontWithFallback(fontString, fontPath, size, outline, defaultFontFace()) end
	local ok, applied = pcall(fontString.SetFont, fontString, fontPath, size, outline)
	if ok and applied ~= false then return true end
	local fallback = defaultFontFace()
	if not fallback or fallback == fontPath then return false end
	ok, applied = pcall(fontString.SetFont, fontString, fallback, size, outline)
	return ok and applied ~= false
end

local function normalizeTextOutline(value)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, defaults.textOutline or "OUTLINE", true)
	end
	if value == "OUTLINE" then return "OUTLINE" end
	if value == "THICKOUTLINE" then return "THICKOUTLINE" end
	if value == "MONOCHROME" then return "MONOCHROME" end
	return "NONE"
end

local function resolveTextOutlineFlags(value, fallback)
	if addon.functions and addon.functions.ResolveFontStyle then
		local _, flags = addon.functions.ResolveFontStyle(value, fallback or defaults.textOutline or "OUTLINE")
		return flags
	end
	if addon.functions and addon.functions.GetFontFlagsForStyle then
		local flags = addon.functions.GetFontFlagsForStyle(value, fallback or defaults.textOutline or "OUTLINE")
		if type(flags) == "string" then return flags end
	end
	local outline = normalizeTextOutline(value)
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = normalizeTextOutline(fallback or defaults.textOutline or "OUTLINE") end
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = "OUTLINE" end
	if outline == "NONE" then return "" end
	return outline
end

local function normalizeFillDirection(value)
	if type(value) == "string" then value = string.upper(value) end
	if value == "RIGHT" then return "RIGHT" end
	if value == "UP" or value == "BOTTOM" then return "UP" end
	if value == "DOWN" or value == "TOP" then return "DOWN" end
	return "LEFT"
end

local function isVerticalFillDirection(value) return value == "UP" or value == "DOWN" end

local function isReverseFillDirection(value) return value == "RIGHT" or value == "DOWN" end

local function normalizeAnchorPoint(value, fallback)
	if value and VALID_ANCHOR_POINTS[value] then return value end
	if fallback and VALID_ANCHOR_POINTS[fallback] then return fallback end
	return "CENTER"
end

local function normalizeAnchorRelativeFrame(value)
	if value == ANCHOR_TARGET_PLAYER_CASTBAR or value == "PlayerCastingBarFrame" or value == EQOL_PLAYER_CASTBAR then return ANCHOR_TARGET_PLAYER_CASTBAR end
	if type(value) == "string" and value ~= "" then return value end
	return ANCHOR_TARGET_UI
end

local function normalizeAnchorOffset(value, fallback)
	local num = tonumber(value)
	if num == nil then num = fallback end
	if num == nil then num = 0 end
	return clamp(num, -1000, 1000)
end

local function normalizeTextOffset(value, fallback)
	local num = tonumber(value)
	if num == nil then num = fallback end
	if num == nil then num = 0 end
	return clamp(num, -200, 200)
end

local function normalizeLegacyTextMode(value)
	if value == "CURMAX" then return "CURMAX" end
	if value == "CURMAXPERCENT" then return "CURMAXPERCENT" end
	return "PERCENT"
end

local function normalizeTextContentMode(value)
	if value == "NONE" then return "NONE" end
	if value == "FACTION" then return "FACTION" end
	if value == "STANDING" then return "STANDING" end
	if value == "CURMAX" then return "CURMAX" end
	if value == "CURMAX_NEEDED" then return "CURMAX_NEEDED" end
	if value == "PERCENT" then return "PERCENT" end
	if value == "CURMAXPERCENT" then return "CURMAXPERCENT" end
	if value == "RATE_PER_HOUR" then return "RATE_PER_HOUR" end
	if value == "ETA_NEXT" then return "ETA_NEXT" end
	if value == "ETA_NEXT_RATE" then return "ETA_NEXT_RATE" end
	return "NONE"
end

local function textModeOptions()
	return {
		{ value = "NONE", label = NONE },
		{ value = "FACTION", label = L["repBarTextTypeFaction"] or "Faction" },
		{ value = "STANDING", label = L["repBarTextTypeStanding"] or "Standing" },
		{ value = "CURMAX", label = L["repBarTextTypeCurMax"] or "Current / Max" },
		{ value = "CURMAX_NEEDED", label = L["repBarTextTypeCurMaxNeeded"] or "Current / Max (needed)" },
		{ value = "PERCENT", label = L["Percent"] or "Percent" },
		{ value = "CURMAXPERCENT", label = L["repBarTextTypeCurMaxPercent"] or "Current / Max (percent)" },
		{ value = "RATE_PER_HOUR", label = L["repBarTextTypeRepPerHour"] or "Reputation per hour" },
		{ value = "ETA_NEXT", label = L["repBarTextTypeETA"] or "Standing in" },
		{ value = "ETA_NEXT_RATE", label = L["repBarTextTypeETARepPerHour"] or "Standing in (+rep/h)" },
	}
end

local function refreshSettingsUI()
	local lib = addon.EditModeLib
	if not (lib and lib.internal) then return end
	if lib.internal.RefreshSettings then lib.internal:RefreshSettings() end
	if lib.internal.RefreshSettingValues then lib.internal:RefreshSettingValues() end
end

local function getSettingsMaxHeight()
	local screenHeight = addon.variables and tonumber(addon.variables.screenHeight)
	if (not screenHeight or screenHeight <= 0) and GetScreenHeight then
		screenHeight = tonumber(GetScreenHeight())
		if screenHeight and screenHeight > 0 then
			addon.variables = addon.variables or {}
			addon.variables.screenHeight = screenHeight
		end
	end
	if not screenHeight or screenHeight <= 0 then return DEFAULT_SETTINGS_MAX_HEIGHT end
	if screenHeight < DEFAULT_SETTINGS_MAX_HEIGHT then return screenHeight end
	return math.max(DEFAULT_SETTINGS_MAX_HEIGHT, screenHeight - DEFAULT_SETTINGS_SCREEN_MARGIN)
end

local function applyFrameSettingsMaxHeight(frame, maxHeight)
	local lib = addon.EditModeLib or (EditMode and EditMode.lib)
	if not (lib and lib.SetFrameSettingsMaxHeight and frame) then return end
	lib:SetFrameSettingsMaxHeight(frame, maxHeight or getSettingsMaxHeight())
end

local function applyRegisteredSettingsMaxHeight() applyFrameSettingsMaxHeight(ReputationBar and ReputationBar.frame, getSettingsMaxHeight()) end

local function ensureSettingsMaxHeightWatcher()
	if settingsMaxHeightWatcher then return end
	settingsMaxHeightWatcher = CreateFrame("Frame")
	settingsMaxHeightWatcher:RegisterEvent("PLAYER_LOGIN")
	settingsMaxHeightWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
	settingsMaxHeightWatcher:RegisterEvent("UI_SCALE_CHANGED")
	settingsMaxHeightWatcher:SetScript("OnEvent", function()
		if GetScreenHeight then
			local screenHeight = tonumber(GetScreenHeight())
			if screenHeight and screenHeight > 0 then
				addon.variables = addon.variables or {}
				addon.variables.screenHeight = screenHeight
			end
		end
		applyRegisteredSettingsMaxHeight()
	end)
end

local function isCustomPlayerCastbarEnabled()
	if addon.functions and addon.functions.IsEQoLUnitFrameEnabled and not addon.functions.IsEQoLUnitFrameEnabled("player") then return false end
	local cfg = addon.db and addon.db.ufFrames and addon.db.ufFrames.player
	if not (cfg and cfg.enabled == true) then return false end
	local castCfg = cfg.cast
	if not castCfg then
		local uf = addon.Aura and addon.Aura.UF
		local ufDefaults = uf and uf.defaults and uf.defaults.player
		castCfg = ufDefaults and ufDefaults.cast
	end
	if not castCfg then return false end
	return castCfg.enabled ~= false
end

local function resolvePlayerCastbarFrame()
	local wantsCustom = isCustomPlayerCastbarEnabled()
	if wantsCustom then
		local custom = _G and _G[EQOL_PLAYER_CASTBAR]
		if custom then return custom, true, true end
	end
	local blizz = _G and _G.PlayerCastingBarFrame
	if blizz then return blizz, false, wantsCustom end
	return UIParent, false, wantsCustom
end

local function normalizeReputationValue(value)
	local n = tonumber(value) or 0
	if n < 0 then return 0 end
	return n
end

local function standingLabel(standingID)
	local id = tonumber(standingID)
	if not id then return nil end
	local key = "FACTION_STANDING_LABEL" .. tostring(id)
	local label = _G[key]
	if type(label) == "string" and label ~= "" then return label end
	if GetText then
		local ok, text = pcall(GetText, key, UnitSex and UnitSex("player") or 2)
		if ok and type(text) == "string" and text ~= "" then return text end
	end
	return nil
end

local function formatNumber(value, abbreviateNumbers)
	value = math.floor((tonumber(value) or 0) + 0.5)
	if abbreviateNumbers and AbbreviateNumbers then return AbbreviateNumbers(value) end
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(value) end
	return tostring(value)
end

local function formatRateNumber(value, abbreviateNumbers)
	value = math.floor((tonumber(value) or 0) + 0.5)
	if abbreviateNumbers and AbbreviateNumbers then return AbbreviateNumbers(value) end
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(value) end
	return tostring(value)
end

local function formatDurationShort(seconds)
	local total = math.max(0, tonumber(seconds) or 0)
	total = math.floor(total + 0.5)
	if total < 60 then return "<1m" end
	if total < 3600 then return string.format("%dm", math.floor(total / 60)) end
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	if hours < 24 then
		if minutes > 0 then return string.format("%dh %dm", hours, minutes) end
		return string.format("%dh", hours)
	end
	local days = math.floor(hours / 24)
	hours = hours % 24
	if hours > 0 then return string.format("%dd %dh", days, hours) end
	return string.format("%dd", days)
end

local function findWatchedFactionData()
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		local data = C_Reputation.GetWatchedFactionData()
		if data and data.factionID and data.factionID ~= 0 and data.name and data.name ~= "" then return data end
	end
	if not (C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex) then return nil end
	local count = tonumber(C_Reputation.GetNumFactions()) or 0
	for index = 1, count do
		local data = C_Reputation.GetFactionDataByIndex(index)
		if data and data.isWatched then return data end
	end
	return nil
end

local function isWatchingHonorAsExperience()
	local isWatching = _G and _G.IsWatchingHonorAsXP
	if isWatching then return isWatching() == true end
	if GetCVarBool then return GetCVarBool("showHonorAsExperience") == true end
	return false
end

local function rememberFactionID(factionID)
	local id = tonumber(factionID)
	if not id or id <= 0 then return end
	ReputationBar.preservedFactionID = id
	if addon.db then addon.db.repBarPreservedFactionID = id end
end

local function getPreservedFactionData()
	if not isWatchingHonorAsExperience() then return nil end
	local factionID = tonumber((addon.db and addon.db.repBarPreservedFactionID) or ReputationBar.preservedFactionID)
	if not factionID or factionID <= 0 then return nil end
	if not (C_Reputation and C_Reputation.GetFactionDataByID) then return nil end
	local data = C_Reputation.GetFactionDataByID(factionID)
	if data and data.factionID and data.factionID ~= 0 and data.name and data.name ~= "" then return data end
	return nil
end

local function applyFactionData(data, name, standingID, minValue, maxValue, value, factionID)
	if not data then return name, standingID, minValue, maxValue, value, factionID end
	factionID = data.factionID or factionID
	name = data.name or name
	standingID = data.reaction or standingID
	minValue = data.currentReactionThreshold or minValue
	maxValue = data.nextReactionThreshold or maxValue
	value = data.currentStanding or value
	return name, standingID, minValue, maxValue, value, factionID
end

local function getWatchedFactionContext()
	local name, standingID, minValue, maxValue, value, factionID
	if GetWatchedFactionInfo then name, standingID, minValue, maxValue, value, factionID = GetWatchedFactionInfo() end

	local data
	if factionID and factionID ~= 0 then rememberFactionID(factionID) end
	if not factionID or factionID == 0 or not name or name == "" then
		data = findWatchedFactionData() or getPreservedFactionData()
		if data then
			name, standingID, minValue, maxValue, value, factionID = applyFactionData(data, name, standingID, minValue, maxValue, value, factionID)
		end
	end

	if not name or name == "" then return nil end
	rememberFactionID(factionID)

	local context = {
		factionID = factionID,
		name = name,
		standingID = standingID,
		minValue = normalizeReputationValue(minValue),
		maxValue = normalizeReputationValue(maxValue),
		value = normalizeReputationValue(value),
		standingText = standingLabel(standingID),
		colorStandingID = standingID,
	}

	if factionID and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
		local friendship = C_GossipInfo.GetFriendshipReputation(factionID)
		if friendship and friendship.friendshipFactionID and friendship.friendshipFactionID > 0 then
			context.isFriendship = true
			context.name = friendship.name or context.name
			context.standingText = friendship.reaction or context.standingText
			context.minValue = normalizeReputationValue(friendship.reactionThreshold)
			context.maxValue = normalizeReputationValue(friendship.nextThreshold)
			context.value = normalizeReputationValue(friendship.standing)
			context.colorStandingID = 5
		end
	end

	if factionID and C_Reputation and C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID) and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
		local major = C_MajorFactions.GetMajorFactionData(factionID)
		if major then
			context.isMajorFaction = true
			context.name = major.name or context.name
			context.minValue = 0
			context.maxValue = normalizeReputationValue(major.renownLevelThreshold)
			context.value = normalizeReputationValue(major.renownReputationEarned)
			if major.renownLevel then
				local label = _G.RENOWN_LEVEL_LABEL or "Renown %d"
				context.standingText = string.format(label, major.renownLevel)
			end
			context.colorStandingID = 5
		end
	end

	if factionID and C_Reputation and C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionID) then
		local isCurrentPlayer = not C_Reputation.IsFactionParagonForCurrentPlayer or C_Reputation.IsFactionParagonForCurrentPlayer(factionID)
		if isCurrentPlayer and C_Reputation.GetFactionParagonInfo then
			local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
			threshold = normalizeReputationValue(threshold)
			if threshold > 0 then
				context.isParagon = true
				context.minValue = 0
				context.maxValue = threshold
				context.value = normalizeReputationValue(currentValue) % threshold
				context.hasRewardPending = hasRewardPending == true
				context.standingText = context.hasRewardPending and (_G.PARAGON_REPUTATION_REWARD_AVAILABLE or _G.REWARD_AVAILABLE or context.standingText) or (_G.PARAGON or context.standingText)
				context.colorStandingID = 5
			end
		end
	end

	local maximum = math.max(0, (context.maxValue or 0) - (context.minValue or 0))
	local current = math.max(0, (context.value or 0) - (context.minValue or 0))
	if maximum > 0 and current > maximum then current = maximum end
	if maximum <= 0 then return nil end

	local currentPercent = 0
	currentPercent = (current / maximum) * 100

	return {
		factionID = context.factionID,
		name = context.name,
		standingID = context.standingID,
		standingText = context.standingText,
		colorStandingID = context.colorStandingID,
		current = current,
		max = maximum,
		remaining = maximum > current and (maximum - current) or 0,
		currentPercent = currentPercent,
		isFriendship = context.isFriendship,
		isMajorFaction = context.isMajorFaction,
		isParagon = context.isParagon,
		hasRewardPending = context.hasRewardPending,
	}
end

function ReputationBar:BuildPreviewContext()
	return {
		name = L["ReputationBar"] or "Reputation Bar",
		standingText = _G.FACTION_STANDING_LABEL5 or "Friendly",
		standingID = 5,
		colorStandingID = 5,
		current = 1800,
		max = 2500,
		remaining = 700,
		currentPercent = 72,
		reputationPerHour = 4200,
		etaNextSeconds = 600,
	}
end

function ReputationBar:UpdatePreviewSample()
	if not self.frame then return end
	local sample = self:BuildPreviewContext()
	local maxReputation = sample.max or 0
	if maxReputation <= 0 then maxReputation = 1 end
	local currentReputation = sample.current or 0
	if currentReputation < 0 then currentReputation = 0 end
	if currentReputation > maxReputation then currentReputation = maxReputation end
	self:ApplyCurrentFillColor(sample)
	self.frame:SetMinMaxValues(0, 1)
	self.frame:SetValue(currentReputation / maxReputation)
	self._lastReputationContext = sample
	self:UpdateTextFromContext(sample)
	self.frame:Show()
	self:ApplyVisibilityPreference(true)
end

function ReputationBar:EnrichReputationContext(ctx)
	if not ctx then return end
	local now = GetTime and GetTime() or 0
	self._reputationStats = self._reputationStats or {}
	local stats = self._reputationStats
	local current = ctx.current or 0
	local key = tostring(ctx.factionID or ctx.name or "") .. ":" .. tostring(ctx.standingText or ctx.standingID or "") .. ":" .. tostring(ctx.max or 0)

	if stats.key ~= key or current < (stats.lastValue or 0) then
		stats.key = key
		stats.startTime = now
		stats.startValue = current
	end

	if not stats.startTime then stats.startTime = now end
	if stats.startValue == nil then stats.startValue = current end
	stats.lastValue = current

	local elapsed = math.max(0, now - (stats.startTime or now))
	local gained = math.max(0, current - (stats.startValue or current))
	local rate = 0
	if elapsed > 1 and gained > 0 then rate = (gained / elapsed) * 3600 end

	ctx.sessionSeconds = elapsed
	ctx.sessionGained = gained
	ctx.reputationPerHour = rate
	if rate > 0 and (ctx.remaining or 0) > 0 then
		ctx.etaNextSeconds = ((ctx.remaining or 0) / rate) * 3600
	else
		ctx.etaNextSeconds = nil
	end
	return ctx
end

local function formatReputationText(mode, ctx, abbreviateNumbers)
	if not ctx then return nil end
	if mode == "NONE" then return nil end
	if mode == "FACTION" then return ctx.name end
	if mode == "STANDING" then return ctx.standingText end
	if mode == "CURMAX" then return formatNumber(ctx.current, abbreviateNumbers) .. " / " .. formatNumber(ctx.max, abbreviateNumbers) end
	if mode == "CURMAX_NEEDED" then
		return string.format("%s / %s (%s)", formatNumber(ctx.current, abbreviateNumbers), formatNumber(ctx.max, abbreviateNumbers), formatNumber(ctx.remaining or 0, abbreviateNumbers))
	end
	if mode == "PERCENT" then return string.format("%.1f%%", ctx.currentPercent or 0) end
	if mode == "CURMAXPERCENT" then return string.format("%s / %s (%.1f%%)", formatNumber(ctx.current, abbreviateNumbers), formatNumber(ctx.max, abbreviateNumbers), ctx.currentPercent or 0) end
	if mode == "RATE_PER_HOUR" then
		if (ctx.reputationPerHour or 0) <= 0 then return nil end
		return string.format("%s: %s", L["Reputation/hour"] or "Reputation/hour", formatRateNumber(ctx.reputationPerHour, abbreviateNumbers))
	end
	if mode == "ETA_NEXT" then
		if not ctx.etaNextSeconds then return nil end
		return string.format("%s: %s", L["repBarETA"] or "Standing in", formatDurationShort(ctx.etaNextSeconds))
	end
	if mode == "ETA_NEXT_RATE" then
		if not ctx.etaNextSeconds or (ctx.reputationPerHour or 0) <= 0 then return nil end
		return string.format(
			"%s: %s (%s %s)",
			L["repBarETA"] or "Standing in",
			formatDurationShort(ctx.etaNextSeconds),
			formatRateNumber(ctx.reputationPerHour, abbreviateNumbers),
			L["Reputation/hour"] or "Reputation/hour"
		)
	end
	return nil
end

function ReputationBar:IsEnabled() return addon.db and addon.db[DB_ENABLED] == true end

function ReputationBar:GetWidth() return clamp(getValue(DB_WIDTH, defaults.width), BAR_SIZE_MIN, BAR_WIDTH_MAX) end

function ReputationBar:GetHeight() return clamp(getValue(DB_HEIGHT, defaults.height), BAR_SIZE_MIN, BAR_SIZE_MAX) end

function ReputationBar:GetTextureKey()
	local key = getValue(DB_TEXTURE, defaults.texture)
	if not key or key == "" then key = defaults.texture end
	return key
end

function ReputationBar:GetColor() return normalizeColor(getValue(DB_COLOR, defaults.color), defaults.color) end

function ReputationBar:GetUseStandingColor() return getValue(DB_USE_STANDING_COLOR, defaults.useStandingColor) == true end

function ReputationBar:GetBackgroundEnabled() return getValue(DB_BG_ENABLED, defaults.bgEnabled) == true end

function ReputationBar:GetBackgroundTextureKey()
	local key = getValue(DB_BG_TEXTURE, defaults.bgTexture)
	if not key or key == "" then key = defaults.bgTexture end
	return key
end

function ReputationBar:GetBackgroundColor() return normalizeColor(getValue(DB_BG_COLOR, defaults.bgColor), defaults.bgColor) end

function ReputationBar:GetBorderEnabled() return getValue(DB_BORDER_ENABLED, defaults.borderEnabled) == true end

function ReputationBar:GetBorderTextureKey()
	local key = getValue(DB_BORDER_TEXTURE, defaults.borderTexture)
	if not key or key == "" then key = defaults.borderTexture end
	return key
end

function ReputationBar:GetBorderColor() return normalizeColor(getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor) end

function ReputationBar:GetBorderSize() return clamp(getValue(DB_BORDER_SIZE, defaults.borderSize), 1, 20) end

function ReputationBar:GetBorderOffset() return clamp(getValue(DB_BORDER_OFFSET, defaults.borderOffset), -20, 20) end

function ReputationBar:GetFillDirection() return normalizeFillDirection(getValue(DB_FILL_DIRECTION, defaults.fillDirection)) end

function ReputationBar:GetAnchorRelativeFrame()
	local target = getValue(DB_ANCHOR_RELATIVE_FRAME, defaults.anchorRelativeFrame or ANCHOR_TARGET_UI)
	return normalizeAnchorRelativeFrame(target)
end

function ReputationBar:GetAnchorMatchWidth() return getValue(DB_ANCHOR_MATCH_WIDTH, defaults.anchorMatchRelativeWidth == true) == true end

function ReputationBar:GetAnchorMatchWidthOffset() return clamp(getValue(DB_ANCHOR_MATCH_WIDTH_OFFSET, defaults.anchorMatchRelativeWidthOffset or 0), -200, 200) end

function ReputationBar:GetAnchorPoint() return normalizeAnchorPoint(getValue(DB_ANCHOR_POINT, defaults.anchorPoint), defaults.anchorPoint) end

function ReputationBar:GetAnchorRelativePoint()
	local point = normalizeAnchorPoint(getValue(DB_ANCHOR_RELATIVE_POINT, defaults.anchorRelativePoint), self:GetAnchorPoint())
	return point
end

function ReputationBar:GetAnchorOffsetX() return normalizeAnchorOffset(getValue(DB_ANCHOR_OFFSET_X, defaults.anchorOffsetX), defaults.anchorOffsetX) end

function ReputationBar:GetAnchorOffsetY() return normalizeAnchorOffset(getValue(DB_ANCHOR_OFFSET_Y, defaults.anchorOffsetY), defaults.anchorOffsetY) end

function ReputationBar:GetTextEnabled() return getValue(DB_TEXT_ENABLED, defaults.textEnabled) == true end

function ReputationBar:GetTextSize() return clamp(getValue(DB_TEXT_SIZE, defaults.textSize), TEXT_SIZE_MIN, TEXT_SIZE_MAX) end

function ReputationBar:GetTextFont()
	local key = getValue(DB_TEXT_FONT, defaults.textFont)
	if not key or key == "" then key = defaults.textFont or "DEFAULT" end
	return key
end

function ReputationBar:GetTextOutline() return normalizeTextOutline(getValue(DB_TEXT_OUTLINE, defaults.textOutline)) end

function ReputationBar:GetTextColor() return normalizeColor(getValue(DB_TEXT_COLOR, defaults.textColor), defaults.textColor) end

function ReputationBar:GetAbbreviateNumbers() return getValue(DB_TEXT_ABBREVIATE_NUMBERS, defaults.abbreviateNumbers) == true end

function ReputationBar:GetTextLeftMode() return normalizeTextContentMode(getValue(DB_TEXT_LEFT_MODE, defaults.textLeftMode or "FACTION")) end

function ReputationBar:GetTextCenterMode()
	local value = getValue(DB_TEXT_CENTER_MODE, nil)
	if value == nil then value = getValue(DB_TEXT_MODE, defaults.textCenterMode or defaults.textMode or "CURMAXPERCENT") end
	return normalizeTextContentMode(value)
end

function ReputationBar:GetTextRightMode() return normalizeTextContentMode(getValue(DB_TEXT_RIGHT_MODE, defaults.textRightMode or "STANDING")) end

function ReputationBar:GetTextLeftOffsetX() return normalizeTextOffset(getValue(DB_TEXT_LEFT_OFFSET_X, defaults.textLeftOffsetX), defaults.textLeftOffsetX) end

function ReputationBar:GetTextLeftOffsetY() return normalizeTextOffset(getValue(DB_TEXT_LEFT_OFFSET_Y, defaults.textLeftOffsetY), defaults.textLeftOffsetY) end

function ReputationBar:GetTextCenterOffsetX() return normalizeTextOffset(getValue(DB_TEXT_CENTER_OFFSET_X, defaults.textCenterOffsetX), defaults.textCenterOffsetX) end

function ReputationBar:GetTextCenterOffsetY() return normalizeTextOffset(getValue(DB_TEXT_CENTER_OFFSET_Y, defaults.textCenterOffsetY), defaults.textCenterOffsetY) end

function ReputationBar:GetTextRightOffsetX() return normalizeTextOffset(getValue(DB_TEXT_RIGHT_OFFSET_X, defaults.textRightOffsetX), defaults.textRightOffsetX) end

function ReputationBar:GetTextRightOffsetY() return normalizeTextOffset(getValue(DB_TEXT_RIGHT_OFFSET_Y, defaults.textRightOffsetY), defaults.textRightOffsetY) end

function ReputationBar:GetHideInPetBattle() return shouldHideInPetBattleForRep() end

function ReputationBar:GetHideBlizzardTracking() return getValue(DB_HIDE_BLIZZARD_TRACKING, defaults.hideBlizzardTracking) == true end

function ReputationBar:AnchorUsesUIParent() return self:GetAnchorRelativeFrame() == ANCHOR_TARGET_UI end

function ReputationBar:AnchorUsesMatchedWidth() return self:GetAnchorMatchWidth() and not self:AnchorUsesUIParent() end

local function anchorDefaultsFor(target)
	if target == ANCHOR_TARGET_UI then
		local point = defaults.anchorPoint or "CENTER"
		local relPoint = defaults.anchorRelativePoint or point
		return point, relPoint, defaults.anchorOffsetX or 0, defaults.anchorOffsetY or 0
	end
	return "TOPLEFT", "BOTTOMLEFT", 0, -2
end

function ReputationBar:ResolveAnchorFrame()
	local target = self:GetAnchorRelativeFrame()
	self._anchorUsingCustom = nil
	self._anchorWantsCustom = nil

	if target == ANCHOR_TARGET_UI then return UIParent end

	if target == ANCHOR_TARGET_PLAYER_CASTBAR then
		local frame, usingCustom, wantsCustom = resolvePlayerCastbarFrame()
		self._anchorUsingCustom = usingCustom
		self._anchorWantsCustom = wantsCustom
		if wantsCustom and not usingCustom then self:ScheduleAnchorRefresh(target) end
		return frame or UIParent
	end

	local frame = _G and _G[target]
	if frame then return frame end
	self:ScheduleAnchorRefresh(target)
	return UIParent
end

function ReputationBar:ScheduleAnchorRefresh(target)
	if not (C_Timer and C_Timer.NewTicker) then return end
	local desired = normalizeAnchorRelativeFrame(target or self:GetAnchorRelativeFrame())
	if desired == ANCHOR_TARGET_UI then return end

	if self._anchorRefreshTicker then
		if self._anchorRefreshTarget == desired then return end
		self._anchorRefreshTicker:Cancel()
		self._anchorRefreshTicker = nil
	end

	self._anchorRefreshTarget = desired
	local tries = 0
	self._anchorRefreshTicker = C_Timer.NewTicker(0.2, function()
		tries = tries + 1
		if self:GetAnchorRelativeFrame() ~= desired then
			if self._anchorRefreshTicker then self._anchorRefreshTicker:Cancel() end
			self._anchorRefreshTicker = nil
			self._anchorRefreshTarget = nil
			return
		end

		if desired == ANCHOR_TARGET_PLAYER_CASTBAR then
			local frame, usingCustom, wantsCustom = resolvePlayerCastbarFrame()
			if frame and (not wantsCustom or usingCustom) then
				if self._anchorRefreshTicker then self._anchorRefreshTicker:Cancel() end
				self._anchorRefreshTicker = nil
				self._anchorRefreshTarget = nil
				self:RefreshAnchor()
				return
			end
		elseif _G and _G[desired] then
			if self._anchorRefreshTicker then self._anchorRefreshTicker:Cancel() end
			self._anchorRefreshTicker = nil
			self._anchorRefreshTarget = nil
			self:RefreshAnchor()
			return
		end

		if tries >= 25 then
			if self._anchorRefreshTicker then self._anchorRefreshTicker:Cancel() end
			self._anchorRefreshTicker = nil
			self._anchorRefreshTarget = nil
		end
	end)
end

function ReputationBar:RefreshAnchor()
	if self._refreshingAnchor then return end
	local target = self:GetAnchorRelativeFrame()
	if self._anchorRefreshTicker and (target == ANCHOR_TARGET_UI or self._anchorRefreshTarget ~= target) then
		self._anchorRefreshTicker:Cancel()
		self._anchorRefreshTicker = nil
		self._anchorRefreshTarget = nil
	end
	self._refreshingAnchor = true
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
	self._refreshingAnchor = nil
	if target == ANCHOR_TARGET_PLAYER_CASTBAR then
		if isCustomPlayerCastbarEnabled() and not (_G and _G[EQOL_PLAYER_CASTBAR]) then self:ScheduleAnchorRefresh(target) end
	elseif target ~= ANCHOR_TARGET_UI then
		if not (_G and _G[target]) then self:ScheduleAnchorRefresh(target) end
	end
end

function ReputationBar:MaybeUpdateAnchor()
	local target = self:GetAnchorRelativeFrame()
	if target == ANCHOR_TARGET_PLAYER_CASTBAR then
		if isCustomPlayerCastbarEnabled() then
			if _G and _G[EQOL_PLAYER_CASTBAR] and not self._anchorUsingCustom then
				self:RefreshAnchor()
			elseif not (_G and _G[EQOL_PLAYER_CASTBAR]) then
				self:ScheduleAnchorRefresh(target)
			end
		elseif self._anchorUsingCustom then
			self:RefreshAnchor()
		end
	elseif target ~= ANCHOR_TARGET_UI then
		if not (_G and _G[target]) then self:ScheduleAnchorRefresh(target) end
	end
end

local widthMatchHookedFrames = {}
local pendingWidthHookRetries = {}
local widthSyncQueued = false

function ReputationBar:ScheduleMatchedWidthSync()
	if widthSyncQueued then return end
	widthSyncQueued = true
	RunNextFrame(function()
		widthSyncQueued = false
		if not (addon and addon.db and addon.db[DB_ENABLED] == true) then return end
		ReputationBar:ApplySize()
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
	end)
end

function ReputationBar:EnsureWidthSyncHook(frameName)
	if not frameName or frameName == "" or frameName == ANCHOR_TARGET_UI or frameName == "EQOL_RepBar" then return end
	if widthMatchHookedFrames[frameName] then return end
	local frame = _G and _G[frameName]
	if not frame then
		if C_Timer and C_Timer.After and not pendingWidthHookRetries[frameName] then
			pendingWidthHookRetries[frameName] = true
			C_Timer.After(1, function()
				pendingWidthHookRetries[frameName] = nil
				if ReputationBar and ReputationBar.EnsureWidthSyncHook then ReputationBar:EnsureWidthSyncHook(frameName) end
			end)
		end
		return
	end

	if frame.HookScript then
		local function onGeometryChanged()
			if ReputationBar and ReputationBar.AnchorUsesMatchedWidth and ReputationBar:AnchorUsesMatchedWidth() then ReputationBar:ScheduleMatchedWidthSync() end
		end
		local okSize = pcall(frame.HookScript, frame, "OnSizeChanged", onGeometryChanged)
		local okShow = pcall(frame.HookScript, frame, "OnShow", onGeometryChanged)
		local okHide = pcall(frame.HookScript, frame, "OnHide", onGeometryChanged)
		if okSize or okShow or okHide then widthMatchHookedFrames[frameName] = true end
	end
end

function ReputationBar:EnsureWidthSyncHooks()
	if not self:AnchorUsesMatchedWidth() then return end
	local target = self:GetAnchorRelativeFrame()
	if target == ANCHOR_TARGET_PLAYER_CASTBAR then
		self:EnsureWidthSyncHook("PlayerCastingBarFrame")
		self:EnsureWidthSyncHook(EQOL_PLAYER_CASTBAR)
	elseif target ~= ANCHOR_TARGET_UI then
		self:EnsureWidthSyncHook(target)
	end
end

function ReputationBar:GetResolvedWidth()
	local width = self:GetWidth()
	if not self:AnchorUsesMatchedWidth() then return width end
	local relativeFrame = self:ResolveAnchorFrame()
	if not (relativeFrame and relativeFrame.GetWidth) then return width end
	local relativeWidth = tonumber(relativeFrame:GetWidth()) or 0
	if relativeWidth <= 0 then return width end
	return math.max(BAR_SIZE_MIN, relativeWidth + self:GetAnchorMatchWidthOffset())
end

function ReputationBar:ApplyCurrentFillColor(ctx)
	if not self.frame then return end
	local r, g, b, a
	if self:GetUseStandingColor() and ctx and ctx.colorStandingID and _G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[ctx.colorStandingID] then
		local color = _G.FACTION_BAR_COLORS[ctx.colorStandingID]
		r, g, b, a = color.r, color.g, color.b, 1
	end
	if not r then
		r, g, b, a = self:GetColor()
	end
	self.frame:SetStatusBarColor(r, g, b, a or 1)
	local tex = self.frame.GetStatusBarTexture and self.frame:GetStatusBarTexture()
	if tex and tex.Show then tex:Show() end
end

function ReputationBar:ApplyTextAnchors()
	if not self.frame then return end
	if self.frame.textLeft then
		self.frame.textLeft:ClearAllPoints()
		self.frame.textLeft:SetPoint("LEFT", self.frame, "LEFT", self:GetTextLeftOffsetX(), self:GetTextLeftOffsetY())
	end
	if self.frame.textCenter then
		self.frame.textCenter:ClearAllPoints()
		self.frame.textCenter:SetPoint("CENTER", self.frame, "CENTER", self:GetTextCenterOffsetX(), self:GetTextCenterOffsetY())
	end
	if self.frame.textRight then
		self.frame.textRight:ClearAllPoints()
		self.frame.textRight:SetPoint("RIGHT", self.frame, "RIGHT", self:GetTextRightOffsetX(), self:GetTextRightOffsetY())
	end
end

function ReputationBar:ApplyAppearance()
	if not self.frame then return end
	local texture = resolveTexture(self:GetTextureKey())
	self.frame:SetStatusBarTexture(texture)
	self:ApplyCurrentFillColor(self._lastReputationContext)

	local fillDirection = self:GetFillDirection()
	if self.frame.SetOrientation then self.frame:SetOrientation(isVerticalFillDirection(fillDirection) and "VERTICAL" or "HORIZONTAL") end
	if self.frame.SetReverseFill then self.frame:SetReverseFill(isReverseFillDirection(fillDirection)) end

	if self.frame.bg then
		if self:GetBackgroundEnabled() then
			local bgTex = resolveTexture(self:GetBackgroundTextureKey())
			self.frame.bg:SetTexture(bgTex)
			local br, bg, bb, ba = self:GetBackgroundColor()
			local alpha = (ba == nil) and 1 or ba
			self.frame.bg:SetVertexColor(br or 0, bg or 0, bb or 0, alpha)
			self.frame.bg:Hide()
			if alpha > 0 then self.frame.bg:Show() end
		else
			self.frame.bg:Hide()
		end
	end

	if self.frame.border then
		if not self:GetBorderEnabled() then
			self.frame.border:SetBackdrop(nil)
			self.frame.border:Hide()
		else
			local size = self:GetBorderSize()
			local offset = self:GetBorderOffset()
			local borderTex = resolveBorderTexture(self:GetBorderTextureKey())
			self.frame.border:SetBackdrop({
				edgeFile = borderTex,
				edgeSize = size,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			local br, bg, bb, ba = self:GetBorderColor()
			self.frame.border:SetBackdropBorderColor(br or 0, bg or 0, bb or 0, ba or 1)
			self.frame.border:SetBackdropColor(0, 0, 0, 0)
			self.frame.border:ClearAllPoints()
			self.frame.border:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -offset, offset)
			self.frame.border:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", offset, -offset)
			self.frame.border:Show()
		end
	end

	local font = resolveFontPath(self:GetTextFont())
	local outlineChoice = self:GetTextOutline()
	local outline = resolveTextOutlineFlags(outlineChoice, defaults.textOutline or "OUTLINE")
	local size = self:GetTextSize()
	local tr, tg, tb, ta = self:GetTextColor()
	for _, key in ipairs({ "textLeft", "textCenter", "textRight" }) do
		local fs = self.frame[key]
		if fs then
			setFontWithFallback(fs, font, size, outline)
			if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fs, outlineChoice, defaults.textOutline or "OUTLINE") end
			fs:SetTextColor(tr or 1, tg or 1, tb or 1, ta or 1)
		end
	end
	if self.frame.editLabel then
		setFontWithFallback(self.frame.editLabel, font, math.max(size, 11), outline)
		if addon.functions and addon.functions.ApplyFontStyleShadow then
			addon.functions.ApplyFontStyleShadow(self.frame.editLabel, outlineChoice, defaults.textOutline or "OUTLINE")
		end
		self.frame.editLabel:SetTextColor(1, 0.9, 0.2, 1)
	end

	self:ApplyTextAnchors()
	self:ApplyCurrentFillColor(self._lastReputationContext)
end

function ReputationBar:ApplySize()
	if not self.frame then return end
	self:EnsureWidthSyncHooks()
	local width = self:GetResolvedWidth()
	local height = self:GetHeight()
	self.frame:SetSize(width, height)
	if self.frame.bg then self.frame.bg:SetAllPoints(self.frame) end
	if self.frame.editBg then self.frame.editBg:SetAllPoints(self.frame) end
	if self.frame.border then self.frame.border:SetAllPoints(self.frame) end
	self:ApplyTextAnchors()
	self:ApplyCurrentFillColor(self._lastReputationContext)
end

function ReputationBar:EnsureFrame()
	if self.frame then
		if self.frame.GetParent and self.frame:GetParent() ~= UIParent then self.frame:SetParent(UIParent) end
		self:RegisterVisibilityFrame()
		return self.frame
	end

	local existing = _G and _G[REP_BAR_FRAME_NAME]
	if existing then
		self.frame = existing
		if existing.GetParent and existing:GetParent() ~= UIParent then existing:SetParent(UIParent) end
		self:ApplyAppearance()
		self:ApplySize()
		self:RegisterEditMode(existing)
		registerEditModeCallbacks()
		self:RegisterVisibilityFrame()
		return existing
	end

	local bar = CreateFrame("StatusBar", REP_BAR_FRAME_NAME, UIParent)
	bar:SetMinMaxValues(0, 1)
	bar:SetClampedToScreen(true)
	bar:Hide()

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(bar)
	bar.bg = bg

	local editBg = bar:CreateTexture(nil, "BORDER")
	editBg:SetAllPoints(bar)
	editBg:SetColorTexture(0.1, 0.6, 0.6, 0.2)
	editBg:Hide()
	bar.editBg = editBg

	local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	border:SetAllPoints(bar)
	border:SetFrameLevel((bar:GetFrameLevel() or 0) + 2)
	border:Hide()
	bar.border = border

	local textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0)
	textLeft:SetJustifyH("LEFT")
	textLeft:Hide()
	bar.textLeft = textLeft

	local textCenter = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	textCenter:SetPoint("CENTER", bar, "CENTER", 0, 0)
	textCenter:SetJustifyH("CENTER")
	textCenter:Hide()
	bar.textCenter = textCenter

	local textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
	textRight:SetJustifyH("RIGHT")
	textRight:Hide()
	bar.textRight = textRight

	local editLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	editLabel:SetPoint("BOTTOM", bar, "TOP", 0, 4)
	editLabel:SetText(L["ReputationBar"] or "Reputation Bar")
	editLabel:Hide()
	bar.editLabel = editLabel

	bar:HookScript("OnShow", function()
		if ReputationBar and ReputationBar.previewing then return end
		if ReputationBar and ReputationBar.UpdateSoon then ReputationBar:UpdateSoon() end
	end)

	self.frame = bar
	self:ApplyAppearance()
	self:ApplySize()
	self:RegisterEditMode(bar)
	registerEditModeCallbacks()
	self:RegisterVisibilityFrame()

	return bar
end

function ReputationBar:EnsureEventFrame()
	if self.eventFrame then return self.eventFrame end
	local frame = _G and _G[REP_BAR_EVENT_FRAME_NAME]
	if not frame then frame = CreateFrame("Frame", REP_BAR_EVENT_FRAME_NAME, UIParent) end
	frame:Hide()
	self.eventFrame = frame
	return frame
end

function ReputationBar:DespawnFrame()
	if not self.frame then return end
	self.frame:Hide()
	if self.frame.editBg then self.frame.editBg:Hide() end
	if self.frame.editLabel then self.frame.editLabel:Hide() end
	self._lastReputationContext = nil
	self._lastFraction = nil
	self._reputationStats = nil
end

function ReputationBar:StopBootstrapRefresh()
	if self._bootstrapTicker then
		self._bootstrapTicker:Cancel()
		self._bootstrapTicker = nil
	end
	self._bootstrapTries = nil
end

function ReputationBar:StartBootstrapRefresh()
	if not self:IsEnabled() then return end
	if not (C_Timer and C_Timer.NewTicker) then
		self:UpdateReputation()
		return
	end
	if self._bootstrapTicker then return end
	self._bootstrapTries = 0
	self._bootstrapTicker = C_Timer.NewTicker(0.25, function()
		if not (ReputationBar and ReputationBar.IsEnabled and ReputationBar:IsEnabled()) then
			if ReputationBar and ReputationBar.StopBootstrapRefresh then ReputationBar:StopBootstrapRefresh() end
			return
		end
		ReputationBar._bootstrapTries = (ReputationBar._bootstrapTries or 0) + 1
		ReputationBar:UpdateReputation()
		local ctx = getWatchedFactionContext()
		if ctx or (ReputationBar._bootstrapTries or 0) >= 32 then ReputationBar:StopBootstrapRefresh() end
	end)
end

function ReputationBar:WantsBlizzardTrackingHidden()
	if not self:IsEnabled() then return false end
	if self.previewing then return false end
	if not self:GetHideBlizzardTracking() then return false end
	return true
end

function ReputationBar:ApplyBlizzardTrackingVisibility()
	local hide = self:WantsBlizzardTrackingHidden()
	local rb = addon.Aura and addon.Aura.ResourceBars
	if rb and rb.SetBlizzardTrackingKilled then rb.SetBlizzardTrackingKilled("repBar", hide) end
end

function ReputationBar:UpdateTextFromContext(ctx)
	if not self.frame then return end

	if self.frame.editLabel then
		if self.previewing then
			self.frame.editLabel:SetText(L["ReputationBar"] or "Reputation Bar")
			self.frame.editLabel:Show()
		else
			self.frame.editLabel:Hide()
		end
	end

	if not self:GetTextEnabled() then
		if self.frame.textLeft then self.frame.textLeft:Hide() end
		if self.frame.textCenter then self.frame.textCenter:Hide() end
		if self.frame.textRight then self.frame.textRight:Hide() end
		return
	end

	local abbreviateNumbers = self:GetAbbreviateNumbers()
	local leftText = formatReputationText(self:GetTextLeftMode(), ctx, abbreviateNumbers)
	local centerText = formatReputationText(self:GetTextCenterMode(), ctx, abbreviateNumbers)
	local rightText = formatReputationText(self:GetTextRightMode(), ctx, abbreviateNumbers)

	local function setText(fs, text)
		if not fs then return end
		if text and text ~= "" then
			fs:SetText(text)
			fs:Show()
		else
			fs:Hide()
		end
	end

	setText(self.frame.textLeft, leftText)
	setText(self.frame.textCenter, centerText)
	setText(self.frame.textRight, rightText)
end

function ReputationBar:UpdateReputation()
	if self.previewing then return end

	if shouldHideInPetBattleForRep() and isPetBattleActive() then
		if self.frame then self.frame:Hide() end
		self:ApplyVisibilityPreference(false)
		self:ApplyBlizzardTrackingVisibility()
		return
	end

	self:MaybeUpdateAnchor()
	local ctx = getWatchedFactionContext()
	if not ctx or (ctx.max or 0) <= 0 then
		self:DespawnFrame()
		self:ApplyVisibilityPreference(false)
		self:ApplyBlizzardTrackingVisibility()
		if not self.frame then self:StartBootstrapRefresh() end
		return
	end

	self:StopBootstrapRefresh()
	local frame = self:EnsureFrame()
	if not frame then return end

	self:EnrichReputationContext(ctx)
	self._lastReputationContext = ctx
	local fraction = 0
	if ctx.max > 0 then
		fraction = ctx.current / ctx.max
		if fraction < 0 then
			fraction = 0
		elseif fraction > 1 then
			fraction = 1
		end
	end
	self._lastFraction = fraction

	frame:SetMinMaxValues(0, 1)
	frame:SetValue(fraction)
	self:ApplyCurrentFillColor(ctx)
	self:UpdateTextFromContext(ctx)
	frame:Show()
	self:ApplyVisibilityPreference(true)
	self:ApplyBlizzardTrackingVisibility()
end

function ReputationBar:UpdateSoon()
	if not self:IsEnabled() then return end
	self:StartBootstrapRefresh()
	RunNextFrame(function()
		if ReputationBar and ReputationBar.IsEnabled and ReputationBar:IsEnabled() then ReputationBar:UpdateReputation() end
	end)
	if not (C_Timer and C_Timer.After) then return end
	C_Timer.After(0.2, function()
		if ReputationBar and ReputationBar.IsEnabled and ReputationBar:IsEnabled() then ReputationBar:UpdateReputation() end
	end)
	C_Timer.After(1.0, function()
		if ReputationBar and ReputationBar.IsEnabled and ReputationBar:IsEnabled() then ReputationBar:UpdateReputation() end
	end)
end

function ReputationBar:ShowEditModeHint(show)
	local frame = self:EnsureFrame()
	if not frame then return end
	if show then
		if frame.editBg then frame.editBg:Show() end
		self.previewing = true
		self:UpdatePreviewSample()
	else
		if frame.editBg then frame.editBg:Hide() end
		self.previewing = nil
		self:UpdateReputation()
		self:UpdateSoon()
	end
end

function ReputationBar:RegisterEvents()
	if self.eventsRegistered then return end
	local frame = self:EnsureEventFrame()
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("UPDATE_FACTION")
	frame:RegisterEvent("PET_BATTLE_OPENING_START")
	frame:RegisterEvent("PET_BATTLE_CLOSE")
	frame:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
			ReputationBar:UpdateSoon()
		end
		ReputationBar:UpdateReputation()
	end)
	self.eventsRegistered = true
end

function ReputationBar:UnregisterEvents()
	if not self.eventsRegistered or not self.eventFrame then return end
	self.eventFrame:UnregisterEvent("PLAYER_LOGIN")
	self.eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.eventFrame:UnregisterEvent("UPDATE_FACTION")
	self.eventFrame:UnregisterEvent("PET_BATTLE_OPENING_START")
	self.eventFrame:UnregisterEvent("PET_BATTLE_CLOSE")
	self.eventFrame:SetScript("OnEvent", nil)
	self.eventsRegistered = false
end

local editModeRegistered = false
local editModeCallbacksRegistered = false

function ReputationBar:BuildLayoutRecordFromProfile()
	local record = {}
	record.point = self:GetAnchorPoint()
	record.relativePoint = self:GetAnchorRelativePoint()
	record.x = self:GetAnchorOffsetX()
	record.y = self:GetAnchorOffsetY()
	record.width = self:GetWidth()
	record.height = self:GetHeight()
	record.texture = self:GetTextureKey()
	record.bgEnabled = self:GetBackgroundEnabled()
	record.bgTexture = self:GetBackgroundTextureKey()
	do
		local r, g, b, a = self:GetBackgroundColor()
		record.bgColor = { r = r, g = g, b = b, a = a }
	end
	record.borderEnabled = self:GetBorderEnabled()
	record.borderTexture = self:GetBorderTextureKey()
	do
		local r, g, b, a = self:GetBorderColor()
		record.borderColor = { r = r, g = g, b = b, a = a }
	end
	record.borderSize = self:GetBorderSize()
	record.borderOffset = self:GetBorderOffset()
	record.fillDirection = self:GetFillDirection()
	record.anchorRelativeFrame = self:GetAnchorRelativeFrame()
	record.anchorMatchWidth = self:GetAnchorMatchWidth()
	record.anchorMatchWidthOffset = self:GetAnchorMatchWidthOffset()
	record.textEnabled = self:GetTextEnabled()
	record.textLeftMode = self:GetTextLeftMode()
	record.textCenterMode = self:GetTextCenterMode()
	record.textRightMode = self:GetTextRightMode()
	record.textLeftOffsetX = self:GetTextLeftOffsetX()
	record.textLeftOffsetY = self:GetTextLeftOffsetY()
	record.textCenterOffsetX = self:GetTextCenterOffsetX()
	record.textCenterOffsetY = self:GetTextCenterOffsetY()
	record.textRightOffsetX = self:GetTextRightOffsetX()
	record.textRightOffsetY = self:GetTextRightOffsetY()
	record.textMode = normalizeLegacyTextMode(record.textCenterMode)
	record.textSize = self:GetTextSize()
	record.textFont = self:GetTextFont()
	record.textOutline = self:GetTextOutline()
	record.abbreviateNumbers = self:GetAbbreviateNumbers()
	record.hideInPetBattle = self:GetHideInPetBattle()
	record.hideBlizzardTracking = self:GetHideBlizzardTracking()
	record.useStandingColor = self:GetUseStandingColor()
	do
		local r, g, b, a = self:GetColor()
		record.color = { r = r, g = g, b = b, a = a }
	end
	do
		local r, g, b, a = self:GetTextColor()
		record.textColor = { r = r, g = g, b = b, a = a }
	end
	return record
end

registerEditModeCallbacks = function()
	if editModeCallbacksRegistered then return end
	local lib = addon.EditModeLib
	if not (lib and lib.RegisterCallback) then return end

	lib:RegisterCallback("exit", function()
		if not (ReputationBar and ReputationBar.IsEnabled and ReputationBar:IsEnabled()) then return end
		ReputationBar.previewing = nil
		if ReputationBar.frame then
			if ReputationBar.frame.editBg then ReputationBar.frame.editBg:Hide() end
			if ReputationBar.frame.editLabel then ReputationBar.frame.editLabel:Hide() end
		end
		ReputationBar:ApplySize()
		ReputationBar:ApplyAppearance()
		ReputationBar:UpdateSoon()
	end)

	editModeCallbacksRegistered = true
end

function ReputationBar:ApplyLayoutData(data)
	if not data or not addon.db then return end

	local width = clamp(data.width or defaults.width, BAR_SIZE_MIN, BAR_WIDTH_MAX)
	local height = clamp(data.height or defaults.height, BAR_SIZE_MIN, BAR_SIZE_MAX)
	local texture = data.texture or defaults.texture
	local r, g, b, a = normalizeColor(data.color or defaults.color, defaults.color)
	local useStandingColor = data.useStandingColor
	if useStandingColor == nil then useStandingColor = addon.db.repBarUseStandingColor end
	if useStandingColor == nil then useStandingColor = defaults.useStandingColor end
	local bgEnabled = data.bgEnabled == true
	local bgTexture = data.bgTexture or defaults.bgTexture
	local bgr, bgg, bgb, bga = normalizeColor(data.bgColor or defaults.bgColor, defaults.bgColor)
	local borderEnabled = data.borderEnabled == true
	local borderTexture = data.borderTexture or defaults.borderTexture
	local bdr, bdg, bdb, bda = normalizeColor(data.borderColor or defaults.borderColor, defaults.borderColor)
	local borderSize = clamp(data.borderSize or defaults.borderSize, 1, 20)
	local borderOffset = clamp(data.borderOffset or defaults.borderOffset, -20, 20)
	local fillDirection = normalizeFillDirection(data.fillDirection or defaults.fillDirection)
	local anchorRelativeFrame = normalizeAnchorRelativeFrame(data.anchorRelativeFrame or data.anchorTarget or addon.db.repBarAnchorTarget or defaults.anchorRelativeFrame)
	local anchorMatchWidth = addon.db.repBarAnchorMatchWidth == true
	if data.anchorMatchWidth ~= nil then
		anchorMatchWidth = data.anchorMatchWidth == true
	elseif data.anchorMatchRelativeWidth ~= nil then
		anchorMatchWidth = data.anchorMatchRelativeWidth == true
	end
	local anchorMatchWidthOffset = clamp(data.anchorMatchWidthOffset or data.anchorMatchRelativeWidthOffset or addon.db.repBarAnchorMatchWidthOffset or defaults.anchorMatchRelativeWidthOffset or 0, -200, 200)
	local anchorPoint = normalizeAnchorPoint(data.point or addon.db.repBarAnchorPoint, defaults.anchorPoint)
	local anchorRelativePoint = normalizeAnchorPoint(data.relativePoint or addon.db.repBarAnchorRelativePoint, anchorPoint)
	local anchorOffsetX = normalizeAnchorOffset(data.x ~= nil and data.x or addon.db.repBarAnchorOffsetX, defaults.anchorOffsetX)
	local anchorOffsetY = normalizeAnchorOffset(data.y ~= nil and data.y or addon.db.repBarAnchorOffsetY, defaults.anchorOffsetY)
	local textEnabled = addon.db.repBarShowText ~= false
	if data.textEnabled ~= nil then textEnabled = data.textEnabled == true end
	local textLeftMode = normalizeTextContentMode(data.textLeftMode or addon.db.repBarTextLeftMode or defaults.textLeftMode)
	local textCenterMode = normalizeTextContentMode(data.textCenterMode or data.textMode or addon.db.repBarTextCenterMode or addon.db.repBarTextMode or defaults.textCenterMode or defaults.textMode)
	local textRightMode = normalizeTextContentMode(data.textRightMode or addon.db.repBarTextRightMode or defaults.textRightMode)
	local textLeftOffsetX = normalizeTextOffset(data.textLeftOffsetX ~= nil and data.textLeftOffsetX or addon.db.repBarTextLeftOffsetX, defaults.textLeftOffsetX)
	local textLeftOffsetY = normalizeTextOffset(data.textLeftOffsetY ~= nil and data.textLeftOffsetY or addon.db.repBarTextLeftOffsetY, defaults.textLeftOffsetY)
	local textCenterOffsetX = normalizeTextOffset(data.textCenterOffsetX ~= nil and data.textCenterOffsetX or addon.db.repBarTextCenterOffsetX, defaults.textCenterOffsetX)
	local textCenterOffsetY = normalizeTextOffset(data.textCenterOffsetY ~= nil and data.textCenterOffsetY or addon.db.repBarTextCenterOffsetY, defaults.textCenterOffsetY)
	local textRightOffsetX = normalizeTextOffset(data.textRightOffsetX ~= nil and data.textRightOffsetX or addon.db.repBarTextRightOffsetX, defaults.textRightOffsetX)
	local textRightOffsetY = normalizeTextOffset(data.textRightOffsetY ~= nil and data.textRightOffsetY or addon.db.repBarTextRightOffsetY, defaults.textRightOffsetY)
	local textSize = clamp(data.textSize or addon.db.repBarTextSize or defaults.textSize, TEXT_SIZE_MIN, TEXT_SIZE_MAX)
	local textFont = data.textFont or addon.db.repBarTextFont or defaults.textFont or "DEFAULT"
	local textOutline = normalizeTextOutline(data.textOutline or addon.db.repBarTextOutline or defaults.textOutline)
	local textR, textG, textB, textA = normalizeColor(data.textColor or addon.db.repBarTextColor or defaults.textColor, defaults.textColor)
	local abbreviateNumbers = addon.db.repBarTextAbbreviateNumbers == true
	if data.abbreviateNumbers ~= nil then abbreviateNumbers = data.abbreviateNumbers == true end
	local hideInPetBattle = addon.db.repBarHideInPetBattle == true
	if data.hideInPetBattle ~= nil then hideInPetBattle = data.hideInPetBattle == true end
	local hideBlizzardTracking = addon.db.repBarHideBlizzardTracking == true
	if data.hideBlizzardTracking ~= nil then hideBlizzardTracking = data.hideBlizzardTracking == true end

	addon.db.repBarWidth = width
	addon.db.repBarHeight = height
	addon.db.repBarTexture = texture
	addon.db.repBarColor = { r = r, g = g, b = b, a = a }
	addon.db.repBarUseStandingColor = useStandingColor == true
	addon.db.repBarBackgroundEnabled = bgEnabled
	addon.db.repBarBackgroundTexture = bgTexture
	addon.db.repBarBackgroundColor = { r = bgr, g = bgg, b = bgb, a = bga }
	addon.db.repBarBorderEnabled = borderEnabled
	addon.db.repBarBorderTexture = borderTexture
	addon.db.repBarBorderColor = { r = bdr, g = bdg, b = bdb, a = bda }
	addon.db.repBarBorderSize = borderSize
	addon.db.repBarBorderOffset = borderOffset
	addon.db.repBarFillDirection = fillDirection
	local prevAnchorRelativeFrame = addon.db.repBarAnchorTarget
	addon.db.repBarAnchorTarget = anchorRelativeFrame
	addon.db.repBarAnchorMatchWidth = anchorMatchWidth and true or false
	addon.db.repBarAnchorMatchWidthOffset = anchorMatchWidthOffset
	addon.db.repBarAnchorPoint = anchorPoint
	addon.db.repBarAnchorRelativePoint = anchorRelativePoint
	addon.db.repBarAnchorOffsetX = anchorOffsetX
	addon.db.repBarAnchorOffsetY = anchorOffsetY
	addon.db.repBarShowText = textEnabled and true or false
	addon.db.repBarTextLeftMode = textLeftMode
	addon.db.repBarTextCenterMode = textCenterMode
	addon.db.repBarTextRightMode = textRightMode
	addon.db.repBarTextLeftOffsetX = textLeftOffsetX
	addon.db.repBarTextLeftOffsetY = textLeftOffsetY
	addon.db.repBarTextCenterOffsetX = textCenterOffsetX
	addon.db.repBarTextCenterOffsetY = textCenterOffsetY
	addon.db.repBarTextRightOffsetX = textRightOffsetX
	addon.db.repBarTextRightOffsetY = textRightOffsetY
	addon.db.repBarTextMode = normalizeLegacyTextMode(textCenterMode)
	addon.db.repBarTextSize = textSize
	addon.db.repBarTextFont = textFont
	addon.db.repBarTextOutline = textOutline
	addon.db.repBarTextColor = { r = textR, g = textG, b = textB, a = textA }
	addon.db.repBarTextAbbreviateNumbers = abbreviateNumbers and true or false
	addon.db.repBarHideInPetBattle = hideInPetBattle and true or false
	addon.db.repBarHideBlizzardTracking = hideBlizzardTracking and true or false

	self:ApplySize()
	self:ApplyAppearance()
	if prevAnchorRelativeFrame ~= anchorRelativeFrame then self:RefreshAnchor() end
	if self.previewing then
		self:UpdatePreviewSample()
	else
		self:UpdateSoon()
	end
end

local function syncEditModeRecordFromLayout(record)
	if not (EditMode and EditMode.EnsureLayoutData) then return end
	if type(record) ~= "table" then return end
	local data = EditMode:EnsureLayoutData(EDITMODE_ID)
	if type(data) ~= "table" then return end
	for key, value in pairs(record) do
		data[key] = value
	end
	if EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

function ReputationBar:ApplyStyleFromExperienceBar()
	local xpBar = addon.Aura and addon.Aura.ExperienceBar
	if not (xpBar and xpBar.BuildLayoutRecordFromProfile) then return false end
	local source = xpBar:BuildLayoutRecordFromProfile()
	if type(source) ~= "table" then return false end

	local record = self:BuildLayoutRecordFromProfile()
	for _, key in ipairs({
		"width",
		"height",
		"texture",
		"bgEnabled",
		"bgTexture",
		"bgColor",
		"borderEnabled",
		"borderTexture",
		"borderColor",
		"borderSize",
		"borderOffset",
		"fillDirection",
		"textEnabled",
		"textSize",
		"textFont",
		"textOutline",
		"textColor",
		"textLeftOffsetX",
		"textLeftOffsetY",
		"textCenterOffsetX",
		"textCenterOffsetY",
		"textRightOffsetX",
		"textRightOffsetY",
		"abbreviateNumbers",
		"hideInPetBattle",
		"hideBlizzardTracking",
	}) do
		if source[key] ~= nil then record[key] = source[key] end
	end
	if source.color ~= nil then
		record.color = source.color
		record.useStandingColor = false
	end
	self:ApplyLayoutData(record)
	syncEditModeRecordFromLayout(record)
	return true
end

local function applySetting(field, value)
	if not addon.db then return end
	local editField = field
	local skipEditValue

	if field == "width" then
		local width = clamp(value, BAR_SIZE_MIN, BAR_WIDTH_MAX)
		addon.db.repBarWidth = width
		value = width
	elseif field == "height" then
		local height = clamp(value, BAR_SIZE_MIN, BAR_SIZE_MAX)
		addon.db.repBarHeight = height
		value = height
	elseif field == "texture" then
		local tex = value or defaults.texture
		addon.db.repBarTexture = tex
		value = tex
	elseif field == "color" then
		local r, g, b, a = normalizeColor(value, defaults.color)
		addon.db.repBarColor = { r = r, g = g, b = b, a = a }
		value = addon.db.repBarColor
	elseif field == "useStandingColor" then
		local enabled = value == true
		addon.db.repBarUseStandingColor = enabled and true or false
		value = enabled
	elseif field == "bgEnabled" then
		local enabled = value == true
		addon.db.repBarBackgroundEnabled = enabled
		value = enabled
	elseif field == "bgTexture" then
		local tex = value or defaults.bgTexture
		addon.db.repBarBackgroundTexture = tex
		value = tex
	elseif field == "bgColor" then
		local r, g, b, a = normalizeColor(value, defaults.bgColor)
		addon.db.repBarBackgroundColor = { r = r, g = g, b = b, a = a }
		value = addon.db.repBarBackgroundColor
	elseif field == "borderEnabled" then
		local enabled = value == true
		addon.db.repBarBorderEnabled = enabled
		value = enabled
	elseif field == "borderTexture" then
		local tex = value or defaults.borderTexture
		addon.db.repBarBorderTexture = tex
		value = tex
	elseif field == "borderColor" then
		local r, g, b, a = normalizeColor(value, defaults.borderColor)
		addon.db.repBarBorderColor = { r = r, g = g, b = b, a = a }
		value = addon.db.repBarBorderColor
	elseif field == "borderSize" then
		local size = clamp(value, 1, 20)
		addon.db.repBarBorderSize = size
		value = size
	elseif field == "borderOffset" then
		local offset = clamp(value, -20, 20)
		addon.db.repBarBorderOffset = offset
		value = offset
	elseif field == "fillDirection" then
		local dir = normalizeFillDirection(value)
		addon.db.repBarFillDirection = dir
		value = dir
	elseif field == "anchorRelativeFrame" then
		local target = normalizeAnchorRelativeFrame(value)
		local prev = addon.db.repBarAnchorTarget
		addon.db.repBarAnchorTarget = target
		editField = "anchorRelativeFrame"
		if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, editField, target, nil, true) end
		if prev ~= target then
			local point, relPoint, x, y = anchorDefaultsFor(target)
			addon.db.repBarAnchorPoint = point
			addon.db.repBarAnchorRelativePoint = relPoint
			addon.db.repBarAnchorOffsetX = x
			addon.db.repBarAnchorOffsetY = y
			if EditMode and EditMode.SetValue then
				EditMode:SetValue(EDITMODE_ID, "point", point, nil, true)
				EditMode:SetValue(EDITMODE_ID, "relativePoint", relPoint, nil, true)
				EditMode:SetValue(EDITMODE_ID, "x", x, nil, true)
				EditMode:SetValue(EDITMODE_ID, "y", y, nil, true)
			end
			refreshSettingsUI()
		end
		value = target
		skipEditValue = true
	elseif field == "anchorMatchWidth" then
		local enabled = value == true
		addon.db.repBarAnchorMatchWidth = enabled and true or false
		value = enabled
		refreshSettingsUI()
	elseif field == "anchorMatchWidthOffset" then
		local offset = clamp(value, -200, 200)
		addon.db.repBarAnchorMatchWidthOffset = offset
		value = offset
	elseif field == "anchorPoint" then
		local point = normalizeAnchorPoint(value, defaults.anchorPoint)
		addon.db.repBarAnchorPoint = point
		editField = "point"
		value = point
		local rel = normalizeAnchorPoint(addon.db.repBarAnchorRelativePoint, point)
		if addon.db.repBarAnchorRelativePoint ~= rel then
			addon.db.repBarAnchorRelativePoint = rel
			if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "relativePoint", rel, nil, true) end
		end
	elseif field == "anchorRelativePoint" then
		local rel = normalizeAnchorPoint(value, defaults.anchorRelativePoint)
		addon.db.repBarAnchorRelativePoint = rel
		editField = "relativePoint"
		value = rel
	elseif field == "anchorOffsetX" then
		local offset = normalizeAnchorOffset(value, defaults.anchorOffsetX)
		addon.db.repBarAnchorOffsetX = offset
		editField = "x"
		value = offset
	elseif field == "anchorOffsetY" then
		local offset = normalizeAnchorOffset(value, defaults.anchorOffsetY)
		addon.db.repBarAnchorOffsetY = offset
		editField = "y"
		value = offset
	elseif field == "textEnabled" then
		local enabled = value == true
		addon.db.repBarShowText = enabled and true or false
		value = enabled
	elseif field == "textLeftMode" then
		local mode = normalizeTextContentMode(value)
		addon.db.repBarTextLeftMode = mode
		value = mode
		refreshSettingsUI()
	elseif field == "textCenterMode" then
		local mode = normalizeTextContentMode(value)
		addon.db.repBarTextCenterMode = mode
		addon.db.repBarTextMode = normalizeLegacyTextMode(mode)
		value = mode
		refreshSettingsUI()
	elseif field == "textRightMode" then
		local mode = normalizeTextContentMode(value)
		addon.db.repBarTextRightMode = mode
		value = mode
		refreshSettingsUI()
	elseif field == "textLeftOffsetX" then
		local offset = normalizeTextOffset(value, defaults.textLeftOffsetX)
		addon.db.repBarTextLeftOffsetX = offset
		value = offset
	elseif field == "textLeftOffsetY" then
		local offset = normalizeTextOffset(value, defaults.textLeftOffsetY)
		addon.db.repBarTextLeftOffsetY = offset
		value = offset
	elseif field == "textCenterOffsetX" then
		local offset = normalizeTextOffset(value, defaults.textCenterOffsetX)
		addon.db.repBarTextCenterOffsetX = offset
		value = offset
	elseif field == "textCenterOffsetY" then
		local offset = normalizeTextOffset(value, defaults.textCenterOffsetY)
		addon.db.repBarTextCenterOffsetY = offset
		value = offset
	elseif field == "textRightOffsetX" then
		local offset = normalizeTextOffset(value, defaults.textRightOffsetX)
		addon.db.repBarTextRightOffsetX = offset
		value = offset
	elseif field == "textRightOffsetY" then
		local offset = normalizeTextOffset(value, defaults.textRightOffsetY)
		addon.db.repBarTextRightOffsetY = offset
		value = offset
	elseif field == "textSize" then
		local size = clamp(value, TEXT_SIZE_MIN, TEXT_SIZE_MAX)
		addon.db.repBarTextSize = size
		value = size
	elseif field == "textFont" then
		local key = value or defaults.textFont or "DEFAULT"
		addon.db.repBarTextFont = key
		value = key
	elseif field == "textOutline" then
		local outline = normalizeTextOutline(value)
		addon.db.repBarTextOutline = outline
		value = outline
	elseif field == "textColor" then
		local r, g, b, a = normalizeColor(value, defaults.textColor)
		addon.db.repBarTextColor = { r = r, g = g, b = b, a = a }
		value = addon.db.repBarTextColor
	elseif field == "abbreviateNumbers" then
		local enabled = value == true
		addon.db.repBarTextAbbreviateNumbers = enabled and true or false
		value = enabled
	elseif field == "hideInPetBattle" then
		local enabled = value == true
		addon.db.repBarHideInPetBattle = enabled and true or false
		value = enabled
	elseif field == "hideBlizzardTracking" then
		local enabled = value == true
		addon.db.repBarHideBlizzardTracking = enabled and true or false
		value = enabled
	end

	if not skipEditValue and EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, editField, value, nil, true) end
	ReputationBar:ApplySize()
	ReputationBar:ApplyAppearance()
	ReputationBar:RefreshAnchor()
	if ReputationBar.previewing then
		ReputationBar:UpdatePreviewSample()
	else
		ReputationBar:UpdateSoon()
	end
end

function ReputationBar:RegisterEditMode(frame)
	if editModeRegistered or not EditMode or not EditMode.RegisterFrame then return end
	local editFrame = frame or self.frame
	if not editFrame then return end

	local settings
	if SettingType then
		local function anchorFrameEntries()
			local entries = {}
			local seen = {}
			local function frameIsAvailable(key)
				if key == ANCHOR_TARGET_UI or key == ANCHOR_TARGET_PLAYER_CASTBAR then return true end
				return _G and _G[key] ~= nil
			end
			local function add(key, label, force)
				if not key or key == "" or seen[key] then return end
				if not force and not frameIsAvailable(key) then return end
				seen[key] = true
				entries[#entries + 1] = { key = key, label = label or key }
			end

			add(ANCHOR_TARGET_UI, L["Screen (UIParent)"] or "Screen (UIParent)", true)
			add(ANCHOR_TARGET_PLAYER_CASTBAR, L["Player Castbar"] or "Player Castbar", true)
			add("EQOL_XPBar", L["ExperienceBar"] or "Experience Bar")
			add("EQOL_HonorBar", L["HonorBar"] or "Honor Bar")
			add("EQOL_GCDBar", L["GCDBar"] or "GCD Bar")

			add("PlayerFrame", _G.HUD_EDIT_MODE_PLAYER_FRAME_LABEL or PLAYER or "Player Frame")
			add("TargetFrame", _G.HUD_EDIT_MODE_TARGET_FRAME_LABEL or TARGET or "Target Frame")

			add("EssentialCooldownViewer", L["cooldownViewerEssential"] or "Essential Cooldown Viewer")
			add("UtilityCooldownViewer", L["cooldownViewerUtility"] or "Utility Cooldown Viewer")
			add("BuffBarCooldownViewer", L["cooldownViewerBuffBar"] or "Buff Bar Cooldowns")
			add("BuffIconCooldownViewer", L["cooldownViewerBuffIcon"] or "Buff Icon Cooldowns")

			local cooldownPanels = addon.Aura and addon.Aura.CooldownPanels
			if cooldownPanels and cooldownPanels.GetRoot then
				local root = cooldownPanels:GetRoot()
				if root and root.panels then
					local order = root.order or {}
					local function addPanelEntry(panelId, panel)
						if not panel or panel.enabled == false then return end
							local label = (L["cooldownPanelReferenceLabel"]):format(tostring(panelId), panel.name or L["cooldownPanelDefaultName"])
						add("EQOL_CooldownPanel" .. tostring(panelId), label)
					end
					if #order > 0 then
						for _, panelId in ipairs(order) do
							addPanelEntry(panelId, root.panels[panelId])
						end
					else
						for panelId, panel in pairs(root.panels) do
							addPanelEntry(panelId, panel)
						end
					end
				end
			end

			local rb = addon.Aura and addon.Aura.ResourceBars
			add("EQOLHealthBar", HEALTH or "Health")
			if rb and rb.classPowerTypes then
				for _, pType in ipairs(rb.classPowerTypes) do
					local frameName = "EQOL" .. tostring(pType) .. "Bar"
					local label = (rb.PowerLabels and rb.PowerLabels[pType]) or _G["POWER_TYPE_" .. tostring(pType)] or tostring(pType)
					add(frameName, label)
				end
			end

			local current = ReputationBar:GetAnchorRelativeFrame()
			if current and not seen[current] then add(current, current, true) end

			return entries
		end

		local function dropdownFromModes(getFn, setFn)
			return function(_, root)
				for _, option in ipairs(textModeOptions()) do
					root:CreateRadio(option.label, function() return getFn() == option.value end, function() setFn(option.value) end)
				end
			end
		end

		local visibilityRuleOptions = (addon.Aura and addon.Aura.ResourceBars and addon.Aura.ResourceBars.GetVisibilityRuleOptions and addon.Aura.ResourceBars.GetVisibilityRuleOptions()) or {}
		local function getVisibilitySelection()
			local rb = addon.Aura and addon.Aura.ResourceBars
			local normalized = rb and rb.NormalizeVisibilityConfig and rb.NormalizeVisibilityConfig(addon.db and addon.db[DB_VISIBILITY], {
				visibilityExplicit = addon.db and addon.db[DB_VISIBILITY_EXPLICIT] == true or nil,
			}) or nil
			if not normalized and addon.db then
				local fallback = nil
				if addon.db.resourceBarsHideOutOfCombat == true then
					fallback = fallback or {}
					fallback.ALWAYS_IN_COMBAT = true
				end
				if addon.db.resourceBarsHideMounted == true then
					fallback = fallback or {}
					fallback.PLAYER_NOT_MOUNTED = true
				end
				if fallback and rb and rb.NormalizeVisibilityConfig then normalized = rb.NormalizeVisibilityConfig(fallback) end
			end
			if rb and rb.CopyVisibilitySelection then return rb.CopyVisibilitySelection(normalized) end
			return normalized and CopyTable(normalized) or nil
		end
		local function setVisibilityRule(rule, state)
			if not addon.db then return end
			local rb = addon.Aura and addon.Aura.ResourceBars
			local normalized = getVisibilitySelection() or {}
			addon.db[DB_VISIBILITY_EXPLICIT] = true
			if rule == "ALWAYS_HIDDEN" and state then
				normalized = { ALWAYS_HIDDEN = true }
			elseif state then
				normalized[rule] = true
				normalized.ALWAYS_HIDDEN = nil
			else
				normalized[rule] = nil
			end
			if not next(normalized) then
				addon.db[DB_VISIBILITY] = nil
			elseif rb and rb.CopyVisibilitySelection then
				addon.db[DB_VISIBILITY] = rb.CopyVisibilitySelection(normalized)
			else
				addon.db[DB_VISIBILITY] = CopyTable(normalized)
			end
			ReputationBar:ApplyVisibilityPreference(ReputationBar.frame and ReputationBar.frame._rbDesiredVisible ~= false)
		end

		settings = {
			{
				name = _G.HUD_EDIT_MODE_SETTING_ANCHOR or "Anchor",
				kind = SettingType.Collapsible,
				id = "repBarAnchor",
				defaultCollapsed = false,
			},
			{
				name = L["Anchor to"] or "Anchor to",
				kind = SettingType.Dropdown,
				field = "anchorRelativeFrame",
				parentId = "repBarAnchor",
				height = 180,
				get = function() return ReputationBar:GetAnchorRelativeFrame() end,
				set = function(_, value) applySetting("anchorRelativeFrame", value) end,
				generator = function(_, root)
					for _, option in ipairs(anchorFrameEntries()) do
						root:CreateRadio(option.label, function() return ReputationBar:GetAnchorRelativeFrame() == option.key end, function() applySetting("anchorRelativeFrame", option.key) end)
					end
				end,
			},
			{
				name = L["Anchor point"] or "Anchor point",
				kind = SettingType.Dropdown,
				field = "anchorPoint",
				parentId = "repBarAnchor",
				height = 180,
				get = function() return ReputationBar:GetAnchorPoint() end,
				set = function(_, value) applySetting("anchorPoint", value) end,
				generator = function(_, root)
					for _, point in ipairs(ANCHOR_POINTS) do
						root:CreateRadio(point, function() return ReputationBar:GetAnchorPoint() == point end, function() applySetting("anchorPoint", point) end)
					end
				end,
			},
			{
				name = L["Relative point"] or "Relative point",
				kind = SettingType.Dropdown,
				field = "anchorRelativePoint",
				parentId = "repBarAnchor",
				height = 180,
				get = function() return ReputationBar:GetAnchorRelativePoint() end,
				set = function(_, value) applySetting("anchorRelativePoint", value) end,
				generator = function(_, root)
					for _, point in ipairs(ANCHOR_POINTS) do
						root:CreateRadio(point, function() return ReputationBar:GetAnchorRelativePoint() == point end, function() applySetting("anchorRelativePoint", point) end)
					end
				end,
			},
			{
				name = L["X Offset"] or "X Offset",
				kind = SettingType.Slider,
				field = "anchorOffsetX",
				parentId = "repBarAnchor",
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetAnchorOffsetX() end,
				set = function(_, value) applySetting("anchorOffsetX", value) end,
			},
			{
				name = L["Y Offset"] or "Y Offset",
				kind = SettingType.Slider,
				field = "anchorOffsetY",
				parentId = "repBarAnchor",
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetAnchorOffsetY() end,
				set = function(_, value) applySetting("anchorOffsetY", value) end,
			},
			{
				name = L["Match relative frame width"] or "Match relative frame width",
				kind = SettingType.Checkbox,
				field = "anchorMatchWidth",
				parentId = "repBarAnchor",
				default = defaults.anchorMatchRelativeWidth == true,
				get = function() return ReputationBar:GetAnchorMatchWidth() end,
				set = function(_, value) applySetting("anchorMatchWidth", value) end,
				isEnabled = function() return not ReputationBar:AnchorUsesUIParent() end,
			},
			{
				name = L["Offset"] or "Offset",
				kind = SettingType.Slider,
				field = "anchorMatchWidthOffset",
				parentId = "repBarAnchor",
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				default = defaults.anchorMatchRelativeWidthOffset or 0,
				get = function() return ReputationBar:GetAnchorMatchWidthOffset() end,
				set = function(_, value) applySetting("anchorMatchWidthOffset", value) end,
				isEnabled = function() return ReputationBar:AnchorUsesMatchedWidth() end,
			},
			{
				name = L["Visibility"] or "Visibility",
				kind = SettingType.Collapsible,
				id = "repBarVisibility",
				defaultCollapsed = true,
			},
			{
				name = L["Show when"] or "Show when",
				kind = SettingType.MultiDropdown,
				field = "visibility",
				parentId = "repBarVisibility",
				height = 220,
				values = visibilityRuleOptions,
				hideSummary = true,
				default = getVisibilitySelection(),
				isSelected = function(_, value)
					local selection = getVisibilitySelection()
					return selection and selection[value] == true or false
				end,
				setSelected = function(_, value, state) setVisibilityRule(value, state and true or false) end,
				isShown = function() return visibilityRuleOptions and #visibilityRuleOptions > 0 end,
				isEnabled = function() return visibilityRuleOptions and #visibilityRuleOptions > 0 end,
			},
			{
				name = L["Hide in pet battles"] or "Hide in pet battles",
				kind = SettingType.Checkbox,
				field = "hideInPetBattle",
				parentId = "repBarVisibility",
				default = defaults.hideInPetBattle == true,
				get = function() return ReputationBar:GetHideInPetBattle() end,
				set = function(_, value) applySetting("hideInPetBattle", value) end,
			},
			{
				name = L["repBarHideBlizzardTracking"] or "Hide Blizzard tracking bars while leveling",
				kind = SettingType.Checkbox,
				field = "hideBlizzardTracking",
				parentId = "repBarVisibility",
				default = defaults.hideBlizzardTracking == true,
				get = function() return ReputationBar:GetHideBlizzardTracking() end,
				set = function(_, value) applySetting("hideBlizzardTracking", value) end,
			},
			{
				name = L["Frame"] or "Frame",
				kind = SettingType.Collapsible,
				id = "repBarFrame",
				defaultCollapsed = true,
			},
			{
				name = L["Bar width"] or "Bar width",
				kind = SettingType.Slider,
				field = "width",
				parentId = "repBarFrame",
				default = defaults.width,
				minValue = BAR_SIZE_MIN,
				maxValue = BAR_WIDTH_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetWidth() end,
				set = function(_, value) applySetting("width", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return not ReputationBar:AnchorUsesMatchedWidth() end,
			},
			{
				name = L["Bar height"] or "Bar height",
				kind = SettingType.Slider,
				field = "height",
				parentId = "repBarFrame",
				default = defaults.height,
				minValue = BAR_SIZE_MIN,
				maxValue = BAR_SIZE_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetHeight() end,
				set = function(_, value) applySetting("height", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["Fill direction"] or "Fill direction",
				kind = SettingType.Dropdown,
				field = "fillDirection",
				parentId = "repBarFrame",
				height = 140,
				get = function() return ReputationBar:GetFillDirection() end,
				set = function(_, value) applySetting("fillDirection", value) end,
				generator = function(_, root)
					local opts = {
						{ value = "LEFT", label = L["Left to right"] or "Left to right" },
						{ value = "RIGHT", label = L["Right to left"] or "Right to left" },
						{ value = "UP", label = L["Bottom to top"] or "Bottom to top" },
						{ value = "DOWN", label = L["Top to bottom"] or "Top to bottom" },
					}
					for _, option in ipairs(opts) do
						root:CreateRadio(option.label, function() return ReputationBar:GetFillDirection() == option.value end, function() applySetting("fillDirection", option.value) end)
					end
				end,
			},
			{
				name = L["Bar"] or "Bar",
				kind = SettingType.Collapsible,
				id = "repBarBar",
				defaultCollapsed = true,
			},
			{
				name = L["Bar texture"] or "Bar texture",
				kind = SettingType.Dropdown,
				field = "texture",
				parentId = "repBarBar",
				height = 180,
				get = function() return ReputationBar:GetTextureKey() end,
				set = function(_, value) applySetting("texture", value) end,
				generator = function(_, root)
					for _, option in ipairs(textureOptions()) do
						root:CreateRadio(option.label, function() return ReputationBar:GetTextureKey() == option.value end, function() applySetting("texture", option.value) end)
					end
				end,
			},
			{
				name = L["repBarColor"] or "Bar color",
				kind = SettingType.Color,
				field = "color",
				parentId = "repBarBar",
				default = defaults.color,
				hasOpacity = true,
				get = function()
					local r, g, b, a = ReputationBar:GetColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("color", value) end,
				isEnabled = function() return not ReputationBar:GetUseStandingColor() end,
			},
			{
				name = L["repBarUseStandingColor"] or "Use standing color",
				kind = SettingType.Checkbox,
				field = "useStandingColor",
				parentId = "repBarBar",
				default = defaults.useStandingColor == true,
				get = function() return ReputationBar:GetUseStandingColor() end,
				set = function(_, value) applySetting("useStandingColor", value) end,
			},
			{
				name = L["Background"] or "Background",
				kind = SettingType.Collapsible,
				id = "repBarBackground",
				defaultCollapsed = true,
			},
			{
				name = L["Use background"] or "Use background",
				kind = SettingType.Checkbox,
				field = "bgEnabled",
				parentId = "repBarBackground",
				default = defaults.bgEnabled == true,
				get = function() return ReputationBar:GetBackgroundEnabled() end,
				set = function(_, value) applySetting("bgEnabled", value) end,
			},
			{
				name = L["Background texture"] or "Background texture",
				kind = SettingType.Dropdown,
				field = "bgTexture",
				parentId = "repBarBackground",
				height = 180,
				get = function() return ReputationBar:GetBackgroundTextureKey() end,
				set = function(_, value) applySetting("bgTexture", value) end,
				generator = function(_, root)
					for _, option in ipairs(textureOptions()) do
						root:CreateRadio(option.label, function() return ReputationBar:GetBackgroundTextureKey() == option.value end, function() applySetting("bgTexture", option.value) end)
					end
				end,
				isEnabled = function() return ReputationBar:GetBackgroundEnabled() end,
			},
			{
				name = L["Background color"] or "Background color",
				kind = SettingType.Color,
				field = "bgColor",
				parentId = "repBarBackground",
				default = defaults.bgColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = ReputationBar:GetBackgroundColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("bgColor", value) end,
				isEnabled = function() return ReputationBar:GetBackgroundEnabled() end,
			},
			{
				name = BORDER_LABEL,
				kind = SettingType.Collapsible,
				id = "repBarBorder",
				defaultCollapsed = true,
			},
			{
				name = L["Use border"] or "Use border",
				kind = SettingType.Checkbox,
				field = "borderEnabled",
				parentId = "repBarBorder",
				default = defaults.borderEnabled == true,
				get = function() return ReputationBar:GetBorderEnabled() end,
				set = function(_, value) applySetting("borderEnabled", value) end,
			},
			{
				name = L["Border texture"] or "Border texture",
				kind = SettingType.Dropdown,
				field = "borderTexture",
				parentId = "repBarBorder",
				height = 180,
				get = function() return ReputationBar:GetBorderTextureKey() end,
				set = function(_, value) applySetting("borderTexture", value) end,
				generator = function(_, root)
					for _, option in ipairs(borderOptions()) do
						root:CreateRadio(option.label, function() return ReputationBar:GetBorderTextureKey() == option.value end, function() applySetting("borderTexture", option.value) end)
					end
				end,
				isEnabled = function() return ReputationBar:GetBorderEnabled() end,
			},
			{
				name = L["Border size"] or "Border size",
				kind = SettingType.Slider,
				field = "borderSize",
				parentId = "repBarBorder",
				default = defaults.borderSize,
				minValue = 1,
				maxValue = 20,
				valueStep = 1,
				get = function() return ReputationBar:GetBorderSize() end,
				set = function(_, value) applySetting("borderSize", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return ReputationBar:GetBorderEnabled() end,
			},
			{
				name = L["Border offset"] or "Border offset",
				kind = SettingType.Slider,
				field = "borderOffset",
				parentId = "repBarBorder",
				default = defaults.borderOffset,
				minValue = -20,
				maxValue = 20,
				valueStep = 1,
				get = function() return ReputationBar:GetBorderOffset() end,
				set = function(_, value) applySetting("borderOffset", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return ReputationBar:GetBorderEnabled() end,
			},
			{
				name = EMBLEM_BORDER_COLOR,
				kind = SettingType.Color,
				field = "borderColor",
				parentId = "repBarBorder",
				default = defaults.borderColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = ReputationBar:GetBorderColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("borderColor", value) end,
				isEnabled = function() return ReputationBar:GetBorderEnabled() end,
			},
			{
				name = TEXT_LABEL,
				kind = SettingType.Collapsible,
				id = "repBarText",
				defaultCollapsed = true,
			},
			{
				name = L["repBarTextEnabled"] or "Show text",
				kind = SettingType.Checkbox,
				field = "textEnabled",
				parentId = "repBarText",
				default = defaults.textEnabled == true,
				get = function() return ReputationBar:GetTextEnabled() end,
				set = function(_, value) applySetting("textEnabled", value) end,
			},
			{
				name = L["Use short numbers"] or "Use short numbers",
				kind = SettingType.Checkbox,
				field = "abbreviateNumbers",
				parentId = "repBarText",
				default = defaults.abbreviateNumbers == true,
				get = function() return ReputationBar:GetAbbreviateNumbers() end,
				set = function(_, value) applySetting("abbreviateNumbers", value) end,
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
			{
				name = L["Left text"] or "Left text",
				kind = SettingType.Dropdown,
				field = "textLeftMode",
				parentId = "repBarText",
				height = 200,
				get = function() return ReputationBar:GetTextLeftMode() end,
				set = function(_, value) applySetting("textLeftMode", value) end,
				generator = dropdownFromModes(function() return ReputationBar:GetTextLeftMode() end, function(value) applySetting("textLeftMode", value) end),
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
				{
					name = L["Left text offset X"] or "Left text offset X",
					kind = SettingType.Slider,
					field = "textLeftOffsetX",
				parentId = "repBarText",
				default = defaults.textLeftOffsetX,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextLeftOffsetX() end,
					set = function(_, value) applySetting("textLeftOffsetX", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextLeftMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
			{
				name = L["Left text offset Y"] or "Left text offset Y",
				kind = SettingType.Slider,
				field = "textLeftOffsetY",
				parentId = "repBarText",
				default = defaults.textLeftOffsetY,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextLeftOffsetY() end,
					set = function(_, value) applySetting("textLeftOffsetY", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextLeftMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
				{
					name = L["Center text"] or "Center text",
					kind = SettingType.Dropdown,
					field = "textCenterMode",
					parentId = "repBarText",
					height = 200,
					get = function() return ReputationBar:GetTextCenterMode() end,
					set = function(_, value) applySetting("textCenterMode", value) end,
					generator = dropdownFromModes(function() return ReputationBar:GetTextCenterMode() end, function(value) applySetting("textCenterMode", value) end),
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
				{
					name = L["Center text offset X"] or "Center text offset X",
					kind = SettingType.Slider,
					field = "textCenterOffsetX",
				parentId = "repBarText",
				default = defaults.textCenterOffsetX,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextCenterOffsetX() end,
					set = function(_, value) applySetting("textCenterOffsetX", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextCenterMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
			{
				name = L["Center text offset Y"] or "Center text offset Y",
				kind = SettingType.Slider,
				field = "textCenterOffsetY",
				parentId = "repBarText",
				default = defaults.textCenterOffsetY,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextCenterOffsetY() end,
					set = function(_, value) applySetting("textCenterOffsetY", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextCenterMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
				{
					name = L["Right text"] or "Right text",
					kind = SettingType.Dropdown,
					field = "textRightMode",
					parentId = "repBarText",
					height = 200,
					get = function() return ReputationBar:GetTextRightMode() end,
					set = function(_, value) applySetting("textRightMode", value) end,
					generator = dropdownFromModes(function() return ReputationBar:GetTextRightMode() end, function(value) applySetting("textRightMode", value) end),
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
				{
					name = L["Right text offset X"] or "Right text offset X",
					kind = SettingType.Slider,
					field = "textRightOffsetX",
				parentId = "repBarText",
				default = defaults.textRightOffsetX,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextRightOffsetX() end,
					set = function(_, value) applySetting("textRightOffsetX", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextRightMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
			{
				name = L["Right text offset Y"] or "Right text offset Y",
				kind = SettingType.Slider,
				field = "textRightOffsetY",
				parentId = "repBarText",
				default = defaults.textRightOffsetY,
				minValue = -200,
				maxValue = 200,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextRightOffsetY() end,
					set = function(_, value) applySetting("textRightOffsetY", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isShown = function() return ReputationBar:GetTextRightMode() ~= "NONE" end,
					isEnabled = function() return ReputationBar:GetTextEnabled() end,
				},
			{
				name = L["Text size"] or "Text size",
				kind = SettingType.Slider,
				field = "textSize",
				parentId = "repBarText",
				default = defaults.textSize,
				minValue = TEXT_SIZE_MIN,
				maxValue = TEXT_SIZE_MAX,
				valueStep = 1,
				allowInput = true,
				get = function() return ReputationBar:GetTextSize() end,
				set = function(_, value) applySetting("textSize", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
			{
				name = L["Text font"] or "Text font",
				kind = SettingType.Dropdown,
				field = "textFont",
				parentId = "repBarText",
				height = 180,
				get = function() return ReputationBar:GetTextFont() end,
				set = function(_, value) applySetting("textFont", value) end,
				generator = function(_, root)
					for _, option in ipairs(fontOptions()) do
						root:CreateRadio(option.label, function() return ReputationBar:GetTextFont() == option.value end, function() applySetting("textFont", option.value) end)
					end
				end,
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
			{
				name = L["Text outline"] or "Text outline",
				kind = SettingType.Dropdown,
				field = "textOutline",
				parentId = "repBarText",
				height = 120,
				get = function() return ReputationBar:GetTextOutline() end,
				set = function(_, value) applySetting("textOutline", value) end,
				generator = function(_, root)
					local options = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true) or {
						{ value = "NONE", label = NONE },
						{ value = "OUTLINE", label = L["Outline"] or "Outline" },
					}
					for _, option in ipairs(options) do
						root:CreateRadio(option.label, function() return ReputationBar:GetTextOutline() == option.value end, function() applySetting("textOutline", option.value) end)
					end
				end,
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
			{
				name = L["Text color"] or "Text color",
				kind = SettingType.Color,
				field = "textColor",
				parentId = "repBarText",
				default = defaults.textColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = ReputationBar:GetTextColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("textColor", value) end,
				isEnabled = function() return ReputationBar:GetTextEnabled() end,
			},
		}
	end

	local function seedEditModeRecordFromProfile(record)
		if type(record) ~= "table" then return end
		local src = ReputationBar:BuildLayoutRecordFromProfile()
		for k, v in pairs(src) do
			record[k] = v
		end
	end

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = editFrame,
		title = L["ReputationBar"] or "Reputation Bar",
		layoutDefaults = {
			point = self:GetAnchorPoint(),
			relativePoint = self:GetAnchorRelativePoint(),
			x = self:GetAnchorOffsetX(),
			y = self:GetAnchorOffsetY(),
			width = self:GetWidth(),
			height = self:GetHeight(),
			texture = self:GetTextureKey(),
			bgEnabled = self:GetBackgroundEnabled(),
			bgTexture = self:GetBackgroundTextureKey(),
			bgColor = (function()
				local r, g, b, a = self:GetBackgroundColor()
				return { r = r, g = g, b = b, a = a }
			end)(),
			borderEnabled = self:GetBorderEnabled(),
			borderTexture = self:GetBorderTextureKey(),
			borderColor = (function()
				local r, g, b, a = self:GetBorderColor()
				return { r = r, g = g, b = b, a = a }
			end)(),
			borderSize = self:GetBorderSize(),
			borderOffset = self:GetBorderOffset(),
			fillDirection = self:GetFillDirection(),
			anchorRelativeFrame = self:GetAnchorRelativeFrame(),
			anchorMatchWidth = self:GetAnchorMatchWidth(),
			anchorMatchWidthOffset = self:GetAnchorMatchWidthOffset(),
			textEnabled = self:GetTextEnabled(),
			textLeftMode = self:GetTextLeftMode(),
			textCenterMode = self:GetTextCenterMode(),
			textRightMode = self:GetTextRightMode(),
			textLeftOffsetX = self:GetTextLeftOffsetX(),
			textLeftOffsetY = self:GetTextLeftOffsetY(),
			textCenterOffsetX = self:GetTextCenterOffsetX(),
			textCenterOffsetY = self:GetTextCenterOffsetY(),
			textRightOffsetX = self:GetTextRightOffsetX(),
			textRightOffsetY = self:GetTextRightOffsetY(),
			textMode = normalizeLegacyTextMode(self:GetTextCenterMode()),
			textSize = self:GetTextSize(),
			textFont = self:GetTextFont(),
			textOutline = self:GetTextOutline(),
			abbreviateNumbers = self:GetAbbreviateNumbers(),
			textColor = (function()
				local r, g, b, a = self:GetTextColor()
				return { r = r, g = g, b = b, a = a }
			end)(),
			hideInPetBattle = self:GetHideInPetBattle(),
			hideBlizzardTracking = self:GetHideBlizzardTracking(),
			useStandingColor = self:GetUseStandingColor(),
			color = (function()
				local r, g, b, a = self:GetColor()
				return { r = r, g = g, b = b, a = a }
			end)(),
		},
		normalizePosition = true,
		onApply = function(_, _, data)
			if not self._eqolEditModeHydrated then
				self._eqolEditModeHydrated = true
				local record = data or {}
				seedEditModeRecordFromProfile(record)
				ReputationBar:ApplyLayoutData(record)
				return
			end
			ReputationBar:ApplyLayoutData(data)
		end,
		onEnter = function() ReputationBar:ShowEditModeHint(true) end,
		onExit = function() ReputationBar:ShowEditModeHint(false) end,
		isEnabled = function() return addon.db and addon.db[DB_ENABLED] == true end,
		settings = settings,
		relativeTo = function() return ReputationBar:ResolveAnchorFrame() end,
		allowDrag = function() return ReputationBar:AnchorUsesUIParent() end,
		settingsMaxHeight = DEFAULT_SETTINGS_MAX_HEIGHT,
		showOutsideEditMode = false,
		collapseExclusive = true,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
	})
	applyFrameSettingsMaxHeight(editFrame)
	ensureSettingsMaxHeightWatcher()
	applyRegisteredSettingsMaxHeight()

	editModeRegistered = true
end

function ReputationBar:OnSettingChanged(enabled)
	if enabled then
		self:EnsureFrame()
		self:RegisterEvents()
		self:ApplyLayoutData(self:BuildLayoutRecordFromProfile())
		self:RefreshAnchor()
		self:ApplySize()
		self:ApplyAppearance()
		self:UpdateReputation()
		self:UpdateSoon()
	else
		self:UnregisterEvents()
		self:StopBootstrapRefresh()
		self:ApplyVisibilityPreference(false)
		if self.frame then self.frame:Hide() end
		if self._anchorRefreshTicker then
			self._anchorRefreshTicker:Cancel()
			self._anchorRefreshTicker = nil
		end
		self:ApplyBlizzardTrackingVisibility()
	end

	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

return ReputationBar
