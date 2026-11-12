local addon = _G.EnhanceQoL
local P = addon.CooldownPulse

function P:StopObserver(observer)
	observer.armed = false
	observer:SetScript("OnCooldownDone", nil)
	observer:Clear()
	observer:Hide()
end

function P:ObserverDone(spellID, observer)
	if not observer.armed or observer.updating then return end
	observer.armed = false
	observer:SetScript("OnCooldownDone", nil)
	local effective = self:ResolveSpell(spellID)
	if effective ~= observer.identity then self:Scan(false); return end
	local cooldown = C_Spell.GetSpellCooldown(effective)
	if not cooldown or not self.Safe(cooldown.isEnabled) or cooldown.isEnabled ~= true then self:Scan(false); return end
	local charges = C_Spell.GetSpellCharges(effective)
	if charges and self.Safe(charges.maxCharges) and type(charges.maxCharges) == "number" and charges.maxCharges > 0 then
		-- A duration object covers one recharge. Only notify once all charges are ready.
		if not self.Safe(charges.isActive) or charges.isActive ~= false then
			-- Let the client advance the recharge object before observing the next charge.
			C_Timer.After(0, function() P:Scan(false) end)
			return
		end
	end
	if self.Trace then self:Trace("native-done", nil, spellID) end
	-- The observed duration excludes GCD. Its completion is authoritative even
	-- when GetSpellCooldown still reports an active global cooldown.
	for id, entries in pairs(self.tracked or {}) do
		local state = self.states[id] and self.states[id][spellID]
		if entries[spellID] and state and state.identity == effective and state.active then
			state.active = false
			if self.Trace then self:Trace("ready-native", id, spellID) end
			self:Pulse(id, spellID)
		end
	end
	self:SyncObservers()
end

function P:SyncObservers()
	if self.classic then return end
	self.observers = self.observers or {}
	local wanted = {}
	for id, entries in pairs(self.tracked or {}) do
		for spellID in pairs(entries) do
			local state = self.states[id] and self.states[id][spellID]
			if spellID > 0 and state and state.active then wanted[spellID] = state.identity end
		end
	end
	for spellID, observer in pairs(self.observers) do
		if not wanted[spellID] then self:StopObserver(observer) end
	end
	for spellID, identity in pairs(wanted) do
		local observer = self.observers[spellID]
		if not observer then
			observer = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
			observer:SetSize(1, 1); observer:SetPoint("CENTER"); observer:SetAlpha(0)
			observer:SetDrawSwipe(false); observer:SetDrawEdge(false); observer:SetDrawBling(false)
			observer:SetHideCountdownNumbers(true); observer:EnableMouse(false)
			self.observers[spellID] = observer
		end
		local charges = C_Spell.GetSpellCharges(identity)
		local hasCharges = charges and self.Safe(charges.maxCharges) and type(charges.maxCharges) == "number" and charges.maxCharges > 0
		local duration
		if hasCharges then duration = C_Spell.GetSpellChargeDuration(identity)
		else duration = C_Spell.GetSpellCooldownDuration(identity, true) end
		if duration then
			observer.updating = true
			observer.identity, observer.armed = identity, true
			observer:SetScript("OnCooldownDone", function(frame) P:ObserverDone(spellID, frame) end)
			-- Keep it shown but transparent: the native cooldown owns timing and
			-- consumes restricted duration values without Lua inspecting them.
			observer:Show(); observer:SetCooldownFromDurationObject(duration)
			observer.updating = false
		else self:StopObserver(observer) end
	end
end
