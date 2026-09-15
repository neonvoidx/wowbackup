-- luacheck: globals CENSORED_MESSAGE_HIDDEN CENSORED_MESSAGE_REPORT PanelTemplates_TabResize FCFTab_UpdateColors
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local canaccessvalue = _G.canaccessvalue
local MouseIsOver = addon.functions.MouseIsOver

local function colorWrap(hex, text) return "|cff" .. hex .. text .. "|r" end

local function colorToHex(colorInfo)
	if not colorInfo then colorInfo = { r = 1, g = 1, b = 1 } end
	local r = math.floor((colorInfo.r or 1) * 255 + 0.5)
	local g = math.floor((colorInfo.g or 1) * 255 + 0.5)
	local b = math.floor((colorInfo.b or 1) * 255 + 0.5)
	return ("%02x%02x%02x"):format(r, g, b)
end

local function getDefaultMessageColor(outbound, isBN)
	if isBN then return outbound and ChatTypeInfo.BN_WHISPER_INFORM or ChatTypeInfo.BN_WHISPER end
	return outbound and ChatTypeInfo.WHISPER_INFORM or ChatTypeInfo.WHISPER
end

local function getMessageColorHex(outbound, isBN)
	local key = outbound and "chatIMOutgoingMessageColor" or "chatIMIncomingMessageColor"
	local color = addon.db and addon.db[key]
	if type(color) ~= "table" then color = getDefaultMessageColor(outbound, isBN) end
	return colorToHex(color)
end

local function applyMessageColor(text, hex)
	text = tostring(text or "")
	if text:find("|r", 1, true) then text = text:gsub("|r", "|r|cff" .. hex) end
	return "|cff" .. hex .. text .. "|r"
end

addon.ChatIM = addon.ChatIM or {}

local ChatIM = addon.ChatIM
ChatIM.maxHistoryLines = ChatIM.maxHistoryLines or (addon.db and addon.db["chatIMMaxHistory"]) or 250

local MU = MenuUtil -- global ab 11.0+
local CHAT_IM_DEFAULT_FONT_SIZE = 12
local CHAT_IM_MIN_FONT_SIZE = 8
local CHAT_IM_MAX_FONT_SIZE = 24

local regionTable = { "US", "KR", "EU", "TW", "CN" }
local regionKey = regionTable[GetCurrentRegion()] or "EU" -- or EU for PTR because that is region 90+

local function sanitizeRealm(realm)
	if not realm or realm == "" then realm = GetRealmName() or "Unknown" end
	return realm:gsub("%s+", "")
end

local function TagPlayerMenu(root, targetName, unit, isBN, bnetID, lineID, chatType, chatTarget, chatFrame)
	if not (root and root.SetTag and unit) then return end

	root:SetTag("MENU_UNIT_FRIEND", {
		name = unit,
		lineID = tonumber(lineID) or 0,
		chatType = chatType or (isBN and "BN_WHISPER" or "WHISPER"),
		chatTarget = chatTarget or unit or targetName,
		chatFrame = chatFrame,
		bnetIDAccount = bnetID,
	})
end

