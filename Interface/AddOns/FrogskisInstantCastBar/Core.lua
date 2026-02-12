-- ========================
-- Frogski’s Instant Cast Bar
--
-- This addon is a resurrection of my old WeakAura https://wago.io/-iMgHlW6n from Friday, October 4th 2024, 12:12 pm
-- 
--
-- My CurseForge profile:
-- https://www.curseforge.com/members/frogski/projects
-- ========================
--
-- ========================
-- Casting helpers
-- ========================
local function IsDruidFlightForm()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        return false
    end
    if GetShapeshiftForm() ~= 3 then
        return false
    end
    if IsFlying and IsFlying() then
        return true
    end
    return false
end

local function IsPlayerCastingOrChanneling()
    local name, _, _, startTime, endTime = UnitCastingInfo("player")
    if not name then
        name, _, _, startTime, endTime = UnitChannelInfo("player")
    end
    return (name and startTime and endTime and endTime > startTime)
end

-- ===========
-- Test
-- ===========
-- local test = false
-- local function TestPrintGCD(label, gcd)
--    if not test then
--       return
--    end
--    print(string.format("%s %.3fs", label or "?", gcd or 0))
-- end

-- ========================
-- Apply haste to GCD
-- ========================

local function ApplyHasteToGCD(base)
    local hastePercent = GetHaste() or 0
    local haste = hastePercent / 100
    local gcd = base / (1 + haste)
    if gcd < 1.0 then
        gcd = 1.0
    end

    return gcd
end

-- ========================
-- Account-wide 
-- ========================
FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
-- ========================
-- First-run defaults seeding
-- ========================
local function SeedDefaultsIfEmpty()
    FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
    FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
    FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}
    if next(FrogskiInstantCastBarDB.overwrites) == nil then
        FrogskiInstantCastBarDB.overwrites[188196] = {
            base = 1.5
        } -- Lightning Bolt
        FrogskiInstantCastBarDB.overwrites[768] = {
            base = 1.0
        } -- Cat Form
        FrogskiInstantCastBarDB.overwrites[452201] = {
            base = 1.5
        } -- Tempest
    end
    local a = FrogskiInstantCastBarDB.appearance

    if a.disableWhileMounted == nil then
        a.disableWhileMounted = false
    end
    if a.disableWhileDruidFlightForm == nil then
        a.disableWhileDruidFlightForm = false
    end

    if a.bgHidden == nil then
        a.bgHidden = false
    end
    if a.textBgHidden == nil then
        a.textBgHidden = false
    end
    if a.borderHidden == nil then
        a.borderHidden = false
    end
    if a.shineHidden == nil then
        a.shineHidden = false
    end
    if a.sparkHidden == nil then
        a.sparkHidden = false
    end
    if a.bgAlpha == nil then
        a.bgAlpha = 1
    end
    if a.textBgAlpha == nil then
        a.textBgAlpha = 1
    end
    if a.borderAlpha == nil then
        a.borderAlpha = 1
    end
    if a.shineAlpha == nil then
        a.shineAlpha = 0.6
    end
    if a.sparkAlpha == nil then
        a.sparkAlpha = 1
    end
end
local function GetOverwrites()
    FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
    FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
    return FrogskiInstantCastBarDB.overwrites
end
local function SetOverwrite(spellID, baseSeconds)
    spellID = tonumber(spellID)
    if not spellID then
        return
    end

    local base = tonumber(baseSeconds)
    if not base then
        return
    end

    local ow = GetOverwrites()
    ow[spellID] = {
        base = base
    }
end

local function GetOverwriteBySpellID(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    return GetOverwrites()[spellID]
end
-- ============================
-- Forbidden secret value blocker
-- ============================
local function IsForbidden(obj)
    return obj and obj.IsForbidden and obj:IsForbidden()
end

local function SafeNumber(v)
    return (type(v) == "number") and v or nil
end

local function SafeGetSize(region)
    if not region or not region.GetWidth or not region.GetHeight then
        return nil, nil
    end
    local w = SafeNumber(region:GetWidth())
    local h = SafeNumber(region:GetHeight())
    return w, h
end
-- ========================
-- No Blizzard reads in combat
-- ========================
local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end
-- =====================
-- no reads in combat
-- ====================
local BLIZZ = {
    cb = nil,
    text = nil,
    textBorder = nil,
    bg = nil
}

local function CacheBlizzardCastbarRegions()
    if InCombat() then
        return
    end
    local cb = _G.PlayerCastingBarFrame or _G.CastingBarFrame
    if not cb or IsForbidden(cb) then
        return
    end
    BLIZZ.cb = cb
    BLIZZ.text = (cb.Text and not IsForbidden(cb.Text)) and cb.Text or nil
    BLIZZ.textBorder = (cb.TextBorder and not IsForbidden(cb.TextBorder)) and cb.TextBorder or nil
    local bg = cb.Background or cb.BG or cb.Bg or cb.BarBackground or cb.BackgroundTexture
    BLIZZ.bg = (bg and not IsForbidden(bg)) and bg or nil
end

local function SanitizeOverwrites()
    local ow = GetOverwrites()
    local cleaned = {}

    for k, v in pairs(ow) do
        local sid = tonumber(k)
        if sid and type(v) == "table" then
            local base = tonumber(v.base)
            if base and base > 20 then
                base = base / 1000
            end
            if base == 0 or base == 1 or base == 1.5 then
                cleaned[sid] = {
                    base = base
                }
            end
        end
    end

    FrogskiInstantCastBarDB.overwrites = cleaned
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    SeedDefaultsIfEmpty()
    SanitizeOverwrites()
    CacheBlizzardCastbarRegions()
end)

