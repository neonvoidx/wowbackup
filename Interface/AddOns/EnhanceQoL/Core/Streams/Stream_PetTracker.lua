-- luacheck: globals EnhanceQoL UnitClass UnitExists UnitIsDeadOrGhost C_SpecializationInfo GetSpecializationInfo NORMAL_FONT_COLOR GetTime UnitOnTaxi UnitInVehicle UnitHasVehicleUI IsMounted C_SpellBook C_Timer C_Spell GetSpellTexture IsResting IsFlying IsPlayerSpell InCombatLockdown UnitAffectingCombat C_UnitAuras AuraUtil
local addonName, addon = ...
local L = addon.L

local db
local blinkStartAt
local blinkTicker
local blinkTickInterval
local DEFAULT_INTERVAL = 1.0
local DEFAULT_THROTTLE = 0.1
local BLINK_TICK = 1 / 30
local HOLD_FRACTION = 0.1
local MAX_HOLD = 0.12

local PET_SPECS = {
	[252] = true, -- Unholy DK
	[253] = true, -- Hunter: Beast Mastery
	[255] = true, -- Hunter: Survival
	[265] = true, -- Warlock: Affliction
	[266] = true, -- Warlock: Demonology
	[267] = true, -- Warlock: Destruction
}

local SPEC_MARKSMANSHIP = 254
local MARKS_PET_TALENT_ID = 1223323
local SPEC_FROST_MAGE = 64
local MAGE_PET_TALENT_ID = 31687
local CALL_PET_SPELL_ID = 883
local RAISE_DEAD_SPELL_ID = 46584
local SUMMON_IMP_SPELL_ID = 688
local GRIMOIRE_OF_SACRIFICE_SPELL_ID = 108503
local GRIMOIRE_OF_SACRIFICE_BUFF_ID = 196099
local DEFAULT_PET_ICON = "Interface\\Icons\\Ability_Hunter_BeastCall"
local DB_IGNORE_PET_DEFENSIVE = "classBuffReminderIgnorePetDefensive"
local DB_IGNORE_PET_PASSIVE = "classBuffReminderIgnorePetPassive"

local PET_CLASSES = {
	HUNTER = true,
	WARLOCK = true,
}

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.pettracker = addon.db.datapanel.pettracker or {}
	db = addon.db.datapanel.pettracker
	db.fontSize = db.fontSize or 14
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	if db.showIcon == nil then db.showIcon = true end
	if db.hideWhileRested == nil then db.hideWhileRested = false end
	if db.layoutMode ~= "textAbove" and db.layoutMode ~= "textBelow" then db.layoutMode = "inline" end
	if db.blinkEnabled == nil then db.blinkEnabled = false end
	db.blinkRate = db.blinkRate or 0.7
end

local function shouldIgnorePetDefensiveReminder()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.ShouldIgnorePetDefensiveReminder then return reminder:ShouldIgnorePetDefensiveReminder() end
	return addon.db and addon.db[DB_IGNORE_PET_DEFENSIVE] == true
end

local function shouldIgnorePetPassiveReminder()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.ShouldIgnorePetPassiveReminder then return reminder:ShouldIgnorePetPassiveReminder() end
	return addon.db and addon.db[DB_IGNORE_PET_PASSIVE] == true
end

local function isWarlockSacrificePetReminderSuppressed()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.IsWarlockSacrificePetReminderSuppressed then return reminder:IsWarlockSacrificePetReminderSuppressed() end

	local class = UnitClass and select(2, UnitClass("player"))
	if class ~= "WARLOCK" then return false end
	if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(GRIMOIRE_OF_SACRIFICE_SPELL_ID) == true then return true end
	if IsPlayerSpell and IsPlayerSpell(GRIMOIRE_OF_SACRIFICE_SPELL_ID) == true then return true end
	if InCombatLockdown and InCombatLockdown() then return false end
	if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
	if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(GRIMOIRE_OF_SACRIFICE_BUFF_ID) then return true end
	if AuraUtil and AuraUtil.FindAuraBySpellID and AuraUtil.FindAuraBySpellID(GRIMOIRE_OF_SACRIFICE_BUFF_ID, "player", "HELPFUL") then return true end
	return false
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_pettracker_fontSize")
	end
end

addon.PetTrackerOptions = addon.PetTrackerOptions or {}
addon.PetTrackerOptions.ResetBlink = function()
	blinkStartAt = nil
end

