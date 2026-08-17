local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.ChatIcons = addon.ChatIcons or {}
local ChatIcons = addon.ChatIcons

local ICON_SIZE = 12
local URL_LINK_TYPE = "url"
local CURRENCY_LINK_PATTERN = "(|Hcurrency:(%d+)[^|]*|h%[[^%]]+%]|h%|r)"
local ITEM_LINK_PATTERN = "|Hitem:.-|h%[.-%]|h|r"

local ITEMLINK_EVENTS_FALLBACK = {
	"CHAT_MSG_LOOT",
	"CHAT_MSG_CURRENCY",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_COMMUNITIES_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_SYSTEM",
	"CHAT_MSG_ACHIEVEMENT",
	"CHAT_MSG_GUILD_ACHIEVEMENT",
	"CHAT_MSG_GUILD_ITEM_LOOTED",
}

local URL_CHAT_EVENTS_FALLBACK = {
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_COMMUNITIES_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
}

local tonumber = tonumber
local format = string.format
local GetDetailedItemLevelInfoFn = C_Item and C_Item.GetDetailedItemLevelInfo
local GetItemInfoFn = C_Item and C_Item.GetItemInfo
local LinkUtil = _G.LinkUtil

local function EnsureCopyPopup()
	if not StaticPopupDialogs then return end
	if StaticPopupDialogs["EQOL_URL_COPY"] then return end
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
end

local function ShowCopyDialog(text)
	EnsureCopyPopup()
	if StaticPopup_Show then StaticPopup_Show("EQOL_URL_COPY", nil, nil, text or "") end
end

local function BuildURLLinkEvents()
	local events = {}
	if type(ChatTypeGroup) == "table" then
		for _, group in pairs(ChatTypeGroup) do
			if type(group) == "table" then
				for _, event in pairs(group) do
					events[event] = true
				end
			end
		end
	end
	for _, event in ipairs(URL_CHAT_EVENTS_FALLBACK) do
		events[event] = true
	end
	return events
end

local function IsURLToken(token)
	return token:match("^https?://") or token:match("^www%.") or token:match("^[%w%-]+%.[%w%.%-]+/.+")
end

local function FormatURLToken(token)
	if token:find("|H", 1, true) or token:find("|h", 1, true) then return token end
	if not IsURLToken(token) then return token end

	local originalToken = token
	local suffix = ""
	while token:match("[%.,%;:%!%?%)%]%}]$") do
		suffix = token:sub(-1) .. suffix
		token = token:sub(1, -2)
	end
	if token == "" or not IsURLToken(token) then return originalToken end

	return format("|H%s:%s|h[|cffffffff%s|r]|h%s", URL_LINK_TYPE, token, token, suffix)
end

local function FormatURLs(text)
	return text:gsub("%S+", FormatURLToken)
end

local function GetItemTexture(link)
	if not link then return nil end

	local itemID = link:match("item:(%d+)")
	if itemID then return C_Item.GetItemIconByID(tonumber(itemID)) end

	return nil
end

local function AppendIcon(texture, link)
	if not texture then return link end
	return format("|T%s:%d|t%s", texture, ICON_SIZE, link)
end

local function FormatItemLink(link)
	return AppendIcon(GetItemTexture(link), link)
end

local function BuildItemLinkEvents()
	local events = {}
	if type(ChatTypeGroup) == "table" then
		for _, group in pairs(ChatTypeGroup) do
			if type(group) == "table" then
				for _, event in pairs(group) do
					events[event] = true
				end
			end
		end
	end
	for _, event in ipairs(ITEMLINK_EVENTS_FALLBACK) do
		events[event] = true
	end
	return events
end

local function GetItemLevelAndEquipLoc(link)
	local level
	if GetDetailedItemLevelInfoFn then level = GetDetailedItemLevelInfoFn(link) end

	local equipLoc
	if GetItemInfoFn then
		local _, _, _, baseLevel, _, _, _, _, itemEquipLoc = GetItemInfoFn(link)
		equipLoc = itemEquipLoc
		if not level or level == 0 then level = baseLevel end
	end

	if level and level > 0 then return level, equipLoc end
	return nil, equipLoc
end