local function GetCastbar_Safe()
    if InCombat() then
        return nil
    end
    local cb = _G.PlayerCastingBarFrame or _G.CastingBarFrame
    if not cb or IsForbidden(cb) then
        return nil
    end
    return cb
end

-- =========================
-- Elements to be turned off
-- =========================
FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}

local function GetAppearance()
    FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
    FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}

    local a = FrogskiInstantCastBarDB.appearance

    if a.bgAlpha == nil then
        a.bgAlpha = 1
    end
    if a.bgHidden == nil then
        a.bgHidden = false
    end

    if a.textBgAlpha == nil then
        a.textBgAlpha = 1
    end
    if a.textBgHidden == nil then
        a.textBgHidden = false
    end

    if a.borderAlpha == nil then
        a.borderAlpha = 1
    end
    if a.borderHidden == nil then
        a.borderHidden = false
    end

    if a.shineAlpha == nil then
        a.shineAlpha = 0.6
    end
    if a.shineHidden == nil then
        a.shineHidden = false
    end

    if a.sparkAlpha == nil then
        a.sparkAlpha = 1
    end
    if a.sparkHidden == nil then
        a.sparkHidden = false
    end
    if a.disableWhileMounted == nil then
        a.disableWhileMounted = false
    end
    if a.disableWhileDruidFlightForm == nil then
        a.disableWhileDruidFlightForm = false
    end
    return a
end

-- ========================
-- Instantcast Bar positioning
-- ========================
local function GetCastbar()
    return GetCastbar_Safe()
end
local f = CreateFrame("Frame", "FrogskisInstantBarFrame", UIParent)
f:Hide()
f:SetToplevel(true)
f._castbar_left, f._castbar_bottom, f._castbar_w, f._castbar_h = nil, nil, nil, nil
local function GetCastbarGeometry()
    local CASTBAR = GetCastbar()
    if not CASTBAR or not CASTBAR.GetLeft or not CASTBAR:IsObjectType("Frame") then
        return false
    end
    local left, bottom = CASTBAR:GetLeft(), CASTBAR:GetBottom()
    local w, h = SafeGetSize(CASTBAR)
    if not left or not bottom or not w or not h or w <= 0 or h <= 0 then
        return false
    end
    local sCB = CASTBAR:GetEffectiveScale() or 1
    local sUI = UIParent:GetEffectiveScale() or 1
    local scale = sCB / sUI
    f._castbar_left = left * scale
    f._castbar_bottom = bottom * scale
    f._castbar_w = w * scale
    f._castbar_h = h * scale
    return true
end
local function ApplySavedGeometry()
    if not f._castbar_left then
        return false
    end
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", f._castbar_left, f._castbar_bottom)
    f:SetSize(f._castbar_w, f._castbar_h)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(20)
    return true
end

local function ApplyToCastbarNow()
    if InCombat() then
        return ApplySavedGeometry()
    end
    if GetCastbarGeometry() then
        ApplySavedGeometry()
        return true
    end
    return false
end

local syncEv = CreateFrame("Frame")
syncEv:RegisterEvent("PLAYER_ENTERING_WORLD")
syncEv:RegisterEvent("UI_SCALE_CHANGED")
syncEv:RegisterEvent("DISPLAY_SIZE_CHANGED")
syncEv:SetScript("OnEvent", function()
    ApplyToCastbarNow()
end)

if not ApplyToCastbarNow() then
    f:SetSize(209, 11)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(20)
end
local function SyncBarToBlizzard()
    if InCombat() then
        return
    end
    if not GetCastbarGeometry() then
        return
    end
    if not GetCastbarGeometry() then
        return
    end

    local left, bottom, w, h = f._castbar_left, f._castbar_bottom, f._castbar_w, f._castbar_h
    if not left or not bottom or not w or not h then
        return
    end

    if f._applied_left ~= left or f._applied_bottom ~= bottom or f._applied_w ~= w or f._applied_h ~= h then
        f._applied_left, f._applied_bottom, f._applied_w, f._applied_h = left, bottom, w, h
        ApplySavedGeometry()
    end
end

local function HookBlizzardGeometrySync()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiGeometrySynced then
        return
    end
    cb.__FrogskiGeometrySynced = true

    cb:HookScript("OnShow", SyncBarToBlizzard)
    cb:HookScript("OnSizeChanged", SyncBarToBlizzard)
end

HookBlizzardGeometrySync()
SyncBarToBlizzard()
f:HookScript("OnShow", SyncBarToBlizzard)

-- ========================
-- Drawing textures 
-- ========================

-- 1) Bar Background 
local BG_SCALE_X = 1.01
local BG_SCALE_Y = 1.25
local bgHolder = CreateFrame("Frame", nil, f)
bgHolder:SetPoint("CENTER", f, "CENTER", 0, 0)
bgHolder:SetFrameLevel(f:GetFrameLevel())

