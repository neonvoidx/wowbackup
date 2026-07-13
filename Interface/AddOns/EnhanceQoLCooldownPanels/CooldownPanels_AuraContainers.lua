local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local CooldownPanels = addon.Aura and addon.Aura.CooldownPanels
local AuraCompat = addon.AuraCompat
if not CooldownPanels or not AuraCompat then return end

local _, _, _, interfaceVersion = GetBuildInfo()
if (tonumber(interfaceVersion) or 0) < 120100 then return end

local Helper = CooldownPanels.helper
local CDMAuras = CooldownPanels.CDMAuras
if not Helper or not CDMAuras then return end
local Bars = CooldownPanels.Bars

local AuraContainers = {}
CooldownPanels.AuraContainers = AuraContainers

local CreateFrame = CreateFrame
local C_Spell = C_Spell
local C_UnitAuras = C_UnitAuras
local UIParent = UIParent
local LSM = LibStub("LibSharedMedia-3.0", true)
local ENTRY_TYPE = "CDM_AURA"
local SPELL_ENTRY_TYPE = "SPELL"
local STATE_KIND_ENTRY = "ENTRY"
local STATE_KIND_OVERLAY = "SPELL_OVERLAY"
local FILTER_STRING = "HELPFUL"
local TARGET_FILTER_STRING = "HARMFUL|PLAYER"
local SLOT_KEY = "trackedAura"
local states = {}
local auraAppliedSoundRegistrations = {}

local function getAuraSpellID(entry)
	return tonumber(entry and (entry.auraSpellID or entry.spellID))
end

local function resolveBarTexture(value)
	if value == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if LSM and LSM.Fetch and type(value) == "string" then
		local texture = LSM:Fetch("statusbar", value, true)
		if type(texture) == "string" and texture ~= "" then return texture end
	end
	if type(value) == "string" and (value:find("\\", 1, true) or value:find("/", 1, true)) then return value end
	return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function getSpellName(spellID)
	return spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or nil
end

local function getSpellTexture(spellID)
	return spellID and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID) or nil
end

local function getStateKey(kind, panelId, entryId)
	return tostring(kind) .. ":" .. tostring(panelId) .. ":" .. tostring(entryId)
end

local function getDisplayMode(entry)
	return entry and entry.displayMode == "BAR" and "BAR" or "BUTTON"
end

local function getColorComponents(color)
	if type(color) ~= "table" then return 1, 1, 1, 1 end
	return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
end

local function createBarTextOverlay(button)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	-- StatusBar is button + 1. Keep native aura text above it and the border,
	-- but below the addon-owned barFrame.textOverlay used for inactive hosts.
	overlay:SetFrameLevel((button:GetFrameLevel() or 0) + 3)
	button._eqolAuraBarTextOverlay = overlay
	return overlay
end

