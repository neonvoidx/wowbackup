-- core.lua: WarGames+
local ADDON_NAME = ...

-- Localization.lua bootstraps _G["WargamesPlus"] and sets WG.L
local WargamesPlus = _G["WargamesPlus"] or {}
_G["WargamesPlus"] = WargamesPlus
local L = WargamesPlus.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

-- uikit.lua (loads immediately before this file) owns the theme system and flat-style
-- helpers; import them as locals so the rest of this file can keep using bare names.
local ApplyModernStyle = WargamesPlus.ApplyModernStyle
local StyleButton      = WargamesPlus.StyleButton
local StyleInput       = WargamesPlus.StyleInput
local StyleDropdown    = WargamesPlus.StyleDropdown
local StyleScrollBar   = WargamesPlus.StyleScrollBar
local ADDON_FONT       = WargamesPlus.ADDON_FONT
local FLAT_BACKDROP    = WargamesPlus.FLAT_BACKDROP
local THEMES           = WargamesPlus.THEMES
local COLOR_GROUPS     = WargamesPlus.COLOR_GROUPS
local ApplyTheme       = WargamesPlus.ApplyTheme
local ApplyCardStyle   = WargamesPlus.ApplyCardStyle
local CreateWindowChrome     = WargamesPlus.CreateWindowChrome
local CreateSegmentedControl = WargamesPlus.CreateSegmentedControl
local CreateToggleSwitch     = WargamesPlus.CreateToggleSwitch
local CreateMapTile          = WargamesPlus.CreateMapTile
local AddPlaceholder         = WargamesPlus.AddPlaceholder
local HexToRGB               = WargamesPlus.HexToRGB
-- Same registry table uikit.lua's ApplyTheme sweeps over — shared by reference so the
-- many inline `table.insert(themedElements, ...)` call-sites below keep working as-is.
local themedElements   = WargamesPlus._themedElements
-- Transparent read-through proxy: always reflects whatever uikit.lua's ApplyTheme last
-- set as the active theme, so every `activeTheme.field` read below (175 call-sites)
-- stays correct across theme switches without changing any of those call-sites.
local activeTheme = setmetatable({}, { __index = function(_, k) return WargamesPlus.GetActiveTheme()[k] end })

-- 0. Database Safety
-- Single source of truth for WG_History defaults, called both here (file-load time) and
-- again from the ADDON_LOADED handler below (belt-and-suspenders in case something else
-- touches WG_History between file-load and ADDON_LOADED firing for this addon). The two
-- call sites previously duplicated this list by hand and had drifted out of sync on
-- mapOrder's shape ({} vs {ARENA={},BG={},BLITZ={}}) — this is now one function.
local function InitDefaults()
    WG_History = WG_History or {}
    if not WG_History.favorites then WG_History.favorites = {} end
    if not WG_History.opponents then WG_History.opponents = {} end
    if not WG_History.theme then WG_History.theme = "Horde" end
    if not WG_History.records then WG_History.records = {} end
    if not WG_History.excluded then WG_History.excluded = {} end
    if not WG_History.favFriends then WG_History.favFriends = {} end
    if not WG_History.mapOrder then WG_History.mapOrder = { ARENA = {}, BG = {}, BLITZ = {} } end
    if not WG_History.mapOrder.ARENA then WG_History.mapOrder.ARENA = {} end
    if not WG_History.mapOrder.BG then WG_History.mapOrder.BG = {} end
    if not WG_History.mapOrder.BLITZ then WG_History.mapOrder.BLITZ = {} end
    if WG_History.tournamentRules == nil then WG_History.tournamentRules = false end
    if WG_History.spectatorMode == nil then WG_History.spectatorMode = false end
    if not WG_History.customTheme then WG_History.customTheme = { baseTheme = "Midnight", overrides = {} } end
    if WG_History.compactMode == nil then WG_History.compactMode = false end
    if WG_History.bansPerPlayer == nil then WG_History.bansPerPlayer = 2 end
    if not WG_History.vetoHistory then WG_History.vetoHistory = {} end
    if not WG_History.sessionOverride then WG_History.sessionOverride = { active = false, startTime = 0 } end
    if WG_History.uiScale == nil then WG_History.uiScale = 110 end
    if WG_History.font == nil then WG_History.font = "Friz Quadrata" end
    if WG_History.vetoFormat == nil then WG_History.vetoFormat = "Bo1" end
    if WG_History.vetoTurnTimer == nil then WG_History.vetoTurnTimer = 30 end
    if not WG_History.slaughterHistory then WG_History.slaughterHistory = {} end
    if WG_History.slaughterTurnTimer == nil then WG_History.slaughterTurnTimer = 30 end
    if not WG_History.dockMode then WG_History.dockMode = {} end
    if WG_History.lfgEnabled == nil then WG_History.lfgEnabled = true end
    if not WG_History.lfgHistory then WG_History.lfgHistory = {} end
    if not WG_History.lfgIgnore then WG_History.lfgIgnore = {} end
    if WG_History.lfgCommunityHintDismissed == nil then WG_History.lfgCommunityHintDismissed = false end
    if WG_History.lfgCommunityHintShown == nil then WG_History.lfgCommunityHintShown = false end
    if WG_History.showMinimap == nil then WG_History.showMinimap = true end
    if WG_History.showMatchChat == nil then WG_History.showMatchChat = true end
    if WG_History.showNemesisChat == nil then WG_History.showNemesisChat = true end
    if WG_History.trackMatches == nil then WG_History.trackMatches = true end
    if WG_History.maxRecords == nil then WG_History.maxRecords = 200 end
    -- compactPos is nil or a table, no init needed
end
InitDefaults()

-- ---------- 1. DATA & STYLES ----------
local ARENA_LIST = {
    "Random Map",
    "Nagrand Arena", "Blade's Edge Arena", "Ruins of Lordaeron", "Dalaran Arena",
    "Ring of Valor", "Tol'viron Arena", "Tiger's Peak", "Ashamane's Fall",
    "Black Rook Hold Arena", "Hook Point", "Mugambala", "Maldraxxus Coliseum",
    "Nokhudon Proving Grounds", "The Robodrome", "Empyrean Domain",
    "Enigma Crucible", "Cage of Carnage"
}

local BG_LIST = {
    "Random Map",
    "Warsong Gulch", "Twin Peaks", "Arathi Basin", "The Battle for Gilneas",
    "Eye of the Storm", "Temple of Kotmogu", "Silvershard Mines",
    "Seething Shore", "Deephaul Ravine"
}

local BLITZ_LIST = {
    "Random Map",
    "Warsong Gulch", "Twin Peaks", "Battle for Gilneas",
    "Silvershard Mines", "Temple of Kotmogu", "Eye of the Storm",
    "Arathi Basin", "Deepwind Gorge", "Deephaul Ravine"
}

-- API lookup table (maps display names → API keywords for StartWarGameByName etc.)
local MAP_DATA = {
    -- Arenas
    ["Nagrand Arena"]            = {value = "nagrand",    apiName = "Nagrand Arena"},
    ["Blade's Edge Arena"]       = {value = "blade's",   apiName = "Blade's Edge Arena"},
    ["Ruins of Lordaeron"]       = {value = "lordaeron",  apiName = "Ruins of Lordaeron"},
    ["Dalaran Arena"]            = {value = "dalaran",    apiName = "Dalaran Sewers"},
    ["Ring of Valor"]            = {value = "valor",      apiName = "Ring of Valor"},
    ["Tol'viron Arena"]          = {value = "tol'viron",  apiName = "Tol'Viron Arena"},
    ["Tiger's Peak"]             = {value = "tiger's",    apiName = "The Tiger's Peak"},
    ["Ashamane's Fall"]          = {value = "ashamane's", apiName = "Ashamane's Fall"},
    ["Black Rook Hold Arena"]    = {value = "black",      apiName = "Black Rook Hold Arena"},
    ["Hook Point"]               = {value = "point",      apiName = "Hook Point"},
    ["Mugambala"]                = {value = "mugambala",  apiName = "Mugambala"},
    ["Maldraxxus Coliseum"]      = {value = "maldraxxus", apiName = "Maldraxxus Coliseum"},
    ["Nokhudon Proving Grounds"] = {value = "nokhudon",   apiName = "Nokhudon Proving Grounds"},
    ["The Robodrome"]            = {value = "robodrome",  apiName = "The Robodrome"},
    ["Empyrean Domain"]          = {value = "empyrean",   apiName = "Empyrean Domain"},
    ["Enigma Crucible"]          = {value = "enigma",     apiName = "Enigma Crucible"},
    ["Cage of Carnage"]          = {value = "carnage",    apiName = "Cage of Carnage"},
    -- Battlegrounds
    ["Warsong Gulch"]            = {value = "warsong",     apiName = "Warsong Gulch"},
    ["Twin Peaks"]               = {value = "peaks",       apiName = "Twin Peaks"},
    ["Arathi Basin"]             = {value = "arathi",      apiName = "Arathi Basin"},
    ["The Battle for Gilneas"]   = {value = "gilneas",     apiName = "The Battle for Gilneas"},
    ["Battle for Gilneas"]       = {value = "gilneas",     apiName = "Battle for Gilneas"},
    ["Eye of the Storm"]         = {value = "eye",         apiName = "Eye of the Storm"},
    ["Temple of Kotmogu"]        = {value = "kotmogu",     apiName = "Temple of Kotmogu"},
    ["Silvershard Mines"]        = {value = "silvershard", apiName = "Silvershard Mines"},
    ["Seething Shore"]           = {value = "seething",    apiName = "Seething Shore"},
    ["Deephaul Ravine"]          = {value = "deephaul",    apiName = "Deephaul Ravine"},
    ["Deepwind Gorge"]           = {value = "deepwind",    apiName = "Deepwind Gorge"},
}

local GAME_MODES = {
    ARENA_2V2    = {tab = "ARENA", mapMode = "ARENA", bracket = 2, apiType = "standard",    label = "2v2"},
    ARENA_3V3    = {tab = "ARENA", mapMode = "ARENA", bracket = 3, apiType = "standard",    label = "3v3"},
    ARENA_5V5    = {tab = "ARENA", mapMode = "ARENA", bracket = 5, apiType = "standard",    label = "5v5"},
    SOLO_SHUFFLE = {tab = "ARENA", mapMode = "ARENA", bracket = 0, apiType = "soloShuffle", label = "Shuffle"},
    BG           = {tab = "BG",    mapMode = "BG",    bracket = 0, apiType = "standard",    label = "Normal"},
    BLITZ        = {tab = "BG",    mapMode = "BLITZ", bracket = 0, apiType = "blitz",       label = "Blitz"},
}

local function GetSortedMapList(mode)
    local sourceList
    if mode == "BLITZ" then sourceList = BLITZ_LIST
    elseif mode == "BG" then sourceList = BG_LIST
    else sourceList = ARENA_LIST end
    local savedOrder = WG_History.mapOrder[mode]

    -- Build set of valid map names (excluding "Random Map")
    local validSet = {}
    for _, name in ipairs(sourceList) do
        if name ~= "Random Map" then validSet[name] = true end
    end

    -- Start from saved order, keeping only maps that still exist
    local ordered = {}
    local seen = {}
    if savedOrder and #savedOrder > 0 then
        for _, name in ipairs(savedOrder) do
            if validSet[name] and not seen[name] then
                table.insert(ordered, name)
                seen[name] = true
            end
        end
    end

    -- Append any new maps not in saved order
    for _, name in ipairs(sourceList) do
        if name ~= "Random Map" and not seen[name] then
            table.insert(ordered, name)
        end
    end

    -- Stable partition: favorites first, then non-favorites
    local favs, rest = {}, {}
    for _, name in ipairs(ordered) do
        if WG_History.favorites[name] then
            table.insert(favs, name)
        else
            table.insert(rest, name)
        end
    end

    local result = {"Random Map"}
    for _, name in ipairs(favs) do table.insert(result, name) end
    for _, name in ipairs(rest) do table.insert(result, name) end
    return result
end

local MAP_TEXTURES = {
    -- 1. MODERN MAPS (Using Widescreen File IDs to prevent green boxes)
    ["Nokhudon Proving Grounds"] = "Interface\\AddOns\\Wargames\\media\\maps\\Nokhudon.blp", -- Wide
    ["Maldraxxus Coliseum"]      = "Interface\\AddOns\\Wargames\\media\\maps\\Maldraxxus.blp", -- Wide
    ["Mugambala"]                = "Interface\\AddOns\\Wargames\\media\\maps\\Mugambala.blp", -- Wide
    ["Hook Point"]               = "Interface\\AddOns\\Wargames\\media\\maps\\Hookpoint.blp", -- Wide
    ["Tiger's Peak"]             = "Interface\\AddOns\\Wargames\\media\\maps\\Tigerspeek.blp",  -- Wide
    ["Seething Shore"]           = "Interface\\AddOns\\Wargames\\media\\maps\\Seething.blp", -- Wide
    ["Ashamane's Fall"]          = "Interface\\AddOns\\Wargames\\media\\maps\\Ashamanes.blp", -- (Standard usually works, but this is the ID)
    ["Black Rook Hold Arena"]    = "Interface\\AddOns\\Wargames\\media\\maps\\Blackrook.blp", -- (Standard)
    ["The Robodrome"]            = "Interface\\AddOns\\Wargames\\media\\maps\\Robodrome.blp",
    ["Empyrean Domain"]          = "Interface\\AddOns\\Wargames\\media\\maps\\Empyrean.blp",
    ["Enigma Crucible"]          = "Interface\\AddOns\\Wargames\\media\\maps\\Enigma.blp",
    ["Cage of Carnage"]          = "Interface\\AddOns\\Wargames\\media\\maps\\cage.blp",

    -- 2. SPECIAL CASES (Internal names differ from map names)
    ["Ring of Valor"]            = "Interface\\AddOns\\Wargames\\media\\maps\\Ring.blp",  -- "Orgrimmar Arena"
    ["Deephaul Ravine"]          = "Interface\\AddOns\\Wargames\\media\\maps\\Deephaul.blp", -- TWW Map (Try this ID, or 5924295 for Wide)
    ["Deepwind Gorge"]           = "Interface\\AddOns\\Wargames\\media\\maps\\Deepwind.blp",

    -- 3. CLASSIC MAPS (Text paths still work reliably for these)
    ["Nagrand Arena"]           = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenNagrandArenaBattlegrounds",
    ["Blade's Edge Arena"]      = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenBladesEdgeArena",
    ["Ruins of Lordaeron"]      = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenRuinsofLordaeronBattlegrounds",
    ["Dalaran Arena"]           = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenDalaranSewersArena",
    ["Tol'viron Arena"]         = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenTolvirArena",

    -- 4. BATTLEGROUNDS
    ["Warsong Gulch"]           = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenWarsongGulch",
    ["Twin Peaks"]              = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenTwinPeaksBG",
    ["Arathi Basin"]            = "Interface\\GLUES\\LOADINGSCREENS\\LoadscreenArathiBasin",
    ["The Battle for Gilneas"]  = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenGilneasBG2",
    ["Battle for Gilneas"]      = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenGilneasBG2",
    ["Eye of the Storm"]        = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenNetherBattlegrounds",
    ["Temple of Kotmogu"]       = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenValleyofPower",
    ["Silvershard Mines"]       = "Interface\\GLUES\\LOADINGSCREENS\\LoadScreenSilvershardMines",
}

local function FavIcon()
    return CreateAtlasMarkup("PetJournal-FavoritesIcon", 14, 14, 0, -1) .. " "
end

-- CRITICAL: Define F here so it is visible to ApplyTheme
local F = CreateFrame("Frame", "WG_CoreFrame", UIParent)
local CreateUI -- Forward declaration so MinimapButton can see it

-- Helper: check if a player has been detected with the addon (handles name/name-realm keys)
local function HasAddonDetected(name)
    if not name or not WargamesPlus.addonUsers then return nil end
    local ts = WargamesPlus.addonUsers[name]
    if ts and time() - ts < 3600 then return ts end
    -- Try short name (strip realm)
    local short = name:match("^([^-]+)")
    if short and short ~= name then
        ts = WargamesPlus.addonUsers[short]
        if ts and time() - ts < 3600 then return ts end
    end
    -- Try matching any key that starts with the short name
    for k, v in pairs(WargamesPlus.addonUsers) do
        local kShort = k:match("^([^-]+)")
        if kShort == (short or name) and time() - v < 3600 then return v end
    end
    return nil
end
WargamesPlus.HasAddonDetected = HasAddonDetected
-- ---------- SHARED NAMESPACE EXPORTS (map/mode data owned by core.lua) ----------
WargamesPlus.GAME_MODES        = GAME_MODES
WargamesPlus.MAP_DATA          = MAP_DATA
WargamesPlus.ARENA_LIST        = ARENA_LIST
WargamesPlus.BG_LIST           = BG_LIST
WargamesPlus.BLITZ_LIST        = BLITZ_LIST
WargamesPlus.GetSortedMapList  = GetSortedMapList
WargamesPlus.MAP_TEXTURES      = MAP_TEXTURES

-- ---------- SHARED RESOLVE / CHALLENGE HELPERS ----------
function WargamesPlus.ResolveBTagToCharName(bTag)
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.battleTag == bTag then
            local ga = accountInfo.gameAccountInfo
            if ga and ga.characterName and ga.isOnline then
                local name = ga.characterName
                local r = ga.realmName or ""
                if r ~= "" then name = name .. "-" .. r:gsub("%s+", "") end
                return name
            end
        end
    end
    return nil