local function UpdateBgHolder()
    local w, h = f:GetSize()
    if not w or not h or w <= 1 or h <= 1 then
        return
    end
    bgHolder:SetSize(w * BG_SCALE_X, h * BG_SCALE_Y)
end
f:HookScript("OnSizeChanged", UpdateBgHolder)
f:HookScript("OnShow", UpdateBgHolder)
UpdateBgHolder()
local bg = bgHolder:CreateTexture(nil, "BACKGROUND", nil, 0)
bg:SetAllPoints(bgHolder)
bg:SetAtlas("UI-CastingBar-Background", true)
local bgBright = bgHolder:CreateTexture(nil, "BACKGROUND", nil, 1)
bgBright:SetAllPoints(bgHolder)
bgBright:SetAtlas("UI-CastingBar-Background", true)
bgBright:SetVertexColor(1, 1, 1)
bgBright:SetAlpha(1)

-- 2) Spell Text backdrop 
local textBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
textBg:SetAtlas("UI-CastingBar-TextBox", true)
f._textBgBlizzardAlpha = 1

-- 2.1) TextBox holder 
local textBgHolder = CreateFrame("Frame", nil, f)
textBgHolder:SetFrameLevel(f:GetFrameLevel())
textBgHolder:SetPoint("CENTER", f, "CENTER", 0, 0)
textBg:ClearAllPoints()
textBg:SetAllPoints(textBgHolder)

local function SyncTextBgToBlizzard()
    if InCombat() then
        return
    end
    local cb = GetCastbar()
    if not cb then
        return
    end
    local tb = cb.TextBorder
    if not tb or IsForbidden(tb) then
        textBg:Hide()
        textBgHolder:Hide()
        f._textBgBlizzardAlpha = 0
        if ApplyAppearance then
            ApplyAppearance()
        end
        return
    end

    f._textBgBlizzardAlpha = (tb.GetAlpha and tb:GetAlpha()) or 1

    textBg:Show()
    textBgHolder:Show()

    local w, h = SafeGetSize(tb)
    if not w or not h or w <= 0 or h <= 0 then
        return
    end

    local sSrc = tb:GetEffectiveScale() or 1
    local sDst = textBgHolder:GetEffectiveScale() or 1
    local scale = sSrc / sDst
    textBgHolder:SetSize(w * scale, h * scale)
    local cbx, cby = cb:GetCenter()
    local tbx, tby = tb:GetCenter()
    if cbx and cby and tbx and tby then
        local dx = (tbx - cbx) * ((cb:GetEffectiveScale() or 1) / (f:GetEffectiveScale() or 1))
        local dy = (tby - cby) * ((cb:GetEffectiveScale() or 1) / (f:GetEffectiveScale() or 1))
        textBgHolder:ClearAllPoints()
        textBgHolder:SetPoint("CENTER", f, "CENTER", dx, dy)
    else
        textBgHolder:ClearAllPoints()
        textBgHolder:SetPoint("CENTER", f, "CENTER", 0, 0)
    end

    if ApplyAppearance then
        ApplyAppearance()
    end
end

local function HookBlizzardTextBorderSync()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiTextBorderSynced then
        return
    end
    cb.__FrogskiTextBorderSynced = true

    cb:HookScript("OnShow", SyncTextBgToBlizzard)
    cb:HookScript("OnSizeChanged", SyncTextBgToBlizzard)

end
HookBlizzardTextBorderSync()
SyncTextBgToBlizzard()
f:HookScript("OnShow", SyncTextBgToBlizzard)
f:HookScript("OnSizeChanged", SyncTextBgToBlizzard)

-- 3) Filling bar texture
local bar = CreateFrame("StatusBar", nil, f)
bar:SetAllPoints(true)
bar:SetStatusBarTexture("UI-CastingBar-Filling-ApplyingCrafting", "atlas")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
bar:SetFrameLevel(f:GetFrameLevel() + 1)

-- 3.25) Border holder
local borderHolder = CreateFrame("Frame", nil, f)
borderHolder:SetFrameLevel(f:GetFrameLevel() + 4)
borderHolder:SetPoint("CENTER", f, "CENTER")
local function SyncBorderHolderToBlizzard()
    if InCombat() then
        return
    end
    local cb = GetCastbar()
    if not cb or not cb.Border or IsForbidden(cb.Border) then
        return
    end

    local bw, bh = SafeGetSize(cb.Border)
    if not bw or not bh or bw <= 0 or bh <= 0 then
        return
    end
    local sSrc = cb.Border:GetEffectiveScale() or 1
    local sDst = borderHolder:GetEffectiveScale() or 1
    local scale = sSrc / sDst

    borderHolder:SetSize(bw * scale, bh * scale)
end

local function HookBlizzardBorderSync()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiBorderSynced then
        return
    end
    cb.__FrogskiBorderSynced = true

    cb:HookScript("OnShow", SyncBorderHolderToBlizzard)
    cb:HookScript("OnSizeChanged", SyncBorderHolderToBlizzard)

end
HookBlizzardBorderSync()
SyncBorderHolderToBlizzard()
f:HookScript("OnShow", SyncBorderHolderToBlizzard)
f:HookScript("OnSizeChanged", SyncBorderHolderToBlizzard)

