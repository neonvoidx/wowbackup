-- luacheck: globals EnhanceQoL C_FriendList
local addonName, addon = ...

local L = addon.L

local AceGUI = addon.AceGUI
local db
local stream
-- Forward declarations used across functions
local listWindow -- AceGUI window
local populateListWindow -- function to (re)build the list window
local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.friends = addon.db.datapanel.friends or {}
	db = addon.db.datapanel.friends
	db.fontSize = db.fontSize or 13
	if db.splitDisplay == nil then db.splitDisplay = false end
	if db.splitDisplayInline == nil then db.splitDisplayInline = false end
end

local function RestorePosition(frame)
	if db.point and db.x and db.y then
		frame:ClearAllPoints()
		frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
	end
end

local aceWindow
local function createAceWindow()
	if aceWindow then
		aceWindow:Show()
		return
	end
	ensureDB()
	local frame = AceGUI:Create("Window")
	aceWindow = frame.frame
	frame:SetTitle((addon.DataPanel and addon.DataPanel.GetStreamOptionsTitle and addon.DataPanel.GetStreamOptionsTitle(stream and stream.meta and stream.meta.title)) or GAMEMENU_OPTIONS)
	frame:SetWidth(300)
	frame:SetHeight(200)
	frame:SetLayout("List")

	frame.frame:SetScript("OnShow", function(self) RestorePosition(self) end)
	frame.frame:SetScript("OnHide", function(self)
		local point, _, _, xOfs, yOfs = self:GetPoint()
		db.point = point
		db.x = xOfs
		db.y = yOfs
	end)

	local fontSize = AceGUI:Create("Slider")
	fontSize:SetLabel(FONT_SIZE)
	fontSize:SetSliderValues(8, 32, 1)
	fontSize:SetValue(db.fontSize)
	fontSize:SetCallback("OnValueChanged", function(_, _, val)
		db.fontSize = val
		addon.DataHub:RequestUpdate(stream)
	end)
	frame:AddChild(fontSize)

	local splitDisplayInline
	local splitDisplay = AceGUI:Create("CheckBox")
	splitDisplay:SetLabel(L["Friends/Guild display"] or "Show friends + guild")
	splitDisplay:SetValue(db.splitDisplay == true)
	splitDisplay:SetCallback("OnValueChanged", function(_, _, val)
		db.splitDisplay = val and true or false
		if splitDisplayInline and splitDisplayInline.SetDisabled then splitDisplayInline:SetDisabled(not db.splitDisplay) end
		addon.DataHub:RequestUpdate(stream)
	end)
	frame:AddChild(splitDisplay)

	splitDisplayInline = AceGUI:Create("CheckBox")
	splitDisplayInline:SetLabel(L["Friends/Guild display single line"] or "Single-line layout")
	splitDisplayInline:SetValue(db.splitDisplayInline == true)
	splitDisplayInline:SetDisabled(not db.splitDisplay)
	splitDisplayInline:SetCallback("OnValueChanged", function(_, _, val)
		db.splitDisplayInline = val and true or false
		addon.DataHub:RequestUpdate(stream)
	end)
	frame:AddChild(splitDisplayInline)

	frame.frame:Show()
end

local GetNumFriends = C_FriendList.GetNumFriends
local GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local C_GuildInfo = _G.C_GuildInfo
local C_Club = _G.C_Club

local myGuid = UnitGUID("player")
local issecretvalue = _G.issecretvalue
local issecrettable = _G.issecrettable

local function isSecret(value)
	if issecretvalue and issecretvalue(value) then return true end
	if issecrettable and issecrettable(value) then return true end
	return false
end

local function sanitizeValue(value)
	if isSecret(value) then return nil end
	return value
end

local function sanitizeString(value)
	value = sanitizeValue(value)
	if type(value) ~= "string" or value == "" then return nil end
	return value
end

local function sanitizeNumber(value)
	value = sanitizeValue(value)
	if type(value) ~= "number" then return nil end
	return value
end

local function isFriendsDataRestricted()
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return true end
	return addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true) == true or false
end

-- Build reverse lookup for class tokens from localized names for coloring
local CLASS_TOKEN_BY_LOCALIZED = {}
if LOCALIZED_CLASS_NAMES_MALE then
	for token, loc in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		CLASS_TOKEN_BY_LOCALIZED[loc] = token
	end
