local CREST_CAP = 100
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key         = "currencies",
    label       = L["Currencies"],
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        { key = "crest_adventurer", currencyId = 3383, max = CREST_CAP, label = L["Crest_Adventurer_Label"], note = L["Crest_Adventurer_Note"] },
        { key = "crest_veteran",    currencyId = 3341, max = CREST_CAP, label = L["Crest_Veteran_Label"],    note = L["Crest_Veteran_Note"] },
        { key = "crest_champion",   currencyId = 3343, max = CREST_CAP, label = L["Crest_Champion_Label"],   note = L["Crest_Champion_Note"] },
        { key = "crest_hero",       currencyId = 3345, max = CREST_CAP, label = L["Crest_Hero_Label"],       note = L["Crest_Hero_Note"] },
        { key = "crest_myth",       currencyId = 3347, max = CREST_CAP, label = L["Crest_Myth_Label"],       note = L["Crest_Myth_Note"] },
        {
            key        = "shards",
            label      = L["CofferKey_Label"],
            currencyId = 3310,
            max        = 600,
            note       = L["CofferKey_Note"],
        },
    },
})
