-- luacheck: globals NineSliceUtil
local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local ChatIM = addon.ChatIM
local H = {}

-- Keep metadata alongside the existing string array for saved-history compatibility.
function ChatIM:TrimHistory(lines)
	if #lines > self.maxHistoryLines and addon.ChatHistoryStorage then addon.ChatHistoryStorage.MarkIMDirty() end
	while #lines > self.maxHistoryLines do
		table.remove(lines, 1)
		if lines.timestamps then table.remove(lines.timestamps, 1) end
	end
end

function H.Plain(text)
	return (text:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", ""))
end

function H.Line(key, lines, index)
	local line = lines[index]
	if key:find("#", 1, true) then
		local name = lines.displayName or key
		local ok, formatted = pcall(string.format, line, name, name)
		if ok then line = formatted end
	end
	-- Archived names must not trigger actions using old Battle.net account IDs.
	return (line:gsub("|HBNplayer:.-|h(.-)|h", "%1"):gsub("|Hplayer:.-|h(.-)|h", "%1"))
end

function H.Day(lines, index)
	local timestamp = lines.timestamps and lines.timestamps[index]
	if type(timestamp) == "number" then return date("%Y-%m-%d", timestamp) end
	return L["ChatIMHistoryUnknownDate"]
end

function H.Panel(parent, name)
	local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
	panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	return panel
end

function ChatIM:ApplyHistoryStyle(resetScroll)
	local frame = self.historyFrame
	if not frame then return end
	frame:SetBackdropColor(self:GetStyleColor("chatIMBackgroundColor"))
	frame.title:SetTextColor(self:GetStyleColor("chatIMTitleColor"))
	local r, g, b, a = self:GetStyleColor("chatIMFrameColor")
	for _, key in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do
		local piece = frame.border[key]
		if piece then
			piece:SetDesaturated(true)
			piece:SetVertexColor(r, g, b, a)
		end
	end
	for _, panel in ipairs({ frame.searchBackground, frame.contactsBackground, frame.messagesBackground }) do
		panel:SetBackdropColor(self:GetStyleColor("chatIMInputBackgroundColor"))
		panel:SetBackdropBorderColor(self:GetStyleColor("chatIMInputBorderColor"))
	end
	for _, button in ipairs(frame.contacts) do
		local selected = button.key == frame.selected
		button:SetBackdropColor(self:GetStyleColor(selected and "chatIMActiveTabBackgroundColor" or "chatIMTabBackgroundColor"))
		button:SetBackdropBorderColor(self:GetStyleColor(selected and "chatIMActiveTabBorderColor" or "chatIMTabBorderColor"))
		button.text:SetTextColor(self:GetStyleColor(selected and "chatIMActiveTabTextColor" or "chatIMTabTextColor"))
	end
	if frame:IsShown() then H.RenderMessages(resetScroll) end
end

function H.RenderMessages(resetScroll)
	local frame = ChatIM.historyFrame
	local scroll, content = frame.messagesScroll, frame.messagesContent
	local offset = scroll:GetVerticalScroll()
	local atBottom = offset >= math.max(0, content:GetHeight() - scroll:GetHeight()) - 1
	local width = math.max(100, scroll:GetWidth() - 12)
	content:SetWidth(width)
	for _, row in ipairs(frame.rows) do row:Hide() end
	local count, y, previousDay, firstMatch = 0, 8, nil, nil
	local query = (frame.search:GetText() or ""):lower():match("^%s*(.-)%s*$")
	local function add(text, centered, matched)
		count = count + 1
		local row = frame.rows[count]
		if not row then
			row = content:CreateFontString(nil, "OVERLAY")
			frame.rows[count] = row
		end
		local font, _, flags
		if ChatFontNormal and ChatFontNormal.GetFont then font, _, flags = ChatFontNormal:GetFont() end
		row:SetFont(font or STANDARD_TEXT_FONT, ChatIM:GetFontSize(), flags or "")
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 6, -y)
		row:SetWidth(width - 12)
		row:SetWordWrap(true)
		row:SetNonSpaceWrap(true)
		row:SetJustifyH(centered and "CENTER" or "LEFT")
		row:SetTextColor(ChatIM:GetStyleColor((centered or matched) and "chatIMActiveTabTextColor" or "chatIMTabTextColor"))
		row:SetText(text)
		row:Show()
		y = y + row:GetStringHeight() + (centered and 12 or 6)
	end
	local source = frame.previewHistory or ChatIM.history
	local lines = source and source[frame.selected]
	if lines then
		frame.heading:SetText(lines.displayName and (lines.displayName .. " (" .. frame.selected .. ")") or frame.selected)
		for index in ipairs(lines) do
			local line = H.Line(frame.selected, lines, index)
			local day = H.Day(lines, index)
			if day ~= previousDay then
				if previousDay then y = y + 8 end
				add(day, true)
				previousDay = day
			end
			local matched = query ~= "" and (day .. " " .. H.Plain(line)):lower():find(query, 1, true)
			if matched then
				firstMatch = firstMatch or y
				line = H.Plain(line)
			end
			add(line, false, matched)
		end
	else
		frame.heading:SetText(L["ChatIMHistoryViewer"])
		add(L["ChatIMHistoryEmpty"], true)
	end
	content:SetHeight(math.max(1, y))
	scroll:UpdateScrollChildRect()
	local maximum = math.max(0, y - scroll:GetHeight())
	local target = (resetScroll and (firstMatch or maximum)) or (atBottom and maximum) or offset
	scroll:SetVerticalScroll(math.min(target, maximum))
