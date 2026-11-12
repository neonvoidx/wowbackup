local addon = _G.EnhanceQoL
local P = addon.CooldownPulse

function P:StopGlow(frame)
	if addon.Glow then addon.Glow.Stop(frame, "cooldownPulse", true) end
end

function P:ApplyGlow(frame, entry)
	if not addon.Glow then return end
	if not entry or entry.glowStyle == "NONE" or not self.nativeGlowStyles[entry.glowStyle] then self:StopGlow(frame); return end
	addon.Glow.Start(frame, "cooldownPulse", entry.glowStyle, {
		color = entry.glowColor, count = entry.glowLines, frequency = entry.glowSpeed,
		thickness = entry.glowThickness, inset = 0, border = false, startAnim = false,
	})
end

function P:Stop(frame)
	frame.queue, frame.current = {}, nil
	frame:SetScript("OnUpdate", nil)
	self:StopGlow(frame.visual)
	frame.visual:SetScale(1)
	frame.visual:SetAlpha(1)
	frame:Hide()
end

function P:EnsureFrame(id)
	if self.frames[id] then return self.frames[id] end
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(75, 75)
	frame.visual = CreateFrame("Frame", nil, frame)
	frame.visual.border = CreateFrame("Frame", nil, frame.visual, "BackdropTemplate")
	frame.visual.border:SetPoint("CENTER")
	frame.visual:SetPoint("CENTER")
	frame.visual.icon = frame.visual:CreateTexture(nil, "ARTWORK")
	frame.visual.icon:SetAllPoints()
	frame.visual.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	frame.visual.text = frame.visual:CreateFontString(nil, "OVERLAY")
	frame.visual.text:SetJustifyH("CENTER")
	frame.queue = {}
	frame:Hide()
	self.frames[id] = frame
	return frame
end

function P:ApplyVisual(id, spellID, preview, style)
	local cat, frame = style or self:ResolveStyle(id, spellID), self.frames[id]
	if not cat or not frame then return end
	local visual = frame.visual
	local name, icon = self:SpellInfo(spellID or 0)
	if preview and (not spellID or spellID == 0) then
		-- Keep group defaults for styling, but display a real spell from the group.
		name, icon = nil, nil
		local selected
		for candidate in pairs(self:Group(id).spells) do
			if candidate > 0 and (not selected or candidate < selected) then
				local spellName, spellIcon = self:SpellInfo(candidate)
				if spellIcon then selected, name, icon = candidate, spellName, spellIcon end
			end
		end
	end
	if preview and not icon then
		name, icon = self:SpellInfo(133)
		icon = icon or "Interface\\Icons\\Spell_Fire_FlameBolt"
	end
	frame:SetSize(cat.iconSize * cat.aspectRatio, cat.iconSize)
	visual:SetSize(cat.iconSize * cat.aspectRatio, cat.iconSize)
	frame:SetFrameStrata(cat.strata)
	visual.icon:SetTexture(icon or 134400)
	visual.icon:SetVertexColor(unpack(cat.iconColor))
	visual.icon:SetDesaturated(cat.desaturate)
	local font = self.media and self.media:Fetch("font", cat.font, true) or STANDARD_TEXT_FONT
	visual.text:SetFont(font or STANDARD_TEXT_FONT, cat.fontSize, cat.outline)
	visual.text:ClearAllPoints()
	visual.text:SetPoint("CENTER", visual, "CENTER", cat.textX, cat.textY)
	visual.text:SetWidth(math.max(cat.iconSize, 200))
	visual.text:SetTextColor(unpack(cat.textColor))
	visual.text:SetText(cat.showName and (cat.customTextEnabled and cat.customText or name or (preview and cat.name) or "") or "")
	-- Geometry, colors and media are exclusively user configuration on this frame.
	if cat.borderEnabled then
		local border = self.media and self.media:Fetch("border", cat.border, true) or "Interface\\Buttons\\WHITE8x8"
		visual.border:SetSize(math.max(1, cat.iconSize * cat.aspectRatio + 2 * cat.borderOffset), math.max(1, cat.iconSize + 2 * cat.borderOffset))
		visual.border:SetBackdrop({ edgeFile = border, edgeSize = cat.borderSize })
		visual.border:SetBackdropBorderColor(unpack(cat.borderColor))
		visual.border:Show()
	else visual.border:Hide() end
	self:ApplyGlow(visual, cat)
end

