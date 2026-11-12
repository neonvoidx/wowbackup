-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSTelemetryComm = private.NewLib("RareScannerTelemetryComm")

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSConfigDB = private.ImportLib("RareScannerConfigDB")
local RSLogger = private.ImportLib("RareScannerLogger")
local RSTelemetryDB = private.ImportLib("RareScannerTelemetryDB")

-- Ace libraries
local AceComm = LibStub("AceComm-3.0")
AceComm:Embed(RSTelemetryComm)

---============================================================================
-- Messages
-- A message groups several items separated by "|". Each item has its fields separated by ",":
--   Kill:   K,...                                         (sent by the versions before 12.1.7, ignored: with the obfuscated GUIDs the kills can't be paired with the ones of other players)
--   Sample: S,npcID,spawnTime,respawnSeconds,shardID[,1][,offlineSeconds][,L]  (respawnSeconds is empty if the death is unknown, 1 if the
--     respawn is not reliable because the sender was offline in between, and the seconds that he was offline; the shard is 0-0-0 if unknown)
--   Request: Q                                           (asks the guild when connecting, or the group when joining it, for recent samples)
--   Claim:   C,requesterHash                              (a member says that he will answer the request)
---============================================================================

local ITEM_SEPARATOR = "|"
local ITEM_KILL = "K"
local ITEM_SAMPLE = "S"
local ITEM_REQUEST = "Q"
local ITEM_CLAIM = "C"

-- The shard is not saved with the samples, so the samples sent when synchronizing use a shard that never matches
local UNKNOWN_SHARD = "0-0-0"

-- RSTelemetry is loaded after this library, so it can't be imported at the top
local function IsNpcSupported(npcID)
	return private.ImportLib("RareScannerTelemetry").IsNpcSupported(npcID)
end

-- An error in the communications must never reach the players, so everything runs protected.
-- If it fails too many times, the communications are disabled until the next reload
local errorCount = 0

local function RunProtected(func, ...)
	if (errorCount >= RSConstants.TELEMETRY_COMM_MAX_ERRORS) then
		return
	end

	local isOk, errorMessage = pcall(func, ...)
	if (not isOk) then
		errorCount = errorCount + 1
		RSTelemetryDB.IncreaseStat("errors")
		RSLogger:PrintTelemetryDebugMessage(string.format("Error en las comunicaciones (%s/%s): %s", errorCount, RSConstants.TELEMETRY_COMM_MAX_ERRORS, tostring(errorMessage)))
	end
end

-- The numbers of a message must be finite integers. tonumber also accepts "nan" and "inf", and every comparison with NaN is false
local function ParseNumber(text)
	local number = tonumber(text)
	if (number and number == number and number ~= math.huge and number ~= -math.huge and number == math.floor(number)) then
		return number
	end

	return nil
end

--- In WoW Forever there are no realms and the players have a name and a surname ("Name Surname"), and several characters can share
--- the name or the surname. Both words are always used, joined with a hyphen, so a player has the same text in every source
local function GetFullName(name)
	name = (name:gsub(" ", "-"))
	if (not name:find("-", 1, true)) then
		return name.."-"..(GetNormalizedRealmName and GetNormalizedRealmName() or "")
	end

	return name
end

--- The name of the player that is whispered. If the client doesn't accept the hyphen, only this function has to change
local function GetWhisperTarget(name)
	return (name:gsub(" ", "-"))
end

--- Short anonymous code of a player, so the names of other players are never saved
function RSTelemetryComm.GetSenderHash(name)
	name = GetFullName(name)
	local hash = 5381
	for index = 1, #name do
		hash = (hash * 33 + string.byte(name, index)) % 4294967296
	end

	return string.format("%08x", hash)
end

---============================================================================
-- Sending
---============================================================================

local pendingItems = {}
local isSendScheduled = false

local function GetGroupDistribution()
	if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
		return "INSTANCE_CHAT"
	elseif (IsInRaid()) then
		return "RAID"
	elseif (IsInGroup()) then
		return "PARTY"
	end

	return nil
end

local function GetDistributions()
	local distributions = {}
	if (IsInGuild()) then
		table.insert(distributions, "GUILD")
	end

	local groupDistribution = GetGroupDistribution()
	if (groupDistribution) then
		table.insert(distributions, groupDistribution)
	end

	return distributions
end

-- Nothing is sent during combat or when the chat is restricted
local function IsSendingRestricted()
	return InCombatLockdown() or (C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown())
end

local function ScheduleSend()
	if (isSendScheduled) then
		return
	end

	isSendScheduled = true
	local delay = RSConstants.TELEMETRY_COMM_SEND_DELAY + (math.random() * RSConstants.TELEMETRY_COMM_SEND_JITTER)
	C_Timer.After(delay, function()
		RSTelemetryComm.SendPendingItems()
	end)
end

local function QueueItem(item)
	RSTelemetryDB.IncreaseStat("itemsQueued")
	if (#pendingItems >= RSConstants.TELEMETRY_COMM_MAX_QUEUE) then
		table.remove(pendingItems, 1)
	end

	table.insert(pendingItems, item)
	ScheduleSend()
end

local function SendPendingItems()
	isSendScheduled = false

	-- If the player disables the telemetry, what is waiting to be sent is not sent
	if (not RSConfigDB.IsTelemetryEnabled()) then
		wipe(pendingItems)
		return
	end

	if (#pendingItems == 0) then
		return
	end

	if (IsSendingRestricted()) then
		ScheduleSend()
		return
	end

	local distributions = GetDistributions()
	if (#distributions == 0) then
		wipe(pendingItems)
		return
	end

	-- Each channel gets one message with the items that it still doesn't have, because someone else
	-- could have sent some of them in only one of the channels
	for _, distribution in ipairs(distributions) do
		local texts = {}
		local length = 0
		for _, item in ipairs(pendingItems) do
			if (not item.covered[distribution] and not item.sentTo[distribution]) then
				if (#texts > 0 and length + #item.text + 1 > RSConstants.TELEMETRY_COMM_MAX_LENGTH) then
					break
				end

				table.insert(texts, item.text)
				length = length + #item.text + 1
				item.sentTo[distribution] = true
			end
		end

		if (#texts > 0) then
			RSTelemetryComm:SendCommMessage(RSConstants.TELEMETRY_COMM_PREFIX, table.concat(texts, ITEM_SEPARATOR), distribution, nil, "BULK")
			RSTelemetryDB.IncreaseStat("messagesSent")
		end
	end

	-- An item is finished when every channel has it, sent by us or by someone else
	for index = #pendingItems, 1, -1 do
		local item = pendingItems[index]
		local isFinished = true
		for _, distribution in ipairs(distributions) do
			if (not item.covered[distribution] and not item.sentTo[distribution]) then
				isFinished = false
				break
			end
		end

		if (isFinished) then
			table.remove(pendingItems, index)
		end
	end

	if (#pendingItems > 0) then
		ScheduleSend()
	end
end

--- Sends the items that are waiting, in a message for each channel. If there are more, they will be sent in the next ones
function RSTelemetryComm.SendPendingItems()
	RunProtected(SendPendingItems)
end

-- Identifies what an item tells, to not send it if someone else already did
-- A sample with respawn tells more than one without it, so they have different keys
local function GetSampleKey(npcID, spawnTime, hasRespawn)
	return string.format("S,%d,%d,%d", npcID, spawnTime, hasRespawn and 1 or 0)
end

--- The optional fields of a sample: the mark of the offline time and the seconds offline (the mark is empty if there is no mark)
local function GetOfflineFields(sample)
	-- The last field is L if the respawn was measured watching, so the others have to be there
	if (sample.live) then
		return string.format(",%s,%s,L", sample.gap and "1" or "", sample.offline and tostring(sample.offline) or "")
	end

	if (sample.offline) then
		return string.format(",%s,%d", sample.gap and "1" or "", sample.offline)
	end

	return sample.gap and ",1" or ""
end

function RSTelemetryComm.SendSample(npcID, sample, shardID)
	-- A creature seen for the first time doesn't tell anything, and its shard only lasts during the session
	if (not sample.deathTime) then
		return
	end
	shardID = UNKNOWN_SHARD

	local respawnSeconds = sample.deathTime and (sample.spawnTime - sample.deathTime) or ""
	QueueItem({
		text = string.format("%s,%d,%d,%s,%s%s", ITEM_SAMPLE, npcID, sample.spawnTime, respawnSeconds, shardID, GetOfflineFields(sample)),
		key = GetSampleKey(npcID, sample.spawnTime, sample.deathTime ~= nil),
		covered = {},
		sentTo = {},
	})
end

-- If someone else already told about it in a channel, there is no need to send it again to that channel
local function MarkItemCovered(key, distribution)
	for _, item in ipairs(pendingItems) do
		if (item.key == key) then
			item.covered[distribution] = true
		end
	end
end

---============================================================================
-- Receiving
---============================================================================

local itemsReceivedBySender = {}

local function IsOwnMessage(sender)
	return RSTelemetryComm.GetSenderHash(sender) == RSTelemetryComm.GetSenderHash(GetUnitName("player", true))
end

--- Each sender can send a limited number of items per minute
local function IsSenderAllowed(sender, itemCount)
	local now = GetTime()
	local senderInfo = itemsReceivedBySender[sender]
	if (not senderInfo or (now - senderInfo.startTime) >= 60) then
		senderInfo = { startTime = now, count = 0 }
		itemsReceivedBySender[sender] = senderInfo
	end

	if (senderInfo.count + itemCount > RSConstants.TELEMETRY_COMM_MAX_ITEMS_PER_MINUTE) then
		return false
	end

	senderInfo.count = senderInfo.count + itemCount
	return true
end

-- A limit of items processed per second in total, no matter how many players send them
local globalWindowStart = 0
local globalItemsCount = 0

local function IsGlobalLimitAllowed(itemCount)
	local now = GetTime()
	if ((now - globalWindowStart) >= 1) then
		globalWindowStart = now
		globalItemsCount = 0
	end

	if (globalItemsCount + itemCount > RSConstants.TELEMETRY_COMM_MAX_ITEMS_PER_SECOND) then
		return false
	end

	globalItemsCount = globalItemsCount + itemCount
	return true
end

-- The context has the name of the sender, how the message was sent and if it is a dry run
local function ReceiveSample(sender, npcID, spawnTime, respawnSeconds, shardID, isGap, offlineSeconds, isLive, context)
	local isDryRun = context.isDryRun
	if (not IsNpcSupported(npcID) or not RSTelemetryDB.IsValidShardID(shardID)) then
		RSTelemetryDB.IncreaseStat(isDryRun and "loopbackInvalid" or "rejectedInvalid")
		return
	end

	-- A dry run only checks that the message is correct, nothing is saved
	if (isDryRun) then
		RSTelemetryDB.IncreaseStat("loopbackValid")
		return
	end

	-- With the obfuscated GUIDs a creature without respawn can't be paired with anything of the other players
	if (not respawnSeconds) then
		RSTelemetryDB.IncreaseStat("ignoredLive")
		return
	end

	-- Someone has already sent it in this channel. A sample without respawn doesn't cancel one with respawn
	MarkItemCovered(GetSampleKey(npcID, spawnTime, false), context.distribution)
	if (respawnSeconds) then
		MarkItemCovered(GetSampleKey(npcID, spawnTime, true), context.distribution)
	end

	local sample = {
		spawnTime = spawnTime,
		deathTime = respawnSeconds and (spawnTime - respawnSeconds) or nil,
		sender = sender,
		gap = isGap or nil,
		offline = offlineSeconds,
		shard = shardID ~= UNKNOWN_SHARD and shardID or nil,
		live = isLive or nil,
	}

	local isAdded, rejectionReason = RSTelemetryDB.AddSample(npcID, sample)
	if (isAdded) then
		RSTelemetryDB.IncreaseStat("samplesAccepted")
		RSLogger:PrintTelemetryDebugMessage(string.format("Muestra recibida de [%s]: NPC [%s] en Shard [%s].", sender, npcID, shardID))
	else
		RSTelemetryDB.IncreaseStat("samplesNotAdded")
		RSTelemetryDB.IncreaseStat("samplesNotAdded_"..rejectionReason)
	end
end

---============================================================================
-- Synchronization with the guild
---============================================================================

local syncRequestTime = nil
local answerers = {} -- the members that announced that they answer our request, the only ones that can whisper us data
local pendingResponses = {}
local requestsSeen = {}
local claimedRequests = {} -- the requests that a member has already claimed
local responseTimes = {}

local function IsSyncResponseExpected()
	return syncRequestTime ~= nil and (GetTime() - syncRequestTime) < RSConstants.TELEMETRY_SYNC_RECEIVE_WINDOW
end

--- The members that announced an answer are forgotten when the window of the request ends, so the requests of the guild
--- and the group don't discard the answers of each other
local function StartSyncWindow()
	if (not IsSyncResponseExpected()) then
		wipe(answerers)
	end

	syncRequestTime = GetTime()
end

function RSTelemetryComm.RequestSync()
	if (not RSConfigDB.IsTelemetryEnabled() or not IsInGuild() or IsSendingRestricted()) then
		return
	end

	-- The guild is asked once every 30 minutes, and each guild has its own time (the player can have characters in several)
	local guildName = GetGuildInfo("player")
	if (not guildName) then
		return
	end

	local now = GetServerTime()
	local lastRequestTime, lastGuildName = RSTelemetryDB.GetLastSyncRequest()
	if (lastGuildName == guildName and (now - lastRequestTime) < RSConstants.TELEMETRY_SYNC_COOLDOWN) then
		return
	end

	RSTelemetryDB.SetLastSyncRequest(now, guildName)
	StartSyncWindow()
	RSTelemetryComm:SendCommMessage(RSConstants.TELEMETRY_COMM_PREFIX, ITEM_REQUEST, "GUILD", nil, "BULK")
	RSTelemetryDB.IncreaseStat("syncRequestsSent")
	return true
end

local lastGroupRequestTime = nil
local wasInGroup = false

--- When the player joins a group, its members are asked for their samples too (the guild could be small or empty)
function RSTelemetryComm.RequestGroupSync(attempt)
	attempt = attempt or 1
	local distribution = GetGroupDistribution()
	if (not RSConfigDB.IsTelemetryEnabled() or not distribution) then
		return
	end

	-- Joining a group of an instance usually happens with the chat restricted, so it tries again a few times
	if (IsSendingRestricted()) then
		if (attempt < RSConstants.TELEMETRY_SYNC_GROUP_MAX_ATTEMPTS) then
			C_Timer.After(RSConstants.TELEMETRY_SYNC_GROUP_RETRY_INTERVAL, function()
				RunProtected(RSTelemetryComm.RequestGroupSync, attempt + 1)
			end)
		end
		return
	end

	-- In debug mode the cooldown is short, to collect data from many groups
	local now = GetTime()
	local cooldown = RSConstants.DEBUG_MODE and RSConstants.TELEMETRY_SYNC_GROUP_DEBUG_COOLDOWN or RSConstants.TELEMETRY_SYNC_GROUP_COOLDOWN
	if (lastGroupRequestTime and (now - lastGroupRequestTime) < cooldown) then
		return
	end

	lastGroupRequestTime = now
	StartSyncWindow()
	RSTelemetryComm:SendCommMessage(RSConstants.TELEMETRY_COMM_PREFIX, ITEM_REQUEST, distribution, nil, "BULK")
	RSTelemetryDB.IncreaseStat("syncRequestsSent")
	return true
end

--- Development only (DEBUG_MODE): asks the guild and the group now, without waiting for the cooldowns.
-- Returns whether the guild was asked and whether the group was asked
function RSTelemetryComm.ForceSync()
	lastGroupRequestTime = nil
	RSTelemetryDB.SetLastSyncRequest(0, nil)
	return RSTelemetryComm.RequestSync() == true, RSTelemetryComm.RequestGroupSync() == true
end

--- Called when the members of the group change. It only asks when the player was not in a group
function RSTelemetryComm.OnGroupRosterUpdate()
	local isInGroup = GetGroupDistribution() ~= nil
	if (isInGroup and not wasInGroup) then
		C_Timer.After(RSConstants.TELEMETRY_SYNC_GROUP_DELAY, function()
			RunProtected(RSTelemetryComm.RequestGroupSync)
		end)
	end

	wasInGroup = isInGroup
end

local function CountRecentResponses()
	local now = GetTime()
	local count = 0
	for index = #responseTimes, 1, -1 do
		if ((now - responseTimes[index]) > 60) then
			table.remove(responseTimes, index)
		else
			count = count + 1
		end
	end

	return count
end

--- Groups the texts in messages that fit in the limit
local function BuildMessages(texts)
	local messages = {}
	local currentTexts = {}
	local length = 0
	for _, text in ipairs(texts) do
		if (#currentTexts > 0 and length + #text + 1 > RSConstants.TELEMETRY_COMM_MAX_LENGTH) then
			table.insert(messages, table.concat(currentTexts, ITEM_SEPARATOR))
			currentTexts = {}
			length = 0
		end

		table.insert(currentTexts, text)
		length = length + #text + 1
	end

	if (#currentTexts > 0) then
		table.insert(messages, table.concat(currentTexts, ITEM_SEPARATOR))
	end

	return messages
end

local function SendSyncMessage(requesterName, messages, index, deadline)
	if (not messages[index] or not RSConfigDB.IsTelemetryEnabled() or GetTime() > deadline) then
		return
	end

	-- In combat the claim has already cancelled the other members, so it waits until the requester stops accepting answers
	if (IsSendingRestricted()) then
		C_Timer.After(RSConstants.TELEMETRY_SYNC_MESSAGE_INTERVAL, function()
			RunProtected(SendSyncMessage, requesterName, messages, index, deadline)
		end)
		return
	end

	RSTelemetryComm:SendCommMessage(RSConstants.TELEMETRY_COMM_PREFIX, messages[index], "WHISPER", GetWhisperTarget(requesterName), "BULK")
	RSTelemetryDB.IncreaseStat("syncMessagesSent")

	if (messages[index + 1]) then
		C_Timer.After(RSConstants.TELEMETRY_SYNC_MESSAGE_INTERVAL, function()
			RunProtected(SendSyncMessage, requesterName, messages, index + 1, deadline)
		end)
	end
end

local function RespondToRequest(requesterHash)
	local pending = pendingResponses[requesterHash]
	pendingResponses[requesterHash] = nil

	-- Someone else has already answered
	if (not pending) then
		RSTelemetryDB.IncreaseStat("syncResponsesCancelled")
		return
	end

	-- The claim goes to the channel where the request came from
	local channel = pending.isGuild and (IsInGuild() and "GUILD" or nil) or GetGroupDistribution()
	if (not RSConfigDB.IsTelemetryEnabled() or not channel or IsSendingRestricted()) then
		return
	end
	local requesterName = pending.name

	-- Several requests can arrive at the same time, so the limit is checked again when answering
	if (CountRecentResponses() >= RSConstants.TELEMETRY_SYNC_MAX_RESPONSES_PER_MINUTE) then
		RSTelemetryDB.IncreaseStat("syncResponsesLimited")
		return
	end

	-- The newest samples are sent, even if they were received from others, so one answer carries what the guild knows.
	-- The requester only accepts a few samples of each NPC from a sender, and he doesn't need his own samples back
	local texts = {}
	local recentSamples = RSTelemetryDB.GetRecentRespawnSamples(RSConstants.TELEMETRY_SYNC_MAX_ITEMS, RSConstants.TELEMETRY_MAX_SAMPLES_PER_SENDER, requesterHash)
	for _, recentSample in ipairs(recentSamples) do
		local sample = recentSample.sample
		table.insert(texts, string.format("%s,%d,%d,%d,%s%s", ITEM_SAMPLE, recentSample.npcID, sample.spawnTime, sample.spawnTime - sample.deathTime, sample.shard or UNKNOWN_SHARD, GetOfflineFields(sample)))
	end
	if (#texts == 0) then
		return
	end

	table.insert(responseTimes, GetTime())
	RSTelemetryComm:SendCommMessage(RSConstants.TELEMETRY_COMM_PREFIX, ITEM_CLAIM..","..requesterHash, channel, nil, "BULK")

	-- The claim goes through the guild channel and the whisper through another route, so the whisper must not arrive first
	local messages = BuildMessages(texts)
	local deadline = (requestsSeen[requesterHash] or GetTime()) + RSConstants.TELEMETRY_SYNC_RECEIVE_WINDOW
	C_Timer.After(RSConstants.TELEMETRY_SYNC_MESSAGE_INTERVAL, function()
		RunProtected(SendSyncMessage, requesterName, messages, 1, deadline)
	end)
end

local function ScheduleResponse(requesterHash, requesterName, isGuild, onlyIfUnclaimed)
	if (pendingResponses[requesterHash] or (onlyIfUnclaimed and (claimedRequests[requesterHash] or not RSConfigDB.IsTelemetryEnabled()))) then
		return
	end

	-- Whoever has nothing to send doesn't answer, and the claim of the first one cancels the rest, so the one with more samples goes first
	local availableSamples = #RSTelemetryDB.GetRecentRespawnSamples(RSConstants.TELEMETRY_SYNC_MAX_ITEMS, RSConstants.TELEMETRY_MAX_SAMPLES_PER_SENDER, requesterHash)
	if (availableSamples == 0) then
		return
	end

	pendingResponses[requesterHash] = { name = requesterName, isGuild = isGuild }

	-- In the second chance all the members that were not chosen wake up at the same time, so they are spread by the members online
	local jitter = RSConstants.TELEMETRY_SYNC_RESPONSE_JITTER
	if (onlyIfUnclaimed) then
		local onlineMembers = (isGuild and select(3, GetNumGuildMembers()) or GetNumGroupMembers()) or 0
		jitter = math.max(jitter, math.min(RSConstants.TELEMETRY_SYNC_SECOND_CHANCE_MAX_JITTER, onlineMembers / 5))
	end
	-- The first half of the time is for the members with more samples, and inside each half the time is random
	local poorness = 1 - math.min(1, availableSamples / RSConstants.TELEMETRY_SYNC_MAX_ITEMS)
	local delay = RSConstants.TELEMETRY_SYNC_RESPONSE_DELAY + (jitter * (0.5 * poorness + 0.5 * math.random()))
	C_Timer.After(delay, function()
		RunProtected(RespondToRequest, requesterHash)
	end)
end

local function ReceiveRequest(requesterHash, requesterName, isGuild)
	RSTelemetryDB.IncreaseStat("syncRequestsReceived")

	-- A player can't ask to the same member too often and we don't answer too many requests
	local now = GetTime()
	if (requestsSeen[requesterHash] and (now - requestsSeen[requesterHash]) < RSConstants.TELEMETRY_SYNC_REQUEST_MEMORY) then
		return
	end
	requestsSeen[requesterHash] = now
	claimedRequests[requesterHash] = nil

	-- The old requests are forgotten
	for hash, time in pairs(requestsSeen) do
		if ((now - time) >= RSConstants.TELEMETRY_SYNC_REQUEST_MEMORY) then
			requestsSeen[hash] = nil
			claimedRequests[hash] = nil
		end
	end

	if (pendingResponses[requesterHash] or CountRecentResponses() >= RSConstants.TELEMETRY_SYNC_MAX_RESPONSES_PER_MINUTE) then
		return
	end

	-- With many members online, each one answers with a probability so only a few of them do it.
	-- The random delay is not enough, because the claims take time to arrive
	local onlineMembers = isGuild and select(3, GetNumGuildMembers()) or GetNumGroupMembers()
	local expectedResponders = RSConstants.TELEMETRY_SYNC_EXPECTED_RESPONDERS
	if (not onlineMembers or onlineMembers < 1 or (onlineMembers > expectedResponders and math.random() > expectedResponders / onlineMembers)) then
		-- Not many of them have the addon, so if nobody has claimed the request after a while, this member answers
		RSTelemetryDB.IncreaseStat("syncRequestsSkipped")
		C_Timer.After(RSConstants.TELEMETRY_SYNC_SECOND_CHANCE_DELAY, function()
			RunProtected(ScheduleResponse, requesterHash, requesterName, isGuild, true)
		end)
		return
	end

	ScheduleResponse(requesterHash, requesterName, isGuild)
end

---============================================================================
-- Receiving items
---============================================================================

-- An optional field can be empty, but if it has something it must be a valid number
local function IsValidOptionalNumber(text, number)
	return (text == nil or text == "" or number ~= nil)
end

local function GetOwnHash()
	return RSTelemetryComm.GetSenderHash(GetUnitName("player", true))
end

local function IsRequestDistribution(distribution)
	return distribution == "GUILD" or distribution == "PARTY" or distribution == "RAID" or distribution == "INSTANCE_CHAT"
end

local function ReceiveItem(sender, text, context)
	local itemType, npcIDText, timeText, field4, field5, field6, field7, field8 = strsplit(",", text)

	-- Requests and claims are only valid in the guild and group channels
	if (itemType == ITEM_REQUEST or itemType == ITEM_CLAIM) then
		if (not IsRequestDistribution(context.distribution)) then
			return
		end

		if (context.isDryRun) then
			RSTelemetryDB.IncreaseStat("loopbackValid")
		elseif (itemType == ITEM_REQUEST) then
			ReceiveRequest(sender, context.senderName, context.distribution == "GUILD")
		elseif (npcIDText) then
			-- The second field of a claim is the hash of the player that asked
			RSTelemetryDB.IncreaseStat("syncClaimsReceived")
			pendingResponses[npcIDText] = nil
			if (requestsSeen[npcIDText]) then
				claimedRequests[npcIDText] = true
			end

			-- If it is for our request, that member is the one that can whisper us the data
			if (npcIDText == GetOwnHash()) then
				answerers[RSTelemetryComm.GetSenderHash(context.senderName)] = GetTime()
			end
		end

		return
	end

	local npcID = ParseNumber(npcIDText)
	local timestamp = ParseNumber(timeText)
	if (not npcID or not timestamp) then
		return
	end

	if (itemType == ITEM_KILL) then
		RSTelemetryDB.IncreaseStat("ignoredLive")
	elseif (itemType == ITEM_SAMPLE) then
		local respawnSeconds = ParseNumber(field4)
		if (not IsValidOptionalNumber(field4, respawnSeconds)) then
			RSTelemetryDB.IncreaseStat("rejectedInvalid")
			return
		end

		-- The sixth field is optional: 1 if the sender was offline between the death and the spawn.
		-- The seventh is also optional: the seconds that he was offline
		-- The eighth is L if the respawn was measured watching, because the sender has the GUIDs obfuscated
		local offlineSeconds = ParseNumber(field7)
		if ((field6 ~= nil and field6 ~= "" and field6 ~= "1") or not IsValidOptionalNumber(field7, offlineSeconds) or (field8 ~= nil and field8 ~= "" and field8 ~= "L")) then
			RSTelemetryDB.IncreaseStat("rejectedInvalid")
			return
		end

		ReceiveSample(sender, npcID, timestamp, respawnSeconds, field5, field6 == "1", offlineSeconds, field8 == "L", context)
	end
end

-- A dry run is used to test the communications with the own messages (DEBUG_TELEMETRY_LOOPBACK).
-- The messages are checked like any other but nothing is saved, so the data can't be corrupted
local function ReceiveMessage(message, sender, isDryRun, distribution)
	-- Data sent directly to us is only accepted as the answer to our request, from a member that announced it
	if (distribution == "WHISPER") then
		if (not IsSyncResponseExpected()) then
			RSTelemetryDB.IncreaseStat("rejectedUnsolicited")
			return
		end

		local announcedAt = answerers[RSTelemetryComm.GetSenderHash(sender)]
		if (not announcedAt or (GetTime() - announcedAt) >= RSConstants.TELEMETRY_SYNC_RECEIVE_WINDOW) then
			RSTelemetryDB.IncreaseStat("rejectedNotAnswerer")
			return
		end
	end

	local items = { strsplit(ITEM_SEPARATOR, message) }
	if (not isDryRun) then
		RSTelemetryDB.IncreaseStat("messagesReceived")
		if (not IsSenderAllowed(sender, #items)) then
			RSTelemetryDB.IncreaseStat("rejectedRateLimit")
			return
		end
		if (not IsGlobalLimitAllowed(#items)) then
			RSTelemetryDB.IncreaseStat("rejectedGlobalLimit")
			return
		end
	end

	-- Only a code of the sender is saved
	local senderHash = RSTelemetryComm.GetSenderHash(sender)
	if (not isDryRun) then
		RSTelemetryDB.AddStatSender(senderHash)
	end

	local context = { senderName = sender, distribution = distribution, isDryRun = isDryRun }
	for _, text in ipairs(items) do
		if (not isDryRun) then
			RSTelemetryDB.IncreaseStat("itemsReceived")
		end
		ReceiveItem(senderHash, text, context)
	end
end

-- Called by AceComm for every message received with our prefix
function RSTelemetryComm:OnCommReceived(prefix, message, distribution, sender)
	if (prefix ~= RSConstants.TELEMETRY_COMM_PREFIX or issecretvalue(message) or issecretvalue(sender)) then
		return
	end
	if (type(message) ~= "string" or type(sender) ~= "string" or not RSConfigDB.IsTelemetryEnabled()) then
		return
	end

	local isOwnMessage = IsOwnMessage(sender)
	if (isOwnMessage and not RSConstants.DEBUG_TELEMETRY_LOOPBACK) then
		RSTelemetryDB.IncreaseStat("ownMessagesIgnored")
		return
	end

	RunProtected(ReceiveMessage, message, sender, isOwnMessage, distribution)
end

---============================================================================
-- Development only (DEBUG_MODE): simulates the answer of another player, to test the synchronization alone
---============================================================================

local SIMULATED_SENDER = "SimPlayer-SimRealm"

function RSTelemetryComm.GetSimulatedSenderHash()
	return RSTelemetryComm.GetSenderHash(SIMULATED_SENDER)
end

--- Four respawns of each NPC arrive by whisper, like the answer of a guild member. Returns the number of samples sent
function RSTelemetryComm.SimulateSyncResponse(npcIDs)
	local now = GetServerTime()
	local texts = {}
	for npcIndex, npcID in ipairs(npcIDs) do
		for index = 1, 4 do
			local spawnTime = now - (npcIndex * 4000) - (index * 900)
			table.insert(texts, string.format("%s,%d,%d,%d,%s", ITEM_SAMPLE, npcID, spawnTime, 400 + (index * 30), UNKNOWN_SHARD))
		end
	end

	-- As if we had asked for them and that member had announced it
	syncRequestTime = GetTime()
	answerers[RSTelemetryComm.GetSenderHash(SIMULATED_SENDER)] = GetTime()
	for _, message in ipairs(BuildMessages(texts)) do
		RSTelemetryComm:OnCommReceived(RSConstants.TELEMETRY_COMM_PREFIX, message, "WHISPER", SIMULATED_SENDER)
	end

	return #texts
end

--- Stops sending and receiving (the player has disabled the telemetry)
function RSTelemetryComm.Disable()
	RSTelemetryComm:UnregisterComm(RSConstants.TELEMETRY_COMM_PREFIX)
	wipe(pendingItems)
	wipe(pendingResponses)
	wipe(answerers)
	wipe(claimedRequests)
	syncRequestTime = nil
end

function RSTelemetryComm.Initialize()
	errorCount = 0
	wasInGroup = false
	RSTelemetryComm:RegisterComm(RSConstants.TELEMETRY_COMM_PREFIX)
	RSTelemetryComm.OnGroupRosterUpdate()

	-- Ask the guild for recent samples once the player has finished loading
	local delay = RSConstants.TELEMETRY_SYNC_START_DELAY + (math.random() * 10)
	C_Timer.After(delay, function()
		RunProtected(RSTelemetryComm.RequestSync)
	end)
end
