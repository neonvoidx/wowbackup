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
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
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
local auraSoundRegistrations = {}
local SoundLifecycle = {
	pendingRemovals = {},
}
local AURA_SOUND_CONFIGS = {
	{
		trigger = Enum.UnitAuraSoundTrigger.Added,
		enabledField = "auraAppliedSound",
		soundField = "auraAppliedSoundFile",
	},
	{
		trigger = Enum.UnitAuraSoundTrigger.ApplicationsIncreased,
		enabledField = "auraApplicationsIncreasedSound",
		soundField = "auraApplicationsIncreasedSoundFile",
	},
	{
		trigger = Enum.UnitAuraSoundTrigger.Removed,
		enabledField = "auraRemovedSound",
		soundField = "auraRemovedSoundFile",
	},
}

local function createSlotHost()
	local host = CreateFrame("Frame", nil, UIParent)
	host:SetSize(1, 1)
	host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	return host
end

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

local function getDurationTextProfile(panelId, entry)
	local panel = CooldownPanels:GetPanel(panelId)
	if Bars and Bars.GetEntryDurationTextProfile then return Bars.GetEntryDurationTextProfile(entry, panel) end
	if entry and entry.barDurationTextProfile ~= nil and CooldownPanels.NormalizeDurationTextProfile then
		return CooldownPanels:NormalizeDurationTextProfile(entry.barDurationTextProfile, "MINIMAL")
	end
	if CooldownPanels.GetPanelDurationTextProfile then return CooldownPanels:GetPanelDurationTextProfile(panel) end
	return "MINIMAL"
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

