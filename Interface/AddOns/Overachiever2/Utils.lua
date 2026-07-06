-- Overachiever2: Utils
-- General utility functions and constants
-- Exposed globally via Overachiever2.Utils for cross-module access.

local appName, ns = ...

local Utils = Overachiever2.Utils

-- Colors (AARRGGBB)
Utils.WhiteColor = "ffffffff"
Utils.BlizzardGreenColor = "ff7eff00"
Utils.BlizzardRedColor = "ffff3D3D"
Utils.BlizzardGoldColor = "ffffd200"
Utils.RedColor = "ffff0000"
Utils.GreenColor = "ff00ff00"
Utils.BlueColor = "ff0000ff"
Utils.GrayColor = "ff868686"
Utils.DarkGrayColor = "ff404040"
Utils.BlizzardLegendaryColor = select(4, C_Item.GetItemQualityColor(Enum.ItemQuality.Legendary))
Utils.BlizzardEpicColor = select(4, C_Item.GetItemQualityColor(Enum.ItemQuality.Epic))
Utils.BlizzardRareColor = select(4, C_Item.GetItemQualityColor(Enum.ItemQuality.Rare))
Utils.BlizzardUncommonColor = select(4, C_Item.GetItemQualityColor(Enum.ItemQuality.Uncommon))
Utils.BlizzardCommonColor = select(4, C_Item.GetItemQualityColor(Enum.ItemQuality.Common))

Utils.DebugIconPath = "Interface\\HelpFrame\\HelpIcon-Bug"
Utils.AchievementIconPath = "Interface\\Icons\\Achievement_General"

function Utils.IsDebugMode()
    return Overachiever2_Settings and Overachiever2_Settings.Debug
end

function Utils.WhiteText(text)
    return "|c" .. Utils.WhiteColor .. text .. "|r"
end

function Utils.BlizzardGreenText(text)
    return "|c" .. Utils.BlizzardGreenColor .. text .. "|r"
end

function Utils.BlizzardRedText(text)
    return "|c" .. Utils.BlizzardRedColor .. text .. "|r"
end

function Utils.BlizzardGoldText(text)
    return "|c" .. Utils.BlizzardGoldColor .. text .. "|r"
end

function Utils.RedText(text)
    return "|c" .. Utils.RedColor .. text .. "|r"
end

function Utils.GreenText(text)
    return "|c" .. Utils.GreenColor .. text .. "|r"
end

function Utils.BlueText(text)
    return "|c" .. Utils.BlueColor .. text .. "|r"
end

function Utils.GrayText(text)
    return "|c" .. Utils.GrayColor .. text .. "|r"
end

function Utils.DarkGrayText(text)
    return "|c" .. Utils.DarkGrayColor .. text .. "|r"
end

function Utils.BlizzardLegendaryColorText(text)
    return "|c" .. Utils.BlizzardLegendaryColor .. text .. "|r"
end

function Utils.BlizzardEpicColorText(text)
    return "|c" .. Utils.BlizzardEpicColor .. text .. "|r"
end

function Utils.BlizzardRareColorText(text)
    return "|c" .. Utils.BlizzardRareColor .. text .. "|r"
end

function Utils.BlizzardUncommonColorText(text)
    return "|c" .. Utils.BlizzardUncommonColor .. text .. "|r"
end

function Utils.BlizzardCommonColorText(text)
    return "|c" .. Utils.BlizzardCommonColor .. text .. "|r"
end

function Utils.DebugIconText()
    return "|T" .. Utils.DebugIconPath .. ":0|t"
end

function Utils.AchievementIconText()
    return "|T" .. Utils.AchievementIconPath .. ":0|t"
end

function Utils.AchievementIconSpacerText()
    return "|T" .. Utils.AchievementIconPath .. ":0::::256:256:0:0:0:0|t"
end

function Utils.DotIconText()
    return "•"
end

function Utils.CheckAtlasText()
    return "|A:common-icon-checkmark:12:12|a"
end

function Utils.RedxAtlasText()
    return "|A:common-icon-redx:12:12|a"
end

-- EditBox Helper
-- Creates a labeled EditBox with standard sizing and positioning.
-- parent: parent frame, labelText: label string, anchorTo: anchor frame,
-- xOffset/yOffset: optional point offsets (defaults: 0, -23)
function Utils.CreateEditBox(parent, labelText, anchorTo, xOffset, yOffset)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetSize(170, 16)
    editBox:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset or 0, yOffset or -23)

    local label = editBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", -6, 4)
    label:SetText(labelText)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetAutoFocus(false)
        self:ClearFocus()
    end)

    return editBox
end

-- Global Message Helper
function Utils.Print(msg)
    print(Utils.BlizzardGreenText(appName .. ":") .. " " .. msg)
end

function Utils.PrintDebug(msg)
    if Utils.IsDebugMode() then print(Utils.BlizzardRedText(appName .. ":") .. " " .. msg) end
end

function Utils.ColorByType(val)
    local t = type(val)
    if t == "number" then
        return Utils.BlizzardGoldText(tostring(val))
    elseif t == "boolean" then
        return (val and Utils.GreenText("true") or Utils.RedText("false"))
    elseif t == "string" then
        return Utils.WhiteText("\"" .. val .. "\"")
    else
        return Utils.DarkGrayText(tostring(val))
    end
end

-- Shared private tooltip frame for everything Overachiever2 owns.
-- Living in Utils.lua (loaded before Core/History/Tooltips per the .toc) so every
-- consumer can take `local OA2Tooltip = Utils.OA2Tooltip` and avoid touching the
-- global GameTooltip, which would taint its layout state and trip
-- LayoutFrame.lua "secret number" errors on AreaPOI/world-quest tooltips.
-- WoWUIBugs #811: https://github.com/Stanzilla/WoWUIBugs/issues/811
Utils.OA2Tooltip = CreateFrame("GameTooltip", "Overachiever2Tooltip", UIParent, "GameTooltipTemplate")
Utils.OA2Tooltip:SetFrameStrata("TOOLTIP")
-- Keep the tooltip on-screen vertically. ShowSidecar handles the horizontal
-- anchor flip itself, so clamping only nudges the bottom edge here.
Utils.OA2Tooltip:SetClampedToScreen(true)

-- Small button-hover helpers built on Utils.OA2Tooltip.
-- Use these for any plain "title + optional secondary lines" tooltip; route
-- richer achievement tooltips through TooltipSetAchievementCommon in Tooltips.lua.
function Utils.ShowTip(owner, anchor, title, ...)
    local tip = Utils.OA2Tooltip
    tip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    tip:SetText(title, 1, 1, 1)
    for i = 1, select("#", ...) do
        local line = select(i, ...)
        if line then tip:AddLine(line, nil, nil, nil, true) end
    end
    tip:Show()
end

function Utils.HideTip()
    Utils.OA2Tooltip:Hide()
end
