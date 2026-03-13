-- Filters Settings Section

function CityGuideSettings_LoadFiltersSection()
    local scrollChild = CityGuideSettings.scrollChild
    
    local filtersSection = CreateFrame("Frame", nil, scrollChild)
    filtersSection:SetPoint("TOPLEFT", 20, -20)
    filtersSection:SetPoint("TOPRIGHT", -20, -20)
    filtersSection:SetHeight(500)
    CityGuideSettings.contentSections["filters"] = filtersSection
    
    -- Section title with icon
    local titleContainer = CreateFrame("Frame", nil, filtersSection, "BackdropTemplate")
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
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    
    local filtersTitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    filtersTitle:SetPoint("LEFT", titleIcon, "RIGHT", 10, 0)
    filtersTitle:SetText("Filters")
    filtersTitle:SetTextColor(1, 0.9, 0.5)
    
    local filtersDesc = filtersSection:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    filtersDesc:SetPoint("TOPLEFT", titleContainer, "BOTTOMLEFT", 0, -10)
    filtersDesc:SetText("Control which types of POIs are displayed on the map")
    filtersDesc:SetTextColor(0.7, 0.7, 0.7)
    
    -- Profession Filter Container
    local profContainer = CreateFrame("Frame", nil, filtersSection, "BackdropTemplate")
    profContainer:SetSize(380, 100)
    profContainer:SetPoint("TOPLEFT", filtersDesc, "BOTTOMLEFT", 0, -20)
    profContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    profContainer:SetBackdropColor(0, 0, 0, 0.4)
    profContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local profTitle = profContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profTitle:SetPoint("TOPLEFT", profContainer, "TOPLEFT", 15, -15)
    profTitle:SetText("Profession Filter")
    profTitle:SetTextColor(0.8, 0.9, 1)
    
    local profFilterCheck = CreateFrame("CheckButton", nil, profContainer, "UICheckButtonTemplate")
    profFilterCheck:SetPoint("TOPLEFT", profTitle, "BOTTOMLEFT", 0, -10)
    
    local profFilterLabel = profFilterCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profFilterLabel:SetPoint("LEFT", profFilterCheck, "RIGHT", 5, 0)
    profFilterLabel:SetText("Only show my learned professions")
    
    profFilterCheck:SetScript("OnClick", function(self)
        CityGuideConfig.filterByProfession = self:GetChecked()
        CityGuide_UpdateMapLabels()
        -- Don't call update function here, it will cause errors
    end)
    
    profFilterCheck:SetScript("OnEnter", function(self)
        profFilterLabel:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Filter by Learned Professions")
        GameTooltip:AddLine("When enabled, only profession trainers for your learned professions will be shown", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    
    profFilterCheck:SetScript("OnLeave", function(self)
        profFilterLabel:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    
    -- Faction Filter Container
    local factionContainer = CreateFrame("Frame", nil, filtersSection, "BackdropTemplate")
    factionContainer:SetSize(380, 100)
    factionContainer:SetPoint("TOPLEFT", profContainer, "BOTTOMLEFT", 0, -15)
    factionContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    factionContainer:SetBackdropColor(0, 0, 0, 0.4)
    factionContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local factionTitle = factionContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    factionTitle:SetPoint("TOPLEFT", factionContainer, "TOPLEFT", 15, -15)
    factionTitle:SetText("Faction Filter")
    factionTitle:SetTextColor(0.8, 0.9, 1)
    
    local factionFilterCheck = CreateFrame("CheckButton", nil, factionContainer, "UICheckButtonTemplate")
    factionFilterCheck:SetPoint("TOPLEFT", factionTitle, "BOTTOMLEFT", 0, -10)
    
    local factionFilterLabel = factionFilterCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    factionFilterLabel:SetPoint("LEFT", factionFilterCheck, "RIGHT", 5, 0)
    factionFilterLabel:SetText("Show faction-specific POIs")
    
    factionFilterCheck:SetScript("OnClick", function(self)
        CityGuideConfig.showFactionPOIs = self:GetChecked()
        
        if not self:GetChecked() then
            CityGuideConfig.factionPOIsOnly = CityGuideConfig.factionPOIsOnly or {}
            for mapID, _ in pairs(CityGuideConfig.factionPOIsOnly) do
                CityGuideConfig.factionPOIsOnly[mapID] = false
            end
        end
        
        CityGuide_UpdateMapLabels()
    end)
    
    factionFilterCheck:SetScript("OnEnter", function(self)
        factionFilterLabel:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show Faction-Specific POIs")
        GameTooltip:AddLine("Displays faction-specific NPCs and locations in all cities", 1, 1, 1, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        local playerFaction = CityGuide_GetPlayerFaction()
        GameTooltip:AddLine("Your faction: |cff00ff00" .. playerFaction .. "|r", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("When enabled: Shows NPCs tagged for your faction", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("When disabled: Hides all faction-tagged NPCs", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    
    factionFilterCheck:SetScript("OnLeave", function(self)
        factionFilterLabel:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    
    -- Decor Filter Container
    local decorContainer = CreateFrame("Frame", nil, filtersSection, "BackdropTemplate")
    decorContainer:SetSize(380, 100)
    decorContainer:SetPoint("TOPLEFT", factionContainer, "BOTTOMLEFT", 0, -15)
    decorContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    decorContainer:SetBackdropColor(0, 0, 0, 0.4)
    decorContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    local decorTitle = decorContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    decorTitle:SetPoint("TOPLEFT", decorContainer, "TOPLEFT", 15, -15)
    decorTitle:SetText("Decor Filter")
    decorTitle:SetTextColor(0.8, 0.9, 1)
    
    local decorFilterCheck = CreateFrame("CheckButton", nil, decorContainer, "UICheckButtonTemplate")
    decorFilterCheck:SetPoint("TOPLEFT", decorTitle, "BOTTOMLEFT", 0, -10)
    
    local decorFilterLabel = decorFilterCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    decorFilterLabel:SetPoint("LEFT", decorFilterCheck, "RIGHT", 5, 0)
    decorFilterLabel:SetText("Show Decor POIs")
    
    decorFilterCheck:SetScript("OnClick", function(self)
        CityGuideConfig.showDecorPOIs = self:GetChecked()
        CityGuide_UpdateMapLabels()
    end)
    
    decorFilterCheck:SetScript("OnEnter", function(self)
        decorFilterLabel:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show Decor POIs")
        GameTooltip:AddLine("Displays decoration vendor and related POIs", 1, 1, 1, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("When disabled: Hides POIs starting with 'Decor'", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("POIs with 'Decor' in the middle will show without the 'Decor' text", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    
    decorFilterCheck:SetScript("OnLeave", function(self)
        decorFilterLabel:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    
    -- Store references for updates
    filtersSection.profFilterCheck = profFilterCheck
    filtersSection.factionFilterCheck = factionFilterCheck
    filtersSection.decorFilterCheck = decorFilterCheck
end

function CityGuideSettings_UpdateFiltersSection()
    local section = CityGuideSettings.contentSections["filters"]
    if not section then return end
    
    section.profFilterCheck:SetChecked(CityGuideConfig.filterByProfession)
    section.factionFilterCheck:SetChecked(CityGuideConfig.showFactionPOIs)
    section.decorFilterCheck:SetChecked(CityGuideConfig.showDecorPOIs)
end