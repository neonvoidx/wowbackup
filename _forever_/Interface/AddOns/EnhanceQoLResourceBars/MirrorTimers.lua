local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

addon.MirrorTimers = addon.MirrorTimers or {}
local M = addon.MirrorTimers
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
M.types = { "BREATH", "EXHAUSTION", "FEIGNDEATH", "DEATH" }
M.frames, M.states, M.suppressedFrames = {}, {}, {}
M.labelKeys = { BREATH = "mirrorTimerBreath", EXHAUSTION = "mirrorTimerFatigue", FEIGNDEATH = "mirrorTimerFeignDeath", DEATH = "mirrorTimerDeath" }
M.colors = {
	BREATH = { r = 0.15, g = 0.65, b = 1, a = 1 }, EXHAUSTION = { r = 1, g = 0.65, b = 0.1, a = 1 },
	FEIGNDEATH = { r = 0.65, g = 0.35, b = 0.95, a = 1 }, DEATH = { r = 0.85, g = 0.2, b = 0.2, a = 1 },
}
M.defaults = {
	width = 260, height = 24, texture = "DEFAULT", color = { r = 0.15, g = 0.65, b = 1, a = 1 },
	bgColor = { r = 0, g = 0, b = 0, a = 0.65 }, borderEnabled = true, borderTexture = "DEFAULT",
	borderSize = 1, borderOffset = 0, borderColor = { r = 0, g = 0, b = 0, a = 1 }, alpha = 1, strata = "MEDIUM", fillDirection = "LEFT",
	labelEnabled = true, labelFont = "__EQOL_GLOBAL_FONT__", labelSize = 12, labelOutline = "__EQOL_GLOBAL_FONT_STYLE__",
	labelColor = { r = 1, g = 1, b = 1, a = 1 }, labelAnchor = "LEFT", labelOffsetX = 6, labelOffsetY = 0,
	textEnabled = true, textFont = "__EQOL_GLOBAL_FONT__", textSize = 12, textOutline = "__EQOL_GLOBAL_FONT_STYLE__",
	textColor = { r = 1, g = 1, b = 1, a = 1 }, textAnchor = "RIGHT", textOffsetX = -6, textOffsetY = 0,
	textFormat = "CURRENT_MAX", decimals = 0, timeStyle = "SECONDS", gradientEnabled = false,
	warningThreshold = 30, criticalThreshold = 10, warningColor = { r = 1, g = 0.85, b = 0, a = 1 },
	criticalColor = { r = 1, g = 0.1, b = 0.1, a = 1 }, point = "CENTER", relativePoint = "CENTER", x = 0, y = 180,
}

function M.Copy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, item in pairs(value) do copy[key] = M.Copy(item) end
	return copy
end

function M.IsSecret(value) return issecretvalue and issecretvalue(value) end

function M.Number(value, fallback, minimum, maximum)
	if M.IsSecret(value) or type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
	if minimum then value = math.max(minimum, value) end
	if maximum then value = math.min(maximum, value) end
	return value
end

function M:GetDefaults(timer)
	local defaults = self.Copy(self.defaults)
	defaults.color = self.Copy(self.colors[timer] or defaults.color)
	for index, name in ipairs(self.types) do if name == timer then defaults.y = 180 - (index - 1) * 36; break end end
	return defaults
end

function M:GetDB()
	if not addon.db then return nil end
	if type(addon.db.mirrorTimers) ~= "table" then addon.db.mirrorTimers = { enabled = false, bars = {} } end
	local db = addon.db.mirrorTimers
	if type(db.bars) ~= "table" then db.bars = {} end
	return db
end

function M:GetConfig(timer)
	local defaults = self:GetDefaults(timer)
	local db = self:GetDB()
	if not db then return defaults end
	if type(db.bars[timer]) ~= "table" then db.bars[timer] = {} end
	local config = db.bars[timer]
	for key, value in pairs(defaults) do if config[key] == nil then config[key] = self.Copy(value) end end
	return config
end

