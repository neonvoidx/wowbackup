-- luacheck: globals EnhanceQoL C_FriendList NORMAL_FONT_COLOR UnitClass CUSTOM_CLASS_COLORS RAID_CLASS_COLORS
local addonName, addon = ...

local L = addon.L

local db
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
	if db.useClassColor == nil then db.useClassColor = false end
	if db.useTextColor == nil then db.useTextColor = false end
	if not db.textColor then
		local r, g, b = 1, 1, 1
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	if db.leftClickAction == nil then db.leftClickAction = "none" end
	if db.showOtherGames == nil then db.showOtherGames = false end
	if db.enhancedDisplay == nil then db.enhancedDisplay = false end
	if db.splitDisplay == nil then db.splitDisplay = false end
	if db.splitDisplayInline == nil then db.splitDisplayInline = false end
end

local function getClassColor()
	local classToken = UnitClass and select(2, UnitClass("player"))
	if not classToken then return nil end
	local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	if not colors then return nil end
	return colors[classToken]
end

local function colorizeStreamText(text)
	if not text or text == "" then return text end
	local color
	if db and db.useClassColor then
		color = getClassColor()
	elseif db and db.useTextColor then
		color = db.textColor
	end
	if color and color.r and color.g and color.b then
		return string.format("|cff%02x%02x%02x%s|r", math.floor((color.r or 1) * 255 + 0.5), math.floor((color.g or 1) * 255 + 0.5), math.floor((color.b or 1) * 255 + 0.5), text)
	end
	return text
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_friends_fontSize")
	end
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

local function sanitizeTable(value)
	value = sanitizeValue(value)
	if type(value) ~= "table" then return nil end
	return value
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

local myRealm = sanitizeString(GetRealmName and GetRealmName())
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

local function whisperTarget(name, realm)
	local base, nameRealm = splitNameRealm(name)
	if not base then return nil end
	realm = nameRealm or sanitizeString(realm)
	if realm then return base .. "-" .. realm:gsub("%s+", "") end
	return base
end

local function makeKey(name, realm)
	name = sanitizeString(name)
	realm = sanitizeString(realm)
	local base, r = splitNameRealm(name)
	base = base or name or ""
	r = r or realm or myRealm
	return (base:lower() .. "-" .. normalizeRealmName(r or ""))
end

local myPlayerName, myPlayerRealm
if UnitFullName then
	myPlayerName, myPlayerRealm = UnitFullName("player")
end
local myPlayerKey = makeKey(myPlayerName, sanitizeString(myPlayerRealm) or myRealm)

local function isOwnGuildEntry(name, realm, guid)
	guid = sanitizeString(guid)
	if guid and sanitizeString(myGuid) and guid == myGuid then return true end
	local key = makeKey(name, realm)
	if key == "-" or myPlayerKey == "-" then return false end
	return key == myPlayerKey
end

local function displayName(name, realm, projectID)
	name = sanitizeString(name)
	realm = sanitizeString(realm)
	local base, r = splitNameRealm(name)
	base = base or name or ""
	if (db and db.enhancedDisplay) or projectID == 18 then return base end
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
	local classInfo = sanitizeTable(C_CreatureInfo.GetClassInfo(classID))
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

local function buildLocationText(areaText, realmText, projectID)
	local area = sanitizeString(areaText)
	if (db and db.enhancedDisplay) or projectID == 18 then return area end
	local realm = getRealmDisplayText(realmText)
	if area and realm then return ("%s - %s"):format(area, realm) end
	return area or realm or nil
end

local function isSameZone(areaText)
	local areaKey = normalizeCompareText(areaText)
	if not areaKey then return false end

	local zoneKey = normalizeCompareText(GetZoneText and GetZoneText())
	local realZoneKey = normalizeCompareText(GetRealZoneText and GetRealZoneText())
	local subZoneKey = normalizeCompareText(GetSubZoneText and GetSubZoneText())

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
	-- This API restricts the call itself; checking its return value is too late.
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return nil end
	if addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true) then return nil end
	if not (C_GuildInfo and C_GuildInfo.GetMOTD) then return nil end
	local ok, motd = pcall(C_GuildInfo.GetMOTD)
	motd = ok and sanitizeString(motd) or nil
	if motd then return motd end
	return nil
end