local function PlayerMenuGenerator(owner, root, targetName, isBN, bnetID, lineID, chatType, chatTarget)
	root:CreateTitle(targetName)

	local unit, riolink, wclLink
	if isBN and bnetID then
		local info = C_BattleNet.GetAccountInfoByID(bnetID)
		if info and info.gameAccountInfo then
			-- check for online and same game version
			if
				info.gameAccountInfo.isOnline
				and WOW_PROJECT_ID == info.gameAccountInfo.wowProjectID
				and BNET_CLIENT_WOW == info.gameAccountInfo.clientProgram
				and info.gameAccountInfo.regionID == GetCurrentRegion()
			then
				unit = info.gameAccountInfo.characterName .. "-" .. sanitizeRealm(info.gameAccountInfo.realmName)
				riolink = "https://raider.io/characters/"
					.. string.lower(regionKey)
					.. "/"
					.. string.lower(info.gameAccountInfo.realmDisplayName:gsub("%s", "-"))
					.. "/"
					.. info.gameAccountInfo.characterName
				wclLink = "https://www.warcraftlogs.com/character/"
					.. string.lower(regionKey)
					.. "/"
					.. string.lower(info.gameAccountInfo.realmDisplayName:gsub("%s", "-"))
					.. "/"
					.. info.gameAccountInfo.characterName
			end
		end
	else
		if nil == targetName:match("-") then
			-- no minus means same realm so get my realm and add it
			targetName = targetName .. "-" .. (GetRealmName()):gsub("%s", "")
		end
		unit = targetName
		if targetName:match("-") then
			local char, realm = targetName:match("^([^%-]+)%-(.+)$")
			if char and realm then
				riolink = "https://raider.io/characters/" .. string.lower(regionKey) .. "/" .. string.lower(realm:gsub("%s+", "-")) .. "/" .. char
				wclLink = "https://www.warcraftlogs.com/character/" .. string.lower(regionKey) .. "/" .. string.lower(realm:gsub("%s+", "-")) .. "/" .. char
			end
		end
	end
	TagPlayerMenu(root, targetName, unit, isBN, bnetID, lineID, chatType, chatTarget, owner)
	if unit then
		root:CreateDivider()
		root:CreateTitle(UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_INTERACT)
		root:CreateButton(INVITE, function(unit) C_PartyInfo.InviteUnit(unit) end, unit)
		root:CreateDivider()
		root:CreateTitle(UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER)
		root:CreateButton(COPY_CHARACTER_NAME, function(unit) StaticPopup_Show("EQOL_URL_COPY", nil, nil, unit) end, unit)
	end

	if not isBN and unit then
		local label = C_FriendList.IsIgnored(targetName) and UNIGNORE_QUEST or IGNORE
		local function toggleIgnore(name) ChatIM:ToggleIgnore(name) end
		root:CreateButton(label, toggleIgnore, targetName)
	end

	if riolink and addon.db["enableChatIMRaiderIO"] then
		root:CreateDivider()
		root:CreateTitle("RaiderIO")
		root:CreateButton(L["RaiderIOUrl"], function(link) StaticPopup_Show("EQOL_URL_COPY", nil, nil, link) end, riolink)
	end
	if wclLink and addon.db["enableChatIMWCL"] then
		root:CreateDivider()
		root:CreateTitle("Warcraftlogs")
		root:CreateButton(L["WCLUrl"], function(link) StaticPopup_Show("EQOL_URL_COPY", nil, nil, link) end, wclLink)
	end
end

StaticPopupDialogs["EQOL_URL_COPY"] = {
	text = CALENDAR_COPY_EVENT,
	button1 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 320,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnShow = function(self, data)
		local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
		if editBox then
			editBox:SetText(data or "")
			editBox:SetFocus()
			editBox:HighlightText()
		end
	end,
}

