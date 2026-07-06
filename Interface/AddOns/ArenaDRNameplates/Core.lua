local _, ns = ...
ns = ns or {}

local Shared = ns.Shared
local S = Shared.S

local isMidnight = select(4, GetBuildInfo()) >= 120000
if not isMidnight then
    print(S("ERR_REQUIRES_MIDNIGHT"))
    return
end

local ARENA_IDS = { 1, 2, 3 }
local TEST_SPELLS = {
    { spellID = 408, duration = 18 },
    { spellID = 5782, duration = 15 },
    { spellID = 118, duration = 12, isImmune = true },
}
local PREVIEW_MIN_DR_COUNT = 1
local PREVIEW_MAX_DR_COUNT = 3
local PREVIEW_MIN_DURATION = 8
local PREVIEW_MAX_DURATION = 24

local defaults = Shared.defaults
local validDRTextAnchors = Shared.validDRTextAnchors
local NextFrameName = Shared.NextFrameName
local NormalizeTrinketVisibility = Shared.NormalizeTrinketVisibility
local issecretvalue_fn = _G.issecretvalue

local db
local liveContainers = {}
local sourceInfoByArenaID = {}
local trinketMirrors = {}
local refreshTicker
local testMode = false
local testTrays = {}
local testConfigsByKey = {}
local testTrinketIcon
local testModeStartedAt
local helperCallbackOwner = {}
local parkingRoot

local function GetParkingRoot()
    if parkingRoot then
        return parkingRoot
    end

    parkingRoot = CreateFrame("Frame", NextFrameName("Core", "ParkingRoot"), UIParent)
    parkingRoot:SetSize(1, 1)
    parkingRoot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -4096, -4096)
    parkingRoot:Show()
    return parkingRoot
end

local function ParkFrameOffscreen(frame)
    if not frame then
        return
    end

    local root = GetParkingRoot()
    if frame:GetParent() ~= root then
        frame:SetParent(root)
    end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", root, "CENTER", 0, 0)
end

local function GetHelper()
    return ns and ns.ArenaNameplateHelper
end

local function NotifySettingsUIRefresh()
    if type(_G.ArenaDRNameplates_RefreshSettingsUI) == "function" then
        _G.ArenaDRNameplates_RefreshSettingsUI()
    end
end

local NormalizeColorTable = Shared.NormalizeColorTable
local ClampNumber = Shared.ClampNumber

local function IsSecretValue(value)
    if value == nil or type(issecretvalue_fn) ~= "function" then
        return false
    end

    local ok, result = pcall(issecretvalue_fn, value)
    return ok and result == true
end

local function Trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetEffectiveIconGrowth()
    return db and Shared.GetEffectiveIconGrowthForTable(db) or defaults.iconGrowth
end

local function GetIconLayout()
    return db and Shared.GetEffectiveIconLayoutForTable(db) or defaults.iconLayout
end

local function GetIconPadding()
    if not db then
        return defaults.iconPadding
    end

    return ClampNumber(db.iconPadding, 0, 20, defaults.iconPadding)
end

local function ShouldScaleWithNameplate()
    if not db then
        return defaults.scaleWithNameplate == true
    end

    return db.scaleWithNameplate ~= false
end

local function GetUIParentEffectiveScale()
    if UIParent and UIParent.GetEffectiveScale then
        local ok, scale = pcall(UIParent.GetEffectiveScale, UIParent)
        if ok and not IsSecretValue(scale) and type(scale) == "number" and scale > 0 then
            return scale
        end
    end

    return 1
end

local function GetFrameEffectiveScale(frame)
    if frame and frame.GetEffectiveScale then
        local ok, scale = pcall(frame.GetEffectiveScale, frame)
        if ok and not IsSecretValue(scale) and type(scale) == "number" and scale > 0 then
            return scale
        end
    end

    return GetUIParentEffectiveScale()
end

local function GetDRTrayScale(parent)
    local scaleValue = ClampNumber(db and db.scale, 0.5, 3.0, defaults.scale)
    if ShouldScaleWithNameplate() then
        return scaleValue
    end

    local parentScale = GetFrameEffectiveScale(parent)
    if parentScale <= 0 then
        return scaleValue
    end

    return scaleValue * (GetUIParentEffectiveScale() / parentScale)
end

local function GetTrinketSettings()
    if db and type(db.trinket) == "table" then
        return db.trinket
    end

    return defaults.trinket
end

local function IsTrinketEnabled()
    return GetTrinketSettings().enabled == true
end

local function GetTrinketVisibilityMode()
    return NormalizeTrinketVisibility(GetTrinketSettings().visibility)
end

local function GetTrinketSize()
    return ClampNumber(GetTrinketSettings().size, 12, 80, defaults.trinket.size)
end

local function GetTrinketOpacity()
    return ClampNumber(GetTrinketSettings().opacity, 0.1, 1.0, defaults.trinket.opacity)
end

local function GetTrinketBorderStyle()
    return Shared.NormalizeTrinketBorderStyle(GetTrinketSettings().borderStyle)
end

local function GetTrinketBorderWidth()
    return ClampNumber(GetTrinketSettings().borderWidth, 1, 8, defaults.trinket.borderWidth)
end

local function GetTrinketBorderColorRGB()
    local color = NormalizeColorTable(GetTrinketSettings().borderColor, defaults.trinket.borderColor)
    return color[1], color[2], color[3]
end

local function GetEffectiveTrinketAnchor()
    local settings = GetTrinketSettings()
    return
        settings.point or defaults.trinket.point,
        settings.relativePoint or defaults.trinket.relativePoint,
        ClampNumber(settings.offsetX, -150, 150, defaults.trinket.offsetX),
        ClampNumber(settings.offsetY, -150, 150, defaults.trinket.offsetY)
end

local function GetTrinketTimerBaseFontSize(size)
    return math.max(10, math.floor((tonumber(size) or defaults.trinket.size) * 0.55 + 0.5))
end

local function IsInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function IsEnemyTarget()
    return UnitExists("target")
        and not UnitIsUnit("target", "player")
        and UnitCanAttack("player", "target")
end

local function GetTimerColorRGB()
    if not db then
        return 1, 1, 1
    end

    local color = NormalizeColorTable(db.timerTextColor, defaults.timerTextColor)
    return color[1], color[2], color[3]
end

local function GetTimerTextScale()
    if not db then
        return defaults.timerTextScale
    end

    return ClampNumber(db.timerTextScale, 0.5, 3.0, defaults.timerTextScale)
end

local function GetTimerTextOffsets()
    if not db then
        return defaults.timerTextOffsetX, defaults.timerTextOffsetY
    end

    return
        ClampNumber(db.timerTextOffsetX, -50, 50, defaults.timerTextOffsetX),
        ClampNumber(db.timerTextOffsetY, -50, 50, defaults.timerTextOffsetY)
end

local function IsTimerTextEnabled()
    if not db then
        return defaults.showTimerText
    end

    if type(db.showTimerText) ~= "boolean" then
        return defaults.showTimerText
    end

    return db.showTimerText
end

local function AreTimerDecimalsEnabled()
    if not db then
        return defaults.showTimerDecimals
    end

    if type(db.showTimerDecimals) ~= "boolean" then
        return defaults.showTimerDecimals
    end

    return db.showTimerDecimals
end

local function GetTimerDecimalThreshold()
    local threshold = db and db.timerDecimalThreshold or defaults.timerDecimalThreshold
    return math.floor(ClampNumber(threshold, 1, 20, defaults.timerDecimalThreshold) + 0.5)
end

local function IsTimerSwipeEnabled()
    if not db then
        return defaults.showTimerSwipe
    end

    if type(db.showTimerSwipe) ~= "boolean" then
        return defaults.showTimerSwipe
    end

    return db.showTimerSwipe
end

local function IsTimerSwipeEdgeEnabled()
    if not db then
        return defaults.showTimerSwipeEdge
    end

    if type(db.showTimerSwipeEdge) ~= "boolean" then
        return defaults.showTimerSwipeEdge
    end

    return db.showTimerSwipeEdge
end

local function ApplyCooldownStyle(cooldown)
    if not cooldown then
        return
    end

    local showSwipe = IsTimerSwipeEnabled()
    local showSwipeEdge = showSwipe and IsTimerSwipeEdgeEnabled()

    if cooldown.SetDrawSwipe then
        cooldown:SetDrawSwipe(showSwipe)
    end

    if cooldown.SetSwipeColor then
        if showSwipe then
            cooldown:SetSwipeColor(0, 0, 0, 0.7)
        else
            cooldown:SetSwipeColor(0, 0, 0, 0)
        end
    end

    if cooldown.SetDrawEdge then
        cooldown:SetDrawEdge(showSwipeEdge)
    end

    if cooldown.SetDrawBling then
        cooldown:SetDrawBling(false)
    end

    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(
            AreTimerDecimalsEnabled() and GetTimerDecimalThreshold() or 0
        )
    end

    if cooldown.SetHideCountdownNumbers then
        cooldown:SetHideCountdownNumbers(not IsTimerTextEnabled())
    end
end

local function ClearCooldownCompat(cooldown)
    if not cooldown then
        return
    end

    if type(CooldownFrame_Clear) == "function" then
        CooldownFrame_Clear(cooldown)
        return
    end

    if cooldown.SetCooldown then
        cooldown:SetCooldown(0, 0)
    end
end

local function GetDRTextColorRGB(isImmune)
    if not db then
        return 1, 1, 1
    end

    local key = isImmune and "drTextImmuneColor" or "drTextColor"
    local fallback = defaults[key]
    local color = NormalizeColorTable(db[key], fallback)
    return color[1], color[2], color[3]
end