local function requestGuildRosterIfNeeded(memberCount)
	if not IsInGuild or sanitizeValue(IsInGuild()) ~= true then return end
	memberCount = sanitizeNumber(memberCount)
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
				local isSelf = sanitizeValue(memberInfo.isSelf) == true or isOwnGuildEntry(name, nil, memberInfo.guid)
				if name and presence and presence ~= CLUB_PRESENCE_OFFLINE then
					local key = makeKey(name)
					if not seen[key] then
						local classDisp, color = classDisplayAndColorFromClassID(memberInfo.classID)
						local entry = {
							name = displayName(name),
							whisperTarget = whisperTarget(name),
							isSelf = isSelf,
							rank = sanitizeString(memberInfo.guildRank),
							faction = PLAYER_FACTION_GROUP and PLAYER_FACTION_GROUP[sanitizeNumber(memberInfo.faction)],
							note = sanitizeString(memberInfo.memberNote),
							level = sanitizeNumber(memberInfo.level),
							class = classDisp,
							color = color,
							status = clubPresenceToStatus(presence),
							location = zone,
							locationSameZone = zone and isSameZone(zone) or false,
						}
						seen[key] = entry
						table.insert(tooltipData.guild, entry)
					end
				end
			end
		end
	end
end

local function addGuildEntriesFromRoster(seen)
	local memberCount = sanitizeNumber(GetNumGuildMembers and GetNumGuildMembers()) or 0
	tooltipMeta.guildTotalCount = memberCount or 0
	requestGuildRosterIfNeeded(memberCount)
	if not memberCount or memberCount <= 0 then return end

	for i = 1, memberCount do
		local name, rank, _, level, _, zone, note, _, isOnline, status, classToken, _, _, _, _, _, guid = GetGuildRosterInfo(i)
		local isSelf = isOwnGuildEntry(name, nil, guid)
		local online = sanitizeValue(isOnline) == true
		name = sanitizeString(name)
		zone = sanitizeString(zone)
		level = sanitizeNumber(level)
		rank = sanitizeString(rank)
		note = sanitizeString(note)
		if online and name then
			local key = makeKey(name)
			if seen[key] then
				local entry = seen[key]
				entry.isSelf = entry.isSelf or isSelf
				entry.rank = entry.rank or rank
				entry.note = entry.note or note
			else
				local classDisp, color = classDisplayAndColor(classToken)
				local entry = {
					name = displayName(name),
					whisperTarget = whisperTarget(name),
					isSelf = isSelf,
					rank = rank,
					note = note,
					level = level,
					class = classDisp,
					color = color,
					status = guildRosterStatusToStatus(status),
					location = zone,
					locationSameZone = isSameZone(zone),
				}
				seen[key] = entry
				table.insert(tooltipData.guild, entry)
			end
		end
	end
end

local otherGameNames = {
	Pro = "DataPanelFriendsGameOverwatch",
	WTCG = "DataPanelFriendsGameHearthstone",
	Hero = "DataPanelFriendsGameHeroes",
	D3 = "DataPanelFriendsGameDiablo3",
	Fen = "DataPanelFriendsGameDiablo4",
	S1 = "DataPanelFriendsGameStarCraft",
	S2 = "DataPanelFriendsGameStarCraft2",
	W3 = "DataPanelFriendsGameWarcraft3",
}

-- Battle.net project IDs remain stable across clients, even when their globals are absent.
local wowProjectNames = {
	[1] = "DataPanelFriendsWoWRetail",
	[2] = "DataPanelFriendsWoWClassic",
	[5] = "DataPanelFriendsWoWTBC",
	[11] = "DataPanelFriendsWoWWrath",
	[14] = "DataPanelFriendsWoWCataclysm",
	[19] = "DataPanelFriendsWoWMists",
}

local function isOnlineGame(info)
	if not info or sanitizeValue(info.isOnline) ~= true then return false end
	local client = sanitizeString(info.clientProgram)
	return client and client ~= "App" and client ~= "BSAp" and client ~= "CLNT" or false
end

local function selectGameAccount(index, info)
	local game = info and sanitizeTable(info.gameAccountInfo)
	if not db.showOtherGames or isOnlineGame(game) then return game end
	if not (C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendGameAccountInfo) then return game end
	local count = sanitizeNumber(C_BattleNet.GetFriendNumGameAccounts(index)) or 0
	for gameIndex = 1, count do
		local candidate = sanitizeTable(C_BattleNet.GetFriendGameAccountInfo(index, gameIndex))
		if isOnlineGame(candidate) then return candidate end
	end
	return game