-- 3.5) Shine 
local shineHolder = CreateFrame("Frame", nil, f)
shineHolder:SetAllPoints(f)
shineHolder:SetFrameLevel(bar:GetFrameLevel() + 2)
local shine = shineHolder:CreateTexture(nil, "ARTWORK", nil, 0)
shine:SetAtlas("Cast_Standard_PipGlow", true)
shine:SetBlendMode("ADD")
shine:SetAlpha(0.6)
shine:SetVertexColor(1, 1, 1)
shine:ClearAllPoints()
shine:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
shine:SetPoint("CENTER", f, "CENTER", 0, 0)
local SHINE_W_MULT = 0.15
local SHINE_H_MULT = 1
local shineBaseW, shineBaseH = 0, 0
local function UpdateShineBaseSize()
    local w, h = f:GetSize()
    if not w or not h or w <= 0 or h <= 0 then
        return
    end
    shineBaseW = w * SHINE_W_MULT
    shineBaseH = h * SHINE_H_MULT
    shine:SetHeight(shineBaseH)
end
f:HookScript("OnSizeChanged", UpdateShineBaseSize)
f:HookScript("OnShow", UpdateShineBaseSize)
UpdateShineBaseSize()

local function UpdateShineTrim()
    local fillTex = bar:GetStatusBarTexture()
    if not fillTex then
        return
    end
    local fillW = SafeNumber(fillTex:GetWidth())

    if not fillW or fillW <= 0 then
        shine:SetWidth(0)
        return
    end
    local w = shineBaseW
    if fillW < w then
        w = fillW
    end
    shine:SetWidth(w)
end
f._UpdateShineTrim = UpdateShineTrim

-- ======================================================
-- follow Blizzard ONLY if Blizzard border is not default
-- ======================================================

local DEFAULT_BORDER_ATLAS = "UI-CastingBar-Frame"

local function IsBlizzardBorderDefault()
    local cb = GetCastbar()
    if not cb or not cb.Border or IsForbidden(cb.Border) or not cb.Border.GetAtlas then
        return false
    end
    local atlas = cb.Border:GetAtlas()
    return atlas == DEFAULT_BORDER_ATLAS
end
local function CopyBorderStyle(src, dst)
    if not src or not dst then
        return
    end
    if src.GetAtlas then
        local atlas = src:GetAtlas()
        if atlas and atlas ~= "" then
            dst:SetAtlas(atlas, true)
        end
    end
    if src.GetTexture then
        local tex = src:GetTexture()
        if tex then
            dst:SetTexture(tex)
        end
    end
    if src.GetTexCoord and dst.SetTexCoord then
        dst:SetTexCoord(src:GetTexCoord())
    end
    if src.GetVertexColor and dst.SetVertexColor then
        local r, g, b, a = src:GetVertexColor()
        dst:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    end
    if src.GetAlpha and dst.SetAlpha then
        dst:SetAlpha(src:GetAlpha() or 1)
    end
    if src.GetDrawLayer and dst.SetDrawLayer then
        local layer, sub = src:GetDrawLayer()
        if layer then
            dst:SetDrawLayer(layer, sub)
        end
    end
    if src.GetBlendMode and dst.SetBlendMode then
        dst:SetBlendMode(src:GetBlendMode())
    end
end

-- 4) Border
local border = borderHolder:CreateTexture(nil, "ARTWORK", nil, 0)
border:SetAllPoints(borderHolder)
border:SetAtlas(DEFAULT_BORDER_ATLAS, true)

local _lastCustomBorderKey

local function SyncBorderToBlizzardOnlyIfCustom()
    if InCombat() then
        return
    end

    local cb = GetCastbar()
    if not cb or not cb.Border or IsForbidden(cb.Border) then
        return
    end

    if IsBlizzardBorderDefault() then
        _lastCustomBorderKey = nil
        if ApplyAppearance then
            ApplyAppearance()
        end
        return
    end

    local src = cb.Border
    local key = tostring(src)
    if src.GetAtlas then
        key = key .. "|A:" .. tostring(src:GetAtlas())
    end
    if src.GetTexture then
        key = key .. "|T:" .. tostring(src:GetTexture())
    end

    if key ~= _lastCustomBorderKey then
        CopyBorderStyle(src, border)
        _lastCustomBorderKey = key
        if ApplyAppearance then
            ApplyAppearance()
        end
    end
end

local function HookBlizzardBorderOnlyIfCustom()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiBorderOnlyIfCustomHooked then
        return
    end
    cb.__FrogskiBorderOnlyIfCustomHooked = true

    cb:HookScript("OnShow", SyncBorderToBlizzardOnlyIfCustom)
    cb:HookScript("OnSizeChanged", SyncBorderToBlizzardOnlyIfCustom)

end

HookBlizzardBorderOnlyIfCustom()
SyncBorderToBlizzardOnlyIfCustom()
f:HookScript("OnShow", SyncBorderToBlizzardOnlyIfCustom)

-- border:SetVertexColor(0.9, 0.9, 0.9)
-- Border Glow
-- local glow = borderHolder:CreateTexture(nil, "OVERLAY", nil, 1)
-- glow:SetAllPoints(borderHolder)
-- glow:SetAtlas("UI-CastingBar-Full-Glow-ApplyingCrafting", true)
-- glow:SetAlpha(0)

