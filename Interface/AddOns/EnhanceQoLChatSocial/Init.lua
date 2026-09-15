-- luacheck: globals ChatFrame1Tab ChatFrame2 ChatFrame2Tab FCF_SetWindowName FCFDock_UpdateTabs GENERAL_CHAT_DOCK
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local ChatFrameUtil = _G.ChatFrameUtil
local CHAT_BUBBLE_FONT_DEFAULT_SIZE = 13
local CHAT_BUBBLES_CVAR = "chatBubbles"

local function getChatBubblesCVar()
	if not (_G.C_CVar and _G.C_CVar.GetCVar) then return nil end
	local ok, value = pcall(_G.C_CVar.GetCVar, CHAT_BUBBLES_CVAR)
	if not ok or value == nil then return nil end
	return tostring(value)
end

local function setChatBubblesCVar(value)
	if not (_G.C_CVar and _G.C_CVar.SetCVar) then return false end
	value = tostring(value)
	if getChatBubblesCVar() == value then return true end
	local ok, changed = pcall(_G.C_CVar.SetCVar, CHAT_BUBBLES_CVAR, value)
	return ok and changed ~= false
end

local function restoreChatBubblesCVar()
	addon.variables = addon.variables or {}
	local restoreValue = addon.variables.chatBubblesInstanceRestoreValue
	if restoreValue == nil then return end
	if setChatBubblesCVar(restoreValue) then addon.variables.chatBubblesInstanceRestoreValue = nil end
end

function addon.functions.ApplyChatBubblesInInstances()
	if not addon.db then return end
	addon.variables = addon.variables or {}

	local inInstance, instanceType = false, "none"
	if _G.IsInInstance then inInstance, instanceType = _G.IsInInstance() end
	local suppress = addon.db.chatBubblesDisableInInstances == true
		and inInstance
		and (instanceType == "party" or instanceType == "raid")

	if suppress then
		if addon.variables.chatBubblesInstanceRestoreValue == nil then
			addon.variables.chatBubblesInstanceRestoreValue = getChatBubblesCVar()
		end
		setChatBubblesCVar("0")
	else
		restoreChatBubblesCVar()
	end
end

local function ensureChatBubblesInstanceWatcher()
	addon.variables = addon.variables or {}
	if addon.variables.chatBubblesInstanceWatcher then return end

	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	watcher:RegisterEvent("PLAYER_LOGOUT")
	watcher:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_LOGOUT" then
			restoreChatBubblesCVar()
		else
			addon.functions.ApplyChatBubblesInInstances()
		end
	end)
	addon.variables.chatBubblesInstanceWatcher = watcher
end

