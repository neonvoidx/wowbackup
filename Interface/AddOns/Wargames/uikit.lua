-- uikit.lua: WarGames+ shared UI kit
-- Owns the theme system (built-in themes, custom theme editor support, live re-theming)
-- and the flat/modern styling primitives every other file builds on. Loads immediately
-- after Localization.lua so every later file can rely on WargamesPlus.* being ready.
local ADDON_NAME = ...

-- Localization.lua bootstraps _G["WargamesPlus"] and sets WG.L
local WargamesPlus = _G["WargamesPlus"] or {}
_G["WargamesPlus"] = WargamesPlus
local L = WargamesPlus.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

-- Minimal safety net for the fields this file reads before core.lua's full
-- default-init block runs (core.lua owns the rest of WG_History's defaults).
WG_History = WG_History or {}
if not WG_History.theme then WG_History.theme = "Horde" end
if not WG_History.customTheme then WG_History.customTheme = { baseTheme = "Midnight", overrides = {} } end

-- ---------- FONT PICKER ----------
-- WoW built-in TTFs only (no bundled fonts). ADDON_FONT is resolved once at load
-- from the saved choice; every file captures it as a local, so a change needs /reload.
local WOW_FONTS = {
    ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",   -- WoW default
    ["Arial Narrow"]  = "Fonts\\ARIALN.TTF",
    ["Expressway"]    = "Fonts\\2002.ttf",
    ["Morpheus"]      = "Fonts\\MORPHEUS.ttf",
    ["Skurri"]        = "Fonts\\skurri.ttf",
}
local FONT_ORDER = { "Friz Quadrata", "Arial Narrow", "Expressway", "Morpheus", "Skurri" }
local ADDON_FONT = WOW_FONTS[WG_History.font] or "Fonts\\FRIZQT__.TTF"
WargamesPlus.WOW_FONTS  = WOW_FONTS
WargamesPlus.FONT_ORDER = FONT_ORDER

-- ---------- THEMES ----------
-- Palette matches the approved "War Room" visual design: layered near-black surfaces
-- (backdropBg = outermost window, cardBg = inner panels one shade lighter), a single
-- saturated accent per theme, and bright neutral titles/body text (accent is reserved
-- for the logo mark, active states and CTAs, not title text — a deliberate change from
-- the old convention where titleColor equaled the theme accent).
local THEMES = {
    Midnight = {
        backdropBg      = {0.031, 0.035, 0.047, 0.97},
        backdropBorder  = {0.110, 0.141, 0.176, 1},
        cardBg          = {0.059, 0.075, 0.094, 1},
        cardBorder      = {0.094, 0.125, 0.157, 1},
        accent          = {0.00, 0.639, 0.800, 1},
        buttonNormal    = {0.078, 0.102, 0.125, 1},
        buttonHover     = {0.110, 0.141, 0.173, 1},
        buttonPushed    = {0.039, 0.051, 0.063, 1},
        buttonBorder    = {0.094, 0.125, 0.157, 1},
        buttonText      = {0.918, 0.949, 0.961, 1},
        buttonDisabled  = {0.40, 0.44, 0.47, 1},
        selectionDim    = {0.00, 0.639, 0.800, 0.28},
        selectionFaint  = {0.00, 0.639, 0.800, 0.06},
        inputBg         = {0.078, 0.102, 0.125, 0.95},
        inputBorder     = {0.094, 0.125, 0.157, 1},
        inputText       = {0.918, 0.949, 0.961, 1},
        scrollThumb     = {0.20, 0.30, 0.36, 0.85},
        scrollTrack     = {0.059, 0.075, 0.094, 0.5},
        titleColor      = {0.918, 0.949, 0.961, 1},
        headerColor     = {0.478, 0.541, 0.580, 1},
        normalText      = {0.918, 0.949, 0.961, 1},
        footerColor     = {0.478, 0.541, 0.580, 1},
        closeNormal     = {0.478, 0.541, 0.580, 1},
        closeHover      = {1.00, 0.361, 0.361, 1},
        rowHighlight    = {1, 1, 1, 0.06},
        inlineAccent    = "00a3cc",
        inlineGreen     = "4fd15c",
        inlineLoss      = "ff5c5c",
        inlineChar      = "e0b84a",
        inlineBnet      = "4d9fe0",
        swatchColor     = {0.00, 0.639, 0.800},
        banColor        = {0.85, 0.18, 0.18, 0.32},
        pickColor       = {0.20, 0.75, 0.30, 0.28},
        warningColor    = {0.88, 0.72, 0.29, 1},
    },
    Horde = {
        backdropBg      = {0.039, 0.027, 0.031, 0.97},
        backdropBorder  = {0.180, 0.110, 0.118, 1},
        cardBg          = {0.075, 0.051, 0.055, 1},
        cardBorder      = {0.125, 0.078, 0.082, 1},
        accent          = {0.522, 0.102, 0.102, 1},
        buttonNormal    = {0.110, 0.075, 0.082, 1},
        buttonHover     = {0.141, 0.094, 0.098, 1},
        buttonPushed    = {0.055, 0.039, 0.039, 1},
        buttonBorder    = {0.125, 0.078, 0.082, 1},
        buttonText      = {0.949, 0.910, 0.902, 1},
        buttonDisabled  = {0.45, 0.38, 0.38, 1},
        selectionDim    = {0.522, 0.102, 0.102, 0.28},
        selectionFaint  = {0.522, 0.102, 0.102, 0.06},
        inputBg         = {0.110, 0.075, 0.082, 0.95},
        inputBorder     = {0.125, 0.078, 0.082, 1},
        inputText       = {0.949, 0.910, 0.902, 1},
        scrollThumb     = {0.35, 0.16, 0.17, 0.85},
        scrollTrack     = {0.075, 0.051, 0.055, 0.5},
        titleColor      = {0.949, 0.910, 0.902, 1},
        headerColor     = {0.541, 0.451, 0.439, 1},
        normalText      = {0.949, 0.910, 0.902, 1},
        footerColor     = {0.541, 0.451, 0.439, 1},
        closeNormal     = {0.541, 0.451, 0.439, 1},
        closeHover      = {1.00, 0.361, 0.361, 1},
        rowHighlight    = {1, 1, 1, 0.06},
        inlineAccent    = "851a1a",
        inlineGreen     = "4fd15c",
        inlineLoss      = "ff5c5c",
        inlineChar      = "e0b84a",
        inlineBnet      = "d85a5a",
        swatchColor     = {0.522, 0.102, 0.102},
        banColor        = {0.85, 0.15, 0.15, 0.32},
        pickColor       = {0.20, 0.75, 0.30, 0.28},
        warningColor    = {0.88, 0.72, 0.29, 1},
    },
    Alliance = {
        backdropBg      = {0.031, 0.031, 0.055, 0.97},
        backdropBorder  = {0.165, 0.141, 0.063, 1},
        cardBg          = {0.055, 0.055, 0.086, 1},
        cardBorder      = {0.125, 0.110, 0.063, 1},
        accent          = {0.753, 0.627, 0.188, 1},
        buttonNormal    = {0.078, 0.078, 0.118, 1},
        buttonHover     = {0.110, 0.110, 0.157, 1},
        buttonPushed    = {0.039, 0.039, 0.063, 1},
        buttonBorder    = {0.125, 0.110, 0.063, 1},
        buttonText      = {0.941, 0.925, 0.847, 1},
        buttonDisabled  = {0.42, 0.40, 0.36, 1},
        selectionDim    = {0.753, 0.627, 0.188, 0.28},
        selectionFaint  = {0.753, 0.627, 0.188, 0.06},
        inputBg         = {0.078, 0.078, 0.118, 0.95},
        inputBorder     = {0.125, 0.110, 0.063, 1},
        inputText       = {0.941, 0.925, 0.847, 1},
        scrollThumb     = {0.32, 0.28, 0.14, 0.85},
        scrollTrack     = {0.055, 0.055, 0.086, 0.5},
        titleColor      = {0.941, 0.925, 0.847, 1},
        headerColor     = {0.541, 0.510, 0.439, 1},
        normalText      = {0.941, 0.925, 0.847, 1},
        footerColor     = {0.541, 0.510, 0.439, 1},
        closeNormal     = {0.541, 0.510, 0.439, 1},
        closeHover      = {1.00, 0.361, 0.361, 1},
        rowHighlight    = {1, 1, 1, 0.06},
        inlineAccent    = "c0a030",
        inlineGreen     = "4fd15c",
        inlineLoss      = "ff5c5c",
        inlineChar      = "e0b84a",
        inlineBnet      = "4d9fe0",
        swatchColor     = {0.753, 0.627, 0.188},
        banColor        = {0.85, 0.15, 0.15, 0.32},
        pickColor       = {0.20, 0.75, 0.30, 0.28},
        warningColor    = {0.88, 0.72, 0.29, 1},
    },
}

-- Faction identity colors — intentionally NOT part of THEMES/COLOR_GROUPS: these mark
-- Horde-red/Alliance-blue the same way everywhere regardless of the active UI theme,
-- the same way Blizzard's own UI never recolors faction indicators per addon skin.
local FACTION_COLORS = {
    Horde    = {0.90, 0.15, 0.15, 1},
    Alliance = {0.25, 0.45, 0.85, 1},
}

-- ---------- CUSTOM THEME SYSTEM ----------
local COLOR_GROUPS = {
    {key = "accent", label = L["THEME_ACCENT"], derive = function(r, g, b)
        return {
            accent          = {r, g, b, 1},
            selectionDim    = {r, g, b, 0.28},
            selectionFaint  = {r, g, b, 0.06},
            swatchColor     = {r, g, b},
            inlineAccent    = string.format("%02x%02x%02x", math.floor(r*255), math.floor(g*255), math.floor(b*255)),
        }
    end},
    {key = "background", label = L["THEME_BACKGROUND"], derive = function(r, g, b)
        return {
            backdropBg  = {r, g, b, 0.97},
            cardBg      = {math.min(r + 0.035, 1), math.min(g + 0.035, 1), math.min(b + 0.035, 1), 1},
            inputBg     = {math.min(r + 0.035, 1), math.min(g + 0.035, 1), math.min(b + 0.035, 1), 0.95},
            scrollTrack = {math.min(r + 0.035, 1), math.min(g + 0.035, 1), math.min(b + 0.035, 1), 0.5},
        }
    end},
    {key = "border", label = L["THEME_BORDER"], derive = function(r, g, b)
        return {
            backdropBorder = {r, g, b, 1},
            cardBorder     = {r * 0.7, g * 0.7, b * 0.7, 1},
            inputBorder    = {r * 0.7, g * 0.7, b * 0.7, 1},
            buttonBorder   = {r * 0.7, g * 0.7, b * 0.7, 1},
        }
    end},
    {key = "button", label = L["THEME_BUTTON"], derive = function(r, g, b)
        return {
            buttonNormal = {r, g, b, 1},
            buttonHover  = {math.min(r * 1.6, 1), math.min(g * 1.6, 1), math.min(b * 1.6, 1), 1},
            buttonPushed = {r * 0.5, g * 0.5, b * 0.5, 1},
        }
    end},
    {key = "text", label = L["THEME_TEXT"], derive = function(r, g, b)
        return {
            buttonText  = {r, g, b, 1},
            normalText  = {r, g, b, 1},
            inputText   = {r, g, b, 1},
            titleColor  = {r, g, b, 1},
            headerColor = {r * 0.6, g * 0.6, b * 0.6, 1},
            footerColor = {r * 0.6, g * 0.6, b * 0.6, 1},
            closeNormal = {r * 0.6, g * 0.6, b * 0.6, 1},
        }
    end},
    {key = "closeHover", label = L["THEME_CLOSE_HOVER"], derive = function(r, g, b)
        return {
            closeNormal = {r * 0.65, g * 0.65, b * 0.65, 1},
            closeHover  = {r, g, b, 1},
        }
    end},
    {key = "winColor", label = L["THEME_WIN_COLOR"], derive = function(r, g, b)
        return {
            inlineGreen = string.format("%02x%02x%02x", math.floor(r*255), math.floor(g*255), math.floor(b*255)),
        }
    end},
    {key = "lossColor", label = L["THEME_LOSS_COLOR"], derive = function(r, g, b)
        return {
            inlineLoss = string.format("%02x%02x%02x", math.floor(r*255), math.floor(g*255), math.floor(b*255)),
        }
    end},
}

local function DeepCopyTheme(src)
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            copy[k] = {unpack(v)}
        else
            copy[k] = v
        end
    end
    return copy
end

local function BuildCustomTheme()
    local ct = WG_History.customTheme
    local baseName = ct.baseTheme or "Midnight"
    local base = THEMES[baseName] or THEMES.Midnight
    local theme = DeepCopyTheme(base)
    for _, group in ipairs(COLOR_GROUPS) do
        local ov = ct.overrides[group.key]
        if ov then
            local derived = group.derive(ov.r, ov.g, ov.b)
            for k, v in pairs(derived) do
                theme[k] = v
            end
        end
    end
    return theme
end

local activeTheme
if WG_History.theme == "Custom" then
    activeTheme = BuildCustomTheme()
else
    activeTheme = THEMES[WG_History.theme] or THEMES.Horde
end

-- ---------- FRAME REGISTRIES ----------
local themedBackdrops = {}
local themedButtons = {}
local themedInputs = {}
local themedElements = {} -- {frame, applyFn}
local themedDropdowns = {}

local FLAT_BACKDROP = {
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    tile = true, tileSize = 16, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local function ApplyModernStyle(frame)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop(FLAT_BACKDROP)
    frame:SetBackdropColor(unpack(activeTheme.backdropBg))
    frame:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
    if not tContains(themedBackdrops, frame) then table.insert(themedBackdrops, frame) end
end

-- One shade lighter than ApplyModernStyle's window-level backdrop — the "inner panel"
-- layer (Friends/Challenge cards, map tiles, series-tracker pills, custom-theme box)
-- that gives the flat design its sense of depth. Not a themedBackdrops entry (that
-- registry always repaints with backdropBg/backdropBorder) — self-registers instead.
local function ApplyCardStyle(frame)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop(FLAT_BACKDROP)
    frame:SetBackdropColor(unpack(activeTheme.cardBg))
    frame:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
    table.insert(themedElements, {frame, function(f)
        f:SetBackdropColor(unpack(activeTheme.cardBg))
        f:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
    end})
end

local function StyleButton(btn)
    if not btn._texturesHidden then
        for _, region in pairs({btn:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                local layer = region:GetDrawLayer()
                if layer == "BACKGROUND" or layer == "BORDER" then
                    region:SetTexture(nil); region:Hide()
                end
            end
        end
        btn._texturesHidden = true
    end

    if not btn._flatBg then
        btn._flatBg = btn:CreateTexture(nil, "BACKGROUND")
        btn._flatBg:SetAllPoints()
    end
    btn._flatBg:SetColorTexture(unpack(activeTheme.buttonNormal))

    if not btn.SetBackdrop then Mixin(btn, BackdropTemplateMixin) end
    btn:SetBackdrop(FLAT_BACKDROP)
    btn:SetBackdropColor(0, 0, 0, 0)
    btn:SetBackdropBorderColor(unpack(activeTheme.buttonBorder))

    local fs = btn:GetFontString()
    if fs then
        if not btn._hasInlineColor then
            fs:SetTextColor(unpack(activeTheme.buttonText))
        end
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", btn, "LEFT", 5, 0)
        fs:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
        fs:SetWordWrap(false)
    end

    if not btn._hooksSet then
        btn:HookScript("OnEnter", function(self)
            if self._flatBg then self._flatBg:SetColorTexture(unpack(activeTheme.buttonHover)) end
        end)
        btn:HookScript("OnLeave", function(self)
            if not self._flatBg then return end
            if self._active then
                self._flatBg:SetColorTexture(unpack(activeTheme.selectionDim))
            else
                self._flatBg:SetColorTexture(unpack(activeTheme.buttonNormal))
            end
        end)
        btn:HookScript("OnMouseDown", function(self)
            if self._flatBg then self._flatBg:SetColorTexture(unpack(activeTheme.buttonPushed)) end
        end)
        btn:HookScript("OnMouseUp", function(self)
            if self._flatBg then self._flatBg:SetColorTexture(unpack(activeTheme.buttonHover)) end
        end)
        btn._hooksSet = true
    end

    if not tContains(themedButtons, btn) then table.insert(themedButtons, btn) end
end

local function StyleInput(editbox)
    if not editbox._texturesHidden then
        for _, region in pairs({editbox:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                region:SetTexture(nil); region:Hide()
            end
        end
        editbox._texturesHidden = true
    end

    if not editbox.SetBackdrop then Mixin(editbox, BackdropTemplateMixin) end
    editbox:SetBackdrop(FLAT_BACKDROP)
    editbox:SetBackdropColor(unpack(activeTheme.inputBg))
    editbox:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
    editbox:SetTextColor(unpack(activeTheme.inputText))
    editbox:SetTextInsets(6, 6, 0, 0)

    if not tContains(themedInputs, editbox) then table.insert(themedInputs, editbox) end
end

local function StyleDropdown(dropdown)
    local name = dropdown:GetName()
    if not name then return end

    -- Hide the default 3-part background textures
    local left = _G[name .. "Left"]
    local middle = _G[name .. "Middle"]
    local right = _G[name .. "Right"]
    if left then left:SetAlpha(0) end
    if middle then middle:SetAlpha(0) end
    if right then right:SetAlpha(0) end

    -- Add flat backdrop matching input style
    if not dropdown._flatBg then
        dropdown._flatBg = CreateFrame("Frame", nil, dropdown)
        dropdown._flatBg:SetPoint("TOPLEFT", 20, -2)
        dropdown._flatBg:SetPoint("BOTTOMRIGHT", -20, 2)
        dropdown._flatBg:SetFrameLevel(dropdown:GetFrameLevel())
        if not dropdown._flatBg.SetBackdrop then Mixin(dropdown._flatBg, BackdropTemplateMixin) end
    end

    -- Stretch the arrow button to cover the full dropdown area
    local ddBtn = _G[name .. "Button"]
    if ddBtn and not ddBtn._stretched then
        ddBtn:ClearAllPoints()
        ddBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 20, -2)
        ddBtn:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -20, 2)
        ddBtn._stretched = true
    end
    dropdown._flatBg:SetBackdrop(FLAT_BACKDROP)
    dropdown._flatBg:SetBackdropColor(unpack(activeTheme.inputBg))
    dropdown._flatBg:SetBackdropBorderColor(unpack(activeTheme.inputBorder))

    -- Style the text
    local text = _G[name .. "Text"]
    if text then
        text:SetFont(ADDON_FONT, 11)
        text:SetTextColor(unpack(activeTheme.inputText))
    end

    -- Style the expand button (arrow)
    local button = _G[name .. "Button"]
    if button then
        local nt = button:GetNormalTexture()
        local pt = button:GetPushedTexture()
        local ht = button:GetHighlightTexture()
        if nt then nt:SetVertexColor(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3]) end
        if pt then pt:SetVertexColor(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3]) end
        if ht then ht:SetVertexColor(1, 1, 1, 0.3) end
    end

    if not tContains(themedDropdowns, dropdown) then table.insert(themedDropdowns, dropdown) end
end

-- Style the global dropdown list popups when they appear
local function StyleDropdownList()
    for i = 1, UIDROPDOWNMENU_MAXLEVELS or 2 do
        local list = _G["DropDownList" .. i]
        if not list then break end

        local backdrop = _G["DropDownList" .. i .. "Backdrop"]
        if backdrop and not backdrop._styled then
            if not backdrop.SetBackdrop then Mixin(backdrop, BackdropTemplateMixin) end
            backdrop:SetBackdrop(FLAT_BACKDROP)
            backdrop:SetBackdropColor(unpack(activeTheme.backdropBg))
            backdrop:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
            backdrop._styled = true

            table.insert(themedElements, {backdrop, function(b)
                b:SetBackdropColor(unpack(activeTheme.backdropBg))
                b:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
            end})
        end

        local menuBackdrop = _G["DropDownList" .. i .. "MenuBackdrop"]
        if menuBackdrop and not menuBackdrop._styled then
            if not menuBackdrop.SetBackdrop then Mixin(menuBackdrop, BackdropTemplateMixin) end
            menuBackdrop:SetBackdrop(FLAT_BACKDROP)
            menuBackdrop:SetBackdropColor(unpack(activeTheme.backdropBg))
            menuBackdrop:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
            menuBackdrop._styled = true

            table.insert(themedElements, {menuBackdrop, function(b)
                b:SetBackdropColor(unpack(activeTheme.backdropBg))
                b:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
            end})
        end
    end
end

hooksecurefunc("ToggleDropDownMenu", StyleDropdownList)

local function StyleScrollBar(scrollFrame)
    local barName = scrollFrame:GetName() and (scrollFrame:GetName() .. "ScrollBar")
    local bar = barName and _G[barName]
    if not bar or bar._styled then return end

    local up = _G[barName .. "ScrollUpButton"]
    local down = _G[barName .. "ScrollDownButton"]
    if up then up:SetAlpha(0); up:SetSize(1, 1) end
    if down then down:SetAlpha(0); down:SetSize(1, 1) end

    for _, region in pairs({bar:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetTexture(nil); region:Hide()
        end
    end

    bar:SetWidth(6)
    if not bar._track then
        bar._track = bar:CreateTexture(nil, "BACKGROUND")
        bar._track:SetAllPoints()
    end
    bar._track:SetColorTexture(unpack(activeTheme.scrollTrack))

    local thumb = _G[barName .. "ThumbTexture"]
    if thumb then
        thumb:SetColorTexture(unpack(activeTheme.scrollThumb))
        thumb:SetSize(6, 30)
    end

    bar._styled = true
    table.insert(themedElements, {bar, function(b)
        if b._track then b._track:SetColorTexture(unpack(activeTheme.scrollTrack)) end
        local t = _G[barName .. "ThumbTexture"]
        if t then t:SetColorTexture(unpack(activeTheme.scrollThumb)) end
    end})
end

-- Filter out dead/hidden-permanently frames from a registry
local function CleanRegistry(registry)
    local j = 1
    for i = 1, #registry do
        local entry = registry[i]
        local frame = type(entry) == "table" and entry[1] or entry
        if frame and frame.GetObjectType then
            registry[j] = entry
            j = j + 1
        end
    end
    for i = j, #registry do registry[i] = nil end
end

local function ApplyTheme(themeName)
    local theme
    if themeName == "Custom" then
        theme = BuildCustomTheme()
    else
        theme = THEMES[themeName]
    end
    if not theme then themeName = "Horde"; theme = THEMES.Horde end
    activeTheme = theme
    WG_History.theme = themeName

    -- Periodically clean registries
    CleanRegistry(themedBackdrops)
    CleanRegistry(themedButtons)
    CleanRegistry(themedInputs)
    CleanRegistry(themedElements)

    for _, frame in ipairs(themedBackdrops) do
        frame:SetBackdropColor(unpack(activeTheme.backdropBg))
        frame:SetBackdropBorderColor(unpack(activeTheme.backdropBorder))
    end
    for _, btn in ipairs(themedButtons) do
        if btn._flatBg then btn._flatBg:SetColorTexture(unpack(activeTheme.buttonNormal)) end
        btn:SetBackdropBorderColor(unpack(activeTheme.buttonBorder))
        local fs = btn:GetFontString()
        if fs and not btn._hasInlineColor then fs:SetTextColor(unpack(activeTheme.buttonText)) end
    end
    for _, eb in ipairs(themedInputs) do
        eb:SetBackdropColor(unpack(activeTheme.inputBg))
        eb:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
        eb:SetTextColor(unpack(activeTheme.inputText))
    end
    for _, dd in ipairs(themedDropdowns) do
        StyleDropdown(dd)
    end
    for _, entry in ipairs(themedElements) do
        local frame, fn = entry[1], entry[2]
        if fn then fn(frame) end
    end

    if WargamesPlus.mainFrame then
        WargamesPlus.mainFrame:Refresh()
        WargamesPlus.mainFrame:RefreshMaps()
    end

    if WargamesPlus.settingsFrame and WargamesPlus.settingsFrame.OnThemeChanged then
        WargamesPlus.settingsFrame:OnThemeChanged()
    end
    if WargamesPlus.OnThemeChanged then WargamesPlus.OnThemeChanged() end
end

-- ---------- SHARED VISUAL PRIMITIVES ----------
-- Every function below is a pure, position-agnostic builder: it creates and themes the
-- widget but leaves layout (anchoring, sizing beyond a default) and persistence to the
-- caller, matching how ApplyModernStyle/StyleButton/etc. already work above.

-- Standard window chrome: accent stripe + title + close button, optionally draggable.
-- Replaces ~5 hand-rolled copies of this pattern that had drifted on close-button size
-- (20x20 vs 16x16), title font size (16/14/13), and title color token (titleColor vs
-- headerColor vs an inline hex string) across core.lua/veto.lua/dock.lua/lfg.lua/etc.
-- Standardizes on theme.titleColor for every window's title and an uppercase "X" close
-- glyph. Returns a table of the created pieces so callers can anchor content below them.
local function CreateWindowChrome(frame, opts)
    opts = opts or {}
    local closeSize = opts.closeSize or 20
    local titleSize = opts.titleSize or 14

    local stripe = frame:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    stripe:SetHeight(2)
    stripe:SetColorTexture(unpack(activeTheme.accent))
    table.insert(themedElements, {stripe, function(tex) tex:SetColorTexture(unpack(activeTheme.accent)) end})

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT, titleSize, "OUTLINE")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(opts.title or "")
    title:SetTextColor(unpack(activeTheme.titleColor))
    table.insert(themedElements, {title, function(fs) fs:SetTextColor(unpack(activeTheme.titleColor)) end})

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(closeSize, closeSize)
    close:SetPoint("TOPRIGHT", -8, -8)
    local closeLabel = close:CreateFontString(nil, "OVERLAY")
    closeLabel:SetFont(ADDON_FONT, 14, "OUTLINE")
    closeLabel:SetPoint("CENTER")
    closeLabel:SetText("X")
    closeLabel:SetTextColor(unpack(activeTheme.closeNormal))
    close:SetScript("OnEnter", function() closeLabel:SetTextColor(unpack(activeTheme.closeHover)) end)
    close:SetScript("OnLeave", function() closeLabel:SetTextColor(unpack(activeTheme.closeNormal)) end)
    close:SetScript("OnClick", opts.onClose or function() frame:Hide() end)
    table.insert(themedElements, {closeLabel, function(fs) fs:SetTextColor(unpack(activeTheme.closeNormal)) end})

    if opts.draggable then
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    local chrome = { stripe = stripe, title = title, close = close, closeLabel = closeLabel }
    frame._chrome = chrome
    return chrome
end

-- Generic themed progress/status bar. colorMode "accent" (default) tracks the active
-- theme's accent color, matching veto.lua's existing turn-timer StatusBar (the reference
-- pattern this generalizes). colorMode "winrate" lerps red->green from the current value,
-- consolidating the 3 independent win-rate-bar reinventions in tracker.lua. The returned
-- frame is a real StatusBar, so callers needing raw SetMinMaxValues/SetValue control
-- (e.g. a ticking timer) can still use those directly instead of SetProgress.
local function HexToRGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function CreateProgressBar(parent, opts)
    opts = opts or {}
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(opts.width or 200, opts.height or 6)
    bar:SetMinMaxValues(0, 1)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, opts.bgAlpha or 0.4)

    local label
    if opts.showLabel then
        label = bar:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, opts.labelSize or 9, "OUTLINE")
        label:SetPoint("CENTER")
        label:SetTextColor(1, 1, 1, 0.9)
        bar._label = label
    end

    local colorMode = opts.colorMode or "accent"

    -- "winrate": a flat theme-green fill on a dim theme-red track, so the bar itself
    -- reads as "green portion vs. red portion" at a glance (matches the approved design)
    -- instead of the old single color that lerped orange-ish between red and green.
    local function Repaint()
        if colorMode == "winrate" then
            local wr, wg, wb = HexToRGB(activeTheme.inlineGreen)
            local lr, lg, lb = HexToRGB(activeTheme.inlineLoss)
            bg:SetColorTexture(lr, lg, lb, opts.bgAlpha or 0.28)
            bar:SetStatusBarColor(wr, wg, wb, 1)
        else
            bar:SetStatusBarColor(unpack(activeTheme.accent))
        end
    end

    function bar:SetProgress(pct01, labelText)
        pct01 = math.max(0, math.min(1, pct01))
        bar:SetValue(pct01)
        Repaint()
        if label then label:SetText(labelText or (math.floor(pct01 * 100 + 0.5) .. "%")) end
    end

    Repaint()
    table.insert(themedElements, {bar, Repaint})
    return bar
end

-- Horizontal row of tabs with a real active-state underline indicator (not just a
-- background recolor), sized from each label's own rendered width up front so no
-- runtime re-centering pass is needed (replaces the C_Timer.After(0,...) hack the old
-- Arena/BG + sub-mode radio row required). tabDefs = { {key=, label=}, ... }.
-- opts.onSelect(key) fires on click; call strip:SetActiveTab(key) to select in code.
local function CreateTabStrip(parent, tabDefs, opts)
    opts = opts or {}
    local height = opts.height or 22
    local spacing = opts.spacing or 18
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetHeight(height)

    local buttons = {}
    local prev

    local function SetActive(key)
        for _, b in ipairs(buttons) do
            local isActive = (b.key == key)
            b.underline:SetShown(isActive)
            b.label:SetTextColor(unpack(isActive and activeTheme.titleColor or activeTheme.footerColor))
        end
        strip.activeKey = key
    end

    for _, def in ipairs(tabDefs) do
        local b = CreateFrame("Button", nil, strip)
        b:SetHeight(height)
        b.key = def.key

        local label = b:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, opts.fontSize or 12, "OUTLINE")
        label:SetPoint("TOP", 0, -2)
        label:SetText(def.label)
        label:SetTextColor(unpack(activeTheme.footerColor))
        b.label = label
        b:SetWidth(math.max(20, label:GetStringWidth()))

        local underline = b:CreateTexture(nil, "ARTWORK")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetColorTexture(unpack(activeTheme.accent))
        underline:Hide()
        b.underline = underline
        table.insert(themedElements, {underline, function(tex) tex:SetColorTexture(unpack(activeTheme.accent)) end})
        table.insert(themedElements, {label, function(fs)
            fs:SetTextColor(unpack(b.key == strip.activeKey and activeTheme.titleColor or activeTheme.footerColor))
        end})

        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
        else
            b:SetPoint("LEFT", strip, "LEFT", 0, 0)
        end
        b:SetScript("OnClick", function()
            SetActive(def.key)
            if opts.onSelect then opts.onSelect(def.key) end
        end)

        table.insert(buttons, b)
        prev = b
    end

    strip.buttons = buttons
    -- Method form (colon call): swallow `self` so SetActive gets just the key string.
    function strip:SetActiveTab(key) SetActive(key) end
    if tabDefs[1] then SetActive(tabDefs[1].key) end
    return strip
