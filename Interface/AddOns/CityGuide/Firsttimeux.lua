-- FirstTimeUX.lua
-- First-time user experience tutorial for the world map widget
-- Shows a hint box below the widget the first time a user opens a supported city map.
-- Also draws a pulsing highlight around the widget button to point the player to it.
-- Disappears permanently once the user has right-clicked AND middle-clicked at least once.

local tutorialFrame  = nil
local highlightFrame = nil
local tutorialVisible = false

local FRAME_W = 300
local FRAME_H = 58

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function CreateHighlightFrame()
    if highlightFrame then return end

    local anchor = _G["CityGuideButtonContainer"]
    if not anchor then return end

    -- A frame slightly larger than the button container, drawn around it.
    highlightFrame = CreateFrame("Frame", "CityGuideTutorialHighlight", WorldMapFrame.BorderFrame)
    highlightFrame:SetFrameStrata("DIALOG")
    highlightFrame:SetFrameLevel(210)

    -- 6px padding on each side so the glow sits outside the button
    local pad = 6
    highlightFrame:SetPoint("TOPLEFT",     anchor, "TOPLEFT",     -pad,  pad)
    highlightFrame:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT",  pad, -pad)

    -- Bright yellow/gold border (4 edges)
    local function GlowEdge(p1, r1, p2, r2, isHoriz)
        local t = highlightFrame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 0.82, 0.1, 1.0)
        t:SetPoint(p1, highlightFrame, r1, 0, 0)
        t:SetPoint(p2, highlightFrame, r2, 0, 0)
        if isHoriz then t:SetHeight(2) else t:SetWidth(2) end
        return t
    end
    GlowEdge("TOPLEFT",    "TOPLEFT",    "TOPRIGHT",    "TOPRIGHT",    true)
    GlowEdge("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", true)
    GlowEdge("TOPLEFT",    "TOPLEFT",    "BOTTOMLEFT",  "BOTTOMLEFT",  false)
    GlowEdge("TOPRIGHT",   "TOPRIGHT",   "BOTTOMRIGHT", "BOTTOMRIGHT", false)

    -- Pulsing alpha animation on the whole highlight frame
    local ag = highlightFrame:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local fade = ag:CreateAnimation("Alpha")
    fade:SetFromAlpha(1.0)
    fade:SetToAlpha(0.2)
    fade:SetDuration(0.7)
    ag:Play()
    highlightFrame.anim = ag

    highlightFrame:Hide()
end

