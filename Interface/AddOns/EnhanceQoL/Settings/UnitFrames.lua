local _, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local cUnitFrame = addon.SettingsLayout and addon.SettingsLayout.rootUI

if cUnitFrame and addon.functions and addon.functions.SettingsCreateExpandableSection and not addon.SettingsLayout.expUnitFrames then
	addon.SettingsLayout.expUnitFrames = addon.functions.SettingsCreateExpandableSection(cUnitFrame, {
		name = UNITFRAME_LABEL,
		description = L["configCenterPageDescUnitFrames"],
		iconKey = "unitframes",
		expanded = false,
		colorizeTitle = false,
		newTagID = "UnitFrames",
	})
end