local function GetDRBorderColorRGB(isImmune)
    if not db then
        return 1, 1, 1
    end

    local key = isImmune and "drBorderImmuneColor" or "drBorderColor"
    local fallback = defaults[key]
    local color = NormalizeColorTable(db[key], fallback)
    return color[1], color[2], color[3]
end

local function GetDRBorderWidth()
    if not db then
        return defaults.drBorderWidth
    end

    return ClampNumber(db.drBorderWidth, 1, 8, defaults.drBorderWidth)
end

local function GetDRBorderStyle()
    if not db then
        return defaults.drBorderStyle
    end

    return Shared.NormalizeDRBorderStyle(db.drBorderStyle)
end

local function FindCooldownText(frame)
    if not frame then
        return nil
    end

    if frame.timerFontString
        and frame.timerFontString.GetObjectType
        and frame.timerFontString:GetObjectType() == "FontString" then
        return frame.timerFontString
    end

    if frame.Cooldown then
        local cooldown = frame.Cooldown

        if cooldown.GetCountdownFontString then
            local ok, countdownFontString = pcall(cooldown.GetCountdownFontString, cooldown)
            if ok
                and countdownFontString
                and countdownFontString.GetObjectType
                and countdownFontString:GetObjectType() == "FontString" then
                frame.timerFontString = countdownFontString
                return frame.timerFontString
            end
        end

        if cooldown.Text
            and cooldown.Text.GetObjectType
            and cooldown.Text:GetObjectType() == "FontString" then
            frame.timerFontString = cooldown.Text
            return frame.timerFontString
        end

        for _, region in ipairs({ cooldown:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                frame.timerFontString = region
                return region
            end
        end
    end

    return nil
end

local function FindCooldownFrame(frame)
    if not frame then
        return nil
    end

    if frame.Cooldown and frame.Cooldown.GetCooldownTimes then
        return frame.Cooldown
    end

    if frame.cooldown and frame.cooldown.GetCooldownTimes then
        return frame.cooldown
    end

    if frame.CooldownFrame and frame.CooldownFrame.GetCooldownTimes then
        return frame.CooldownFrame
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        if child and child.GetCooldownTimes and child.SetCooldown then
            return child
        end
    end

    return nil
end

local function FindTextureRegion(frame)
    if not frame then
        return nil
    end

    if frame.Icon and frame.Icon.GetTexture then
        return frame.Icon
    end

    if frame.icon and frame.icon.GetTexture then
        return frame.icon
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            return region
        end
    end

    return nil
end

local function ApplyTimerTextStyle(timerText, parent, fontSize)
    if not timerText or not parent then
        return
    end

    local timerR, timerG, timerB = GetTimerColorRGB()
    local offsetX, offsetY = GetTimerTextOffsets()
    local textScale = GetTimerTextScale()
    local actualFontSize = math.max(6, math.floor((tonumber(fontSize) or 14) * textScale + 0.5))

    timerText:SetTextColor(timerR, timerG, timerB, 1)
    timerText:ClearAllPoints()
    timerText:SetPoint("CENTER", parent, "CENTER", offsetX, offsetY)

    if timerText.SetJustifyH then
        timerText:SetJustifyH("CENTER")
    end
    if timerText.SetJustifyV then
        timerText:SetJustifyV("MIDDLE")
    end
    if timerText.SetFont then
        timerText:SetFont(STANDARD_TEXT_FONT, actualFontSize, "OUTLINE")
    end
end

local LIVE_DR_TIMER_DURATION = 16.1
local LIVE_DR_IMMUNITY_DURATION_FIRST = 20
local LIVE_DR_IMMUNITY_DURATION_REPEAT = 18

local function ResetLiveSlotSeverity(slot)
    if not slot then
        return
    end

    slot.ArenaDRNameplatesLiveSeverity = 0
end

local function IncrementLiveSlotSeverity(slot)
    if not slot then
        return
    end

    local current = tonumber(slot.ArenaDRNameplatesLiveSeverity) or 0
    slot.ArenaDRNameplatesLiveSeverity = math.min(current + 1, 2)
end

local function GetLiveSlotImmunityDuration(slot)
    local severity = tonumber(slot and slot.ArenaDRNameplatesLiveSeverity) or 0
    if severity <= 1 then
        return LIVE_DR_IMMUNITY_DURATION_FIRST
    end

    return LIVE_DR_IMMUNITY_DURATION_REPEAT
end

local function StartLiveSlotCooldown(slot, durationSeconds)
    if not slot or not slot.Cooldown then
        return
    end

    local cooldown = slot.Cooldown
    local startedAt = GetTime()
    local trackedDuration = tonumber(durationSeconds) or LIVE_DR_TIMER_DURATION

    pcall(function()
        cooldown:SetCooldown(startedAt, trackedDuration)
    end)
end

local function EnsureVisualOverlay(frame)
    if not frame then
        return nil
    end

    local overlay = frame.ArenaDRNameplatesVisualOverlay
    if not overlay then
        overlay = CreateFrame("Frame", NextFrameName("Core", "VisualOverlay"), frame)
        overlay:SetAllPoints(frame)
        overlay:EnableMouse(false)
        frame.ArenaDRNameplatesVisualOverlay = overlay
    end

    local targetLevel = frame.GetFrameLevel and frame:GetFrameLevel() or 0
    if frame.Cooldown and frame.Cooldown.GetFrameLevel then
        targetLevel = math.max(targetLevel, frame.Cooldown:GetFrameLevel())
    end
    if overlay.SetFrameLevel then
        overlay:SetFrameLevel(targetLevel + 10)
    end

    return overlay
end

local CLASSIC_BORDER_TEXTURE = "Interface\\Buttons\\UI-Debuff-Overlays"
local CLASSIC_BORDER_TEX_COORDS = {
    0.296875,
    0.5703125,
    0,
    0.515625,
}

local function EnsureSolidDRBorderRegions(overlay)
    if not overlay then
        return nil
    end

    if not overlay.ArenaDRNameplatesBorderSegments then
        local function CreateBorderSegment()
            local segment = overlay:CreateTexture(nil, "ARTWORK")
            segment:SetTexture("Interface\\Buttons\\WHITE8X8")
            return segment
        end

        local top = CreateBorderSegment()
        local bottom = CreateBorderSegment()
        local left = CreateBorderSegment()
        local right = CreateBorderSegment()

        overlay.ArenaDRNameplatesBorderSegments = {
            top,
            bottom,
            left,
            right,
        }
    end

    return overlay.ArenaDRNameplatesBorderSegments
end

local function UpdateSolidDRBorderLayout(overlay)
    local borderSegments = EnsureSolidDRBorderRegions(overlay)
    if not borderSegments then
        return nil
    end

    local borderWidth = GetDRBorderWidth()
    local extent = borderWidth / 2
    local top = borderSegments[1]
    local bottom = borderSegments[2]
    local left = borderSegments[3]
    local right = borderSegments[4]

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", overlay, "TOPLEFT", -extent, extent)
    top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", extent, extent)
    top:SetHeight(borderWidth)

    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", -extent, -extent)
    bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", extent, -extent)
    bottom:SetHeight(borderWidth)

    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", overlay, "TOPLEFT", -extent, extent)
    left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", -extent, -extent)
    left:SetWidth(borderWidth)

    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", extent, extent)
    right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", extent, -extent)
    right:SetWidth(borderWidth)

    return borderSegments
end

local function EnsureClassicDRBorderRegion(overlay)
    if not overlay then
        return nil
    end

    if not overlay.ArenaDRNameplatesClassicBorder then
        local border = overlay:CreateTexture(nil, "OVERLAY")
        border:SetTexture(CLASSIC_BORDER_TEXTURE)
        border:SetTexCoord(unpack(CLASSIC_BORDER_TEX_COORDS))
        overlay.ArenaDRNameplatesClassicBorder = border
    end

    return overlay.ArenaDRNameplatesClassicBorder
end

local function UpdateClassicDRBorderLayout(overlay)
    local border = EnsureClassicDRBorderRegion(overlay)
    if not border then
        return nil
    end

    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", overlay, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 1, -1)
    return border
end

local function HideDRBorderVisuals(overlay)
    if not overlay then
        return
    end

    if overlay.ArenaDRNameplatesBorderSegments then
        for _, segment in ipairs(overlay.ArenaDRNameplatesBorderSegments) do
            segment:Hide()
        end
    end

    if overlay.ArenaDRNameplatesClassicBorder then
        overlay.ArenaDRNameplatesClassicBorder:Hide()
    end
end

local function GetDRBorderVisual(frame)
    local overlay = EnsureVisualOverlay(frame)
    if not overlay then
        return nil, nil
    end

    local borderStyle = GetDRBorderStyle()
    if borderStyle == "NONE" then
        HideDRBorderVisuals(overlay)
        return borderStyle, nil
    end

    if borderStyle == "CLASSIC" then
        local border = UpdateClassicDRBorderLayout(overlay)
        if overlay.ArenaDRNameplatesBorderSegments then
            for _, segment in ipairs(overlay.ArenaDRNameplatesBorderSegments) do
                segment:Hide()
            end
        end
        return borderStyle, border
    end

    local borderSegments = UpdateSolidDRBorderLayout(overlay)
    if overlay.ArenaDRNameplatesClassicBorder then
        overlay.ArenaDRNameplatesClassicBorder:Hide()
    end
    return borderStyle, borderSegments
end

local function ApplyDRBorderColor(frame, isImmune)
    local borderStyle, borderVisual = GetDRBorderVisual(frame)
    if not borderVisual then
        return
    end

    local normalR, normalG, normalB = GetDRBorderColorRGB(false)
    local immuneR, immuneG, immuneB = GetDRBorderColorRGB(true)
    local normalColor = CreateColor(normalR, normalG, normalB, 1)
    local immuneColor = CreateColor(immuneR, immuneG, immuneB, 1)

    local function ApplyTextureColor(texture)
        if texture.SetVertexColorFromBoolean then
            texture:SetVertexColorFromBoolean(isImmune, immuneColor, normalColor)
        elseif not IsSecretValue(isImmune) then
            local r, g, b = normalR, normalG, normalB
            if isImmune then
                r, g, b = immuneR, immuneG, immuneB
            end
            texture:SetVertexColor(r, g, b, 1)
        else
            texture:SetVertexColor(normalR, normalG, normalB, 1)
        end
    end

    if borderStyle == "CLASSIC" then
        ApplyTextureColor(borderVisual)
        borderVisual:Show()
        return
    end

    for _, segment in ipairs(borderVisual) do
        ApplyTextureColor(segment)
        segment:Show()
    end
end

local function EnsureDRTextRegions(frame)
    if not frame then
        return nil, nil
    end

    local overlay = EnsureVisualOverlay(frame)
    if not overlay then
        return nil, nil
    end

    if not frame.ArenaDRNameplatesDRText then
        local drText = overlay:CreateFontString(nil, "OVERLAY")
        drText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        drText:SetShadowOffset(1, -1)
        drText:SetShadowColor(0, 0, 0, 1)
        if drText.SetDrawLayer then
            drText:SetDrawLayer("OVERLAY", 7)
        end
        drText:SetText("½")
        frame.ArenaDRNameplatesDRText = drText
    end

    if not frame.ArenaDRNameplatesDRTextImmune then
        local drTextImmune = overlay:CreateFontString(nil, "OVERLAY")
        drTextImmune:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        drTextImmune:SetShadowOffset(1, -1)
        drTextImmune:SetShadowColor(0, 0, 0, 1)
        if drTextImmune.SetDrawLayer then
            drTextImmune:SetDrawLayer("OVERLAY", 7)
        end
        drTextImmune:SetText("%")
        frame.ArenaDRNameplatesDRTextImmune = drTextImmune
    end

    return frame.ArenaDRNameplatesDRText, frame.ArenaDRNameplatesDRTextImmune
end

local function EnsureImmunityIndicatorRegion(frame)
    if not frame then
        return nil
    end

    local overlay = EnsureVisualOverlay(frame)
    if not overlay then
        return nil
    end

    if not frame.ImmunityIndicator then
        local immunityIndicator = overlay:CreateTexture(nil, "OVERLAY")
        immunityIndicator:SetTexture("Interface\\AddOns\\ArenaDRNameplates\\Images\\shield.tga")
        immunityIndicator:SetSize(12, 12)
        immunityIndicator:SetPoint("CENTER", overlay, "TOP", 0, 2)
        if immunityIndicator.SetDrawLayer then
            immunityIndicator:SetDrawLayer("OVERLAY", 7)
        end
        immunityIndicator:Hide()
        frame.ImmunityIndicator = immunityIndicator
    end

    return frame.ImmunityIndicator
end

local function SetDRTextAlpha(frame, normalAlpha, immuneAlpha)
    local drText, drTextImmune = EnsureDRTextRegions(frame)
    if not drText or not drTextImmune then
        return
    end

    drText:SetAlpha(normalAlpha or 0)
    drTextImmune:SetAlpha(immuneAlpha or 0)
end

local function SetImmunityIndicatorAlpha(frame)
    local indicator = EnsureImmunityIndicatorRegion(frame)
    if not indicator or not indicator.SetAlpha then
        return
    end

    local visibleAlpha = (db and db.showImmunityIndicator) and 1 or 0

    if frame and frame.ArenaDRNameplatesLiveTracksImmunity and indicator.SetAlphaFromBoolean then
        indicator:Show()
        indicator:SetAlphaFromBoolean(frame.ArenaDRNameplatesLiveIsImmune, visibleAlpha, 0)
        return
    end

    indicator:SetAlpha(visibleAlpha)
end

local function SetDRBorderColor(frame, isImmune)
    ApplyDRBorderColor(frame, isImmune)
end

local function ApplyDRBorderVisibilityFromImmune(frame, shown)
    ApplyDRBorderColor(frame, shown)
end

local function ApplyDRVisualStateFromImmune(frame, shown)
    SetImmunityIndicatorAlpha(frame)
    ApplyDRBorderVisibilityFromImmune(frame, shown)

    if not db or not db.showDRText then
        SetDRTextAlpha(frame, 0, 0)
        return
    end

    local drText, drTextImmune = EnsureDRTextRegions(frame)
    if not drText or not drTextImmune then
        return
    end

    drText:SetAlphaFromBoolean(shown, 0, 1)
    drTextImmune:SetAlphaFromBoolean(shown, 1, 0)
end

local function ApplyDRTextStyle(frame, baseFontSize, isImmuneOverride)
    if not frame then
        return
    end

    local overlay = EnsureVisualOverlay(frame)
    local drText, drTextImmune = EnsureDRTextRegions(frame)
    if not overlay or not drText or not drTextImmune then
        return
    end

    SetImmunityIndicatorAlpha(frame)

    local fontSize = tonumber(baseFontSize) or 14
    local anchor = db.drTextAnchor
    if not validDRTextAnchors[anchor] then
        anchor = defaults.drTextAnchor
    end
    local offsetX = tonumber(db.drTextOffsetX) or 4
    local offsetY = tonumber(db.drTextOffsetY) or -4
    local scale = tonumber(db.drTextScale) or 1.0

    drText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    drText:SetText("½")
    drText:SetScale(scale)
    drText:ClearAllPoints()
    drText:SetPoint(anchor, overlay, anchor, offsetX, offsetY)
    drText:SetTextColor(GetDRTextColorRGB(false))

    drTextImmune:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    drTextImmune:SetText("%")
    drTextImmune:SetScale(scale)
    drTextImmune:ClearAllPoints()
    drTextImmune:SetPoint("CENTER", drText, "CENTER", 0, 0)
    drTextImmune:SetTextColor(GetDRTextColorRGB(true))

    if not db.showDRText then
        SetDRTextAlpha(frame, 0, 0)
    else
        SetDRTextAlpha(frame, 1, 0)
    end

    if isImmuneOverride ~= nil then
        ApplyDRVisualStateFromImmune(frame, isImmuneOverride)
        return
    end

    if frame.ImmunityIndicator and frame.ImmunityIndicator.IsShown then
        ApplyDRVisualStateFromImmune(frame, frame.ImmunityIndicator:IsShown())
    else
        ApplyDRVisualStateFromImmune(frame, false)
    end
end

local function ApplyLiveDRTextStyle(frame, baseFontSize)
    ApplyDRTextStyle(frame, baseFontSize, false)
    ApplyDRVisualStateFromImmune(frame, frame and frame.ArenaDRNameplatesLiveIsImmune)
end

local function EnsureDB()
    db = Shared.EnsureDB()
end

local LIVE_ICON_SIZE = 26

local function CreateDRIconFrame(parent, explicitID)
    local icon = CreateFrame("Frame", NextFrameName("Core", "DRIcon", explicitID), parent)
    icon:SetSize(LIVE_ICON_SIZE, LIVE_ICON_SIZE)
    icon:EnableMouse(false)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.Icon = texture

    local cooldown = CreateFrame(
        "Cooldown",
        NextFrameName("Core", "DRCooldown", explicitID),
        icon,
        "CooldownFrameTemplate"
    )
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(false)
    icon.Cooldown = cooldown

    EnsureDRTextRegions(icon)
    EnsureImmunityIndicatorRegion(icon)
    return icon
end

local function GetLiveContainer(arenaID)
    local frame = liveContainers[arenaID]
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", NextFrameName("Core", "LiveContainer", arenaID), UIParent)
    frame:SetSize(1, 1)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(200)
    frame:EnableMouse(false)
    frame.slots = {}
    frame:Hide()
    liveContainers[arenaID] = frame
    return frame
end

local function EnsureLiveSlot(arenaID, slotIndex)
    local container = GetLiveContainer(arenaID)
    container.slots = container.slots or {}

    if container.slots[slotIndex] then
        return container.slots[slotIndex]
    end

    local slot = CreateDRIconFrame(container, "Live" .. tostring(arenaID) .. "_" .. tostring(slotIndex))
    slot:SetFrameLevel(201)
    slot:Hide()
    slot.ArenaDRNameplatesLiveTracksImmunity = true
    slot.ArenaDRNameplatesLiveSourceShown = false
    slot.ArenaDRNameplatesLiveHasTexture = false
    slot.ArenaDRNameplatesLiveHasAtlas = false
    slot.ArenaDRNameplatesLiveIsImmune = false
    ResetLiveSlotSeverity(slot)
    container.slots[slotIndex] = slot
    return slot
end

local function EnsureSourceInfo(arenaID)
    local info = sourceInfoByArenaID[arenaID]
    if info and info.tray then
        return info
    end

    local arenaFrame = _G["CompactArenaFrameMember" .. arenaID]
    local tray = arenaFrame and arenaFrame.SpellDiminishStatusTray
    if not tray then
        return nil
    end

    info = {
        arenaID = arenaID,
        arenaFrame = arenaFrame,
        tray = tray,
    }

    sourceInfoByArenaID[arenaID] = info
    return info
end

local function GetLiveSourceChildren(tray)
    local children = {}
    if not tray then
        return children
    end

    for _, child in ipairs({ tray:GetChildren() }) do
        if child then
            table.insert(children, child)
        end
    end

    return children
end

local function SafeGetShownState(frame)
    if not frame or type(frame.IsShown) ~= "function" then
        return nil
    end

    local ok, shown = pcall(frame.IsShown, frame)
    if not ok or IsSecretValue(shown) or type(shown) ~= "boolean" then
        return nil
    end

    return shown
end

local ANCHOR_POINT_FACTORS = {
    TOPLEFT = { -0.5, 0.5 },
    TOP = { 0, 0.5 },
    TOPRIGHT = { 0.5, 0.5 },
    LEFT = { -0.5, 0 },
    CENTER = { 0, 0 },
    RIGHT = { 0.5, 0 },
    BOTTOMLEFT = { -0.5, -0.5 },
    BOTTOM = { 0, -0.5 },
    BOTTOMRIGHT = { 0.5, -0.5 },
}

local function GetPointOffset(point, width, height)
    local factors = ANCHOR_POINT_FACTORS[tostring(point or "CENTER")] or ANCHOR_POINT_FACTORS.CENTER
    return (width * factors[1]), (height * factors[2])
end

local function GetEffectiveContainerAnchor(parent)
    local point = db and db.point or defaults.point
    local relativePoint = db and db.relativePoint or defaults.relativePoint
    local offsetX = tonumber(db and db.offsetX) or defaults.offsetX
    local offsetY = tonumber(db and db.offsetY) or defaults.offsetY

    if GetIconLayout() ~= "VERTICAL" then
        return point, relativePoint, offsetX, offsetY
    end

    local growth = GetEffectiveIconGrowth()
    local forcedPoint = growth == "DOWN" and "TOP" or "BOTTOM"
    local scaleValue = GetDRTrayScale(parent)
    local baseSize = LIVE_ICON_SIZE * scaleValue
    local oldX, oldY = GetPointOffset(point, baseSize, baseSize)
    local newX, newY = GetPointOffset(forcedPoint, baseSize, baseSize)

    return forcedPoint, relativePoint, offsetX + (newX - oldX), offsetY + (newY - oldY)
end

local function CalculateTrayLayout(iconCount, iconSize, spacing, iconLayout)
    iconCount = math.max(tonumber(iconCount) or 0, 0)
    iconSize = math.max(1, tonumber(iconSize) or 1)
    spacing = math.max(0, tonumber(spacing) or 0)
    iconLayout = tostring(iconLayout or "HORIZONTAL")

    local totalLength = iconSize
    if iconCount > 0 then
        totalLength = (iconCount * iconSize) + (math.max(iconCount - 1, 0) * spacing)
    end

    if iconLayout == "VERTICAL" then
        return iconSize, totalLength, iconSize + spacing
    end

    return totalLength, iconSize, iconSize + spacing
end

local function AnchorChildByGrowth(child, tray, iconLayout, growth, index, childCount, iconPitch)
    child:ClearAllPoints()

    if iconLayout == "VERTICAL" then
        if growth == "UP" then
            child:SetPoint("BOTTOM", tray, "BOTTOM", 0, (index - 1) * iconPitch)
            return
        end

        if growth == "DOWN" then
            child:SetPoint("TOP", tray, "TOP", 0, -((index - 1) * iconPitch))
            return
        end

        local centerOffsetY = (((childCount + 1) / 2) - index) * iconPitch
        child:SetPoint("CENTER", tray, "CENTER", 0, centerOffsetY)
        return
    end

    if growth == "LEFT" then
        child:SetPoint("LEFT", tray, "LEFT", (index - 1) * iconPitch, 0)
        return
    end

    if growth == "RIGHT" then
        child:SetPoint("RIGHT", tray, "RIGHT", -((index - 1) * iconPitch), 0)
        return
    end

    local centerOffset = (index - ((childCount + 1) / 2)) * iconPitch
    child:SetPoint("CENTER", tray, "CENTER", centerOffset, 0)
end

local function GetVisibleLiveSlots(container)
    local visibleSlots = {}
    if not container or type(container.slots) ~= "table" then
        return visibleSlots
    end

    for _, slot in ipairs(container.slots) do
        if slot and slot:IsShown() then
            table.insert(visibleSlots, slot)
        end
    end

    return visibleSlots
end

local function ApplyLiveSlotStyle(slot)
    if not slot then
        return
    end

    ApplyCooldownStyle(slot.Cooldown)

    local timerText = FindCooldownText(slot)
    if timerText then
        ApplyTimerTextStyle(timerText, slot, 14)
    end

    ApplyLiveDRTextStyle(slot, 14)
end

local function LayoutLiveContainer(arenaID)
    local container = liveContainers[arenaID]
    if not container then
        return 0
    end

    local visibleSlots = GetVisibleLiveSlots(container)
    local childCount = #visibleSlots
    local iconSpacing = GetIconPadding()
    local iconLayout = GetIconLayout()
    local layoutWidth, layoutHeight, iconPitch = CalculateTrayLayout(
        childCount,
        LIVE_ICON_SIZE,
        iconSpacing,
        iconLayout
    )
    local growth = GetEffectiveIconGrowth()
    local scaleValue = GetDRTrayScale(container:GetParent())

    container:SetSize(layoutWidth, layoutHeight)
    container:SetScale(scaleValue)
    container:SetAlpha(tonumber(db and db.opacity) or 1.0)

    for index, slot in ipairs(visibleSlots) do
        slot:SetSize(LIVE_ICON_SIZE, LIVE_ICON_SIZE)
        ApplyLiveSlotStyle(slot)
        AnchorChildByGrowth(slot, container, iconLayout, growth, index, childCount, iconPitch)
    end

    if childCount == 0 then
        container:Hide()
    end

    return childCount
end

local function ClearLiveSlotCooldown(slot)
    if not slot or not slot.Cooldown then
        return
    end

    ClearCooldownCompat(slot.Cooldown)
end

local function UpdateLiveSlotVisibility(arenaID, slot)
    if not slot then
        return
    end

    local hasVisual = slot.ArenaDRNameplatesLiveHasTexture == true
        or slot.ArenaDRNameplatesLiveHasAtlas == true
    local shouldShow = slot.ArenaDRNameplatesLiveSourceShown ~= false and hasVisual

    slot:SetShown(shouldShow)
    LayoutLiveContainer(arenaID)
end

local function SetLiveSlotTexture(arenaID, slot, texture)
    if not slot or not slot.Icon or not slot.Icon.SetTexture then
        return
    end

    if texture == nil then
        slot.Icon:SetTexture(nil)
        slot.ArenaDRNameplatesLiveHasTexture = false
        UpdateLiveSlotVisibility(arenaID, slot)
        return
    end

    if not IsSecretValue(texture) and (texture == "" or texture == 0) then
        slot.Icon:SetTexture(nil)
        slot.ArenaDRNameplatesLiveHasTexture = false
        UpdateLiveSlotVisibility(arenaID, slot)
        return
    end

    if slot.Icon.SetTexCoord then
        slot.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    slot.Icon:SetTexture(texture)
    slot.ArenaDRNameplatesLiveHasTexture = true
    slot.ArenaDRNameplatesLiveHasAtlas = false
    UpdateLiveSlotVisibility(arenaID, slot)
end

local function SetLiveSlotAtlas(arenaID, slot, atlas)
    if not slot or not slot.Icon or not slot.Icon.SetAtlas then
        return
    end

    if atlas == nil then
        slot.ArenaDRNameplatesLiveHasAtlas = false
        UpdateLiveSlotVisibility(arenaID, slot)
        return
    end

    if not IsSecretValue(atlas) and atlas == "" then
        slot.ArenaDRNameplatesLiveHasAtlas = false
        UpdateLiveSlotVisibility(arenaID, slot)
        return
    end

    if slot.Icon.SetTexCoord then
        slot.Icon:SetTexCoord(0, 1, 0, 1)
    end
    slot.Icon:SetAtlas(atlas, true)
    slot.ArenaDRNameplatesLiveHasAtlas = true
    slot.ArenaDRNameplatesLiveHasTexture = false
    UpdateLiveSlotVisibility(arenaID, slot)
end

local function SetLiveSlotImmunity(arenaID, slot, isShown)
    if not slot or not slot.ImmunityIndicator then
        return
    end

    slot.ArenaDRNameplatesLiveIsImmune = isShown
    ApplyLiveSlotStyle(slot)
    LayoutLiveContainer(arenaID)
end

local function GetLiveAnchorParent(arenaID)
    local helper = GetHelper()
    if not helper or type(helper.GetAnchorParentByArenaID) ~= "function" then
        return nil
    end
    return helper:GetAnchorParentByArenaID(arenaID)
end

local function HookLiveSourceItem(arenaID, slotIndex, sourceItem)
    if not sourceItem then
        return
    end

    local slot = EnsureLiveSlot(arenaID, slotIndex)
    sourceItem.ArenaDRNameplatesLiveMirrorArenaID = arenaID
    sourceItem.ArenaDRNameplatesLiveMirrorSlot = slot

    local sourceIcon = FindTextureRegion(sourceItem)
    local sourceCooldown = FindCooldownFrame(sourceItem)
    local sourceIndicator = sourceItem.ImmunityIndicator

    local shown = SafeGetShownState(sourceItem)
    if shown ~= nil then
        slot.ArenaDRNameplatesLiveSourceShown = shown
        if shown then
            if (tonumber(slot.ArenaDRNameplatesLiveSeverity) or 0) == 0 then
                IncrementLiveSlotSeverity(slot)
            end
        else
            ResetLiveSlotSeverity(slot)
        end
    end

    if sourceIcon and sourceIcon.GetAtlas and slot.Icon.SetAtlas then
        local okAtlas, atlas = pcall(sourceIcon.GetAtlas, sourceIcon)
        if okAtlas and atlas ~= nil then
            SetLiveSlotAtlas(arenaID, slot, atlas)
        end
    end

    if sourceIcon and sourceIcon.GetTexture then
        local okTexture, texture = pcall(sourceIcon.GetTexture, sourceIcon)
        if okTexture and texture ~= nil then
            SetLiveSlotTexture(arenaID, slot, texture)
        end
    end

    local indicatorShown = SafeGetShownState(sourceIndicator)
    if indicatorShown ~= nil then
        SetLiveSlotImmunity(arenaID, slot, indicatorShown)
    end

    if not sourceItem.ArenaDRNameplatesLiveMirrorHooked then
        sourceItem.ArenaDRNameplatesLiveMirrorHooked = true

        -- The hook callback's self argument can be a secret table while in
        -- combat. Use the non-secret frame reference captured when the hook
        -- was installed instead of indexing that callback argument.
        hooksecurefunc(sourceItem, "Show", function()
            local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
            local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
            if not hookedSlot or not hookedArenaID then
                return
            end

            IncrementLiveSlotSeverity(hookedSlot)
            hookedSlot.ArenaDRNameplatesLiveSourceShown = true
            UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
        end)

        hooksecurefunc(sourceItem, "Hide", function()
            local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
            local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
            if not hookedSlot or not hookedArenaID then
                return
            end

            hookedSlot.ArenaDRNameplatesLiveSourceShown = false
            ClearLiveSlotCooldown(hookedSlot)
            ResetLiveSlotSeverity(hookedSlot)
            SetLiveSlotImmunity(hookedArenaID, hookedSlot, false)
            UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
        end)
    end

    if sourceIcon and sourceItem.ArenaDRNameplatesLiveIconHookTarget ~= sourceIcon then
        sourceItem.ArenaDRNameplatesLiveIconHookTarget = sourceIcon

        if sourceIcon.SetTexture then
            hooksecurefunc(sourceIcon, "SetTexture", function(_, texture)
                local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
                local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
                if not hookedSlot or not hookedArenaID then
                    return
                end

                SetLiveSlotTexture(hookedArenaID, hookedSlot, texture)
            end)
        end

        if sourceIcon.SetAtlas and slot.Icon.SetAtlas then
            hooksecurefunc(sourceIcon, "SetAtlas", function(_, atlas)
                local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
                local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
                if not hookedSlot or not hookedArenaID then
                    return
                end

                SetLiveSlotAtlas(hookedArenaID, hookedSlot, atlas)
            end)
        end
    end

    if sourceCooldown and sourceItem.ArenaDRNameplatesLiveCooldownHookTarget ~= sourceCooldown then
        sourceItem.ArenaDRNameplatesLiveCooldownHookTarget = sourceCooldown

        if sourceCooldown.SetCooldown then
            hooksecurefunc(sourceCooldown, "SetCooldown", function()
                local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
                local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
                if not hookedSlot or not hookedArenaID or not hookedSlot.Cooldown then
                    return
                end

                StartLiveSlotCooldown(hookedSlot, LIVE_DR_TIMER_DURATION)
                UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
            end)
        end

        sourceCooldown:HookScript("OnCooldownDone", function()
            local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
            local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
            if not hookedSlot or not hookedArenaID then
                return
            end

            ClearLiveSlotCooldown(hookedSlot)
            UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
        end)

        sourceCooldown:HookScript("OnHide", function()
            local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
            local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
            if not hookedSlot or not hookedArenaID then
                return
            end

            ClearLiveSlotCooldown(hookedSlot)
            UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
        end)
    end

    if sourceIndicator and sourceItem.ArenaDRNameplatesLiveIndicatorHookTarget ~= sourceIndicator then
        sourceItem.ArenaDRNameplatesLiveIndicatorHookTarget = sourceIndicator

        if sourceIndicator.SetShown then
            hooksecurefunc(sourceIndicator, "SetShown", function(_, shown)
                local hookedSlot = sourceItem.ArenaDRNameplatesLiveMirrorSlot
                local hookedArenaID = sourceItem.ArenaDRNameplatesLiveMirrorArenaID
                if not hookedSlot or not hookedArenaID then
                    return
                end

                ClearLiveSlotCooldown(hookedSlot)
                StartLiveSlotCooldown(hookedSlot, GetLiveSlotImmunityDuration(hookedSlot))
                SetLiveSlotImmunity(hookedArenaID, hookedSlot, shown)
                UpdateLiveSlotVisibility(hookedArenaID, hookedSlot)
            end)
        end
    end

    UpdateLiveSlotVisibility(arenaID, slot)
end

local function AnchorLiveTray(arenaID)
    local info = EnsureSourceInfo(arenaID)
    local parent = GetLiveAnchorParent(arenaID)
    local container = GetLiveContainer(arenaID)

    if not info or not info.tray then
        container:Hide()
        return
    end

    if not parent then
        ParkFrameOffscreen(container)
        return
    end

    if container:GetParent() ~= parent then
        container:SetParent(parent)
    end

    container:ClearAllPoints()
    do
        local point, relativePoint, offsetX, offsetY = GetEffectiveContainerAnchor(parent)
        container:SetPoint(point, parent, relativePoint, offsetX, offsetY)
    end
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(200)

    local sourceChildren = GetLiveSourceChildren(info.tray)
    for slotIndex, sourceItem in ipairs(sourceChildren) do
        HookLiveSourceItem(arenaID, slotIndex, sourceItem)
    end

    if type(container.slots) == "table" then
        for slotIndex = #sourceChildren + 1, #container.slots do
            local slot = container.slots[slotIndex]
            if slot then
                slot.ArenaDRNameplatesLiveSourceShown = false
                ClearLiveSlotCooldown(slot)
                SetLiveSlotImmunity(arenaID, slot, false)
                UpdateLiveSlotVisibility(arenaID, slot)
            end
        end
    end

    if LayoutLiveContainer(arenaID) > 0 then
        container:Show()
    end
end

local function RestoreAllLiveTrays()
    for _, arenaID in ipairs(ARENA_IDS) do
        local container = liveContainers[arenaID]
        if container then
            container:Hide()
        end
    end
end

local function RefreshLiveTrays()
    if not db or not db.enabled or not IsInArena() then
        RestoreAllLiveTrays()
        return
    end

    for _, arenaID in ipairs(ARENA_IDS) do
        AnchorLiveTray(arenaID)
    end
end

local TRINKET_ALLIANCE_ICON = 133452
local TRINKET_HORDE_ICON = 133453

local function GetArenaMember(arenaID)
    return _G["CompactArenaFrameMember" .. tostring(arenaID)]
end

local function IsArenaMatchEngaged()
    if not IsInArena() then
        return false
    end

    if C_PvP and C_PvP.GetActiveMatchState and Enum and Enum.PvPMatchState and Enum.PvPMatchState.Engaged then
        local ok, state = pcall(C_PvP.GetActiveMatchState)
        if ok and type(state) == "number" then
            return state == Enum.PvPMatchState.Engaged
        end
    end

    return true
end

local function GetTrinketSourceFrame(arenaID)
    local arenaFrame = GetArenaMember(arenaID)
    if not arenaFrame then
        return nil
    end

    return arenaFrame.CcRemoverFrame
end

local function GetUnitTrinketFallbackTexture(unit)
    local faction = UnitFactionGroup(unit)
    if faction == "Alliance" then
        return TRINKET_ALLIANCE_ICON
    end

    return TRINKET_HORDE_ICON
end

local function EnsureTrinketBorder(frame)
    if not frame then
        return nil
    end

    local borderStyle = GetTrinketBorderStyle()
    if borderStyle == "NONE" then
        if frame.ArenaDRNameplatesTrinketBorderSegments then
            for _, segment in ipairs(frame.ArenaDRNameplatesTrinketBorderSegments) do
                segment:Hide()
            end
        end
        if frame.ArenaDRNameplatesTrinketClassicBorder then
            frame.ArenaDRNameplatesTrinketClassicBorder:Hide()
        end
        return nil
    end

    local r, g, b = GetTrinketBorderColorRGB()
    local borderParent = EnsureVisualOverlay(frame) or frame
    if borderStyle == "CLASSIC" then
        if frame.ArenaDRNameplatesTrinketBorderSegments then
            for _, segment in ipairs(frame.ArenaDRNameplatesTrinketBorderSegments) do
                segment:Hide()
            end
        end

        if not frame.ArenaDRNameplatesTrinketClassicBorder then
            local border = borderParent:CreateTexture(nil, "OVERLAY")
            border:SetTexture(CLASSIC_BORDER_TEXTURE)
            border:SetTexCoord(unpack(CLASSIC_BORDER_TEX_COORDS))
            frame.ArenaDRNameplatesTrinketClassicBorder = border
        end

        local border = frame.ArenaDRNameplatesTrinketClassicBorder
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", borderParent, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", borderParent, "BOTTOMRIGHT", 1, -1)
        border:SetVertexColor(r, g, b, 1)
        border:Show()
        return border
    end

    if frame.ArenaDRNameplatesTrinketClassicBorder then
        frame.ArenaDRNameplatesTrinketClassicBorder:Hide()
    end

    if not frame.ArenaDRNameplatesTrinketBorderSegments then
        local function CreateSegment()
            local segment = borderParent:CreateTexture(nil, "OVERLAY")
            segment:SetTexture("Interface\\Buttons\\WHITE8X8")
            return segment
        end

        frame.ArenaDRNameplatesTrinketBorderSegments = {
            CreateSegment(),
            CreateSegment(),
            CreateSegment(),
            CreateSegment(),
        }
    end

    local borderSegments = frame.ArenaDRNameplatesTrinketBorderSegments
    local borderWidth = GetTrinketBorderWidth()
    local extent = borderWidth / 2
    local top = borderSegments[1]
    local bottom = borderSegments[2]
    local left = borderSegments[3]
    local right = borderSegments[4]

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", borderParent, "TOPLEFT", -extent, extent)
    top:SetPoint("TOPRIGHT", borderParent, "TOPRIGHT", extent, extent)
    top:SetHeight(borderWidth)

    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", borderParent, "BOTTOMLEFT", -extent, -extent)
    bottom:SetPoint("BOTTOMRIGHT", borderParent, "BOTTOMRIGHT", extent, -extent)
    bottom:SetHeight(borderWidth)

    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", borderParent, "TOPLEFT", -extent, extent)
    left:SetPoint("BOTTOMLEFT", borderParent, "BOTTOMLEFT", -extent, -extent)
    left:SetWidth(borderWidth)

    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", borderParent, "TOPRIGHT", extent, extent)
    right:SetPoint("BOTTOMRIGHT", borderParent, "BOTTOMRIGHT", extent, -extent)
    right:SetWidth(borderWidth)

    for _, segment in ipairs(borderSegments) do
        segment:SetVertexColor(r, g, b, 1)
        segment:Show()
    end

    return borderSegments
end

local function CreateTrinketIconFrame(parent, explicitID)
    local frame = CreateFrame("Frame", NextFrameName("Core", "TrinketIcon", explicitID), parent)
    frame:SetSize(GetTrinketSize(), GetTrinketSize())
    frame:EnableMouse(false)
    frame.hasActiveCooldown = false
    frame.hasSourceTexture = false
    frame.hasFallbackTexture = false

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0.45)
    frame.Background = background

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(frame)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.Icon = texture

    local cooldown = CreateFrame(
        "Cooldown",
        NextFrameName("Core", "TrinketCooldown", explicitID),
        frame,
        "CooldownFrameTemplate"
    )
    cooldown:SetAllPoints(frame)
    frame.Cooldown = cooldown

    EnsureTrinketBorder(frame)
    return frame