end

local function getFriends(stream)
	ensureDB()
	wipeTooltipSections()

	stream.snapshot.fontSize = db and db.fontSize or 13
	stream.snapshot.skipPanelClassColor = db and (db.useClassColor == true or db.useTextColor == true) or nil

	local seen = {} -- Deduplicate Battle.net and character friends.
	local totalUnique = 0
	local friendsCount = 0

	tooltipMeta.guildName = resolveGuildName()
	tooltipMeta.guildMotd = resolveGuildMotd()

	-- 1) Battle.net friends (prefer these when deduping)
	local numBNetTotal = sanitizeNumber(BNGetNumFriends())
	if numBNetTotal and numBNetTotal > 0 then
		for i = 1, numBNetTotal do
			local info = sanitizeTable(C_BattleNet.GetFriendAccountInfo(i))
			local ga = info and selectGameAccount(i, info)
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
					local battleTag = sanitizeString(info.battleTag)
					local bnName = sanitizeString(info.accountName) or (battleTag and battleTag:match("^[^#]+"))
					-- Prefer game-specific AFK/DND, fall back to account level
					local isAFK = (sanitizeValue(ga.isGameAFK) == true) or (sanitizeValue(info.isAFK) == true)
					local isDND = (sanitizeValue(ga.isGameBusy) == true) or (sanitizeValue(info.isDND) == true)
					local status
					if isDND then
						status = "DND"
					elseif isAFK then
						status = "AFK"
					end
					local projectID = sanitizeNumber(ga.wowProjectID)
					local location = buildLocationText(ga.areaName, sanitizeString(ga.realmDisplayName) or sanitizeString(ga.realmName), projectID)
					table.insert(tooltipData.bnet, {
						name = displayName(characterName, ga.realmName, projectID),
						bnetAccountID = sanitizeNumber(info.bnetAccountID),
						level = characterLevel,
						faction = sanitizeString(ga.factionName),
						class = classDisp,
						color = color,
						bnName = bnName,
						status = status,
						client = clientProgram,
						wowProjectID = projectID,
						location = location or sanitizeString(ga.richPresence) or sanitizeString(ga.gameText),
						locationSameZone = isSameZone(ga.areaName),
						note = sanitizeString(info.note),
					})
				end
			elseif db.showOtherGames and clientProgram ~= BNET_CLIENT_WOW and isOnlineGame(ga) then
				local battleTag = sanitizeString(info.battleTag)
				local accountName = sanitizeString(info.accountName) or (battleTag and battleTag:match("^[^#]+")) or characterName
				if accountName then
					table.insert(tooltipData.bnet, {
						name = accountName,
						bnetAccountID = sanitizeNumber(info.bnetAccountID),
						client = clientProgram,
						gameName = L[otherGameNames[clientProgram] or "DataPanelFriendsOtherGame"],
						location = sanitizeString(ga.richPresence) or sanitizeString(ga.gameText),
						note = sanitizeString(info.note),
						status = (sanitizeValue(ga.isGameBusy) == true or sanitizeValue(info.isDND) == true) and "DND"
							or (sanitizeValue(ga.isGameAFK) == true or sanitizeValue(info.isAFK) == true) and "AFK" or nil,
					})
				end
			end
		end
	end

	-- 2) Regular WoW friends
	local numWoWFriends = sanitizeNumber(C_FriendList.GetNumFriends()) or 0
	for i = 1, numWoWFriends do
		local friendInfo = sanitizeTable(C_FriendList.GetFriendInfoByIndex(i))
		local friendName = friendInfo and sanitizeString(friendInfo.name) or nil
		local friendConnected = friendInfo and sanitizeValue(friendInfo.connected) == true or false
		if friendInfo and friendConnected and friendName then
			local key = makeKey(friendName)
			if not seen[key] then
				seen[key] = true
				totalUnique = totalUnique + 1
				local classDisp, color = classDisplayAndColor(sanitizeString(friendInfo.className) or sanitizeString(friendInfo.classNameFile))
				local nameForDisp = displayName(friendName)
				table.insert(tooltipData.friends, {
					name = nameForDisp,
					whisperTarget = whisperTarget(friendName),
					level = sanitizeNumber(friendInfo.level),
					class = classDisp,
					color = color,
					status = (sanitizeValue(friendInfo.dnd) == true and "DND") or (sanitizeValue(friendInfo.afk) == true and "AFK") or nil,
					location = sanitizeString(friendInfo.area),
					locationSameZone = isSameZone(friendInfo.area),
					note = sanitizeString(friendInfo.notes),
				})
			end
		end
	end
	friendsCount = #tooltipData.bnet + #tooltipData.friends

	-- 3) Guild members
	local guildSeen = {}
	addGuildEntriesFromClub(guildSeen)
	addGuildEntriesFromRoster(guildSeen)
	-- Count the player once even while their roster entry is unavailable.
	tooltipMeta.guildOnlineCount = #tooltipData.guild
	local hasSelf = false
	for _, entry in ipairs(tooltipData.guild) do
		if entry.isSelf then hasSelf = true end
	end
	if not hasSelf and IsInGuild and sanitizeValue(IsInGuild()) == true then tooltipMeta.guildOnlineCount = tooltipMeta.guildOnlineCount + 1 end

	-- Enhanced sections group locations alphabetically, then names; unknown locations come last.
	local function byName(a, b)
		if db.enhancedDisplay then
			local leftZone = (sanitizeString(a.location) or ""):lower()
			local rightZone = (sanitizeString(b.location) or ""):lower()
			if leftZone ~= rightZone then
				if leftZone == "" then return false end
				if rightZone == "" then return true end
				return leftZone < rightZone
			end
		end
		local left = sanitizeString(a and a.name) or ""
		local right = sanitizeString(b and b.name) or ""
		return left:lower() < right:lower()
	end
	table.sort(tooltipData.bnet, function(a, b)
		local leftWoW, rightWoW = a.client == BNET_CLIENT_WOW, b.client == BNET_CLIENT_WOW
		if leftWoW ~= rightWoW then return leftWoW end
		return byName(a, b)
	end)
	table.sort(tooltipData.friends, byName)
	table.sort(tooltipData.guild, byName)

	totalUnique = friendsCount
	for key, entry in pairs(guildSeen) do
		if not entry.isSelf and not seen[key] then totalUnique = totalUnique + 1 end
	end

	if db and db.splitDisplay and db.enhancedDisplay then
		local guildText = tooltipMeta.guildName or GUILD
		local counts = string.format("%d / %d", friendsCount, tooltipMeta.guildOnlineCount)
		if not db.useClassColor and not db.useTextColor then
			counts = string.format("|cff4db3ff%d|r / |cff40ff66%d|r", friendsCount, tooltipMeta.guildOnlineCount)
		end
		if db.splitDisplayInline then
			stream.snapshot.text = colorizeStreamText(guildText .. "  " .. counts)
		else
			stream.snapshot.text = colorizeStreamText(guildText .. "\n" .. counts)
		end
	elseif db and db.splitDisplay then
		local guildText
		if tooltipMeta.guildTotalCount and tooltipMeta.guildTotalCount > 0 then
			guildText = string.format("%s: %d/%d", GUILD, tooltipMeta.guildOnlineCount, tooltipMeta.guildTotalCount)
		else
			guildText = string.format("%s: %d", GUILD, tooltipMeta.guildOnlineCount)
		end
		if db.splitDisplayInline then
			stream.snapshot.text = colorizeStreamText(string.format("%s  %s: %d", guildText, FRIENDS, friendsCount))
		else
			stream.snapshot.text = colorizeStreamText(string.format("%s\n%s: %d", guildText, FRIENDS, friendsCount))
		end
	else
		stream.snapshot.text = colorizeStreamText(totalUnique .. " " .. FRIENDS)
	end
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

