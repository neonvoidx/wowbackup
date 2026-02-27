local ADDON_NAME = ...
local FCT2 = CreateFrame("Frame")
_G.FrogskisCursorTrail2 = FCT2

-- ========
-- Defaults 
-- ========
local DEFAULTS = {
    combatoption = false,
    changeWithTime = true,
    useClassColor = false,
    shrinkWithTime = true,
    shrinkWithDistance = true,

    dotdistance = 3,
    lifetime = 0.35,
    maxdots = 300,
    widthx = 50,
    heightx = 50,
    Alphax = 1.0,
    colourspeed = 0.5,
    phasecount = 6,

    cursorlayer = 1,
    blendmode = 1,
    textureInput = "bags-glow-flash",
    fallbackTexture = "bags-glow-flash",

    colour1 = {1.0, 0, 0},
    colour2 = {0.76, 0.35, 0},
    colour3 = {0.08, 0.73, 0},
    colour4 = {0, 0.54, 1},
    colour5 = {0, 0, 1},
    colour6 = {0.58, 0, 1},
    colour7 = {0, 0, 0},
    colour8 = {0, 0, 0},
    colour9 = {0, 0, 0},
    colour10 = {0, 0, 0},

    offsetX = 20,
    offsetY = -18,

    updateEveryOther = true,
    adaptiveTargetFPS = 90,
    enableLook = false,
    enableCombatLook = false,
    enableIndicator = true,
    cursorFrameSize = 40

}

_G.FrogskiCursorTrailDefaults = DEFAULTS

-- ==============
-- Small helpers
-- ==============
local function Clamp(n, lo, hi)
    if n < lo then
        return lo
    end
    if n > hi then
        return hi
    end
    return n
end

local function DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    local t = {}
    for k, v in pairs(src) do
        t[k] = DeepCopy(v)
    end
    return t
end

local function CopyDefaults(dst, src)
    if type(dst) ~= "table" then
        dst = {}
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function Trim(s)
    s = tostring(s or "")
    return (s:match("^%s*(.-)%s*$") or "")
end

local function GetCurrentCharKey()
    local name, realm = UnitFullName("player")
    if not name then
        name = UnitName("player")
    end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name or "Unknown"
end

-- =============================
-- SavedVariables + Profile DB
-- =============================
local cfg
local rootDB
local accountDB
local activeName
local glowBoost = 1
local trailDormant = false
local dormantX, dormantY

local function GetEffectiveCfg()
    return cfg
end

local function SanitizeProfile(p)
    if type(p) ~= "table" then
        return
    end
    if type(p.shrinkWithTime) ~= "boolean" then
        p.shrinkWithTime = true
    end
    if type(p.shrinkWithDistance) ~= "boolean" then
        p.shrinkWithDistance = true
    end
    if p.cursorlayer == "TOOLTIP" then
        p.cursorlayer = 1
    end
    if p.cursorlayer == "BACKGROUND" then
        p.cursorlayer = 2
    end
    if type(p.cursorlayer) ~= "number" or (p.cursorlayer ~= 1 and p.cursorlayer ~= 2) then
        p.cursorlayer = 1
    end

    if p.blendmode == "ADD" then
        p.blendmode = 1
    end
    if p.blendmode == "DISABLE" then
        p.blendmode = 2
    end
    if type(p.blendmode) ~= "number" or (p.blendmode ~= 1 and p.blendmode ~= 2) then
        p.blendmode = 1
    end
    if type(p.updateEveryOther) ~= "boolean" then
        p.updateEveryOther = false
    end
    if type(p.phasecount) ~= "number" then
        p.phasecount = 10
    end
    p.phasecount = math.max(1, math.min(10, math.floor(p.phasecount)))

    if type(p.dotdistance) ~= "number" then
        p.dotdistance = 2
    end
    if type(p.lifetime) ~= "number" then
        p.lifetime = 0.35
    end
    if type(p.maxdots) ~= "number" then
        p.maxdots = DEFAULTS.maxdots
    end
    p.maxdots = math.floor(Clamp(p.maxdots, 1, 800))
    if type(p.adaptiveTargetFPS) ~= "number" then
        p.adaptiveTargetFPS = 90
    end
    p.adaptiveTargetFPS = math.floor(Clamp(p.adaptiveTargetFPS, 1, 240))
    if type(p.widthx) ~= "number" then
        p.widthx = 45
    end
    if type(p.heightx) ~= "number" then
        p.heightx = 45
    end
    if type(p.Alphax) ~= "number" then
        p.Alphax = 1.0
    end
    if type(p.colourspeed) ~= "number" then
        p.colourspeed = 2.5
    end

    if type(p.offsetX) ~= "number" then
        p.offsetX = 13
    end
    if type(p.offsetY) ~= "number" then
        p.offsetY = -12
    end

    if type(p.cursorFrameSize) ~= "number" then
        p.cursorFrameSize = 40
    end
end

