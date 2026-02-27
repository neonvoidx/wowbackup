local ADDON_NAME = ...
local C_NamePlate = _G.C_NamePlate
local C_Timer = _G.C_Timer
local CreateFrame = _G.CreateFrame
local IsAddOnLoaded = _G.IsAddOnLoaded
local issecure = _G.issecure
local UIParent = _G.UIParent
local EnumerateFrames = _G.EnumerateFrames
local UnitGUID = _G.UnitGUID
local UnitExists = _G.UnitExists
local UnitFullName = _G.UnitFullName
local UnitName = _G.UnitName
local UnitTokenFromGUID = _G.UnitTokenFromGUID
local securecallfunction = _G.securecallfunction
local issecretvalue = _G.issecretvalue

local defaults = {
    enabled = true,
    useBlizzardTray = true,
    enemyShowNameplates = true,
    enemyShowTargetFocus = false,
    enemyOpenWorldNameplates = false,
    enemyOpenWorldTargetFocus = false,
    enemyHideArenaTrays = false,
    iconBorderStyle = "solid",
    iconBorderThickness = 1.0,
    iconInfoTextStyle = "blizz",
    iconZoomEnabled = false,
    iconZoomPercent = 15,
    iconSpacing = 2,
    drCategoryIconOverrides = {},
    drCategoryVisibility = {},
    offsetX = 0,
    offsetY = 4,
    trayScale = 0.75,
    enemyDRMode = "nameplate",
    enemyTargetOffsetX = 0,
    enemyTargetOffsetY = 0,
    enemyFocusOffsetX = 0,
    enemyFocusOffsetY = 0,
    enemyTargetFocusTestMode = false,
    enemyTargetScale = 1.0,
    enemyFocusScale = 1.0,
    debug = false,
    experimentalTracking = false,
    friendlyTracking = true,
    friendlyOffsetX = 0,
    friendlyOffsetY = 0,
    friendlyPlayerSeparate = false,
    friendlyPlayerOffsetX = 0,
    friendlyPlayerOffsetY = 0,
    friendlyPlayerAnchor = "player",
    friendlyDirection = "left",
    playerDirection = "left",
    friendlyHidePlayerInGroup = true,
    friendlyTestMode = false,
    playerTestMode = false,
    logEnabled = true,
}

local db
local ticker
local testTray
local testTrays
local saveFrame
local nameplateEventFrame
local RestoreAllTrays
local GetNameplateToken
local ResolveTokenForPlate
local BuildArenaToNameplateMap
local GetEnemyDRMode
local IsInArena
local GetNameplateAnchorForEnemyTray
local GetConfiguredIcon
local logFrame
local logEditBox
local IsSecret
local ApplySettings
local DRList = _G.LibStub and _G.LibStub("DRList-1.0", true)

local enemyNameplateStates = {}
local enemyNameplateFrames = {}
local enemyOpenWorldNameplateFrames = {}
local enemyOpenWorldStates = {}
local enemyTargetFocusFrames = {}
local enemyModeTrayHidden = false
local enemyNameplateMapLogKey
local enemyTargetFocusMapLogKey
local enemyOpenWorldNameplateMapLogKey
local enemyOpenWorldTargetFocusMapLogKey
local enemyNameplateTokenByArenaIndex = {}
local enemyArenaIndexByNameplateToken = {}
local enemySpellNameToCategory

local ENEMY_DR_RESET_TIME = 16
local ENEMY_DR_ORDER = {
    "stun",
    "incap",
    "disorient",
    "silence",
    "disarm",
    "root",
}
local ENABLE_ARENA_NAME_FALLBACK = false
local TEST_CATEGORY_ICON_FALLBACK = {
    stun = "Interface\\Icons\\Ability_Rogue_CheapShot",
    incap = "Interface\\Icons\\Ability_Rogue_Sap",
    disorient = "Interface\\Icons\\Spell_Shadow_MindSteal",
    silence = "Interface\\Icons\\Ability_Rogue_Garrote",
    disarm = "Interface\\Icons\\Ability_Warrior_Disarm",
    root = "Interface\\Icons\\Spell_Nature_StrangleVines",
}

function FDR_NormalizePersistedDB()
    if type(FreshDRsDB) ~= "table" then
        return
    end
    local persist = FreshDRsDB._persist
    if type(persist) ~= "table" then
        return
    end
    for key, _ in pairs(defaults) do
        local persisted = persist[key]
        if persisted ~= nil and FreshDRsDB[key] ~= persisted then
            FreshDRsDB[key] = persisted
        end
    end
    db = FreshDRsDB
end

function FDR_RefreshDB()
    if type(_G.FreshDRsDB) == "table" then
        db = _G.FreshDRsDB
    end
end

local SafeSecureCall

function FDR_SafeCloneString(value)
    if type(value) ~= "string" then
        return nil
    end
    local okLen, len = pcall(string.len, value)
    if not okLen or type(len) ~= "number" then
        return nil
    end
    local okCopy, copy = pcall(string.sub, value, 1, len)
    if okCopy and type(copy) == "string" then
        return copy
    end
    return nil
end

function FDR_SafeGetField(obj, key)
    if not obj then
        return nil
    end
    local ok, value = pcall(function()
        return obj[key]
    end)
    if ok then
        local okBool = pcall(function()
            return not not value
        end)
        if not okBool then
            return nil
        end
        return value
    end
    return nil
end

function FDR_SafeUnitGUID(unit)
    if not unit or not UnitGUID then
        return nil
    end
    local ok, guid = SafeSecureCall(UnitGUID, unit)
    if not ok then
        return nil
    end
    if IsSecret(guid) then
        return nil
    end

    local okType, guidType = pcall(type, guid)
    if not okType or guidType ~= "string" then
        return nil
    end

    local okLen, len = pcall(string.len, guid)
    if not okLen or type(len) ~= "number" or len <= 0 then
        return nil
    end

    local okCopy, copy = pcall(string.sub, guid, 1, len)
    if okCopy and type(copy) == "string" then
        return copy
    end
    return nil
end

function FDR_SafeIsExactlyTrue(value)
    if IsSecret(value) then
        return false
    end
    local okEq, result = pcall(function()
        return value == true
    end)
    if not okEq or IsSecret(result) or type(result) ~= "boolean" then
        return false
    end
    return result == true
end

IsSecret = function(value)
    if type(issecretvalue) ~= "function" then
        return false
    end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == true
end

function FDR_SafeBool(value)
    if IsSecret(value) then
        return false
    end
    if type(value) == "boolean" then
        return value
    end
    local ok, coerced = pcall(function()
        return not not value
    end)
    if ok and type(coerced) == "boolean" and not IsSecret(coerced) then
        return coerced
    end
    return false
end

local function FDR_SafeNumber(value, fallback)
    local valueType = type(value)
    if valueType == "number" then
        if not IsSecret(value) then
            return value
        end
        return fallback
    end
    if valueType == "string" then
        local ok, num = pcall(tonumber, value)
        if ok and type(num) == "number" and not IsSecret(num) then
            return num
        end
    end
    return fallback
end

