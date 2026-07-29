local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local ResourceBars = addon.Aura and addon.Aura.ResourceBars
local AuraCompat = addon.AuraCompat
if not (ResourceBars and AuraCompat) then return end

local _, _, _, interfaceVersion = GetBuildInfo()
if (tonumber(interfaceVersion) or 0) < 120100 then return end

local Backend = {}
ResourceBars.NativeAuraPowerBackend = Backend

local CreateFrame = CreateFrame
local UIParent = UIParent
local LSM = LibStub("LibSharedMedia-3.0", true)
local FILTER_STRING = "HELPFUL"
local states = {}
local pendingBars = {}
local precreateDriver
local resolveTexture
local resolveColor
local applyFont

local function createSlotHost()
	local host = CreateFrame("Frame", nil, UIParent)
	host:SetSize(1, 1)
	host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	return host
end

local function getAuraConfig(pType)
	if ResourceBars.GetAuraPowerConfig then return ResourceBars.GetAuraPowerConfig(pType) end
	local vars = addon.Aura and addon.Aura.ResourcebarVars
	return vars and vars.AURA_POWER_CONFIG and vars.AURA_POWER_CONFIG[pType] or nil
end

local function buildSpellFilter(cfg)
	local includeSpellIDs = {}
	for i = 1, #(cfg and cfg.spellIds or {}) do
		local spellID = tonumber(cfg.spellIds[i])
		if spellID and spellID > 0 then includeSpellIDs[spellID] = true end
	end
	return includeSpellIDs
end

local function hasSpellFilter(includeSpellIDs)
	return next(includeSpellIDs) ~= nil
end

local function getDisplayMax(cfg, definition)
	local value = tonumber(cfg and cfg.visualSegments)
	if not value or value < 1 then value = tonumber(definition and definition.visualSegments) end
	if not value or value < 1 then value = tonumber(definition and definition.maxStacks) end
	if not value or value < 1 then value = 1 end
	return value
end

local function createTextOverlay(button)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel((button:GetFrameLevel() or 0) + 2)
	return overlay
end

local function createInitializer(pType, cfg)
	local definition = getAuraConfig(pType) or {}
	local showText = not (cfg and cfg.textStyle == "NONE")
	local texture = resolveTexture(cfg)
	local r, g, b, a = resolveColor(pType, cfg, definition)
	local fontConfig = {
		fontFace = cfg and cfg.fontFace,
		fontSize = cfg and cfg.fontSize,
		fontOutline = cfg and cfg.fontOutline,
		fontColor = cfg and cfg.fontColor,
		textOffset = cfg and cfg.textOffset,
	}
	local reverseFill = cfg and cfg.reverseFill == true
	local displayMax = getDisplayMax(cfg, definition)
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(cfg and cfg.durationTextProfile)
		or nil
	return function(button)
		button:EnableMouse(false)
		if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
		if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end
		local fill = CreateFrame("StatusBar", nil, button)
		fill:SetAllPoints(button)
		fill:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
		fill:SetStatusBarTexture(texture)
		fill:SetStatusBarColor(r, g, b, a)
		if fill.SetReverseFill then fill:SetReverseFill(reverseFill) end
		button._eqolAuraPowerFill = fill

		local textOverlay = showText and createTextOverlay(button) or nil
		button._eqolAuraPowerTextOverlay = textOverlay
		if definition.durationAsValue == true then
			button:SetDurationBar(fill, {
				interpolation = Enum.StatusBarInterpolation.Immediate,
				direction = Enum.StatusBarTimerDirection.RemainingTime,
			})
			if showText then
				local durationText = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				durationText:SetPoint("CENTER", textOverlay, "CENTER", 0, 0)
				durationText:SetDrawLayer("OVERLAY", 7)
				applyFont(durationText, fontConfig)
				button:SetDurationText(durationText, durationTextOptions)
				button._eqolAuraPowerDurationText = durationText
			end
		else
			-- PTR6 applies the secret application count directly to this StatusBar.
			-- Keep the configured visual maximum public (for example Maelstrom
			-- Weapon's 5/10 mode) and never inspect or derive from applications.
			button:SetApplicationBar(fill, { maxApplications = displayMax })
			if showText then
				local applicationCount = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				applicationCount:SetPoint("CENTER", textOverlay, "CENTER", 0, 0)
				applicationCount:SetDrawLayer("OVERLAY", 7)
				applyFont(applicationCount, fontConfig)
				-- Application counts can be secret in restricted encounters. Let the
				-- native button write the value without exposing it to addon Lua.
				button:SetApplicationCount(applicationCount)
				button._eqolAuraPowerApplicationCount = applicationCount
			end
		end
		button._eqolAuraPowerType = pType
	end
end

resolveTexture = function(cfg)
	local value = cfg and cfg.barTexture
	if type(value) == "string" and value ~= "" and value ~= "DEFAULT" then
		if value:find("\\", 1, true) or value:find("/", 1, true) then return value end
		if LSM and LSM.Fetch then
			local texture = LSM:Fetch("statusbar", value, true)
			if type(texture) == "string" and texture ~= "" then return texture end
		end
	end
	return "Interface\\Buttons\\WHITE8x8"
end

resolveColor = function(pType, cfg, definition)
	local color
	if cfg and cfg.useBarColor == true and type(cfg.barColor) == "table" then
		color = cfg.barColor
	elseif cfg and cfg.useClassColor == true then
		local class = addon.variables and addon.variables.unitClass
		color = class and ((CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])) or nil
	elseif definition and type(definition.defaultColor) == "table" then
		color = definition.defaultColor
	elseif ResourceBars.GetBasePowerColor then
		color = ResourceBars.GetBasePowerColor(pType)
	end
	if type(color) ~= "table" then return 1, 1, 1, 1 end
	return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
