local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key         = "lfr_s1",
    label       = L["Raid"],
    labelColor  = "#99ccff",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key      = "lfr_w1",
            label    = L["LFR_Wing1"],
            max      = 1,
            questIds = { 0 },
        },
        {
            key      = "lfr_w2",
            label    = L["LFR_Wing2"],
            max      = 1,
            questIds = { 0 },
        },
        {
            key      = "lfr_w3",
            label    = L["LFR_Wing3"],
            max      = 1,
            questIds = { 0 },
        },
        {
            key      = "lfr_w4",
            label    = L["LFR_Wing4"],
            max      = 1,
            questIds = { 0 },
        },
    },
})