local function applyBarTextStyle(fontString, anchorFrame, entry, role)
	if not (fontString and anchorFrame and entry) then return end
	local defaults = Bars and Bars.DEFAULTS or {}
	local isValue = role == "VALUE"
	local isLabel = role == "LABEL"
	local prefix = isValue and "barValue" or isLabel and "barLabel" or "barStack"
	local anchor = entry[prefix .. "Anchor"] or defaults[prefix .. "Anchor"] or "AUTO"
	local orientation = entry.barOrientation or defaults.barOrientation or "HORIZONTAL"
	local resolvedAnchor = Bars and Bars.GetResolvedTextAnchor and Bars.GetResolvedTextAnchor(anchor, orientation, role) or (isValue and "RIGHT" or "LEFT")
	local point, relativePoint, justifyH
	if Bars and Bars.GetTextAnchorConfig then
		point, relativePoint, justifyH = Bars.GetTextAnchorConfig(anchor, orientation, role)
	else
		point, relativePoint, justifyH = resolvedAnchor, resolvedAnchor, resolvedAnchor
	end
	local offsetX = tonumber(entry[prefix .. "OffsetX"]) or tonumber(defaults[prefix .. "OffsetX"]) or 0
	local offsetY = tonumber(entry[prefix .. "OffsetY"]) or tonumber(defaults[prefix .. "OffsetY"]) or 0
	local inset = 4
	local justifyV = "MIDDLE"
	fontString:ClearAllPoints()
	if resolvedAnchor == "LEFT" then
		fontString:SetPoint("LEFT", anchorFrame, "LEFT", inset + offsetX, offsetY)
	elseif resolvedAnchor == "RIGHT" then
		fontString:SetPoint("RIGHT", anchorFrame, "RIGHT", -inset + offsetX, offsetY)
	elseif resolvedAnchor == "TOP" then
		justifyV = "TOP"
		fontString:SetPoint(point, anchorFrame, relativePoint, offsetX, offsetY - inset)
	elseif resolvedAnchor == "BOTTOM" then
		justifyV = "BOTTOM"
		fontString:SetPoint(point, anchorFrame, relativePoint, offsetX, offsetY + inset)
	else
		fontString:SetPoint(point, anchorFrame, relativePoint, offsetX, offsetY)
	end
	fontString:SetJustifyH(justifyH)
	if fontString.SetJustifyV then fontString:SetJustifyV(justifyV) end
	if fontString.SetWordWrap then fontString:SetWordWrap(false) end
	if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(false) end
	if fontString.SetMaxLines then fontString:SetMaxLines(1) end
	if fontString.SetDrawLayer then fontString:SetDrawLayer("OVERLAY", isValue and 7 or isLabel and 5 or 6) end

	local fallbackPath, fallbackSize, fallbackStyle
	if isValue and CooldownPanels.GetCooldownFontDefaults then
		fallbackPath, fallbackSize, fallbackStyle = CooldownPanels:GetCooldownFontDefaults(anchorFrame)
	elseif Helper.GetCountFontDefaults then
		fallbackPath, fallbackSize, fallbackStyle = Helper.GetCountFontDefaults(anchorFrame)
	end
	local fontPath = Helper.ResolveFontPath and Helper.ResolveFontPath(entry[prefix .. "Font"], fallbackPath) or fallbackPath
	local fontSize = tonumber(entry[prefix .. "Size"]) or tonumber(defaults[prefix .. "Size"]) or fallbackSize or 11
	local styleChoice = Helper.NormalizeFontStyleChoice and Helper.NormalizeFontStyleChoice(entry[prefix .. "Style"], fallbackStyle) or entry[prefix .. "Style"]
	local fontStyle = Helper.NormalizeFontStyle and Helper.NormalizeFontStyle(styleChoice, fallbackStyle) or styleChoice or ""
	if Helper.SetFont then Helper.SetFont(fontString, fontPath, fontSize, fontStyle, fallbackPath) end
	local r, g, b, a = getColorComponents(entry[prefix .. "Color"] or defaults[prefix .. "Color"])
	fontString:SetTextColor(r, g, b, a)
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, styleChoice, fallbackStyle) end
end

local function createInitializer(mode, entry, activeDesaturate)
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = entry.showCooldownText ~= false and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = entry.showStacks == true and (mode ~= "BAR" or entry.barShowStackText ~= false)
	local reverseFill = entry.barReverseFill == true
	return function(button)
		local textOverlay
		if mode == "BAR" then
			local statusBar = CreateFrame("StatusBar", nil, button)
			statusBar:SetAllPoints(button)
			statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
			statusBar:SetStatusBarTexture(resolveBarTexture(entry.barTexture))
			local color = entry.barColor
			if activeDesaturate then
				statusBar:SetStatusBarColor(0.45, 0.45, 0.45, 1)
			elseif type(color) == "table" then
				statusBar:SetStatusBarColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1)
			end
			button:SetDurationBar(statusBar, {
				direction = reverseFill and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
			})
			button._eqolDurationBar = statusBar
			if showLabel or showDuration or showStacks then textOverlay = createBarTextOverlay(button) end
			if showLabel then
				local label = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				applyBarTextStyle(label, textOverlay, entry, "LABEL")
				button:SetSpellName(label)
				button._eqolSpellName = label
			end
		else
			local icon = button:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints(button)
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			icon:SetDesaturated(activeDesaturate == true)
			button:SetIcon(icon)
			local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cooldown:SetAllPoints(button)
			cooldown:SetHideCountdownNumbers(not showDuration)
			if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
			button:SetDurationCooldown(cooldown)
			button._eqolIcon = icon
			button._eqolCooldown = cooldown
		end

		if showDuration and mode == "BAR" then
			local duration = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			applyBarTextStyle(duration, textOverlay, entry, "VALUE")
			button:SetDurationText(duration)
			button._eqolDurationText = duration
		end
		if showStacks then
			local countParent = mode == "BAR" and textOverlay or button
			local count = countParent:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
			if mode == "BAR" then
				applyBarTextStyle(count, countParent, entry, "STACK")
			else
				count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			end
			button:SetApplicationCount(count)
			button._eqolApplicationCount = count
		end
	end
end