end

-- Generic list row: optional leading icon, primary text, optional trailing secondary
-- text. Replaces 3 independently-built row patterns (friends list, map list, settings)
-- plus tracker.lua's pooled match-history rows. Callers set row.primaryText/.secondaryText
-- content and row.icon's texture per-row when reusing pooled instances.
local function CreateListRow(parent, opts)
    opts = opts or {}
    local height = opts.height or 26
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(height)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.06)
    highlight:SetBlendMode("ADD")
    row.highlight = highlight

    local leftAnchor = 6
    if opts.showIcon then
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(opts.iconSize or 16, opts.iconSize or 16)
        icon:SetPoint("LEFT", 4, 0)
        row.icon = icon
        leftAnchor = (opts.iconSize or 16) + 10
    end

    local primary = row:CreateFontString(nil, "OVERLAY")
    primary:SetFont(ADDON_FONT, opts.fontSize or 12)
    primary:SetPoint("LEFT", leftAnchor, 0)
    primary:SetTextColor(unpack(activeTheme.normalText))
    row.primaryText = primary
    table.insert(themedElements, {primary, function(fs)
        if not fs._hasInlineColor then fs:SetTextColor(unpack(activeTheme.normalText)) end
    end})

    if opts.showSecondary then
        local secondary = row:CreateFontString(nil, "OVERLAY")
        secondary:SetFont(ADDON_FONT, (opts.fontSize or 12) - 1)
        secondary:SetPoint("RIGHT", -6, 0)
        secondary:SetTextColor(unpack(activeTheme.footerColor))
        row.secondaryText = secondary
        primary:SetPoint("RIGHT", secondary, "LEFT", -6, 0)
        table.insert(themedElements, {secondary, function(fs) fs:SetTextColor(unpack(activeTheme.footerColor)) end})
    end

    return row
