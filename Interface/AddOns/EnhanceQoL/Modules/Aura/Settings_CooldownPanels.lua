local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not (cat and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Cooldown Panels"] or "Cooldown Panels",
	description = L["configCenterPageDescCooldownPanels"]
		or "Create and manage custom cooldown panels, then edit tracked abilities, layout and visibility in the panel editor.",
	newTagID = "CooldownPanels",
	iconKey = "cooldownpanels",
	modernCategory = "suites",
	expanded = false,
	colorizeTitle = false,
})

local function withCooldownPanels(action)
	local panels = addon.Aura and addon.Aura.CooldownPanels
	if not panels then return end
	action(panels)
end

local function openEditorExclusively(panels)
	if not (panels and panels.OpenEditor) then return end
	local editorFrame = panels:OpenEditor()
	if addon.functions.HideConfigCenterUntilFrameHidden then
		addon.functions.HideConfigCenterUntilFrameHidden(editorFrame)
	end
end

addon.functions.SettingsCreateButton(cat, {
	text = L["CooldownPanelOpenEditor"] or "Open Cooldown Panel Editor",
	func = function()
		withCooldownPanels(function(panels)
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(cat, {
	text = L["Add Panel"] or "Add Panel",
	func = function()
		withCooldownPanels(function(panels)
			local panelId = panels:CreatePanel(L["CooldownPanelNewPanel"] or "New Panel")
			if panelId then panels:SelectPanel(panelId) end
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})
