local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Glow = addon.Glow or {}
local Glow = addon.Glow

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local pairs = pairs
local issecretvalue = _G.issecretvalue
local tonumber = tonumber
local tostring = tostring
local type = type

Glow.STYLE = Glow.STYLE or {}
Glow.STYLE.BLIZZARD = "BLIZZARD"
Glow.STYLE.MARCHING_ANTS = "MARCHING_ANTS"
Glow.STYLE.FLASH = "FLASH"
Glow.STYLE.BUTTON = "BUTTON"
Glow.STYLE.PIXEL = "PIXEL"
Glow.STYLE.PULSING = "PULSING"
Glow.STYLE.SOLID = "SOLID"
Glow.STYLE.TINT_BORDER = "TINT_BORDER"
Glow.STYLE.SHINE = "SHINE"
Glow.STYLE.PROC = "PROC"
Glow.STYLE.AUTOCAST = Glow.STYLE.SHINE

local BLIZZARD_GLOW_TEXTURE = [[Interface\SpellActivationOverlay\IconAlert]]
local BLIZZARD_ANTS_TEXTURE = [[Interface\SpellActivationOverlay\IconAlertAnts]]
local PIXEL_GLOW_TEXTURE = [[Interface\Buttons\WHITE8X8]]
local HEXAGON_BORDER_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\hexagon_1px.tga]]
local DIAMOND_GLOW_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\diamond_glow.tga]]
local ROUND_STAR_GLOW_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\round_star_border.tga]]
local ROUND_PULSING_ATLAS = "ChallengeMode-KeystoneSlotFrameGlow"
local MARCHING_ANTS_ATLAS = "VisualAlert_Ants_Flipbook"
local FLASH_GLOW_ATLAS = "UI-CooldownManager-VisualAlert-Glow"
local BLIZZ_CONTAINER_RATIO = 66 / 45
local FLASH_LEVEL_OFFSET = -2
local DEFAULT_GLOW_SIZE = 36

local VALID_STRATA = {
	BACKGROUND = true,
	LOW = true,
	MEDIUM = true,
	HIGH = true,
	DIALOG = true,
	FULLSCREEN = true,
	FULLSCREEN_DIALOG = true,
	TOOLTIP = true,
}

local function normalizeColor(color, fallback)
	fallback = fallback or { 1, 1, 1, 1 }
	if type(color) ~= "table" then return fallback end
	return {
		tonumber(color.r or color[1]) or fallback[1],
		tonumber(color.g or color[2]) or fallback[2],
		tonumber(color.b or color[3]) or fallback[3],
		tonumber(color.a or color[4]) or fallback[4],
	}
end

local function normalizeKey(key)
	if key == nil then return "" end
	return tostring(key)
end

local function normalizeStyle(style)
	local normalized = tostring(style or Glow.STYLE.BLIZZARD):upper()
	if normalized == "BLIZZARD" then return Glow.STYLE.BLIZZARD end
	if normalized == "MARCHING_ANTS" or normalized == "MARCHINGANTS" or normalized == "ANTS" then return Glow.STYLE.MARCHING_ANTS end
	if normalized == "FLASH" then return Glow.STYLE.FLASH end
	if normalized == "BUTTON" then return Glow.STYLE.BUTTON end
	if normalized == "PIXEL" then return Glow.STYLE.PIXEL end
	if normalized == "PULSING" or normalized == "PULSE" then return Glow.STYLE.PULSING end
	if normalized == "SOLID" or normalized == "SOLID_BORDER" then return Glow.STYLE.SOLID end
	if normalized == "TINT_BORDER" or normalized == "BORDER_TINT" then return Glow.STYLE.TINT_BORDER end
	if normalized == "SHINE" or normalized == "AUTOCAST" or normalized == "AUTOCAST_SHINE" then return Glow.STYLE.SHINE end
	if normalized == "PROC" or normalized == "PROC_GLOW" then return Glow.STYLE.PROC end
	return Glow.STYLE.BLIZZARD
end

local function isHexagonShape(opts)
	local shape = type(opts) == "table" and opts.shape or nil
	if addon.IconShape and addon.IconShape.Normalize then
		return addon.IconShape.Normalize(shape) == addon.IconShape.HEXAGON
	end
	return type(shape) == "string" and shape:upper() == "HEXAGON"
end

local function isRoundShape(opts)
	local shape = type(opts) == "table" and opts.shape or nil
	if addon.IconShape and addon.IconShape.Normalize then
		return addon.IconShape.Normalize(shape) == addon.IconShape.ROUND
	end
	if type(shape) ~= "string" then return false end
	shape = shape:upper()
	return shape == "ROUND" or shape == "CIRCLE"
end

local function isRoundStarShape(opts)
	local shape = type(opts) == "table" and opts.shape or nil
	if addon.IconShape and addon.IconShape.Normalize then
		return addon.IconShape.Normalize(shape) == addon.IconShape.ROUND_STAR
	end
	if type(shape) ~= "string" then return false end
	shape = shape:upper()
	return shape == "ROUND_STAR" or shape == "ROUNDSTAR" or shape == "ROUND-STAR"
end

local function isDiamondShape(opts)
	local shape = type(opts) == "table" and opts.shape or nil
	if addon.IconShape and addon.IconShape.Normalize then
		return addon.IconShape.Normalize(shape) == addon.IconShape.DIAMOND
	end
	return type(shape) == "string" and shape:upper() == "DIAMOND"
end

local function setFullTexture(texture, path)
	if not texture then return end
	texture:SetTexture(path)
	if texture.SetTexCoord then texture:SetTexCoord(0, 1, 0, 1) end
end

local function roundOffset(value)
	value = tonumber(value) or 0
	if value < 0 then return ceil(value - 0.5) end
	return floor(value + 0.5)
end

local function normalizeInset(opts)
	if type(opts) ~= "table" then return 0 end
	return roundOffset(opts.inset)
end

local function normalizeScalar(opts, key, fallback)
	if type(opts) ~= "table" then return fallback end
	local value = tonumber(opts[key])
	if value == nil then return fallback end
	return value
end

local function normalizeVisualScale(opts, fallback)
	local explicitScale = normalizeScalar(opts, "scale", nil)
	if explicitScale and explicitScale > 0 then return explicitScale end

	local thickness = normalizeScalar(opts, "thickness", nil)
	if thickness == nil then thickness = normalizeScalar(opts, "th", nil) end
	if thickness == nil then return fallback or 1 end
	return max(0.1, 1 + ((thickness - 2) * 0.1))
end

local function normalizePositiveNumber(value, fallback)
	if issecretvalue and issecretvalue(value) then return fallback end
	value = tonumber(value)
	if value and value > 0 then return value end
	return fallback
end

local function getCachedGlowDimension(frame, key)
	if type(frame) ~= "table" then return nil end
	local cache = frame._eqolGlowSizeCache
	if type(cache) ~= "table" then return nil end
	local value = cache[key]
	if type(value) == "number" and value > 0 then return value end
	return nil
end

local function rememberGlowSize(frame, width, height)
	if type(frame) ~= "table" then return end
	local cache = frame._eqolGlowSizeCache
	if type(cache) ~= "table" then
		cache = {}
		frame._eqolGlowSizeCache = cache
	end
	if type(width) == "number" and width > 0 then cache.width = width end
	if type(height) == "number" and height > 0 then cache.height = height end
end

