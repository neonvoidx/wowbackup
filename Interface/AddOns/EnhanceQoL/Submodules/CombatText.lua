local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.CombatText = addon.CombatText or {}
local CombatText = addon.CombatText

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local LSM = LibStub("LibSharedMedia-3.0", true)
local SharedAnchors = addon.SharedAnchors

local EDITMODE_ID = "combatText"
local PREVIEW_PADDING_X = 20
local PREVIEW_PADDING_Y = 10

local function defaultFontFace()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
end

local function globalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function globalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

CombatText.defaults = CombatText.defaults
	or {
		duration = 3,
		alwaysVisible = false,
		alwaysVisibleMode = "STATUS",
		fontSize = 32,
		fontFace = globalFontConfigKey(),
		color = { r = 1, g = 1, b = 1, a = 1 },
		enterColor = { r = 1, g = 1, b = 1, a = 1 },
		leaveColor = { r = 1, g = 1, b = 1, a = 1 },
	}

local defaults = CombatText.defaults
defaults.enterColor = defaults.enterColor or defaults.color or { r = 1, g = 1, b = 1, a = 1 }
defaults.leaveColor = defaults.leaveColor or defaults.color or defaults.enterColor or { r = 1, g = 1, b = 1, a = 1 }
defaults.color = defaults.color or defaults.enterColor

CombatText.ALWAYS_VISIBLE_MODE_COMBAT_ONLY = CombatText.ALWAYS_VISIBLE_MODE_COMBAT_ONLY or "COMBAT_ONLY"
CombatText.ALWAYS_VISIBLE_MODE_STATUS = CombatText.ALWAYS_VISIBLE_MODE_STATUS or "STATUS"
local ALWAYS_VISIBLE_MODE_COMBAT_ONLY = CombatText.ALWAYS_VISIBLE_MODE_COMBAT_ONLY
local ALWAYS_VISIBLE_MODE_STATUS = CombatText.ALWAYS_VISIBLE_MODE_STATUS
if defaults.alwaysVisibleMode ~= ALWAYS_VISIBLE_MODE_COMBAT_ONLY and defaults.alwaysVisibleMode ~= ALWAYS_VISIBLE_MODE_STATUS then defaults.alwaysVisibleMode = ALWAYS_VISIBLE_MODE_STATUS end

local DB_ENABLED = "combatTextEnabled"
local DB_DURATION = "combatTextDuration"
local DB_ALWAYS_VISIBLE = "combatTextAlwaysVisible"
local DB_ALWAYS_VISIBLE_MODE = "combatTextAlwaysVisibleMode"
local DB_FONT = "combatTextFont"
local DB_FONT_SIZE = "combatTextFontSize"
local DB_COLOR = "combatTextColor"
local DB_ENTER_COLOR = "combatTextEnterColor"
local DB_LEAVE_COLOR = "combatTextLeaveColor"
local DB_ANCHOR_TARGET = "combatTextAnchorTarget"

local function onCombatTextHideTimer()
	CombatText.hideTimer = nil
	CombatText:HideText()
end

local function refreshCombatTextDisplayState()
	if CombatText.previewing then return end
	if addon.db and addon.db[DB_ENABLED] then
		CombatText:RefreshDisplayMode()
	else
		CombatText:HideText()
	end
end

local function onCombatTextEvent(_, event)
	CombatText:OnEvent(event)
end

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

local function getValue(key, fallback)
	if not addon.db then return fallback end
	local value = addon.db[key]
	if value == nil then return fallback end
	return value
end

local function normalizeAnchorTarget(value, current)
	if SharedAnchors and SharedAnchors.ValidateTarget then return SharedAnchors:ValidateTarget(value, current, { includeCursor = false }) end
	if type(value) ~= "string" or value == "" then return "UIParent" end
	return value
end

local function getAnchorTargetEntries(current)
	if SharedAnchors and SharedAnchors.GetEntries then return SharedAnchors:GetEntries(current, { includeCursor = false }) end
	return {
		{ key = "UIParent", label = "UIParent" },
	}
