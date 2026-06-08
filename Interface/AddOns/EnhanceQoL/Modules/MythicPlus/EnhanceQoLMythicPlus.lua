local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.variables = addon.MythicPlus.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local LSM = LibStub("LibSharedMedia-3.0")
local issecretvalue = _G.issecretvalue
local wipe = _G.wipe or (table and table.wipe)
local SharedAnchors = addon.SharedAnchors

local frameLoad = CreateFrame("Frame")

local brButton
local brAnchor
local bloodlustButton
local bloodlustAnchor
local defaultButtonSize = 60
local defaultFontSize = 16

local EditMode = addon.EditMode
local BR_EDITMODE_ID = "mythicPlusBRTracker"
local brEditModeRegistered = false
local BR_MIN_SIZE = 20
local BR_MAX_SIZE = 100

local BLOODLUST_EDITMODE_ID = "mythicPlusBloodlustTracker"
local bloodlustEditModeRegistered = false
local BLOODLUST_MIN_SIZE = 20
local BLOODLUST_MAX_SIZE = 100
local BLOODLUST_DEFAULT_ICON_IDS = {
	136090,
	458224,
	4723908,
	136224,
	132313,
	136012,
}
local BLOODLUST_DEFAULT_ICON_SET = {}
for i = 1, #BLOODLUST_DEFAULT_ICON_IDS do
	BLOODLUST_DEFAULT_ICON_SET[BLOODLUST_DEFAULT_ICON_IDS[i]] = true
end
local BLOODLUST_BORDER_SIZE_MIN = 1
local BLOODLUST_BORDER_SIZE_MAX = 24
local BLOODLUST_BORDER_OFFSET_MIN = -20
local BLOODLUST_BORDER_OFFSET_MAX = 20
local BLOODLUST_PREVIEW_COOLDOWN_TEXT = "12.3"
local BLOODLUST_COOLDOWN_TEXT_SIZE_MIN = 8
local BLOODLUST_COOLDOWN_TEXT_SIZE_MAX = 64
local BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN = -40
local BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX = 40
local BLOODLUST_COOLDOWN_OUTLINE_OPTIONS = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true) or {
	{ value = "NONE", label = NONE },
	{ value = "OUTLINE", label = L["Outline"] or "Outline" },
}
local BLOODLUST_COOLDOWN_OUTLINE_SET = {}
for i = 1, #BLOODLUST_COOLDOWN_OUTLINE_OPTIONS do
	local option = BLOODLUST_COOLDOWN_OUTLINE_OPTIONS[i]
	if option and option.value then BLOODLUST_COOLDOWN_OUTLINE_SET[option.value] = true end
end
local BLOODLUST_LOCKOUT_IDS = {
	57723, -- Exhaustion
	57724, -- Sated
	80354, -- Temporal Displacement
	95809, -- Hunter Pet Insanity
	160455, -- Hunter Pet Fatigued
	264689, -- Hunter Pet Fatigued
	390435, -- Exhaustion (declassified)
}
local BLOODLUST_LOCKOUT_SET = {}
for i = 1, #BLOODLUST_LOCKOUT_IDS do
	BLOODLUST_LOCKOUT_SET[BLOODLUST_LOCKOUT_IDS[i]] = true
end
local BLOODLUST_READY_SPELL_ID = 2825
local BLOODLUST_FALLBACK_ICON = BLOODLUST_DEFAULT_ICON_IDS[1]
local BLOODLUST_LOCKOUT_DURATION_SECONDS = 600
local BLOODLUST_ACTIVE_SOUND_GRACE_SECONDS = 10
local BLOODLUST_ACTIVE_SOUND_MIN_REMAINING = BLOODLUST_LOCKOUT_DURATION_SECONDS - BLOODLUST_ACTIVE_SOUND_GRACE_SECONDS
local BLOODLUST_DELVE_DIFFICULTY_ID = 208
local BLOODLUST_READY_CLASSES = {
	SHAMAN = true,
	HUNTER = true,
	MAGE = true,
	EVOKER = true,
}
local BLOODLUST_GLOBAL_FONT_KEY = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__"
local BLOODLUST_GLOBAL_FONT_LABEL = addon.functions and addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or "Use global font config"
local bloodlustTrackedAuraInstanceIDs = {}
local bloodlustStateActive = false
local bloodlustStateInitialized = false
local bloodlustCooldownDeferredApplyPending = false
local bloodlustUnitAuraRegistered = false
local BR_DEFAULT_ICON_IDS = {
	136080,
	134336,
	4726195,
	136143,
}
local BR_DEFAULT_ICON_SET = {}
for i = 1, #BR_DEFAULT_ICON_IDS do
	BR_DEFAULT_ICON_SET[BR_DEFAULT_ICON_IDS[i]] = true
end
local BR_DEFAULT_ICON = BR_DEFAULT_ICON_IDS[1]
local BR_BORDER_SIZE_MIN = BLOODLUST_BORDER_SIZE_MIN
local BR_BORDER_SIZE_MAX = BLOODLUST_BORDER_SIZE_MAX
local BR_BORDER_OFFSET_MIN = BLOODLUST_BORDER_OFFSET_MIN
local BR_BORDER_OFFSET_MAX = BLOODLUST_BORDER_OFFSET_MAX
local BR_TEXT_SIZE_MIN = BLOODLUST_COOLDOWN_TEXT_SIZE_MIN
local BR_TEXT_SIZE_MAX = BLOODLUST_COOLDOWN_TEXT_SIZE_MAX
local BR_TEXT_OFFSET_MIN = BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN
local BR_TEXT_OFFSET_MAX = BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX
local TRACKER_ICON_ZOOM_MIN = 0
local TRACKER_ICON_ZOOM_MAX = 45
local BR_PREVIEW_COOLDOWN_TEXT = BLOODLUST_PREVIEW_COOLDOWN_TEXT
local BR_PREVIEW_CHARGES_TEXT = "1"
local BR_DEFAULT_BORDER_COLOR = { 1, 1, 1, 1 }
local BR_DEFAULT_COOLDOWN_COLOR = { 1, 1, 1, 1 }
local BR_DEFAULT_CHARGES_COLOR = { 0, 1, 0, 1 }
local BR_TEXT_POINT_OPTIONS = {
	{ value = "TOPLEFT", label = "Top Left" },
	{ value = "TOP", label = "Top" },
	{ value = "TOPRIGHT", label = "Top Right" },
	{ value = "LEFT", label = "Left" },
	{ value = "CENTER", label = "Center" },
	{ value = "RIGHT", label = "Right" },
	{ value = "BOTTOMLEFT", label = "Bottom Left" },
	{ value = "BOTTOM", label = "Bottom" },
	{ value = "BOTTOMRIGHT", label = "Bottom Right" },
}
local BR_TEXT_POINT_SET = {}
for i = 1, #BR_TEXT_POINT_OPTIONS do
	BR_TEXT_POINT_SET[BR_TEXT_POINT_OPTIONS[i].value] = true
end
local brCooldownDeferredApplyPending = false

local function normalizeTrackerAnchorPoint(value, fallback)
	if SharedAnchors and SharedAnchors.NormalizePoint then return SharedAnchors:NormalizePoint(value, fallback or "CENTER") end
	local point = type(value) == "string" and string.upper(value) or nil
	if point and BR_TEXT_POINT_SET[point] then return point end
	local fallbackPoint = type(fallback) == "string" and string.upper(fallback) or "CENTER"
	if BR_TEXT_POINT_SET[fallbackPoint] then return fallbackPoint end
	return "CENTER"
end

local function getTrackerAnchorPointOptions()
	if SharedAnchors and SharedAnchors.GetAnchorPointOptions then return SharedAnchors:GetAnchorPointOptions() end
	return BR_TEXT_POINT_OPTIONS
end

local function getTrackerAnchorEntries(currentTarget)
	if SharedAnchors and SharedAnchors.GetEntries then return SharedAnchors:GetEntries(currentTarget, { includeCursor = false }) end
	return {
		{ key = "UIParent", label = "UIParent" },
	}
end

local function validateTrackerAnchorTarget(value, currentTarget)
	if SharedAnchors and SharedAnchors.ValidateTarget then return SharedAnchors:ValidateTarget(value, currentTarget, { includeCursor = false }) end
	return "UIParent"
end

local function resolveTrackerAnchorFrame(target)
	if SharedAnchors and SharedAnchors.ResolveFrame then return SharedAnchors:ResolveFrame(target) end
	return UIParent
end

local function trackerAnchorUsesUIParent(target)
	if SharedAnchors and SharedAnchors.IsUIParentTarget then return SharedAnchors:IsUIParentTarget(target) end
	return target == nil or target == "" or target == "UIParent"
end

local function getTrackerAnchorDefaults(target)
	if SharedAnchors and SharedAnchors.GetDefaultAnchorData then return SharedAnchors:GetDefaultAnchorData(target) end
	return {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0,
	}
end

local function getUserSelectedTrackerAnchorTargetDefaults(target)
	local defaults = getTrackerAnchorDefaults(target)
	defaults.x = 0
	defaults.y = 0
	return defaults
end

local function applyTrackerEditModeAnchorData(editModeId, target, defaults)
	if not (EditMode and EditMode.SetValue and defaults) then return end
	EditMode:SetValue(editModeId, "anchorTarget", target, nil, true)
	EditMode:SetValue(editModeId, "point", defaults.point, nil, true)
	EditMode:SetValue(editModeId, "relativePoint", defaults.relativePoint, nil, true)
	EditMode:SetValue(editModeId, "x", defaults.x, nil, true)
	EditMode:SetValue(editModeId, "y", defaults.y, nil, true)
	if EditMode.ApplyLayout then EditMode:ApplyLayout(editModeId) end
end

local function maybeScheduleTrackerAnchorRefresh(target)
	if SharedAnchors and SharedAnchors.MaybeScheduleRefresh then SharedAnchors:MaybeScheduleRefresh(target) end
end

local function trackerAnchorNeedsReapply(target)
	if trackerAnchorUsesUIParent(target) then return false end
	return resolveTrackerAnchorFrame(target) == UIParent
end

local function trackersNeedAnchorReapply()
	if not addon.db then return false end
	if addon.db["mythicPlusBRTrackerEnabled"] and trackerAnchorNeedsReapply(addon.db["mythicPlusBRTrackerRelativeFrame"]) then return true end
	if addon.db["mythicPlusBloodlustTrackerEnabled"] and trackerAnchorNeedsReapply(addon.db["mythicPlusBloodlustTrackerRelativeFrame"]) then return true end
	return false
end

local function trackerUsesAnchorTarget(dbKey, target)
	if not (addon.db and type(target) == "string" and target ~= "") then return false end
	local normalizeRelativeFrame = SharedAnchors and SharedAnchors.NormalizeRelativeFrame
	local normalizedTarget = normalizeRelativeFrame and SharedAnchors:NormalizeRelativeFrame(target) or target
	local currentTarget = addon.db[dbKey] or "UIParent"
	local normalizedCurrent = normalizeRelativeFrame and SharedAnchors:NormalizeRelativeFrame(currentTarget) or currentTarget
	return normalizedCurrent == normalizedTarget
end

local function cancelTrackerAnchorReapplyTicker()
	local variables = addon.MythicPlus and addon.MythicPlus.variables
	local ticker = variables and variables.trackerAnchorReapplyTicker or nil
	if ticker and ticker.Cancel then ticker:Cancel() end
	if variables then
		variables.trackerAnchorReapplyTicker = nil
		variables.trackerAnchorReapplyAttempts = nil
	end
end

local function normalizeBRSize(value)
	local size = tonumber(value) or defaultButtonSize
	size = math.floor(size + 0.5)
	if size < BR_MIN_SIZE then size = BR_MIN_SIZE end
	if size > BR_MAX_SIZE then size = BR_MAX_SIZE end
	return size
end

local function normalizeBRIcon(value)
	local iconId = tonumber(value)
	if iconId then
		iconId = math.floor(iconId + 0.5)
		if BR_DEFAULT_ICON_SET[iconId] then return iconId end
	end
	return BR_DEFAULT_ICON
end

local function getBRConfiguredIcon() return normalizeBRIcon(addon.db and addon.db["mythicPlusBRTrackerIcon"]) end

local function normalizeTrackerIconZoom(value)
	local zoom = tonumber(value) or 0
	zoom = math.floor(zoom + 0.5)
	if zoom < TRACKER_ICON_ZOOM_MIN then zoom = TRACKER_ICON_ZOOM_MIN end
	if zoom > TRACKER_ICON_ZOOM_MAX then zoom = TRACKER_ICON_ZOOM_MAX end
	return zoom
end

local function applyTrackerIconZoom(texture, zoom)
	if not texture then return end
	local inset = normalizeTrackerIconZoom(zoom) / 100
	texture:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
end

local function normalizeBRTextPoint(value, fallback)
	if type(value) == "string" and BR_TEXT_POINT_SET[value] then return value end
	return fallback or "CENTER"
end

local function normalizeBRTextSize(value, fallback)
	local size = tonumber(value) or fallback or defaultFontSize
	size = math.floor(size + 0.5)
	if size < BR_TEXT_SIZE_MIN then size = BR_TEXT_SIZE_MIN end
	if size > BR_TEXT_SIZE_MAX then size = BR_TEXT_SIZE_MAX end
	return size
end

local function normalizeBRTextOffset(value)
	local offset = tonumber(value) or 0
	offset = math.floor(offset + 0.5)
	if offset < BR_TEXT_OFFSET_MIN then offset = BR_TEXT_OFFSET_MIN end
	if offset > BR_TEXT_OFFSET_MAX then offset = BR_TEXT_OFFSET_MAX end
	return offset
end

local function normalizeBRTextOutline(value)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, "OUTLINE", true)
	end
	if type(value) == "string" and BLOODLUST_COOLDOWN_OUTLINE_SET[value] then return value end
	return "OUTLINE"
end

local function resolveTrackerFontFlags(value, fallback)
	if addon.functions and addon.functions.ResolveFontStyle then
		local _, flags = addon.functions.ResolveFontStyle(value, fallback or "OUTLINE")
		return flags
	end
	if addon.functions and addon.functions.GetFontFlagsForStyle then
		local flags = addon.functions.GetFontFlagsForStyle(value, fallback or "OUTLINE")
		if type(flags) == "string" then return flags end
	end
	local outline = value
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = fallback or "OUTLINE" end
	if outline == "__EQOL_GLOBAL_FONT_STYLE__" then outline = "OUTLINE" end
	if outline == "NONE" then return "" end
	if type(outline) == "string" and BLOODLUST_COOLDOWN_OUTLINE_SET[outline] then return outline end
	return fallback or "OUTLINE"
end

local function applyTrackerFontString(fontString, fontFace, fontSize, fontStyle, fallbackStyle)
	local fallback = addon.variables.defaultFont or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ApplyFontString then
		return addon.functions.ApplyFontString(fontString, fontFace, fontSize, fontStyle, fallback, fallbackStyle or "OUTLINE")
	end
	local flags = resolveTrackerFontFlags(fontStyle, fallbackStyle or "OUTLINE")
	local ok = fontString:SetFont(fontFace, fontSize, flags)
	if ok == false then ok = fontString:SetFont(fallback, fontSize, flags) end
	return ok
end

local function normalizeBRColor(value, defaultColor)
	local color = value
	if type(color) ~= "table" then color = defaultColor or BR_DEFAULT_COOLDOWN_COLOR end
	local r = tonumber(color.r or color[1]) or (defaultColor and defaultColor[1]) or 1
	local g = tonumber(color.g or color[2]) or (defaultColor and defaultColor[2]) or 1
	local b = tonumber(color.b or color[3]) or (defaultColor and defaultColor[3]) or 1
	local a = tonumber(color.a or color[4]) or (defaultColor and defaultColor[4]) or 1
	if r < 0 then r = 0 end
	if r > 1 then r = 1 end
	if g < 0 then g = 0 end
	if g > 1 then g = 1 end
	if b < 0 then b = 0 end
	if b > 1 then b = 1 end
	if a < 0 then a = 0 end
	if a > 1 then a = 1 end
	return { r, g, b, a }
end

local function normalizeBRFontFace(value)
	if type(value) ~= "string" or value == "" then return BLOODLUST_GLOBAL_FONT_KEY end
	if value == BLOODLUST_GLOBAL_FONT_KEY then return value end
	return value
end

local function resolveBRFontFace(dbKey)
	local configured = normalizeBRFontFace(addon.db and addon.db[dbKey])
	local fallback = (addon.functions and addon.functions.GetGlobalDefaultFontFace and addon.functions.GetGlobalDefaultFontFace())
		or (addon.functions and addon.functions.GetLocaleDefaultFontFace and addon.functions.GetLocaleDefaultFontFace())
		or addon.variables.defaultFont
		or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, fallback) end
	if configured == BLOODLUST_GLOBAL_FONT_KEY then return fallback end
	return configured
end

local function isLikelyBRFilePath(value)
	if type(value) ~= "string" or value == "" then return false end
	return value:find("/", 1, true) ~= nil or value:find("\\", 1, true) ~= nil
end

local function getBRCachedMediaHash(mediaType)
	if addon.functions and addon.functions.GetLSMMediaHash then
		local hash = addon.functions.GetLSMMediaHash(mediaType)
		if type(hash) == "table" then return hash end
	end
	if LSM and LSM.HashTable then
		local ok, hash = pcall(LSM.HashTable, LSM, mediaType)
		if ok and type(hash) == "table" then return hash end
	end
	return {}
end

