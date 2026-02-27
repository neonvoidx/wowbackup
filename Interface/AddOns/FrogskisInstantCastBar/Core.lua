-- Frogski’s Instant Cast Bar
--
-- This addon is a resurrection of my old WeakAura https://wago.io/-iMgHlW6n from Friday, October 4th 2024, 12:12 pm
--
-- My CurseForge profile:
-- https://www.curseforge.com/members/frogski/projects
--
-- ================
-- Casting helpers
-- ================
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

-- ==================
-- Apply haste to GCD
-- ==================
local function ApplyHasteToGCD(base)
    local hastePercent = GetHaste() or 0
    local haste = hastePercent / 100
    local gcd = base / (1 + haste)
    if gcd < 1.0 then
        gcd = 1.0
    end
    return gcd
end

-- =============================
-- Forbidden secret value blcker
-- =============================
local function IsForbidden(obj)
    return obj and obj.IsForbidden and obj:IsForbidden()
end

local function SafeNumber(v)
    if type(v) ~= "number" then
        return nil
    end
    local ok, n = pcall(function()
        return v + 0
    end)
    if ok and type(n) == "number" then
        return n
    end
    return nil
end

local function SafeGetSize(region)
    if not region then
        return nil, nil
    end

    if region.GetSize then
        local ok, w, h = pcall(region.GetSize, region)
        if ok then
            w = SafeNumber(w)
            h = SafeNumber(h)
            return w, h
        end
    end

    if not region.GetWidth or not region.GetHeight then
        return nil, nil
    end

    local okW, w = pcall(region.GetWidth, region)
    local okH, h = pcall(region.GetHeight, region)
    w = okW and SafeNumber(w) or nil
    h = okH and SafeNumber(h) or nil
    return w, h
end
local function SafeGetCenter(region)
    if not region or not region.GetCenter then
        return nil, nil
    end
    local ok, cx, cy = pcall(region.GetCenter, region)
    if not ok then
        return nil, nil
    end
    return SafeNumber(cx), SafeNumber(cy)
end
-- ===========================
-- No Blizzard reads in combat==
-- ===========================
local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

-- ===================
-- DB init + accessors
-- ===================
FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}

local function InitDB()
    FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
    FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
    FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}
end

local function GetOverwrites()
    InitDB()
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

-- ==========================
-- First-run defaults seeding
-- ==========================
local function SeedDefaultsIfEmpty()
    InitDB()

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
    if a.useElvUIStyle == nil then
        a.useElvUIStyle = true
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

-- =====================
-- Blizzard region cache
-- =====================
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

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    SeedDefaultsIfEmpty()
    SanitizeOverwrites()
    CacheBlizzardCastbarRegions()
end)

-- ===================
-- Castbar safe getter
-- ===================
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

-- ===================
-- Appearance accessor
-- ===================
local function GetAppearance()
    InitDB()
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
    if a.useElvUIStyle == nil then
        a.useElvUIStyle = true
    end
    return a
end
-- ===========================
-- Instantcast Bar positioning
-- ===========================
local f = CreateFrame("Frame", "FrogskisInstantBarFrame", UIParent)
f:Hide()
f:SetToplevel(true)
f._castbar_cx, f._castbar_cy, f._castbar_w, f._castbar_h = nil, nil, nil, nil
f._lastShown_cx, f._lastShown_cy = nil, nil
-- ==========================================
-- ElvUI standalone castbar (visual instance)
-- ==========================================
local ELV = {
    owner = nil,
    bar = nil,
    UF = nil,
    ready = false
}
local ELV_ICON_PAD = 0
local function ElvUI_IsLoaded()
    return (type(ElvUI) == "table") and (type(unpack) == "function")
end
local function GetElvUIPlayerCastbarFrame()
    if not ElvUI_IsLoaded() then
        return nil
    end

    -- ElvUI unitframe objects are usually named like ElvUF_Player
    local playerUF = _G.ElvUF_Player
    if not playerUF then
        return nil
    end

    -- Castbar element is typically "Castbar" in ElvUI
    local cb = playerUF.Castbar or playerUF.CastBar
    if not cb then
        return nil
    end

    -- Prefer Holder if present (this matches mover size/pos)
    if cb.Holder and cb.Holder.GetCenter then
        return cb.Holder
    end

    return cb
end

