local _, ns = ...
local Affected = ns.API.Affected

local CooldownStyle = ns.CooldownStyle or {}
ns.CooldownStyle = CooldownStyle
local MENU_TITLE = "|cff008945C|r|cff1e9a4eo|r|cff3faa4fol|r|cff5fb64ado|r|cff7ac243wn|r |cff8ccd00Manager Centered|r"
local GCD_SPELL_ID = 61304

local DEFAULT_ALWAYS_SHOW_COOLDOWN_EDGE = false
local DEFAULT_SHOW_AURAS = true
local DEFAULT_DISABLE_PROCS_GLOW = false
local DEFAULT_REVERSE_AURA_SWIPE = false
local DEFAULT_GLOW_WHEN_READY = false
local DEFAULT_GLOW_ON_FULL_CHARGES = false
local DEFAULT_ALWAYS_GLOW = false
local DEFAULT_NEVER_DESATURATE = false
local DEFAULT_BAR_COLOR = { 1, 0.5, 0.25 }

local LCG = LibStub("WilduCustomGlow-1.0")
local GLOW_STYLE_DEFAULT = "DEFAULT"
local GLOW_STYLE_PROC = "PROC"
local GLOW_STYLE_AUTOCAST = "AUTOCAST"
local GLOW_STYLE_PIXEL = "PIXEL"
local GLOW_STYLE_ANTS = "ANTS"

local isZeroCurve = C_CurveUtil.CreateCurve()
isZeroCurve:AddPoint(0, 1)
isZeroCurve:AddPoint(0.001, 0)

local function GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
    if not cooldownInfo then
        return nil
    end
    if cooldownInfo.overrideTooltipSpellID then
        return cooldownInfo.overrideTooltipSpellID
    end
    if cooldownInfo.overrideSpellID then
        return cooldownInfo.overrideSpellID
    end

    if cooldownInfo.spellID then
        return cooldownInfo.spellID
    end
    return nil
end

local function GetBaseSpellIDFromCooldownInfo(cooldownInfo)
    if not cooldownInfo then
        return nil
    end
    if cooldownInfo.spellID then
        return cooldownInfo.spellID
    end
    return nil
end

-- 12.1.0 dynamic icons: equip-slot items (cooldownInfo.equipSlot) and
-- spell-category cooldowns like potions/healthstones (cooldownInfo.spellCategoryID).
-- Their spellID changes with whatever item/spell is currently underneath them.
local function IsDynamicCooldownInfo(cooldownInfo)
    return cooldownInfo ~= nil and (cooldownInfo.spellCategoryID ~= nil or cooldownInfo.equipSlot ~= nil)
end

-- Stable key for per-icon style settings (glow when ready, never desaturate, ...).
-- Normal cooldowns key by spellID (backwards compatible with saved settings).
-- Dynamic icons have no fixed spellID, so they key off the icon slot's stable
-- cooldownID; the "cd:" prefix namespaces it so it can never collide with a
-- numeric spellID key. useOverride mirrors the base-vs-override spellID choice
-- for normal spells and is irrelevant for dynamic icons (one slot identity).
local function GetStyleKeyFromCooldownInfo(cooldownInfo, useOverride)
    if cooldownInfo == nil then
        return nil
    end
    if IsDynamicCooldownInfo(cooldownInfo) then
        local cooldownID = cooldownInfo.cooldownID
        return cooldownID and ("cd:" .. cooldownID) or nil
    end
    if useOverride then
        return GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
    end
    return GetBaseSpellIDFromCooldownInfo(cooldownInfo)
end

-- 12.1.0 added spec-agnostic (5/6) and equip-slot (7/8) category variants that
-- style like the base Essential/Utility (cooldown) and TrackedBuff (aura)
-- categories. Negative keys are CMC's legacy hidden-variant pseudo-categories.
local COOLDOWN_LIKE_CATEGORY = { [-1] = true, [0] = true, [1] = true, [5] = true, [7] = true }
local TRACKED_LIKE_CATEGORY = { [-2] = true, [2] = true, [6] = true, [8] = true }

local function ResolveGlowStyle(defaultStyle)
    local style = ns.db.profile.cooldownManager_experimental_glow_style or GLOW_STYLE_DEFAULT

    if
        style ~= GLOW_STYLE_DEFAULT
        and style ~= GLOW_STYLE_PROC
        and style ~= GLOW_STYLE_AUTOCAST
        and style ~= GLOW_STYLE_PIXEL
        and style ~= GLOW_STYLE_ANTS
    then
        style = GLOW_STYLE_DEFAULT
    end
    if style == GLOW_STYLE_DEFAULT then
        return defaultStyle
    end
    return style
end

local function GetConfiguredGlowColor()
    if not ns.db.profile.cooldownManager_experimental_glow_custom_color then
        return nil
    end
    return {
        ns.db.profile.cooldownManager_experimental_glow_color_r or 0.95,
        ns.db.profile.cooldownManager_experimental_glow_color_g or 0.95,
        ns.db.profile.cooldownManager_experimental_glow_color_b or 0.32,
        ns.db.profile.cooldownManager_experimental_glow_color_a or 1,
    }
end

local function GetConfiguredGlowFrequency()
    local speed = tonumber(ns.db.profile.cooldownManager_experimental_glow_animation_speed) or 0
    if speed > 1 then
        speed = 1
    elseif speed < -1 then
        speed = -1
    end
    return speed
end

local function GetConfiguredGlowDensity()
    local density = tonumber(ns.db.profile.cooldownManager_experimental_glow_animation_density) or 0
    if density > 16 then
        density = 16
    elseif density < 0.5 then
        density = 0
    end
    return density
end

local function GetAntsGlowLayers()
    local layers = math.floor(GetConfiguredGlowDensity())
    if layers < 1 then
        layers = 1
    elseif layers > 4 then
        layers = 4
    end
    return layers
end

local function GetAutoCastGlowScale()
    local scale = tonumber(ns.db.profile.cooldownManager_experimental_glow_autocast_scale) or 1
    scale = math.floor((scale * 10) + 0.5) / 10
    if scale > 5 then
        scale = 5
    elseif scale < 0.5 then
        scale = 0.5
    end
    return scale
end

