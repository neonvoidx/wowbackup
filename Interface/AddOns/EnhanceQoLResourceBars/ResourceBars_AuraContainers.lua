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

local function getApplicationBarInset(cfg)
	-- A positive segment offset uses per-segment borders. The native application
	-- bar is continuous, so only inset it for the shared outer-border layout.
	if (tonumber(cfg and cfg.separatedOffset) or 0) > 0 then return 0 end
	local backdrop = cfg and cfg.backdrop
	if not (backdrop and backdrop.enabled ~= false) then return 0 end
	local borderAlpha = ResourceBars.ResolveColorAlpha and ResourceBars.ResolveColorAlpha(backdrop.borderColor) or 0
	if not ResourceBars.ResolveBorderContentInset then return 0 end
	return ResourceBars.ResolveBorderContentInset(backdrop.edgeSize, backdrop.outset, borderAlpha)
end

local function createTextOverlay(button, levelOffset)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel((button:GetFrameLevel() or 0) + (levelOffset or 2))
	return overlay
end

local function createContentFrame(button, inset)
	local content = CreateFrame("Frame", nil, button)
	if inset > 0 and ResourceBars.Pixel and ResourceBars.Pixel.SetInside then
		ResourceBars.Pixel.SetInside(content, button, inset, inset)
	else
		content:SetAllPoints(button)
	end
	return content
end

local function getDurationThresholdLayers(pType, cfg, definition)
	if not (definition and definition.durationAsValue == true and cfg and cfg.useAbsoluteThresholdColors == true) then return {} end
	local mode = ResourceBars.GetThresholdColorModeAndCap and ResourceBars.GetThresholdColorModeAndCap(pType)
	if mode ~= "PERCENT" then return {} end
	local points = ResourceBars.NormalizeAbsoluteThresholdColorPoints and ResourceBars.NormalizeAbsoluteThresholdColorPoints(cfg, pType)
	if not points or #points == 0 then return {} end
	local baseR, baseG, baseB, baseA = resolveColor(pType, cfg, definition)
	local layers = {}
	local function add(fraction, color, step)
		fraction = math.max(0, math.min(1, fraction))
		layers[#layers + 1] = {
			fraction = fraction,
			color = color,
			step = step == true,
		}
	end
	for index = #points, 1, -1 do
		local point = points[index]
		add((tonumber(point.value) or 0) / 100, point.color, false)
	end
	for index = 1, #points do
		local point = points[index]
		local nextPoint = points[index + 1]
		add((tonumber(point.value) or 0) / 100, nextPoint and nextPoint.color or { baseR, baseG, baseB, baseA }, true)
	end
	return layers
end

local function getDurationTextThresholdPoints(pType, cfg, definition)
	if not (definition and definition.durationAsValue == true and cfg and cfg.useTextThresholdColors == true) then return nil end
	local mode = ResourceBars.GetThresholdColorModeAndCap and ResourceBars.GetThresholdColorModeAndCap(pType)
	if mode ~= "PERCENT" then return nil end
	local proxy = ResourceBars.GetTextThresholdColorConfig and ResourceBars.GetTextThresholdColorConfig(cfg)
	if not proxy or not ResourceBars.NormalizeAbsoluteThresholdColorPoints then return nil end
	return ResourceBars.NormalizeAbsoluteThresholdColorPoints(proxy, pType)
end

local function createDurationTextColorCurve(pType, cfg, definition)
	local points = getDurationTextThresholdPoints(pType, cfg, definition)
	if not points or #points == 0 then return nil end
	if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return nil end
	local curve = C_CurveUtil.CreateColorCurve()
	if not curve then return nil end
	curve:SetType(Enum.LuaCurveType.Step)
	local base = cfg and cfg.fontColor or {}
	local baseColor = { base.r or base[1] or 1, base.g or base[2] or 1, base.b or base[3] or 1, base.a or base[4] or 1 }
	local firstColor = points[1].color or baseColor
	curve:AddPoint(0, CreateColor(firstColor.r or firstColor[1] or 1, firstColor.g or firstColor[2] or 1, firstColor.b or firstColor[3] or 1, firstColor.a or firstColor[4] or 1))
	for index = 1, #points do
		local point = points[index]
		local nextPoint = points[index + 1]
		local nextColor = nextPoint and nextPoint.color or baseColor
		local progress = math.max(0, math.min(100, tonumber(point.value) or 0))
		if progress < 100 then
			progress = math.min(100, progress + 0.0001)
			curve:AddPoint(progress, CreateColor(nextColor.r or nextColor[1] or 1, nextColor.g or nextColor[2] or 1, nextColor.b or nextColor[3] or 1, nextColor.a or nextColor[4] or 1))
		end
	end
	return curve