end
if LOCALIZED_CLASS_NAMES_FEMALE then
	for token, loc in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
		CLASS_TOKEN_BY_LOCALIZED[loc] = token
	end
end

local function normalizeRealmName(realm)
	realm = sanitizeString(realm)
	if not realm then return "" end
	-- remove spaces and apostrophes for stable keys, lowercase
	realm = realm:gsub("%s+", ""):gsub("'", "")
	return realm:lower()
end

local function normalizeCompareText(text)
	text = sanitizeString(text)
	if not text then return nil end
	text = text:gsub("[%s%-']", ""):lower()
	if text == "" then return nil end
	return text
end

local myRealm = GetRealmName and GetRealmName() or nil
local myRealmKey = normalizeRealmName(myRealm)
local myRealmCompareKey = normalizeCompareText(myRealm)

local function splitNameRealm(name)
	name = sanitizeString(name)
	if not name then return nil, nil end
	-- Names coming from various APIs can sometimes end up with the realm
	-- appended multiple times (e.g., "Name-Antonidas-Antonidas-...").
	-- We always want:
	--   base  = the character name (before the first hyphen)
	--   realm = the final segment (after the last hyphen), if present
	local base, remainder = name:match("^([^%-]+)%-(.+)$")
	if base then
		-- Take only the last segment of the remainder as the realm
		local realm = remainder:match("([^%-]+)$")
		return base, realm
	end
	return name, nil
end

local function makeKey(name, realm)
	name = sanitizeString(name)
	realm = sanitizeValue(realm)
	local base, r = splitNameRealm(name)
	base = base or name or ""
	r = r or realm or myRealm
	return (base:lower() .. "-" .. normalizeRealmName(r or ""))
end

local myPlayerName, myPlayerRealm
if UnitFullName then
	myPlayerName, myPlayerRealm = UnitFullName("player")
end
local myPlayerKey = makeKey(myPlayerName, myPlayerRealm or myRealm)

local function isOwnGuildEntry(name, realm, guid)
	guid = sanitizeString(guid)
	if guid and myGuid and guid == myGuid then return true end
	local key = makeKey(name, realm)
	if key == "-" or myPlayerKey == "-" then return false end
	return key == myPlayerKey
end

local function displayName(name, realm)
	name = sanitizeString(name)
	realm = sanitizeValue(realm)
	local base, r = splitNameRealm(name)
	base = base or name or ""
	r = r or realm
	local rKey = normalizeRealmName(r or "")
	if rKey == "" or rKey == myRealmKey then return base end
	-- Show cross-realm without spaces in realm to match WoW name formatting
	local realmDisplay = (r or ""):gsub("%s+", "")
	return base .. "-" .. realmDisplay
end

local function classDisplayAndColor(classTokenOrLocalized)
	classTokenOrLocalized = sanitizeString(classTokenOrLocalized)
	if not classTokenOrLocalized then return nil, nil end
	local token = classTokenOrLocalized
	if token:upper() == token then
		-- Looks like a class file token (e.g., "MAGE")
	else
		-- Probably localized name; try reverse-lookup
		token = CLASS_TOKEN_BY_LOCALIZED[classTokenOrLocalized] or token
	end
	local nameLocalized = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]) or classTokenOrLocalized
	local colorTbl = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)
	local color = colorTbl and colorTbl[token]
	return nameLocalized, color
end

local function classDisplayAndColorFromClassID(classID)
	classID = sanitizeNumber(classID)
	if not classID or not (C_CreatureInfo and C_CreatureInfo.GetClassInfo) then return nil, nil end
	local classInfo = C_CreatureInfo.GetClassInfo(classID)
	local classFile = classInfo and sanitizeString(classInfo.classFile)
	if not classFile then return nil, nil end
	return classDisplayAndColor(classFile)
end

local function cleanRealmName(realm)
	realm = sanitizeString(realm)
	if not realm then return nil end
	local cleaned = realm:gsub("%(%*%)", "")
	cleaned = cleaned:gsub("%*$", "")
	cleaned = cleaned:gsub("^%s+", "")
	cleaned = cleaned:gsub("%s+$", "")
	if cleaned == "" then return nil end
	return cleaned
end

local function getRealmDisplayText(realm)
	local cleaned = cleanRealmName(realm)
	if not cleaned then return nil end
	local realmKey = normalizeCompareText(cleaned)
	if realmKey and myRealmCompareKey and realmKey == myRealmCompareKey then return nil end
	return cleaned