StaticPopupDialogs["EQOL_LINK_WARNING"] = {
	text = L["communityWarningLink"],
	button1 = CLOSE,
	hasEditBox = false,
	editBoxWidth = 320,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

ChatIM.storage = ChatIM.storage or CreateFrame("Frame")
ChatIM.activeTab = nil
ChatIM.insertLinkHooked = ChatIM.insertLinkHooked or false
ChatIM.hooksSet = ChatIM.hooksSet or false
ChatIM.inactiveAlpha = 0.6
ChatIM.pendingShow = false
ChatIM.wasOpenBeforeCombat = false
ChatIM.soundQueue = {}
ChatIM.inCombat = false

function ChatIM:IsChatMessagingRestricted()
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return true end

	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	local restrictionStates = Enum and Enum.AddOnRestrictionState
	local restrictedActions = _G.C_RestrictedActions
	if not (restrictionTypes and restrictedActions and restrictedActions.GetAddOnRestrictionState) then return false end

	local chatRestriction = restrictionTypes.Chat
	if not chatRestriction then return false end

	local activeState = restrictionStates and restrictionStates.Active or 2
	return restrictedActions.GetAddOnRestrictionState(chatRestriction) == activeState
end

function ChatIM:UpdateAlpha()
	if not addon.db["enableChatIMFade"] then return end
	if not self.frame then return end
	local tab = self.activeTab and self.tabs[self.activeTab]
	local focus = MouseIsOver(self.frame) or (tab and tab.edit and tab.edit:HasFocus())
	if focus then
		self.frame:SetAlpha(1)
	else
		self.frame:SetAlpha(self.inactiveAlpha)
	end
end

function ChatIM:SetMaxHistoryLines(val)
	self.maxHistoryLines = val or self.maxHistoryLines or 250
	if self.history then
		for partner, lines in pairs(self.history) do
			while #lines > self.maxHistoryLines do
				table.remove(lines, 1)
			end
		end
	end
end

function ChatIM:GetFontSize()
	local size = tonumber(addon.db and addon.db.chatIMFontSize) or CHAT_IM_DEFAULT_FONT_SIZE
	if size < CHAT_IM_MIN_FONT_SIZE then return CHAT_IM_MIN_FONT_SIZE end
	if size > CHAT_IM_MAX_FONT_SIZE then return CHAT_IM_MAX_FONT_SIZE end
	return math.floor(size + 0.5)
end

function ChatIM:ApplyFontSizeToTab(tab)
	if not tab then return end
	local size = self:GetFontSize()
	local font, flags
	if ChatFontNormal and ChatFontNormal.GetFont then
		local fontFile, _, fontFlags = ChatFontNormal:GetFont()
		font = fontFile
		flags = fontFlags
	end
	font = font or STANDARD_TEXT_FONT
	if tab.msg and tab.msg.SetFont then tab.msg:SetFont(font, size, flags) end
	if tab.edit then
		if tab.edit.SetFont then tab.edit:SetFont(font, size, flags) end
		if tab.edit.SetHeight then tab.edit:SetHeight(math.max(20, size + 8)) end
	end
end

function ChatIM:ApplyFontSize()
	if not self.tabs then return end
	for _, tab in pairs(self.tabs) do
		self:ApplyFontSizeToTab(tab)
	end
end

function ChatIM:FormatURLs(text)
	local function repl(url) return "|Hurl:" .. url .. "|h[|cffffffff" .. url .. "|r]|h" end
	text = text:gsub("https?://%S+", repl)
	text = text:gsub("www%.%S+", repl)
	return text
end

local function canUpdateLastTellTarget(target, isBN)
	if not target or not ChatFrameUtil then return false end
	if issecretvalue and issecretvalue(target) then return false end
	if canaccessvalue and not canaccessvalue(target) then return false end
	if ChatIM.IsChatMessagingRestricted and ChatIM:IsChatMessagingRestricted() then return false end
	return true
end

function ChatIM:HookInsertLink()
	if self.insertLinkHooked then return end

	local function tryInsertLink(link)
		if not link or not ChatIM.enabled then return end
		local tab = ChatIM.activeTab and ChatIM.tabs[ChatIM.activeTab]
		if not (tab and tab.edit) then return end
		if not (ChatIM.widget and ChatIM.widget.frame and ChatIM.widget.frame:IsShown()) then return end

		local hasBlizzardChatFocus = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
		if not tab.edit:HasFocus() and hasBlizzardChatFocus then return end

		tab.edit:Insert(link)
		tab.edit:SetFocus()
		return true
	end

	if ChatFrameUtil and type(ChatFrameUtil.InsertLink) == "function" then hooksecurefunc(ChatFrameUtil, "InsertLink", tryInsertLink) end
	self.insertLinkHooked = true
end

local function ensureChatIMFrameData()
	if not addon.db then addon.db = {} end
	if type(addon.db.chatIMFrameData) ~= "table" then addon.db.chatIMFrameData = {} end
	local status = addon.db.chatIMFrameData
	if type(status.width) ~= "number" then status.width = 400 end
	if type(status.height) ~= "number" then status.height = 300 end
	return status
end

local function saveChatIMFrameData(widgetFrame)
	local status = ensureChatIMFrameData()
	if not widgetFrame or not widgetFrame.frame then return end
	local frame = widgetFrame.frame
	status.width = frame:GetWidth()
	status.height = frame:GetHeight()
	local top = frame:GetTop()
	local left = frame:GetLeft()
	if top then status.top = top end
	if left then status.left = left end
end

local function positionNativeWindow(frame)
	local status = ensureChatIMFrameData()
	frame:ClearAllPoints()
	if type(status.left) == "number" and type(status.top) == "number" then
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", status.left, status.top)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:SetSize(status.width or 400, status.height or 300)
end

local function anchorFrameToCurrentScreenPosition(frame)
	if not frame or not UIParent or not frame.GetLeft or not frame.GetTop then return end
	local left = frame:GetLeft()
	local top = frame:GetTop()
	if not left or not top then return end

	local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
	local parentScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
	if frameScale <= 0 then frameScale = 1 end
	if parentScale <= 0 then parentScale = 1 end

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * frameScale / parentScale, top * frameScale / parentScale)
end

local function getButtonTextWidth(button)
	local fontString = button and button.GetFontString and button:GetFontString()
	return fontString and fontString:GetStringWidth() or 0
end

local function setNativeTabWidth(button)
	local width = math.max(72, math.min(150, getButtonTextWidth(button) + 26))
	if PanelTemplates_TabResize and button.Left and button.Right and button.Middle then
		button.textWidth = getButtonTextWidth(button)
		PanelTemplates_TabResize(button, button.sizePadding or 0, nil, 72, 150, button.textWidth)
	else
		button:SetWidth(width)
	end
end

local function updateChatIMTabColor(button, selected)
	if FCFTab_UpdateColors and button.ActiveLeft and button.ActiveMiddle and button.ActiveRight then
		FCFTab_UpdateColors(button, selected)
	elseif button.SetButtonState then
		button:SetButtonState(selected and "PUSHED" or "NORMAL", selected)
	end
	button:SetAlpha(selected and 1 or 0.75)
end

