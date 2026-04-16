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
local BORDER_OFFSET_MAX = 20
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

local function normalizeBorderTexture(value)
	if type(value) ~= "string" or value == "" then return defaults.borderTexture or "DEFAULT" end
	return value
end

local function resolveBorderTexture(value)
	local key = normalizeBorderTexture(value)
	if key == "DEFAULT" or key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if isLikelyFilePath(key) then return key end
	local hash = getCachedMediaHash("border")
	local texture = hash and hash[key]
	if type(texture) == "string" and texture ~= "" then return texture end
	return "Interface\\Buttons\\WHITE8x8"
end

local function getBorderOptions()
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
function ActionTracker:GetBorderEnabled() return getValue(DB_BORDER_ENABLED, defaults.borderEnabled) == true end
function ActionTracker:GetBorderTextureKey() return normalizeBorderTexture(getValue(DB_BORDER_TEXTURE, defaults.borderTexture)) end
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
	if icon.timeText and icon.timeText.SetWidth then icon.timeText:SetWidth(size + 8) end
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
			if not selfIcon.spellID then return end
			GameTooltip:SetOwner(selfIcon, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(selfIcon.spellID)
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

	for i = 1, MAX_ICONS_LIMIT do
		local icon = frame.icons[i]
		local border = ensureIconBorder(icon)
		if borderEnabled and icon:IsShown() then
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

	self:TrimEntries()

	for i = 1, MAX_ICONS_LIMIT do
		local icon = frame.icons[i]
		local entry = i <= maxIcons and entries[i] or nil
		if entry then
			local texture = entry.texture or (entry.spellID and C_Spell.GetSpellTexture(entry.spellID))
			icon.texture:SetTexture(texture)
			icon.spellID = entry.spellID

			if entry.cooldownDuration then
				icon.cooldown:SetCooldownFromDurationObject(entry.cooldownDuration)
				icon.cooldown:SetDrawEdge(false)
				icon.cooldown:SetDrawBling(false)
				icon.cooldown:SetDrawSwipe(false)
			else
				icon.cooldown:Clear()
			end

			icon:SetAlpha(self:GetEntryAlpha(entry, now, fade))
			if icon.timeText then
				if showElapsed and i > 1 and entries[i - 1] then
					local delta = (entry.time or now) - (entries[i - 1].time or now)
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
			icon.texture:SetTexture(getPreviewTexture(i))
			icon.cooldown:Clear()
			icon:SetAlpha(1)
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
			icon.texture:SetTexture(nil)
			icon.cooldown:Clear()
			icon:SetAlpha(0)
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
	self:StopFadeUpdate()
	self:RefreshIcons()
end

function ActionTracker:AddEntry(spellID)
	if not spellID then return end

	local ignoreList = self.ignoreList
	if ignoreList and ignoreList[spellID] then return end

	local texture = C_Spell.GetSpellTexture(spellID)
	if not texture then return end

	local entry = {
		spellID = spellID,
		texture = texture,
		time = GetTime(),
	}

	local duration = C_Spell.GetSpellCooldownDuration(spellID)
	entry.cooldownDuration = duration

	self.entries[#self.entries + 1] = entry
	local maxIcons = self:GetMaxIcons()
	while #self.entries > maxIcons do
		table.remove(self.entries, 1)
	end

	self:RefreshIcons()
	self:UpdateFadeState(true)
end

function ActionTracker:OnEvent(event, unit, arg2, arg3, arg4)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local spellID = arg3
		self:AddEntry(spellID)
	end
end

function ActionTracker:RegisterEvents()
	if self.eventsRegistered then return end
	local frame = self:EnsureFrame()
	frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	frame:SetScript("OnEvent", function(_, event, ...) ActionTracker:OnEvent(event, ...) end)
	self.eventsRegistered = true
end

function ActionTracker:UnregisterEvents()
	if not self.eventsRegistered or not self.frame then return end
	self.frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
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
	local borderEnabled = data.borderEnabled
	if borderEnabled == nil then borderEnabled = self:GetBorderEnabled() end
	borderEnabled = borderEnabled == true
	local borderTexture = normalizeBorderTexture(data.borderTexture or self:GetBorderTextureKey())
	local borderSize = clampNumber(data.borderSize ~= nil and data.borderSize or self:GetBorderSize(), BORDER_SIZE_MIN, BORDER_SIZE_MAX, defaults.borderSize)
	local borderOffset = clampNumber(data.borderOffset ~= nil and data.borderOffset or self:GetBorderOffset(), BORDER_OFFSET_MIN, BORDER_OFFSET_MAX, defaults.borderOffset)
	local borderR, borderG, borderB, borderA = normalizeColor(data.borderColor or getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor)

	addon.db[DB_MAX_ICONS] = maxIcons
	addon.db[DB_ICON_SIZE] = size
	addon.db[DB_SPACING] = spacing
	addon.db[DB_DIRECTION] = direction
	addon.db[DB_FADE] = fade
	addon.db[DB_SHOW_ELAPSED] = showElapsed
	addon.db[DB_BORDER_ENABLED] = borderEnabled
	addon.db[DB_BORDER_TEXTURE] = borderTexture
	addon.db[DB_BORDER_SIZE] = borderSize
	addon.db[DB_BORDER_OFFSET] = borderOffset
	addon.db[DB_BORDER_COLOR] = { r = borderR, g = borderG, b = borderB, a = borderA }

	self:TrimEntries()
	self:UpdateLayout()
	self:RefreshIcons()
	self:UpdateFadeState(true)
end

local function applySetting(field, value)
	if not addon.db then return end

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
	elseif field == "borderEnabled" then
		local borderEnabled = value == true
		addon.db[DB_BORDER_ENABLED] = borderEnabled
		value = borderEnabled
	elseif field == "borderTexture" then
		local borderTexture = normalizeBorderTexture(value)
		addon.db[DB_BORDER_TEXTURE] = borderTexture
		value = borderTexture
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
					for _, option in ipairs(getBorderOptions()) do
						root:CreateRadio(option.label, function() return ActionTracker:GetBorderTextureKey() == option.value end, function() applySetting("borderTexture", option.value) end)
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