local function getGlowFallbackDimension(frame, key)
	local cached = getCachedGlowDimension(frame, key)
	if cached then return cached end
	if type(frame) ~= "table" then return DEFAULT_GLOW_SIZE end

	local target = frame._eqolGlowTarget
	if target and target ~= frame then
		local targetCached = getCachedGlowDimension(target, key)
		if targetCached then return targetCached end
	end

	local visualSize = normalizePositiveNumber(frame._eqolVisualSize, nil)
	if visualSize then return visualSize end

	local baseSlotSize = normalizePositiveNumber(frame._eqolBaseSlotSize, nil)
	if baseSlotSize then return baseSlotSize end

	if target and target ~= frame then
		local targetVisualSize = normalizePositiveNumber(target._eqolVisualSize, nil)
		if targetVisualSize then return targetVisualSize end

		local targetBaseSlotSize = normalizePositiveNumber(target._eqolBaseSlotSize, nil)
		if targetBaseSlotSize then return targetBaseSlotSize end
	end

	return DEFAULT_GLOW_SIZE
end

local function getSafeFrameDimension(frame, key)
	if not (frame and type(frame) == "table") then return DEFAULT_GLOW_SIZE end
	local getter = key == "width" and frame.GetWidth or frame.GetHeight
	local fallback = getGlowFallbackDimension(frame, key)
	if not getter then return fallback end

	local ok, value = pcall(getter, frame)
	if not ok then return fallback end

	value = normalizePositiveNumber(value, nil)
	if value then return value end
	return fallback
end

local function getSafeFrameSize(frame)
	local width = getSafeFrameDimension(frame, "width")
	local height = getSafeFrameDimension(frame, "height")
	rememberGlowSize(frame, width, height)

	local target = type(frame) == "table" and frame._eqolGlowTarget or nil
	if target and target ~= frame then rememberGlowSize(target, width, height) end

	return width, height
end

local function normalizeGlowThrottle(opts)
	local frequency = normalizeScalar(opts, "frequency", nil)
	if frequency and frequency > 0 then
		return 0.25 / frequency * 0.01
	end
	return 0.01
end

local function getGlowAnchorRegion(host)
	local target = host and (host._eqolGlowTarget or host) or nil
	if not target then return host end
	local region = target.Icon or target.icon or target.texture
	if region then return region end
	return target
end

local function resetSpellAlertTextures(frame)
	if not frame then return end
	if frame.spark then
		frame.spark:SetTexture(BLIZZARD_GLOW_TEXTURE)
		frame.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)
	end
	if frame.innerGlow then
		frame.innerGlow:SetTexture(BLIZZARD_GLOW_TEXTURE)
		frame.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
	end
	if frame.innerGlowOver then
		frame.innerGlowOver:SetTexture(BLIZZARD_GLOW_TEXTURE)
		frame.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
	end
	if frame.outerGlow then
		frame.outerGlow:SetTexture(BLIZZARD_GLOW_TEXTURE)
		frame.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
	end
	if frame.outerGlowOver then
		frame.outerGlowOver:SetTexture(BLIZZARD_GLOW_TEXTURE)
		frame.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
	end
	if frame.ants then frame.ants:SetTexture(BLIZZARD_ANTS_TEXTURE) end
end

local function resetMarchingAntsTexture(overlay)
	if not (overlay and overlay.Texture) then return end
	if overlay.Texture.SetAtlas then
		overlay.Texture:SetAtlas(MARCHING_ANTS_ATLAS)
	else
		overlay.Texture:SetTexture(BLIZZARD_GLOW_TEXTURE)
		overlay.Texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
	end
	if overlay.FlipAnim then
		overlay.FlipAnim:SetFlipBookFrameWidth(0)
		overlay.FlipAnim:SetFlipBookFrameHeight(0)
	end
end

local function resetProcGlowTextures(frame)
	if not frame then return end
	if frame.ProcStart and frame.ProcStart.SetAtlas then frame.ProcStart:SetAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook") end
	if frame.ProcLoop and frame.ProcLoop.SetAtlas then frame.ProcLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook") end
	if frame.ProcLoopAnim and frame.ProcLoopAnim.flipbookRepeat then
		frame.ProcLoopAnim.flipbookRepeat:SetFlipBookFrameWidth(0)
		frame.ProcLoopAnim.flipbookRepeat:SetFlipBookFrameHeight(0)
	end
	if frame.ProcStartAnim and frame.ProcStartAnim.flipbookStart then
		frame.ProcStartAnim.flipbookStart:SetFlipBookFrameWidth(0)
		frame.ProcStartAnim.flipbookStart:SetFlipBookFrameHeight(0)
	end
end

local function copyOptions(opts)
	if type(opts) ~= "table" then return opts end
	local copy = {}
	for key, value in pairs(opts) do
		if type(value) == "table" then
			local nested = {}
			for nestedKey, nestedValue in pairs(value) do
				nested[nestedKey] = nestedValue
			end
			copy[key] = nested
		else
			copy[key] = value
		end
	end
	return copy
end

local function getState(target, key, create)
	if not target then return nil end
	local states = target._eqolGlowStates
	if not states then
		if not create then return nil end
		states = {}
		target._eqolGlowStates = states
	end
	local state = states[key]
	if state or not create then return state end
	local host = CreateFrame("Frame", nil, target)
	host:EnableMouse(false)
	host:SetAllPoints(target)
	host:Hide()
	state = { host = host }
	states[key] = state
	return state
end

local function configureHost(target, state, opts)
	local host = state and state.host
	if not host then return end
	host:SetParent(target)
	host._eqolGlowTarget = target
	host:EnableMouse(false)
	host:ClearAllPoints()
	host:SetAllPoints(target)

	local strata = target:GetFrameStrata()
	local requestedStrata = type(opts) == "table" and opts.strata or nil
	if type(requestedStrata) == "string" then
		local upper = tostring(requestedStrata):upper()
		if VALID_STRATA[upper] then strata = upper end
	end
	host:SetFrameStrata(strata)

	local baseLevel = target:GetFrameLevel() or 0
	local offset = type(opts) == "table" and roundOffset(opts.hostFrameLevelOffset) or 0
	host:SetFrameLevel(max(0, baseLevel + offset))
	host.cooldown = (type(opts) == "table" and opts.cooldown) or target.cooldown
	host:Show()
end

local function applyStateAlpha(state)
	local host = state and state.host
	if not host then return end
	if state.alphaMode == "boolean" then
		local onAlpha = tonumber(state.alphaOn)
		local offAlpha = tonumber(state.alphaOff)
		if onAlpha == nil then onAlpha = 1 end
		if offAlpha == nil then offAlpha = 0 end
		if host.SetAlphaFromBoolean and state.alphaCondition ~= nil then
			host:SetAlphaFromBoolean(state.alphaCondition, onAlpha, offAlpha)
		elseif type(state.alphaCondition) == "boolean" then
			host:SetAlpha(state.alphaCondition and onAlpha or offAlpha)
		else
			host:SetAlpha(offAlpha)
		end
		return
	end
	host:SetAlpha(tonumber(state.alphaValue) or 1)
end

local function anchorCooldownViewerAlertScaled(frame, host, inset, scale)
	if not (frame and host) then return end
	inset = roundOffset(inset)
	scale = normalizePositiveNumber(scale, 1)
	local width, height = getSafeFrameSize(host)
	local left = 8 + inset
	local right = 9 + inset
	local top = 8 + inset
	local bottom = 9 + inset
	local scaledExtraX = ((width + left + right) * scale - (width + left + right)) / 2
	local scaledExtraY = ((height + top + bottom) * scale - (height + top + bottom)) / 2
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", host, "TOPLEFT", -left - scaledExtraX, top + scaledExtraY)
	frame:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", right + scaledExtraX, -bottom - scaledExtraY)
end