end

local function ClearLiveTrinketMirrorCooldown(frame)
    if not frame then
        return
    end

    frame.hasActiveCooldown = false
    ClearCooldownCompat(frame.Cooldown)
end

local function UpdateLiveTrinketMirrorVisibility(frame)
    if not frame then
        return
    end

    local hasTexture = frame.hasSourceTexture == true or frame.hasFallbackTexture == true
    local shouldShow = IsTrinketEnabled()
        and IsInArena()
        and IsArenaMatchEngaged()
        and hasTexture
        and (GetTrinketVisibilityMode() == "ALWAYS" or frame.hasActiveCooldown == true)

    frame:SetShown(shouldShow)
end

local function ApplyLiveTrinketFallback(frame, arenaUnit)
    if not frame then
        return
    end

    frame.fallbackUnit = arenaUnit
    if frame.hasSourceTexture == true then
        frame.hasFallbackTexture = false
        return
    end

    local fallbackTexture = GetUnitTrinketFallbackTexture(arenaUnit)
    if fallbackTexture then
        frame.Icon:SetTexture(fallbackTexture)
        frame.hasFallbackTexture = true
    else
        frame.Icon:SetTexture(nil)
        frame.hasFallbackTexture = false
    end
end

local function SetLiveTrinketMirrorTexture(frame, texture)
    if not frame then
        return
    end

    if IsSecretValue(texture) then
        frame.Icon:SetTexture(texture)
        frame.hasSourceTexture = true
        frame.hasFallbackTexture = false
        UpdateLiveTrinketMirrorVisibility(frame)
        return
    end

    if texture == nil or texture == "" or texture == 0 then
        frame.hasSourceTexture = false
        ApplyLiveTrinketFallback(frame, frame.fallbackUnit)
        UpdateLiveTrinketMirrorVisibility(frame)
        return
    end

    frame.Icon:SetTexture(texture)
    frame.hasSourceTexture = true
    frame.hasFallbackTexture = false
    UpdateLiveTrinketMirrorVisibility(frame)
