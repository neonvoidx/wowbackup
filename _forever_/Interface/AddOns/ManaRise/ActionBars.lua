-- ManaRise - ActionBars.lua
-- Discovers action buttons (Blizzard's, plus Bartender4 / Dominos / ElvUI via
-- BarAddons.lua), attaches a passive overlay to each, and drives the overlays
-- from the observed resource.
--
-- Overlay design (per button):
--   * A hidden-alpha StatusBar (child of the button) sized to the icon,
--     vertical orientation, min..max = 0..requiredMana, value = current mana.
--     The engine computes the fill height, so this works even when mana is a
--     secret value (StatusBar:SetValue accepts secrets).
--   * Three textures created ON THE BUTTON's ARTWORK layer and anchored to the
--     StatusBar's fill texture:
--       dark  - from the icon's top down to the fill edge (unfilled = darker)
--       fill  - from the fill edge down to the icon's bottom (arcane blue)
--       edge  - thin bright line at the fill edge
--     Because they live on the button's own ARTWORK layer they draw *under*
--     the button's Cooldown frames, hotkey/count text (frameLevel 500) and
--     border, so Blizzard cooldown swipes and text remain on top.
--   * They are clipped by the masks the button's icon really uses (the
--     IconMask on default and LibActionButton skins), so the fill never
--     leaves the icon's rounded boundary. Square skins (ElvUI hides the
--     IconMask) get a square mask of our own the size of the icon instead.
--   * "liquid" style (default) adds layers on top of that geometry: a wave
--     band centered on the fill line (dark above the curve, liquid below,
--     a bright crest, and a dimmer back wave), depth shading, a surface
--     sheen and a few rising bubbles. The waves scroll with native
--     TextureCoordTranslation loops and the bubbles use native Translation and
--     Alpha loops, so no Lua runs per frame. In liquid mode the flat dark and
--     fill stop WAVE_HALF short of the fill line, and the wave band covers
--     the gap. "flat" style is the original look.
--
-- Nothing here touches secure attributes, button scripts, positions or sizes.
-- Indicator state is stored in ManaRise's own table, never on the Blizzard
-- button table, to avoid tainting it.

local _, ns = ...

local AB = {}
ns.ActionBars = AB

local IsSecret = ns.IsSecret
local L = ns.L
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLOW_ATLAS = "UI-HUD-ActionBar-IconFrame-Mouseover"
local ZERO_EPS = 0.002   -- tiny negative min so an empty bar keeps a valid fill rect
local MEDIA = "Interface\\AddOns\\ManaRise\\Media\\"
-- Sizes are in icon units (an action button icon is about 45 units). They are
-- deliberately bold: on a real button one unit is only 1-2 pixels.
local WAVE_HALF = 9      -- half the height of the wave band
local BACK_RAISE = 2.5   -- back wave sits slightly above the front surface
local TROUGH = 4         -- deepest point of the front wave below the fill line
                         -- (from wave_fill.tga); layers that belong inside the
                         -- liquid start below it so they never show above it
local SHEEN_HEIGHT = 12
local BUBBLES = {        -- x position (fraction of icon width from center), size
    { -0.28, 5.0 }, { -0.08, 3.5 }, { 0.10, 5.5 }, { 0.27, 4.0 }, { -0.18, 3.0 },
}
AB.LIQUID = { WAVE_HALF = WAVE_HALF, TROUGH = TROUGH }   -- full-size values (tests)

-- The wave band at the chosen intensity: the same textures squeezed
-- vertically, so the surface and the fill line stay together. Returns the
-- band half height, the trough depth and the back wave raise.
local function Geometry(ind)
    local k = ns.Animation:WaveScale(ind and ind.category, ind and ind.resource)
    return WAVE_HALF * k, TROUGH * k, BACK_RAISE * k
end
function AB:WaveGeometry(ind) return Geometry(ind) end

local indicators = {}    -- [button] = indicator
local list = {}          -- array of indicators (stable iteration, no allocs)

AB.discoverAfterCombat = false