local function ensureMarchingAntsOverlay(host)
	local overlay = host and host._eqolMarchingAntsOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay.Texture = overlay:CreateTexture(nil, "ARTWORK")
	overlay.Texture:SetAllPoints()
	overlay.Texture:SetAlpha(0)
	if overlay.Texture.SetAtlas then
		overlay.Texture:SetAtlas(MARCHING_ANTS_ATLAS)
	else
		overlay.Texture:SetTexture(BLIZZARD_GLOW_TEXTURE)
		overlay.Texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
	end

	local anim = overlay:CreateAnimationGroup()
	anim:SetLooping("REPEAT")
	anim:SetToFinalAlpha(true)
	overlay.Anim = anim

	local alphaAnim = anim:CreateAnimation("Alpha")
	alphaAnim:SetChildKey("Texture")
	alphaAnim:SetFromAlpha(1)
	alphaAnim:SetToAlpha(1)
	alphaAnim:SetDuration(0.001)
	alphaAnim:SetOrder(0)

	local flipAnim
	if anim.CreateAnimation then
		local ok, created = pcall(anim.CreateAnimation, anim, "FlipBook")
		if ok then flipAnim = created end
	end
	if flipAnim and flipAnim.SetFlipBookRows then
		flipAnim:SetChildKey("Texture")
		flipAnim:SetDuration(1)
		flipAnim:SetOrder(1)
		flipAnim:SetFlipBookRows(6)
		flipAnim:SetFlipBookColumns(5)
		flipAnim:SetFlipBookFrames(30)
		flipAnim:SetFlipBookFrameWidth(0)
		flipAnim:SetFlipBookFrameHeight(0)
		overlay.FlipAnim = flipAnim
	end

	local function resumeMarchingAnts(self)
		if not self then return end
		if self.Texture then self.Texture:SetAlpha(1) end
		if self.Anim and self.Anim.IsPlaying and not self.Anim:IsPlaying() then self.Anim:Play() end
	end

	overlay:SetScript("OnShow", function(self)
		resumeMarchingAnts(self)
	end)

	overlay:SetScript("OnHide", function(self)
		if self.Anim and self.Anim.IsPlaying and self.Anim:IsPlaying() then self.Anim:Stop() end
		if self.Texture then self.Texture:SetAlpha(0) end
	end)

	host._eqolMarchingAntsOverlay = overlay
	return overlay
end

local function updateMarchingAntsOverlay(host, opts)
	local overlay = ensureMarchingAntsOverlay(host)
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })
	local scale = normalizeVisualScale(opts, 1)
	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + 3))
	anchorCooldownViewerAlertScaled(overlay, host, normalizeInset(opts), scale)
	overlay.Texture:SetVertexColor(color[1], color[2], color[3], color[4])
	resetMarchingAntsTexture(overlay)
	return overlay
end

local function startMarchingAnts(host, opts)
	local overlay = updateMarchingAntsOverlay(host, opts)
	if not overlay then return end
	if overlay.Texture then overlay.Texture:SetAlpha(1) end
	overlay:Show()
	if overlay.Anim and overlay.Anim.IsPlaying and not overlay.Anim:IsPlaying() then overlay.Anim:Play() end
end

local function stopMarchingAnts(host)
	local overlay = host and host._eqolMarchingAntsOverlay
	if not overlay then return end
	if overlay.Anim and overlay.Anim.IsPlaying and overlay.Anim:IsPlaying() then overlay.Anim:Stop() end
	overlay:Hide()
end

local function ensureFlashOverlay(host)
	local overlay = host and host._eqolFlashOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay.Texture = overlay:CreateTexture(nil, "ARTWORK")
	overlay.Texture:SetAllPoints()
	overlay.Texture:SetAlpha(0)
	if overlay.Texture.SetAtlas then
		overlay.Texture:SetAtlas(FLASH_GLOW_ATLAS)
	else
		overlay.Texture:SetTexture(BLIZZARD_GLOW_TEXTURE)
		overlay.Texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
	end

	local anim = overlay:CreateAnimationGroup()
	anim:SetLooping("BOUNCE")
	anim:SetToFinalAlpha(true)
	overlay.Anim = anim

	local alphaAnim = anim:CreateAnimation("Alpha")
	alphaAnim:SetChildKey("Texture")
	alphaAnim:SetDuration(0.5)
	alphaAnim:SetOrder(1)
	alphaAnim:SetSmoothing("IN_OUT")
	alphaAnim:SetFromAlpha(0.25)
	alphaAnim:SetToAlpha(1)
	overlay.AlphaAnim = alphaAnim

	local function resumeFlashOverlay(self)
		if not self then return end
		if self.Texture then
			local alpha = 1
			if self.AlphaAnim and self.AlphaAnim.GetToAlpha then
				local toAlpha = self.AlphaAnim:GetToAlpha()
				if type(toAlpha) == "number" then alpha = toAlpha end
			end
			self.Texture:SetAlpha(alpha)
		end
		if self.Anim and self.Anim.IsPlaying and not self.Anim:IsPlaying() then self.Anim:Play() end
	end

	overlay:SetScript("OnShow", function(self)
		resumeFlashOverlay(self)
	end)

	overlay:SetScript("OnHide", function(self)
		if self.Anim and self.Anim.IsPlaying and self.Anim:IsPlaying() then self.Anim:Stop() end
		if self.Texture then self.Texture:SetAlpha(0) end
	end)

	host._eqolFlashOverlay = overlay
	return overlay
end

local function updateFlashOverlay(host, opts)
	local overlay = ensureFlashOverlay(host)
	local anchor = getGlowAnchorRegion(host)
	local width, height = getSafeFrameSize(anchor)
	local scale = normalizeVisualScale(opts, 1)
	local inset = normalizeInset(opts)
	local xOffset = normalizeScalar(opts, "xOffset", 0)
	local yOffset = normalizeScalar(opts, "yOffset", 0)
	local frameLevel = roundOffset(normalizeScalar(opts, "frameLevel", FLASH_LEVEL_OFFSET))
	local overlayWidth = max(1, (width * BLIZZ_CONTAINER_RATIO * scale) + (inset * 2))
	local overlayHeight = max(1, (height * BLIZZ_CONTAINER_RATIO * scale) + (inset * 2))
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })
	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + frameLevel))
	overlay:ClearAllPoints()
	overlay:SetSize(overlayWidth, overlayHeight)
	overlay:SetPoint("CENTER", anchor, "CENTER", xOffset, yOffset)
	if overlay.SetAlpha then overlay:SetAlpha(normalizeScalar(opts, "intensity", 1) or 1) end
	local hasCustomColor = not (color[1] >= 0.99 and color[2] >= 0.99 and color[3] >= 0.99)
	if overlay.Texture and overlay.Texture.SetDesaturated then overlay.Texture:SetDesaturated(hasCustomColor) end
	overlay.Texture:SetVertexColor(color[1], color[2], color[3], color[4])
	if overlay.AlphaAnim then
		overlay.AlphaAnim:SetFromAlpha(color[4] * 0.25)
		overlay.AlphaAnim:SetToAlpha(color[4])
		overlay.AlphaAnim:SetDuration((normalizeScalar(opts, "frequency", 0.25) or 0.25) * 2)
	end
	return overlay
end

local function startFlash(host, opts)
	local overlay = updateFlashOverlay(host, opts)
	if not overlay then return end
	if overlay.Texture then
		local alpha = 1
		if overlay.AlphaAnim and overlay.AlphaAnim.GetToAlpha then
			local toAlpha = overlay.AlphaAnim:GetToAlpha()
			if type(toAlpha) == "number" then alpha = toAlpha end
		end
		overlay.Texture:SetAlpha(alpha)
	end
	overlay:Show()
	if overlay.Anim and overlay.Anim.IsPlaying and not overlay.Anim:IsPlaying() then overlay.Anim:Play() end
