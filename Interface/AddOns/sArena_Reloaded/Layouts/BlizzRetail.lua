local layoutName = "BlizzRetail"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Retail |A:NewCharacter-Alliance:38:65|a"

layout.defaultSettings = {
    posX = 400,
    posY = 120,
    scale = 1.05,
    classIconFontSize = 21,
    spacing = 20,
    growthDirection = 1,
    specIcon = {
        posX = -43,
        posY = -24,
        scale = 1,
    },
    trinket = {
        posX = 116,
        posY = -6,
        scale = 1,
        fontSize = 15,
    },
    racial = {
        posX = 154,
        posY = -6,
        scale = 1,
        fontSize = 15,
    },
    dispel = {
        posX = 192.5,
        posY = -6,
        scale = 1,
        fontSize = 15,
    },
    castBar = {
        posX = -141,
        posY = -10,
        scale = 1.2,
        width = 120,
        iconScale = 1.15,
        iconPosX = 1,
        iconPosY = 0,
        useModernCastbars = true,
        keepDefaultModernTextures = true,
    },
    dr = {
        posX = -113,
        posY = 15,
        size = 29,
        borderSize = 1,
        fontSize = 12,
        spacing = 5,
        growthDirection = 4,
        brightDRBorder = true,
    },

    textures          = {
        generalStatusBarTexture       = "Blizzard RetailBar",
        healStatusBarTexture          = "sArena Stripes 2",
        castbarStatusBarTexture       = "sArena Default",
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    frameFont = "Prototype",
    cdFont  = "Prototype",
    mirrored = true,
    showSpecManaText = true,
    hideNameBackground = (BetterBlizzFramesDB and BetterBlizzFramesDB.hideUnitFrameShadow) or nil,

    textSettings = {
        specNameSize = 0.85,
        powerAnchor = "RIGHT",
    },
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

    layout.optionsTable.arenaFrames.args.other.args.showSpecManaText = {
        order = 3,
        name = "Spec Text on Manabar",
        type = "toggle",
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.other.args.hideNameBackground = {
        order = 3,
        name = "Hide Name Background",
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
        frame.parent:UpdateDispelSettings(self.db.dispel)
    end

    frame:SetSize(195, 67)

    -- some reused variables
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local f = frame.ClassIcon

    -- text adjustments
    local healthText = frame.HealthText
    healthText:SetJustifyH("CENTER")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
    --healthText:SetShadowOffset(0, 0)
    healthText:SetDrawLayer("OVERLAY", 4)

    local powerText = frame.PowerText
    -- powerText:SetJustifyH("CENTER")
    -- powerText:SetPoint("CENTER", healthBar, "CENTER", -1, -16.5)
    --powerText:SetShadowOffset(0, 0)
    powerText:SetDrawLayer("OVERLAY", 4)

    local playerName = frame.Name
    playerName:SetJustifyH("CENTER")
    playerName:SetHeight(12)
    playerName:SetDrawLayer("OVERLAY", 6)

    -- portrait icon
    frame.ClassIconCooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    frame.ClassIconCooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
    frame.ClassIconCooldown:SetUseCircularEdge(true)
    frame.ClassIcon:SetSize(55, 55)
    frame.ClassIcon:Show()
    frame.ClassIcon:SetTexCoord(0.05, 0.95, 0.1, 0.9)
    frame.ClassIcon:AddMaskTexture(frame.ClassIconMask)
    frame.ClassIconMask:ClearAllPoints()
    frame.ClassIconMask:SetPoint("CENTER", frame.ClassIcon, 0,1)
    frame.ClassIconMask:SetSize(60, 57)

    -- trinket
    local trinket = frame.Trinket


    if not trinket.Border then
        trinket.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local trinketBorder = trinket.Border

    if not trinket.Mask then
        trinket.Mask = trinket:CreateMaskTexture()
    end
    trinket.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    trinket.Mask:SetAllPoints(trinket.Texture)

    -- Apply the mask
    trinket.Texture:AddMaskTexture(trinket.Mask)

    trinket.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    trinket.Border = trinketBorder


    trinket:SetSize(35, 35)
    if not trinket.BorderParent then
        trinket.BorderParent = CreateFrame("Frame", nil, trinket)
        trinket.BorderParent:SetFrameStrata("HIGH")
    end
    trinketBorder:SetParent(trinket.BorderParent)
    trinketBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    trinketBorder:SetPoint("TOPLEFT", trinket, "TOPLEFT", -6, 6)
    trinketBorder:SetPoint("BOTTOMRIGHT", trinket, "BOTTOMRIGHT", 6, -6)
    trinketBorder:SetDrawLayer("OVERLAY", 3)
    trinketBorder:Show()
    trinket.Border = trinketBorder

    if not trinket.TrinketBorderHook then
        hooksecurefunc(trinket.Texture, "SetTexture", function(self, t)
            if t == nil or t == "" or t == 0 or t == "nil" or frame.parent.db.profile.currentLayout ~= layoutName then
                trinketBorder:Hide()
            else
                trinketBorder:Hide()
                trinketBorder:Show()
            end
        end)
        trinket.TrinketBorderHook = true
    end

    -- racial
    local racial = frame.Racial
    if not racial.Border then
        racial.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local racialBorder = racial.Border
    if not racial.Mask then
        racial.Mask = racial:CreateMaskTexture()
    end
    racial.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    racial.Mask:SetAllPoints(racial.Texture)

    -- Apply the mask
    racial.Texture:AddMaskTexture(racial.Mask)

    racial.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    racial:SetSize(35, 35)
    if not racial.BorderParent then
        racial.BorderParent = CreateFrame("Frame", nil, racial)
        racial.BorderParent:SetFrameStrata("HIGH")
    end
    racialBorder:SetParent(racial.BorderParent)
    racialBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    racialBorder:SetPoint("TOPLEFT", racial, "TOPLEFT", -6, 6)
    racialBorder:SetPoint("BOTTOMRIGHT", racial, "BOTTOMRIGHT", 6, -6)
    racialBorder:SetDrawLayer("OVERLAY", 3)
    racialBorder:Show()
    racial.Border = racialBorder

    if not racial.RacialBorderHook then
        hooksecurefunc(racial.Texture, "SetTexture", function(self, t)
            if t == nil or t == "" or t == 0 or t == "nil" or frame.parent.db.profile.currentLayout ~= layoutName then
                racialBorder:Hide()
            else
                racialBorder:Hide()
                racialBorder:Show()
            end
        end)
        racial.RacialBorderHook = true
    end

    -- dispel
    local dispel = frame.Dispel
    if not dispel.Border then
        dispel.Border = frame:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    local dispelBorder = dispel.Border
    if not dispel.Mask then
        dispel.Mask = dispel:CreateMaskTexture()
    end
    dispel.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    dispel.Mask:SetAllPoints(dispel.Texture)

    -- Apply the mask
    dispel.Texture:AddMaskTexture(dispel.Mask)

    dispel.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
    dispel:SetSize(35, 35)
    if not dispel.BorderParent then
        dispel.BorderParent = CreateFrame("Frame", nil, dispel)
        dispel.BorderParent:SetFrameStrata("HIGH")
    end
    dispelBorder:SetParent(dispel.BorderParent)
    dispelBorder:SetAtlas("plunderstorm-actionbar-slot-border")
    dispelBorder:SetPoint("TOPLEFT", dispel, "TOPLEFT", -6, 6)
    dispelBorder:SetPoint("BOTTOMRIGHT", dispel, "BOTTOMRIGHT", 6, -6)
    dispelBorder:SetDrawLayer("OVERLAY", 3)
    dispelBorder:Show()
    dispel.Border = dispelBorder

    if not dispel.DispelBorderHook then
        hooksecurefunc(dispel.Texture, "SetTexture", function(self, t)
            if t == nil or t == "" or t == 0 or t == "nil" or frame.parent.db.profile.currentLayout ~= layoutName then
                dispelBorder:Hide()
            else
                dispelBorder:Hide()
                dispelBorder:Show()
            end
        end)
        hooksecurefunc(dispel, "Hide", function()
            dispelBorder:Hide()
        end)
        dispel.DispelBorderHook = true
    end

    -- spec icon
    if not frame.SpecIcon.Border then
        frame.SpecIcon.Border = frame.SpecIcon:CreateTexture(nil, "ARTWORK", nil, 3)
    end

    local specBorder = frame.SpecIcon.Border

    frame.SpecIcon:SetSize(20, 20)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    frame.SpecIcon.Texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    specBorder:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\Map_Faction_Ring.tga")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -8.5, 8.5)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 8, -8)
    specBorder:SetDrawLayer("OVERLAY", 7)
    frame.SpecIcon.Texture:SetDrawLayer("OVERLAY", 6)
    --specBorder:Hide()

    frame.SpecNameText:SetTextColor(1,1,1)
    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER", -1, -5)
    f:SetSize(42, 42)
    f:SetDrawLayer("OVERLAY", 7)


    -- Health bar underlay
    if not frame.hpUnderlay then
        frame.hpUnderlay = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.hpUnderlay:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT")
        frame.hpUnderlay:SetPoint("BOTTOMRIGHT", frame.HealthBar, "BOTTOMRIGHT")
        frame.hpUnderlay:Show()
    end

    -- Power bar underlay
    if not frame.ppUnderlay then
        frame.ppUnderlay = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.ppUnderlay:SetPoint("TOPLEFT", frame.PowerBar, "TOPLEFT")
        frame.ppUnderlay:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT")
        frame.ppUnderlay:Show()
    end

    frame.hpUnderlay:SetColorTexture(0, 0, 0, 0.55)
    frame.ppUnderlay:SetColorTexture(0, 0, 0, 0.55)

    -- Full-frame texture (owned by the frame)
    if not frame.frameTexture then
        frame.frameTexture = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    end

    local frameTexture = frame.frameTexture
    frameTexture:ClearAllPoints()
    frameTexture:SetAllPoints(frame)
    if self.db.hideNameBackground then
        frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-UnitFrame-Target-PortraitOn-NoShadow.tga")
    else
        frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-UnitFrame-Target-PortraitOn.tga")
    end
    frameTexture:SetDrawLayer("OVERLAY", 5)
    frameTexture:Show()

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local frameTexture = frame.frameTexture
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon
    local name = frame.Name
    local specName = frame.SpecNameText
    local healthText = frame.HealthText
    local powerText = frame.PowerText
    local castbarText = frame.CastBar.Text

    name:ClearAllPoints()
    healthBar:ClearAllPoints()
    powerBar:ClearAllPoints()
    classIcon:ClearAllPoints()
    specName:ClearAllPoints()

    if self.db.textSettings then
        local txt = self.db.textSettings
        local modernCastbar = self.db.castBar.useModernCastbars

        name:SetScale(txt.nameSize or 1)
        healthText:SetScale(txt.healthSize or 1)
        specName:SetScale(txt.specNameSize or 1)
        castbarText:SetScale(txt.castbarSize or 1)
        powerText:SetScale(txt.powerSize or 1)

        -- Name
        name:ClearAllPoints()
        if (txt.nameAnchor or "CENTER") == "LEFT" then
            name:SetPoint("BOTTOMLEFT", frame.HealthBar, "TOPLEFT", 3 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", -3 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("BOTTOM", frame.HealthBar, "TOP", -1 + (txt.nameOffsetX or 0), 1.5 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", 4 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", -3 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", -1 + (txt.healthOffsetX or 0), (txt.healthOffsetY or 0))
        end

        -- Power Text
        powerText:ClearAllPoints()
        if (txt.powerAnchor or "CENTER") == "LEFT" then
            powerText:SetPoint("LEFT", frame.PowerBar, "LEFT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        elseif (txt.powerAnchor or "CENTER") == "RIGHT" then
            powerText:SetPoint("RIGHT", frame.PowerBar, "RIGHT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        else
            powerText:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        end

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", healthBar, "LEFT", 4 + (txt.specNameOffsetX or 0), -19.5 + (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", healthBar, "RIGHT", -3 + (txt.specNameOffsetX or 0), -19.5 + (txt.specNameOffsetY or 0))
        else
            specName:SetPoint("CENTER", healthBar, "CENTER", -1 + (txt.specNameOffsetX or 0), -19.5 + (txt.specNameOffsetY or 0))
        end

        -- Castbar Text
        castbarText:ClearAllPoints()
        local simpleCastbar = self.db.castBar.simpleCastbar and modernCastbar
        if (txt.castbarAnchor or "CENTER") == "LEFT" then
            castbarText:SetPoint("LEFT", frame.CastBar, "LEFT", 3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        elseif (txt.castbarAnchor or "CENTER") == "RIGHT" then
            castbarText:SetPoint("RIGHT", frame.CastBar, "RIGHT", -3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        else
            castbarText:SetPoint("CENTER", frame.CastBar, "CENTER", (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        end
    end

    if (self.db.mirrored) then
    	frameTexture:SetTexCoord(1, 0, 0, 1)
        healthBar:SetSize(128, 21)
    	healthBar:GetStatusBarTexture():SetDrawLayer("BORDER", 1)
    	healthBar:SetPoint("TOPRIGHT", -3, -23)
        powerBar:SetSize(136, 11)
        powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", -8, 0)
        classIcon:SetPoint("TOPLEFT", 8, -4)
        --specName:SetPoint("CENTER", healthBar, "CENTER", -1, -19.5)
        --healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
        --name:SetPoint("BOTTOM", healthBar, "TOP", -1, 1.5)
    else
    	frameTexture:SetTexCoord(0, 1, 0, 1)
    	healthBar:SetSize(128, 21)
    	healthBar:GetStatusBarTexture():SetDrawLayer("BORDER", 1)
    	healthBar:SetPoint("TOPLEFT", 3, -23)
    	powerBar:SetSize(137, 11)
    	powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 0)
    	classIcon:SetPoint("TOPRIGHT", -8, -4)
        --specName:SetPoint("CENTER", healthBar, "CENTER", 1, -19.5)
        --healthText:SetPoint("CENTER", healthBar, "CENTER", 1.5, 0)
        --name:SetPoint("BOTTOM", healthBar, "TOP", 1, 1.5)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
