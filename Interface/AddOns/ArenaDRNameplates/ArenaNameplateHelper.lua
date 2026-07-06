-- ArenaNameplateHelper.lua
-- Retail Midnight friendly
-- Goal:
--   arena1/arena2/arena3 -> nameplate token -> nameplate frame / anchor parent

local _, ns = ...
ns = ns or {}

local Helper = CreateFrame("Frame", "ArenaDrNP_NameplateHelper")
ns.ArenaNameplateHelper = Helper

Helper.arenaToToken = {}
Helper.tokenToArena = {}
Helper.callbacks = {}

local burstToken = 0
local refreshQueued = false
local burstRefreshDelays = { 0, 0.05, 0.12, 0.25, 0.50, 0.90, 1.50 }

local function isSecretValue(value)
    if type(issecretvalue) ~= "function" then
        return false
    end

    local ok, result = pcall(issecretvalue, value)
    return ok and result == true
end

local function safeCall(func, ...)
    if type(func) ~= "function" then
        return nil, nil, nil, nil
    end

    local ok, a, b, c, d = pcall(func, ...)
    if not ok then
        return nil, nil, nil, nil
    end

    return a, b, c, d
end

local function asPublicString(value)
    if type(value) ~= "string" or isSecretValue(value) then
        return nil
    end
    return value
end

local function asPublicNumber(value)
    if type(value) ~= "number" or isSecretValue(value) then
        return nil
    end
    return value
end

local function asPublicBoolean(value)
    if type(value) ~= "boolean" or isSecretValue(value) then
        return nil
    end
    return value
end

local function safePublicString(func, ...)
    return asPublicString(safeCall(func, ...))
end

local function safePublicNumber(func, ...)
    return asPublicNumber(safeCall(func, ...))
end

local function safePublicBoolean(func, ...)
    return asPublicBoolean(safeCall(func, ...))
end

local function safeUnitExists(unit)
    return safePublicBoolean(UnitExists, unit) == true
end

local function safeUnitsMatch(unitA, unitB)
    return safePublicBoolean(UnitIsUnit, unitA, unitB) == true
end

local function safeUnitCanAttack(unitA, unitB)
    return safePublicBoolean(UnitCanAttack, unitA, unitB)
end

local function safeUnitIsEnemy(unitA, unitB)
    return safePublicBoolean(UnitIsEnemy, unitA, unitB)
end

local function safeUnitIsPlayer(unit)
    return safePublicBoolean(UnitIsPlayer, unit)
end

local function safeUnitName(unit)
    local name = safePublicString(UnitName, unit)
    if name and name ~= "" then
        return name
    end
    return nil
end

local function safeUnitGUID(unit)
    local guid = asPublicString(safeCall(UnitGUID, unit))
    if guid and guid ~= "" then
        return guid
    end
    return nil
end

local function safeUnitClassToken(unit)
    local _, classToken = safeCall(UnitClass, unit)
    classToken = asPublicString(classToken)
    if classToken and classToken ~= "" then
        return classToken
    end
    return nil
end

local FRIENDLY_REFERENCE_UNITS = {
    "player",
    "party1",
    "party2",
    "party3",
    "party4",
}

local isNameplateToken

local function isKnownFriendlyToken(token)
    token = isNameplateToken(token)
    if not token then
        return false
    end

    for _, unit in ipairs(FRIENDLY_REFERENCE_UNITS) do
        if safeUnitsMatch(token, unit) then
            return true
        end
    end

    return false
end

local function isEnemyPlayerToken(token)
    token = isNameplateToken(token)
    if not token or not safeUnitExists(token) then
        return false
    end

    if safeUnitIsPlayer(token) == false then
        return false
    end

    if isKnownFriendlyToken(token) then
        return false
    end

    local canAttack = safeUnitCanAttack("player", token)
    local isEnemy = safeUnitIsEnemy("player", token)

    if canAttack == true or isEnemy == true then
        return true
    end

    if canAttack == false or isEnemy == false then
        return false
    end

    return safeUnitClassToken(token) ~= nil
end

local function isAttackableNameplateToken(token)
    token = isNameplateToken(token)
    if not token or not safeUnitExists(token) then
        return false
    end

    if isKnownFriendlyToken(token) then
        return false
    end

    local canAttack = safeUnitCanAttack("player", token)
    local isEnemy = safeUnitIsEnemy("player", token)
    return canAttack == true or isEnemy == true
end

