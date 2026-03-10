-- By D4KiR
local _, SpecBisTooltip = ...
local BIS = {}
if SpecBisTooltip:GetWoWBuild() == "RETAIL" then
    function SpecBisTooltip:GetBisTable()
        return BIS
    end
end

-- DATA FROM: 06.03.2026
if SpecBisTooltip:GetWoWBuild() == "RETAIL" then
    BIS["RETAIL"] = {}
    BIS["RETAIL"]["DEATHKNIGHT"] = {}
    BIS["RETAIL"]["DEATHKNIGHT"][1] = {
        ["BISO"] = {
            [49802] = {"npc;drop=36494", "INVTYPE_2HWEAPON"},
            [151333] = {"npc;drop=122056", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [249968] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [260312] = {"npc;drop=231863", "INVTYPE_CLOAK"},
            [249973] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [249971] = {"catalyst/unknown", "INVTYPE_HAND"},
            [49808] = {"npc;drop=36476", "INVTYPE_WAIST"},
            [249969] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [251513] = {"spell;created=1230479", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249344] = {"npc;drop=240435", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DEATHKNIGHT"][2] = {
        ["BISO"] = {
            [249277] = {"npc;drop=250589", "INVTYPE_2HWEAPON"},
            [249281] = {"npc;drop=240432", "INVTYPE_WEAPON"},
            [249970] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [50234] = {"npc;drop=36494", "INVTYPE_SHOULDER"},
            [258575] = {"npc;drop=75964", "INVTYPE_CLOAK"},
            [249973] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [249971] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249380] = {"npc;drop=244761", "INVTYPE_WAIST"},
            [249949] = {"catalyst/unknown", "INVTYPE_WAIST"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [251513] = {"spell;created=1230479", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249344] = {"npc;drop=240435", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DEATHKNIGHT"][3] = {
        ["BISO"] = {
            [249277] = {"npc;drop=250589", "INVTYPE_2HWEAPON"},
            [249970] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [50234] = {"npc;drop=36494", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [249973] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [249971] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249967] = {"catalyst/unknown", "INVTYPE_WAIST"},
            [249969] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249344] = {"npc;drop=240435", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DEMONHUNTER"] = {}
    BIS["RETAIL"]["DEMONHUNTER"][1] = {
        ["BISO"] = {
            [260408] = {"npc;drop=214650", "INVTYPE_WEAPON"},
            [249280] = {"npc;drop=242056", "INVTYPE_WEAPON"},
            [250033] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250031] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250036] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244576] = {"spell;created=1237514", "INVTYPE_WRIST"},
            [250034] = {"catalyst/unknown", "INVTYPE_HAND"},
            [251082] = {"npc;drop=231606", "INVTYPE_WAIST"},
            [251087] = {"npc;drop=231626", "INVTYPE_LEGS"},
            [258577] = {"npc;drop=76141", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [251217] = {"npc;drop=241546", "INVTYPE_FINGER"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DEMONHUNTER"][2] = {
        ["BISO"] = {
            [260408] = {"npc;drop=214650", "INVTYPE_WEAPON"},
            [249298] = {"npc;drop=240432", "INVTYPE_WEAPON"},
            [250033] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [151309] = {"npc;drop=122056", "INVTYPE_NECK"},
            [250031] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [151313] = {"npc;drop=124729", "INVTYPE_CHEST"},
            [50264] = {"npc;drop=36476", "INVTYPE_WRIST"},
            [250034] = {"catalyst/unknown", "INVTYPE_HAND"},
            [49806] = {"npc;drop=36494", "INVTYPE_WAIST"},
            [250032] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [251210] = {"npc;drop=254227", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [251513] = {"spell;created=1230479", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249344] = {"npc;drop=240435", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DEMONHUNTER"][3] = {
        ["BISO"] = {
            [260408] = {"npc;drop=214650", "INVTYPE_WEAPON"},
            [249294] = {"npc;drop=250589", "INVTYPE_WEAPON"},
            [250033] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [250031] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [250036] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244748] = {"spell;created=1229875", "INVTYPE_WRIST"},
            [250034] = {"catalyst/unknown", "INVTYPE_HAND"},
            [109830] = {"npc;drop=75452", "INVTYPE_WAIST"},
            [49817] = {"npc;drop=36658", "INVTYPE_LEGS"},
            [109788] = {"npc;drop=76141", "INVTYPE_FEET"},
            [249369] = {"npc;drop=250589", "INVTYPE_FINGER"},
            [251513] = {"spell;created=1230479", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DRUID"] = {}
    BIS["RETAIL"]["DRUID"][1] = {
        ["BISO"] = {
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [245769] = {"spell;created=1230061", "INVTYPE_HOLDABLE"},
            [250024] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250022] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [250027] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244576] = {"spell;created=1237514", "INVTYPE_WRIST"},
            [251113] = {"npc;drop=231864", "INVTYPE_HAND"},
            [251082] = {"npc;drop=231606", "INVTYPE_WAIST"},
            [250023] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249382] = {"npc;drop=244761", "INVTYPE_FEET"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [251217] = {"npc;drop=241546", "INVTYPE_FINGER"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DRUID"][2] = {
        ["BISO"] = {
            [249302] = {"npc;drop=240434", "INVTYPE_2HWEAPON"},
            [250024] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250022] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [250027] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244576] = {"spell;created=1237514", "INVTYPE_WRIST"},
            [244575] = {"spell;created=1237509", "INVTYPE_HAND"},
            [251082] = {"npc;drop=231606", "INVTYPE_WAIST"},
            [250023] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249382] = {"npc;drop=244761", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [251115] = {"npc;drop=231864", "INVTYPE_FINGER"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DRUID"][3] = {
        ["BISO"] = {
            [249278] = {"npc;drop=256116", "INVTYPE_2HWEAPON"},
            [249913] = {"npc;drop=214650", "INVTYPE_HEAD"},
            [251096] = {"npc;drop=231636", "INVTYPE_NECK"},
            [250022] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [250027] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249327] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [250025] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249374] = {"npc;drop=256116", "INVTYPE_WAIST"},
            [250023] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249334] = {"npc;drop=240435", "INVTYPE_FEET"},
            [251093] = {"npc;drop=254227", "INVTYPE_FINGER"},
            [251217] = {"npc;drop=241546", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["DRUID"][4] = {
        ["BISO"] = {
            [250024] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250022] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [251216] = {"npc;drop=241546", "INVTYPE_CHEST"},
            [193714] = {"npc;drop=196482", "INVTYPE_WRIST"},
            [250025] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249314] = {"npc;drop=240432", "INVTYPE_WAIST"},
            [250023] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [251210] = {"npc;drop=254227", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [251115] = {"npc;drop=231864", "INVTYPE_FINGER"},
            [249809] = {"npc;drop=244761", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249922] = {"npc;drop=256116", "INVTYPE_HOLDABLE"},
        },
    }

    BIS["RETAIL"]["EVOKER"] = {}
    BIS["RETAIL"]["EVOKER"][1] = {
        ["BISO"] = {
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249276] = {"npc;drop=240434", "INVTYPE_HOLDABLE"},
            [249997] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249995] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250000] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244584] = {"spell;created=1237543", "INVTYPE_WRIST"},
            [249325] = {"npc;drop=244761", "INVTYPE_HAND"},
            [49810] = {"npc;drop=36476", "INVTYPE_WAIST"},
            [249996] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249377] = {"npc;drop=246729", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["EVOKER"][2] = {
        ["BISO"] = {
            [249914] = {"npc;drop=214650", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249995] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [251206] = {"quest;reward=86521", "INVTYPE_CLOAK"},
            [250000] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [251079] = {"npc;drop=231606", "INVTYPE_WRIST"},
            [249998] = {"catalyst/unknown", "INVTYPE_HAND"},
            [193722] = {"npc;drop=191736", "INVTYPE_WAIST"},
            [249996] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [251084] = {"npc;drop=231626", "INVTYPE_FEET"},
            [249369] = {"npc;drop=250589", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249809] = {"npc;drop=244761", "INVTYPE_TRINKET"},
            [258514] = {"npc;drop=122313", "INVTYPE_2HWEAPON"},
        },
    }

    BIS["RETAIL"]["EVOKER"][3] = {
        ["BISO"] = {
            [251178] = {"npc;drop=248595", "INVTYPE_WEAPON"},
            [249276] = {"npc;drop=240434", "INVTYPE_HOLDABLE"},
            [249997] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249995] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250000] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244584] = {"spell;created=1237543", "INVTYPE_WRIST"},
            [249325] = {"npc;drop=244761", "INVTYPE_HAND"},
            [49810] = {"npc;drop=36476", "INVTYPE_WAIST"},
            [249996] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249999] = {"catalyst/unknown", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249810] = {"npc;drop=214650", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["HUNTER"] = {}
    BIS["RETAIL"]["HUNTER"][1] = {
        ["BISO"] = {
            [251174] = {"npc;drop=247570", "INVTYPE_RANGED"},
            [249988] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [151323] = {"npc;drop=122316", "INVTYPE_SHOULDER"},
            [258575] = {"npc;drop=75964", "INVTYPE_CLOAK"},
            [249991] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [251209] = {"npc;drop=254227", "INVTYPE_WRIST"},
            [249989] = {"catalyst/unknown", "INVTYPE_HAND"},
            [244611] = {"spell;created=1237519", "INVTYPE_WAIST"},
            [244610] = {"spell;created=1237518", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249369] = {"npc;drop=250589", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["HUNTER"][2] = {
        ["BISO"] = {
            [249288] = {"npc;drop=244761", "INVTYPE_RANGED"},
            [249988] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [151323] = {"npc;drop=122316", "INVTYPE_SHOULDER"},
            [249335] = {"npc;drop=240435", "INVTYPE_CLOAK"},
            [249991] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249304] = {"npc;drop=240432", "INVTYPE_WRIST"},
            [249989] = {"catalyst/unknown", "INVTYPE_HAND"},
            [244611] = {"spell;created=1237519", "INVTYPE_WAIST"},
            [249987] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [244610] = {"spell;created=1237518", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249336] = {"npc;drop=240434", "INVTYPE_FINGER"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
            [260235] = {"npc;drop=246729", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["HUNTER"][3] = {
        ["BISO"] = {
            [251077] = {"npc;drop=231606", "INVTYPE_2HWEAPON"},
            [249988] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249986] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [251179] = {"npc;drop=248605", "INVTYPE_CHEST"},
            [249304] = {"npc;drop=240432", "INVTYPE_WRIST"},
            [249989] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249371] = {"npc;drop=256116", "INVTYPE_WAIST"},
            [249987] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [244577] = {"spell;created=1237537", "INVTYPE_FEET"},
            [251093] = {"npc;drop=254227", "INVTYPE_FINGER"},
            [251115] = {"npc;drop=231864", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249806] = {"npc;drop=246729", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MAGE"] = {}
    BIS["RETAIL"]["MAGE"][1] = {
        ["BISO"] = {
            [258218] = {"npc;drop=75964", "INVTYPE_WEAPON"},
            [251094] = {"npc;drop=231636", "INVTYPE_HOLDABLE"},
            [250060] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250058] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250063] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [258580] = {"npc;drop=76379", "INVTYPE_WRIST"},
            [250061] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [251090] = {"npc;drop=231631", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [240949] = {"spell;created=1230485", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MAGE"][2] = {
        ["BISO"] = {
            [249286] = {"npc;drop=214650", "INVTYPE_2HWEAPON"},
            [250060] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250058] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [249912] = {"npc;drop=214650", "INVTYPE_CHEST"},
            [239648] = {"spell;created=1228945", "INVTYPE_WRIST"},
            [250061] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250059] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [258584] = {"npc;drop=76266", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249369] = {"npc;drop=250589", "INVTYPE_FINGER"},
            [250144] = {"npc;drop=231606", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MAGE"][3] = {
        ["BISO"] = {
            [258514] = {"npc;drop=122313", "INVTYPE_2HWEAPON"},
            [250060] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [251085] = {"npc;drop=231626", "INVTYPE_SHOULDER"},
            [258575] = {"npc;drop=75964", "INVTYPE_CLOAK"},
            [250063] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [258580] = {"npc;drop=76379", "INVTYPE_WRIST"},
            [250061] = {"catalyst/unknown", "INVTYPE_HAND"},
            [250057] = {"catalyst/unknown", "INVTYPE_WAIST"},
            [250059] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [250144] = {"npc;drop=231606", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MONK"] = {}
    BIS["RETAIL"]["MONK"][1] = {
        ["BISO"] = {
            [249302] = {"npc;drop=240434", "INVTYPE_2HWEAPON"},
            [251207] = {"npc;drop=254227", "INVTYPE_WEAPON"},
            [250015] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [240950] = {"spell;created=1230486", "INVTYPE_NECK"},
            [250013] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249335] = {"npc;drop=240435", "INVTYPE_CLOAK"},
            [250018] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [250011] = {"catalyst/unknown", "INVTYPE_WRIST"},
            [250016] = {"catalyst/unknown", "INVTYPE_HAND"},
            [251082] = {"npc;drop=231606", "INVTYPE_WAIST"},
            [151314] = {"npc;drop=122316", "INVTYPE_LEGS"},
            [151317] = {"npc;drop=122056", "INVTYPE_FEET"},
            [249336] = {"npc;drop=240434", "INVTYPE_FINGER"},
            [251513] = {"spell;created=1230479", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249806] = {"npc;drop=246729", "INVTYPE_TRINKET"},
            [249339] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [151312] = {"npc;drop=122313", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MONK"][2] = {
        ["BISO"] = {
            [258047] = {"npc;drop=76141", "INVTYPE_2HWEAPON"},
            [249276] = {"npc;drop=240434", "INVTYPE_HOLDABLE"},
            [249913] = {"npc;drop=214650", "INVTYPE_HEAD"},
            [249337] = {"npc;drop=240432", "INVTYPE_NECK"},
            [250013] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [260312] = {"npc;drop=231863", "INVTYPE_CLOAK"},
            [250018] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [50264] = {"npc;drop=36476", "INVTYPE_WRIST"},
            [250016] = {"catalyst/unknown", "INVTYPE_HAND"},
            [49806] = {"npc;drop=36494", "INVTYPE_WAIST"},
            [250014] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [251210] = {"npc;drop=254227", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [151311] = {"npc;drop=124729", "INVTYPE_FINGER"},
            [249341] = {"npc;drop=240432", "INVTYPE_TRINKET"},
            [250256] = {"npc;drop=231636", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["MONK"][3] = {
        ["BISO"] = {
            [250015] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250013] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [250010] = {"catalyst/unknown", "INVTYPE_CLOAK"},
            [250018] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249327] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [249321] = {"npc;drop=242056", "INVTYPE_HAND"},
            [251082] = {"npc;drop=231606", "INVTYPE_WAIST"},
            [250014] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [250017] = {"catalyst/unknown", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [237845] = {"spell;created=1229649", "INVTYPE_WEAPON"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["PALADIN"] = {}
    BIS["RETAIL"]["PALADIN"][1] = {
        ["BISO"] = {
            [193710] = {"npc;drop=194181", "INVTYPE_WEAPON"},
            [258049] = {"npc;drop=76266", "INVTYPE_SHIELD"},
            [249961] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249959] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [258575] = {"npc;drop=75964", "INVTYPE_CLOAK"},
            [249964] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [263193] = {"npc;drop=247570", "INVTYPE_WRIST"},
            [249962] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249331] = {"npc;drop=242056", "INVTYPE_WAIST"},
            [249915] = {"npc;drop=214650", "INVTYPE_LEGS"},
            [249332] = {"npc;drop=240434", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["PALADIN"][2] = {
        ["BISO"] = {
            [249295] = {"npc;drop=244761", "INVTYPE_WEAPON"},
            [249921] = {"npc;drop=246729", "INVTYPE_SHIELD"},
            [249316] = {"npc;drop=240432", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [249959] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [249964] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249326] = {"npc;drop=240435", "INVTYPE_WRIST"},
            [249962] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249331] = {"npc;drop=242056", "INVTYPE_WAIST"},
            [249960] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [151311] = {"npc;drop=124729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249342] = {"npc;drop=240434", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["PALADIN"][3] = {
        ["BISO"] = {
            [249277] = {"npc;drop=250589", "INVTYPE_2HWEAPON"},
            [249961] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249959] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [249964] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [151332] = {"npc;drop=122056", "INVTYPE_HAND"},
            [249380] = {"npc;drop=244761", "INVTYPE_WAIST"},
            [249960] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [260235] = {"npc;drop=246729", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["PRIEST"] = {}
    BIS["RETAIL"]["PRIEST"][1] = {
        ["BISO"] = {
            [250051] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250049] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [249912] = {"npc;drop=214650", "INVTYPE_CHEST"},
            [251108] = {"npc;drop=231863", "INVTYPE_WRIST"},
            [250052] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250050] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249809] = {"npc;drop=244761", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249922] = {"npc;drop=256116", "INVTYPE_HOLDABLE"},
        },
    }

    BIS["RETAIL"]["PRIEST"][2] = {
        ["BISO"] = {
            [250051] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250049] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [249912] = {"npc;drop=214650", "INVTYPE_CHEST"},
            [251108] = {"npc;drop=231863", "INVTYPE_WRIST"},
            [250052] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250050] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249809] = {"npc;drop=244761", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249922] = {"npc;drop=256116", "INVTYPE_HOLDABLE"},
        },
    }

    BIS["RETAIL"]["PRIEST"][3] = {
        ["BISO"] = {
            [250051] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [250049] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [250054] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [251108] = {"npc;drop=231863", "INVTYPE_WRIST"},
            [250052] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250050] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249922] = {"npc;drop=256116", "INVTYPE_HOLDABLE"},
        },
    }

    BIS["RETAIL"]["ROGUE"] = {}
    BIS["RETAIL"]["ROGUE"][1] = {
        ["BISO"] = {
            [249925] = {"npc;drop=240434", "INVTYPE_WEAPON"},
            [237837] = {"spell;created=1229659", "INVTYPE_WEAPON"},
            [250006] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249337] = {"npc;drop=240432", "INVTYPE_NECK"},
            [250004] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [260312] = {"npc;drop=231863", "INVTYPE_CLOAK"},
            [250009] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [244576] = {"spell;created=1237514", "INVTYPE_WRIST"},
            [250007] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249374] = {"npc;drop=256116", "INVTYPE_WAIST"},
            [251087] = {"npc;drop=231626", "INVTYPE_LEGS"},
            [249382] = {"npc;drop=244761", "INVTYPE_FEET"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [193701] = {"npc;drop=190609", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["ROGUE"][2] = {
        ["BISO"] = {
            [260423] = {"npc;drop=244761", "INVTYPE_WEAPON"},
            [133491] = {"npc;drop=36476", "INVTYPE_WEAPON"},
            [151336] = {"npc;drop=122313", "INVTYPE_HEAD"},
            [50228] = {"npc;drop=36494", "INVTYPE_NECK"},
            [250004] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249335] = {"npc;drop=240435", "INVTYPE_CLOAK"},
            [250009] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [50264] = {"npc;drop=36476", "INVTYPE_WRIST"},
            [250007] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249374] = {"npc;drop=256116", "INVTYPE_WAIST"},
            [250005] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [244569] = {"spell;created=1237508", "INVTYPE_FEET"},
            [249336] = {"npc;drop=240434", "INVTYPE_FINGER"},
            [240949] = {"spell;created=1230485", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [260235] = {"npc;drop=246729", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["ROGUE"][3] = {
        ["BISO"] = {
            [250006] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [250004] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [258575] = {"npc;drop=75964", "INVTYPE_CLOAK"},
            [250009] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249327] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [250007] = {"catalyst/unknown", "INVTYPE_HAND"},
            [244573] = {"spell;created=1237513", "INVTYPE_WAIST"},
            [133499] = {"npc;drop=36658", "INVTYPE_LEGS"},
            [258577] = {"npc;drop=76141", "INVTYPE_FEET"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [251115] = {"npc;drop=231864", "INVTYPE_FINGER"},
            [249344] = {"npc;drop=240435", "INVTYPE_TRINKET"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249925] = {"npc;drop=240434", "INVTYPE_WEAPON"},
            [237837] = {"spell;created=1229659", "INVTYPE_WEAPON"},
        },
    }

    BIS["RETAIL"]["SHAMAN"] = {}
    BIS["RETAIL"]["SHAMAN"][1] = {
        ["BISO"] = {
            [251083] = {"npc;drop=231626", "INVTYPE_WEAPON"},
            [251105] = {"npc;drop=231863", "INVTYPE_SHIELD"},
            [249979] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249977] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249974] = {"catalyst/unknown", "INVTYPE_CLOAK"},
            [249982] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249304] = {"npc;drop=240432", "INVTYPE_WRIST"},
            [249980] = {"catalyst/unknown", "INVTYPE_HAND"},
            [244611] = {"spell;created=1237519", "INVTYPE_WAIST"},
            [251215] = {"npc;drop=241546", "INVTYPE_LEGS"},
            [244610] = {"spell;created=1237518", "INVTYPE_FEET"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [249919] = {"npc;drop=246729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [250144] = {"npc;drop=231606", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["SHAMAN"][2] = {
        ["BISO"] = {},
    }

    BIS["RETAIL"]["SHAMAN"][3] = {
        ["BISO"] = {
            [249914] = {"npc;drop=214650", "INVTYPE_HEAD"},
            [251096] = {"npc;drop=231636", "INVTYPE_NECK"},
            [249977] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [251161] = {"npc;drop=248595", "INVTYPE_CLOAK"},
            [249982] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249975] = {"catalyst/unknown", "INVTYPE_WRIST"},
            [249980] = {"catalyst/unknown", "INVTYPE_HAND"},
            [193722] = {"npc;drop=191736", "INVTYPE_WAIST"},
            [249978] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249981] = {"catalyst/unknown", "INVTYPE_FEET"},
            [249336] = {"npc;drop=240434", "INVTYPE_FINGER"},
            [193708] = {"npc;drop=194181", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249809] = {"npc;drop=244761", "INVTYPE_TRINKET"},
            [251178] = {"npc;drop=248595", "INVTYPE_WEAPON"},
            [249921] = {"npc;drop=246729", "INVTYPE_SHIELD"},
        },
    }

    BIS["RETAIL"]["WARLOCK"] = {}
    BIS["RETAIL"]["WARLOCK"][1] = {
        ["BISO"] = {
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249276] = {"npc;drop=240434", "INVTYPE_HOLDABLE"},
            [250042] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [251085] = {"npc;drop=231626", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250045] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249315] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [250043] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250041] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249305] = {"npc;drop=242056", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [241140] = {"spell;created=1230487", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [250144] = {"npc;drop=231606", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["WARLOCK"][2] = {
        ["BISO"] = {
            [193707] = {"npc;drop=190609", "INVTYPE_2HWEAPON"},
            [250042] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [50228] = {"npc;drop=36494", "INVTYPE_NECK"},
            [251085] = {"npc;drop=231626", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250045] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249315] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [250043] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250041] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249373] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [241140] = {"spell;created=1230487", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249810] = {"npc;drop=214650", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["WARLOCK"][3] = {
        ["BISO"] = {
            [249283] = {"npc;drop=246729", "INVTYPE_WEAPON"},
            [249276] = {"npc;drop=240434", "INVTYPE_HOLDABLE"},
            [250042] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [249328] = {"npc;drop=246729", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [250045] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249315] = {"npc;drop=240434", "INVTYPE_WRIST"},
            [250043] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249376] = {"npc;drop=246729", "INVTYPE_WAIST"},
            [250041] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249305] = {"npc;drop=242056", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [241140] = {"spell;created=1230487", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249346] = {"npc;drop=242056", "INVTYPE_TRINKET"},
        },
    }

    BIS["RETAIL"]["WARRIOR"] = {}
    BIS["RETAIL"]["WARRIOR"][1] = {
        ["BISO"] = {
            [249952] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [249337] = {"npc;drop=240432", "INVTYPE_NECK"},
            [249950] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [249955] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [251081] = {"npc;drop=231606", "INVTYPE_HAND"},
            [249949] = {"catalyst/unknown", "INVTYPE_WAIST"},
            [249951] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [251217] = {"npc;drop=241546", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249342] = {"npc;drop=240434", "INVTYPE_TRINKET"},
            [249296] = {"npc;drop=214650", "INVTYPE_2HWEAPON"},
        },
    }

    BIS["RETAIL"]["WARRIOR"][2] = {
        ["BISO"] = {
            [249952] = {"catalyst/unknown", "INVTYPE_HEAD"},
            [250247] = {"npc;drop=214650", "INVTYPE_NECK"},
            [249950] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [239656] = {"spell;created=1228950", "INVTYPE_CLOAK"},
            [249955] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [237834] = {"spell;created=1229662", "INVTYPE_WRIST"},
            [249953] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249949] = {"catalyst/unknown", "INVTYPE_WAIST"},
            [249951] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249954] = {"catalyst/unknown", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [249369] = {"npc;drop=250589", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249342] = {"npc;drop=240434", "INVTYPE_TRINKET"},
            [249277] = {"npc;drop=250589", "INVTYPE_2HWEAPON"},
            [249296] = {"npc;drop=214650", "INVTYPE_2HWEAPON"},
        },
    }

    BIS["RETAIL"]["WARRIOR"][3] = {
        ["BISO"] = {
            [249295] = {"npc;drop=244761", "INVTYPE_WEAPON"},
            [249921] = {"npc;drop=246729", "INVTYPE_SHIELD"},
            [249316] = {"npc;drop=240432", "INVTYPE_HEAD"},
            [249368] = {"npc;drop=244761", "INVTYPE_NECK"},
            [249950] = {"catalyst/unknown", "INVTYPE_SHOULDER"},
            [249370] = {"npc;drop=242056", "INVTYPE_CLOAK"},
            [249955] = {"catalyst/unknown", "INVTYPE_CHEST"},
            [249326] = {"npc;drop=240435", "INVTYPE_WRIST"},
            [249953] = {"catalyst/unknown", "INVTYPE_HAND"},
            [249331] = {"npc;drop=242056", "INVTYPE_WAIST"},
            [249951] = {"catalyst/unknown", "INVTYPE_LEGS"},
            [249381] = {"npc;drop=256116", "INVTYPE_FEET"},
            [249920] = {"npc;drop=214650", "INVTYPE_FINGER"},
            [151311] = {"npc;drop=124729", "INVTYPE_FINGER"},
            [249343] = {"npc;drop=256116", "INVTYPE_TRINKET"},
            [249342] = {"npc;drop=240434", "INVTYPE_TRINKET"},
        },
    }
end