end

local function stopFlash(host)
	local overlay = host and host._eqolFlashOverlay
	if not overlay then return end
	if overlay.Anim and overlay.Anim.IsPlaying and overlay.Anim:IsPlaying() then overlay.Anim:Stop() end
	overlay:Hide()
end

local function ensurePixelTexture(overlay, index)
	local texture = overlay and overlay.textures and overlay.textures[index]
	if texture then return texture end
	texture = overlay:CreateTexture(nil, "ARTWORK")
	texture:SetTexture(PIXEL_GLOW_TEXTURE)
	if texture.SetBlendMode then texture:SetBlendMode("ADD") end
	overlay.textures[index] = texture
	return texture
end

local function ensurePixelBorderTexture(overlay, index)
	local texture = overlay and overlay.borderTextures and overlay.borderTextures[index]
	if texture then return texture end
	texture = overlay:CreateTexture(nil, "BACKGROUND")
	texture:SetTexture(PIXEL_GLOW_TEXTURE)
	if texture.SetBlendMode then texture:SetBlendMode("ADD") end
	overlay.borderTextures[index] = texture
	return texture
end

local function updatePixelBorder(overlay, enabled, thickness, color)
	if not overlay then return end
	if not enabled then
		for i = 1, #(overlay.borderTextures or {}) do
			overlay.borderTextures[i]:Hide()
		end
		return
	end

	local top = ensurePixelBorderTexture(overlay, 1)
	local right = ensurePixelBorderTexture(overlay, 2)
	local bottom = ensurePixelBorderTexture(overlay, 3)
	local left = ensurePixelBorderTexture(overlay, 4)
	local alpha = (color[4] or 1) * 0.25
	for i = 1, 4 do
		overlay.borderTextures[i]:SetVertexColor(color[1], color[2], color[3], alpha)
	end

	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	top:SetHeight(thickness)
	top:Show()

	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(thickness)
	right:Show()

	bottom:ClearAllPoints()
	bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(thickness)
	bottom:Show()

	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	left:SetWidth(thickness)
	left:Show()
end

local function pixelSegmentAvailable(distance, width, height)
	local perimeter = (width + height) * 2
	if perimeter <= 0 then return 0 end
	distance = distance % perimeter
	if distance < width then return width - distance end
	if distance < width + height then return width + height - distance end
	if distance < (width * 2) + height then return (width * 2) + height - distance end
	return perimeter - distance
end

local function drawPixelTexture(texture, overlay, distance, length, thickness, width, height, color)
	if not (texture and overlay) or length <= 0 then
		if texture then texture:Hide() end
		return
	end

	local perimeter = (width + height) * 2
	distance = distance % perimeter
	length = max(1, length)
	texture:ClearAllPoints()
	texture:SetVertexColor(color[1], color[2], color[3], color[4])

	if distance < width then
		texture:SetPoint("TOPLEFT", overlay, "TOPLEFT", distance, 0)
		texture:SetSize(length, thickness)
	elseif distance < width + height then
		texture:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, -(distance - width))
		texture:SetSize(thickness, length)
	elseif distance < (width * 2) + height then
		texture:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -(distance - width - height), 0)
		texture:SetSize(length, thickness)
	else
		texture:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, distance - (width * 2) - height)
		texture:SetSize(thickness, length)
	end
	texture:Show()
end

local function pixelOverlayOnUpdate(self, elapsed)
	local info = self and self.info
	if not info then return end
	self.timer = (self.timer or 0) + (elapsed / info.period)
	if self.timer > 1 or self.timer < -1 then self.timer = self.timer % 1 end

	local width, height = self:GetSize()
	width = max(1, width or 0)
	height = max(1, height or 0)
	local perimeter = (width + height) * 2
	if perimeter <= 0 then return end

	for i = 1, info.count do
		local distance = ((self.timer + (info.step * (i - 1))) % 1) * perimeter
		local firstLength = min(info.length, pixelSegmentAvailable(distance, width, height))
		local textureIndex = ((i - 1) * 2) + 1
		drawPixelTexture(self.textures[textureIndex], self, distance, firstLength, info.thickness, width, height, info.color)
		drawPixelTexture(self.textures[textureIndex + 1], self, distance + firstLength, info.length - firstLength, info.thickness, width, height, info.color)
	end
	for i = (info.count * 2) + 1, #self.textures do
		self.textures[i]:Hide()
	end
end

local function ensurePixelOverlay(host)
	local overlay = host and host._eqolPixelOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay:Hide()
	overlay.textures = {}
	overlay.borderTextures = {}
	overlay:SetScript("OnUpdate", pixelOverlayOnUpdate)
	host._eqolPixelOverlay = overlay
	return overlay
end

local function updatePixelOverlay(host, opts)
	local overlay = ensurePixelOverlay(host)
	if not overlay then return nil end

	local count = roundOffset(type(opts) == "table" and (opts.count or opts.N) or nil)
	if count < 1 then count = 8 end
	if count > 32 then count = 32 end
	local thickness = roundOffset(type(opts) == "table" and (opts.thickness or opts.th) or nil)
	if thickness < 1 then thickness = 2 end
	local inset = normalizeInset(opts)
	local xOffset = roundOffset(normalizeScalar(opts, "xOffset", 0))
	local yOffset = roundOffset(normalizeScalar(opts, "yOffset", 0))
	local frameLevel = roundOffset(normalizeScalar(opts, "frameLevel", 3))
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })
	local frequency = normalizeScalar(opts, "frequency", 0.25)
	local period = 4
	if frequency and frequency ~= 0 then period = 1 / frequency end
	local border = type(opts) == "table" and opts.border == true

	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + frameLevel))
	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", host, "TOPLEFT", -inset + xOffset, inset + yOffset)
	overlay:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", inset + xOffset, -inset + yOffset)

	local width, height = getSafeFrameSize(host)
	width = max(1, width + (inset * 2))
	height = max(1, height + (inset * 2))
	local length = roundOffset(type(opts) == "table" and opts.length or nil)
	if length < 1 then length = floor((width + height) * ((2 / count) - 0.1)) end
	length = max(1, min(length, width, height))

	for i = 1, count * 2 do
		ensurePixelTexture(overlay, i)
	end
	updatePixelBorder(overlay, border, thickness, color)

	overlay.info = overlay.info or {}
	overlay.info.count = count
	overlay.info.step = 1 / count
	overlay.info.period = period
	overlay.info.length = length
	overlay.info.thickness = thickness
	overlay.info.color = color
	pixelOverlayOnUpdate(overlay, 0)
	return overlay
end

local function startPixel(host, opts)
	local overlay = updatePixelOverlay(host, opts)
	if not overlay then return end
	overlay:Show()
end

local function stopPixel(host)
	local overlay = host and host._eqolPixelOverlay
	if not overlay then return end
	for i = 1, #(overlay.textures or {}) do
		overlay.textures[i]:Hide()
	end
	for i = 1, #(overlay.borderTextures or {}) do
		overlay.borderTextures[i]:Hide()
	end
	overlay:Hide()
end

local function ensureSolidOverlay(host)
	local overlay = host and host._eqolSolidOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay:Hide()
	overlay.lines = {}
	for i = 1, 4 do
		local texture = overlay:CreateTexture(nil, "OVERLAY")
		texture:SetTexture(PIXEL_GLOW_TEXTURE)
		overlay.lines[i] = texture
	end
	host._eqolSolidOverlay = overlay
	return overlay
