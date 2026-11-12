local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local MythicPlus = addon.MythicPlus
local AuraCompat = addon.AuraCompat
if not (MythicPlus and AuraCompat) then return end

local _, _, _, interfaceVersion = GetBuildInfo()
if (tonumber(interfaceVersion) or 0) < 120100 then return end

local Backend = {}
MythicPlus.BloodlustAuraBackend = Backend

local BLOODLUST_BUFF_IDS = {
	2825, -- Bloodlust
	32182, -- Heroism
	80353, -- Time Warp
	90355, -- Ancient Hysteria
	146555, -- Drums of Rage
	160452, -- Netherwinds
	178207, -- Drums of Fury
	230935, -- Drums of the Mountain
	256740, -- Drums of the Maelstrom
	264667, -- Primal Rage
	309658, -- Drums of Deathly Ferocity
	381301, -- Feral Hide Drums
	390386, -- Fury of the Aspects
	441076, -- Timeless Drums
	444257, -- Thunderous Drums
	466904, -- Harrier's Cry
	1243972, -- Void-touched Drums
}
local BLOODLUST_LOCKOUT_IDS = {
	57723, -- Exhaustion
	57724, -- Sated
	80354, -- Temporal Displacement
	95809, -- Hunter Pet Insanity
	160455, -- Hunter Pet Fatigued
	264689, -- Hunter Pet Fatigued
	288293, -- Temporal Displacement
	390435, -- Exhaustion (declassified)
}
local ACTIVE_FILTER_STRING = "HELPFUL"
local ACTIVE_SLOT_KEY = "bloodlustBuff"
local FALLBACK_ICON = 136090
local DEFAULT_APPLY_SOUND = "Interface\\AddOns\\EnhanceQoL\\Sounds\\ChatIM\\Ping.ogg"
local DEFAULT_FADE_SOUND = "Interface\\AddOns\\EnhanceQoL\\Sounds\\ChatIM\\Ring.ogg"
local OVERLAY_FRAME_LEVEL_GAP = 16
local state = {}
local LSM = LibStub("LibSharedMedia-3.0", true)

local function createSlotHost()
	local host = CreateFrame("Frame", nil, UIParent)
	host:SetSize(1, 1)
	host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	return host
end

local function buildSpellFilter(spellIDs)
	local filter = {}
	for i = 1, #spellIDs do filter[spellIDs[i]] = true end
	return filter
end

local function getConfiguredIcon()
	local value = addon.db and tonumber(addon.db["mythicPlusBloodlustTrackerIcon"])
	return value and value > 0 and value or FALLBACK_ICON
end

local function createActiveInitializer(isLockout)
	local iconTexture = getConfiguredIcon()
	local iconShape = MythicPlus.functions.GetBloodlustIconShape and MythicPlus.functions.GetBloodlustIconShape() or "DEFAULT"
	local iconZoom = addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"] or 0
	local drawSwipe = not addon.db or addon.db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false
	local drawEdge = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true
	local drawBling = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true
	local showDuration = isLockout or (addon.db and addon.db["mythicPlusBloodlustTrackerShowActiveDuration"] == true)
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(addon.db and addon.db["mythicPlusBloodlustTrackerDurationTextProfile"])
		or nil
	local activeGlowEnabled = not isLockout and addon.db and addon.db["mythicPlusBloodlustTrackerGlowOnActive"] == true
	local trackerSize = tonumber(addon.db and addon.db["mythicPlusBloodlustButtonSize"]) or 60
	return function(button)
		button:SetSize(trackerSize, trackerSize)
		button:EnableMouse(false)
		if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
		if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints(button)
		background:SetColorTexture(0, 0, 0, 1)

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(button)
		icon:SetTexture(iconTexture)

		local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cooldown:SetAllPoints(button)
		cooldown:SetSwipeColor(0, 0, 0, 0.45)
		cooldown:SetDrawSwipe(drawSwipe)
		cooldown:SetDrawEdge(drawEdge)
		cooldown:SetDrawBling(drawBling)
		cooldown:SetHideCountdownNumbers(true)
		if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
		if cooldown.SetReverse then cooldown:SetReverse(not isLockout) end
		button:SetDurationCooldown(cooldown)
		if showDuration then
			local textOverlay = CreateFrame("Frame", nil, button)
			textOverlay:SetAllPoints(button)
			textOverlay:EnableMouse(false)
			textOverlay:SetFrameLevel(math.min(65535, (button:GetFrameLevel() or 0) + 6))
			local durationText = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			durationText:SetDrawLayer("OVERLAY", 7)
			if MythicPlus.functions.ApplyBloodlustCooldownTextStyle then
				MythicPlus.functions.ApplyBloodlustCooldownTextStyle(durationText, button, addon.db or {})
			else
				durationText:SetPoint("CENTER", button, "CENTER")
			end
			button:SetDurationText(durationText, durationTextOptions)
		end
		if activeGlowEnabled and AuraCompat.CreateRestrictedAuraGlow and MythicPlus.functions.BuildBloodlustGlowOptions then
			local style, options = MythicPlus.functions.BuildBloodlustGlowOptions(button)
			if style and options then
				options.style = style
				options.cooldown = nil
				options.frameLevelOffset = 5
				options.width = trackerSize
				options.height = trackerSize
				button._eqolActiveGlow = AuraCompat:CreateRestrictedAuraGlow(button, button, options)
			end
		end

		if MythicPlus.functions.ApplyTrackerIconShape then
			MythicPlus.functions.ApplyTrackerIconShape(button, icon, cooldown, iconShape, iconZoom)
			local mask = button._eqolMythicTrackerMask
			if mask and addon.IconShape and addon.IconShape.ApplyTextureMask then
				addon.IconShape.ApplyTextureMask(background, mask, "_eqolBloodlustActiveBackgroundMask")
			end
		end
	end