local function createChatIMTabButton(parent)
	local button = CreateFrame("Button", nil, parent, "ChatTabArtTemplate")
	button:SetHeight(32)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", button, "CENTER", 0, -5)
	text:SetJustifyH("CENTER")
	button.Text = text
	button:SetFontString(text)
	if button.glow then button.glow:Hide() end
	updateChatIMTabColor(button, false)
	return button
end

local function createNativeWindow()
	local frame = CreateFrame("Frame", "EnhanceQoLChatIMFrame", UIParent, "BackdropTemplate")
	frame:SetSize(400, 300)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(280, 180)
	else
		frame:SetMinResize(280, 180)
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetFrameStrata("MEDIUM")
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:SetScript("OnDragStart", function(self)
		anchorFrameToCurrentScreenPosition(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		saveChatIMFrameData({ frame = self })
	end)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -14)
	title:SetText(L["Instant Chats"])
	frame.title = title

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
	close:SetScript("OnClick", function() ChatIM:HideWindow() end)

	local tabBar = CreateFrame("Frame", nil, frame)
	tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -28)
	tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -28)
	tabBar:SetHeight(32)
	frame.tabBar = tabBar

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 18)
	frame.content = content

	local sizer = CreateFrame("Button", nil, frame)
	sizer:SetSize(16, 16)
	sizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	sizer:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		self:SetButtonState("PUSHED", true)
		if self:GetHighlightTexture() then self:GetHighlightTexture():Hide() end
		anchorFrameToCurrentScreenPosition(frame)
		frame:StartSizing("BOTTOMRIGHT")
	end)
	sizer:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return end
		self:SetButtonState("NORMAL")
		if self:GetHighlightTexture() then self:GetHighlightTexture():Show() end
		frame:StopMovingOrSizing()
		saveChatIMFrameData({ frame = frame })
	end)

	frame:HookScript("OnSizeChanged", function(self) saveChatIMFrameData({ frame = self }) end)
	positionNativeWindow(frame)
	frame:Hide()
	return {
		frame = frame,
	}
end

local function createNativeTabGroup(owner, parent)
	local tabGroup = {
		frame = parent,
		tabs = {},
		tabList = {},
	}

	function tabGroup:SetTabs(tabList)
		self.tabList = tabList or {}
		for index, button in ipairs(self.tabs) do
			button:Hide()
			button.value = nil
		end

		local previous
		for index, data in ipairs(self.tabList) do
			local button = self.tabs[index]
			if not button then
				button = createChatIMTabButton(self.frame)
				button:SetScript("OnClick", function(btn, mouseButton)
					if mouseButton == "RightButton" then
						owner:RemoveTab(btn.value)
					else
						owner:SelectTab(self, btn.value)
					end
				end)
				self.tabs[index] = button
			end
			button.value = data.value
			button:SetText(data.text or data.value or "")
			button:ClearAllPoints()
			if previous then
				button:SetPoint("LEFT", previous, "RIGHT", -8, 0)
			else
				button:SetPoint("LEFT", self.frame, "LEFT", -2, 0)
			end
			button:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
			setNativeTabWidth(button)
			button:Show()
			previous = button
		end
		self:UpdateSelected()
	end

	function tabGroup:UpdateSelected()
		for _, button in ipairs(self.tabs) do
			if button.value then
				updateChatIMTabColor(button, button.value == owner.activeTab)
			end
		end
	end

	function tabGroup:SelectTab(value)
		owner:SelectTab(self, value)
	end

	return tabGroup
end

function ChatIM:CreateUI()
	if self.widget then return end
	self:HookInsertLink()
	local frame = createNativeWindow()
	frame.frame:SetAlpha(0.4)
	frame.frame:HookScript("OnMouseUp", function() saveChatIMFrameData(frame) end)
	frame.frame:HookScript("OnEnter", function() ChatIM:UpdateAlpha() end)
	frame.frame:HookScript("OnLeave", function()
		C_Timer.After(5, function() ChatIM:UpdateAlpha() end)
	end)
	saveChatIMFrameData(frame)

	local tabGroup = createNativeTabGroup(self, frame.frame.tabBar)

	self.widget = frame
	self.frame = frame.frame
	self.contentFrame = frame.frame.content
	self.tabGroup = tabGroup
	self.tabs = {}
	self.tabList = {}

	if not self.hooksSet then
		self.frame:HookScript("OnMouseDown", ChatIM.ClearEditFocus)
		WorldFrame:HookScript("OnMouseDown", ChatIM.ClearEditFocus)
		self.hooksSet = true
	end

	self:UpdateAlpha()
end

function ChatIM:RefreshTabCallbacks()
	if not self.tabGroup or not self.tabGroup.tabs then return end
	for _, btn in ipairs(self.tabGroup.tabs) do
		if btn.value then
			local data = ChatIM.tabs[btn.value]
			if data and data.label then
				btn:SetText(data.label)
				setNativeTabWidth(btn)
			end
		end
	end
	if self.tabGroup.UpdateSelected then self.tabGroup:UpdateSelected() end