end

local function createThresholdMask(button)
	local mask = button:CreateMaskTexture(nil, "BACKGROUND")
	mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
	if mask.SetSnapToPixelGrid then mask:SetSnapToPixelGrid(false) end
	if mask.SetTexelSnappingBias then mask:SetTexelSnappingBias(0) end
	return mask
end

local function applyDurationThresholdGeometry(button, statusBar, mask, layer, cfg, inset)
	local vertical = cfg and cfg.verticalFill == true
	local reverse = cfg and cfg.reverseFill == true
	local configuredSize = tonumber(vertical and cfg and cfg.height or cfg and cfg.width) or (vertical and 20 or 200)
	configuredSize = math.max(1, configuredSize - (2 * inset))
	local liveSize = vertical and button:GetHeight() or button:GetWidth()
	local size = type(liveSize) == "number" and liveSize > 1 and math.max(1, liveSize - (2 * inset)) or configuredSize
	local scale = button.GetEffectiveScale and button:GetEffectiveScale() or 1
	local _, physicalHeight = GetPhysicalScreenSize()
	local onePixel = physicalHeight and physicalHeight > 0 and scale and scale > 0 and (768 / physicalHeight) / scale or 1
	local seam = math.floor((size * layer.fraction) / onePixel + 0.5) * onePixel
	local padding = 400
	local overlap = onePixel
	local content = statusBar._eqolThresholdContent

	mask:ClearAllPoints()
	if vertical then
		if reverse then
			mask:SetPoint("BOTTOMLEFT", content, "TOPLEFT", -padding, -seam - overlap)
			mask:SetPoint("TOPRIGHT", content, "TOPRIGHT", padding, 0)
		else
			mask:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", -padding, 0)
			mask:SetPoint("TOPRIGHT", content, "BOTTOMRIGHT", padding, seam + overlap)
		end
	elseif reverse then
		mask:SetPoint("TOPLEFT", content, "TOPRIGHT", -seam - overlap, padding)
		mask:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, -padding)
	else
		mask:SetPoint("TOPLEFT", content, "TOPLEFT", 0, padding)
		mask:SetPoint("BOTTOMRIGHT", content, "BOTTOMLEFT", seam + overlap, -padding)
	end
	mask:Show()

	statusBar:ClearAllPoints()
	if not layer.step then
		statusBar:SetAllPoints(content)
		statusBar:SetMinMaxValues(0, 1)
		return
	end
	local minimum = math.min(layer.fraction, 0.9998)
	statusBar:SetMinMaxValues(minimum, minimum + 0.0002)
	local length = math.min(120000, math.max(size, seam / 0.0005))
	local back = length * layer.fraction
	if vertical then
		if reverse then
			statusBar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, back)
			statusBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, back)
		else
			statusBar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, -back)
			statusBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, -back)
		end
		statusBar:SetHeight(length)
	elseif reverse then
		statusBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", back, 0)
		statusBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", back, 0)
		statusBar:SetWidth(length)
	else
		statusBar:SetPoint("TOPLEFT", content, "TOPLEFT", -back, 0)
		statusBar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", -back, 0)
		statusBar:SetWidth(length)
	end
end

