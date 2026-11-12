-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSTelemetryDB = private.NewLib("RareScannerTelemetryDB")

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSNpcDB = private.ImportLib("RareScannerNpcDB")

---============================================================================
-- SavedVariables Management (RareScannerDB.global.telemetry)
---============================================================================
-- Structure:
--   telemetry.version
--   telemetry.npcs[npcID]               = { samples }
--   telemetry.recentKills[shardID][npcID] = { timestamp, mapID }
--
-- Sample: { spawnTime, deathTime (optional), mapID, sender (only if it was received from another player), gap (true if the player
-- was offline between the death and the spawn, so the respawn is not used for the estimation), live (true if the respawn was measured
-- watching, because the GUIDs are obfuscated: spawnTime is when the creature was seen for the first time), shard (where the creature was seen,
-- to separate the layers), offline (seconds that the player was offline between the death and the spawn, if any) }
-- All the timestamps are server time (GetServerTime)

local MAX_KILL_CACHE_AGE = RSConstants.TELEMETRY_MAX_RESPAWN_SECONDS
local staleKillsCleaned = false

-- A number that comes from another player can be NaN or infinite, and every comparison with NaN is false
local function IsFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function CleanStaleKills(telemetry)
	local now = GetServerTime()
	for shardID, npcKills in pairs(telemetry.recentKills) do
		for npcID, killData in pairs(npcKills) do
			if (type(killData) ~= "table" or not IsFiniteNumber(killData.timestamp) or (now - killData.timestamp) > MAX_KILL_CACHE_AGE) then
				npcKills[npcID] = nil
			end
		end

		if (next(npcKills) == nil) then
			telemetry.recentKills[shardID] = nil
		end
	end
end

--- With the obfuscated GUIDs a kill of another session of the game can't be paired nor used, so it is removed
local function CleanOtherSessionKills(telemetry)
	for shardID, npcKills in pairs(telemetry.recentKills) do
		for npcID, killData in pairs(npcKills) do
			if (type(killData) ~= "table" or killData.session ~= telemetry.session) then
				npcKills[npcID] = nil
			end
		end

		if (next(npcKills) == nil) then
			telemetry.recentKills[shardID] = nil
		end
	end
end

-- Returns the telemetry table, creating it if it doesn't exist or its version is outdated
local function GetTelemetry()
	if (not private.dbglobal) then
		return nil
	end

	local telemetry = private.dbglobal.telemetry
	if (not telemetry or telemetry.version ~= RSConstants.TELEMETRY_VERSION) then
		telemetry = {
			version = RSConstants.TELEMETRY_VERSION,
			npcs = {},
			recentKills = {},
		}
		private.dbglobal.telemetry = telemetry
	end

	if (not staleKillsCleaned) then
		staleKillsCleaned = true
		CleanStaleKills(telemetry)
	end

	return telemetry
end

---============================================================================
-- Offline time. A respawn measured with the player offline in between can include many cycles
---============================================================================

--- Called when the telemetry starts (login). If the player was offline for a long time, the interval is saved
function RSTelemetryDB.RegisterLogin()
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return
	end

	-- A wrong clock would save a false interval
	local now = GetServerTime()
	if (not IsFiniteNumber(now) or now <= 0) then
		return
	end

	-- The obfuscated values of the GUIDs only last while the game is open, so a long time offline is another session
	if (not IsFiniteNumber(telemetry.lastOnline) or (now - telemetry.lastOnline) >= RSConstants.TELEMETRY_SESSION_BREAK_SECONDS) then
		telemetry.session = (telemetry.session or 0) + 1
		telemetry.seen = {}
		telemetry.seenCount = 0
	end

	CleanOtherSessionKills(telemetry)

	telemetry.offline = telemetry.offline or {}
	if (IsFiniteNumber(telemetry.lastOnline) and telemetry.lastOnline > 0 and (now - telemetry.lastOnline) >= RSConstants.TELEMETRY_OFFLINE_MIN_SECONDS) then
		table.insert(telemetry.offline, { from = telemetry.lastOnline, to = now })
	end

	-- The intervals older than the kills are not needed
	for index = #telemetry.offline, 1, -1 do
		local interval = telemetry.offline[index]
		if (type(interval) ~= "table" or not IsFiniteNumber(interval.to) or (now - interval.to) > MAX_KILL_CACHE_AGE) then
			table.remove(telemetry.offline, index)
		end
	end

	telemetry.lastOnline = now
