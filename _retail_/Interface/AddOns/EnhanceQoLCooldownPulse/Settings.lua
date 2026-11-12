local addon = _G.EnhanceQoL
local P = addon.CooldownPulse
local L = P.L
local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not cat then return end
local section = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["CooldownPulse"], configPageKey = "CooldownPulse", description = L["CooldownPulseDescription"], newTagID = "CooldownPulse",
	iconKey = "cooldownpanels", modernCategory = "interface", expanded = false, colorizeTitle = false,
})
addon.functions.SettingsCreateText(cat, "|cff99e599" .. L["CooldownPulseDescription"] .. "|r", { parentSection = section })
addon.functions.SettingsCreateButton(cat, {
	text = L["CooldownPulseOpenEditor"], parentSection = section, func = function() P:OpenEditor() end,
})
if not P.classic then addon.functions.SettingsCreateText(cat, L["CooldownPulseChargeHint"], { parentSection = section }) end