local function applyAuraBarOrientation(statusBar, orientation)
	if not (statusBar and statusBar.SetOrientation) then return end
	statusBar:SetOrientation(orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL")
end

local function createAuraBarChrome(button, statusBar, entry)
	local defaults = Bars and Bars.DEFAULTS or {}
	local texture = resolveBarTexture(entry.barTexture or defaults.barTexture)
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints(button)
	background:SetTexture(texture)
	background:SetVertexColor(getColorComponents(entry.barBackgroundColor or defaults.barBackgroundColor))
	button._eqolAuraBarBackground = background

	statusBar:SetAllPoints(button)
	statusBar:SetStatusBarTexture(texture)
	applyAuraBarOrientation(statusBar, entry.barOrientation or defaults.barOrientation)

	local borderEnabled = entry.barBorderEnabled
	if borderEnabled == nil then borderEnabled = defaults.barBorderEnabled ~= false end
	local borderSize = math.max(0, tonumber(entry.barBorderSize) or tonumber(defaults.barBorderSize) or 1)
	local borderOffset = tonumber(entry.barBorderOffset) or tonumber(defaults.barBorderOffset) or 0
	local borderColor = entry.barBorderColor or defaults.barBorderColor
	local borderR, borderG, borderB, borderA = getColorComponents(borderColor)
	if borderEnabled and borderSize > 0 and addon.functions and addon.functions.SetSafeBorder then
		local border = CreateFrame("Frame", nil, button)
		border:SetPoint("TOPLEFT", button, "TOPLEFT", -borderOffset, borderOffset)
		border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", borderOffset, -borderOffset)
		border:SetFrameLevel((button:GetFrameLevel() or 0) + 2)
		addon.functions.SetSafeBorder(border, true, entry.barBorderTexture or defaults.barBorderTexture, borderSize, borderR, borderG, borderB, borderA, {
			stateKey = "_eqolAuraBarBorder",
			defaultTexture = "Interface\\Buttons\\WHITE8x8",
			mediaType = "border",
			drawLayer = "OVERLAY",
		})
		button._eqolAuraBarBorder = border
	end

	local showIcon = entry.barShowIcon
	if showIcon == nil then showIcon = defaults.barShowIcon ~= false end
	if showIcon then
		local iconSize = math.max(1, tonumber(entry.barIconSize) or tonumber(defaults.barIconSize) or 18)
		local iconOffsetX = tonumber(entry.barIconOffsetX) or tonumber(defaults.barIconOffsetX) or 0
		local iconOffsetY = tonumber(entry.barIconOffsetY) or tonumber(defaults.barIconOffsetY) or 0
		local iconPosition = entry.barIconPosition or defaults.barIconPosition or "LEFT"
		local iconHolder = CreateFrame("Frame", nil, button)
		iconHolder:SetSize(iconSize, iconSize)
		iconHolder:SetFrameLevel((button:GetFrameLevel() or 0) + 2)
		if iconPosition == "RIGHT" then
			iconHolder:SetPoint("LEFT", button, "RIGHT", 4 + iconOffsetX, iconOffsetY)
		elseif iconPosition == "TOP" then
			iconHolder:SetPoint("BOTTOM", button, "TOP", iconOffsetX, 4 + iconOffsetY)
		elseif iconPosition == "BOTTOM" then
			iconHolder:SetPoint("TOP", button, "BOTTOM", iconOffsetX, -4 + iconOffsetY)
		else
			iconHolder:SetPoint("RIGHT", button, "LEFT", -4 + iconOffsetX, iconOffsetY)
		end
		local icon = iconHolder:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(iconHolder)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button:SetIcon(icon)
		button._eqolAuraBarIcon = icon
		button._eqolAuraBarIconHolder = iconHolder
		if borderEnabled and borderSize > 0 and addon.functions and addon.functions.SetSafeBorder then
			local iconBorder = CreateFrame("Frame", nil, iconHolder)
			iconBorder:SetPoint("TOPLEFT", iconHolder, "TOPLEFT", -borderOffset, borderOffset)
			iconBorder:SetPoint("BOTTOMRIGHT", iconHolder, "BOTTOMRIGHT", borderOffset, -borderOffset)
			iconBorder:SetFrameLevel(iconHolder:GetFrameLevel() + 1)
			addon.functions.SetSafeBorder(iconBorder, true, entry.barBorderTexture or defaults.barBorderTexture, borderSize, borderR, borderG, borderB, borderA, {
				stateKey = "_eqolAuraBarIconBorder",
				defaultTexture = "Interface\\Buttons\\WHITE8x8",
				mediaType = "border",
				drawLayer = "OVERLAY",
			})
			button._eqolAuraBarIconBorder = iconBorder
		end
	end
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

local function resolveActiveGlowConfig(layout, entry)
	layout = layout or Helper.PANEL_LAYOUT_DEFAULTS
	local configured = entry and CooldownPanels:ResolveEntryGlowReady(layout, entry) == true
	local _, color, style, inset = CooldownPanels:ResolveEntryGlowStyle(layout, entry)
	style = Helper.NormalizeGlowStyle(style, Helper.PANEL_LAYOUT_DEFAULTS.readyGlowStyle)
	local pixelOptions = CooldownPanels:ResolveGlowPixelOptions(layout, entry) or {}
	local supported = style == "BLIZZARD"
		or style == "FLASH"
		or style == "MARCHING_ANTS"
		or style == "PIXEL"
		or style == "PULSING"
		or style == "SOLID"
		or style == "TINT_BORDER"
	local isBar = entry and entry.displayMode == "BAR"
	local borderEnabled
	local borderTexture
	local borderSize
	local borderOffset
	local borderIsBlizzard = false
	local iconShape = Helper.NormalizeIconShape(layout.iconShape, Helper.PANEL_LAYOUT_DEFAULTS.iconShape)
	if isBar then
		local defaults = Bars and Bars.DEFAULTS or {}
		borderEnabled = entry.barBorderEnabled
		if borderEnabled == nil then borderEnabled = defaults.barBorderEnabled ~= false end
		borderTexture = entry.barBorderTexture or defaults.barBorderTexture
		borderSize = math.max(0, tonumber(entry.barBorderSize) or tonumber(defaults.barBorderSize) or 1)
		borderEnabled = borderEnabled == true and borderSize > 0
		borderOffset = tonumber(entry.barBorderOffset) or tonumber(defaults.barBorderOffset) or 0
	else
		borderEnabled = layout.iconBorderEnabled == true
		borderTexture = layout.iconBorderTexture or Helper.PANEL_LAYOUT_DEFAULTS.iconBorderTexture
		borderSize = math.max(1, tonumber(layout.iconBorderSize) or tonumber(Helper.PANEL_LAYOUT_DEFAULTS.iconBorderSize) or 1)
		borderOffset = tonumber(layout.iconBorderOffset) or tonumber(Helper.PANEL_LAYOUT_DEFAULTS.iconBorderOffset) or 0
		local upperTexture = type(borderTexture) == "string" and string.upper(borderTexture) or ""
		local usesBlizzardBorder = upperTexture == "BLIZZARD" or upperTexture == "ORIGINAL_BLIZZARD"
		borderIsBlizzard = usesBlizzardBorder and iconShape == "DEFAULT"
		if usesBlizzardBorder and not borderIsBlizzard then borderEnabled = false end
	end
	return {
		configured = configured,
		enabled = configured and supported,
		color = color,
		style = style,
		inset = inset,
		shape = isBar and "DEFAULT" or iconShape,
		border = pixelOptions.border == true,
		count = pixelOptions.count,
		frequency = pixelOptions.frequency,
		thickness = pixelOptions.thickness,
		borderEnabled = borderEnabled == true,
		borderTexture = borderTexture,
		borderSize = borderSize,
		borderOffset = borderOffset,
		borderIsBlizzard = borderIsBlizzard,
	}
end

local function resolveNativeCooldownVisuals(layout, entry)
	local _, drawEdge, drawBling, drawSwipe = CooldownPanels:ResolveEntryCooldownVisuals(layout, entry)
	local color = CooldownPanels:GetCustomCooldownSwipeColor(layout, entry)
	if color then
		local r, g, b, a = getColorComponents(color)
		return drawEdge, drawBling, drawSwipe, r, g, b, a
	end
	return drawEdge, drawBling, drawSwipe, 0, 0, 0, 0.7
end

local function createInitializer(mode, entry, layout, durationTextProfile, activeDesaturate, activeGlow, glowWidth, glowHeight)
	local useApplicationBar = mode == "BAR" and entry.barMode == "STACKS"
	local maxApplications = Bars and Bars.NormalizeBarStackMax and Bars.NormalizeBarStackMax(entry.barStackMax, Bars.DEFAULTS and Bars.DEFAULTS.barStackMax or 10)
		or math.max(1, tonumber(entry.barStackMax) or 10)
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = not useApplicationBar and entry.showCooldownText ~= false and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = (entry.showStacks == true or useApplicationBar) and (mode ~= "BAR" or entry.barShowStackText ~= false)
	local reverseFill = entry.barReverseFill == true
	local cooldownDrawEdge, cooldownDrawBling, cooldownDrawSwipe, cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA =
		resolveNativeCooldownVisuals(layout, entry)
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(durationTextProfile)
		or nil
	return function(button)
		local showTooltips = layout and layout.showTooltips == true
		button:EnableMouse(showTooltips)
		if button.SetMouseClickEnabled then button:SetMouseClickEnabled(showTooltips) end
		if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(showTooltips) end
		if button.SetTooltipAnchorPoint then button:SetTooltipAnchorPoint("ANCHOR_RIGHT", 0, 0) end
		if AuraCompat.RegisterAuraButtonTooltipPolicy then AuraCompat:RegisterAuraButtonTooltipPolicy(button, false, showTooltips) end
		local textOverlay
		if mode == "BAR" then
			local statusBar = CreateFrame("StatusBar", nil, button)
			statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
			createAuraBarChrome(button, statusBar, entry)
			local color = entry.barColor
			if activeDesaturate then
				statusBar:SetStatusBarColor(0.45, 0.45, 0.45, 1)
			elseif type(color) == "table" then
				statusBar:SetStatusBarColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1)
			end
			if useApplicationBar then
				-- PTR6 writes the secret application count directly into this bar.
				-- barStackMax is public configuration; addon Lua never reads stacks.
				button:SetApplicationBar(statusBar, { maxApplications = maxApplications })
			else
				button:SetDurationBar(statusBar, {
					direction = reverseFill and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
				})
			end
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
			if cooldown.SetDrawEdge then cooldown:SetDrawEdge(cooldownDrawEdge) end
			if cooldown.SetDrawBling then cooldown:SetDrawBling(cooldownDrawBling) end
			if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(cooldownDrawSwipe) end
			if cooldown.SetSwipeColor then cooldown:SetSwipeColor(cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA) end
			if addon.functions and addon.functions.ApplyDurationTextProfileToCooldownFrame then
				addon.functions.ApplyDurationTextProfileToCooldownFrame(cooldown, durationTextProfile)
			end
			button:SetDurationCooldown(cooldown)
			button._eqolIcon = icon
			button._eqolCooldown = cooldown
		end

		if showDuration and mode == "BAR" then
			local duration = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			applyBarTextStyle(duration, textOverlay, entry, "VALUE")
			button:SetDurationText(duration, durationTextOptions)
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
		if activeGlow and activeGlow.enabled then
			local r, g, b, a = getColorComponents(activeGlow.color)
			button._eqolActiveGlow = AuraCompat:CreateRestrictedAuraGlow(button, button, {
				color = { r, g, b, a },
				style = activeGlow.style,
				shape = activeGlow.shape,
				border = activeGlow.border,
				count = activeGlow.count,
				frequency = activeGlow.frequency,
				inset = activeGlow.inset,
				thickness = activeGlow.thickness,
				borderEnabled = activeGlow.borderEnabled,
				borderTexture = activeGlow.borderTexture,
				borderSize = activeGlow.borderSize,
				borderOffset = activeGlow.borderOffset,
				borderIsBlizzard = activeGlow.borderIsBlizzard,
				frameLevelOffset = 2,
				width = glowWidth,
				height = glowHeight,
			})
		end
	end
