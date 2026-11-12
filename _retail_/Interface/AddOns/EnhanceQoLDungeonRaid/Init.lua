-- luacheck: globals UIWidgetObjectiveTracker MonthlyActivitiesObjectiveTracker InitiativeTasksObjectiveTracker
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.Buttons = addon.MythicPlus.Buttons or {}
addon.MythicPlus.nrOfButtons = addon.MythicPlus.nrOfButtons or 0
addon.MythicPlus.variables = addon.MythicPlus.variables or {}
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local MouseIsOver = addon.functions.MouseIsOver

local function normalizeNumericDropdownValue(key, labels, fallback)
	if not addon.db then return end
	local value = addon.db[key]
	if type(value) == "number" and labels[value] ~= nil then return end
	if type(value) == "string" then
		local numeric = tonumber(value)
		if numeric and labels[numeric] ~= nil then
			addon.db[key] = numeric
			return
		end
		local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
		for index, label in pairs(labels) do
			if trimmed == tostring(label) then
				addon.db[key] = index
				return
			end
		end
	end
	addon.db[key] = fallback
end

function addon.MythicPlus.functions.InitDB()
	if addon.MythicPlus.variables.dbInitialized then return end
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	addon.MythicPlus.variables.dbInitialized = true
	local init = addon.functions.InitDBValue
	local function initTracker(key, value)
		addon.MythicPlus.variables.editModeTrackerDefaults = addon.MythicPlus.variables.editModeTrackerDefaults or {}
		addon.MythicPlus.variables.editModeTrackerDefaults[key] = type(value) == "table" and CopyTable(value) or value
		init(key, value)
	end
	local globalFontKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__"

	-- Always use the improved Keystone Helper UI (legacy removed)
	-- PullTimer
	init("enableKeystoneHelper", false)
	init("autoInsertKeystone", false)
	init("closeBagsOnKeyInsert", false)
	init("noChatOnPullTimer", false)
	init("autoKeyStart", false)
	init("pullTimerShortTime", 5)
	init("pullTimerLongTime", 10)
	init("PullTimerType", 4)

	-- Dungeon Browser
	init("groupfinderAppText", false)
	init("groupfinderSkipRoleSelect", false)
	init("groupfinderSkipRoleSelectOption", 1)
	normalizeNumericDropdownValue("groupfinderSkipRoleSelectOption", {
		[1] = L["groupfinderSkipRolecheckUseSpec"] or "Use your current spec's role (e.g. Blood Death Knight = Tank)",
		[2] = L["groupfinderSkipRolecheckUseLFD"] or "Use Blizzard's selected role",
	}, 1)
	init("groupfinderShowDungeonScoreFrame", false)

	init("dungeonScoreFrameLocked", true)
	init("dungeonScoreFrameData", {})

	-- Party Keystone frame
	init("groupfinderShowPartyKeystone", false)
	init("partyKeystoneFrameAnchor", "DEFAULT")
	init("partyKeystoneFrameOffsetX", 0)
	init("partyKeystoneFrameOffsetY", 0)
	init("partyKeystoneFrameAutoWidth", true)
	init("partyKeystoneFrameWidth", 200)
	init("partyKeystoneFrameHeight", 50)
	init("partyKeystoneFrameShowIcon", true)
	init("partyKeystoneFrameIconSize", 30)
	init("partyKeystoneFrameShowRealm", false)
	init("partyKeystoneFrameFont", (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT)
	init("partyKeystoneFrameFontStyle", "NONE")
	init("partyKeystoneFrameLevelFontSize", 16)
	init("partyKeystoneFrameLocationFontSize", 12)
	init("partyKeystoneFrameNameFontSize", 12)
	init("partyKeystoneFrameLevelColor", { r = 1, g = 1, b = 1, a = 1 })
	init("partyKeystoneFrameLocationColor", { r = 1, g = 0.82, b = 0, a = 1 })
	init("partyKeystoneFrameUseClassColor", true)
	init("partyKeystoneFrameNameColor", { r = 1, g = 1, b = 1, a = 1 })
	init("partyKeystoneFrameBackgroundColor", { r = 0, g = 0, b = 0, a = 0.8 })
	init("partyKeystoneFrameBorderEnabled", false)
	init("partyKeystoneFrameBorderStyle", "Blizzard Tooltip")
	init("partyKeystoneFrameBorderSize", 16)
	init("partyKeystoneFrameBorderColor", { r = 1, g = 1, b = 1, a = 1 })

	-- Mythic dungeon Keystone reminder
	init("partyKeystoneDungeonIndicatorEnabled", false)
	init("partyKeystoneDungeonIndicatorShowHeader", true)
	init("partyKeystoneDungeonIndicatorFont", addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or ((addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT))
	init("partyKeystoneDungeonIndicatorFontStyle", addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "OUTLINE")
	init("partyKeystoneDungeonIndicatorHeaderFontSize", 20)
	init("partyKeystoneDungeonIndicatorEntryFontSize", 18)
	init("partyKeystoneDungeonIndicatorHeaderColor", { r = 1, g = 1, b = 1, a = 1 })
	init("partyKeystoneDungeonIndicatorUseClassColor", true)
	init("partyKeystoneDungeonIndicatorNameColor", { r = 1, g = 1, b = 1, a = 1 })
	init("partyKeystoneDungeonIndicatorUseRarityColor", true)
	init("partyKeystoneDungeonIndicatorLevelColor", { r = 1, g = 1, b = 1, a = 1 })
	init("partyKeystoneDungeonIndicatorRowSpacing", 2)
	init("partyKeystoneDungeonIndicatorAlignment", "LEFT")
	init("partyKeystoneDungeonIndicatorGrowth", "DOWN")
	init("partyKeystoneDungeonIndicatorNameOffsetX", 0)
	init("partyKeystoneDungeonIndicatorNameOffsetY", 0)

	-- Misc

	-- BR Tracker
	initTracker("mythicPlusBRTrackerEnabled", false)
	initTracker("mythicPlusBRButtonSize", 50)
	initTracker("mythicPlusBRTrackerPoint", "CENTER")
	initTracker("mythicPlusBRTrackerRelativePoint", "CENTER")
	initTracker("mythicPlusBRTrackerRelativeFrame", "UIParent")
	initTracker("mythicPlusBRTrackerX", 0)
	initTracker("mythicPlusBRTrackerY", 0)
	initTracker("mythicPlusBRTrackerIcon", 136080)
	initTracker("mythicPlusBRTrackerIconZoom", 0)
	initTracker("mythicPlusBRTrackerIconShape", "DEFAULT")
	initTracker("mythicPlusBRTrackerBorderEnabled", true)
	initTracker("mythicPlusBRTrackerBorderTexture", "DEFAULT")
	initTracker("mythicPlusBRTrackerBorderSize", 1)
	initTracker("mythicPlusBRTrackerBorderOffset", 0)
	initTracker("mythicPlusBRTrackerBorderColor", { 1, 1, 1, 1 })
	initTracker("mythicPlusBRTrackerCooldownTextEnabled", true)
	initTracker("mythicPlusBRTrackerCooldownDrawSwipe", true)
	initTracker("mythicPlusBRTrackerCooldownDrawEdge", false)
	initTracker("mythicPlusBRTrackerCooldownDrawBling", false)
	initTracker("mythicPlusBRTrackerCooldownFontFace", globalFontKey)
	initTracker("mythicPlusBRTrackerCooldownTextSize", 16)
	initTracker("mythicPlusBRTrackerCooldownTextOutline", "OUTLINE")
	initTracker("mythicPlusBRTrackerCooldownTextColor", { 1, 1, 1, 1 })
	initTracker("mythicPlusBRTrackerCooldownTextPoint", "CENTER")
	initTracker("mythicPlusBRTrackerCooldownTextOffsetX", 0)
	initTracker("mythicPlusBRTrackerCooldownTextOffsetY", 0)
	initTracker("mythicPlusBRTrackerDurationTextProfile", "MINIMAL")
	initTracker("mythicPlusBRTrackerChargesEnabled", true)
	initTracker("mythicPlusBRTrackerChargesFontFace", globalFontKey)
	initTracker("mythicPlusBRTrackerChargesTextSize", 16)
	initTracker("mythicPlusBRTrackerChargesTextOutline", "OUTLINE")
	initTracker("mythicPlusBRTrackerChargesTextColor", { 0, 1, 0, 1 })
	initTracker("mythicPlusBRTrackerChargesTextPoint", "BOTTOMRIGHT")
	initTracker("mythicPlusBRTrackerChargesTextOffsetX", -3)
	initTracker("mythicPlusBRTrackerChargesTextOffsetY", 3)

	-- Bloodlust Tracker
	initTracker("mythicPlusBloodlustTrackerEnabled", false)
	initTracker("mythicPlusBloodlustButtonSize", 50)
	initTracker("mythicPlusBloodlustTrackerPoint", "CENTER")
	initTracker("mythicPlusBloodlustTrackerRelativePoint", "CENTER")
	initTracker("mythicPlusBloodlustTrackerRelativeFrame", "UIParent")
	initTracker("mythicPlusBloodlustTrackerX", 0)
	initTracker("mythicPlusBloodlustTrackerY", 0)
	initTracker("mythicPlusBloodlustTrackerOnlyInInstances", true)
	initTracker("mythicPlusBloodlustTrackerShowActiveDuration", false)
	initTracker("mythicPlusBloodlustTrackerGlowOnActive", false)
	initTracker("mythicPlusBloodlustTrackerActiveGlowStyle", "MARCHING_ANTS")
	initTracker("mythicPlusBloodlustTrackerActiveGlowColor", { 1, 0.82, 0.2, 1 })
	initTracker("mythicPlusBloodlustTrackerActiveGlowInset", 0)
	initTracker("mythicPlusBloodlustTrackerActiveGlowPixelBorder", false)
	initTracker("mythicPlusBloodlustTrackerActiveGlowPixelCount", 8)
	initTracker("mythicPlusBloodlustTrackerActiveGlowPixelSpeed", 0.25)
	initTracker("mythicPlusBloodlustTrackerActiveGlowPixelThickness", 2)
	initTracker("mythicPlusBloodlustTrackerIcon", 136090)
	initTracker("mythicPlusBloodlustTrackerIconZoom", 0)
	initTracker("mythicPlusBloodlustTrackerIconShape", "DEFAULT")
	initTracker("mythicPlusBloodlustTrackerBorderEnabled", true)
	initTracker("mythicPlusBloodlustTrackerBorderTexture", "DEFAULT")
	initTracker("mythicPlusBloodlustTrackerBorderSize", 1)
	initTracker("mythicPlusBloodlustTrackerBorderOffset", 0)
	initTracker("mythicPlusBloodlustTrackerBorderColor", { 1, 1, 1, 1 })
	initTracker("mythicPlusBloodlustTrackerCooldownDrawSwipe", true)
	initTracker("mythicPlusBloodlustTrackerCooldownDrawEdge", false)
	initTracker("mythicPlusBloodlustTrackerCooldownDrawBling", false)
	initTracker("mythicPlusBloodlustTrackerCooldownFontFace", globalFontKey)
	initTracker("mythicPlusBloodlustTrackerCooldownTextSize", 16)
	initTracker("mythicPlusBloodlustTrackerCooldownTextOutline", "OUTLINE")
	initTracker("mythicPlusBloodlustTrackerCooldownTextColor", { 1, 1, 1, 1 })
	initTracker("mythicPlusBloodlustTrackerCooldownTextOffsetX", 0)
	initTracker("mythicPlusBloodlustTrackerCooldownTextOffsetY", 0)
	initTracker("mythicPlusBloodlustTrackerReadyFontFace", globalFontKey)
	initTracker("mythicPlusBloodlustTrackerReadyText", "")
	initTracker("mythicPlusBloodlustTrackerReadyTextSize", 12)
	initTracker("mythicPlusBloodlustTrackerReadyTextOutline", "OUTLINE")
	initTracker("mythicPlusBloodlustTrackerReadyTextColor", { 0.2, 1, 0.2, 1 })
	initTracker("mythicPlusBloodlustTrackerReadyTextOffsetX", 0)
	initTracker("mythicPlusBloodlustTrackerReadyTextOffsetY", 4)
	initTracker("mythicPlusBloodlustTrackerDurationTextProfile", "MINIMAL")
	initTracker("mythicPlusBloodlustTrackerSoundOnDebuffActive", false)
	initTracker("mythicPlusBloodlustTrackerUseCustomDebuffSound", false)
	initTracker("mythicPlusBloodlustTrackerDebuffSoundFile", "")
	initTracker("mythicPlusBloodlustTrackerSoundOnDebuffFade", false)
	initTracker("mythicPlusBloodlustTrackerUseCustomFadeSound", false)
	initTracker("mythicPlusBloodlustTrackerFadeSoundFile", "")
	initTracker("mythicPlusBloodlustTrackerReadySoundOnEncounterStart", false)
	initTracker("mythicPlusBloodlustTrackerUseCustomReadySound", false)
	initTracker("mythicPlusBloodlustTrackerReadySoundFile", "")

	-- Talent Reminder
	init("talentReminderEnabled", false)
	init("talentReminderSettings", {})
	init("talentReminderShowActiveBuild", false)
	init("talentReminderActiveBuildPoint", "CENTER")
	init("talentReminderActiveBuildX", 0)
	init("talentReminderActiveBuildY", 0)
	init("talentReminderActiveBuildSize", 14)
	-- switched from single number -> table (multiselect)
	init("talentReminderActiveBuildShowOnly", {})
	init("talentReminderLoadOnReadyCheck", false)
	init("talentReminderSoundOnDifference", false)
	init("talentReminderUseCustomSound", false)
	init("talentReminderCustomSoundFile", "")

	-- Backward compatibility migration: convert old numeric value to table
	local v = addon.db["talentReminderActiveBuildShowOnly"]
	if type(v) ~= "table" then
		local newVal = {}
		if type(v) == "number" and v >= 1 and v <= 3 then newVal[v] = true end
		addon.db["talentReminderActiveBuildShowOnly"] = newVal
	end

	-- Group Dungeon Filter
	init("mythicPlusEnableDungeonFilter", false)
	init("mythicPlusEnableDungeonFilterClearReset", false)
	init("mythicPlusDungeonFilters", {})
end

function addon.MythicPlus.functions.InitState()
	if addon.MythicPlus.variables.stateInitialized then return end
	if not addon.db then return end
	addon.MythicPlus.variables.stateInitialized = true
	if addon.MythicPlus.functions.InitTalentReminder then addon.MythicPlus.functions.InitTalentReminder() end
	if addon.MythicPlus.functions.InitDungeonFilter then addon.MythicPlus.functions.InitDungeonFilter() end
	if addon.MythicPlus.functions.InitObjectiveTracker then addon.MythicPlus.functions.InitObjectiveTracker() end
	if addon.MythicPlus.functions.InitMain then addon.MythicPlus.functions.InitMain() end
end

-- PullTimer
addon.MythicPlus.variables.handled = false
addon.MythicPlus.variables.breakIt = false

addon.MythicPlus.variables.resetCooldownEncounterDifficult = {
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[9] = true,
	[14] = true,
	[15] = true,
	[16] = true,
	[17] = true,
	[18] = true,
	[33] = true,
	[151] = true,
	[208] = true, -- delves
}

function addon.MythicPlus.functions.addRCButton()
	local rcButton = CreateFrame("Button", "EnhanceQoLMythicPlus_ReadyCheck", ChallengesKeystoneFrame)
	rcButton:ClearAllPoints()
	rcButton:SetPoint("TOPLEFT", ChallengesKeystoneFrame, "TOPLEFT", 15, -15)
	rcButton:SetSize(110, 110)
	rcButton:SetHitRectInsets(15, 15, 15, 15)
	rcButton:SetScript("OnClick", function(self, button)
		if not self.readyCheckRunning then
			if InCombatLockdown and InCombatLockdown() then
				if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(L["readyCheckUnavailableInCombat"], 1, 0.1, 0.1) end
				return
			end
			self.readyCheckRunning = true
			local doReadyCheck = C_PartyInfo and C_PartyInfo.DoReadyCheck or DoReadyCheck
			if doReadyCheck then doReadyCheck() end
		end
	end)
	rcButton:RegisterEvent("READY_CHECK")
	rcButton:RegisterEvent("READY_CHECK_CONFIRM")
	rcButton:RegisterEvent("READY_CHECK_FINISHED")
	rcButton:SetScript("OnEvent", function(self, event, ...)
		if event == "READY_CHECK" then
			self.icon:SetVertexColor(1, 0.8, 0)
			self.icon:SetDesaturated(false)
			self.spin:Play()
			-- pulse animation for "waiting" state
			if self.iconPulse and not self.iconPulse:IsPlaying() then
				self.iconPulse:Play() -- start pulsing while we wait
			end
			self.readyCheckRunning = true
		elseif event == "READY_CHECK_CONFIRM" then
			local unit, ready = ...
			if not ready then
				self.notReady = true
				self.icon:SetVertexColor(1, 0.2, 0.2)
			end
		elseif event == "READY_CHECK_FINISHED" then
			if self.iconPulse and self.iconPulse:IsPlaying() then
				self.iconPulse:Stop() -- stop pulsing, restore full alpha
				self.icon:SetAlpha(1)
			end
			if not self.notReady then self.icon:SetVertexColor(0, 1, 0.3) end
			self.readyCheckRunning = false
			C_Timer.After(2, function()
				if self.readyCheckRunning then return end
				self.icon:SetVertexColor(1, 1, 1)
				self.notReady = false
				if not MouseIsOver(rcButton) then
					self.spin:Stop()
					self.ring:SetRotation(0)
				end
			end)
		end
	end)
	rcButton:SetFrameStrata("HIGH")

	local icon = rcButton:CreateTexture(nil, "ARTWORK", nil, 0)
	icon:SetPoint("CENTER", rcButton, "CENTER")
	icon:SetTexture("Interface\\AddOns\\EnhanceQoLDungeonRaid\\Art\\coreRC.tga")
	icon:SetSize(70, 70)
	rcButton.icon = icon

	-- pulse animation for "waiting" state
	local pulse = icon:CreateAnimationGroup()
	local fadeOut = pulse:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0.3)
	fadeOut:SetDuration(0.8)
	fadeOut:SetOrder(1)

	local fadeIn = pulse:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0.3)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.8)
	fadeIn:SetOrder(2)

	pulse:SetLooping("REPEAT")
	rcButton.iconPulse = pulse

	local ring = rcButton:CreateTexture(nil, "OVERLAY", nil, 1)
	ring:SetTexture("Interface\\AddOns\\EnhanceQoLDungeonRaid\\Art\\coreRing.tga")
	ring:SetSize(110, 110)
	ring:SetPoint("CENTER", rcButton, "CENTER")
	rcButton.ring = ring

	local spin = ring:CreateAnimationGroup()
	local rot = spin:CreateAnimation("Rotation")
	rot:SetDegrees(360)
	rot:SetDuration(24)
	spin:SetLooping("REPEAT")
	rcButton.spin = spin

	rcButton:SetScript("OnEnter", function(self, button)
		if not self.readyCheckRunning then spin:Play() end
	end)
	rcButton:SetScript("OnLeave", function(self, button)
		if not self.readyCheckRunning then
			spin:Stop()
			ring:SetRotation(0)
		end
	end)
	addon.MythicPlus.Buttons["EnhanceQoLMythicPlus_ReadyCheck"] = rcButton
	addon.MythicPlus.nrOfButtons = addon.MythicPlus.nrOfButtons + 1