end

local function ApplyLiveTrinketCooldown(frame, arenaUnit, startTime, duration)
    if not frame or not frame.Cooldown then
        return
    end

    local usedDurationObject = false
    if C_PvP and C_PvP.GetArenaCrowdControlDuration and frame.Cooldown.SetCooldownFromDurationObject then
        local okObj, durationObject = pcall(C_PvP.GetArenaCrowdControlDuration, arenaUnit)
        if okObj and durationObject then
            local okSet = pcall(function()
                frame.Cooldown:SetCooldownFromDurationObject(durationObject)
            end)
            usedDurationObject = okSet == true
        end
    end

    if not usedDurationObject and startTime ~= nil and duration ~= nil then
        pcall(function()
            frame.Cooldown:SetCooldown(startTime, duration)
        end)
    end

    if frame.Cooldown.SetReverse then
        frame.Cooldown:SetReverse(false)
    end

    frame.hasActiveCooldown = true
    UpdateLiveTrinketMirrorVisibility(frame)
end

local function HookLiveTrinketSource(arenaID, frame, sourceFrame)
    if not frame or not sourceFrame then
        return
    end

    local arenaUnit = "arena" .. tostring(arenaID)
    local sourceIcon = FindTextureRegion(sourceFrame)
    local sourceCooldown = FindCooldownFrame(sourceFrame)

    if sourceIcon and sourceIcon.GetTexture then
        local ok, texture = pcall(sourceIcon.GetTexture, sourceIcon)
        if ok then
            SetLiveTrinketMirrorTexture(frame, texture)
        end
    end

    if sourceIcon and frame.sourceIconHookTarget ~= sourceIcon then
        frame.sourceIconHookTarget = sourceIcon

        if sourceIcon.SetTexture then
            hooksecurefunc(sourceIcon, "SetTexture", function(_, texture)
                SetLiveTrinketMirrorTexture(frame, texture)
            end)
        end
    end

    if sourceCooldown and frame.sourceCooldownHookTarget ~= sourceCooldown then
        frame.sourceCooldownHookTarget = sourceCooldown

        if sourceCooldown.SetCooldown then
            hooksecurefunc(sourceCooldown, "SetCooldown", function(_, startTime, duration)
                if not IsTrinketEnabled() or not IsInArena() or not IsArenaMatchEngaged() then
                    ClearLiveTrinketMirrorCooldown(frame)
                    UpdateLiveTrinketMirrorVisibility(frame)
                    return
                end

                if duration == nil or (not IsSecretValue(duration) and duration <= 0) then
                    ClearLiveTrinketMirrorCooldown(frame)
                    UpdateLiveTrinketMirrorVisibility(frame)
                    return
                end

                ApplyLiveTrinketCooldown(frame, arenaUnit, startTime, duration)
            end)
        end

        sourceCooldown:HookScript("OnCooldownDone", function()
            ClearLiveTrinketMirrorCooldown(frame)
            UpdateLiveTrinketMirrorVisibility(frame)
        end)
    end
