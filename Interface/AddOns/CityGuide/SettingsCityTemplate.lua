-- Per-City Settings Template
-- This file creates city-specific settings dynamically

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

function CityGuideSettings_LoadCitySection(mapID)
    local scrollChild = CityGuideSettings.scrollChild
    local mapNames = CityGuide_GetCityNames()
    local allowCondensation = CityGuide_GetCityAllowsProfessionCondensation()
    local cityName = mapNames[mapID]
    local cityThemes = CityGuideSettings.cityThemes
    local theme = cityThemes[mapID]
    
    -- Create city section
    local citySection = CreateFrame("Frame", nil, scrollChild)
    citySection:SetPoint("TOPLEFT", 20, -20)
    citySection:SetPoint("TOPRIGHT", -20, -20)
    citySection:SetHeight(600)
    CityGuideSettings.contentSections["city_"..mapID] = citySection
    
    -- Section title with city-specific styling
    local titleContainer = CreateFrame("Frame", nil, citySection, "BackdropTemplate")
    titleContainer:SetSize(380, 60)
    titleContainer:SetPoint("TOPLEFT", 0, 0)
    titleContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    titleContainer:SetBackdropColor(0, 0, 0, 0.5)
    titleContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- City-specific icon
    local titleIcon = titleContainer:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(40, 40)
    titleIcon:SetPoint("LEFT", titleContainer, "LEFT", 10, 0)
    titleIcon:SetTexture(theme and theme.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    local cityTitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    cityTitle:SetPoint("LEFT", titleIcon, "RIGHT", 15, 5)
    cityTitle:SetText(cityName)
    cityTitle:SetTextColor(1, 0.9, 0.5)
    
    local citySubtitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    citySubtitle:SetPoint("LEFT", titleIcon, "RIGHT", 15, -12)
    citySubtitle:SetText("City-Specific Settings")
    citySubtitle:SetTextColor(0.7, 0.7, 0.7)
    
    local yOffset = -80
    
    -- Icon Size Container
    local iconSizeContainer = CreateFrame("Frame", nil, citySection, "BackdropTemplate")
    iconSizeContainer:SetSize(380, 120)
    iconSizeContainer:SetPoint("TOPLEFT", 0, yOffset)
    iconSizeContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    iconSizeContainer:SetBackdropColor(0, 0, 0, 0.4)
    iconSizeContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local iconLabel = iconSizeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    iconLabel:SetPoint("TOPLEFT", iconSizeContainer, "TOPLEFT", 15, -15)
    iconLabel:SetText("Icon Size")
    iconLabel:SetTextColor(0.8, 0.9, 1)
    
    local iconSlider = CreateSlider(iconSizeContainer, "CityGuide"..cityName:gsub("[^%w]", "").."IconSlider", 0.5, 2.0, 0.1, 15, -50, 340)
    _G["CityGuide"..cityName:gsub("[^%w]", "").."IconSliderText"]:Hide()
    
    local iconValue = iconSizeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconValue:SetPoint("TOP", iconSlider, "BOTTOM", 0, -5)
    iconValue:SetText("1.0x")
    iconValue:SetTextColor(1, 1, 0.5)
    
    iconSlider:SetScript("OnValueChanged", function(self, value)
        CityGuideConfig.cityIconSizes[mapID] = value
        iconValue:SetText(string.format("%.1fx", value))
        CityGuide_UpdateMapLabels()
    end)
    
    yOffset = yOffset - 135
    
    -- Label Size Container
    local labelSizeContainer = CreateFrame("Frame", nil, citySection, "BackdropTemplate")
    labelSizeContainer:SetSize(380, 120)
    labelSizeContainer:SetPoint("TOPLEFT", 0, yOffset)
    labelSizeContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    labelSizeContainer:SetBackdropColor(0.05, 0.1, 0.15, 0.6)
    labelSizeContainer:SetBackdropBorderColor(0.3, 0.4, 0.5, 0.8)
    
    local labelLabel = labelSizeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelLabel:SetPoint("TOPLEFT", labelSizeContainer, "TOPLEFT", 15, -15)
    labelLabel:SetText("Label Size")
    labelLabel:SetTextColor(0.8, 0.9, 1)
    
    local labelSlider = CreateSlider(labelSizeContainer, "CityGuide"..cityName:gsub("[^%w]", "").."LabelSlider", 0.5, 2.0, 0.1, 15, -50, 340)
    _G["CityGuide"..cityName:gsub("[^%w]", "").."LabelSliderText"]:Hide()
    
    local labelValue = labelSizeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    labelValue:SetPoint("TOP", labelSlider, "BOTTOM", 0, -5)
    labelValue:SetText("1.0x")
    labelValue:SetTextColor(1, 1, 0.5)
    
    labelSlider:SetScript("OnValueChanged", function(self, value)
        CityGuideConfig.cityLabelSizes = CityGuideConfig.cityLabelSizes or {}
        CityGuideConfig.cityLabelSizes[mapID] = value
        labelValue:SetText(string.format("%.1fx", value))
        CityGuide_UpdateMapLabels()
    end)
    
    yOffset = yOffset - 135
    
    -- City-specific options (only show header if there are options)
    local hasOptions = allowCondensation[mapID] or mapID == 2393
    
    local optionsTitle, profCheckbox, factionOnlyCheckbox
    
    if hasOptions then
        optionsTitle = citySection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        optionsTitle:SetPoint("TOPLEFT", 0, yOffset)
        optionsTitle:SetText("City Options")
        optionsTitle:SetTextColor(0.8, 0.9, 1)
        
        yOffset = yOffset - 30
    end
    
    local profCheckbox, factionOnlyCheckbox
    
    -- Condense Profession Tables Checkbox (if applicable)
    if allowCondensation[mapID] then
        profCheckbox = CreateFrame("CheckButton", nil, citySection, "UICheckButtonTemplate")
        profCheckbox:SetPoint("TOPLEFT", 20, yOffset)
        
        local profLabel = profCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        profLabel:SetPoint("LEFT", profCheckbox, "RIGHT", 5, 0)
        profLabel:SetText("Condense Profession Tables")
        
        profCheckbox.mapID = mapID
        profCheckbox:SetScript("OnClick", function(self)
            CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
            CityGuideConfig.condenseProfessions[self.mapID] = self:GetChecked()
            CityGuide_UpdateMapLabels()
        end)
        
        profCheckbox:SetScript("OnEnter", function(self)
            profLabel:SetTextColor(1, 1, 0.5)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Condense Profession Tables")
            GameTooltip:AddLine("Groups all profession trainers into a single 'Profession Tables' label", 1, 1, 1, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Note: Overridden by 'Filter My Professions'", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        
        profCheckbox:SetScript("OnLeave", function(self)
            profLabel:SetTextColor(1, 1, 1)
            GameTooltip:Hide()
        end)
        
        yOffset = yOffset - 40
    end
    
    -- Faction POIs Only (Silvermoon specific)
    if mapID == 2393 then
        factionOnlyCheckbox = CreateFrame("CheckButton", nil, citySection, "UICheckButtonTemplate")
        factionOnlyCheckbox:SetPoint("TOPLEFT", 20, yOffset)
        
        local factionLabel = factionOnlyCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        factionLabel:SetPoint("LEFT", factionOnlyCheckbox, "RIGHT", 5, 0)
        factionLabel:SetText("Faction POIs Only Mode")
        
        factionOnlyCheckbox.mapID = mapID
        factionOnlyCheckbox:SetScript("OnClick", function(self)
            CityGuideConfig.factionPOIsOnly = CityGuideConfig.factionPOIsOnly or {}
            CityGuideConfig.factionPOIsOnly[self.mapID] = self:GetChecked()
            CityGuide_UpdateMapLabels()
        end)
        
        factionOnlyCheckbox:SetScript("OnEnter", function(self)
            factionLabel:SetTextColor(1, 1, 0.5)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Faction POIs Only Mode")
            
            if not CityGuideConfig.showFactionPOIs then
                GameTooltip:AddLine("|cffff0000Requires 'Show faction-specific POIs' enabled|r", 1, 1, 1, true)
            else
                GameTooltip:AddLine("Shows your faction's POIs, intelligently hiding duplicates", 1, 1, 1, true)
                local playerFaction = CityGuide_GetPlayerFaction()
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("Your faction: |cff00ff00" .. playerFaction .. "|r", 0.8, 0.8, 0.8)
            end
            
            GameTooltip:Show()
        end)
        
        factionOnlyCheckbox:SetScript("OnLeave", function(self)
            factionLabel:SetTextColor(1, 1, 1)
            GameTooltip:Hide()
        end)
    end
    
    -- Store references
    citySection.iconSlider = iconSlider
    citySection.iconValue = iconValue
    citySection.labelSlider = labelSlider
    citySection.labelValue = labelValue
    citySection.profCheckbox = profCheckbox
    citySection.factionOnlyCheckbox = factionOnlyCheckbox
    citySection.mapID = mapID
    
    -- Create update function for this city
    _G["CityGuideSettings_UpdateCitySection_"..mapID] = function()
        local section = CityGuideSettings.contentSections["city_"..mapID]
        if not section then return end
        
        local citySize = CityGuideConfig.cityIconSizes[mapID] or 1.0
        section.iconSlider:SetValue(citySize)
        section.iconValue:SetText(string.format("%.1fx", citySize))
        
        local labelSize = CityGuideConfig.cityLabelSizes[mapID] or 1.0
        section.labelSlider:SetValue(labelSize)
        section.labelValue:SetText(string.format("%.1fx", labelSize))
        
        if section.profCheckbox then
            CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
            local defaultCondensation = CityGuide_GetCityDefaultCondensation()
            if CityGuideConfig.condenseProfessions[mapID] == nil then
                CityGuideConfig.condenseProfessions[mapID] = defaultCondensation[mapID] or false
            end
            section.profCheckbox:SetChecked(CityGuideConfig.condenseProfessions[mapID])
        end
        
        if section.factionOnlyCheckbox then
            CityGuideConfig.factionPOIsOnly = CityGuideConfig.factionPOIsOnly or {}
            section.factionOnlyCheckbox:SetChecked(CityGuideConfig.factionPOIsOnly[mapID] or false)
            
            if CityGuideConfig.showFactionPOIs then
                section.factionOnlyCheckbox:Enable()
            else
                section.factionOnlyCheckbox:Disable()
                section.factionOnlyCheckbox:SetChecked(false)
                CityGuideConfig.factionPOIsOnly[mapID] = false
            end
        end
    end
end