end

local function getAnchorDefaults(target)
	if SharedAnchors and SharedAnchors.GetDefaultAnchorData then return SharedAnchors:GetDefaultAnchorData(target) end
	return {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0,
	}
end

local function getEditModeLayoutValue(field, fallback)
	if EditMode and EditMode.GetValue then
		local value = EditMode:GetValue(EDITMODE_ID, field)
		if value ~= nil then return value end
	end
	return fallback
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

local function normalizeFontFace(value)
	if type(value) ~= "string" or value == "" then return nil end
	return value
end

local function normalizeAlwaysVisibleMode(value)
	if value == ALWAYS_VISIBLE_MODE_COMBAT_ONLY then return ALWAYS_VISIBLE_MODE_COMBAT_ONLY end
	return ALWAYS_VISIBLE_MODE_STATUS
end

function CombatText:_debugTrace(...) end

function CombatText:_debugCheckExternal(...) end

function CombatText:_debugCheckVisual(...) end

function CombatText:_debugEnsureWatcher(enabled)
	if self._debugWatchFrame then
		self._debugWatchFrame:Hide()
		self._debugWatchFrame = nil
	end
end

local function fontFaceOptions()
	local list = {}
	local defaultPath = defaultFontFace()
	local hasDefault = false
	local names = getCachedMediaNames("font")
	local hash = getCachedMediaHash("font")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then
			list[#list + 1] = { value = path, label = tostring(name) }
			if path == defaultPath then hasDefault = true end
		end
	end
	if defaultPath and not hasDefault then list[#list + 1] = { value = defaultPath, label = DEFAULT } end
	table.insert(list, 1, { value = globalFontConfigKey(), label = globalFontConfigLabel() })
	return list
end

local function combatLabel() return _G.COMBAT or "Combat" end

local function getCombatText(inCombat)
	local key = inCombat and "combatTextEnter" or "combatTextLeave"
	local text = L[key]
	if type(text) == "string" and text ~= "" and text ~= key then return text end
	return (inCombat and "+" or "-") .. combatLabel()
end

function CombatText:GetDuration() return clamp(getValue(DB_DURATION, defaults.duration), 0.5, 10) end

function CombatText:IsAlwaysVisible() return getValue(DB_ALWAYS_VISIBLE, defaults.alwaysVisible) == true end

function CombatText:GetAlwaysVisibleMode() return normalizeAlwaysVisibleMode(getValue(DB_ALWAYS_VISIBLE_MODE, defaults.alwaysVisibleMode)) end

function CombatText:GetFontSize() return clamp(getValue(DB_FONT_SIZE, defaults.fontSize), 8, 96) end

function CombatText:GetFontFaceSetting()
	local face = normalizeFontFace(getValue(DB_FONT, defaults.fontFace))
	if not face then face = defaults.fontFace end
	return face
end

function CombatText:GetAnchorTarget()
	local current = getValue(DB_ANCHOR_TARGET, "UIParent")
	return normalizeAnchorTarget(current, current)
end

function CombatText:ResolveAnchorFrame()
	local target = self:GetAnchorTarget()
	if SharedAnchors and SharedAnchors.ResolveFrame then return SharedAnchors:ResolveFrame(target) end
	return UIParent
end

function CombatText:AnchorUsesUIParent()
	local target = self:GetAnchorTarget()
	if SharedAnchors and SharedAnchors.IsUIParentTarget then return SharedAnchors:IsUIParentTarget(target) end
	return target == "UIParent"
end

function CombatText:GetFontFace()
	local face = self:GetFontFaceSetting()
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(face, defaultFontFace()) end
	return face or defaultFontFace()
end

function CombatText:GetEnterColor()
	local fallback = defaults.enterColor or defaults.color
	local value = getValue(DB_ENTER_COLOR, getValue(DB_COLOR, fallback))
	return normalizeColor(value, fallback)
end

function CombatText:GetLeaveColor()
	local fallback = defaults.leaveColor or defaults.enterColor or defaults.color
	local value = getValue(DB_LEAVE_COLOR, getValue(DB_COLOR, fallback))
	return normalizeColor(value, fallback)
end

function CombatText:GetColor() return self:GetEnterColor() end

function CombatText:ApplyStyle(r, g, b, a)
	if not self.frame or not self.frame.text then return end
	local font = self:GetFontFace()
	local size = self:GetFontSize()
	local ok = self.frame.text:SetFont(font, size, "OUTLINE")
	local appliedFont = font
	local fallbackUsed = false
	if not ok then
		appliedFont = defaultFontFace()
		self.frame.text:SetFont(appliedFont, size, "OUTLINE")
		fallbackUsed = true
	end
	if r == nil or g == nil or b == nil then
		local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
		if inCombat then
			r, g, b, a = self:GetEnterColor()
		else
			r, g, b, a = self:GetLeaveColor()
		end
	end
	self.frame.text:SetTextColor(r, g, b, a or 1)
	self:_debugTrace("ApplyStyle", {
		requestedFont = tostring(font),
		appliedFont = tostring(appliedFont),
		fontSize = size,
		setFontOk = ok == true,
		fallbackUsed = fallbackUsed == true,
	})
	self:_debugCheckVisual("ApplyStyle")
end

function CombatText:UpdateFrameSize()
	if not self.frame or not self.frame.text then return end
	local width = self.frame.text:GetStringWidth()
	local height = self.frame.text:GetStringHeight()
	if width < 1 then width = 1 end
	if height < 1 then height = 1 end
	self.frame:SetSize(width + PREVIEW_PADDING_X, height + PREVIEW_PADDING_Y)
	if self.frame.bg then self.frame.bg:SetAllPoints(self.frame) end
end

function CombatText:ApplyAnchorPosition(data)
	if not self.frame then return end

	local point = getEditModeLayoutValue("point", "CENTER")
	if type(point) ~= "string" or point == "" then point = "CENTER" end
	point = SharedAnchors and SharedAnchors.NormalizePoint and SharedAnchors:NormalizePoint(point, "CENTER") or point

	local relativePoint = getEditModeLayoutValue("relativePoint", point)
	if type(relativePoint) ~= "string" or relativePoint == "" then relativePoint = point end
	relativePoint = SharedAnchors and SharedAnchors.NormalizePoint and SharedAnchors:NormalizePoint(relativePoint, point) or relativePoint

	local x = getEditModeLayoutValue("x", 0)
	local y = getEditModeLayoutValue("y", 0)
	if type(data) == "table" then
		if data.point ~= nil then point = SharedAnchors and SharedAnchors.NormalizePoint and SharedAnchors:NormalizePoint(data.point, point) or data.point end
		if data.relativePoint ~= nil then
			relativePoint = SharedAnchors and SharedAnchors.NormalizePoint and SharedAnchors:NormalizePoint(data.relativePoint, point) or data.relativePoint
		end
		if data.x ~= nil then x = data.x end
		if data.y ~= nil then y = data.y end
	end

	if self.frame.SetClampedToScreen then self.frame:SetClampedToScreen(true) end
	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, self:ResolveAnchorFrame(), relativePoint, tonumber(x) or 0, tonumber(y) or 0)
end

function CombatText:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "EQOL_CombatText", UIParent)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("LOW")
	frame:Hide()

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0.1, 0.1, 0.1, 0.4)
	bg:Hide()
	frame.bg = bg

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	frame.text = text

	self.frame = frame
	self:ApplyStyle()
	self:UpdateFrameSize()
	self:ApplyAnchorPosition()

	return frame