end

applyFont = function(fontString, cfg)
	if not fontString then return end
	local fontPath
	if addon.functions and addon.functions.ResolveFontFace then fontPath = addon.functions.ResolveFontFace(cfg and cfg.fontFace) end
	fontPath = fontPath or (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local size = tonumber(cfg and cfg.fontSize) or 16
	local style = cfg and cfg.fontOutline
	if addon.functions and addon.functions.GetFontFlagsForStyle then style = addon.functions.GetFontFlagsForStyle(style, "OUTLINE") end
	if style == "NONE" or style == "" then style = nil end
	if addon.functions and addon.functions.SetFontWithFallback then
		addon.functions.SetFontWithFallback(fontString, fontPath, size, style, STANDARD_TEXT_FONT)
	else
		fontString:SetFont(fontPath, size, style)
	end
	local color = cfg and cfg.fontColor
	if type(color) == "table" then fontString:SetTextColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1) end
	local offset = cfg and cfg.textOffset
	fontString:ClearAllPoints()
	fontString:SetPoint("CENTER", fontString:GetParent(), "CENTER", type(offset) == "table" and (offset.x or offset[1] or 0) or 0, type(offset) == "table" and (offset.y or offset[2] or 0) or 0)
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, cfg and cfg.fontOutline, "OUTLINE") end
end

local function getStyleSignature(pType, cfg)
	local definition = getAuraConfig(pType) or {}
	local texture = resolveTexture(cfg)
	local r, g, b, a = resolveColor(pType, cfg, definition)
	local displayMax = getDisplayMax(cfg, definition)
	local fontColor = cfg and cfg.fontColor
	local offset = cfg and cfg.textOffset
	return table.concat({
		texture,
		tostring(r), tostring(g), tostring(b), tostring(a),
		tostring(displayMax),
		cfg and cfg.reverseFill == true and "1" or "0",
		tostring(cfg and cfg.textStyle or ""),
		tostring(cfg and cfg.durationTextProfile or ""),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		tostring(cfg and cfg.fontFace or ""),
		tostring(cfg and cfg.fontSize or ""),
		tostring(cfg and cfg.fontOutline or ""),
		tostring(type(fontColor) == "table" and (fontColor.r or fontColor[1]) or ""),
		tostring(type(fontColor) == "table" and (fontColor.g or fontColor[2]) or ""),
		tostring(type(fontColor) == "table" and (fontColor.b or fontColor[3]) or ""),
		tostring(type(fontColor) == "table" and (fontColor.a or fontColor[4]) or ""),
		tostring(type(offset) == "table" and (offset.x or offset[1]) or ""),
		tostring(type(offset) == "table" and (offset.y or offset[2]) or ""),
	}, "\031")
