-- luacheck: globals NineSliceUtil PlayerLocation C_ReportSystem REPORT_CHAT CENSORED_MESSAGE_HIDDEN CENSORED_MESSAGE_REPORT PanelTemplates_TabResize FCFTab_UpdateColors
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

function ChatIM:ConfigureWhisperInput(edit)
	-- Match the client chat input, including its extra room for hyperlink metadata.
	local native = _G.ChatFrame1EditBox
	local total = native and native.GetMaxBytes and native:GetMaxBytes()
	local visible = native and native.GetVisibleTextByteLimit and native:GetVisibleTextByteLimit()
	edit:SetMaxBytes(total and total > 0 and total or 1280)
	edit:SetVisibleTextByteLimit(visible and visible > 0 and visible or 255)
end

function ChatIM:UpdateWhisperInputLayout(tab)
	local edit, scroll = tab and tab.edit, tab and tab.editScroll
	if not edit or not scroll or tab.inputLayoutBusy then return end
	tab.inputLayoutBusy = true
	local size = self:GetFontSize()
	local width = scroll:GetWidth()
	if width and width > 0 and edit:GetWidth() ~= width then edit:SetWidth(width) end
	local height = math.max(1, edit:GetNumLines() or 1) * size
	local available = self.contentFrame and self.contentFrame:GetHeight() or 200
	local visible = math.min(height, math.max(size, math.min(size * 4, available * 0.4 - 12)))
	if edit:GetHeight() ~= height then edit:SetHeight(height) end
	if scroll:GetHeight() ~= visible then scroll:SetHeight(visible) end
	scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll() or 0, math.max(0, height - visible)))
	if self.tabs[self.activeTab] == tab then
		if self.frame and self.frame.inputBackground then self.frame.inputBackground:SetHeight(visible + 22) end
		tab.msg:SetPoint("BOTTOMLEFT", self.contentFrame, "BOTTOMLEFT", 0, visible + 27)
	end
	tab.inputLayoutBusy = nil
end

function ChatIM:ScrollWhisperCursor(tab, y, height)
	self:UpdateWhisperInputLayout(tab)
	local scroll = tab.editScroll
	local offset = scroll:GetVerticalScroll() or 0
	local top = -y
	if top < offset then
		offset = top
	elseif top + height > offset + scroll:GetHeight() then
		offset = top + height - scroll:GetHeight()
	end
	scroll:SetVerticalScroll(math.max(0, math.min(offset, math.max(0, tab.edit:GetHeight() - scroll:GetHeight()))))
end

function ChatIM:SendWhisperDraft(edit, target, tab)
	if not self.enabled or not tab or self.tabs[target] ~= tab or self:IsChatMessagingRestricted() then return end
	local text = edit:GetText()
	if text == "" then return end
	local isBN = tab.isBN and tab.bnetID ~= nil
	local ok, result
	if isBN then
		ok, result = pcall(C_BattleNet.SendWhisper, tab.bnetID, text)
	else
		local characterTarget = self:UsesSurnames() and self:NormalizeCharacterName(target) or target
		ok, result = pcall(C_ChatInfo.SendChatMessage, text, "WHISPER", nil, characterTarget)
	end
	if not ok or (isBN and result == false) then
		if UIErrorsFrame then UIErrorsFrame:AddMessage(L["ChatIMSendFailed"], 1, 0.2, 0.2) end
		return
	end
	-- API acceptance is not a server delivery receipt. Never retry automatically.
	edit:SetText("")
	edit:ClearFocus()
end

ChatIM.styleDefaults = {
	chatIMBackgroundColor = { r = 0.035, g = 0.025, b = 0.015, a = 1 },
	chatIMFrameColor = { r = 0.68, g = 0.49, b = 0.24, a = 1 },
	chatIMInputBackgroundColor = { r = 0.025, g = 0.02, b = 0.015, a = 0.95 },
	chatIMInputBorderColor = { r = 0.38, g = 0.29, b = 0.17, a = 1 },
	chatIMTabBackgroundColor = { r = 0.07, g = 0.06, b = 0.05, a = 0.95 },
	chatIMTabBorderColor = { r = 0.29, g = 0.24, b = 0.17, a = 1 },
	chatIMActiveTabBackgroundColor = { r = 0.19, g = 0.14, b = 0.08, a = 0.95 },
	chatIMActiveTabBorderColor = { r = 0.68, g = 0.49, b = 0.24, a = 1 },
	chatIMTitleColor = { r = 0.95, g = 0.85, b = 0.65, a = 1 },
	chatIMTabTextColor = { r = 0.78, g = 0.72, b = 0.61, a = 1 },
	chatIMActiveTabTextColor = { r = 1, g = 0.85, b = 0.57, a = 1 },
	chatIMUnreadColor = { r = 0.7, g = 0.46, b = 0.12, a = 0.25 },
}

function ChatIM:MigrateStyleColors()
	if not addon.db or (tonumber(addon.db.chatIMStyleColorVersion) or 0) >= 2 then return end
	local background = addon.db.chatIMBackgroundColor
	if type(background) == "table" and background.r == 0.8 and background.g == 0.75 and background.b == 0.67 then
		local color = self.styleDefaults.chatIMBackgroundColor
		addon.db.chatIMBackgroundColor = { r = color.r, g = color.g, b = color.b, a = background.a or color.a }
	end
	local border = addon.db.chatIMFrameColor
	if type(border) == "table" and border.r == 1 and border.g == 1 and border.b == 1 then
		local color = self.styleDefaults.chatIMFrameColor
		addon.db.chatIMFrameColor = { r = color.r, g = color.g, b = color.b, a = border.a or color.a }
	end
	addon.db.chatIMStyleColorVersion = 2
end

function ChatIM:GetStyleColor(key)
	local default = self.styleDefaults[key]
	local color = addon.db and addon.db[key]
	if type(color) ~= "table" then color = default end
	return color.r or default.r, color.g or default.g, color.b or default.b, color.a or default.a
end

-- Chat line IDs belong to the current session and must not enter saved history.
function ChatIM:BuildPlayerLink(name, displayName, isBN, bnetID, lineID)
	if not isBN and self:UsesSurnames() then name = self:NormalizeCharacterName(name) end
	local link = isBN and ("BNplayer:" .. name .. ":" .. tostring(bnetID or "")) or ("player:" .. name)
	if not (issecretvalue and issecretvalue(lineID)) then
		lineID = tonumber(lineID)
		if lineID and lineID > 0 then link = link .. ":" .. tostring(lineID) .. ":" .. (isBN and "BN_WHISPER" or "WHISPER") end
	end
	return "|H" .. link .. "|h[" .. displayName .. "]|h"
end

function ChatIM:GetReportLocation(lineID)
	if issecretvalue and issecretvalue(lineID) then return end
	lineID = tonumber(lineID)
	if not lineID or lineID <= 0 then return end
	if not (C_ChatInfo and C_ChatInfo.IsValidChatLine and C_ChatInfo.IsValidChatLine(lineID)) then return end
	if not (PlayerLocation and PlayerLocation.CreateFromChatLineID and C_ReportSystem and C_ReportSystem.CanReportPlayer) then return end
	if not (ReportFrame and ReportFrame.InitiateReport and ReportInfo and ReportInfo.CreateReportInfoFromType and Enum and Enum.ReportType and Enum.ReportType.Chat) then return end
	local location = PlayerLocation:CreateFromChatLineID(lineID)
	if not location then return end
	-- A live chat line is not necessarily accepted as a reportable player location.
	local ok, canReport = pcall(C_ReportSystem.CanReportPlayer, location)
	if ok and not (issecretvalue and issecretvalue(canReport)) and canReport then return location end
end

function ChatIM:AddReportMenuButton(root, name, isBN, lineID)
	if not isBN and self:UsesSurnames() then name = self:NormalizeCharacterName(name) end
	if not self:GetReportLocation(lineID) then return end
	root:CreateButton(REPORT_CHAT, function()
		-- The chat line may have expired since the menu was opened.
		local location = self:GetReportLocation(lineID)
		if not location then return end
		local reportInfo = ReportInfo:CreateReportInfoFromType(Enum.ReportType.Chat)
		ReportFrame:InitiateReport(reportInfo, name, location, isBN)
	end)
end

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
	if not isBN then targetName = ChatIM:NormalizeCharacterName(targetName) end
	root:CreateTitle(targetName)
	if not isBN and chatTarget and ChatIM:UsesSurnames() then chatTarget = ChatIM:NormalizeCharacterName(chatTarget) end

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
				unit = ChatIM:NormalizeCharacterName(info.gameAccountInfo.characterName, sanitizeRealm(info.gameAccountInfo.realmName))
				if not ChatIM:UsesSurnames() then
					riolink = "https://raider.io/characters/"
						.. string.lower(regionKey)
						.. "/"
						.. addon.functions.NormalizeRaiderIORealm(info.gameAccountInfo.realmDisplayName)
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
		end
	else
		unit = targetName
		if not ChatIM:UsesSurnames() and targetName:match("-") then
			local char, realm = targetName:match("^([^%-]+)%-(.+)$")
			if char and realm then
				riolink = "https://raider.io/characters/" .. string.lower(regionKey) .. "/" .. addon.functions.NormalizeRaiderIORealm(realm) .. "/" .. char
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
		local label = ChatIM:IsPlayerIgnored(targetName) and UNIGNORE_QUEST or IGNORE
		local function toggleIgnore(name) ChatIM:ToggleIgnore(name) end
		root:CreateButton(label, toggleIgnore, targetName)
	end

	ChatIM:AddReportMenuButton(root, targetName, isBN, lineID)

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
	EditBoxOnEscapePressed = addon.functions.CancelPopupOnEscape,
	EditBoxOnEnterPressed = addon.functions.AcceptPopupOnEnter,
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

function ChatIM:GetWindowAlpha()
	if not (addon.db and addon.db.enableChatIMFade) then return 1 end
	local tab = self.activeTab and self.tabs and self.tabs[self.activeTab]
	return (MouseIsOver(self.frame) or (tab and tab.edit and tab.edit:HasFocus())) and 1 or self.inactiveAlpha
end

function ChatIM:UpdateAlpha()
	if not self.frame then return end
	local target = self:GetWindowAlpha()
	if self.frame.inputBackground then self.frame.inputBackground:SetAlpha(target < 1 and 0.3 or 1) end
	if self.frame.chatIMFade then
		if not self.frame.chatIMFade.hide then self.frame.chatIMFade.to = target end
	else
		self.frame:SetAlpha(target)
	end
end

function ChatIM:SetMaxHistoryLines(val)
	self.maxHistoryLines = val or self.maxHistoryLines or 250
	if self.history then
		for partner, lines in pairs(self.history) do
			self:TrimHistory(lines)
		end
	end
	self:QueueHistoryRefresh()
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
		self:UpdateWhisperInputLayout(tab)
	end
end

function ChatIM:ApplyFontSize()
	self:RefreshHistoryViewer()
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
	button:SetBackdropColor(ChatIM:GetStyleColor(selected and "chatIMActiveTabBackgroundColor" or "chatIMTabBackgroundColor"))
	button:SetBackdropBorderColor(ChatIM:GetStyleColor(selected and "chatIMActiveTabBorderColor" or "chatIMTabBorderColor"))
	button.Text:SetTextColor(ChatIM:GetStyleColor(selected and "chatIMActiveTabTextColor" or "chatIMTabTextColor"))
	button.glow:SetColorTexture(ChatIM:GetStyleColor("chatIMUnreadColor"))
end

function ChatIM:ApplyStyle()
	local frame = self.frame
	if not frame then return end
	frame:SetBackdropColor(self:GetStyleColor("chatIMBackgroundColor"))
	frame.inputBackground:SetBackdropColor(self:GetStyleColor("chatIMInputBackgroundColor"))
	frame.inputBackground:SetBackdropBorderColor(self:GetStyleColor("chatIMInputBorderColor"))
	frame.title:SetTextColor(self:GetStyleColor("chatIMTitleColor"))
	local r, g, b, a = self:GetStyleColor("chatIMFrameColor")
	for _, key in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do
		local piece = frame.chatIMBorder[key]
		if piece then
			piece:SetDesaturated(true)
			piece:SetVertexColor(r, g, b, a)
		end
	end
	if self.tabGroup then self.tabGroup:UpdateSelected() end
	self:UpdateAlpha()
	self:ApplyHistoryStyle()
end

local function createChatIMTabButton(parent)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	button.glow = button:CreateTexture(nil, "OVERLAY")
	button.glow:SetAllPoints()
	button.glow:SetColorTexture(0.7, 0.46, 0.12, 0.25)
	button:SetHeight(25)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER")
	text:SetJustifyH("CENTER")
	button.Text = text
	button:SetFontString(text)
	button.glow:Hide()
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
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", insets = { left = 16, right = 2, top = 18, bottom = 7 } })
	frame:SetBackdropColor(ChatIM:GetStyleColor("chatIMBackgroundColor"))
	local border = CreateFrame("Frame", nil, frame, "NineSlicePanelTemplate")
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -16)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 5)
	border:SetFrameLevel(frame:GetFrameLevel() + 1)
	NineSliceUtil.ApplyLayoutByName(border, "ButtonFrameTemplateNoPortrait")
	frame.chatIMBorder = border
	frame:SetScript("OnDragStart", function(self)
		anchorFrameToCurrentScreenPosition(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		saveChatIMFrameData({ frame = self })
	end)

	local paddedMetalArt = addon.variables and addon.variables.isForever and not addon.variables.isTBC
	local retailMetalArt = not (addon.variables and (addon.variables.isForever or addon.variables.isTBC))
	local titleParent = CreateFrame("Frame", nil, frame)
	titleParent:SetAllPoints()
	titleParent:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.titleContainer = titleParent
	local title = titleParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("CENTER", border.TopEdge, "CENTER", 0, paddedMetalArt and 21 or retailMetalArt and 9 or -3)
	title:SetText(L["Instant Chats"])
	title:SetTextColor(0.95, 0.85, 0.65)
	frame.title = title

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetFrameLevel(frame:GetFrameLevel() + 3)
	close:SetPoint("CENTER", border.TopRightCorner, "CENTER", paddedMetalArt and 33 or retailMetalArt and 19 or -1, paddedMetalArt and 23 or retailMetalArt and 9 or -1)
	frame.closeButton = close
	close:SetScript("OnClick", function() ChatIM:HideWindow() end)

	local history = CreateFrame("Button", nil, frame)
	history:SetFrameLevel(close:GetFrameLevel())
	history:SetSize(22, 22)
	history:SetPoint("RIGHT", close, "LEFT", -2, 0)
	history:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
	history:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
	history:SetScript("OnClick", function() ChatIM:OpenHistoryViewer() end)
	history:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(L["ChatIMHistoryViewer"])
		GameTooltip:AddLine("/eim history", 1, 1, 1)
		GameTooltip:Show()
	end)
	history:SetScript("OnLeave", GameTooltip_Hide)
	frame.historyButton = history

	local tabBar = CreateFrame("Frame", nil, frame)
	tabBar:SetPoint("TOPLEFT", border, "TOPLEFT", 16, -31)
	tabBar:SetPoint("TOPRIGHT", border, "TOPRIGHT", -12, -31)
	tabBar:SetHeight(25)
	frame.tabBar = tabBar

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
	content:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -16, 22)
	frame.content = content
	local input = CreateFrame("Frame", nil, content, "BackdropTemplate")
	input:SetPoint("BOTTOMLEFT", 0, -3)
	input:SetPoint("BOTTOMRIGHT", 0, -3)
	input:SetHeight(32)
	input:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	input:SetBackdropColor(0.025, 0.02, 0.015, 0.95)
	input:SetBackdropBorderColor(0.38, 0.29, 0.17, 1)
	input:SetFrameLevel(content:GetFrameLevel())
	input:EnableMouse(true)
	input:SetScript("OnMouseDown", function()
		local tab = ChatIM.activeTab and ChatIM.tabs[ChatIM.activeTab]
		if tab and tab.edit then tab.edit:SetFocus() end
	end)
	frame.inputBackground = input

	local sizer = CreateFrame("Button", nil, frame)
	sizer:SetSize(16, 16)
	sizer:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", retailMetalArt and 1 or -1, -2)
	sizer:SetFrameLevel(frame:GetFrameLevel() + 3)
	sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	frame.resizeButton = sizer
	sizer:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		self:SetButtonState("PUSHED", true)
		if self:GetHighlightTexture() then self:GetHighlightTexture():Hide() end
		local x, y = GetCursorPosition()
		local scale = frame:GetEffectiveScale() or 1
		if scale <= 0 then scale = 1 end
		self.resizeState = { x = x, y = y, width = frame:GetWidth(), height = frame:GetHeight(), scale = scale }
		anchorFrameToCurrentScreenPosition(frame)
		self:SetScript("OnUpdate", function(handle)
			local start = handle.resizeState
			local cursorX, cursorY = GetCursorPosition()
			local parentScale = UIParent:GetEffectiveScale() or 1
			local maxWidth = math.max(280, UIParent:GetWidth() * parentScale / start.scale)
			local maxHeight = math.max(180, UIParent:GetHeight() * parentScale / start.scale)
			local width = math.max(280, math.min(maxWidth, start.width + (cursorX - start.x) / start.scale))
			local height = math.max(180, math.min(maxHeight, start.height - (cursorY - start.y) / start.scale))
			if width ~= frame:GetWidth() or height ~= frame:GetHeight() then frame:SetSize(width, height) end
		end)
	end)
	sizer:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return end
		ChatIM:StopResizing(self)
	end)
	sizer:SetScript("OnHide", function(self) ChatIM:StopResizing(self) end)

	frame:HookScript("OnSizeChanged", function(self)
		if not sizer.resizeState then saveChatIMFrameData({ frame = self }) end
	end)
	positionNativeWindow(frame)
	frame:Hide()
	return {
		frame = frame,
	}