local function GetElvUICastbarGeometry()
    local ref = GetElvUIPlayerCastbarFrame()
    if not ref or not ref.GetCenter then
        return false
    end

    local cx, cy = SafeGetCenter(ref)
    local w, h = SafeGetSize(ref)
    if not cx or not cy or not w or not h or w <= 0 or h <= 0 then
        return false
    end

    local sRef = ref:GetEffectiveScale() or 1
    local sUI = UIParent:GetEffectiveScale() or 1
    local scale = sRef / sUI

    f._castbar_cx = cx * scale
    f._castbar_cy = cy * scale
    f._castbar_w = w * scale
    f._castbar_h = h * scale
    f._lastShown_cx = f._castbar_cx
    f._lastShown_cy = f._castbar_cy

    return true
end
local function CreateElvUIStandaloneCastbar()
    if ELV.ready then
        local b = ELV.bar
        if b and b.Holder and b.Holder.SetClipsChildren then
            b.Holder:SetClipsChildren(false)
        end
        if b and b.SetClipsChildren then
            b:SetClipsChildren(false)
        end
        return true
    end
    if not ElvUI_IsLoaded() then
        return false
    end

    local E = unpack(ElvUI)
    if not E or not E.GetModule then
        return false
    end

    local UF = E:GetModule("UnitFrames")
    if not UF or not UF.Construct_Castbar or not UF.Configure_Castbar then
        return false
    end

    ELV.UF = UF

    -- Dummy owner frame (NOT oUF-driven, no unit, no events)
    local owner = CreateFrame("Frame", "FrogskiInstantCastBar_ElvUIOwner", UIParent)
    owner:SetFrameStrata("TOOLTIP")
    owner:SetFrameLevel(20)

    owner.RaisedElementParent = CreateFrame("Frame", nil, owner)
    owner.RaisedElementParent.CastBarLevel = owner:GetFrameLevel() + 5

    -- Minimal db UF:Configure_Castbar expects
    owner.db = owner.db or {}
    owner.db.castbar = {
        enable = true,

        -- IMPORTANT: prevents ElvUI from trying to anchor to frame[db.overlayOnFrame]
        overlayOnFrame = "Health",

        width = 250,
        height = 18,

        format = "REMAINING",
        reverse = false,
        smoothbars = true,
        timeToHold = 0,

        -- optional elements (keep them explicitly defined)
        spark = true,
        shield = true,

        latency = false,
        ticks = false,
        displayTarget = false,

        -- icon settings (ElvUI assumes some of these exist when icon=true)
        icon = false,
        iconAttached = true,
        iconAttachedTo = 'Frame',
        iconPosition = 'LEFT',
        iconSize = 18,
        iconXOffset = 0,
        iconYOffset = 0,

        -- text offsets
        xOffsetText = 4,
        yOffsetText = 0,
        xOffsetTime = -4,
        yOffsetTime = 0,

        nameLength = 0,

        customTextFont = {
            enable = false
        },
        customTimeFont = {
            enable = false
        },

        textColor = {
            r = 1,
            g = 1,
            b = 1
        }
    }
    owner.unitframeType = "customStandalone"

    -- >>> ADD THIS <<<
    owner.Health = owner.Health or CreateFrame("Frame", nil, owner)
    owner.Health:SetAllPoints(owner)
    owner.Health.RaisedElementParent = owner.RaisedElementParent
    -- >>> END ADD <<<

    local bar = UF:Construct_Castbar(owner, nil)
    owner.Castbar = bar
    bar.__owner = owner
    bar:SetParent(owner)

    bar:SetStatusBarTexture(E.media.blankTex)

    owner.IsElementEnabled = owner.IsElementEnabled or function()
        return true
    end
    owner.EnableElement = owner.EnableElement or function()
    end
    owner.DisableElement = owner.DisableElement or function()
    end

    UF:Configure_Castbar(owner)
    if bar.Icon then
        bar.Icon:Hide()
    end
    if bar.Iconbg then
        bar.Iconbg:Hide()
    end
    if bar.IconBackdrop then
        bar.IconBackdrop:Hide()
    end
    if bar.ButtonIcon then
        bar.ButtonIcon:Hide()
    end
    -- =========================
    -- Frogski icon for ElvUI-mode (we manage it ourselves)
    -- =========================
    if not bar.FrogskiIconFrame then
        local iconFrame = CreateFrame("Frame", nil, bar.Holder, BackdropTemplateMixin and "BackdropTemplate" or nil)
        iconFrame:SetFrameLevel(bar.Holder:GetFrameLevel() + 10)
        iconFrame:Hide()

        -- ElvUI border thickness (usually 1)
        local B = (UF and UF.BORDER) or 1

        -- Use ElvUI blankTex if available
        local bgTex = "Interface\\Buttons\\WHITE8x8"
        if E and E.media and E.media.blankTex then
            bgTex = E.media.blankTex
        end

        -- This is the missing "ElvUI black border"
        iconFrame:SetBackdrop({
            bgFile = bgTex,
            edgeFile = bgTex,
            edgeSize = B,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0.35) -- inner dark fill
        iconFrame:SetBackdropBorderColor(0, 0, 0, 1) -- black border

        -- Icon texture inset so border is visible
        local tex = iconFrame:CreateTexture(nil, "ARTWORK", nil, 0)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", B, -B)
        tex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -B, B)

        bar.FrogskiIconFrame = iconFrame
        bar.FrogskiIconTex = tex
    end
    bar:Hide()
    bar.Holder:Hide()

    ELV.owner = owner
    ELV.bar = bar
    ELV.ready = true
    return true