local function GetPixelGlowSize()
    local size = tonumber(ns.db.profile.cooldownManager_experimental_glow_pixel_size) or 1
    size = math.floor(size + 0.5)
    if size > 6 then
        size = 6
    elseif size < 1 then
        size = 1
    end
    return size
end

local SHAPED_GLOW_BLOOM = 0.2
local SHAPED_GLOW_TEXCOORD = { 0.00781250, 0.50781250, 0.27734375, 0.52734375 }
local SHAPED_GLOW_SCALE_DURATION = 0.5

local function GetOrCreateShapedGlow(host)
    local glow = Affected(host).shapedGlow
    if glow then
        return glow
    end
    glow = CreateFrame("Frame", nil, host)
    glow:SetFrameLevel(host:GetFrameLevel() + 1)
    glow:SetAllPoints(host)

    local tex = glow:CreateTexture(nil, "OVERLAY")
    tex:SetBlendMode("ADD")
    glow.Texture = tex

    local anim = glow:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local scale = anim:CreateAnimation("Scale")
    scale:SetOrigin("CENTER", 0, 0)
    scale:SetScaleTo(1.06, 1.06)
    scale:SetDuration(SHAPED_GLOW_SCALE_DURATION)
    glow.Anim = anim
    glow.ScaleAnim = scale

    glow:Hide()
    Affected(host).shapedGlow = glow
    return glow
end

local function StartShapedGlow(host, glowTexture, color, speedFactor)
    local glow = GetOrCreateShapedGlow(host)
    glow.ScaleAnim:SetDuration(SHAPED_GLOW_SCALE_DURATION * (speedFactor or 1))

    local w, h = host._width, host._height
    if not w then
        w, h = ns.API:GetSafeSize(host)
    end
    local bx, by = (w and w * SHAPED_GLOW_BLOOM) or 0, (h and h * SHAPED_GLOW_BLOOM) or 0
    local tex = glow.Texture
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", glow, "TOPLEFT", -bx, by)
    tex:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", bx, -by)
    tex:SetTexture(glowTexture)
    tex:SetTexCoord(SHAPED_GLOW_TEXCOORD[1], SHAPED_GLOW_TEXCOORD[2], SHAPED_GLOW_TEXCOORD[3], SHAPED_GLOW_TEXCOORD[4])
    if color then
        tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    else
        tex:SetVertexColor(1, 1, 1, 1)
    end
    glow:SetAlpha(1)
    glow:Show()
    if not glow.Anim:IsPlaying() then
        glow.Anim:Play()
    end
    return glow
end

local function StopShapedGlow(host)
    local glow = Affected(host).shapedGlow
    if not glow then
        return
    end
    if glow.Anim:IsPlaying() then
        glow.Anim:Stop()
    end
    glow:Hide()
end

local function StopAllCustomGlows(frame)
    LCG.ProcGlow_Stop(frame)
    LCG.AutoCastGlow_Stop(frame)
    LCG.PixelGlow_Stop(frame)
    LCG.AntsGlow_Stop(frame)
    StopShapedGlow(frame)
end

local function GetGlowSpeedFactor()
    return 2 ^ -GetConfiguredGlowFrequency()
end

local function CollectGlowParams(cdmFrame, defaultStyle)
    local masque = ns.MasqueModule
    return {
        style = ResolveGlowStyle(defaultStyle),
        color = GetConfiguredGlowColor(),
        frequency = GetConfiguredGlowFrequency(),
        speedFactor = GetGlowSpeedFactor(),
        density = GetConfiguredGlowDensity(),
        antsLayers = GetAntsGlowLayers(),
        autoCastScale = GetAutoCastGlowScale(),
        pixelSize = GetPixelGlowSize(),
        shape = (cdmFrame and masque and masque:GetShape(cdmFrame)),
        vertices = masque and masque:GetShapeVertices(cdmFrame),
        acStyle = masque and masque:GetAssistedCombatStyle(cdmFrame),
        shapedTexture = masque and masque:GetSpellAlertTextures(cdmFrame),
    }
end

local function StartConfiguredGlow(frame, params)
    local style = params.style
    local color = params.color

    if style == GLOW_STYLE_AUTOCAST then
        LCG.AutoCastGlow_Start(
            frame,
            color,
            params.density,
            params.frequency,
            params.autoCastScale,
            nil,
            nil,
            nil,
            nil,
            params.vertices
        )
    elseif style == GLOW_STYLE_PIXEL then
        LCG.PixelGlow_Start(
            frame,
            color,
            params.density,
            params.frequency,
            nil,
            params.pixelSize,
            nil,
            nil,
            nil,
            nil,
            nil,
            params.vertices
        )
    elseif style == GLOW_STYLE_ANTS then
        local opts = {
            color = color,
            duration = LCG.AntsGlowDefaults.duration * params.speedFactor,
            count = params.antsLayers,
        }
        local acStyle = params.acStyle
        if acStyle and acStyle.Texture then
            opts.texture = acStyle.Texture
            opts.texCoords = acStyle.TexCoords
            opts.frameWidth = acStyle.FrameWidth
            opts.frameHeight = acStyle.FrameHeight
        end
        LCG.AntsGlow_Start(frame, opts)
    else
        if params.shapedTexture then
            StartShapedGlow(frame, params.shapedTexture, color, params.speedFactor)
        else
            LCG.ProcGlow_Start(frame, { startAnim = false, color = color, duration = params.speedFactor })
        end
    end
    return style
end

local function BuildGlowSignature(params)
    local style = params.style
    local color = params.color
    local base
    if style == GLOW_STYLE_ANTS then
        if color then
            base = string.format(
                "%s:%.3f:%.3f:%.3f:%.3f:%.3f:%d",
                style,
                color[1] or 0,
                color[2] or 0,
                color[3] or 0,
                color[4] or 1,
                params.frequency,
                params.antsLayers
            )
        else
            base = string.format("%s:%.3f:%d", style, params.frequency, params.antsLayers)
        end
    elseif style == GLOW_STYLE_AUTOCAST or style == GLOW_STYLE_PIXEL then
        if color then
            base = string.format(
                "%s:%.3f:%.3f:%.3f:%.3f:%.3f:%d:%.1f:%d",
                style,
                color[1] or 0,
                color[2] or 0,
                color[3] or 0,
                color[4] or 1,
                params.frequency,
                params.density,
                params.autoCastScale,
                params.pixelSize
            )
        else
            base = string.format(
                "%s:%.3f:%d:%.1f:%d",
                style,
                params.frequency,
                params.density,
                params.autoCastScale,
                params.pixelSize
            )
        end
    else
        base = string.format("%s:%.3f", style, params.frequency)
    end
    return base .. "|" .. (params.shape or "")