end

local function createNativeTabGroup(owner, parent)
	local viewport = CreateFrame("ScrollFrame", nil, parent)
	viewport:SetAllPoints()
	local strip = CreateFrame("Frame", nil, viewport)
	strip:SetHeight(parent:GetHeight())
	strip:SetWidth(1)
	strip:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, 0)
	viewport:SetScrollChild(strip)
	local tabGroup = {
		frame = strip,
		viewport = viewport,
		offset = 0,
		tabs = {},
		tabList = {},
	}
	local previousButton = CreateFrame("Button", nil, parent)
	previousButton:SetSize(16, 24)
	previousButton:SetPoint("LEFT")
	previousButton:SetNormalFontObject("GameFontNormal")
	previousButton:SetHighlightFontObject("GameFontHighlight")
	previousButton:SetText("<")
	local nextButton = CreateFrame("Button", nil, parent)
	nextButton:SetSize(16, 24)
	nextButton:SetPoint("RIGHT")
	nextButton:SetNormalFontObject("GameFontNormal")
	nextButton:SetHighlightFontObject("GameFontHighlight")
	nextButton:SetText(">")

	function tabGroup:ScrollBy(delta)
		local maximum = math.max(0, self.frame:GetWidth() - self.viewport:GetWidth())
		self.offset = math.max(0, math.min(maximum, self.offset + delta))
		self.viewport:SetHorizontalScroll(self.offset)
	end
	previousButton:SetScript("OnClick", function() tabGroup:ScrollBy(-120) end)
	nextButton:SetScript("OnClick", function() tabGroup:ScrollBy(120) end)
	viewport:EnableMouseWheel(true)
	viewport:SetScript("OnMouseWheel", function(_, delta) tabGroup:ScrollBy(-delta * 120) end)
	parent:HookScript("OnSizeChanged", function()
		strip:SetHeight(parent:GetHeight())
		tabGroup:SetTabs(tabGroup.tabList)
	end)

	function tabGroup:SetTabs(tabList)
		self.tabList = tabList or {}
		for index, button in ipairs(self.tabs) do
			button:Hide()
			button.value = nil
		end

		local totalWidth = 0
		local gap = 5
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
			button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", totalWidth, 0)
			setNativeTabWidth(button)
			button:Show()
			button.scrollLeft = totalWidth
			button.scrollRight = totalWidth + button:GetWidth()
			totalWidth = button.scrollRight + gap
		end
		self.frame:SetWidth(math.max(1, totalWidth - gap))
		local overflow = totalWidth - gap > parent:GetWidth()
		previousButton:SetShown(overflow)
		nextButton:SetShown(overflow)
		self.viewport:ClearAllPoints()
		self.viewport:SetPoint("TOPLEFT", parent, "TOPLEFT", overflow and 18 or 0, 0)
		self.viewport:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", overflow and -18 or 0, 0)
		self:ScrollBy(0)
		self:UpdateSelected()
	end

	function tabGroup:UpdateSelected()
		for _, button in ipairs(self.tabs) do
			if button.value then
				updateChatIMTabColor(button, button.value == owner.activeTab)
				if button.value == owner.activeTab then
					if button.scrollLeft < self.offset then
						self:ScrollBy(button.scrollLeft - self.offset)
					elseif button.scrollRight > self.offset + self.viewport:GetWidth() then
						self:ScrollBy(button.scrollRight - self.offset - self.viewport:GetWidth())
					end
				end
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
	frame.frame:SetAlpha(1)
	frame.frame:HookScript("OnMouseUp", function() saveChatIMFrameData(frame) end)
	frame.frame:HookScript("OnEnter", function() ChatIM:UpdateAlpha() end)
	frame.frame:HookScript("OnLeave", function()
		C_Timer.After(0.3, function() ChatIM:UpdateAlpha() end)
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

	self:ApplyStyle()
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
				(old.editScroll or old.edit):SetParent(ChatIM.storage)
				if old.editScroll then old.editScroll:Hide() end
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
	tab.msg:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 37)

	if tab.edit then
		local input = tab.editScroll or tab.edit
		input:SetParent(content)
		input:ClearAllPoints()
		input:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 8)
		input:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 8)
		input:Show()
		tab.edit:Show()
		self:UpdateWhisperInputLayout(tab)
	end

	self:UpdateTabLabel(value)
	if widget and widget.UpdateSelected then widget:UpdateSelected() end