end

local function buildLocationText(areaText, realmText)
	local area = sanitizeString(areaText)
	local realm = getRealmDisplayText(realmText)
	if area and realm then return ("%s - %s"):format(area, realm) end
	return area or realm or nil
end

local function isSameZone(areaText)
	local areaKey = normalizeCompareText(areaText)
	if not areaKey then return false end

	local zoneKey = normalizeCompareText(GetZoneText and GetZoneText() or nil)
	local realZoneKey = normalizeCompareText(GetRealZoneText and GetRealZoneText() or nil)
	local subZoneKey = normalizeCompareText(GetSubZoneText and GetSubZoneText() or nil)

	return areaKey == zoneKey or areaKey == realZoneKey or areaKey == subZoneKey
end

-- Structured tooltip data: sections with lists
local tooltipData = { bnet = {}, friends = {}, guild = {} }
local tooltipMeta = {
	guildMotd = nil,
	guildName = nil,
	guildOnlineCount = 0,
	guildTotalCount = 0,
}

local function wipeTooltipSections()
	wipe(tooltipData.bnet)
	wipe(tooltipData.friends)
	wipe(tooltipData.guild)
	tooltipMeta.guildMotd = nil
	tooltipMeta.guildName = nil
	tooltipMeta.guildOnlineCount = 0
	tooltipMeta.guildTotalCount = 0
end

local function resolveGuildName()
	local guildName = sanitizeString(GetGuildInfo and GetGuildInfo("player"))
	if guildName then return guildName end
	return nil
end

local function resolveGuildMotd()
	if not (C_GuildInfo and C_GuildInfo.GetMOTD) then return nil end
	local ok, motd = pcall(C_GuildInfo.GetMOTD)
	motd = ok and sanitizeString(motd) or nil
	if motd then return motd end
	return nil
end

local function requestGuildRosterIfNeeded(memberCount)
	if not (IsInGuild and IsInGuild()) then return end
	if memberCount and memberCount > 0 then return end
	if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
end

local function guildRosterStatusToStatus(status)
	status = sanitizeValue(status)
	if status == 1 or status == "AFK" then return "AFK" end
	if status == 2 or status == "DND" then return "DND" end
	return nil
end

local CLUB_PRESENCE = Enum and Enum.ClubMemberPresence or nil
local CLUB_PRESENCE_OFFLINE = CLUB_PRESENCE and CLUB_PRESENCE.Offline or 3
local CLUB_PRESENCE_AWAY = CLUB_PRESENCE and CLUB_PRESENCE.Away or 4
local CLUB_PRESENCE_BUSY = CLUB_PRESENCE and CLUB_PRESENCE.Busy or 5

local function clubPresenceToStatus(presence)
	presence = sanitizeNumber(presence)
	if not presence then return nil end
	if presence == CLUB_PRESENCE_BUSY then return "DND" end
	if presence == CLUB_PRESENCE_AWAY then return "AFK" end
	return nil
end

local function addGuildEntriesFromClub(seen)
	if isFriendsDataRestricted() then return end
	if not (C_Club and C_Club.GetGuildClubId and C_Club.GetClubMembers and C_Club.GetMemberInfo) then return end

	local clubId = sanitizeNumber(C_Club.GetGuildClubId())
	if not clubId then return end

	local memberIds = C_Club.GetClubMembers(clubId)
	if isSecret(memberIds) or type(memberIds) ~= "table" then return end

	for _, memberId in ipairs(memberIds) do
		memberId = sanitizeNumber(memberId)
		if memberId then
			local memberInfo = C_Club.GetMemberInfo(clubId, memberId)
			if not isSecret(memberInfo) and type(memberInfo) == "table" then
				local name = sanitizeString(memberInfo.name)
				local presence = sanitizeNumber(memberInfo.presence)
				local zone = sanitizeString(memberInfo.zone)
				local isSelf = memberInfo.isSelf == true or isOwnGuildEntry(name, nil, memberInfo.guid)
				if not isSelf and name and presence and presence ~= CLUB_PRESENCE_OFFLINE then
					local key = makeKey(name)
					if not seen[key] then
						seen[key] = true
						local classDisp, color = classDisplayAndColorFromClassID(memberInfo.classID)
						table.insert(tooltipData.guild, {
							name = displayName(name),
							level = sanitizeNumber(memberInfo.level),
							class = classDisp,
							color = color,
							status = clubPresenceToStatus(presence),
							location = zone,
							locationSameZone = zone and isSameZone(zone) or false,
						})
					end
				end
			end
		end
	end