local function formatEntryName(entry)
	local nameText = colorizedName(entry.name, entry.color) or (sanitizeString(entry.name) or "")
	local projectKey = entry.wowProjectID and wowProjectNames[entry.wowProjectID]
	if projectKey then nameText = nameText .. " |cff80bfff[" .. L[projectKey] .. "]|r" end
	if entry.gameName then
		local icon = _G.BNet_GetClientEmbeddedAtlas and _G.BNet_GetClientEmbeddedAtlas(entry.client, 14, 14) or ""
		nameText = icon .. " |cffffffff" .. entry.gameName .. "|r  |cff80bfff" .. nameText .. "|r"
	end
	if db.enhancedDisplay then
		local faction = sanitizeString(entry.faction)
		if faction == "Alliance" or faction == "Horde" then
			nameText = "|TInterface\\PVPFrame\\PVP-Currency-" .. faction .. ":14:14:0:0|t " .. nameText
		end
	end
	local level = sanitizeNumber(entry.level)
	if db.enhancedDisplay and level then nameText = "|cffffffff" .. level .. "|r  " .. nameText end
	local bnName = sanitizeString(entry.bnName)
	if bnName then nameText = nameText .. " |cff80bfff(" .. bnName .. ")|r" end
	local rank = sanitizeString(entry.rank)
	if db.enhancedDisplay and rank then nameText = nameText .. "  |cffffd100" .. rank .. "|r" end
	local status = sanitizeString(entry.status)
	if status == "DND" then
		nameText = nameText .. " |cffff5050[DND]|r"
	elseif status == "AFK" then
		nameText = nameText .. " |cffffb84d[AFK]|r"
	end
	local note = sanitizeString(entry.note)
	if db.enhancedDisplay and note then nameText = nameText .. "  |cffffffff" .. note:gsub("[\r\n]+", " ") .. "|r" end
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