end

function CombatText:CancelHideTimer()
	if self.hideTimer then
		self.hideTimer:Cancel()
		self.hideTimer = nil
	end
end

function CombatText:RefreshHideTimer()
	self:CancelHideTimer()
	if self.previewing or self:IsAlwaysVisible() then return end
	if not self.frame or not self.frame:IsShown() then return end
	local duration = self:GetDuration()
	if duration > 0 then self.hideTimer = C_Timer.NewTimer(duration, onCombatTextHideTimer) end
end

function CombatText:RefreshDisplayMode()
	if self.previewing then return end
	if self:IsAlwaysVisible() then
		self:CancelHideTimer()
		if addon.db and addon.db[DB_ENABLED] then
			local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
			self:ShowCombatText(inCombat)
		end
		return
	end
	self:RefreshHideTimer()
end

function CombatText:SetText(text)
	if not self.frame or not self.frame.text then return end
	self.frame.text:SetText(text or "")
	self:UpdateFrameSize()
end

function CombatText:ShowText(text, r, g, b, a)
	local frame = self:EnsureFrame()
	if not frame then return end
	self:ApplyStyle(r, g, b, a)
	self:SetText(text)
	frame:Show()
	self:RefreshHideTimer()
end

function CombatText:HideText()
	self:CancelHideTimer()
	if self.previewing then return end
	if self.frame then self.frame:Hide() end
