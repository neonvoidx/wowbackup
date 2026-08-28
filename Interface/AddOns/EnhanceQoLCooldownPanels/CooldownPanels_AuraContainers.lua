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

local Helper = CooldownPanels.helper
local CDMAuras = CooldownPanels.CDMAuras
if not Helper or not CDMAuras then return end
local Bars = CooldownPanels.Bars

local AuraContainers = {}
CooldownPanels.AuraContainers = AuraContainers
AuraContainers.dynamicGroups = {}
AuraContainers.dynamicGroupsByPanel = {}
AuraContainers.GRID_GROUP_ID = "__GRID__"
AuraContainers.buildSerial = 0
AuraContainers.panelBuildTokens = {}
AuraContainers.panelBuildDepths = {}
AuraContainers.pendingPanelSyncs = {}
AuraContainers.geometryStatesByTarget = setmetatable({}, { __mode = "k" })
AuraContainers.geometryHookedTargets = setmetatable({}, { __mode = "k" })
AuraContainers.visibilityHookedFrames = setmetatable({}, { __mode = "k" })
AuraContainers.PARTY_UNIT_TOKENS = { "party1", "party2", "party3", "party4" }
AuraContainers.PARTY_PLAYER_UNIT_TOKENS = { "player", "party1", "party2", "party3", "party4" }
AuraContainers.GROUP_FILTER_STRING = "HELPFUL|PLAYER"

function AuraContainers:GetAuraGroupUnitTokens(mode)
	mode = Helper.NormalizeAuraUnit(mode)
	if mode == "party" then return self.PARTY_UNIT_TOKENS end
	if mode == "party_player" then return self.PARTY_PLAYER_UNIT_TOKENS end
	local role = mode == "tank" and "TANK" or mode == "healer" and "HEALER" or nil
	if not role then return nil end
	local matches = {}
	for _, unitToken in ipairs(self.PARTY_PLAYER_UNIT_TOKENS) do
		local assignedRole = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unitToken) or nil
		if not AuraCompat:IsSecretValue(assignedRole) and assignedRole == role then matches[#matches + 1] = unitToken end
	end
	return matches
end

function AuraContainers:IsTargetHarmfulIdentityTracked(unitToken, filterString)
	return unitToken == "target" and (filterString == "HARMFUL" or filterString == "HARMFUL|PLAYER")
end

function AuraContainers:IsTrackedAuraSuppressed(unitToken, filterString)
	-- Harmful identity filters are intentionally unavailable for friendly units.
	-- Ignore temporary immune or uninteractable states when checking that relationship.
	return self:IsTargetHarmfulIdentityTracked(unitToken, filterString) and UnitCanAssist("player", unitToken, true, true) == true
end

local CreateFrame = CreateFrame
local C_Spell = C_Spell
local C_UnitAuras = C_UnitAuras
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local LSM = LibStub("LibSharedMedia-3.0", true)
local ENTRY_TYPE = "CDM_AURA"
local SPELL_ENTRY_TYPE = "SPELL"
local SLOT_ENTRY_TYPE = "SLOT"
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
	-- AuraSlot buttons make their layout dependency forbidden. Opt the host in
	-- at creation so it can safely own that relationship without propagating it
	-- into the regular Cooldown Panel icon or bar.
	local host = CreateFrame("Frame", nil, UIParent, "DisableUntrustedLayoutScriptsTemplate")
	host:SetSize(1, 1)
	host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	return host
end

local function getAuraSpellID(entry)
	local auraPresets = CooldownPanels.AuraPresets
	local presetSpellID = auraPresets and auraPresets.GetEntryDefinition and auraPresets:GetEntryDefinition(entry)
	presetSpellID = presetSpellID and presetSpellID.primarySpellID or nil
	return tonumber(presetSpellID or entry and (entry.auraSpellID or entry.spellID))
end

local function getAuraSpellIDs(entry)
	local auraPresets = CooldownPanels.AuraPresets
	local presetDefinition = auraPresets and auraPresets.GetEntryDefinition and auraPresets:GetEntryDefinition(entry) or nil
	local presetSpellIDs, presetIncludeSpellIDs, presetSignature
	if auraPresets and auraPresets.GetEntrySpellData then
		presetSpellIDs, presetIncludeSpellIDs, presetSignature = auraPresets:GetEntrySpellData(entry)
	elseif auraPresets and auraPresets.GetEntrySpellIDs then
		presetSpellIDs = auraPresets:GetEntrySpellIDs(entry)
	end
	if presetDefinition and #(entry and entry.cdmAuraOverlaySpellIDs or {}) == 0 and presetIncludeSpellIDs then
		return presetSpellIDs, presetIncludeSpellIDs, presetSignature
	end
	local spellIDs = {}
	local includeSpellIDs = {}
	local function addSpellID(value)
		local spellID = tonumber(value)
		if spellID and spellID > 0 and not includeSpellIDs[spellID] then
			includeSpellIDs[spellID] = true
			spellIDs[#spellIDs + 1] = spellID
		end
	end
	for i = 1, #(presetSpellIDs or {}) do
		addSpellID(presetSpellIDs[i])
	end
	-- A custom tracked aura always keeps its primary identity. Preset candidates
	-- are filtered globally, so their primary ID must not be added a second time.
	if not presetDefinition then addSpellID(getAuraSpellID(entry)) end
	for i = 1, #(entry and entry.cdmAuraOverlaySpellIDs or {}) do
		local overlaySpellID = entry.cdmAuraOverlaySpellIDs[i]
		local overlayEnabled = not presetDefinition or not auraPresets.IsSpellIDEnabled
		if not overlayEnabled then overlayEnabled = auraPresets:IsSpellIDEnabled(presetDefinition.key, overlaySpellID) end
		if overlayEnabled then addSpellID(overlaySpellID) end
	end
	return spellIDs, includeSpellIDs, table.concat(spellIDs, ",")
end

local function getAuraMaxFrameCount(entry)
	local auraPresets = CooldownPanels.AuraPresets
	local maxFrameCount = auraPresets and auraPresets.GetEntryMaxFrameCount and auraPresets:GetEntryMaxFrameCount(entry) or 1
	return math.max(1, math.floor(tonumber(maxFrameCount) or 1))
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

local function getCooldownTextStyleSignature(layout, entry)
	local fontPath, fontSize, fontStyleChoice, fontStyle, color, offsetX, offsetY = CooldownPanels:ResolveEntryCooldownTextStyle(layout, entry)
	local r, g, b, a = getColorComponents(color)
	return table.concat({
		tostring(fontPath or ""),
		tostring(fontSize or ""),
		tostring(fontStyleChoice or ""),
		tostring(fontStyle or ""),
		tostring(r),
		tostring(g),
		tostring(b),
		tostring(a),
		tostring(offsetX or ""),
		tostring(offsetY or ""),
	}, ",")
end

local function getStackTextStyleSignature(layout, entry)
	local fontPath, fontSize, fontStyleChoice, fontStyle, color, anchor, offsetX, offsetY = CooldownPanels:ResolveEntryStackTextStyle(layout, entry)
	local r, g, b, a = getColorComponents(color)
	return table.concat({
		tostring(fontPath or ""),
		tostring(fontSize or ""),
		tostring(fontStyleChoice or ""),
		tostring(fontStyle or ""),
		tostring(r),
		tostring(g),
		tostring(b),
		tostring(a),
		tostring(anchor or ""),
		tostring(offsetX or ""),
		tostring(offsetY or ""),
	}, ",")
end

local function getStaticTextStyleSignature(layout, entry)
	if not (entry and type(entry.staticText) == "string" and entry.staticText ~= "") then return "" end
	local fontPath, fontSize, fontStyleChoice, fontStyle, color, anchor, offsetX, offsetY = CooldownPanels:ResolveEntryStaticTextStyle(layout, entry)
	local r, g, b, a = getColorComponents(color)
	return table.concat({
		entry.staticText,
		entry.staticTextShowOnCooldown == true and 1 or 0,
		tostring(fontPath or ""),
		tostring(fontSize or ""),
		tostring(fontStyleChoice or ""),
		tostring(fontStyle or ""),
		tostring(r),
		tostring(g),
		tostring(b),
		tostring(a),
		tostring(anchor or ""),
		tostring(offsetX or ""),
		tostring(offsetY or ""),
	}, ",")
end

local function applyNativeStackTextStyle(count, anchorFrame, layout, entry)
	if not (count and anchorFrame) then return end
	local fallbackFontPath, fallbackFontSize, fallbackFontStyle = count:GetFont()
	local fontPath, fontSize, fontStyleChoice, fontStyle, color, anchor, offsetX, offsetY =
		CooldownPanels:ResolveEntryStackTextStyle(layout, entry, fallbackFontPath, fallbackFontSize, fallbackFontStyle)
	count:ClearAllPoints()
	count:SetPoint(anchor, anchorFrame, anchor, offsetX, offsetY)
	if Helper.SetFont then
		Helper.SetFont(count, fontPath, fontSize, fontStyle, fallbackFontPath)
	else
		count:SetFont(fontPath, fontSize, fontStyle)
	end
	if count.SetDrawLayer then count:SetDrawLayer("OVERLAY", 7) end
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(count, fontStyleChoice, fallbackFontStyle) end
	count:SetTextColor(getColorComponents(color))
end

local function resolveBarStackMax(entry)
	if Bars and Bars.ResolveBarStackMax then return Bars.ResolveBarStackMax(entry) end
	if Bars and Bars.NormalizeBarStackMax then
		return Bars.NormalizeBarStackMax(entry and entry.barStackMax, Bars.DEFAULTS and Bars.DEFAULTS.barStackMax or 10)
	end
	return math.max(1, tonumber(entry and entry.barStackMax) or 10)
end

local function createBarTextOverlay(button, frameLevelOffset)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	-- Keep text above the cooldown swipe, custom border, and active glow.
	overlay:SetFrameLevel((button:GetFrameLevel() or 0) + (frameLevelOffset or 6))
	button._eqolAuraBarTextOverlay = overlay
	return overlay
end

local function usesNativeStackDividers(mode, entry)
	return mode == "BAR" and entry and entry.barMode == "STACKS" and entry.barStacksSegmented == true
end

local function createNativeAuraBarDividers(button, entry, bodyWidth, bodyHeight, overlayLevelBoost)
	if not (button and entry and Bars and Bars.LayoutStackDividers) then return end
	if type(bodyWidth) ~= "number" or bodyWidth < 1 or type(bodyHeight) ~= "number" or bodyHeight < 1 then return end
	local defaults = Bars.DEFAULTS or {}
	local stackMax = resolveBarStackMax(entry)
	if stackMax <= 1 then return end

	local dividerOverlay = CreateFrame("Frame", nil, button)
	dividerOverlay:SetAllPoints(button)
	dividerOverlay:EnableMouse(false)
	dividerOverlay:SetFrameLevel((button:GetFrameLevel() or 0) + 2 + (overlayLevelBoost or 0))
	dividerOverlay.dividerOverlay = dividerOverlay
	dividerOverlay.stackDividers = {}
	button._eqolAuraBarDividerOverlay = dividerOverlay

	local effectiveScale = button.GetEffectiveScale and button:GetEffectiveScale() or 1
	Bars.LayoutStackDividers(
		dividerOverlay,
		entry.barOrientation or defaults.barOrientation or "HORIZONTAL",
		stackMax,
		bodyWidth,
		bodyHeight,
		entry.barStackDividerColor or defaults.barStackDividerColor,
		effectiveScale,
		entry.barStackDividerThickness or defaults.barStackDividerThickness
	)
end

local function applyAuraBarOrientation(statusBar, orientation)
	if not (statusBar and statusBar.SetOrientation) then return end
	statusBar:SetOrientation(orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL")
end

function AuraContainers:ApplyStackBarDirection(statusBar, entry)
	if not statusBar then return end
	local defaults = Bars and Bars.DEFAULTS or {}
	applyAuraBarOrientation(statusBar, entry and entry.barOrientation or defaults.barOrientation)
	if statusBar.SetReverseFill then statusBar:SetReverseFill(entry and entry.barReverseFill == true) end
end

function AuraContainers:GetStackThresholds(entry, activeDesaturate)
	if activeDesaturate == true or not (Bars and Bars.GetStackThresholds) then return {} end
	return Bars.GetStackThresholds(entry, resolveBarStackMax(entry))
end

function AuraContainers:GetStackThresholdSignature(entry, activeDesaturate)
	local parts = {}
	for _, threshold in ipairs(self:GetStackThresholds(entry, activeDesaturate)) do
		local color = threshold.color or {}
		parts[#parts + 1] = table.concat({
			threshold.index or 0,
			threshold.value or 0,
			color.r or color[1] or 1,
			color.g or color[2] or 1,
			color.b or color[3] or 1,
			color.a or color[4] or 1,
		}, ",")
	end
	return table.concat(parts, ";")
end

function AuraContainers:CreateStackThresholdMask(button)
	local mask = button:CreateMaskTexture(nil, "BACKGROUND")
	mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
	if mask.SetSnapToPixelGrid then mask:SetSnapToPixelGrid(false) end
	if mask.SetTexelSnappingBias then mask:SetTexelSnappingBias(0) end
	return mask
end

function AuraContainers:ApplyStackThresholdGeometry(button, statusBar, mask, entry, threshold, maximum, kind, bodyWidth, bodyHeight)
	local defaults = Bars and Bars.DEFAULTS or {}
	local vertical = (entry and entry.barOrientation or defaults.barOrientation) == "VERTICAL"
	local reverse = entry and entry.barReverseFill == true
	local size = vertical and bodyHeight or bodyWidth
	if type(size) ~= "number" or size < 1 then size = 1 end
	local scale = button.GetEffectiveScale and button:GetEffectiveScale() or 1
	local _, physicalHeight = GetPhysicalScreenSize()
	local onePixel = physicalHeight and physicalHeight > 0 and scale and scale > 0 and (768 / physicalHeight) / scale or 1
	local seam = math.floor(((size * threshold) / maximum) / onePixel + 0.5) * onePixel
	local padding = 400
	local overlap = onePixel

	mask:ClearAllPoints()
	if vertical then
		if reverse then
			if kind == "upper" then
				mask:SetPoint("TOPLEFT", button, "TOPLEFT", -padding, -(seam - overlap))
				mask:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", padding, -padding)
			else
				mask:SetPoint("TOPLEFT", button, "TOPLEFT", -padding, 0)
				mask:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", padding, -(seam + overlap))
			end
		elseif kind == "upper" then
			mask:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -padding, seam - overlap)
			mask:SetPoint("TOPRIGHT", button, "TOPRIGHT", padding, padding)
		else
			mask:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -padding, 0)
			mask:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", padding, seam + overlap)
		end
	elseif reverse then
		if kind == "upper" then
			mask:SetPoint("TOPRIGHT", button, "TOPRIGHT", -(seam - overlap), padding)
			mask:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -padding, -padding)
		else
			mask:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, padding)
			mask:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", -(seam + overlap), -padding)
		end
	elseif kind == "upper" then
		mask:SetPoint("TOPLEFT", button, "TOPLEFT", seam - overlap, padding)
		mask:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", padding, -padding)
	else
		mask:SetPoint("TOPLEFT", button, "TOPLEFT", 0, padding)
		mask:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", seam + overlap, -padding)
	end
	mask:Show()

	statusBar:ClearAllPoints()
	if kind == "upper" then
		statusBar:SetAllPoints(button)
		return
	end
	local overshoot = seam / (2 * math.max(threshold - 1, 1))
	local length = math.max(1, ((threshold + 1) * seam) + overshoot)
	if vertical then
		if reverse then
			statusBar:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, -(seam + overshoot))
			statusBar:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 0, -(seam + overshoot))
		else
			statusBar:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, seam + overshoot)
			statusBar:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, seam + overshoot)
		end
		statusBar:SetHeight(length)
	elseif reverse then
		statusBar:SetPoint("TOPLEFT", button, "TOPRIGHT", -(seam + overshoot), 0)
		statusBar:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", -(seam + overshoot), 0)
		statusBar:SetWidth(length)
	else
		statusBar:SetPoint("TOPRIGHT", button, "TOPLEFT", seam + overshoot, 0)
		statusBar:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", seam + overshoot, 0)
		statusBar:SetWidth(length)
	end
