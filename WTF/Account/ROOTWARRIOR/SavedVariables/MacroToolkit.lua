
MacroToolkitDB = {
["char"] = {
["Starphage - Tichondrius"] = {
["macros"] = {
[131] = {
["name"] = " ",
["icon"] = "1380368",
["body"] = "#showtooltip\n/cast [mod:shift,@focus,exists,harm,nodead][] Imprison\n",
},
[135] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip \n/cast [@cursor] Sigil of Chains\n",
},
[139] = {
["name"] = " ",
["icon"] = "7554213",
["body"] = "#showtooltip\n/cast [@cursor] Shift\n",
},
[143] = {
["name"] = " ",
["icon"] = "7554169",
["body"] = "#showtooltip Vengeful Retreat\n/castsequence reset=1 Vengeful Retreat, Glide\n",
},
[122] = {
["name"] = " ",
["icon"] = "828455",
["body"] = "#showtooltip Consume Magic\n/cast  [@mouseover,exists,harm,nodead][] Consume Magic\n",
},
[124] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip \n/stopcasting \n/cast Felblade \n",
},
[126] = {
["name"] = " ",
["icon"] = "7554162",
["body"] = "#showtooltip\n/cast [mod:shift,@focus,exists,harm,nodead][] Disrupt\n/use Goblin Weather Machine - Prototype 01-B\n",
},
[128] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast  [@mouseover,exists][] Fel Eruption\n",
},
[132] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@cursor] Infernal Strike\n",
},
[136] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip \n/cast [@cursor] Sigil of Flame\n",
},
[140] = {
["name"] = " ",
["icon"] = "7554200",
["body"] = "#showtooltip Consume\n/cast [nochanneling] Consume\n",
},
[144] = {
["name"] = " STOP",
["icon"] = "1345086",
["body"] = "/stopcasting\n",
},
[129] = {
["name"] = " ",
["icon"] = "425957",
["body"] = "#showtooltip\n/cast Immolation Aura\n/use FIre-Eater's Vial\n",
},
[133] = {
["name"] = " ",
["icon"] = "1418287",
["body"] = "#showtooltip \n/cast [@cursor] Sigil of Misery\n",
},
[137] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip \n/cast [@cursor] Sigil of Spite\n",
},
[141] = {
["name"] = " ",
["icon"] = "7554210",
["body"] = "#showtooltip Reap\n/cast [nochanneling] Reap\n",
},
[121] = {
["name"] = " ",
["icon"] = "1344654",
["body"] = "#showtooltip Torment\n/cast [@mouseover,exists, harm, nodead][] Torment\n",
},
[123] = {
["name"] = " ",
["icon"] = "7554200",
["body"] = "#showtooltip Demon's Bite\n/startattack\n/cast Demon's Bite\n",
},
[125] = {
["name"] = " ",
["icon"] = "7554210",
["body"] = "#showtooltip Chaos Strike\n/cast [nochanneling] Chaos Strike\n",
},
[127] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip Blade Dance\n/cast [nochanneling] Blade Dance\n/cast [nochanneling] Prismatic Bauble\n",
},
[130] = {
["name"] = " ",
["icon"] = "7135881",
["body"] = "#showtooltip Metamorphosis\n/use Tempered Potion\n/cast [@cursor] Metamorphosis\n",
},
[134] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip The Hunt\n/castsequence reset=2 the hunt\n",
},
[138] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "/run SetView(5)\n/run SetView(5)\n/script FlipCameraYaw(180)\n",
},
[142] = {
["name"] = " ",
["icon"] = "7554220",
["body"] = "#showtooltip void ray\n/cast [nochanneling] Void ray\n",
},
[146] = {
["name"] = "Outfit Collection",
["icon"] = "2869702",
["body"] = "#plumber:outfit\n/click PLMR_OUTFIT\n",
},
[145] = {
["name"] = "Full Combo",
["icon"] = "134400",
["body"] = "#showtooltip\n/castsequence reset=90 The Hunt, Hungering Slash, Vengeful Retreat, Voidblade, Hungering Slash, Vengeful Retreat\n",
},
[147] = {
["name"] = "Teleport Home",
["icon"] = "7252953",
["body"] = "#plumber:home\n/click PLMR_HOME1\n",
},
},
["classFile"] = "DEMONHUNTER",
},
["Stormclout - Tichondrius"] = {
["classFile"] = "MONK",
["macros"] = {
[131] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover, exists,help][] Soothing Mist\n",
},
[135] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@cursor] Summon Jade Serpent Statue\n",
},
[139] = {
["icon"] = "839107",
["name"] = " ",
["body"] = "#showtooltip\n/cast [known: Ring of peace, @cursor] Ring of Peace\n/cast [known: Song of chi-ji] Song of chi-ji\n",
},
[143] = {
["icon"] = "606543",
["name"] = " ",
["body"] = "#showtooltip Spinning Crane Kick\n/use Fire-Eater's Vial\n/cast Spinning Crane Kick\n",
},
[122] = {
["icon"] = "642414",
["name"] = " ",
["body"] = "#showtooltip\n/cancelaura Flying Serpent Kick\n/cancelaura Roll\n/cancelaura Chi Torpedo\n/cast Leg Sweep\n",
},
[124] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Life Cocoon\n",
},
[126] = {
["icon"] = "629534",
["name"] = " ",
["body"] = "#showtooltip Paralysis\n/cast [mod:shift,@focus,exists,harm,nodead][] Paralysis\n",
},
[128] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover, exists,help][] Enveloping Mist\n",
},
[132] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast Breath of fire\n/use Fire-eater's Vial\n",
},
[136] = {
["icon"] = "988194",
["name"] = " ",
["body"] = "#showtooltip [known: Whirling Dragon Punch] Whirling Dragon Punch; [known: Strike of the Windlord] Strike of the Windlord\n/cast [known: Whirling Dragon Punch] Whirling Dragon Punch\n/cast [known: Strike of the Windlord] Strike of the Windlord\n",
},
[140] = {
["icon"] = "6035314",
["name"] = " ",
["body"] = "#showtooltip Zenith\n/cast Zenith\n/use Saltwater Potion\n/cast Blood Fury\n/cast Beserking\n/use Perpetual Purple Firework\n/use Winning Hand\n",
},
[144] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip Disable\n/use [@target,exists] Disable\n",
},
[129] = {
["icon"] = "1360980",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover, exists,help][] Vivify\n",
},
[133] = {
["icon"] = "574575",
["name"] = " ",
["body"] = "#showtooltip Blackout Kick\n/stopmacro [channeling:Fists of Fury]\n/stopmacro [channeling:Crackling Jade Lightning]\n/stopmacro [channeling:Spinning Crane Kick]\n/stopmacro [channeling:Celestial Conduit]\n/cast Blackout Kick\n",
},
[137] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@cursor] Summon Black Ox Statue\n",
},
[141] = {
["icon"] = "574574",
["name"] = " ",
["body"] = "#showtooltip\n/cast roll\n/cast Prismatic Bauble\n",
},
[121] = {
["icon"] = "642415",
["name"] = " ",
["body"] = "#showtooltip Rising Sun Kick\n/cast Rising Sun Kick\n",
},
[123] = {
["icon"] = "606551",
["name"] = " ",
["body"] = "#showtooltip Tiger Palm\n/stopmacro [channeling:Fists of Fury]\n/stopmacro [channeling:Crackling Jade Lightning]\n/stopmacro [channeling:Spinning Crane Kick]\n/stopmacro [channeling:Celestial Conduit]\n/cast Tiger Palm\n/petattack\n",
},
[125] = {
["icon"] = "651727",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists] Tiger's Lust; [@player] Tiger's Lust;\n",
},
[127] = {
["icon"] = "608940",
["name"] = " ",
["body"] = "#showtooltip\n/cast  [@focus,exists,mod:shift,harm,nodead][] Spear Hand Strike\n/use Goblin Weather Machine - Prototype 01-B\n",
},
[130] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover, exists,help][] Renewing Mist\n",
},
[134] = {
["icon"] = "135734",
["name"] = " ",
["body"] = "#showtooltip [known:Chi burst] Chi Burst;[known: chi wave] Chi wave;\n/cast [known:Chi Burst] Chi burst;\n/cast [known:Chi Wave] Chi wave\n/use Goblin Weather Machine - Prototype 01-B\n",
},
[138] = {
["icon"] = "134400",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@cursor] Exploding Keg\n",
},
[142] = {
["icon"] = "606552",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover, exists, harm][] Touch of Death\n/use Seafarer's Slidewhistle\n",
},
[146] = {
["icon"] = "236356",
["name"] = "Cancel",
["body"] = "/cancelaura Zen Flight\n/cancelaura Blessing of Protection\n/cancelaura Blessing of Freedom\n/cancelaura Slow Fall\n/cancelaura Flying Serpent Kick\n/cancelaura Parachute\n/dismount\n/stopcasting\n",
},
[147] = {
["icon"] = "615340",
["name"] = "Dismiss",
["body"] = "/run if not UnitAffectingCombat(\"player\")then for i=1,4 do n=\"t\"..i CreateFrame(\"Button\",n,UIParent,\"SecureUnitButtonTemplate\")_G[n]:SetAttribute(\"type\", \"destroytotem\")_G[n]:SetAttribute(\"totem-slot\",i)end end\n/click t1\n/click t2\n/click t3\n/click t4\n",
},
[145] = {
["icon"] = "620830",
["name"] = "Black Ox",
["body"] = "#showtooltip Provoke\n/targetexact Black Ox Statue\n/cast Provoke\n/targetlasttarget\n",
},
},
["backups"] = {
},
},
["Neonvoid - Tichondrius"] = {
["macros"] = {
[131] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists] Rapture;[] Rapture\n",
},
[135] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Renew\n",
},
[139] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtoolip\n/cast [mod:shift,@focus,exists,harm,nodead][] Psychic Horror\n",
},
[143] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists,nodead][] Void shift\n",
},
[122] = {
["name"] = " ",
["icon"] = "463835",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists,nodead][] Leap of Faith\n",
},
[124] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip [known: Void Eruption] Void Eruption; [known: Dark Ascension] Dark Ascension\n/use 13\n/use Tempered Potion\n/cast [known: Void Eruption] Void Eruption\n/cast [known: Dark Ascension] Dark Ascension\n",
},
[126] = {
["name"] = " ",
["icon"] = "135987",
["body"] = "#showtooltip\n/cast [@player] Power Word: Fortitude\n/use Goblin Weather Machine - Prototype 01-B\n/use Thaumaturgist's Orb\n",
},
[128] = {
["name"] = " ",
["icon"] = "237563",
["body"] = "#showtooltip Dispersion\n/use Thaumaturgist's Orb\n/cast Dispersion\n",
},
[132] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Pain Suppression\n",
},
[136] = {
["name"] = " ",
["icon"] = "135907",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Flash Heal\n",
},
[140] = {
["name"] = " ",
["icon"] = "458230",
["body"] = "#showtooltip\n/cancelaura Dispersion\n/cast [mod:shift,@focus,exists,harm,nodead][] Silence\n",
},
[144] = {
["name"] = " ",
["icon"] = "1386548",
["body"] = "#showtooltip Voidform\n/cast [@focus,exists,help,nodead] Power Infusion;[@mouseover,help,exists,nodead] Power Infusion;[] Power Infusion;\n/cast Voidform\n",
},
[129] = {
["name"] = " ",
["icon"] = "135928",
["body"] = "#showtooltip\n/cast [@player] Levitate\n/cancelaura levitate\n",
},
[133] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Power Word: Life\n",
},
[137] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [@cursor] Power Word: Barrier\n",
},
[141] = {
["name"] = " ",
["icon"] = "136206",
["body"] = "#showtooltip Mind Control\n/cast [nochanneling: Mind Control,mod:shift,@focus,exists,harm,nodead][nochanneling: Mind Control] Mind Controll\n/stopcasting [channeling: Mind Control]\n",
},
[121] = {
["name"] = " ",
["icon"] = "642580",
["body"] = "#showtooltip\n/cast [nomod,@player] Angelic Feather;[mod:shift,@cursor] Angelic Feather; [@player] Angelic Feather;\n/use prismatic bauble\n",
},
[123] = {
["name"] = " ",
["icon"] = "135940",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists][] Power Word: Shield\n",
},
[125] = {
["name"] = " ",
["icon"] = "135939",
["body"] = "#showtooltip Power Infusion\n/cast [@focus,exists,help,nodead] Power Infusion;[@mouseover,help,exists,nodead] Power Infusion;[] Power Infusion;\n",
},
[127] = {
["name"] = " ",
["icon"] = "135978",
["body"] = "#showtooltip\n/cast [@mouseover,harm,exists][] Vampiric Touch\n",
},
[130] = {
["name"] = " ",
["icon"] = "135739",
["body"] = "#showtooltip\n/cast [@cursor] Mass Dispel\n",
},
[134] = {
["name"] = " ",
["icon"] = "136207",
["body"] = "#showtooltip\n/cast [@mouseover,harm,exists][] Shadow Word: Pain\n",
},
[138] = {
["name"] = " ",
["icon"] = "134400",
["body"] = "#showtooltip\n/cast [known:457042] Shadow Crash\n/cast [known:205385, @cursor] Shadow Crash\n",
},
[142] = {
["name"] = " ",
["icon"] = "136224",
["body"] = "#showtooltip mind blast\n/cancelaura Dispersion\n/cast Mind Blast\n",
},
},
["classFile"] = "PRIEST",
["backups"] = {
},
},
},
["global"] = {
["backups"] = {
},
["ebackups"] = {
},
},
["profileKeys"] = {
["Starphage - Tichondrius"] = "profile",
["Stormclout - Tichondrius"] = "profile",
["Neonvoid - Tichondrius"] = "profile",
},
["profiles"] = {
["profile"] = {
["x"] = 854.62353515625,
["height"] = 423.9999694824219,
["scale"] = 1.4,
["override"] = true,
["confirmdelete"] = false,
["visconditions"] = true,
["width"] = 638.0001220703125,
["fonts"] = {
["edfont"] = "1",
["mifont"] = "1",
["mfont"] = "1",
["errfont"] = "1",
},
["y"] = 251.2262420654297,
},
},
}
