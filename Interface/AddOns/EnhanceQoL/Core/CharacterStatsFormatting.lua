local addonName, addon = ...

addon.CharacterStatsFormatting = addon.CharacterStatsFormatting or {}
local CharacterStatsFormatting = addon.CharacterStatsFormatting

local function disableFeature()
	if addon.db then addon.db.characterStatsFormattingEnabled = false end
end

-- Temporarily disabled in 12.0.5 because formatting stat rows can receive
-- secret values from PaperDollFrame and must not run in tainted addon code.
function CharacterStatsFormatting.Enable() disableFeature() end

function CharacterStatsFormatting.Disable() disableFeature() end

function CharacterStatsFormatting.Refresh() disableFeature() end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		CharacterStatsFormatting.Refresh()
		return
	end
	if event == "ADDON_LOADED" and (name == "Blizzard_CharacterUI" or name == "Blizzard_UIPanels_Game") then CharacterStatsFormatting.Refresh() end
end)