end

--- Number of the session of the game. It changes when the game is restarted
function RSTelemetryDB.GetSession()
	local telemetry = GetTelemetry()
	return telemetry and telemetry.session or 0
end

--- The player has changed of zone. A respawn measured watching is not reliable if the player left the zone in between
function RSTelemetryDB.MarkZoneChange()
	local telemetry = GetTelemetry()
	if (telemetry) then
		telemetry.zoneChangedAt = GetServerTime()
	end
end

function RSTelemetryDB.GetZoneChangedAt()
	local telemetry = GetTelemetry()
	return telemetry and telemetry.zoneChangedAt or 0
end

--- Creatures already seen in this session. With the obfuscated GUIDs it is the only way to know that a creature is new
function RSTelemetryDB.IsGuidSeen(guid)
	local telemetry = GetTelemetry()
	return telemetry ~= nil and telemetry.seen ~= nil and telemetry.seen[guid] == true
end

function RSTelemetryDB.SetGuidSeen(guid)
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return
	end

	telemetry.seen = telemetry.seen or {}
	if (telemetry.seen[guid]) then
		return
	end

	if ((telemetry.seenCount or 0) >= RSConstants.TELEMETRY_MAX_SEEN_GUIDS) then
		telemetry.seen = {}
		telemetry.seenCount = 0
	end
	telemetry.seen[guid] = true
	telemetry.seenCount = (telemetry.seenCount or 0) + 1
end

function RSTelemetryDB.UpdateLastOnline()
	local telemetry = GetTelemetry()
	local now = GetServerTime()
	if (telemetry and IsFiniteNumber(now) and now > 0) then
		telemetry.lastOnline = now
	end
end

--- Returns true if the respawn between the two times is not reliable because the player was offline: a long time
-- or at least a part of the respawn (offline for half of it means that a whole cycle could have been missed).
-- It also returns the seconds that the player was offline
function RSTelemetryDB.HasOfflineGap(fromTime, toTime)
	local telemetry = GetTelemetry()
	if (not telemetry or type(telemetry.offline) ~= "table") then
		return false, 0
	end

	local offlineSeconds = 0
	for _, interval in ipairs(telemetry.offline) do
		if (type(interval) == "table" and IsFiniteNumber(interval.from) and IsFiniteNumber(interval.to)) then
			offlineSeconds = offlineSeconds + math.max(0, math.min(toTime, interval.to) - math.max(fromTime, interval.from))
		end
	end

	offlineSeconds = math.floor(offlineSeconds)
	local isGap = offlineSeconds >= RSConstants.TELEMETRY_OFFLINE_GAP_SECONDS or (offlineSeconds > 0 and offlineSeconds >= (toTime - fromTime) * RSConstants.TELEMETRY_OFFLINE_GAP_RATIO)
	return isGap, offlineSeconds
end

---============================================================================
-- Kills (shared across account/characters)
---============================================================================

--- There is a limit of kills saved, so the oldest one is removed to make room for a new one
local function RemoveOldestKillIfFull(telemetry)
	local killsCount = 0
	local oldest = {}
	for shardID, npcKills in pairs(telemetry.recentKills) do
		for npcID, killData in pairs(npcKills) do
			killsCount = killsCount + 1
			if (not oldest.timestamp or killData.timestamp < oldest.timestamp) then
				oldest = { shardID = shardID, npcID = npcID, timestamp = killData.timestamp }
			end
		end
	end

	if (killsCount >= RSConstants.TELEMETRY_MAX_RECENT_KILLS and oldest.timestamp) then
		telemetry.recentKills[oldest.shardID][oldest.npcID] = nil
		if (next(telemetry.recentKills[oldest.shardID]) == nil) then
			telemetry.recentKills[oldest.shardID] = nil
		end
	end