end

function ChatIM:SelectTab(widget, value)
	if self.activeTab == value then
		local current = self.tabs[value]
		if current and current.unread then
			current.unread = false
			self:StopTabFlash(value)
			self:UpdateTabLabel(value)
		elseif widget and widget.UpdateSelected then
			widget:UpdateSelected()
		end
		return
	end

	if self.activeTab then
		local old = self.tabs[self.activeTab]
		if old and old.msg then
			old.msg:SetParent(self.storage)
			old.msg:Hide()
			if old.edit then
				old.edit:SetParent(ChatIM.storage)
				old.edit:Hide()
			end
		end
	end

	self.activeTab = value

	local tab = self.tabs[value]
	if not tab then return end
	tab.unread = false
	self:StopTabFlash(value)

	local content = self.contentFrame
	if not content then return end

	tab.msg:SetParent(content)
	tab.msg:Show()
	-- ensure the message frame fills the new parent
	tab.msg:ClearAllPoints()
	tab.msg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -2)
	tab.msg:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -2)
	tab.msg:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 28)

	if tab.edit then
		tab.edit:SetParent(content)
		tab.edit:ClearAllPoints()
		tab.edit:SetPoint("LEFT", content, "LEFT", 0, 2)
		tab.edit:SetPoint("RIGHT", content, "RIGHT", 0, 2)
		tab.edit:SetPoint("BOTTOM", content, "BOTTOM", 0, 2)
		tab.edit:Show()
	end

	self:UpdateTabLabel(value)
	if widget and widget.UpdateSelected then widget:UpdateSelected() end
end