end

local function getStyleSignature()
	local db = addon.db or {}
	return table.concat({
		tostring(getConfiguredIcon()),
		tostring(db["mythicPlusBloodlustButtonSize"] or 60),
		tostring(db["mythicPlusBloodlustTrackerIconShape"] or "DEFAULT"),
		tostring(db["mythicPlusBloodlustTrackerIconZoom"] or 0),
		db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false and "1" or "0",
		db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true and "1" or "0",
		db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true and "1" or "0",
		db["mythicPlusBloodlustTrackerShowActiveDuration"] == true and "1" or "0",
		tostring(db["mythicPlusBloodlustTrackerCooldownFontFace"] or ""),
		tostring(db["mythicPlusBloodlustTrackerCooldownTextSize"] or ""),
		tostring(db["mythicPlusBloodlustTrackerCooldownTextOutline"] or ""),
		tostring(db["mythicPlusBloodlustTrackerCooldownTextOffsetX"] or ""),
		tostring(db["mythicPlusBloodlustTrackerCooldownTextOffsetY"] or ""),
		tostring(db["mythicPlusBloodlustTrackerDurationTextProfile"] or ""),
		db["mythicPlusBloodlustTrackerGlowOnActive"] == true and "1" or "0",
		tostring(db["mythicPlusBloodlustTrackerActiveGlowStyle"] or ""),
		tostring(db["mythicPlusBloodlustTrackerActiveGlowInset"] or ""),
		tostring(db["mythicPlusBloodlustTrackerActiveGlowPixelCount"] or ""),
		tostring(db["mythicPlusBloodlustTrackerActiveGlowPixelSpeed"] or ""),
		tostring(db["mythicPlusBloodlustTrackerActiveGlowPixelThickness"] or ""),
		db["mythicPlusBloodlustTrackerActiveGlowPixelBorder"] == true and "1" or "0",
		tostring(type(db["mythicPlusBloodlustTrackerActiveGlowColor"]) == "table" and (db["mythicPlusBloodlustTrackerActiveGlowColor"].r or db["mythicPlusBloodlustTrackerActiveGlowColor"][1]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerActiveGlowColor"]) == "table" and (db["mythicPlusBloodlustTrackerActiveGlowColor"].g or db["mythicPlusBloodlustTrackerActiveGlowColor"][2]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerActiveGlowColor"]) == "table" and (db["mythicPlusBloodlustTrackerActiveGlowColor"].b or db["mythicPlusBloodlustTrackerActiveGlowColor"][3]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerActiveGlowColor"]) == "table" and (db["mythicPlusBloodlustTrackerActiveGlowColor"].a or db["mythicPlusBloodlustTrackerActiveGlowColor"][4]) or ""),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].r or db["mythicPlusBloodlustTrackerCooldownTextColor"][1]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].g or db["mythicPlusBloodlustTrackerCooldownTextColor"][2]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].b or db["mythicPlusBloodlustTrackerCooldownTextColor"][3]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].a or db["mythicPlusBloodlustTrackerCooldownTextColor"][4]) or ""),
	}, "\031")
end

local function releaseInverseClip(discard)
	if state.clipHost and state.clipHost.textOverlay then state.clipHost.textOverlay:SetParent(state.clipHost) end
	if state.lockout and state.clipHost then state.lockout.container:SetParent(state.clipHost) end
	if state.readyClip then state.readyClip:Release() end
	if state.inverseClip then state.inverseClip:Release() end
	if discard then state.inverseClip, state.readyClip, state.clipHost = nil, nil, nil end
	if state.viewportFrame then state.viewportFrame:UnregisterAllEvents() end
end

local function syncInverseClip(host)
	if state.clipHost and state.clipHost ~= host then releaseInverseClip(true) end
	-- Bounds come only from the public viewport and host, never native aura geometry.
	local viewportScale, hostScale = UIParent:GetEffectiveScale(), host:GetEffectiveScale()
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	for _, value in ipairs({ viewportScale, hostScale, width, height }) do
		if AuraCompat:IsSecretValue(value) or type(value) ~= "number" or value <= 0 then releaseInverseClip(true) return false end
	end
	local options = {
		width = width * viewportScale / hostScale, height = height * viewportScale / hostScale,
		unit = "player", filterString = ACTIVE_FILTER_STRING,
		candidateFilters = { includeSpellIDs = buildSpellFilter(BLOODLUST_BUFF_IDS) },
		-- The host's base icon is outside the clip. Its artwork can overdraw
		-- clipped descendants at the same level, regardless of their own levels.
		frameLevel = host:GetFrameLevel() + 2, frameStrata = host:GetFrameStrata(), enabled = true,
	}
	local gate = state.inverseClip
	if gate then
		if not gate:Configure(options) then releaseInverseClip(true) return false end
	else
		gate = AuraCompat:CreateInverseAuraClip(host, UIParent, options)
		if not gate then return false end
		state.inverseClip, state.clipHost = gate, host
	end
	state.lockout.container:SetParent(gate.content)
	-- The buff gate hides all underlying visuals. The nested debuff gate
	-- additionally hides READY while the native lockout slot is present.
	options.filterString = "HARMFUL"
	options.candidateFilters = { includeSpellIDs = buildSpellFilter(BLOODLUST_LOCKOUT_IDS) }
	options.frameLevel = host:GetFrameLevel() + 4
	local readyGate = state.readyClip
	if readyGate then
		readyGate.clip:SetParent(host)
		if not readyGate:Configure(options) then releaseInverseClip(true) return false end
	else
		readyGate = AuraCompat:CreateInverseAuraClip(host, UIParent, options)
		if not readyGate then releaseInverseClip(true) return false end
		state.readyClip = readyGate
	end
	readyGate.clip:SetParent(gate.content)
	if host.textOverlay then host.textOverlay:SetParent(readyGate.content) end
	if not state.viewportFrame then
		state.viewportFrame = CreateFrame("Frame")
		state.viewportFrame:SetScript("OnEvent", function()
			if state.host then Backend:Attach(state.host) end
		end)
	end
	state.viewportFrame:RegisterEvent("UI_SCALE_CHANGED")
	state.viewportFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	return gate:Refresh() and readyGate:Refresh()
end

local function discardVisuals()
	releaseInverseClip(true)
	if state.active and state.active.container then
		state.active.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.active.container)
	end
	if state.lockout then
		state.lockout.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.lockout.container)
	end
	state.active = nil
	state.lockout = nil
	state.host = nil
	state.styleSignature = nil