end

-- Themed checkbox: square + accent checkmark + optional label, purely visual (no
-- SavedVariables coupling, unlike the Settings-panel-local checkbox this generalizes).
-- Replaces both that hand-drawn implementation and the un-restyled native
-- UICheckButtonTemplate used for the tournament-rules toggle in core.lua/dock.lua.
local function CreateThemedCheckbox(parent, opts)
    opts = opts or {}
    local size = opts.size or 20
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(size, size)

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(activeTheme.inputBg))

    local border = cb:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(unpack(activeTheme.inputBorder))

    local check = cb:CreateTexture(nil, "ARTWORK")
    check:SetSize(size - 6, size - 6)
    check:SetPoint("CENTER")
    check:SetColorTexture(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 0.9)
    check:Hide()
    cb._check = check

    table.insert(themedElements, {cb, function()
        bg:SetColorTexture(unpack(activeTheme.inputBg))
        border:SetColorTexture(unpack(activeTheme.inputBorder))
        check:SetColorTexture(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 0.9)
    end})

    if opts.label then
        local label = cb:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, opts.labelSize or 11)
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        label:SetText(opts.label)
        label:SetTextColor(unpack(activeTheme.normalText))
        cb._label = label
        table.insert(themedElements, {label, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})
    end

    if opts.checked then
        cb:SetChecked(true)
        check:Show()
    end

    cb:HookScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        check:SetShown(checked)
        if opts.onChange then opts.onChange(checked) end
    end)

    return cb