-- ===================
-- 5) Spell name text
-- ====================

local txtHolder = CreateFrame("Frame", nil, f)
txtHolder:SetFrameLevel(f:GetFrameLevel() + 10)
txtHolder:SetPoint("CENTER", textBgHolder, "CENTER", 0, 0)

local txt = txtHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txt:SetAllPoints(txtHolder)
txt:SetText("")

local function SyncTxtHolderToBlizzard()
    if InCombat() then
        return
    end
    local cb = GetCastbar()
    if not cb or not cb.Text then
        return
    end
    local src = cb.Text
    if not src or IsForbidden(src) then
        return
    end

    local w = SafeNumber(src:GetWidth())
    local h = SafeNumber(src:GetHeight())
    if w and h and w > 0 and h > 0 then
        local sSrc = src:GetEffectiveScale() or 1
        local sDst = txtHolder:GetEffectiveScale() or 1
        txtHolder:SetSize((w * sSrc) / sDst, (h * sSrc) / sDst)
    end

    txtHolder:ClearAllPoints()
    local p, rel, rp, x, y = src:GetPoint(1)
    if not p or not rel or not rp then
        txtHolder:SetPoint("CENTER", f, "CENTER", 0, 0)
        return
    end
    x = x or 0
    y = y or 0
    local origRel = rel
    if rel == cb then
        rel = f
    elseif cb.TextBorder and rel == cb.TextBorder then
        rel = textBgHolder
    end
    if rel ~= origRel then
        local sFrom = origRel:GetEffectiveScale() or 1
        local sTo = rel:GetEffectiveScale() or 1
        local k = sFrom / sTo
        x = x * k
        y = y * k
    end
    txtHolder:SetPoint(p, rel, rp, x, y)
end

local function HookBlizzardTextRegionSync()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiTextRegionSynced then
        return
    end
    cb.__FrogskiTextRegionSynced = true
    cb:HookScript("OnShow", SyncTxtHolderToBlizzard)
    cb:HookScript("OnSizeChanged", SyncTxtHolderToBlizzard)

end

HookBlizzardTextRegionSync()
SyncTxtHolderToBlizzard()
f:HookScript("OnShow", SyncTxtHolderToBlizzard)
f:HookScript("OnSizeChanged", SyncTxtHolderToBlizzard)

-- 5.2) Sync style from Blizzard cast bar 1:1
local function CopyFontStringStyle(src, dst)
    if not src or not dst then
        return
    end
    local sSrc = src:GetEffectiveScale() or 1
    local sDst = dst:GetEffectiveScale() or 1
    local scale = sSrc / sDst
    local font, size, flags = src:GetFont()
    if font and size then
        dst:SetFont(font, size * scale, flags)
    end
    local r, g, b, a = src:GetTextColor()
    if r then
        dst:SetTextColor(r, g, b, a)
    end
    local sr, sg, sb, sa = src:GetShadowColor()
    if sr then
        dst:SetShadowColor(sr, sg, sb, sa)
    end
    local sx, sy = src:GetShadowOffset()
    if sx and sy then
        local sSrc = src:GetEffectiveScale() or 1
        local sDst = dst:GetEffectiveScale() or 1
        local px = sx * sSrc
        local py = sy * sSrc
        local pxSnap = (px >= 0) and math.floor(px + 0.5) or math.ceil(px - 0.5)
        local pySnap = (py >= 0) and math.floor(py + 0.5) or math.ceil(py - 0.5)
        pySnap = pySnap + 0.5
        dst:SetShadowOffset(pxSnap / sDst, pySnap / sDst)
    end
    if src.GetJustifyH and dst.SetJustifyH then
        dst:SetJustifyH(src:GetJustifyH())
    end
    if src.GetJustifyV and dst.SetJustifyV then
        dst:SetJustifyV(src:GetJustifyV())
    end
    if src.GetSpacing and dst.SetSpacing then
        dst:SetSpacing(src:GetSpacing())
    end
end
local _lastFont, _lastSize, _lastFlags
local _lastTR, _lastTG, _lastTB, _lastTA
local _lastSX, _lastSY
local _lastSR, _lastSG, _lastSB, _lastSA
local _lastSrcScale, _lastDstScale

local function SyncTxtToBlizzard()
    if InCombat() then
        return
    end
    local cb = GetCastbar()
    if not cb or not cb.Text or not cb.Text.GetFont then
        return
    end
    local src = cb.Text
    local font, size, flags = src:GetFont()
    local tr, tg, tb, ta = src:GetTextColor()
    local sx, sy = src:GetShadowOffset()
    local sr, sg, sb, sa = src:GetShadowColor()
    local srcScale = src:GetEffectiveScale() or 1
    local dstScale = txt:GetEffectiveScale() or 1
    if font ~= _lastFont or size ~= _lastSize or flags ~= _lastFlags or tr ~= _lastTR or tg ~= _lastTG or tb ~= _lastTB or
        ta ~= _lastTA or sx ~= _lastSX or sy ~= _lastSY or sr ~= _lastSR or sg ~= _lastSG or sb ~= _lastSB or sa ~=
        _lastSA or srcScale ~= _lastSrcScale or dstScale ~= _lastDstScale then
        CopyFontStringStyle(src, txt)
        SyncTxtHolderToBlizzard()
        _lastFont, _lastSize, _lastFlags = font, size, flags
        _lastTR, _lastTG, _lastTB, _lastTA = tr, tg, tb, ta
        _lastSX, _lastSY = sx, sy
        _lastSR, _lastSG, _lastSB, _lastSA = sr, sg, sb, sa
        _lastSrcScale, _lastDstScale = srcScale, dstScale
    end
