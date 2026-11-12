local addon = _G.EnhanceQoL
local Panels = addon.Aura.CooldownPanels
local Sounds = { widgets = setmetatable({}, { __mode = "k" }), generation = 0, blockedSpells = {} }
Panels.ReadySounds = Sounds

local function isSecret(value) return issecretvalue and issecretvalue(value) end

function Sounds:IsSuppressed()
	if C_PvP and C_PvP.GetActiveMatchState and Enum and Enum.PvPMatchState then
		local state = C_PvP.GetActiveMatchState()
		if not isSecret(state) then
			return state ~= Enum.PvPMatchState.Inactive and state ~= Enum.PvPMatchState.Engaged
		end
	end
	return false
end

function Sounds:Queue(name, record)
	if not name or name == "None" or self:IsSuppressed() then return end
	local generation = self.generation
	local ticket = {}
	record.ticket = ticket
	-- Wait for the current event batch: a reset arriving after the cooldown
	-- update must still be able to cancel this notification.
	C_Timer.After(0, function()
		if generation ~= self.generation or record.ticket ~= ticket or self:IsSuppressed() then return end
		record.ticket = nil
		if record.panelId then
			local enabled = Panels.runtime and Panels.runtime.enabledPanels
			local panel = Panels:GetPanel(record.panelId)
			local entry = panel and panel.entries and panel.entries[record.entryId]
			if not (enabled and enabled[record.panelId] and entry and entry.soundReady == true) then return end
		elseif record.stateKey then
			local sounds = Panels.runtime and Panels.runtime.readySoundSoundByStateKey
			if not sounds or sounds[record.stateKey] ~= name then return end
		end
		if self.play then self.play(name) end
	end)
end

function Sounds:IsReady(data)
	if data.cooldownGCD == true then return false end
	if data.resolvedType == "SPELL" then
		return not isSecret(data.cooldownIsActive) and data.cooldownIsActive == false
	end
	if data.resolvedType == "ITEM" or data.resolvedType == "SLOT" then
		local start, duration = data.cooldownStart, data.cooldownDuration
		if isSecret(start) or isSecret(duration) then return false end
		if type(start) ~= "number" or type(duration) ~= "number" then return false end
		return start == 0 or duration == 0 or start + duration <= GetTime()
	end
	return false
end

function Sounds:Update(cooldown, panelId, entryId, data, arm)
	local record = self.widgets[cooldown]
	if not record or record.panelId ~= panelId or record.entryId ~= entryId then
		if record then record.ticket = nil end
		local key = data.spellId and Panels:GetReadySoundStateKey(data.spellId)
		record = { panelId = panelId, entryId = entryId, phase = key and self.blockedSpells[key] and "blocked" or "idle" }
		self.widgets[cooldown] = record
	end
	record.spellId, record.baseSpellId = data.spellId, data.baseSpellId
	local eligible = data.soundReady == true and data.spellAuraOverlayActive ~= true and data.customCooldownDurationActive ~= true
		and not (data.chargesInfo and data.chargesInfo.maxCharges ~= nil)
	if not eligible then
		record.phase, record.ticket = "idle", nil
	elseif self:IsSuppressed() then
		record.phase, record.ticket = "blocked", nil
	elseif self:IsReady(data) then
		if record.phase == "armed" then self:Queue(data.soundName, record) end
		record.phase = "idle"
		if data.spellId then self.blockedSpells[Panels:GetReadySoundStateKey(data.spellId)] = nil end
	elseif arm and record.phase == "idle" then
		record.phase = "armed"
	end
	-- A callback consumes the cycle before asking for a refresh. Stale active
	-- data must not arm it again; a ready sample or a new cast starts a new cycle.
	cooldown._eqolSoundReady = record.phase == "armed" or nil
	cooldown._eqolSoundReadyIgnoreGCD = record.phase == "armed" and data.cooldownGCD == true or nil
end

function Sounds:Complete(cooldown)
	local record = self.widgets[cooldown]
	if not record or record.phase ~= "armed" then return end
	record.phase = "done"
	cooldown._eqolSoundReady = nil
	cooldown._eqolSoundReadyIgnoreGCD = nil
	self:Queue(cooldown._eqolSoundName, record)
end

function Sounds:Reset(reason)
	self.generation = self.generation + 1
	local block = reason ~= "rebuild"
	if block then
		self.blockedSpells = {}
		for key in pairs(Panels.runtime and Panels.runtime.readySoundQueryByStateKey or {}) do self.blockedSpells[key] = true end
	end
	for cooldown, record in pairs(self.widgets) do
		record.phase, record.ticket = (block or record.phase == "blocked") and "blocked" or "idle", nil
		cooldown._eqolSoundReady = nil
		cooldown._eqolSoundReadyIgnoreGCD = nil
	end
	for _, state in pairs(Panels.runtime and Panels.runtime.readySoundStates or {}) do
		state.initialized, state.unavailable, state.resetBlocked, state.ticket = false, false, block or state.resetBlocked, nil
	end
end

function Sounds:OnCast(spellId)
	if isSecret(spellId) or type(spellId) ~= "number" then return end
	self.blockedSpells[Panels:GetReadySoundStateKey(spellId)] = nil
	for _, record in pairs(self.widgets) do
		if record.spellId == spellId or record.baseSpellId == spellId then
			record.phase, record.ticket = "idle", nil
		end
	end
	local state = Panels.GetReadySoundState and Panels:GetReadySoundState(spellId, false)
	if state then state.resetBlocked = nil end
end

Sounds.frame = CreateFrame("Frame")
for _, event in ipairs({
	"PLAYER_ENTERING_WORLD", "PLAYER_LOGIN", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED",
	"PLAYER_SPECIALIZATION_CHANGED", "CHALLENGE_MODE_START", "CHALLENGE_MODE_RESET",
	"ARENA_PREP_OPPONENT_SPECIALIZATIONS", "PVP_MATCH_STATE_CHANGED", "PVP_MATCH_ACTIVE", "PVP_MATCH_COMPLETE",
}) do
	-- Client event sets differ; unsupported events are intentionally omitted.
	if _G.C_EventUtils and _G.C_EventUtils.IsEventValid then
		if _G.C_EventUtils.IsEventValid(event) then Sounds.frame:RegisterEvent(event) end
	else
		pcall(Sounds.frame.RegisterEvent, Sounds.frame, event)
	end
end
Sounds.frame:SetScript("OnEvent", function(_, event, unit, isReload)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
	if event == "PLAYER_LOGIN" or (event == "PLAYER_ENTERING_WORLD" and (unit == true or isReload == true)) then
		Sounds:Reset("rebuild")
	else
		Sounds:Reset(event)
	end
end)
