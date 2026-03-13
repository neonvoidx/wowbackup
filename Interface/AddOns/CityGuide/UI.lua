-- UI creation functions for City Guide

-- Map button reference
local mapButton = nil
local profFilterButton = nil
local buttonContainer = nil

-- Icon paths for each mode (better choices)
local modeIcons = {
    labels = "Interface\\Icons\\INV_Inscription_Scroll",  -- Scroll icon for text
    icons = "Interface\\Icons\\Ability_Spy",              -- Spyglass for viewing/finding
    both = "Interface\\Icons\\INV_Misc_Map02",             -- Map icon for both
    smallicons = "Interface\\Minimap\\Tracking\\Banker",   -- Small icon style
    smallboth = "Interface\\Cursor\\Crosshair\\workorders"        -- Small icons with labels
}

-- Returns the strata and frame level to use for map labels/icons.
-- Controlled by CityGuideConfig.labelPriority:
--   "under"  -> MEDIUM/100  (below quest pins - default)
--   "normal" -> HIGH/100    (above most pins but not extreme)
--   "top"    -> HIGH/9999   (always on top - original behaviour)
local function GetLabelStrataAndLevel()
    local p = CityGuideConfig.labelPriority or "under"
    if p == "normal" then
        return "HIGH", 100
    elseif p == "top" then
        return "HIGH", 9999
    else -- "under"
        return "MEDIUM", 100
    end
end

-- Function to create a label (text only)
function CityGuide_CreateTextLabel(parent, x, y, text, scale, textDirection, color, labelDistance, sizeMultiplier)
    scale = scale or 1.0
    textDirection = textDirection or "down"
    color = color or "FFFFFF"
    labelDistance = labelDistance or 1.0
    sizeMultiplier = sizeMultiplier or 1.0
    
    local finalScale = scale * sizeMultiplier
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200 * finalScale, 50 * finalScale) -- Increased height for multi-line
    
    local strata, level = GetLabelStrataAndLevel()
    container:SetFrameStrata(strata)
    container:SetFrameLevel(level)

    -- Check if text contains line breaks
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    if #lines > 1 then
        -- Multi-line text - create multiple font strings
        local lineHeight = 16 * finalScale
        local totalHeight = lineHeight * #lines
        
        for i, line in ipairs(lines) do
            local fontString = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            
            -- Position each line
            local yOffset = (totalHeight / 2) - (i - 0.5) * lineHeight
            fontString:SetPoint("CENTER", container, "CENTER", 0, yOffset)
            fontString:SetText(line)
            
            local r = tonumber(color:sub(1, 2), 16) / 255
            local g = tonumber(color:sub(3, 4), 16) / 255
            local b = tonumber(color:sub(5, 6), 16) / 255
            fontString:SetTextColor(r, g, b, 1)
            
            local font, _, flags = fontString:GetFont()
            fontString:SetFont(font, 16 * finalScale, "OUTLINE")
        end
    else
        -- Single-line text (original code)
        local fontString = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fontString:SetPoint("CENTER")
        fontString:SetText(text)
        
        local r = tonumber(color:sub(1, 2), 16) / 255
        local g = tonumber(color:sub(3, 4), 16) / 255
        local b = tonumber(color:sub(5, 6), 16) / 255
        fontString:SetTextColor(r, g, b, 1)
        
        local font, _, flags = fontString:GetFont()
        fontString:SetFont(font, 16 * finalScale, "OUTLINE")
    end

    local mapWidth = parent:GetWidth()
    local mapHeight = parent:GetHeight()
    
    local baseOffset = 0.03
    
    local offsetX, offsetY = 0, 0
    if textDirection == "left" then
        offsetX = -(baseOffset * labelDistance) * mapWidth
    elseif textDirection == "right" then
        offsetX = (baseOffset * labelDistance) * mapWidth
    elseif textDirection == "top" then
        offsetY = (baseOffset * labelDistance) * mapHeight
    elseif textDirection == "down" then
        offsetY = -(baseOffset * labelDistance) * mapHeight
    elseif textDirection == "none" then
        offsetX = 0
        offsetY = 0
    end
    
    container:SetPoint("CENTER", parent, "TOPLEFT", x * mapWidth + offsetX, -y * mapHeight + offsetY)

    container:Show()
    return container