local function resolveAuraAppliedSound(value)
	if type(value) == "number" and value > 0 then return nil, value end
	if type(value) ~= "string" or value == "" or value == "None" then return nil, nil end
	local numeric = tonumber(value)
	if numeric and numeric > 0 then return nil, numeric end
	if LSM and LSM.Fetch then
		local resolved = LSM:Fetch("sound", value, true)
		if type(resolved) == "number" and resolved > 0 then return nil, resolved end
		if type(resolved) == "string" and resolved ~= "" then return resolved, nil end
	end
	return value, nil
end

local function unregisterAuraAppliedSounds(state)
	if not state then return end
	if state.auraAppliedSoundKeys and C_UnitAuras and C_UnitAuras.RemoveAuraAppliedSound then
		for i = 1, #state.auraAppliedSoundKeys do
			local key = state.auraAppliedSoundKeys[i]
			local registration = auraAppliedSoundRegistrations[key]
			if registration then
				registration.refs = registration.refs - 1
				if registration.refs <= 0 then
					C_UnitAuras.RemoveAuraAppliedSound(registration.id)
					auraAppliedSoundRegistrations[key] = nil
				end
			end
		end
	end
	state.auraAppliedSoundKeys = nil
	state.auraAppliedSoundSignature = nil
end

local function registerAuraAppliedSounds(state, entry, spellIDs, unitToken)
	if not state then return end
	unitToken = unitToken == "target" and "target" or "player"
	local soundFileName, soundFileID = resolveAuraAppliedSound(entry.auraAppliedSoundFile)
	local soundIdentity = soundFileName or soundFileID
	local signature = entry.auraAppliedSound == true and soundIdentity
		and (unitToken .. ":" .. (soundFileName and "file:" or "id:") .. tostring(soundIdentity) .. ":" .. table.concat(spellIDs, ","))
		or ""
	if state.auraAppliedSoundSignature == signature then return end
	unregisterAuraAppliedSounds(state)
	state.auraAppliedSoundSignature = signature
	if not (entry.auraAppliedSound == true and soundIdentity and C_UnitAuras and C_UnitAuras.AddAuraAppliedSound) then return end
	local registrationKeys = {}
	for i = 1, #spellIDs do
		local key = table.concat({ unitToken, spellIDs[i], soundFileName and "file" or "id", tostring(soundIdentity), "Master" }, ":")
		local registration = auraAppliedSoundRegistrations[key]
		if registration then
			registration.refs = registration.refs + 1
			registrationKeys[#registrationKeys + 1] = key
		else
			local info = {
				unitToken = unitToken,
				spellID = spellIDs[i],
				outputChannel = "Master",
			}
			if soundFileName then
				info.soundFileName = soundFileName
			else
				info.soundFileID = soundFileID
			end
			local registrationID = C_UnitAuras.AddAuraAppliedSound(info)
			if registrationID then
				auraAppliedSoundRegistrations[key] = { id = registrationID, refs = 1 }
				registrationKeys[#registrationKeys + 1] = key
			end
		end
	end
	state.auraAppliedSoundKeys = registrationKeys
	if #registrationKeys == 0 then state.auraAppliedSoundSignature = nil end
end

local function createOverlayInitializer(mode, entry, layout)
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = entry.showCooldownText ~= false and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = mode == "BAR" and entry.showStacks == true and entry.barShowStackText ~= false
	local reverse = CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry)
	local color = CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local showGlow = CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true
	return function(button)
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints(button)
		background:SetColorTexture(0, 0, 0, 1)
		button._eqolOverlayBackground = background
		if mode == "BAR" then
			local statusBar = CreateFrame("StatusBar", nil, button)
			statusBar:SetAllPoints(button)
			statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
			statusBar:SetStatusBarTexture(resolveBarTexture(entry.barTexture))
			statusBar:SetStatusBarColor(r, g, b, a)
			button:SetDurationBar(statusBar, {
				direction = reverse and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
			})
			button._eqolOverlayDurationBar = statusBar
			local textOverlay
			if showLabel or showDuration or showStacks then textOverlay = createBarTextOverlay(button) end
			if showLabel then
				local label = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				applyBarTextStyle(label, textOverlay, entry, "LABEL")
				button:SetSpellName(label)
				button._eqolOverlaySpellName = label
			end
			if showDuration then
				local duration = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				applyBarTextStyle(duration, textOverlay, entry, "VALUE")
				button:SetDurationText(duration)
				button._eqolOverlayDurationText = duration
			end
			if showStacks then
				local count = textOverlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
				applyBarTextStyle(count, textOverlay, entry, "STACK")
				button:SetApplicationCount(count)
				button._eqolOverlayApplicationCount = count
			end
		else
			-- The native aura icon and an opaque background cover the complete
			-- spell host. This prevents transparent icon edges from revealing the
			-- cooldown icon underneath the active overlay.
			local icon = button:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints(button)
			button:SetIcon(icon)
			local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cooldown:SetAllPoints(button)
			cooldown:SetHideCountdownNumbers(not showDuration)
			if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
			if cooldown.SetReverse then cooldown:SetReverse(reverse) end
			if cooldown.SetSwipeColor then cooldown:SetSwipeColor(r, g, b, a) end
			button:SetDurationCooldown(cooldown)
			button._eqolOverlayIcon = icon
			button._eqolOverlayCooldown = cooldown
			if CooldownPanels.ApplyAuraOverlayIconStyle then CooldownPanels:ApplyAuraOverlayIconStyle(button, layout, background) end
			-- Shape setup may replace the swipe texture or color. Reapply the
			-- overlay-specific direction and tint after matching the host style.
			if cooldown.SetReverse then cooldown:SetReverse(reverse) end
			if cooldown.SetSwipeColor then cooldown:SetSwipeColor(r, g, b, a) end
		end

		if showGlow then
			local glow = CreateFrame("Frame", nil, button)
			glow:SetAllPoints(button)
			if addon.functions and addon.functions.SetSafeBorder then
				addon.functions.SetSafeBorder(glow, true, "Interface\\Buttons\\WHITE8x8", 2, r, g, b, a, {
					stateKey = "_eqolAuraOverlayGlow",
					defaultTexture = "Interface\\Buttons\\WHITE8x8",
					drawLayer = "OVERLAY",
				})
			end
			button._eqolOverlayGlow = glow
		end
	end
end

local function restoreOverlayHost(state, icon)
	if state and state.kind == STATE_KIND_OVERLAY then
		if state.mode == "BAR" then
			local barFrame = icon and icon._eqolBarsFrame
			if barFrame then barFrame:SetAlpha(1) end
		elseif icon then
			icon:SetAlpha(1)
		end
	end
end

local function disableState(state)
	if not state then return end
	unregisterAuraAppliedSounds(state)
	if state.kind == STATE_KIND_OVERLAY then
		local runtime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId]
		local icon = state.displayIcon or (runtime and runtime.entryToIcon and runtime.entryToIcon[state.entryId])
		restoreOverlayHost(state, icon)
	end
	if state.container then AuraCompat:DisableAuraContainer(state.container) end
	state.disabled = true