end

-- Toggle switch (Tournament Rules / Spectator Mode / Settings toggles). WoW textures
-- can't do CSS border-radius, so this is a rectangular track+knob rather than a true
-- pill — the same simplification the rest of this flat-styled addon already makes
-- everywhere else (FLAT_BACKDROP itself is a plain 1px-bordered rectangle).
local function CreateToggleSwitch(parent, opts)
    opts = opts or {}
    local w, h = opts.width or 30, opts.height or 16
    local sw = CreateFrame("Button", nil, parent)
    sw:SetSize(w, h)

    local track = sw:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()

    local knobSize = h - 4
    local knob = sw:CreateTexture(nil, "ARTWORK")
    knob:SetSize(knobSize, knobSize)

    sw._checked = opts.checked and true or false

    local function Repaint()
        if sw._checked then
            track:SetColorTexture(unpack(activeTheme.accent))
            knob:SetColorTexture(1, 1, 1, 1)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", sw, "RIGHT", -2, 0)
        else
            track:SetColorTexture(unpack(activeTheme.cardBorder))
            knob:SetColorTexture(activeTheme.footerColor[1], activeTheme.footerColor[2], activeTheme.footerColor[3], 1)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", sw, "LEFT", 2, 0)
        end
    end
    Repaint()
    table.insert(themedElements, {sw, Repaint})

    sw:SetScript("OnClick", function()
        sw._checked = not sw._checked
        Repaint()
        if opts.onChange then opts.onChange(sw._checked) end
    end)

    function sw:SetChecked(v)
        sw._checked = v and true or false
        Repaint()
    end
    function sw:GetChecked() return sw._checked end

    return sw
