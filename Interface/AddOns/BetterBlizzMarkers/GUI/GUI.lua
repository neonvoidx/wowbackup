local addonName, BBM = ...
local BBG   = BetterBlizzGUI

BBM.totemPreviewTints = BBM.totemPreviewTints or {}

local function BuildClassIconPreview(holder, size, hidePin)
    local scale = size / 41

    local class      = UnitClassBase("player")
    local classColor = C_ClassColor.GetClassColor(class)

    local bg = holder:CreateTexture(nil, "BACKGROUND")
    bg:SetAtlas("talents-node-choiceflyout-circle-greenglow")
    bg:SetSize(61 * scale, 61 * scale)
    bg:SetPoint("CENTER", holder)
    bg:SetDesaturated(true)
    bg:SetVertexColor(0.1, 0.1, 0.1)

    local icon = holder:CreateTexture(nil, "BORDER")
    icon:SetPoint("CENTER", holder)
    icon:SetSize(size - 6, size - 6)

    local mask = holder:CreateMaskTexture()
    mask:SetTexture("Interface/Masks/CircleMaskScalable")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    icon:SetAtlas(GetClassAtlas(class))
    icon:SetTexCoord(-0.06, 1.05, -0.06, 1.05)

    local border = holder:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("AutoQuest-badgeborder")
    border:SetAllPoints(holder)
    if classColor then
        border:SetDesaturated(true)
        border:SetVertexColor(classColor.r, classColor.g, classColor.b)
    end

    if hidePin then return end

    local pin = holder:CreateTexture(nil, "BACKGROUND")
    pin:SetAtlas("UI-QuestPoiImportant-QuestNumber-SuperTracked")
    pin:SetSize(43 * scale, 39 * scale)
    pin:SetPoint("TOP", icon, "BOTTOM", 0, 10 * scale)
    pin:SetDesaturated(true)
    pin:SetTexCoord(0, 1, 0.27, 1)
    if classColor then
        pin:SetVertexColor(classColor.r, classColor.g, classColor.b)
    end
end

local function BuildTotemIconPreview(holder, size)
    local icon = holder:CreateTexture(nil, "BORDER")
    icon:SetAllPoints(holder)
    icon:SetTexture("Interface\\Icons\\Spell_Nature_Groundingtotem")

    local mask = holder:CreateMaskTexture()
    mask:SetAtlas("UI-Frame-IconMask")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    local glow = holder:CreateTexture(nil, "OVERLAY")
    glow:SetAtlas("newplayertutorial-drag-slotgreen", false)
    glow:SetDesaturated(true)
    local offset = size * (28.5 / 64)
    glow:SetPoint("TOPLEFT",     holder, "TOPLEFT",     -offset,  offset)
    glow:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT",  offset, -offset)

    local function TintGlow()
        local color = BBM.addon.db.profile.totemIcons.totemColors.grounding
        glow:SetVertexColor(color.r or color[1], color.g or color[2], color.b or color[3])
    end
    TintGlow()
    BBM.totemPreviewTints[#BBM.totemPreviewTints + 1] = TintGlow
end

local TEXTURE_PATH = "Interface\\AddOns\\" .. addonName .. "\\Assets\\Textures\\"

local SOCIAL_LINKS = {
    { label = "Discord", url = "https://discord.gg/cjqVaEMm25",  icon = TEXTURE_PATH .. "discord.png" },
    { label = "PayPal",  url = "https://paypal.me/bodifydev",    icon = TEXTURE_PATH .. "paypal.png"  },
    { label = "Patreon", url = "https://patreon.com/bodifydev",  icon = TEXTURE_PATH .. "patreon.tga" },
}

local LINK_COLUMN_H     = 46
local LINK_COLUMN_SCALE = 0.85

local function MakeLinkColumn(parent, link, centerX, y, width)
    local column = CreateFrame("Frame", nil, parent)
    column:SetSize(width, LINK_COLUMN_H)
    column:SetScale(LINK_COLUMN_SCALE)
    column:SetPoint("TOP", parent, "TOPLEFT", centerX / LINK_COLUMN_SCALE, y / LINK_COLUMN_SCALE)

    local icon = column:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(link.icon)
    icon:SetSize(20, 20)

    local label = column:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(link.label)
    label:SetPoint("LEFT", icon, "RIGHT", 5, 0)

    icon:SetPoint("TOPLEFT", column, "TOPLEFT", (width - (20 + 5 + label:GetStringWidth())) / 2, 0)

    local box = CreateFrame("EditBox", nil, column, "InputBoxTemplate")
    box:SetSize(width - 4, 20)
    box:SetPoint("BOTTOM", column, "BOTTOM", 3, 0)
    box:SetFontObject("ChatFontSmall")
    box:SetAutoFocus(false)
    box:SetText(link.url)
    box:SetCursorPosition(0)
    box:SetAlpha(0.7)

    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
    box:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= link.url then
            self:SetText(link.url)
        end
        if self:HasFocus() then
            self:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnEditFocusLost",   function(self) self:HighlightText(0, 0) end)
    box:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    return column
end

local function BuildSocialFooter(root, top)
    local WIDTH   = root:GetWidth()
    local MARGIN  = 48
    local COL_W   = 168
    local ON_SCREEN_W = COL_W * LINK_COLUMN_SCALE
    local GAP     = 14
    local SPAN    = ON_SCREEN_W * #SOCIAL_LINKS + GAP * (#SOCIAL_LINKS - 1)

    local divider = root:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.3, 0.3, 0.3, 0.7)
    divider:SetPoint("TOPLEFT",  root, "TOPLEFT",  MARGIN, top)
    divider:SetPoint("TOPRIGHT", root, "TOPRIGHT", -MARGIN, top)

    local credit = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    credit:SetText("by |cff00c0ffBodify|r")
    credit:SetPoint("TOP", root, "TOP", -14, top - 8)

    local columnsY = top - 32
    local firstX   = (WIDTH - SPAN) / 2 + ON_SCREEN_W / 2
    for i, link in ipairs(SOCIAL_LINKS) do
        MakeLinkColumn(root, link, firstX + (i - 1) * (ON_SCREEN_W + GAP), columnsY, COL_W)
    end

    BBG.NoteContentBottom(root, math.abs(columnsY) + LINK_COLUMN_H * LINK_COLUMN_SCALE)
end

local function MakeTestModeButton(panel, key, what)
    BBG.MakeHeaderButton({
        key     = "testmode",
        width   = 100,
        height  = 22,
        yOffset = 3,
        label   = function()
            if BBM.IsTestMode(key) then return "Stop Test" end
            return "Test"
        end,
        desc    = "Preview " .. what .. " on the nameplates around you so you can "
               .. "position and colour them without being in an arena.\n\n"
               .. "Only one preview runs at a time, and it follows you as you "
               .. "switch pages. Stops when you close settings, change zone or reload.",
        func    = function() BBM.ToggleTestMode(key) end,
    }, panel)
end

