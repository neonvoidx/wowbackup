-- Slash Commands for City Guide

-- Coordinate capture helper
local function CaptureCoordinates(npcName, iconPath)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        print("|cffff0000Error:|r Could not get map ID")
        return
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        print("|cffff0000Error:|r Could not get position")
        return
    end

    local x, y = position:GetXY()
    x = x * 100
    y = y * 100

    local output
    if iconPath then
        output = string.format('x = %.2f / 100, \ny = %.2f / 100, \nname = "%s", icon = "%s",', x, y, npcName, iconPath)
    else
        output = string.format('x = %.2f / 100, \ny = %.2f / 100, \nname = "%s", icon = "ICON_PATH_HERE",', x, y, npcName)
    end

    print("|cff00ff00Coordinate captured!|r")
    print(output)

    if not CityGuideCopyFrame then
        CityGuideCopyFrame = CreateFrame("Frame", "CityGuideCopyFrame", UIParent, "BasicFrameTemplateWithInset")
        CityGuideCopyFrame:SetSize(600, 120)
        CityGuideCopyFrame:SetPoint("CENTER")
        CityGuideCopyFrame:Hide()
        CityGuideCopyFrame:SetMovable(true)
        CityGuideCopyFrame:EnableMouse(true)
        CityGuideCopyFrame:RegisterForDrag("LeftButton")
        CityGuideCopyFrame:SetScript("OnDragStart", CityGuideCopyFrame.StartMoving)
        CityGuideCopyFrame:SetScript("OnDragStop", CityGuideCopyFrame.StopMovingOrSizing)

        CityGuideCopyFrame.title = CityGuideCopyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        CityGuideCopyFrame.title:SetPoint("TOP", 0, -5)
        CityGuideCopyFrame.title:SetText("Copy Coordinates (Ctrl+A, Ctrl+C)")

        local scrollFrame = CreateFrame("ScrollFrame", nil, CityGuideCopyFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(550)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function()
            CityGuideCopyFrame:Hide()
        end)

        scrollFrame:SetScrollChild(editBox)
        CityGuideCopyFrame.editBox = editBox
    end

    CityGuideCopyFrame.editBox:SetText(output)
    CityGuideCopyFrame.editBox:HighlightText()
    CityGuideCopyFrame:Show()
end

-- Slash command for coordinate capture (coordinates only)
local function HandleCoordsOnly()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        print("|cffff0000Error:|r Could not get map ID")
        return
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        print("|cffff0000Error:|r Could not get position")
        return
    end

    local x, y = position:GetXY()
    x = x * 100
    y = y * 100

    local output = string.format('x = %.2f / 100, \ny = %.2f / 100,', x, y)

    print("|cff00ff00Coordinates captured!|r")
    print(output)

    if not CityGuideCoordsFrame then
        CityGuideCoordsFrame = CreateFrame("Frame", "CityGuideCoordsFrame", UIParent, "BasicFrameTemplateWithInset")
        CityGuideCoordsFrame:SetSize(400, 100)
        CityGuideCoordsFrame:SetPoint("CENTER")
        CityGuideCoordsFrame:Hide()
        CityGuideCoordsFrame:SetMovable(true)
        CityGuideCoordsFrame:EnableMouse(true)
        CityGuideCoordsFrame:RegisterForDrag("LeftButton")
        CityGuideCoordsFrame:SetScript("OnDragStart", CityGuideCoordsFrame.StartMoving)
        CityGuideCoordsFrame:SetScript("OnDragStop", CityGuideCoordsFrame.StopMovingOrSizing)

        CityGuideCoordsFrame.title = CityGuideCoordsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        CityGuideCoordsFrame.title:SetPoint("TOP", 0, -5)
        CityGuideCoordsFrame.title:SetText("Copy Coordinates (Ctrl+A, Ctrl+C)")

        local scrollFrame = CreateFrame("ScrollFrame", nil, CityGuideCoordsFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(250)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function()
            CityGuideCoordsFrame:Hide()
        end)

        scrollFrame:SetScrollChild(editBox)
        CityGuideCoordsFrame.editBox = editBox
    end

    CityGuideCoordsFrame.editBox:SetText(output)
    CityGuideCoordsFrame.editBox:HighlightText()
    CityGuideCoordsFrame:Show()
end

local function HandleZoneID()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local mapInfo = C_Map.GetMapInfo(mapID)
        local mapName = mapInfo and mapInfo.name or "Unknown"

        if not CityGuideZoneIDFrame then
            CityGuideZoneIDFrame = CreateFrame("Frame", "CityGuideZoneIDFrame", UIParent, "BasicFrameTemplateWithInset")
            CityGuideZoneIDFrame:SetSize(300, 100)
            CityGuideZoneIDFrame:SetPoint("CENTER")
            CityGuideZoneIDFrame:Hide()
            CityGuideZoneIDFrame:SetMovable(true)
            CityGuideZoneIDFrame:EnableMouse(true)
            CityGuideZoneIDFrame:RegisterForDrag("LeftButton")
            CityGuideZoneIDFrame:SetScript("OnDragStart", CityGuideZoneIDFrame.StartMoving)
            CityGuideZoneIDFrame:SetScript("OnDragStop", CityGuideZoneIDFrame.StopMovingOrSizing)
            
            CityGuideZoneIDFrame.title = CityGuideZoneIDFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            CityGuideZoneIDFrame.title:SetPoint("TOP", 0, -5)
            CityGuideZoneIDFrame.title:SetText("Copy Map ID (Ctrl+A, Ctrl+C)")
            
            local scrollFrame = CreateFrame("ScrollFrame", nil, CityGuideZoneIDFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 10, -30)
            scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
            
            local editBox = CreateFrame("EditBox", nil, scrollFrame)
            editBox:SetMultiLine(true)
            editBox:SetFontObject(ChatFontNormal)
            editBox:SetWidth(250)
            editBox:SetAutoFocus(false)
            editBox:SetScript("OnEscapePressed", function()
                CityGuideZoneIDFrame:Hide()
            end)
            
            scrollFrame:SetScrollChild(editBox)
            CityGuideZoneIDFrame.editBox = editBox
        end
        
        CityGuideZoneIDFrame.editBox:SetText(tostring(mapID))
        CityGuideZoneIDFrame.editBox:HighlightText()
        CityGuideZoneIDFrame:Show()
    else
        print("|cffff0000Error:|r Could not get map info")
    end