end

local function ApplyTrinketFrameStyle(frame)
    if not frame then
        return
    end

    local size = GetTrinketSize()
    frame:SetSize(size, size)
    frame:SetAlpha(GetTrinketOpacity())

    ApplyCooldownStyle(frame.Cooldown)
    if frame.Cooldown and frame.Cooldown.SetReverse then
        frame.Cooldown:SetReverse(false)
    end

    local timerText = FindCooldownText(frame)
    if timerText then
        ApplyTimerTextStyle(timerText, frame, GetTrinketTimerBaseFontSize(size))
    end

    EnsureTrinketBorder(frame)
end

local function GetLiveTrinketMirror(arenaID)
    if trinketMirrors[arenaID] then
        return trinketMirrors[arenaID]
    end

    local frame = CreateTrinketIconFrame(UIParent, "Live" .. tostring(arenaID))
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(220)
    frame:Hide()
    trinketMirrors[arenaID] = frame
    return frame
end

local function HideLiveTrinketMirror(arenaID)
    local frame = trinketMirrors[arenaID]
    if not frame then
        return
    end

    frame.hasSourceTexture = false
    frame.hasFallbackTexture = false
    ClearLiveTrinketMirrorCooldown(frame)
    frame.Icon:SetTexture(nil)
    frame:Hide()
