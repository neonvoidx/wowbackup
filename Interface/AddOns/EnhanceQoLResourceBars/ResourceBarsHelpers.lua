local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local ResourceBars = addon.Aura and addon.Aura.ResourceBars
if not ResourceBars then return end

local function getPixelHelper()
	return addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFramesHelper and addon.Aura.UF.GroupFramesHelper.Pixel
end

local function roundPixel(value)
	if ResourceBars.RoundPixel then return ResourceBars.RoundPixel(value) end
	value = tonumber(value) or 0
	if value >= 0 then return math.floor(value + 0.5) end
	return math.ceil(value - 0.5)
end

local function getPixelScale(region)
	if ResourceBars.GetPixelScale then return ResourceBars.GetPixelScale(region) end
	local pixel = getPixelHelper()
	local scale
	if pixel and pixel.GetScale then
		scale = pixel.GetScale(region)
	elseif region and region.GetEffectiveScale then
		scale = region:GetEffectiveScale()
	elseif UIParent and UIParent.GetEffectiveScale then
		scale = UIParent:GetEffectiveScale()
	end
	scale = tonumber(scale) or 1
	if scale <= 0 then scale = 1 end
	local factor = (pixel and pixel.GetPixelToUIUnitFactor and pixel.GetPixelToUIUnitFactor()) or 1
	factor = tonumber(factor) or 1
	if factor <= 0 then factor = 1 end
	return scale, factor
end

local function uiToPixels(value, region, minPixels)
	if ResourceBars.UiToPixels then return ResourceBars.UiToPixels(value, region, minPixels) end
	local scale, factor = getPixelScale(region)
	local pixels = roundPixel(((tonumber(value) or 0) * scale) / factor)
	minPixels = tonumber(minPixels)
	if minPixels and minPixels > 0 then
		if pixels > 0 and pixels < minPixels then pixels = minPixels end
		if pixels < 0 and pixels > -minPixels then pixels = -minPixels end
	end
	return pixels, scale, factor
end

local function pixelsToUi(pixels, scale, factor)
	if ResourceBars.PixelsToUi then return ResourceBars.PixelsToUi(pixels, scale, factor) end
	scale = tonumber(scale) or 1
	factor = tonumber(factor) or 1
	if scale <= 0 then scale = 1 end
	if factor <= 0 then factor = 1 end
	return ((tonumber(pixels) or 0) * factor) / scale
end

local function resolveVisibilityFlag(cfg, cfgKey, globalKey, defaultValue)
	if type(cfg) == "table" and cfg[cfgKey] ~= nil then return cfg[cfgKey] == true end
	local db = addon and addon.db
	if db and db[globalKey] ~= nil then return db[globalKey] == true end
	return defaultValue == true
end

function ResourceBars.ShouldHideInClientScene(cfg) return resolveVisibilityFlag(cfg, "hideClientScene", "resourceBarsHideClientScene", true) end

function ResourceBars.ShouldHideOutOfCombat(cfg) return resolveVisibilityFlag(cfg, "hideOutOfCombat", "resourceBarsHideOutOfCombat", false) end

function ResourceBars.ShouldHideMounted(cfg) return resolveVisibilityFlag(cfg, "hideMounted", "resourceBarsHideMounted", false) end

function ResourceBars.ShouldHideInVehicle(cfg) return resolveVisibilityFlag(cfg, "hideVehicle", "resourceBarsHideVehicle", false) end

function ResourceBars.ShouldHideInPetBattle(cfg) return resolveVisibilityFlag(cfg, "hidePetBattle", "resourceBarsHidePetBattle", false) end

function ResourceBars.ShouldHideWhenEmpty(cfg) return resolveVisibilityFlag(cfg, "hideWhenEmpty", "resourceBarsHideWhenEmpty", false) end

local function updateManagedFrameAlpha(frame)
	if not (frame and frame.SetAlpha) then return end
	local shouldHide = frame._rbClientSceneAlphaHidden == true or frame._rbRuntimeForcedAlphaHidden == true
	if shouldHide then
		frame:SetAlpha(0)
	elseif frame._rbEmptyAlphaActive == true then
		frame:SetAlpha(frame._rbEmptyAlphaValue)
	else
		frame:SetAlpha(1)
	end
end

function ResourceBars.ApplyClientSceneAlphaToFrame(frame, forceHide)
	if not (frame and frame.SetAlpha) then return end
	if forceHide then
		frame._rbClientSceneAlphaHidden = true
	elseif frame._rbClientSceneAlphaHidden then
		frame._rbClientSceneAlphaHidden = nil
	end
	updateManagedFrameAlpha(frame)
end

function ResourceBars.ApplyRuntimeForceHiddenAlphaToFrame(frame, forceHide)
	if not (frame and frame.SetAlpha) then return end
	if forceHide then
		frame._rbRuntimeForcedAlphaHidden = true
	elseif frame._rbRuntimeForcedAlphaHidden then
		frame._rbRuntimeForcedAlphaHidden = nil
	end
	updateManagedFrameAlpha(frame)
end

function ResourceBars.ApplyHideWhenEmptyAlphaToFrame(frame, cfg, rawValue)
	if not (frame and frame.SetAlpha) then return end
	local editModeActive = addon.EditMode and addon.EditMode.IsInEditMode and addon.EditMode:IsInEditMode()
	local emptyAlphaActive
	local emptyAlphaValue
	if rawValue ~= nil and not editModeActive and ResourceBars.ShouldHideWhenEmpty and ResourceBars.ShouldHideWhenEmpty(cfg) then
		emptyAlphaActive = true
		emptyAlphaValue = rawValue
	end
	local previousValue = frame._rbEmptyAlphaValue
	local previousValueSecret = issecretvalue and issecretvalue(previousValue)
	local nextValueSecret = issecretvalue and issecretvalue(emptyAlphaValue)
	if not previousValueSecret and not nextValueSecret and frame._rbEmptyAlphaActive == emptyAlphaActive and previousValue == emptyAlphaValue then return end
	frame._rbEmptyAlphaActive = emptyAlphaActive
	frame._rbEmptyAlphaValue = emptyAlphaValue
	updateManagedFrameAlpha(frame)
end

local function normalizeGradientColor(value)
	if type(value) == "table" then
		if value.r ~= nil then return value.r or 1, value.g or 1, value.b or 1, value.a or 1 end
		return value[1] or 1, value[2] or 1, value[3] or 1, value[4] or 1
	end
	return 1, 1, 1, 1
end

local function isSecretGradientComponent(value) return issecretvalue and issecretvalue(value) end
local USE_ESSENCE_REGEN_API = false -- GetPowerRegenForPowerType is secret-only on current patch; keep disabled until Blizzard fixes it.

local function hasSecretGradientColor(r, g, b, a) return isSecretGradientComponent(r) or isSecretGradientComponent(g) or isSecretGradientComponent(b) or isSecretGradientComponent(a) end

local function resolveSolidGradientColors(baseR, baseG, baseB, baseA)
	local br = baseR ~= nil and baseR or 1
	local bg = baseG ~= nil and baseG or 1
	local bb = baseB ~= nil and baseB or 1
	local ba = baseA ~= nil and baseA or 1
	return br, bg, bb, ba, br, bg, bb, ba
end

local function canCreateGradientColor(r, g, b, a)
	if hasSecretGradientColor(r, g, b, a) then return false end
	return type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a or 1) == "number"
end

local function resolveDiscreteSegmentBackground(cfg, fallbackTexture, fallbackR, fallbackG, fallbackB, fallbackA)
	local bd = cfg and cfg.backdrop
	if bd and bd.enabled == false then return nil, 0, 0, 0, 0, false end
	-- A shared outer border uses the parent backdrop for the complete bar. Drawing
	-- the same backdrop on every segment would blend its alpha a second time.
	if ResourceBars.ShouldUsePerSegmentBorders and not ResourceBars.ShouldUsePerSegmentBorders(cfg) then return nil, 0, 0, 0, 0, false end

	if bd and bd.enabled ~= false then
		local tex = bd.backgroundTexture or fallbackTexture or "Interface\\DialogFrame\\UI-DialogBox-Background"
		local r, g, b, a = normalizeGradientColor(bd.backgroundColor or { 0, 0, 0, 0.8 })
		return tex, r, g, b, a, true
	end

	return fallbackTexture, fallbackR, fallbackG, fallbackB, fallbackA, true