end

function RSTelemetryDB.SetKill(shardID, npcID, timestamp, mapID, session)
	local telemetry = GetTelemetry()
	if (not telemetry or not shardID or not npcID) then
		return
	end

	if (not timestamp) then
		local shardKills = telemetry.recentKills[shardID]
		if (shardKills) then
			shardKills[npcID] = nil

			-- An empty shard is removed, because there is a new one for each zone and session
			if (next(shardKills) == nil) then
				telemetry.recentKills[shardID] = nil
			end
		end

		return
	end

	if (not (telemetry.recentKills[shardID] and telemetry.recentKills[shardID][npcID])) then
		RemoveOldestKillIfFull(telemetry)
	end

	if (not telemetry.recentKills[shardID]) then
		telemetry.recentKills[shardID] = {}
	end

	telemetry.recentKills[shardID][npcID] = {
		timestamp = timestamp,
		mapID = mapID,
		session = session,
	}
end

function RSTelemetryDB.GetKill(shardID, npcID)
	local telemetry = GetTelemetry()
	if (not telemetry or not shardID or not npcID or not telemetry.recentKills[shardID]) then
		return nil
	end

	local killData = telemetry.recentKills[shardID][npcID]
	if (killData and killData.timestamp and (GetServerTime() - killData.timestamp) <= MAX_KILL_CACHE_AGE) then
		-- With the obfuscated GUIDs the shard of another session of the game means nothing, even if it looks the same
		if (killData.session ~= telemetry.session) then
			return nil
		end

		return killData
	end

	return nil
end

--- Returns the kill that matches the shard where the player is.
-- Shards are different for each zone, so they only can be compared if the player is in the zone
-- where the NPC died. In any other zone the shard of the player is unknown and the most recent kill is returned
function RSTelemetryDB.GetLastKill(npcID, currentShardID, currentMapID)
	local telemetry = GetTelemetry()
	if (not telemetry or not npcID) then
		return nil
	end

	local currentShardKill = currentShardID and RSTelemetryDB.GetKill(currentShardID, npcID)
	if (currentShardKill) then
		return currentShardKill
	end

	local lastKill = nil
	for shardID in pairs(telemetry.recentKills) do
		local killData = RSTelemetryDB.GetKill(shardID, npcID)

		-- A kill in this zone with a different shard is a kill in another layer
		local isOtherLayer = (currentShardID and killData and killData.mapID == currentMapID)
		if (killData and not isOtherLayer and (not lastKill or killData.timestamp > lastKill.timestamp)) then
			lastKill = killData
		end
	end

	return lastKill
end

