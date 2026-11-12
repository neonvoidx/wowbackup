local _, GQ = ...

-- Localization. English is the source text and the fallback: GQ.L[text]
-- returns the translation when the active locale has one, else text itself.
-- Locale files fill their tables only when GetLocale() matches them.
--
-- Data tables stay English on purpose: several code paths search them.
-- Translate at display time:
--   GQ.TL(text)        a data text (instructions, lore, proc), sentence by sentence
--   GQ.TN(kind, name)  a proper noun: zone, npc, quest, item, object, enchant, faction
--   GQ.TX(text)        a label that may be UI text or a place name
--
-- GQ.LocaleText      whole English text -> translation
-- GQ.LocaleSentences one English sentence -> translation
-- GQ.LocaleRules     { pattern, function(...) return translation end } tried in
--                    order on a sentence with no exact translation. A rule
--                    returns nil to pass the sentence on to the next rule.
-- GQ.LocaleObjectives the text after "Objective: " in instructions -> the
--                    quest's objective as the client words it
-- GQ.LocaleNames     English proper noun -> translation, by kind
--
-- The game client and the language on screen are separate. A client starts
-- in its own language when that language addon is enabled. An English client
-- stays in English until the player picks another language. The choice is
-- settings.locale and applies after a reload. GQ.TClient still follows the
-- game client, so map names match the maps.

GQ.LOCALE = (GetLocale and GetLocale()) or "enUS"
local ENGLISH = GQ.LOCALE == "enUS" or GQ.LOCALE == "enGB"

-- Every language other than English lives in one addon, GearQuestForever_Languages.
-- It stays unloaded while English is selected. Disable that addon to keep
-- GearQuest in English.
GQ.LocalePacks = {
    { id = "frFR", name = "Français" },
    { id = "deDE", name = "Deutsch" },
    { id = "esES", name = "Español" },
    { id = "esMX", name = "Español (AL)" },
    { id = "ptBR", name = "Português" },
    { id = "ruRU", name = "Русский" },
    { id = "koKR", name = "한국어" },
    { id = "zhCN", name = "简体中文" },
    { id = "zhTW", name = "繁體中文" },
}

local PACK_IDS = {}
for i = 1, #GQ.LocalePacks do
    PACK_IDS[GQ.LocalePacks[i].id] = true
end

GQ.LOCALE_ADDON = "GearQuestForever_Languages"

function GQ:LocalePackSeen()
    local name = self.LOCALE_ADDON
    if C_AddOns and C_AddOns.DoesAddOnExist then
        return C_AddOns.DoesAddOnExist(name) and true or false
    end
    if GetAddOnInfo then
        local title = GetAddOnInfo(name)
        return type(title) == "string" and title ~= ""
    end
    return false
end

function GQ:LocalePackAvailable()
    if not self:LocalePackSeen() then
        return false
    end
    local name = self.LOCALE_ADDON
    if C_AddOns and C_AddOns.GetAddOnEnableState then
        local who = UnitName and UnitName("player")
        local ok, state = pcall(C_AddOns.GetAddOnEnableState, name, who)
        if not ok then
            ok, state = pcall(C_AddOns.GetAddOnEnableState, who, name)
        end
        if not ok then
            ok, state = pcall(C_AddOns.GetAddOnEnableState, name)
        end
        if ok and (state == 0 or state == false) then
            return false
        end
    end
    return true
end

local function WantLocale(settings)
    local chosen = settings and settings.locale
    if chosen == "enUS" or chosen == "enGB" then
        return "enUS"
    end
    if chosen and PACK_IDS[chosen] then
        return chosen
    end
    if settings and settings.englishInterface then
        return "enUS"
    end
    if PACK_IDS[GQ.LOCALE] then
        return GQ.LOCALE
    end
    return "enUS"
end

local saved = type(GearQuestForeverDB) == "table" and GearQuestForeverDB.settings or nil
GQ.ActiveLocale = WantLocale(saved)
GQ.LocaleActive = GQ.ActiveLocale ~= "enUS" and GQ.ActiveLocale ~= "enGB"

function GQ:LoadLocalePack()
    local id = GQ.ActiveLocale
    if not id or id == "enUS" or id == "enGB" then
        return
    end
    if not self:LocalePackAvailable() then
        GQ.ActiveLocale = "enUS"
        GQ.LocaleActive = false
        return
    end
    local name = self.LOCALE_ADDON
    local ok, reason
    if C_AddOns and C_AddOns.LoadAddOn then
        ok, reason = C_AddOns.LoadAddOn(name)
    elseif LoadAddOn then
        ok, reason = LoadAddOn(name)
    end
    if not ok then
        GQ.LocaleLoadReason = reason
        GQ.ActiveLocale = "enUS"
        GQ.LocaleActive = false
    end