local function getTooltipEntryRight(entry)
	local rightText = sanitizeString(entry.location) or ""
	if rightText == "" then
		if not db.enhancedDisplay then return buildClassLevelText(entry), false end
		return sanitizeString(entry.class) or "", false
	end
	return rightText, entry.locationSameZone == true
end

local function getTooltipRightColor(entry, sameZone)
	if not sanitizeString(entry.location) then return HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b end
	if sameZone then return 0.25, 1.0, 0.4 end
	if db.enhancedDisplay then return 1, 1, 1 end
	return 0.62, 0.62, 0.62
end

-- A separate window lets the pointer leave the stream and interact with rows.
local FriendsPopup = { rows = {}, count = 0 }

function FriendsPopup:UpdateWhisperLink(row, entry)
	local link = row.whisperLink
	row.canWhisper = false
	local name, accountID, format
	if entry and not entry.isSelf and entry.whisperTarget then
		name = sanitizeString(entry.whisperTarget)
		format = "|Hplayer:%s:0:WHISPER:%s|h%s|h"
	elseif entry and not entry.isSelf and entry.bnetAccountID and C_BattleNet.GetAccountInfoByID then
		local info = sanitizeTable(C_BattleNet.GetAccountInfoByID(entry.bnetAccountID))
		name = info and sanitizeString(info.accountName)
		accountID = sanitizeNumber(entry.bnetAccountID)
		if not accountID then name = nil end
		format = "|HBNplayer:%s:%d:0:BN_WHISPER:%s|h%s|h"
	end
	if not name or name:find("[:\r\n]") then
		if link then
			link.text:SetText("")
			link:Hide()
		end
		return
	end
	if not link then
		-- Keep the template's click handler: opening chat must start in Blizzard code.
		link = CreateFrame("Frame", nil, row, "InlineHyperlinkFrameTemplate")
		row.whisperLink = link
		link:SetAllPoints(row)
		link:EnableMouse(true)
		link.highlight = link:CreateTexture(nil, "BACKGROUND")
		link.highlight:SetAllPoints(link)
		link.highlight:SetColorTexture(1, 1, 1, 0.12)
		link.highlight:Hide()
		link.text = link:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		link.text:SetJustifyH("LEFT")
		link.text:SetJustifyV("TOP")
		link.text:SetWordWrap(false)
		link.text:SetAlpha(0)
		link:SetScript("OnHyperlinkEnter", function()
			self:SetRowHighlight(row, true)
			self:ShowRowTooltip(row)
		end)
		link:SetScript("OnHyperlinkLeave", function()
			self:SetRowHighlight(row, false)
			self:HideRowTooltip(row)
		end)
		link:SetScript("OnEnter", function()
			self:UpdateWhisperLink(row, row.entry)
			self:SetRowHighlight(row, true)
			self:ShowRowTooltip(row)
		end)
		link:SetScript("OnLeave", function()
			self:SetRowHighlight(row, false)
			self:HideRowTooltip(row)
		end)
		-- Run after the native click so opening chat and menus stays in Blizzard code.
		link:HookScript("OnHyperlinkClick", function(_, _, _, button)
			if button == "LeftButton" then
				self.frame:Hide()
			elseif button == "RightButton" then
				local menu = _G.Menu
				local manager = menu and menu.GetManager and menu.GetManager()
				self.contextMenu = manager and manager.GetOpenMenu and manager:GetOpenMenu() or nil
			end
		end)
	end
	local filler = string.rep("W", 128)
	if accountID then
		link.text:SetFormattedText(format, name, accountID, name, filler)
	else
		link.text:SetFormattedText(format, name, name, filler)
	end
	row.canWhisper = true
	link:Show()