end

local DISCRETE_LEGACY_BORDER_TEXTURE_IDS = {
	EQOL_BORDER_RUNES = true,
	EQOL_BORDER_GOLDEN = true,
	EQOL_BORDER_MODERN = true,
	EQOL_BORDER_CLASSIC = true,
}

local function resolveDiscreteSegmentBorderStyle(cfg, forceSegmentBorders)
	if forceSegmentBorders ~= true then return false end
	local bd = cfg and cfg.backdrop
	if not bd or bd.enabled == false then return false end

	local edgeSize = tonumber(bd.edgeSize) or 0
	if edgeSize <= 0 then return false end

	local borderTexture = bd.borderTexture or "Interface\\Tooltips\\UI-Tooltip-Border"
	if ResourceBars.ResolveBorderTexture then
		borderTexture = ResourceBars.ResolveBorderTexture(borderTexture, "Interface\\Tooltips\\UI-Tooltip-Border")
	elseif DISCRETE_LEGACY_BORDER_TEXTURE_IDS[borderTexture] then
		borderTexture = "Interface\\Tooltips\\UI-Tooltip-Border"
	end
	if not borderTexture or borderTexture == "" then return false end

	local outset = tonumber(bd.outset) or 0
	local br, bg, bb, ba = normalizeGradientColor(bd.borderColor or { 0, 0, 0, 0 })
	return true, borderTexture, edgeSize, outset, br, bg, bb, ba
end

local function isGradientDebugEnabled()
	if _G and _G.EQOL_DEBUG_RB_GRADIENT == true then return true end
	return addon and addon.db and addon.db.debugResourceBarsGradient == true
end

local function formatColor(r, g, b, a)
	if hasSecretGradientColor(r, g, b, a) then return "<secret>" end
	return string.format("%.2f/%.2f/%.2f/%.2f", r or 0, g or 0, b or 0, a or 1)
end

local function debugGradient(bar, reason, cfg, baseR, baseG, baseB, baseA, sr, sg, sb, sa, er, eg, eb, ea, force)
	if not isGradientDebugEnabled() then return end
	local now = GetTime and GetTime() or 0
	if bar then
		bar._rbGradDebugNext = bar._rbGradDebugNext or 0
		if now < bar._rbGradDebugNext then return end
		bar._rbGradDebugNext = now + 0.75
	end
	local name = (bar and bar.GetName and bar:GetName()) or tostring(bar) or "bar"
	local cfgStart, cfgEnd = "nil", "nil"
	if cfg then
		local csr, csg, csb, csa = normalizeGradientColor(cfg.gradientStartColor)
		local cer, ceg, ceb, cea = normalizeGradientColor(cfg.gradientEndColor)
		cfgStart = formatColor(csr, csg, csb, csa)
		cfgEnd = formatColor(cer, ceg, ceb, cea)
	end
	local msg = string.format(
		"grad %s %s base=%s cfgStart=%s cfgEnd=%s outStart=%s outEnd=%s force=%s",
		reason or "?",
		name,
		formatColor(baseR, baseG, baseB, baseA),
		cfgStart,
		cfgEnd,
		formatColor(sr, sg, sb, sa),
		formatColor(er, eg, eb, ea),
		force and "1" or "0"
	)
	print("|cff00ff98Enhance QoL|r: " .. msg)
end

local function resolveGradientColors(cfg, baseR, baseG, baseB, baseA)
	local sr, sg, sb, sa = normalizeGradientColor(cfg and cfg.gradientStartColor)
	local er, eg, eb, ea = normalizeGradientColor(cfg and cfg.gradientEndColor)
	local ba = baseA or 1
	return sr, sg, sb, (ba or 1) * (sa or 1), er, eg, eb, (ba or 1) * (ea or 1)
end

local function clearGradientState(bar)
	bar._rbGradientEnabled = nil
	bar._rbGradientTex = nil
	bar._rbGradDir = nil
	bar._rbGradUsesSecretBase = nil
	bar._rbGradSR = nil
	bar._rbGradSG = nil
	bar._rbGradSB = nil
	bar._rbGradSA = nil
	bar._rbGradER = nil
	bar._rbGradEG = nil
	bar._rbGradEB = nil
	bar._rbGradEA = nil
end

local function getStatusBarTextureVisualState(bar)
	if not (bar and bar.GetStatusBarTexture) then return nil, nil, nil end
	local tex = bar:GetStatusBarTexture()
	if not tex then return nil, nil, nil end
	local currentPath = tex.GetTexture and tex:GetTexture() or nil
	if (currentPath == nil or currentPath == "") and tex.GetAtlas then currentPath = tex:GetAtlas() end
	local alpha = tex.GetAlpha and tex:GetAlpha() or nil
	return tex, currentPath, alpha
end

local function ensureStatusBarTexturePath(bar, texturePath)
	if not (bar and texturePath and bar.SetStatusBarTexture) then return false end
	local tex, currentPath, alpha = getStatusBarTextureVisualState(bar)
	local needsReset = bar._rb_tex ~= texturePath or currentPath ~= texturePath
	if not needsReset and tex and alpha ~= nil and alpha <= 0 then needsReset = true end
	if not needsReset then
		if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(tex, 0) end
		return false
	end
	bar:SetStatusBarTexture(texturePath)
	tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if tex then
		if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(tex, 0) end
		if tex.SetHorizTile then tex:SetHorizTile(false) end
		if tex.SetVertTile then tex:SetVertTile(false) end
	end
	bar._rb_tex = texturePath
	return true
end

local function resetSegmentVisualCache(sb)
	if not sb then return end
	if sb.fill then resetSegmentVisualCache(sb.fill) end
	sb._rb_tex = nil
	sb._rbColorInitialized = nil
	sb._essenceState = nil
	sb._essenceColorKey = nil
	sb._rbSegmentFillColorKey = nil
	sb._rbSegmentBgPath = nil
	sb._rbSegmentBgColorKey = nil
	clearGradientState(sb)
end

function ResourceBars.InvalidateEssenceSegmentCaches(bar)
	if not bar then return end
	if bar.essences then
		for i = 1, #bar.essences do
			resetSegmentVisualCache(bar.essences[i])
		end
	end
	if bar._rbDiscreteSegments then
		for i = 1, #bar._rbDiscreteSegments do
			resetSegmentVisualCache(bar._rbDiscreteSegments[i])
		end
	end
	bar._essenceSegments = nil
	bar._essenceVertical = nil
	bar._essenceGap = nil
	bar._essenceGapRequested = nil
	bar._essenceSegmentStyled = nil
	bar._rbDiscreteCount = nil
	bar._rbDiscreteVertical = nil
	bar._rbDiscreteGapRequested = nil
	bar._rbDiscreteGap = nil
	bar._rbDiscreteReverse = nil
	bar._rbDiscreteBoundaryEnabled = nil
	bar._rbDiscreteBoundaryTexture = nil
	bar._rbDiscreteBoundaryEdgeSize = nil
	bar._rbDiscreteBoundaryOutset = nil
	bar._rbDiscreteBoundaryR = nil
	bar._rbDiscreteBoundaryG = nil
	bar._rbDiscreteBoundaryB = nil
	bar._rbDiscreteBoundaryA = nil
	bar._essenceNextTick = nil
	bar._essenceFraction = 0
	bar._essenceLastPower = nil
	bar._essenceTickDuration = nil
end

function ResourceBars.DeactivateEssenceTicker(bar)
	if not bar then return end
	if bar:GetScript("OnUpdate") == bar._essenceUpdater then bar:SetScript("OnUpdate", nil) end
	bar._essenceAnimating = false
	bar._essenceAccum = 0
	bar._essenceUpdateInterval = nil
end

