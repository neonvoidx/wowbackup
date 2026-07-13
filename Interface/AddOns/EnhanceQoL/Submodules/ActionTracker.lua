local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.ActionTracker = addon.ActionTracker or {}
local ActionTracker = addon.ActionTracker

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType

local EDITMODE_ID = "actionTracker"
local MAX_ICONS_LIMIT = 10
local FADE_TICK = 0.05
local TIME_LABEL_FONT_SIZE = 11
local TIME_LABEL_PADDING = 2
local TIME_LABEL_HEIGHT = TIME_LABEL_FONT_SIZE + TIME_LABEL_PADDING
local BORDER_SIZE_MIN = 1
local BORDER_SIZE_MAX = 24
local BORDER_OFFSET_MIN = -20
local BORDER_OFFSET_MAX = 100
local GCD_SPELL_ID = 61304
local GCD_FALLBACK = 1.5
local GCD_MIN = 0.5
local GCD_MAX = 2
local GCD_GAP_THRESHOLD = 1.25
local GCD_GAP_MAX_COUNT = 9
local PREVIEW_INTERVAL = 1.35
local PREVIEW_TEXTURE_FALLBACK = "Interface\\ICONS\\INV_Misc_QuestionMark"
local PREVIEW_SPELL_IDS = {
	133, -- Fireball
	116, -- Frostbolt
	172, -- Corruption
	19434, -- Aimed Shot
	30451, -- Arcane Blast
}

ActionTracker.defaults = ActionTracker.defaults
	or {
		maxIcons = 5,
		iconSize = 48,
		spacing = 0,
		direction = "RIGHT",
		fadeDuration = 0,
		showElapsed = false,
		showGCDGaps = false,
		showInterruptedCasts = false,
		onlyInCombat = false,
		iconShape = "DEFAULT",
		iconZoom = 0,
		borderEnabled = false,
		borderTexture = "DEFAULT",
		borderSize = 1,
		borderOffset = 0,
		borderColor = { r = 1, g = 1, b = 1, a = 1 },
	}

local defaults = ActionTracker.defaults

local DB_ENABLED = "actionTrackerEnabled"
local DB_MAX_ICONS = "actionTrackerMaxIcons"
local DB_ICON_SIZE = "actionTrackerIconSize"
local DB_SPACING = "actionTrackerSpacing"
local DB_DIRECTION = "actionTrackerDirection"
local DB_FADE = "actionTrackerFadeDuration"
local DB_SHOW_ELAPSED = "actionTrackerShowElapsed"
local DB_SHOW_GCD_GAPS = "actionTrackerShowGCDGaps"
local DB_SHOW_INTERRUPTED_CASTS = "actionTrackerShowInterruptedCasts"
local DB_ONLY_IN_COMBAT = "actionTrackerOnlyInCombat"
local DB_ICON_SHAPE = "actionTrackerIconShape"
local DB_ICON_ZOOM = "actionTrackerIconZoom"
local DB_BORDER_ENABLED = "actionTrackerBorderEnabled"
local DB_BORDER_TEXTURE = "actionTrackerBorderTexture"
local DB_BORDER_SIZE = "actionTrackerBorderSize"
local DB_BORDER_OFFSET = "actionTrackerBorderOffset"
local DB_BORDER_COLOR = "actionTrackerBorderColor"

local VALID_DIRECTIONS = {
	RIGHT = true,
	LEFT = true,
	UP = true,
	DOWN = true,
}

ActionTracker.entries = ActionTracker.entries or {}
ActionTracker.runtime = ActionTracker.runtime or {}

local function getCachedMediaHash(mediaType)
	if addon.functions and addon.functions.GetLSMMediaHash then
		local hash = addon.functions.GetLSMMediaHash(mediaType)
		if type(hash) == "table" then return hash end
	end
	return {}
end

local function getValue(key, fallback)
	if not addon.db then return fallback end
	local value = addon.db[key]
	if value == nil then return fallback end
	return value
end

local function normalizeDirection(direction)
	if VALID_DIRECTIONS[direction] then return direction end
	return defaults.direction
end

local function clampNumber(value, minimum, maximum, fallback)
	local number = tonumber(value)
	if number == nil then number = fallback end
	if number == nil then number = minimum end
	number = math.floor(number + 0.5)
	if number < minimum then number = minimum end
	if number > maximum then number = maximum end
	return number
end

local function normalizeColor(value, fallback)
	local default = type(fallback) == "table" and fallback or { r = 1, g = 1, b = 1, a = 1 }
	local r = tonumber(value and (value.r or value[1])) or tonumber(default.r or default[1]) or 1
	local g = tonumber(value and (value.g or value[2])) or tonumber(default.g or default[2]) or 1
	local b = tonumber(value and (value.b or value[3])) or tonumber(default.b or default[3]) or 1
	local a = tonumber(value and (value.a or value[4])) or tonumber(default.a or default[4]) or 1
	if r < 0 then
		r = 0
	elseif r > 1 then
		r = 1
	end
	if g < 0 then
		g = 0
	elseif g > 1 then
		g = 1
	end
	if b < 0 then
		b = 0
	elseif b > 1 then
		b = 1
	end
	if a < 0 then
		a = 0
	elseif a > 1 then
		a = 1
	end
	return r, g, b, a
end

local function isLikelyFilePath(value) return type(value) == "string" and (value:find("\\", 1, true) or value:find("/", 1, true)) ~= nil end

local function normalizeIconShape(value, fallback)
	if addon.IconShape and addon.IconShape.Normalize then return addon.IconShape.Normalize(value, fallback or defaults.iconShape or "DEFAULT") end
	if type(value) == "string" and value ~= "" then return value end
	return fallback or defaults.iconShape or "DEFAULT"
end

local function isBackdropBorderCompatible(shape)
	if addon.IconShape and addon.IconShape.IsBackdropBorderCompatible then return addon.IconShape.IsBackdropBorderCompatible(shape) end
	shape = normalizeIconShape(shape, "DEFAULT")
	return shape == "DEFAULT" or shape == "SQUARE"
end

local function normalizeBorderTexture(value, fallback, shape)
	if addon.IconShape and addon.IconShape.NormalizeBorder then return addon.IconShape.NormalizeBorder(value, fallback or defaults.borderTexture or "DEFAULT", shape or normalizeIconShape(nil), { allowNone = true }) end
	if type(value) ~= "string" or value == "" then return fallback or defaults.borderTexture or "DEFAULT" end
	return value