end
local function GetElvUI_PlayerCastbarIconSize()
    if not ElvUI_IsLoaded() then
        return nil
    end
    local E = unpack(ElvUI)
    local db = E and E.db and E.db.unitframe and E.db.unitframe.units and E.db.unitframe.units.player and
                   E.db.unitframe.units.player.castbar

    local iconSize = db and tonumber(db.iconSize) or nil
    if iconSize and iconSize > 0 then
        return iconSize
    end
    return nil
end
-- Position + size the ElvUI bar to match your saved castbar geometry
local function ElvUI_ApplyGeometry(cx, cy, w, h)
    if not ELV.ready or not ELV.bar or not ELV.owner then
        return
    end

    local bar = ELV.bar
    local BORDER = (ELV.UF and ELV.UF.BORDER) or 1

    ELV.owner:SetFrameStrata("TOOLTIP")
    ELV.owner:SetFrameLevel(20)

    -- Holder is the "mover"
    bar.Holder:ClearAllPoints()
    bar.Holder:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

    if w and h and w > 0 and h > 0 then
        bar.Holder:SetSize(w, (h))
    end

    -- Icon sizing: match holder height (minus border)
    local holderH = bar.Holder:GetHeight() or h or 0
    local holderH = bar.Holder:GetHeight() or h or 0

    -- Use ElvUI setting if available, otherwise fallback to "match height"
    local elvIconSize = GetElvUI_PlayerCastbarIconSize()

    local iconSize = elvIconSize or math.max(1, holderH - (BORDER * 2))
    iconSize = math.min(iconSize, math.max(1, holderH - (BORDER * 2)))

    -- Position our Frogski icon inside the holder (left side)
    if bar.FrogskiIconFrame then
        bar.FrogskiIconFrame:ClearAllPoints()
        bar.FrogskiIconFrame:SetPoint("BOTTOMLEFT", bar.Holder, "BOTTOMLEFT", BORDER, 0)
        bar.FrogskiIconFrame:SetSize(iconSize + (BORDER * 2), iconSize + (BORDER * 2))
    end

    -- Now place the actual statusbar area to the RIGHT of the icon
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMLEFT", bar.Holder, "BOTTOMLEFT", BORDER + iconSize + ELV_ICON_PAD, BORDER)
    bar:SetPoint("TOPRIGHT", bar.Holder, "TOPRIGHT", -BORDER, -BORDER)
end

local function ElvUI_Show()
    if ELV.ready and ELV.bar then
        local b = ELV.bar
        if b.Holder then
            b.Holder:Show()
        end
        b:Show()
        -- DO NOT show ElvUI icon containers; we use FrogskiIconFrame instead
    end
end

local function ElvUI_Hide()
    if ELV.ready and ELV.bar and ELV.bar.FrogskiIconFrame then
        ELV.bar.FrogskiIconFrame:Hide()
    end
    if ELV.ready and ELV.bar then
        ELV.bar:Hide()
        ELV.bar.Holder:Hide()
    end
end
local function ElvUI_SyncTextAnchorFromRealPlayerCastbar()
    if not (ELV.ready and ELV.bar and ELV.bar.Text) then
        return
    end
    if not ElvUI_IsLoaded() then
        return
    end

    local playerUF = _G.ElvUF_Player
    if not playerUF then
        return
    end

    local srcCB = playerUF.Castbar or playerUF.CastBar
    if not srcCB or not srcCB.Text or IsForbidden(srcCB) or IsForbidden(srcCB.Text) then
        return
    end

    local src = srcCB.Text
    local dst = ELV.bar.Text

    local p, rel, rp, x, y = src:GetPoint(1)
    if not p or not rel or not rp then
        return
    end
    x, y = x or 0, y or 0

    -- Map "relative frame" from real ElvUI castbar -> our standalone castbar
    local rel2 = rel
    if rel == srcCB then
        rel2 = ELV.bar
    elseif srcCB.Holder and rel == srcCB.Holder then
        rel2 = ELV.bar.Holder or ELV.bar
    elseif rel == playerUF then
        rel2 = ELV.bar.__owner or ELV.bar
    end

    -- Scale-correct offsets
    local sFrom = src:GetEffectiveScale() or 1
    local sTo = dst:GetEffectiveScale() or 1
    local k = sFrom / sTo

    dst:ClearAllPoints()
    dst:SetPoint(p, rel2, rp, x * k, y * k)
