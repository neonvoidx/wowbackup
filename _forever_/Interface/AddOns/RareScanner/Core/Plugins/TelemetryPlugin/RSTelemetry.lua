-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSTelemetry = private.NewLib("RareScannerTelemetry")

local AL = LibStub("AceLocale-3.0"):GetLocale("RareScanner", false)

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSConfigDB = private.ImportLib("RareScannerConfigDB")
local RSTelemetryDB = private.ImportLib("RareScannerTelemetryDB")
local RSTelemetryEngine = private.ImportLib("RareScannerTelemetryEngine")
local RSTelemetryComm = private.ImportLib("RareScannerTelemetryComm")
local RSTelemetryExport = private.ImportLib("RareScannerTelemetryExport")
local RSNpcDB = private.ImportLib("RareScannerNpcDB")
local RSMapDB = private.ImportLib("RareScannerMapDB")
local RSLogger = private.ImportLib("RareScannerLogger")
local RSRoutines = private.ImportLib("RareScannerRoutines")
local RSUtils = private.ImportLib("RareScannerUtils")
local RSTimeUtils = private.ImportLib("RareScannerTimeUtils")

---============================================================================
-- Validation & Status
---============================================================================

local heartbeat = nil

function RSTelemetry.InitializeComm()
	if (RSConfigDB.IsTelemetryEnabled()) then
		-- The time that the player is offline is needed to know which respawns are reliable
		RSTelemetryDB.RegisterLogin()
		if (not heartbeat) then
			heartbeat = C_Timer.NewTicker(RSConstants.TELEMETRY_HEARTBEAT_SECONDS, RSTelemetryDB.UpdateLastOnline)
		end

		RSTelemetryComm.Initialize()
	end
end

function RSTelemetry.OnLogout()
	-- The option can't be read here: AceDB removes the default values of the profile when the game closes
	if (heartbeat) then
		RSTelemetryDB.UpdateLastOnline()
	end
end

