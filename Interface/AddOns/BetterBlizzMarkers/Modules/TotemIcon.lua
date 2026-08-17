local addonName, BBM = ...

local addon = BBM.addon

local isFriend                 = BBM.isFriend
local isEnemy                  = BBM.isEnemy
local GetNamePlate             = BBM.GetNamePlate
local GetAnchorFrame           = BBM.GetAnchorFrame
local anchorOpposite           = BBM.anchorOpposite
local isInArena                = BBM.isInArena
local isInBG                   = BBM.isInBG
local isInCity                 = BBM.isInCity
local isInWorld                = BBM.isInWorld
local CreateNameplateContainer = BBM.CreateNameplateContainer

local TOTEM_ICON_GENERIC   = "Interface\\Icons\\Spell_shaman_totemrecall"
local TOTEM_ICON_GROUNDING = "Interface\\Icons\\Spell_Nature_Groundingtotem"
local TOTEM_ICON_PSYFIEND  = C_Spell.GetSpellTexture(199824)
local TOTEM_ICON_CAPACITOR = C_Spell.GetSpellTexture(192058)

local STRATA_ORDER = {
    BACKGROUND        = 1,
    LOW               = 2,
    MEDIUM            = 3,
    HIGH              = 4,
    DIALOG            = 5,
    FULLSCREEN        = 6,
    FULLSCREEN_DIALOG = 7,
    TOOLTIP           = 8,
}

local PSYFIEND_DURATION           = 12
local CAPACITOR_DURATION          = 2

local TOTEM_AURA_IMPORTANT_FILTER = "HELPFUL|IMPORTANT"
local TOTEM_AURA_OTHERS_FILTER    = "HELPFUL|!IMPORTANT"
local TOTEM_AURA_ICON_MASK        = "UI-Frame-IconMask"

local GetHealthBar = BBM.GetHealthBar

local function GetNameText(nameplate)
    if nameplate.unitFrame and nameplate.unitFrame.name then
        return nameplate.unitFrame.name
    end
    local uf = nameplate.UnitFrame
    return uf and uf.name
end

local function GetPlaterUnitFrame(nameplate)
    if not Plater then return nil end
    local uf = nameplate.unitFrame
    if uf and uf.PlaterOnScreen and uf.unit then return uf end
    return nil
end

local GetPlatynatorHealthBar = BBM.GetPlatynatorHealthBar
local GetVisibleHealthBar    = BBM.GetVisibleHealthBar

local function GetPlaterHealthBar(nameplate)
    local uf = GetPlaterUnitFrame(nameplate)
    return uf and uf.healthBar or nil
end

local function ApplyAuraContainerLayering(nameplate, container)
    local platerBar = GetPlaterHealthBar(nameplate)
    if platerBar then
        if container:GetParent() ~= platerBar then
            container:SetParent(platerBar)
            container:SetFrameStrata("MEDIUM")
            container:SetFrameLevel(1)
        end
        return
    end

    local ownFrame = nameplate.BetterBlizzMarkers
    if ownFrame and container:GetParent() ~= ownFrame then
        container:SetParent(ownFrame)
    end

    local bar = GetVisibleHealthBar(nameplate)
    if bar and bar.GetFrameLevel then
        local barStrata = bar:GetFrameStrata()
        local raise = (STRATA_ORDER[barStrata] or 0) > STRATA_ORDER.MEDIUM
        container:SetFrameStrata(raise and barStrata or "MEDIUM")
        container:SetFrameLevel(bar:GetFrameLevel() + 10)
    end
end

local function ApplyHealthbarOverlay(overlay, nameplate, color)
    local bar = GetVisibleHealthBar(nameplate)
    local fill = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not fill then
        overlay:Hide()
        return
    end

    overlay:SetAllPoints(fill)

    local atlas = fill.GetAtlas and fill:GetAtlas()
    if atlas then
        overlay:SetAtlas(atlas)
    else
        overlay:SetTexture(fill:GetTexture())
    end

    overlay:SetVertexColor(color.r or color[1], color.g or color[2], color.b or color[3], 1)

    if not BBM.OtherNameplateAddonActive then
        BBM.ApplyMidnightMask(bar, overlay)
    end
