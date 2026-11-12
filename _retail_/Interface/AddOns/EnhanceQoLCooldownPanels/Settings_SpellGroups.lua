local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local app = addon.ConfigApp
local CDP = addon.Aura and addon.Aura.CooldownPanels
if not (app and CDP and CDP.SpellGroupsEditor) then return end

local pageID = addon.functions.RegisterSpellsActionsGroup("spellgroups", L["CDLSpellGroupsTitle"], 20)
if not pageID then return end

app:RegisterControl(pageID, {
	groupID = "spellgroups",
	groupTitle = L["CDLSpellGroupsTitle"],
	id = "spellgroups.openEditor",
	type = "button",
	label = L["CDLSpellGroupsOpenEditor"],
	buttonText = L["CDLSpellGroupsOpenEditor"],
	newTagID = "SpellGroupsOpenEditor",
	order = 10,
	onClick = function()
		local frame = CDP:OpenSpellGroupsEditor()
		if frame and addon.functions and addon.functions.HideConfigCenterUntilFrameHidden then addon.functions.HideConfigCenterUntilFrameHidden(frame) end
	end,
})

app:RegisterControl(pageID, {
	groupID = "spellgroups",
	groupTitle = L["CDLSpellGroupsTitle"],
	id = "spellgroups.editorMacroHint",
	type = "inlinehint",
	label = string.format(L["EditorMacroHint"], "/eqol spellgroups"),
	order = 20,
})