local function unitsShareIdentity(unitA, unitB)
    unitA = asPublicString(unitA)
    unitB = asPublicString(unitB)
    if not unitA or not unitB then
        return false
    end

    if not safeUnitExists(unitA) or not safeUnitExists(unitB) then
        return false
    end

    if safeUnitsMatch(unitA, unitB) then
        return true
    end

    local guidA = safeUnitGUID(unitA)
    local guidB = safeUnitGUID(unitB)
    return guidA and guidB and guidA == guidB
end

local function isInArenaInstance()
    local arenaActive = safePublicBoolean(IsActiveBattlefieldArena)
    if arenaActive == true then
        return true
    end

    local _, instanceType = safeCall(IsInInstance)
    instanceType = asPublicString(instanceType)
    return instanceType == "arena"
end

isNameplateToken = function(token)
    token = asPublicString(token)
    if not token then
        return nil
    end

    if token:match("^nameplate%d+$") then
        return token
    end

    return nil
end

local function getNameplateAdapters()
    return ns and ns.NameplateAdapters
end

local function getNameplateTokenFromUnitFrame(frame)
    if type(frame) ~= "table" then
        return nil
    end

    return isNameplateToken(frame.unit)
        or isNameplateToken(frame.displayedUnit)
end

local function getNameplateTokenFromPlate(plate)
    if type(plate) ~= "table" then
        return nil
    end

    local adapters = getNameplateAdapters()
    if adapters and type(adapters.ResolveTokenForPlate) == "function" then
        local token = isNameplateToken(safeCall(adapters.ResolveTokenForPlate, adapters, plate))
        if token then
            return token
        end
    end

    if isNameplateToken(plate.namePlateUnitToken) then
        return isNameplateToken(plate.namePlateUnitToken)
    end

    if type(plate.UnitFrame) == "table" then
        local token = getNameplateTokenFromUnitFrame(plate.UnitFrame)
        if token then
            return token
        end
    end

    if type(plate.unitFrame) == "table" then
        local token = isNameplateToken(plate.unitFrame.namePlateUnitToken)
            or getNameplateTokenFromUnitFrame(plate.unitFrame)
        if token then
            return token
        end
    end

    return nil
end

local function getVisiblePlates()
    local plates = C_NamePlate.GetNamePlates()
    if type(plates) ~= "table" then
        return nil
    end
    return plates
end

local function getDefaultAnchorParentFromPlate(plate)
    if type(plate) ~= "table" then
        return nil
    end

    local unitFrame = nil
    if type(plate.UnitFrame) == "table" then
        unitFrame = plate.UnitFrame
    elseif type(plate.unitFrame) == "table" then
        unitFrame = plate.unitFrame
    end

    if unitFrame then
        for _, key in ipairs({
            "HealthBarsContainer",
            "healthBarsContainer",
            "healthBar",
            "HealthBar",
        }) do
            if type(unitFrame[key]) == "table" then
                return unitFrame[key]
            end
        end

        return unitFrame
    end

    return plate
end

local function getValidatedTokenForUnitFromPlate(unit, plate)
    unit = asPublicString(unit)
    if not unit or type(plate) ~= "table" then
        return nil
    end

    local token = getNameplateTokenFromPlate(plate)
    if not token then
        return nil
    end

    if isNameplateToken(unit) then
        if token == unit then
            return token
        end
        return nil
    end

    if unitsShareIdentity(unit, token) then
        return token
    end

    return nil
end

local function tryMap(newArenaToToken, newTokenToArena, arenaID, token)
    arenaID = asPublicNumber(arenaID)
    token = isNameplateToken(token)

    if not arenaID or not token then
        return false
    end

    if not isEnemyPlayerToken(token) then
        return false
    end

    if arenaID < 1 or arenaID > 3 then
        return false
    end

    local oldToken = newArenaToToken[arenaID]
    if oldToken and oldToken ~= token then
        newTokenToArena[oldToken] = nil
    end

    local oldArenaID = newTokenToArena[token]
    if oldArenaID and oldArenaID ~= arenaID then
        newArenaToToken[oldArenaID] = nil
    end

    newArenaToToken[arenaID] = token
    newTokenToArena[token] = arenaID
    return true
end

local function mappingsDiffer(a, b)
    for k, v in pairs(a) do
        if b[k] ~= v then
            return true
        end
    end
    for k, v in pairs(b) do
        if a[k] ~= v then
            return true
        end
    end
    return false
end

function Helper:ClearMappings()
    wipe(self.arenaToToken)
    wipe(self.tokenToArena)
