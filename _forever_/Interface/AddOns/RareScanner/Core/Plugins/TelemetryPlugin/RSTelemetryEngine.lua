-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSTelemetryEngine = private.NewLib("RareScannerTelemetryEngine")

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSLogger = private.ImportLib("RareScannerLogger")
local RSTelemetryDB = private.ImportLib("RareScannerTelemetryDB")
local RSTelemetryComm = private.ImportLib("RareScannerTelemetryComm")
local RSNpcDB = private.ImportLib("RareScannerNpcDB")

---============================================================================
-- Helpers & GUID Parsing
---============================================================================

--- Checks whether a given GUID belongs to a real in-game creature instance
-- Returns: isValid, npcID, shardID, spawnUID
-- The shardID combines serverID, instanceID and zoneUID, so two different shards are never mixed
function RSTelemetryEngine.ParseCreatureGUID(guid)
	-- A secret value is checked first, because it can't be used in a condition
	if (issecretvalue(guid) or type(guid) ~= "string") then
		return false
	end

	-- Expected real GUID structure: "Creature-0-serverID-instanceID-zoneUID-npcID-spawnUID"
	-- Simulated GUIDs (e.g. "a-a-a-a-a-...") are rejected here
	local unitType, _, serverID, instanceID, zoneUID, npcIDStr, spawnUID = strsplit("-", guid)
	if (unitType ~= "Creature" and unitType ~= "Vehicle") then
		return false
	end

	local npcID = tonumber(npcIDStr)
	if (not npcID or not tonumber(serverID) or not tonumber(instanceID) or not tonumber(zoneUID) or not spawnUID or spawnUID == "") then
		return false
	end

	return true, npcID, string.format("%s-%s-%s", serverID, instanceID, zoneUID), spawnUID
end

--- A respawn much longer than the maximum known means that the NPC spawned and died again before it was seen
function RSTelemetryEngine.IsRespawnTooLong(npcID, respawnSeconds)
	local estimate = RSTelemetryEngine.GetEstimatedRespawn(npcID)
	if (not estimate or not estimate.maxRespawn) then
		return false
	end

	local isReliable = (estimate.hasStaticRange or estimate.respawnSamples >= RSConstants.TELEMETRY_MIN_SAMPLES_RELIABLE)
	return isReliable and respawnSeconds > estimate.maxRespawn * RSConstants.TELEMETRY_STALE_RESPAWN_FACTOR
end

-- Shard where the player is, taken from the GUID of the creatures around (RAM only)
local currentShardID = nil

local lastShardUpdateTime = 0

function RSTelemetryEngine.UpdateCurrentShard(guid)
	-- Nameplates and mouseover fire many times per second, and the shard only changes when the player changes of zone
	local now = GetTime()
	if (now - lastShardUpdateTime < RSConstants.TELEMETRY_SHARD_UPDATE_SECONDS) then
		return
	end
	lastShardUpdateTime = now

	local isValid, _, shardID = RSTelemetryEngine.ParseCreatureGUID(guid)
	if (isValid) then
		currentShardID = shardID
	end
end

---============================================================================
-- Event Recording
---============================================================================

function RSTelemetryEngine.RecordDeath(npcID, guid, mapID)
	local isValid, parsedNpcID, shardID = RSTelemetryEngine.ParseCreatureGUID(guid)
	if (not isValid) then
		RSLogger:PrintTelemetryDebugMessage(string.format("Muerte descartada (GUID no válido o simulado: %s)", tostring(guid)))
		return
	end

	npcID = parsedNpcID
	local now = GetServerTime()
	mapID = mapID or C_Map.GetBestMapForUnit("player")

	-- Without the spawn time in the GUID the death is only useful for this player, in this session
	RSTelemetryDB.SetGuidSeen(guid)
	RSTelemetryDB.SetKill(shardID, npcID, now, mapID, RSTelemetryDB.GetSession())
	RSLogger:PrintTelemetryDebugMessage(string.format("Muerte registrada: NPC [%s] | Hora: %s", npcID, date("%H:%M:%S", now)))
end

-- Called for any tracking system that provides the creature GUID (vignettes, nameplates, mouseover...)
-- GUIDs already seen in this session (RAM only), so the same creature is not parsed every time it is detected
local seenGuids = {}