function BBM.GuiGeneral(root)
    local addon = BBM.addon

    local header = CreateFrame("Frame", nil, root)
    header:SetPoint("TOP", root, "TOP", 0, -26)
    header:SetSize(root:GetWidth(), 34)

    local titleIcon = header:CreateTexture(nil, "ARTWORK")
    titleIcon:SetAtlas("gmchat-icon-blizz")
    titleIcon:SetSize(30, 30)

    local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
    titleText:SetText(BBM.addonNameColor)
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 6, 3)

    local titleVer = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleVer:SetText("v" .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or ""))
    titleVer:SetPoint("LEFT", titleText, "RIGHT", 6, -3)

    local totalW = titleIcon:GetWidth() + 6 + titleText:GetStringWidth() + 6 + titleVer:GetStringWidth()
    titleIcon:ClearAllPoints()
    titleIcon:SetPoint("LEFT", header, "CENTER", -totalW / 2, 0)

    local TILE_W, TILE_H = 250, 72
    local GAP_X, GAP_Y   = 24, 20
    local marginX  = (root:GetWidth() - (TILE_W * 2 + GAP_X)) / 2
    local gridTop  = -100

    local function openSub(key)
        return function() BBG.OpenPanel(root.subPanels[key]) end
    end

    BBG.MakeCategoryTile({
        title    = "Arena Names",
        x        = marginX,
        y        = gridTop,
        width    = TILE_W, height = TILE_H,
        iconSize = 45,
        iconOffsetY = -7,
        icon     = { atlas = "services-number-1" },
        onClick  = openSub("arena"),
    }, root)

    BBG.MakeCategoryTile({
        title     = "Class Icons",
        x         = marginX + TILE_W + GAP_X,
        y         = gridTop,
        width     = TILE_W, height = TILE_H,
        iconSize  = 49.5,
        iconOffsetX = 0,
        iconOffsetY = 5,
        iconScale = 0.7,
        buildIcon = BuildClassIconPreview,
        onClick   = openSub("class"),
    }, root)

    BBG.MakeCategoryTile({
        title     = "Totem Icons",
        x         = marginX,
        y         = gridTop - TILE_H - GAP_Y,
        width     = TILE_W, height = TILE_H,
        iconSize    = 51,
        iconOffsetX = 3,
        iconOffsetY = -8,
        iconScale = 0.6,
        buildIcon   = BuildTotemIconPreview,
        onClick   = openSub("totem"),
    }, root)

    BBG.MakeCategoryTile({
        title       = "Misc",
        x           = marginX + TILE_W + GAP_X,
        y           = gridTop - TILE_H - GAP_Y,
        width       = TILE_W, height = TILE_H,
        iconSize    = 67,
        iconOffsetX = 9,
        iconOffsetY = -6,
        icon        = { atlas = "GM-icon-settings-hover" },
        onClick     = openSub("misc"),
    }, root)

    BBG.MakeCategoryTile({
        title       = "Profiles",
        x           = marginX + TILE_W / 2 + GAP_X / 2,
        y           = gridTop - (TILE_H + GAP_Y) * 2,
        width       = TILE_W, height = TILE_H,
        iconSize    = 50,
        iconOffsetX = 5,
        iconOffsetY = -6,
        icon        = { atlas = "GM-icon-assistActive" },
        onClick     = openSub("profiles"),
    }, root)

    BuildSocialFooter(root, gridTop - (TILE_H + GAP_Y) * 2 - TILE_H - 165)
end

function BBM.GuiClassIcons(root)
    local addon = BBM.addon
    local p       = BBG.CreateSubPanel(root._category, "BetterBlizzMarkers_ClassIcons", "Class Icons", 620, 800)

    local function P() return addon.db.profile.classIcons end

    BBG.MakePanelHeader({
        title       = "Class Icons",
        iconSize    = 45,
        iconScale   = 0.56,
        iconOffsetX = -2,
        iconOffsetY = 6,
        buildIcon   = function(holder, size) BuildClassIconPreview(holder, size, true) end,
    }, p)
    MakeTestModeButton(p, "classIcons", "class icons")

    local anchorOptions = {
        { label = "Top Left",    value = "TOPLEFT"    }, { label = "Top",    value = "TOP"    },
        { label = "Top Right",   value = "TOPRIGHT"   }, { label = "Left",   value = "LEFT"   },
        { label = "Center",      value = "CENTER"     }, { label = "Right",  value = "RIGHT"  },
        { label = "Bottom Left", value = "BOTTOMLEFT" }, { label = "Bottom", value = "BOTTOM" },
        { label = "Bottom Right",value = "BOTTOMRIGHT"},
    }
    local strataOptions = {
        { label = "Background", value = "BACKGROUND" },
        { label = "Low",        value = "LOW"        },
        { label = "Medium",     value = "MEDIUM"     },
        { label = "High",       value = "HIGH"       },
    }

    BBG.MakeTitle("Visibility", p, { atlas = "GM-icon-visible-hover", sizeX = 33, sizeY = 33, offsetX = 6 })
    BBG.MakeLargeCheckDropdown({
        label = "Show class icon on:",
        options = {
            { label = "Friendly",   get = function() return P().showFriendly    end, set = function(v) P().showFriendly    = v; addon:RefreshAll()              end },
            { label = "Enemy",      get = function() return P().showEnemy       end, set = function(v) P().showEnemy       = v; addon:RefreshAll()              end },
            { label = "Player Pet", get = function() return P().showOnPlayerPet end, set = function(v) P().showOnPlayerPet = v; addon:UpdateEventRegistration(); addon:RefreshAll() end },
        },
    }, p)
    BBG.MakeLargeCheckDropdown({
        label = "Show class icon while:",
        options = {
            { label = "In Arena",         get = function() return P().showInArena end, set = function(v) P().showInArena = v; addon:RefreshAll() end },
            { label = "In Battlegrounds", get = function() return P().showInBG    end, set = function(v) P().showInBG    = v; addon:RefreshAll() end },
            { label = "In World",         get = function() return P().showInWorld end, set = function(v) P().showInWorld = v; addon:RefreshAll() end },
            { label = "In City",          get = function() return P().showInCity  end, set = function(v) P().showInCity  = v; addon:RefreshAll() end },
        },
    }, p)

    BBG.MakeTitle("Tweaks", p, { atlas = "worldquest-tracker-questmarker", sizeX = 17, sizeY = 17, offsetX = -2, offsetY = 1 })
    BBG.MakeCheckbox({ label = "Show Spec Icon",     get = function() return P().showSpecIcon      end, set = function(v) P().showSpecIcon      = v; addon:RefreshAll() end }, p)
    BBG.MakeCheckbox({ label = "Show Healer Icon",   get = function() return P().showHealerIcon    end, set = function(v) P().showHealerIcon    = v; addon:RefreshAll() end }, p)
    BBG.MakeCheckbox({ label = "Class Color Border", get = function() return P().classColorBorder  end, set = function(v) P().classColorBorder  = v; addon:RefreshAll() end }, p)
    BBG.MakeCheckbox({
        label = "Hide Friendly Player Names with active Class Icon",
        desc  = "Blanks out the nameplate name on friendly units that show a class icon.\n\nNames written by Arena Names are left alone.",
        get   = function() return P().hideFriendlyNames end,
        set   = function(v) P().hideFriendlyNames = v; addon:RefreshAll() end,
    }, p)
    local cbTargetGlow = BBG.MakeCheckbox({ label = "Target Glow", get = function() return P().showTargetGlow end, set = function(v) P().showTargetGlow = v; addon:RefreshAll() end }, p)
    local ddTargetGlow = BBG.MakeSmallCheckDropdown({
        subsettingOf = cbTargetGlow,
        buttonText   = "Glow Options",
        options = {
            { label = "Class Color Glow", get = function() return P().targetGlowClassColor end, set = function(v) P().targetGlowClassColor = v; addon:RefreshAll() end },
        },
    }, p)
    local cbShowCC = BBG.MakeCheckbox({ label = "Show CC", get = function() return P().showCC end, set = function(v) P().showCC = v; addon:RefreshAll() end }, p)
    local ddShowCC = BBG.MakeSmallCheckDropdown({
        subsettingOf = cbShowCC,
        buttonText   = "CC Options",
        options = {
            { label = "On Enemy",    get = function() return P().showCCEnemy    end, set = function(v) P().showCCEnemy    = v; addon:RefreshAll() end },
            { label = "On Friendly", get = function() return P().showCCFriendly end, set = function(v) P().showCCFriendly = v; addon:RefreshAll() end },
        },
    }, p)
    local cbPinMode = BBG.MakeCheckbox({ label = "Pin Mode", get = function() return P().pinMode end, set = function(v) P().pinMode = v; addon:RefreshAll() end }, p)
    local ddPinMode = BBG.MakeSmallCheckDropdown({
        subsettingOf = cbPinMode,
        buttonText   = "Pin Options",
        options = {
            { label = "On Enemy",    get = function() return P().pinModeEnemy    end, set = function(v) P().pinModeEnemy    = v; addon:RefreshAll() end },
            { label = "On Friendly", get = function() return P().pinModeFriendly end, set = function(v) P().pinModeFriendly = v; addon:RefreshAll() end },
        },
    }, p)
    local cbPetHealthbars = BBG.MakeCheckbox({
        label = "Hide Pet Healthbars",
        desc  = "Fades out the healthbar on pet nameplates, your own and other players'.\n\nDefault nameplates only, other nameplate addons handle their own healthbars.",
        get   = function() return P().hidePetHealthbars end,
        set   = function(v) P().hidePetHealthbars = v; addon:RefreshAll() end,
    }, p)
    local ddPetHealthbars = BBG.MakeSmallCheckDropdown({
        subsettingOf = cbPetHealthbars,
        buttonText   = "Pet Options",
        options = {
            { label = "Hide Friendly", get = function() return P().hidePetHealthbarsFriendly end, set = function(v) P().hidePetHealthbarsFriendly = v; addon:RefreshAll() end },
            { label = "Hide Enemy",    get = function() return P().hidePetHealthbarsEnemy    end, set = function(v) P().hidePetHealthbarsEnemy    = v; addon:RefreshAll() end },
        },
    }, p)
    BBG.AlignSubsettings({
        { cbTargetGlow,    ddTargetGlow    },
        { cbShowCC,        ddShowCC        },
        { cbPinMode,       ddPinMode       },
        { cbPetHealthbars, ddPetHealthbars },
    })

    BBG.MakeTitle("Size & Position", p, { atlas = "OptionsIcon-Brown", sizeX = 17, sizeY = 17, offsetX = -1.5, offsetY = 0.5 })

    local sharedSection, separateSection, advancedSection
    local advancedYShared, advancedYSeparate

    local function RefreshPositionLayout()
        local sep = P().separateSettings
        sharedSection:SetShown(not sep)
        separateSection:SetShown(sep)
        advancedSection:ClearAllPoints()
        advancedSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, sep and advancedYSeparate or advancedYShared)
    end
    p._layoutRefresh = RefreshPositionLayout

    BBG.MakeCheckbox({
        label = "Use Separate Settings for Friendly & Enemy",
        get   = function() return P().separateSettings end,
        set   = function(v)
            P().separateSettings = v
            addon:RefreshAll()
            RefreshPositionLayout()
        end,
    }, p)

    local sectionsStartY = BBG.GetCursor(p)

    sharedSection = BBG.MakeSection(p)
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().scale end,
        set = function(v) P().scale = v; addon:RefreshAll() end }, sharedSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().xPos end,
        set = function(v) P().xPos = v; addon:RefreshAll() end }, sharedSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().yPos end,
        set = function(v) P().yPos = v; addon:RefreshAll() end }, sharedSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().anchor end,
        set = function(v) P().anchor = v; addon:RefreshAll() end }, sharedSection)
    local H_shared = BBG.FinaliseSection(sharedSection)

    BBG.SetCursor(p, sectionsStartY)
    separateSection = BBG.MakeSection(p)

    local friendlyGroup = BBG.MakeSubTitleGroup("Friendly", separateSection, {0.4, 0.7, 1.0})
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().friendlyScale end,
        set = function(v) P().friendlyScale = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().friendlyXPos end,
        set = function(v) P().friendlyXPos = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().friendlyYPos end,
        set = function(v) P().friendlyYPos = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().friendlyAnchor end,
        set = function(v) P().friendlyAnchor = v; addon:RefreshAll() end }, separateSection)
    BBG.FinaliseSubTitleGroup(friendlyGroup)

    local enemyGroup = BBG.MakeSubTitleGroup("Enemy", separateSection, {1.0, 0.3, 0.3})
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().enemyScale end,
        set = function(v) P().enemyScale = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().enemyXPos end,
        set = function(v) P().enemyXPos = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().enemyYPos end,
        set = function(v) P().enemyYPos = v; addon:RefreshAll() end }, separateSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().enemyAnchor end,
        set = function(v) P().enemyAnchor = v; addon:RefreshAll() end }, separateSection)
    BBG.FinaliseSubTitleGroup(enemyGroup)

    local H_separate = BBG.FinaliseSection(separateSection)

    advancedYShared   = sectionsStartY - H_shared   - 6
    advancedYSeparate = sectionsStartY - H_separate - 6 + 17

    if P().separateSettings then
        sharedSection:Hide()
        BBG.SetCursor(p, advancedYSeparate)
    else
        separateSection:Hide()
        BBG.SetCursor(p, advancedYShared)
    end

    advancedSection = BBG.MakeSection(p)
    BBG.MakeTitle("Misc", advancedSection, { atlas = "services-icon-warning", sizeX = 16, sizeY = 16, offsetX = -2 })
    BBG.MakeDropdown({ label = "Frame Strata", options = strataOptions,
        get = function() return P().strata end,
        set = function(v) P().strata = v; addon:RefreshAll() end }, advancedSection)
    BBG.FinaliseSection(advancedSection)

    return p