local function isPetExpected()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.IsPetExpectedForPlayer then return reminder:IsPetExpectedForPlayer() end

	local class = UnitClass and select(2, UnitClass("player"))
	local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	if specIndex and C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
		local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if specID == SPEC_FROST_MAGE then return C_SpellBook.IsSpellKnown(MAGE_PET_TALENT_ID) and true or false end
		if specID == SPEC_MARKSMANSHIP then return C_SpellBook.IsSpellKnown(MARKS_PET_TALENT_ID) and true or false end
		if PET_SPECS[specID] then return class ~= "WARLOCK" or not isWarlockSacrificePetReminderSuppressed() end
		return false
	end

	if class == "MAGE" then return C_SpellBook.IsSpellKnown(MAGE_PET_TALENT_ID) and true or false end
	if class == "HUNTER" then return C_SpellBook.IsSpellKnown(MARKS_PET_TALENT_ID) and true or false end
	if class == "WARLOCK" then return not isWarlockSacrificePetReminderSuppressed() end
	if class and PET_CLASSES[class] then return true end
	return false
end


local function hasActivePet()
	if not UnitExists or not UnitExists("pet") then return false end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("pet") then return false end
	return true
end

local function isPetSuppressed()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.IsPetReminderSuppressed then return reminder:IsPetReminderSuppressed() end

	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return true end
	if IsMounted and IsMounted() then return true end
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true end
	if UnitInVehicle and UnitInVehicle("player") then return true end
	if UnitOnTaxi and UnitOnTaxi("player") then return true end
	if IsFlying and IsFlying() then return true end
	return false
end

local function getPetReminderState()
	local reminder = addon.ClassBuffReminder
	if reminder and reminder.IsPetExpectedForPlayer and not reminder:IsPetExpectedForPlayer() then return nil end
	if reminder and reminder.IsPetReminderSuppressed and reminder:IsPetReminderSuppressed() then return nil end


	if not hasActivePet() then
		return "missing", L["ClassBuffReminderPetMissing"] or L["Pet Missing"] or "Pet Missing", reminder and reminder.GetPetReminderIcon and reminder:GetPetReminderIcon("missing") or DEFAULT_PET_ICON
	end

	if reminder and reminder.GetPetStance and reminder.petTracking then
		local stance = reminder:GetPetStance()
		if stance == reminder.petTracking.stancePassive and not shouldIgnorePetPassiveReminder() then
			return "passive", L["ClassBuffReminderPetPassive"] or "Pet Passive", reminder:GetPetReminderIcon("passive")
		end
		if stance == reminder.petTracking.stanceDefensive and not shouldIgnorePetDefensiveReminder() then
			return "defensive", L["ClassBuffReminderPetDefensive"] or "Pet Defensive", reminder:GetPetReminderIcon("defensive")
		end
	end

	return nil
end

local floor = math.floor
local format = string.format
local max = math.max

local function colorToHex(color)
	local r = (color and color.r) or 1
	local g = (color and color.g) or 1
	local b = (color and color.b) or 1
	return format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

local function getPlayerClassAndSpec()
	local class = UnitClass and select(2, UnitClass("player"))
	local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	local specID
	if specIndex and C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then specID = C_SpecializationInfo.GetSpecializationInfo(specIndex) end
	return class, specID
end

local function getReminderIconTexture()
	local class, specID = getPlayerClassAndSpec()
	local spellID

	if specID == SPEC_FROST_MAGE or class == "MAGE" then
		spellID = MAGE_PET_TALENT_ID
	elseif specID == 252 or class == "DEATHKNIGHT" then
		spellID = RAISE_DEAD_SPELL_ID
	elseif specID == 253 or specID == 255 or specID == SPEC_MARKSMANSHIP or class == "HUNTER" then
		spellID = CALL_PET_SPELL_ID
	elseif specID == 265 or specID == 266 or specID == 267 or class == "WARLOCK" then
		spellID = SUMMON_IMP_SPELL_ID
	end

	if spellID and C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellID)
		if texture then return texture end
	end
	if spellID and GetSpellTexture then
		local texture = GetSpellTexture(spellID)
		if texture then return texture end
	end
	return DEFAULT_PET_ICON
end

local function isPlayerResting()
	if IsResting then return IsResting() and true or false end
	return false
end

local function hideSnapshot(snapshot)
	snapshot.hidden = true
	snapshot.text = nil
	snapshot.parts = nil
	snapshot.textAlpha = nil
	snapshot.tooltip = nil
end

local function buildReminderParts(text, iconTexture, fontSize)
	local iconSize = max(floor((fontSize or 14) + 0.5), 14)
	local textHeight = max(floor((fontSize or 14) + 4 + 0.5), 16)
	local iconPart = {
		icon = { texture = iconTexture, size = iconSize },
		iconSize = iconSize,
		iconWidth = iconSize,
		height = iconSize,
	}
	local textPart = {
		text = text,
		height = textHeight,
	}

	if db.layoutMode == "textAbove" then
		return {
			partsLayout = "vertical",
			partSpacing = 1,
			parts = { textPart, iconPart },
		}
	elseif db.layoutMode == "textBelow" then
		return {
			partsLayout = "vertical",
			partSpacing = 1,
			parts = { iconPart, textPart },
		}
	end

	return {
		partSpacing = 4,
		parts = { iconPart, textPart },
	}
end

