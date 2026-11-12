local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end

local H = addon.Aura.UFHelper
local M = {}

function M.IsSecret(value) return _G.issecretvalue and _G.issecretvalue(value) end

function M.GetTiming(unit, spellId)
	if _G.UnitCastingDuration and C_Spell and C_Spell.GetSpellCooldownDuration then
		local empowered = _G.UnitEmpoweredChannelDuration and _G.UnitEmpoweredChannelDuration(unit, true)
		local duration = empowered
		local channel = false
		if not duration then
			duration = _G.UnitCastingDuration(unit)
			if not duration then
				duration = _G.UnitChannelDuration and _G.UnitChannelDuration(unit)
				channel = duration ~= nil
			end
		end
		local cooldown = C_Spell.GetSpellCooldownDuration(spellId, true)
		if not (duration and cooldown) then return end
		local blocked
		if channel or empowered then blocked = select(7, UnitChannelInfo(unit)) else blocked = select(8, UnitCastingInfo(unit)) end
		if type(blocked) == "nil" then blocked = false end
		return duration:GetElapsedDuration(), duration:GetTotalDuration(), cooldown:GetRemainingDuration(), channel, blocked, cooldown:IsZero()
	end

	-- Older clients expose ordinary timestamps instead of duration objects.
	local name, _, _, startTime, endTime, _, _, blocked = UnitCastingInfo(unit)
	local channel = false
	if not name then
		name, _, _, startTime, endTime, _, blocked = UnitChannelInfo(unit)
		channel = true
	end
	if not name or M.IsSecret(startTime) or M.IsSecret(endTime) or M.IsSecret(blocked) then return end
	local start, duration, enabled, rate
	if C_Spell and C_Spell.GetSpellCooldown then
		local info = C_Spell.GetSpellCooldown(spellId)
		if not info then return end
		start, duration, enabled, rate = info.startTime, info.duration, info.isEnabled, info.modRate
	elseif _G.GetSpellCooldown then
		start, duration, enabled, rate = _G.GetSpellCooldown(spellId)
	end
	if M.IsSecret(start) or M.IsSecret(duration) or M.IsSecret(enabled) or M.IsSecret(rate) then return end
	if not start or not duration or enabled == false or enabled == 0 or not startTime or not endTime then return end
	local total = (endTime - startTime) / 1000
	if total <= 0 then return end
	local remaining = start + duration / ((rate and rate > 0) and rate or 1) - GetTime()
	return GetTime() - startTime / 1000, total, remaining, channel, blocked, remaining <= 0
end

function M.Update(marker)
	local st, cfg = marker.state, marker.config
	if cfg.showInterruptReadyMarker ~= true or st.castInterruptActive then marker.position:Hide(); return end
	local elapsed, total, remaining, channel, blocked, ready
	if st.castInfo and st.castInfo.isSample == true then
		-- A stable preview remains visible regardless of the player's real cooldown.
		elapsed, total, remaining, channel, blocked, ready = 0, 1, 0.65, false, false, false
	else
		local tracker = addon.Aura.FocusInterruptTracker
		if tracker and tracker.GetSharedInterruptReadiness and tracker:GetSharedInterruptReadiness() == true then marker.position:Hide(); return end
		local spellId = tracker and tracker.ResolveInterruptSpell and tracker:ResolveInterruptSpell()
		if not spellId then marker.position:Hide(); return end
		elapsed, total, remaining, channel, blocked, ready = M.GetTiming(marker.unit, spellId)
	end
	if type(total) == "nil" then marker.position:Hide(); return end
	local reverse = channel ~= (cfg.reverseFill == true)
	H.applyStatusBarReverseFill(marker.position, reverse)
	H.applyStatusBarReverseFill(marker.offset, reverse)
	marker.offset:ClearAllPoints()
	marker.line:ClearAllPoints()
	local edge, opposite = reverse and "RIGHT" or "LEFT", reverse and "LEFT" or "RIGHT"
	marker.offset:SetPoint(edge, marker.position:GetStatusBarTexture(), opposite)
	marker.line:SetPoint(edge, marker.offset:GetStatusBarTexture(), opposite)
	marker.position:SetMinMaxValues(0, total)
	marker.offset:SetMinMaxValues(0, total)
	marker.position:SetValue(elapsed)
	marker.offset:SetValue(remaining)
	if C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
		local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(blocked, 0, 1)
		marker.offset:SetAlpha(C_CurveUtil.EvaluateColorValueFromBoolean(ready, 0, alpha))
	elseif not M.IsSecret(blocked) and not M.IsSecret(ready) then
		marker.offset:SetAlpha((blocked or ready) and 0 or 1)
	else
		marker.position:Hide()
		return
	end
	marker.position:Show()
end

function H.ConfigureCastInterruptMarker(st, unit, cfg)
	local marker = st.castInterruptMarker
	if cfg.showInterruptReadyMarker ~= true or not (unit == "target" or unit == "focus" or unit:match("^boss%d$")) then
		if marker then marker:Hide() end
		return
	end
	if not marker then
		marker = CreateFrame("Frame", nil, st.castBar)
		marker:Hide()
		st.castInterruptMarker = marker
		marker:SetAllPoints(st.castBar)
		marker:SetClipsChildren(true)
		marker:SetFrameLevel(st.castBar:GetFrameLevel() + 6)
		marker.position = CreateFrame("StatusBar", nil, marker)
		marker.position:SetAllPoints(marker)
		marker.position:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		marker.position:SetStatusBarColor(1, 1, 1, 0)
		marker.offset = CreateFrame("StatusBar", nil, marker.position)
		marker.offset:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		marker.offset:SetStatusBarColor(1, 1, 1, 0)
		marker.line = marker.offset:CreateTexture(nil, "OVERLAY")
		marker.line:SetColorTexture(1, 1, 1, 1)
		marker.line:SetWidth(2)
		marker:SetScript("OnShow", function(self)
			M.Update(self)
		end)
		marker:SetScript("OnSizeChanged", function(self, width, height)
			self.offset:SetSize(width, height)
			self.line:SetHeight(height)
		end)
	end
	marker.state, marker.unit, marker.config = st, unit, cfg
	local color = cfg.interruptReadyMarkerColor or { 1, 1, 1, 1 }
	marker.line:SetColorTexture(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
	marker.offset:SetSize(st.castBar:GetSize())
	marker.line:SetHeight(st.castBar:GetHeight())
	marker:Show()
	M.Update(marker)
end

-- The shared interrupt tracker owns the native cooldown-completion observer.
function H.RefreshCastInterruptMarker(st)
	local marker = st.castInterruptMarker
	if marker and marker:IsShown() then M.Update(marker) end
end