local function getBRCachedMediaNames(mediaType)
	if addon.functions and addon.functions.GetLSMMediaNames then
		local names = addon.functions.GetLSMMediaNames(mediaType)
		if type(names) == "table" then return names end
	end

	local names = {}
	for name in pairs(getBRCachedMediaHash(mediaType)) do
		if type(name) == "string" and name ~= "" then names[#names + 1] = name end
	end
	table.sort(names, function(a, b)
		local al = string.lower(a)
		local bl = string.lower(b)
		if al == bl then return a < b end
		return al < bl
	end)
	return names
end

local function normalizeBRBorderTexture(value)
	if type(value) ~= "string" or value == "" then return "DEFAULT" end
	if value == "DEFAULT" or value == "SOLID" then return value end
	return value
end

local function resolveBRBorderTexture(value)
	local key = normalizeBRBorderTexture(value)
	if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	if isLikelyBRFilePath(key) then return key end
	if LSM and LSM.Fetch then
		local tex = LSM:Fetch("border", key, true)
		if tex then return tex end
	end
	return "Interface\\Buttons\\WHITE8x8"
end

local function normalizeBRBorderSize(value)
	local size = tonumber(value) or 1
	size = math.floor(size + 0.5)
	if size < BR_BORDER_SIZE_MIN then size = BR_BORDER_SIZE_MIN end
	if size > BR_BORDER_SIZE_MAX then size = BR_BORDER_SIZE_MAX end
	return size
end

local function normalizeBRBorderOffset(value)
	local offset = tonumber(value) or 0
	offset = math.floor(offset + 0.5)
	if offset < BR_BORDER_OFFSET_MIN then offset = BR_BORDER_OFFSET_MIN end
	if offset > BR_BORDER_OFFSET_MAX then offset = BR_BORDER_OFFSET_MAX end
	return offset
end

local function applyBRBorderFrame(frame, target, enabled, textureKey, borderSize, borderOffset, borderColor)
	if not frame or not target or not frame.SetBackdrop then return end
	if not enabled then
		frame:SetBackdrop(nil)
		frame:Hide()
		return
	end

	frame:SetBackdrop({
		edgeFile = resolveBRBorderTexture(textureKey),
		edgeSize = borderSize,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	frame:SetBackdropColor(0, 0, 0, 0)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", target, "TOPLEFT", -borderOffset, borderOffset)
	frame:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", borderOffset, -borderOffset)
	frame:Show()
end

local function syncTrackerTextOverlay(owner, overlay, border)
	if not (owner and overlay) then return end
	overlay:SetAllPoints(owner)
	overlay:SetFrameStrata(owner:GetFrameStrata())
	local level = owner:GetFrameLevel() or 0
	if border and border.GetFrameLevel then
		local borderLevel = border:GetFrameLevel()
		if type(borderLevel) == "number" and borderLevel > level then level = borderLevel end
	end
	overlay:SetFrameLevel(level + 1)
end

local function applyBRBorderVisualSettings()
	local db = addon.db or {}
	local enabled = db["mythicPlusBRTrackerBorderEnabled"] ~= false
	local textureKey = normalizeBRBorderTexture(db["mythicPlusBRTrackerBorderTexture"])
	local borderSize = normalizeBRBorderSize(db["mythicPlusBRTrackerBorderSize"])
	local borderOffset = normalizeBRBorderOffset(db["mythicPlusBRTrackerBorderOffset"])
	local borderColor = normalizeBRColor(db["mythicPlusBRTrackerBorderColor"], BR_DEFAULT_BORDER_COLOR)

	if brAnchor and brAnchor.previewBorder and brAnchor.previewIcon then
		applyBRBorderFrame(brAnchor.previewBorder, brAnchor.previewIcon, enabled, textureKey, borderSize, borderOffset, borderColor)
	end
	if brButton and brButton.border then applyBRBorderFrame(brButton.border, brButton, enabled, textureKey, borderSize, borderOffset, borderColor) end
	if brAnchor and brAnchor.textOverlay then syncTrackerTextOverlay(brAnchor, brAnchor.textOverlay, brAnchor.previewBorder) end
	if brButton and brButton.textOverlay then syncTrackerTextOverlay(brButton, brButton.textOverlay, brButton.border) end
end

local function applyBRCooldownTextStyle(fontString, anchorFrame, db)
	if not fontString or not anchorFrame then return end
	local fontFace = resolveBRFontFace("mythicPlusBRTrackerCooldownFontFace")
	local fontSize = normalizeBRTextSize(db["mythicPlusBRTrackerCooldownTextSize"], defaultFontSize)
	local outlineValue = normalizeBRTextOutline(db["mythicPlusBRTrackerCooldownTextOutline"])
	applyTrackerFontString(fontString, fontFace, fontSize, outlineValue, "OUTLINE")
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, outlineValue, "OUTLINE") end
	local color = normalizeBRColor(db["mythicPlusBRTrackerCooldownTextColor"], BR_DEFAULT_COOLDOWN_COLOR)
	fontString:SetTextColor(color[1], color[2], color[3], color[4])
	local point = normalizeBRTextPoint(db["mythicPlusBRTrackerCooldownTextPoint"], "CENTER")
	fontString:ClearAllPoints()
	fontString:SetPoint(
		point,
		anchorFrame,
		point,
		normalizeBRTextOffset(db["mythicPlusBRTrackerCooldownTextOffsetX"]),
		normalizeBRTextOffset(db["mythicPlusBRTrackerCooldownTextOffsetY"])
	)
end

local function applyBRLiveCooldownTextStyle(deferIfMissing)
	if not (brButton and brButton.cooldownFrame) then return false end
	local db = addon.db or {}
	local enabled = db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false
	local cooldown = brButton.cooldownFrame
	if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(not enabled) end

	local fontString = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if fontString then
		if enabled then
			applyBRCooldownTextStyle(fontString, cooldown, db)
			fontString:Show()
		else
			fontString:Hide()
		end
		return true
	end

	if enabled and deferIfMissing and not brCooldownDeferredApplyPending then
		brCooldownDeferredApplyPending = true
		RunNextFrame(function()
			brCooldownDeferredApplyPending = false
			if not (brButton and brButton.cooldownFrame) then return end
			local deferredCooldown = brButton.cooldownFrame
			if deferredCooldown.SetHideCountdownNumbers then deferredCooldown:SetHideCountdownNumbers(not (addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false)) end
			local deferredFontString = deferredCooldown.GetCountdownFontString and deferredCooldown:GetCountdownFontString()
			if not deferredFontString then return end
			if addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false then
				applyBRCooldownTextStyle(deferredFontString, deferredCooldown, addon.db or {})
				deferredFontString:Show()
			else
				deferredFontString:Hide()
			end
		end)
	end

	return false
end

local function updateBRChargesDisplay(current, maxCharges)
	if not (brButton and brButton.charges) then return end
	brButton.currentCharges = current
	brButton.maxCharges = maxCharges

	if current == nil then
		brButton.charges:SetText("")
		brButton.charges:Hide()
		return
	end

	local enabled = addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false
	local displayText = current
	if issecretvalue and issecretvalue(current) and C_StringUtil and C_StringUtil.TruncateWhenZero then displayText = C_StringUtil.TruncateWhenZero(current) end
	brButton.charges:SetText(displayText)
	if not enabled then
		brButton.charges:Hide()
		return
	end

	local color = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerChargesTextColor"], BR_DEFAULT_CHARGES_COLOR)
	brButton.charges:SetTextColor(color[1], color[2], color[3], color[4])
	if issecretvalue and issecretvalue(current) then
		brButton.charges:Show()
		return
	end

	local currentValue = tonumber(current)
	local maxValue = tonumber(maxCharges)
	if currentValue and maxValue and currentValue < maxValue and currentValue <= 0 then
		brButton.charges:Hide()
	else
		brButton.charges:Show()
	end
end

local function applyBRCooldownVisualSettings()
	local db = addon.db or {}
	if brButton and brButton.cooldownFrame then
		local cooldown = brButton.cooldownFrame
		if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(db["mythicPlusBRTrackerCooldownDrawSwipe"] ~= false) end
		if cooldown.SetDrawEdge then cooldown:SetDrawEdge(db["mythicPlusBRTrackerCooldownDrawEdge"] == true) end
		if cooldown.SetDrawBling then cooldown:SetDrawBling(db["mythicPlusBRTrackerCooldownDrawBling"] == true) end
		applyBRLiveCooldownTextStyle(true)
	end
	if brAnchor and brAnchor.previewCooldownText and brAnchor.previewIcon then
		applyBRCooldownTextStyle(brAnchor.previewCooldownText, brAnchor.previewIcon, db)
		brAnchor.previewCooldownText:SetText(BR_PREVIEW_COOLDOWN_TEXT)
		if db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false then
			brAnchor.previewCooldownText:Show()
		else
			brAnchor.previewCooldownText:Hide()
		end
	end
end

local function applyBRChargesTextStyle(fontString, anchorFrame, db)
	if not fontString or not anchorFrame then return end
	local fontFace = resolveBRFontFace("mythicPlusBRTrackerChargesFontFace")
	local fontSize = normalizeBRTextSize(db["mythicPlusBRTrackerChargesTextSize"], defaultFontSize)
	local outlineValue = normalizeBRTextOutline(db["mythicPlusBRTrackerChargesTextOutline"])
	applyTrackerFontString(fontString, fontFace, fontSize, outlineValue, "OUTLINE")
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, outlineValue, "OUTLINE") end
	local color = normalizeBRColor(db["mythicPlusBRTrackerChargesTextColor"], BR_DEFAULT_CHARGES_COLOR)
	fontString:SetTextColor(color[1], color[2], color[3], color[4])
	local point = normalizeBRTextPoint(db["mythicPlusBRTrackerChargesTextPoint"], "BOTTOMRIGHT")
	fontString:ClearAllPoints()
	fontString:SetPoint(
		point,
		anchorFrame,
		point,
		normalizeBRTextOffset(db["mythicPlusBRTrackerChargesTextOffsetX"]),
		normalizeBRTextOffset(db["mythicPlusBRTrackerChargesTextOffsetY"])
	)
end

local function applyBRChargesVisualSettings()
	local db = addon.db or {}
	if brButton and brButton.charges then
		applyBRChargesTextStyle(brButton.charges, brButton, db)
		updateBRChargesDisplay(brButton.currentCharges, brButton.maxCharges)
	end
	if brAnchor and brAnchor.previewCharges and brAnchor.previewIcon then
		applyBRChargesTextStyle(brAnchor.previewCharges, brAnchor.previewIcon, db)
		brAnchor.previewCharges:SetText(BR_PREVIEW_CHARGES_TEXT)
		if db["mythicPlusBRTrackerChargesEnabled"] ~= false then
			brAnchor.previewCharges:Show()
		else
			brAnchor.previewCharges:Hide()
		end
	end
end

local function refreshBRMedia(mediaType)
	if mediaType == "border" then
		applyBRBorderVisualSettings()
	elseif mediaType == "font" then
		applyBRCooldownVisualSettings()
		applyBRChargesVisualSettings()
	end
end

addon.MythicPlus.functions.refreshBRMedia = refreshBRMedia

local function removeBRFrame()
	if brButton then
		brCooldownDeferredApplyPending = false
		brButton:Hide()
		brButton:SetParent(nil)
		brButton:SetScript("OnClick", nil)
		brButton:SetScript("OnEnter", nil)
		brButton:SetScript("OnLeave", nil)
		brButton:SetScript("OnUpdate", nil)
		brButton:SetScript("OnEvent", nil)
		brButton:SetScript("OnDragStart", nil)
		brButton:SetScript("OnDragStop", nil)
		brButton:UnregisterAllEvents()
		brButton:ClearAllPoints()
		brButton = nil
	end
end

local function isRaidDifficulty(d) return d == 14 or d == 15 or d == 16 or d == 17 end

local function safeRegisterUnitEvent(frame, event, ...)
	if not frame or not frame.RegisterUnitEvent or type(event) ~= "string" then return false end
	local ok = pcall(frame.RegisterUnitEvent, frame, event, ...)
	return ok
end

local function setFrameClickThrough(frame)
	if not frame then return end
	frame:EnableMouse(false)
	if frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(false) end
	if frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(false) end
end

local function syncBloodlustUnitAuraRegistration()
	local enabled = addon and addon.db and addon.db["mythicPlusBloodlustTrackerEnabled"] == true

	if enabled then
		if bloodlustUnitAuraRegistered then return end
		bloodlustUnitAuraRegistered = safeRegisterUnitEvent(frameLoad, "UNIT_AURA", "player") == true
		return
	end

	if not bloodlustUnitAuraRegistered then return end
	frameLoad:UnregisterEvent("UNIT_AURA")
	bloodlustUnitAuraRegistered = false
end

local function buildBRLayoutSnapshot()
	local currentTarget = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent"
	local relativeFrame = validateTrackerAnchorTarget(currentTarget, currentTarget)
	local point = normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerPoint"], "CENTER")
	return {
		point = point,
		relativePoint = normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerRelativePoint"] or point, point),
		anchorTarget = relativeFrame,
		x = addon.db["mythicPlusBRTrackerX"] or 0,
		y = addon.db["mythicPlusBRTrackerY"] or 0,
		size = normalizeBRSize(addon.db["mythicPlusBRButtonSize"] or defaultButtonSize),
	}
end

local function seedBREditModeRecordFromProfile(record)
	if type(record) ~= "table" then return end
	local snapshot = buildBRLayoutSnapshot()
	record.point = snapshot.point or "CENTER"
	record.relativePoint = snapshot.relativePoint or record.point
	record.anchorTarget = snapshot.anchorTarget or "UIParent"
	record.x = snapshot.x or 0
	record.y = snapshot.y or 0
	record.size = snapshot.size or defaultButtonSize
end

local function applyBRLayoutData(data)
	local config = data or buildBRLayoutSnapshot()
	local currentTarget = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent"
	local relativeFrame = validateTrackerAnchorTarget(config.anchorTarget or config.relativeFrame or currentTarget, currentTarget)
	local point = normalizeTrackerAnchorPoint(config.point or addon.db["mythicPlusBRTrackerPoint"], "CENTER")
	local relativePoint = normalizeTrackerAnchorPoint(config.relativePoint or addon.db["mythicPlusBRTrackerRelativePoint"] or point, point)
	local x = config.x
	if x == nil then x = addon.db["mythicPlusBRTrackerX"] or 0 end
	local y = config.y
	if y == nil then y = addon.db["mythicPlusBRTrackerY"] or 0 end
	local size = normalizeBRSize(addon.db["mythicPlusBRButtonSize"] or config.size or defaultButtonSize)
	local iconId = normalizeBRIcon(addon.db["mythicPlusBRTrackerIcon"])
	local iconZoom = normalizeTrackerIconZoom(addon.db["mythicPlusBRTrackerIconZoom"])
	local borderEnabled = addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false
	local borderTexture = normalizeBRBorderTexture(addon.db["mythicPlusBRTrackerBorderTexture"])
	local borderSize = normalizeBRBorderSize(addon.db["mythicPlusBRTrackerBorderSize"])
	local borderOffset = normalizeBRBorderOffset(addon.db["mythicPlusBRTrackerBorderOffset"])
	local borderColor = normalizeBRColor(addon.db["mythicPlusBRTrackerBorderColor"], BR_DEFAULT_BORDER_COLOR)
	local cooldownTextEnabled = addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false
	local cooldownDrawSwipe = addon.db["mythicPlusBRTrackerCooldownDrawSwipe"] ~= false
	local cooldownDrawEdge = addon.db["mythicPlusBRTrackerCooldownDrawEdge"] == true
	local cooldownDrawBling = addon.db["mythicPlusBRTrackerCooldownDrawBling"] == true
	local cooldownFontFace = normalizeBRFontFace(addon.db["mythicPlusBRTrackerCooldownFontFace"])
	local cooldownTextSize = normalizeBRTextSize(addon.db["mythicPlusBRTrackerCooldownTextSize"], defaultFontSize)
	local cooldownTextOutline = normalizeBRTextOutline(addon.db["mythicPlusBRTrackerCooldownTextOutline"])
	local cooldownTextColor = normalizeBRColor(addon.db["mythicPlusBRTrackerCooldownTextColor"], BR_DEFAULT_COOLDOWN_COLOR)
	local cooldownTextPoint = normalizeBRTextPoint(addon.db["mythicPlusBRTrackerCooldownTextPoint"], "CENTER")
	local cooldownTextOffsetX = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetX"])
	local cooldownTextOffsetY = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetY"])
	local chargesEnabled = addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false
	local chargesFontFace = normalizeBRFontFace(addon.db["mythicPlusBRTrackerChargesFontFace"])
	local chargesTextSize = normalizeBRTextSize(addon.db["mythicPlusBRTrackerChargesTextSize"], defaultFontSize)
	local chargesTextOutline = normalizeBRTextOutline(addon.db["mythicPlusBRTrackerChargesTextOutline"])
	local chargesTextColor = normalizeBRColor(addon.db["mythicPlusBRTrackerChargesTextColor"], BR_DEFAULT_CHARGES_COLOR)
	local chargesTextPoint = normalizeBRTextPoint(addon.db["mythicPlusBRTrackerChargesTextPoint"], "BOTTOMRIGHT")
	local chargesTextOffsetX = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetX"])
	local chargesTextOffsetY = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetY"])

	if addon.db then
		addon.db["mythicPlusBRTrackerPoint"] = point
		addon.db["mythicPlusBRTrackerRelativePoint"] = relativePoint
		addon.db["mythicPlusBRTrackerRelativeFrame"] = relativeFrame
		addon.db["mythicPlusBRTrackerX"] = x
		addon.db["mythicPlusBRTrackerY"] = y
		addon.db["mythicPlusBRButtonSize"] = size
		addon.db["mythicPlusBRTrackerIcon"] = iconId
		addon.db["mythicPlusBRTrackerIconZoom"] = iconZoom
		addon.db["mythicPlusBRTrackerBorderEnabled"] = borderEnabled
		addon.db["mythicPlusBRTrackerBorderTexture"] = borderTexture
		addon.db["mythicPlusBRTrackerBorderSize"] = borderSize
		addon.db["mythicPlusBRTrackerBorderOffset"] = borderOffset
		addon.db["mythicPlusBRTrackerBorderColor"] = borderColor
		addon.db["mythicPlusBRTrackerCooldownTextEnabled"] = cooldownTextEnabled
		addon.db["mythicPlusBRTrackerCooldownDrawSwipe"] = cooldownDrawSwipe
		addon.db["mythicPlusBRTrackerCooldownDrawEdge"] = cooldownDrawEdge
		addon.db["mythicPlusBRTrackerCooldownDrawBling"] = cooldownDrawBling
		addon.db["mythicPlusBRTrackerCooldownFontFace"] = cooldownFontFace
		addon.db["mythicPlusBRTrackerCooldownTextSize"] = cooldownTextSize
		addon.db["mythicPlusBRTrackerCooldownTextOutline"] = cooldownTextOutline
		addon.db["mythicPlusBRTrackerCooldownTextColor"] = cooldownTextColor
		addon.db["mythicPlusBRTrackerCooldownTextPoint"] = cooldownTextPoint
		addon.db["mythicPlusBRTrackerCooldownTextOffsetX"] = cooldownTextOffsetX
		addon.db["mythicPlusBRTrackerCooldownTextOffsetY"] = cooldownTextOffsetY
		addon.db["mythicPlusBRTrackerChargesEnabled"] = chargesEnabled
		addon.db["mythicPlusBRTrackerChargesFontFace"] = chargesFontFace
		addon.db["mythicPlusBRTrackerChargesTextSize"] = chargesTextSize
		addon.db["mythicPlusBRTrackerChargesTextOutline"] = chargesTextOutline
		addon.db["mythicPlusBRTrackerChargesTextColor"] = chargesTextColor
		addon.db["mythicPlusBRTrackerChargesTextPoint"] = chargesTextPoint
		addon.db["mythicPlusBRTrackerChargesTextOffsetX"] = chargesTextOffsetX
		addon.db["mythicPlusBRTrackerChargesTextOffsetY"] = chargesTextOffsetY
	end

	local resolvedAnchorFrame = resolveTrackerAnchorFrame(relativeFrame)
	maybeScheduleTrackerAnchorRefresh(relativeFrame)

	if brAnchor then
		brAnchor:SetSize(size, size)
		brAnchor:ClearAllPoints()
		brAnchor:SetPoint(point, resolvedAnchorFrame, relativePoint, x, y)
		if brAnchor.previewIcon then
			brAnchor.previewIcon:SetAllPoints(brAnchor)
			brAnchor.previewIcon:SetTexture(iconId)
			applyTrackerIconZoom(brAnchor.previewIcon, iconZoom)
		end
	end

	if brButton then
		brButton:SetSize(size, size)
		brButton:ClearAllPoints()
		brButton:SetPoint(point, resolvedAnchorFrame, relativePoint, x, y)
		if brButton.cooldownFrame then brButton.cooldownFrame:SetScale(1) end
		if brButton.icon then
			brButton.icon:SetTexture(iconId)
			applyTrackerIconZoom(brButton.icon, iconZoom)
		end
	end

	applyBRBorderVisualSettings()
	applyBRCooldownVisualSettings()
	applyBRChargesVisualSettings()
	if trackerAnchorNeedsReapply(relativeFrame)
		and not (addon.MythicPlus and addon.MythicPlus.variables and addon.MythicPlus.variables.trackerAnchorReapplyBusy)
		and addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.ScheduleTrackerAnchorReapply
	then
		addon.MythicPlus.functions.ScheduleTrackerAnchorReapply("BR")
	end
end

local function ensureBRAnchor()
	if not brAnchor then
		brAnchor = CreateFrame("Frame", "EnhanceQoLMythicPlusBRAnchor", UIParent)
		brAnchor:SetClampedToScreen(true)
		brAnchor:SetMovable(true)
		brAnchor:EnableMouse(true)

		local bg = brAnchor:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.5)
		brAnchor.bg = bg

		brAnchor.previewIcon = brAnchor:CreateTexture(nil, "ARTWORK")
		brAnchor.previewIcon:SetAllPoints(brAnchor)
		brAnchor.previewIcon:SetTexture(getBRConfiguredIcon())
		applyTrackerIconZoom(brAnchor.previewIcon, addon.db and addon.db["mythicPlusBRTrackerIconZoom"])

		brAnchor.previewBorder = CreateFrame("Frame", nil, brAnchor, "BackdropTemplate")
		brAnchor.previewBorder:SetFrameLevel((brAnchor:GetFrameLevel() or 0) + 4)
		brAnchor.previewBorder:SetFrameStrata(brAnchor:GetFrameStrata())

		brAnchor.textOverlay = CreateFrame("Frame", nil, brAnchor)
		brAnchor.textOverlay:SetAllPoints(brAnchor)
		brAnchor.textOverlay:EnableMouse(false)

		brAnchor.previewCooldownText = brAnchor.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		brAnchor.previewCooldownText:SetPoint("CENTER", brAnchor, "CENTER", 0, 0)
		brAnchor.previewCooldownText:SetText(BR_PREVIEW_COOLDOWN_TEXT)

		brAnchor.previewCharges = brAnchor.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		brAnchor.previewCharges:SetPoint("BOTTOMRIGHT", brAnchor, "BOTTOMRIGHT", -3, 3)
		brAnchor.previewCharges:SetText(BR_PREVIEW_CHARGES_TEXT)

		brAnchor.label = brAnchor.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		brAnchor.label:SetPoint("CENTER")
		brAnchor.label:SetText(L["mythicPlusBRTrackerAnchor"])
		brAnchor.label:SetAlpha(0)
	end

	if EditMode and not brEditModeRegistered then
		local settingType = EditMode.lib and EditMode.lib.SettingType
		local settings
		if settingType then
			local function buildBorderEntries()
				local entries = {
					{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
					{ value = "SOLID", label = "Solid" },
				}
				local names = getBRCachedMediaNames("border")
				for i = 1, #names do
					local name = names[i]
					entries[#entries + 1] = { value = name, label = name }
				end
				return entries
			end

			local function getStoredFontKey(dbKey)
				local entries = getBRCachedMediaNames("font")
				local fontTable = getBRCachedMediaHash("font")
				local current = normalizeBRFontFace(addon.db and addon.db[dbKey])
				if current ~= BLOODLUST_GLOBAL_FONT_KEY and not (fontTable and fontTable[current]) and not isLikelyBRFilePath(current) then current = BLOODLUST_GLOBAL_FONT_KEY end
				return current, entries
			end

			local function setStoredFontKey(dbKey, value, applyFunc)
				if addon.db then addon.db[dbKey] = normalizeBRFontFace(value) end
				applyFunc()
			end

			local function outlineOptionLabel(value)
				if addon.functions and addon.functions.GetFontStyleLabel then return addon.functions.GetFontStyleLabel(value) end
				return value
			end

			settings = {
				{
					name = L["Anchor"] or "Anchor",
					kind = settingType.Collapsible,
					id = "mythicPlusBRTrackerAnchor",
					defaultCollapsed = false,
				},
				{
					field = "anchorTarget",
					name = L["Anchor to"] or "Anchor to",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerAnchor",
					height = 220,
					default = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent",
					get = function()
						return validateTrackerAnchorTarget(addon.db["mythicPlusBRTrackerRelativeFrame"], addon.db["mythicPlusBRTrackerRelativeFrame"])
					end,
					set = function(_, value)
						local current = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent"
						local target = validateTrackerAnchorTarget(value, current)
						local defaults = getUserSelectedTrackerAnchorTargetDefaults(target)
						addon.db["mythicPlusBRTrackerRelativeFrame"] = target
						addon.db["mythicPlusBRTrackerPoint"] = defaults.point
						addon.db["mythicPlusBRTrackerRelativePoint"] = defaults.relativePoint
						addon.db["mythicPlusBRTrackerX"] = defaults.x
						addon.db["mythicPlusBRTrackerY"] = defaults.y
						applyTrackerEditModeAnchorData(BR_EDITMODE_ID, target, defaults)
						applyBRLayoutData({
							anchorTarget = target,
							point = defaults.point,
							relativePoint = defaults.relativePoint,
							x = defaults.x,
							y = defaults.y,
						})
						if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
							addon.EditModeLib.internal:RefreshSettingValues()
						end
						if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BR_EDITMODE_ID) end
					end,
					generator = function(_, root)
						local entries = getTrackerAnchorEntries(addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent")
						local current = validateTrackerAnchorTarget(addon.db["mythicPlusBRTrackerRelativeFrame"], addon.db["mythicPlusBRTrackerRelativeFrame"])
						for i = 1, #entries do
							local entry = entries[i]
							root:CreateRadio(entry.label, function() return current == entry.key end, function()
								local currentTarget = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent"
								local target = validateTrackerAnchorTarget(entry.key, currentTarget)
								local defaults = getUserSelectedTrackerAnchorTargetDefaults(target)
								addon.db["mythicPlusBRTrackerRelativeFrame"] = target
								addon.db["mythicPlusBRTrackerPoint"] = defaults.point
								addon.db["mythicPlusBRTrackerRelativePoint"] = defaults.relativePoint
								addon.db["mythicPlusBRTrackerX"] = defaults.x
								addon.db["mythicPlusBRTrackerY"] = defaults.y
								applyTrackerEditModeAnchorData(BR_EDITMODE_ID, target, defaults)
								applyBRLayoutData({
									anchorTarget = target,
									point = defaults.point,
									relativePoint = defaults.relativePoint,
									x = defaults.x,
									y = defaults.y,
								})
								if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
									addon.EditModeLib.internal:RefreshSettingValues()
								end
								if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BR_EDITMODE_ID) end
							end)
						end
					end,
				},
				{
					field = "point",
					name = L["Anchor point"] or "Anchor point",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerAnchor",
					height = 180,
					default = normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerPoint"], "CENTER"),
					get = function() return normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerPoint"], "CENTER") end,
					set = function(_, value)
						if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "point", value, nil, true) end
						applyBRLayoutData({ point = value })
					end,
					generator = function(_, root)
						local options = getTrackerAnchorPointOptions()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(option.label, function() return normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerPoint"], "CENTER") == option.value end, function()
								if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "point", option.value, nil, true) end
								applyBRLayoutData({ point = option.value })
							end)
						end
					end,
				},
				{
					field = "relativePoint",
					name = L["Relative point"] or "Relative point",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerAnchor",
					height = 180,
					default = normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerRelativePoint"] or addon.db["mythicPlusBRTrackerPoint"], "CENTER"),
					get = function()
						return normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerRelativePoint"] or addon.db["mythicPlusBRTrackerPoint"], addon.db["mythicPlusBRTrackerPoint"] or "CENTER")
					end,
					set = function(_, value)
						if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "relativePoint", value, nil, true) end
						applyBRLayoutData({ relativePoint = value })
					end,
					generator = function(_, root)
						local options = getTrackerAnchorPointOptions()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(
								option.label,
								function()
									return normalizeTrackerAnchorPoint(addon.db["mythicPlusBRTrackerRelativePoint"] or addon.db["mythicPlusBRTrackerPoint"], addon.db["mythicPlusBRTrackerPoint"] or "CENTER") == option.value
								end,
								function()
									if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "relativePoint", option.value, nil, true) end
									applyBRLayoutData({ relativePoint = option.value })
								end
							)
						end
					end,
				},
				{
					field = "x",
					name = L["X Offset"] or "X Offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerAnchor",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					default = addon.db["mythicPlusBRTrackerX"] or 0,
					get = function() return addon.db["mythicPlusBRTrackerX"] or 0 end,
					set = function(_, value)
						local x = tonumber(value) or 0
						if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "x", x, nil, true) end
						applyBRLayoutData({ x = x })
					end,
				},
				{
					field = "y",
					name = L["Y Offset"] or "Y Offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerAnchor",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					default = addon.db["mythicPlusBRTrackerY"] or 0,
					get = function() return addon.db["mythicPlusBRTrackerY"] or 0 end,
					set = function(_, value)
						local y = tonumber(value) or 0
						if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "y", y, nil, true) end
						applyBRLayoutData({ y = y })
					end,
				},
				{
					name = "Layout",
					kind = settingType.Collapsible,
					id = "mythicPlusBRTrackerLayout",
					defaultCollapsed = true,
				},
				{
					field = "size",
					name = L["Button Size"] or "Button Size",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerLayout",
					minValue = BR_MIN_SIZE,
					maxValue = BR_MAX_SIZE,
					valueStep = 1,
					default = normalizeBRSize(addon.db["mythicPlusBRButtonSize"] or defaultButtonSize),
					get = function() return normalizeBRSize(addon.db["mythicPlusBRButtonSize"] or defaultButtonSize) end,
					set = function(_, value)
						local size = normalizeBRSize(value)
						addon.db["mythicPlusBRButtonSize"] = size
						if EditMode and EditMode.SetValue then EditMode:SetValue(BR_EDITMODE_ID, "size", size, nil, true) end
						applyBRLayoutData()
					end,
				},
				{
					name = L["Tracker icon"] or "Tracker icon",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerLayout",
					get = function() return normalizeBRIcon(addon.db and addon.db["mythicPlusBRTrackerIcon"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerIcon"] = normalizeBRIcon(value) end
						applyBRLayoutData()
					end,
					generator = function(_, root)
						for i = 1, #BR_DEFAULT_ICON_IDS do
							local iconId = BR_DEFAULT_ICON_IDS[i]
							local label = string.format("|T%d:22:22:0:0|t", iconId)
							root:CreateRadio(label, function() return normalizeBRIcon(addon.db and addon.db["mythicPlusBRTrackerIcon"]) == iconId end, function()
								if addon.db then addon.db["mythicPlusBRTrackerIcon"] = iconId end
								applyBRLayoutData()
							end)
						end
					end,
				},
				{
					name = L["Icon zoom"] or "Icon zoom",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerLayout",
					minValue = TRACKER_ICON_ZOOM_MIN,
					maxValue = TRACKER_ICON_ZOOM_MAX,
					valueStep = 1,
					default = normalizeTrackerIconZoom(addon.db["mythicPlusBRTrackerIconZoom"]),
					get = function() return normalizeTrackerIconZoom(addon.db["mythicPlusBRTrackerIconZoom"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerIconZoom"] = normalizeTrackerIconZoom(value)
						applyBRLayoutData()
					end,
				},
				{
					name = "Border",
					kind = settingType.Collapsible,
					id = "mythicPlusBRTrackerBorder",
					defaultCollapsed = true,
				},
				{
					name = L["Use border"] or "Use border",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerBorder",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerBorderEnabled"] = value == true end
						applyBRBorderVisualSettings()
					end,
				},
				{
					name = L["Border texture"] or "Border texture",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerBorder",
					height = 220,
					get = function() return normalizeBRBorderTexture(addon.db and addon.db["mythicPlusBRTrackerBorderTexture"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerBorderTexture"] = normalizeBRBorderTexture(value) end
						applyBRBorderVisualSettings()
					end,
					generator = function(_, root)
						local options = buildBorderEntries()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(
								option.label,
								function() return normalizeBRBorderTexture(addon.db and addon.db["mythicPlusBRTrackerBorderTexture"]) == option.value end,
								function()
									if addon.db then addon.db["mythicPlusBRTrackerBorderTexture"] = option.value end
									applyBRBorderVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false end,
				},
				{
					name = L["Border size"] or "Border size",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerBorder",
					minValue = BR_BORDER_SIZE_MIN,
					maxValue = BR_BORDER_SIZE_MAX,
					valueStep = 1,
					default = normalizeBRBorderSize(addon.db and addon.db["mythicPlusBRTrackerBorderSize"]),
					get = function() return normalizeBRBorderSize(addon.db and addon.db["mythicPlusBRTrackerBorderSize"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerBorderSize"] = normalizeBRBorderSize(value) end
						applyBRBorderVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false end,
				},
				{
					name = L["Border offset"] or "Border offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerBorder",
					minValue = BR_BORDER_OFFSET_MIN,
					maxValue = BR_BORDER_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBRBorderOffset(addon.db and addon.db["mythicPlusBRTrackerBorderOffset"]),
					get = function() return normalizeBRBorderOffset(addon.db and addon.db["mythicPlusBRTrackerBorderOffset"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerBorderOffset"] = normalizeBRBorderOffset(value) end
						applyBRBorderVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false end,
				},
				{
					name = EMBLEM_BORDER_COLOR,
					kind = settingType.Color,
					parentId = "mythicPlusBRTrackerBorder",
					get = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerBorderColor"], BR_DEFAULT_BORDER_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					set = function(_, color)
						if addon.db then addon.db["mythicPlusBRTrackerBorderColor"] = normalizeBRColor(color, BR_DEFAULT_BORDER_COLOR) end
						applyBRBorderVisualSettings()
					end,
					colorGet = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerBorderColor"], BR_DEFAULT_BORDER_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					colorSet = function(_, color)
						if addon.db then addon.db["mythicPlusBRTrackerBorderColor"] = normalizeBRColor(color, BR_DEFAULT_BORDER_COLOR) end
						applyBRBorderVisualSettings()
					end,
					colorDefault = { r = BR_DEFAULT_BORDER_COLOR[1], g = BR_DEFAULT_BORDER_COLOR[2], b = BR_DEFAULT_BORDER_COLOR[3], a = BR_DEFAULT_BORDER_COLOR[4] },
					hasOpacity = true,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerBorderEnabled"] ~= false end,
				},
				{
					name = "Cooldown",
					kind = settingType.Collapsible,
					id = "mythicPlusBRTrackerCooldown",
					defaultCollapsed = false,
				},
				{
					name = L["Show cooldown text"] or "Show cooldown text",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerCooldownTextEnabled"] = value == true end
						applyBRCooldownVisualSettings()
					end,
				},
				{
					name = L["Draw cooldown swipe"] or "Draw cooldown swipe",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownDrawSwipe"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerCooldownDrawSwipe"] = value == true end
						applyBRCooldownVisualSettings()
					end,
				},
				{
					name = L["Draw cooldown edge"] or "Draw cooldown edge",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownDrawEdge"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerCooldownDrawEdge"] = value == true end
						applyBRCooldownVisualSettings()
					end,
				},
				{
					name = L["Draw cooldown bling"] or "Draw cooldown bling",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownDrawBling"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerCooldownDrawBling"] = value == true end
						applyBRCooldownVisualSettings()
					end,
				},
				{
					name = L["Cooldown font"] or "Cooldown font",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCooldown",
					height = 280,
					get = function()
						local current = getStoredFontKey("mythicPlusBRTrackerCooldownFontFace")
						return current
					end,
					set = function(_, value) setStoredFontKey("mythicPlusBRTrackerCooldownFontFace", value, applyBRCooldownVisualSettings) end,
					generator = function(_, root)
						local _, entries = getStoredFontKey("mythicPlusBRTrackerCooldownFontFace")
						root:CreateRadio(
							BLOODLUST_GLOBAL_FONT_LABEL,
							function() return getStoredFontKey("mythicPlusBRTrackerCooldownFontFace") == BLOODLUST_GLOBAL_FONT_KEY end,
							function() setStoredFontKey("mythicPlusBRTrackerCooldownFontFace", BLOODLUST_GLOBAL_FONT_KEY, applyBRCooldownVisualSettings) end
						)
						for i = 1, #entries do
							local fontName = entries[i]
							root:CreateRadio(
								fontName,
								function() return getStoredFontKey("mythicPlusBRTrackerCooldownFontFace") == fontName end,
								function() setStoredFontKey("mythicPlusBRTrackerCooldownFontFace", fontName, applyBRCooldownVisualSettings) end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text size"] or "Cooldown text size",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCooldown",
					minValue = BR_TEXT_SIZE_MIN,
					maxValue = BR_TEXT_SIZE_MAX,
					valueStep = 1,
					default = normalizeBRTextSize(addon.db["mythicPlusBRTrackerCooldownTextSize"], defaultFontSize),
					get = function() return normalizeBRTextSize(addon.db["mythicPlusBRTrackerCooldownTextSize"], defaultFontSize) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerCooldownTextSize"] = normalizeBRTextSize(value, defaultFontSize)
						applyBRCooldownVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text outline"] or "Cooldown text outline",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function() return normalizeBRTextOutline(addon.db and addon.db["mythicPlusBRTrackerCooldownTextOutline"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerCooldownTextOutline"] = normalizeBRTextOutline(value)
						applyBRCooldownVisualSettings()
					end,
					generator = function(_, root)
						for i = 1, #BLOODLUST_COOLDOWN_OUTLINE_OPTIONS do
							local option = BLOODLUST_COOLDOWN_OUTLINE_OPTIONS[i]
							local value = option.value
							root:CreateRadio(
								outlineOptionLabel(value),
								function() return normalizeBRTextOutline(addon.db and addon.db["mythicPlusBRTrackerCooldownTextOutline"]) == value end,
								function()
									addon.db["mythicPlusBRTrackerCooldownTextOutline"] = value
									applyBRCooldownVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text color"] or "Cooldown text color",
					kind = settingType.Color,
					parentId = "mythicPlusBRTrackerCooldown",
					get = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerCooldownTextColor"], BR_DEFAULT_COOLDOWN_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					set = function(_, color)
						addon.db["mythicPlusBRTrackerCooldownTextColor"] = normalizeBRColor(color, BR_DEFAULT_COOLDOWN_COLOR)
						applyBRCooldownVisualSettings()
					end,
					colorGet = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerCooldownTextColor"], BR_DEFAULT_COOLDOWN_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					colorSet = function(_, color)
						addon.db["mythicPlusBRTrackerCooldownTextColor"] = normalizeBRColor(color, BR_DEFAULT_COOLDOWN_COLOR)
						applyBRCooldownVisualSettings()
					end,
					colorDefault = { r = BR_DEFAULT_COOLDOWN_COLOR[1], g = BR_DEFAULT_COOLDOWN_COLOR[2], b = BR_DEFAULT_COOLDOWN_COLOR[3], a = BR_DEFAULT_COOLDOWN_COLOR[4] },
					hasOpacity = true,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text anchor"] or "Cooldown text anchor",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCooldown",
					height = 220,
					get = function() return normalizeBRTextPoint(addon.db and addon.db["mythicPlusBRTrackerCooldownTextPoint"], "CENTER") end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerCooldownTextPoint"] = normalizeBRTextPoint(value, "CENTER")
						applyBRCooldownVisualSettings()
					end,
					generator = function(_, root)
						for i = 1, #BR_TEXT_POINT_OPTIONS do
							local option = BR_TEXT_POINT_OPTIONS[i]
							root:CreateRadio(
								option.label,
								function() return normalizeBRTextPoint(addon.db and addon.db["mythicPlusBRTrackerCooldownTextPoint"], "CENTER") == option.value end,
								function()
									addon.db["mythicPlusBRTrackerCooldownTextPoint"] = option.value
									applyBRCooldownVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text X offset"] or "Cooldown text X offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCooldown",
					minValue = BR_TEXT_OFFSET_MIN,
					maxValue = BR_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetX"]),
					get = function() return normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetX"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerCooldownTextOffsetX"] = normalizeBRTextOffset(value)
						applyBRCooldownVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = L["Cooldown text Y offset"] or "Cooldown text Y offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCooldown",
					minValue = BR_TEXT_OFFSET_MIN,
					maxValue = BR_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetY"]),
					get = function() return normalizeBRTextOffset(addon.db["mythicPlusBRTrackerCooldownTextOffsetY"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerCooldownTextOffsetY"] = normalizeBRTextOffset(value)
						applyBRCooldownVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerCooldownTextEnabled"] ~= false end,
				},
				{
					name = "Charges",
					kind = settingType.Collapsible,
					id = "mythicPlusBRTrackerCharges",
					defaultCollapsed = false,
				},
				{
					name = L["Show charges"] or "Show charges",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBRTrackerCharges",
					get = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBRTrackerChargesEnabled"] = value == true end
						applyBRChargesVisualSettings()
					end,
				},
				{
					name = L["mythicPlusBRTrackerChargesFont"] or "Charges font",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCharges",
					height = 280,
					get = function()
						local current = getStoredFontKey("mythicPlusBRTrackerChargesFontFace")
						return current
					end,
					set = function(_, value) setStoredFontKey("mythicPlusBRTrackerChargesFontFace", value, applyBRChargesVisualSettings) end,
					generator = function(_, root)
						local _, entries = getStoredFontKey("mythicPlusBRTrackerChargesFontFace")
						root:CreateRadio(
							BLOODLUST_GLOBAL_FONT_LABEL,
							function() return getStoredFontKey("mythicPlusBRTrackerChargesFontFace") == BLOODLUST_GLOBAL_FONT_KEY end,
							function() setStoredFontKey("mythicPlusBRTrackerChargesFontFace", BLOODLUST_GLOBAL_FONT_KEY, applyBRChargesVisualSettings) end
						)
						for i = 1, #entries do
							local fontName = entries[i]
							root:CreateRadio(
								fontName,
								function() return getStoredFontKey("mythicPlusBRTrackerChargesFontFace") == fontName end,
								function() setStoredFontKey("mythicPlusBRTrackerChargesFontFace", fontName, applyBRChargesVisualSettings) end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextSize"] or "Charges text size",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCharges",
					minValue = BR_TEXT_SIZE_MIN,
					maxValue = BR_TEXT_SIZE_MAX,
					valueStep = 1,
					default = normalizeBRTextSize(addon.db["mythicPlusBRTrackerChargesTextSize"], defaultFontSize),
					get = function() return normalizeBRTextSize(addon.db["mythicPlusBRTrackerChargesTextSize"], defaultFontSize) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerChargesTextSize"] = normalizeBRTextSize(value, defaultFontSize)
						applyBRChargesVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextOutline"] or "Charges text outline",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCharges",
					get = function() return normalizeBRTextOutline(addon.db and addon.db["mythicPlusBRTrackerChargesTextOutline"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerChargesTextOutline"] = normalizeBRTextOutline(value)
						applyBRChargesVisualSettings()
					end,
					generator = function(_, root)
						for i = 1, #BLOODLUST_COOLDOWN_OUTLINE_OPTIONS do
							local option = BLOODLUST_COOLDOWN_OUTLINE_OPTIONS[i]
							local value = option.value
							root:CreateRadio(
								outlineOptionLabel(value),
								function() return normalizeBRTextOutline(addon.db and addon.db["mythicPlusBRTrackerChargesTextOutline"]) == value end,
								function()
									addon.db["mythicPlusBRTrackerChargesTextOutline"] = value
									applyBRChargesVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextColor"] or "Charges text color",
					kind = settingType.Color,
					parentId = "mythicPlusBRTrackerCharges",
					get = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerChargesTextColor"], BR_DEFAULT_CHARGES_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					set = function(_, color)
						addon.db["mythicPlusBRTrackerChargesTextColor"] = normalizeBRColor(color, BR_DEFAULT_CHARGES_COLOR)
						applyBRChargesVisualSettings()
					end,
					colorGet = function()
						local c = normalizeBRColor(addon.db and addon.db["mythicPlusBRTrackerChargesTextColor"], BR_DEFAULT_CHARGES_COLOR)
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					colorSet = function(_, color)
						addon.db["mythicPlusBRTrackerChargesTextColor"] = normalizeBRColor(color, BR_DEFAULT_CHARGES_COLOR)
						applyBRChargesVisualSettings()
					end,
					colorDefault = { r = BR_DEFAULT_CHARGES_COLOR[1], g = BR_DEFAULT_CHARGES_COLOR[2], b = BR_DEFAULT_CHARGES_COLOR[3], a = BR_DEFAULT_CHARGES_COLOR[4] },
					hasOpacity = true,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextPoint"] or "Charges text anchor",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBRTrackerCharges",
					height = 220,
					get = function() return normalizeBRTextPoint(addon.db and addon.db["mythicPlusBRTrackerChargesTextPoint"], "BOTTOMRIGHT") end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerChargesTextPoint"] = normalizeBRTextPoint(value, "BOTTOMRIGHT")
						applyBRChargesVisualSettings()
					end,
					generator = function(_, root)
						for i = 1, #BR_TEXT_POINT_OPTIONS do
							local option = BR_TEXT_POINT_OPTIONS[i]
							root:CreateRadio(
								option.label,
								function() return normalizeBRTextPoint(addon.db and addon.db["mythicPlusBRTrackerChargesTextPoint"], "BOTTOMRIGHT") == option.value end,
								function()
									addon.db["mythicPlusBRTrackerChargesTextPoint"] = option.value
									applyBRChargesVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextOffsetX"] or "Charges text X offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCharges",
					minValue = BR_TEXT_OFFSET_MIN,
					maxValue = BR_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetX"]),
					get = function() return normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetX"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerChargesTextOffsetX"] = normalizeBRTextOffset(value)
						applyBRChargesVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
				{
					name = L["mythicPlusBRTrackerChargesTextOffsetY"] or "Charges text Y offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBRTrackerCharges",
					minValue = BR_TEXT_OFFSET_MIN,
					maxValue = BR_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetY"]),
					get = function() return normalizeBRTextOffset(addon.db["mythicPlusBRTrackerChargesTextOffsetY"]) end,
					set = function(_, value)
						addon.db["mythicPlusBRTrackerChargesTextOffsetY"] = normalizeBRTextOffset(value)
						applyBRChargesVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBRTrackerChargesEnabled"] ~= false end,
				},
			}
		end

		EditMode:RegisterFrame(BR_EDITMODE_ID, {
			frame = brAnchor,
			title = L["mythicPlusBRTrackerAnchor"],
			layoutDefaults = {
				point = addon.db["mythicPlusBRTrackerPoint"] or "CENTER",
				relativePoint = addon.db["mythicPlusBRTrackerRelativePoint"] or addon.db["mythicPlusBRTrackerPoint"] or "CENTER",
				anchorTarget = addon.db["mythicPlusBRTrackerRelativeFrame"] or "UIParent",
				x = addon.db["mythicPlusBRTrackerX"] or 0,
				y = addon.db["mythicPlusBRTrackerY"] or 0,
				size = addon.db["mythicPlusBRButtonSize"] or defaultButtonSize,
			},
			legacyKeys = {
				point = "mythicPlusBRTrackerPoint",
				relativePoint = "mythicPlusBRTrackerRelativePoint",
				x = "mythicPlusBRTrackerX",
				y = "mythicPlusBRTrackerY",
				size = "mythicPlusBRButtonSize",
			},
			isEnabled = function() return addon.db["mythicPlusBRTrackerEnabled"] end,
			onApply = function(_, layoutName, data)
				if not brAnchor._eqolEditModeHydrated then
					brAnchor._eqolEditModeHydrated = true
					local record = data or {}
					seedBREditModeRecordFromProfile(record)
					applyBRLayoutData(record)
					return
				end
				applyBRLayoutData(data)
			end,
			onPositionChanged = function(_, _, data)
				applyBRLayoutData(data)
				if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
					addon.EditModeLib.internal:RefreshSettingValues()
				end
			end,
			settings = settings,
			relativeTo = function() return resolveTrackerAnchorFrame(addon.db and addon.db["mythicPlusBRTrackerRelativeFrame"]) end,
			allowDrag = function() return trackerAnchorUsesUIParent(addon.db and addon.db["mythicPlusBRTrackerRelativeFrame"]) end,
			managePosition = false,
			persistPosition = false,
		})
		brEditModeRegistered = true
	end
	applyBRLayoutData()

	return brAnchor
end

local function shouldShowBRTracker()
	if not addon.db["mythicPlusBRTrackerEnabled"] then return false end
	if not IsInInstance() then return false end
	local _, _, diff = GetInstanceInfo()
	if diff == 8 then return true end
	if isRaidDifficulty(diff) then return C_InstanceEncounter.IsEncounterInProgress() end
	return false
end

local function createBRFrame()
	removeBRFrame()
	if not addon.db["mythicPlusBRTrackerEnabled"] then
		if brAnchor then brAnchor:Hide() end
		if EditMode then EditMode:RefreshFrame(BR_EDITMODE_ID) end
		return
	end
	local layout = buildBRLayoutSnapshot()
	ensureBRAnchor()
	if IsInGroup() and shouldShowBRTracker() then
		local point = layout.point or "CENTER"
		local relativePoint = layout.relativePoint or point
		local xOfs = layout.x or 0
		local yOfs = layout.y or 0
		local size = layout.size or defaultButtonSize

		brButton = CreateFrame("Button", nil, UIParent)
		brButton:SetClampedToScreen(true)
		brButton:SetSize(size, size)
		brButton:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
		setFrameClickThrough(brButton)

		local bg = brButton:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(brButton)
		bg:SetColorTexture(0, 0, 0, 0.8)

		local icon = brButton:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(brButton)
		icon:SetTexture(getBRConfiguredIcon())
		applyTrackerIconZoom(icon, addon.db and addon.db["mythicPlusBRTrackerIconZoom"])
		brButton.icon = icon

		brButton.border = CreateFrame("Frame", nil, brButton, "BackdropTemplate")
		brButton.border:SetFrameLevel((brButton:GetFrameLevel() or 0) + 5)
		brButton.border:SetFrameStrata(brButton:GetFrameStrata())

		brButton.textOverlay = CreateFrame("Frame", nil, brButton)
		brButton.textOverlay:SetAllPoints(brButton)
		brButton.textOverlay:EnableMouse(false)

		brButton.cooldownFrame = CreateFrame("Cooldown", nil, brButton, "CooldownFrameTemplate")
		brButton.cooldownFrame:SetAllPoints(brButton)
		brButton.cooldownFrame.cooldownSet = false
		brButton.cooldownFrame:SetSwipeColor(0, 0, 0, 0.3)
		brButton.cooldownFrame:SetCountdownAbbrevThreshold(600)
		brButton.cooldownFrame:SetScale(1)

		brButton.charges = brButton.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		brButton.charges:SetPoint("BOTTOMRIGHT", brButton, "BOTTOMRIGHT", -3, 3)
		brButton.charges:SetText("")
		brButton.cooldownFrame:Clear()
		applyBRBorderVisualSettings()
		applyBRCooldownVisualSettings()
		applyBRChargesVisualSettings()
	end
	applyBRLayoutData(layout)
	if EditMode then EditMode:RefreshFrame(BR_EDITMODE_ID) end
end

addon.MythicPlus.functions.createBRFrame = createBRFrame

local function normalizeBloodlustSize(value)
	local size = tonumber(value) or defaultButtonSize
	size = math.floor(size + 0.5)
	if size < BLOODLUST_MIN_SIZE then size = BLOODLUST_MIN_SIZE end
	if size > BLOODLUST_MAX_SIZE then size = BLOODLUST_MAX_SIZE end
	return size
end

local function normalizeBloodlustIcon(value)
	local iconId = tonumber(value)
	if iconId and BLOODLUST_DEFAULT_ICON_SET[iconId] then return iconId end
	return BLOODLUST_DEFAULT_ICON_IDS[1]
end

local function getBloodlustConfiguredIcon() return normalizeBloodlustIcon(addon.db and addon.db["mythicPlusBloodlustTrackerIcon"]) end

local function isLikelyFilePath(value)
	if type(value) ~= "string" or value == "" then return false end
	return value:find("/", 1, true) ~= nil or value:find("\\", 1, true) ~= nil
end

local function getCachedMediaHash(mediaType)
	if addon.functions and addon.functions.GetLSMMediaHash then
		local hash = addon.functions.GetLSMMediaHash(mediaType)
		if type(hash) == "table" then return hash end
	end
	return {}
end

local function getCachedMediaNames(mediaType)
	if addon.functions and addon.functions.GetLSMMediaNames then
		local names = addon.functions.GetLSMMediaNames(mediaType)
		if type(names) == "table" then return names end
	end

	local names = {}
	for name in pairs(getCachedMediaHash(mediaType)) do
		if type(name) == "string" and name ~= "" then names[#names + 1] = name end
	end
	table.sort(names, function(a, b)
		local al = string.lower(a)
		local bl = string.lower(b)
		if al == bl then return a < b end
		return al < bl
	end)
	return names
end

local function normalizeBloodlustBorderTexture(value)
	if type(value) ~= "string" or value == "" then return "DEFAULT" end
	if value == "DEFAULT" or value == "SOLID" then return value end
	return value
end

local function resolveBloodlustBorderTexture(value)
	local key = normalizeBloodlustBorderTexture(value)
	if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	if isLikelyFilePath(key) then return key end
	if LSM and LSM.Fetch then
		local tex = LSM:Fetch("border", key, true)
		if tex then return tex end
	end
	return "Interface\\Buttons\\WHITE8x8"
end

local function normalizeBloodlustBorderSize(value)
	local size = tonumber(value) or 1
	size = math.floor(size + 0.5)
	if size < BLOODLUST_BORDER_SIZE_MIN then size = BLOODLUST_BORDER_SIZE_MIN end
	if size > BLOODLUST_BORDER_SIZE_MAX then size = BLOODLUST_BORDER_SIZE_MAX end
	return size
end

local function normalizeBloodlustBorderOffset(value)
	local offset = tonumber(value) or 0
	offset = math.floor(offset + 0.5)
	if offset < BLOODLUST_BORDER_OFFSET_MIN then offset = BLOODLUST_BORDER_OFFSET_MIN end
	if offset > BLOODLUST_BORDER_OFFSET_MAX then offset = BLOODLUST_BORDER_OFFSET_MAX end
	return offset
end

local function normalizeBloodlustBorderColor(value)
	local color = value
	if type(color) ~= "table" then color = { 1, 1, 1, 1 } end
	local r = tonumber(color.r or color[1]) or 1
	local g = tonumber(color.g or color[2]) or 1
	local b = tonumber(color.b or color[3]) or 1
	local a = tonumber(color.a or color[4]) or 1
	if r < 0 then r = 0 end
	if r > 1 then r = 1 end
	if g < 0 then g = 0 end
	if g > 1 then g = 1 end
	if b < 0 then b = 0 end
	if b > 1 then b = 1 end
	if a < 0 then a = 0 end
	if a > 1 then a = 1 end
	return { r, g, b, a }
end

local function normalizeBloodlustCooldownTextSize(value)
	local size = tonumber(value) or 16
	size = math.floor(size + 0.5)
	if size < BLOODLUST_COOLDOWN_TEXT_SIZE_MIN then size = BLOODLUST_COOLDOWN_TEXT_SIZE_MIN end
	if size > BLOODLUST_COOLDOWN_TEXT_SIZE_MAX then size = BLOODLUST_COOLDOWN_TEXT_SIZE_MAX end
	return size
end

local function normalizeBloodlustCooldownTextOffset(value)
	local offset = tonumber(value) or 0
	offset = math.floor(offset + 0.5)
	if offset < BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN then offset = BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN end
	if offset > BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX then offset = BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX end
	return offset
end

local function normalizeBloodlustCooldownOutline(value)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, "OUTLINE", true)
	end
	if type(value) == "string" and BLOODLUST_COOLDOWN_OUTLINE_SET[value] then return value end
	return "OUTLINE"
end

local function normalizeBloodlustCooldownColor(value)
	local color = value
	if type(color) ~= "table" then color = { 1, 1, 1, 1 } end
	local r = tonumber(color.r or color[1]) or 1
	local g = tonumber(color.g or color[2]) or 1
	local b = tonumber(color.b or color[3]) or 1
	local a = tonumber(color.a or color[4]) or 1
	if r < 0 then r = 0 end
	if r > 1 then r = 1 end
	if g < 0 then g = 0 end
	if g > 1 then g = 1 end
	if b < 0 then b = 0 end
	if b > 1 then b = 1 end
	if a < 0 then a = 0 end
	if a > 1 then a = 1 end
	return { r, g, b, a }
end

local function normalizeBloodlustCooldownFontFace(value)
	if type(value) ~= "string" or value == "" then return BLOODLUST_GLOBAL_FONT_KEY end
	if value == BLOODLUST_GLOBAL_FONT_KEY then return value end
	return value
end

local function resolveBloodlustCooldownFontFace()
	local configured = normalizeBloodlustCooldownFontFace(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownFontFace"])
	local fallback = (addon.functions and addon.functions.GetGlobalDefaultFontFace and addon.functions.GetGlobalDefaultFontFace())
		or (addon.functions and addon.functions.GetLocaleDefaultFontFace and addon.functions.GetLocaleDefaultFontFace())
		or addon.variables.defaultFont
		or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, fallback) end
	if configured == BLOODLUST_GLOBAL_FONT_KEY then return fallback end
	return configured
end

local function applyBloodlustAnchorPreviewIcon()
	if not (bloodlustAnchor and bloodlustAnchor.previewIcon) then return end
	bloodlustAnchor.previewIcon:SetTexture(getBloodlustConfiguredIcon())
	applyTrackerIconZoom(bloodlustAnchor.previewIcon, addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"])
end

local function applyBloodlustBorderFrame(frame, target, enabled, textureKey, borderSize, borderOffset, borderColor)
	if not frame or not target or not frame.SetBackdrop then return end
	if not enabled then
		frame:SetBackdrop(nil)
		frame:Hide()
		return
	end

	frame:SetBackdrop({
		edgeFile = resolveBloodlustBorderTexture(textureKey),
		edgeSize = borderSize,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	frame:SetBackdropColor(0, 0, 0, 0)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", target, "TOPLEFT", -borderOffset, borderOffset)
	frame:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", borderOffset, -borderOffset)
	frame:Show()
end

local function applyBloodlustBorderVisualSettings()
	local db = addon.db or {}
	local enabled = db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false
	local textureKey = normalizeBloodlustBorderTexture(db["mythicPlusBloodlustTrackerBorderTexture"])
	local borderSize = normalizeBloodlustBorderSize(db["mythicPlusBloodlustTrackerBorderSize"])
	local borderOffset = normalizeBloodlustBorderOffset(db["mythicPlusBloodlustTrackerBorderOffset"])
	local borderColor = normalizeBloodlustBorderColor(db["mythicPlusBloodlustTrackerBorderColor"])

	if bloodlustAnchor and bloodlustAnchor.previewBorder and bloodlustAnchor.previewIcon then
		applyBloodlustBorderFrame(bloodlustAnchor.previewBorder, bloodlustAnchor.previewIcon, enabled, textureKey, borderSize, borderOffset, borderColor)
	end
	if bloodlustButton and bloodlustButton.border then applyBloodlustBorderFrame(bloodlustButton.border, bloodlustButton, enabled, textureKey, borderSize, borderOffset, borderColor) end
	if bloodlustAnchor and bloodlustAnchor.textOverlay then syncTrackerTextOverlay(bloodlustAnchor, bloodlustAnchor.textOverlay, bloodlustAnchor.previewBorder) end
	if bloodlustButton and bloodlustButton.textOverlay then syncTrackerTextOverlay(bloodlustButton, bloodlustButton.textOverlay, bloodlustButton.border) end
end

local function applyBloodlustCooldownTextStyle(fontString, anchorFrame, db)
	if not fontString or not anchorFrame then return end
	local fontFace = resolveBloodlustCooldownFontFace()
	local fontSize = normalizeBloodlustCooldownTextSize(db["mythicPlusBloodlustTrackerCooldownTextSize"])
	local outlineValue = normalizeBloodlustCooldownOutline(db["mythicPlusBloodlustTrackerCooldownTextOutline"])
	applyTrackerFontString(fontString, fontFace, fontSize, outlineValue, "OUTLINE")
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, outlineValue, "OUTLINE") end
	local color = normalizeBloodlustCooldownColor(db["mythicPlusBloodlustTrackerCooldownTextColor"])
	fontString:SetTextColor(color[1], color[2], color[3], color[4])
	fontString:ClearAllPoints()
	fontString:SetPoint(
		"CENTER",
		anchorFrame,
		"CENTER",
		normalizeBloodlustCooldownTextOffset(db["mythicPlusBloodlustTrackerCooldownTextOffsetX"]),
		normalizeBloodlustCooldownTextOffset(db["mythicPlusBloodlustTrackerCooldownTextOffsetY"])
	)
end

local function applyBloodlustLiveCooldownTextStyle(deferIfMissing)
	if not (bloodlustButton and bloodlustButton.cooldownFrame) then return false end
	local cooldown = bloodlustButton.cooldownFrame
	local fontString = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if fontString then
		applyBloodlustCooldownTextStyle(fontString, cooldown, addon.db or {})
		return true
	end

	if deferIfMissing and not bloodlustCooldownDeferredApplyPending then
		bloodlustCooldownDeferredApplyPending = true
		RunNextFrame(function()
			bloodlustCooldownDeferredApplyPending = false
			if not (bloodlustButton and bloodlustButton.cooldownFrame) then return end
			local deferredCooldown = bloodlustButton.cooldownFrame
			local deferredFontString = deferredCooldown.GetCountdownFontString and deferredCooldown:GetCountdownFontString()
			if deferredFontString then applyBloodlustCooldownTextStyle(deferredFontString, deferredCooldown, addon.db or {}) end
		end)
	end

	return false
end

local function applyBloodlustCooldownVisualSettings()
	local db = addon.db or {}
	if bloodlustButton and bloodlustButton.cooldownFrame then
		local cooldown = bloodlustButton.cooldownFrame
		if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false) end
		if cooldown.SetDrawEdge then cooldown:SetDrawEdge(db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true) end
		if cooldown.SetDrawBling then cooldown:SetDrawBling(db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true) end
		applyBloodlustLiveCooldownTextStyle(true)
	end
	if bloodlustAnchor and bloodlustAnchor.previewCooldownText and bloodlustAnchor.previewIcon then
		applyBloodlustCooldownTextStyle(bloodlustAnchor.previewCooldownText, bloodlustAnchor.previewIcon, db)
		bloodlustAnchor.previewCooldownText:SetText(BLOODLUST_PREVIEW_COOLDOWN_TEXT)
		bloodlustAnchor.previewCooldownText:Show()
	end
end

local function refreshBloodlustMedia(mediaType)
	if mediaType == "border" then
		applyBloodlustBorderVisualSettings()
	elseif mediaType == "font" then
		applyBloodlustCooldownVisualSettings()
	end
end

addon.MythicPlus.functions.refreshBloodlustMedia = refreshBloodlustMedia

local function removeBloodlustFrame()
	if bloodlustButton then
		bloodlustCooldownDeferredApplyPending = false
		bloodlustButton:Hide()
		bloodlustButton:SetParent(nil)
		bloodlustButton:SetScript("OnClick", nil)
		bloodlustButton:SetScript("OnEnter", nil)
		bloodlustButton:SetScript("OnLeave", nil)
		bloodlustButton:SetScript("OnUpdate", nil)
		bloodlustButton:SetScript("OnEvent", nil)
		bloodlustButton:SetScript("OnDragStart", nil)
		bloodlustButton:SetScript("OnDragStop", nil)
		bloodlustButton:UnregisterAllEvents()
		bloodlustButton:ClearAllPoints()
		bloodlustButton = nil
	end
end

local function buildBloodlustLayoutSnapshot()
	local currentTarget = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent"
	local relativeFrame = validateTrackerAnchorTarget(currentTarget, currentTarget)
	local point = normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER")
	return {
		point = point,
		relativePoint = normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerRelativePoint"] or point, point),
		anchorTarget = relativeFrame,
		x = addon.db["mythicPlusBloodlustTrackerX"] or 0,
		y = addon.db["mythicPlusBloodlustTrackerY"] or 0,
		size = normalizeBloodlustSize(addon.db["mythicPlusBloodlustButtonSize"] or defaultButtonSize),
	}
end

local function seedBloodlustEditModeRecordFromProfile(record)
	if type(record) ~= "table" then return end
	local snapshot = buildBloodlustLayoutSnapshot()
	record.point = snapshot.point or "CENTER"
	record.relativePoint = snapshot.relativePoint or record.point
	record.anchorTarget = snapshot.anchorTarget or "UIParent"
	record.x = snapshot.x or 0
	record.y = snapshot.y or 0
	record.size = snapshot.size or defaultButtonSize
end

local function applyBloodlustLayoutData(data)
	local config = data or buildBloodlustLayoutSnapshot()
	local currentTarget = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent"
	local relativeFrame = validateTrackerAnchorTarget(config.anchorTarget or config.relativeFrame or currentTarget, currentTarget)
	local point = normalizeTrackerAnchorPoint(config.point or addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER")
	local relativePoint = normalizeTrackerAnchorPoint(config.relativePoint or addon.db["mythicPlusBloodlustTrackerRelativePoint"] or point, point)
	local x = config.x
	if x == nil then x = addon.db["mythicPlusBloodlustTrackerX"] or 0 end
	local y = config.y
	if y == nil then y = addon.db["mythicPlusBloodlustTrackerY"] or 0 end
	local size = normalizeBloodlustSize(addon.db["mythicPlusBloodlustButtonSize"] or config.size or defaultButtonSize)
	local iconId = normalizeBloodlustIcon(addon.db["mythicPlusBloodlustTrackerIcon"])
	local iconZoom = normalizeTrackerIconZoom(addon.db["mythicPlusBloodlustTrackerIconZoom"])
	local cooldownTextSize = normalizeBloodlustCooldownTextSize(addon.db["mythicPlusBloodlustTrackerCooldownTextSize"])
	local cooldownTextOutline = normalizeBloodlustCooldownOutline(addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"])
	local cooldownTextColor = normalizeBloodlustCooldownColor(addon.db["mythicPlusBloodlustTrackerCooldownTextColor"])
	local cooldownTextOffsetX = normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"])
	local cooldownTextOffsetY = normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"])
	local cooldownFontFace = normalizeBloodlustCooldownFontFace(addon.db["mythicPlusBloodlustTrackerCooldownFontFace"])
	local borderEnabled = addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false
	local borderTexture = normalizeBloodlustBorderTexture(addon.db["mythicPlusBloodlustTrackerBorderTexture"])
	local borderSize = normalizeBloodlustBorderSize(addon.db["mythicPlusBloodlustTrackerBorderSize"])
	local borderOffset = normalizeBloodlustBorderOffset(addon.db["mythicPlusBloodlustTrackerBorderOffset"])
	local borderColor = normalizeBloodlustBorderColor(addon.db["mythicPlusBloodlustTrackerBorderColor"])

	if addon.db then
		addon.db["mythicPlusBloodlustTrackerPoint"] = point
		addon.db["mythicPlusBloodlustTrackerRelativePoint"] = relativePoint
		addon.db["mythicPlusBloodlustTrackerRelativeFrame"] = relativeFrame
		addon.db["mythicPlusBloodlustTrackerX"] = x
		addon.db["mythicPlusBloodlustTrackerY"] = y
		addon.db["mythicPlusBloodlustButtonSize"] = size
		addon.db["mythicPlusBloodlustTrackerIcon"] = iconId
		addon.db["mythicPlusBloodlustTrackerIconZoom"] = iconZoom
		addon.db["mythicPlusBloodlustTrackerCooldownTextSize"] = cooldownTextSize
		addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"] = cooldownTextOutline
		addon.db["mythicPlusBloodlustTrackerCooldownTextColor"] = cooldownTextColor
		addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"] = cooldownTextOffsetX
		addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"] = cooldownTextOffsetY
		addon.db["mythicPlusBloodlustTrackerCooldownFontFace"] = cooldownFontFace
		addon.db["mythicPlusBloodlustTrackerBorderEnabled"] = borderEnabled
		addon.db["mythicPlusBloodlustTrackerBorderTexture"] = borderTexture
		addon.db["mythicPlusBloodlustTrackerBorderSize"] = borderSize
		addon.db["mythicPlusBloodlustTrackerBorderOffset"] = borderOffset
		addon.db["mythicPlusBloodlustTrackerBorderColor"] = borderColor
	end

	local resolvedAnchorFrame = resolveTrackerAnchorFrame(relativeFrame)
	maybeScheduleTrackerAnchorRefresh(relativeFrame)

	if bloodlustAnchor then
		bloodlustAnchor:SetSize(size, size)
		bloodlustAnchor:ClearAllPoints()
		bloodlustAnchor:SetPoint(point, resolvedAnchorFrame, relativePoint, x, y)
		if bloodlustAnchor.previewIcon then bloodlustAnchor.previewIcon:SetAllPoints(bloodlustAnchor) end
		applyBloodlustAnchorPreviewIcon()
	end

	if bloodlustButton then
		bloodlustButton:SetSize(size, size)
		bloodlustButton:ClearAllPoints()
		bloodlustButton:SetPoint(point, resolvedAnchorFrame, relativePoint, x, y)
		local scaleFactor = size / defaultButtonSize
		local timerFontSize = math.floor(defaultFontSize * 0.75 * scaleFactor + 0.5)
		if timerFontSize < 10 then timerFontSize = 10 end
		bloodlustButton.defaultIcon = iconId
		if bloodlustButton.icon then applyTrackerIconZoom(bloodlustButton.icon, iconZoom) end
		if bloodlustButton.status then bloodlustButton.status:SetFont(addon.variables.defaultFont, timerFontSize, "OUTLINE") end
		if bloodlustButton.cooldownFrame then bloodlustButton.cooldownFrame:SetScale(1) end
	end
	-- Always apply text styling so Edit Mode preview updates even without a live tracker button.
	applyBloodlustCooldownVisualSettings()
	applyBloodlustBorderVisualSettings()
	if trackerAnchorNeedsReapply(relativeFrame)
		and not (addon.MythicPlus and addon.MythicPlus.variables and addon.MythicPlus.variables.trackerAnchorReapplyBusy)
		and addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.ScheduleTrackerAnchorReapply
	then
		addon.MythicPlus.functions.ScheduleTrackerAnchorReapply("Bloodlust")
	end
end

local function ensureBloodlustAnchor()
	if not bloodlustAnchor then
		bloodlustAnchor = CreateFrame("Frame", "EnhanceQoLMythicPlusBloodlustAnchor", UIParent)
		bloodlustAnchor:SetClampedToScreen(true)
		bloodlustAnchor:SetMovable(true)
		bloodlustAnchor:EnableMouse(true)

		local bg = bloodlustAnchor:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.5)
		bloodlustAnchor.bg = bg

		bloodlustAnchor.previewIcon = bloodlustAnchor:CreateTexture(nil, "ARTWORK")
		bloodlustAnchor.previewIcon:SetAllPoints(bloodlustAnchor)
		bloodlustAnchor.previewIcon:SetTexture(getBloodlustConfiguredIcon())
		applyTrackerIconZoom(bloodlustAnchor.previewIcon, addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"])

		bloodlustAnchor.previewBorder = CreateFrame("Frame", nil, bloodlustAnchor, "BackdropTemplate")
		bloodlustAnchor.previewBorder:SetFrameLevel((bloodlustAnchor:GetFrameLevel() or 0) + 4)
		bloodlustAnchor.previewBorder:SetFrameStrata(bloodlustAnchor:GetFrameStrata())

		bloodlustAnchor.textOverlay = CreateFrame("Frame", nil, bloodlustAnchor)
		bloodlustAnchor.textOverlay:SetAllPoints(bloodlustAnchor)
		bloodlustAnchor.textOverlay:EnableMouse(false)

		bloodlustAnchor.previewCooldownText = bloodlustAnchor.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		bloodlustAnchor.previewCooldownText:SetPoint("CENTER", bloodlustAnchor, "CENTER", 0, 0)
		bloodlustAnchor.previewCooldownText:SetText(BLOODLUST_PREVIEW_COOLDOWN_TEXT)
		bloodlustAnchor.previewCooldownText:Show()

		bloodlustAnchor.label = bloodlustAnchor.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		bloodlustAnchor.label:SetPoint("CENTER")
		bloodlustAnchor.label:SetText(L["mythicPlusBloodlustTrackerAnchor"] or "Bloodlust Tracker Anchor")
		bloodlustAnchor.label:SetAlpha(0)
	end

	if EditMode and not bloodlustEditModeRegistered then
		local settingType = EditMode.lib and EditMode.lib.SettingType
		local settings
		if settingType then
			local function buildSoundEntries()
				local entries = getCachedMediaNames("sound")
				local soundTable = getCachedMediaHash("sound")
				return entries, soundTable
			end

			local function getStoredSoundKey(dbKey)
				local entries, soundTable = buildSoundEntries()
				local current = addon.db and addon.db[dbKey]
				if type(current) == "string" and current ~= "" and soundTable[current] then return current, entries, soundTable end
				return "", entries, soundTable
			end

			local function setStoredSoundKey(dbKey, value, preview)
				local current, _, soundTable = getStoredSoundKey(dbKey)
				local selected = type(value) == "string" and value or ""
				if selected ~= "" and not soundTable[selected] then selected = "" end
				if addon.db then addon.db[dbKey] = selected end
				if preview and selected ~= "" and soundTable[selected] then PlaySoundFile(soundTable[selected], "Master") end
				return current
			end

			local function buildFontEntries()
				local entries = getCachedMediaNames("font")
				local fontTable = getCachedMediaHash("font")
				return entries, fontTable
			end

			local function buildBorderEntries()
				local entries = {
					{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
					{ value = "SOLID", label = "Solid" },
				}
				local names = getCachedMediaNames("border")
				for i = 1, #names do
					local name = names[i]
					entries[#entries + 1] = { value = name, label = name }
				end
				return entries
			end

			local function getStoredFontKey()
				local entries, fontTable = buildFontEntries()
				local current = normalizeBloodlustCooldownFontFace(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownFontFace"])
				if current ~= BLOODLUST_GLOBAL_FONT_KEY and not (fontTable and fontTable[current]) and not (current:find("\\", 1, true) or current:find("/", 1, true)) then
					current = BLOODLUST_GLOBAL_FONT_KEY
				end
				return current, entries, fontTable
			end

			local function setStoredFontKey(value)
				local selected = normalizeBloodlustCooldownFontFace(value)
				if addon.db then addon.db["mythicPlusBloodlustTrackerCooldownFontFace"] = selected end
				applyBloodlustCooldownVisualSettings()
			end

			local function outlineOptionLabel(value)
				if addon.functions and addon.functions.GetFontStyleLabel then return addon.functions.GetFontStyleLabel(value) end
				return value
			end

			settings = {
				{
					name = L["General"] or "General",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerGeneral",
					defaultCollapsed = false,
				},
				{
					name = L["mythicPlusBloodlustTrackerOnlyInInstances"] or "Only show in instances",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerGeneral",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerOnlyInInstances"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerOnlyInInstances"] = value == true end
						if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBloodlustFrame then
							addon.MythicPlus.functions.createBloodlustFrame()
							if addon.MythicPlus.functions.refreshBloodlustTracker then addon.MythicPlus.functions.refreshBloodlustTracker(false) end
						end
					end,
				},
				{
					name = L["Anchor"] or "Anchor",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerAnchor",
					defaultCollapsed = false,
				},
				{
					field = "anchorTarget",
					name = L["Anchor to"] or "Anchor to",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerAnchor",
					height = 220,
					default = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent",
					get = function()
						return validateTrackerAnchorTarget(addon.db["mythicPlusBloodlustTrackerRelativeFrame"], addon.db["mythicPlusBloodlustTrackerRelativeFrame"])
					end,
					set = function(_, value)
						local current = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent"
						local target = validateTrackerAnchorTarget(value, current)
						local defaults = getUserSelectedTrackerAnchorTargetDefaults(target)
						addon.db["mythicPlusBloodlustTrackerRelativeFrame"] = target
						addon.db["mythicPlusBloodlustTrackerPoint"] = defaults.point
						addon.db["mythicPlusBloodlustTrackerRelativePoint"] = defaults.relativePoint
						addon.db["mythicPlusBloodlustTrackerX"] = defaults.x
						addon.db["mythicPlusBloodlustTrackerY"] = defaults.y
						applyTrackerEditModeAnchorData(BLOODLUST_EDITMODE_ID, target, defaults)
						applyBloodlustLayoutData({
							anchorTarget = target,
							point = defaults.point,
							relativePoint = defaults.relativePoint,
							x = defaults.x,
							y = defaults.y,
						})
						if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
							addon.EditModeLib.internal:RefreshSettingValues()
						end
						if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BLOODLUST_EDITMODE_ID) end
					end,
					generator = function(_, root)
						local entries = getTrackerAnchorEntries(addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent")
						local current = validateTrackerAnchorTarget(addon.db["mythicPlusBloodlustTrackerRelativeFrame"], addon.db["mythicPlusBloodlustTrackerRelativeFrame"])
						for i = 1, #entries do
							local entry = entries[i]
							root:CreateRadio(entry.label, function() return current == entry.key end, function()
								local currentTarget = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent"
								local target = validateTrackerAnchorTarget(entry.key, currentTarget)
								local defaults = getUserSelectedTrackerAnchorTargetDefaults(target)
								addon.db["mythicPlusBloodlustTrackerRelativeFrame"] = target
								addon.db["mythicPlusBloodlustTrackerPoint"] = defaults.point
								addon.db["mythicPlusBloodlustTrackerRelativePoint"] = defaults.relativePoint
								addon.db["mythicPlusBloodlustTrackerX"] = defaults.x
								addon.db["mythicPlusBloodlustTrackerY"] = defaults.y
								applyTrackerEditModeAnchorData(BLOODLUST_EDITMODE_ID, target, defaults)
								applyBloodlustLayoutData({
									anchorTarget = target,
									point = defaults.point,
									relativePoint = defaults.relativePoint,
									x = defaults.x,
									y = defaults.y,
								})
								if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
									addon.EditModeLib.internal:RefreshSettingValues()
								end
								if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BLOODLUST_EDITMODE_ID) end
							end)
						end
					end,
				},
				{
					field = "point",
					name = L["Anchor point"] or "Anchor point",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerAnchor",
					height = 180,
					default = normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER"),
					get = function() return normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER") end,
					set = function(_, value)
						if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "point", value, nil, true) end
						applyBloodlustLayoutData({ point = value })
					end,
					generator = function(_, root)
						local options = getTrackerAnchorPointOptions()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(option.label, function() return normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER") == option.value end, function()
								if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "point", option.value, nil, true) end
								applyBloodlustLayoutData({ point = option.value })
							end)
						end
					end,
				},
				{
					field = "relativePoint",
					name = L["Relative point"] or "Relative point",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerAnchor",
					height = 180,
					default = normalizeTrackerAnchorPoint(addon.db["mythicPlusBloodlustTrackerRelativePoint"] or addon.db["mythicPlusBloodlustTrackerPoint"], "CENTER"),
					get = function()
						return normalizeTrackerAnchorPoint(
							addon.db["mythicPlusBloodlustTrackerRelativePoint"] or addon.db["mythicPlusBloodlustTrackerPoint"],
							addon.db["mythicPlusBloodlustTrackerPoint"] or "CENTER"
						)
					end,
					set = function(_, value)
						if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "relativePoint", value, nil, true) end
						applyBloodlustLayoutData({ relativePoint = value })
					end,
					generator = function(_, root)
						local options = getTrackerAnchorPointOptions()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(
								option.label,
								function()
									return normalizeTrackerAnchorPoint(
										addon.db["mythicPlusBloodlustTrackerRelativePoint"] or addon.db["mythicPlusBloodlustTrackerPoint"],
										addon.db["mythicPlusBloodlustTrackerPoint"] or "CENTER"
									) == option.value
								end,
								function()
									if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "relativePoint", option.value, nil, true) end
									applyBloodlustLayoutData({ relativePoint = option.value })
								end
							)
						end
					end,
				},
				{
					field = "x",
					name = L["X Offset"] or "X Offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerAnchor",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					default = addon.db["mythicPlusBloodlustTrackerX"] or 0,
					get = function() return addon.db["mythicPlusBloodlustTrackerX"] or 0 end,
					set = function(_, value)
						local x = tonumber(value) or 0
						if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "x", x, nil, true) end
						applyBloodlustLayoutData({ x = x })
					end,
				},
				{
					field = "y",
					name = L["Y Offset"] or "Y Offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerAnchor",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					default = addon.db["mythicPlusBloodlustTrackerY"] or 0,
					get = function() return addon.db["mythicPlusBloodlustTrackerY"] or 0 end,
					set = function(_, value)
						local y = tonumber(value) or 0
						if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "y", y, nil, true) end
						applyBloodlustLayoutData({ y = y })
					end,
				},
				{
					name = L["Layout"] or "Layout",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerLayout",
					defaultCollapsed = true,
				},
				{
					field = "size",
					name = L["Button Size"] or (L["Button Size"] or "Button Size"),
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerLayout",
					minValue = BLOODLUST_MIN_SIZE,
					maxValue = BLOODLUST_MAX_SIZE,
					valueStep = 1,
					default = normalizeBloodlustSize(addon.db["mythicPlusBloodlustButtonSize"] or defaultButtonSize),
					get = function() return normalizeBloodlustSize(addon.db["mythicPlusBloodlustButtonSize"] or defaultButtonSize) end,
					set = function(_, value)
						local size = normalizeBloodlustSize(value)
						addon.db["mythicPlusBloodlustButtonSize"] = size
						if EditMode and EditMode.SetValue then EditMode:SetValue(BLOODLUST_EDITMODE_ID, "size", size, nil, true) end
						applyBloodlustLayoutData()
					end,
				},
				{
					name = L["Tracker icon"] or "Tracker icon",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerLayout",
					get = function() return normalizeBloodlustIcon(addon.db and addon.db["mythicPlusBloodlustTrackerIcon"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerIcon"] = normalizeBloodlustIcon(value) end
						applyBloodlustLayoutData()
						if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBloodlustTracker then addon.MythicPlus.functions.refreshBloodlustTracker(false) end
					end,
					generator = function(_, root)
						for i = 1, #BLOODLUST_DEFAULT_ICON_IDS do
							local iconId = BLOODLUST_DEFAULT_ICON_IDS[i]
							local label = string.format("|T%d:22:22:0:0|t", iconId)
							root:CreateRadio(label, function() return normalizeBloodlustIcon(addon.db and addon.db["mythicPlusBloodlustTrackerIcon"]) == iconId end, function()
								if addon.db then addon.db["mythicPlusBloodlustTrackerIcon"] = iconId end
								applyBloodlustLayoutData()
								if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBloodlustTracker then
									addon.MythicPlus.functions.refreshBloodlustTracker(false)
								end
							end)
						end
					end,
				},
				{
					name = L["Icon zoom"] or "Icon zoom",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerLayout",
					minValue = TRACKER_ICON_ZOOM_MIN,
					maxValue = TRACKER_ICON_ZOOM_MAX,
					valueStep = 1,
					default = normalizeTrackerIconZoom(addon.db["mythicPlusBloodlustTrackerIconZoom"]),
					get = function() return normalizeTrackerIconZoom(addon.db["mythicPlusBloodlustTrackerIconZoom"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerIconZoom"] = normalizeTrackerIconZoom(value) end
						applyBloodlustLayoutData()
						if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBloodlustTracker then addon.MythicPlus.functions.refreshBloodlustTracker(false) end
					end,
				},
				{
					name = L["Border"] or "Border",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerBorder",
					defaultCollapsed = true,
				},
				{
					name = L["Use border"] or "Use border",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerBorder",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderEnabled"] = value == true end
						applyBloodlustBorderVisualSettings()
					end,
				},
				{
					name = L["Border texture"] or "Border texture",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerBorder",
					height = 220,
					get = function() return normalizeBloodlustBorderTexture(addon.db and addon.db["mythicPlusBloodlustTrackerBorderTexture"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderTexture"] = normalizeBloodlustBorderTexture(value) end
						applyBloodlustBorderVisualSettings()
					end,
					generator = function(_, root)
						local options = buildBorderEntries()
						for i = 1, #options do
							local option = options[i]
							root:CreateRadio(
								option.label,
								function() return normalizeBloodlustBorderTexture(addon.db and addon.db["mythicPlusBloodlustTrackerBorderTexture"]) == option.value end,
								function()
									if addon.db then addon.db["mythicPlusBloodlustTrackerBorderTexture"] = option.value end
									applyBloodlustBorderVisualSettings()
								end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false end,
				},
				{
					name = L["Border size"] or "Border size",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerBorder",
					minValue = BLOODLUST_BORDER_SIZE_MIN,
					maxValue = BLOODLUST_BORDER_SIZE_MAX,
					valueStep = 1,
					default = normalizeBloodlustBorderSize(addon.db and addon.db["mythicPlusBloodlustTrackerBorderSize"]),
					get = function() return normalizeBloodlustBorderSize(addon.db and addon.db["mythicPlusBloodlustTrackerBorderSize"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderSize"] = normalizeBloodlustBorderSize(value) end
						applyBloodlustBorderVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false end,
				},
				{
					name = L["Border offset"] or "Border offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerBorder",
					minValue = BLOODLUST_BORDER_OFFSET_MIN,
					maxValue = BLOODLUST_BORDER_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBloodlustBorderOffset(addon.db and addon.db["mythicPlusBloodlustTrackerBorderOffset"]),
					get = function() return normalizeBloodlustBorderOffset(addon.db and addon.db["mythicPlusBloodlustTrackerBorderOffset"]) end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderOffset"] = normalizeBloodlustBorderOffset(value) end
						applyBloodlustBorderVisualSettings()
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false end,
				},
				{
					name = EMBLEM_BORDER_COLOR,
					kind = settingType.Color,
					parentId = "mythicPlusBloodlustTrackerBorder",
					get = function()
						local c = normalizeBloodlustBorderColor(addon.db and addon.db["mythicPlusBloodlustTrackerBorderColor"])
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					set = function(_, color)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderColor"] = normalizeBloodlustBorderColor(color) end
						applyBloodlustBorderVisualSettings()
					end,
					colorGet = function()
						local c = normalizeBloodlustBorderColor(addon.db and addon.db["mythicPlusBloodlustTrackerBorderColor"])
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					colorSet = function(_, color)
						if addon.db then addon.db["mythicPlusBloodlustTrackerBorderColor"] = normalizeBloodlustBorderColor(color) end
						applyBloodlustBorderVisualSettings()
					end,
					colorDefault = { r = 1, g = 1, b = 1, a = 1 },
					hasOpacity = true,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerBorderEnabled"] ~= false end,
				},
				{
					name = L["Cooldown"] or "Cooldown",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerCooldown",
					defaultCollapsed = false,
				},
				{
					name = L["Draw cooldown swipe"] or "Draw cooldown swipe",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] = value == true end
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = L["Draw cooldown edge"] or "Draw cooldown edge",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerCooldownDrawEdge"] = value == true end
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = L["Draw cooldown bling"] or "Draw cooldown bling",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerCooldownDrawBling"] = value == true end
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = "",
					kind = settingType.Divider,
					parentId = "mythicPlusBloodlustTrackerCooldown",
				},
				{
					name = L["Cooldown font"] or "Cooldown font",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					height = 280,
					get = function()
						local current = getStoredFontKey()
						return current
					end,
					set = function(_, value) setStoredFontKey(value) end,
					generator = function(_, root)
						local _, entries = getStoredFontKey()
						root:CreateRadio(BLOODLUST_GLOBAL_FONT_LABEL, function() return getStoredFontKey() == BLOODLUST_GLOBAL_FONT_KEY end, function() setStoredFontKey(BLOODLUST_GLOBAL_FONT_KEY) end)
						for i = 1, #entries do
							local fontName = entries[i]
							root:CreateRadio(fontName, function() return getStoredFontKey() == fontName end, function() setStoredFontKey(fontName) end)
						end
					end,
				},
				{
					name = L["Cooldown text size"] or "Cooldown text size",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					minValue = BLOODLUST_COOLDOWN_TEXT_SIZE_MIN,
					maxValue = BLOODLUST_COOLDOWN_TEXT_SIZE_MAX,
					valueStep = 1,
					default = normalizeBloodlustCooldownTextSize(addon.db["mythicPlusBloodlustTrackerCooldownTextSize"]),
					get = function() return normalizeBloodlustCooldownTextSize(addon.db["mythicPlusBloodlustTrackerCooldownTextSize"]) end,
					set = function(_, value)
						addon.db["mythicPlusBloodlustTrackerCooldownTextSize"] = normalizeBloodlustCooldownTextSize(value)
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = L["Cooldown text outline"] or "Cooldown text outline",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					get = function() return normalizeBloodlustCooldownOutline(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"]) end,
					set = function(_, value)
						addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"] = normalizeBloodlustCooldownOutline(value)
						applyBloodlustCooldownVisualSettings()
					end,
					generator = function(_, root)
						for i = 1, #BLOODLUST_COOLDOWN_OUTLINE_OPTIONS do
							local option = BLOODLUST_COOLDOWN_OUTLINE_OPTIONS[i]
							local value = option.value
							root:CreateRadio(
								outlineOptionLabel(value),
								function() return normalizeBloodlustCooldownOutline(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"]) == value end,
								function()
									addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"] = value
									applyBloodlustCooldownVisualSettings()
								end
							)
						end
					end,
				},
				{
					name = L["Cooldown text color"] or "Cooldown text color",
					kind = settingType.Color,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					get = function()
						local c = normalizeBloodlustCooldownColor(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextColor"])
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					set = function(_, color)
						addon.db["mythicPlusBloodlustTrackerCooldownTextColor"] = normalizeBloodlustCooldownColor(color)
						applyBloodlustCooldownVisualSettings()
					end,
					colorGet = function()
						local c = normalizeBloodlustCooldownColor(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextColor"])
						return { r = c[1], g = c[2], b = c[3], a = c[4] }
					end,
					colorSet = function(_, color)
						addon.db["mythicPlusBloodlustTrackerCooldownTextColor"] = normalizeBloodlustCooldownColor(color)
						applyBloodlustCooldownVisualSettings()
					end,
					colorDefault = { r = 1, g = 1, b = 1, a = 1 },
					hasOpacity = true,
				},
				{
					name = L["Cooldown text X offset"] or "Cooldown text X offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					minValue = BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN,
					maxValue = BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"]),
					get = function() return normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"]) end,
					set = function(_, value)
						addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"] = normalizeBloodlustCooldownTextOffset(value)
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = L["Cooldown text Y offset"] or "Cooldown text Y offset",
					kind = settingType.Slider,
					parentId = "mythicPlusBloodlustTrackerCooldown",
					minValue = BLOODLUST_COOLDOWN_TEXT_OFFSET_MIN,
					maxValue = BLOODLUST_COOLDOWN_TEXT_OFFSET_MAX,
					valueStep = 1,
					default = normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"]),
					get = function() return normalizeBloodlustCooldownTextOffset(addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"]) end,
					set = function(_, value)
						addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"] = normalizeBloodlustCooldownTextOffset(value)
						applyBloodlustCooldownVisualSettings()
					end,
				},
				{
					name = SOUND or "Sound",
					kind = settingType.Collapsible,
					id = "mythicPlusBloodlustTrackerSound",
					defaultCollapsed = false,
				},
				{
					name = L["mythicPlusBloodlustTrackerSoundOnDebuffActive"] or "Play sound when Bloodlust lockout becomes active",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] = value == true end
					end,
				},
				{
					name = L["mythicPlusBloodlustTrackerUseCustomDebuffSound"] or "Use custom sound for active lockout",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerUseCustomDebuffSound"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerUseCustomDebuffSound"] = value == true end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] == true end,
				},
				{
					name = L["mythicPlusBloodlustTrackerDebuffSound"] or "Active lockout sound",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerSound",
					height = 280,
					get = function()
						local value = getStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile")
						return value
					end,
					set = function(_, value) setStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile", value, true) end,
					generator = function(_, root)
						local _, entries = getStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile")
						root:CreateRadio(
							NONE,
							function() return getStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile") == "" end,
							function() setStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile", "", false) end
						)
						for i = 1, #entries do
							local soundName = entries[i]
							root:CreateRadio(
								soundName,
								function() return getStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile") == soundName end,
								function() setStoredSoundKey("mythicPlusBloodlustTrackerDebuffSoundFile", soundName, true) end
							)
						end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] == true and addon.db["mythicPlusBloodlustTrackerUseCustomDebuffSound"] == true end,
				},
				{
					name = "",
					kind = settingType.Divider,
					parentId = "mythicPlusBloodlustTrackerSound",
				},
				{
					name = L["mythicPlusBloodlustTrackerSoundOnDebuffFade"] or "Play sound when Bloodlust lockout fades",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"] = value == true end
					end,
				},
				{
					name = L["mythicPlusBloodlustTrackerUseCustomFadeSound"] or "Use custom sound for lockout fade",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerUseCustomFadeSound"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerUseCustomFadeSound"] = value == true end
					end,
					isEnabled = function() return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"] == true end,
				},
				{
					name = L["mythicPlusBloodlustTrackerFadeSound"] or "Lockout fade sound",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerSound",
					height = 280,
					get = function()
						local value = getStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile")
						return value
					end,
					set = function(_, value) setStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile", value, true) end,
					generator = function(_, root)
						local _, entries = getStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile")
						root:CreateRadio(
							NONE,
							function() return getStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile") == "" end,
							function() setStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile", "", false) end
						)
						for i = 1, #entries do
							local soundName = entries[i]
							root:CreateRadio(
								soundName,
								function() return getStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile") == soundName end,
								function() setStoredSoundKey("mythicPlusBloodlustTrackerFadeSoundFile", soundName, true) end
							)
						end
					end,
					isEnabled = function()
						return addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"] == true
							and addon.db["mythicPlusBloodlustTrackerUseCustomFadeSound"] == true
					end,
				},
				{
					name = L["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] or "Play sound on ENCOUNTER_START when Bloodlust is ready",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] = value == true end
					end,
				},
				{
					name = L["mythicPlusBloodlustTrackerUseCustomReadySound"] or "Use custom sound for ready reminder",
					kind = settingType.Checkbox,
					parentId = "mythicPlusBloodlustTrackerSound",
					get = function() return addon.db and addon.db["mythicPlusBloodlustTrackerUseCustomReadySound"] == true end,
					set = function(_, value)
						if addon.db then addon.db["mythicPlusBloodlustTrackerUseCustomReadySound"] = value == true end
					end,
					isEnabled = function()
						return addon.db and addon.db["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] == true
					end,
				},
				{
					name = L["mythicPlusBloodlustTrackerReadySound"] or "Ready reminder sound",
					kind = settingType.Dropdown,
					parentId = "mythicPlusBloodlustTrackerSound",
					height = 280,
					get = function()
						local value = getStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile")
						return value
					end,
					set = function(_, value) setStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile", value, true) end,
					generator = function(_, root)
						local _, entries = getStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile")
						root:CreateRadio(
							NONE,
							function() return getStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile") == "" end,
							function() setStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile", "", false) end
						)
						for i = 1, #entries do
							local soundName = entries[i]
							root:CreateRadio(
								soundName,
								function() return getStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile") == soundName end,
								function() setStoredSoundKey("mythicPlusBloodlustTrackerReadySoundFile", soundName, true) end
							)
						end
					end,
					isEnabled = function()
						return addon.db and addon.db["mythicPlusBloodlustTrackerUseCustomReadySound"] == true
							and addon.db["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] == true
					end,
				},
			}
		end

		EditMode:RegisterFrame(BLOODLUST_EDITMODE_ID, {
			frame = bloodlustAnchor,
			title = L["mythicPlusBloodlustTrackerAnchor"] or "Bloodlust Tracker Anchor",
			layoutDefaults = {
				point = addon.db["mythicPlusBloodlustTrackerPoint"] or "CENTER",
				relativePoint = addon.db["mythicPlusBloodlustTrackerRelativePoint"] or addon.db["mythicPlusBloodlustTrackerPoint"] or "CENTER",
				anchorTarget = addon.db["mythicPlusBloodlustTrackerRelativeFrame"] or "UIParent",
				x = addon.db["mythicPlusBloodlustTrackerX"] or 0,
				y = addon.db["mythicPlusBloodlustTrackerY"] or 0,
				size = addon.db["mythicPlusBloodlustButtonSize"] or defaultButtonSize,
			},
			legacyKeys = {
				point = "mythicPlusBloodlustTrackerPoint",
				relativePoint = "mythicPlusBloodlustTrackerRelativePoint",
				x = "mythicPlusBloodlustTrackerX",
				y = "mythicPlusBloodlustTrackerY",
				size = "mythicPlusBloodlustButtonSize",
			},
			isEnabled = function() return addon.db["mythicPlusBloodlustTrackerEnabled"] end,
			onApply = function(_, layoutName, data)
				if not bloodlustAnchor._eqolEditModeHydrated then
					bloodlustAnchor._eqolEditModeHydrated = true
					local record = data or {}
					seedBloodlustEditModeRecordFromProfile(record)
					applyBloodlustLayoutData(record)
					return
				end
				applyBloodlustLayoutData(data)
			end,
			onPositionChanged = function(_, _, data)
				applyBloodlustLayoutData(data)
				if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
					addon.EditModeLib.internal:RefreshSettingValues()
				end
			end,
			settings = settings,
			relativeTo = function() return resolveTrackerAnchorFrame(addon.db and addon.db["mythicPlusBloodlustTrackerRelativeFrame"]) end,
			allowDrag = function() return trackerAnchorUsesUIParent(addon.db and addon.db["mythicPlusBloodlustTrackerRelativeFrame"]) end,
			managePosition = false,
			persistPosition = false,
		})
		bloodlustEditModeRegistered = true
	end
	applyBloodlustLayoutData()

	return bloodlustAnchor
end

local function shouldShowBloodlustTracker()
	if not addon.db["mythicPlusBloodlustTrackerEnabled"] then return false end
	if not IsInInstance() then return false end
	local _, _, diff = GetInstanceInfo()
	if diff == BLOODLUST_DELVE_DIFFICULTY_ID then return true end
	if not IsInGroup() then return false end
	if diff == 8 then return true end
	if isRaidDifficulty(diff) then return C_InstanceEncounter.IsEncounterInProgress() end
	return false
end

local function shouldAllowBloodlustTrackerScope()
	if not addon.db["mythicPlusBloodlustTrackerOnlyInInstances"] then return true end
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return false end
	local _, _, diff = GetInstanceInfo()
	return instanceType == "party" or instanceType == "raid" or instanceType == "scenario" or diff == BLOODLUST_DELVE_DIFFICULTY_ID
end

local function shouldShowBloodlustFrame()
	return shouldShowBloodlustTracker() or (bloodlustStateActive and shouldAllowBloodlustTrackerScope())
end

local function getBloodlustDefaultIcon()
	local configured = getBloodlustConfiguredIcon()
	if configured then return configured end
	if issecretvalue and issecretvalue(BLOODLUST_READY_SPELL_ID) then return BLOODLUST_FALLBACK_ICON end
	if C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(BLOODLUST_READY_SPELL_ID)
		if texture and not (issecretvalue and issecretvalue(texture)) then return texture end
	end
	return BLOODLUST_FALLBACK_ICON
end

local function createBloodlustFrame()
	removeBloodlustFrame()
	if not addon.db["mythicPlusBloodlustTrackerEnabled"] then
		if bloodlustAnchor then bloodlustAnchor:Hide() end
		if EditMode then EditMode:RefreshFrame(BLOODLUST_EDITMODE_ID) end
		return
	end

	local layout = buildBloodlustLayoutSnapshot()
	ensureBloodlustAnchor()
	if shouldShowBloodlustFrame() then
		local point = layout.point or "CENTER"
		local relativePoint = layout.relativePoint or point
		local xOfs = layout.x or 0
		local yOfs = layout.y or 0
		local size = layout.size or defaultButtonSize
		local defaultIcon = getBloodlustDefaultIcon()

		bloodlustButton = CreateFrame("Button", nil, UIParent)
		bloodlustButton:SetClampedToScreen(true)
		bloodlustButton:SetSize(size, size)
		bloodlustButton:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
		setFrameClickThrough(bloodlustButton)

		local bg = bloodlustButton:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(bloodlustButton)
		bg:SetColorTexture(0, 0, 0, 0.8)

		local icon = bloodlustButton:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(bloodlustButton)
		icon:SetTexture(defaultIcon)
		applyTrackerIconZoom(icon, addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"])
		bloodlustButton.icon = icon
		bloodlustButton.defaultIcon = defaultIcon

		bloodlustButton.border = CreateFrame("Frame", nil, bloodlustButton, "BackdropTemplate")
		bloodlustButton.border:SetFrameLevel((bloodlustButton:GetFrameLevel() or 0) + 5)
		bloodlustButton.border:SetFrameStrata(bloodlustButton:GetFrameStrata())

		bloodlustButton.textOverlay = CreateFrame("Frame", nil, bloodlustButton)
		bloodlustButton.textOverlay:SetAllPoints(bloodlustButton)
		bloodlustButton.textOverlay:EnableMouse(false)

		local scaleFactor = size / defaultButtonSize
		local timerFontSize = math.floor(defaultFontSize * 0.75 * scaleFactor + 0.5)
		if timerFontSize < 10 then timerFontSize = 10 end

		bloodlustButton.cooldownFrame = CreateFrame("Cooldown", nil, bloodlustButton, "CooldownFrameTemplate")
		bloodlustButton.cooldownFrame:SetAllPoints(bloodlustButton)
		bloodlustButton.cooldownFrame:SetSwipeColor(0, 0, 0, 0.45)
		bloodlustButton.cooldownFrame:SetCountdownAbbrevThreshold(600)
		bloodlustButton.cooldownFrame:SetScale(1)
		if bloodlustButton.cooldownFrame.SetDrawSwipe then bloodlustButton.cooldownFrame:SetDrawSwipe(addon.db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false) end
		if bloodlustButton.cooldownFrame.SetDrawEdge then bloodlustButton.cooldownFrame:SetDrawEdge(addon.db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true) end
		if bloodlustButton.cooldownFrame.SetDrawBling then bloodlustButton.cooldownFrame:SetDrawBling(addon.db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true) end
		if bloodlustButton.cooldownFrame.SetHideCountdownNumbers then bloodlustButton.cooldownFrame:SetHideCountdownNumbers(false) end

		bloodlustButton.status = bloodlustButton.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		bloodlustButton.status:SetPoint("BOTTOM", bloodlustButton, "BOTTOM", 0, 4)
		bloodlustButton.status:SetFont(addon.variables.defaultFont, timerFontSize, "OUTLINE")
		bloodlustButton.status:SetText(L["mythicPlusBloodlustTrackerReadyLabel"] or "READY")
		bloodlustButton.status:SetTextColor(0.2, 1, 0.2)
		bloodlustButton.cooldownFrame:Clear()
		applyBloodlustCooldownVisualSettings()
		applyBloodlustBorderVisualSettings()
	end

	applyBloodlustLayoutData(layout)
	if EditMode then EditMode:RefreshFrame(BLOODLUST_EDITMODE_ID) end
end

addon.MythicPlus.functions.createBloodlustFrame = createBloodlustFrame

local function clearBloodlustTrackedAuraInstances()
	if wipe then
		wipe(bloodlustTrackedAuraInstanceIDs)
	else
		for key in pairs(bloodlustTrackedAuraInstanceIDs) do
			bloodlustTrackedAuraInstanceIDs[key] = nil
		end
	end
end

local function isTrackedBloodlustSpell(spellId)
	if spellId == nil then return false end
	if issecretvalue and issecretvalue(spellId) then return false end
	spellId = tonumber(spellId)
	if not spellId then return false end
	return BLOODLUST_LOCKOUT_SET[spellId] == true
end

local function getActiveBloodlustAura()
	local unitGetter = C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID
	local playerGetter = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
	if not unitGetter and not playerGetter then return nil, false end

	for i = 1, #BLOODLUST_LOCKOUT_IDS do
		local spellId = BLOODLUST_LOCKOUT_IDS[i]
		if not (issecretvalue and issecretvalue(spellId)) then
			local aura = nil
			if unitGetter then aura = unitGetter("player", spellId) end
			if not aura and playerGetter then aura = playerGetter(spellId) end
			-- Query-by-ID on a whitelisted lockout spell is authoritative enough here.
			if aura then return aura, true end
		end
	end

	return nil, true
end

local function shouldRefreshBloodlustFromUpdateInfo(updateInfo)
	-- Active lockout fast path: only refresh if tracked aura got removed (or full/secret update).
	if bloodlustStateActive then
		if type(updateInfo) ~= "table" then return false end
		if issecretvalue and issecretvalue(updateInfo) then return true end
		if updateInfo.isFullUpdate == true then return true end

		local removedIDs = updateInfo.removedAuraInstanceIDs
		if type(removedIDs) ~= "table" then return false end
		for i = 1, #removedIDs do
			local auraInstanceID = removedIDs[i]
			if issecretvalue and issecretvalue(auraInstanceID) then return true end
			if auraInstanceID and bloodlustTrackedAuraInstanceIDs[auraInstanceID] then return true end
		end
		return false
	end

	if type(updateInfo) ~= "table" then return true end
	if issecretvalue and issecretvalue(updateInfo) then return true end
	if updateInfo.isFullUpdate == true then return true end

	local addedAuras = updateInfo.addedAuras
	if type(addedAuras) == "table" then
		for i = 1, #addedAuras do
			local aura = addedAuras[i]
			if type(aura) == "table" then
				local spellId = aura.spellId
				if issecretvalue and issecretvalue(spellId) then return true end
				if isTrackedBloodlustSpell(spellId) then return true end
			end
		end
	end

	local removedIDs = updateInfo.removedAuraInstanceIDs
	if type(removedIDs) == "table" then
		for i = 1, #removedIDs do
			local auraInstanceID = removedIDs[i]
			if issecretvalue and issecretvalue(auraInstanceID) then return true end
			if auraInstanceID and bloodlustTrackedAuraInstanceIDs[auraInstanceID] then return true end
		end
	end

	local updatedIDs = updateInfo.updatedAuraInstanceIDs
	if type(updatedIDs) == "table" then
		local getByInstanceID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
		for i = 1, #updatedIDs do
			local auraInstanceID = updatedIDs[i]
			if issecretvalue and issecretvalue(auraInstanceID) then return true end
			if auraInstanceID and bloodlustTrackedAuraInstanceIDs[auraInstanceID] then return true end
			if getByInstanceID and auraInstanceID then
				local aura = getByInstanceID("player", auraInstanceID)
				if aura then
					local spellId = aura.spellId
					if issecretvalue and issecretvalue(spellId) then return true end
					if isTrackedBloodlustSpell(spellId) then return true end
				end
			end
		end
	end

	-- Some clients emit UNIT_AURA with sparse/empty updateInfo payloads.
	-- In that case, do a safe full refresh to avoid missing lockout transitions.
	local addedCount = type(addedAuras) == "table" and #addedAuras or 0
	local removedCount = type(removedIDs) == "table" and #removedIDs or 0
	local updatedCount = type(updatedIDs) == "table" and #updatedIDs or 0
	if addedCount == 0 and removedCount == 0 and updatedCount == 0 then return true end

	return false
end

local function getCustomSoundFile(settingKey)
	if not addon.db then return nil end
	local soundName = addon.db[settingKey]
	if type(soundName) ~= "string" or soundName == "" then return nil end
	local soundTable = getCachedMediaHash("sound")
	return soundTable and soundTable[soundName] or nil
end

local function getBloodlustFallbackSoundKit(soundSettingKey)
	if not SOUNDKIT then return nil end
	if soundSettingKey == "mythicPlusBloodlustTrackerFadeSoundFile" then return SOUNDKIT.READY_CHECK or SOUNDKIT.RAID_WARNING end
	if soundSettingKey == "mythicPlusBloodlustTrackerReadySoundFile" then return SOUNDKIT.READY_CHECK or SOUNDKIT.RAID_WARNING end
	return SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK
end

local function playBloodlustSound(useCustomKey, soundSettingKey, fallbackSoundKit)
	if not addon.db then return end
	local file = nil
	if addon.db[useCustomKey] == true then file = getCustomSoundFile(soundSettingKey) end
	if file then
		PlaySoundFile(file, "Master")
	elseif PlaySound then
		local kit = fallbackSoundKit or getBloodlustFallbackSoundKit(soundSettingKey)
		if kit then PlaySound(kit, "Master") end
	end
end

local function applyBloodlustAuraToFrame(aura)
	if not bloodlustButton then return end
	local icon = bloodlustButton.defaultIcon or getBloodlustDefaultIcon()

	if aura then
		bloodlustButton.icon:SetTexture(icon)
		applyTrackerIconZoom(bloodlustButton.icon, addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"])
		bloodlustButton.icon:SetDesaturated(true)

		local duration = aura.duration
		local expiration = aura.expirationTime
		if issecretvalue and (issecretvalue(duration) or issecretvalue(expiration)) then
			duration = nil
			expiration = nil
		end
		duration = duration and tonumber(duration) or nil
		expiration = expiration and tonumber(expiration) or nil
		if duration and duration > 0 and expiration and expiration > 0 then
			bloodlustButton.cooldownFrame:SetCooldown(expiration - duration, duration)
		else
			bloodlustButton.cooldownFrame:Clear()
		end
		if bloodlustButton.status then
			bloodlustButton.status:SetText("")
			bloodlustButton.status:SetTextColor(1, 0.2, 0.2)
		end
	else
		bloodlustButton.icon:SetTexture(icon)
		applyTrackerIconZoom(bloodlustButton.icon, addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"])
		bloodlustButton.icon:SetDesaturated(false)
		bloodlustButton.cooldownFrame:Clear()
		if bloodlustButton.status then
			bloodlustButton.status:SetText(L["mythicPlusBloodlustTrackerReadyLabel"] or "READY")
			bloodlustButton.status:SetTextColor(0.2, 1, 0.2)
		end
	end

	-- Cooldown timer text is created lazily by Blizzard code; re-apply style after state updates.
	applyBloodlustLiveCooldownTextStyle(true)
end

local function refreshBloodlustTracker(playReadySound)
	local aura, known = getActiveBloodlustAura()
	if not known then return false end

	clearBloodlustTrackedAuraInstances()
	local auraInstanceID = aura and aura.auraInstanceID
	if auraInstanceID and not (issecretvalue and issecretvalue(auraInstanceID)) then bloodlustTrackedAuraInstanceIDs[auraInstanceID] = true end

	local isActive = aura ~= nil
	local classToken = addon.variables.unitClass
	local allowNotifications = shouldAllowBloodlustTrackerScope()
	local shouldPlayDebuffActiveSound = false
	local shouldPlayDebuffFadeSound = false
	if allowNotifications and bloodlustStateInitialized and not bloodlustStateActive and isActive and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] then
		local expiration = aura and aura.expirationTime
		if expiration and not (issecretvalue and issecretvalue(expiration)) then
			expiration = tonumber(expiration)
			if expiration and expiration > 0 then
				local remaining = expiration - GetTime()
				shouldPlayDebuffActiveSound = remaining > BLOODLUST_ACTIVE_SOUND_MIN_REMAINING
			end
		end
	end
	if allowNotifications and bloodlustStateInitialized and bloodlustStateActive and not isActive and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"]
		and BLOODLUST_READY_CLASSES[classToken]
	then
		shouldPlayDebuffFadeSound = true
	end
	if shouldPlayDebuffActiveSound then playBloodlustSound("mythicPlusBloodlustTrackerUseCustomDebuffSound", "mythicPlusBloodlustTrackerDebuffSoundFile") end
	if shouldPlayDebuffFadeSound then playBloodlustSound("mythicPlusBloodlustTrackerUseCustomFadeSound", "mythicPlusBloodlustTrackerFadeSoundFile") end
	if allowNotifications and playReadySound and not isActive and addon.db["mythicPlusBloodlustTrackerReadySoundOnEncounterStart"] and BLOODLUST_READY_CLASSES[classToken] then
		playBloodlustSound("mythicPlusBloodlustTrackerUseCustomReadySound", "mythicPlusBloodlustTrackerReadySoundFile")
	end

	bloodlustStateActive = isActive
	bloodlustStateInitialized = true
	applyBloodlustAuraToFrame(aura)
	return true
end

addon.MythicPlus.functions.refreshBloodlustTracker = refreshBloodlustTracker
addon.MythicPlus.functions.syncBloodlustUnitAuraRegistration = syncBloodlustUnitAuraRegistration

local function reapplyTrackerAnchors()
	if not addon.db then
		cancelTrackerAnchorReapplyTicker()
		return false
	end

	local variables = addon.MythicPlus and addon.MythicPlus.variables
	if variables then variables.trackerAnchorReapplyAttempts = (variables.trackerAnchorReapplyAttempts or 0) + 1 end

	if addon.db["mythicPlusBRTrackerEnabled"] then
		ensureBRAnchor()
		applyBRLayoutData()
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BR_EDITMODE_ID) end
	end

	if addon.db["mythicPlusBloodlustTrackerEnabled"] then
		ensureBloodlustAnchor()
		applyBloodlustLayoutData()
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(BLOODLUST_EDITMODE_ID) end
	end

	if not trackersNeedAnchorReapply() then
		cancelTrackerAnchorReapplyTicker()
		return false
	end

	if variables and (variables.trackerAnchorReapplyAttempts or 0) >= 15 then
		cancelTrackerAnchorReapplyTicker()
		return false
	end

	return true
end

local function scheduleTrackerAnchorReapply()
	if not addon.db or not trackersNeedAnchorReapply() then
		cancelTrackerAnchorReapplyTicker()
		return
	end

	local variables = addon.MythicPlus and addon.MythicPlus.variables
	if not variables or variables.trackerAnchorReapplyBusy then return end

	if not variables.trackerAnchorReapplyTicker then variables.trackerAnchorReapplyAttempts = 0 end

	variables.trackerAnchorReapplyBusy = true
	local shouldContinue = reapplyTrackerAnchors()
	variables.trackerAnchorReapplyBusy = nil
	if not shouldContinue or variables.trackerAnchorReapplyTicker or not (C_Timer and C_Timer.NewTicker) then return end

	variables.trackerAnchorReapplyTicker = C_Timer.NewTicker(0.2, function()
		if variables.trackerAnchorReapplyBusy then return end
		variables.trackerAnchorReapplyBusy = true
		local keepTrying = reapplyTrackerAnchors()
		variables.trackerAnchorReapplyBusy = nil
		if not keepTrying then cancelTrackerAnchorReapplyTicker() end
	end)
end

addon.MythicPlus.functions.ReapplyTrackerAnchors = reapplyTrackerAnchors
addon.MythicPlus.functions.ScheduleTrackerAnchorReapply = scheduleTrackerAnchorReapply
addon.MythicPlus.functions.ReapplyTrackerAnchorsForTarget = function(target)
	if not addon.db then return false end
	if type(target) ~= "string" or target == "" then return false end

	local needsBR = addon.db["mythicPlusBRTrackerEnabled"] and trackerUsesAnchorTarget("mythicPlusBRTrackerRelativeFrame", target)
	local needsBloodlust = addon.db["mythicPlusBloodlustTrackerEnabled"] and trackerUsesAnchorTarget("mythicPlusBloodlustTrackerRelativeFrame", target)
	if not needsBR and not needsBloodlust then return false end

	reapplyTrackerAnchors()
	return true
end

local function setBRInfo(info)
	if brButton and brButton.cooldownFrame and info then
		local current = info.currentCharges
		local max = info.maxCharges

		if issecretvalue and issecretvalue(current) then
			brButton.cooldownFrame:SetCooldown(info.cooldownStartTime, info.cooldownDuration, info.chargeModRate)
			brButton.cooldownFrame.startTime = info.cooldownStartTime
			brButton.cooldownFrame.charges = C_StringUtil.TruncateWhenZero(current)
			brButton.icon:SetDesaturated(false)
			brButton.cooldownFrame:SetSwipeColor(0, 0, 0, 0.3)
		elseif current < max then
			if brButton.cooldownFrame.charges ~= current or brButton.cooldownFrame.startTime ~= info.cooldownStartTime then
				brButton.cooldownFrame:SetCooldown(info.cooldownStartTime, info.cooldownDuration, info.chargeModRate)
				brButton.cooldownFrame.startTime = info.cooldownStartTime
				brButton.cooldownFrame.charges = current

				if current > 0 then
					brButton.icon:SetDesaturated(false)
					brButton.cooldownFrame:SetSwipeColor(0, 0, 0, 0.3)
				else
					brButton.cooldownFrame:SetSwipeColor(0, 0, 0, 1)
					brButton.icon:SetDesaturated(true)
				end
			end
		else
			brButton.cooldownFrame:Clear()
			brButton.cooldownFrame.startTime = nil
			brButton.cooldownFrame.charges = current
			brButton.cooldownFrame:SetSwipeColor(0, 0, 0, 0.3)
			brButton.icon:SetDesaturated(false)
		end
		updateBRChargesDisplay(current, max)
		applyBRLiveCooldownTextStyle(true)
	end
end

hooksecurefunc(ScenarioObjectiveTracker.ChallengeModeBlock, "UpdateTime", function(self, elapsedTime)
	if addon.db["mythicPlusBRTrackerEnabled"] then
		if not brButton or not brButton.cooldownFrame or not brButton.cooldownFrame.cooldownSet then
			createBRFrame()
			if brButton and brButton.cooldownFrame then
				brButton.cooldownFrame.cooldownSet = true
				local info = C_Spell.GetSpellCharges(20484)
				setBRInfo(info)
			end
		end
	end

	if addon.db["mythicPlusBloodlustTrackerEnabled"] then
		if shouldShowBloodlustTracker() then
			if not bloodlustButton or not bloodlustButton.cooldownFrame then
				createBloodlustFrame()
				refreshBloodlustTracker(false)
			end
		else
			removeBloodlustFrame()
		end
	end

	if not addon.db["enableKeystoneHelper"] or not addon.db["mythicPlusShowChestTimers"] then return end

	-- Always show chest timers in challenge mode
	local timeLeft = math.max(0, self.timeLimit - elapsedTime)
	local chest3Time = self.timeLimit * 0.4
	local chest2Time = self.timeLimit * 0.2

	if not self.CustomTextAdded then
		self.ChestTimeText2 = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		self.ChestTimeText2:SetPoint("TOPLEFT", self.TimeLeft, "TOPRIGHT", 4, 2)
		self.ChestTimeText2:SetJustifyH("LEFT")
		self.ChestTimeText3 = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		self.ChestTimeText3:SetPoint("BOTTOMLEFT", self.TimeLeft, "BOTTOMRIGHT", 4, 0)
		self.ChestTimeText3:SetJustifyH("LEFT")
		self.CustomTextAdded = true
	end

	if timeLeft > 0 then
		local chestText3 = ""
		local chestText2 = ""

		if timeLeft >= chest3Time then chestText3 = string.format("+3: %s", SecondsToClock(timeLeft - chest3Time)) end
		if timeLeft >= chest2Time then chestText2 = string.format("+2: %s", SecondsToClock(timeLeft - chest2Time)) end

		self.ChestTimeText2:SetText(chestText2)
		self.ChestTimeText3:SetText(chestText3)
	else
		self.ChestTimeText2:SetText("")
		self.ChestTimeText3:SetText("")
	end
end)

local function GetScenarioPercent(criteriaIndex)
	local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	if criteriaInfo and criteriaInfo.isWeightedProgress then
		local sValue = criteriaInfo.quantity
		if criteriaInfo.quantityString then
			sValue = tonumber(string.sub(criteriaInfo.quantityString, 1, string.len(criteriaInfo.quantityString) - 1)) / criteriaInfo.totalQuantity * 100
			sValue = math.floor(sValue * 100 + 0.5) / 100
		end
		return sValue
	end
	return nil
end

hooksecurefunc(ScenarioTrackerProgressBarMixin, "SetValue", function(self, percentage)
	-- Always show decimal progress for enemy forces in M+
	if not IsInInstance() or not self:IsVisible() then return end
	local _, _, diff = GetInstanceInfo()
	if diff ~= 8 then return end -- only in mythic challenge mode
	local sData = C_ScenarioInfo.GetScenarioStepInfo()
	if nil == sData then return end

	local truePercent
	if self.criteriaIndex then self.criteriaIndex = nil end
	for criteriaIndex = 1, sData.numCriteria do
		if nil == truePercent then
			truePercent = GetScenarioPercent(criteriaIndex)
			if truePercent then
				self.Bar.Label:SetFormattedText(truePercent .. "%%")
				self.percentage = percentage
			end
		end
	end
end)

local function createButtons()
	-- Always use improved Keystone Helper UI
	addon.MythicPlus.functions.addRCButton()
	addon.MythicPlus.functions.addPullButton()
end

local function checkKeyStone()
	addon.MythicPlus.variables.handled = false -- reset handle on Keystoneframe open
	addon.MythicPlus.functions.removeExistingButton()
	if not addon.db["enableKeystoneHelper"] then return end
	local GetContainerNumSlots = C_Container.GetContainerNumSlots
	local GetContainerItemID = C_Container.GetContainerItemID
	local UseContainerItem = C_Container.UseContainerItem
	local GetContainerItemInfo = C_Container.GetContainerItemInfo

	local kId = C_MythicPlus.GetOwnedKeystoneMapID()
	local mapId = select(8, GetInstanceInfo())
	if nil ~= kId and mapId == kId then
		for container = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(container) do
				local id = GetContainerItemID(container, slot)
				if id == 180653 or id == 151086 then
					-- Button for ReadyCheck and Pulltimer
					if UnitInParty("player") and UnitIsGroupLeader("player") then createButtons() end

					if addon.db["autoInsertKeystone"] and addon.db["autoInsertKeystone"] == true then
						UseContainerItem(container, slot)
						if addon.db["closeBagsOnKeyInsert"] and addon.db["closeBagsOnKeyInsert"] == true then CloseAllBags() end
					end
					break
				end
			end
		end
	end
end

-- Funktion zum Umgang mit Events
local function eventHandler(self, event, arg1, arg2, arg3, arg4)
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- loadMain()
	elseif event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
		if InCombatLockdown() then return end
		if addon.db["enableKeystoneHelper"] then checkKeyStone() end
	elseif event == "READY_CHECK_FINISHED" and ChallengesKeystoneFrame and addon.MythicPlus.Buttons["ReadyCheck"] then
		addon.MythicPlus.Buttons["ReadyCheck"]:SetText(L["Ready Check"])
	elseif event == "SPELL_UPDATE_CHARGES" then
		if shouldShowBRTracker() then
			if not brButton or not brButton.cooldownFrame then createBRFrame() end
			local info = C_Spell.GetSpellCharges(20484)
			setBRInfo(info)
		else
			removeBRFrame()
		end
	elseif event == "UNIT_AURA" then
		if arg1 ~= "player" then return end
		if not addon.db["mythicPlusBloodlustTrackerEnabled"] then return end
		if bloodlustStateInitialized and not shouldRefreshBloodlustFromUpdateInfo(arg2) then return end

		-- Refresh state first so visibility logic can react to newly applied/removed lockout auras.
		refreshBloodlustTracker(false)
		if not shouldShowBloodlustFrame() then
			removeBloodlustFrame()
			return
		end
		if not bloodlustButton or not bloodlustButton.cooldownFrame then createBloodlustFrame() end
		refreshBloodlustTracker(false)
	elseif event == "ENCOUNTER_START" then
		local _, _, diff = GetInstanceInfo()
		if isRaidDifficulty(diff) and shouldShowBRTracker() then
			if not brButton or not brButton.cooldownFrame then createBRFrame() end
			local info = C_Spell.GetSpellCharges(20484)
			setBRInfo(info)
		end
		if addon.db["mythicPlusBloodlustTrackerEnabled"] then
			-- Ready reminder sound should run on encounter start even when the frame is currently hidden.
			refreshBloodlustTracker(true)
			if shouldShowBloodlustFrame() then
				if not bloodlustButton or not bloodlustButton.cooldownFrame then createBloodlustFrame() end
				refreshBloodlustTracker(false)
			else
				removeBloodlustFrame()
			end
		end
	elseif event == "ENCOUNTER_END" then
		-- In raids we hide after encounter; in M+ we keep showing
		if not shouldShowBRTracker() then removeBRFrame() end
		if not shouldShowBloodlustFrame() then removeBloodlustFrame() end
	elseif event == "PLAYER_ENTERING_WORLD" then
		if addon.db["mythicPlusBloodlustTrackerEnabled"] then
			refreshBloodlustTracker(false)
			if shouldShowBloodlustFrame() then
				if not bloodlustButton or not bloodlustButton.cooldownFrame then createBloodlustFrame() end
				refreshBloodlustTracker(false)
			else
				removeBloodlustFrame()
			end
		end
	end
end

function addon.MythicPlus.functions.InitMain()
	if addon.MythicPlus.variables.mainInitialized then return end
	if not addon.db then return end
	addon.MythicPlus.variables.mainInitialized = true

	-- Registriere das Event
	frameLoad:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")
	frameLoad:RegisterEvent("READY_CHECK_FINISHED")
	frameLoad:RegisterEvent("LFG_ROLE_CHECK_SHOW")
	frameLoad:RegisterEvent("SPELL_UPDATE_CHARGES")
	frameLoad:RegisterEvent("ENCOUNTER_END")
	frameLoad:RegisterEvent("ENCOUNTER_START")
	frameLoad:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Setze den Event-Handler
	frameLoad:SetScript("OnEvent", eventHandler)
	syncBloodlustUnitAuraRegistration()

	if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBRFrame then addon.MythicPlus.functions.createBRFrame() end
	if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBloodlustFrame then addon.MythicPlus.functions.createBloodlustFrame() end
	refreshBloodlustTracker(false)
	if bloodlustStateActive and (not bloodlustButton or not bloodlustButton.cooldownFrame) then
		createBloodlustFrame()
		refreshBloodlustTracker(false)
	end
	if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.ScheduleTrackerAnchorReapply then
		addon.MythicPlus.functions.ScheduleTrackerAnchorReapply("InitMain")
	end

	if addon.db["mythicPlusEnableDungeonFilter"] then addon.MythicPlus.functions.addDungeonFilter() end
end
