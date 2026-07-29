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
	160452, -- Netherwinds
	264667, -- Primal Rage
	390386, -- Fury of the Aspects
}
local FILTER_STRING = "HELPFUL"
local SLOT_KEY = "bloodlustBuff"
local FALLBACK_ICON = 136090
local state = {
	soundRegistrationIDs = {},
}
local driver

local function createSlotHost()
	local host = CreateFrame("Frame", nil, UIParent)
	host:SetSize(1, 1)
	host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	return host
end

local function buildSpellFilter()
	local filter = {}
	for i = 1, #BLOODLUST_BUFF_IDS do filter[BLOODLUST_BUFF_IDS[i]] = true end
	return filter
end

local function getConfiguredIcon()
	local value = addon.db and tonumber(addon.db["mythicPlusBloodlustTrackerIcon"])
	return value and value > 0 and value or FALLBACK_ICON
end

local function createInitializer()
	local iconTexture = getConfiguredIcon()
	local iconShape = MythicPlus.functions.GetBloodlustIconShape and MythicPlus.functions.GetBloodlustIconShape() or "DEFAULT"
	local iconZoom = addon.db and addon.db["mythicPlusBloodlustTrackerIconZoom"] or 0
	local drawSwipe = not addon.db or addon.db["mythicPlusBloodlustTrackerCooldownDrawSwipe"] ~= false
	local drawEdge = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawEdge"] == true
	local drawBling = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownDrawBling"] == true
	local showDuration = addon.db and addon.db["mythicPlusBloodlustTrackerShowActiveDuration"] == true
	local fontFace = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownFontFace"]
	local fontSize = tonumber(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextSize"]) or 16
	local fontOutline = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextOutline"] or "OUTLINE"
	local fontColor = addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextColor"] or { 1, 1, 1, 1 }
	local fontOffsetX = tonumber(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetX"]) or 0
	local fontOffsetY = tonumber(addon.db and addon.db["mythicPlusBloodlustTrackerCooldownTextOffsetY"]) or 0
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(addon.db and addon.db["mythicPlusBloodlustTrackerDurationTextProfile"])
		or nil
	return function(button)
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
		button:SetDurationCooldown(cooldown)
		if showDuration then
			local durationText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			durationText:SetPoint("CENTER", button, "CENTER", fontOffsetX, fontOffsetY)
			durationText:SetDrawLayer("OVERLAY", 7)
			local resolvedFont
			if fontFace == "__EQOL_GLOBAL_FONT__" and addon.functions and addon.functions.GetGlobalDefaultFontFace then
				resolvedFont = addon.functions.GetGlobalDefaultFontFace()
			elseif addon.functions and addon.functions.ResolveFontFace then
				resolvedFont = addon.functions.ResolveFontFace(fontFace)
			end
			resolvedFont = resolvedFont or (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
			if addon.functions and addon.functions.SetFontWithFallback then
				addon.functions.SetFontWithFallback(durationText, resolvedFont, fontSize, fontOutline, STANDARD_TEXT_FONT)
			else
				durationText:SetFont(resolvedFont, fontSize, fontOutline)
			end
			durationText:SetTextColor(fontColor.r or fontColor[1] or 1, fontColor.g or fontColor[2] or 1, fontColor.b or fontColor[3] or 1, fontColor.a or fontColor[4] or 1)
			if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(durationText, fontOutline, "OUTLINE") end
			button:SetDurationText(durationText, durationTextOptions)
		end

		if MythicPlus.functions.ApplyTrackerIconShape then
			MythicPlus.functions.ApplyTrackerIconShape(button, icon, cooldown, iconShape, iconZoom)
			local mask = button._eqolMythicTrackerMask
			if mask and addon.IconShape and addon.IconShape.ApplyTextureMask then
				addon.IconShape.ApplyTextureMask(background, mask, "_eqolBloodlustBackgroundMask")
			end
		end
	end
end

local function getStyleSignature()
	local db = addon.db or {}
	return table.concat({
		tostring(getConfiguredIcon()),
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
		tostring(addon.DurationText and addon.DurationText.version or 0),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].r or db["mythicPlusBloodlustTrackerCooldownTextColor"][1]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].g or db["mythicPlusBloodlustTrackerCooldownTextColor"][2]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].b or db["mythicPlusBloodlustTrackerCooldownTextColor"][3]) or ""),
		tostring(type(db["mythicPlusBloodlustTrackerCooldownTextColor"]) == "table" and (db["mythicPlusBloodlustTrackerCooldownTextColor"].a or db["mythicPlusBloodlustTrackerCooldownTextColor"][4]) or ""),
	}, "\031")
end

local function discardContainer()
	if state.container then
		state.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.container)
	end
	state.container = nil
	state.slot = nil
	state.slotHost = nil
	state.host = nil
	state.styleSignature = nil
end

local function canChangeAuraSoundRegistrations()
	if InCombatLockdown and InCombatLockdown() then return false end
	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return false end
	return true
end

local function requestSoundRegistrationRetry()
	if not driver then return end
	driver:RegisterEvent("PLAYER_REGEN_ENABLED")
	driver:RegisterEvent("ENCOUNTER_END")
	driver:RegisterEvent("PLAYER_ENTERING_WORLD")
	driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

local function clearSoundRegistrations()
	if #state.soundRegistrationIDs > 0 and not canChangeAuraSoundRegistrations() then
		state.pendingSoundClear = true
		requestSoundRegistrationRetry()
		return false
	end
	if C_UnitAuras and C_UnitAuras.RemoveAuraSound then
		for i = 1, #state.soundRegistrationIDs do C_UnitAuras.RemoveAuraSound(state.soundRegistrationIDs[i]) end
	end
	state.soundRegistrationIDs = {}
	state.soundSignature = nil
	state.pendingSoundClear = nil
	return true
end

local function resolveAppliedSound()
	if not (addon.db and addon.db["mythicPlusBloodlustTrackerSoundOnDebuffActive"] == true) then return nil, nil end
	if addon.db["mythicPlusBloodlustTrackerUseCustomDebuffSound"] ~= true then return nil, nil end
	local soundName = addon.db["mythicPlusBloodlustTrackerDebuffSoundFile"]
	if type(soundName) ~= "string" or soundName == "" then return nil, nil end
	local LSM = LibStub("LibSharedMedia-3.0", true)
	local value = LSM and LSM.Fetch and LSM:Fetch("sound", soundName, true) or nil
	if type(value) == "number" and value > 0 then return nil, value end
	if type(value) == "string" and value ~= "" then return value, nil end
	return nil, nil
end

function Backend:IsSupported()
	return AuraCompat:ShouldUseAuraContainer() == true
end

function Backend:SyncSounds()
	local soundFileName, soundFileID = resolveAppliedSound()
	local onlyInInstances = addon.db and addon.db["mythicPlusBloodlustTrackerOnlyInInstances"] == true
	local inAllowedScope = not onlyInInstances or IsInInstance()
	local identity = soundFileName or soundFileID
	local signature = inAllowedScope and identity and ((soundFileName and "file:" or "id:") .. tostring(identity)) or ""
	if state.soundSignature == signature and not state.pendingSoundClear then
		state.pendingSoundSync = nil
		return
	end
	if not canChangeAuraSoundRegistrations() then
		state.pendingSoundSync = true
		requestSoundRegistrationRetry()
		return
	end
	state.pendingSoundSync = nil
	if not clearSoundRegistrations() then return end
	state.soundSignature = signature
	if not (identity and inAllowedScope and C_UnitAuras and C_UnitAuras.AddAuraSound) then return end
	for i = 1, #BLOODLUST_BUFF_IDS do
		local info = {
			unitToken = "player",
			spellID = BLOODLUST_BUFF_IDS[i],
			outputChannel = "Master",
		}
		if soundFileName then info.soundFileName = soundFileName else info.soundFileID = soundFileID end
		-- This tracks the Bloodlust buff itself. Removed would mean that the
		-- short buff expired, not that the longer Bloodlust lockout is ready.
		local registrationID = C_UnitAuras.AddAuraSound(Enum.UnitAuraSoundTrigger.Added, info)
		if registrationID then state.soundRegistrationIDs[#state.soundRegistrationIDs + 1] = registrationID end
	end
end

function Backend:Ensure()
	local styleSignature = getStyleSignature()
	if state.container and state.styleSignature == styleSignature then return true end
	if state.container then discardContainer() end
	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return false end
	local slotHost = createSlotHost()
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit("player")
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, FILTER_STRING, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = buildSpellFilter() },
		initializeFrame = createInitializer(),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return false
	end
	state.container = container
	state.slot = slot
	state.slotHost = slotHost
	state.styleSignature = styleSignature
	AuraCompat:RefreshAuraContainer(container, "player")
	return true
end

function Backend:RefreshStyle()
	if not self:IsSupported() then return end
	local host = state.host or state.pendingHost
	if state.container and state.styleSignature ~= getStyleSignature() then discardContainer() end
	if host then self:Attach(host) else self:Ensure() end
end

function Backend:Attach(host)
	state.pendingHost = host
	if not host or not self:Ensure() then return false end
	if state.container:GetParent() ~= host then
		state.container:SetParent(host)
		state.container:ClearAllPoints()
		state.container:SetAllPoints(host)
	end
	state.container:SetFrameStrata(host:GetFrameStrata())
	-- Keep the native aura above the legacy host cooldown/text, but below the
	-- existing configured border at host + 5.
	state.container:SetFrameLevel(math.min(65535, (host:GetFrameLevel() or 0) + 2))
	state.slotHost:ClearAllPoints()
	state.slotHost:SetAllPoints(host)
	state.host = host
	state.container:SetAlpha(1)
	AuraCompat:RefreshAuraContainer(state.container, "player")
	self:SyncSounds()
	return true
end

function Backend:Detach()
	state.pendingHost = nil
	state.host = nil
	if not state.slotHost then return end
	state.slotHost:ClearAllPoints()
	state.slotHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	if state.container then
		state.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(state.container)
	end
end

function Backend:Refresh(host)
	self:SyncSounds()
	if host then return self:Attach(host) end
	if state.container then AuraCompat:RefreshAuraContainer(state.container, "player") end
	return state.container ~= nil
end

function Backend:Sync()
	if not (addon.db and addon.db["mythicPlusBloodlustTrackerEnabled"] == true) then
		self:Detach()
		clearSoundRegistrations()
		return
	end
	self:SyncSounds()
	if state.pendingHost then self:Attach(state.pendingHost) else self:Ensure() end
end

driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(self)
	if not canChangeAuraSoundRegistrations() then return end
	if state.pendingSoundClear then clearSoundRegistrations() end
	if state.pendingSoundSync then Backend:SyncSounds() end
	if addon.db and addon.db["mythicPlusBloodlustTrackerEnabled"] == true then
		Backend:Ensure()
		if state.pendingHost then Backend:Attach(state.pendingHost) end
	end
	self:UnregisterAllEvents()
end)

Backend:Ensure()