local function createDurationThresholdInitializer(cfg, layer, rank, inset, registry)
	return function(button)
		button:EnableMouse(false)
		button:SetFrameLevel((button:GetFrameLevel() or 0) + rank)
		local content = createContentFrame(button, inset)
		local statusBar = CreateFrame("StatusBar", nil, content)
		statusBar._eqolThresholdContent = content
		statusBar:SetFrameLevel((content:GetFrameLevel() or 0) + 1)
		if statusBar.SetOrientation then statusBar:SetOrientation(cfg and cfg.verticalFill == true and "VERTICAL" or "HORIZONTAL") end
		if statusBar.SetReverseFill then statusBar:SetReverseFill(cfg and cfg.reverseFill == true) end
		button:SetDurationBar(statusBar, {
			interpolation = layer.step and Enum.StatusBarInterpolation.Immediate or nil,
			direction = Enum.StatusBarTimerDirection.RemainingTime,
		})
		statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
		local color = layer.color or {}
		statusBar:SetStatusBarColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1)
		local mask = createThresholdMask(button)
		local fill = statusBar:GetStatusBarTexture()
		if fill and fill.AddMaskTexture then fill:AddMaskTexture(mask) end
		applyDurationThresholdGeometry(button, statusBar, mask, layer, cfg, inset)
		registry[#registry + 1] = { button = button, statusBar = statusBar, mask = mask, layer = layer }
	end
end

local function createDurationThresholdShadeInitializer(cfg, texture, rank, inset)
	return function(button)
		button:EnableMouse(false)
		button:SetFrameLevel((button:GetFrameLevel() or 0) + rank)
		local content = createContentFrame(button, inset)
		local statusBar = CreateFrame("StatusBar", nil, content)
		statusBar:SetAllPoints(content)
		statusBar:SetFrameLevel((content:GetFrameLevel() or 0) + 1)
		if statusBar.SetOrientation then statusBar:SetOrientation(cfg and cfg.verticalFill == true and "VERTICAL" or "HORIZONTAL") end
		if statusBar.SetReverseFill then statusBar:SetReverseFill(cfg and cfg.reverseFill == true) end
		statusBar:SetStatusBarTexture(texture)
		statusBar:SetStatusBarColor(1, 1, 1, 1)
		local fill = statusBar:GetStatusBarTexture()
		if fill and fill.SetBlendMode then fill:SetBlendMode("MOD") end
		button:SetDurationBar(statusBar, { direction = Enum.StatusBarTimerDirection.RemainingTime })
	end
end

local function createInitializer(pType, cfg, durationThresholdLayerCount)
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
	local applicationBarInset = getApplicationBarInset(cfg)
	local useDurationThresholdLayers = definition.durationAsValue == true and durationThresholdLayerCount > 0
	local durationTextColorCurve = createDurationTextColorCurve(pType, cfg, definition)
	local durationTextColorProperty = durationTextColorCurve and addon.functions and addon.functions.GetDurationTextBindingProperty
		and addon.functions.GetDurationTextBindingProperty("RemainingPercent")
		or nil
	local durationTextOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
		and addon.functions.GetAuraButtonDurationTextOptions(cfg and cfg.durationTextProfile, durationTextColorCurve and {
			textColorCurve = durationTextColorCurve,
			textColorProperty = durationTextColorProperty,
		} or nil)
		or nil
	return function(button)
		button:EnableMouse(false)
		if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
		if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end
		local content = createContentFrame(button, applicationBarInset)
		local fill = CreateFrame("StatusBar", nil, content)
		fill:SetAllPoints(content)
		fill:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
		fill:SetStatusBarTexture(useDurationThresholdLayers and "Interface\\Buttons\\WHITE8X8" or texture)
		if ResourceBars.ApplyStatusBarTexturePixelSnapping then ResourceBars.ApplyStatusBarTexturePixelSnapping(fill, 0) end
		fill:SetStatusBarColor(r, g, b, a)
		if fill.SetOrientation then fill:SetOrientation(cfg and cfg.verticalFill == true and "VERTICAL" or "HORIZONTAL") end
		if fill.SetReverseFill then fill:SetReverseFill(reverseFill) end
		button._eqolAuraPowerFill = fill

		local textOverlay = showText and createTextOverlay(button, useDurationThresholdLayers and (durationThresholdLayerCount + 4) or 2) or nil
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
	local applicationBarInset = getApplicationBarInset(cfg)
	local durationThresholdLayers = getDurationThresholdLayers(pType, cfg, definition)
	local durationTextThresholdPoints = getDurationTextThresholdPoints(pType, cfg, definition)
	local fontColor = cfg and cfg.fontColor
	local offset = cfg and cfg.textOffset
	local signature = {
		texture,
		tostring(r), tostring(g), tostring(b), tostring(a),
		tostring(displayMax),
		tostring(applicationBarInset),
		cfg and cfg.reverseFill == true and "1" or "0",
		cfg and cfg.verticalFill == true and "1" or "0",
		tostring(cfg and cfg.width or ""),
		tostring(cfg and cfg.height or ""),
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
	}
	for index = 1, #durationThresholdLayers do
		local layer = durationThresholdLayers[index]
		local color = layer.color or {}
		signature[#signature + 1] = tostring(layer.fraction)
		signature[#signature + 1] = layer.step and "1" or "0"
		signature[#signature + 1] = tostring(color.r or color[1] or 1)
		signature[#signature + 1] = tostring(color.g or color[2] or 1)
		signature[#signature + 1] = tostring(color.b or color[3] or 1)
		signature[#signature + 1] = tostring(color.a or color[4] or 1)
	end
	for index = 1, #(durationTextThresholdPoints or {}) do
		local point = durationTextThresholdPoints[index]
		local color = point.color or {}
		signature[#signature + 1] = "text"
		signature[#signature + 1] = tostring(point.value or 0)
		signature[#signature + 1] = tostring(color.r or color[1] or 1)
		signature[#signature + 1] = tostring(color.g or color[2] or 1)
		signature[#signature + 1] = tostring(color.b or color[3] or 1)
		signature[#signature + 1] = tostring(color.a or color[4] or 1)
	end
	return table.concat(signature, "\031")
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
	local durationThresholdLayers = getDurationThresholdLayers(pType, runtimeCfg, cfg)
	local thresholdRegistry = {}
	local container = AuraCompat:CreateAuraContainer(UIParent)
	if not container then return nil end
	local slotHost = createSlotHost()
	container:SetAllPoints(UIParent)
	container:SetAlpha(0)
	container:SetUnit("player")
	local slot = AuraCompat:RegisterAuraSlot(container, "resourceAura", FILTER_STRING, {
		anchorFrame = slotHost,
		candidateFilters = { includeSpellIDs = includeSpellIDs },
		initializeFrame = createInitializer(pType, runtimeCfg, #durationThresholdLayers),
	})
	if not slot then
		AuraCompat:DisableAuraContainer(container)
		return nil
	end
	if #durationThresholdLayers > 0 then
		local inset = getApplicationBarInset(runtimeCfg)
		for rank, layer in ipairs(durationThresholdLayers) do
			local thresholdSlot = AuraCompat:RegisterAuraSlot(container, "resourceAuraThreshold" .. rank, FILTER_STRING, {
				anchorFrame = slotHost,
				candidateFilters = { includeSpellIDs = includeSpellIDs },
				initializeFrame = createDurationThresholdInitializer(runtimeCfg, layer, rank, inset, thresholdRegistry),
			})
			if not thresholdSlot then
				AuraCompat:DisableAuraContainer(container)
				return nil
			end
		end
		local shadeSlot = AuraCompat:RegisterAuraSlot(container, "resourceAuraThresholdShade", FILTER_STRING, {
			anchorFrame = slotHost,
			candidateFilters = { includeSpellIDs = includeSpellIDs },
			initializeFrame = createDurationThresholdShadeInitializer(runtimeCfg, resolveTexture(runtimeCfg), #durationThresholdLayers + 1, inset),
		})
		if not shadeSlot then
			AuraCompat:DisableAuraContainer(container)
			return nil
		end
	end

	local state = {
		pType = pType,
		container = container,
		slot = slot,
		slotHost = slotHost,
		durationThresholdRegistry = thresholdRegistry,
		durationThresholdInset = getApplicationBarInset(runtimeCfg),
		runtimeCfg = runtimeCfg,
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
		if not InCombatLockdown() then
			for index = 1, #(state.durationThresholdRegistry or {}) do
				local record = state.durationThresholdRegistry[index]
				applyDurationThresholdGeometry(record.button, record.statusBar, record.mask, record.layer, state.runtimeCfg, state.durationThresholdInset or 0)
			end
		end
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