end

function AuraContainers:CreateStackThresholdInitializer(entry, threshold, maximum, kind, rank, bodyWidth, bodyHeight)
	return function(button)
		button:EnableMouse(false)
		button:SetFrameLevel((button:GetFrameLevel() or 0) + rank)
		local statusBar = CreateFrame("StatusBar", nil, button)
		statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
		statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
		self:ApplyStackBarDirection(statusBar, entry)
		local color = threshold.color or {}
		statusBar:SetStatusBarColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1)
		local mask = self:CreateStackThresholdMask(button)
		local fill = statusBar.GetStatusBarTexture and statusBar:GetStatusBarTexture()
		if fill and fill.AddMaskTexture then fill:AddMaskTexture(mask) end
		self:ApplyStackThresholdGeometry(button, statusBar, mask, entry, threshold.value, maximum, kind, bodyWidth, bodyHeight)
		local interpolation = kind == "lower" and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or nil
		button:SetApplicationBar(statusBar, { maxApplications = kind == "lower" and threshold.value or maximum, interpolation = interpolation })
	end
end

function AuraContainers:CreateStackThresholdShadeInitializer(entry, maximum, rank)
	return function(button)
		button:EnableMouse(false)
		button:SetFrameLevel((button:GetFrameLevel() or 0) + rank)
		local statusBar = CreateFrame("StatusBar", nil, button)
		statusBar:SetAllPoints(button)
		statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
		local defaults = Bars and Bars.DEFAULTS or {}
		statusBar:SetStatusBarTexture(resolveBarTexture(entry.barTexture or defaults.barTexture))
		self:ApplyStackBarDirection(statusBar, entry)
		statusBar:SetStatusBarColor(1, 1, 1, 1)
		local fill = statusBar.GetStatusBarTexture and statusBar:GetStatusBarTexture()
		if fill and fill.SetBlendMode then fill:SetBlendMode("MOD") end
		button:SetApplicationBar(statusBar, { maxApplications = maximum })
	end
end

function AuraContainers:RegisterStackThresholdSlots(container, state, slotHost, bodyWidth, bodyHeight)
	if not (container and state and slotHost and state.mode == "BAR" and state.entry and state.entry.barMode == "STACKS") then return true end
	local thresholds = self:GetStackThresholds(state.entry, state.activeDesaturate)
	if #thresholds == 0 then return true end
	local maximum = resolveBarStackMax(state.entry)
	for rank, threshold in ipairs(thresholds) do
		for _, kind in ipairs({ "upper", "lower" }) do
			local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY .. "Threshold" .. rank .. kind, state.filterString, {
				anchorFrame = slotHost,
				candidateFilters = { includeSpellIDs = state.includeSpellIDs },
				initializeFrame = self:CreateStackThresholdInitializer(state.entry, threshold, maximum, kind, rank, bodyWidth, bodyHeight),
			})
			if not slot then return false end
		end
	end
	local shade = AuraCompat:RegisterAuraSlot(container, SLOT_KEY .. "ThresholdShade", state.filterString, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = state.includeSpellIDs },
		initializeFrame = self:CreateStackThresholdShadeInitializer(state.entry, maximum, #thresholds + 1),
	})
	return shade ~= nil
end

local function createAuraBarChrome(button, statusBar, entry, bodyWidth, bodyHeight, overlayLevelBoost)
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
	local configuredBorderTexture = entry.barBorderTexture or defaults.barBorderTexture
	local borderTexture = Bars and Bars.ResolveBarBorderTexture and Bars.ResolveBarBorderTexture(configuredBorderTexture)
		or "Interface\\Buttons\\WHITE8x8"
	if borderEnabled and borderSize > 0 and addon.functions and addon.functions.SetSafeBorder then
		local border = CreateFrame("Frame", nil, button)
		border:SetPoint("TOPLEFT", button, "TOPLEFT", -borderOffset, borderOffset)
		border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", borderOffset, -borderOffset)
		border:SetFrameLevel((button:GetFrameLevel() or 0) + 3 + (overlayLevelBoost or 0))
		addon.functions.SetSafeBorder(border, true, borderTexture, borderSize, borderR, borderG, borderB, borderA, {
			stateKey = "_eqolAuraBarBorder",
			defaultTexture = "Interface\\Buttons\\WHITE8x8",
			drawLayer = "OVERLAY",
		})
		button._eqolAuraBarBorder = border
	end

	if entry.barMode == "STACKS" and entry.barStacksSegmented == true then createNativeAuraBarDividers(button, entry, bodyWidth, bodyHeight, overlayLevelBoost) end

	local showIcon = entry.barShowIcon
	if showIcon == nil then showIcon = defaults.barShowIcon ~= false end
	if showIcon then
		local iconSize = math.max(1, tonumber(entry.barIconSize) or tonumber(defaults.barIconSize) or 18)
		local iconOffsetX = tonumber(entry.barIconOffsetX) or tonumber(defaults.barIconOffsetX) or 0
		local iconOffsetY = tonumber(entry.barIconOffsetY) or tonumber(defaults.barIconOffsetY) or 0
		local iconPosition = entry.barIconPosition or defaults.barIconPosition or "LEFT"
		local iconHolder = CreateFrame("Frame", nil, button)
		iconHolder:SetSize(iconSize, iconSize)
		iconHolder:SetFrameLevel((button:GetFrameLevel() or 0) + 3 + (overlayLevelBoost or 0))
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
			addon.functions.SetSafeBorder(iconBorder, true, borderTexture, borderSize, borderR, borderG, borderB, borderA, {
				stateKey = "_eqolAuraBarIconBorder",
				defaultTexture = "Interface\\Buttons\\WHITE8x8",
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

local function resolveActiveGlowConfig(layout, entry, useActivationGlowColor)
	layout = layout or Helper.PANEL_LAYOUT_DEFAULTS
	local configured = entry and CooldownPanels:ResolveEntryGlowReady(layout, entry) == true
	local _, color, style, inset = CooldownPanels:ResolveEntryGlowStyle(layout, entry)
	if useActivationGlowColor == true then color = CooldownPanels:ResolveEntryActivationOverlayGlowColor(layout, entry) end
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
		supported = supported,
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

local function resolvePandemicGlowConfig(layout, entry, unitToken, filterString)
	local config = resolveActiveGlowConfig(layout, entry)
	local configured = entry and entry.pandemicGlow == true and unitToken == "target" and type(filterString) == "string" and filterString:find("HARMFUL", 1, true) ~= nil
	local color, style, inset = CooldownPanels:ResolveEntryPandemicGlowVisual(layout, entry)
	style = Helper.NormalizeGlowStyle(style, Helper.PANEL_LAYOUT_DEFAULTS.readyGlowStyle)
	local supported = style == "BLIZZARD"
		or style == "FLASH"
		or style == "MARCHING_ANTS"
		or style == "PIXEL"
		or style == "PULSING"
		or style == "SOLID"
		or style == "TINT_BORDER"
	config.configured = configured
	config.supported = supported
	config.enabled = configured and supported
	config.color = color
	config.style = style
	config.inset = inset
	return config
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

function AuraContainers:BuildStateTextureData(entry, desaturated)
	local textureType, textureValue, width, height, scale, angle, doubleTexture, mirror, mirrorSecond, mirrorVertical, mirrorVerticalSecond, spacingX, spacingY =
		CooldownPanels:ResolveEntryStateTexture(entry)
	if not textureType then return nil, "" end
	local data = {
		stateTextureShown = true,
		stateTextureType = textureType,
		stateTextureValue = textureValue,
		stateTextureWidth = width,
		stateTextureHeight = height,
		stateTextureScale = scale,
		stateTextureAngle = angle,
		stateTextureDouble = doubleTexture,
		stateTextureMirror = mirror,
		stateTextureMirrorSecond = mirrorSecond,
		stateTextureMirrorVertical = mirrorVertical,
		stateTextureMirrorVerticalSecond = mirrorVerticalSecond,
		stateTextureSpacingX = spacingX,
		stateTextureSpacingY = spacingY,
		stateTextureDesaturated = desaturated == true,
	}
	return data,
		table.concat({
			tostring(textureType),
			tostring(textureValue),
			tostring(width),
			tostring(height),
			tostring(scale),
			tostring(angle),
			doubleTexture and 1 or 0,
			mirror and 1 or 0,
			mirrorSecond and 1 or 0,
			mirrorVertical and 1 or 0,
			mirrorVerticalSecond and 1 or 0,
			tostring(spacingX),
			tostring(spacingY),
			desaturated == true and 1 or 0,
		}, ":")
end

function AuraContainers:ApplyStateTexture(button, data)
	if not (button and data and CooldownPanels.ApplyStateTexture) then return end
	-- Keep the configured texture inside the AuraButton so its secret active
	-- visibility is inherited without inspecting aura state in addon Lua.
	button.stateTexture = button:CreateTexture(nil, "ARTWORK", nil, 1)
	button.stateTexture:SetBlendMode("BLEND")
	button.stateTexture:Hide()
	button.stateTextureSecond = button:CreateTexture(nil, "ARTWORK", nil, 1)
	button.stateTextureSecond:SetBlendMode("BLEND")
	button.stateTextureSecond:Hide()
	CooldownPanels.ApplyStateTexture(button, data)
end

local function createInitializer(mode, entry, layout, durationTextProfile, activeDesaturate, activeGlow, pandemicGlow, glowWidth, glowHeight, showNativeStaticText, stateTextureData)
	local useApplicationBar = mode == "BAR" and entry.barMode == "STACKS"
	local maxApplications = resolveBarStackMax(entry)
	local stackThresholds = useApplicationBar and AuraContainers:GetStackThresholds(entry, activeDesaturate) or {}
	local stackThresholdOverlayBoost = #stackThresholds > 0 and (#stackThresholds + 2) or 0
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = not useApplicationBar and CooldownPanels:ShouldShowEntryCooldownText(layout, entry) and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = (CooldownPanels:ShouldShowEntryStacks(layout, entry, ENTRY_TYPE) or useApplicationBar) and (mode ~= "BAR" or entry.barShowStackText ~= false)
	local showStaticText = showNativeStaticText == true
		and mode == "BUTTON"
		and type(entry.staticText) == "string"
		and entry.staticText ~= ""
	local showIconTexture = mode ~= "BUTTON" or CooldownPanels:ResolveEntryShowIconTexture(layout, entry) ~= false
	local reverseFill = entry.barReverseFill == true
	local cooldownDrawEdge, cooldownDrawBling, cooldownDrawSwipe, cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA =
		resolveNativeCooldownVisuals(layout, entry)
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(durationTextProfile)
		or nil
	return function(button)
		-- AuraSlots inherit their host geometry. AuraGroup frames participate in
		-- FlowLayout directly, so their measured bootstrap geometry must be
		-- applied explicitly before restricted children and glows are created.
		if type(glowWidth) == "number" and glowWidth >= 1 and type(glowHeight) == "number" and glowHeight >= 1 then button:SetSize(glowWidth, glowHeight) end
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
			createAuraBarChrome(button, statusBar, entry, glowWidth, glowHeight, stackThresholdOverlayBoost)
			if useApplicationBar then AuraContainers:ApplyStackBarDirection(statusBar, entry) end
			if #stackThresholds > 0 then statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") end
			local color = entry.barColor
			if activeDesaturate then
				statusBar:SetStatusBarColor(0.45, 0.45, 0.45, 1)
			elseif type(color) == "table" then
				statusBar:SetStatusBarColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1)
			end
			if useApplicationBar then
				-- PTR6 writes the secret application count directly into this bar.
				-- The resolved maximum is public configuration; addon Lua never reads stacks.
				button:SetApplicationBar(statusBar, { maxApplications = maxApplications })
			else
				button:SetDurationBar(statusBar, {
					direction = reverseFill and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
				})
			end
			button._eqolDurationBar = statusBar
			if showLabel or showDuration or showStacks then textOverlay = createBarTextOverlay(button, 6 + stackThresholdOverlayBoost) end
			if showLabel then
				local label = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				applyBarTextStyle(label, textOverlay, entry, "LABEL")
				button:SetSpellName(label)
				button._eqolSpellName = label
			end
		else
			local icon
			if showIconTexture then
				icon = button:CreateTexture(nil, "ARTWORK")
				icon:SetAllPoints(button)
				icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				icon:SetDesaturated(activeDesaturate == true)
				button:SetIcon(icon)
				button._eqolIcon = icon
			end
			local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cooldown:SetAllPoints(button)
			cooldown:SetHideCountdownNumbers(true)
			if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
			if cooldown.SetReverse then cooldown:SetReverse(true) end
			if cooldown.SetDrawEdge then cooldown:SetDrawEdge(cooldownDrawEdge) end
			if cooldown.SetDrawBling then cooldown:SetDrawBling(cooldownDrawBling) end
			if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(cooldownDrawSwipe) end
			if cooldown.SetSwipeColor then cooldown:SetSwipeColor(cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA) end
			if addon.functions and addon.functions.ApplyDurationTextProfileToCooldownFrame then
				addon.functions.ApplyDurationTextProfileToCooldownFrame(cooldown, durationTextProfile)
			end
			button:SetDurationCooldown(cooldown)
			button._eqolCooldown = cooldown
			if stateTextureData then AuraContainers:ApplyStateTexture(button, stateTextureData) end
			if CooldownPanels.ApplyNativeAuraIconStyle then CooldownPanels:ApplyNativeAuraIconStyle(button, layout, icon, cooldown) end
		end

		if showDuration then
			if not textOverlay then textOverlay = createBarTextOverlay(button) end
			local duration = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			if mode == "BAR" then
				applyBarTextStyle(duration, textOverlay, entry, "VALUE")
			elseif CooldownPanels.ApplyCooldownTextFontStringStyle then
				CooldownPanels:ApplyCooldownTextFontStringStyle(button, layout, entry, duration, textOverlay, button._eqolCooldown or duration)
			end
			button:SetDurationText(duration, durationTextOptions)
			button._eqolDurationText = duration
		end
		if showStacks then
			if not textOverlay then textOverlay = createBarTextOverlay(button) end
			local count = textOverlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
			if mode == "BAR" then
				applyBarTextStyle(count, textOverlay, entry, "STACK")
			else
				applyNativeStackTextStyle(count, textOverlay, layout, entry)
			end
			button:SetApplicationCount(count)
			button._eqolApplicationCount = count
		end
		if showStaticText then
			local staticTextOverlay = CreateFrame("Frame", nil, button)
			staticTextOverlay:SetAllPoints(button)
			staticTextOverlay:EnableMouse(false)
			staticTextOverlay:SetFrameLevel((button:GetFrameLevel() or 0) + 16)
			local staticText = staticTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			staticText:SetJustifyV("MIDDLE")
			if staticText.SetWordWrap then staticText:SetWordWrap(true) end
			if staticText.SetDrawLayer then staticText:SetDrawLayer("OVERLAY", 7) end
			CooldownPanels:ApplyStaticTextFontString(staticText, button, layout, entry, nil, nil, nil, true)
			button._eqolStaticTextOverlay = staticTextOverlay
			button._eqolStaticText = staticText
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
				frameLevelOffset = 5 + stackThresholdOverlayBoost,
				width = glowWidth,
				height = glowHeight,
			})
		end
		if pandemicGlow and pandemicGlow.enabled and type(button.AddPandemicRegion) == "function" then
			local r, g, b, a = getColorComponents(pandemicGlow.color)
			local glow = AuraCompat:CreateRestrictedAuraGlow(button, button, {
				color = { r, g, b, a },
				style = pandemicGlow.style,
				shape = pandemicGlow.shape,
				border = pandemicGlow.border,
				count = pandemicGlow.count,
				frequency = pandemicGlow.frequency,
				inset = pandemicGlow.inset,
				thickness = pandemicGlow.thickness,
				borderEnabled = pandemicGlow.borderEnabled,
				borderTexture = pandemicGlow.borderTexture,
				borderSize = pandemicGlow.borderSize,
				borderOffset = pandemicGlow.borderOffset,
				borderIsBlizzard = pandemicGlow.borderIsBlizzard,
				frameLevelOffset = 15 + stackThresholdOverlayBoost,
				width = glowWidth,
				height = glowHeight,
			})
			if glow then
				button:AddPandemicRegion(glow)
				button._eqolPandemicGlow = glow
			end
		end
	end