end

local function resolveAuraSound(value)
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

function SoundLifecycle.CanChangeRegistrations()
	if InCombatLockdown and InCombatLockdown() then return false end
	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return false end
	return true
end

function SoundLifecycle.RequestRetry()
	if not SoundLifecycle.frame then
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", function()
			if SoundLifecycle.CanChangeRegistrations() then SoundLifecycle.Flush() end
		end)
		SoundLifecycle.frame = frame
	end
	SoundLifecycle.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	SoundLifecycle.frame:RegisterEvent("ENCOUNTER_END")
	SoundLifecycle.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	SoundLifecycle.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function SoundLifecycle.Unregister(state)
	if not state then return end
	if state.auraSoundKeys and C_UnitAuras and C_UnitAuras.RemoveAuraSound then
		for i = 1, #state.auraSoundKeys do
			local key = state.auraSoundKeys[i]
			local registration = auraSoundRegistrations[key]
			if registration then
				registration.refs = registration.refs - 1
				if registration.refs <= 0 then
					if SoundLifecycle.CanChangeRegistrations() then
						C_UnitAuras.RemoveAuraSound(registration.id)
					else
						SoundLifecycle.pendingRemovals[registration.id] = true
						SoundLifecycle.RequestRetry()
					end
					auraSoundRegistrations[key] = nil
				end
			end
		end
	end
	state.auraSoundKeys = nil
	state.auraSoundSignature = nil
