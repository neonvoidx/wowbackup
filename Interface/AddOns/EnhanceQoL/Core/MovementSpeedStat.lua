local addonName, addon = ...

local STAT_TOKEN = "MOVESPEED"
addon.MovementSpeedStat = {}

local function removeInjectedStat()
	local categories = PAPERDOLL_STATCATEGORIES
	if not categories then return nil end

	for _, category in ipairs(categories) do
		if category.stats then
			for index = #category.stats, 1, -1 do
				local entry = category.stats[index]
				if type(entry) == "table" then
					if entry.stat == STAT_TOKEN then table.remove(category.stats, index) end
				elseif entry == STAT_TOKEN then
					table.remove(category.stats, index)
				end
			end
		end
	end
end

local function disableFeature()
	removeInjectedStat()
	if addon.db then addon.db.movementSpeedStatEnabled = false end
end

-- Temporarily disabled in 12.0.5 because PaperDoll movement speed now
-- participates in secret-value handling and our stat injection taints it.
function addon.MovementSpeedStat.Enable() disableFeature() end

function addon.MovementSpeedStat.Disable() disableFeature() end

function addon.MovementSpeedStat.Refresh() disableFeature() end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		addon.MovementSpeedStat.Refresh()
	elseif event == "ADDON_LOADED" and (name == "Blizzard_CharacterUI" or name == "Blizzard_UIPanels_Game") then
		addon.MovementSpeedStat.Refresh()
	end
end)