end

local HealGlowOnResize

local function GetGlowHostSize(cdmFrame)
    -- Trackers stamp their icon size; viewers resolve through Sizes.
    local stamped = Affected(cdmFrame).glowIconSizeW
    if stamped then
        return stamped, Affected(cdmFrame).glowIconSizeH or stamped
    end
    local width, height = ns.Sizes.GetIconSize(cdmFrame)
    if not width then
        width, height = cdmFrame:GetSize()
    end
    return width, height
end

local function GetGlowHost(cdmFrame)
    local host = Affected(cdmFrame).glowHost
    if not host then
        host = CreateFrame("Frame", nil, cdmFrame)
        host:SetAllPoints(cdmFrame.Icon)
        Affected(cdmFrame).glowHost = host

        host:HookScript("OnSizeChanged", function(self)
            C_Timer.After(0.1, function()
                self._width, self._height = GetGlowHostSize(cdmFrame)
                HealGlowOnResize(self)
            end)
        end)
    end
    host._width, host._height = GetGlowHostSize(cdmFrame)
    return host
end

local function GetButtonGlowFrame(host)
    if Affected(host).shapedGlow and Affected(host).shapedGlow:IsShown() then
        return Affected(host).shapedGlow
    end

    if host._ProcGlow then
        return host._ProcGlow
    end
    if host._AutoCastGlow then
        return host._AutoCastGlow
    end
    if host._PixelGlow then
        return host._PixelGlow
    end
    if host._AntsGlow then
        return host._AntsGlow
    end

    return nil
end

local function EnsureButtonGlow(cdmFrame)
    local host = GetGlowHost(cdmFrame)
    local params = CollectGlowParams(cdmFrame, GLOW_STYLE_PROC)
    local signature = BuildGlowSignature(params)

    local glow = GetButtonGlowFrame(host)
    if not (Affected(host).glowSignature == signature and glow) then
        StopAllCustomGlows(host)
        StartConfiguredGlow(host, params)
        Affected(host).glowSignature = signature
        Affected(host).glowParams = params
        glow = GetButtonGlowFrame(host)
    end

    return glow
end

HealGlowOnResize = function(host)
    if not Affected(host).glowParams then
        return
    end
    local glow = GetButtonGlowFrame(host)
    local alpha = (glow and glow:GetAlpha()) or 0
    StopAllCustomGlows(host)
    StartConfiguredGlow(host, Affected(host).glowParams)
    glow = GetButtonGlowFrame(host)
    if glow then
        glow:SetAlpha(alpha)
    end
end

local function SetButtonGlowVisible(cdmFrame, alpha)
    if alpha == nil then
        alpha = 1
    end
    local glow = EnsureButtonGlow(cdmFrame)
    if glow then
        glow:SetAlpha(alpha)
    end
    return glow
end

local function ClearButtonGlow(cdmFrame)
    local host = Affected(cdmFrame).glowHost
    if not host then
        return
    end
    if not Affected(host).glowSignature and not GetButtonGlowFrame(host) then
        return
    end
    Affected(host).glowSignature = nil
    StopAllCustomGlows(host)
end

-- Public glow controls for frames outside the cooldown viewers (trackers).
function CooldownStyle:ShowFrameGlow(frame, alpha)
    return SetButtonGlowVisible(frame, alpha)
end

function CooldownStyle:HideFrameGlow(frame)
    ClearButtonGlow(frame)
end

local function ComputeConfiguredGlowAlpha(cdmFrame, cooldownInfo)
    if cooldownInfo == nil then
        return false
    end

    if COOLDOWN_LIKE_CATEGORY[cooldownInfo.category] then
        local hideForAura = ns.db.profile.cooldownManager_hide_glow_on_active_aura and cdmFrame.wasSetFromAura
        local spellID = GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
        local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, false)

        -- Item/spell-category icons (12.1.0: potions, healthstones, equip-slot
        -- trinkets) carry no live spellID until triggered, so their cooldown/
        -- charge readiness can't be queried; nothing to glow off yet.
        if not spellID then
            return false
        end

        local spellCharges = C_Spell.GetSpellCharges(spellID)
        local hasCharges = spellCharges and spellCharges.maxCharges > 1
        if hideForAura then
            return true, 0
        end
        local glowOnFullCharges = CooldownStyle.GetGlowOnFullCharges(styleKey)
        if hasCharges and glowOnFullCharges then
            return true, C_Spell.GetSpellChargeDuration(spellID):EvaluateRemainingDuration(isZeroCurve)
        end

        if CooldownStyle.GetGlowWhenReady(styleKey) or glowOnFullCharges then
            local _, notEnoughPower = C_Spell.IsSpellUsable(spellID)
            if notEnoughPower then
                return true, 0
            end
            local cooldown = C_Spell.GetSpellCooldown(spellID)
            if cooldown.isOnGCD then
                return true, 1
            end
            return true, C_Spell.GetSpellCooldownDuration(spellID):EvaluateRemainingDuration(isZeroCurve)
        end
    end

    if TRACKED_LIKE_CATEGORY[cooldownInfo.category] then
        local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, true)
        if CooldownStyle.GetAlwaysGlow(styleKey) then
            return true, 1
        end
    end

    return false
end

local function UpdateButtonGlowState(cdmFrame)
    local cooldownInfo = cdmFrame:GetCooldownInfo()
    local wantsGlow, configuredAlpha = ComputeConfiguredGlowAlpha(cdmFrame, cooldownInfo)

    local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, false)
    local procForcing = Affected(cdmFrame).procActive and styleKey and not CooldownStyle.GetDisableProcsGlow(styleKey)

    if procForcing then
        SetButtonGlowVisible(cdmFrame)
    elseif wantsGlow then
        SetButtonGlowVisible(cdmFrame, configuredAlpha)
    else
        ClearButtonGlow(cdmFrame)
    end
end