end

-- Main slash command handler
local function HandleSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "both" then
        CityGuideConfig.displayMode = "both"
        print("|cff00ff00City Guide:|r Icons with labels enabled!")
        CityGuide_UpdateMapLabels()
    elseif cmd == "icons" or cmd == "icon" then
        CityGuideConfig.displayMode = "icons"
        print("|cff00ff00City Guide:|r Icons only mode!")
        CityGuide_UpdateMapLabels()
    elseif cmd == "labels" or cmd == "label" then
        CityGuideConfig.displayMode = "labels"
        print("|cff00ff00City Guide:|r Labels only mode!")
        CityGuide_UpdateMapLabels()
    elseif cmd == "toggle" then
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
        print("|cff00ff00City Guide:|r Switched to " .. CityGuideConfig.displayMode .. " mode!")
    elseif cmd == "prof" then
        CityGuideConfig.filterByProfession = not CityGuideConfig.filterByProfession
        print("|cff00ff00City Guide:|r Profession filter " .. (CityGuideConfig.filterByProfession and "enabled" or "disabled"))
        CityGuide_UpdateMapLabels()
    elseif cmd == "decor" then
        CityGuideConfig.showDecorPOIs = not CityGuideConfig.showDecorPOIs
        print("|cff00ff00City Guide:|r Decor POIs " .. (CityGuideConfig.showDecorPOIs and "shown" or "hidden"))
        CityGuide_UpdateMapLabels()
    elseif cmd == "widget" then
        CityGuideConfig.showMapWidget = not CityGuideConfig.showMapWidget
        print("|cff00ff00City Guide:|r Map widget " .. (CityGuideConfig.showMapWidget and "shown" or "hidden"))
        CityGuide_UpdateMapLabels()
    elseif cmd == "labelsize" then
        local size = tonumber(arg)
        if size and size >= 0.5 and size <= 2.0 then
            CityGuideConfig.labelSize = size
            print("|cff00ff00City Guide:|r Label size set to " .. string.format("%.1fx", size))
            CityGuide_UpdateMapLabels()
        else
            print("|cffff0000City Guide:|r Invalid size. Use a number between 0.5 and 2.0")
            print("|cffaaaaaa Example: /cg labelsize 1.5")
        end
    elseif cmd == "iconsize" then
        local size = tonumber(arg)
        if size and size >= 0.5 and size <= 2.0 then
            CityGuideConfig.iconSize = size
            print("|cff00ff00City Guide:|r Icon size set to " .. string.format("%.1fx", size))
            CityGuide_UpdateMapLabels()
        else
            print("|cffff0000City Guide:|r Invalid size. Use a number between 0.5 and 2.0")
            print("|cffaaaaaa Example: /cg iconsize 1.2")
        end
    elseif cmd == "resetsize" then
        CityGuideConfig.labelSize = 1.0
        CityGuideConfig.iconSize = 1.0
        print("|cff00ff00City Guide:|r Sizes reset to default (1.0x)")
        CityGuide_UpdateMapLabels()
    elseif cmd == "settings" or cmd == "config" or cmd == "options" then
        -- Open standalone settings window
        CityGuide_ToggleStandaloneSettings()
    -- Dev commands (hidden from help)
    elseif cmd == "capture" then
        if arg and arg ~= "" then
            local npcName, iconPath = arg:match("^(.-)%s*,%s*(.+)$")
            if not npcName or npcName == "" then
                npcName = arg:trim()
            end
            CaptureCoordinates(npcName, iconPath)
        else
            print("|cffaaaaaa Usage: /cg capture <n> [, icon path]")
        end
    elseif cmd == "coords" then
        HandleCoordsOnly()
    elseif cmd == "zoneid" then
        HandleZoneID()
    else
        print("|cff00ff00City Guide Commands:|r")
        print("/cg settings - Open settings window")
        print("/cg labels - Show labels only")
        print("/cg icons - Show icons only")
        print("/cg both - Show icons with labels")
        print("/cg toggle - Cycle through modes")
        print("/cg prof - Toggle profession filter")
        print("/cg decor - Toggle decor POIs")
        print("/cg widget - Toggle map widget buttons")
        print("/cg labelsize <0.5-2.0> - Set label size")
        print("/cg iconsize <0.5-2.0> - Set icon size")
        print("/cg resetsize - Reset sizes to default")
    end
end

-- Register slash commands
SLASH_CITYGUIDE1 = "/cityguide"
SLASH_CITYGUIDE2 = "/cg"
SlashCmdList["CITYGUIDE"] = HandleSlashCommand