end

local function createState(panelId, entryId, entry, alwaysShowMode)
	local spellID = getAuraSpellID(entry)
	if not spellID then return nil end
	local mode = getDisplayMode(entry)
	local unitToken = entry.auraUnit == "target" and "target" or "player"
	local filterString = unitToken == "target" and (entry.auraFilter == "HARMFUL" and "HARMFUL" or TARGET_FILTER_STRING) or FILTER_STRING
	local showInactive = alwaysShowMode ~= "HIDE" and alwaysShowMode ~= "HIDE_DESATURATE_ACTIVE"
	local activeDesaturate = alwaysShowMode == "DESATURATE_ACTIVE" or alwaysShowMode == "HIDE_DESATURATE_ACTIVE"
	local color = entry.barColor
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local signature = table.concat({
		spellID,
		unitToken,
		filterString,
		mode,
		entry.showCooldownText == false and 0 or 1,
		entry.showStacks == true and 1 or 0,
		entry.barReverseFill == true and 1 or 0,
		showInactive and 1 or 0,
		activeDesaturate and 1 or 0,
		tostring(entry.barTexture or ""),
		tostring(type(color) == "table" and (color.r or color[1]) or ""),
		tostring(type(color) == "table" and (color.g or color[2]) or ""),
		tostring(type(color) == "table" and (color.b or color[3]) or ""),
		tostring(type(color) == "table" and (color.a or color[4]) or ""),
		entry.barShowLabel == false and 0 or 1,
		tostring(entry.barLabelAnchor or ""),
		tostring(entry.barLabelOffsetX or ""),
		tostring(entry.barLabelOffsetY or ""),
		tostring(entry.barLabelFont or ""),
		tostring(entry.barLabelSize or ""),
		tostring(entry.barLabelStyle or ""),
		tostring(type(labelColor) == "table" and (labelColor.r or labelColor[1]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.g or labelColor[2]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.b or labelColor[3]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.a or labelColor[4]) or ""),
		entry.barShowValueText == false and 0 or 1,
		tostring(entry.barValueAnchor or ""),
		tostring(entry.barValueOffsetX or ""),
		tostring(entry.barValueOffsetY or ""),
		tostring(entry.barValueFont or ""),
		tostring(entry.barValueSize or ""),
		tostring(entry.barValueStyle or ""),
		tostring(type(valueColor) == "table" and (valueColor.r or valueColor[1]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.g or valueColor[2]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.b or valueColor[3]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.a or valueColor[4]) or ""),
		entry.barShowStackText == false and 0 or 1,
		tostring(entry.barStackAnchor or ""),
		tostring(entry.barStackOffsetX or ""),
		tostring(entry.barStackOffsetY or ""),
		tostring(entry.barStackFont or ""),
		tostring(entry.barStackSize or ""),
		tostring(entry.barStackStyle or ""),
		tostring(type(stackColor) == "table" and (stackColor.r or stackColor[1]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.g or stackColor[2]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.b or stackColor[3]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.a or stackColor[4]) or ""),
		tostring(entry.barOrientation or ""),
	}, ":")
	local key = getStateKey(STATE_KIND_ENTRY, panelId, entryId)
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		registerAuraAppliedSounds(state, entry, { spellID }, unitToken)
		return state
	end
	if state then disableState(state) end

	-- The container must remain effectively visible so PTR4's
	-- RunWhenVisibleOnce dirty pass can assign a hidden-until-active AuraSlot.
	-- Alpha zero keeps the sensor invisible until it is attached for display.
	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return nil end
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit(unitToken)
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, filterString, {
		candidateFilters = { includeSpellIDs = { [spellID] = true } },
		initializeFrame = createInitializer(mode, entry, activeDesaturate),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	slot:ClearAllPoints()
	slot:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	state = {
		key = key,
		kind = STATE_KIND_ENTRY,
		panelId = panelId,
		entryId = entryId,
		spellID = spellID,
		unitToken = unitToken,
		filterString = filterString,
		mode = mode,
		signature = signature,
		container = container,
		slot = slot,
		showInactive = showInactive,
	}
	states[key] = state
	registerAuraAppliedSounds(state, entry, { spellID }, unitToken)
	AuraCompat:RefreshAuraContainer(container, unitToken)
	return state
end

local function getOverlaySpellIDs(entry, spellID)
	local candidates = CooldownPanels.GetEntryAuraOverlaySpellIDs and CooldownPanels:GetEntryAuraOverlaySpellIDs(entry, spellID) or { spellID }
	local includeSpellIDs = {}
	for i = 1, #candidates do includeSpellIDs[candidates[i]] = true end
	return candidates, includeSpellIDs
end

local function createOverlayState(panelId, entryId, entry, spellID, layout)
	spellID = tonumber(spellID or entry and entry.spellID)
	if not spellID then return nil end
	local candidates, includeSpellIDs = getOverlaySpellIDs(entry, spellID)
	if #candidates == 0 then return nil end
	local mode = getDisplayMode(entry)
	local unitToken = entry.cdmAuraOverlayTrackTarget == true and "target" or "player"
	local filterString
	if unitToken == "target" then
		filterString = entry.cdmAuraOverlayTargetPlayerOnly == false and "HARMFUL" or TARGET_FILTER_STRING
	else
		filterString = FILTER_STRING
	end
	local color = CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local signature = table.concat({
		table.concat(candidates, ","),
		unitToken,
		filterString,
		mode,
		entry.showCooldownText == false and 0 or 1,
		CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry) and 1 or 0,
		CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true and 1 or 0,
		tostring(entry.barTexture or ""),
		tostring(layout and layout.iconShape or ""),
		tostring(layout and layout.iconZoom or ""),
		layout and layout.iconBorderEnabled == true and 1 or 0,
		tostring(layout and layout.iconBorderTexture or ""),
		tostring(r),
		tostring(g),
		tostring(b),
		tostring(a),
		entry.barShowLabel == false and 0 or 1,
		tostring(entry.barLabelAnchor or ""),
		tostring(entry.barLabelOffsetX or ""),
		tostring(entry.barLabelOffsetY or ""),
		tostring(entry.barLabelFont or ""),
		tostring(entry.barLabelSize or ""),
		tostring(entry.barLabelStyle or ""),
		tostring(type(labelColor) == "table" and (labelColor.r or labelColor[1]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.g or labelColor[2]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.b or labelColor[3]) or ""),
		tostring(type(labelColor) == "table" and (labelColor.a or labelColor[4]) or ""),
		entry.barShowValueText == false and 0 or 1,
		tostring(entry.barValueAnchor or ""),
		tostring(entry.barValueOffsetX or ""),
		tostring(entry.barValueOffsetY or ""),
		tostring(entry.barValueFont or ""),
		tostring(entry.barValueSize or ""),
		tostring(entry.barValueStyle or ""),
		tostring(type(valueColor) == "table" and (valueColor.r or valueColor[1]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.g or valueColor[2]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.b or valueColor[3]) or ""),
		tostring(type(valueColor) == "table" and (valueColor.a or valueColor[4]) or ""),
		entry.showStacks == true and 1 or 0,
		entry.barShowStackText == false and 0 or 1,
		tostring(entry.barStackAnchor or ""),
		tostring(entry.barStackOffsetX or ""),
		tostring(entry.barStackOffsetY or ""),
		tostring(entry.barStackFont or ""),
		tostring(entry.barStackSize or ""),
		tostring(entry.barStackStyle or ""),
		tostring(type(stackColor) == "table" and (stackColor.r or stackColor[1]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.g or stackColor[2]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.b or stackColor[3]) or ""),
		tostring(type(stackColor) == "table" and (stackColor.a or stackColor[4]) or ""),
		tostring(entry.barOrientation or ""),
	}, ":")
	local key = getStateKey(STATE_KIND_OVERLAY, panelId, entryId)
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		registerAuraAppliedSounds(state, entry, candidates, unitToken)
		return state
	end
	if state then disableState(state) end

	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return nil end
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit(unitToken)
	-- AddAuraSlot owns exactly one AuraButton. Configured aura IDs and their
	-- aliases are candidate identities for that slot; they cannot exceed 1.
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, filterString, {
		candidateFilters = { includeSpellIDs = includeSpellIDs },
		initializeFrame = createOverlayInitializer(mode, entry, layout),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	slot:ClearAllPoints()
	slot:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	state = {
		key = key,
		kind = STATE_KIND_OVERLAY,
		panelId = panelId,
		entryId = entryId,
		spellID = spellID,
		unitToken = unitToken,
		filterString = filterString,
		mode = mode,
		signature = signature,
		container = container,
		slot = slot,
		maxCount = 1,
	}
	states[key] = state
	registerAuraAppliedSounds(state, entry, candidates, unitToken)
	AuraCompat:RefreshAuraContainer(container, unitToken)
	return state
end

function AuraContainers:BuildRuntimeData(panelId, entryId, entry, _, alwaysShowMode)
	local state = createState(panelId, entryId, entry, alwaysShowMode)
	if not state then return nil end
	return {
		-- PTR4 owns the secret shown state of the AuraButton. Keep the normal
		-- layout host allocated and never infer aura activity in addon Lua.
		active = false,
		show = true,
		buffName = entry.buffName or getSpellName(getAuraSpellID(entry)),
		iconTextureID = entry.iconTextureID or getSpellTexture(getAuraSpellID(entry)) or Helper.PREVIEW_ICON,
		stackCount = nil,
		cooldownStart = 0,
		cooldownDuration = 0,
		cooldownRate = 1,
		cooldownEnabled = true,
		durationActive = false,
		inactiveDesaturate = alwaysShowMode == "DESATURATE",
		activeDesaturate = false,
	}
end

function AuraContainers:SupportsSpellAuraOverlay(spellID)
	spellID = tonumber(spellID)
	return spellID ~= nil and spellID > 0
end

function AuraContainers:BuildSpellAuraOverlayData(panelId, entryId, entry, spellID, layout)
	local state = createOverlayState(panelId, entryId, entry, spellID, layout)
	if not state then return nil end
	return {
		-- The normal spell host remains allocated, while Blizzard alone owns the
		-- AuraButton's secret active visibility and duration.
		nativeAuraSlot = true,
		active = false,
		buffName = getSpellName(spellID),
	}
end

local function attachState(state)
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId]
	local panelFrame = runtime and runtime.frame
	local icon = runtime and runtime.entryToIcon and runtime.entryToIcon[state.entryId]
	local target = nil
	if icon and state.mode == "BAR" and icon._eqolBarsFrame then
		target = icon._eqolBarsFrame.fill
	elseif icon and state.mode == "BUTTON" then
		target = icon
	end
	if icon ~= state.displayIcon then
		restoreOverlayHost(state, state.displayIcon)
		state.displayIcon = icon
	end
	if target ~= state.displayTarget then
		state.slot:ClearAllPoints()
		if target then
			state.slot:SetAllPoints(target)
		else
			state.slot:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
		end
		state.displayTarget = target
	end
	-- Layout Edit uses the regular Cooldown Panels preview icon/bar as a dummy
	-- so entries remain visible and movable without requiring the tracked aura
	-- to be active. Keep the real AuraSlot sensor hidden until runtime resumes.
	if CooldownPanels:IsPanelLayoutEditActive(state.panelId) then
			if state.mode == "BAR" then
				local barFrame = icon and icon._eqolBarsFrame
			if barFrame then barFrame:SetAlpha(1) end
		elseif icon then
			icon:SetAlpha(1)
		end
		state.container:SetAlpha(0)
		return
	end
	if state.kind == STATE_KIND_OVERLAY then
		local panel = CooldownPanels:GetPanel(state.panelId)
		local entry = panel and panel.entries and panel.entries[state.entryId]
		local hostAlpha = entry and CooldownPanels:ResolveEntryActivationOverlayOnly(panel and panel.layout, entry) and 0 or 1
		if state.mode == "BAR" then
			local barFrame = icon and icon._eqolBarsFrame
			if barFrame then barFrame:SetAlpha(hostAlpha) end
		elseif icon then
			icon:SetAlpha(hostAlpha)
		end
	elseif state.mode == "BAR" then
		local barFrame = icon and icon._eqolBarsFrame
		if barFrame then barFrame:SetAlpha(state.showInactive and 1 or 0) end
	elseif icon then
		icon:SetAlpha(state.showInactive and 1 or 0)
	end
	local panelVisible = panelFrame and panelFrame.IsVisible and panelFrame:IsVisible() == true
	if panelVisible and target then
		if state.mode == "BAR" then
			local barFrame = icon and icon._eqolBarsFrame
			-- The native AuraButton supplies the secret duration fill, but the
			-- addon-owned border, icon and text overlays must remain above it.
			if state.container.SetFrameStrata and barFrame and barFrame.GetFrameStrata then state.container:SetFrameStrata(barFrame:GetFrameStrata()) end
			local fillLevel = barFrame and barFrame.fill and barFrame.fill.GetFrameLevel and barFrame.fill:GetFrameLevel() or nil
			-- AuraSlot and its StatusBar are child frames above the container.
			-- Put the container one level below the regular fill so the native bar
			-- lands above the fill but below border and text overlays.
			if state.container.SetFrameLevel and fillLevel then state.container:SetFrameLevel(fillLevel - 1) end
		else
			if state.container.SetFrameStrata and target.GetFrameStrata then state.container:SetFrameStrata(target:GetFrameStrata()) end
			-- Keep the AuraSlot above both the base icon and its cooldown swipe.
			-- The AuraButton reproduces the configured shape/border itself, while
			-- the host's overlay text and layout handle remain on higher layers.
			if state.container.SetFrameLevel then state.container:SetFrameLevel(target:GetFrameLevel() + 2) end
		end
		state.container:SetAlpha(1)
	else
		state.container:SetAlpha(0)
	end
