local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}

local Tracker = {}
addon.Aura.WhirlwindTracker = Tracker

local MAX_STACKS = 4
local STACK_DURATION = 20
local MAX_SEEN_CASTS = 32
local FURY_SPECIALIZATION_ID = 72
local BLADESTORM_SPELL_ID = 446035
local UNHINGED_NO_CONSUME_DURATION = 4

local BLOODTHIRST_SPELL_ID = 23881
local TALENT = { IMPROVED_WHIRLWIND = 12950, CRASHING_THUNDER = 436707, UNHINGED = 386628 }
local GENERATOR = {
	[190411] = true, -- Whirlwind
	[6343] = true, -- Thunder Clap (Crashing Thunder)
	[435222] = true, -- Thunder Blast (Crashing Thunder)
}
local SPENDER = {
	[23881] = true, -- Bloodthirst
	[85288] = true, -- Raging Blow
	[280735] = true, -- Execute
	[202168] = true, -- Impending Victory
	[184367] = true, -- Rampage
	[335096] = true, -- Bloodbath
	[335097] = true, -- Crushing Blow
	[5308] = true, -- Execute (base)
}
local UNHINGED_PROTECTED_SPENDER = { [23881] = true, [335096] = true }

local state = {
	active = false,
	stacks = 0,
	expiresAt = nil,
	noConsumeUntil = 0,
	expiryToken = 0,
	talents = {},
	seen = {},
	seenRing = {},
	seenWrite = 1,
	seenCount = 0,
}
local eventFrame

local function notifyChanged()
	local resourceBars = addon.Aura and addon.Aura.ResourceBars
	if resourceBars and resourceBars.RefreshAuraPowerBar then resourceBars.RefreshAuraPowerBar("WHIRLWIND") end
end

local function clearSeenCasts()
	for index = 1, MAX_SEEN_CASTS do
		local castGUID = state.seenRing[index]
		if castGUID then state.seen[castGUID] = nil end
		state.seenRing[index] = nil
	end
	state.seenWrite, state.seenCount = 1, 0
end

local function wasCastSeen(castGUID)
	if not castGUID then return false end
	if state.seen[castGUID] then return true end
	if state.seenCount >= MAX_SEEN_CASTS then
		local previousGUID = state.seenRing[state.seenWrite]
		if previousGUID then state.seen[previousGUID] = nil end
	else
		state.seenCount = state.seenCount + 1
	end
	state.seenRing[state.seenWrite] = castGUID
	state.seen[castGUID] = true
	state.seenWrite = (state.seenWrite % MAX_SEEN_CASTS) + 1
	return false
end

local function resetState(shouldNotify)
	local changed = state.stacks ~= 0 or state.expiresAt ~= nil
	state.stacks, state.expiresAt, state.noConsumeUntil = 0, nil, 0
	state.expiryToken = state.expiryToken + 1
	clearSeenCasts()
	if shouldNotify and changed then notifyChanged() end
end

local function isSpellKnown(spellID)
	return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) == true
end

local function refreshTalents()
	state.talents.improvedWhirlwind = isSpellKnown(TALENT.IMPROVED_WHIRLWIND)
	state.talents.crashingThunder = isSpellKnown(TALENT.CRASHING_THUNDER)
	state.talents.unhinged = isSpellKnown(TALENT.UNHINGED)
end

local function isFurySpecialization()
	local index = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	if not index then return false end
	return C_SpecializationInfo.GetSpecializationInfo(index) == FURY_SPECIALIZATION_ID
end

local function hasHostileUnitInGeneratorRange()
	local function isValid(unit)
		if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDead(unit) then return false end
		return C_Spell and C_Spell.IsSpellInRange and C_Spell.IsSpellInRange(BLOODTHIRST_SPELL_ID, unit) == true
	end
	if isValid("target") then return true end
	for index = 1, 40 do
		if isValid("nameplate" .. index) then return true end
	end
	return false
end

local function scheduleExpiry()
	state.expiryToken = state.expiryToken + 1
	local token = state.expiryToken
	local remaining = state.expiresAt and (state.expiresAt - GetTime()) or 0
	if remaining <= 0 then
		resetState(true)
		return
	end
	C_Timer.After(remaining + 0.05, function()
		if token ~= state.expiryToken then return end
		if state.expiresAt and GetTime() >= state.expiresAt then resetState(true) end
	end)
end

local function isUnhingedProtected(spellID)
	return state.talents.unhinged and UNHINGED_PROTECTED_SPENDER[spellID] and GetTime() < state.noConsumeUntil or false
end

local function handleSucceededCast(castGUID, spellID)
	if not state.active or not state.talents.improvedWhirlwind or not isFurySpecialization() or wasCastSeen(castGUID) then return end
	if state.talents.unhinged and spellID == BLADESTORM_SPELL_ID then state.noConsumeUntil = GetTime() + UNHINGED_NO_CONSUME_DURATION end
	if GENERATOR[spellID] then
		if (spellID == 6343 or spellID == 435222) and not state.talents.crashingThunder then return end
		if not hasHostileUnitInGeneratorRange() then return end
		state.stacks, state.expiresAt = MAX_STACKS, GetTime() + STACK_DURATION
		scheduleExpiry()
		notifyChanged()
		return
	end
	if SPENDER[spellID] and state.stacks > 0 and not isUnhingedProtected(spellID) then
		state.stacks = state.stacks - 1
		if state.stacks == 0 then
			state.expiresAt = nil
			state.expiryToken = state.expiryToken + 1
		end
		notifyChanged()
	end
end

local function onEvent(_, event, unit, castGUID, spellID)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		if unit == "player" then handleSucceededCast(castGUID, spellID) end
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		clearSeenCasts()
		return
	end
	refreshTalents()
	resetState(true)
end

local function ensureEventFrame()
	if eventFrame then return eventFrame end
	eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", onEvent)
	return eventFrame
end

function Tracker:SetActive(active)
	refreshTalents()
	active = active == true and state.talents.improvedWhirlwind and isFurySpecialization()
	if state.active == active then return end
	state.active = active
	local frame = ensureEventFrame()
	if active then
		frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("PLAYER_DEAD")
		frame:RegisterEvent("PLAYER_ALIVE")
		frame:RegisterEvent("PLAYER_UNGHOST")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
		frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	else
		frame:UnregisterAllEvents()
		resetState(true)
	end
end

function Tracker:GetCounts()
	if state.expiresAt and GetTime() >= state.expiresAt then resetState(false) end
	return state.stacks, MAX_STACKS, MAX_STACKS
end