end

-- Function to create icon only
function CityGuide_CreateIconOnly(parent, x, y, iconPath, minimapIcon, scale, sizeMultiplier, tooltipText, npcName)
    scale = scale or 1.0
    sizeMultiplier = sizeMultiplier or 1.0
    
    local finalScale = scale * sizeMultiplier
    
    -- Check display mode
    local displayMode = CityGuideConfig.displayMode or "labels"
    local useSmallIcons = (displayMode == "smallicons" or displayMode == "smallboth")
    
    -- Minimap icons are larger (28px) than square icons (24px)
    local iconSize = useSmallIcons and (30 * finalScale) or (24 * finalScale)
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(iconSize, iconSize)

    local strata, level = GetLabelStrataAndLevel()
    container:SetFrameStrata(strata)
    container:SetFrameLevel(level)
    
    if useSmallIcons and minimapIcon then
        -- Create circular glow background for small icons
        local glow = container:CreateTexture(nil, "BACKGROUND")
        glow:SetSize(iconSize * 2.4, iconSize * 2.4)
        glow:SetPoint("CENTER")
        
        -- Using a simple white texture with radial gradient effect
        glow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
        glow:SetVertexColor(1, 1, 0.8, 0.5) -- Warm white, 50% opacity
        glow:SetBlendMode("ADD")
        
        -- Main icon
        local icon = container:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER")
        icon:SetTexture(minimapIcon)
    else
        -- Use square icon (regular icons mode) - no glow
        local icon = container:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER")
        icon:SetTexture(iconPath)
    end

    -- Always enable mouse for waypoint clicking on icon modes
    container:EnableMouse(true)
    container:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and CityGuideConfig.enableWaypoints then
            local mapID = WorldMapFrame:GetMapID()
            if mapID and C_Map.CanSetUserWaypointOnMap(mapID) then
                local existing = C_Map.GetUserWaypoint()
                if existing and existing.uiMapID == mapID
                    and math.abs(existing.position.x - x) < 0.0001
                    and math.abs(existing.position.y - y) < 0.0001 then
                    -- Same icon clicked again — remove the waypoint
                    C_Map.ClearUserWaypoint()
                    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
                    PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_OFF)
                else
                    -- New icon — set the waypoint
                    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                    PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON)
                end
            end
        end
    end)

    -- Add tooltip if tooltipText is provided (tooltip mode)
    if tooltipText and CityGuideConfig.useTooltips then
        container:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            
            -- Check if text contains line breaks
            local lines = {}
            for line in tooltipText:gmatch("[^\n]+") do
                table.insert(lines, line)
            end
            
            if #lines > 1 then
                -- Multi-line tooltip - add first line as title, rest as centered lines
                GameTooltip:SetText(lines[1], 1, 1, 1, 1, true)
                for i = 2, #lines do
                    GameTooltip:AddLine(lines[i], 1, 1, 1, true) -- true = wrap text
                end
            else
                -- Single line tooltip
                GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            end
            
            GameTooltip:Show()
        end)
        container:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    local mapWidth = parent:GetWidth()
    local mapHeight = parent:GetHeight()
    container:SetPoint("CENTER", parent, "TOPLEFT", x * mapWidth, -y * mapHeight)

    container:Show()
    return container
end