end
local function GetCastbarGeometry()
    local CASTBAR = GetCastbar_Safe()
    if not CASTBAR or not CASTBAR:IsObjectType("Frame") then
        return false
    end

    if not CASTBAR:IsShown() then
        return false
    end

    local cx, cy = SafeGetCenter(CASTBAR)
    local w, h = SafeGetSize(CASTBAR)
    if not cx or not cy or not w or not h or w <= 0 or h <= 0 then
        return false
    end

    local sCB = CASTBAR:GetEffectiveScale() or 1
    local sUI = UIParent:GetEffectiveScale() or 1
    local scale = sCB / sUI

    f._castbar_cx = cx * scale
    f._castbar_cy = cy * scale
    f._castbar_w = w * scale
    f._castbar_h = h * scale
    f._lastShown_cx = f._castbar_cx
    f._lastShown_cy = f._castbar_cy

    return true
end

local _pendingResync = false

local function ForceCaptureCastbarGeometry()
    if InCombat() then
        return false
    end

    local cb = GetCastbar_Safe()
    if not cb or IsForbidden(cb) then
        return false
    end

    local wasShown = cb:IsShown()
    local oldAlpha = (cb.GetAlpha and cb:GetAlpha()) or 1

    if not wasShown then
        cb:SetAlpha(0)
        cb:Show()
    end

    C_Timer.After(0, function()
        if InCombat() then
            _pendingResync = true
            return
        end

        local cx, cy = SafeGetCenter(cb)
        local w, h = SafeGetSize(cb)
        if cx and cy and w and h and w > 0 and h > 0 then
            local sCB = cb:GetEffectiveScale() or 1
            local sUI = UIParent:GetEffectiveScale() or 1
            local scale = sCB / sUI

            f._castbar_cx = cx * scale
            f._castbar_cy = cy * scale
            f._castbar_w = w * scale
            f._castbar_h = h * scale

            f._lastShown_cx = f._castbar_cx
            f._lastShown_cy = f._castbar_cy

            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", f._castbar_cx, f._castbar_cy)
            f:SetSize(f._castbar_w, f._castbar_h)
        end

        cb:SetAlpha(oldAlpha)
        if not wasShown then
            cb:Hide()
        end
    end)

    return true
end

local function ApplySavedGeometry()
    local cx = f._castbar_cx or f._lastShown_cx
    local cy = f._castbar_cy or f._lastShown_cy
    if not cx or not cy then
        return false
    end

    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    f:SetSize(f._castbar_w, f._castbar_h)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(20)

    -- If ElvUI instance exists, keep it pinned to the same spot/size
    if ELV.ready and ELV.bar then
        ElvUI_ApplyGeometry(cx, cy, f._castbar_w, f._castbar_h)
    end

    return true
end

local function ApplyToCastbarNow()
    if InCombat() then
        return ApplySavedGeometry()
    end

    -- If user wants ElvUI style, try ElvUI geometry FIRST
    local a = GetAppearance()
    if a.useElvUIStyle and ElvUI_IsLoaded() then
        if GetElvUICastbarGeometry() then
            ApplySavedGeometry()
            return true
        end
    end

    -- Fallback: Blizzard geometry
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
    -- Try to create ElvUI bar when ElvUI loads (load order safe)
    -- Try to create ElvUI bar when ElvUI loads (load order safe)

end
local function HookElvUICastbarChanges()
    local ref = GetElvUIPlayerCastbarFrame()
    if not ref or ref.__FrogskiHooked then
        return
    end
    ref.__FrogskiHooked = true

    ref:HookScript("OnShow", function()
        ApplyToCastbarNow()
    end)
    ref:HookScript("OnSizeChanged", function()
        ApplyToCastbarNow()
    end)

    -- Optional: if it’s a Holder, it moves via SetPoint changes, so also poll once after UI changes
    C_Timer.After(0, function()
        ApplyToCastbarNow()
    end)
