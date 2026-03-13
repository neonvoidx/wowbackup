-- Map Button UI

local mapButton = nil

-- Function to create/update the map button
function MapLabels_CreateOrUpdateMapButton()
    -- Create button if it doesn't exist
    if not mapButton then
        mapButton = CreateFrame("Button", "MapLabelsToggleButton", WorldMapFrame.BorderFrame, "UIPanelButtonTemplate")
        mapButton:SetSize(120, 22)
        
        -- Try to position to the left of the ? button, fallback to bottom-right if not available
        if WorldMapFrame.SidePanelToggle and WorldMapFrame.SidePanelToggle.CloseButton then
            mapButton:SetPoint("RIGHT", WorldMapFrame.SidePanelToggle.CloseButton, "LEFT", -5, 0)
        else
            -- Fallback position if the close button doesn't exist yet
            mapButton:SetPoint("BOTTOMRIGHT", WorldMapFrame.BorderFrame, "BOTTOMRIGHT", -10, 10)
        end
        
        -- Button click handler - cycles through modes
        mapButton:SetScript("OnClick", function()
            -- Cycle through modes
            if MapLabelsConfig.displayMode == "labels" then
                MapLabelsConfig.displayMode = "icons"
            elseif MapLabelsConfig.displayMode == "icons" then
                MapLabelsConfig.displayMode = "both"
            else
                MapLabelsConfig.displayMode = "labels"
            end
            
            MapLabels_CreateOrUpdateMapButton() -- Update button text
            MapLabels_UpdateMapLabels()
            print("|cff00ff00Map Labels:|r Switched to " .. MapLabelsConfig.displayMode .. " mode!")
        end)
        
        -- Tooltip
        mapButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Map Labels Display Mode")
            GameTooltip:AddLine("Click to cycle through display modes", 1, 1, 1)
            GameTooltip:Show()
        end)
        
        mapButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Update button text based on current mode
    if MapLabelsConfig.displayMode == "labels" then
        mapButton:SetText("Labels Only")
    elseif MapLabelsConfig.displayMode == "icons" then
        mapButton:SetText("Icons Only")
    else -- both
        mapButton:SetText("Icons + Labels")
    end
    
    mapButton:Show()
end