end

function SoundLifecycle.Register(state, entry, spellIDs, unitToken)
	if not state then return end
	unitToken = unitToken == "target" and "target" or "player"
	local resolvedConfigs = {}
	local signatureParts = { unitToken, table.concat(spellIDs, ",") }
	for i = 1, #AURA_SOUND_CONFIGS do
		local config = AURA_SOUND_CONFIGS[i]
		local soundFileName, soundFileID = resolveAuraSound(entry[config.soundField])
		local soundIdentity = soundFileName or soundFileID
		if entry[config.enabledField] == true and soundIdentity then
			resolvedConfigs[#resolvedConfigs + 1] = {
				trigger = config.trigger,
				soundFileName = soundFileName,
				soundFileID = soundFileID,
				soundIdentity = soundIdentity,
			}
			signatureParts[#signatureParts + 1] = table.concat({ config.trigger, soundFileName and "file" or "id", tostring(soundIdentity) }, ":")
		end
	end
	local signature = #resolvedConfigs > 0 and table.concat(signatureParts, "|") or ""
	if state.auraSoundSignature == signature then
		state.pendingAuraSoundRequest = nil
		return
	end
	if not SoundLifecycle.CanChangeRegistrations() then
		local spellIDCopy = {}
		for i = 1, #spellIDs do spellIDCopy[i] = spellIDs[i] end
		state.pendingAuraSoundRequest = { entry = entry, spellIDs = spellIDCopy, unitToken = unitToken }
		SoundLifecycle.RequestRetry()
		return
	end
	state.pendingAuraSoundRequest = nil
	SoundLifecycle.Unregister(state)
	state.auraSoundSignature = signature
	if not (signature ~= "" and C_UnitAuras and C_UnitAuras.AddAuraSound) then return end
	local registrationKeys = {}
	for configIndex = 1, #resolvedConfigs do
		local config = resolvedConfigs[configIndex]
		for spellIndex = 1, #spellIDs do
			local key = table.concat({ config.trigger, unitToken, spellIDs[spellIndex], config.soundFileName and "file" or "id", tostring(config.soundIdentity), "Master" }, ":")
			local registration = auraSoundRegistrations[key]
			if registration then
				registration.refs = registration.refs + 1
				registrationKeys[#registrationKeys + 1] = key
			else
				local info = {
					unitToken = unitToken,
					spellID = spellIDs[spellIndex],
					outputChannel = "Master",
				}
				if config.soundFileName then
					info.soundFileName = config.soundFileName
				else
					info.soundFileID = config.soundFileID
				end
				local registrationID = C_UnitAuras.AddAuraSound(config.trigger, info)
				if registrationID then
					auraSoundRegistrations[key] = { id = registrationID, refs = 1 }
					registrationKeys[#registrationKeys + 1] = key
				end
			end
		end
	end
	state.auraSoundKeys = registrationKeys
	if #registrationKeys == 0 then state.auraSoundSignature = nil end
end

function SoundLifecycle.Flush()
	if not SoundLifecycle.CanChangeRegistrations() then return end
	if C_UnitAuras and C_UnitAuras.RemoveAuraSound then
		for registrationID in pairs(SoundLifecycle.pendingRemovals) do
			C_UnitAuras.RemoveAuraSound(registrationID)
			SoundLifecycle.pendingRemovals[registrationID] = nil
		end
	end
	for _, state in pairs(states) do
		local request = state.pendingAuraSoundRequest
		if request and not state.disabled then
			state.pendingAuraSoundRequest = nil
			SoundLifecycle.Register(state, request.entry, request.spellIDs, request.unitToken)
		end
	end
	if SoundLifecycle.frame then SoundLifecycle.frame:UnregisterAllEvents() end
end

local function createOverlayInitializer(mode, entry, layout, durationTextProfile, glowWidth, glowHeight)
	local useApplicationBar = mode == "BAR" and entry.barMode == "STACKS"
	local maxApplications = Bars and Bars.NormalizeBarStackMax and Bars.NormalizeBarStackMax(entry.barStackMax, Bars.DEFAULTS and Bars.DEFAULTS.barStackMax or 10)
		or math.max(1, tonumber(entry.barStackMax) or 10)
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = not useApplicationBar and entry.showCooldownText ~= false and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = mode == "BAR" and (entry.showStacks == true or useApplicationBar) and entry.barShowStackText ~= false
	local reverse = CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry)
	local color = CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local showGlow = CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true
	local _, resolvedGlowColor, _, resolvedGlowInset = CooldownPanels:ResolveEntryGlowStyle(layout, entry)
	local glowR, glowG, glowB, glowA = getColorComponents(resolvedGlowColor)
	local glowPixelOptions = CooldownPanels:ResolveGlowPixelOptions(layout, entry) or {}
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(durationTextProfile)
		or nil
	return function(button)
		local showTooltips = layout and layout.showTooltips == true
		button:EnableMouse(showTooltips)
		if button.SetMouseClickEnabled then button:SetMouseClickEnabled(showTooltips) end
		if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(showTooltips) end
		if button.SetTooltipAnchorPoint then button:SetTooltipAnchorPoint("ANCHOR_RIGHT", 0, 0) end
		if AuraCompat.RegisterAuraButtonTooltipPolicy then AuraCompat:RegisterAuraButtonTooltipPolicy(button, false, showTooltips) end
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints(button)
		background:SetColorTexture(0, 0, 0, 1)
		button._eqolOverlayBackground = background
		if mode == "BAR" then
			local statusBar = CreateFrame("StatusBar", nil, button)
			statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
			createAuraBarChrome(button, statusBar, entry)
			statusBar:SetStatusBarColor(r, g, b, a)
			if useApplicationBar then
				button:SetApplicationBar(statusBar, { maxApplications = maxApplications })
			else
				button:SetDurationBar(statusBar, {
					direction = reverse and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
				})
			end
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
				button:SetDurationText(duration, durationTextOptions)
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
			if addon.functions and addon.functions.ApplyDurationTextProfileToCooldownFrame then
				addon.functions.ApplyDurationTextProfileToCooldownFrame(cooldown, durationTextProfile)
			end
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
			local glow = AuraCompat:CreateRestrictedAuraGlow(button, button, {
				color = { glowR, glowG, glowB, glowA },
				count = glowPixelOptions.count,
				frequency = glowPixelOptions.frequency,
				inset = resolvedGlowInset,
				thickness = glowPixelOptions.thickness,
				frameLevelOffset = 15,
				width = glowWidth,
				height = glowHeight,
			})
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
	state.pendingAuraSoundRequest = nil
	SoundLifecycle.Unregister(state)
	if state.kind == STATE_KIND_OVERLAY then
		local runtime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId]
		local icon = state.displayIcon or (runtime and runtime.entryToIcon and runtime.entryToIcon[state.entryId])
		restoreOverlayHost(state, icon)
	end
	if state.container then AuraCompat:DisableAuraContainer(state.container) end
	state.disabled = true
end

local function createState(panelId, entryId, entry, layout, alwaysShowMode)
	local spellID = getAuraSpellID(entry)
	if not spellID then return nil end
	local mode = getDisplayMode(entry)
	local unitToken = entry.auraUnit == "target" and "target" or "player"
	local filterString = unitToken == "target" and (entry.auraFilter == "HARMFUL" and "HARMFUL" or TARGET_FILTER_STRING) or FILTER_STRING
	local showInactive = alwaysShowMode ~= "HIDE" and alwaysShowMode ~= "HIDE_DESATURATE_ACTIVE"
	local activeDesaturate = alwaysShowMode == "DESATURATE_ACTIVE" or alwaysShowMode == "HIDE_DESATURATE_ACTIVE"
	local durationTextProfile = getDurationTextProfile(panelId, entry)
	local color = entry.barColor
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local activeGlow = resolveActiveGlowConfig(layout, entry)
	local glowR, glowG, glowB, glowA = getColorComponents(activeGlow.color)
	local cooldownDrawEdge, cooldownDrawBling, cooldownDrawSwipe, cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA =
		resolveNativeCooldownVisuals(layout, entry)
	local signature = table.concat({
		spellID,
		unitToken,
		filterString,
		mode,
		tostring(durationTextProfile),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		layout and layout.showTooltips == true and 1 or 0,
		entry.showCooldownText == false and 0 or 1,
		cooldownDrawEdge and 1 or 0,
		cooldownDrawBling and 1 or 0,
		cooldownDrawSwipe and 1 or 0,
		tostring(cooldownSwipeR),
		tostring(cooldownSwipeG),
		tostring(cooldownSwipeB),
		tostring(cooldownSwipeA),
		entry.showStacks == true and 1 or 0,
		entry.barReverseFill == true and 1 or 0,
		showInactive and 1 or 0,
		activeDesaturate and 1 or 0,
		activeGlow.configured and 1 or 0,
		activeGlow.enabled and 1 or 0,
		tostring(activeGlow.style or ""),
		tostring(glowR),
		tostring(glowG),
		tostring(glowB),
		tostring(glowA),
		tostring(activeGlow.inset or ""),
		tostring(activeGlow.shape or ""),
		activeGlow.border and 1 or 0,
		tostring(activeGlow.count or ""),
		tostring(activeGlow.frequency or ""),
		tostring(activeGlow.thickness or ""),
		activeGlow.borderEnabled and 1 or 0,
		tostring(activeGlow.borderTexture or ""),
		tostring(activeGlow.borderSize or ""),
		tostring(activeGlow.borderOffset or ""),
		activeGlow.borderIsBlizzard and 1 or 0,
		tostring(entry.barTexture or ""),
		tostring(entry.barMode or ""),
		tostring(entry.barStackMax or ""),
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
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.r or entry.barBackgroundColor[1]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.g or entry.barBackgroundColor[2]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.b or entry.barBackgroundColor[3]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.a or entry.barBackgroundColor[4]) or ""),
		entry.barBorderEnabled == false and 0 or 1,
		tostring(entry.barBorderTexture or ""),
		tostring(entry.barBorderSize or ""),
		tostring(entry.barBorderOffset or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.r or entry.barBorderColor[1]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.g or entry.barBorderColor[2]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.b or entry.barBorderColor[3]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.a or entry.barBorderColor[4]) or ""),
		entry.barShowIcon == false and 0 or 1,
		tostring(entry.barIconSize or ""),
		tostring(entry.barIconPosition or ""),
		tostring(entry.barIconOffsetX or ""),
		tostring(entry.barIconOffsetY or ""),
	}, ":")
	local key = getStateKey(STATE_KIND_ENTRY, panelId, entryId)
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		state.entry = entry
		state.layout = layout
		state.durationTextProfile = durationTextProfile
		state.activeDesaturate = activeDesaturate
		state.activeGlow = activeGlow
		state.showInactive = showInactive
		SoundLifecycle.Register(state, entry, { spellID }, unitToken)
		return state
	end
	if state then disableState(state) end

	local container
	local slot
	local slotHost
	if not activeGlow.enabled then
		-- Glow-free slots do not snapshot target geometry. Keep their original
		-- immediate sensor setup, including synthetic other-aura states.
		container = AuraCompat:CreateAuraContainer(UIParent)
		if not container then return nil end
		slotHost = createSlotHost()
		container:SetAllPoints(UIParent)
		container:SetAlpha(0)
		container:SetUnit(unitToken)
		slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, filterString, {
			anchorFrame = slotHost,
			candidateFilters = { includeSpellIDs = { [spellID] = true } },
			initializeFrame = createInitializer(mode, entry, layout, durationTextProfile, activeDesaturate, activeGlow),
		})
		if not slot then
			AuraCompat:DisableAuraContainer(container)
			return nil
		end
	end
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
		entry = entry,
		layout = layout,
		durationTextProfile = durationTextProfile,
		activeDesaturate = activeDesaturate,
		activeGlow = activeGlow,
		container = container,
		slot = slot,
		slotHost = slotHost,
		showInactive = showInactive,
	}
	states[key] = state
	SoundLifecycle.Register(state, entry, { spellID }, unitToken)
	if container then AuraCompat:RefreshAuraContainer(container, unitToken) end
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
	local durationTextProfile = getDurationTextProfile(panelId, entry)
	local unitToken = entry.cdmAuraOverlayTrackTarget == true and "target" or "player"
	local filterString
	if unitToken == "target" then
		filterString = entry.cdmAuraOverlayTargetPlayerOnly == false and "HARMFUL" or TARGET_FILTER_STRING
	else
		filterString = FILTER_STRING
	end
	local color = CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local _, resolvedGlowColor, _, resolvedGlowInset = CooldownPanels:ResolveEntryGlowStyle(layout, entry)
	local glowR, glowG, glowB, glowA = getColorComponents(resolvedGlowColor)
	local glowPixelOptions = CooldownPanels:ResolveGlowPixelOptions(layout, entry) or {}
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local signature = table.concat({
		table.concat(candidates, ","),
		unitToken,
		filterString,
		mode,
		tostring(durationTextProfile),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		layout and layout.showTooltips == true and 1 or 0,
		entry.showCooldownText == false and 0 or 1,
		CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry) and 1 or 0,
		CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true and 1 or 0,
		tostring(glowR),
		tostring(glowG),
		tostring(glowB),
		tostring(glowA),
		tostring(resolvedGlowInset or ""),
		tostring(glowPixelOptions.count or ""),
		tostring(glowPixelOptions.frequency or ""),
		tostring(glowPixelOptions.thickness or ""),
		tostring(entry.barTexture or ""),
		tostring(entry.barMode or ""),
		tostring(entry.barStackMax or ""),
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
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.r or entry.barBackgroundColor[1]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.g or entry.barBackgroundColor[2]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.b or entry.barBackgroundColor[3]) or ""),
		tostring(entry.barBackgroundColor and (entry.barBackgroundColor.a or entry.barBackgroundColor[4]) or ""),
		entry.barBorderEnabled == false and 0 or 1,
		tostring(entry.barBorderTexture or ""),
		tostring(entry.barBorderSize or ""),
		tostring(entry.barBorderOffset or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.r or entry.barBorderColor[1]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.g or entry.barBorderColor[2]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.b or entry.barBorderColor[3]) or ""),
		tostring(entry.barBorderColor and (entry.barBorderColor.a or entry.barBorderColor[4]) or ""),
		entry.barShowIcon == false and 0 or 1,
		tostring(entry.barIconSize or ""),
		tostring(entry.barIconPosition or ""),
		tostring(entry.barIconOffsetX or ""),
		tostring(entry.barIconOffsetY or ""),
	}, ":")
	local key = getStateKey(STATE_KIND_OVERLAY, panelId, entryId)
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		state.entry = entry
		state.layout = layout
		state.durationTextProfile = durationTextProfile
		state.includeSpellIDs = includeSpellIDs
		SoundLifecycle.Register(state, entry, candidates, unitToken)
		return state
	end
	if state then disableState(state) end

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
		entry = entry,
		layout = layout,
		durationTextProfile = durationTextProfile,
		includeSpellIDs = includeSpellIDs,
		maxCount = 1,
	}
	states[key] = state
	SoundLifecycle.Register(state, entry, candidates, unitToken)
	return state