end

local function HideAllLiveTrinketMirrors()
    for _, arenaID in ipairs(ARENA_IDS) do
        HideLiveTrinketMirror(arenaID)
    end
end

local function UpdateLiveTrinketMirror(arenaID)
    local parent = GetLiveAnchorParent(arenaID)
    if not parent then
        ParkFrameOffscreen(GetLiveTrinketMirror(arenaID))
        return
    end

    local frame = GetLiveTrinketMirror(arenaID)
    if frame:GetParent() ~= parent then
        frame:SetParent(parent)
    end

    ApplyTrinketFrameStyle(frame)

    frame:ClearAllPoints()
    do
        local point, relativePoint, offsetX, offsetY = GetEffectiveTrinketAnchor()
        frame:SetPoint(point, parent, relativePoint, offsetX, offsetY)
    end

    ApplyLiveTrinketFallback(frame, "arena" .. tostring(arenaID))

    local sourceFrame = GetTrinketSourceFrame(arenaID)
    if sourceFrame then
        HookLiveTrinketSource(arenaID, frame, sourceFrame)
    else
        ClearLiveTrinketMirrorCooldown(frame)
    end

    if not IsArenaMatchEngaged() then
        ClearLiveTrinketMirrorCooldown(frame)
    end

    UpdateLiveTrinketMirrorVisibility(frame)
end

local function RefreshLiveTrinketMirrors()
    if not db or not db.enabled or not IsInArena() or not IsTrinketEnabled() then
        HideAllLiveTrinketMirrors()
        return
    end

    for _, arenaID in ipairs(ARENA_IDS) do
        UpdateLiveTrinketMirror(arenaID)
    end
end