function M:IsSupported(capabilitiesOnly)
	if not capabilitiesOnly and self.supported ~= nil then return self.supported end
	if not (GetMirrorTimerInfo and GetMirrorTimerProgress and _G.C_DurationUtil and C_StringUtil and Enum
		and _G.C_DurationUtil.CreateDuration and _G.C_DurationUtil.CreateManualClock and _G.C_DurationUtil.CreateDurationTextBinding
		and C_StringUtil.CreateNumericRuleFormatter and Enum.StatusBarTimerDirection and Enum.StatusBarInterpolation
		and Enum.DurationTimeModifier and Enum.DurationTextBindingProperty and Enum.NumericRuleFormatRounding) then return false end
	if capabilitiesOnly then return true end
	local probe = CreateFrame("StatusBar", nil, UIParent)
	probe:Hide()
	local ok, supported = pcall(function()
		local duration = _G.C_DurationUtil.CreateDuration()
		local clock = _G.C_DurationUtil.CreateManualClock()
		local binding = _G.C_DurationUtil.CreateDurationTextBinding()
		local formatter = C_StringUtil.CreateNumericRuleFormatter()
		return probe.SetTimerDuration and duration.SetClock and duration.SetTimeFromStart and duration.Reset and clock.SetTime
			and binding.SetFontString and binding.SetDuration and binding.SetTimeModifier and binding.SetUpdateInterval and binding.Disable
			and binding.SetTextFormat and binding.SetExpiredText and binding.SetZeroDurationText and binding.SetEnabled and binding.UpdateFontString
			and formatter.SetBreakpoints and formatter.FormatNumber
	end)
	self.supported = ok and not not supported
	return self.supported
end

function M:IsEnabled()
	local db = self:GetDB()
	return db and db.enabled == true and self:IsSupported() or false
end

function M:EnsureFrames()
	if not self:IsSupported() then return false end
	for _, timer in ipairs(self.types) do
		if not self.frames[timer] then
			local bar = CreateFrame("StatusBar", "EQOLMirrorTimer" .. timer, UIParent)
			bar.timerType = timer
			bar:SetClampedToScreen(true)
			bar.duration = _G.C_DurationUtil.CreateDuration()
			bar.clock = _G.C_DurationUtil.CreateManualClock()
			bar.bg = bar:CreateTexture(nil, "BACKGROUND")
			bar.bg:SetAllPoints()
			bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
			bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			bar.binding = _G.C_DurationUtil.CreateDurationTextBinding()
			bar.binding:SetFontString(bar.text)
			bar.binding:SetDuration(bar.duration)
			bar.binding:SetTimeModifier(Enum.DurationTimeModifier.RealTime)
			bar.binding:Disable()
			bar:Hide()
			self.frames[timer] = bar
		end
	end
	return true
end

function M.Color(value, fallback)
	value = type(value) == "table" and value or fallback
	return M.Number(value.r or value[1], fallback.r, 0, 1), M.Number(value.g or value[2], fallback.g, 0, 1),
		M.Number(value.b or value[3], fallback.b, 0, 1), M.Number(value.a or value[4], fallback.a or 1, 0, 1)
end

function M:ApplyFont(fontString, cfg, prefix)
	local functions = addon.functions or {}
	local face = functions.GetGlobalDefaultFontFace and functions.GetGlobalDefaultFontFace() or STANDARD_TEXT_FONT
	if functions.ResolveFontFace then face = functions.ResolveFontFace(cfg[prefix .. "Font"], face) or face end
	local size = self.Number(cfg[prefix .. "Size"], 12, 6, 64)
	if functions.ApplyFontString then functions.ApplyFontString(fontString, cfg[prefix .. "Font"], size, cfg[prefix .. "Outline"], face, "OUTLINE")
	else fontString:SetFont(face, size, "OUTLINE") end
	fontString:SetTextColor(self.Color(cfg[prefix .. "Color"], self.defaults[prefix .. "Color"]))
	fontString:ClearAllPoints()
	local anchor = cfg[prefix .. "Anchor"]
	if not ({ TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true })[anchor] then anchor = "CENTER" end
	fontString:SetPoint(anchor, fontString:GetParent(), anchor, self.Number(cfg[prefix .. "OffsetX"], 0, -1000, 1000), self.Number(cfg[prefix .. "OffsetY"], 0, -1000, 1000))
	fontString:SetShown(cfg[prefix .. "Enabled"] ~= false)
