---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
---@class Navigation
local Navigation = MapPinEnhanced:GetModule("Navigation")
local L = MapPinEnhanced.L

---@class NavigationStaticPhase
---@field group string
---@field fromArtID number
---@field toArtID number

---@class NavigationPhaseSwitchData
---@field fromMap number
---@field toMap number
---@field phase NavigationStaticPhase?
---@field npcID number?
---@field gossipOptionID number?
---@field parentOptionID number?

-- Only Zidormi transitions change these search states. Sharing coordinates or
-- a world instance never makes the two versions connected by ordinary movement.
---@type table<string, number[][]>
local groups = {
    vale = { { 390, 402 }, { 1530, 1342 } },
    uldum = { { 249, 289 }, { 1527, 260 } },
    darkshore = { { 62, 67 }, { 62, 1176 } },
    blasted_lands = { { 17, 18 }, { 17, 628 } },
    silithus = { { 81, 86 }, { 81, 962 } },
    dustwallow = { { 70, 75 }, { 70, 498 } },
}
---@type string[]
local groupNames = { "vale", "uldum", "darkshore", "blasted_lands", "silithus", "dustwallow" }
-- Remote phases are deferred until zone entry, not inferred from remote map art.
-- Missing observations in the current region remain unavailable (0).
local DEFERRED_PHASE = -1
local mapGroups = {} ---@type table<number, string>
local pastMaps = { [57] = { group = "darkshore", art = 67 }, [89] = { group = "darkshore", art = 67 } }
local pointPhases = {} ---@type table<number, {group: string, art: number}>
for name, sides in pairs(groups) do
    for _, side in ipairs(sides) do mapGroups[side[1]] = name end
end

---@param mapID number
---@return number?
local function ReadArt(mapID)
    local art = C_Map and C_Map.GetMapArtID and C_Map.GetMapArtID(mapID)
    if MapPinEnhanced:IsReadablePositiveInteger(art) then return art end
end

---@param mapID number?
---@return number?
---@return boolean ready
local function GetPhaseMap(mapID)
    local visited = {} ---@type table<number, boolean>
    while mapID and MapPinEnhanced:IsReadablePositiveInteger(mapID) and not visited[mapID] do
        if mapGroups[mapID] or pastMaps[mapID] then return mapID, true end
        visited[mapID] = true
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        if not info then return nil, false end
        if info.parentMapID == 0 then return nil, true end
        mapID = info.parentMapID
    end
    return nil, false
end

---@return table<string, number>
function Navigation:GetTravelPhaseState()
    local state = {} ---@type table<string, number>
    if MapPinEnhanced.isForever then return state end
    local current = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not MapPinEnhanced:IsReadablePositiveInteger(current) then current = nil end
    local phaseMap, ready = GetPhaseMap(current)
    local past = phaseMap and pastMaps[phaseMap]
    local currentGroup = past and past.group or phaseMap and mapGroups[phaseMap]
    for name, sides in pairs(groups) do
        state[name] = ready and DEFERRED_PHASE or 0
        if name == currentGroup then
            state[name] = past and past.art or 0
            local art = phaseMap and ReadArt(phaseMap)
            for _, side in ipairs(sides) do
                if phaseMap == side[1] and art == side[2] then state[name] = art end
            end
        end
    end
    return state
end