end

function WargamesPlus.ResolveCharToBTag(charName)
    if not charName or charName == "" then return nil end
    if charName:find("#") then return charName end
    local short = charName:match("^([^-]+)")
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local ga = accountInfo.gameAccountInfo
            if ga.characterName and ga.isOnline then
                if ga.characterName == charName or ga.characterName == short then
                    return accountInfo.battleTag
                end
                local r = ga.realmName or ""
                if r ~= "" then
                    local fullName = ga.characterName .. "-" .. r:gsub("%s+", "")
                    if fullName == charName then return accountInfo.battleTag end
                end
            end
        end
    end
    return nil
end

-- Resolve a character name or BattleTag to the BNet account name (used by StartWarGameByName)
function WargamesPlus.ResolveToAccountName(nameOrTag)
    if not nameOrTag or nameOrTag == "" then return nil end
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo then
            -- Match by BattleTag
            if accountInfo.battleTag == nameOrTag then
                return accountInfo.accountName
            end
            -- Match by character name
            if accountInfo.gameAccountInfo then
                local ga = accountInfo.gameAccountInfo
                if ga.characterName and ga.isOnline then
                    local short = nameOrTag:match("^([^-#]+)")
                    if ga.characterName == nameOrTag or ga.characterName == short then
                        return accountInfo.accountName
                    end
                end
            end
        end
    end
    return nil
end

function WargamesPlus.ResolveBNetID(nameOrTag)
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo then
            if accountInfo.battleTag == nameOrTag or accountInfo.accountName == nameOrTag then
                return accountInfo.bnetAccountID
            end
            if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName == nameOrTag then
                return accountInfo.bnetAccountID
            end
        end
    end
    return nil
end

-- params = { target, gameMode, mapName, tournamentRules, spectator, leader1, leader2 }
function WargamesPlus.SendChallengeByParams(params)
    local gm = GAME_MODES[params.gameMode]
    if not gm then return end

    local mapMode = gm.mapMode
    local mapName = params.mapName or "Random Map"
    local theme = activeTheme

    -- Handle random map
    if mapName == "Random Map" then
        local sourceList
        if mapMode == "BLITZ" then sourceList = BLITZ_LIST
        elseif mapMode == "BG" then sourceList = BG_LIST
        else sourceList = ARENA_LIST end
        local pool = {}
        for j = 2, #sourceList do
            if not WG_History.excluded[sourceList[j]] then
                table.insert(pool, sourceList[j])
            end
        end
        if #pool == 0 then
            print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_ALL_MAPS_EXCLUDED"])
            for j = 2, #sourceList do table.insert(pool, sourceList[j]) end
        end
        mapName = pool[math.random(1, #pool)]
        print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_RANDOM_SELECTED"], mapName))
    end

    local mapInfo = MAP_DATA[mapName]
    local mapKeyword = mapInfo and mapInfo.value or mapName
    local mapApiName = mapInfo and mapInfo.apiName or mapName
    local tournamentRules = params.tournamentRules
    local tournamentStr = tournamentRules and "1" or "0"

    if params.spectator then
        local target1 = params.leader1 or ""
        local target2 = params.leader2 or ""
        if target1 == "" or target2 == "" then
            print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_BOTH_LEADERS_REQUIRED"])
            return
        end
        local bnetID1 = WargamesPlus.ResolveBNetID(target1)
        local bnetID2 = WargamesPlus.ResolveBNetID(target2)
        if not bnetID1 then
            print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CANNOT_RESOLVE_BNET"], target1))
            return
        end
        if not bnetID2 then
            print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CANNOT_RESOLVE_BNET"], target2))
            return
        end
        if gm.apiType == "soloShuffle" then
            if StartSpectatorSoloShuffleWarGame then StartSpectatorSoloShuffleWarGame(bnetID1, bnetID2, mapApiName, tournamentRules) end
        elseif gm.apiType == "blitz" then
            if C_PvP and C_PvP.StartSpectatorSoloRBGWarGame then C_PvP.StartSpectatorSoloRBGWarGame(bnetID1, bnetID2, mapApiName, tournamentRules) end
        else
            if StartSpectatorWarGame then StartSpectatorWarGame(bnetID1, bnetID2, gm.bracket, mapApiName, tournamentRules) end
        end
        print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_SPECTATING"], target1, target2, mapName))
    else
        local t = params.target or ""
        if t == "" then return end
        local displayName = t
        if t:find("#") then
            local resolved = WargamesPlus.ResolveBTagToCharName(t)
            if resolved then displayName = resolved end
        end
        for i, v in ipairs(WG_History.opponents or {}) do
            if v == displayName then table.remove(WG_History.opponents, i) break end
        end
        table.insert(WG_History.opponents, 1, displayName)
        if #WG_History.opponents > 10 then table.remove(WG_History.opponents) end
        WargamesPlus.lastChallenge = {
            opponent = displayName, map = mapName,
            mode = gm.tab, matchSize = params.gameMode,
            timestamp = time(), initiator = UnitName("player"),
        }
        WG_History.lastChallenge = WargamesPlus.lastChallenge
        if WargamesPlus.BroadcastChallenge then WargamesPlus.BroadcastChallenge() end
        local challengeTarget = WargamesPlus.ResolveToAccountName(t) or displayName
        local cmdStr = challengeTarget .. " " .. mapKeyword .. " " .. tournamentStr
        if gm.apiType == "soloShuffle" then
            if StartSoloShuffleWarGameByName then StartSoloShuffleWarGameByName(cmdStr) end
        elseif gm.apiType == "blitz" then
            if C_PvP and C_PvP.StartSoloRBGWarGameByName then C_PvP.StartSoloRBGWarGameByName(cmdStr) end
        else
            if StartWarGameByName then StartWarGameByName(cmdStr) end
        end
        print("|cff" .. theme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CHALLENGE_SENT"], displayName, mapName))
    end
end

local function GetFormattedName(name, realm)
    if not name or name == "" then return nil end
    if realm and realm ~= "" then return name .. "-" .. realm:gsub("%s+", "") end
    return name
end

local function CreateMinimapButton()
    if F.minimapBtn then return end

    local btn = CreateFrame("Button", "WG_MinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetFixedFrameStrata(true)
    btn:SetFixedFrameLevel(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\AddOns\\Wargames\\media\\wglogo.blp")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Migrate old absolute-position format to Minimap-relative offsets
    if WG_History.minimapPos then
        local pos = WG_History.minimapPos
        if math.abs(pos.x) > 500 or math.abs(pos.y) > 500 then
            WG_History.minimapPos = nil
        end
    end

    -- Restore saved offset from Minimap center, or default
    if WG_History.minimapPos then
        btn:SetPoint("CENTER", Minimap, "CENTER", WG_History.minimapPos.x, WG_History.minimapPos.y)
    else
        btn:SetPoint("CENTER", Minimap, "CENTER", -80, 0)
    end

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local mx, my = Minimap:GetCenter()
            local dx, dy = cx - mx, cy - my
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", dx, dy)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        local bx, by = self:GetCenter()
        local mx, my = Minimap:GetCenter()
        local dx, dy = bx - mx, by - my
        WG_History.minimapPos = { x = dx, y = dy }
    end)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if WargamesPlus.ToggleAdvancedStats then WargamesPlus.ToggleAdvancedStats() end
            return
        end
        if IsControlKeyDown() then
            if WargamesPlus.ToggleSlaughterHouse then WargamesPlus.ToggleSlaughterHouse() end
            return
        end
        if IsShiftKeyDown() then
            if WargamesPlus.ToggleDock then WargamesPlus.ToggleDock() end
            return
        end
        -- Delegate to slash command which handles compact mode properly
        SlashCmdList["WARGAMESPLUS"]()
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["ADDON_TITLE_TOOLTIP"])
        GameTooltip:AddLine("Right-Click: Advanced Stats", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Shift-Click: Dock Mode", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Ctrl-Click: Slaughterhouse", 0.7, 0.7, 0.7)

        -- Today's W-L record
        local records = WG_History.records
        if records and #records > 0 then
            local now = time()
            local today = now - (now % 86400)  -- midnight UTC
            local w, l, d = 0, 0, 0
            for i = 1, #records do
                local rec = records[i]
                if rec.timestamp < today then break end  -- records are newest-first
                if rec.result == "win" then w = w + 1
                elseif rec.result == "loss" then l = l + 1
                else d = d + 1 end
            end
            if w + l + d > 0 then
                local line = w .. "W - " .. l .. "L"
                if d > 0 then line = line .. " - " .. d .. "D" end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["TODAY_RECORD"], line), 1, 0.82, 0, false)
            end
        end

        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    F.minimapBtn = btn
end

F:RegisterEvent("ADDON_LOADED")
F:RegisterEvent("PLAYER_LOGIN")
F:RegisterEvent("PLAYER_REGEN_DISABLED")
F:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Combat hide/restore — tracks which WG+ frames were visible before combat
local combatHiddenFrames = {}

-- ---------- 2. CONTEXT MENU ----------
local function OpenWarGamesMenu(owner, friendData)
    if not friendData then return end
    
    local charName = GetFormattedName(friendData.targetName, friendData.realm) or friendData.targetName
    local title = charName or friendData.battleTag

    MenuUtil.CreateContextMenu(owner, function(owner, rootDescription)
        rootDescription:CreateTitle("|cff" .. activeTheme.inlineAccent .. title .. "|r")
        
        if charName then
            rootDescription:CreateButton(L["WHISPER_CHARACTER"], function() ChatFrame_OpenChat("/w " .. charName .. " ") end)
            rootDescription:CreateButton(L["INVITE_CHARACTER"], function() C_PartyInfo.InviteUnit(charName) end)
        end
        
        local favKey = friendData.targetName
        local isFav = WG_History.favFriends[favKey]
        rootDescription:CreateButton(isFav and L["UNFAVORITE"] or L["FAVORITE"], function()
            WG_History.favFriends[favKey] = not isFav or nil
            if F.ui then F.ui:Refresh() end
        end)

        if charName and WargamesPlus.ShowProfileCard then
            rootDescription:CreateButton(L["VIEW_PROFILE"], function()
                WargamesPlus.ShowProfileCard(charName, owner)
            end)
        end

        rootDescription:CreateDivider()

        if charName then
            local fillName = friendData.battleTag or friendData.whisperName or charName
            rootDescription:CreateButton(L["SEND_CHALLENGE_MENU"], function()
                if F.ui and fillName then
                    F.ui.editBox:SetText(fillName)
                    F.ui.challengeBtn:Click()
                end
            end)

            -- Veto / Ready Check (need the opponent to have the addon)
            if HasAddonDetected(charName) or HasAddonDetected(friendData.whisperName) then
                rootDescription:CreateButton(L["VETO_START"], function()
                    if F.ui then
                        F.ui.editBox:SetText(friendData.whisperName or charName)
                        if F.ui.vetoBtn then F.ui.vetoBtn:Click() end
                    end
                end)
                rootDescription:CreateButton(L["RC_START"], function()
                    if F.ui then
                        F.ui.editBox:SetText(friendData.whisperName or charName)
                        if F.ui.rcBtn then F.ui.rcBtn:Click() end
                    end
                end)
            end
        end
    end)
end

-- Reorder a map within a mode's custom order (right-click menu Move to Top/Up/Down).
-- Operates on WG_History.mapOrder[mode] (excludes "Random Map", same as the old
-- drag path); seeds it from the current sorted list on first use. Favorites are
-- still partitioned to the front by GetSortedMapList afterward.
local function MoveMap(mode, name, dir)
    if not name or name == "Random Map" then return end
    local base = WG_History.mapOrder[mode]
    if not base or #base == 0 then
        base = {}
        for _, n in ipairs(GetSortedMapList(mode)) do
            if n ~= "Random Map" then table.insert(base, n) end
        end
    end

    local idx
    for i, n in ipairs(base) do if n == name then idx = i; break end end
    if not idx then return end

    if dir == "top" then
        table.remove(base, idx)
        table.insert(base, 1, name)
    elseif dir == "up" and idx > 1 then
        base[idx], base[idx - 1] = base[idx - 1], base[idx]
    elseif dir == "down" and idx < #base then
        base[idx], base[idx + 1] = base[idx + 1], base[idx]
    end

    WG_History.mapOrder[mode] = base
    if F.ui then F.ui:RefreshMaps() end
end

-- ---------- MAP CONTEXT MENU ----------
local function OpenMapContextMenu(owner, mapName, mapMode)
    if not mapName or mapName == "Random Map" then return end

    MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
        rootDescription:CreateTitle("|cff" .. activeTheme.inlineAccent .. mapName .. "|r")

        local isFav = WG_History.favorites[mapName]
        rootDescription:CreateButton(isFav and L["UNFAVORITE"] or L["FAVORITE"], function()
            WG_History.favorites[mapName] = not isFav or nil
            if F.ui then F.ui:RefreshMaps() end
        end)

        local isExcluded = WG_History.excluded[mapName]
        rootDescription:CreateButton(isExcluded and L["INCLUDE_IN_RANDOM"] or L["EXCLUDE_FROM_RANDOM"], function()
            WG_History.excluded[mapName] = not isExcluded or nil
            if F.ui then F.ui:RefreshMaps() end
        end)

        if mapMode then
            rootDescription:CreateButton(L["MAP_MOVE_TOP"],  function() MoveMap(mapMode, mapName, "top")  end)
            rootDescription:CreateButton(L["MAP_MOVE_UP"],   function() MoveMap(mapMode, mapName, "up")   end)
            rootDescription:CreateButton(L["MAP_MOVE_DOWN"], function() MoveMap(mapMode, mapName, "down") end)
        end
    end)
end