local function EnsureProfileExists(name)
    rootDB.profiles = rootDB.profiles or {}
    if type(rootDB.profiles[name]) ~= "table" then
        rootDB.profiles[name] = DeepCopy(_G.FrogskiCursorTrailDefaults or DEFAULTS)
    else
        CopyDefaults(rootDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        SanitizeProfile(rootDB.profiles[name])
    end
end

local function NormalizeRoot()

    FrogskisCursorTrailAccountDB = FrogskisCursorTrailAccountDB or {}
    accountDB = FrogskisCursorTrailAccountDB
    accountDB.profiles = accountDB.profiles or {}
    accountDB.accountWideProfiles = accountDB.accountWideProfiles or {}
    accountDB.accountWideOwners = accountDB.accountWideOwners or {}

    FrogskisCursorTrailDB = FrogskisCursorTrailDB or {}
    rootDB = FrogskisCursorTrailDB
    rootDB.conditions = rootDB.conditions or {}

    if type(rootDB.profiles) ~= "table" then
        local legacy = rootDB
        local newRoot = {
            currentProfile = "Default",
            profiles = {}
        }
        newRoot.profiles["Default"] = DeepCopy(_G.FrogskiCursorTrailDefaults or DEFAULTS)

        for k, _ in pairs(_G.FrogskiCursorTrailDefaults or DEFAULTS) do
            if legacy[k] ~= nil then
                newRoot.profiles["Default"][k] = DeepCopy(legacy[k])
            end
        end

        wipe(legacy)
        for k, v in pairs(newRoot) do
            legacy[k] = v
        end

        rootDB = legacy
    end

    if type(rootDB.currentProfile) ~= "string" or rootDB.currentProfile == "" then
        rootDB.currentProfile = "Default"
    end

    EnsureProfileExists("Default")
    EnsureProfileExists(rootDB.currentProfile)

    activeName = rootDB.currentProfile

    if accountDB.accountWideProfiles[activeName] then
        if type(accountDB.profiles[activeName]) ~= "table" then
            accountDB.profiles[activeName] = DeepCopy(_G.FrogskiCursorTrailDefaults or DEFAULTS)
        else
            CopyDefaults(accountDB.profiles[activeName], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        end
        SanitizeProfile(accountDB.profiles[activeName])
        cfg = accountDB.profiles[activeName]
    else
        cfg = rootDB.profiles[activeName]
        SanitizeProfile(cfg)
    end
end

local function SetActiveProfile(name)
    if type(name) ~= "string" or name == "" then
        return
    end
    if not rootDB or not accountDB then
        NormalizeRoot()
    end

    rootDB.currentProfile = name
    activeName = name

    if accountDB.accountWideProfiles and accountDB.accountWideProfiles[name] then
        if type(accountDB.profiles[name]) ~= "table" then
            accountDB.profiles[name] = DeepCopy(_G.FrogskiCursorTrailDefaults or DEFAULTS)
        else
            CopyDefaults(accountDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        end
        SanitizeProfile(accountDB.profiles[name])
        cfg = accountDB.profiles[name]
    else
        EnsureProfileExists(name)
        SanitizeProfile(rootDB.profiles[name])
        cfg = rootDB.profiles[name]
    end
end

FCT2.db = FCT2.db or {}

function FCT2.db:GetCurrentProfile()
    return activeName or (rootDB and rootDB.currentProfile) or "Default"
end

function FCT2.db:GetProfiles()
    return (rootDB and rootDB.profiles) or {}
end

function FCT2.db:ListProfilesSorted()
    local names, seen = {}, {}
    local charProfiles = (rootDB and rootDB.profiles) or {}
    for name in pairs(charProfiles) do
        if not seen[name] then
            names[#names + 1] = name
            seen[name] = true
        end
    end
    local acctProfiles = (accountDB and accountDB.profiles) or {}
    for name in pairs(acctProfiles) do
        if not seen[name] then
            names[#names + 1] = name
            seen[name] = true
        end
    end
    table.sort(names, function(a, b)
        if a == "Default" then
            return true
        end
        if b == "Default" then
            return false
        end
        return a:lower() < b:lower()
    end)
    return names
end

function FCT2.db:GetProfileTable()
    return cfg
end

function FCT2.db:SetProfile(name)
    SetActiveProfile(name)
end

function FCT2.db:IsProfileAccountWide(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    return (accountDB and accountDB.accountWideProfiles and accountDB.accountWideProfiles[name]) or false
end

function FCT2.db:GetProfileOwner(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if not (accountDB and accountDB.accountWideOwners) then
        return nil
    end
    return accountDB.accountWideOwners[name]
end

function FCT2.db:SetProfileAccountWide(name, makeWide)
    if type(name) ~= "string" or name == "" then
        return false
    end
    if not accountDB then
        return false
    end

    accountDB.profiles = accountDB.profiles or {}
    accountDB.accountWideProfiles = accountDB.accountWideProfiles or {}
    accountDB.accountWideOwners = accountDB.accountWideOwners or {}

    local wide = (makeWide == true)
    if wide then
        accountDB.profiles[name] = DeepCopy(cfg or (_G.FrogskiCursorTrailDefaults or DEFAULTS))
        CopyDefaults(accountDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        SanitizeProfile(accountDB.profiles[name])
        accountDB.accountWideProfiles[name] = true
        accountDB.accountWideOwners[name] = accountDB.accountWideOwners[name] or GetCurrentCharKey()
    else
        EnsureProfileExists(name)
        rootDB.profiles[name] = DeepCopy(cfg or (_G.FrogskiCursorTrailDefaults or DEFAULTS))
        CopyDefaults(rootDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        SanitizeProfile(rootDB.profiles[name])
        accountDB.accountWideProfiles[name] = nil
        accountDB.profiles[name] = nil
        accountDB.accountWideOwners[name] = nil
    end

    SetActiveProfile(name)
    return true
end

local function GetProfileByName(name)
    if accountDB and accountDB.accountWideProfiles and accountDB.accountWideProfiles[name] then
        return (accountDB.profiles and accountDB.profiles[name]), true
    end
    return (rootDB and rootDB.profiles and rootDB.profiles[name]), false
end

local function OverwriteProfile(name, tbl, makeAccountWide)
    if makeAccountWide then
        accountDB.profiles = accountDB.profiles or {}
        accountDB.accountWideProfiles = accountDB.accountWideProfiles or {}
        accountDB.accountWideOwners = accountDB.accountWideOwners or {}

        accountDB.accountWideProfiles[name] = true
        accountDB.accountWideOwners[name] = accountDB.accountWideOwners[name] or GetCurrentCharKey()

        accountDB.profiles[name] = DeepCopy(tbl)
        CopyDefaults(accountDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        SanitizeProfile(accountDB.profiles[name])
    else
        EnsureProfileExists(name)
        rootDB.profiles[name] = DeepCopy(tbl)
        CopyDefaults(rootDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        SanitizeProfile(rootDB.profiles[name])

        if accountDB and accountDB.accountWideProfiles then
            accountDB.accountWideProfiles[name] = nil
        end
        if accountDB and accountDB.profiles then
            accountDB.profiles[name] = nil
        end
        if accountDB and accountDB.accountWideOwners then
            accountDB.accountWideOwners[name] = nil
        end
    end
end

function FCT2.db:CreateProfile(name, copyFromCurrent)
    if type(name) ~= "string" then
        return false
    end
    name = Trim(name)
    if name == "" then
        return false
    end

    rootDB.profiles = rootDB.profiles or {}

    if type(rootDB.profiles[name]) ~= "table" then
        if copyFromCurrent and type(cfg) == "table" then
            rootDB.profiles[name] = DeepCopy(cfg)
            CopyDefaults(rootDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
        else
            rootDB.profiles[name] = DeepCopy(_G.FrogskiCursorTrailDefaults or DEFAULTS)
        end
    else
        CopyDefaults(rootDB.profiles[name], _G.FrogskiCursorTrailDefaults or DEFAULTS)
    end
    SanitizeProfile(rootDB.profiles[name])
    return true
end

function FCT2.db:DeleteProfile(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    if name == "Default" then
        return false
    end
    if not rootDB or not rootDB.profiles or not rootDB.profiles[name] then
        return false
    end

    rootDB.profiles[name] = nil

    if activeName == name then
        SetActiveProfile("Default")
    end
    return true
end

function FCT2:ResetDefaultProfileToFactory()
    FrogskisCursorTrailDB = FrogskisCursorTrailDB or {}
    local sv = FrogskisCursorTrailDB
    sv.profiles = sv.profiles or {}
    sv.currentProfile = sv.currentProfile or "Default"
    local defaults = _G.FrogskiCursorTrailDefaults or DEFAULTS
    sv.profiles["Default"] = DeepCopy(defaults)

    if self.db and self.db.GetCurrentProfile and self.db.SetProfile then
        if self.db:GetCurrentProfile() == "Default" then
            self.db:SetProfile("Default")
        end
    else
        if sv.currentProfile == "Default" and sv.profiles["Default"] then
            cfg = sv.profiles["Default"]
        end
    end

    self:Refresh()
    if self.RefreshOptionsUI then
        self:RefreshOptionsUI()
    end
end

-- ================
-- Export / Import 
-- ================
local EXPORT_DELIMITER = "@"
local _bxor = (bit and bit.bxor) or (bit32 and bit32.bxor)
if not _bxor then
    _bxor = function(a, b)
        local res, p = 0, 1
        while a > 0 or b > 0 do
            local aa, bb = a % 2, b % 2
            if aa ~= bb then
                res = res + p
            end
            a = (a - aa) / 2
            b = (b - bb) / 2
            p = p * 2
        end
        return res
    end
end

local B64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local B64_REVERSE = {}
for i = 1, #B64_ALPHABET do
    B64_REVERSE[B64_ALPHABET:sub(i, i)] = i
end

local function Base64Encode(data)
    local out = {}
    local len = #data
    local i = 1
    while i <= len do
        local a = data:byte(i) or 0;
        i = i + 1
        local b = data:byte(i) or 0;
        i = i + 1
        local c = data:byte(i) or 0;
        i = i + 1
        local n = a * 65536 + b * 256 + c
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64_ALPHABET:sub(c1 + 1, c1 + 1)
        out[#out + 1] = B64_ALPHABET:sub(c2 + 1, c2 + 1)
        if (i - 2) <= len then
            out[#out + 1] = B64_ALPHABET:sub(c3 + 1, c3 + 1)
        end
        if (i - 1) <= len then
            out[#out + 1] = B64_ALPHABET:sub(c4 + 1, c4 + 1)
        end
    end
    return table.concat(out)
end

local function Base64Decode(str)
    local out = {}
    local len = #str
    local i = 1
    while i <= len do
        local c1 = B64_REVERSE[str:sub(i, i)];
        i = i + 1
        local c2 = B64_REVERSE[str:sub(i, i)];
        i = i + 1
        local c3 = B64_REVERSE[str:sub(i, i)];
        i = i + 1
        local c4 = B64_REVERSE[str:sub(i, i)];
        i = i + 1
        if not c1 or not c2 then
            break
        end
        c1 = c1 - 1;
        c2 = c2 - 1
        c3 = (c3 and (c3 - 1)) or 0
        c4 = (c4 and (c4 - 1)) or 0
        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        local a = math.floor(n / 65536) % 256
        local b = math.floor(n / 256) % 256
        local c = n % 256
        out[#out + 1] = string.char(a)
        if (i - 2) <= len and B64_REVERSE[str:sub(i - 2, i - 2)] then
            out[#out + 1] = string.char(b)
        end
        if (i - 1) <= len and B64_REVERSE[str:sub(i - 1, i - 1)] then
            out[#out + 1] = string.char(c)
        end
    end
    return table.concat(out)
end

local OBFUSCATION_KEY = "FCTP_OBFUSCATE_V2"
local function XorCrypt(data)
    local out = {}
    local klen = #OBFUSCATION_KEY
    for i = 1, #data do
        local kb = OBFUSCATION_KEY:byte(((i - 1) % klen) + 1)
        out[i] = string.char(_bxor(data:byte(i), kb))
    end
    return table.concat(out)
end

local function EscapeValue(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub(";", "\\;")
    s = s:gsub("=", "\\=")
    s = s:gsub(EXPORT_DELIMITER, "\\" .. EXPORT_DELIMITER)
    s = s:gsub("|", "\\|")
    s = s:gsub("\n", " ")
    s = s:gsub("\r", "")
    return s
end

local function UnescapeValue(s)
    s = tostring(s or "")
    s = s:gsub("\\|", "|")
    s = s:gsub("\\" .. EXPORT_DELIMITER, EXPORT_DELIMITER)
    s = s:gsub("\\=", "=")
    s = s:gsub("\\;", ";")
    s = s:gsub("\\\\", "\\")
    return s
end

local function MakeUniqueProfileName(desired)
    desired = Trim(desired)
    if desired == "" then
        return nil
    end
    local base = desired
    local function Exists(name)
        local p = GetProfileByName(name)
        return type(p) == "table"
    end
    if base == "Default" then
        base = "Default-Imported"
    end
    if not Exists(base) then
        return base
    end
    for i = 2, 9999 do
        local cand = base .. "-" .. i
        if not Exists(cand) then
            return cand
        end
    end
    return base .. "-" .. date("%H%M%S")
end

local function SerializeProfileTable(p)
    local out = {}
    local defaults = _G.FrogskiCursorTrailDefaults or DEFAULTS
    for k, _ in pairs(defaults) do
        local v = p[k]
        if v ~= nil then
            local t = type(v)
            if t == "number" or t == "boolean" then
                out[#out + 1] = k .. "=" .. tostring(v)
            elseif t == "string" then
                out[#out + 1] = k .. "=" .. EscapeValue(v)
            elseif t == "table" and #v > 0 then
                local nums = {}
                for i = 1, #v do
                    nums[#nums + 1] = tostring(v[i])
                end
                out[#out + 1] = k .. "=" .. table.concat(nums, ",")
            end
        end
    end
    return table.concat(out, ";")
end

local function ParseProfileTable(body)
    local p = {}
    local defaults = _G.FrogskiCursorTrailDefaults or DEFAULTS
    for pair in tostring(body or ""):gmatch("[^;]+") do
        local k, v = pair:match("^([^=]+)=(.*)$")
        if k and defaults[k] ~= nil then
            v = tostring(v or "")
            local defaultType = type(defaults[k])
            if defaultType == "boolean" then
                p[k] = (v == "true")
            elseif defaultType == "number" then
                p[k] = tonumber(v) or defaults[k]
            elseif defaultType == "table" and v:find(",") then
                local t = {}
                for num in v:gmatch("[^,]+") do
                    t[#t + 1] = tonumber(num) or 0
                end
                p[k] = t
            else
                p[k] = UnescapeValue(v)
            end
        end
    end
    return p
end

function FCT2.db:ExportProfileString(name)
    name = name or self:GetCurrentProfile()
    if type(name) ~= "string" or name == "" then
        return nil, "bad name"
    end
    local prof = select(1, GetProfileByName(name))
    if type(prof) ~= "table" then
        return nil, "profile not found"
    end

    local plain = name .. "\0" .. SerializeProfileTable(prof)
    local crypt = XorCrypt(plain)
    local payload = Base64Encode(crypt)
    return "FCTP@2@" .. payload
end

function FCT2.db:ImportProfileString(str)
    str = tostring(str or "")
    str = str:gsub("[%c]", "")
    str = Trim(str)
    if str == "" then
        return nil, "empty string"
    end

    do
        local prefix, ver, payload = str:match("^(FCTP)@(%d+)@(.+)$")
        if prefix == "FCTP" and ver == "2" and payload and payload ~= "" then
            local decoded = Base64Decode(payload)
            if not decoded or decoded == "" then
                return nil, "decode failed (bad payload)"
            end
            local plain = XorCrypt(decoded)
            local importedName, body = plain:match("^(.-)%z(.*)$")
            importedName = Trim(importedName)
            if not body or body == "" then
                return nil, "import payload missing body"
            end

            local tbl = ParseProfileTable(body)
            local finalName = MakeUniqueProfileName(importedName) or ("Imported-" .. date("%Y%m%d-%H%M%S"))
            OverwriteProfile(finalName, tbl, false)
            self:SetProfile(finalName)
            return finalName
        end
    end

    local sep = EXPORT_DELIMITER
    if str:find("|") and not str:find(EXPORT_DELIMITER) then
        sep = "|"
    end

    local parts = {strsplit(sep, str)}
    if #parts < 5 then
        return nil, "malformed string (missing parts)"
    end
    if parts[1] ~= "FCTP" then
        return nil, "not an FCT export string"
    end

    local ver = parts[2]:match("^%s*(%d+)%s*$")
    if ver ~= "1" then
        return nil, "unsupported version: " .. tostring(parts[2])
    end

    local name = UnescapeValue(parts[3])
    local scope = parts[4]
    local body = table.concat(parts, sep, 5)
    if not name or name == "" then
        return nil, "missing profile name"
    end

    local makeWide = (scope == "ACCOUNT")
    local tbl = ParseProfileTable(body)
    OverwriteProfile(name, tbl, makeWide)
    self:SetProfile(name)
    return name
end

-- ===============================
-- Mount helper + Conditions
-- ==============================
local function TrimStr(s)
    return Trim(s)
end

local function SplitByCommaList(input)
    local out = {}
    input = tostring(input or "")
    for part in input:gmatch("([^,]+)") do
        part = TrimStr(part)
        if part ~= "" then
            out[#out + 1] = part
        end
    end
    if #out == 0 then
        input = TrimStr(input)
        if input ~= "" then
            out[1] = input
        end
    end
    return out
end

local function PlayerHasAuraSpellID(spellID)
    if not spellID then
        return false
    end
    if AuraUtil and AuraUtil.FindAuraBySpellId then
        local name = AuraUtil.FindAuraBySpellId(spellID, "player", "HELPFUL")
        return name ~= nil
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 80 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then
                break
            end
            if aura.spellId == spellID then
                return true
            end
        end
    end
    if UnitBuff then
        for i = 1, 80 do
            local _, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
            if not id then
                break
            end
            if id == spellID then
                return true
            end
        end
    end
    return false
end

local function GetMountSpellIDFromMountID(mountID)
    if not (C_MountJournal and C_MountJournal.GetMountInfoByID) then
        return nil
    end
    local name, spellID = C_MountJournal.GetMountInfoByID(mountID)
    if name and spellID then
        return spellID
    end
    return nil
end

local function FindMountSpellIDsByName(nameLower)
    local out = {}
    if not (C_MountJournal and C_MountJournal.GetMountIDs and C_MountJournal.GetMountInfoByID) then
        return out
    end
    local ids = C_MountJournal.GetMountIDs()
    if type(ids) ~= "table" then
        return out
    end
    for i = 1, #ids do
        local mountID = ids[i]
        local name, spellID = C_MountJournal.GetMountInfoByID(mountID)
        if name and spellID and name:lower() == nameLower then
            out[#out + 1] = spellID
        end
    end
    return out
end

local function MountIDIsActive(mountID)
    if not (C_MountJournal and C_MountJournal.GetMountInfoByID) then
        return false
    end
    local name, spellID, icon, active = C_MountJournal.GetMountInfoByID(mountID)
    return active == true
end

local function FindActiveMountSpellIDsByName(nameLower)
    local out = {}
    if not (C_MountJournal and C_MountJournal.GetMountIDs and C_MountJournal.GetMountInfoByID) then
        return out
    end
    local ids = C_MountJournal.GetMountIDs()
    if type(ids) ~= "table" then
        return out
    end
    for i = 1, #ids do
        local mountID = ids[i]
        local name, spellID, icon, active = C_MountJournal.GetMountInfoByID(mountID)
        if active == true and name and spellID and name:lower() == nameLower then
            out[#out + 1] = spellID
        end
    end
    return out
end

local function IsSpecificMountActive(query)
    query = TrimStr(query)
    if query == "" then
        return false
    end
    if not (IsMounted and IsMounted()) then
        return false
    end

    local queries = SplitByCommaList(query)
    for i = 1, #queries do
        local q = queries[i]
        if q and q ~= "" then
            local asNum = tonumber(q)
            if asNum then
                if C_MountJournal and C_MountJournal.GetMountInfoByID then
                    local name, spellID, icon, active = C_MountJournal.GetMountInfoByID(asNum)
                    if name and spellID and active ~= nil and active == true then
                        return true
                    end
                end

                if C_MountJournal and C_MountJournal.GetMountFromSpell then
                    local mountID = C_MountJournal.GetMountFromSpell(asNum)
                    if mountID and MountIDIsActive(mountID) then
                        return true
                    end
                end

                local spellID = GetMountSpellIDFromMountID(asNum)
                if spellID and PlayerHasAuraSpellID(spellID) then
                    return true
                end

                if PlayerHasAuraSpellID(asNum) then
                    return true
                end
            else
                local lower = q:lower()
                local spellIDs = FindActiveMountSpellIDsByName(lower)
                for j = 1, #spellIDs do
                    if spellIDs[j] then
                        return true
                    end
                end
                spellIDs = FindMountSpellIDsByName(lower)
                for j = 1, #spellIDs do
                    if PlayerHasAuraSpellID(spellIDs[j]) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function IsConditionTrue(whenKey, rule)
    if whenKey == "combat" then
        return UnitAffectingCombat and UnitAffectingCombat("player") or false
    elseif whenKey == "notcombat" then
        return not (UnitAffectingCombat and UnitAffectingCombat("player") or false)
    elseif whenKey == "resting" then
        return IsResting and IsResting() or false
    elseif whenKey == "mounted" then
        return IsMounted and IsMounted() or false
    elseif whenKey == "mount_specific" then
        return IsSpecificMountActive(rule and rule.mount)
    elseif type(whenKey) == "string" and whenKey:match("^spec:%d+$") then
        local wantID = tonumber(whenKey:match("^spec:(%d+)$"))
        if not wantID then
            return false
        end
        if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
            return false
        end
        local specIndex = GetSpecialization()
        if not specIndex then
            return false
        end
        local specID = select(1, GetSpecializationInfo(specIndex))
        return specID == wantID
    end

    local inInstance, instanceType = false, "none"
    if IsInInstance then
        inInstance, instanceType = IsInInstance()
    end

    if whenKey == "openworld" then
        return (not inInstance) or (instanceType == "none")
    elseif whenKey == "dungeon" then
        return inInstance and instanceType == "party"
    elseif whenKey == "raid" then
        return inInstance and instanceType == "raid"
    elseif whenKey == "pvp" then
        return inInstance and (instanceType == "pvp" or instanceType == "arena")
    elseif whenKey == "scenario" then
        return inInstance and instanceType == "scenario"
    end

    return false
end

function FCT2:UpdateConditionOverride()
    if not rootDB or not accountDB then
        NormalizeRoot()
    end

    FrogskisCursorTrailDB = FrogskisCursorTrailDB or {}
    local conds = FrogskisCursorTrailDB.conditions or {}

    local chosen = nil

    for i = 1, #conds do
        local rule = conds[i]
        if rule and rule.when and rule.profile and rule.profile ~= "" then
            if IsConditionTrue(rule.when, rule) then
                chosen = rule.profile
                break
            end
        end
    end
    if not chosen then
        self._autoLatchActive = false
        self._autoLatchProfile = nil
        self._activeAutomationProfile = nil

        local cur = (self.db and self.db.GetCurrentProfile) and self.db:GetCurrentProfile() or
                        (rootDB and rootDB.currentProfile) or "Default"

        if cur ~= "Default" then
            if self.db and self.db.SetProfile then
                self.db:SetProfile("Default")
            else
                SetActiveProfile("Default")
            end

            self:Refresh()
            if self.RefreshOptionsUI then
                self:RefreshOptionsUI()
            end
        end
        return
    end

    if self._autoLatchActive and self._autoLatchProfile == chosen then
        return
    end

    self._autoLatchActive = true
    self._autoLatchProfile = chosen
    self._activeAutomationProfile = nil

    if self.db and self.db.SetProfile then
        self.db:SetProfile(chosen)
    else
        SetActiveProfile(chosen)
    end

    self:Refresh()
    if self.RefreshOptionsUI then
        self:RefreshOptionsUI()
    end
end

-- ==============
-- RMBLook module 
-- ==============
local abs = math.abs
local MOUSELOOK_CURSOR_ATLAS = "Cursor_cast_128"

local RMBLook = {}
RMBLook.enabled = false
RMBLook.inLook = false
RMBLook.wasDown = false
RMBLook.lastX, RMBLook.lastY = 0, 0
RMBLook.threshold = 1
RMBLook.thresholdPassed = false
RMBLook.moveAccum = 0
RMBLook.holdActive = false
RMBLook.startedByAddon = false

RMBLook.blockWhileVisible = {function()
    return CharacterFrame
end}

RMBLook.enableLook = true
RMBLook.enableIndicator = true
RMBLook.enableCombatLook = false
RMBLook.cursorFrameSize = 40

local function EnsureCursorTex()
    if RMBLook.cursorFrame then
        return
    end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(RMBLook.cursorFrameSize, RMBLook.cursorFrameSize)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(99)
    f:Hide()
    f:SetAlpha(0.5)

    local base = f:CreateTexture(nil, "OVERLAY")
    base:SetAllPoints(f)
    base:SetAtlas(MOUSELOOK_CURSOR_ATLAS, true)

    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(f)
    glow:SetAtlas(MOUSELOOK_CURSOR_ATLAS, true)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.8)

    RMBLook.cursorFrame = f
    RMBLook.cursorTex = base
    RMBLook.cursorGlow = glow
end

local function ShowCursorTex()
    EnsureCursorTex()
    RMBLook.cursorFrame:Show()
end

local function HideCursorTex()
    if RMBLook.cursorFrame then
        RMBLook.cursorFrame:Hide()
    end
end

local function UpdateCursorTexPos()
    if not (RMBLook.cursorFrame and RMBLook.cursorFrame:IsShown()) then
        return
    end

    if type(GetScaledCursorPosition) == "function" then
        local x, y = GetScaledCursorPosition()
        if x and y then
            RMBLook.cursorFrame:ClearAllPoints()
            RMBLook.cursorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            return
        end
    end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = (x or 0) / scale, (y or 0) / scale
    RMBLook.cursorFrame:ClearAllPoints()
    RMBLook.cursorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local function SafeGetMouseFocus()
    if type(GetMouseFoci) == "function" then
        local foci = {GetMouseFoci()}
        return foci[1]
    end
    if UIParent and UIParent.GetMouseFocus then
        return UIParent:GetMouseFocus()
    end
    return nil
end

local function IsDragFrameUnderMouse()
    local f = SafeGetMouseFocus()
    while f and f ~= UIParent do
        if f.IsMovable and f:IsMovable() then
            return true
        end
        if f.GetScript then
            if f:GetScript("OnDragStart") or f:GetScript("OnDragStop") then
                return true
            end
        end
        local gp = f and f.GetParent
        if type(gp) == "function" then
            local ok, parent = pcall(gp, f)
            f = ok and parent or nil
        else
            f = nil
        end
    end
    return false
end

local function IsBlocked()
    for i = 1, #RMBLook.blockWhileVisible do
        local getter = RMBLook.blockWhileVisible[i]
        local f = (type(getter) == "function") and getter() or getter
        if f and f.IsShown and f:IsShown() then
            return true
        end
    end
    return false
end

local function ForEachMouseFrame(fn)
    if type(GetMouseFoci) == "function" then
        local foci = GetMouseFoci()
        if type(foci) == "table" then
            for i = 1, #foci do
                local f = foci[i]
                if f and fn(f) then
                    return true
                end
            end
        end
        return false
    end

    if type(GetMouseFocus) == "function" then
        local f = GetMouseFocus()
        local hops = 0
        while f and hops < 30 do
            hops = hops + 1
            if fn(f) then
                return true
            end
            local gp = f and f.GetParent
            if type(gp) == "function" then
                local ok, parent = pcall(gp, f)
                f = ok and parent or nil
            else
                f = nil
            end
        end
    end
end

local function IsMouseOverStatusBar()
    return ForEachMouseFrame(function(f)
        if f.IsObjectType and (f:IsObjectType("StatusBar") or f:IsObjectType("UnitFrame")) then
            return true
        end
        if f.UpdateTextStringWithValues or f.ShowStatusBarText or f.HideStatusBarText then
            return true
        end
        return false
    end)
end

local function StopLook()
    if RMBLook.enableLook and RMBLook.startedByAddon then
        pcall(MouselookStop)
    end
    RMBLook.inLook = false
    RMBLook.thresholdPassed = false
    RMBLook.moveAccum = 0
    RMBLook.holdActive = false
    RMBLook.startedByAddon = false
    HideCursorTex()
end

local function SyncLookState(down)
    local ml = (type(IsMouselooking) == "function") and IsMouselooking() or false
    RMBLook.inLook = ml

    if down and ml then
        RMBLook.thresholdPassed = true
    end

    if not RMBLook.enableIndicator then
        HideCursorTex()
        return ml
    end

    if ml and RMBLook.thresholdPassed then
        ShowCursorTex()
        UpdateCursorTexPos()
    else
        HideCursorTex()
    end
    return ml
end

local function IsPlayerInCombat()
    return UnitAffectingCombat and UnitAffectingCombat("player") or false
end

local function SafeStartLook()
    if not RMBLook.enableLook then
        return
    end
    if RMBLook.enableCombatLook and (not IsPlayerInCombat()) then
        return
    end
    if IsBlocked() then
        return
    end
    if IsDragFrameUnderMouse() then
        return
    end
    if IsMouseOverStatusBar() then
        return
    end

    pcall(MouselookStart)
    if type(IsMouselooking) == "function" and IsMouselooking() then
        RMBLook.startedByAddon = true
    end
end

local function UpdateThresholdPassed()
    if RMBLook.thresholdPassed then
        return true
    end

    if type(GetMouseDelta) == "function" then
        local dx, dy = GetMouseDelta()
        RMBLook.moveAccum = RMBLook.moveAccum + abs(dx or 0) + abs(dy or 0)
        if RMBLook.moveAccum >= RMBLook.threshold then
            RMBLook.thresholdPassed = true
            return true
        end
        return false
    end

    local x, y = GetCursorPosition()
    if abs(x - RMBLook.lastX) > RMBLook.threshold or abs(y - RMBLook.lastY) > RMBLook.threshold then
        RMBLook.thresholdPassed = true
        return true
    end
    return false
end

local function RMB_OnUpdate()
    if not RMBLook.enabled then
        HideCursorTex()
        return
    end

    local down = IsMouseButtonDown("RightButton")

    if down and not RMBLook.wasDown then
        RMBLook.lastX, RMBLook.lastY = GetCursorPosition()
        RMBLook.thresholdPassed = false
        RMBLook.moveAccum = 0
        RMBLook.holdActive = true
        if RMBLook.enableIndicator then
            EnsureCursorTex()
        end
    end

    if (not down) and RMBLook.wasDown then
        StopLook()
    end

    RMBLook.wasDown = down

    local isLooking = SyncLookState(down)

    if not down then
        return
    end

    if IsBlocked() then
        if RMBLook.startedByAddon then
            StopLook()
        else
            RMBLook.inLook = (type(IsMouselooking) == "function") and IsMouselooking() or false
            RMBLook.thresholdPassed = false
            RMBLook.moveAccum = 0
            RMBLook.holdActive = false
        end

        if RMBLook.enableIndicator and down then
            ShowCursorTex()
            UpdateCursorTexPos()
        else
            HideCursorTex()
        end
        RMBLook.wasDown = down
        return
    end

    local passed = UpdateThresholdPassed()
    if (not isLooking) and passed then
        SafeStartLook()
        SyncLookState(down)
    end

    if RMBLook.inLook and RMBLook.thresholdPassed then
        UpdateCursorTexPos()
    end
end

function RMBLook:Init()
    if self.frame then
        return
    end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetScript("OnUpdate", RMB_OnUpdate)
    self.frame = f
end

function RMBLook:Enable(threshold)
    self:Init()
    self.enabled = true
    self.wasDown = false
    self.inLook = false
    self.thresholdPassed = false
    self.moveAccum = 0
    self.holdActive = false
    self.startedByAddon = false
    if type(threshold) == "number" then
        self.threshold = threshold
    end
end

function RMBLook:Disable()
    self.enabled = false
    self.wasDown = false
    self.startedByAddon = false
    StopLook()
end

function RMBLook:SetThreshold(n)
    if type(n) == "number" then
        self.threshold = n
    end
end

function RMBLook:SetLookEnabled(on)
    self.enableLook = not not on
    if not self.enableLook then
        if (type(IsMouselooking) == "function") and IsMouselooking() then
            pcall(MouselookStop)
        end
        self.inLook = false
    end
end

function RMBLook:SetIndicatorEnabled(on)
    self.enableIndicator = not not on
    if not self.enableIndicator then
        HideCursorTex()
    end
end

_G.RMBLook = RMBLook

-- ========================
-- NEw Trail Engine 
-- ========================
local Anchor = CreateFrame("Frame", nil, UIParent)
Anchor:SetAllPoints(UIParent)

local headTex
local slotTex = {}
local pointsX, pointsY, pointsT = {}, {}, {}
local headIndex = 1
local haveInit = false
local trailDist = 0
local lastX, lastY
local lastSampleX, lastSampleY
local lastUpdateTime
local lastEmitTime = 0
local ElementCap = 800
local MaxSpacing = 2
local duration = 0.35
local onlyincombat = false
local rainbowx = true
local colourspeed = 2.5
local numPhases = 6
local phaseColors
local blendmodeStr = "ADD"
local cursorLayerStrata = "TOOLTIP"
local alphaMul = 1.0
local dotW, dotH = 40, 40
local offX, offY = 0, 0
local shrinkWithTime = true
local shrinkWithDistance = true
local updateEveryOther = false
local adaptiveTargetFPS = 90
local lastHeadPX, lastHeadPY = nil, nil
local lastHeadOffX, lastHeadOffY = nil, nil
local invDuration = 1 / duration
local posByRank = {}
local sqrtPosByRank = {}
local MAX_STEPS_PER_TICK = 250

local DEBUG_COUNT = false

local debugHolder = CreateFrame("Frame", nil, UIParent)
debugHolder:SetPoint("TOP", UIParent, "TOP", 0, -40)
debugHolder:SetSize(900, 90)
debugHolder:Hide()

local debugLabel1 = debugHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
debugLabel1:SetPoint("TOP", debugHolder, "TOP", 0, 0)
debugLabel1:SetJustifyH("RIGHT")
debugLabel1:SetText("Frogski's Cursor Trail Textures count:")
debugLabel1:SetScale(1.3)

local debugValue1 = debugHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
debugValue1:SetPoint("LEFT", debugLabel1, "RIGHT", 8, 0)
debugValue1:SetJustifyH("LEFT")
debugValue1:SetScale(1.3)

local debugLabel2 = debugHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
debugLabel2:SetPoint("TOP", debugHolder, "TOP", 0, -28)
debugLabel2:SetJustifyH("RIGHT")
debugLabel2:SetText("FPS / update target:")
debugLabel2:SetScale(1.3)

local debugValue2 = debugHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
debugValue2:SetPoint("LEFT", debugLabel2, "RIGHT", 8, 0)
debugValue2:SetJustifyH("LEFT")
debugValue2:SetScale(1.3)

local fpsElapsed, fpsFrames, fpsValue = 0, 0, 0

local fpsSampleElapsed = 0
local fpsAutoValue = 120
local FPS_SAMPLE_PERIOD = 0.25

function FrogskisCursorTrail2:IsDebugEnabled()
    return DEBUG_COUNT == true
end

function FrogskisCursorTrail2:SetDebugEnabled(enabled)
    DEBUG_COUNT = enabled
    if enabled then
        debugHolder:Show()
    else
        debugHolder:Hide()
    end
end

local function WrapIndex(i, count)
    if i < 1 then
        i = i % count
        if i == 0 then
            i = count
        end
    elseif i > count then
        i = ((i - 1) % count) + 1
    end
    return i
end

local function EnsurePoints(count, x, y)
    x = x or 0
    y = y or 0
    local now = GetTime()
    lastEmitTime = now
    for i = 1, count do
        pointsX[i] = x
        pointsY[i] = y
        pointsT[i] = now
    end
    headIndex = 1
    haveInit = true
end
local SetSlotTexPos
local SetHeadTexPos
local function ResetTrailSilent(x, y, now)
    local deadTime = now - (duration + 1)
    lastEmitTime = deadTime
    for i = 1, ElementCap do
        pointsX[i] = x
        pointsY[i] = y
        pointsT[i] = deadTime
    end
    for slot = 1, ElementCap do
        if slotTex[slot] then
            SetSlotTexPos(slot, x, y)
        end
    end
    headIndex = 1
    haveInit = true
    lastSampleX, lastSampleY = x, y
    lastX, lastY = x, y
    lastHeadPX, lastHeadPY = nil, nil
    lastHeadOffX, lastHeadOffY = nil, nil
end

local function PushPoint(x, y, now)
    headIndex = WrapIndex(headIndex + 1, ElementCap)
    pointsX[headIndex] = x
    pointsY[headIndex] = y
    pointsT[headIndex] = now or GetTime()
    lastEmitTime = pointsT[headIndex]
    SetSlotTexPos(headIndex, x, y)
end

local function GetCursorXY()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    return x / scale, y / scale
end
SetSlotTexPos = function(slot, x, y)
    local tex = slotTex[slot]
    if not tex then
        return
    end
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + offX, y + offY)
end

SetHeadTexPos = function(x, y)
    if not headTex then
        return
    end

    local px = x + offX
    local py = y + offY

    if lastHeadPX and lastHeadPY and lastHeadOffX == offX and lastHeadOffY == offY then
        if math.abs(px - lastHeadPX) < 0.05 and math.abs(py - lastHeadPY) < 0.05 then
            return
        end
    end

    headTex:ClearAllPoints()
    headTex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)

    lastHeadPX, lastHeadPY = px, py
    lastHeadOffX, lastHeadOffY = offX, offY
end

-- ===============
-- Texture routing
-- ===============
local function LooksLikeAPath(s)
    if not s or s == "" then
        return false
    end
    if s:find("\\") or s:find("/") then
        return true
    end
    s = s:lower()
    if s:match("%.blp$") or s:match("%.tga$") or s:match("%.png$") or s:match("%.jpg$") or s:match("%.jpeg$") then
        return true
    end
    return false
end

local function TrySetAtlas(tex, atlasName)
    if not atlasName or atlasName == "" then
        return false
    end
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName) then
        tex:SetAtlas(atlasName, true)
        return true
    end
    return false
end

local function ApplyElementTexture(tex)
    local p = GetEffectiveCfg()
    local input = p and p.textureInput
    if not input or input == "" then
        input = (p and p.fallbackTexture) or "bags-glow-flash"
    end

    if LooksLikeAPath(input) then
        tex:SetTexture(input)
        tex:SetTexCoord(0, 1, 0, 1)
        return
    end

    if TrySetAtlas(tex, input) then
        return
    end

    tex:SetTexture(input)
    tex:SetTexCoord(0, 1, 0, 1)
end

local function CreateOneTexture()
    local t = Anchor:CreateTexture(nil, "OVERLAY")
    t:SetSize(dotW, dotH)
    t:SetBlendMode(blendmodeStr)
    t:SetAlpha(0.9)
    t:Hide()
    ApplyElementTexture(t)
    return t
end

local function EnsureTextures(count)

    if not headTex then
        headTex = CreateOneTexture()
    end
    headTex:SetBlendMode(blendmodeStr)
    ApplyElementTexture(headTex)

    for slot = 1, count do
        if not slotTex[slot] then
            slotTex[slot] = CreateOneTexture()
        end
        slotTex[slot]:SetBlendMode(blendmodeStr)
        ApplyElementTexture(slotTex[slot])
    end
    for slot = count + 1, #slotTex do
        if slotTex[slot] then
            slotTex[slot]:Hide()
        end
    end
end

-- ======
-- Colors
-- ======
local function WorldLockedRainbowColor(worldDistPx)
    local phases = math.max(1, numPhases or 1)
    if not phaseColors or not phaseColors[1] or phases == 1 then
        local c = phaseColors and phaseColors[1] or {1, 1, 1}
        return c[1] or 1, c[2] or 1, c[3] or 1
    end

    local baseBandLenPx = math.max(1e-3, MaxSpacing * (ElementCap / phases))
    local spd = tonumber(colourspeed) or 1
    if spd <= 0 then
        spd = 1
    end

    local bandLenPx = baseBandLenPx / spd

    local u = (worldDistPx / bandLenPx) % phases
    local i1 = math.floor(u) + 1
    local frac = u - math.floor(u)
    local i2 = (i1 % phases) + 1

    local c1 = phaseColors[i1] or phaseColors[1]
    local c2 = phaseColors[i2] or c1

    local r1, g1, b1 = c1[1] or 1, c1[2] or 1, c1[3] or 1
    local r2, g2, b2 = c2[1] or 1, c2[2] or 1, c2[3] or 1

    return r1 + (r2 - r1) * frac, g1 + (g2 - g1) * frac, b1 + (b2 - b1) * frac
end

local function ColorByVisibleRank(rank, total)

    if not phaseColors or not phaseColors[1] then
        return 1, 1, 1
    end

    if not total or total <= 1 then
        local c = phaseColors[1]
        return c[1] or 1, c[2] or 1, c[3] or 1
    end

    local t = rank / (total - 1)

    local phases = math.max(1, numPhases or 1)
    if phases == 1 then
        local c = phaseColors[1]
        return c[1] or 1, c[2] or 1, c[3] or 1
    end

    local fp = t * (phases - 1)
    local i1 = math.floor(fp) + 1
    local i2 = math.min(i1 + 1, phases)
    local frac = fp - (i1 - 1)

    local c1 = phaseColors[i1] or phaseColors[1]
    local c2 = phaseColors[i2] or c1

    local r1, g1, b1 = c1[1] or 1, c1[2] or 1, c1[3] or 1
    local r2, g2, b2 = c2[1] or 1, c2[2] or 1, c2[3] or 1

    local r = r1 + (r2 - r1) * frac
    local g = g1 + (g2 - g1) * frac
    local b = b1 + (b2 - b1) * frac
    return r, g, b
end

local function GetPlayerClassColorRGB()
    local _, classFile = UnitClass("player")
    if classFile then
        if C_ClassColor and C_ClassColor.GetClassColor then
            local c = C_ClassColor.GetClassColor(classFile)
            if c and c.GetRGB then
                return c:GetRGB()
            end
        end
        if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
            local c = RAID_CLASS_COLORS[classFile]
            return c.r, c.g, c.b
        end
    end
    return 1, 1, 1
end

-- =====================
-- ApplyConfig + Refresh 
-- =====================
local function ApplyConfig()
    local p = GetEffectiveCfg()
    if type(p) ~= "table" then
        p = _G.FrogskiCursorTrailDefaults or DEFAULTS
    end

    SanitizeProfile(p)
    shrinkWithTime = (p.shrinkWithTime ~= false)
    shrinkWithDistance = (p.shrinkWithDistance ~= false)

    MaxSpacing = tonumber(p.dotdistance) or 2

    if MaxSpacing <= 0 then
        MaxSpacing = 1
    end

    duration = tonumber(p.lifetime) or 0.35
    if duration < 0.05 then
        duration = 0.05
    end

    ElementCap = math.floor(Clamp(tonumber(p.maxdots) or 800, 1, 2000))
    invDuration = (duration > 0) and (1 / duration) or 0

    wipe(posByRank)
    wipe(sqrtPosByRank)

    if ElementCap <= 1 then
        posByRank[1] = 1
        sqrtPosByRank[1] = 1
    else
        local denom = (ElementCap - 1)
        for rank = 1, ElementCap do
            local pos = 1 - ((rank - 1) / denom)
            posByRank[rank] = pos
            sqrtPosByRank[rank] = math.sqrt(pos)
        end
    end

    onlyincombat = (p.combatoption == true)
    rainbowx = (p.changeWithTime == true)
    colourspeed = tonumber(p.colourspeed) or 2.5
    if colourspeed <= 0 then
        colourspeed = 1
    end

    numPhases = math.max(1, math.min(10, math.floor(tonumber(p.phasecount) or 10)))

    alphaMul = tonumber(p.Alphax) or 1.0
    alphaMul = Clamp(alphaMul, 0, 1)

    dotW = tonumber(p.widthx) or 45
    dotH = tonumber(p.heightx) or 45
    dotW = Clamp(dotW, 1, 256)
    dotH = Clamp(dotH, 1, 256)

    offX = tonumber(p.offsetX) or 0
    offY = tonumber(p.offsetY) or 0

    if p.useClassColor then
        local r, g, b = GetPlayerClassColorRGB()
        r = r * 1 / glowBoost
        g = g * 1 / glowBoost
        b = b * 1 / glowBoost

        local c = {r, g, b}
        phaseColors = {c, c, c, c, c, c, c, c, c, c}
    else
        phaseColors = {p.colour1, p.colour2, p.colour3, p.colour4, p.colour5, p.colour6, p.colour7, p.colour8,
                       p.colour9, p.colour10}

        for i = 1, 10 do
            if type(phaseColors[i]) ~= "table" then
                phaseColors[i] = {1, 1, 1}
            end
        end
    end

    if p.blendmode == 1 then
        blendmodeStr = "ADD"
    elseif p.blendmode == 2 then
        blendmodeStr = "BLEND"
    else
        blendmodeStr = "ADD"
    end
    updateEveryOther = (p.updateEveryOther == true)
    adaptiveTargetFPS = math.floor(Clamp(tonumber(p.adaptiveTargetFPS) or 90, 1, 240))
    if p.cursorlayer == 1 then
        cursorLayerStrata = "TOOLTIP"
    elseif p.cursorlayer == 2 then
        cursorLayerStrata = "BACKGROUND"
    else
        cursorLayerStrata = "TOOLTIP"
    end

    Anchor:SetFrameStrata(cursorLayerStrata)

    if RMBLook then
        RMBLook.enableLook = (p.enableLook ~= false)
        RMBLook.enableIndicator = (p.enableIndicator ~= false)
        RMBLook.enableCombatLook = (p.enableCombatLook == true)

        local sz = tonumber(p.cursorFrameSize) or 40
        sz = Clamp(sz, 10, 256)
        RMBLook.cursorFrameSize = sz
        if RMBLook.cursorFrame then
            RMBLook.cursorFrame:SetSize(sz, sz)
        end
        if not RMBLook.enableIndicator and RMBLook.cursorFrame then
            RMBLook.cursorFrame:Hide()
        end
    end
end

function FCT2:Refresh()
    ApplyConfig()

    EnsureTextures(ElementCap)
    for slot = 1, ElementCap do
        if slotTex[slot] and pointsX[slot] and pointsY[slot] then
            SetSlotTexPos(slot, pointsX[slot], pointsY[slot])
        end
    end
    if not haveInit then
        local x, y = GetCursorXY()
        ResetTrailSilent(x, y, GetTime())
        lastUpdateTime = GetTime()
        return
    end

    if #pointsX ~= ElementCap then
        local x = lastX or 0
        local y = lastY or 0
        local now = GetTime()
        ResetTrailSilent(x, y, now)
        lastSampleX, lastSampleY = x, y
        lastX, lastY = x, y
    end

end
local function CountVisibleDots(now, shouldGenerate, headFade)
    if not shouldGenerate or headFade <= 0.01 then
        return 0
    end

    local count = 1
    local idx = headIndex

    for i = 2, ElementCap do
        idx = idx - 1
        if idx <= 0 then
            idx = ElementCap
        end

        local born = pointsT[idx]
        if not born then
            break
        end

        local age = now - born
        if duration > 0 and age >= duration then
            break
        end

        count = count + 1
    end

    return count
end

-- =============
-- Trail update 
-- =============

local function AddCursorPathPoint(x, y, now)
    now = now or GetTime()

    if not haveInit then
        ResetTrailSilent(x, y, now)
        PushPoint(x, y, now)

        lastX, lastY = x, y
        lastSampleX, lastSampleY = x, y
        return
    end

    if not lastSampleX or not lastSampleY then
        lastSampleX, lastSampleY = x, y
    end

    local lx, ly = lastSampleX, lastSampleY
    local dx = x - lx
    local dy = y - ly
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist <= 0.0001 then
        lastX, lastY = x, y
        return
    end

    local step = MaxSpacing
    if step <= 0 then
        step = 1
    end

    if dist < step then
        lastX, lastY = x, y
        return
    end

    local n = math.floor(dist / step)
    if n > MAX_STEPS_PER_TICK then
        ResetTrailSilent(x, y, now)
        return
    end
    trailDist = trailDist + (n * step)

    local ux = dx / dist
    local uy = dy / dist
    for s = 1, n do
        local px = lx + ux * step * s
        local py = ly + uy * step * s
        PushPoint(px, py, now)
        lastSampleX, lastSampleY = px, py
    end

    lastX, lastY = x, y
end

local function UpdateTrail(dt)
    local now = GetTime()
    local x, y = GetCursorXY()
    if trailDormant and dormantX and dormantY then
        if math.abs(x - dormantX) < 0.5 and math.abs(y - dormantY) < 0.5 then
            if headTex then
                headTex:Hide()
            end
            for slot = 1, ElementCap do
                local tex = slotTex[slot]
                if tex then
                    tex:Hide()
                end
            end
            return
        end
    end
    if lastUpdateTime then
        local hitch = now - lastUpdateTime
        if hitch > 0.25 then
            ResetTrailSilent(x, y, now)
            lastUpdateTime = now
            return
        end
    end
    lastUpdateTime = now

    local p = GetEffectiveCfg()
    local shouldGenerate = true
    if onlyincombat then
        shouldGenerate = UnitAffectingCombat and UnitAffectingCombat("player") or false
    end

    if shouldGenerate then
        AddCursorPathPoint(x, y, now)
    else
        lastX, lastY = x, y
        lastSampleX, lastSampleY = x, y
    end

    local idle = now - (lastEmitTime or now)
    local headFade = (duration > 0) and (1 - Clamp(idle / duration, 0, 1)) or 1
    if not shouldGenerate then
        headFade = 0
    end

    local visibleCount = CountVisibleDots(now, shouldGenerate, headFade)
    local visibleRank = 0

    if visibleCount == 0 and headFade <= 0.01 then
        if not trailDormant then
            haveInit = false
            lastSampleX, lastSampleY = nil, nil
            lastX, lastY = nil, nil
            trailDist = 0

            trailDormant = true
            dormantX, dormantY = x, y
        end
    else
        trailDormant = false
        dormantX, dormantY = nil, nil
    end

    local r, g, b

    -- ==========================
    -- Render (NO SetPoint spam)
    -- ==========================

    if headTex then
        if headFade <= 0.01 or visibleCount == 0 then
            headTex:Hide()
        else
            local pos = (shrinkWithDistance and (posByRank[1] or 1)) or 1
            local sqrtPos = (shrinkWithDistance and (sqrtPosByRank[1] or 1)) or 1

            local headScale = headFade
            local headAlpha = headFade
            if not shrinkWithTime then
                headScale = 1
                headAlpha = 1
            end

            local alpha, scale
            if shrinkWithTime and shrinkWithDistance then
                local sTime = math.sqrt(headAlpha) -- headAlpha == headScale here
                alpha = alphaMul * sTime * sqrtPos
                scale = sTime * sqrtPos
            else
                alpha = alphaMul * headAlpha * pos
                scale = headScale * pos
            end

            if alpha <= 0.01 or scale <= 0.01 then
                headTex:Hide()
            else
                visibleRank = 1
                if rainbowx then
                    r, g, b = WorldLockedRainbowColor(trailDist)
                else
                    r, g, b = ColorByVisibleRank(visibleRank, visibleCount)
                end

                headTex:Show()
                headTex:SetSize(dotW * scale, dotH * scale)
                headTex:SetVertexColor(r * glowBoost, g * glowBoost, b * glowBoost, alpha)
                SetHeadTexPos(x, y)
            end
        end
    end

    local slot = headIndex

    for rank = 2, visibleCount do
        slot = slot - 1
        if slot <= 0 then
            slot = ElementCap
        end

        local tex = slotTex[slot]
        if tex then
            local born = pointsT[slot]
            if not born then
                tex:Hide()
            else
                local age = now - born
                if duration > 0 and age >= duration then
                    tex:Hide()
                else
                    local t = age * invDuration
                    if t < 0 then
                        t = 0
                    elseif t > 1 then
                        t = 1
                    end

                    local timeFade = 1 - t
                    local timeScale = 1 - t
                    if not shrinkWithTime then
                        timeFade = 1
                        timeScale = 1
                    end

                    local pos = (shrinkWithDistance and (posByRank[rank] or 1)) or 1
                    local sqrtPos = (shrinkWithDistance and (sqrtPosByRank[rank] or 1)) or 1

                    local alpha, scale
                    if shrinkWithTime and shrinkWithDistance then
                        local sTime = math.sqrt(timeFade)
                        alpha = alphaMul * sTime * sqrtPos
                        scale = sTime * sqrtPos
                    else
                        alpha = alphaMul * timeFade * pos
                        scale = timeScale * pos
                    end

                    if alpha <= 0.01 or scale <= 0.01 then
                        tex:Hide()
                    else
                        if rainbowx then
                            local behind = (rank - 1) * MaxSpacing
                            r, g, b = WorldLockedRainbowColor(trailDist - behind)
                        else
                            r, g, b = ColorByVisibleRank(rank, visibleCount)
                        end

                        tex:Show()
                        tex:SetSize(dotW * scale, dotH * scale)
                        tex:SetVertexColor(r * glowBoost, g * glowBoost, b * glowBoost, alpha)
                    end
                end
            end
        end
    end
    local slot2 = slot
    for rank = visibleCount + 1, ElementCap do
        slot2 = slot2 - 1
        if slot2 <= 0 then
            slot2 = ElementCap
        end
        local tex = slotTex[slot2]
        if tex then
            tex:Hide()
        end
    end

    if DEBUG_COUNT then
        local shown = 0
        for i = 1, ElementCap do
            local tex = slotTex[i]
            if tex and tex:IsShown() then
                shown = shown + 1
            end
        end

        local hzStr = updateEveryOther and (("%d Hz"):format(adaptiveTargetFPS or 0)) or "every frame"

        debugValue1:SetText(("%d / %d"):format(shown, ElementCap))
        debugValue2:SetText(("%d  /  %s"):format(fpsValue, hzStr))
    else
    end

end

local function UpdateAutoFPS(dt)
    fpsSampleElapsed = fpsSampleElapsed + (dt or 0)

    if fpsSampleElapsed < FPS_SAMPLE_PERIOD then
        return
    end
    fpsSampleElapsed = 0

    local fpsNow
    if type(GetFramerate) == "function" then
        fpsNow = GetFramerate()
    end

    if not fpsNow or fpsNow <= 0 then
        if fpsElapsed > 0 then
            fpsNow = fpsFrames / fpsElapsed
        else
            fpsNow = fpsAutoValue
        end
    end

    fpsAutoValue = fpsAutoValue * 0.8 + fpsNow * 0.2
end

-- =======
-- Events 
-- =======
local function OnAnyAutomationEvent()
    if FCT2.UpdateConditionOverride then
        FCT2:UpdateConditionOverride()
    end
end

FCT2:RegisterEvent("PLAYER_LOGIN")
FCT2:RegisterEvent("PLAYER_LOGOUT")
FCT2:RegisterEvent("PLAYER_REGEN_DISABLED")
FCT2:RegisterEvent("PLAYER_REGEN_ENABLED")
FCT2:RegisterEvent("PLAYER_UPDATE_RESTING")
FCT2:RegisterEvent("PLAYER_ENTERING_WORLD")
FCT2:RegisterEvent("ZONE_CHANGED_NEW_AREA")
FCT2:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
FCT2:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
FCT2:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

FCT2:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        NormalizeRoot()
        if self.db then
            local db = self.db:GetProfileTable()
            db.maxdots = math.min(db.maxdots or DEFAULTS.maxdots, 800)
        end
        self:Refresh()

        local x, y = GetCursorXY()
        lastX, lastY = x, y
        lastSampleX, lastSampleY = x, y
        EnsurePoints(ElementCap, x, y)

        RMBLook:Enable(1)

        OnAnyAutomationEvent()

        local _dtAcc = 0

        self:SetScript("OnUpdate", function(_, dt)
            if DEBUG_COUNT then
                fpsElapsed = fpsElapsed + dt
                fpsFrames = fpsFrames + 1
                if fpsElapsed >= 1 then
                    fpsValue = math.floor(fpsFrames / fpsElapsed + 0.5)
                    fpsElapsed = 0
                    fpsFrames = 0
                end
            end

            if not updateEveryOther then
                _dtAcc = 0
                UpdateTrail(dt)
                return
            end

            local targetHz = tonumber(adaptiveTargetFPS) or 60
            targetHz = math.floor(Clamp(targetHz, 1, 240))

            local interval = 1 / targetHz
            _dtAcc = _dtAcc + dt

            if _dtAcc < interval then
                return
            end

            local steps = math.floor(_dtAcc / interval)
            if steps > 3 then
                steps = 3
            end

            for i = 1, steps do
                UpdateTrail(interval)
            end

            _dtAcc = _dtAcc - (steps * interval)

        end)

    elseif event == "PLAYER_LOGOUT" then
        self:SetScript("OnUpdate", nil)

    else
        OnAnyAutomationEvent()
    end
end)
