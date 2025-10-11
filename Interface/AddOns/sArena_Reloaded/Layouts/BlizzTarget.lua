local layoutName = "BlizzTarget"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Target |A:NewCharacter-Alliance:36:64|a"

layout.defaultSettings = {
    posX = 450,
    posY = 170,
    scale = 1,
    classIconFontSize = 20,
    spacing = 14,
    growthDirection = 1,
    specIcon = {
        posX = 82,
        posY = -25,
        scale = 1,
    },
    trinket = {
        posX = 80,
        posY = 0,
        scale = 1.5,
        fontSize = 12,
    },
    racial = {
        posX = 104,
        posY = 0,
        scale = 1.5,
        fontSize = 12,
    },
    castBar = {
        posX = -15,
        posY = -29,
        scale = 1.2,
        width = 82,
        iconScale = 1,
        keepDefaultModernTextures = true,
    },
    dr = {
        posX = -114,
        posY = 0,
        size = 28,
        borderSize = 2.5,
        fontSize = 12,
        spacing = 7,
        growthDirection = 4,
    },

    textures          = {
        generalStatusBarTexture       = "sArena Default",
        healStatusBarTexture          = "sArena Stripes",
        castbarStatusBarTexture       = "sArena Default",
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    frameFont = "Prototype",
    cdFont  = "Prototype",
    mirrored = false,
    bigHealthbar = true,

    textSettings = {},
}

local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        layout:UpdateOrientation(frame)
    end
    sArenaMixin:RefreshConfig()
end

local function setupOptionsTable(self)
    layout.optionsTable = self:GetLayoutOptionsTable(layoutName)

    layout.optionsTable.arenaFrames.args.positioning.args.mirrored = {
        order = 5,
        name = "Mirrored Frames",
        type = "toggle",
        width = "full",
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.other.args.bigHealthbar = {
        order = 1,
        name = "Big Healthbar",
        type = "toggle",
        get = getSetting,
        set = setSetting,
    }
end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]

    if (not self.optionsTable) then
        setupOptionsTable(frame.parent)
    end

    if (frame:GetID() == sArenaMixin.maxArenaOpponents) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
    end

    frame.ClassIconCooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    frame.ClassIconCooldown:SetUseCircularEdge(true)

    frame:SetSize(192, 76.8)
    frame.SpecIcon:SetSize(22, 22)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    frame.Trinket:SetSize(22, 22)
    frame.Racial:SetSize(22, 22)

    frame.AuraStacks:SetPoint("BOTTOMLEFT", frame.ClassIcon, "BOTTOMLEFT", 6, -1)
    frame.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 18, "THICKOUTLINE")

    if not frame.NameBackground then
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
        bg:SetTexture(137017)
        bg:SetPoint("TOPLEFT", frame.Name, "TOPLEFT", -2, 2)
        bg:SetPoint("BOTTOMRIGHT", frame.Name, "BOTTOMRIGHT", 2, -2)
        bg:SetVertexColor(0,0,0, 0.6)
        frame.NameBackground = bg
    end

    local healthBar = frame.HealthBar
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local powerBar = frame.PowerBar
    powerBar:SetSize(118, 9)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1.5)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local f = frame.ClassIcon
    f:SetSize(64, 64)
    f:Show()
    f:AddMaskTexture(frame.ClassIconMask)

    frame.ClassIconMask:SetSize(64, 64)

    -- SpecIcon border (owned by SpecIcon)
    if not frame.SpecIcon.Border then
        frame.SpecIcon.Border = frame.SpecIcon:CreateTexture(nil, "ARTWORK", nil, 3)
    end

    local specBorder = frame.SpecIcon.Border
    specBorder:ClearAllPoints()
    specBorder:SetTexture("Interface\\CHARACTERFRAME\\TotemBorder")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -8, 8)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 8, -8)
    specBorder:Show()

    f = frame.Name
    f:SetJustifyH("CENTER")
    --f:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 4)
    --f:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -2, 4)
    f:SetHeight(12)
    f:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

    f = frame.CastBar
    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "TOP")
    f:SetSize(48, 48)

    --frame.HealthText:SetPoint("CENTER", frame.HealthBar)
    --frame.HealthText:SetShadowOffset(0, 0)

    frame.PowerText:SetPoint("CENTER", frame.PowerBar)
    --frame.PowerText:SetShadowOffset(0, 0)
    frame.PowerText:SetAlpha(0)

    -- Health bar underlay
    if not frame.hpUnderlay then
        frame.hpUnderlay = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.hpUnderlay:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT")
        frame.hpUnderlay:SetPoint("BOTTOMRIGHT", frame.HealthBar, "BOTTOMRIGHT")
        frame.hpUnderlay:SetColorTexture(0, 0, 0, 0.65)
        frame.hpUnderlay:Show()
    end

    -- Power bar underlay
    if not frame.ppUnderlay then
        frame.ppUnderlay = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.ppUnderlay:SetPoint("TOPLEFT", frame.PowerBar, "TOPLEFT")
        frame.ppUnderlay:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT")
        frame.ppUnderlay:SetColorTexture(0, 0, 0, 0.65)
        frame.ppUnderlay:Show()
    end

    -- Full-frame texture (owned by the frame)
    if not frame.frameTexture then
        frame.frameTexture = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    end

    local frameTexture = frame.frameTexture
    frameTexture:ClearAllPoints()
    frameTexture:SetAllPoints(frame)
    frameTexture:SetDrawLayer("ARTWORK", 2)
    frameTexture:Show()

    if self.db.bigHealthbar then
        healthBar:SetSize(118, 29)
        frame.NameBackground:Hide()
        frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-TargetingFrame-NoLevel-Large")
    else
        healthBar:SetSize(118, 9)
        frameTexture:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-NoLevel")
        frame.NameBackground:Show()
    end

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local frameTexture = frame.frameTexture
    local healthBar = frame.HealthBar
    local classIcon = frame.ClassIcon
    local classIconMask = frame.ClassIconMask
    local name = frame.Name
    local specName = frame.SpecNameText
    local healthText = frame.HealthText
    local castbarText = frame.CastBar.Text

    if self.db.textSettings then
        local txt = self.db.textSettings
        local modernCastbar = self.db.castBar.useModernCastbars

        name:SetScale(txt.nameSize or 1.0)
        healthText:SetScale(txt.healthSize or 1.0)
        specName:SetScale(txt.specNameSize or 1.0)
        castbarText:SetScale(txt.castbarSize or 1.0)

        -- Name
        name:ClearAllPoints()
        if (txt.nameAnchor or "CENTER") == "LEFT" then
            name:SetPoint("BOTTOMLEFT", frame.HealthBar, "TOPLEFT", 3 + (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", -3 + (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("BOTTOM", frame.HealthBar, "TOP", (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        end

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", frame.PowerBar, "LEFT", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", frame.PowerBar, "RIGHT", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        else
            specName:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        end

        -- Castbar Text
        castbarText:ClearAllPoints()
        if (txt.castbarAnchor or "CENTER") == "LEFT" then
            castbarText:SetPoint("LEFT", frame.CastBar, "LEFT", 3 + (txt.castbarOffsetX or 0), (modernCastbar and -11 or 0) + (txt.castbarOffsetY or 0))
        elseif (txt.castbarAnchor or "CENTER") == "RIGHT" then
            castbarText:SetPoint("RIGHT", frame.CastBar, "RIGHT", -3 + (txt.castbarOffsetX or 0), (modernCastbar and -11 or 0) + (txt.castbarOffsetY or 0))
        else
            castbarText:SetPoint("CENTER", frame.CastBar, "CENTER", (txt.castbarOffsetX or 0), (modernCastbar and -11 or 0) + (txt.castbarOffsetY or 0))
        end
    end

    healthBar:ClearAllPoints()
    classIcon:ClearAllPoints()
    classIconMask:ClearAllPoints()

    if (self.db.mirrored) then
        frameTexture:SetTexCoord(0.85, 0.1, 0.05, 0.65)
        healthBar:SetPoint("RIGHT", -5, self.db.bigHealthbar and 7 or -2)
        classIcon:SetPoint("LEFT", 5, 0)
        classIconMask:SetPoint("LEFT", 5, 0)
    else
        frameTexture:SetTexCoord(0.1, 0.85, 0.05, 0.65)
        healthBar:SetPoint("LEFT", 5, self.db.bigHealthbar and 7 or -2)
        classIcon:SetPoint("RIGHT", -5, 0)
        classIconMask:SetPoint("RIGHT", -5, 0)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
