-- ManaRise - Animation.lua
-- Smoothing and flashes.
--
-- Preferred path: the client's native StatusBar interpolation
-- (Enum.StatusBarInterpolation.ExponentialEaseOut). It runs in the engine,
-- costs no Lua per frame, and accepts secret values.
--
-- Fallback path: ONE shared driver frame with an OnUpdate capped at ~30 fps.
-- It only exists while something is animating and stops itself when idle.
-- It is used for (a) smoothing when native interpolation is missing and the
-- mana value is readable, and (b) the /mr test simulation.
--
-- Flashes and the liquid loops use native AnimationGroups (no OnUpdate).

local _, ns = ...

local A = {}
ns.Animation = A

local FRAME_INTERVAL = 1 / 30
local EASE_RATE = 14          -- higher = snappier fallback easing

---------------------------------------------------------------------------
-- Native interpolation detection
---------------------------------------------------------------------------
function A:Init()
    local interp = ns.api.StatusBarInterpolation
    self.interpImmediate = interp and interp.Immediate
    self.interpSmooth = interp and interp.ExponentialEaseOut
    self.hasNativeInterpolation = (self.interpImmediate ~= nil and self.interpSmooth ~= nil)
end

---------------------------------------------------------------------------
-- Shared driver
---------------------------------------------------------------------------
local driver = CreateFrame("Frame")
local tickers = {}        -- [key] = fn(elapsed) -> keepRunning
local tickerCount = 0
local accum = 0

local function OnUpdate(_, elapsed)
    accum = accum + elapsed
    if accum < FRAME_INTERVAL then return end
    local dt = accum
    accum = 0
    for key, fn in pairs(tickers) do
        if not fn(dt) then
            tickers[key] = nil
            tickerCount = tickerCount - 1
        end
    end
    if tickerCount <= 0 then
        tickerCount = 0
        driver:SetScript("OnUpdate", nil)
    end
end

function A:AddTicker(key, fn)
    if not tickers[key] then
        tickerCount = tickerCount + 1
    end
    tickers[key] = fn
    if tickerCount == 1 then
        accum = 0
        driver:SetScript("OnUpdate", OnUpdate)
    end
end

function A:RemoveTicker(key)
    if tickers[key] then
        tickers[key] = nil
        tickerCount = tickerCount - 1
        if tickerCount <= 0 then
            tickerCount = 0
            driver:SetScript("OnUpdate", nil)
        end
    end
end

function A:IsDriverRunning()
    return tickerCount > 0
end

---------------------------------------------------------------------------
-- Fallback smoothing (only for readable, non-secret values)
---------------------------------------------------------------------------
local easing = {}   -- [indicator] = true
local easingCount = 0

local function EaseTick(dt)
    local k = dt * EASE_RATE
    if k > 1 then k = 1 end
    for ind in pairs(easing) do
        local target = ind.target
        local cur = ind.display or target
        local snap = (ind.barMax or 1) * 0.002
        local diff = target - cur
        if diff < snap and diff > -snap then
            ind.display = target
            ind.bar:SetValue(target)
            easing[ind] = nil
            easingCount = easingCount - 1
        else
            cur = cur + diff * k
            ind.display = cur
            ind.bar:SetValue(cur)
        end
    end
    return easingCount > 0
end

local function StopEasing(ind)
    if easing[ind] then
        easing[ind] = nil
        easingCount = easingCount - 1
        if easingCount <= 0 then
            easingCount = 0
            A:RemoveTicker("ease")
        end
    end
end

-- Push a value to an indicator's StatusBar.
-- value may be secret; if so it is only ever handed to the engine.
function A:SetBarValue(ind, value, isSecret, smooth)
    local bar = ind.bar
    if self.hasNativeInterpolation then
        bar:SetValue(value, smooth and self.interpSmooth or self.interpImmediate)
        return
    end

    if smooth and not isSecret then
        ind.target = value
        if ind.display == nil then ind.display = value end
        if not easing[ind] then
            easing[ind] = true
            easingCount = easingCount + 1
            self:AddTicker("ease", EaseTick)
        end
    else
        StopEasing(ind)
        bar:SetValue(value)
        if isSecret then
            ind.display = nil
        else
            ind.display = value
        end
    end
