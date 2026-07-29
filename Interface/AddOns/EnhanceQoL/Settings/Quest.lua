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

addon.functions.SettingsCreateHeadline(cQuest, L["Cinematics"], { parentSection = questingExpandable })
applyParentSection(cinematicData, questingExpandable)
addon.functions.SettingsCreateCheckboxes(cQuest, cinematicData)

----- REGION END

function addon.functions.initQuest()
	if addon.db then
		if addon.db.autoChooseQuest == nil then
			if addon.db.autoAcceptQuest == true or addon.db.autoTurnInQuest == true or addon.db.autoGossip == true then addon.db.autoChooseQuest = true end
		end
		if addon.db.autoChooseQuestModifier == nil then
			local modifiers = {}
			if addon.db.autoAcceptQuest == true then table.insert(modifiers, NormalizeQuestAutomationModifier(addon.db.autoAcceptQuestModifier) or "NONE") end
			if addon.db.autoTurnInQuest == true then table.insert(modifiers, NormalizeQuestAutomationModifier(addon.db.autoTurnInQuestModifier) or "NONE") end
			if addon.db.autoGossip == true then table.insert(modifiers, NormalizeQuestAutomationModifier(addon.db.autoGossipModifier) or "NONE") end
			if #modifiers == 0 then
				local fallbackModifiers = {
					NormalizeQuestAutomationModifier(addon.db.autoAcceptQuestModifier),
					NormalizeQuestAutomationModifier(addon.db.autoTurnInQuestModifier),
					NormalizeQuestAutomationModifier(addon.db.autoGossipModifier),
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
	addon.functions.InitDBValue("ignoreTrivialQuests", false)
	addon.functions.InitDBValue("ignoreDailyQuests", false)
	addon.functions.InitDBValue("ignoreGoldCostQuests", false)
	addon.functions.InitDBValue("ignoreCurrencyCostQuests", false)
	addon.functions.InitDBValue("ignoreWarbandCompleted", false)
	addon.functions.InitDBValue("questWowheadLink", false)
	addon.functions.InitDBValue("ignoredQuestNPC", {})
	GetIgnoredQuestNPCs(true)
	addon.functions.InitDBValue("autogossipID", {})
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
			if not addon.db["autoChooseQuest"] then return end
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