end

local function createActiveLayer(isLockout)
	local container = AuraCompat:CreateAuraContainer(UIParent, nil, "CustomAuraContainerTemplate,DisableUntrustedLayoutScriptsTemplate")
	if not container then return nil end
	local slotHost = createSlotHost()
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit("player")
	local slot = AuraCompat:RegisterAuraSlot(container, isLockout and "bloodlustLockout" or ACTIVE_SLOT_KEY, isLockout and "HARMFUL" or ACTIVE_FILTER_STRING, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = buildSpellFilter(isLockout and BLOODLUST_LOCKOUT_IDS or BLOODLUST_BUFF_IDS) },
		initializeFrame = createActiveInitializer(isLockout),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	return { container = container, slot = slot, slotHost = slotHost }
end

local function canChangeAuraSounds()
	if InCombatLockdown and InCombatLockdown() then return false end
	return not (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret())
end

local function resolveSound(useCustomKey, soundSettingKey, fallbackSound)
	if addon.db and addon.db[useCustomKey] == true then
		local soundName = addon.db[soundSettingKey]
		if type(soundName) == "string" and soundName ~= "" and LSM and LSM.Fetch then
			local sound = LSM:Fetch("sound", soundName, true)
			if type(sound) == "string" and sound ~= "" then return sound, nil end
			if type(sound) == "number" and sound > 0 then return nil, sound end
		end
	end
	if type(fallbackSound) == "string" then return fallbackSound, nil end
	return nil, fallbackSound