end

function M:HasPositionAssignment(timer)
	local id = "mirrorTimer:" .. timer
	local anchors = addon.EditModeAnchors
	local record
	if anchors and anchors.Store then record = anchors:Store(id)
	elseif addon.db and type(addon.db.editModeAnchorLinks) == "table" then record = addon.db.editModeAnchorLinks[id] end
	return type(record) == "table" and type(record.assignment) == "table" and record.assignment.enabled == true
end

function M:ApplyAppearance(timer)
	local bar, cfg = self.frames[timer], self:GetConfig(timer)
	if not bar then return end
	bar:SetSize(self.Number(cfg.width, 260, 20, 2000), self.Number(cfg.height, 24, 4, 200))
	bar:SetAlpha(self.Number(cfg.alpha, 1, 0, 1))
	local strata = cfg.strata
	if not ({ BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true, DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true })[strata] then strata = "MEDIUM" end
	bar:SetFrameStrata(strata)
	local positioned = bar.GetNumPoints and bar:GetNumPoints() > 0 or (not bar.GetNumPoints and bar:GetPoint(1) ~= nil)
	-- Shared Edit Mode anchors own linked placement. Reanchoring to UIParent on
	-- a timer event would detach the link until its owner can run out of combat.
	-- New frames still receive a fallback while their first link is resolved.
	if not self:HasPositionAssignment(timer) or not positioned then
		bar:ClearAllPoints()
		local points = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
		bar:SetPoint(points[cfg.point] and cfg.point or "CENTER", UIParent, points[cfg.relativePoint] and cfg.relativePoint or "CENTER",
			self.Number(cfg.x, 0, -10000, 10000), self.Number(cfg.y, 180, -10000, 10000))
	end
	local texture = LSM and LSM:Fetch("statusbar", cfg.texture, true)
	bar:SetStatusBarTexture(texture or "Interface\\Buttons\\WHITE8x8")
	bar:SetOrientation((cfg.fillDirection == "UP" or cfg.fillDirection == "DOWN") and "VERTICAL" or "HORIZONTAL")
	bar:SetReverseFill(cfg.fillDirection == "RIGHT" or cfg.fillDirection == "DOWN")
	bar.bg:SetColorTexture(self.Color(cfg.bgColor, self.defaults.bgColor))
	self:ApplyFont(bar.label, cfg, "label")
	self:ApplyFont(bar.text, cfg, "text")
	local offset = self.Number(cfg.borderOffset, 0, -20, 20)
	bar.border:ClearAllPoints()
	bar.border:SetPoint("TOPLEFT", bar, "TOPLEFT", -offset, offset)
	bar.border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", offset, -offset)
	if cfg.borderEnabled then
		local r, g, b, a = self.Color(cfg.borderColor, self.defaults.borderColor)
		local border = LSM and LSM:Fetch("border", cfg.borderTexture, true)
		bar.border:SetBackdrop({ edgeFile = border or "Interface\\Buttons\\WHITE8x8", edgeSize = self.Number(cfg.borderSize, 1, 1, 20) })
		bar.border:SetBackdropBorderColor(r, g, b, a)
	else bar.border:SetBackdrop(nil) end
end

function M:GetCurrentValue(state)
	if not state then return nil end
	local value = state.value
	if not state.paused and state.scale ~= 0 then value = value + (GetTime() - state.startedAt) * state.scale * 1000 end
	return math.max(0, math.min(state.maximum, value))
end

function M:MakeState(value, maximum, scale, paused, label)
	if self.IsSecret(value) or self.IsSecret(maximum) or self.IsSecret(scale) or self.IsSecret(paused) then return nil end
	value, maximum, scale = self.Number(value), self.Number(maximum), self.Number(scale)
	if not value or not maximum or not scale or maximum <= 0 then return nil end
	return { value = math.max(0, math.min(maximum, value)), maximum = maximum, scale = scale,
		paused = paused == true or (type(paused) == "number" and paused ~= 0), label = label, startedAt = GetTime() }
end