end

local function updateSolidOverlay(host, opts)
	local overlay = ensureSolidOverlay(host)
	if not overlay then return nil end

	local thickness = roundOffset(type(opts) == "table" and (opts.thickness or opts.th) or nil)
	if thickness < 1 then thickness = 2 end
	local inset = normalizeInset(opts)
	local xOffset = roundOffset(normalizeScalar(opts, "xOffset", 0))
	local yOffset = roundOffset(normalizeScalar(opts, "yOffset", 0))
	local frameLevel = roundOffset(normalizeScalar(opts, "frameLevel", 3))
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })

	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + frameLevel))
	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", host, "TOPLEFT", -inset + xOffset, inset + yOffset)
	overlay:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", inset + xOffset, -inset + yOffset)
	overlay:SetAlpha(color[4])

	local top, bottom, left, right = overlay.lines[1], overlay.lines[2], overlay.lines[3], overlay.lines[4]
	for i = 1, 4 do
		overlay.lines[i]:SetVertexColor(color[1], color[2], color[3], 1)
	end
	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", overlay, "TOPLEFT")
	top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT")
	top:SetHeight(thickness)
	bottom:ClearAllPoints()
	bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT")
	bottom:SetHeight(thickness)
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, -thickness)
	left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, thickness)
	left:SetWidth(thickness)
	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, -thickness)
	right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, thickness)
	right:SetWidth(thickness)
	return overlay
end

local function startSolid(host, opts)
	local overlay = updateSolidOverlay(host, opts)
	if overlay then overlay:Show() end
end

local function stopSolid(host)
	local overlay = host and host._eqolSolidOverlay
	if overlay then overlay:Hide() end
end

local function updateTintBorder(host, opts)
	local target = host and host._eqolGlowTarget
	local adapter = target and target._eqolGlowBorderTintAdapter
	if type(adapter) == "function" then adapter(target, host, opts, true) end
end

local function stopTintBorder(host)
	local target = host and host._eqolGlowTarget
	local adapter = target and target._eqolGlowBorderTintAdapter
	if type(adapter) == "function" then adapter(target, host, nil, false) end
end

local function ensurePulsingOverlay(host)
	local overlay = host and host._eqolPulsingOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay:Hide()
	overlay.lines = {}
	for i = 1, 4 do
		local texture = overlay:CreateTexture(nil, "ARTWORK")
		texture:SetTexture(PIXEL_GLOW_TEXTURE)
		if texture.SetBlendMode then texture:SetBlendMode("ADD") end
		overlay.lines[i] = texture
	end
	overlay.shapeTextures = {}
	for i = 1, 3 do
		local texture = overlay:CreateTexture(nil, "OVERLAY")
		texture:SetTexture(HEXAGON_BORDER_TEXTURE)
		if texture.SetBlendMode then texture:SetBlendMode("ADD") end
		texture:Hide()
		overlay.shapeTextures[i] = texture
	end

	local anim = overlay:CreateAnimationGroup()
	anim:SetLooping("BOUNCE")
	anim:SetToFinalAlpha(true)
	overlay.Anim = anim

	local alphaAnim = anim:CreateAnimation("Alpha")
	alphaAnim:SetDuration(0.5)
	alphaAnim:SetOrder(1)
	alphaAnim:SetSmoothing("IN_OUT")
	alphaAnim:SetFromAlpha(0.45)
	alphaAnim:SetToAlpha(1)
	overlay.AlphaAnim = alphaAnim

	overlay:SetScript("OnShow", function(self)
		if self.Anim and self.Anim.IsPlaying and not self.Anim:IsPlaying() then self.Anim:Play() end
	end)
	overlay:SetScript("OnHide", function(self)
		if self.Anim and self.Anim.IsPlaying and self.Anim:IsPlaying() then self.Anim:Stop() end
	end)

	host._eqolPulsingOverlay = overlay
	return overlay
end

local function updatePulsingOverlay(host, opts)
	local overlay = ensurePulsingOverlay(host)
	if not overlay then return nil end

	local thickness = roundOffset(type(opts) == "table" and (opts.thickness or opts.th) or nil)
	if thickness < 1 then thickness = 2 end
	local inset = normalizeInset(opts)
	local xOffset = roundOffset(normalizeScalar(opts, "xOffset", 0))
	local yOffset = roundOffset(normalizeScalar(opts, "yOffset", 0))
	local frameLevel = roundOffset(normalizeScalar(opts, "frameLevel", 3))
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })

	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	if isHexagonShape(opts) or isRoundShape(opts) or isRoundStarShape(opts) or isDiamondShape(opts) then frameLevel = max(frameLevel, 8) end
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + frameLevel))
	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", host, "TOPLEFT", -inset + xOffset, inset + yOffset)
	overlay:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", inset + xOffset, -inset + yOffset)
	overlay:SetAlpha(color[4])

	if isHexagonShape(opts) then
		for i = 1, 4 do
			overlay.lines[i]:Hide()
		end
		local width, height = getSafeFrameSize(host)
		width = max(1, width + (inset * 2))
		height = max(1, height + (inset * 2))
		local layers = overlay.shapeTextures or {}
		local alphas = { 0.18, 0.35, 1 }
		for i = 1, 3 do
			local texture = layers[i]
			if texture then
				local grow = (3 - i) * max(1, thickness)
				setFullTexture(texture, HEXAGON_BORDER_TEXTURE)
				texture:ClearAllPoints()
				texture:SetPoint("CENTER", overlay, "CENTER", 0, 0)
				texture:SetSize(width + (grow * 2), height + (grow * 2))
				texture:SetVertexColor(color[1], color[2], color[3], alphas[i])
				texture:Show()
			end
		end
		if overlay.AlphaAnim then
			local frequency = normalizeScalar(opts, "frequency", 0.25) or 0.25
			overlay.AlphaAnim:SetFromAlpha(color[4] * 0.35)
			overlay.AlphaAnim:SetToAlpha(color[4])
			overlay.AlphaAnim:SetDuration(max(0.05, frequency * 2))
		end
		return overlay
	end

	if isDiamondShape(opts) then
		for i = 1, 4 do
			overlay.lines[i]:Hide()
		end
		local width, height = getSafeFrameSize(host)
		width = max(1, width + (inset * 2))
		height = max(1, height + (inset * 2))
		local layers = overlay.shapeTextures or {}
		local alphas = { 0.18, 0.35, 1 }
		for i = 1, 3 do
			local texture = layers[i]
			if texture then
				local grow = (3 - i) * max(1, thickness)
				setFullTexture(texture, DIAMOND_GLOW_TEXTURE)
				texture:ClearAllPoints()
				texture:SetPoint("CENTER", overlay, "CENTER", 0, 0)
				texture:SetSize(width + (grow * 2), height + (grow * 2))
				texture:SetVertexColor(color[1], color[2], color[3], alphas[i])
				texture:Show()
			end
		end
		if overlay.AlphaAnim then
			local frequency = normalizeScalar(opts, "frequency", 0.25) or 0.25
			overlay.AlphaAnim:SetFromAlpha(color[4] * 0.35)
			overlay.AlphaAnim:SetToAlpha(color[4])
			overlay.AlphaAnim:SetDuration(max(0.05, frequency * 2))
		end
		return overlay
	end

	if isRoundStarShape(opts) then
		for i = 1, 4 do
			overlay.lines[i]:Hide()
		end
		local width, height = getSafeFrameSize(host)
		width = max(1, width + (inset * 2))
		height = max(1, height + (inset * 2))
		local layers = overlay.shapeTextures or {}
		local alphas = { 0.18, 0.35, 1 }
		for i = 1, 3 do
			local texture = layers[i]
			if texture then
				local grow = (3 - i) * max(1, thickness)
				setFullTexture(texture, ROUND_STAR_GLOW_TEXTURE)
				texture:ClearAllPoints()
				texture:SetPoint("CENTER", overlay, "CENTER", 0, 0)
				texture:SetSize(width + (grow * 2), height + (grow * 2))
				texture:SetVertexColor(color[1], color[2], color[3], alphas[i])
				texture:Show()
			end
		end
		if overlay.AlphaAnim then
			local frequency = normalizeScalar(opts, "frequency", 0.25) or 0.25
			overlay.AlphaAnim:SetFromAlpha(color[4] * 0.35)
			overlay.AlphaAnim:SetToAlpha(color[4])
			overlay.AlphaAnim:SetDuration(max(0.05, frequency * 2))
		end
		return overlay
	end

	if isRoundShape(opts) then
		for i = 1, 4 do
			overlay.lines[i]:Hide()
		end
		local width, height = getSafeFrameSize(host)
		width = max(1, width + (inset * 2) + (thickness * 4))
		height = max(1, height + (inset * 2) + (thickness * 4))
		local layers = overlay.shapeTextures or {}
		for i = 2, #layers do
			layers[i]:Hide()
		end
		local texture = layers[1]
		if texture then
			texture:ClearAllPoints()
			texture:SetPoint("CENTER", overlay, "CENTER", 0, 0)
			texture:SetSize(width, height)
			if texture.SetAtlas then
				texture:SetAtlas(ROUND_PULSING_ATLAS, false)
			else
				texture:SetTexture(nil)
			end
			texture:SetVertexColor(color[1], color[2], color[3], 1)
			texture:Show()
		end
		if overlay.AlphaAnim then
			local frequency = normalizeScalar(opts, "frequency", 0.25) or 0.25
			overlay.AlphaAnim:SetFromAlpha(color[4] * 0.35)
			overlay.AlphaAnim:SetToAlpha(color[4])
			overlay.AlphaAnim:SetDuration(max(0.05, frequency * 2))
		end
		return overlay
	end

	for i = 1, #(overlay.shapeTextures or {}) do
		overlay.shapeTextures[i]:Hide()
	end

	local top, right, bottom, left = overlay.lines[1], overlay.lines[2], overlay.lines[3], overlay.lines[4]
	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	top:SetHeight(thickness)

	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(thickness)

	bottom:ClearAllPoints()
	bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(thickness)

	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	left:SetWidth(thickness)

	for i = 1, 4 do
		local line = overlay.lines[i]
		line:SetTexture(PIXEL_GLOW_TEXTURE)
		if line.SetTexCoord then line:SetTexCoord(0, 1, 0, 1) end
		line:SetVertexColor(color[1], color[2], color[3], 1)
		line:Show()
	end
	if overlay.AlphaAnim then
		local frequency = normalizeScalar(opts, "frequency", 0.25) or 0.25
		overlay.AlphaAnim:SetFromAlpha(color[4] * 0.45)
		overlay.AlphaAnim:SetToAlpha(color[4])
		overlay.AlphaAnim:SetDuration(max(0.05, frequency * 2))
	end
	return overlay
