local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.variables = addon.MythicPlus.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local wipe = wipe

local function buildRuntimeOwnedSettings(cGameplay)
	local sectionDungeon = addon.SettingsLayout.gameplayDungeonsMythicSection
	if sectionDungeon then
		addon.functions.SettingsCreateHeadline(cGameplay, PLAYER_DIFFICULTY_MYTHIC_PLUS .. " & " .. RAID, { parentSection = sectionDungeon, order = 10 })

		local keystoneEnable = addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "enableKeystoneHelper",
			text = L["enableKeystoneHelper"],
			desc = L["enableKeystoneHelperDesc"],
			func = function(v)
				addon.db["enableKeystoneHelper"] = v
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.toggleFrame then addon.MythicPlus.functions.toggleFrame() end
			end,
			order = 10,
			parentSection = sectionDungeon,
		})
		local function isKeystoneEnabled() return keystoneEnable and keystoneEnable.setting and keystoneEnable.setting:GetValue() == true end

		local keystoneChildren = {
			{ var = "autoInsertKeystone", text = L["Automatically insert keystone"], func = function(v) addon.db["autoInsertKeystone"] = v end, order = 20, parentSection = sectionDungeon },
			{ var = "closeBagsOnKeyInsert", text = L["Close all bags on keystone insert"], func = function(v) addon.db["closeBagsOnKeyInsert"] = v end, order = 30, parentSection = sectionDungeon },
			{ var = "autoKeyStart", text = L["autoKeyStart"], func = function(v) addon.db["autoKeyStart"] = v end, order = 40, parentSection = sectionDungeon },
		}
		for _, entry in ipairs(keystoneChildren) do
			entry.parent = true
			entry.element = keystoneEnable.element
			entry.parentCheck = isKeystoneEnabled
			addon.functions.SettingsCreateCheckbox(cGameplay, entry)
		end

		local listPull, orderPull = addon.functions.prepareListForDropdown({
			[1] = _G.NONE,
			[2] = L["Blizzard Pull Timer"],
			[3] = L["DBM / BigWigs Pull Timer"],
			[4] = _G.STATUS_TEXT_BOTH,
		})
		addon.functions.SettingsCreateDropdown(cGameplay, {
			var = "PullTimerType",
			text = L["Pull Timer"],
			desc = L["PullTimerTypeDesc"],
			type = Settings.VarType.Number,
			default = 2,
			list = listPull,
			order = 50,
			orderList = orderPull,
			get = function() return (addon.db and addon.db["PullTimerType"]) or 1 end,
			set = function(value) addon.db["PullTimerType"] = value end,
			parent = true,
			element = keystoneEnable.element,
			parentCheck = isKeystoneEnabled,
			parentSection = sectionDungeon,
		})

		addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "noChatOnPullTimer",
			text = L["noChatOnPullTimer"],
			desc = L["noChatOnPullTimerDesc"],
			func = function(v) addon.db["noChatOnPullTimer"] = v end,
			order = 60,
			parent = true,
			element = keystoneEnable.element,
			parentCheck = isKeystoneEnabled,
			parentSection = sectionDungeon,
		})

		addon.functions.SettingsCreateSlider(cGameplay, {
			var = "pullTimerShortTime",
			text = L["sliderShortTime"],
			desc = L["pullTimerShortTimeDesc"],
			min = 0,
			max = 60,
			step = 1,
			default = 5,
			order = 80,
			get = function() return (addon.db and addon.db["pullTimerShortTime"]) or 5 end,
			set = function(val) addon.db["pullTimerShortTime"] = val end,
			parent = true,
			element = keystoneEnable.element,
			parentCheck = isKeystoneEnabled,
			parentSection = sectionDungeon,
		})

		local objEnable = addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "mythicPlusEnableObjectiveTracker",
			text = L["mythicPlusEnableObjectiveTracker"],
			desc = L["mythicPlusEnableObjectiveTrackerDesc"],
			func = function(v)
				addon.db["mythicPlusEnableObjectiveTracker"] = v
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then addon.MythicPlus.functions.setObjectiveFrames() end
			end,
			order = 90,
			parentSection = sectionDungeon,
		})
		local function isObjectiveEnabled() return objEnable and objEnable.setting and objEnable.setting:GetValue() == true end

		local objectiveTrackerDefaultScope = "dungeonMythicPlus"
		local objectiveTrackerScopeOptions = {
			{ value = "dungeonNormal", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY1 },
			{ value = "dungeonHeroic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY2 },
			{ value = "dungeonMythic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY6 },
			{ value = objectiveTrackerDefaultScope, text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_MYTHIC_PLUS },
			{ value = "dungeonTimewalking", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
			{ value = "raidLfr", text = RAID .. " - " .. PLAYER_DIFFICULTY3 },
			{ value = "raidNormal", text = RAID .. " - " .. PLAYER_DIFFICULTY1 },
			{ value = "raidHeroic", text = RAID .. " - " .. PLAYER_DIFFICULTY2 },
			{ value = "raidMythic", text = RAID .. " - " .. PLAYER_DIFFICULTY6 },
			{ value = "raidTimewalking", text = RAID .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
			{ value = "scenarioDelve", text = L["objectiveTrackerScopeScenarioDelve"] },
		}
		local function getObjectiveTrackerScopes()
			if type(addon.db["mythicPlusObjectiveTrackerScopes"]) ~= "table" then addon.db["mythicPlusObjectiveTrackerScopes"] = { [objectiveTrackerDefaultScope] = true } end
			return addon.db["mythicPlusObjectiveTrackerScopes"]
		end
		addon.functions.SettingsCreateMultiDropdown(cGameplay, {
			var = "mythicPlusObjectiveTrackerScopes",
			text = L["objectiveTrackerScope"],
			desc = L["objectiveTrackerScopeDesc"],
			options = objectiveTrackerScopeOptions,
			order = 100,
			get = getObjectiveTrackerScopes,
			set = function(value)
				addon.db["mythicPlusObjectiveTrackerScopes"] = type(value) == "table" and value or { [objectiveTrackerDefaultScope] = true }
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then addon.MythicPlus.functions.setObjectiveFrames() end
			end,
			parent = true,
			element = objEnable.element,
			parentCheck = isObjectiveEnabled,
			parentSection = sectionDungeon,
		})

		addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "mythicPlusBRTrackerEnabled",
			text = L["mythicPlusBRTrackerEnabled"],
			desc = L["mythicPlusBRTrackerEditModeHint"],
			func = function(v)
				addon.db["mythicPlusBRTrackerEnabled"] = v
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBRFrame then
					addon.MythicPlus.functions.createBRFrame()
				elseif addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then
					addon.MythicPlus.functions.setObjectiveFrames()
				end
			end,
			order = 110,
			parentSection = sectionDungeon,
		})

		addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "mythicPlusBloodlustTrackerEnabled",
			text = L["mythicPlusBloodlustTrackerEnabled"],
			desc = L["mythicPlusBloodlustTrackerEditModeHint"],
			func = function(v)
				addon.db["mythicPlusBloodlustTrackerEnabled"] = v
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.syncBloodlustUnitAuraRegistration then addon.MythicPlus.functions.syncBloodlustUnitAuraRegistration() end
				if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBloodlustFrame then
					addon.MythicPlus.functions.createBloodlustFrame()
					if addon.MythicPlus.functions.refreshBloodlustTracker then addon.MythicPlus.functions.refreshBloodlustTracker(false) end
				end
			end,
			order = 120,
			parentSection = sectionDungeon,
		})
	end

	local sectionGroupFinder = addon.SettingsLayout.gameplayGroupFinderSection
	if sectionGroupFinder then
		local groupFinderControlOrder = addon.SettingsLayout.gameplayGroupFinderControlOrder or {}
		addon.functions.SettingsCreateCheckbox(cGameplay, {
			var = "mythicPlusEnableDungeonFilter",
			text = L["mythicPlusEnableDungeonFilter"],
			desc = L["mythicPlusEnableDungeonFilterDesc"],
			func = function(v)
				addon.db["mythicPlusEnableDungeonFilter"] = v
				if addon.MythicPlus and addon.MythicPlus.functions then
					if v and addon.MythicPlus.functions.addDungeonFilter then
						addon.MythicPlus.functions.addDungeonFilter()
					elseif not v and addon.MythicPlus.functions.removeDungeonFilter then
						addon.MythicPlus.functions.removeDungeonFilter()
					end
				end
			end,
			order = groupFinderControlOrder.mythicPlusEnableDungeonFilter,
			parentSection = sectionGroupFinder,
			children = {
				{
					var = "mythicPlusEnableDungeonFilterClearReset",
					text = L["mythicPlusEnableDungeonFilterClearReset"],
					func = function(v) addon.db["mythicPlusEnableDungeonFilterClearReset"] = v end,
					parentCheck = function()
						return addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"]
							and addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"].setting
							and addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"].setting:GetValue() == true
					end,
					parent = true,
					order = groupFinderControlOrder.mythicPlusEnableDungeonFilter and groupFinderControlOrder.mythicPlusEnableDungeonFilter + 0.1 or nil,
					default = false,
					type = Settings.VarType.Boolean,
					sType = "checkbox",
					parentSection = sectionGroupFinder,
				},
			},
		})
	end