-- The Cooldown Manager (Essential and Utility viewers). Its icons are tracked
-- as spell-based buttons; buff icons and bars have no spell cost to show.
local CDM_SOURCE = "Cooldown Manager"
local CDM_VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer" }
local cdmHooked = {}     -- [viewer name] = true (ManaRise's own table)
AB.CDM_SOURCE = CDM_SOURCE
AB.cdmViewers = 0        -- viewers found on the last scan

local BAR_FRAMES = {
    "MainActionBar", "MainMenuBar",
    "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft",
    "MultiBar5", "MultiBar6", "MultiBar7",
}

local NAMED_BUTTONS = {
    "ActionButton",
    "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton",
    "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}

---------------------------------------------------------------------------
-- Overlay construction
---------------------------------------------------------------------------
-- A lighter shade of the fill color for highlights (edge, crest, flash,
-- bubbles). rg is added to red and blue, g to green. For the default mana
-- blue this gives exactly the highlights of earlier versions; for rage,
-- energy and focus the highlight stays in the same color family.
local function Light(c, rb, g)
    return math.min(1, c.r + rb), math.min(1, c.g + g), math.min(1, c.b + rb)
end

-- The color for an indicator: its spell's resource (mana if unknown).
local function ColorOf(ind)
    local res = ind.resource or "mana"
    return ns:CatColor(ind.category, res) or ns:CatColor(ind.category, "mana")
end

-- Fill opacity: the Fill opacity setting times the opacity of the resource color.
local function FillAlpha(ind)
    return ns:ResSettingFor(ind.category, ind.resource, "fillAlpha") * ns.ColorOpacity(ColorOf(ind))
end

-- Ice and burning-page particles: { horizontal position (0-1), size }.
local FX_PARTS = { { 0.15, 5 }, { 0.38, 4 }, { 0.55, 6 }, { 0.74, 4 }, { 0.90, 5 } }

local function IsFxMode(mode) return mode == "ice" or mode == "paper" or mode == "parchment" end

-- Parchment keeps its own paper color; the resource color only tints it.
local function Tint(c)
    return 0.7 + 0.3 * c.r, 0.7 + 0.3 * c.g, 0.7 + 0.3 * c.b
end

-- Ice: the resource color pulled toward a clear icy blue (k = how far), so
-- the default mana blue stays blue instead of turning pale green or white.
local function IceTint(c, k, tr, tg, tb)
    return k * tr + (1 - k) * c.r, k * tg + (1 - k) * c.g, k * tb + (1 - k) * c.b
end

-- The fill layer: a flat color, or the texture of the ice / burning-page style.
local function StyleFill(ind)
    local c = ColorOf(ind)
    local mode = ind.mode
    if mode == "ice" then
        ind.fill:SetTexture(MEDIA .. "ice_fill", "REPEAT", "REPEAT")
        ind.fill:SetVertexColor(IceTint(c, 0.45, 0.30, 0.62, 1.0))
        ind.fill:SetAlpha(FillAlpha(ind))
    elseif mode == "paper" then
        -- an orange, see-through gradient: brightest at the burn edge, fading down
        ind.fill:SetTexture(MEDIA .. "burn_fill", "CLAMP", "CLAMP")
        ind.fill:SetVertexColor(IceTint(c, 0.8, 1.0, 0.45, 0.08))
        ind.fill:SetAlpha(FillAlpha(ind))
    elseif mode == "parchment" then
        ind.fill:SetTexture(MEDIA .. "parch_fill", "REPEAT", "REPEAT")
        ind.fill:SetVertexColor(Tint(c))
        ind.fill:SetAlpha(FillAlpha(ind))
    else
        ind.fill:SetColorTexture(c.r, c.g, c.b, FillAlpha(ind))
    end
end

-- Burning parchment: dark charcoal above a jagged burn line, cracked scorched
-- parchment below it, a glowing edge along the line, and embers and ash.
local function StyleParchment(ind, fx, c, anchor)
    fx.ptop:SetTexture(MEDIA .. "parch_top", "CLAMP", "CLAMP")
    fx.ptop:SetBlendMode("BLEND")
    fx.ptop:SetVertexColor(0.07, 0.06, 0.06)
    fx.ptop:SetAlpha(ns:ResSettingFor(ind.category, ind.resource, "darkAlpha"))
    fx.pbody:SetTexture(MEDIA .. "parch_body", "CLAMP", "CLAMP")
    fx.pbody:SetBlendMode("BLEND")
    fx.pbody:SetVertexColor(Tint(c))
    fx.pbody:SetAlpha(FillAlpha(ind))
    fx.edge:SetTexture(MEDIA .. "parch_edge", "CLAMP", "CLAMP")
    fx.edge:SetBlendMode("ADD")
    fx.edge:SetVertexColor(1, 1, 1)
    fx.edge:SetAlpha(1)
    fx.shade:SetTexture(MEDIA .. "sheen", "CLAMP", "CLAMP")
    fx.shade:SetBlendMode("BLEND")
    fx.shade:SetVertexColor(0.2, 0.08, 0.02)
    fx.shade:SetAlpha(0.5)
    for i = 1, #fx.parts do
        local t = fx.parts[i]
        local spark = i % 2 == 1
        t:SetTexture(MEDIA .. (spark and "spark" or "ash"), "CLAMP", "CLAMP")
        t:SetBlendMode(spark and "ADD" or "BLEND")
        if spark then t:SetVertexColor(1, 0.7, 0.25) else t:SetVertexColor(0.85, 0.8, 0.75) end
        t:SetAlpha(0)
        if anchor then
            local spec = FX_PARTS[i]
            local size = spec[2] + (spark and 0 or 2)
            t:SetSize(size, size)
            t:ClearAllPoints()
            t:SetPoint("CENTER", ind.barTex, ind.reversed and "BOTTOMLEFT" or "TOPLEFT", spec[1] * fx.width, 0)
        end
    end
end

-- Ice and burning-page extras: a ragged edge, a soft shade under it and a few
-- particles. They are retextured when the style changes. `anchor` re-places
-- the particles (out of combat, from ApplyMode); colors may change any time.
local function StyleFx(ind, anchor)
    local fx = ind.fx
    local mode = ind.mode
    if not fx or not IsFxMode(mode) then return end
    local c = ColorOf(ind)
    if mode == "parchment" then return StyleParchment(ind, fx, c, anchor) end
    local ice = mode == "ice"
    -- vertex color first, then alpha: SetVertexColor resets texture alpha
    fx.edge:SetTexture(MEDIA .. (ice and "ice_edge" or "burn_edge"), "CLAMP", "CLAMP")
    fx.edge:SetBlendMode("ADD")
    if ice then fx.edge:SetVertexColor(IceTint(c, 0.6, 0.40, 0.72, 1.0)) else fx.edge:SetVertexColor(1, 0.55, 0.15) end
    fx.edge:SetAlpha(ice and 0.9 or 1)
    fx.shade:SetTexture(MEDIA .. "sheen", "CLAMP", "CLAMP")
    if ice then
        fx.shade:SetBlendMode("ADD")
        fx.shade:SetVertexColor(IceTint(c, 0.6, 0.25, 0.55, 1.0))
        fx.shade:SetAlpha(0.4)
    else
        fx.shade:SetBlendMode("BLEND")
        fx.shade:SetVertexColor(0, 0, 0)
        fx.shade:SetAlpha(0.55)
    end
    for i = 1, #fx.parts do
        local t = fx.parts[i]
        t:SetTexture(MEDIA .. (ice and "spark" or "ember"), "CLAMP", "CLAMP")
        t:SetBlendMode("ADD")
        if ice then
            t:SetVertexColor(IceTint(c, 0.6, 0.55, 0.82, 1.0))
        else
            -- flame colors: the particles that rise highest are the deepest orange-red
            local f = (i - 1) / math.max(1, #fx.parts - 1)
            t:SetVertexColor(1, 0.85 - 0.5 * f, 0.3 - 0.2 * f)
        end
        t:SetAlpha(0)                              -- driven by its animation only
        if anchor then
            local spec = FX_PARTS[i]
            local size = ice and spec[2] + 3 or spec[2]
            t:SetSize(size, size)
            t:ClearAllPoints()
            t:SetPoint("CENTER", ind.barTex, "TOPLEFT", spec[1] * fx.width, ice and -(3 + (i * 2) % 7) or 0)
        end
    end
end

-- Colors and shows the right texture for the out-of-range mark.
local function ApplyRangeStyle(ind)
    local db = ns.db
    local r, g, b = ns.ParseHexColor(db.rangeColor)
    r, g, b = r or 0.85, g or 0.1, b or 0.1
    if db.rangeStyle == "grey" then
        ind.range:SetColorTexture(0.3, 0.3, 0.3, math.min(1, db.rangeAlpha + 0.2))
    else
        ind.range:SetColorTexture(r, g, b, db.rangeAlpha)
    end
    ind.rangeEdge:SetVertexColor(r, g, b)
    ind.rangeEdge:SetAlpha(math.min(1, ind.rangeEdgeBase * db.rangeAlpha / 0.4))
    local on = ind.rangeOn == true
    ind.range:SetShown(on and db.rangeStyle ~= "border")
    ind.rangeEdge:SetShown(on and db.rangeStyle == "border")
end

-- Colors of the ready flash, edge pulse and ready sweep/double. A custom color
-- (ns.db.fxColors) wins; otherwise the resource color made lighter.
local FX_LIGHT = { flash = 0.2, pulse = 0.3, sweep = 0.3 }
function ns:EffectColor(res, fx)
    local t = self.db and self.db.fxColors
    return t and t[fx .. "_" .. res]
end
-- r, g, b, opacity of an effect for a resource color c
function ns.EffectRGB(res, fx, c)
    local t = ns:EffectColor(res, fx)
    if t then return t.r, t.g, t.b, t.a or 1 end
    local r, g, b = Light(c, FX_LIGHT[fx], FX_LIGHT[fx])
    return r, g, b, 1
end

local function ApplyIndicatorStyle(ind)
    local db = ns.db
    ApplyRangeStyle(ind)
    local c = ColorOf(ind)
    local darkAlpha = ns:ResSettingFor(ind.category, ind.resource, "darkAlpha")
    ind.styledResource = ind.resource or "mana"
    if ind.mode == "parchment" then
        ind.dark:SetColorTexture(0.07, 0.06, 0.06, darkAlpha)   -- charcoal
    else
        ind.dark:SetColorTexture(0, 0, 0, darkAlpha)
    end
    StyleFill(ind)
    local res = ind.resource or "mana"
    local sr, sg, sb, sa = ns.EffectRGB(res, "sweep", c)
    local pr, pg, pb, pa = ns.EffectRGB(res, "pulse", c)
    local fr, fg, fb, fa = ns.EffectRGB(res, "flash", c)
    ind.fxOpacity = { flash = fa, pulse = pa, sweep = sa }
    if ns.Animation.ApplyEffectOpacity then ns.Animation:ApplyEffectOpacity(ind) end
    if ind.sweep then ind.sweep:SetVertexColor(sr, sg, sb) end
    local er, eg, eb = Light(c, 0.45, 0.35)
    ind.edge:SetColorTexture(er, eg, eb, 0.95)
    -- Color only. Never pass an alpha here: on textures it is the same value
    -- as SetAlpha and would make the resting (invisible) flash layers visible.
    ind.edgeGlow:SetVertexColor(pr, pg, pb)
    if ind.mode == "parchment" and not ns:EffectColor(res, "flash") then
        ind.glow:SetVertexColor(1, 0.72, 0.28)        -- golden-orange ready flash
    else
        ind.glow:SetVertexColor(fr, fg, fb)           -- the ready flash
    end

    StyleFx(ind, false)
    local liq = ind.liquid
    if liq then
        -- Vertex color first, then alpha: SetVertexColor resets texture alpha.
        -- Every liquid texture is hidden whenever the liquid is not playing.
        liq.top:SetVertexColor(0, 0, 0)
        liq.top:SetAlpha(darkAlpha)                 -- matches the flat dark layer
        liq.body:SetVertexColor(c.r, c.g, c.b)
        liq.body:SetAlpha(FillAlpha(ind))               -- matches the flat fill layer
        liq.crest:SetVertexColor(Light(c, 0.45, 0.35))
        liq.crest:SetAlpha(1)
        liq.back:SetVertexColor(Light(c, 0.25, 0.25))
        liq.back:SetAlpha(ns.Animation:BackWaveAlpha(ind.category, ind.resource))   -- stronger with livelier waves
        liq.depth:SetVertexColor(c.r * 0.12, c.g * 0.12, c.b * 0.3)
        liq.depth:SetAlpha(0.6)
        liq.sheen:SetVertexColor(Light(c, 0.3, 0.3))
        liq.sheen:SetAlpha(0.35)
        for i = 1, #liq.bubbles do
            liq.bubbles[i]:SetVertexColor(Light(c, 0.5, 0.4))
            liq.bubbles[i]:SetAlpha(0)                 -- driven by its animation only
        end
    end
end

local function SetOverlayShown(ind, shown)
    -- "out-of-resource indicator" off for this bar category: nothing is drawn,
    -- but ManaRise still tracks the state so the ready flash keeps working
    if shown and ind.category and ns:CatGet(ind.category, "overlay") == false then shown = false end
    ind.overlayVisible = shown
    ind.dark:SetShown(shown)
    ind.fill:SetShown(shown)
    local liquid = shown and ind.mode == "liquid"
    local fxStyle = shown and IsFxMode(ind.mode)
    ind.edge:SetShown(shown and not liquid and not fxStyle)
    if liquid then
        ns.Animation:StartLiquid(ind)
    elseif ind.liquid then
        ns.Animation:StopLiquid(ind)
    end
    if fxStyle then
        ns.Animation:StartFx(ind)
    elseif ind.fx then
        ns.Animation:StopFx(ind)
    end
end

-- Burning parchment fills from the top down (the burn line travels down the
-- icon as the resource rises). Other styles, and clients whose status bars
-- cannot reverse their fill, keep filling upward.
local function WantsReverse(ind, mode)
    return mode == "parchment" and ind.bar.SetReverseFill ~= nil
end

-- Flat dark/fill meet at the fill line. In liquid mode they stop WAVE_HALF
-- short of it and the wave band draws the surface in between.
local function AnchorBase(ind, mode)
    local liquid = mode == "liquid"
    local parch = mode == "parchment"
    local off = parch and WAVE_HALF or (liquid and (Geometry(ind)) or 0)
    local barTex = ind.barTex
    local fx = ind.fx
    local rev = ind.reversed
    if rev then
        -- the fill grows down from the top: barTex's BOTTOM edge is the burn line
        for _, t in ipairs({ fx.edge, fx.ptop, fx.pbody }) do t:ClearAllPoints() end
        for _, t in ipairs({ fx.edge, fx.ptop, fx.pbody }) do
            t:SetPoint("TOPLEFT", barTex, "BOTTOMLEFT", 0, WAVE_HALF)
            t:SetPoint("BOTTOMRIGHT", barTex, "BOTTOMRIGHT", 0, -WAVE_HALF)
            t:SetTexCoord(0, 1, 1, 0)
        end
        fx.shade:ClearAllPoints()
        fx.shade:SetPoint("BOTTOMLEFT", barTex, "BOTTOMLEFT")
        fx.shade:SetPoint("BOTTOMRIGHT", barTex, "BOTTOMRIGHT")
        fx.shade:SetTexCoord(0, 1, 1, 0)
        ind.dark:ClearAllPoints()
        ind.fill:ClearAllPoints()
        ind.edge:ClearAllPoints()
        ind.edgeGlow:ClearAllPoints()
        ind.fill:SetPoint("TOPLEFT", ind.icon, "TOPLEFT")
        ind.fill:SetPoint("BOTTOMRIGHT", barTex, "BOTTOMRIGHT", 0, off)
        ind.dark:SetPoint("TOPLEFT", barTex, "BOTTOMLEFT", 0, -off)
        ind.dark:SetPoint("BOTTOMRIGHT", ind.icon, "BOTTOMRIGHT")
        ind.edge:SetPoint("BOTTOMLEFT", barTex, "BOTTOMLEFT")
        ind.edge:SetPoint("BOTTOMRIGHT", barTex, "BOTTOMRIGHT")
        ind.edgeGlow:SetPoint("LEFT", barTex, "BOTTOMLEFT")
        ind.edgeGlow:SetPoint("RIGHT", barTex, "BOTTOMRIGHT")
        return
    end
    if fx then
        for _, t in ipairs({ fx.edge, fx.ptop, fx.pbody, fx.shade }) do t:SetTexCoord(0, 1, 0, 1) end
        fx.shade:ClearAllPoints()
        fx.shade:SetPoint("TOPLEFT", barTex, "TOPLEFT")
        fx.shade:SetPoint("TOPRIGHT", barTex, "TOPRIGHT")
        -- the fx edge is a thin strip normally; parchment's jagged burn line
        -- uses the same band as its top and body layers
        local bands = { fx.edge }
        if parch then bands = { fx.edge, fx.ptop, fx.pbody } end
        for _, t in ipairs({ fx.edge, fx.ptop, fx.pbody }) do t:ClearAllPoints() end
        if parch then
            for _, t in ipairs(bands) do
                t:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, WAVE_HALF)
                t:SetPoint("BOTTOMRIGHT", barTex, "TOPRIGHT", 0, -WAVE_HALF)
            end
        else
            fx.edge:SetPoint("BOTTOMLEFT", barTex, "TOPLEFT", 0, -2)
            fx.edge:SetPoint("TOPRIGHT", barTex, "TOPRIGHT", 0, 8)
        end
    end
    ind.dark:ClearAllPoints()
    ind.fill:ClearAllPoints()
    ind.edge:ClearAllPoints()
    ind.edgeGlow:ClearAllPoints()
    ind.dark:SetPoint("TOPLEFT", ind.icon, "TOPLEFT")
    ind.dark:SetPoint("BOTTOMRIGHT", barTex, "TOPRIGHT", 0, off)
    ind.fill:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, -off)
    ind.fill:SetPoint("BOTTOMRIGHT", ind.icon, "BOTTOMRIGHT")
    ind.edge:SetPoint("TOPLEFT", barTex, "TOPLEFT")
    ind.edge:SetPoint("TOPRIGHT", barTex, "TOPRIGHT")
    ind.edgeGlow:SetPoint("LEFT", barTex, "TOPLEFT")
    ind.edgeGlow:SetPoint("RIGHT", barTex, "TOPRIGHT")
end

local function DesiredMode(ind)
    local style = ns:StyleFor(ind.category, ind.resource)
    if style == "liquid" and ind.liquid then return "liquid" end
    if IsFxMode(style) and ind.fx then return style end
    return "flat"
end

-- Returns false if the change has to wait until combat ends (re-anchoring is
-- kept out of combat, like frame creation).
local function ApplyWaveGeometry(ind)
    local liq = ind.liquid
    if not liq then return end
    local half, trough, raise = Geometry(ind)
    liq.waveHalf = half
    liq.raise[liq.back] = raise
    ns.Animation:AnchorLiquidBands(liq)
    liq.depth:ClearAllPoints()
    liq.depth:SetPoint("TOPLEFT", liq.barTex, "TOPLEFT", 0, -half)
    liq.depth:SetPoint("BOTTOMRIGHT", ind.icon, "BOTTOMRIGHT")
    liq.sheen:ClearAllPoints()
    liq.sheen:SetPoint("TOPLEFT", liq.barTex, "TOPLEFT", 0, -trough)
    liq.sheen:SetPoint("TOPRIGHT", liq.barTex, "TOPRIGHT", 0, -trough)
    if liq.mask then
        liq.mask:ClearAllPoints()
        liq.mask:SetPoint("TOPLEFT", liq.barTex, "TOPLEFT", 0, -trough)
        liq.mask:SetPoint("BOTTOMRIGHT", ind.icon, "BOTTOMRIGHT")
    end
    ind.waveScale = ns.Animation:WaveScale(ind.category, ind.resource)
end

local function ApplyMode(ind)
    local mode = DesiredMode(ind)
    if ind.mode == mode and (mode ~= "liquid" or ind.waveScale == ns.Animation:WaveScale(ind.category, ind.resource)) then
        return true
    end
    if ind.mode ~= nil and ns:InCombat() then return false end
    ind.reversed = WantsReverse(ind, mode)
    if ind.bar.SetReverseFill then ind.bar:SetReverseFill(ind.reversed) end
    AnchorBase(ind, mode)
    if mode == "liquid" then ApplyWaveGeometry(ind) end
    ind.mode = mode
    StyleFill(ind)
    StyleFx(ind, true)
    ApplyIndicatorStyle(ind)
    if ind.overlayVisible then SetOverlayShown(ind, true) end
    return true
end

local function CreateLiquid(ind, button, icon, barTex)
    local liq = { bubbles = {} }
    local failed = false

    local function Tex(sub, file, blend, wrapH)
        local t = button:CreateTexture(nil, "ARTWORK", nil, sub)
        if t:SetTexture(MEDIA .. file, wrapH or "CLAMP", "CLAMP") == false then
            failed = failed or file
        end
        t:SetBlendMode(blend)
        t:Hide()
        liq.all = liq.all or {}
        liq.all[#liq.all + 1] = t
        return t
    end
    liq.raise = {}
    local function Band(t, raise)
        liq.raise[t] = raise
        t:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, WAVE_HALF + raise)
        t:SetPoint("BOTTOMRIGHT", barTex, "TOPRIGHT", 0, -WAVE_HALF + raise)
    end

    -- depth: darker toward the bottom of the liquid
    liq.depth = Tex(4, "gradient", "BLEND")
    liq.depth:SetTexCoord(0, 1, 1, 0)
    liq.depth:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, -WAVE_HALF)
    liq.depth:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")

    -- back wave (additive, dimmed by the front surface drawn over it)
    liq.back = Tex(5, "wave_back", "ADD", "REPEAT")
    Band(liq.back, BACK_RAISE)

    -- front surface: dark above the curve, liquid below, crest on the curve
    liq.top = Tex(6, "wave_top", "BLEND", "REPEAT")
    Band(liq.top, 0)
    liq.body = Tex(6, "wave_fill", "BLEND", "REPEAT")
    Band(liq.body, 0)
    liq.crest = Tex(7, "wave_crest", "ADD", "REPEAT")
    Band(liq.crest, 0)

    -- sheen: soft glow just under the surface (soft at both ends, and below
    -- the wave troughs, so it never draws a straight line above the liquid)
    liq.sheen = Tex(7, "sheen", "ADD")
    liq.sheen:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, -TROUGH)
    liq.sheen:SetPoint("TOPRIGHT", barTex, "TOPRIGHT", 0, -TROUGH)
    liq.sheen:SetHeight(SHEEN_HEIGHT)

    -- bubbles, clipped to the liquid by a mask that ends below the wave troughs
    local width = icon.GetWidth and icon:GetWidth() or 0
    local height = icon.GetHeight and icon:GetHeight() or 0
    if type(width) ~= "number" or width <= 0 then width = 36 end
    if type(height) ~= "number" or height <= 0 then height = 36 end
    liq.height = height
    liq.width = width
    liq.barTex = barTex
    liq.waveHalf = (Geometry())
    liq.clipped = true             -- every layer is clipped to the icon (ApplyMasks)

    local liquidMask = button.CreateMaskTexture and button:CreateMaskTexture(nil, "ARTWORK")
    if liquidMask then
        liquidMask:SetTexture(WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        liquidMask:SetPoint("TOPLEFT", barTex, "TOPLEFT", 0, -TROUGH)
        liquidMask:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
        liq.mask = liquidMask
        for i = 1, #BUBBLES do
            local b = Tex(5, "bubble", "ADD")
            b:AddMaskTexture(liquidMask)
            b:SetSize(BUBBLES[i][2], BUBBLES[i][2])
            b:SetPoint("BOTTOM", icon, "BOTTOM", BUBBLES[i][1] * width, 1)
            liq.bubbles[i] = b
        end
    end

    if not liquidMask then
        AB.liquidProblem = L.PROBLEM_NO_MASK
        ns:LogError("liquid", "no mask texture support")
        return nil
    end
    if failed then
        AB.liquidProblem = string.format(L.PROBLEM_TEXTURE, failed)
        ns:LogError("liquid", "texture failed to load: " .. tostring(failed))
        return nil
    end
    return liq
end

-- Layers for the ice and burning-page styles. Returns nil (those styles then
-- fall back to flat) if a texture file does not load.
local function CreateFx(ind, button, icon, barTex)
    local fx = { parts = {}, all = {} }
    local failed
    local function Probe(t, file)
        if t:SetTexture(MEDIA .. file, "CLAMP", "CLAMP") == false then failed = failed or file end
    end
    local function Tex(sub)
        local t = button:CreateTexture(nil, "ARTWORK", nil, sub)
        t:Hide()
        fx.all[#fx.all + 1] = t
        return t
    end
    Probe(ind.fill, "ice_fill")
    Probe(ind.fill, "burn_fill")
    Probe(ind.fill, "parch_fill")

    fx.ptop = Tex(5)
    Probe(fx.ptop, "parch_top")
    fx.pbody = Tex(5)
    Probe(fx.pbody, "parch_body")

    fx.shade = Tex(5)
    fx.shade:SetPoint("TOPLEFT", barTex, "TOPLEFT")
    fx.shade:SetPoint("TOPRIGHT", barTex, "TOPRIGHT")
    fx.shade:SetHeight(10)
    Probe(fx.shade, "sheen")

    fx.edge = Tex(6)
    fx.edge:SetPoint("BOTTOMLEFT", barTex, "TOPLEFT", 0, -2)
    fx.edge:SetPoint("TOPRIGHT", barTex, "TOPRIGHT", 0, 8)
    Probe(fx.edge, "ice_edge")
    Probe(fx.edge, "burn_edge")
    Probe(fx.edge, "parch_edge")

    local width = icon.GetWidth and icon:GetWidth() or 0
    local height = icon.GetHeight and icon:GetHeight() or 0
    if type(width) ~= "number" or width <= 0 then width = 36 end
    if type(height) ~= "number" or height <= 0 then height = 36 end
    fx.width, fx.height = width, height
    for i = 1, #FX_PARTS do
        fx.parts[i] = Tex(7)
        Probe(fx.parts[i], "spark")
        Probe(fx.parts[i], "bubble")
        Probe(fx.parts[i], "ember")
        Probe(fx.parts[i], "ash")
    end
    if failed then
        AB.fxProblem = string.format(L.PROBLEM_TEXTURE, failed)
        ns:LogError("style", "texture failed to load: " .. tostring(failed))
        for _, t in ipairs(fx.all) do t:Hide() end
        return nil
    end
    return fx
end

-- The masks the icon is drawn with right now. A hidden mask does not clip
-- (that is how ElvUI turns the rounded IconMask off), so it is skipped.
local function Shown(m)
    return type(m.IsShown) ~= "function" or m:IsShown()
end

local function IconMasks(button, icon)
    local masks = {}
    if type(icon.GetNumMaskTextures) == "function" and type(icon.GetMaskTexture) == "function" then
        for i = 1, icon:GetNumMaskTextures() or 0 do
            local m = icon:GetMaskTexture(i)
            if m and Shown(m) then masks[#masks + 1] = m end
        end
    else
        -- client can't list an icon's masks: use the template's IconMask
        local m = button.IconMask
        if type(m) == "table" and Shown(m) then masks[1] = m end
    end
    return masks
end

-- What our layers should be clipped by: the icon's own masks, or (square
-- skins) a square mask of ours covering exactly the icon, so the wave band
-- never draws over the skin's border. Out of combat only (may create it).
local function WantedMasks(ind)
    local masks = IconMasks(ind.button, ind.icon)
    if #masks == 0 and ind.button.CreateMaskTexture then
        if not ind.squareMask then
            local m = ind.button:CreateMaskTexture(nil, "ARTWORK")
            m:SetTexture(WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            m:SetAllPoints(ind.icon)
            ind.squareMask = m
        end
        masks[1] = ind.squareMask
    end
    return masks
end

local function SameMasks(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

local function ApplyMasks(ind, masks)
    local old = ind.masks or {}
    for _, t in ipairs(ind.clip) do
        if t.RemoveMaskTexture then
            for i = 1, #old do t:RemoveMaskTexture(old[i]) end
        end
        for i = 1, #masks do t:AddMaskTexture(masks[i]) end
    end
    ind.masks = masks
    ind.square = masks[1] ~= nil and masks[1] == ind.squareMask
end

-- Re-check the clip masks when a skin may have changed (out of combat).
function AB:SyncMasks(ind)
    if ns:InCombat() then return end
    local masks = WantedMasks(ind)
    if not SameMasks(masks, ind.masks or {}) then ApplyMasks(ind, masks) end
end

local function CreateIndicator(button, source, getSlot)
    local icon = button.icon or button.Icon
    local ind = { button = button, icon = icon, shown = false, source = source, getSlot = getSlot,
        category = AB.Classify(button, source) }

    -- Geometry-only StatusBar. Alpha 0: it is never drawn, the engine just
    -- sizes its fill texture for us.
    local bar = CreateFrame("StatusBar", nil, button)
    bar:SetAllPoints(icon)
    bar:SetOrientation("VERTICAL")
    bar:SetStatusBarTexture(WHITE)
    bar:SetMinMaxValues(-ZERO_EPS, 1)
    bar:SetValue(0)
    bar:SetAlpha(0)
    bar:EnableMouse(false)
    ind.bar = bar
    local barTex = bar:GetStatusBarTexture()
    ind.barTex = barTex

    -- dark and fill are anchored by AnchorBase (depends on the style)
    local dark = button:CreateTexture(nil, "ARTWORK", nil, 2)
    ind.dark = dark

    local fill = button:CreateTexture(nil, "ARTWORK", nil, 3)
    ind.fill = fill

    local edge = button:CreateTexture(nil, "ARTWORK", nil, 4)
    edge:SetPoint("TOPLEFT", barTex, "TOPLEFT")
    edge:SetPoint("TOPRIGHT", barTex, "TOPRIGHT")
    edge:SetHeight(1)
    edge:SetBlendMode("ADD")
    ind.edge = edge

    local edgeGlow = button:CreateTexture(nil, "ARTWORK", nil, 7)
    edgeGlow:SetTexture(WHITE)
    edgeGlow:SetBlendMode("ADD")
    edgeGlow:SetPoint("LEFT", barTex, "TOPLEFT")
    edgeGlow:SetPoint("RIGHT", barTex, "TOPRIGHT")
    edgeGlow:SetHeight(4)
    edgeGlow:SetAlpha(0)
    edgeGlow:Hide()
    ind.edgeGlow = edgeGlow

    local glow = button:CreateTexture(nil, "OVERLAY", nil, 2)
    if ns.api.GetAtlasInfo and ns.api.GetAtlasInfo(GLOW_ATLAS) then
        glow:SetAtlas(GLOW_ATLAS)
    else
        glow:SetTexture(WHITE)
    end
    glow:SetBlendMode("ADD")
    glow:SetAllPoints(button)
    glow:SetAlpha(0)
    glow:Hide()
    ind.glow = glow

    -- ready sweep: a soft band that rises through the icon (hidden at rest)
    local sweep = button:CreateTexture(nil, "ARTWORK", nil, 7)
    sweep:SetTexture(MEDIA .. "sheen", "CLAMP", "CLAMP")
    sweep:SetBlendMode("ADD")
    sweep:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT")
    sweep:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    sweep:SetHeight(14)
    sweep:SetAlpha(0)
    sweep:Hide()
    ind.sweep = sweep

    -- out-of-range tint (signal, hidden unless the spell is out of range)
    local range = button:CreateTexture(nil, "OVERLAY", nil, 1)
    range:SetAllPoints(icon)
    range:SetColorTexture(0.85, 0.1, 0.1, 0.4)
    range:Hide()
    ind.range = range

    -- the "border" look of the out-of-range mark
    local rangeEdge = button:CreateTexture(nil, "OVERLAY", nil, 3)
    local edgeAlpha = 1
    if ns.api.GetAtlasInfo and ns.api.GetAtlasInfo(GLOW_ATLAS) then
        rangeEdge:SetAtlas(GLOW_ATLAS)
    else
        rangeEdge:SetTexture(WHITE)
        edgeAlpha = 0.3
    end
    rangeEdge:SetBlendMode("ADD")
    rangeEdge:SetAllPoints(button)
    rangeEdge:Hide()
    ind.rangeEdge = rangeEdge
    ind.rangeEdgeBase = edgeAlpha

    ind.clip = { dark, fill, edge, edgeGlow, sweep, range }
    local liquid = CreateLiquid(ind, button, icon, barTex)
    if liquid then
        for _, t in ipairs(liquid.all or {}) do ind.clip[#ind.clip + 1] = t end
    end
    local fx = CreateFx(ind, button, icon, barTex)
    if fx then
        for _, t in ipairs(fx.all) do ind.clip[#ind.clip + 1] = t end
    end
    ApplyMasks(ind, WantedMasks(ind))

    if fx then
        local ok, err = ns.Animation:SetupFx(fx, #list + 1)
        if ok then
            ind.fx = fx
        else
            AB.fxProblem = string.format(L.PROBLEM_ANIMATIONS, tostring(err))
            ns:LogError("style", err)
            for _, t in ipairs(fx.all) do t:Hide() end
        end
    end

    if liquid then
        local ok, err = ns.Animation:SetupLiquid(liquid, #list + 1)
        if ok then
            ind.liquid = liquid
        else
            AB.liquidProblem = string.format(L.PROBLEM_ANIMATIONS, tostring(err))
            ns:LogError("liquid", err)
            for _, t in ipairs(liquid.all or {}) do t:Hide() end
        end
    end

    ApplyIndicatorStyle(ind)
    ApplyMode(ind)
    SetOverlayShown(ind, false)
    ns.Animation:SetupIndicator(ind)
    return ind
end

---------------------------------------------------------------------------
-- Options-panel preview. A few sample buttons of our own (never Blizzard's or
-- another addon's) get the same overlay as real buttons, built by the same
-- CreateIndicator, and are driven by a made-up resource. They are not in
-- `list`, so nothing else ever touches them; ApplyStyle restyles them. Frames
-- are created once, out of combat. The cycle runs on the shared driver and
-- only while the panel shows the preview.
---------------------------------------------------------------------------
local previews = {}
local PREVIEW_SPECS = {
    { "mana", "Interface\\Icons\\Spell_Frost_FrostBolt02", 0 },
    { "rage", "Interface\\Icons\\Ability_Warrior_Rampage", 0.3 },
    { "energy", "Interface\\Icons\\Ability_Rogue_Eviscerate", 0.6 },
    { "focus", "Interface\\Icons\\Ability_Hunter_SteadyShot", 0.85 },
}
local PREVIEW_SIZE, PREVIEW_GAP = 36, 6
local PREVIEW_PERIOD, PREVIEW_HOLD = 6, 1.2
local previewRunning = false

AB.PREVIEW_WIDTH = #PREVIEW_SPECS * PREVIEW_SIZE + (#PREVIEW_SPECS - 1) * PREVIEW_GAP
AB.PREVIEW_HEIGHT = PREVIEW_SIZE

-- Builds the sample buttons inside `parent`. Returns the number built, or nil
-- if it has to wait (combat) or the client rejected them.
function AB:CreatePreview(parent)
    if #previews > 0 then return #previews end
    if ns:InCombat() then return nil end
    for i, spec in ipairs(PREVIEW_SPECS) do
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(PREVIEW_SIZE, PREVIEW_SIZE)
        b:SetPoint("LEFT", parent, "LEFT", (i - 1) * (PREVIEW_SIZE + PREVIEW_GAP), 0)
        b:EnableMouse(false)
        b.icon = b:CreateTexture(nil, "BACKGROUND")
        b.icon:SetSize(PREVIEW_SIZE, PREVIEW_SIZE)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexture(spec[2])
        local ok, ind = pcall(CreateIndicator, b, "preview", nil)
        if not ok then
            ns:LogError("preview", ind)
            return nil
        end
        ind.category = nil          -- previews show the global look
        ind.resource = spec[1]
        ind.pv = { t = spec[3] * PREVIEW_PERIOD, hold = 0 }
        ApplyIndicatorStyle(ind)
        ApplyMode(ind)
        previews[#previews + 1] = ind
    end
    return #previews
end

local function PreviewTick(dt)
    for i = 1, #previews do
        local ind, pv = previews[i], previews[i].pv
        if pv.hold > 0 then
            pv.hold = pv.hold - dt
            if pv.hold <= 0 then
                pv.t = 0
                ind.bar:SetValue(0)
                SetOverlayShown(ind, true)
            end
        else
            pv.t = pv.t + dt
            if pv.t >= PREVIEW_PERIOD then
                SetOverlayShown(ind, false)       -- ready: clear and flash
                pv.hold = PREVIEW_HOLD
                if ns:CatGet(ind.category, "glow") then ns.Animation:PlayGlow(ind) end
            else
                ind.bar:SetValue(pv.t / PREVIEW_PERIOD)
            end
        end
    end
    return previewRunning
end

function AB:SetPreviewRunning(on)
    on = on and #previews > 0 or false
    if on == previewRunning then return end
    previewRunning = on
    if on then
        for i = 1, #previews do
            local ind = previews[i]
            ApplyIndicatorStyle(ind)
            ApplyMode(ind)
            ns.Animation:ApplyLiquidSettings(ind)
            ns.Animation:ApplyFxSettings(ind)
            ind.pv.hold = 0
            ind.bar:SetValue(ind.pv.t / PREVIEW_PERIOD)
            SetOverlayShown(ind, true)
        end
        ns.Animation:AddTicker("preview", PreviewTick)
    else
        ns.Animation:RemoveTicker("preview")
        for i = 1, #previews do
            local ind = previews[i]
            SetOverlayShown(ind, false)
            for _, g in ipairs({ ind.glowAnim, ind.doubleAnim, ind.sweepAnim, ind.pulseAnim }) do g:Stop() end
        end
    end
end

-- The global animation shutdown (Enable toggled off) also stops the preview's
-- ticker and effects. While the preview is still wanted, bring it back.
function AB:ResumePreview()
    if not previewRunning then return end
    for i = 1, #previews do
        local ind = previews[i]
        if ind.pv.hold <= 0 then SetOverlayShown(ind, true) end
    end
    ns.Animation:AddTicker("preview", PreviewTick)
end

function AB:PreviewIndicators() return previews end

function AB:PreviewInfo()
    return #previews, previewRunning
end

---------------------------------------------------------------------------
-- Discovery
---------------------------------------------------------------------------
local function IsCandidate(button)
    if type(button) ~= "table" or type(button.GetObjectType) ~= "function" then
        return false
    end
    if button:GetObjectType() ~= "CheckButton" then return false end
    local icon = button.icon
    if type(icon) ~= "table" or type(icon.GetObjectType) ~= "function" then return false end
    return icon:GetObjectType() == "Texture"
end

-- Gamepad bar frames hold dozens of placeholder buttons with no real action
-- slot; they are never shown, so ManaRise leaves them alone.
local SKIP_PREFIXES = { "GamepadMainActionBarFramePage", "GamepadActionBarEditFramePage" }
local gamepadSeen = {}      -- [button] = true (ManaRise's own table)
AB.gamepadSkipped = 0

-- Which bar category a button belongs to (for the per-category settings).
-- Buttons of a bar addon are "other"; Blizzard's own are told apart by name.
function AB.Classify(button, source)
    if source == CDM_SOURCE then return "cooldown" end
    if source then return "other" end
    local name = button.GetName and button:GetName()
    if type(name) == "string" then
        if string.sub(name, 1, 12) == "ActionButton" then return "main" end
        if string.sub(name, 1, 8) == "MultiBar" then return "additional" end
        if string.sub(name, 1, 12) == "StanceButton" then return "stance" end
    end
    return "other"
end

local function IsGamepadButton(button)
    local name = button.GetName and button:GetName()
    if type(name) ~= "string" then return false end
    for i = 1, #SKIP_PREFIXES do
        local p = SKIP_PREFIXES[i]
        if string.sub(name, 1, #p) == p then return true end
    end
    return false
end

-- source: the bar addon that owns the button (nil for the default bars).
-- getSlot: how to read its action slot (nil: the .action field/attribute).
local function IsCdmItem(item)
    if type(item) ~= "table" or type(item.GetObjectType) ~= "function" then return false end
    local icon = item.Icon
    return type(icon) == "table" and type(icon.GetObjectType) == "function"
        and icon:GetObjectType() == "Texture"
end

local function Track(button, source, getSlot, isCdm)
    local ind = indicators[button]
    if ind then
        -- e.g. Dominos reuses Blizzard's buttons: credit the addon that owns it
        if source and not ind.source then
            ind.source, ind.getSlot = source, getSlot
            ind.category = AB.Classify(button, source)
        end
        return
    end
    if isCdm then
        if not IsCdmItem(button) then return end
    elseif not IsCandidate(button) then
        return
    end
    if not source and IsGamepadButton(button) then
        if not gamepadSeen[button] then
            gamepadSeen[button] = true
            AB.gamepadSkipped = AB.gamepadSkipped + 1
        end
        return
    end
    ind = CreateIndicator(button, source, getSlot)
    ind.isCDM = isCdm and true or nil
    indicators[button] = ind
    list[#list + 1] = ind
end

-- Cooldown Manager: icons are pooled, so the viewers tell us when icons are
-- laid out again (RefreshLayout) or given other spells (RefreshData). Both
-- hooks only schedule work for the next frame; nothing is changed on the
-- viewer. hooksecurefunc re-sets the viewer's own method names, no new keys.
local function HookViewer(viewer, name)
    if type(_G.hooksecurefunc) ~= "function" then return end
    local ok = true
    if type(viewer.RefreshLayout) == "function" then
        ok = pcall(hooksecurefunc, viewer, "RefreshLayout", function()
            if ns.db and ns.db.enabled then ns:Schedule("discover") end
        end) and ok
    end
    if type(viewer.RefreshData) == "function" then
        ok = pcall(hooksecurefunc, viewer, "RefreshData", function()
            if ns.db and ns.db.enabled then ns:Schedule("slots") end
        end) and ok
    end
    cdmHooked[name] = ok or nil
end

function AB:DiscoverCooldownManager()
    local found = 0
    for i = 1, #CDM_VIEWERS do
        local name = CDM_VIEWERS[i]
        local viewer = _G[name]
        if type(viewer) == "table" and type(viewer.GetObjectType) == "function" then
            found = found + 1
            if not cdmHooked[name] then HookViewer(viewer, name) end
            if type(viewer.GetItemFrames) == "function" then
                local ok, frames = pcall(viewer.GetItemFrames, viewer)
                if ok and type(frames) == "table" then
                    for _, item in pairs(frames) do Track(item, CDM_SOURCE, nil, true) end
                end
            end
        end
    end
    self.cdmViewers = found
end

function AB:Discover()
    -- Creating child frames/textures on secure buttons is done out of combat.
    if ns:InCombat() then
        self.discoverAfterCombat = true
        ns:Debug(L.DBG_DEFERRED)
        return
    end
    self.discoverAfterCombat = false
    local before = #list

    -- 0) Bartender4 / Dominos / ElvUI buttons, when one of them is loaded.
    if ns.BarAddons then ns.BarAddons:EachButton(Track) end

    -- 1) Blizzard's own registry of action-bar buttons, when present.
    local registry = ActionBarButtonEventsFrame
    if registry and type(registry.frames) == "table" then
        for _, button in pairs(registry.frames) do Track(button) end
    end

    -- 2) Each known bar's actionButtons array.
    for i = 1, #BAR_FRAMES do
        local bar = _G[BAR_FRAMES[i]]
        if type(bar) == "table" and type(bar.actionButtons) == "table" then
            for _, button in pairs(bar.actionButtons) do Track(button) end
        end
    end

    -- 2b) Stance / form buttons (StanceButton1..10; Bartender4 and Dominos
    -- reuse the same global names for their stance bars).
    for n = 1, 10 do
        local button = _G["StanceButton" .. n]
        if button then
            Track(button)
            local ind = indicators[button]
            if ind and not ind.getSlot then ind.isForm = true; ind.category = "stance" end
        end
    end

    -- 2c) Cooldown Manager icons
    self:DiscoverCooldownManager()

    -- 3) Conventional global names as a last resort.
    for i = 1, #NAMED_BUTTONS do
        local prefix = NAMED_BUTTONS[i]
        for n = 1, 12 do
            local button = _G[prefix .. n]
            if button then Track(button) end
        end
    end

    -- Skins can change after a button was first seen (e.g. a bar addon
    -- styles its buttons after creating them): keep the clip masks current.
    for i = 1, before do self:SyncMasks(list[i]) end

    if #list ~= before then
        ns:Debug(L.DBG_TRACKING, #list, #list - before)
    end
end

-- Tracked buttons per bar addon: { Bartender4 = 36, default = 24 }.
function AB:SourceCounts()
    local counts = {}
    for i = 1, #list do
        local key = list[i].source or "default"
        counts[key] = (counts[key] or 0) + 1
    end
    return counts
end

---------------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------------
local function ButtonLabel(ind)
    local name = ind.isCDM and CDM_SOURCE or (ind.button.GetName and ind.button:GetName() or "button")
    local spell = ""
    if ind.spellID and ns.api.GetSpellName then
        local s = ns.api.GetSpellName(ind.spellID)
        if type(s) == "string" and not IsSecret(s) then spell = " " .. s end
    end
    return string.format(L.BUTTON_LABEL, name or "button", tostring(ind.slot or "-"), spell)
end

-- Reason texts are the locale keys "REASON_<reason>"; %s is replaced by the
-- button's resource (mana, rage, energy, focus).
AB.REASONS = {
    "showing", "showing-secret", "ready", "empty-slot", "no-slot", "not-a-spell",
    "secret-action", "no-resource-cost", "no-mana-cost", "no-tracked-cost", "zero-cost",
    "cost-aura-inactive", "secret-cost", "secret-usability", "no-value", "no-pool",
    "dead", "disabled", "simulation", "active-form", "category-off",
}
local REASON_KEYS = {}
for _, r in ipairs(AB.REASONS) do REASON_KEYS[r] = "REASON_" .. r end

local function ReasonText(ind, reason)
    local key = REASON_KEYS[reason]
    if not key then return tostring(reason) end
    return string.format(L[key], ns.ResourceName(ind.resource))
end
AB.ReasonText = ReasonText

local function SetReason(ind, reason)
    if ind.reason ~= reason then
        ind.reason = reason
        if ns.db.debug and reason ~= "ready" and reason ~= "showing" and reason ~= "showing-secret"
           and reason ~= "empty-slot" and reason ~= "not-a-spell" then
            ns:Debug("%s: %s", ButtonLabel(ind), ReasonText(ind, reason))
        end
    end
end

function AB:ResetReasons()
    for i = 1, #list do list[i].reason = nil end
end

function AB:PrintScan()
    ns:Print(L.SCAN_HEADER, #list, ns.BarAddons and ns.BarAddons:Summary() or L.BAR_NONE)
    for i = 1, #list do
        local ind = list[i]
        if ind.reason ~= "empty-slot" then
            ns:Print(L.SCAN_LINE, ButtonLabel(ind),
                ind.cost and (ind.cost .. " " .. ns.ResourceName(ind.resource)) or "-", ReasonText(ind, ind.reason))
        end
    end
end

-- Liquid status for /mr status and the login check: how many buttons have the
-- liquid layers, how many tracked buttons there are, and why any don't.
function AB:LiquidInfo()
    local built = 0
    for i = 1, #list do
        if list[i].liquid then built = built + 1 end
    end
    return built, #list, self.liquidProblem
end

-- For /mr status: how many Cooldown Manager icons are tracked, or nil when the
-- client has no viewer.
function AB:CooldownManagerInfo()
    if self.cdmViewers == 0 then return nil end
    return self:SourceCounts()[CDM_SOURCE] or 0, self.cdmViewers
end

function AB:Counts()
    local withCost, showing = 0, 0
    for i = 1, #list do
        if list[i].cost then withCost = withCost + 1 end
        if list[i].shown then showing = showing + 1 end
    end
    return #list, withCost, showing
end

---------------------------------------------------------------------------
-- Slot -> spell -> cost
---------------------------------------------------------------------------
-- The action slot a button shows right now. Bar addons may supply their own
-- reader (LibActionButton: button:GetAction()); otherwise the button's
-- .action field or "action" attribute, as on the default bars.
local function GetSlot(ind)
    if ind.getSlot then return ind.getSlot(ind.button) end
    local button = ind.button
    local action = button.action
    if type(action) ~= "number" and button.GetAttribute then
        action = button:GetAttribute("action")
    end
    if type(action) == "number" and action > 0 then
        return action
    end
    return nil, "no-slot"
end
AB.GetSlot = GetSlot

-- Stance / shapeshift buttons (Warrior stances, Druid forms...) have no
-- action slot. The form's own spell comes from GetShapeshiftFormInfo. The
-- active form is left alone so Blizzard's checked-button look stays clear.
local function FormSpell(button)
    if type(_G.GetShapeshiftFormInfo) ~= "function" then return nil, "no-slot" end
    local index = button.GetID and button:GetID()
    if type(index) ~= "number" or index < 1 then index = button.index end
    if type(index) ~= "number" or index < 1 then return nil, "no-slot" end
    local _, active, _, spellID = _G.GetShapeshiftFormInfo(index)
    if IsSecret(active) or IsSecret(spellID) then return nil, "secret-action" end
    if type(spellID) ~= "number" then return nil, "empty-slot" end
    if active then return nil, "active-form" end
    return spellID
end
AB.FormSpell = FormSpell

-- A Cooldown Manager icon: the spell it shows right now (its own GetSpellID
-- follows overrides and procs). Read-only; errors and secrets count as "no spell".
local function CdmSpell(item)
    if type(item.GetSpellID) ~= "function" then return nil, "no-slot" end
    local ok, id = pcall(item.GetSpellID, item)
    if not ok then return nil, "no-slot" end
    if IsSecret(id) then return nil, "secret-action" end
    if type(id) ~= "number" or id <= 0 then return nil, "empty-slot" end
    return id
end

local function ResolveSpell(ind)
    if ind.isCDM then
        ind.slot = nil
        return CdmSpell(ind.button)
    end
    if ind.isForm then
        ind.slot = nil
        return FormSpell(ind.button)
    end
    local slot, why = GetSlot(ind)
    ind.slot = slot
    if not slot then return nil, why or "no-slot" end

    local has = ns.api.HasAction(slot)
    if IsSecret(has) then return nil, "secret-action" end
    if not has then return nil, "empty-slot" end

    local actionType, id, subType = ns.api.GetActionInfo(slot)
    if IsSecret(actionType) or IsSecret(id) or IsSecret(subType) then
        return nil, "secret-action"
    end
    if actionType == "spell" and type(id) == "number" then
        return id, nil
    end
    if actionType == "macro" and subType == "spell" and type(id) == "number" then
        return id, nil
    end
    return nil, "not-a-spell"
end

local function ResolveCost(ind)
    local cost, resource, reason
    if ind.spellID then
        cost, resource, reason = ns.Mana:GetRequiredCost(ind.spellID)
        ind.costReason = reason
    end
    ind.cost = cost
    if resource ~= ind.resource then
        -- e.g. a druid changed form: the same button now follows another
        -- resource. Snap to the new value and recolor (colors only, so this
        -- is fine in combat).
        ind.resource = resource
        ind.barMax = nil
    end
    if (resource or "mana") ~= ind.styledResource then
        -- the resource may have its own style; a style change waits for the
        -- end of combat, the colors do not
        if not ApplyMode(ind) then AB.restyleAfterCombat = true end
        ApplyIndicatorStyle(ind)
        ns.Animation:ApplyLiquidSettings(ind)
        ns.Animation:ApplyFxSettings(ind)
    end
end

function AB:RefreshSlots()
    for i = 1, #list do
        local ind = list[i]
        local spellID, reason = ResolveSpell(ind)
        if spellID ~= ind.spellID then
            ind.barMax = nil  -- force a snap (no animation) on content change
        end
        ind.spellID = spellID
        ind.costReason = reason
        ResolveCost(ind)
    end
    self:RefreshRange()
    self:UpdateAll()
end

function AB:RefreshCosts()
    ns.Mana:InvalidateCosts()
    for i = 1, #list do
        ResolveCost(list[i])
    end
    self:UpdateAll()
end

---------------------------------------------------------------------------
-- Display
---------------------------------------------------------------------------
local function HideIndicator(ind, reason)
    if ind.shown then
        ind.shown = false
        SetOverlayShown(ind, false)
        ns.Animation:ResetIndicator(ind)
    end
    SetReason(ind, reason)
end

local function UpdateIndicator(ind, value, secret, last)
    local cost = ind.cost
    local ready
    if not secret then
        ready = value >= cost
    else
        -- The value is secret: we may not compare it. Ask the client whether this
        -- action is lacking resources instead; if that is not readable either,
        -- show nothing rather than guess.
        if not ind.slot or not ns.api.IsUsableAction then
            return HideIndicator(ind, "secret-usability")
        end
        local _, lacking = ns.api.IsUsableAction(ind.slot)
        if IsSecret(lacking) or type(lacking) ~= "boolean" then
            return HideIndicator(ind, "secret-usability")
        end
        ready = not lacking
    end

    if ready then
        if ind.shown then
            ind.shown = false
            SetOverlayShown(ind, false)
            ns.Animation:ResetIndicator(ind)
            if ns:CatGet(ind.category, "glow") then ns.Animation:PlayGlow(ind) end
            if AB:ReadySoundWanted(ind) then AB:PlayReadySound() end
        end
        SetReason(ind, "ready")
        return
    end

    local continuing = ind.shown
    if not continuing then
        ind.shown = true
        SetOverlayShown(ind, true)
    end
    if ind.barMax ~= cost then
        ind.bar:SetMinMaxValues(-cost * ZERO_EPS, cost)
        ind.barMax = cost
        continuing = false
    end

    local smooth = ns.db.smooth and continuing
    local gained = false
    if not secret and last ~= nil then
        if value < last then
            -- Spending: update immediately. Exception: rage that drops out
            -- of combat is decaying a point at a time, so let it drain
            -- smoothly instead of stepping.
            if ind.resource ~= "rage" or ns:InCombat() then
                smooth = false
            end
        elseif value > last then
            gained = true
        end
    end

    ns.Animation:SetBarValue(ind, value, secret, smooth)

    if gained and continuing and ns.db.pulse then
        ns.Animation:PlayPulse(ind)
    end
    SetReason(ind, secret and "showing-secret" or "showing")
end

function AB:HideAll(reason)
    for i = 1, #list do
        local ind = list[i]
        HideIndicator(ind, reason)
        if ind.rangeOn then ind.rangeOn = false; ind.range:Hide(); ind.rangeEdge:Hide() end
        ind.rangeOut = false
    end
end

---------------------------------------------------------------------------
-- Signals (all optional, off by default)
-- Every value is checked for secrecy first. When the game hides a value, the
-- signal switches itself off instead of guessing.
---------------------------------------------------------------------------
AB.rangeSecret = false

local function SetRangeTint(ind, out)
    if ind.rangeOn ~= out then
        ind.rangeOn = out
        ind.range:SetShown(out and ns.db.rangeStyle ~= "border")
        ind.rangeEdge:SetShown(out and ns.db.rangeStyle == "border")
    end
end

-- A spell you could not cast anyway (no mana, wrong stance...) is not marked.
local function CastBlocked(ind)
    if not ns.db.rangeUsable then return false end
    if ind.shown then return true end    -- ManaRise is showing "not enough resource"
    if ind.slot and ns.api.IsUsableAction then
        local usable = ns.api.IsUsableAction(ind.slot)
        if not IsSecret(usable) and usable == false then return true end
    end
    return false
end

-- Shows the mark from the last range result (ind.rangeOut) and the usability rule.
local function ShowRange(ind)
    SetRangeTint(ind, ind.rangeOut == true and ns.db.range and ns.db.enabled and not AB.simulating
        and not CastBlocked(ind))
end

-- inRange: what IsActionInRange / the range event reported
local function EvalRange(ind, inRange)
    local out = false
    if ns.db.range and ns.db.enabled and not AB.simulating then
        if IsSecret(inRange) then
            AB.rangeSecret = true
        elseif inRange == false or inRange == 0 then
            out = true
        end
    end
    ind.rangeOut = out
    ShowRange(ind)
end

function AB:RefreshRange()
    local fn = ns.api.IsActionInRange
    local enable = ns.api.EnableActionRangeCheck
    if not ns.db.range then self.rangeSecret = false end
    for i = 1, #list do
        local ind = list[i]
        local r
        if ns.db.range and fn and ind.slot then
            if enable and ind.rangeSlot ~= ind.slot then
                ind.rangeSlot = ind.slot
                pcall(enable, ind.slot, true)
            end
            r = fn(ind.slot)
        end
        EvalRange(ind, r)
    end
end

-- ACTION_RANGE_CHECK_UPDATE: slot, isInRange, checksRange
function AB:OnRangeEvent(slot, isInRange, checksRange)
    if not ns.db.range then return end
    for i = 1, #list do
        local ind = list[i]
        if ind.slot == slot then
            if IsSecret(checksRange) then
                self.rangeSecret = true
                ind.rangeOut = false
                SetRangeTint(ind, false)
            elseif checksRange == false then
                ind.rangeOut = false
                SetRangeTint(ind, false)
            else
                EvalRange(ind, isInRange)
            end
        end
    end
end

-- Sounds. One slot, "ready" (a spell becomes castable). Its value is "off", a built-in name,
-- "custom" (a file path or a numeric sound ID typed by the player) or
-- "lsm:<name>" (a sound registered with LibSharedMedia, if another addon
-- provides it). Everything is resolved when played.
local SLOT_KEYS = { ready = { "sound", "soundCustom" } }
local SLOT_LABEL = { ready = "SLOT_READY" }
AB.soundBad = {}      -- [slot] = text of a sound that failed to play
local soundWarned = {}
local lastSound = -10

local function LSMFetch(name)
    local stub = LibStub
    local lsm = stub and stub("LibSharedMedia-3.0", true)
    if lsm and lsm.Fetch then return lsm:Fetch("sound", name, true) end
end

-- Readable name of what a slot is set to (for messages).
function AB:SoundLabel(slot, value)
    local keys = SLOT_KEYS[slot]
    value = value or ns.db[keys[1]]
    if value == "custom" then
        local c = strtrim(ns.db[keys[2]] or "")
        return c ~= "" and c or "custom"
    end
    if value == "off" or ns.SOUNDS[value] then return L["OPT_SOUND_" .. string.upper(value)] end
    if ns.SOUND_PACK_NAME[value] then return ns.SOUND_PACK_NAME[value] end
    return (string.gsub(value, "^lsm:", ""))
end

-- kind, argument for a slot, or nil, reason
function AB:ResolveSound(slot, value)
    local keys = SLOT_KEYS[slot]
    value = value or ns.db[keys[1]]
    if value == "off" then return nil, "off" end
    local target
    if value == "custom" then
        target = strtrim(ns.db[keys[2]] or "")
        if target == "" then return nil, "empty" end
    elseif string.sub(value, 1, 4) == "lsm:" then
        target = LSMFetch(string.sub(value, 5))
        if target == nil then return nil, "missing" end
    elseif ns.SOUND_PACK_NAME[value] then
        if not ns.api.PlaySoundFile then return nil, "missing" end
        return "file", ns.SOUND_PACK_PATH .. string.sub(value, 6) .. ".ogg"
    else
        local name = ns.SOUNDS[value]
        local kit = name and SOUNDKIT and SOUNDKIT[name]
        if type(kit) == "number" and ns.api.PlaySound then return "kit", kit end
        return nil, "missing"
    end
    if type(target) == "number" or string.match(target, "^%d+$") then
        if ns.api.PlaySound then return "kit", tonumber(target) end
        return nil, "missing"
    end
    if not ns.api.PlaySoundFile then return nil, "missing" end
    return "file", (string.gsub(target, "/", "\\"))
end

-- Plays a slot (or a value being tried out). Returns true if the game accepted
-- it. A failure is said once in chat (every time when loud) and kept for
-- /mr status and /mr report. Never raises an error.
function AB:PlaySlot(slot, value, loud)
    local kind, arg = self:ResolveSound(slot, value)
    local played = false
    if kind then
        local ok, willPlay
        if kind == "kit" then
            ok, willPlay = pcall(ns.api.PlaySound, arg, "SFX")
        else
            ok, willPlay = pcall(ns.api.PlaySoundFile, arg, "SFX")
        end
        if not ok then ns:LogError("sound", willPlay) end
        played = ok and willPlay ~= false
    end
    local label = string.format(L.SOUND_UNPLAYABLE, L[SLOT_LABEL[slot]], self:SoundLabel(slot, value))
    if played then
        self.soundBad[slot] = nil
    else
        self.soundBad[slot] = label
        if loud or not soundWarned[label] then
            soundWarned[label] = true
            ns:Print("%s", label)
        end
    end
    return played
end

-- The sound of a slot as configured, once per short pause (a burst of spells
-- becoming ready makes one sound; the pause is shared).
function AB:PlayThrottled(slot)
    if self.simulating or ns.db[SLOT_KEYS[slot][1]] == "off" then return end
    local now = ns.api.GetTime and ns.api.GetTime() or 0
    if now - lastSound < 0.75 then
        return
    end
    lastSound = now
    self:PlaySlot(slot)
end

function AB:PlayReadySound() self:PlayThrottled("ready") end

-- Spell ID and name for text typed by the player: a spell ID, a spell link or
-- an ability name. Returns nil if the client does not know it.
function AB:ResolveSpellText(text)
    text = strtrim(text or "")
    local id = tonumber(string.match(text, "Hspell:(%d+)") or string.match(text, "^%d+$") or "")
    local info = id or text
    local name
    if ns.api.GetSpellInfo and info ~= "" then
        local ok, a, _, _, _, _, _, sid = pcall(ns.api.GetSpellInfo, info)
        if ok and type(a) == "table" then
            id, name = a.spellID or id, a.name
        elseif ok and type(a) == "string" then
            id, name = sid or id, a
        elseif ok then
            id = nil
        end
    end
    if id and not name and ns.api.GetSpellName then name = ns.api.GetSpellName(id) end
    if type(id) ~= "number" or (not name and ns.api.GetSpellInfo) then return nil end
    return id, name
end

function AB:SoundSpellList()
    local names = {}
    for id in pairs(ns.db.soundSpells) do
        names[#names + 1] = (ns.api.GetSpellName and ns.api.GetSpellName(id)) or tostring(id)
    end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or L.SOUNDSPELL_NONE
end

-- Does this button's ability play the ready sound? (all of them unless limited)
function AB:ReadySoundWanted(ind)
    if not ns.db.soundOnly then return true end
    local id = ind.spellID
    if type(id) ~= "number" then return false end
    if ns.db.soundSpells[id] then return true end
    -- the same ability under another ID (a talent replacing it): compare names
    local name = ns.api.GetSpellName and ns.api.GetSpellName(id)
    if type(name) ~= "string" then return false end
    for sid in pairs(ns.db.soundSpells) do
        if ns.api.GetSpellName(sid) == name then return true end
    end
    return false
end

-- Features that are running in a reduced way, in plain words (for
-- /mr status and /mr report). Empty when everything works as configured.
function AB:FeatureNotes()
    local notes = {}
    local db = ns.db
    if db.style == "liquid" and ns.Animation.scrollMethod == "move" then
        notes[#notes + 1] = L.FEAT_WAVES_MOVE
    end
    if db.range and ns.api.IsActionInRange == nil then
        notes[#notes + 1] = L.FEAT_RANGE
    elseif db.range and ns.IsEventValid and not ns:IsEventValid("ACTION_RANGE_CHECK_UPDATE") then
        notes[#notes + 1] = L.FEAT_RANGE
    elseif db.range and self.rangeSecret then
        notes[#notes + 1] = L.FEAT_RANGE_SECRET
    end
    for _, slot in ipairs({ "ready" }) do
        local value = db[SLOT_KEYS[slot][1]]
        if value ~= "off" and (self.soundBad[slot] or not self:ResolveSound(slot)) then
            notes[#notes + 1] = string.format(L.SOUND_UNPLAYABLE, L[SLOT_LABEL[slot]], self:SoundLabel(slot))
        end
    end
    return notes
end

-- Button and mask counts for /mr report.
function AB:ButtonStats()
    local squares = 0
    for i = 1, #list do if list[i].square then squares = squares + 1 end end
    return #list, squares, self.gamepadSkipped
end

-- Reused between updates so power updates allocate nothing.
local current, currentSecret, blocked = {}, {}, {}

-- only: a resource key to update just the buttons using that resource (a
-- UNIT_POWER_UPDATE for energy needn't touch mana buttons), or nil for all.
function AB:UpdateAll(only)
    if self.simulating or not ns.db.enabled then return end
    local Mana = ns.Mana

    local dead = ns.api.UnitIsDeadOrGhost and ns.api.UnitIsDeadOrGhost("player")
    if not IsSecret(dead) and dead then
        self:HideAll("dead")
        wipe(Mana.last)
        return
    end

    for key in pairs(Mana.RESOURCES) do
        if only == nil or only == key then
            local v, secret = Mana:GetCurrent(key)
            current[key], currentSecret[key] = v, secret
            if v == nil then
                blocked[key] = "no-value"
            elseif not Mana:HasPool(key) then
                blocked[key] = "no-pool"
            else
                blocked[key] = nil
            end
        end
    end

    for i = 1, #list do
        local ind = list[i]
        local key = ind.resource
        if only == nil or key == only then
            if not ns:CatEnabled(ind.category) then
                HideIndicator(ind, "category-off")
            elseif not ind.cost then
                HideIndicator(ind, ind.costReason or "no-tracked-cost")
            elseif blocked[key] then
                HideIndicator(ind, blocked[key])
            else
                UpdateIndicator(ind, current[key], currentSecret[key], Mana.last[key])
            end
            if ind.rangeOut then ShowRange(ind) end
        end
    end

    for key in pairs(Mana.RESOURCES) do
        if only == nil or only == key then
            if blocked[key] or currentSecret[key] then
                Mana.last[key] = nil
            else
                Mana.last[key] = current[key]
            end
        end
    end
end

function AB:ApplyStyle()
    local deferred = false
    for i = 1, #list do
        ApplyIndicatorStyle(list[i])
        if not ApplyMode(list[i]) then deferred = true end
        ns.Animation:ApplyLiquidSettings(list[i])
        ns.Animation:ApplyFxSettings(list[i])
        -- the category's fill switch may have changed
        if list[i].category then SetOverlayShown(list[i], list[i].shown == true) end
    end
    for i = 1, #previews do
        local ind = previews[i]
        ApplyIndicatorStyle(ind)
        if not ApplyMode(ind) then deferred = true end
        ns.Animation:ApplyLiquidSettings(ind)
        ns.Animation:ApplyFxSettings(ind)
    end
    self.restyleAfterCombat = deferred
    if ns.apiOK then
        self:RefreshRange()
        if ns.db.enabled then self:UpdateAll() end
    end
    return deferred
end

-- ManaRise's own state for a button (tests and diagnostics).
function AB:GetIndicator(button)
    return indicators[button]
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
ns:On("UNIT_POWER_UPDATE", function(_, unit, token)
    -- immediate: no frame delay on spend/regen
    local which = ns.Mana:TokenResource(token)
    if which == true then
        AB:UpdateAll()
    elseif which then
        AB:UpdateAll(which)
    end
end)
ns:On("UNIT_MAXPOWER", function() AB:UpdateAll() end)
ns:On("UNIT_DISPLAYPOWER", function() ns:Schedule("costs") end)
ns:On("PLAYER_DEAD", function() AB:UpdateAll() end)
ns:On("PLAYER_ALIVE", function() ns:Schedule("mana") end)
ns:On("PLAYER_UNGHOST", function() ns:Schedule("mana") end)

local function CostsChanged() ns:Schedule("costs") end
ns:On("UNIT_AURA", CostsChanged)
ns:On("ACTIONBAR_UPDATE_USABLE", CostsChanged)
ns:On("SPELL_UPDATE_USABLE", CostsChanged)
-- forms change both the bar page and which costs apply (druids)
ns:On("UPDATE_SHAPESHIFT_FORM", function() ns.Mana:InvalidateCosts(); ns:Schedule("slots") end)
ns:On("PLAYER_SPECIALIZATION_CHANGED", function() ns:Schedule("slots") end)
ns:On("SPELLS_CHANGED", function() ns.Mana:InvalidateCosts(); ns:Schedule("slots") end)

ns:On("ACTIONBAR_SLOT_CHANGED", function() ns:Schedule("slots") end)
ns:On("ACTIONBAR_PAGE_CHANGED", function() ns:Schedule("slots") end)
ns:On("UPDATE_BONUS_ACTIONBAR", function() ns:Schedule("slots") end)
ns:On("ACTION_RANGE_CHECK_UPDATE", function(_, slot, inRange, checks) AB:OnRangeEvent(slot, inRange, checks) end)
ns:On("PLAYER_TARGET_CHANGED", function() if ns.db and ns.db.range then AB:RefreshRange() end end)
ns:On("EDIT_MODE_LAYOUTS_UPDATED", function() ns:Schedule("discover") end)
ns:On("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED", function() ns:Schedule("slots") end)

---------------------------------------------------------------------------
-- Simulation (/mr test)
-- STRICTLY a visual preview with fake numbers. Never runs in combat, never
-- reflects real readiness, and stops automatically when combat starts.
---------------------------------------------------------------------------
local sim = { chosen = {}, costs = {}, ready = {} }
local SIM_DURATION = 6
local SIM_COSTS = { 120, 200, 280, 360, 440, 520, 160, 240, 320, 400, 480, 560 }

local function SimTick(dt)
    sim.t = sim.t + dt
    local mana = sim.peak * (sim.t / SIM_DURATION)
    for i = 1, #sim.chosen do
        local ind = sim.chosen[i]
        if not sim.ready[i] then
            if mana >= sim.costs[i] then
                sim.ready[i] = true
                SetOverlayShown(ind, false)
                if ns:CatGet(ind.category, "glow") then ns.Animation:PlayGlow(ind) end
            else
                ind.bar:SetValue(mana)
            end
        end
    end
    if sim.t >= SIM_DURATION + 0.6 then
        AB:StopSimulation(false)
        return false
    end
    return true
end

function AB:StartSimulation()
    if ns:InCombat() then
        ns:Print(L.TEST_COMBAT)
        return
    end
    if self.simulating then self:StopSimulation(true) end
    self:Discover()

    wipe(sim.chosen); wipe(sim.costs); wipe(sim.ready)
    local peak = 0
    for i = 1, #list do
        local ind = list[i]
        if ind.button:IsVisible() and #sim.chosen < #SIM_COSTS then
            local n = #sim.chosen + 1
            sim.chosen[n] = ind
            sim.costs[n] = SIM_COSTS[n]
            if SIM_COSTS[n] > peak then peak = SIM_COSTS[n] end
        end
    end
    if #sim.chosen == 0 then
        ns:Print(L.TEST_NO_BUTTONS)
        return
    end

    self.simulating = true
    self:HideAll("simulation")
    sim.t = 0
    sim.peak = peak * 1.08
    for i = 1, #sim.chosen do
        local ind = sim.chosen[i]
        ind.bar:SetMinMaxValues(-sim.costs[i] * ZERO_EPS, sim.costs[i])
        ind.bar:SetValue(0)
        ind.barMax = nil
        SetOverlayShown(ind, true)
    end
    ns:Print(L.TEST_STARTED, #sim.chosen, SIM_DURATION)
    -- let the player hear the ready sound if it is switched on
    if ns.db.sound ~= "off" then
        local sims = self
        ns.api.TimerAfter(1, function() if sims.simulating then sims:PlaySlot("ready") end end)
    end
    ns.Animation:AddTicker("simulation", SimTick)
end

function AB:StopSimulation(silent)
    if not self.simulating then return end
    self.simulating = false
    ns.Animation:RemoveTicker("simulation")
    for i = 1, #sim.chosen do
        SetOverlayShown(sim.chosen[i], false)
        sim.chosen[i].shown = false
        sim.chosen[i].barMax = nil
    end
    wipe(sim.chosen)
    if not silent then ns:Print(L.TEST_ENDED) end
    if ns.db.enabled then ns:Schedule("slots") end
end