-- ---------- 3. UI CONSTRUCTION ----------
CreateUI = function()
    if F.ui then return end

    local ui = CreateFrame("Frame", "WarGamesPlusUI", UIParent)
    ui:SetSize(900, 720)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:SetFrameStrata("DIALOG")
    ui:SetFrameLevel(50)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
    ApplyModernStyle(ui)
    WargamesPlus.ApplyUIScale(ui)

    -- Shared chrome (accent stripe + close); title text set below with per-span colors.
    local chrome = CreateWindowChrome(ui, { title = "", titleSize = 19, closeSize = 20 })

    ui.TitleText = chrome.title
    ui.TitleText:ClearAllPoints()
    ui.TitleText:SetPoint("TOPLEFT", 16, -12)
    -- "WAR" and the trailing "+" in the accent color, "GAMES" in the base title color.
    local function StyledTitle()
        local acc = activeTheme.inlineAccent
        return "|cff" .. acc .. "WAR|r" .. "GAMES" .. "|cff" .. acc .. "+|r"
    end
    ui.TitleText:SetText(StyledTitle())
    table.insert(themedElements, {ui.TitleText, function(fs) fs:SetText(StyledTitle()) end})

    local close = chrome.close

    -- --- TITLE BAR ACTION ROW ---
    -- No SVG/icon-texture support for custom glyphs in WoW, so these are short text
    -- buttons (matching how every other action in this addon has always worked)
    -- instead of the icon buttons in the approved design.
    local titleBarButtons = {}
    local function AddTitleBarButton(label, onClick)
        local btn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
        btn:SetHeight(22)
        btn:SetText(label)
        StyleButton(btn)
        btn:GetFontString():SetFont(ADDON_FONT, 10.5, "OUTLINE")
        btn:SetWidth(math.max(46, btn:GetFontString():GetStringWidth() + 18))
        btn:SetScript("OnClick", onClick)
        local prev = titleBarButtons[#titleBarButtons]
        if prev then
            btn:SetPoint("RIGHT", prev, "LEFT", -6, 0)
        else
            btn:SetPoint("RIGHT", close, "LEFT", -10, 0)
        end
        table.insert(titleBarButtons, btn)
        return btn
    end

    AddTitleBarButton(L["SIDEBAR_SETTINGS"], function()
        if WargamesPlus.ToggleSettingsFrame then WargamesPlus.ToggleSettingsFrame() end
    end)
    local lfgTitleBtn = AddTitleBarButton(L["LFG"], function()
        if WargamesPlus.ToggleLFGFrame then WargamesPlus.ToggleLFGFrame() end
    end)
    local lfgDot = lfgTitleBtn:CreateTexture(nil, "OVERLAY")
    lfgDot:SetSize(6, 6)
    lfgDot:SetPoint("TOPRIGHT", 2, 2)
    lfgDot:SetColorTexture(unpack(activeTheme.accent))
    table.insert(themedElements, {lfgDot, function(tex) tex:SetColorTexture(unpack(activeTheme.accent)) end})
    AddTitleBarButton(L["SIDEBAR_ADVANCED"], function()
        if WargamesPlus.ToggleAdvancedStats then WargamesPlus.ToggleAdvancedStats() end
    end)
    AddTitleBarButton(L["STATS"], function()
        if WargamesPlus.ToggleStatsFrame then WargamesPlus.ToggleStatsFrame() end
    end)

    -- --- BOTTOM UTILITY ROW ---
    local bottomRow = CreateFrame("Frame", nil, ui)
    bottomRow:SetPoint("BOTTOMLEFT", 16, 10)
    bottomRow:SetPoint("BOTTOMRIGHT", -16, 10)
    bottomRow:SetHeight(16)

    local function AddUtilityLink(parentAnchor, label, onClick)
        local btn = CreateFrame("Button", nil, bottomRow)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ADDON_FONT, 10.5)
        fs:SetText(label)
        fs:SetTextColor(unpack(activeTheme.footerColor))
        table.insert(themedElements, {fs, function(f2) f2:SetTextColor(unpack(activeTheme.footerColor)) end})
        btn:SetFontString(fs)
        btn:SetSize(fs:GetStringWidth(), 16)
        if parentAnchor then
            btn:SetPoint("LEFT", parentAnchor, "RIGHT", 16, 0)
        else
            btn:SetPoint("LEFT", bottomRow, "LEFT", 0, 0)
        end
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function() fs:SetTextColor(unpack(activeTheme.buttonText)) end)
        btn:SetScript("OnLeave", function() fs:SetTextColor(unpack(activeTheme.footerColor)) end)
        return btn
    end

    local compactLink = AddUtilityLink(nil, L["COMPACT"], function()
        WG_History.compactMode = true
        ui:Hide()
        F:CreateCompactFrame()
        if F.compactFrame then F.compactFrame:Show(); F:RefreshCompact() end
    end)
    local dockLink = AddUtilityLink(compactLink, L["DOCK_MODE"], function()
        ui:Hide()
        if WargamesPlus.ToggleDock then WargamesPlus.ToggleDock() end
    end)
    AddUtilityLink(dockLink, L["SIDEBAR_SLAUGHTER"], function()
        if WargamesPlus.ToggleSlaughterHouse then WargamesPlus.ToggleSlaughterHouse() end
    end)

    local footer = bottomRow:CreateFontString(nil, "OVERLAY")
    footer:SetFont(ADDON_FONT, 10)
    footer:SetPoint("RIGHT", bottomRow, "RIGHT", 0, 0)
    local function UpdateFooter()
        footer:SetText("By |cff" .. activeTheme.inlineAccent .. "Waxilliam|r")
    end
    UpdateFooter()
    footer:SetTextColor(unpack(activeTheme.footerColor))
    table.insert(themedElements, {footer, function(fs) fs:SetTextColor(unpack(activeTheme.footerColor)); UpdateFooter() end})

    -- --- SOCIAL PANEL ---
    local leftPanel = CreateFrame("Frame", nil, ui)
    leftPanel:SetWidth(280)
    leftPanel:SetPoint("TOPLEFT", 15, -75)
    leftPanel:SetPoint("BOTTOMLEFT", 15, 45)
    ui.leftPanel = leftPanel
    ApplyCardStyle(leftPanel)

    local socialLabel = leftPanel:CreateFontString(nil, "OVERLAY")
    socialLabel:SetFont(ADDON_FONT, 11, "OUTLINE")
    socialLabel:SetPoint("TOPLEFT", 11, -10)
    socialLabel:SetText(L["FRIENDS"])
    socialLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {socialLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})

    local refreshBtn = CreateFrame("Button", nil, leftPanel)
    local refreshFS = refreshBtn:CreateFontString(nil, "OVERLAY")
    refreshFS:SetFont(ADDON_FONT, 10.5)
    refreshFS:SetText(L["REFRESH"])
    refreshFS:SetTextColor(unpack(activeTheme.footerColor))
    table.insert(themedElements, {refreshFS, function(fs) fs:SetTextColor(unpack(activeTheme.footerColor)) end})
    refreshBtn:SetFontString(refreshFS)
    refreshBtn:SetSize(refreshFS:GetStringWidth(), 14)
    refreshBtn:SetPoint("TOPRIGHT", -10, -11)
    refreshBtn:SetScript("OnClick", function()
        C_FriendList.ShowFriends()
        ui:Refresh()
    end)
    refreshBtn:SetScript("OnEnter", function() refreshFS:SetTextColor(unpack(activeTheme.buttonText)) end)
    refreshBtn:SetScript("OnLeave", function() refreshFS:SetTextColor(unpack(activeTheme.footerColor)) end)

    local searchBox = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
    searchBox:SetSize(258, 24)
    searchBox:SetPoint("TOPLEFT", 11, -28)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        ui.filterText = self:GetText()
        ui:Refresh()
    end)
    StyleInput(searchBox)
    AddPlaceholder(searchBox, L["SEARCH_FRIENDS"])

    ui.filterMode = "all"
    local filterPills = CreateSegmentedControl(leftPanel, {
        {key = "all", label = L["FILTER_ALL"]},
        {key = "favorites", label = L["FILTER_FAVORITES"]},
        {key = "online", label = L["FILTER_ONLINE"]},
    }, {
        height = 18, fontSize = 10, padX = 8,
        onSelect = function(key) ui.filterMode = key; ui:Refresh() end,
    })
    filterPills:SetPoint("TOPLEFT", 11, -58)

    local scrollFrame = CreateFrame("ScrollFrame", "WG_RosterScroll", leftPanel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -82)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10)

    ui.rows = {}
    for i = 1, 18 do
        local row = CreateFrame("Button", nil, leftPanel)
        row:SetSize(250, 28)
        row:SetPoint("TOPLEFT", 5, -82 - ((i-1)*28))

        local hlTex = row:CreateTexture(nil, "HIGHLIGHT")
        hlTex:SetAllPoints()
        hlTex:SetColorTexture(unpack(activeTheme.rowHighlight))
        row._hlTex = hlTex
        table.insert(themedElements, {row, function(r) r._hlTex:SetColorTexture(unpack(activeTheme.rowHighlight)) end})

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameText:SetPoint("LEFT", 10, 0)
        row.nameText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetWordWrap(false)
        
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnEnter", function(self)
            if not self.friend then return end
            local oppS = ui.oppStatsLookup and ui.oppStatsLookup[self.friend.targetName]
            if not oppS or oppS.total == 0 then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.friend.targetName, 1, 1, 1)
            local pct = oppS.pct
            local pr, pg, pb = 0, 1, 0
            if pct < 50 then pr, pg, pb = 1, 0.27, 0.27 end
            GameTooltip:AddDoubleLine(L["RECORD_LABEL"], oppS.wins .. "W - " .. oppS.losses .. "L - " .. oppS.draws .. "D", 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["WIN_RATE_LABEL"], pct .. "%", 0.7, 0.7, 0.7, pr, pg, pb)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self, button)
            if not self.friend then return end
            
            local charName = GetFormattedName(self.friend.targetName, self.friend.realm) or self.friend.targetName
            local bTag = self.friend.battleTag
            
            if button == "RightButton" then
                OpenWarGamesMenu(self, self.friend)
            elseif IsShiftKeyDown() then
                local key = self.friend.targetName
                WG_History.favFriends[key] = not WG_History.favFriends[key] or nil
                ui:Refresh()
            else
                local fillName = bTag or self.friend.whisperName or charName
                if fillName then
                    if ui.spectatorMode then
                        -- Fill leader 1 first, then leader 2
                        if ui.leader1EditBox:GetText():trim() == "" then
                            ui.leader1EditBox:SetText(fillName)
                        else
                            ui.leader2EditBox:SetText(fillName)
                        end
                    else
                        ui.editBox:SetText(fillName)
                    end
                end
                PlaySound(856)
            end
        end)
        ui.rows[i] = row
    end

    -- --- CUSTOM THEME EDITOR (standalone movable window) ---
    -- Theme selection itself lives in the Settings panel (preset cards + Custom); this
    -- window is the per-color override editor, opened while the Custom theme is active.
    local customEditor = CreateFrame("Frame", "WG_CustomThemeEditor", UIParent, "BackdropTemplate")
    customEditor:SetSize(288, 360)
    -- left of the main window (Settings, which drives it, sits on the right)
    customEditor:SetPoint("TOPRIGHT", ui, "TOPLEFT", -5, -40)
    customEditor:SetFrameStrata("DIALOG")
    customEditor:SetFrameLevel(200)
    ApplyModernStyle(customEditor)
    WargamesPlus.ApplyUIScale(customEditor)
    ui.customEditor = customEditor

    CreateWindowChrome(customEditor, {
        title = L["CUSTOM_THEME"], titleSize = 13, closeSize = 18, draggable = true,
    })

    local baseLabel = customEditor:CreateFontString(nil, "OVERLAY")
    baseLabel:SetFont(ADDON_FONT, 9, "OUTLINE")
    baseLabel:SetPoint("TOPLEFT", 14, -36)
    baseLabel:SetText(L["BASE_LABEL"])
    baseLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {baseLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})

    local baseStrip = CreateSegmentedControl(customEditor, {
        {key = "Midnight", label = "Midnight"},
        {key = "Horde",    label = "Horde"},
        {key = "Alliance", label = "Alliance"},
    }, { height = 22, fontSize = 10, padX = 9, onSelect = function(name)
        WG_History.customTheme.baseTheme = name
        ApplyTheme("Custom")
        customEditor:RefreshSwatches()
    end })
    baseStrip:SetPoint("TOPLEFT", 14, -50)
    customEditor._baseStrip = baseStrip

    -- Helper: get display color for a group (override or base theme fallback)
    local function GetGroupDisplayColor(groupKey)
        local ov = WG_History.customTheme.overrides[groupKey]
        if ov then return ov.r, ov.g, ov.b end
        -- Derive from base theme's first key in this group
        local baseName = WG_History.customTheme.baseTheme or "Midnight"
        local base = THEMES[baseName] or THEMES.Midnight
        for _, group in ipairs(COLOR_GROUPS) do
            if group.key == groupKey then
                -- Pick the representative color from the base theme
                if groupKey == "accent" then return base.accent[1], base.accent[2], base.accent[3]
                elseif groupKey == "background" then return base.backdropBg[1], base.backdropBg[2], base.backdropBg[3]
                elseif groupKey == "border" then return base.backdropBorder[1], base.backdropBorder[2], base.backdropBorder[3]
                elseif groupKey == "button" then return base.buttonNormal[1], base.buttonNormal[2], base.buttonNormal[3]
                elseif groupKey == "text" then return base.buttonText[1], base.buttonText[2], base.buttonText[3]
                elseif groupKey == "closeHover" then return base.closeHover[1], base.closeHover[2], base.closeHover[3]
                elseif groupKey == "winColor" then
                    local hex = base.inlineGreen
                    return tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255
                elseif groupKey == "lossColor" then
                    local hex = base.inlineLoss or "ff4444"
                    return tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255
                end
            end
        end
        return 1, 1, 1
    end

    -- Color swatch rows — one card per COLOR_GROUP: name (left), color chip + Reset (right)
    customEditor.swatches = {}
    local ROW_H, ROW_GAP, ROW_TOP = 30, 4, -84
    for i, group in ipairs(COLOR_GROUPS) do
        local yOff = ROW_TOP - ((i - 1) * (ROW_H + ROW_GAP))

        local row = CreateFrame("Frame", nil, customEditor, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 12, yOff)
        row:SetPoint("RIGHT", customEditor, "RIGHT", -12, 0)
        row:SetHeight(ROW_H)
        row:SetBackdrop(FLAT_BACKDROP)
        row:SetBackdropColor(unpack(activeTheme.cardBg))
        row:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
        table.insert(themedElements, {row, function(r)
            r:SetBackdropColor(unpack(activeTheme.cardBg))
            r:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
        end})

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, 10)
        label:SetPoint("LEFT", 10, 0)
        label:SetText(group.label)
        label:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {label, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

        local resetBtn = CreateFrame("Button", nil, row)
        resetBtn:SetSize(40, 16)
        resetBtn:SetPoint("RIGHT", -8, 0)
        local resetFS = resetBtn:CreateFontString(nil, "OVERLAY")
        resetFS:SetFont(ADDON_FONT, 9)
        resetFS:SetPoint("CENTER")
        resetFS:SetText(L["RESET"])
        resetFS:SetTextColor(unpack(activeTheme.footerColor))
        resetBtn:SetFontString(resetFS)
        table.insert(themedElements, {resetBtn, function() resetFS:SetTextColor(unpack(activeTheme.footerColor)) end})
        resetBtn:SetScript("OnEnter", function() resetFS:SetTextColor(unpack(activeTheme.buttonText)) end)
        resetBtn:SetScript("OnLeave", function() resetFS:SetTextColor(unpack(activeTheme.footerColor)) end)
        resetBtn:SetScript("OnClick", function()
            WG_History.customTheme.overrides[group.key] = nil
            ApplyTheme("Custom")
            customEditor:RefreshSwatches()
        end)

        local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
        swatch:SetSize(40, 18)
        swatch:SetPoint("RIGHT", resetBtn, "LEFT", -8, 0)
        swatch:SetBackdrop(FLAT_BACKDROP)
        swatch:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
        swatch._colorTex = swatch:CreateTexture(nil, "ARTWORK")
        swatch._colorTex:SetPoint("TOPLEFT", 1, -1)
        swatch._colorTex:SetPoint("BOTTOMRIGHT", -1, 1)
        table.insert(themedElements, {swatch, function(s)
            s:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
        end})

        swatch:SetScript("OnClick", function()
            local r, g, b = GetGroupDisplayColor(group.key)
            local info = {
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    WG_History.customTheme.overrides[group.key] = {r = nr, g = ng, b = nb}
                    ApplyTheme("Custom")
                    customEditor:RefreshSwatches()
                end,
                hasOpacity = false,
                r = r, g = g, b = b,
                cancelFunc = function()
                    WG_History.customTheme.overrides[group.key] = (r and {r = r, g = g, b = b} or nil)
                    ApplyTheme("Custom")
                    customEditor:RefreshSwatches()
                end,
            }
            if ColorPickerFrame.SetupColorPickerAndShow then
                ColorPickerFrame:SetupColorPickerAndShow(info)
            else
                ColorPickerFrame.previousValues = {r, g, b}
                ColorPickerFrame.func = info.swatchFunc
                ColorPickerFrame.cancelFunc = info.cancelFunc
                ColorPickerFrame:SetColorRGB(r, g, b)
                ColorPickerFrame:Show()
            end
        end)

        customEditor.swatches[group.key] = swatch
    end

    -- Size the window to fit the rows
    customEditor:SetHeight(-(ROW_TOP - (#COLOR_GROUPS * (ROW_H + ROW_GAP))) + 12)

    function customEditor:RefreshSwatches()
        if self._baseStrip then
            self._baseStrip:SetActiveSegment(WG_History.customTheme.baseTheme or "Midnight")
        end
        for _, group in ipairs(COLOR_GROUPS) do
            local sw = self.swatches[group.key]
            if sw then
                local r, g, b = GetGroupDisplayColor(group.key)
                sw._colorTex:SetColorTexture(r, g, b, 1)
            end
        end
    end

    customEditor:RefreshSwatches()

    -- Show editor only if Custom theme is active
    if WG_History.theme == "Custom" then
        customEditor:Show()
    else
        customEditor:Hide()
    end

    -- Hide editor when main frame hides
    ui:HookScript("OnHide", function()
        customEditor:Hide()
        if WargamesPlus.HideProfileCard then WargamesPlus.HideProfileCard() end
    end)
    ui:HookScript("OnShow", function()
        if WG_History.theme == "Custom" then
            customEditor:Show()
            customEditor:RefreshSwatches()
        end
    end)

    -- --- SETTINGS PANEL ---
    local wgBox = CreateFrame("Frame", nil, ui)
    wgBox:SetPoint("TOPLEFT", 310, -75)
    wgBox:SetPoint("BOTTOMRIGHT", -20, 40)
    ApplyCardStyle(wgBox)
    ui.wgBox = wgBox

    -- --- TARGET (opponent name) ---
    local targetLabel = wgBox:CreateFontString(nil, "OVERLAY")
    targetLabel:SetFont(ADDON_FONT, 10, "OUTLINE")
    targetLabel:SetText(L["TARGET_HEADER"])
    targetLabel:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -14)
    targetLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {targetLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})
    ui.targetLabel = targetLabel

    local editBox  -- created below; referenced by targetBtn's OnClick closure

    local targetBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    targetBtn:SetSize(62, 24)
    targetBtn:SetPoint("TOPRIGHT", wgBox, "TOPRIGHT", -14, -30)
    targetBtn:SetText(L["TARGET"])
    targetBtn:SetScript("OnClick", function()
        if not UnitExists("target") then return end
        local name, realm = GetUnitName("target", true)
        local fullName = GetFormattedName(name, realm)
        if fullName then editBox:SetText(fullName) end
    end)
    StyleButton(targetBtn)

    editBox = CreateFrame("EditBox", nil, wgBox, "InputBoxTemplate")
    editBox:SetHeight(24)
    editBox:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 26, -30)
    editBox:SetPoint("RIGHT", targetBtn, "LEFT", -10, 0)
    editBox:SetAutoFocus(false)
    ui.editBox = editBox
    StyleInput(editBox)

    -- Help guide (opened from the "Help" button in the title bar).
    local function ShowHelp()
        if ui.helpFrame and ui.helpFrame:IsShown() then
            ui.helpFrame:Hide()
            return
        end
        if not ui.helpFrame then
            local hf = CreateFrame("Frame", "WG_HelpFrame", UIParent, "BackdropTemplate")
            hf:SetSize(360, 380)
            hf:SetFrameStrata("DIALOG")
            hf:SetFrameLevel(120)
            hf:SetMovable(true)
            hf:EnableMouse(true)
            hf:RegisterForDrag("LeftButton")
            hf:SetScript("OnDragStart", hf.StartMoving)
            hf:SetScript("OnDragStop", hf.StopMovingOrSizing)
            ApplyModernStyle(hf)
            WargamesPlus.ApplyUIScale(hf)

            local hClose = CreateFrame("Button", nil, hf)
            hClose:SetSize(20, 20)
            hClose:SetPoint("TOPRIGHT", -6, -6)
            hClose.label = hClose:CreateFontString(nil, "OVERLAY")
            hClose.label:SetFont(ADDON_FONT, 14, "OUTLINE")
            hClose.label:SetPoint("CENTER")
            hClose.label:SetText("X")
            hClose.label:SetTextColor(unpack(activeTheme.closeNormal))
            hClose:SetScript("OnClick", function() hf:Hide() end)
            hClose:HookScript("OnEnter", function() hClose.label:SetTextColor(unpack(activeTheme.closeHover)) end)
            hClose:HookScript("OnLeave", function() hClose.label:SetTextColor(unpack(activeTheme.closeNormal)) end)
            WargamesPlus.RegisterThemedElement(hClose, function(c)
                c.label:SetTextColor(unpack(activeTheme.closeNormal))
            end)

            local title = hf:CreateFontString(nil, "OVERLAY")
            title:SetFont(ADDON_FONT, 14, "OUTLINE")
            title:SetPoint("TOPLEFT", 12, -10)
            title:SetText("|cff" .. activeTheme.inlineAccent .. L["HELP_TITLE"] .. "|r")
            WargamesPlus.RegisterThemedElement(title, function(fs)
                fs:SetText("|cff" .. activeTheme.inlineAccent .. L["HELP_TITLE"] .. "|r")
            end)

            local scroll = CreateFrame("ScrollFrame", "WG_HelpScroll", hf, "UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT", 10, -32)
            scroll:SetPoint("BOTTOMRIGHT", -28, 10)
            WargamesPlus.StyleScrollBar(scroll)

            local content = CreateFrame("Frame", nil, scroll)
            content:SetSize(300, 1)
            scroll:SetScrollChild(content)

            local body = content:CreateFontString(nil, "OVERLAY")
            body:SetFont(ADDON_FONT, 10)
            body:SetPoint("TOPLEFT", 4, 0)
            body:SetPoint("RIGHT", -4, 0)
            body:SetJustifyH("LEFT")
            body:SetSpacing(3)
            body:SetWordWrap(true)
            body:SetTextColor(unpack(activeTheme.normalText))
            WargamesPlus.RegisterThemedElement(body, function(fs)
                fs:SetTextColor(unpack(activeTheme.normalText))
            end)
            hf.body = body

            hf:Hide()
            ui.helpFrame = hf
        end

        local acc = activeTheme.inlineAccent
        -- Highlight feature name before the em dash
        local function hl(text)
            local pos = text:find(" — ", 1, true)
            if not pos then pos = text:find(" - ", 1, true) end
            if pos then
                local name = text:sub(1, pos - 1)
                local desc = text:sub(pos)
                return "|cff" .. acc .. name .. "|r|cffdddddd" .. desc .. "|r"
            end
            return "|cffdddddd" .. text .. "|r"
        end
        local function step(text)
            return "|cffbbbbbb" .. text .. "|r"
        end
        local lines = {
            "|cff" .. acc .. L["HELP_SECTION_BASICS"] .. "|r",
            hl(L["HELP_OPPONENT_FIELD"]),
            hl(L["HELP_TARGET_BTN"]),
            hl(L["HELP_RECENT_DROPDOWN"]),
            "",
            "|cff" .. acc .. L["HELP_SECTION_MODES"] .. "|r",
            "|cffdddddd" .. L["HELP_GAME_MODES"] .. "|r",
            "|cffdddddd" .. L["HELP_MAP_SELECT"] .. "|r",
            "",
            "|cff" .. acc .. L["HELP_SECTION_FEATURES"] .. "|r",
            hl(L["HELP_BAN_MAPS"]),
            hl(L["HELP_VETO"]),
            hl(L["HELP_SPECTATE"]),
            step(L["HELP_SPECTATE_1"]),
            step(L["HELP_SPECTATE_2"]),
            step(L["HELP_SPECTATE_3"]),
            step(L["HELP_SPECTATE_4"]),
            hl(L["HELP_TOURNAMENT"]),
            "",
            "|cff" .. acc .. L["HELP_SECTION_LFG"] .. "|r",
            hl(L["HELP_LFG"]),
            step(L["HELP_LFG_POST"]),
            step(L["HELP_LFG_BROWSE"]),
            step(L["HELP_LFG_INTERACT"]),
            step(L["HELP_LFG_BADGE"]),
            step(L["HELP_LFG_H2H"]),
            step(L["HELP_LFG_HISTORY"]),
            hl(L["HELP_LFG_REACH"]),
            "",
            "|cff" .. acc .. L["HELP_SECTION_EXTRAS"] .. "|r",
            hl(L["HELP_STATS"]),
            hl(L["HELP_THEMES"]),
            hl(L["HELP_RIGHT_CLICK"]),
            hl(L["HELP_DRAG_MAPS"]),
        }
        ui.helpFrame.body:SetText(table.concat(lines, "\n"))
        local textHeight = ui.helpFrame.body:GetStringHeight()
        ui.helpFrame.body:GetParent():SetHeight(textHeight + 10)

        ui.helpFrame:ClearAllPoints()
        -- left of the main window (the right side is the Settings/History/LFG dock)
        ui.helpFrame:SetPoint("TOPRIGHT", ui, "TOPLEFT", -5, 0)
        ui.helpFrame:Show()
    end
    AddTitleBarButton(L["HELP"], ShowHelp)

    -- --- RECENT OPPONENTS (inline chips under the target field) ---
    local recentRow = CreateFrame("Frame", nil, wgBox)
    recentRow:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 26, -58)
    recentRow:SetPoint("RIGHT", wgBox, "RIGHT", -14, 0)
    recentRow:SetHeight(16)
    ui.recentRow = recentRow
    ui.recentChips = {}

    function ui:RefreshRecentChips()
        local list = WG_History.opponents or {}
        for _, chip in ipairs(ui.recentChips) do chip:Hide() end

        local maxW = recentRow:GetWidth()
        if not maxW or maxW < 20 then maxW = 240 end
        local x = 0
        for i, name in ipairs(list) do
            if i > 6 then break end
            local chip = ui.recentChips[i]
            if not chip then
                chip = CreateFrame("Button", nil, recentRow, "BackdropTemplate")
                chip:SetSize(60, 16)
                chip:SetBackdrop(FLAT_BACKDROP)
                chip._label = chip:CreateFontString(nil, "OVERLAY")
                chip._label:SetFont(ADDON_FONT, 9)
                chip._label:SetPoint("CENTER")
                chip:SetScript("OnClick", function(self)
                    ui.editBox:SetText(self._name or "")
                    ui.editBox:SetFocus()
                end)
                table.insert(themedElements, {chip, function(c)
                    c:SetBackdropColor(unpack(activeTheme.cardBg))
                    c:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
                    c._label:SetTextColor(unpack(activeTheme.footerColor))
                end})
                ui.recentChips[i] = chip
            end

            chip._name = name
            chip._label:SetText(name:match("^[^-]+") or name)
            local w = math.floor(chip._label:GetStringWidth() + 0.5) + 16
            if x + w > maxW then break end
            chip:SetSize(w, 16)
            chip:ClearAllPoints()
            chip:SetPoint("LEFT", recentRow, "LEFT", x, 0)
            chip:SetBackdropColor(unpack(activeTheme.cardBg))
            chip:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
            chip._label:SetTextColor(unpack(activeTheme.footerColor))
            chip:Show()
            x = x + w + 5
        end
        recentRow:SetShown(#list > 0 and not ui.spectatorMode)
    end

    ui.gameMode = "ARENA_2V2"
    ui.lastArenaMode = "ARENA_2V2"
    ui.lastBGMode = "BG"

    local function GetActiveTab()
        return GAME_MODES[ui.gameMode] and GAME_MODES[ui.gameMode].tab or "ARENA"
    end

    -- ---------- MODE SELECTOR (segmented pills) ----------
    -- Two stacked segmented controls (Arena/BG, then the sub-modes). Anchored at a
    -- fixed TOPLEFT offset, so the old C_Timer re-centering hack in UpdateTabDisplay
    -- is gone. Only one sub-mode strip is shown at a time (arena vs bg).
    local modeLabel = wgBox:CreateFontString(nil, "OVERLAY")
    modeLabel:SetFont(ADDON_FONT, 10, "OUTLINE")
    modeLabel:SetText(L["MODE_HEADER"])
    modeLabel:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -88)
    modeLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {modeLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})

    local function SelectSubMode(key)
        ui.gameMode = key
        local gm = GAME_MODES[key]
        if gm and gm.tab == "ARENA" then ui.lastArenaMode = key
        else ui.lastBGMode = key end
        ui:UpdateTabDisplay()
        PlaySound(856)
    end

    local tabStrip = CreateSegmentedControl(wgBox, {
        {key = "ARENA", label = L["TAB_ARENAS"]},
        {key = "BG",    label = L["TAB_BATTLEGROUNDS"]},
    }, {
        height = 24,
        onSelect = function(k)
            ui.gameMode = (k == "ARENA") and ui.lastArenaMode or ui.lastBGMode
            ui:UpdateTabDisplay()
            PlaySound(856)
        end,
    })
    tabStrip:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -104)
    ui.tabStrip = tabStrip

    local arenaStrip = CreateSegmentedControl(wgBox, {
        {key = "ARENA_2V2",    label = L["MODE_2V2"]},
        {key = "ARENA_3V3",    label = L["MODE_3V3"]},
        {key = "ARENA_5V5",    label = L["MODE_5V5"]},
        {key = "SOLO_SHUFFLE", label = L["MODE_SHUFFLE"]},
    }, { height = 22, fontSize = 11, padX = 10, onSelect = SelectSubMode })
    arenaStrip:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -134)
    ui.arenaStrip = arenaStrip

    local bgStrip = CreateSegmentedControl(wgBox, {
        {key = "BG",    label = L["MODE_NORMAL"]},
        {key = "BLITZ", label = L["MODE_BLITZ"]},
    }, { height = 22, fontSize = 11, padX = 10, onSelect = SelectSubMode })
    bgStrip:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -134)
    ui.bgStrip = bgStrip

    -- ---------- MAP GRID ----------
    local mapLabel = wgBox:CreateFontString(nil, "OVERLAY")
    mapLabel:SetFont(ADDON_FONT, 10, "OUTLINE")
    mapLabel:SetText(L["MAP_HEADER"])
    mapLabel:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 20, -170)
    mapLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {mapLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})

    local mapHint = wgBox:CreateFontString(nil, "OVERLAY")
    mapHint:SetFont(ADDON_FONT, 10)
    mapHint:SetText(L["MAP_MANAGE_HINT"])
    mapHint:SetPoint("TOPRIGHT", wgBox, "TOPRIGHT", -22, -170)
    mapHint:SetTextColor(unpack(activeTheme.footerColor))
    table.insert(themedElements, {mapHint, function(fs) fs:SetTextColor(unpack(activeTheme.footerColor)) end})

    -- Fixed grid area: derived from the (non-resizable) window layout so tile sizing is
    -- deterministic — querying GetHeight mid-build gave stale values and clipped the
    -- bottom row. ui 720 - top(75) - bottom(40) - mapHeader(186) - bottomCluster(88).
    local MAP_AREA_H = 720 - 75 - 40 - 186 - 88

    local mapScroll = CreateFrame("ScrollFrame", "WG_MapScroll", wgBox, "UIPanelScrollFrameTemplate")
    mapScroll:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 18, -186)
    mapScroll:SetPoint("RIGHT", wgBox, "RIGHT", -24, 0)
    mapScroll:SetHeight(MAP_AREA_H)
    ApplyModernStyle(mapScroll)
    StyleScrollBar(mapScroll)
    local mapContent = CreateFrame("Frame", nil, mapScroll)
    mapContent:SetSize(1, 1)
    mapScroll:SetScrollChild(mapContent)

    ui.mapBtns = {}
    ui.selectedArena = "Random Map"
    ui.selectedBG = "Random Map"
    ui.selectedBlitz = "Random Map"

    local MAP_COLS, MAP_GAP = 4, 7
    local MAP_TILE_H = 60  -- recomputed per mode in RefreshMaps so every row always fits

    -- Drag-to-reorder: a floating ghost follows the cursor; on drop the target slot is
    -- computed from the cursor's row/column over the grid and the mode's custom order
    -- (WG_History.mapOrder[mapMode]) is rewritten. "Random Map" is pinned at slot 1.
    local drag = {}
    local dragGhost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dragGhost:SetSize(112, MAP_TILE_H)
    dragGhost:SetFrameStrata("TOOLTIP")
    dragGhost:SetBackdrop(FLAT_BACKDROP)
    dragGhost:SetBackdropColor(unpack(activeTheme.cardBg))
    dragGhost:SetBackdropBorderColor(unpack(activeTheme.accent))
    dragGhost.tex = dragGhost:CreateTexture(nil, "ARTWORK")
    dragGhost.tex:SetPoint("TOPLEFT", 1, -1)
    dragGhost.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    dragGhost.tex:SetTexCoord(0.08, 0.92, 0.15, 0.85)
    dragGhost.label = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhost.label:SetFont(ADDON_FONT, 10, "OUTLINE")
    dragGhost.label:SetPoint("BOTTOM", 0, 4)
    dragGhost:Hide()
    dragGhost:SetScript("OnUpdate", function(self)
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / s, cy / s)
    end)

    local dropLine = mapContent:CreateTexture(nil, "OVERLAY")
    dropLine:SetColorTexture(unpack(activeTheme.accent))
    dropLine:SetWidth(3)
    dropLine:Hide()
    table.insert(themedElements, {dropLine, function(t) t:SetColorTexture(unpack(activeTheme.accent)) end})

    local function GridDropIndex(list, tileW)
        local s = mapContent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / s, cy / s
        local left, top = mapContent:GetLeft(), mapContent:GetTop()
        if not left or not top then return #list + 1 end
        local col = math.max(0, math.min(MAP_COLS - 1, math.floor((cx - left) / (tileW + MAP_GAP))))
        local row = math.max(0, math.floor((top - cy) / (MAP_TILE_H + MAP_GAP)))
        return math.max(2, math.min(#list + 1, row * MAP_COLS + col + 1))
    end

    local function CommitGridDrop(name, dropIndex, list, mapMode)
        local order = {}
        for _, n in ipairs(list) do
            if n ~= "Random Map" and n ~= name then order[#order + 1] = n end
        end
        table.insert(order, math.max(1, math.min(#order + 1, dropIndex - 1)), name)
        WG_History.mapOrder[mapMode] = order
    end

    function ui:RefreshMaps()
        local gm = GAME_MODES[ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        local currentList = GetSortedMapList(mapMode)
        local greenR, greenG, greenB = HexToRGB(activeTheme.inlineGreen)
        local currentSelection
        if mapMode == "ARENA" then currentSelection = ui.selectedArena
        elseif mapMode == "BLITZ" then currentSelection = ui.selectedBlitz
        else currentSelection = ui.selectedBG end

        local areaW = mapScroll:GetWidth()
        if not areaW or areaW < 40 then areaW = 520 end
        -- Leave a few px on the right so the last column's selection border isn't
        -- clipped by the scroll frame's edge / scrollbar gutter.
        local usableW = areaW - 8
        local tileW = math.floor((usableW - (MAP_COLS - 1) * MAP_GAP) / MAP_COLS)
        local rows = math.max(1, math.ceil(#currentList / MAP_COLS))

        -- Tile height = as large as lets every row fit MAP_AREA_H, clamped to a sane band.
        MAP_TILE_H = math.max(44, math.min(66, math.floor((MAP_AREA_H - (rows - 1) * MAP_GAP) / rows)))
        local contentH = rows * MAP_TILE_H + (rows - 1) * MAP_GAP
        mapContent:SetSize(areaW, contentH)

        local sb = _G["WG_MapScrollScrollBar"]
        if sb then sb:SetShown(contentH > MAP_AREA_H) end

        for _, tile in pairs(ui.mapBtns) do tile:Hide() end
        local banning = ui.banMode and WargamesPlus.banState == "selecting"

        for i, name in ipairs(currentList) do
            local isPinned = (name == "Random Map")

            local tile = ui.mapBtns[i]
            if not tile then
                tile = CreateMapTile(mapContent, { height = MAP_TILE_H, fontSize = 10 })
                tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                tile:RegisterForDrag("LeftButton")
                ui.mapBtns[i] = tile
            end

            tile:SetSize(tileW, MAP_TILE_H)
            local col = (i - 1) % MAP_COLS
            local row = math.floor((i - 1) / MAP_COLS)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", mapContent, "TOPLEFT", col * (tileW + MAP_GAP), -row * (MAP_TILE_H + MAP_GAP))
            tile:SetAlpha(1)

            tile:SetMapTexture((not isPinned) and MAP_TEXTURES[name] or nil)

            local isExcluded = WG_History.excluded[name] and true or false
            local isBanSelected = false
            if ui.banMode then
                for _, bn in ipairs(ui.banSelections) do
                    if bn == name then isBanSelected = true; break end
                end
            end

            tile._label:SetText(isExcluded and (name .. " " .. L["MAP_EXCLUDED_SUFFIX"]) or name)
            if isPinned then tile._label:SetTextColor(greenR, greenG, greenB, 1)
            else tile._label:SetTextColor(1, 1, 1, 1) end

            tile:SetFavorite((not isPinned) and WG_History.favorites[name])
            tile:SetDimmed(isExcluded)
            tile:SetBanned(isBanSelected)
            tile:SetSelected((not isBanSelected) and name == currentSelection)

            tile:SetScript("OnClick", function(self, button)
                if banning and not isPinned and button ~= "RightButton" then
                    local removed = false
                    for bi, bn in ipairs(ui.banSelections) do
                        if bn == name then table.remove(ui.banSelections, bi); removed = true; break end
                    end
                    if not removed and #ui.banSelections < ui.maxBans then
                        table.insert(ui.banSelections, name)
                    end
                    ui.banCountText:SetText(string.format(L["BAN_COUNT"], #ui.banSelections, ui.maxBans))
                    ui.banCountText:Show()
                    ui.banSubmitBtn:SetShown(#ui.banSelections > 0)
                    ui:RefreshMaps()
                    return
                end
                if button == "RightButton" then
                    OpenMapContextMenu(self, name, mapMode)
                    return
                end
                if IsShiftKeyDown() and not isPinned then
                    WG_History.favorites[name] = not WG_History.favorites[name] or nil
                else
                    if mapMode == "ARENA" then ui.selectedArena = name
                    elseif mapMode == "BLITZ" then ui.selectedBlitz = name
                    else ui.selectedBG = name end
                end
                ui:RefreshMaps()
            end)

            tile:SetScript("OnDragStart", function(self)
                if isPinned or banning then return end
                drag.name = name
                dragGhost:SetSize(math.min(140, tileW), MAP_TILE_H)
                dragGhost.label:SetText(name)
                local tex = MAP_TEXTURES[name]
                if tex then dragGhost.tex:SetTexture(tex); dragGhost.tex:Show() else dragGhost.tex:Hide() end
                dragGhost:SetBackdropColor(unpack(activeTheme.cardBg))
                dragGhost:SetBackdropBorderColor(unpack(activeTheme.accent))
                dragGhost:Show()
                dropLine:Show()
                self:SetAlpha(0.35)
            end)
            tile:SetScript("OnDragStop", function()
                if not drag.name then return end
                local dropIdx = GridDropIndex(currentList, tileW)
                CommitGridDrop(drag.name, dropIdx, currentList, mapMode)
                drag.name = nil
                dragGhost:Hide()
                dropLine:Hide()
                ui:RefreshMaps()
            end)
            tile:SetScript("OnEnter", function()
                if not drag.name then return end
                local di = GridDropIndex(currentList, tileW) - 1
                local c, r = di % MAP_COLS, math.floor(di / MAP_COLS)
                dropLine:ClearAllPoints()
                dropLine:SetHeight(MAP_TILE_H)
                dropLine:SetPoint("TOPLEFT", mapContent, "TOPLEFT",
                    c * (tileW + MAP_GAP) - math.floor(MAP_GAP / 2) - 1, -r * (MAP_TILE_H + MAP_GAP))
            end)

            tile:Show()
        end
    end

    -- --- SPECTATOR MODE UI ---
    ui.spectatorMode = WG_History.spectatorMode or false

    -- Spectator leader inputs — two stacked rows that mirror the TARGET field layout
    -- (full-width editbox + a Target button on the right, aligned under the TARGET one).
    local function MakeLeaderRow(yOffset, placeholder)
        local btn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
        btn:SetSize(62, 24)
        btn:SetPoint("TOPRIGHT", wgBox, "TOPRIGHT", -14, yOffset)
        btn:SetText(L["TARGET"])
        StyleButton(btn)

        local eb = CreateFrame("EditBox", nil, wgBox, "InputBoxTemplate")
        eb:SetHeight(24)
        eb:SetPoint("TOPLEFT", wgBox, "TOPLEFT", 26, yOffset)
        eb:SetPoint("RIGHT", btn, "LEFT", -10, 0)
        eb:SetAutoFocus(false)
        StyleInput(eb)
        AddPlaceholder(eb, placeholder)

        btn:SetScript("OnClick", function()
            if not UnitExists("target") then return end
            local name, realm = GetUnitName("target", true)
            local fullName = GetFormattedName(name, realm)
            if fullName then eb:SetText(fullName) end
        end)
        return eb, btn
    end

    local leader1EditBox, target1Btn = MakeLeaderRow(-30, L["LEADER_1"])
    local leader2EditBox, target2Btn = MakeLeaderRow(-58, L["LEADER_2"])
    ui.leader1EditBox = leader1EditBox
    ui.leader2EditBox = leader2EditBox

    -- Hide spectator elements by default
    leader1EditBox:Hide(); target1Btn:Hide()
    leader2EditBox:Hide(); target2Btn:Hide()

    -- BTag resolution helpers — delegate to shared module-scope functions
    local function ResolveBTagToCharName(bTag) return WargamesPlus.ResolveBTagToCharName(bTag) end
    local function ResolveCharToBTag(charName) return WargamesPlus.ResolveCharToBTag(charName) end
    local function ResolveBNetID(nameOrTag) return WargamesPlus.ResolveBNetID(nameOrTag) end
    local function ResolveToAccountName(nameOrTag) return WargamesPlus.ResolveToAccountName(nameOrTag) end

    local function UpdateSpectatorUI()
        -- The "TARGET" header stays visible in both modes; only the field(s) below swap.
        if ui.spectatorMode then
            leader1EditBox:Show(); target1Btn:Show()
            leader2EditBox:Show(); target2Btn:Show()
            editBox:Hide(); targetBtn:Hide(); ui.recentRow:Hide()
        else
            leader1EditBox:Hide(); target1Btn:Hide()
            leader2EditBox:Hide(); target2Btn:Hide()
            editBox:Show(); targetBtn:Show()
            if ui.RefreshRecentChips then ui:RefreshRecentChips() end
        end
        ui.targetLabel:Show()
        if ui.spectatorToggle then ui.spectatorToggle:SetChecked(ui.spectatorMode) end
    end

    -- --- OPTION TOGGLES (Tournament Rules + Spectator Mode) ---
    local function AddOptionToggle(labelText, checked, onChange)
        local sw = CreateToggleSwitch(wgBox, { checked = checked, onChange = onChange })
        local lbl = wgBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetText(labelText)
        lbl:SetPoint("LEFT", sw, "RIGHT", 5, 0)
        lbl:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {lbl, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})
        sw._label = lbl
        return sw
    end

    local tourneyCheck = AddOptionToggle(L["TOURNAMENT_RULES"], WG_History.tournamentRules ~= false, function(checked)
        WG_History.tournamentRules = checked
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)
    tourneyCheck:SetPoint("BOTTOMLEFT", wgBox, "BOTTOMLEFT", 20, 66)
    ui.tourneyCheck = tourneyCheck
    ui.tourneyLabel = tourneyCheck._label

    local spectatorToggle = AddOptionToggle(L["SPECTATE_MODE"], ui.spectatorMode, function(checked)
        ui.spectatorMode = checked
        WG_History.spectatorMode = checked
        UpdateSpectatorUI()
        ui:UpdateChallengeButtons()
        PlaySound(856)
    end)
    spectatorToggle:SetPoint("LEFT", tourneyCheck._label, "RIGHT", 22, 0)
    ui.spectatorToggle = spectatorToggle

    -- --- ACTION ROW: Send Challenge (primary) + Veto + Ban (secondary "ghost") ---
    -- Ghost = transparent accent-tinted fill + accent outline, brightening on hover.
    -- Runs StyleButton first (texture cleanup + press feedback) then re-asserts the tint
    -- over StyleButton's hover/leave hooks.
    local function MakeGhostButton(btn, labelText)
        btn:SetText(labelText)
        StyleButton(btn)
        btn:GetFontString():SetFont(ADDON_FONT, 12, "")
        local function paint(b, hover)
            local a = activeTheme.accent
            if b._flatBg then b._flatBg:SetColorTexture(a[1], a[2], a[3], hover and 0.24 or 0.10) end
            b:SetBackdropBorderColor(a[1], a[2], a[3], hover and 0.95 or 0.55)
            b:GetFontString():SetTextColor(unpack(activeTheme.normalText))
        end
        paint(btn, false)
        btn:HookScript("OnEnter", function(b) paint(b, true) end)
        btn:HookScript("OnLeave", function(b) paint(b, false) end)
        btn:HookScript("OnMouseUp", function(b) paint(b, true) end)
        table.insert(themedElements, {btn, function(b) paint(b, false) end})
    end

    local banBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    banBtn:SetSize(52, 38)
    banBtn:SetPoint("BOTTOMRIGHT", wgBox, "BOTTOMRIGHT", -18, 14)
    MakeGhostButton(banBtn, L["BAN_MODE_SHORT"])
    ui.banBtn = banBtn

    local vetoBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    vetoBtn:SetSize(52, 38)
    vetoBtn:SetPoint("RIGHT", banBtn, "LEFT", -6, 0)
    MakeGhostButton(vetoBtn, L["VETO_MODE_SHORT"])
    ui.vetoBtn = vetoBtn

    local rcBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    rcBtn:SetSize(52, 38)
    rcBtn:SetPoint("RIGHT", vetoBtn, "LEFT", -6, 0)
    MakeGhostButton(rcBtn, L["RC_SHORT"])
    ui.rcBtn = rcBtn
    rcBtn:SetScript("OnClick", function()
        local opp = editBox:GetText():trim()
        if opp == "" then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["RC_NO_OPPONENT"])
            return
        end
        -- StartReadyCheck resolves the whisper target and probes for the addon
        -- itself (incl. players we haven't pinged yet), so no pre-gate here.
        if WargamesPlus.StartReadyCheck then WargamesPlus.StartReadyCheck(opp) end
    end)

    -- --- BAN MODE STATE ---
    ui.banMode = false
    ui.banSelections = {}
    ui.maxBans = WG_History.bansPerPlayer or 2

    vetoBtn:SetScript("OnClick", function()
        -- If a veto is active, cancel it
        if WargamesPlus.vetoState then
            if WargamesPlus.CancelVeto then WargamesPlus.CancelVeto() end
            return
        end

        -- Get opponent name
        local oppName = editBox:GetText():trim()
        if oppName == "" then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_NO_OPPONENT"])
            return
        end

        -- Check addon detection
        if not HasAddonDetected(oppName) then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_NO_ADDON"])
            return
        end

        -- Build map pool
        local gm = GAME_MODES[ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        local sourceList
        if mapMode == "BLITZ" then sourceList = BLITZ_LIST
        elseif mapMode == "BG" then sourceList = BG_LIST
        else sourceList = ARENA_LIST end

        local pool = {}
        for j = 2, #sourceList do
            if not WG_History.excluded[sourceList[j]] then
                table.insert(pool, sourceList[j])
            end
        end

        -- Show format dropdown via context menu
        MenuUtil.CreateContextMenu(vetoBtn, function(_, rootDescription)
            rootDescription:CreateTitle(L["VETO_SELECT_FORMAT"])
            for _, fmt in ipairs({"Bo1", "Bo3", "Bo5"}) do
                rootDescription:CreateButton(L["VETO_FORMAT_" .. fmt:upper()], function()
                    if WargamesPlus.StartVeto then
                        WargamesPlus.StartVeto(oppName, fmt, pool)
                    end
                end)
            end
        end)
    end)

    -- Ban counter text (shown during ban mode) — above the challenge button
    local banCountText = wgBox:CreateFontString(nil, "OVERLAY")
    banCountText:SetFont(ADDON_FONT, 10)
    banCountText:SetPoint("BOTTOMLEFT", wgBox, "BOTTOMLEFT", 20, 66)
    banCountText:SetTextColor(unpack(activeTheme.normalText))
    banCountText:Hide()
    ui.banCountText = banCountText
    table.insert(themedElements, {banCountText, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

    -- Submit bans button (shown during ban mode)
    local banSubmitBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    banSubmitBtn:SetSize(100, 22)
    banSubmitBtn:SetPoint("LEFT", banCountText, "RIGHT", 10, 0)
    banSubmitBtn:SetText(L["BAN_SUBMIT"])
    StyleButton(banSubmitBtn)
    banSubmitBtn:Hide()
    ui.banSubmitBtn = banSubmitBtn

    banSubmitBtn:SetScript("OnClick", function()
        if #ui.banSelections == 0 then return end
        if WargamesPlus.SubmitBans then
            WargamesPlus.SubmitBans(ui.banSelections)
        end
    end)

    banBtn:SetScript("OnClick", function()
        if ui.banMode then
            -- Cancel ban mode and notify opponent
            ui.banMode = false
            ui.banSelections = {}
            if WargamesPlus.CancelBanPhase then
                WargamesPlus.CancelBanPhase()
            else
                WargamesPlus.banState = nil
                WargamesPlus._banData = nil
            end
            banCountText:Hide()
            banSubmitBtn:Hide()
            ui:RefreshMaps()
            return
        end

        -- Get opponent name (character name, not BattleTag)
        local oppName = editBox:GetText():trim()
        if oppName == "" then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_NO_OPPONENT"])
            return
        end

        -- Check if opponent has addon
        if not HasAddonDetected(oppName) then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_OPPONENT_NO_ADDON"])
            return
        end

        -- Build current map pool (non-excluded, non-Random)
        local gm = GAME_MODES[ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        local sourceList
        if mapMode == "BLITZ" then sourceList = BLITZ_LIST
        elseif mapMode == "BG" then sourceList = BG_LIST
        else sourceList = ARENA_LIST end

        local pool = {}
        for j = 2, #sourceList do
            if not WG_History.excluded[sourceList[j]] then
                table.insert(pool, sourceList[j])
            end
        end

        if #pool < 3 then
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_MIN_MAPS"])
            return
        end

        -- Start ban phase
        ui.banMode = true
        ui.banSelections = {}
        ui.maxBans = WG_History.bansPerPlayer or 2
        if WargamesPlus.StartBanPhase then
            WargamesPlus.StartBanPhase(oppName, pool, ui.maxBans)
        end
        ui:RefreshMaps()
    end)

    -- SelectMapByName helper for ban result auto-fill
    function ui:SelectMapByName(mapName)
        local gm = GAME_MODES[ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        if mapMode == "ARENA" then ui.selectedArena = mapName
        elseif mapMode == "BLITZ" then ui.selectedBlitz = mapName
        else ui.selectedBG = mapName end
        ui:RefreshMaps()
    end

    -- RefreshBanMode helper called from comm.lua
    -- The Tournament/Spectator toggles + Veto/Ban buttons are hidden while a ban phase
    -- is running (the map tiles + Submit button take over the panel).
    local function SetOptionRowShown(shown)
        tourneyCheck:SetShown(shown)
        ui.tourneyLabel:SetShown(shown)
        ui.spectatorToggle:SetShown(shown)
        ui.spectatorToggle._label:SetShown(shown)
        banBtn:SetShown(shown)
        vetoBtn:SetShown(shown)
        rcBtn:SetShown(shown)
    end

    function ui:RefreshBanMode()
        local st = WargamesPlus.banState
        if st == nil or st == "complete" then
            ui.banMode = false
            ui.banSelections = {}
            banCountText:Hide()
            banSubmitBtn:Hide()
            SetOptionRowShown(true)
        elseif st == "selecting" then
            ui.banMode = true
            if WargamesPlus._banData then
                ui.maxBans = WargamesPlus._banData.maxBans or 2
            end
            SetOptionRowShown(false)
        elseif st == "waiting" then
            ui.banMode = true
            banCountText:SetText(L["BAN_WAITING"])
            banCountText:Show()
            banSubmitBtn:Hide()
            SetOptionRowShown(false)
        end
        ui:RefreshMaps()
    end

    -- --- SEND CHALLENGE ---
    local function SendWarGame()
        local gm = GAME_MODES[ui.gameMode]
        if not gm then return end

        local mapMode = gm.mapMode
        local selectedName
        if mapMode == "ARENA" then selectedName = ui.selectedArena
        elseif mapMode == "BLITZ" then selectedName = ui.selectedBlitz
        else selectedName = ui.selectedBG end

        -- Resolve map name (handle "Random Map" addon-side random)
        local mapName = selectedName
        if mapName == "Random Map" then
            local sourceList
            if mapMode == "BLITZ" then sourceList = BLITZ_LIST
            elseif mapMode == "BG" then sourceList = BG_LIST
            else sourceList = ARENA_LIST end
            local pool = {}
            for j = 2, #sourceList do
                if not WG_History.excluded[sourceList[j]] then
                    table.insert(pool, sourceList[j])
                end
            end
            if #pool == 0 then
                print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_ALL_MAPS_EXCLUDED"])
                for j = 2, #sourceList do table.insert(pool, sourceList[j]) end
            end
            mapName = pool[math.random(1, #pool)]
            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_RANDOM_SELECTED"], mapName))
        end

        local mapInfo = MAP_DATA[mapName]
        local mapKeyword = mapInfo and mapInfo.value or mapName
        local mapApiName = mapInfo and mapInfo.apiName or mapName

        local tournamentRules = WG_History.tournamentRules ~= false
        local tournamentStr = tournamentRules and "1" or "0"

        if ui.spectatorMode then
            -- --- SPECTATOR MODE ---
            local target1 = leader1EditBox:GetText():trim()
            local target2 = leader2EditBox:GetText():trim()
            if target1 == "" or target2 == "" then
                print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_BOTH_LEADERS_REQUIRED"])
                return
            end

            local bnetID1 = ResolveBNetID(target1)
            local bnetID2 = ResolveBNetID(target2)
            if not bnetID1 then
                print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CANNOT_RESOLVE_BNET"], target1))
                return
            end
            if not bnetID2 then
                print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CANNOT_RESOLVE_BNET"], target2))
                return
            end

            if gm.apiType == "soloShuffle" then
                if StartSpectatorSoloShuffleWarGame then
                    StartSpectatorSoloShuffleWarGame(bnetID1, bnetID2, mapApiName, tournamentRules)
                end
            elseif gm.apiType == "blitz" then
                if C_PvP and C_PvP.StartSpectatorSoloRBGWarGame then
                    C_PvP.StartSpectatorSoloRBGWarGame(bnetID1, bnetID2, mapApiName, tournamentRules)
                end
            else
                if StartSpectatorWarGame then
                    StartSpectatorWarGame(bnetID1, bnetID2, gm.bracket, mapApiName, tournamentRules)
                end
            end

            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_SPECTATING"], target1, target2, mapName))
        else
            -- --- NORMAL MODE ---
            local t = editBox:GetText():trim()
            if t == "" then return end

            -- Resolve display name (character name) for storage/display
            local displayName = t
            if t:find("#") then
                local resolved = ResolveBTagToCharName(t)
                if resolved then displayName = resolved end
            end

            -- Update recent opponents
            for i, v in ipairs(WG_History.opponents or {}) do
                if v == displayName then table.remove(WG_History.opponents, i) break end
            end
            table.insert(WG_History.opponents, 1, displayName)
            if #WG_History.opponents > 10 then table.remove(WG_History.opponents) end

            -- Record challenge for tracker
            WargamesPlus.lastChallenge = {
                opponent = displayName, map = mapName,
                mode = gm.tab, matchSize = ui.gameMode,
                timestamp = time(),
                initiator = UnitName("player"),
            }
            WG_History.lastChallenge = WargamesPlus.lastChallenge
            if WargamesPlus.BroadcastChallenge then
                WargamesPlus.BroadcastChallenge()
            end

            -- Resolve to BNet account name for the API call (StartWarGameByName expects account name, not BattleTag)
            local challengeTarget = ResolveToAccountName(t) or displayName
            local cmdStr = challengeTarget .. " " .. mapKeyword .. " " .. tournamentStr

            if gm.apiType == "soloShuffle" then
                if StartSoloShuffleWarGameByName then
                    StartSoloShuffleWarGameByName(cmdStr)
                end
            elseif gm.apiType == "blitz" then
                if C_PvP and C_PvP.StartSoloRBGWarGameByName then
                    C_PvP.StartSoloRBGWarGameByName(cmdStr)
                end
            else
                if StartWarGameByName then
                    StartWarGameByName(cmdStr)
                end
            end

            print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["MSG_CHALLENGE_SENT"], displayName, mapName))
        end
    end

    -- --- CHALLENGE BUTTON (primary action, accent-filled, fills the row) ---
    local challengeBtn = CreateFrame("Button", nil, wgBox, "UIPanelButtonTemplate")
    challengeBtn:SetHeight(38)
    challengeBtn:SetPoint("BOTTOMLEFT", wgBox, "BOTTOMLEFT", 18, 14)
    challengeBtn:SetPoint("RIGHT", rcBtn, "LEFT", -8, 0)
    challengeBtn:SetScript("OnClick", function() SendWarGame() end)
    StyleButton(challengeBtn)
    challengeBtn._hasInlineColor = true
    -- White glyphs + a thin dark edge read crisply on any accent (dark text muddied,
    -- plain white washed out on the light cyan theme).
    challengeBtn:GetFontString():SetFont(ADDON_FONT, 13, "THINOUTLINE")

    local function PaintChallengeBtn(b)
        b._flatBg:SetColorTexture(unpack(activeTheme.accent))
        b:SetBackdropBorderColor(unpack(activeTheme.accent))
        local label = ui.spectatorMode and L["SPECTATE_MATCH"] or L["SEND_CHALLENGE"]
        b:SetText("|cffffffff" .. label:upper() .. "|r")
    end
    -- StyleButton's hover/leave hooks reset _flatBg to buttonNormal; re-assert accent
    -- after them so the primary action stays filled.
    local function fillAccent(b) if b._flatBg then b._flatBg:SetColorTexture(unpack(activeTheme.accent)) end end
    challengeBtn:HookScript("OnEnter", fillAccent)
    challengeBtn:HookScript("OnLeave", fillAccent)
    challengeBtn:HookScript("OnMouseUp", fillAccent)
    PaintChallengeBtn(challengeBtn)
    table.insert(themedElements, {challengeBtn, PaintChallengeBtn})
    ui.challengeBtn = challengeBtn

    function ui:UpdateChallengeButtons()
        PaintChallengeBtn(challengeBtn)
    end

    function ui:UpdateTabDisplay()
        local activeTab = GetActiveTab()

        -- Sync both segmented strips from ui.gameMode (visual only; SetActiveSegment
        -- does not fire onSelect, so this is safe to call from the compact frame /
        -- keybinds / combat-restore paths that mutate ui.gameMode directly).
        ui.tabStrip:SetActiveSegment(activeTab)
        ui.arenaStrip:SetShown(activeTab == "ARENA")
        ui.bgStrip:SetShown(activeTab == "BG")
        if activeTab == "ARENA" then
            ui.arenaStrip:SetActiveSegment(ui.gameMode)
        else
            ui.bgStrip:SetActiveSegment(ui.gameMode)
        end

        ui:RefreshMaps()
    end
    
    function ui:Refresh()
        local charHex = activeTheme.inlineChar
        local bnetHex = activeTheme.inlineBnet

        if ui.RefreshRecentChips then ui:RefreshRecentChips() end

        -- Build opponent stats lookup for W-L display on friend rows
        ui.oppStatsLookup = {}
        if WargamesPlus.GetOpponentStats then
            local oppStats = WargamesPlus.GetOpponentStats()
            for _, s in ipairs(oppStats) do
                ui.oppStatsLookup[s.name] = s
            end
        end

        local data = {}
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then
                local r = info.realmName or ""
                local display = info.name .. (r ~= "" and (" - " .. r) or "")
                table.insert(data, { displayName = "|cff"..charHex..display.."|r", targetName = info.name, realm = r, connected = info.connected })
            end
        end
        for i = 1, (BNGetNumFriends() or 0) do
            local acc = C_BattleNet.GetFriendAccountInfo(i)
            if acc and acc.gameAccountInfo then
                local ga = acc.gameAccountInfo
                local char = ga.characterName
                local r = ga.realmName or ""
                local bTag = acc.battleTag
                -- Only include friends actively in retail WoW (wowProjectID 1)
                local isRetail = ga.wowProjectID == 1
                if char and ga.isOnline and isRetail then
                    local display = "|cff"..bnetHex..(acc.accountName or bTag).."|r (|cff"..charHex..char..(r ~= "" and (" - "..r) or "").."|r)"
                    -- Build realm-qualified whisper name for cross-realm friends
                    local whisperName = char
                    if r ~= "" then
                        whisperName = char .. "-" .. r:gsub("%s+", "")
                    end
                    -- Only same-faction friends can receive addon whispers
                    local playerFaction = UnitFactionGroup("player")
                    local canWhisper = (ga.factionName == nil or ga.factionName == playerFaction)
                    table.insert(data, { displayName = display, targetName = char, whisperName = whisperName, realm = r, battleTag = bTag, connected = ga.isOnline, canWhisper = canWhisper })
                end
            end
        end
        -- Ping online friends for addon detection (rate-limited per friend in PingForAddon)
        -- Only ping when UI is freshly shown, not on every Refresh (e.g., search keystrokes)
        if WargamesPlus.PingForAddon and ui._doPing then
            ui._doPing = false
            for _, d in ipairs(data) do
                if d.connected and d.targetName and d.canWhisper ~= false then
                    WargamesPlus.PingForAddon(d.whisperName or d.targetName)
                end
            end
            -- Party-based ping for cross-faction groupmates
            if WargamesPlus.BroadcastPresence then
                WargamesPlus.BroadcastPresence()
            end
        end

        if ui.filterText and ui.filterText ~= "" then
            local f = {}
            local s = ui.filterText:lower()
            for _, d in ipairs(data) do
                local matchName = d.targetName and d.targetName:lower():find(s, 1, true)
                local matchRealm = d.realm and d.realm:lower():find(s, 1, true)
                local matchBTag = d.battleTag and d.battleTag:lower():find(s, 1, true)
                if matchName or matchRealm or matchBTag then 
                    table.insert(f, d) 
                end
            end
            data = f
        end
        if ui.filterMode == "favorites" then
            local f2 = {}
            for _, d in ipairs(data) do
                if WG_History.favFriends[d.targetName] then table.insert(f2, d) end
            end
            data = f2
        elseif ui.filterMode == "online" then
            local f2 = {}
            for _, d in ipairs(data) do
                if d.connected then table.insert(f2, d) end
            end
            data = f2
        end
        table.sort(data, function(a, b)
            local aFav = WG_History.favFriends[a.targetName] and true or false
            local bFav = WG_History.favFriends[b.targetName] and true or false
            if aFav ~= bFav then return aFav end
            if a.connected ~= b.connected then return a.connected end
            return a.targetName < b.targetName
        end)
        local needsScroll = FauxScrollFrame_Update(WG_RosterScroll, #data, 18, 28)
        local rosterBar = _G["WG_RosterScrollScrollBar"]
        if rosterBar then
            if needsScroll then rosterBar:Show() else rosterBar:Hide() end
        end
        local o = FauxScrollFrame_GetOffset(WG_RosterScroll)
        for i = 1, 18 do
            local r = ui.rows[i]
            local d = data[i+o]
            if d then
                r:Show(); r.friend = d
                local prefix = WG_History.favFriends[d.targetName] and FavIcon() or ""
                local displayStr = prefix .. d.displayName
                -- Append W-L record if match history exists
                local oppS = ui.oppStatsLookup[d.targetName]
                if oppS and oppS.total > 0 then
                    displayStr = displayStr .. "  |cff" .. activeTheme.inlineGreen .. oppS.wins .. "W|r-|cff" .. activeTheme.inlineLoss .. oppS.losses .. "L|r"
                end
                -- Addon detection indicator (after stats, right side)
                if HasAddonDetected(d.whisperName or d.targetName) or HasAddonDetected(d.targetName) then
                    displayStr = displayStr .. "  |cff" .. activeTheme.inlineAccent .. L["ADDON_DETECTED"] .. "|r"
                end
                r.nameText:SetText(displayStr)
            else r:Hide() end
        end
    end

    WG_RosterScroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 28, function() ui:Refresh() end) end)
    StyleScrollBar(WG_RosterScroll)

    ui:SetScript("OnShow", function(self)
        self._doPing = true  -- trigger addon detection pings on next Refresh
    end)

    UpdateSpectatorUI()
    ui:UpdateChallengeButtons()
    ui:UpdateTabDisplay(); ui:Hide(); F.ui = ui
    WargamesPlus.mainFrame = ui
end

-- ---------- SETTINGS PANEL ----------
local settingsFrame

local function CreateSettingsFrame()
    local mainFrame = WargamesPlus.mainFrame
    if not mainFrame then return end

    local f = CreateFrame("Frame", "WG_SettingsFrame", mainFrame)
    f:SetSize(330, 540)
    f:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, 0)
    f:SetFrameStrata("HIGH")
    ApplyModernStyle(f)

    -- Accent stripe
    local stripe = f:CreateTexture(nil, "ARTWORK")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", -1, -1)
    stripe:SetColorTexture(unpack(activeTheme.accent))
    table.insert(themedElements, {stripe, function(tex) tex:SetColorTexture(unpack(activeTheme.accent)) end})

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(ADDON_FONT, 13, "OUTLINE")
    f.title:SetPoint("TOPLEFT", 15, -12)
    f.title:SetText("SETTINGS")
    f.title:SetTextColor(unpack(activeTheme.titleColor))
    table.insert(themedElements, {f.title, function(fs) fs:SetTextColor(unpack(activeTheme.titleColor)) end})

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn.label = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.label:SetFont(ADDON_FONT, 13, "OUTLINE")
    closeBtn.label:SetPoint("CENTER", 0, 0)
    closeBtn.label:SetText("X")
    closeBtn.label:SetTextColor(unpack(activeTheme.closeNormal))
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:HookScript("OnEnter", function() closeBtn.label:SetTextColor(unpack(activeTheme.closeHover)) end)
    closeBtn:HookScript("OnLeave", function() closeBtn.label:SetTextColor(unpack(activeTheme.closeNormal)) end)
    table.insert(themedElements, {closeBtn, function(c) c.label:SetTextColor(unpack(activeTheme.closeNormal)) end})

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 8)
    StyleScrollBar(scrollFrame)

    local CONTENT_WIDTH = 300
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CONTENT_WIDTH, 1) -- height set dynamically
    scrollFrame:SetScrollChild(content)

    local yOff = -8

    -- ====== HELPER: Section Header ======
    local function CreateSectionHeader(text)
        yOff = yOff - 4 -- extra breathing room before separator
        local sep = content:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("LEFT", 10, 0)
        sep:SetPoint("RIGHT", -10, 0)
        sep:SetPoint("TOP", 0, yOff)
        sep:SetColorTexture(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 0.2)
        table.insert(themedElements, {sep, function(tex)
            tex:SetColorTexture(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 0.2)
        end})
        yOff = yOff - 10

        local label = content:CreateFontString(nil, "OVERLAY")
        label:SetFont(ADDON_FONT, 10, "OUTLINE")
        label:SetPoint("TOPLEFT", 12, yOff)
        label:SetText(text)
        label:SetTextColor(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 1)
        table.insert(themedElements, {label, function(fs)
            fs:SetTextColor(activeTheme.accent[1], activeTheme.accent[2], activeTheme.accent[3], 1)
        end})
        yOff = yOff - 20
    end

    -- ====== HELPER: Toggle row ======
    local function CreateCheckbox(label, savedKey, onChange)
        local sw = CreateToggleSwitch(content, {
            checked = WG_History[savedKey] and true or false,
            onChange = function(checked)
                WG_History[savedKey] = checked
                if onChange then onChange(checked) end
            end,
        })
        sw:SetPoint("TOPLEFT", 12, yOff)

        local text = content:CreateFontString(nil, "OVERLAY")
        text:SetFont(ADDON_FONT, 10)
        text:SetPoint("LEFT", sw, "RIGHT", 8, 0)
        text:SetText(label)
        text:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {text, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

        yOff = yOff - 26
        return sw
    end

    -- ====== HELPER: Segmented (pill) setting ======
    local function CreateSegmentedSetting(label, savedKey, options, onChange)
        local lbl = content:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ADDON_FONT, 10)
        lbl:SetPoint("TOPLEFT", 12, yOff)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {lbl, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

        local segs = {}
        for _, opt in ipairs(options) do segs[#segs + 1] = {key = opt, label = opt} end
        local strip = CreateSegmentedControl(content, segs, {
            height = 20, fontSize = 10, padX = 10,
            onSelect = function(v)
                WG_History[savedKey] = v
                if onChange then onChange(v) end
            end,
        })
        strip:SetPoint("TOPLEFT", 90, yOff + 1)
        strip:SetActiveSegment(WG_History[savedKey] or options[1])
        yOff = yOff - 28
        return strip
    end

    -- ====== HELPER: Slider ======
    local function CreateSettingsSlider(label, savedKey, minVal, maxVal, step, suffix, onChange)
        local sliderLabel = content:CreateFontString(nil, "OVERLAY")
        sliderLabel:SetFont(ADDON_FONT, 10)
        sliderLabel:SetPoint("TOPLEFT", 12, yOff)
        sliderLabel:SetText(label)
        sliderLabel:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {sliderLabel, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})
        yOff = yOff - 16

        local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        slider:SetSize(160, 16)
        slider:SetPoint("TOPLEFT", 20, yOff)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(WG_History[savedKey] or minVal)

        -- Theme the slider track
        if not slider.SetBackdrop then Mixin(slider, BackdropTemplateMixin) end
        slider:SetBackdrop(FLAT_BACKDROP)
        slider:SetBackdropColor(unpack(activeTheme.inputBg))
        slider:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
        table.insert(themedElements, {slider, function(s)
            s:SetBackdropColor(unpack(activeTheme.inputBg))
            s:SetBackdropBorderColor(unpack(activeTheme.inputBorder))
        end})

        -- Hide default min/max text
        local sliderName = slider:GetName()
        if sliderName then
            local low = _G[sliderName .. "Low"]
            local high = _G[sliderName .. "High"]
            local txt = _G[sliderName .. "Text"]
            if low then low:SetText("") end
            if high then high:SetText("") end
            if txt then txt:SetText("") end
        end

        -- Value label
        local valLabel = content:CreateFontString(nil, "OVERLAY")
        valLabel:SetFont(ADDON_FONT, 10, "OUTLINE")
        valLabel:SetPoint("LEFT", slider, "RIGHT", 8, 0)
        valLabel:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {valLabel, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

        local function UpdateLabel(val)
            valLabel:SetText(tostring(math.floor(val + 0.5)) .. (suffix or ""))
        end
        UpdateLabel(slider:GetValue())

        slider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val + 0.5)
            UpdateLabel(val)
            WG_History[savedKey] = val
            if onChange then onChange(val) end
        end)

        yOff = yOff - 28
        return slider
    end

    -- ====== HELPER: Dropdown (UIDropDownMenuTemplate) ======
    local ddCount = 0
    local function CreateDropdownSetting(label, savedKey, options, onChange)
        ddCount = ddCount + 1

        local ddLabel = content:CreateFontString(nil, "OVERLAY")
        ddLabel:SetFont(ADDON_FONT, 10)
        ddLabel:SetPoint("TOPLEFT", 12, yOff)
        ddLabel:SetText(label)
        ddLabel:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {ddLabel, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})

        local dd = CreateFrame("Frame", "WG_SettingsDrop" .. ddCount, content, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", content, "TOPLEFT", 70, yOff + 2)
        UIDropDownMenu_SetWidth(dd, 120)
        UIDropDownMenu_SetText(dd, WG_History[savedKey] or options[1])
        StyleDropdown(dd)

        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, opt in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt
                info.func = function()
                    WG_History[savedKey] = opt
                    UIDropDownMenu_SetText(dd, opt)
                    CloseDropDownMenus()
                    if onChange then onChange(opt) end
                end
                info.checked = (WG_History[savedKey] == opt)
                UIDropDownMenu_AddButton(info)
            end
        end)

        yOff = yOff - 32
        return dd
    end

    -- ==========================================
    -- GENERAL
    -- ==========================================
    CreateSectionHeader("GENERAL")

    -- ====== THEME PICKER (preset cards + Custom) ======
    do
        local pickerLabel = content:CreateFontString(nil, "OVERLAY")
        pickerLabel:SetFont(ADDON_FONT, 10)
        pickerLabel:SetPoint("TOPLEFT", 12, yOff)
        pickerLabel:SetText(L["THEME_LABEL"])
        pickerLabel:SetTextColor(unpack(activeTheme.normalText))
        table.insert(themedElements, {pickerLabel, function(fs) fs:SetTextColor(unpack(activeTheme.normalText)) end})
        yOff = yOff - 18

        local presets = { "Midnight", "Horde", "Alliance" }
        local cards = {}
        local gap, cardW, cardH = 6, 78, 44

        local function ApplyCardVisual(c)
            local sel = (WG_History.theme == c._theme)
            c:SetBackdropColor(unpack(activeTheme.cardBg))
            c:SetBackdropBorderColor(unpack(sel and activeTheme.accent or activeTheme.cardBorder))
            c._name:SetTextColor(unpack(sel and activeTheme.titleColor or activeTheme.footerColor))
        end

        local customBtn  -- fwd decl

        local function SelectTheme(name)
            ApplyTheme(name)
            for _, c in ipairs(cards) do ApplyCardVisual(c) end
            if customBtn then
                customBtn._sel:SetShown(name == "Custom")
                customBtn._txt:SetTextColor(unpack(name == "Custom" and activeTheme.titleColor or activeTheme.footerColor))
            end
            if F.ui and F.ui.customEditor then
                if name == "Custom" then
                    F.ui.customEditor:Show(); F.ui.customEditor:RefreshSwatches()
                else
                    F.ui.customEditor:Hide()
                end
            end
        end
        f._refreshThemePicker = function()
            for _, c in ipairs(cards) do ApplyCardVisual(c) end
            if customBtn then
                customBtn._sel:SetShown(WG_History.theme == "Custom")
                customBtn._txt:SetTextColor(unpack(WG_History.theme == "Custom" and activeTheme.titleColor or activeTheme.footerColor))
            end
        end

        for i, name in ipairs(presets) do
            local th = THEMES[name] or THEMES.Midnight
            local card = CreateFrame("Button", nil, content, "BackdropTemplate")
            card:SetSize(cardW, cardH)
            card:SetPoint("TOPLEFT", 12 + (i - 1) * (cardW + gap), yOff)
            card:SetBackdrop(FLAT_BACKDROP)
            card._theme = name

            local bgSw = card:CreateTexture(nil, "ARTWORK")
            bgSw:SetPoint("TOPLEFT", 6, -6)
            bgSw:SetSize(cardW - 12 - 14 - 3, 14)
            bgSw:SetColorTexture(unpack(th.backdropBg))

            local accSw = card:CreateTexture(nil, "ARTWORK")
            accSw:SetPoint("TOPRIGHT", -6, -6)
            accSw:SetSize(14, 14)
            accSw:SetColorTexture(unpack(th.accent))

            local nm = card:CreateFontString(nil, "OVERLAY")
            nm:SetFont(ADDON_FONT, 10)
            nm:SetPoint("BOTTOMLEFT", 6, 6)
            nm:SetText(name)
            card._name = nm

            card:SetScript("OnClick", function() SelectTheme(name) end)
            table.insert(themedElements, {card, ApplyCardVisual})
            ApplyCardVisual(card)
            cards[i] = card
        end
        yOff = yOff - (cardH + 6)

        -- Custom row (full width, toggles the floating swatch editor)
        customBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
        customBtn:SetSize(cardW * 3 + gap * 2, 22)
        customBtn:SetPoint("TOPLEFT", 12, yOff)
        customBtn:SetBackdrop(FLAT_BACKDROP)
        customBtn:SetBackdropColor(unpack(activeTheme.cardBg))
        customBtn:SetBackdropBorderColor(unpack(activeTheme.cardBorder))

        local cSel = customBtn:CreateTexture(nil, "ARTWORK")
        cSel:SetPoint("TOPLEFT", 1, -1)
        cSel:SetPoint("BOTTOMLEFT", 1, 1)
        cSel:SetWidth(3)
        cSel:SetColorTexture(unpack(activeTheme.accent))
        cSel:Hide()
        customBtn._sel = cSel

        local cTxt = customBtn:CreateFontString(nil, "OVERLAY")
        cTxt:SetFont(ADDON_FONT, 10)
        cTxt:SetPoint("LEFT", 10, 0)
        cTxt:SetText(L["CUSTOM_THEME"])
        cTxt:SetTextColor(unpack(activeTheme.footerColor))
        customBtn._txt = cTxt

        customBtn:SetScript("OnClick", function() SelectTheme("Custom") end)
        table.insert(themedElements, {customBtn, function(c)
            c:SetBackdropColor(unpack(activeTheme.cardBg))
            c:SetBackdropBorderColor(unpack(activeTheme.cardBorder))
            c._sel:SetColorTexture(unpack(activeTheme.accent))
        end})
        f._refreshThemePicker()

        yOff = yOff - 30
    end

    CreateCheckbox("Show Minimap Button", "showMinimap", function(checked)
        if F.minimapBtn then
            if checked then F.minimapBtn:Show() else F.minimapBtn:Hide() end
        end
    end)

    CreateSettingsSlider("Max Match History:", "maxRecords", 50, 1000, 50, "", nil)
    CreateSettingsSlider("UI Scale:", "uiScale", 90, 150, 5, "%", function()
        if WargamesPlus.RefreshUIScale then WargamesPlus.RefreshUIScale() end
    end)
    CreateDropdownSetting(L["FONT_LABEL"], "font", WargamesPlus.FONT_ORDER or { "Friz Quadrata" }, function()
        print("|cff" .. activeTheme.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["FONT_RELOAD_HINT"])
    end)

    -- ==========================================
    -- CHAT & NOTIFICATIONS
    -- ==========================================
    CreateSectionHeader("CHAT & NOTIFICATIONS")

    CreateCheckbox("Match Result Messages", "showMatchChat", nil)
    CreateCheckbox("Nemesis / Rival Messages", "showNemesisChat", nil)

    -- ==========================================
    -- VETO
    -- ==========================================
    CreateSectionHeader("VETO")

    CreateSettingsSlider("Bans Per Player:", "bansPerPlayer", 1, 5, 1, "", nil)
    CreateSettingsSlider("Turn Timer:", "vetoTurnTimer", 10, 60, 5, "s", nil)
    CreateSegmentedSetting("Default Format:", "vetoFormat", {"Bo1", "Bo3", "Bo5"}, nil)

    -- ==========================================
    -- LFG
    -- ==========================================
    CreateSectionHeader(L["LFG_SETTINGS_HEADER"])

    CreateCheckbox(L["LFG_ENABLED"], "lfgEnabled", nil)

    -- Manage hidden posters button + inline list (shown on click)
    local manageBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    manageBtn:SetSize(160, 22)
    manageBtn:SetPoint("TOPLEFT", 20, yOff)
    manageBtn:SetText(L["LFG_MANAGE_IGNORED"])
    StyleButton(manageBtn)
    yOff = yOff - 28

    local ignoreList = CreateFrame("Frame", nil, content, "BackdropTemplate")
    ignoreList:SetPoint("TOPLEFT", 20, yOff)
    ignoreList:SetSize(230, 4)  -- grows on populate
    ignoreList:Hide()
    ApplyModernStyle(ignoreList)

    local function RebuildIgnoreList()
        -- Clear old children
        if ignoreList.rows then
            for _, r in ipairs(ignoreList.rows) do r:Hide() end
        end
        ignoreList.rows = ignoreList.rows or {}

        local keys = (WargamesPlus.LFG_GetIgnoreList and WargamesPlus.LFG_GetIgnoreList()) or {}
        local h = 28
        if #keys == 0 then
            if not ignoreList.emptyText then
                ignoreList.emptyText = ignoreList:CreateFontString(nil, "OVERLAY")
                ignoreList.emptyText:SetFont(ADDON_FONT, 10)
                ignoreList.emptyText:SetPoint("TOPLEFT", 8, -8)
                ignoreList.emptyText:SetTextColor(0.7, 0.7, 0.7, 1)
            end
            ignoreList.emptyText:SetText(L["LFG_IGNORED_EMPTY"])
            ignoreList.emptyText:Show()
            h = 28
        else
            if ignoreList.emptyText then ignoreList.emptyText:Hide() end
            for i, key in ipairs(keys) do
                local row = ignoreList.rows[i]
                if not row then
                    row = CreateFrame("Frame", nil, ignoreList)
                    row:SetSize(220, 22)
                    row.text = row:CreateFontString(nil, "OVERLAY")
                    row.text:SetFont(ADDON_FONT, 10)
                    row.text:SetPoint("LEFT", 8, 0)
                    row.text:SetWidth(140)
                    row.text:SetJustifyH("LEFT")
                    row.text:SetTextColor(unpack(activeTheme.normalText))
                    row.btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.btn:SetSize(60, 18)
                    row.btn:SetPoint("RIGHT", -6, 0)
                    row.btn:SetText(L["LFG_IGNORED_UNHIDE"])
                    StyleButton(row.btn)
                    ignoreList.rows[i] = row
                end
                row:SetPoint("TOPLEFT", 4, -(i - 1) * 22 - 4)
                row.text:SetText(key)
                row.btn:SetScript("OnClick", function()
                    if WargamesPlus.LFG_UnignorePoster then
                        WargamesPlus.LFG_UnignorePoster(key)
                    end
                    RebuildIgnoreList()
                end)
                row:Show()
            end
            h = #keys * 22 + 10
        end
        ignoreList:SetHeight(h)
    end

    manageBtn:SetScript("OnClick", function()
        if ignoreList:IsShown() then
            ignoreList:Hide()
        else
            RebuildIgnoreList()
            ignoreList:Show()
        end
    end)

    -- Reserve vertical space for the expanded ignore list. The list grows to
    -- #keys * 22 + 10 px; reserving 200px covers ~8 entries without reflowing
    -- the sections below (this is a scrollable panel so blank space is harmless).
    yOff = yOff - 200

    -- ==========================================
    -- MATCH TRACKING
    -- ==========================================
    CreateSectionHeader("MATCH TRACKING")

    CreateCheckbox("Enable Match Tracking", "trackMatches", nil)
    CreateCheckbox("Tournament Rules Default", "tournamentRules", nil)

    -- ==========================================
    -- RESET TO DEFAULTS
    -- ==========================================
    yOff = yOff - 12
    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 24)
    resetBtn:SetPoint("TOP", content, "TOP", 0, yOff)
    resetBtn:SetText("Reset to Defaults")
    StyleButton(resetBtn)
    resetBtn:SetScript("OnClick", function()
        WG_History.showMinimap = true
        WG_History.maxRecords = 200
        WG_History.showMatchChat = true
        WG_History.showNemesisChat = true
        WG_History.bansPerPlayer = 2
        WG_History.vetoTurnTimer = 30
        WG_History.vetoFormat = "Bo1"
        WG_History.trackMatches = true
        WG_History.tournamentRules = false
        ApplyTheme("Horde")
        -- Rebuild settings panel with fresh values
        if F.minimapBtn then F.minimapBtn:Show() end
        f:Hide()
        settingsFrame = nil
        WargamesPlus.settingsFrame = nil
        f:SetParent(nil)
    end)
    yOff = yOff - 32

    -- Set content height
    content:SetHeight(math.abs(yOff) + 10)

    -- Refresh dropdown text on theme change
    function f:OnThemeChanged()
        if self._refreshThemePicker then self._refreshThemePicker() end
    end

    settingsFrame = f
    WargamesPlus.settingsFrame = f
end

-- The big "info" panels (Settings / Match History / LFG / Advanced Stats) share the
-- space around the main window; only one shows at a time so they never overlap.
-- Flow windows (Veto / Ready Check / Slaughterhouse) are self-guarding and excluded.
local SECONDARY_WINDOWS = { "WG_SettingsFrame", "WG_StatsFrame", "WG_LFGFrame", "WG_AdvancedStatsFrame" }
function WargamesPlus.CloseSecondaryWindows(except)
    for _, name in ipairs(SECONDARY_WINDOWS) do
        if name ~= except then
            local frame = _G[name]
            if frame and frame:IsShown() then frame:Hide() end
        end
    end
end

function WargamesPlus.ToggleSettingsFrame()
    if not WargamesPlus.mainFrame then return end
    if not settingsFrame then
        CreateSettingsFrame()
        if not settingsFrame then return end
        WargamesPlus.CloseSecondaryWindows("WG_SettingsFrame")
        settingsFrame:Show()
        return
    end

    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        WargamesPlus.CloseSecondaryWindows("WG_SettingsFrame")
        settingsFrame:Show()
    end
end

-- ---------- COMPACT MODE ----------
function F:CreateCompactFrame()
    if F.compactFrame then return end

    local cf = CreateFrame("Frame", "WG_CompactFrame", UIParent)
    cf:SetSize(480, 120)
    cf:SetFrameStrata("DIALOG")
    cf:SetFrameLevel(50)
    cf:SetClipsChildren(false)
    cf:SetMovable(true)
    cf:EnableMouse(true)
    cf:RegisterForDrag("LeftButton")
    cf:SetScript("OnDragStart", cf.StartMoving)
    cf:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        WG_History.compactPos = {point = point, relPoint = relPoint, x = x, y = y}
    end)
    ApplyModernStyle(cf)
    WargamesPlus.ApplyUIScale(cf)

    -- Accent stripe (matches the War Room window chrome)
    local cfStripe = cf:CreateTexture(nil, "ARTWORK")
    cfStripe:SetHeight(2)
    cfStripe:SetPoint("TOPLEFT", 1, -1)
    cfStripe:SetPoint("TOPRIGHT", -1, -1)
    cfStripe:SetColorTexture(unpack(activeTheme.accent))
    table.insert(themedElements, {cfStripe, function(t) t:SetColorTexture(unpack(activeTheme.accent)) end})

    -- Restore saved position or default
    if WG_History.compactPos then
        local p = WG_History.compactPos
        cf:SetPoint(p.point or "TOP", UIParent, p.relPoint or "TOP", p.x or 0, p.y or -100)
    else
        cf:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end

    -- Logo badge + wordmark
    local cfLogo = CreateFrame("Frame", nil, cf, "BackdropTemplate")
    cfLogo:SetSize(18, 18)
    cfLogo:SetPoint("TOPLEFT", 10, -8)
    cfLogo:SetBackdrop(FLAT_BACKDROP)
    cfLogo:SetBackdropColor(unpack(activeTheme.accent))
    cfLogo:SetBackdropBorderColor(unpack(activeTheme.accent))
    local cfGlyph = cfLogo:CreateFontString(nil, "OVERLAY")
    cfGlyph:SetFont(ADDON_FONT, 11, "OUTLINE")
    cfGlyph:SetPoint("CENTER")
    cfGlyph:SetText("W")
    cfGlyph:SetTextColor(unpack(activeTheme.backdropBg))
    table.insert(themedElements, {cfLogo, function(f)
        f:SetBackdropColor(unpack(activeTheme.accent)); f:SetBackdropBorderColor(unpack(activeTheme.accent))
        cfGlyph:SetTextColor(unpack(activeTheme.backdropBg))
    end})

    local cfTitle = cf:CreateFontString(nil, "OVERLAY")
    cfTitle:SetFont(ADDON_FONT, 12, "OUTLINE")
    cfTitle:SetPoint("LEFT", cfLogo, "RIGHT", 7, 0)
    cfTitle:SetText("WARGAMES+")
    cfTitle:SetTextColor(unpack(activeTheme.titleColor))
    table.insert(themedElements, {cfTitle, function(fs) fs:SetTextColor(unpack(activeTheme.titleColor)) end})

    -- Expand button (top-right)
    local expandBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    expandBtn:SetSize(68, 22)
    expandBtn:SetPoint("TOPRIGHT", -8, -6)
    expandBtn:SetText(L["EXPAND"] or "Expand")
    expandBtn:GetFontString():SetFont(ADDON_FONT, 10.5, "OUTLINE")
    StyleButton(expandBtn)
    expandBtn:SetScript("OnClick", function()
        cf:Hide()
        WargamesPlus.ShowMainFrame()
    end)

    -- Spectate toggle switch (left of Expand). UpdateCompactSpectate is defined further
    -- down; forward-declare so the toggle's onChange can reach it.
    local UpdateCompactSpectate
    local specToggle = CreateToggleSwitch(cf, {
        checked = WG_History.spectatorMode or false,
        onChange = function(checked)
            WG_History.spectatorMode = checked
            if UpdateCompactSpectate then UpdateCompactSpectate() end
            PlaySound(856)
        end,
    })
    specToggle:SetPoint("RIGHT", expandBtn, "LEFT", -34, 0)
    local specLabel = cf:CreateFontString(nil, "OVERLAY")
    specLabel:SetFont(ADDON_FONT, 10)
    specLabel:SetText(L["SPECTATE_MODE"])
    specLabel:SetPoint("RIGHT", specToggle, "LEFT", -4, 0)
    specLabel:SetTextColor(unpack(activeTheme.footerColor))
    table.insert(themedElements, {specLabel, function(fs) fs:SetTextColor(unpack(activeTheme.footerColor)) end})
    cf.specToggle = specToggle

    -- Leader 2 row (shown only in spectator mode)
    local opp2Label = cf:CreateFontString(nil, "OVERLAY")
    opp2Label:SetFont(ADDON_FONT, 10)
    opp2Label:SetPoint("TOPLEFT", 10, -68)
    opp2Label:SetText(L["LEADER_2"])
    opp2Label:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {opp2Label, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})

    local opp2Input = CreateFrame("EditBox", nil, cf, "InputBoxTemplate")
    opp2Input:SetSize(238, 24)
    opp2Input:SetPoint("LEFT", opp2Label, "RIGHT", 5, 0)
    opp2Input:SetAutoFocus(false)
    StyleInput(opp2Input)
    cf.opp2Input = opp2Input

    local target2Btn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    target2Btn:SetSize(55, 24)
    target2Btn:SetPoint("LEFT", opp2Input, "RIGHT", 4, 0)
    target2Btn:SetText(L["TARGET"])
    target2Btn:GetFontString():SetFont(ADDON_FONT, 9)
    StyleButton(target2Btn)
    target2Btn:SetScript("OnClick", function()
        if not UnitExists("target") then return end
        local name, realm = GetUnitName("target", true)
        local fullName = GetFormattedName(name, realm)
        if fullName then opp2Input:SetText(fullName) end
    end)

    -- Hide spectator elements initially
    opp2Label:Hide(); opp2Input:Hide(); target2Btn:Hide()

    UpdateCompactSpectate = function()
        local isSpec = WG_History.spectatorMode or false
        if isSpec then
            cf:SetHeight(150)
            opp2Label:Show(); opp2Input:Show(); target2Btn:Show()
            if cf.oppLabel then cf.oppLabel:SetText(L["LEADER_1"]) end
        else
            cf:SetHeight(120)
            opp2Label:Hide(); opp2Input:Hide(); target2Btn:Hide()
            if cf.oppLabel then cf.oppLabel:SetText(L["TARGET"] .. ":") end
        end
        cf.specToggle:SetChecked(isSpec)
        if cf.PaintCompactSend then cf.PaintCompactSend() end
        -- Sync to main UI
        CreateUI()
        if F.ui then
            F.ui.spectatorMode = isSpec
        end
    end
    cf.UpdateCompactSpectate = UpdateCompactSpectate

    -- Row 1: Opponent input + Target button
    local oppLabel = cf:CreateFontString(nil, "OVERLAY")
    oppLabel:SetFont(ADDON_FONT, 10)
    oppLabel:SetPoint("TOPLEFT", 10, -38)
    oppLabel:SetText(L["TARGET"] .. ":")
    oppLabel:SetTextColor(unpack(activeTheme.headerColor))
    table.insert(themedElements, {oppLabel, function(fs) fs:SetTextColor(unpack(activeTheme.headerColor)) end})
    cf.oppLabel = oppLabel

    local oppInput = CreateFrame("EditBox", nil, cf, "InputBoxTemplate")
    oppInput:SetSize(238, 24)
    oppInput:SetPoint("LEFT", oppLabel, "RIGHT", 5, 0)
    oppInput:SetAutoFocus(false)
    StyleInput(oppInput)
    cf.oppInput = oppInput

    -- Sync compact input -> main UI input
    oppInput:SetScript("OnTextChanged", function(self)
        if F.ui and F.ui.editBox then
            F.ui.editBox:SetText(self:GetText())
        end
    end)

    local targetBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    targetBtn:SetSize(55, 24)
    targetBtn:SetPoint("LEFT", oppInput, "RIGHT", 4, 0)
    targetBtn:SetText(L["TARGET"])
    targetBtn:GetFontString():SetFont(ADDON_FONT, 9)
    StyleButton(targetBtn)
    targetBtn:SetScript("OnClick", function()
        if not UnitExists("target") then return end
        local name, realm = GetUnitName("target", true)
        local fullName = GetFormattedName(name, realm)
        if fullName then oppInput:SetText(fullName) end
    end)

    -- Row 2: Mode dropdown + Map dropdown + Send button
    local modeDrop = CreateFrame("Frame", "WG_CompactModeDrop", cf, "UIDropDownMenuTemplate")
    modeDrop:SetPoint("BOTTOMLEFT", -8, 4)
    UIDropDownMenu_SetWidth(modeDrop, 80)
    StyleDropdown(modeDrop)
    cf.modeDrop = modeDrop

    UIDropDownMenu_Initialize(modeDrop, function(self, level)
        local modes = {
            {id = "ARENA_2V2", label = GAME_MODES.ARENA_2V2.label},
            {id = "ARENA_3V3", label = GAME_MODES.ARENA_3V3.label},
            {id = "ARENA_5V5", label = GAME_MODES.ARENA_5V5.label},
            {id = "SOLO_SHUFFLE", label = GAME_MODES.SOLO_SHUFFLE.label},
            {id = "BG", label = GAME_MODES.BG.label},
            {id = "BLITZ", label = GAME_MODES.BLITZ.label},
        }
        for _, m in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = m.label
            info.func = function()
                CreateUI()
                if F.ui then
                    F.ui.gameMode = m.id
                    local gm = GAME_MODES[m.id]
                    if gm.tab == "ARENA" then F.ui.lastArenaMode = m.id
                    else F.ui.lastBGMode = m.id end
                end
                UIDropDownMenu_SetText(modeDrop, m.label)
                F:RefreshCompactMapDrop()
                CloseDropDownMenus()
            end
            info.checked = (F.ui and F.ui.gameMode == m.id)
            UIDropDownMenu_AddButton(info)
        end
    end)

    local mapDrop = CreateFrame("Frame", "WG_CompactMapDrop", cf, "UIDropDownMenuTemplate")
    mapDrop:SetPoint("LEFT", modeDrop, "RIGHT", -15, 0)
    UIDropDownMenu_SetWidth(mapDrop, 120)
    StyleDropdown(mapDrop)
    cf.mapDrop = mapDrop

    local function InitMapDropdown()
        UIDropDownMenu_Initialize(mapDrop, function(self, level)
            CreateUI()
            if not F.ui then return end
            local gm = GAME_MODES[F.ui.gameMode]
            local mapMode = gm and gm.mapMode or "ARENA"
            local mapList = GetSortedMapList(mapMode)
            for _, mapName in ipairs(mapList) do
                if not WG_History.excluded[mapName] or mapName == "Random Map" then
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = mapName
                    info.func = function()
                        if mapMode == "ARENA" then F.ui.selectedArena = mapName
                        elseif mapMode == "BLITZ" then F.ui.selectedBlitz = mapName
                        else F.ui.selectedBG = mapName end
                        UIDropDownMenu_SetText(mapDrop, mapName)
                        CloseDropDownMenus()
                    end
                    local sel
                    if mapMode == "ARENA" then sel = F.ui.selectedArena
                    elseif mapMode == "BLITZ" then sel = F.ui.selectedBlitz
                    else sel = F.ui.selectedBG end
                    info.checked = (mapName == sel)
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)
    end
    InitMapDropdown()

    -- Send button — primary accent-filled action (mirrors the main window)
    local sendBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    sendBtn:SetSize(118, 26)
    sendBtn:SetPoint("BOTTOMRIGHT", -8, 6)
    sendBtn._hasInlineColor = true
    StyleButton(sendBtn)
    sendBtn:GetFontString():SetFont(ADDON_FONT, 11, "THINOUTLINE")
    local function PaintCompactSend()
        sendBtn._flatBg:SetColorTexture(unpack(activeTheme.accent))
        sendBtn:SetBackdropBorderColor(unpack(activeTheme.accent))
        local label = (WG_History.spectatorMode) and L["SPECTATE_MATCH"] or L["SEND_CHALLENGE"]
        sendBtn:SetText("|cffffffff" .. label:upper() .. "|r")
    end
    local function fillCompactAccent(b) if b._flatBg then b._flatBg:SetColorTexture(unpack(activeTheme.accent)) end end
    sendBtn:HookScript("OnEnter", fillCompactAccent)
    sendBtn:HookScript("OnLeave", fillCompactAccent)
    sendBtn:HookScript("OnMouseUp", fillCompactAccent)
    PaintCompactSend()
    cf.PaintCompactSend = PaintCompactSend
    table.insert(themedElements, {sendBtn, function(b) PaintCompactSend() end})
    sendBtn:SetScript("OnClick", function()
        CreateUI()
        if F.ui then
            local isSpec = WG_History.spectatorMode or false
            F.ui.spectatorMode = isSpec
            if isSpec then
                -- Sync leader inputs to main UI
                if F.ui.leader1EditBox then
                    F.ui.leader1EditBox:SetText(cf.oppInput:GetText())
                end
                if F.ui.leader2EditBox then
                    F.ui.leader2EditBox:SetText(cf.opp2Input:GetText())
                end
            else
                if F.ui.editBox then
                    F.ui.editBox:SetText(cf.oppInput:GetText())
                end
            end
            if F.ui.challengeBtn then
                F.ui.challengeBtn:Click()
            end
        end
    end)
    cf.sendBtn = sendBtn

    -- Helper to refresh map dropdown when mode changes
    function F:RefreshCompactMapDrop()
        if not F.compactFrame or not F.ui then return end
        local gm = GAME_MODES[F.ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        local sel
        if mapMode == "ARENA" then sel = F.ui.selectedArena
        elseif mapMode == "BLITZ" then sel = F.ui.selectedBlitz
        else sel = F.ui.selectedBG end
        UIDropDownMenu_SetText(cf.mapDrop, sel or "Random Map")
        InitMapDropdown()
    end

    cf:Hide()
    F.compactFrame = cf
end

function F:RefreshCompact()
    if not F.compactFrame then return end
    local cf = F.compactFrame

    CreateUI()

    -- Sync opponent name from main UI
    local oppName = ""
    if F.ui and F.ui.editBox then
        oppName = F.ui.editBox:GetText():trim()
    end
    if oppName ~= "" then
        cf.oppInput:SetText(oppName)
    end

    -- Sync mode dropdown text
    local modeLabel = ""
    if F.ui and F.ui.gameMode then
        local gm = GAME_MODES[F.ui.gameMode]
        if gm then modeLabel = gm.label end
    end
    UIDropDownMenu_SetText(cf.modeDrop, modeLabel)

    -- Sync map dropdown text
    if F.ui then
        local gm = GAME_MODES[F.ui.gameMode]
        local mapMode = gm and gm.mapMode or "ARENA"
        local sel
        if mapMode == "ARENA" then sel = F.ui.selectedArena
        elseif mapMode == "BLITZ" then sel = F.ui.selectedBlitz
        else sel = F.ui.selectedBG end
        UIDropDownMenu_SetText(cf.mapDrop, sel or "Random Map")
    end

    -- Sync spectate state
    if cf.UpdateCompactSpectate then cf.UpdateCompactSpectate() end
end

-- Switch to the full window from any of the small modes (compact bar / dock).
function WargamesPlus.ShowMainFrame()
    CreateUI()
    if F.compactFrame and F.compactFrame:IsShown() then F.compactFrame:Hide() end
    WG_History.compactMode = false
    if WargamesPlus.dockFrame and WargamesPlus.dockFrame:IsShown() then
        WargamesPlus.dockFrame:Hide()
    elseif _G["WG_DockFrame"] and _G["WG_DockFrame"]:IsShown() then
        _G["WG_DockFrame"]:Hide()
    end
    if F.ui then
        F.ui:Show(); F.ui:Refresh(); F.ui:UpdateTabDisplay()
    end
end

SLASH_WARGAMESPLUS1 = "/war"
SlashCmdList["WARGAMESPLUS"] = function(msg)
    msg = (msg or ""):trim()
    local cmd = msg:lower()
    if cmd == "dock" then
        if WargamesPlus.ToggleDock then WargamesPlus.ToggleDock() end
        return
    end
    if cmd:sub(1, 10) == "debugmatch" then
        if WargamesPlus.DebugMatch then WargamesPlus.DebugMatch(msg:sub(12)) end
        return
    end
    if cmd:sub(1, 7) == "lfgfake" then
        local n = tonumber(msg:match("lfgfake%s*(%d+)")) or 5
        CreateUI()
        if WargamesPlus.LFG_InjectFake then WargamesPlus.LFG_InjectFake(n) end
        if _G.WG_LFGFrame and not _G.WG_LFGFrame:IsShown() then
            if WargamesPlus.ToggleLFGFrame then WargamesPlus.ToggleLFGFrame() end
        end
        return
    end
    if cmd == "lfgclear" then
        if WargamesPlus.LFG_ClearLive then WargamesPlus.LFG_ClearLive() end
        return
    end
    if cmd == "slaughter" or cmd == "sh" then
        if WargamesPlus.ToggleSlaughterHouse then WargamesPlus.ToggleSlaughterHouse() end
        return
    end
    msg = cmd
    CreateUI()
    -- If compact frame is showing, hide it
    if F.compactFrame and F.compactFrame:IsShown() then
        F.compactFrame:Hide()
        WG_History.compactMode = false
        return
    end
    -- If compact mode is saved, restore compact frame
    if WG_History.compactMode then
        F:CreateCompactFrame()
        if F.compactFrame then F.compactFrame:Show(); F:RefreshCompact() end
        return
    end
    -- Normal toggle
    if F.ui:IsShown() then F.ui:Hide() else F.ui:Show(); F.ui:Refresh(); F.ui:UpdateTabDisplay() end
end

F:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Re-run database safety after WoW loads saved variables
        InitDefaults()
        -- Restore lastChallenge for reload recovery (expire if older than 1 hour)
        if WG_History.lastChallenge then
            local elapsed = time() - (WG_History.lastChallenge.timestamp or 0)
            if elapsed > 3600 then
                WG_History.lastChallenge = nil
            else
                WargamesPlus.lastChallenge = WG_History.lastChallenge
            end
        end
        -- Re-derive the real activeTheme (uikit.lua) from persisted WG_History; safe to
        -- route through the shared ApplyTheme here since mainFrame/settingsFrame don't
        -- exist yet at this point in the load sequence, so no premature UI refresh fires.
        WargamesPlus.ApplyTheme(WG_History.theme)
    elseif event == "PLAYER_LOGIN" then
        CreateMinimapButton()
        if WG_History.showMinimap == false and F.minimapBtn then
            F.minimapBtn:Hide()
        end
        -- Auto-show compact frame if compact mode was active
        if WG_History.compactMode then
            CreateUI()
            F:CreateCompactFrame()
            if F.compactFrame then F.compactFrame:Show(); F:RefreshCompact() end
        end
        print(L["ADDON_LOADED"])
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat — hide all visible WG+ frames and remember them
        wipe(combatHiddenFrames)
        local frameNames = {
            "WarGamesPlusUI", "WG_CompactFrame", "WG_DockFrame",
            "WG_StatsFrame", "WG_ProfileCard", "WG_VetoFrame", "WG_HelpFrame", "WG_SettingsFrame",
            "WG_LFGFrame", "WG_SlaughterHouseFrame", "WG_AdvancedStatsFrame",
        }
        for _, name in ipairs(frameNames) do
            local frame = _G[name]
            if frame and frame:IsShown() then
                frame:Hide()
                table.insert(combatHiddenFrames, name)
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat — restore previously hidden frames
        for _, name in ipairs(combatHiddenFrames) do
            local frame = _G[name]
            if frame then
                frame:Show()
            end
        end
        -- Refresh main UI if it was restored
        if F.ui and F.ui:IsShown() then
            F.ui:Refresh()
            F.ui:UpdateTabDisplay()
        end
        if F.compactFrame and F.compactFrame:IsShown() then
            F:RefreshCompact()
        end
        wipe(combatHiddenFrames)
    end
end)

-- ---------- ESC HANDLER: close only the topmost WG frame ----------
do
    -- Priority order: topmost/highest strata first
    local WG_ESC_FRAMES = {
        "WG_AdvancedStatsFrame",
        "WG_HelpFrame",
        "WG_SlaughterHouseFrame",
        "WG_ReadyCheckFrame",
        "WG_VetoFrame",
        "WG_ProfileCard",
        "WG_StatsFrame",
        "WG_LFGFrame",
        "WarGamesPlusUI",
        "WG_CompactFrame",
        "WG_DockFrame",
    }

    local origCloseSpecialWindows = CloseSpecialWindows
    CloseSpecialWindows = function()
        -- Close only the topmost visible WG frame
        for _, name in ipairs(WG_ESC_FRAMES) do
            local frame = _G[name]
            if frame and frame:IsShown() then
                frame:Hide()
                return true
            end
        end
        return origCloseSpecialWindows()
    end
end