end

local function buildSettings()
	local cGameplay = addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY
	if not cGameplay then return end
	buildRuntimeOwnedSettings(cGameplay)

	local suitesCategory = nil
	local mythicPlusTimerSection = addon.SettingsLayout.suitesMythicPlusTimerSection
	if not mythicPlusTimerSection then
		mythicPlusTimerSection = addon.functions.SettingsCreateExpandableSection(suitesCategory, {
			name = L["mythicPlusTimerTitle"] or "Mythic+ Timer",
			configPageKey = "MythicPlusTimer",
			description = L["mythicPlusTimerEditModeHint"],
			iconKey = "dungeons",
			modernCategory = "suites",
			modernOnly = true,
			expanded = false,
			colorizeTitle = false,
			newTagID = "mythicPlusTimerEnabled",
		})
		addon.SettingsLayout.suitesMythicPlusTimerSection = mythicPlusTimerSection
	end

	addon.functions.SettingsCreateCheckbox(suitesCategory, {
		var = "mythicPlusTimerEnabled",
		text = L["mythicPlusTimerEnabled"],
		desc = L["mythicPlusTimerEditModeHint"],
		get = function()
			local config = type(addon.db.mythicPlusTimer) == "table" and addon.db.mythicPlusTimer or nil
			return config and config.enabled == true
		end,
		func = function(value)
			addon.db.mythicPlusTimer = type(addon.db.mythicPlusTimer) == "table" and addon.db.mythicPlusTimer or {}
			addon.db.mythicPlusTimer.enabled = value == true
			if addon.MythicPlus and addon.MythicPlus.MythicPlusTimer and addon.MythicPlus.MythicPlusTimer.UpdateEventState then addon.MythicPlus.MythicPlusTimer:UpdateEventState() end
		end,
		parentSection = mythicPlusTimerSection,
	})

	-- Talent Reminder
	local sectionTalent = addon.SettingsLayout.gameplayTalentReminderSection
	if not sectionTalent then
		sectionTalent = addon.functions.SettingsCreateExpandableSection(cGameplay, {
			name = L["TalentReminder"],
			configPageKey = "TalentReminder",
			description = L["TalentReminderDesc"],
			iconKey = "talentreminder",
			expanded = false,
			colorizeTitle = false,
			modernOnly = true,
			modernCategory = "gameplay",
			sortGroups = false,
		})
		addon.SettingsLayout.gameplayTalentReminderSection = sectionTalent
	end

	function addon.MythicPlus.functions.refreshTalentReminderSettings()
		local frame = addon.ConfigCenterFrame
		if not (frame and frame.IsShown and frame:IsShown()) then return end
		local state = frame._LibSettingsDesignerState
		if state and state.RenderContent then state:RenderContent() end
	end

	addon.MythicPlus.functions.getAllLoadouts()
	if #addon.MythicPlus.variables.seasonMapInfo == 0 then addon.MythicPlus.functions.createSeasonInfo() end

	local function ensureTalentSettings(specID)
		local guid = addon.variables.unitPlayerGUID
		if not guid or not specID then return end
		addon.db["talentReminderSettings"] = addon.db["talentReminderSettings"] or {}
		addon.db["talentReminderSettings"][guid] = addon.db["talentReminderSettings"][guid] or {}
		addon.db["talentReminderSettings"][guid][specID] = addon.db["talentReminderSettings"][guid][specID] or {}
		return addon.db["talentReminderSettings"][guid][specID]
	end

	local talentLoadoutOrders = {}
	local function buildTalentLoadoutList(specID, emptyLabel)
		local source = (specID and addon.MythicPlus.variables.knownLoadout and addon.MythicPlus.variables.knownLoadout[specID]) or {}
		local normalized = {}
		for key, value in pairs(source) do
			normalized[tostring(key)] = value
		end
		normalized["0"] = emptyLabel or ""
		local list, order = addon.functions.prepareListForDropdown(normalized)
		for index, key in ipairs(order) do
			if key == "0" then
				table.remove(order, index)
				break
			end
		end
		table.insert(order, 1, "0")
		local orderTarget = talentLoadoutOrders[specID]
		if orderTarget then
			wipe(orderTarget)
		else
			orderTarget = {}
			talentLoadoutOrders[specID] = orderTarget
		end
		for i, key in ipairs(order) do
			orderTarget[i] = key
		end
		return list
	end

	local talentSoundOptions = {}
	local talentSoundOrder = {}
	local talentSoundCacheVersion = -1
	local function buildTalentSoundOptions()
		local version = (addon.functions and addon.functions.GetLSMMediaVersion and addon.functions.GetLSMMediaVersion("sound")) or 0
		if talentSoundCacheVersion == version then return talentSoundOptions, talentSoundOrder end
		talentSoundCacheVersion = version

		local list, order
		if addon.functions and addon.functions.GetLSMMediaDropdown then
			list, order = addon.functions.GetLSMMediaDropdown("sound", false)
		else
			list, order = {}, {}
			local soundTable = (addon.ChatIM and addon.ChatIM.availableSounds) or {}
			for name in pairs(soundTable) do
				if type(name) == "string" and name ~= "" then
					list[name] = name
					order[#order + 1] = name
				end
			end
			table.sort(order, function(a, b)
				local al = string.lower(a)
				local bl = string.lower(b)
				if al == bl then return a < b end
				return al < bl
			end)
		end

		wipe(talentSoundOptions)
		for key, value in pairs(list or {}) do
			talentSoundOptions[key] = value
		end
		wipe(talentSoundOrder)
		for i = 1, #(order or {}) do
			talentSoundOrder[i] = order[i]
		end
		return talentSoundOptions, talentSoundOrder
	end

	addon.functions.SettingsCreateHeadline(cGameplay, SETTINGS, { parentSection = sectionTalent })

	local talentEnable = addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "talentReminderEnabled",
		text = L["talentReminderEnabled"],
		desc = L["talentReminderEnabledDesc"]:format(PLAYER_DIFFICULTY6, PLAYER_DIFFICULTY_MYTHIC_PLUS),
		func = function(v)
			addon.db["talentReminderEnabled"] = v
			addon.MythicPlus.functions.checkLoadout()
			addon.MythicPlus.functions.updateActiveTalentText()
		end,
		parentSection = sectionTalent,
	})
	local function isTalentReminderEnabled() return talentEnable and talentEnable.setting and talentEnable.setting:GetValue() == true end

	addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "talentReminderLoadOnReadyCheck",
		text = L["talentReminderLoadOnReadyCheck"]:format(READY_CHECK),
		desc = L["talentReminderLoadOnReadyCheckDesc"],
		func = function(v)
			addon.db["talentReminderLoadOnReadyCheck"] = v
			addon.MythicPlus.functions.checkLoadout()
		end,
		parent = true,
		element = talentEnable.element,
		parentCheck = isTalentReminderEnabled,
		parentSection = sectionTalent,
	})

	local soundDifference = addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "talentReminderSoundOnDifference",
		text = L["talentReminderSoundOnDifference"],
		desc = L["talentReminderSoundOnDifferenceDesc"],
		func = function(v)
			addon.db["talentReminderSoundOnDifference"] = v
			addon.MythicPlus.functions.checkLoadout()
		end,
		parent = true,
		element = talentEnable.element,
		parentCheck = isTalentReminderEnabled,
		parentSection = sectionTalent,
	})
	local function isSoundReminderEnabled() return soundDifference and soundDifference.setting and soundDifference.setting:GetValue() == true end

	local customSound = addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "talentReminderUseCustomSound",
		text = L["talentReminderUseCustomSound"],
		desc = L["talentReminderUseCustomSoundDesc"],
		func = function(v) addon.db["talentReminderUseCustomSound"] = v end,
		parent = true,
		element = soundDifference.element,
		parentCheck = function()
			return addon.SettingsLayout.elements["talentReminderEnabled"]
				and addon.SettingsLayout.elements["talentReminderEnabled"].setting
				and addon.SettingsLayout.elements["talentReminderEnabled"].setting:GetValue() == true
				and addon.SettingsLayout.elements["talentReminderSoundOnDifference"]
				and addon.SettingsLayout.elements["talentReminderSoundOnDifference"].setting
				and addon.SettingsLayout.elements["talentReminderSoundOnDifference"].setting:GetValue() == true
		end,
		parentSection = sectionTalent,
	})

	addon.functions.SettingsCreateSoundDropdown(cGameplay, {
		var = "talentReminderCustomSoundFile",
		text = L["talentReminderCustomSound"],
		desc = L["talentReminderCustomSoundFileDesc"],
		listFunc = buildTalentSoundOptions,
		order = talentSoundOrder,
		default = "",
		get = function()
			local value = addon.db["talentReminderCustomSoundFile"]
			return value ~= nil and value or ""
		end,
		set = function(value) addon.db["talentReminderCustomSoundFile"] = value end,
		callback = function(value)
			local soundTable = (addon.ChatIM and addon.ChatIM.availableSounds) or (addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("sound"))
			local file = soundTable and soundTable[value]
			if file then PlaySoundFile(file, "Master") end
		end,
		parent = true,
		element = customSound.element,
		parentCheck = function() return isTalentReminderEnabled() and isSoundReminderEnabled() and addon.db["talentReminderUseCustomSound"] == true end,
		parentSection = sectionTalent,
	})

	local showActiveBuild = addon.functions.SettingsCreateCheckbox(cGameplay, {
		var = "talentReminderShowActiveBuild",
		text = L["talentReminderShowActiveBuild"],
		desc = L["talentReminderShowActiveBuildDesc"],
		func = function(v)
			addon.db["talentReminderShowActiveBuild"] = v
			addon.MythicPlus.functions.updateActiveTalentText()
		end,
		parent = true,
		element = talentEnable.element,
		parentCheck = isTalentReminderEnabled,
		parentSection = sectionTalent,
	})

	addon.functions.SettingsAttachNotify(talentEnable.setting, "talentReminderSoundOnDifference")
	addon.functions.SettingsAttachNotify(talentEnable.setting, "talentReminderUseCustomSound")
	addon.functions.SettingsAttachNotify(soundDifference.setting, "talentReminderUseCustomSound")

	addon.functions.SettingsCreateText(cGameplay, "|cff99e599" .. L["talentReminderHint"]:format(CRF_EDIT_MODE) .. "|r", { parentSection = sectionTalent })

	if TalentLoadoutEx then
		addon.functions.SettingsCreateText(cGameplay, "|cffffd700" .. L["labelExplainedlineTLE"] .. "|r", { parentSection = sectionTalent })
		addon.functions.SettingsCreateButton(cGameplay, {
			var = "talentReminderReloadLoadouts",
			text = L["ReloadLoadouts"],
			func = function()
				addon.MythicPlus.functions.getAllLoadouts()
				addon.MythicPlus.functions.checkRemovedLoadout()
				addon.MythicPlus.functions.refreshTalentReminderSettings()
			end,
			parent = true,
			element = talentEnable.element,
			parentCheck = isTalentReminderEnabled,
			parentSection = sectionTalent,
		})
	end

	if #addon.MythicPlus.variables.specNames > 0 and #addon.MythicPlus.variables.seasonMapInfo > 0 then
		for _, specData in ipairs(addon.MythicPlus.variables.specNames) do
			local orderTable = talentLoadoutOrders[specData.value] or {}
			talentLoadoutOrders[specData.value] = orderTable
			addon.functions.SettingsCreateHeadline(cGameplay, specData.text, { parentSection = sectionTalent })
			addon.functions.SettingsCreateDropdown(cGameplay, {
				id = string.format("talentReminderDefault_%s", specData.value),
				var = string.format("talentReminderDefault_%s", specData.value),
				key = false,
				storage = false,
				text = L["talentReminderDefaultBuild"],
				desc = L["talentReminderDefaultBuildDesc"],
				type = Settings.VarType.String,
				default = "0",
				listFunc = function() return buildTalentLoadoutList(specData.value, _G.NONE or "None") end,
				order = orderTable,
				get = function()
					local specSettings = ensureTalentSettings(specData.value)
					local current = specSettings
						and addon.MythicPlus.functions.GetDefaultTalentReminderSetting
						and addon.MythicPlus.functions.GetDefaultTalentReminderSetting(specSettings)
					if type(current) == "number" then return tostring(current) end
					if current == nil then return "0" end
					return current
				end,
				set = function(value)
					local specSettings = ensureTalentSettings(specData.value)
					if not (specSettings and addon.MythicPlus.functions.SetDefaultTalentReminderSetting) then return end
					local converted = tonumber(value)
					addon.MythicPlus.functions.SetDefaultTalentReminderSetting(specSettings, converted ~= nil and converted or value)
					C_Timer.After(1, function() addon.MythicPlus.functions.checkLoadout() end)
				end,
				parent = true,
				element = talentEnable.element,
				parentCheck = isTalentReminderEnabled,
				parentSection = sectionTalent,
				newTagID = "talentReminderDefaultBuild",
			})
			for _, mapData in ipairs(addon.MythicPlus.variables.seasonMapInfo) do
				addon.functions.SettingsCreateDropdown(cGameplay, {
					var = string.format("talentReminder_%s_%s", specData.value, mapData.id),
					text = mapData.name,
					type = Settings.VarType.String,
					default = "0",
					listFunc = function() return buildTalentLoadoutList(specData.value, L["talentReminderUseDefault"]) end,
					customDefaultText = L["talentReminderUseDefault"],
					order = orderTable,
					get = function()
						local specSettings = ensureTalentSettings(specData.value)
						local current = specSettings
							and (
								addon.MythicPlus.functions.GetTalentReminderSetting and select(1, addon.MythicPlus.functions.GetTalentReminderSetting(specSettings, mapData.id))
								or specSettings[mapData.id]
							)
						if type(current) == "number" then return tostring(current) end
						if current == nil then return "0" end
						return current
					end,
					set = function(value)
						local specSettings = ensureTalentSettings(specData.value)
						if not specSettings then return end
						local converted = tonumber(value)
						if addon.MythicPlus.functions.SetTalentReminderSetting then
							addon.MythicPlus.functions.SetTalentReminderSetting(specSettings, mapData.id, converted ~= nil and converted or value)
						elseif converted ~= nil then
							specSettings[mapData.id] = converted
						else
							specSettings[mapData.id] = value
						end
						C_Timer.After(1, function() addon.MythicPlus.functions.checkLoadout() end)
					end,
					parent = true,
					element = talentEnable.element,
					parentCheck = isTalentReminderEnabled,
					parentSection = sectionTalent,
				})
			end
		end
	end
end

----- REGION END


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

function addon.MythicPlus.functions.InitSettings()
	if addon.MythicPlus.variables.settingsBuilt then return end
	if not addon.db or not addon.functions or not addon.functions.SettingsCreateCategory then return end
	if not addon.SettingsLayout or not addon.SettingsLayout.rootGAMEPLAY then return end
	buildSettings()
	addon.MythicPlus.variables.settingsBuilt = true
end