local function initChatFrame()
	-- Build learn/unlearn message patterns and filter once
	if not addon.variables.learnUnlearnPatterns then
		local patterns = {}
		if ERR_LEARN_PASSIVE_S then table.insert(patterns, addon.functions.fmtToPattern(ERR_LEARN_PASSIVE_S)) end
		if ERR_LEARN_SPELL_S then table.insert(patterns, addon.functions.fmtToPattern(ERR_LEARN_SPELL_S)) end
		if ERR_LEARN_ABILITY_S then table.insert(patterns, addon.functions.fmtToPattern(ERR_LEARN_ABILITY_S)) end
		if ERR_SPELL_UNLEARNED_S then table.insert(patterns, addon.functions.fmtToPattern(ERR_SPELL_UNLEARNED_S)) end
		addon.variables.learnUnlearnPatterns = patterns
	end

	addon.functions.ChatLearnFilter = addon.functions.ChatLearnFilter
		or function(_, _, msg)
			if not msg then return false end
			if issecretvalue and issecretvalue(msg) then return end
			for _, pat in ipairs(addon.variables.learnUnlearnPatterns or {}) do
				if msg:match(pat) then return true end
			end
			return false
		end

	addon.functions.ApplyChatLearnFilter = addon.functions.ApplyChatLearnFilter
		or function(enabled)
			if enabled then
				ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", addon.functions.ChatLearnFilter)
			else
				ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_SYSTEM", addon.functions.ChatLearnFilter)
			end
		end

	addon.functions.ApplyChatFrameMaxLines = addon.functions.ApplyChatFrameMaxLines
		or function()
			local frame = DEFAULT_CHAT_FRAME or ChatFrame1
			if not frame or not frame.SetMaxLines then return end
			if addon.db and addon.db.chatFrameMaxLines2000 then
				frame:SetMaxLines(2000)
			else
				frame:SetMaxLines(128)
			end
		end

	local function getChatEditBox(chatFrame)
		if not chatFrame then return nil end
		if chatFrame.editBox then return chatFrame.editBox end
		local name = chatFrame:GetName()
		return name and _G[name .. "EditBox"]
	end

	local function forEachChatFrame(callback)
		local maxFrames = math.max(Constants.ChatFrameConstants.MaxChatWindows or 0, 50)
		for i = 1, maxFrames do
			local frame = _G["ChatFrame" .. i]
			if frame then callback(frame, getChatEditBox(frame)) end
		end
	end

	local function refreshChatUnclampFrame()
		if not (addon.functions and addon.functions.ApplyChatUnclampFrame) then return end
		local pending = addon.variables and addon.variables.pendingChatUnclampFrame
		if pending ~= nil then
			addon.functions.ApplyChatUnclampFrame(pending)
		elseif addon.db then
			addon.functions.ApplyChatUnclampFrame(addon.db.chatUnclampFrame)
		end
	end

	local function ensureChatFrameHooks()
		addon.variables = addon.variables or {}
		if addon.variables.chatFrameHooksInstalled then return end
		addon.variables.chatFrameHooksInstalled = true

		hooksecurefunc("FCF_OpenTemporaryWindow", function()
			if addon.db and addon.db.chatUseArrowKeys and addon.functions.ApplyChatArrowKeys then addon.functions.ApplyChatArrowKeys(true) end
			if addon.db and addon.db.chatEditBoxOnTop and addon.functions.ApplyChatEditBoxOnTop then addon.functions.ApplyChatEditBoxOnTop(true) end
			refreshChatUnclampFrame()
			if addon.db and addon.db.chatHideCombatLogTab and addon.functions.ApplyChatHideCombatLogTab then addon.functions.ApplyChatHideCombatLogTab(true) end
			if addon.db and addon.functions.ApplyChatFrameFade then addon.functions.ApplyChatFrameFade() end
		end)

		hooksecurefunc("FCF_SetTabPosition", function()
			if not (addon.db and addon.db.chatHideCombatLogTab) then return end
			if ChatFrame1Tab and ChatFrame2Tab then ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0) end
		end)

		local frame = CreateFrame("Frame")
		frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:SetScript("OnEvent", function()
			if addon.db and addon.db.chatUseArrowKeys and addon.functions.ApplyChatArrowKeys then addon.functions.ApplyChatArrowKeys(true) end
			if addon.db and addon.db.chatEditBoxOnTop and addon.functions.ApplyChatEditBoxOnTop then addon.functions.ApplyChatEditBoxOnTop(true) end
			refreshChatUnclampFrame()
			if addon.db and addon.db.chatHideCombatLogTab and addon.functions.ApplyChatHideCombatLogTab then addon.functions.ApplyChatHideCombatLogTab(true) end
			if addon.db and addon.functions.ApplyChatFrameFade then addon.functions.ApplyChatFrameFade() end
		end)
		addon.variables.chatFrameWatcher = frame
	end

	addon.functions.ApplyChatArrowKeys = addon.functions.ApplyChatArrowKeys
		or function(enabled)
			addon.variables = addon.variables or {}
			addon.variables.chatArrowKeyModeCache = addon.variables.chatArrowKeyModeCache or {}
			local cache = addon.variables.chatArrowKeyModeCache

			forEachChatFrame(function(_, editBox)
				if not (editBox and editBox.SetAltArrowKeyMode) then return end
				if enabled then
					if cache[editBox] == nil and editBox.GetAltArrowKeyMode then cache[editBox] = editBox:GetAltArrowKeyMode() end
					editBox:SetAltArrowKeyMode(false)
				else
					if cache[editBox] ~= nil then
						editBox:SetAltArrowKeyMode(cache[editBox])
						cache[editBox] = nil
					end
				end
			end)

			ensureChatFrameHooks()
		end

	addon.functions.ApplyChatEditBoxOnTop = addon.functions.ApplyChatEditBoxOnTop
		or function(enabled)
			forEachChatFrame(function(frame, editBox)
				if not (frame and editBox) then return end
				if enabled then
					editBox:ClearAllPoints()
					editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
					editBox:SetWidth(frame:GetWidth())
					if not frame.eqolEditBoxSizeHooked then
						frame:HookScript("OnSizeChanged", function(self)
							if addon.db and addon.db.chatEditBoxOnTop and self.editBox then self.editBox:SetWidth(self:GetWidth()) end
						end)
						frame.eqolEditBoxSizeHooked = true
					end
				end
			end)

			ensureChatFrameHooks()
		end

	local function storeChatClampState(frame)
		addon.variables = addon.variables or {}
		addon.variables.chatClampCache = addon.variables.chatClampCache or {}
		local cache = addon.variables.chatClampCache
		if cache[frame] then return end
		local state = {
			clamped = frame.IsClampedToScreen and frame:IsClampedToScreen() or nil,
		}
		if frame.GetClampRectInsets then state.insets = { frame:GetClampRectInsets() } end
		cache[frame] = state
	end

	local function restoreChatClampState(frame)
		addon.variables = addon.variables or {}
		local cache = addon.variables.chatClampCache
		local state = cache and cache[frame]
		if not state then return end
		if frame.SetClampedToScreen and state.clamped ~= nil then frame:SetClampedToScreen(state.clamped) end
		if state.insets and frame.SetClampRectInsets then frame:SetClampRectInsets(state.insets[1], state.insets[2], state.insets[3], state.insets[4]) end
		cache[frame] = nil
	end

	addon.functions.ApplyChatUnclampFrame = addon.functions.ApplyChatUnclampFrame
		or function(enabled)
			ensureChatFrameHooks()
			addon.variables = addon.variables or {}
			if InCombatLockdown and InCombatLockdown() then
				-- Chat frames are protected in combat; replay the requested clamp state afterwards.
				addon.variables.pendingChatUnclampFrame = enabled and true or false
				return
			end
			addon.variables.pendingChatUnclampFrame = nil

			forEachChatFrame(function(frame)
				if not frame then return end
				if enabled then
					storeChatClampState(frame)
					if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
				else
					restoreChatClampState(frame)
				end
			end)
		end

	addon.functions.ApplyChatFrameFade = addon.functions.ApplyChatFrameFade
		or function()
			if not addon.db then return end
			local enabled = addon.db["chatFrameFadeEnabled"]
			local timeVisible = addon.db["chatFrameFadeTimeVisible"]
			local fadeDuration = addon.db["chatFrameFadeDuration"]
			if enabled == nil or timeVisible == nil or fadeDuration == nil then return end

			forEachChatFrame(function(frame)
				if frame.SetFading then frame:SetFading(enabled) end
				if frame.SetTimeVisible then frame:SetTimeVisible(timeVisible) end
				if frame.SetFadeDuration then frame:SetFadeDuration(fadeDuration) end
			end)

			ensureChatFrameHooks()
		end

	local function hideCombatLogTab()
		if not (ChatFrame2 and ChatFrame2Tab) then return end
		addon.variables = addon.variables or {}
		local state = addon.variables.chatCombatLogTabState or {}
		if not state.saved then
			state.name = ChatFrame2.name or (GetChatWindowInfo(2))
			state.scale = ChatFrame2Tab:GetScale()
			state.width = ChatFrame2Tab:GetWidth()
			state.height = ChatFrame2Tab:GetHeight()
			state.mouseEnabled = ChatFrame2Tab:IsMouseEnabled()
			state.saved = true
			addon.variables.chatCombatLogTabState = state
		end
		ChatFrame2Tab:EnableMouse(false)
		ChatFrame2Tab:SetText(" ")
		ChatFrame2Tab:SetScale(0.01)
		ChatFrame2Tab:SetWidth(0.01)
		ChatFrame2Tab:SetHeight(0.01)
		addon.variables.chatCombatLogHidden = true
	end

	local function showCombatLogTab()
		if not (ChatFrame2 and ChatFrame2Tab) then return end
		addon.variables = addon.variables or {}
		local state = addon.variables.chatCombatLogTabState or {}
		local name = state.name or COMBAT_LOG
		ChatFrame2Tab:SetScale(state.scale or 1)
		if state.width then ChatFrame2Tab:SetWidth(state.width) end
		if state.height then ChatFrame2Tab:SetHeight(state.height) end
		ChatFrame2Tab:EnableMouse(state.mouseEnabled ~= false)
		if FCF_SetWindowName then
			FCF_SetWindowName(ChatFrame2, name, true)
		else
			ChatFrame2Tab:SetText(name)
		end
		if FCFDock_UpdateTabs and GENERAL_CHAT_DOCK then FCFDock_UpdateTabs(GENERAL_CHAT_DOCK, true) end
		addon.variables.chatCombatLogHidden = nil
	end

	addon.functions.ApplyChatHideCombatLogTab = addon.functions.ApplyChatHideCombatLogTab
		or function(enabled)
			ensureChatFrameHooks()
			if not (ChatFrame2 and ChatFrame2Tab) then return end
			addon.variables = addon.variables or {}

			if enabled then
				if ChatFrame2.isDocked then
					hideCombatLogTab()
					addon.variables.chatCombatLogPending = nil
				else
					if addon.variables.chatCombatLogHidden then showCombatLogTab() end
					if not addon.variables.chatCombatLogWarned then
						local msg = L and L["chatHideCombatLogTabUndocked"] or "Combat log tab cannot be hidden while undocked."
						if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
							DEFAULT_CHAT_FRAME:AddMessage(msg)
						else
							print(msg)
						end
						addon.variables.chatCombatLogWarned = true
					end
					addon.variables.chatCombatLogPending = true
				end
			else
				if addon.variables.chatCombatLogHidden then showCombatLogTab() end
				addon.variables.chatCombatLogPending = nil
			end
		end

	if ChatFrame1 then
		addon.functions.InitDBValue("chatFrameFadeEnabled", ChatFrame1:GetFading())
		addon.functions.InitDBValue("chatFrameFadeTimeVisible", ChatFrame1:GetTimeVisible())
		addon.functions.InitDBValue("chatFrameFadeDuration", ChatFrame1:GetFadeDuration())
	else
		addon.functions.InitDBValue("chatFrameFadeEnabled", true)
		addon.functions.InitDBValue("chatFrameFadeTimeVisible", 120)
		addon.functions.InitDBValue("chatFrameFadeDuration", 3)
	end
	if addon.functions.ApplyChatFrameFade then addon.functions.ApplyChatFrameFade() end

	addon.functions.InitDBValue("chatFrameMaxLines2000", false)
	addon.functions.InitDBValue("enableChatIM", false)
	addon.functions.InitDBValue("enableChatIMFade", false)
	addon.functions.InitDBValue("chatIMUseCustomSound", false)
	addon.functions.InitDBValue("chatIMCustomSoundFile", "")
	addon.functions.InitDBValue("chatIMFontSize", 12)
	addon.functions.InitDBValue("chatIMMaxHistory", 250)
	addon.functions.InitDBValue("enableChatHistory", false)
	addon.functions.InitDBValue("chatChannelHistoryMaxLines", 500)
	addon.functions.InitDBValue("chatChannelHistoryMaxViewLines", 1000)
	addon.functions.InitDBValue("chatHistoryRestoreOnLogin", false)
	addon.functions.InitDBValue("chatChannelHistoryFontSize", 12)
	addon.functions.InitDBValue("chatChannelHistoryLootQualities", {
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = true,
	})
	addon.functions.InitDBValue("chatHistoryFrameStrata", "MEDIUM")
	addon.functions.InitDBValue("chatHistoryFrameLevel", 600)
	addon.functions.InitDBValue("chatHistoryButtonOffsetX", 0)
	addon.functions.InitDBValue("chatHistoryButtonOffsetY", -10)
	addon.functions.InitDBValue("chatHistoryShowButton", true)
	addon.functions.InitDBValue("chatHistoryFramePos", nil)
	addon.functions.InitDBValue("chatChannelFilters", {})
	addon.functions.InitDBValue("chatChannelFiltersEnable", {})
	addon.functions.InitDBValue("chatIMFrameData", {})
	addon.functions.InitDBValue("chatIMHideInCombat", false)
	addon.functions.InitDBValue("chatIMUseAnimation", true)
	addon.functions.InitDBValue("chatShowLootCurrencyIcons", false)
	addon.functions.InitDBValue("chatShowItemTooltipsOnHover", false)
	addon.functions.InitDBValue("chatShowItemLevelInLinks", false)
	addon.functions.InitDBValue("chatShowItemLevelLocation", false)
	addon.functions.InitDBValue("chatLinkCopy", false)
	addon.functions.InitDBValue("chatHideLearnUnlearn", false)
	addon.functions.InitDBValue("chatUseArrowKeys", false)
	addon.functions.InitDBValue("chatEditBoxOnTop", false)
	addon.functions.InitDBValue("chatUnclampFrame", false)
	addon.functions.InitDBValue("chatHideCombatLogTab", false)
	addon.functions.InitDBValue("chatBubbleFontOverride", false)
	addon.functions.InitDBValue("chatBubbleFontSize", CHAT_BUBBLE_FONT_DEFAULT_SIZE)
	addon.functions.InitDBValue("chatBubblesDisableInInstances", false)
	addon.functions.ApplyChatBubbleFontSize(addon.db["chatBubbleFontSize"])
	ensureChatBubblesInstanceWatcher()
	addon.functions.ApplyChatBubblesInInstances()
	-- Apply learn/unlearn message filter based on saved setting
	addon.functions.ApplyChatLearnFilter(addon.db["chatHideLearnUnlearn"])
	if addon.ChatIcons and addon.ChatIcons.SetEnabled then addon.ChatIcons:SetEnabled(addon.db["chatShowLootCurrencyIcons"]) end
	if addon.ChatIcons and addon.ChatIcons.SetItemTooltipOnHoverEnabled then addon.ChatIcons:SetItemTooltipOnHoverEnabled(addon.db["chatShowItemTooltipsOnHover"]) end
	if addon.ChatIcons and addon.ChatIcons.SetItemLevelEnabled then addon.ChatIcons:SetItemLevelEnabled(addon.db["chatShowItemLevelInLinks"]) end
	if addon.ChatIcons and addon.ChatIcons.SetURLCopyEnabled then addon.ChatIcons:SetURLCopyEnabled(addon.db["chatLinkCopy"]) end

	if addon.ChatIM and addon.ChatIM.SetEnabled then addon.ChatIM:SetEnabled(addon.db["enableChatIM"]) end
	if addon.functions.ApplyChatFrameMaxLines then addon.functions.ApplyChatFrameMaxLines() end
	if addon.functions.ApplyChatArrowKeys then addon.functions.ApplyChatArrowKeys(addon.db["chatUseArrowKeys"]) end
	if addon.functions.ApplyChatEditBoxOnTop then addon.functions.ApplyChatEditBoxOnTop(addon.db["chatEditBoxOnTop"]) end
	if addon.functions.ApplyChatUnclampFrame then addon.functions.ApplyChatUnclampFrame(addon.db["chatUnclampFrame"]) end
	if addon.functions.ApplyChatHideCombatLogTab then addon.functions.ApplyChatHideCombatLogTab(addon.db["chatHideCombatLogTab"]) end
