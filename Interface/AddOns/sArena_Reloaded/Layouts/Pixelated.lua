local layoutName = "Pixelated"
local layout = {}
layout.name = "Pixelated |A:NewCharacter-Alliance:38:65|a"

layout.defaultSettings = {
    posX = 433,
    posY = 143,
    scale = 1.05,
    classIconFontSize = 14,
    spacing = 35,
    growthDirection = 1,
    specIcon = {
        posX = -21,
        posY = -2,
        scale = 1,
    },
    trinket = {
        posX = 105,
        posY = 0,
        scale = 1.049,
        fontSize = 14,
    },
    racial = {
        posX = 147,
        posY = 0,
        scale = 1.049,
        fontSize = 14,
    },
    castBar = {
        posX = -125,
        posY = -8.2,
        scale = 1.33,
        width = 115,
        iconScale = 1,
        iconPosX = 4,
        keepDefaultModernTextures = true,
    },
    dr = {
        posX = -110,
        posY = 22,
        size = 31,
        borderSize = 1,
        fontSize = 12,
        spacing = 7,
        growthDirection = 4,
    },
    statusText = {
        usePercentage = true,
        alwaysShow = true,
    },

    textures          = {
        generalStatusBarTexture       = "sArena Default",
        healStatusBarTexture          = "sArena Stripes",
        castbarStatusBarTexture       = "sArena Default",
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    changeFont = true,
    frameFont = "Prototype",
    cdFont  = "Prototype",
    width = 177,
    height = 47,
    powerBarHeight = 9,
    pixelBorderSize = 1,
    drPixelBorderSize = 2,
    mirrored = true,
    classicBars = false,
    replaceClassIcon = true,
    showSpecManaText = true,
    cropIcons = true,

    textSettings = {
        nameAnchor = "LEFT",
        healthAnchor = "RIGHT",
        specNameAnchor = "LEFT",
    },
}

local function CreatePixelTextureBorder(parent, target, key, size, offset)
    offset = offset or 0
    size = size or 1

    if not parent[key] then
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetIgnoreParentScale(true)
        parent[key] = holder

        local edges = {}
        for i = 1, 4 do
            local tex = holder:CreateTexture(nil, "BORDER", nil, 7)
            tex:SetColorTexture(0,0,0,1)
            tex:SetIgnoreParentScale(true)
            edges[i] = tex
        end
        holder.edges = edges

        function holder:SetVertexColor(r, g, b, a)
            for _, tex in ipairs(self.edges) do
                tex:SetColorTexture(r, g, b, a or 1)
            end
        end
    end

    local holder = parent[key]
    local edges = holder.edges

    local spacing = offset

    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", target, "TOPLEFT", -spacing - size, spacing + size)
    holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", spacing + size, -spacing - size)

    -- Top
    edges[1]:ClearAllPoints()
    edges[1]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[1]:SetHeight(size)

    -- Right
    edges[2]:ClearAllPoints()
    edges[2]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[2]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[2]:SetWidth(size)

    -- Bottom
    edges[3]:ClearAllPoints()
    edges[3]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[3]:SetHeight(size)

    -- Left
    edges[4]:ClearAllPoints()
    edges[4]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[4]:SetWidth(size)

    holder:Show()
end


function sArenaMixin:AddPixelBorder()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local size = frame.parent.db.profile.layoutSettings[layoutName].pixelBorderSize or 1.5
        local drSize = frame.parent.db.profile.layoutSettings[layoutName].drPixelBorderSize or 1.5
        local offset = frame.parent.db.profile.layoutSettings[layoutName].pixelBorderOffset or 0

        if not frame.PixelBorders then
            frame.PixelBorders = CreateFrame("Frame", nil, frame)
            frame.PixelBorders:SetAllPoints()
            frame.PixelBorders:SetFrameLevel(frame:GetFrameLevel() - 1)
        end

        local borders = frame.PixelBorders
        frame.PixelBorders.hide = nil

        if frame.HealthBar and frame.PowerBar then
            local wrapper = borders.mainWrapper
            if not wrapper then
                wrapper = CreateFrame("Frame", nil, borders)
                borders.mainWrapper = wrapper
            end
            wrapper:ClearAllPoints()
            wrapper:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT")
            wrapper:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT")
            CreatePixelTextureBorder(borders, wrapper, "main", size, offset)
        end

        CreatePixelTextureBorder(borders, frame.ClassIcon, "classIcon", size, offset)
        CreatePixelTextureBorder(borders, frame.Trinket, "trinket", size, offset)
        CreatePixelTextureBorder(borders, frame.Racial, "racial", size, offset)
        CreatePixelTextureBorder(frame.SpecIcon, frame.SpecIcon, "specIcon", size, offset)
        CreatePixelTextureBorder(frame.CastBar, frame.CastBar, "castBar", size, offset)
        CreatePixelTextureBorder(frame.CastBar, frame.CastBar.Icon, "castBarIcon", size, offset)
        frame:SetTextureCrop(frame.CastBar.Icon, true)

        for n = 1, #self.drCategories do
            local drFrame = frame[self.drCategories[n]]
            if drFrame then
                -- Only apply pixel borders if bright DR borders are disabled
                if not frame.parent.db.profile.layoutSettings[layoutName].dr.brightDRBorder then
                    drFrame.Border:Hide()
                    CreatePixelTextureBorder(drFrame, drFrame, "PixelBorder", drSize, offset)

                    local blackDRBorder = frame.parent.db.profile.layoutSettings[layoutName].dr and frame.parent.db.profile.layoutSettings[layoutName].dr.blackDRBorder
                    if blackDRBorder then
                        drFrame.PixelBorder:SetVertexColor(0, 0, 0, 1)
                    else
                        if i == 1 then
                            drFrame.PixelBorder:SetVertexColor(1, 0, 0, 1)
                        else
                            drFrame.PixelBorder:SetVertexColor(0, 1, 0, 1)
                        end
                    end
                else
                    -- If bright borders are enabled, make sure pixel border is hidden
                    if drFrame.PixelBorder then
                        drFrame.PixelBorder:Hide()
                    end
                    -- Show the original border for bright border functionality
                    if drFrame.Border then
                        drFrame.Border:Show()
                    end
                end
            end
        end

        borders:Show()
    end
end

function sArenaMixin:RemovePixelBorders()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame.PixelBorders then
            return
        end

        if frame.PixelBorders then
            frame.PixelBorders:Hide()
            frame.PixelBorders.hide = true
        end

        -- Hide individual borders
        local function hideBorder(parent, key)
            if parent and parent[key] then
                parent[key]:Hide()
            end
        end

        local borders = frame.PixelBorders
        if borders and borders.mainWrapper then
            hideBorder(borders, "main")
        end

        hideBorder(borders, "classIcon")
        hideBorder(borders, "trinket")
        hideBorder(borders, "racial")
        hideBorder(frame.SpecIcon, "specIcon")
        hideBorder(frame.CastBar, "castBar")
        hideBorder(frame.CastBar, "castBarIcon")

        -- Reset cast bar icon position
        frame.CastBar.Icon:ClearAllPoints()
        frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5, 0)

        -- Reset DR borders and restore original border texture if needed
        for n = 1, #self.drCategories do
            local drFrame = frame[self.drCategories[n]]
            if drFrame and drFrame.PixelBorder then
                drFrame.PixelBorder:Hide()
                -- Always restore the original border when removing pixel borders
                if drFrame.Border then
                    drFrame.Border:Show()
                end
            end
        end
    end