-- Reused scratch table for the style context. Both callers (ApplyCooldownSettings,
-- ApplyIconSettings) consume the context synchronously and never retain it past
-- the next BuildStyleContext call, so a single shared table avoids allocating one
-- per frame on every styling pass (a major source of GC churn during refreshes).
local styleContext = {}

local function BuildStyleContext(cdmFrame)
    local cooldownInfo = cdmFrame:GetCooldownInfo()
    if cooldownInfo == nil then
        return nil
    end

    local spellID = GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
    local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, false)
    -- Dynamic icons (12.1.0 items/potions) have a stable styleKey but no live
    -- spellID until triggered. Keep styling them (never desaturate, cooldown
    -- edge) off the styleKey; their spell-state queries below simply no-op.
    if not styleKey then
        return nil
    end

    local cooldown = spellID and C_Spell.GetSpellCooldown(spellID)
    local spellCharges = spellID and C_Spell.GetSpellCharges(spellID)
    local fromAura = cdmFrame.wasSetFromAura
    local showAuras = CooldownStyle.GetShowAuras(styleKey)

    local ctx = styleContext
    ctx.spellID = spellID
    ctx.styleKey = styleKey
    ctx.cooldown = cooldown
    ctx.hasCharges = spellCharges and spellCharges.maxCharges > 1
    ctx.isActualCooldown = cooldown and cooldown.isActive and not cooldown.isOnGCD and true or false
    -- Display modes (mutually exclusive):
    ctx.auraShown = (fromAura and showAuras) and true or false
    ctx.auraHidden = (fromAura and not showAuras) and true or false
    return ctx
end

local function ApplyCooldownDisplay(cdmFrame, ctx)
    local cd = cdmFrame.Cooldown

    if CooldownStyle.GetAlwaysShowCooldownEdge(ctx.styleKey) then
        cd:SetDrawEdge(true)
    end

    if ctx.auraShown then
        if ns.db.profile.cooldownManager_customSwipeColor_enabled then
            cd:SetSwipeColor(
                ns.db.profile.cooldownManager_customActiveColor_r or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.r,
                ns.db.profile.cooldownManager_customActiveColor_g or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.g,
                ns.db.profile.cooldownManager_customActiveColor_b or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.b,
                ns.db.profile.cooldownManager_customActiveColor_a or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.a
            )
            -- Setting active swipe color to default may be unnecessary since the cooldown viewer's swipe color should already be at the default
            -- else
            --     cd:SetSwipeColor(
            --         ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.r,
            --         ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.g,
            --         ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.b,
            --         ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.a
            --     )
        end
        cd:SetDrawSwipe(true)
        if CooldownStyle.GetReverseAuraSwipe(ctx.styleKey) then
            cd:SetReverse(true)
        else
            cd:SetReverse(false)
        end
        return
    else
        cd:SetReverse(false)
    end

    if ns.db.profile.cooldownManager_customSwipeColor_enabled then
        cd:SetSwipeColor(
            ns.db.profile.cooldownManager_customCDSwipeColor_r or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.r,
            ns.db.profile.cooldownManager_customCDSwipeColor_g or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.g,
            ns.db.profile.cooldownManager_customCDSwipeColor_b or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.b,
            ns.db.profile.cooldownManager_customCDSwipeColor_a or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.a
        )
    else
        -- Don't remove it.. if the option is disabled we should still set it to the default in case it was changed by the active swipe color and therefore should be overridden
        cd:SetSwipeColor(
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.r,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.g,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.b,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.a
        )
    end

    local hideGCD = ns.db.profile.cooldownManager_hide_gcd

    if ctx.auraHidden and ctx.spellID then
        if ctx.hasCharges then
            cd:SetCooldownFromDurationObject(C_Spell.GetSpellChargeDuration(ctx.spellID))
        elseif ctx.cooldown and ctx.cooldown.isOnGCD then
            if hideGCD then
                cd:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration())
            else
                cd:SetCooldownFromDurationObject(C_Spell.GetSpellCooldownDuration(GCD_SPELL_ID))
            end
        else
            local cooldownDuration = C_Spell.GetSpellCooldownDuration(ctx.spellID)
            cd:SetCooldownFromDurationObject(cooldownDuration)
        end
    elseif ctx.cooldown and ctx.cooldown.isOnGCD and hideGCD then
        if ctx.hasCharges then
            cd:SetCooldownFromDurationObject(C_Spell.GetSpellChargeDuration(ctx.spellID))
        else
            cd:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration())
        end
    end

    if ctx.auraHidden then
        if ctx.hasCharges then
            cd:SetDrawSwipe(ctx.isActualCooldown)
            cd:SetDrawEdge(not ctx.isActualCooldown or CooldownStyle.GetAlwaysShowCooldownEdge(ctx.styleKey))
        else
            cd:SetDrawSwipe(true)
        end
    end
end

local function ApplyIconDisplay(cdmFrame, ctx)
    local icon = cdmFrame.Icon

    -- Aura is shown.
    if ctx.auraShown then
        if ns.db.profile.cooldownManager_desaturate_under_aura then
            -- Single-charge spells always desaturate under their aura; charge
            -- spells only while actually on cooldown.
            if not ctx.hasCharges or ctx.isActualCooldown then
                icon:SetDesaturation(1)
            end
        end
        return
    end

    if CooldownStyle.GetNeverDesaturate(ctx.styleKey) then
        icon:SetDesaturation(0)
    elseif ctx.auraHidden and ctx.isActualCooldown then
        icon:SetDesaturation(1)
    end
end

local function ApplyCooldownSettings(cdmFrame)
    local ctx = BuildStyleContext(cdmFrame)
    if not ctx then
        return
    end
    ApplyCooldownDisplay(cdmFrame, ctx)
    ApplyIconDisplay(cdmFrame, ctx)
end

-- Icon-only pass for when Blizzard re-desaturates the icon.
local function ApplyIconSettings(cdmFrame)
    local ctx = BuildStyleContext(cdmFrame)
    if not ctx then
        return
    end
    ApplyIconDisplay(cdmFrame, ctx)
end