end

function H.WhisperTarget(key)
	if not key:find("#", 1, true) then return ChatIM:NormalizeCharacterName(key) end
	if not (BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo) then return end
	for index = 1, BNGetNumFriends() do
		local info = C_BattleNet.GetFriendAccountInfo(index)
		if info and info.battleTag == key and info.gameAccountInfo and info.gameAccountInfo.isOnline and info.bnetAccountID then
			return info.accountName or key:match("^[^#]+"), info.bnetAccountID, key
		end
	end
end

function H.StartChat(source, key, preview)
	if preview or not ChatIM.enabled or not source[key] then return end
	local target, bnetID, battleTag = H.WhisperTarget(key)
	if not target then return end
	-- Existing tabs may still carry an account ID from before a reconnect.
	local tab = ChatIM.tabs and ChatIM.tabs[target]
	if tab and bnetID then tab.bnetID, tab.battleTag = bnetID, battleTag end
	if ChatIM:StartWhisper(target, bnetID, battleTag) then
		ChatIM.historyFrame:Hide()
		ChatIM:FocusConversation(target, true)
	end
end

StaticPopupDialogs["EQOL_DELETE_IM_HISTORY_VIEWER"] = {
	text = L["ChatIMHistoryDeleteConfirm"],
	button1 = DELETE,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(_, data)
		data.source[data.key] = nil
		if not data.preview and addon.ChatHistoryStorage then addon.ChatHistoryStorage.MarkIMDirty() end
		if not data.preview then
			for target, tab in pairs(ChatIM.tabs or {}) do
				local historyKey = tab.isBN and tab.battleTag or target
				if historyKey == data.key and tab.msg then tab.msg:Clear() end
			end
		end
		local frame = ChatIM.historyFrame
		if frame and frame.searchCache then frame.searchCache[data.key] = nil end
		ChatIM:RefreshHistoryViewer(true)
	end,
}