end

function AuraContainers:BuildRuntimeData(panelId, entryId, entry, layout, alwaysShowMode)
	local state = createState(panelId, entryId, entry, layout, alwaysShowMode)
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

local function initializeEntryState(state, target, width, height)
	if not (state and target and width and height) then return false end

	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return false end
	local slotHost = createSlotHost()
	slotHost:ClearAllPoints()
	slotHost:SetAllPoints(target)
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit(state.unitToken)
	-- AuraButton children become restricted immediately after initialization.
	-- Create them only after the real icon or bar geometry is known so the
	-- restricted glow snapshots the correct dimensions.
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, state.filterString, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = { [state.spellID] = true } },
		initializeFrame = createInitializer(
			state.mode,
			state.entry,
			state.layout,
			state.durationTextProfile,
			state.activeDesaturate,
			state.activeGlow,
			width,
			height
		),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return false
	end

	local oldContainer = state.container
	state.container = container
	state.slot = slot
	state.slotHost = slotHost
	state.geometryWidth = width
	state.geometryHeight = height
	if oldContainer then
		AuraCompat:DisableAuraContainer(oldContainer)
		oldContainer:SetAlpha(0)
	end
	AuraCompat:RefreshAuraContainer(container, state.unitToken)
	return true
end

local function initializeOverlayState(state, target, width, height)
	if not (state and target and width and height) then return false end

	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return false end
	local slotHost = createSlotHost()
	slotHost:ClearAllPoints()
	slotHost:SetAllPoints(target)
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit(state.unitToken)
	-- AddAuraSlot owns exactly one AuraButton. Configured aura IDs and their
	-- aliases are candidate identities for that slot; they cannot exceed 1.
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, state.filterString, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = state.includeSpellIDs },
		initializeFrame = createOverlayInitializer(state.mode, state.entry, state.layout, state.durationTextProfile, width, height),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return false
	end

	local oldContainer = state.container
	state.container = container
	state.slot = slot
	state.slotHost = slotHost
	state.geometryWidth = width
	state.geometryHeight = height
	if oldContainer then
		AuraCompat:DisableAuraContainer(oldContainer)
		oldContainer:SetAlpha(0)
	end
	AuraCompat:RefreshAuraContainer(container, state.unitToken)
	return true