end

local function moveSlotOffscreen(state)
	if not (state and state.slotHost) then return end
	state.slotHost:ClearAllPoints()
	state.slotHost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -64, -64)
	state.bar = nil
end

function Backend:IsSupported()
	return AuraCompat:ShouldUseAuraContainer() == true
end

function Backend:CanHandlePowerType(pType)
	local cfg = getAuraConfig(pType)
	return cfg ~= nil and cfg.spellCastCountId == nil and hasSpellFilter(buildSpellFilter(cfg))
end

function Backend:EnsureState(pType, runtimeCfg)
	local existing = states[pType]
	runtimeCfg = runtimeCfg or (ResourceBars.GetRuntimeBarConfig and ResourceBars.GetRuntimeBarConfig(pType)) or {}
	local styleSignature = getStyleSignature(pType, runtimeCfg)
	if existing and existing.styleSignature == styleSignature then return existing end
	if not self:CanHandlePowerType(pType) then return nil end
	if existing then
		moveSlotOffscreen(existing)
		existing.container:SetAlpha(0)
		AuraCompat:DisableAuraContainer(existing.container)
	end

	local cfg = getAuraConfig(pType)
	local includeSpellIDs = buildSpellFilter(cfg)
	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return nil end
	local slotHost = createSlotHost()
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit("player")
	local slot = AuraCompat:RegisterAuraSlot(container, "resourceAura", FILTER_STRING, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = includeSpellIDs },
		initializeFrame = createInitializer(pType, runtimeCfg),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end

	local state = {
		pType = pType,
		container = container,
		slot = slot,
		slotHost = slotHost,
		styleSignature = styleSignature,
	}
	states[pType] = state
	moveSlotOffscreen(state)
	AuraCompat:RefreshAuraContainer(container, "player")
	return state
end

function Backend:ApplyContainerLayer(state, bar)
	if not (state and bar) then return end
	local cfg = ResourceBars.GetRuntimeBarConfig and ResourceBars.GetRuntimeBarConfig(state.pType, bar) or bar._cfg or {}

	-- Use saved/runtime layer settings only. Reading a secret-tainted frame strata
	-- string here would itself be forbidden in restricted aura environments.
	local vars = addon.Aura and addon.Aura.ResourcebarVars or {}
	local strata = ResourceBars.NormalizeFrameStrataToken and ResourceBars.NormalizeFrameStrataToken(cfg.strata) or nil
	strata = strata or bar._rbBaseStrata or vars.DEFAULT_FRAME_STRATA or "MEDIUM"
	local baseLevel = tonumber(bar._rbBaseFrameLevel) or 0
	local levelOffset = ResourceBars.NormalizeFrameLevelOffset and ResourceBars.NormalizeFrameLevelOffset(cfg.frameLevelOffset) or 0
	state.container:SetFrameStrata(strata)
	state.container:SetFrameLevel(math.min(65535, baseLevel + (levelOffset or 0) + 1))
end

local function restoreBaseBar(bar, showText)
	if not bar then return end
	local texture = bar:GetStatusBarTexture()
	if texture then texture:SetAlpha(1) end
	if showText and bar.text and (not bar._cfg or bar._cfg.textStyle ~= "NONE") then bar.text:Show() end
	bar._lastMax = nil
	bar._lastVal = nil
	bar._lastText = nil
end