end

function CombatText:ShowCombatText(inCombat)
	if self.previewing then return end
	if not inCombat and self:IsAlwaysVisible() and self:GetAlwaysVisibleMode() == ALWAYS_VISIBLE_MODE_COMBAT_ONLY then
		self:HideText()
		return
	end
	local r, g, b, a
	if inCombat then
		r, g, b, a = self:GetEnterColor()
	else
		r, g, b, a = self:GetLeaveColor()
	end
	self:ShowText(getCombatText(inCombat), r, g, b, a)
end

function CombatText:ShowEditModeHint(show)
	if not self.frame then return end
	if show then
		self.previewing = true
		self:CancelHideTimer()
		if self.frame.bg then self.frame.bg:Show() end
		local r, g, b, a = self:GetEnterColor()
		self:ApplyStyle(r, g, b, a)
		self:SetText(getCombatText(true))
		self.frame:Show()
	else
		self.previewing = nil
		if self.frame.bg then self.frame.bg:Hide() end
		if addon.db and addon.db[DB_ENABLED] then
			if C_Timer and C_Timer.After then
				C_Timer.After(0, refreshCombatTextDisplayState)
			else
				self:RefreshDisplayMode()
			end
		else
			self:HideText()
		end
	end
end

function CombatText:OnEvent(event)
	if event == "PLAYER_REGEN_DISABLED" then
		self:ShowCombatText(true)
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:ShowCombatText(false)
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Delay one frame so the display state is applied after login/loading transitions.
		if C_Timer and C_Timer.After then
			C_Timer.After(0, refreshCombatTextDisplayState)
		elseif addon.db and addon.db[DB_ENABLED] then
			self:RefreshDisplayMode()
		end
	end
end

function CombatText:RegisterEvents()
	if self.eventsRegistered then return end
	local frame = self:EnsureFrame()
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", onCombatTextEvent)
	self.eventsRegistered = true
end

function CombatText:UnregisterEvents()
	if not self.eventsRegistered or not self.frame then return end
	self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:SetScript("OnEvent", nil)
	self.eventsRegistered = false
end