local function ApplyCooldownFlashHidden(cdmFrame)
    local flash = cdmFrame.CooldownFlash
    if not flash then
        return
    end
    if ns.db.profile.cooldownManager_hideCooldownFlash then
        flash:Hide()
        flash:SetAlpha(0)
        if cdmFrame.Cooldown then
            cdmFrame.Cooldown:SetDrawBling(false)
        end
    else
        -- Undo our suppression; Blizzard controls Show/Hide from here.
        flash:SetAlpha(1)
    end
    if not ns.API:GetIsAffected(cdmFrame, "cooldownFlashHooked") then
        ns.API:SetAffected(cdmFrame, "cooldownFlashHooked")
        hooksecurefunc(flash, "Show", function(self)
            if ns.db.profile.cooldownManager_hideCooldownFlash then
                self:Hide()
                self:SetAlpha(0)
                if self.FlashAnim then
                    self.FlashAnim:Stop()
                end
            end
        end)
        if flash.FlashAnim and flash.FlashAnim.Play then
            hooksecurefunc(flash.FlashAnim, "Play", function(self)
                if ns.db.profile.cooldownManager_hideCooldownFlash then
                    self:Stop()
                    flash:Hide()
                    flash:SetAlpha(0)
                end
            end)
        end
    end
end

local function HookCooldownFrame(cdmFrame)
    if cdmFrame.Cooldown == nil or cdmFrame.Icon == nil then
        return
    end

    UpdateButtonGlowState(cdmFrame)
    ApplyCooldownSettings(cdmFrame)
    ApplyCooldownFlashHidden(cdmFrame)

    if ns.API:GetIsAffected(cdmFrame, "cooldownStyleHooked") then
        return
    end

    ns.API:SetAffected(cdmFrame, "cooldownStyleHooked")

    hooksecurefunc(cdmFrame.Cooldown, "SetCooldown", function(self)
        local cdmFrame = self:GetParent()
        UpdateButtonGlowState(cdmFrame)
        ApplyCooldownSettings(cdmFrame)
    end)

    hooksecurefunc(cdmFrame.Cooldown, "Clear", function(self)
        local cdmFrame = self:GetParent()
        UpdateButtonGlowState(cdmFrame)
    end)

    hooksecurefunc(cdmFrame.Icon, "SetSize", function(self)
        local cdmFrame = self:GetParent()
        UpdateButtonGlowState(cdmFrame)
    end)
    hooksecurefunc(cdmFrame.Icon, "SetDesaturated", function(self)
        local cdmFrame = self:GetParent()

        -- Only the aura case needs a glow recalc here; SetDesaturated fires far too
        -- often otherwise (and its arg is a secret value we can't branch on).
        if cdmFrame.wasSetFromAura then
            UpdateButtonGlowState(cdmFrame)
        end
        ApplyIconSettings(cdmFrame)
    end)
end

local function HookBuffIconFrame(cdmFrame)
    if cdmFrame.Cooldown == nil or cdmFrame.Icon == nil then
        return
    end
    if cdmFrame.GetCooldownInfo then
        local cooldownInfo = cdmFrame:GetCooldownInfo()
        if cooldownInfo then
            local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, true)
            if TRACKED_LIKE_CATEGORY[cooldownInfo.category] then
                if CooldownStyle.GetAlwaysGlow(styleKey) then
                    SetButtonGlowVisible(cdmFrame)
                else
                    ClearButtonGlow(cdmFrame)
                end
            end
        end
    end

    if ns.API:GetIsAffected(cdmFrame, "cooldownStyleHooked") then
        return
    end

    ns.API:SetAffected(cdmFrame, "cooldownStyleHooked")

    hooksecurefunc(cdmFrame.Cooldown, "SetCooldown", function(self)
        local cdmFrame = self:GetParent()
        local cooldownInfo = cdmFrame:GetCooldownInfo()
        if cooldownInfo == nil then
            return
        end

        local styleKey = GetStyleKeyFromCooldownInfo(cooldownInfo, true)
        cdmFrame.Cooldown:SetDrawEdge(CooldownStyle.GetAlwaysShowCooldownEdge(styleKey))
        if TRACKED_LIKE_CATEGORY[cooldownInfo.category] then
            if CooldownStyle.GetAlwaysGlow(styleKey) then
                SetButtonGlowVisible(cdmFrame)
            else
                ClearButtonGlow(cdmFrame)
            end
        end
    end)
end

local function ResolveBarColor(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    local value = settings and settings.barColor
    if type(value) == "table" then
        return value[1], value[2], value[3]
    end
    return nil
end

local function SetBarFillColor(bar, r, g, b)
    if bar.SetStatusBarColor then
        bar:SetStatusBarColor(r, g, b)
    elseif bar.FillTexture then
        bar.FillTexture:SetVertexColor(r, g, b)
    end
end

local function ApplyBarColorToBar(bar, spellID)
    local r, g, b = ResolveBarColor(spellID)
    if not r then
        r, g, b = DEFAULT_BAR_COLOR[1], DEFAULT_BAR_COLOR[2], DEFAULT_BAR_COLOR[3]
    end
    SetBarFillColor(bar, r, g, b)
end

local function ApplyBarColor(cdmFrame)
    local bar = cdmFrame.Bar or cdmFrame.bar
    if not bar or not cdmFrame.GetCooldownInfo then
        return
    end
    local cooldownInfo = cdmFrame:GetCooldownInfo()
    if not cooldownInfo then
        return
    end
    local spellID = GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
    if not spellID then
        return
    end
    ApplyBarColorToBar(bar, spellID)
end

local function HookBuffBarColor(cdmFrame)
    ApplyBarColor(cdmFrame)
    if ns.API:GetIsAffected(cdmFrame, "barColorHooked") then
        return
    end
    ns.API:SetAffected(cdmFrame, "barColorHooked")
    if cdmFrame.RefreshData then
        hooksecurefunc(cdmFrame, "RefreshData", function(self)
            ApplyBarColor(self)
        end)
    end
end

local function RefreshBuffBarColors()
    local buffBarViewer = _G["BuffBarCooldownViewer"]
    if not buffBarViewer then
        return
    end
    for _, cdmFrame in ipairs(buffBarViewer:GetItemFrames()) do
        if (cdmFrame.Bar or cdmFrame.bar) and cdmFrame.GetCooldownInfo then
            HookBuffBarColor(cdmFrame)
        end
    end
end

local settingsSwatchPool

-- Color a swatch should show: the active override, or the fixed default fill
-- while in "Default" mode.
local function GetBarSwatchColor(bar, spellID)
    local r, g, b = ResolveBarColor(spellID)
    if r then
        return r, g, b
    end
    return DEFAULT_BAR_COLOR[1], DEFAULT_BAR_COLOR[2], DEFAULT_BAR_COLOR[3]
end

local function OpenBarColorPicker(spellID, swatch, bar)
    local existing = CooldownStyle.GetSpellSettings(spellID)
    local originalBarColor = existing and existing.barColor

    local function refresh()
        if swatch then
            swatch:SetColorRGB(GetBarSwatchColor(bar, spellID))
        end
        if bar then
            ApplyBarColorToBar(bar, spellID)
        end
        RefreshBuffBarColors()
    end

    local r, g, b = GetBarSwatchColor(bar, spellID)
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r,
        g = g,
        b = b,
        hasOpacity = false,
        swatchFunc = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            CooldownStyle.SetBarColorCustom(spellID, nr, ng, nb)
            refresh()
        end,
        cancelFunc = function()
            if originalBarColor == nil then
                CooldownStyle.ClearBarColor(spellID)
            else
                CooldownStyle.SetBarColorCustom(spellID, originalBarColor[1], originalBarColor[2], originalBarColor[3])
            end
            refresh()
        end,
    })
