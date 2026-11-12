local addon = _G.EnhanceQoL
local QC = addon.QuickCast
local Q = {}
QC.QuestItems = Q

function QC:GetQuestItemManagedActions()
	local actions, seen = {}, {}
	local container, item, questLog = _G.C_Container, _G.C_Item, _G.C_QuestLog
	if not (container and item and container.GetContainerNumSlots and container.GetContainerItemID and container.GetContainerItemQuestInfo and item.GetItemSpell) then return nil end
	local function add(itemID)
		if not itemID or seen[itemID] then return end
		seen[itemID] = true
		actions[#actions + 1] = { kind = "item", id = itemID, managedSource = self.MANAGED_SOURCE_QUEST_ITEMS, managedKey = "item:" .. itemID }
	end
	local isCompleted = questLog and questLog.IsQuestFlaggedCompleted or _G.IsQuestFlaggedCompleted
	local isTBC = addon.variables and addon.variables.isTBC
	for bag = 0, (_G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4) do
		for slot = 1, container.GetContainerNumSlots(bag) do
			local itemID = container.GetContainerItemID(bag, slot)
			if itemID then
				local info = container.GetContainerItemQuestInfo(bag, slot)
				local questItem = info and info.isQuestItem
				if isTBC and item.GetItemInfoInstant and _G.Enum and _G.Enum.ItemClass then
					questItem = questItem or select(6, item.GetItemInfoInstant(itemID)) == _G.Enum.ItemClass.Questitem
				end
				local starter = info and info.questID and not info.isActive and isCompleted and not isCompleted(info.questID)
				if starter or (questItem and item.GetItemSpell(itemID)) then
					add(itemID)
				elseif questItem and item.IsItemDataCachedByID and not item.IsItemDataCachedByID(itemID) and item.RequestLoadItemDataByID then
					item.RequestLoadItemDataByID(itemID)
				end
			end
		end
	end
	local getCount = questLog and questLog.GetNumQuestLogEntries or _G.GetNumQuestLogEntries
	if getCount and _G.GetQuestLogSpecialItemInfo then
		for index = 1, getCount() do
			local info = questLog and questLog.GetInfo and questLog.GetInfo(index)
			local complete, header
			if info then
				header = info.isHeader
				complete = not header and questLog.IsComplete and questLog.IsComplete(info.questID)
			elseif _G.GetQuestLogTitle then
				local _, _, _, isHeader, _, isComplete = _G.GetQuestLogTitle(index)
				header, complete = isHeader, isComplete == true or isComplete == 1
			end
			if not header then
				local link, _, _, showWhenComplete = _G.GetQuestLogSpecialItemInfo(index)
				if link and (not complete or showWhenComplete) then add(tonumber(link:match("item:(%d+)"))) end
			end
		end
	end
	table.sort(actions, function(a, b) return a.id < b.id end)
	return actions
end

function Q:IsEnabled()
	local config = QC:GetConfig()
	for _, menuID in ipairs(config.order or {}) do
		local menu = config.menus and config.menus[menuID]
		if menu and menu.managedSources and menu.managedSources[QC.MANAGED_SOURCE_QUEST_ITEMS] then return true end
	end
	return false
end

function Q:OnEvent()
	if self.pending or not self:IsEnabled() then return end
	self.pending = true
	_G.C_Timer.After(0.1, function()
		self.pending = nil
		if self:IsEnabled() then QC:QueueManagedSourceSync() end
	end)
end

Q.frame = _G.CreateFrame("Frame")
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
	Q.frame:RegisterEvent(event)
end
Q.frame:SetScript("OnEvent", function() Q:OnEvent() end)