end

function addon.MythicPlus.functions.addPullButton()
	local rcButton = CreateFrame("Button", "EnhanceQoLMythicPlus_PullTimer", ChallengesKeystoneFrame)
	rcButton:ClearAllPoints()
	rcButton:SetPoint("TOPRIGHT", ChallengesKeystoneFrame, "TOPRIGHT", -15, -15)
	rcButton:SetSize(110, 110)
	rcButton:SetHitRectInsets(15, 15, 15, 15)
	-- streamlined pull‑timer logic
	local function startPull(self, duration)
		self.remaining = duration
		self.icon:Hide()
		self.timerCountdown:SetText(duration)
		self.timerCountdown:Show()
		if self.remaining > 6 then
			self.timerCountdown:SetVertexColor(0, 1, 0)
		elseif self.remaining > 3 then
			self.timerCountdown:SetVertexColor(1, 1, 0)
		else
			self.timerCountdown:SetVertexColor(1, 0, 0)
		end
		-- blizzard / DBM alignment
		local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
		if (addon.db["PullTimerType"] == 2 or addon.db["PullTimerType"] == 4) and (not InCombatLockdown or not InCombatLockdown()) then C_PartyInfo.DoCountdown(duration) end
		if addon.db["PullTimerType"] == 3 or addon.db["PullTimerType"] == 4 then
			C_ChatInfo.SendAddonMessage("D4", ("PT\t%d\t%d"):format(duration, instanceId), IsInGroup(2) and "INSTANCE_CHAT" or "RAID")
		end
			if not addon.db["noChatOnPullTimer"] then C_ChatInfo.SendChatMessage((L["mpPullInSeconds"]):format(duration), "PARTY") end

		-- ticker updates local countdown (also handles chat, optional)
		self.ticker = C_Timer.NewTicker(1, function(t)
			self.remaining = self.remaining - 1
			if self.remaining > 6 then
				self.timerCountdown:SetVertexColor(0, 1, 0)
			elseif self.remaining > 3 then
				self.timerCountdown:SetVertexColor(1, 1, 0)
			else
				self.timerCountdown:SetVertexColor(1, 0, 0)
			end
			if self.remaining <= 0 then
				t:Cancel()
				self.timerCountdown:SetText("0")
				self.icon:Show()
				self.timerCountdown:Hide()
				self.running = false
				if not MouseIsOver(rcButton) then
					self.spin:Stop()
					self.ring:SetRotation(0)
				end

					if not addon.db["noChatOnPullTimer"] then C_ChatInfo.SendChatMessage(L["mpPullNow"], "PARTY") end
				if addon.db["autoKeyStart"] and C_ChallengeMode.GetSlottedKeystoneInfo() then
					C_ChallengeMode.StartChallengeMode()
					ChallengesKeystoneFrame:Hide()
				end
			else
				self.timerCountdown:SetText(self.remaining)
					if not addon.db["noChatOnPullTimer"] then C_ChatInfo.SendChatMessage((L["mpPullInSecond"]):format(self.remaining), "PARTY") end
			end
		end)
		self.running = true
	end

	local function cancelPull(self)
		if self.ticker then self.ticker:Cancel() end
		self.icon:Show()
		self.timerCountdown:Hide()
		self.running = false
		if not MouseIsOver(rcButton) then
			self.spin:Stop()
			self.ring:SetRotation(0)
		end
		if not InCombatLockdown or not InCombatLockdown() then
			C_PartyInfo.DoCountdown(0) -- abort Blizzard countdown
		end
			if not addon.db["noChatOnPullTimer"] then C_ChatInfo.SendChatMessage(L["mpPullCanceled"], "PARTY") end
	end

	rcButton:RegisterForClicks("RightButtonDown", "LeftButtonDown")
	rcButton:SetScript("OnClick", function(self, button)
		if self.running then
			cancelPull(self)
			return
		end

		local duration = (button == "RightButton") and addon.db["pullTimerShortTime"] or addon.db["pullTimerLongTime"]
		startPull(self, duration)
	end)
	rcButton:SetFrameStrata("HIGH")

	local icon = rcButton:CreateTexture(nil, "ARTWORK", nil, 0)
	icon:SetPoint("CENTER", rcButton, "CENTER")
	icon:SetTexture("Interface\\AddOns\\EnhanceQoLDungeonRaid\\Art\\corePull.tga")
	icon:SetSize(72, 72)
	rcButton.icon = icon

	local timerCountdown = rcButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	timerCountdown:SetPoint("CENTER", rcButton, "CENTER", 0, 0)
	timerCountdown:SetFont(addon.variables.defaultFont, 20, "OUTLINE")
	timerCountdown:SetVertexColor(1, 1, 0)
	timerCountdown:Hide()
	rcButton.timerCountdown = timerCountdown

	-- pulse animation for "waiting" state
	local pulse = icon:CreateAnimationGroup()
	local fadeOut = pulse:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0.3)
	fadeOut:SetDuration(0.8)
	fadeOut:SetOrder(1)

	local fadeIn = pulse:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0.3)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.8)
	fadeIn:SetOrder(2)

	pulse:SetLooping("REPEAT")
	rcButton.iconPulse = pulse

	local ring = rcButton:CreateTexture(nil, "OVERLAY", nil, 1)
	ring:SetTexture("Interface\\AddOns\\EnhanceQoLDungeonRaid\\Art\\coreRing.tga")
	ring:SetSize(110, 110)
	ring:SetPoint("CENTER", rcButton, "CENTER")
	rcButton.ring = ring

	local spin = ring:CreateAnimationGroup()
	local rot = spin:CreateAnimation("Rotation")
	rot:SetDegrees(360)
	rot:SetDuration(24)
	spin:SetLooping("REPEAT")
	rcButton.spin = spin

	rcButton:SetScript("OnEnter", function(self, button)
		if not self.running then spin:Play() end
	end)
	rcButton:SetScript("OnLeave", function(self, button)
		if not self.running then
			spin:Stop()
			ring:SetRotation(0)
		end
	end)
	addon.MythicPlus.Buttons["EnhanceQoLMythicPlus_PullTimer"] = rcButton
	addon.MythicPlus.nrOfButtons = addon.MythicPlus.nrOfButtons + 1