function CombatText:ApplyLayoutData(data)
	if not addon.db then return end
	data = type(data) == "table" and data or {}
	self:_debugTrace("ApplyLayoutData:begin")

	local currentAnchorTarget = self:GetAnchorTarget()
	local anchorTarget = normalizeAnchorTarget(data.anchorTarget or currentAnchorTarget, currentAnchorTarget)
	local duration = clamp(data.duration ~= nil and data.duration or self:GetDuration(), 0.5, 10)
	local alwaysVisible = data.alwaysVisible ~= nil and data.alwaysVisible == true or self:IsAlwaysVisible()
	local alwaysVisibleMode = normalizeAlwaysVisibleMode(data.alwaysVisibleMode ~= nil and data.alwaysVisibleMode or self:GetAlwaysVisibleMode())
	local fontSize = clamp(data.fontSize ~= nil and data.fontSize or self:GetFontSize(), 8, 96)
	local fontFace = normalizeFontFace(data.fontFace) or self:GetFontFaceSetting() or defaults.fontFace
	local enterR, enterG, enterB, enterA = normalizeColor(
		data.enterColor or data.color or getValue(DB_ENTER_COLOR, getValue(DB_COLOR, defaults.enterColor)),
		defaults.enterColor
	)
	local leaveR, leaveG, leaveB, leaveA = normalizeColor(
		data.leaveColor or data.enterColor or data.color or getValue(DB_LEAVE_COLOR, getValue(DB_COLOR, defaults.leaveColor)),
		defaults.leaveColor
	)

	addon.db[DB_ANCHOR_TARGET] = anchorTarget
	addon.db[DB_DURATION] = duration
	addon.db[DB_ALWAYS_VISIBLE] = alwaysVisible
	addon.db[DB_ALWAYS_VISIBLE_MODE] = alwaysVisibleMode
	addon.db[DB_FONT_SIZE] = fontSize
	addon.db[DB_FONT] = fontFace
	addon.db[DB_ENTER_COLOR] = { r = enterR, g = enterG, b = enterB, a = enterA }
	addon.db[DB_LEAVE_COLOR] = { r = leaveR, g = leaveG, b = leaveB, a = leaveA }
	addon.db[DB_COLOR] = { r = enterR, g = enterG, b = enterB, a = enterA }

	self:ApplyStyle()
	self:UpdateFrameSize()
	self:ApplyAnchorPosition(data)
	self:RefreshDisplayMode()
	self:_debugTrace("ApplyLayoutData:end")
end

local function applySetting(field, value)
	if not addon.db then return end
	CombatText:_debugTrace("applySetting:begin", { field = tostring(field) })

	if field == "duration" then
		local duration = clamp(value, 0.5, 10)
		addon.db[DB_DURATION] = duration
		value = duration
	elseif field == "alwaysVisible" then
		local alwaysVisible = value == true
		addon.db[DB_ALWAYS_VISIBLE] = alwaysVisible
		value = alwaysVisible
	elseif field == "alwaysVisibleMode" then
		local alwaysVisibleMode = normalizeAlwaysVisibleMode(value)
		addon.db[DB_ALWAYS_VISIBLE_MODE] = alwaysVisibleMode
		value = alwaysVisibleMode
	elseif field == "fontSize" then
		local fontSize = clamp(value, 8, 96)
		addon.db[DB_FONT_SIZE] = fontSize
		value = fontSize
	elseif field == "fontFace" then
		local fontFace = normalizeFontFace(value) or defaults.fontFace
		addon.db[DB_FONT] = fontFace
		value = fontFace
	elseif field == "enterColor" then
		local r, g, b, a = normalizeColor(value, defaults.enterColor)
		addon.db[DB_ENTER_COLOR] = { r = r, g = g, b = b, a = a }
		addon.db[DB_COLOR] = { r = r, g = g, b = b, a = a }
		value = addon.db[DB_ENTER_COLOR]
	elseif field == "leaveColor" then
		local r, g, b, a = normalizeColor(value, defaults.leaveColor)
		addon.db[DB_LEAVE_COLOR] = { r = r, g = g, b = b, a = a }
		value = addon.db[DB_LEAVE_COLOR]
	elseif field == "color" then
		local r, g, b, a = normalizeColor(value, defaults.enterColor)
		addon.db[DB_COLOR] = { r = r, g = g, b = b, a = a }
		addon.db[DB_ENTER_COLOR] = { r = r, g = g, b = b, a = a }
		addon.db[DB_LEAVE_COLOR] = { r = r, g = g, b = b, a = a }
		value = addon.db[DB_ENTER_COLOR]
	end

	CombatText:ApplyStyle()
	CombatText:UpdateFrameSize()
	if field == "alwaysVisible" or field == "alwaysVisibleMode" then
		CombatText:RefreshDisplayMode()
	else
		CombatText:RefreshHideTimer()
	end
	CombatText:_debugTrace("applySetting:end", { field = tostring(field) })