--- The player has changed of zone (a reload doesn't count)
function RSTelemetry.OnZoneChanged(isReloadingUi)
	if (not isReloadingUi and RSConfigDB.IsTelemetryEnabled()) then
		RSTelemetryDB.MarkZoneChange()
	end
end

function RSTelemetry.OnGroupRosterUpdate()
	if (RSConfigDB.IsTelemetryEnabled()) then
		RSTelemetryComm.OnGroupRosterUpdate()
	end
end

function RSTelemetry.DisableComm()
	if (heartbeat) then
		heartbeat:Cancel()
		heartbeat = nil
	end

	RSTelemetryComm.Disable()
end

local npcsOnlyInInstances = {}

local function IsNpcOnlyInInstances(npcID, npcInfo)
	if (npcsOnlyInInstances[npcID] == nil) then
		local zoneIDs = type(npcInfo.zoneID) == "table" and npcInfo.zoneID or { [npcInfo.zoneID] = true }
		local onlyInInstances = next(zoneIDs) ~= nil
		for zoneID in pairs(zoneIDs) do
			if (not RSMapDB.IsMapInAnyContinent(zoneID, RSConstants.TELEMETRY_IGNORED_CONTINENTS)) then
				onlyInInstances = false
				break
			end
		end

		npcsOnlyInInstances[npcID] = onlyInInstances
	end

	return npcsOnlyInInstances[npcID]
end

--- Checks whether a NPC is supported by the addon for telemetry tracking
function RSTelemetry.IsNpcSupported(npcID)
	if (not npcID) then
		return false
	end

	-- Must exist in RareScanner's internal database
	local npcInfo = RSNpcDB.GetInternalNpcInfo(npcID)
	if (not npcInfo) then
		return false
	end

	-- Custom NPCs of the player are not tracked
	if (npcInfo.custom) then
		return false
	end

	-- The rares of instances don't have a respawn time
	if (IsNpcOnlyInInstances(npcID, npcInfo)) then
		return false
	end

	-- NPCs that stop being rare after the first kill have no respawn
	if (npcInfo.reset == false) then
		return false
	end

	-- NPCs that are summoned manually have no respawn timer, and the final ones are already known
	if (RSNpcDB.IsNpcManualEvent(npcID) or RSNpcDB.IsNpcSpawnFinal(npcID)) then
		return false
	end

	-- Skip ignored NPC vignettes and friendly NPCs
	if (RSUtils.Contains(RSConstants.IGNORED_VIGNETTES_NPCS, npcID) or RSUtils.Contains(RSConstants.IGNORED_FRIENDLY_NPCS, npcID)) then
		return false
	end

	return true
end

---============================================================================
-- External Callbacks & Hooks
---============================================================================

---============================================================================
-- Hooks
---============================================================================

-- An error in the telemetry must never break the rest of the addon (the hooks are called in the middle of the detection
-- of the rares), so they run protected. If one fails too many times, they stop until the next reload
local hookErrorCount = 0

local function RunHook(func, ...)
	if (hookErrorCount >= RSConstants.TELEMETRY_HOOK_MAX_ERRORS) then
		return
	end

	local isOk, errorMessage = pcall(func, ...)
	if (not isOk) then
		hookErrorCount = hookErrorCount + 1
		RSTelemetryDB.IncreaseStat("hookErrors")
		RSLogger:PrintTelemetryDebugMessage(string.format("Error en un enganche (%s/%s): %s", hookErrorCount, RSConstants.TELEMETRY_HOOK_MAX_ERRORS, tostring(errorMessage)))
	end
end

local function OnEntityFound(npcID, vignetteInfo, mapID)
	if (not RSConfigDB.IsTelemetryEnabled() or not vignetteInfo) then
		return
	end

	-- The statistics (debug mode) tell where each detection stops
	RSTelemetryDB.IncreaseStat("sightings")
	if (not RSConstants.IsNpcAtlas(vignetteInfo.atlasName) or not RSTelemetry.IsNpcSupported(npcID)) then
		RSTelemetryDB.IncreaseStat("sightingsNotSupported")
		return
	end

	-- A secret value is checked first, because it can't be used in a condition
	local guid = vignetteInfo.objectGUID
	if (issecretvalue(guid) or not guid) then
		guid = vignetteInfo.vignetteGUID
	end
	RSTelemetryEngine.RecordSighting(npcID, guid, mapID)
end

-- Called for every tracking system (vignettes, nameplates, mouseover...)
function RSTelemetry.OnEntityFound(npcID, vignetteInfo, mapID)
	RunHook(OnEntityFound, npcID, vignetteInfo, mapID)
end

-- Called for every creature seen around the player, to know in which shard he is
function RSTelemetry.OnCreatureSeen(guid)
	if (not RSConfigDB.IsTelemetryEnabled()) then
		return
	end

	RunHook(RSTelemetryEngine.UpdateCurrentShard, guid)
end

local recentDeadGuids = {}

local function OnEntityDied(npcID, guid)
	if (not RSConfigDB.IsTelemetryEnabled() or issecretvalue(guid) or not guid) then
		return
	end
	RSTelemetryDB.IncreaseStat("deaths")
	if (not RSTelemetry.IsNpcSupported(npcID)) then
		RSTelemetryDB.IncreaseStat("deathsNotSupported")
		return
	end

	-- Deduplicate death events by unit GUID
	if (recentDeadGuids[guid]) then
		RSTelemetryDB.IncreaseStat("deathsRepeated")
		return
	end
	recentDeadGuids[guid] = true

	RSTelemetryEngine.RecordDeath(npcID, guid)
end

function RSTelemetry.OnEntityDied(npcID, guid)
	RunHook(OnEntityDied, npcID, guid)
end

function RSTelemetry.GetEstimatedRespawn(npcID)
	if (not RSConfigDB.IsTelemetryEnabled()) then
		return nil
	end

	-- It is called by the tooltips, so an error must not reach them
	local isOk, estimate = pcall(RSTelemetryEngine.GetEstimatedRespawn, npcID)
	if (not isOk) then
		RSTelemetryDB.IncreaseStat("estimateErrors")
		RSLogger:PrintTelemetryDebugMessage(string.format("Error al estimar el respawn del NPC [%s]: %s", npcID, tostring(estimate)))
		return nil
	end

	return estimate
end

---============================================================================
-- Reports via chat / slash command
---============================================================================

local function FormatDuration(seconds)
	if (not seconds) then
		return AL["TELEMETRY_UNKNOWN"]
	end

	return RSTimeUtils.FormatShortDuration(seconds)
end

local function Value(value)
	return RSUtils.TextColor(tostring(value), "FFFFFF")
end

local function GetTargetNpcID()
	local targetGuid = UnitGUID("target")
	if (not issecretvalue(targetGuid) and targetGuid) then
		local isValid, npcID = RSTelemetryEngine.ParseCreatureGUID(targetGuid)
		if (isValid) then
			return npcID
		end
	end

	return nil
end

local function PrintNpcReport(npcID)
	local est = RSTelemetryEngine.GetEstimatedRespawn(npcID)
	local npcName = RSNpcDB.GetNpcName(npcID) or "NPC "..npcID

	RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_REPORT_TITLE"], RSUtils.TextColor(npcName, "FFCC00"), npcID))

	if (not est) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_NO_DATA"])
		return
	end

	if (est.isTriggered) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_TYPE_SUMMONED"])
	end
	if (est.nonResetting) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_TYPE_NON_RESETTING"])
	end

	if (est.hasStaticConfig) then
		local spawnInfo = RSNpcDB.GetNpcSpawnInfo(npcID)
		if (spawnInfo.exact) then
			RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_DATABASE_EXACT"], Value(FormatDuration(spawnInfo.exact))))
		elseif (spawnInfo.min or spawnInfo.max) then
			RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_DATABASE_RANGE"], Value(FormatDuration(spawnInfo.min)), Value(FormatDuration(spawnInfo.max))))
		end
		if (spawnInfo.onTime) then
			RSLogger:PrintTelemetryMessage(AL["TELEMETRY_DATABASE_SCHEDULE"])
		end
	end

	if (est.isLearnedSchedule) then
		local minutes = {}
		for _, minute in ipairs(est.schedule.minutes) do
			table.insert(minutes, string.format(":%02d", minute))
		end
		RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_LEARNED_SCHEDULE"], Value(table.concat(minutes, " "))))
	end

	if (est.secondsUntilNext and est.nextClock) then
		RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_NEXT_RESPAWN"], Value(FormatDuration(est.secondsUntilNext)), Value(est.nextClock)))
	end

	if (est.samples > 0) then
		RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_SAMPLES"], Value(est.samples), Value(est.respawnSamples)))
		if (est.respawnSamples > 0) then
			-- The observed values are shown, even if the database has its own range
			if (est.isExactRespawn and not est.hasStaticConfig) then
				RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_EXACT_LEARNED"], Value(FormatDuration(est.minRespawn))))
			elseif (est.observedMinRespawn == est.observedMaxRespawn) then
				RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_RESPAWN_UNCONFIRMED"], Value(FormatDuration(est.observedMinRespawn))))
			else
				RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_OBSERVED_RANGE"], Value(FormatDuration(est.observedMinRespawn)), Value(FormatDuration(est.observedMaxRespawn))))
			end
			RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_LAST_RESPAWN"], Value(FormatDuration(est.lastRespawn))))
		end
	elseif (not est.hasStaticConfig) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_NOT_ENOUGH_SAMPLES"])
	end
end

---============================================================================
-- Development only (DEBUG_MODE): these reports are printed in the chat window of the telemetry
---============================================================================

local function PrintStats()
	local stats, sendersCount = RSTelemetryDB.GetStats()
	RSLogger:PrintTelemetryDebugMessage("Estadísticas de comunicaciones:")

	local statNames = {}
	for statName in pairs(stats) do
		table.insert(statNames, statName)
	end
	table.sort(statNames)

	for _, statName in ipairs(statNames) do
		RSLogger:PrintTelemetryDebugMessage(string.format("  %s: %d", statName, stats[statName]))
	end
	RSLogger:PrintTelemetryDebugMessage(string.format("  Remitentes distintos: %d", sendersCount))
end

local MAX_PROPOSALS_PRINTED = 15

local function PrintProposals()
	local lines = {}
	for _, line in pairs(RSTelemetryDB.GetProposals()) do
		table.insert(lines, line)
	end
	table.sort(lines)

	RSLogger:PrintTelemetryDebugMessage(string.format("Propuestas para NPC_SPAWN_INFO: %d (se guardan completas en el fichero de variables)", #lines))
	for index = 1, math.min(#lines, MAX_PROPOSALS_PRINTED) do
		RSLogger:PrintTelemetryDebugMessage("  "..lines[index])
	end
end

local SIMULATED_NPCS_COUNT = 3

--- Simulates the answer of another player with samples of the first supported NPCs
local function SimulateSync()
	local npcIDs = {}
	for npcID in pairs(RSNpcDB.GetAllInternalNpcInfo()) do
		if (RSTelemetry.IsNpcSupported(npcID)) then
			table.insert(npcIDs, npcID)
		end
	end
	table.sort(npcIDs)
	for index = #npcIDs, SIMULATED_NPCS_COUNT + 1, -1 do
		npcIDs[index] = nil
	end

	local samplesCount = RSTelemetryComm.SimulateSyncResponse(npcIDs)
	RSLogger:PrintTelemetryDebugMessage(string.format("Simuladas %d muestras recibidas por susurro de otro jugador. Mira '/rs %s %s'. Para borrarlas: '/rs %s %s'.", samplesCount, RSConstants.CMD_TELEMETRY, RSConstants.CMD_TELEMETRY_STATS, RSConstants.CMD_TELEMETRY, RSConstants.CMD_TELEMETRY_SIMSYNC_CLEAR))
end

local function ClearSimulatedSync()
	local removedCount = RSTelemetryDB.RemoveSamplesBySender(RSTelemetryComm.GetSimulatedSenderHash())
	RSLogger:PrintTelemetryDebugMessage(string.format("Borradas %d muestras simuladas.", removedCount))
end

--- Cleans the data saved and, in debug mode, prepares the lines proposed for NPC_SPAWN_INFO
function RSTelemetry.CreateMaintenanceRoutine()
	local maintenanceRoutine = RSRoutines.LoopRoutineNew()
	maintenanceRoutine:Init(
		function()
			RSTelemetryDB.ResetProposals()
			return RSTelemetryDB.GetAllTelemetryNpcs()
		end,
		function(context, npcID)
			if (not RSTelemetry.IsNpcSupported(npcID)) then
				RSTelemetryDB.RemoveNpc(npcID)
				return
			end

			RSTelemetryDB.CleanNpcData(npcID)
			if (RSConstants.DEBUG_MODE) then
				local proposal, samplesCount, alternative = RSTelemetryEngine.GetSpawnInfoProposal(npcID)
				if (proposal) then
					local alternativeText = alternative and (" [it also fits "..alternative.."]") or ""
					RSTelemetryDB.SetProposal(npcID, string.format("[%d] = %s, -- %s (%d)%s", npcID, proposal, RSNpcDB.GetNpcName(npcID) or "", samplesCount, alternativeText))
				end
			end
		end,
		function(context)
			RSLogger:PrintTelemetryDebugMessage("Limpiados los datos de telemetría")
		end
	)

	return maintenanceRoutine
end

local function RequestSync()
	local isGuildAsked, isGroupAsked = RSTelemetryComm.ForceSync()
	if (isGuildAsked or isGroupAsked) then
		RSLogger:PrintTelemetryDebugMessage(string.format("Petición de datos enviada a: %s%s.", isGuildAsked and "hermandad " or "", isGroupAsked and "grupo" or ""))
	else
		RSLogger:PrintTelemetryDebugMessage("No se ha enviado ninguna petición (sin hermandad ni grupo, o el chat está restringido).")
	end
end

-- The reports for development are only available in debug mode
local DEBUG_REPORTS = {
	[RSConstants.CMD_TELEMETRY_STATS] = PrintStats,
	[RSConstants.CMD_TELEMETRY_STATS_RESET] = function()
		RSTelemetryDB.ResetStats()
		RSLogger:PrintTelemetryDebugMessage("Estadísticas a cero.")
	end,
	[RSConstants.CMD_TELEMETRY_PROPOSALS] = PrintProposals,
	[RSConstants.CMD_TELEMETRY_SIMSYNC] = SimulateSync,
	[RSConstants.CMD_TELEMETRY_SIMSYNC_CLEAR] = ClearSimulatedSync,
	[RSConstants.CMD_TELEMETRY_SYNC] = RequestSync,
}

function RSTelemetry.PrintReport(argument)
	if (not RSConfigDB.IsTelemetryEnabled()) then
		return
	end

	if (argument == RSConstants.CMD_TELEMETRY_EXPORT) then
		RSTelemetryExport.ShowWindow()
		return
	end

	local debugReport = argument and DEBUG_REPORTS[argument]
	if (debugReport and RSConstants.DEBUG_MODE) then
		debugReport()
		return
	end

	local npcID = argument and tonumber(argument) or GetTargetNpcID()
	if (npcID) then
		PrintNpcReport(npcID)
	else
		RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_TOTAL_NPCS"], Value(RSTelemetryDB.GetTelemetryNpcCount())))
		RSLogger:PrintTelemetryMessage(string.format(AL["TELEMETRY_USAGE"], RSConstants.CMD_TELEMETRY))
	end
end