local function GetNameplateAnchorParentForTarget()
    local helper = GetHelper()
    if helper and type(helper.GetAnchorParentByUnit) == "function" then
        local parent = helper:GetAnchorParentByUnit("target")
        if parent then
            return parent
        end
    end

    local plate = C_NamePlate.GetNamePlateForUnit("target")
    if not plate then
        return nil
    end

    local unitFrame = nil
    if type(plate.UnitFrame) == "table" then
        unitFrame = plate.UnitFrame
    elseif type(plate.unitFrame) == "table" then
        unitFrame = plate.unitFrame
    end

    if unitFrame then
        for _, key in ipairs({
            "HealthBarsContainer",
            "healthBarsContainer",
            "healthBar",
            "HealthBar",
        }) do
            if type(unitFrame[key]) == "table" then
                return unitFrame[key]
            end
        end

        return unitFrame
    end

    return plate
end

local function CreateTestIcon(parent)
    return CreateDRIconFrame(parent)
end

local function GetVisiblePreviewNameplates()
    local helper = GetHelper()
    if helper and type(helper.GetVisibleEnemyNameplates) == "function" then
        local entries = helper:GetVisibleEnemyNameplates()
        if type(entries) == "table" and #entries > 0 then
            return entries
        end
    end

    if IsEnemyTarget() then
        local parent = GetNameplateAnchorParentForTarget()
        if parent then
            local guid = UnitGUID("target")
            if IsSecretValue(guid) or type(guid) ~= "string" or guid == "" then
                guid = nil
            end

            return {
                {
                    token = "target",
                    guid = guid,
                    parent = parent,
                },
            }
        end
    end

    return {}
end

local function EnsureTestTray(previewKey)
    previewKey = tostring(previewKey or "Default")

    local tray = testTrays[previewKey]
    if tray then
        return tray
    end

    tray = CreateFrame("Frame", NextFrameName("Core", "TestTray", previewKey), UIParent)
    tray:SetSize(1, 1)
    tray:SetFrameStrata("HIGH")
    tray:SetFrameLevel(250)
    tray.previewIcons = {}
    tray.previewKey = previewKey
    tray:Hide()
    testTrays[previewKey] = tray
    return tray
end

local function EnsureTestTrinketIcon()
    if testTrinketIcon then
        return testTrinketIcon
    end

    testTrinketIcon = CreateTrinketIconFrame(UIParent, "Test")
    testTrinketIcon:SetFrameStrata("HIGH")
    testTrinketIcon:SetFrameLevel(260)
    testTrinketIcon:Hide()
    return testTrinketIcon
end

local function ClearPreviewConfigs()
    for key in pairs(testConfigsByKey) do
        testConfigsByKey[key] = nil
    end
end

