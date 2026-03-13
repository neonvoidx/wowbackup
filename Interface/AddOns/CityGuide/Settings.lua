-- Simple Settings Launcher Panel
-- This just shows a button to open the standalone settings window

-- Store city themes globally for standalone window
CityGuideSettings = CityGuideSettings or {}
CityGuideSettings.cityThemes = {
    [2393] = {r1=0.8, g1=0.1, b1=0.1, r2=0.4, g2=0.05, b2=0.05, name="Silvermoon", icon="Interface\\Icons\\Inv_misc_tournaments_banner_bloodelf"},
    [2339] = {r1=0.3, g1=0.2, b1=0.1, r2=0.15, g2=0.1, b2=0.05, name="Dornogal", icon="Interface\\Icons\\Ability_earthen_wideeyedwonder"},
    [2472] = {r1=0.2, g1=0.3, b1=0.5, r2=0.1, g2=0.15, b2=0.3, name="Tazavesh", icon="Interface\\Icons\\inv_achievement_raidnerubian_etherealassasin"},
    [2112] = {r1=0.1, g1=0.3, b1=0.5, r2=0.05, g2=0.15, b2=0.3, name="Valdrakken", icon="Interface\\AddOns\\CityGuide\\Icons\\rostrum"},
    [627] = {r1=0.4, g1=0.2, b1=0.5, r2=0.2, g2=0.1, b2=0.3, name="Dalaran", icon="Interface\\Icons\\Spell_Arcane_PortalDalaran"},
    [85] = {r1=0.6, g1=0.1, b1=0.1, r2=0.3, g2=0.05, b2=0.05, name="Orgrimmar", icon="Interface\\Icons\\INV_BannerPVP_01"},
    [84] = {r1=0.1, g1=0.2, b1=0.5, r2=0.05, g2=0.1, b2=0.3, name="Stormwind", icon="Interface\\Icons\\INV_BannerPVP_02"},
}

-- Create simple launcher panel
local panel = CreateFrame("Frame", "CityGuideSettingsPanel", UIParent)
panel.name = "City Guide"

-- Title
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
title:SetPoint("TOP", 0, -40)
title:SetText("City Guide")
title:SetTextColor(1, 0.9, 0.5, 1)

-- Description
local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOP", title, "BOTTOM", 0, -20)
desc:SetText("Displays important NPCs on capital city maps")

-- Info text
local infoText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
infoText:SetPoint("TOP", desc, "BOTTOM", 0, -40)
infoText:SetText("Click the button below to open the settings window,")
infoText:SetTextColor(0.8, 0.8, 0.8)

local infoText2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
infoText2:SetPoint("TOP", infoText, "BOTTOM", 0, -5)
infoText2:SetText("or use the command:")
infoText2:SetTextColor(0.8, 0.8, 0.8)

-- Command text
local commandText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
commandText:SetPoint("TOP", infoText2, "BOTTOM", 0, -15)
commandText:SetText("|cff00ff00/cg settings|r")

-- Open Settings Button
local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
openButton:SetSize(200, 40)
openButton:SetPoint("TOP", commandText, "BOTTOM", 0, -30)
openButton:SetText("Open Settings Window")
openButton:SetNormalFontObject("GameFontNormalLarge")

openButton:SetScript("OnClick", function()
    CityGuide_ToggleStandaloneSettings()
end)

-- Button glow effect
local btnGlow = openButton:CreateTexture(nil, "BACKGROUND")
btnGlow:SetPoint("CENTER")
btnGlow:SetSize(220, 60)
btnGlow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
btnGlow:SetBlendMode("ADD")
btnGlow:SetVertexColor(1, 0.9, 0.5, 0)

openButton:SetScript("OnEnter", function(self)
    btnGlow:SetAlpha(0.3)
end)

openButton:SetScript("OnLeave", function(self)
    btnGlow:SetAlpha(0)
end)

-- Additional commands info
local commandsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
commandsTitle:SetPoint("TOP", openButton, "BOTTOM", 0, -40)
commandsTitle:SetText("Other useful commands:")
commandsTitle:SetTextColor(0.8, 0.8, 0.8)

local commandsList = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
commandsList:SetPoint("TOP", commandsTitle, "BOTTOM", 0, -10)
commandsList:SetText(
    "|cff00ff00/cg toggle|r - Cycle display modes\n" ..
    "|cff00ff00/cg prof|r - Toggle profession filter\n" ..
    "|cff00ff00/cg decor|r - Toggle decor POIs"
)
commandsList:SetSpacing(4)

-- Register the panel
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(panel)
end