function Backend:AttachBar(pType, bar)
	if not (bar and self:CanHandlePowerType(pType)) then return false end
	local runtimeCfg = ResourceBars.GetRuntimeBarConfig and ResourceBars.GetRuntimeBarConfig(pType, bar) or bar._cfg or {}
	local state = self:EnsureState(pType, runtimeCfg)
	if not state then return false end
	if state.container:GetParent() ~= bar then
		state.container:SetParent(bar)
		state.container:ClearAllPoints()
		state.container:SetAllPoints(bar)
	end

	if state.bar ~= bar then
		moveSlotOffscreen(state)
		state.slotHost:SetAllPoints(bar)
		state.bar = bar
	end
	pendingBars[pType] = nil
	bar._eqolNativeAuraPowerType = pType
	local editModeActive = addon.EditMode and addon.EditMode.IsInEditMode and addon.EditMode:IsInEditMode()
	if editModeActive then
		local definition = getAuraConfig(pType) or {}
		local sampleMax = getDisplayMax(runtimeCfg, definition)
		bar:SetMinMaxValues(0, sampleMax)
		bar:SetValue(sampleMax)
		bar._lastMax = sampleMax
		bar._lastVal = sampleMax
		local texture = bar:GetStatusBarTexture()
		if texture then texture:SetAlpha(1) end
		if bar.text and runtimeCfg.textStyle ~= "NONE" then
			bar.text:SetText(sampleMax)
			bar.text:Show()
		elseif bar.text then
			bar.text:Hide()
		end
		self:ApplyContainerLayer(state, bar)
		state.container:SetAlpha(0)
		return true
	end
	local definition = getAuraConfig(pType) or {}
	local displayMax = getDisplayMax(runtimeCfg, definition)
	bar:SetMinMaxValues(0, displayMax)
	bar:SetValue(0)
	bar._lastMax = displayMax
	bar._lastVal = 0
	local texture = bar:GetStatusBarTexture()
	if texture then texture:SetAlpha(0) end
	if bar.text then bar.text:Hide() end
	if not bar._eqolNativeAuraPowerVisibilityHooked then
		bar:HookScript("OnShow", function(self)
			local activeType = self._eqolNativeAuraPowerType
			local activeState = activeType and states[activeType]
			if activeState and activeState.bar == self then AuraCompat:RefreshAuraContainer(activeState.container, "player") end
		end)
		bar._eqolNativeAuraPowerVisibilityHooked = true
	end
	self:ApplyContainerLayer(state, bar)
	state.container:SetAlpha(1)
	AuraCompat:RefreshAuraContainer(state.container, "player")
	return true
end

function Backend:UpdatePowerBar(pType, bar)
	return self:AttachBar(pType, bar)
end

function Backend:OnBarTypeAssigned(bar, pType)
	if not bar then return end
	local previousType = bar._eqolNativeAuraPowerType
	if previousType and previousType ~= pType then
		local state = states[previousType]
		if state and state.bar == bar then
			moveSlotOffscreen(state)
			state.container:SetAlpha(0)
			AuraCompat:DisableAuraContainer(state.container)
		end
		bar._eqolNativeAuraPowerType = nil
		restoreBaseBar(bar, true)
	end
	-- The normal ResourceBars construction path applies its frame layers after
	-- AssignFrameRuntimeConfig. UpdatePowerBar attaches the AuraContainer only
	-- after that setup is complete.
end

function Backend:RefreshPowerType(pType)
	local bar = ResourceBars.GetPowerBar and ResourceBars.GetPowerBar(pType)
	if not bar then return false end
	return self:AttachBar(pType, bar)
end

function Backend:Refresh()
	for pType in pairs(states) do self:RefreshPowerType(pType) end
end

function Backend:DisablePowerType(pType)
	local state = states[pType]
	if not state then return end
	local bar = state.bar
	moveSlotOffscreen(state)
	state.container:SetAlpha(0)
	AuraCompat:DisableAuraContainer(state.container)
	if bar and bar._eqolNativeAuraPowerType == pType then
		bar._eqolNativeAuraPowerType = nil
		restoreBaseBar(bar, true)
	end
	pendingBars[pType] = nil
end

function Backend:Disable()
	for pType in pairs(states) do self:DisablePowerType(pType) end
end

function Backend:Precreate()
	local configs = ResourceBars.GetAuraPowerConfigs and ResourceBars.GetAuraPowerConfigs() or {}
	for pType, cfg in pairs(configs) do
		if cfg.spellCastCountId == nil then self:EnsureState(pType) end
	end
	return true
end

local originalDisableResourceBars = ResourceBars.DisableResourceBars
if originalDisableResourceBars then
	function ResourceBars.DisableResourceBars(...)
		Backend:Disable()
		return originalDisableResourceBars(...)
	end
end

precreateDriver = CreateFrame("Frame")
precreateDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
precreateDriver:SetScript("OnEvent", function(self)
	Backend:Precreate()
	for pType, bar in pairs(pendingBars) do Backend:AttachBar(pType, bar) end
	if next(pendingBars) == nil then self:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end)
if Backend:Precreate() then precreateDriver:UnregisterEvent("PLAYER_REGEN_ENABLED") end