function ResourceBars.ComputeEssenceFraction(bar, current, maxPower, now, powerEnum)
	if not bar then return 0, 0 end
	if current == nil or maxPower == nil then
		bar._essenceNextTick = nil
		bar._essenceFraction = 0
		return 0, 0
	end
	if issecretvalue and (issecretvalue(current) or issecretvalue(maxPower)) then
		bar._essenceNextTick = nil
		bar._essenceFraction = 0
		return 0, 0
	end
	local regen
	if USE_ESSENCE_REGEN_API and GetPowerRegenForPowerType then
		regen = GetPowerRegenForPowerType(powerEnum)
		if issecretvalue and issecretvalue(regen) then regen = nil end
	end
	if not regen or regen <= 0 then regen = 0.2 end
	local tickDuration = 1 / regen

	bar._essenceTickDuration = tickDuration
	bar._essenceNextTick = bar._essenceNextTick or nil
	bar._essenceLastPower = bar._essenceLastPower or current

	if current > bar._essenceLastPower then
		if current < maxPower then
			bar._essenceNextTick = now + tickDuration
		else
			bar._essenceNextTick = nil
		end
	end

	if current < maxPower and not bar._essenceNextTick then bar._essenceNextTick = now + tickDuration end

	if current >= maxPower then bar._essenceNextTick = nil end

	bar._essenceLastPower = current

	local fraction = 0
	if current < maxPower and bar._essenceNextTick and tickDuration > 0 then
		local remaining = bar._essenceNextTick - now
		if remaining < 0 then remaining = 0 end
		fraction = 1 - (remaining / tickDuration)
		if fraction < 0 then
			fraction = 0
		elseif fraction > 1 then
			fraction = 1
		end
	end

	if UnitPartialPower and current < maxPower and powerEnum then
		local partial = UnitPartialPower("player", powerEnum)
		if partial ~= nil and not (issecretvalue and issecretvalue(partial)) then
			local partialFrac = partial / 1000
			if partialFrac < 0 then
				partialFrac = 0
			elseif partialFrac > 1 then
				partialFrac = 1
			end
			fraction = partialFrac
			if tickDuration > 0 then bar._essenceNextTick = now + (1 - fraction) * tickDuration end
		end
	end

	bar._essenceFraction = fraction
	return fraction, tickDuration
end

local function hideEssenceSegments(bar)
	if not bar then return end
	if bar.essences then
		for i = 1, #bar.essences do
			local sb = bar.essences[i]
			if sb then
				sb:Hide()
				if sb._rbSegmentBg then sb._rbSegmentBg:Hide() end
				if sb._rbSegmentBorder then sb._rbSegmentBorder:Hide() end
			end
		end
	end
	if bar.essenceGapMarks then
		for i = 1, #bar.essenceGapMarks do
			local mark = bar.essenceGapMarks[i]
			if mark then mark:Hide() end
		end
	end
	bar._essenceSegments = 0
	bar._essenceVertical = nil
	bar._essenceGap = nil
	bar._essenceGapRequested = nil
	bar._essenceSegmentStyled = nil
end

function ResourceBars.LayoutEssences(bar, cfg, count, texturePath)
	if not bar then return end
	local separatedOffset = math.max(0, math.floor((tonumber(cfg and cfg.separatedOffset) or 0) + 0.5))
	local useDiscreteLayout = ResourceBars.LayoutDiscreteSegments ~= nil
	if not count or count <= 0 then
		hideEssenceSegments(bar)
		if ResourceBars.HideDiscreteSegments then ResourceBars.HideDiscreteSegments(bar) end
		return
	end

	if useDiscreteLayout then
		hideEssenceSegments(bar)
		ResourceBars.LayoutDiscreteSegments(bar, cfg, count, texturePath)
		return
	end

	if ResourceBars.HideDiscreteSegments then ResourceBars.HideDiscreteSegments(bar) end
	bar.essences = bar.essences or {}
	local inner = bar._rbInner or bar
	local w = math.max(1, inner:GetWidth() or (bar:GetWidth() or 0))
	local h = math.max(1, inner:GetHeight() or (bar:GetHeight() or 0))
	local vertical = cfg and cfg.verticalFill == true
	local requestedGap = ResourceBars.ResolveDiscreteSegmentGap and ResourceBars.ResolveDiscreteSegmentGap(cfg) or separatedOffset
	local gap = requestedGap
	local useSegmentStyling = true
	local useSegmentBorders = count > 1 and ((ResourceBars.ShouldUsePerSegmentBorders and ResourceBars.ShouldUsePerSegmentBorders(cfg)) or separatedOffset > 0)
	local borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA = resolveDiscreteSegmentBorderStyle(cfg, true)
	local bgTexture, bgR, bgG, bgB, bgA, bgVisible
	if useSegmentStyling then
		bgTexture, bgR, bgG, bgB, bgA, bgVisible = resolveDiscreteSegmentBackground(cfg, texturePath, 0.35, 0.35, 0.35, 0.9)
	end
	local span = vertical and h or w
	local spanPx, scale, factor = uiToPixels(span, inner, count)
	local crossPx = select(1, uiToPixels(vertical and w or h, inner, 1))
	local gapPx = (count > 1) and select(1, uiToPixels(gap, inner, 0)) or 0
	local maxGapPx = (count > 1) and math.max(0, math.floor((spanPx - count) / (count - 1))) or 0
	if gapPx > maxGapPx then gapPx = maxGapPx end
	local availablePx = spanPx - (gapPx * (count - 1))
	if availablePx < count then availablePx = count end
	local segmentBasePx = math.max(1, math.floor(availablePx / count))
	local remainderPx = math.max(0, availablePx - (segmentBasePx * count))
	local segmentOffsetsPx = bar._rbEssenceSegmentOffsetsPx
	if not segmentOffsetsPx then
		segmentOffsetsPx = {}
		bar._rbEssenceSegmentOffsetsPx = segmentOffsetsPx
	end
	local segmentSizesPx = bar._rbEssenceSegmentSizesPx
	if not segmentSizesPx then
		segmentSizesPx = {}
		bar._rbEssenceSegmentSizesPx = segmentSizesPx
	end
	for i = 1, count do
		local extraPx = i <= remainderPx and 1 or 0
		segmentSizesPx[i] = segmentBasePx + extraPx
		segmentOffsetsPx[i] = ((i - 1) * (segmentBasePx + gapPx)) + math.min(i - 1, remainderPx)
	end
	for i = count + 1, #segmentSizesPx do
		segmentSizesPx[i] = nil
		segmentOffsetsPx[i] = nil
	end

	for i = 1, count do
		local sb = bar.essences[i]
		if not sb then
			sb = CreateFrame("StatusBar", bar:GetName() .. "Essence" .. i, inner)
			sb:SetMinMaxValues(0, 1)
			bar.essences[i] = sb
		end
		ensureStatusBarTexturePath(sb, texturePath)
		sb:ClearAllPoints()
		if sb:GetParent() ~= inner then sb:SetParent(inner) end
		if sb.SetFrameStrata then sb:SetFrameStrata(bar:GetFrameStrata()) end
		sb:SetFrameLevel((bar:GetFrameLevel() or 1) + 1)
		local primaryUi = pixelsToUi(segmentSizesPx[i], scale, factor)
		local offsetUi = pixelsToUi(segmentOffsetsPx[i], scale, factor)
		local crossUi = pixelsToUi(crossPx, scale, factor)
		if vertical then
			if ResourceBars.Pixel and ResourceBars.Pixel.Size then
				ResourceBars.Pixel.Size(sb, crossUi, primaryUi)
			else
				sb:SetWidth(crossUi)
				sb:SetHeight(primaryUi)
			end
			sb:SetOrientation("VERTICAL")
			if ResourceBars.Pixel and ResourceBars.Pixel.Point then
				ResourceBars.Pixel.Point(sb, "BOTTOMLEFT", inner, "BOTTOMLEFT", 0, offsetUi)
			else
				sb:SetPoint("BOTTOMLEFT", inner, "BOTTOMLEFT", 0, offsetUi)
			end
		else
			if ResourceBars.Pixel and ResourceBars.Pixel.Size then
				ResourceBars.Pixel.Size(sb, primaryUi, crossUi)
			else
				sb:SetWidth(primaryUi)
				sb:SetHeight(crossUi)
			end
			sb:SetOrientation("HORIZONTAL")
			if ResourceBars.Pixel and ResourceBars.Pixel.Point then
				ResourceBars.Pixel.Point(sb, "TOPLEFT", inner, "TOPLEFT", offsetUi, 0)
			else
				sb:SetPoint("TOPLEFT", inner, "TOPLEFT", offsetUi, 0)
			end
		end
		if not sb._rbSegmentBg then
			sb._rbSegmentBg = sb:CreateTexture(nil, "BACKGROUND")
			if ResourceBars.Pixel and ResourceBars.Pixel.SetInside then
				ResourceBars.Pixel.SetInside(sb._rbSegmentBg, sb, 0, 0)
			else
				sb._rbSegmentBg:SetAllPoints(sb)
			end
			if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(sb._rbSegmentBg, 0) end
		end
		if useSegmentStyling and bgVisible then
			if sb._rbSegmentBgPath ~= bgTexture then
				sb._rbSegmentBg:SetTexture(bgTexture)
				if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(sb._rbSegmentBg, 0) end
				sb._rbSegmentBgPath = bgTexture
			end
			local bgColorKey = tostring(bgR) .. ":" .. tostring(bgG) .. ":" .. tostring(bgB) .. ":" .. tostring(bgA)
			if sb._rbSegmentBgColorKey ~= bgColorKey then
				sb._rbSegmentBg:SetVertexColor(bgR, bgG, bgB, bgA)
				sb._rbSegmentBgColorKey = bgColorKey
			end
			if not sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Show() end
		else
			if sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Hide() end
			sb._rbSegmentBgPath = nil
			sb._rbSegmentBgColorKey = nil
		end
		if ResourceBars.ApplyDiscreteSegmentBorder then
			ResourceBars.ApplyDiscreteSegmentBorder(sb, bar, useSegmentBorders and borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA)
		end
		if ResourceBars.ApplySegmentContentInset then
			ResourceBars.ApplySegmentContentInset(sb, 0)
		end
		if ResourceBars.ApplySegmentBackgroundInset then ResourceBars.ApplySegmentBackgroundInset(sb, cfg) end
		if not sb:IsShown() then sb:Show() end
	end
	for i = count + 1, #bar.essences do
		if bar.essences[i] then
			bar.essences[i]:Hide()
			if bar.essences[i]._rbSegmentBg then bar.essences[i]._rbSegmentBg:Hide() end
			if bar.essences[i]._rbSegmentBorder then bar.essences[i]._rbSegmentBorder:Hide() end
		end
	end
	bar.essenceGapMarks = bar.essenceGapMarks or {}
	ResourceBars.LayoutSegmentBoundaryMarks(
		bar,
		inner,
		count,
		vertical,
		segmentOffsetsPx,
		segmentSizesPx,
		scale,
		factor,
		bar.essenceGapMarks,
		not useSegmentBorders and borderEnabled,
		borderTexture,
		borderEdgeSize,
		borderOutset,
		borderR,
		borderG,
		borderB,
		borderA
	)
	bar._essenceSegments = count
	bar._essenceVertical = vertical
	bar._essenceGap = pixelsToUi(gapPx, scale, factor)
	bar._essenceGapPixels = gapPx
	bar._essenceSpanPixels = spanPx
	bar._essenceCrossPixels = crossPx
	bar._essenceGapRequested = requestedGap
	bar._essenceSegmentStyled = useSegmentStyling