end

local function InitTotemAuraIcon(auraFrame, nameplate, colorKey, useGlow)
    auraFrame:SetSize(25, 25)

    local icon = auraFrame:CreateTexture(nil, "BORDER")
    icon:SetAllPoints(auraFrame)
    auraFrame:SetIcon(icon)

    local mask = auraFrame:CreateMaskTexture()
    mask:SetAtlas(TOTEM_AURA_ICON_MASK)
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    local p = addon.db.profile.totemIcons
    local color = colorKey and p.totemColors[colorKey]

    if useGlow and p.showGlow then
        local glow = auraFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        glow:SetAtlas("clickcast-highlight-spellbook", false)
        glow:SetDesaturated(true)
        glow:SetPoint("TOPLEFT",     auraFrame, "TOPLEFT",     -9,  9)
        glow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT",  9, -9)
        if color then
            glow:SetVertexColor(color.r or color[1], color.g or color[2], color.b or color[3])
        end
    end

    if nameplate and color and p.showColor and p.colorHealthbar then
        local overlay = auraFrame:CreateTexture(nil, "OVERLAY")
        ApplyHealthbarOverlay(overlay, nameplate, color)
    end

    auraFrame:SetMouseMotionEnabled(false)
end

local function CreateTotemAuraContainer(f, nameplate)
    if f.auraContainer then return end

    local container = CreateFrame("AuraContainer", nil, nameplate.BetterBlizzMarkers, "CustomAuraContainerTemplate")
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(1)
    ApplyAuraContainerLayering(nameplate, container)
    container:SetPoint("CENTER", f, "CENTER", 0, 0)
    container:SetFlowLayoutAnchorPoint("CENTER")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    container:SetEnabled(false)
    container:Hide()

    container:AddAuraGroup("Important", TOTEM_AURA_IMPORTANT_FILTER, {
        maxFrameCount   = 1,
        initializeFrame = function(auraFrame) InitTotemAuraIcon(auraFrame, nameplate, "grounding", true) end,
    })
    container:AddAuraGroup("Others", TOTEM_AURA_OTHERS_FILTER, {
        maxFrameCount   = 1,
        initializeFrame = function(auraFrame) InitTotemAuraIcon(auraFrame, nameplate, "healingStream", false) end,
    })

    f.auraContainer = container
end

local function DisableTotemAuraContainer(f)
    if not f.auraContainer then return end
    f.auraContainer:SetEnabled(false)
    f.auraContainer:Hide()
end

local function UpdateTotemAuraContainer(f, unitToken)
    local container = f.auraContainer
    container:SetUnit(unitToken)
    container:SetEnabled(true)
    container:Show()
end

local function CreateTotemIcon(nameplate)
    CreateNameplateContainer(nameplate)
    if nameplate.BetterBlizzMarkers.TotemIcon then return end

    local f = CreateFrame("Frame", nil, nameplate.BetterBlizzMarkers)
    f:SetSize(25, 25)
    f:SetIgnoreParentAlpha(true)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(1)

    f.icon = f:CreateTexture(nil, "BORDER")
    f.icon:SetAllPoints(f)

    f.iconMask = f:CreateMaskTexture()
    f.iconMask:SetAtlas("UI-Frame-IconMask")
    f.iconMask:SetAllPoints(f.icon)
    f.icon:AddMaskTexture(f.iconMask)

    f.glowFrame = CreateFrame("Frame", nil, f)
    f.glowFrame:SetAllPoints(f)
    f.glowFrame:SetFrameStrata("LOW")

    f.glow = f.glowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    f.glow:SetAtlas("clickcast-highlight-spellbook", false)
    f.glow:SetDesaturated(true)
    f.glow:SetPoint("TOPLEFT",     f, "TOPLEFT",     -9,  9)
    f.glow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  9, -9)
    f.glow:Hide()

    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown:SetPoint("TOPLEFT",     f, "TOPLEFT",      1, -1)
    f.cooldown:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  -1,  1)
    f.cooldown:SetReverse(true)
    f.cooldown:SetDrawSwipe(true)
    f.cooldown:SetDrawEdge(false)
    f.cooldown:SetAlpha(0)
    f.cooldown:Hide()

    if BBM.NewMidnightAuras then
        CreateTotemAuraContainer(f, nameplate)
    end

    nameplate.BetterBlizzMarkers.TotemIcon = f