end

local originalBuildRuntimeData = CDMAuras.BuildRuntimeData
local originalNormalizeEntry = CDMAuras.NormalizeEntry

function CDMAuras:NormalizeEntry(entry, defaults)
	if originalNormalizeEntry then originalNormalizeEntry(self, entry, defaults) end
	if not (entry and entry.type == ENTRY_TYPE) then return end
	local spellID = getAuraSpellID(entry)
	if not spellID then return end
	entry.auraSpellID = spellID
	entry.spellID = spellID
	-- PTR4 AuraSlots identify the aura by Spell ID. The old Cooldown Manager
	-- tracking ID is no longer runtime or persistence state on 12.1.
	entry.cooldownID = nil
	entry.auraBackend = "AURA_CONTAINER"
	if entry.auraUnit == "target" then
		entry.auraUnit = "target"
		entry.auraFilter = entry.auraFilter == "HARMFUL" and "HARMFUL" or TARGET_FILTER_STRING
	else
		entry.auraUnit = "player"
		entry.auraFilter = FILTER_STRING
	end
	entry.buffName = entry.buffName or getSpellName(spellID)
	entry.iconTextureID = entry.iconTextureID or getSpellTexture(spellID) or Helper.PREVIEW_ICON
end

function CDMAuras:BuildRuntimeData(panelId, entryId, entry, layout, alwaysShowMode)
	return AuraContainers:BuildRuntimeData(panelId, entryId, entry, layout, alwaysShowMode)
end

function CDMAuras:SupportsSpellAuraOverlay(spellID)
	return AuraContainers:SupportsSpellAuraOverlay(spellID)
end

function CDMAuras:BuildSpellAuraOverlayData(panelId, entryId, sourceEntry, spellID, entryLayout)
	return AuraContainers:BuildSpellAuraOverlayData(panelId, entryId, sourceEntry, spellID, entryLayout)
end

function CDMAuras:UpdateEventRegistration()
	if self.eventFrame then self.eventFrame:UnregisterAllEvents() end
	self.eventsRegistered = nil
	return false
end

function CDMAuras:CreateEntryData(idValue, overrides, defaults)
	local spellID = tonumber(type(idValue) == "table" and (idValue.auraSpellID or idValue.spellID) or idValue)
	if not spellID or not getSpellName(spellID) then return nil end
	local entryDefaults = (defaults and defaults.entry) or Helper.ENTRY_DEFAULTS or {}
	local entry = Helper.CopyTableShallow(entryDefaults)
	for key, value in pairs(Helper.ENTRY_DEFAULTS or {}) do if entry[key] == nil then entry[key] = value end end
	entry.type = ENTRY_TYPE
	entry.auraSpellID = spellID
	entry.spellID = spellID
	entry.auraBackend = "AURA_CONTAINER"
	entry.auraUnit = "player"
	entry.auraFilter = FILTER_STRING
	entry.buffName = getSpellName(spellID)
	entry.iconTextureID = getSpellTexture(spellID) or Helper.PREVIEW_ICON
	entry.sourceType = "ICON"
	entry.sourceViewer = nil
	entry.cdmAuraAlwaysShowUseGlobal = true
	entry.cdmAuraAlwaysShowMode = "HIDE"
	entry.alwaysShow = false
	entry.showCooldown = true
	entry.showCooldownText = true
	entry.showStacks = false
	entry.glowReady = false
	entry.pandemicGlow = false
	entry.soundReady = false
	if type(overrides) == "table" then for key, value in pairs(overrides) do entry[key] = value end end
	self:NormalizeEntry(entry)
	return entry