function M:CreateFormatter(speed, maximum, cfg, percent)
	local formatter = C_StringUtil.CreateNumericRuleFormatter()
	local decimals = math.floor(self.Number(cfg.decimals, 0, 0, 3))
	local components, format
	if percent then
		format, components = "%d%%", { { div = maximum / speed / 100, step = 1 } }
	elseif cfg.timeStyle == "CLOCK" then
		format = "%d:%0" .. (decimals > 0 and tostring(3 + decimals) .. "." .. decimals .. "f" or "2d")
		components = { { div = 60 / speed, step = 1, rounding = Enum.NumericRuleFormatRounding.Down },
			{ div = 1 / speed, mod = 60, step = 10 ^ -decimals, rounding = Enum.NumericRuleFormatRounding.Down } }
	else
		format, components = "%." .. decimals .. "f", { { div = 1 / speed, step = 10 ^ -decimals } }
	end
	formatter:SetBreakpoints({ { threshold = 0, min = 0, max = maximum / speed,
		step = not percent and 10 ^ -decimals / speed or nil, format = format, components = components } })
	return formatter
end

function M:ConfigureText(bar, state, cfg, increasing, speed)
	local property = increasing and Enum.DurationTextBindingProperty.ElapsedDuration or Enum.DurationTextBindingProperty.RemainingDuration
	local maximum = state.maximum / 1000
	bar.valueFormatter = self:CreateFormatter(speed, maximum, cfg)
	bar.percentFormatter = self:CreateFormatter(speed, maximum, cfg, true)
	local totalFormatter = self:CreateFormatter(1, maximum, cfg)
	local maximumText = totalFormatter:FormatNumber(maximum)
	local format, components = "{}", { { property = property, formatter = bar.valueFormatter } }
	local ending = bar.valueFormatter:FormatNumber(increasing and maximum / speed or 0)
	if cfg.textFormat == "CURRENT_MAX" or cfg.textFormat == "CURRENT_MAX_PERCENT" then
		format, ending = format .. " / " .. maximumText, ending .. " / " .. maximumText
	end
	if cfg.textFormat == "PERCENT" then
		components[1].formatter = bar.percentFormatter
		ending = increasing and "100%" or "0%"
	elseif cfg.textFormat == "CURRENT_MAX_PERCENT" then
		format = format .. " ({})"
		components[2] = { property = property, formatter = bar.percentFormatter }
		ending = ending .. (increasing and " (100%)" or " (0%)")
	elseif cfg.textFormat == "TIME_TO_FULL" then
		local realMaximum = maximum / speed
		bar.timeFormatter = self:CreateFormatter(1, realMaximum, cfg)
		components[1] = { property = Enum.DurationTextBindingProperty.RemainingDuration, formatter = bar.timeFormatter }
		ending = bar.timeFormatter:FormatNumber(0)
	end
	bar.binding:SetUpdateInterval(cfg.decimals and cfg.decimals > 0 and 0.05 or 0.1)
	bar.binding:SetTextFormat(format, components)
	bar.binding:SetExpiredText(ending)
	bar.binding:SetZeroDurationText(ending)
	bar.binding:SetEnabled(cfg.textEnabled ~= false)
	if cfg.textEnabled ~= false then bar.binding:UpdateFontString() else bar.text:SetText("") end
end

function M:CancelColorTimer(bar)
	if bar.colorTimer then bar.colorTimer:Cancel(); bar.colorTimer = nil end
end

function M:GetGradientThresholds(timer)
	local cfg = self:GetConfig(timer)
	local warning = self.Number(cfg.warningThreshold, 30, 1, 100)
	local critical = math.min(warning, self.Number(cfg.criticalThreshold, 10, 0, 99))
	return warning, critical
end

function M:GetPreviewPercentage(timer)
	if not self.colors[timer] then return nil end
	local phase = self.previewSamples and self.previewSamples[timer] or 1
	local warning, critical = self:GetGradientThresholds(timer)
	if phase == 2 then return warning end
	if phase == 3 then return critical end
	return 100
end

function M:CyclePreviewSample(timer)
	if not self.preview or not self.colors[timer] then return false end
	self.previewSamples = self.previewSamples or {}
	self.previewSamples[timer] = (self.previewSamples[timer] or 1) % 3 + 1
	self:Refresh()
	return true
end