end

function A:ResetIndicator(ind)
    StopEasing(ind)
    ind.display = nil
    ind.target = nil
end

---------------------------------------------------------------------------
-- Flashes (native AnimationGroups)
---------------------------------------------------------------------------
local function MakeFlash(texture, peak, inDur, outDur)
    local group = texture:CreateAnimationGroup()
    group.parts = {}
    local fadeIn = group:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(peak)
    fadeIn:SetDuration(inDur)
    fadeIn:SetOrder(1)
    group.parts[1] = { fadeIn, 0, peak }
    local fadeOut = group:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(peak)
    fadeOut:SetToAlpha(0)
    group.parts[2] = { fadeOut, peak, 0 }
    fadeOut:SetDuration(outDur)
    fadeOut:SetOrder(2)
    -- The texture stays hidden at rest and is shown only while the flash
    -- plays. Relying on alpha 0 alone is not safe: on textures, alpha and the
    -- vertex-color alpha are the same value, so restyling can make it visible.
    local function HideTexture() texture:Hide() end
    group:SetScript("OnFinished", HideTexture)
    group:SetScript("OnStop", HideTexture)
    return group
end

-- Alternative ready animations (ns.db.readyAnim).
-- double: two quick pulses of the same border glow.
local function MakeDouble(texture)
    local group = texture:CreateAnimationGroup()
    local steps = { { 0, 0.9, 0.05 }, { 0.9, 0, 0.1 }, { 0, 0.9, 0.05 }, { 0.9, 0, 0.18 } }
    group.parts = {}
    for i, s in ipairs(steps) do
        local a = group:CreateAnimation("Alpha")
        group.parts[i] = { a, s[1], s[2] }
        a:SetFromAlpha(s[1])
        a:SetToAlpha(s[2])
        a:SetDuration(s[3])
        a:SetOrder(i)
    end
    local function HideTexture() texture:Hide() end
    group:SetScript("OnFinished", HideTexture)
    group:SetScript("OnStop", HideTexture)
    return group
end

-- sweep: a soft band rises through the icon (native Translation + Alpha).
local function MakeSweep(texture, rise)
    local group = texture:CreateAnimationGroup()
    local up = group:CreateAnimation("Translation")
    up:SetOffset(0, rise)
    up:SetDuration(0.45)
    up:SetOrder(1)
    local fadeIn = group:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(0.9)
    fadeIn:SetDuration(0.12)
    fadeIn:SetOrder(1)
    local fadeOut = group:CreateAnimation("Alpha")
    group.parts = { { fadeIn, 0, 0.9 }, { fadeOut, 0.9, 0 } }
    fadeOut:SetFromAlpha(0.9)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.25)
    fadeOut:SetStartDelay(0.2)
    fadeOut:SetOrder(1)
    local function HideTexture() texture:Hide() end
    group:SetScript("OnFinished", HideTexture)
    group:SetScript("OnStop", HideTexture)
    return group
end

function A:SetupIndicator(ind)
    -- ~0.25 s ready flash around the icon border
    ind.glowAnim = MakeFlash(ind.glow, 0.9, 0.07, 0.18)
    ind.doubleAnim = MakeDouble(ind.glow)
    if ind.sweep then
        local h = ind.icon.GetHeight and ind.icon:GetHeight() or 0
        if type(h) ~= "number" or h <= 0 then h = 36 end
        ind.sweepAnim = MakeSweep(ind.sweep, h)
    end
    -- short brightening of the fill edge on an observed mana gain
    ind.pulseAnim = MakeFlash(ind.edgeGlow, 0.8, 0.06, 0.22)
    self:ApplyEffectOpacity(ind)
end