end

function CDMAuras:FindEntryByValue(panel, idValue)
	local spellID = tonumber(type(idValue) == "table" and (idValue.auraSpellID or idValue.spellID) or idValue)
	if not spellID or not panel or not panel.entries then return nil end
	for entryId, entry in pairs(panel.entries) do
		if entry and entry.type == ENTRY_TYPE and getAuraSpellID(entry) == spellID then return entryId, entry end
	end
	return nil
end

function CDMAuras:GetEntryIdText(entry)
	return entry and entry.type == ENTRY_TYPE and tostring(getAuraSpellID(entry) or "") or nil
end

function CDMAuras:EntryIsAvailableForPreview(entry)
	return entry and entry.type == ENTRY_TYPE and getAuraSpellID(entry) ~= nil
end

function CDMAuras:AddEntrySafe(panelId, idValue, overrides)
	local root = CooldownPanels:GetRoot()
	local entry = self:CreateEntryData(idValue, overrides, root and root.defaults)
	if not entry then return nil end
	if CooldownPanels:FindEntryByValue(panelId, ENTRY_TYPE, entry.auraSpellID) then return nil end
	return CooldownPanels:AddEntry(panelId, ENTRY_TYPE, entry.auraSpellID, entry)
end

local originalUpdateRuntimeIcons = CooldownPanels.UpdateRuntimeIcons
function CooldownPanels:UpdateRuntimeIcons(panelId)
	originalUpdateRuntimeIcons(self, panelId)
	for _, state in pairs(states) do
		if state.panelId == panelId and not state.disabled then attachState(state) end
	end