end

-- Horizontal row of pill segments where the active one gets a solid accent fill (the
-- mode selector's Arena/Battlegrounds and 2v2/3v3/5v5/Shuffle rows) — distinct from
-- CreateTabStrip's underline-indicator style, which is for page/panel navigation.
local function CreateSegmentedControl(parent, segments, opts)
    opts = opts or {}
    local height = opts.height or 24
    local padX = opts.padX or 14
    local spacing = opts.spacing or 6
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetHeight(height)

    local buttons = {}

    local fontSize = opts.fontSize or 12
    local function SetActive(key)
        for _, b in ipairs(buttons) do
            local isActive = (b.key == key)
            if isActive then
                b:SetBackdropColor(unpack(activeTheme.accent))
                b:SetBackdropBorderColor(unpack(activeTheme.accent))
                -- Dark text, no outline: readable on every accent (the light cyan
                -- washed out white text; the outline muddied dark text).
                b.label:SetFont(ADDON_FONT, fontSize, "")
                b.label:SetTextColor(unpack(activeTheme.backdropBg))
            else
                b:SetBackdropColor(0, 0, 0, 0)
                b:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
                b.label:SetFont(ADDON_FONT, fontSize, "OUTLINE")
                b.label:SetTextColor(unpack(activeTheme.footerColor))
            end
        end
        strip.activeKey = key
    end

    local prev
    local totalW = 0
    for _, def in ipairs(segments) do
        local b = CreateFrame("Button", nil, strip, "BackdropTemplate")
        b.key = def.key

        local label = b:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, opts.fontSize or 12, "OUTLINE")
        label:SetPoint("CENTER")
        label:SetText(def.label)
        b.label = label

        local bw = math.max(30, label:GetStringWidth() + padX * 2)
        b:SetSize(bw, height)
        b:SetBackdrop(FLAT_BACKDROP)

        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
            totalW = totalW + spacing + bw
        else
            b:SetPoint("LEFT", strip, "LEFT", 0, 0)
            totalW = bw
        end
        b:SetScript("OnClick", function()
            SetActive(def.key)
            if opts.onSelect then opts.onSelect(def.key) end
        end)

        table.insert(buttons, b)
        prev = b
    end

    strip:SetWidth(math.max(1, totalW))
    strip.buttons = buttons
    -- Method form (colon call): callers do strip:SetActiveSegment(key); the wrapper
    -- swallows `self` so the inner SetActive still gets just the key string.
    function strip:SetActiveSegment(key) SetActive(key) end
    table.insert(themedElements, {strip, function() SetActive(strip.activeKey) end})
    if segments[1] then SetActive(segments[1].key) end

    return strip
