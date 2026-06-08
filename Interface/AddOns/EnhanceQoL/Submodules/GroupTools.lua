local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.GroupTools = addon.GroupTools or {}
local GroupTools = addon.GroupTools
GroupTools.functions = GroupTools.functions or {}

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType

local UIParent = UIParent
local math = math
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local table = table
local string = string

local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local VALID_STRATA = {}
for _, strata in ipairs(STRATA_ORDER) do
	VALID_STRATA[strata] = true
end

local HEALER_MANA_FRAME_WIDTH = 220
local HEALER_MANA_PERCENT_WIDTH = 54
local HEALER_MANA_TEXT_PADDING = 4
local DEATH_ALERT_FRAME_WIDTH = 320
local NO_TARGET_FRAME_WIDTH = 220

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
local ROLE_LABELS = {
	TANK = _G.TANK or "Tank",
	HEALER = _G.HEALER or "Healer",
	DAMAGER = _G.DAMAGER or "Damage",
}

local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

local MARKER_TOKENS = {
	[1] = "star",
	[2] = "circle",
	[3] = "diamond",
	[4] = "triangle",
	[5] = "moon",
	[6] = "square",
	[7] = "cross",
	[8] = "skull",
}

local TTS_VOICE_DEFAULT = 0
local TTS_RATE_DEFAULT = 1

local EDITMODE_IDS = {
	healerMana = "groupToolsHealerMana",
	deathAlert = "groupToolsDeathAlert",
	noTarget = "groupToolsNoTarget",
}
GroupTools.EDITMODE_IDS = EDITMODE_IDS

local DB = {
	healerEnabled = "groupToolsHealerManaEnabled",
	healerDungeons = "groupToolsHealerManaDungeons",
	healerRaids = "groupToolsHealerManaRaids",
	healerGrowUp = "groupToolsHealerManaGrowUp",
	healerShowName = "groupToolsHealerManaShowName",
	healerNameMaxChars = "groupToolsHealerManaNameMaxChars",
	healerNameNoEllipsis = "groupToolsHealerManaNameNoEllipsis",
	healerColor = "groupToolsHealerManaColor",
	healerFontFace = "groupToolsHealerManaFontFace",
	healerFontStyle = "groupToolsHealerManaFontStyle",
	healerFontSize = "groupToolsHealerManaFontSize",
	healerStrata = "groupToolsHealerManaStrata",

	deathEnabled = "groupToolsDeathAlertEnabled",
	deathShowText = "groupToolsDeathAlertShowText",
	deathColor = "groupToolsDeathAlertColor",
	deathDuration = "groupToolsDeathAlertDuration",
	deathFontFace = "groupToolsDeathAlertFontFace",
	deathFontStyle = "groupToolsDeathAlertFontStyle",
	deathFontSize = "groupToolsDeathAlertFontSize",
	deathStrata = "groupToolsDeathAlertStrata",
	deathTTSVoice = "groupToolsDeathAlertTTSVoice",
	deathTTSVolume = "groupToolsDeathAlertTTSVolume",
	deathRoleConfig = "groupToolsDeathAlertRoleConfig",

	noTargetEnabled = "groupToolsNoTargetEnabled",
	noTargetShowText = "groupToolsNoTargetShowText",
	noTargetText = "groupToolsNoTargetText",
	noTargetColor = "groupToolsNoTargetColor",
	noTargetFontFace = "groupToolsNoTargetFontFace",
	noTargetFontStyle = "groupToolsNoTargetFontStyle",
	noTargetFontSize = "groupToolsNoTargetFontSize",
	noTargetStrata = "groupToolsNoTargetStrata",
	noTargetFriendly = "groupToolsNoTargetFriendly",
	noTargetPlaySound = "groupToolsNoTargetPlaySound",
	noTargetSound = "groupToolsNoTargetSound",

	focusMarkerEnabled = "groupToolsFocusMarkerEnabled",
	focusMarker = "groupToolsFocusMarkerIcon",
	focusMarkerAnnounce = "groupToolsFocusMarkerAnnounce",
	focusMarkerMessage = "groupToolsFocusMarkerMessage",
}
GroupTools.DB = DB

local function locale(key, fallback) return L[key] or fallback end
local function globalFontKey() return addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__" end
local function globalStyleKey() return addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__" end

local function copyValue(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = copyValue(child)
	end
	return copy
end

local function initDBValue(key, value)
	if not addon.db then return end
	if addon.db[key] == nil then addon.db[key] = copyValue(value) end
end

local function clamp(value, minValue, maxValue, fallback)
	local num = tonumber(value) or fallback or minValue
	if num < minValue then num = minValue end
	if num > maxValue then num = maxValue end
	return num
end

local function normalizeColor(value, fallback)
	if type(value) ~= "table" then value = fallback end
	value = type(value) == "table" and value or {}
	fallback = type(fallback) == "table" and fallback or {}
	return {
		r = clamp(value.r, 0, 1, fallback.r or 1),
		g = clamp(value.g, 0, 1, fallback.g or 1),
		b = clamp(value.b, 0, 1, fallback.b or 1),
		a = clamp(value.a, 0, 1, fallback.a or 1),
	}
end

local function normalizeStrata(value, fallback)
	if type(value) == "string" then
		local upper = string.upper(value)
		if VALID_STRATA[upper] then return upper end
	end
	return fallback or "MEDIUM"
end

local function getDB(key, fallback)
	if not addon.db then return fallback end
	local value = addon.db[key]
	if value == nil then return fallback end
	return value
end

local function setDB(key, value)
	if addon.db then addon.db[key] = value end
end

local function getSoundFile(soundKey)
	if type(soundKey) ~= "string" or soundKey == "" or not (LSM and LSM.Fetch) then return nil end
	return LSM:Fetch("sound", soundKey, true)
end

local function playSharedMediaSound(soundKey)
	local file = getSoundFile(soundKey)
	if file then PlaySoundFile(file, "Master") end
end

local function speakText(text, volume, voiceID)
	if type(text) ~= "string" or text == "" then return end
	if C_VoiceChat and C_VoiceChat.SpeakText then
		C_VoiceChat.SpeakText(tonumber(voiceID) or TTS_VOICE_DEFAULT, text, TTS_RATE_DEFAULT, clamp(volume, 0, 100, 50), true)
	end
end

local function refreshEditModeSettingValues()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then addon.EditModeLib.internal:RefreshSettingValues() end
end

local function refreshEditModeFrame(id)
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(id) end
end

local function runNextFrame(callback)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, callback)
	else
		callback()
	end
end

local function isInEditMode() return EditMode and EditMode.IsInEditMode and EditMode:IsInEditMode() end

local function getUnitDisplayName(unit, hideRealm)
	local name = UnitName(unit)
	if not name then return nil end
	if hideRealm == true and _G.Ambiguate then
		local shortName = _G.Ambiguate(name, "short")
		if shortName and shortName ~= "" then name = shortName end
	end
	return name
end

local function colorUnitName(unit, name)
	if not name then return nil end
	local _, class = UnitClass(unit)
	local color = class and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class)
	if color and color.WrapTextInColorCode then return color:WrapTextInColorCode(name) end
	local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if classColor and classColor.colorStr then return ("|c%s%s|r"):format(classColor.colorStr, name) end
	return name
end

local function classColoredUnitName(unit, hideRealm)
	local name = getUnitDisplayName(unit, hideRealm)
	if not name then return nil end
	return colorUnitName(unit, name), name
end