function ChatIM:CreateTab(sender, isBN, bnetID, battleTag)
	if issecretvalue and issecretvalue(sender) then return end
	self:CreateUI()
	if self.tabs[sender] then return end

	local displayName = Ambiguate(sender, "short")

	if isBN and not battleTag and bnetID then
		local info = C_BattleNet.GetAccountInfoByID(bnetID)
		if info then battleTag = info.battleTag end
	end

	local smf = CreateFrame("ScrollingMessageFrame", nil, ChatIM.storage)
	-- we'll anchor later when the tab becomes active
	smf:SetAllPoints(ChatIM.storage)
	smf:SetJustifyH("LEFT")
	smf:SetFading(false)
	smf:SetMaxLines(ChatIM.maxHistoryLines)
	smf:SetHyperlinksEnabled(true)
	-- enable wheel scrolling
	smf:EnableMouseWheel(true)
	smf:SetScript("OnMouseWheel", function(frame, delta)
		if delta > 0 then
			if IsShiftKeyDown() then
				frame:ScrollToTop()
			else
				frame:ScrollUp()
			end
		elseif delta < 0 then
			if IsShiftKeyDown() then
				frame:ScrollToBottom()
			else
				frame:ScrollDown()
			end
		end
	end)
	smf:SetScript("OnHyperlinkClick", function(frame, linkData, text, button)
		local linkType, payload = linkData:match("^(%a+):(.+)$")

		if linkType == "url" then
			StaticPopup_Show("EQOL_URL_COPY", nil, nil, payload)
			return
		end

		if linkType == "player" or linkType == "BNplayer" then
			if button == "RightButton" then
				local name, lineID, chatType, chatTarget
				local parsedBnetID
				if linkType == "BNplayer" then
					name, parsedBnetID, lineID, chatType, chatTarget = strsplit(":", payload)
					parsedBnetID = tonumber(parsedBnetID) or bnetID
				else
					name, lineID, chatType, chatTarget = strsplit(":", payload)
				end
				name = Ambiguate(name, "none")
				local bn = linkType == "BNplayer"
				MU.CreateContextMenu(frame, PlayerMenuGenerator, name, bn, parsedBnetID, lineID, chatType, chatTarget)
			end
			return
		end
		if linkType == "clubTicket" then
			-- Special case - because of Taint need to funnel it through blizzard frame
			StaticPopup_Show("EQOL_LINK_WARNING", nil, nil, payload)
			DEFAULT_CHAT_FRAME:AddMessage(text)
			return
		end

		if linkType == "censoredmessage" then
			local _, censorID = string.split(":", linkData)
			if censorID then
				_G.C_ChatInfo.UncensorChatLine(censorID)
				local text = C_ChatInfo.GetChatLineText(censorID)
				if text then
					text = ChatIM:FormatURLs(text)
					local hidden = CENSORED_MESSAGE_HIDDEN:format(sender, censorID)
					local report = CENSORED_MESSAGE_REPORT:format(censorID)
					local tabData = ChatIM.tabs[sender]
					local key = tabData and tabData.isBN and tabData.battleTag or sender
					local history = key and ChatIM.history[key]
					local replaced
					if history then
						for i, line in ipairs(history) do
							if line:find(hidden, 1, true) then
								local escHidden = hidden:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
								local escReport = report:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
								history[i] = line:gsub(escHidden, text, 1):gsub(escReport, "", 1)
								replaced = true
								break
							end
						end
					end
					if replaced and history then
						frame:Clear()
						for _, line in ipairs(history) do
							if tabData and tabData.isBN then
								frame:AddMessage(string.format(line, sender))
							else
								frame:AddMessage(line)
							end
						end
					end
				end
			end
			return
		end

		if not C_Glue.IsOnGlueScreen() then SetItemRef(linkData, text, button, frame) end
	end)
	smf:SetScript("OnHyperlinkEnter", function(self, linkData)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(linkData)
	end)
	smf:SetScript("OnHyperlinkLeave", GameTooltip_Hide)

	self.tabs[sender] = {
		msg = smf,
		isBN = isBN,
		bnetID = bnetID,
		battleTag = battleTag,
		displayName = displayName,
		unread = false,
	}
	self.tabs[sender].target = sender

	local historyKey = isBN and battleTag or sender
	if historyKey and ChatIM.history[historyKey] then
		-- purge excessive saved lines on load
		while #ChatIM.history[historyKey] > ChatIM.maxHistoryLines do
			table.remove(ChatIM.history[historyKey], 1)
		end
		smf:SetMaxLines(ChatIM.maxHistoryLines)

		for _, line in ipairs(ChatIM.history[historyKey]) do
			if isBN then
				smf:AddMessage(string.format(line, sender, sender))
			else
				smf:AddMessage(line)
			end
		end
	end
	-- will be parented/anchored once the tab becomes active
	local eb = CreateFrame("EditBox", nil, ChatIM.storage, "InputBoxTemplate")
	eb:SetAutoFocus(false)
	eb:SetScript("OnEditFocusGained", function() ChatIM:UpdateAlpha() end)
	eb:SetScript("OnEditFocusLost", function()
		C_Timer.After(5, function() ChatIM:UpdateAlpha() end)
	end)
	eb:SetScript("OnEnterPressed", function(self)
		local txt = self:GetText()
		local tgt = ChatIM.activeTab or sender
		if txt == "" or not tgt then
			self:ClearFocus()
			return
		end
		if ChatIM:IsChatMessagingRestricted() then return end

		self:SetText("")
		local tab = ChatIM.tabs[tgt]
		if tab and tab.isBN and tab.bnetID then
			C_BattleNet.SendWhisper(tab.bnetID, txt)
		else
			C_ChatInfo.SendChatMessage(txt, "WHISPER", nil, tgt)
		end
		self:ClearFocus()
	end)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	self.tabs[sender].edit = eb
	self:ApplyFontSizeToTab(self.tabs[sender])

	table.insert(self.tabList, { text = displayName, value = sender })
	self.tabGroup:SetTabs(self.tabList)
	if not self.activeTab then self.tabGroup:SelectTab(sender) end
	self:RefreshTabCallbacks()
	self:UpdateTabLabel(sender)
end