end

local function getPositionSettings(p, friend)
    if not p.separateSettings then
        return p.anchor, p.xPos, p.yPos, p.scale
    end
    if friend then
        return p.friendlyAnchor, p.friendlyXPos, p.friendlyYPos, p.friendlyScale
    else
        return p.enemyAnchor, p.enemyXPos, p.enemyYPos, p.enemyScale
    end
end

local function UpdateTotemIcon(nameplate, friend)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.TotemIcon
    if not f then return end
    local p = addon.db.profile.totemIcons
    local anchor, xPos, yPos, scale = getPositionSettings(p, friend)

    f:SetScale(scale or 1.0)
    f:SetFrameStrata(p.strata or "BACKGROUND")
    f:ClearAllPoints()
    f:SetPoint(anchorOpposite[anchor], GetAnchorFrame(nameplate), anchor, xPos, yPos + 10)

    if f.auraContainer then
        f.auraContainer:SetScale(scale or 1.0)
        ApplyAuraContainerLayering(nameplate, f.auraContainer)
    end
end

local applyingPlatynatorColor = false
local ReapplyHealthbarColor

local DRIVER_PLATER     = "plater"
local DRIVER_PLATYNATOR = "platynator"
local DRIVER_BLIZZARD   = "blizzard"

local function HookPlatynatorHealthBar(bar)
    if bar.bbmSetColorHook == bar.SetColor then return end

    hooksecurefunc(bar, "SetColor", function(self, r, g, b, a)
        if applyingPlatynatorColor then return end
        if r ~= nil then
            local c = self.bbmBaseColor
            if not c then
                c = {}
                self.bbmBaseColor = c
            end
            if a == nil then a = 1 end
            c[1], c[2], c[3], c[4] = r, g, b, a
            c.unit = self.unit
        end
        local display = self:GetParent()
        ReapplyHealthbarColor(display and display:GetParent(), true)
    end)
    bar.bbmSetColorHook = bar.SetColor
end

local function GetHealthbarDriver(nameplate)
    local platerFrame = GetPlaterUnitFrame(nameplate)
    if platerFrame and platerFrame.healthBar then
        return DRIVER_PLATER, platerFrame.healthBar
    end

    local platynatorBar = GetPlatynatorHealthBar(nameplate)
    if platynatorBar then
        HookPlatynatorHealthBar(platynatorBar)
        return DRIVER_PLATYNATOR, platynatorBar
    end

    local hb = GetHealthBar(nameplate)
    if hb then return DRIVER_BLIZZARD, hb end
end