end

local function addGuildEntriesFromRoster(seen)
	local memberCount = sanitizeNumber(GetNumGuildMembers and GetNumGuildMembers() or 0) or 0
	tooltipMeta.guildTotalCount = memberCount or 0
	requestGuildRosterIfNeeded(memberCount)
	if not memberCount or memberCount <= 0 then return end

	for i = 1, memberCount do
		local name, _, _, level, _, zone, _, _, isOnline, status, classToken, _, _, _, _, _, guid = GetGuildRosterInfo(i)
		local isSelf = isOwnGuildEntry(name, nil, guid)
		local online = sanitizeValue(isOnline) == true
		if online and not isSelf then tooltipMeta.guildOnlineCount = tooltipMeta.guildOnlineCount + 1 end
		name = sanitizeString(name)
		zone = sanitizeString(zone)
		level = sanitizeNumber(level)
		if online and not isSelf and name then
			local key = makeKey(name)
			if not seen[key] then
				seen[key] = true
				local classDisp, color = classDisplayAndColor(classToken)
				table.insert(tooltipData.guild, {
					name = displayName(name),
					level = level,
					class = classDisp,
					color = color,
					status = guildRosterStatusToStatus(status),
					location = zone,
					locationSameZone = isSameZone(zone),
				})
			end
		end
	end
end

local function getFriends(stream)
	ensureDB()
	wipeTooltipSections()

	stream.snapshot.fontSize = db and db.fontSize or 13
	if isFriendsDataRestricted() then
		stream.snapshot.text = FRIENDS
		if listWindow and listWindow.frame and listWindow.frame:IsShown() then populateListWindow() end
		return
	end

	local seen = {} -- key -> true (dedupe across sources)
	local totalUnique = 0
	local friendsCount = 0

	tooltipMeta.guildName = resolveGuildName()
	tooltipMeta.guildMotd = resolveGuildMotd()

	-- 1) Battle.net friends (prefer these when deduping)
	local numBNetTotal, _ = BNGetNumFriends()
	if numBNetTotal and numBNetTotal > 0 then
		for i = 1, numBNetTotal do
			local info = C_BattleNet.GetFriendAccountInfo(i)
			local ga = info and info.gameAccountInfo
			local gameOnline = ga and sanitizeValue(ga.isOnline) == true or false
			local clientProgram = ga and sanitizeString(ga.clientProgram) or nil
			local characterName = ga and sanitizeString(ga.characterName) or nil
			local characterLevel = ga and sanitizeNumber(ga.characterLevel) or nil
			if ga and gameOnline and clientProgram == BNET_CLIENT_WOW and characterName and characterLevel then
				local key = makeKey(characterName, ga.realmName)
				if not seen[key] then
					seen[key] = true
					totalUnique = totalUnique + 1
					local classNameLocalized = ga.className
					local classDisp, color = classDisplayAndColor(classNameLocalized)
					-- BNet presence / status details
					local bnName = sanitizeString(info and (info.accountName or (info.battleTag and info.battleTag:match("^[^#]+"))) or nil)
					-- Prefer game-specific AFK/DND, fall back to account level
					local isAFK = (ga.isGameAFK == true) or (info and info.isAFK == true)
					local isDND = (ga.isGameBusy == true) or (info and info.isDND == true)
					local status
					if isDND then
						status = "DND"
					elseif isAFK then
						status = "AFK"
					end
					local location = buildLocationText(ga.areaName, ga.realmDisplayName or ga.realmName)
					table.insert(tooltipData.bnet, {
						name = displayName(characterName, ga.realmName),
						level = characterLevel,
						class = classDisp,
						color = color,
						bnName = bnName,
						status = status,
						client = clientProgram,
						location = location or sanitizeString(ga.richPresence) or sanitizeString(ga.gameText),
						locationSameZone = ga.areaName and isSameZone(ga.areaName) or false,
						note = sanitizeString(info and info.note or nil),
					})
				end
			end
		end
	end

	-- 2) Regular WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends()
	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		local friendName = friendInfo and sanitizeString(friendInfo.name) or nil
		local friendConnected = friendInfo and sanitizeValue(friendInfo.connected) == true or false
		if friendInfo and friendConnected and friendName then
			local key = makeKey(friendName)
			if not seen[key] then
				seen[key] = true
				totalUnique = totalUnique + 1
				local classDisp, color = classDisplayAndColor(friendInfo.className or friendInfo.classNameFile or "")
				local nameForDisp = displayName(friendName)
				table.insert(tooltipData.friends, {
					name = nameForDisp,
					level = sanitizeNumber(friendInfo.level),
					class = classDisp,
					color = color,
					status = (friendInfo.dnd == true and "DND") or (friendInfo.afk == true and "AFK") or nil,
					location = sanitizeString(friendInfo.area),
					locationSameZone = isSameZone(friendInfo.area),
					note = sanitizeString(friendInfo.notes),
				})
			end
		end
	end
	friendsCount = #tooltipData.bnet + #tooltipData.friends

	-- 3) Guild members
	addGuildEntriesFromClub(seen)
	addGuildEntriesFromRoster(seen)

	-- Sort each section by name
	local function byName(a, b)
		local left = sanitizeString(a and a.name) or ""
		local right = sanitizeString(b and b.name) or ""
		return left:lower() < right:lower()
	end
	table.sort(tooltipData.bnet, byName)
	table.sort(tooltipData.friends, byName)
	table.sort(tooltipData.guild, byName)

	totalUnique = friendsCount + #tooltipData.guild

	if db and db.splitDisplay then
		local guildText
		if tooltipMeta.guildTotalCount and tooltipMeta.guildTotalCount > 0 then
			guildText = string.format("%s: %d/%d", GUILD, tooltipMeta.guildOnlineCount, tooltipMeta.guildTotalCount)
		else
			guildText = string.format("%s: %d", GUILD, tooltipMeta.guildOnlineCount)
		end
		if db.splitDisplayInline then
			stream.snapshot.text = string.format("%s  %s: %d", guildText, FRIENDS, friendsCount)
		else
			stream.snapshot.text = string.format("%s\n%s: %d", guildText, FRIENDS, friendsCount)
		end
	else
		stream.snapshot.text = totalUnique .. " " .. FRIENDS
	end

	-- If our extended window is open, refresh its content
	if listWindow and listWindow.frame and listWindow.frame:IsShown() then populateListWindow() end