end

function Helper:GetArenaToken(arenaID)
    return self.arenaToToken[arenaID]
end

function Helper:GetArenaIDFromToken(token)
    token = isNameplateToken(token)
    if not token then
        return nil
    end
    return self.tokenToArena[token]
end

local function getArenaUnit(arenaID)
    arenaID = asPublicNumber(arenaID)
    if not arenaID or arenaID < 1 or arenaID > 3 then
        return nil
    end

    return "arena" .. arenaID
end

function Helper:GetPlateFrameByToken(token)
    return self:GetPlateFrameByUnit(token)
end

function Helper:GetPlateFrameByUnit(unit)
    unit = asPublicString(unit)
    if not unit then
        return nil
    end

    local directPlate = safeCall(C_NamePlate.GetNamePlateForUnit, unit)
    if type(directPlate) == "table" then
        if unit:match("^arena%d+$") or isNameplateToken(unit) then
            if getValidatedTokenForUnitFromPlate(unit, directPlate) then
                return directPlate
            end
        else
            return directPlate
        end
    end

    local token = isNameplateToken(unit)
    if not token then
        return nil
    end

    local plates = getVisiblePlates()
    if not plates then
        return nil
    end

    for _, plate in ipairs(plates) do
        if getNameplateTokenFromPlate(plate) == token then
            return plate
        end
    end

    return nil
end

function Helper:GetPlateFrameByArenaID(arenaID)
    local arenaUnit = getArenaUnit(arenaID)
    if arenaUnit and safeUnitExists(arenaUnit) then
        local directPlate = self:GetPlateFrameByUnit(arenaUnit)
        if directPlate then
            return directPlate
        end
    end

    local token = self:GetArenaToken(arenaID)
    if not token then
        return nil
    end
    return self:GetPlateFrameByToken(token)
end

function Helper:GetAnchorParentByArenaID(arenaID)
    local arenaUnit = getArenaUnit(arenaID)
    if arenaUnit and safeUnitExists(arenaUnit) then
        local directParent = self:GetAnchorParentByUnit(arenaUnit)
        if directParent then
            return directParent
        end
    end

    local token = self:GetArenaToken(arenaID)
    if not token then
        return nil
    end

    return self:GetAnchorParentByUnit(token)
end

function Helper:GetAnchorParentByUnit(unit)
    local plate = self:GetPlateFrameByUnit(unit)
    if type(plate) ~= "table" then
        return nil
    end

    local token = isNameplateToken(unit) or getNameplateTokenFromPlate(plate)
    local adapters = getNameplateAdapters()
    if adapters and type(adapters.ResolveAnchorParent) == "function" then
        local resolvedParent = safeCall(adapters.ResolveAnchorParent, adapters, plate, token)
        if type(resolvedParent) == "table" then
            return resolvedParent
        end
    end

    return getDefaultAnchorParentFromPlate(plate)
end

function Helper:GetVisibleEnemyNameplates()
    local results = {}
    local plates = getVisiblePlates()
    if not plates then
        return results
    end

    local seenTokens = {}
    local adapters = getNameplateAdapters()
    for _, plate in ipairs(plates) do
        local token = getNameplateTokenFromPlate(plate)
        if token and not seenTokens[token] and isAttackableNameplateToken(token) then
            local parent
            if adapters and type(adapters.ResolveAnchorParent) == "function" then
                parent = safeCall(adapters.ResolveAnchorParent, adapters, plate, token)
            end
            if type(parent) ~= "table" then
                parent = getDefaultAnchorParentFromPlate(plate)
            end

            if type(parent) == "table" then
                seenTokens[token] = true
                table.insert(results, {
                    token = token,
                    guid = safeUnitGUID(token),
                    name = safeUnitName(token),
                    plate = plate,
                    parent = parent,
                })
            end
        end
    end

    return results
end

function Helper:RegisterCallback(owner, func)
    if not owner or type(func) ~= "function" then
        return
    end
    self.callbacks[owner] = func
end

function Helper:UnregisterCallback(owner)
    self.callbacks[owner] = nil
end

function Helper:NotifyUpdated()
    for owner, func in pairs(self.callbacks) do
        local ok = pcall(func, owner, self)
        if not ok then
            -- ignore callback errors
        end
    end
end