function M:ApplyColor(timer, state)
	local bar, cfg = self.frames[timer], self:GetConfig(timer)
	self:CancelColorTimer(bar)
	local r, g, b, a = self.Color(cfg.color, self.colors[timer])
	if cfg.gradientEnabled and state then
		local fraction = self:GetCurrentValue(state) / state.maximum
		local warning, critical = self:GetGradientThresholds(timer)
		warning, critical = warning / 100, critical / 100
		local from, target, ratio
		if fraction <= critical then
			from, target, ratio = cfg.criticalColor, cfg.criticalColor, 0
		elseif fraction <= warning then
			from, target = cfg.criticalColor, cfg.warningColor
			ratio = (fraction - critical) / math.max(0.001, warning - critical)
		else
			from, target, ratio = cfg.warningColor, cfg.color, (fraction - warning) / math.max(0.001, 1 - warning)
		end
		local fr, fg, fb, fa = self.Color(from, self.defaults.criticalColor)
		local tr, tg, tb, ta = self.Color(target, self.colors[timer])
		r, g, b, a = fr + (tr - fr) * ratio, fg + (tg - fg) * ratio, fb + (tb - fb) * ratio, fa + (ta - fa) * ratio
		if not state.paused and ((state.scale < 0 and fraction > 0) or (state.scale > 0 and fraction < 1)) then
			-- Sample at half-percent steps, never every rendered frame. Only color
			-- interpolation needs Lua; duration bars and text are native bindings.
			local delay = math.max(0.05, state.maximum / math.abs(state.scale) / 1000 / 200)
			bar.colorTimer = C_Timer.NewTimer(delay, function()
				bar.colorTimer = nil
				if self:IsEnabled() and bar:IsShown() then self:ApplyColor(timer, state) end
			end)
		end
	end
	bar:SetStatusBarColor(r, g, b, a)
end

function M:Render(timer, state)
	local bar, cfg = self.frames[timer], self:GetConfig(timer)
	if not bar then return end
	if not state then self:HideBar(bar); return end
	local value, now = self:GetCurrentValue(state), GetTime()
	local speed = state.scale == 0 and 1 or math.abs(state.scale)
	local elapsed = state.scale > 0 and value or state.maximum - value
	bar.binding:Disable()
	if state.paused or state.scale == 0 then bar.clock:SetTime(now); bar.duration:SetClock(bar.clock)
	else bar.duration:SetClock(nil) end
	bar.duration:SetTimeFromStart(now - elapsed / 1000 / speed, state.maximum / 1000 / speed, 1 / speed)
	local increasing = state.scale > 0
	bar:SetTimerDuration(bar.duration, Enum.StatusBarInterpolation.Immediate,
		increasing and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime)
	self:ConfigureText(bar, state, cfg, increasing, speed)
	if self.IsSecret(state.label) then bar.label:SetText(state.label) else bar.label:SetText(state.label or L[self.labelKeys[timer]]) end
	bar:Show()
	self:ApplyColor(timer, state)
end

function M:HideBar(bar)
	if not bar then return end
	self:CancelColorTimer(bar)
	bar.binding:Disable()
	bar.duration:Reset()
	bar:Hide()
end

function M:SuppressBlizzard(enabled)
	local defaults = { _G.MirrorTimerContainer, _G.MirrorTimer1, _G.MirrorTimer2, _G.MirrorTimer3 }
	if enabled then
		for _, frame in pairs(defaults) do
			if not self.suppressedFrames[frame] then self.suppressedFrames[frame] = { alpha = frame:GetAlpha() } end
			frame:SetAlpha(0)
		end
	else
		for frame, state in pairs(self.suppressedFrames) do frame:SetAlpha(state.alpha) end
		wipe(self.suppressedFrames)
	end
end

function M:Snapshot()
	local states, unsafe = {}, false
	for index = 1, 3 do
		local timer, value, maximum, scale, paused, label = GetMirrorTimerInfo(index)
		if self.IsSecret(timer) then unsafe = true
		elseif timer and timer ~= "UNKNOWN" then
			if self.colors[timer] then
				local progress = GetMirrorTimerProgress(timer)
				if self.IsSecret(progress) or progress ~= nil then value = progress end
				states[timer] = self:MakeState(value, maximum, scale, paused, label)
				if not states[timer] then unsafe = true end
			else unsafe = true end
		end
	end
	self.states, self.unsafe = states, unsafe