local function CreateTutorialFrame()
    if tutorialFrame then return end

    local anchor = _G["CityGuideButtonContainer"]
    if not anchor then return end

    tutorialFrame = CreateFrame("Frame", "CityGuideTutorialFrame", WorldMapFrame.BorderFrame)
    tutorialFrame:SetSize(FRAME_W, FRAME_H)
    tutorialFrame:SetFrameStrata("DIALOG")
    tutorialFrame:SetFrameLevel(200)
    tutorialFrame:SetPoint("TOP", anchor, "BOTTOM", 0, -6)

    -- Solid black background
    local bg = tutorialFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tutorialFrame)
    bg:SetColorTexture(0, 0, 0, 1.0)

    -- 1px grey border (four edges)
    local function Border(p1, r1, p2, r2, isHoriz)
        local t = tutorialFrame:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.35, 0.35, 0.35, 1.0)
        t:SetPoint(p1, tutorialFrame, r1, 0, 0)
        t:SetPoint(p2, tutorialFrame, r2, 0, 0)
        if isHoriz then t:SetHeight(1) else t:SetWidth(1) end
    end
    Border("TOPLEFT",    "TOPLEFT",    "TOPRIGHT",    "TOPRIGHT",    true)
    Border("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", true)
    Border("TOPLEFT",    "TOPLEFT",    "BOTTOMLEFT",  "BOTTOMLEFT",  false)
    Border("TOPRIGHT",   "TOPRIGHT",   "BOTTOMRIGHT", "BOTTOMRIGHT", false)

    -- "TIP" label
    local badge = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("TOPLEFT", tutorialFrame, "TOPLEFT", 8, -6)
    badge:SetText("|cff00d4ffTIP|r")

    -- Close button (X) top-right
    local closeBtn = CreateFrame("Button", nil, tutorialFrame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", tutorialFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetFrameLevel(tutorialFrame:GetFrameLevel() + 5)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetAllPoints(closeBtn)
    closeText:SetJustifyH("CENTER")
    closeText:SetText("|cffaaaaaaX|r")

    closeBtn:SetScript("OnEnter", function() closeText:SetText("|cffffffffX|r") end)
    closeBtn:SetScript("OnLeave", function() closeText:SetText("|cffaaaaaaX|r") end)
    closeBtn:SetScript("OnClick", function()
        CityGuideConfig.tutorialSeen = true
        tutorialFrame:Hide()
        if highlightFrame then
            if highlightFrame.anim then highlightFrame.anim:Stop() end
            highlightFrame:Hide()
        end
        tutorialVisible = false
    end)

    -- Right-click hint
    local rightText = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightText:SetPoint("TOPLEFT", tutorialFrame, "TOPLEFT", 8, -20)
    rightText:SetWidth(FRAME_W - 16)
    rightText:SetJustifyH("LEFT")
    rightText:SetWordWrap(false)
    tutorialFrame.rightText = rightText

    -- Middle-click hint
    local midText = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    midText:SetPoint("TOPLEFT", rightText, "BOTTOMLEFT", 0, -8)
    midText:SetWidth(FRAME_W - 16)
    midText:SetJustifyH("LEFT")
    midText:SetWordWrap(false)
    tutorialFrame.midText = midText

    tutorialFrame:Hide()
end

local function UpdateTutorialText()
    if not tutorialFrame then return end

    local rightDone = CityGuideConfig.tutorialRightClicked
    local midDone   = CityGuideConfig.tutorialMiddleClicked

    local readyTex   = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t "
    local waitingTex = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12:12|t "

    local rightColor = rightDone and "ffaaaaaa" or "ffffffff"
    local midColor   = midDone   and "ffaaaaaa" or "ffffffff"

    tutorialFrame.rightText:SetText((rightDone and readyTex or waitingTex) .. "|c" .. rightColor .. "Right-click to change mode|r")
    tutorialFrame.midText:SetText(  (midDone   and readyTex or waitingTex) .. "|c" .. midColor   .. "Middle-click to enable/disable in this city|r")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

function CityGuide_TryShowTutorial()
    if CityGuideConfig.tutorialSeen then return end

    CreateHighlightFrame()
    CreateTutorialFrame()
    if not tutorialFrame then return end

    UpdateTutorialText()
    tutorialFrame:Show()
    if highlightFrame then
        highlightFrame:Show()
        if highlightFrame.anim then highlightFrame.anim:Play() end
    end
    tutorialVisible = true
end

function CityGuide_OnTutorialRightClick()
    if CityGuideConfig.tutorialSeen then return end
    CityGuideConfig.tutorialRightClicked = true
    CityGuide_CheckTutorialComplete()
end

function CityGuide_OnTutorialMiddleClick()
    if CityGuideConfig.tutorialSeen then return end
    CityGuideConfig.tutorialMiddleClicked = true
    CityGuide_CheckTutorialComplete()
end

function CityGuide_CheckTutorialComplete()
    if not CityGuideConfig.tutorialRightClicked or
       not CityGuideConfig.tutorialMiddleClicked then
        if tutorialFrame and tutorialFrame:IsShown() then
            UpdateTutorialText()
        end
        return
    end

    CityGuideConfig.tutorialSeen = true
    if tutorialFrame then
        tutorialFrame:Hide()
        tutorialVisible = false
    end
    if highlightFrame then
        if highlightFrame.anim then highlightFrame.anim:Stop() end
        highlightFrame:Hide()
    end
end

function CityGuide_HideTutorial()
    if tutorialFrame then
        tutorialFrame:Hide()
        tutorialVisible = false
    end
    if highlightFrame then
        if highlightFrame.anim then highlightFrame.anim:Stop() end
        highlightFrame:Hide()
    end
end

function CityGuide_ResetTutorial()
    CityGuideConfig.tutorialSeen          = false
    CityGuideConfig.tutorialRightClicked  = false
    CityGuideConfig.tutorialMiddleClicked = false

    if tutorialFrame then
        tutorialFrame:Hide()
        tutorialFrame = nil
        tutorialVisible = false
    end
    if highlightFrame then
        if highlightFrame.anim then highlightFrame.anim:Stop() end
        highlightFrame:Hide()
        highlightFrame = nil
    end

    local container = _G["CityGuideButtonContainer"]
    if container and container:IsShown() then
        CityGuide_TryShowTutorial()
        print("|cff00ff00City Guide:|r Tutorial reset.")
    else
        print("|cff00ff00City Guide:|r Tutorial reset - open a supported city map to see it.")
    end
end