--- Measures the respawn watching: without the spawn time in the GUID, a creature that was not seen before the kill and is seen
--- after it in the same session is the respawn, and the time that it took to see it is the upper limit of the respawn
local function RecordSightingLive(npcID, guid, shardID, mapID)
	local wasSeen = RSTelemetryDB.IsGuidSeen(guid)
	RSTelemetryDB.SetGuidSeen(guid)
	if (wasSeen) then
		RSTelemetryDB.IncreaseStat("liveSeenBefore")
		return
	end

	local lastKill = RSTelemetryDB.GetKill(shardID, npcID)
	if (not lastKill) then
		return
	end

	local now = GetServerTime()
	RSTelemetryDB.ClearKill(shardID, npcID)
	if (now <= lastKill.timestamp or RSTelemetryEngine.IsRespawnTooLong(npcID, now - lastKill.timestamp)) then
		RSTelemetryDB.IncreaseStat("liveUnpaired")
		return
	end

	-- The respawn is not reliable if the player was offline, or left the zone, between the death and the creature
	local isGap, offlineSeconds = RSTelemetryDB.HasOfflineGap(lastKill.timestamp, now)
	local sample = {
		spawnTime = now,
		deathTime = lastKill.timestamp,
		mapID = mapID or C_Map.GetBestMapForUnit("player"),
		live = true,
		gap = (isGap or RSTelemetryDB.GetZoneChangedAt() > lastKill.timestamp) or nil,
		offline = offlineSeconds > 0 and offlineSeconds or nil,
	}

	local isAdded, rejectionReason = RSTelemetryDB.AddSample(npcID, sample)
	if (isAdded) then
		RSTelemetryDB.IncreaseStat("respawnsMeasured")
		RSTelemetryComm.SendSample(npcID, sample, shardID)
		RSLogger:PrintTelemetryDebugMessage(string.format("Respawn medido: NPC [%s]. Intervalo: %s seg%s.", npcID, now - lastKill.timestamp, sample.gap and " (no fiable)" or ""))
	else
		RSTelemetryDB.IncreaseStat("creaturesRejected")
		RSTelemetryDB.IncreaseStat("creaturesRejected_"..rejectionReason)
	end
end

function RSTelemetryEngine.RecordSighting(npcID, guid, mapID)
	if (issecretvalue(guid) or type(guid) ~= "string") then
		RSTelemetryDB.IncreaseStat("sightingsInvalidGuid")
		return
	end
	if (seenGuids[guid]) then
		RSTelemetryDB.IncreaseStat("sightingsRepeated")
		return
	end

	local isValid, parsedNpcID, shardID = RSTelemetryEngine.ParseCreatureGUID(guid)
	if (not isValid) then
		RSTelemetryDB.IncreaseStat("sightingsInvalidGuid")
		return
	end

	seenGuids[guid] = true
	RecordSightingLive(parsedNpcID, guid, shardID, mapID)
end

---============================================================================
-- Query helper
---============================================================================

--- Retrieves current realm server time and date
local function GetServerDateTime()
	local cal = C_DateAndTime.GetCurrentCalendarTime()
	local serverTime = GetServerTime and GetServerTime() or time()
	local curSec = serverTime % 60
	local curMin = cal and cal.minute or (math.floor(serverTime / 60) % 60)
	local curHour = cal and cal.hour or (math.floor(serverTime / 3600) % 24)
	local curWeekday = cal and cal.weekday or 1

	return curWeekday, curHour, curMin, curSec, serverTime
end