end

function BBM.GuiTotemIcons(root)
    local BBG   = BetterBlizzGUI
    local addon = BBM.addon
    if not BBG or not addon then return end

    local p       = BBG.CreateSubPanel(root._category, "BetterBlizzMarkers_TotemIcons", "Totem Icons", 620, 775)

    local function P() return addon.db.profile.totemIcons end

    BBG.MakePanelHeader({
        title       = "Totem Icons",
        iconSize    = 30,
        iconScale   = 0.765,
        iconOffsetX = 2,
        iconOffsetY = 6,
        buildIcon   = BuildTotemIconPreview,
    }, p)
    MakeTestModeButton(p, "totemIcons", "totem icons")

    local anchorOptions = {
        { label = "Top Left",    value = "TOPLEFT"    }, { label = "Top",    value = "TOP"    },
        { label = "Top Right",   value = "TOPRIGHT"   }, { label = "Left",   value = "LEFT"   },
        { label = "Center",      value = "CENTER"     }, { label = "Right",  value = "RIGHT"  },
        { label = "Bottom Left", value = "BOTTOMLEFT" }, { label = "Bottom", value = "BOTTOM" },
        { label = "Bottom Right",value = "BOTTOMRIGHT"},
    }
    local strataOptions = {
        { label = "Background", value = "BACKGROUND" },
        { label = "Low",        value = "LOW"        },
        { label = "Medium",     value = "MEDIUM"     },
        { label = "High",       value = "HIGH"       },
    }

    BBG.MakeTitle("Visibility", p, { atlas = "GM-icon-visible-hover", sizeX = 33, sizeY = 33, offsetX = 6 })
    BBG.MakeLargeCheckDropdown({
        label = "Show totem icon on:",
        options = {
            { label = "Friendly",   get = function() return P().showFriendly end, set = function(v) P().showFriendly = v; BBM.RefreshTotems() end },
            { label = "Enemy",      get = function() return P().showEnemy     end, set = function(v) P().showEnemy     = v; BBM.RefreshTotems() end },
        },
    }, p)
    BBG.MakeLargeCheckDropdown({
        label = "Show totem icon while:",
        options = {
            { label = "In Arena",         get = function() return P().showInArena end, set = function(v) P().showInArena = v; BBM.RefreshTotems() end },
            { label = "In Battlegrounds", get = function() return P().showInBG    end, set = function(v) P().showInBG    = v; BBM.RefreshTotems() end },
            { label = "In World",         get = function() return P().showInWorld end, set = function(v) P().showInWorld = v; BBM.RefreshTotems() end },
            { label = "In City",          get = function() return P().showInCity  end, set = function(v) P().showInCity  = v; BBM.RefreshTotems() end },
        },
    }, p)

    BBG.MakeTitle("Tweaks", p, { atlas = "worldquest-tracker-questmarker", sizeX = 17, sizeY = 17, offsetX = -2, offsetY = 1 })
    BBG.MakeCheckbox({
        label = "Show Glow",
        get   = function() return P().showGlow end,
        set   = function(v) P().showGlow = v; BBM.RefreshTotems() end,
    }, p)
    BBG.MakeCheckbox({
        label = "Show Other Totems",
        desc  = "Show a generic totem icon on \"other\" totem nameplates. These totems cannot be detected individually so they just get a generic totem icon and color.",
        get   = function() return P().showOtherTotems end,
        set   = function(v) P().showOtherTotems = v; BBM.RefreshTotems() end,
    }, p)
    local cbColor = BBG.MakeCheckbox({
        label = "Color",
        get   = function() return P().showColor end,
        set   = function(v) P().showColor = v; BBM.RefreshTotems() end,
    }, p)
    local ddColor = BBG.MakeSmallCheckDropdown({
        subsettingOf = cbColor,
        buttonText   = "Color Options",
        options = {
            { label = "Color Name",      get = function() return P().colorName      end, set = function(v) P().colorName      = v; BBM.RefreshTotems() end },
            { label = "Color Healthbar", get = function() return P().colorHealthbar end, set = function(v) P().colorHealthbar = v; BBM.RefreshTotems() end,
              warnGet = BBM.IsNameplateAddonActive, warnText = "May not be perfect for other nameplate addons than default nameplates." },
            { label = "Color Others",    get = function() return P().colorOthers    end, set = function(v) P().colorOthers    = v; BBM.RefreshTotems() end,
              desc = "Color all other totems that is not the main ones mentioned. The other ones cannot be detected." },
        },
    }, p)
    local RefreshLimitationColors

    local function SetTotemColor(key, r, g, b)
        P().totemColors[key] = { r = r, g = g, b = b }
        BBM.RefreshTotems()
        if RefreshLimitationColors then RefreshLimitationColors() end
    end

    local topColorSwatches, SetTopColorRowEnabled = BBG.MakeColorRow({
        anchorLeft = ddColor,
        offsetY    = 9,
        items = {
            { label = "Grounding", getColor = function() return P().totemColors.grounding end, setColor = function(r,g,b) SetTotemColor("grounding", r, g, b) end },
            { label = "Capacitor", getColor = function() return P().totemColors.capacitor end, setColor = function(r,g,b) SetTotemColor("capacitor", r, g, b) end },
            { label = "Others",    getColor = function() return P().totemColors.others    end, setColor = function(r,g,b) SetTotemColor("others",    r, g, b) end },
        },
    }, p)
    local _, SetBottomColorRowEnabled = BBG.MakeColorRow({
        anchorBelow = topColorSwatches[1],
        items = {
            { label = "Psyfiend",       getColor = function() return P().totemColors.psyfiend      end, setColor = function(r,g,b) SetTotemColor("psyfiend",      r, g, b) end },
            { label = "Healing Stream", getColor = function() return P().totemColors.healingStream end, setColor = function(r,g,b) SetTotemColor("healingStream", r, g, b) end },
        },
    }, p)
    local function SetColorRowEnabled(enabled)
        SetTopColorRowEnabled(enabled)
        SetBottomColorRowEnabled(enabled)
    end
    SetColorRowEnabled(P().showColor)
    cbColor:HookScript("OnClick", function(self) SetColorRowEnabled(self:GetChecked() == true) end)

    BBG.MakeTitle("Size & Position", p, { atlas = "OptionsIcon-Brown", sizeX = 17, sizeY = 17, offsetX = -1.5, offsetY = 0.5 })

    local sharedSection, separateSection, advancedSection
    local advancedYShared, advancedYSeparate

    local function RefreshPositionLayout()
        local sep = P().separateSettings
        sharedSection:SetShown(not sep)
        separateSection:SetShown(sep)
        advancedSection:ClearAllPoints()
        advancedSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, sep and advancedYSeparate or advancedYShared)
    end
    p._layoutRefresh = RefreshPositionLayout

    BBG.MakeCheckbox({
        label = "Use Separate Settings for Friendly & Enemy",
        get   = function() return P().separateSettings end,
        set   = function(v)
            P().separateSettings = v; BBM.RefreshTotems(); RefreshPositionLayout()
        end,
    }, p)

    local sectionsStartY = BBG.GetCursor(p)

    sharedSection = BBG.MakeSection(p)
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().scale end,
        set = function(v) P().scale = v; BBM.RefreshTotems() end }, sharedSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().xPos end,
        set = function(v) P().xPos = v; BBM.RefreshTotems() end }, sharedSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().yPos end,
        set = function(v) P().yPos = v; BBM.RefreshTotems() end }, sharedSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().anchor end,
        set = function(v) P().anchor = v; BBM.RefreshTotems() end }, sharedSection)
    local H_shared = BBG.FinaliseSection(sharedSection)

    BBG.SetCursor(p, sectionsStartY)
    separateSection = BBG.MakeSection(p)

    local friendlyGroup = BBG.MakeSubTitleGroup("Friendly", separateSection, {0.4, 0.7, 1.0})
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().friendlyScale end,
        set = function(v) P().friendlyScale = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().friendlyXPos end,
        set = function(v) P().friendlyXPos = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().friendlyYPos end,
        set = function(v) P().friendlyYPos = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().friendlyAnchor end,
        set = function(v) P().friendlyAnchor = v; BBM.RefreshTotems() end }, separateSection)
    BBG.FinaliseSubTitleGroup(friendlyGroup)

    local enemyGroup = BBG.MakeSubTitleGroup("Enemy", separateSection, {1.0, 0.3, 0.3})
    BBG.MakeSlider({ label = "Size", min = 0.5, max = 4.0, step = 0.05, fmt = "%.2f",
        get = function() return P().enemyScale end,
        set = function(v) P().enemyScale = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().enemyXPos end,
        set = function(v) P().enemyXPos = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().enemyYPos end,
        set = function(v) P().enemyYPos = v; BBM.RefreshTotems() end }, separateSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().enemyAnchor end,
        set = function(v) P().enemyAnchor = v; BBM.RefreshTotems() end }, separateSection)
    BBG.FinaliseSubTitleGroup(enemyGroup)

    local H_separate = BBG.FinaliseSection(separateSection)
    advancedYShared   = sectionsStartY - H_shared   - 6
    advancedYSeparate = sectionsStartY - H_separate - 6 + 17
    if P().separateSettings then
        sharedSection:Hide(); BBG.SetCursor(p, advancedYSeparate)
    else
        separateSection:Hide(); BBG.SetCursor(p, advancedYShared)
    end

    advancedSection = BBG.MakeSection(p)
    BBG.MakeTitle("Misc", advancedSection, { atlas = "services-icon-warning", sizeX = 16, sizeY = 16, offsetX = -2 })
    BBG.MakeDropdown({ label = "Frame Strata", options = strataOptions,
        get = function() return P().strata end,
        set = function(v) P().strata = v; BBM.RefreshTotems() end }, advancedSection)

    BBG.MakeLabel("|cffff4040LIMITATIONS:|r", advancedSection, nil, 0, -8, 560)
    BBG.SetCursor(advancedSection, BBG.GetCursor(advancedSection) - 1)

    local function TotemText(key, text)
        return BBM.WrapTextInColor(text, P().totemColors[key])
    end

    local function BuildLimitations()
        return {
            "• Totem Icons can only properly identify "
                .. TotemText("grounding", "Grounding Totem") .. ", "
                .. TotemText("capacitor", "Capacitor Totem") .. ", "
                .. TotemText("psyfiend", "Psyfiend") .. " and "
                .. TotemText("healingStream", "Healing Stream Totem")
                .. ". All the others get bundled as \"" .. TotemText("others", "Others") .. "\".",
            "• You can only have Totem and/or Pet nameplates enabled and not Minus and Guardians as this would kind of break totem detection and they would all be considered \""
                .. TotemText("others", "Others") .. "\".",
            "• Other nameplate addons may control the visibility of Totem/Pet/Guardian/Minus nameplates. You can click the button below to make sure it's set correctly but other nameplate addons might have their own settings for it and you should check that.",
        }
    end

    local limitationLabels = {}
    for _, limitation in ipairs(BuildLimitations()) do
        limitationLabels[#limitationLabels + 1] = BBG.MakeLabel(limitation, advancedSection, nil, 0, 0, 560)
        BBG.SetCursor(advancedSection, BBG.GetCursor(advancedSection) + 2)
    end

    RefreshLimitationColors = function()
        local texts = BuildLimitations()
        for i, label in ipairs(limitationLabels) do label:SetText(texts[i]) end
    end
    BBM.totemPreviewTints[#BBM.totemPreviewTints + 1] = RefreshLimitationColors

    BBG.SetCursor(advancedSection, BBG.GetCursor(advancedSection) - 12)

    BBG.MakeButton({
        label = "Set Totem/Pet Nameplate CVars",
        width = 220,
        func  = function()
            BBM.RunAfterCombat(function()
                C_CVar.SetCVar("nameplateShowEnemyMinions",   "0")
                C_CVar.SetCVar("nameplateShowEnemyGuardians", "0")
                C_CVar.SetCVar("nameplateShowEnemyMinus",     "0")
                C_CVar.SetCVar("nameplateShowEnemyPets",      "1")
                C_CVar.SetCVar("nameplateShowEnemyTotems",    "1")
            end)
        end,
    }, advancedSection)

    BBG.FinaliseSection(advancedSection)

    return p
end

function BBM.GuiMisc(root)
    local addon = BBM.addon
    local p       = BBG.CreateSubPanel(root._category, "BetterBlizzMarkers_Misc", "Misc", 620, 400)

    local function P() return addon.db.profile.others end

    BBG.MakePanelHeader({
        title       = "Misc",
        iconSize    = 42,
        iconOffsetX = -8,
        iconOffsetY = 1,
        icon        = { atlas = "GM-icon-settings-hover" },
    }, p)

    BBG.MakeTitle("Tweaks", p, { atlas = "worldquest-tracker-questmarker", sizeX = 17, sizeY = 17, offsetX = -2, offsetY = 1 })

    BBG.MakeLargeCheckDropdown({
        label = "Friendly name only mode:",
        options = {
            { label = "In Arena",         get = function() return P().nameOnlyMode.showInArena end, set = function(v) P().nameOnlyMode.showInArena = v; BBM.ApplyNameOnlyMode(true) end },
            { label = "In Battlegrounds", get = function() return P().nameOnlyMode.showInBG    end, set = function(v) P().nameOnlyMode.showInBG    = v; BBM.ApplyNameOnlyMode(true) end },
            { label = "In World",         get = function() return P().nameOnlyMode.showInWorld end, set = function(v) P().nameOnlyMode.showInWorld = v; BBM.ApplyNameOnlyMode(true) end },
            { label = "In City",          get = function() return P().nameOnlyMode.showInCity  end, set = function(v) P().nameOnlyMode.showInCity  = v; BBM.ApplyNameOnlyMode(true) end },
            { label = "In PvE",           get = function() return P().nameOnlyMode.showInPvE  end, set = function(v) P().nameOnlyMode.showInPvE   = v; BBM.ApplyNameOnlyMode(true) end },
        },
    }, p)

    BBG.MakeCheckbox({
        label = "Hide Realm Names",
        get   = function() return P().hideRealmNames end,
        set   = function(v) P().hideRealmNames = v; BBM.ApplyHideRealmNames() end,
    }, p)

    BBG.MakeCheckbox({
        label = "Class Color Friendly Names",
        get   = function() return P().classColorNames end,
        set   = function(v) P().classColorNames = v; BBM.ApplyClassColorNames(true) end,
    }, p)

    BBG.MakeCheckbox({
        label = "Moveable Settings Panel",
        desc  = "Drag the Blizzard settings window around by its frame.",
        get   = function() return P().moveableSettingsPanel end,
        set   = function(v) P().moveableSettingsPanel = v; BBM.ApplyMoveableSettingsPanel() end,
    }, p)

    return p
end

local POPUP_NEW           = "BETTERBLIZZMARKERS_NEW_PROFILE"
local POPUP_RENAME        = "BETTERBLIZZMARKERS_RENAME_PROFILE"
local POPUP_DELETE        = "BETTERBLIZZMARKERS_DELETE_PROFILE"
local POPUP_RESET         = "BETTERBLIZZMARKERS_RESET_PROFILE"
local POPUP_IMPORT        = "BETTERBLIZZMARKERS_IMPORT_PROFILE"
local POPUP_SPEC_CONFLICT = "BETTERBLIZZMARKERS_SPEC_CONFLICT"

local COLOR_SPEC    = "|cff40dd40"
local COLOR_GLOBAL  = "|cffffd100"
local COLOR_PROFILE = "|cff00c0ff"

local function SetupProfilePopups(refresh, setSelected)
    local addon = BBM.addon

    local function NameDialog(text, button, onAccept)
        return {
            text         = text,
            button1      = button,
            button2      = CANCEL,
            hasEditBox   = true,
            maxLetters   = 40,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
            OnShow = function(self)
                local editBox = self:GetEditBox()
                if not editBox then return end
                editBox:SetText(self.data and self.data.suggested or "")
                editBox:HighlightText()
                editBox:SetFocus()
            end,
            OnAccept = function(self)
                local name, reason = onAccept(self:GetEditBoxText(), self.data)
                if not name then
                    addon:Message(reason or "Could not create that profile.")
                    return
                end
                setSelected(name)
                refresh()
            end,
            EditBoxOnEnterPressed = function(self)
                local parentFrame = self:GetParent()
                StaticPopup_OnClick(parentFrame, 1)
            end,
            EditBoxOnEscapePressed = function(self)
                self:GetParent():Hide()
            end,
        }
    end

    StaticPopupDialogs[POPUP_NEW] = NameDialog(
        "Name for the new profile:", "Create",
        function(text, data) return BBM.CreateProfile(text, data and data.copyFrom) end)

    StaticPopupDialogs[POPUP_RENAME] = NameDialog(
        "Rename this profile to:", "Rename",
        function(text, data) return BBM.RenameProfile(data.old, text) end)

    StaticPopupDialogs[POPUP_IMPORT] = NameDialog(
        "Import this profile as:", "Import",
        function(text, data)
            if BBM.ProfileExists(BBM.NormalizeProfileName(text) or "") then
                addon:Message(string.format("Overwriting profile \"%s\".", text))
            end
            return BBM.ImportProfile(data.payload, text)
        end)

    StaticPopupDialogs[POPUP_DELETE] = {
        text         = "Delete the profile \"%s\"? This cannot be undone.",
        button1      = DELETE,
        button2      = CANCEL,
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
        showAlert    = true,
        OnAccept = function(self)
            local ok, reason = BBM.DeleteProfile(self.data.name)
            if not ok then addon:Message(reason) end
            refresh()
        end,
    }

    StaticPopupDialogs[POPUP_RESET] = {
        text         = "Reset the profile \"%s\" back to defaults?",
        button1      = RESET,
        button2      = CANCEL,
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
        showAlert    = true,
        OnAccept = function(self)
            local ok, reason = BBM.ResetProfile(self.data.name)
            if not ok then addon:Message(reason) end
            refresh()
        end,
    }

    StaticPopupDialogs[POPUP_SPEC_CONFLICT] = {
        text         = "%s",
        button1      = "Change All",
        button2      = CANCEL,
        button3      = "Only Unassigned",
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
        showAlert    = true,
        OnAccept = function(self)
            BBM.SetSpecProfiles(self.data.specIDs, self.data.target)
            if self.data.dropdown then self.data.dropdown:OpenMenu() end
        end,
        OnAlt = function(self)
            BBM.SetSpecProfiles(self.data.unassigned, self.data.target)
            if self.data.dropdown then self.data.dropdown:OpenMenu() end
        end,
        OnCancel = function(self)
            if self.data.dropdown then self.data.dropdown:OpenMenu() end
        end,
    }
end

local ROLE_COLORS = {
    Tank   = CreateColor(0.31, 0.45, 0.86),
    Healer = CreateColor(0.31, 0.85, 0.34),
    DPS    = CreateColor(0.86, 0.28, 0.28),
}

local function BuildSpecGridClasses()
    local classes = {}
    for i, class in ipairs(BBM.GetClassSpecTree()) do
        classes[i] = class
    end

    local byRole = { Tank = {}, Healer = {}, DPS = {} }
    for _, class in ipairs(classes) do
        for _, spec in ipairs(class.specs) do
            local role = BBM.TankSpecs[spec.id] and "Tank"
                or BBM.HealerSpecs[spec.id] and "Healer"
                or "DPS"
            table.insert(byRole[role], spec)
        end
    end

    for _, role in ipairs({ "Tank", "Healer", "DPS" }) do
        classes[#classes + 1] = {
            name      = role,
            color     = ROLE_COLORS[role],
            specs     = byRole[role],
            hideSpecs = true,
        }
    end

    return classes
end

local function BuildSpecConflictMessage(conflicts, target)
    table.sort(conflicts, function(a, b)
        return (BBM.GetSpecDisplay(a.id) or "") < (BBM.GetSpecDisplay(b.id) or "")
    end)

    local lines = {
        "These specs already have a profile set to them:",
        "",
    }
    for _, conflict in ipairs(conflicts) do
        local name, _, classColor = BBM.GetSpecDisplay(conflict.id)
        local label = (classColor and name) and classColor:WrapTextInColorCode(name) or (name or "Unknown")
        lines[#lines + 1] = string.format("%s: %s", label, conflict.owner)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("Do you want to change these to use \"%s%s|r\"?", COLOR_PROFILE, target)
    return table.concat(lines, "\n")
end

function BBM.GuiProfiles(root)
    local addon = BBM.addon
    local p = BBG.CreateSubPanel(root._category, "BetterBlizzMarkers_Profiles", "Profiles", 620, 780)

    BBG.MakePanelHeader({
        title       = "Profiles",
        iconSize    = 37,
        iconOffsetX = -3,
        iconOffsetY = 2,
        icon        = { atlas = "GM-icon-assistActive" },
    }, p)

    local exportBox, importBox

    local function UsingSpecProfiles()
        return BetterBlizzMarkersDB.autoSwitch and true or false
    end

    local specSelected

    local function SelectedSpecProfile()
        if not specSelected or not BBM.ProfileExists(specSelected) then
            local specID = BBM.GetPlayerSpecID()
            specSelected = (specID and BBM.GetSpecProfile(specID))
                or BBM.ActiveProfileName or "Default"
        end
        return specSelected
    end

    local function TargetProfile()
        if UsingSpecProfiles() then return SelectedSpecProfile() end
        return BetterBlizzMarkersDB.global
    end

    local function RefreshPanel()
        BBG.RefreshPanel(p)
    end

    SetupProfilePopups(RefreshPanel, function(name)
        if UsingSpecProfiles() then
            specSelected = name
        else
            BBM.SetGlobalProfile(name)
        end
    end)

    BBG.MakeTitle("Global Profile", p, { atlas = "GM-icon-assistActive", sizeX = 26, sizeY = 26, offsetX = 2, offsetY = 1 })

    local function StatusText()
        local active = BBM.ActiveProfileName or "Default"
        local specID = BBM.GetPlayerSpecID()
        local kind   = (specID and BBM.GetSpecProfile(specID) and UsingSpecProfiles())
            and (COLOR_SPEC .. "spec|r") or (COLOR_GLOBAL .. "global|r")

        local who = "|cff999999unknown specialization|r"
        if specID then
            local specName, specIcon, classColor = BBM.GetSpecDisplay(specID)
            local hex  = (classColor and classColor.GenerateHexColorMarkup
                and classColor:GenerateHexColorMarkup()) or "|cffffffff"
            local icon = specIcon and string.format("|T%s:18:18:0:0|t ", tostring(specIcon)) or ""
            who = string.format("%s%s%s|r", icon, hex, specName or "Unknown")
        end

        return string.format("%sActive:|r %s is using %s profile: %s%s|r",
            COLOR_SPEC, who, kind, COLOR_PROFILE, active)
    end

    local statusFS = BBG.MakeLabel(StatusText(), p, nil, -2, -7)

    local function RefreshStatus()
        statusFS:SetText(StatusText())
    end

    local globalOptions, specOptions = {}, {}

    local function RebuildProfileOptions()
        wipe(globalOptions)
        wipe(specOptions)
        for i, name in ipairs(BBM.GetProfileNames()) do
            globalOptions[i] = { label = name, value = name }
            specOptions[i]   = { label = name, value = name }
        end
    end
    RebuildProfileOptions()
    table.insert(p._refreshers, RebuildProfileOptions)

    local ROW_LABEL_WIDTH = 300
    local sectionsStartY = BBG.GetCursor(p)

    local globalSection = BBG.MakeSection(p)
    local globalDropdown, globalLabelFS = BBG.MakeDropdown({
        label      = "Global profile selected:",
        labelWidth = ROW_LABEL_WIDTH,
        options    = globalOptions,
        get        = function() return BetterBlizzMarkersDB.global end,
        set        = function(v) BBM.SetGlobalProfile(v); RefreshPanel() end,
    }, globalSection)

    local H_global = BBG.FinaliseSection(globalSection)
    local buttonsSection = BBG.MakeSection(p)

    BBG.MakeButtonRow({
        {
            label = "New",
            func  = function() StaticPopup_Show(POPUP_NEW, nil, nil, { suggested = "" }) end,
            desc  = "Create a new profile",
        },
        {
            label = "Copy",
            func  = function()
                StaticPopup_Show(POPUP_NEW, nil, nil, {
                    suggested = TargetProfile() .. " Copy",
                    copyFrom  = TargetProfile(),
                })
            end,
            desc  = "Copy currently selected profile into a new one",
        },
        {
            label = "Rename",
            func  = function()
                StaticPopup_Show(POPUP_RENAME, nil, nil, {
                    suggested = TargetProfile(),
                    old       = TargetProfile(),
                })
            end,
            desc    = "Rename currently selected profile",
            enabled = function() return TargetProfile() ~= "Default" end,
        },
        {
            label = "Delete",
            func  = function()
                StaticPopup_Show(POPUP_DELETE, TargetProfile(), nil, { name = TargetProfile() })
            end,
            desc    = "Delete currently selected profile",
            enabled = function() return TargetProfile() ~= "Default" end,
        },
        {
            label = "Reset",
            func  = function()
                StaticPopup_Show(POPUP_RESET, TargetProfile(), nil, { name = TargetProfile() })
            end,
            desc  = "Reset currently selected profile to defaults",
        },
    }, buttonsSection, { xOffset = -3, yOffset = -7 })
    local H_buttons = BBG.FinaliseSection(buttonsSection)

    local specSection = BBG.MakeSection(p)
    BBG.MakeTitle("Spec Profiles", specSection, { atlas = "OptionsIcon-Brown", sizeX = 17, sizeY = 17, offsetX = -1.5, offsetY = 0.5 })

    BBG.MakeCheckbox({
        label = "Use Spec Profiles",
        get   = function() return BetterBlizzMarkersDB.autoSwitch end,
        set   = function(v)
            BetterBlizzMarkersDB.autoSwitch = v
            BBM.RefreshActiveProfile()
            RefreshPanel()
        end,
    }, specSection)

    local function RefreshGlobalRow()
        local usingSpecs = BetterBlizzMarkersDB.autoSwitch
        globalLabelFS:SetText(usingSpecs and "Global fallback profile selected:" or "Global profile selected:")
        local alpha = usingSpecs and 0.65 or 1.0
        globalLabelFS:SetAlpha(alpha)
        globalDropdown:SetAlpha(alpha)
    end
    RefreshGlobalRow()
    table.insert(p._refreshers, RefreshGlobalRow)

    local specPickerDropdown, specPickerLabelFS = BBG.MakeDropdown({
        label      = "Select a spec profile:",
        labelWidth = ROW_LABEL_WIDTH,
        options    = specOptions,
        get        = SelectedSpecProfile,
        set        = function(v) specSelected = v; RefreshPanel() end,
    }, specSection)

    local specGridDropdown, specGridLabelFS
    specGridDropdown, specGridLabelFS = BBG.MakeSpecGridDropdown({
        label           = "Enable selected profile for specs:",
        labelWidth      = ROW_LABEL_WIDTH,
        textNone        = "No specs",
        classes         = BuildSpecGridClasses(),
        playerSpecID    = BBM.GetPlayerSpecID,
        selectedProfile = SelectedSpecProfile,
        getSpec         = function(specID) return BBM.GetSpecProfile(specID) == SelectedSpecProfile() end,
        setSpec      = function(specID, on)
            BBM.SetSpecProfile(specID, on and SelectedSpecProfile() or nil)
        end,
        setSpecs     = function(specIDs, on)
            local target = SelectedSpecProfile()

            if not on then
                local owned = {}
                for _, specID in ipairs(specIDs) do
                    if BBM.GetSpecProfile(specID) == target then
                        owned[#owned + 1] = specID
                    end
                end
                BBM.SetSpecProfiles(owned, nil)
                return
            end

            local conflicts = {}
            for _, specID in ipairs(specIDs) do
                local owner = BBM.GetSpecProfile(specID)
                if owner and owner ~= target then
                    conflicts[#conflicts + 1] = { id = specID, owner = owner }
                end
            end

            if #conflicts == 0 then
                BBM.SetSpecProfiles(specIDs, target)
                return
            end

            local unassigned = {}
            for _, specID in ipairs(specIDs) do
                if not BBM.GetSpecProfile(specID) then
                    unassigned[#unassigned + 1] = specID
                end
            end

            specGridDropdown:CloseMenu()
            StaticPopup_Show(POPUP_SPEC_CONFLICT, BuildSpecConflictMessage(conflicts, target), nil, {
                specIDs    = specIDs,
                unassigned = unassigned,
                target     = target,
                dropdown   = specGridDropdown,
            })
        end,
        getSpecOwner = function(specID)
            local owner = BBM.GetSpecProfile(specID)
            if owner and owner ~= SelectedSpecProfile() then return owner end
        end,
    }, specSection)

    local function RefreshSpecSection()
        specGridLabelFS:SetText(string.format("Enable selected profile %s%s|r for specs:",
            COLOR_PROFILE, SelectedSpecProfile()))

        local on = BetterBlizzMarkersDB.autoSwitch
        local function SetRowEnabled(dropdown, labelFS)
            if dropdown then
                if on then dropdown:Enable() else dropdown:Disable() end
                dropdown:SetAlpha(on and 1.0 or 0.4)
            end
            if labelFS then
                labelFS:SetTextColor(on and 1 or 0.5, on and 1 or 0.5, on and 1 or 0.5)
                labelFS:SetAlpha(on and 1 or 0.6)
            end
        end
        SetRowEnabled(specPickerDropdown, specPickerLabelFS)
        SetRowEnabled(specGridDropdown, specGridLabelFS)
    end
    RefreshSpecSection()
    table.insert(p._refreshers, RefreshSpecSection)

    local H_spec = BBG.FinaliseSection(specSection)

    local shareSection = BBG.MakeSection(p)
    BBG.MakeTitle("Share", shareSection, { atlas = "GM-icon-headCount", sizeX = 17, sizeY = 17, offsetX = -2, offsetY = 1 })

    exportBox = BBG.MakeTextArea({
        label       = "Export, then copy the string with Ctrl+C",
        height      = 66,
        readOnly    = true,
        buttonLabel = "Export",
        buttonFunc  = function(handle)
            local str, reason = BBM.ExportProfile(TargetProfile())
            if not str then
                addon:Message(reason)
                return
            end
            handle:SetText(str)
            handle:SelectAll()
        end,
    }, shareSection)

    importBox = BBG.MakeTextArea({
        label       = "Import: paste a profile string with Ctrl+V",
        height      = 66,
        labelGap    = 9,
        boxGap      = 12,
        buttonLabel = "Import",
        buttonFunc  = function(handle)
            local payload, reason = BBM.DecodeProfileString(handle:GetText())
            if not payload then
                addon:Message(reason)
                return
            end
            StaticPopup_Show(POPUP_IMPORT, nil, nil, {
                suggested = payload.name or "Imported",
                payload   = payload,
            })
        end,
    }, shareSection)
    BBG.FinaliseSection(shareSection)

    local function RefreshButtonPosition()
        local useSpecs = BetterBlizzMarkersDB.autoSwitch

        local afterGlobalY = sectionsStartY - H_global

        if useSpecs then
            specSection:ClearAllPoints()
            specSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY)
            buttonsSection:ClearAllPoints()
            buttonsSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY - H_spec)
            shareSection:ClearAllPoints()
            shareSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY - H_spec - H_buttons)
        else
            buttonsSection:ClearAllPoints()
            buttonsSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY)
            specSection:ClearAllPoints()
            specSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY - H_buttons)
            shareSection:ClearAllPoints()
            shareSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, afterGlobalY - H_buttons - H_spec)
        end
    end
    p._layoutRefresh = RefreshButtonPosition
    RefreshButtonPosition()

    local lastExported = TargetProfile()
    table.insert(p._refreshers, function()
        if TargetProfile() ~= lastExported then
            lastExported = TargetProfile()
            exportBox:Clear()
            importBox:Clear()
        end
        RefreshStatus()
    end)

    return p