end

function ResourceBars.UpdateEssenceSegments(bar, cfg, current, maxPower, fraction, fallbackColor, layoutFunc, texturePath)
	if not bar then return end
	local separatedOffset = math.max(0, math.floor((tonumber(cfg and cfg.separatedOffset) or 0) + 0.5))
	local useDiscreteLayout = ResourceBars.UpdateDiscreteSegments ~= nil and ResourceBars.LayoutDiscreteSegments ~= nil
	local base = bar._lastColor or bar._baseColor or fallbackColor or { 1, 1, 1, 1 }
	if not maxPower or maxPower <= 0 then
		hideEssenceSegments(bar)
		if ResourceBars.HideDiscreteSegments then ResourceBars.HideDiscreteSegments(bar) end
		return
	end

	if useDiscreteLayout then
		hideEssenceSegments(bar)
		local displayValue = (tonumber(current) or 0) + (tonumber(fraction) or 0)
		if displayValue < 0 then
			displayValue = 0
		elseif displayValue > maxPower then
			displayValue = maxPower
		end
		ResourceBars.UpdateDiscreteSegments(
			bar,
			cfg,
			maxPower,
			displayValue,
			base,
			texturePath
		)
		return
	end

	if ResourceBars.HideDiscreteSegments then ResourceBars.HideDiscreteSegments(bar) end
	local expectedGap = ResourceBars.ResolveDiscreteSegmentGap and ResourceBars.ResolveDiscreteSegmentGap(cfg) or separatedOffset
	local useSegmentStyling = true
	if
		not bar.essences
		or bar._essenceSegments ~= maxPower
		or bar._essenceVertical ~= (cfg and cfg.verticalFill == true)
		or bar._essenceGapRequested ~= expectedGap
		or bar._essenceSegmentStyled ~= useSegmentStyling
	then
		if layoutFunc then layoutFunc(bar, cfg, maxPower, texturePath) end
	end
	if not bar.essences then return end

	local fullR, fullG, fullB, fullA = base[1] or 1, base[2] or 1, base[3] or 1, base[4] or 1
	local dimFactor = 0.5
	local dimR, dimG, dimB, dimA = fullR * dimFactor, fullG * dimFactor, fullB * dimFactor, fullA
	local colorKey = fullR .. ":" .. fullG .. ":" .. fullB .. ":" .. fullA

	for i = 1, maxPower do
		local sb = bar.essences[i]
		if sb then
			local textureReset = ensureStatusBarTexturePath(sb, texturePath)
			local state
			local value
			if i <= current then
				state = "full"
				value = 1
			elseif i == current + 1 and fraction and fraction > 0 then
				state = "partial"
				value = fraction
			else
				state = "empty"
				value = 0
			end
			sb:SetMinMaxValues(0, 1)
			sb:SetValue(value)

			local wantR, wantG, wantB, wantA
			if state == "full" then
				wantR, wantG, wantB, wantA = fullR, fullG, fullB, fullA
			else
				wantR, wantG, wantB, wantA = dimR, dimG, dimB, dimA
			end

			local needsColor = textureReset or not sb._rbColorInitialized or sb._essenceState ~= state or sb._essenceColorKey ~= colorKey
			sb._essenceState = state
			sb._essenceColorKey = colorKey
			if needsColor then
				if ResourceBars.SetStatusBarColorWithGradient then
					ResourceBars.SetStatusBarColorWithGradient(sb, cfg, wantR, wantG, wantB, wantA)
				else
					sb:SetStatusBarColor(wantR, wantG, wantB, wantA or 1)
				end
				sb._rbColorInitialized = true
			elseif ResourceBars.RefreshStatusBarGradient then
				ResourceBars.RefreshStatusBarGradient(sb, cfg, wantR, wantG, wantB, wantA)
			end
			if sb._rbSegmentBg and useSegmentStyling then
				local bgTexture, bgR, bgG, bgB, bgA, bgVisible = resolveDiscreteSegmentBackground(cfg, texturePath, dimR, dimG, dimB, dimA)
				if bgVisible then
					if sb._rbSegmentBgPath ~= bgTexture then
						sb._rbSegmentBg:SetTexture(bgTexture)
						if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(sb._rbSegmentBg, 0) end
						sb._rbSegmentBgPath = bgTexture
					end
					local bgColorKey = tostring(bgR) .. ":" .. tostring(bgG) .. ":" .. tostring(bgB) .. ":" .. tostring(bgA)
					if sb._rbSegmentBgColorKey ~= bgColorKey then
						sb._rbSegmentBg:SetVertexColor(bgR, bgG, bgB, bgA)
						sb._rbSegmentBgColorKey = bgColorKey
					end
					if not sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Show() end
				else
					if sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Hide() end
					sb._rbSegmentBgPath = nil
					sb._rbSegmentBgColorKey = nil
				end
			elseif sb._rbSegmentBg and sb._rbSegmentBg:IsShown() then
				sb._rbSegmentBg:Hide()
			end
			if not sb:IsShown() then sb:Show() end
		end
	end
	for i = maxPower + 1, #bar.essences do
		if bar.essences[i] then bar.essences[i]:Hide() end
	end
end

local function hideDiscreteSegments(bar)
	if not bar or not bar._rbDiscreteSegments then return end
	for i = 1, #bar._rbDiscreteSegments do
		local sb = bar._rbDiscreteSegments[i]
		if sb then
			sb:Hide()
			if sb._rbSegmentBorder then sb._rbSegmentBorder:Hide() end
		end
	end
end