end

local function ConfigureBarColorSwatch(item, spellID, bar)
    local swatch = Affected(item).barColorSwatch
    if not swatch then
        swatch = settingsSwatchPool:Acquire()
        swatch:SetParent(item)
        swatch:ClearAllPoints()
        swatch:SetPoint("LEFT", item, "RIGHT", 4, 0)
        swatch:SetSize(18, 18)
        swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        Affected(item).barColorSwatch = swatch
    end

    swatch:SetColorRGB(GetBarSwatchColor(bar, spellID))
    swatch:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            CooldownStyle.ClearBarColor(spellID)
            ApplyBarColorToBar(bar, spellID)
            swatch:SetColorRGB(GetBarSwatchColor(bar, spellID))
            RefreshBuffBarColors()
        else
            OpenBarColorPicker(spellID, swatch, bar)
        end
    end)
    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Bar Color")
        GameTooltip:AddLine("Left-click: pick a color", 1, 1, 1)
        GameTooltip:AddLine("Right-click: reset to default", 1, 1, 1)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", GameTooltip_Hide)
    swatch:Show()
end

local function RefreshBarColorSwatches(category)
    if not category or not category.itemPool then
        return
    end
    if not settingsSwatchPool then
        settingsSwatchPool = CreateFramePool("Button", UIParent, "ColorSwatchTemplate")
    end
    for item in category.itemPool:EnumerateActive() do
        local bar = item.Bar
        if item.GetCooldownInfo and bar then
            local cooldownInfo = item:GetCooldownInfo()
            local spellID = GetMostOverrideSpellIDFromCooldownInfo(cooldownInfo)
            if spellID then
                ApplyBarColorToBar(bar, spellID)
                ConfigureBarColorSwatch(item, spellID, bar)
            end
        end
    end
end

local barColorSettingsHooked = false
local function InstallBarColorSettingsHook()
    if barColorSettingsHooked then
        return
    end
    if
        type(CooldownViewerSettingsBarCategoryMixin) ~= "table"
        or not CooldownViewerSettingsBarCategoryMixin.RefreshLayout
    then
        return
    end
    barColorSettingsHooked = true
    hooksecurefunc(CooldownViewerSettingsBarCategoryMixin, "RefreshLayout", RefreshBarColorSwatches)
end

local function RefreshChildFramesHook()
    local essentialViewer = _G["EssentialCooldownViewer"]
    if essentialViewer then
        for _, cdmFrame in ipairs(essentialViewer:GetItemFrames()) do
            if cdmFrame.Cooldown and cdmFrame.Icon then
                HookCooldownFrame(cdmFrame)
            end
        end
    end

    local utilityViewer = _G["UtilityCooldownViewer"]
    if utilityViewer then
        for _, cdmFrame in ipairs(utilityViewer:GetItemFrames()) do
            if cdmFrame.Cooldown and cdmFrame.Icon then
                HookCooldownFrame(cdmFrame)
            end
        end
    end

    local buffViewer = _G["BuffIconCooldownViewer"]
    if buffViewer then
        for _, cdmFrame in ipairs(buffViewer:GetItemFrames()) do
            if cdmFrame.Cooldown and cdmFrame.Icon then
                HookBuffIconFrame(cdmFrame)
            end
        end
    end

    RefreshBuffBarColors()
end

local viewers = {
    ["BuffIconCooldownViewer"] = BuffIconCooldownViewer,
    ["BuffBarCooldownViewer"] = BuffBarCooldownViewer,
    ["EssentialCooldownViewer"] = EssentialCooldownViewer,
    ["UtilityCooldownViewer"] = UtilityCooldownViewer,
}

local function GetCooldownViewerChild(frame)
    if not frame or not frame.GetParent then
        return nil
    end
    if not frame.cooldownInfo then
        return nil
    end
    local current = frame
    while current and current.GetParent do
        local parent = current:GetParent()
        if not parent then
            return nil
        end
        for _, viewer in pairs(viewers) do
            if parent == viewer then
                return current
            end
        end
        current = parent
    end
    return nil
end

local function HookActionButtonSpellAlertManager()
    if not ActionButtonSpellAlertManager then
        return
    end
    if ns.API:GetIsAffected(ActionButtonSpellAlertManager, "spellAlertHooked") then
        return
    end

    hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, frame)
        local activeGlowTarget = GetCooldownViewerChild(frame)
        if not activeGlowTarget then
            return
        end
        local styleKey = GetStyleKeyFromCooldownInfo(frame.cooldownInfo, false)
        if not styleKey then
            return
        end

        local disableProcs = CooldownStyle.GetDisableProcsGlow(styleKey)
        local glowStyle = ns.db.profile.cooldownManager_experimental_glow_style
        local customStyle = glowStyle and glowStyle ~= "DEFAULT"

        if activeGlowTarget.SpellActivationAlert then
            activeGlowTarget.SpellActivationAlert:SetAlpha((disableProcs or customStyle) and 0 or 1)
        end

        Affected(activeGlowTarget).procActive = (customStyle and not disableProcs) or nil
        UpdateButtonGlowState(activeGlowTarget)
    end)

    hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(_, frame)
        local activeGlowTarget = GetCooldownViewerChild(frame)
        if not activeGlowTarget or not Affected(activeGlowTarget).procActive then
            return
        end
        Affected(activeGlowTarget).procActive = nil
        UpdateButtonGlowState(activeGlowTarget)
    end)
    ns.API:SetAffected(ActionButtonSpellAlertManager, "spellAlertHooked")