end


local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        frame:SetSize(layout.db.width, layout.db.height)
        frame.ClassIcon:SetSize(layout.db.height, layout.db.height)
        frame.DeathIcon:SetSize(layout.db.height * 0.8, layout.db.height * 0.8)
        frame.PowerBar:SetHeight(layout.db.powerBarHeight)
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

    layout.optionsTable.arenaFrames.args.sizing.args.width = {
        order = 3,
        name = "Width",
        type = "range",
        min = 40,
        max = 400,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.height = {
        order = 4,
        name = "Height",
        type = "range",
        min = 2,
        max = 100,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.powerBarHeight = {
        order = 5,
        name = "Power Bar Height",
        type = "range",
        min = 1,
        max = 50,
        step = 1,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.showSpecManaText = {
        order = 2,
        name = "Spec Text on Manabar",
        type = "toggle",
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.cropIcons = {
        order = 5,
        name = "Crop Icons",
        type = "toggle",
        width = "full",
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderSize = {
        order = 6,
        name = "Pixel Border Size",
        type = "range",
        min = 0.5,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderOffset = {
        order = 7,
        name = "Pixel Border Offset",
        type = "range",
        min = -3,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.drPixelBorderSize = {
        order = 8,
        name = "DR Pixel Border Size",
        type = "range",
        min = 0.5,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setSetting,
    }
end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]
    sArenaMixin.useSpecClassIcon = true

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

        frame.parent:AddPixelBorder()

        for n = 1, #sArenaMixin.drCategories do
            local drFrame = frame[sArenaMixin.drCategories[n]]
            if drFrame and not drFrame.PixelBorder then
                if not drFrame.Border:GetTexture() then
                    drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress", true)
                end
            end
        end
    end

     --0,0,0,1,1,0,1,1

    frame:SetSize(self.db.width, self.db.height)
    frame.SpecIcon:SetSize(22, 22)
    frame.Trinket:SetSize(41, 41)
    frame.Racial:SetSize(41, 41)
    frame.Name:SetTextColor(1,1,1)
    frame.SpecNameText:SetTextColor(1,1,1)

    frame.Trinket.Cooldown:SetSwipeTexture(1)
    frame.Trinket.Cooldown:SetSwipeColor(0, 0, 0, 0.6)
    frame.Trinket.Cooldown:SetUseCircularEdge(false)

    frame.Racial.Cooldown:SetSwipeTexture(1)
    frame.Racial.Cooldown:SetSwipeColor(0, 0, 0, 0.6)
    frame.Racial.Cooldown:SetUseCircularEdge(false)

    if not frame.Trinket.TrinketPixelBorderHook then
        hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
            if t == nil or t == "" or t == 0 or t == "nil" or frame.parent.db.profile.currentLayout ~= layoutName then
                frame.PixelBorders.trinket:Hide()
            else
                frame.PixelBorders.trinket:Show()
            end
        end)
        frame.Trinket.TrinketPixelBorderHook = true
    end

    if not frame.Racial.RacialPixelBorderHook then
        hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
            if t == nil or t == "" or t == 0 or t == "nil" or frame.parent.db.profile.currentLayout ~= layoutName then
                frame.PixelBorders.racial:Hide()
            else
                frame.PixelBorders.racial:Show()
            end
        end)
        frame.Racial.RacialPixelBorderHook = true
    end

    frame.PowerBar:SetHeight(self.db.powerBarHeight)

    frame.ClassIcon:SetSize(self.db.height-4, self.db.height-4)
    frame.ClassIcon:Show()

    local f = frame.Name
    f:SetJustifyH("LEFT")
    f:SetFontObject("Game10Font_o1")
    --f:SetPoint("LEFT", frame.HealthBar, "LEFT", 3, -1)
    f:SetHeight(12)



    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER", 0, -1)
    f:SetSize(self.db.height * 0.8, self.db.height * 0.8)

    --frame.HealthText:SetPoint("RIGHT", frame.HealthBar, "RIGHT", 0, -1)
    --frame.HealthText:SetShadowOffset(0, 0)

    frame.PowerText:SetPoint("CENTER", frame.PowerBar)
    --frame.PowerText:SetShadowOffset(0, 0)
    frame.PowerText:SetAlpha(0)

    frame.SpecNameText:SetPoint("LEFT", frame.PowerBar, "LEFT", 3, 0)

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

    self:UpdateOrientation(frame)
end

function layout:UpdateOrientation(frame)
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon
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
            name:SetPoint("LEFT", frame.HealthBar, "LEFT", 3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
            name:SetPoint("RIGHT", frame.HealthBar, "RIGHT", -3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        else
            name:SetPoint("CENTER", frame.HealthBar, "CENTER", (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0))
        end

        -- Health Text
        healthText:ClearAllPoints()
        if (txt.healthAnchor or "CENTER") == "LEFT" then
            healthText:SetPoint("LEFT", healthBar, "LEFT", 0 + (txt.healthOffsetX or 0), 1 + (txt.healthOffsetY or 0))
        elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
            healthText:SetPoint("RIGHT", healthBar, "RIGHT", 0 + (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0))
        else
            healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0))
        end

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", frame.PowerBar, "LEFT", 3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", frame.PowerBar, "RIGHT", -3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
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
    powerBar:ClearAllPoints()
    classIcon:ClearAllPoints()
    frame.ClassIcon:SetSize(self.db.height-4, self.db.height-4)

    if (self.db.mirrored) then
        healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
        healthBar:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT")
        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2)
        powerBar:SetPoint("LEFT", classIcon, "RIGHT", 0, 0)

        classIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
    else
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
        healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT")

        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 2)
        powerBar:SetPoint("RIGHT", classIcon, "LEFT", 0, 0)

        classIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
    end
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings