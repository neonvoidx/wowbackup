local SCAN_THROTTLE       = 2
local DELVE_ACTIVITY_TYPE = 4
local DELVE_T8_MIN_LEVEL  = 8
local DELVERS_BOUNTY_ITEM = 233071

local QUEST_CALL_TO_DELVES  = 84776
local QUEST_MIDNIGHT_DELVES = 93909
local QUEST_NULLAEUS        = 93525
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local EXPANSIONS = {
    {
        label  = L["Midnight"],
        mapIds = { [2395]=true, [2405]=true, [2413]=true, [2437]=true },
        zones  = {
            { uiMapId = 2395, delves = { {8426,8425,93384}, {8438,8437,93372} } },
            { uiMapId = 2405, delves = { {8432,8431,93428}, {8430,8429,93427} } },
            { uiMapId = 2413, delves = { {8434,8433,93421}, {8436,8435,93416} } },
            { uiMapId = 2437, delves = { {8444,8443,93409}, {8442,8441,93410} } },
        },
    },
    {
        label  = L["Delves_WarWithin"],
        mapIds = { [2248]=true, [2214]=true, [2215]=true, [2255]=true, [2346]=true, [2371]=true },
        zones  = {
            { uiMapId = 2248, delves = { {7779,7864,82939}, {7781,7865,82941}, {7787,7863,82944} } },
            { uiMapId = 2214, delves = { {7782,7866,82945}, {7788,7867,82938}, {8181,8143,85187} } },
            { uiMapId = 2215, delves = { {7780,7869,82940}, {7783,7870,82937}, {7785,7868,82777}, {7789,7871,78508} } },
            { uiMapId = 2255, delves = { {7784,7873,82776}, {7786,7872,82943}, {7790,7874,82942} } },
            { uiMapId = 2346, delves = { {8246,8140,85668} } },
            { uiMapId = 2371, delves = { {8273,8274,0} } },
        },
    },
}

local function GetPlayerExpansion()
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId then
        for _ = 1, 6 do
            for _, exp in ipairs(EXPANSIONS) do
                if exp.mapIds[mapId] then return exp end
            end
            local info = C_Map.GetMapInfo(mapId)
            if not info or not info.parentMapID or info.parentMapID == 0 then break end
            mapId = info.parentMapID
        end
    end
    return EXPANSIONS[1]
end

for _, exp in ipairs(EXPANSIONS) do
    local total = 0
    for _, zone in ipairs(exp.zones) do total = total + #zone.delves end
    exp.total = total
end

local function ScanExpansion(exp, mdb)
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo) then return end

    local done    = 0
    local total   = 0
    local entries = {}

    for _, zone in ipairs(exp.zones) do
        local zoneName = (C_Map.GetMapInfo(zone.uiMapId) or {}).name or "Unknown"
        for _, pair in ipairs(zone.delves) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(zone.uiMapId, pair[1])
            if poiInfo then
                total = total + 1
                local questDone = pair[3] ~= 0 and C_QuestLog.IsQuestFlaggedCompleted(pair[3])
                if questDone then
                    done = done + 1
                    entries[#entries + 1] = "|cff808080" .. zoneName .. ": " .. (poiInfo.name or "?") .. " \226\156\147|r"
                else
                    entries[#entries + 1] = zoneName .. ": " .. (poiInfo.name or "?")
                end
            end
        end
    end

    mdb["bountiful_live"]    = done
    mdb["bountiful_total"]   = total
    mdb["bountiful_entries"] = table.concat(entries, "\n")
    mdb["bountiful_exp"]     = exp.label
end

local bountifulRow
local lastScan = 0

MR:RegisterModule({
    key         = "delves",
    label       = L["Delves"],
    labelColor  = "#c8956c",
    resetType   = "weekly",
    defaultOpen = false,

    onScan = function(mod)
        local now = GetTime()
        local db  = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local mdb = db[mod.key]

        local exp = GetPlayerExpansion()
        if exp then
            ScanExpansion(exp, mdb)
            bountifulRow.max = mdb["bountiful_total"] > 0 and mdb["bountiful_total"] or exp.total
        else
            mdb["bountiful_live"]    = 0
            mdb["bountiful_total"]   = 0
            mdb["bountiful_entries"] = ""
            mdb["bountiful_exp"]     = nil
        end

        if (now - lastScan) < SCAN_THROTTLE then return end
        lastScan = now

        if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
            local activities = C_WeeklyRewards.GetActivities()
            if activities then
                for _, act in ipairs(activities) do
                    if act.type == DELVE_ACTIVITY_TYPE then
                        local runs = act.progress or 0
                        local t8   = ((act.level or 0) >= DELVE_T8_MIN_LEVEL) and 1 or 0
                        if mdb["delve_runs"] ~= runs then mdb["delve_runs"] = runs end
                        if mdb["delve_t8"]   ~= t8   then mdb["delve_t8"]   = t8   end
                        break
                    end
                end
            end
        end

        local bountyCount = C_Item.GetItemCount and C_Item.GetItemCount(DELVERS_BOUNTY_ITEM) or 0
        local bountyUsed  = (bountyCount == 0) and 1 or 0
        if mdb["delve_bounty"] ~= bountyUsed then
            mdb["delve_bounty"] = bountyUsed
        end
    end,

    rows = {
        {
            key      = "delve_weekly",
            label    = L["Delves_Call_Label"],
            max      = 1,
            note     = L["Delves_Call_Note"],
            questIds = { QUEST_CALL_TO_DELVES },
        },
        {
            key      = "delve_valeera",
            label    = L["Delves_Midnight_Label"],
            max      = 1,
            note     = L["Delves_Midnight_Note"],
            questIds = { QUEST_MIDNIGHT_DELVES },
        },
        {
            key     = "delve_runs",
            label   = L["Delves_Runs_Label"],
            max     = 8,
            note    = L["Delves_Runs_Note"],
            liveKey = "delve_runs",
        },
        {
            key   = "delve_t8",
            label = L["Delves_T8_Label"],
            max   = 1,
            note  = L["Delves_T8_Note"],
        },
        {
            key     = "delve_bounty",
            label   = L["Delves_Bounty_Label"],
            max     = 1,
            note    = L["Delves_Bounty_Note"],
            liveKey = "delve_bounty",
        },
        {
            key      = "delve_nullaeus",
            label    = L["Delves_Nullaeus_Label"],
            max      = 1,
            note     = L["Delves_Nullaeus_Note"],
            questIds = { QUEST_NULLAEUS },
        },
        {
            key     = "bountiful_count",
            label   = L["Delves_Bountiful_Label"],
            max     = 4,
            note    = L["Delves_Bountiful_Note"],
            liveKey = "bountiful_live",
            isVisible = function()
                local mdb = MR.db.char.progress["delves"]
                return mdb and mdb["bountiful_exp"] ~= nil
            end,
            tooltipFunc = function(tip)
                local mdb     = MR.db.char.progress["delves"]
                local expName = mdb and mdb["bountiful_exp"]
                local entries = mdb and mdb["bountiful_entries"]
                tip:AddLine(" ")
                if expName then
                    tip:AddLine(string.format(L["Delves_Bountiful_Today"], expName), 1, 1, 1)
                end
                if entries and entries ~= "" then
                    for line in entries:gmatch("[^\n]+") do
                        tip:AddLine("  " .. line, 0.9, 0.85, 0.6)
                    end
                else
                    tip:AddLine(L["Delves_No_Bountiful"], 0.6, 0.6, 0.6)
                end
            end,
        },
    },
})

do
    local mod = MR.moduleByKey["delves"]
    for _, r in ipairs(mod.rows) do
        if r.key == "bountiful_count" then bountifulRow = r; break end
    end
end