end

local function requestSoundSync()
	state.soundSyncPending = true
	if not state.soundFrame then
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", function()
			if canChangeAuraSounds() then Backend:SyncSounds() end
		end)
		state.soundFrame = frame
	end
	state.soundFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	state.soundFrame:RegisterEvent("ENCOUNTER_END")
	state.soundFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	state.soundFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

local function clearSoundRegistrations()
	if not state.soundRegistrationIDs then return end
	for i = 1, #state.soundRegistrationIDs do pcall(C_UnitAuras.RemoveAuraSound, state.soundRegistrationIDs[i]) end
	state.soundRegistrationIDs = nil
end

local function addSoundRegistrations(trigger, soundFileName, soundFileID)
	if not (trigger and (soundFileName or soundFileID)) then return 0 end
	local registered = 0
	for i = 1, #BLOODLUST_LOCKOUT_IDS do
		local info = {
			unitToken = "player",
			spellID = BLOODLUST_LOCKOUT_IDS[i],
			outputChannel = "Master",
			soundFileName = soundFileName,
			soundFileID = soundFileID,
		}
		local ok, registrationID = pcall(C_UnitAuras.AddAuraSound, trigger, info)
		if ok and registrationID then
			state.soundRegistrationIDs = state.soundRegistrationIDs or {}
			state.soundRegistrationIDs[#state.soundRegistrationIDs + 1] = registrationID
			registered = registered + 1
		end
	end
	return registered
end

function Backend:IsSupported()
	return AuraCompat:ShouldUseAuraContainer() == true
end

function Backend:Ensure()
	local styleSignature = getStyleSignature()
	if state.active and state.lockout and state.styleSignature == styleSignature then return true end
	if state.active or state.lockout then discardVisuals() end
	local active = createActiveLayer()
	if not active then
		return false
	end
	state.active = active
	state.lockout = createActiveLayer(true)
	if not state.lockout then discardVisuals() return false end
	state.styleSignature = styleSignature
	AuraCompat:RefreshAuraContainer(active.container, "player")
	return true
end

function Backend:RefreshStyle()
	if not self:IsSupported() then return end
	local host = state.host or state.pendingHost
	if (state.active or state.lockout) and state.styleSignature ~= getStyleSignature() then discardVisuals() end
	if host then self:Attach(host) else self:Ensure() end
	self:SyncSounds()
end

-- Used only on encounter/challenge lifecycle changes, never for aura polling.
function Backend:RevalidateLockout()
	if not state.host then return end
	if state.lockout then AuraCompat:RefreshAuraContainer(state.lockout.container, "player") end
	if state.readyClip then state.readyClip:Refresh() end
end

function Backend:Attach(host)
	state.pendingHost = host
	if not host or not self:Ensure() then return false end
	if not syncInverseClip(host) then return false end
	local hostVisualLevel = host:GetFrameLevel() or 0
	if host.border then host.border:SetFrameLevel(hostVisualLevel + OVERLAY_FRAME_LEVEL_GAP * 2) end
	if host.textOverlay then host.textOverlay:SetFrameLevel(hostVisualLevel + OVERLAY_FRAME_LEVEL_GAP * 2 + 1) end
	local lockout = state.lockout
	lockout.container:ClearAllPoints()
	lockout.container:SetAllPoints(host)
	lockout.container:SetFrameStrata(host:GetFrameStrata())
	lockout.container:SetFrameLevel(math.min(65535, hostVisualLevel + 3))
	lockout.slotHost:ClearAllPoints()
	lockout.slotHost:SetAllPoints(host)
	lockout.container:SetAlpha(1)
	AuraCompat:RefreshAuraContainer(lockout.container, "player")
	if host.status then host.status:Show() end

	local active = state.active
	if active.container:GetParent() ~= host then
		active.container:SetParent(host)
		active.container:ClearAllPoints()
		active.container:SetAllPoints(host)
	end
	active.container:SetFrameStrata(host:GetFrameStrata())
	active.container:SetFrameLevel(math.min(65535, hostVisualLevel + OVERLAY_FRAME_LEVEL_GAP + 1))
	active.slotHost:ClearAllPoints()
	active.slotHost:SetAllPoints(host)
	active.container:SetAlpha(1)
	AuraCompat:RefreshAuraContainer(active.container, "player")
	state.host = host
	return true
end

function Backend:Detach()
	releaseInverseClip()
	state.pendingHost = nil
	state.host = nil
	if state.lockout then
		state.lockout.slotHost:ClearAllPoints()
		state.lockout.slotHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
		state.lockout.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.lockout.container)
	end
	if state.active then
		state.active.slotHost:ClearAllPoints()
		state.active.slotHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
		state.active.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.active.container)
	end