end

local function resolveAuraSound(value)
	local soundCatalog = CooldownPanels.SoundCatalog
	local soundFileID = soundCatalog and soundCatalog:GetSoundFileID(value)
	if soundFileID then return nil, soundFileID end
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
	unitToken = Helper.NormalizeAuraUnit(unitToken)
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

local function createOverlayInitializer(mode, entry, layout, durationTextProfile, glowWidth, glowHeight, preserveHostVisual, useActivationColor, sourceIconTexture)
	local useApplicationBar = mode == "BAR" and entry.barMode == "STACKS"
	local maxApplications = resolveBarStackMax(entry)
	local stackThresholds = useApplicationBar and AuraContainers:GetStackThresholds(entry, false) or {}
	local stackThresholdOverlayBoost = #stackThresholds > 0 and (#stackThresholds + 2) or 0
	local showLabel = mode == "BAR" and entry.barShowLabel ~= false
	local showDuration = not useApplicationBar and CooldownPanels:ShouldShowEntryCooldownText(layout, entry) and (mode ~= "BAR" or entry.barShowValueText ~= false)
	local showStacks = mode == "BAR" and (entry.showStacks == true or useApplicationBar) and entry.barShowStackText ~= false
	local reverse = CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry)
	local color = useActivationColor == true and CooldownPanels:ResolveEntryActivationOverlayColor(layout, entry)
		or CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local overlayGlow = resolveActiveGlowConfig(layout, entry, true)
	local showGlow = CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true and overlayGlow.supported == true
	local glowR, glowG, glowB, glowA = getColorComponents(overlayGlow.color)
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
		local background
		if preserveHostVisual ~= true then
			background = button:CreateTexture(nil, "BACKGROUND")
			background:SetAllPoints(button)
			background:SetColorTexture(0, 0, 0, 1)
			button._eqolOverlayBackground = background
		end
		if mode == "BAR" then
			local statusBar = CreateFrame("StatusBar", nil, button)
			statusBar:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
			createAuraBarChrome(button, statusBar, entry, glowWidth, glowHeight, stackThresholdOverlayBoost)
			if useApplicationBar then AuraContainers:ApplyStackBarDirection(statusBar, entry) end
			if #stackThresholds > 0 then statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") end
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
			if showLabel or showDuration or showStacks then textOverlay = createBarTextOverlay(button, 6 + stackThresholdOverlayBoost) end
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
			local icon
			if preserveHostVisual ~= true then
				-- Native overlays replace the complete host visual while active. SLOT
				-- overlays keep the equipped item's artwork as a static AuraButton
				-- child so Blizzard can secret-hide the whole replacement together.
				icon = button:CreateTexture(nil, "ARTWORK")
				icon:SetAllPoints(button)
				if sourceIconTexture then
					icon:SetTexture(sourceIconTexture)
				else
					button:SetIcon(icon)
				end
			end
			local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cooldown:SetAllPoints(button)
			cooldown:SetHideCountdownNumbers(true)
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
			if showDuration then
				local textOverlay = createBarTextOverlay(button)
				local duration = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				if CooldownPanels.ApplyCooldownTextFontStringStyle then
					CooldownPanels:ApplyCooldownTextFontStringStyle(button, layout, entry, duration, textOverlay, cooldown)
				end
				button:SetDurationText(duration, durationTextOptions)
				button._eqolOverlayDurationText = duration
			end
		end

		if showGlow then
			local glow = AuraCompat:CreateRestrictedAuraGlow(button, button, {
				color = { glowR, glowG, glowB, glowA },
				style = overlayGlow.style,
				shape = overlayGlow.shape,
				border = overlayGlow.border,
				count = overlayGlow.count,
				frequency = overlayGlow.frequency,
				inset = overlayGlow.inset,
				thickness = overlayGlow.thickness,
				borderEnabled = overlayGlow.borderEnabled,
				borderTexture = overlayGlow.borderTexture,
				borderSize = overlayGlow.borderSize,
				borderOffset = overlayGlow.borderOffset,
				borderIsBlizzard = overlayGlow.borderIsBlizzard,
				frameLevelOffset = 15 + stackThresholdOverlayBoost,
				width = glowWidth,
				height = glowHeight,
			})
			button._eqolOverlayGlow = glow
		end
	end
end

local function applyOverlayHostVisibility(state, icon, layoutEditActive)
	if not (state and state.kind == STATE_KIND_OVERLAY and icon) then return end
	local data = icon._eqolRuntimeData
	if not (data and tostring(data.entryId) == tostring(state.entryId)) then return end

	local alpha
	if layoutEditActive then
		alpha = 1
	else
		local panel = CooldownPanels:GetPanel(state.panelId)
		local entry = panel and panel.entries and panel.entries[state.entryId]
		local overlayOnly = entry and CooldownPanels:ResolveEntryActivationOverlayOnly(panel and panel.layout, entry) == true
		if overlayOnly or data.nativeAuraHostBaseVisible == false then alpha = 0 end
	end
	-- When the regular host is allowed, retain the alpha chosen by the normal
	-- icon/bar runtime (including cooldown visibility rules and secret values).
	if alpha == nil then return end
	if state.mode == "BAR" then
		local barFrame = icon._eqolBarsFrame
		if barFrame then barFrame:SetAlpha(alpha) end
	else
		icon:SetAlpha(alpha)
	end
end

function AuraContainers:ApplySuppressedHost(state, icon, layoutEditActive)
	if not state then return end
	if state.kind == STATE_KIND_OVERLAY then
		applyOverlayHostVisibility(state, icon, layoutEditActive)
		return
	end
	local alpha = layoutEditActive and 1 or (state.showInactive and 1 or 0)
	if state.mode == "BAR" then
		local barFrame = icon and icon._eqolBarsFrame
		if barFrame then barFrame:SetAlpha(alpha) end
	elseif icon then
		icon:SetAlpha(alpha)
	end
end

function AuraContainers:BeginPanelBuild(panelId)
	panelId = tonumber(panelId) or panelId
	if panelId == nil then return nil end
	local activeToken = self.panelBuildTokens[panelId]
	if activeToken then
		self.panelBuildDepths[panelId] = (self.panelBuildDepths[panelId] or 1) + 1
		return activeToken
	end
	self.buildSerial = self.buildSerial + 1
	local token = self.buildSerial
	self.panelBuildTokens[panelId] = token
	self.panelBuildDepths[panelId] = 1
	return token
end

function AuraContainers:MarkStateSeen(state)
	if not state then return end
	local panelId = tonumber(state.panelId) or state.panelId
	local token = panelId ~= nil and self.panelBuildTokens[panelId] or nil
	if token then state.buildToken = token end
end

function AuraContainers:CancelStateGeometryRefresh(state)
	if not state then return end
	local timer = state.geometryTimer
	if timer and timer.Cancel then timer:Cancel() end
	state.geometryTimer = nil
	state.pendingGeometryWidth = nil
	state.pendingGeometryHeight = nil
end

function AuraContainers:UntrackStateGeometry(state)
	if not state then return end
	self:CancelStateGeometryRefresh(state)
	local target = state.geometryTarget
	if not target then return end
	local tracked = self.geometryStatesByTarget[target]
	if tracked then
		tracked[state] = nil
		if not next(tracked) then self.geometryStatesByTarget[target] = nil end
	end
	state.geometryTarget = nil
end

function AuraContainers:StateNeedsGeometryRefresh(state)
	return state
		and (
			state.kind == STATE_KIND_OVERLAY
			or state.nativeStackDividers == true
			or (state.activeGlow and state.activeGlow.enabled == true)
		)
end

function AuraContainers:TrackStateGeometry(state, target)
	if not (state and target) then return end
	if state.geometryTarget ~= target then
		self:UntrackStateGeometry(state)
		state.geometryTarget = target
	end
	local tracked = self.geometryStatesByTarget[target]
	if not tracked then
		tracked = setmetatable({}, { __mode = "k" })
		self.geometryStatesByTarget[target] = tracked
	end
	tracked[state] = true
	if self.geometryHookedTargets[target] or not target.HookScript then return end
	if InCombatLockdown and InCombatLockdown() and target.IsProtected and target:IsProtected() then return end
	if target.HasAnyForbiddenAspects and Enum and Enum.ForbiddenAspect then
		if target:HasAnyForbiddenAspects(Enum.ForbiddenAspect.ScriptBindings) then return end
		if target:HasAnyForbiddenAspects(Enum.ForbiddenAspect.UntrustedLayoutScriptExecution) then return end
	end
	local hooked = target:HookScript("OnSizeChanged", function(frame)
		local targetStates = AuraContainers.geometryStatesByTarget[frame]
		if not targetStates then return end
		for trackedState in pairs(targetStates) do
			if
				trackedState
				and not trackedState.disabled
				and trackedState.geometryTarget == frame
				and not (trackedState.dynamicOwner and trackedState.dynamicOwner.enabled == true)
			then
				if AuraContainers:StateNeedsGeometryRefresh(trackedState) then
					AuraContainers:ScheduleStateGeometryRefresh(trackedState, frame)
				else
					AuraContainers:RequestPanelSync(trackedState.panelId)
				end
			end
		end
	end)
	if hooked ~= false then self.geometryHookedTargets[target] = true end
end

function AuraContainers:EnsurePanelVisibilityHook(frame)
	if not (frame and frame.HookScript) or self.visibilityHookedFrames[frame] then return end
	if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end
	if frame.HasAnyForbiddenAspects and Enum and Enum.ForbiddenAspect then
		if frame:HasAnyForbiddenAspects(Enum.ForbiddenAspect.ScriptBindings) then return end
		if frame:HasAnyForbiddenAspects(Enum.ForbiddenAspect.UntrustedScriptExecution) then return end
	end
	local showHooked = frame:HookScript("OnShow", function(owner)
		if owner.panelId ~= nil then AuraContainers:RequestPanelSync(owner.panelId) end
	end)
	local hideHooked = frame:HookScript("OnHide", function(owner)
		if owner.panelId ~= nil then AuraContainers:RequestPanelSync(owner.panelId) end
	end)
	if showHooked ~= false and hideHooked ~= false then self.visibilityHookedFrames[frame] = true end
end

function AuraContainers:RequestPanelSync(panelId)
	panelId = tonumber(panelId) or panelId
	if panelId == nil then return end
	self.pendingPanelSyncs[panelId] = true
	if self.panelSyncScheduled then return end
	self.panelSyncScheduled = true
	RunNextFrame(function()
		AuraContainers.panelSyncScheduled = nil
		local queue = AuraContainers.pendingPanelSyncs
		for queuedPanelId in pairs(queue) do
			queue[queuedPanelId] = nil
			AuraContainers:SyncPanelStates(queuedPanelId)
		end
	end)
end

function AuraContainers:RequestAllPanelSyncs()
	for _, state in pairs(states) do
		if not state.disabled then self:RequestPanelSync(state.panelId) end
	end
	for panelId in pairs(self.dynamicGroupsByPanel) do self:RequestPanelSync(panelId) end
end

local function disableState(state)
	if not state then return end
	AuraContainers:UntrackStateGeometry(state)
	if state.dynamicOwner and AuraContainers.InvalidateDynamicGroup then AuraContainers:InvalidateDynamicGroup(state.dynamicOwner, true) end
	state.pendingAuraSoundRequest = nil
	SoundLifecycle.Unregister(state)
	if state.container then AuraCompat:DisableAuraContainer(state.container) end
	state.disabled = true
end

function AuraContainers:RemoveState(state)
	if not state then return end
	disableState(state)
	if state.container then state.container:SetAlpha(0) end
	if states[state.key] == state then states[state.key] = nil end
end