end

function FriendsPopup:SetRowHighlight(row, enabled)
	local link = row.whisperLink
	if not link then return end
	if enabled and row.canWhisper then
		link.highlight:Show()
	else
		link.highlight:Hide()
	end
end

function FriendsPopup:ShowRowTooltip(row)
	if not row.truncated or not GameTooltip then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	local r, g, b = row.left:GetTextColor()
	GameTooltip:AddLine(row.left:GetText() or "", r, g, b, true)
	local right = row.right:GetText()
	if right and right ~= "" then
		r, g, b = row.right:GetTextColor()
		GameTooltip:AddLine(right, r, g, b, true)
	end
	GameTooltip:Show()
end

function FriendsPopup:HideRowTooltip(row)
	if GameTooltip and GameTooltip:GetOwner() == row then GameTooltip:Hide() end
end

function FriendsPopup:Create()
	if self.frame then return end
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	self.frame = frame
	frame:Hide()
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
	frame:SetBackdropColor(0.05, 0.05, 0.08, 1)
	self.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	self.scroll.scrollBarHideable = true
	self.scroll:SetPoint("TOPLEFT", 10, -10)
	self.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
	self.content = CreateFrame("Frame", nil, self.scroll)
	self.content:SetSize(1, 1)
	self.scroll:SetScrollChild(self.content)
	frame:SetScript("OnUpdate", function(_, elapsed)
		local owner = self.owner
		if not owner or not owner:IsVisible() or (owner.slot and owner.slot.panel and owner.slot.panel.info and owner.slot.panel.info.showTooltips == false) then
			frame:Hide()
			return
		end
		if self.contextMenu and self.contextMenu:IsShown() then
			self.leaveTime = 0
			return
		end
		self.contextMenu = nil
		if addon.functions.MouseIsOver(frame) or addon.functions.MouseIsOver(owner) then
			self.leaveTime = 0
		else
			self.leaveTime = (self.leaveTime or 0) + elapsed
			if self.leaveTime > 0.25 then frame:Hide() end
		end
	end)
	frame:SetScript("OnHide", function()
		self.owner = nil
		self.contextMenu = nil
	end)
end

function FriendsPopup:ClearLines()
	self:Create()
	self.contextMenu = nil
	for _, row in ipairs(self.rows) do
		row:Hide()
		row.entry = nil
		self:UpdateWhisperLink(row)
	end
	self.count = 0
	self.leaveTime = 0
	self.scroll:SetVerticalScroll(0)
end

function FriendsPopup:SetOwner(owner)
	self.owner = owner
end

function FriendsPopup:ClearAllPoints() self.frame:ClearAllPoints() end
function FriendsPopup:SetPoint(...) self.frame:SetPoint(...) end

function FriendsPopup:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)
	self.count = self.count + 1
	local row = self.rows[self.count]
	if not row then
		row = CreateFrame("Button", nil, self.content)
		row:RegisterForClicks("LeftButtonUp")
		row.left = row:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		row.left:SetPoint("TOPLEFT", 2, -2)
		row.left:SetJustifyH("LEFT")
		row.right = row:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		row.right:SetPoint("TOPRIGHT", -2, -2)
		row.right:SetJustifyH("RIGHT")
		row.right:SetWordWrap(true)
		row.right:SetNonSpaceWrap(true)
		row:SetScript("OnEnter", function(button) self:ShowRowTooltip(button) end)
		row:SetScript("OnLeave", function(button) self:HideRowTooltip(button) end)
		row:SetScript("OnHide", function(button)
			self:SetRowHighlight(button, false)
			self:HideRowTooltip(button)
		end)
		self.rows[self.count] = row
	end
	row.left:SetWordWrap(true)
	row.left:SetText(left or "")
	row.right:SetText(right or "")
	row.left:SetTextColor(lr or 1, lg or 1, lb or 1)
	row.right:SetTextColor(rr or 1, rg or 1, rb or 1)
	row.wrap = false
	row.entry = nil
	self:SetRowHighlight(row, false)
	self:UpdateWhisperLink(row)
	row:EnableMouse(false)
	row:Show()
	return row
