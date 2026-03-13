-- General Settings Section

function CityGuideSettings_LoadGeneralSection()
    local scrollChild = CityGuideSettings.scrollChild
    
    -- Create general section
    local generalSection = CreateFrame("Frame", nil, scrollChild)
    generalSection:SetPoint("TOPLEFT", 20, -20)
    generalSection:SetPoint("TOPRIGHT", -20, -20)
    generalSection:SetHeight(700)
    CityGuideSettings.contentSections["general"] = generalSection
    
    -- Section title with icon
    local titleContainer = CreateFrame("Frame", nil, generalSection, "BackdropTemplate")
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
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    
    local generalTitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalTitle:SetPoint("LEFT", titleIcon, "RIGHT", 10, 0)
    generalTitle:SetText("General Settings")
    generalTitle:SetTextColor(1, 0.9, 0.5)
    
    -- Show Map Widget Container (expanded to fit waypoint checkbox)
    local widgetContainer = CreateFrame("Frame", nil, generalSection, "BackdropTemplate")
    widgetContainer:SetSize(380, 135)
    widgetContainer:SetPoint("TOPLEFT", titleContainer, "BOTTOMLEFT", 0, -20)
    widgetContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    widgetContainer:SetBackdropColor(0, 0, 0, 0.4)
    widgetContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local widgetTitle = widgetContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    widgetTitle:SetPoint("TOPLEFT", widgetContainer, "TOPLEFT", 15, -15)
    widgetTitle:SetText("Map Widget")
    widgetTitle:SetTextColor(0.8, 0.9, 1)
    
    local showMapWidgetCheck = CreateFrame("CheckButton", nil, widgetContainer, "UICheckButtonTemplate")
    showMapWidgetCheck:SetPoint("TOPLEFT", widgetTitle, "BOTTOMLEFT", 0, -10)
    
    local showMapWidgetLabel = showMapWidgetCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    showMapWidgetLabel:SetPoint("LEFT", showMapWidgetCheck, "RIGHT", 5, 0)
    showMapWidgetLabel:SetText("Show world map widget buttons")
    
    showMapWidgetCheck:SetScript("OnClick", function(self)
        CityGuideConfig.showMapWidget = self:GetChecked()
        CityGuide_UpdateMapLabels()
        
        if CityGuideConfig.showMapWidget then
            print("|cff00ff00City Guide:|r Map widget enabled")
        else
            print("|cff00ff00City Guide:|r Map widget disabled")
        end
    end)
    
    showMapWidgetCheck:SetScript("OnEnter", function(self)
        showMapWidgetLabel:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show World Map Widget")
        GameTooltip:AddLine("When enabled, shows the City Guide buttons on the world map", 1, 1, 1, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("When disabled: Hides all City Guide buttons from the world map", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("Note: Labels and icons will still appear on the map", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    
    showMapWidgetCheck:SetScript("OnLeave", function(self)
        showMapWidgetLabel:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)

    -- Waypoint checkbox
    local enableWaypointsCheck = CreateFrame("CheckButton", nil, widgetContainer, "UICheckButtonTemplate")
    enableWaypointsCheck:SetPoint("TOPLEFT", showMapWidgetCheck, "BOTTOMLEFT", 0, -8)

    local enableWaypointsLabel = enableWaypointsCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    enableWaypointsLabel:SetPoint("LEFT", enableWaypointsCheck, "RIGHT", 5, 0)
    enableWaypointsLabel:SetText("Enable icon waypoints")

    enableWaypointsCheck:SetScript("OnClick", function(self)
        CityGuideConfig.enableWaypoints = self:GetChecked()
    end)

    enableWaypointsCheck:SetScript("OnEnter", function(self)
        enableWaypointsLabel:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable Icon Waypoints")
        GameTooltip:AddLine("When enabled, left-clicking any icon on the map sets a waypoint at that location", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    enableWaypointsCheck:SetScript("OnLeave", function(self)
        enableWaypointsLabel:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    
    -- Enabled Cities
    local citiesTitle = generalSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    citiesTitle:SetPoint("TOPLEFT", widgetContainer, "BOTTOMLEFT", 0, -20)
    citiesTitle:SetText("Enabled Cities")
    citiesTitle:SetTextColor(0.8, 0.9, 1)
    
    local citiesDesc = generalSection:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    citiesDesc:SetPoint("TOPLEFT", citiesTitle, "BOTTOMLEFT", 0, -5)
    citiesDesc:SetText("Select which cities show City Guide labels")
    citiesDesc:SetTextColor(0.7, 0.7, 0.7)
    
    local cityCheckboxes = {}
    local cityYOffset = -255 -- Adjusted for the new widget container
    local cityOrder = CityGuide_GetCityOrder()
    local mapNames = CityGuide_GetCityNames()
    
    for _, mapID in ipairs(cityOrder) do
        local cityName = mapNames[mapID]
        local checkbox = CreateFrame("CheckButton", nil, generalSection, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 20, cityYOffset)
        
        local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(cityName)
        
        checkbox.mapID = mapID
        
        checkbox:SetScript("OnClick", function(self)
            CityGuideConfig.enabledCities = CityGuideConfig.enabledCities or {}
            CityGuideConfig.enabledCities[self.mapID] = self:GetChecked()
            CityGuide_UpdateMapLabels()
        end)
        
        -- Hover effect
        checkbox:SetScript("OnEnter", function(self)
            label:SetTextColor(1, 1, 0.5)
        end)
        
        checkbox:SetScript("OnLeave", function(self)
            label:SetTextColor(1, 1, 1)
        end)
        
        cityCheckboxes[mapID] = checkbox
        cityYOffset = cityYOffset - 30
    end
    
    -- Store references for updates
    generalSection.cityCheckboxes = cityCheckboxes
    generalSection.showMapWidgetCheck = showMapWidgetCheck
    generalSection.enableWaypointsCheck = enableWaypointsCheck
end

function CityGuideSettings_UpdateGeneralSection()
    local section = CityGuideSettings.contentSections["general"]
    if not section then return end
    
    -- Update map widget checkbox
    if section.showMapWidgetCheck then
        section.showMapWidgetCheck:SetChecked(CityGuideConfig.showMapWidget)
    end

    -- Update waypoint checkbox
    if section.enableWaypointsCheck then
        section.enableWaypointsCheck:SetChecked(CityGuideConfig.enableWaypoints ~= false)
    end
    
    -- Update city checkboxes
    CityGuideConfig.enabledCities = CityGuideConfig.enabledCities or {}
    
    for mapID, checkbox in pairs(section.cityCheckboxes) do
        if CityGuideConfig.enabledCities[mapID] == nil then
            checkbox:SetChecked(true)
        else
            checkbox:SetChecked(CityGuideConfig.enabledCities[mapID])
        end
    end
end