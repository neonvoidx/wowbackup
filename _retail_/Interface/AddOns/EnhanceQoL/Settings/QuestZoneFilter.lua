local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local QF = { modules = {}, names = { "QuestObjectiveTracker", "CampaignQuestObjectiveTracker" } }
addon.QuestZoneFilter = QF

function QF.Enabled()
	return QF.active == true
end

function QF.Pinned(questID)
	local pins = addon.db and addon.db.questTrackerZonePins
	return type(pins) == "table" and pins[questID] == true
end

function QF.ReadZone()
	QF.quests = nil
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	-- Micro maps use their containing map; dungeon maps keep their own quest POIs.
	for _ = 1, 8 do
		local info = C_Map.GetMapInfo(mapID)
		if not info or info.mapType ~= Enum.UIMapType.Micro or not info.parentMapID or info.parentMapID == 0 then break end
		mapID = info.parentMapID
	end
	local quests = C_QuestLog.GetQuestsOnMap(mapID)
	if not quests then return end
	QF.quests = {}
	for _, info in ipairs(quests) do
		QF.quests[info.questID] = true
	end
end

function QF.Refresh()
	if not QF.Enabled() then return end
	if InCombatLockdown() then
		return
	end
	QF.ReadZone()
	for _, name in ipairs(QF.names) do
		local tracker = _G[name]
		if tracker then
			local state = QF.modules[tracker]
			if not state then
				state = { original = tracker.BuildQuestWatchInfos }
				state.filter = function(self)
					local infos = state.original(self)
					if not QF.quests then return infos end
					for i = #infos, 1, -1 do
						local questID = infos[i].quest:GetID()
						if not QF.quests[questID] and not QF.Pinned(questID) then table.remove(infos, i) end
					end
					return infos
				end
				QF.modules[tracker] = state
				tracker.BuildQuestWatchInfos = state.filter
			end
			if tracker.MarkDirty then tracker:MarkDirty() end
		end
	end
end

function QF.QueueRefresh()
	if not QF.Enabled() or QF.queued then return end
	QF.queued = true
	RunNextFrame(function()
		QF.queued = nil
		QF.Refresh()
	end)
end

function QF.MenuQuestID(owner, context)
	if context and context.questID then return context.questID end
	if owner and owner.questID then return owner.questID end
	-- Tracker menus belong to the container, while the clicked header belongs to a quest block.
	for _, focus in ipairs(GetMouseFoci()) do
		local frame = focus
		for _ = 1, 8 do
			if not frame then break end
			if frame.parentModule and (frame.parentModule == _G.QuestObjectiveTracker or frame.parentModule == _G.CampaignQuestObjectiveTracker) then return frame.id end
			frame = frame.GetParent and frame:GetParent()
		end
	end
end

function QF.AddMenu(owner, root, context)
	if not QF.Enabled() then return end
	local questID = QF.MenuQuestID(owner, context)
	if not questID then return end
	root:CreateDivider()
	root:CreateCheckbox(L["questTrackerZoneAlwaysShow"], function() return QF.Pinned(questID) end, function()
		if type(addon.db.questTrackerZonePins) ~= "table" then addon.db.questTrackerZonePins = {} end
		local pinned = not QF.Pinned(questID)
		addon.db.questTrackerZonePins[questID] = pinned or nil
		-- Pinning from the quest log also starts normal tracking; unpinning only removes the exception.
		if pinned and C_QuestLog.GetQuestWatchType(questID) == nil then C_QuestLog.AddQuestWatch(questID) end
		QF.QueueRefresh()
	end)
end

function QF.Init()
	if not (addon.db and addon.db.questTrackerZoneFilter == true) then
		if QF.active then
			-- Runtime registrations remain active until reload, including menu modifications.
			addon.variables.requireReload = true
			if addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
		end
		return
	end
	QF.active = true
	if not QF.watcher then
		QF.watcher = CreateFrame("Frame")
		for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "QUEST_POI_UPDATE", "QUEST_LOG_UPDATE", "PLAYER_REGEN_ENABLED", "ADDON_LOADED" }) do
			QF.watcher:RegisterEvent(event)
		end
		QF.watcher:SetScript("OnEvent", function(_, event, name)
			if event == "ADDON_LOADED" and name ~= "Blizzard_ObjectiveTracker" then return end
			QF.QueueRefresh()
		end)
		Menu.ModifyMenu("MENU_QUEST_OBJECTIVE_TRACKER", QF.AddMenu)
		Menu.ModifyMenu("MENU_QUEST_MAP_LOG_TITLE", QF.AddMenu)
	end
	QF.QueueRefresh()
end

function QF.RegisterSettings(category, expandable)
	addon.functions.SettingsCreateCheckbox(category, {
		var = "questTrackerZoneFilter",
		text = L["questTrackerZoneFilter"],
		desc = L["questTrackerZoneFilter_desc"],
		newTagID = "questTrackerZoneFilter",
		parentSection = expandable,
		default = false,
		func = function(value)
			addon.db.questTrackerZoneFilter = value and true or false
			QF.Init()
		end,
	})
end