end

local function ensureListWindow()
	if listWindow and listWindow.frame and listWindow.frame:IsShown() then return listWindow end
	local frame = AceGUI:Create("Window")
	listWindow = frame
	frame:SetTitle(FRIENDS)
	frame:SetWidth(720)
	frame:SetHeight(520)
	frame:SetLayout("Fill")

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	frame:AddChild(scroll)

	frame._scroll = scroll
	return frame
end

local function colorizeText(text, r, g, b)
	text = sanitizeString(text)
	if not text then return nil end
	return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

local function colorizedName(name, color)
	name = sanitizeString(name)
	if not name then return nil end
	if not color then return name end
	return colorizeText(name, color.r or 1, color.g or 1, color.b or 1)
end

local function colorizedLocation(location, sameZone)
	location = sanitizeString(location)
	if not location then return nil end
	if sameZone then return colorizeText(location, 0.25, 1.0, 0.4) end
	return colorizeText(location, 0.62, 0.62, 0.62)
end

local function formatEntryName(entry)
	local nameText = colorizedName(entry.name, entry.color) or (sanitizeString(entry.name) or "")
	local bnName = sanitizeString(entry.bnName)
	if bnName then nameText = nameText .. " |cff80bfff(" .. bnName .. ")|r" end
	local status = sanitizeString(entry.status)
	if status == "DND" then
		nameText = nameText .. " |cffff5050[DND]|r"
	elseif status == "AFK" then
		nameText = nameText .. " |cffffb84d[AFK]|r"
	end
	return nameText
end

local function buildClassLevelText(entry)
	if entry.class and entry.level then return string.format("%s (%s)", entry.class, tostring(entry.level)) end
	if entry.class then return entry.class end
	if entry.level then return tostring(entry.level) end
	local note = sanitizeString(entry.note)
	if note then return note end
	return ""
end

local function getEntryRightText(entry)
	local rightText = sanitizeString(entry.location) or ""
	if rightText == "" then rightText = buildClassLevelText(entry) end
	return colorizedLocation(rightText, rightText ~= "" and entry.locationSameZone == true)
end