end

function BBM.GuiArenaNames(root)
    local addon = BBM.addon
    local p       = BBG.CreateSubPanel(root._category, "BetterBlizzMarkers_ArenaNames", "Arena Names", 620, 800)

    local function P() return addon.db.profile.arenaNames end
    local RefreshLayout

    BBG.MakePanelHeader({
        title       = "Arena Names",
        iconSize    = 30,
        iconOffsetX = 0,
        iconOffsetY = 1,
        icon        = { atlas = "services-number-1" },
    }, p)
    MakeTestModeButton(p, "arenaNames", "arena names")

    local anchorOptions = {
        { label = "Top Left",    value = "TOPLEFT"    }, { label = "Top",    value = "TOP"    },
        { label = "Top Right",   value = "TOPRIGHT"   }, { label = "Left",   value = "LEFT"   },
        { label = "Center",      value = "CENTER"     }, { label = "Right",  value = "RIGHT"  },
        { label = "Bottom Left", value = "BOTTOMLEFT" }, { label = "Bottom", value = "BOTTOM" },
        { label = "Bottom Right",value = "BOTTOMRIGHT"},
    }
    local anchorToOptions = {
        { label = "Spec and Name (Text)", value = "specName"  },
        { label = "Nameplate",     value = "nameplate" },
    }
    local namesModeOptions = {
        { label = "Replace original name.",                            value = "adapt"   },
        { label = "Create new customisable text. Hide original name.", value = "replace" },
        { label = "Create new customisable text. Keep original name.", value = "add"     },
    }

    BBG.MakeTitle("Visibility", p, { atlas = "GM-icon-visible-hover", sizeX = 33, sizeY = 33, offsetX = 6 })
    BBG.MakeCheckbox({
        label = "Enable Arena Names",
        get   = function() return P().enabled end,
        set   = function(v) P().enabled = v; addon:RefreshAll() end,
    }, p)
    BBG.MakeLargeCheckDropdown({
        label = "Show Arena Names on:",
        options = {
            { label = "Enemy Nameplates",    get = function() return P().showOnEnemy    end, set = function(v) P().showOnEnemy    = v; addon:RefreshAll(); RefreshLayout() end },
            { label = "Friendly Nameplates", get = function() return P().showOnFriendly end, set = function(v) P().showOnFriendly = v; addon:RefreshAll(); RefreshLayout() end },
        },
    }, p)

    BBG.MakeTitle("Tweaks", p, { atlas = "worldquest-tracker-questmarker", sizeX = 17, sizeY = 17, offsetX = -2, offsetY = 1 })
    BBG.MakeCheckbox({
        label = "Abbreviate Spec Names",
        get   = function() return P().abbreviateSpec end,
        set   = function(v) P().abbreviateSpec = v; addon:RefreshAll() end,
    }, p)
    BBG.MakeCheckbox({
        label = "Class Color Arena Names",
        get   = function() return P().classColorArenaNames end,
        set   = function(v) P().classColorArenaNames = v; addon:RefreshAll() end,
    }, p)
    BBG.MakeDropdown({
        label   = "Arena Names Mode:",
        options = namesModeOptions,
        get     = function() return P().namesMode end,
        set     = function(v) P().namesMode = v; addon:RefreshAll(); RefreshLayout() end,
    }, p)

    local startY = BBG.GetCursor(p)

    local enemySection = BBG.MakeSection(p)
    BBG.MakeLargeCheckDropdown({
        label = "For Enemy Nameplates show:",
        options = {
            { label = "Arena ID", get = function() return P().enemyShowArenaID end, set = function(v) P().enemyShowArenaID = v; addon:RefreshAll() end },
            { label = "Spec",     get = function() return P().enemyShowSpec    end, set = function(v) P().enemyShowSpec    = v; addon:RefreshAll() end },
            { label = "Name",     get = function() return P().enemyShowName    end, set = function(v) P().enemyShowName    = v; addon:RefreshAll() end },
        },
    }, enemySection)
    local H_enemy = BBG.FinaliseSection(enemySection)
    BBG.SetCursor(p, startY - H_enemy)

    local friendlySection = BBG.MakeSection(p)
    BBG.MakeLargeCheckDropdown({
        label = "For Friendly Nameplates show:",
        options = {
            { label = "Arena ID", get = function() return P().friendlyShowArenaID end, set = function(v) P().friendlyShowArenaID = v; addon:RefreshAll() end },
            { label = "Spec",     get = function() return P().friendlyShowSpec    end, set = function(v) P().friendlyShowSpec    = v; addon:RefreshAll() end },
            { label = "Name",     get = function() return P().friendlyShowName    end, set = function(v) P().friendlyShowName    = v; addon:RefreshAll() end },
        },
    }, friendlySection)
    local H_friendly = BBG.FinaliseSection(friendlySection)
    BBG.SetCursor(p, startY - H_enemy - H_friendly)

    local posSection = BBG.MakeSection(p)
    BBG.MakeTitle("Font, Size & Position", posSection, { atlas = "OptionsIcon-Brown", sizeX = 17, sizeY = 17, offsetX = -1.5, offsetY = 0.5 })

    if BBM.LSM then
        local fontItems = { { label = "Default", value = "" } }
        for _, name in ipairs(BBM.LSM:List("font")) do
            fontItems[#fontItems + 1] = { label = name, value = name, previewFont = BBM.LSM:Fetch("font", name) }
        end

        BBG.MakeFontDropdown({
            label = "Font:",
            items = fontItems,
            get   = function() return P().fontKey end,
            set   = function(v) P().fontKey = v; addon:RefreshAll() end,
        }, posSection)
    end

    local specNameGroup = BBG.MakeSubTitleGroup("Spec & Name", posSection, {0.4, 0.8, 1.0})
    BBG.MakeSlider({ label = "Size", min = 9, max = 40, step = 1,
        get = function() return P().specNameFontSize end,
        set = function(v) P().specNameFontSize = v; addon:RefreshAll() end }, posSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().specNameXPos end,
        set = function(v) P().specNameXPos = v; addon:RefreshAll() end }, posSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().specNameYPos end,
        set = function(v) P().specNameYPos = v; addon:RefreshAll() end }, posSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().specNameAnchor end,
        set = function(v) P().specNameAnchor = v; addon:RefreshAll() end }, posSection)
    BBG.FinaliseSubTitleGroup(specNameGroup)

    local arenaIDGroup = BBG.MakeSubTitleGroup("Arena ID", posSection, {1.0, 0.85, 0.0})
    BBG.MakeSlider({ label = "Size", min = 9, max = 40, step = 1,
        get = function() return P().arenaIDFontSize end,
        set = function(v) P().arenaIDFontSize = v; addon:RefreshAll() end }, posSection)
    BBG.MakeSlider({ label = "Horizontal Position", min = -150, max = 150, step = 1,
        get = function() return P().arenaIDXPos end,
        set = function(v) P().arenaIDXPos = v; addon:RefreshAll() end }, posSection)
    BBG.MakeSlider({ label = "Vertical Position", min = -150, max = 150, step = 1,
        get = function() return P().arenaIDYPos end,
        set = function(v) P().arenaIDYPos = v; addon:RefreshAll() end }, posSection)
    BBG.MakeDropdown({ label = "Anchor", options = anchorOptions,
        get = function() return P().arenaIDAnchor end,
        set = function(v) P().arenaIDAnchor = v; addon:RefreshAll() end }, posSection)
    BBG.MakeDropdown({ label = "Anchor To:", options = anchorToOptions,
        get = function() return P().arenaIDAnchorTo end,
        set = function(v) P().arenaIDAnchorTo = v; addon:RefreshAll() end }, posSection)
    BBG.FinaliseSubTitleGroup(arenaIDGroup)

    BBG.FinaliseSection(posSection)

    function RefreshLayout()
        local showE = P().showOnEnemy
        local showF = P().showOnFriendly

        enemySection:SetShown(showE)

        local friendlyY = startY
        if showE then friendlyY = friendlyY - H_enemy end
        friendlySection:ClearAllPoints()
        friendlySection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, friendlyY)
        friendlySection:SetShown(showF)

        local posY = friendlyY
        if showF then posY = posY - H_friendly end
        posSection:ClearAllPoints()
        posSection:SetPoint("TOPLEFT", p, "TOPLEFT", 0, posY)
        posSection:SetShown(P().namesMode == "add" or P().namesMode == "replace")
    end
    p._layoutRefresh = RefreshLayout

    RefreshLayout()

    return p