local function FormatItemLinkWithLevel(link)
	if not ChatIcons.itemLevelEnabled then return link end

	local prefix, label, suffix = link:match("^(|Hitem:[^|]+|h)%[(.-)%](|h|r)$")
	if not prefix or not label or not suffix then return link end

	local level, equipLoc = GetItemLevelAndEquipLoc(link)
	if not level then return link end
	if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP_IGNORE" then return link end

	local parts = {}
	if ChatIcons.itemLevelShowLocation and equipLoc and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" and _G[equipLoc] then
		parts[#parts + 1] = _G[equipLoc]
	end
	parts[#parts + 1] = tostring(level)

	local suffixText = table.concat(parts, " ")
	if suffixText == "" then return link end

	return prefix .. "[" .. label .. " (" .. suffixText .. ")]" .. suffix
end

local function FormatCurrencyLink(link, id)
	id = tonumber(id)
	if not id then return link end
	if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return link end

	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	local texture = info and (info.iconFileID or info.icon)
	return AppendIcon(texture, link)
end

local function IsTooltipRestricted()
	return addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true)
end

local function ShowChatItemTooltip(chatFrame, link)
	if not ChatIcons.itemTooltipOnHoverEnabled then return end
	if type(link) ~= "string" or not link:match("^item:") then return end
	if not GameTooltip or IsTooltipRestricted() then return end
	GameTooltip:SetOwner(chatFrame, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(link)
	GameTooltip.__EnhanceQoLChatItemTooltip = true
	GameTooltip:Show()
end

local function HideChatItemTooltip()
	if GameTooltip and GameTooltip.__EnhanceQoLChatItemTooltip then
		GameTooltip.__EnhanceQoLChatItemTooltip = nil
		GameTooltip:Hide()
	end
end

local function RegisterChatItemTooltipHooks()
	if ChatIcons.itemTooltipHooksInitialized then return end
	ChatIcons.itemTooltipHooksInitialized = true
	for i = 1, _G.NUM_CHAT_WINDOWS or 10 do
		local chatFrame = _G["ChatFrame" .. i]
		if chatFrame and chatFrame.HookScript then
			chatFrame:HookScript("OnHyperlinkEnter", ShowChatItemTooltip)
			chatFrame:HookScript("OnHyperlinkLeave", HideChatItemTooltip)
		end
	end
end

local function FilterChatMessage(_, event, message, ...)
	if issecretvalue and issecretvalue(message) then return end
	if type(message) ~= "string" or message == "" then return false end

	if ChatIcons.urlCopyEnabled then message = FormatURLs(message) end

	local formatItemIcons = ChatIcons.enabled == true
	local formatItemLevel = ChatIcons.itemLevelEnabled
	if formatItemIcons or formatItemLevel then
		message = message:gsub(ITEM_LINK_PATTERN, function(link)
			if formatItemLevel then link = FormatItemLinkWithLevel(link) end
			if formatItemIcons then link = FormatItemLink(link) end
			return link
		end)
	end
	if ChatIcons.enabled and (event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_CURRENCY") then
		message = message:gsub(CURRENCY_LINK_PATTERN, FormatCurrencyLink)
	end

	return false, message, ...
end

ChatIcons.Filter = ChatIcons.Filter or FilterChatMessage
ChatIcons.enabled = ChatIcons.enabled or false
ChatIcons.itemLevelEnabled = ChatIcons.itemLevelEnabled or false
ChatIcons.itemLevelShowLocation = ChatIcons.itemLevelShowLocation or false
ChatIcons.itemTooltipOnHoverEnabled = ChatIcons.itemTooltipOnHoverEnabled or false
ChatIcons.urlCopyEnabled = ChatIcons.urlCopyEnabled or false
ChatIcons.registeredEvents = ChatIcons.registeredEvents or {}

function ChatIcons:RegisterURLCopyHandler()
	if self.urlCopyHandlerRegistered then return end
	self.urlCopyHandlerRegistered = true

	if LinkUtil and LinkUtil.RegisterLinkHandler and (not LinkUtil.IsLinkHandlerRegistered or not LinkUtil.IsLinkHandlerRegistered(URL_LINK_TYPE)) then
		LinkUtil.RegisterLinkHandler(URL_LINK_TYPE, function(link, text, linkData)
			local payload = linkData and linkData.options or link and link:match("^url:(.+)$") or text
			ShowCopyDialog(payload)
		end)
	end
end

function ChatIcons:UpdateFilters()
	local needed = {}
	if self.urlCopyEnabled then
		self.urlLinkEvents = self.urlLinkEvents or BuildURLLinkEvents()
		for event in pairs(self.urlLinkEvents) do
			needed[event] = true
		end
	end
	if self.itemLevelEnabled or self.enabled then
		self.itemLinkEvents = self.itemLinkEvents or BuildItemLinkEvents()
		for event in pairs(self.itemLinkEvents) do
			needed[event] = true
		end
	end
	if self.enabled then
		needed["CHAT_MSG_LOOT"] = true
		needed["CHAT_MSG_CURRENCY"] = true
	end

	for event in pairs(self.registeredEvents) do
		if not needed[event] then
			ChatFrameUtil.RemoveMessageEventFilter(event, self.Filter)
			self.registeredEvents[event] = nil
		end
	end
	for event in pairs(needed) do
		if not self.registeredEvents[event] then
			ChatFrameUtil.AddMessageEventFilter(event, self.Filter)
			self.registeredEvents[event] = true
		end
	end
end

function ChatIcons:SetEnabled(enabled)
	self.enabled = enabled and true or false
	self:UpdateFilters()
end

function ChatIcons:SetItemLevelEnabled(enabled)
	self.itemLevelEnabled = enabled and true or false
	self.itemLevelShowLocation = addon.db and addon.db.chatShowItemLevelLocation or self.itemLevelShowLocation
	self:UpdateFilters()
end

function ChatIcons:SetItemLevelLocation(enabled)
	self.itemLevelShowLocation = enabled and true or false
end

function ChatIcons:SetItemTooltipOnHoverEnabled(enabled)
	self.itemTooltipOnHoverEnabled = enabled and true or false
	RegisterChatItemTooltipHooks()
	if not self.itemTooltipOnHoverEnabled then HideChatItemTooltip() end
end

function ChatIcons:SetURLCopyEnabled(enabled)
	self.urlCopyEnabled = enabled and true or false
	if self.urlCopyEnabled then self:RegisterURLCopyHandler() end
	self:UpdateFilters()
end