end

function FriendsPopup:AddLine(text, r, g, b, wrap)
	local row = self:AddDoubleLine(text, nil, r, g, b)
	row.wrap = wrap == true
	row.left:SetWordWrap(true)
end

function FriendsPopup:AddFriendLine(entry, left, right, lr, lg, lb, rr, rg, rb)
	local row = self:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)
	row.entry = entry
	self:UpdateWhisperLink(row, entry)
	row:EnableMouse(row.canWhisper)
end

function FriendsPopup:Show()
	if self.count == 0 then
		self.frame:Hide()
		return
	end
	local leftWidth, rightWidth = 0, 0
	for i = 1, self.count do
		local row = self.rows[i]
		-- Wrapped announcements use the list width instead of expanding it to their full text length.
		if not row.wrap then leftWidth = math.max(leftWidth, row.left:GetUnboundedStringWidth()) end
		rightWidth = math.max(rightWidth, row.right:GetUnboundedStringWidth())
	end
	-- Long locations and game statuses wrap instead of expanding the entire popup.
	rightWidth = math.min(rightWidth, 320)
	local width = math.min(math.max(640, leftWidth + rightWidth + 68), UIParent:GetWidth() - 40, 1100)
	local available = width - 44
	local columnBudget = available - (rightWidth > 0 and 24 or 0)
	if leftWidth + rightWidth > columnBudget then
		-- Keep fitting names intact; oversized status text must not consume their space.
		-- When both columns overflow, reserve at least 60 percent for names.
		rightWidth = math.min(rightWidth, math.max(columnBudget - leftWidth, math.floor(columnBudget * 0.4)))
	end
	leftWidth = columnBudget - rightWidth
	self.frame:SetWidth(width)
	self.content:SetWidth(width - 40)
	local height = 0
	for i = 1, self.count do
		local row = self.rows[i]
		row.left:SetWidth(row.wrap and available or leftWidth)
		row.right:SetWidth(math.max(1, rightWidth))
		row.truncated = not row.wrap and (row.left:IsTruncated() or row.right:IsTruncated())
		row:EnableMouse(row.canWhisper or row.truncated)
		local rowHeight = math.max(18, row.left:GetStringHeight() + 4, row.right:GetStringHeight() + 4)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -height)
		row:SetSize(width - 40, rowHeight)
		if row.whisperLink then
			local text = row.whisperLink.text
			local fontSize = rowHeight + 8
			text:SetFont(_G.STANDARD_TEXT_FONT, fontSize, "")
			text:ClearAllPoints()
			text:SetPoint("TOPLEFT", row.whisperLink, "TOPLEFT", -4, 4)
			text:SetPoint("RIGHT", row.whisperLink, "RIGHT", fontSize * 2, 0)
		end
		height = height + rowHeight
	end
	self.content:SetHeight(math.max(1, height))
	self.frame:SetHeight(math.min(height + 20, UIParent:GetHeight() * 0.65))
	self.frame:Show()
	-- Refresh after layout, including the initial zero-range case and reopening a shorter list.
	_G.ScrollFrame_OnScrollRangeChanged(self.scroll)
end