function P:PlaySoundConfig(config)
	if not config then return end
	local key = config.key
	if type(key) ~= "number" and type(key) ~= "string" then return end
	if key == "DEFAULT" then key = SOUNDKIT.ALARM_CLOCK_WARNING_3 end
	local channel = self.channels[config.channel] and config.channel or "Master"
	local path = self.media and self.media:Fetch("sound", key, true)
	if path then PlaySoundFile(path, channel)
	elseif tonumber(key) then PlaySound(tonumber(key), channel)
	elseif SOUNDKIT[key] then PlaySound(SOUNDKIT[key], channel) end
end

function P:PlaySound(id, spellID) self:PlaySoundConfig(self:ResolveSound(id, spellID)) end

function P:Tick(id, elapsed)
	local frame, cat = self.frames[id], self:Group(id)
	if not frame or not cat then return end
	if not frame.current then
		repeat
			frame.current = table.remove(frame.queue, 1)
		until not frame.current or frame.current.preview or not cat.ignoredSpells[frame.current.spellID]
		if not frame.current then
			self:Stop(frame)
			if frame.editing or (addon.EditModeLib and addon.EditModeLib:IsStandaloneSettingsDialogShown(frame)) then self:Preview(id) end
			return
		end
		if self.Trace then self:Trace("animation", id, frame.current.spellID, frame.current.preview and "test" or "live") end
		frame.elapsed = 0
		frame.current.style = self.Copy(self:ResolveStyle(id, frame.current.spellID))
		self:ApplyVisual(id, frame.current.spellID, frame.current.preview, frame.current.style)
		self:PlaySound(id, frame.current.spellID)
	end
	cat = frame.current.style
	frame.elapsed = frame.elapsed + elapsed
	local t = frame.elapsed
	local total = math.max(0.05, cat.fadeInTime + cat.holdTime + cat.fadeOutTime)
	if t >= total then
		self:StopGlow(frame.visual)
		frame.current = nil
		frame.visual:SetAlpha(0)
		return
	end
	local alpha = cat.maxAlpha
	if cat.fadeInTime > 0 and t < cat.fadeInTime then alpha = alpha * t / cat.fadeInTime
	elseif cat.fadeOutTime > 0 and t > cat.fadeInTime + cat.holdTime then alpha = alpha * (total - t) / cat.fadeOutTime end
	frame.visual:SetAlpha(alpha)
	frame.visual:SetScale(1 + (cat.animScale - 1) * t / total)
end