local function ensureDiscreteSegmentFrame(bar, inner, segments, index, nameBase)
	local segment = segments[index]
	if segment and segment._rbDiscreteSegmentFrame and segment.fill then return segment, segment.fill end

	if segment then
		segment:Hide()
		if segment._rbSegmentBorder then segment._rbSegmentBorder:Hide() end
	end

	segment = CreateFrame("Frame", nil, inner)
	segment._rbDiscreteSegmentFrame = true
	segment:SetClampedToScreen(false)
	segment:SetMovable(false)
	segment:EnableMouse(false)
	if segment.SetClipsChildren then segment:SetClipsChildren(true) end

	local fill = CreateFrame("StatusBar", nameBase .. "Seg" .. index .. "Fill", segment)
	fill:SetMinMaxValues(0, 1)
	fill:SetValue(0)
	if ResourceBars.Pixel and ResourceBars.Pixel.SetInside then
		ResourceBars.Pixel.SetInside(fill, segment, 0, 0)
	else
		fill:SetPoint("TOPLEFT", segment, "TOPLEFT", 0, 0)
		fill:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", 0, 0)
	end
	segment.fill = fill
	segments[index] = segment
	return segment, fill
end

local function ensureDiscreteSegmentBorderFrame(bar, sb)
	if not (bar and sb) then return nil end
	local border = sb._rbSegmentBorder
	if not border then
		border = CreateFrame("Frame", nil, bar)
		border:EnableMouse(false)
		sb._rbSegmentBorder = border
	end
	local strata = bar:GetFrameStrata()
	if border:GetFrameStrata() ~= strata then border:SetFrameStrata(strata) end
	local level = min((bar:GetFrameLevel() or 1) + 2, 65535)
	if border:GetFrameLevel() ~= level then border:SetFrameLevel(level) end
	return border
end

local function applySafeBorderTextureSnapping(frame, stateKey)
	local state = frame and frame[stateKey]
	if not state then return end
	if ResourceBars.ApplyTexturePixelSnapping then
		ResourceBars.ApplyTexturePixelSnapping(state.top, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.bottom, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.left, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.right, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.topLeft, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.topRight, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.bottomLeft, 0)
		ResourceBars.ApplyTexturePixelSnapping(state.bottomRight, 0)
	end
end

local function applyDiscreteSegmentBorder(sb, bar, enabled, texture, edgeSize, outset, r, g, b, a)
	if not sb then return end
	if enabled ~= true then
		if sb._rbSegmentBorder and addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(sb._rbSegmentBorder, false, nil, nil, nil, nil, nil, nil, { stateKey = "_rbDiscreteSegmentSafeBorder" })
		elseif sb._rbSegmentBorder and sb._rbSegmentBorder:IsShown() then
			sb._rbSegmentBorder:Hide()
		end
		return
	end

	local border = ensureDiscreteSegmentBorderFrame(bar, sb)
	if not border then return end

	if border._rbOutset ~= outset then
		if ResourceBars.Pixel and ResourceBars.Pixel.SetOutside then
			ResourceBars.Pixel.SetOutside(border, sb, outset, outset)
		else
			border:ClearAllPoints()
			border:SetPoint("TOPLEFT", sb, "TOPLEFT", -outset, outset)
			border:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", outset, -outset)
		end
		border._rbOutset = outset
	end

	if border.GetBackdrop and border:GetBackdrop() then
		border:SetBackdrop(nil)
		border._rbBackdrop = nil
	end

	if addon.functions and addon.functions.SetSafeBorder then
		local stateKey = "_rbDiscreteSegmentSafeBorder"
		addon.functions.SetSafeBorder(border, true, texture, edgeSize, r, g, b, a, {
			stateKey = stateKey,
			defaultTexture = "Interface\\Buttons\\WHITE8x8",
			mediaType = "border",
			pixelPerfect = true,
		})
		applySafeBorderTextureSnapping(border, stateKey)
	else
		if not border:IsShown() then border:Show() end
	end
end

local function resolveDiscreteSegmentOffset(cfg)
	local offset = tonumber(cfg and cfg.separatedOffset) or 0
	return math.max(0, math.floor(offset + 0.5))
end

local function resolveDiscreteSegmentGap(cfg)
	return resolveDiscreteSegmentOffset(cfg)
end

function ResourceBars.ResolveDiscreteSegmentBackground(cfg, fallbackTexture, fallbackR, fallbackG, fallbackB, fallbackA)
	return resolveDiscreteSegmentBackground(cfg, fallbackTexture, fallbackR, fallbackG, fallbackB, fallbackA)
end

function ResourceBars.ResolveDiscreteSegmentBorderStyle(cfg, forceSegmentBorders) return resolveDiscreteSegmentBorderStyle(cfg, forceSegmentBorders) end

function ResourceBars.ApplyDiscreteSegmentBorder(sb, bar, enabled, texture, edgeSize, outset, r, g, b, a) return applyDiscreteSegmentBorder(sb, bar, enabled, texture, edgeSize, outset, r, g, b, a) end

function ResourceBars.ResolveDiscreteSegmentGap(cfg) return resolveDiscreteSegmentGap(cfg) end

local function resolveMaelstromCarryMode(bar, cfg, count, clamped)
	if not (bar and cfg and cfg.useMaelstromCarryFill == true and cfg.useMaelstromTenStacks ~= true) then return false end
	if bar._usingMaxColor == true then return false end
	if (bar._rbType ~= "MAELSTROM_WEAPON") or count <= 0 then return false end
	local maelstromSegments = (ResourceBars and ResourceBars.MAELSTROM_WEAPON_SEGMENTS) or 5
	if count ~= maelstromSegments then return false end

	local rawStacks = tonumber(bar._rbDiscreteRawValue) or clamped or 0
	local overflow = rawStacks - count
	if overflow <= 0 then return false end
	if overflow > count then overflow = count end

	local carryR, carryG, carryB, carryA = normalizeGradientColor(bar._baseColor or { 1, 1, 1, 1 })
	return true, overflow, carryR, carryG, carryB, carryA
end

function ResourceBars.HideDiscreteSegments(bar)
	if not bar then return end
	hideDiscreteSegments(bar)
	if bar._rbDiscreteGapMarks then
		for i = 1, #bar._rbDiscreteGapMarks do
			local mark = bar._rbDiscreteGapMarks[i]
			if mark then mark:Hide() end
		end
	end
end