end

-- Map picker tile: real map art (the addon's existing loading-screen textures, cropped)
-- with a darkening overlay for label legibility, a favorite-star corner badge, and a
-- selected-state accent border. Replaces the flat text-row map list for the Challenge
-- panel's map section.
local function CreateMapTile(parent, opts)
    opts = opts or {}
    local w, h = opts.width or 100, opts.height or 60
    local tile = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tile:SetSize(w, h)
    tile:SetBackdrop(FLAT_BACKDROP)
    tile:SetBackdropColor(unpack(activeTheme.cardBg))
    tile:SetBackdropBorderColor(unpack(activeTheme.cardBorder))

    local art = tile:CreateTexture(nil, "ARTWORK")
    art:SetPoint("TOPLEFT", 1, -1)
    art:SetPoint("BOTTOMRIGHT", -1, 1)
    art:SetTexCoord(0.08, 0.92, 0.15, 0.85)
    art:Hide()
    tile._art = art

    local shade = tile:CreateTexture(nil, "OVERLAY")
    shade:SetAllPoints(art)
    shade:SetColorTexture(0, 0, 0, 0.4)
    shade:Hide()
    tile._shade = shade

    local label = tile:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT, opts.fontSize or 10)
    label:SetPoint("BOTTOMLEFT", 5, 4)
    label:SetPoint("BOTTOMRIGHT", -18, 4)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetTextColor(1, 1, 1, 1)
    tile._label = label

    local star = tile:CreateTexture(nil, "OVERLAY")
    star:SetSize(12, 12)
    star:SetPoint("TOPRIGHT", -4, -4)
    star:SetAtlas("PetJournal-FavoritesIcon")
    star:Hide()
    tile._star = star

    -- Banned/picked state wash (drawn over the art, under the label)
    local tint = tile:CreateTexture(nil, "ARTWORK", nil, 2)
    tint:SetPoint("TOPLEFT", 1, -1)
    tint:SetPoint("BOTTOMRIGHT", -1, 1)
    tint:Hide()
    tile._tint = tint

    local bannedX = tile:CreateFontString(nil, "OVERLAY")
    bannedX:SetFont(ADDON_FONT, (opts.height and opts.height * 0.4) or 22, "OUTLINE")
    bannedX:SetPoint("CENTER")
    bannedX:SetText("X")
    bannedX:SetTextColor(1, 0.36, 0.36, 1)
    bannedX:Hide()
    tile._bannedX = bannedX

    -- Crisp 2px accent selection outline. The 1px backdrop border was easy to mistake
    -- for a clipped edge; these four thin OVERLAY strips read clearly as "selected".
    local selEdges = {}
    local function edge(p1, p2, dim)
        local t = tile:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetPoint(p1, 0, 0)
        t:SetPoint(p2, 0, 0)
        if dim == "h" then t:SetHeight(2) else t:SetWidth(2) end
        t:Hide()
        selEdges[#selEdges + 1] = t
    end
    edge("TOPLEFT", "TOPRIGHT", "h")
    edge("BOTTOMLEFT", "BOTTOMRIGHT", "h")
    edge("TOPLEFT", "BOTTOMLEFT", "v")
    edge("TOPRIGHT", "BOTTOMRIGHT", "v")
    tile._selEdges = selEdges

    -- Precedence: banned > picked > selected > dimmed > normal. All state setters
    -- flip a flag then re-run this so the ordering lives in exactly one place.
    function tile:_ApplyVisual()
        local border = activeTheme.cardBorder
        if self._banned then
            self._tint:SetColorTexture(0.78, 0.08, 0.08, 0.30)
            self._tint:Show()
            self._bannedX:Show()
            border = activeTheme.cardBorder
        elseif self._picked then
            local pr, pg, pb = HexToRGB(activeTheme.inlineGreen)
            self._tint:SetColorTexture(pr, pg, pb, 0.16)
            self._tint:Show()
            self._bannedX:Hide()
            border = {pr, pg, pb, 1}
        else
            self._tint:Hide()
            self._bannedX:Hide()
            if self._selected then border = activeTheme.accent end
        end
        self:SetBackdropBorderColor(unpack(border))

        local showSel = (self._selected and not self._banned and not self._picked) and true or false
        for _, t in ipairs(self._selEdges) do
            t:SetColorTexture(unpack(activeTheme.accent))
            t:SetShown(showSel)
        end

        local dim = (self._dimmed and not self._banned and not self._picked) and true or false
        if self._art:IsShown() then
            self._art:SetDesaturated(dim)
            self._art:SetVertexColor(dim and 0.5 or 1, dim and 0.5 or 1, dim and 0.5 or 1)
        end
        self._label:SetAlpha(dim and 0.55 or (self._banned and 0.6 or 1))
    end

    function tile:SetMapTexture(texturePath)
        if texturePath then
            art:SetTexture(texturePath)
            art:Show()
            shade:Show()
        else
            art:Hide()
            shade:Hide()
        end
        self:_ApplyVisual()
    end

    function tile:SetSelected(selected)  self._selected = selected or nil; self:_ApplyVisual() end
    function tile:SetFavorite(fav)       self._star:SetShown(fav and true or false) end
    function tile:SetBanned(banned)      self._banned = banned or nil; self:_ApplyVisual() end
    function tile:SetPicked(picked)      self._picked = picked or nil; self:_ApplyVisual() end
    function tile:SetDimmed(dimmed)      self._dimmed = dimmed or nil; self:_ApplyVisual() end

    table.insert(themedElements, {tile, function()
        tile:SetBackdropColor(unpack(activeTheme.cardBg))
        tile:_ApplyVisual()
    end})

    return tile
end

-- Small colored chip/pill with a centered label (faction/bracket/status badges).
-- Promoted from lfg.lua's local CreateChip — was the only file using this pattern.
local function CreateChip(parent, w, h, fontSize)
    local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    c:SetSize(w, h)
    c:SetBackdrop(FLAT_BACKDROP)
    local fs = c:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ADDON_FONT, fontSize or 9, "OUTLINE")
    fs:SetPoint("CENTER")
    c.text = fs
    return c