end

local function refreshEditModeSettingValues()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
		addon.EditModeLib.internal:RefreshSettingValues()
	end
end

local function setAnchorTarget(value)
	if not addon.db then return end
	local current = CombatText:GetAnchorTarget()
	local target = normalizeAnchorTarget(value, current)
	local defaults = getAnchorDefaults(target)
	addon.db[DB_ANCHOR_TARGET] = target
	if EditMode and EditMode.SetValue then
		EditMode:SetValue(EDITMODE_ID, "anchorTarget", target, nil, true)
		EditMode:SetValue(EDITMODE_ID, "point", defaults.point, nil, true)
		EditMode:SetValue(EDITMODE_ID, "relativePoint", defaults.relativePoint, nil, true)
		EditMode:SetValue(EDITMODE_ID, "x", defaults.x, nil, true)
		EditMode:SetValue(EDITMODE_ID, "y", defaults.y, nil, true)
	end
	CombatText:ApplyLayoutData({
		anchorTarget = target,
		point = defaults.point,
		relativePoint = defaults.relativePoint,
		x = defaults.x,
		y = defaults.y,
	})
	refreshEditModeSettingValues()
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

local editModeRegistered = false

function CombatText:RegisterEditMode()
	if editModeRegistered or not EditMode or not EditMode.RegisterFrame then return end

	local settings
	if SettingType then
		settings = {
			{
				name = L["Anchor to"] or "Anchor to",
				kind = SettingType.Dropdown,
				field = "anchorTarget",
				height = 220,
				default = CombatText:GetAnchorTarget(),
				get = function() return CombatText:GetAnchorTarget() end,
				set = function(_, value) setAnchorTarget(value) end,
				generator = function(_, root)
					local entries = getAnchorTargetEntries(CombatText:GetAnchorTarget())
					local current = CombatText:GetAnchorTarget()
					for i = 1, #entries do
						local option = entries[i]
						root:CreateRadio(option.label, function() return current == option.key end, function() setAnchorTarget(option.key) end)
					end
				end,
			},
			{
				name = L["Anchor point"] or "Anchor point",
				kind = SettingType.Dropdown,
				field = "point",
				height = 180,
				default = "CENTER",
				get = function() return getEditModeLayoutValue("point", "CENTER") end,
				generator = function(_, root)
					local options = SharedAnchors and SharedAnchors.GetAnchorPointOptions and SharedAnchors:GetAnchorPointOptions() or {
						{ value = "TOPLEFT", label = "TOPLEFT" },
						{ value = "TOP", label = "TOP" },
						{ value = "TOPRIGHT", label = "TOPRIGHT" },
						{ value = "LEFT", label = "LEFT" },
						{ value = "CENTER", label = "CENTER" },
						{ value = "RIGHT", label = "RIGHT" },
						{ value = "BOTTOMLEFT", label = "BOTTOMLEFT" },
						{ value = "BOTTOM", label = "BOTTOM" },
						{ value = "BOTTOMRIGHT", label = "BOTTOMRIGHT" },
					}
					for i = 1, #options do
						local option = options[i]
						root:CreateRadio(option.label, function() return getEditModeLayoutValue("point", "CENTER") == option.value end, function()
							if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "point", option.value, nil, true) end
							CombatText:ApplyLayoutData({ point = option.value })
							refreshEditModeSettingValues()
						end)
					end
				end,
			},
			{
				name = L["Relative point"] or "Relative point",
				kind = SettingType.Dropdown,
				field = "relativePoint",
				height = 180,
				default = "CENTER",
				get = function() return getEditModeLayoutValue("relativePoint", getEditModeLayoutValue("point", "CENTER")) end,
				generator = function(_, root)
					local options = SharedAnchors and SharedAnchors.GetAnchorPointOptions and SharedAnchors:GetAnchorPointOptions() or {
						{ value = "TOPLEFT", label = "TOPLEFT" },
						{ value = "TOP", label = "TOP" },
						{ value = "TOPRIGHT", label = "TOPRIGHT" },
						{ value = "LEFT", label = "LEFT" },
						{ value = "CENTER", label = "CENTER" },
						{ value = "RIGHT", label = "RIGHT" },
						{ value = "BOTTOMLEFT", label = "BOTTOMLEFT" },
						{ value = "BOTTOM", label = "BOTTOM" },
						{ value = "BOTTOMRIGHT", label = "BOTTOMRIGHT" },
					}
					for i = 1, #options do
						local option = options[i]
						root:CreateRadio(
							option.label,
							function() return getEditModeLayoutValue("relativePoint", getEditModeLayoutValue("point", "CENTER")) == option.value end,
							function()
								if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "relativePoint", option.value, nil, true) end
								CombatText:ApplyLayoutData({ relativePoint = option.value })
								refreshEditModeSettingValues()
							end
						)
					end
				end,
			},
			{
				name = L["X Offset"] or "X Offset",
				kind = SettingType.Slider,
				field = "x",
				default = 0,
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return tonumber(getEditModeLayoutValue("x", 0)) or 0 end,
				set = function(_, value)
					local x = tonumber(value) or 0
					if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "x", x, nil, true) end
					CombatText:ApplyLayoutData({ x = x })
				end,
			},
			{
				name = L["Y Offset"] or "Y Offset",
				kind = SettingType.Slider,
				field = "y",
				default = 0,
				minValue = -1000,
				maxValue = 1000,
				valueStep = 1,
				allowInput = true,
				get = function() return tonumber(getEditModeLayoutValue("y", 0)) or 0 end,
				set = function(_, value)
					local y = tonumber(value) or 0
					if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "y", y, nil, true) end
					CombatText:ApplyLayoutData({ y = y })
				end,
			},
			{
				name = "",
				kind = SettingType.Divider,
			},
			{
				name = L["combatTextDuration"] or "Display duration",
				kind = SettingType.Slider,
				field = "duration",
				default = defaults.duration,
				minValue = 0.5,
				maxValue = 10,
				valueStep = 0.1,
				get = function() return CombatText:GetDuration() end,
				set = function(_, value) applySetting("duration", value) end,
				formatter = function(value) return string.format("%.1fs", tonumber(value) or 0) end,
				isEnabled = function() return not CombatText:IsAlwaysVisible() end,
			},
			{
				name = L["combatTextAlwaysVisible"] or "Always visible",
				kind = SettingType.Checkbox,
				field = "alwaysVisible",
				default = defaults.alwaysVisible == true,
				get = function() return CombatText:IsAlwaysVisible() end,
				set = function(_, value) applySetting("alwaysVisible", value) end,
			},
			{
				name = L["combatTextAlwaysVisibleMode"] or "Always-show mode",
				kind = SettingType.Dropdown,
				field = "alwaysVisibleMode",
				get = function() return CombatText:GetAlwaysVisibleMode() end,
				set = function(_, value) applySetting("alwaysVisibleMode", value) end,
				isEnabled = function() return CombatText:IsAlwaysVisible() end,
				generator = function(_, root)
					root:CreateRadio(
						L["combatTextAlwaysVisibleModeCombatOnly"] or "Only while in combat (+Combat)",
						function() return CombatText:GetAlwaysVisibleMode() == ALWAYS_VISIBLE_MODE_COMBAT_ONLY end,
						function() applySetting("alwaysVisibleMode", ALWAYS_VISIBLE_MODE_COMBAT_ONLY) end
					)
					root:CreateRadio(
						L["combatTextAlwaysVisibleModeStatus"] or "Always show status (+/-Combat)",
						function() return CombatText:GetAlwaysVisibleMode() == ALWAYS_VISIBLE_MODE_STATUS end,
						function() applySetting("alwaysVisibleMode", ALWAYS_VISIBLE_MODE_STATUS) end
					)
				end,
			},
			{
				name = FONT_SIZE,
				kind = SettingType.Slider,
				field = "fontSize",
				default = defaults.fontSize,
				minValue = 8,
				maxValue = 96,
				valueStep = 1,
				get = function() return CombatText:GetFontSize() end,
				set = function(_, value) applySetting("fontSize", value) end,
				formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			},
			{
				name = L["Font"] or "Font",
				kind = SettingType.Dropdown,
				field = "fontFace",
				height = 200,
				get = function() return CombatText:GetFontFaceSetting() end,
				set = function(_, value) applySetting("fontFace", value) end,
				generator = function(_, root)
					for _, option in ipairs(fontFaceOptions()) do
						root:CreateRadio(option.label, function() return CombatText:GetFontFaceSetting() == option.value end, function() applySetting("fontFace", option.value) end)
					end
				end,
			},
			{
				name = L["combatTextEnterColor"] or "Entering combat color",
				kind = SettingType.Color,
				field = "enterColor",
				default = defaults.enterColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = CombatText:GetEnterColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("enterColor", value) end,
			},
			{
				name = L["combatTextLeaveColor"] or "Leaving combat color",
				kind = SettingType.Color,
				field = "leaveColor",
				default = defaults.leaveColor,
				hasOpacity = true,
				get = function()
					local r, g, b, a = CombatText:GetLeaveColor()
					return { r = r, g = g, b = b, a = a }
				end,
				set = function(_, value) applySetting("leaveColor", value) end,
			},
		}
	end

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["CombatText"] or "Combat text",
		layoutDefaults = {
			point = "CENTER",
			relativePoint = "CENTER",
			anchorTarget = self:GetAnchorTarget(),
			x = 0,
			y = 120,
		},
		onApply = function(_, _, data)
			CombatText:_debugCheckExternal("onApply:before")
			CombatText:ApplyLayoutData(data)
			CombatText:_debugCheckExternal("onApply:after")
		end,
		onEnter = function() CombatText:ShowEditModeHint(true) end,
		onExit = function() CombatText:ShowEditModeHint(false) end,
		isEnabled = function() return addon.db and addon.db[DB_ENABLED] end,
		settings = settings,
		relativeTo = function() return CombatText:ResolveAnchorFrame() end,
		allowDrag = function() return CombatText:AnchorUsesUIParent() end,
		managePosition = false,
		showOutsideEditMode = false,
		showReset = false,
		showSettingsReset = false,
		enableOverlayToggle = true,
	})

	editModeRegistered = true