local function getTooltipEntryRight(entry)
	local rightText = sanitizeString(entry.location) or ""
	if rightText == "" then return buildClassLevelText(entry), false end
	return rightText, entry.locationSameZone == true
end

local function getTooltipRightColor(entry, sameZone)
	if not sanitizeString(entry.location) then return HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b end
	if sameZone then return 0.25, 1.0, 0.4 end
	return 0.62, 0.62, 0.62
end

local function addHeader(scroll, title)
	local header = AceGUI:Create("Label")
	header:SetFullWidth(true)
	header:SetText("|cffffd100" .. title .. "|r")
	header:SetFont(addon.variables and addon.variables.defaultFont or GameFontNormal:GetFont(), 14, "OUTLINE")
	scroll:AddChild(header)
end

local function addTwoColumnRow(scroll, leftText, rightText, leftWidth, rightWidth)
	local row = AceGUI:Create("SimpleGroup")
	row:SetFullWidth(true)
	row:SetLayout("Flow")
	local left = AceGUI:Create("Label")
	left:SetRelativeWidth(leftWidth or 0.58)
	left:SetText(leftText or "")
	row:AddChild(left)

	local right = AceGUI:Create("Label")
	right:SetRelativeWidth(rightWidth or 0.42)
	right:SetText(rightText or "")
	row:AddChild(right)

	scroll:AddChild(row)
end

local function addColumnHeader(scroll)
	local rightHeader = _G.ZONE or _G.PRESENCE or L["Presence"] or "Presence"
	addTwoColumnRow(scroll, "|cffcccccc" .. NAME .. "|r", "|cffcccccc" .. rightHeader .. "|r")
end

