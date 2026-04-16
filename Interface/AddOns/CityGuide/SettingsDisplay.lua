-- Display Settings Section

function CityGuideSettings_LoadDisplaySection()
    local scrollChild = CityGuideSettings.scrollChild
    
    local displaySection = CreateFrame("Frame", nil, scrollChild)
    displaySection:SetPoint("TOPLEFT", 20, -20)
    displaySection:SetPoint("TOPRIGHT", -20, -20)
    displaySection:SetHeight(760)  -- Increased from 600 to fit Label Priority section
    CityGuideSettings.contentSections["display"] = displaySection
    
    -- Section title
    local titleContainer = CreateFrame("Frame", nil, displaySection, "BackdropTemplate")
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
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
    
    local displayTitle = titleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    displayTitle:SetPoint("LEFT", titleIcon, "RIGHT", 10, 0)
    displayTitle:SetText("Display Modes")
    displayTitle:SetTextColor(1, 0.9, 0.5)

    -- ── Label Priority ────────────────────────────────────────────────────────
    -- Controls frame strata of map labels/icons relative to quest pins.

    local priorityTitle = displaySection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    priorityTitle:SetPoint("TOPLEFT", titleContainer, "BOTTOMLEFT", 0, -20)
    priorityTitle:SetText("Frame Strata:")
    priorityTitle:SetTextColor(0.8, 0.9, 1)

    local priorityDesc = displaySection:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    priorityDesc:SetPoint("TOPLEFT", priorityTitle, "BOTTOMLEFT", 0, -4)
    priorityDesc:SetText("Sets the frame strata of labels/icons. Use 'Medium' if city guide overlaps quest or campaign pins.")
    priorityDesc:SetTextColor(0.6, 0.6, 0.6)
    priorityDesc:SetWidth(355)
    priorityDesc:SetJustifyH("LEFT")

    local priorityContainer = CreateFrame("Frame", nil, displaySection)
    priorityContainer:SetPoint("TOPLEFT", priorityDesc, "BOTTOMLEFT", 0, -10)
    priorityContainer:SetSize(355, 55)

    local priorityOptions = {
        { key = "under",  text = "Medium",  desc = "Below quest pins" },
        { key = "normal", text = "Normal",         desc = "(default)" },
        { key = "top",    text = "Always On Top"},
    }

    local priorityButtons = {}
    local btnWidth = 115
    local btnGap = 5

    for i, opt in ipairs(priorityOptions) do
        local btn = CreateFrame("Button", nil, priorityContainer, "BackdropTemplate")
        btn:SetSize(btnWidth, 50)
        btn:SetPoint("TOPLEFT", priorityContainer, "TOPLEFT", (i - 1) * (btnWidth + btnGap), 0)
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })

        local isSelected = (CityGuideConfig.labelPriority or "normal") == opt.key
        if isSelected then
            btn:SetBackdropColor(0.2, 0.4, 0.2, 1)
            btn:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
        else
            btn:SetBackdropColor(0, 0, 0, 0.4)
            btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        end

        local btnTitle = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnTitle:SetPoint("TOP", btn, "TOP", 0, -10)
        btnTitle:SetText(opt.text)
        btnTitle:SetTextColor(isSelected and 0.5 or 1, 1, isSelected and 0.5 or 1)
        btnTitle:SetJustifyH("CENTER")

        local btnDesc = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnDesc:SetPoint("TOP", btnTitle, "BOTTOM", 0, -3)
        btnDesc:SetText(opt.desc)
        btnDesc:SetTextColor(0.6, 0.6, 0.6)
        btnDesc:SetWidth(btnWidth - 10)
        btnDesc:SetJustifyH("CENTER")

        btn.optKey   = opt.key
        btn.btnTitle = btnTitle
        priorityButtons[i] = btn

        btn:SetScript("OnClick", function(self)
            CityGuideConfig.labelPriority = self.optKey
            CityGuide_UpdateMapLabels()
            print("|cff00ff00City Guide:|r Label strata priority set to " .. opt.text)
            CityGuideSettings_UpdateDisplaySection()
        end)

        btn:SetScript("OnEnter", function(self)
            if (CityGuideConfig.labelPriority or "normal") ~= self.optKey then
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
            self.btnTitle:SetTextColor(1, 1, 0.5)
        end)

        btn:SetScript("OnLeave", function(self)
            if (CityGuideConfig.labelPriority or "normal") ~= self.optKey then
                self:SetBackdropColor(0, 0, 0, 0.4)
            end
            local sel = (CityGuideConfig.labelPriority or "normal") == self.optKey
            self.btnTitle:SetTextColor(sel and 0.5 or 1, 1, sel and 0.5 or 1)
        end)
    end

    displaySection.priorityButtons = priorityButtons
    -- ── End Label Priority ────────────────────────────────────────────────────

    -- Display System Toggle (Two horizontal buttons)
    local systemToggleContainer = CreateFrame("Frame", nil, displaySection, "BackdropTemplate")
    systemToggleContainer:SetSize(380, 100)
    systemToggleContainer:SetPoint("TOPLEFT", priorityContainer, "BOTTOMLEFT", 0, -20)
    systemToggleContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    systemToggleContainer:SetBackdropColor(0.1, 0.15, 0.2, 0.6)
    systemToggleContainer:SetBackdropBorderColor(0.5, 0.7, 1, 0.8)
    
    local systemToggleTitle = systemToggleContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    systemToggleTitle:SetPoint("TOPLEFT", systemToggleContainer, "TOPLEFT", 15, -12)
    systemToggleTitle:SetText("Display System")
    systemToggleTitle:SetTextColor(0.8, 0.9, 1)
    
    -- Text Mode Button
    local textModeButton = CreateFrame("Button", nil, systemToggleContainer, "BackdropTemplate")
    textModeButton:SetSize(170, 50)
    textModeButton:SetPoint("TOPLEFT", systemToggleTitle, "BOTTOMLEFT", 0, -10)
    textModeButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    local textModeTitle = textModeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textModeTitle:SetPoint("TOP", textModeButton, "TOP", 0, -10)
    textModeTitle:SetText("Text Mode")
    
    local textModeDesc = textModeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textModeDesc:SetPoint("TOP", textModeTitle, "BOTTOM", 0, -3)
    textModeDesc:SetText("5 display modes")
    textModeDesc:SetTextColor(0.7, 0.7, 0.7)
    
    -- Tooltip Mode Button
    local tooltipModeButton = CreateFrame("Button", nil, systemToggleContainer, "BackdropTemplate")
    tooltipModeButton:SetSize(170, 50)
    tooltipModeButton:SetPoint("LEFT", textModeButton, "RIGHT", 10, 0)
    tooltipModeButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    local tooltipModeTitle = tooltipModeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltipModeTitle:SetPoint("TOP", tooltipModeButton, "TOP", 0, -10)
    tooltipModeTitle:SetText("Tooltip Mode")
    
    local tooltipModeDesc = tooltipModeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tooltipModeDesc:SetPoint("TOP", tooltipModeTitle, "BOTTOM", 0, -3)
    tooltipModeDesc:SetText("3 display modes")
    tooltipModeDesc:SetTextColor(0.7, 0.7, 0.7)
    
    -- Mode selection title
    local modeTitle = displaySection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeTitle:SetPoint("TOPLEFT", systemToggleContainer, "BOTTOMLEFT", 0, -20)
    modeTitle:SetText("Select Display Mode:")
    modeTitle:SetTextColor(0.8, 0.9, 1)
    
    -- Mode buttons container - THIS IS KEY: single container that we'll populate dynamically
    local modeButtonsContainer = CreateFrame("Frame", nil, displaySection)
    modeButtonsContainer:SetPoint("TOPLEFT", modeTitle, "BOTTOMLEFT", 0, -10)
    modeButtonsContainer:SetPoint("TOPRIGHT", displaySection, "TOPRIGHT", 0, -200)
    modeButtonsContainer:SetHeight(400)
    
    -- Store references
    displaySection.textModeButton = textModeButton
    displaySection.tooltipModeButton = tooltipModeButton
    displaySection.textModeTitle = textModeTitle
    displaySection.tooltipModeTitle = tooltipModeTitle
    displaySection.modeButtonsContainer = modeButtonsContainer
    displaySection.modeButtons = {} -- Will hold currently displayed buttons
    
    -- Function to rebuild the mode buttons
    local function RebuildModeButtons()
        -- Clear existing buttons
        for _, btn in ipairs(displaySection.modeButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        displaySection.modeButtons = {}
        
        -- Define which modes to show
        local modesToShow
        if CityGuideConfig.useTooltips then
            modesToShow = {
                {mode = "labels", text = "Labels Only", desc = "Show only text labels"},
                {mode = "both", text = "Icons with Tooltips", desc = "Hover icons to see names"},
                {mode = "smallboth", text = "Small Icons with Tooltips", desc = "Minimap-style with hover"},
            }
        else
            modesToShow = {
                {mode = "labels", text = "Labels Only", desc = "Show only text labels"},
                {mode = "icons", text = "Icons Only", desc = "Show only square icons"},
                {mode = "both", text = "Icons with Labels", desc = "Square icons + labels"},
                {mode = "smallicons", text = "Small Icons", desc = "Minimap-style icons only"},
                {mode = "smallboth", text = "Small Icons with Labels", desc = "Minimap-style + labels"},
            }
        end
        
        -- Create buttons for current mode
        local yOffset = 0
        for _, modeData in ipairs(modesToShow) do
            local btn = CreateFrame("Button", nil, modeButtonsContainer, "BackdropTemplate")
            btn:SetSize(355, 50)
            btn:SetPoint("TOPLEFT", 0, yOffset)
            btn:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 8,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            
            -- Check if this is the selected mode
            local isSelected = (CityGuideConfig.displayMode == modeData.mode)
            if isSelected then
                btn:SetBackdropColor(0.2, 0.4, 0.2, 1)
                btn:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
            else
                btn:SetBackdropColor(0, 0, 0, 0.4)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
            end
            
            local checkmark = btn:CreateTexture(nil, "OVERLAY")
            checkmark:SetSize(24, 24)
            checkmark:SetPoint("LEFT", btn, "LEFT", 10, 0)
            checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            if isSelected then
                checkmark:Show()
            else
                checkmark:Hide()
            end
            
            local title = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOPLEFT", btn, "TOPLEFT", 45, -10)
            title:SetText(modeData.text)
            title:SetTextColor(1, 1, 1)
            
            local descText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            descText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
            descText:SetText(modeData.desc)
            descText:SetTextColor(0.7, 0.7, 0.7)
            
            btn:SetScript("OnClick", function(self)
                CityGuideConfig.displayMode = modeData.mode
                CityGuide_UpdateMapLabels()
                print("|cff00ff00City Guide:|r " .. modeData.text)
                RebuildModeButtons() -- Rebuild to update selection
            end)

            btn:SetScript("OnEnter", function(self)
                if CityGuideConfig.displayMode ~= modeData.mode then
                    self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                end
                title:SetTextColor(1, 1, 0.5)
            end)
            
            btn:SetScript("OnLeave", function(self)
                if CityGuideConfig.displayMode ~= modeData.mode then
                    self:SetBackdropColor(0, 0, 0, 0.4)
                end
                title:SetTextColor(1, 1, 1)
            end)
            
            table.insert(displaySection.modeButtons, btn)
            yOffset = yOffset - 60
        end
    end
    
    -- Set up system toggle button clicks
    textModeButton:SetScript("OnClick", function(self)
        CityGuideConfig.useTooltips = false
        CityGuideConfig.displayMode = "labels"
        print("|cff00ff00City Guide:|r Text Mode enabled - Labels Only")
        CityGuide_UpdateMapLabels()
        
        -- Force rebuild immediately
        if displaySection.RebuildModeButtons then
            displaySection.RebuildModeButtons()
        end
        
        -- Then update colors
        CityGuideSettings_UpdateDisplaySection()
    end)
    
    textModeButton:SetScript("OnEnter", function(self)
        if not CityGuideConfig.useTooltips then
            textModeTitle:SetTextColor(1, 1, 0.5)
        else
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            textModeTitle:SetTextColor(1, 1, 0.5)
        end
    end)
    
    textModeButton:SetScript("OnLeave", function(self)
        if not CityGuideConfig.useTooltips then
            textModeTitle:SetTextColor(0.5, 1, 0.5)
        else
            self:SetBackdropColor(0, 0, 0, 0.4)
            textModeTitle:SetTextColor(1, 1, 1)
        end
    end)
    
    tooltipModeButton:SetScript("OnClick", function(self)
        CityGuideConfig.useTooltips = true
        CityGuideConfig.displayMode = "both"
        print("|cff00ff00City Guide:|r Tooltip Mode enabled - Icons with Tooltips")
        CityGuide_UpdateMapLabels()
        
        -- Force rebuild immediately
        if displaySection.RebuildModeButtons then
            displaySection.RebuildModeButtons()
        end
        
        -- Then update colors
        CityGuideSettings_UpdateDisplaySection()
    end)
    
    tooltipModeButton:SetScript("OnEnter", function(self)
        if CityGuideConfig.useTooltips then
            tooltipModeTitle:SetTextColor(1, 1, 0.5)
        else
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            tooltipModeTitle:SetTextColor(1, 1, 0.5)
        end
    end)
    
    tooltipModeButton:SetScript("OnLeave", function(self)
        if CityGuideConfig.useTooltips then
            tooltipModeTitle:SetTextColor(0.5, 1, 0.5)
        else
            self:SetBackdropColor(0, 0, 0, 0.4)
            tooltipModeTitle:SetTextColor(1, 1, 1)
        end
    end)
    
    -- Store the rebuild function so update can call it
    displaySection.RebuildModeButtons = RebuildModeButtons
    
    -- Initial build
    RebuildModeButtons()
end

function CityGuideSettings_UpdateDisplaySection()
    local section = CityGuideSettings.contentSections and CityGuideSettings.contentSections["display"]
    if not section then return end
    if not section.textModeButton or not section.tooltipModeButton then return end
    
    -- Update system toggle button colors (mutually exclusive)
    if CityGuideConfig.useTooltips then
        -- Tooltip mode is active
        section.textModeButton:SetBackdropColor(0, 0, 0, 0.4)
        section.textModeButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        section.textModeTitle:SetTextColor(1, 1, 1)
        
        section.tooltipModeButton:SetBackdropColor(0.2, 0.4, 0.2, 1)
        section.tooltipModeButton:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
        section.tooltipModeTitle:SetTextColor(0.5, 1, 0.5)
    else
        -- Text mode is active
        section.textModeButton:SetBackdropColor(0.2, 0.4, 0.2, 1)
        section.textModeButton:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
        section.textModeTitle:SetTextColor(0.5, 1, 0.5)
        
        section.tooltipModeButton:SetBackdropColor(0, 0, 0, 0.4)
        section.tooltipModeButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        section.tooltipModeTitle:SetTextColor(1, 1, 1)
    end
    
    -- Rebuild the mode buttons to show correct set
    if section.RebuildModeButtons then
        section.RebuildModeButtons()
    end

    -- Update label priority button highlights
    if section.priorityButtons then
        local current = CityGuideConfig.labelPriority or "normal"
        for _, btn in ipairs(section.priorityButtons) do
            if btn.optKey == current then
                btn:SetBackdropColor(0.2, 0.4, 0.2, 1)
                btn:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
                btn.btnTitle:SetTextColor(0.5, 1, 0.5)
            else
                btn:SetBackdropColor(0, 0, 0, 0.4)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
                btn.btnTitle:SetTextColor(1, 1, 1)
            end
        end
    end
end