function ResourceBars.LayoutDiscreteSegments(bar, cfg, count, texturePath)
	if not bar then return end
	count = tonumber(count) or 0
	if count < 1 then
		ResourceBars.HideDiscreteSegments(bar)
		bar._rbDiscreteCount = 0
		return
	end

	local inner = bar._rbInner or bar
	local w = math.max(1, inner:GetWidth() or (bar:GetWidth() or 0))
	local h = math.max(1, inner:GetHeight() or (bar:GetHeight() or 0))
	local vertical = cfg and cfg.verticalFill == true
	local reverse = cfg and cfg.reverseFill == true

	local segmentOffset = resolveDiscreteSegmentOffset(cfg)
	local requestedGap = resolveDiscreteSegmentGap(cfg)
	local useSegmentBorders = count > 1 and ((ResourceBars.ShouldUsePerSegmentBorders and ResourceBars.ShouldUsePerSegmentBorders(cfg)) or segmentOffset > 0)
	local borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA = resolveDiscreteSegmentBorderStyle(cfg, true)
	local boundaryEnabled = count > 1 and not useSegmentBorders and borderEnabled
	if count < 2 then
		requestedGap = 0
	end

	local span = vertical and h or w
	local spanPx, scale, factor = uiToPixels(span, inner, count)
	local crossPx = select(1, uiToPixels(vertical and w or h, inner, 1))
	local gapPx = count > 1 and select(1, uiToPixels(requestedGap, inner, 0)) or 0
	local maxGapPx = count > 1 and math.max(0, math.floor((spanPx - count) / (count - 1))) or 0
	if gapPx > maxGapPx then gapPx = maxGapPx end

	local availablePx = spanPx - (gapPx * (count - 1))
	if availablePx < count then availablePx = count end
	local segmentBasePx = math.max(1, math.floor(availablePx / count))
	local remainderPx = math.max(0, availablePx - (segmentBasePx * count))
	local segmentOffsetsPx = bar._rbDiscreteSegmentOffsetsPx
	if not segmentOffsetsPx then
		segmentOffsetsPx = {}
		bar._rbDiscreteSegmentOffsetsPx = segmentOffsetsPx
	end
	local segmentSizesPx = bar._rbDiscreteSegmentSizesPx
	if not segmentSizesPx then
		segmentSizesPx = {}
		bar._rbDiscreteSegmentSizesPx = segmentSizesPx
	end
	for i = 1, count do
		local extraPx = i <= remainderPx and 1 or 0
		segmentSizesPx[i] = segmentBasePx + extraPx
		segmentOffsetsPx[i] = ((i - 1) * (segmentBasePx + gapPx)) + math.min(i - 1, remainderPx)
	end
	for i = count + 1, #segmentSizesPx do
		segmentSizesPx[i] = nil
		segmentOffsetsPx[i] = nil
	end

	bar._rbDiscreteGapMarks = bar._rbDiscreteGapMarks or {}
	local gapMarks = bar._rbDiscreteGapMarks

	bar._rbDiscreteSegments = bar._rbDiscreteSegments or {}
	local segments = bar._rbDiscreteSegments
	local nameBase = bar:GetName() or "EQOLDiscrete"
	local texPath = texturePath or "Interface\\Buttons\\WHITE8x8"
	local segmentBgPath, segmentBgR, segmentBgG, segmentBgB, segmentBgA, segmentBgVisible = resolveDiscreteSegmentBackground(cfg, texPath, 0, 0, 0, 0.8)
	local segmentBgColorKey = segmentBgR .. ":" .. segmentBgG .. ":" .. segmentBgB .. ":" .. segmentBgA

	for i = 1, count do
		local segment, fill = ensureDiscreteSegmentFrame(bar, inner, segments, i, nameBase)
		if segment:GetParent() ~= inner then segment:SetParent(inner) end
		if segment.SetFrameStrata then segment:SetFrameStrata(bar:GetFrameStrata()) end
		segment:SetFrameLevel((bar:GetFrameLevel() or 1) + 1)
		if fill.SetFrameStrata then fill:SetFrameStrata(bar:GetFrameStrata()) end
		fill:SetFrameLevel(segment:GetFrameLevel())
		ensureStatusBarTexturePath(fill, texPath)
		if fill.SetReverseFill then fill:SetReverseFill(reverse) end
		if ResourceBars.SetStatusBarColorWithGradient then
			local fillColor = fill._lastColor or bar._lastColor or bar._baseColor
			if fillColor then
				ResourceBars.SetStatusBarColorWithGradient(fill, cfg, fillColor[1] or 1, fillColor[2] or 1, fillColor[3] or 1, fillColor[4] or 1, true)
			elseif ResourceBars.RefreshStatusBarGradient then
				ResourceBars.RefreshStatusBarGradient(fill, cfg)
			end
		elseif ResourceBars.RefreshStatusBarGradient then
			ResourceBars.RefreshStatusBarGradient(fill, cfg)
		end
		if not segment._rbSegmentBg then
			segment._rbSegmentBg = segment:CreateTexture(nil, "BACKGROUND")
			segment._rbSegmentBg:SetAllPoints(segment)
			if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(segment._rbSegmentBg, 0) end
			if segment._rbSegmentBg.SetHorizTile then segment._rbSegmentBg:SetHorizTile(false) end
			if segment._rbSegmentBg.SetVertTile then segment._rbSegmentBg:SetVertTile(false) end
			if segment._rbSegmentBg.SetTexCoord then segment._rbSegmentBg:SetTexCoord(0, 1, 0, 1) end
		end
		if segmentBgVisible then
			if segment._rbSegmentBgPath ~= segmentBgPath then
				segment._rbSegmentBg:SetTexture(segmentBgPath)
				if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(segment._rbSegmentBg, 0) end
				segment._rbSegmentBgPath = segmentBgPath
			end
			if segment._rbSegmentBgColorKey ~= segmentBgColorKey then
				segment._rbSegmentBg:SetVertexColor(segmentBgR, segmentBgG, segmentBgB, segmentBgA)
				segment._rbSegmentBgColorKey = segmentBgColorKey
			end
			if not segment._rbSegmentBg:IsShown() then segment._rbSegmentBg:Show() end
		else
			if segment._rbSegmentBg:IsShown() then segment._rbSegmentBg:Hide() end
			segment._rbSegmentBgPath = nil
			segment._rbSegmentBgColorKey = nil
		end
		segment:ClearAllPoints()
		local primaryUi = pixelsToUi(segmentSizesPx[i], scale, factor)
		local offsetUi = pixelsToUi(segmentOffsetsPx[i], scale, factor)
		local crossUi = pixelsToUi(crossPx, scale, factor)
		if vertical then
			if ResourceBars.Pixel and ResourceBars.Pixel.Size then
				ResourceBars.Pixel.Size(segment, crossUi, primaryUi)
			else
				segment:SetSize(crossUi, primaryUi)
			end
			fill:SetOrientation("VERTICAL")
			if ResourceBars.Pixel and ResourceBars.Pixel.Point then
				ResourceBars.Pixel.Point(segment, "BOTTOMLEFT", inner, "BOTTOMLEFT", 0, offsetUi)
			else
				segment:SetPoint("BOTTOMLEFT", inner, "BOTTOMLEFT", 0, offsetUi)
			end
		else
			if ResourceBars.Pixel and ResourceBars.Pixel.Size then
				ResourceBars.Pixel.Size(segment, primaryUi, crossUi)
			else
				segment:SetSize(primaryUi, crossUi)
			end
			fill:SetOrientation("HORIZONTAL")
			if ResourceBars.Pixel and ResourceBars.Pixel.Point then
				ResourceBars.Pixel.Point(segment, "TOPLEFT", inner, "TOPLEFT", offsetUi, 0)
			else
				segment:SetPoint("TOPLEFT", inner, "TOPLEFT", offsetUi, 0)
			end
		end
		applyDiscreteSegmentBorder(segment, bar, useSegmentBorders and borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA)
		if ResourceBars.ApplySegmentContentInset then
			ResourceBars.ApplySegmentContentInset(segment, 0)
		end
		if ResourceBars.ApplySegmentBackgroundInset then ResourceBars.ApplySegmentBackgroundInset(segment, cfg) end
		if not segment:IsShown() then segment:Show() end
	end

	for i = count + 1, #segments do
		if segments[i] then
			segments[i]:Hide()
			if segments[i]._rbSegmentBorder then segments[i]._rbSegmentBorder:Hide() end
		end
	end

	ResourceBars.LayoutSegmentBoundaryMarks(
		bar,
		inner,
		count,
		vertical,
		segmentOffsetsPx,
		segmentSizesPx,
		scale,
		factor,
		gapMarks,
		boundaryEnabled,
		borderTexture,
		borderEdgeSize,
		borderOutset,
		borderR,
		borderG,
		borderB,
		borderA
	)

	bar._rbDiscreteCount = count
	bar._rbDiscreteVertical = vertical
	bar._rbDiscreteGapRequested = requestedGap
	bar._rbDiscreteGap = pixelsToUi(gapPx, scale, factor)
	bar._rbDiscreteGapPixels = gapPx
	bar._rbDiscreteSpanPixels = spanPx
	bar._rbDiscreteCrossPixels = crossPx
	bar._rbDiscreteReverse = reverse
	bar._rbDiscreteBoundaryEnabled = boundaryEnabled
	bar._rbDiscreteBoundaryTexture = borderTexture
	bar._rbDiscreteBoundaryEdgeSize = borderEdgeSize
	bar._rbDiscreteBoundaryOutset = borderOutset
	bar._rbDiscreteBoundaryR = borderR
	bar._rbDiscreteBoundaryG = borderG
	bar._rbDiscreteBoundaryB = borderB
	bar._rbDiscreteBoundaryA = borderA
end