end
local function HookElvUIConfigToggle()
    if not ElvUI_IsLoaded() then
        return
    end
    local E = unpack(ElvUI)
    if not E or not E.ToggleOptions or E.__FrogskiHookedToggleOptions then
        return
    end
    E.__FrogskiHookedToggleOptions = true

    hooksecurefunc(E, "ToggleOptions", function()
        -- When options are opened/closed, re-apply geometry (picks up new iconSize)
        ApplyToCastbarNow()
        ElvUI_SyncTextAnchorFromRealPlayerCastbar()
    end)
end
local elvLoader = CreateFrame("Frame")
elvLoader:RegisterEvent("ADDON_LOADED")
elvLoader:RegisterEvent("PLAYER_LOGIN")
elvLoader:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "ElvUI" or addonName == nil then
        if CreateElvUIStandaloneCastbar() then
            HookElvUICastbarChanges()
            HookElvUIConfigToggle()

            -- refresh border + size now that ELV.UF exists
            if ApplyIconBorderBackdrop then
                ApplyIconBorderBackdrop()
            end
            if LayoutIcon then
                LayoutIcon()
            end

            ApplyToCastbarNow()
        end
    end
end)

local function SyncBarToBlizzard()
    if InCombat() then
        return
    end
    if not GetCastbarGeometry() then
        return
    end

    local cx, cy, w, h = f._castbar_cx, f._castbar_cy, f._castbar_w, f._castbar_h
    if not cx or not cy or not w or not h then
        return
    end

    if f._applied_cx ~= cx or f._applied_cy ~= cy or f._applied_w ~= w or f._applied_h ~= h then
        f._applied_cx, f._applied_cy, f._applied_w, f._applied_h = cx, cy, w, h
        ApplySavedGeometry()
    end
end

-- ==========================
-- Generic "hook once" helper
-- ==========================
local function HookOnceToCastbar(flagKey, fn)
    local cb = GetCastbar_Safe()
    if not cb or cb[flagKey] then
        return
    end
    cb[flagKey] = true
    cb:HookScript("OnShow", fn)
    cb:HookScript("OnSizeChanged", fn)
end

HookOnceToCastbar("__FrogskiGeometrySynced", SyncBarToBlizzard)
SyncBarToBlizzard()
f:HookScript("OnShow", SyncBarToBlizzard)

-- ================
-- Drawing textures
-- ================

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
    local cb = GetCastbar_Safe()
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

    local cbx, cby = SafeGetCenter(cb)
    local tbx, tby = SafeGetCenter(tb)
    if cbx and cby and tbx and tby then
        local dx = (tbx - cbx) * ((cb:GetEffectiveScale() or 1) / (f:GetEffectiveScale() or 1))
        local dy = (tby - cby) * ((cb:GetEffectiveScale() or 1) / (f:GetEffectiveScale() or 1))
        local ix = (iconFrame and iconFrame:GetWidth() or 0)
        textBgHolder:ClearAllPoints()
        textBgHolder:SetPoint("CENTER", f, "CENTER", dx + (ix * 0.5), dy)
    else
        local ix = (iconFrame and iconFrame:GetWidth() or 0)
        textBgHolder:ClearAllPoints()
        textBgHolder:SetPoint("CENTER", f, "CENTER", (ix * 0.5), 0)
    end

    if ApplyAppearance then
        ApplyAppearance()
    end
end

HookOnceToCastbar("__FrogskiTextBorderSynced", SyncTextBgToBlizzard)
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
-- =========================
-- ElvUI-like spell icon (Blizzard-style path)
-- (match ElvUI icon size + border 1:1-ish)
-- =========================
local ICON_PAD = 0 -- gap between icon and bar (0 = flush)

local iconFrame = CreateFrame("Frame", nil, f)
iconFrame:SetFrameLevel(f:GetFrameLevel() + 6)
iconFrame:ClearAllPoints()
iconFrame:SetPoint("RIGHT", f, "LEFT", -ICON_PAD, 0)

-- Use ElvUI border width if available, otherwise 1
local function GetElvBorder()
    if ELV and ELV.UF and ELV.UF.BORDER then
        return tonumber(ELV.UF.BORDER) or 1
    end
    return 1
end