end

function CooldownStyle:RefreshHooks()
    RefreshChildFramesHook()
    InstallBarColorSettingsHook()
end

function CooldownStyle:RefreshAllGlows()
    for name in pairs(viewers) do
        local viewer = _G[name]
        if viewer then
            for _, cdmFrame in ipairs(viewer:GetItemFrames()) do
                if cdmFrame.GetCooldownInfo and ns.API:GetIsAffected(cdmFrame, "cooldownStyleHooked") then
                    UpdateButtonGlowState(cdmFrame)
                end
            end
        end
    end
end

local glowUsabilityFrame
local function HookGlowUsabilityEvents()
    if glowUsabilityFrame then
        return
    end
    glowUsabilityFrame = CreateFrame("Frame")
    glowUsabilityFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    glowUsabilityFrame:SetScript("OnEvent", function()
        CooldownStyle:RefreshAllGlows()
    end)
end

local isMenuModified = false
function CooldownStyle:Initialize()
    RefreshChildFramesHook()
    HookActionButtonSpellAlertManager()
    HookGlowUsabilityEvents()
    InstallBarColorSettingsHook()
    if isMenuModified then
        return
    end

    Menu.ModifyMenu("MENU_COOLDOWN_SETTINGS_ITEM", function(owner, rootDescription, _contextData)
        local cdInfo = owner:GetCooldownInfo()
        local category = cdInfo.category
        -- Settings key: base spellID (first tab) / most-specific override spellID
        -- (second tab) for normal cooldowns; the slot's stable cooldownID for
        -- 12.1.0 dynamic item/spell-category icons. See GetStyleKeyFromCooldownInfo.
        local baseKey = GetStyleKeyFromCooldownInfo(cdInfo, false)
        local overrideKey = GetStyleKeyFromCooldownInfo(cdInfo, true)

        rootDescription:CreateDivider()
        rootDescription:CreateTitle(MENU_TITLE)

        if COOLDOWN_LIKE_CATEGORY[category] then
            rootDescription:CreateCheckbox("Always Show Cooldown Edge", function()
                return CooldownStyle.GetAlwaysShowCooldownEdge(baseKey)
            end, function()
                CooldownStyle.ToggleAlwaysShowCooldownEdge(baseKey)
                RefreshChildFramesHook()
            end)
        end
        if TRACKED_LIKE_CATEGORY[category] then
            rootDescription:CreateCheckbox("Always Show Cooldown Edge", function()
                return CooldownStyle.GetAlwaysShowCooldownEdge(overrideKey)
            end, function()
                CooldownStyle.ToggleAlwaysShowCooldownEdge(overrideKey)
                RefreshChildFramesHook()
            end)
        end

        --[[ category: 
        
        -1 HiddenSpell,
        0 Essential,
        1 Utility,

        -2 HiddenAura, 
        2 TrackedBuff, 
        3 TrackedBar.
        ]]
        if cdInfo.hasAura or cdInfo.selfAura then
            if COOLDOWN_LIKE_CATEGORY[category] then
                rootDescription:CreateCheckbox("Hide Aura", function()
                    return not CooldownStyle.GetShowAuras(baseKey)
                end, function()
                    CooldownStyle.ToggleShowAuras(baseKey)
                    RefreshChildFramesHook()
                end)
            end

            if COOLDOWN_LIKE_CATEGORY[category] then
                rootDescription:CreateCheckbox("Reverse Aura Swipe", function()
                    return CooldownStyle.GetReverseAuraSwipe(baseKey)
                end, function()
                    CooldownStyle.ToggleReverseAuraSwipe(baseKey)
                    RefreshChildFramesHook()
                end)
            end
        end

        if COOLDOWN_LIKE_CATEGORY[category] then
            rootDescription:CreateCheckbox("Disable Proc Glow", function()
                return CooldownStyle.GetDisableProcsGlow(baseKey)
            end, function()
                CooldownStyle.ToggleDisableProcsGlow(baseKey)
                -- RefreshChildFramesHook()
            end)

            rootDescription:CreateCheckbox("Glow when ready", function()
                return CooldownStyle.GetGlowWhenReady(baseKey)
            end, function()
                CooldownStyle.ToggleGlowWhenReady(baseKey)
                RefreshChildFramesHook()
            end)
            if cdInfo.charges then
                rootDescription:CreateCheckbox("Glow when full charges", function()
                    return CooldownStyle.GetGlowOnFullCharges(baseKey)
                end, function()
                    CooldownStyle.ToggleGlowOnFullCharges(baseKey)
                    RefreshChildFramesHook()
                end)
            end

            rootDescription:CreateCheckbox("Never Desaturate", function()
                return CooldownStyle.GetNeverDesaturate(baseKey)
            end, function()
                CooldownStyle.ToggleNeverDesaturate(baseKey)
                RefreshChildFramesHook()
            end)
        end

        if TRACKED_LIKE_CATEGORY[category] then
            rootDescription:CreateCheckbox("Always glow", function()
                return CooldownStyle.GetAlwaysGlow(overrideKey)
            end, function()
                CooldownStyle.ToggleAlwaysGlow(overrideKey)
                RefreshChildFramesHook()
            end)
        end

        rootDescription:CreateButton("Reset to Defaults", function()
            local db = CooldownStyle.GetDB()
            if COOLDOWN_LIKE_CATEGORY[category] then
                db.spellSettings[baseKey] = nil
            else
                db.spellSettings[overrideKey] = nil
            end
            RefreshChildFramesHook()
        end)
    end)
    isMenuModified = true
end
function CooldownStyle.GetDB()
    return ns.db.profile.cooldownStyleSettings
end

function CooldownStyle.GetSpellSettings(spellID)
    local db = ns.db.profile.cooldownStyleSettings
    if not db or not db.spellSettings or db.spellSettings[spellID] == nil then
        return nil
    end
    return db.spellSettings[spellID]
end