function AuraContainers:ReleasePanelStates(panelId)
	panelId = tonumber(panelId) or panelId
	if panelId == nil then return end
	-- Detach native group ownership first so removing its member states cannot
	-- enqueue a pointless panel rebuild while the whole panel is being released.
	local panelGroups = self.dynamicGroupsByPanel[panelId]
	if panelGroups then
		local owners = {}
		for _, owner in pairs(panelGroups) do owners[#owners + 1] = owner end
		for i = 1, #owners do self:InvalidateDynamicGroup(owners[i], false) end
	end
	local stale = {}
	for _, state in pairs(states) do
		if (tonumber(state.panelId) or state.panelId) == panelId then stale[#stale + 1] = state end
	end
	for i = 1, #stale do self:RemoveState(stale[i]) end
	self.pendingPanelSyncs[panelId] = nil
	self.panelBuildTokens[panelId] = nil
	self.panelBuildDepths[panelId] = nil
end

function AuraContainers:PanelCanOwnStates(panelId)
	panelId = tonumber(panelId) or panelId
	local panel = panelId ~= nil and CooldownPanels:GetPanel(panelId) or nil
	if not panel then return false end
	if CooldownPanels:IsPanelLayoutEditActive(panelId) then return true end
	if panel.enabled == false then return false end
	local runtime = CooldownPanels.runtime
	local enabledPanels = runtime and runtime.enabledPanels
	if enabledPanels then return enabledPanels[panelId] == true end
	return true
end

function AuraContainers:PruneInactiveStates(panelId)
	if panelId ~= nil then
		panelId = tonumber(panelId) or panelId
		if not self:PanelCanOwnStates(panelId) then self:ReleasePanelStates(panelId) end
		return
	end
	local panelIds = {}
	for _, state in pairs(states) do panelIds[state.panelId] = true end
	for activePanelId in pairs(panelIds) do
		if not self:PanelCanOwnStates(activePanelId) then self:ReleasePanelStates(activePanelId) end
	end
end

local function createState(panelId, entryId, entry, layout, alwaysShowMode, unitTokenOverride, stateKeySuffix)
	local configuredUnit = Helper.NormalizeAuraUnit(entry.auraUnit)
	local unitToken = unitTokenOverride or configuredUnit
	local stateKeyEntryId = stateKeySuffix and (tostring(entryId) .. ":" .. tostring(stateKeySuffix)) or entryId
	local key = getStateKey(STATE_KIND_ENTRY, panelId, stateKeyEntryId)
	local spellID = getAuraSpellID(entry)
	if not spellID then
		local state = states[key]
		if state then
			disableState(state)
			states[key] = nil
		end
		return nil
	end
	local spellIDs, includeSpellIDs, spellIDSignature = getAuraSpellIDs(entry)
	if #spellIDs == 0 then
		local state = states[key]
		if state then
			disableState(state)
			states[key] = nil
		end
		return nil
	end
	spellIDSignature = spellIDSignature or table.concat(spellIDs, ",")
	local maxFrameCount = getAuraMaxFrameCount(entry)
	local mode = getDisplayMode(entry)
	local filterString = Helper.IsAuraGroupUnit(configuredUnit) and AuraContainers.GROUP_FILTER_STRING
		or unitToken == "target" and (entry.auraFilter == "HARMFUL" and "HARMFUL" or TARGET_FILTER_STRING)
		or FILTER_STRING
	local showInactive = alwaysShowMode ~= "HIDE" and alwaysShowMode ~= "HIDE_DESATURATE_ACTIVE"
	-- An always-visible host already owns its static text. Let the native
	-- AuraButton own it only when Blizzard must control the text visibility.
	local showNativeStaticText = not showInactive or entry.staticTextShowOnCooldown == true
	local activeDesaturate = alwaysShowMode == "DESATURATE_ACTIVE" or alwaysShowMode == "HIDE_DESATURATE_ACTIVE"
	local durationTextProfile = getDurationTextProfile(panelId, entry)
	local showIconTexture = mode ~= "BUTTON" or CooldownPanels:ResolveEntryShowIconTexture(layout, entry) ~= false
	local stateTextureData, stateTextureSignature
	if mode == "BUTTON" then stateTextureData, stateTextureSignature = AuraContainers:BuildStateTextureData(entry, activeDesaturate) end
	local color = entry.barColor
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local activeGlow = resolveActiveGlowConfig(layout, entry)
	local pandemicGlow = resolvePandemicGlowConfig(layout, entry, unitToken, filterString)
	local glowR, glowG, glowB, glowA = getColorComponents(activeGlow.color)
	local pandemicR, pandemicG, pandemicB, pandemicA = getColorComponents(pandemicGlow.color)
	local cooldownTextStyleSignature = mode == "BUTTON" and getCooldownTextStyleSignature(layout, entry) or ""
	local stackTextStyleSignature = mode == "BUTTON" and getStackTextStyleSignature(layout, entry) or ""
	local staticTextStyleSignature = mode == "BUTTON" and showNativeStaticText and getStaticTextStyleSignature(layout, entry) or ""
	local showStacks = CooldownPanels:ShouldShowEntryStacks(layout, entry, ENTRY_TYPE)
	local iconBorderColor = layout and layout.iconBorderColor
	local effectiveStackMax = resolveBarStackMax(entry)
	local stackThresholdSignature = AuraContainers:GetStackThresholdSignature(entry, activeDesaturate)
	local nativeStackDividers = usesNativeStackDividers(mode, entry)
	local visualSize, visualOffsetX, visualOffsetY, visualWidth, visualHeight
	if mode == "BUTTON" and CooldownPanels.ResolveEntryIconVisualLayout then
		visualSize, visualOffsetX, visualOffsetY, visualWidth, visualHeight = CooldownPanels:ResolveEntryIconVisualLayout(layout, entry)
	end
	local cooldownDrawEdge, cooldownDrawBling, cooldownDrawSwipe, cooldownSwipeR, cooldownSwipeG, cooldownSwipeB, cooldownSwipeA =
		resolveNativeCooldownVisuals(layout, entry)
	local signature = table.concat({
		spellIDSignature,
		maxFrameCount,
		unitToken,
		filterString,
		Helper.IsAuraGroupUnit(configuredUnit) and Helper.NormalizeDirection(layout and layout.direction, Helper.PANEL_LAYOUT_DEFAULTS.direction) or "",
		Helper.IsAuraGroupUnit(configuredUnit) and tostring(layout and layout.spacing or Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0) or "",
		mode,
		tostring(durationTextProfile),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		layout and layout.showTooltips == true and 1 or 0,
		showIconTexture and 1 or 0,
		stateTextureSignature or "",
		CooldownPanels:ShouldShowEntryCooldownText(layout, entry) and 1 or 0,
		cooldownTextStyleSignature,
		stackTextStyleSignature,
		staticTextStyleSignature,
		cooldownDrawEdge and 1 or 0,
		cooldownDrawBling and 1 or 0,
		cooldownDrawSwipe and 1 or 0,
		tostring(cooldownSwipeR),
		tostring(cooldownSwipeG),
		tostring(cooldownSwipeB),
		tostring(cooldownSwipeA),
		showStacks and 1 or 0,
		tostring(layout and layout.iconShape or ""),
		tostring(layout and layout.iconZoom or ""),
		layout and layout.iconBorderEnabled == true and 1 or 0,
		tostring(layout and layout.iconBorderTexture or ""),
		tostring(layout and layout.iconBorderSize or ""),
		tostring(layout and layout.iconBorderOffset or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.r or iconBorderColor[1]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.g or iconBorderColor[2]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.b or iconBorderColor[3]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.a or iconBorderColor[4]) or ""),
		tostring(visualSize or ""),
		tostring(visualOffsetX or ""),
		tostring(visualOffsetY or ""),
		tostring(visualWidth or ""),
		tostring(visualHeight or ""),
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
		pandemicGlow.configured and 1 or 0,
		pandemicGlow.enabled and 1 or 0,
		tostring(pandemicGlow.style or ""),
		tostring(pandemicR),
		tostring(pandemicG),
		tostring(pandemicB),
		tostring(pandemicA),
		tostring(pandemicGlow.inset or ""),
		tostring(pandemicGlow.shape or ""),
		pandemicGlow.border and 1 or 0,
		tostring(pandemicGlow.count or ""),
		tostring(pandemicGlow.frequency or ""),
		tostring(pandemicGlow.thickness or ""),
		pandemicGlow.borderEnabled and 1 or 0,
		tostring(pandemicGlow.borderTexture or ""),
		tostring(pandemicGlow.borderSize or ""),
		tostring(pandemicGlow.borderOffset or ""),
		pandemicGlow.borderIsBlizzard and 1 or 0,
		tostring(entry.barTexture or ""),
		tostring(entry.barMode or ""),
		tostring(entry.barStackMax or ""),
		entry.barStackTalentMaxEnabled == true and 1 or 0,
		tostring(entry.barStackTalentSpellID or ""),
		tostring(entry.barStackTalentMax or ""),
		tostring(effectiveStackMax),
		stackThresholdSignature,
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
		entry.barStacksSegmented == true and 1 or 0,
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.r or entry.barStackDividerColor[1]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.g or entry.barStackDividerColor[2]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.b or entry.barStackDividerColor[3]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.a or entry.barStackDividerColor[4]) or ""),
		tostring(entry.barStackDividerThickness or ""),
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
		tostring(entry.barWidth or ""),
		tostring(entry.barHeight or ""),
		tostring(entry.barSpan or ""),
		tostring(entry.barOffsetX or ""),
		tostring(entry.barOffsetY or ""),
	}, ":")
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		state.entry = entry
		state.layout = layout
		state.durationTextProfile = durationTextProfile
		state.activeDesaturate = activeDesaturate
		state.activeGlow = activeGlow
		state.pandemicGlow = pandemicGlow
		state.visualOffsetX = visualOffsetX or 0
		state.visualOffsetY = visualOffsetY or 0
		state.showInactive = showInactive
		state.showNativeStaticText = showNativeStaticText
		state.stateTextureData = stateTextureData
		state.spellIDs = spellIDs
		state.includeSpellIDs = includeSpellIDs
		state.spellIDSignature = spellIDSignature
		state.maxFrameCount = maxFrameCount
		state.nativeStackDividers = nativeStackDividers
		SoundLifecycle.Register(state, entry, spellIDs, unitToken)
		AuraContainers:MarkStateSeen(state)
		return state
	end
	if state then disableState(state) end

	local container
	local slot
	local slotHost
	local sensorOnly = type(entryId) == "string" and entryId:find(":glowOtherAura", 1, true) ~= nil
	if sensorOnly then
		-- Synthetic other-aura states are sensors only and never attach to a
		-- panel visual. Real tracked-aura slots must wait until attachState knows
		-- their final target so the host is anchored before AddAuraSlot makes its
		-- AuraButton relationship immutable.
		container = AuraCompat:CreateAuraContainer(UIParent)
		if not container then return nil end
		slotHost = createSlotHost()
		container:SetAllPoints(UIParent)
		container:SetAlpha(0)
		container:SetUnit(unitToken)
		slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, filterString, {
			anchorFrame = slotHost,
			candidateFilters = { includeSpellIDs = includeSpellIDs },
			initializeFrame = createInitializer(mode, entry, layout, durationTextProfile, activeDesaturate, activeGlow, nil, nil, nil, false),
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
		spellIDs = spellIDs,
		includeSpellIDs = includeSpellIDs,
		spellIDSignature = spellIDSignature,
		maxFrameCount = maxFrameCount,
		unitToken = unitToken,
		auraUnitMode = configuredUnit,
		filterString = filterString,
		mode = mode,
		signature = signature,
		entry = entry,
		layout = layout,
		durationTextProfile = durationTextProfile,
		activeDesaturate = activeDesaturate,
		activeGlow = activeGlow,
		pandemicGlow = pandemicGlow,
		visualOffsetX = visualOffsetX or 0,
		visualOffsetY = visualOffsetY or 0,
		nativeStackDividers = nativeStackDividers,
		sensorOnly = sensorOnly,
		container = container,
		slot = slot,
		slotHost = slotHost,
		showInactive = showInactive,
		showNativeStaticText = showNativeStaticText,
		stateTextureData = stateTextureData,
	}
	states[key] = state
	SoundLifecycle.Register(state, entry, spellIDs, unitToken)
	AuraContainers:MarkStateSeen(state)
	if container then
		if AuraContainers:IsTrackedAuraSuppressed(state.unitToken, state.filterString) then
			AuraCompat:DisableAuraContainer(container)
			state.auraIdentitySuppressed = true
		else
			AuraCompat:RefreshAuraContainer(container, unitToken)
		end
	end
	return state
end

local function getOverlaySpellIDs(entry, spellID)
	local candidates = CooldownPanels.GetEntryAuraOverlaySpellIDs and CooldownPanels:GetEntryAuraOverlaySpellIDs(entry, spellID) or { spellID }
	local includeSpellIDs = {}
	for i = 1, #candidates do includeSpellIDs[candidates[i]] = true end
	return candidates, includeSpellIDs
end

