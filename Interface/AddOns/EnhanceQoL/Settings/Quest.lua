local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function applyParentSection(entries, section)
	for _, entry in ipairs(entries or {}) do
		entry.parentSection = section
		if entry.children then applyParentSection(entry.children, section) end
	end
end

local function NormalizeQuestAutomationModifier(value)
	if value == "SHIFT" or value == "CTRL" or value == "ALT" or value == "NONE" then return value end
	return nil
end

local cQuest = addon.SettingsLayout.rootGAMEPLAY
addon.SettingsLayout.questCategory = cQuest

local questingExpandable = addon.functions.SettingsCreateExpandableSection(cQuest, {
	name = L["QuestingAndCinematics"] or "Questing & Cinematics",
	newTagID = "Questing",
	iconKey = "questing",
	expanded = false,
	colorizeTitle = false,
	modernOnly = true,
})

local REMOVE_IGNORED_QUEST_NPC_DIALOG = addonName .. "QuestIgnoredNPCRemove"

local function GetIgnoredQuestNPCs(resetInvalid)
	if not addon.db then return nil end
	if type(addon.db["ignoredQuestNPC"]) ~= "table" then
		if resetInvalid then addon.db["ignoredQuestNPC"] = {} end
		return resetInvalid and addon.db["ignoredQuestNPC"] or nil
	end
	return addon.db["ignoredQuestNPC"]
end

local function ShowRemoveIgnoredQuestNPCDialog(selectionKey)
	if not selectionKey or selectionKey == "" then return end
	local ignored = GetIgnoredQuestNPCs()
	if not ignored then return end

	local npcID = tonumber(selectionKey) or selectionKey
	local npcName = ignored[npcID]
	if not npcName then
		local asString = tostring(selectionKey)
		if ignored[asString] then
			npcID = asString
			npcName = ignored[asString]
		end
	end
	if not npcName then return end

	StaticPopupDialogs[REMOVE_IGNORED_QUEST_NPC_DIALOG] = StaticPopupDialogs[REMOVE_IGNORED_QUEST_NPC_DIALOG]
		or {
			text = L["ignoredQuestNPCRemoveConfirm"],
			button1 = ACCEPT,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}

	StaticPopupDialogs[REMOVE_IGNORED_QUEST_NPC_DIALOG].OnAccept = function(_, data)
		local ignoredNPCs = GetIgnoredQuestNPCs()
		if not data or data == "" or not ignoredNPCs then return end
		if ignoredNPCs[data] then ignoredNPCs[data] = nil end
		local numericID = tonumber(data)
		if numericID and ignoredNPCs[numericID] then ignoredNPCs[numericID] = nil end
		local stringKey = tostring(data)
		if ignoredNPCs[stringKey] then ignoredNPCs[stringKey] = nil end
	end

	StaticPopup_Show(REMOVE_IGNORED_QUEST_NPC_DIALOG, npcName or tostring(npcID), nil, npcID)
end

local function IsAutomaticGossipEnabled()
	return addon.SettingsLayout.elements["autoChooseGossip"]
		and addon.SettingsLayout.elements["autoChooseGossip"].setting
		and addon.SettingsLayout.elements["autoChooseGossip"].setting:GetValue() == true
end

local AUTO_GOSSIP_CONTEXT_DEFAULTS = {
	world = true,
	delve = true,
	scenario = true,
	dungeonFollower = true,
	dungeonNormal = true,
	dungeonHeroic = true,
	dungeonMythic = true,
	dungeonMythicPlus = true,
	dungeonTimewalking = true,
	raidLfr = true,
	raidStory = true,
	raidNormal = true,
	raidHeroic = true,
	raidMythic = true,
	raidTimewalking = true,
	pvp = true,
	other = true,
}

