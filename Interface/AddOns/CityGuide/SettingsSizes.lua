-- Size Settings Section

local function CreateSlider(parent, name, minVal, maxVal, step, xOffset, yOffset, width)
    width = width or 200
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(width)
    
    _G[name.."Low"]:SetText(minVal)
    _G[name.."High"]:SetText(maxVal)
    
    return slider
end

function CityGuideSettings_LoadSizesSection()
    local scrollChild = CityGuideSettings.scrollChild
    
    local sizesSection = CreateFrame("Frame", nil, scrollChild)
    sizesSection:SetPoint("TOPLEFT", 20, -20)
    sizesSection:SetPoint("TOPRIGHT", -20, -20)
    sizesSection:SetHeight(500)
    CityGuideSettings.contentSections["sizes"] = sizesSection
    
    -- Section title with icon
    local titleContainer = CreateFrame("Frame", nil, sizesSection, "BackdropTemplate")
    titleContainer:SetSize(380, 50)
    titleContainer:SetPoint("TOPLEFT", 0, 0)
    titleContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    titleContainer:SetBackdropColor(0, 0, 0, 0.5)
    titleContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local titleIcon = titleContainer:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(32, 32)
    titleIcon:SetPoint("LEFT", titleContainer, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\Icons\\Ability_Warrior_ShieldMastery")
    
    local sizesTitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sizesTitle:SetPoint("LEFT", titleIcon, "RIGHT", 10, 0)
    sizesTitle:SetText("Global Size Settings")
    sizesTitle:SetTextColor(1, 0.9, 0.5)
    
    local sizesDesc = sizesSection:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sizesDesc:SetPoint("TOPLEFT", titleContainer, "BOTTOMLEFT", 0, -10)
    sizesDesc:SetText("Adjust the base size for all cities (can be overridden per-city)")
    sizesDesc:SetTextColor(0.7, 0.7, 0.7)
    sizesDesc:SetWidth(360)
    sizesDesc:SetJustifyH("LEFT")
    
    -- Label Size Container
    local labelSizeContainer = CreateFrame("Frame", nil, sizesSection, "BackdropTemplate")
    labelSizeContainer:SetSize(380, 120)
    labelSizeContainer:SetPoint("TOPLEFT", sizesDesc, "BOTTOMLEFT", 0, -20)
    labelSizeContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    labelSizeContainer:SetBackdropColor(0, 0, 0, 0.4)
    labelSizeContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local labelSizeTitle = labelSizeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelSizeTitle:SetPoint("TOPLEFT", labelSizeContainer, "TOPLEFT", 15, -15)
    labelSizeTitle:SetText("Label Size (Global)")
    labelSizeTitle:SetTextColor(0.8, 0.9, 1)
    
    local labelSizeSlider = CreateSlider(labelSizeContainer, "CityGuideLabelSizeSlider", 0.5, 2.0, 0.1, 15, -50, 340)
    _G["CityGuideLabelSizeSliderText"]:Hide()
    
    local labelSizeValue = labelSizeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    labelSizeValue:SetPoint("TOP", labelSizeSlider, "BOTTOM", 0, -5)
    labelSizeValue:SetText("1.0x")
    labelSizeValue:SetTextColor(1, 1, 0.5)
    
    labelSizeSlider:SetScript("OnValueChanged", function(self, value)
        CityGuideConfig.labelSize = value
        labelSizeValue:SetText(string.format("%.1fx", value))
        CityGuide_UpdateMapLabels()
    end)
    
    -- Icon Size Container
    local iconSizeContainer = CreateFrame("Frame", nil, sizesSection, "BackdropTemplate")
    iconSizeContainer:SetSize(380, 120)
    iconSizeContainer:SetPoint("TOPLEFT", labelSizeContainer, "BOTTOMLEFT", 0, -15)
    iconSizeContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    iconSizeContainer:SetBackdropColor(0, 0, 0, 0.4)
    iconSizeContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local iconSizeTitle = iconSizeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    iconSizeTitle:SetPoint("TOPLEFT", iconSizeContainer, "TOPLEFT", 15, -15)
    iconSizeTitle:SetText("Icon Size (Global)")
    iconSizeTitle:SetTextColor(0.8, 0.9, 1)
    
    local iconSizeSlider = CreateSlider(iconSizeContainer, "CityGuideIconSizeSlider", 0.5, 2.0, 0.1, 15, -50, 340)
    _G["CityGuideIconSizeSliderText"]:Hide()
    
    local iconSizeValue = iconSizeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconSizeValue:SetPoint("TOP", iconSizeSlider, "BOTTOM", 0, -5)
    iconSizeValue:SetText("1.0x")
    iconSizeValue:SetTextColor(1, 1, 0.5)
    
    iconSizeSlider:SetScript("OnValueChanged", function(self, value)
        CityGuideConfig.iconSize = value
        iconSizeValue:SetText(string.format("%.1fx", value))
        CityGuide_UpdateMapLabels()
    end)
    
    -- Reset All Sizes Button
    local resetButton = CreateFrame("Button", nil, sizesSection, "UIPanelButtonTemplate")
    resetButton:SetSize(200, 40)
    resetButton:SetPoint("TOP", iconSizeContainer, "BOTTOM", 0, -30)
    resetButton:SetText("Reset All Sizes")
    resetButton:SetNormalFontObject("GameFontNormalLarge")
    
    -- Button glow effect
    local btnGlow = resetButton:CreateTexture(nil, "BACKGROUND")
    btnGlow:SetPoint("CENTER")
    btnGlow:SetSize(220, 50)
    btnGlow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
    btnGlow:SetBlendMode("ADD")
    btnGlow:SetVertexColor(1, 0.5, 0.2, 0)
    resetButton.glow = btnGlow
    
    resetButton:SetScript("OnEnter", function(self)
        self.glow:SetAlpha(0.3)
    end)
    
    resetButton:SetScript("OnLeave", function(self)
        self.glow:SetAlpha(0)
    end)
    
resetButton:SetScript("OnClick", function(self)
    -- ONLY reset sizes - nothing else!
    CityGuideConfig.labelSize = 1.0
    CityGuideConfig.iconSize = 1.0
    CityGuideConfig.cityIconSizes = {}
    CityGuideConfig.cityLabelSizes = {}
    -- DO NOT TOUCH: condenseProfessions, filters, enabled cities, etc.

    -- Update global sliders
    labelSizeSlider:SetValue(1.0)
    iconSizeSlider:SetValue(1.0)
    labelSizeValue:SetText("1.0x")
    iconSizeValue:SetText("1.0x")

    -- Update per-city sliders if they exist
    if CityGuideSettings and CityGuideSettings.contentSections then
        for _, mapID in ipairs(CityGuide_GetCityOrder()) do
            local citySection = CityGuideSettings.contentSections["city_" .. mapID]
            if citySection then
                if citySection.iconSlider then
                    citySection.iconSlider:SetValue(1.0)
                    if citySection.iconValue then
                        citySection.iconValue:SetText("1.0x")
                    end
                end
                if citySection.labelSlider then
                    citySection.labelSlider:SetValue(1.0)
                    if citySection.labelValue then
                        citySection.labelValue:SetText("1.0x")
                    end
                end
            end
        end
    end

    CityGuide_UpdateMapLabels()

    -- Success message
    print("|cff00ff00City Guide:|r All sizes reset to 1.0x (default)")

    -- Visual feedback: flash the glow
    local flash = self:CreateAnimationGroup()
    local alpha1 = flash:CreateAnimation("Alpha")
    alpha1:SetTarget(self.glow)
    alpha1:SetFromAlpha(0)
    alpha1:SetToAlpha(0.8)
    alpha1:SetDuration(0.15)

    local alpha2 = flash:CreateAnimation("Alpha")
    alpha2:SetTarget(self.glow)
    alpha2:SetFromAlpha(0.8)
    alpha2:SetToAlpha(0)
    alpha2:SetDuration(0.3)
    alpha2:SetStartDelay(0.15)

    flash:Play()

    -- SAFE text color pulse (no SetNormalFontObject)
    local text = self:GetFontString()
    if text then
        local originalFont = text:GetFontObject()
        text:SetFontObject(GameFontNormalLargeGreen)

        C_Timer.After(0.5, function()
            if text and originalFont then
                text:SetFontObject(originalFont)
            end
        end)
    end
end)
    
    -- Store references
    sizesSection.labelSizeSlider = labelSizeSlider
    sizesSection.labelSizeValue = labelSizeValue
    sizesSection.iconSizeSlider = iconSizeSlider
    sizesSection.iconSizeValue = iconSizeValue
end

function CityGuideSettings_UpdateSizesSection()
    local section = CityGuideSettings.contentSections and CityGuideSettings.contentSections["sizes"]
    if not section then return end
    
    section.labelSizeSlider:SetValue(CityGuideConfig.labelSize or 1.0)
    section.iconSizeSlider:SetValue(CityGuideConfig.iconSize or 1.0)
    section.labelSizeValue:SetText(string.format("%.1fx", CityGuideConfig.labelSize or 1.0))
    section.iconSizeValue:SetText(string.format("%.1fx", CityGuideConfig.iconSize or 1.0))
end