end

-- Translucent card panel (theme-neutral fill, themed border) used to group related
-- controls. Promoted from lfg.lua's local StyleCard.
local function StyleCard(card)
    if not card.SetBackdrop then Mixin(card, BackdropTemplateMixin) end
    card:SetBackdrop(FLAT_BACKDROP)
    card:SetBackdropColor(1, 1, 1, 0.03)
    card:SetBackdropBorderColor(activeTheme.backdropBorder[1], activeTheme.backdropBorder[2], activeTheme.backdropBorder[3], 0.5)
    table.insert(themedElements, {card, function(c)
        local bb = activeTheme.backdropBorder
        c:SetBackdropBorderColor(bb[1], bb[2], bb[3], 0.5)
    end})
end

-- Faint placeholder text shown inside an EditBox while empty and unfocused.
-- Promoted from lfg.lua's local AddPlaceholder.
local function AddPlaceholder(editBox, text)
    local ph = editBox:CreateFontString(nil, "OVERLAY")
    ph:SetFont(ADDON_FONT, 11)
    ph:SetPoint("LEFT", 8, 0)
    ph:SetText(text)
    ph:SetTextColor(0.5, 0.5, 0.55, 0.7)
    local function UpdateVisibility()
        ph:SetShown(editBox:GetText() == "" and not editBox:HasFocus())
    end
    editBox:HookScript("OnTextChanged", UpdateVisibility)
    editBox:HookScript("OnEditFocusGained", UpdateVisibility)
    editBox:HookScript("OnEditFocusLost", UpdateVisibility)
    UpdateVisibility()
    return ph