end

function addon.MythicPlus.functions.addButton(frame, name, text, call)
	local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	button:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, (addon.MythicPlus.nrOfButtons * -40))
	button:SetSize(140, 40)
	button:SetText(text)
	button:SetNormalFontObject("GameFontNormalLarge")
	button:SetHighlightFontObject("GameFontHighlightLarge")
	button:RegisterForClicks("RightButtonDown", "LeftButtonDown")
	button:SetScript("OnClick", call)
	if UnitIsGroupLeader("Player") == false then button:Hide() end
	addon.MythicPlus.Buttons[name] = button
	addon.MythicPlus.nrOfButtons = addon.MythicPlus.nrOfButtons + 1
end

function addon.MythicPlus.functions.removeExistingButton()
	for _, button in pairs(addon.MythicPlus.Buttons) do
		if button then
			button:Hide() -- Versteckt den Button
			button:SetParent(nil) -- Entfernt den Parent-Frame

			-- Entferne alle registrierten Event-Handler und Scripte
			button:SetScript("OnClick", nil)
			button:SetScript("OnEnter", nil)
			button:SetScript("OnLeave", nil)
			button:SetScript("OnUpdate", nil)
			button:SetScript("OnEvent", nil)

			-- Entferne alle Texturen und andere Frames
			button:UnregisterAllEvents()
			button:ClearAllPoints()
		end
	end
	addon.MythicPlus.Buttons = {}
	addon.MythicPlus.nrOfButtons = 0