local AUTO_GOSSIP_CONTEXT_OPTIONS = {
	{ value = "world", text = WORLD },
	{ value = "delve", text = DELVES_LABEL or L["combatLogDelve"] },
	{ value = "scenario", text = SCENARIOS or L["combatLogScenario"] },
	{ value = "dungeonFollower", text = _G.LFG_TYPE_FOLLOWER_DUNGEON or L["autoGossipContextFollowerDungeon"] },
	{ value = "dungeonNormal", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY1 },
	{ value = "dungeonHeroic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY2 },
	{ value = "dungeonMythic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY6 },
	{ value = "dungeonMythicPlus", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_MYTHIC_PLUS },
	{ value = "dungeonTimewalking", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
	{ value = "raidLfr", text = RAID .. " - " .. PLAYER_DIFFICULTY3 },
	{ value = "raidStory", text = RAID .. " - " .. (_G.PLAYER_DIFFICULTY_STORY_RAID or L["autoGossipContextStory"]) },
	{ value = "raidNormal", text = RAID .. " - " .. PLAYER_DIFFICULTY1 },
	{ value = "raidHeroic", text = RAID .. " - " .. PLAYER_DIFFICULTY2 },
	{ value = "raidMythic", text = RAID .. " - " .. PLAYER_DIFFICULTY6 },
	{ value = "raidTimewalking", text = RAID .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
	{ value = "pvp", text = PVP },
	{ value = "other", text = L["autoGossipContextOther"] },
}

local function FormatGossipOptionLabel(name, gossipOptionID)
	if name and name ~= "" then return ("%s (%s)"):format(name, tostring(gossipOptionID)) end
	return ("ID: %s"):format(tostring(gossipOptionID))
end

local function GetSortedActiveGossipOptions()
	local options = C_GossipInfo and C_GossipInfo.GetOptions and C_GossipInfo.GetOptions() or {}
	table.sort(options, function(leftInfo, rightInfo) return leftInfo.orderIndex < rightInfo.orderIndex end)
	return options
end

local function GetAutoGossipIDs(resetInvalid)
	if not addon.db then return nil end
	if type(addon.db.autogossipID) ~= "table" then
		if resetInvalid then addon.db.autogossipID = {} end
		return resetInvalid and addon.db.autogossipID or nil
	end
	return addon.db.autogossipID
end

local function BuildActiveGossipOptionList()
	local list = {}
	local order = {}
	local saved = GetAutoGossipIDs() or {}
	local options = GetSortedActiveGossipOptions()
	for _, optionInfo in ipairs(options) do
		local gossipOptionID = optionInfo.gossipOptionID
		if gossipOptionID and not saved[gossipOptionID] and not saved[tostring(gossipOptionID)] then
			local key = tostring(gossipOptionID)
			if not list[key] then
				list[key] = FormatGossipOptionLabel(addon.functions.getGossipOptionDisplayName(optionInfo), gossipOptionID)
				order[#order + 1] = key
			end
		end
	end
	if #order == 0 then
		list[""] = L["autoGossipNoAddOptions"]
		order[1] = ""
	end
	return list, order
end

local function BuildSavedGossipOptionList()
	local list = {}
	local order = {}
	local activeNames = {}
	local activeOrder = {}
	local saved = GetAutoGossipIDs() or {}
	local options = GetSortedActiveGossipOptions()
	for _, optionInfo in ipairs(options) do
		if optionInfo.gossipOptionID then
			local key = tostring(optionInfo.gossipOptionID)
			activeNames[key] = addon.functions.getGossipOptionDisplayName(optionInfo)
			activeOrder[key] = optionInfo.orderIndex
			if saved[optionInfo.gossipOptionID] or saved[key] then addon.functions.storeAutoGossipInfo(optionInfo) end
		end
	end
	local infoByID = addon.functions.getAutoGossipInfo() or {}
	for gossipOptionID, enabled in pairs(saved) do
		if enabled then
			local key = tostring(gossipOptionID)
			if not list[key] then
				local info = infoByID[gossipOptionID] or infoByID[tonumber(gossipOptionID)]
				local optionText = activeNames[key] or (type(info) == "table" and info.optionText)
				local npcName = type(info) == "table" and info.npcName
				local displayName = optionText
				if npcName and npcName ~= "" then
					displayName = optionText and optionText ~= "" and (npcName .. " — " .. optionText) or npcName
				end
				list[key] = FormatGossipOptionLabel(displayName, gossipOptionID)
				order[#order + 1] = key
			end
		end
	end
	table.sort(order, function(left, right)
		local leftOrder = activeOrder[left]
		local rightOrder = activeOrder[right]
		if leftOrder and rightOrder and leftOrder ~= rightOrder then return leftOrder < rightOrder end
		if leftOrder ~= nil and rightOrder == nil then return true end
		if leftOrder == nil and rightOrder ~= nil then return false end
		local leftID = tonumber(left)
		local rightID = tonumber(right)
		if leftID and rightID then return leftID < rightID end
		return left < right
	end)
	if #order == 0 then
		list[""] = L["autoGossipNoSavedOptions"]
		order[1] = ""
	end
	return list, order
end

local questingData = {
	{
		var = "autoChooseQuest",
		text = L["autoChooseQuest"],
		desc = L["autoChooseQuestDesc"],
		richNote = {
			blocks = {
				{ text = "|cff99e599" .. L["ignoreNPCTipp"] .. "|r" },
			},
		},
		func = function(key) addon.db["autoChooseQuest"] = key end,
		default = false,
		children = {
			{
				var = "autoChooseQuestModifier",
				text = L["questAutomationModifier"] or "Quest automation modifier",
				desc = L["questAutomationModifierDesc"],
				listFunc = function()
					return {
						NONE = NONE,
						SHIFT = SHIFT_KEY_TEXT,
						CTRL = CTRL_KEY_TEXT,
						ALT = ALT_KEY_TEXT,
					}
				end,
				get = function() return addon.db and addon.db.autoChooseQuestModifier or "NONE" end,
				set = function(key)
					if not key or key == "" then key = "NONE" end
					addon.db["autoChooseQuestModifier"] = key
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
				sType = "dropdown",
			},
			{
				var = "ignoreDailyQuests",
				text = L["ignoreDailyQuests"]:format(QUESTS_LABEL),
				desc = L["ignoreDailyQuestsDesc"],
				func = function(key) addon.db["ignoreDailyQuests"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreGoldCostQuests",
				text = L["ignoreGoldCostQuests"],
				desc = L["ignoreGoldCostQuestsDesc"],
				func = function(key) addon.db["ignoreGoldCostQuests"] = key end,
				default = false,
				newTagID = "ignoreGoldCostQuests",
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreCurrencyCostQuests",
				text = L["ignoreCurrencyCostQuests"],
				desc = L["ignoreCurrencyCostQuestsDesc"],
				func = function(key) addon.db["ignoreCurrencyCostQuests"] = key end,
				default = false,
				newTagID = "ignoreCurrencyCostQuests",
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreWarbandCompleted",
				text = L["ignoreWarbandCompleted"]:format(ACCOUNT_COMPLETED_QUEST_LABEL, QUESTS_LABEL),
				desc = L["ignoreWarbandCompletedDesc"],
				func = function(key) addon.db["ignoreWarbandCompleted"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreTrivialQuests",
				text = L["ignoreTrivialQuests"]:format(QUESTS_LABEL),
				desc = L["ignoreTrivialQuestsDesc"],
				func = function(key) addon.db["ignoreTrivialQuests"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				listFunc = function()
					local tList = { [""] = "" }
					for id, name in pairs(GetIgnoredQuestNPCs() or {}) do
						tList[id] = name
					end
					return tList
				end,
				text = REMOVE,
				get = function() return "" end,
				set = function(key)
					if not key or key == "" then return end
					ShowRemoveIgnoredQuestNPCDialog(key)
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
				var = "ignoredQuestNPC",
				type = Settings.VarType.Number,
				sType = "dropdown",
			},
		},
	},
	{
		var = "questWowheadLink",
		text = L["questWowheadLink"],
		desc = L["questWowheadLinkDesc"],
		func = function(key) addon.db["questWowheadLink"] = key end,
		default = false,
	},
}

local gossipData = {
	{
		var = "autoChooseGossip",
		groupID = "Gossip",
		groupTitle = L["gossipSettingsHeadline"],
		text = L["autoChooseGossip"],
		desc = L["autoChooseGossipDesc"],
		richNote = {
			blocks = {
				{ text = "|cff99e599" .. L["ignoreNPCTipp"] .. "|r" },
			},
		},
		func = function(key) addon.db["autoChooseGossip"] = key end,
		default = false,
		newTagID = "autoChooseGossip",
		children = {
			{
				var = "autoChooseGossipModifier",
				text = L["gossipAutomationModifier"],
				desc = L["gossipAutomationModifierDesc"],
				listFunc = function()
					return {
						NONE = NONE,
						SHIFT = SHIFT_KEY_TEXT,
						CTRL = CTRL_KEY_TEXT,
						ALT = ALT_KEY_TEXT,
					}
				end,
				get = function() return addon.db and addon.db.autoChooseGossipModifier or "NONE" end,
				set = function(key)
					if not key or key == "" then key = "NONE" end
					addon.db["autoChooseGossipModifier"] = key
				end,
				parentCheck = IsAutomaticGossipEnabled,
				parent = true,
				newTagID = "autoChooseGossipModifier",
				sType = "dropdown",
			},
			{
				var = "autoChooseGossipContexts",
				text = L["autoGossipContexts"],
				desc = L["autoGossipContextsDesc"],
				options = AUTO_GOSSIP_CONTEXT_OPTIONS,
				parentCheck = IsAutomaticGossipEnabled,
				parent = true,
				newTagID = "autoChooseGossipContexts",
				sType = "multidropdown",
			},
		},
	},
	{
		id = "autoGossipAdd",
		var = "autoGossipAdd",
		groupID = "Gossip",
		groupTitle = L["gossipSettingsHeadline"],
		key = false,
		storage = false,
		text = ADD,
		desc = L["autoGossipAddDesc"],
		listFunc = BuildActiveGossipOptionList,
		get = function() return "" end,
		set = function(key)
			local gossipOptionID = tonumber(key)
			if not gossipOptionID then return false end
			local saved = GetAutoGossipIDs(true)
			saved[gossipOptionID] = true
			for _, optionInfo in ipairs(GetSortedActiveGossipOptions()) do
				if optionInfo.gossipOptionID == gossipOptionID then
					addon.functions.storeAutoGossipInfo(optionInfo)
					break
				end
			end
			print(ADD, "ID:", gossipOptionID)
			return true
		end,
		default = "",
		newTagID = "autoGossipAdd",
		trackCustomized = false,
		sType = "dropdown",
	},
	{
		id = "autoGossipRemove",
		var = "autoGossipRemove",
		groupID = "Gossip",
		groupTitle = L["gossipSettingsHeadline"],
		key = false,
		storage = false,
		text = REMOVE,
		desc = L["autoGossipRemoveDesc"],
		listFunc = BuildSavedGossipOptionList,
		get = function() return "" end,
		set = function(key)
			local gossipOptionID = tonumber(key)
			if not gossipOptionID then return false end
			local saved = GetAutoGossipIDs(true)
			saved[gossipOptionID] = nil
			saved[tostring(gossipOptionID)] = nil
			local infoByID = addon.functions.getAutoGossipInfo()
			if infoByID then
				infoByID[gossipOptionID] = nil
				infoByID[tostring(gossipOptionID)] = nil
			end
			print(REMOVE, "ID:", gossipOptionID)
			return true
		end,
		default = "",
		newTagID = "autoGossipRemove",
		trackCustomized = false,
		sType = "dropdown",
	},
}

local cinematicData = {
	{
		var = "autoCancelCinematic",
		text = L["autoCancelCinematic"],
		desc = L["autoCancelCinematicDesc"],
		func = function(value)
			addon.db["autoCancelCinematic"] = value and true or false
			if value then
				addon.db["quickSkipCinematic"] = false
				local quickSetting = addon.SettingsLayout.elements and addon.SettingsLayout.elements["quickSkipCinematic"]
				if quickSetting and quickSetting.setting then quickSetting.setting:SetValue(false) end
			end
		end,
		default = false,
	},
	{
		var = "quickSkipCinematic",
		text = L["quickSkipCinematic"],
		desc = L["quickSkipCinematicDesc"],
		func = function(value)
			addon.db["quickSkipCinematic"] = value and true or false
			if value then
				addon.db["autoCancelCinematic"] = false
				local autoSetting = addon.SettingsLayout.elements and addon.SettingsLayout.elements["autoCancelCinematic"]
				if autoSetting and autoSetting.setting then autoSetting.setting:SetValue(false) end
			end
		end,
		default = false,
	},
}

addon.functions.SettingsCreateHeadline(cQuest, L["Questing"], { parentSection = questingExpandable })
applyParentSection(questingData, questingExpandable)
addon.functions.SettingsCreateCheckboxes(cQuest, questingData)

addon.functions.SettingsCreateHeadline(cQuest, L["gossipSettingsHeadline"], {
	parentSection = questingExpandable,
	groupID = "Gossip",
	groupTitle = L["gossipSettingsHeadline"],
})
applyParentSection(gossipData, questingExpandable)
addon.functions.SettingsCreateCheckbox(cQuest, gossipData[1])
addon.functions.SettingsCreateDropdown(cQuest, gossipData[2])
addon.functions.SettingsCreateDropdown(cQuest, gossipData[3])

addon.functions.SettingsCreateHeadline(cQuest, L["Cinematics"], { parentSection = questingExpandable })
applyParentSection(cinematicData, questingExpandable)
addon.functions.SettingsCreateCheckboxes(cQuest, cinematicData)

----- REGION END

function addon.functions.initQuest()
	if addon.db then
		if addon.db.autoChooseQuest == nil then
			if addon.db.autoAcceptQuest == true or addon.db.autoTurnInQuest == true then addon.db.autoChooseQuest = true end
		end
		if addon.db.autoChooseQuestModifier == nil then
			local modifiers = {}
			if addon.db.autoAcceptQuest == true then table.insert(modifiers, NormalizeQuestAutomationModifier(addon.db.autoAcceptQuestModifier) or "NONE") end
			if addon.db.autoTurnInQuest == true then table.insert(modifiers, NormalizeQuestAutomationModifier(addon.db.autoTurnInQuestModifier) or "NONE") end
			if #modifiers == 0 then
				local fallbackModifiers = {
					NormalizeQuestAutomationModifier(addon.db.autoAcceptQuestModifier),
					NormalizeQuestAutomationModifier(addon.db.autoTurnInQuestModifier),
				}
				for _, modifier in ipairs(fallbackModifiers) do
					if modifier then
						addon.db.autoChooseQuestModifier = modifier
						break
					end
				end
			end
			if addon.db.autoChooseQuestModifier == nil then
				local selectedModifier = "NONE"
				for _, modifier in ipairs(modifiers) do
					if modifier ~= "NONE" then
						if selectedModifier == "NONE" or selectedModifier == modifier then
							selectedModifier = modifier
						else
							selectedModifier = "SHIFT"
							break
						end
					end
				end
				addon.db.autoChooseQuestModifier = selectedModifier
			end
		end
		if addon.db.autoChooseGossip == nil then
			if addon.db.autoGossip ~= nil then
				addon.db.autoChooseGossip = addon.db.autoGossip == true
			else
				addon.db.autoChooseGossip = addon.db.autoChooseQuest == true
			end
		end
		if addon.db.autoChooseGossipModifier == nil then
			addon.db.autoChooseGossipModifier = NormalizeQuestAutomationModifier(addon.db.autoGossipModifier)
				or NormalizeQuestAutomationModifier(addon.db.autoChooseQuestModifier)
				or "NONE"
		end
		if addon.db.ignoreDailyQuests == nil then
			addon.db.ignoreDailyQuests = (type(addon.db.questAutomationFiltersAccept) == "table" and addon.db.questAutomationFiltersAccept.daily == true)
				or (type(addon.db.questAutomationFiltersTurnIn) == "table" and addon.db.questAutomationFiltersTurnIn.daily == true)
				or false
		end
		if addon.db.ignoreTrivialQuests == nil then
			addon.db.ignoreTrivialQuests = (type(addon.db.questAutomationFiltersAccept) == "table" and addon.db.questAutomationFiltersAccept.trivial == true)
				or (type(addon.db.questAutomationFiltersTurnIn) == "table" and addon.db.questAutomationFiltersTurnIn.trivial == true)
				or false
		end
		if addon.db.ignoreWarbandCompleted == nil then
			addon.db.ignoreWarbandCompleted = (type(addon.db.questAutomationFiltersAccept) == "table" and addon.db.questAutomationFiltersAccept.warband == true)
				or (type(addon.db.questAutomationFiltersTurnIn) == "table" and addon.db.questAutomationFiltersTurnIn.warband == true)
				or false
		end
	end

	addon.functions.InitDBValue("autoChooseQuest", false)
	addon.functions.InitDBValue("autoChooseQuestModifier", "NONE")
	addon.functions.InitDBValue("autoChooseGossip", false)
	addon.functions.InitDBValue("autoChooseGossipModifier", "NONE")
	addon.functions.InitDBValue("autoChooseGossipContexts", AUTO_GOSSIP_CONTEXT_DEFAULTS)
	addon.functions.InitDBValue("ignoreTrivialQuests", false)
	addon.functions.InitDBValue("ignoreDailyQuests", false)
	addon.functions.InitDBValue("ignoreGoldCostQuests", false)
	addon.functions.InitDBValue("ignoreCurrencyCostQuests", false)
	addon.functions.InitDBValue("ignoreWarbandCompleted", false)
	addon.functions.InitDBValue("questWowheadLink", false)
	addon.functions.InitDBValue("ignoredQuestNPC", {})
	GetIgnoredQuestNPCs(true)
	addon.functions.InitDBValue("autogossipID", {})
	GetAutoGossipIDs(true)
	addon.functions.InitDBValue("autogossipInfo", {})
	addon.functions.getAutoGossipInfo(true)
	if addon.db then addon.db.testOwner = nil end


	local function EQOL_GetQuestIDFromMenu(owner, ctx)
		if ctx and (ctx.questID or ctx.questId) then return ctx.questID or ctx.questId end

		if owner then
			if owner.questID then return owner.questID end
			if owner.GetQuestID then
				local ok, id = pcall(owner.GetQuestID, owner)
				if ok and id then return id end
			end
			if owner.questLogIndex and C_QuestLog and C_QuestLog.GetInfo then
				local info = C_QuestLog.GetInfo(owner.questLogIndex)
				if info and info.questID then return info.questID end
			end
		end
		return nil
	end

	local function EQOL_ShowCopyURL(url)
		if not StaticPopupDialogs["ENHANCEQOL_COPY_URL"] then
			StaticPopupDialogs["ENHANCEQOL_COPY_URL"] = {
					text = L["copyUrlPopupText"],
				button1 = OKAY,
				hasEditBox = true,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
				OnShow = function(self, data)
					local eb = self.editBox or self.GetEditBox and self:GetEditBox()
					eb:SetAutoFocus(true)
					eb:SetText(data or "")
					eb:HighlightText()
					eb:SetCursorPosition(0)
				end,
				OnAccept = function(self) end,
				EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
			}
		end
		StaticPopup_Show("ENHANCEQOL_COPY_URL", nil, nil, url)
	end

	local function EQOL_AddQuestWowheadEntry(owner, root, ctx)
		if not addon.db["questWowheadLink"] then return end
		local qid
		if owner.GetName and owner:GetName() == "ObjectiveTrackerFrame" then
			local mFocus = GetMouseFoci()
			if mFocus and mFocus[1] and mFocus[1].GetParent then
				local pInfo = mFocus[1]:GetParent()
				if pInfo.poiQuestID then
					qid = pInfo.poiQuestID
				else
					return
				end
			end
		else
			qid = EQOL_GetQuestIDFromMenu(owner, ctx)
		end
		if not qid then return end
		root:CreateDivider()
		local btn = root:CreateButton(L["CopyWowheadURL"], function() EQOL_ShowCopyURL(("https://www.wowhead.com/quest=%d"):format(qid)) end)
		btn:AddInitializer(function()
			btn:SetTooltip(function(tt)
				GameTooltip_SetTitle(tt, L["wowhead"])
				GameTooltip_AddNormalLine(tt, ("quest=%d"):format(qid))
			end)
		end)
	end

	-- Register for Blizzard's menu tags (provided by /etrace):
	if Menu and Menu.ModifyMenu then
		Menu.ModifyMenu("MENU_QUEST_MAP_LOG_TITLE", EQOL_AddQuestWowheadEntry)
		Menu.ModifyMenu("MENU_QUEST_OBJECTIVE_TRACKER", EQOL_AddQuestWowheadEntry)
	end

	if Menu and Menu.ModifyMenu then
		local function GetNPCIDFromGUID(guid)
			if type(guid) == "nil" then return end
			if type(guid) ~= "nil" and issecretvalue(guid) then return nil end
			if guid then
				local type, _, _, _, _, npcID = strsplit("-", guid)
				if type == "Creature" or type == "Vehicle" then return tonumber(npcID) end
			end
			return nil
		end

		local function AddIgnoreAutoQuest(owner, root, ctx)
			if not addon.db["autoChooseQuest"] and not addon.db["autoChooseGossip"] then return end
			if addon.functions.isRestrictedContent() then return end

			if not UnitExists("target") or UnitPlayerControlled("target") then return end
			local guid = UnitGUID("target")
			if issecretvalue(guid) then return end
			local npcID = GetNPCIDFromGUID(guid)
			if not npcID then return end
			if issecretvalue and issecretvalue(npcID) then return end
			local name = UnitName("target")
			if not name or (issecretvalue and issecretvalue(name)) then return end

			root:CreateDivider()
			root:CreateTitle(addonName)
			local ignoredNPCs = GetIgnoredQuestNPCs(true)
			if ignoredNPCs[npcID] then
				root:CreateButton(L["SettingsQuestHeaderIgnoredNPCRemove"], function(id) ignoredNPCs[id] = nil end, npcID)
			else
				root:CreateButton(L["SettingsQuestHeaderIgnoredNPCAdd"], function(id) ignoredNPCs[id] = name end, npcID)
			end
		end

		Menu.ModifyMenu("MENU_UNIT_TARGET", AddIgnoreAutoQuest)
	end

end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