-- Border frame (ElvUI-like: bg + 1px border)
local iconBorder = CreateFrame("Frame", nil, iconFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
iconBorder:SetAllPoints(iconFrame)

local function ApplyIconBorderBackdrop()
    local B = GetElvBorder()

    -- Prefer ElvUI blank texture if present, otherwise fallback to a safe built-in
    local bgTex = "Interface\\Buttons\\WHITE8x8"
    if ElvUI_IsLoaded() then
        local E = unpack(ElvUI)
        if E and E.media and E.media.blankTex then
            bgTex = E.media.blankTex
        end
    end

    iconBorder:SetBackdrop({
        bgFile = bgTex,
        edgeFile = bgTex,
        edgeSize = B,
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    })

    -- ElvUI-ish colors
    iconBorder:SetBackdropColor(0, 0, 0, 0.35)
    iconBorder:SetBackdropBorderColor(0, 0, 0, 1)
end

ApplyIconBorderBackdrop()

-- Icon texture (inset so border is visible)
local iconTex = iconFrame:CreateTexture(nil, "ARTWORK", nil, 0)
iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
iconTex:Hide()

local function LayoutIcon()
    local h = f:GetHeight() or 0
    if h <= 1 then
        return
    end

    -- IMPORTANT: match ElvUI icon size if available (even in Blizzard-style mode)
    local elvIconSize = GetElvUI_PlayerCastbarIconSize()
    local size = elvIconSize or h

    iconFrame:SetSize(size, size)

    local B = GetElvBorder()
    iconTex:ClearAllPoints()
    iconTex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", B, -B)
    iconTex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -B, B)
end

f:HookScript("OnSizeChanged", LayoutIcon)
f:HookScript("OnShow", LayoutIcon)
LayoutIcon()
-- 3.25) Border holder
local borderHolder = CreateFrame("Frame", nil, f)
borderHolder:SetFrameLevel(f:GetFrameLevel() + 4)
borderHolder:SetPoint("CENTER", f, "CENTER")

local function SyncBorderHolderToBlizzard()
    if InCombat() then
        return
    end
    local cb = GetCastbar_Safe()
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

HookOnceToCastbar("__FrogskiBorderSynced", SyncBorderHolderToBlizzard)
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
    local cb = GetCastbar_Safe()
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

    local cb = GetCastbar_Safe()
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

HookOnceToCastbar("__FrogskiBorderOnlyIfCustomHooked", SyncBorderToBlizzardOnlyIfCustom)
SyncBorderToBlizzardOnlyIfCustom()
f:HookScript("OnShow", SyncBorderToBlizzardOnlyIfCustom)

-- ===================
-- 5) Spell name text
-- ===================
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
    local cb = GetCastbar_Safe()
    if not cb or not cb.Text then
        return
    end
    local src = cb.Text
    if not src or IsForbidden(src) then
        return
    end

    local w, h = SafeGetSize(src)
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
    local ix = (iconFrame and iconFrame:GetWidth() or 0)
    x = x + (ix * 0.5)
    txtHolder:SetPoint(p, rel, rp, x, y)
end

HookOnceToCastbar("__FrogskiTextRegionSynced", SyncTxtHolderToBlizzard)
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
        local sSrc2 = src:GetEffectiveScale() or 1
        local sDst2 = dst:GetEffectiveScale() or 1
        local px = sx * sSrc2
        local py = sy * sSrc2
        local pxSnap = (px >= 0) and math.floor(px + 0.5) or math.ceil(px - 0.5)
        local pySnap = (py >= 0) and math.floor(py + 0.5) or math.ceil(py - 0.5)
        pySnap = pySnap + 0.5
        dst:SetShadowOffset(pxSnap / sDst2, pySnap / sDst2)
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
    local cb = GetCastbar_Safe()
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

HookOnceToCastbar("__FrogskiTextStyleSynced", SyncTxtToBlizzard)
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
local ApplyAppearance

ApplyAppearance = function()
    if f._usingElvUI then
        return
    end

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
        sparkCore:SetAlpha(0)
        sparkCore:Hide()
        sparkGlow:SetAlpha(0)
        sparkGlow:Hide()
    else
        local sa = tonumber(a.sparkAlpha) or 1
        sparkCore:Show()
        sparkGlow:Show()
        sparkCore:SetAlpha(sa)
        sparkGlow:SetAlpha(sa * 0.2)
    end
end

_G.FrogskiInstantCastBar_ApplyAppearance = ApplyAppearance
if ApplyAppearance then
    ApplyAppearance()
end

-- =======
-- resync
-- =======
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

    if event == "EDIT_MODE_LAYOUTS_UPDATED" then
        ForceCaptureCastbarGeometry()
        PerformFullResync()
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
        ForceCaptureCastbarGeometry()
        PerformFullResync()
    end)
end

HookEditModeClose()
resyncEv:HookScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookEditModeClose()
    end
end)

-- ===================
-- Bar live state core
-- ===================
local RETRIGGER_AT = 0.80
local OUTRO_HOLD = 0.25
local TEXTBG_SHOWN_ALPHA = 1.0
local TEXTBG_FADE_START = 0.35