end

function Backend:IsLockoutActive()
	-- The optional encounter-start reminder needs a Lua decision once per
	-- encounter. The native display and removal sound never use this query.
	local getter = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
	if not getter then return true end
	for _, spellID in ipairs(BLOODLUST_LOCKOUT_IDS) do
		local aura = getter(spellID)
		if AuraCompat:IsSecretValue(aura) or aura then return true end
	end
	return false
end

function Backend:SyncSounds()
	if not (C_UnitAuras and C_UnitAuras.AddAuraSound and C_UnitAuras.RemoveAuraSound and Enum and Enum.UnitAuraSoundTrigger) then return end
	local enabled = addon.db and addon.db["mythicPlusBloodlustTrackerEnabled"] == true
	local classToken = addon.variables and addon.variables.unitClass
	local fadeClass = classToken == "SHAMAN" or classToken == "HUNTER" or classToken == "MAGE" or classToken == "EVOKER"
	local applyEnabled = enabled and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] == true
	local fadeEnabled = enabled and fadeClass and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffFade"] == true
	local applyFile, applyID = resolveSound("mythicPlusBloodlustTrackerUseCustomDebuffSound", "mythicPlusBloodlustTrackerDebuffSoundFile", DEFAULT_APPLY_SOUND)
	local fadeFile, fadeID = resolveSound("mythicPlusBloodlustTrackerUseCustomFadeSound", "mythicPlusBloodlustTrackerFadeSoundFile", DEFAULT_FADE_SOUND)
	local signature = table.concat({
		table.concat(BLOODLUST_LOCKOUT_IDS, ","),
		applyEnabled and "1" or "0",
		fadeEnabled and "1" or "0",
		tostring(applyFile or applyID or ""),
		tostring(fadeFile or fadeID or ""),
	}, "\031")
	if state.soundSignature == signature and not state.soundSyncPending then return end
	if not canChangeAuraSounds() then
		requestSoundSync()
		return
	end
	state.soundSyncPending = false
	clearSoundRegistrations()
	local expected = 0
	local registered = 0
	if applyEnabled then
		expected = expected + #BLOODLUST_LOCKOUT_IDS
		registered = registered + addSoundRegistrations(Enum.UnitAuraSoundTrigger.Added, applyFile, applyID)
	end
	if fadeEnabled then
		expected = expected + #BLOODLUST_LOCKOUT_IDS
		registered = registered + addSoundRegistrations(Enum.UnitAuraSoundTrigger.Removed, fadeFile, fadeID)
	end
	if registered == expected then
		state.soundSignature = signature
		if state.soundFrame then state.soundFrame:UnregisterAllEvents() end
	else
		state.soundSignature = nil
		requestSoundSync()
	end
end

function Backend:Sync()
	if not (addon.db and addon.db["mythicPlusBloodlustTrackerEnabled"] == true) then
		self:Detach()
		self:SyncSounds()
		return
	end
	if state.pendingHost then self:Attach(state.pendingHost) else self:Ensure() end
	self:SyncSounds()
end

Backend:Ensure()
Backend:SyncSounds()