end

-- Small draggable popup wrapping an EditBox — for "copy this text" (readOnly, multiline)
-- and short free-text edits (a match note). Promoted/generalized from lfg.lua's
-- ShowCommunityInviteBox. Returns the frame; call frame:Open(text) to show it.
--   opts: title, width, height, multiline (bool), readOnly (bool), onSave(text)
local function CreateTextPopup(opts)
    opts = opts or {}
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(opts.width or 380, opts.height or 160)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    ApplyModernStyle(f)
    if WargamesPlus.ApplyUIScale then WargamesPlus.ApplyUIScale(f) end
    CreateWindowChrome(f, { title = opts.title or "", titleSize = 13, closeSize = 18, draggable = true })

    local edit
    if opts.multiline then
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -34)
        scroll:SetPoint("BOTTOMRIGHT", -28, 12)
        ApplyModernStyle(scroll)
        StyleScrollBar(scroll)
        edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetWidth((opts.width or 380) - 44)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetTextColor(unpack(activeTheme.normalText))
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(edit)
        table.insert(themedElements, {edit, function(e) e:SetTextColor(unpack(activeTheme.normalText)) end})
    else
        edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        edit:SetPoint("TOPLEFT", 14, -38)
        edit:SetPoint("RIGHT", -14, 0)
        edit:SetHeight(24)
        edit:SetAutoFocus(false)
        StyleInput(edit)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        edit:SetScript("OnEnterPressed", function() f:Hide() end)
    end
    f.editBox = edit

    if opts.readOnly then
        -- Block edits but keep selection/copy working.
        edit:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(f._text or "") self:HighlightText() end
        end)
    end

    function f:Open(text)
        f._text = text or ""
        edit:SetText(f._text)
        f:Show()
        edit:SetFocus()
        if opts.readOnly then edit:HighlightText() end
    end

    f:Hide()
    -- Set the save hook only after the initial Hide so creating the popup can't fire it.
    if not opts.readOnly and opts.onSave then
        f:SetScript("OnHide", function() if f._opened then opts.onSave(edit:GetText()) end end)
        f:HookScript("OnShow", function() f._opened = true end)
    end
    return f
end

-- ---------- SHARED NAMESPACE EXPORTS ----------
WargamesPlus.ApplyModernStyle = ApplyModernStyle
WargamesPlus.ApplyCardStyle   = ApplyCardStyle
WargamesPlus.StyleButton      = StyleButton
WargamesPlus.StyleInput       = StyleInput
WargamesPlus.StyleScrollBar   = StyleScrollBar
WargamesPlus.StyleDropdown    = StyleDropdown
WargamesPlus.ADDON_FONT       = ADDON_FONT
WargamesPlus.FLAT_BACKDROP    = FLAT_BACKDROP
WargamesPlus.HexToRGB         = HexToRGB
WargamesPlus.THEMES           = THEMES
WargamesPlus.COLOR_GROUPS     = COLOR_GROUPS
WargamesPlus.ApplyTheme       = ApplyTheme
WargamesPlus.BuildCustomTheme = BuildCustomTheme
WargamesPlus.FACTION_COLORS   = FACTION_COLORS

-- New shared visual primitives (see definitions above)
WargamesPlus.CreateWindowChrome   = CreateWindowChrome
WargamesPlus.CreateProgressBar    = CreateProgressBar
WargamesPlus.CreateTabStrip       = CreateTabStrip
WargamesPlus.CreateListRow        = CreateListRow
WargamesPlus.CreateThemedCheckbox = CreateThemedCheckbox
WargamesPlus.CreateToggleSwitch    = CreateToggleSwitch
WargamesPlus.CreateSegmentedControl = CreateSegmentedControl
WargamesPlus.CreateMapTile         = CreateMapTile
WargamesPlus.CreateChip           = CreateChip
WargamesPlus.CreateTextPopup      = CreateTextPopup
WargamesPlus.StyleCard            = StyleCard
WargamesPlus.AddPlaceholder       = AddPlaceholder

-- Internal registry tables, shared by reference with core.lua/tracker.lua/etc. so their
-- existing inline `table.insert(themedElements, ...)` call-sites keep working unchanged.
WargamesPlus._themedBackdrops = themedBackdrops
WargamesPlus._themedButtons   = themedButtons
WargamesPlus._themedInputs    = themedInputs
WargamesPlus._themedElements  = themedElements
WargamesPlus._themedDropdowns = themedDropdowns

function WargamesPlus.GetActiveTheme() return activeTheme end
function WargamesPlus.RegisterThemedElement(frame, applyFn)
    table.insert(themedElements, {frame, applyFn})
end

-- ---------- UI SCALE ----------
-- WG_History.uiScale is a percent (default 110). Top-level windows parented to UIParent
-- call ApplyUIScale after creation; the ones parented to the main frame inherit its
-- scale automatically, so they must NOT call this. RefreshUIScale re-applies live.
local scaledFrames = setmetatable({}, { __mode = "k" })
function WargamesPlus.ApplyUIScale(frame)
    if not frame then return end
    scaledFrames[frame] = true
    frame:SetScale(((WG_History and WG_History.uiScale) or 100) / 100)
end
function WargamesPlus.RefreshUIScale()
    local s = ((WG_History and WG_History.uiScale) or 100) / 100
    for f in pairs(scaledFrames) do
        if f and f.SetScale then f:SetScale(s) end
    end
end