function Helper:RefreshMappings()
    if not isInArenaInstance() then
        if next(self.arenaToToken) ~= nil then
            self:ClearMappings()
            self:NotifyUpdated()
        end
        return
    end

    local plates = getVisiblePlates()
    if not plates then
        return
    end

    local arenaGUIDByID = {}
    local arenaNameByID = {}
    local arenaClassByID = {}

    for arenaID = 1, 3 do
        local arenaUnit = "arena" .. arenaID
        if safeUnitExists(arenaUnit) then
            arenaGUIDByID[arenaID] = safeUnitGUID(arenaUnit)
            arenaNameByID[arenaID] = safeUnitName(arenaUnit)
            arenaClassByID[arenaID] = safeUnitClassToken(arenaUnit)
        end
    end

    local enemyTokenSet = {}
    local enemyTokens = {}
    local classByToken = {}

    for _, plate in ipairs(plates) do
        local token = getNameplateTokenFromPlate(plate)
        if token then
            local classToken = safeUnitClassToken(token)
            if classToken and isEnemyPlayerToken(token) then
                enemyTokenSet[token] = true
                classByToken[token] = classToken
                table.insert(enemyTokens, token)
            end
        end
    end

    local newArenaToToken = {}
    local newTokenToArena = {}

    -- Keep still valid cached mappings
    for arenaID, token in pairs(self.arenaToToken) do
        if enemyTokenSet[token] then
            newArenaToToken[arenaID] = token
            newTokenToArena[token] = arenaID
        end
    end

    -- Prefer the arena unit directly so the mapping survives token churn
    -- from temporary effects like vanish or feign death.
    for arenaID = 1, 3 do
        if not newArenaToToken[arenaID] then
            local arenaUnit = getArenaUnit(arenaID)
            if arenaUnit and safeUnitExists(arenaUnit) then
                local directPlate = self:GetPlateFrameByUnit(arenaUnit)
                local directToken = getValidatedTokenForUnitFromPlate(arenaUnit, directPlate)
                if directToken and enemyTokenSet[directToken] then
                    tryMap(newArenaToToken, newTokenToArena, arenaID, directToken)
                end
            end
        end
    end

    -- Fast path fallback: GUID -> nameplate token
    for arenaID = 1, 3 do
        if not newArenaToToken[arenaID] then
            local guid = arenaGUIDByID[arenaID]
            if guid then
                local tokenFromGUID = isNameplateToken(asPublicString(safeCall(UnitTokenFromGUID, guid)))
                if tokenFromGUID and enemyTokenSet[tokenFromGUID] then
                    tryMap(newArenaToToken, newTokenToArena, arenaID, tokenFromGUID)
                end
            end
        end
    end

    -- Fallback: target / focus / mouseover bridge
    for _, refUnit in ipairs({ "target", "focus", "mouseover" }) do
        if safeUnitExists(refUnit) then
            local matchedToken = nil

            for _, token in ipairs(enemyTokens) do
                if safeUnitsMatch(token, refUnit) then
                    matchedToken = token
                    break
                end
            end

            if matchedToken then
                for arenaID = 1, 3 do
                    local arenaUnit = "arena" .. arenaID
                    if safeUnitExists(arenaUnit) and safeUnitsMatch(refUnit, arenaUnit) then
                        tryMap(newArenaToToken, newTokenToArena, arenaID, matchedToken)
                        break
                    end
                end
            end
        end
    end

    -- Fallback: unique name
    local unresolvedArenaIDsByName = {}
    local unresolvedTokensByName = {}

    for arenaID = 1, 3 do
        if not newArenaToToken[arenaID] then
            local name = arenaNameByID[arenaID]
            if name then
                unresolvedArenaIDsByName[name] = unresolvedArenaIDsByName[name] or {}
                table.insert(unresolvedArenaIDsByName[name], arenaID)
            end
        end
    end

    for _, token in ipairs(enemyTokens) do
        if not newTokenToArena[token] then
            local name = safeUnitName(token)
            if name then
                unresolvedTokensByName[name] = unresolvedTokensByName[name] or {}
                table.insert(unresolvedTokensByName[name], token)
            end
        end
    end

    for name, arenaIDs in pairs(unresolvedArenaIDsByName) do
        local tokens = unresolvedTokensByName[name]
        if type(arenaIDs) == "table" and #arenaIDs == 1 and type(tokens) == "table" and #tokens == 1 then
            tryMap(newArenaToToken, newTokenToArena, arenaIDs[1], tokens[1])
        end
    end

    -- Fallback: unique class
    local unresolvedArenaIDsByClass = {}
    local unresolvedTokensByClass = {}

    for arenaID = 1, 3 do
        if not newArenaToToken[arenaID] then
            local classToken = arenaClassByID[arenaID]
            if classToken then
                unresolvedArenaIDsByClass[classToken] = unresolvedArenaIDsByClass[classToken] or {}
                table.insert(unresolvedArenaIDsByClass[classToken], arenaID)
            end
        end
    end

    for _, token in ipairs(enemyTokens) do
        if not newTokenToArena[token] then
            local classToken = classByToken[token] or safeUnitClassToken(token)
            if classToken then
                unresolvedTokensByClass[classToken] = unresolvedTokensByClass[classToken] or {}
                table.insert(unresolvedTokensByClass[classToken], token)
            end
        end
    end

    for classToken, arenaIDs in pairs(unresolvedArenaIDsByClass) do
        local tokens = unresolvedTokensByClass[classToken]
        if type(arenaIDs) == "table" and #arenaIDs == 1 and type(tokens) == "table" and #tokens == 1 then
            tryMap(newArenaToToken, newTokenToArena, arenaIDs[1], tokens[1])
        end
    end

    -- Last fallback: if only one arena slot and one token remain
    local unresolvedArenaIDs = {}
    local unresolvedTokens = {}

    for arenaID = 1, 3 do
        if arenaClassByID[arenaID] and not newArenaToToken[arenaID] then
            table.insert(unresolvedArenaIDs, arenaID)
        end
    end

    for _, token in ipairs(enemyTokens) do
        if not newTokenToArena[token] then
            table.insert(unresolvedTokens, token)
        end
    end

    if #unresolvedArenaIDs == 1 and #unresolvedTokens == 1 then
        tryMap(newArenaToToken, newTokenToArena, unresolvedArenaIDs[1], unresolvedTokens[1])
    end

    if mappingsDiffer(self.arenaToToken, newArenaToToken) then
        wipe(self.arenaToToken)
        wipe(self.tokenToArena)

        for arenaID, token in pairs(newArenaToToken) do
            self.arenaToToken[arenaID] = token
        end
        for token, arenaID in pairs(newTokenToArena) do
            self.tokenToArena[token] = arenaID
        end

        self:NotifyUpdated()
    end