local function CreatePreviewSpellSet()
    local pool = {}
    for index, spellData in ipairs(TEST_SPELLS) do
        pool[index] = spellData
    end

    for index = #pool, 2, -1 do
        local swapIndex = math.random(index)
        pool[index], pool[swapIndex] = pool[swapIndex], pool[index]
    end

    local count = math.random(PREVIEW_MIN_DR_COUNT, math.min(PREVIEW_MAX_DR_COUNT, #pool))
    local spells = {}
    for index = 1, count do
        local source = pool[index]
        local duration = math.random(PREVIEW_MIN_DURATION, PREVIEW_MAX_DURATION)
        spells[index] = {
            spellID = source.spellID,
            duration = duration,
            isImmune = source.isImmune == true,
            previewOffset = math.random(0, math.max(duration - 2, 0)),
        }
    end

    return spells
end

local function GetPreviewTrayKey(entry, index)
    if type(entry) == "table" then
        if type(entry.token) == "string" and entry.token ~= "" and not IsSecretValue(entry.token) then
            return entry.token
        end
        if type(entry.guid) == "string" and entry.guid ~= "" and not IsSecretValue(entry.guid) then
            return entry.guid
        end
    end

    return "Preview" .. tostring(index or 0)
end

local function GetPreviewConfigKey(entry, index)
    if type(entry) == "table" then
        if type(entry.guid) == "string" and entry.guid ~= "" and not IsSecretValue(entry.guid) then
            return entry.guid
        end
        if type(entry.token) == "string" and entry.token ~= "" and not IsSecretValue(entry.token) then
            return entry.token
        end
    end

    return "Preview" .. tostring(index or 0)
end

local function GetPreviewConfig(previewKey)
    previewKey = tostring(previewKey or "Default")
    local config = testConfigsByKey[previewKey]
    if config then
        return config
    end

    config = {
        spells = CreatePreviewSpellSet(),
    }
    testConfigsByKey[previewKey] = config
    return config
end

local function ResetPreviewIconTimerCache(icon)
    if not icon then
        return
    end

    icon.ArenaDRPreviewCooldownCycle = nil
    icon.ArenaDRPreviewCooldownDuration = nil
    icon.ArenaDRPreviewCooldownOffset = nil
    icon.ArenaDRPreviewShowSwipe = nil
    icon.ArenaDRPreviewShowSwipeEdge = nil
end

local function ResetPreviewTimerCache()
    for _, tray in pairs(testTrays) do
        if tray and type(tray.previewIcons) == "table" then
            for _, icon in ipairs(tray.previewIcons) do
                ResetPreviewIconTimerCache(icon)
            end
        end
    end
end

local function HideAllTestTrays()
    for _, tray in pairs(testTrays) do
        if tray then
            tray:Hide()
        end
    end
end

local function ApplyPreviewCooldown(icon, spellData)
    if not icon or not icon.Cooldown or not icon.Cooldown.SetCooldown then
        return
    end

    local duration = math.max(1, tonumber(spellData and spellData.duration) or 18)
    if not testModeStartedAt then
        if type(CooldownFrame_Clear) == "function" then
            CooldownFrame_Clear(icon.Cooldown)
        else
            icon.Cooldown:SetCooldown(0, 0)
        end
        return
    end

    local now = GetTime()
    local previewOffset = ClampNumber(spellData and spellData.previewOffset, 0, duration, 0)
    local elapsed = math.max(0, now - testModeStartedAt + previewOffset)
    local cycle = math.floor(elapsed / duration)
    local showSwipe = IsTimerSwipeEnabled()
    local showSwipeEdge = showSwipe and IsTimerSwipeEdgeEnabled()

    if icon.ArenaDRPreviewCooldownCycle == cycle
        and icon.ArenaDRPreviewCooldownDuration == duration
        and icon.ArenaDRPreviewCooldownOffset == previewOffset
        and icon.ArenaDRPreviewShowSwipe == showSwipe
        and icon.ArenaDRPreviewShowSwipeEdge == showSwipeEdge then
        return
    end

    local cycleStart = testModeStartedAt - previewOffset + (cycle * duration)
    icon.Cooldown:SetCooldown(cycleStart, duration)
    icon.ArenaDRPreviewCooldownCycle = cycle
    icon.ArenaDRPreviewCooldownDuration = duration
    icon.ArenaDRPreviewCooldownOffset = previewOffset
    icon.ArenaDRPreviewShowSwipe = showSwipe
    icon.ArenaDRPreviewShowSwipeEdge = showSwipeEdge
end

local function ApplyTestTrayLayout(tray, parent, spells)
    if not tray then
        return 1, 1
    end

    spells = type(spells) == "table" and spells or TEST_SPELLS

    local scaleValue = GetDRTrayScale(parent or tray:GetParent())
    local spacing = GetIconPadding()
    local iconCount = #spells
    local iconLayout = GetIconLayout()
    local layoutWidth, layoutHeight, iconPitch = CalculateTrayLayout(
        iconCount,
        LIVE_ICON_SIZE,
        spacing,
        iconLayout
    )
    local growth = GetEffectiveIconGrowth()

    tray:SetSize(layoutWidth, layoutHeight)
    tray:SetScale(scaleValue)
    tray:SetAlpha(tonumber(db.opacity) or 1.0)

    tray.previewIcons = tray.previewIcons or {}
    for index, spellData in ipairs(spells) do
        local icon = tray.previewIcons[index] or CreateTestIcon(tray)
        tray.previewIcons[index] = icon
        icon:Show()
        icon:SetSize(LIVE_ICON_SIZE, LIVE_ICON_SIZE)

        local spellInfo = C_Spell.GetSpellInfo(spellData.spellID)
        if spellInfo then
            icon.Icon:SetTexture(spellInfo.iconID or spellInfo.originalIconID)
        else
            icon.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        AnchorChildByGrowth(icon, tray, iconLayout, growth, index, iconCount, iconPitch)
        ApplyCooldownStyle(icon.Cooldown)
        ApplyPreviewCooldown(icon, spellData)

        SetDRBorderColor(icon, spellData.isImmune == true)

        if icon.ImmunityIndicator then
            if spellData.isImmune == true then
                icon.ImmunityIndicator:Show()
            else
                icon.ImmunityIndicator:Hide()
            end
            SetImmunityIndicatorAlpha(icon)
        end

        local timerText = FindCooldownText(icon)
        if timerText then
            ApplyTimerTextStyle(timerText, icon, 14)
        end

        ApplyDRTextStyle(icon, 14, spellData.isImmune == true)
    end

    for index = iconCount + 1, #tray.previewIcons do
        local icon = tray.previewIcons[index]
        if icon then
            ResetPreviewIconTimerCache(icon)
            icon:Hide()
        end
    end

    return layoutWidth, layoutHeight
end

local function RefreshTestTrays()
    if not testMode then
        HideAllTestTrays()
        return
    end

    local activeKeys = {}
    local entries = GetVisiblePreviewNameplates()
    for index, entry in ipairs(entries) do
        local parent = type(entry) == "table" and entry.parent or nil
        if parent then
            local trayKey = GetPreviewTrayKey(entry, index)
            local configKey = GetPreviewConfigKey(entry, index)
            activeKeys[trayKey] = true

            local tray = EnsureTestTray(trayKey)
            if tray:GetParent() ~= parent then
                tray:SetParent(parent)
            end

            local config = GetPreviewConfig(configKey)
            ApplyTestTrayLayout(tray, parent, config.spells)

            tray:ClearAllPoints()
            do
                local point, relativePoint, offsetX, offsetY = GetEffectiveContainerAnchor(parent)
                tray:SetPoint(point, parent, relativePoint, offsetX, offsetY)
            end
            tray:SetFrameStrata("HIGH")
            tray:SetFrameLevel(210)
            tray:Show()
        end
    end

    for trayKey, tray in pairs(testTrays) do
        if tray and not activeKeys[trayKey] then
            tray:Hide()
        end
    end
end

local function RefreshTestTrinket()
    local frame = EnsureTestTrinketIcon()

    if not testMode or not IsTrinketEnabled() or not IsEnemyTarget() then
        frame.previewCooldownCycle = nil
        frame.previewCooldownDuration = nil
        ClearCooldownCompat(frame.Cooldown)
        frame:Hide()
        return
    end

    local parent = GetNameplateAnchorParentForTarget()
    if not parent then
        frame:Hide()
        return
    end

    if frame:GetParent() ~= parent then
        frame:SetParent(parent)
    end

    ApplyTrinketFrameStyle(frame)

    frame:ClearAllPoints()
    do
        local point, relativePoint, offsetX, offsetY = GetEffectiveTrinketAnchor()
        frame:SetPoint(point, parent, relativePoint, offsetX, offsetY)
    end

    local texture = GetUnitTrinketFallbackTexture("target")
    if frame.lastTexture ~= texture then
        frame.Icon:SetTexture(texture)
        frame.lastTexture = texture
    end

    ApplyPreviewCooldown(frame, { duration = 30 })
    if frame.Cooldown and frame.Cooldown.SetReverse then
        frame.Cooldown:SetReverse(false)
    end

    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(260)
    frame:Show()
end

local function StartTestMode()
    if testMode then
        return
    end

    testMode = true
    testModeStartedAt = GetTime()
    ClearPreviewConfigs()
    ResetPreviewTimerCache()
    RefreshTestTrays()
    NotifySettingsUIRefresh()
end

local function StopTestMode()
    local wasActive = testMode
    testMode = false
    testModeStartedAt = nil
    ResetPreviewTimerCache()
    ClearPreviewConfigs()
    HideAllTestTrays()

    if testTrinketIcon then
        testTrinketIcon.previewCooldownCycle = nil
        testTrinketIcon.previewCooldownDuration = nil
        ClearCooldownCompat(testTrinketIcon.Cooldown)
        testTrinketIcon:Hide()
    end

    if wasActive then
        NotifySettingsUIRefresh()
    end
end

local function ToggleTestMode()
    if testMode then
        StopTestMode()
    else
        StartTestMode()
    end
end

local function RefreshAll()
    RefreshLiveTrays()
    RefreshLiveTrinketMirrors()
    RefreshTestTrays()
    RefreshTestTrinket()
end

local function ResetPosition()
    if not db then
        return
    end

    Shared.CopyDefaultsIntoTable(db, true)
    Shared.ResetBlizzardDRCVarsToDefaults()

    StopTestMode()
    RefreshAll()
end

local function ApplyAnchorPreset(preset)
    if not db then
        return
    end

    Shared.ApplyAnchorPresetToTable(db, preset)
    RefreshAll()
end

local function SetAdvancedAnchor(point, relativePoint)
    if not db then
        return
    end

    db.point = point or db.point or defaults.point
    db.relativePoint = relativePoint or db.relativePoint or defaults.relativePoint
    db.anchorPreset = "ADVANCED"
    RefreshAll()
end

local function StartRefreshTicker()
    if refreshTicker then
        return
    end

    refreshTicker = C_Timer.NewTicker(0.20, function()
        RefreshLiveTrays()
        RefreshLiveTrinketMirrors()
        if testMode then
            RefreshTestTrays()
            RefreshTestTrinket()
        end
    end)
end

local function RegisterHelperCallback()
    local helper = GetHelper()
    if not helper or type(helper.RegisterCallback) ~= "function" then
        print(S("WARN_HELPER_NOT_FOUND"))
        return
    end

    helper:RegisterCallback(helperCallbackOwner, function()
        RefreshLiveTrays()
        RefreshLiveTrinketMirrors()
    end)

    if type(helper.QueueBurstRefresh) == "function" then
        helper:QueueBurstRefresh()
    elseif type(helper.RefreshMappings) == "function" then
        helper:RefreshMappings()
    end
end

local function OpenSettings(pageKey)
    if type(_G.ArenaDRNameplates_OpenSettingsWindow) == "function" then
        _G.ArenaDRNameplates_OpenSettingsWindow(pageKey)
        return
    end

    local category = _G.ArenaDRNameplates_SettingsCategory
    local categoryID

    if type(category) == "table" and type(category.GetID) == "function" then
        local ok, value = pcall(category.GetID, category)
        if ok and type(value) == "number" then
            categoryID = value
        end
    end

    if not categoryID and category and type(category.ID) == "number" then
        categoryID = category.ID
    end

    if Settings and Settings.OpenToCategory then
        if categoryID then
            Settings.OpenToCategory(categoryID)
        else
            Settings.OpenToCategory()
        end
    else
        print(S("WARN_SETTINGS_MENU_NOT_AVAILABLE"))
    end
end

local function SlashHandler(msg)
    local rawMsg = Trim(msg or "")
    local lowerMsg = string.lower(rawMsg)

    if lowerMsg == "" or lowerMsg == "config" or lowerMsg == "settings" or lowerMsg == "menu" then
        OpenSettings()
    elseif lowerMsg == "share" then
        OpenSettings("share")
        if type(_G.ArenaDRNameplates_GenerateExportString) == "function" then
            _G.ArenaDRNameplates_GenerateExportString(false)
        end
    elseif lowerMsg == "export" then
        OpenSettings("share")
        local exportString
        if type(_G.ArenaDRNameplates_GenerateExportString) == "function" then
            exportString = _G.ArenaDRNameplates_GenerateExportString(true)
        else
            exportString = Shared.ExportSettings()
        end
        print(S("MSG_EXPORT_READY"))
        print(exportString)
    elseif lowerMsg:match("^import%s+") then
        local importString = Trim(rawMsg:match("^%S+%s+(.+)$") or "")
        local ok, reason = Shared.ImportSettings(importString)
        if ok then
            db = Shared.EnsureDB()
            RefreshAll()
            NotifySettingsUIRefresh()
            print(S("MSG_IMPORT_SUCCESS"))
        else
            print(S(Shared.GetImportErrorMessageKey(reason)))
        end
    elseif lowerMsg == "test" then
        ToggleTestMode()
    elseif lowerMsg == "reset" then
        ResetPosition()
        print(S("MSG_SETTINGS_RESET"))
    elseif lowerMsg:match("^scale%s+") then
        local value = tonumber(lowerMsg:match("^scale%s+([%d%.]+)"))
        if value and value >= 0.5 and value <= 3.0 then
            EnsureDB()
            db.scale = value
            RefreshAll()
            print(string.format(S("MSG_SCALE_SET_TO"), value))
        else
            print(S("ERR_INVALID_SCALE"))
        end
    else
        print(S("MSG_COMMANDS_HEADER"))
        print(S("MSG_COMMAND_CONFIG"))
        print(S("MSG_COMMAND_TEST"))
        print(S("MSG_COMMAND_RESET"))
        print(S("MSG_COMMAND_SCALE"))
        print(S("MSG_COMMAND_SHARE"))
        print(S("MSG_COMMAND_EXPORT"))
        print(S("MSG_COMMAND_IMPORT"))
    end
end

SLASH_ArenaDRNameplates1 = "/ArenaDRNameplates"
SLASH_ArenaDRNameplates2 = "/arenadr"
SlashCmdList["ArenaDRNameplates"] = SlashHandler

local eventFrame = CreateFrame("Frame", NextFrameName("Core", "EventFrame"))
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
eventFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        EnsureDB()
        RegisterHelperCallback()
        StartRefreshTicker()
        RefreshAll()
    elseif event == "PLAYER_ENTERING_WORLD" then
        StopTestMode()
        C_Timer.After(0.3, RefreshAll)
    elseif (event == "PLAYER_LEAVING_WORLD"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA") and testMode then
        StopTestMode()
    elseif event == "ARENA_OPPONENT_UPDATE"
        or event == "ARENA_COOLDOWNS_UPDATE"
        or event == "PVP_MATCH_STATE_CHANGED" then
        RefreshAll()
    elseif event == "PLAYER_TARGET_CHANGED" and testMode then
        RefreshTestTrays()
        RefreshTestTrinket()
    end
end)

_G.ArenaDRNameplates_UpdateScale = RefreshAll
_G.ArenaDRNameplates_UpdateOpacity = RefreshAll
_G.ArenaDRNameplates_UpdateIconGrowth = RefreshAll
_G.ArenaDRNameplates_UpdateBorderWidth = RefreshAll
_G.ArenaDRNameplates_UpdateTimerColor = RefreshAll
_G.ArenaDRNameplates_UpdateTimerPosition = RefreshAll
_G.ArenaDRNameplates_RefreshAll = RefreshAll
_G.ArenaDRNameplates_ToggleTestMode = ToggleTestMode
_G.ArenaDRNameplates_IsTestModeActive = function()
    return testMode
end
_G.ArenaDRNameplates_ResetAllAnchors = ResetPosition
_G.ArenaDRNameplates_ResetAnchor = ResetPosition
_G.ArenaDRNameplates_ResetAllSettings = ResetPosition
_G.ArenaDRNameplates_ApplyAnchorPreset = ApplyAnchorPreset
_G.ArenaDRNameplates_SetAdvancedAnchor = SetAdvancedAnchor
