local addonName, addonTable = ...
RdyCrateGlobal2 = addonTable
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)

-- Get locale table with proper fallback
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("RdysCrateTracker", true) or {}

if not RdysCrateTracker then
    error(L["ADDON_NOT_FOUND"] or "RdysCrateTracker addon not found. Please ensure it is loaded.")
end


RdysCrateTracker.ALLOWED_CRATE_ZONES = {
    [2248] = true,  -- Isle of Dorn
    [2214] = true,  -- Ringing Deeps
    [2215] = true,  -- Hallowfall
    [2255] = true,  -- Azj-Kahet
    [2346] = true,  -- Undermine
    [2369] = true,  -- Siren Isle
    [2022] = true,  -- Waking Shores
    [2023] = true,  -- Ohn'ahran Plains
    [2024] = true,  -- The Azure Span
    [2025] = true,  -- Thaldraszus
    [2371] = true,  -- K'aresh
    [2405] = true,  -- VoidStorm
    [2413] = true,  -- Harandar
    [2395] = true,  -- EverSong Woods
    [2437] = true,  -- Zul'Aman
    [2537] = true,  -- Quel'thalas
    [2444] = true,  -- Slayer's Rise
}





local NS_ZoneNormalize = {
-- Midnight (12.0)
    [2405] = 2405, -- VoidStorm
    [2444] = 2444, -- Slayers Rise → VoidStorm
    [2413] = 2413, -- Harandar
    [2395] = 2395, -- EverSong Woods
    [2437] = 2437, -- Zul'Aman
    [2536] = 2437, -- ZA
    [2393] = 2395, -- Silvermoon City → EverSong Woods

----------------------------------------------------------------------------
-- THE WAR WITHIN (10.1)

    [2213] = 2255, -- City of Threads → Azj-Kahet
    [2214] = 2214, -- The Ringing Deeps
    [2215] = 2215, -- Hallowfall
    [2216] = 2255, -- Ara-Kara: City of Echoes → Azj-Kahet
    [2248] = 2248, -- Isle of Dorn
    [2255] = 2255, -- Azj-Kahet
    [2328] = 2340, -- The Proscenium → (parent)
    [2339] = 2248, -- Dornogal → Isle of Dorn
    [2346] = 2346, -- Undermine
    [2369] = 2369, -- Siren Isle
    [2371] = 2371, -- K'aresh
    [2472] = 2371, -- Tazavesh → K'aresh
    [2256] = 2255, -- The Echoing City → Azj-Kahet

    ----------------------------------------------------------------------------
    -- DRAGONFLIGHT (10.0)
    ----------------------------------------------------------------------------
    [2022] = 2022, -- The Waking Shores
    [2023] = 2023, -- Ohn'ahran Plains
    [2024] = 2024, -- The Azure Span
    [2025] = 2025, -- Thaldraszus
    [2112] = 2025, -- Valdrakken → Thaldraszus
    [2133] = 2133, -- Zaralek Cavern
    [2151] = 2151, -- Forbidden Reach
    [2200] = 2200, -- Emerald Dream
    [2239] = 2023, -- Bel'ameth → Ohn'ahran Plains

    ----------------------------------------------------------------------------
    -- SHADOWLANDS (9.0)
    ----------------------------------------------------------------------------
    [1525] = 1525, -- Revendreth
    [1533] = 1533, -- Bastion
    [1536] = 1536, -- Maldraxxus
    [1543] = 1543, -- The Maw
    [1550] = 1550, -- Shadowlands
    [1565] = 1565, -- Ardenweald
    [1670] = 1670, -- Oribos
    [1671] = 1670, -- Oribos (portals) → Oribos
    [1961] = 1961, -- Korthia
    [1970] = 1970, -- Zereth Mortis

    ----------------------------------------------------------------------------
    -- BATTLE FOR AZEROTH (8.0)
    ----------------------------------------------------------------------------
    [  62] =   62, -- Darkshore
    [2070] =   18, -- Tirisfal Glades (revamp) → Eastern Kingdoms
    
    -- Zandalar
    [  862] =  862, -- Zuldazar
    [  863] =  863, -- Nazmir
    [  864] =  864, -- Vol'dun
    [1163] = 1165, -- The Great Seal → Dazar'alor
    [1165] = 1165, -- Dazar'alor
    
    -- Kul Tiras
    [  895] =  895, -- Tiragarde Sound
    [  896] =  896, -- Drustvar
    [  942] =  942, -- Stormsong Valley
    [1161] = 1161, -- Boralus
    
    -- Patches
    [1355] = 1355, -- Nazjatar
    [1462] = 1462, -- Mechagon
    [1527] =  249, -- Uldum (8.3) → Uldum
    [1530] =  390, -- Vale of Eternal Blossoms (8.3) → Vale

    ----------------------------------------------------------------------------
    -- LEGION (7.0)
    ----------------------------------------------------------------------------
    [  627] =  627, -- Broken Isles / Dalaran
    [  628] =  627, -- Dalaran → Broken Isles
    [  630] =  630, -- Stormheim
    [  634] =  634, -- Azsuna
    [  641] =  641, -- Val'sharah
    [  646] =  646, -- Highmountain
    [  649] =  650, -- Suramar (sub-zone) → Suramar
    [  650] =  650, -- Suramar
    [  652] =  650, -- Suramar (alias) → Suramar
    [  715] =  641, -- Val'sharah (alias) → Val'sharah
    [  747] =  641, -- Val'sharah (alias) → Val'sharah
    [  750] =  650, -- Suramar (alias) → Suramar
    [  790] =  630, -- Stormheim (alias) → Stormheim
    
    -- Argus
    [  830] =  830, -- Mac'Aree
    [  831] =  830, -- Mac'Aree (alias) → Mac'Aree
    [  882] =  882, -- Antoran Wastes
    [  885] =  885, -- Argus

    ----------------------------------------------------------------------------
    -- WARLORDS OF DRAENOR (6.0)
    ----------------------------------------------------------------------------
    [  525] =  525, -- Frostfire Ridge
    [  535] =  535, -- Talador
    [  539] =  539, -- Shadowmoon Valley (Draenor)
    [  542] =  542, -- Spires of Arak
    [  543] =  543, -- Gorgrond
    [  550] =  550, -- Nagrand (Draenor)
    [  582] =  582, -- Lunarfall / Frostwall
    [  588] =  588, -- Ashran
    [  590] =  590, -- Tanaan Jungle
    [  622] =  622, -- Stormshield
    [  624] =  624, -- Warspear

    ----------------------------------------------------------------------------
    -- MISTS OF PANDARIA (5.0)
    ----------------------------------------------------------------------------
    [  371] =  371, -- The Jade Forest
    [  376] =  376, -- Valley of the Four Winds
    [  379] =  379, -- Kun-Lai Summit
    [  388] =  388, -- Townlong Steppes
    [  390] =  390, -- Vale of Eternal Blossoms
    [  392] =  392, -- Krasarang Wilds
    [  418] =  418, -- Dread Wastes
    [  422] =  422, -- Timeless Isle
    [  433] =  390, -- Vale (alias) → Vale of Eternal Blossoms
    [  554] =  554, -- Isle of Thunder

    ----------------------------------------------------------------------------
    -- CATACLYSM (4.0)
    ----------------------------------------------------------------------------
    [  198] =  198, -- Mount Hyjal
    [  201] =  201, -- Twilight Highlands
    [  204] =  204, -- Abyssal Depths
    [  205] =  205, -- Shimmering Expanse
    [  207] =  207, -- Deepholm
    [  241] =  241, -- Tol Barad
    [  245] =  245, -- Tol Barad Peninsula
    [  249] =  249, -- Uldum

    ----------------------------------------------------------------------------
    -- WRATH OF THE LICH KING (3.0)
    ----------------------------------------------------------------------------
    [  114] =  114, -- Borean Tundra
    [  115] =  115, -- Dragonblight
    [  116] =  116, -- Grizzly Hills
    [  117] =  117, -- Howling Fjord
    [  118] =  118, -- Icecrown
    [  119] =  119, -- Sholazar Basin
    [  120] =  120, -- The Storm Peaks
    [  121] =  121, -- Zul'Drak
    [  123] =  123, -- Wintergrasp
    [  125] =  125, -- Dalaran (Northrend)
    [  126] =  125, -- Dalaran (sub-zone) → Dalaran
    [  127] =  125, -- Dalaran (sub-zone) → Dalaran

    ----------------------------------------------------------------------------
    -- THE BURNING CRUSADE (2.0)
    ----------------------------------------------------------------------------
    [   94] =   94, -- Eversong Woods
    [   95] =   95, -- Ghostlands
    [  100] =  100, -- Hellfire Peninsula
    [  101] =  101, -- Zangarmarsh
    [  102] =  102, -- The Exodar
    [  103] =  103, -- Telogrus Rift
    [  104] =  104, -- Shadowmoon Valley (Outland)
    [  105] =  105, -- Blade's Edge Mountains
    [  106] =  106, -- Nagrand (Outland)
    [  107] =  107, -- Terokkar Forest
    [  108] =  108, -- Netherstorm
    [  109] =  109, -- Shattrath City
    [  110] =  110, -- Silvermoon City
    [  111] =  111, -- Isle of Quel'Danas
    [  122] =  122, -- Azuremyst Isle

    ----------------------------------------------------------------------------
    -- KALIMDOR (Classic)
    ----------------------------------------------------------------------------
    [    1] =    1, -- Durotar
    [    7] =    7, -- Mulgore
    [   10] =   10, -- Northern Barrens
    [   12] =   12, -- Teldrassil
    [   57] =   57, -- Azshara
    [   62] =   62, -- Darkshore
    [   63] =   63, -- Ashenvale
    [   64] =   64, -- Thousand Needles
    [   65] =   65, -- Stonetalon Mountains
    [   66] =   66, -- Desolace
    [   69] =   69, -- Feralas
    [   70] =   70, -- Dustwallow Marsh
    [   71] =   71, -- Tanaris
    [   76] =   76, -- Moonglade
    [   77] =   77, -- Felwood
    [   78] =   78, -- Un'Goro Crater
    [   80] =   80, -- Silithus
    [   83] =   83, -- Winterspring
    [   85] =   85, -- Orgrimmar
    [   86] =   85, -- Orgrimmar (sub-zone) → Orgrimmar
    [   88] =   88, -- Thunder Bluff
    [   89] =   89, -- Darnassus
    [  199] =  199, -- Southern Barrens
    [  463] =  463, -- The Exodar

    ----------------------------------------------------------------------------
    -- EASTERN KINGDOMS (Classic)
    ----------------------------------------------------------------------------
    [   13] =   13, -- The Hinterlands
    [   14] =   14, -- Arathi Highlands
    [   15] =   15, -- Badlands
    [   17] =   17, -- Blasted Lands
    [   18] =   18, -- Tirisfal Glades
    [   21] =   21, -- Silverpine Forest
    [   22] =   22, -- Western Plaguelands
    [   23] =   23, -- Eastern Plaguelands
    [   25] =   25, -- Hillsbrad Foothills
    [   26] =   26, -- The Cape of Stranglethorn
    [   29] =   29, -- Dun Morogh
    [   32] =   32, -- Searing Gorge
    [   33] =   33, -- Burning Steppes
    [   36] =   36, -- Elwynn Forest
    [   37] =   37, -- Deadwind Pass
    [   42] =   42, -- Duskwood
    [   47] =   47, -- Loch Modan
    [   48] =   48, -- Redridge Mountains
    [   49] =   49, -- Northern Stranglethorn
    [   50] =  210, -- Wetlands (alias) → Wetlands
    [   51] =   51, -- Swamp of Sorrows
    [   52] =   52, -- Westfall
    [   56] =   56, -- Wetlands
    [   84] =   84, -- Stormwind City
    [   87] =   87, -- Ironforge
    [   90] =   90, -- Undercity
    [  210] =  210, -- The Wetlands
    [  217] =  217, -- Ruins of Gilneas
    [  499] =  499, -- Stranglethorn Vale
}
RdysCrateTracker.NS_ZoneNormalize = NS_ZoneNormalize