end

function CombatText:OnSettingChanged(enabled)
	if addon.db then
		addon.db["_combatTextTraceEnabled"] = nil
		addon.db["_combatTextTrace"] = nil
	end
	self:_debugEnsureWatcher(enabled == true)
	self:_debugCheckExternal("OnSettingChanged:begin")
	self:_debugTrace("OnSettingChanged:begin", { enabled = enabled == true })

	if enabled then
		self:EnsureFrame()
		self:RegisterEditMode()
		self:RegisterEvents()
		self:ApplyStyle()
		self:RefreshDisplayMode()
	else
		self:UnregisterEvents()
		self.previewing = nil
		if self.frame and self.frame.bg then self.frame.bg:Hide() end
		self:HideText()
	end

	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
	self:_debugCheckExternal("OnSettingChanged:end")
	self:_debugTrace("OnSettingChanged:end", { enabled = enabled == true })
end

function CombatText:RefreshAnchor()
	if not addon.db or addon.db[DB_ENABLED] ~= true then return end

	self:EnsureFrame()
	if self.frame and self.frame.SetClampedToScreen then self.frame:SetClampedToScreen(true) end

	if EditMode and EditMode.RefreshFrame then
		EditMode:RefreshFrame(EDITMODE_ID)
	else
		self:ApplyAnchorPosition()
	end
end

return CombatText
