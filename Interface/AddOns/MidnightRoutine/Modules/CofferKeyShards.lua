local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key         = "coffer_key_shards",
    label       = L["CofferKey_Title"],
    labelColor  = "#e8c96e",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key        = "shards",
            label      = L["CofferKey_Label"],
            currencyId = 3310,
            max        = 600,
            note       = L["CofferKey_Note"],
        },
    },
})