end

local function startPulsing(host, opts)
	local overlay = updatePulsingOverlay(host, opts)
	if not overlay then return end
	overlay:Show()
	if overlay.Anim and overlay.Anim.IsPlaying and not overlay.Anim:IsPlaying() then overlay.Anim:Play() end
end

local function stopPulsing(host)
	local overlay = host and host._eqolPulsingOverlay
	if not overlay then return end
	if overlay.Anim and overlay.Anim.IsPlaying and overlay.Anim:IsPlaying() then overlay.Anim:Stop() end
	overlay:Hide()
end

local function createTargetScaleAnim(group, target, order, duration, scaleX, scaleY, delay)
	local anim = group:CreateAnimation("Scale")
	anim:SetTarget(target)
	anim:SetOrder(order)
	anim:SetDuration(duration)
	anim:SetScale(scaleX, scaleY)
	if delay then anim:SetStartDelay(delay) end
	return anim
end

local function createTargetAlphaAnim(group, target, order, duration, fromAlpha, toAlpha, delay)
	local anim = group:CreateAnimation("Alpha")
	anim:SetTarget(target)
	anim:SetOrder(order)
	anim:SetDuration(duration)
	anim:SetFromAlpha(fromAlpha)
	anim:SetToAlpha(toAlpha)
	if delay then anim:SetStartDelay(delay) end
	return anim
end

local function resetBlizzardOverlayVisuals(overlay)
	if not overlay then return end
	overlay.spark:SetAlpha(0)
	overlay.innerGlow:SetAlpha(0)
	overlay.innerGlowOver:SetAlpha(0)
	overlay.outerGlow:SetAlpha(0)
	overlay.outerGlowOver:SetAlpha(0)
	overlay.ants:SetAlpha(0)
end

local function applyBlizzardOverlayRestState(overlay)
	if not overlay then return end
	local width, height = overlay:GetSize()
	width = max(1, width or 0)
	height = max(1, height or 0)
	overlay.spark:SetSize(width, height)
	overlay.spark:SetAlpha(0)
	overlay.innerGlow:SetSize(width, height)
	overlay.innerGlow:SetAlpha(0)
	overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
	overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
	overlay.innerGlowOver:SetAlpha(0)
	overlay.outerGlow:SetSize(width, height)
	overlay.outerGlow:SetAlpha(1)
	overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
	overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
	overlay.outerGlowOver:SetSize(width, height)
	overlay.outerGlowOver:SetAlpha(0)
	overlay.ants:SetSize(width * 0.85, height * 0.85)
	overlay.ants:SetAlpha(1)
end

local function blizzardAnimOutFinished(animGroup)
	local overlay = animGroup and animGroup:GetParent() or nil
	if not overlay then return end
	resetBlizzardOverlayVisuals(overlay)
	overlay:Hide()
end

local function blizzardOverlayOnHide(self)
	if self.animOut and self.animOut:IsPlaying() then self.animOut:Stop() end
	if self.animIn and self.animIn:IsPlaying() then self.animIn:Stop() end
	resetBlizzardOverlayVisuals(self)
end

local function blizzardOverlayOnUpdate(self, elapsed)
	if not (self and self.ants and self.ants:IsShown()) then return end
	local animateTexCoords = _G.TextureUtil and _G.TextureUtil.AnimateTexCoords or _G.AnimateTexCoords
	if animateTexCoords then animateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, self.throttle or 0.01) end
end

local function blizzardAnimInOnPlay(group)
	local overlay = group and group:GetParent() or nil
	if not overlay then return end
	local width, height = overlay:GetSize()
	overlay.spark:SetSize(width, height)
	overlay.spark:SetAlpha(0.3)
	overlay.innerGlow:SetSize(width / 2, height / 2)
	overlay.innerGlow:SetAlpha(1)
	overlay.innerGlowOver:SetAlpha(1)
	overlay.outerGlow:SetSize(width * 2, height * 2)
	overlay.outerGlow:SetAlpha(1)
	overlay.outerGlowOver:SetAlpha(1)
	overlay.ants:SetSize(width * 0.85, height * 0.85)
	overlay.ants:SetAlpha(0)
	overlay:Show()
end

local function blizzardAnimInOnFinished(group)
	local overlay = group and group:GetParent() or nil
	if not overlay then return end
	applyBlizzardOverlayRestState(overlay)
end