local function addSectionRows(scroll, title, items)
	if #items == 0 then return end
	addHeader(scroll, string.format("%s (%d)", title, #items))
	addColumnHeader(scroll)
	for _, entry in ipairs(items) do
		addTwoColumnRow(scroll, formatEntryName(entry), getEntryRightText(entry))
	end
end

local function addSpacer(scroll)
	local spacer = AceGUI:Create("Label")
	spacer:SetFullWidth(true)
	spacer:SetText(" ")
	scroll:AddChild(spacer)
end

function populateListWindow()
	if not (listWindow and listWindow._scroll) then return end
	local scroll = listWindow._scroll
	scroll:ReleaseChildren()

	if tooltipMeta.guildName or tooltipMeta.guildTotalCount > 0 or tooltipMeta.guildMotd or #tooltipData.guild > 0 then
		addHeader(scroll, tooltipMeta.guildName or GUILD)
		if tooltipMeta.guildTotalCount and tooltipMeta.guildTotalCount > 0 then
			addTwoColumnRow(scroll, "|cffcccccc" .. GUILD .. "|r", string.format("%d/%d", tooltipMeta.guildOnlineCount, tooltipMeta.guildTotalCount), 0.24, 0.76)
		elseif tooltipMeta.guildOnlineCount and tooltipMeta.guildOnlineCount > 0 then
			addTwoColumnRow(scroll, "|cffcccccc" .. GUILD .. "|r", tostring(tooltipMeta.guildOnlineCount), 0.24, 0.76)
		end
		if tooltipMeta.guildMotd and tooltipMeta.guildMotd ~= "" then addTwoColumnRow(scroll, "|cffccccccMOTD|r", tooltipMeta.guildMotd, 0.24, 0.76) end
		if #tooltipData.guild > 0 then
			addSpacer(scroll)
			addColumnHeader(scroll)
			for _, entry in ipairs(tooltipData.guild) do
				addTwoColumnRow(scroll, formatEntryName(entry), getEntryRightText(entry))
			end
		end
	end

	if (tooltipMeta.guildName or tooltipMeta.guildTotalCount > 0 or tooltipMeta.guildMotd or #tooltipData.guild > 0) and (#tooltipData.friends > 0 or #tooltipData.bnet > 0) then addSpacer(scroll) end

	addSectionRows(scroll, FRIENDS, tooltipData.friends)
	if #tooltipData.friends > 0 and #tooltipData.bnet > 0 then addSpacer(scroll) end
	addSectionRows(scroll, BATTLENET_OPTIONS_LABEL or "Battle.net", tooltipData.bnet)
end

local function toggleListWindow()
	local frame = ensureListWindow()
	if frame.frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
		populateListWindow()
	end
end

local provider = {
	id = "friends",
	version = 1,
	title = FRIENDS,
	update = getFriends,
	events = {
		PLAYER_LOGIN = function(stream)
			requestGuildRosterIfNeeded(GetNumGuildMembers and GetNumGuildMembers() or 0)
			addon.DataHub:RequestUpdate(stream)
		end,
		BN_FRIEND_ACCOUNT_ONLINE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		BN_FRIEND_ACCOUNT_OFFLINE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		BN_FRIEND_INFO_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		FRIENDLIST_UPDATE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		GUILD_MOTD = function(stream) addon.DataHub:RequestUpdate(stream) end,
		GUILD_ROSTER_UPDATE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_REGEN_DISABLED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_REGEN_ENABLED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_GUILD_UPDATE = function(stream)
			requestGuildRosterIfNeeded(GetNumGuildMembers and GetNumGuildMembers() or 0)
			addon.DataHub:RequestUpdate(stream)
		end,
		CLUB_MEMBER_ADDED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		CLUB_MEMBER_PRESENCE_UPDATED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		CLUB_MEMBER_REMOVED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		CLUB_MEMBER_UPDATED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ZONE_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ZONE_CHANGED_INDOORS = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ZONE_CHANGED_NEW_AREA = function(stream) addon.DataHub:RequestUpdate(stream) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then
			createAceWindow()
		else
			toggleListWindow()
		end
	end,
	OnMouseEnter = function(btn)
		local tip = GameTooltip
		tip:ClearLines()
		if addon.DataPanel and addon.DataPanel.SetTooltipOwner then
			addon.DataPanel.SetTooltipOwner(btn, tip)
		else
			tip:SetOwner(btn, "ANCHOR_TOPLEFT")
		end

		local function addSection(title, items, color)
			if #items == 0 then return end
			color = color or HIGHLIGHT_FONT_COLOR
			tip:AddLine(string.format("%s (%d)", title, #items), color.r, color.g, color.b)
			for _, entry in ipairs(items) do
				local left = formatEntryName(entry)
				local right, sameZone = getTooltipEntryRight(entry)
				if right and right ~= "" then
					local rr, rg, rb = getTooltipRightColor(entry, sameZone)
					tip:AddDoubleLine(left, right, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, rr, rg, rb)
				else
					tip:AddLine(left)
				end
			end
			tip:AddLine(" ")
		end

		if tooltipMeta.guildName or tooltipMeta.guildTotalCount > 0 or tooltipMeta.guildMotd then
			local guildCountText
			if tooltipMeta.guildTotalCount and tooltipMeta.guildTotalCount > 0 then
				guildCountText = string.format("%s: %d/%d", GUILD, tooltipMeta.guildOnlineCount, tooltipMeta.guildTotalCount)
			else
				guildCountText = string.format("%s: %d", GUILD, tooltipMeta.guildOnlineCount)
			end
			tip:AddDoubleLine(tooltipMeta.guildName or GUILD, guildCountText, 0.25, 1.0, 0.4, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			if tooltipMeta.guildMotd and tooltipMeta.guildMotd ~= "" then tip:AddLine("MOTD - " .. tooltipMeta.guildMotd, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true) end
			if #tooltipData.guild > 0 then tip:AddLine(" ") end
		end

		addSection(GUILD, tooltipData.guild, CreateColor(0.25, 1.0, 0.4))
		addSection(FRIENDS, tooltipData.friends, CreateColor(0.8, 0.8, 1.0))
		addSection(BATTLENET_OPTIONS_LABEL or "Battle.net", tooltipData.bnet, CreateColor(0.3, 0.7, 1.0))

		local hint = getOptionsHint()
		if hint then tip:AddLine(hint) end
		tip:Show()

		-- Keep first line styling consistent
		local name = tip:GetName()
		local left1 = _G[name .. "TextLeft1"]
		local right1 = _G[name .. "TextRight1"]
		local r, g, b = NORMAL_FONT_COLOR:GetRGB()
		if left1 then
			left1:SetFontObject(GameTooltipText)
			left1:SetTextColor(r, g, b)
		end
		if right1 then
			right1:SetFontObject(GameTooltipText)
			right1:SetTextColor(r, g, b)
		end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

-- If the list window is open during updates, refresh its contents
hooksecurefunc(addon.DataHub, "RequestUpdate", function(_)
	if listWindow and listWindow.frame and listWindow.frame:IsShown() then populateListWindow() end
end)

return provider