local function GetDriverTextures(driver, bar)
    local textures = bar.bbmTintTextures
    if textures then return textures end

    textures = {}
    if driver == DRIVER_PLATYNATOR then
        local fill = bar.statusBar and bar.statusBar:GetStatusBarTexture()
        if fill then textures[#textures + 1] = fill end
        local cutaway = bar.statusBarCutaway and bar.statusBarCutaway:GetStatusBarTexture()
        if cutaway then textures[#textures + 1] = cutaway end
        if bar.marker then textures[#textures + 1] = bar.marker end
    else
        local fill = bar.barTexture or (bar.GetStatusBarTexture and bar:GetStatusBarTexture())
        if fill then textures[#textures + 1] = fill end
    end

    if #textures == 0 then return nil end
    bar.bbmTintTextures = textures
    return textures
end

local function ReadDriverBaseColor(driver, bar, tinted)
    if driver == DRIVER_PLATER then
        return bar.R, bar.G, bar.B, bar.A
    end

    if driver == DRIVER_PLATYNATOR then
        local c = bar.bbmBaseColor
        if c and c.unit == bar.unit then return c[1], c[2], c[3], c[4] end
        if tinted then return nil end
        local fill = bar.statusBar and bar.statusBar:GetStatusBarTexture()
        if fill then return fill:GetVertexColor() end
        return nil
    end

    if tinted or not bar.GetStatusBarColor then return nil end
    return bar:GetStatusBarColor()
end

local function EnsureBaseColor(f, driver, bar, refresh)
    local tinted = f.healthbarPainted and f.healthbarBar == bar and not refresh
    local r, g, b, a = ReadDriverBaseColor(driver, bar, tinted)

    if r == nil then
        if f.healthbarBase and f.healthbarBaseBar == bar then return f.healthbarBase end
        r, g, b, a = 1, 1, 1, 1
    end
    if a == nil then a = 1 end

    local base = f.healthbarBase
    if not base then
        base = CreateColor(1, 1, 1, 1)
        f.healthbarBase = base
    end
    base:SetRGBA(r, g, b, a)
    f.healthbarBaseBar = bar
    return base
end

local function ApplyPlainColor(driver, bar, r, g, b, a)
    if driver == DRIVER_PLATYNATOR then
        applyingPlatynatorColor = true
        bar:SetColor(r, g, b, a)
        applyingPlatynatorColor = false
        return true
    end

    local textures = GetDriverTextures(driver, bar)
    if not textures then return false end
    for _, texture in ipairs(textures) do
        texture:SetVertexColor(r, g, b, a)
    end
    return true
end

local function ApplyBooleanColor(driver, bar, uninterruptible, tint, base)
    local textures = GetDriverTextures(driver, bar)
    if not textures then return false end

    local applied = false
    for _, texture in ipairs(textures) do
        if texture.SetVertexColorFromBoolean then
            texture:SetVertexColorFromBoolean(uninterruptible, tint, base)
            applied = true
        end
    end
    return applied
end

local function PaintHealthbar(nameplate, r, g, b, f, uninterruptible, refreshBase)
    local driver, bar = GetHealthbarDriver(nameplate)
    if not driver then return end

    local base = EnsureBaseColor(f, driver, bar, refreshBase)

    local applied
    if uninterruptible == nil then
        applied = ApplyPlainColor(driver, bar, r, g, b, base.a)
    else
        local tint = f.healthbarTint
        if not tint then
            tint = CreateColor(1, 1, 1, 1)
            f.healthbarTint = tint
        end
        tint:SetRGBA(r, g, b, base.a)
        applied = ApplyBooleanColor(driver, bar, uninterruptible, tint, base)
    end

    if applied then
        f.healthbarPainted = true
        f.healthbarDriver  = driver
        f.healthbarBar     = bar
    end
end

local function RestoreHealthbarColor(f)
    if not f.healthbarPainted then return end
    local driver, bar, base = f.healthbarDriver, f.healthbarBar, f.healthbarBase
    f.healthbarPainted = nil
    if not driver or not bar or not base then return end
    ApplyPlainColor(driver, bar, base.r, base.g, base.b, base.a)
end

local function SetHealthbarColor(nameplate, f, r, g, b, uninterruptible)
    local c = f.healthbarColor
    if not c then
        c = {}
        f.healthbarColor = c
    end
    c[1], c[2], c[3] = r, g, b
    f.healthbarUninterruptible = uninterruptible
    PaintHealthbar(nameplate, r, g, b, f, uninterruptible)
end

local function ClearHealthbarColor(f)
    if not f then return end
    RestoreHealthbarColor(f)
    f.healthbarColor = nil
    f.healthbarUninterruptible = nil
end

local function ForgetHealthbarColor(f)
    RestoreHealthbarColor(f)
    f.healthbarColor           = nil
    f.healthbarUninterruptible = nil
    f.healthbarBase            = nil
    f.healthbarBaseBar         = nil
    f.healthbarDriver          = nil
    f.healthbarBar             = nil
end

local function ClearPsyfiendIconAlpha(f)
    if not f then return end
    f.icon:SetAlpha(1)
    f.glow:SetAlpha(1)
    f.cooldown:SetAlpha(0)
end

local function PaintName(nameplate, color)
    local nt = GetNameText(nameplate)
    if not nt or not nt.GetText then return end

    local text = BBM.StripColorCodes(nt:GetText())
    if not text or text == "" then return end

    BBM.SetColoredText(nt, BBM.WrapTextInColor(text, color))
end

local function SetNameColor(nameplate, f, r, g, b)
    local c = f.nameColor
    if not c then
        c = {}
        f.nameColor = c
    end
    c[1], c[2], c[3] = r, g, b
    PaintName(nameplate, c)
end

local function ClearTotemColors(f)
    if not f then return end
    ClearHealthbarColor(f)
    f.nameColor = nil
end

local function ForgetTotemColors(f)
    ForgetHealthbarColor(f)
    f.nameColor = nil
    ClearPsyfiendIconAlpha(f)
end

local function HideTotemIcon(f)
    f:Hide()
    DisableTotemAuraContainer(f)
    ClearTotemColors(f)
    ClearPsyfiendIconAlpha(f)
end

function ReapplyHealthbarColor(nameplate, refreshBase)
    if not nameplate or BBM.IsForbiddenNameplate(nameplate) then return end
    local container = nameplate.BetterBlizzMarkers
    local f = container and container.TotemIcon
    local c = f and f.healthbarColor
    if not c then return end
    PaintHealthbar(nameplate, c[1], c[2], c[3], f, f.healthbarUninterruptible, refreshBase)
end

local function ReapplyNameColor(nameplate)
    if BBM.IsForbiddenNameplate(nameplate) then return end
    local container = nameplate.BetterBlizzMarkers
    local f = container and container.TotemIcon
    local c = f and f.nameColor
    if not c then return end
    PaintName(nameplate, c)
end

local function HookBlizzardHealthColor()
    if BBM.hooks["TotemIcon_HealthColor"] then return end
    BBM.hooks["TotemIcon_HealthColor"] = true

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        if issecretvalue(frame) then return end
        if not frame or frame:IsForbidden() or not frame.unit then return end
        local unit = frame.unit
        if not unit:find("nameplate") then return end
        ReapplyHealthbarColor(GetNamePlate(unit), true)
    end)
end

local function HookPlaterHealthColor()
    if BBM.hooks["TotemIcon_PlaterHealthColor"] then return end
    if not (Plater and Plater.ChangeHealthBarColor_Internal) then return end
    BBM.hooks["TotemIcon_PlaterHealthColor"] = true

    hooksecurefunc(Plater, "ChangeHealthBarColor_Internal", function(healthBar)
        local unitFrame = healthBar and healthBar.unitFrame
        local plateFrame = unitFrame and unitFrame.PlateFrame
        if not plateFrame then return end
        ReapplyHealthbarColor(plateFrame, true)
    end)
end

local function HookBlizzardName()
    if BBM.hooks["TotemIcon_NameColor"] then return end
    BBM.hooks["TotemIcon_NameColor"] = true

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if issecretvalue(frame) then return end
        if not frame or frame:IsForbidden() or not frame.unit then return end
        local unit = frame.unit
        if not unit:find("nameplate") then return end
        ReapplyNameColor(GetNamePlate(unit))
    end)
end

local function ApplyHook()
    local p = addon.db.profile.totemIcons
    if not p.showColor then return end
    if p.colorHealthbar then
        HookBlizzardHealthColor()
        HookPlaterHealthColor()
    end
    if p.colorName then
        HookBlizzardName()
    end
end

local function ApplyNameplateColor(nameplate, f, color, isImportant, uninterruptible)
    local p = addon.db.profile.totemIcons
    if not p.showColor or (not isImportant and not p.colorOthers) then
        ClearTotemColors(f)
        return
    end

    local r = color.r or color[1]
    local g = color.g or color[2]
    local b = color.b or color[3]

    if p.colorHealthbar then
        SetHealthbarColor(nameplate, f, r, g, b, uninterruptible)
    else
        ClearHealthbarColor(f)
    end

    if p.colorName then
        SetNameColor(nameplate, f, r, g, b)
    else
        f.nameColor = nil
    end
end

local function RenderTotemIcon(nameplate, unitToken, friend, isRetry)
    local f = nameplate.BetterBlizzMarkers.TotemIcon
    local p = addon.db.profile.totemIcons

    local isCapTotem = UnitCastingInfo(unitToken) ~= nil
    local channelName, _, _, _, _, _, notInterruptible = UnitChannelInfo(unitToken)
    local isPsyfiend = channelName ~= nil

    local uninterruptible
    if isPsyfiend then
        uninterruptible = notInterruptible
    else
        ClearPsyfiendIconAlpha(f)
    end

    if not isPsyfiend and not isCapTotem and not isRetry then
        C_Timer.After(0.25, function()
            if GetNamePlate(unitToken) ~= nameplate then return end
            if not nameplate.BetterBlizzMarkers then return end
            if UnitChannelInfo(unitToken) or UnitCastingInfo(unitToken) then
                RenderTotemIcon(nameplate, unitToken, friend, true)
            end
        end)
    end

    local icon, color, isImportant
    local useOuterGlow = true
    if isPsyfiend then
        icon        = TOTEM_ICON_PSYFIEND
        color       = p.totemColors.psyfiend
        isImportant = true
        if f.auraContainer then f.auraContainer:Hide() end
    elseif isCapTotem then
        icon        = TOTEM_ICON_CAPACITOR
        color       = p.totemColors.capacitor
        isImportant = true
        if f.auraContainer then f.auraContainer:Hide() end
    elseif BBM.NewMidnightAuras then
        if f.auraContainer then
            UpdateTotemAuraContainer(f, unitToken)
        end
        icon         = TOTEM_ICON_GENERIC
        color        = p.totemColors.others
        isImportant  = false
        useOuterGlow = false
    else
        icon        = TOTEM_ICON_GENERIC
        color       = p.totemColors.others
        isImportant = false
    end

    ApplyNameplateColor(nameplate, f, color, isImportant, uninterruptible)

    if not isImportant and not p.showOtherTotems then
        if BBM.NewMidnightAuras and f.auraContainer then
            f.icon:Hide()
            f.glow:Hide()
            f.cooldown:Hide()
            UpdateTotemIcon(nameplate, friend)
            f:Show()
            return
        end
        f:Hide()
        return
    end

    f.icon:SetTexture(icon)
    f.icon:Show()

    if isPsyfiend then
        f.cooldown:SetCooldown(GetTime(), PSYFIEND_DURATION)
        f.cooldown:Show()
    elseif isCapTotem then
        f.cooldown:SetAlpha(1)
        f.cooldown:SetCooldown(GetTime(), CAPACITOR_DURATION)
        f.cooldown:Show()
    else
        f.cooldown:Hide()
    end

    if useOuterGlow and p.showGlow and color then
        local r = color.r or color[1]
        local g = color.g or color[2]
        local b = color.b or color[3]
        f.glow:SetVertexColor(r, g, b)
        f.glow:Show()
    else
        f.glow:Hide()
    end

    if isPsyfiend then
        f.icon:SetAlphaFromBoolean(uninterruptible, 1, 0)
        f.glow:SetAlphaFromBoolean(uninterruptible, 1, 0)
        f.cooldown:SetAlphaFromBoolean(uninterruptible, 1, 0)
    end

    UpdateTotemIcon(nameplate, friend)
    f:Show()
end

local TOTEM_TEST_TYPES = {
    grounding = { icon = TOTEM_ICON_GROUNDING, colorKey = "grounding", isImportant = true  },
    capacitor = { icon = TOTEM_ICON_CAPACITOR, colorKey = "capacitor", isImportant = true  },
    psyfiend  = { icon = TOTEM_ICON_PSYFIEND,  colorKey = "psyfiend",  isImportant = true  },
    others    = { icon = TOTEM_ICON_GENERIC,   colorKey = "others",    isImportant = false },
}

local function RollTestTotemType(p)
    local roll = math.random()
    if p.showOtherTotems then
        if roll < 0.25 then return "grounding"
        elseif roll < 0.50 then return "capacitor"
        elseif roll < 0.70 then return "psyfiend"
        else return "others" end
    else
        if roll < 0.34 then return "grounding"
        elseif roll < 0.67 then return "capacitor"
        else return "psyfiend" end
    end
end

local function ShowHideTotemIconTestMode(nameplate, unitToken)
    if not nameplate then return end
    CreateTotemIcon(nameplate)

    local f = nameplate.BetterBlizzMarkers.TotemIcon
    local p = addon.db.profile.totemIcons

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not p.showFriendly then f:Hide(); ClearTotemColors(f); return end
    if enemy  and not p.showEnemy    then f:Hide(); ClearTotemColors(f); return end

    if not f.testType or (f.testType == "others" and not p.showOtherTotems) then
        f.testType = RollTestTotemType(p)
    end

    local vis         = TOTEM_TEST_TYPES[f.testType]
    local icon        = vis.icon
    local color       = p.totemColors[vis.colorKey]
    local isImportant = vis.isImportant

    ClearPsyfiendIconAlpha(f)

    if f.auraContainer then f.auraContainer:Hide() end
    f.icon:SetTexture(icon)
    f.icon:Show()

    if p.showGlow and color then
        local r = color.r or color[1]
        local g = color.g or color[2]
        local b = color.b or color[3]
        f.glow:SetVertexColor(r, g, b)
        f.glow:Show()
    else
        f.glow:Hide()
    end

    f.cooldown:Hide()

    ApplyNameplateColor(nameplate, f, color, isImportant)
    UpdateTotemIcon(nameplate, friend)
    f:Show()
end

local function ClearTestState(nameplate)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.TotemIcon
    if f then f.testType = nil end
end

local function ShowHideTotemIcon(nameplate, unitToken)
    if not nameplate then return end
    CreateTotemIcon(nameplate)

    local f = nameplate.BetterBlizzMarkers.TotemIcon
    local p = addon.db.profile.totemIcons

    if isInArena() and not p.showInArena then HideTotemIcon(f); return end
    if isInBG()    and not p.showInBG    then HideTotemIcon(f); return end
    if isInCity()  and not p.showInCity  then HideTotemIcon(f); return end
    if isInWorld() and not p.showInWorld then HideTotemIcon(f); return end

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not p.showFriendly then HideTotemIcon(f); return end
    if enemy  and not p.showEnemy    then HideTotemIcon(f); return end

    local isProbablyTotem = UnitIsMinion(unitToken)
        and not UnitIsOtherPlayersPet(unitToken)
        and not UnitIsUnit(unitToken, "pet")

    if not isProbablyTotem then
        HideTotemIcon(f)
        return
    end

    RenderTotemIcon(nameplate, unitToken, friend)
end

local function onNamePlateAdded(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    if BBM.IsForbiddenNameplate(nameplate) then return end
    if BBM.IsTestMode("totemIcons") then
        ShowHideTotemIconTestMode(nameplate, unitToken)
    else
        ShowHideTotemIcon(nameplate, unitToken)
    end
end

local function onNamePlateRemoved(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    if BBM.IsForbiddenNameplate(nameplate) then return end
    if nameplate.BetterBlizzMarkers then
        local ti = nameplate.BetterBlizzMarkers.TotemIcon
        if ti then
            ti:Hide()
            ti.testType = nil
            DisableTotemAuraContainer(ti)
            ForgetTotemColors(ti)
        end
    end
end

local function onUnitFaction(_, unitToken)
    if not GetNamePlate(unitToken) then return end
    C_Timer.After(0.1, function()
        onNamePlateAdded(_, unitToken)
    end)
end

local function RefreshAllTotemPlates()
    ApplyHook()

    local testMode = BBM.IsTestMode("totemIcons")
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        if not BBM.IsForbiddenNameplate(nameplate) then
            local unit = nameplate.namePlateUnitToken
                or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
            if unit then
                if testMode then
                    ShowHideTotemIconTestMode(nameplate, unit)
                else
                    ClearTestState(nameplate)
                    ShowHideTotemIcon(nameplate, unit)
                end
            end
        end
    end
end

table.insert(BBM.RefreshCallbacks, RefreshAllTotemPlates)

table.insert(BBM.EnableCallbacks, function(_)
    BBM.On("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
    BBM.On("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
    BBM.On("UNIT_FACTION",            onUnitFaction)
    ApplyHook()
end)

function BBM.RefreshTotems()
    RefreshAllTotemPlates()
end