end

function BBM.BuildBBGPanel()
    local addon = BBM.addon
    local root = BBG.CreatePanel("BetterBlizzMarkers", BBM.addonNameLogo, 620, 470)

    BBM.GuiGeneral(root)

    root.subPanels = {
        arena    = BBM.GuiArenaNames(root),
        class    = BBM.GuiClassIcons(root),
        totem    = BBM.GuiTotemIcons(root),
        misc     = BBM.GuiMisc(root),
        profiles = BBM.GuiProfiles(root),
    }

    local pageTestKeys = {
        [root.subPanels.class] = "classIcons",
        [root.subPanels.totem] = "totemIcons",
        [root.subPanels.arena] = "arenaNames",
    }

    local function HookPage(panel)
        local canvas = panel and panel._canvas
        if not canvas then return end
        canvas:HookScript("OnShow", function()
            BBM.OnSettingsPageShown(pageTestKeys[panel])
        end)
    end

    HookPage(root)
    for _, panel in pairs(root.subPanels) do HookPage(panel) end

    if SettingsPanel then
        SettingsPanel:HookScript("OnHide", BBM.ClearTestModes)
    end

    addon.bbgPanel = root
end

function BBM.RefreshGUI()
    local root = BBM.addon.bbgPanel
    if not root then return end

    BBG.RefreshPanel(root)
    for _, tint in ipairs(BBM.totemPreviewTints) do tint() end

    for _, panel in pairs(root.subPanels or {}) do
        BBG.RefreshPanel(panel)
    end
end

function BBM.RefreshProfilesPanel()
    local root = BBM.addon.bbgPanel
    if not root or not root.subPanels then return end
    BBG.RefreshPanel(root.subPanels.profiles)
end