function CooldownStyle.EnsureSpellSettings(spellID)
    -- Backstop: every caller should pass a stable styleKey (spellID or
    -- "cd:"..cooldownID). A nil key means an unresolved icon slipped through;
    -- hand back a throwaway table so writes no-op instead of erroring.
    if spellID == nil then
        return {}
    end
    local db = ns.db.profile.cooldownStyleSettings
    if db.spellSettings[spellID] == nil then
        db.spellSettings[spellID] = {}
    end
    return db.spellSettings[spellID]
end

function CooldownStyle.GetAlwaysShowCooldownEdge(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.alwaysShowCooldownEdge ~= nil then
        return settings.alwaysShowCooldownEdge
    end
    return DEFAULT_ALWAYS_SHOW_COOLDOWN_EDGE
end

function CooldownStyle.SetAlwaysShowCooldownEdge(spellID, value)
    if value == DEFAULT_ALWAYS_SHOW_COOLDOWN_EDGE then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.alwaysShowCooldownEdge = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.alwaysShowCooldownEdge = value
end

function CooldownStyle.ToggleAlwaysShowCooldownEdge(spellID)
    local current = CooldownStyle.GetAlwaysShowCooldownEdge(spellID)
    CooldownStyle.SetAlwaysShowCooldownEdge(spellID, not current)
end

function CooldownStyle.GetShowAuras(spellID)
    if spellID == nil then
        return DEFAULT_SHOW_AURAS
    end
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.showAuras ~= nil then
        return settings.showAuras
    end
    return DEFAULT_SHOW_AURAS
end

function CooldownStyle.SetShowAuras(spellID, value)
    if value == DEFAULT_SHOW_AURAS then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.showAuras = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.showAuras = value
end

function CooldownStyle.ToggleShowAuras(spellID)
    local current = CooldownStyle.GetShowAuras(spellID)
    CooldownStyle.SetShowAuras(spellID, not current)
end

function CooldownStyle.GetReverseAuraSwipe(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.reverseAuraSwipe ~= nil then
        return settings.reverseAuraSwipe
    end
    return DEFAULT_REVERSE_AURA_SWIPE
end

function CooldownStyle.SetReverseAuraSwipe(spellID, value)
    if value == DEFAULT_REVERSE_AURA_SWIPE then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.reverseAuraSwipe = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.reverseAuraSwipe = value
end

function CooldownStyle.ToggleReverseAuraSwipe(spellID)
    local current = CooldownStyle.GetReverseAuraSwipe(spellID)
    CooldownStyle.SetReverseAuraSwipe(spellID, not current)
end

function CooldownStyle.GetDisableProcsGlow(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.disableProcsGlow ~= nil then
        return settings.disableProcsGlow
    end
    return DEFAULT_DISABLE_PROCS_GLOW
end

function CooldownStyle.SetDisableProcsGlow(spellID, value)
    if value == DEFAULT_DISABLE_PROCS_GLOW then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.disableProcsGlow = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.disableProcsGlow = value
end

function CooldownStyle.ToggleDisableProcsGlow(spellID)
    local current = CooldownStyle.GetDisableProcsGlow(spellID)
    CooldownStyle.SetDisableProcsGlow(spellID, not current)
end

function CooldownStyle.GetGlowWhenReady(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.glowWhenReady ~= nil then
        return settings.glowWhenReady
    end
    return DEFAULT_GLOW_WHEN_READY
end

function CooldownStyle.SetGlowWhenReady(spellID, value)
    if value == DEFAULT_GLOW_WHEN_READY then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.glowWhenReady = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.glowWhenReady = value
end

function CooldownStyle.ToggleGlowWhenReady(spellID)
    local current = CooldownStyle.GetGlowWhenReady(spellID)
    CooldownStyle.SetGlowWhenReady(spellID, not current)
end

function CooldownStyle.GetGlowOnFullCharges(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.glowOnFullCharges ~= nil then
        return settings.glowOnFullCharges
    end
    return DEFAULT_GLOW_ON_FULL_CHARGES
end

function CooldownStyle.SetGlowOnFullCharges(spellID, value)
    if value == DEFAULT_GLOW_ON_FULL_CHARGES then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.glowOnFullCharges = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.glowOnFullCharges = value
end

function CooldownStyle.ToggleGlowOnFullCharges(spellID)
    local current = CooldownStyle.GetGlowOnFullCharges(spellID)
    CooldownStyle.SetGlowOnFullCharges(spellID, not current)
end

function CooldownStyle.GetAlwaysGlow(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.alwaysGlow ~= nil then
        return settings.alwaysGlow
    end
    return DEFAULT_ALWAYS_GLOW
end

function CooldownStyle.SetAlwaysGlow(spellID, value)
    if value == DEFAULT_ALWAYS_GLOW then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.alwaysGlow = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.alwaysGlow = value
end

function CooldownStyle.ToggleAlwaysGlow(spellID)
    local current = CooldownStyle.GetAlwaysGlow(spellID)
    CooldownStyle.SetAlwaysGlow(spellID, not current)
end

-- Bar fill color is stored per spell in settings.barColor: nil leaves Blizzard's
-- color, { r, g, b } is a custom fill chosen with the color picker.
function CooldownStyle.SetBarColorCustom(spellID, r, g, b)
    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.barColor = { r, g, b }
end

function CooldownStyle.ClearBarColor(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings ~= nil then
        settings.barColor = nil
    end
end

function CooldownStyle.GetNeverDesaturate(spellID)
    local settings = CooldownStyle.GetSpellSettings(spellID)
    if settings and settings.neverDesaturate ~= nil then
        return settings.neverDesaturate
    end
    return DEFAULT_NEVER_DESATURATE
end

function CooldownStyle.SetNeverDesaturate(spellID, value)
    if value == DEFAULT_NEVER_DESATURATE then
        local settings = CooldownStyle.GetSpellSettings(spellID)
        if settings ~= nil then
            settings.neverDesaturate = nil
        end
        return
    end

    local settings = CooldownStyle.EnsureSpellSettings(spellID)
    settings.neverDesaturate = value
end

function CooldownStyle.ToggleNeverDesaturate(spellID)
    local current = CooldownStyle.GetNeverDesaturate(spellID)
    CooldownStyle.SetNeverDesaturate(spellID, not current)
end