end

local driver = CreateFrame("Frame")
local elapsed = 0
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:SetScript("OnEvent", function(_, event)
	if event ~= "PLAYER_TARGET_CHANGED" then return end
	for _, state in pairs(states) do
		if not state.disabled and state.unitToken == "target" and state.container then
			AuraCompat:RefreshAuraContainer(state.container, "target")
		end
	end
end)
driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < 0.10 then return end
	elapsed = 0
	for _, state in pairs(states) do
		if not state.disabled and state.slot then
			local panel = CooldownPanels:GetPanel(state.panelId)
			local entry = panel and panel.entries and panel.entries[state.entryId]
			local runtime = CooldownPanels.runtime
			local panelRuntimeActive = runtime and runtime.enabledPanels and runtime.enabledPanels[state.panelId] == true
			local valid
			if state.kind == STATE_KIND_OVERLAY then
				valid = panelRuntimeActive
					and entry
					and entry.type == SPELL_ENTRY_TYPE
					and CooldownPanels:IsEntryCDMAuraOverlayEnabled(panel and panel.layout, entry, SPELL_ENTRY_TYPE)
			else
				valid = panelRuntimeActive and entry and entry.type == ENTRY_TYPE and getAuraSpellID(entry) == state.spellID
			end
			if not valid then
				disableState(state)
				state.container:SetAlpha(0)
				states[state.key] = nil
			else
				attachState(state)
			end
		end
	end
end)

AuraContainers.originalBuildRuntimeData = originalBuildRuntimeData