end

addon.MythicPlus.variables.objectiveTrackerFrames = {
	{ frame = UIWidgetObjectiveTracker, name = "UIWidgetObjectiveTracker" },
	{ frame = CampaignQuestObjectiveTracker, name = "CampaignQuestObjectiveTracker" },
	{ frame = QuestObjectiveTracker, name = "QuestObjectiveTracker" },
	{ frame = AdventureObjectiveTracker, name = "AdventureObjectiveTracker" },
	{ frame = AchievementObjectiveTracker, name = "AchievementObjectiveTracker" },
	{ frame = MonthlyActivitiesObjectiveTracker, name = "MonthlyActivitiesObjectiveTracker" },
	{ frame = InitiativeTasksObjectiveTracker, name = "InitiativeTasksObjectiveTracker" },
	{ frame = ProfessionsRecipeTracker, name = "ProfessionsRecipeTracker" },
	{ frame = BonusObjectiveTracker, name = "BonusObjectiveTracker" },
	{ frame = WorldQuestObjectiveTracker, name = "WorldQuestObjectiveTracker" },
}

local challengeMapIDDefaults = {
	[560] = "MC",
	[559] = "NPX",
	[558] = "MT",
	[557] = "WS",
	[584] = "BV",
	[585] = "VSA",
	[586] = "DON",
	[587] = "MR",
	[588] = "AOF",
	[239] = "SEAT",
	[556] = "POS",
	[542] = "ED",
	[501] = "SV",
	[502] = "COT",
	[505] = "DAWN",
	[503] = "ARAK",
	[525] = "FLOOD",
	[506] = "MEAD",
	[499] = "PSF",
	[504] = "DFC",
	[500] = "ROOK",
	[463] = "DOTI",
	[464] = "DOTI",
	[399] = "RLP",
	[400] = "NO",
	[405] = "BH",
	[402] = "AA",
	[404] = "NELT",
	[401] = "AV",
	[406] = "HOI",
	[403] = "ULD",
	[376] = "NW",
	[379] = "PF",
	[375] = "MISTS",
	[378] = "HOA",
	[381] = "SOA",
	[382] = "TOP",
	[377] = "DOS",
	[380] = "SD",
	[391] = "STREET",
	[392] = "GAMBIT",
	[245] = "FH",
	[249] = "KR",
	[250] = "TOS",
	[251] = "UR",
	[369] = "WORK",
	[370] = "WORK",
	[248] = "WM",
	[244] = "AD",
	[353] = "SIEG",
	[247] = "ML",
	[199] = "BRH",
	[210] = "COS",
	[198] = "DHT",
	[200] = "HOV",
	[206] = "NL",
	[227] = "KARA",
	[234] = "KARA",
	[164] = "AUCH",
	[163] = "BSM",
	[168] = "EB",
	[166] = "GD",
	[169] = "ID",
	[165] = "SBG",
	[161] = "SR",
	[167] = "UBRS",
	[57] = "GSS",
	[60] = "MP",
	[76] = "SCHO",
	[77] = "SH",
	[78] = "SM",
	[59] = "SN",
	[58] = "SPM",
	[56] = "SB",
	[2] = "TJS",
	[507] = "GB",
	[456] = "TOTT",
	[438] = "VP",
}

addon.MythicPlus.variables.challengeMapID = addon.functions and addon.functions.BuildChallengeMapLabelTable and addon.functions.BuildChallengeMapLabelTable(challengeMapIDDefaults)
	or challengeMapIDDefaults