local ZONE_CACHE = {}

local function SafeGetMapInfo(mapID)
    if not mapID or mapID == 0 then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok then return nil end
    return info
end

function RdysCrateTracker:NormalizeZoneID(id)
    id = tonumber(id)
    if not id then return nil end

    -- Step 1: allowed crate zones (final roots)
    local ALLOWED = self.ALLOWED_CRATE_ZONES

    -- Step 2: override table takes priority
    if NS_ZoneNormalize[id] ~= nil then
        local override = NS_ZoneNormalize[id]
        if ALLOWED[override] then
            return override
        else
            return nil -- override maps into invalid zone → reject
        end
    end

    -- Step 3: cached?
    local cached = ZONE_CACHE[id]
    if cached ~= nil then
        return cached
    end

    -- Step 4: walk map parents to find the real root zone
    local info = C_Map.GetMapInfo(id)
    if not info then
        return nil
    end

    local best = nil
    local depth = 0

    while info and depth < 10 do
        depth = depth + 1

        if info.mapType == Enum.UIMapType.Zone then
            best = info.mapID
        end

        if not info.parentMapID or info.parentMapID == 0 then
            break
        end

        info = C_Map.GetMapInfo(info.parentMapID)
    end

    -- Step 5: no root zone found → reject
    if not best then
        return nil
    end

    -- Step 6: reapply override
    best = NS_ZoneNormalize[best] or best

    -- Step 7: final allowlist filter
    if not ALLOWED[best] then
        ZONE_CACHE[id] = nil
        return nil
    end

    ZONE_CACHE[id] = best
    return best
end