local function ensureBlizzardOverlay(host)
	local overlay = host and host._eqolBlizzardOverlay
	if overlay then return overlay end

	overlay = CreateFrame("Frame", nil, host)
	overlay:EnableMouse(false)
	overlay:Hide()

	overlay.spark = overlay:CreateTexture(nil, "BACKGROUND")
	overlay.spark:SetPoint("CENTER")
	overlay.spark:SetTexture(BLIZZARD_GLOW_TEXTURE)
	overlay.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)

	overlay.innerGlow = overlay:CreateTexture(nil, "ARTWORK")
	overlay.innerGlow:SetPoint("CENTER")
	overlay.innerGlow:SetTexture(BLIZZARD_GLOW_TEXTURE)
	overlay.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	overlay.innerGlowOver = overlay:CreateTexture(nil, "ARTWORK")
	overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
	overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
	overlay.innerGlowOver:SetTexture(BLIZZARD_GLOW_TEXTURE)
	overlay.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	overlay.outerGlow = overlay:CreateTexture(nil, "ARTWORK")
	overlay.outerGlow:SetPoint("CENTER")
	overlay.outerGlow:SetTexture(BLIZZARD_GLOW_TEXTURE)
	overlay.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	overlay.outerGlowOver = overlay:CreateTexture(nil, "ARTWORK")
	overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
	overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
	overlay.outerGlowOver:SetTexture(BLIZZARD_GLOW_TEXTURE)
	overlay.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	overlay.ants = overlay:CreateTexture(nil, "OVERLAY")
	overlay.ants:SetPoint("CENTER")
	overlay.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]])

	overlay.animIn = overlay:CreateAnimationGroup()
	createTargetScaleAnim(overlay.animIn, overlay.spark, 1, 0.2, 1.5, 1.5)
	createTargetAlphaAnim(overlay.animIn, overlay.spark, 1, 0.2, 0, 1)
	createTargetScaleAnim(overlay.animIn, overlay.innerGlow, 1, 0.3, 2, 2)
	createTargetScaleAnim(overlay.animIn, overlay.innerGlowOver, 1, 0.3, 2, 2)
	createTargetAlphaAnim(overlay.animIn, overlay.innerGlowOver, 1, 0.3, 1, 0)
	createTargetScaleAnim(overlay.animIn, overlay.outerGlow, 1, 0.3, 0.5, 0.5)
	createTargetScaleAnim(overlay.animIn, overlay.outerGlowOver, 1, 0.3, 0.5, 0.5)
	createTargetAlphaAnim(overlay.animIn, overlay.outerGlowOver, 1, 0.3, 1, 0)
	createTargetScaleAnim(overlay.animIn, overlay.spark, 1, 0.2, 2 / 3, 2 / 3, 0.2)
	createTargetAlphaAnim(overlay.animIn, overlay.spark, 1, 0.2, 1, 0, 0.2)
	createTargetAlphaAnim(overlay.animIn, overlay.innerGlow, 1, 0.2, 1, 0, 0.3)
	createTargetAlphaAnim(overlay.animIn, overlay.ants, 1, 0.2, 0, 1, 0.3)
	overlay.animIn:SetScript("OnPlay", blizzardAnimInOnPlay)
	overlay.animIn:SetScript("OnFinished", blizzardAnimInOnFinished)

	overlay.animOut = overlay:CreateAnimationGroup()
	createTargetAlphaAnim(overlay.animOut, overlay.outerGlowOver, 1, 0.2, 0, 1)
	createTargetAlphaAnim(overlay.animOut, overlay.ants, 1, 0.2, 1, 0)
	createTargetAlphaAnim(overlay.animOut, overlay.outerGlowOver, 2, 0.2, 1, 0)
	createTargetAlphaAnim(overlay.animOut, overlay.outerGlow, 2, 0.2, 1, 0)
	overlay.animOut:SetScript("OnFinished", blizzardAnimOutFinished)

	overlay:SetScript("OnShow", function(self)
		if self.animIn and self.animIn:IsPlaying() then return end
		if self.animOut and self.animOut:IsPlaying() then return end
		applyBlizzardOverlayRestState(self)
	end)
	overlay:SetScript("OnHide", blizzardOverlayOnHide)
	overlay:SetScript("OnUpdate", blizzardOverlayOnUpdate)

	host._eqolBlizzardOverlay = overlay
	return overlay
end

local function updateBlizzardOverlay(host, opts)
	local overlay = ensureBlizzardOverlay(host)
	local width, height = getSafeFrameSize(host)
	local inset = normalizeInset(opts)
	local xOffset = normalizeScalar(opts, "xOffset", 0)
	local yOffset = normalizeScalar(opts, "yOffset", 0)
	local frameLevel = roundOffset(normalizeScalar(opts, "frameLevel", 3))
	local extraX = max(0, (width * 0.2) + inset)
	local extraY = max(0, (height * 0.2) + inset)
	local overlayWidth = max(1, width + (extraX * 2))
	local overlayHeight = max(1, height + (extraY * 2))
	local color = normalizeColor(type(opts) == "table" and opts.color or nil, { 1, 0.82, 0.2, 1 })
	local r, g, b, a = color[1], color[2], color[3], color[4]

	overlay:SetParent(host)
	overlay:SetFrameStrata(host:GetFrameStrata())
	overlay:SetFrameLevel(max(0, (host:GetFrameLevel() or 0) + frameLevel))
	overlay:ClearAllPoints()
	overlay:SetSize(overlayWidth, overlayHeight)
	overlay:SetPoint("CENTER", host, "CENTER", xOffset, yOffset)
	overlay.throttle = normalizeGlowThrottle(opts)

	resetSpellAlertTextures(overlay)
	overlay.spark:SetVertexColor(r, g, b, a)
	overlay.innerGlow:SetVertexColor(r, g, b, a)
	overlay.innerGlowOver:SetVertexColor(r, g, b, a)
	overlay.outerGlow:SetVertexColor(r, g, b, a)
	overlay.outerGlowOver:SetVertexColor(r, g, b, a)
	overlay.ants:SetVertexColor(r, g, b, a)
	if overlay:IsShown() and not (overlay.animIn and overlay.animIn:IsPlaying()) and not (overlay.animOut and overlay.animOut:IsPlaying()) then applyBlizzardOverlayRestState(overlay) end
	return overlay
end

local function startBlizzard(host, opts)
	local overlay = updateBlizzardOverlay(host, opts)
	if not overlay then return end
	if overlay.animOut and overlay.animOut:IsPlaying() then
		overlay.animOut:Stop()
		overlay.animIn:Play()
		return
	end
	if not overlay:IsShown() then
		overlay.animIn:Play()
		return
	end
	if overlay.animIn and overlay.animIn:IsPlaying() then return end
	applyBlizzardOverlayRestState(overlay)
end

local function stopBlizzard(host)
	local overlay = host and host._eqolBlizzardOverlay
	if not overlay then return end
	if overlay.animIn and overlay.animIn:IsPlaying() then overlay.animIn:Stop() end
	if not overlay:IsShown() then
		resetBlizzardOverlayVisuals(overlay)
		return
	end
	if host:IsVisible() and overlay.animOut then
		overlay.animOut:Play()
	else
		resetBlizzardOverlayVisuals(overlay)
		overlay:Hide()
	end
end

local function stopBackendImmediately(host)
	if not host then return end
	stopMarchingAnts(host)
	stopFlash(host)
	stopPixel(host)
	stopPulsing(host)
	stopSolid(host)
	stopTintBorder(host)
	local overlay = host._eqolBlizzardOverlay
	if overlay then
		if overlay.animIn and overlay.animIn:IsPlaying() then overlay.animIn:Stop() end
		if overlay.animOut and overlay.animOut:IsPlaying() then overlay.animOut:Stop() end
		resetBlizzardOverlayVisuals(overlay)
		overlay:Hide()
	end
	if LCG then
		if LCG.ButtonGlow_Stop then LCG.ButtonGlow_Stop(host) end
		if LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(host, "") end
		if LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(host, "") end
	end