local function getExplicitOverlaySpellIDs(spellIDs)
	local candidates = {}
	local includeSpellIDs = {}
	for i = 1, #(spellIDs or {}) do
		local spellID = tonumber(spellIDs[i])
		if spellID and spellID > 0 and not includeSpellIDs[spellID] then
			includeSpellIDs[spellID] = true
			candidates[#candidates + 1] = spellID
		end
	end
	return candidates, includeSpellIDs
end

local function clearOverlayState(panelId, entryId)
	local stale = {}
	for _, state in pairs(states) do
		if state.kind == STATE_KIND_OVERLAY and tostring(state.panelId) == tostring(panelId) and tostring(state.entryId) == tostring(entryId) then stale[#stale + 1] = state end
	end
	for i = 1, #stale do AuraContainers:RemoveState(stale[i]) end
end

local function createOverlayState(panelId, entryId, entry, spellID, layout, options, unitTokenOverride, stateKeySuffix)
	options = options or {}
	local configuredUnit = Helper.NormalizeAuraUnit(options.unitToken or entry.cdmAuraOverlayUnit)
	local unitToken = unitTokenOverride or configuredUnit
	local stateKeyEntryId = stateKeySuffix and (tostring(entryId) .. ":" .. tostring(stateKeySuffix)) or entryId
	local key = getStateKey(STATE_KIND_OVERLAY, panelId, stateKeyEntryId)
	spellID = tonumber(spellID or entry and entry.spellID)
	if not spellID then
		clearOverlayState(panelId, entryId)
		return nil
	end
	local candidates, includeSpellIDs
	if type(options.spellIDs) == "table" then
		candidates, includeSpellIDs = getExplicitOverlaySpellIDs(options.spellIDs)
	else
		candidates, includeSpellIDs = getOverlaySpellIDs(entry, spellID)
	end
	if #candidates == 0 then
		clearOverlayState(panelId, entryId)
		return nil
	end
	local mode = getDisplayMode(entry)
	local durationTextProfile = getDurationTextProfile(panelId, entry)
	local filterString = options.filterString
	if not filterString then
		if Helper.IsAuraGroupUnit(configuredUnit) then
			filterString = AuraContainers.GROUP_FILTER_STRING
		elseif unitToken == "target" then
			filterString = entry.cdmAuraOverlayTargetPlayerOnly == false and "HARMFUL" or TARGET_FILTER_STRING
		else
			filterString = FILTER_STRING
		end
	end
	local color = options.useActivationColor == true and CooldownPanels:ResolveEntryActivationOverlayColor(layout, entry)
		or CooldownPanels:ResolveEntryCDMAuraOverlayColor(layout, entry)
	local r, g, b, a = getColorComponents(color)
	local overlayGlow = resolveActiveGlowConfig(layout, entry, true)
	local glowR, glowG, glowB, glowA = getColorComponents(overlayGlow.color)
	local labelColor = entry.barLabelColor
	local valueColor = entry.barValueColor
	local stackColor = entry.barStackColor
	local cooldownTextStyleSignature = mode == "BUTTON" and getCooldownTextStyleSignature(layout, entry) or ""
	local iconBorderColor = layout and layout.iconBorderColor
	local effectiveStackMax = resolveBarStackMax(entry)
	local stackThresholdSignature = AuraContainers:GetStackThresholdSignature(entry, false)
	local signature = table.concat({
		options.sourceEntryType or SPELL_ENTRY_TYPE,
		tostring(options.sourceItemID or ""),
		tostring(options.sourceIconTexture or ""),
		options.preserveHostVisual == true and 1 or 0,
		options.useActivationColor == true and 1 or 0,
		table.concat(candidates, ","),
		unitToken,
		filterString,
		Helper.IsAuraGroupUnit(configuredUnit) and Helper.NormalizeDirection(layout and layout.direction, Helper.PANEL_LAYOUT_DEFAULTS.direction) or "",
		Helper.IsAuraGroupUnit(configuredUnit) and tostring(layout and layout.spacing or Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0) or "",
		mode,
		tostring(durationTextProfile),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		layout and layout.showTooltips == true and 1 or 0,
		CooldownPanels:ShouldShowEntryCooldownText(layout, entry) and 1 or 0,
		cooldownTextStyleSignature,
		CooldownPanels:ResolveEntryActivationOverlayReverse(layout, entry) and 1 or 0,
		CooldownPanels:ResolveEntryActivationOverlayGlow(layout, entry) == true and 1 or 0,
		tostring(glowR),
		tostring(glowG),
		tostring(glowB),
		tostring(glowA),
		tostring(overlayGlow.style or ""),
		tostring(overlayGlow.inset or ""),
		tostring(overlayGlow.shape or ""),
		overlayGlow.border and 1 or 0,
		tostring(overlayGlow.count or ""),
		tostring(overlayGlow.frequency or ""),
		tostring(overlayGlow.thickness or ""),
		overlayGlow.borderEnabled and 1 or 0,
		tostring(overlayGlow.borderTexture or ""),
		tostring(overlayGlow.borderSize or ""),
		tostring(overlayGlow.borderOffset or ""),
		overlayGlow.borderIsBlizzard and 1 or 0,
		tostring(entry.barTexture or ""),
		tostring(entry.barMode or ""),
		tostring(entry.barStackMax or ""),
		entry.barStackTalentMaxEnabled == true and 1 or 0,
		tostring(entry.barStackTalentSpellID or ""),
		tostring(entry.barStackTalentMax or ""),
		tostring(effectiveStackMax),
		stackThresholdSignature,
		tostring(layout and layout.iconShape or ""),
		tostring(layout and layout.iconZoom or ""),
		layout and layout.iconBorderEnabled == true and 1 or 0,
		tostring(layout and layout.iconBorderTexture or ""),
		tostring(layout and layout.iconBorderSize or ""),
		tostring(layout and layout.iconBorderOffset or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.r or iconBorderColor[1]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.g or iconBorderColor[2]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.b or iconBorderColor[3]) or ""),
		tostring(type(iconBorderColor) == "table" and (iconBorderColor.a or iconBorderColor[4]) or ""),
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
		entry.barStacksSegmented == true and 1 or 0,
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.r or entry.barStackDividerColor[1]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.g or entry.barStackDividerColor[2]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.b or entry.barStackDividerColor[3]) or ""),
		tostring(type(entry.barStackDividerColor) == "table" and (entry.barStackDividerColor.a or entry.barStackDividerColor[4]) or ""),
		tostring(entry.barStackDividerThickness or ""),
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
	local state = states[key]
	if state and state.signature == signature and not state.disabled then
		state.entry = entry
		state.layout = layout
		state.durationTextProfile = durationTextProfile
		state.includeSpellIDs = includeSpellIDs
		state.sourceEntryType = options.sourceEntryType or SPELL_ENTRY_TYPE
		state.sourceItemID = tonumber(options.sourceItemID)
		state.sourceIconTexture = options.sourceIconTexture
		state.preserveHostVisual = options.preserveHostVisual == true
		state.useActivationColor = options.useActivationColor == true
		SoundLifecycle.Register(state, entry, candidates, unitToken)
		AuraContainers:MarkStateSeen(state)
		return state
	end
	if state then disableState(state) end

	state = {
		key = key,
		kind = STATE_KIND_OVERLAY,
		panelId = panelId,
		entryId = entryId,
		spellID = spellID,
		sourceEntryType = options.sourceEntryType or SPELL_ENTRY_TYPE,
		sourceItemID = tonumber(options.sourceItemID),
		sourceIconTexture = options.sourceIconTexture,
		preserveHostVisual = options.preserveHostVisual == true,
		useActivationColor = options.useActivationColor == true,
		unitToken = unitToken,
		auraUnitMode = configuredUnit,
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
	AuraContainers:MarkStateSeen(state)
	return state
end

function AuraContainers:BuildRuntimeData(panelId, entryId, entry, layout, alwaysShowMode)
	local state
	local groupUnitTokens = self:GetAuraGroupUnitTokens(entry and entry.auraUnit)
	if groupUnitTokens then
		for i, unitToken in ipairs(groupUnitTokens) do
			local partyState = createState(panelId, entryId, entry, layout, alwaysShowMode, unitToken, i > 1 and unitToken or nil)
			if partyState then
				partyState.partyIndex = i
			end
			state = state or partyState
		end
	else
		state = createState(panelId, entryId, entry, layout, alwaysShowMode)
	end
	if not state then return nil end
	local nativeDynamicGroup = state.dynamicOwner and state.dynamicOwner.enabled == true
	return {
		-- PTR4 owns the secret shown state of the AuraButton. Keep the normal
		-- layout host allocated until a shared dynamic AuraGroup owns the entry.
		-- Regular grids keep their configured hosts as invisible geometry so the
		-- panel and its first slot cannot move when the secret visible count changes.
		nativeAuraTooltipOwner = true,
		active = false,
		show = not nativeDynamicGroup or state.dynamicOwner.keepLayoutHosts == true,
		nativeDynamicGroup = nativeDynamicGroup,
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
	local state
	local groupUnitTokens = self:GetAuraGroupUnitTokens(entry and entry.cdmAuraOverlayUnit)
	if groupUnitTokens then
		for i, unitToken in ipairs(groupUnitTokens) do
			local partyState = createOverlayState(panelId, entryId, entry, spellID, layout, nil, unitToken, i > 1 and unitToken or nil)
			if partyState then
				partyState.partyIndex = i
			end
			state = state or partyState
		end
	else
		state = createOverlayState(panelId, entryId, entry, spellID, layout)
	end
	if not state then return nil end
	return {
		-- The normal spell host remains allocated, while Blizzard alone owns the
		-- AuraButton's secret active visibility and duration.
		nativeAuraSlot = true,
		nativeAuraTooltipOwner = true,
		active = false,
		buffName = getSpellName(spellID),
	}
end

function AuraContainers:BuildSlotAuraOverlayData(panelId, entryId, entry, itemID, layout)
	local spellIDs, knownItem, resolvedItemID = CooldownPanels:GetEntryNativeAuraItemInfo(entry, SLOT_ENTRY_TYPE)
	itemID = tonumber(itemID)
	if not (knownItem and itemID and itemID == tonumber(resolvedItemID)) or not spellIDs then
		clearOverlayState(panelId, entryId)
		return nil
	end
	local sourceIconTexture = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or Helper.PREVIEW_ICON
	local state = createOverlayState(panelId, entryId, entry, spellIDs[1], layout, {
		spellIDs = spellIDs,
		sourceEntryType = SLOT_ENTRY_TYPE,
		sourceItemID = itemID,
		sourceIconTexture = sourceIconTexture,
		preserveHostVisual = false,
		useActivationColor = true,
		unitToken = "player",
		filterString = FILTER_STRING,
	})
	if not state then return nil end
	return {
		-- The equipped-item host remains stable while Blizzard owns the tracked
		-- aura's secret visibility, duration and restricted activation glow.
		nativeAuraSlot = true,
		nativeAuraTooltipOwner = true,
		active = false,
		buffName = getSpellName(spellIDs[1]),
	}
end

function AuraContainers:AnchorPartySlotHost(state, slotHost, target, width, height)
	if not (state and state.partyIndex and state.partyIndex > 1) then
		slotHost:SetAllPoints(target)
		return
	end
	local direction = Helper.NormalizeDirection(state.layout and state.layout.direction, Helper.PANEL_LAYOUT_DEFAULTS.direction)
	local spacing = Helper.ClampInt(state.layout and state.layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0)
	local step = state.partyIndex - 1
	local offsetX, offsetY = 0, 0
	if direction == "LEFT" then
		offsetX = -step * (width + spacing)
	elseif direction == "UP" then
		offsetY = step * (height + spacing)
	elseif direction == "DOWN" then
		offsetY = -step * (height + spacing)
	else
		offsetX = step * (width + spacing)
	end
	slotHost:SetSize(width, height)
	slotHost:SetPoint("CENTER", target, "CENTER", offsetX, offsetY)
end

local function initializeEntryState(state, target, width, height)
	if not (state and target and width and height) then return false end

	local multiFrame = (state.maxFrameCount or 1) > 1
	local template = multiFrame and (tostring(AuraCompat.defaultContainerTemplate or "CustomAuraContainerTemplate") .. ",DisableUntrustedLayoutScriptsTemplate")
		or nil
	local container = AuraCompat:CreateAuraContainer(UIParent, nil, template)
	if not container then return false end
	local slotHost = createSlotHost()
	slotHost:ClearAllPoints()
	AuraContainers:AnchorPartySlotHost(state, slotHost, target, width, height)
	container:SetAlpha(0)
	container:SetUnit(state.unitToken)
	-- AuraButton children become restricted immediately after initialization.
	-- Create them only after the real icon or bar geometry is known so the
	-- restricted glow snapshots the correct dimensions.
	local initializer = createInitializer(
		state.mode,
		state.entry,
		state.layout,
		state.durationTextProfile,
		state.activeDesaturate,
		state.activeGlow,
		state.pandemicGlow,
		width,
		height,
		state.showNativeStaticText,
		state.stateTextureData
	)
	local slot
	local auraGroupKey
	if multiFrame then
		local flowAxes = AnchorUtil and AnchorUtil.FlowLayoutAxis
		local spacing = Helper.ClampInt(
			state.layout and state.layout.spacing,
			0,
			Helper.SPACING_RANGE or 200,
			Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0
		)
		if not flowAxes then
			AuraCompat:DisableAuraContainer(container)
			return false
		end
		container:ClearAllPoints()
		container:SetPoint("TOPLEFT", slotHost, "TOPLEFT")
		if not AuraCompat:ConfigureAuraContainerLayout(container, {
			axis = flowAxes.Horizontal,
			anchorPoint = "TOPLEFT",
			horizontalGrowthDirection = 1,
			verticalGrowthDirection = -1,
			maximumLineSize = AuraCompat:GetSafeFlowLayoutMaximumLineSize(container, width, spacing, state.maxFrameCount),
		}) then
			AuraCompat:DisableAuraContainer(container)
			return false
		end
		auraGroupKey = SLOT_KEY
		slot = AuraCompat:RegisterAuraGroup(container, auraGroupKey, state.filterString, {
			maxFrameCount = state.maxFrameCount,
			candidateFilters = { includeSpellIDs = state.includeSpellIDs },
			initializeFrame = initializer,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				elementWidth = width,
				elementHeight = height,
				layoutIndex = 1,
			},
		})
	else
		container:SetAllPoints(UIParent)
		slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, state.filterString, {
			anchorFrame = slotHost,
			candidateFilters = { includeSpellIDs = state.includeSpellIDs },
			initializeFrame = initializer,
		})
	end
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return false
	end
	if not multiFrame and not AuraContainers:RegisterStackThresholdSlots(container, state, slotHost, width, height) then
		AuraCompat:DisableAuraContainer(container)
		return false
	end

	local oldContainer = state.container
	state.container = container
	state.slot = slot
	state.slotHost = slotHost
	state.auraGroupKey = auraGroupKey
	state.displayTarget = target
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
	AuraContainers:AnchorPartySlotHost(state, slotHost, target, width, height)
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	if state.mode ~= "BAR" then
		if container.SetFrameStrata and target.GetFrameStrata then container:SetFrameStrata(target:GetFrameStrata()) end
		local targetLevel = target.GetFrameLevel and target:GetFrameLevel() or 0
		if state.kind == STATE_KIND_OVERLAY and target.overlay and target.overlay.GetFrameLevel then
			targetLevel = math.max(targetLevel, target.overlay:GetFrameLevel())
		end
		if container.SetFrameLevel then container:SetFrameLevel(targetLevel + 1) end
	end
	container:SetUnit(state.unitToken)
	-- AddAuraSlot owns exactly one AuraButton. Configured aura IDs and their
	-- aliases are candidate identities for that slot; they cannot exceed 1.
	local slot = AuraCompat:RegisterAuraSlot(container, SLOT_KEY, state.filterString, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = state.includeSpellIDs },
		initializeFrame = createOverlayInitializer(
			state.mode,
			state.entry,
			state.layout,
			state.durationTextProfile,
			width,
			height,
			state.preserveHostVisual,
			state.useActivationColor,
			state.sourceIconTexture
		),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return false
	end
	if not AuraContainers:RegisterStackThresholdSlots(container, state, slotHost, width, height) then
		AuraCompat:DisableAuraContainer(container)
		return false
	end

	local oldContainer = state.container
	state.container = container
	state.slot = slot
	state.slotHost = slotHost
	state.displayTarget = target
	state.geometryWidth = width
	state.geometryHeight = height
	if oldContainer then
		AuraCompat:DisableAuraContainer(oldContainer)
		oldContainer:SetAlpha(0)
	end
	AuraCompat:RefreshAuraContainer(container, state.unitToken)
	return true
end

local function attachState(state, refreshUnitToken)
	if not state then return end
	if state.dynamicOwner and state.dynamicOwner.enabled == true then
		AuraContainers:UntrackStateGeometry(state)
		return
	end
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[state.panelId]
	local panelFrame = runtime and runtime.frame
	AuraContainers:EnsurePanelVisibilityHook(panelFrame)
	local layoutEditActive = CooldownPanels:IsPanelLayoutEditActive(state.panelId)
	local icon = runtime and runtime.entryToIcon and runtime.entryToIcon[state.entryId]
	if AuraContainers:IsTrackedAuraSuppressed(state.unitToken, state.filterString) then
		AuraContainers:CancelStateGeometryRefresh(state)
		if state.container and state.auraIdentitySuppressed ~= true then
			AuraCompat:DisableAuraContainer(state.container)
			state.auraIdentitySuppressed = true
		end
		AuraContainers:ApplySuppressedHost(state, icon, layoutEditActive)
		return
	elseif state.auraIdentitySuppressed then
		if not state.container or AuraCompat:RefreshAuraContainer(state.container, state.unitToken) then state.auraIdentitySuppressed = nil end
	elseif refreshUnitToken == state.unitToken and state.container then
		AuraCompat:RefreshAuraContainer(state.container, state.unitToken)
	end
	local target = nil
	if icon and state.mode == "BAR" and icon._eqolBarsFrame then
		target = icon._eqolBarsFrame.body or icon._eqolBarsFrame.fill
	elseif icon and state.mode == "BUTTON" then
		target = icon
	end
	if icon ~= state.displayIcon then
		state.displayIcon = icon
	end
	if target and (state.kind == STATE_KIND_OVERLAY or not layoutEditActive) then
		AuraContainers:TrackStateGeometry(state, target)
		local width = target.GetWidth and target:GetWidth() or nil
		local height = target.GetHeight and target:GetHeight() or nil
		if type(width) == "number" and width >= 1 and type(height) == "number" and height >= 1 then
			local geometryChanged = state.geometryWidth ~= width or state.geometryHeight ~= height
			local initializeState = state.kind == STATE_KIND_ENTRY and initializeEntryState or initializeOverlayState
			local refreshGeometry = AuraContainers:StateNeedsGeometryRefresh(state)
			local targetChanged = state.container and state.displayTarget ~= target
			if not state.container or targetChanged then
				AuraContainers:CancelStateGeometryRefresh(state)
				initializeState(state, target, width, height)
			elseif refreshGeometry and geometryChanged then
				AuraContainers:ScheduleStateGeometryRefresh(state, target)
			else
				AuraContainers:CancelStateGeometryRefresh(state)
				state.geometryWidth = width
				state.geometryHeight = height
			end
		end
	else
		AuraContainers:UntrackStateGeometry(state)
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
			applyOverlayHostVisibility(state, icon, layoutEditActive)
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
		applyOverlayHostVisibility(state, icon, false)
	elseif state.mode == "BAR" then
		local barFrame = icon and icon._eqolBarsFrame
		if barFrame then barFrame:SetAlpha(state.showInactive and 1 or 0) end
	elseif icon then
		icon:SetAlpha(state.showInactive and 1 or 0)
	end
	local panelVisible = panelFrame and panelFrame.IsVisible and panelFrame:IsVisible() == true
	if panelVisible and panelFrame.GetAlpha then
		local panelAlpha = panelFrame:GetAlpha()
		if type(panelAlpha) == "number" and panelAlpha <= 0 then panelVisible = false end
	end
	if panelVisible and target and state.displayTarget == target then
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
			-- A native overlay is a complete secret-shown replacement. Keep it above
			-- the host cooldown and text; the layout handle remains higher still.
			local targetLevel = target.GetFrameLevel and target:GetFrameLevel() or 0
			if state.kind == STATE_KIND_OVERLAY and target.overlay and target.overlay.GetFrameLevel then
				targetLevel = math.max(targetLevel, target.overlay:GetFrameLevel())
			end
			if state.container.SetFrameLevel then state.container:SetFrameLevel(targetLevel + 1) end
		end
		state.container:SetAlpha(1)
	else
		state.container:SetAlpha(0)
	end
end

function AuraContainers:ScheduleStateGeometryRefresh(state, target)
	if
		not (state and target)
		or state.disabled
		or state.geometryTarget ~= target
		or not self:StateNeedsGeometryRefresh(state)
		or (state.dynamicOwner and state.dynamicOwner.enabled == true)
	then
		return
	end
	local width = target.GetWidth and target:GetWidth() or nil
	local height = target.GetHeight and target:GetHeight() or nil
	if type(width) ~= "number" or width < 1 or type(height) ~= "number" or height < 1 then
		self:CancelStateGeometryRefresh(state)
		return
	end
	self:CancelStateGeometryRefresh(state)
	state.pendingGeometryWidth = width
	state.pendingGeometryHeight = height
	state.geometryTimer = C_Timer.NewTimer(0.25, function()
		state.geometryTimer = nil
		if
			state.disabled
			or state.geometryTarget ~= target
			or (state.dynamicOwner and state.dynamicOwner.enabled == true)
			or AuraContainers:IsTrackedAuraSuppressed(state.unitToken, state.filterString)
		then
			AuraContainers:CancelStateGeometryRefresh(state)
			return
		end
		local currentWidth = target.GetWidth and target:GetWidth() or nil
		local currentHeight = target.GetHeight and target:GetHeight() or nil
		if type(currentWidth) ~= "number" or currentWidth < 1 or type(currentHeight) ~= "number" or currentHeight < 1 then
			AuraContainers:CancelStateGeometryRefresh(state)
			return
		end
		if math.abs(currentWidth - (state.pendingGeometryWidth or currentWidth)) > 0.01 or math.abs(currentHeight - (state.pendingGeometryHeight or currentHeight)) > 0.01 then
			AuraContainers:ScheduleStateGeometryRefresh(state, target)
			return
		end
		if state.displayTarget == target and state.geometryWidth == currentWidth and state.geometryHeight == currentHeight then
			AuraContainers:CancelStateGeometryRefresh(state)
			attachState(state)
			return
		end
		local initializeState = state.kind == STATE_KIND_ENTRY and initializeEntryState or initializeOverlayState
		local initialized = initializeState(state, target, currentWidth, currentHeight)
		AuraContainers:CancelStateGeometryRefresh(state)
		if initialized then attachState(state) end
	end)
end

function AuraContainers:SyncPanelStates(panelId, panelStates)
	panelId = tonumber(panelId) or panelId
	if panelId == nil then return end
	if not self:PanelCanOwnStates(panelId) then
		self:ReleasePanelStates(panelId)
		return
	end
	if not panelStates then
		panelStates = {}
		for _, state in pairs(states) do
			if (tonumber(state.panelId) or state.panelId) == panelId and not state.disabled then panelStates[#panelStates + 1] = state end
		end
	end
	for i = 1, #panelStates do
		local state = panelStates[i]
		if state and not state.disabled then attachState(state) end
	end
	local panelGroups = self.dynamicGroupsByPanel[panelId]
	if panelGroups then
		local owners = {}
		for _, owner in pairs(panelGroups) do owners[#owners + 1] = owner end
		for i = 1, #owners do
			local owner = owners[i]
			if owner.enabled == true and not self:ShowDynamicGroup(owner) then self:InvalidateDynamicGroup(owner, true) end
		end
	end
end

function AuraContainers:EndPanelBuild(panelId, token)
	panelId = tonumber(panelId) or panelId
	if panelId == nil or token == nil then return end
	if self.panelBuildTokens[panelId] ~= token then return end
	local depth = self.panelBuildDepths[panelId] or 1
	if depth > 1 then
		self.panelBuildDepths[panelId] = depth - 1
		return
	end
	self.panelBuildTokens[panelId] = nil
	self.panelBuildDepths[panelId] = nil
	local current = {}
	local stale = {}
	for _, state in pairs(states) do
		if (tonumber(state.panelId) or state.panelId) == panelId then
			if state.buildToken == token and not state.disabled then
				current[#current + 1] = state
			else
				stale[#stale + 1] = state
			end
		end
	end
	for i = 1, #stale do self:RemoveState(stale[i]) end
	self:SyncPanelStates(panelId, current)
end

function AuraContainers:GetDynamicGroupKey(panelId, groupId)
	return tostring(panelId) .. ":" .. tostring(groupId)
end

function AuraContainers:GetDynamicGroupMemberIds(panel, groupId)
	local memberIds = {}
	for _, entryId in ipairs(panel and panel.order or {}) do
		local entry = panel.entries and panel.entries[entryId]
		if entry and entry.fixedGroupId == groupId and (not CooldownPanels.EntryAllowsSpec or CooldownPanels.EntryAllowsSpec(entry)) then memberIds[#memberIds + 1] = entryId end
	end
	return memberIds
end

function AuraContainers:GetEntryAuraStates(panelId, entryId)
	local entryStates = {}
	for _, state in pairs(states) do
		if
			state.kind == STATE_KIND_ENTRY
			and tostring(state.panelId) == tostring(panelId)
			and tostring(state.entryId) == tostring(entryId)
			and not state.disabled
		then
			entryStates[#entryStates + 1] = state
		end
	end
	table.sort(entryStates, function(left, right)
		local leftIndex = tonumber(left.partyIndex) or 1
		local rightIndex = tonumber(right.partyIndex) or 1
		if leftIndex ~= rightIndex then return leftIndex < rightIndex end
		return tostring(left.key) < tostring(right.key)
	end)
	return entryStates
end

function AuraContainers:ResolveGridGroupPlan(panelId)
	local panel = CooldownPanels:GetPanel(panelId)
	local layout = panel and panel.layout
	if not (panel and type(layout) == "table") then return nil end
	if Helper.NormalizeLayoutMode(layout.layoutMode, Helper.PANEL_LAYOUT_DEFAULTS.layoutMode) ~= "GRID" then return nil end
	if CooldownPanels:IsPanelLayoutEditActive(panelId) then return nil end

	local direction = Helper.NormalizeDirection(layout.direction, Helper.PANEL_LAYOUT_DEFAULTS.direction)
	local horizontal = direction == "RIGHT" or direction == "LEFT"
	local wrapDirection = Helper.NormalizeDirection(layout.wrapDirection, Helper.PANEL_LAYOUT_DEFAULTS.wrapDirection or "DOWN")
	if horizontal then
		wrapDirection = wrapDirection == "UP" and "UP" or "DOWN"
	else
		wrapDirection = wrapDirection == "LEFT" and "LEFT" or "RIGHT"
	end
	local growthPoint = Helper.NormalizeGrowthPoint(layout.growthPoint, Helper.PANEL_LAYOUT_DEFAULTS.growthPoint)
	local centered = growthPoint == "TOP"
	local wrapCount = Helper.ClampInt(layout.wrapCount, 0, 40, Helper.PANEL_LAYOUT_DEFAULTS.wrapCount or 0)
	local wraps = wrapCount > 0
	-- Centering a wrapped vertical grid would require aligning the final partial
	-- column from its secret visible aura count. Non-wrapping columns can keep
	-- their primary-axis center anchored entirely through Blizzard's layout.
	if centered and not horizontal and wraps then return nil end
	-- Right-aligned partial rows require addon-side alignment from the secret
	-- visible count. Center growth instead follows the native container bounds.
	if wraps and growthPoint == "TOPRIGHT" then return nil end
	-- Per-row sizes depend on the resulting wrapped row assignment. Without
	-- wrapping there is only one effective row, so its uniform override remains
	-- compatible with Blizzard's secret-sized native container layout.
	if wraps and type(layout.rowSizes) == "table" and next(layout.rowSizes) then return nil end
	local spacing = Helper.ClampInt(layout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0)

	local memberIds = {}
	local auraStates = {}
	local signatureParts = {
		"GRID",
		direction,
		wrapDirection,
		growthPoint,
		tostring(wrapCount),
		tostring(spacing),
	}
	local sharedWidth
	local sharedHeight
	local sharedOffsetX
	local sharedOffsetY
	local sharedUnitToken
	local geometryTolerance = 0.01
	for _, entryId in ipairs(panel.order or {}) do
		local entry = panel.entries and panel.entries[entryId]
		if entry and (not CooldownPanels.EntryAllowsSpec or CooldownPanels.EntryAllowsSpec(entry)) then
			-- One native FlowLayout can pack only AuraGroup frames. Mixed Spell,
			-- Item or bar grids stay on the regular renderer.
			if entry.type ~= ENTRY_TYPE or entry.displayMode == "BAR" then return nil end
			local entryStates = self:GetEntryAuraStates(panelId, entryId)
			if #entryStates == 0 then return nil end
			memberIds[#memberIds + 1] = entryId
			for i = 1, #entryStates do
				local state = entryStates[i]
				if
					state.showInactive == true
					or type(state.geometryWidth) ~= "number"
					or state.geometryWidth < 1
					or type(state.geometryHeight) ~= "number"
					or state.geometryHeight < 1
				then
					return nil
				end
				sharedWidth = sharedWidth or state.geometryWidth
				sharedHeight = sharedHeight or state.geometryHeight
				sharedOffsetX = sharedOffsetX or state.visualOffsetX
				sharedOffsetY = sharedOffsetY or state.visualOffsetY
				sharedUnitToken = sharedUnitToken or state.unitToken
				-- Different units require separate AuraContainers. Those runs can be
				-- chained without gaps in one dimension, but cannot share a secret wrap count.
				if
					math.abs(state.geometryWidth - sharedWidth) > geometryTolerance
					or math.abs(state.geometryHeight - sharedHeight) > geometryTolerance
					or math.abs((state.visualOffsetX or 0) - (sharedOffsetX or 0)) > geometryTolerance
					or math.abs((state.visualOffsetY or 0) - (sharedOffsetY or 0)) > geometryTolerance
					or wraps and state.unitToken ~= sharedUnitToken
				then
					return nil
				end
				auraStates[#auraStates + 1] = state
				signatureParts[#signatureParts + 1] = table.concat({
					tostring(entryId),
					state.signature,
					tostring(state.geometryWidth),
					tostring(state.geometryHeight),
					tostring(state.unitToken),
					tostring(state.filterString),
				}, "@")
			end
		end
	end
	if #auraStates == 0 then return nil end
	local primarySize = horizontal and sharedWidth or sharedHeight
	local centerRowCount = centered and math.min(wraps and wrapCount or #memberIds, #memberIds) or 0
	local centerOffsetX = 0
	local centerOffsetY = 0
	local centeredStartPoint
	local flowAnchorPoint = growthPoint
	if centered then
		if horizontal then
			centerOffsetX = ((centerRowCount - 1) * (sharedWidth + spacing)) / 2
			if direction == "LEFT" then centerOffsetX = -centerOffsetX end
			centeredStartPoint = "TOP"
			flowAnchorPoint = direction == "LEFT" and "TOPRIGHT" or "TOPLEFT"
		else
			centerOffsetY = ((centerRowCount - 1) * (sharedHeight + spacing)) / 2
			if direction == "DOWN" then centerOffsetY = -centerOffsetY end
			centeredStartPoint = "LEFT"
			flowAnchorPoint = direction == "UP" and "BOTTOMLEFT" or "TOPLEFT"
		end
	end

	return {
		panelId = panelId,
		panel = panel,
		groupId = self.GRID_GROUP_ID,
		memberIds = memberIds,
		auraStates = auraStates,
		effectiveLayout = layout,
		spacing = spacing,
		startPoint = centeredStartPoint or growthPoint,
		flowAnchorPoint = flowAnchorPoint,
		direction = direction,
		wrapDirection = wrapDirection,
		horizontal = horizontal,
		wraps = wraps,
		maximumLineSize = math.huge,
		flowPrimaryCount = wraps and wrapCount or nil,
		flowPrimarySize = wraps and primarySize or nil,
		baseIndex = 1,
		centered = centered,
		centerOffsetX = centerOffsetX,
		centerOffsetY = centerOffsetY,
		keepLayoutHosts = true,
		layoutKind = "GRID",
		signature = table.concat(signatureParts, "\031"),
	}
end

function AuraContainers:ResolveDynamicGroupPlan(panelId, groupId)
	local panel = CooldownPanels:GetPanel(panelId)
	local layout = panel and panel.layout
	if not (panel and type(layout) == "table" and Helper.IsFixedLayout and Helper.IsFixedLayout(layout)) then return nil end
	if CooldownPanels:IsPanelLayoutEditActive(panelId) then return nil end
	local group = Helper.GetFixedGroupById and Helper.GetFixedGroupById(panel, groupId) or nil
	if not group or Helper.FixedGroupUsesStaticSlots(group) == true then return nil end

	local columns = Helper.NormalizeFixedGridSize(group.columns, 0)
	local rows = Helper.NormalizeFixedGridSize(group.rows, 0)
	local startPoint = Helper.NormalizeFixedGroupStartPoint(group.dynamicStartPoint, "TOPLEFT")
	local direction = Helper.NormalizeFixedGroupDynamicDirection(startPoint, group.dynamicDirection, nil)
	local centered = direction == "CENTER" and (startPoint == "TOP" or startPoint == "BOTTOM")
	local horizontal = centered or direction == "RIGHT" or direction == "LEFT"
	local vertical = direction == "UP" or direction == "DOWN"
	if not horizontal and not vertical then return nil end
	local wraps = (horizontal and rows > 1) or (vertical and columns > 1)

	local fixedLayoutCache = Helper.GetFixedLayoutCache and Helper.GetFixedLayoutCache(panel) or nil
	local effectiveLayout = layout
	if group.layoutOverrides then
		effectiveLayout = CooldownPanels:GetFixedGroupEffectiveLayout(panelId, group, {}, panel, layout, fixedLayoutCache) or layout
	end
	local spacing = Helper.ClampInt(effectiveLayout and effectiveLayout.spacing, 0, Helper.SPACING_RANGE or 200, Helper.PANEL_LAYOUT_DEFAULTS.spacing or 0)
	local targetIndices = Helper.GetFixedGroupDynamicTargetIndices and Helper.GetFixedGroupDynamicTargetIndices(group) or nil
	local baseIndex = targetIndices and targetIndices[1] or nil
	if not baseIndex then return nil end
	local configuredMemberIds = self:GetDynamicGroupMemberIds(panel, group.id)
	local memberIds = {}
	local capacity = Helper.GetFixedGroupCapacity and Helper.GetFixedGroupCapacity(group) or #configuredMemberIds
	for i = 1, math.min(#configuredMemberIds, capacity) do
		-- Match the normal fixed-group runtime: entries beyond an unavailable
		-- target cell do not participate in the live dynamic chain.
		if not targetIndices[i] then break end
		memberIds[#memberIds + 1] = configuredMemberIds[i]
	end
	local auraStates = {}
	local signatureParts = {
		tostring(group.id), tostring(group.column), tostring(group.row), tostring(columns), tostring(rows), startPoint, direction, tostring(spacing),
	}
	local sharedWidth
	local sharedHeight
	local sharedOffsetX
	local sharedOffsetY
	local sharedUnitToken
	local geometryTolerance = 0.01
	for i = 1, #memberIds do
		local entryId = memberIds[i]
		local entry = panel.entries and panel.entries[entryId]
		-- Blizzard's secret-safe FlowLayout can only place AuraGroup frames. A
		-- Spell/Item frame cannot join that layout, and an anchor chain cannot
		-- calculate a secret row wrap. Keep dynamic ownership limited to pure
		-- tracked-aura groups rather than leaving a forbidden mixed dependency.
		if not entry or entry.type ~= ENTRY_TYPE or entry.displayMode == "BAR" then return nil end
		signatureParts[#signatureParts + 1] = tostring(entryId)
		local alwaysShowMode = CooldownPanels:ResolveEntryCDMAuraAlwaysShowMode(effectiveLayout, entry)
		if CooldownPanels:IsCDMAuraAlwaysShowModeVisibleWhenInactive(alwaysShowMode) then return nil end
		local entryStates = self:GetEntryAuraStates(panelId, entryId)
		if #entryStates == 0 then return nil end
		for stateIndex = 1, #entryStates do
			local state = entryStates[stateIndex]
			if not (type(state.geometryWidth) == "number" and state.geometryWidth >= 1 and type(state.geometryHeight) == "number" and state.geometryHeight >= 1) then return nil end
			-- Native FlowLayout can reproduce the existing fixed-grid placement only
			-- when every visual consumes the same square cell and uses the same
			-- configured icon offset. More exotic per-entry geometry safely keeps the
			-- existing fixed-slot renderer instead of jumping relative to its preview.
			sharedWidth = sharedWidth or state.geometryWidth
			sharedHeight = sharedHeight or state.geometryHeight
			sharedOffsetX = sharedOffsetX or state.visualOffsetX
			sharedOffsetY = sharedOffsetY or state.visualOffsetY
			sharedUnitToken = sharedUnitToken or state.unitToken
			-- Different units require separate AuraContainers. Those runs can be
			-- chained without gaps in one dimension, but cannot share a secret wrap count.
			if
				math.abs(state.geometryWidth - sharedWidth) > geometryTolerance
				or math.abs(state.geometryHeight - sharedHeight) > geometryTolerance
				or math.abs(state.geometryWidth - state.geometryHeight) > geometryTolerance
				or math.abs((state.visualOffsetX or 0) - (sharedOffsetX or 0)) > geometryTolerance
				or math.abs((state.visualOffsetY or 0) - (sharedOffsetY or 0)) > geometryTolerance
				or wraps and state.unitToken ~= sharedUnitToken
			then
				return nil
			end
			auraStates[#auraStates + 1] = state
			signatureParts[#signatureParts + 1] = table.concat({ state.signature, tostring(state.geometryWidth), tostring(state.geometryHeight) }, "@")
		end
	end
	if #auraStates == 0 then return nil end
	local primaryCount = horizontal and columns or rows
	local primarySize = horizontal and auraStates[1].geometryWidth or auraStates[1].geometryHeight
	local centerRowCount = centered and math.min(columns, #memberIds) or 0
	local centerOffsetX = centered and (((centerRowCount - 1) * (auraStates[1].geometryWidth + spacing)) / 2) or 0

	return {
		panelId = panelId,
		panel = panel,
		group = group,
		groupId = group.id,
		memberIds = memberIds,
		auraStates = auraStates,
		effectiveLayout = effectiveLayout,
		spacing = spacing,
		startPoint = startPoint,
		flowAnchorPoint = centered and (startPoint == "BOTTOM" and "BOTTOMLEFT" or "TOPLEFT") or startPoint,
		direction = direction,
		horizontal = horizontal,
		wraps = wraps,
		maximumLineSize = math.huge,
		flowPrimaryCount = wraps and primaryCount or nil,
		flowPrimarySize = wraps and primarySize or nil,
		baseIndex = baseIndex,
		centered = centered,
		centerOffsetX = centerOffsetX,
		signature = table.concat(signatureParts, "\031"),
	}
end

function AuraContainers:ResolveOwnedDynamicGroupPlan(panelId, groupId)
	if groupId == self.GRID_GROUP_ID then return self:ResolveGridGroupPlan(panelId) end
	return self:ResolveDynamicGroupPlan(panelId, groupId)
end

function AuraContainers:CaptureFrameLayout(frame)
	if not (frame and frame.GetNumPoints and frame.GetPoint and frame.GetSize) then return nil end
	local width, height = frame:GetSize()
	if AuraCompat:IsSecretValue(width) or AuraCompat:IsSecretValue(height) then return nil end
	local snapshot = { width = width, height = height, points = {} }
	for index = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = frame:GetPoint(index)
		if AuraCompat:IsSecretValue(x) or AuraCompat:IsSecretValue(y) then return nil end
		snapshot.points[#snapshot.points + 1] = { point, relativeTo, relativePoint, x or 0, y or 0 }
	end
	return snapshot
end

function AuraContainers:ApplyFrameLayout(frame, snapshot, offsetX, offsetY)
	if not (frame and snapshot) then return false end
	offsetX = tonumber(offsetX) or 0
	offsetY = tonumber(offsetY) or 0
	frame:ClearAllPoints()
	for i = 1, #(snapshot.points or {}) do
		local point = snapshot.points[i]
		frame:SetPoint(point[1], point[2], point[3], (point[4] or 0) + offsetX, (point[5] or 0) + offsetY)
	end
	if type(snapshot.width) == "number" and type(snapshot.height) == "number" then frame:SetSize(snapshot.width, snapshot.height) end
	return true
end

function AuraContainers:ReleaseStandaloneRenderer(state)
	if not state then return end
	self:UntrackStateGeometry(state)
	if state.container then
		AuraCompat:DisableAuraContainer(state.container)
		state.container:SetAlpha(0)
	end
	state.container = nil
	state.slot = nil
	state.slotHost = nil
	state.auraGroupKey = nil
	state.displayIcon = nil
	state.displayTarget = nil
	state.pendingGeometryWidth = nil
	state.pendingGeometryHeight = nil
end

function AuraContainers:InvalidateDynamicGroup(owner, requestRefresh)
	if not owner or owner.invalidating then return end
	owner.invalidating = true
	owner.enabled = false
	for i = 1, #(owner.runs or {}) do
		local container = owner.runs[i].container
		if container then AuraCompat:DisableAuraContainer(container) end
	end
	for i = 1, #(owner.auraStates or {}) do
		local state = owner.auraStates[i]
		if state.dynamicOwner == owner then state.dynamicOwner = nil end
	end
	self.dynamicGroups[owner.key] = nil
	local panelGroups = self.dynamicGroupsByPanel[owner.panelId]
	if panelGroups then
		panelGroups[owner.key] = nil
		if not next(panelGroups) then self.dynamicGroupsByPanel[owner.panelId] = nil end
	end
	owner.invalidating = nil
	if requestRefresh and CooldownPanels.RequestPanelRefresh then CooldownPanels:RequestPanelRefresh(owner.panelId) end
end

function AuraContainers:GetDynamicAnchorPoints(startPoint, direction)
	if direction == "LEFT" then return startPoint, startPoint == "TOPRIGHT" and "TOPLEFT" or "BOTTOMLEFT", -1, 0 end
	if direction == "DOWN" then return startPoint, startPoint == "TOPLEFT" and "BOTTOMLEFT" or "BOTTOMRIGHT", 0, -1 end
	if direction == "UP" then return startPoint, startPoint == "BOTTOMLEFT" and "TOPLEFT" or "TOPRIGHT", 0, 1 end
	return startPoint, startPoint == "TOPLEFT" and "TOPRIGHT" or "BOTTOMRIGHT", 1, 0
end

function AuraContainers:AttachDynamicGroup(owner)
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[owner.panelId]
	local panelFrame = runtime and runtime.frame
	local baseIcon = panelFrame and panelFrame.icons and panelFrame.icons[owner.baseIndex]
	-- Clone the actual visual icon rectangle, not its larger fixed-grid slot.
	-- This preserves the configured icon offset and any pixel-snapped geometry
	-- while keeping the unrestricted slot anchor out of the forbidden chain.
	local baseFrame = baseIcon
	if not (panelFrame and baseFrame) then return false end

	-- The regular icon is reset to panel defaults after native ownership hides
	-- its fixed slot. Preserve the correctly styled first-pass geometry for all
	-- later refreshes; a signature change rebuilds the owner and this snapshot.
	local baseSnapshot = owner.baseSnapshot or self:CaptureFrameLayout(baseFrame)
	if not baseSnapshot then return false end
	owner.baseSnapshot = baseSnapshot
	if not owner.origin then owner.origin = CreateFrame("Frame", nil, panelFrame) end
	self:ApplyFrameLayout(owner.origin, baseSnapshot, owner.centerOffsetX, owner.centerOffsetY)

	if owner.centered then
		-- Separate containers cannot be centered as one secret-sized run without
		-- reading their bounds. Keep center ownership native only when every group
		-- can participate in the same Blizzard FlowLayout.
		if #owner.runs ~= 1 then return false end
		local container = owner.runs[1].container
		container:ClearAllPoints()
		container:SetPoint(owner.startPoint, owner.origin, owner.startPoint)
		if container.SetFrameStrata and panelFrame.GetFrameStrata then container:SetFrameStrata(panelFrame:GetFrameStrata()) end
		if container.SetFrameLevel then container:SetFrameLevel((panelFrame:GetFrameLevel() or 0) + 5) end
		return self:ShowDynamicGroup(owner)
	end

	local leadingPoint, trailingPoint, growthX, growthY = self:GetDynamicAnchorPoints(owner.startPoint, owner.direction)
	local previousFrame = owner.origin
	local previousKind = "ORIGIN"
	for i = 1, #owner.nodes do
		local node = owner.nodes[i]
		local nodeFrame = node.run and node.run.container or nil
		if nodeFrame then
			local offsetX, offsetY = 0, 0
			if previousKind ~= "ORIGIN" then
				-- A non-final run owns an invisible conditional sentinel. Its
				-- spacing+1 extent exists only while at least one aura in that run
				-- is visible; cancel the container's unavoidable one-pixel minimum.
				offsetX = -growthX
				offsetY = -growthY
			end
			nodeFrame:ClearAllPoints()
			nodeFrame:SetPoint(leadingPoint, previousFrame, previousKind == "ORIGIN" and leadingPoint or trailingPoint, offsetX, offsetY)
			previousFrame = nodeFrame
			previousKind = "RUN"
		end
	end

	for i = 1, #owner.runs do
		local container = owner.runs[i].container
		if container.SetFrameStrata and panelFrame.GetFrameStrata then container:SetFrameStrata(panelFrame:GetFrameStrata()) end
		if container.SetFrameLevel then container:SetFrameLevel((panelFrame:GetFrameLevel() or 0) + 5) end
	end
	return self:ShowDynamicGroup(owner)
end

function AuraContainers:ShowDynamicGroup(owner, refreshUnitToken)
	if not owner then return false end
	for i = 1, #(owner.runs or {}) do
		local run = owner.runs[i]
		local container = run.container
		if not container then return false end
		local suppressed = self:IsTrackedAuraSuppressed(run.unitToken, run.filterString)
		if suppressed then
			if run.auraIdentitySuppressed ~= true then
				AuraCompat:DisableAuraContainer(container)
				run.auraIdentitySuppressed = true
			end
			container:SetAlpha(0)
		elseif run.auraIdentitySuppressed then
			if not AuraCompat:RefreshAuraContainer(container, run.unitToken) then return false end
			run.auraIdentitySuppressed = nil
			container:SetAlpha(1)
		else
			if refreshUnitToken == run.unitToken then
				AuraCompat:RefreshAuraContainer(container, run.unitToken)
			end
			container:SetAlpha(1)
			container:Show()
		end
	end
	return true
end

function AuraContainers:HideDynamicGroupHosts(owner)
	if not (owner and owner.keepLayoutHosts == true) then return end
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[owner.panelId]
	local entryToIcon = runtime and runtime.entryToIcon
	if not entryToIcon then return end
	for i = 1, #(owner.memberIds or {}) do
		local icon = entryToIcon[owner.memberIds[i]]
		if icon then icon:SetAlpha(0) end
	end
end

function AuraContainers:CreateDynamicRun(owner, unitToken, filterString)
	local runtime = CooldownPanels.runtime and CooldownPanels.runtime[owner.panelId]
	local parent = runtime and runtime.frame or UIParent
	local template = tostring(AuraCompat.defaultContainerTemplate or "CustomAuraContainerTemplate") .. ",DisableUntrustedLayoutScriptsTemplate"
	local container = AuraCompat:CreateAuraContainer(parent, nil, template)
	if not container then return nil end
	container:SetAlpha(0)
	container:SetUnit(unitToken)
	local flowAxes = AnchorUtil and AnchorUtil.FlowLayoutAxis
	if not flowAxes then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	local horizontalGrowthDirection
	local verticalGrowthDirection
	if owner.layoutKind == "GRID" then
		if owner.horizontal then
			horizontalGrowthDirection = owner.direction == "LEFT" and -1 or 1
			verticalGrowthDirection = owner.wrapDirection == "UP" and 1 or -1
		else
			horizontalGrowthDirection = owner.wrapDirection == "LEFT" and -1 or 1
			verticalGrowthDirection = owner.direction == "UP" and 1 or -1
		end
	else
		horizontalGrowthDirection = owner.direction == "LEFT" and -1 or 1
		if owner.direction == "UP" then
			verticalGrowthDirection = 1
		elseif owner.direction == "DOWN" then
			verticalGrowthDirection = -1
		else
			verticalGrowthDirection = owner.startPoint:find("BOTTOM", 1, true) and 1 or -1
		end
		if not owner.horizontal then horizontalGrowthDirection = owner.startPoint:find("RIGHT", 1, true) and -1 or 1 end
	end
	local configured = AuraCompat:ConfigureAuraContainerLayout(container, {
		axis = owner.horizontal and flowAxes.Horizontal or flowAxes.Vertical,
		anchorPoint = owner.flowAnchorPoint or owner.startPoint,
		horizontalGrowthDirection = horizontalGrowthDirection,
		verticalGrowthDirection = verticalGrowthDirection,
		maximumLineSize = owner.wraps
			and AuraCompat:GetSafeFlowLayoutMaximumLineSize(container, owner.flowPrimarySize, owner.spacing, owner.flowPrimaryCount)
			or owner.maximumLineSize,
	})
	if not configured then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	local run = {
		container = container,
		unitToken = unitToken,
		filterString = filterString,
		states = {},
		includeSpellIDs = {},
	}
	owner.runs[#owner.runs + 1] = run
	owner.nodes[#owner.nodes + 1] = { kind = "RUN", run = run }
	return run
end

function AuraContainers:RegisterDynamicRun(owner, run, runIndex)
	for i = 1, #run.states do
		local state = run.states[i]
		local registered = AuraCompat:RegisterAuraGroup(run.container, "entry:" .. tostring(state.entryId), state.filterString, {
			maxFrameCount = state.maxFrameCount or 1,
			candidateFilters = { includeSpellIDs = state.includeSpellIDs },
			initializeFrame = createInitializer(
				state.mode,
				state.entry,
				state.layout,
				state.durationTextProfile,
				state.activeDesaturate,
				state.activeGlow,
				state.pandemicGlow,
				state.geometryWidth,
				state.geometryHeight,
				state.showNativeStaticText,
				state.stateTextureData
			),
			layout = {
				elementSpacing = owner.spacing,
				lineSpacing = owner.spacing,
				groupLineSpacing = owner.spacing,
				elementWidth = state.geometryWidth,
				elementHeight = state.geometryHeight,
				layoutIndex = i,
			},
		})
		if not registered then return false end
	end
	if not owner.wraps and runIndex < #owner.runs then
		local sentinelSize = owner.spacing + 1
		local registered = AuraCompat:RegisterAuraGroup(run.container, "spacing-sentinel", run.filterString, {
			maxFrameCount = 1,
			candidateFilters = { includeSpellIDs = run.includeSpellIDs },
			initializeFrame = function(button)
				button:SetSize(1, 1)
				button:SetAlpha(0)
				button:EnableMouse(false)
				if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
				if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end
			end,
			layout = {
				groupSpacing = 0,
				lineSpacing = 0,
				groupLineSpacing = 0,
				elementWidth = owner.horizontal and sentinelSize or 1,
				elementHeight = owner.horizontal and 1 or sentinelSize,
				layoutIndex = #run.states + 1,
			},
		})
		if not registered then return false end
	end

	if self:IsTrackedAuraSuppressed(run.unitToken, run.filterString) then
		AuraCompat:DisableAuraContainer(run.container)
		run.auraIdentitySuppressed = true
	else
		AuraCompat:RefreshAuraContainer(run.container, run.unitToken)
	end
	return true
end

function AuraContainers:BuildDynamicGroup(plan)
	local owner = {
		key = self:GetDynamicGroupKey(plan.panelId, plan.groupId),
		panelId = plan.panelId,
		groupId = plan.groupId,
		group = plan.group,
		panel = plan.panel,
		effectiveLayout = plan.effectiveLayout,
		memberIds = plan.memberIds,
		auraStates = plan.auraStates,
		spacing = plan.spacing,
		startPoint = plan.startPoint,
		flowAnchorPoint = plan.flowAnchorPoint,
		direction = plan.direction,
		wrapDirection = plan.wrapDirection,
		horizontal = plan.horizontal,
		wraps = plan.wraps,
		maximumLineSize = plan.maximumLineSize,
		flowPrimaryCount = plan.flowPrimaryCount,
		flowPrimarySize = plan.flowPrimarySize,
		baseIndex = plan.baseIndex,
		centered = plan.centered == true,
		centerOffsetX = plan.centerOffsetX or 0,
		centerOffsetY = plan.centerOffsetY or 0,
		keepLayoutHosts = plan.keepLayoutHosts == true,
		layoutKind = plan.layoutKind or "FIXED",
		signature = plan.signature,
		runs = {},
		nodes = {},
	}
	local currentRun
	for i = 1, #plan.auraStates do
		local state = plan.auraStates[i]
		if not state then
			self:InvalidateDynamicGroup(owner, false)
			return nil
		end
		if
			not currentRun
			or currentRun.unitToken ~= state.unitToken
			or (not owner.centered and owner.layoutKind ~= "GRID" and not owner.wraps and currentRun.filterString ~= state.filterString)
		then
			-- A wrapped layout must remain one native FlowLayout so its secret
			-- visible count determines row/column wrapping consistently.
			if owner.wraps and currentRun then
				self:InvalidateDynamicGroup(owner, false)
				return nil
			end
			currentRun = self:CreateDynamicRun(owner, state.unitToken, state.filterString)
			if not currentRun then
				self:InvalidateDynamicGroup(owner, false)
				return nil
			end
		end
		currentRun.states[#currentRun.states + 1] = state
		for spellID in pairs(state.includeSpellIDs or {}) do currentRun.includeSpellIDs[spellID] = true end
	end
	if not self:AttachDynamicGroup(owner) then
		self:InvalidateDynamicGroup(owner, false)
		return nil
	end
	for i = 1, #owner.runs do
		if not self:RegisterDynamicRun(owner, owner.runs[i], i) then
			self:InvalidateDynamicGroup(owner, false)
			return nil
		end
	end
	owner.enabled = true
	self.dynamicGroups[owner.key] = owner
	self.dynamicGroupsByPanel[owner.panelId] = self.dynamicGroupsByPanel[owner.panelId] or {}
	self.dynamicGroupsByPanel[owner.panelId][owner.key] = owner
	for i = 1, #owner.auraStates do
		local state = owner.auraStates[i]
		state.dynamicOwner = owner
		self:ReleaseStandaloneRenderer(state)
	end
	self:HideDynamicGroupHosts(owner)
	if CooldownPanels.RequestPanelRefresh then CooldownPanels:RequestPanelRefresh(owner.panelId) end
	return owner
end

function AuraContainers:PrepareDynamicGroups(panelId)
	local panelGroups = self.dynamicGroupsByPanel[panelId]
	if not panelGroups then return end
	local owners = {}
	for _, owner in pairs(panelGroups) do owners[#owners + 1] = owner end
	for i = 1, #owners do
		local owner = owners[i]
		for runIndex = 1, #owner.runs do owner.runs[runIndex].container:SetAlpha(0) end
		local plan = self:ResolveOwnedDynamicGroupPlan(panelId, owner.groupId)
		if not plan or plan.signature ~= owner.signature then self:InvalidateDynamicGroup(owner, false) end
	end
end

function AuraContainers:FinalizeDynamicGroupPlan(plan, seen)
	if not plan then return nil end
	local key = self:GetDynamicGroupKey(plan.panelId, plan.groupId)
	local owner = self.dynamicGroups[key]
	if owner and owner.signature ~= plan.signature then
		self:InvalidateDynamicGroup(owner, false)
		owner = nil
	end
	if not owner then
		owner = self:BuildDynamicGroup(plan)
	else
		owner.panel = plan.panel
		owner.effectiveLayout = plan.effectiveLayout
		-- AddAuraGroup makes the container's layout dependency immutable.
		-- Existing owners only need to become visible again; any geometry or
		-- anchor change is represented in the signature and rebuilds above.
		if not self:ShowDynamicGroup(owner) then
			self:InvalidateDynamicGroup(owner, true)
			owner = nil
		end
	end
	if owner then
		self:HideDynamicGroupHosts(owner)
		seen[key] = true
	end
	return owner
end

function AuraContainers:FinalizeDynamicGroups(panelId)
	local panel = CooldownPanels:GetPanel(panelId)
	local layout = panel and panel.layout
	if not (panel and layout) or CooldownPanels:IsPanelLayoutEditActive(panelId) then return end
	local layoutMode = Helper.NormalizeLayoutMode(layout.layoutMode, Helper.PANEL_LAYOUT_DEFAULTS.layoutMode)
	local seen = {}
	if layoutMode == "GRID" then
		self:FinalizeDynamicGroupPlan(self:ResolveGridGroupPlan(panelId), seen)
	elseif layoutMode == "FIXED" then
		local groups = Helper.NormalizeFixedGroups(layout)
		for i = 1, #groups do
			local group = groups[i]
			if group and Helper.FixedGroupUsesStaticSlots(group) ~= true then
				self:FinalizeDynamicGroupPlan(self:ResolveDynamicGroupPlan(panelId, group.id), seen)
			end
		end
	end
	local panelGroups = self.dynamicGroupsByPanel[panelId]
	if panelGroups then
		local stale = {}
		for key, owner in pairs(panelGroups) do if not seen[key] then stale[#stale + 1] = owner end end
		for i = 1, #stale do self:InvalidateDynamicGroup(stale[i], false) end
	end
	if next(seen) then
		local runtime = CooldownPanels.runtime and CooldownPanels.runtime[panelId]
		if runtime and (tonumber(runtime.visibleCount) or 0) < 1 then runtime.visibleCount = 1 end
	end
end

local originalBuildRuntimeData = CDMAuras.BuildRuntimeData
local originalNormalizeEntry = CDMAuras.NormalizeEntry

function CDMAuras:NormalizeEntry(entry, defaults)
	if originalNormalizeEntry then originalNormalizeEntry(self, entry, defaults) end
	if not (entry and entry.type == ENTRY_TYPE) then return end
	local auraPresets = CooldownPanels.AuraPresets
	if auraPresets and auraPresets.NormalizeEntry then auraPresets:NormalizeEntry(entry) end
	local spellID = getAuraSpellID(entry)
	if not spellID then return end
	entry.auraSpellID = spellID
	entry.spellID = spellID
	entry.cdmAuraOverlaySpellIDs = Helper.NormalizeSpellIDList(entry.cdmAuraOverlaySpellIDs)
	-- PTR4 AuraSlots identify the aura by Spell ID. The old Cooldown Manager
	-- tracking ID is no longer runtime or persistence state on 12.1.
	entry.cooldownID = nil
	entry.auraBackend = "AURA_CONTAINER"
	entry.auraUnit = Helper.NormalizeAuraUnit(entry.auraUnit)
	if entry.auraUnit == "target" then
		entry.auraFilter = entry.auraFilter == "HARMFUL" and "HARMFUL" or TARGET_FILTER_STRING
	elseif Helper.IsAuraGroupUnit(entry.auraUnit) then
		entry.auraFilter = AuraContainers.GROUP_FILTER_STRING
	else
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

function CDMAuras:BuildSlotAuraOverlayData(panelId, entryId, sourceEntry, itemID, entryLayout)
	return AuraContainers:BuildSlotAuraOverlayData(panelId, entryId, sourceEntry, itemID, entryLayout)
end

function CDMAuras:UpdateEventRegistration()
	if self.eventFrame then self.eventFrame:UnregisterAllEvents() end
	self.eventsRegistered = nil
	return false
end

function CDMAuras:CreateEntryData(idValue, overrides, defaults)
	local presetKey = type(idValue) == "table" and idValue.auraPresetKey or type(overrides) == "table" and overrides.auraPresetKey or nil
	local auraPresets = CooldownPanels.AuraPresets
	local presetSpellID = auraPresets and auraPresets.GetPrimarySpellID and auraPresets:GetPrimarySpellID(presetKey) or nil
	local spellID = tonumber(presetSpellID or type(idValue) == "table" and (idValue.auraSpellID or idValue.spellID) or idValue)
	if not spellID or not getSpellName(spellID) then return nil end
	local entryDefaults = (defaults and defaults.entry) or Helper.ENTRY_DEFAULTS or {}
	local entry = Helper.CopyTableShallow(entryDefaults)
	for key, value in pairs(Helper.ENTRY_DEFAULTS or {}) do if entry[key] == nil then entry[key] = value end end
	entry.type = ENTRY_TYPE
	entry.auraSpellID = spellID
	entry.spellID = spellID
	entry.auraPresetKey = presetKey
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
	local presetKey = type(idValue) == "table" and idValue.auraPresetKey or nil
	local auraPresets = CooldownPanels.AuraPresets
	local presetSpellID = auraPresets and auraPresets.GetPrimarySpellID and auraPresets:GetPrimarySpellID(presetKey) or nil
	local spellID = tonumber(presetSpellID or type(idValue) == "table" and (idValue.auraSpellID or idValue.spellID) or idValue)
	if not spellID or not panel or not panel.entries then return nil end
	for entryId, entry in pairs(panel.entries) do
		if presetKey and entry and entry.type == ENTRY_TYPE and entry.auraPresetKey == presetKey then return entryId, entry end
		if auraPresets and auraPresets.EntryTracksSpellID and auraPresets:EntryTracksSpellID(entry, spellID) then return entryId, entry end
		if entry and entry.type == ENTRY_TYPE and getAuraSpellID(entry) == spellID then return entryId, entry end
	end
	return nil
end

function CDMAuras:GetEntryIdText(entry)
	if not (entry and entry.type == ENTRY_TYPE) or entry.auraPresetKey then return nil end
	return tostring(getAuraSpellID(entry) or "")
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

AuraContainers.originalUpdateRuntimeIcons = CooldownPanels.UpdateRuntimeIcons
function CooldownPanels:UpdateRuntimeIcons(panelId)
	panelId = tonumber(panelId) or panelId
	local buildToken = AuraContainers:BeginPanelBuild(panelId)
	AuraContainers:PrepareDynamicGroups(panelId)
	AuraContainers.originalUpdateRuntimeIcons(self, panelId)
	AuraContainers:EndPanelBuild(panelId, buildToken)
	AuraContainers:FinalizeDynamicGroups(panelId)
end

AuraContainers.originalUpdateVisibility = CooldownPanels.UpdateVisibility
function CooldownPanels:UpdateVisibility(panelId)
	local result = AuraContainers.originalUpdateVisibility(self, panelId)
	AuraContainers:SyncPanelStates(panelId)
	return result
end

AuraContainers.originalRefreshPanel = CooldownPanels.RefreshPanel
function CooldownPanels:RefreshPanel(panelId, framePrepared)
	local result = AuraContainers.originalRefreshPanel(self, panelId, framePrepared)
	AuraContainers:PruneInactiveStates(panelId)
	return result
end

AuraContainers.originalRefreshAllPanels = CooldownPanels.RefreshAllPanels
function CooldownPanels:RefreshAllPanels(forceAll, explicitPanelIds)
	local result = AuraContainers.originalRefreshAllPanels(self, forceAll, explicitPanelIds)
	AuraContainers:PruneInactiveStates()
	return result
end

AuraContainers.originalDeletePanel = CooldownPanels.DeletePanel
function CooldownPanels:DeletePanel(panelId)
	AuraContainers:ReleasePanelStates(panelId)
	return AuraContainers.originalDeletePanel(self, panelId)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("GROUP_ROSTER_UPDATE")
driver:RegisterEvent("ROLE_CHANGED_INFORM")
driver:RegisterUnitEvent("UNIT_PET", "player")
driver:RegisterUnitEvent("UNIT_FACTION", "target")
driver:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if not AuraContainers._deferredLoadHandled and AuraCompat._auraContainerLoadDeferred and AuraCompat:HasAuraContainerSupport() then
			AuraContainers._deferredLoadHandled = true
			CooldownPanels:RefreshAllPanels(true)
		end
		AuraContainers:RequestAllPanelSyncs()
	elseif event == "GROUP_ROSTER_UPDATE" then
		local rebuildRoleUnits = false
		for _, state in pairs(states) do
			if Helper.IsAuraRoleUnit(state.auraUnitMode) then rebuildRoleUnits = true end
			if not state.disabled and Helper.IsAuraGroupUnit(state.auraUnitMode) and state.container
				and not AuraContainers:IsTrackedAuraSuppressed(state.unitToken, state.filterString) then
				AuraCompat:RefreshAuraContainer(state.container, state.unitToken)
			end
		end
		if rebuildRoleUnits then
			CooldownPanels:RefreshAllPanels(true)
		else
			AuraContainers:RequestAllPanelSyncs()
		end
	elseif event == "ROLE_CHANGED_INFORM" then
		CooldownPanels:RefreshAllPanels(true)
	elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_FACTION" then
		local refreshUnitToken = event == "PLAYER_TARGET_CHANGED" and "target" or nil
		for _, state in pairs(states) do
			if not state.disabled and state.unitToken == "target" then attachState(state, refreshUnitToken) end
		end
		for _, panelGroups in pairs(AuraContainers.dynamicGroupsByPanel) do
			for _, owner in pairs(panelGroups) do
				local refreshOwner = false
				for i = 1, #(owner.runs or {}) do
					local run = owner.runs[i]
					if run.unitToken == "target" then
						refreshOwner = true
						break
					end
				end
				if refreshOwner then AuraContainers:ShowDynamicGroup(owner, refreshUnitToken) end
			end
		end
	elseif event == "UNIT_PET" then
		for _, state in pairs(states) do
			if not state.disabled and state.unitToken == "pet" and state.container
				and not AuraContainers:IsTrackedAuraSuppressed(state.unitToken, state.filterString) then
				AuraCompat:RefreshAuraContainer(state.container, "pet")
			end
		end
		for _, panelGroups in pairs(AuraContainers.dynamicGroupsByPanel) do
			for _, owner in pairs(panelGroups) do
				for i = 1, #(owner.runs or {}) do
					local run = owner.runs[i]
					if run.unitToken == "pet" and run.container
						and not AuraContainers:IsTrackedAuraSuppressed(run.unitToken, run.filterString) then
						AuraCompat:RefreshAuraContainer(run.container, "pet")
					end
				end
			end
		end
	end
end)

AuraContainers.originalBuildRuntimeData = originalBuildRuntimeData