local provider = {
	id = "friends",
	version = 1,
	title = FRIENDS,
	update = getFriends,
	events = {
		PLAYER_LOGIN = function(stream)
			requestGuildRosterIfNeeded(GetNumGuildMembers and GetNumGuildMembers())
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
			requestGuildRosterIfNeeded(GetNumGuildMembers and GetNumGuildMembers())
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
		ensureDB()
		if btn == "RightButton" then
			openSettings()
		elseif btn == "LeftButton" then
			if db.leftClickAction == "guild" then
				if _G.InCombatLockdown and _G.InCombatLockdown() then
					if _G.UIErrorsFrame and _G.ERR_NOT_IN_COMBAT then _G.UIErrorsFrame:AddMessage(_G.ERR_NOT_IN_COMBAT) end
					return
				end
				local addons = _G.C_AddOns
				if addons and addons.IsAddOnLoaded and addons.LoadAddOn then
					if not addons.IsAddOnLoaded("Blizzard_Communities") then addons.LoadAddOn("Blizzard_Communities") end
				elseif _G.UIParentLoadAddOn then
					_G.UIParentLoadAddOn("Blizzard_Communities")
				end
				if _G.ToggleGuildFrame then _G.ToggleGuildFrame() end
			elseif db.leftClickAction == "guildChat" and IsInGuild and sanitizeValue(IsInGuild()) == true then
				local openChat = _G.ChatFrameUtil and _G.ChatFrameUtil.OpenChat or _G.ChatFrame_OpenChat
				if openChat then openChat((_G.SLASH_GUILD1 or "/g") .. " ") end
			end
		end
	end,
	OnMouseEnter = function(btn)
		ensureDB()
		GameTooltip:Hide()
		local tip = FriendsPopup
		tip:ClearLines()
		if addon.DataPanel and addon.DataPanel.SetTooltipOwner then
			addon.DataPanel.SetTooltipOwner(btn, tip)
		else
			tip:SetOwner(btn)
			tip:ClearAllPoints()
			tip:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
		end

		local hasContent = false
		local function addSection(title, items, color, total, onlineCount)
			local count = onlineCount or #items
			if #items == 0 and not (db.enhancedDisplay and (count > 0 or (total and total > 0))) then return end
			if hasContent then tip:AddLine(" ") end
			hasContent = true
			color = color or HIGHLIGHT_FONT_COLOR
			local countText = total and total > 0 and string.format("%d/%d", count, total) or tostring(count)
			if db.enhancedDisplay then
				tip:AddDoubleLine(title, countText, color.r, color.g, color.b, color.r, color.g, color.b)
			else
				tip:AddLine(string.format("%s (%d)", title, count), color.r, color.g, color.b)
			end
			for _, entry in ipairs(items) do
				local left = formatEntryName(entry)
				local right, sameZone = getTooltipEntryRight(entry)
				local rr, rg, rb = getTooltipRightColor(entry, sameZone)
				tip:AddFriendLine(entry, left, right, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, rr, rg, rb)
			end
		end

		if db.enhancedDisplay then
			if tooltipMeta.guildName or tooltipMeta.guildTotalCount > 0 or tooltipMeta.guildMotd then
				tip:AddLine(tooltipMeta.guildName or GUILD, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				if tooltipMeta.guildMotd and tooltipMeta.guildMotd ~= "" then tip:AddLine("MOTD - " .. tooltipMeta.guildMotd, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true) end
				hasContent = true
			end

			addSection(BATTLENET_OPTIONS_LABEL or "Battle.net", tooltipData.bnet, CreateColor(0.3, 0.7, 1.0))
			addSection(FRIENDS, tooltipData.friends, CreateColor(0.8, 0.8, 1.0))
			addSection(GUILD, tooltipData.guild, CreateColor(0.25, 1.0, 0.4), tooltipMeta.guildTotalCount, tooltipMeta.guildOnlineCount)
		else
			if tooltipMeta.guildName or tooltipMeta.guildTotalCount > 0 or tooltipMeta.guildMotd then
				local guildCountText
				if tooltipMeta.guildTotalCount and tooltipMeta.guildTotalCount > 0 then
					guildCountText = string.format("%s: %d/%d", GUILD, tooltipMeta.guildOnlineCount, tooltipMeta.guildTotalCount)
				else
					guildCountText = string.format("%s: %d", GUILD, tooltipMeta.guildOnlineCount)
				end
				tip:AddDoubleLine(tooltipMeta.guildName or GUILD, guildCountText, 0.25, 1.0, 0.4, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				if tooltipMeta.guildMotd and tooltipMeta.guildMotd ~= "" then tip:AddLine("MOTD - " .. tooltipMeta.guildMotd, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true) end
				hasContent = true
			end

			addSection(GUILD, tooltipData.guild, CreateColor(0.25, 1.0, 0.4), nil, tooltipMeta.guildOnlineCount)
			addSection(FRIENDS, tooltipData.friends, CreateColor(0.8, 0.8, 1.0))
			addSection(BATTLENET_OPTIONS_LABEL or "Battle.net", tooltipData.bnet, CreateColor(0.3, 0.7, 1.0))
		end

		local hint = getOptionsHint()
		if hint then
			if hasContent then tip:AddLine(" ") end
			tip:AddLine(hint)
		end
		tip:Show()

	end,
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
