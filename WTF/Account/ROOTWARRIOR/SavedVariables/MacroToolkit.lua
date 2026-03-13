
MacroToolkitDB = {
["char"] = {
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
["icon"] = "620830",
["name"] = "Black Ox",
["body"] = "#showtooltip Provoke\n/targetexact Black Ox Statue\n/cast Provoke\n/targetlasttarget\n",
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
["body"] = "#showtooltip Zenith\n/use Saltwater Potion\n/cast Zenith\n",
},
[144] = {
["icon"] = "615340",
["name"] = "Dismiss",
["body"] = "/run if not UnitAffectingCombat(\"player\")then for i=1,4 do n=\"t\"..i CreateFrame(\"Button\",n,UIParent,\"SecureUnitButtonTemplate\")_G[n]:SetAttribute(\"type\", \"destroytotem\")_G[n]:SetAttribute(\"totem-slot\",i)end end\n/click t1\n/click t2\n/click t3\n/click t4\n",
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
["body"] = "#showtooltip Tiger Palm\n/stopmacro [channeling:Fists of Fury]\n/stopmacro [channeling:Crackling Jade Lightning]\n/stopmacro [channeling:Spinning Crane Kick]\n/stopmacro [channeling:Celestial Conduit]\n/cast Tiger Palm\n",
},
[125] = {
["icon"] = "651727",
["name"] = " ",
["body"] = "#showtooltip\n/cast [@mouseover,help,exists] Tiger's Lust; [@player] Tiger's Lust;\n/use Perpetual Purple Firework\n",
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
[145] = {
["icon"] = "7252953",
["name"] = "Teleport Home",
["body"] = "#plumber:home\n/click PLMR_HOME1\n",
},
},
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
["Stormclout - Tichondrius"] = "profile",
},
["profiles"] = {
["profile"] = {
["x"] = 845.69482421875,
["confirmdelete"] = false,
["override"] = true,
["scale"] = 1.2,
["visconditions"] = true,
["width"] = 637.9999389648438,
["fonts"] = {
["edfont"] = "1",
["mifont"] = "1",
["mfont"] = "1",
["errfont"] = "1",
},
["y"] = 332.2777099609375,
},
},
}