end

local function resolveBorderTexture(value)
	local key = normalizeBorderTexture(value, defaults.borderTexture, "DEFAULT")
	if key == "DEFAULT" or key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if isLikelyFilePath(key) then return key end
	local hash = getCachedMediaHash("border")
	local texture = hash and hash[key]
	if type(texture) == "string" and texture ~= "" then return texture end
	return "Interface\\Buttons\\WHITE8x8"
end

local function getBorderOptions(shape)
	if addon.IconShape and addon.IconShape.GetBorderOptions then
		return addon.IconShape.GetBorderOptions(L, shape, {
			defaultOptions = {
				{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
				{ value = "SOLID", label = "Solid" },
			},
			includeNone = true,
			noneLabel = _G.NONE or "None",
		})
	end

	local options = {}
	local seen = {}

	local function addOption(value, label)
		if type(value) ~= "string" or value == "" or seen[value] then return end
		seen[value] = true
		options[#options + 1] = {
			value = value,
			label = label or value,
		}
	end

	addOption("DEFAULT", _G.DEFAULT or "Default")
	addOption("SOLID", "Solid")

	local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("border") or nil
	if type(mediaOptions) == "table" then
		for i = 1, #mediaOptions do
			local option = mediaOptions[i]
			if type(option) == "table" then addOption(option.value, option.label or option.value) end
		end
		return options
	end

	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or {}
	for i = 1, #names do
		local name = names[i]
		addOption(name, name)
	end

	return options
end

local function refreshEditModeSettingValues()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then addon.EditModeLib.internal:RefreshSettingValues() end
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

local function getPreviewTexture(index)
	local spellID = PREVIEW_SPELL_IDS[((index - 1) % #PREVIEW_SPELL_IDS) + 1]
	if C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellID)
		if texture then return texture end
	end
	return PREVIEW_TEXTURE_FALLBACK
end

function ActionTracker:GetIconSize()
	local size = tonumber(getValue(DB_ICON_SIZE, defaults.iconSize)) or defaults.iconSize
	if size < 16 then size = 16 end
	return size
end

function ActionTracker:GetMaxIcons()
	local maxIcons = tonumber(getValue(DB_MAX_ICONS, defaults.maxIcons)) or defaults.maxIcons
	maxIcons = math.floor(maxIcons + 0.5)
	if maxIcons < 1 then maxIcons = 1 end
	if maxIcons > MAX_ICONS_LIMIT then maxIcons = MAX_ICONS_LIMIT end
	return maxIcons
end

function ActionTracker:GetSpacing()
	local spacing = tonumber(getValue(DB_SPACING, defaults.spacing)) or defaults.spacing
	if spacing < 0 then spacing = 0 end
	return spacing
end

function ActionTracker:GetDirection() return normalizeDirection(getValue(DB_DIRECTION, defaults.direction)) end

function ActionTracker:GetFadeDuration()
	local fade = tonumber(getValue(DB_FADE, defaults.fadeDuration)) or defaults.fadeDuration
	if fade < 0 then fade = 0 end
	return fade
end

function ActionTracker:GetShowElapsed() return getValue(DB_SHOW_ELAPSED, defaults.showElapsed) == true end
function ActionTracker:GetShowGCDGaps() return getValue(DB_SHOW_GCD_GAPS, defaults.showGCDGaps) == true end
function ActionTracker:GetShowInterruptedCasts() return getValue(DB_SHOW_INTERRUPTED_CASTS, defaults.showInterruptedCasts) == true end
function ActionTracker:GetOnlyInCombat() return getValue(DB_ONLY_IN_COMBAT, defaults.onlyInCombat) == true end
function ActionTracker:IsTrackingActive() return not self:GetOnlyInCombat() or (InCombatLockdown and InCombatLockdown() == true) end
function ActionTracker:GetIconShape() return normalizeIconShape(getValue(DB_ICON_SHAPE, defaults.iconShape), defaults.iconShape or "DEFAULT") end
function ActionTracker:GetIconZoom()
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then return addon.IconShape.NormalizeIconZoom(getValue(DB_ICON_ZOOM, defaults.iconZoom)) end
	return clampNumber(getValue(DB_ICON_ZOOM, defaults.iconZoom), 0, 35, defaults.iconZoom or 0)
end
function ActionTracker:GetBorderEnabled() return getValue(DB_BORDER_ENABLED, defaults.borderEnabled) == true end
function ActionTracker:GetBorderTextureKey()
	local shape = self:GetIconShape()
	return normalizeBorderTexture(getValue(DB_BORDER_TEXTURE, defaults.borderTexture), defaults.borderTexture or "DEFAULT", shape)
end
function ActionTracker:GetBorderSize() return clampNumber(getValue(DB_BORDER_SIZE, defaults.borderSize), BORDER_SIZE_MIN, BORDER_SIZE_MAX, defaults.borderSize) end
function ActionTracker:GetBorderOffset() return clampNumber(getValue(DB_BORDER_OFFSET, defaults.borderOffset), BORDER_OFFSET_MIN, BORDER_OFFSET_MAX, defaults.borderOffset) end

function ActionTracker:GetBorderColor()
	local r, g, b, a = normalizeColor(getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor)
	return r, g, b, a
end

function ActionTracker:GetEntryAlpha(entry, now, fade)
	local duration = fade
	if duration == nil then duration = self:GetFadeDuration() end
	if duration <= 0 then return 1 end
	local age = (now or GetTime()) - (entry.time or 0)
	if age >= duration then return 0 end
	return 1 - (age / duration)
end

local function formatElapsed(elapsed)
	if elapsed < 0 then elapsed = 0 end
	if elapsed < 10 then
		return string.format("%.2fs", elapsed)
	elseif elapsed < 100 then
		return string.format("%.1fs", elapsed)
	end
	local minutes = math.floor(elapsed / 60)
	local seconds = math.floor(elapsed % 60)
	return string.format("%dm%02ds", minutes, seconds)
end

local function getCurrentGCDDuration()
	if C_Spell and C_Spell.GetSpellCooldown then
		local info = C_Spell.GetSpellCooldown(GCD_SPELL_ID)
		local duration = tonumber(info and info.duration)
		if duration and duration >= GCD_MIN and duration <= GCD_MAX then return duration end
	end
	return GCD_FALLBACK
end

local function getEntryTexture(entry)
	if not entry then return nil end
	if entry.kind == "gap" then return "Interface\\Buttons\\WHITE8x8" end
	if entry.texture then return entry.texture end
	if entry.spellID and C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(entry.spellID) end
	return nil
end

local function getEntryLabel(entry)
	if not entry then return nil end
	if entry.kind == "gap" then return string.format("+%d\nGCD", entry.gcdCount or 1) end
	if entry.kind == "interrupted" then return entry.wasKicked and "KICK" or "X" end
	return nil
end

local function setTextureVertexColor(texture, r, g, b, a)
	if texture and texture.SetVertexColor then texture:SetVertexColor(r, g, b, a) end
end

function ActionTracker:TrimEntries()
	local maxIcons = self:GetMaxIcons()
	while #self.entries > maxIcons do
		table.remove(self.entries, 1)
	end
end

local function applyIconSize(icon, size)
	icon:SetSize(size, size)
	if icon.texture then icon.texture:SetAllPoints(icon) end
	if icon.cooldown then icon.cooldown:SetAllPoints(icon) end
	if icon.markerText and icon.markerText.SetFont then
		local font, _, flags = icon.markerText:GetFont()
		if font then icon.markerText:SetFont(font, math.max(10, math.floor(size * 0.34)), flags) end
	end
	if icon.timeText and icon.timeText.SetWidth then icon.timeText:SetWidth(size + 8) end
end

local function applyIconShape(icon, shape)
	if not (addon.IconShape and addon.IconShape.ApplyFrameShape) then return end
	addon.IconShape.ApplyFrameShape(icon, shape, {
		textures = { icon.texture },
		cooldown = icon.cooldown,
		maskKey = "_eqolActionTrackerMask",
		textureMaskKey = "_eqolActionTrackerTextureMask",
		textureTexCoordKey = "_eqolActionTrackerTexCoord",
		iconZoom = ActionTracker:GetIconZoom(),
	})
end

local function ensureIconBorder(icon)
	if icon.border then return icon.border end

	local border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
	border:SetFrameStrata(icon:GetFrameStrata())
	border:SetFrameLevel((icon:GetFrameLevel() or 0) + 4)
	border:SetBackdropColor(0, 0, 0, 0)
	border:Hide()

	icon.border = border
	return border
end

function ActionTracker:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "EQOL_ActionTrackerFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(false)
	frame.icons = {}

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0.1, 0.6, 0.6, 0.2)
	bg:Hide()
	frame.bg = bg

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER")
	label:SetText(L["ActionTracker"] or "Action Tracker")
	label:Hide()
	frame.label = label

	for i = 1, MAX_ICONS_LIMIT do
		local icon = CreateFrame("Frame", nil, frame)
		icon:SetAlpha(0)
		icon:Hide()

		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints(icon)

		icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
		icon.cooldown:SetAllPoints(icon)

		icon.markerText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		icon.markerText:SetPoint("CENTER")
		icon.markerText:SetJustifyH("CENTER")
		icon.markerText:SetJustifyV("MIDDLE")
		icon.markerText:SetText("")
		icon.markerText:Hide()

		icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		icon.timeText:SetPoint("TOP", icon, "BOTTOM", 0, -TIME_LABEL_PADDING)
		icon.timeText:SetJustifyH("CENTER")
		icon.timeText:SetText("")
		if icon.timeText.SetFont then
			local font, _, flags = icon.timeText:GetFont()
			if font then icon.timeText:SetFont(font, TIME_LABEL_FONT_SIZE, flags) end
		end
		icon.timeText:Hide()

		icon:SetScript("OnEnter", function(selfIcon)
			local entry = selfIcon.entry
			if entry and entry.kind == "gap" then
				GameTooltip:SetOwner(selfIcon, "ANCHOR_RIGHT")
				GameTooltip:SetText(L["actionTrackerGCDGap"] or "GCD gap")
				GameTooltip:AddLine((L["actionTrackerGCDGapTooltip"] or "No tracked action for about %d GCDs (%s)."):format(entry.gcdCount or 1, formatElapsed(entry.elapsed or 0)), 1, 1, 1, true)
				GameTooltip:Show()
				return
			end

			if not selfIcon.spellID then return end
			GameTooltip:SetOwner(selfIcon, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(selfIcon.spellID)
			if entry and entry.kind == "interrupted" then
				if entry.wasKicked then
					GameTooltip:AddLine(L["actionTrackerKicked"] or "Kicked", 1, 0.2, 0.2, true)
				else
					GameTooltip:AddLine(L["actionTrackerInterrupted"] or "Interrupted", 1, 0.2, 0.2, true)
				end
			end
			GameTooltip:Show()
		end)
		icon:SetScript("OnLeave", GameTooltip_Hide)

		frame.icons[i] = icon
	end

	self.frame = frame
	self:UpdateLayout()
	self:RefreshIcons()

	return frame
end

function ActionTracker:ShowEditModeHint(show)
	if not self.frame then return end
	self.previewActive = show == true and #self.entries == 0
	if show then
		self.frame.bg:Show()
		self.frame.label:Show()
	else
		self.frame.bg:Hide()
		self.frame.label:Hide()
	end
	self:RefreshIcons()
end

function ActionTracker:UpdateBorderVisuals()
	local frame = self.frame
	if not frame or not frame.icons then return end

	local borderEnabled = self:GetBorderEnabled()
	local borderTexture = self:GetBorderTextureKey()
	local borderSize = self:GetBorderSize()
	local borderOffset = self:GetBorderOffset()
	local r, g, b, a = self:GetBorderColor()
	local shape = self:GetIconShape()
	local backdropBorder = isBackdropBorderCompatible(shape)

	for i = 1, MAX_ICONS_LIMIT do
		local icon = frame.icons[i]
		local border = ensureIconBorder(icon)
		local noBorder = addon.IconShape and addon.IconShape.IsNoBorder and addon.IconShape.IsNoBorder(borderTexture)
		if borderEnabled and not noBorder and icon:IsShown() then
			if addon.IconShape and addon.IconShape.HideBorderTextures then addon.IconShape.HideBorderTextures(icon) end
			if backdropBorder then
				border:SetBackdrop({
					edgeFile = resolveBorderTexture(borderTexture),
					edgeSize = borderSize,
					insets = { left = 0, right = 0, top = 0, bottom = 0 },
				})
				border:SetBackdropBorderColor(r, g, b, a)
				border:SetBackdropColor(0, 0, 0, 0)
				border:ClearAllPoints()
				border:SetPoint("TOPLEFT", icon, "TOPLEFT", -borderOffset, borderOffset)
				border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", borderOffset, -borderOffset)
				border:Show()
			else
				border:SetBackdrop(nil)
				border:Hide()
				if addon.IconShape and addon.IconShape.ApplyBorder then
					addon.IconShape.ApplyBorder(icon, borderTexture, shape, {
						borderSize = borderSize,
						borderOffset = borderOffset,
						color = { r, g, b, a },
					})
				end
			end
		else
			border:SetBackdrop(nil)
			border:Hide()
			if addon.IconShape and addon.IconShape.HideBorderTextures then addon.IconShape.HideBorderTextures(icon) end
		end
	end
end

function ActionTracker:UpdateLayout()
	local frame = self.frame
	if not frame then return end

	local iconSize = self:GetIconSize()
	local maxIcons = self:GetMaxIcons()
	local spacing = self:GetSpacing()
	local direction = self:GetDirection()
	local showElapsed = self:GetShowElapsed()
	local labelExtra = showElapsed and TIME_LABEL_HEIGHT or 0
	local iconShape = self:GetIconShape()

	if direction == "LEFT" or direction == "RIGHT" then
		local total = (iconSize * maxIcons) + (spacing * (maxIcons - 1))
		frame:SetSize(total, iconSize + labelExtra)
	else
		local step = iconSize + spacing + labelExtra
		local total = (step * maxIcons) - spacing
		frame:SetSize(iconSize, total)
	end

	for i = 1, MAX_ICONS_LIMIT do
		local icon = frame.icons[i]
		local step = iconSize + spacing
		if (direction == "UP" or direction == "DOWN") and showElapsed then step = iconSize + spacing + labelExtra end
		local baseOffset = (showElapsed and direction == "UP") and labelExtra or 0
		local offset = baseOffset + ((i - 1) * step)
		local yOffset = (showElapsed and (direction == "LEFT" or direction == "RIGHT")) and (labelExtra / 2) or 0

		applyIconSize(icon, iconSize)
		icon._eqolVisualSize = iconSize
		icon._eqolBaseSlotSize = iconSize
		applyIconShape(icon, iconShape)
		icon:ClearAllPoints()
		if direction == "RIGHT" then
			icon:SetPoint("LEFT", frame, "LEFT", offset, yOffset)
		elseif direction == "LEFT" then
			icon:SetPoint("RIGHT", frame, "RIGHT", -offset, yOffset)
		elseif direction == "DOWN" then
			icon:SetPoint("TOP", frame, "TOP", 0, -offset)
		else
			icon:SetPoint("BOTTOM", frame, "BOTTOM", 0, offset)
		end
	end

	self:UpdateBorderVisuals()
end

function ActionTracker:RefreshIcons()
	local frame = self.frame
	if not frame then return end

	local entries = self.entries
	local maxIcons = self:GetMaxIcons()
	local now = GetTime()
	local fade = self:GetFadeDuration()
	local showElapsed = self:GetShowElapsed()
	local previewActive = self.previewActive == true and #entries == 0
	local iconShape = self:GetIconShape()

	self:TrimEntries()

	for i = 1, MAX_ICONS_LIMIT do
		local icon = frame.icons[i]
		applyIconShape(icon, iconShape)
		local entry = i <= maxIcons and entries[i] or nil
		if entry then
			local texture = getEntryTexture(entry)
			icon.texture:SetTexture(texture)
			if entry.kind == "gap" then
				setTextureVertexColor(icon.texture, 0.18, 0.18, 0.18, 0.85)
			elseif entry.kind == "interrupted" then
				setTextureVertexColor(icon.texture, 0.45, 0.45, 0.45, 1)
			else
				setTextureVertexColor(icon.texture, 1, 1, 1, 1)
			end
			icon.spellID = entry.spellID
			icon.entry = entry

			local markerText = getEntryLabel(entry)
			if markerText and icon.markerText then
				icon.markerText:SetText(markerText)
				if entry.kind == "gap" then
					icon.markerText:SetTextColor(1, 0.15, 0.15, 1)
				elseif entry.kind == "interrupted" then
					if entry.wasKicked then
						icon.markerText:SetTextColor(1, 0.1, 0.1, 1)
					else
						icon.markerText:SetTextColor(1, 0.75, 0.15, 1)
					end
				end
				icon.markerText:Show()
			elseif icon.markerText then
				icon.markerText:SetText("")
				icon.markerText:Hide()
			end

			if entry.kind == "spell" and entry.cooldownDuration then
				icon.cooldown:SetCooldownFromDurationObject(entry.cooldownDuration)
				icon.cooldown:SetDrawEdge(false)
				icon.cooldown:SetDrawBling(false)
				icon.cooldown:SetDrawSwipe(false)
			else
				icon.cooldown:Clear()
			end

			icon:SetAlpha(self:GetEntryAlpha(entry, now, fade))
			if icon.timeText then
				local previousEntry = entries[i - 1]
				if showElapsed and entry.kind == "gap" then
					icon.timeText:SetText(formatElapsed(entry.elapsed or 0))
					icon.timeText:Show()
				elseif showElapsed and i > 1 and previousEntry and not (entry.kind == "spell" and previousEntry.kind == "gap") then
					local delta = (entry.time or now) - (previousEntry.time or now)
					icon.timeText:SetText(formatElapsed(delta))
					icon.timeText:Show()
				else
					icon.timeText:SetText("")
					icon.timeText:Hide()
				end
			end
			icon:Show()
		elseif previewActive and i <= maxIcons then
			icon.spellID = nil
			icon.entry = nil
			icon.texture:SetTexture(getPreviewTexture(i))
			setTextureVertexColor(icon.texture, 1, 1, 1, 1)
			icon.cooldown:Clear()
			icon:SetAlpha(1)
			if icon.markerText then
				icon.markerText:SetText("")
				icon.markerText:Hide()
			end
			if icon.timeText then
				if showElapsed and i > 1 then
					icon.timeText:SetText(formatElapsed(PREVIEW_INTERVAL))
					icon.timeText:Show()
				else
					icon.timeText:SetText("")
					icon.timeText:Hide()
				end
			end
			icon:Show()
		else
			icon.spellID = nil
			icon.entry = nil
			icon.texture:SetTexture(nil)
			setTextureVertexColor(icon.texture, 1, 1, 1, 1)
			icon.cooldown:Clear()
			icon:SetAlpha(0)
			if icon.markerText then
				icon.markerText:SetText("")
				icon.markerText:Hide()
			end
			if icon.timeText then
				icon.timeText:SetText("")
				icon.timeText:Hide()
			end
			icon:Hide()
		end
	end

	self:UpdateBorderVisuals()
end

function ActionTracker:OnMediaRegistered(mediaType, mediaKey)
	if mediaType ~= "border" or type(mediaKey) ~= "string" or mediaKey == "" then return end
	if not (addon and addon.db and addon.db[DB_ENABLED] == true) then return end
	if not self.frame then return end
	if self:GetBorderTextureKey() ~= mediaKey then return end

	self:RefreshIcons()
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

function ActionTracker:StartFadeUpdate()
	if self.fadeTicker or not self.frame then return end
	local tracker = self
	self.fadeTicker = C_Timer.NewTicker(FADE_TICK, function() tracker:UpdateFade() end)
end

function ActionTracker:StopFadeUpdate()
	if self.fadeTicker then
		self.fadeTicker:Cancel()
		self.fadeTicker = nil
	end
end

function ActionTracker:UpdateFade()
	local fade = self:GetFadeDuration()
	if fade <= 0 then
		self:StopFadeUpdate()
		return
	end

	local now = GetTime()
	local removed
	for i = #self.entries, 1, -1 do
		if (now - (self.entries[i].time or 0)) >= fade then
			table.remove(self.entries, i)
			removed = true
		end
	end

	if removed then
		self:RefreshIcons()
	else
		for i, entry in ipairs(self.entries) do
			local icon = self.frame and self.frame.icons and self.frame.icons[i]
			if icon then icon:SetAlpha(self:GetEntryAlpha(entry, now, fade)) end
		end
	end

	if #self.entries == 0 then self:StopFadeUpdate() end
end

function ActionTracker:UpdateFadeState(skipRefresh)
	local fade = self:GetFadeDuration()
	self:TrimEntries()
	local hasEntries = #self.entries > 0

	if fade <= 0 or not hasEntries then
		self:StopFadeUpdate()
		if not skipRefresh then self:RefreshIcons() end
	else
		self:StartFadeUpdate()
		if not skipRefresh then self:RefreshIcons() end
	end
end

function ActionTracker:ClearEntries()
	wipe(self.entries)
	wipe(self.runtime)
	self:StopFadeUpdate()
	self:RefreshIcons()
end

function ActionTracker:AppendEntry(entry)
	if type(entry) ~= "table" then return end
	self.entries[#self.entries + 1] = entry
	local maxIcons = self:GetMaxIcons()
	while #self.entries > maxIcons do
		table.remove(self.entries, 1)
	end
end

function ActionTracker:AddGCDGapIfNeeded(now)
	if not self:GetShowGCDGaps() then return end

	local lastTime = self.runtime.lastTrackedActionTime
	if not lastTime then return end

	local gcd = tonumber(self.runtime.lastGCDDuration) or GCD_FALLBACK
	if gcd < GCD_MIN or gcd > GCD_MAX then gcd = GCD_FALLBACK end

	local elapsed = (now or GetTime()) - lastTime
	if elapsed <= (gcd * GCD_GAP_THRESHOLD) then return end

	local missed = math.floor(elapsed / gcd) - 1
	if missed < 1 then missed = 1 end
	if missed > GCD_GAP_MAX_COUNT then missed = GCD_GAP_MAX_COUNT end

	self:AppendEntry({
		kind = "gap",
		time = now,
		gcdCount = missed,
		elapsed = elapsed,
	})
end

function ActionTracker:UpdateTimelineAnchor(now)
	self.runtime.lastTrackedActionTime = now or GetTime()
	self.runtime.lastGCDDuration = getCurrentGCDDuration()
end

function ActionTracker:AddEntry(spellID)
	if not self:IsTrackingActive() then return end
	if not spellID then return end

	local ignoreList = self.ignoreList
	if ignoreList and ignoreList[spellID] then return end

	local texture = C_Spell.GetSpellTexture(spellID)
	if not texture then return end

	local now = GetTime()
	self:AddGCDGapIfNeeded(now)

	local entry = {
		kind = "spell",
		spellID = spellID,
		texture = texture,
		time = now,
	}

	local duration = C_Spell.GetSpellCooldownDuration(spellID)
	entry.cooldownDuration = duration

	self:AppendEntry(entry)
	self:UpdateTimelineAnchor(now)

	self:RefreshIcons()
	self:UpdateFadeState(true)
end

function ActionTracker:AddInterruptedCast(spellID, castGUID, interruptedBy)
	if not self:IsTrackingActive() then return end
	if not self:GetShowInterruptedCasts() then return end

	local ignoreList = self.ignoreList
	if spellID and ignoreList and ignoreList[spellID] then return end

	if castGUID then
		self.runtime.interruptedCastGUIDs = self.runtime.interruptedCastGUIDs or {}
		if self.runtime.interruptedCastGUIDs[castGUID] then return end
		self.runtime.interruptedCastGUIDs[castGUID] = true
	end

	local texture = spellID and C_Spell.GetSpellTexture(spellID) or nil
	if not texture then texture = PREVIEW_TEXTURE_FALLBACK end

	local now = GetTime()

	self:AppendEntry({
		kind = "interrupted",
		spellID = spellID,
		texture = texture,
		time = now,
		wasKicked = interruptedBy ~= nil,
	})

	self:RefreshIcons()
	self:UpdateFadeState(true)
end

function ActionTracker:OnEvent(event, unit, arg2, arg3, arg4)
	if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		self:ClearEntries()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local spellID = arg3
		self:AddEntry(spellID)
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		self:AddInterruptedCast(arg3, arg2, arg4)
	end
end

function ActionTracker:UpdateOptionalEventRegistration()
	if not self.eventsRegistered or not self.frame then return end

	if self:GetShowInterruptedCasts() then
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
	else
		self.frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	end

	if self:GetOnlyInCombat() then
		self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function ActionTracker:RegisterEvents()
	if self.eventsRegistered then return end
	local frame = self:EnsureFrame()
	frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	frame:SetScript("OnEvent", function(_, event, ...) ActionTracker:OnEvent(event, ...) end)
	self.eventsRegistered = true
	self:UpdateOptionalEventRegistration()
end

function ActionTracker:UnregisterEvents()
	if not self.eventsRegistered or not self.frame then return end
	self.frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self.frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.frame:SetScript("OnEvent", nil)
	self.eventsRegistered = false
end

local editModeRegistered = false

function ActionTracker:ApplyLayoutData(data)
	if not data or not addon.db then return end

	local size = tonumber(data.size) or defaults.iconSize
	if size < 16 then size = 16 end

	local maxIcons = tonumber(data.maxIcons) or self:GetMaxIcons()
	maxIcons = math.floor(maxIcons + 0.5)
	if maxIcons < 1 then maxIcons = 1 end
	if maxIcons > MAX_ICONS_LIMIT then maxIcons = MAX_ICONS_LIMIT end

	local spacing = tonumber(data.spacing) or defaults.spacing
	if spacing < 0 then spacing = 0 end

	local direction = normalizeDirection(data.direction)
	local fade = tonumber(data.fade) or defaults.fadeDuration
	if fade < 0 then fade = 0 end
	local showElapsed = data.showElapsed == true
	local showGCDGaps = data.showGCDGaps
	if showGCDGaps == nil then showGCDGaps = self:GetShowGCDGaps() end
	showGCDGaps = showGCDGaps == true
	local showInterruptedCasts = data.showInterruptedCasts
	if showInterruptedCasts == nil then showInterruptedCasts = self:GetShowInterruptedCasts() end
	showInterruptedCasts = showInterruptedCasts == true
	local onlyInCombat = data.onlyInCombat
	if onlyInCombat == nil then onlyInCombat = self:GetOnlyInCombat() end
	onlyInCombat = onlyInCombat == true
	local iconShape = normalizeIconShape(data.iconShape or self:GetIconShape(), defaults.iconShape or "DEFAULT")
	local iconZoom = addon.IconShape and addon.IconShape.NormalizeIconZoom and addon.IconShape.NormalizeIconZoom(data.iconZoom or self:GetIconZoom()) or clampNumber(data.iconZoom or self:GetIconZoom(), 0, 35, defaults.iconZoom or 0)
	local borderEnabled = data.borderEnabled
	if borderEnabled == nil then borderEnabled = self:GetBorderEnabled() end
	borderEnabled = borderEnabled == true
	local borderTexture = normalizeBorderTexture(data.borderTexture or self:GetBorderTextureKey(), defaults.borderTexture or "DEFAULT", iconShape)
	local borderSize = clampNumber(data.borderSize ~= nil and data.borderSize or self:GetBorderSize(), BORDER_SIZE_MIN, BORDER_SIZE_MAX, defaults.borderSize)
	local borderOffset = clampNumber(data.borderOffset ~= nil and data.borderOffset or self:GetBorderOffset(), BORDER_OFFSET_MIN, BORDER_OFFSET_MAX, defaults.borderOffset)
	local borderR, borderG, borderB, borderA = normalizeColor(data.borderColor or getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor)

	addon.db[DB_MAX_ICONS] = maxIcons
	addon.db[DB_ICON_SIZE] = size
	addon.db[DB_SPACING] = spacing
	addon.db[DB_DIRECTION] = direction
	addon.db[DB_FADE] = fade
	addon.db[DB_SHOW_ELAPSED] = showElapsed
	addon.db[DB_SHOW_GCD_GAPS] = showGCDGaps
	addon.db[DB_SHOW_INTERRUPTED_CASTS] = showInterruptedCasts
	addon.db[DB_ONLY_IN_COMBAT] = onlyInCombat
	addon.db[DB_ICON_SHAPE] = iconShape
	addon.db[DB_ICON_ZOOM] = iconZoom
	addon.db[DB_BORDER_ENABLED] = borderEnabled
	addon.db[DB_BORDER_TEXTURE] = borderTexture
	addon.db[DB_BORDER_SIZE] = borderSize
	addon.db[DB_BORDER_OFFSET] = borderOffset
	addon.db[DB_BORDER_COLOR] = { r = borderR, g = borderG, b = borderB, a = borderA }

	self:TrimEntries()
	self:UpdateLayout()
	self:RefreshIcons()
	self:UpdateFadeState(true)
	self:UpdateOptionalEventRegistration()
	if self:GetOnlyInCombat() and not self:IsTrackingActive() then self:ClearEntries() end
end

local function applySetting(field, value)
	if not addon.db then return end
	local refreshSettings = false

	if field == "maxIcons" then
		local maxIcons = tonumber(value) or defaults.maxIcons
		maxIcons = math.floor(maxIcons + 0.5)
		if maxIcons < 1 then maxIcons = 1 end
		if maxIcons > MAX_ICONS_LIMIT then maxIcons = MAX_ICONS_LIMIT end
		addon.db[DB_MAX_ICONS] = maxIcons
		value = maxIcons
	elseif field == "size" then
		local size = tonumber(value) or defaults.iconSize
		if size < 16 then size = 16 end
		addon.db[DB_ICON_SIZE] = size
		value = size
	elseif field == "spacing" then
		local spacing = tonumber(value) or defaults.spacing
		if spacing < 0 then spacing = 0 end
		addon.db[DB_SPACING] = spacing
		value = spacing
	elseif field == "direction" then
		local direction = normalizeDirection(value)
		addon.db[DB_DIRECTION] = direction
		value = direction
	elseif field == "fade" then
		local fade = tonumber(value) or defaults.fadeDuration
		if fade < 0 then fade = 0 end
		addon.db[DB_FADE] = fade
		value = fade
	elseif field == "showElapsed" then
		local showElapsed = value == true
		addon.db[DB_SHOW_ELAPSED] = showElapsed
		value = showElapsed
	elseif field == "showGCDGaps" then
		local showGCDGaps = value == true
		addon.db[DB_SHOW_GCD_GAPS] = showGCDGaps
		value = showGCDGaps
	elseif field == "showInterruptedCasts" then
		local showInterruptedCasts = value == true
		addon.db[DB_SHOW_INTERRUPTED_CASTS] = showInterruptedCasts
		value = showInterruptedCasts
		ActionTracker:UpdateOptionalEventRegistration()
	elseif field == "onlyInCombat" then
		local onlyInCombat = value == true
		addon.db[DB_ONLY_IN_COMBAT] = onlyInCombat
		value = onlyInCombat
		ActionTracker:UpdateOptionalEventRegistration()
		if onlyInCombat and not ActionTracker:IsTrackingActive() then ActionTracker:ClearEntries() end
	elseif field == "iconShape" then
		local iconShape = normalizeIconShape(value, defaults.iconShape or "DEFAULT")
		addon.db[DB_ICON_SHAPE] = iconShape
		addon.db[DB_BORDER_TEXTURE] = normalizeBorderTexture(addon.db[DB_BORDER_TEXTURE], defaults.borderTexture or "DEFAULT", iconShape)
		value = iconShape
		refreshSettings = true
	elseif field == "iconZoom" then
		local iconZoom = addon.IconShape and addon.IconShape.NormalizeIconZoom and addon.IconShape.NormalizeIconZoom(value) or clampNumber(value, 0, 35, defaults.iconZoom or 0)
		addon.db[DB_ICON_ZOOM] = iconZoom
		value = iconZoom
	elseif field == "borderEnabled" then
		local borderEnabled = value == true
		addon.db[DB_BORDER_ENABLED] = borderEnabled
		value = borderEnabled
	elseif field == "borderTexture" then
		local borderTexture = normalizeBorderTexture(value, defaults.borderTexture or "DEFAULT", ActionTracker:GetIconShape())
		addon.db[DB_BORDER_TEXTURE] = borderTexture
		value = borderTexture
		refreshSettings = true
	elseif field == "borderSize" then
		local borderSize = clampNumber(value, BORDER_SIZE_MIN, BORDER_SIZE_MAX, defaults.borderSize)
		addon.db[DB_BORDER_SIZE] = borderSize
		value = borderSize
	elseif field == "borderOffset" then
		local borderOffset = clampNumber(value, BORDER_OFFSET_MIN, BORDER_OFFSET_MAX, defaults.borderOffset)
		addon.db[DB_BORDER_OFFSET] = borderOffset
		value = borderOffset
	elseif field == "borderColor" then
		local r, g, b, a = normalizeColor(value, defaults.borderColor)
		value = { r = r, g = g, b = b, a = a }
		addon.db[DB_BORDER_COLOR] = value
	end

	if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, field, value, nil, true) end
	ActionTracker:TrimEntries()
	ActionTracker:UpdateLayout()
	ActionTracker:RefreshIcons()
	ActionTracker:UpdateFadeState(true)
	if refreshSettings then refreshEditModeSettingValues() end
end

function ActionTracker:RegisterEditMode()
	if editModeRegistered or not EditMode or not EditMode.RegisterFrame then return end

	local directionOptions = {
		{ value = "RIGHT", label = L["Right"] or "Right" },
		{ value = "LEFT", label = L["Left"] or "Left" },
		{ value = "UP", label = L["Up"] or "Up" },
		{ value = "DOWN", label = L["Down"] or "Down" },
	}

	local settings
	if SettingType then
		settings = {
			{
				name = L["actionTrackerMaxIcons"] or "Max icons",
				kind = SettingType.Slider,
				field = "maxIcons",
				default = defaults.maxIcons,
				minValue = 1,
				maxValue = MAX_ICONS_LIMIT,
				valueStep = 1,
				get = function() return ActionTracker:GetMaxIcons() end,
				set = function(_, value) applySetting("maxIcons", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["Icon size"] or "Icon size",
				kind = SettingType.Slider,
				field = "size",
				default = defaults.iconSize,
				minValue = 16,
				maxValue = 128,
				valueStep = 1,
				get = function() return ActionTracker:GetIconSize() end,
				set = function(_, value) applySetting("size", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["Icon spacing"] or "Icon spacing",
				kind = SettingType.Slider,
				field = "spacing",
				default = defaults.spacing,
				minValue = 0,
				maxValue = 50,
				valueStep = 1,
				get = function() return ActionTracker:GetSpacing() end,
				set = function(_, value) applySetting("spacing", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["Icon direction"] or "Icon direction",
				kind = SettingType.Dropdown,
				field = "direction",
				height = 120,
				get = function() return ActionTracker:GetDirection() end,
				set = function(_, value) applySetting("direction", value) end,
				generator = function(_, root)
					for _, option in ipairs(directionOptions) do
						root:CreateRadio(option.label, function() return ActionTracker:GetDirection() == option.value end, function() applySetting("direction", option.value) end)
					end
				end,
			},
			{
				name = L["actionTrackerFadeDuration"] or "Fade duration",
				kind = SettingType.Slider,
				field = "fade",
				default = defaults.fadeDuration,
				minValue = 0,
				maxValue = 10,
				valueStep = 1,
				get = function() return ActionTracker:GetFadeDuration() end,
				set = function(_, value) applySetting("fade", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["actionTrackerShowElapsed"] or "Show time since last action",
				kind = SettingType.Checkbox,
				field = "showElapsed",
				default = defaults.showElapsed,
				get = function() return ActionTracker:GetShowElapsed() end,
				set = function(_, value) applySetting("showElapsed", value) end,
			},
			{
				name = L["actionTrackerOnlyInCombat"] or "Only track during combat",
				kind = SettingType.Checkbox,
				field = "onlyInCombat",
				default = defaults.onlyInCombat,
				get = function() return ActionTracker:GetOnlyInCombat() end,
				set = function(_, value) applySetting("onlyInCombat", value) end,
			},
			{
				name = L["actionTrackerShowGCDGaps"] or "Show GCD gaps",
				kind = SettingType.Checkbox,
				field = "showGCDGaps",
				default = defaults.showGCDGaps,
				get = function() return ActionTracker:GetShowGCDGaps() end,
				set = function(_, value) applySetting("showGCDGaps", value) end,
			},
			{
				name = L["actionTrackerShowInterruptedCasts"] or "Show interrupted casts",
				kind = SettingType.Checkbox,
				field = "showInterruptedCasts",
				default = defaults.showInterruptedCasts,
				get = function() return ActionTracker:GetShowInterruptedCasts() end,
				set = function(_, value) applySetting("showInterruptedCasts", value) end,
			},
			{
				name = L["settingsIconShapeLabel"] or "Icon shape",
				kind = SettingType.Dropdown,
				field = "iconShape",
				height = 160,
				default = defaults.iconShape or "DEFAULT",
				get = function() return ActionTracker:GetIconShape() end,
				set = function(_, value) applySetting("iconShape", value) end,
				generator = function(_, root)
						local options = addon.IconShape and addon.IconShape.GetOptions and addon.IconShape.GetOptions(L) or {
							{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
							{ value = "SQUARE", label = "Square" },
							{ value = "ROUND", label = "Round" },
							{ value = "ROUND_STAR", label = L["settingsIconShapeRoundStar"] or "Round star" },
							{ value = "HEXAGON", label = "Hexagon" },
							{ value = "DIAMOND", label = "Diamond" },
						}
					for _, option in ipairs(options) do
						local optionValue = option.value
						local optionLabel = option.label
						root:CreateRadio(optionLabel, function() return ActionTracker:GetIconShape() == optionValue end, function() applySetting("iconShape", optionValue) end)
					end
				end,
			},
			{
				name = L["Icon zoom"] or "Icon zoom",
				kind = SettingType.Slider,
				field = "iconZoom",
				minValue = 0,
				maxValue = 35,
				valueStep = 1,
				default = defaults.iconZoom or 0,
				get = function() return ActionTracker:GetIconZoom() end,
				set = function(_, value) applySetting("iconZoom", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = EMBLEM_BORDER,
				kind = SettingType.Collapsible,
				id = "border",
				defaultCollapsed = true,
			},
			{
				name = L["Use border"] or "Use border",
				kind = SettingType.Checkbox,
				field = "borderEnabled",
				parentId = "border",
				default = defaults.borderEnabled == true,
				get = function() return ActionTracker:GetBorderEnabled() end,
				set = function(_, value) applySetting("borderEnabled", value) end,
			},
			{
				name = L["Border texture"] or "Border texture",
				kind = SettingType.Dropdown,
				field = "borderTexture",
				parentId = "border",
				height = 220,
				get = function() return ActionTracker:GetBorderTextureKey() end,
				set = function(_, value) applySetting("borderTexture", value) end,
				generator = function(_, root)
					for _, option in ipairs(getBorderOptions(ActionTracker:GetIconShape())) do
						local optionValue = option.value
						local optionLabel = option.label
						root:CreateRadio(optionLabel, function() return ActionTracker:GetBorderTextureKey() == optionValue end, function() applySetting("borderTexture", optionValue) end)
					end
				end,
				isEnabled = function() return ActionTracker:GetBorderEnabled() end,
			},
			{
				name = L["Border size"] or "Border size",
				kind = SettingType.Slider,
				field = "borderSize",
				parentId = "border",
				default = defaults.borderSize,
				minValue = BORDER_SIZE_MIN,
				maxValue = BORDER_SIZE_MAX,
				valueStep = 1,
				get = function() return ActionTracker:GetBorderSize() end,
				set = function(_, value) applySetting("borderSize", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return ActionTracker:GetBorderEnabled() end,
			},
			{
				name = L["Border offset"] or "Border offset",
				kind = SettingType.Slider,
				field = "borderOffset",
				parentId = "border",
				default = defaults.borderOffset,
				minValue = BORDER_OFFSET_MIN,
				maxValue = BORDER_OFFSET_MAX,
				valueStep = 1,
				get = function() return ActionTracker:GetBorderOffset() end,
				set = function(_, value) applySetting("borderOffset", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				isEnabled = function() return ActionTracker:GetBorderEnabled() end,
			},
			{
				name = EMBLEM_BORDER_COLOR,
				kind = SettingType.Color,
				field = "borderColor",
				parentId = "border",
				default = defaults.borderColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = ActionTracker:GetBorderColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("borderColor", value) end,
				isEnabled = function() return ActionTracker:GetBorderEnabled() end,
			},
		}
	end

	local function seedEditModeRecordFromProfile(record)
		if type(record) ~= "table" then return end
		record.maxIcons = self:GetMaxIcons()
		record.size = self:GetIconSize()
		record.spacing = self:GetSpacing()
		record.direction = self:GetDirection()
		record.fade = self:GetFadeDuration()
		record.showElapsed = self:GetShowElapsed()
		record.showGCDGaps = self:GetShowGCDGaps()
		record.showInterruptedCasts = self:GetShowInterruptedCasts()
		record.iconShape = self:GetIconShape()
		record.iconZoom = self:GetIconZoom()
		record.borderEnabled = self:GetBorderEnabled()
		record.borderTexture = self:GetBorderTextureKey()
		do
			local r, g, b, a = self:GetBorderColor()
			record.borderColor = { r = r, g = g, b = b, a = a }
		end
		record.borderSize = self:GetBorderSize()
		record.borderOffset = self:GetBorderOffset()
	end

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["ActionTracker"] or "Action Tracker",
		layoutDefaults = {
			point = "CENTER",
			relativePoint = "CENTER",
			x = 0,
			y = -200,
			maxIcons = self:GetMaxIcons(),
			size = self:GetIconSize(),
			spacing = self:GetSpacing(),
			direction = self:GetDirection(),
			fade = self:GetFadeDuration(),
			showElapsed = self:GetShowElapsed(),
			showGCDGaps = self:GetShowGCDGaps(),
			showInterruptedCasts = self:GetShowInterruptedCasts(),
			iconShape = self:GetIconShape(),
			iconZoom = self:GetIconZoom(),
			borderEnabled = self:GetBorderEnabled(),
			borderTexture = self:GetBorderTextureKey(),
			borderColor = (function()
				local r, g, b, a = self:GetBorderColor()
				return { r = r, g = g, b = b, a = a }
			end)(),
			borderSize = self:GetBorderSize(),
			borderOffset = self:GetBorderOffset(),
		},
		onApply = function(_, _, data)
			if not self._eqolEditModeHydrated then
				self._eqolEditModeHydrated = true
				local record = data or {}
				seedEditModeRecordFromProfile(record)
				ActionTracker:ApplyLayoutData(record)
				return
			end
			ActionTracker:ApplyLayoutData(data)
		end,
		onEnter = function() ActionTracker:ShowEditModeHint(true) end,
		onExit = function() ActionTracker:ShowEditModeHint(false) end,
		isEnabled = function() return addon.db and addon.db[DB_ENABLED] end,
		settings = settings,
		showOutsideEditMode = true,
	})

	editModeRegistered = true
end

function ActionTracker:OnSettingChanged(enabled)
	if enabled then
		self:EnsureFrame()
		self:RegisterEditMode()
		self:RegisterEvents()
		self:UpdateLayout()
		self:RefreshIcons()
		self:UpdateFadeState(true)
	else
		self:UnregisterEvents()
		self:ClearEntries()
		if self.frame then self.frame:Hide() end
	end

	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end