end

local function attachState(state)
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId]
	local panelFrame = runtime and runtime.frame
	local layoutEditActive = CooldownPanels:IsPanelLayoutEditActive(state.panelId)
	local icon = runtime and runtime.entryToIcon and runtime.entryToIcon[state.entryId]
	local target = nil
	if icon and state.mode == "BAR" and icon._eqolBarsFrame then
		target = icon._eqolBarsFrame.body or icon._eqolBarsFrame.fill
	elseif icon and state.mode == "BUTTON" then
		target = icon
	end
	if icon ~= state.displayIcon then
		restoreOverlayHost(state, state.displayIcon)
		state.displayIcon = icon
	end
	if target and (state.kind == STATE_KIND_OVERLAY or not layoutEditActive) then
		local width = target.GetWidth and target:GetWidth() or nil
		local height = target.GetHeight and target:GetHeight() or nil
		if type(width) == "number" and width >= 1 and type(height) == "number" and height >= 1 then
			local initializeState = state.kind == STATE_KIND_ENTRY and initializeEntryState or initializeOverlayState
			local refreshGeometry = state.kind == STATE_KIND_OVERLAY or (state.activeGlow and state.activeGlow.enabled)
			local geometryChanged = state.geometryWidth ~= width or state.geometryHeight ~= height
			if not state.container then
				if initializeState(state, target, width, height) then
					state.pendingGeometryWidth = nil
					state.pendingGeometryHeight = nil
					state.pendingGeometryAt = nil
				end
			elseif refreshGeometry and geometryChanged then
				if state.pendingGeometryWidth ~= width or state.pendingGeometryHeight ~= height then
					state.pendingGeometryWidth = width
					state.pendingGeometryHeight = height
					state.pendingGeometryAt = GetTime and GetTime() or 0
				elseif not GetTime or (GetTime() - (state.pendingGeometryAt or 0)) >= 0.25 then
					if initializeState(state, target, width, height) then
						state.pendingGeometryWidth = nil
						state.pendingGeometryHeight = nil
						state.pendingGeometryAt = nil
					end
				end
			else
				state.pendingGeometryWidth = nil
				state.pendingGeometryHeight = nil
				state.pendingGeometryAt = nil
			end
		end
	end
	if state.slotHost and target ~= state.displayTarget then
		state.slotHost:ClearAllPoints()
		if target then
			state.slotHost:SetAllPoints(target)
		else
			state.slotHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
		end
		state.displayTarget = target
	end
	if not state.container then
		if state.kind == STATE_KIND_ENTRY then
			-- Style changes invalidate the restricted AuraButton, but its
			-- replacement is deferred until Layout Edit closes. Keep the
			-- public preview visible while that replacement is pending.
			local alpha = layoutEditActive and 1 or (state.showInactive and 1 or 0)
			if state.mode == "BAR" then
				local barFrame = icon and icon._eqolBarsFrame
				if barFrame then barFrame:SetAlpha(alpha) end
			elseif icon then
				icon:SetAlpha(alpha)
			end
		else
			restoreOverlayHost(state, icon)
		end
		return
	end
	-- Layout Edit uses the regular Cooldown Panels preview icon/bar as a dummy
	-- so entries remain visible and movable without requiring the tracked aura
	-- to be active. Keep the real AuraSlot sensor hidden until runtime resumes.
	if layoutEditActive then
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
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if not AuraContainers._deferredLoadHandled and AuraCompat._auraContainerLoadDeferred and AuraCompat:HasAuraContainerSupport() then
			AuraContainers._deferredLoadHandled = true
			CooldownPanels:RefreshAllPanels(true)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		for _, state in pairs(states) do
			if not state.disabled and state.unitToken == "target" and state.container then
				AuraCompat:RefreshAuraContainer(state.container, "target")
			end
		end
	end
end)
driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < 0.10 then return end
	elapsed = 0
	for _, state in pairs(states) do
		if not state.disabled and (state.slot or state.kind == STATE_KIND_OVERLAY or state.kind == STATE_KIND_ENTRY) then
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
				if state.container then state.container:SetAlpha(0) end
				states[state.key] = nil
			else
				attachState(state)
			end
		end
	end
end)

AuraContainers.originalBuildRuntimeData = originalBuildRuntimeData