function ResourceBars.UpdateDiscreteSegments(bar, cfg, count, value, color, texturePath, chargedPoints)
	if not bar then return end
	count = tonumber(count) or 0
	if count < 1 then
		ResourceBars.HideDiscreteSegments(bar)
		bar._rbDiscreteCount = 0
		return
	end

	local vertical = cfg and cfg.verticalFill == true
	local reverse = cfg and cfg.reverseFill == true
	local gap = resolveDiscreteSegmentGap(cfg)
	local useSegmentBorders = count > 1 and ((ResourceBars.ShouldUsePerSegmentBorders and ResourceBars.ShouldUsePerSegmentBorders(cfg)) or gap > 0)
	local borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA = resolveDiscreteSegmentBorderStyle(cfg, true)
	local boundaryEnabled = count > 1 and not useSegmentBorders and borderEnabled
	if count < 2 then gap = 0 end
	local boundaryStyleChanged = bar._rbDiscreteBoundaryEnabled ~= boundaryEnabled
	if boundaryEnabled then
		boundaryStyleChanged = boundaryStyleChanged
			or bar._rbDiscreteBoundaryTexture ~= borderTexture
			or bar._rbDiscreteBoundaryEdgeSize ~= borderEdgeSize
			or bar._rbDiscreteBoundaryOutset ~= borderOutset
			or bar._rbDiscreteBoundaryR ~= borderR
			or bar._rbDiscreteBoundaryG ~= borderG
			or bar._rbDiscreteBoundaryB ~= borderB
			or bar._rbDiscreteBoundaryA ~= borderA
	end

	if
		not bar._rbDiscreteSegments
		or bar._rbDiscreteCount ~= count
		or bar._rbDiscreteVertical ~= vertical
		or bar._rbDiscreteGapRequested ~= gap
		or bar._rbDiscreteReverse ~= reverse
		or boundaryStyleChanged
	then
		ResourceBars.LayoutDiscreteSegments(bar, cfg, count, texturePath)
	end

	local segments = bar._rbDiscreteSegments
	if not segments then return end
	local parentTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if parentTex then parentTex:SetAlpha(0) end

	local baseR, baseG, baseB, baseA = normalizeGradientColor(color)
	local dimFactor = 0.35
	local dimR, dimG, dimB, dimA = baseR * dimFactor, baseG * dimFactor, baseB * dimFactor, (baseA or 1) * 0.9
	local fillColorKey = baseR .. ":" .. baseG .. ":" .. baseB .. ":" .. baseA
	local texPath = texturePath or "Interface\\Buttons\\WHITE8x8"
	local segmentBgPath, segmentBgR, segmentBgG, segmentBgB, segmentBgA, segmentBgVisible = resolveDiscreteSegmentBackground(cfg, texPath, dimR, dimG, dimB, dimA)
	local bgColorKey = segmentBgR .. ":" .. segmentBgG .. ":" .. segmentBgB .. ":" .. segmentBgA
	local valueIsSecret = issecretvalue and issecretvalue(value)
	local clamped = 0
	if not valueIsSecret then
		clamped = tonumber(value) or 0
		if clamped < 0 then
			clamped = 0
		elseif clamped > count then
			clamped = count
		end
	end
	local useMaelstromCarryFill, carryOverflow, carryR, carryG, carryB, carryA
	if not valueIsSecret then
		useMaelstromCarryFill, carryOverflow, carryR, carryG, carryB, carryA = resolveMaelstromCarryMode(bar, cfg, count, clamped)
		if useMaelstromCarryFill then clamped = count end
	end
	local chargedStyleActive = bar and bar._rbType == "COMBO_POINTS" and addon and addon.variables and addon.variables.unitClass == "ROGUE" and (cfg and cfg.useChargedComboStyling ~= false)
	local chargedFillActive = chargedStyleActive and (cfg.chargedComboAffectFill ~= false)
	local chargedBgActive = chargedStyleActive and (cfg.chargedComboAffectBackground ~= false)
	local chargedUseCustomFillColor = chargedFillActive and cfg.chargedComboUseCustomFillColor == true
	local chargedUseCustomBackgroundColor = chargedBgActive and cfg.chargedComboUseCustomBackgroundColor == true
	local function clamp01(value, defaultValue)
		local n = tonumber(value)
		if n == nil then n = defaultValue end
		if n < 0 then
			n = 0
		elseif n > 1 then
			n = 1
		end
		return n
	end
	local chargedFillLighten = clamp01(cfg and cfg.chargedComboFillLighten, 0.35)
	local chargedFillAlphaBoost = clamp01(cfg and cfg.chargedComboFillAlphaBoost, 0.10)
	local chargedBackgroundLighten = clamp01(cfg and cfg.chargedComboBackgroundLighten, 0.30)
	local chargedBackgroundAlphaBoost = clamp01(cfg and cfg.chargedComboBackgroundAlphaBoost, 0.10)
	local chargedFillCustomR, chargedFillCustomG, chargedFillCustomB, chargedFillCustomA
	if chargedUseCustomFillColor then
		chargedFillCustomR, chargedFillCustomG, chargedFillCustomB, chargedFillCustomA = normalizeGradientColor((cfg and cfg.chargedComboFillColor) or { 1.0, 0.95, 0.45, 1.0 })
	end
	local chargedBgCustomR, chargedBgCustomG, chargedBgCustomB, chargedBgCustomA
	if chargedUseCustomBackgroundColor then
		chargedBgCustomR, chargedBgCustomG, chargedBgCustomB, chargedBgCustomA = normalizeGradientColor((cfg and cfg.chargedComboBackgroundColor) or { 0.75, 0.60, 0.25, 0.75 })
	end

	for physicalIndex = 1, count do
		local sb = segments[physicalIndex]
		if sb then
			local fill = sb.fill or sb
			local logicalIndex = reverse and (count - physicalIndex + 1) or physicalIndex
			local isChargedPoint = type(chargedPoints) == "table" and chargedPoints[logicalIndex] == true
			local segmentValue
			if not valueIsSecret then
				segmentValue = clamped - (logicalIndex - 1)
				if segmentValue < 0 then
					segmentValue = 0
				elseif segmentValue > 1 then
					segmentValue = 1
				end
			end

			local textureReset = ensureStatusBarTexturePath(fill, texPath)
			if fill.SetReverseFill then fill:SetReverseFill(reverse) end
			applyDiscreteSegmentBorder(sb, bar, useSegmentBorders and borderEnabled, borderTexture, borderEdgeSize, borderOutset, borderR, borderG, borderB, borderA)
			if ResourceBars.ApplySegmentContentInset then
				ResourceBars.ApplySegmentContentInset(sb, 0)
			end
			if ResourceBars.ApplySegmentBackgroundInset then ResourceBars.ApplySegmentBackgroundInset(sb, cfg) end
			if sb._rbSegmentBg then
				if segmentBgVisible then
					local bgR, bgG, bgB, bgA = segmentBgR, segmentBgG, segmentBgB, segmentBgA
					local segmentBgColorKey = bgColorKey
					if isChargedPoint and chargedBgActive then
						if chargedUseCustomBackgroundColor then
							bgR, bgG, bgB, bgA = chargedBgCustomR, chargedBgCustomG, chargedBgCustomB, chargedBgCustomA
						else
							bgR = min(1, bgR + (1 - bgR) * chargedBackgroundLighten)
							bgG = min(1, bgG + (1 - bgG) * chargedBackgroundLighten)
							bgB = min(1, bgB + (1 - bgB) * chargedBackgroundLighten)
							bgA = min(1, (bgA or 1) + chargedBackgroundAlphaBoost)
						end
						segmentBgColorKey = bgR .. ":" .. bgG .. ":" .. bgB .. ":" .. bgA .. ":charged"
					end
					if sb._rbSegmentBgPath ~= segmentBgPath then
						sb._rbSegmentBg:SetTexture(segmentBgPath)
						if ResourceBars.ApplyTexturePixelSnapping then ResourceBars.ApplyTexturePixelSnapping(sb._rbSegmentBg, 0) end
						sb._rbSegmentBgPath = segmentBgPath
					end
					if sb._rbSegmentBgColorKey ~= segmentBgColorKey then
						sb._rbSegmentBg:SetVertexColor(bgR, bgG, bgB, bgA)
						sb._rbSegmentBgColorKey = segmentBgColorKey
					end
					if not sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Show() end
				else
					if sb._rbSegmentBg:IsShown() then sb._rbSegmentBg:Hide() end
					sb._rbSegmentBgPath = nil
					sb._rbSegmentBgColorKey = nil
				end
			end
			local segmentR, segmentG, segmentB, segmentA = baseR, baseG, baseB, baseA
			local segmentColorKey = fillColorKey
			if useMaelstromCarryFill and logicalIndex > carryOverflow then
				segmentR, segmentG, segmentB, segmentA = carryR, carryG, carryB, carryA
				segmentColorKey = segmentR .. ":" .. segmentG .. ":" .. segmentB .. ":" .. segmentA
			end
			if isChargedPoint and chargedFillActive then
				if chargedUseCustomFillColor then
					segmentR, segmentG, segmentB, segmentA = chargedFillCustomR, chargedFillCustomG, chargedFillCustomB, chargedFillCustomA
				else
					segmentR = min(1, segmentR + (1 - segmentR) * chargedFillLighten)
					segmentG = min(1, segmentG + (1 - segmentG) * chargedFillLighten)
					segmentB = min(1, segmentB + (1 - segmentB) * chargedFillLighten)
					segmentA = min(1, (segmentA or 1) + chargedFillAlphaBoost)
				end
			end
			segmentColorKey = segmentR .. ":" .. segmentG .. ":" .. segmentB .. ":" .. segmentA
			if textureReset or fill._rbSegmentFillColorKey ~= segmentColorKey then
				if ResourceBars.SetStatusBarColorWithGradient then
					ResourceBars.SetStatusBarColorWithGradient(fill, cfg, segmentR, segmentG, segmentB, segmentA)
				else
					fill:SetStatusBarColor(segmentR, segmentG, segmentB, segmentA or 1)
				end
				fill._rbSegmentFillColorKey = segmentColorKey
			elseif ResourceBars.RefreshStatusBarGradient then
				ResourceBars.RefreshStatusBarGradient(fill, cfg, segmentR, segmentG, segmentB, segmentA)
			end

			if valueIsSecret then
				fill:SetMinMaxValues(logicalIndex - 1, logicalIndex)
				fill:SetValue(value)
			else
				fill:SetMinMaxValues(0, 1)
				local pixel = getPixelHelper()
				if pixel and pixel.SetStatusBarValue then
					pixel.SetStatusBarValue(fill, segmentValue, false, true)
				else
					fill:SetValue(segmentValue)
				end
			end
			if not sb:IsShown() then sb:Show() end
		end
	end

	for i = count + 1, #segments do
		if segments[i] then
			segments[i]:Hide()
			if segments[i]._rbSegmentBorder then segments[i]._rbSegmentBorder:Hide() end
		end
	end