end

local ui = {}
GQ.LocaleUI = ui
-- Text handed out before the saved settings exist: translation -> English key.
local loadTimeKeys = {}
local settingsKnown = false
GQ.L = setmetatable({}, {
    __index = function(_, key)
        if GQ.LocaleActive then
            local translated = ui[key]
            if translated ~= nil then
                if not settingsKnown and loadTimeKeys[translated] == nil then
                    loadTimeKeys[translated] = key
                end
                return translated
            end
        end
        return key
    end,
    __newindex = function(_, key, value)
        ui[key] = value
    end,
})

-- Tables built while the files load take GQ.L text before the saved
-- settings exist. GQ.LocaleTable marks them so English can be put back.
local loadTimeTables = {}
function GQ.LocaleTable(tbl)
    loadTimeTables[#loadTimeTables + 1] = tbl
    return tbl
end

local function RestoreEnglish(tbl, english, depth)
    for key, value in pairs(tbl) do
        if type(value) == "string" and english[value] then
            tbl[key] = english[value]
        elseif type(value) == "table" and depth < 3 then
            RestoreEnglish(value, english, depth + 1)
        end
    end
end

-- Called once the saved settings exist. English keeps the client's own names
-- (items, zones) that the game itself hands back in its language.
function GQ.ApplyLanguageSetting(settings)
    settingsKnown = true
    local wasActive = GQ.LocaleActive
    local id = WantLocale(settings)
    if id ~= "enUS" and id ~= "enGB" then
        if GQ.ActiveLocale ~= id or not GQ.LocaleActive then
            GQ.ActiveLocale = id
            GQ.LocaleActive = true
            GQ:LoadLocalePack()
        end
        return
    end
    GQ.ActiveLocale = "enUS"
    GQ.LocaleActive = false
    if not wasActive then
        return
    end
    for i = 1, #loadTimeTables do
        RestoreEnglish(loadTimeTables[i], loadTimeKeys, 1)
    end
end

GQ.LocaleText = {}
GQ.LocaleSentences = {}
GQ.LocaleRules = {}
GQ.LocaleObjectives = {}
GQ.LocaleNames = { zone = {}, npc = {}, quest = {}, item = {}, object = {}, enchant = {}, faction = {} }

-- Zone names come from the language pack when one is selected. The client
-- name, through the ids in Locales/Zones.lua, is only the fallback, and that
-- follows the installed client (positive = area id, negative = uiMapId).
local zoneCache = {}
local function ClientZoneName(name)
    local cached = zoneCache[name]
    if cached ~= nil then
        return cached or nil
    end
    local id = GQ.ZONE_IDS and GQ.ZONE_IDS[name]
    local found
    if id and id < 0 and C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(-id)
        found = info and info.name
    elseif id and C_Map and C_Map.GetAreaInfo then
        found = C_Map.GetAreaInfo(id)
    end
    if type(found) ~= "string" or found == "" then
        found = nil
    end
    zoneCache[name] = found or false
    return found
end

-- Returns the translation, or nil when this kind has none.
local function Lookup(kind, name)
    local names = GQ.LocaleNames[kind]
    local translated = names and names[name]
    if translated then
        return translated
    end
    if kind == "zone" then
        return ClientZoneName(name)
    end
    return nil
end
GQ.LocaleLookup = Lookup

function GQ.TN(kind, name)
    if type(name) ~= "string" or not GQ.LocaleActive then
        return name
    end
    return Lookup(kind, name) or name
end

-- The client's name for a data name, whatever the display language: for
-- comparing with names the client reports (map names, faction list).
function GQ.TClient(kind, name)
    if type(name) ~= "string" or ENGLISH then
        return name
    end
    return Lookup(kind, name) or name
end

-- A name of unknown kind, as found inside a sentence.
local ANY_ORDER = { "npc", "zone", "quest", "item", "object" }
function GQ.TAny(name)
    if type(name) ~= "string" or not GQ.LocaleActive then
        return name
    end
    for i = 1, #ANY_ORDER do
        local translated = Lookup(ANY_ORDER[i], name)
        if translated then
            return translated
        end
    end
    return name
end

-- A label that may be UI text or a place name (filter rows mix both).
function GQ.TX(text)
    if type(text) ~= "string" then
        return text
    end
    local translated = GQ.L[text]
    if translated ~= text then
        return translated
    end
    return GQ.TN("zone", text)
end

-- Search key: lower case with accents dropped, so "epee" finds "Épée".
-- string.lower only folds ASCII.
local FOLD = {}
for plain, letters in pairs({
    a = "àâäáãåÀÂÄÁÃÅ", c = "çÇ", e = "éèêëÉÈÊË", i = "îïíìÎÏÍÌ", n = "ñÑ",
    o = "ôöóòõÔÖÓÒÕ", u = "ùûüúÙÛÜÚ", y = "ÿýŸÝ", oe = "œŒ", ae = "æÆ",
}) do
    for letter in letters:gmatch("[\192-\255][\128-\191]*") do
        FOLD[letter] = plain
    end
end
function GQ.FoldText(text)
    return (string.lower(text):gsub("[\192-\255][\128-\191]*", FOLD))
end

local function TranslateSentence(sentence)
    local exact = GQ.LocaleSentences[sentence]
    if exact then
        return exact
    end
    local rules = GQ.LocaleRules
    for i = 1, #rules do
        local rule = rules[i]
        local captures = { sentence:match(rule[1]) }
        if captures[1] ~= nil then
            local translated = rule[2](unpack(captures))
            if translated then
                return translated
            end
        end
    end
    return sentence
end
GQ.LocaleTranslateSentence = TranslateSentence

-- A period after one letter is an initial (S. J. Erlgadin), not a sentence end.
local function InitialPeriod(line, dotAt)
    if line:sub(dotAt, dotAt) ~= "." then
        return false
    end
    if not line:sub(dotAt - 1, dotAt - 1):match("%a") then
        return false
    end
    local before = dotAt > 1 and line:sub(dotAt - 2, dotAt - 2) or ""
    return before == "" or not before:match("%a")
end

-- Quest names are wrapped in quotes. "Wanted! Otto" is one name, not two sentences.
local function InsideQuotes(line, pos)
    local singles, doubles = 0, 0
    for i = 1, pos - 1 do
        local ch = line:sub(i, i)
        if ch == "'" then
            local prev = i > 1 and line:sub(i - 1, i - 1) or ""
            local nxt = line:sub(i + 1, i + 1)
            if not (prev:match("%a") and nxt:match("%a")) then
                singles = singles + 1
            end
        elseif ch == '"' then
            doubles = doubles + 1
        end
    end
    return (singles % 2 == 1) or (doubles % 2 == 1)
end

-- One line: split after . ! ? when a space and a capital, quote or bracket follow.
local function TranslateLine(line)
    if line == "" then
        return line
    end
    local out = {}
    local start = 1
    local len = #line
    while start <= len do
        local stop, nextStart
        local search = start
        while true do
            local s, e = line:find("[%.!?]+['\"]?%s+", search)
            if not s then
                break
            end
            if InitialPeriod(line, s) or InsideQuotes(line, s) then
                search = e + 1
            else
                local following = line:sub(e + 1, e + 1)
                if following:match("[%u%(\"'%d%+]") then
                    stop, nextStart = e, e + 1
                    break
                end
                search = e + 1
            end
        end
        if not stop then
            out[#out + 1] = TranslateSentence(line:sub(start))
            break
        end
        local chunk = line:sub(start, stop)
        local body, space = chunk:match("^(.-)(%s+)$")
        out[#out + 1] = TranslateSentence(body) .. space
        start = nextStart
    end
    return table.concat(out)
end

local cache = {}
local translating = 0
function GQ.TL(text)
    if type(text) ~= "string" or not GQ.LocaleActive or text == "" then
        return text
    end
    if translating > 3 then
        return text
    end
    local whole = GQ.LocaleText[text]
    if whole then
        return whole
    end
    local cached = cache[text]
    if cached then
        return cached
    end
    local source = text
    translating = translating + 1
    -- A quest objective is the tail of the text and is translated whole.
    local objectiveTail
    local at = text:find("Objective: ", 1, true)
    if at then
        local objective = GQ.LocaleObjectives[text:sub(at + 11)]
        if objective then
            objectiveTail = (GQ.LocaleObjectiveLabel or "Objective: ") .. objective
            text = text:sub(1, at - 1):gsub("%s+$", "")
        end
    end
    local lines = {}
    for line, sep in text:gmatch("([^\n]*)(\n?)") do
        if line == "" and sep == "" then
            break
        end
        lines[#lines + 1] = TranslateLine(line) .. sep
    end
    local translated = table.concat(lines)
    if objectiveTail then
        translated = translated ~= "" and (translated .. " " .. objectiveTail) or objectiveTail
    end
    cache[source] = translated
    translating = translating - 1
    return translated
end