function P:Pulse(id, spellID, preview)
	if not preview and (not self:Enabled(id) or self:Group(id).ignoredSpells[spellID]) then return end
	local frame = self:EnsureFrame(id)
	if frame.editing and not preview then
		if self.Trace then self:Trace("suppressed-editor", id, spellID) end
		return
	end
	if frame.current and frame.current.spellID == spellID then return end
	for _, entry in ipairs(frame.queue) do if entry.spellID == spellID then return end end
	if #frame.queue >= 32 then return end
	frame.queue[#frame.queue + 1] = { spellID = spellID, preview = preview }
	if self.Trace then self:Trace("queued", id, spellID, preview and "test" or "live") end
	frame.visual:SetAlpha(0)
	frame:Show()
	frame:SetScript("OnUpdate", function(_, elapsed) P:Tick(id, elapsed) end)
end

function P:Preview(id)
	local frame = self:EnsureFrame(id)
	self:Stop(frame)
	local spellID = self.editGroup == id and (self.editSpell or 0) or self.selectedSpells[id] or next(self:Group(id).spells) or 0
	self:ApplyVisual(id, spellID, true)
	frame.visual:SetAlpha(self:ResolveStyle(id, spellID).maxAlpha)
	frame:Show()
end

function P:BuildPlayerSpells()
	self.playerSpells = {}
	local book = C_SpellBook
	if book and book.GetNumSpellBookSkillLines then
		for line = 1, book.GetNumSpellBookSkillLines() do
			local info = book.GetSpellBookSkillLineInfo(line)
			if info and not info.offSpecID then
				for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
					local _, _, id = book.GetSpellBookItemType(slot, Enum.SpellBookSpellBank.Player)
					if id and self.Safe(id) and not C_Spell.IsSpellPassive(id) then self.playerSpells[id] = true end
				end
			end
		end
	elseif _G.GetNumSpellTabs then
		for tab = 1, _G.GetNumSpellTabs() do
			local _, _, offset, count = _G.GetSpellTabInfo(tab)
			for slot = offset + 1, offset + count do
				local kind, id = _G.GetSpellBookItemInfo(slot, "spell")
				if kind == "SPELL" and id and not _G.IsPassiveSpell(slot, "spell") then self.playerSpells[id] = true end
			end
		end
	end
end

function P:ResolveSpell(id)
	local effective = C_Spell and C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(id) or id
	if not self.Safe(effective) or not effective or effective == 0 then effective = id end
	return effective
end

function P:KnowsSpell(id)
	local function known(spellID)
		local value
		if C_SpellBook and C_SpellBook.IsSpellKnown then value = C_SpellBook.IsSpellKnown(spellID)
		elseif _G.IsSpellKnown then value = _G.IsSpellKnown(spellID, false)
		else value = self.playerSpells and self.playerSpells[spellID] end
		return self.Safe(value) and value == true
	end
	if known(id) then return true end
	local effective = self:ResolveSpell(id)
	return effective ~= id and known(effective)
end

function P:QuerySpell(id, cooldownEvent)
	local effective = self:ResolveSpell(id)
	local getCooldown = C_Spell and C_Spell.GetSpellCooldown or _G.GetSpellCooldown
	local a, b, c = getCooldown(effective)
	if a == nil then return end
	if not self.classic then
		-- Only documented public flags are inspected. Never touch restricted times/counts.
		if type(a) ~= "table" or not self.Safe(a.isActive) or not self.Safe(a.isEnabled) then return end
		if a.isEnabled ~= true then return end
		local charge = C_Spell.GetSpellCharges(effective)
		if charge and self.Safe(charge.maxCharges) and type(charge.maxCharges) == "number" and charge.maxCharges > 0 then
			if self.Safe(charge.isActive) and type(charge.isActive) == "boolean" then return charge.isActive, effective end
			return
		end
		if a.isActive == false then return false, effective end
		if not cooldownEvent then return nil, effective, "defer-gcd" end
		if not self.Safe(a.isOnGCD) or type(a.isOnGCD) ~= "boolean" then
			-- Off-GCD spells can omit isOnGCD entirely. The native duration API
			-- filters GCD without inspecting restricted cooldown timestamps.
			if C_Spell.GetSpellCooldownDuration(effective, true) then return true, effective end
			return nil, effective, "defer-gcd"
		end
		return not a.isOnGCD, effective
	end
	local start, duration, enabled = a, b, c
	if type(a) == "table" then start, duration, enabled = a.startTime, a.duration, a.isEnabled end
	if not self.Safe(start) or not self.Safe(duration) or not self.Safe(enabled) then return end
	if enabled == false or enabled == 0 or type(start) ~= "number" or type(duration) ~= "number" then return end
	local getCharges = C_Spell and C_Spell.GetSpellCharges or _G.GetSpellCharges
	if getCharges then
		local charges, maximum = getCharges(effective)
		if type(charges) == "table" then charges, maximum = charges.currentCharges, charges.maxCharges end
		if self.Safe(charges) and self.Safe(maximum) and type(charges) == "number" and type(maximum) == "number" and maximum > 0 then return charges < maximum, effective end
	end
	local gcdStart, gcdDuration = getCooldown(61304)
	if type(gcdStart) == "table" then gcdStart, gcdDuration = gcdStart.startTime, gcdStart.duration end
	local gcd = self.Safe(gcdStart) and self.Safe(gcdDuration) and start == gcdStart and duration == gcdDuration
	return not gcd and duration > 0 and start + duration > GetTime(), effective
end

function P:QueryItem(id)
	local slot = -id
	local identity = GetInventoryItemID("player", slot)
	if not identity then return end
	local start, duration, enabled = GetInventoryItemCooldown("player", slot)
	if not self.Safe(start) or not self.Safe(duration) or not self.Safe(enabled) then return end
	if enabled == false or enabled == 0 or type(start) ~= "number" or type(duration) ~= "number" then return end
	return duration > 2 and start + duration > GetTime(), identity
end

function P:UpdateReadyPoller()
	local needed = self.hasTrackedItems or self.classic and self.hasTrackedGroups
	if needed and not self.ticker then
		self.ticker = C_Timer.NewTicker(0.1, function() P:Scan(false, false, not P.classic) end)
	elseif not needed and self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

function P:Scan(cooldownEvent, baseline, itemsOnly)
	local cache = {}
	for id, entries in pairs(self.tracked or {}) do
		local states = self.states[id] or {}
		self.states[id] = states
		for spellID in pairs(entries) do
			if not itemsOnly or spellID < 0 then
				local result = cache[spellID]
				if not result then
					local active, identity, reason
					if spellID < 0 then active, identity = self:QueryItem(spellID) else active, identity, reason = self:QuerySpell(spellID, cooldownEvent) end
					result = { active = active, identity = identity, reason = reason }
					cache[spellID] = result
				end
				local old = states[spellID]
				if result.active == nil then
					-- An unavailable GCD flag does not invalidate an already observed real cooldown.
					-- Held/removed spells and identity changes still break the transition chain.
					if result.reason ~= "defer-gcd" or not old or old.identity ~= result.identity then states[spellID] = nil end
				else
					if not baseline and old and old.identity == result.identity and old.active == true and result.active == false then
						if self.Trace then self:Trace("ready", id, spellID) end
						self:Pulse(id, spellID)
					end
					states[spellID] = { active = result.active, identity = result.identity }
				end
			end
		end
	end
	self:UpdateReadyPoller()
	if self.SyncObservers then self:SyncObservers() end
end

function P:FilterSpellRanks(entries, group)
	if not addon.variables.isForever then return end
	for _, family in pairs(addon.SpellRankFamilies or {}) do
		local selected, explicit, ignored
		-- Families are ordered by rank, so the highest configured rank wins.
		for _, spellID in ipairs(family) do
			if group.ignoredSpells[spellID] then ignored = true end
			if entries[spellID] then
				selected = spellID
				if group.spells[spellID] then explicit = spellID end
			end
		end
		if selected then
			for _, spellID in ipairs(family) do entries[spellID] = nil end
			if not ignored then entries[explicit or selected] = true end
		end
	end
end

function P:Refresh(reset)
	self:InitDB()
	if not self.playerSpells or reset then self:BuildPlayerSpells() end
	self.tracked = {}
	local hasItems, any = false, false
	local knownSpells = {}
	for _, id in ipairs(self:IDs()) do
		local cat = self:Group(id)
		if self.RegisterGroup then self:RegisterGroup(id) end
		if self:Enabled(id) then
			any = true
			local entries = {}
			if not cat.useAdvancedTracking then for spellID in pairs(self.playerSpells) do if not cat.ignoredSpells[spellID] then entries[spellID] = true end end end
			for spellID in pairs(cat.spells) do
				if not cat.ignoredSpells[spellID] then
					if spellID > 0 and knownSpells[spellID] == nil then knownSpells[spellID] = self:KnowsSpell(spellID) end
					if spellID < 0 or knownSpells[spellID] then entries[spellID] = true end
				end
			end
			for spellID in pairs(entries) do if spellID < 0 then hasItems = true end end
			if not cat.useAdvancedTracking then
				for _, sid in ipairs({ -13, -14 }) do if not cat.ignoredSpells[sid] then entries[sid] = true; hasItems = true end end
			end
			self:FilterSpellRanks(entries, cat)
			self.tracked[id] = entries
		else
			self.states[id] = nil
			if self.frames[id] then self:Stop(self.frames[id]) end
		end
	end
	self.events:UnregisterAllEvents()
	if self.ticker then self.ticker:Cancel(); self.ticker = nil end
	self.hasTrackedItems, self.hasTrackedGroups = hasItems, any
	if not any and self.SyncObservers then self:SyncObservers() end
	if any then
		for _, event in ipairs({ "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_COOLDOWN" }) do self.events:RegisterEvent(event) end
		self:Scan(false, true)
	end
end

P.events = CreateFrame("Frame")
P.events:SetScript("OnEvent", function(_, event)
	if P.TraceEvent then P:TraceEvent(event) end
	if event == "SPELL_UPDATE_COOLDOWN" then P:Scan(true)
	elseif event == "SPELL_UPDATE_CHARGES" then
		-- isOnGCD is not valid in this event. The subsequent cooldown event handles ordinary spells.
		for id, entries in pairs(P.tracked or {}) do
			for spellID in pairs(entries) do
				if spellID > 0 then
					local effective = P:ResolveSpell(spellID)
					local charge = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(effective)
					if charge and P.Safe(charge.isActive) and type(charge.isActive) == "boolean" then
						local state = P.states[id] and P.states[id][spellID]
						if state and state.identity == effective and state.active and not charge.isActive then
							if P.Trace then P:Trace("ready-charge", id, spellID) end
							P:Pulse(id, spellID)
						end
						P.states[id] = P.states[id] or {}
						P.states[id][spellID] = { active = charge.isActive, identity = effective }
					end
				end
			end
		end
		P:UpdateReadyPoller()
		if P.SyncObservers then P:SyncObservers() end
	elseif event == "BAG_UPDATE_COOLDOWN" then P:Scan(false, false, true)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then P:Scan(false, true, true)
	else
		for _, frame in pairs(P.frames) do P:Stop(frame) end
		P.states = {}
		P:Refresh(true)
	end
end)