---@param state table<string, number>
---@return string
function Navigation:GetTravelPhaseKey(state)
    local values = {} ---@type string[]
    for _, name in ipairs(groupNames) do values[#values + 1] = tostring(state[name] or 0) end
    return table.concat(values, ":")
end

---@param requirement NavigationRequirement
---@param state table<string, number>?
---@return NavigationRequirementState?
function Navigation:EvaluateTravelPhaseRequirement(requirement, state)
    if not state or requirement.operation ~= "check" or requirement.kind ~= "mapArtID" or
        type(requirement.value) ~= "table" then
        return
    end
    local group = mapGroups[requirement.value[1]]
    if not group or state[group] == nil then return end
    if state[group] == 0 or state[group] == DEFERRED_PHASE then return "unknown" end
    return state[group] == requirement.value[2] and "satisfied" or "unsatisfied"
end

---@param state table<string, number>
---@param mapID number
---@return boolean
function Navigation:IsTravelPhaseMapAllowed(state, mapID)
    local past = pastMaps[mapID]
    if past and state[past.group] ~= nil then
        return state[past.group] == DEFERRED_PHASE or state[past.group] == past.art
    end
    local group = mapGroups[mapID]
    if not group or state[group] == nil then return true end
    if state[group] == DEFERRED_PHASE then return true end
    if state[group] == 0 then return false end
    local sides = groups[group]
    if sides[1][1] == sides[2][1] then return true end
    for _, side in ipairs(sides) do
        if side[1] == mapID then return state[group] == side[2] end
    end
    return true
end

---@param state table<string, number>
---@param mapID number
---@param destinationState table<string, number>
---@return boolean
function Navigation:IsTravelPhaseDestinationAllowed(state, mapID, destinationState)
    if not self:IsTravelPhaseMapAllowed(state, mapID) then return false end
    local group = mapGroups[mapID]
    if not group or state[group] == nil then return true end
    if state[group] == DEFERRED_PHASE then return true end
    local sides = groups[group]
    if sides[1][1] ~= sides[2][1] then return true end
    return state[group] == destinationState[group]
end

-- Planning permissions are provisional outside the region. Actual arrival must
-- observe the region and its requested variant before consuming the destination.
---@param mapID number
---@param destinationState table<string, number>?
---@return boolean
function Navigation:IsTravelPhaseArrivalAllowed(mapID, destinationState)
    if MapPinEnhanced.isForever then return true end
    local phaseMap, ready = GetPhaseMap(mapID)
    if not ready then return false end
    if not phaseMap then return true end
    local past = pastMaps[phaseMap]
    local group = past and past.group or mapGroups[phaseMap]
    local state = self:GetTravelPhaseState()
    if not state[group] or state[group] <= 0 then return false end
    if destinationState and destinationState[group] == DEFERRED_PHASE then destinationState = nil end
    return self:IsTravelPhaseDestinationAllowed(state, phaseMap, destinationState or state)
end

---@param fromMap number
---@param toMap number
---@return boolean
function Navigation:IsTravelPhaseCrossing(fromMap, toMap)
    return not MapPinEnhanced.isForever and fromMap ~= toMap and mapGroups[fromMap] ~= nil and
        mapGroups[fromMap] == mapGroups[toMap]
end

---@param graph NavigationGraph
---@param point integer
---@param state table<string, number>
---@return boolean
function Navigation:IsTravelPhasePointAllowed(graph, point, state)
    local phase = pointPhases[graph.pointIDs[point]]
    if phase then return state[phase.group] == phase.art or state[phase.group] == DEFERRED_PHASE end
    return self:IsTravelPhaseMapAllowed(state, graph.pointMapIDs[point])
end

---@param graph NavigationGraph
---@param reference integer
---@param state table<string, number>
---@return table<string, number>?
function Navigation:AdvanceTravelPhase(graph, reference, state)
    local from = graph.pathFromPointIndexes[reference]
    if from and not self:IsTravelPhasePointAllowed(graph, from, state) then return nil end
    local data = graph.pathTypes[reference] == "phaseswitch" and graph.pathHandlerData[reference]
    -- Old catalog portals between phase variants must not become shortcuts just
    -- because their remote phase checks are deferred.
    if from and not (data and data.phase) and
        self:IsTravelPhaseCrossing(graph.pointMapIDs[from], graph.pointMapIDs[graph.pathToPointIndexes[reference]]) then
        return nil
    end
    if data and data.phase then
        local phase = data.phase ---@type NavigationStaticPhase
        if state[phase.group] ~= phase.fromArtID then return nil end
        local changed = {} ---@type table<string, number>
        for name, art in pairs(state) do changed[name] = art end
        changed[phase.group] = phase.toArtID
        state = changed
    end
    if not self:IsTravelPhasePointAllowed(graph, graph.pathToPointIndexes[reference], state) then return nil end
    return state
end

---@param graph NavigationGraph
function Navigation:IndexTravelPhaseRequirements(graph)
    if MapPinEnhanced.isForever then return end
    ---@param requirement NavigationRequirement?
    ---@param found table<string, boolean>
    local function Collect(requirement, found)
        if not requirement then return end
        if requirement.operation == "check" then
            if requirement.kind == "mapArtID" and type(requirement.value) == "table" then
                local name = mapGroups[requirement.value[1]]
                if name then found[name] = true end
            end
        else
            for _, child in ipairs(requirement.children or {}) do Collect(child, found) end
        end
    end
    -- Dependencies are authored graph data; eligibility and observations stay search-local.
    for _, reference in ipairs(graph.pathsByRequirementKind.mapArtID or {}) do
        local found = {} ---@type table<string, boolean>
        local names = {} ---@type string[]
        Collect(graph.pathRequirements[reference], found)
        for _, name in ipairs(groupNames) do if found[name] then names[#names + 1] = name end end
        if #names > 0 then graph.phaseGroupsByPath[reference] = names end
    end
end

---@param requirement NavigationRequirement?
---@param names string[]
---@param index integer
---@param state table<string, number>
---@param observations NavigationRequirementObservations?
---@return NavigationRequirementState
---@return string?
local function EvaluatePhaseVariants(requirement, names, index, state, observations)
    local name = names[index]
    if not name then return Navigation:EvaluateRequirement(requirement, observations, state) end
    if state[name] ~= DEFERRED_PHASE then
        return EvaluatePhaseVariants(requirement, names, index + 1, state, observations)
    end
    local result, failure = "unsatisfied", "phase requirement not satisfied"
    for _, side in ipairs(groups[name]) do
        state[name] = side[2]
        local candidate, reason = EvaluatePhaseVariants(requirement, names, index + 1, state, observations)
        if candidate == "satisfied" then
            state[name] = DEFERRED_PHASE
            return candidate
        end
        if candidate == "unknown" then result, failure = candidate, reason end
    end
    state[name] = DEFERRED_PHASE
    return result, failure
end

-- Defer only the phase-dependent part of a remote path. Enumerating its authored
-- variants preserves all/any/not and keeps unrelated unlocks/readiness authoritative.
---@param graph NavigationGraph
---@param reference integer
---@param state table<string, number>?
---@param observations NavigationRequirementObservations?
---@return NavigationRequirementState
---@return string?
function Navigation:EvaluateTravelPhasePathRequirement(graph, reference, state, observations)
    local requirement = graph.pathRequirements[reference]
    local names = graph.phaseGroupsByPath[reference]
    if state and names then
        for _, name in ipairs(names) do
            if state[name] == DEFERRED_PHASE then
                local copy = {} ---@type table<string, number>
                for group, art in pairs(state) do copy[group] = art end
                return EvaluatePhaseVariants(requirement, names, 1, copy, observations)
            end
        end
    end
    return self:EvaluateRequirement(requirement, observations, state)
end

-- Alternate phase eligibility is lazy too. The graph owns only dependency
-- metadata; this search owns the observations and both positive/negative results.
---@param prepared NavigationPreparedData
---@return NavigationPreparedData
function Navigation:PrepareTravelPhaseSearch(prepared)
    if MapPinEnhanced.isForever then return prepared end
    return setmetatable({
        phaseStates = {},
        phaseFailures = {},
        phaseObservations = {}
    }, { __index = prepared })
end

---@param graph NavigationGraph
---@param prepared NavigationPreparedData
---@param reference integer
---@param state table<string, number>
---@return boolean
function Navigation:IsTravelPhasePathAllowed(graph, prepared, reference, state)
    if reference < 0 then return true end
    local data = graph.pathTypes[reference] == "phaseswitch" and graph.pathHandlerData[reference]
    if data and data.phase and state[data.phase.group] == DEFERRED_PHASE then return false end
    if self:GetPreparedPathState(graph, prepared, reference) ~= "satisfied" then return false end
    if prepared.phaseStates and graph.phaseGroupsByPath[reference] then
        local remote = true
        for _, name in ipairs(graph.phaseGroupsByPath[reference]) do
            if state[name] ~= DEFERRED_PHASE then
                remote = false
                break
            end
        end
        if remote then return true end
        return self:EvaluateTravelPhasePathRequirement(graph, reference, state, prepared.phaseObservations) ==
            "satisfied"
    end
    return true
end

local activeContext ---@type NavigationActivePathContext?
local activeReport ---@type NavigationPathReport?
local observedOrigin = false

local function CheckPhaseChange()
    local context, report = activeContext, activeReport
    if not context or not report then return end
    local data = context.data ---@type NavigationPhaseSwitchData
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if MapPinEnhanced:IsSecretValue(mapID) then return end
    local phase = data.phase
    if mapID == data.fromMap and (not phase or ReadArt(data.fromMap) == phase.fromArtID) then
        observedOrigin = true
    end
    if observedOrigin and context.phase ~= "approach" and mapID == data.toMap and
        (not phase or ReadArt(data.toMap) == phase.toArtID) then
        report("completed")
    end
end

Navigation:RegisterPathHandler("phaseswitch", function(context)
    local data = context and context.data
    ---@cast data NavigationPhaseSwitchData?
    local phase = data and data.phase
    local instruction = L["Navigation Talk To NPC"]
    if phase then
        instruction = L[phase.toArtID == groups[phase.group][1][2] and
        "Navigation Phase Past" or "Navigation Phase Present"]
    end
    return "ChromieTime-32x32", L["Navigation Method Phase Change"], instruction
end, function(path)
    if type(path.fromMap) ~= "number" or type(path.fromPointID) ~= "number" then
        return nil, "phase switch requires an origin map and point"
    end
    local phase = path.phase
    if phase then
        local sides = groups[phase.group]
        if not sides or phase.fromArtID == phase.toArtID then return nil, "invalid phase transition" end
        local fromSide = sides[1][2] == phase.fromArtID and sides[1] or sides[2][2] == phase.fromArtID and sides[2]
        local toSide = sides[1][2] == phase.toArtID and sides[1] or sides[2][2] == phase.toArtID and sides[2]
        if not fromSide or not toSide or path.fromMap ~= fromSide[1] or path.toMap ~= toSide[1] then
            return nil, "phase maps and art do not match the region"
        end
        pointPhases[path.fromPointID] = { group = phase.group, art = phase.fromArtID }
        pointPhases[path.toPointID] = { group = phase.group, art = phase.toArtID }
        return { fromMap = path.fromMap, toMap = path.toMap, phase = phase }
    end
    if path.fromMap == path.toMap then return nil, "phase switch requires map or art change" end
    local gossip, failure = Navigation:GetGossipPathData(path)
    if not gossip then return nil, failure end
    return {
        fromMap = path.fromMap,
        toMap = path.toMap,
        npcID = gossip.npcID,
        gossipOptionID = gossip.gossipOptionID
    }
end, function()
    return {
        expectedSeconds = 10,
        uncertaintySeconds = 0,
        comparisonSeconds = 10,
        explanation = { kind = "phase-switch", seconds = 10 }
    }
end, function(context, report)
    if not activeContext or activeContext.pathReference ~= context.pathReference then observedOrigin = false end
    activeContext, activeReport = context, report
    if context.data.gossipOptionID then Navigation:ActivateGossipPath(context, report) end
    CheckPhaseChange()
end, function()
    activeContext, activeReport = nil, nil
    observedOrigin = false
    Navigation:DeactivateGossipPath()
end)

MapPinEnhanced:RegisterEventBucket({ "LOADING_SCREEN_DISABLED", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE",
    "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "GOSSIP_CLOSED" }, CheckPhaseChange, 0.1)