-- A shard is "serverID-instanceID-zoneUID"
function RSTelemetryDB.IsValidShardID(shardID)
	return (type(shardID) == "string" and #shardID <= 32 and string.match(shardID, "^%d+%-%d+%-%d+$") ~= nil)
end

function RSTelemetryDB.ClearKill(shardID, npcID)
	RSTelemetryDB.SetKill(shardID, npcID, nil, nil)
end

---============================================================================
-- Samples
---============================================================================

-- Checks the format of a sample and that its respawn is possible, no matter when it was saved
local function IsValidSampleFormat(npcID, sample)
	if (not npcID or type(sample) ~= "table" or not RSNpcDB.GetInternalNpcInfo(npcID)) then
		return false
	end

	if (sample.sender ~= nil and (type(sample.sender) ~= "string" or #sample.sender > 40)) then
		return false
	end

	if (sample.gap ~= nil and sample.gap ~= true) then
		return false
	end

	if (sample.live ~= nil and sample.live ~= true) then
		return false
	end

	if (sample.shard ~= nil and not RSTelemetryDB.IsValidShardID(sample.shard)) then
		return false
	end

	if (sample.offline ~= nil and (not IsFiniteNumber(sample.offline) or sample.offline <= 0 or sample.offline ~= math.floor(sample.offline) or sample.offline > RSConstants.TELEMETRY_MAX_RESPAWN_SECONDS)) then
		return false
	end

	if (not IsFiniteNumber(sample.spawnTime) or sample.spawnTime <= 0) then
		return false
	end

	if (sample.mapID ~= nil and not IsFiniteNumber(sample.mapID)) then
		return false
	end

	if (sample.deathTime ~= nil) then
		if (not IsFiniteNumber(sample.deathTime)) then
			return false
		end

		local respawnSeconds = sample.spawnTime - sample.deathTime
		if (respawnSeconds < RSConstants.TELEMETRY_MIN_RESPAWN_SECONDS or respawnSeconds > RSConstants.TELEMETRY_MAX_RESPAWN_SECONDS) then
			return false
		end
	end

	return true
end

--- If the database has the respawn of the NPC, the samples that are very far from it are discarded
local function IsPlausibleRespawn(npcID, sample)
	if (not sample.deathTime) then
		return true
	end

	local minRespawn, maxRespawn = RSNpcDB.GetNpcRespawnRange(npcID)
	local respawnSeconds = sample.spawnTime - sample.deathTime
	local tolerance = RSConstants.TELEMETRY_STATIC_TOLERANCE_FACTOR

	-- The database can have only one of the limits
	if (minRespawn and respawnSeconds < minRespawn / tolerance) then
		return false
	end

	return not (maxRespawn and respawnSeconds > maxRespawn * tolerance)
end

--- Returns the reason why a new sample is not valid, or nil if it is valid
local function GetSampleRejectionReason(npcID, sample)
	if (not IsValidSampleFormat(npcID, sample)) then
		-- The respawn out of the limits is the most common case, so it has its own reason (for the statistics)
		if (type(sample) == "table" and IsFiniteNumber(sample.spawnTime) and IsFiniteNumber(sample.deathTime)) then
			local respawnSeconds = sample.spawnTime - sample.deathTime
			if (respawnSeconds < RSConstants.TELEMETRY_MIN_RESPAWN_SECONDS) then
				return "respawnTooShort"
			elseif (respawnSeconds > RSConstants.TELEMETRY_MAX_RESPAWN_SECONDS) then
				return "respawnTooLong"
			end
		end

		return "format"
	end

	if (not IsPlausibleRespawn(npcID, sample)) then
		return "implausible"
	end

	local now = GetServerTime()
	if (sample.spawnTime > now + RSConstants.TELEMETRY_CLOCK_TOLERANCE_SECONDS) then
		return "future"
	end

	return nil
end

-- Checks that a new sample is coherent. Samples received from other players must pass this too
function RSTelemetryDB.IsValidSample(npcID, sample)
	return GetSampleRejectionReason(npcID, sample) == nil
end

-- Samples without death time are less valuable (they can't measure a respawn), and the marked ones are not used in the game,
-- so they are removed first. The live ones are only an upper limit, so the exact ones of before are never replaced by them
local function RemoveOldestSample(npcSamples)
	for index, sample in ipairs(npcSamples) do
		if (not sample.deathTime) then
			table.remove(npcSamples, index)
			return
		end
	end

	for index, sample in ipairs(npcSamples) do
		if (sample.gap) then
			table.remove(npcSamples, index)
			return
		end
	end

	for index, sample in ipairs(npcSamples) do
		if (sample.live) then
			table.remove(npcSamples, index)
			return
		end
	end

	table.remove(npcSamples, 1)
end

-- Returns true if the sample was added, or false and the reason (format, respawnTooShort, respawnTooLong, implausible, future, duplicate, senderLimit)
function RSTelemetryDB.AddSample(npcID, sample)
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return false, "noTelemetry"
	end

	local rejectionReason = GetSampleRejectionReason(npcID, sample)
	if (rejectionReason) then
		return false, rejectionReason
	end

	local npcData = telemetry.npcs[npcID]
	if (not npcData) then
		npcData = { samples = {} }
		telemetry.npcs[npcID] = npcData
	end

	-- A sample is identified by its spawn time. A player can't fill the samples of a NPC with his own data
	local npcSamples = npcData.samples
	local senderSamples = 0
	for _, savedSample in ipairs(npcSamples) do
		if (savedSample.spawnTime == sample.spawnTime) then
			return false, "duplicate"
		end
		if (sample.sender and savedSample.sender == sample.sender) then
			senderSamples = senderSamples + 1
		end
	end
	if (senderSamples >= RSConstants.TELEMETRY_MAX_SAMPLES_PER_SENDER_SAVED) then
		return false, "senderLimit"
	end

	table.insert(npcSamples, {
		spawnTime = sample.spawnTime,
		deathTime = sample.deathTime,
		mapID = sample.mapID,
		sender = sample.sender,
		gap = sample.gap,
		shard = sample.shard,
		offline = sample.offline,
		live = sample.live,
	})
	if (sample.gap) then
		RSTelemetryDB.IncreaseStat("samplesWithGap")
	end

	-- In debug mode all the samples are kept, to build the data of the database
	if (not RSConstants.DEBUG_MODE and #npcSamples > RSConstants.TELEMETRY_MAX_SAMPLES_PER_NPC) then
		RemoveOldestSample(npcSamples)
	end

	return true
end

function RSTelemetryDB.GetNpcData(npcID)
	local telemetry = GetTelemetry()
	if (not telemetry or not npcID) then
		return nil
	end

	return telemetry.npcs[npcID]
end

function RSTelemetryDB.GetTelemetryNpcCount()
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return 0
	end

	local count = 0
	for _ in pairs(telemetry.npcs) do
		count = count + 1
	end

	return count
end

--- Returns when the guild was asked for data for the last time, and which guild it was
function RSTelemetryDB.GetLastSyncRequest()
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return 0, nil
	end

	return telemetry.lastSyncRequest or 0, telemetry.lastSyncGuild
end

function RSTelemetryDB.SetLastSyncRequest(timestamp, guildName)
	local telemetry = GetTelemetry()
	if (telemetry) then
		telemetry.lastSyncRequest = timestamp
		telemetry.lastSyncGuild = guildName
	end
end

local function IsBetterSample(sample, otherSample)
	if (sample.gap ~= otherSample.gap) then
		return not sample.gap
	end

	return sample.spawnTime > otherSample.spawnTime
end

--- Returns the newest respawns measured, as a list of { npcID, sample }. It doesn't matter if they were measured by
-- this player or received from others. A NPC can't have more than maxPerNpc samples in the list, so there is variety,
-- and the samples received from excludedSender are not included
function RSTelemetryDB.GetRecentRespawnSamples(maxCount, maxPerNpc, excludedSender)
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return {}
	end

	-- Only the newest samples of each NPC can be in the list, so the rest are not sorted (there can be thousands)
	local allSamples = {}
	for npcID, npcData in pairs(telemetry.npcs) do
		local newestSamples = {}
		for _, sample in ipairs(npcData.samples) do
			if (sample.deathTime and (not excludedSender or sample.sender ~= excludedSender)) then
				-- The samples that are not marked go first, then the newest ones
				local position = #newestSamples + 1
				while (position > 1 and IsBetterSample(sample, newestSamples[position - 1])) do
					position = position - 1
				end

				if (position <= maxPerNpc) then
					table.insert(newestSamples, position, sample)
					newestSamples[maxPerNpc + 1] = nil
				end
			end
		end

		for _, sample in ipairs(newestSamples) do
			table.insert(allSamples, { npcID = npcID, sample = sample })
		end
	end

	table.sort(allSamples, function(a, b)
		return a.sample.spawnTime > b.sample.spawnTime
	end)

	local recentSamples = {}
	for _, npcSample in ipairs(allSamples) do
		if (#recentSamples >= maxCount) then
			break
		end

		table.insert(recentSamples, npcSample)
	end

	return recentSamples
end

--- Removes all the samples received from a sender. Used to clean the simulated ones
function RSTelemetryDB.RemoveSamplesBySender(senderHash)
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return 0
	end

	local removedCount = 0
	for npcID, npcData in pairs(telemetry.npcs) do
		for index = #npcData.samples, 1, -1 do
			if (npcData.samples[index].sender == senderHash) then
				table.remove(npcData.samples, index)
				removedCount = removedCount + 1
			end
		end

		if (#npcData.samples == 0) then
			telemetry.npcs[npcID] = nil
		end
	end

	return removedCount
end

--- Returns a copy of the list, because the routines that go through it take several frames and new NPCs can be added meanwhile
function RSTelemetryDB.GetAllTelemetryNpcs()
	local telemetry = GetTelemetry()
	local npcs = {}
	if (telemetry) then
		for npcID, npcData in pairs(telemetry.npcs) do
			npcs[npcID] = npcData
		end
	end

	return npcs
end

function RSTelemetryDB.RemoveNpc(npcID)
	local telemetry = GetTelemetry()
	if (telemetry) then
		telemetry.npcs[npcID] = nil
	end
end

--- Removes the samples that are not valid anymore (the rules or the NPC database could have changed)
function RSTelemetryDB.CleanNpcData(npcID)
	local telemetry = GetTelemetry()
	local npcData = telemetry and telemetry.npcs[npcID]
	if (not npcData) then
		return
	end

	-- Fields of old versions that are not used anymore
	npcData.respawnCount, npcData.lastRespawn, npcData.minRespawn, npcData.maxRespawn = nil, nil, nil, nil

	for index = #npcData.samples, 1, -1 do
		local sample = npcData.samples[index]
		sample.id = nil
		if (not IsValidSampleFormat(npcID, sample) or not IsPlausibleRespawn(npcID, sample)) then
			table.remove(npcData.samples, index)
		end
	end

	if (#npcData.samples == 0) then
		telemetry.npcs[npcID] = nil
	end
end

---============================================================================
-- Development only (DEBUG_MODE): statistics and proposals for the spawn info database
---============================================================================

function RSTelemetryDB.IncreaseStat(statName, amount)
	local telemetry = RSConstants.DEBUG_MODE and GetTelemetry()
	if (not telemetry) then
		return
	end

	telemetry.stats = telemetry.stats or {}
	telemetry.stats[statName] = (telemetry.stats[statName] or 0) + (amount or 1)
end

function RSTelemetryDB.AddStatSender(senderHash)
	local telemetry = RSConstants.DEBUG_MODE and GetTelemetry()
	if (not telemetry) then
		return
	end

	telemetry.statSenders = telemetry.statSenders or {}
	telemetry.statSenders[senderHash] = true
end

function RSTelemetryDB.ResetStats()
	local telemetry = GetTelemetry()
	if (telemetry) then
		telemetry.stats = nil
		telemetry.statSenders = nil
	end
end

--- Returns the statistics and the number of different senders
function RSTelemetryDB.GetStats()
	local telemetry = GetTelemetry()
	if (not telemetry) then
		return {}, 0
	end

	local sendersCount = 0
	for _ in pairs(telemetry.statSenders or {}) do
		sendersCount = sendersCount + 1
	end

	return telemetry.stats or {}, sendersCount
end

function RSTelemetryDB.ResetProposals()
	local telemetry = RSConstants.DEBUG_MODE and GetTelemetry()
	if (telemetry) then
		telemetry.proposals = {}
	end
end

function RSTelemetryDB.SetProposal(npcID, line)
	local telemetry = RSConstants.DEBUG_MODE and GetTelemetry()
	if (telemetry) then
		telemetry.proposals = telemetry.proposals or {}
		telemetry.proposals[npcID] = line
	end
end

function RSTelemetryDB.GetProposals()
	local telemetry = GetTelemetry()
	return telemetry and telemetry.proposals or {}
end

function RSTelemetryDB.ResetTelemetry()
	if (private.dbglobal) then
		private.dbglobal.telemetry = nil
	end
end