end

local function initSocial()
	addon.functions.InitDBValue("enableIgnore", false)
	addon.functions.InitDBValue("ignoreAttachFriendsFrame", true)
	addon.functions.InitDBValue("ignoreAnchorFriendsFrame", false)
	addon.functions.InitDBValue("ignoreTooltipNote", false)
	addon.functions.InitDBValue("ignoreTooltipMaxChars", 100)
	addon.functions.InitDBValue("ignoreTooltipWordsPerLine", 5)
	addon.functions.InitDBValue("ignoreFramePoint", "CENTER")
	addon.functions.InitDBValue("ignoreFrameX", 0)
	addon.functions.InitDBValue("ignoreFrameY", 0)
	addon.functions.InitDBValue("blockDuelRequests", false)
	addon.functions.InitDBValue("blockPetBattleRequests", false)
	addon.functions.InitDBValue("blockPartyInvites", false)
	addon.functions.InitDBValue("friendsListDecorEnabled", false)
	addon.functions.InitDBValue("friendsListDecorShowLocation", true)
	addon.functions.InitDBValue("friendsListDecorHideOwnRealm", true)
	addon.functions.InitDBValue("friendsListDecorNameFontSize", 0)
	addon.functions.InitDBValue("communityChatPrivacyEnabled", false)
	addon.functions.InitDBValue("communityChatPrivacyMode", 1)
	if addon.Ignore and addon.Ignore.SetEnabled then addon.Ignore:SetEnabled(addon.db["enableIgnore"]) end
	if addon.Ignore and addon.Ignore.UpdateAnchor then addon.Ignore:UpdateAnchor() end
	if addon.FriendsListDecor and addon.FriendsListDecor.SetEnabled then addon.FriendsListDecor:SetEnabled(addon.db["friendsListDecorEnabled"] == true) end
	if addon.CommunityChatPrivacy and addon.CommunityChatPrivacy.SetMode then addon.CommunityChatPrivacy:SetMode(addon.db["communityChatPrivacyMode"]) end
	if addon.CommunityChatPrivacy and addon.CommunityChatPrivacy.SetEnabled then addon.CommunityChatPrivacy:SetEnabled(addon.db["communityChatPrivacyEnabled"]) end
end

function addon.functions.InitChatSocial()
	addon.variables = addon.variables or {}
	if addon.variables.chatSocialInitialized then return end
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	addon.variables.chatSocialInitialized = true
	initChatFrame()
	if addon.functions.initChatFrame then addon.functions.initChatFrame() end
	initSocial()
	if addon.functions.initSocial then addon.functions.initSocial() end
end

addon.functions.InitChatSocial()