function ChatIM:AddMessage(partner, text, outbound, isBN, bnetID)
	if issecretvalue and issecretvalue(partner) then return end
	local accountTag
	if isBN and bnetID then
		local info = C_BattleNet.GetAccountInfoByID(bnetID)
		if info then accountTag = info.battleTag end
	end
	self:CreateTab(partner, isBN, bnetID, accountTag)
	-- make sure the main window is visible
	if self.widget and self.widget.frame and not self.widget.frame:IsShown() then
		if addon.db and addon.db["chatIMHideInCombat"] and ChatIM.inCombat then
			ChatIM.pendingShow = true
		else
			UIFrameFlashStop(self.widget.frame) -- stop any pending flash
			ChatIM:ShowWindow()
		end
	end
	local tab = self.tabs[partner]
	-- New message formatting: recolour whole line and show "You" for outbound
	local timestamp = date("%H:%M")
	local shortName = outbound and AUCTION_HOUSE_SELLER_YOU or Ambiguate(partner, "short")
	local prefix = "|cff999999" .. timestamp .. "|r"
	local formattedText = self:FormatURLs(text)
	local storeText = formattedText:gsub("%%", "%%%%")
	local nameLink
	if isBN then
		nameLink = string.format("|HBNplayer:%s:%s|h[%s]|h", partner, tostring(bnetID or ""), shortName)
	else
		nameLink = string.format("|Hplayer:%s|h[%s]|h", partner, shortName)
	end
	local cHex = getMessageColorHex(outbound, isBN)

	local line = string.format("%s %s: %s", prefix, applyMessageColor(nameLink, cHex), applyMessageColor(formattedText, cHex))
	tab.msg:AddMessage(line)
	local historyKey = isBN and tab.battleTag or partner
	local storeLine
	if isBN then
		local nameLinkFmt
		if outbound then
			nameLinkFmt = "|HBNplayer:%s:" .. tostring(bnetID or "") .. "|h[" .. AUCTION_HOUSE_SELLER_YOU .. "]|h"
		else
			nameLinkFmt = "|HBNplayer:%s:" .. tostring(bnetID or "") .. "|h[%s]|h"
		end
		storeLine = string.format("%s %s: %s", prefix, applyMessageColor(nameLinkFmt, cHex), applyMessageColor(storeText, cHex))
	else
		storeLine = line
	end
	if historyKey then
		ChatIM.history[historyKey] = ChatIM.history[historyKey] or {}
		table.insert(ChatIM.history[historyKey], storeLine)
		while #ChatIM.history[historyKey] > ChatIM.maxHistoryLines do
			table.remove(ChatIM.history[historyKey], 1)
		end
	end
	tab.msg:SetMaxLines(ChatIM.maxHistoryLines)

	if canUpdateLastTellTarget(partner, isBN) then
		if outbound then
			if isBN then
				ChatFrameUtil.SetLastToldTarget(partner, "BN_WHISPER")
			else
				ChatFrameUtil.SetLastToldTarget(partner, "WHISPER")
			end
		else
			if isBN then
				ChatFrameUtil.SetLastTellTarget(partner, "BN_WHISPER")
			else
				ChatFrameUtil.SetLastTellTarget(partner, "WHISPER")
			end
		end
	end

	if self.activeTab ~= partner then
		tab.unread = true
		self:UpdateTabLabel(partner)
		self:StartTabFlash(partner)
	end
end