end

function ResourceBars.ApplyBarGradient(bar, cfg, baseR, baseG, baseB, baseA, force)
	if not bar or not cfg or cfg.useGradient ~= true then return false end
	local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if not tex or not tex.SetGradient then return false end
	local usesSecretBase = hasSecretGradientColor(baseR, baseG, baseB, baseA)
	local sr, sg, sb, sa, er, eg, eb, ea
	if usesSecretBase then
		-- Secret colors cannot be used in Lua arithmetic. Fall back to a solid fill instead of
		-- multiplying the configured gradient against the protected color values.
		sr, sg, sb, sa, er, eg, eb, ea = resolveSolidGradientColors(baseR, baseG, baseB, baseA)
	else
		sr, sg, sb, sa, er, eg, eb, ea = resolveGradientColors(cfg, baseR, baseG, baseB, baseA)
	end
	local direction = (cfg and cfg.gradientDirection) or "VERTICAL"
	if type(direction) == "string" then direction = direction:upper() end
	if direction ~= "HORIZONTAL" then direction = "VERTICAL" end
	if
		not usesSecretBase
		and not force
		and bar._rbGradientEnabled
		and not bar._rbGradUsesSecretBase
		and bar._rbGradientTex == tex
		and bar._rbGradDir == direction
		and bar._rbGradSR == sr
		and bar._rbGradSG == sg
		and bar._rbGradSB == sb
		and bar._rbGradSA == sa
		and bar._rbGradER == er
		and bar._rbGradEG == eg
		and bar._rbGradEB == eb
		and bar._rbGradEA == ea
	then
		return true
	end
	if usesSecretBase then
		-- Retail can return protected status-bar colors here. Keep the already-applied solid/curve tint
		-- and skip SetGradient entirely instead of rewrapping secret values through CreateColor.
		debugGradient(bar, "skip-secret", cfg, baseR, baseG, baseB, baseA, sr, sg, sb, sa, er, eg, eb, ea, force)
		clearGradientState(bar)
		return false
	end
	if not canCreateGradientColor(sr, sg, sb, sa) or not canCreateGradientColor(er, eg, eb, ea) then
		debugGradient(bar, "skip-invalid", cfg, baseR, baseG, baseB, baseA, sr, sg, sb, sa, er, eg, eb, ea, force)
		clearGradientState(bar)
		return false
	end
	local startColor = CreateColor(sr, sg, sb, sa)
	local endColor = CreateColor(er, eg, eb, ea)
	tex:SetGradient(direction, startColor, endColor)
	debugGradient(bar, "apply", cfg, baseR, baseG, baseB, baseA, sr, sg, sb, sa, er, eg, eb, ea, force)
	bar._rbGradientEnabled = true
	bar._rbGradientTex = tex
	bar._rbGradDir = direction
	bar._rbGradUsesSecretBase = usesSecretBase or nil
	if usesSecretBase then
		bar._rbGradSR, bar._rbGradSG, bar._rbGradSB, bar._rbGradSA = nil, nil, nil, nil
		bar._rbGradER, bar._rbGradEG, bar._rbGradEB, bar._rbGradEA = nil, nil, nil, nil
	else
		bar._rbGradSR, bar._rbGradSG, bar._rbGradSB, bar._rbGradSA = sr, sg, sb, sa
		bar._rbGradER, bar._rbGradEG, bar._rbGradEB, bar._rbGradEA = er, eg, eb, ea
	end
	return true
end

function ResourceBars.SetStatusBarColorWithGradient(bar, cfg, r, g, b, a, force)
	if not bar then return end
	local alpha = a or 1
	local hasSecretColor = hasSecretGradientColor(r, g, b, alpha)
	local currentColorMatches = false
	if not hasSecretColor and bar.GetStatusBarColor then
		local cr, cg, cb, ca = bar:GetStatusBarColor()
		local currentHasSecret = issecretvalue and (issecretvalue(cr) or issecretvalue(cg) or issecretvalue(cb) or issecretvalue(ca))
		if not currentHasSecret then currentColorMatches = cr == r and cg == g and cb == b and ca == alpha end
	end
	if
		not hasSecretColor
		and not force
		and not bar._lastColorHasSecret
		and bar._lastColor
		and bar._lastColor[1] == r
		and bar._lastColor[2] == g
		and bar._lastColor[3] == b
		and bar._lastColor[4] == alpha
		and currentColorMatches
		and not (cfg and cfg.useGradient == true)
		and not bar._rbGradientEnabled
	then
		return
	end
	bar:SetStatusBarColor(r, g, b, alpha)
	bar._lastColor = bar._lastColor or {}
	bar._lastColor[1], bar._lastColor[2], bar._lastColor[3], bar._lastColor[4] = r, g, b, alpha
	bar._lastColorHasSecret = hasSecretColor or nil
	if cfg and cfg.useGradient == true then
		ResourceBars.ApplyBarGradient(bar, cfg, r, g, b, alpha, true)
	elseif bar._rbGradientEnabled then
		debugGradient(bar, "clear", cfg, r, g, b, a)
		clearGradientState(bar)
	end
end

function ResourceBars.RefreshStatusBarGradient(bar, cfg, r, g, b, a)
	if not bar then return end
	if cfg and cfg.useGradient == true then
		local br, bg, bb, ba = r, g, b, a
		if br == nil then
			if bar._lastColor then
				br, bg, bb, ba = bar._lastColor[1], bar._lastColor[2], bar._lastColor[3], bar._lastColor[4]
			elseif bar.GetStatusBarColor then
				br, bg, bb, ba = bar:GetStatusBarColor()
			end
		end
		ResourceBars.ApplyBarGradient(bar, cfg, br or 1, bg or 1, bb or 1, ba or 1, true)
	elseif bar._rbGradientEnabled then
		local br, bg, bb, ba = r, g, b, a
		if br == nil then
			if bar._lastColor then
				br, bg, bb, ba = bar._lastColor[1], bar._lastColor[2], bar._lastColor[3], bar._lastColor[4]
			elseif bar.GetStatusBarColor then
				br, bg, bb, ba = bar:GetStatusBarColor()
			end
		end
		if br ~= nil then bar:SetStatusBarColor(br, bg or 1, bb or 1, ba or 1) end
		clearGradientState(bar)
	end
end

function ResourceBars.ResolveRuneCooldownColor(cfg)
	local fallback = 0.35
	local c = cfg and cfg.runeCooldownColor
	return c and (c[1] or fallback) or fallback, c and (c[2] or fallback) or fallback, c and (c[3] or fallback) or fallback, c and (c[4] or 1) or 1
end
