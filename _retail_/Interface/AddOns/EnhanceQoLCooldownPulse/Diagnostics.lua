local addon = _G.EnhanceQoL
local P = addon.CooldownPulse

-- Temporary, opt-in timing diagnostics. Restricted values are never formatted.
function P:Trace(stage, id, spellID, detail)
	local trace = self.trace
	if not trace or not trace.active or (spellID and spellID ~= trace.spellID) then return end
	local elapsed = GetTime() - trace.started
	if elapsed >= 60 then trace.active = false; return end
	local frame = id and self.frames[id]
	local current = frame and frame.current
	local row = {
		t = elapsed, stage = stage, group = id, spell = spellID, detail = detail,
		queued = frame and #frame.queue or 0, current = current and current.spellID,
	}
	trace.rows[#trace.rows + 1] = row
	if #trace.rows > 500 then table.remove(trace.rows, 1) end
end

function P:TraceFlags()
	local trace = self.trace
	if not trace then return "no trace" end
	local id = self:ResolveSpell(trace.spellID)
	if self.classic then
		local function value(v)
			if not P.Safe(v) then return "restricted" end
			if v == nil then return "nil" end
			if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
			return type(v)
		end
		local getCooldown = C_Spell and C_Spell.GetSpellCooldown or _G.GetSpellCooldown
		local start, duration, enabled = getCooldown(id)
		if type(start) == "table" then start, duration, enabled = start.startTime, start.duration, start.isEnabled end
		local gcdStart, gcdDuration = getCooldown(61304)
		if type(gcdStart) == "table" then gcdStart, gcdDuration = gcdStart.startTime, gcdStart.duration end
		local getCharges = C_Spell and C_Spell.GetSpellCharges or _G.GetSpellCharges
		local current, maximum
		if getCharges then
			current, maximum = getCharges(id)
			if type(current) == "table" then current, maximum = current.currentCharges, current.maxCharges end
		end
		local active = self:QuerySpell(trace.spellID, false)
		return "classic effective=" .. value(id) .. " known=" .. value(self:KnowsSpell(trace.spellID))
			.. " active=" .. value(active) .. " start=" .. value(start) .. " duration=" .. value(duration) .. " enabled=" .. value(enabled)
			.. " gcdStart=" .. value(gcdStart) .. " gcdDuration=" .. value(gcdDuration)
			.. " charges=" .. value(current) .. "/" .. value(maximum) .. " ticker=" .. value(self.ticker ~= nil)
	end
	local cd = C_Spell.GetSpellCooldown(id)
	local charges = C_Spell.GetSpellCharges(id)
	local function flag(value)
		if not P.Safe(value) then return "restricted" end
		if value == true then return "1" elseif value == false then return "0" end
		return "?"
	end
	-- isOnGCD is recorded only in the cooldown event, never trusted by the probe.
	return "active=" .. flag(cd and cd.isActive) .. " enabled=" .. flag(cd and cd.isEnabled) .. " recharge=" .. flag(charges and charges.isActive)
end

function P:StartTrace(spellID)
	spellID = tonumber(spellID) or 77758
	self.trace = { active = true, spellID = spellID, started = GetTime(), rows = {} }
	if not self.traceFrame then self.traceFrame = CreateFrame("Frame") end
	local elapsed, last = 0, nil
	self.traceFrame:SetScript("OnUpdate", function(_, delta)
		local trace = P.trace
		if not trace.active or GetTime() - trace.started >= 60 then
			trace.active = false; P.traceFrame:SetScript("OnUpdate", nil); P.traceFrame:Hide(); return
		end
		elapsed = elapsed + delta
		if elapsed < 0.05 then return end
		elapsed = 0
		local flags = P:TraceFlags()
		if flags ~= last then last = flags; P:Trace("probe", nil, spellID, flags) end
	end)
	self.traceFrame:Show()
	self:Trace("start", nil, spellID, self:TraceFlags())
	for _, id in ipairs(self:IDs()) do
		local group = self:Group(id)
		local tracked = self.tracked and self.tracked[id]
		self:Trace("config", id, spellID, "enabled=" .. tostring(group.enabled == true)
			.. " manual=" .. tostring(group.useAdvancedTracking == true) .. " explicit=" .. tostring(group.spells[spellID] ~= nil)
			.. " ignored=" .. tostring(group.ignoredSpells[spellID] == true) .. " tracked=" .. tostring(tracked and tracked[spellID] == true or false))
	end
end

function P:TraceEvent(event)
	if not self.trace or not self.trace.active then return end
	local detail = self:TraceFlags()
	if event == "SPELL_UPDATE_COOLDOWN" and not self.classic then
		local cd = C_Spell.GetSpellCooldown(self:ResolveSpell(self.trace.spellID))
		local gcd = cd and cd.isOnGCD
		if self.Safe(gcd) and type(gcd) == "boolean" then detail = detail .. " gcd=" .. (gcd and "1" or "0") end
	end
	self:Trace(event, nil, self.trace.spellID, detail)
end

function P:ShowTrace()
	local trace = self.trace
	if not trace then return end
	trace.active = false
	if self.traceFrame then self.traceFrame:SetScript("OnUpdate", nil); self.traceFrame:Hide() end
	local lines = { "Cooldown Pulse timing / spell " .. trace.spellID }
	for _, row in ipairs(trace.rows) do
		lines[#lines + 1] = string.format("%.3f %s group=%s queue=%d current=%s %s", row.t, row.stage, tostring(row.group or "-"), row.queued, tostring(row.current or "-"), row.detail or "")
	end
	return self:ShowTextDialog(self.L["CooldownPulse"], table.concat(lines, "\n"))
end