end

local BACKENDS = {
	[Glow.STYLE.BLIZZARD] = {
		start = function(host, opts) startBlizzard(host, opts) end,
		refresh = function(host, opts) updateBlizzardOverlay(host, opts) end,
		stop = function(host) stopBlizzard(host) end,
	},
	[Glow.STYLE.MARCHING_ANTS] = {
		start = function(host, opts) startMarchingAnts(host, opts) end,
		refresh = function(host, opts) updateMarchingAntsOverlay(host, opts) end,
		stop = function(host) stopMarchingAnts(host) end,
	},
	[Glow.STYLE.FLASH] = {
		start = function(host, opts) startFlash(host, opts) end,
		refresh = function(host, opts) updateFlashOverlay(host, opts) end,
		stop = function(host) stopFlash(host) end,
	},
	[Glow.STYLE.BUTTON] = {
		start = function(host, opts)
			if LCG and LCG.ButtonGlow_Start then
				LCG.ButtonGlow_Start(host, type(opts) == "table" and opts.color or nil, type(opts) == "table" and opts.frequency or nil, type(opts) == "table" and opts.frameLevel or nil)
				resetSpellAlertTextures(host and host._ButtonGlow)
			else
				startBlizzard(host, opts)
			end
		end,
		refresh = function(host, opts)
			if LCG and host and host._ButtonGlow then
				resetSpellAlertTextures(host._ButtonGlow)
			else
				updateBlizzardOverlay(host, opts)
			end
		end,
		stop = function(host)
			if LCG and LCG.ButtonGlow_Stop then
				LCG.ButtonGlow_Stop(host)
			else
				stopBlizzard(host)
			end
		end,
	},
	[Glow.STYLE.PIXEL] = {
		start = function(host, opts)
			startPixel(host, opts)
		end,
		refresh = function(host, opts)
			updatePixelOverlay(host, opts)
		end,
		stop = function(host)
			stopPixel(host)
		end,
	},
	[Glow.STYLE.PULSING] = {
		start = function(host, opts)
			startPulsing(host, opts)
		end,
		refresh = function(host, opts)
			updatePulsingOverlay(host, opts)
		end,
		stop = function(host)
			stopPulsing(host)
		end,
	},
	[Glow.STYLE.SOLID] = {
		start = function(host, opts) startSolid(host, opts) end,
		refresh = function(host, opts) updateSolidOverlay(host, opts) end,
		stop = function(host) stopSolid(host) end,
	},
	[Glow.STYLE.TINT_BORDER] = {
		start = function(host, opts) updateTintBorder(host, opts) end,
		refresh = function(host, opts) updateTintBorder(host, opts) end,
		stop = function(host) stopTintBorder(host) end,
	},
	[Glow.STYLE.SHINE] = {
		start = function(host, opts)
			if LCG and LCG.AutoCastGlow_Start then
				LCG.AutoCastGlow_Start(
					host,
					type(opts) == "table" and opts.color or nil,
					type(opts) == "table" and (opts.count or opts.N) or nil,
					type(opts) == "table" and opts.frequency or nil,
					type(opts) == "table" and opts.scale or nil,
					type(opts) == "table" and opts.xOffset or nil,
					type(opts) == "table" and opts.yOffset or nil,
					"",
					type(opts) == "table" and opts.frameLevel or nil
				)
			else
				startBlizzard(host, opts)
			end
		end,
		stop = function(host)
			if LCG and LCG.AutoCastGlow_Stop then
				LCG.AutoCastGlow_Stop(host, "")
			else
				stopBlizzard(host)
			end
		end,
	},
	[Glow.STYLE.PROC] = {
		start = function(host, opts)
			if LCG and LCG.ProcGlow_Start then
				if host and host._ProcGlow and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(host, "") end
				local procOptions = {}
				if type(opts) == "table" then
					for optionKey, optionValue in pairs(opts) do
						procOptions[optionKey] = optionValue
					end
				end
				procOptions.frameLevel = normalizeScalar(opts, "frameLevel", 3)
				procOptions.key = ""
				LCG.ProcGlow_Start(host, procOptions)
				resetProcGlowTextures(host and host._ProcGlow)
			else
				startBlizzard(host, opts)
			end
		end,
		refresh = function(host, opts)
			if LCG and host and host._ProcGlow then
				resetProcGlowTextures(host._ProcGlow)
			else
				updateBlizzardOverlay(host, opts)
			end
		end,
		stop = function(host)
			if LCG and LCG.ProcGlow_Stop then
				LCG.ProcGlow_Stop(host, "")
			else
				stopBlizzard(host)
			end
		end,
	},
}

local function stopBackend(state)
	if not (state and state.active and state.style) then return end
	local backend = BACKENDS[state.style] or BACKENDS[Glow.STYLE.BLIZZARD]
	if backend and backend.stop and state.host then backend.stop(state.host) end
end

function Glow.GetHost(target, key)
	local state = getState(target, normalizeKey(key), false)
	return state and state.host or nil
end

function Glow.CreateRestrictedAura(target, anchorFrame, opts)
	local auraCompat = addon.AuraCompat
	if not (auraCompat and auraCompat.CreateRestrictedAuraGlow) then return nil end
	return auraCompat:CreateRestrictedAuraGlow(target, anchorFrame, opts)
end

function Glow.IsActive(target, key)
	local state = getState(target, normalizeKey(key), false)
	return state and state.active == true or false
end

function Glow.Start(target, key, style, opts)
	if not target then return nil end
	key = normalizeKey(key)
	style = normalizeStyle(style)
	local state = getState(target, key, true)
	if state.style and state.style ~= style then stopBackend(state) end
	state.style = style
	state.active = true
	state.opts = copyOptions(opts)
	configureHost(target, state, opts)
	local backend = BACKENDS[style] or BACKENDS[Glow.STYLE.BLIZZARD]
	if backend and backend.start and state.host then backend.start(state.host, opts) end
	applyStateAlpha(state)
	return state.host
end

function Glow.Refresh(target, key, style, opts) return Glow.Start(target, key, style, opts) end

function Glow.Stop(target, key, immediate)
	local state = getState(target, normalizeKey(key), false)
	if not state then return end
	if immediate then
		stopBackendImmediately(state.host)
	else
		stopBackend(state)
	end
	state.active = false
	state.style = nil
	state.alphaMode = nil
	state.alphaCondition = nil
	if state.host then
		state.host:SetAlpha(1)
		state.host:Hide()
	end
	state.opts = nil
end

function Glow.StopAll(target)
	if not (target and target._eqolGlowStates) then return end
	for key in pairs(target._eqolGlowStates) do
		Glow.Stop(target, key)
	end
end

function Glow.SetAlpha(target, key, alpha)
	local state = getState(target, normalizeKey(key), true)
	if not state then return end
	state.alphaMode = "value"
	state.alphaValue = tonumber(alpha) or 1
	applyStateAlpha(state)
end

function Glow.SetAlphaFromBoolean(target, key, condition, onAlpha, offAlpha)
	local state = getState(target, normalizeKey(key), true)
	if not state then return end
	state.alphaMode = "boolean"
	state.alphaCondition = condition
	state.alphaOn = onAlpha
	state.alphaOff = offAlpha
	applyStateAlpha(state)
end