SafeSecureCall = function(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end
    if type(securecallfunction) == "function" then
        return pcall(securecallfunction, func, ...)
    end
    return pcall(func, ...)
end

function FDR_SafeUnitIsUnit(unitA, unitB)
    if not UnitIsUnit then
        return false
    end

    local ok, same = SafeSecureCall(UnitIsUnit, unitA, unitB)
    if ok then
        local boolSame = FDR_SafeBool(same)
        if boolSame then
            return true
        end
    end

    local okReverse, reverseSame = SafeSecureCall(UnitIsUnit, unitB, unitA)
    if not okReverse then
        return false
    end
    return FDR_SafeBool(reverseSame)
end

function FDR_SafeUnitExists(unit)
    if not UnitExists then
        return false
    end
    local ok, exists = SafeSecureCall(UnitExists, unit)
    if not ok then
        return false
    end
    return FDR_SafeBool(exists)
end

function FDR_HasUnitToken(unit)
    if FDR_SafeUnitExists(unit) then
        return true
    end
    local guid = FDR_SafeUnitGUID(unit)
    return type(guid) == "string"
end

function FDR_SafeUnitIsPlayer(unit)
    if not _G.UnitIsPlayer then
        return false
    end
    local ok, isPlayer = SafeSecureCall(_G.UnitIsPlayer, unit)
    if not ok then
        return false
    end
    return FDR_SafeBool(isPlayer)
end

function FDR_SafeUnitIsEnemy(unitA, unitB)
    if not _G.UnitIsEnemy then
        return false
    end
    local ok, isEnemy = SafeSecureCall(_G.UnitIsEnemy, unitA, unitB)
    if not ok then
        return false
    end
    return FDR_SafeBool(isEnemy)
end

function FDR_SafeUnitClassToken(unit)
    if not _G.UnitClass then
        return nil
    end
    local ok, _, classToken = SafeSecureCall(_G.UnitClass, unit)
    if not ok then
        return nil
    end
    return FDR_SafeCloneString(classToken)
end

function FDR_SafeUnitRaceName(unit)
    if not _G.UnitRace then
        return nil
    end
    local ok, raceName = SafeSecureCall(_G.UnitRace, unit)
    if not ok then
        return nil
    end
    return FDR_SafeCloneString(raceName)
end

function FDR_SafeUnitHonorLevel(unit)
    if not _G.UnitHonorLevel then
        return nil
    end
    local ok, honorLevel = SafeSecureCall(_G.UnitHonorLevel, unit)
    if not ok or type(honorLevel) ~= "number" then
        return nil
    end
    local okMath, n = pcall(function()
        return honorLevel + 0
    end)
    if not okMath or type(n) ~= "number" then
        return nil
    end
    return n
end

function FDR_BuildEnemyCompositeKey(unit)
    local honor = FDR_SafeUnitHonorLevel(unit)
    local classToken = FDR_SafeUnitClassToken(unit)
    local raceName = FDR_SafeUnitRaceName(unit)
    if type(honor) ~= "number" or type(classToken) ~= "string" or type(raceName) ~= "string" then
        return nil
    end
    return string.format("%d:%s:%s", honor, classToken, raceName)
end

function FDR_BuildEnemyCompositeKeyRaw(unit)
    if type(unit) ~= "string" then
        return nil
    end

    local honorLevel = FDR_SafeUnitHonorLevel(unit)
    local classToken = FDR_SafeUnitClassToken(unit)
    local raceName = FDR_SafeUnitRaceName(unit)
    if type(classToken) ~= "string" or classToken == "" then
        return nil
    end
    if type(raceName) ~= "string" or raceName == "" then
        return nil
    end
    if type(honorLevel) ~= "number" then
        honorLevel = 0
    end
    return string.format("%d:%s:%s", honorLevel, classToken, raceName)
end

function FDR_GetBestEnemyCompositeKey(unit)
    return FDR_BuildEnemyCompositeKey(unit) or FDR_BuildEnemyCompositeKeyRaw(unit)
end

function FDR_SafeSpellTexture(spellID)
    if type(spellID) ~= "number" then
        return nil
    end
    if _G.C_Spell and _G.C_Spell.GetSpellTexture then
        local ok, tex = pcall(_G.C_Spell.GetSpellTexture, spellID)
        if ok and not IsSecret(tex) and tex ~= nil then
            return tex
        end
    end
    if _G.GetSpellTexture then
        local ok, tex = pcall(_G.GetSpellTexture, spellID)
        if ok and not IsSecret(tex) and tex ~= nil then
            return tex
        end
    end
    return nil
end

function FDR_SafeSpellName(spellID)
    if type(spellID) ~= "number" then
        return nil
    end
    if _G.C_Spell and _G.C_Spell.GetSpellName then
        local ok, name = pcall(_G.C_Spell.GetSpellName, spellID)
        if ok and type(name) == "string" and not IsSecret(name) and #name > 0 then
            return name
        end
    end
    if _G.GetSpellInfo then
        local ok, name = pcall(_G.GetSpellInfo, spellID)
        if ok and type(name) == "string" and not IsSecret(name) and #name > 0 then
            return name
        end
    end
    return nil
end

function FDR_EnsureDRList()
    if DRList then
        return true
    end
    if not _G.LibStub then
        return false
    end
    local ok, lib = pcall(_G.LibStub, "DRList-1.0", true)
    if ok and lib then
        DRList = lib
        return true
    end
    return false
end

function FDR_IsAllowedNameplateLookupToken(unitToken)
    if type(unitToken) ~= "string" then
        return false
    end

    if unitToken == "player" or unitToken == "target" or unitToken == "focus" or unitToken == "mouseover" then
        return true
    end

    local ok, isNameplateToken = pcall(function()
        return string.match(unitToken, "^nameplate%d+$") ~= nil
    end)
    return ok and isNameplateToken == true
end

function FDR_SafeGetChildren(frame)
    if not (frame and frame.GetChildren) then
        return nil
    end
    local ok, children = pcall(function()
        return { frame:GetChildren() }
    end)
    if ok then
        return children
    end
    return nil
end

function FDR_SafeIndex(tbl, key)
    if not tbl then
        return nil
    end
    local ok, value = pcall(function()
        return tbl[key]
    end)
    if ok then
        local okBool = pcall(function()
            return not not value
        end)
        if not okBool then
            return nil
        end
        return value
    end
    return nil
end

function FDR_SafeType(value)
    local ok, t = pcall(type, value)
    if ok then
        return t
    end
    return nil
end

function FDR_SafeStringEquals(a, b)
    if a == nil or b == nil then
        return false
    end
    if IsSecret(a) or IsSecret(b) then
        return false
    end
    if type(a) == "string" and type(b) == "string" then
        local okDirect, sameDirect = pcall(function()
            return a == b
        end)
        if okDirect then
            return sameDirect == true
        end
        return false
    end

    local okA, sa = pcall(tostring, a)
    local okB, sb = pcall(tostring, b)
    if not okA or not okB or type(sa) ~= "string" or type(sb) ~= "string" then
        return false
    end
    local okFallback, sameFallback = pcall(function()
        return sa == sb
    end)
    return okFallback and sameFallback == true
end

function FDR_SafeFrameEquals(a, b)
    local ta, tb = type(a), type(b)
    if (ta ~= "table" and ta ~= "userdata") or (tb ~= "table" and tb ~= "userdata") then
        return false
    end
    local ok, same = pcall(function()
        return a == b
    end)
    return ok and same == true
end

function FDR_SafeIsObject(value)
    local t = FDR_SafeType(value)
    return t == "table" or t == "userdata"
end

function FDR_SafeIsTrue(value)
    if type(value) == "boolean" then
        return value
    end
    return false
end

function FDR_SafeIsForbidden(frame)
    if not frame or not frame.IsForbidden then
        return false
    end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    if ok and type(forbidden) == "boolean" then
        return forbidden
    end
    return false
end

function FDR_SafeCopyArray(tbl)
    if type(tbl) ~= "table" then
        return nil
    end
    local ok, copied = pcall(function()
        local out = {}
        for i = 1, #tbl do
            out[i] = tbl[i]
        end
        return out
    end)
    if ok then
        return copied
    end
    return nil
end

function FDR_GetAllNamePlates()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then
        return nil
    end

    local secure = (type(issecure) == "function") and issecure() or nil
    local candidates = {}

    local okSecure, securePlates = pcall(C_NamePlate.GetNamePlates, secure)
    if okSecure and type(securePlates) == "table" then
        candidates[#candidates + 1] = securePlates
    end

    local okTrue, truePlates = pcall(C_NamePlate.GetNamePlates, true)
    if okTrue and type(truePlates) == "table" then
        candidates[#candidates + 1] = truePlates
    end

    local okDefault, defaultPlates = pcall(C_NamePlate.GetNamePlates)
    if okDefault and type(defaultPlates) == "table" then
        candidates[#candidates + 1] = defaultPlates
    end

    if #candidates == 0 then
        return nil
    end

    local best = candidates[1]
    for i = 2, #candidates do
        if #candidates[i] > #best then
            best = candidates[i]
        end
    end
    return best
end

function FDR_NormalizeNameplateToken(unitToken)
    local token = unitToken
    if type(token) ~= "string" then
        local okToString, tokenString = pcall(tostring, token)
        if okToString and type(tokenString) == "string" then
            token = tokenString
        else
            return nil
        end
    end

    local ok, id = pcall(function()
        return string.match(token, "^nameplate(%d+)$")
    end)
    if ok and type(id) == "string" then
        return "nameplate" .. id
    end

    local okAlt, alt = pcall(function()
        return string.match(token, "^NamePlate(%d+)$") or string.match(token, "^ForbiddenNamePlate(%d+)$")
    end)
    if okAlt and type(alt) == "string" then
        return "nameplate" .. alt
    end
    return nil
end

function FDR_GetFrameNameplateToken(frame)
    if not (frame and frame.GetName) then
        return nil
    end
    local ok, frameName = pcall(frame.GetName, frame)
    if not ok or type(frameName) ~= "string" then
        return nil
    end
    local okMatch, id = pcall(function()
        return string.match(frameName, "^NamePlate(%d+)$") or string.match(frameName, "^ForbiddenNamePlate(%d+)$")
    end)
    if okMatch and type(id) == "string" then
        return "nameplate" .. id
    end

    local okToString, frameString = pcall(tostring, frame)
    if okToString and type(frameString) == "string" then
        local okFromString, idFromString = pcall(function()
            return string.match(frameString, "^NamePlate(%d+)$")
                or string.match(frameString, "^ForbiddenNamePlate(%d+)$")
                or string.match(frameString, "^NamePlate(%d+) ")
                or string.match(frameString, "^ForbiddenNamePlate(%d+) ")
        end)
        if okFromString and type(idFromString) == "string" then
            return "nameplate" .. idFromString
        end
    end
    return nil
end

function FDR_FindNameplateFrameByToken(unitToken)
    if type(unitToken) ~= "string" or not EnumerateFrames then
        return nil
    end
    local token = FDR_NormalizeNameplateToken(unitToken)
    if not token then
        return nil
    end
    local okId, id = pcall(function()
        return string.match(token, "^nameplate(%d+)$")
    end)
    if not okId or type(id) ~= "string" then
        return nil
    end

    local expectedA = "NamePlate" .. id
    local expectedB = "ForbiddenNamePlate" .. id
    local frame = EnumerateFrames()
    while frame do
        local okName, frameName = pcall(frame.GetName, frame)
        if okName and type(frameName) == "string" and (frameName == expectedA or frameName == expectedB) then
            return frame
        end
        frame = EnumerateFrames(frame)
    end
    return nil
end

function FDR_FindNameplateInListByToken(unitToken, plates)
    if type(unitToken) ~= "string" or type(plates) ~= "table" then
        return nil
    end
    local token = FDR_NormalizeNameplateToken(unitToken)
    if not token then
        return nil
    end

    for _, candidate in ipairs(plates) do
        local candidateToken = (ResolveTokenForPlate and ResolveTokenForPlate(candidate)) or FDR_NormalizeNameplateToken(GetNameplateToken(candidate) or FDR_GetFrameNameplateToken(candidate))
        if candidateToken and FDR_SafeStringEquals(candidateToken, token) then
            return candidate
        end
    end

    return nil
end

function FDR_GetNamePlateForUnitRaw(unitToken)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil
    end
    if type(unitToken) ~= "string" then
        return nil
    end
    -- Only query with explicit nameplate-capable tokens.
    if not FDR_IsAllowedNameplateLookupToken(unitToken) then
        return nil
    end

    if _G.NamePlateDriverFrame and _G.NamePlateDriverFrame.GetNamePlateForUnit then
        local okDriver, plateDriver = SafeSecureCall(function(frame, token)
            return frame:GetNamePlateForUnit(token)
        end, _G.NamePlateDriverFrame, unitToken)
        if okDriver and FDR_SafeIsObject(plateDriver) then
            return plateDriver
        end
    end

    local secure = (type(issecure) == "function") and issecure() or nil
    local okSecure, plateSecure = SafeSecureCall(C_NamePlate.GetNamePlateForUnit, unitToken, secure)
    if okSecure and FDR_SafeIsObject(plateSecure) then
        return plateSecure
    end

    local okDefault, plateDefault = SafeSecureCall(C_NamePlate.GetNamePlateForUnit, unitToken)
    if okDefault and FDR_SafeIsObject(plateDefault) then
        return plateDefault
    end

    return nil
end

function FDR_FindNameplateTokenForUnit(unitToken)
    if type(unitToken) ~= "string" or not UnitIsUnit then
        return nil
    end

    for i = 1, 40 do
        local probe = "nameplate" .. i
        -- Keep the nameplate token as first arg (works better with current secret gating).
        if FDR_SafeUnitIsUnit(probe, unitToken) then
            return probe
        end
    end

    return nil
end

function FDR_ResolveUnitTokenToNameplateToken(unitToken)
    if type(unitToken) ~= "string" then
        return nil
    end

    local normalized = FDR_NormalizeNameplateToken(unitToken)
    if normalized then
        return normalized
    end

    for i = 1, 40 do
        local probe = "nameplate" .. i
        if FDR_SafeUnitExists(probe) and FDR_SafeUnitIsUnit(probe, unitToken) then
            return probe
        end
    end

    return nil
end

local nameplateByToken = {}
local tokenByPlate = {}

function FDR_CacheNameplateByToken(unitToken, plate)
    local token = FDR_NormalizeNameplateToken(unitToken)
    if token and FDR_SafeIsObject(plate) then
        nameplateByToken[token] = plate
    end
end

local function ClearNameplateByToken(unitToken)
    local token = FDR_NormalizeNameplateToken(unitToken)
    if token then
        local plate = nameplateByToken[token]
        if plate then
            tokenByPlate[plate] = nil
        end
        nameplateByToken[token] = nil
        local index = enemyArenaIndexByNameplateToken[token]
        if index then
            enemyArenaIndexByNameplateToken[token] = nil
            if enemyNameplateTokenByArenaIndex[index] == token then
                enemyNameplateTokenByArenaIndex[index] = nil
            end
        end
    end
end

local function LinkArenaIndexToNameplateToken(index, token)
    if type(index) ~= "number" or index < 1 or index > 3 then
        return
    end
    local normalized = FDR_NormalizeNameplateToken(token)
    if not normalized then
        return
    end

    local prevToken = enemyNameplateTokenByArenaIndex[index]
    if prevToken and prevToken ~= normalized then
        enemyArenaIndexByNameplateToken[prevToken] = nil
    end

    local prevIndex = enemyArenaIndexByNameplateToken[normalized]
    if prevIndex and prevIndex ~= index then
        enemyNameplateTokenByArenaIndex[prevIndex] = nil
    end

    enemyNameplateTokenByArenaIndex[index] = normalized
    enemyArenaIndexByNameplateToken[normalized] = index
end

local function ClearArenaNameplateLinks()
    for i = 1, 3 do
        enemyNameplateTokenByArenaIndex[i] = nil
    end
    for token in pairs(enemyArenaIndexByNameplateToken) do
        enemyArenaIndexByNameplateToken[token] = nil
    end
end

local function RebuildNameplateTokenCache()
    for token in pairs(nameplateByToken) do
        nameplateByToken[token] = nil
    end
    for plate in pairs(tokenByPlate) do
        tokenByPlate[plate] = nil
    end

    local plates = FDR_GetAllNamePlates()
    if type(plates) ~= "table" then
        return
    end
    for _, plate in ipairs(plates) do
        local token = FDR_NormalizeNameplateToken(GetNameplateToken(plate) or FDR_GetFrameNameplateToken(plate))
        if type(token) == "string" then
            tokenByPlate[plate] = token
        end
        FDR_CacheNameplateByToken(token, plate)
    end
end

ResolveTokenForPlate = function(plate)
    if not FDR_SafeIsObject(plate) then
        return nil
    end

    local cached = tokenByPlate[plate]
    if type(cached) == "string" then
        return cached
    end

    local direct = FDR_NormalizeNameplateToken(GetNameplateToken(plate) or FDR_GetFrameNameplateToken(plate))
    if type(direct) == "string" then
        tokenByPlate[plate] = direct
        nameplateByToken[direct] = plate
        return direct
    end

    for i = 1, 40 do
        local token = "nameplate" .. i
        local mapped = FDR_GetNamePlateForUnitRaw(token)
        if FDR_SafeFrameEquals(mapped, plate) then
            tokenByPlate[plate] = token
            nameplateByToken[token] = plate
            return token
        end
    end

    return nil
end

local function GetNamePlateForToken(unitToken)
    if type(unitToken) ~= "string" then
        return nil
    end

    local nameplateToken = FDR_NormalizeNameplateToken(unitToken)
    if nameplateToken then
        local plateRaw = FDR_GetNamePlateForUnitRaw(nameplateToken)
        if FDR_SafeIsObject(plateRaw) then
            nameplateByToken[nameplateToken] = plateRaw
            return plateRaw
        end

        local cached = nameplateByToken[nameplateToken]
        if FDR_SafeIsObject(cached) then
            return cached
        end

        local plates = FDR_GetAllNamePlates()
        if type(plates) == "table" then
            local byToken = FDR_FindNameplateInListByToken(nameplateToken, plates)
            if FDR_SafeIsObject(byToken) then
                nameplateByToken[nameplateToken] = byToken
                return byToken
            end
        end

        local enumPlate = FDR_FindNameplateFrameByToken(nameplateToken)
        if FDR_SafeIsObject(enumPlate) then
            nameplateByToken[nameplateToken] = enumPlate
            return enumPlate
        end
    end

    local queryToken = nameplateToken or unitToken
    local plate = FDR_GetNamePlateForUnitRaw(queryToken)
    if FDR_SafeIsObject(plate) then
        if nameplateToken then
            nameplateByToken[nameplateToken] = plate
        end
        return plate
    end

    if nameplateToken then
        local plates = FDR_GetAllNamePlates()
        if type(plates) == "table" then
            local byToken = FDR_FindNameplateInListByToken(nameplateToken, plates)
            if FDR_SafeIsObject(byToken) then
                nameplateByToken[nameplateToken] = byToken
                return byToken
            end

            if UnitIsUnit then
                for _, candidate in ipairs(plates) do
                    local candidateToken = (ResolveTokenForPlate and ResolveTokenForPlate(candidate)) or GetNameplateToken(candidate)
                    if type(candidateToken) == "string" and FDR_SafeUnitIsUnit(nameplateToken, candidateToken) then
                        nameplateByToken[nameplateToken] = candidate
                        return candidate
                    end
                end
            end
        end

        local enumPlate = FDR_FindNameplateFrameByToken(nameplateToken)
        if FDR_SafeIsObject(enumPlate) then
            nameplateByToken[nameplateToken] = enumPlate
            return enumPlate
        end
    end

    return nil
end

local function IsPlatynatorLoaded()
    if type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Platynator") then
        return true
    end
    return type(_G.Platynator) == "table"
end

local platynatorManager

local function FindPlatynatorManager()
    if not (IsPlatynatorLoaded() and EnumerateFrames) then
        return nil
    end
    local frame = EnumerateFrames()
    while frame do
        local displays = FDR_SafeGetField(frame, "nameplateDisplays")
        local unitMap = FDR_SafeGetField(frame, "unitToNameplate")
        if type(displays) == "table" and type(unitMap) == "table" then
            return frame
        end
        frame = EnumerateFrames(frame)
    end
end

local function GetPlatynatorNameplate(unit)
    if not IsPlatynatorLoaded() then
        return nil
    end
    if not platynatorManager then
        platynatorManager = FindPlatynatorManager()
    end
    if not platynatorManager then
        return nil
    end
    local unitMap = FDR_SafeGetField(platynatorManager, "unitToNameplate")
    if type(unitMap) ~= "table" then
        return nil
    end
    return FDR_SafeIndex(unitMap, unit)
end

local function GetPlatynatorDisplay(unit)
    if not IsPlatynatorLoaded() then
        return nil
    end
    if not platynatorManager then
        platynatorManager = FindPlatynatorManager()
    end
    if not platynatorManager then
        return nil
    end
    local displays = FDR_SafeGetField(platynatorManager, "nameplateDisplays")
    if type(displays) ~= "table" then
        return nil
    end
    return FDR_SafeIndex(displays, unit)
end

GetNameplateToken = function(plate)
    if not FDR_SafeIsObject(plate) then
        return nil
    end
    local token
    local okToken1, token1 = pcall(function()
        return plate.namePlateUnitToken
    end)
    if okToken1 then
        token = token1
    end
    if FDR_SafeType(token) ~= "string" then
        local okToken2, token2 = pcall(function()
            return plate.unitToken
        end)
        if okToken2 then
            token = token2
        end
    end
    if FDR_SafeType(token) ~= "string" then
        local uf = FDR_SafeGetField(plate, "UnitFrame")
        if FDR_SafeIsObject(uf) then
            local okToken3, token3 = pcall(function()
                return uf.unit
            end)
            if okToken3 then
                token = token3
            end
        end
    end
    if FDR_SafeType(token) ~= "string" and plate and plate.GetUnit then
        local ok, methodToken = pcall(plate.GetUnit, plate)
        if ok then
            token = methodToken
        end
    end
    if FDR_SafeType(token) == "string" then
        return token
    end
    return nil
end

local function IsDisplayFrame(frame)
    return frame and FDR_SafeGetField(frame, "widgets") and FDR_SafeGetField(frame, "InitializeWidgets") and FDR_SafeGetField(frame, "SetUnit")
end

local function FindPlatynatorDisplay(nameplate)
    if IsDisplayFrame(nameplate) then
        return nameplate
    end
    for _, child in ipairs(FDR_SafeGetChildren(nameplate) or {}) do
        if IsDisplayFrame(child) then
            return child
        end
        for _, grand in ipairs(FDR_SafeGetChildren(child) or {}) do
            if IsDisplayFrame(grand) then
                return grand
            end
        end
    end
    local unitFrame = nameplate and FDR_SafeGetField(nameplate, "UnitFrame")
    if unitFrame then
        if IsDisplayFrame(unitFrame) then
            return unitFrame
        end
        for _, child in ipairs(FDR_SafeGetChildren(unitFrame) or {}) do
            if IsDisplayFrame(child) then
                return child
            end
        end
    end
end

local function FindHealthBar(display)
    local widgets = display and FDR_SafeGetField(display, "widgets")
    if FDR_SafeType(widgets) ~= "table" then
        return nil
    end
    for _, w in ipairs(widgets) do
        local kind = FDR_SafeGetField(w, "kind")
        if FDR_SafeType(kind) == "string" and kind == "bars" then
            local details = FDR_SafeGetField(w, "details")
            if FDR_SafeType(details) == "table" then
                local detailKind = FDR_SafeGetField(details, "kind")
                if FDR_SafeType(detailKind) == "string" and detailKind == "health" then
                    local statusBar = FDR_SafeGetField(w, "statusBar")
                    if FDR_SafeIsObject(statusBar) then
                        return statusBar
                    end
                end
            end
        end
    end
end

local function IsPlatynatorHealthBar(frame)
    local details = FDR_SafeGetField(frame, "details")
    if FDR_SafeType(details) ~= "table" then
        return false
    end
    local kind = FDR_SafeGetField(details, "kind")
    return FDR_SafeType(kind) == "string" and kind == "health"
end

local function FindHealthBarInTree(root)
    if not root then
        return nil
    end
    local seen = {}
    local stack = { root }
    while #stack > 0 do
        local frame = table.remove(stack)
        if frame and not seen[frame] then
            seen[frame] = true
            local details = FDR_SafeGetField(frame, "details")
            if FDR_SafeType(details) == "table" then
                local kind = FDR_SafeGetField(details, "kind")
                if FDR_SafeType(kind) == "string" and kind == "health" then
                    local statusBar = FDR_SafeGetField(frame, "statusBar")
                    if FDR_SafeIsObject(statusBar) then
                        return frame
                    end
                end
            end
            local children = FDR_SafeGetChildren(frame)
            if children then
                for _, child in ipairs(children) do
                    table.insert(stack, child)
                end
            end
        end
    end
end

local function SafeGetObjectType(frame)
    if not (frame and frame.GetObjectType) then
        return nil
    end
    local ok, objectType = pcall(frame.GetObjectType, frame)
    if ok and type(objectType) == "string" then
        return objectType
    end
    return nil
end

local function SafeGetFrameName(frame)
    if not (frame and frame.GetName) then
        return nil
    end
    local ok, name = pcall(frame.GetName, frame)
    if ok and type(name) == "string" then
        return name
    end
    return nil
end

local function SafeGetFrameWidth(frame)
    if not (frame and frame.GetWidth) then
        return nil
    end
    local ok, width = pcall(frame.GetWidth, frame)
    if ok and type(width) == "number" then
        return width
    end
    return nil
end

local function FindStatusBarInTree(root)
    if not FDR_SafeIsObject(root) then
        return nil
    end

    local seen = {}
    local queue = { root }
    local fallback = nil

    while #queue > 0 do
        local frame = table.remove(queue, 1)
        if frame and not seen[frame] then
            seen[frame] = true

            if SafeGetObjectType(frame) == "StatusBar" then
                local name = SafeGetFrameName(frame)
                local lowerName = name and string.lower(name) or nil
                if lowerName and (string.find(lowerName, "health", 1, true) or string.find(lowerName, "hp", 1, true)) then
                    return frame
                end

                local width = SafeGetFrameWidth(frame)
                if not fallback and width and width >= 30 then
                    fallback = frame
                end
            end

            local children = FDR_SafeGetChildren(frame)
            if children then
                for _, child in ipairs(children) do
                    queue[#queue + 1] = child
                end
            end
        end
    end

    return fallback
end

local function InitDB()
    if type(_G.FreshDRsDB) ~= "table" and type(_G.NameplateDRsDB) == "table" then
        _G.FreshDRsDB = {}
        for k, v in pairs(_G.NameplateDRsDB) do
            _G.FreshDRsDB[k] = v
        end
    end

    FreshDRsDB = FreshDRsDB or {}
    if type(FreshDRsDB._persist) ~= "table" then
        FreshDRsDB._persist = {}
    end

    -- One-time migration from old ad-hoc persist keys.
    local legacyPersistMap = {
        enemyDRModePersist = "enemyDRMode",
        offsetXPersist = "offsetX",
        offsetYPersist = "offsetY",
        trayScalePersist = "trayScale",
    }
    for legacyKey, key in pairs(legacyPersistMap) do
        if FreshDRsDB[legacyKey] ~= nil and FreshDRsDB._persist[key] == nil then
            FreshDRsDB._persist[key] = FreshDRsDB[legacyKey]
        end
    end

    if FreshDRsDB.enemyShowNameplates == nil and FreshDRsDB.enemyShowTargetFocus == nil then
        if FreshDRsDB.enemyDRMode == "targetfocus" then
            FreshDRsDB.enemyShowNameplates = false
            FreshDRsDB.enemyShowTargetFocus = true
        elseif FreshDRsDB.enemyDRMode == "off" then
            FreshDRsDB.enemyShowNameplates = false
            FreshDRsDB.enemyShowTargetFocus = false
        else
            FreshDRsDB.enemyShowNameplates = true
            FreshDRsDB.enemyShowTargetFocus = false
        end
    end

    if FreshDRsDB.enemyOpenWorldNameplates == nil and FreshDRsDB.experimentalTracking == true then
        FreshDRsDB.enemyOpenWorldNameplates = true
        FreshDRsDB.experimentalTracking = false
    end
    if type(FreshDRsDB._persist) == "table" and FreshDRsDB._persist.enemyOpenWorldNameplates == nil and FreshDRsDB._persist.experimentalTracking == true then
        FreshDRsDB._persist.enemyOpenWorldNameplates = true
        FreshDRsDB._persist.experimentalTracking = false
    end

    for key, value in pairs(defaults) do
        if FreshDRsDB[key] == nil then
            FreshDRsDB[key] = value
        end
        if FreshDRsDB._persist[key] == nil then
            FreshDRsDB._persist[key] = FreshDRsDB[key]
        end
    end
    if type(FreshDRsDB.drCategoryIconOverrides) ~= "table" then
        FreshDRsDB.drCategoryIconOverrides = {}
    end
    if type(FreshDRsDB._persist.drCategoryIconOverrides) ~= "table" then
        FreshDRsDB._persist.drCategoryIconOverrides = {}
    end
    if type(FreshDRsDB.drCategoryVisibility) ~= "table" then
        FreshDRsDB.drCategoryVisibility = {}
    end
    if type(FreshDRsDB._persist.drCategoryVisibility) ~= "table" then
        FreshDRsDB._persist.drCategoryVisibility = {}
    end
    do
        local allHidden = true
        for _, category in ipairs(ENEMY_DR_ORDER) do
            if FreshDRsDB.drCategoryVisibility[category] ~= false then
                allHidden = false
                break
            end
        end
        if allHidden then
            FreshDRsDB.drCategoryVisibility = {}
            FreshDRsDB._persist.drCategoryVisibility = {}
        end
    end
    if FreshDRsDB.enemyTargetScale == nil then
        FreshDRsDB.enemyTargetScale = 1.0
    end
    if FreshDRsDB.enemyFocusScale == nil then
        FreshDRsDB.enemyFocusScale = 1.0
    end
    if FreshDRsDB.playerDirection == nil then
        FreshDRsDB.playerDirection = "left"
    end
    if FreshDRsDB.iconBorderStyle == "quick" then
        FreshDRsDB.iconBorderStyle = "solid"
    end
    if FreshDRsDB._persist and FreshDRsDB._persist.iconBorderStyle == "quick" then
        FreshDRsDB._persist.iconBorderStyle = "solid"
    end
    if FreshDRsDB.iconInfoTextStyle == "modern_coloured" then
        FreshDRsDB.iconInfoTextStyle = "modern_colored"
    end
    if FreshDRsDB._persist and FreshDRsDB._persist.iconInfoTextStyle == "modern_coloured" then
        FreshDRsDB._persist.iconInfoTextStyle = "modern_colored"
    end
    FDR_NormalizePersistedDB()
    db = FreshDRsDB
end

local function SaveDB()
    if not db then
        return
    end
    FreshDRsDB = db
end

local function SetDBValue(key, value)
    if not db then
        InitDB()
    end
    if type(FreshDRsDB) ~= "table" then
        FreshDRsDB = {}
    end
    if type(FreshDRsDB._persist) ~= "table" then
        FreshDRsDB._persist = {}
    end
    FreshDRsDB[key] = value
    if defaults[key] ~= nil then
        FreshDRsDB._persist[key] = value
    end
    db = FreshDRsDB
    SaveDB()
end

local arenaLog = {
    sessions = {},
    current = nil,
    nextId = 1,
    inArena = false,
    anchorState = {},
}

local function SafeToText(value)
    if value == nil then
        return "nil"
    end

    local valueType = type(value)
    if valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "number" then
        local okNum, numText = pcall(tostring, value)
        if okNum and type(numText) == "string" then
            return numText
        end
        return "<num>"
    elseif valueType == "string" then
        local okLen, len = pcall(string.len, value)
        if not okLen or type(len) ~= "number" then
            return "<secret>"
        end
        local okCopy, copy = pcall(string.sub, value, 1, len)
        if okCopy and type(copy) == "string" then
            return copy
        end
        return "<secret>"
    end

    local ok, text = pcall(tostring, value)
    if ok and type(text) == "string" then
        local okLen = pcall(string.len, text)
        if okLen then
            return text
        end
        return "<secret>"
    end
    return "<err>"
end

local function IsArenaLoggingEnabled()
    return db and db.logEnabled ~= false
end

local function ArenaLogLine(message)
    if not IsArenaLoggingEnabled() then
        return
    end
    if not arenaLog.current then
        return
    end
    local now = date("%H:%M:%S")
    local line = string.format("[%s] %s", now, message)
    local entries = arenaLog.current.entries
    entries[#entries + 1] = line
    if #entries > 600 then
        table.remove(entries, 1)
    end
end

local function ArenaLogf(fmt, ...)
    local ok, text = pcall(string.format, fmt, ...)
    if not ok then
        text = "format_error"
    end
    ArenaLogLine(text)
end

local function StartArenaLogSession(reason)
    if not IsArenaLoggingEnabled() then
        return
    end

    local session = {
        id = arenaLog.nextId,
        started = date("%Y-%m-%d %H:%M:%S"),
        reason = reason or "unknown",
        entries = {},
    }
    arenaLog.nextId = arenaLog.nextId + 1
    arenaLog.current = session
    arenaLog.anchorState = {}
    table.insert(arenaLog.sessions, 1, session)
    while #arenaLog.sessions > 20 do
        table.remove(arenaLog.sessions)
    end
    ArenaLogf("session-start reason=%s mode=%s", SafeToText(reason), SafeToText(GetEnemyDRMode and GetEnemyDRMode() or "unknown"))
end

local function EndArenaLogSession(reason)
    if not arenaLog.current then
        return
    end
    ArenaLogf("session-end reason=%s", SafeToText(reason))
    arenaLog.current = nil
    arenaLog.anchorState = {}
end

local function UpdateArenaLogSessionState()
    local inArena = IsInArena()
    if inArena and not arenaLog.inArena then
        StartArenaLogSession("entered-arena")
    elseif not inArena and arenaLog.inArena then
        EndArenaLogSession("left-arena")
    end
    arenaLog.inArena = inArena
end

local function BuildArenaLogText()
    if #arenaLog.sessions == 0 then
        return "No arena logs captured yet."
    end

    local out = {}
    for i, session in ipairs(arenaLog.sessions) do
        out[#out + 1] = string.format("=== Arena Log %d (id=%s, started=%s, reason=%s) ===", i, SafeToText(session.id), SafeToText(session.started), SafeToText(session.reason))
        for _, line in ipairs(session.entries) do
            out[#out + 1] = line
        end
        out[#out + 1] = ""
    end
    return table.concat(out, "\n")
end

local function ShowArenaLogWindow(text)
    if not logFrame then
        logFrame = CreateFrame("Frame", "FreshDRsLogWindow", UIParent, "BackdropTemplate")
        logFrame:SetSize(900, 560)
        logFrame:SetPoint("CENTER")
        logFrame:SetFrameStrata("DIALOG")
        logFrame:SetMovable(true)
        logFrame:EnableMouse(true)
        logFrame:RegisterForDrag("LeftButton")
        logFrame:SetScript("OnDragStart", logFrame.StartMoving)
        logFrame:SetScript("OnDragStop", logFrame.StopMovingOrSizing)
        logFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })

        local title = logFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 16, -16)
        title:SetText("Fresh DRs Arena Log (copy)")

        local close = CreateFrame("Button", nil, logFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -4, -4)

        local scroll = CreateFrame("ScrollFrame", nil, logFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 14, -42)
        scroll:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -34, 14)

        logEditBox = CreateFrame("EditBox", nil, scroll)
        logEditBox:SetMultiLine(true)
        logEditBox:SetFontObject(ChatFontNormal)
        logEditBox:SetWidth(840)
        logEditBox:SetAutoFocus(false)
        logEditBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        scroll:SetScrollChild(logEditBox)
    end

    if logEditBox then
        logEditBox:SetText(text or "")
        logEditBox:HighlightText()
        logEditBox:SetFocus()
    end
    logFrame:Show()
end

local function DebugPrint(...)
    if db and db.debug then
        print("Nameplate DRs:", ...)
    end
end

IsInArena = function()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function GetArenaTray(index)
    local frame = _G["CompactArenaFrameMember" .. index]
    if frame and frame.SpellDiminishStatusTray then
        return frame.SpellDiminishStatusTray
    end
    return nil
end

local function NormalizeName(name)
    if type(name) ~= "string" then
        return nil
    end
    local ok, normalized = pcall(function()
        if string.len(name) <= 0 then
            return nil
        end
        local base = name
        local dash = string.find(base, "-", 1, true)
        if dash and dash > 1 then
            base = string.sub(base, 1, dash - 1)
        end
        return string.lower(base)
    end)
    if ok then
        return normalized
    end
    return nil
end

local function GetNormalizedUnitName(unit)
    if not UnitName then
        return nil
    end
    local ok, name = pcall(UnitName, unit)
    if not ok or IsSecret(name) or type(name) ~= "string" then
        return nil
    end
    return NormalizeName(name)
end

local function GetTextFromFontString(fontString)
    if not fontString or not fontString.GetText then
        return nil
    end
    local ok, text = pcall(fontString.GetText, fontString)
    if not ok then
        return nil
    end
    local okText, safeText = pcall(function()
        if type(text) ~= "string" then
            return nil
        end
        if string.len(text) <= 0 then
            return nil
        end
        return text
    end)
    if okText then
        return safeText
    end
    return nil
end

local function GetArenaDisplayName(index)
    local frame = _G["CompactArenaFrameMember" .. index]
    local frameName = frame and FDR_SafeGetField(frame, "name")
    local text = GetTextFromFontString(frameName)
    if text then
        return text
    end

    if UnitName then
        local ok, unitName = pcall(UnitName, "arena" .. index)
        if ok and type(unitName) == "string" then
            return unitName
        end
    end
    return nil
end

local function GetPlateAnchor(plate)
    if not plate then
        return nil
    end
    if IsPlatynatorLoaded() then
        local display = FindPlatynatorDisplay(plate)
        if FDR_SafeIsObject(display) then
            local bar = FindHealthBar(display) or FindHealthBarInTree(display)
            if FDR_SafeIsObject(bar) then
                return bar
            end
        end
        local fallback = FindHealthBarInTree(plate)
        if FDR_SafeIsObject(fallback) then
            return fallback
        end
    end
    local unitFrame = FDR_SafeGetField(plate, "UnitFrame")
    if FDR_SafeIsObject(unitFrame) then
        local healthBar = FDR_SafeGetField(unitFrame, "healthBar")
        if FDR_SafeIsObject(healthBar) then
            return healthBar
        end
    end

    -- Plater support (common frame fields in Plater nameplates).
    local platerUnitFrame = FDR_SafeGetField(plate, "unitFrame") or FDR_SafeGetField(plate, "PlaterUnitFrame")
    if FDR_SafeIsObject(platerUnitFrame) then
        local platerHealthBar = FDR_SafeGetField(platerUnitFrame, "healthBar") or FDR_SafeGetField(platerUnitFrame, "HealthBar")
        if FDR_SafeIsObject(platerHealthBar) then
            return platerHealthBar
        end

        local platerTreeBar = FindStatusBarInTree(platerUnitFrame)
        if FDR_SafeIsObject(platerTreeBar) then
            return platerTreeBar
        end
    end

    local treeStatusBar = FindStatusBarInTree(plate)
    if FDR_SafeIsObject(treeStatusBar) then
        return treeStatusBar
    end

    return unitFrame or platerUnitFrame or plate
end

local function GetAnchorParent(anchor, plate, fallback)
    local parent = fallback
    if anchor and anchor.GetParent then
        parent = anchor:GetParent() or parent
    end
    if FDR_SafeIsForbidden(parent) then
        return plate or anchor
    end
    return parent or anchor
end

local function ShouldAnchorInUIParent(anchor)
    if not FDR_SafeIsObject(anchor) then
        return false
    end
    return FDR_SafeFrameEquals(anchor, _G.TargetFrame) or FDR_SafeFrameEquals(anchor, _G.FocusFrame)
end

local function LogArenaAnchorState(index, hasAnchor, source, details)
    if not (IsArenaLoggingEnabled() and arenaLog.current and arenaLog.inArena) then
        return
    end
    local mode = GetEnemyDRMode and GetEnemyDRMode() or "unknown"
    local key = string.format(
        "%s|%s|%s|%s",
        SafeToText(mode),
        hasAnchor and "yes" or "no",
        SafeToText(source),
        SafeToText(details)
    )
    if arenaLog.anchorState[index] == key then
        return
    end
    arenaLog.anchorState[index] = key
    if hasAnchor then
        ArenaLogf("arena%d anchor=yes src=%s mode=%s", index, SafeToText(source), SafeToText(mode))
    else
        ArenaLogf("arena%d anchor=no src=%s mode=%s %s", index, SafeToText(source), SafeToText(mode), SafeToText(details))
    end
end

local function GetArenaAnchor(index)
    local arenaUnit = "arena" .. index
    local mapToken = nil

    if BuildArenaToNameplateMap then
        local mapping = BuildArenaToNameplateMap()
        mapToken = mapping and mapping[index] or nil
    end

    local function ResolveFromNameplateToken(nameplateToken, source)
        if type(nameplateToken) ~= "string" then
            return nil
        end
        local plate = GetNamePlateForToken(nameplateToken)
        if not FDR_SafeIsObject(plate) then
            return nil
        end
        local anchor = GetPlateAnchor(plate)
        if FDR_SafeIsObject(anchor) then
            LogArenaAnchorState(index, true, source)
            return anchor, plate, source
        end
        LogArenaAnchorState(index, true, source)
        return plate, plate, source
    end

    local anchor, plate, source = ResolveFromNameplateToken(mapToken, "map-token")
    if anchor then
        return anchor, plate, source
    end

    local unitMatchToken = FDR_FindNameplateTokenForUnit(arenaUnit)
    if not unitMatchToken then
        unitMatchToken = FDR_ResolveUnitTokenToNameplateToken(arenaUnit)
    end
    anchor, plate, source = ResolveFromNameplateToken(unitMatchToken, "unitisunit-token")
    if anchor then
        return anchor, plate, source
    end

    local guid = FDR_SafeUnitGUID(arenaUnit)
    if guid and UnitTokenFromGUID then
        local okTok, unitToken = pcall(UnitTokenFromGUID, guid)
        if okTok then
            local normalized = FDR_ResolveUnitTokenToNameplateToken(unitToken)
            anchor, plate, source = ResolveFromNameplateToken(normalized, "guid-token")
            if anchor then
                return anchor, plate, source
            end
        end
    end

    local display = GetPlatynatorDisplay(arenaUnit)
    if FDR_SafeIsObject(display) then
        local bar = FindHealthBar(display) or FindHealthBarInTree(display)
        if FDR_SafeIsObject(bar) then
            local border = FDR_SafeGetField(bar, "border")
            if FDR_SafeIsObject(border) then
                LogArenaAnchorState(index, true, "platynator-bar")
                return border, display, "platynator-bar"
            end
            LogArenaAnchorState(index, true, "platynator-bar")
            return bar, display, "platynator-bar"
        end
        LogArenaAnchorState(index, true, "platynator-display")
        return display, display, "platynator-display"
    end

    local plateCount = 0
    local list = FDR_GetAllNamePlates()
    if type(list) == "table" then
        plateCount = #list
    end
    local guidToken = nil
    if guid and UnitTokenFromGUID then
        local okGuidTok, value = pcall(UnitTokenFromGUID, guid)
        if okGuidTok then
            guidToken = value
        end
    end
    local detail = string.format(
        "mapTok=%s unitTok=%s guidTok=%s plates=%s",
        SafeToText(mapToken),
        SafeToText(unitMatchToken),
        SafeToText(guidToken),
        SafeToText(plateCount)
    )
    LogArenaAnchorState(index, false, "none", detail)
    return nil, nil, "none"
end

local function IsEnemyNameplateEnabled()
    if not db then
        return true
    end
    return db.enemyShowNameplates ~= false
end

local function IsEnemyTargetFocusEnabled()
    if not db then
        return false
    end
    return db.enemyShowTargetFocus == true
end

local function IsEnemyOpenWorldNameplateEnabled()
    return IsEnemyNameplateEnabled()
end

local function IsEnemyOpenWorldTargetFocusEnabled()
    return IsEnemyTargetFocusEnabled()
end

local function IsInBattleground()
    local _, instanceType = IsInInstance()
    return instanceType == "pvp"
end

local function GetEnemyRoutingState()
    local inArena = IsInArena()
    local inBattleground = IsInBattleground()

    -- Enemy DR routing now uses one unified toggle set across arena/bg/open world.
    local showNameplate = IsEnemyNameplateEnabled()
    local showTargetFocus = IsEnemyTargetFocusEnabled()

    local context
    if inArena then
        context = "arena"
    elseif inBattleground then
        context = "battleground"
    else
        context = "world"
    end

    return {
        inArena = inArena,
        inBattleground = inBattleground,
        context = context,
        showNameplate = showNameplate,
        showTargetFocus = showTargetFocus,
    }
end

GetEnemyDRMode = function()
    local route = GetEnemyRoutingState()
    local nameplateEnabled = route.showNameplate
    local targetFocusEnabled = route.showTargetFocus
    if nameplateEnabled and targetFocusEnabled then
        return route.context .. ":both"
    elseif nameplateEnabled then
        return route.context .. ":nameplate"
    elseif targetFocusEnabled then
        return route.context .. ":targetfocus"
    end
    return route.context .. ":off"
end

local function GetTestAnchor()
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil, "none", nil
    end
    local units = { "target", "mouseover", "focus" }
    for _, unit in ipairs(units) do
        local plate = GetNamePlateForToken(unit)
        if FDR_SafeIsObject(plate) then
            local anchor = GetNameplateAnchorForEnemyTray(plate)
            if FDR_SafeIsObject(anchor) then
                local source = "nameplate"
                local unitFrame = FDR_SafeGetField(plate, "UnitFrame")
                local platerUnitFrame = FDR_SafeGetField(plate, "unitFrame") or FDR_SafeGetField(plate, "PlaterUnitFrame")
                if FDR_SafeIsObject(platerUnitFrame) then
                    source = "plater"
                elseif FDR_SafeIsObject(unitFrame) then
                    source = "blizzard"
                end
                return anchor, source, plate
            end
        end
    end
    return nil, "none", nil
end

function _G.NameplateDRs_GetAnchorForUnit(unit)
    if not unit then
        return nil
    end
    local arenaIndex = unit:match("^arena(%d)$")
    if arenaIndex then
        local index = FDR_SafeNumber(arenaIndex, nil)
        if index then
            local anchor = GetArenaAnchor(index)
            return anchor
        end
    end

    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil
    end
    local plate = GetNamePlateForToken(unit)
    if not FDR_SafeIsObject(plate) then
        return nil
    end
    local token = GetNameplateToken(plate)
    if type(token) == "string" then
        local display = GetPlatynatorDisplay(token)
        if FDR_SafeIsObject(display) then
            local bar = FindHealthBar(display) or FindHealthBarInTree(display)
            if FDR_SafeIsObject(bar) then
                local border = FDR_SafeGetField(bar, "border")
                if FDR_SafeIsObject(border) then
                    return border
                end
                return bar
            end
            return display
        end
    end
    local anchor = GetPlateAnchor(plate)
    if FDR_SafeIsObject(anchor) then
        return anchor
    end
    return plate
end

local BORDER_STYLE_CONFIG = {
    none = { kind = "none" },
    solid = { kind = "backdrop", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeScale = 0.08, alpha = 1.0 },
    soft = { kind = "backdrop", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeScale = 0.06, alpha = 0.65 },
    glow = { kind = "glow" },
    dashed = { kind = "dashed", alpha = 0.95 },
    wideglow = { kind = "wideglow" },
    halo = { kind = "halo" },
}

local function EnsureIconVisualWidgets(item)
    if not item then
        return
    end
    if not item.NPDRS_BorderBackdrop then
        item.NPDRS_BorderBackdrop = CreateFrame("Frame", nil, item, "BackdropTemplate")
        item.NPDRS_BorderBackdrop:SetAllPoints(item)
        if item.GetFrameLevel then
            item.NPDRS_BorderBackdrop:SetFrameLevel(item:GetFrameLevel() + 2)
        end
    end
    if not item.NPDRS_BorderGlow then
        item.NPDRS_BorderGlow = item:CreateTexture(nil, "OVERLAY")
        item.NPDRS_BorderGlow:SetAllPoints(item)
        item.NPDRS_BorderGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_BorderGlow:SetBlendMode("ADD")
        item.NPDRS_BorderGlow:SetVertexColor(0.0, 1.0, 0.2, 0.9)
        item.NPDRS_BorderGlow:Hide()
    end
    if not item.NPDRS_WideGlow then
        item.NPDRS_WideGlow = item:CreateTexture(nil, "BACKGROUND", nil, -6)
        item.NPDRS_WideGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_WideGlow:SetBlendMode("ADD")
        item.NPDRS_WideGlow:SetVertexColor(0.0, 1.0, 0.2, 0.8)
        item.NPDRS_WideGlow:Hide()
    end
    if not item.NPDRS_WideGlowOuter then
        item.NPDRS_WideGlowOuter = item:CreateTexture(nil, "BACKGROUND", nil, -7)
        item.NPDRS_WideGlowOuter:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_WideGlowOuter:SetBlendMode("ADD")
        item.NPDRS_WideGlowOuter:SetVertexColor(0.0, 1.0, 0.2, 0.45)
        item.NPDRS_WideGlowOuter:Hide()
    end
    if not item.NPDRS_WideGlowFar then
        item.NPDRS_WideGlowFar = item:CreateTexture(nil, "BACKGROUND", nil, -8)
        item.NPDRS_WideGlowFar:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_WideGlowFar:SetBlendMode("ADD")
        item.NPDRS_WideGlowFar:SetVertexColor(0.0, 1.0, 0.2, 0.25)
        item.NPDRS_WideGlowFar:Hide()
    end
    if not item.NPDRS_HaloGlow then
        item.NPDRS_HaloGlow = item:CreateTexture(nil, "ARTWORK", nil, -1)
        item.NPDRS_HaloGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_HaloGlow:SetBlendMode("ADD")
        item.NPDRS_HaloGlow:SetVertexColor(0.0, 1.0, 0.2, 0.8)
        item.NPDRS_HaloGlow:Hide()
    end
    if not item.NPDRS_HaloGlowOuter then
        item.NPDRS_HaloGlowOuter = item:CreateTexture(nil, "ARTWORK", nil, -2)
        item.NPDRS_HaloGlowOuter:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_HaloGlowOuter:SetBlendMode("ADD")
        item.NPDRS_HaloGlowOuter:SetVertexColor(0.0, 1.0, 0.2, 0.0)
        item.NPDRS_HaloGlowOuter:Hide()
    end
    if not item.NPDRS_HaloGlowFar then
        item.NPDRS_HaloGlowFar = item:CreateTexture(nil, "ARTWORK", nil, -3)
        item.NPDRS_HaloGlowFar:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        item.NPDRS_HaloGlowFar:SetBlendMode("ADD")
        item.NPDRS_HaloGlowFar:SetVertexColor(0.0, 1.0, 0.2, 0.0)
        item.NPDRS_HaloGlowFar:Hide()
    end
    if not item.NPDRS_DashedSegments then
        item.NPDRS_DashedSegments = {}
        for i = 1, 32 do
            local seg = item:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8x8")
            seg:Hide()
            item.NPDRS_DashedSegments[i] = seg
        end
    end
end

GetConfiguredIcon = function(category, fallbackTexture)
    local normalizedCategory = nil
    if type(category) == "string" then
        normalizedCategory = string.lower(category)
        if normalizedCategory == "incapacitate" then
            normalizedCategory = "incap"
        end
    end
    local overrides = db and db.drCategoryIconOverrides
    if normalizedCategory and type(overrides) == "table" then
        local overrideSpellID = overrides[normalizedCategory]
        if type(overrideSpellID) == "number" then
            local overrideTexture = FDR_SafeSpellTexture(overrideSpellID)
            if overrideTexture then
                return overrideTexture
            end
        end
    end
    return fallbackTexture
end

local function HideDashedSegments(item)
    if not (item and item.NPDRS_DashedSegments) then
        return
    end
    for i = 1, #item.NPDRS_DashedSegments do
        item.NPDRS_DashedSegments[i]:Hide()
    end
end

local function LayoutDashedSegments(item, r, g, b, alpha, thickness)
    if not (item and item.NPDRS_DashedSegments) then
        return
    end
    local width = 16
    local height = 16
    if item.GetWidth then
        local okW, frameWidth = pcall(item.GetWidth, item)
        if okW then
            width = FDR_SafeNumber(frameWidth, width)
        end
    end
    if item.GetHeight then
        local okH, frameHeight = pcall(item.GetHeight, item)
        if okH then
            height = FDR_SafeNumber(frameHeight, width)
        else
            height = width
        end
    else
        height = width
    end
    local parsedThickness = FDR_SafeNumber(thickness, 1.0)
    local edgeScale = 0.06 * math.max(0.5, math.min(3.0, parsedThickness))
    local edge = math.max(1, math.floor(math.min(width, height) * edgeScale + 0.5))
    local dashCount = 8
    local usableW = math.max(1, width - (edge * 2))
    local usableH = math.max(1, height - (edge * 2))
    local hDash = math.max(1, math.floor((usableW / ((dashCount * 2) - 1)) + 0.5))
    local vDash = math.max(1, math.floor((usableH / ((dashCount * 2) - 1)) + 0.5))
    local hGap = hDash
    local vGap = vDash

    local idx = 1
    for side = 1, 4 do
        for n = 0, dashCount - 1 do
            local seg = item.NPDRS_DashedSegments[idx]
            idx = idx + 1
            seg:ClearAllPoints()
            seg:SetVertexColor(r, g, b, alpha or 0.95)
            if side == 1 then
                seg:SetPoint("TOPLEFT", item, "TOPLEFT", edge + (n * (hDash + hGap)), 0)
                seg:SetSize(hDash, edge)
            elseif side == 2 then
                seg:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", edge + (n * (hDash + hGap)), 0)
                seg:SetSize(hDash, edge)
            elseif side == 3 then
                seg:SetPoint("TOPLEFT", item, "TOPLEFT", 0, -(edge + (n * (vDash + vGap))))
                seg:SetSize(edge, vDash)
            else
                seg:SetPoint("TOPRIGHT", item, "TOPRIGHT", 0, -(edge + (n * (vDash + vGap))))
                seg:SetSize(edge, vDash)
            end
            seg:Show()
        end
    end
    while idx <= #item.NPDRS_DashedSegments do
        item.NPDRS_DashedSegments[idx]:Hide()
        idx = idx + 1
    end
end

local function ApplyIconVisual(item, category, fallbackTexture, isImmune)
    if not item or not item.icon then
        return
    end

    local texture = GetConfiguredIcon(category, fallbackTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    item.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    local zoomEnabled = db and db.iconZoomEnabled == true
    if zoomEnabled then
        local percent = FDR_SafeNumber(db and db.iconZoomPercent, 7)
        local inset = math.max(0, math.min(45, percent)) / 100
        item.icon:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
    else
        item.icon:SetTexCoord(0, 1, 0, 1)
    end

    EnsureIconVisualWidgets(item)
    local styleKey = (db and db.iconBorderStyle) or "solid"
    local style = BORDER_STYLE_CONFIG[styleKey] or BORDER_STYLE_CONFIG.solid
    local borderThickness = FDR_SafeNumber(db and db.iconBorderThickness, 1.0)
    borderThickness = math.max(0.5, math.min(3.0, borderThickness))
    local function GetSafeDimensions()
        local width = 16
        local height = 16
        if item.GetWidth then
            local okW, frameWidth = pcall(item.GetWidth, item)
            if okW then
                width = FDR_SafeNumber(frameWidth, width)
            end
        end
        if item.GetHeight then
            local okH, frameHeight = pcall(item.GetHeight, item)
            if okH then
                height = FDR_SafeNumber(frameHeight, width)
            else
                height = width
            end
        else
            height = width
        end
        return width, height
    end
    local border = item.NPDRS_BorderBackdrop
    local glow = item.NPDRS_BorderGlow
    local wideGlow = item.NPDRS_WideGlow
    local wideGlowOuter = item.NPDRS_WideGlowOuter
    local wideGlowFar = item.NPDRS_WideGlowFar
    local haloGlow = item.NPDRS_HaloGlow
    local haloGlowOuter = item.NPDRS_HaloGlowOuter
    local haloGlowFar = item.NPDRS_HaloGlowFar
    if not border or not glow then
        return
    end

    local isImmuneSafe = false
    if type(FDR_SafeIsExactlyTrue) == "function" then
        isImmuneSafe = FDR_SafeIsExactlyTrue(isImmune)
    elseif not IsSecret(isImmune) and isImmune == true then
        isImmuneSafe = true
    end

    local borderR, borderG, borderB = 0.0, 1.0, 0.2
    local glowR, glowG, glowB = 0.0, 1.0, 0.2
    if isImmuneSafe then
        borderR, borderG, borderB = 1.0, 0.15, 0.15
        glowR, glowG, glowB = 1.0, 0.15, 0.15
    end
    glow:SetVertexColor(glowR, glowG, glowB, 0.9)
    if wideGlow then
        wideGlow:SetVertexColor(glowR, glowG, glowB, 0.65)
    end
    if wideGlowOuter then
        wideGlowOuter:SetVertexColor(glowR, glowG, glowB, 0.35)
    end
    if wideGlowFar then
        wideGlowFar:SetVertexColor(glowR, glowG, glowB, 0.18)
    end
    if haloGlow then
        haloGlow:SetVertexColor(glowR, glowG, glowB, 0.78)
    end
    if haloGlowOuter then
        haloGlowOuter:SetVertexColor(glowR, glowG, glowB, 0.0)
    end
    if haloGlowFar then
        haloGlowFar:SetVertexColor(glowR, glowG, glowB, 0.0)
    end

    item.icon:ClearAllPoints()
    item.icon:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    item.icon:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)

    if style.kind == "none" then
        border:Hide()
        glow:Hide()
        if wideGlow then
            wideGlow:Hide()
        end
        if wideGlowOuter then
            wideGlowOuter:Hide()
        end
        if wideGlowFar then
            wideGlowFar:Hide()
        end
        if haloGlow then
            haloGlow:Hide()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        HideDashedSegments(item)
    elseif style.kind == "glow" then
        border:Hide()
        if wideGlow then
            wideGlow:Hide()
        end
        if wideGlowOuter then
            wideGlowOuter:Hide()
        end
        if wideGlowFar then
            wideGlowFar:Hide()
        end
        if haloGlow then
            haloGlow:Hide()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        HideDashedSegments(item)
        local width, height = GetSafeDimensions()
        local glowSize = math.max(width, height) * (2.05 + ((borderThickness - 1.0) * 0.55))
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", item, "CENTER", 0, 0)
        glow:SetSize(glowSize, glowSize)
        glow:Show()
    elseif style.kind == "halo" then
        border:Hide()
        glow:Hide()
        HideDashedSegments(item)
        if wideGlow then
            wideGlow:Hide()
        end
        if wideGlowOuter then
            wideGlowOuter:Hide()
        end
        if wideGlowFar then
            wideGlowFar:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        local width, height = GetSafeDimensions()
        local size = math.max(width, height)
        if haloGlow then
            haloGlow:ClearAllPoints()
            haloGlow:SetPoint("CENTER", item, "CENTER", 0, 0)
            haloGlow:SetSize(size * 1.35, size * 1.35)
            haloGlow:Show()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
    elseif style.kind == "wideglow" then
        border:Hide()
        glow:Hide()
        HideDashedSegments(item)
        if haloGlow then
            haloGlow:Hide()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        if wideGlow and wideGlowOuter and wideGlowFar then
            local width, height = GetSafeDimensions()
            local size = math.max(width, height)
            local innerSize = size * 1.55
            local outerSize = size * 2.2
            local farSize = size * 3.05
            wideGlow:ClearAllPoints()
            wideGlow:SetPoint("CENTER", item, "CENTER", 0, 0)
            wideGlow:SetSize(innerSize, innerSize)
            wideGlow:Show()
            wideGlowOuter:ClearAllPoints()
            wideGlowOuter:SetPoint("CENTER", item, "CENTER", 0, 0)
            wideGlowOuter:SetSize(outerSize, outerSize)
            wideGlowOuter:Show()
            wideGlowFar:ClearAllPoints()
            wideGlowFar:SetPoint("CENTER", item, "CENTER", 0, 0)
            wideGlowFar:SetSize(farSize, farSize)
            wideGlowFar:Show()
        end
    elseif style.kind == "dashed" then
        border:Hide()
        glow:Hide()
        if wideGlow then
            wideGlow:Hide()
        end
        if wideGlowOuter then
            wideGlowOuter:Hide()
        end
        if wideGlowFar then
            wideGlowFar:Hide()
        end
        if haloGlow then
            haloGlow:Hide()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        LayoutDashedSegments(item, borderR, borderG, borderB, style.alpha or 0.95, borderThickness)
    else
        glow:Hide()
        if wideGlow then
            wideGlow:Hide()
        end
        if wideGlowOuter then
            wideGlowOuter:Hide()
        end
        if wideGlowFar then
            wideGlowFar:Hide()
        end
        if haloGlow then
            haloGlow:Hide()
        end
        if haloGlowOuter then
            haloGlowOuter:Hide()
        end
        if haloGlowFar then
            haloGlowFar:Hide()
        end
        HideDashedSegments(item)
        local width, height = GetSafeDimensions()
        local minSize = math.max(1, math.min(width, height))
        local edgeSize = math.max(1, math.floor(minSize * (style.edgeScale or 0.08) * borderThickness + 0.5))
        border:SetBackdrop({
            bgFile = nil,
            edgeFile = style.edgeFile,
            tile = false,
            edgeSize = edgeSize,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        border:SetBackdropBorderColor(borderR, borderG, borderB, style.alpha or 1.0)
        border:Show()
    end
end

_G.FreshDRs_ApplyIconVisual = function(item, category, fallbackTexture, isImmune)
    ApplyIconVisual(item, category, fallbackTexture, isImmune)
end

local function GetIconInfoTextStyle()
    local style = db and db.iconInfoTextStyle
    if style == "modern_coloured" then
        style = "modern_colored"
    end
    if style == "modern_colored" or style == "modern_white" or style == "retro" or style == "retro_text" then
        return style
    end
    return "blizz"
end

local function ParseStageValue(stage)
    if type(stage) == "number" then
        if stage >= 2 then
            return 2
        end
        if stage >= 1 then
            return 1
        end
        return 0
    end
    if type(stage) ~= "string" then
        return 0
    end
    local lower = string.lower(stage)
    if lower == "imm" or lower == "immune" or lower == "2/2" then
        return 2
    end
    if lower == "1/2" then
        return 1
    end
    return 0
end

local function GetStageLabel(stageValue, textStyle)
    if stageValue >= 2 then
        if textStyle == "retro_text" then
            return "IMM"
        end
        return "2/2"
    end
    if stageValue == 1 then
        return "1/2"
    end
    return ""
end

local function GetStageColor(stageValue)
    if stageValue >= 2 then
        return 1, 0.2, 0.2, 1
    end
    if stageValue == 1 then
        return 0.2, 1, 0.2, 1
    end
    return 1, 1, 1, 1
end

local function SetFontSize(fontString, size)
    if not (fontString and fontString.SetFont) then
        return
    end
    local rounded = math.floor((size or 8) + 0.5)
    if rounded < 6 then
        rounded = 6
    end
    if fontString.NPDRS_FontSize == rounded then
        return
    end
    fontString.NPDRS_FontSize = rounded
    fontString:SetFont("Fonts\\FRIZQT__.TTF", rounded, "OUTLINE")
end

local function SetTextStyle(item, stage, remaining, showTimer)
    if not item then
        return
    end
    local timerText = item.timerText
    local stageText = item.stageText or item.text
    local textStyle = GetIconInfoTextStyle()
    local stageValue = ParseStageValue(stage)
    local stageLabel = GetStageLabel(stageValue, textStyle)
    local iconSize = 18
    if item.GetWidth then
        local ok, width = pcall(item.GetWidth, item)
        if ok then
            iconSize = FDR_SafeNumber(width, iconSize)
        end
    end
    local hasTimer = showTimer and type(remaining) == "number" and remaining > 0

    if timerText then
        timerText:ClearAllPoints()
    end
    if stageText then
        stageText:ClearAllPoints()
    end

    if textStyle == "blizz" then
        if timerText then
            timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
            timerText:SetJustifyH("LEFT")
            SetFontSize(timerText, math.max(8, math.min(18, iconSize * 0.45)))
            if hasTimer then
                timerText:SetText(tostring(math.ceil(remaining)))
                timerText:SetTextColor(1, 1, 1, 1)
                timerText:Show()
            else
                timerText:SetText("")
                timerText:Hide()
            end
        end
        if stageText then
            stageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
            stageText:SetJustifyH("RIGHT")
            SetFontSize(stageText, math.max(7, math.min(14, iconSize * 0.36)))
            if stageLabel ~= "" then
                stageText:SetText(stageLabel)
                stageText:SetTextColor(GetStageColor(stageValue))
                stageText:Show()
            else
                stageText:SetText("")
                stageText:Hide()
            end
        end
        return
    end

    if textStyle == "modern_colored" or textStyle == "modern_white" then
        if stageText then
            stageText:SetText("")
            stageText:Hide()
        end
        if timerText then
            timerText:SetPoint("CENTER", item, "CENTER", 0, 0)
            timerText:SetJustifyH("CENTER")
            SetFontSize(timerText, math.max(10, math.min(26, iconSize * 0.58)))
            if hasTimer then
                timerText:SetText(tostring(math.ceil(remaining)))
                if textStyle == "modern_colored" then
                    timerText:SetTextColor(GetStageColor(stageValue))
                else
                    timerText:SetTextColor(1, 1, 1, 1)
                end
                timerText:Show()
            else
                timerText:SetText("")
                timerText:Hide()
            end
        end
        return
    end

    if stageText then
        stageText:SetPoint("BOTTOM", item, "TOP", 0, 1)
        stageText:SetJustifyH("CENTER")
        SetFontSize(stageText, math.max(7, math.min(15, iconSize * 0.34)))
        if stageLabel ~= "" then
            stageText:SetText(stageLabel)
            stageText:SetTextColor(GetStageColor(stageValue))
            stageText:Show()
        else
            stageText:SetText("")
            stageText:Hide()
        end
    end
    if timerText then
        timerText:SetPoint("CENTER", item, "CENTER", 0, 0)
        timerText:SetJustifyH("CENTER")
        SetFontSize(timerText, math.max(10, math.min(24, iconSize * 0.56)))
        if hasTimer then
            timerText:SetText(tostring(math.ceil(remaining)))
            timerText:SetTextColor(1, 1, 1, 1)
            timerText:Show()
        else
            timerText:SetText("")
            timerText:Hide()
        end
    end
end

_G.FreshDRs_ApplyTextStyle = function(item, stage, remaining, showTimer)
    SetTextStyle(item, stage, remaining, showTimer)
end

local function EnsureSolidBorder(item)
    EnsureIconVisualWidgets(item)
    ApplyIconVisual(item, nil, item.NPDRS_DefaultTexture)
end

local function NormalizeEnemyDRCategory(category)
    if type(category) ~= "string" then
        return nil
    end
    local lower = string.lower(category)
    if lower == "incapacitate" or lower == "incap" then
        return "incap"
    end
    return lower
end

local function IsCategoryVisible(category)
    local normalized = NormalizeEnemyDRCategory(category)
    if not normalized then
        return true
    end
    local visibility = db and db.drCategoryVisibility
    if type(visibility) ~= "table" then
        return true
    end
    local allHidden = true
    for _, tracked in ipairs(ENEMY_DR_ORDER) do
        if visibility[tracked] ~= false then
            allHidden = false
            break
        end
    end
    if allHidden then
        return true
    end
    return visibility[normalized] ~= false
end

_G.FreshDRs_IsCategoryVisible = function(category)
    return IsCategoryVisible(category)
end

local function BuildVisibleCategoryList()
    local list = {}
    for _, category in ipairs(ENEMY_DR_ORDER) do
        if IsCategoryVisible(category) then
            list[#list + 1] = category
        end
    end
    if #list == 0 then
        for _, category in ipairs(ENEMY_DR_ORDER) do
            list[#list + 1] = category
        end
    end
    return list
end

local function GetVisibleCategoryKey()
    local list = BuildVisibleCategoryList()
    return table.concat(list, "|")
end

local function GetIconSpacing()
    local spacing = FDR_SafeNumber(db and db.iconSpacing, 2)
    spacing = math.floor(spacing + 0.5)
    if spacing < 0 then
        spacing = 0
    elseif spacing > 20 then
        spacing = 20
    end
    return spacing
end

_G.FreshDRs_GetIconSpacing = function()
    return GetIconSpacing()
end

local function BuildRandomTestItems(count, now)
    local source = BuildVisibleCategoryList()
    local pool = {}
    for i = 1, #source do
        pool[i] = source[i]
    end

    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local picked = {}
    while #picked < count and #pool > 0 do
        picked[#picked + 1] = table.remove(pool, 1)
    end
    while #picked < count do
        picked[#picked + 1] = source[math.random(#source)]
    end

    local items = {}
    for i = 1, count do
        local category = picked[i]
        local stage
        if i == 1 then
            stage = "1/2"
        elseif i == 2 then
            stage = "IMM"
        else
            stage = "1/2"
        end
        local icon = GetConfiguredIcon(category, TEST_CATEGORY_ICON_FALLBACK[category] or "Interface\\Icons\\INV_Misc_QuestionMark")
        items[i] = {
            category = category,
            icon = icon,
            stage = stage,
            active = false,
            resetAt = (now + ENEMY_DR_RESET_TIME - ((i - 1) * 3)),
            bgColor = (stage == "1/2") and { 0, 1, 0, 0.25 } or ((stage == "IMM") and { 0.8, 0.2, 0.2, 0.25 } or nil),
        }
    end
    return items
end

_G.FreshDRs_GetRandomTestItems = function(count, now)
    local amount = FDR_SafeNumber(count, 3)
    if amount < 1 then
        amount = 1
    end
    if amount > 8 then
        amount = 8
    end
    return BuildRandomTestItems(amount, now or GetTime())
end

local function IsEnemyDRCategoryTracked(category)
    if type(category) ~= "string" then
        return false
    end
    for _, key in ipairs(ENEMY_DR_ORDER) do
        if key == category then
            return true
        end
    end
    return false
end

local LOSS_OF_CONTROL_FALLBACK = {
    STUN = "stun",
    STUN_MECHANIC = "stun",
    ROOT = "root",
    SILENCE = "silence",
    DISARM = "disarm",
    DISORIENT = "disorient",
    FEAR = "disorient",
    CHARM = "incap",
    CONFUSE = "incap",
    PACIFY = "incap",
    PACIFYSILENCE = "incap",
    POSSESS = "incap",
}

local function EnsureEnemySpellNameMap()
    if enemySpellNameToCategory then
        return true
    end
    if not FDR_EnsureDRList() then
        return nil
    end
    if not (DRList and DRList.GetSpells) then
        return nil
    end

    local spells = DRList:GetSpells()
    if type(spells) ~= "table" then
        return nil
    end

    enemySpellNameToCategory = {}
    for spellID, rawCategory in pairs(spells) do
        local category = rawCategory
        if type(category) == "table" then
            category = category[1]
        end
        category = NormalizeEnemyDRCategory(category)
        if IsEnemyDRCategoryTracked(category) and type(spellID) == "number" then
            local spellName = FDR_SafeSpellName(spellID)
            if type(spellName) == "string" and not enemySpellNameToCategory[spellName] then
                enemySpellNameToCategory[spellName] = category
            end
        end
    end

    return true
end

local function GetEnemyDRCategoryBySpellID(spellID, locType)
    local category = nil

    if type(spellID) == "number" and not IsSecret(spellID) then
        if not FDR_EnsureDRList() then
            return nil
        end
        if not (DRList and DRList.GetCategoryBySpellID) then
            return nil
        end
        local ok, value = pcall(DRList.GetCategoryBySpellID, DRList, spellID)
        if ok and not IsSecret(value) then
            category = NormalizeEnemyDRCategory(value)
        end

        if not IsEnemyDRCategoryTracked(category) then
            local spellName = FDR_SafeSpellName(spellID)
            if type(spellName) == "string" and EnsureEnemySpellNameMap() then
                category = enemySpellNameToCategory and enemySpellNameToCategory[spellName] or nil
            end
        end
    end

    if not IsEnemyDRCategoryTracked(category) and type(locType) == "string" and not IsSecret(locType) then
        category = LOSS_OF_CONTROL_FALLBACK[locType]
    end

    if IsEnemyDRCategoryTracked(category) then
        return category
    end

    return nil
end

local function ClampEnemyDRCount(value)
    local n = FDR_SafeNumber(value, 0) or 0
    n = math.floor(n + 0.5)
    if n < 0 then
        return 0
    end
    if n > 2 then
        return 2
    end
    return n
end

local function EnsureEnemyCategoryState(state, category)
    if type(state.categories) ~= "table" then
        state.categories = {}
    end
    local categoryState = state.categories[category]
    if type(categoryState) ~= "table" then
        categoryState = { count = 0 }
        state.categories[category] = categoryState
    end
    return categoryState
end

local function ApplyEnemyCategoryActiveState(state, category, payload, source, now)
    local categoryState = EnsureEnemyCategoryState(state, category)
    categoryState.active = true
    categoryState.resetAt = nil
    categoryState.startTime = payload and payload.startTime or nil
    categoryState.duration = payload and payload.duration or nil
    categoryState.endTime = payload and payload.endTime or nil
    categoryState.spellID = payload and payload.spellID or nil
    if payload and payload.icon then
        categoryState.icon = payload.icon
    end
    categoryState.count = ClampEnemyDRCount(categoryState.count)
    categoryState.source = source
    categoryState.lastUpdate = now
    return categoryState
end

local function ApplyEnemyCategoryCooldownState(state, category, count, resetAt, icon, source, now)
    local categoryState = EnsureEnemyCategoryState(state, category)
    categoryState.active = false
    categoryState.count = ClampEnemyDRCount(count)
    if type(resetAt) == "number" and resetAt > now then
        categoryState.resetAt = resetAt
    else
        categoryState.resetAt = nil
    end
    categoryState.startTime = nil
    categoryState.duration = nil
    categoryState.endTime = nil
    categoryState.spellID = nil
    if icon then
        categoryState.icon = icon
    end
    categoryState.source = source
    categoryState.lastUpdate = now

    if categoryState.count <= 0 and not categoryState.resetAt and not categoryState.icon then
        state.categories[category] = nil
    end
    return categoryState
end

function FDR_IsSpellDiminishSystemReady()
    if not (_G.C_SpellDiminish and _G.C_SpellDiminish.IsSystemSupported) then
        return false
    end
    local ok, supported = pcall(_G.C_SpellDiminish.IsSystemSupported)
    return ok and supported == true
end

function FDR_NormalizeSpellDiminishUnitToken(unitToken)
    if type(unitToken) ~= "string" or IsSecret(unitToken) then
        return nil
    end
    local token = FDR_SafeCloneString(unitToken)
    if type(token) ~= "string" then
        return nil
    end
    if token == "target" or token == "focus" then
        return token
    end
    if string.match(token, "^arena[1-3]$") then
        return token
    end
    if string.match(token, "^nameplate%d+$") then
        return token
    end
    return nil
end

function FDR_GetSpellDiminishCategoryIcon(category)
    if type(category) ~= "string" then
        return nil
    end
    _G.FreshDRsSpellDiminishCategoryIcons = _G.FreshDRsSpellDiminishCategoryIcons or {}
    local cached = _G.FreshDRsSpellDiminishCategoryIcons[category]
    if cached ~= nil then
        return cached or nil
    end
    local icon = nil
    if _G.C_SpellDiminish and _G.C_SpellDiminish.GetSpellDiminishCategoryInfo then
        local okInfo, info = pcall(_G.C_SpellDiminish.GetSpellDiminishCategoryInfo, category)
        if okInfo and type(info) == "table" then
            local rawIcon = FDR_SafeGetField(info, "icon")
            if rawIcon ~= nil and not IsSecret(rawIcon) then
                local iconType = type(rawIcon)
                if iconType == "number" or iconType == "string" then
                    icon = rawIcon
                end
            end
        end
    end
    _G.FreshDRsSpellDiminishCategoryIcons[category] = icon or false
    return icon
end

local function FDR_EnsureSpellDiminishStores()
    _G.FreshDRsEnemySpellDiminishByUnit = _G.FreshDRsEnemySpellDiminishByUnit or {}
    _G.FreshDRsEnemySpellDiminishByGUID = _G.FreshDRsEnemySpellDiminishByGUID or {}
    _G.FreshDRsEnemySpellDiminishUnitToGUID = _G.FreshDRsEnemySpellDiminishUnitToGUID or {}
    return _G.FreshDRsEnemySpellDiminishByUnit, _G.FreshDRsEnemySpellDiminishByGUID, _G.FreshDRsEnemySpellDiminishUnitToGUID
end

local function FDR_ClearSpellDiminishStores()
    _G.FreshDRsEnemySpellDiminishByUnit = {}
    _G.FreshDRsEnemySpellDiminishByGUID = {}
    _G.FreshDRsEnemySpellDiminishUnitToGUID = {}
end

local function FDR_GetSpellDiminishBucketForUnit(normalizedUnit, now)
    local byUnit, byGUID, unitToGUID = FDR_EnsureSpellDiminishStores()
    local bucket = byUnit[normalizedUnit]

    local guid = FDR_SafeUnitGUID(normalizedUnit)
    if type(guid) ~= "string" then
        guid = unitToGUID[normalizedUnit]
    end

    if type(guid) == "string" then
        local byGuidBucket = byGUID[guid]
        if type(byGuidBucket) == "table" then
            bucket = byGuidBucket
            byUnit[normalizedUnit] = byGuidBucket
        elseif type(bucket) == "table" then
            byGUID[guid] = bucket
        end
        if type(bucket) == "table" then
            bucket.guid = guid
            unitToGUID[normalizedUnit] = guid
        end
    end

    if type(bucket) ~= "table" then
        bucket = { categories = {}, seen = true, lastUpdate = now, lastTrackedAt = nil }
        byUnit[normalizedUnit] = bucket
        if type(guid) == "string" then
            byGUID[guid] = bucket
            unitToGUID[normalizedUnit] = guid
            bucket.guid = guid
        end
    elseif type(bucket.categories) ~= "table" then
        bucket.categories = {}
    end

    return bucket
end

local function FDR_GetSpellDiminishBucketForRead(normalizedUnit)
    local byUnit, byGUID, unitToGUID = FDR_EnsureSpellDiminishStores()
    local bucket = byUnit[normalizedUnit]

    local guid = FDR_SafeUnitGUID(normalizedUnit)
    if type(guid) ~= "string" then
        guid = unitToGUID[normalizedUnit]
    end

    if type(guid) == "string" then
        local byGuidBucket = byGUID[guid]
        if type(byGuidBucket) == "table" then
            bucket = byGuidBucket
            byUnit[normalizedUnit] = byGuidBucket
        end
        if type(bucket) == "table" then
            bucket.guid = guid
            unitToGUID[normalizedUnit] = guid
        end
    end

    if type(bucket) ~= "table" then
        return nil
    end
    if type(bucket.categories) ~= "table" then
        bucket.categories = {}
    end
    return bucket
end

function FDR_RecordSpellDiminishCategoryState(unitToken, trackerInfo)
    local normalizedUnit = FDR_NormalizeSpellDiminishUnitToken(unitToken)
    if not normalizedUnit then
        return
    end
    if type(trackerInfo) ~= "table" then
        return
    end

    local rawCategory = FDR_SafeGetField(trackerInfo, "category")
    local category = NormalizeEnemyDRCategory(rawCategory)
    if not IsEnemyDRCategoryTracked(category) then
        return
    end

    local startTime = FDR_SafeNumber(FDR_SafeGetField(trackerInfo, "startTime"), nil)
    local duration = FDR_SafeNumber(FDR_SafeGetField(trackerInfo, "duration"), nil)
    local isImmune = FDR_SafeIsExactlyTrue(FDR_SafeGetField(trackerInfo, "isImmune"))
    local showCountdown = FDR_SafeIsExactlyTrue(FDR_SafeGetField(trackerInfo, "showCountdown"))

    local now = GetTime()
    local expiresAt = nil
    if type(startTime) == "number" and type(duration) == "number" and duration > 0 then
        expiresAt = startTime + duration
    end

    local perUnit = FDR_GetSpellDiminishBucketForUnit(normalizedUnit, now)
    perUnit.seen = true
    perUnit.lastUpdate = now

    if expiresAt and expiresAt > now then
        perUnit.categories[category] = {
            expiresAt = expiresAt,
            isImmune = isImmune,
            showCountdown = showCountdown,
            icon = GetConfiguredIcon(category, FDR_GetSpellDiminishCategoryIcon(category)),
        }
        perUnit.lastTrackedAt = now
    else
        perUnit.categories[category] = nil
    end
end

function FDR_ApplySpellDiminishStateToEnemyUnit(state, unitToken, now)
    local normalizedUnit = FDR_NormalizeSpellDiminishUnitToken(unitToken)
    if not normalizedUnit then
        return false
    end
    local perUnit = FDR_GetSpellDiminishBucketForRead(normalizedUnit)
    if type(perUnit) ~= "table" or perUnit.seen ~= true then
        return false
    end

    local categories = perUnit.categories

    local hasAny = false
    for category, info in pairs(categories) do
        if type(info) ~= "table" or type(info.expiresAt) ~= "number" or info.expiresAt <= now then
            categories[category] = nil
        else
            hasAny = true
        end
    end

    if type(state.categories) ~= "table" then
        state.categories = {}
    end

    for category, _ in pairs(state.categories) do
        if categories[category] == nil then
            state.categories[category] = nil
        end
    end

    for category, info in pairs(categories) do
        if type(info) == "table" then
            ApplyEnemyCategoryCooldownState(
                state,
                category,
                info.isImmune and 2 or 1,
                info.expiresAt,
                info.icon,
                "spell_diminish",
                now
            )
        end
    end

    if not hasAny then
        local lastTrackedAt = FDR_SafeNumber(perUnit.lastTrackedAt, nil)
        if type(lastTrackedAt) == "number" and (now - lastTrackedAt) <= (ENEMY_DR_RESET_TIME + 1.0) then
            return true
        end
        return false
    end

    return true
end

function FDR_ShouldUseLossOfControlFallback(unitToken, now)
    local normalizedUnit = FDR_NormalizeSpellDiminishUnitToken(unitToken)
    if not normalizedUnit then
        return false
    end
    if not FDR_IsSpellDiminishSystemReady() then
        return true
    end

    local perUnit = FDR_GetSpellDiminishBucketForRead(normalizedUnit)
    if type(perUnit) ~= "table" then
        return true
    end
    local categories = perUnit.categories
    if type(categories) == "table" then
        for _ in pairs(categories) do
            return false
        end
    end

    local lastTrackedAt = FDR_SafeNumber(perUnit.lastTrackedAt, nil)
    if type(lastTrackedAt) == "number" then
        if (now - lastTrackedAt) <= (ENEMY_DR_RESET_TIME + 1.0) then
            return false
        end
    end
    return true
end

function FDR_GetEnemyDRCategoryByAuraName(auraName)
    if type(auraName) ~= "string" then
        return nil
    end
    if not EnsureEnemySpellNameMap() then
        return nil
    end
    local category = enemySpellNameToCategory and enemySpellNameToCategory[auraName] or nil
    category = NormalizeEnemyDRCategory(category)
    if IsEnemyDRCategoryTracked(category) then
        return category
    end
    return nil
end

function FDR_UpdateEnemyUnitStateFromAuras(state, unit, now)
    if not (state and state.categories and type(unit) == "string") then
        return false
    end
    if not FDR_SafeUnitExists(unit) then
        return false
    end

    local seen = {}
    local activeCountByCategory = {}
    local bestByCategory = {}
    local scanned = false

    if _G.C_UnitAuras and _G.C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local okAura, aura = pcall(_G.C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not okAura or not aura then
                break
            end
            scanned = true

            local spellID = FDR_SafeNumber(FDR_SafeGetField(aura, "spellId") or FDR_SafeGetField(aura, "spellID"), nil)
            local auraName = FDR_SafeGetField(aura, "name")
            if IsSecret(auraName) or type(auraName) ~= "string" then
                auraName = nil
            end
            local category = GetEnemyDRCategoryBySpellID(spellID, nil)
            if not category then
                category = FDR_GetEnemyDRCategoryByAuraName(auraName)
            end

            if category then
                seen[category] = true
                activeCountByCategory[category] = (activeCountByCategory[category] or 0) + 1

                local duration = FDR_SafeNumber(FDR_SafeGetField(aura, "duration"), nil)
                local endTime = FDR_SafeNumber(FDR_SafeGetField(aura, "expirationTime"), nil)
                local startTime = nil
                if type(endTime) == "number" and type(duration) == "number" and duration > 0 then
                    startTime = endTime - duration
                end

                local icon = FDR_SafeGetField(aura, "icon")
                if IsSecret(icon) or (type(icon) ~= "number" and type(icon) ~= "string") then
                    icon = FDR_SafeSpellTexture(spellID)
                end

                local candidate = bestByCategory[category]
                if not candidate then
                    bestByCategory[category] = {
                        spellID = spellID,
                        startTime = startTime,
                        duration = duration,
                        endTime = endTime,
                        icon = icon,
                    }
                else
                    local currentEnd = candidate.endTime
                    local replace = false
                    if type(endTime) == "number" then
                        if type(currentEnd) ~= "number" or endTime > currentEnd then
                            replace = true
                        end
                    elseif type(currentEnd) ~= "number" and type(duration) == "number" and type(candidate.duration) ~= "number" then
                        replace = true
                    end
                    if replace then
                        candidate.spellID = spellID
                        candidate.startTime = startTime
                        candidate.duration = duration
                        candidate.endTime = endTime
                        candidate.icon = icon
                    elseif not candidate.icon and icon then
                        candidate.icon = icon
                    end
                end
            end
        end
    elseif _G.UnitAura then
        for i = 1, 40 do
            local okAura, name, _rank, _icon, _count, _dtype, duration, expirationTime, _source, _stealable, _nameplateShowPersonal, spellID = pcall(_G.UnitAura, unit, i, "HARMFUL")
            if not okAura or not name then
                break
            end
            scanned = true

            local category = GetEnemyDRCategoryBySpellID(spellID, nil)
            if not category then
                category = FDR_GetEnemyDRCategoryByAuraName(name)
            end

            if category then
                seen[category] = true
                activeCountByCategory[category] = (activeCountByCategory[category] or 0) + 1

                local safeDuration = FDR_SafeNumber(duration, nil)
                local safeEndTime = FDR_SafeNumber(expirationTime, nil)
                local startTime = nil
                if type(safeEndTime) == "number" and type(safeDuration) == "number" and safeDuration > 0 then
                    startTime = safeEndTime - safeDuration
                end

                local icon = FDR_SafeSpellTexture(spellID)
                local candidate = bestByCategory[category]
                if not candidate then
                    bestByCategory[category] = {
                        spellID = spellID,
                        startTime = startTime,
                        duration = safeDuration,
                        endTime = safeEndTime,
                        icon = icon,
                    }
                else
                    local currentEnd = candidate.endTime
                    local replace = false
                    if type(safeEndTime) == "number" then
                        if type(currentEnd) ~= "number" or safeEndTime > currentEnd then
                            replace = true
                        end
                    elseif type(currentEnd) ~= "number" and type(safeDuration) == "number" and type(candidate.duration) ~= "number" then
                        replace = true
                    end
                    if replace then
                        candidate.spellID = spellID
                        candidate.startTime = startTime
                        candidate.duration = safeDuration
                        candidate.endTime = safeEndTime
                        candidate.icon = icon
                    elseif not candidate.icon and icon then
                        candidate.icon = icon
                    end
                end
            end
        end
    else
        return false
    end

    if not scanned then
        return false
    end

    local function IsLikelyNewAuraInstance(oldState, candidate)
        if not (oldState and candidate) then
            return false
        end
        local prevStart = oldState.startTime
        local newStart = candidate.startTime
        if type(prevStart) == "number" and type(newStart) == "number" and newStart > (prevStart + 0.12) then
            return true
        end
        local prevSpell = oldState.spellID
        local newSpell = candidate.spellID
        if type(prevSpell) == "number" and type(newSpell) == "number" and newSpell ~= prevSpell then
            local prevEnd = oldState.endTime
            local newEnd = candidate.endTime
            if type(prevEnd) == "number" and type(newEnd) == "number" and newEnd >= (prevEnd - 0.05) then
                return true
            end
        end
        return false
    end

    for category, candidate in pairs(bestByCategory) do
        local categoryState = EnsureEnemyCategoryState(state, category)
        if categoryState.active and IsLikelyNewAuraInstance(categoryState, candidate) then
            local nextCount = (categoryState.count or 0) + 1
            categoryState.count = ClampEnemyDRCount(nextCount)
        end
        ApplyEnemyCategoryActiveState(state, category, candidate, "aura", now)
    end

    for category, count in pairs(activeCountByCategory) do
        if count > 1 then
            local categoryState = state.categories[category]
            if categoryState then
                -- Avoid false IMM on first CC when aura APIs report duplicate entries.
                local current = ClampEnemyDRCount(categoryState.count)
                if current >= 1 then
                    categoryState.count = current
                end
            end
        end
    end

    for category, categoryState in pairs(state.categories) do
        if categoryState.active and not seen[category] then
            local nextCount = ClampEnemyDRCount((categoryState.count or 0) + 1)
            local resetAt = nextCount > 0 and (now + ENEMY_DR_RESET_TIME) or nil
            ApplyEnemyCategoryCooldownState(state, category, nextCount, resetAt, categoryState.icon, "aura", now)
        elseif not categoryState.active then
            if categoryState.resetAt and now >= categoryState.resetAt then
                categoryState.count = 0
                categoryState.resetAt = nil
            end
            if (categoryState.count or 0) <= 0 and not categoryState.resetAt and not categoryState.icon then
                state.categories[category] = nil
            end
        end
    end

    return true
end

local function EnsureEnemyNameplateFrame(index)
    if enemyNameplateFrames[index] then
        return enemyNameplateFrames[index]
    end

    local tray = CreateFrame("Frame", "FreshDRsEnemyNameplateTray" .. index, UIParent)
    tray.items = {}
    tray.iconSize = 22
    tray.spacing = 2
    tray:SetFrameStrata("HIGH")

    for i = 1, #ENEMY_DR_ORDER do
        local item = CreateFrame("Frame", nil, tray)
        item:SetSize(tray.iconSize, tray.iconSize)

        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetAllPoints(item)
        item.NPDRS_DefaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        item.icon:SetTexture(item.NPDRS_DefaultTexture)

        item.timerText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
        item.timerText:SetJustifyH("LEFT")
        item.timerText:SetText("")
        item.timerText:Hide()

        item.stageText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.stageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
        item.stageText:SetJustifyH("RIGHT")
        item.stageText:SetText("")
        item.stageText:Hide()

        EnsureSolidBorder(item)
        item:Hide()
        tray.items[i] = item
    end

    tray:Hide()
    enemyNameplateFrames[index] = tray
    return tray
end

local function EnsureEnemyOpenWorldNameplateFrame(token)
    if type(token) ~= "string" then
        return nil
    end
    if enemyOpenWorldNameplateFrames[token] then
        return enemyOpenWorldNameplateFrames[token]
    end

    local sanitized = string.gsub(token, "[^%w_]", "_")
    local tray = CreateFrame("Frame", "FreshDRsOpenWorldNameplateTray_" .. sanitized, UIParent)
    tray.items = {}
    tray.iconSize = 22
    tray.spacing = 2
    tray:SetFrameStrata("HIGH")

    for i = 1, #ENEMY_DR_ORDER do
        local item = CreateFrame("Frame", nil, tray)
        item:SetSize(tray.iconSize, tray.iconSize)

        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetAllPoints(item)
        item.NPDRS_DefaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        item.icon:SetTexture(item.NPDRS_DefaultTexture)

        item.timerText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
        item.timerText:SetJustifyH("LEFT")
        item.timerText:SetText("")
        item.timerText:Hide()

        item.stageText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.stageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
        item.stageText:SetJustifyH("RIGHT")
        item.stageText:SetText("")
        item.stageText:Hide()

        EnsureSolidBorder(item)
        item:Hide()
        tray.items[i] = item
    end

    tray:Hide()
    enemyOpenWorldNameplateFrames[token] = tray
    return tray
end

local function HideEnemyNameplateFrames()
    for _, tray in pairs(enemyNameplateFrames) do
        tray:Hide()
    end
end

local function HideEnemyOpenWorldNameplateFrames()
    for _, tray in pairs(enemyOpenWorldNameplateFrames) do
        tray:Hide()
    end
end

local function EnsureEnemyTargetFocusFrame(kind)
    local key = (kind == "focus") and "focus" or "target"
    if enemyTargetFocusFrames[key] then
        return enemyTargetFocusFrames[key]
    end

    local frameName = (key == "focus") and "FreshDRsEnemyFocusTray" or "FreshDRsEnemyTargetTray"
    local tray = CreateFrame("Frame", frameName, UIParent)
    tray.items = {}
    tray.iconSize = 22
    tray.spacing = 2
    tray:SetFrameStrata("HIGH")

    for i = 1, #ENEMY_DR_ORDER do
        local item = CreateFrame("Frame", nil, tray)
        item:SetSize(tray.iconSize, tray.iconSize)

        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetAllPoints(item)
        item.NPDRS_DefaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        item.icon:SetTexture(item.NPDRS_DefaultTexture)

        item.timerText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
        item.timerText:SetJustifyH("LEFT")
        item.timerText:SetText("")
        item.timerText:Hide()

        item.stageText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.stageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
        item.stageText:SetJustifyH("RIGHT")
        item.stageText:SetText("")
        item.stageText:Hide()

        EnsureSolidBorder(item)
        item:Hide()
        tray.items[i] = item
    end

    tray:Hide()
    enemyTargetFocusFrames[key] = tray
    return tray
end

local function HideEnemyTargetFocusFrames()
    for _, tray in pairs(enemyTargetFocusFrames) do
        tray:Hide()
    end
end

local function BuildEnemyDisplayList(state, now)
    local displayList = {}
    if not state or type(state.categories) ~= "table" then
        return displayList
    end
    for _, category in ipairs(ENEMY_DR_ORDER) do
        if IsCategoryVisible(category) then
        local categoryState = state.categories[category]
        if categoryState then
            local active = categoryState.active == true
            local hasDR = (categoryState.count or 0) > 0 and categoryState.resetAt and categoryState.resetAt > now
            if active or hasDR then
                displayList[#displayList + 1] = { category = category, state = categoryState }
            end
        end
        end
    end
    return displayList
end

local function ApplyTrayAnchor(tray, anchor, plateForParent, offsetX, offsetY, scale, forcedParent)
    if not (tray and anchor) then
        return
    end
    local parent = forcedParent or GetAnchorParent(anchor, plateForParent, UIParent)
    if ShouldAnchorInUIParent(anchor) then
        parent = UIParent
    end
    tray:SetParent(parent)
    tray:ClearAllPoints()
    tray:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", offsetX or 0, offsetY or 0)
    tray:SetScale(scale or 1)
    if anchor.GetFrameLevel then
        tray:SetFrameLevel(anchor:GetFrameLevel() + 12)
    end
end

local function RenderEnemyTrayAtAnchor(tray, state, anchor, plateForParent, offsetX, offsetY, scale, now, forcedParent)
    if not (tray and state and anchor) then
        if tray then
            tray:Hide()
        end
        return false
    end

    local displayList = BuildEnemyDisplayList(state, now)
    if #displayList == 0 then
        tray:Hide()
        return false
    end

    ApplyTrayAnchor(tray, anchor, plateForParent, offsetX, offsetY, scale, forcedParent)

    local size = tray.iconSize
    local spacing = GetIconSpacing()
    tray.spacing = spacing
    tray:SetSize((size * #displayList) + (spacing * (#displayList - 1)), size)

    local prev
    for itemIndex, item in ipairs(tray.items) do
        local displayEntry = displayList[itemIndex]
        local categoryState = displayEntry and displayEntry.state
        if categoryState then
            item:SetSize(size, size)
            item.NPDRS_DefaultTexture = categoryState.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            local stage = categoryState.count or 0
            if categoryState.active then
                stage = math.min(2, stage + 1)
            end
            local isImmune = stage >= 2
            ApplyIconVisual(item, displayEntry.category, item.NPDRS_DefaultTexture, isImmune)
            local remaining = nil
            if not categoryState.active then
                remaining = (categoryState.resetAt or 0) - now
            end
            SetTextStyle(item, stage, remaining, remaining and remaining > 0)

            item:ClearAllPoints()
            if not prev then
                item:SetPoint("RIGHT", tray, "RIGHT", 0, 0)
            else
                item:SetPoint("RIGHT", prev, "LEFT", -spacing, 0)
            end
            prev = item
            item:Show()
        else
            item:Hide()
        end
    end

    tray:Show()
    return true
end

GetNameplateAnchorForEnemyTray = function(plate)
    if not FDR_SafeIsObject(plate) then
        return nil
    end

    local unitFrame = FDR_SafeGetField(plate, "UnitFrame")
    if FDR_SafeIsObject(unitFrame) then
        local healthBar = FDR_SafeGetField(unitFrame, "healthBar")
        if FDR_SafeIsObject(healthBar) then
            return healthBar
        end
    end

    local platerUnitFrame = FDR_SafeGetField(plate, "unitFrame") or FDR_SafeGetField(plate, "PlaterUnitFrame")
    if FDR_SafeIsObject(platerUnitFrame) then
        local platerHealthBar = FDR_SafeGetField(platerUnitFrame, "healthBar") or FDR_SafeGetField(platerUnitFrame, "HealthBar")
        if FDR_SafeIsObject(platerHealthBar) then
            return platerHealthBar
        end
    end

    return plate
end

local function SetArenaTrayHidden(hidden)
    if enemyModeTrayHidden == hidden then
        return
    end
    enemyModeTrayHidden = hidden

    for i = 1, 3 do
        local tray = GetArenaTray(i)
        if tray then
            if hidden then
                if tray.NPDRS_OriginalAlpha == nil then
                    tray.NPDRS_OriginalAlpha = tray:GetAlpha()
                end
                tray:SetAlpha(0)
            else
                if tray.NPDRS_OriginalAlpha ~= nil then
                    tray:SetAlpha(tray.NPDRS_OriginalAlpha)
                    tray.NPDRS_OriginalAlpha = nil
                else
                    tray:SetAlpha(1)
                end
            end
        end
    end
end

local function UpdateEnemyArenaUnitState(state, unit, now)
    if not (state and state.categories and _G.C_LossOfControl and _G.C_LossOfControl.GetActiveLossOfControlDataByUnit) then
        return
    end

    local seen = {}
    local activeCountByCategory = {}
    local bestByCategory = {}

    local function GetBestEndTime(startTime, duration)
        if type(startTime) == "number" and type(duration) == "number" and duration > 0 then
            return startTime + duration
        end
        return nil
    end

    local function IsLikelyNewInstance(oldState, candidate)
        if not (oldState and candidate) then
            return false
        end
        local prevStart = oldState.startTime
        local newStart = candidate.startTime
        if type(prevStart) == "number" and type(newStart) == "number" then
            if newStart > (prevStart + 0.12) then
                return true
            end
        end

        local prevSpell = oldState.spellID
        local newSpell = candidate.spellID
        if type(prevSpell) == "number" and type(newSpell) == "number" and newSpell ~= prevSpell then
            local prevEnd = oldState.endTime
            local newEnd = candidate.endTime
            if type(prevEnd) == "number" and type(newEnd) == "number" and newEnd >= (prevEnd - 0.05) then
                return true
            end
        end

        return false
    end

    for i = 1, 20 do
        local okData, data = pcall(_G.C_LossOfControl.GetActiveLossOfControlDataByUnit, unit, i)
        if not okData or not data then
            break
        end

        local spellID = data.spellID
        if IsSecret(spellID) then
            spellID = nil
        end

        local locType = data.locType
        if IsSecret(locType) or type(locType) ~= "string" then
            locType = nil
        end

        local category = GetEnemyDRCategoryBySpellID(spellID, locType)
        if category then
            seen[category] = true
            activeCountByCategory[category] = (activeCountByCategory[category] or 0) + 1

            local startTime = data.startTime
            if IsSecret(startTime) or type(startTime) ~= "number" then
                startTime = nil
            end
            local duration = data.duration
            if IsSecret(duration) or type(duration) ~= "number" then
                duration = nil
            end
            local endTime = GetBestEndTime(startTime, duration)

            local icon = FDR_SafeSpellTexture(spellID)
            local candidate = bestByCategory[category]
            if not candidate then
                bestByCategory[category] = {
                    spellID = spellID,
                    startTime = startTime,
                    duration = duration,
                    endTime = endTime,
                    icon = icon,
                }
            else
                local currentEnd = candidate.endTime
                local replace = false
                if type(endTime) == "number" then
                    if type(currentEnd) ~= "number" or endTime > currentEnd then
                        replace = true
                    end
                elseif type(currentEnd) ~= "number" and type(duration) == "number" and type(candidate.duration) ~= "number" then
                    replace = true
                end
                if replace then
                    candidate.spellID = spellID
                    candidate.startTime = startTime
                    candidate.duration = duration
                    candidate.endTime = endTime
                    candidate.icon = icon
                elseif not candidate.icon and icon then
                    candidate.icon = icon
                end
            end
        end
    end

    for category, candidate in pairs(bestByCategory) do
        local categoryState = EnsureEnemyCategoryState(state, category)
        if categoryState.active and IsLikelyNewInstance(categoryState, candidate) then
            local nextCount = (categoryState.count or 0) + 1
            categoryState.count = ClampEnemyDRCount(nextCount)
        end

        ApplyEnemyCategoryActiveState(state, category, candidate, "loss_of_control", now)
    end

    -- Immune fast-track: multiple simultaneous CCs in one DR category.
    for category, count in pairs(activeCountByCategory) do
        if count > 1 then
            local categoryState = state.categories[category]
            if categoryState then
                -- Avoid false IMM on first CC when LoC emits duplicate category rows.
                local current = ClampEnemyDRCount(categoryState.count)
                if current >= 1 then
                    categoryState.count = current
                end
            end
        end
    end

    for category, categoryState in pairs(state.categories) do
        if categoryState.active and not seen[category] then
            local nextCount = (categoryState.count or 0) + 1
            nextCount = ClampEnemyDRCount(nextCount)
            local resetAt = nextCount > 0 and (now + ENEMY_DR_RESET_TIME) or nil
            ApplyEnemyCategoryCooldownState(state, category, nextCount, resetAt, categoryState.icon, "loss_of_control", now)
        elseif not categoryState.active then
            if categoryState.resetAt and now >= categoryState.resetAt then
                categoryState.count = 0
                categoryState.resetAt = nil
            end
            if (categoryState.count or 0) <= 0 and not categoryState.resetAt and not categoryState.icon then
                state.categories[category] = nil
            end
        end
    end
end

local function BuildArenaToNameplateMap()
    local mapping = {}
    local visible = {}
    local visibleSet = {}
    local used = {}

    local function AddVisibleToken(token)
        if type(token) ~= "string" or visibleSet[token] then
            return
        end
        -- Prefer enemy player nameplates in arena
        if FDR_SafeUnitExists(token) then
            local isEnemyPlayer = FDR_SafeUnitIsEnemy("player", token) and FDR_SafeUnitIsPlayer(token)
            if isEnemyPlayer then
                visible[#visible + 1] = token
                visibleSet[token] = true
                return
            end
        end
        -- Fallback path: keep token if visibility checks are restricted.
        visible[#visible + 1] = token
        visibleSet[token] = true
    end

    -- Primary source: visible nameplate<N> unit tokens.
    for i = 1, 40 do
        local token = "nameplate" .. i
        if FDR_SafeUnitExists(token) then
            AddVisibleToken(token)
        end
    end

    -- Secondary source: cached tokens from nameplate events.
    for token, plate in pairs(nameplateByToken) do
        if type(token) == "string" and FDR_SafeIsObject(plate) then
            AddVisibleToken(token)
        end
    end

    -- Tertiary source: plates enumeration (helps with custom nameplate addons).
    local plates = FDR_GetAllNamePlates()
    if type(plates) == "table" then
        for _, plate in ipairs(plates) do
            local rawToken = (ResolveTokenForPlate and ResolveTokenForPlate(plate)) or GetNameplateToken(plate) or FDR_GetFrameNameplateToken(plate)
            local token = FDR_ResolveUnitTokenToNameplateToken(rawToken)
            AddVisibleToken(token)
        end
    end

    -- Pass 0: cached event-time arena<n> -> nameplate<n> links.
    for arenaIndex = 1, 3 do
        local cachedToken = enemyNameplateTokenByArenaIndex[arenaIndex]
        if type(cachedToken) == "string" and visibleSet[cachedToken] and not used[cachedToken] then
            mapping[arenaIndex] = cachedToken
            used[cachedToken] = true
        end
    end

    -- Pass 0.5: composite key pairing arena<n> <-> nameplate<n>.
    if #visible > 0 then
        local npByKey = {}
        for _, token in ipairs(visible) do
            if not used[token] then
                local key = FDR_BuildEnemyCompositeKeyRaw(token)
                if key then
                    if not npByKey[key] then
                        npByKey[key] = {}
                    end
                    npByKey[key][#npByKey[key] + 1] = token
                end
            end
        end
        for arenaIndex = 1, 3 do
            if not mapping[arenaIndex] then
                local arenaKey = FDR_BuildEnemyCompositeKeyRaw("arena" .. arenaIndex)
                local candidates = arenaKey and npByKey[arenaKey] or nil
                if candidates and #candidates > 0 then
                    local token = table.remove(candidates, 1)
                    if type(token) == "string" and visibleSet[token] and not used[token] then
                        mapping[arenaIndex] = token
                        used[token] = true
                    end
                end
            end
        end
    end

    -- First pass: direct token normalization (if API returns a nameplate token already).
    for arenaIndex = 1, 3 do
        if not mapping[arenaIndex] then
            local token = FDR_ResolveUnitTokenToNameplateToken("arena" .. arenaIndex)
            if type(token) == "string" and visibleSet[token] and not used[token] then
                mapping[arenaIndex] = token
                used[token] = true
            end
        end
    end

    -- Second pass: direct unit GUID -> token resolution.
    for arenaIndex = 1, 3 do
        if not mapping[arenaIndex] and UnitTokenFromGUID then
            local arenaUnit = "arena" .. arenaIndex
            local guid = FDR_SafeUnitGUID(arenaUnit)
            if guid then
                local okTok, unitToken = pcall(UnitTokenFromGUID, guid)
                local token = okTok and FDR_ResolveUnitTokenToNameplateToken(unitToken) or nil
                if type(token) == "string" and visibleSet[token] and not used[token] then
                    mapping[arenaIndex] = token
                    used[token] = true
                end
            end
        end
    end

    -- Third pass: UnitIsUnit probing against visible nameplate tokens.
    for arenaIndex = 1, 3 do
        if not mapping[arenaIndex] then
            local matchedToken = FDR_FindNameplateTokenForUnit("arena" .. arenaIndex)
            if type(matchedToken) == "string" and visibleSet[matchedToken] and not used[matchedToken] then
                mapping[arenaIndex] = matchedToken
                used[matchedToken] = true
            end
        end
    end

    -- Fourth pass: composite key matching (honor/class/race).
    local npByKey = {}
    for _, token in ipairs(visible) do
        if not used[token] then
            local key = FDR_GetBestEnemyCompositeKey(token)
            if key then
                if not npByKey[key] then
                    npByKey[key] = {}
                end
                npByKey[key][#npByKey[key] + 1] = token
            end
        end
    end

    for arenaIndex = 1, 3 do
        if not mapping[arenaIndex] then
            local key = FDR_GetBestEnemyCompositeKey("arena" .. arenaIndex)
            local candidates = key and npByKey[key] or nil
            if candidates and #candidates > 0 then
                local token = table.remove(candidates, 1)
                mapping[arenaIndex] = token
                used[token] = true
            end
        end
    end

    if ENABLE_ARENA_NAME_FALLBACK then
        -- Optional final pass: name-based fallback (disabled by default to avoid false pairings).
        local npByName = {}
        for _, token in ipairs(visible) do
            if not used[token] then
                local normalizedName = GetNormalizedUnitName(token)
                if normalizedName then
                    if not npByName[normalizedName] then
                        npByName[normalizedName] = {}
                    end
                    npByName[normalizedName][#npByName[normalizedName] + 1] = token
                end
            end
        end

        for arenaIndex = 1, 3 do
            if not mapping[arenaIndex] then
                local arenaName = NormalizeName(GetArenaDisplayName(arenaIndex))
                if not arenaName then
                    arenaName = GetNormalizedUnitName("arena" .. arenaIndex)
                end
                local candidates = arenaName and npByName[arenaName] or nil
                if candidates and #candidates > 0 then
                    local token = table.remove(candidates, 1)
                    mapping[arenaIndex] = token
                    used[token] = true
                end
            end
        end
    end

    -- Refresh cache with successfully matched tokens.
    for arenaIndex = 1, 3 do
        local token = mapping[arenaIndex]
        if type(token) == "string" then
            LinkArenaIndexToNameplateToken(arenaIndex, token)
        end
    end

    return mapping
end

local function RenderEnemyNameplateFrame(index, state, unitToken, now)
    local tray = EnsureEnemyNameplateFrame(index)
    if not (state and unitToken) then
        tray:Hide()
        return false
    end

    local plate = GetNamePlateForToken(unitToken)
    if not FDR_SafeIsObject(plate) then
        tray:Hide()
        return false
    end

    -- anchoring: parent to native nameplate frame directly.
    local anchor = GetNameplateAnchorForEnemyTray(plate)
    if not FDR_SafeIsObject(anchor) then
        tray:Hide()
        return false
    end

    return RenderEnemyTrayAtAnchor(tray, state, anchor, plate, db.offsetX or 0, db.offsetY or 0, db.trayScale or 1, now, plate)
end

local function UpdateEnemyArenaStates(now)
    for i = 1, 3 do
        local unit = "arena" .. i
        local state = enemyNameplateStates[i]
        if not state then
            state = { categories = {} }
            enemyNameplateStates[i] = state
        end

        local handledBySpellDiminish = false
        if FDR_IsSpellDiminishSystemReady() then
            handledBySpellDiminish = FDR_ApplySpellDiminishStateToEnemyUnit(state, unit, now)
        end

        if handledBySpellDiminish then
            -- Event-first path already populated state from Spell Diminish API.
        elseif FDR_HasUnitToken(unit) and FDR_ShouldUseLossOfControlFallback(unit, now) then
            UpdateEnemyArenaUnitState(state, unit, now)
        else
            -- Keep existing DR state while arena tokens flap (prevents false reset to fresh 1/2).
            for category, categoryState in pairs(state.categories) do
                if not categoryState.active and categoryState.resetAt and now >= categoryState.resetAt then
                    state.categories[category] = nil
                end
            end
        end
    end
end

local function GetArenaIndexForUnitToken(unitToken)
    if type(unitToken) ~= "string" then
        return nil
    end

    for i = 1, 3 do
        local arenaUnit = "arena" .. i
        if FDR_HasUnitToken(arenaUnit) and FDR_SafeUnitIsUnit(arenaUnit, unitToken) then
            return i
        end
    end

    local unitKey = FDR_GetBestEnemyCompositeKey(unitToken)
    if unitKey then
        for i = 1, 3 do
            local arenaUnit = "arena" .. i
            if FDR_HasUnitToken(arenaUnit) then
                local arenaKey = FDR_GetBestEnemyCompositeKey(arenaUnit)
                if arenaKey and FDR_SafeStringEquals(arenaKey, unitKey) then
                    return i
                end
            end
        end
    end

    if ENABLE_ARENA_NAME_FALLBACK then
        local wantedName = GetNormalizedUnitName(unitToken)
        if not wantedName then
            return nil
        end

        for i = 1, 3 do
            local arenaName = NormalizeName(GetArenaDisplayName(i))
            if not arenaName then
                arenaName = GetNormalizedUnitName("arena" .. i)
            end
            if arenaName and FDR_SafeStringEquals(arenaName, wantedName) then
                return i
            end
        end
    end

    return nil
end

local function UpdateEnemyNameplateMode()
    if not db or not db.enabled then
        HideEnemyNameplateFrames()
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
        return
    end
    if not IsInArena() then
        HideEnemyNameplateFrames()
        table.wipe(enemyNameplateStates)
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
        return
    end
    if not FDR_EnsureDRList() then
        HideEnemyNameplateFrames()
        enemyNameplateMapLogKey = nil
        return
    end

    local now = GetTime()
    UpdateEnemyArenaStates(now)

    local mapping = BuildArenaToNameplateMap()
    local shownAny = false
    for i = 1, 3 do
        local shown = RenderEnemyNameplateFrame(i, enemyNameplateStates[i], mapping[i], now)
        if shown then
            shownAny = true
        end
    end

    if IsArenaLoggingEnabled() and arenaLog.current and arenaLog.inArena then
        local key = string.format(
            "a1=%s|a2=%s|a3=%s|shown=%s",
            SafeToText(mapping[1]),
            SafeToText(mapping[2]),
            SafeToText(mapping[3]),
            shownAny and "1" or "0"
        )
        if enemyNameplateMapLogKey ~= key then
            enemyNameplateMapLogKey = key
            ArenaLogf(
                "np-map a1=%s a2=%s a3=%s shown=%s",
                SafeToText(mapping[1]),
                SafeToText(mapping[2]),
                SafeToText(mapping[3]),
                shownAny and "yes" or "no"
            )
        end
    end
end

local function UpdateEnemyTargetFocusMode()
    if not db or not db.enabled then
        HideEnemyTargetFocusFrames()
        enemyTargetFocusMapLogKey = nil
        return
    end
    if not IsInArena() or not FDR_EnsureDRList() then
        HideEnemyTargetFocusFrames()
        enemyTargetFocusMapLogKey = nil
        return
    end

    local now = GetTime()
    UpdateEnemyArenaStates(now)

    local targetFrame = _G.TargetFrame
    local focusFrame = _G.FocusFrame

    local targetIndex = GetArenaIndexForUnitToken("target")
    local focusIndex = GetArenaIndexForUnitToken("focus")

    local targetTray = EnsureEnemyTargetFocusFrame("target")
    local focusTray = EnsureEnemyTargetFocusFrame("focus")

    local targetShown = false
    local focusShown = false

    if targetIndex and targetFrame and targetFrame:IsShown() then
        targetShown = RenderEnemyTrayAtAnchor(
            targetTray,
            enemyNameplateStates[targetIndex],
            targetFrame,
            targetFrame,
            db.enemyTargetOffsetX or 0,
            db.enemyTargetOffsetY or 0,
            db.enemyTargetScale or db.trayScale or 1,
            now
        )
    else
        targetTray:Hide()
    end

    if focusIndex and focusFrame and focusFrame:IsShown() then
        focusShown = RenderEnemyTrayAtAnchor(
            focusTray,
            enemyNameplateStates[focusIndex],
            focusFrame,
            focusFrame,
            db.enemyFocusOffsetX or 0,
            db.enemyFocusOffsetY or 0,
            db.enemyFocusScale or db.trayScale or 1,
            now
        )
    else
        focusTray:Hide()
    end

    if IsArenaLoggingEnabled() and arenaLog.current and arenaLog.inArena then
        local key = string.format(
            "target=%s|focus=%s|shown=%s/%s",
            SafeToText(targetIndex),
            SafeToText(focusIndex),
            targetShown and "1" or "0",
            focusShown and "1" or "0"
        )
        if enemyTargetFocusMapLogKey ~= key then
            enemyTargetFocusMapLogKey = key
            ArenaLogf(
                "tf-map target=%s focus=%s shown=%s/%s",
                SafeToText(targetIndex),
                SafeToText(focusIndex),
                targetShown and "yes" or "no",
                focusShown and "yes" or "no"
            )
        end
    end
end

local function GetEnemyOpenWorldState(guid)
    if type(guid) ~= "string" then
        return nil
    end
    local state = enemyOpenWorldStates[guid]
    if not state then
        state = { categories = {} }
        enemyOpenWorldStates[guid] = state
    end
    return state
end

local function PruneEnemyOpenWorldStates(now)
    for guid, state in pairs(enemyOpenWorldStates) do
        local keep = false
        if state and type(state.categories) == "table" then
            for category, categoryState in pairs(state.categories) do
                if categoryState.active then
                    keep = true
                else
                    if categoryState.resetAt and now >= categoryState.resetAt then
                        categoryState.count = 0
                        categoryState.resetAt = nil
                    end
                    local hasDR = (categoryState.count or 0) > 0 and categoryState.resetAt and categoryState.resetAt > now
                    if hasDR then
                        keep = true
                    elseif (categoryState.count or 0) <= 0 and not categoryState.resetAt and not categoryState.icon then
                        state.categories[category] = nil
                    end
                end
            end
        end
        if not keep then
            enemyOpenWorldStates[guid] = nil
        end
    end
end

local function UpdateEnemyOpenWorldNameplateMode()
    if not db or not db.enabled or IsInArena() or not IsEnemyOpenWorldNameplateEnabled() then
        HideEnemyOpenWorldNameplateFrames()
        enemyOpenWorldNameplateMapLogKey = nil
        return
    end
    if not FDR_EnsureDRList() then
        HideEnemyOpenWorldNameplateFrames()
        return
    end

    local now = GetTime()
    local seenTokens = {}
    local mapping = {}

    for i = 1, 40 do
        local token = "nameplate" .. i
        if FDR_SafeUnitExists(token) and FDR_SafeUnitIsEnemy("player", token) then
            local guid = FDR_SafeUnitGUID(token)
            if guid then
                local state = GetEnemyOpenWorldState(guid)
                if state then
                    local usedEvent = false
                    if FDR_IsSpellDiminishSystemReady() then
                        usedEvent = FDR_ApplySpellDiminishStateToEnemyUnit(state, token, now)
                    end
                    if not usedEvent then
                        local usedAuras = FDR_UpdateEnemyUnitStateFromAuras(state, token, now)
                        if (not usedAuras) and FDR_ShouldUseLossOfControlFallback(token, now) then
                            UpdateEnemyArenaUnitState(state, token, now)
                        end
                    end
                    local tray = EnsureEnemyOpenWorldNameplateFrame(token)
                    local plate = GetNamePlateForToken(token)
                    local anchor = GetNameplateAnchorForEnemyTray(plate)
                    if FDR_SafeIsObject(anchor) and FDR_SafeIsObject(plate) then
                        local shown = RenderEnemyTrayAtAnchor(tray, state, anchor, plate, db.offsetX or 0, db.offsetY or 0, db.trayScale or 1, now, plate)
                        if shown then
                            mapping[token] = guid
                        else
                            tray:Hide()
                        end
                    else
                        tray:Hide()
                    end
                end
            end
            seenTokens[token] = true
        end
    end

    for token, tray in pairs(enemyOpenWorldNameplateFrames) do
        if not seenTokens[token] then
            tray:Hide()
        end
    end

    PruneEnemyOpenWorldStates(now)

    if IsArenaLoggingEnabled() and db.debug then
        local key = string.format(
            "openworld np count=%d",
            (function()
                local c = 0
                for _ in pairs(mapping) do
                    c = c + 1
                end
                return c
            end)()
        )
        if enemyOpenWorldNameplateMapLogKey ~= key then
            enemyOpenWorldNameplateMapLogKey = key
            DebugPrint(key)
        end
    end
end

local function UpdateEnemyOpenWorldTargetFocusMode()
    if not db or not db.enabled or IsInArena() or not IsEnemyOpenWorldTargetFocusEnabled() then
        local targetTray = enemyTargetFocusFrames.target
        if targetTray then
            targetTray:Hide()
        end
        local focusTray = enemyTargetFocusFrames.focus
        if focusTray then
            focusTray:Hide()
        end
        enemyOpenWorldTargetFocusMapLogKey = nil
        return
    end
    if not FDR_EnsureDRList() then
        HideEnemyTargetFocusFrames()
        return
    end

    local now = GetTime()
    local targetFrame = _G.TargetFrame
    local focusFrame = _G.FocusFrame
    local targetTray = EnsureEnemyTargetFocusFrame("target")
    local focusTray = EnsureEnemyTargetFocusFrame("focus")

    local targetGuid = nil
    local focusGuid = nil
    local targetShown = false
    local focusShown = false

    if targetFrame and targetFrame:IsShown() and FDR_SafeUnitExists("target") and FDR_SafeUnitIsEnemy("player", "target") then
        targetGuid = FDR_SafeUnitGUID("target")
        local state = GetEnemyOpenWorldState(targetGuid)
        if state then
            local usedEvent = false
            if FDR_IsSpellDiminishSystemReady() then
                usedEvent = FDR_ApplySpellDiminishStateToEnemyUnit(state, "target", now)
            end
            if not usedEvent then
                local usedAuras = FDR_UpdateEnemyUnitStateFromAuras(state, "target", now)
                if (not usedAuras) and FDR_ShouldUseLossOfControlFallback("target", now) then
                    UpdateEnemyArenaUnitState(state, "target", now)
                end
            end
            targetShown = RenderEnemyTrayAtAnchor(
                targetTray,
                state,
                targetFrame,
                targetFrame,
                db.enemyTargetOffsetX or 0,
                db.enemyTargetOffsetY or 0,
                db.enemyTargetScale or db.trayScale or 1,
                now
            )
        end
    else
        targetTray:Hide()
    end

    if focusFrame and focusFrame:IsShown() and FDR_SafeUnitExists("focus") and FDR_SafeUnitIsEnemy("player", "focus") then
        focusGuid = FDR_SafeUnitGUID("focus")
        local state = GetEnemyOpenWorldState(focusGuid)
        if state then
            if not (targetGuid and focusGuid and FDR_SafeStringEquals(targetGuid, focusGuid)) then
                local usedEvent = false
                if FDR_IsSpellDiminishSystemReady() then
                    usedEvent = FDR_ApplySpellDiminishStateToEnemyUnit(state, "focus", now)
                end
                if not usedEvent then
                    local usedAuras = FDR_UpdateEnemyUnitStateFromAuras(state, "focus", now)
                    if (not usedAuras) and FDR_ShouldUseLossOfControlFallback("focus", now) then
                        UpdateEnemyArenaUnitState(state, "focus", now)
                    end
                end
            end
            focusShown = RenderEnemyTrayAtAnchor(
                focusTray,
                state,
                focusFrame,
                focusFrame,
                db.enemyFocusOffsetX or 0,
                db.enemyFocusOffsetY or 0,
                db.enemyFocusScale or db.trayScale or 1,
                now
            )
        end
    else
        focusTray:Hide()
    end

    PruneEnemyOpenWorldStates(now)

    if IsArenaLoggingEnabled() and db.debug then
        local key = string.format(
            "openworld tf target=%s focus=%s shown=%s/%s",
            SafeToText(targetGuid),
            SafeToText(focusGuid),
            targetShown and "1" or "0",
            focusShown and "1" or "0"
        )
        if enemyOpenWorldTargetFocusMapLogKey ~= key then
            enemyOpenWorldTargetFocusMapLogKey = key
            DebugPrint(key)
        end
    end
end

local function EnsureTestTrayFor(key)
    if not testTrays then
        testTrays = {}
    end
    if testTrays[key] then
        return testTrays[key]
    end

    local tray = CreateFrame("Frame", nil, UIParent)
    tray.items = {}
    tray.iconSize = 26
    tray.iconSpacing = 2
    tray.NPDRS_TimerElapsed = 0

    local now = GetTime()
    tray.demoItems = BuildRandomTestItems(3, now)
    tray.NPDRS_TestKey = GetVisibleCategoryKey()

    for i = 1, #tray.demoItems do
        local sample = tray.demoItems[i]
        local item = CreateFrame("Frame", nil, tray)
        item:SetSize(tray.iconSize, tray.iconSize)
        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetAllPoints(item)
        item.NPDRS_DefaultTexture = sample.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        item.icon:SetTexture(item.NPDRS_DefaultTexture)

        item.cooldown = CreateFrame("Cooldown", nil, item, "CooldownFrameTemplate")
        item.cooldown:SetAllPoints(item)
        item.cooldown:SetDrawEdge(false)
        item.cooldown:SetDrawSwipe(false)
        item.cooldown:SetHideCountdownNumbers(true)
        item.cooldown:SetAlpha(0)

        item.timerText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
        if item.timerText.SetFont then
            item.timerText:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
        end

        item.stageText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.stageText:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
        if item.stageText.SetFont then
            item.stageText:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
        end

        item.bg = item:CreateTexture(nil, "BACKGROUND")
        item.bg:SetAllPoints(item)

        EnsureSolidBorder(item)
        tray.items[i] = item
    end

    tray:SetScript("OnUpdate", function(self, elapsed)
        self.NPDRS_TimerElapsed = (self.NPDRS_TimerElapsed or 0) + elapsed
        if self.NPDRS_TimerElapsed < 0.1 then
            return
        end
        self.NPDRS_TimerElapsed = 0

        local nowTime = GetTime()
        for i, data in ipairs(self.demoItems or {}) do
            local item = self.items[i]
            if item and item:IsShown() then
                if not data.active and data.resetAt then
                    local remaining = data.resetAt - nowTime
                    if remaining > 0 then
                        SetTextStyle(item, data.stage, remaining, true)
                    else
                        -- Keep the test mode alive by looping the sample timer.
                        data.resetAt = nowTime + ENEMY_DR_RESET_TIME
                        if data.stage == "IMM" then
                            data.stage = "1/2"
                            data.bgColor = { 0, 1, 0, 0.25 }
                        else
                            data.stage = "IMM"
                            data.bgColor = { 0.8, 0.2, 0.2, 0.25 }
                        end
                        SetTextStyle(item, data.stage, ENEMY_DR_RESET_TIME, true)
                    end
                else
                    SetTextStyle(item, data.stage, nil, false)
                end
            end
        end
    end)

    testTrays[key] = tray
    return tray
end

local function RefreshTestTraySamples(tray, force)
    if not tray then
        return
    end
    local key = GetVisibleCategoryKey()
    if force or not tray.demoItems or tray.NPDRS_TestKey ~= key then
        tray.demoItems = BuildRandomTestItems(3, GetTime())
        tray.NPDRS_TestKey = key
    end
end

local function EnsureTestTray()
    if testTray then
        return testTray
    end
    testTray = EnsureTestTrayFor("nameplate")
    return testTray
end

local function HideTestTrayFor(key)
    if testTrays and testTrays[key] then
        testTrays[key]:Hide()
    end
end

local function HideAllTestTrays()
    if testTray then
        testTray:Hide()
    end
    if testTrays then
        for _, tray in pairs(testTrays) do
            tray:Hide()
        end
    end
end

local function LayoutTestTray(tray, anchor, offsetX, offsetY, scale, source, plateForParent, forcedParent)
    if not (tray and anchor) then
        return
    end
    ApplyTrayAnchor(tray, anchor, plateForParent, offsetX, offsetY, scale, forcedParent)
    tray:SetFrameStrata("HIGH")

    local samples = tray.demoItems or {}
    local visibleSamples = {}
    for i = 1, #samples do
        local sample = samples[i]
        if sample and IsCategoryVisible(sample.category) then
            visibleSamples[#visibleSamples + 1] = sample
        end
    end
    local count = #visibleSamples
    local spacing = GetIconSpacing()
    tray.iconSpacing = spacing
    local width = (count * tray.iconSize) + math.max(0, (count - 1) * spacing)
    tray:SetSize(width, tray.iconSize)

    local now = GetTime()
    for i = 1, #tray.items do
        local item = tray.items[i]
        local sample = visibleSamples[i]
        item:ClearAllPoints()
        if i == 1 then
            item:SetPoint("RIGHT", tray, "RIGHT", 0, 0)
        else
            item:SetPoint("RIGHT", tray.items[i - 1], "LEFT", -spacing, 0)
        end

        if sample then
            item.NPDRS_DefaultTexture = sample.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            ApplyIconVisual(item, sample.category, item.NPDRS_DefaultTexture, sample.stage == "IMM")

            if sample.bgColor then
                item.bg:SetColorTexture(sample.bgColor[1], sample.bgColor[2], sample.bgColor[3], sample.bgColor[4] or 0.25)
                item.bg:Show()
            else
                item.bg:Hide()
            end

            local remaining = nil
            if not sample.active and sample.resetAt and sample.resetAt > now then
                local start = sample.resetAt - ENEMY_DR_RESET_TIME
                item.cooldown:SetCooldown(start, ENEMY_DR_RESET_TIME)
                item.cooldown:Show()
                remaining = sample.resetAt - now
            else
                item.cooldown:SetCooldown(0, 0)
                item.cooldown:Hide()
            end
            SetTextStyle(item, sample.stage, remaining, remaining and remaining > 0)

            item:Show()
        else
            item:Hide()
        end
    end

    tray:Show()

    if db and db.debug then
        local tag = string.format("test src=%s offx=%s offy=%s", tostring(source), tostring(offsetX), tostring(offsetY))
        if tray.NPDRS_LastDebug ~= tag then
            tray.NPDRS_LastDebug = tag
            DebugPrint(tag)
        end
    end
end

local function UpdateTestTray()
    if not db or not db.testMode or IsInArena() then
        if testTray then
            testTray:Hide()
        end
        return
    end

    local anchor, source, plate = GetTestAnchor()
    if not FDR_SafeIsObject(anchor) then
        if testTray then
            testTray:Hide()
        end
        return
    end

    local tray = EnsureTestTray()
    RefreshTestTraySamples(tray, not tray:IsShown())
    local offsetX = db.offsetX
    local offsetY = db.offsetY
    LayoutTestTray(tray, anchor, offsetX, offsetY, db.trayScale or 1, source, plate, plate)
end

local function UpdateTargetFocusTestTrays()
    if not db or not db.enemyTargetFocusTestMode or IsInArena() then
        HideTestTrayFor("target")
        HideTestTrayFor("focus")
        return
    end

    local targetFrame = _G.TargetFrame
    if targetFrame and targetFrame:IsShown() then
        local tray = EnsureTestTrayFor("target")
        RefreshTestTraySamples(tray, not tray:IsShown())
        LayoutTestTray(tray, targetFrame, db.enemyTargetOffsetX or 0, db.enemyTargetOffsetY or 0, db.enemyTargetScale or db.trayScale or 1, "target", targetFrame, nil)
    else
        HideTestTrayFor("target")
    end

    local focusFrame = _G.FocusFrame
    if focusFrame and focusFrame:IsShown() then
        local tray = EnsureTestTrayFor("focus")
        RefreshTestTraySamples(tray, not tray:IsShown())
        LayoutTestTray(tray, focusFrame, db.enemyFocusOffsetX or 0, db.enemyFocusOffsetY or 0, db.enemyFocusScale or db.trayScale or 1, "focus", focusFrame, nil)
    else
        HideTestTrayFor("focus")
    end
end

local function MoveArenaTrays()
    if not db or not db.enabled then
        SetArenaTrayHidden(false)
        HideEnemyNameplateFrames()
        HideEnemyOpenWorldNameplateFrames()
        HideEnemyTargetFocusFrames()
        table.wipe(enemyNameplateStates)
        table.wipe(enemyOpenWorldStates)
        FDR_ClearSpellDiminishStores()
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
        enemyTargetFocusMapLogKey = nil
        enemyOpenWorldNameplateMapLogKey = nil
        enemyOpenWorldTargetFocusMapLogKey = nil
        return false
    end

    local route = GetEnemyRoutingState()

    if not route.inArena then
        HideEnemyNameplateFrames()
        table.wipe(enemyNameplateStates)
        FDR_ClearSpellDiminishStores()
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
        enemyTargetFocusMapLogKey = nil
        SetArenaTrayHidden(false)

        if route.showNameplate then
            UpdateEnemyOpenWorldNameplateMode()
        else
            HideEnemyOpenWorldNameplateFrames()
            enemyOpenWorldNameplateMapLogKey = nil
        end

        if route.showTargetFocus then
            UpdateEnemyOpenWorldTargetFocusMode()
        else
            HideEnemyTargetFocusFrames()
            enemyOpenWorldTargetFocusMapLogKey = nil
        end
        return true
    end

    HideEnemyOpenWorldNameplateFrames()
    table.wipe(enemyOpenWorldStates)
    enemyOpenWorldNameplateMapLogKey = nil
    enemyOpenWorldTargetFocusMapLogKey = nil

    if route.showNameplate then
        UpdateEnemyNameplateMode()
    else
        HideEnemyNameplateFrames()
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
    end

    if route.showTargetFocus then
        UpdateEnemyTargetFocusMode()
    else
        HideEnemyTargetFocusFrames()
        enemyTargetFocusMapLogKey = nil
    end

    local hideArenaTrays = db.enemyHideArenaTrays == true
    SetArenaTrayHidden(hideArenaTrays)

    return true
end

RestoreAllTrays = function()
    SetArenaTrayHidden(false)
end

local configFrame
local optionSliderCounter = 0

ApplySettings = function()
    if not db then
        InitDB()
    end
    FDR_RefreshDB()
    FDR_NormalizePersistedDB()
    SaveDB()
    UpdateArenaLogSessionState()
    local experimental = _G.NameplateDRs_Experimental
    if experimental and experimental.SetEnabled then
        experimental.SetEnabled(false)
    end
    local friendly = _G.NameplateDRs_Friendly
    if friendly and friendly.SetEnabled then
        friendly.SetEnabled(db.friendlyTracking and db.enabled)
    end
    if friendly and friendly.ApplySettings then
        friendly.ApplySettings()
    end
    if not db.enabled then
        SetArenaTrayHidden(false)
        HideEnemyNameplateFrames()
        HideEnemyOpenWorldNameplateFrames()
        HideEnemyTargetFocusFrames()
        table.wipe(enemyNameplateStates)
        table.wipe(enemyOpenWorldStates)
        FDR_ClearSpellDiminishStores()
        ClearArenaNameplateLinks()
        enemyNameplateMapLogKey = nil
        enemyTargetFocusMapLogKey = nil
        enemyOpenWorldNameplateMapLogKey = nil
        enemyOpenWorldTargetFocusMapLogKey = nil
        RestoreAllTrays()
        HideAllTestTrays()
        SaveDB()
        return
    end
    MoveArenaTrays()
    if IsEnemyNameplateEnabled() and db.testMode and not IsInArena() then
        UpdateTestTray()
    else
        HideTestTrayFor("nameplate")
    end
    if IsEnemyTargetFocusEnabled() and db.enemyTargetFocusTestMode and not IsInArena() then
        UpdateTargetFocusTestTrays()
    else
        HideTestTrayFor("target")
        HideTestTrayFor("focus")
    end
    SaveDB()
end

function FDR_CreateCheckbox(parent, label, initial, onToggle)
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkbox.Text:SetText(label)
    checkbox:SetChecked(initial)
    checkbox:SetScript("OnClick", function(self)
        onToggle(self:GetChecked())
    end)
    return checkbox
end

function FDR_CreateSliderRow(parent, label, minValue, maxValue, step, initial, onChange, isFloat, rowWidth, sliderWidth)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(rowWidth or 440, 28)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(sliderWidth or 280)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    editBox:SetSize(60, 18)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)

    local function FormatValue(value)
        if isFloat then
            return string.format("%.2f", value)
        end
        return string.format("%d", value)
    end

    local function SetValue(value)
        if value == nil then
            value = minValue
        end
        slider:SetValue(value)
        editBox:SetText(FormatValue(value))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        if isFloat then
            value = FDR_SafeNumber(string.format("%.2f", value), value)
        else
            value = math.floor(value + 0.5)
        end
        editBox:SetText(FormatValue(value))
        onChange(value)
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local value = FDR_SafeNumber(text, nil)
        if not value then
            value = initial
        end
        if value < minValue then
            value = minValue
        elseif value > maxValue then
            value = maxValue
        end
        SetValue(value)
        onChange(value)
        self:ClearFocus()
    end)

    SetValue(initial)
    return frame
end

function FDR_CreateOptionSliderRow(parent, label, options, initialValue, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(440, 44)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    optionSliderCounter = optionSliderCounter + 1
    local sliderName = "NameplateDRsOptionSlider" .. optionSliderCounter
    local slider = CreateFrame("Slider", sliderName, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(220)
    slider:SetMinMaxValues(1, #options)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    local low = _G[sliderName .. "Low"]
    if low then
        low:Hide()
    end
    local high = _G[sliderName .. "High"]
    if high then
        high:Hide()
    end
    local text = _G[sliderName .. "Text"]
    if text then
        text:Hide()
    end

    local valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:Hide()

    local valueToIndex = {}
    for i, opt in ipairs(options) do
        valueToIndex[opt.value] = i
    end

    local optionLabels = {}
    for i, opt in ipairs(options) do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetText(opt.label)
        if #options == 1 then
            label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
        elseif #options == 2 then
            if i == 1 then
                label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
            else
                label:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
            end
        elseif #options == 3 then
            if i == 1 then
                label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
            elseif i == 2 then
                label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
            else
                label:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
            end
        else
            local width = slider:GetWidth()
            local x = ((i - 1) / (#options - 1)) * width
            label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", x, -2)
        end
        optionLabels[i] = label
    end

    local function SetIndex(idx)
        local index = math.floor(idx + 0.5)
        if index < 1 then
            index = 1
        elseif index > #options then
            index = #options
        end
        slider:SetValue(index)
        for i, label in ipairs(optionLabels) do
            if i == index then
                label:SetTextColor(1, 0.82, 0, 1)
            else
                label:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end
        onChange(options[index].value)
    end

    slider:SetScript("OnValueChanged", function(self, value)
        SetIndex(value)
    end)

    SetIndex(valueToIndex[initialValue] or 1)
    return frame
end

function FDR_CreateDropdownRow(parent, label, options, initial, onChange, rowWidth, dropdownWidth)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(rowWidth or 440, 30)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    local dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropdown, dropdownWidth or 200)
    local function BuildOptionText(option)
        if option and option.icon then
            return string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", tostring(option.icon), option.label or "")
        end
        return option and option.label or ""
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = BuildOptionText(option)
            info.value = option.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, option.value)
                onChange(option.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, initial)
    frame.title = title
    frame.dropdown = dropdown
    return frame
end

local DR_CATEGORY_UI_ORDER = { "stun", "incap", "disorient", "silence", "disarm", "root" }
local DR_CATEGORY_UI_LABEL = {
    stun = "Stun",
    incap = "Incapacitate",
    disorient = "Disorient",
    silence = "Silence",
    disarm = "Disarm",
    root = "Root",
}

function FDR_GetCategoryIconDropdownOptions(category)
    local options = {
        { value = 0, label = "Default" },
    }

    if not FDR_EnsureDRList() or not (DRList and DRList.GetSpells) then
        return options
    end

    local spells = DRList:GetSpells()
    if type(spells) ~= "table" then
        return options
    end

    local seen = {}
    local list = {}
    for spellID, cat in pairs(spells) do
        local normalized = cat
        if type(normalized) == "table" then
            normalized = normalized[1]
        end
        normalized = NormalizeEnemyDRCategory(normalized)
        if normalized == category and type(spellID) == "number" and not seen[spellID] then
            seen[spellID] = true
            local spellName = FDR_SafeSpellName(spellID)
            if spellName then
                list[#list + 1] = {
                    value = spellID,
                    label = string.format("%s (%d)", spellName, spellID),
                    icon = FDR_SafeSpellTexture(spellID),
                }
            end
        end
    end

    table.sort(list, function(a, b)
        return a.label < b.label
    end)
    for i = 1, #list do
        options[#options + 1] = list[i]
    end
    return options
end

local function CreateTabButton(parent, text, width)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(width, 24)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.label:SetPoint("CENTER")
    tab.label:SetText(text)
    return tab
end

local function BuildTopLevelTabs(configFrame, donateBox)
    local tabGeneral = CreateTabButton(configFrame, "General", 95)
    tabGeneral:SetPoint("TOPLEFT", donateBox, "BOTTOMLEFT", 0, -10)

    local tab1 = CreateTabButton(configFrame, "PvP Enemy DRs", 170)
    tab1:SetPoint("LEFT", tabGeneral, "RIGHT", 6, 0)

    local tab2 = CreateTabButton(configFrame, "PvP Friendly DRs", 170)
    tab2:SetPoint("LEFT", tab1, "RIGHT", 6, 0)

    local generalFrame = CreateFrame("Frame", nil, configFrame)
    generalFrame:SetPoint("TOPLEFT", tabGeneral, "BOTTOMLEFT", 0, -8)
    generalFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -16, 0)
    generalFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 16, 16)
    generalFrame:Hide()

    local enemyFrame = CreateFrame("Frame", nil, configFrame)
    enemyFrame:SetPoint("TOPLEFT", tabGeneral, "BOTTOMLEFT", 0, -8)
    enemyFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -16, 0)
    enemyFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 16, 16)
    enemyFrame:Hide()

    local friendlyFrame = CreateFrame("Frame", nil, configFrame)
    friendlyFrame:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    friendlyFrame:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    friendlyFrame:Hide()

    local function StyleTab(tab, active)
        if active then
            tab:SetBackdropColor(0.45, 0.85, 1.0, 0.5)
            tab:SetBackdropBorderColor(0.2, 1.0, 0.35, 0.5)
            if tab.label then
                tab.label:SetTextColor(1, 1, 1, 1)
            end
        else
            tab:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
            tab:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
            if tab.label then
                tab.label:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end
    end

    local function SelectTab(index)
        generalFrame:SetShown(index == 1)
        enemyFrame:SetShown(index == 2)
        friendlyFrame:SetShown(index == 3)
        StyleTab(tabGeneral, index == 1)
        StyleTab(tab1, index == 2)
        StyleTab(tab2, index == 3)
    end

    tabGeneral:SetScript("OnClick", function()
        SelectTab(1)
    end)
    tab1:SetScript("OnClick", function()
        SelectTab(2)
    end)
    tab2:SetScript("OnClick", function()
        SelectTab(3)
    end)

    return SelectTab, generalFrame, enemyFrame, friendlyFrame
end

local function BuildEnemyAndGeneralUI(generalFrame, enemyFrame)
    local function CreateSeparator(parent, anchor, offsetY)
        local sep = parent:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(1, 1, 1, 0.08)
        sep:SetHeight(1)
        sep:SetPoint("LEFT", parent, "LEFT", 0, 0)
        sep:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        sep:SetPoint("TOP", anchor, "BOTTOM", 0, offsetY or -12)
        return sep
    end

    local enemySubTabBar = CreateFrame("Frame", nil, enemyFrame)
    enemySubTabBar:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    enemySubTabBar:SetSize(520, 24)

    local enemySubNameplateBtn = CreateTabButton(enemySubTabBar, "Nameplate DRs", 130)
    enemySubNameplateBtn:SetPoint("TOPLEFT", enemySubTabBar, "TOPLEFT", 0, 0)

    local enemySubTargetFocusBtn = CreateTabButton(enemySubTabBar, "Target/Focus DRs", 140)
    enemySubTargetFocusBtn:SetPoint("LEFT", enemySubNameplateBtn, "RIGHT", 4, 0)

    local enemyGeneralSub = CreateFrame("Frame", nil, generalFrame)
    enemyGeneralSub:SetPoint("TOPLEFT", generalFrame, "TOPLEFT", 0, 0)
    enemyGeneralSub:SetPoint("BOTTOMRIGHT", generalFrame, "BOTTOMRIGHT", 0, 0)

    local enemyNameplateSub = CreateFrame("Frame", nil, enemyFrame)
    enemyNameplateSub:SetPoint("TOPLEFT", enemySubTabBar, "BOTTOMLEFT", 0, -8)
    enemyNameplateSub:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    enemyNameplateSub:Hide()

    local enemyTargetFocusSub = CreateFrame("Frame", nil, enemyFrame)
    enemyTargetFocusSub:SetPoint("TOPLEFT", enemySubTabBar, "BOTTOMLEFT", 0, -8)
    enemyTargetFocusSub:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    enemyTargetFocusSub:Hide()

    local function StyleEnemySubTab(tab, active)
        if active then
            tab:SetBackdropColor(0.45, 0.85, 1.0, 0.5)
            tab:SetBackdropBorderColor(0.2, 1.0, 0.35, 0.5)
            if tab.label then
                tab.label:SetTextColor(1, 1, 1, 1)
            end
            return
        end
        tab:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        tab:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
        if tab.label then
            tab.label:SetTextColor(0.72, 0.72, 0.72, 1)
        end
    end

    local function SelectEnemySubTab(index)
        enemyNameplateSub:SetShown(index == 1)
        enemyTargetFocusSub:SetShown(index == 2)
        StyleEnemySubTab(enemySubNameplateBtn, index == 1)
        StyleEnemySubTab(enemySubTargetFocusBtn, index == 2)
    end

    enemySubNameplateBtn:SetScript("OnClick", function()
        SelectEnemySubTab(1)
    end)
    enemySubTargetFocusBtn:SetScript("OnClick", function()
        SelectEnemySubTab(2)
    end)

    local enemyGeneralTitle = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyGeneralTitle:SetPoint("TOPLEFT", enemyGeneralSub, "TOPLEFT", 0, 0)
    enemyGeneralTitle:SetText("General")

    local borderStyleOptions = {
        { value = "none", label = "None" },
        { value = "solid", label = "Solid" },
        { value = "soft", label = "Soft" },
        { value = "glow", label = "Glow" },
        { value = "halo", label = "Halo" },
        { value = "dashed", label = "Dashed" },
        { value = "wideglow", label = "Wide Glow" },
    }

    local borderStyleRow = FDR_CreateDropdownRow(enemyGeneralSub, "DR Icon Border Style", borderStyleOptions, db.iconBorderStyle or "solid", function(v)
        SetDBValue("iconBorderStyle", v)
        ApplySettings()
    end, 420, 180)
    borderStyleRow:SetPoint("TOPLEFT", enemyGeneralTitle, "BOTTOMLEFT", -2, -6)

    local borderThicknessRow = FDR_CreateSliderRow(enemyGeneralSub, "Border Thickness", 0.5, 3.0, 0.05, db.iconBorderThickness or 1.0, function(v)
        SetDBValue("iconBorderThickness", v)
        ApplySettings()
    end, true, 220, 120)
    borderThicknessRow:SetPoint("TOPLEFT", borderStyleRow, "TOPRIGHT", 14, 0)

    local zoomCheckbox = FDR_CreateCheckbox(enemyGeneralSub, "Zoom DR icons by 7% (hide default icon edge)", db.iconZoomEnabled == true, function(checked)
        SetDBValue("iconZoomEnabled", checked)
        ApplySettings()
    end)
    zoomCheckbox:SetPoint("TOPLEFT", borderStyleRow, "BOTTOMLEFT", 0, -12)
    if zoomCheckbox.Text then
        zoomCheckbox.Text:SetWidth(420)
        zoomCheckbox.Text:SetWordWrap(true)
    end

    local infoTextStyleOptions = {
        { value = "blizz", label = "Blizz" },
        { value = "modern_colored", label = "Modern Lean Coloured" },
        { value = "modern_white", label = "Modern Lean White" },
        { value = "retro", label = "Retro" },
        { value = "retro_text", label = "Retro Text" },
    }
    local infoTextStyleRow = FDR_CreateDropdownRow(enemyGeneralSub, "DR Icon Info Text Style", infoTextStyleOptions, db.iconInfoTextStyle or "blizz", function(v)
        SetDBValue("iconInfoTextStyle", v)
        ApplySettings()
    end, 420, 200)
    infoTextStyleRow:SetPoint("TOPLEFT", zoomCheckbox, "BOTTOMLEFT", -2, -10)

    local iconSpacingRow = FDR_CreateSliderRow(enemyGeneralSub, "DR Icon Spacing", 0, 12, 1, db.iconSpacing or 2, function(v)
        SetDBValue("iconSpacing", v)
        ApplySettings()
    end, false, 420, 280)
    iconSpacingRow:SetPoint("TOPLEFT", infoTextStyleRow, "BOTTOMLEFT", 0, -16)

    local categoryHeader = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryHeader:SetPoint("TOPLEFT", iconSpacingRow, "BOTTOMLEFT", 2, -16)
    categoryHeader:SetText("Per-Category DR Icon Override")

    local categoryHelp = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    categoryHelp:SetPoint("TOPLEFT", categoryHeader, "BOTTOMLEFT", 0, -2)
    categoryHelp:SetText("Pick fixed icons and toggle categories on/off (applies to all DR displays/test modes).")

    local colX = { 0, 250 }
    local colY = { -20, -70, -120 }
    for idx, category in ipairs(DR_CATEGORY_UI_ORDER) do
        local col = ((idx - 1) % 2) + 1
        local row = math.floor((idx - 1) / 2) + 1
        local overrideTable = db.drCategoryIconOverrides or {}
        local selected = overrideTable[category] or 0
        local options = FDR_GetCategoryIconDropdownOptions(category)
        local rowWidget = FDR_CreateDropdownRow(
            enemyGeneralSub,
            (DR_CATEGORY_UI_LABEL[category] or category) .. " Icon",
            options,
            selected,
            function(v)
                local map = {}
                local src = db.drCategoryIconOverrides
                if type(src) == "table" then
                    for k, value in pairs(src) do
                        map[k] = value
                    end
                end
                local parsed = FDR_SafeNumber(v, nil)
                if parsed and parsed > 0 then
                    map[category] = parsed
                else
                    map[category] = nil
                end
                SetDBValue("drCategoryIconOverrides", map)
                ApplySettings()
            end,
            240,
            190
        )
        rowWidget:SetPoint("TOPLEFT", categoryHelp, "BOTTOMLEFT", colX[col], colY[row])

        local visibilityMap = db.drCategoryVisibility or {}
        local isVisible = visibilityMap[category] ~= false
        local visibilityToggle = FDR_CreateCheckbox(enemyGeneralSub, "", isVisible, function(checked)
            local map = {}
            local src = db.drCategoryVisibility
            if type(src) == "table" then
                for k, value in pairs(src) do
                    map[k] = value
                end
            end
            if checked == false then
                map[category] = false
            else
                map[category] = nil
            end
            SetDBValue("drCategoryVisibility", map)
            ApplySettings()
        end)
        if visibilityToggle.Text then
            visibilityToggle.Text:SetText("")
            visibilityToggle.Text:Hide()
        end
        if rowWidget.title then
            visibilityToggle:SetPoint("LEFT", rowWidget.title, "RIGHT", 6, 0)
        else
            visibilityToggle:SetPoint("TOPLEFT", rowWidget, "TOPRIGHT", -18, 0)
        end
    end

    local enemyNameplateTitle = enemyNameplateSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyNameplateTitle:SetPoint("TOPLEFT", enemyNameplateSub, "TOPLEFT", 0, 0)
    enemyNameplateTitle:SetText("Nameplate DRs")

    local checkboxEnemyNameplate = FDR_CreateCheckbox(enemyNameplateSub, "Enable nameplate DRs", IsEnemyNameplateEnabled(), function(checked)
        SetDBValue("enemyShowNameplates", checked)
        ApplySettings()
    end)
    checkboxEnemyNameplate:SetPoint("TOPLEFT", enemyNameplateTitle, "BOTTOMLEFT", -2, -6)

    local checkboxEnemyHideArenaTrays = FDR_CreateCheckbox(enemyNameplateSub, "Hide Blizzard arena DR trays", db.enemyHideArenaTrays == true, function(checked)
        SetDBValue("enemyHideArenaTrays", checked)
        ApplySettings()
    end)
    checkboxEnemyHideArenaTrays:SetPoint("TOPLEFT", checkboxEnemyNameplate, "BOTTOMLEFT", 0, -4)

    local checkboxTest = FDR_CreateCheckbox(enemyNameplateSub, "Test mode (target something in open world)", db.testMode, function(checked)
        SetDBValue("testMode", checked)
        ApplySettings()
    end)
    checkboxTest:SetPoint("TOPLEFT", checkboxEnemyHideArenaTrays, "BOTTOMLEFT", 0, -4)
    if checkboxTest.Text then
        checkboxTest.Text:SetWidth(420)
        checkboxTest.Text:SetWordWrap(true)
    end

    local note = enemyNameplateSub:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", checkboxTest, "BOTTOMLEFT", 2, -6)
    note:SetWidth(420)
    note:SetJustifyH("LEFT")
    note:SetText("Offsets apply to the active nameplate system (Platynator or Plater if loaded).")

    local row1 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Offset X", -100, 100, 1, db.offsetX, function(v)
        SetDBValue("offsetX", v)
        ApplySettings()
    end, false)
    row1:SetPoint("TOPLEFT", note, "BOTTOMLEFT", -2, -6)

    local row2 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Offset Y", -100, 100, 1, db.offsetY, function(v)
        SetDBValue("offsetY", v)
        ApplySettings()
    end, false)
    row2:SetPoint("TOPLEFT", row1, "BOTTOMLEFT", 0, -8)

    local row3 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Scale", 0.5, 1.5, 0.01, db.trayScale, function(v)
        SetDBValue("trayScale", v)
        ApplySettings()
    end, true)
    row3:SetPoint("TOPLEFT", row2, "BOTTOMLEFT", 0, -6)

    local enemyTargetFocusTitle = enemyTargetFocusSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyTargetFocusTitle:SetPoint("TOPLEFT", enemyTargetFocusSub, "TOPLEFT", 0, 0)
    enemyTargetFocusTitle:SetText("Target/Focus DRs")

    local checkboxEnemyTargetFocus = FDR_CreateCheckbox(enemyTargetFocusSub, "Enable target/focus DRs", IsEnemyTargetFocusEnabled(), function(checked)
        SetDBValue("enemyShowTargetFocus", checked)
        ApplySettings()
    end)
    checkboxEnemyTargetFocus:SetPoint("TOPLEFT", enemyTargetFocusTitle, "BOTTOMLEFT", -2, -6)

    local checkboxTargetFocusTest = FDR_CreateCheckbox(enemyTargetFocusSub, "Test mode (target/focus)", db.enemyTargetFocusTestMode, function(checked)
        SetDBValue("enemyTargetFocusTestMode", checked)
        ApplySettings()
    end)
    checkboxTargetFocusTest:SetPoint("TOPLEFT", checkboxEnemyTargetFocus, "BOTTOMLEFT", 0, -4)
    if checkboxTargetFocusTest.Text then
        checkboxTargetFocusTest.Text:SetWidth(420)
        checkboxTargetFocusTest.Text:SetWordWrap(true)
    end

    local row4 = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Offset X", -300, 300, 1, db.enemyTargetOffsetX, function(v)
        SetDBValue("enemyTargetOffsetX", v)
        ApplySettings()
    end, false)
    row4:SetPoint("TOPLEFT", checkboxTargetFocusTest, "BOTTOMLEFT", 0, -8)

    local row5 = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Offset Y", -300, 300, 1, db.enemyTargetOffsetY, function(v)
        SetDBValue("enemyTargetOffsetY", v)
        ApplySettings()
    end, false)
    row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)

    local row5b = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Scale", 0.5, 1.5, 0.01, db.enemyTargetScale, function(v)
        SetDBValue("enemyTargetScale", v)
        ApplySettings()
    end, true)
    row5b:SetPoint("TOPLEFT", row5, "BOTTOMLEFT", 0, -8)

    local row6 = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Offset X", -300, 300, 1, db.enemyFocusOffsetX, function(v)
        SetDBValue("enemyFocusOffsetX", v)
        ApplySettings()
    end, false)
    row6:SetPoint("TOPLEFT", row5b, "BOTTOMLEFT", 0, -8)

    local row7 = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Offset Y", -300, 300, 1, db.enemyFocusOffsetY, function(v)
        SetDBValue("enemyFocusOffsetY", v)
        ApplySettings()
    end, false)
    row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -8)

    local row7b = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Scale", 0.5, 1.5, 0.01, db.enemyFocusScale, function(v)
        SetDBValue("enemyFocusScale", v)
        ApplySettings()
    end, true)
    row7b:SetPoint("TOPLEFT", row7, "BOTTOMLEFT", 0, -8)

    SelectEnemySubTab(1)
end

local function ShowConfig()
    if configFrame then
        configFrame:SetShown(not configFrame:IsShown())
        return
    end
    FDR_RefreshDB()

    configFrame = CreateFrame("Frame", "NameplateDRsConfig", UIParent, "BackdropTemplate")
    configFrame:SetSize(620, 520)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -16)
    title:SetText("Fresh DRs")

    local byline = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    byline:SetPoint("LEFT", title, "RIGHT", 8, 0)
    byline:SetText("by lesh")

    local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)

    local donate1 = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    donate1:SetPoint("LEFT", byline, "RIGHT", 12, 0)
    donate1:SetText("Please donate for my ill friend <3")

    local donateBox = CreateFrame("EditBox", nil, configFrame, "InputBoxTemplate")
    donateBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    donateBox:SetSize(configFrame:GetWidth() - 32, 20)
    donateBox:SetAutoFocus(false)
    donateBox:SetText("https://www.gofundme.com/f/help-michael-survive-myalgic-encephalomyelitis")
    donateBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    donateBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local function CreateTabButton(parent, text, width)
        local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
        tab:SetSize(width, 24)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 1,
        })
        tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.label:SetPoint("CENTER")
        tab.label:SetText(text)
        return tab
    end

    local tabGeneral = CreateTabButton(configFrame, "General", 95)
    tabGeneral:SetPoint("TOPLEFT", donateBox, "BOTTOMLEFT", 0, -10)

    local tab1 = CreateTabButton(configFrame, "PvP Enemy DRs", 170)
    tab1:SetPoint("LEFT", tabGeneral, "RIGHT", 6, 0)

    local tab2 = CreateTabButton(configFrame, "PvP Friendly DRs", 170)
    tab2:SetPoint("LEFT", tab1, "RIGHT", 6, 0)

    local generalFrame = CreateFrame("Frame", nil, configFrame)
    generalFrame:SetPoint("TOPLEFT", tabGeneral, "BOTTOMLEFT", 0, -8)
    generalFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -16, 0)
    generalFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 16, 16)
    generalFrame:Hide()

    local enemyFrame = CreateFrame("Frame", nil, configFrame)
    enemyFrame:SetPoint("TOPLEFT", tabGeneral, "BOTTOMLEFT", 0, -8)
    enemyFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -16, 0)
    enemyFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 16, 16)
    enemyFrame:Hide()

    local friendlyFrame = CreateFrame("Frame", nil, configFrame)
    friendlyFrame:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    friendlyFrame:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    friendlyFrame:Hide()

    local function SelectTab(index)
        local function StyleTab(tab, active)
            if active then
                tab:SetBackdropColor(0.45, 0.85, 1.0, 0.5)
                tab:SetBackdropBorderColor(0.2, 1.0, 0.35, 0.5)
                if tab.label then
                    tab.label:SetTextColor(1, 1, 1, 1)
                end
            else
                tab:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
                tab:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
                if tab.label then
                    tab.label:SetTextColor(0.7, 0.7, 0.7, 1)
                end
            end
        end

        generalFrame:SetShown(index == 1)
        enemyFrame:SetShown(index == 2)
        friendlyFrame:SetShown(index == 3)
        StyleTab(tabGeneral, index == 1)
        StyleTab(tab1, index == 2)
        StyleTab(tab2, index == 3)
    end

    tabGeneral:SetScript("OnClick", function()
        SelectTab(1)
    end)
    tab1:SetScript("OnClick", function()
        SelectTab(2)
    end)
    tab2:SetScript("OnClick", function()
        SelectTab(3)
    end)

    local function CreateSeparator(parent, anchor, offsetY)
        local sep = parent:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(1, 1, 1, 0.08)
        sep:SetHeight(1)
        sep:SetPoint("LEFT", parent, "LEFT", 0, 0)
        sep:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        sep:SetPoint("TOP", anchor, "BOTTOM", 0, offsetY or -12)
        return sep
    end

    local enemySubTabBar = CreateFrame("Frame", nil, enemyFrame)
    enemySubTabBar:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    enemySubTabBar:SetSize(520, 24)

    local enemySubNameplateBtn = CreateTabButton(enemySubTabBar, "Nameplate DRs", 130)
    enemySubNameplateBtn:SetPoint("TOPLEFT", enemySubTabBar, "TOPLEFT", 0, 0)

    local enemySubTargetFocusBtn = CreateTabButton(enemySubTabBar, "Target/Focus DRs", 140)
    enemySubTargetFocusBtn:SetPoint("LEFT", enemySubNameplateBtn, "RIGHT", 4, 0)

    local enemyGeneralSub = CreateFrame("Frame", nil, generalFrame)
    enemyGeneralSub:SetPoint("TOPLEFT", generalFrame, "TOPLEFT", 0, 0)
    enemyGeneralSub:SetPoint("BOTTOMRIGHT", generalFrame, "BOTTOMRIGHT", 0, 0)

    local enemyNameplateSub = CreateFrame("Frame", nil, enemyFrame)
    enemyNameplateSub:SetPoint("TOPLEFT", enemySubTabBar, "BOTTOMLEFT", 0, -8)
    enemyNameplateSub:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    enemyNameplateSub:Hide()

    local enemyTargetFocusSub = CreateFrame("Frame", nil, enemyFrame)
    enemyTargetFocusSub:SetPoint("TOPLEFT", enemySubTabBar, "BOTTOMLEFT", 0, -8)
    enemyTargetFocusSub:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    enemyTargetFocusSub:Hide()

    local function StyleEnemySubTab(tab, active)
        if active then
            tab:SetBackdropColor(0.45, 0.85, 1.0, 0.5)
            tab:SetBackdropBorderColor(0.2, 1.0, 0.35, 0.5)
            if tab.label then
                tab.label:SetTextColor(1, 1, 1, 1)
            end
            return
        end
        tab:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        tab:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
        if tab.label then
            tab.label:SetTextColor(0.72, 0.72, 0.72, 1)
        end
    end

    local function SelectEnemySubTab(index)
        enemyNameplateSub:SetShown(index == 1)
        enemyTargetFocusSub:SetShown(index == 2)
        StyleEnemySubTab(enemySubNameplateBtn, index == 1)
        StyleEnemySubTab(enemySubTargetFocusBtn, index == 2)
    end

    enemySubNameplateBtn:SetScript("OnClick", function()
        SelectEnemySubTab(1)
    end)
    enemySubTargetFocusBtn:SetScript("OnClick", function()
        SelectEnemySubTab(2)
    end)

    local enemyGeneralTitle = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyGeneralTitle:SetPoint("TOPLEFT", enemyGeneralSub, "TOPLEFT", 0, 0)
    enemyGeneralTitle:SetText("General")

    local borderStyleOptions = {
        { value = "none", label = "None" },
        { value = "solid", label = "Solid" },
        { value = "soft", label = "Soft" },
        { value = "glow", label = "Glow" },
        { value = "halo", label = "Halo" },
        { value = "dashed", label = "Dashed" },
        { value = "wideglow", label = "Wide Glow" },
    }

    local borderStyleRow = FDR_CreateDropdownRow(enemyGeneralSub, "DR Icon Border Style", borderStyleOptions, db.iconBorderStyle or "solid", function(v)
        SetDBValue("iconBorderStyle", v)
        ApplySettings()
    end, 420, 180)
    borderStyleRow:SetPoint("TOPLEFT", enemyGeneralTitle, "BOTTOMLEFT", -2, -6)

    local borderThicknessRow = FDR_CreateSliderRow(enemyGeneralSub, "Border Thickness", 0.5, 3.0, 0.05, db.iconBorderThickness or 1.0, function(v)
        SetDBValue("iconBorderThickness", v)
        ApplySettings()
    end, true, 220, 120)
    borderThicknessRow:SetPoint("TOPLEFT", borderStyleRow, "TOPRIGHT", 14, 0)

    local zoomCheckbox = FDR_CreateCheckbox(enemyGeneralSub, "Zoom DR icons by 7% (hide default icon edge)", db.iconZoomEnabled == true, function(checked)
        SetDBValue("iconZoomEnabled", checked)
        ApplySettings()
    end)
    zoomCheckbox:SetPoint("TOPLEFT", borderStyleRow, "BOTTOMLEFT", 0, -12)
    if zoomCheckbox.Text then
        zoomCheckbox.Text:SetWidth(420)
        zoomCheckbox.Text:SetWordWrap(true)
    end

    local infoTextStyleOptions = {
        { value = "blizz", label = "Blizz" },
        { value = "modern_colored", label = "Modern Lean Coloured" },
        { value = "modern_white", label = "Modern Lean White" },
        { value = "retro", label = "Retro" },
        { value = "retro_text", label = "Retro Text" },
    }
    local infoTextStyleRow = FDR_CreateDropdownRow(enemyGeneralSub, "DR Icon Info Text Style", infoTextStyleOptions, db.iconInfoTextStyle or "blizz", function(v)
        SetDBValue("iconInfoTextStyle", v)
        ApplySettings()
    end, 420, 200)
    infoTextStyleRow:SetPoint("TOPLEFT", zoomCheckbox, "BOTTOMLEFT", -2, -10)

    local iconSpacingRow = FDR_CreateSliderRow(enemyGeneralSub, "DR Icon Spacing", 0, 12, 1, db.iconSpacing or 2, function(v)
        SetDBValue("iconSpacing", v)
        ApplySettings()
    end, false, 420, 280)
    iconSpacingRow:SetPoint("TOPLEFT", infoTextStyleRow, "BOTTOMLEFT", 0, -16)

    local categoryHeader = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryHeader:SetPoint("TOPLEFT", iconSpacingRow, "BOTTOMLEFT", 2, -16)
    categoryHeader:SetText("Per-Category DR Icon Override")

    local categoryHelp = enemyGeneralSub:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    categoryHelp:SetPoint("TOPLEFT", categoryHeader, "BOTTOMLEFT", 0, -2)
    categoryHelp:SetText("Pick fixed icons and toggle categories on/off (applies to all DR displays/test modes).")

    local colX = { 0, 250 }
    local colY = { -20, -70, -120 }
    for idx, category in ipairs(DR_CATEGORY_UI_ORDER) do
        local col = ((idx - 1) % 2) + 1
        local row = math.floor((idx - 1) / 2) + 1
        local overrideTable = db.drCategoryIconOverrides or {}
        local selected = overrideTable[category] or 0
        local options = FDR_GetCategoryIconDropdownOptions(category)
        local rowWidget = FDR_CreateDropdownRow(
            enemyGeneralSub,
            (DR_CATEGORY_UI_LABEL[category] or category) .. " Icon",
            options,
            selected,
            function(v)
                local map = {}
                local src = db.drCategoryIconOverrides
                if type(src) == "table" then
                    for k, value in pairs(src) do
                        map[k] = value
                    end
                end
                local parsed = FDR_SafeNumber(v, nil)
                if parsed and parsed > 0 then
                    map[category] = parsed
                else
                    map[category] = nil
                end
                SetDBValue("drCategoryIconOverrides", map)
                ApplySettings()
            end,
            240,
            190
        )
        rowWidget:SetPoint("TOPLEFT", categoryHelp, "BOTTOMLEFT", colX[col], colY[row])

        local visibilityMap = db.drCategoryVisibility or {}
        local isVisible = visibilityMap[category] ~= false
        local visibilityToggle = FDR_CreateCheckbox(enemyGeneralSub, "", isVisible, function(checked)
            local map = {}
            local src = db.drCategoryVisibility
            if type(src) == "table" then
                for k, value in pairs(src) do
                    map[k] = value
                end
            end
            if checked == false then
                map[category] = false
            else
                map[category] = nil
            end
            SetDBValue("drCategoryVisibility", map)
            ApplySettings()
        end)
        if visibilityToggle.Text then
            visibilityToggle.Text:SetText("")
            visibilityToggle.Text:Hide()
        end
        if rowWidget.title then
            visibilityToggle:SetPoint("LEFT", rowWidget.title, "RIGHT", 6, 0)
        else
            visibilityToggle:SetPoint("TOPLEFT", rowWidget, "TOPRIGHT", -18, 0)
        end
    end

    local enemyNameplateTitle = enemyNameplateSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyNameplateTitle:SetPoint("TOPLEFT", enemyNameplateSub, "TOPLEFT", 0, 0)
    enemyNameplateTitle:SetText("Nameplate DRs")

    local checkboxEnemyNameplate = FDR_CreateCheckbox(enemyNameplateSub, "Enable nameplate DRs", IsEnemyNameplateEnabled(), function(checked)
        SetDBValue("enemyShowNameplates", checked)
        ApplySettings()
    end)
    checkboxEnemyNameplate:SetPoint("TOPLEFT", enemyNameplateTitle, "BOTTOMLEFT", -2, -6)

    local checkboxEnemyHideArenaTrays = FDR_CreateCheckbox(enemyNameplateSub, "Hide Blizzard arena DR trays", db.enemyHideArenaTrays == true, function(checked)
        SetDBValue("enemyHideArenaTrays", checked)
        ApplySettings()
    end)
    checkboxEnemyHideArenaTrays:SetPoint("TOPLEFT", checkboxEnemyNameplate, "BOTTOMLEFT", 0, -4)

    local checkboxTest = FDR_CreateCheckbox(enemyNameplateSub, "Test mode (target something in open world)", db.testMode, function(checked)
        SetDBValue("testMode", checked)
        ApplySettings()
    end)
    checkboxTest:SetPoint("TOPLEFT", checkboxEnemyHideArenaTrays, "BOTTOMLEFT", 0, -4)
    if checkboxTest.Text then
        checkboxTest.Text:SetWidth(420)
        checkboxTest.Text:SetWordWrap(true)
    end

    local note = enemyNameplateSub:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", checkboxTest, "BOTTOMLEFT", 2, -6)
    note:SetWidth(420)
    note:SetJustifyH("LEFT")
    note:SetText("Offsets apply to the active nameplate system (Platynator or Plater if loaded).")

    local row1 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Offset X", -100, 100, 1, db.offsetX, function(v)
        SetDBValue("offsetX", v)
        ApplySettings()
    end, false)
    row1:SetPoint("TOPLEFT", note, "BOTTOMLEFT", -2, -6)

    local row2 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Offset Y", -100, 100, 1, db.offsetY, function(v)
        SetDBValue("offsetY", v)
        ApplySettings()
    end, false)
    row2:SetPoint("TOPLEFT", row1, "BOTTOMLEFT", 0, -8)

    local row3 = FDR_CreateSliderRow(enemyNameplateSub, "Nameplate DR Scale", 0.5, 1.5, 0.01, db.trayScale, function(v)
        SetDBValue("trayScale", v)
        ApplySettings()
    end, true)
    row3:SetPoint("TOPLEFT", row2, "BOTTOMLEFT", 0, -6)

    local enemyTargetFocusTitle = enemyTargetFocusSub:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enemyTargetFocusTitle:SetPoint("TOPLEFT", enemyTargetFocusSub, "TOPLEFT", 0, 0)
    enemyTargetFocusTitle:SetText("Target/Focus DRs")

    local checkboxEnemyTargetFocus = FDR_CreateCheckbox(enemyTargetFocusSub, "Enable target/focus DRs", IsEnemyTargetFocusEnabled(), function(checked)
        SetDBValue("enemyShowTargetFocus", checked)
        ApplySettings()
    end)
    checkboxEnemyTargetFocus:SetPoint("TOPLEFT", enemyTargetFocusTitle, "BOTTOMLEFT", -2, -6)

    local checkboxTargetFocusTest = FDR_CreateCheckbox(enemyTargetFocusSub, "Test mode (target/focus)", db.enemyTargetFocusTestMode, function(checked)
        SetDBValue("enemyTargetFocusTestMode", checked)
        ApplySettings()
    end)
    checkboxTargetFocusTest:SetPoint("TOPLEFT", checkboxEnemyTargetFocus, "BOTTOMLEFT", 0, -4)
    if checkboxTargetFocusTest.Text then
        checkboxTargetFocusTest.Text:SetWidth(420)
        checkboxTargetFocusTest.Text:SetWordWrap(true)
    end

    local row4 = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Offset X", -300, 300, 1, db.enemyTargetOffsetX, function(v)
        SetDBValue("enemyTargetOffsetX", v)
        ApplySettings()
    end, false)
    row4:SetPoint("TOPLEFT", checkboxTargetFocusTest, "BOTTOMLEFT", 0, -8)

    local row5 = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Offset Y", -300, 300, 1, db.enemyTargetOffsetY, function(v)
        SetDBValue("enemyTargetOffsetY", v)
        ApplySettings()
    end, false)
    row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)

    local row5b = FDR_CreateSliderRow(enemyTargetFocusSub, "Target Frame DR Scale", 0.5, 1.5, 0.01, db.enemyTargetScale, function(v)
        SetDBValue("enemyTargetScale", v)
        ApplySettings()
    end, true)
    row5b:SetPoint("TOPLEFT", row5, "BOTTOMLEFT", 0, -8)

    local row6 = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Offset X", -300, 300, 1, db.enemyFocusOffsetX, function(v)
        SetDBValue("enemyFocusOffsetX", v)
        ApplySettings()
    end, false)
    row6:SetPoint("TOPLEFT", row5b, "BOTTOMLEFT", 0, -8)

    local row7 = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Offset Y", -300, 300, 1, db.enemyFocusOffsetY, function(v)
        SetDBValue("enemyFocusOffsetY", v)
        ApplySettings()
    end, false)
    row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -8)

    local row7b = FDR_CreateSliderRow(enemyTargetFocusSub, "Focus Frame DR Scale", 0.5, 1.5, 0.01, db.enemyFocusScale, function(v)
        SetDBValue("enemyFocusScale", v)
        ApplySettings()
    end, true)
    row7b:SetPoint("TOPLEFT", row7, "BOTTOMLEFT", 0, -8)

    SelectEnemySubTab(1)

    local friendlyNote = friendlyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    friendlyNote:SetPoint("TOPLEFT", friendlyFrame, "TOPLEFT", 0, -2)
    friendlyNote:SetWidth(540)
    friendlyNote:SetHeight(16)
    friendlyNote:SetJustifyH("LEFT")
    friendlyNote:SetTextColor(0.85, 0.85, 0.85)
    friendlyNote:SetText("PvP-friendly DR tracking for player / party / raid frames.")

    local columnWidth = 260
    local sliderWidth = 160

    local friendlyLeft = CreateFrame("Frame", nil, friendlyFrame)
    friendlyLeft:SetPoint("TOPLEFT", friendlyNote, "BOTTOMLEFT", 0, -10)
    friendlyLeft:SetSize(columnWidth, 400)

    local friendlyRight = CreateFrame("Frame", nil, friendlyFrame)
    friendlyRight:SetPoint("TOPRIGHT", friendlyLeft, "TOPRIGHT", (columnWidth + 20), 0)
    friendlyRight:SetSize(columnWidth, 400)

    local sepV = friendlyFrame:CreateTexture(nil, "ARTWORK")
    sepV:SetColorTexture(1, 1, 1, 0.08)
    sepV:SetWidth(1)
    sepV:SetPoint("TOP", friendlyLeft, "TOPRIGHT", 10, 0)
    sepV:SetPoint("BOTTOM", friendlyLeft, "BOTTOMRIGHT", 10, 0)

    local midTitle = friendlyLeft:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    midTitle:SetPoint("TOPLEFT", friendlyLeft, "TOPLEFT", 0, 0)
    midTitle:SetText("Raid/Party DRs")

    local checkboxFriendly = FDR_CreateCheckbox(friendlyLeft, "Show DRs on raid frames", db.friendlyTracking, function(checked)
        SetDBValue("friendlyTracking", checked)
        ApplySettings()
    end)
    checkboxFriendly:SetPoint("TOPLEFT", midTitle, "BOTTOMLEFT", -2, -6)
    if checkboxFriendly.Text then
        checkboxFriendly.Text:SetWidth(columnWidth - 10)
        checkboxFriendly.Text:SetWordWrap(true)
    end

    local checkboxHidePlayer = FDR_CreateCheckbox(friendlyLeft, "Hide player DRs in party/raid frame", db.friendlyHidePlayerInGroup, function(checked)
        SetDBValue("friendlyHidePlayerInGroup", checked)
        ApplySettings()
    end)
    checkboxHidePlayer:SetPoint("TOPLEFT", checkboxFriendly, "BOTTOMLEFT", 14, -4)
    if checkboxHidePlayer.Text then
        checkboxHidePlayer.Text:SetWidth(columnWidth - 24)
        checkboxHidePlayer.Text:SetWordWrap(true)
    end

    local checkboxFriendlyTest = FDR_CreateCheckbox(friendlyLeft, "Test mode", db.friendlyTestMode, function(checked)
        SetDBValue("friendlyTestMode", checked)
        ApplySettings()
    end)
    checkboxFriendlyTest:SetPoint("TOPLEFT", checkboxHidePlayer, "BOTTOMLEFT", -14, -6)

    local directionOptions = {
        { value = "left", label = "Left" },
        { value = "right", label = "Right" },
        { value = "up", label = "Up" },
        { value = "down", label = "Down" },
    }
    local directionRow = FDR_CreateDropdownRow(friendlyLeft, "DR Icon Direction", directionOptions, db.friendlyDirection, function(v)
        SetDBValue("friendlyDirection", v)
        ApplySettings()
    end, columnWidth, 150)
    directionRow:SetPoint("TOPLEFT", checkboxFriendlyTest, "BOTTOMLEFT", -2, -10)

    local row4 = FDR_CreateSliderRow(friendlyLeft, "Friendly DR Offset X", -50, 50, 1, db.friendlyOffsetX, function(v)
        SetDBValue("friendlyOffsetX", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row4:SetPoint("TOPLEFT", directionRow, "BOTTOMLEFT", 0, -21)

    local row5 = FDR_CreateSliderRow(friendlyLeft, "Friendly DR Offset Y", -50, 50, 1, db.friendlyOffsetY, function(v)
        SetDBValue("friendlyOffsetY", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)

    local rightTitle = friendlyRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightTitle:SetPoint("TOPLEFT", friendlyRight, "TOPLEFT", 0, 0)
    rightTitle:SetText("Player DRs")

    local checkboxPlayerSeparate = FDR_CreateCheckbox(friendlyRight, "Show player DRs", db.friendlyPlayerSeparate, function(checked)
        SetDBValue("friendlyPlayerSeparate", checked)
        if checked then
            SetDBValue("friendlyHidePlayerInGroup", true)
            if checkboxHidePlayer then
                checkboxHidePlayer:SetChecked(true)
            end
        end
        ApplySettings()
    end)
    checkboxPlayerSeparate:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", -2, -6)
    if checkboxPlayerSeparate.Text then
        checkboxPlayerSeparate.Text:SetWidth(columnWidth - 10)
        checkboxPlayerSeparate.Text:SetWordWrap(true)
    end

    local checkboxPlayerTest = FDR_CreateCheckbox(friendlyRight, "Test mode", db.playerTestMode, function(checked)
        SetDBValue("playerTestMode", checked)
        ApplySettings()
    end)
    checkboxPlayerTest:SetPoint("TOPLEFT", checkboxPlayerSeparate, "BOTTOMLEFT", 0, -4)

    local anchorOptions = {
        { value = "player", label = "Player frame" },
        { value = "center", label = "Screen center" },
    }
    local playerAnchorRow = FDR_CreateDropdownRow(friendlyRight, "Player DR Anchor", anchorOptions, db.friendlyPlayerAnchor, function(v)
        SetDBValue("friendlyPlayerAnchor", v)
        ApplySettings()
    end, columnWidth, 150)
    playerAnchorRow:SetPoint("TOPLEFT", checkboxPlayerTest, "BOTTOMLEFT", -2, -18)

    local playerDirectionOptions = {
        { value = "left", label = "Left" },
        { value = "right", label = "Right" },
        { value = "up", label = "Up" },
        { value = "down", label = "Down" },
    }
    local playerDirectionRow = FDR_CreateDropdownRow(friendlyRight, "Player DR Direction", playerDirectionOptions, db.playerDirection or "left", function(v)
        SetDBValue("playerDirection", v)
        ApplySettings()
    end, columnWidth, 150)
    playerDirectionRow:SetPoint("TOPLEFT", playerAnchorRow, "BOTTOMLEFT", 0, -19)

    local row6 = FDR_CreateSliderRow(friendlyRight, "Player DR Offset X", -2000, 2000, 1, db.friendlyPlayerOffsetX, function(v)
        SetDBValue("friendlyPlayerOffsetX", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row6:SetPoint("TOPLEFT", playerDirectionRow, "BOTTOMLEFT", 0, -21)

    local row7 = FDR_CreateSliderRow(friendlyRight, "Player DR Offset Y", -2000, 2000, 1, db.friendlyPlayerOffsetY, function(v)
        SetDBValue("friendlyPlayerOffsetY", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -21)

    SelectTab(2)
end

local function EnsureNameplateEventBridge()
    if nameplateEventFrame then
        return
    end

    nameplateEventFrame = CreateFrame("Frame")
    nameplateEventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    nameplateEventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    nameplateEventFrame:RegisterEvent("UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED")
    nameplateEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    nameplateEventFrame:SetScript("OnEvent", function(_, event, ...)
        local unitToken, trackerInfo = ...
        if event == "NAME_PLATE_UNIT_ADDED" then
            if arenaLog.inArena and IsArenaLoggingEnabled() then
                ArenaLogf("event %s token=%s", event, SafeToText(unitToken))
            end
            local normalizedToken = FDR_NormalizeNameplateToken(unitToken)
            local plate = FDR_GetNamePlateForUnitRaw(unitToken)
            if FDR_SafeIsObject(plate) then
                FDR_CacheNameplateByToken(unitToken, plate)
            else
                -- Fallback for API paths where GetNamePlateForUnit(nameplateX) returns nil.
                if normalizedToken then
                    local plates = FDR_GetAllNamePlates()
                    if type(plates) == "table" then
                        for _, candidate in ipairs(plates) do
                            local candidateToken = FDR_NormalizeNameplateToken((ResolveTokenForPlate and ResolveTokenForPlate(candidate)) or GetNameplateToken(candidate) or FDR_GetFrameNameplateToken(candidate))
                            if candidateToken and FDR_SafeStringEquals(candidateToken, normalizedToken) then
                                nameplateByToken[normalizedToken] = candidate
                                break
                            end
                        end
                    end
                else
                    RebuildNameplateTokenCache()
                end
            end

            -- Cache a direct arena<n> -> nameplate<n> link at add-time.
            if normalizedToken then
                for i = 1, 3 do
                    local arenaUnit = "arena" .. i
                    if FDR_SafeUnitIsUnit(normalizedToken, arenaUnit) or FDR_SafeUnitIsUnit(arenaUnit, normalizedToken) then
                        LinkArenaIndexToNameplateToken(i, normalizedToken)
                        break
                    end
                end
            end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            if arenaLog.inArena and IsArenaLoggingEnabled() then
                ArenaLogf("event %s token=%s", event, SafeToText(unitToken))
            end
            ClearNameplateByToken(unitToken)
        elseif event == "UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED" then
            FDR_RecordSpellDiminishCategoryState(unitToken, trackerInfo)
        elseif event == "PLAYER_ENTERING_WORLD" then
            ClearArenaNameplateLinks()
            RebuildNameplateTokenCache()
            FDR_ClearSpellDiminishStores()
        end
    end)

    RebuildNameplateTokenCache()
end

local function Start()
    if not db then
        InitDB()
    end
    FDR_RefreshDB()
    EnsureNameplateEventBridge()
    if not saveFrame then
        saveFrame = CreateFrame("Frame")
        saveFrame:RegisterEvent("PLAYER_LOGOUT")
        saveFrame:SetScript("OnEvent", function()
            SaveDB()
        end)
    end

    if not ticker then
        ticker = C_Timer.NewTicker(0.2, function()
            UpdateArenaLogSessionState()
            FDR_NormalizePersistedDB()
            if db and not IsInArena() then
                local ranTest = false
                if IsEnemyNameplateEnabled() and db.testMode then
                    UpdateTestTray()
                    ranTest = true
                else
                    HideTestTrayFor("nameplate")
                end
                if IsEnemyTargetFocusEnabled() and db.enemyTargetFocusTestMode then
                    UpdateTargetFocusTestTrays()
                    ranTest = true
                else
                    HideTestTrayFor("target")
                    HideTestTrayFor("focus")
                end
                if ranTest then
                    SetArenaTrayHidden(false)
                    HideEnemyNameplateFrames()
                    HideEnemyOpenWorldNameplateFrames()
                    HideEnemyTargetFocusFrames()
                    ClearArenaNameplateLinks()
                    return
                end
            end
            MoveArenaTrays()
        end)
    end

    C_Timer.After(0, function()
        UpdateArenaLogSessionState()
        FDR_NormalizePersistedDB()
        if db and not IsInArena() then
            local ranTest = false
            if IsEnemyNameplateEnabled() and db.testMode then
                UpdateTestTray()
                ranTest = true
            else
                HideTestTrayFor("nameplate")
            end
            if IsEnemyTargetFocusEnabled() and db.enemyTargetFocusTestMode then
                UpdateTargetFocusTestTrays()
                ranTest = true
            else
                HideTestTrayFor("target")
                HideTestTrayFor("focus")
            end
            if ranTest then
                SetArenaTrayHidden(false)
                HideEnemyNameplateFrames()
                HideEnemyOpenWorldNameplateFrames()
                HideEnemyTargetFocusFrames()
                ClearArenaNameplateLinks()
                return
            end
        end
        MoveArenaTrays()
    end)
end

local function DumpNameplateSnapshot()
    local secure = (type(issecure) == "function") and issecure() or nil
    local plates = FDR_GetAllNamePlates()
    local count = (type(plates) == "table") and #plates or 0

    print("Fresh DRs DUMP: ===== START =====")
    print("Fresh DRs DUMP: secure=", SafeToText(secure), "count=", SafeToText(count))

    for i = 1, 3 do
        local unit = "arena" .. i
        local tokType = "err"
        local tokValue = "err"
        local okTok, tok = pcall(function()
            if UnitGUID and UnitTokenFromGUID then
                return UnitTokenFromGUID(UnitGUID(unit))
            end
            return nil
        end)
        if okTok then
            tokType = type(tok)
            tokValue = SafeToText(tok)
        end
        print("Fresh DRs DUMP:", unit, "tokType=", tokType, "tok=", tokValue)
    end

    if type(plates) == "table" then
        for idx, plate in ipairs(plates) do
            local token = (ResolveTokenForPlate and ResolveTokenForPlate(plate)) or FDR_NormalizeNameplateToken(GetNameplateToken(plate) or FDR_GetFrameNameplateToken(plate))
            local okName, frameName = pcall(function()
                return plate:GetName()
            end)
            local frameString = SafeToText(plate)
            print(
                "Fresh DRs DUMP: plate",
                SafeToText(idx),
                "name=",
                okName and SafeToText(frameName) or "nil",
                "token=",
                SafeToText(token),
                "str=",
                SafeToText(frameString)
            )
        end
    end

    print("Fresh DRs DUMP: ===== END =====")
end

InitDB()
Start()

SLASH_NAMEPLATEDRS1 = "/ndr"
SLASH_NAMEPLATEDRS2 = "/fdr"
SlashCmdList.NAMEPLATEDRS = function(msg)
    local cmd = msg and string.lower((msg:gsub("^%s+", ""):gsub("%s+$", ""))) or ""
    if cmd == "debug" then
        local newValue = not (db and db.debug)
        SetDBValue("debug", newValue)
        print("Fresh DRs: debug =", newValue and "ON" or "OFF")
        return
    elseif cmd == "debug on" then
        SetDBValue("debug", true)
        print("Fresh DRs: debug = ON")
        return
    elseif cmd == "debug off" then
        SetDBValue("debug", false)
        print("Fresh DRs: debug = OFF")
        return
    elseif cmd == "dump" then
        DumpNameplateSnapshot()
        return
    elseif cmd == "log" then
        ShowArenaLogWindow(BuildArenaLogText())
        return
    elseif cmd == "log clear" then
        arenaLog.sessions = {}
        arenaLog.current = nil
        arenaLog.anchorState = {}
        print("Fresh DRs: arena log cleared.")
        return
    elseif cmd == "log on" then
        SetDBValue("logEnabled", true)
        print("Fresh DRs: arena log = ON")
        return
    elseif cmd == "log off" then
        SetDBValue("logEnabled", false)
        print("Fresh DRs: arena log = OFF")
        return
    end
    ShowConfig()
end