local function SetOutroAlpha(a)
    if f._usingElvUI then
        return
    end
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
local function UsingElvUIStyle()
    local a = GetAppearance()
    if not a.useElvUIStyle then
        return false
    end
    if not ELV.ready then
        CreateElvUIStandaloneCastbar()
    end
    return ELV.ready and ELV.bar
end
local function ElvUI_SetIconTexture(castbar, spellID)
    if not castbar or not spellID then
        return
    end

    local icon
    if C_Spell and C_Spell.GetSpellTexture then
        icon = C_Spell.GetSpellTexture(spellID)
    elseif GetSpellTexture then
        icon = GetSpellTexture(spellID)
    end
    if not icon then
        return
    end

    -- Possible icon texture locations across ElvUI versions
    local tex = castbar.ButtonIcon or (castbar.Icon and castbar.Icon.icon) or (castbar.Icon and castbar.Icon.Icon) or
                    castbar.IconTexture or castbar.Icon

    -- If "tex" is actually a Frame, try common texture members
    if tex and tex.IsObjectType and tex:IsObjectType("Frame") then
        tex = tex.icon or tex.Icon or tex.texture
    end

    if tex and tex.SetTexture then
        tex:SetTexture(icon)
        if tex.Show then
            tex:Show()
        end
    end

    -- Also force-show common icon containers
    if castbar.Icon and castbar.Icon.Show then
        castbar.Icon:Show()
    end
    if castbar.Iconbg and castbar.Iconbg.Show then
        castbar.Iconbg:Show()
    end
    if castbar.ButtonIcon and castbar.ButtonIcon.Show then
        castbar.ButtonIcon:Show()
    end
end
local function ElvUI_StartVisual(duration, label, spellID)
    -- Ensure ElvUI exists
    if not ELV.ready then
        CreateElvUIStandaloneCastbar()
    end
    if not ELV.ready or not ELV.bar then
        return false
    end

    -- Position to current saved geometry
    ApplyToCastbarNow()
    -- Force geometry apply NOW (because ELV.ready may have just become true)
    local cx = f._castbar_cx or f._lastShown_cx
    local cy = f._castbar_cy or f._lastShown_cy
    local w = f._castbar_w or f:GetWidth()
    local h = f._castbar_h or f:GetHeight()
    if cx and cy then
        ElvUI_ApplyGeometry(cx, cy, w, h)
    end
    local bar = ELV.bar
    bar:SetMinMaxValues(0, duration > 0 and duration or 1)
    bar:SetReverseFill(false)
    bar:SetValue(0)

    if bar.Text then
        bar.Text:SetText(label or "")
    end
    ElvUI_SyncTextAnchorFromRealPlayerCastbar()
    -- Set icon if we can
    ElvUI_SetIconTexture(bar, spellID)
    if spellID and bar.FrogskiIconTex and bar.FrogskiIconFrame then
        local icon
        if C_Spell and C_Spell.GetSpellTexture then
            icon = C_Spell.GetSpellTexture(spellID)
        elseif GetSpellTexture then
            icon = GetSpellTexture(spellID)
        end

        if icon then
            bar.FrogskiIconTex:SetTexture(icon)
            bar.FrogskiIconFrame:Show()
        else
            bar.FrogskiIconFrame:Hide()
        end
    elseif bar.FrogskiIconFrame then
        bar.FrogskiIconFrame:Hide()
    end
    -- Your instant bar should look “cast-like”
    bar:SetStatusBarColor(1, 0.7, 0.2, 1)

    ElvUI_Show()
    return true
end

local function ElvUI_UpdateVisual(duration, elapsed)
    if not (ELV.ready and ELV.bar) then
        return
    end
    local bar = ELV.bar
    if duration <= 0 then
        return
    end

    if elapsed < 0 then
        elapsed = 0
    end
    if elapsed > duration then
        elapsed = duration
    end

    bar:SetValue(elapsed)

    local remain = duration - elapsed
    if remain < 0 then
        remain = 0
    end

    if bar.Time then
        bar.Time:SetFormattedText("%.1f", remain)
    end

    -- Move ElvUI spark if present (Spark_ exists in ElvUI UF castbars)
    if bar.Spark_ then
        local pct = elapsed / duration
        if pct <= 0 or pct >= 1 then
            bar.Spark_:Hide()
        else
            bar.Spark_:Show()
            local w = bar:GetWidth() or 0
            local x = w * pct
            bar.Spark_:ClearAllPoints()
            bar.Spark_:SetPoint("CENTER", bar, "LEFT", x, 0)
            bar.Spark_:SetHeight(bar:GetHeight() or 0)
        end
    end