-- The opacity of a custom effect color scales the peak of its animation.
-- (Never the texture's own alpha: the resting layers must stay invisible.)
local function ScaleParts(group, k)
    if not group or not group.parts then return end
    for _, p in ipairs(group.parts) do
        p[1]:SetFromAlpha(p[2] * k)
        p[1]:SetToAlpha(p[3] * k)
    end
end

function A:ApplyEffectOpacity(ind)
    local o = ind.fxOpacity
    if not o then return end
    ScaleParts(ind.glowAnim, o.flash)
    ScaleParts(ind.doubleAnim, o.flash)
    ScaleParts(ind.pulseAnim, o.pulse)
    ScaleParts(ind.sweepAnim, o.sweep)
end

function A:PlayGlow(ind)
    local kind = ns.db.readyAnim
    if kind == "sweep" and ind.sweepAnim then
        ind.sweepAnim:Stop()
        ind.sweep:Show()
        ind.sweepAnim:Play()
    elseif kind == "double" and ind.doubleAnim then
        ind.doubleAnim:Stop()
        ind.glow:Show()
        ind.doubleAnim:Play()
    elseif ind.glowAnim then
        ind.glowAnim:Stop()
        ind.glow:Show()
        ind.glowAnim:Play()
    end
end

function A:PlayPulse(ind)
    if ind.pulseAnim and not ind.pulseAnim:IsPlaying() then
        ind.edgeGlow:Show()
        ind.pulseAnim:Play()
    end
end

---------------------------------------------------------------------------
-- Liquid loops (native AnimationGroups, looping; no OnUpdate)
-- Waves: TextureCoordTranslation by exactly one texture width on textures
-- with horizontal REPEAT wrap, the same technique Blizzard's marching-ants
-- border uses. Bubbles: Translation up plus Alpha fades, with start delays.
-- Loops play only while an indicator's overlay is shown.
---------------------------------------------------------------------------
local BUBBLE_DUR = { 2.6, 3.3, 2.9, 3.6, 2.4 }
local BUBBLE_RISE = { 0.80, 0.62, 0.72, 0.85, 0.55 }   -- fraction of the icon height
local BUBBLE_DRIFT = { 1.5, -1.0, 0.8, -1.4, 1.1 }
local BUBBLE_ALPHA = 0.95

local liquidPlaying = {}   -- [indicator] = true

-- Wave intensity (/mr waves, options panel): how long one wave loop takes
-- (a multiplier on each button's base duration) and how strong the back
-- wave is.
A.WAVE_SPEED = { calm = 1.7, normal = 1, lively = 0.6 }
-- Wave intensity (ns.db.waveHeight): how tall the wave band is, as a share of
-- the full-size band the textures were drawn for, and how strong the back wave
-- is. Low keeps the surface close to the real fill line.
A.WAVE_SCALE = { low = 0.4, medium = 0.7, high = 1 }
A.BACK_ALPHA = { low = 0.25, medium = 0.45, high = 0.7 }

-- cat: the bar category of the button (nil: the global setting); res: its resource
local function WaveSetting(cat, res)
    local w = ns.db and ns:WaveFor(cat, res, "waves")
    if A.WAVE_SPEED[w] then return w end
    return "normal"
end

local function HeightSetting(cat, res)
    local h = ns.db and ns:WaveFor(cat, res, "waveHeight")
    if A.WAVE_SCALE[h] then return h end
    return "low"
end

function A:WaveScale(cat, res)
    return A.WAVE_SCALE[HeightSetting(cat, res)]
end

function A:BackWaveAlpha(cat, res)
    return A.BACK_ALPHA[HeightSetting(cat, res)]
end

-- (Re)anchor the four wave bands for the current L.waveHalf. Textures that
-- scroll by sliding ("move" method) are twice the icon width and keep their
-- start offset in L.scrollX0.
function A:AnchorLiquidBands(L)
    local half = L.waveHalf
    for _, t in ipairs({ L.back, L.top, L.body, L.crest }) do
        local raise = L.raise[t] or 0
        local x0 = L.scrollX0 and L.scrollX0[t]
        t:ClearAllPoints()
        if x0 then
            t:SetPoint("TOPLEFT", L.barTex, "TOPLEFT", x0, half + raise)
            t:SetPoint("BOTTOMRIGHT", L.barTex, "TOPLEFT", x0 + 2 * L.width, -half + raise)
        else
            t:SetPoint("TOPLEFT", L.barTex, "TOPLEFT", 0, half + raise)
            t:SetPoint("BOTTOMRIGHT", L.barTex, "TOPRIGHT", 0, -half + raise)
        end
    end
end

local function BubblesWanted(L, cat, res)
    return L.bubblesOK and ns.db and ns:ResSettingFor(cat, res, "bubbles") ~= false
end

-- How the waves scroll. On the 1.60.1 client, CreateAnimation from Lua does
-- not give a working TextureCoordTranslation (the object has no SetOffset;
-- confirmed in-game), while Blizzard's own UI only ever defines that type in
-- XML. So, in order of preference:
--   "lua"  - Lua TextureCoordTranslation, if this client supports it
--   "xml"  - TextureCoordTranslation from the templates in ManaRise.xml
--   "move" - slide a double-width wave texture sideways with Translation
--            (clipped by the button's IconMask), which Blizzard Lua uses
A.scrollMethod = nil
A.scrollProbe = nil       -- what the Lua attempt returned, for /mr status

local function PickScrollMethod(L)
    local t = L.top
    local ok, a = pcall(function()
        return t:CreateAnimationGroup():CreateAnimation("TextureCoordTranslation")
    end)
    A.scrollProbe = ok and a and a.GetObjectType and a:GetObjectType() or tostring(a)
    if ok and a and a.SetOffset then return "lua" end

    local ok2, g = pcall(t.CreateAnimationGroup, t, nil, "ManaRiseScrollLeftTemplate")
    if ok2 and g and g.GetAnimations then
        local x = g:GetAnimations()
        if x and x.SetDuration and (not x.GetObjectType or x:GetObjectType() == "TextureCoordTranslation") then
            return "xml"
        end
    end
    if L.clipped then return "move" end
    return nil
end

-- direction +1 moves the wave left (texture coords increase), -1 right.
local function MakeScroll(L, texture, duration, direction, phase, groups)
    local method = A.scrollMethod
    if method == "move" then
        -- Two wave periods over two icon widths, slid by one icon width per
        -- loop, so the end of each loop matches its start exactly.
        local w, half, raise = L.width, L.waveHalf, L.raise[texture] or 0
        local x0 = (direction > 0) and 0 or -w
        L.scrollX0 = L.scrollX0 or {}
        L.scrollX0[texture] = x0
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", L.barTex, "TOPLEFT", x0, half + raise)
        texture:SetPoint("BOTTOMRIGHT", L.barTex, "TOPLEFT", x0 + 2 * w, -half + raise)
        texture:SetTexCoord(phase, phase + 2, 0, 1)
        local g = texture:CreateAnimationGroup()
        g:SetLooping("REPEAT")
        local a = g:CreateAnimation("Translation")
        a:SetOffset(-direction * w, 0)
        a:SetDuration(duration)
        groups[#groups + 1] = g
        return a
    end

    texture:SetTexCoord(phase, 1 + phase, 0, 1)
    local g, a
    if method == "xml" then
        g = texture:CreateAnimationGroup(nil,
            direction > 0 and "ManaRiseScrollLeftTemplate" or "ManaRiseScrollRightTemplate")
        a = g:GetAnimations()
    else
        g = texture:CreateAnimationGroup()
        g:SetLooping("REPEAT")
        a = g:CreateAnimation("TextureCoordTranslation")
        a:SetOffset(direction, 0)
    end
    a:SetDuration(duration)
    groups[#groups + 1] = g
    return a
end

local function MakeBubble(texture, duration, delay, rise, drift, groups)
    local g = texture:CreateAnimationGroup()
    g:SetLooping("REPEAT")
    local up = g:CreateAnimation("Translation")
    up:SetOffset(drift, rise)
    up:SetDuration(duration)
    up:SetStartDelay(delay)
    up:SetSmoothing("IN")
    up:SetOrder(1)
    local fadeIn = g:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(BUBBLE_ALPHA)
    fadeIn:SetDuration(0.4)
    fadeIn:SetStartDelay(delay)
    fadeIn:SetOrder(1)
    local fadeOut = g:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(BUBBLE_ALPHA)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.7)
    fadeOut:SetStartDelay(delay + duration - 0.7)
    fadeOut:SetOrder(1)
    groups[#groups + 1] = g
end

-- Build the loops for one indicator's liquid layers. seed varies timing so
-- buttons don't move in lockstep. Returns false plus the error if the client
-- rejected anything (the caller then keeps that button on the flat look).
function A:SetupLiquid(L, seed)
    if A.scrollMethod == nil then
        A.scrollMethod = PickScrollMethod(L) or false
    end
    if not A.scrollMethod then
        return false, string.format(ns.L.PROBLEM_NO_SCROLL, tostring(A.scrollProbe))
    end
    local ok, err = pcall(function()
        local groups = {}
        local scrolls = {}
        -- start each button at a different point along the wave
        local p1 = (seed * 0.37) % 1
        local p2 = (seed * 0.61) % 1
        local speed = A.WAVE_SPEED[WaveSetting()]
        local function Scroll(texture, base, direction, phase)
            local a = MakeScroll(L, texture, base * speed, direction, phase, groups)
            scrolls[#scrolls + 1] = { anim = a, base = base }
        end

        -- the three front-surface textures share one speed so they stay aligned
        local front = 2.8 + (seed % 3) * 0.3
        Scroll(L.top, front, 1, p1)
        Scroll(L.body, front, 1, p1)
        Scroll(L.crest, front, 1, p1)
        -- back wave: slower, opposite direction
        Scroll(L.back, 4.6 + (seed % 4) * 0.35, -1, p2)
        L.groups = groups
        L.scrolls = scrolls
        L.speed = speed
    end)
    if not ok then return false, err end
    L.waveGroups = {}
    for i = 1, #L.groups do L.waveGroups[i] = L.groups[i] end

    -- Bubbles are extra: if the client rejects them, keep the waves.
    local bubbleGroups = {}
    local bok, berr = pcall(function()
        for i = 1, #L.bubbles do
            local duration = BUBBLE_DUR[i] + (seed * 0.29) % 0.6
            local delay = (seed * 0.53 + i * 0.87) % 2.6
            MakeBubble(L.bubbles[i], duration, delay, L.height * BUBBLE_RISE[i], BUBBLE_DRIFT[i], bubbleGroups)
        end
    end)
    L.waveTextures = { L.depth, L.back, L.top, L.body, L.crest, L.sheen }
    L.textures = { L.depth, L.back, L.top, L.body, L.crest, L.sheen }
    L.bubbleGroups = {}
    L.bubblesOK = bok and #L.bubbles > 0
    if bok then
        for i = 1, #bubbleGroups do
            L.groups[#L.groups + 1] = bubbleGroups[i]
            L.bubbleGroups[i] = bubbleGroups[i]
        end
        for i = 1, #L.bubbles do L.textures[#L.textures + 1] = L.bubbles[i] end
    else
        A.bubbleProblem = tostring(berr)
        for i = 1, #L.bubbles do L.bubbles[i]:Hide() end
    end
    return true
end

local function SetBubblesPlaying(L, on)
    L.bubblesPlaying = on
    for i = 1, #L.bubbleGroups do
        if on then L.bubbleGroups[i]:Play() else L.bubbleGroups[i]:Stop() end
    end
    for i = 1, #L.bubbles do L.bubbles[i]:SetShown(on) end
end

function A:StartLiquid(ind)
    local liq = ind.liquid
    if not liq or liquidPlaying[ind] then return end
    liquidPlaying[ind] = true
    for i = 1, #liq.waveTextures do liq.waveTextures[i]:Show() end
    for i = 1, #liq.waveGroups do liq.waveGroups[i]:Play() end
    if BubblesWanted(liq, ind.category, ind.resource) then SetBubblesPlaying(liq, true) end
end

-- Apply the wave intensity and bubbles settings to one button's liquid.
-- Only changes animation timing and visibility, so it is safe in combat.
function A:ApplyLiquidSettings(ind)
    local liq = ind.liquid
    if not liq or not liq.scrolls then return end
    local speed = A.WAVE_SPEED[WaveSetting(ind.category, ind.resource)]
    if liq.speed ~= speed then
        liq.speed = speed
        for i = 1, #liq.scrolls do
            local s = liq.scrolls[i]
            s.anim:SetDuration(s.base * speed)
        end
        if liquidPlaying[ind] then
            -- restart so the new duration takes effect right away
            for i = 1, #liq.waveGroups do
                liq.waveGroups[i]:Stop()
                liq.waveGroups[i]:Play()
            end
        end
    end
    local want = BubblesWanted(liq, ind.category, ind.resource) and liquidPlaying[ind] or false
    if want ~= (liq.bubblesPlaying or false) then
        SetBubblesPlaying(liq, want)
    end
end

function A:StopLiquid(ind)
    local liq = ind.liquid
    if not liq or not liquidPlaying[ind] then return end
    liquidPlaying[ind] = nil
    for i = 1, #liq.groups do liq.groups[i]:Stop() end
    for i = 1, #liq.textures do liq.textures[i]:Hide() end
    liq.bubblesPlaying = false
end

function A:LiquidPlayingCount()
    local n = 0
    for _ in pairs(liquidPlaying) do n = n + 1 end
    return n
end

---------------------------------------------------------------------------
-- Ice and burning-page loops. Same rules as the liquid: native looping
-- AnimationGroups, playing only while the overlay is shown. The edge shimmers
-- (ice slowly, fire fast). Ice sparks twinkle in place; fire embers rise.
-- The waves setting scales the durations, the bubbles toggle the particles.
---------------------------------------------------------------------------
local FX_EDGE_DUR = { ice = 1.8, paper = 0.45, parchment = 0.6 }
-- parchment reuses the rising paper particle animations
local function GroupKind(mode) return mode == "ice" and "ice" or "paper" end
local FX_TWINKLE = { 1.3, 1.7, 1.5, 1.9, 1.4 }
local FX_EMBER_RISE = { 0.55, 0.45, 0.6, 0.4, 0.5 }   -- fraction of the icon height
local FX_EMBER_DRIFT = { 1.5, -1.2, 0.8, -1.5, 1.0 }
local fxPlaying = {}   -- [indicator] = true

function A:SetupFx(fx, seed)
    local ok, err = pcall(function()
        local g = fx.edge:CreateAnimationGroup()
        g:SetLooping("BOUNCE")
        local a = g:CreateAnimation("Alpha")
        a:SetFromAlpha(1)
        a:SetToAlpha(0.55)
        a:SetDuration(1)
        fx.edgeGroup, fx.edgeAnim = g, a
    end)
    if not ok then return false, err end

    fx.groups = { ice = {}, paper = {} }
    fx.retime = {}
    local pok, perr = pcall(function()
        for i = 1, #fx.parts do
            local t = fx.parts[i]
            local delay = (seed * 0.53 + i * 0.87) % 2.2
            -- ice: fade in and out in place
            local tg = t:CreateAnimationGroup()
            tg:SetLooping("REPEAT")
            local fin = tg:CreateAnimation("Alpha")
            fin:SetFromAlpha(0)
            fin:SetToAlpha(1)
            fin:SetStartDelay(delay)
            fin:SetOrder(1)
            local fout = tg:CreateAnimation("Alpha")
            fout:SetFromAlpha(1)
            fout:SetToAlpha(0)
            fout:SetOrder(2)
            -- paper: rise from the burning edge and fade out
            local eg = t:CreateAnimationGroup()
            eg:SetLooping("REPEAT")
            local up = eg:CreateAnimation("Translation")
            up:SetOffset(FX_EMBER_DRIFT[i], fx.height * FX_EMBER_RISE[i])
            up:SetStartDelay(delay)
            up:SetSmoothing("OUT")
            up:SetOrder(1)
            local ein = eg:CreateAnimation("Alpha")
            ein:SetFromAlpha(0)
            ein:SetToAlpha(BUBBLE_ALPHA)
            ein:SetDuration(0.2)
            ein:SetStartDelay(delay)
            ein:SetOrder(1)
            local eout = eg:CreateAnimation("Alpha")
            eout:SetFromAlpha(BUBBLE_ALPHA)
            eout:SetToAlpha(0)
            eout:SetDuration(0.5)
            eout:SetOrder(1)
            fx.retime[i] = function(speed)
                local d = FX_TWINKLE[i] * speed
                fin:SetDuration(d * 0.5)
                fout:SetDuration(d * 0.5)
                local rise = (1.1 + i * 0.15) * speed
                up:SetDuration(rise)
                eout:SetStartDelay(delay + rise - 0.5)
            end
            fx.groups.ice[i] = tg
            fx.groups.paper[i] = eg
        end
    end)
    fx.partsOK = pok
    if not pok then
        A.fxParticleProblem = tostring(perr)
        fx.groups = { ice = {}, paper = {} }
    end
    return true
end

local function FxPartsWanted(fx, cat, res)
    return fx.partsOK and ns.db and ns:ResSettingFor(cat, res, "bubbles") ~= false
end

local function SetFxParts(fx, mode, on)
    fx.partsPlaying = on and mode or nil
    for i = 1, #fx.parts do
        local ice, paper = fx.groups.ice[i], fx.groups.paper[i]
        if ice then ice:Stop() end
        if paper then paper:Stop() end
        if on then fx.groups[GroupKind(mode)][i]:Play() end
        fx.parts[i]:SetShown(on)
    end
end

local function ConfigureFx(fx, mode, cat, res)
    local speed = A.WAVE_SPEED[WaveSetting(cat, res)]
    fx.speed = speed
    fx.edgeAnim:SetDuration(FX_EDGE_DUR[mode] * speed)
    if fx.partsOK then
        for i = 1, #fx.parts do fx.retime[i](speed) end
    end
end

function A:StartFx(ind)
    local fx, mode = ind.fx, ind.mode
    if not fx or (mode ~= "ice" and mode ~= "paper" and mode ~= "parchment") or fx.playing == mode then return end
    if fx.playing then self:StopFx(ind) end
    fxPlaying[ind] = true
    fx.playing = mode
    ConfigureFx(fx, mode, ind.category, ind.resource)
    fx.edge:Show()
    fx.shade:Show()
    if mode == "parchment" then
        fx.ptop:Show()
        fx.pbody:Show()
    end
    fx.edgeGroup:Play()
    if FxPartsWanted(fx, ind.category, ind.resource) then SetFxParts(fx, mode, true) end
end

-- Waves and bubbles settings for one button. Timing and visibility only,
-- so it is safe in combat.
function A:ApplyFxSettings(ind)
    local fx, mode = ind.fx, ind.fx and ind.fx.playing
    if not mode then return end
    if fx.speed ~= A.WAVE_SPEED[WaveSetting(ind.category, ind.resource)] then
        ConfigureFx(fx, mode, ind.category, ind.resource)
        fx.edgeGroup:Stop()
        fx.edgeGroup:Play()
        if fx.partsPlaying then SetFxParts(fx, mode, true) end
    end
    local want = FxPartsWanted(fx, ind.category, ind.resource) and true or false
    if want ~= (fx.partsPlaying ~= nil) then SetFxParts(fx, mode, want) end
end

function A:StopFx(ind)
    local fx = ind.fx
    if not fx or not fx.playing then return end
    fxPlaying[ind] = nil
    fx.playing = nil
    fx.edgeGroup:Stop()
    SetFxParts(fx, nil, false)
    for i = 1, #fx.all do fx.all[i]:Hide() end
end

function A:FxPlayingCount()
    local n = 0
    for _ in pairs(fxPlaying) do n = n + 1 end
    return n
end

function A:StopAll()
    for ind in pairs(fxPlaying) do
        self:StopFx(ind)
    end
    for ind in pairs(liquidPlaying) do
        self:StopLiquid(ind)
    end
    for ind in pairs(easing) do
        easing[ind] = nil
    end
    easingCount = 0
    for key in pairs(tickers) do
        tickers[key] = nil
    end
    tickerCount = 0
    driver:SetScript("OnUpdate", nil)
end