function H.ContactMenu(button)
	local frame = ChatIM.historyFrame
	local source, preview = frame.previewHistory or ChatIM.history, frame.previewHistory ~= nil
	local key = button.key
	if not source or not source[key] then return end
	local lines = source[key]
	MenuUtil.CreateContextMenu(button, function(_, root)
		root:CreateTitle(lines.displayName or key)
		local start = root:CreateButton(L["ChatIMHistoryStartChat"], function() H.StartChat(source, key, preview) end)
		start:SetEnabled(not preview and H.WhisperTarget(key) ~= nil)
		root:CreateDivider()
		root:CreateButton(DELETE, function()
			StaticPopup_Show("EQOL_DELETE_IM_HISTORY_VIEWER", lines.displayName or key, nil, { source = source, key = key, preview = preview })
		end)
	end)
end

function ChatIM:RefreshHistoryViewer(resetScroll)
	local frame = self.historyFrame
	if not frame or not frame:IsShown() then return end
	local query = (frame.search:GetText() or ""):lower():match("^%s*(.-)%s*$")
	local entries = {}
	for key, lines in pairs(frame.previewHistory or self.history or {}) do
		if type(key) == "string" and type(lines) == "table" and #lines > 0 then
			frame.searchCache = frame.searchCache or {}
			local cached = frame.searchCache[key]
			if not cached or cached.lines ~= lines or cached.count ~= #lines or cached.last ~= lines[#lines] or cached.name ~= lines.displayName then
				local parts = { key, lines.displayName or "" }
				for index in ipairs(lines) do
					parts[#parts + 1] = H.Day(lines, index) .. " " .. H.Plain(H.Line(key, lines, index))
				end
				cached = { lines = lines, count = #lines, last = lines[#lines], name = lines.displayName, text = table.concat(parts, "\n"):lower() }
				frame.searchCache[key] = cached
			end
			local matches = query == "" or cached.text:find(query, 1, true)
			if matches then
				local timestamps = lines.timestamps
				entries[#entries + 1] = { key = key, name = lines.displayName or key, latest = timestamps and timestamps[#lines] or 0 }
			end
		end
	end
	table.sort(entries, function(a, b)
		if a.latest ~= b.latest then return a.latest > b.latest end
		return a.key < b.key
	end)
	local found
	for _, entry in ipairs(entries) do
		if entry.key == frame.selected then found = true end
	end
	if not found then
		frame.selected = entries[1] and entries[1].key
		resetScroll = true
	end
	for _, button in ipairs(frame.contacts) do button:Hide() end
	for index, entry in ipairs(entries) do
		local button = frame.contacts[index]
		if not button then
			button = CreateFrame("Button", nil, frame.contactsContent, "BackdropTemplate")
			button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			button.text:SetPoint("LEFT", 8, 0)
			button.text:SetPoint("RIGHT", -8, 0)
			button.text:SetJustifyH("LEFT")
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, mouseButton)
				if mouseButton == "RightButton" then
					H.ContactMenu(self)
					return
				end
				frame.selected = self.key
				ChatIM:ApplyHistoryStyle(true)
			end)
			button:SetScript("OnDoubleClick", function(self, mouseButton)
				if mouseButton == "LeftButton" then H.StartChat(frame.previewHistory or ChatIM.history, self.key, frame.previewHistory ~= nil) end
			end)
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.key)
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", GameTooltip_Hide)
			frame.contacts[index] = button
		end
		button.key = entry.key
		button:SetPoint("TOPLEFT", 0, -(index - 1) * 32)
		button:SetSize(174, 30)
		button.text:SetText(entry.name)
		button:Show()
	end
	frame.contactsContent:SetHeight(math.max(1, #entries * 32))
	frame.contactsScroll:UpdateScrollChildRect()
	frame.contactsScroll:SetVerticalScroll(math.min(frame.contactsScroll:GetVerticalScroll(), math.max(0, #entries * 32 - frame.contactsScroll:GetHeight())))
	self:ApplyHistoryStyle(resetScroll)
end

function ChatIM:OpenHistoryViewer(preview)
	if not self.enabled then return end
	if self.historyFrame then
		self.historyFrame.previewHistory = preview and H.Preview() or nil
		self.historyFrame.searchCache = nil
		self.historyFrame.search:SetText("")
		self.historyFrame.title:SetText(L[preview and "ChatIMHistoryPreview" or "ChatIMHistoryViewer"])
		self.historyFrame:Show()
		self.historyFrame:Raise()
		self:RefreshHistoryViewer(true)
		return
	end
	local frame = H.Panel(UIParent, "EnhanceQoLChatIMHistoryFrame")
	self.historyFrame = frame
	frame.previewHistory = preview and H.Preview() or nil
	frame.rows, frame.contacts = {}, {}
	frame:SetSize(820, 560)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if frame.SetResizeBounds then frame:SetResizeBounds(620, 360) end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnHide", function(self)
		self:StopMovingOrSizing()
		self.search:ClearFocus()
		if self.searchTimer then self.searchTimer:Cancel() end
	end)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", insets = { left = 16, right = 2, top = 18, bottom = 7 } })
	local border = CreateFrame("Frame", nil, frame, "NineSlicePanelTemplate")
	border:SetPoint("TOPLEFT", 8, -16)
	border:SetPoint("BOTTOMRIGHT", -2, 5)
	border:SetFrameLevel(frame:GetFrameLevel() + 1)
	NineSliceUtil.ApplyLayoutByName(border, "ButtonFrameTemplateNoPortrait")
	frame.border = border
	local controls = CreateFrame("Frame", nil, frame)
	controls:SetAllPoints()
	controls:SetFrameLevel(frame:GetFrameLevel() + 2)
	local paddedMetalArt = addon.variables and addon.variables.isForever and not addon.variables.isTBC
	local retailMetalArt = not (addon.variables and (addon.variables.isForever or addon.variables.isTBC))
	frame.title = controls:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("CENTER", border.TopEdge, "CENTER", 0, paddedMetalArt and 21 or retailMetalArt and 9 or -3)
	frame.title:SetText(L[preview and "ChatIMHistoryPreview" or "ChatIMHistoryViewer"])
	local close = CreateFrame("Button", nil, controls, "UIPanelCloseButton")
	close:SetPoint("CENTER", border.TopRightCorner, "CENTER", paddedMetalArt and 33 or retailMetalArt and 21 or -1, paddedMetalArt and 23 or retailMetalArt and 9 or -1)
	close:SetScript("OnClick", function() frame:Hide() end)
	local sizer = CreateFrame("Button", nil, controls)
	sizer:SetSize(16, 16)
	sizer:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", retailMetalArt and 1 or -1, -2)
	sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	sizer:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
	end)
	sizer:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
	table.insert(UISpecialFrames, "EnhanceQoLChatIMHistoryFrame")

	frame.searchBackground = H.Panel(controls)
	frame.searchBackground:SetPoint("TOPLEFT", border, "TOPLEFT", 16, -36)
	frame.searchBackground:SetPoint("TOPRIGHT", border, "TOPRIGHT", -16, -36)
	frame.searchBackground:SetHeight(30)
	local search = CreateFrame("EditBox", nil, frame.searchBackground)
	search:SetPoint("TOPLEFT", 8, -4)
	search:SetPoint("BOTTOMRIGHT", -30, 4)
	search:SetFontObject("ChatFontNormal")
	search:SetAutoFocus(false)
	search:SetMaxLetters(160)
	frame.search = search
	local clear = CreateFrame("Button", nil, frame.searchBackground, "UIPanelCloseButton")
	clear:SetSize(24, 24)
	clear:SetPoint("RIGHT", -3, 0)
	clear:Hide()
	clear:SetScript("OnClick", function()
		search:SetText("")
		if frame.searchTimer then
			frame.searchTimer:Cancel()
			frame.searchTimer = nil
		end
		ChatIM:RefreshHistoryViewer(true)
		search:SetFocus()
	end)
	frame.searchClearButton = clear
	local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	hint:SetPoint("LEFT")
	hint:SetText(L["ChatIMHistorySearch"])
	search:SetScript("OnTextChanged", function(self)
		hint:SetShown(self:GetText() == "")
		clear:SetShown(self:GetText() ~= "")
		if frame.searchTimer then frame.searchTimer:Cancel() end
		frame.searchTimer = C_Timer.NewTimer(0.15, function() ChatIM:RefreshHistoryViewer(true) end)
	end)
	search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	search:SetScript("OnEnterPressed", function(self)
		if frame.searchTimer then frame.searchTimer:Cancel() end
		ChatIM:RefreshHistoryViewer(true)
		self:ClearFocus()
	end)

	frame.contactsBackground = H.Panel(controls)
	frame.contactsBackground:SetPoint("TOPLEFT", frame.searchBackground, "BOTTOMLEFT", 0, -10)
	frame.contactsBackground:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 16, 18)
	frame.contactsBackground:SetWidth(210)
	frame.contactsScroll = CreateFrame("ScrollFrame", nil, frame.contactsBackground, "UIPanelScrollFrameTemplate")
	frame.contactsScroll:SetPoint("TOPLEFT", 6, -6)
	frame.contactsScroll:SetPoint("BOTTOMRIGHT", -30, 6)
	if retailMetalArt then
		local bar = frame.contactsScroll.ScrollBar
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", frame.contactsScroll, "TOPRIGHT", 8, -16)
		bar:SetPoint("BOTTOMLEFT", frame.contactsScroll, "BOTTOMRIGHT", 8, 16)
	end
	frame.contactsContent = CreateFrame("Frame", nil, frame.contactsScroll)
	frame.contactsContent:SetSize(174, 1)
	frame.contactsScroll:SetScrollChild(frame.contactsContent)

	frame.messagesBackground = H.Panel(controls)
	frame.messagesBackground:SetPoint("TOPLEFT", frame.contactsBackground, "TOPRIGHT", 10, 0)
	frame.messagesBackground:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -16, 18)
	frame.heading = frame.messagesBackground:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.heading:SetPoint("TOPLEFT", 10, -10)
	frame.heading:SetPoint("TOPRIGHT", -10, -10)
	frame.heading:SetJustifyH("LEFT")
	frame.messagesScroll = CreateFrame("ScrollFrame", nil, frame.messagesBackground, "UIPanelScrollFrameTemplate")
	frame.messagesScroll:SetPoint("TOPLEFT", 4, -32)
	frame.messagesScroll:SetPoint("BOTTOMRIGHT", -30, 6)
	if retailMetalArt then
		local bar = frame.messagesScroll.ScrollBar
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", frame.messagesScroll, "TOPRIGHT", 8, -16)
		bar:SetPoint("BOTTOMLEFT", frame.messagesScroll, "BOTTOMRIGHT", 8, 16)
	end
	frame.messagesContent = CreateFrame("Frame", nil, frame.messagesScroll)
	frame.messagesContent:SetSize(500, 1)
	frame.messagesScroll:SetScrollChild(frame.messagesContent)
	frame.messagesScroll:SetScript("OnSizeChanged", function() H.RenderMessages(false) end)
	self:RefreshHistoryViewer(true)
end

-- Synthetic test conversations remain in memory and never enter SavedVariables.
function H.Preview()
	local history = {}
	local samples = {
		"Treffpunkt ist morgen um 20:30 am Eingang. Bring bitte Tränke, Essen und genug Platz in den Taschen mit. Ich frage noch zwei Leute aus der Gilde, ob sie mitkommen möchten.",
		"Alles klar! Ich habe die Materialien für die Verzauberung schon auf der Bank. Welche davon fehlen dir noch? Schick mir einfach die genaue Liste, dann bringe ich alles mit.",
		"Raidplanung: Wir sollten die Gruppen vor dem Start einteilen. Beim letzten Versuch haben wir sehr viel Zeit damit verbracht, Aufgaben zu verteilen. Für den nächsten Abend würde ich gern Tanks, Heilung und Unterbrechungen vorher festlegen. Danach können wir gemeinsam schauen, an welcher Stelle wir noch etwas ändern müssen. Was hältst du davon?",
		"Suche noch jemanden für eine entspannte Dungeonrunde. Kein Zeitdruck, wir können auch die Quests unterwegs erledigen. Ich bin in ungefähr zehn Minuten bereit.",
		"Danke, das hat super funktioniert. Den Rest besprechen wir morgen. Gute Nacht!",
		"Hier ist meine längere Zusammenfassung: Zuerst erledigen wir die offenen Quests im Norden und treffen uns anschließend wieder in der Stadt. Falls jemand später dazukommt, holen wir ihn am Flugpunkt ab. Ich würde gern zwischendurch eine Pause machen, weil ich noch etwas vorbereiten muss. Die gesammelten Gegenstände teilen wir am Ende auf. Bei den seltenen Materialien sollten wir vorher besprechen, wer sie gerade benötigt. Bitte denk auch an die Ersatzwaffe, die wir gestern erwähnt haben. Danach können wir entscheiden, ob wir noch einen Dungeon machen oder den Abend gemütlich ausklingen lassen.",
		"Preis für die Materialien: 125 Gold. Alternativ können wir tauschen; ich brauche noch Kräuter und Stoff. Die Verzauberung selbst kostet nichts extra.",
		"Kurze Rückfrage zum Termin: Samstag oder Sonntag? 19:00 wäre für mich an beiden Tagen möglich. Sag bitte Bescheid, sobald die anderen geantwortet haben.",
		"Ja, passt. :)",
		"Die Notizen sind jetzt vollständig. Suchbegriffe für später: Raidplanung, Verzauberung, Dungeon, Materialien. Damit sollten wir die richtige Unterhaltung auch zwischen vielen anderen Kontakten wiederfinden.",
	}
	local names = { "Eira Moonfall", "Tharion", "Mira Dawnwhisper", "Ash", "Valeria Longshadow", "Borin", "Alessandra Silverbrook", "Finn", "Liora", "Theron Stormwatcher" }
	local now = time()
	for contact = 1, 100 do
		local key = string.format("Preview %03d · %s", contact, names[(contact - 1) % #names + 1])
		local lines = { timestamps = {} }
		history[key] = lines
		for index = 1, 10 do
			local timestamp = now - (4 - math.floor((index - 1) / 3)) * 86400 + index * 180 + contact
			local outbound = index % 2 == 0
			local color = addon.db and addon.db[outbound and "chatIMOutgoingMessageColor" or "chatIMIncomingMessageColor"]
			if type(color) ~= "table" then color = outbound and ChatTypeInfo.WHISPER_INFORM or ChatTypeInfo.WHISPER end
			local hex = string.format("%02x%02x%02x", math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
			local text = samples[(contact - 1) % #samples + 1]
			if index % 3 == 0 then text = samples[5] end
			if index == 10 then text = samples[9] end
			if contact % 10 == 0 and index == 2 then text = string.rep(samples[6] .. " ", 5) end
			lines[index] = "|cff999999" .. date("%H:%M", timestamp) .. "|r |cff" .. hex .. (outbound and AUCTION_HOUSE_SELLER_YOU or key) .. ": " .. text .. "|r"
			lines.timestamps[index] = timestamp
		end
	end
	return history
end

function ChatIM:QueueHistoryRefresh(key)
	if key and self.historyFrame and self.historyFrame.searchCache then self.historyFrame.searchCache[key] = nil end
	local frame = self.historyFrame
	if not frame or not frame:IsShown() or frame.previewHistory or frame.refreshTimer then return end
	frame.refreshTimer = C_Timer.NewTimer(0.15, function()
		frame.refreshTimer = nil
		self:RefreshHistoryViewer()
	end)
end