function ChatIM:RemoveTab(sender)
	local tab = self.tabs[sender]
	if not tab then return end
	self:StopTabFlash(sender)
	if self.activeTab == sender then
		self.activeTab = nil
	end

	if tab.msg then
		tab.msg:SetParent(nil)
		tab.msg:Hide()
	end
	if tab.edit then
		tab.edit:SetParent(nil)
		tab.edit:Hide()
	end
	for i, t in ipairs(self.tabList) do
		if t.value == sender then
			table.remove(self.tabList, i)
			break
		end
	end
	self.tabs[sender] = nil
	self.tabGroup:SetTabs(self.tabList)
	self:RefreshTabCallbacks()
	if #self.tabList == 0 then
		self:HideWindow()
		UIFrameFlashStop(self.widget.frame)
	else
		local last = self.tabList[#self.tabList]
		if last then self.tabGroup:SelectTab(last.value) end
	end
end

function ChatIM:Toggle()
	self:CreateUI()
	if self.widget.frame:IsShown() then
		UIFrameFlashStop(self.widget.frame)
		self:HideWindow()
	else
		UIFrameFlashStop(self.widget.frame)
		self:ShowWindow()
		-- reselect previously active tab so messages are visible
		if self.activeTab then
			self.tabGroup:SelectTab(self.activeTab)
		elseif self.tabList[1] then
			self.tabGroup:SelectTab(self.tabList[1].value)
		end
		self:UpdateAlpha()
	end
end

function ChatIM:Flash()
	if self.widget and not self.widget.frame:IsShown() then UIFrameFlash(self.widget.frame, 0.2, 0.8, 1, false, 0, 1) end
end

function ChatIM:StartTabFlash(sender)
	if not self.tabGroup or not self.tabGroup.tabs then return end
	for _, btn in ipairs(self.tabGroup.tabs) do
		if btn.value == sender then
			local flashRegion = btn.glow or btn
			if flashRegion.Show then flashRegion:Show() end
			if not UIFrameIsFlashing(flashRegion) then UIFrameFlash(flashRegion, 0.8, 0.8, -1, true, 0.6, 0) end
			break
		end
	end
end

function ChatIM:StopTabFlash(sender)
	if not self.tabGroup or not self.tabGroup.tabs then return end
	for _, btn in ipairs(self.tabGroup.tabs) do
		if btn.value == sender then
			local flashRegion = btn.glow or btn
			UIFrameFlashStop(flashRegion)
			if flashRegion.Hide then flashRegion:Hide() end
			break
		end
	end
end

function ChatIM:UpdateTabLabel(sender)
	if not self.tabGroup or not self.tabList then return end
	local tab = self.tabs[sender]
	if not tab then return end
	local baseName = tab.displayName or Ambiguate(sender, "short")
	local label = tab.unread and ("* " .. baseName) or baseName
	tab.label = label
	for _, t in ipairs(self.tabList) do
		if t.value == sender then
			t.text = label
			break
		end
	end
	local current = self.activeTab
	self.tabGroup:SetTabs(self.tabList)
	if current then self.tabGroup:SelectTab(current) end
	self:RefreshTabCallbacks()
end

function ChatIM:GetOpenTabs()
	local entries = {}
	if not self.tabList then return entries end

	for _, item in ipairs(self.tabList) do
		local tab = self.tabs and self.tabs[item.value]
		local baseName = (tab and tab.displayName) or Ambiguate(item.value, "short")
		table.insert(entries, {
			value = item.value,
			label = (tab and tab.label) or item.text or baseName,
			baseName = baseName,
			unread = tab and tab.unread or false,
		})
	end

	table.sort(entries, function(a, b)
		if a.unread ~= b.unread then return a.unread end
		return string.lower(a.baseName or a.label or "") < string.lower(b.baseName or b.label or "")
	end)

	return entries
end

function ChatIM:FocusConversation(sender, focusEdit)
	if not sender then return end
	self:CreateUI()
	if not self.tabs or not self.tabs[sender] then return end

	if self.widget and self.widget.frame then
		UIFrameFlashStop(self.widget.frame)
		if not self.widget.frame:IsShown() then self:ShowWindow() end
	end

	if self.tabGroup then self.tabGroup:SelectTab(sender) end

	if focusEdit then RunNextFrame(function()
		local tab = ChatIM.tabs and ChatIM.tabs[sender]
		if tab and tab.edit and tab.edit:IsShown() then tab.edit:SetFocus() end
	end) end
end

function ChatIM:ClearEditFocus()
	local tab = ChatIM.activeTab and ChatIM.tabs[ChatIM.activeTab]
	if tab and tab.edit then tab.edit:ClearFocus() end
end

local ANIM_OFFSET = 80

function ChatIM:EnsureAnimations()
	if not self.widget or not self.widget.frame or self.widget.frame.slideIn then return end
	local frame = self.widget.frame
	frame.slideIn = frame:CreateAnimationGroup()
	local sin = frame.slideIn:CreateAnimation("Translation")
	sin:SetDuration(0.25)
	sin:SetSmoothing("OUT")
	frame.slideInTrans = sin

	frame.slideOut = frame:CreateAnimationGroup()
	local sout = frame.slideOut:CreateAnimation("Translation")
	sout:SetDuration(0.25)
	sout:SetSmoothing("IN")
	frame.slideOutTrans = sout
	frame.slideOut:SetScript("OnFinished", function()
		frame:Hide()
		if ChatIM.animFinal then
			frame:ClearAllPoints()
			for i, p in ipairs(ChatIM.animFinal) do
				frame:SetPoint(unpack(p))
			end
		end
	end)
end

function ChatIM:ShowWindow()
	self:CreateUI()
	if not self.widget or not self.widget.frame or self.widget.frame:IsShown() then return end
	UIFrameFlashStop(self.widget.frame)
	if addon.db and addon.db["chatIMUseAnimation"] then
		self:EnsureAnimations()
		local frame = self.widget.frame
		self.animFinal = {}
		for i = 1, frame:GetNumPoints() do
			self.animFinal[i] = { frame:GetPoint(i) }
		end
		frame:ClearAllPoints()
		for i, p in ipairs(self.animFinal) do
			if i == 1 then
				frame:SetPoint(p[1], p[2], p[3], (p[4] or 0) + ANIM_OFFSET, p[5])
			else
				frame:SetPoint(unpack(p))
			end
		end
		frame:Show()
		frame.slideInTrans:SetOffset(-ANIM_OFFSET, 0)
		frame.slideIn:SetScript("OnFinished", function()
			frame:ClearAllPoints()
			for _, p in ipairs(ChatIM.animFinal) do
				frame:SetPoint(unpack(p))
			end
		end)
		frame.slideIn:Play()
	else
		self.widget.frame:Show()
	end
end

function ChatIM:HideWindow()
	if not self.widget or not self.widget.frame or not self.widget.frame:IsShown() then return end
	UIFrameFlashStop(self.widget.frame)
	if addon.db and addon.db["chatIMUseAnimation"] then
		self:EnsureAnimations()
		local frame = self.widget.frame
		self.animFinal = {}
		for i = 1, frame:GetNumPoints() do
			self.animFinal[i] = { frame:GetPoint(i) }
		end
		frame.slideOutTrans:SetOffset(ANIM_OFFSET, 0)
		frame.slideOut:Play()
	else
		self.widget.frame:Hide()
	end
end

function ChatIM:StartWhisper(target, bnetID, accountTag)
	if not target then return end
	if self:IsChatMessagingRestricted() then return false end
	if bnetID then
		self:CreateTab(target, true, bnetID, accountTag)
	else
		self:CreateTab(target)
	end
	self:FocusConversation(target)
	return true
end