end

local function HookBlizzardTextStyleSync()
    local cb = GetCastbar()
    if not cb or cb.__FrogskiTextStyleSynced then
        return
    end
    cb.__FrogskiTextStyleSynced = true
    cb:HookScript("OnShow", SyncTxtToBlizzard)
    cb:HookScript("OnSizeChanged", SyncTxtToBlizzard)

end

HookBlizzardTextStyleSync()
SyncTxtToBlizzard()
f:HookScript("OnShow", SyncTxtToBlizzard)
f:HookScript("OnSizeChanged", SyncTxtToBlizzard)

-- 6) Spark holder
local sparkHolder = CreateFrame("Frame", nil, f)
sparkHolder:SetAllPoints(f)
sparkHolder:SetFrameLevel(borderHolder:GetFrameLevel() + 5)

-- 6.1) Spark
local sparkCore = sparkHolder:CreateTexture(nil, "OVERLAY", nil, 6)
sparkCore:SetAtlas("UI-CastingBar-Pip", true)
sparkCore:SetBlendMode("ADD")
sparkCore:ClearAllPoints()
sparkCore:SetPoint("LEFT", bar, "RIGHT", 0, 0)
sparkCore:SetDesaturated(true)
sparkCore:SetVertexColor(0.2, 0.5, 0.6)

-- 7) Spark glow
local sparkGlow = sparkHolder:CreateTexture(nil, "OVERLAY", nil, 7)
sparkGlow:SetAtlas("UI-CastingBar-Pip", true)
sparkGlow:SetBlendMode("ADD")
sparkGlow:SetAlpha(0.2)
sparkGlow:ClearAllPoints()
sparkGlow:SetPoint("CENTER", sparkCore, "CENTER", 0, 0)
sparkGlow:SetDesaturated(true)
sparkGlow:SetVertexColor(0.4, 0.7, 1.0)
sparkCore:Show()
sparkGlow:Show()
local SPARK_W_MULT = 0.7
local SPARK_H_MULT = 1.8
local BASE_BAR_HEIGHT = 11
local DIMIRETURN = 0.85
local function UpdateSparkSize()
    local h = f:GetHeight()
    if not h or h <= 0 then
        return
    end
    local scale = (h / BASE_BAR_HEIGHT) ^ DIMIRETURN
    local w = math.max(3, math.floor((BASE_BAR_HEIGHT * SPARK_W_MULT) * scale + 0.5))
    local ph = math.max(6, math.floor((BASE_BAR_HEIGHT * SPARK_H_MULT) * scale + 0.5))
    sparkCore:SetSize(w, ph)
    sparkGlow:SetSize(w, ph)
end
f:HookScript("OnSizeChanged", UpdateSparkSize)
f:HookScript("OnShow", UpdateSparkSize)
UpdateSparkSize()

local function UpdateSparkPosition()
    if not f._active then
        return
    end
    local dur = f._dur or 0
    if dur <= 0 then
        return
    end
    local v = bar:GetValue() or 0
    local frac = v / dur
    local w = f:GetWidth() or 0
    local x = w * frac
    if x < 0 then
        x = 0
    end
    if x > w then
        x = w
    end
    sparkCore:ClearAllPoints()
    sparkCore:SetPoint("CENTER", bar, "LEFT", x + 1, 0)
    sparkGlow:ClearAllPoints()
    sparkGlow:SetPoint("CENTER", sparkCore, "CENTER", 0, 0)
end

-- ========================
-- Apply appearance options
-- ========================
local function ApplyAppearance()
    local a = GetAppearance()

    -- Background 
    if a.bgHidden then
        bgHolder:SetAlpha(0)
        bgHolder:Hide()
    else
        bgHolder:Show()
        bgHolder:SetAlpha(tonumber(a.bgAlpha) or 1)
    end

    -- Text backdrop
    if a.textBgHidden then
        textBg:SetAlpha(0)
        textBg:Hide()
        textBgHolder:Hide()
    else
        textBg:Show()
        textBgHolder:Show()
        local alpha = (tonumber(a.textBgAlpha) or 1) * (f._textBgBlizzardAlpha or 1)
        textBg:SetAlpha(alpha)
    end

    -- Border
    if a.borderHidden then
        border:SetAlpha(0)
        border:Hide()
    else
        border:Show()
        border:SetAlpha(tonumber(a.borderAlpha) or 1)
    end

    -- Shine
    if a.shineHidden then
        shine:SetAlpha(0)
        shine:Hide()
    else
        shine:Show()
        shine:SetAlpha(tonumber(a.shineAlpha) or 0.6)
    end

    -- Spark 
    if a.sparkHidden then
        sparkCore:SetAlpha(0);
        sparkCore:Hide()
        sparkGlow:SetAlpha(0);
        sparkGlow:Hide()
    else
        local sa = tonumber(a.sparkAlpha) or 1
        sparkCore:Show();
        sparkGlow:Show()
        sparkCore:SetAlpha(sa)
        sparkGlow:SetAlpha(sa * 0.2)
    end
