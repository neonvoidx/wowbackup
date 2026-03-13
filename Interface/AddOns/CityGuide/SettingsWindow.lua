-- Standalone Settings Window
-- This creates a detached, movable settings window

local standaloneWindow = nil

function CityGuide_CreateStandaloneSettingsWindow()
    if standaloneWindow then
        return standaloneWindow
    end
    
    -- Get city data
    local cityOrder = CityGuide_GetCityOrder()
    local mapNames = CityGuide_GetCityNames()
    local cityThemes = CityGuideSettings.cityThemes
    
    -- Create main window
    local window = CreateFrame("Frame", "CityGuideStandaloneSettings", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(700, 550)
    window:SetPoint("CENTER")
    window:Hide()
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    
    -- The template already has a background, just color it black
    if window.Bg then
        window.Bg:SetColorTexture(0, 0, 0, 0.9)
    end
    if window.InsetBg then
        window.InsetBg:SetColorTexture(0, 0, 0, 0.8)
    end
    
    -- Title (use the built-in TitleText from the template)
    if window.TitleText then
        window.TitleText:SetText("City Guide Settings")
        window.TitleText:SetTextColor(1, 0.9, 0.5)
    else
        window.title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        window.title:SetPoint("TOP", 0, -5)
        window.title:SetText("City Guide Settings")
        window.title:SetTextColor(1, 0.9, 0.5)
    end
    
    -- Close button (X) is provided by BasicFrameTemplateWithInset
    
    -- Create navigation panel
    local navPanel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    navPanel:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -30)
    navPanel:SetSize(150, 480)
    navPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    navPanel:SetBackdropColor(0, 0, 0, 0.8)
    navPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create content panel
    local contentPanel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    contentPanel:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 10, 0)
    contentPanel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -12, 12)
    contentPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentPanel:SetBackdropColor(0, 0, 0, 0.8)
    contentPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Store for theme changes
    contentPanel.bgTexture = contentPanel:CreateTexture(nil, "BACKGROUND")
    contentPanel.bgTexture:SetAllPoints()
    contentPanel.bgTexture:SetColorTexture(0, 0, 0, 0.8)
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    local function UpdateScrollChildSize()
        local width = scrollFrame:GetWidth() - 40
        scrollChild:SetWidth(width)
    end
    
    scrollFrame:SetScript("OnSizeChanged", UpdateScrollChildSize)
    UpdateScrollChildSize()
    
    -- Store references
    window.contentPanel = contentPanel
    window.scrollChild = scrollChild
    window.contentSections = {}
    window.navButtons = {}
    window.currentCategory = nil
    
    -- Theme function
    local function SetContentPanelTheme(mapID)
        if not mapID or not cityThemes[mapID] then
            contentPanel.bgTexture:SetGradient("VERTICAL",
                CreateColor(0, 0, 0, 0.8),
                CreateColor(0.05, 0.05, 0.05, 0.8))
            return
        end
        
        local theme = cityThemes[mapID]
        contentPanel.bgTexture:SetGradient("VERTICAL",
            CreateColor(theme.r1 * 0.1, theme.g1 * 0.1, theme.b1 * 0.1, 0.8),
            CreateColor(theme.r2 * 0.15, theme.g2 * 0.15, theme.b2 * 0.15, 0.8))
    end
    
    window.SetContentPanelTheme = SetContentPanelTheme
    
    -- Show/hide sections
    local function HideAllSections()
        for id, section in pairs(window.contentSections) do
            section:Hide()
        end
    end
    
    local function ShowSection(sectionId)
        if window.currentCategory == sectionId then
            return
        end
        
        HideAllSections()
        
        if window.contentSections[sectionId] then
            local section = window.contentSections[sectionId]
            section:Show()
            window.currentCategory = sectionId
            
            local mapID = sectionId:match("city_(%d+)")
            if mapID then
                SetContentPanelTheme(tonumber(mapID))
            else
                SetContentPanelTheme(nil)
            end
        end
        
        -- Update nav highlights
        for _, btn in ipairs(window.navButtons) do
            if btn.categoryId == sectionId then
                btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
                if btn.highlight then btn.highlight:Show() end
            else
                btn:SetBackdropColor(0, 0, 0, 0.5)
                if btn.highlight then btn.highlight:Hide() end
            end
        end
    end
    
    window.ShowSection = ShowSection
    
    -- Create nav categories
    local navCategories = {
        {name = "General", id = "general", icon = "Interface\\Icons\\INV_Misc_Book_09"},
        {name = "Filters", id = "filters", icon = "Interface\\Icons\\INV_Misc_Spyglass_03"},
        {name = "Display", id = "display", icon = "Interface\\Icons\\INV_Misc_Map02"},
        {name = "Sizes", id = "sizes", icon = "Interface\\Icons\\Ability_Warrior_ShieldMastery"}
    }
    
    for _, mapID in ipairs(cityOrder) do
        local theme = cityThemes[mapID]
        table.insert(navCategories, {
            name = mapNames[mapID],
            id = "city_"..mapID,
            icon = theme and theme.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            mapID = mapID
        })
    end
    
    -- Create nav buttons
    local yOffset = -10
    for i, category in ipairs(navCategories) do
        local btn = CreateFrame("Button", nil, navPanel, "BackdropTemplate")
        btn:SetSize(130, 35)
        btn:SetPoint("TOP", navPanel, "TOP", 0, yOffset)
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\UI-Common-MouseHilight",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0, 0, 0, 0.5)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        if category.icon then
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
            icon:SetTexture(category.icon)
            btn.icon = icon
        end
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", category.icon and 38 or 10, 0)
        text:SetText(category.name)
        text:SetJustifyH("LEFT")
        text:SetWidth(85)
        
        local highlight = btn:CreateTexture(nil, "BACKGROUND")
        highlight:SetPoint("TOPLEFT", -2, 2)
        highlight:SetPoint("BOTTOMRIGHT", 2, -2)
        highlight:SetColorTexture(0.3, 0.3, 0.3, 0.4)
        highlight:Hide()
        btn.highlight = highlight
        
        btn.categoryId = category.id
        btn.mapID = category.mapID
        
        btn:SetScript("OnClick", function(self)
            ShowSection(self.categoryId)
        end)
        
        btn:SetScript("OnEnter", function(self)
            if window.currentCategory ~= self.categoryId then
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            end
            if self.icon then
                self.icon:SetVertexColor(1, 1, 0.7)
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            if window.currentCategory ~= self.categoryId then
                self:SetBackdropColor(0, 0, 0, 0.5)
            end
            if self.icon then
                self.icon:SetVertexColor(1, 1, 1)
            end
        end)
        
        table.insert(window.navButtons, btn)
        yOffset = yOffset - 38
    end
    
    -- Footer: donation link at bottom of nav panel
    -- Version label
    local versionText = navPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionText:SetPoint("BOTTOM", navPanel, "BOTTOM", 0, 2)
    versionText:SetText("|cff444444v" .. (C_AddOns.GetAddOnMetadata("CityGuide", "Version") or "?") .. "|r")

    -- Donation button
    local footerBtn = CreateFrame("Button", nil, navPanel)
    footerBtn:SetSize(130, 20)
    footerBtn:SetPoint("BOTTOM", navPanel, "BOTTOM", 0, -18)

    local footerText = footerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerText:SetPoint("CENTER", footerBtn, "CENTER", 0, 0)
    footerText:SetText("|cff555555Buy me a coffee|r")

    footerBtn:SetScript("OnClick", function()
        if not StaticPopupDialogs["CITYGUIDE_DONATE"] then
            StaticPopupDialogs["CITYGUIDE_DONATE"] = {
                text = "Enjoying City Guide? Support development:",
                button1 = "Close",
                hasEditBox = true,
                editBoxWidth = 260,
                OnShow = function(self)
                    self.EditBox:SetText("https://buymeacoffee.com/valash")
                    self.EditBox:SetFocus()
                    self.EditBox:HighlightText()
                end,
                OnAccept = function() end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
        end
        StaticPopup_Show("CITYGUIDE_DONATE")
    end)

    footerBtn:SetScript("OnEnter", function()
        footerText:SetText("|cffa0a0a0 Buy me a coffee|r")
    end)

    footerBtn:SetScript("OnLeave", function()
        footerText:SetText("|cff555555 Buy me a coffee|r")
    end)

    -- Load sections using existing functions but with our scroll child
    local originalScrollChild = CityGuideSettings.scrollChild
    local originalContentSections = CityGuideSettings.contentSections
    
    -- Temporarily set up for loading
    CityGuideSettings.scrollChild = scrollChild
    CityGuideSettings.contentSections = {}
    
    -- Create sections and store in window
    CityGuideSettings_LoadGeneralSection()
    window.contentSections["general"] = CityGuideSettings.contentSections["general"]
    
    CityGuideSettings_LoadFiltersSection()
    window.contentSections["filters"] = CityGuideSettings.contentSections["filters"]
    
    CityGuideSettings_LoadDisplaySection()
    window.contentSections["display"] = CityGuideSettings.contentSections["display"]
    
    CityGuideSettings_LoadSizesSection()
    window.contentSections["sizes"] = CityGuideSettings.contentSections["sizes"]
    
    for _, mapID in ipairs(cityOrder) do
        CityGuideSettings_LoadCitySection(mapID)
        window.contentSections["city_"..mapID] = CityGuideSettings.contentSections["city_"..mapID]
    end
    
    -- Restore original
    CityGuideSettings.scrollChild = originalScrollChild
    CityGuideSettings.contentSections = originalContentSections
    
    -- OnShow handler
    window:SetScript("OnShow", function()
        -- Temporarily redirect CityGuideSettings.contentSections to window's sections
        local originalContentSections = CityGuideSettings.contentSections
        CityGuideSettings.contentSections = window.contentSections
        
        -- Update all sections
        if CityGuideSettings_UpdateGeneralSection then
            CityGuideSettings_UpdateGeneralSection()
        end
        if CityGuideSettings_UpdateFiltersSection then
            CityGuideSettings_UpdateFiltersSection()
        end
        if CityGuideSettings_UpdateDisplaySection then
            CityGuideSettings_UpdateDisplaySection()
        end
        if CityGuideSettings_UpdateSizesSection then
            CityGuideSettings_UpdateSizesSection()
        end
        
        for _, mapID in ipairs(cityOrder) do
            local updateFunc = _G["CityGuideSettings_UpdateCitySection_"..mapID]
            if updateFunc then
                updateFunc()
            end
        end
        
        -- Restore
        CityGuideSettings.contentSections = originalContentSections
        
        ShowSection("general")
    end)
    
    -- Make closable with ESC key
    tinsert(UISpecialFrames, "CityGuideStandaloneSettings")
    
    standaloneWindow = window
    return window
end

-- Function to toggle the standalone window
function CityGuide_ToggleStandaloneSettings()
    local window = CityGuide_CreateStandaloneSettingsWindow()
    if window:IsShown() then
        window:Hide()
    else
        window:Show()
    end
end