local function stopBlinkTicker()
	if blinkTicker then
		blinkTicker:Cancel()
		blinkTicker = nil
		blinkTickInterval = nil
	end
end

local function startBlinkTicker(stream, tick)
	if blinkTicker and blinkTickInterval == tick then return end
	stopBlinkTicker()
	blinkTickInterval = tick
	blinkTicker = C_Timer.NewTicker(tick, function()
		if not stream or not stream.subscribers or not next(stream.subscribers) then
			stopBlinkTicker()
			return
		end
		addon.DataHub:RequestUpdate(stream)
	end)
end

local function setStreamTiming(stream, interval, throttle)
	if stream.interval ~= interval then stream.interval = interval end
	if stream.throttle ~= throttle then stream.throttle = throttle end
end

local function resetBlink(stream)
	blinkStartAt = nil
	stopBlinkTicker()
	setStreamTiming(stream, DEFAULT_INTERVAL, DEFAULT_THROTTLE)
end

local function getBlinkInterval()
	local interval = tonumber(db.blinkRate) or 0.7
	if interval < 0.2 then interval = 0.2 end
	return interval
end

local function smoothstep(t)
	if t <= 0 then return 0 end
	if t >= 1 then return 1 end
	return t * t * (3 - 2 * t)
end

local function getBlinkAlpha(interval)
	local now = GetTime()
	if not blinkStartAt then blinkStartAt = now end
	local half = interval
	local period = half * 2
	local phase = (now - blinkStartAt) % period
	local hold = half * HOLD_FRACTION
	if hold > MAX_HOLD then hold = MAX_HOLD end
	local fade = half - hold
	if fade <= 0 then return (phase < half) and 1 or 0 end
	if phase < half then
		if phase < hold then return 1 end
		local t = (phase - hold) / fade
		return 1 - smoothstep(t)
	end
	phase = phase - half
	if phase < hold then return 0 end
	local t = (phase - hold) / fade
	return smoothstep(t)
end

local function update(stream)
	ensureDB()
	local editModeActive = addon.EditModeLib and addon.EditModeLib:IsInEditMode()
	local needsPet = editModeActive or isPetExpected()
	if not needsPet then
		hideSnapshot(stream.snapshot)
		resetBlink(stream)
		return
	end

	if not editModeActive and db.hideWhileRested and isPlayerResting() then
		hideSnapshot(stream.snapshot)
		resetBlink(stream)
		return
	end

	local state, text, icon = getPetReminderState()
	if not editModeActive and (not state or isPetSuppressed()) then
		hideSnapshot(stream.snapshot)
		resetBlink(stream)
		return
	end

	stream.snapshot.hidden = nil
	stream.snapshot.fontSize = db.fontSize or 14
	stream.snapshot.tooltip = getOptionsHint()
	stream.snapshot.text = nil
	stream.snapshot.parts = nil

	local alpha = 1
	if db.blinkEnabled and not editModeActive then
		local interval = getBlinkInterval()
		setStreamTiming(stream, DEFAULT_INTERVAL, 0)
		startBlinkTicker(stream, BLINK_TICK)
		alpha = getBlinkAlpha(interval)
	else
		resetBlink(stream)
	end

	text = text or L["Pet Missing"] or "Pet Missing"
	local hex = colorToHex(db.textColor)
	local coloredText = format("|cff%s%s|r", hex, text)
	if db.showIcon then
		local partsPayload = buildReminderParts(coloredText, icon or DEFAULT_PET_ICON, db.fontSize or 14)
		stream.snapshot.parts = partsPayload.parts
		stream.snapshot.partsLayout = partsPayload.partsLayout
		stream.snapshot.partSpacing = partsPayload.partSpacing
	else
		stream.snapshot.partsLayout = nil
		stream.snapshot.partSpacing = nil
		stream.snapshot.text = coloredText
	end
	stream.snapshot.textAlpha = alpha
end

local provider = {
	id = "pettracker",
	version = 1,
	title = L["Pet Tracker"] or "Pet Tracker",
	classFilter = {
		DEATHKNIGHT = true,
		HUNTER = true,
		MAGE = true,
		WARLOCK = true,
	},
	poll = 1.0,
	update = update,
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
	events = {
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
		ACTIVE_PLAYER_SPECIALIZATION_CHANGED = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_SPECIALIZATION_CHANGED = function(s, _, unit)
			if unit == nil or unit == "player" then addon.DataHub:RequestUpdate(s) end
		end,
		PLAYER_TALENT_UPDATE = function(s) addon.DataHub:RequestUpdate(s) end,
		SPELLS_CHANGED = function(s) addon.DataHub:RequestUpdate(s) end,
		TRAIT_CONFIG_UPDATED = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_MOUNT_DISPLAY_CHANGED = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_UPDATE_RESTING = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	eventsUnit = {
		player = {
			UNIT_PET = true,
		},
		pet = {
			UNIT_FLAGS = true,
		},
	},
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