end
_G.FrogskiInstantCastBar_ApplyAppearance = ApplyAppearance
ApplyAppearance()

-- =======
-- resync 
-- ======
local _pendingResync = false

local function PerformFullResync()
    if InCombat() then
        _pendingResync = true
        return
    end

    _pendingResync = false

    CacheBlizzardCastbarRegions()
    ApplyToCastbarNow()
    SyncBarToBlizzard()
    SyncTextBgToBlizzard()
    SyncBorderHolderToBlizzard()
    SyncBorderToBlizzardOnlyIfCustom()
    SyncTxtHolderToBlizzard()
    SyncTxtToBlizzard()

    if ApplyAppearance then
        ApplyAppearance()
    end
end
local SetBlizzardCastbarTextShown
local resyncEv = CreateFrame("Frame")
resyncEv:RegisterEvent("PLAYER_LOGIN")
resyncEv:RegisterEvent("PLAYER_ENTERING_WORLD")
resyncEv:RegisterEvent("UI_SCALE_CHANGED")
resyncEv:RegisterEvent("DISPLAY_SIZE_CHANGED")
resyncEv:RegisterEvent("PLAYER_REGEN_ENABLED")
resyncEv:RegisterEvent("PLAYER_REGEN_DISABLED")
resyncEv:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") -- confirmed
resyncEv:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if f._active then
            SetBlizzardCastbarTextShown(false)
        else
            SetBlizzardCastbarTextShown(true)
        end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if _pendingResync then
            PerformFullResync()
        end
        return
    end
    PerformFullResync()
end)

local function HookEditModeClose()
    if not EditModeManagerFrame or EditModeManagerFrame.__FrogskiHooked then
        return
    end
    EditModeManagerFrame.__FrogskiHooked = true
    EditModeManagerFrame:HookScript("OnHide", function()
        PerformFullResync()
    end)
end

HookEditModeClose()
resyncEv:HookScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookEditModeClose()
    end
end)

-- ========================
-- Bar live state core 
-- ========================
local RETRIGGER_AT = 0.80
local OUTRO_HOLD = 0.25
local TEXTBG_SHOWN_ALPHA = 1.0
local TEXTBG_FADE_START = 0.35
local function SetOutroAlpha(a)
    if a < 0 then
        a = 0
    end
    if a > 1 then
        a = 1
    end
    local ap = GetAppearance()
    if ap.borderHidden then
        border:SetAlpha(0)
    else
        border:SetAlpha(a * (tonumber(ap.borderAlpha) or 1))
    end
    if ap.bgHidden then
        bgHolder:SetAlpha(0)
    else
        bgHolder:SetAlpha(a * (tonumber(ap.bgAlpha) or 1))
    end
    txt:SetAlpha(a)
    local tbBase
    if a >= TEXTBG_FADE_START then
        tbBase = TEXTBG_SHOWN_ALPHA
    else
        tbBase = TEXTBG_SHOWN_ALPHA * (a / TEXTBG_FADE_START)
    end

    if ap.textBgHidden then
        textBg:SetAlpha(0)
    else
        local userA = (tonumber(ap.textBgAlpha) or 1)
        textBg:SetAlpha(tbBase * userA * (f._textBgBlizzardAlpha or 1))
    end
end

SetBlizzardCastbarTextShown = function(shown)
    if not InCombat() then
        CacheBlizzardCastbarRegions()
    end
    local a = GetAppearance()
    if not BLIZZ.cb then
        return
    end
    local bgShouldShow = true
    if shown == false then
        bgShouldShow = not a.bgHidden
    end
    f._frogskiHidingBlizzardText = (shown == false) and true or false
    if BLIZZ.text and BLIZZ.text.SetShown then
        BLIZZ.text:SetShown(shown)
    end
    if BLIZZ.textBorder and BLIZZ.textBorder.SetShown then
        if shown == false and a.textBgHidden then
            BLIZZ.textBorder:SetShown(false)
        else
            BLIZZ.textBorder:SetShown(shown)
        end
    end
    if BLIZZ.bg and BLIZZ.bg.SetShown then
        BLIZZ.bg:SetShown(bgShouldShow)
    end
end

local function StopBar()
    f._active = false
    f._outroUntil = 0
    f._outroStart = 0
    f._retriggerReadyAt = nil

    SetOutroAlpha(1)
    SetBlizzardCastbarTextShown(true)
    f:Hide()
end

local function FinishBarVisual()
    f._active = false
    f._outroUntil = GetTime() + OUTRO_HOLD
    f._outroStart = GetTime()

    bar:SetValue(0)
    bar:Hide()
    sparkCore:Hide()
    sparkGlow:Hide()
    shine:Hide()
    SetOutroAlpha(1)