local function getGroupUnits()
	local units = {}
	if IsInRaid() then
		local count = GetNumGroupMembers() or 0
		for i = 1, count do
			units[#units + 1] = "raid" .. i
		end
	elseif IsInGroup() then
		units[#units + 1] = "player"
		local count = GetNumSubgroupMembers() or 0
		for i = 1, count do
			units[#units + 1] = "party" .. i
		end
	else
		units[#units + 1] = "player"
	end
	return units
end

local function unitTokenFromGUID(guid)
	if not guid then return nil end
	if _G.issecretvalue and _G.issecretvalue(guid) then return nil end
	local token = _G.UnitTokenFromGUID and _G.UnitTokenFromGUID(guid)
	if token then return token end
	if UnitGUID("player") == guid then return "player" end
	for _, unit in ipairs(getGroupUnits()) do
		if unit ~= "player" and UnitGUID(unit) == guid then return unit end
	end
	return nil
end

local function isGroupUnit(unit)
	if type(unit) ~= "string" then return false end
	return unit == "player" or UnitInParty(unit) or UnitInRaid(unit)
end

local function isManaPowerToken(powerToken)
	if powerToken == nil then return true end
	if powerToken == "MANA" then return true end
	local manaPowerType = Enum and Enum.PowerType and Enum.PowerType.Mana
	return manaPowerType ~= nil and powerToken == manaPowerType
end

local function applyFontString(fontString, fontFaceKey, fontSize, fontStyleKey)
	if addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(fontString, fontFaceKey, fontSize, fontStyleKey, globalFontKey(), globalStyleKey())
	elseif fontString and fontString.SetFont then
		local fallback = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
		fontString:SetFont(fallback, fontSize or 14, "OUTLINE")
	end
end

local function measureTextWidth(fontFace, fontSize, fontStyle, text)
	if type(text) ~= "string" or text == "" or not (UIParent and UIParent.CreateFontString) then return 0 end
	GroupTools.measureText = GroupTools.measureText or UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	local measure = GroupTools.measureText
	if not measure then return 0 end
	measure:Hide()
	applyFontString(measure, fontFace, fontSize, fontStyle)
	measure:SetText(text)
	return measure:GetStringWidth() or 0
end

local function buildFontFaceOptions()
	local options = {
		{ value = globalFontKey(), label = addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or locale("useGlobalFontConfig", "Use global font config") },
	}
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	for i = 1, #names do
		options[#options + 1] = { value = names[i], label = names[i] }
	end
	return options
end

local function buildFontStyleOptions()
	if addon.functions.GetFontStyleOptionList then return addon.functions.GetFontStyleOptionList(true) end
	return {
		{ value = globalStyleKey(), label = addon.functions.GetGlobalFontStyleConfigLabel and addon.functions.GetGlobalFontStyleConfigLabel() or locale("useGlobalFontStyleConfig", "Use global font styling") },
		{ value = "OUTLINE", label = locale("Outline", "Outline") },
		{ value = "NONE", label = _G.NONE or "None" },
	}
end

local function buildSoundOptions(includeNone)
	local options = {}
	if includeNone then options[#options + 1] = { value = "", label = _G.NONE or "None" } end
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("sound") or {}
	for i = 1, #names do
		options[#options + 1] = { value = names[i], label = names[i] }
	end
	return options
end

local function buildTTSVoiceOptions()
	local options = {}
	local seen = {}
	local voices = C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()
	if type(voices) == "table" then
		for i = 1, #voices do
			local voice = voices[i]
			local voiceID = type(voice) == "table" and tonumber(voice.voiceID)
			local name = type(voice) == "table" and voice.name
			if voiceID then
				options[#options + 1] = {
					value = voiceID,
					label = type(name) == "string" and name ~= "" and name or tostring(voiceID),
				}
				seen[voiceID] = true
			end
		end
	end
	if not seen[TTS_VOICE_DEFAULT] then
		table.insert(options, 1, { value = TTS_VOICE_DEFAULT, label = _G.DEFAULT or "Default" })
	end
	return options
end

local function buildStrataOptions()
	local options = {}
	for i = 1, #STRATA_ORDER do
		options[#options + 1] = { value = STRATA_ORDER[i], label = STRATA_ORDER[i] }
	end
	return options
end

local function buildAnchorPointOptions()
	local options = {}
	for i = 1, #ANCHOR_POINTS do
		options[#options + 1] = { value = ANCHOR_POINTS[i], label = ANCHOR_POINTS[i] }
	end
	return options
end

local function formatPercentValue(value)
	if value == nil then return "0" end
	if _G.issecretvalue and _G.issecretvalue(value) then
		if _G.C_StringUtil and _G.C_StringUtil.RoundToNearestString then return tostring(_G.C_StringUtil.RoundToNearestString(value)) end
		if _G.AbbreviateLargeNumbers then return tostring(_G.AbbreviateLargeNumbers(value)) end
		return tostring(value)
	end
	return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function createDropdownSetting(name, getValue, setValue, optionsFunc, height)
	return {
		name = name,
		kind = SettingType.Dropdown,
		height = height or 180,
		get = getValue,
		set = function(_, value) setValue(value) end,
		generator = function(_, root)
			local options = optionsFunc()
			for i = 1, #options do
				local option = options[i]
				root:CreateRadio(option.label, function() return getValue() == option.value end, function() setValue(option.value) end)
			end
		end,
	}
end

local function createAnchorSettings(feature, editModeId, onChanged)
	local function layoutValue(field, fallback)
		if EditMode and EditMode.GetValue then
			local value = EditMode:GetValue(editModeId, field)
			if value ~= nil then return value end
		end
		return fallback
	end
	local function setLayoutValue(field, value)
		if EditMode and EditMode.SetValue then EditMode:SetValue(editModeId, field, value, nil, true) end
		if EditMode and EditMode.ApplyLayout then EditMode:ApplyLayout(editModeId) end
		if onChanged then onChanged() end
	end

	return {
		{
			name = L["Anchor point"] or "Anchor point",
			kind = SettingType.Dropdown,
			height = 180,
			get = function() return layoutValue("point", "CENTER") end,
			generator = function(_, root)
				for _, option in ipairs(buildAnchorPointOptions()) do
					root:CreateRadio(option.label, function() return layoutValue("point", "CENTER") == option.value end, function()
						setLayoutValue("point", option.value)
						refreshEditModeSettingValues()
					end)
				end
			end,
		},
		{
			name = L["Relative point"] or "Relative point",
			kind = SettingType.Dropdown,
			height = 180,
			get = function() return layoutValue("relativePoint", layoutValue("point", "CENTER")) end,
			generator = function(_, root)
				for _, option in ipairs(buildAnchorPointOptions()) do
					root:CreateRadio(option.label, function() return layoutValue("relativePoint", layoutValue("point", "CENTER")) == option.value end, function()
						setLayoutValue("relativePoint", option.value)
						refreshEditModeSettingValues()
					end)
				end
			end,
		},
		{
			name = L["X Offset"] or "X Offset",
			kind = SettingType.Slider,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			allowInput = true,
			get = function() return tonumber(layoutValue("x", 0)) or 0 end,
			set = function(_, value) setLayoutValue("x", tonumber(value) or 0) end,
		},
		{
			name = L["Y Offset"] or "Y Offset",
			kind = SettingType.Slider,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			allowInput = true,
			get = function() return tonumber(layoutValue("y", 0)) or 0 end,
			set = function(_, value) setLayoutValue("y", tonumber(value) or 0) end,
		},
		{
			name = "",
			kind = SettingType.Divider,
		},
		feature,
	}
end

local HealerMana = {}
GroupTools.HealerMana = HealerMana

function HealerMana:IsEnabled()
	return addon.db and addon.db[DB.healerEnabled] == true
end

function HealerMana:EnsureFrame()
	if self.frame then return self.frame end
	local frame = CreateFrame("Frame", "EQOLGroupToolsHealerMana", UIParent)
	frame:SetSize(170, 28)
	frame.texts = {}
	frame:Hide()
	self.frame = frame
	return frame
end

function HealerMana:GetText(index)
	local frame = self:EnsureFrame()
	if not frame.texts[index] then
		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetJustifyH("LEFT")
		self:ApplyTextStyle(text)
		text:SetText("")
		frame.texts[index] = text
	end
	return frame.texts[index]
end

function HealerMana:ClearTexts()
	local frame = self:EnsureFrame()
	for _, text in ipairs(frame.texts) do
		text:SetText("")
		text:Hide()
	end
end

function HealerMana:EnsureWatcherFrame()
	if self.watcherFrame then return self.watcherFrame end
	local frame = CreateFrame("Frame")
	self.watcherFrame = frame
	return frame
end

function HealerMana:UpdateWatcherEvents()
	local enabled = self:IsEnabled()
	if not enabled and not self.watcherFrame then return end
	local frame = self:EnsureWatcherFrame()
	if enabled then
		if self.eventsRegistered then return end
		self.onEvent = self.onEvent or function(_, event, ...) HealerMana:OnEvent(event, ...) end
		frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
		frame:RegisterEvent("LFG_ROLE_UPDATE")
		frame:RegisterEvent("UNIT_POWER_UPDATE")
		frame:RegisterEvent("UNIT_DISPLAYPOWER")
		frame:RegisterEvent("UNIT_MAXPOWER")
		frame:SetScript("OnEvent", self.onEvent)
		self.eventsRegistered = true
	elseif self.eventsRegistered then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		self.eventsRegistered = nil
	end
end

function HealerMana:ApplyTextStyle(text)
	local color = normalizeColor(getDB(DB.healerColor, { r = 1, g = 1, b = 1, a = 1 }), { r = 1, g = 1, b = 1, a = 1 })
	text:SetTextColor(color.r, color.g, color.b, color.a)
	text:SetJustifyH("LEFT")
	applyFontString(text, getDB(DB.healerFontFace, globalFontKey()), clamp(getDB(DB.healerFontSize, 14), 8, 64, 14), getDB(DB.healerFontStyle, globalStyleKey()))
end

function HealerMana:ApplyStyle()
	local frame = self:EnsureFrame()
	frame:SetFrameStrata(normalizeStrata(getDB(DB.healerStrata, "MEDIUM"), "MEDIUM"))
	for _, text in ipairs(frame.texts) do
		self:ApplyTextStyle(text)
	end
end

function HealerMana:GetLineWidth()
	if addon.db and addon.db[DB.healerShowName] == false then return HEALER_MANA_PERCENT_WIDTH end
	local maxChars = clamp(getDB(DB.healerNameMaxChars, 0), 0, 100, 0)
	if maxChars <= 0 then return HEALER_MANA_FRAME_WIDTH end
	local helper = addon.Aura and addon.Aura.UFHelper
	if not (helper and helper.getNameLimitWidth) then return HEALER_MANA_FRAME_WIDTH end
	local fontSize = clamp(getDB(DB.healerFontSize, 14), 8, 64, 14)
	local fontFace = getDB(DB.healerFontFace, globalFontKey())
	local fontStyle = getDB(DB.healerFontStyle, globalStyleKey())
	local width = helper.getNameLimitWidth(fontFace, fontSize, fontStyle, maxChars)
	if width and width > 0 then return measureTextWidth(fontFace, fontSize, fontStyle, "100% - ") + width + HEALER_MANA_TEXT_PADDING end
	return HEALER_MANA_FRAME_WIDTH
end

function HealerMana:FormatDisplayName(unit)
	local displayName = getUnitDisplayName(unit, true) or unit
	if addon.db and addon.db[DB.healerNameNoEllipsis] == true then
		local maxChars = clamp(getDB(DB.healerNameMaxChars, 0), 0, 100, 0)
		local helper = addon.Aura and addon.Aura.UFHelper
		if maxChars > 0 and helper and helper.getNameLimitWidth and helper.truncateTextToWidth then
			local fontFace = getDB(DB.healerFontFace, globalFontKey())
			local fontStyle = getDB(DB.healerFontStyle, globalStyleKey())
			local fontSize = clamp(getDB(DB.healerFontSize, 14), 8, 64, 14)
			local maxWidth = helper.getNameLimitWidth(fontFace, fontSize, fontStyle, maxChars)
			if maxWidth and maxWidth > 0 then displayName = helper.truncateTextToWidth(fontFace, fontSize, fontStyle, displayName, maxWidth) end
		end
	end
	return colorUnitName(unit, displayName) or displayName
end

function HealerMana:PositionTexts(count)
	local frame = self:EnsureFrame()
	local growUp = addon.db and addon.db[DB.healerGrowUp] == true
	local fontSize = clamp(getDB(DB.healerFontSize, 14), 8, 64, 14)
	local lineWidth = self:GetLineWidth()
	for i = 1, count do
		local text = frame.texts[i]
		if text then
			self:ApplyTextStyle(text)
			text:SetWidth(lineWidth)
			if text.SetMaxLines then text:SetMaxLines(1) end
			text:SetWordWrap(false)
			if text.SetNonSpaceWrap then text:SetNonSpaceWrap(false) end
			text:ClearAllPoints()
			if i == 1 then
				text:SetPoint(growUp and "BOTTOMLEFT" or "TOPLEFT", frame, growUp and "BOTTOMLEFT" or "TOPLEFT", 0, 0)
			elseif growUp then
				text:SetPoint("BOTTOMLEFT", frame.texts[i - 1], "TOPLEFT", 0, 4)
			else
				text:SetPoint("TOPLEFT", frame.texts[i - 1], "BOTTOMLEFT", 0, -4)
			end
		end
	end
	frame:SetSize(lineWidth, math.max(fontSize, count * (fontSize + 4)))
end

function HealerMana:ShouldShowInCurrentInstance()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return false end
	if instanceType == "party" then return addon.db and addon.db[DB.healerDungeons] == true end
	if instanceType == "raid" then return addon.db and addon.db[DB.healerRaids] == true end
	return false
end

function HealerMana:IsHealer(unit)
	return UnitExists(unit) and UnitIsConnected(unit) and UnitGroupRolesAssigned(unit) == "HEALER"
end

function HealerMana:IsTrackedUnit(unit)
	return unit and isGroupUnit(unit) and self:IsHealer(unit)
end

function HealerMana:GetManaPercent(unit)
	local powerType = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
	if _G.UnitPowerPercent then return _G.UnitPowerPercent(unit, powerType, true, _G.CurveConstants and _G.CurveConstants.ScaleTo100) end
	return nil
end

function HealerMana:SetManaText(index, unit, overridePercent)
	local text = self:GetText(index)
	local percent = overridePercent or self:GetManaPercent(unit)
	if addon.db and addon.db[DB.healerShowName] == false then
		text:SetText(("%s%%"):format(formatPercentValue(percent)))
	else
		text:SetText(("%s%% - %s"):format(formatPercentValue(percent), self:FormatDisplayName(unit)))
	end
	text:Show()
end

function HealerMana:Update()
	local frame = self:EnsureFrame()
	self:ClearTexts()
	if not self:IsEnabled() then
		frame:Hide()
		return
	end

	local count = 0
	if isInEditMode() then
		self:SetManaText(1, "player", 69)
		self:SetManaText(2, "player", 50)
		count = 2
	elseif self:ShouldShowInCurrentInstance() then
		for _, unit in ipairs(getGroupUnits()) do
			if self:IsHealer(unit) then
				count = count + 1
				self:SetManaText(count, unit)
			end
		end
	end

	if count > 0 then
		self:PositionTexts(count)
		frame:Show()
	else
		frame:Hide()
	end
end

function HealerMana:OnEvent(event, unit, powerToken)
	if event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" or event == "UNIT_MAXPOWER" then
		if type(unit) ~= "string" then return end
		if not self:IsTrackedUnit(unit) then return end
		if not isManaPowerToken(powerToken) then return end
	end
	self:Update()
end

function HealerMana:OnSettingChanged()
	self:EnsureFrame()
	self:RegisterEditMode()
	self:UpdateWatcherEvents()
	self:ApplyStyle()
	self:Update()
	refreshEditModeFrame(EDITMODE_IDS.healerMana)
end

local DeathAlert = {}
GroupTools.DeathAlert = DeathAlert

function DeathAlert:IsEnabled()
	return addon.db and addon.db[DB.deathEnabled] == true
end

function DeathAlert:EnsureFrame()
	if self.frame then return self.frame end
	local frame = CreateFrame("Frame", "EQOLGroupToolsDeathAlert", UIParent)
	frame:SetSize(240, 36)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER")
	frame.text:SetJustifyH("CENTER")
	applyFontString(frame.text, getDB(DB.deathFontFace, globalFontKey()), clamp(getDB(DB.deathFontSize, 28), 10, 96, 28), getDB(DB.deathFontStyle, globalStyleKey()))
	frame:Hide()
	self.frame = frame
	return frame
end

function DeathAlert:EnsureWatcherFrame()
	if self.watcherFrame then return self.watcherFrame end
	local frame = CreateFrame("Frame")
	self.watcherFrame = frame
	return frame
end

function DeathAlert:UpdateWatcherEvents()
	local enabled = self:IsEnabled()
	if not enabled and not self.watcherFrame then return end
	local frame = self:EnsureWatcherFrame()
	if enabled then
		if self.eventsRegistered then return end
		self.onEvent = self.onEvent or function(...) DeathAlert:OnEvent(...) end
		frame:RegisterEvent("UNIT_DIED")
		frame:SetScript("OnEvent", self.onEvent)
		self.eventsRegistered = true
	elseif self.eventsRegistered then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		self.eventsRegistered = nil
	end
end

function DeathAlert:GetRoleConfig(role)
	if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER" then role = "DAMAGER" end
	addon.db[DB.deathRoleConfig] = type(addon.db[DB.deathRoleConfig]) == "table" and addon.db[DB.deathRoleConfig] or {}
	local cfg = addon.db[DB.deathRoleConfig][role]
	if type(cfg) ~= "table" then
		cfg = {}
		addon.db[DB.deathRoleConfig][role] = cfg
	end
	if cfg.textDisabled == nil then cfg.textDisabled = false end
	if cfg.soundEnabled == nil then cfg.soundEnabled = false end
	if cfg.ttsEnabled == nil then cfg.ttsEnabled = false end
	if cfg.sound == nil then cfg.sound = "" end
	if cfg.tts == nil then cfg.tts = "" end
	return cfg
end

function DeathAlert:ApplyStyle()
	local frame = self:EnsureFrame()
	local fontSize = clamp(getDB(DB.deathFontSize, 28), 10, 96, 28)
	local color = normalizeColor(getDB(DB.deathColor, { r = 1, g = 1, b = 1, a = 1 }), { r = 1, g = 1, b = 1, a = 1 })
	frame:SetFrameStrata(normalizeStrata(getDB(DB.deathStrata, "HIGH"), "HIGH"))
	frame.text:SetTextColor(color.r, color.g, color.b, color.a)
	frame.text:SetJustifyH("CENTER")
	applyFontString(frame.text, getDB(DB.deathFontFace, globalFontKey()), fontSize, getDB(DB.deathFontStyle, globalStyleKey()))
	frame:SetSize(DEATH_ALERT_FRAME_WIDTH, fontSize + 8)
end

function DeathAlert:GetDisplayMessage(role, coloredName, plainName)
	local name = coloredName or plainName or ROLE_LABELS[role] or ""
	local suffix = locale("groupToolsDeathAlertDefaultSuffix", "died")
	if type(suffix) ~= "string" or suffix == "" then return name end
	return name .. " " .. suffix
end

function DeathAlert:GetTTSVoice()
	return tonumber(getDB(DB.deathTTSVoice, TTS_VOICE_DEFAULT)) or TTS_VOICE_DEFAULT
end

function DeathAlert:GetTTSMessage(role, plainName)
	local roleCfg = self:GetRoleConfig(role)
	local tts = roleCfg.tts
	if type(tts) == "string" and tts ~= "" then return tts end
	return self:GetDisplayMessage(role, plainName, plainName)
end

function DeathAlert:HasRoleTTS()
	for _, role in ipairs(ROLE_ORDER) do
		if self:GetRoleConfig(role).ttsEnabled == true then return true end
	end
	return false
end

function DeathAlert:HideText()
	if self.hideTimer then
		self.hideTimer:Cancel()
		self.hideTimer = nil
	end
	if self.frame then self.frame:Hide() end
end

function DeathAlert:ShowText(message, keepVisible)
	local frame = self:EnsureFrame()
	frame.text:SetText(message or "")
	frame.text:SetAlpha(1)
	self:ApplyStyle()
	frame:Show()
	if self.hideTimer then
		self.hideTimer:Cancel()
		self.hideTimer = nil
	end
	if keepVisible or isInEditMode() then return end
	local duration = clamp(getDB(DB.deathDuration, 2), 0.5, 10, 2)
	self.hideTimer = C_Timer and C_Timer.NewTimer and C_Timer.NewTimer(duration, function() DeathAlert:HideText() end)
end

function DeathAlert:HandleDeath(guid)
	if not self:IsEnabled() then return end
	local unit = unitTokenFromGUID(guid)
	if not unit or not isGroupUnit(unit) then return end
	if _G.UnitIsFeignDeath and _G.UnitIsFeignDeath(unit) then return end
	if not UnitIsDeadOrGhost(unit) then return end

	local role = UnitGroupRolesAssigned(unit)
	if role ~= "TANK" and role ~= "HEALER" then role = "DAMAGER" end
	local roleCfg = self:GetRoleConfig(role)
	local coloredName, plainName = classColoredUnitName(unit)

	if addon.db[DB.deathShowText] == true and roleCfg.textDisabled ~= true then self:ShowText(self:GetDisplayMessage(role, coloredName or plainName or unit, plainName or unit)) end

	local now = GetTime()
	self.lastNotificationByGUID = self.lastNotificationByGUID or {}
	if self.lastNotificationByGUID[guid] and now - self.lastNotificationByGUID[guid] < 2 then return end
	local notified
	if roleCfg.soundEnabled == true then
		local soundKey = roleCfg.sound
		if type(soundKey) == "string" and soundKey ~= "" then
			playSharedMediaSound(soundKey)
			notified = true
		end
	end
	if roleCfg.ttsEnabled == true then
		speakText(self:GetTTSMessage(role, plainName or unit), addon.db[DB.deathTTSVolume], self:GetTTSVoice())
		notified = true
	end
	if notified then self.lastNotificationByGUID[guid] = now end
end

function DeathAlert:OnEvent(_, event, unitGUID)
	if event ~= "UNIT_DIED" then return end
	self:HandleDeath(unitGUID)
end

function DeathAlert:Preview()
	local coloredName, plainName = classColoredUnitName("player")
	plainName = plainName or UnitName("player") or _G.PLAYER or "Player"
	self:ShowText(self:GetDisplayMessage("DAMAGER", coloredName or plainName, plainName), true)
end

function DeathAlert:PreviewTTS()
	local plainName = UnitName("player") or _G.PLAYER or "Player"
	for _, role in ipairs(ROLE_ORDER) do
		if self:GetRoleConfig(role).ttsEnabled == true then
			speakText(self:GetTTSMessage(role, plainName), addon.db[DB.deathTTSVolume], self:GetTTSVoice())
			return
		end
	end
end

function DeathAlert:OnSettingChanged()
	self:EnsureFrame()
	self:RegisterEditMode()
	self:UpdateWatcherEvents()
	self:ApplyStyle()
	if isInEditMode() then
		self:Preview()
	elseif not self:IsEnabled() then
		self:HideText()
	end
	refreshEditModeFrame(EDITMODE_IDS.deathAlert)
end

local NoTarget = {}
GroupTools.NoTarget = NoTarget

function NoTarget:IsEnabled()
	return addon.db and addon.db[DB.noTargetEnabled] == true
end

function NoTarget:EnsureFrame()
	if self.frame then return self.frame end
	local frame = CreateFrame("Frame", "EQOLGroupToolsNoTarget", UIParent)
	frame:SetSize(160, 24)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER")
	frame.text:SetJustifyH("CENTER")
	applyFontString(frame.text, getDB(DB.noTargetFontFace, globalFontKey()), clamp(getDB(DB.noTargetFontSize, 18), 8, 96, 18), getDB(DB.noTargetFontStyle, globalStyleKey()))
	frame:Hide()
	self.frame = frame
	return frame
end

function NoTarget:EnsureWatcherFrame()
	if self.watcherFrame then return self.watcherFrame end
	local frame = CreateFrame("Frame")
	self.watcherFrame = frame
	return frame
end

function NoTarget:UpdateWatcherEvents()
	local enabled = self:IsEnabled()
	if not enabled and not self.watcherFrame then return end
	local frame = self:EnsureWatcherFrame()
	if enabled then
		if self.eventsRegistered then return end
		self.onEvent = self.onEvent or function() NoTarget:OnEvent() end
		frame:RegisterEvent("PLAYER_TARGET_CHANGED")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("UNIT_DIED")
		if frame.RegisterUnitEvent then
			frame:RegisterUnitEvent("UNIT_HEALTH", "target")
			frame:RegisterUnitEvent("UNIT_FLAGS", "target")
		else
			frame:RegisterEvent("UNIT_HEALTH")
			frame:RegisterEvent("UNIT_FLAGS")
		end
		frame:SetScript("OnEvent", self.onEvent)
		self.eventsRegistered = true
	elseif self.eventsRegistered then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		self.eventsRegistered = nil
	end
end

function NoTarget:ApplyStyle()
	local frame = self:EnsureFrame()
	local fontSize = clamp(getDB(DB.noTargetFontSize, 18), 8, 96, 18)
	local color = normalizeColor(getDB(DB.noTargetColor, { r = 0.769, g = 0.118, b = 0.227, a = 1 }), { r = 0.769, g = 0.118, b = 0.227, a = 1 })
	frame:SetFrameStrata(normalizeStrata(getDB(DB.noTargetStrata, "HIGH"), "HIGH"))
	frame.text:SetTextColor(color.r, color.g, color.b, color.a)
	frame.text:SetJustifyH("CENTER")
	applyFontString(frame.text, getDB(DB.noTargetFontFace, globalFontKey()), fontSize, getDB(DB.noTargetFontStyle, globalStyleKey()))
	frame:SetSize(NO_TARGET_FRAME_WIDTH, fontSize + 8)
end

function NoTarget:GetText()
	local text = getDB(DB.noTargetText, locale("groupToolsNoTargetDefaultText", "No target"))
	if type(text) ~= "string" or text == "" then text = locale("groupToolsNoTargetDefaultText", "No target") end
	return text
end

function NoTarget:IsMissingTarget()
	if not UnitAffectingCombat("player") then return false end
	if not UnitExists("target") then return true end
	if UnitIsDeadOrGhost("target") then return true end
	if UnitCanAttack("player", "target") then return false end
	return addon.db and addon.db[DB.noTargetFriendly] ~= true
end

function NoTarget:Update()
	local frame = self:EnsureFrame()
	if not self:IsEnabled() then
		self.missing = false
		frame:Hide()
		return
	end

	local missing = isInEditMode() or self:IsMissingTarget()
	if missing and addon.db[DB.noTargetShowText] == true then
		frame.text:SetText(self:GetText())
		self:ApplyStyle()
		frame:Show()
	else
		frame:Hide()
	end

	if not isInEditMode() and missing and not self.missing and addon.db[DB.noTargetPlaySound] == true then
		local now = GetTime()
		if not self.lastSoundAt or now - self.lastSoundAt > 3 then
			playSharedMediaSound(addon.db[DB.noTargetSound])
			self.lastSoundAt = now
		end
	end
	self.missing = missing
end

function NoTarget:OnEvent()
	self:Update()
end

function NoTarget:OnSettingChanged()
	self:EnsureFrame()
	self:RegisterEditMode()
	self:UpdateWatcherEvents()
	self:ApplyStyle()
	self:Update()
	refreshEditModeFrame(EDITMODE_IDS.noTarget)
end

local FocusMarker = {}
GroupTools.FocusMarker = FocusMarker

function FocusMarker:IsEnabled()
	return addon.db and addon.db[DB.focusMarkerEnabled] == true
end

function FocusMarker:EnsureWatcherFrame()
	if self.watcherFrame then return self.watcherFrame end
	local frame = CreateFrame("Frame")
	self.watcherFrame = frame
	return frame
end

function FocusMarker:UpdateWatcherEvents()
	local enabled = self:IsEnabled()
	if not enabled and not self.watcherFrame then return end
	local frame = self:EnsureWatcherFrame()
	if enabled then
		if self.eventsRegistered then return end
		self.onEvent = self.onEvent or function(...) FocusMarker:OnEvent(...) end
		frame:RegisterEvent("PLAYER_LOGIN")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("READY_CHECK")
		frame:SetScript("OnEvent", self.onEvent)
		self.eventsRegistered = true
	elseif self.eventsRegistered then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		self.eventsRegistered = nil
	end
end

function FocusMarker:GetMarker()
	local marker = tonumber(getDB(DB.focusMarker, 5)) or 5
	if marker < 1 or marker > 8 then marker = 5 end
	return marker
end

function FocusMarker:GetMarkerLabel(index)
	index = index or self:GetMarker()
	return _G["RAID_TARGET_" .. tostring(index)] or MARKER_TOKENS[index] or tostring(index)
end

function FocusMarker:GetMarkerIcon(index)
	index = index or self:GetMarker()
	local left = ((index - 1) % 4) * 0.25
	local right = left + 0.25
	local top = index <= 4 and 0 or 0.25
	local bottom = top + 0.25
	return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:16:16:0:0:256:256:%d:%d:%d:%d|t"):format(left * 256, right * 256, top * 256, bottom * 256)
end

function FocusMarker:GetMacroName()
	return "EQOLFocusMarker"
end

function FocusMarker:GetMacroBody()
	return ("/focus [@mouseover,harm,nodead][]\n/tm [@mouseover,harm,nodead][] %d"):format(self:GetMarker())
end

function FocusMarker:WriteMacro(showErrors)
	if not self:IsEnabled() then return false end
	if InCombatLockdown and InCombatLockdown() then
		self.pendingMacroUpdate = true
		if showErrors and UIErrorsFrame then UIErrorsFrame:AddMessage(locale("groupToolsFocusMarkerMacroCombat", "Focus marker macro updates after combat."), 1, 0, 0) end
		return false
	end
	local name = self:GetMacroName()
	local icon = 132219
	local body = self:GetMacroBody()
	local index = GetMacroIndexByName(name)
	if index and index > 0 then
		EditMacro(index, name, icon, body)
	else
		CreateMacro(name, icon, body, nil)
	end
	self.pendingMacroUpdate = nil
	return true
end

function FocusMarker:GetAnnounceMessage()
	local marker = self:GetMarker()
	local token = MARKER_TOKENS[marker] or "moon"
	local markerText = "{" .. token .. "}"
	local defaultTemplate = locale("groupToolsFocusMarkerReadyTemplate", "My focus marker: {%s}")
	local custom = getDB(DB.focusMarkerMessage, "")
	if type(custom) == "string" and custom ~= "" then
		custom = custom:gsub("{markerName}", self:GetMarkerLabel(marker))
		custom = custom:gsub("{marker}", "")
		custom = custom:gsub("^%s+", ""):gsub("%s+$", "")
		custom = custom:gsub("%s*:%s*$", "")
		if custom ~= "" then return custom .. ": " .. markerText end
	end
	return defaultTemplate:format(token)
end

function FocusMarker:Announce()
	if not self:IsEnabled() or addon.db[DB.focusMarkerAnnounce] ~= true then return end
	local inInstance, instanceType = IsInInstance()
	if not inInstance or instanceType ~= "party" then return end
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end
	local socialRestrictions = _G.C_SocialRestrictions
	if socialRestrictions and socialRestrictions.CanSendChat and not socialRestrictions.CanSendChat() then return end
	if C_ChatInfo and C_ChatInfo.SendChatMessage then
		C_ChatInfo.SendChatMessage(self:GetAnnounceMessage(), "PARTY")
	elseif _G.SendChatMessage then
		_G.SendChatMessage(self:GetAnnounceMessage(), "PARTY")
	end
end

function FocusMarker:OnEvent(_, event)
	if event == "READY_CHECK" then
		self:Announce()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.pendingMacroUpdate then self:WriteMacro(false) end
	else
		self:WriteMacro(false)
	end
end

function FocusMarker:OnSettingChanged(updateMacro)
	self:UpdateWatcherEvents()
	if updateMacro ~= false then self:WriteMacro(false) end
end

local function applyHealerSetting(field, value)
	if field == "dungeons" then
		setDB(DB.healerDungeons, value == true)
	elseif field == "raids" then
		setDB(DB.healerRaids, value == true)
	elseif field == "growUp" then
		setDB(DB.healerGrowUp, value == true)
	elseif field == "showName" then
		setDB(DB.healerShowName, value == true)
	elseif field == "nameMaxChars" then
		setDB(DB.healerNameMaxChars, clamp(value, 0, 100, 0))
	elseif field == "nameNoEllipsis" then
		setDB(DB.healerNameNoEllipsis, value == true)
	elseif field == "color" then
		setDB(DB.healerColor, normalizeColor(value, { r = 1, g = 1, b = 1, a = 1 }))
	elseif field == "fontFace" then
		setDB(DB.healerFontFace, type(value) == "string" and value ~= "" and value or globalFontKey())
	elseif field == "fontStyle" then
		setDB(DB.healerFontStyle, type(value) == "string" and value ~= "" and value or globalStyleKey())
	elseif field == "fontSize" then
		setDB(DB.healerFontSize, clamp(value, 8, 64, 14))
	elseif field == "strata" then
		setDB(DB.healerStrata, normalizeStrata(value, "MEDIUM"))
	end
	HealerMana:OnSettingChanged()
end

local function applyDeathSetting(field, value)
	if field == "showText" then
		setDB(DB.deathShowText, value == true)
	elseif field == "color" then
		setDB(DB.deathColor, normalizeColor(value, { r = 1, g = 1, b = 1, a = 1 }))
	elseif field == "duration" then
		setDB(DB.deathDuration, clamp(value, 0.5, 10, 2))
	elseif field == "fontFace" then
		setDB(DB.deathFontFace, type(value) == "string" and value ~= "" and value or globalFontKey())
	elseif field == "fontStyle" then
		setDB(DB.deathFontStyle, type(value) == "string" and value ~= "" and value or globalStyleKey())
	elseif field == "fontSize" then
		setDB(DB.deathFontSize, clamp(value, 10, 96, 28))
	elseif field == "strata" then
		setDB(DB.deathStrata, normalizeStrata(value, "HIGH"))
	elseif field == "ttsVoice" then
		setDB(DB.deathTTSVoice, tonumber(value) or TTS_VOICE_DEFAULT)
	elseif field == "ttsVolume" then
		setDB(DB.deathTTSVolume, clamp(value, 0, 100, 50))
	end
	DeathAlert:OnSettingChanged()
end

local function applyRoleDeathSetting(role, field, value)
	local cfg = DeathAlert:GetRoleConfig(role)
	if field == "textDisabled" then
		cfg.textDisabled = value == true
	elseif field == "soundEnabled" then
		cfg.soundEnabled = value == true
	elseif field == "sound" then
		cfg.sound = type(value) == "string" and value or ""
	elseif field == "ttsEnabled" then
		cfg.ttsEnabled = value == true
	elseif field == "tts" then
		cfg.tts = type(value) == "string" and value or ""
	end
	DeathAlert:OnSettingChanged()
end

local function applyNoTargetSetting(field, value)
	if field == "showText" then
		setDB(DB.noTargetShowText, value == true)
	elseif field == "text" then
		setDB(DB.noTargetText, type(value) == "string" and value or "")
	elseif field == "color" then
		setDB(DB.noTargetColor, normalizeColor(value, { r = 0.769, g = 0.118, b = 0.227, a = 1 }))
	elseif field == "fontFace" then
		setDB(DB.noTargetFontFace, type(value) == "string" and value ~= "" and value or globalFontKey())
	elseif field == "fontStyle" then
		setDB(DB.noTargetFontStyle, type(value) == "string" and value ~= "" and value or globalStyleKey())
	elseif field == "fontSize" then
		setDB(DB.noTargetFontSize, clamp(value, 8, 96, 18))
	elseif field == "strata" then
		setDB(DB.noTargetStrata, normalizeStrata(value, "HIGH"))
	elseif field == "friendly" then
		setDB(DB.noTargetFriendly, value == true)
	elseif field == "playSound" then
		setDB(DB.noTargetPlaySound, value == true)
	elseif field == "sound" then
		setDB(DB.noTargetSound, type(value) == "string" and value or "")
	end
	NoTarget:OnSettingChanged()
end

local function applyFocusSetting(field, value)
	if field == "marker" then
		local marker = tonumber(value) or 5
		if marker < 1 or marker > 8 then marker = 5 end
		setDB(DB.focusMarker, marker)
	elseif field == "announce" then
		setDB(DB.focusMarkerAnnounce, value == true)
	elseif field == "message" then
		setDB(DB.focusMarkerMessage, type(value) == "string" and value or "")
	end
	FocusMarker:OnSettingChanged()
end

function GroupTools.functions.SetFocusMarkerSetting(field, value)
	applyFocusSetting(field, value)
end

function HealerMana:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end
	local settings = createAnchorSettings({
		name = locale("groupToolsHealerManaEnableDungeons", "Enable in dungeons"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.healerDungeons] == true end,
		set = function(_, value) applyHealerSetting("dungeons", value) end,
	}, EDITMODE_IDS.healerMana, function() HealerMana:Update() end)
	settings[#settings + 1] = {
		name = locale("groupToolsHealerManaEnableRaids", "Enable in raids"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.healerRaids] == true end,
		set = function(_, value) applyHealerSetting("raids", value) end,
	}
	settings[#settings + 1] = {
		name = locale("groupToolsHealerManaGrowUpwards", "Grow upwards"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.healerGrowUp] == true end,
		set = function(_, value) applyHealerSetting("growUp", value) end,
	}
	settings[#settings + 1] = {
		name = locale("groupToolsHealerManaShowName", "Show name"),
		kind = SettingType.Checkbox,
		get = function() return not (addon.db and addon.db[DB.healerShowName] == false) end,
		set = function(_, value) applyHealerSetting("showName", value) end,
	}
	settings[#settings + 1] = {
		name = L["Name max width"] or "Name max width",
		kind = SettingType.Slider,
		minValue = 0,
		maxValue = 100,
		valueStep = 1,
		allowInput = true,
		get = function() return clamp(getDB(DB.healerNameMaxChars, 0), 0, 100, 0) end,
		set = function(_, value) applyHealerSetting("nameMaxChars", value) end,
		isEnabled = function() return not (addon.db and addon.db[DB.healerShowName] == false) end,
	}
	settings[#settings + 1] = {
		name = L["Hide ellipsis"] or "Hide ellipsis",
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.healerNameNoEllipsis] == true end,
		set = function(_, value) applyHealerSetting("nameNoEllipsis", value) end,
		isEnabled = function() return not (addon.db and addon.db[DB.healerShowName] == false) and clamp(getDB(DB.healerNameMaxChars, 0), 0, 100, 0) > 0 end,
	}
	settings[#settings + 1] = { name = "", kind = SettingType.Divider }
	settings[#settings + 1] = {
		name = L["Text color"] or "Text color",
		kind = SettingType.Color,
		hasOpacity = true,
		get = function() return normalizeColor(addon.db and addon.db[DB.healerColor], { r = 1, g = 1, b = 1, a = 1 }) end,
		set = function(_, value) applyHealerSetting("color", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Font"] or "Font", function() return getDB(DB.healerFontFace, globalFontKey()) end, function(value) applyHealerSetting("fontFace", value) end, buildFontFaceOptions, 220)
	settings[#settings + 1] = createDropdownSetting(L["Font outline"] or "Font outline", function() return getDB(DB.healerFontStyle, globalStyleKey()) end, function(value) applyHealerSetting("fontStyle", value) end, buildFontStyleOptions, 240)
	settings[#settings + 1] = {
		name = _G.FONT_SIZE or "Font size",
		kind = SettingType.Slider,
		minValue = 8,
		maxValue = 64,
		valueStep = 1,
		allowInput = true,
		get = function() return clamp(getDB(DB.healerFontSize, 14), 8, 64, 14) end,
		set = function(_, value) applyHealerSetting("fontSize", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Frame strata"] or "Frame strata", function() return normalizeStrata(getDB(DB.healerStrata, "MEDIUM"), "MEDIUM") end, function(value) applyHealerSetting("strata", value) end, buildStrataOptions, 180)

	EditMode:RegisterFrame(EDITMODE_IDS.healerMana, {
		frame = self:EnsureFrame(),
		title = locale("groupToolsHealerManaIndicator", "Healer Mana Indicator"),
		layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = -100, y = 50 },
		onApply = function() HealerMana:Update() end,
		onEnter = function() HealerMana:Update() end,
		onExit = function() runNextFrame(function() HealerMana:Update() end) end,
		isEnabled = function() return HealerMana:IsEnabled() end,
		settings = settings,
		showOutsideEditMode = false,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
	})
	self.editModeRegistered = true
end

function DeathAlert:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end
	local function textAlertsEnabled() return addon.db and addon.db[DB.deathShowText] == true end
	local settings = createAnchorSettings({
		name = locale("groupToolsDeathAlertShowText", "Show text alert"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.deathShowText] == true end,
		set = function(_, value) applyDeathSetting("showText", value) end,
	}, EDITMODE_IDS.deathAlert, function() DeathAlert:Preview() end)
	settings[#settings + 1] = {
		name = L["Text color"] or "Text color",
		kind = SettingType.Color,
		hasOpacity = true,
		get = function() return normalizeColor(addon.db and addon.db[DB.deathColor], { r = 1, g = 1, b = 1, a = 1 }) end,
		set = function(_, value) applyDeathSetting("color", value) end,
	}
	settings[#settings + 1] = {
		name = locale("groupToolsDisplayDuration", "Display duration"),
		kind = SettingType.Slider,
		minValue = 0.5,
		maxValue = 10,
		valueStep = 0.5,
		allowInput = true,
		get = function() return clamp(getDB(DB.deathDuration, 2), 0.5, 10, 2) end,
		set = function(_, value) applyDeathSetting("duration", value) end,
		formatter = function(value) return string.format("%.1fs", tonumber(value) or 0) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Font"] or "Font", function() return getDB(DB.deathFontFace, globalFontKey()) end, function(value) applyDeathSetting("fontFace", value) end, buildFontFaceOptions, 220)
	settings[#settings + 1] = createDropdownSetting(L["Font outline"] or "Font outline", function() return getDB(DB.deathFontStyle, globalStyleKey()) end, function(value) applyDeathSetting("fontStyle", value) end, buildFontStyleOptions, 240)
	settings[#settings + 1] = {
		name = _G.FONT_SIZE or "Font size",
		kind = SettingType.Slider,
		minValue = 10,
		maxValue = 96,
		valueStep = 1,
		allowInput = true,
		get = function() return clamp(getDB(DB.deathFontSize, 28), 10, 96, 28) end,
		set = function(_, value) applyDeathSetting("fontSize", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Frame strata"] or "Frame strata", function() return normalizeStrata(getDB(DB.deathStrata, "HIGH"), "HIGH") end, function(value) applyDeathSetting("strata", value) end, buildStrataOptions, 180)
	settings[#settings + 1] = { name = "", kind = SettingType.Divider }
	for _, role in ipairs(ROLE_ORDER) do
		local roleKey = role
		local roleSectionId = "groupToolsDeathAlert" .. roleKey
		local function roleSoundEnabled() return DeathAlert:GetRoleConfig(roleKey).soundEnabled == true end
		local function roleTTSEnabled() return DeathAlert:GetRoleConfig(roleKey).ttsEnabled == true end
		settings[#settings + 1] = { name = ROLE_LABELS[roleKey], kind = SettingType.Collapsible, id = roleSectionId, defaultCollapsed = true }
		settings[#settings + 1] = {
			name = (locale("groupToolsDeathAlertDisableTextFor", "Disable text for %s")):format(ROLE_LABELS[roleKey]),
			kind = SettingType.Checkbox,
			parentId = roleSectionId,
			get = function() return DeathAlert:GetRoleConfig(roleKey).textDisabled == true end,
			set = function(_, value) applyRoleDeathSetting(roleKey, "textDisabled", value) end,
			isEnabled = textAlertsEnabled,
		}
		settings[#settings + 1] = {
			name = locale("groupToolsPlaySound", "Play sound"),
			kind = SettingType.Checkbox,
			parentId = roleSectionId,
			get = function() return DeathAlert:GetRoleConfig(roleKey).soundEnabled == true end,
			set = function(_, value) applyRoleDeathSetting(roleKey, "soundEnabled", value) end,
		}
		local soundDropdown = createDropdownSetting(_G.SOUND or "Sound", function() return DeathAlert:GetRoleConfig(roleKey).sound or "" end, function(value) applyRoleDeathSetting(roleKey, "sound", value) end, function() return buildSoundOptions(true) end, 220)
		soundDropdown.parentId = roleSectionId
		soundDropdown.isEnabled = roleSoundEnabled
		settings[#settings + 1] = soundDropdown
		settings[#settings + 1] = {
			name = locale("groupToolsPlayTTS", "Play TTS"),
			kind = SettingType.Checkbox,
			parentId = roleSectionId,
			get = function() return DeathAlert:GetRoleConfig(roleKey).ttsEnabled == true end,
			set = function(_, value) applyRoleDeathSetting(roleKey, "ttsEnabled", value) end,
		}
		settings[#settings + 1] = {
			name = locale("groupToolsTTSMessage", "TTS message"),
			kind = SettingType.Input,
			parentId = roleSectionId,
			maxChars = 120,
			inputWidth = 220,
			get = function() return DeathAlert:GetRoleConfig(roleKey).tts or "" end,
			set = function(_, value) applyRoleDeathSetting(roleKey, "tts", value) end,
			isEnabled = roleTTSEnabled,
		}
	end
	settings[#settings + 1] = { name = "", kind = SettingType.Divider }
	local ttsVoiceDropdown = createDropdownSetting(
		locale("groupToolsTTSVoice", "TTS voice"),
		function() return DeathAlert:GetTTSVoice() end,
		function(value) applyDeathSetting("ttsVoice", value) end,
		buildTTSVoiceOptions,
		220
	)
	ttsVoiceDropdown.isEnabled = function() return DeathAlert:HasRoleTTS() end
	settings[#settings + 1] = ttsVoiceDropdown
	settings[#settings + 1] = {
		name = locale("groupToolsTTSVolume", "TTS volume"),
		kind = SettingType.Slider,
		minValue = 0,
		maxValue = 100,
		valueStep = 5,
		allowInput = true,
		get = function() return clamp(getDB(DB.deathTTSVolume, 50), 0, 100, 50) end,
		set = function(_, value) applyDeathSetting("ttsVolume", value) end,
		isEnabled = function() return DeathAlert:HasRoleTTS() end,
	}

	EditMode:RegisterFrame(EDITMODE_IDS.deathAlert, {
		frame = self:EnsureFrame(),
		title = locale("groupToolsDeathAlert", "Death Alert"),
		layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 },
		onApply = function() DeathAlert:ApplyStyle() end,
		onEnter = function() DeathAlert:Preview() end,
		onExit = function() runNextFrame(function() if not isInEditMode() then DeathAlert:HideText() end end) end,
		isEnabled = function() return DeathAlert:IsEnabled() end,
		settings = settings,
		showOutsideEditMode = false,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
		settingsMaxHeight = 520,
		buttons = {
			{
				text = locale("groupToolsPreviewTTS", "Preview TTS"),
				click = function() DeathAlert:PreviewTTS() end,
			},
		},
	})
	self.editModeRegistered = true
end

function NoTarget:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end
	local settings = createAnchorSettings({
		name = locale("groupToolsNoTargetShowText", "Show text"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.noTargetShowText] == true end,
		set = function(_, value) applyNoTargetSetting("showText", value) end,
	}, EDITMODE_IDS.noTarget, function() NoTarget:Update() end)
	settings[#settings + 1] = {
		name = locale("groupToolsDisplayText", "Display text"),
		kind = SettingType.Input,
		maxChars = 64,
		inputWidth = 180,
		get = function() return getDB(DB.noTargetText, locale("groupToolsNoTargetDefaultText", "No target")) end,
		set = function(_, value) applyNoTargetSetting("text", value) end,
	}
	settings[#settings + 1] = {
		name = L["Text color"] or "Text color",
		kind = SettingType.Color,
		hasOpacity = true,
		get = function() return normalizeColor(addon.db and addon.db[DB.noTargetColor], { r = 0.769, g = 0.118, b = 0.227, a = 1 }) end,
		set = function(_, value) applyNoTargetSetting("color", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Font"] or "Font", function() return getDB(DB.noTargetFontFace, globalFontKey()) end, function(value) applyNoTargetSetting("fontFace", value) end, buildFontFaceOptions, 220)
	settings[#settings + 1] = createDropdownSetting(L["Font outline"] or "Font outline", function() return getDB(DB.noTargetFontStyle, globalStyleKey()) end, function(value) applyNoTargetSetting("fontStyle", value) end, buildFontStyleOptions, 240)
	settings[#settings + 1] = {
		name = _G.FONT_SIZE or "Font size",
		kind = SettingType.Slider,
		minValue = 8,
		maxValue = 96,
		valueStep = 1,
		allowInput = true,
		get = function() return clamp(getDB(DB.noTargetFontSize, 18), 8, 96, 18) end,
		set = function(_, value) applyNoTargetSetting("fontSize", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(L["Frame strata"] or "Frame strata", function() return normalizeStrata(getDB(DB.noTargetStrata, "HIGH"), "HIGH") end, function(value) applyNoTargetSetting("strata", value) end, buildStrataOptions, 180)
	settings[#settings + 1] = { name = "", kind = SettingType.Divider }
	settings[#settings + 1] = {
		name = locale("groupToolsNoTargetFriendly", "Include friendly targets"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.noTargetFriendly] == true end,
		set = function(_, value) applyNoTargetSetting("friendly", value) end,
	}
	settings[#settings + 1] = {
		name = locale("groupToolsPlaySound", "Play sound"),
		kind = SettingType.Checkbox,
		get = function() return addon.db and addon.db[DB.noTargetPlaySound] == true end,
		set = function(_, value) applyNoTargetSetting("playSound", value) end,
	}
	settings[#settings + 1] = createDropdownSetting(_G.SOUND or "Sound", function() return getDB(DB.noTargetSound, "") end, function(value) applyNoTargetSetting("sound", value) end, function() return buildSoundOptions(true) end, 220)

	EditMode:RegisterFrame(EDITMODE_IDS.noTarget, {
		frame = self:EnsureFrame(),
		title = locale("groupToolsNoTargetIndicator", "No Target Indicator"),
		layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 25 },
		onApply = function() NoTarget:Update() end,
		onEnter = function() NoTarget:Update() end,
		onExit = function() runNextFrame(function() NoTarget:Update() end) end,
		isEnabled = function() return NoTarget:IsEnabled() end,
		settings = settings,
		showOutsideEditMode = false,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
	})
	self.editModeRegistered = true
end

function GroupTools.functions.InitDB()
	if not addon.db then return end
	initDBValue(DB.healerEnabled, false)
	initDBValue(DB.healerDungeons, true)
	initDBValue(DB.healerRaids, false)
	initDBValue(DB.healerGrowUp, false)
	initDBValue(DB.healerShowName, true)
	initDBValue(DB.healerNameMaxChars, 0)
	initDBValue(DB.healerNameNoEllipsis, false)
	initDBValue(DB.healerColor, { r = 1, g = 1, b = 1, a = 1 })
	initDBValue(DB.healerFontFace, globalFontKey())
	initDBValue(DB.healerFontStyle, globalStyleKey())
	initDBValue(DB.healerFontSize, 14)
	initDBValue(DB.healerStrata, "MEDIUM")

	initDBValue(DB.deathEnabled, false)
	initDBValue(DB.deathShowText, true)
	initDBValue(DB.deathColor, { r = 1, g = 1, b = 1, a = 1 })
	initDBValue(DB.deathDuration, 2)
	initDBValue(DB.deathFontFace, globalFontKey())
	initDBValue(DB.deathFontStyle, globalStyleKey())
	initDBValue(DB.deathFontSize, 28)
	initDBValue(DB.deathStrata, "HIGH")
	initDBValue(DB.deathTTSVoice, TTS_VOICE_DEFAULT)
	initDBValue(DB.deathTTSVolume, 50)
	initDBValue(DB.deathRoleConfig, {
		TANK = { textDisabled = false, soundEnabled = false, sound = "", ttsEnabled = false, tts = "" },
		HEALER = { textDisabled = false, soundEnabled = false, sound = "", ttsEnabled = false, tts = "" },
		DAMAGER = { textDisabled = false, soundEnabled = false, sound = "", ttsEnabled = false, tts = "" },
	})
	for _, role in ipairs(ROLE_ORDER) do
		DeathAlert:GetRoleConfig(role)
	end

	initDBValue(DB.noTargetEnabled, false)
	initDBValue(DB.noTargetShowText, true)
	initDBValue(DB.noTargetText, locale("groupToolsNoTargetDefaultText", "No target"))
	initDBValue(DB.noTargetColor, { r = 0.769, g = 0.118, b = 0.227, a = 1 })
	initDBValue(DB.noTargetFontFace, globalFontKey())
	initDBValue(DB.noTargetFontStyle, globalStyleKey())
	initDBValue(DB.noTargetFontSize, 18)
	initDBValue(DB.noTargetStrata, "HIGH")
	initDBValue(DB.noTargetFriendly, false)
	initDBValue(DB.noTargetPlaySound, false)
	initDBValue(DB.noTargetSound, "")

	initDBValue(DB.focusMarkerEnabled, false)
	initDBValue(DB.focusMarker, 5)
	initDBValue(DB.focusMarkerAnnounce, true)
	initDBValue(DB.focusMarkerMessage, "")
end

function GroupTools.functions.InitState()
	if HealerMana:IsEnabled() then HealerMana:OnSettingChanged() end
	if DeathAlert:IsEnabled() then DeathAlert:OnSettingChanged() end
	if NoTarget:IsEnabled() then NoTarget:OnSettingChanged() end
	if FocusMarker:IsEnabled() then FocusMarker:OnSettingChanged(false) end
end

function GroupTools.functions.SetFeatureEnabled(feature, enabled)
	if feature == "healerMana" then
		setDB(DB.healerEnabled, enabled == true)
		HealerMana:OnSettingChanged()
	elseif feature == "deathAlert" then
		setDB(DB.deathEnabled, enabled == true)
		DeathAlert:OnSettingChanged()
	elseif feature == "noTarget" then
		setDB(DB.noTargetEnabled, enabled == true)
		NoTarget:OnSettingChanged()
	elseif feature == "focusMarker" then
		setDB(DB.focusMarkerEnabled, enabled == true)
		FocusMarker:OnSettingChanged(enabled == true)
	end
end

function GroupTools.functions.RefreshGlobalFont()
	if HealerMana.frame then
		HealerMana:ApplyStyle()
		HealerMana:Update()
	end
	if DeathAlert.frame then DeathAlert:ApplyStyle() end
	if NoTarget.frame then
		NoTarget:ApplyStyle()
		NoTarget:Update()
	end
end
