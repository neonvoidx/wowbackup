
TD_DB_BATTLEPETSCRIPT_GLOBAL = {
["global"] = {
["version"] = "0.0.0.0",
["scripts"] = {
["AllInOne"] = {
},
["FirstEnemy"] = {
},
["Base"] = {
},
["Rematch"] = {
["team:13"] = {
["name"] = "Little Tommy Newcomer",
["code"] = "if [self(#2).dead]\nchange(#3) [self(#1).power=284 & self(#1).hp>533]\nchange(#3) [self(#1).power=305 & self(#1).hp>569]\nchange(#1)\nendif\n\nuse(Murder the Innocent:2223)\nuse(Bombing Run:647)\nuse(Flyby:515) [round=3]\nuse(Explode:282)",
},
["team:6"] = {
["name"] = "Wise Mari",
["code"] = "ability(Blingtron Gift Package:989) [ enemy.aura(Make it Rain:986).duration=1 ]\nability(Make it Rain:985)\nability(Inflation:1002)\nability(Consume Magic:1231) [ self.aura(Whirlpool:512).exists ]\nability(Creeping Ooze:448)\nchange(#2)",
},
["team:7"] = {
["name"] = "Blingtron 4000",
["code"] = "ability(Pump:297) [round~1,3]\nability(Water Jet:118)\n\nability(Nature's Ward:574) [!self.aura(Nature's Ward:820).exists]\nability(Hawk Eye:521) [!self.aura(Hawk Eye:520).exists]\nability(Claw:429)\n\nability(Conflagrate:179) [enemy.aura(Immolate:177).exists]\nability(Immolate:178) [!enemy.aura(Immolate:177).exists]\nability(Burn:113)\n\nchange(next)",
},
["team:4"] = {
["name"] = "Ashlei",
["code"] = "use(Explode:282) [ enemy(#2).active & enemy.hp.can_explode ]\nuse(Bombing Run:647) [ enemy(#2).active & enemy.hp.full ]\nuse(Breath:115)",
},
["team:10"] = {
["name"] = "Zao, Calfling of Niuzao",
["code"] = "use(Fel Immolate:901) [round=1]\nuse(Call Lightning:204) [round=2]\nchange(Zandalari Anklerender:1211) [round=3]\nuse(Black Claw:919) [round=4]\nuse(Hunting Party:921) [round=5]",
},
["team:39"] = {
["name"] = "Miniature Army",
["code"] = "use(Swarm of Flies:232) [ !enemy.aura(Swarm of Flies:231).exists ]\nuse(Swarm of Flies:232) [ enemy.aura(Dodge:311).exists ]\nuse(Bubble:934)\nuse(Water Jet:118)\nuse(Bombing Run:647)\nuse(Decoy:334)\nuse(Missile:777)\nuse(Supercharge:208) [ self.aura(Wind-Up:458).exists & enemy.hp>1000 ]\nuse(Wind-Up:459) [ enemy.hp>700 ]\nuse(Toxic Smoke:640)\nchange(next)",
},
["team:16"] = {
["name"] = "Sully \"The Pickle\" McLeary",
["code"] = "ability(Flyby:515) [round=1]\nchange(#2) [enemy(#2).active&ally(#1).active]\nability(Swarm:706) [!enemy.aura(Shattered Defenses:542).exists]\nability(Flurry:360)\n\nability(Uncanny Luck:252) [enemy(#3).active&ally.aura(Uncanny Luck:251).duration<3]\nchange(#3) [enemy(#3).active&ally.aura(Uncanny Luck:251).exists&ally(#2).active]\nability(Prowl:536)\nability(Bite:110)\nability(Uncanny Luck:252)\n\nability(Nocturnal Strike:517) [weather(Darkness:257)]\nability(Call Darkness:256)\nability(Murder:870)\n\nchange(next)",
},
["team:5"] = {
["name"] = "Vesharr",
["code"] = "ability(Arcane Explosion:299)\nability(Explode:282) [enemy.aura(Mechanical:244).exists]\nability(Thunderbolt:779) [!enemy.aura(Flying Mark:1420).exists]\nability(Breath:115)\nchange(#2)",
},
["team:31"] = {
["name"] = "Drilling Down",
["code"] = "standby [self(#3).active]\nchange(#1) [round=3]\nchange(#2) [round=2]\nuse(Blistering Cold:786) [round=1]\nuse(Black Claw:919) [!enemy.aura(Black Claw:918).exists]\nuse(Leap:364) [self.speed.slow]\nuse(#1)\nchange(next)\n\n-- This script was generated with wow-petsim.com",
},
["team:17"] = {
["name"] = "Taran Zhu",
["code"] = "ability(Call Lightning:204)\nstandby [ round=2 ]\n\nchange(Infernal Pyreclaw:2089)\nability(Great Sting:1966) [ self.round=1 ]\nstandby [ self.round=5 ]\nstandby [ self.round=6 ]\nability(Great Sting:1966) [ self.round=7 ]\nability(Cleave:1273)\n\nchange(Anomalus:2842)\nability(Poison Protocol:1954)\nability(Void Nova:2356)\nability(Corrosion:447)",
},
["team:24"] = {
["name"] = "Bloodknight Antari",
["code"] = "if [!enemy(#1).dead]\nuse(#3)\nuse(#1)\nendif\n\nif [!enemy(#2).dead & enemy(#1).dead]\nchange(#2) \nuse(Dive:564)\nuse(Shell Shield:310) [!self(#2).aura(Shell Shield:309).exists]\nuse(Absorb:449)\nendif\n\nif [enemy(#3).active]\nchange(#3) [self(#2).active & enemy(#3).hp>1347]\nchange(#1) [self(#3).active]\nuse(#3) [self(#1).active]\nuse(#2) [self(#1).active]\nuse(#1) [self(#1).active]\nchange(#2) [self(#1).dead]\nuse(Dive:564)\nuse(Shell Shield:310) [!self(#2).aura(Shell Shield:309).exists]\nuse(Absorb:449)\nendif",
},
["team:22"] = {
["name"] = "Jeremy Feasel",
["code"] = "use(Flash Freeze:1955) [enemy(1066).active]\nuse(Deep Freeze:481) [enemy(1066).active]\nuse(Bite:110)\nuse(Deep Burn:1407)\nuse(Curse of Doom:218) [enemy(1067).active]\nuse(Scorched Earth:172) [round~1]\nuse(Shadowflame:393)\nstandby\nchange(next)",
},
["team:25"] = {
["name"] = "Morulu The Elder",
["code"] = "ability(Dodge:312) [round=3]\nability(Ravage:802) [round=4]\nability(Dodge:312) [enemy(#3).active & enemy.round=1]\nability(Sandstorm:453)\nability(#1)\nchange(next)",
},
["team:8"] = {
["name"] = "Shademaster Kiryn",
["code"] = "change(#1) [self(#2).dead]\nchange(#2) [self(#3).active]\nchange(#3) [enemy(Summer:1286).active & !self(#3).played]\nuse(Decoy:334)\nuse(Sons of the Flame:330) [self(#2).dead]\nuse(Magma Trap:811) [enemy(Nairn:1288).active]\nuse(Sons of the Flame:330) [enemy.round=2 & enemy(Stormoen:1287).active]\nuse(Magma Wave:319)\nstandby [enemy.aura(Dodge:311).exists]\nstandby [enemy.ability(Dodge:311).usable]\nuse(Bombing Run:647) [enemy(Summer:1286).active]\nuse(Missile:777)\nchange(next)",
},
["team:26"] = {
["name"] = "Major Malfunction",
["code"] = "use(Thunderbolt:779) [round=1]\nuse(Explode:282)\nuse(Call Blizzard:206)\nuse(#1)\nchange(next)\n\n-- This script was generated with wow-petsim.com",
},
["team:14"] = {
["name"] = "Lorewalker Cho",
["code"] = "change(#2) [ self(#1).dead ]\nuse(Life Exchange:277) [ enemy(#2).active ]\nuse(Moonfire:595)\nuse(Breath:115) [ enemy(#2).active ]\nuse(Decoy:334)\nuse(#2)\nuse(#1)",
},
["team:18"] = {
["name"] = "Chen Stormstout",
["code"] = "change(next) [ enemy(#2).active & !self(#3).played ]\nability(Decoy:334)\nability(Haywire:916)\nability(Dodge:312) [ enemy(#2).active ]\nability(Dodge:312) [ enemy.aura(Barrel Ready:353).exists ]\nability(Ravage:802) [ enemy(#2).active & enemy.hp<927 ]\nability(Ravage:802) [ enemy(#3).hp<619 ]\nability(#1)\nchange(#1)",
},
["team:28"] = {
["name"] = "Enbi'see, Mal, and Bones",
["code"] = "standby [round=1]\nstandby [enemy.aura(Undead:242).exists]\ntest(KILL IT WITH YOUR RANDOM PET) [self(#3).active]\nchange(#2) [round=2]\nuse(Surge of Power:593) [enemy(#3).active]\nuse(Arcane Explosion:299)\nchange(#3)",
},
["team:37"] = {
["name"] = "Ziriak",
["code"] = "change(#2) [round=3]\nchange(River Calf:1453) [enemy.aura(Undead:242).exists]\nuse(Poison Protocol:1954) [!enemy.aura(Poisoned:379).exists]\nuse(Void Nova:2356)\nuse(Headbutt:376)\nuse(#1)\nchange(next)\n\n-- This script was generated with wow-petsim.com",
},
["team:9"] = {
["name"] = "Chi-Chi, Hatchling of Chi-Ji",
["code"] = "ability(Immolation:409) [!self.aura(Immolation:408).exists]\nability(Wild Magic:592) [!enemy.aura(Wild Magic:591).exists]\nability(Acidic Goo:369) [self.round=1]\nability(Dive:564) [self.round=4]\nchange(#2)\nability(#1)",
},
["team:38"] = {
["name"] = "The Thing from the Swamp",
["code"] = "use(Blistering Cold:786)\nuse(Chop:943) [!enemy.aura(Bleeding:491).exists]\nuse(BONESTORM!!:1762)\nuse(Chop:943)\nuse(Black Claw:919) [!enemy.aura(Black Claw:918).exists]\nuse(Flock:581)\nstandby\nchange(next)",
},
["team:11"] = {
["name"] = "Xu-Fu, Cub of Xuen",
["code"] = "use(116) [ round=1 ]\nuse(282)\nuse(518)\nchange(#2)",
},
["team:35"] = {
["name"] = "Approach the Croach",
["code"] = "use(Black Claw:919) [enemy.round=1]\nuse(Flock:581)\nuse(Hunting Party:921)\nuse(Leap:364)\nuse(Bite:110)\nchange(next)",
},
["team:33"] = {
["name"] = "Christoph VonFeasel",
["code"] = "change(#1) [self(#2).active]\nchange(#3) [round=3]\nuse(Sweep:457) [round=1]\nuse(Wind-Up:459) [round=2]\nuse(Wind-Up:459) [self.round~1,3 & self(#3).active]\nuse(Supercharge:208) [self.round=2]\nuse(Toxic Smoke:640)\nuse(Batter:455) [enemy.aura(Bubble:933).exists]\nuse(Sweep:457) [!enemy(#2).dead & enemy(#1).active]\nuse(Wind-Up:459) [enemy(#2).active]\nuse(Batter:455)\nchange(#2)",
},
["team:20"] = {
["name"] = "Robot Rumble",
["code"] = "use(Blistering Cold:786)\nuse(Chop:943) [!enemy.aura(Bleeding:491).exists]\nuse(BONESTORM!!:1762)\nuse(Chop:943)\nuse(Black Claw:919) [!enemy.aura(Black Claw:918).exists]\nuse(Flock:581)\nstandby\nchange(next)",
},
["team:1"] = {
["name"] = "Training With Durian",
["code"] = "if [enemy(#1).active]\nability(#1) [ enemy.round =1 ]\nability(#2) [ enemy.round =2 ]\nability(#3) [ enemy.round =3 ]\nability(#1)\nendif\nif [enemy(#2).active]\nability(#1)\nendif\nif [enemy(#3).active]\nchange(#2) [enemy.round =1 ]\nchange(#3) [enemy.round =2 ]\nability(#2) [ enemy.round =3 ]\nability(#3) [ enemy.round =4 ]\nendif",
},
["team:12"] = {
["name"] = "Yu'la, Broodling of Yu'lon",
["code"] = "use(460)\nuse(282)\nuse(#1) [ self(#3).dead ]\nchange(next)",
},
["team:30"] = {
["name"] = "Loyal Crewmates",
["code"] = "ability(Arkaner Sturm:589) [!weather(Arkane Winde:590).exists]\nability(Abheben:170)\nability(#2)\nability(#1)\nchange(next)",
},
["team:27"] = {
["name"] = "Spores, Dusty, and Salad",
["code"] = "quit [ self(#3).dead ]\nchange(next) [ self(#1).dead & !self(#3).played ]\nuse(Arcane Explosion:299) [ !enemy(#3).active ]\nuse(Arcane Explosion:299) [ enemy(#3).hpp>50 ]\nuse(Arcane Storm:589)\nuse(Mana Surge:489)\nuse(Frost Breath:782)\nstandby",
},
["team:19"] = {
["name"] = "Wrathion",
["code"] = "change(next) [self.dead]\nuse(Dodge:312) [self.aura(Ice Tomb:623).duration = 1]\nuse(Stampede:163) [enemy(Cindy:1299).active & enemy.round = 4]\nuse(Stampede:163) [enemy(Alex:1301).active & !self.aura(Ice Tomb:623).exists]\nstandby [enemy.aura(Undead:242).exists]\nuse(Scratch:119)\nuse(Crush:406) [enemy(Alex:1301).aura(Shattered Defenses:542).exists]\nuse(Stoneskin:436) [!self.aura(Stoneskin:435).exists]\nuse(Deflection:490) [self.aura(Elementium Bolt:605).duration = 1]\nuse(Crush:406)\nuse(Dead Man's Party:1093)\nuse(Macabre Maraca:1094)",
},
["team:2"] = {
["name"] = "Tarr the Terrible",
["code"] = "change(#1) [self(#2).played]\nchange(#2) [round=4]\nuse(Corrosion:447) [round=1]\nuse(Poison Protocol:1954)\nuse(Void Nova:2356)\nuse(Corrosion:447)\nuse(Raise Ally:2298)\nuse(Dead Man's Party:1093)\nchange(#3)",
},
["team:23"] = {
["name"] = "The Beakinator",
["code"] = "standby [round=1]\nchange(#2) [ self(#1).active ]\nchange(#3) [ self(#2).active ]\nuse(Arcane Storm:589)\nuse(Mana Surge:489)",
},
["team:29"] = {
["name"] = "Stitches Jr.",
["code"] = "standby [round~3,7]\nability(Supercharge:208) [round=5]\nability(Wind-Up:459)\nchange(#2)",
},
["team:21"] = {
["name"] = "One Hungry Worm",
["code"] = "use(Blistering Cold:786)\nuse(Chop:943) [!enemy.aura(Bleeding:491).exists]\nuse(BONESTORM!!:1762)\nuse(Chop:943)\nuse(Black Claw:919) [!enemy.aura(Black Claw:918).exists]\nuse(Flock:581)\nstandby\nchange(next)",
},
["team:32"] = {
["name"] = "Jeremy Feasel (2)",
["code"] = "if [enemy(#1).active]\nability(Thunderbolt:779)\nability(Decoy:334)\nability(Breath:115)\nendif\nif [enemy(#2).active]\nstandby [self.aura(Stunned:927).exists]\nability(Thunderbolt:779)\nability(Decoy:334)\nability(Breath:115)\nability(Alpha Strike:504)\nchange(#3) [self(#1).dead]\nendif\nif [enemy(#3).active]\nchange(#2) [enemy.round=1]\nchange(#3)\nability(Haywire:916)\nability(Alpha Strike:504)\nendif",
},
["team:15"] = {
["name"] = "Dr. Ion Goldbloom",
["code"] = "use(Howl:362) [enemy.aura(Flying:341).exists]\nuse(Surge of Power:593) [enemy.aura(Howl:1725).exists]\nuse(Arcane Explosion:299)\nuse(Conflagrate:179) [enemy(#3).active]\nuse(Flame Breath:501) [!enemy.aura(Flame Breath:500).exists]\nuse(Scorched Earth:172)\nuse(Ion Cannon:209) [enemy(#3).hp<1142]\nuse(#1)\nchange(next)",
},
["team:34"] = {
["name"] = "Deebs, Tyri and Puzzle",
["code"] = "ability(Sweep:457) [ round=1 ]\nchange(next) [ !self(#3).active & !self(#3).played ]\nability(Wind-Up:459) [ enemy(#3).active ]\nability(#1)\nability(#2)\nability(#3)\nchange(#1)",
},
["team:36"] = {
["name"] = "The Power of Friendship",
["code"] = "use(Toxic Smoke:640) [round>3]\nuse(Supercharge:208) [round=2]\nuse(Wind-Up:459)\nuse(Black Claw:919) [self.round=1]\nuse(Flock:581)\nuse(Arcane Storm:589) [self.round=1]\nuse(Surge of Power:593) [enemy(#3).active & self.aura(Dragonkin:245).exists & enemy.hp<1099]\nuse(Breath:115)\nchange(next)",
},
},
},
},
["profileKeys"] = {
["Thingreyline - Tichondrius"] = "Default",
["Crillessana - Mal'Ganis"] = "Default",
["Gehyo - Tichondrius"] = "Default",
["Heilsatan - Tichondrius"] = "Default",
["Praisesun - Tichondrius"] = "Default",
["Smaugchamp - Tichondrius"] = "Default",
["Tampacks - Mal'Ganis"] = "Default",
["Auteist - Mal'Ganis"] = "Default",
["Ofpuss - Mal'Ganis"] = "Default",
["Hellavator - Mal'Ganis"] = "Default",
["Smaugchamp - Mal'Ganis"] = "Default",
["Choppiez - Mal'Ganis"] = "Default",
["Choppiez - Tichondrius"] = "Default",
["Thickshape - Mal'Ganis"] = "Default",
["Neonvoid - Tichondrius"] = "Default",
["Corsic - Mal'Ganis"] = "Default",
["Mäñýfäçëð - Mal'Ganis"] = "Default",
["Auteist - Tichondrius"] = "Default",
["Hellavator - Tichondrius"] = "Default",
["Ofpusstwo - Tichondrius"] = "Default",
["Gehyo - Mal'Ganis"] = "Default",
["Cullnvoid - Tichondrius"] = "Default",
["Stormclout - Tichondrius"] = "Default",
["Reedingo - Mal'Ganis"] = "Default",
["Stormclout - Mal'Ganis"] = "Default",
["Rakeist - Mal'Ganis"] = "Default",
["Starstypeshi - Tichondrius"] = "Default",
["Neonvoid - Mal'Ganis"] = "Default",
["Ofpuss - Tichondrius"] = "Default",
["Praisesun - Mal'Ganis"] = "Default",
["Mäñýfäçëð - Tichondrius"] = "Default",
["Clevagirl - Mal'Ganis"] = "Default",
},
["profiles"] = {
["Default"] = {
["settings"] = {
["editorFontFace"] = "Interface\\Addons\\SharedMedia_MyMedia\\font\\1.ttf",
["hideMinimap"] = true,
},
["pluginOrders"] = {
"Rematch",
"Base",
"FirstEnemy",
"AllInOne",
},
["minimap"] = {
["hide"] = true,
},
},
},
}