end
local function StartBar(duration, label)

    f._outroUntil = 0
    f._outroStart = 0

    SetOutroAlpha(1)

    if duration <= 0 then
        StopBar()
        return
    end
    local ap = GetAppearance()
    if ap.disableWhileMounted and IsMounted() then
        StopBar()
        return
    end
    if ap.disableWhileDruidFlightForm and IsDruidFlightForm() then
        StopBar()
        return
    end
    ApplyToCastbarNow()
    SetBlizzardCastbarTextShown(false)
    if not InCombat() then
        SyncBorderToBlizzardOnlyIfCustom()

    end

    if ApplyAppearance then
        ApplyAppearance()
    end
    bar:Show()
    -- sparkCore:Show()
    -- sparkGlow:Show()
    -- shine:Show()
    f._active = true
    f._t0 = GetTime()
    f._dur = duration
    f._retriggerReadyAt = f._t0 + (duration * RETRIGGER_AT)
    -- TestPrintGCD((label or "?"), duration)
    txt:SetText(label or "")
    bar:SetMinMaxValues(0, duration)
    bar:SetValue(duration)
    UpdateSparkPosition()
    shine:ClearAllPoints()
    shine:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    shine:SetPoint("CENTER", f, "CENTER", 0, 0)

    if f._UpdateShineTrim then
        f._UpdateShineTrim()
    end

    f:Show()
end
f:SetScript("OnUpdate", function(self)
    if not self._active then
        if self._outroUntil and self._outroUntil > 0 then
            local now = GetTime()
            if now >= self._outroUntil then
                SetOutroAlpha(1)
                StopBar()
            else
                local t = now - (self._outroStart or now)
                local a = 1 - (t / OUTRO_HOLD)
                SetOutroAlpha(a)
            end
        end
        return
    end
    SetBlizzardCastbarTextShown(false)
    if IsPlayerCastingOrChanneling() then
        StopBar()
        return
    end
    local ap = GetAppearance()
    if ap.disableWhileMounted and IsMounted() then
        StopBar()
        return
    end

    if ap.disableWhileDruidFlightForm and IsDruidFlightForm() then
        StopBar()
        return
    end

    local t = GetTime() - self._t0
    if t >= self._dur then
        FinishBarVisual()
        return
    end
    bar:SetValue(self._dur - t)
    UpdateSparkPosition()
    if f._UpdateShineTrim then
        f._UpdateShineTrim()
    end
end)

-- ========================
-- Get spells base GCD
-- ========================

local function GetBaseGCDForInstantSpell(spellID)
    local o = GetOverwriteBySpellID(spellID)
    if o and o.base ~= nil then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        local name = (info and info.name) or ""
        return tonumber(o.base) or 0, name
    end

    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if not info or not info.castTime or info.castTime ~= 0 then
        return nil, nil
    end

    local _, gcdMS = GetSpellBaseCooldown(spellID)
    if not gcdMS or gcdMS <= 0 then
        return nil, nil
    end

    return (gcdMS / 1000), (info.name or "")
end

-- ========================
-- Instant-cast detection
-- ========================
local lastStartedSpellID = nil
local lastStartedWasRealCast = false
local lastCastSpellID = nil
local function on_event(self, event, unit, _, spellID)
    if unit ~= "player" then
        return
    end
    if event == "UNIT_SPELLCAST_START" then
        lastCastSpellID = spellID
        StopBar()
        local name, _, _, startTime, endTime = UnitCastingInfo("player")
        if name and startTime and endTime and endTime > startTime then
            lastStartedSpellID = spellID
            lastStartedWasRealCast = true
        else
            lastStartedSpellID = spellID
            lastStartedWasRealCast = false
        end
        return
    end

    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        lastCastSpellID = spellID
        StopBar()
        lastStartedSpellID = spellID
        lastStartedWasRealCast = true
        return
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if lastStartedWasRealCast and lastStartedSpellID == spellID then
            lastStartedSpellID = nil
            lastStartedWasRealCast = false
            lastCastSpellID = nil
            return
        end
        lastStartedSpellID = nil
        lastStartedWasRealCast = false
        if f._active then
            local now = GetTime()
            local readyAt = f._retriggerReadyAt or (f._t0 and f._dur and (f._t0 + f._dur * RETRIGGER_AT)) or nil
            if readyAt and now < readyAt then
                return
            end
            StopBar()
        end

        local now = GetTime()
        if f._outroUntil and f._outroUntil > now then
            f._outroUntil = 0
            f._outroStart = 0
            SetOutroAlpha(1)
            f:Hide()
        end
        local ap = GetAppearance()
        if ap.disableWhileMounted and IsMounted() then
            lastCastSpellID = nil
            return
        end
        if ap.disableWhileDruidFlightForm and IsDruidFlightForm() then
            lastCastSpellID = nil
            return
        end
        local base, name = GetBaseGCDForInstantSpell(spellID)

        if not base or base <= 0 then
            lastCastSpellID = nil
            return
        end

        if not name or name == "" then
            local info = C_Spell.GetSpellInfo(spellID)
            name = info and info.name or ""
        end

        local duration = ApplyHasteToGCD(base)
        StartBar(duration, name)
        lastCastSpellID = nil
        lastCastSpellID = nil
    end

end

-- ========================
-- Events
-- ========================

local ev = CreateFrame("Frame")
ev:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
ev:SetScript("OnEvent", on_event)

