-- By D4KiR
local _, SpecBisTooltip = ...
local BIS = {}
if SpecBisTooltip:GetWoWBuild() == "TBC" then
    function SpecBisTooltip:GetBisTable()
        return BIS
    end
end

-- DATA FROM: 07.02.2026
if SpecBisTooltip:GetWoWBuild() == "TBC" then
    BIS["TBC"] = {}
    BIS["TBC"]["DRUID"] = {}
    BIS["TBC"]["DRUID"][1] = {
        [29093] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [29095] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28766] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21848] = {"BIS,PVE,P1", "spell;created=26754", "INVTYPE_CHEST"},
        [29523] = {"BIS,PVE,P1", "spell;created=35588", "INVTYPE_WRIST"},
        [21847] = {"BIS,PVE,P1", "spell;created=26753", "INVTYPE_HAND"},
        [21846] = {"BIS,PVE,P1", "spell;created=26752", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [28517] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_FEET"},
        [28530] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_NECK"},
        [28793] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [29370] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28770] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [29271] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [27518] = {"BIS,PVE,P1", "npc;drop=16807", "INVTYPE_RELIC"},
    }

    BIS["TBC"]["DRUID"][2] = {}
    BIS["TBC"]["DRUID"][3] = {}
    BIS["TBC"]["DRUID"][4] = {
        [24264] = {"BIS,PVE,P1", "spell;created=31454", "INVTYPE_HEAD"},
        [21874] = {"BIS,PVE,P1", "spell;created=26761", "INVTYPE_SHOULDER"},
        [28765] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21875] = {"BIS,PVE,P1", "spell;created=26762", "INVTYPE_CHEST"},
        [29183] = {"BIS,PVE,P1", "npc;sold=21643", "INVTYPE_WRIST"},
        [28521] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_HAND"},
        [21873] = {"BIS,PVE,P1", "spell;created=26760", "INVTYPE_WAIST"},
        [30727] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_LEGS"},
        [30737] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_FEET"},
        [30726] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_NECK"},
        [29290] = {"BIS,PVE,P1", "quest;reward=11032", "INVTYPE_FINGER"},
        [29376] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28771] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [30732] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_2HWEAPON"},
        [29274] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [27886] = {"BIS,PVE,P1", "npc;drop=18731", "INVTYPE_RELIC"},
    }

    BIS["TBC"]["HUNTER"] = {}
    BIS["TBC"]["HUNTER"][1] = {
        [28275] = {"BIS,PVE,P1", "npc;drop=19220", "INVTYPE_HEAD"},
        [27801] = {"BIS,PVE,P1", "npc;drop=17798", "INVTYPE_SHOULDER"},
        [24259] = {"BIS,PVE,P1", "spell;created=31449", "INVTYPE_CLOAK"},
        [28228] = {"BIS,PVE,P1", "npc;drop=17977", "INVTYPE_CHEST"},
        [29246] = {"BIS,PVE,P1", "npc;drop=18096", "INVTYPE_WRIST"},
        [27474] = {"BIS,PVE,P1", "npc;drop=16808", "INVTYPE_HAND"},
        [28828] = {"BIS,PVE,P1", "npc;drop=19044", "INVTYPE_WAIST"},
        [30739] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_LEGS"},
        [28545] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_FEET"},
        [29381] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_NECK"},
        [28791] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [28830] = {"BIS,PVE,P1", "npc;drop=19044", "INVTYPE_TRINKET"},
        [27846] = {"BIS,PVE,P1", "npc;drop=18371", "INVTYPE_WEAPONMAINHAND"},
        [28572] = {"BIS,PVE,P1", "npc;drop=17534", "INVTYPE_WEAPON"},
        [28435] = {"BIS,PVE,P1", "spell;created=34544", "INVTYPE_2HWEAPON"},
        [28772] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_RANGED"},
        [31949] = {"BIS,PVE,P1", "npc;sold=17904", "INVTYPE_AMMO"},
        [32882] = {"BIS,PVE,P1", "npc;sold=17585", "INVTYPE_AMMO"},
    }

    BIS["TBC"]["HUNTER"][2] = {
        [31949] = {"BIS,PVE,P1", "npc;sold=17904", "INVTYPE_AMMO"},
        [32882] = {"BIS,PVE,P1", "npc;sold=17585", "INVTYPE_AMMO"},
    }

    BIS["TBC"]["HUNTER"][3] = {
        [31949] = {"BIS,PVE,P1", "npc;sold=17904", "INVTYPE_AMMO"},
        [32882] = {"BIS,PVE,P1", "npc;sold=17585", "INVTYPE_AMMO"},
    }

    BIS["TBC"]["MAGE"] = {}
    BIS["TBC"]["MAGE"][1] = {
        [29076] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [29079] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28797] = {"BIS,PVE,P1", "npc;drop=18831", "INVTYPE_CLOAK"},
        [21848] = {"BIS,PVE,P1", "spell;created=26754", "INVTYPE_CHEST"},
        [28411] = {"BIS,PVE,P1", "npc;sold=12792", "INVTYPE_WRIST"},
        [21847] = {"BIS,PVE,P1", "spell;created=26753", "INVTYPE_HAND"},
        [21846] = {"BIS,PVE,P1", "spell;created=26752", "INVTYPE_WAIST"},
        [29078] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_LEGS"},
        [28517] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_FEET"},
        [28762] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_NECK"},
        [28793] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [28785] = {"BIS,PVE,P1", "npc;drop=15688", "INVTYPE_TRINKET"},
        [30723] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_WEAPONMAINHAND"},
        [29271] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28783] = {"BIS,PVE,P1", "npc;drop=17257", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["MAGE"][2] = {
        [29076] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [29079] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28766] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21848] = {"BIS,PVE,P1", "spell;created=26754", "INVTYPE_CHEST"},
        [28411] = {"BIS,PVE,P1", "npc;sold=12792", "INVTYPE_WRIST"},
        [21847] = {"BIS,PVE,P1", "spell;created=26753", "INVTYPE_HAND"},
        [21846] = {"BIS,PVE,P1", "spell;created=26752", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [28585] = {"BIS,PVE,P1", "npc;drop=18168", "INVTYPE_FEET"},
        [28530] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_NECK"},
        [28793] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [29370] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [30723] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_WEAPONMAINHAND"},
        [28633] = {"BIS,PVE,P1", "npc;drop=15691", "INVTYPE_2HWEAPON"},
        [28734] = {"BIS,PVE,P1", "npc;drop=15689", "INVTYPE_HOLDABLE"},
        [28673] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["MAGE"][3] = {
        [29076] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [21869] = {"BIS,PVE,P1", "spell;created=26756", "INVTYPE_SHOULDER"},
        [28766] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21871] = {"BIS,PVE,P1", "spell;created=26758", "INVTYPE_CHEST"},
        [28411] = {"BIS,PVE,P1", "npc;sold=12792", "INVTYPE_WRIST"},
        [30725] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_HAND"},
        [24256] = {"BIS,PVE,P1", "spell;created=31443", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [21870] = {"BIS,PVE,P1", "spell;created=26757", "INVTYPE_FEET"},
        [28530] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_NECK"},
        [29287] = {"BIS,PVE,P1", "quest;reward=11033", "INVTYPE_FINGER"},
        [29370] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [30723] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_WEAPONMAINHAND"},
        [28633] = {"BIS,PVE,P1", "npc;drop=15691", "INVTYPE_2HWEAPON"},
        [29269] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28783] = {"BIS,PVE,P1", "npc;drop=17257", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["PALADIN"] = {}
    BIS["TBC"]["PALADIN"][1] = {
        [29061] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [29064] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28765] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [29062] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [29523] = {"BIS,PVE,P1", "spell;created=35588", "INVTYPE_WRIST"},
        [29065] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HAND"},
        [29524] = {"BIS,PVE,P1", "spell;created=35587", "INVTYPE_WAIST"},
        [28748] = {"BIS,PVE,P1", "npc;drop=16816", "INVTYPE_LEGS"},
        [28569] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_FEET"},
        [30726] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_NECK"},
        [28790] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [29376] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28592] = {"BIS,PVE,P1", "npc;drop=17521", "INVTYPE_RELIC"},
    }

    BIS["TBC"]["PALADIN"][2] = {}
    BIS["TBC"]["PALADIN"][3] = {}
    BIS["TBC"]["PRIEST"] = {}
    BIS["TBC"]["PRIEST"][1] = {
        [29049] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [21874] = {"BIS,PVE,P1", "spell;created=26761", "INVTYPE_SHOULDER"},
        [28765] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21875] = {"BIS,PVE,P1", "spell;created=26762", "INVTYPE_CHEST"},
        [29183] = {"BIS,PVE,P1", "npc;sold=21643", "INVTYPE_WRIST"},
        [28508] = {"BIS,PVE,P1", "npc;drop=16152", "INVTYPE_HAND"},
        [21873] = {"BIS,PVE,P1", "spell;created=26760", "INVTYPE_WAIST"},
        [30727] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_LEGS"},
        [28663] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_FEET"},
        [30726] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_NECK"},
        [30736] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_FINGER"},
        [29376] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28771] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [30732] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_2HWEAPON"},
        [29170] = {"BIS,PVE,P1", "npc;sold=17904", "INVTYPE_HOLDABLE"},
        [28588] = {"BIS,PVE,P1", "npc;drop=18168", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["PRIEST"][2] = {
        [29049] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [21874] = {"BIS,PVE,P1", "spell;created=26761", "INVTYPE_SHOULDER"},
        [28765] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [21875] = {"BIS,PVE,P1", "spell;created=26762", "INVTYPE_CHEST"},
        [29183] = {"BIS,PVE,P1", "npc;sold=21643", "INVTYPE_WRIST"},
        [28508] = {"BIS,PVE,P1", "npc;drop=16152", "INVTYPE_HAND"},
        [21873] = {"BIS,PVE,P1", "spell;created=26760", "INVTYPE_WAIST"},
        [30727] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_LEGS"},
        [28663] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_FEET"},
        [30726] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_NECK"},
        [30736] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_FINGER"},
        [29376] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28771] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [30732] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_2HWEAPON"},
        [29170] = {"BIS,PVE,P1", "npc;sold=17904", "INVTYPE_HOLDABLE"},
        [28588] = {"BIS,PVE,P1", "npc;drop=18168", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["PRIEST"][3] = {
        [24266] = {"BIS,PVE,P1", "spell;created=31455", "INVTYPE_HEAD"},
        [21869] = {"BIS,PVE,P1", "spell;created=26756", "INVTYPE_SHOULDER"},
        [31201] = {"BIS,PVE,P1", "npc;drop=18697", "INVTYPE_CLOAK"},
        [21871] = {"BIS,PVE,P1", "spell;created=26758", "INVTYPE_CHEST"},
        [30684] = {"BIS,PVE,P1", "npc;drop=16181", "INVTYPE_WRIST"},
        [31166] = {"BIS,PVE,P1", "npc;drop=18693", "INVTYPE_HAND"},
        [30675] = {"BIS,PVE,P1", "npc;drop=16179", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [30680] = {"BIS,PVE,P1", "npc;drop=16180", "INVTYPE_FEET"},
        [30666] = {"BIS,PVE,P1", "npc;drop=16485", "INVTYPE_NECK"},
        [21709] = {"BIS,PVE,P1", "quest;reward=8802", "INVTYPE_FINGER"},
        [29370] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28770] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [29272] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [25295] = {"BIS,PVE,P1", "npc;drop=23281", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["ROGUE"] = {}
    BIS["TBC"]["ROGUE"][1] = {
        [29044] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [27797] = {"BIS,PVE,P1", "npc;drop=18478", "INVTYPE_SHOULDER"},
        [28672] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_CLOAK"},
        [29045] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [29246] = {"BIS,PVE,P1", "npc;drop=18096", "INVTYPE_WRIST"},
        [27531] = {"BIS,PVE,P1", "npc;drop=16808", "INVTYPE_HAND"},
        [29247] = {"BIS,PVE,P1", "npc;drop=17881", "INVTYPE_WAIST"},
        [28741] = {"BIS,PVE,P1", "npc;drop=15689", "INVTYPE_LEGS"},
        [28545] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_FEET"},
        [29381] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_NECK"},
        [28757] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_FINGER"},
        [28830] = {"BIS,PVE,P1", "npc;drop=19044", "INVTYPE_TRINKET"},
        [28438] = {"BIS,PVE,P1", "spell;created=34546", "INVTYPE_WEAPONMAINHAND"},
        [28307] = {"BIS,PVE,P1", "npc;sold=25176", "INVTYPE_SHIELD"},
        [29151] = {"BIS,PVE,P1", "npc;sold=17657", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["ROGUE"][2] = {
        [29044] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [27797] = {"BIS,PVE,P1", "npc;drop=18478", "INVTYPE_SHOULDER"},
        [28672] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_CLOAK"},
        [29045] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [29246] = {"BIS,PVE,P1", "npc;drop=18096", "INVTYPE_WRIST"},
        [27531] = {"BIS,PVE,P1", "npc;drop=16808", "INVTYPE_HAND"},
        [29247] = {"BIS,PVE,P1", "npc;drop=17881", "INVTYPE_WAIST"},
        [28741] = {"BIS,PVE,P1", "npc;drop=15689", "INVTYPE_LEGS"},
        [28545] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_FEET"},
        [29381] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_NECK"},
        [28757] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_FINGER"},
        [28830] = {"BIS,PVE,P1", "npc;drop=19044", "INVTYPE_TRINKET"},
        [28438] = {"BIS,PVE,P1", "spell;created=34546", "INVTYPE_WEAPONMAINHAND"},
        [28307] = {"BIS,PVE,P1", "npc;sold=25176", "INVTYPE_SHIELD"},
        [29151] = {"BIS,PVE,P1", "npc;sold=17657", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["ROGUE"][3] = {
        [29044] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [27797] = {"BIS,PVE,P1", "npc;drop=18478", "INVTYPE_SHOULDER"},
        [28672] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_CLOAK"},
        [29045] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [29246] = {"BIS,PVE,P1", "npc;drop=18096", "INVTYPE_WRIST"},
        [27531] = {"BIS,PVE,P1", "npc;drop=16808", "INVTYPE_HAND"},
        [29247] = {"BIS,PVE,P1", "npc;drop=17881", "INVTYPE_WAIST"},
        [28741] = {"BIS,PVE,P1", "npc;drop=15689", "INVTYPE_LEGS"},
        [28545] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_FEET"},
        [29381] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_NECK"},
        [28757] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_FINGER"},
        [28830] = {"BIS,PVE,P1", "npc;drop=19044", "INVTYPE_TRINKET"},
        [28438] = {"BIS,PVE,P1", "spell;created=34546", "INVTYPE_WEAPONMAINHAND"},
        [28307] = {"BIS,PVE,P1", "npc;sold=25176", "INVTYPE_SHIELD"},
        [29151] = {"BIS,PVE,P1", "npc;sold=17657", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["SHAMAN"] = {}
    BIS["TBC"]["SHAMAN"][1] = {
        [29035] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [29037] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28797] = {"BIS,PVE,P1", "npc;drop=18831", "INVTYPE_CLOAK"},
        [29519] = {"BIS,PVE,P1", "spell;created=35580", "INVTYPE_CHEST"},
        [29521] = {"BIS,PVE,P1", "spell;created=35584", "INVTYPE_WRIST"},
        [28780] = {"BIS,PVE,P1", "npc;drop=21174", "INVTYPE_HAND"},
        [29520] = {"BIS,PVE,P1", "spell;created=35582", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [28517] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_FEET"},
        [28762] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_NECK"},
        [30667] = {"BIS,PVE,P1", "npc;drop=184259", "INVTYPE_FINGER"},
        [28785] = {"BIS,PVE,P1", "npc;drop=15688", "INVTYPE_TRINKET"},
        [30723] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_WEAPONMAINHAND"},
        [29273] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28248] = {"BIS,PVE,P1", "object;contained=184465", "INVTYPE_RELIC"},
    }

    BIS["TBC"]["SHAMAN"][2] = {}
    BIS["TBC"]["SHAMAN"][3] = {
        [24264] = {"BIS,PVE,P1", "spell;created=31454", "INVTYPE_HEAD"},
        [29031] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28765] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [29522] = {"BIS,PVE,P1", "spell;created=35585", "INVTYPE_CHEST"},
        [29523] = {"BIS,PVE,P1", "spell;created=35588", "INVTYPE_WRIST"},
        [28520] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_HAND"},
        [29524] = {"BIS,PVE,P1", "spell;created=35587", "INVTYPE_WAIST"},
        [30727] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_LEGS"},
        [30737] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_FEET"},
        [30726] = {"BIS,PVE,P1", "npc;drop=17711", "INVTYPE_NECK"},
        [28763] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_FINGER"},
        [29376] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_TRINKET"},
        [28771] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_WEAPONMAINHAND"},
        [30732] = {"BIS,PVE,P1", "npc;drop=18728", "INVTYPE_2HWEAPON"},
        [29274] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28523] = {"BIS,PVE,P1", "npc;drop=16457", "INVTYPE_RELIC"},
    }

    BIS["TBC"]["WARLOCK"] = {}
    BIS["TBC"]["WARLOCK"][1] = {
        [28963] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [28967] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28766] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [28964] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [24250] = {"BIS,PVE,P1", "spell;created=31435", "INVTYPE_WRIST"},
        [28968] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HAND"},
        [24256] = {"BIS,PVE,P1", "spell;created=31443", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [21870] = {"BIS,PVE,P1", "spell;created=26757", "INVTYPE_FEET"},
        [28530] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_NECK"},
        [28793] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [27683] = {"BIS,PVE,P1", "npc;drop=17942", "INVTYPE_TRINKET"},
        [22630] = {"BIS,PVE,P1", "quest;reward=9271", "INVTYPE_2HWEAPON"},
        [29273] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28673] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["WARLOCK"][2] = {}
    BIS["TBC"]["WARLOCK"][3] = {
        [28963] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_HEAD"},
        [28967] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_SHOULDER"},
        [28766] = {"BIS,PVE,P1", "npc;drop=15690", "INVTYPE_CLOAK"},
        [28964] = {"BIS,PVE,P1", "npc;sold=20613", "INVTYPE_CHEST"},
        [24250] = {"BIS,PVE,P1", "spell;created=31435", "INVTYPE_WRIST"},
        [21847] = {"BIS,PVE,P1", "spell;created=26753", "INVTYPE_HAND"},
        [21846] = {"BIS,PVE,P1", "spell;created=26752", "INVTYPE_WAIST"},
        [24262] = {"BIS,PVE,P1", "spell;created=31452", "INVTYPE_LEGS"},
        [21870] = {"BIS,PVE,P1", "spell;created=26757", "INVTYPE_FEET"},
        [28530] = {"BIS,PVE,P1", "npc;drop=15687", "INVTYPE_NECK"},
        [28793] = {"BIS,PVE,P1", "quest;reward=11002", "INVTYPE_FINGER"},
        [27683] = {"BIS,PVE,P1", "npc;drop=17942", "INVTYPE_TRINKET"},
        [22630] = {"BIS,PVE,P1", "quest;reward=9271", "INVTYPE_2HWEAPON"},
        [29270] = {"BIS,PVE,P1", "npc;sold=18525", "INVTYPE_HOLDABLE"},
        [28673] = {"BIS,PVE,P1", "npc;drop=16524", "INVTYPE_RANGED"},
    }

    BIS["TBC"]["WARRIOR"] = {}
    BIS["TBC"]["WARRIOR"][1] = {
        [28429] = {"BIS,PVE,P1", "spell;created=34540", "INVTYPE_2HWEAPON"},
    }

    BIS["TBC"]["WARRIOR"][2] = {
        [28429] = {"BIS,PVE,P1", "spell;created=34540", "INVTYPE_2HWEAPON"},
    }

    BIS["TBC"]["WARRIOR"][3] = {}
end
