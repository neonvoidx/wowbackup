local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HOLIDAY_DARKMOON_FAIRE = 479

local HOLIDAY_TIMEWALKING = {
    1056,
    1063,
    1326,
    1400,
    1404,
    1500,
}

local function IsHolidayActive(holidayId)
    if not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then return false end
    local info = C_DateAndTime.GetHolidayInfo(holidayId)
    return info ~= nil and info.startTime ~= nil and GetServerTime() >= info.startTime and GetServerTime() <= info.endTime
end

local function IsDarkmoonActive()
    return IsHolidayActive(HOLIDAY_DARKMOON_FAIRE)
end

local function IsTimewalkingActive()
    for _, id in ipairs(HOLIDAY_TIMEWALKING) do
        if IsHolidayActive(id) then return true end
    end
    return false
end

local DARKMOON_PROFESSION_QUESTS = { 29513, 29514, 29515, 29516, 29517, 29518 }

local function ScanDarkmoon(mod)
    local db = MR.db.char.progress
    if not db[mod.key] then db[mod.key] = {} end

    local profDone = 0
    for _, qid in ipairs(DARKMOON_PROFESSION_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(qid) then
            profDone = profDone + 1
        end
    end
    db[mod.key]["dmf_profession"] = math.min(profDone, 6)

    local function q(qid) return C_QuestLog.IsQuestFlaggedCompleted(qid) and 1 or 0 end
    db[mod.key]["dmf_dungeon"]  = q(29525)
    db[mod.key]["dmf_tonk"]     = q(29520)
    db[mod.key]["dmf_shooting"] = q(29526)
    db[mod.key]["dmf_ring"]     = q(29524)
    db[mod.key]["dmf_cannon"]   = q(29527)
    db[mod.key]["dmf_sword"]    = q(29529)
end

MR:RegisterModule({
    key         = "darkmoon_faire",
    label       = L["DMF_Title"],
    labelColor  = "#cc99ff",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsDarkmoonActive,
    onScan      = ScanDarkmoon,

    rows = {
        {
            key     = "dmf_profession",
            label   = L["DMF_Prof_Label"],
            max     = 6,
            note    = L["DMF_Prof_Note"],
            liveKey = "dmf_profession",
        },
        {
            key     = "dmf_dungeon",
            label   = L["DMF_Dungeon_Label"],
            max     = 1,
            note    = L["DMF_Dungeon_Note"],
            liveKey = "dmf_dungeon",
        },
        {
            key     = "dmf_tonk",
            label   = L["DMF_Tonk_Label"],
            max     = 1,
            note    = L["DMF_Tonk_Note"],
            liveKey = "dmf_tonk",
        },
        {
            key     = "dmf_shooting",
            label   = L["DMF_Hammer_Label"],
            max     = 1,
            note    = L["DMF_Hammer_Note"],
            liveKey = "dmf_shooting",
        },
        {
            key     = "dmf_ring",
            label   = L["DMF_Ring_Label"],
            max     = 1,
            note    = L["DMF_Ring_Note"],
            liveKey = "dmf_ring",
        },
        {
            key     = "dmf_cannon",
            label   = L["DMF_Cannon_Label"],
            max     = 1,
            note    = L["DMF_Cannon_Note"],
            liveKey = "dmf_cannon",
        },
        {
            key     = "dmf_sword",
            label   = L["DMF_Target_Label"],
            max     = 1,
            note    = L["DMF_Target_Note"],
            liveKey = "dmf_sword",
        },
    },
})

local MAPID_ISLE_OF_DORN     = 2248
local MAPID_RINGING_DEEPS    = 2249
local MAPID_HALLOWFALL       = 2255
local MAPID_AZJ_KAHET        = 2346

local function IsInMap(mapId)
    local current = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not current then return false end
    local checked = 0
    while current and checked < 10 do
        if current == mapId then return true end
        local info = C_Map.GetMapInfo(current)
        current = info and info.parentMapID
        checked = checked + 1
    end
    return false
end

MR:RegisterModule({
    key         = "world_bosses",
    label       = L["WB_Title"],
    labelColor  = "#ff4444",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = function()
        return IsInMap(MAPID_ISLE_OF_DORN)
            or IsInMap(MAPID_RINGING_DEEPS)
            or IsInMap(MAPID_HALLOWFALL)
            or IsInMap(MAPID_AZJ_KAHET)
    end,
    rows = {
        {
            key       = "skarmorak",
            label     = L["WB_Skarmorak_Label"],
            max       = 1,
            note      = L["WB_Skarmorak_Note"],
            questIds  = { 78319 },
            isVisible = function() return IsInMap(MAPID_ISLE_OF_DORN) end,
        },
        {
            key       = "aggregation",
            label     = L["WB_Aggregation_Label"],
            max       = 1,
            note      = L["WB_Aggregation_Note"],
            questIds  = { 83173 },
            isVisible = function() return IsInMap(MAPID_RINGING_DEEPS) end,
        },
        {
            key       = "odalrik",
            label     = L["WB_Odalrik_Label"],
            max       = 1,
            note      = L["WB_Odalrik_Note"],
            questIds  = { 80385 },
            isVisible = function() return IsInMap(MAPID_HALLOWFALL) end,
        },
        {
            key       = "echo_forgotten",
            label     = L["WB_Echo_Label"],
            max       = 1,
            note      = L["WB_Echo_Note"],
            questIds  = { 84446 },
            isVisible = function() return IsInMap(MAPID_AZJ_KAHET) end,
        },
    },
})

MR:RegisterModule({
    key         = "timewalking",
    label       = L["TW_DungeonTitle"],
    labelColor  = "#66ccff",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsTimewalkingActive,

    rows = {
        {
            key      = "tw_weekly",
            label    = L["TW_Weekly_Label"],
            max      = 1,
            note     = L["TW_Weekly_Note"],
            questIds = { 40753, 40173, 40786, 40785, 45566, 62786 },
        },
    },
})