end

function Helper:QueueRefresh()
    if refreshQueued then
        return
    end

    refreshQueued = true
    C_Timer.After(0, function()
        refreshQueued = false
        Helper:RefreshMappings()
    end)
end

function Helper:QueueBurstRefresh()
    burstToken = burstToken + 1
    local thisBurstToken = burstToken

    for _, delay in ipairs(burstRefreshDelays) do
        C_Timer.After(delay, function()
            if thisBurstToken ~= burstToken then
                return
            end
            Helper:RefreshMappings()
        end)
    end
end

function Helper:OnEvent(event, unitToken)
    if event == "NAME_PLATE_UNIT_REMOVED" or event == "FORBIDDEN_NAME_PLATE_UNIT_REMOVED" then
        unitToken = isNameplateToken(unitToken)
        if unitToken then
            local arenaID = self.tokenToArena[unitToken]
            if arenaID then
                self.tokenToArena[unitToken] = nil
                self.arenaToToken[arenaID] = nil
                self:NotifyUpdated()
                self:QueueBurstRefresh()
            end
        end
        return
    end

    if event == "NAME_PLATE_UNIT_ADDED"
        or event == "FORBIDDEN_NAME_PLATE_UNIT_ADDED"
        or event == "ARENA_OPPONENT_UPDATE"
        or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "PLAYER_REGEN_ENABLED" then
        self:QueueBurstRefresh()
        return
    end

    if event == "PLAYER_TARGET_CHANGED"
        or event == "PLAYER_FOCUS_CHANGED"
        or event == "UPDATE_MOUSEOVER_UNIT" then
        self:QueueRefresh()
        return
    end
end

Helper:SetScript("OnEvent", function(self, event, ...)
    self:OnEvent(event, ...)
end)

Helper:RegisterEvent("PLAYER_ENTERING_WORLD")
Helper:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Helper:RegisterEvent("PLAYER_REGEN_ENABLED")
Helper:RegisterEvent("ARENA_OPPONENT_UPDATE")
Helper:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
Helper:RegisterEvent("PLAYER_TARGET_CHANGED")
Helper:RegisterEvent("PLAYER_FOCUS_CHANGED")
Helper:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
Helper:RegisterEvent("NAME_PLATE_UNIT_ADDED")
Helper:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_ADDED")
Helper:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
Helper:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_REMOVED")