end
local function StopBar()
    f._active = false
    f._outroUntil = 0
    f._outroStart = 0
    f._retriggerReadyAt = nil

    SetOutroAlpha(1)
    SetBlizzardCastbarTextShown(true)

    -- Hide ElvUI instance if used
    if ELV.ready and ELV.bar then
        ElvUI_Hide()
    end
    f._usingElvUI = false
    f:SetAlpha(1)
    if ApplyAppearance then
        ApplyAppearance()
    end
    if iconTex then
        iconTex:Hide()
    end
    if iconFrame then
        iconFrame:Hide()
    end
    f:Hide()
end

local function FinishBarVisual()
    f._active = false
    f._outroUntil = GetTime() + OUTRO_HOLD
    f._outroStart = GetTime()

    if UsingElvUIStyle() then
        -- keep ElvUI bar visible during OUTRO_HOLD, then hide in OnUpdate
        SetOutroAlpha(1) -- just in case your old bar was visible
        return
    end

    bar:SetValue(0)
    bar:Hide()
    sparkCore:Hide()
    sparkGlow:Hide()
    shine:Hide()
    SetOutroAlpha(1)
end

-- Debug 
local DEBUG_POS = false

local function StartBar(duration, label, spellID)
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

    f._usingElvUI = UsingElvUIStyle()

    if f._usingElvUI then
        -- show ElvUI bar
        ElvUI_StartVisual(duration, label, spellID)

        -- keep f running OnUpdate but invisible
        f:SetAlpha(0)
        f:Show()

        -- ensure your default visuals stay hidden
        bar:Hide()
        bgHolder:Hide()
        textBg:Hide()
        textBgHolder:Hide()
        border:Hide()
        shine:Hide()
        sparkCore:Hide()
        sparkGlow:Hide()
    else
        ElvUI_Hide()
        f:SetAlpha(1)

        -- Never show spell icon in Blizzard-style mode
        if iconTex then
            iconTex:Hide()
        end
        if iconFrame then
            iconFrame:Hide()
        end
    end
    SetBlizzardCastbarTextShown(false)
    if not InCombat() then
        SyncBorderToBlizzardOnlyIfCustom()
    end

    if ApplyAppearance then
        ApplyAppearance()
    end

    if not f._usingElvUI then
        bar:Show()
    end

    f._active = true
    f._t0 = GetTime()
    f._dur = duration
    f._retriggerReadyAt = f._t0 + (duration * RETRIGGER_AT)

    txt:SetText(label or "")
    bar:SetMinMaxValues(0, duration)

    if not f._usingElvUI then
        bar:SetValue(duration)
        UpdateSparkPosition()

        shine:ClearAllPoints()
        shine:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
        shine:SetPoint("CENTER", f, "CENTER", 0, 0)

        if f._UpdateShineTrim then
            f._UpdateShineTrim()
        end

        f:Show()
    else
        -- ElvUI drives visuals; f is already shown at alpha 0 above
    end
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

    if self._usingElvUI then
        ElvUI_UpdateVisual(self._dur, t)
    else
        -- your current visual behavior (countdown)
        bar:SetValue(self._dur - t)
        UpdateSparkPosition()
        if f._UpdateShineTrim then
            f._UpdateShineTrim()
        end
    end

    if f._UpdateShineTrim then
        f._UpdateShineTrim()
    end
end)

-- ===================
-- Get spells base GCD
-- ===================
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

-- ======================
-- Instant-cast detection
-- ======================
local lastStartedSpellID = nil
local lastStartedWasRealCast = false

local function on_event(_, event, unit, _, spellID)
    if unit ~= "player" then
        return
    end

    if event == "UNIT_SPELLCAST_START" then
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
        StopBar()
        lastStartedSpellID = spellID
        lastStartedWasRealCast = true
        return
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if lastStartedWasRealCast and lastStartedSpellID == spellID then
            lastStartedSpellID = nil
            lastStartedWasRealCast = false
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
            return
        end
        if ap.disableWhileDruidFlightForm and IsDruidFlightForm() then
            return
        end

        local base, name = GetBaseGCDForInstantSpell(spellID)
        if not base or base <= 0 then
            return
        end

        if not name or name == "" then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            name = info and info.name or ""
        end

        local duration = ApplyHasteToGCD(base)
        StartBar(duration, name, spellID)
    end
end

-- ======
-- Events
-- ======
local ev = CreateFrame("Frame")
ev:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
ev:SetScript("OnEvent", on_event)