-- Function to create/update the combined button container
function CityGuide_CreateOrUpdateMapButton()
    if not buttonContainer then
        -- Create container frame with backdrop
        buttonContainer = CreateFrame("Frame", "CityGuideButtonContainer", WorldMapFrame.BorderFrame, "BackdropTemplate")
        buttonContainer:SetSize(70, 30)
        
        -- Position it
        if WorldMapFrame.overlayFrames and WorldMapFrame.overlayFrames[2] then
            buttonContainer:SetPoint("RIGHT", WorldMapFrame.overlayFrames[2], "LEFT", -20, 0)
        else
            buttonContainer:SetPoint("TOPRIGHT", WorldMapFrame.BorderFrame, "TOPRIGHT", -10, -10)
        end
        
        -- Set backdrop (dark background)
        buttonContainer:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        buttonContainer:SetBackdropColor(0, 0, 0, 0.8)
        
        -- Create a glow texture for mode indication
        local modeGlow = buttonContainer:CreateTexture(nil, "BACKGROUND")
        modeGlow:SetPoint("TOPLEFT", -6, 6)
        modeGlow:SetPoint("BOTTOMRIGHT", 6, -6)
        modeGlow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
        modeGlow:SetBlendMode("ADD")
        buttonContainer.modeGlow = modeGlow
        
        -- Create one-shot flash animation for mode changes
        local flashAnim = modeGlow:CreateAnimationGroup()
        
        local flash1 = flashAnim:CreateAnimation("Alpha")
        flash1:SetFromAlpha(1)
        flash1:SetToAlpha(0.3)
        flash1:SetDuration(0.15)
        flash1:SetOrder(1)
        
        local flash2 = flashAnim:CreateAnimation("Alpha")
        flash2:SetFromAlpha(0.3)
        flash2:SetToAlpha(1)
        flash2:SetDuration(0.15)
        flash2:SetOrder(2)
        
        buttonContainer.flashAnim = flashAnim
        
        -- Create profession filter as a standard checkbox
        profFilterButton = CreateFrame("CheckButton", "CityGuideProfFilterButton", buttonContainer, "UICheckButtonTemplate")
        profFilterButton:SetSize(24, 24)
        profFilterButton:SetPoint("LEFT", buttonContainer, "LEFT", 5, 0)
        
        profFilterButton:SetScript("OnClick", function(self)
            CityGuideConfig.filterByProfession = self:GetChecked()
            CityGuide_UpdateMapLabels()
            
            if CityGuideConfig.filterByProfession then
                print("|cff00ff00City Guide:|r Profession filter enabled")
            else
                print("|cff00ff00City Guide:|r Profession filter disabled")
            end
        end)
        
        profFilterButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Filter My Professions")
            if CityGuideConfig.filterByProfession then
                GameTooltip:AddLine("|cff00ff00Enabled|r - Showing only your professions", 1, 1, 1)
            else
                GameTooltip:AddLine("|cffaaaaaa Disabled|r - Showing all professions", 1, 1, 1)
            end
            local profs = CityGuide_GetPlayerProfessions()
            if #profs > 0 then
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("Your professions:", 0.5, 1, 0.5)
                for _, profNames in ipairs(profs) do
                    GameTooltip:AddLine("  • " .. profNames[1], 1, 1, 1)
                end
            end
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Click to toggle", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        
        profFilterButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Create mode toggle button
        mapButton = CreateFrame("Button", "CityGuideToggleButton", buttonContainer)
        mapButton:SetSize(24, 24)
        mapButton:SetPoint("LEFT", profFilterButton, "RIGHT", 8, 0)
        
        -- Mode icon
        local modeIcon = mapButton:CreateTexture(nil, "ARTWORK")
        modeIcon:SetSize(20, 20)
        modeIcon:SetPoint("CENTER")
        modeIcon:SetTexture(modeIcons[CityGuideConfig.displayMode] or modeIcons["labels"])
        mapButton.icon = modeIcon
        
        mapButton:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                CityGuide_OnTutorialRightClick()   -- First-time UX tracking
                -- Right-click: Toggle tooltip mode ON/OFF
                CityGuideConfig.useTooltips = not CityGuideConfig.useTooltips
                
                if CityGuideConfig.useTooltips then
                    -- Switching TO tooltip mode - default to "both" (icons with tooltips)
                    CityGuideConfig.displayMode = "both"
                    print("|cff00ff00City Guide:|r Tooltip mode enabled - Icons with Tooltips")
                else
                    -- Switching to text mode - default to "labels"
                    CityGuideConfig.displayMode = "labels"
                    print("|cff00ff00City Guide:|r Text mode enabled - Labels Only")
                end
                
                -- Update icon immediately
                self.icon:SetTexture(modeIcons[CityGuideConfig.displayMode] or modeIcons["labels"])
                CityGuide_UpdateMapLabels()
                
                -- Update button container appearance
                CityGuide_CreateOrUpdateMapButton()
                
                -- Force refresh tooltip if it's showing
                if GameTooltip:IsOwned(self) then
                    GameTooltip:Hide()
                    self:GetScript("OnEnter")(self)
                end
            elseif button == "MiddleButton" then
                CityGuide_OnTutorialMiddleClick()   -- First-time UX tracking
                -- FEATURE 2: Middle-click to toggle current city enabled/disabled
                local mapID = WorldMapFrame:GetMapID()
                if mapID then
                    CityGuideConfig.enabledCities = CityGuideConfig.enabledCities or {}
                    
                    -- Get current state (nil means enabled by default)
                    local currentState = CityGuideConfig.enabledCities[mapID]
                    if currentState == nil then
                        currentState = true
                    end
                    
                    -- Toggle the state
                    CityGuideConfig.enabledCities[mapID] = not currentState
                    
                    -- Update the map labels
                    CityGuide_UpdateMapLabels()
                    
                    -- Print confirmation message
                    local mapNames = CityGuide_GetCityNames()
                    local cityName = mapNames[mapID] or "Unknown City"
                    if CityGuideConfig.enabledCities[mapID] == false then
                        print("|cff00ff00City Guide:|r " .. cityName .. " disabled")
                    else
                        print("|cff00ff00City Guide:|r " .. cityName .. " enabled")
                    end
                end
            else
                -- Left-click: Cycle through modes based on tooltip state
                if CityGuideConfig.useTooltips then
                    -- Tooltip mode: Only cycle through labels, both, smallboth
                    if CityGuideConfig.displayMode == "labels" then
                        CityGuideConfig.displayMode = "both"
                    elseif CityGuideConfig.displayMode == "both" then
                        CityGuideConfig.displayMode = "smallboth"
                    else
                        CityGuideConfig.displayMode = "labels"
                    end
                else
                    -- Legacy mode: Cycle through all 5 modes
                    if CityGuideConfig.displayMode == "labels" then
                        CityGuideConfig.displayMode = "icons"
                    elseif CityGuideConfig.displayMode == "icons" then
                        CityGuideConfig.displayMode = "both"
                    elseif CityGuideConfig.displayMode == "both" then
                        CityGuideConfig.displayMode = "smallicons"
                    elseif CityGuideConfig.displayMode == "smallicons" then
                        CityGuideConfig.displayMode = "smallboth"
                    else
                        CityGuideConfig.displayMode = "labels"
                    end
                end
                
                -- Update icon immediately
                self.icon:SetTexture(modeIcons[CityGuideConfig.displayMode] or modeIcons["labels"])
                CityGuide_UpdateMapLabels()
                
                -- Update button container appearance
                CityGuide_CreateOrUpdateMapButton()
                
                -- Force refresh tooltip if it's showing
                if GameTooltip:IsOwned(self) then
                    GameTooltip:Hide()
                    self:GetScript("OnEnter")(self)
                end
                
                -- Print mode name
                local modeName
                if CityGuideConfig.useTooltips then
                    modeName = CityGuideConfig.displayMode == "labels" and "Labels Only" or
                              CityGuideConfig.displayMode == "both" and "Icons with Tooltips" or
                              "Small Icons with Tooltips"
                else
                    modeName = CityGuideConfig.displayMode == "labels" and "Labels Only" or
                              CityGuideConfig.displayMode == "icons" and "Icons Only" or
                              CityGuideConfig.displayMode == "both" and "Icons with Labels" or
                              CityGuideConfig.displayMode == "smallicons" and "Small Icons" or
                              "Small Icons with Labels"
                end
                print("|cff00ff00City Guide:|r " .. modeName)
            end
        end)
        
        -- Register for left-click, right-click, and middle-click
        mapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        
        mapButton:SetScript("OnEnter", function(self)
            self.icon:SetVertexColor(1, 1, 0.7)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("City Guide Display Mode")
            
            -- Show current mode
            local mapID = WorldMapFrame:GetMapID()
            local isCityDisabled = mapID and (CityGuideConfig.enabledCities[mapID] == false)
            
            if isCityDisabled then
                GameTooltip:AddLine("|cffFF4444City Disabled|r", 1, 1, 1)
                GameTooltip:AddLine("Middle-click to re-enable this city", 0.8, 0.8, 0.8)
            else
                if CityGuideConfig.useTooltips then
                    GameTooltip:AddLine("|cffFFD700Tooltip Mode:|r ON", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Left-click: Cycle (3 modes)", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Right-click: Switch to Text Mode", 0.8, 0.8, 0.8)
                else
                    GameTooltip:AddLine("|cffFFD700Text Mode:|r ON", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Left-click: Cycle (5 modes)", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Right-click: Switch to Tooltip Mode", 0.8, 0.8, 0.8)
                end
                
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("|cffFFD700Middle-click:|r Disable this city", 1, 1, 0.5)
                
                -- Waypoint hint: only shown when icons are visible to click
                if CityGuideConfig.displayMode ~= "labels" then
                    GameTooltip:AddLine(" ", 1, 1, 1)
                    GameTooltip:AddLine("|cff444444Left-click an icon to set a waypoint|r")
                end
            end
            
            GameTooltip:Show()
        end)
        
        mapButton:SetScript("OnLeave", function(self)
            self.icon:SetVertexColor(1, 1, 1)
            GameTooltip:Hide()
        end)
    end
    
    -- Update checkbox state
    profFilterButton:SetChecked(CityGuideConfig.filterByProfession)
    
    -- Update mode icon - show X if current city is disabled
    local mapID = WorldMapFrame:GetMapID()
    local isCityDisabled = mapID and (CityGuideConfig.enabledCities[mapID] == false)
    
    if isCityDisabled then
        -- Show X icon when city is disabled
        mapButton.icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    else
        -- Show normal mode icon when city is enabled
        mapButton.icon:SetTexture(modeIcons[CityGuideConfig.displayMode] or modeIcons["labels"])
    end
    
    -- Update border glow based on mode - MUCH MORE VISIBLE
    if CityGuideConfig.useTooltips then
        -- Tooltip mode: Bright Blue/cyan glow
        buttonContainer:SetBackdropBorderColor(0.2, 0.6, 1, 1)
        buttonContainer.modeGlow:SetVertexColor(0.3, 0.8, 1, 1)
    else
        -- Text mode: Bright Orange/amber glow
        buttonContainer:SetBackdropBorderColor(1, 0.6, 0.2, 1)
        buttonContainer.modeGlow:SetVertexColor(1, 0.7, 0.2, 1)
    end
    
    -- Play flash animation when mode changes
    if buttonContainer.flashAnim then
        buttonContainer.flashAnim:Stop()
        buttonContainer.flashAnim:Play()
    end

    -- First-time UX tutorial
    CityGuide_TryShowTutorial()

    buttonContainer:Show()
end

-- Function to hide the map button
function CityGuide_HideMapButton()
    if buttonContainer then
        buttonContainer:Hide()
    end
    CityGuide_HideTutorial()
end

-- Function to hide profession filter button (kept for compatibility)
function CityGuide_HideProfFilterButton()
    -- No longer needed, handled by hiding container
end