end

function M:Refresh()
	local enabled = self:IsEnabled()
	if enabled and not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
	if self.eventFrame and self._eventsEnabled ~= enabled then
		self.eventFrame:UnregisterAllEvents()
		self.eventFrame:SetScript("OnEvent", enabled and function(_, event, ...) self:OnEvent(event, ...) end or nil)
		if enabled then
			for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ADDON_LOADED", "MIRROR_TIMER_START", "MIRROR_TIMER_STOP", "MIRROR_TIMER_PAUSE" }) do self.eventFrame:RegisterEvent(event) end
		end
		self._eventsEnabled = enabled
	end
	if not enabled then
		self.preview, self.previewSamples, self.unsafe = false, nil, false
		wipe(self.states)
		if self.UnregisterEditMode then self:UnregisterEditMode() end
	end
	if not enabled or not self:EnsureFrames() then
		for _, bar in pairs(self.frames) do self:HideBar(bar) end
		self:SuppressBlizzard(false)
		return
	end
	self:SuppressBlizzard(enabled and not self.unsafe)
	for _, timer in ipairs(self.types) do
		self:ApplyAppearance(timer)
		local state = enabled and not self.unsafe and self.states[timer] or nil
		if self.preview then
			local editMode = addon.EditMode
			if not editMode or not editMode.IsFrameVisibleInEditMode or editMode:IsFrameVisibleInEditMode("mirrorTimer:" .. timer) then
				state = self:MakeState(self:GetPreviewPercentage(timer) * 600, 60000, -1, true, L[self.labelKeys[timer]])
			else state = nil end
		end
		self:Render(timer, state)
	end
end

function M:SetPreview(enabled)
	self.preview = enabled == true and self:IsEnabled()
	if not self.preview then self.previewSamples = nil end
	self:Refresh()
end

function M:SetEnabled(enabled)
	local db = self:GetDB()
	if not db then return end
	db.enabled = enabled == true
	if self:IsEnabled() then
		self:EnsureFrames()
		if self.RegisterEditMode then self:RegisterEditMode() end
		self:Snapshot()
		local editMode = addon.EditMode
		self.preview = editMode and editMode.IsInEditMode and editMode:IsInEditMode() or false
	end
	self:Refresh()
	local editMode = addon.EditMode
	if editMode and editMode.RefreshFrame then
		for _, timer in ipairs(self.types) do editMode:RefreshFrame("mirrorTimer:" .. timer) end
	end
end

function M:OnEvent(event, timer, value, maximum, scale, paused, label)
	if not self:IsEnabled() then self:SuppressBlizzard(false); return end
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
		self:Snapshot()
	elseif event == "MIRROR_TIMER_START" then
		if self.IsSecret(timer) then self.unsafe = true
		elseif self.colors[timer] then
			self.states[timer] = self:MakeState(value, maximum, scale, paused, label)
			if not self.states[timer] then self.unsafe = true elseif self.unsafe then self:Snapshot() end
		else self.unsafe = true end
	elseif event == "MIRROR_TIMER_STOP" then
		if not self.IsSecret(timer) and timer then self.states[timer] = nil else self.unsafe = true end
		if self.unsafe then self:Snapshot() end
	elseif event == "MIRROR_TIMER_PAUSE" then
		if self.IsSecret(timer) then self.unsafe = true
		elseif self.states[timer] then
			local state = self.states[timer]
			local progress = GetMirrorTimerProgress(timer)
			if not self.IsSecret(progress) and progress == nil then progress = self:GetCurrentValue(state) end
			self.states[timer] = self:MakeState(progress, state.maximum, state.scale, value, state.label)
			if not self.states[timer] then self.unsafe = true end
		end
	end
	self:Refresh()
end

function M:Initialize()
	self:GetDB()
	if self:IsEnabled() then
		self:EnsureFrames()
		if self.RegisterEditMode then self:RegisterEditMode() end
		self:Snapshot()
	end
	self:Refresh()
end