--- Normalizes schedule configuration into target lists
-- Returns targetMinutes, targetHours, targetWeekdays
local function NormalizeScheduleConfig(schedule)
	if (schedule == nil) then
		return nil
	end

	local targetMinutes = nil
	local targetHours = nil
	local targetWeekdays = nil

	if (type(schedule) == "number") then
		if (schedule == 0 or schedule == 60) then
			targetMinutes = { 0 }
		elseif (schedule > 0 and schedule <= 30 and (60 % schedule == 0)) then
			targetMinutes = {}
			for m = 0, 59, schedule do
				table.insert(targetMinutes, m)
			end
		elseif (schedule > 0 and schedule < 60) then
			targetMinutes = { schedule }
		else
			return nil
		end
	elseif (type(schedule) == "table") then
		-- Simple sequence of numbers { 0, 15, 30, 45 } or { 10, 40 }
		if (#schedule > 0 or schedule[1] ~= nil) then
			targetMinutes = {}
			for _, m in ipairs(schedule) do
				if (type(m) == "number" and m >= 0 and m < 60) then
					table.insert(targetMinutes, m)
				end
			end
			if (#targetMinutes == 0) then
				return nil
			end
			table.sort(targetMinutes)
		else
			-- Structured table: { minutes = ..., hours = ..., weekdays = ..., period = ... }
			if (schedule.period and type(schedule.period) == "number" and schedule.period > 0 and schedule.period <= 60) then
				targetMinutes = {}
				for m = 0, 59, schedule.period do
					table.insert(targetMinutes, m)
				end
			elseif (schedule.minutes or schedule.minute) then
				local mins = schedule.minutes or schedule.minute
				if (type(mins) == "table") then
					targetMinutes = {}
					for _, m in ipairs(mins) do
						table.insert(targetMinutes, m)
					end
					table.sort(targetMinutes)
				elseif (type(mins) == "number") then
					targetMinutes = { mins }
				end
			else
				targetMinutes = { 0 }
			end

			if (schedule.hours or schedule.hour) then
				local hrs = schedule.hours or schedule.hour
				if (type(hrs) == "table") then
					targetHours = {}
					for _, h in ipairs(hrs) do
						table.insert(targetHours, h)
					end
					table.sort(targetHours)
				elseif (type(hrs) == "number") then
					targetHours = { hrs }
				end
			end

			if (schedule.weekdays or schedule.weekday) then
				local wds = schedule.weekdays or schedule.weekday
				if (type(wds) == "table") then
					targetWeekdays = {}
					for _, w in ipairs(wds) do
						table.insert(targetWeekdays, w)
					end
					table.sort(targetWeekdays)
				elseif (type(wds) == "number") then
					targetWeekdays = { wds }
				end
			end
		end
	else
		return nil
	end

	return targetMinutes, targetHours, targetWeekdays
end

local function ListContains(list, value)
	if (not list) then
		return true
	end
	for _, v in ipairs(list) do
		if (v == value) then
			return true
		end
	end
	return false
end

--- Calculates seconds until next clock-aligned spawn given a schedule configuration using server time
local function CalculateSecondsUntilNextSchedule(schedule)
	local targetMinutes, targetHours, targetWeekdays = NormalizeScheduleConfig(schedule)
	if (not targetMinutes or #targetMinutes == 0) then
		return nil
	end

	local curWeekday, curHour, curMin, curSec = GetServerDateTime()

	-- Fast path for standard hourly schedules (no explicit server hours or weekdays specified)
	if (not targetHours and not targetWeekdays) then
		local nextMinute = nil
		for _, m in ipairs(targetMinutes) do
			if (m > curMin or (m == curMin and curSec == 0)) then
				nextMinute = m
				break
			end
		end

		local minDiff = 0
		local nextHour = curHour
		if (nextMinute ~= nil) then
			minDiff = nextMinute - curMin
		else
			nextMinute = targetMinutes[1]
			minDiff = (60 - curMin) + nextMinute
			nextHour = (curHour + 1) % 24
		end

		local secondsUntilNext = (minDiff * 60) - curSec
		if (secondsUntilNext < 0) then
			secondsUntilNext = 0
		end

		local nextClockStr = string.format("%02d:%02d", nextHour, nextMinute)
		return secondsUntilNext, nextClockStr
	end

	-- Comprehensive search across upcoming hours (up to 7 days = 168 hours)
	for hourOffset = 0, 168 do
		local candHour = (curHour + hourOffset) % 24
		local dayOffset = math.floor((curHour + hourOffset) / 24)
		local candWeekday = ((curWeekday - 1 + dayOffset) % 7) + 1

		if (ListContains(targetWeekdays, candWeekday) and ListContains(targetHours, candHour)) then
			for _, m in ipairs(targetMinutes) do
				if (hourOffset > 0 or (m > curMin or (m == curMin and curSec == 0))) then
					local totalMinutes = (hourOffset * 60) + (m - curMin)
					local secondsUntilNext = (totalMinutes * 60) - curSec
					if (secondsUntilNext < 0) then
						secondsUntilNext = 0
					end
					local nextClockStr = string.format("%02d:%02d", candHour, m)
					return secondsUntilNext, nextClockStr
				end
			end
		end
	end

	return nil
end

local function GetMinuteOfHour(timestamp)
	return math.floor(timestamp / 60) % 60
end

--- Groups the spawn minutes in clusters (a minute and its two neighbours to tolerate small delays),
-- taking the biggest ones first until most of the samples are covered.
-- Server timezones are whole hours, so the minute of the UTC timestamp is the server minute
-- Returns the central minute of each cluster and the number of samples covered
local function GetMinuteClusters(samples)
	local minuteCounts = {}
	for _, sample in ipairs(samples) do
		local minute = GetMinuteOfHour(sample.spawnTime)
		minuteCounts[minute] = (minuteCounts[minute] or 0) + 1
	end

	local clusterCenters = {}
	local claimedMinutes = {}
	local coveredSamples = 0
	while (#clusterCenters < RSConstants.TELEMETRY_MAX_SCHEDULE_MINUTES and coveredSamples / #samples < RSConstants.TELEMETRY_SCHEDULE_MATCH_RATIO) do
		local bestCenter, bestCount, bestOwnCount = nil, 0, 0
		for minute = 0, 59 do
			if (not claimedMinutes[minute]) then
				local ownCount = minuteCounts[minute] or 0
				local nearbyCount = ownCount
				local previousMinute = (minute - 1) % 60
				local nextMinute = (minute + 1) % 60
				if (not claimedMinutes[previousMinute]) then
					nearbyCount = nearbyCount + (minuteCounts[previousMinute] or 0)
				end
				if (not claimedMinutes[nextMinute]) then
					nearbyCount = nearbyCount + (minuteCounts[nextMinute] or 0)
				end

				-- On a tie, the minute with more samples of its own wins
				if (nearbyCount > bestCount or (nearbyCount == bestCount and ownCount > bestOwnCount)) then
					bestCenter = minute
					bestCount = nearbyCount
					bestOwnCount = ownCount
				end
			end
		end

		if (not bestCenter) then
			break
		end

		table.insert(clusterCenters, bestCenter)
		coveredSamples = coveredSamples + bestCount
		for offset = -1, 1 do
			claimedMinutes[(bestCenter + offset) % 60] = true
		end
	end

	return clusterCenters, coveredSamples
end

--- Looks for the minutes of the hour (for example :00 and :30) where most of the spawns happen.
-- Returns a schedule like { minutes = { 0, 30 } }, or nil if there is no clear pattern
local function GetLearnedMinutesSchedule(samples)
	if (#samples < RSConstants.TELEMETRY_MIN_SAMPLES_SCHEDULE) then
		return nil
	end

	local clusterCenters, coveredSamples = GetMinuteClusters(samples)

	-- Most of the samples must fit in the clusters. The more clusters there are, the easier it is to find them
	-- by coincidence, so more samples are needed (3 for 1 minute, 8 for 2, 15 for 3, 24 for 4...)
	local minSamples = #clusterCenters * (#clusterCenters + 2)
	if (coveredSamples / #samples < RSConstants.TELEMETRY_SCHEDULE_MATCH_RATIO or #samples < minSamples) then
		return nil
	end

	table.sort(clusterCenters)

	return { minutes = clusterCenters }
end

-- Periods (in minutes) that divide the hour. The biggest go first because a 30 minutes schedule also fits in a 15 minutes one
local SCHEDULE_PERIODS = { 30, 20, 15 }

--- Looks for NPCs that spawn every N minutes of the server clock (for example every 15 minutes).
-- It needs fewer samples than looking for every minute separately
local function GetLearnedPeriodSchedule(samples)
	if (#samples < RSConstants.TELEMETRY_MIN_SAMPLES_PERIOD) then
		return nil
	end

	for _, period in ipairs(SCHEDULE_PERIODS) do
		-- Spawns of different hours fall in the same minute when the minute is folded by the period
		local residueCounts = {}
		for _, sample in ipairs(samples) do
			local residue = GetMinuteOfHour(sample.spawnTime) % period
			residueCounts[residue] = (residueCounts[residue] or 0) + 1
		end

		local bestResidue, bestCount, bestOwnCount = nil, 0, 0
		for residue = 0, period - 1 do
			local ownCount = residueCounts[residue] or 0
			local nearbyCount = (residueCounts[(residue - 1) % period] or 0) + ownCount + (residueCounts[(residue + 1) % period] or 0)
			if (nearbyCount > bestCount or (nearbyCount == bestCount and ownCount > bestOwnCount)) then
				bestResidue = residue
				bestCount = nearbyCount
				bestOwnCount = ownCount
			end
		end

		if (bestCount / #samples >= RSConstants.TELEMETRY_SCHEDULE_MATCH_RATIO) then
			local minutes = {}
			for minute = bestResidue, 59, period do
				table.insert(minutes, minute)
			end
			return { minutes = minutes }
		end
	end

	return nil
end

--- Returns the schedule learned from the spawn times, or nil if there is no clear pattern
local function GetLearnedSchedule(samples)
	return GetLearnedMinutesSchedule(samples) or GetLearnedPeriodSchedule(samples)
end

--- Returns the min and max respawn of the samples, the number of respawns measured and the last one.
-- The highest values are ignored when they are far from the median, so a wrong sample doesn't distort the range
local function GetObservedRespawns(samples)
	local respawns = {}
	local lastRespawn, lastSpawnTime = nil, nil
	for _, sample in ipairs(samples) do
		-- A respawn measured with the player offline in between is not reliable, and a live one is only an upper limit
		-- (a layer jump can also create a false one), so it is only saved and exported until it is validated
		if (sample.deathTime and not sample.gap and not sample.live) then
			table.insert(respawns, sample.spawnTime - sample.deathTime)

			-- The samples are not always in order (the ones received can arrive late)
			if (not lastSpawnTime or sample.spawnTime > lastSpawnTime) then
				lastSpawnTime = sample.spawnTime
				lastRespawn = sample.spawnTime - sample.deathTime
			end
		end
	end

	if (#respawns == 0) then
		return nil, nil, 0, nil
	end

	table.sort(respawns)
	-- The maximum is the value that fails: the errors of pairing make the respawn longer, never shorter.
	-- With enough samples, the ones that are far above the median are ignored
	local firstIndex = 1
	local maxRespawn = respawns[#respawns]
	if (#respawns >= RSConstants.TELEMETRY_MIN_SAMPLES_MAX_FILTER) then
		local middle = math.floor(#respawns / 2)
		local median = (#respawns % 2 == 1) and respawns[middle + 1] or (respawns[middle] + respawns[middle + 1]) / 2
		local index = #respawns
		while (index > 1 and respawns[index] > median * RSConstants.TELEMETRY_MAX_FILTER_FACTOR) do
			index = index - 1
		end
		maxRespawn = respawns[index]

		-- A received sample that is much shorter than the rest would make the tooltip announce the respawn too soon
		while (firstIndex < index and respawns[firstIndex] < median / RSConstants.TELEMETRY_MIN_FILTER_DIVISOR) do
			firstIndex = firstIndex + 1
		end
	end

	return respawns[firstIndex], maxRespawn, #respawns, lastRespawn
end

--- If all the respawns measured are almost the same, the NPC has an exact respawn.
-- Returns minRespawn, maxRespawn, isExact
local function GetLearnedRespawn(minRespawn, maxRespawn, respawnCount)
	if (not minRespawn or not maxRespawn) then
		return nil, nil, false
	end

	local isExact = (respawnCount >= RSConstants.TELEMETRY_MIN_SAMPLES_EXACT and (maxRespawn - minRespawn) <= RSConstants.TELEMETRY_EXACT_TOLERANCE_SECONDS)
	if (isExact) then
		local exactRespawn = math.floor((minRespawn + maxRespawn) / 2 + 0.5)
		return exactRespawn, exactRespawn, true
	end

	return minRespawn, maxRespawn, false
end

function RSTelemetryEngine.GetEstimatedRespawn(npcID)
	if (not npcID) then
		return nil
	end

	local spawnInfo = RSNpcDB.GetNpcSpawnInfo(npcID)
	local npcData = RSTelemetryDB.GetNpcData(npcID)
	local samples = npcData and npcData.samples or {}
	if (not spawnInfo and #samples == 0) then
		return nil
	end

	local npcInfo = RSNpcDB.GetInternalNpcInfo(npcID)

	-- The database information has priority over the one learned from the samples
	local observedMin, observedMax, respawnCount, lastRespawn = GetObservedRespawns(samples)
	local minRespawn, maxRespawn = RSNpcDB.GetNpcRespawnRange(npcID)
	local hasStaticRange = (minRespawn ~= nil and maxRespawn ~= nil)
	local isExactRespawn = (minRespawn ~= nil and minRespawn == maxRespawn)
	if (not minRespawn or not maxRespawn) then
		minRespawn, maxRespawn, isExactRespawn = GetLearnedRespawn(observedMin, observedMax, respawnCount)
	end

	local schedule = RSNpcDB.GetNpcSchedule(npcID)
	local isLearnedSchedule = false
	if (not schedule) then
		-- A creature seen for the first time doesn't tell when it spawned
		local spawnSamples = {}
		for _, sample in ipairs(samples) do
			if (not sample.live) then
				table.insert(spawnSamples, sample)
			end
		end
		schedule = GetLearnedSchedule(spawnSamples)
		isLearnedSchedule = (schedule ~= nil)
	end

	local result = {
		samples = #samples,
		respawnSamples = respawnCount,
		observedMinRespawn = observedMin,
		observedMaxRespawn = observedMax,
		minRespawn = minRespawn,
		maxRespawn = maxRespawn,
		isExactRespawn = isExactRespawn,
		lastRespawn = lastRespawn,
		schedule = schedule,
		isLearnedSchedule = isLearnedSchedule,
		isTriggered = RSNpcDB.IsNpcManualEvent(npcID),
		nonResetting = (npcInfo ~= nil and npcInfo.reset == false),
		hasStaticConfig = (spawnInfo ~= nil),
		hasStaticRange = hasStaticRange,
	}

	-- Calculate countdown to next spawn if schedule is configured
	if (schedule) then
		local secondsUntilNext, nextClockStr = CalculateSecondsUntilNextSchedule(schedule)
		if (secondsUntilNext) then
			result.secondsUntilNext = secondsUntilNext
			result.nextSpawnTime = time() + secondsUntilNext
			result.nextClock = nextClockStr
		end
	end

	-- Calculate the respawn window from the last death
	local lastKill = RSTelemetryDB.GetLastKill(npcID, currentShardID, C_Map.GetBestMapForUnit("player"))
	if (lastKill and result.minRespawn and result.maxRespawn) then
		local secondsSinceDeath = GetServerTime() - lastKill.timestamp
		local secondsUntilWindowEnd = result.maxRespawn - secondsSinceDeath

		-- Some minutes after the window we don't know if it was killed again, so the generic range is shown instead
		if (secondsUntilWindowEnd > -RSConstants.TELEMETRY_OVERDUE_GRACE_SECONDS) then
			result.hasRecentDeath = true
			result.secondsUntilWindowStart = result.minRespawn - secondsSinceDeath
			result.secondsUntilWindowEnd = secondsUntilWindowEnd
		end
	end

	return result
end

--- Returns the line of NPC_SPAWN_INFO that the samples suggest for a NPC, the number of respawns measured and,
-- if the samples fit in two different ways (a schedule and an exact respawn), the other way.
-- NPCs that already have information in the database get no proposal
function RSTelemetryEngine.GetSpawnInfoProposal(npcID)
	local estimate = RSTelemetryEngine.GetEstimatedRespawn(npcID)
	if (not estimate or estimate.hasStaticConfig) then
		return nil
	end

	if (estimate.isLearnedSchedule) then
		local alternative = estimate.isExactRespawn and string.format("{ exact = %d }", estimate.minRespawn) or nil
		return string.format("{ onTime = { %s } }", table.concat(estimate.schedule.minutes, ", ")), estimate.samples, alternative
	elseif (estimate.isExactRespawn) then
		return string.format("{ exact = %d }", estimate.minRespawn), estimate.respawnSamples
	elseif (estimate.respawnSamples >= RSConstants.TELEMETRY_MIN_SAMPLES_PROPOSAL) then
		return string.format("{ min = %d, max = %d }", estimate.minRespawn, estimate.maxRespawn), estimate.respawnSamples
	end

	return nil
end