end

function ChatIM:CreateTab(sender, isBN, bnetID, battleTag)
	if issecretvalue and issecretvalue(sender) then return end
	if not isBN and self:UsesSurnames() then sender = self:NormalizeCharacterName(sender) end
	self:CreateUI()
	if self.tabs[sender] then return end

	local displayName = self:GetNameDisplay(sender, isBN)

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
				name = ChatIM:GetNameDisplay(name, linkType == "BNplayer", "none")
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
						if addon.ChatHistoryStorage then addon.ChatHistoryStorage.MarkIMDirty() end
						ChatIM:QueueHistoryRefresh(key)
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
		local linkType = type(linkData) == "string" and linkData:match("^([^:]+):")
		-- These links trigger chat actions and are not tooltip hyperlinks.
		if not linkType or linkType == "player" or linkType == "BNplayer" or linkType == "url" or linkType == "clubTicket"
			or linkType == "censoredmessage" or linkType == "censoredmessagereport" then return end
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
		self:TrimHistory(ChatIM.history[historyKey])
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
	local inputTab = self.tabs[sender]
	local scroll = CreateFrame("ScrollFrame", nil, ChatIM.storage)
	scroll:SetHeight(20)
	inputTab.editScroll = scroll
	local eb = CreateFrame("EditBox", nil, scroll)
	eb:SetMultiLine(true)
	eb:SetSize(200, 20)
	eb:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
	scroll:SetScrollChild(eb)
	scroll:EnableMouse(true)
	scroll:SetScript("OnMouseDown", function() eb:SetFocus() end)
	scroll:SetScript("OnSizeChanged", function() ChatIM:UpdateWhisperInputLayout(inputTab) end)
	eb:SetScript("OnTextChanged", function() ChatIM:UpdateWhisperInputLayout(inputTab) end)
	eb:SetScript("OnCursorChanged", function(_, _, y, _, height) ChatIM:ScrollWhisperCursor(inputTab, y, height) end)
	eb:SetAutoFocus(false)
	self:ConfigureWhisperInput(eb)
	eb:SetJustifyV("TOP")
	-- Keep vertical padding outside the multiline EditBox to avoid repeated caret layout.
	eb:SetTextInsets(6, 6, 0, 0)
	eb:SetFontObject("ChatFontNormal")
	eb:SetScript("OnEditFocusGained", function() ChatIM:UpdateAlpha() end)
	eb:SetScript("OnEditFocusLost", function()
		C_Timer.After(0.3, function() ChatIM:UpdateAlpha() end)
	end)
	eb:SetScript("OnEnterPressed", function(self)
		local txt = self:GetText()
		local tgt = ChatIM.activeTab or sender
		if txt == "" or not tgt then
			self:ClearFocus()
			return
		end
		if ChatIM:IsChatMessagingRestricted() then return end

		ChatIM:SendWhisperDraft(self, tgt, ChatIM.tabs[tgt])
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

function ChatIM:AddMessage(partner, text, outbound, isBN, bnetID, lineID)
	if issecretvalue and issecretvalue(partner) then return end
	if not isBN and self:UsesSurnames() then partner = self:NormalizeCharacterName(partner) end
	local accountTag
	if isBN and bnetID then
		local info = C_BattleNet.GetAccountInfoByID(bnetID)
		if info then accountTag = info.battleTag end
	end
	self:CreateTab(partner, isBN, bnetID, accountTag)
	-- make sure the main window is visible
	if self.widget and self.widget.frame and (not self.widget.frame:IsShown() or (self.widget.frame.chatIMFade and self.widget.frame.chatIMFade.hide)) then
		if addon.db and addon.db["chatIMHideInCombat"] and ChatIM.inCombat then
			ChatIM.pendingShow = true
		else
			ChatIM:ShowWindow()
		end
	end
	local tab = self.tabs[partner]
	-- New message formatting: recolour whole line and show "You" for outbound
	local timestamp = date("%H:%M")
	local shortName = outbound and AUCTION_HOUSE_SELLER_YOU or self:GetNameDisplay(partner, isBN)
	local prefix = "|cff999999" .. timestamp .. "|r"
	local formattedText = self:FormatURLs(text)
	local storeText = formattedText:gsub("%%", "%%%%")
	local historyNameLink = self:BuildPlayerLink(partner, shortName, isBN, bnetID)
	local nameLink = self:BuildPlayerLink(partner, shortName, isBN, bnetID, not outbound and lineID or nil)
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
		storeLine = string.format("%s %s: %s", prefix, applyMessageColor(historyNameLink, cHex), applyMessageColor(formattedText, cHex))
	end
	if historyKey then
		ChatIM.history[historyKey] = ChatIM.history[historyKey] or {}
		local lines = ChatIM.history[historyKey]
		lines.timestamps = lines.timestamps or {}
		for index = #lines.timestamps + 1, #lines do lines.timestamps[index] = false end
		if isBN then lines.displayName = partner end
		table.insert(lines, storeLine)
		lines.timestamps[#lines] = time()
		if addon.ChatHistoryStorage then addon.ChatHistoryStorage.MarkIMDirty() end
		self:TrimHistory(lines)
		self:QueueHistoryRefresh()
	end
	tab.msg:SetMaxLines(ChatIM.maxHistoryLines)

	if canUpdateLastTellTarget(partner, isBN) then
		if outbound then
			if isBN then
				ChatFrameUtil.SetLastToldTarget(partner, "BN_WHISPER")
			else
				ChatFrameUtil.SetLastToldTarget(partner, "WHISPER")
			end
		elseif not ChatIM.UsesNativeWhisperSink then
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
	if tab.editScroll then
		tab.editScroll:Hide()
		tab.editScroll:SetParent(nil)
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
	else
		local last = self.tabList[#self.tabList]
		if last then self.tabGroup:SelectTab(last.value) end
	end
end

function ChatIM:Toggle()
	self:CreateUI()
	if self.widget.frame:IsShown() and not (self.widget.frame.chatIMFade and self.widget.frame.chatIMFade.hide) then
		self:HideWindow()
	else
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
	if addon.db and addon.db.chatIMHideInCombat and self.inCombat then return end
	if self.widget and not self.widget.frame:IsShown() then self:ShowWindow() end
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
	local baseName = tab.displayName or self:GetNameDisplay(sender, tab.isBN)
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
		local baseName = (tab and tab.displayName) or self:GetNameDisplay(item.value, tab and tab.isBN)
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
		self:ShowWindow()
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

function ChatIM:CancelWindowFade(frame)
	frame.chatIMFade = nil
	frame:SetScript("OnUpdate", nil)
end

function ChatIM:FadeWindow(frame, hide)
	self:CancelWindowFade(frame)
	frame.chatIMFade = { from = frame:GetAlpha(), to = hide and 0 or self:GetWindowAlpha(), elapsed = 0, duration = hide and 0.12 or 0.2, hide = hide }
	frame:SetScript("OnUpdate", function(window, elapsed)
		local fade = window.chatIMFade
		fade.elapsed = fade.elapsed + elapsed
		local progress = math.min(1, fade.elapsed / fade.duration)
		local eased = progress * progress * (3 - 2 * progress)
		window:SetAlpha(fade.from + (fade.to - fade.from) * eased)
		if progress == 1 then
			ChatIM:CancelWindowFade(window)
			if fade.hide then window:Hide() end
			ChatIM:UpdateAlpha()
		end
	end)
end

function ChatIM:ShowWindow()
	self:CreateUI()
	local frame = self.widget and self.widget.frame
	if not frame then return end
	if frame:IsShown() then
		if frame.chatIMFade and frame.chatIMFade.hide then
			self:CancelWindowFade(frame)
			self:UpdateAlpha()
		end
		return
	end
	self:CancelWindowFade(frame)
	frame:Show()
	if addon.db and addon.db.chatIMUseAnimation then
		frame:SetAlpha(0)
		self:FadeWindow(frame, false)
	else
		self:UpdateAlpha()
	end
end

function ChatIM:HideWindow()
	local frame = self.widget and self.widget.frame
	if not frame or not frame:IsShown() then return end
	if frame.chatIMFade and frame.chatIMFade.hide then return end
	if addon.db and addon.db.chatIMUseAnimation then
		self:FadeWindow(frame, true)
	else
		self:CancelWindowFade(frame)
		frame:Hide()
		self:UpdateAlpha()
	end
end

function ChatIM:StartWhisper(target, bnetID, accountTag)
	if not bnetID and self:UsesSurnames() then target = self:NormalizeCharacterName(target) end
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

function ChatIM:StopResizing(handle)
	if not handle or not handle.resizeState then return end
	handle.resizeState = nil
	handle:SetScript("OnUpdate", nil)
	handle:SetButtonState("NORMAL")
	if handle:GetHighlightTexture() then handle:GetHighlightTexture():Show() end
	if self.widget then saveChatIMFrameData(self.widget) end
end

function ChatIM:ResetWindow()
	if self.widget then self:StopResizing(self.widget.frame.resizeButton) end
	local status = ensureChatIMFrameData()
	status.width, status.height, status.left, status.top = 400, 300, nil, nil
	self:CreateUI()
	self:CancelWindowFade(self.frame)
	positionNativeWindow(self.frame)
	saveChatIMFrameData(self.widget)
	self:ShowWindow()
	self:UpdateAlpha()
end
