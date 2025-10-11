-- By D4KiR
local _, SpecBisTooltip = ...
local s = {}
if SpecBisTooltip:GetWoWBuild() == "CLASSIC" then
    function SpecBisTooltip:GetTranslationMap()
        return s
    end
end

-- SOURCE FROM: 01.04.2025
if SpecBisTooltip:GetWoWBuild() == "CLASSIC" then
    function SpecBisTooltip:TranslationenUS()
        s["npc;drop=11583"] = {"Nefarian", "Blackwing Lair"}
        s["npc;drop=11502"] = {"Ragnaros", "Molten Core"}
        s["npc;drop=12435"] = {"Razorgore the Untamed", "Blackwing Lair"}
        s["npc;drop=14834"] = {"Hakkar", "Zul'Gurub"}
        s["spell;created=24091"] = {"Bloodvine Vest", ""}
        s["npc;drop=12017"] = {"Broodlord Lashlayer", "Blackwing Lair"}
        s["npc;drop=11380"] = {"Jin'do the Hexxer", "Zul'Gurub"}
        s["npc;drop=11983"] = {"Firemaw", "Blackwing Lair"}
        s["spell;created=24092"] = {"Bloodvine Leggings", ""}
        s["spell;created=24093"] = {"Bloodvine Boots", ""}
        s["npc;drop=12098"] = {"Sulfuron Harbinger", "Molten Core"}
        s["npc;drop=14601"] = {"Ebonroc", "Blackwing Lair"}
        s["quest;reward=8183"] = {"The Heart of Hakkar", ""}
        s["npc;sold=13217"] = {"Thanthaldis Snowgleam <Stormpike Supply Officer>", "Alterac Mountains"}
        s["npc;drop=10363"] = {"General Drakkisath", "Blackrock Spire"}
        s["npc;drop=10435"] = {"Magistrate Barthilas", "Stratholme"}
        s["spell;created=12622"] = {"Green Lens", ""}
        s["spell;created=12092"] = {"Dreamweave Circlet", ""}
        s["npc;drop=11261"] = {"Doctor Theolen Krastinov <The Butcher>", "Scholomance"}
        s["npc;sold=12777"] = {"Captain Dirgehammer <Armor Quartermaster>", "Alterac Valley"}
        s["npc;sold=12792"] = {"Lady Palanseer <Armor Quartermaster>", "Alterac Valley"}
        s["npc;drop=9018"] = {"High Interrogator Gerstahn <Twilight's Hammer Interrogator>", "Blackrock Depths"}
        s["npc;drop=14353"] = {"Mizzle the Crafty", "Dire Maul"}
        s["npc;drop=10811"] = {"Archivist Galford", "Stratholme"}
        s["npc;drop=15727"] = {"C'Thun", "Ahn'Qiraj"}
        s["npc;drop=9319"] = {"Houndmaster Grebmar", "Blackrock Depths"}
        s["npc;drop=11487"] = {"Magister Kalendris", "Dire Maul"}
        s["npc;sold=13218"] = {"Grunnda Wolfheart <Frostwolf Supply Officer>", "Alterac Valley"}
        s["quest;reward=7861"] = {"Wanted: Vile Priestess Hexx and Her Minions", ""}
        s["npc;drop=12118"] = {"Lucifron", "Molten Core"}
        s["npc;drop=11496"] = {"Immol'thar", "Dire Maul"}
        s["npc;drop=11486"] = {"Prince Tortheldrin", "Dire Maul"}
        s["npc;drop=15815"] = {"Qiraji Captain Ka'ark", "Thousand Needles"}
        s["npc;drop=10508"] = {"Ras Frostwhisper", "Scholomance"}
        s["npc;sold=14753"] = {"Illiyana Moonblaze <Silverwing Supply Officer>", "Ashenvale"}
        s["quest;reward=8574"] = {"Stalwart's Battlegear", ""}
        s["npc;drop=9017"] = {"Lord Incendius", "Blackrock Depths"}
        s["npc;drop=10516"] = {"The Unforgiven", "Stratholme"}
        s["npc;drop=14326"] = {"Guard Mol'dar", "Dire Maul"}
        s["npc;drop=11662"] = {"Flamewaker Priest", "Molten Core"}
        s["npc;drop=12397"] = {"Lord Kazzak", "Blasted Lands"}
        s["npc;drop=10584"] = {"Urok Doomhowl", "Blackrock Spire"}
        s["npc;drop=14020"] = {"Chromaggus", "Blackwing Lair"}
        s["npc;drop=9736"] = {"Quartermaster Zigris <Bloodaxe Legion>", "Blackrock Spire"}
        s["quest;reward=8464"] = {"Winterfall Activity", ""}
        s["npc;drop=5719"] = {"Morphaz", "The Temple of Atal'Hakkar"}
        s["spell;created=12067"] = {"Dreamweave Gloves", ""}
        s["npc;drop=12056"] = {"Baron Geddon", "Molten Core"}
        s["npc;drop=9030"] = {"Ok'thor the Breaker", "Blackrock Depths"}
        s["npc;sold=13219"] = {"Jekyll Flandring <Frostwolf Supply Officer>", "Alterac Mountains"}
        s["spell;created=3864"] = {"Star Belt", ""}
        s["npc;drop=10437"] = {"Nerub'enkan", "Stratholme"}
        s["npc;drop=12119"] = {"Flamewaker Protector", "Molten Core"}
        s["npc;drop=9196"] = {"Highlord Omokk", "Blackrock Spire"}
        s["npc;drop=6109"] = {"Azuregos", "Azshara"}
        s["spell;created=23667"] = {"Flarecore Leggings", ""}
        s["npc;drop=7267"] = {"Chief Ukorz Sandscalp", "Zul'Farrak"}
        s["npc;drop=8983"] = {"Golem Lord Argelmach", "Blackrock Depths"}
        s["npc;drop=15276"] = {"Emperor Vek'lor", "Ahn'Qiraj"}
        s["npc;drop=13280"] = {"Hydrospawn", "Dire Maul"}
        s["npc;drop=10429"] = {"Warchief Rend Blackhand", "Blackrock Spire"}
        s["npc;drop=10997"] = {"Cannon Master Willey", "Stratholme"}
        s["npc;drop=10812"] = {"Grand Crusader Dathrohan", "Stratholme"}
        s["npc;drop=15275"] = {"Emperor Vek'nilash", "Ahn'Qiraj"}
        s["npc;drop=15742"] = {"Colossus of Ashi", "Silithus"}
        s["npc;drop=16042"] = {"Lord Valthalak", "Blackrock Spire"}
        s["quest;reward=8802"] = {"The Savior of Kalimdor", ""}
        s["spell;created=25925"] = {"Signet Ring of the Bronze Dragonflight CASTER R5 DND", ""}
        s["quest;reward=4363"] = {"The Princess's Surprise", ""}
        s["quest;reward=4004"] = {"The Princess Saved?", ""}
        s["quest;reward=7491"] = {"For All To See", ""}
        s["npc;sold=14754"] = {"Kelm Hargunth <Warsong Supply Officer>", "The Barrens"}
        s["npc;drop=11982"] = {"Magmadar", "Molten Core"}
        s["npc;drop=10509"] = {"Jed Runewatcher <Blackhand Legion>", "Blackrock Spire"}
        s["quest;reward=5102"] = {"General Drakkisath's Demise", ""}
        s["npc;drop=9156"] = {"Ambassador Flamelash", "Blackrock Depths"}
        s["npc;sold=12782"] = {"Captain O'Neal <Weapons Quartermaster>", "Alterac Valley"}
        s["npc;sold=14581"] = {"Sergeant Thunderhorn <Weapons Quartermaster>", "Alterac Valley"}
        s["npc;sold=15126"] = {"Rutherford Twing <Defilers Supply Officer>", "Arathi Highlands"}
        s["npc;sold=15127"] = {"Samuel Hawke <League of Arathor Supply Officer>", "Arathi Highlands"}
        s["npc;drop=12057"] = {"Garr", "Molten Core"}
        s["npc;drop=12259"] = {"Gehennas", "Molten Core"}
        s["npc;drop=1853"] = {"Darkmaster Gandling", "Scholomance"}
        s["npc;drop=10899"] = {"Goraluk Anvilcrack <Blackhand Legion Armorsmith>", "Blackrock Spire"}
        s["npc;drop=11492"] = {"Alzzin the Wildshaper", "Dire Maul"}
        s["quest;reward=8790"] = {"Imperial Qiraji Regalia", ""}
        s["npc;drop=11988"] = {"Golemagg the Incinerator", "Molten Core"}
        s["npc;drop=2585"] = {"Stromgarde Vindicator", "Arathi Highlands"}
        s["quest;reward=82112"] = {"A Better Ingredient", ""}
        s["npc;drop=7271"] = {"Witch Doctor Zum'rah", "Zul'Farrak"}
        s["npc;drop=8440"] = {"Shade of Hakkar", "The Temple of Atal'Hakkar"}
        s["npc;drop=5721"] = {"Dreamscythe", "The Temple of Atal'Hakkar"}
        s["object;contained=181083"] = {"Sothos and Jarien's Heirlooms", "Stratholme"}
        s["quest;reward=7784"] = {"The Lord of Blackrock", ""}
        s["quest;reward=3962"] = {"It's Dangerous to Go Alone", ""}
        s["npc;drop=4543"] = {"Bloodmage Thalnos", "Scarlet Monastery"}
        s["npc;sold=227819"] = {"Duke Hydraxis", ""}
        s["npc;drop=228435"] = {"Golemagg the Incinerator", "Molten Core"}
        s["npc;sold=230319"] = {"Deliana", "Ironforge"}
        s["npc;drop=228438"] = {"Ragnaros", "Molten Core"}
        s["npc;drop=228432"] = {"Garr", "Molten Core"}
        s["npc;sold=227853"] = {"Pix Xizzix <Undermine Trader>", "Stranglethorn Vale"}
        s["spell;created=446192"] = {"Membrane of Dark Neurosis", ""}
        s["npc;drop=15205"] = {"Baron Kazum <Abyssal High Council>", "Silithus"}
        s["spell;created=461653"] = {"Brilliant Chromatic Cloak", ""}
        s["item:contained=20601"] = {"Sack of Spoils", ""}
        s["npc;drop=228434"] = {"Shazzrah", "Molten Core"}
        s["npc;sold=222413"] = {"Zalgo the Explorer <Purveyor of Lost Goods>", "Stranglethorn Vale"}
        s["quest;reward=84147"] = {"An Earnest Proposition", ""}
        s["npc;drop=218819"] = {"Festering Rotslime", "The Temple of Atal'Hakkar"}
        s["spell;created=429869"] = {"Void-Touched Leather Gauntlets", ""}
        s["npc;drop=220833"] = {"Dreamscythe", "The Temple of Atal'Hakkar"}
        s["npc;sold=222408"] = {"Shadowtooth Emissary", "Felwood"}
        s["spell;created=461754"] = {"Girdle of Arcane Insight", ""}
        s["npc;drop=228433"] = {"Baron Geddon", "Molten Core"}
        s["object;contained=179703"] = {"Cache of the Firelord", ""}
        s["npc;drop=228429"] = {"Lucifron", "Molten Core"}
        s["npc;drop=226923"] = {"Grimroot <The Mourning Guardian>", "Demon Fall Canyon"}
        s["npc;drop=12201"] = {"Princess Theradras", "Maraudon"}
        s["npc;drop=217280"] = {"Grubbis", "Gnomeregan"}
        s["spell;created=461647"] = {"Skyrider's Masterwork Stormhammer", ""}
        s["npc;drop=4542"] = {"High Inquisitor Fairbanks", "Scarlet Monastery"}
        s["npc;drop=204068"] = {"Lady Sarevess", "Blackfathom Deeps"}
        s["spell;created=12060"] = {"Red Mageweave Pants", ""}
        s["npc;drop=213334"] = {"Aku'mai", "Blackfathom Deeps"}
        s["spell;created=439105"] = {"Big Voodoo Mask", ""}
        s["npc;drop=6490"] = {"Azshir the Sleepless", "Scarlet Monastery"}
        s["spell;created=439093"] = {"Crimson Silk Shoulders", ""}
        s["quest;reward=82055"] = {"Darkmoon Dunes Deck", ""}
        s["quest;reward=82057"] = {"Darkmoon Plagues Deck", ""}
        s["npc;drop=221637"] = {"Gasher", "The Temple of Atal'Hakkar"}
        s["quest;reward=7940"] = {"1200 Tickets - Orb of the Darkmoon", ""}
        s["npc;drop=218721"] = {"Jammal'an the Prophet", "The Temple of Atal'Hakkar"}
        s["npc;sold=11557"] = {"Meilosh", "Felwood"}
        s["spell;created=10621"] = {"Wolfshead Helm", ""}
        s["npc;drop=9816"] = {"Pyroguard Emberseer", "Blackrock Spire"}
        s["npc;drop=12467"] = {"Death Talon Captain", "Blackwing Lair"}
        s["spell;created=23710"] = {"Molten Belt", ""}
        s["npc;drop=11981"] = {"Flamegor", "Blackwing Lair"}
        s["npc;drop=6229"] = {"Crowd Pummeler 9-60", "Gnomeregan"}
        s["npc;drop=15206"] = {"The Duke of Cynders <Abyssal Council>", "Silithus"}
        s["npc;drop=9041"] = {"Warder Stilgiss", "Blackrock Depths"}
        s["quest;reward=4261"] = {"Ancient Spirit", ""}
        s["npc;drop=10440"] = {"Baron Rivendare", "Stratholme"}
        s["npc;drop=15511"] = {"Lord Kri", "Ahn'Qiraj"}
        s["quest;reward=5068"] = {"Breastplate of Bloodthirst", ""}
        s["npc;drop=9019"] = {"Emperor Dagran Thaurissan", "Blackrock Depths"}
        s["npc;drop=15516"] = {"Battleguard Sartura", "Ahn'Qiraj"}
        s["spell;created=19084"] = {"Devilsaur Gauntlets", ""}
        s["npc;drop=11361"] = {"Zulian Tiger", "Zul'Gurub"}
        s["npc;drop=15323"] = {"Hive'Zara Sandstalker", "Ruins of Ahn'Qiraj"}
        s["spell;created=19097"] = {"Devilsaur Leggings", ""}
        s["object;contained=181366"] = {"Four Horsemen Chest", ""}
        s["npc;drop=10399"] = {"Thuzadin Acolyte", "Stratholme"}
        s["npc;drop=16097"] = {"Isalien", "Dire Maul"}
        s["npc;drop=8929"] = {"Princess Moira Bronzebeard <Princess of Ironforge>", "Blackrock Depths"}
        s["quest;reward=7981"] = {"1200 Tickets - Amulet of the Darkmoon", ""}
        s["npc;drop=15114"] = {"Gahz'ranka", "Zul'Gurub"}
        s["npc;drop=15517"] = {"Ouro", "Ahn'Qiraj"}
        s["quest;reward=7862"] = {"Job Opening: Guard Captain of Revantusk Village", ""}
        s["npc;drop=9568"] = {"Overlord Wyrmthalak", "Blackrock Spire"}
        s["quest;reward=3321"] = {"Did You Lose This?", ""}
        s["npc;sold=12805"] = {"Officer Areyn <Accessories Quartermaster>", "Stormwind City"}
        s["npc;sold=12799"] = {"Sergeant Ba'sha <Accessories Quartermaster>", "Orgrimmar"}
        s["npc;drop=12463"] = {"Death Talon Flamescale", "Blackwing Lair"}
        s["quest;reward=7877"] = {"The Treasure of the Shen'dralar", ""}
        s["npc;drop=9025"] = {"Lord Roccor", "Blackrock Depths"}
        s["npc;drop=2748"] = {"Archaedas <Ancient Stone Watcher>", "Uldaman"}
        s["npc;drop=10503"] = {"Jandice Barov", "Scholomance"}
        s["spell;created=23707"] = {"Lava Belt", ""}
        s["npc;drop=228022"] = {"The Destructor's Wraith", "Demon Fall Canyon"}
        s["npc;drop=227140"] = {"Pyranis", "Demon Fall Canyon"}
        s["spell;created=460462"] = {"Eye of Sulfuras", ""}
        s["npc;drop=227028"] = {"Hellscream's Phantom", "Demon Fall Canyon"}
        s["npc;drop=15204"] = {"High Marshal Whirlaxis <Abyssal High Council>", "Silithus"}
        s["npc;drop=218624"] = {"Atal'alarion <Guardian of the Idol>", "The Temple of Atal'Hakkar"}
        s["npc;drop=228430"] = {"Magmadar", "Molten Core"}
        s["spell;created=24123"] = {"Primal Batskin Bracers", ""}
        s["spell;created=24122"] = {"Primal Batskin Gloves", ""}
        s["npc;drop=10422"] = {"Crimson Sorcerer", "Stratholme"}
        s["quest;reward=84561"] = {"For All To See", ""}
        s["quest;reward=5944"] = {"In Dreams", ""}
        s["quest;reward=8949"] = {"Falrin's Vendetta", ""}
        s["npc;sold=12944"] = {"Lokhtos Darkbargainer <The Thorium Brotherhood>", ""}
        s["npc;drop=228436"] = {"Sulfuron Harbinger", "Molten Core"}
        s["spell;created=461712"] = {"Refined Hammer of the Titans", ""}
        s["spell;created=16988"] = {"Hammer of the Titans", ""}
        s["npc;drop=221943"] = {"Hazzas", "The Temple of Atal'Hakkar"}
        s["npc;drop=7355"] = {"Tuten'kash", "Razorfen Downs"}
        s["spell;created=461722"] = {"Devilcore Gauntlets", ""}
        s["spell;created=461724"] = {"Devilcore Leggings", ""}
        s["quest;reward=84545"] = {"A Hero's Reward", ""}
        s["npc;drop=15510"] = {"Fankriss the Unyielding", "Ahn'Qiraj"}
        s["npc;drop=15341"] = {"General Rajaxx", "Ruins of Ahn'Qiraj"}
        s["spell;created=25931"] = {"Signet Ring of the Bronze Dragonflight DPS R5 DND", ""}
        s["npc;drop=15340"] = {"Moam", "Ruins of Ahn'Qiraj"}
        s["npc;drop=10487"] = {"Risen Protector", "Scholomance"}
        s["npc;drop=5717"] = {"Mijan", "The Temple of Atal'Hakkar"}
        s["npc;drop=15263"] = {"The Prophet Skeram", "Ahn'Qiraj"}
        s["npc;drop=16449"] = {"Spirit of Naxxramas", "Naxxramas"}
        s["npc;drop=12460"] = {"Death Talon Wyrmguard", "Blackwing Lair"}
        s["npc;drop=10430"] = {"The Beast", "Blackrock Spire"}
        s["npc;drop=10500"] = {"Spectral Teacher", "Scholomance"}
        s["npc;drop=221407"] = {"Dreamshadow Imp", "Feralas"}
        s["npc;drop=10220"] = {"Halycon", "Blackrock Spire"}
        s["npc;drop=15990"] = {"Kel'Thuzad", "Naxxramas"}
        s["npc;drop=12264"] = {"Shazzrah", "Molten Core"}
        s["npc;drop=15952"] = {"Maexxna", "Naxxramas"}
        s["quest;reward=9120"] = {"The Fall of Kel'Thuzad", ""}
        s["spell;created=15596"] = {"Smoking Heart of the Mountain", ""}
        s["quest;reward=7067"] = {"The Pariah's Instructions", ""}
        s["quest;reward=8573"] = {"Champion's Battlegear", ""}
        s["npc;drop=9547"] = {"Guzzling Patron", "Blackrock Depths"}
        s["spell;created=461690"] = {"Mastercrafted Shifting Cloak", ""}
        s["npc;drop=230302"] = {"Lord Kazzak", "The Tainted Scar"}
        s["spell;created=435904"] = {"Glowing Gneuro-Linked Cowl", ""}
        s["spell;created=23703"] = {"Might of the Timbermaw", ""}
        s["spell;created=19080"] = {"Warbear Woolies", ""}
        s["npc;sold=10857"] = {"Argent Quartermaster Lightspark <The Argent Dawn>", "Western Plaguelands"}
        s["spell;created=23705"] = {"Dawn Treaders", ""}
        s["npc;sold=13278"] = {"Duke Hydraxis", "Azshara"}
        s["npc;sold=218115"] = {"Mai'zin <Gurubashi Bloodchanger>", "Stranglethorn Vale"}
        s["npc;drop=204921"] = {"Gelihast", "Blackfathom Deeps"}
        s["quest;reward=80324"] = {"The Mad King", ""}
        s["npc;drop=202699"] = {"Baron Aquanis", "Blackfathom Deeps"}
        s["npc;drop=8567"] = {"Glutton", "Razorfen Downs"}
        s["npc;drop=220007"] = {"Viscous Fallout", "Gnomeregan"}
        s["npc;sold=217689"] = {"Ziri 'The Wrench' Littlesprocket <Gearhead>", ""}
        s["npc;drop=201722"] = {"Ghamoo-ra", "Blackfathom Deeps"}
        s["npc;drop=220072"] = {"Electrocutioner 6000", "Gnomeregan"}
        s["spell;created=429354"] = {"Void-Touched Leather Gloves", ""}
        s["quest;reward=824"] = {"Je'neu of the Earthen Ring", ""}
        s["quest;reward=80132"] = {"Rig Wars", ""}
        s["npc;drop=3669"] = {"Lord Cobrahn <Fanglord>", "Wailing Caverns"}
        s["npc;drop=215728"] = {"Crowd Pummeler 9-60", "Gnomeregan"}
        s["npc;drop=218537"] = {"Mekgineer Thermaplugg", "Gnomeregan"}
        s["npc;drop=4295"] = {"Scarlet Myrmidon", "Scarlet Monastery"}
        s["quest;reward=7541"] = {"Service to the Horde", ""}
        s["npc;drop=6489"] = {"Ironspine", "Scarlet Monastery"}
        s["quest;reward=78916"] = {"The Heart of the Void", ""}
        s["npc;drop=207356"] = {"Lorgus Jett", "Blackfathom Deeps"}
        s["npc;drop=7584"] = {"Wandering Forest Walker", "Feralas"}
        s["npc;drop=14491"] = {"Kurmokk", "Stranglethorn Vale"}
        s["npc;drop=4389"] = {"Murk Thresher", "Dustwallow Marsh"}
        s["npc;drop=2433"] = {"Helcular's Remains", "Hillsbrad Foothills"}
        s["spell;created=6705"] = {"Murloc Scale Bracers", ""}
        s["spell;created=3779"] = {"Barbaric Belt", ""}
        s["npc;drop=4845"] = {"Shadowforge Ruffian", "Badlands"}
        s["npc;drop=218242"] = {"STX-04/BD", "Gnomeregan"}
        s["quest;reward=2767"] = {"Rescue OOX-22/FE!", ""}
        s["quest;reward=793"] = {"Broken Alliances", ""}
        s["spell;created=435960"] = {"Hyperconductive Goldwap", ""}
        s["npc;drop=16118"] = {"Kormok", "Scholomance"}
        s["npc;drop=9033"] = {"General Angerforge", "Blackrock Depths"}
        s["npc;drop=12018"] = {"Majordomo Executus", "Molten Core"}
        s["npc;drop=15509"] = {"Princess Huhuran", "Ahn'Qiraj"}
        s["quest;reward=7506"] = {"The Emerald Dream...", ""}
        s["npc;drop=15299"] = {"Viscidus", "Ahn'Qiraj"}
        s["npc;drop=15543"] = {"Princess Yauj", "Ahn'Qiraj"}
        s["spell;created=22927"] = {"Hide of the Wild", ""}
        s["spell;created=28942"] = {"Summon Haruspex's Bracers DND", ""}
        s["npc;drop=11501"] = {"King Gordok", "Dire Maul"}
        s["npc;drop=10268"] = {"Gizrul the Slavener", "Blackrock Spire"}
        s["spell;created=22759"] = {"Flarecore Wraps", ""}
        s["npc;drop=15339"] = {"Ossirian the Unscarred", "Ruins of Ahn'Qiraj"}
        s["npc;drop=5712"] = {"Zolo", "The Temple of Atal'Hakkar"}
        s["spell;created=23709"] = {"Corehound Belt", ""}
        s["npc;drop=13020"] = {"Vaelastrasz the Corrupt", "Blackwing Lair"}
        s["npc;drop=11488"] = {"Illyanna Ravenoak", "Dire Maul"}
        s["npc;drop=9056"] = {"Fineous Darkvire <Chief Architect>", "Blackrock Depths"}
        s["npc;drop=10504"] = {"Lord Alexei Barov", "Scholomance"}
        s["npc;drop=14325"] = {"Captain Kromcrush", "Dire Maul"}
        s["npc;drop=10809"] = {"Stonespine", "Stratholme"}
        s["quest;reward=8791"] = {"The Fall of Ossirian", ""}
        s["npc;drop=10439"] = {"Ramstein the Gorger", "Stratholme"}
        s["quest;reward=7907"] = {"Darkmoon Beast Deck", ""}
        s["spell;created=24279"] = {"Punctured Voodoo Doll DRU DND", ""}
        s["object;contained=169243"] = {"Chest of The Seven", "Blackrock Depths"}
        s["npc;drop=14515"] = {"High Priestess Arlokk", "Zul'Gurub"}
        s["npc;drop=16080"] = {"Mor Grayhoof", "Blackrock Spire"}
        s["spell;created=461750"] = {"Incandescent Mooncloth Circlet", ""}
        s["spell;created=23665"] = {"Argent Shoulders", ""}
        s["spell;created=446189"] = {"Shoulderpads of Obsession", ""}
        s["spell;created=19061"] = {"Living Shoulders", ""}
        s["spell;created=446194"] = {"Mantle of Insanity", ""}
        s["npc;drop=221394"] = {"Avatar of Hakkar", "The Temple of Atal'Hakkar"}
        s["npc;drop=228431"] = {"Gehennas", "Molten Core"}
        s["npc;drop=9236"] = {"Shadow Hunter Vosh'gajin", "Blackrock Spire"}
        s["spell;created=19435"] = {"Mooncloth Boots", ""}
        s["npc;drop=218571"] = {"Shade of Eranikus", "The Temple of Atal'Hakkar"}
        s["spell;created=22207"] = {"Summon Drakefire Amulet DND", ""}
        s["npc;drop=10506"] = {"Kirtonos the Herald", "Scholomance"}
        s["quest;reward=80325"] = {"The Mad King", ""}
        s["quest;reward=82081"] = {"A Broken Ritual", ""}
        s["quest;reward=82058"] = {"Darkmoon Wilds Deck", ""}
        s["npc;drop=226922"] = {"Zilbagob", "Demon Fall Canyon"}
        s["npc;drop=9938"] = {"Magmus", "Blackrock Depths"}
        s["npc;drop=3977"] = {"High Inquisitor Whitemane", "Scarlet Monastery"}
        s["npc;drop=14324"] = {"Cho'Rush the Observer", "Dire Maul"}
        s["npc;drop=11661"] = {"Flamewaker", "Molten Core"}
        s["npc;drop=11673"] = {"Ancient Core Hound", "Molten Core"}
        s["quest;reward=9008"] = {"Saving the Best for Last", ""}
        s["quest;reward=4024"] = {"A Taste of Flame", ""}
        s["npc;drop=13276"] = {"Wildspawn Imp", "Dire Maul"}
        s["npc;drop=9027"] = {"Gorosh the Dervish", "Blackrock Depths"}
        s["npc;drop=10264"] = {"Solakar Flamewreath", "Blackrock Spire"}
        s["quest;reward=8906"] = {"An Earnest Proposition", ""}
        s["quest;reward=8938"] = {"Just Compensation", ""}
        s["npc;drop=10393"] = {"Skul", "Stratholme"}
        s["npc;drop=11489"] = {"Tendris Warpwood", "Dire Maul"}
        s["npc;drop=9596"] = {"Bannok Grimaxe <Firebrand Legion Champion>", "Blackrock Spire"}
        s["quest;reward=8952"] = {"Anthion's Parting Words", ""}
        s["spell;created=22922"] = {"Mongoose Boots", ""}
        s["quest;reward=5125"] = {"Aurius' Reckoning", ""}
        s["quest;reward=7503"] = {"The Greatest Race of Hunters", ""}
        s["quest;reward=82108"] = {"The Green Drake", ""}
        s["npc;drop=10438"] = {"Maleki the Pallid", "Stratholme"}
        s["spell;created=24872"] = {"Create Hunter Epic Staff DND", ""}
        s["npc;drop=221391"] = {"Slirena <Harpy Queen>", "Feralas"}
        s["spell;created=24873"] = {"Create Hunter Epic Bow DND", ""}
        s["npc;drop=15740"] = {"Colossus of Zora", "Silithus"}
        s["spell;created=462623"] = {"Forming Rhok'delar", ""}
        s["quest;reward=82104"] = {"Jammal'an the Prophet", ""}
        s["npc;drop=8908"] = {"Molten War Golem", "Blackrock Depths"}
        s["quest;reward=84148"] = {"An Earnest Proposition", ""}
        s["spell;created=446237"] = {"Void-Powered Slayer's Vambraces", ""}
        s["npc;drop=9029"] = {"Eviscerator", "Blackrock Depths"}
        s["quest;reward=7029"] = {"Vyletongue Corruption", ""}
        s["object;contained=179564"] = {"Gordok Tribute", ""}
        s["npc;drop=9445"] = {"Dark Guard", "Blackrock Depths"}
        s["spell;created=23639"] = {"Blackfury", ""}
        s["spell;created=462630"] = {"Create Hunter Epic Staff DND", ""}
        s["spell;created=461675"] = {"Refined Arcanite Reaper", ""}
        s["npc;drop=222573"] = {"Delirious Ancient", "Zul'Farrak"}
        s["quest;reward=8272"] = {"Hero of the Frostwolf", ""}
        s["quest;reward=3636"] = {"Bring the Light", ""}
        s["quest;reward=1364"] = {"Mazen's Behest", ""}
        s["npc;drop=7603"] = {"Leprous Assistant", "Gnomeregan"}
        s["npc;drop=2716"] = {"Dustbelcher Wyrmhunter", "Badlands"}
        s["quest;reward=628"] = {"Excelsior", ""}
        s["npc;drop=6910"] = {"Revelosh", "Uldaman"}
        s["quest;reward=7068"] = {"Shadowshard Fragments", ""}
        s["quest;reward=2822"] = {"The Mark of Quality", ""}
        s["npc;drop=5860"] = {"Twilight Dark Shaman", "Searing Gorge"}
        s["npc;drop=13601"] = {"Tinkerer Gizlock", "Maraudon"}
        s["quest;reward=1048"] = {"Into The Scarlet Monastery", ""}
        s["spell;created=435953"] = {"Rad-Resistant Scale Hood", ""}
        s["spell;created=18457"] = {"Robe of the Archmage", ""}
        s["quest;reward=8632"] = {"Enigma Circlet", ""}
        s["quest;reward=8625"] = {"Enigma Shoulderpads", ""}
        s["quest;reward=8633"] = {"Enigma Robes", ""}
        s["quest;reward=8634"] = {"Enigma Boots", ""}
        s["npc;drop=15236"] = {"Vekniss Wasp", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"Saving the Best for Last", ""}
        s["quest;reward=84157"] = {"An Earnest Proposition", ""}
        s["quest;reward=84549"] = {"The Arcanist's Cookbook", ""}
        s["npc;drop=11480"] = {"Arcane Aberration", "Dire Maul"}
        s["quest;reward=84181"] = {"Anthion's Parting Words", ""}
        s["npc;drop=10198"] = {"Kashoch the Reaver", "Winterspring"}
        s["quest;reward=84165"] = {"Just Compensation", ""}
        s["spell;created=22868"] = {"Inferno Gloves", ""}
        s["npc;drop=14684"] = {"Balzaphon", "Stratholme"}
        s["quest;reward=82095"] = {"The God Hakkar", ""}
        s["quest;reward=8932"] = {"Just Compensation", ""}
        s["npc;drop=9024"] = {"Pyromancer Loregrain", "Blackrock Depths"}
        s["quest;reward=617"] = {"Akiris by the Bundle", ""}
        s["npc;drop=6146"] = {"Cliff Breaker", "Azshara"}
        s["spell;created=446236"] = {"Void-Powered Invoker's Vambraces", ""}
        s["quest;reward=3907"] = {"Disharmony of Fire", ""}
        s["spell;created=23663"] = {"Mantle of the Timbermaw", ""}
        s["npc;drop=4288"] = {"Scarlet Beastmaster", "Scarlet Monastery"}
        s["npc;drop=6487"] = {"Arcanist Doan", "Scarlet Monastery"}
        s["quest;reward=8366"] = {"Southsea Shakedown", ""}
        s["npc;drop=14446"] = {"Fingat", "Swamp of Sorrows"}
        s["spell;created=16724"] = {"Whitesoul Helm", ""}
        s["npc;drop=10339"] = {"Gyth <Rend Blackhand's Mount>", "Blackrock Spire"}
        s["spell;created=19054"] = {"Red Dragonscale Breastplate", ""}
        s["npc;drop=14321"] = {"Guard Fengus", "Dire Maul"}
        s["npc;drop=14861"] = {"Blood Steward of Kirtonos", "Scholomance"}
        s["quest;reward=7501"] = {"The Light and How To Swing It", ""}
        s["spell;created=446191"] = {"Baleful Pauldrons", ""}
        s["spell;created=446190"] = {"Wailing Chain Mantle", ""}
        s["quest;reward=84150"] = {"An Earnest Proposition", ""}
        s["npc;drop=10464"] = {"Wailing Banshee", "Stratholme"}
        s["npc;drop=12203"] = {"Landslide", "Maraudon"}
        s["spell;created=435906"] = {"Reflective Truesilver Braincage", ""}
        s["spell;created=435949"] = {"Glowing Hyperconductive Scale Coif", ""}
        s["spell;created=435610"] = {"Gneuro-Linked Arcano-Filament Monocle", ""}
        s["npc;drop=14686"] = {"Lady Falther'ess", "Razorfen Downs"}
        s["npc;sold=222685"] = {"Quartermaster Kyleen", "Ashenvale"}
        s["spell;created=20874"] = {"Dark Iron Bracers", ""}
        s["spell;created=24399"] = {"Dark Iron Boots", ""}
        s["npc;sold=3144"] = {"Eitrigg", "Orgrimmar"}
        s["quest;reward=80131"] = {"Gnome Improvement", ""}
        s["npc;drop=2691"] = {"Highvale Outrunner", "The Hinterlands"}
        s["npc;drop=10596"] = {"Mother Smolderweb", "Blackrock Spire"}
        s["spell;created=465693"] = {"Clean Up Quel'Serrar Era to SoD [DNT]", ""}
        s["spell;created=461730"] = {"Hardened Frostguard", ""}
        s["spell;created=23652"] = {"Blackguard", ""}
        s["spell;created=461669"] = {"Refined Arcanite Champion", ""}
        s["spell;created=22797"] = {"Force Reactive Disk", ""}
        s["npc;drop=3976"] = {"Scarlet Commander Mograine", "Scarlet Monastery"}
        s["quest;reward=7065"] = {"Corruption of Earth and Seed", ""}
        s["spell;created=9952"] = {"Ornate Mithril Shoulders", ""}
        s["npc;drop=5287"] = {"Longtooth Howler", "Feralas"}
        s["npc;drop=1884"] = {"Scarlet Lumberjack", "Western Plaguelands"}
        s["npc;drop=14690"] = {"Revanchion", "Dire Maul"}
        s["npc;drop=10418"] = {"Crimson Guardsman", "Stratholme"}
        s["npc;drop=10808"] = {"Timmy the Cruel", "Stratholme"}
        s["spell;created=16729"] = {"Lionheart Helm", ""}
        s["spell;created=435908"] = {"Tempered Interference-Negating Helmet", ""}
        s["spell;created=24141"] = {"Darksoul Shoulders", ""}
        s["npc;drop=7524"] = {"Anguished Highborne", "Winterspring"}
        s["spell;created=19101"] = {"Volcanic Shoulders", ""}
        s["spell;created=446179"] = {"Shoulderplates of Dread", ""}
        s["quest;reward=5166"] = {"Breastplate of the Chromatic Flight", ""}
        s["spell;created=19076"] = {"Volcanic Breastplate", ""}
        s["spell;created=24139"] = {"Darksoul Breastplate", ""}
        s["spell;created=446238"] = {"Void-Powered Protector's Vambraces", ""}
        s["spell;created=23633"] = {"Gloves of the Dawn", ""}
        s["spell;created=461671"] = {"Stronger-hold Gauntlets", ""}
        s["spell;created=23632"] = {"Girdle of the Dawn", ""}
        s["quest;reward=5081"] = {"Maxwell's Mission", ""}
        s["spell;created=19059"] = {"Volcanic Leggings", ""}
        s["quest;reward=84332"] = {"A Thane's Gratitude", ""}
        s["spell;created=461718"] = {"Tranquility", ""}
        s["spell;created=21160"] = {"Eye of Sulfuras", ""}
        s["npc;drop=9039"] = {"Doom'rel", "Blackrock Depths"}
        s["npc;drop=9031"] = {"Anub'shiah", "Blackrock Depths"}
        s["spell;created=20873"] = {"Fiery Chain Shoulders", ""}
        s["npc;drop=15305"] = {"Lord Skwol <Abyssal High Council>", "Silithus"}
        s["spell;created=461651"] = {"Fiery Plate Gauntlets of the Hidden Technique", ""}
        s["spell;created=27585"] = {"Heavy Obsidian Belt", ""}
        s["spell;created=27829"] = {"Titanic Leggings", ""}
        s["spell;created=20876"] = {"Dark Iron Leggings", ""}
        s["quest;reward=8572"] = {"Veteran's Battlegear", ""}
        s["spell;created=12906"] = {"Gnomish Battle Chicken", ""}
        s["spell;created=460460"] = {"Sulfuron Hammer", ""}
        s["spell;created=450409"] = {"Call of Sul'thraze", ""}
        s["npc;drop=8127"] = {"Antu'sul <Overseer of Sul>", "Zul'Farrak"}
        s["quest;reward=84008"] = {"A Lesson in Grace", ""}
        s["spell;created=461714"] = {"Desecration", ""}
        s["npc;drop=227019"] = {"Diathorus the Seeker", "Demon Fall Canyon"}
        s["spell;created=16994"] = {"Arcanite Reaper", ""}
        s["spell;created=24284"] = {"Punctured Voodoo Doll PRT DND", ""}
        s["spell;created=23151"] = {"Balance of Light and Shadow", ""}
        s["spell;created=28943"] = {"Summon Confessor's Mantle DND", ""}
        s["spell;created=28945"] = {"Summon Confessor's Belt DND", ""}
        s["npc;drop=14517"] = {"High Priestess Jeklik", "Zul'Gurub"}
        s["npc;drop=15816"] = {"Qiraji Major He'al-ie", "Thousand Needles"}
        s["quest;reward=9009"] = {"Saving the Best for Last", ""}
        s["npc;drop=11382"] = {"Bloodlord Mandokir", "Zul'Gurub"}
        s["spell;created=18456"] = {"Truefaith Vestments", ""}
        s["spell;created=28946"] = {"Summon Confessor's Bracers DND", ""}
        s["npc;drop=11664"] = {"Flamewaker Elite", "Molten Core"}
        s["quest;reward=8909"] = {"An Earnest Proposition", ""}
        s["quest;reward=8940"] = {"Just Compensation", ""}
        s["npc;drop=14509"] = {"High Priest Thekal", "Zul'Gurub"}
        s["quest;reward=9019"] = {"Anthion's Parting Words", ""}
        s["quest;reward=7504"] = {"Holy Bologna: What the Light Won't Tell You", ""}
        s["quest;reward=82111"] = {"Blood of Morphaz", ""}
        s["npc;drop=12459"] = {"Blackwing Warlock", "Blackwing Lair"}
        s["object;contained=161495"] = {"Secret Safe", "Blackrock Depths"}
        s["spell;created=463008"] = {"Balance of Light and Shadow", ""}
        s["spell;created=461708"] = {"Incandescent Mooncloth Robe", ""}
        s["quest;reward=84151"] = {"An Earnest Proposition", ""}
        s["spell;created=461752"] = {"Incandescent Mooncloth Leggings", ""}
        s["quest;reward=55"] = {"Morbent Fel", ""}
        s["npc;drop=4366"] = {"Strashaz Serpent Guard", "Dustwallow Marsh"}
        s["npc;drop=10423"] = {"Crimson Priest", "Stratholme"}
        s["npc;drop=9818"] = {"Blackhand Summoner <Blackhand Legion>", "Blackrock Spire"}
        s["spell;created=446193"] = {"Fractured Mind Pauldrons", ""}
        s["npc;drop=9219"] = {"Spirestone Butcher", "Blackrock Spire"}
        s["npc;drop=223544"] = {"Fel Interloper", "Blasted Lands"}
        s["quest;reward=9225"] = {"Epic Armaments of Battle - Revered Amongst the Dawn", ""}
        s["npc;drop=10425"] = {"Crimson Battle Mage", "Stratholme"}
        s["npc;drop=10477"] = {"Scholomance Necromancer", "Scholomance"}
        s["npc;drop=8923"] = {"Panzor the Invincible", "Blackrock Depths"}
        s["npc;drop=10502"] = {"Lady Illucia Barov", "Scholomance"}
        s["quest;reward=9221"] = {"Superior Armaments of Battle - Friend of the Dawn", ""}
        s["npc;drop=14327"] = {"Lethtendris", "Dire Maul"}
        s["spell;created=18436"] = {"Robe of Winter Night", ""}
        s["npc;drop=12457"] = {"Blackwing Spellbinder", "Blackwing Lair"}
        s["quest;reward=8592"] = {"Tiara of the Oracle", ""}
        s["quest;reward=8594"] = {"Mantle of the Oracle", ""}
        s["spell;created=18453"] = {"Felcloth Shoulders", ""}
        s["quest;reward=8603"] = {"Vestments of the Oracle", ""}
        s["npc;drop=15247"] = {"Qiraji Brainwasher", "Ahn'Qiraj"}
        s["spell;created=22867"] = {"Felcloth Gloves", ""}
        s["npc;drop=10432"] = {"Vectus", "Scholomance"}
        s["spell;created=23041"] = {"Call Anathema", ""}
        s["npc;drop=14516"] = {"Death Knight Darkreaver", "Scholomance"}
        s["spell;created=461962"] = {"Call Anathema", ""}
        s["npc;drop=1843"] = {"Foreman Jerris", "Western Plaguelands"}
        s["npc;drop=12801"] = {"Arcane Chimaerok", "Feralas"}
        s["npc;drop=228914"] = {"Severed Keeper", "Demon Fall Canyon"}
        s["npc;drop=10119"] = {"Volchan", "Burning Steppes"}
        s["npc;drop=16154"] = {"Risen Deathknight", "Naxxramas"}
        s["npc;drop=11469"] = {"Eldreth Seether", "Dire Maul"}
        s["npc;drop=14506"] = {"Lord Hel'nurath", "Dire Maul"}
        s["npc;drop=14473"] = {"Lapress", "Silithus"}
        s["npc;drop=15975"] = {"Carrion Spinner", "Naxxramas"}
        s["npc;drop=1838"] = {"Scarlet Interrogator", "Western Plaguelands"}
        s["npc;drop=1851"] = {"The Husk", "Western Plaguelands"}
        s["npc;drop=7104"] = {"Dessecus", "Felwood"}
        s["npc;drop=15757"] = {"Qiraji Lieutenant General", "Silithus"}
        s["npc;drop=15390"] = {"Captain Xurrem", "Ruins of Ahn'Qiraj"}
        s["npc;drop=10371"] = {"Rage Talon Captain", "Blackrock Spire"}
        s["npc;drop=11896"] = {"Borelgore", "Eastern Plaguelands"}
        s["npc;drop=7459"] = {"Ice Thistle Matriarch", "Winterspring"}
        s["npc;drop=10663"] = {"Manaclaw", "Winterspring"}
        s["spell;created=18442"] = {"Felcloth Hood", ""}
        s["npc;drop=11143"] = {"Postmaster Malown", "Stratholme"}
        s["spell;created=19794"] = {"Spellpower Goggles Xtreme Plus", ""}
        s["npc;drop=11622"] = {"Rattlegore", "Scholomance"}
        s["object;contained=181074"] = {"Arena Spoils", "Blackrock Depths"}
        s["spell;created=18451"] = {"Felcloth Robe", ""}
        s["npc;drop=9817"] = {"Blackhand Dreadweaver <Blackhand Legion>", "Blackrock Spire"}
        s["npc;drop=10372"] = {"Rage Talon Fire Tongue", "Blackrock Spire"}
        s["npc;drop=11490"] = {"Zevrim Thornhoof", "Dire Maul"}
        s["npc;drop=10901"] = {"Lorekeeper Polkelt", "Scholomance"}
        s["npc;drop=11467"] = {"Tsu'zee", "Dire Maul"}
        s["spell;created=18454"] = {"Gloves of Spell Mastery", ""}
        s["spell;created=18419"] = {"Felcloth Pants", ""}
        s["npc;drop=10436"] = {"Baroness Anastari", "Stratholme"}
        s["npc;drop=10558"] = {"Hearthsinger Forresten", "Stratholme"}
        s["npc;drop=9217"] = {"Spirestone Lord Magus", "Blackrock Spire"}
        s["npc;drop=6228"] = {"Dark Iron Ambassador", "Gnomeregan"}
        s["npc;drop=6370"] = {"Makrinni Scrabbler", "Azshara"}
        s["quest;reward=9004"] = {"Saving the Best for Last", ""}
        s["quest;reward=8956"] = {"Anthion's Parting Words", ""}
        s["quest;reward=8910"] = {"An Earnest Proposition", ""}
        s["spell;created=24281"] = {"Punctured Voodoo Doll ROG DND", ""}
        s["spell;created=28937"] = {"Summon Madcap's Mantle DND", ""}
        s["quest;reward=8941"] = {"Just Compensation", ""}
        s["quest;reward=8639"] = {"Deathdealer's Helm", ""}
        s["quest;reward=8641"] = {"Deathdealer's Spaulders", ""}
        s["quest;reward=8638"] = {"Deathdealer's Vest", ""}
        s["npc;drop=10505"] = {"Instructor Malicia", "Scholomance"}
        s["quest;reward=8201"] = {"A Collection of Heads", ""}
        s["npc;drop=9265"] = {"Smolderthorn Shadow Hunter", "Blackrock Spire"}
        s["quest;reward=8640"] = {"Deathdealer's Leggings", ""}
        s["quest;reward=8637"] = {"Deathdealer's Boots", ""}
        s["npc;drop=14507"] = {"High Priest Venoxis", "Zul'Gurub"}
        s["quest;reward=7498"] = {"Garona: A Study on Stealth and Treachery", ""}
        s["quest;reward=7787"] = {"Rise, Thunderfury!", ""}
        s["npc;drop=203138"] = {"Anvilrage Overseer", "Blackrock Depths"}
        s["spell;created=461237"] = {"Shadowflame Skull", ""}
        s["spell;created=19090"] = {"Stormshroud Shoulders", ""}
        s["spell;created=19079"] = {"Stormshroud Armor", ""}
        s["quest;reward=84152"] = {"An Earnest Proposition", ""}
        s["spell;created=26279"] = {"Stormshroud Gloves", ""}
        s["npc;drop=10318"] = {"Blackhand Assassin <Blackhand Legion>", "Blackrock Spire"}
        s["spell;created=19067"] = {"Stormshroud Pants", ""}
        s["quest;reward=84548"] = {"Garona: A Study on Stealth and Treachery", ""}
        s["npc;drop=15741"] = {"Colossus of Regal", "Silithus"}
        s["npc;drop=14222"] = {"Araga", "Alterac Mountains"}
        s["quest;reward=53"] = {"Sweet Amber", ""}
        s["npc;drop=2601"] = {"Foulbelly", "Arathi Highlands"}
        s["npc;drop=2751"] = {"War Golem", "Badlands"}
        s["spell;created=9201"] = {"Dusky Bracers", ""}
        s["quest;reward=80455"] = {"Biding Our Time", ""}
        s["npc;drop=15209"] = {"Crimson Templar <Abyssal Council>", "Silithus"}
        s["spell;created=23706"] = {"Golden Mantle of the Dawn", ""}
        s["spell;created=19068"] = {"Warbear Harness", ""}
        s["npc;drop=9237"] = {"War Master Voone", "Blackrock Spire"}
        s["npc;drop=15817"] = {"Qiraji Brigadier General Pax-lish", "Silithus"}
        s["quest;reward=8623"] = {"Stormcaller's Diadem", ""}
        s["quest;reward=9011"] = {"Saving the Best for Last", ""}
        s["quest;reward=7668"] = {"The Darkreaver Menace", ""}
        s["quest;reward=8602"] = {"Stormcaller's Pauldrons", ""}
        s["spell;created=16650"] = {"Wildthorn Mail", ""}
        s["quest;reward=8622"] = {"Stormcaller's Hauberk", ""}
        s["quest;reward=8918"] = {"An Earnest Proposition", ""}
        s["npc;drop=14454"] = {"The Windreaver", "Silithus"}
        s["quest;reward=8621"] = {"Stormcaller's Footguards", ""}
        s["npc;drop=11462"] = {"Warpwood Treant", "Dire Maul"}
        s["quest;reward=7505"] = {"Frost Shock and You", ""}
        s["quest;reward=82113"] = {"Da Voodoo", ""}
        s["spell;created=461735"] = {"Invincible Mail", ""}
        s["quest;reward=84160"] = {"An Earnest Proposition", ""}
        s["npc;drop=11043"] = {"Crimson Monk", "Stratholme"}
        s["spell;created=461737"] = {"Tempest Gauntlets", ""}
        s["npc;drop=10083"] = {"Rage Talon Flamescale", "Blackrock Spire"}
        s["npc;drop=10814"] = {"Chromatic Elite Guard", "Blackrock Spire"}
        s["npc;drop=14323"] = {"Guard Slip'kik", "Dire Maul"}
        s["spell;created=446186"] = {"Cacophonous Chain Shoulderguards", ""}
        s["spell;created=451706"] = {"Screaming Chain Pauldrons", ""}
        s["npc;drop=9028"] = {"Grizzle", "Blackrock Depths"}
        s["spell;created=24138"] = {"Bloodsoul Gauntlets", ""}
        s["npc;drop=224257"] = {"Atal'ai Slave", "The Temple of Atal'Hakkar"}
        s["spell;created=435958"] = {"Whirling Truesilver Gearwall", ""}
        s["spell;created=19094"] = {"Black Dragonscale Shoulders", ""}
        s["spell;created=23708"] = {"Chromatic Gauntlets", ""}
        s["spell;created=19107"] = {"Black Dragonscale Leggings", ""}
        s["spell;created=20855"] = {"Black Dragonscale Boots", ""}
        s["spell;created=23653"] = {"Nightfall", ""}
        s["npc;drop=6117"] = {"Highborne Lichling", "Azshara"}
        s["spell;created=19085"] = {"Black Dragonscale Breastplate", ""}
        s["npc;drop=10507"] = {"The Ravenian", "Scholomance"}
        s["spell;created=16991"] = {"Annihilator", ""}
        s["npc;drop=12258"] = {"Razorlash", "Maraudon"}
        s["npc;drop=7358"] = {"Amnennar the Coldbringer", "Razorfen Downs"}
        s["quest;reward=79366"] = {"Calm Before the Storm", ""}
        s["npc;drop=13596"] = {"Rotgrip", "Maraudon"}
        s["quest;reward=8624"] = {"Stormcaller's Leggings", ""}
        s["quest;reward=7488"] = {"Lethtendris's Web", ""}
        s["quest;reward=5526"] = {"Shards of the Felvine", ""}
        s["spell;created=8770"] = {"Robe of Power", ""}
        s["npc;drop=7357"] = {"Mordresh Fire Eye", "Razorfen Downs"}
        s["spell;created=24356"] = {"Bloodvine Goggles", ""}
        s["quest;reward=8662"] = {"Doomcaller's Circlet", ""}
        s["quest;reward=9005"] = {"Saving the Best for Last", ""}
        s["quest;reward=8664"] = {"Doomcaller's Mantle", ""}
        s["spell;created=28956"] = {"Summon Demoniac's Mantle DND", ""}
        s["quest;reward=8661"] = {"Doomcaller's Robes", ""}
        s["spell;created=18458"] = {"Robe of the Void", ""}
        s["spell;created=28954"] = {"Summon Demoniac's BP DND", ""}
        s["spell;created=28958"] = {"Summon Demoniac's Bracers DND", ""}
        s["quest;reward=8936"] = {"Just Compensation", ""}
        s["quest;reward=8381"] = {"Armaments of War", ""}
        s["spell;created=29033"] = {"Summon Ring of Unspoken Names DND", ""}
        s["spell;created=24290"] = {"Punctured Voodoo Doll WLK DND", ""}
        s["spell;created=24201"] = {"Create Rune of the Dawn", ""}
        s["quest;reward=7502"] = {"Harnessing Shadows", ""}
        s["item:contained=224851"] = {"Otherworldly Treasure", ""}
        s["spell;created=461747"] = {"Incandescent Mooncloth Vest", ""}
        s["quest;reward=84153"] = {"An Earnest Proposition", ""}
        s["spell;created=23662"] = {"Wisdom of the Timbermaw", ""}
        s["spell;created=462282"] = {"Embroidered Belt of the Archmage", ""}
        s["npc;drop=15220"] = {"The Duke of Zephyrs <Abyssal Council>", "Silithus"}
        s["spell;created=429351"] = {"Extraplanar Spidersilk Boots", ""}
        s["npc;drop=15203"] = {"Prince Skaldrenox <Abyssal High Council>", "Silithus"}
        s["spell;created=19830"] = {"Arcanite Dragonling", ""}
        s["spell;created=461743"] = {"Sageblade of the Archmagus", ""}
        s["item:contained=223150"] = {"Otherworldly Treasure", ""}
        s["spell;created=20848"] = {"Flarecore Mantle", ""}
        s["npc;drop=10376"] = {"Crystal Fang", "Blackrock Spire"}
        s["npc;drop=16058"] = {"Volida", "Blackrock Depths"}
        s["spell;created=446195"] = {"Shoulderpads of the Deranged", ""}
        s["spell;created=22870"] = {"Cloak of Warding", ""}
        s["npc;drop=9439"] = {"Dark Keeper Uggel", "Blackrock Depths"}
        s["spell;created=19093"] = {"Onyxia Scale Cloak", ""}
        s["spell;created=20849"] = {"Flarecore Gloves", ""}
        s["quest;reward=84411"] = {"Diplomat Ring", ""}
        s["quest;reward=5942"] = {"Hidden Treasures", ""}
        s["npc;drop=5722"] = {"Hazzas", "The Temple of Atal'Hakkar"}
        s["quest;reward=1560"] = {"Tooga's Quest", ""}
        s["npc;drop=15208"] = {"The Duke of Shards <Abyssal Council>", "Silithus"}
        s["spell;created=23666"] = {"Flarecore Robe", ""}
        s["quest;reward=80141"] = {"Nogg's Ring Redo", ""}
        s["quest;reward=82107"] = {"Voodoo Feathers", ""}
        s["npc;drop=8762"] = {"Timberweb Recluse", "Azshara"}
        s["quest;reward=3129"] = {"Weapons of Spirit", ""}
        s["quest;reward=84162"] = {"An Earnest Proposition", ""}
        s["quest;reward=9006"] = {"Saving the Best for Last", ""}
        s["quest;reward=8561"] = {"Conqueror's Crown", ""}
        s["quest;reward=8544"] = {"Conqueror's Spaulders", ""}
        s["quest;reward=8562"] = {"Conqueror's Breastplate", ""}
        s["quest;reward=8937"] = {"Just Compensation", ""}
        s["quest;reward=8560"] = {"Conqueror's Legguards", ""}
        s["quest;reward=8559"] = {"Conqueror's Greaves", ""}
        s["quest;reward=9022"] = {"Anthion's Parting Words", ""}
        s["spell;created=465699"] = {"Clean Up Quel'Serrar SoD to Era [DNT]", ""}
        s["quest;reward=8789"] = {"Imperial Qiraji Armaments", ""}
        s["spell;created=9954"] = {"Truesilver Gauntlets", ""}
        s["quest;reward=3566"] = {"Rise, Obsidion!", ""}
        s["quest;reward=84550"] = {"Codex of Defense", ""}
        s["npc;sold=231711"] = {"Victor Nefriendius", ""}
        s["spell;created=469680"] = {"Create Zul'Gurub Talisman DRU R4 DND", ""}
        s["spell;created=469681"] = {"Summon Haruspex's BP DND", ""}
        s["spell;created=468559"] = {"Punctured Voodoo Doll DRU DND", ""}
        s["spell;created=452433"] = {"Summon Gla'sir", ""}
        s["spell;created=469682"] = {"Summon Haruspex's Belt DND", ""}
        s["npc;drop=231494"] = {"Prince Thunderaan <The Wind Seeker>", "The Crystal Vale"}
        s["quest;reward=85643"] = {"The Lord of Blackrock", ""}
        s["spell;created=452434"] = {"Summon Rae'lar", ""}
        s["npc;drop=14510"] = {"High Priestess Mar'li", "Zul'Gurub"}
        s["npc;drop=232632"] = {"Azgaloth <Lord of the Pit>", "Demon Fall Canyon"}
        s["spell;created=461710"] = {"Fiery Core Sharpshooter Rifle", ""}
        s["spell;created=469746"] = {"Create Zul'Gurub Talisman MAG R4 DND", ""}
        s["spell;created=466117"] = {"Attune Staff of Rime", ""}
        s["spell;created=465417"] = {"Change Stance", ""}
        s["quest;reward=85443"] = {"Rise, Thunderfury!", ""}
        s["spell;created=465418"] = {"Change Stance", ""}
        s["npc;drop=227939"] = {"The Molten Core", "Molten Core"}
        s["quest;reward=85480"] = {"Procrastimond's Gratitude", ""}
        s["spell;created=469730"] = {"Summon Confessor's Mantle DND", ""}
        s["spell;created=469732"] = {"Summon Confessor's Bracers DND", ""}
        s["spell;created=469731"] = {"Summon Confessor's Belt DND", ""}
        s["spell;created=469718"] = {"Create Zul'Gurub Talisman PRT R4 DND", ""}
        s["spell;created=468558"] = {"Punctured Voodoo Doll PRT DND", ""}
        s["npc;drop=15085"] = {"Wushoolay", "Zul'Gurub"}
        s["npc;drop=15083"] = {"Hazza'rah", "Zul'Gurub"}
        s["spell;created=469754"] = {"Create Zul'Gurub Talisman ROG R4 DND", ""}
        s["spell;created=469759"] = {"Summon Madcap's Mantle DND", ""}
        s["spell;created=468560"] = {"Punctured Voodoo Doll ROG DND", ""}
        s["spell;created=469758"] = {"Summon Madcap's BP DND", ""}
        s["spell;created=469761"] = {"Summon Madcap's Bracers DND", ""}
        s["spell;created=469201"] = {"Ignite Flames", ""}
        s["spell;created=469733"] = {"Create Zul'Gurub Talisman WLK R4 DND", ""}
        s["spell;created=469736"] = {"Summon Demoniac's Bracers DND", ""}
        s["spell;created=468557"] = {"Punctured Voodoo Doll WLK DND", ""}
        s["spell;created=468840"] = {"Combine Scythe of Chaos", ""}
        s["spell;created=469735"] = {"Summon Demoniac's Mantle DND", ""}
        s["spell;created=469734"] = {"Summon Demoniac's BP DND", ""}
        s["npc;drop=15084"] = {"Renataki", "Zul'Gurub"}
        s["object;contained=495500"] = {"Shadowflame Cache", "Blackwing Lair"}
        s["spell;created=469684"] = {"Create Zul'Gurub Talisman WAR R4 DND", ""}
        s["spell;created=469685"] = {"Summon Vindicator's BP DND", ""}
        s["spell;created=469687"] = {"Summon Vindicator's Armguards DND", ""}
        s["quest;reward=85454"] = {"A Just Reward", ""}
        s["spell;created=468552"] = {"Punctured Voodoo Doll WAR DND", ""}
        s["spell;created=467790"] = {"Combine Staff of Order", ""}
        s["spell;created=469743"] = {"Summon Illusionist's Mantle DND", ""}
        s["spell;created=469742"] = {"Summon Illusionist's BP DND", ""}
        s["spell;created=469744"] = {"Summon Illusionist's Bracers DND", ""}
        s["spell;created=468556"] = {"Punctured Voodoo Doll MAG DND", ""}
        s["npc;drop=16011"] = {"Loatheb", "Naxxramas"}
        s["quest;reward=84881"] = {"Into the Hold of Shadows", ""}
        s["npc;drop=14887"] = {"Ysondre", "Duskwood"}
        s["npc;drop=14889"] = {"Emeriss", "Duskwood"}
        s["npc;drop=10184"] = {"Onyxia", "Onyxia's Lair"}
        s["npc;drop=14890"] = {"Taerar", "Duskwood"}
        s["npc;drop=14888"] = {"Lethon", "Duskwood"}
        s["npc;drop=15369"] = {"Ayamiss the Hunter", "Ruins of Ahn'Qiraj"}
        s["quest;reward=86678"] = {"Champion's Battlegear", "Silithus"}
        s["spell;created=1216020"] = {"Idol of Sidereal Wrath", "CRAFTING"}
        s["spell;created=1213538"] = {"Qiraji Silk Cloak", "CRAFTING"}
        s["spell;created=469683"] = {"Summon Haruspex's Bracers DND", "CRAFTING"}
        s["npc;drop=15370"] = {"Buru the Gorger", "Ruins of Ahn'Qiraj"}
        s["npc;drop=235197"] = {"Taerar", "Ashenvale"}
        s["npc;sold=15192"] = {"Anachronos", "Tanaris"}
        s["spell;created=1213595"] = {"Tear of the Dreamer", "CRAFTING"}
        s["spell;created=1213502"] = {"Obsidian Stormhammer", "CRAFTING"}
        s["npc;sold=15500"] = {"Keyl Swiftclaw", "Silithus"}
        s["spell;created=1216340"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1216022"] = {"Idol of Feline Ferocity", "CRAFTING"}
        s["npc;drop=228230"] = {"Harrigen <The Undermarket>", "Burning Steppes"}
        s["spell;created=1213536"] = {"Qiraji Silk Cape", "CRAFTING"}
        s["quest;reward=86675"] = {"Volunteer's Battlegear", "Silithus"}
        s["spell;created=23704"] = {"Timbermaw Brawlers", "CRAFTING"}
        s["quest;reward=86676"] = {"Veteran's Battlegear", "Silithus"}
        s["spell;created=1213593"] = {"Speedstone", "CRAFTING"}
        s["spell;created=1216385"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213500"] = {"Obsidian Destroyer", "CRAFTING"}
        s["spell;created=1216024"] = {"Idol of Ursin Power", "CRAFTING"}
        s["spell;created=24121"] = {"Primal Batskin Jerkin", "CRAFTING"}
        s["spell;created=1213738"] = {"Bramblewood Helm", "CRAFTING"}
        s["spell;created=1213736"] = {"Bramblewood Boots", "CRAFTING"}
        s["spell;created=1213598"] = {"Lodestone of Retaliation", "CRAFTING"}
        s["spell;created=1216366"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213521"] = {"Razorbramble Cowl", "CRAFTING"}
        s["spell;created=1213525"] = {"Razorbramble Leathers", "CRAFTING"}
        s["spell;created=1213523"] = {"Razorbramble Shoulderpads", "CRAFTING"}
        s["npc;drop=15348"] = {"Kurinnaxx", "Ruins of Ahn'Qiraj"}
        s["npc;drop=15544"] = {"Vem", "Ahn'Qiraj"}
        s["spell;created=1213603"] = {"Ruby-Encrusted Broach", "CRAFTING"}
        s["spell;created=1216319"] = {"Void-Touched", "CRAFTING"}
        s["quest;reward=86677"] = {"Stalwart's Battlegear", "Silithus"}
        s["spell;created=1213635"] = {"Enchanted Mushroom", "CRAFTING"}
        s["spell;created=1213540"] = {"Qiraji Silk Drape", "CRAFTING"}
        s["npc;drop=235232"] = {"Ysondre", "The Hinterlands"}
        s["quest;reward=86449"] = {"Treasure of the Timeless One", "Silithus"}
        s["quest;reward=86674"] = {"The Perfect Poison", "Silithus"}
        s["spell;created=1216365"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=468563"] = {"Punctured Voodoo Doll HUN DND", "CRAFTING"}
        s["spell;created=469772"] = {"Create Zul'Gurub Talisman HUN R4 DND", "CRAFTING"}
        s["spell;created=469775"] = {"Summon Predator's Belt DND", "CRAFTING"}
        s["quest;reward=85559"] = {"Night Falls", "Un'Goro Crater"}
        s["spell;created=24137"] = {"Bloodsoul Shoulders", "CRAFTING"}
        s["spell;created=1216384"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1216387"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1216327"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=466116"] = {"Attune Staff of Inferno", "CRAFTING"}
        s["spell;created=1213628"] = {"Enchanted Prayer Tome", "CRAFTING"}
        s["quest;reward=86672"] = {"Imperial Qiraji Armaments", "Blackwing Lair"}
        s["spell;created=1216005"] = {"Libram of Righteousness", "CRAFTING"}
        s["spell;created=1213481"] = {"Razorspike Headcage", "CRAFTING"}
        s["spell;created=1213484"] = {"Razorspike Shoulderplate", "CRAFTING"}
        s["spell;created=1214884"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213588"] = {"Tuned Force Reactive Disk", "CRAFTING"}
        s["spell;created=1214270"] = {"Jagged Obsidian Shield", "CRAFTING"}
        s["spell;created=1213490"] = {"Razorspike Battleplate", "CRAFTING"}
        s["spell;created=1213506"] = {"Obsidian Defender", "CRAFTING"}
        s["spell;created=1216379"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1216007"] = {"Libram of the Exorcist", "CRAFTING"}
        s["spell;created=1216382"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213534"] = {"Qiraji Silk Scarf", "CRAFTING"}
        s["spell;created=1216375"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213492"] = {"Obsidian Reaver", "CRAFTING"}
        s["spell;created=1216377"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213498"] = {"Obsidian Champion", "CRAFTING"}
        s["quest;reward=86671"] = {"Imperial Qiraji Regalia", "Blackwing Lair"}
        s["npc;drop=234880"] = {"Emeriss", "Duskwood"}
        s["spell;created=469677"] = {"Summon Augur's BP DND", "CRAFTING"}
        s["spell;created=469679"] = {"Summon Augur's Bracers DND", "CRAFTING"}
        s["spell;created=469678"] = {"Summon Augur's Belt DND", "CRAFTING"}
        s["spell;created=469676"] = {"Create Zul'Gurub Talisman SHM R4 DND", "CRAFTING"}
        s["spell;created=468555"] = {"Punctured Voodoo Doll SHM DND", "CRAFTING"}
        s["spell;created=1216354"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1216014"] = {"Totem of Pyroclastic Thunder", "CRAFTING"}
        s["spell;created=1213742"] = {"Sylvan Crown", "CRAFTING"}
        s["spell;created=1213740"] = {"Sylvan Shoulders", "CRAFTING"}
        s["spell;created=28210"] = {"Gaea's Embrace", "CRAFTING"}
        s["spell;created=1213744"] = {"Sylvan Vest", "CRAFTING"}
        s["spell;created=1214306"] = {"Dreamscale Bracers", "CRAFTING"}
        s["spell;created=1214307"] = {"Dreamscale Mitts", "CRAFTING"}
        s["npc;drop=235180"] = {"Lethon", "Feralas"}
        s["quest;reward=9248"] = {"A Humble Offering", "Silithus"}
        s["quest;reward=86442"] = {"Nefarius's Corruption", "Blackwing Lair"}
        s["spell;created=1213532"] = {"Vampiric Robe", "CRAFTING"}
        s["object;contained=495503"] = {"Chromatic Hoard", "Blackwing Lair"}
        s["spell;created=1216372"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=29036"] = {"Summon Drape of Unyielding Strength DND", "CRAFTING"}
        s["quest;reward=86673"] = {"The Fall of Ossirian", "Silithus"}
        s["quest;reward=86670"] = {"The Savior of Kalimdor", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"Darkmoon Beast Deck", "Elwynn Forest"}
        s["quest;reward=86762"] = {"Darkmoon Elementals Deck", "Elwynn Forest"}
        s["quest;reward=86680"] = {"Waking Legends", "Moonglade"}
        s["npc;sold=15502"] = {"Andorgos <Brood of Malygos>", "Ahn'Qiraj"}
        s["npc;sold=15504"] = {"Vethsera <Brood of Ysera>", "Ahn'Qiraj"}
        s["npc;sold=15503"] = {"Kandrostrasz <Brood of Alexstrasza>", "Ahn'Qiraj"}
        s["spell;created=1214303"] = {"Dreamscale Kilt", "CRAFTING"}
        s["quest;reward=85063"] = {"Culmination", "Winterspring"}
        s["npc;drop=3975"] = {"Herod <The Scarlet Champion>", "Scarlet Monastery"}
        s["spell;created=1216364"] = {"Void-Touched", "CRAFTING"}
        s["spell;created=1213633"] = {"Enchanted Totem", "CRAFTING"}
        s["spell;created=1216381"] = {"Void-Touched", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne <Cenarion Circle>", "Eastern Plaguelands"}
        s["npc;drop=16061"] = {"Instructor Razuvious", "Naxxramas"}
        s["quest;reward=87360"] = {"The Fall of Kel'Thuzad", "Eastern Plaguelands"}
        s["npc;drop=237964"] = {"Harbinger of Sin", "Karazhan Crypts"}
        s["npc;drop=16143"] = {"Shadow of Doom", "Blasted Lands"}
        s["npc;drop=16380"] = {"Bone Witch", "Burning Steppes"}
        s["quest;reward=87438"] = {"Argent Dawn Leather Gloves", "Eastern Plaguelands"}
        s["npc;drop=238233"] = {"Kaigy Maryla <The Failed Apprentice>", "Karazhan Crypts"}
        s["quest;reward=88723"] = {"Superior Armaments of Battle - Revered Amongst the Dawn", "Eastern Plaguelands"}
        s["npc;drop=16060"] = {"Gothik the Harvester", "Naxxramas"}
        s["npc;drop=15936"] = {"Heigan the Unclean", "Naxxramas"}
        s["npc;drop=15931"] = {"Grobbulus", "Naxxramas"}
        s["npc;drop=15932"] = {"Gluth", "Naxxramas"}
        s["npc;drop=15989"] = {"Sapphiron", "Naxxramas"}
        s["npc;drop=14697"] = {"Lumbering Horror", "Burning Steppes"}
        s["npc;drop=237439"] = {"Kharon", "Karazhan Crypts"}
        s["quest;reward=87440"] = {"Argent Dawn Cloth Gloves", "Eastern Plaguelands"}
        s["npc;drop=15928"] = {"Thaddius", "Naxxramas"}
        s["npc;drop=15953"] = {"Grand Widow Faerlina", "Naxxramas"}
        s["npc;drop=15956"] = {"Anub'Rekhan", "Naxxramas"}
        s["npc;drop=15954"] = {"Noth the Plaguebringer", "Naxxramas"}
        s["npc;drop=238234"] = {"Barian Maryla <The Failed Apprentice>", "Karazhan Crypts"}
        s["npc;drop=238024"] = {"Creeping Malison", "Karazhan Crypts"}
        s["spell;created=1223762"] = {"Glacial Cloak", "CRAFTING"}
        s["npc;drop=16028"] = {"Patchwerk", "Naxxramas"}
        s["npc;drop=238055"] = {"Dark Rider", "Karazhan Crypts"}
        s["npc;drop=238560"] = {"The Warden", "Karazhan Crypts"}
        s["npc;drop=238638"] = {"Echo of the Baroness", "Karazhan Crypts"}
        s["spell;created=24179"] = {"Create Seal of the Dawn", "CRAFTING"}
        s["npc;drop=238213"] = {"Sairuh Maryla <The Failed Apprentice>", "Karazhan Crypts"}
        s["quest;reward=88728"] = {"Epic Armaments of Battle - Exalted Amongst the Dawn", "Eastern Plaguelands"}
        s["npc;drop=238511"] = {"The Gravekeeper", "Karazhan Crypts"}
        s["npc;drop=16379"] = {"Spirit of the Damned", "Burning Steppes"}
        s["npc;sold=16132"] = {"Huntsman Leopold <The Scarlet Crusade>", "Eastern Plaguelands"}
        s["quest;reward=87435"] = {"Argent Dawn Mail Gloves", "Eastern Plaguelands"}
        s["npc;sold=16116"] = {"Archmage Angela Dosantos <Brotherhood of the Light>", "Eastern Plaguelands"}
        s["npc;sold=16115"] = {"Commander Eligor Dawnbringer <Brotherhood of the Light>", "Eastern Plaguelands"}
        s["quest;reward=87434"] = {"Argent Dawn Plate Gloves", "Eastern Plaguelands"}
        s["spell;created=1223787"] = {"Icebane Breastplate", "CRAFTING"}
        s["spell;created=1223791"] = {"Icebane Bracers", "CRAFTING"}
        s["spell;created=1223789"] = {"Icebane Gauntlets", "CRAFTING"}
        s["quest;reward=88730"] = {"The Only Song I Know...", "Eastern Plaguelands"}
        s["spell;created=1223780"] = {"Polar Tunic", "CRAFTING"}
        s["spell;created=1223784"] = {"Polar Bracers", "CRAFTING"}
        s["spell;created=1223782"] = {"Polar Gloves", "CRAFTING"}
        s["quest;reward=86445"] = {"The Wrath of Neptulon", "Tanaris"}
        s["npc;sold=16113"] = {"Father Inigo Montoy <Brotherhood of the Light>", "Eastern Plaguelands"}
        s["spell;created=1223760"] = {"Glacial Vest", "CRAFTING"}
        s["spell;created=1223764"] = {"Glacial Gloves", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan the Assassin <The Scarlet Crusade>", "Eastern Plaguelands"}
        s["spell;created=1214137"] = {"Obsidian Heartseeker", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Earthshatter <The Earthen Ring>", "Eastern Plaguelands"}
        s["npc;drop=238678"] = {"Unk'omon <The Winged Sorrow>", "Karazhan Crypts"}
        s["spell;created=1223766"] = {"Glacial Wrists", "CRAFTING"}
        s["spell;created=1223772"] = {"Frosty Wrists", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus the Wrathcaster <The Scarlet Crusade>", "Eastern Plaguelands"}
        s["spell;created=1213504"] = {"Obsidian Sageblade", "CRAFTING"}
        s["spell;created=1213527"] = {"Vampiric Cowl", "CRAFTING"}
        s["spell;created=1213530"] = {"Vampiric Shawl", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax, Champion of the Light <Brotherhood of the Light>", "Eastern Plaguelands"}
        s["spell;created=1214145"] = {"Obsidian Shotgun", "CRAFTING"}
        s["quest;reward=88729"] = {"Ramaladni's Icy Grasp", "Eastern Plaguelands"}
        s["quest;reward=87443"] = {"Atiesh, Greatstaff of the Guardian", "Tanaris"}
        s["quest;reward=87442"] = {"Atiesh, Greatstaff of the Guardian", "Stratholme"}
        s["quest;reward=87441"] = {"Atiesh, Greatstaff of the Guardian", "Stratholme"}
        s["quest;reward=87444"] = {"Atiesh, Greatstaff of the Guardian", "Tanaris"}
    end

    function SpecBisTooltip:TranslationdeDE()
        s["npc;drop=12435"] = {"Razorgore der Ungezähmte", "Pechschwingenhort"}
        s["spell;created=24091"] = {"Blutrebenweste", ""}
        s["npc;drop=12017"] = {"Brutwächter Dreschbringer", "Pechschwingenhort"}
        s["npc;drop=11380"] = {"Jin'do der Verhexer", "Zul'Gurub"}
        s["npc;drop=11983"] = {"Feuerschwinge", "Pechschwingenhort"}
        s["spell;created=24092"] = {"Blutrebengamaschen", ""}
        s["spell;created=24093"] = {"Blutrebenstiefel", ""}
        s["npc;drop=12098"] = {"Sulfuronherold", "Geschmolzener Kern"}
        s["npc;drop=14601"] = {"Schattenschwinge", "Pechschwingenhort"}
        s["quest;reward=8183"] = {"Das Herz von Hakkar", ""}
        s["npc;sold=13217"] = {"Thanthaldis Snowgleam <Stormpike-Versorgungsoffizier>", "Alteracgebirge"}
        s["npc;drop=10435"] = {"Magistrat Barthilas", "Stratholme"}
        s["spell;created=12622"] = {"Grüne Linse", ""}
        s["spell;created=12092"] = {"Traumzwirnreif", ""}
        s["npc;drop=11261"] = {"Doktor Theolen Krastinov <Der Schlächter>", "Scholomance"}
        s["npc;sold=12777"] = {"Captain Dirgehammer <Rüstmeister für Rüstungen>", "Alteractal"}
        s["npc;sold=12792"] = {"Lady Palanseer <Rüstmeisterin für Rüstungen>", "Alteractal"}
        s["npc;drop=9018"] = {"Verhörmeisterin Gerstahn <Twilight-Hammer-Befrager>", "Blackrocktiefen"}
        s["npc;drop=14353"] = {"Mizzle der Gewiefte", "Düsterbruch"}
        s["npc;drop=10811"] = {"Archivar Galford", "Stratholme"}
        s["npc;drop=9319"] = {"Hundemeister Grebmar", "Blackrocktiefen"}
        s["npc;sold=13218"] = {"Grunnda Wolfheart <Versorgungsoffizier der Frostwolf>", "Alteractal"}
        s["quest;reward=7861"] = {"GESUCHT: Üble Priesterin Hexx und ihre Diener", ""}
        s["npc;drop=11486"] = {"Prinz Tortheldrin", "Düsterbruch"}
        s["npc;drop=15815"] = {"Captain der Qiraji Ka'ark", "Tausend Nadeln"}
        s["npc;drop=10508"] = {"Ras Frostraunen", "Scholomance"}
        s["npc;sold=14753"] = {"Illiyana Moonblaze <Versorgungsoffizier der Silverwing>", "Ashenvale"}
        s["quest;reward=8574"] = {"Schlachtrüstung des Gefolgsmanns", ""}
        s["npc;drop=10516"] = {"Der Unverziehene", "Stratholme"}
        s["npc;drop=14326"] = {"Wache  Mol'dar", "Düsterbruch"}
        s["npc;drop=11662"] = {"Feuerschuppenpriester", "Geschmolzener Kern"}
        s["npc;drop=10584"] = {"Urok Schreckensbote", "Blackrockspitze"}
        s["npc;drop=9736"] = {"Rüstmeister Zigris <Blutaxtlegion>", "Blackrockspitze"}
        s["quest;reward=8464"] = {"Aktivität der Winterfelle", ""}
        s["spell;created=12067"] = {"Traumzwirnhandschuhe", ""}
        s["npc;drop=9030"] = {"Ok'thor der Zerstörer", "Blackrocktiefen"}
        s["npc;sold=13219"] = {"Jekyll Flandring <Versorgungsoffizier der Frostwolf>", "Alteracgebirge"}
        s["spell;created=3864"] = {"Sternengürtel", ""}
        s["npc;drop=12119"] = {"Feuerschuppenbeschützer", "Geschmolzener Kern"}
        s["npc;drop=9196"] = {"Hochlord Omokk", "Blackrockspitze"}
        s["spell;created=23667"] = {"Flimmerkerngamaschen", ""}
        s["npc;drop=7267"] = {"Häuptling Ukorz Sandscalp", "Zul'Farrak"}
        s["npc;drop=8983"] = {"Golemlord Argelmach", "Blackrocktiefen"}
        s["npc;drop=15276"] = {"Imperator Vek'lor", "Ahn'Qiraj"}
        s["npc;drop=13280"] = {"Hydrobrut", "Düsterbruch"}
        s["npc;drop=10429"] = {"Kriegshäuptling Rend Blackhand", "Blackrockspitze"}
        s["npc;drop=10997"] = {"Kanonenmeister Willey", "Stratholme"}
        s["npc;drop=10812"] = {"Oberster Kreuzzügler Dathrohan", "Stratholme"}
        s["npc;drop=15275"] = {"Imperator Vek'nilash", "Ahn'Qiraj"}
        s["npc;drop=15742"] = {"Koloss des Ashischwarms", "Silithus"}
        s["quest;reward=8802"] = {"Der Retter von Kalimdor", ""}
        s["quest;reward=4363"] = {"Die Überraschung der Prinzessin", ""}
        s["quest;reward=4004"] = {"Ist die Prinzessin gerettet?", ""}
        s["quest;reward=7491"] = {"Für alle sichtbar", ""}
        s["npc;sold=14754"] = {"Kelm Hargunth <Warsongversorgungsoffizier>", "Brachland"}
        s["npc;drop=10509"] = {"Jed Runenblick <Blackhand-Legion>", "Blackrockspitze"}
        s["quest;reward=5102"] = {"General Drakkisaths Niedergang", ""}
        s["npc;drop=9156"] = {"Botschafter Flammenschlag", "Blackrocktiefen"}
        s["npc;sold=12782"] = {"Captain O'Neal <Rüstmeister für Waffen>", "Alteractal"}
        s["npc;sold=14581"] = {"Sergeant Thunderhorn <Rüstmeister für Waffen>", "Alteractal"}
        s["npc;sold=15126"] = {"Rutherford Twing <Versorgungsoffizier der Entweihten>", "Arathihochland"}
        s["npc;sold=15127"] = {"Samuel Hawke <Versorgungsoffizier des Bundes von Arathor>", "Arathihochland"}
        s["npc;drop=1853"] = {"Dunkelmeister Gandling", "Scholomance"}
        s["npc;drop=10899"] = {"Goraluk Hammerbruch <Rüstungsschmied der Blackhand-Legion>", "Blackrockspitze"}
        s["npc;drop=11492"] = {"Alzzin der Wildformer", "Düsterbruch"}
        s["quest;reward=8790"] = {"Imperiale Qirajiinsignien", ""}
        s["npc;drop=11988"] = {"Golemagg der Verbrenner", "Geschmolzener Kern"}
        s["npc;drop=2585"] = {"Verteidiger von Stromgarde", "Arathihochland"}
        s["quest;reward=82112"] = {"Eine bessere Zutat", ""}
        s["npc;drop=7271"] = {"Hexendoktor Zum'rah", "Zul'Farrak"}
        s["npc;drop=8440"] = {"Schemen von Hakkar", "Der Tempel von Atal'Hakkar"}
        s["npc;drop=5721"] = {"Traumsense", "Der Tempel von Atal'Hakkar"}
        s["object;contained=181083"] = {"Sothos' und Jariens Erbstücke", "Stratholme"}
        s["quest;reward=7784"] = {"Der Herrscher von Blackrock", ""}
        s["quest;reward=3962"] = {"Allein ist es gefährlich", ""}
        s["npc;drop=4543"] = {"Blutmagier Thalnos", "Das scharlachrote Kloster"}
        s["npc;sold=227819"] = {"Fürst Hydraxis", ""}
        s["npc;drop=228435"] = {"Golemagg der Verbrenner", "Geschmolzener Kern"}
        s["npc;sold=227853"] = {"Pix Xizzix <Händlerin aus Undermine>", "Schlingendorntal"}
        s["spell;created=446192"] = {"Membran der dunklen Neurose", ""}
        s["npc;drop=15205"] = {"Baron Kazum", "Silithus"}
        s["spell;created=461653"] = {"Glänzender chromatischer Umhang", ""}
        s["item:contained=20601"] = {"Beutesack", ""}
        s["npc;sold=222413"] = {"Zalgo der Entdecker <Vertreter für verlorene Waren>", "Schlingendorntal"}
        s["quest;reward=84147"] = {"Ein aufrichtiges Angebot", ""}
        s["npc;drop=218819"] = {"Schwärender Faulschleim", "Der Tempel von Atal'Hakkar"}
        s["spell;created=429869"] = {"Leerenberührte Lederstulpen", ""}
        s["npc;drop=220833"] = {"Traumsense", "Der Tempel von Atal'Hakkar"}
        s["npc;sold=222408"] = {"Abgesandte des Schattenzahns", "Teufelswald"}
        s["spell;created=461754"] = {"Gurt der arkanen Einsicht", ""}
        s["object;contained=179703"] = {"Behälter des Feuerfürsten", "Geschmolzener Kern"}
        s["npc;drop=226923"] = {"Grimmwurzel <Der trauernde Wächter>", "Demonfall-Canyon"}
        s["npc;drop=12201"] = {"Prinzessin Theradras", "Maraudon"}
        s["spell;created=461647"] = {"Meisterlicher Sturmhammer des Himmelsreiters", ""}
        s["npc;drop=4542"] = {"Hochinquisitor Fairbanks", "Das scharlachrote Kloster"}
        s["spell;created=12060"] = {"Rote Magiestoffhose", ""}
        s["spell;created=439105"] = {"Große Voodoomaske", ""}
        s["npc;drop=6490"] = {"Azshir der Schlaflose", "Das scharlachrote Kloster"}
        s["spell;created=439093"] = {"Purpurrote Seidenschultern", ""}
        s["quest;reward=82055"] = {"Dünenkartenset des Dunkelmond-Jahrmarkts", ""}
        s["quest;reward=82057"] = {"Seuchenkartenset des Dunkelmond-Jahrmarkts", ""}
        s["npc;drop=221637"] = {"Schlitzer", "Der Tempel von Atal'Hakkar"}
        s["quest;reward=7940"] = {"1200 Lose - Kugel des Dunkelmonds", ""}
        s["npc;drop=218721"] = {"Jammal'an der Prophet", "Der Tempel von Atal'Hakkar"}
        s["spell;created=10621"] = {"Wolfskopfhelm", ""}
        s["npc;drop=9816"] = {"Feuerwache Glutseher", "Blackrockspitze"}
        s["npc;drop=12467"] = {"Captain der Todeskrallen", "Pechschwingenhort"}
        s["spell;created=23710"] = {"Geschmolzener Gürtel", ""}
        s["npc;drop=11981"] = {"Flammenmaul", "Pechschwingenhort"}
        s["npc;drop=6229"] = {"Meute-Verprügler 9-60", "Gnomeregan"}
        s["npc;drop=15206"] = {"Der Fürst der Asche <Abyssischer Rat>", "Silithus"}
        s["npc;drop=9041"] = {"Wärter Stilgiss", "Blackrocktiefen"}
        s["quest;reward=4261"] = {"Alter Geist", ""}
        s["quest;reward=5068"] = {"Brustplatte des Blutdurstes", ""}
        s["npc;drop=9019"] = {"Imperator Dagran Thaurissan", "Blackrocktiefen"}
        s["npc;drop=15516"] = {"Schlachtwache Sartura", "Ahn'Qiraj"}
        s["spell;created=19084"] = {"Teufelssaurierstulpen", ""}
        s["npc;drop=11361"] = {"Zulianischer Tiger", "Zul'Gurub"}
        s["npc;drop=15323"] = {"Sandpirscher des Zaraschwarms", "Ruinen von Ahn'Qiraj"}
        s["spell;created=19097"] = {"Teufelssauriergamaschen", ""}
        s["object;contained=181366"] = {"Truhe der vier Reiter", "Naxxramas"}
        s["npc;drop=10399"] = {"Thuzadinakolyth", "Stratholme"}
        s["npc;drop=8929"] = {"Prinzessin Moira Bronzebeard <Prinzessin von Ironforge>", "Blackrocktiefen"}
        s["quest;reward=7981"] = {"1200 Lose - Amulett des Dunkelmonds", ""}
        s["quest;reward=7862"] = {"Offener Posten: Wachbefehlshaber von Revantusk", ""}
        s["npc;drop=9568"] = {"Oberanführer Wyrmthalak", "Blackrockspitze"}
        s["quest;reward=3321"] = {"Habt Ihr das verloren?", ""}
        s["npc;sold=12805"] = {"Offizier Areyn <Rüstmeisterin für Zubehör>", "Stormwind"}
        s["npc;sold=12799"] = {"Sergeant Ba'sha <Rüstmeister für Zubehör>", "Orgrimmar"}
        s["npc;drop=12463"] = {"Flammenschuppe der Todeskrallen", "Pechschwingenhort"}
        s["quest;reward=7877"] = {"Der Schatz der Shen'dralar", ""}
        s["npc;drop=2748"] = {"Archaedas <Alter Steinbehüter>", "Uldaman"}
        s["spell;created=23707"] = {"Lavagürtel", ""}
        s["npc;drop=228022"] = {"Gespenst des Zerstörers", "Demonfall-Canyon"}
        s["spell;created=460462"] = {"Auge von Sulfuras", ""}
        s["npc;drop=227028"] = {"Höllschreis Phantom", "Demonfall-Canyon"}
        s["npc;drop=15204"] = {"Hochmarschall Whirlaxis", "Silithus"}
        s["npc;drop=218624"] = {"Atal'alarion <Wächter des Götzen>", "Der Tempel von Atal'Hakkar"}
        s["spell;created=24123"] = {"Urzeitliche Fledermaushautarmschienen", ""}
        s["spell;created=24122"] = {"Urzeitliche Fledermaushauthandschuhe", ""}
        s["npc;drop=10422"] = {"Purpurroter Zauberhexer", "Stratholme"}
        s["quest;reward=84561"] = {"[For All To See]", ""}
        s["quest;reward=5944"] = {"In den Träumen", ""}
        s["quest;reward=8949"] = {"Falrins Rachefeldzug", ""}
        s["npc;sold=12944"] = {"Lokhtos Darkbargainer <Die Thoriumbruderschaft>", ""}
        s["npc;drop=228436"] = {"Sulfuronherold", "Geschmolzener Kern"}
        s["spell;created=461712"] = {"Veredelter Hammer der Titanen", ""}
        s["spell;created=16988"] = {"Hammer der Titanen", ""}
        s["spell;created=461722"] = {"Teufelskernstulpen", ""}
        s["spell;created=461724"] = {"Teufelskerngamaschen", ""}
        s["quest;reward=84545"] = {"Die Belohnung eines Helden", ""}
        s["npc;drop=15510"] = {"Fankriss der Unnachgiebige", "Ahn'Qiraj"}
        s["npc;drop=10487"] = {"Auferstandener Beschützer", "Scholomance"}
        s["npc;drop=15263"] = {"Der Prophet Skeram", "Ahn'Qiraj"}
        s["npc;drop=16449"] = {"Geist von Naxxramas", "Naxxramas"}
        s["npc;drop=12460"] = {"Wyrmwache der Todeskrallen", "Pechschwingenhort"}
        s["npc;drop=10430"] = {"Die Bestie", "Blackrockspitze"}
        s["npc;drop=10500"] = {"Spektraler Lehrmeister", "Scholomance"}
        s["npc;drop=221407"] = {"Traumschattenwichtel", "Feralas"}
        s["quest;reward=9120"] = {"Der Niedergang Kel'Thuzads", ""}
        s["spell;created=15596"] = {"Rauchendes Herz des Berges", ""}
        s["quest;reward=7067"] = {"Die Anweisungen des Pariahs", ""}
        s["quest;reward=8573"] = {"Schlachtrüstung des Feldherrn", ""}
        s["npc;drop=9547"] = {"Saufender Gast", "Blackrocktiefen"}
        s["spell;created=461690"] = {"Meisterlich gefertigter unbeständiger Umhang", ""}
        s["spell;created=435904"] = {"Leuchtende Gneuro-verkettete Gugel", ""}
        s["spell;created=23703"] = {"Macht der Holzschlundfeste", ""}
        s["spell;created=19080"] = {"Kriegsbärenwollwäsche", ""}
        s["npc;sold=10857"] = {"Argentumrüstmeister Lightspark <Die Argentumdämmerung>", "Westliche Pestländer"}
        s["spell;created=23705"] = {"Stiefel der Dämmerung", ""}
        s["npc;sold=13278"] = {"Fürst Hydraxis", "Azshara"}
        s["npc;sold=218115"] = {"Mai'zin <Blutwandler der Gurubashi>", "Schlingendorntal"}
        s["quest;reward=80324"] = {"Der irre König", ""}
        s["npc;drop=8567"] = {"Nimmersatt", "Die Hügel von Razorfen"}
        s["npc;drop=220007"] = {"Verflüssigte Ablagerung", "Gnomeregan"}
        s["npc;sold=217689"] = {"Ziri 'Schraubenschlüssel' Miniritzel <Bastlerin>", ""}
        s["npc;drop=220072"] = {"Elektrokutor 6000", "Gnomeregan"}
        s["spell;created=429354"] = {"Leerenberührte Lederhandschuhe", ""}
        s["quest;reward=824"] = {"Je'neu vom Irdenen Ring", ""}
        s["quest;reward=80132"] = {"Maschinenkriege", ""}
        s["npc;drop=3669"] = {"Lord Kobrahn <Giftzahnlord>", "Die Höhlen des Wehklagens"}
        s["npc;drop=215728"] = {"Meuteverprügler 9-60", "Gnomeregan"}
        s["npc;drop=218537"] = {"Robogenieur Thermaplugg", "Gnomeregan"}
        s["npc;drop=4295"] = {"Scharlachroter Myrmidone", "Das scharlachrote Kloster"}
        s["quest;reward=7541"] = {"Dienst an der Horde", ""}
        s["npc;drop=6489"] = {"Eisenrücken", "Das scharlachrote Kloster"}
        s["quest;reward=78916"] = {"Herz der Leere", ""}
        s["npc;drop=7584"] = {"Wandernder Waldgänger", "Feralas"}
        s["npc;drop=4389"] = {"Düsterdrescher", "Marschen von Dustwallow"}
        s["npc;drop=2433"] = {"Helculars sterbliche Überreste", "Vorgebirge von Hillsbrad"}
        s["spell;created=6705"] = {"Murlocschuppenarmschienen", ""}
        s["spell;created=3779"] = {"Barbarischer Gürtel", ""}
        s["npc;drop=4845"] = {"Grobian der Schattenschmiede", "Ödland"}
        s["quest;reward=2767"] = {"Die Rettung von OOX-22/FE", ""}
        s["quest;reward=793"] = {"Zerbrochene Allianzen", ""}
        s["spell;created=435960"] = {"Hyperleitendes Goldnetz", ""}
        s["npc;drop=9033"] = {"General Zornesschmied", "Blackrocktiefen"}
        s["npc;drop=12018"] = {"Majordomus Executus", "Geschmolzener Kern"}
        s["npc;drop=15509"] = {"Prinzessin Huhuran", "Ahn'Qiraj"}
        s["quest;reward=7506"] = {"Der Smaragdgrüne Traum", ""}
        s["npc;drop=15543"] = {"Prinzessin Yauj", "Ahn'Qiraj"}
        s["spell;created=22927"] = {"Balg der Wildnis", ""}
        s["npc;drop=11501"] = {"König Gordok", "Düsterbruch"}
        s["npc;drop=10268"] = {"Gizrul der Geifernde", "Blackrockspitze"}
        s["spell;created=22759"] = {"Flimmerkernwickeltücher", ""}
        s["npc;drop=15339"] = {"Ossirian der Narbenlose", "Ruinen von Ahn'Qiraj"}
        s["spell;created=23709"] = {"Kernhundgürtel", ""}
        s["npc;drop=13020"] = {"Vaelastrasz der Verdorbene", "Pechschwingenhort"}
        s["npc;drop=11488"] = {"Illyanna Rabeneiche", "Düsterbruch"}
        s["npc;drop=9056"] = {"Fineous Darkvire <Chefarchitekt>", "Blackrocktiefen"}
        s["npc;drop=10809"] = {"Steinbuckel", "Stratholme"}
        s["quest;reward=8791"] = {"Der Untergang von Ossirian", ""}
        s["npc;drop=10439"] = {"Ramstein der Verschlinger", "Stratholme"}
        s["quest;reward=7907"] = {"Bestienkartenset des Dunkelmond-Jahrmarkts", ""}
        s["object;contained=169243"] = {"Truhe der Sieben", "Blackrocktiefen"}
        s["npc;drop=14515"] = {"Hohepriesterin Arlokk", "Zul'Gurub"}
        s["spell;created=461750"] = {"Gleißender Mondstoffreif", ""}
        s["spell;created=23665"] = {"Argentumschultern", ""}
        s["spell;created=446189"] = {"Schulterpolster der Besessenheit", ""}
        s["spell;created=19061"] = {"Lebendige Schultern", ""}
        s["spell;created=446194"] = {"Mantel des Wahnsinns", ""}
        s["npc;drop=221394"] = {"Avatar von Hakkar", "Der Tempel von Atal'Hakkar"}
        s["npc;drop=9236"] = {"Schattenjägerin Vosh'gajin", "Blackrockspitze"}
        s["spell;created=19435"] = {"Mondstoffstiefel", ""}
        s["npc;drop=218571"] = {"Eranikus' Schemen", "Der Tempel von Atal'Hakkar"}
        s["npc;drop=10506"] = {"Kirtonos der Herold", "Scholomance"}
        s["quest;reward=80325"] = {"Der irre König", ""}
        s["quest;reward=82081"] = {"Ein zerbrochenes Ritual", ""}
        s["quest;reward=82058"] = {"Wildniskartenset des Dunkelmond-Jahrmarkts", ""}
        s["npc;drop=3977"] = {"Hochinquisitor Whitemane", "Das scharlachrote Kloster"}
        s["npc;drop=14324"] = {"Cho'Rush der Beobachter", "Düsterbruch"}
        s["npc;drop=11661"] = {"Feuerschuppe", "Geschmolzener Kern"}
        s["npc;drop=11673"] = {"Uralter Kernhund", "Geschmolzener Kern"}
        s["quest;reward=9008"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=4024"] = {"Eine Kostprobe der Flamme", ""}
        s["npc;drop=13276"] = {"Wichtel der Wildhufe", "Düsterbruch"}
        s["npc;drop=9027"] = {"Gorosh der Derwisch", "Blackrocktiefen"}
        s["npc;drop=10264"] = {"Solakar Feuerkrone", "Blackrockspitze"}
        s["quest;reward=8906"] = {"Ein aufrichtiges Angebot", ""}
        s["quest;reward=8938"] = {"Die angemessene Entlohnung", ""}
        s["npc;drop=11489"] = {"Tendris Wucherborke", "Düsterbruch"}
        s["npc;drop=9596"] = {"Bannok Grimmaxt <Champion der Feuerbrandlegion>", "Blackrockspitze"}
        s["quest;reward=8952"] = {"Anthions Abschiedsworte", ""}
        s["spell;created=22922"] = {"Mungostiefel", ""}
        s["quest;reward=5125"] = {"Aurius' Abrechnung", ""}
        s["quest;reward=7503"] = {"Das größte Volk von Jägern", ""}
        s["quest;reward=82108"] = {"Der grüne Drache", ""}
        s["npc;drop=10438"] = {"Maleki der Leichenblasse", "Stratholme"}
        s["npc;drop=221391"] = {"Slirena <Harpyienkönigin>", "Feralas"}
        s["npc;drop=15740"] = {"Koloss des Zoraschwarms", "Silithus"}
        s["spell;created=462623"] = {"Stellt Rhok'delar her", ""}
        s["quest;reward=82104"] = {"Jammal'an der Prophet", ""}
        s["npc;drop=8908"] = {"Geschmolzener Kriegsgolem", "Blackrocktiefen"}
        s["quest;reward=84148"] = {"Ein aufrichtiges Angebot", ""}
        s["spell;created=446237"] = {"Leerenaufgeladene Unterarmschienen des Rächers", ""}
        s["npc;drop=9029"] = {"Ausweider", "Blackrocktiefen"}
        s["quest;reward=7029"] = {"Schlangenzunges Verderbnis", ""}
        s["object;contained=179564"] = {"Tribut der Gordok", "Düsterbruch"}
        s["npc;drop=9445"] = {"Dunkelwache", "Blackrocktiefen"}
        s["spell;created=23639"] = {"Schattenzorn", ""}
        s["spell;created=461675"] = {"Veredelter Arkanitschnitter", ""}
        s["npc;drop=222573"] = {"Wahnbesessene Uralte", "Zul'Farrak"}
        s["quest;reward=8272"] = {"Held der Frostwolf", ""}
        s["quest;reward=3636"] = {"Das Licht bringen", ""}
        s["quest;reward=1364"] = {"Mazens Befehl", ""}
        s["npc;drop=7603"] = {"Aussätziger Gehilfe", "Gnomeregan"}
        s["npc;drop=2716"] = {"Wyrmjäger der Staubspeier", "Ödland"}
        s["quest;reward=628"] = {"Exzelsior", ""}
        s["quest;reward=7068"] = {"Schattensplitter", ""}
        s["quest;reward=2822"] = {"Das Zeichen der Qualität", ""}
        s["npc;drop=5860"] = {"Twilight-Dunkelschamane", "Sengende Schlucht"}
        s["npc;drop=13601"] = {"Tüftler Gizlock", "Maraudon"}
        s["quest;reward=1048"] = {"In das Scharlachrote Kloster", ""}
        s["spell;created=435953"] = {"Strahlungsresistente Schuppenkapuze", ""}
        s["spell;created=18457"] = {"Robe des Erzmagiers", ""}
        s["quest;reward=8632"] = {"Reif des Mysteriums", ""}
        s["quest;reward=8625"] = {"Schulterpolster des Mysteriums", ""}
        s["quest;reward=8633"] = {"Roben des Mysteriums", ""}
        s["quest;reward=8634"] = {"Stiefel des Mysteriums", ""}
        s["npc;drop=15236"] = {"Wespe der Vekniss", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=84157"] = {"Ein aufrichtiges Angebot", ""}
        s["quest;reward=84549"] = {"Das Arkanistenkochbuch", ""}
        s["npc;drop=11480"] = {"Arkane Entartung", "Düsterbruch"}
        s["quest;reward=84181"] = {"Anthions Abschiedsworte", ""}
        s["npc;drop=10198"] = {"Kashoch der Häscher", "Winterspring"}
        s["quest;reward=84165"] = {"Die angemessene Entlohnung", ""}
        s["spell;created=22868"] = {"Infernohandschuhe", ""}
        s["quest;reward=82095"] = {"Der Gott Hakkar", ""}
        s["quest;reward=8932"] = {"Die angemessene Entlohnung", ""}
        s["npc;drop=9024"] = {"Pyromant Weiskorn", "Blackrocktiefen"}
        s["quest;reward=617"] = {"Bündelweise Akiris", ""}
        s["npc;drop=6146"] = {"Klippenbrecher", "Azshara"}
        s["spell;created=446236"] = {"Leerenaufgeladene Unterarmschienen des Herbeirufers", ""}
        s["quest;reward=3907"] = {"Disharmonie des Feuers", ""}
        s["spell;created=23663"] = {"Mantel der Holzschlundfeste", ""}
        s["npc;drop=4288"] = {"Scharlachroter Bestienmeister", "Das scharlachrote Kloster"}
        s["npc;drop=6487"] = {"Arkanist Doan", "Das scharlachrote Kloster"}
        s["quest;reward=8366"] = {"Gaunerei und Erpressung im Südmeer", ""}
        s["npc;drop=14446"] = {"Flossgat", "Sümpfe des Elends"}
        s["spell;created=16724"] = {"Helm der weißen Seele", ""}
        s["npc;drop=10339"] = {"Gyth <Rend Blackhands Reittier>", "Blackrockspitze"}
        s["spell;created=19054"] = {"Rote Drachenschuppenbrustplatte", ""}
        s["npc;drop=14321"] = {"Wache Fengus", "Düsterbruch"}
        s["npc;drop=14861"] = {"Blutdiener von Kirtonos", "Scholomance"}
        s["quest;reward=7501"] = {"Vom Licht und wie man es schwingt", ""}
        s["spell;created=446191"] = {"Elendige Schulterstücke", ""}
        s["spell;created=446190"] = {"Wehklagender Kettenmantel", ""}
        s["quest;reward=84150"] = {"Ein aufrichtiges Angebot", ""}
        s["npc;drop=10464"] = {"Heulende Banshee", "Stratholme"}
        s["npc;drop=12203"] = {"Erdrutsch", "Maraudon"}
        s["spell;created=435906"] = {"Reflektierender Echtsilbergehirnkäfig", ""}
        s["spell;created=435949"] = {"Leuchtende hyperleitende Schuppenkappe", ""}
        s["spell;created=435610"] = {"Gneuro-verkettetes Arkanfaden-Monokel", ""}
        s["npc;sold=222685"] = {"Rüstmeisterin Kyleen", "Ashenvale"}
        s["spell;created=20874"] = {"Dunkeleisenarmschienen", ""}
        s["spell;created=24399"] = {"Dunkeleisenstiefel", ""}
        s["npc;sold=3144"] = {"Etrigg", "Orgrimmar"}
        s["quest;reward=80131"] = {"Gnomenverbesserungen", ""}
        s["npc;drop=2691"] = {"Hochtalkundschafterin", "Hinterland"}
        s["npc;drop=10596"] = {"Mutter Glimmernetz", "Blackrockspitze"}
        s["spell;created=461730"] = {"Gehärtete Frostwache", ""}
        s["spell;created=23652"] = {"Finsterer Streiter", ""}
        s["spell;created=461669"] = {"Veredelter Arkanitchampion", ""}
        s["spell;created=22797"] = {"Machtreaktive Scheibe", ""}
        s["npc;drop=3976"] = {"Scharlachroter Kommandant Mograine", "Das scharlachrote Kloster"}
        s["quest;reward=7065"] = {"Verderbnis von Erde und Samenkorn", ""}
        s["spell;created=9952"] = {"Verschnörkelte Mithrilschultern", ""}
        s["npc;drop=5287"] = {"Langzahnheuler", "Feralas"}
        s["npc;drop=1884"] = {"Scharlachroter Holzfäller", "Westliche Pestländer"}
        s["npc;drop=10418"] = {"Purpurroter Gardist", "Stratholme"}
        s["npc;drop=10808"] = {"Timmy der Grausame", "Stratholme"}
        s["spell;created=16729"] = {"Löwenherzhelm", ""}
        s["spell;created=435908"] = {"Gehärteter Interferenzen-negierender Helm", ""}
        s["spell;created=24141"] = {"Dunkelseelenschultern", ""}
        s["npc;drop=7524"] = {"Gepeinigter Hochgeborener", "Winterspring"}
        s["spell;created=19101"] = {"Vulkanische Schultern", ""}
        s["spell;created=446179"] = {"Schulterplatten des Schreckens", ""}
        s["quest;reward=5166"] = {"Brustplatte des Chromatischen Drachenschwarms", ""}
        s["spell;created=19076"] = {"Vulkanische Brustplatte", ""}
        s["spell;created=24139"] = {"Dunkelseelenbrustplatte", ""}
        s["spell;created=446238"] = {"Leerenaufgeladene Unterarmschienen des Beschützers", ""}
        s["spell;created=23633"] = {"Handschuhe der Dämmerung", ""}
        s["spell;created=461671"] = {"Festerungsstulpen", ""}
        s["spell;created=23632"] = {"Gurt der Dämmerung", ""}
        s["quest;reward=5081"] = {"Maxwells Mission", ""}
        s["spell;created=19059"] = {"Vulkanische Gamaschen", ""}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", ""}
        s["spell;created=461718"] = {"Gelassenheit", ""}
        s["spell;created=21160"] = {"Auge von Sulfuras", ""}
        s["npc;drop=9039"] = {"Un'rel", "Blackrocktiefen"}
        s["spell;created=20873"] = {"Feurige Kettenschultern", ""}
        s["npc;drop=15305"] = {"Lord Skwol", "Silithus"}
        s["spell;created=461651"] = {"Feurige Plattenstulpen der verborgenen Technik", ""}
        s["spell;created=27585"] = {"Schwerer Obsidiangürtel", ""}
        s["spell;created=27829"] = {"Gamaschen der Titanen", ""}
        s["spell;created=20876"] = {"Dunkeleisengamaschen", ""}
        s["quest;reward=8572"] = {"Schlachtrüstung des Veteranen", ""}
        s["spell;created=12906"] = {"Gnomen-Kampfhuhn", ""}
        s["spell;created=460460"] = {"Sulfuronhammer", ""}
        s["spell;created=450409"] = {"Sul'thrazes Ruf", ""}
        s["npc;drop=8127"] = {"Antu'sul <Vorarbeiter von Sul>", "Zul'Farrak"}
        s["quest;reward=84008"] = {"Eine Lektion in Sachen Anmut", ""}
        s["spell;created=461714"] = {"Entweihung", ""}
        s["npc;drop=227019"] = {"Diathorus der Sucher", "Demonfall-Canyon"}
        s["spell;created=16994"] = {"Arkanitschnitter", ""}
        s["spell;created=23151"] = {"Balance von Licht und Schatten", ""}
        s["npc;drop=14517"] = {"Hohepriesterin Jeklik", "Zul'Gurub"}
        s["npc;drop=15816"] = {"Major der Qiraji He'al-ie", "Tausend Nadeln"}
        s["quest;reward=9009"] = {"Das Beste gibt's zum Schluss", ""}
        s["npc;drop=11382"] = {"Blutfürst Mandokir", "Zul'Gurub"}
        s["spell;created=18456"] = {"Trachten des wahren Glaubens", ""}
        s["npc;drop=11664"] = {"Feuerschuppenelite", "Geschmolzener Kern"}
        s["quest;reward=8909"] = {"Ein aufrichtiges Angebot", ""}
        s["quest;reward=8940"] = {"Die angemessene Entlohnung", ""}
        s["npc;drop=14509"] = {"Hohepriester Thekal", "Zul'Gurub"}
        s["quest;reward=9019"] = {"Anthions Abschiedsworte", ""}
        s["quest;reward=7504"] = {"Heiliger Fleischklops: Was das Licht Dir nicht erzählt", ""}
        s["quest;reward=82111"] = {"Morphaz' Blut", ""}
        s["npc;drop=12459"] = {"Hexenmeister der Pechschwingen", "Pechschwingenhort"}
        s["object;contained=161495"] = {"Geheimsafe", "Blackrocktiefen"}
        s["spell;created=463008"] = {"Balance von Licht und Schatten", ""}
        s["spell;created=461708"] = {"Gleißende Mondstoffrobe", ""}
        s["quest;reward=84151"] = {"Ein aufrichtiges Angebot", ""}
        s["spell;created=461752"] = {"Gleißende Mondstoffgamaschen", ""}
        s["quest;reward=55"] = {"Morbent Fel", ""}
        s["npc;drop=4366"] = {"Strashazschlangenwache", "Marschen von Dustwallow"}
        s["npc;drop=10423"] = {"Purpurroter Priester", "Stratholme"}
        s["npc;drop=9818"] = {"Blackhand-Beschwörer <Blackhand-Legion>", "Blackrockspitze"}
        s["spell;created=446193"] = {"Schulterstücke des zerrütteten Geists", ""}
        s["npc;drop=9219"] = {"Metzger der Felsspitzoger", "Blackrockspitze"}
        s["npc;drop=223544"] = {"Teuflischer Eindringling", "Verwüstete Lande"}
        s["quest;reward=9225"] = {"Epische Kampfausrüstung - Respekt der Dämmerung", ""}
        s["npc;drop=10425"] = {"Purpurroter Kampfmagier", "Stratholme"}
        s["npc;drop=10477"] = {"Totenbeschwörer aus Scholomance", "Scholomance"}
        s["npc;drop=8923"] = {"Panzor der Unbesiegbare", "Blackrocktiefen"}
        s["quest;reward=9221"] = {"Überragende Kampfausrüstung - Freund der Dämmerung", ""}
        s["spell;created=18436"] = {"Robe der Winternacht", ""}
        s["npc;drop=12457"] = {"Zauberbinder der Pechschwingen", "Pechschwingenhort"}
        s["quest;reward=8592"] = {"Tiara des Orakels", ""}
        s["quest;reward=8594"] = {"Mantel des Orakels", ""}
        s["spell;created=18453"] = {"Teufelsstoffschultern", ""}
        s["quest;reward=8603"] = {"Gewänder des Orakels", ""}
        s["npc;drop=15247"] = {"Gehirnwäscher der Qiraji", "Ahn'Qiraj"}
        s["spell;created=22867"] = {"Teufelsstoffhandschuhe", ""}
        s["spell;created=23041"] = {"Bannfluch rufen", ""}
        s["npc;drop=14516"] = {"Todesritter Schattensichel", "Scholomance"}
        s["spell;created=461962"] = {"Bannfluch rufen", ""}
        s["npc;drop=1843"] = {"Großknecht Jerris", "Westliche Pestländer"}
        s["npc;drop=12801"] = {"Arkaner Chimaerok", "Feralas"}
        s["npc;drop=228914"] = {"Abtrünniger Bewahrer", "Demonfall-Canyon"}
        s["npc;drop=16154"] = {"Auferstandener Todesritter", "Naxxramas"}
        s["npc;drop=11469"] = {"Schnauber der Eldreth", "Düsterbruch"}
        s["npc;drop=15975"] = {"Aasspinner", "Naxxramas"}
        s["npc;drop=1838"] = {"Scharlachroter Befrager", "Westliche Pestländer"}
        s["npc;drop=1851"] = {"Die Hülse", "Westliche Pestländer"}
        s["npc;drop=15757"] = {"Generallieutenant der Qiraji", "Silithus"}
        s["npc;drop=10371"] = {"Captain der Zornkrallen", "Blackrockspitze"}
        s["npc;drop=11896"] = {"Blutschlinger", "Östliche Pestländer"}
        s["npc;drop=7459"] = {"Eisdistelmatriarchin", "Winterspring"}
        s["npc;drop=10663"] = {"Manaklaue", "Winterspring"}
        s["spell;created=18442"] = {"Teufelsstoffkapuze", ""}
        s["npc;drop=11143"] = {"Postmeister Malown", "Stratholme"}
        s["spell;created=19794"] = {"Zaubermachtschutzbrille Xtrem Plus", ""}
        s["npc;drop=11622"] = {"Blutrippe", "Scholomance"}
        s["object;contained=181074"] = {"Arenabeute", "Blackrocktiefen"}
        s["spell;created=18451"] = {"Teufelsstoffrobe", ""}
        s["npc;drop=9817"] = {"Blackhand-Schreckenswirker <Blackhand-Legion>", "Blackrockspitze"}
        s["npc;drop=10372"] = {"Feuerzunge der Zornkrallen", "Blackrockspitze"}
        s["npc;drop=11490"] = {"Zevrim Dornhuf", "Düsterbruch"}
        s["npc;drop=10901"] = {"Hüter des Wissens Polkelt", "Scholomance"}
        s["spell;created=18454"] = {"Handschuhe der Zauberbeherrschung", ""}
        s["spell;created=18419"] = {"Teufelsstoffhose", ""}
        s["npc;drop=10558"] = {"Herdsinger Forresten", "Stratholme"}
        s["npc;drop=9217"] = {"Maguslord der Felsspitzoger", "Blackrockspitze"}
        s["npc;drop=6228"] = {"Botschafter der Dunkeleisenzwerge", "Gnomeregan"}
        s["npc;drop=6370"] = {"Makrinnischarrer", "Azshara"}
        s["quest;reward=9004"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=8956"] = {"Anthions Abschiedsworte", ""}
        s["quest;reward=8910"] = {"Ein aufrichtiges Angebot", ""}
        s["quest;reward=8941"] = {"Die angemessene Entlohnung", ""}
        s["quest;reward=8639"] = {"Helm des Todesboten", ""}
        s["quest;reward=8641"] = {"Schiftung des Todesboten", ""}
        s["quest;reward=8638"] = {"Weste des Todesboten", ""}
        s["npc;drop=10505"] = {"Instrukteurin Malicia", "Scholomance"}
        s["quest;reward=8201"] = {"Die Schädelsammlung", ""}
        s["npc;drop=9265"] = {"Schattenjäger der Gluthauer", "Blackrockspitze"}
        s["quest;reward=8640"] = {"Gamaschen des Todesboten", ""}
        s["quest;reward=8637"] = {"Stiefel des Todesboten", ""}
        s["npc;drop=14507"] = {"Hohepriester Venoxis", "Zul'Gurub"}
        s["quest;reward=7498"] = {"Garona: Eine Studie über Heimlichkeit und Verrat", ""}
        s["quest;reward=7787"] = {"Donnerzorn erwache!", ""}
        s["npc;drop=203138"] = {"Vorarbeiter der Zorneshämmer", "Blackrocktiefen"}
        s["spell;created=461237"] = {"Schattenflammenschädel", ""}
        s["spell;created=19090"] = {"Sturmschleierschultern", ""}
        s["spell;created=19079"] = {"Sturmschleierrüstung", ""}
        s["quest;reward=84152"] = {"Ein aufrichtiges Angebot", ""}
        s["spell;created=26279"] = {"Sturmschleierhandschuhe", ""}
        s["npc;drop=10318"] = {"Blackhand-Auftragsmörder <Blackhand-Legion>", "Blackrockspitze"}
        s["spell;created=19067"] = {"Sturmschleierhose", ""}
        s["quest;reward=84548"] = {"Garona: Eine Studie über Heimlichkeit und Verrat", ""}
        s["npc;drop=15741"] = {"Koloss des Regalschwarms", "Silithus"}
        s["quest;reward=53"] = {"Goldbrauner Samt", ""}
        s["npc;drop=2601"] = {"Faulbauch", "Arathihochland"}
        s["npc;drop=2751"] = {"Kriegsgolem", "Ödland"}
        s["spell;created=9201"] = {"Schwärzliche Armschienen", ""}
        s["quest;reward=80455"] = {"Sich Zeit nehmen", ""}
        s["npc;drop=15209"] = {"Purpurroter Templer <Abyssischer Rat>", "Silithus"}
        s["spell;created=23706"] = {"Goldener Mantel der Dämmerung", ""}
        s["spell;created=19068"] = {"Kriegsbärenharnisch", ""}
        s["npc;drop=9237"] = {"Kriegsmeister Voone", "Blackrockspitze"}
        s["npc;drop=15817"] = {"Brigadegeneral der Qiraji Pax-lish", "Silithus"}
        s["quest;reward=8623"] = {"Diadem des Sturmrufers", ""}
        s["quest;reward=9011"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=7668"] = {"Die Bedrohung durch Schattensichel", ""}
        s["quest;reward=8602"] = {"Schulterstücke des Sturmrufers", ""}
        s["spell;created=16650"] = {"Wilddornpanzerung", ""}
        s["quest;reward=8622"] = {"Halsberge des Sturmrufers", ""}
        s["quest;reward=8918"] = {"Ein aufrichtiges Angebot", ""}
        s["npc;drop=14454"] = {"Der Windhäscher", "Silithus"}
        s["quest;reward=8621"] = {"Fußschützer des Sturmrufers", ""}
        s["npc;drop=11462"] = {"Wucherborkentreant", "Düsterbruch"}
        s["quest;reward=7505"] = {"Frostschock und Du", ""}
        s["quest;reward=82113"] = {"Die Macht des Voodoos", ""}
        s["spell;created=461735"] = {"Unverwundbarer Panzer", ""}
        s["quest;reward=84160"] = {"Ein aufrichtiges Angebot", ""}
        s["npc;drop=11043"] = {"Purpurroter Mönch", "Stratholme"}
        s["spell;created=461737"] = {"Sturmstulpen", ""}
        s["npc;drop=10083"] = {"Flammenschuppe der Zornkrallen", "Blackrockspitze"}
        s["npc;drop=10814"] = {"Chromatische Elitewache", "Blackrockspitze"}
        s["npc;drop=14323"] = {"Wache Slip'kik", "Düsterbruch"}
        s["spell;created=446186"] = {"Kakofonische Kettenschulterschützer", ""}
        s["spell;created=451706"] = {"Schreiende Kettenschulterstücke", ""}
        s["spell;created=24138"] = {"Blutseelenstulpen", ""}
        s["npc;drop=224257"] = {"Sklave der Atal'ai", "Der Tempel von Atal'Hakkar"}
        s["spell;created=435958"] = {"Wirbelnder Echtsilberzahnradschild", ""}
        s["spell;created=19094"] = {"Schwarze Drachenschuppenschultern", ""}
        s["spell;created=23708"] = {"Chromatische Stulpen", ""}
        s["spell;created=19107"] = {"Schwarze Drachenschuppengamaschen", ""}
        s["spell;created=20855"] = {"Schwarze Drachenschuppenstiefel", ""}
        s["spell;created=23653"] = {"Nachtlauer", ""}
        s["npc;drop=6117"] = {"Lichling eines Hochgeborenen", "Azshara"}
        s["spell;created=19085"] = {"Schwarze Drachenschuppenbrustplatte", ""}
        s["npc;drop=10507"] = {"Der Ravenier", "Scholomance"}
        s["spell;created=16991"] = {"Vernichter", ""}
        s["npc;drop=12258"] = {"Schlingwurzler", "Maraudon"}
        s["npc;drop=7358"] = {"Amnennar der Kältebringer", "Die Hügel von Razorfen"}
        s["quest;reward=79366"] = {"Die Ruhe vor dem Sturm", ""}
        s["npc;drop=13596"] = {"Faulschnapper", "Maraudon"}
        s["quest;reward=8624"] = {"Gamaschen des Sturmrufers", ""}
        s["quest;reward=7488"] = {"Lethtendris' Netz", ""}
        s["quest;reward=5526"] = {"Die Splitter der Teufelsranke", ""}
        s["spell;created=8770"] = {"Robe der Macht", ""}
        s["npc;drop=7357"] = {"Mordresh Feuerauge", "Die Hügel von Razorfen"}
        s["spell;created=24356"] = {"Blutrebenschutzbrille", ""}
        s["quest;reward=8662"] = {"Reif des Verdammnisrufers", ""}
        s["quest;reward=9005"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=8664"] = {"Mantel des Verdammnisrufers", ""}
        s["quest;reward=8661"] = {"Roben des Verdammnisrufers", ""}
        s["spell;created=18458"] = {"Robe der Leere", ""}
        s["quest;reward=8936"] = {"Die angemessene Entlohnung", ""}
        s["quest;reward=8381"] = {"Kriegsausrüstung", ""}
        s["spell;created=24201"] = {"Rune der Dämmerung herstellen", ""}
        s["quest;reward=7502"] = {"Schatten einspannen", ""}
        s["item:contained=224851"] = {"Überirdischer Schatz", ""}
        s["spell;created=461747"] = {"Gleißende Mondstoffweste", ""}
        s["quest;reward=84153"] = {"Ein aufrichtiges Angebot", ""}
        s["spell;created=23662"] = {"Weisheit der Holzschlundfeste", ""}
        s["spell;created=462282"] = {"Bestickter Gürtel des Erzmagiers", ""}
        s["npc;drop=15220"] = {"Der Fürst der Stürme <Abyssischer Rat>", "Silithus"}
        s["spell;created=429351"] = {"Extraplanare Spinnenseidenstiefel", ""}
        s["npc;drop=15203"] = {"Prinz Skaldrenox", "Silithus"}
        s["spell;created=19830"] = {"Arkanitdrachling", ""}
        s["spell;created=461743"] = {"Weisenklinge des Erzmagiers", ""}
        s["item:contained=223150"] = {"Überirdischer Schatz", ""}
        s["spell;created=20848"] = {"Flimmerkernmantel", ""}
        s["npc;drop=10376"] = {"Kristallfangzahn", "Blackrockspitze"}
        s["spell;created=446195"] = {"Schulterpolster der Verwirrten", ""}
        s["spell;created=22870"] = {"Schutzumhang der Verteidigung", ""}
        s["npc;drop=9439"] = {"Dunkelbewahrer Uggel", "Blackrocktiefen"}
        s["spell;created=19093"] = {"Onyxiaschuppenumhang", ""}
        s["spell;created=20849"] = {"Flimmerkernhandschuhe", ""}
        s["quest;reward=84411"] = {"[Diplomat Ring]", ""}
        s["quest;reward=5942"] = {"Versteckte Schätze", ""}
        s["quest;reward=1560"] = {"Toogas Bitte", ""}
        s["npc;drop=15208"] = {"Der Fürst der Splitter <Abyssischer Rat>", "Silithus"}
        s["spell;created=23666"] = {"Flimmerkernrobe", ""}
        s["quest;reward=80141"] = {"Noggs Ringerneuerung", ""}
        s["quest;reward=82107"] = {"Voodoofedern", ""}
        s["npc;drop=8762"] = {"Baumspinnereremit", "Azshara"}
        s["quest;reward=3129"] = {"Waffen des Geistes", ""}
        s["quest;reward=84162"] = {"Ein aufrichtiges Angebot", ""}
        s["quest;reward=9006"] = {"Das Beste gibt's zum Schluss", ""}
        s["quest;reward=8561"] = {"Krone des Eroberers", ""}
        s["quest;reward=8544"] = {"Schiftung des Eroberers", ""}
        s["quest;reward=8562"] = {"Brustplatte des Eroberers", ""}
        s["quest;reward=8937"] = {"Die angemessene Entlohnung", ""}
        s["quest;reward=8560"] = {"Beinschützer des Eroberers", ""}
        s["quest;reward=8559"] = {"Schienbeinschützer des Eroberers", ""}
        s["quest;reward=9022"] = {"Anthions Abschiedsworte", ""}
        s["quest;reward=8789"] = {"Imperiale Qirajiwaffen", ""}
        s["spell;created=9954"] = {"Echtsilberstulpen", ""}
        s["quest;reward=3566"] = {"Erhebt Euch, Obsidion!", ""}
        s["quest;reward=84550"] = {"Kodex der Verteidigung", ""}
        s["npc;sold=231711"] = {"Viktor Nefreundius", ""}
        s["spell;created=452433"] = {"Gla'sir beschwören", ""}
        s["npc;drop=231494"] = {"Prinz Donneraan <Der Windsucher>", "Das Kristalltal"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", ""}
        s["spell;created=452434"] = {"Rae'lar beschwören", ""}
        s["npc;drop=14510"] = {"Hohepriesterin Mar'li", "Zul'Gurub"}
        s["npc;drop=232632"] = {"Azgaloth <Herr der Grube>", "Demonfall-Canyon"}
        s["spell;created=461710"] = {"Feuerkern-Scharfschützengewehr", ""}
        s["spell;created=466117"] = {"Stab des Raureifs abstimmen", ""}
        s["spell;created=465417"] = {"Haltung ändern", ""}
        s["quest;reward=85443"] = {"[Rise, Thunderfury!]", ""}
        s["spell;created=465418"] = {"Haltung ändern", ""}
        s["npc;drop=227939"] = {"Der Geschmolzene Kern", "Geschmolzener Kern"}
        s["quest;reward=85480"] = {"[Procrastimond's Gratitude]", ""}
        s["spell;created=469201"] = {"Flammen entfachen", ""}
        s["spell;created=468840"] = {"Sense des Chaos zusammensetzen", ""}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Pechschwingenhort"}
        s["quest;reward=85454"] = {"[A Just Reward]", ""}
        s["spell;created=467790"] = {"Stab der Ordnung kombinieren", ""}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", ""}
        s["npc;drop=15369"] = {"Ayamiss der Jäger", "Ruinen von Ahn'Qiraj"}
        s["quest;reward=86678"] = {"Schlachtrüstung des Feldherren", "Silithus"}
        s["spell;created=1216020"] = {"Götze des siderischen Zorns", "CRAFTING"}
        s["spell;created=1213538"] = {"Qirajiseidenumhang", "CRAFTING"}
        s["npc;drop=15370"] = {"Buru der Verschlinger", "Ruinen von Ahn'Qiraj"}
        s["spell;created=1213595"] = {"Träne des Träumers", "CRAFTING"}
        s["spell;created=1213502"] = {"Obsidiansturmhammer", "CRAFTING"}
        s["spell;created=1216340"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1216022"] = {"Götze der Katzenwildheit", "CRAFTING"}
        s["npc;drop=228230"] = {"Harrigen <Der Untermarkt>", "Brennende Steppe"}
        s["spell;created=1213536"] = {"Qirajiseidencape", "CRAFTING"}
        s["quest;reward=86675"] = {"Schlachtrüstung des Kriegsfreiwilligen", "Silithus"}
        s["spell;created=23704"] = {"Kampfhandschuhe der Holzschlundfeste", "CRAFTING"}
        s["quest;reward=86676"] = {"Schlachtrüstung des Veteranen", "Silithus"}
        s["spell;created=1213593"] = {"Geschwindigkeitsstein", "CRAFTING"}
        s["spell;created=1216385"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213500"] = {"Obsidianzerstörer", "CRAFTING"}
        s["spell;created=1216024"] = {"Götze der Bärenwut", "CRAFTING"}
        s["spell;created=24121"] = {"Urzeitliche Fledermaushautwams", "CRAFTING"}
        s["spell;created=1213738"] = {"Dornenholzhelm", "CRAFTING"}
        s["spell;created=1213736"] = {"Dornenholzstiefel", "CRAFTING"}
        s["spell;created=1213598"] = {"Leitstein der Vergeltung", "CRAFTING"}
        s["spell;created=1216366"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213521"] = {"Messerdornengugel", "CRAFTING"}
        s["spell;created=1213525"] = {"Messerdornenlederwams", "CRAFTING"}
        s["spell;created=1213523"] = {"Messerdornenschulterpolster", "CRAFTING"}
        s["spell;created=1213603"] = {"Rubinbesetzte Brosche", "CRAFTING"}
        s["spell;created=1216319"] = {"Leerenberührt", "CRAFTING"}
        s["quest;reward=86677"] = {"Schlachtrüstung des Gefolgsmanns", "Silithus"}
        s["spell;created=1213635"] = {"Verzauberter Pilz", "CRAFTING"}
        s["spell;created=1213540"] = {"Qirajiseidentuch", "CRAFTING"}
        s["quest;reward=86449"] = {"Der Schatz des Zeitlosen", "Silithus"}
        s["quest;reward=86674"] = {"Das perfekte Gift", "Silithus"}
        s["spell;created=1216365"] = {"Leerenberührt", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Un'Goro-Krater"}
        s["spell;created=24137"] = {"Blutseelenschultern", "CRAFTING"}
        s["spell;created=1216384"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1216387"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1216327"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=466116"] = {"Stab des Infernos abstimmen", "CRAFTING"}
        s["spell;created=1213628"] = {"Verzauberter Gebetsband", "CRAFTING"}
        s["quest;reward=86672"] = {"Imperiale Qirajiwaffen", "Pechschwingenhort"}
        s["spell;created=1216005"] = {"Buchband der Rechtschaffenheit", "CRAFTING"}
        s["spell;created=1213481"] = {"Klingenstachelhirnkasten", "CRAFTING"}
        s["spell;created=1213484"] = {"Klingenstachelschulterplatten", "CRAFTING"}
        s["spell;created=1214884"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213588"] = {"Gestimmte machtreaktive Scheibe", "CRAFTING"}
        s["spell;created=1214270"] = {"Gezackter Obsidianschild", "CRAFTING"}
        s["spell;created=1213490"] = {"Klingenstachelkampfplatte", "CRAFTING"}
        s["spell;created=1213506"] = {"Obsidianverteidiger", "CRAFTING"}
        s["spell;created=1216379"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1216007"] = {"Buchband des Exorzisten", "CRAFTING"}
        s["spell;created=1216382"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213534"] = {"Qirajiseidenschal", "CRAFTING"}
        s["spell;created=1216375"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213492"] = {"Obsidianhäscher", "CRAFTING"}
        s["spell;created=1216377"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213498"] = {"Obsidianchampion", "CRAFTING"}
        s["quest;reward=86671"] = {"Imperiale Qirajiinsignien", "Pechschwingenhort"}
        s["spell;created=1216354"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1216014"] = {"Totem des pyroklastischen Donners", "CRAFTING"}
        s["spell;created=1213742"] = {"Sylvankrone", "CRAFTING"}
        s["spell;created=1213740"] = {"Sylvanschultern", "CRAFTING"}
        s["spell;created=28210"] = {"Gaeas Umarmung", "CRAFTING"}
        s["spell;created=1213744"] = {"Sylvanweste", "CRAFTING"}
        s["spell;created=1214306"] = {"Traumschuppenarmschienen", "CRAFTING"}
        s["spell;created=1214307"] = {"Traumschuppenfäustlinge", "CRAFTING"}
        s["quest;reward=9248"] = {"Eine bescheidene Darbringung", "Silithus"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "Pechschwingenhort"}
        s["spell;created=1213532"] = {"Vampirrobe", "CRAFTING"}
        s["object;contained=495503"] = {"Chromatischer Hort", "Pechschwingenhort"}
        s["spell;created=1216372"] = {"Leerenberührt", "CRAFTING"}
        s["quest;reward=86673"] = {"Der Untergang von Ossirian", "Silithus"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"Bestienkartenset des Dunkelmond-Jahrmarkts", "Wald von Elwynn"}
        s["quest;reward=86762"] = {"Elementarkartenset des Dunkelmond-Jahrmarkts", "Wald von Elwynn"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Moonglade"}
        s["spell;created=1214303"] = {"Traumschuppenkilt", "CRAFTING"}
        s["quest;reward=85063"] = {"Höhepunkt", "Winterspring"}
        s["npc;drop=3975"] = {"Herod <Der Scharlachrote Held>", "Das scharlachrote Kloster"}
        s["spell;created=1216364"] = {"Leerenberührt", "CRAFTING"}
        s["spell;created=1213633"] = {"Verzaubertes Totem", "CRAFTING"}
        s["spell;created=1216381"] = {"Leerenberührt", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne <Der Zirkel des Cenarius>", "Östliche Pestländer"}
        s["npc;drop=16061"] = {"Instrukteur Razuvious", "Naxxramas"}
        s["quest;reward=87360"] = {"Der Niedergang Kel'Thuzads", "Östliche Pestländer"}
        s["npc;drop=237964"] = {"Herold der Sünde", "Karazhangruften"}
        s["npc;drop=16143"] = {"Schatten der Verdammnis", "Verwüstete Lande"}
        s["npc;drop=16380"] = {"Knochenhexe", "Brennende Steppe"}
        s["quest;reward=87438"] = {"Lederhandschuhe der Argentumdämmerung", "Östliche Pestländer"}
        s["npc;drop=238233"] = {"Kaigy Maryla <Der versagte Lehrling>", "Karazhangruften"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Östliche Pestländer"}
        s["npc;drop=16060"] = {"Gothik der Seelenjäger", "Naxxramas"}
        s["npc;drop=15936"] = {"Heigan der Unreine", "Naxxramas"}
        s["npc;drop=15989"] = {"Saphiron", "Naxxramas"}
        s["npc;drop=14697"] = {"Schwerfälliger Horror", "Brennende Steppe"}
        s["quest;reward=87440"] = {"Stoffhandschuhe der Argentumdämmerung", "Östliche Pestländer"}
        s["npc;drop=15953"] = {"Großwitwe Faerlina", "Naxxramas"}
        s["npc;drop=15954"] = {"Noth der Seuchenfürst", "Naxxramas"}
        s["npc;drop=238234"] = {"Barian Maryla <Der versagte Lehrling>", "Karazhangruften"}
        s["npc;drop=238024"] = {"Schleichender Fluch", "Karazhangruften"}
        s["spell;created=1223762"] = {"Gletscherumhang", "CRAFTING"}
        s["npc;drop=16028"] = {"Flickwerk", "Naxxramas"}
        s["npc;drop=238055"] = {"Dunkler Reiter", "Karazhangruften"}
        s["npc;drop=238560"] = {"Der Wärter", "Karazhangruften"}
        s["npc;drop=238638"] = {"Echo der Baronin", "Karazhangruften"}
        s["spell;created=24179"] = {"Siegel der Dämmerung herstellen", "CRAFTING"}
        s["npc;drop=238213"] = {"Sairuh Maryla <Der versagte Lehrling>", "Karazhangruften"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "Östliche Pestländer"}
        s["npc;drop=238511"] = {"Der Grabhüter", "Karazhangruften"}
        s["npc;drop=16379"] = {"Geist der Verdammten", "Brennende Steppe"}
        s["npc;sold=16132"] = {"Jäger Leopold <Der Scharlachrote Kreuzzug>", "Östliche Pestländer"}
        s["quest;reward=87435"] = {"Kettenhandschuhe der Argentumdämmerung", "Östliche Pestländer"}
        s["npc;sold=16116"] = {"Erzmagierin Angela Dosantos <Bruderschaft des Lichts>", "Östliche Pestländer"}
        s["npc;sold=16115"] = {"Kommandant Eligor Dawnbringer <Bruderschaft des Lichts>", "Östliche Pestländer"}
        s["quest;reward=87434"] = {"Plattenhandschuhe der Argentumdämmerung", "Östliche Pestländer"}
        s["spell;created=1223787"] = {"Eisfluchbrustplatte", "CRAFTING"}
        s["spell;created=1223791"] = {"Eisflucharmschienen", "CRAFTING"}
        s["spell;created=1223789"] = {"Eisfluchstulpen", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Östliche Pestländer"}
        s["spell;created=1223780"] = {"Polartunika", "CRAFTING"}
        s["spell;created=1223784"] = {"Polararmschienen", "CRAFTING"}
        s["spell;created=1223782"] = {"Polarhandschuhe", "CRAFTING"}
        s["quest;reward=86445"] = {"Der Zorn von Neptulon", "Tanaris"}
        s["npc;sold=16113"] = {"Vater Inigo Montoy <Bruderschaft des Lichts>", "Östliche Pestländer"}
        s["spell;created=1223760"] = {"Gletscherweste", "CRAFTING"}
        s["spell;created=1223764"] = {"Gletscherhandschuhe", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan der Assassine <Der Scharlachrote Kreuzzug>", "Östliche Pestländer"}
        s["spell;created=1214137"] = {"Obsidianherzsucher", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Erdspalter <Der irdene Ring>", "Östliche Pestländer"}
        s["npc;drop=238678"] = {"Un'G'wöhnlich <Der geflügelte Kummer>", "Karazhangruften"}
        s["spell;created=1223766"] = {"Gletscherhandschutz", "CRAFTING"}
        s["spell;created=1223772"] = {"Frostige Handgelenke", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus der Zornwirker <Der Scharlachrote Kreuzzug>", "Östliche Pestländer"}
        s["spell;created=1213504"] = {"Obsidianweisenklinge", "CRAFTING"}
        s["spell;created=1213527"] = {"Vampirgugel", "CRAFTING"}
        s["spell;created=1213530"] = {"Vampirschal", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax der Held des Lichts <Bruderschaft des Lichts>", "Östliche Pestländer"}
        s["spell;created=1214145"] = {"Obsidianschrotflinte", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Östliche Pestländer"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
    end

    function SpecBisTooltip:TranslationesES()
        s["npc;drop=12435"] = {"Sangrevaja el Indomable", "Guarida Alanegra"}
        s["spell;created=24091"] = {"Jubón vid de sangre", ""}
        s["npc;drop=12017"] = {"Señor de prole Capazote", "Guarida Alanegra"}
        s["npc;drop=11380"] = {"Jin'do el Malhechor", "Zul'Gurub"}
        s["npc;drop=11983"] = {"Faucefogo", "Guarida Alanegra"}
        s["spell;created=24092"] = {"Leotardos vid de sangre", ""}
        s["spell;created=24093"] = {"Botas vid de sangre", ""}
        s["npc;drop=12098"] = {"Sulfuron Presagista", "Núcleo de Magma"}
        s["npc;drop=14601"] = {"Ebanorroca", "Guarida Alanegra"}
        s["quest;reward=8183"] = {"El corazón de Hakkar", ""}
        s["npc;sold=13217"] = {"Thanthaldis Brillaneve <Oficial de suministros Pico Tormenta>", "Montañas de Alterac"}
        s["npc;drop=10435"] = {"Magistrado Barthilas", "Stratholme"}
        s["spell;created=12622"] = {"Lentes verdes", ""}
        s["spell;created=12092"] = {"Aro Tejesueños", ""}
        s["npc;drop=11261"] = {"Doctor Theolen Krastinov", "Scholomance"}
        s["npc;sold=12777"] = {"Capitán Plañiazote <Intendente de armaduras>", "Cuenca de Arathi"}
        s["npc;sold=12792"] = {"Lady Palanseer <Intendente de armaduras>", "Cuenca de Arathi"}
        s["npc;drop=9018"] = {"Alta Interrogadora Gerstahn <Interrogador del Martillo Crepuscular>", "Profundidades de Roca Negra"}
        s["npc;drop=14353"] = {"Mizzle el Astuto", "La Masacre"}
        s["npc;drop=10811"] = {"Archivista Galford", "Stratholme"}
        s["npc;drop=9319"] = {"Domador de jaurías Grebmar", "Profundidades de Roca Negra"}
        s["npc;drop=11487"] = {"Magistral Kalendris", "La Masacre"}
        s["npc;sold=13218"] = {"Grunnda Cuorelupo <Oficial de suministros Lobo Gélido>", "Valle de Alterac"}
        s["quest;reward=7861"] = {"Se buscan: Sacerdotisa Vil Hexx y sus esbirros", ""}
        s["npc;drop=11486"] = {"Príncipe Tortheldrin", "La Masacre"}
        s["npc;drop=15815"] = {"Capitán qiraji Ka'ark", "Las Mil Agujas"}
        s["npc;drop=10508"] = {"Ras Levescarcha", "Scholomance"}
        s["npc;sold=14753"] = {"Illiyana Lunardiente <Oficial de suministros de Ala de Plata>", "Vallefresno"}
        s["quest;reward=8574"] = {"Equipamiento de Fiel", ""}
        s["npc;drop=10516"] = {"El imperdonable", "Stratholme"}
        s["npc;drop=14326"] = {"Guardia Mol'dar", "La Masacre"}
        s["npc;drop=11662"] = {"Sacerdote despiertallamas", "Núcleo de Magma"}
        s["npc;drop=10584"] = {"Urok Aullapocalipsis", "Cumbre de Roca Negra"}
        s["npc;drop=9736"] = {"Intendente Zigris", "Cumbre de Roca Negra"}
        s["quest;reward=8464"] = {"Actividad de los Nevada", ""}
        s["spell;created=12067"] = {"Guantes Tejesueños", ""}
        s["npc;drop=12056"] = {"Barón Geddon", "Núcleo de Magma"}
        s["npc;drop=9030"] = {"Ok'thor el Rompedor", "Profundidades de Roca Negra"}
        s["npc;sold=13219"] = {"Jekyll Flandring <Oficial de suministros Lobo Gélido>", "Montañas de Alterac"}
        s["spell;created=3864"] = {"Cinturón de estrella", ""}
        s["npc;drop=12119"] = {"Protector Caminallamas", "Núcleo de Magma"}
        s["npc;drop=9196"] = {"Alto Señor Omokk", "Cumbre de Roca Negra"}
        s["spell;created=23667"] = {"Leotardos Nucleobengala", ""}
        s["npc;drop=7267"] = {"Jefe Ukorz Cabellarena", "Zul'Farrak"}
        s["npc;drop=8983"] = {"Señor Gólem Argelmach", "Profundidades de Roca Negra"}
        s["npc;drop=15276"] = {"Emperador Vek'lor", "Ahn'Qiraj"}
        s["npc;drop=13280"] = {"Hidromilecio", "La Masacre"}
        s["npc;drop=10429"] = {"Jefe de Guerra Desgarro Puño Negro", "Cumbre de Roca Negra"}
        s["npc;drop=10997"] = {"Maestro cañonero Willey", "Stratholme"}
        s["npc;drop=10812"] = {"Gran Cruzado Dathrohan", "Stratholme"}
        s["npc;drop=15275"] = {"Emperador Vek'nilash", "Ahn'Qiraj"}
        s["npc;drop=15742"] = {"Coloso de Ashi", "Silithus"}
        s["quest;reward=8802"] = {"El salvador de Kalimdor", ""}
        s["quest;reward=4363"] = {"La sorpresa de la princesa", ""}
        s["quest;reward=4004"] = {"¿Princesa salvada?", ""}
        s["quest;reward=7491"] = {"Para que todo lo vean", ""}
        s["npc;sold=14754"] = {"Kelm Hargunth <Oficial de suministros Grito de Guerra>", "Los Baldíos"}
        s["npc;drop=10509"] = {"Jed Observarrunas <Legión Puño Negro>", "Cumbre de Roca Negra"}
        s["quest;reward=5102"] = {"Muerte al general Drakkisath", ""}
        s["npc;drop=9156"] = {"Embajador Latifuego", "Profundidades de Roca Negra"}
        s["npc;sold=12782"] = {"Capitán O'Neal <Intendente de armas>", "Cuenca de Arathi"}
        s["npc;sold=14581"] = {"Sargento Tronacuerno", "Cuenca de Arathi"}
        s["npc;sold=15126"] = {"Rutherford Twing <Oficial de suministros de los Rapiñadores>", "Tierras Altas de Arathi"}
        s["npc;sold=15127"] = {"Samuel Halcón <Oficial de suministros de la Liga de Arathor>", "Tierras Altas de Arathi"}
        s["npc;drop=1853"] = {"Maestro oscuro Gandling", "Scholomance"}
        s["npc;drop=10899"] = {"Goraluk Yunquegrieta", "Cumbre de Roca Negra"}
        s["npc;drop=11492"] = {"Alzzin el Formaferal", "La Masacre"}
        s["quest;reward=8790"] = {"Regalos imperiales Qiraji", ""}
        s["npc;drop=11988"] = {"Golemagg el Incinerador", "Núcleo de Magma"}
        s["npc;drop=2585"] = {"Vindicador de Stromgarde", "Tierras Altas de Arathi"}
        s["quest;reward=82112"] = {"Un ingrediente mejor", ""}
        s["npc;drop=7271"] = {"Médico brujo Zum'rah", "Zul'Farrak"}
        s["npc;drop=8440"] = {"Sombra de Hakkar", "El Templo de Atal'Hakkar"}
        s["npc;drop=5721"] = {"Guadañasueños", "El Templo de Atal'Hakkar"}
        s["object;contained=181083"] = {"[Sothos and Jarien's Heirlooms]", "Stratholme"}
        s["quest;reward=7784"] = {"Señor de Roca Negra", ""}
        s["quest;reward=3962"] = {"Ir solo es peligroso", ""}
        s["npc;drop=4543"] = {"Mago sangriento Thalnos", "Monasterio Escarlata"}
        s["npc;sold=227819"] = {"[Duke Hydraxis]", ""}
        s["npc;drop=228435"] = {"[Golemagg the Incinerator]", "Núcleo de Magma"}
        s["npc;drop=228438"] = {"[Ragnaros]", "Núcleo de Magma"}
        s["npc;drop=228432"] = {"[Garr]", "Núcleo de Magma"}
        s["npc;sold=227853"] = {"Pix Xizzix <Comerciante de Minahonda>", "Vega de Tuercespina"}
        s["spell;created=446192"] = {"Membrana de neurosis oscura", ""}
        s["npc;drop=15205"] = {"Barón Kazum", "Silithus"}
        s["spell;created=461653"] = {"Capa cromática brillante", ""}
        s["item:contained=20601"] = {"Saco de botín", ""}
        s["npc;drop=228434"] = {"[Shazzrah]", "Núcleo de Magma"}
        s["npc;sold=222413"] = {"Zalgo el Explorador <Proveedor de cosas perdidas>", "Vega de Tuercespina"}
        s["quest;reward=84147"] = {"[An Earnest Proposition]", ""}
        s["npc;drop=218819"] = {"Baba putrefacta purulenta", "El Templo de Atal'Hakkar"}
        s["spell;created=429869"] = {"Guanteletes de cuero tocados por el Vacío", ""}
        s["npc;drop=220833"] = {"Guadañasueños", "El Templo de Atal'Hakkar"}
        s["npc;sold=222408"] = {"Emisaria diente oscuro", "Frondavil"}
        s["spell;created=461754"] = {"Faja de perspicacia Arcana", ""}
        s["npc;drop=228433"] = {"[Baron Geddon]", "Núcleo de Magma"}
        s["object;contained=179703"] = {"Alijo del Señor del Fuego", "Núcleo de Magma"}
        s["npc;drop=228429"] = {"[Lucifron]", "Núcleo de Magma"}
        s["npc;drop=226923"] = {"[Grimroot] <[The Mourning Guardian]>", "Barranco del Demonio"}
        s["npc;drop=12201"] = {"Princesa Theradras", "Maraudon"}
        s["spell;created=461647"] = {"Martillo de tormenta magistral de jinete celeste", ""}
        s["npc;drop=4542"] = {"Alto Inquisidor Ribalimpia", "Monasterio Escarlata"}
        s["spell;created=12060"] = {"Pantalones rojos de tejemagia", ""}
        s["spell;created=439105"] = {"Máscara de gran vudú", ""}
        s["npc;drop=6490"] = {"Azshir el Insomne", "Monasterio Escarlata"}
        s["spell;created=439093"] = {"Sobrehombros de seda carmesíes", ""}
        s["quest;reward=82055"] = {"La baraja de Dunas de la Luna Negra", ""}
        s["quest;reward=82057"] = {"La baraja de Plagas de la Luna Negra", ""}
        s["quest;reward=7940"] = {"1200 vales: orbe de la Luna Negra", ""}
        s["npc;drop=218721"] = {"Jammal'an el Profeta", "El Templo de Atal'Hakkar"}
        s["spell;created=10621"] = {"Yelmo de Cabezalobo", ""}
        s["npc;drop=9816"] = {"Piroguardián brasadivino", "Cumbre de Roca Negra"}
        s["npc;drop=12467"] = {"Capitán Garramortal", "Guarida Alanegra"}
        s["spell;created=23710"] = {"Cinturón de arrabio", ""}
        s["npc;drop=11981"] = {"Flamagor", "Guarida Alanegra"}
        s["npc;drop=6229"] = {"Golpeamasa 9-60", "Gnomeregan"}
        s["npc;drop=15206"] = {"Duque de las Brasas", "Silithus"}
        s["npc;drop=9041"] = {"Guarda Stilgiss", "Profundidades de Roca Negra"}
        s["quest;reward=4261"] = {"El espíritu de un Ancestro", ""}
        s["npc;drop=10440"] = {"Barón Osahendido", "Stratholme"}
        s["quest;reward=5068"] = {"Peto Sed de Sangre", ""}
        s["npc;drop=9019"] = {"Emperador Dagran Thaurissan", "Profundidades de Roca Negra"}
        s["npc;drop=15516"] = {"Guardia de batalla Sartura", "Ahn'Qiraj"}
        s["spell;created=19084"] = {"Guanteletes de devilsaurio", ""}
        s["npc;drop=11361"] = {"Tigre Zulian", "Zul'Gurub"}
        s["npc;drop=15323"] = {"Acecharenas Colmen'Zara", "Ruinas de Ahn'Qiraj"}
        s["spell;created=19097"] = {"Leotardos de devilsaurio", ""}
        s["object;contained=181366"] = {"[Four Horsemen Chest]", "Naxxramas"}
        s["npc;drop=10399"] = {"Acólito Thuzadin", "Stratholme"}
        s["npc;drop=8929"] = {"Princesa Moira Barbabronce <Princesa de Forjaz>", "Profundidades de Roca Negra"}
        s["quest;reward=7981"] = {"1200 vales: amuleto de la Luna Negra", ""}
        s["quest;reward=7862"] = {"Oferta de empleo: capitán de la guardia de Poblado Sañadiente", ""}
        s["npc;drop=9568"] = {"Señor Supremo Vermiothalak", "Cumbre de Roca Negra"}
        s["quest;reward=3321"] = {"¿Has perdido esto?", ""}
        s["npc;sold=12805"] = {"Oficial Areyn <Intendente de accesorios>", "Ciudad de Ventormenta"}
        s["npc;sold=12799"] = {"Sargento Ba'sha <Intendente de accesorios>", "Orgrimmar"}
        s["npc;drop=12463"] = {"Flamascama Garramortal", "Guarida Alanegra"}
        s["quest;reward=7877"] = {"El tesoro de los Shen'dralar", ""}
        s["npc;drop=2748"] = {"Archaedas <Guardapiedras antiguo>", "Uldaman"}
        s["spell;created=23707"] = {"Cinturón de lava", ""}
        s["npc;drop=228022"] = {"[The Destructor's Wraith]", "Barranco del Demonio"}
        s["npc;drop=227140"] = {"[Pyranis]", "Barranco del Demonio"}
        s["spell;created=460462"] = {"Ojo de Sulfuras", ""}
        s["npc;drop=227028"] = {"[Hellscream's Phantom]", "Barranco del Demonio"}
        s["npc;drop=15204"] = {"Alto mariscal Eje Torbellino", "Silithus"}
        s["npc;drop=218624"] = {"Atal'alarion <Guardián del ídolo>", "El Templo de Atal'Hakkar"}
        s["npc;drop=228430"] = {"[Magmadar]", "Núcleo de Magma"}
        s["spell;created=24123"] = {"Brazales primigenios de piel de murciélago", ""}
        s["spell;created=24122"] = {"Guantes primigenios de piel de murciélago", ""}
        s["npc;drop=10422"] = {"Hechicero Carmesí", "Stratholme"}
        s["quest;reward=84561"] = {"[For All To See]", ""}
        s["quest;reward=5944"] = {"En sueños", ""}
        s["quest;reward=8949"] = {"La vendetta de Falrin", ""}
        s["npc;sold=12944"] = {"Lokhtos Tratoscuro <La Hermandad del torio>", ""}
        s["npc;drop=228436"] = {"[Sulfuron Harbinger]", "Núcleo de Magma"}
        s["spell;created=461712"] = {"Martillo de los titanes refinado", ""}
        s["spell;created=16988"] = {"Martillo de los Titanes", ""}
        s["spell;created=461722"] = {"Guanteletes de núcleo demoníaco", ""}
        s["spell;created=461724"] = {"Leotardos de núcleo demoníaco", ""}
        s["quest;reward=84545"] = {"[A Hero's Reward]", ""}
        s["npc;drop=15510"] = {"Fankriss el Implacable", "Ahn'Qiraj"}
        s["npc;drop=10487"] = {"Protector resucitado", "Scholomance"}
        s["npc;drop=15263"] = {"El profeta Skeram", "Ahn'Qiraj"}
        s["npc;drop=16449"] = {"Espíritu de Naxxramas", "Naxxramas"}
        s["npc;drop=12460"] = {"Vermiguardia Garramortal", "Guarida Alanegra"}
        s["npc;drop=10430"] = {"La Bestia", "Cumbre de Roca Negra"}
        s["npc;drop=10500"] = {"Maestro espectral", "Scholomance"}
        s["npc;drop=221407"] = {"Diablillo sombrasueño", "Feralas"}
        s["quest;reward=9120"] = {"La caída de Kel'Thuzad", ""}
        s["spell;created=15596"] = {"Corazón fumeante de la montaña", ""}
        s["quest;reward=7067"] = {"Las instrucciones del Paria", ""}
        s["quest;reward=8573"] = {"Equipamiento de Campeón", ""}
        s["npc;drop=9547"] = {"Patrosuccio", "Profundidades de Roca Negra"}
        s["spell;created=461690"] = {"Capa cambiante magistral", ""}
        s["npc;drop=230302"] = {"[Lord Kazzak]", "Escara Impía"}
        s["spell;created=435904"] = {"Capucha gneurovinculada brillante", ""}
        s["spell;created=23703"] = {"Poder de los Fauces de Madera", ""}
        s["spell;created=19080"] = {"Ropa interior de oso de guerra", ""}
        s["npc;sold=10857"] = {"Intendente Argenta Destelllo de Luz <El Alba Argenta>", "Tierras de la Peste del Oeste"}
        s["spell;created=23705"] = {"Alpargatas del Alba", ""}
        s["npc;sold=13278"] = {"Duque Hydraxis", "Azshara"}
        s["npc;sold=218115"] = {"Mai'zin <Cambiasangre Gurubashi>", "Vega de Tuercespina"}
        s["quest;reward=80324"] = {"El rey loco", ""}
        s["npc;drop=202699"] = {"Barón Aquanis", "Cavernas de Brazanegra"}
        s["npc;drop=8567"] = {"Glotón", "Zahúrda Rojocieno"}
        s["npc;drop=220007"] = {"Radiactivo viscoso", "Gnomeregan"}
        s["npc;sold=217689"] = {"Ziri 'la Manitas' Pequerrueda <Jefa de equipo>", ""}
        s["npc;drop=201722"] = {"Ghamoo-Ra", "Cavernas de Brazanegra"}
        s["npc;drop=220072"] = {"Electrocutor 6000", "Gnomeregan"}
        s["spell;created=429354"] = {"Guantes de cuero tocados por el Vacío", ""}
        s["quest;reward=824"] = {"Je'neu del Anillo de la Tierra", ""}
        s["quest;reward=80132"] = {"Las guerras de la plataforma", ""}
        s["npc;drop=3669"] = {"Lord Cobrahn <Noble del Colmillo>", "Cuevas de los Lamentos"}
        s["npc;drop=215728"] = {"Golpeamasa 9-60", "Gnomeregan"}
        s["npc;drop=218537"] = {"Mekigeniero Termochufe", "Gnomeregan"}
        s["npc;drop=4295"] = {"Myrmidón Escarlata", "Monasterio Escarlata"}
        s["quest;reward=7541"] = {"Un servicio para la Horda", ""}
        s["npc;drop=6489"] = {"Dorsacerado", "Monasterio Escarlata"}
        s["quest;reward=78916"] = {"El corazón del Vacío", ""}
        s["npc;drop=7584"] = {"Caminabosques deambulante", "Feralas"}
        s["npc;drop=4389"] = {"Trillador de la oscuridad", "Marjal Revolcafango"}
        s["npc;drop=2433"] = {"Restos de Helcular", "Laderas de Trabalomas"}
        s["spell;created=6705"] = {"Brazales de escamas de múrloc", ""}
        s["spell;created=3779"] = {"Cinturón primitivo", ""}
        s["npc;drop=4845"] = {"Rufián Forjatiniebla", "Tierras Inhóspitas"}
        s["quest;reward=2767"] = {"¡Escolta a OOX-22/FE!", ""}
        s["quest;reward=793"] = {"Alianzas rotas", ""}
        s["spell;created=435960"] = {"Cinturón dorado hiperconductor", ""}
        s["npc;drop=9033"] = {"General Forjira", "Profundidades de Roca Negra"}
        s["npc;drop=12018"] = {"Mayordomo Executus", "Núcleo de Magma"}
        s["npc;drop=15509"] = {"Princesa Huhuran", "Ahn'Qiraj"}
        s["quest;reward=7506"] = {"El Sueño Esmeralda", ""}
        s["npc;drop=15543"] = {"Princesa Yauj", "Ahn'Qiraj"}
        s["spell;created=22927"] = {"Pellejo de lo salvaje", ""}
        s["npc;drop=11501"] = {"Rey Gordok", "La Masacre"}
        s["npc;drop=10268"] = {"Gizrul el esclavista", "Cumbre de Roca Negra"}
        s["spell;created=22759"] = {"Brazaletes Nucleobengala", ""}
        s["npc;drop=15339"] = {"Osirio el Sinmarcas", "Ruinas de Ahn'Qiraj"}
        s["spell;created=23709"] = {"Cinturón del Can del núcleo", ""}
        s["npc;drop=13020"] = {"Vaelastrasz el Corrupto", "Guarida Alanegra"}
        s["npc;drop=11488"] = {"Illyanna Roblecuervo", "La Masacre"}
        s["npc;drop=9056"] = {"Finoso Virunegro", "Profundidades de Roca Negra"}
        s["npc;drop=14325"] = {"Capitán Kromcrush", "La Masacre"}
        s["npc;drop=10809"] = {"Pidrespina", "Stratholme"}
        s["quest;reward=8791"] = {"La caída de Osirio", ""}
        s["npc;drop=10439"] = {"Ramstein el Empachador", "Stratholme"}
        s["quest;reward=7907"] = {"La baraja de las Bestias de la Luna Negra", ""}
        s["object;contained=169243"] = {"Cofre de los Siete", "Profundidades de Roca Negra"}
        s["npc;drop=14515"] = {"Suma Sacerdotisa Arlokk", "Zul'Gurub"}
        s["npc;drop=16080"] = {"Mor Ruciapezuña", "Cumbre de Roca Negra"}
        s["spell;created=461750"] = {"Aro de tela lunar incandescente", ""}
        s["spell;created=23665"] = {"Hombreras Argenta", ""}
        s["spell;created=446189"] = {"Hombreras de obsesión", ""}
        s["spell;created=19061"] = {"Hombreras vivientes", ""}
        s["spell;created=446194"] = {"Manto de locura", ""}
        s["npc;drop=221394"] = {"Avatar de Hakkar", "El Templo de Atal'Hakkar"}
        s["npc;drop=228431"] = {"[Gehennas]", "Núcleo de Magma"}
        s["npc;drop=9236"] = {"Cazador de las Sombras Vosh'gajin", "Cumbre de Roca Negra"}
        s["spell;created=19435"] = {"Botas de tela lunar", ""}
        s["npc;drop=218571"] = {"Sombra de Eranikus", "El Templo de Atal'Hakkar"}
        s["npc;drop=10506"] = {"Kirtonos el Heraldo", "Scholomance"}
        s["quest;reward=80325"] = {"El rey loco", ""}
        s["quest;reward=82081"] = {"Un ritual fallido", ""}
        s["quest;reward=82058"] = {"La baraja Salvaje de la Luna Negra", ""}
        s["npc;drop=226922"] = {"[Zilbagob]", "Barranco del Demonio"}
        s["npc;drop=3977"] = {"Alta Inquisidora Melenablanca", "Monasterio Escarlata"}
        s["npc;drop=14324"] = {"Cho'Rush el Observador", "La Masacre"}
        s["npc;drop=11661"] = {"Caminallamas", "Núcleo de Magma"}
        s["npc;drop=11673"] = {"Can del Núcleo anciano", "Núcleo de Magma"}
        s["quest;reward=9008"] = {"[Saving the Best for Last]", ""}
        s["quest;reward=4024"] = {"Un sabor a llamarada", ""}
        s["npc;drop=13276"] = {"Diablillo Mala Hierba", "La Masacre"}
        s["npc;drop=9027"] = {"Gorosh el Endemoniado", "Profundidades de Roca Negra"}
        s["npc;drop=10264"] = {"Solakar Corona de Fuego", "Cumbre de Roca Negra"}
        s["quest;reward=8906"] = {"Una propuesta seria", ""}
        s["quest;reward=8938"] = {"Una compensación justa", ""}
        s["npc;drop=11489"] = {"Tendris Madeguerra", "La Masacre"}
        s["npc;drop=9596"] = {"Bannok Hachamacabra <Legión Pirotigma>", "Cumbre de Roca Negra"}
        s["quest;reward=8952"] = {"La despedida de Anthion", ""}
        s["spell;created=22922"] = {"Botas de mangosta", ""}
        s["quest;reward=5125"] = {"La estimación de Aurius", ""}
        s["quest;reward=7503"] = {"La mayor raza de cazadores", ""}
        s["quest;reward=82108"] = {"El dragón verde", ""}
        s["npc;drop=10438"] = {"Maleki el Pálido", "Stratholme"}
        s["npc;drop=221391"] = {"Slirena <Reina de las arpías>", "Feralas"}
        s["npc;drop=15740"] = {"Coloso de Zora", "Silithus"}
        s["spell;created=462623"] = {"Formando Rhok'delar", ""}
        s["quest;reward=82104"] = {"Jammal'an el Profeta", ""}
        s["npc;drop=8908"] = {"Gólem de guerra fundido", "Profundidades de Roca Negra"}
        s["quest;reward=84148"] = {"[An Earnest Proposition]", ""}
        s["spell;created=446237"] = {"Avambrazos de asesino potenciados por el Vacío", ""}
        s["npc;drop=9029"] = {"Eviscerador", "Profundidades de Roca Negra"}
        s["quest;reward=7029"] = {"La corrupción de Lenguavil", ""}
        s["object;contained=179564"] = {"Tributo a Gordok", "La Masacre"}
        s["npc;drop=9445"] = {"Guardia oscuro", "Profundidades de Roca Negra"}
        s["spell;created=23639"] = {"Furianegra", ""}
        s["spell;created=461675"] = {"Segadora de arcanita refinada", ""}
        s["npc;drop=222573"] = {"Anciana delirante", "Zul'Farrak"}
        s["quest;reward=8272"] = {"Héroe de Lobo Gélido", ""}
        s["quest;reward=3636"] = {"Trae la Luz", ""}
        s["quest;reward=1364"] = {"La orden de Mazen", ""}
        s["npc;drop=7603"] = {"Asistente leproso", "Gnomeregan"}
        s["npc;drop=2716"] = {"Cazavermis Rotapolvo", "Tierras Inhóspitas"}
        s["quest;reward=628"] = {"Borceguí", ""}
        s["quest;reward=7068"] = {"Fragmentos Oscuros", ""}
        s["quest;reward=2822"] = {"La marca de la calidad", ""}
        s["npc;drop=5860"] = {"Chamán Oscuro Crepuscular", "La Garganta de Fuego"}
        s["npc;drop=13601"] = {"Manitas Gizlock", "Maraudon"}
        s["quest;reward=1048"] = {"En el Monasterio Escarlata", ""}
        s["spell;created=435953"] = {"Caperuza de escamas resistente a la radiación", ""}
        s["spell;created=18457"] = {"Toga del archimago", ""}
        s["quest;reward=8632"] = {"El aro Enigma", ""}
        s["quest;reward=8625"] = {"Las hombreras Enigma", ""}
        s["quest;reward=8633"] = {"La Toga Enigma", ""}
        s["quest;reward=8634"] = {"Las botas Enigma", ""}
        s["npc;drop=15236"] = {"Avispa Vekniss", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", ""}
        s["quest;reward=84157"] = {"[An Earnest Proposition]", ""}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", ""}
        s["npc;drop=11480"] = {"Aberración Arcana", "La Masacre"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", ""}
        s["npc;drop=10198"] = {"Kashoch el Atracador", "Cuna del Invierno"}
        s["quest;reward=84165"] = {"[Just Compensation]", ""}
        s["spell;created=22868"] = {"Guantes inferno", ""}
        s["quest;reward=82095"] = {"El dios Hakkar", ""}
        s["quest;reward=8932"] = {"Una compensación justa", ""}
        s["npc;drop=9024"] = {"Piromántico Cultugrano", "Profundidades de Roca Negra"}
        s["quest;reward=617"] = {"Tallos de juncos akiris", ""}
        s["npc;drop=6146"] = {"Rompedor del risco", "Azshara"}
        s["spell;created=446236"] = {"Avambrazos de invocador potenciados por el Vacío", ""}
        s["quest;reward=3907"] = {"La discordia de las llamas", ""}
        s["spell;created=23663"] = {"Manto de Fauces de Madera", ""}
        s["npc;drop=4288"] = {"Maestro de bestias Escarlata", "Monasterio Escarlata"}
        s["npc;drop=6487"] = {"Arcanista Doan", "Monasterio Escarlata"}
        s["quest;reward=8366"] = {"Mamporros en el Mar del Sur", ""}
        s["spell;created=16724"] = {"Yelmo Almablanca", ""}
        s["npc;drop=10339"] = {"Gyth", "Cumbre de Roca Negra"}
        s["spell;created=19054"] = {"Peto de escamas de dragón rojo", ""}
        s["npc;drop=14321"] = {"Guardia Fengus", "La Masacre"}
        s["npc;drop=14861"] = {"Ayudante de sangre de Kirtonos", "Scholomance"}
        s["quest;reward=7501"] = {"La Luz y cómo alterarla", ""}
        s["spell;created=446191"] = {"Espaldares aciagos", ""}
        s["spell;created=446190"] = {"Manto de anillas gemebundas", ""}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", ""}
        s["npc;drop=10464"] = {"Alma en pena de los Lamentos", "Stratholme"}
        s["npc;drop=12203"] = {"Derrumblo", "Maraudon"}
        s["spell;created=435906"] = {"Jaula cerebral de veraplata reflectante", ""}
        s["spell;created=435949"] = {"Almófar de escamas hiperconductoras brillante", ""}
        s["spell;created=435610"] = {"Monóculo de filamento Arcano gneurovinculado", ""}
        s["npc;sold=222685"] = {"Intendente Kyleen", "Vallefresno"}
        s["spell;created=20874"] = {"Brazales Hierro Negro", ""}
        s["spell;created=24399"] = {"Botas Hierro Negro", ""}
        s["quest;reward=80131"] = {"Mejora gnómica", ""}
        s["npc;drop=2691"] = {"Avanzado Vallealto", "Tierras del Interior"}
        s["npc;drop=10596"] = {"Madre Telabrasada", "Cumbre de Roca Negra"}
        s["spell;created=461730"] = {"Guardia de Escarcha endurecida", ""}
        s["spell;created=23652"] = {"Guardanegro", ""}
        s["spell;created=461669"] = {"Campeona de arcanita refinada", ""}
        s["spell;created=22797"] = {"Forzar disco reactivo", ""}
        s["npc;drop=3976"] = {"Comandante Escarlata Mograine", "Monasterio Escarlata"}
        s["quest;reward=7065"] = {"Corrupción de la tierra y de la semilla", ""}
        s["spell;created=9952"] = {"Hombreras de mitril ornamentado", ""}
        s["npc;drop=5287"] = {"Aullador Dientelargo", "Feralas"}
        s["npc;drop=1884"] = {"Leñador Escarlata", "Tierras de la Peste del Oeste"}
        s["npc;drop=10418"] = {"Custodio Carmesí", "Stratholme"}
        s["npc;drop=10808"] = {"Timmy el Cruel", "Stratholme"}
        s["spell;created=16729"] = {"Yelmo Corazón de león", ""}
        s["spell;created=435908"] = {"Casco antiinterferencias templado", ""}
        s["spell;created=24141"] = {"Hombreras Almanegra", ""}
        s["npc;drop=7524"] = {"Altonato angustioso", "Cuna del Invierno"}
        s["spell;created=19101"] = {"Hombreras volcánicas", ""}
        s["spell;created=446179"] = {"Hombreras de terror", ""}
        s["quest;reward=5166"] = {"Peto del Vuelo Cromático", ""}
        s["spell;created=19076"] = {"Peto volcánico", ""}
        s["spell;created=24139"] = {"Peto Almanegra", ""}
        s["spell;created=446238"] = {"Avambrazos de protector potenciados por el Vacío", ""}
        s["spell;created=23633"] = {"Guantes del Alba", ""}
        s["spell;created=461671"] = {"Guanteletes de bastión recios", ""}
        s["spell;created=23632"] = {"Faja del Alba", ""}
        s["quest;reward=5081"] = {"La misión de Maxwell", ""}
        s["spell;created=19059"] = {"Leotardos volcánicos", ""}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", ""}
        s["spell;created=461718"] = {"Tranquilidad", ""}
        s["spell;created=21160"] = {"Ojo de Sulfuras", ""}
        s["spell;created=20873"] = {"Hombreras abrasadoras de anillas", ""}
        s["npc;drop=15305"] = {"Lord Skwol", "Silithus"}
        s["spell;created=461651"] = {"Guanteletes de placas ígneas de la técnica oculta", ""}
        s["spell;created=27585"] = {"Cinturón obsidiano pesado", ""}
        s["spell;created=27829"] = {"Leotardos titánicos", ""}
        s["spell;created=20876"] = {"Leotardos Hierro Negro", ""}
        s["quest;reward=8572"] = {"Equipamiento de Veterano", ""}
        s["spell;created=12906"] = {"Pollo de batalla gnomo", ""}
        s["spell;created=460460"] = {"Martillo de Sulfuron", ""}
        s["spell;created=450409"] = {"Llamada de Sul'thraze", ""}
        s["npc;drop=8127"] = {"Antu'sul <Sobrestante de Sul>", "Zul'Farrak"}
        s["quest;reward=84008"] = {"[A Lesson in Grace]", ""}
        s["spell;created=461714"] = {"Profanación", ""}
        s["npc;drop=227019"] = {"[Diathorus the Seeker]", "Barranco del Demonio"}
        s["spell;created=16994"] = {"Segadora de arcanita", ""}
        s["spell;created=23151"] = {"Equilibrio de Luz y Sombras", ""}
        s["npc;drop=14517"] = {"Suma Sacerdotisa Jeklik", "Zul'Gurub"}
        s["npc;drop=15816"] = {"Mayor qiraji He'al-ie", "Las Mil Agujas"}
        s["quest;reward=9009"] = {"[Saving the Best for Last]", ""}
        s["npc;drop=11382"] = {"Señor sangriento Mandokir", "Zul'Gurub"}
        s["spell;created=18456"] = {"Vestimentas de la fe verdadera", ""}
        s["npc;drop=11664"] = {"Élite Caminallamas", "Núcleo de Magma"}
        s["quest;reward=8909"] = {"Una propuesta seria", ""}
        s["quest;reward=8940"] = {"Una compensación justa", ""}
        s["npc;drop=14509"] = {"Sumo Sacerdote Thekal", "Zul'Gurub"}
        s["quest;reward=9019"] = {"La despedida de Anthion", ""}
        s["quest;reward=7504"] = {"Sagrada Bologna: lo que la Luz nunca te dirá", ""}
        s["quest;reward=82111"] = {"Sangre de Morphaz", ""}
        s["npc;drop=12459"] = {"Brujo Alanegra", "Guarida Alanegra"}
        s["object;contained=161495"] = {"Caja fuerte secreta", "Profundidades de Roca Negra"}
        s["spell;created=463008"] = {"Equilibrio de Luz y Sombras", ""}
        s["spell;created=461708"] = {"Toga de tela lunar incandescente", ""}
        s["quest;reward=84151"] = {"[An Earnest Proposition]", ""}
        s["spell;created=461752"] = {"Leotardos de tela lunar incandescente", ""}
        s["quest;reward=55"] = {"Morbent Vil", ""}
        s["npc;drop=4366"] = {"Guardia serpiente Strashaz", "Marjal Revolcafango"}
        s["npc;drop=10423"] = {"Sacerdote Carmesí", "Stratholme"}
        s["npc;drop=9818"] = {"Invocador Puño Negro", "Cumbre de Roca Negra"}
        s["spell;created=446193"] = {"Espaldares de mente fracturada", ""}
        s["npc;drop=9219"] = {"Carnicero Cumbrerroca", "Cumbre de Roca Negra"}
        s["npc;drop=223544"] = {"Intruso vil", "Las Tierras Devastadas"}
        s["quest;reward=9225"] = {"Armamento épico de batalla: venerado en el Alba", ""}
        s["npc;drop=10425"] = {"Mago de batalla Carmesí", "Stratholme"}
        s["npc;drop=10477"] = {"Necromántico de Scholomance", "Scholomance"}
        s["npc;drop=8923"] = {"Panzor el Invencible", "Profundidades de Roca Negra"}
        s["quest;reward=9221"] = {"Armamento superior de batalla: amigo del Alba", ""}
        s["spell;created=18436"] = {"Toga de la noche Invernal", ""}
        s["npc;drop=12457"] = {"Vinculador de hechizos Alanegra", "Guarida Alanegra"}
        s["quest;reward=8592"] = {"La tiara del Oráculo", ""}
        s["quest;reward=8594"] = {"El manto del Oráculo", ""}
        s["spell;created=18453"] = {"Hombreras de tela de inferi", ""}
        s["quest;reward=8603"] = {"Las vestimentas del Oráculo", ""}
        s["npc;drop=15247"] = {"Lavacerebros Qiraji", "Ahn'Qiraj"}
        s["spell;created=22867"] = {"Guatnes de tela de inferi", ""}
        s["spell;created=23041"] = {"Llamar Anatema", ""}
        s["npc;drop=14516"] = {"Caballero de la Muerte Atracoscuro", "Scholomance"}
        s["spell;created=461962"] = {"Llamar Anatema", ""}
        s["npc;drop=1843"] = {"Supervisor Jerris", "Tierras de la Peste del Oeste"}
        s["npc;drop=12801"] = {"Quimerok Arcano", "Feralas"}
        s["npc;drop=228914"] = {"[Severed Keeper]", "Barranco del Demonio"}
        s["npc;drop=16154"] = {"Caballero de la Muerte resucitado", "Naxxramas"}
        s["npc;drop=11469"] = {"Bullidor Eldreth", "La Masacre"}
        s["npc;drop=15975"] = {"Engranasto carroñero", "Naxxramas"}
        s["npc;drop=1838"] = {"Interrogador Escarlata", "Tierras de la Peste del Oeste"}
        s["npc;drop=1851"] = {"La Casca", "Tierras de la Peste del Oeste"}
        s["npc;drop=15757"] = {"Teniente general qiraji", "Silithus"}
        s["npc;drop=15390"] = {"Capitán Xurrem", "Ruinas de Ahn'Qiraj"}
        s["npc;drop=10371"] = {"Capitán Garra de Furia", "Cumbre de Roca Negra"}
        s["npc;drop=7459"] = {"Matriarca Cardo Nevado", "Cuna del Invierno"}
        s["npc;drop=10663"] = {"Zarpamaná", "Cuna del Invierno"}
        s["spell;created=18442"] = {"Capucha de tela de inferi", ""}
        s["npc;drop=11143"] = {"Jefe de correos Gassol", "Stratholme"}
        s["spell;created=19794"] = {"Gafas hechizorosas extremas plus", ""}
        s["npc;drop=11622"] = {"Traquesangre", "Scholomance"}
        s["object;contained=181074"] = {"Botín de la arena", "Profundidades de Roca Negra"}
        s["spell;created=18451"] = {"Toga de tela de inferi", ""}
        s["npc;drop=9817"] = {"Tejedor de tinieblas Puño Negro", "Cumbre de Roca Negra"}
        s["npc;drop=10372"] = {"Lenguáfoga Garra de Furia", "Cumbre de Roca Negra"}
        s["npc;drop=11490"] = {"Zevrim Pezuñahendida", "La Masacre"}
        s["npc;drop=10901"] = {"Tradicionalista Polkelt", "Scholomance"}
        s["spell;created=18454"] = {"Guantes de maestría en hechizos", ""}
        s["spell;created=18419"] = {"Pantalones de tela de inferi", ""}
        s["npc;drop=10436"] = {"Baronesa Anastari", "Stratholme"}
        s["npc;drop=10558"] = {"Escupezones Foreste", "Escupezones Foreste"}
        s["npc;drop=9217"] = {"Señor Magus Cumbrerroca", "Cumbre de Roca Negra"}
        s["npc;drop=6228"] = {"Embajador Hierro Negro", "Gnomeregan"}
        s["npc;drop=6370"] = {"Escarbador Makrinni", "Azshara"}
        s["quest;reward=9004"] = {"Guardar lo mejor para el final", ""}
        s["quest;reward=8956"] = {"La despedida de Anthion", ""}
        s["quest;reward=8910"] = {"Una propuesta seria", ""}
        s["quest;reward=8941"] = {"Una compensación justa", ""}
        s["quest;reward=8639"] = {"El casco de mortífero", ""}
        s["quest;reward=8641"] = {"Las hombreras de mortífero", ""}
        s["quest;reward=8638"] = {"El jubón de mortífero", ""}
        s["quest;reward=8201"] = {"Una colección de cabezas", ""}
        s["npc;drop=9265"] = {"Cazador de las Sombras Espina Ahumada", "Cumbre de Roca Negra"}
        s["quest;reward=8640"] = {"Los leotardos de mortífero", ""}
        s["quest;reward=8637"] = {"Las botas de mortífero", ""}
        s["npc;drop=14507"] = {"Sumo Sacerdote Venoxis", "Zul'Gurub"}
        s["quest;reward=7498"] = {"Garona: un estudio acerca de la discreción y la traición", ""}
        s["quest;reward=7787"] = {"¡Arriba, Trueno Furioso!", ""}
        s["npc;drop=203138"] = {"Sobrestante Yunque Colérico", "Profundidades de Roca Negra"}
        s["spell;created=461237"] = {"Cráneo de Pirosombra", ""}
        s["spell;created=19090"] = {"Hombreras velotormenta", ""}
        s["spell;created=19079"] = {"Armadura velotormenta", ""}
        s["quest;reward=84152"] = {"[An Earnest Proposition]", ""}
        s["spell;created=26279"] = {"Guantes velotormenta", ""}
        s["npc;drop=10318"] = {"Asesino Puño Negro", "Cumbre de Roca Negra"}
        s["spell;created=19067"] = {"Pantalones velotormenta", ""}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", ""}
        s["npc;drop=15741"] = {"Coloso de Regal", "Silithus"}
        s["quest;reward=53"] = {"Dulce ámbar", ""}
        s["npc;drop=2601"] = {"Panzatroz", "Tierras Altas de Arathi"}
        s["npc;drop=2751"] = {"Gólem de guerra", "Tierras Inhóspitas"}
        s["spell;created=9201"] = {"Brazales oscuros", ""}
        s["quest;reward=80455"] = {"[Biding Our Time]", ""}
        s["npc;drop=15209"] = {"Templario Carmesí", "Silithus"}
        s["spell;created=23706"] = {"Manto dorado del Alba", ""}
        s["spell;created=19068"] = {"Arnés de oso de guerra", ""}
        s["npc;drop=9237"] = {"Maestro de guerra Voone", "Cumbre de Roca Negra"}
        s["npc;drop=15817"] = {"General de brigada qiraji Pax-lish", "Silithus"}
        s["quest;reward=8623"] = {"La diadema de clamatormentas", ""}
        s["quest;reward=9011"] = {"[Saving the Best for Last]", ""}
        s["quest;reward=7668"] = {"La amenaza de Atracoscuro", ""}
        s["quest;reward=8602"] = {"Los espaldares de clamatormentas", ""}
        s["spell;created=16650"] = {"Malla espinavestre", ""}
        s["quest;reward=8622"] = {"El camisote de clamatormentas", ""}
        s["quest;reward=8918"] = {"Una propuesta seria", ""}
        s["npc;drop=14454"] = {"El Atracavientos", "Silithus"}
        s["quest;reward=8621"] = {"Las botas de clamatormentas", ""}
        s["npc;drop=11462"] = {"Antárbol Combadera", "La Masacre"}
        s["quest;reward=7505"] = {"El choque de Escarcha y tú", ""}
        s["quest;reward=82113"] = {"El vudú", ""}
        s["spell;created=461735"] = {"Malla invencible", ""}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", ""}
        s["npc;drop=11043"] = {"Monje Carmesí", "Stratholme"}
        s["spell;created=461737"] = {"Guanteletes de tempestad", ""}
        s["npc;drop=10083"] = {"Flamascala Garra de Furia", "Cumbre de Roca Negra"}
        s["npc;drop=10814"] = {"Guardia de élite cromático", "Cumbre de Roca Negra"}
        s["npc;drop=14323"] = {"Guardia Slip'kik", "La Masacre"}
        s["spell;created=446186"] = {"Guardahombros de anillas cacofónicas", ""}
        s["spell;created=451706"] = {"Espaldares de anillas aulladoras", ""}
        s["npc;drop=9028"] = {"Grisez", "Profundidades de Roca Negra"}
        s["spell;created=24138"] = {"Guanteletes Almasangre", ""}
        s["npc;drop=224257"] = {"Esclavo Atal'ai", "El Templo de Atal'Hakkar"}
        s["spell;created=435958"] = {"Bastión de veraplata giratorio", ""}
        s["spell;created=19094"] = {"Hombreras negras de escamas de dragón", ""}
        s["spell;created=23708"] = {"Guanteletes cromáticos", ""}
        s["spell;created=19107"] = {"Leotardos negros de escamas de dragón", ""}
        s["spell;created=20855"] = {"Botas negras de escama de dragón", ""}
        s["spell;created=23653"] = {"Ocaso", ""}
        s["npc;drop=6117"] = {"Exanimato Altonato", "Azshara"}
        s["spell;created=19085"] = {"Peto negro de escamas de dragón", ""}
        s["npc;drop=10507"] = {"El Devorador", "Scholomance"}
        s["spell;created=16991"] = {"Aniquilador", ""}
        s["npc;drop=12258"] = {"Lativaja", "Maraudon"}
        s["npc;drop=7358"] = {"Amnennar el Gélido", "Zahúrda Rojocieno"}
        s["quest;reward=79366"] = {"La calma que precede a la tormenta", ""}
        s["npc;drop=13596"] = {"Escamapodrida", "Maraudon"}
        s["quest;reward=8624"] = {"Los leotardos de clamatormentas", ""}
        s["quest;reward=7488"] = {"La Membrana de Lethtendris", ""}
        s["quest;reward=5526"] = {"Fragmentos de gangrevid", ""}
        s["spell;created=8770"] = {"Toga de poder", ""}
        s["npc;drop=7357"] = {"Mordresh Ojo de Fuego", "Zahúrda Rojocieno"}
        s["spell;created=24356"] = {"Gafas vid de sangre", ""}
        s["quest;reward=8662"] = {"El aro de clamacondenas", ""}
        s["quest;reward=9005"] = {"Guardar lo mejor para el final", ""}
        s["quest;reward=8664"] = {"El manto de clamacondenas", ""}
        s["quest;reward=8661"] = {"La toga de clamacondenas", ""}
        s["spell;created=18458"] = {"Toga del vacío", ""}
        s["quest;reward=8936"] = {"Una compensación justa", ""}
        s["quest;reward=8381"] = {"Armamentos de guerra", ""}
        s["spell;created=24201"] = {"Crear Runa del Alba", ""}
        s["quest;reward=7502"] = {"Controlar las Sombras", ""}
        s["item:contained=224851"] = {"Un tesoro de otro mundo", ""}
        s["spell;created=461747"] = {"Jubón de tela lunar incandescente", ""}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", ""}
        s["spell;created=23662"] = {"Sabiduría de los Fauces de Madera", ""}
        s["spell;created=462282"] = {"Cinturón bordado del archimago", ""}
        s["npc;drop=15220"] = {"Duque de los Céfiros", "Silithus"}
        s["spell;created=429351"] = {"Botas de seda de araña extrabidimensional", ""}
        s["npc;drop=15203"] = {"Príncipe Skaldrenox", "Silithus"}
        s["spell;created=19830"] = {"Dragonizo de arcanita", ""}
        s["spell;created=461743"] = {"Hoja sabia del archimago", ""}
        s["item:contained=223150"] = {"Un tesoro de otro mundo", ""}
        s["spell;created=20848"] = {"Manto Nucleobengala", ""}
        s["npc;drop=10376"] = {"Colmillor de cristal", "Cumbre de Roca Negra"}
        s["spell;created=446195"] = {"Hombreras del trastornado", ""}
        s["spell;created=22870"] = {"Capa de custodia", ""}
        s["npc;drop=9439"] = {"Guarda oscuro Uggel", "Profundidades de Roca Negra"}
        s["spell;created=19093"] = {"Capa de escamas de Onyxia", ""}
        s["spell;created=20849"] = {"Guantes Nucleobengala", ""}
        s["quest;reward=84411"] = {"[Diplomat Ring]", ""}
        s["quest;reward=5942"] = {"Tesoros ocultos", ""}
        s["quest;reward=1560"] = {"La misión de Tooga", ""}
        s["npc;drop=15208"] = {"Duque de las Esquirlas", "Silithus"}
        s["spell;created=23666"] = {"Toga Nucleobengala", ""}
        s["quest;reward=80141"] = {"Nogg mejora el anillo", ""}
        s["quest;reward=82107"] = {"Plumas vudú", ""}
        s["npc;drop=8762"] = {"Ermitaña Telamadera", "Azshara"}
        s["quest;reward=3129"] = {"Armas del espíritu", ""}
        s["quest;reward=84162"] = {"[An Earnest Proposition]", ""}
        s["quest;reward=9006"] = {"Guardar lo mejor para el final", ""}
        s["quest;reward=8561"] = {"La corona de conquistador", ""}
        s["quest;reward=8544"] = {"Las hombreras de conquistador", ""}
        s["quest;reward=8562"] = {"El peto de conquistador", ""}
        s["quest;reward=8937"] = {"Una compensación justa", ""}
        s["quest;reward=8560"] = {"Los leotardos de conquistador", ""}
        s["quest;reward=8559"] = {"Las grebas de conquistador", ""}
        s["quest;reward=9022"] = {"La despedida de Anthion", ""}
        s["quest;reward=8789"] = {"Armamentos imperiales Qiraji", ""}
        s["spell;created=9954"] = {"Guanteletes de veraplata", ""}
        s["quest;reward=3566"] = {"¡Arriba, Obsidion!", ""}
        s["quest;reward=84550"] = {"[Codex of Defense]", ""}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", ""}
        s["spell;created=452433"] = {"Invocar a Gla'sir", ""}
        s["npc;drop=231494"] = {"[Prince Thunderaan] <[The Wind Seeker]>", "Vega de Cristal"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", ""}
        s["spell;created=452434"] = {"Invocar a Rae'lar", ""}
        s["npc;drop=14510"] = {"Suma Sacerdotisa Mar'li", "Zul'Gurub"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "Barranco del Demonio"}
        s["spell;created=461710"] = {"Rifle de tirador certero de núcleo ígneo", ""}
        s["spell;created=466117"] = {"Armonizar bastón de helada", ""}
        s["spell;created=465417"] = {"Cambiar actitud", ""}
        s["quest;reward=85443"] = {"[Rise, Thunderfury!]", ""}
        s["spell;created=465418"] = {"Cambiar actitud", ""}
        s["npc;drop=227939"] = {"[The Molten Core]", "Núcleo de Magma"}
        s["quest;reward=85480"] = {"[Procrastimond's Gratitude]", ""}
        s["spell;created=469201"] = {"Prender llamas", ""}
        s["spell;created=468840"] = {"Combinar guadaña del caos", ""}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Guarida Alanegra"}
        s["quest;reward=85454"] = {"[A Just Reward]", ""}
        s["spell;created=467790"] = {"Combinar bastón de orden", ""}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", ""}
        s["npc;drop=15369"] = {"Ayamiss el Cazador", "Ruinas de Ahn'Qiraj"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "Silithus"}
        s["spell;created=1216020"] = {"Ídolo de cólera sideral", "CRAFTING"}
        s["spell;created=1213538"] = {"Capa de seda Qiraji", "CRAFTING"}
        s["npc;drop=15370"] = {"Buru el Manducador", "Ruinas de Ahn'Qiraj"}
        s["npc;drop=235197"] = {"[Taerar]", "Vallefresno"}
        s["npc;sold=15192"] = {"Anacronos", "Tanaris"}
        s["spell;created=1213595"] = {"Lágrima del soñador", "CRAFTING"}
        s["spell;created=1213502"] = {"Martillo de tormenta de obsidiana", "CRAFTING"}
        s["npc;sold=15500"] = {"Keyl Patacerce", "Silithus"}
        s["spell;created=1216340"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1216022"] = {"Ídolo de ferocidad felina", "CRAFTING"}
        s["npc;drop=228230"] = {"[Harrigen] <[The Undermarket]>", "Las Estepas Ardientes"}
        s["spell;created=1213536"] = {"Manteo de seda Qiraji", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "Silithus"}
        s["spell;created=23704"] = {"Camorrista Fauces de Madera", "CRAFTING"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "Silithus"}
        s["spell;created=1213593"] = {"Piedraveloz", "CRAFTING"}
        s["spell;created=1216385"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213500"] = {"Destructora de obsidiana", "CRAFTING"}
        s["spell;created=1216024"] = {"Ídolo de poder osuno", "CRAFTING"}
        s["spell;created=24121"] = {"Chaleco primigenio de piel de murciélago", "CRAFTING"}
        s["spell;created=1213738"] = {"Yelmo zarzal", "CRAFTING"}
        s["spell;created=1213736"] = {"Botas zarzal", "CRAFTING"}
        s["spell;created=1213598"] = {"Magnetita de la represalia", "CRAFTING"}
        s["spell;created=1216366"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213521"] = {"Capucha de filozarza", "CRAFTING"}
        s["spell;created=1213525"] = {"Cuero de filozarza", "CRAFTING"}
        s["spell;created=1213523"] = {"Hombreras de filozarza", "CRAFTING"}
        s["spell;created=1213603"] = {"Broche incrustado de rubíes", "CRAFTING"}
        s["spell;created=1216319"] = {"Tocado por el Vacío", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "Silithus"}
        s["spell;created=1213635"] = {"Seta encantada", "CRAFTING"}
        s["spell;created=1213540"] = {"Mantón de seda Qiraji", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "Tierras del Interior"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "Silithus"}
        s["quest;reward=86674"] = {"[The Perfect Poison]", "Silithus"}
        s["spell;created=1216365"] = {"Tocado por el Vacío", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Cráter de Un'Goro"}
        s["spell;created=24137"] = {"Hombreras Almasangre", "CRAFTING"}
        s["spell;created=1216384"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1216387"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1216327"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=466116"] = {"Armonizar bastón infernal", "CRAFTING"}
        s["spell;created=1213628"] = {"Libro de plegarias encantado", "CRAFTING"}
        s["quest;reward=86672"] = {"[Imperial Qiraji Armaments]", "Guarida Alanegra"}
        s["spell;created=1216005"] = {"Tratado sobre Rectitud", "CRAFTING"}
        s["spell;created=1213481"] = {"Jaula de cabeza de zarzapúa", "CRAFTING"}
        s["spell;created=1213484"] = {"Hombreras de zarzapúa", "CRAFTING"}
        s["spell;created=1214884"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213588"] = {"Disco reactivo de potencia afinado", "CRAFTING"}
        s["spell;created=1214270"] = {"Escudo dentado de obsidiana", "CRAFTING"}
        s["spell;created=1213490"] = {"Placa de batalla de zarzapúa", "CRAFTING"}
        s["spell;created=1213506"] = {"Defensora de obsidiana", "CRAFTING"}
        s["spell;created=1216379"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1216007"] = {"Tratado del exorcista", "CRAFTING"}
        s["spell;created=1216382"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213534"] = {"Bufanda de seda Qiraji", "CRAFTING"}
        s["spell;created=1216375"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213492"] = {"Atracadora de obsidiana", "CRAFTING"}
        s["spell;created=1216377"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213498"] = {"Campeón de obsidiana", "CRAFTING"}
        s["quest;reward=86671"] = {"[Imperial Qiraji Regalia]", "Guarida Alanegra"}
        s["npc;drop=234880"] = {"[Emeriss]", "Bosque del Ocaso"}
        s["spell;created=1216354"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1216014"] = {"Tótem de trueno piroclástico", "CRAFTING"}
        s["spell;created=1213742"] = {"Corona nemorosa", "CRAFTING"}
        s["spell;created=1213740"] = {"Hombreras nemorosas", "CRAFTING"}
        s["spell;created=28210"] = {"Abrazo de Gaea", "CRAFTING"}
        s["spell;created=1213744"] = {"Jubón nemoroso", "CRAFTING"}
        s["spell;created=1214306"] = {"Brazales de escamas oníricas", "CRAFTING"}
        s["spell;created=1214307"] = {"Mitones de escamas oníricas", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "Feralas"}
        s["quest;reward=9248"] = {"Una humilde ofrenda", "Silithus"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "Guarida Alanegra"}
        s["spell;created=1213532"] = {"Toga vampírica", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "Guarida Alanegra"}
        s["spell;created=1216372"] = {"Tocado por el Vacío", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "Silithus"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"[Darkmoon Beast Deck]", "Bosque de Elwynn"}
        s["quest;reward=86762"] = {"[Darkmoon Elementals Deck]", "Bosque de Elwynn"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Claro de la Luna"}
        s["spell;created=1214303"] = {"Falda de escamas oníricas", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "Cuna del Invierno"}
        s["npc;drop=3975"] = {"Herod <El Campeón Escarlata>", "Monasterio Escarlata"}
        s["spell;created=1216364"] = {"Tocado por el Vacío", "CRAFTING"}
        s["spell;created=1213633"] = {"Tótem encantado", "CRAFTING"}
        s["spell;created=1216381"] = {"Tocado por el Vacío", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne", "Tierras de la Peste del Este"}
        s["quest;reward=87360"] = {"[The Fall of Kel'Thuzad]", "Tierras de la Peste del Este"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "Criptas de Karazhan"}
        s["npc;drop=16143"] = {"Sombra del Apocalipsis", "Las Tierras Devastadas"}
        s["npc;drop=16380"] = {"Bruja Osaria", "Las Estepas Ardientes"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "Tierras de la Peste del Este"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Tierras de la Peste del Este"}
        s["npc;drop=16060"] = {"Gothik el Cosechador", "Naxxramas"}
        s["npc;drop=15936"] = {"Heigan el Impuro", "Naxxramas"}
        s["npc;drop=14697"] = {"Horror pesado", "Las Estepas Ardientes"}
        s["npc;drop=237439"] = {"[Kharon]", "Criptas de Karazhan"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "Tierras de la Peste del Este"}
        s["npc;drop=15953"] = {"Gran Viuda Faerlina", "Naxxramas"}
        s["npc;drop=15954"] = {"Noth el Pesteador", "Naxxramas"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "Criptas de Karazhan"}
        s["spell;created=1223762"] = {"Capa glacial", "CRAFTING"}
        s["npc;drop=16028"] = {"Remendejo", "Naxxramas"}
        s["npc;drop=238055"] = {"[Dark Rider]", "Criptas de Karazhan"}
        s["npc;drop=238560"] = {"[The Warden]", "Criptas de Karazhan"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "Criptas de Karazhan"}
        s["spell;created=24179"] = {"Crear Sello del Amanecer", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "Tierras de la Peste del Este"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "Criptas de Karazhan"}
        s["npc;drop=16379"] = {"Espíritu de los Malditos", "Las Estepas Ardientes"}
        s["npc;sold=16132"] = {"Cazador Leopold", "Tierras de la Peste del Este"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "Tierras de la Peste del Este"}
        s["npc;sold=16116"] = {"Archimaga Ángela Dosantos", "Tierras de la Peste del Este"}
        s["npc;sold=16115"] = {"Comandante Eligor Albar", "Tierras de la Peste del Este"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "Tierras de la Peste del Este"}
        s["spell;created=1223787"] = {"Coraza Deliriohelado", "CRAFTING"}
        s["spell;created=1223791"] = {"Brazales Deliriohelado", "CRAFTING"}
        s["spell;created=1223789"] = {"Guanteletes Deliriohelado", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Tierras de la Peste del Este"}
        s["spell;created=1223780"] = {"Guerrera polar", "CRAFTING"}
        s["spell;created=1223784"] = {"Brazales polares", "CRAFTING"}
        s["spell;created=1223782"] = {"Guantes polares", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "Tanaris"}
        s["npc;sold=16113"] = {"Padre Íñigo Montoya", "Tierras de la Peste del Este"}
        s["spell;created=1223760"] = {"Jubón glacial", "CRAFTING"}
        s["spell;created=1223764"] = {"Guantes glaciales", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan el Asesino", "Tierras de la Peste del Este"}
        s["spell;created=1214137"] = {"Buscacorazones de obsidiana", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Rompeterra", "Tierras de la Peste del Este"}
        s["npc;drop=238678"] = {"Pok'o Kmun <La Pena Alada>", "Criptas de Karazhan"}
        s["spell;created=1223766"] = {"Muñequeras glaciales", "CRAFTING"}
        s["spell;created=1223772"] = {"Muñequeras escarchadas", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus el Colérico", "Tierras de la Peste del Este"}
        s["spell;created=1213504"] = {"Hoja sabia de obsidiana", "CRAFTING"}
        s["spell;created=1213527"] = {"Capucha vampírica", "CRAFTING"}
        s["spell;created=1213530"] = {"Chal vampírico", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax, Campeón de la Luz", "Tierras de la Peste del Este"}
        s["spell;created=1214145"] = {"Escopeta de obsidiana", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Tierras de la Peste del Este"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
    end

    function SpecBisTooltip:TranslationfrFR()
        s["npc;drop=12435"] = {"Tranchetripe l'Indompté", "Repaire de l'Aile noire"}
        s["spell;created=24091"] = {"Gilet en vignesang", ""}
        s["npc;drop=12017"] = {"Seigneur des couvées Lashlayer", "Repaire de l'Aile noire"}
        s["npc;drop=11380"] = {"Jin'do le Maléficieur", "Zul'Gurub"}
        s["npc;drop=11983"] = {"Gueule-de-feu", "Repaire de l'Aile noire"}
        s["spell;created=24092"] = {"Jambières en vignesang", ""}
        s["spell;created=24093"] = {"Bottes en vignesang", ""}
        s["npc;drop=12098"] = {"Messager de Sulfuron", "Cœur du Magma"}
        s["npc;drop=14601"] = {"Rochébène", "Repaire de l'Aile noire"}
        s["quest;reward=8183"] = {"Le cœur d'Hakkar", ""}
        s["npc;sold=13217"] = {"Thanthaldis Snowgleam <Officier de ravitaillement Stormpike>", "Montagnes d'Alterac"}
        s["npc;drop=10363"] = {"Général Drakkisath", "Pic Blackrock"}
        s["npc;drop=10435"] = {"Magistrat Barthilas", "Stratholme"}
        s["spell;created=12622"] = {"Lentille verte", ""}
        s["spell;created=12092"] = {"Diadème en tisse-rêve", ""}
        s["npc;drop=11261"] = {"Docteur Theolen Krastinov <Le Boucher>", "Scholomance"}
        s["npc;sold=12777"] = {"Capitaine Dirgehammer <Intendant des armures>", "Bassin d'Arathi"}
        s["npc;sold=12792"] = {"Dame Palanseer <Intendant des armures>", "Bassin d'Arathi"}
        s["npc;drop=9018"] = {"Grand Interrogateur Gerstahn <Inquisiteur du Marteau du crépuscule>", "Profondeurs de Blackrock"}
        s["npc;drop=14353"] = {"Mizzle l'Ingénieux", "Hache-tripes"}
        s["npc;drop=10811"] = {"Archiviste Galford", "Stratholme"}
        s["npc;drop=9319"] = {"Maître-chien Grebmar", "Profondeurs de Blackrock"}
        s["npc;drop=11487"] = {"Magistère Kalendris", "Hache-tripes"}
        s["npc;sold=13218"] = {"Grunnda Wolfheart <Officier de ravitaillement Frostwolf>", "Vallée d'Alterac"}
        s["quest;reward=7861"] = {"On recherche : la vile prêtresse Maléficia et ses sbires", ""}
        s["npc;drop=15815"] = {"Capitaine qiraji Ka'rak", "Mille pointes (Thousand Needles)"}
        s["npc;drop=10508"] = {"Ras Murmegivre", "Scholomance"}
        s["npc;sold=14753"] = {"Illiyana Moonblaze <Officier de ravitaillement d'Aile-argent>", "Ashenvale"}
        s["quest;reward=8574"] = {"Equipement de guerre de fidèle", ""}
        s["npc;drop=9017"] = {"Seigneur Incendius", "Profondeurs de Blackrock"}
        s["npc;drop=10516"] = {"Le Condamné", "Stratholme"}
        s["npc;drop=14326"] = {"Garde Mol'dar", "Hache-tripes"}
        s["npc;drop=11662"] = {"Prêtre Attise-flammes", "Cœur du Magma"}
        s["npc;drop=12397"] = {"Seigneur Kazzak", "Terres foudroyées (Blasted Lands)"}
        s["npc;drop=10584"] = {"Urok Hurleruine", "Pic Blackrock"}
        s["npc;drop=9736"] = {"Intendant Zigris <Légion Bloodaxe>", "Pic Blackrock"}
        s["quest;reward=8464"] = {"Les Tombe-hiver s'agitent", ""}
        s["spell;created=12067"] = {"Gants en tisse-rêve", ""}
        s["npc;drop=9030"] = {"Ok'thor le Briseur", "Profondeurs de Blackrock"}
        s["npc;sold=13219"] = {"Jekyll Flandring <Officier de ravitaillement Frostwolf>", "Montagnes d'Alterac"}
        s["spell;created=3864"] = {"Ceinture de l'étoile", ""}
        s["npc;drop=12119"] = {"Protecteur Attise-flammes", "Cœur du Magma"}
        s["npc;drop=9196"] = {"Généralissime Omokk", "Pic Blackrock"}
        s["spell;created=23667"] = {"Jambières Coeur-de-braise", ""}
        s["npc;drop=7267"] = {"Chef Ukorz Scalpessable", "Zul'Farrak"}
        s["npc;drop=8983"] = {"Seigneur golem Argelmach", "Profondeurs de Blackrock"}
        s["npc;drop=15276"] = {"Empereur Vek'lor", "Ahn'Qiraj"}
        s["npc;drop=13280"] = {"Hydrogénos", "Hache-tripes"}
        s["npc;drop=10429"] = {"Chef de guerre Rend Blackhand", "Pic Blackrock"}
        s["npc;drop=10997"] = {"Maître canonnier Willey", "Stratholme"}
        s["npc;drop=10812"] = {"Grand croisé Dathrohan", "Stratholme"}
        s["npc;drop=15275"] = {"Empereur Vek'nilash", "Ahn'Qiraj"}
        s["npc;drop=15742"] = {"Colosse d'Ashi", "Silithus"}
        s["npc;drop=16042"] = {"Seigneur Valthalak", "Pic Blackrock"}
        s["quest;reward=8802"] = {"Le sauveur de Kalimdor", ""}
        s["quest;reward=4363"] = {"La surprise de la Princesse", ""}
        s["quest;reward=4004"] = {"La Princesse sauvée ?", ""}
        s["quest;reward=7491"] = {"Pour que tous voient", ""}
        s["npc;sold=14754"] = {"Kelm Hargunth <Officier de ravitaillement Warsong>", "Les Tarides (the Barrens)"}
        s["npc;drop=10509"] = {"Jed Runewatcher <Légion Blackhand>", "Pic Blackrock"}
        s["quest;reward=5102"] = {"La reddition du général Drakkisath", ""}
        s["npc;drop=9156"] = {"Ambassadeur Cinglefouet", "Profondeurs de Blackrock"}
        s["npc;sold=12782"] = {"Capitaine O'Neal <Intendant des armes>", "Bassin d'Arathi"}
        s["npc;sold=14581"] = {"Sergent Thunderhorn <Intendant des armes>", "Bassin d'Arathi"}
        s["npc;sold=15126"] = {"Rutherford Twing <Officier de ravitaillement des Profanateurs>", "Hautes-terres d'Arathi"}
        s["npc;sold=15127"] = {"Samuel Hawke <Officier de ravitallement, Ligue d'Arathor>", "Hautes-terres d'Arathi"}
        s["npc;drop=1853"] = {"Sombre Maître Gandling", "Scholomance"}
        s["npc;drop=10899"] = {"Goraluk Anvilcrack <Fabricant d'armures de la légion Blackhand>", "Pic Blackrock"}
        s["npc;drop=11492"] = {"Alzzin le Modeleur", "Hache-tripes"}
        s["quest;reward=8790"] = {"L'équipement impérial qiraji", ""}
        s["npc;drop=11988"] = {"Golemagg l'Incinérateur", "Cœur du Magma"}
        s["npc;drop=2585"] = {"Redresseur de torts de Stromgarde", "Hautes-terres d'Arathi"}
        s["quest;reward=82112"] = {"Un meilleur ingrédient", ""}
        s["npc;drop=7271"] = {"Sorcier-docteur Zum'rah", "Zul'Farrak"}
        s["npc;drop=8440"] = {"Ombre d'Hakkar", "Le temple d'Atal'Hakkar"}
        s["npc;drop=5721"] = {"Fauche-rêve", "Le temple d'Atal'Hakkar"}
        s["object;contained=181083"] = {"Possessions de Sothos et Jarien", "Stratholme"}
        s["quest;reward=7784"] = {"Le seigneur de Blackrock", ""}
        s["quest;reward=3962"] = {"C'est dangereux d'y aller seul", ""}
        s["npc;drop=4543"] = {"Mage de sang Thalnos", "Monastère écarlate"}
        s["npc;sold=227819"] = {"Duc Hydraxis", ""}
        s["npc;drop=228435"] = {"Golemagg l'Incinérateur", "Cœur du Magma"}
        s["npc;sold=227853"] = {"Pix Xizzix <Marchande de Terremine>", "Vallée de Strangleronce (Stranglethorn Vale)"}
        s["spell;created=446192"] = {"Membrane de sombre névrose", ""}
        s["npc;drop=15205"] = {"Baron Kazum", "Silithus"}
        s["spell;created=461653"] = {"Cape chromatique brillante", ""}
        s["item:contained=20601"] = {"Besace de butin", ""}
        s["npc;sold=222413"] = {"Zalgo l'Explorateur <Pourvoyeur de marchandises perdues>", "Vallée de Strangleronce (Stranglethorn Vale)"}
        s["quest;reward=84147"] = {"Une proposition sérieuse", ""}
        s["npc;drop=218819"] = {"Pourriture gélatineuse purulente", "Le temple d'Atal'Hakkar"}
        s["spell;created=429869"] = {"Gantelets en cuir touché par le Vide", ""}
        s["npc;drop=220833"] = {"Fauche-rêve", "Le temple d'Atal'Hakkar"}
        s["npc;sold=222408"] = {"Emissaire crocs-d'ombre", "Gangrebois (Felwood)"}
        s["spell;created=461754"] = {"Ceinturon de clairvoyance des arcanes", ""}
        s["object;contained=179703"] = {"Cachette du Seigneur du feu", "Cœur du Magma"}
        s["npc;drop=226923"] = {"Tristeracine <Le garde endeuillé>", "Canyon de la Malechute"}
        s["npc;drop=12201"] = {"Princesse Theradras", "Maraudon"}
        s["spell;created=461647"] = {"Marteau-tempête ouvragé de vol dynamique", ""}
        s["npc;drop=4542"] = {"Grand Inquisiteur Fairbanks", "Monastère écarlate"}
        s["npc;drop=204068"] = {"Dame Sarevess", "Profondeurs de Brassenoire"}
        s["spell;created=12060"] = {"Pantalon rouge en tisse-mage", ""}
        s["spell;created=439105"] = {"Masque du grand vaudou", ""}
        s["npc;drop=6490"] = {"Azshir le Sans-sommeil", "Monastère écarlate"}
        s["spell;created=439093"] = {"Épaulières cramoisies en soie", ""}
        s["quest;reward=82055"] = {"Suite de Dunes de Sombrelune", ""}
        s["quest;reward=82057"] = {"Suite de Pestes de Sombrelune", ""}
        s["npc;drop=221637"] = {"Balafreur", "Le temple d'Atal'Hakkar"}
        s["quest;reward=7940"] = {"1200 bons - Orbe de la Sombrelune", ""}
        s["npc;drop=218721"] = {"Jammal'an le prophète", "Le temple d'Atal'Hakkar"}
        s["spell;created=10621"] = {"Casque tête-de-loup", ""}
        s["npc;drop=9816"] = {"Pyrogarde Prophète ardent", "Pic Blackrock"}
        s["npc;drop=12467"] = {"Capitaine Griffemort", "Repaire de l'Aile noire"}
        s["spell;created=23710"] = {"Ceinture de la fournaise", ""}
        s["npc;drop=6229"] = {"Faucheur de foule 9-60", "Gnomeregan"}
        s["npc;drop=15206"] = {"Le duc des Cendres <Conseil abyssal>", "Silithus"}
        s["npc;drop=9041"] = {"Gardien Stilgiss", "Profondeurs de Blackrock"}
        s["quest;reward=4261"] = {"Esprit d'un ancien", ""}
        s["npc;drop=15511"] = {"Seigneur Kri", "Ahn'Qiraj"}
        s["quest;reward=5068"] = {"La cuirasse carnassière", ""}
        s["npc;drop=9019"] = {"Empereur Dagran Thaurissan", "Profondeurs de Blackrock"}
        s["npc;drop=15516"] = {"Garde de guerre Sartura", "Ahn'Qiraj"}
        s["spell;created=19084"] = {"Gantelets diablosaures", ""}
        s["npc;drop=11361"] = {"Tigre zulien", "Zul'Gurub"}
        s["npc;drop=15323"] = {"Traqueur des sables de la Ruche'Zara", "Ruines d'Ahn'Qiraj"}
        s["spell;created=19097"] = {"Jambières diablosaures", ""}
        s["object;contained=181366"] = {"Coffre des quatre cavaliers", "Naxxramas"}
        s["npc;drop=10399"] = {"Acolyte Thuzadin", "Stratholme"}
        s["npc;drop=8929"] = {"Princesse Moira Bronzebeard <Princesse d'Ironforge>", "Profondeurs de Blackrock"}
        s["quest;reward=7981"] = {"1200 bons - Amulette de la Sombrelune", ""}
        s["quest;reward=7862"] = {"Offre d’emploi : capitaine de la garde du village des Revantusk", ""}
        s["npc;drop=9568"] = {"Seigneur Wyrmthalak", "Pic Blackrock"}
        s["quest;reward=3321"] = {"Est-ce que ceci est à vous ?", ""}
        s["npc;sold=12805"] = {"Officier Areyn <Intendant des accessoires>", "Cité de Stormwind"}
        s["npc;sold=12799"] = {"Sergent Ba'sha <Intendante des accessoires>", "Orgrimmar"}
        s["npc;drop=12463"] = {"Flammécaille Griffemort", "Repaire de l'Aile noire"}
        s["quest;reward=7877"] = {"Le trésor des Shen'dralar", ""}
        s["npc;drop=9025"] = {"Seigneur Roccor", "Profondeurs de Blackrock"}
        s["npc;drop=2748"] = {"Archaedas <Ancien gardien des pierres>", "Uldaman"}
        s["spell;created=23707"] = {"Ceinture de lave", ""}
        s["npc;drop=228022"] = {"Ame en peine du Destructeur", "Canyon de la Malechute"}
        s["spell;created=460462"] = {"Œil de Sulfuras", ""}
        s["npc;drop=227028"] = {"Fantôme de Hurlenfer", "Canyon de la Malechute"}
        s["npc;drop=15204"] = {"Haut maréchal Trombe", "Silithus"}
        s["npc;drop=218624"] = {"Atal'alarion <Gardien de l'idole>", "Le temple d'Atal'Hakkar"}
        s["spell;created=24123"] = {"Brassards en peau de chauve-souris primordiale", ""}
        s["spell;created=24122"] = {"Gants en peau de chauve-souris primordiale", ""}
        s["npc;drop=10422"] = {"Ensorceleur cramoisi", "Stratholme"}
        s["quest;reward=84561"] = {"Pour que tous voient", ""}
        s["quest;reward=5944"] = {"En rêves", ""}
        s["quest;reward=8949"] = {"La vendetta de Falrin", ""}
        s["npc;sold=12944"] = {"Lokhtos Darkbargainer <La Confrérie du thorium>", ""}
        s["npc;drop=228436"] = {"Messager de Sulfuron", "Cœur du Magma"}
        s["spell;created=461712"] = {"Marteau des titans raffiné", ""}
        s["spell;created=16988"] = {"Marteau des Titans", ""}
        s["spell;created=461722"] = {"Gantelets diablocœur", ""}
        s["spell;created=461724"] = {"Jambières diablocœur", ""}
        s["quest;reward=84545"] = {"La récompense du héros", ""}
        s["npc;drop=15510"] = {"Fankriss l'Inflexible", "Ahn'Qiraj"}
        s["npc;drop=15341"] = {"Général Rajaxx", "Ruines d'Ahn'Qiraj"}
        s["npc;drop=10487"] = {"Protecteur ressuscité", "Scholomance"}
        s["npc;drop=15263"] = {"Le Prophète Skeram", "Ahn'Qiraj"}
        s["npc;drop=16449"] = {"Esprit de Naxxramas", "Naxxramas"}
        s["npc;drop=12460"] = {"Garde wyrm Griffemort", "Repaire de l'Aile noire"}
        s["npc;drop=10430"] = {"La Bête", "Pic Blackrock"}
        s["npc;drop=10500"] = {"Professeur spectral", "Scholomance"}
        s["npc;drop=221407"] = {"Diablotin ombrerêve", "Feralas"}
        s["quest;reward=9120"] = {"La chute de Kel'Thuzad", ""}
        s["spell;created=15596"] = {"Coeur fumant de la montagne", ""}
        s["quest;reward=7067"] = {"Les instructions du paria", ""}
        s["quest;reward=8573"] = {"Equipement de guerre de champion", ""}
        s["npc;drop=9547"] = {"Client assoiffé", "Profondeurs de Blackrock"}
        s["spell;created=461690"] = {"Cape changeante ouvragée", ""}
        s["npc;drop=230302"] = {"Seigneur Kazzak", "La Balafre impure"}
        s["spell;created=435904"] = {"Capuche gneuro-liée luminescente", ""}
        s["spell;created=23703"] = {"Pouvoir des Grumegueules", ""}
        s["spell;created=19080"] = {"Jambières de l'ours de guerre", ""}
        s["npc;sold=10857"] = {"Intendant de l'Aube d'argent Lightspark <L'Aube d'argent>", "Maleterres de l'ouest (Western Plaguelands)"}
        s["spell;created=23705"] = {"Demi-bottes de l'aube", ""}
        s["npc;sold=13278"] = {"Duc Hydraxis", "Azshara"}
        s["npc;sold=218115"] = {"Mai'zin <Changeur de sang Gurubashi>", "Vallée de Strangleronce (Stranglethorn Vale)"}
        s["quest;reward=80324"] = {"Le roi fou", ""}
        s["npc;drop=8567"] = {"Glouton", "Souilles de Tranchebauge"}
        s["npc;drop=220007"] = {"Retombée visqueuse", "Gnomeregan"}
        s["npc;sold=217689"] = {"Ziri 'Clé à molette' Petipignon <Mordue de mécanique>", ""}
        s["npc;drop=201722"] = {"Ghamoo-Ra", "Profondeurs de Brassenoire"}
        s["npc;drop=220072"] = {"Électrocuteur 6000", "Gnomeregan"}
        s["spell;created=429354"] = {"Gants en cuir touché par le Vide", ""}
        s["quest;reward=824"] = {"Je'neu du Cercle terrestre", ""}
        s["quest;reward=80132"] = {"Guerre des plates-formes", ""}
        s["npc;drop=3669"] = {"Seigneur Cobrahn <Seigneur-Croc>", "Cavernes des lamentations"}
        s["npc;drop=215728"] = {"Disperseur de foule 9-60", "Gnomeregan"}
        s["npc;drop=218537"] = {"Mekgénieur Thermojoncteur", "Gnomeregan"}
        s["npc;drop=4295"] = {"Myrmidon écarlate", "Monastère écarlate"}
        s["quest;reward=7541"] = {"Un service pour la Horde", ""}
        s["npc;drop=6489"] = {"Echine-de-fer", "Monastère écarlate"}
        s["quest;reward=78916"] = {"Le Cœur du Vide", ""}
        s["npc;drop=7584"] = {"Marcheur des bois errant", "Feralas"}
        s["npc;drop=4389"] = {"Batteur des boues", "Marécage d'Âprefange (Dustwallow Marsh)"}
        s["npc;drop=2433"] = {"Cadavre d'Helcular", "Contreforts d'Hillsbrad"}
        s["spell;created=6705"] = {"Brassards en écailles de murloc", ""}
        s["spell;created=3779"] = {"Ceinture barbare", ""}
        s["npc;drop=4845"] = {"Forban Ombreforge", "Terres ingrates (Badlands)"}
        s["quest;reward=2767"] = {"Sauvez OOX-22/FE !", ""}
        s["quest;reward=793"] = {"Alliances rompues", ""}
        s["spell;created=435960"] = {"Feuille d’or hyperconductrice", ""}
        s["npc;drop=9033"] = {"Général Forgehargne", "Profondeurs de Blackrock"}
        s["npc;drop=12018"] = {"Chambellan Executus", "Cœur du Magma"}
        s["npc;drop=15509"] = {"Princesse Huhuran", "Ahn'Qiraj"}
        s["quest;reward=7506"] = {"Le Rêve d'Emeraude…", ""}
        s["npc;drop=15543"] = {"Princesse Yauj", "Ahn'Qiraj"}
        s["spell;created=22927"] = {"Peau du Fauve", ""}
        s["npc;drop=11501"] = {"Roi Gordok", "Hache-tripes"}
        s["npc;drop=10268"] = {"Gizrul l'esclavagiste", "Pic Blackrock"}
        s["spell;created=22759"] = {"Couvre-bras Coeur-de-braise", ""}
        s["npc;drop=15339"] = {"Ossirian l'Intouché", "Ruines d'Ahn'Qiraj"}
        s["spell;created=23709"] = {"Ceinture du Magma", ""}
        s["npc;drop=13020"] = {"Vaelastrasz le Corrompu", "Repaire de l'Aile noire"}
        s["npc;drop=9056"] = {"Fineous Darkvire <Chef architecte>", "Profondeurs de Blackrock"}
        s["npc;drop=10504"] = {"Seigneur Alexei Barov", "Scholomance"}
        s["npc;drop=14325"] = {"Capitaine Kromcrush", "Hache-tripes"}
        s["npc;drop=10809"] = {"Echine-de-pierre", "Stratholme"}
        s["quest;reward=8791"] = {"La chute d'Ossirian", ""}
        s["npc;drop=10439"] = {"Ramstein Grandgosier", "Stratholme"}
        s["quest;reward=7907"] = {"Suite de Fauves de Sombrelune", ""}
        s["object;contained=169243"] = {"Coffre des sept", "Profondeurs de Blackrock"}
        s["npc;drop=14515"] = {"Grande prêtresse Arlokk", "Zul'Gurub"}
        s["spell;created=461750"] = {"Diadème en étoffe lunaire incandescent", ""}
        s["spell;created=23665"] = {"Epaulières de l'Aube d'argent", ""}
        s["spell;created=446189"] = {"Protège-épaules d’obsession", ""}
        s["spell;created=19061"] = {"Epaulières vivantes", ""}
        s["spell;created=446194"] = {"Mantelet de la démence", ""}
        s["npc;drop=221394"] = {"Avatar d'Hakkar", "Le temple d'Atal'Hakkar"}
        s["npc;drop=9236"] = {"Chasseresse des ombres Vosh'gajin", "Pic Blackrock"}
        s["spell;created=19435"] = {"Bottes en étoffe lunaire", ""}
        s["npc;drop=218571"] = {"Ombre d'Eranikus", "Le temple d'Atal'Hakkar"}
        s["npc;drop=10506"] = {"Kirtonos le Héraut", "Scholomance"}
        s["quest;reward=80325"] = {"Le roi fou", ""}
        s["quest;reward=82081"] = {"Un rituel interrompu", ""}
        s["quest;reward=82058"] = {"Suite de Nature de Sombrelune", ""}
        s["npc;drop=3977"] = {"Grand Inquisiteur Whitemane", "Monastère écarlate"}
        s["npc;drop=14324"] = {"Cho'Rush l'Observateur", "Hache-tripes"}
        s["npc;drop=11661"] = {"Attise-flammes", "Cœur du Magma"}
        s["npc;drop=11673"] = {"Ancien chien du Magma", "Cœur du Magma"}
        s["quest;reward=9008"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=4024"] = {"Un goût de flammes", ""}
        s["npc;drop=13276"] = {"Diablotin Follengeance", "Hache-tripes"}
        s["npc;drop=9027"] = {"Gorosh le Derviche", "Profondeurs de Blackrock"}
        s["npc;drop=10264"] = {"Solakar Voluteflamme", "Pic Blackrock"}
        s["quest;reward=8906"] = {"Une proposition sérieuse", ""}
        s["quest;reward=8938"] = {"Une juste compensation", ""}
        s["npc;drop=10393"] = {"Krân", "Stratholme"}
        s["npc;drop=11489"] = {"Tendris Crochebois", "Hache-tripes"}
        s["npc;drop=9596"] = {"Bannok Grimaxe <Champion de la légion Brandefeu>", "Pic Blackrock"}
        s["quest;reward=8952"] = {"Les adieux d'Anthion", ""}
        s["spell;created=22922"] = {"Bottes de la mangouste", ""}
        s["quest;reward=5125"] = {"L'estimation d'Aurius", ""}
        s["quest;reward=7503"] = {"La plus grande race de chasseurs", ""}
        s["quest;reward=82108"] = {"Le drake vert", ""}
        s["npc;drop=10438"] = {"Maleki le Blafard", "Stratholme"}
        s["npc;drop=221391"] = {"Slirena <Reine harpie>", "Feralas"}
        s["npc;drop=15740"] = {"Colosse de Zora", "Silithus"}
        s["spell;created=462623"] = {"Création de Rhok’delar", ""}
        s["quest;reward=82104"] = {"Jammal’an le prophète", ""}
        s["npc;drop=8908"] = {"Golem de lave de guerre", "Profondeurs de Blackrock"}
        s["quest;reward=84148"] = {"Une proposition sérieuse", ""}
        s["spell;created=446237"] = {"Protège-bras de tueur alimentés par le Vide", ""}
        s["npc;drop=9029"] = {"Eviscérateur", "Profondeurs de Blackrock"}
        s["quest;reward=7029"] = {"La corruption de Vylelangue", ""}
        s["object;contained=179564"] = {"Tribut des Gordok", "Hache-tripes"}
        s["npc;drop=9445"] = {"Garde noir", "Profondeurs de Blackrock"}
        s["spell;created=23639"] = {"Fureur noire", ""}
        s["spell;created=461675"] = {"Faucheuse en arcanite raffinée", ""}
        s["npc;drop=222573"] = {"Ancienne délirante", "Zul'Farrak"}
        s["quest;reward=8272"] = {"Héros des Frostwolf", ""}
        s["quest;reward=3636"] = {"Apportez la Lumière", ""}
        s["quest;reward=1364"] = {"Les ordres de Mazen", ""}
        s["npc;drop=7603"] = {"Assistant lépreux", "Gnomeregan"}
        s["npc;drop=2716"] = {"Chasseur Wyrm Crache-poussières", "Terres ingrates (Badlands)"}
        s["quest;reward=628"] = {"L’Excelsior de chez Drizzlik", ""}
        s["quest;reward=7068"] = {"Fragments d'Ombréclat", ""}
        s["quest;reward=2822"] = {"La marque de la qualité", ""}
        s["npc;drop=5860"] = {"Chaman noir du crépuscule", "Gorge des Vents brûlants (Searing Gorge)"}
        s["npc;drop=13601"] = {"Artisan Gizlock", "Maraudon"}
        s["quest;reward=1048"] = {"Au monastère écarlate", ""}
        s["spell;created=435953"] = {"Chaperon antiradiation en écailles", ""}
        s["spell;created=18457"] = {"Robe de l'archimage", ""}
        s["quest;reward=8632"] = {"Le diadème de l'énigme", ""}
        s["quest;reward=8625"] = {"Les protège-épaules de l'énigme", ""}
        s["quest;reward=8633"] = {"La robe de l'énigme", ""}
        s["quest;reward=8634"] = {"Les bottes de l'énigme", ""}
        s["npc;drop=15236"] = {"Guêpe vekniss", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=84157"] = {"Une proposition sérieuse", ""}
        s["quest;reward=84549"] = {"Les recettes de l’arcaniste", ""}
        s["npc;drop=11480"] = {"Aberration des arcanes", "Hache-tripes"}
        s["quest;reward=84181"] = {"Les adieux d’Anthion", ""}
        s["npc;drop=10198"] = {"Kashoch le ravageur", "Berceau-de-l'Hiver (Winterspring)"}
        s["quest;reward=84165"] = {"Une juste compensation", ""}
        s["spell;created=22868"] = {"Gants d'Inferno", ""}
        s["quest;reward=82095"] = {"Le dieu Hakkar", ""}
        s["quest;reward=8932"] = {"Une juste compensation", ""}
        s["npc;drop=9024"] = {"Pyromancien Loregrain", "Profondeurs de Blackrock"}
        s["quest;reward=617"] = {"De derrière les fagots", ""}
        s["npc;drop=6146"] = {"Brise-falaises", "Azshara"}
        s["spell;created=446236"] = {"Protège-bras d’invocatrice alimentés par le Vide", ""}
        s["quest;reward=3907"] = {"Discordance des flammes", ""}
        s["spell;created=23663"] = {"Mantelet des Grumegueules", ""}
        s["npc;drop=4288"] = {"Belluaire écarlate", "Monastère écarlate"}
        s["npc;drop=6487"] = {"Arcaniste Doan", "Monastère écarlate"}
        s["quest;reward=8366"] = {"Le racket des Mers du sud", ""}
        s["spell;created=16724"] = {"Heaume d'âme blanche", ""}
        s["npc;drop=10339"] = {"Gyth <Monture de Rend Blackhand>", "Pic Blackrock"}
        s["spell;created=19054"] = {"Cuirasse en écailles de dragon rouge", ""}
        s["npc;drop=14321"] = {"Garde Fengus", "Hache-tripes"}
        s["npc;drop=14861"] = {"Régisseuse sanglante de Kirtonos", "Scholomance"}
        s["quest;reward=7501"] = {"La lumière et comment l'altérer", ""}
        s["spell;created=446191"] = {"Espauliers maléfiques", ""}
        s["spell;created=446190"] = {"Mantelet gémissant en anneaux", ""}
        s["quest;reward=84150"] = {"Une proposition sérieuse", ""}
        s["npc;drop=10464"] = {"Banshee gémissante", "Stratholme"}
        s["npc;drop=12203"] = {"Glissement de terrain", "Maraudon"}
        s["spell;created=435906"] = {"Cage cérébrale en vrai-argent réfléchissant", ""}
        s["spell;created=435949"] = {"Camail hyperconducteur en écailles lumineux", ""}
        s["spell;created=435610"] = {"Monocle gneuro-lié en arcano-filament", ""}
        s["npc;drop=14686"] = {"Dame Falther'ess", "Souilles de Tranchebauge"}
        s["npc;sold=222685"] = {"Intendante Kyleen", "Ashenvale"}
        s["spell;created=20874"] = {"Brassards en sombrefer", ""}
        s["spell;created=24399"] = {"Bottes en sombrefer", ""}
        s["quest;reward=80131"] = {"Amélioration gnomique", ""}
        s["npc;drop=2691"] = {"Estafette du Haut-val", "Les Hinterlands"}
        s["npc;drop=10596"] = {"Matriarche Couveuse", "Pic Blackrock"}
        s["spell;created=461730"] = {"Garde de givre durcie", ""}
        s["spell;created=23652"] = {"Garde noire", ""}
        s["spell;created=461669"] = {"Championne en arcanite raffinée", ""}
        s["spell;created=22797"] = {"Disque de force réactif", ""}
        s["npc;drop=3976"] = {"Commandant écarlate Mograine", "Monastère écarlate"}
        s["quest;reward=7065"] = {"Corruption de la terre et de la Graine", ""}
        s["spell;created=9952"] = {"Epaulières ornées en mithril", ""}
        s["npc;drop=5287"] = {"Hurleur Longues-dents", "Feralas"}
        s["npc;drop=1884"] = {"Bûcheron écarlate", "Maleterres de l'ouest (Western Plaguelands)"}
        s["npc;drop=10418"] = {"Gardien cramoisi", "Stratholme"}
        s["npc;drop=10808"] = {"Timmy le Cruel", "Stratholme"}
        s["spell;created=16729"] = {"Heaume Cœur-de-lion", ""}
        s["spell;created=435908"] = {"Casque anti-interférences trempé", ""}
        s["spell;created=24141"] = {"Epaulières de ténébrâme", ""}
        s["npc;drop=7524"] = {"Bien-née angoissée", "Berceau-de-l'Hiver (Winterspring)"}
        s["spell;created=19101"] = {"Epaulières volcaniques", ""}
        s["spell;created=446179"] = {"Plaques d’épaule d’effroi", ""}
        s["quest;reward=5166"] = {"La cuirasse du vol chromatique", ""}
        s["spell;created=19076"] = {"Cuirasse volcanique", ""}
        s["spell;created=24139"] = {"Cuirasse de ténébrâme", ""}
        s["spell;created=446238"] = {"Protège-bras de protecteur alimentés par le Vide", ""}
        s["spell;created=23633"] = {"Gants de l'Aube", ""}
        s["spell;created=461671"] = {"Gantelets de forteresse majeure", ""}
        s["spell;created=23632"] = {"Ceinturon de l'Aube", ""}
        s["quest;reward=5081"] = {"Mission de Maxwell", ""}
        s["spell;created=19059"] = {"Jambières volcaniques", ""}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", ""}
        s["spell;created=461718"] = {"Tranquillité", ""}
        s["spell;created=21160"] = {"Oeil de Sulfuras", ""}
        s["npc;drop=9039"] = {"Tragi'rel", "Profondeurs de Blackrock"}
        s["spell;created=20873"] = {"Epaulières en anneaux de feu", ""}
        s["npc;drop=15305"] = {"Seigneur Skwol", "Silithus"}
        s["spell;created=461651"] = {"Gantelets en plaques de feu de la technique cachée", ""}
        s["spell;created=27585"] = {"Ceinture lourde en obsidienne", ""}
        s["spell;created=27829"] = {"Jambières titanesques", ""}
        s["spell;created=20876"] = {"Jambières en sombrefer", ""}
        s["quest;reward=8572"] = {"La tenue de combat de vétéran", ""}
        s["spell;created=12906"] = {"Coq de combat gnome", ""}
        s["spell;created=460460"] = {"Marteau en sulfuron", ""}
        s["spell;created=450409"] = {"Appel de Sul’thraze", ""}
        s["npc;drop=8127"] = {"Antu'sul <Surveillant de Sul>", "Zul'Farrak"}
        s["quest;reward=84008"] = {"Une leçon de grâce", ""}
        s["spell;created=461714"] = {"Violation", ""}
        s["npc;drop=227019"] = {"Diathorus le Chercheur", "Canyon de la Malechute"}
        s["spell;created=16994"] = {"Déchireuse en arcanite", ""}
        s["spell;created=23151"] = {"Equilibre de la Lumière et de l'Ombre", ""}
        s["npc;drop=14517"] = {"Grande prêtresse Jeklik", "Zul'Gurub"}
        s["npc;drop=15816"] = {"Major qiraji He'al-ie", "Mille pointes (Thousand Needles)"}
        s["quest;reward=9009"] = {"Garder le meilleur pour la fin", ""}
        s["npc;drop=11382"] = {"Seigneur sanglant Mandokir", "Zul'Gurub"}
        s["spell;created=18456"] = {"Habit de vraie foi", ""}
        s["npc;drop=11664"] = {"Elite Attise-flammes", "Cœur du Magma"}
        s["quest;reward=8909"] = {"Une proposition sérieuse", ""}
        s["quest;reward=8940"] = {"Une juste compensation", ""}
        s["npc;drop=14509"] = {"Grand prêtre Thekal", "Zul'Gurub"}
        s["quest;reward=9019"] = {"Les adieux d'Anthion", ""}
        s["quest;reward=7504"] = {"Sainte Bolognaise : Ce que la lumière ne vous dit pas", ""}
        s["quest;reward=82111"] = {"Le sang de Morphaz", ""}
        s["npc;drop=12459"] = {"Démoniste de l'Aile noire", "Repaire de l'Aile noire"}
        s["object;contained=161495"] = {"Coffre secret", "Profondeurs de Blackrock"}
        s["spell;created=463008"] = {"Équilibre de la Lumière et de l’Ombre", ""}
        s["spell;created=461708"] = {"Robe en étoffe lunaire incandescente", ""}
        s["quest;reward=84151"] = {"Une proposition sérieuse", ""}
        s["spell;created=461752"] = {"Jambières en étoffe lunaire incandescentes", ""}
        s["quest;reward=55"] = {"Morbent Fel", ""}
        s["npc;drop=4366"] = {"Garde-serpent Strashaz", "Marécage d'Âprefange (Dustwallow Marsh)"}
        s["npc;drop=10423"] = {"Prêtre cramoisi", "Stratholme"}
        s["npc;drop=9818"] = {"Invocateur Blackhand <Légion Blackhand>", "Pic Blackrock"}
        s["spell;created=446193"] = {"Espauliers d’esprit fracturé", ""}
        s["npc;drop=9219"] = {"Boucher Pierre-du-pic", "Pic Blackrock"}
        s["npc;drop=223544"] = {"Intrus gangrené", "Terres foudroyées (Blasted Lands)"}
        s["quest;reward=9225"] = {"Armes de bataille épiques - Révéré auprès de l'Aube", ""}
        s["npc;drop=10425"] = {"Mage de bataille cramoisi", "Stratholme"}
        s["npc;drop=10477"] = {"Nécromancien Scholomance", "Scholomance"}
        s["npc;drop=8923"] = {"Panzor l'Invincible", "Profondeurs de Blackrock"}
        s["npc;drop=10502"] = {"Dame Illucia Barov", "Scholomance"}
        s["quest;reward=9221"] = {"Armes de bataille excellentes - Ami de l'Aube", ""}
        s["spell;created=18436"] = {"Robe de la nuit hivernale", ""}
        s["npc;drop=12457"] = {"Lieur de sort de l'Aile noire", "Repaire de l'Aile noire"}
        s["quest;reward=8592"] = {"La tiare de l'Oracle", ""}
        s["quest;reward=8594"] = {"Le mantelet de l'Oracle", ""}
        s["spell;created=18453"] = {"Epaulières en gangrétoffe", ""}
        s["quest;reward=8603"] = {"Les habits de l'Oracle", ""}
        s["npc;drop=15247"] = {"Lave-cerveaux qiraji", "Ahn'Qiraj"}
        s["spell;created=22867"] = {"Gants en gangrétoffe", ""}
        s["spell;created=23041"] = {"Prononcer l'Anathème", ""}
        s["npc;drop=14516"] = {"Chevalier de la mort Ravassombre", "Scholomance"}
        s["spell;created=461962"] = {"Prononcer l’Anathème", ""}
        s["npc;drop=1843"] = {"Contremaître Jerris", "Maleterres de l'ouest (Western Plaguelands)"}
        s["npc;drop=12801"] = {"Chimaerok des arcanes", "Feralas"}
        s["npc;drop=228914"] = {"Gardien disjoint", "Canyon de la Malechute"}
        s["npc;drop=16154"] = {"Chevalier de la mort ressuscité", "Naxxramas"}
        s["npc;drop=11469"] = {"Rongé Eldreth", "Hache-tripes"}
        s["npc;drop=14506"] = {"Seigneur Hel'nurath", "Hache-tripes"}
        s["npc;drop=15975"] = {"Tisse-charogne", "Naxxramas"}
        s["npc;drop=1838"] = {"Inquisiteur écarlate", "Maleterres de l'ouest (Western Plaguelands)"}
        s["npc;drop=1851"] = {"La Bogue", "Maleterres de l'ouest (Western Plaguelands)"}
        s["npc;drop=15757"] = {"Général de division qiraji", "Silithus"}
        s["npc;drop=15390"] = {"Capitaine Xurrem", "Ruines d'Ahn'Qiraj"}
        s["npc;drop=10371"] = {"Capitaine de la Griffe enragée", "Pic Blackrock"}
        s["npc;drop=11896"] = {"Creusechair", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=7459"] = {"Matriarche Chardon de glace", "Berceau-de-l'Hiver (Winterspring)"}
        s["npc;drop=10663"] = {"Griffemana", "Berceau-de-l'Hiver (Winterspring)"}
        s["spell;created=18442"] = {"Chaperon en gangrétoffe", ""}
        s["npc;drop=11143"] = {"Postier Malown", "Stratholme"}
        s["spell;created=19794"] = {"Lunettes de concentration extrême", ""}
        s["npc;drop=11622"] = {"Cliquettripes", "Scholomance"}
        s["object;contained=181074"] = {"Butin de l'arène", "Profondeurs de Blackrock"}
        s["spell;created=18451"] = {"Robe en gangrétoffe", ""}
        s["npc;drop=9817"] = {"Tisseur d’effroi Blackhand <Légion Blackhand>", "Pic Blackrock"}
        s["npc;drop=10372"] = {"Langue de feu de la Griffe enragée", "Pic Blackrock"}
        s["npc;drop=10901"] = {"Gardien du savoir Polkelt", "Scholomance"}
        s["spell;created=18454"] = {"Gants de maîtrise magique", ""}
        s["spell;created=18419"] = {"Pantalon en gangrétoffe", ""}
        s["npc;drop=10436"] = {"Baronne Anastari", "Stratholme"}
        s["npc;drop=9217"] = {"Seigneur magus Pierre-du-pic", "Pic Blackrock"}
        s["npc;drop=6228"] = {"Ambassadeur Sombrefer", "Gnomeregan"}
        s["npc;drop=6370"] = {"Fouilleur Makrinni", "Azshara"}
        s["quest;reward=9004"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=8956"] = {"Les adieux d'Anthion", ""}
        s["quest;reward=8910"] = {"Une proposition sérieuse", ""}
        s["quest;reward=8941"] = {"Une juste compensation", ""}
        s["quest;reward=8639"] = {"Le casque du dispensateur de mort", ""}
        s["quest;reward=8641"] = {"Les spallières du dispensateur de mort", ""}
        s["quest;reward=8638"] = {"Le gilet du dispensateur de mort", ""}
        s["npc;drop=10505"] = {"Instructeur Malicia", "Scholomance"}
        s["quest;reward=8201"] = {"Une collection de têtes", ""}
        s["npc;drop=9265"] = {"Chasseur d'ombre Smolderthorn", "Pic Blackrock"}
        s["quest;reward=8640"] = {"Les jambières du dispensateur de mort", ""}
        s["quest;reward=8637"] = {"Les bottes du dispensateur de mort", ""}
        s["npc;drop=14507"] = {"Grand prêtre Venoxis", "Zul'Gurub"}
        s["quest;reward=7498"] = {"Garona : une étude en discrétion et en trahison", ""}
        s["quest;reward=7787"] = {"Éveille-toi, Lame-tonnerre !", ""}
        s["npc;drop=203138"] = {"Surveillant ragenclume", "Profondeurs de Blackrock"}
        s["spell;created=461237"] = {"Crâne d’ombreflamme", ""}
        s["spell;created=19090"] = {"Epaulières tempétueuses", ""}
        s["spell;created=19079"] = {"Armure tempétueuse", ""}
        s["quest;reward=84152"] = {"Une proposition sérieuse", ""}
        s["spell;created=26279"] = {"Gants tempétueux", ""}
        s["npc;drop=10318"] = {"Assassin Blackhand <Légion Blackhand>", "Pic Blackrock"}
        s["spell;created=19067"] = {"Pantalon tempétueux", ""}
        s["quest;reward=84548"] = {"Garona : une étude en discrétion et en trahison", ""}
        s["npc;drop=15741"] = {"Colosse de Regal", "Silithus"}
        s["quest;reward=53"] = {"Doux whisky", ""}
        s["npc;drop=2751"] = {"Golem de guerre", "Terres ingrates (Badlands)"}
        s["spell;created=9201"] = {"Brassards mats", ""}
        s["quest;reward=80455"] = {"Attente insoutenable", ""}
        s["npc;drop=15209"] = {"Templier cramoisi <Conseil abyssal>", "Silithus"}
        s["spell;created=23706"] = {"Mantelet doré de l'Aube", ""}
        s["spell;created=19068"] = {"Harnais de l'ours de guerre", ""}
        s["npc;drop=9237"] = {"Maître de guerre Voone", "Pic Blackrock"}
        s["npc;drop=15817"] = {"Général de brigade qiraji Pax-lish", "Silithus"}
        s["quest;reward=8623"] = {"Le diadème d'implorateur de tempête", ""}
        s["quest;reward=9011"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=7668"] = {"La menace de Ravassombre", ""}
        s["quest;reward=8602"] = {"Les espauliers de l'implorateur des tempêtes", ""}
        s["spell;created=16650"] = {"Cotte de mailles Ronce-sauvage", ""}
        s["quest;reward=8622"] = {"Le haubert d'implorateur de tempête", ""}
        s["quest;reward=8918"] = {"Une proposition sérieuse", ""}
        s["npc;drop=14454"] = {"Le Déchirevent", "Silithus"}
        s["quest;reward=8621"] = {"Les bottes d'implorateur de tempête", ""}
        s["npc;drop=11462"] = {"Tréant Crochebois", "Hache-tripes"}
        s["quest;reward=7505"] = {"Le Horion de givre et vous", ""}
        s["quest;reward=82113"] = {"Vaudou !", ""}
        s["spell;created=461735"] = {"Maille invincible", ""}
        s["quest;reward=84160"] = {"Une proposition sérieuse", ""}
        s["npc;drop=11043"] = {"Moine cramoisi", "Stratholme"}
        s["spell;created=461737"] = {"Gantelets de la tempête", ""}
        s["npc;drop=10083"] = {"Flammécaille de la Griffe enragée", "Pic Blackrock"}
        s["npc;drop=10814"] = {"Garde d'élite chromatique", "Pic Blackrock"}
        s["npc;drop=14323"] = {"Garde Slip'kik", "Hache-tripes"}
        s["spell;created=446186"] = {"Garde-épaules cacophoniques en anneaux", ""}
        s["spell;created=451706"] = {"Espauliers hurlants en anneaux", ""}
        s["npc;drop=9028"] = {"Grison", "Profondeurs de Blackrock"}
        s["spell;created=24138"] = {"Gantelets d'âmesang", ""}
        s["npc;drop=224257"] = {"Esclave atal'ai", "Le temple d'Atal'Hakkar"}
        s["spell;created=435958"] = {"Mur de rouages en vrai-argent", ""}
        s["spell;created=19094"] = {"Epaulières en écailles de dragon noir", ""}
        s["spell;created=23708"] = {"Gantelets chromatiques", ""}
        s["spell;created=19107"] = {"Jambières en écailles de dragon noir", ""}
        s["spell;created=20855"] = {"Bottes en écailles de dragon noir", ""}
        s["spell;created=23653"] = {"Crépuscule", ""}
        s["npc;drop=6117"] = {"Jeune liche bien-née", "Azshara"}
        s["spell;created=19085"] = {"Cuirasse en écailles de dragon noir", ""}
        s["npc;drop=10507"] = {"Le Voracien", "Scholomance"}
        s["spell;created=16991"] = {"Annihilateur", ""}
        s["npc;drop=12258"] = {"Tranchefouet", "Maraudon"}
        s["npc;drop=7358"] = {"Amnennar le Porte-froid", "Souilles de Tranchebauge"}
        s["quest;reward=79366"] = {"Le calme avant la tempête", ""}
        s["npc;drop=13596"] = {"Grippe-charogne", "Maraudon"}
        s["quest;reward=8624"] = {"Les jambières d'implorateur de tempête", ""}
        s["quest;reward=7488"] = {"Le filet de Lethtendris", ""}
        s["quest;reward=5526"] = {"Fragment de la Gangrevigne", ""}
        s["spell;created=8770"] = {"Robe de puissance", ""}
        s["npc;drop=7357"] = {"Mordresh Oeil-de-feu", "Souilles de Tranchebauge"}
        s["spell;created=24356"] = {"Lunettes en vignesang", ""}
        s["quest;reward=8662"] = {"Le diadème d'implorateur funeste", ""}
        s["quest;reward=9005"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=8664"] = {"Le mantelet d'implorateur funeste", ""}
        s["quest;reward=8661"] = {"La robe d'implorateur funeste", ""}
        s["spell;created=18458"] = {"Robe du Vide", ""}
        s["quest;reward=8936"] = {"Une juste compensation", ""}
        s["quest;reward=8381"] = {"Armes de guerre", ""}
        s["spell;created=24201"] = {"Création de la Rune de l'Aube", ""}
        s["quest;reward=7502"] = {"Contrôler les ombres", ""}
        s["item:contained=224851"] = {"Trésor venu d’ailleurs", ""}
        s["spell;created=461747"] = {"Gilet en étoffe lunaire incandescent", ""}
        s["quest;reward=84153"] = {"Une proposition sérieuse", ""}
        s["spell;created=23662"] = {"Sagesse des Grumegueules", ""}
        s["spell;created=462282"] = {"Ceinture brodée de l’archimage", ""}
        s["npc;drop=15220"] = {"Le duc des Zéphyrs <Conseil abyssal>", "Silithus"}
        s["spell;created=429351"] = {"Bottes en soie d’araignée extraplanaires", ""}
        s["npc;drop=15203"] = {"Prince Skaldrenox", "Silithus"}
        s["spell;created=19830"] = {"Petit dragon en arcanite", ""}
        s["spell;created=461743"] = {"Lame feuille-de-saule de l’archimagus", ""}
        s["item:contained=223150"] = {"Trésor venu d’ailleurs", ""}
        s["spell;created=20848"] = {"Mantelet Coeur-de-braise", ""}
        s["npc;drop=10376"] = {"Croc cristallin", "Pic Blackrock"}
        s["spell;created=446195"] = {"Protège-épaules des dérangés", ""}
        s["spell;created=22870"] = {"Cape de sauvegarde", ""}
        s["npc;drop=9439"] = {"Gardien noir Uggel", "Profondeurs de Blackrock"}
        s["spell;created=19093"] = {"Cape en écailles d'Onyxia", ""}
        s["spell;created=20849"] = {"Gants Coeur-de-braise", ""}
        s["quest;reward=84411"] = {"[Diplomat Ring]", ""}
        s["quest;reward=5942"] = {"Trésors cachés", ""}
        s["quest;reward=1560"] = {"La quête de Tooga", ""}
        s["npc;drop=15208"] = {"Le duc des Eclats <Conseil abyssal>", "Silithus"}
        s["spell;created=23666"] = {"Robe Coeur-de-braise", ""}
        s["quest;reward=80141"] = {"Nogg améliore l’anneau", ""}
        s["quest;reward=82107"] = {"Plumes vaudou", ""}
        s["npc;drop=8762"] = {"Grumetoile solitaire", "Azshara"}
        s["quest;reward=3129"] = {"Armes de l'Esprit", ""}
        s["quest;reward=84162"] = {"Une proposition sérieuse", ""}
        s["quest;reward=9006"] = {"Garder le meilleur pour la fin", ""}
        s["quest;reward=8561"] = {"La couronne du Conquérant", ""}
        s["quest;reward=8544"] = {"Les spallières du Conquérant", ""}
        s["quest;reward=8562"] = {"La cuirasse du Conquérant", ""}
        s["quest;reward=8937"] = {"Une juste compensation", ""}
        s["quest;reward=8560"] = {"Les cuissards du Conquérant", ""}
        s["quest;reward=8559"] = {"Les grèves du Conquérant", ""}
        s["quest;reward=9022"] = {"Les adieux d'Anthion", ""}
        s["quest;reward=8789"] = {"Les armes impériales qiraji", ""}
        s["spell;created=9954"] = {"Gantelets en vrai-argent", ""}
        s["quest;reward=3566"] = {"Debout, Obsidion !", ""}
        s["quest;reward=84550"] = {"Le codex de défense", ""}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", ""}
        s["spell;created=452433"] = {"Invocation de Gla’sir", ""}
        s["npc;drop=231494"] = {"Prince Tonneraan <Le Cherchevent>", "La vallée des Cristaux"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", ""}
        s["spell;created=452434"] = {"Invocation de Rae’lar", ""}
        s["npc;drop=14510"] = {"Grande prêtresse Mar'li", "Zul'Gurub"}
        s["npc;drop=232632"] = {"Azgaloth <Seigneur de la fosse>", "Canyon de la Malechute"}
        s["spell;created=461710"] = {"Fusil de précision du noyau enflammé", ""}
        s["spell;created=466117"] = {"Harmonisation du bâton du givre", ""}
        s["spell;created=465417"] = {"Changer de posture", ""}
        s["quest;reward=85443"] = {"[Rise, Thunderfury!]", ""}
        s["spell;created=465418"] = {"Changer de posture", ""}
        s["npc;drop=227939"] = {"[The Molten Core]", "Cœur du Magma"}
        s["quest;reward=85480"] = {"[Procrastimond's Gratitude]", ""}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Repaire de l'Aile noire"}
        s["npc;drop=16011"] = {"Horreb", "Naxxramas"}
        s["npc;drop=14888"] = {"Léthon", "Bois de la Pénombre (Duskwood)"}
        s["spell;created=469201"] = {"Ignition de flammes", "CRAFTING"}
        s["spell;created=468840"] = {"Combiner la faux du Chaos", "CRAFTING"}
        s["spell;created=467790"] = {"Combiner le bâton de l’ordre", "CRAFTING"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "Montagnes d'Alterac"}
        s["quest;reward=85454"] = {"[A Just Reward]", "Les Paluns (Wetlands)"}
        s["npc;drop=15369"] = {"Ayamiss le Chasseur", "Ruines d'Ahn'Qiraj"}
        s["quest;reward=86678"] = {"Équipement de guerre de champion", "Silithus"}
        s["spell;created=1216020"] = {"Idole de courroux sidéral", "CRAFTING"}
        s["spell;created=1213538"] = {"Cape en soie qiraji", "CRAFTING"}
        s["npc;drop=15370"] = {"Buru Grandgosier", "Ruines d'Ahn'Qiraj"}
        s["spell;created=1213595"] = {"Larme de la Rêveuse", "CRAFTING"}
        s["spell;created=1213502"] = {"Marteau-tempête d’obsidienne", "CRAFTING"}
        s["spell;created=1216340"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1216022"] = {"Idole de férocité féline", "CRAFTING"}
        s["npc;drop=228230"] = {"Harrigen <Le Sous-marché>", "Steppes ardentes"}
        s["spell;created=1213536"] = {"Pèlerine en soie qiraji", "CRAFTING"}
        s["quest;reward=86675"] = {"L’équipement de guerre des volontaires", "Silithus"}
        s["spell;created=23704"] = {"Batailleurs grumegueules", "CRAFTING"}
        s["quest;reward=86676"] = {"La tenue de combat de vétéran", "Silithus"}
        s["spell;created=1213593"] = {"Pierre de vitesse", "CRAFTING"}
        s["spell;created=1216385"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213500"] = {"Destructeur d’obsidienne", "CRAFTING"}
        s["spell;created=1216024"] = {"Idole de la puissance ursine", "CRAFTING"}
        s["spell;created=24121"] = {"Pourpoint en peau de chauve-souris primordiale", "CRAFTING"}
        s["spell;created=1213738"] = {"Casque de la ronceraie", "CRAFTING"}
        s["spell;created=1213736"] = {"Bottes de la ronceraie", "CRAFTING"}
        s["spell;created=1213598"] = {"Magnétite de vengeance", "CRAFTING"}
        s["spell;created=1216366"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213521"] = {"Capuche de Roncerasoir", "CRAFTING"}
        s["spell;created=1213525"] = {"Armure en cuir de Roncerasoir", "CRAFTING"}
        s["spell;created=1213523"] = {"Protège-épaules de Roncerasoir", "CRAFTING"}
        s["spell;created=1213603"] = {"Broche incrustée de rubis", "CRAFTING"}
        s["spell;created=1216319"] = {"Touché par le Vide", "CRAFTING"}
        s["quest;reward=86677"] = {"Équipement de guerre de fidèle", "Silithus"}
        s["spell;created=1213635"] = {"Champignon enchanté", "CRAFTING"}
        s["spell;created=1213540"] = {"Drapé en soie qiraji", "CRAFTING"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "Silithus"}
        s["quest;reward=86674"] = {"Le poison parfait", "Silithus"}
        s["spell;created=1216365"] = {"Touché par le Vide", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Cratère d'Un'Goro"}
        s["spell;created=24137"] = {"Epaulières d'âmesang", "CRAFTING"}
        s["spell;created=1216384"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1216387"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1216327"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=466116"] = {"Harmonisation du bâton infernal", "CRAFTING"}
        s["spell;created=1213628"] = {"Tome de prière enchanté", "CRAFTING"}
        s["quest;reward=86672"] = {"Les armes impériales qiraji", "Repaire de l'Aile noire"}
        s["spell;created=1216005"] = {"Libram de piété", "CRAFTING"}
        s["spell;created=1213481"] = {"Cervelière de Tranchépic", "CRAFTING"}
        s["spell;created=1213484"] = {"Plaques d’épaules de Tranchépic", "CRAFTING"}
        s["spell;created=1214884"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213588"] = {"Disque de force réactif syntonisé", "CRAFTING"}
        s["spell;created=1214270"] = {"Bouclier dentelé en obsidienne", "CRAFTING"}
        s["spell;created=1213490"] = {"Harnois de bataille d’épaules de Tranchépic", "CRAFTING"}
        s["spell;created=1213506"] = {"Défenseur d’obsidienne", "CRAFTING"}
        s["spell;created=1216379"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1216007"] = {"Libram de l’exorciste", "CRAFTING"}
        s["spell;created=1216382"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213534"] = {"Écharpe en soie qiraji", "CRAFTING"}
        s["spell;created=1216375"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213492"] = {"Saccageur en obsidienne", "CRAFTING"}
        s["spell;created=1216377"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213498"] = {"Championne en obsidienne", "CRAFTING"}
        s["quest;reward=86671"] = {"L’équipement impérial qiraji", "Repaire de l'Aile noire"}
        s["spell;created=1216354"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1216014"] = {"Totem de tonnerre pyroclastique", "CRAFTING"}
        s["spell;created=1213742"] = {"Couronne sylvestre", "CRAFTING"}
        s["spell;created=1213740"] = {"Épaulières sylvestres", "CRAFTING"}
        s["spell;created=28210"] = {"Etreinte de Gaïa", "CRAFTING"}
        s["spell;created=1213744"] = {"Gilet sylvestre", "CRAFTING"}
        s["spell;created=1214306"] = {"Brassards de rêvécaille", "CRAFTING"}
        s["spell;created=1214307"] = {"Mitaines de rêvécaille", "CRAFTING"}
        s["npc;drop=235180"] = {"Léthon", "Feralas"}
        s["quest;reward=9248"] = {"Une humble offrande", "Silithus"}
        s["quest;reward=86442"] = {"La corruption de Nefarius", "Repaire de l'Aile noire"}
        s["spell;created=1213532"] = {"Robe vampirique", "CRAFTING"}
        s["object;contained=495503"] = {"Trésor chromatique", "Repaire de l'Aile noire"}
        s["spell;created=1216372"] = {"Touché par le Vide", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "Silithus"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"Suite de Fauves de Sombrelune", "Forêt d'Elwynn"}
        s["quest;reward=86762"] = {"Suite d’Élémentaires de Sombrelune", "Forêt d'Elwynn"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Reflet-de-Lune (Moonglade)"}
        s["spell;created=1214303"] = {"Kilt de rêvécaille", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "Berceau-de-l'Hiver (Winterspring)"}
        s["npc;drop=3975"] = {"Herod <Le champion écarlate>", "Monastère écarlate"}
        s["spell;created=1216364"] = {"Touché par le Vide", "CRAFTING"}
        s["spell;created=1213633"] = {"Totem enchanté", "CRAFTING"}
        s["spell;created=1216381"] = {"Touché par le Vide", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne <Le Cercle cénarien>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=16061"] = {"Instructeur Razuvious", "Naxxramas"}
        s["quest;reward=87360"] = {"La chute de Kel’Thuzad", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "Cryptes de Karazhan"}
        s["npc;drop=16143"] = {"Ombre funeste", "Terres foudroyées (Blasted Lands)"}
        s["npc;drop=16380"] = {"Sorcière des ossements", "Steppes ardentes"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "Cryptes de Karazhan"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=16060"] = {"Gothik le Moissonneur", "Naxxramas"}
        s["npc;drop=15936"] = {"Heigan l'Impur", "Naxxramas"}
        s["npc;drop=15989"] = {"Saphiron", "Naxxramas"}
        s["npc;drop=14697"] = {"Horreur chancelante", "Steppes ardentes"}
        s["npc;drop=237439"] = {"[Kharon]", "Cryptes de Karazhan"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=15953"] = {"Grande veuve Faerlina", "Naxxramas"}
        s["npc;drop=15954"] = {"Noth le Porte-peste", "Naxxramas"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "Cryptes de Karazhan"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "Cryptes de Karazhan"}
        s["spell;created=1223762"] = {"Cape glaciaire", "CRAFTING"}
        s["npc;drop=16028"] = {"Le Recousu", "Naxxramas"}
        s["npc;drop=238055"] = {"[Dark Rider]", "Cryptes de Karazhan"}
        s["npc;drop=238560"] = {"[The Warden]", "Cryptes de Karazhan"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "Cryptes de Karazhan"}
        s["spell;created=24179"] = {"Création du Sceau de l'Aube", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "Cryptes de Karazhan"}
        s["quest;reward=88728"] = {"Armes de bataille épiques – Exalté auprès de l’Aube", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "Cryptes de Karazhan"}
        s["npc;drop=16379"] = {"Esprit de damné", "Steppes ardentes"}
        s["npc;sold=16132"] = {"Veneur Leopold <La Croisade écarlate>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["quest;reward=87435"] = {"Gants en mailles de l’Aube d’argent", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;sold=16116"] = {"Archimage Angela Dosantos <Fraternité de la Lumière>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;sold=16115"] = {"Commandant Eligor Dawnbringer <Fraternité de la Lumière>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1223787"] = {"Cuirasse plaie-de-glace", "CRAFTING"}
        s["spell;created=1223791"] = {"Brassards plaie-de-glace", "CRAFTING"}
        s["spell;created=1223789"] = {"Gantelets plaie-de-glace", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1223780"] = {"Tunique polaire", "CRAFTING"}
        s["spell;created=1223784"] = {"Brassards polaires", "CRAFTING"}
        s["spell;created=1223782"] = {"Gants polaires", "CRAFTING"}
        s["quest;reward=86445"] = {"Le courroux de Neptulon", "Tanaris"}
        s["npc;sold=16113"] = {"Père Inigo Montoy <Fraternité de la Lumière>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1223760"] = {"Gilet glaciaire", "CRAFTING"}
        s["spell;created=1223764"] = {"Gants glaciaires", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan l'Assassin <La Croisade écarlate>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1214137"] = {"Crève-cœur en obsidienne", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Brise-terre <Le Cercle terrestre>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["npc;drop=238678"] = {"Peuk'ommun <Le Chagrin ailé>", "Cryptes de Karazhan"}
        s["spell;created=1223766"] = {"Poignets glaciaires", "CRAFTING"}
        s["spell;created=1223772"] = {"Poignets givrés", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus la Voix du courroux <La Croisade écarlate>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1213504"] = {"Lame feuille-de-saule d’obsidienne", "CRAFTING"}
        s["spell;created=1213527"] = {"Capuche vampirique", "CRAFTING"}
        s["spell;created=1213530"] = {"Châle vampirique", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax, Champion de la Lumière <Fraternité de la Lumière>", "Maleterres de l'est (Eastern Plaguelands)"}
        s["spell;created=1214145"] = {"Fusil en obsidienne", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Maleterres de l'est (Eastern Plaguelands)"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87444"] = {"Atiesh, le grand bâton du Gardien", "Tanaris"}
    end

    function SpecBisTooltip:TranslationitIT()
        s["npc;sold=13217"] = {"Thanthaldis Snowgleam", "Alterac Mountains"}
        s["npc;drop=11261"] = {"Doctor Theolen Krastinov", "Scholomance"}
        s["npc;sold=12777"] = {"Captain Dirgehammer", "Alterac Valley"}
        s["npc;sold=12792"] = {"Lady Palanseer", "Alterac Valley"}
        s["npc;drop=9018"] = {"High Interrogator Gerstahn", "Blackrock Depths"}
        s["npc;sold=13218"] = {"Grunnda Wolfheart", "Alterac Valley"}
        s["npc;sold=14753"] = {"Illiyana Moonblaze", "Ashenvale"}
        s["npc;drop=9736"] = {"Quartermaster Zigris", "Blackrock Spire"}
        s["npc;sold=13219"] = {"Jekyll Flandring", "Alterac Mountains"}
        s["npc;sold=14754"] = {"Kelm Hargunth", "The Barrens"}
        s["npc;drop=10509"] = {"Jed Runewatcher", "Blackrock Spire"}
        s["npc;sold=12782"] = {"Captain O'Neal", "Alterac Valley"}
        s["npc;sold=14581"] = {"Sergeant Thunderhorn", "Alterac Valley"}
        s["npc;sold=15126"] = {"Rutherford Twing", "Arathi Highlands"}
        s["npc;sold=15127"] = {"Samuel Hawke", "Arathi Highlands"}
        s["npc;drop=10899"] = {"Goraluk Anvilcrack", "Blackrock Spire"}
        s["npc;drop=228435"] = {"[Golemagg the Incinerator]", "Molten Core"}
        s["npc;sold=230319"] = {"[Deliana]", "Ironforge"}
        s["npc;drop=228438"] = {"[Ragnaros]", "Molten Core"}
        s["npc;drop=228432"] = {"[Garr]", "Molten Core"}
        s["npc;sold=227853"] = {"[Pix Xizzix] <[Undermine Trader]>", "Stranglethorn Vale"}
        s["npc;drop=15205"] = {"Baron Kazum", "Silithus"}
        s["npc;drop=228434"] = {"[Shazzrah]", "Molten Core"}
        s["npc;sold=222413"] = {"[Zalgo the Explorer] <[Purveyor of Lost Goods]>", "Stranglethorn Vale"}
        s["npc;drop=218819"] = {"[Festering Rotslime]", "The Temple of Atal'Hakkar"}
        s["npc;drop=220833"] = {"[Dreamscythe]", "The Temple of Atal'Hakkar"}
        s["npc;sold=222408"] = {"[Shadowtooth Emissary]", "Felwood"}
        s["npc;drop=228433"] = {"[Baron Geddon]", "Molten Core"}
        s["npc;drop=228429"] = {"[Lucifron]", "Molten Core"}
        s["npc;drop=226923"] = {"[Grimroot] <[The Mourning Guardian]>", "Demon Fall Canyon"}
        s["npc;drop=217280"] = {"[Grubbis]", "Gnomeregan"}
        s["npc;drop=204068"] = {"[Lady Sarevess]", "Blackfathom Deeps"}
        s["npc;drop=213334"] = {"[Aku'mai]", "Blackfathom Deeps"}
        s["npc;drop=221637"] = {"[Gasher]", "The Temple of Atal'Hakkar"}
        s["npc;drop=218721"] = {"[Jammal'an the Prophet]", "The Temple of Atal'Hakkar"}
        s["npc;drop=15206"] = {"The Duke of Cynders", "Silithus"}
        s["npc;drop=8929"] = {"Princess Moira Bronzebeard", "Blackrock Depths"}
        s["npc;sold=12805"] = {"Officer Areyn", "Stormwind City"}
        s["npc;sold=12799"] = {"Sergeant Ba'sha", "Orgrimmar"}
        s["npc;drop=2748"] = {"Archaedas", "Uldaman"}
        s["npc;drop=228022"] = {"[The Destructor's Wraith]", "Demon Fall Canyon"}
        s["npc;drop=227140"] = {"[Pyranis]", "Demon Fall Canyon"}
        s["npc;drop=227028"] = {"[Hellscream's Phantom]", "Demon Fall Canyon"}
        s["npc;drop=15204"] = {"High Marshal Whirlaxis", "Silithus"}
        s["npc;drop=218624"] = {"[Atal'alarion] <[Guardian of the Idol]>", "The Temple of Atal'Hakkar"}
        s["npc;drop=228430"] = {"[Magmadar]", "Molten Core"}
        s["npc;drop=228436"] = {"[Sulfuron Harbinger]", "Molten Core"}
        s["npc;drop=221943"] = {"[Hazzas]", "The Temple of Atal'Hakkar"}
        s["npc;drop=221407"] = {"[Dreamshadow Imp]", "Feralas"}
        s["npc;drop=230302"] = {"[Lord Kazzak]", "The Tainted Scar"}
        s["npc;sold=10857"] = {"Argent Quartermaster Lightspark", "Western Plaguelands"}
        s["npc;sold=218115"] = {"[Mai'zin] <[Gurubashi Bloodchanger]>", "Stranglethorn Vale"}
        s["npc;drop=204921"] = {"[Gelihast]", "Blackfathom Deeps"}
        s["npc;drop=202699"] = {"[Baron Aquanis]", "Blackfathom Deeps"}
        s["npc;drop=220007"] = {"[Viscous Fallout]", "Gnomeregan"}
        s["npc;drop=201722"] = {"[Ghamoo-ra]", "Blackfathom Deeps"}
        s["npc;drop=220072"] = {"[Electrocutioner 6000]", "Gnomeregan"}
        s["npc;drop=3669"] = {"Lord Cobrahn", "Wailing Caverns"}
        s["npc;drop=215728"] = {"[Crowd Pummeler 9-60]", "Gnomeregan"}
        s["npc;drop=218537"] = {"[Mekgineer Thermaplugg]", "Gnomeregan"}
        s["npc;drop=207356"] = {"[Lorgus Jett]", "Blackfathom Deeps"}
        s["npc;drop=218242"] = {"[STX-04/BD]", "Gnomeregan"}
        s["npc;drop=9056"] = {"Fineous Darkvire", "Blackrock Depths"}
        s["npc;drop=221394"] = {"[Avatar of Hakkar]", "The Temple of Atal'Hakkar"}
        s["npc;drop=228431"] = {"[Gehennas]", "Molten Core"}
        s["npc;drop=218571"] = {"[Shade of Eranikus]", "The Temple of Atal'Hakkar"}
        s["npc;drop=226922"] = {"[Zilbagob]", "Demon Fall Canyon"}
        s["npc;drop=9596"] = {"Bannok Grimaxe", "Blackrock Spire"}
        s["npc;drop=221391"] = {"[Slirena] <[Harpy Queen]>", "Feralas"}
        s["npc;drop=222573"] = {"[Delirious Ancient]", "Zul'Farrak"}
        s["npc;drop=10339"] = {"Gyth", "Blackrock Spire"}
        s["npc;sold=222685"] = {"[Quartermaster Kyleen]", "Ashenvale"}
        s["npc;drop=15305"] = {"Lord Skwol", "Silithus"}
        s["npc;drop=8127"] = {"Antu'sul", "Zul'Farrak"}
        s["npc;drop=227019"] = {"[Diathorus the Seeker]", "Demon Fall Canyon"}
        s["npc;drop=9818"] = {"Blackhand Summoner", "Blackrock Spire"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "Blasted Lands"}
        s["npc;drop=228914"] = {"[Severed Keeper]", "Demon Fall Canyon"}
        s["npc;drop=9817"] = {"Blackhand Dreadweaver", "Blackrock Spire"}
        s["npc;drop=203138"] = {"[Anvilrage Overseer]", "Blackrock Depths"}
        s["npc;drop=10318"] = {"Blackhand Assassin", "Blackrock Spire"}
        s["quest;reward=80455"] = {"[Biding Our Time]", "Silverpine Forest"}
        s["npc;drop=15209"] = {"Crimson Templar", "Silithus"}
        s["quest;reward=8623"] = {"Stormcaller's Diadem", "Ahn'Qiraj"}
        s["quest;reward=9011"] = {"Saving the Best for Last", "Orgrimmar"}
        s["quest;reward=7668"] = {"The Darkreaver Menace", "Orgrimmar"}
        s["quest;reward=8602"] = {"Stormcaller's Pauldrons", "Ahn'Qiraj"}
        s["quest;reward=8622"] = {"Stormcaller's Hauberk", "Ahn'Qiraj"}
        s["quest;reward=8918"] = {"An Earnest Proposition", "Orgrimmar"}
        s["quest;reward=8621"] = {"Stormcaller's Footguards", "Ahn'Qiraj"}
        s["quest;reward=7505"] = {"Frost Shock and You", "Dire Maul"}
        s["quest;reward=82113"] = {"[Da Voodoo]", "Alterac Mountains"}
        s["spell;created=461735"] = {"[Invincible Mail]", "CRAFTING"}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", "Orgrimmar"}
        s["spell;created=461737"] = {"[Tempest Gauntlets]", "CRAFTING"}
        s["spell;created=446186"] = {"[Cacophonous Chain Shoulderguards]", "CRAFTING"}
        s["spell;created=451706"] = {"[Screaming Chain Pauldrons]", "CRAFTING"}
        s["npc;drop=224257"] = {"[Atal'ai Slave]", "The Temple of Atal'Hakkar"}
        s["spell;created=435958"] = {"[Whirling Truesilver Gearwall]", "CRAFTING"}
        s["quest;reward=79366"] = {"[Calm Before the Storm]", "Thousand Needles"}
        s["quest;reward=8624"] = {"Stormcaller's Leggings", "Ahn'Qiraj"}
        s["quest;reward=7488"] = {"Lethtendris's Web", "Feralas"}
        s["quest;reward=5526"] = {"Shards of the Felvine", "Moonglade"}
        s["quest;reward=8662"] = {"Doomcaller's Circlet", "Ahn'Qiraj"}
        s["quest;reward=9005"] = {"Saving the Best for Last", "Ironforge"}
        s["quest;reward=8664"] = {"Doomcaller's Mantle", "Ahn'Qiraj"}
        s["quest;reward=8661"] = {"Doomcaller's Robes", "Ahn'Qiraj"}
        s["quest;reward=8936"] = {"Just Compensation", "Ironforge"}
        s["quest;reward=8381"] = {"Armaments of War", "Silithus"}
        s["quest;reward=7502"] = {"Harnessing Shadows", "Dire Maul"}
        s["spell;created=461747"] = {"[Incandescent Mooncloth Vest]", "CRAFTING"}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", "Ironforge"}
        s["spell;created=462282"] = {"[Embroidered Belt of the Archmage]", "CRAFTING"}
        s["npc;drop=15220"] = {"The Duke of Zephyrs", "Silithus"}
        s["spell;created=429351"] = {"[Extraplanar Spidersilk Boots]", "CRAFTING"}
        s["npc;drop=15203"] = {"Prince Skaldrenox", "Silithus"}
        s["spell;created=461743"] = {"[Sageblade of the Archmagus]", "CRAFTING"}
        s["spell;created=446195"] = {"[Shoulderpads of the Deranged]", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "Orgrimmar"}
        s["quest;reward=5942"] = {"Hidden Treasures", "Eastern Plaguelands"}
        s["quest;reward=1560"] = {"Tooga's Quest", "Tanaris"}
        s["npc;drop=15208"] = {"The Duke of Shards", "Silithus"}
        s["quest;reward=80141"] = {"[Nogg's Ring Redo]", "Orgrimmar"}
        s["quest;reward=82107"] = {"[Voodoo Feathers]", "Swamp of Sorrows"}
        s["quest;reward=3129"] = {"Weapons of Spirit", "Feralas"}
        s["quest;reward=84162"] = {"[An Earnest Proposition]", "Orgrimmar"}
        s["quest;reward=9006"] = {"Saving the Best for Last", "Ironforge"}
        s["quest;reward=8561"] = {"Conqueror's Crown", "Ahn'Qiraj"}
        s["quest;reward=8544"] = {"Conqueror's Spaulders", "Ahn'Qiraj"}
        s["quest;reward=8562"] = {"Conqueror's Breastplate", "Ahn'Qiraj"}
        s["quest;reward=8937"] = {"Just Compensation", "Ironforge"}
        s["quest;reward=8560"] = {"Conqueror's Legguards", "Ahn'Qiraj"}
        s["quest;reward=8559"] = {"Conqueror's Greaves", "Ahn'Qiraj"}
        s["quest;reward=9022"] = {"Anthion's Parting Words", "Scholomance"}
        s["spell;created=465699"] = {"[Clean Up Quel'Serrar SoD to Era [DNT]]", "CRAFTING"}
        s["quest;reward=8789"] = {"Imperial Qiraji Armaments", "Ahn'Qiraj"}
        s["quest;reward=3566"] = {"Rise, Obsidion!", "Searing Gorge"}
        s["quest;reward=84550"] = {"[Codex of Defense]", "Dire Maul"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "Blackwing Lair"}
        s["spell;created=469680"] = {"[Create Zul'Gurub Talisman DRU R4 DND]", "CRAFTING"}
        s["spell;created=469681"] = {"[Summon Haruspex's BP DND]", "CRAFTING"}
        s["spell;created=468559"] = {"[Punctured Voodoo Doll DRU DND]", "CRAFTING"}
        s["spell;created=452433"] = {"[Summon Gla'sir]", "CRAFTING"}
        s["spell;created=469682"] = {"[Summon Haruspex's Belt DND]", "CRAFTING"}
        s["npc;drop=231494"] = {"[Prince Thunderaan] <[The Wind Seeker]>", "The Crystal Vale"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "Stormwind City"}
        s["spell;created=452434"] = {"[Summon Rae'lar]", "CRAFTING"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "Demon Fall Canyon"}
        s["spell;created=461710"] = {"[Fiery Core Sharpshooter Rifle]", "CRAFTING"}
        s["spell;created=469746"] = {"[Create Zul'Gurub Talisman MAG R4 DND]", "CRAFTING"}
        s["spell;created=466117"] = {"[Attune Staff of Rime]", "CRAFTING"}
        s["spell;created=465417"] = {"[Change Stance]", "CRAFTING"}
        s["spell;created=465418"] = {"[Change Stance]", "CRAFTING"}
        s["npc;drop=227939"] = {"[The Molten Core]", "Molten Core"}
        s["spell;created=469730"] = {"[Summon Confessor's Mantle DND]", "CRAFTING"}
        s["spell;created=469732"] = {"[Summon Confessor's Bracers DND]", "CRAFTING"}
        s["spell;created=469731"] = {"[Summon Confessor's Belt DND]", "CRAFTING"}
        s["spell;created=469718"] = {"[Create Zul'Gurub Talisman PRT R4 DND]", "CRAFTING"}
        s["spell;created=468558"] = {"[Punctured Voodoo Doll PRT DND]", "CRAFTING"}
        s["spell;created=469754"] = {"[Create Zul'Gurub Talisman ROG R4 DND]", "CRAFTING"}
        s["spell;created=469759"] = {"[Summon Madcap's Mantle DND]", "CRAFTING"}
        s["spell;created=468560"] = {"[Punctured Voodoo Doll ROG DND]", "CRAFTING"}
        s["spell;created=469758"] = {"[Summon Madcap's BP DND]", "CRAFTING"}
        s["spell;created=469761"] = {"[Summon Madcap's Bracers DND]", "CRAFTING"}
        s["spell;created=469201"] = {"[Ignite Flames]", "CRAFTING"}
        s["spell;created=469733"] = {"[Create Zul'Gurub Talisman WLK R4 DND]", "CRAFTING"}
        s["spell;created=469736"] = {"[Summon Demoniac's Bracers DND]", "CRAFTING"}
        s["spell;created=468557"] = {"[Punctured Voodoo Doll WLK DND]", "CRAFTING"}
        s["spell;created=468840"] = {"[Combine Scythe of Chaos]", "CRAFTING"}
        s["spell;created=469735"] = {"[Summon Demoniac's Mantle DND]", "CRAFTING"}
        s["spell;created=469734"] = {"[Summon Demoniac's BP DND]", "CRAFTING"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Blackwing Lair"}
        s["spell;created=469684"] = {"[Create Zul'Gurub Talisman WAR R4 DND]", "CRAFTING"}
        s["spell;created=469685"] = {"[Summon Vindicator's BP DND]", "CRAFTING"}
        s["spell;created=469687"] = {"[Summon Vindicator's Armguards DND]", "CRAFTING"}
        s["spell;created=468552"] = {"[Punctured Voodoo Doll WAR DND]", "CRAFTING"}
        s["spell;created=467790"] = {"[Combine Staff of Order]", "CRAFTING"}
        s["spell;created=469743"] = {"[Summon Illusionist's Mantle DND]", "CRAFTING"}
        s["spell;created=469742"] = {"[Summon Illusionist's BP DND]", "CRAFTING"}
        s["spell;created=469744"] = {"[Summon Illusionist's Bracers DND]", "CRAFTING"}
        s["spell;created=468556"] = {"[Punctured Voodoo Doll MAG DND]", "CRAFTING"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "Alterac Mountains"}
        s["quest;reward=8183"] = {"The Heart of Hakkar", "Stranglethorn Vale"}
        s["quest;reward=7861"] = {"Wanted: Vile Priestess Hexx and Her Minions", "The Hinterlands"}
        s["quest;reward=8574"] = {"Stalwart's Battlegear", "Silithus"}
        s["quest;reward=8464"] = {"Winterfall Activity", "Winterspring"}
        s["quest;reward=8802"] = {"The Savior of Kalimdor", "Ahn'Qiraj"}
        s["quest;reward=4363"] = {"The Princess's Surprise", "Blackrock Depths"}
        s["quest;reward=4004"] = {"The Princess Saved?", "Blackrock Depths"}
        s["quest;reward=7491"] = {"For All To See", "Orgrimmar"}
        s["quest;reward=5102"] = {"General Drakkisath's Demise", "Burning Steppes"}
        s["quest;reward=8790"] = {"Imperial Qiraji Regalia", "Ahn'Qiraj"}
        s["quest;reward=82112"] = {"[A Better Ingredient]", "Un'Goro Crater"}
        s["quest;reward=7784"] = {"The Lord of Blackrock", "Orgrimmar"}
        s["quest;reward=3962"] = {"It's Dangerous to Go Alone", "Un'Goro Crater"}
        s["npc;sold=227819"] = {"[Duke Hydraxis]", "Molten Core"}
        s["spell;created=446192"] = {"[Membrane of Dark Neurosis]", "CRAFTING"}
        s["spell;created=461653"] = {"[Brilliant Chromatic Cloak]", "CRAFTING"}
        s["quest;reward=84147"] = {"[An Earnest Proposition]", "Ironforge"}
        s["spell;created=429869"] = {"[Void-Touched Leather Gauntlets]", "CRAFTING"}
        s["spell;created=461754"] = {"[Girdle of Arcane Insight]", "CRAFTING"}
        s["spell;created=461647"] = {"[Skyrider's Masterwork Stormhammer]", "CRAFTING"}
        s["spell;created=439105"] = {"[Big Voodoo Mask]", "CRAFTING"}
        s["spell;created=439093"] = {"[Crimson Silk Shoulders]", "CRAFTING"}
        s["quest;reward=82055"] = {"[Darkmoon Dunes Deck]", "Elwynn Forest"}
        s["quest;reward=82057"] = {"[Darkmoon Plagues Deck]", "Elwynn Forest"}
        s["quest;reward=7940"] = {"1200 Tickets - Orb of the Darkmoon", "Mulgore"}
        s["quest;reward=4261"] = {"Ancient Spirit", "Felwood"}
        s["quest;reward=5068"] = {"Breastplate of Bloodthirst", "Winterspring"}
        s["quest;reward=7981"] = {"1200 Tickets - Amulet of the Darkmoon", "Mulgore"}
        s["quest;reward=7862"] = {"Job Opening: Guard Captain of Revantusk Village", "The Hinterlands"}
        s["quest;reward=3321"] = {"Did You Lose This?", "Tanaris"}
        s["quest;reward=7877"] = {"The Treasure of the Shen'dralar", "Dire Maul"}
        s["spell;created=460462"] = {"[Eye of Sulfuras]", "CRAFTING"}
        s["quest;reward=84561"] = {"[For All To See]", "Orgrimmar"}
        s["quest;reward=5944"] = {"In Dreams", "Western Plaguelands"}
        s["quest;reward=8949"] = {"Falrin's Vendetta", "Dire Maul"}
        s["npc;sold=12944"] = {"Lokhtos Darkbargainer", "Blackrock Depths"}
        s["spell;created=461712"] = {"[Refined Hammer of the Titans]", "CRAFTING"}
        s["spell;created=461722"] = {"[Devilcore Gauntlets]", "CRAFTING"}
        s["spell;created=461724"] = {"[Devilcore Leggings]", "CRAFTING"}
        s["quest;reward=84545"] = {"[A Hero's Reward]", "Azshara"}
        s["quest;reward=9120"] = {"The Fall of Kel'Thuzad", "Eastern Plaguelands"}
        s["quest;reward=7067"] = {"The Pariah's Instructions", "Desolace"}
        s["quest;reward=8573"] = {"Champion's Battlegear", "Silithus"}
        s["spell;created=461690"] = {"[Mastercrafted Shifting Cloak]", "CRAFTING"}
        s["spell;created=435904"] = {"[Glowing Gneuro-Linked Cowl]", "CRAFTING"}
        s["quest;reward=80324"] = {"[The Mad King]", "Ironforge"}
        s["npc;sold=217689"] = {"[Ziri 'The Wrench' Littlesprocket] <[Gearhead]>", "Gnomeregan"}
        s["spell;created=429354"] = {"[Void-Touched Leather Gloves]", "CRAFTING"}
        s["quest;reward=824"] = {"Je'neu of the Earthen Ring", "Ashenvale"}
        s["quest;reward=80132"] = {"[Rig Wars]", "Orgrimmar"}
        s["quest;reward=7541"] = {"Service to the Horde", "Orgrimmar"}
        s["quest;reward=78916"] = {"[The Heart of the Void]", "Darnassus"}
        s["quest;reward=2767"] = {"Rescue OOX-22/FE!", "Feralas"}
        s["quest;reward=793"] = {"Broken Alliances", "Badlands"}
        s["spell;created=435960"] = {"[Hyperconductive Goldwap]", "CRAFTING"}
        s["quest;reward=7506"] = {"The Emerald Dream...", "Dire Maul"}
        s["quest;reward=8791"] = {"The Fall of Ossirian", "Silithus"}
        s["quest;reward=7907"] = {"Darkmoon Beast Deck", "Elwynn Forest"}
        s["spell;created=461750"] = {"[Incandescent Mooncloth Circlet]", "CRAFTING"}
        s["spell;created=446189"] = {"[Shoulderpads of Obsession]", "CRAFTING"}
        s["spell;created=446194"] = {"[Mantle of Insanity]", "CRAFTING"}
        s["quest;reward=80325"] = {"[The Mad King]", "Orgrimmar"}
        s["quest;reward=82081"] = {"[A Broken Ritual]", "Stranglethorn Vale"}
        s["quest;reward=82058"] = {"[Darkmoon Wilds Deck]", "Elwynn Forest"}
        s["quest;reward=9008"] = {"Saving the Best for Last", "Orgrimmar"}
        s["quest;reward=4024"] = {"A Taste of Flame", "Burning Steppes"}
        s["quest;reward=8906"] = {"An Earnest Proposition", "Ironforge"}
        s["quest;reward=8938"] = {"Just Compensation", "Orgrimmar"}
        s["quest;reward=8952"] = {"Anthion's Parting Words", "Blackrock Spire"}
        s["quest;reward=5125"] = {"Aurius' Reckoning", "Stratholme"}
        s["quest;reward=7503"] = {"The Greatest Race of Hunters", "Dire Maul"}
        s["quest;reward=82108"] = {"[The Green Drake]", "The Temple of Atal'Hakkar"}
        s["spell;created=462623"] = {"[Forming Rhok'delar]", "CRAFTING"}
        s["quest;reward=82104"] = {"[Jammal'an the Prophet]", "The Hinterlands"}
        s["quest;reward=84148"] = {"[An Earnest Proposition]", "Ironforge"}
        s["spell;created=446237"] = {"[Void-Powered Slayer's Vambraces]", "CRAFTING"}
        s["quest;reward=7029"] = {"Vyletongue Corruption", "Desolace"}
        s["spell;created=462630"] = {"[Create Hunter Epic Staff DND]", "CRAFTING"}
        s["spell;created=461675"] = {"[Refined Arcanite Reaper]", "CRAFTING"}
        s["quest;reward=8272"] = {"Hero of the Frostwolf", "Alterac Mountains"}
        s["quest;reward=3636"] = {"Bring the Light", "Stormwind City"}
        s["quest;reward=1364"] = {"Mazen's Behest", "Stormwind City"}
        s["quest;reward=628"] = {"Excelsior", "Stranglethorn Vale"}
        s["quest;reward=7068"] = {"Shadowshard Fragments", "Orgrimmar"}
        s["quest;reward=2822"] = {"The Mark of Quality", "Feralas"}
        s["quest;reward=1048"] = {"Into The Scarlet Monastery", "Scarlet Monastery"}
        s["spell;created=435953"] = {"[Rad-Resistant Scale Hood]", "CRAFTING"}
        s["quest;reward=8632"] = {"Enigma Circlet", "Ahn'Qiraj"}
        s["quest;reward=8625"] = {"Enigma Shoulderpads", "Ahn'Qiraj"}
        s["quest;reward=8633"] = {"Enigma Robes", "Ahn'Qiraj"}
        s["quest;reward=8634"] = {"Enigma Boots", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "Ironforge"}
        s["quest;reward=84157"] = {"[An Earnest Proposition]", "Orgrimmar"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "Dire Maul"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", "Stratholme"}
        s["quest;reward=84165"] = {"[Just Compensation]", "Ironforge"}
        s["quest;reward=82095"] = {"[The God Hakkar]", "Tanaris"}
        s["quest;reward=8932"] = {"Just Compensation", "Ironforge"}
        s["quest;reward=617"] = {"Akiris by the Bundle", "Stranglethorn Vale"}
        s["spell;created=446236"] = {"[Void-Powered Invoker's Vambraces]", "CRAFTING"}
        s["quest;reward=3907"] = {"Disharmony of Fire", "Badlands"}
        s["quest;reward=8366"] = {"Southsea Shakedown", "Tanaris"}
        s["quest;reward=7501"] = {"The Light and How To Swing It", "Dire Maul"}
        s["spell;created=446191"] = {"[Baleful Pauldrons]", "CRAFTING"}
        s["spell;created=446190"] = {"[Wailing Chain Mantle]", "CRAFTING"}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", "Ironforge"}
        s["spell;created=435906"] = {"[Reflective Truesilver Braincage]", "CRAFTING"}
        s["spell;created=435949"] = {"[Glowing Hyperconductive Scale Coif]", "CRAFTING"}
        s["spell;created=435610"] = {"[Gneuro-Linked Arcano-Filament Monocle]", "CRAFTING"}
        s["quest;reward=80131"] = {"[Gnome Improvement]", "Ironforge"}
        s["spell;created=465693"] = {"[Clean Up Quel'Serrar Era to SoD [DNT]]", "CRAFTING"}
        s["spell;created=461730"] = {"[Hardened Frostguard]", "CRAFTING"}
        s["spell;created=461669"] = {"[Refined Arcanite Champion]", "CRAFTING"}
        s["quest;reward=7065"] = {"Corruption of Earth and Seed", "Desolace"}
        s["spell;created=435908"] = {"[Tempered Interference-Negating Helmet]", "CRAFTING"}
        s["spell;created=446179"] = {"[Shoulderplates of Dread]", "CRAFTING"}
        s["quest;reward=5166"] = {"Breastplate of the Chromatic Flight", "Western Plaguelands"}
        s["spell;created=446238"] = {"[Void-Powered Protector's Vambraces]", "CRAFTING"}
        s["spell;created=461671"] = {"[Stronger-hold Gauntlets]", "CRAFTING"}
        s["quest;reward=5081"] = {"Maxwell's Mission", "Blackrock Spire"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "Eastern Plaguelands"}
        s["spell;created=461718"] = {"[Tranquility]", "CRAFTING"}
        s["spell;created=461651"] = {"[Fiery Plate Gauntlets of the Hidden Technique]", "CRAFTING"}
        s["quest;reward=8572"] = {"Veteran's Battlegear", "Silithus"}
        s["spell;created=460460"] = {"[Sulfuron Hammer]", "CRAFTING"}
        s["spell;created=450409"] = {"[Call of Sul'thraze]", "CRAFTING"}
        s["spell;created=461714"] = {"[Desecration]", "CRAFTING"}
        s["quest;reward=9009"] = {"Saving the Best for Last", "Orgrimmar"}
        s["quest;reward=8909"] = {"An Earnest Proposition", "Ironforge"}
        s["quest;reward=8940"] = {"Just Compensation", "Orgrimmar"}
        s["quest;reward=9019"] = {"Anthion's Parting Words", "Blackrock Spire"}
        s["quest;reward=7504"] = {"Holy Bologna: What the Light Won't Tell You", "Dire Maul"}
        s["quest;reward=82111"] = {"[Blood of Morphaz]", "Azshara"}
        s["spell;created=463008"] = {"[Balance of Light and Shadow]", "CRAFTING"}
        s["spell;created=461708"] = {"[Incandescent Mooncloth Robe]", "CRAFTING"}
        s["quest;reward=84151"] = {"[An Earnest Proposition]", "Ironforge"}
        s["spell;created=461752"] = {"[Incandescent Mooncloth Leggings]", "CRAFTING"}
        s["quest;reward=55"] = {"Morbent Fel", "Duskwood"}
        s["spell;created=446193"] = {"[Fractured Mind Pauldrons]", "CRAFTING"}
        s["quest;reward=9225"] = {"Epic Armaments of Battle - Revered Amongst the Dawn", "Eastern Plaguelands"}
        s["quest;reward=9221"] = {"Superior Armaments of Battle - Friend of the Dawn", "Eastern Plaguelands"}
        s["quest;reward=8592"] = {"Tiara of the Oracle", "Ahn'Qiraj"}
        s["quest;reward=8594"] = {"Mantle of the Oracle", "Ahn'Qiraj"}
        s["quest;reward=8603"] = {"Vestments of the Oracle", "Ahn'Qiraj"}
        s["spell;created=461962"] = {"[Call Anathema]", "CRAFTING"}
        s["quest;reward=9004"] = {"Saving the Best for Last", "Ironforge"}
        s["quest;reward=8956"] = {"Anthion's Parting Words", "Ironforge"}
        s["quest;reward=8910"] = {"An Earnest Proposition", "Ironforge"}
        s["quest;reward=8941"] = {"Just Compensation", "Orgrimmar"}
        s["quest;reward=8639"] = {"Deathdealer's Helm", "Ahn'Qiraj"}
        s["quest;reward=8641"] = {"Deathdealer's Spaulders", "Ahn'Qiraj"}
        s["quest;reward=8638"] = {"Deathdealer's Vest", "Ahn'Qiraj"}
        s["quest;reward=8201"] = {"A Collection of Heads", "Stranglethorn Vale"}
        s["quest;reward=8640"] = {"Deathdealer's Leggings", "Ahn'Qiraj"}
        s["quest;reward=8637"] = {"Deathdealer's Boots", "Ahn'Qiraj"}
        s["quest;reward=7498"] = {"Garona: A Study on Stealth and Treachery", "Dire Maul"}
        s["quest;reward=7787"] = {"Rise, Thunderfury!", "Silithus"}
        s["spell;created=461237"] = {"[Shadowflame Skull]", "CRAFTING"}
        s["quest;reward=84152"] = {"[An Earnest Proposition]", "Ironforge"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "Dire Maul"}
        s["quest;reward=53"] = {"Sweet Amber", "Westfall"}
        s["quest;reward=85454"] = {"[A Just Reward]", "Wetlands"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "Silithus"}
        s["spell;created=1216020"] = {"[Idol of Sidereal Wrath]", "CRAFTING"}
        s["spell;created=469683"] = {"[Summon Haruspex's Bracers DND]", "CRAFTING"}
        s["npc;drop=235197"] = {"[Taerar]", "Ashenvale"}
        s["spell;created=1213595"] = {"[Tear of the Dreamer]", "CRAFTING"}
        s["spell;created=1213502"] = {"[Obsidian Stormhammer]", "CRAFTING"}
        s["spell;created=1216340"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1216022"] = {"[Idol of Feline Ferocity]", "CRAFTING"}
        s["npc;drop=228230"] = {"[Harrigen] <[The Undermarket]>", "Burning Steppes"}
        s["spell;created=1213536"] = {"[Qiraji Silk Cape]", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "Silithus"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "Silithus"}
        s["spell;created=1213593"] = {"[Speedstone]", "CRAFTING"}
        s["spell;created=1216385"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213500"] = {"[Obsidian Destroyer]", "CRAFTING"}
        s["spell;created=1216024"] = {"[Idol of Ursin Power]", "CRAFTING"}
        s["spell;created=1213738"] = {"[Bramblewood Helm]", "CRAFTING"}
        s["spell;created=1213736"] = {"[Bramblewood Boots]", "CRAFTING"}
        s["spell;created=1213598"] = {"[Lodestone of Retaliation]", "CRAFTING"}
        s["spell;created=1216366"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213521"] = {"[Razorbramble Cowl]", "CRAFTING"}
        s["spell;created=1213525"] = {"[Razorbramble Leathers]", "CRAFTING"}
        s["spell;created=1213523"] = {"[Razorbramble Shoulderpads]", "CRAFTING"}
        s["spell;created=1213603"] = {"[Ruby-Encrusted Broach]", "CRAFTING"}
        s["spell;created=1216319"] = {"[Void-Touched]", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "Silithus"}
        s["spell;created=1213635"] = {"[Enchanted Mushroom]", "CRAFTING"}
        s["spell;created=1213540"] = {"[Qiraji Silk Drape]", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "The Hinterlands"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "Silithus"}
        s["quest;reward=86674"] = {"[The Perfect Poison]", "Silithus"}
        s["spell;created=1216365"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=468563"] = {"[Punctured Voodoo Doll HUN DND]", "CRAFTING"}
        s["spell;created=469772"] = {"[Create Zul'Gurub Talisman HUN R4 DND]", "CRAFTING"}
        s["spell;created=469775"] = {"[Summon Predator's Belt DND]", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Un'Goro Crater"}
        s["spell;created=1216384"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1216387"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1216327"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=466116"] = {"[Attune Staff of Inferno]", "CRAFTING"}
        s["spell;created=1213628"] = {"[Enchanted Prayer Tome]", "CRAFTING"}
        s["quest;reward=86672"] = {"[Imperial Qiraji Armaments]", "Blackwing Lair"}
        s["spell;created=1216005"] = {"[Libram of Righteousness]", "CRAFTING"}
        s["spell;created=1213481"] = {"[Razorspike Headcage]", "CRAFTING"}
        s["spell;created=1213484"] = {"[Razorspike Shoulderplate]", "CRAFTING"}
        s["spell;created=1214884"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213588"] = {"[Tuned Force Reactive Disk]", "CRAFTING"}
        s["spell;created=1214270"] = {"[Jagged Obsidian Shield]", "CRAFTING"}
        s["spell;created=1213490"] = {"[Razorspike Battleplate]", "CRAFTING"}
        s["spell;created=1213506"] = {"[Obsidian Defender]", "CRAFTING"}
        s["spell;created=1216379"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1216007"] = {"[Libram of the Exorcist]", "CRAFTING"}
        s["spell;created=1216382"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213534"] = {"[Qiraji Silk Scarf]", "CRAFTING"}
        s["spell;created=1216375"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213492"] = {"[Obsidian Reaver]", "CRAFTING"}
        s["spell;created=1216377"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213498"] = {"[Obsidian Champion]", "CRAFTING"}
        s["quest;reward=86671"] = {"[Imperial Qiraji Regalia]", "Blackwing Lair"}
        s["npc;drop=234880"] = {"[Emeriss]", "Duskwood"}
        s["spell;created=469677"] = {"[Summon Augur's BP DND]", "CRAFTING"}
        s["spell;created=469679"] = {"[Summon Augur's Bracers DND]", "CRAFTING"}
        s["spell;created=469678"] = {"[Summon Augur's Belt DND]", "CRAFTING"}
        s["spell;created=469676"] = {"[Create Zul'Gurub Talisman SHM R4 DND]", "CRAFTING"}
        s["spell;created=468555"] = {"[Punctured Voodoo Doll SHM DND]", "CRAFTING"}
        s["spell;created=1216354"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1216014"] = {"[Totem of Pyroclastic Thunder]", "CRAFTING"}
        s["spell;created=1213742"] = {"[Sylvan Crown]", "CRAFTING"}
        s["spell;created=1213740"] = {"[Sylvan Shoulders]", "CRAFTING"}
        s["spell;created=1213744"] = {"[Sylvan Vest]", "CRAFTING"}
        s["spell;created=1214306"] = {"[Dreamscale Bracers]", "CRAFTING"}
        s["spell;created=1214307"] = {"[Dreamscale Mitts]", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "Feralas"}
        s["quest;reward=9248"] = {"A Humble Offering", "Silithus"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "Blackwing Lair"}
        s["spell;created=1213532"] = {"[Vampiric Robe]", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "Blackwing Lair"}
        s["spell;created=1216372"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213538"] = {"[Qiraji Silk Cloak]", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "Silithus"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"[Darkmoon Beast Deck]", "Elwynn Forest"}
        s["quest;reward=86762"] = {"[Darkmoon Elementals Deck]", "Elwynn Forest"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Moonglade"}
        s["spell;created=1214303"] = {"[Dreamscale Kilt]", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "Winterspring"}
        s["npc;drop=3975"] = {"Herod", "Scarlet Monastery"}
        s["spell;created=1216364"] = {"[Void-Touched]", "CRAFTING"}
        s["spell;created=1213633"] = {"[Enchanted Totem]", "CRAFTING"}
        s["spell;created=1216381"] = {"[Void-Touched]", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne", "Eastern Plaguelands"}
        s["quest;reward=87360"] = {"[The Fall of Kel'Thuzad]", "Eastern Plaguelands"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "Karazhan Crypts"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "Eastern Plaguelands"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "Karazhan Crypts"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Eastern Plaguelands"}
        s["npc;drop=237439"] = {"[Kharon]", "Karazhan Crypts"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "Eastern Plaguelands"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "Karazhan Crypts"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "Karazhan Crypts"}
        s["spell;created=1223762"] = {"[Glacial Cloak]", "CRAFTING"}
        s["npc;drop=238055"] = {"[Dark Rider]", "Karazhan Crypts"}
        s["npc;drop=238560"] = {"[The Warden]", "Karazhan Crypts"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "Karazhan Crypts"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "Karazhan Crypts"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "Eastern Plaguelands"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "Karazhan Crypts"}
        s["npc;sold=16132"] = {"Huntsman Leopold", "Eastern Plaguelands"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "Eastern Plaguelands"}
        s["npc;sold=16116"] = {"Archmage Angela Dosantos", "Eastern Plaguelands"}
        s["npc;sold=16115"] = {"Commander Eligor Dawnbringer", "Eastern Plaguelands"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "Eastern Plaguelands"}
        s["spell;created=1223787"] = {"[Icebane Breastplate]", "CRAFTING"}
        s["spell;created=1223791"] = {"[Icebane Bracers]", "CRAFTING"}
        s["spell;created=1223789"] = {"[Icebane Gauntlets]", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Eastern Plaguelands"}
        s["spell;created=1223780"] = {"[Polar Tunic]", "CRAFTING"}
        s["spell;created=1223784"] = {"[Polar Bracers]", "CRAFTING"}
        s["spell;created=1223782"] = {"[Polar Gloves]", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "Tanaris"}
        s["npc;sold=16113"] = {"Father Inigo Montoy", "Eastern Plaguelands"}
        s["spell;created=1223760"] = {"[Glacial Vest]", "CRAFTING"}
        s["spell;created=1223764"] = {"[Glacial Gloves]", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan the Assassin", "Eastern Plaguelands"}
        s["spell;created=1214137"] = {"[Obsidian Heartseeker]", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Earthshatter", "Eastern Plaguelands"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "Karazhan Crypts"}
        s["spell;created=1223766"] = {"[Glacial Wrists]", "CRAFTING"}
        s["spell;created=1223772"] = {"[Frosty Wrists]", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus the Wrathcaster", "Eastern Plaguelands"}
        s["spell;created=1213504"] = {"[Obsidian Sageblade]", "CRAFTING"}
        s["spell;created=1213527"] = {"[Vampiric Cowl]", "CRAFTING"}
        s["spell;created=1213530"] = {"[Vampiric Shawl]", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax, Champion of the Light", "Eastern Plaguelands"}
        s["spell;created=1214145"] = {"[Obsidian Shotgun]", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Eastern Plaguelands"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
    end

    function SpecBisTooltip:TranslationkoKR()
        s["npc;drop=11583"] = {"네파리안", "검은날개 둥지"}
        s["npc;drop=11502"] = {"라그나로스", "화산 심장부"}
        s["npc;drop=12435"] = {"폭군 서슬송곳니", "검은날개 둥지"}
        s["npc;drop=14834"] = {"학카르", "줄구룹"}
        s["spell;created=24091"] = {"붉은덩굴 조끼", "CRAFTING"}
        s["npc;drop=12017"] = {"용기대장 래쉬레이어", "검은날개 둥지"}
        s["npc;drop=11380"] = {"주술사 진도", "줄구룹"}
        s["npc;drop=11983"] = {"화염아귀", "검은날개 둥지"}
        s["spell;created=24092"] = {"붉은덩굴 다리보호구", "CRAFTING"}
        s["spell;created=24093"] = {"붉은덩굴 장화", "CRAFTING"}
        s["npc;drop=12098"] = {"설퍼론 사자", "화산 심장부"}
        s["npc;drop=14601"] = {"에본로크", "검은날개 둥지"}
        s["quest;reward=8183"] = {"학카르의 심장", "가시덤불 골짜기"}
        s["npc;sold=13217"] = {"산살디스 스노우글림 <스톰파이크 병참장교>", "알터랙 산맥"}
        s["npc;drop=10363"] = {"사령관 드라키사스", "검은바위 첨탑"}
        s["npc;drop=10435"] = {"집정관 발실라스", "스트라솔름"}
        s["spell;created=12622"] = {"녹색 렌즈", "CRAFTING"}
        s["spell;created=12092"] = {"꿈매듭 머리장식", "CRAFTING"}
        s["npc;drop=11261"] = {"학자 테올렌 크라스티노브 <도살자>", "스칼로맨스"}
        s["npc;sold=12777"] = {"대장 더지해머 <방어구 병참장교>", "아라시 분지"}
        s["npc;sold=12792"] = {"여군주 팔란시어", "아라시 분지"}
        s["npc;drop=9018"] = {"대심문관 게르스탄 <황혼의 망치단 심문관>", "검은바위 나락"}
        s["npc;drop=14353"] = {"약삭빠른 미즐", "혈투의 전장"}
        s["npc;drop=10811"] = {"기록관 갈포드", "스트라솔름"}
        s["npc;drop=15727"] = {"쑨", "안퀴라즈"}
        s["npc;drop=9319"] = {"사냥개조련사 그렙마르", "검은바위 나락"}
        s["npc;drop=11487"] = {"마술사 칼렌드리스", "혈투의 전장"}
        s["npc;sold=13218"] = {"그룬다 울프하트 <서리늑대 병참장교>", "알터랙 계곡"}
        s["quest;reward=7861"] = {"현상수배: 타락한 여사제 헥스와 그녀의 부하", "동부 내륙지"}
        s["npc;drop=12118"] = {"루시프론", "화산 심장부"}
        s["npc;drop=11496"] = {"이몰타르", "혈투의 전장"}
        s["npc;drop=11486"] = {"왕자 토르텔드린", "혈투의 전장"}
        s["npc;drop=15815"] = {"퀴라지 부대장 카르크", "버섯구름 봉우리"}
        s["npc;drop=10508"] = {"라스 프로스트위스퍼", "스칼로맨스"}
        s["npc;sold=14753"] = {"일리야나 문블레이즈 <은빛날개 병참장교>", "잿빛 골짜기"}
        s["quest;reward=8574"] = {"신념의 전투장비", "실리더스"}
        s["npc;drop=9017"] = {"불의군주 인센디우스", "검은바위 나락"}
        s["npc;drop=10516"] = {"용서받지 못한 자", "스트라솔름"}
        s["npc;drop=14326"] = {"경비병 몰다르", "혈투의 전장"}
        s["npc;drop=11662"] = {"불꽃꼬리일족 사제", "화산 심장부"}
        s["npc;drop=12397"] = {"군주 카자크", "저주받은 땅"}
        s["npc;drop=10584"] = {"우로크 둠하울", "검은바위 첨탑"}
        s["npc;drop=14020"] = {"크로마구스", "검은날개 둥지"}
        s["npc;drop=9736"] = {"병참장교 지그리스 <도끼 부대>", "검은바위 첨탑"}
        s["quest;reward=8464"] = {"눈사태일족의 동태", "여명의 설원"}
        s["npc;drop=5719"] = {"몰파즈", "아탈학카르 신전"}
        s["spell;created=12067"] = {"꿈매듭 장갑", "CRAFTING"}
        s["npc;drop=12056"] = {"남작 게돈", "화산 심장부"}
        s["npc;drop=9030"] = {"파괴자 오크토르", "검은바위 나락"}
        s["npc;sold=13219"] = {"제킬 플랜드링 <서리늑대 병참장교>", "알터랙 산맥"}
        s["spell;created=3864"] = {"별장식 허리띠", "CRAFTING"}
        s["npc;drop=10437"] = {"네룹엔칸", "스트라솔름"}
        s["npc;drop=12119"] = {"불꽃꼬리일족 수호병", "화산 심장부"}
        s["npc;drop=9196"] = {"대군주 오모크", "검은바위 첨탑"}
        s["npc;drop=6109"] = {"아주어고스", "아즈샤라"}
        s["spell;created=23667"] = {"화염핵 다리보호구", "CRAFTING"}
        s["npc;drop=7267"] = {"족장 우코르즈 샌드스칼프", "줄파락"}
        s["npc;drop=8983"] = {"골렘 군주 아젤마크", "검은바위 나락"}
        s["npc;drop=15276"] = {"제왕 베클로어", "안퀴라즈"}
        s["npc;drop=13280"] = {"히드로스폰", "혈투의 전장"}
        s["npc;drop=10429"] = {"대족장 렌드 블랙핸드", "검은바위 첨탑"}
        s["npc;drop=10997"] = {"포병대장 윌리", "스트라솔름"}
        s["npc;drop=10812"] = {"십자군사령관 다스로한", "스트라솔름"}
        s["npc;drop=15275"] = {"제왕 베크닐라쉬", "안퀴라즈"}
        s["npc;drop=15742"] = {"아쉬 거대괴수", "실리더스"}
        s["npc;drop=16042"] = {"군주 발타라크", "검은바위 첨탑"}
        s["quest;reward=8802"] = {"칼림도어의 구세주", "안퀴라즈"}
        s["quest;reward=4363"] = {"브론즈비어드 공주", "검은바위 나락"}
        s["quest;reward=4004"] = {"구출된 공주?", "검은바위 나락"}
        s["quest;reward=7491"] = {"승리의 축제", "오그리마"}
        s["npc;sold=14754"] = {"켈름 하건스 <전쟁노래 병참장교>", "불모의 땅"}
        s["npc;drop=11982"] = {"마그마다르", "화산 심장부"}
        s["npc;drop=10509"] = {"제드 룬와처 <검은손 부대>", "검은바위 첨탑"}
        s["quest;reward=5102"] = {"사령관 드라키사스 처치", "불타는 평원"}
        s["npc;drop=9156"] = {"사자 화염채찍", "검은바위 나락"}
        s["npc;sold=12782"] = {"대장 오닐 <무기 병참장교>", "아라시 분지"}
        s["npc;sold=14581"] = {"하사관 썬더혼", "아라시 분지"}
        s["npc;sold=15126"] = {"러더퍼드 트윙 <파멸단 병참장교>", "아라시 고원"}
        s["npc;sold=15127"] = {"사무엘 호키 <아라소르 연맹 병참장교>", "아라시 고원"}
        s["npc;drop=12057"] = {"가르", "화산 심장부"}
        s["npc;drop=12259"] = {"게헨나스", "화산 심장부"}
        s["npc;drop=1853"] = {"암흑스승 간들링", "스칼로맨스"}
        s["npc;drop=10899"] = {"고랄루크 앤빌크랙 <검은손 부대 갑옷제작자>", "검은바위 첨탑"}
        s["npc;drop=11492"] = {"칼날바람 알진", "혈투의 전장"}
        s["quest;reward=8790"] = {"제국의 퀴라지 표장", "안퀴라즈"}
        s["npc;drop=11988"] = {"초열의 골레마그", "화산 심장부"}
        s["npc;drop=2585"] = {"스트롬가드 성기사", "아라시 고원"}
        s["quest;reward=82112"] = {"더욱 강력한 재료", "운고로 분화구"}
        s["npc;drop=7271"] = {"의술사 줌라", "줄파락"}
        s["npc;drop=8440"] = {"학카르의 사령", "아탈학카르 신전"}
        s["npc;drop=5721"] = {"드림사이드", "아탈학카르 신전"}
        s["object;contained=181083"] = {"소도스와 자리엔의 가보", "스트라솔름"}
        s["quest;reward=7784"] = {"검은바위부족의 군주", "오그리마"}
        s["quest;reward=3962"] = {"혼자서 가기 무서운 곳", "운고로 분화구"}
        s["npc;drop=4543"] = {"혈법사 탈노스", "붉은십자군 수도원"}
        s["npc;sold=227819"] = {"군주 히드락시스", "화산 심장부"}
        s["npc;drop=228435"] = {"초열의 골레마그", "화산 심장부"}
        s["npc;sold=230319"] = {"델리아나", "아이언포지"}
        s["npc;drop=228438"] = {"라그나로스", "화산 심장부"}
        s["npc;drop=228432"] = {"가르", "화산 심장부"}
        s["npc;sold=227853"] = {"픽스 시직스 <언더마인 무역상>", "가시덤불 골짜기"}
        s["spell;created=446192"] = {"어두운 공포의 막", "CRAFTING"}
        s["npc;drop=15205"] = {"남작 카줌", "실리더스"}
        s["spell;created=461653"] = {"찬란한 오색 망토", "CRAFTING"}
        s["npc;drop=228434"] = {"샤즈라", "화산 심장부"}
        s["npc;sold=222413"] = {"탐험가 잘고 <잊힌 상품 조달자>", "가시덤불 골짜기"}
        s["quest;reward=84147"] = {"진지한 제안", "아이언포지"}
        s["npc;drop=218819"] = {"곪아가는 부식수액", "아탈학카르 신전"}
        s["spell;created=429869"] = {"공허에 물든 가죽 건틀릿", "CRAFTING"}
        s["npc;drop=220833"] = {"드림사이드", "아탈학카르 신전"}
        s["npc;sold=222408"] = {"어둠이빨 사절", "악령의 숲"}
        s["spell;created=461754"] = {"비전 통찰의 요대", "CRAFTING"}
        s["npc;drop=228433"] = {"남작 게돈", "화산 심장부"}
        s["object;contained=179703"] = {"불의 군주의 보물", "화산 심장부"}
        s["npc;drop=228429"] = {"루시프론", "화산 심장부"}
        s["npc;drop=14890"] = {"타에라", "그늘숲"}
        s["npc;drop=226923"] = {"암울뿌리 <애도하는 수호자>", "악마벼락 협곡"}
        s["npc;drop=12201"] = {"공주 테라드라스", "마라우돈"}
        s["npc;drop=217280"] = {"그루비스", "놈리건"}
        s["spell;created=461647"] = {"하늘기수의 명인의 폭풍망치", "CRAFTING"}
        s["npc;drop=4542"] = {"종교재판관 페어뱅크스", "붉은십자군 수도원"}
        s["npc;drop=204068"] = {"여왕 사레베스", "검은심연의 나락"}
        s["spell;created=12060"] = {"붉은 마법매듭 바지", "CRAFTING"}
        s["npc;drop=213334"] = {"아쿠마이", "검은심연의 나락"}
        s["spell;created=439105"] = {"부두교 가면", "CRAFTING"}
        s["npc;drop=6490"] = {"잠들지 않는 아즈쉬르", "붉은십자군 수도원"}
        s["spell;created=439093"] = {"심홍색 비단 어깨보호구", "CRAFTING"}
        s["quest;reward=82055"] = {"다크문 사막 카드 한 벌", "엘윈 숲"}
        s["quest;reward=82057"] = {"다크문 역병 카드 한 벌", "엘윈 숲"}
        s["npc;drop=221637"] = {"게이셔", "아탈학카르 신전"}
        s["quest;reward=7940"] = {"상품권 1200매 - 다크문의 보주", "멀고어"}
        s["npc;drop=218721"] = {"예언자 잠말란", "아탈학카르 신전"}
        s["npc;sold=11557"] = {"메일로쉬", "악령의 숲"}
        s["spell;created=10621"] = {"늑대머리 투구", "CRAFTING"}
        s["npc;drop=9816"] = {"불의수호자 엠버시어", "검은바위 첨탑"}
        s["npc;drop=12467"] = {"죽음의발톱 부대장", "검은날개 둥지"}
        s["spell;created=23710"] = {"작열의 허리띠", "CRAFTING"}
        s["npc;drop=11981"] = {"플레임고르", "검은날개 둥지"}
        s["npc;drop=6229"] = {"고철 압축기 9-60", "놈리건"}
        s["npc;drop=15206"] = {"불꽃의 군주 <심연의 의회>", "실리더스"}
        s["npc;drop=9041"] = {"문지기 스틸기스", "검은바위 나락"}
        s["quest;reward=4261"] = {"고대의 정령", "악령의 숲"}
        s["npc;drop=10440"] = {"남작 리븐데어", "스트라솔름"}
        s["npc;drop=15511"] = {"군주 크리", "안퀴라즈"}
        s["quest;reward=5068"] = {"핏빛갈증의 흉갑", "여명의 설원"}
        s["npc;drop=9019"] = {"제왕 다그란 타우릿산", "검은바위 나락"}
        s["npc;drop=15516"] = {"전투감시병 살투라", "안퀴라즈"}
        s["spell;created=19084"] = {"데빌사우루스 건틀릿", "CRAFTING"}
        s["npc;drop=11361"] = {"줄리안 호랑이", "줄구룹"}
        s["npc;drop=15323"] = {"모래무지 하이브자라", "안퀴라즈 폐허"}
        s["spell;created=19097"] = {"데빌사우루스 다리보호구", "CRAFTING"}
        s["object;contained=181366"] = {"기사의 궤짝", "낙스라마스"}
        s["npc;drop=10399"] = {"투자딘 수행사제", "스트라솔름"}
        s["npc;drop=16097"] = {"이살리엔", "혈투의 전장"}
        s["npc;drop=8929"] = {"공주 모이라 브론즈비어드 <아이언포지 공주>", "검은바위 나락"}
        s["quest;reward=7981"] = {"상품권 1200 매 - 다크문의 아뮬렛", "멀고어"}
        s["npc;drop=15114"] = {"가즈란카", "줄구룹"}
        s["npc;drop=15517"] = {"아우로", "안퀴라즈"}
        s["quest;reward=7862"] = {"구인광고: 레반터스크 마을의 경비대장", "동부 내륙지"}
        s["npc;drop=9568"] = {"대군주 웜타라크", "검은바위 첨탑"}
        s["quest;reward=3321"] = {"잃어버린 물건", "타나리스"}
        s["npc;sold=12805"] = {"장교 아레인 <비전투장비 병참장교>", "스톰윈드"}
        s["npc;sold=12799"] = {"병장 바샤 <비전투장비 병참장교>", "오그리마"}
        s["npc;drop=12463"] = {"죽음의발톱 화염전사", "검은날개 둥지"}
        s["quest;reward=7877"] = {"셴드랄라의 보물", "혈투의 전장"}
        s["npc;drop=9025"] = {"불의군주 록코르", "검은바위 나락"}
        s["npc;drop=2748"] = {"아카에다스 <고대의 바위감시자>", "울다만"}
        s["npc;drop=10503"] = {"잔다이스 바로브", "스칼로맨스"}
        s["spell;created=23707"] = {"용암 허리띠", "CRAFTING"}
        s["npc;drop=228022"] = {"파괴자의 망령", "악마벼락 협곡"}
        s["npc;drop=227140"] = {"피라니스", "악마벼락 협곡"}
        s["spell;created=460462"] = {"설퍼라스의 눈", "CRAFTING"}
        s["npc;drop=227028"] = {"헬스크림의 악령", "악마벼락 협곡"}
        s["npc;drop=15204"] = {"대장군 휠락시스", "실리더스"}
        s["npc;drop=218624"] = {"아탈알라리온 <신상의 수호신>", "아탈학카르 신전"}
        s["npc;drop=228430"] = {"마그마다르", "화산 심장부"}
        s["spell;created=24123"] = {"원시 박쥐가죽 팔보호구", "CRAFTING"}
        s["spell;created=24122"] = {"원시 박쥐가죽 장갑", "CRAFTING"}
        s["npc;drop=10422"] = {"진홍십자군 사술사", "스트라솔름"}
        s["quest;reward=84561"] = {"[For All To See]", "오그리마"}
        s["quest;reward=5944"] = {"탤런의 꿈", "서부 역병지대"}
        s["quest;reward=8949"] = {"팔린의 피의 복수", "혈투의 전장"}
        s["npc;sold=12944"] = {"로크토스 다크바게이너 <토륨 대장조합>", "검은바위 나락"}
        s["npc;drop=228436"] = {"설퍼론 사자", "화산 심장부"}
        s["spell;created=461712"] = {"제련된 티탄의 망치", "CRAFTING"}
        s["spell;created=16988"] = {"티탄의 망치", "CRAFTING"}
        s["npc;drop=221943"] = {"하자스", "아탈학카르 신전"}
        s["npc;drop=7355"] = {"투텐카쉬", "가시덩굴 구릉"}
        s["spell;created=461722"] = {"악마핵 건틀릿", "CRAFTING"}
        s["spell;created=461724"] = {"악마핵 다리보호구", "CRAFTING"}
        s["quest;reward=84545"] = {"[A Hero's Reward]", "아즈샤라"}
        s["npc;drop=15510"] = {"불굴의 판크리스", "안퀴라즈"}
        s["npc;drop=15341"] = {"장군 라작스", "안퀴라즈 폐허"}
        s["npc;drop=15340"] = {"모암", "안퀴라즈 폐허"}
        s["npc;drop=10487"] = {"되살아난 민병대원", "스칼로맨스"}
        s["npc;drop=5717"] = {"마이잔", "아탈학카르 신전"}
        s["npc;drop=15263"] = {"예언자 스케람", "안퀴라즈"}
        s["npc;drop=16449"] = {"낙스라마스의 영혼", "낙스라마스"}
        s["npc;drop=12460"] = {"죽음의발톱 고룡수호병", "검은날개 둥지"}
        s["npc;drop=10430"] = {"괴수", "검은바위 첨탑"}
        s["npc;drop=10500"] = {"교사 유령", "스칼로맨스"}
        s["npc;drop=221407"] = {"꿈그림자 임프", "페랄라스"}
        s["npc;drop=10220"] = {"할리콘", "검은바위 첨탑"}
        s["npc;drop=15990"] = {"켈투자드", "낙스라마스"}
        s["npc;drop=12264"] = {"샤즈라", "화산 심장부"}
        s["npc;drop=15952"] = {"맥스나", "낙스라마스"}
        s["quest;reward=9120"] = {"켈투자드의 죽음", "동부 역병지대"}
        s["spell;created=15596"] = {"연기나는 산의 정수", "CRAFTING"}
        s["quest;reward=7067"] = {"추방자의 지시서", "잊혀진 땅"}
        s["quest;reward=8573"] = {"영웅의 전투장비", "실리더스"}
        s["npc;drop=9547"] = {"술취한 손님", "검은바위 나락"}
        s["spell;created=461690"] = {"장인이 만든 변화의 망토", "CRAFTING"}
        s["npc;drop=230302"] = {"군주 카자크", "타락의 흉터"}
        s["spell;created=435904"] = {"빛나는 노움 신경 연결 수도두건", "CRAFTING"}
        s["spell;created=23703"] = {"나무구렁일족의 힘", "CRAFTING"}
        s["spell;created=19080"] = {"전투곰 다리보호구", "CRAFTING"}
        s["npc;sold=10857"] = {"은빛병참장교 라이트스파크 <은빛 여명회>", "서부 역병지대"}
        s["spell;created=23705"] = {"여명의 가죽장화", "CRAFTING"}
        s["npc;sold=13278"] = {"군주 히드락시스", "아즈샤라"}
        s["npc;sold=218115"] = {"마이진 <구루바시부족 혈돌격병>", "가시덤불 골짜기"}
        s["npc;drop=204921"] = {"겔리하스트", "검은심연의 나락"}
        s["quest;reward=80324"] = {"미친 왕", "아이언포지"}
        s["npc;drop=202699"] = {"군주 아쿠아니스", "검은심연의 나락"}
        s["npc;drop=8567"] = {"게걸먹보", "가시덩굴 구릉"}
        s["npc;drop=220007"] = {"방사성 폐기물", "놈리건"}
        s["npc;sold=217689"] = {"지리 '스패너' 리틀스프로켓 <기계공학광>", "놈리건"}
        s["npc;drop=201722"] = {"가무라", "검은심연의 나락"}
        s["npc;drop=220072"] = {"기계화 문지기 6000", "놈리건"}
        s["spell;created=429354"] = {"공허에 물든 가죽 장갑", "CRAFTING"}
        s["quest;reward=824"] = {"속세의 고리회 제네우", "잿빛 골짜기"}
        s["quest;reward=80132"] = {"기술 전쟁", "오그리마"}
        s["npc;drop=3669"] = {"군주 코브란 <송곳니 군주>", "통곡의 동굴"}
        s["npc;drop=215728"] = {"고철 압축기 9-60", "놈리건"}
        s["npc;drop=218537"] = {"멕기니어 텔마플러그", "놈리건"}
        s["npc;drop=4295"] = {"붉은십자군 정예병", "붉은십자군 수도원"}
        s["quest;reward=7541"] = {"호드를 위한 활약", "오그리마"}
        s["npc;drop=6489"] = {"무쇠해골", "붉은십자군 수도원"}
        s["quest;reward=78916"] = {"공허의 심장", "다르나서스"}
        s["npc;drop=207356"] = {"로구스 제트", "검은심연의 나락"}
        s["npc;drop=7584"] = {"떠도는 나무정령", "페랄라스"}
        s["npc;drop=14491"] = {"쿠르모크", "가시덤불 골짜기"}
        s["npc;drop=4389"] = {"늪지트레샤돈", "먼지진흙 습지대"}
        s["npc;drop=2433"] = {"부활한 헬쿨라", "힐스브래드 구릉지"}
        s["spell;created=6705"] = {"멀록 비늘 팔보호구", "CRAFTING"}
        s["spell;created=3779"] = {"야만전사의 허리띠", "CRAFTING"}
        s["npc;drop=4845"] = {"어둠괴철로단 악당", "황야의 땅"}
        s["quest;reward=2767"] = {"OOX-22/FE 구출!", "페랄라스"}
        s["quest;reward=793"] = {"깨어진 동맹", "황야의 땅"}
        s["spell;created=435960"] = {"초전도성 금빛 허리싸개", "CRAFTING"}
        s["npc;drop=16118"] = {"코르모크", "스칼로맨스"}
        s["npc;drop=9033"] = {"사령관 앵거포지", "검은바위 나락"}
        s["npc;drop=12018"] = {"청지기 이그젝큐투스", "화산 심장부"}
        s["npc;drop=15509"] = {"공주 후후란", "안퀴라즈"}
        s["quest;reward=7506"] = {"에메랄드의 꿈...", "혈투의 전장"}
        s["npc;drop=15299"] = {"비시디우스", "안퀴라즈"}
        s["npc;drop=14888"] = {"레손", "그늘숲"}
        s["npc;drop=15543"] = {"공주 야우즈", "안퀴라즈"}
        s["spell;created=22927"] = {"야생의 장막", "CRAFTING"}
        s["npc;drop=11501"] = {"왕 고르독", "혈투의 전장"}
        s["npc;drop=10268"] = {"흉포한 기즈룰", "검은바위 첨탑"}
        s["spell;created=22759"] = {"화염핵 손목띠", "CRAFTING"}
        s["npc;drop=15339"] = {"무적의 오시리안", "안퀴라즈 폐허"}
        s["npc;drop=5712"] = {"졸로", "아탈학카르 신전"}
        s["spell;created=23709"] = {"화산사냥개 허리띠", "CRAFTING"}
        s["npc;drop=13020"] = {"타락한 밸라스트라즈", "검은날개 둥지"}
        s["npc;drop=11488"] = {"일샨나 레이븐오크", "혈투의 전장"}
        s["npc;drop=9056"] = {"파이너스 다크바이어 <선임건축가>", "검은바위 나락"}
        s["npc;drop=10504"] = {"군주 알렉세이 바로브", "스칼로맨스"}
        s["npc;drop=14325"] = {"대장 크롬크러쉬", "혈투의 전장"}
        s["npc;drop=10809"] = {"뾰족바위", "스트라솔름"}
        s["quest;reward=8791"] = {"오시리안 처치", "실리더스"}
        s["npc;drop=10439"] = {"먹보 람스타인", "스트라솔름"}
        s["quest;reward=7907"] = {"다크문 야수 카드", "엘윈 숲"}
        s["object;contained=169243"] = {"일곱 현자의 궤짝", "검은바위 나락"}
        s["npc;drop=14515"] = {"대여사제 알로크", "줄구룹"}
        s["npc;drop=16080"] = {"모르 그레이후프", "검은바위 첨탑"}
        s["spell;created=461750"] = {"강렬한 달빛매듭 머리장식", "CRAFTING"}
        s["spell;created=23665"] = {"은빛 여명회 어깨보호구", "CRAFTING"}
        s["spell;created=446189"] = {"집착의 어깨덧대", "CRAFTING"}
        s["spell;created=19061"] = {"살아있는 어깨보호구", "CRAFTING"}
        s["spell;created=446194"] = {"광기의 어깨덧옷", "CRAFTING"}
        s["npc;drop=221394"] = {"학카르의 화신", "아탈학카르 신전"}
        s["npc;drop=228431"] = {"게헨나스", "화산 심장부"}
        s["npc;drop=9236"] = {"어둠사냥꾼 보쉬가진", "검은바위 첨탑"}
        s["spell;created=19435"] = {"달빛매듭 장화", "CRAFTING"}
        s["npc;drop=218571"] = {"에라니쿠스의 사령", "아탈학카르 신전"}
        s["npc;drop=10506"] = {"사자 키르토노스", "스칼로맨스"}
        s["quest;reward=80325"] = {"미친 왕", "오그리마"}
        s["quest;reward=82081"] = {"중단된 의식", "가시덤불 골짜기"}
        s["quest;reward=82058"] = {"다크문 야생 카드 한 벌", "엘윈 숲"}
        s["npc;drop=226922"] = {"질바고브", "악마벼락 협곡"}
        s["npc;drop=9938"] = {"마그무스", "검은바위 나락"}
        s["npc;drop=3977"] = {"종교재판관 화이트메인", "붉은십자군 수도원"}
        s["npc;drop=14324"] = {"정찰병 초루쉬", "혈투의 전장"}
        s["npc;drop=11661"] = {"불꽃꼬리일족 전사", "화산 심장부"}
        s["npc;drop=11673"] = {"고대의 심장부 사냥개", "화산 심장부"}
        s["quest;reward=9008"] = {"[Saving the Best for Last]", "오그리마"}
        s["quest;reward=4024"] = {"화염의 맛", "불타는 평원"}
        s["npc;drop=13276"] = {"야생혈족 임프", "혈투의 전장"}
        s["npc;drop=9027"] = {"광신자 고로쉬", "검은바위 나락"}
        s["npc;drop=10264"] = {"화염고리 솔라카르", "검은바위 첨탑"}
        s["quest;reward=8906"] = {"진지한 제안", "아이언포지"}
        s["quest;reward=8938"] = {"정당한 보상", "오그리마"}
        s["npc;drop=10393"] = {"스컬", "스트라솔름"}
        s["npc;drop=11489"] = {"굽이나무 텐드리스", "혈투의 전장"}
        s["npc;drop=9596"] = {"반노크 그림액스 <횃불 부대 용사>", "검은바위 첨탑"}
        s["quest;reward=8952"] = {"[Anthion's Parting Words]", "검은바위 첨탑"}
        s["spell;created=22922"] = {"살쾡이 장화", "CRAFTING"}
        s["quest;reward=5125"] = {"아우리우스의 복수", "스트라솔름"}
        s["quest;reward=7503"] = {"사냥꾼의 위대한 혈통", "혈투의 전장"}
        s["quest;reward=82108"] = {"녹색 비룡 몰파즈", "아탈학카르 신전"}
        s["npc;drop=10438"] = {"냉혈한 말레키", "스트라솔름"}
        s["npc;drop=221391"] = {"슬리레나 <하피 여왕>", "페랄라스"}
        s["npc;drop=15740"] = {"조라 거대괴수", "실리더스"}
        s["spell;created=462623"] = {"라크델라 결합", "CRAFTING"}
        s["quest;reward=82104"] = {"예언자 잠말란", "동부 내륙지"}
        s["npc;drop=8908"] = {"뜨겁게 달궈진 전투골렘", "검은바위 나락"}
        s["quest;reward=84148"] = {"진지한 제안", "아이언포지"}
        s["spell;created=446237"] = {"공허 동력 학살자의 완갑", "CRAFTING"}
        s["npc;drop=9029"] = {"적출자", "검은바위 나락"}
        s["quest;reward=7029"] = {"바일텅의 타락", "잊혀진 땅"}
        s["object;contained=179564"] = {"고르독 공물", "혈투의 전장"}
        s["npc;drop=9445"] = {"암흑의 경비병", "검은바위 나락"}
        s["spell;created=23639"] = {"검은분노", "CRAFTING"}
        s["spell;created=461675"] = {"제련된 아케이나이트 도끼", "CRAFTING"}
        s["npc;drop=222573"] = {"이성을 상실한 고대정령", "줄파락"}
        s["quest;reward=8272"] = {"서리늑대의 영웅", "알터랙 산맥"}
        s["quest;reward=3636"] = {"빛의 힘", "스톰윈드"}
        s["quest;reward=1364"] = {"마젠의 부탁", "스톰윈드"}
        s["npc;drop=7603"] = {"오염된 노움 조수", "놈리건"}
        s["npc;drop=2716"] = {"먼지목도리일족 고룡사냥꾼", "황야의 땅"}
        s["quest;reward=628"] = {"덩치큰 바다악어 가죽", "가시덤불 골짜기"}
        s["npc;drop=6910"] = {"레벨로쉬", "울다만"}
        s["quest;reward=7068"] = {"음영석 조각", "오그리마"}
        s["quest;reward=2822"] = {"품질 표시", "페랄라스"}
        s["npc;drop=5860"] = {"황혼의망치단 암흑주술사", "이글거리는 협곡"}
        s["npc;drop=13601"] = {"땜장이 기즐록", "마라우돈"}
        s["quest;reward=1048"] = {"붉은십자군 수도원으로", "붉은십자군 수도원"}
        s["spell;created=435953"] = {"방사능 저항 비늘 두건", "CRAFTING"}
        s["spell;created=18457"] = {"대마법사의 로브", "CRAFTING"}
        s["quest;reward=8632"] = {"불가사의의 머리장식", "안퀴라즈"}
        s["quest;reward=8625"] = {"불가사의의 어깨보호대", "안퀴라즈"}
        s["quest;reward=8633"] = {"불가사의의 로브", "안퀴라즈"}
        s["quest;reward=8634"] = {"불가사의의 장화", "안퀴라즈"}
        s["npc;drop=15236"] = {"독침 베크니스", "안퀴라즈"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "아이언포지"}
        s["quest;reward=84157"] = {"진지한 제안", "오그리마"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "혈투의 전장"}
        s["npc;drop=11480"] = {"불가사의한 피조물", "혈투의 전장"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", "스트라솔름"}
        s["npc;drop=10198"] = {"약탈자 카쇼크", "여명의 설원"}
        s["quest;reward=84165"] = {"정당한 보상", "아이언포지"}
        s["spell;created=22868"] = {"지옥불 장갑", "CRAFTING"}
        s["npc;drop=14684"] = {"발자폰", "스트라솔름"}
        s["quest;reward=82095"] = {"학카르의 화신", "타나리스"}
        s["quest;reward=8932"] = {"[Just Compensation]", "아이언포지"}
        s["npc;drop=9024"] = {"화염술사 로어그레인", "검은바위 나락"}
        s["quest;reward=617"] = {"아키리스 묶음", "가시덤불 골짜기"}
        s["npc;drop=6146"] = {"우레절벽거인", "아즈샤라"}
        s["spell;created=446236"] = {"공허 동력 기원자의 완갑", "CRAFTING"}
        s["quest;reward=3907"] = {"불의 부조화", "황야의 땅"}
        s["spell;created=23663"] = {"나무구렁일족 어깨보호대", "CRAFTING"}
        s["npc;drop=4288"] = {"붉은십자군 조련사", "붉은십자군 수도원"}
        s["npc;drop=6487"] = {"신비술사 도안", "붉은십자군 수도원"}
        s["quest;reward=8366"] = {"남쪽바다해적단 처리반", "타나리스"}
        s["npc;drop=14446"] = {"핀개트", "슬픔의 늪"}
        s["spell;created=16724"] = {"순백의 투구", "CRAFTING"}
        s["npc;drop=10339"] = {"기스 <렌드 블랙핸드의 탈것>", "검은바위 첨탑"}
        s["spell;created=19054"] = {"붉은용비늘 흉갑", "CRAFTING"}
        s["npc;drop=14321"] = {"경비병 펜구스", "혈투의 전장"}
        s["npc;drop=14861"] = {"키르토노스의 혈지기", "스칼로맨스"}
        s["quest;reward=7501"] = {"빛과 정의에 관하여", "혈투의 전장"}
        s["spell;created=446191"] = {"불길한 견갑", "CRAFTING"}
        s["spell;created=446190"] = {"통곡의 사슬 어깨덧옷", "CRAFTING"}
        s["quest;reward=84150"] = {"진지한 제안", "아이언포지"}
        s["npc;drop=10464"] = {"울부짖는 밴시", "스트라솔름"}
        s["npc;drop=12203"] = {"산사태", "마라우돈"}
        s["spell;created=435906"] = {"반사성 진은 뇌우리", "CRAFTING"}
        s["spell;created=435949"] = {"빛나는 초전도성 비늘 코이프", "CRAFTING"}
        s["spell;created=435610"] = {"노움 신경 연결 비전 전선 단안경", "CRAFTING"}
        s["npc;drop=14686"] = {"귀부인 팔데리스", "가시덩굴 구릉"}
        s["npc;sold=222685"] = {"병참장교 카일린", "잿빛 골짜기"}
        s["spell;created=20874"] = {"검은무쇠 팔보호구", "CRAFTING"}
        s["spell;created=24399"] = {"검은무쇠 장화", "CRAFTING"}
        s["npc;sold=3144"] = {"아이트리그", "오그리마"}
        s["quest;reward=80131"] = {"노움의 실력 향상", "아이언포지"}
        s["npc;drop=2691"] = {"깊은골짜기 길잡이", "동부 내륙지"}
        s["npc;drop=10596"] = {"여왕 불그물거미", "검은바위 첨탑"}
        s["spell;created=461730"] = {"강화된 서리수호검", "CRAFTING"}
        s["spell;created=23652"] = {"검은 수호자", "CRAFTING"}
        s["spell;created=461669"] = {"제련된 용사의 아케이나이트검", "CRAFTING"}
        s["spell;created=22797"] = {"마력장 원반", "CRAFTING"}
        s["npc;drop=3976"] = {"붉은십자군 사령관 모그레인", "붉은십자군 수도원"}
        s["quest;reward=7065"] = {"대지와 씨앗의 오염", "잊혀진 땅"}
        s["spell;created=9952"] = {"화려한 미스릴 어깨보호구", "CRAFTING"}
        s["npc;drop=5287"] = {"긴울음 송곳니늑대", "페랄라스"}
        s["npc;drop=1884"] = {"붉은십자군 벌목꾼", "서부 역병지대"}
        s["npc;drop=14690"] = {"레반치온", "혈투의 전장"}
        s["npc;drop=10418"] = {"진홍십자군 보초", "스트라솔름"}
        s["npc;drop=10808"] = {"잔혹한 티미", "스트라솔름"}
        s["spell;created=16729"] = {"사자심장 투구", "CRAFTING"}
        s["spell;created=435908"] = {"강화된 간섭 무효화 보호모", "CRAFTING"}
        s["spell;created=24141"] = {"검은영혼의 어깨보호구", "CRAFTING"}
        s["npc;drop=7524"] = {"고통받는 명가의 원혼", "여명의 설원"}
        s["spell;created=19101"] = {"화산 어깨보호구", "CRAFTING"}
        s["spell;created=446179"] = {"공포의 어깨철갑", "CRAFTING"}
        s["quest;reward=5166"] = {"오색용군단 흉갑", "서부 역병지대"}
        s["spell;created=19076"] = {"화산 흉갑", "CRAFTING"}
        s["spell;created=24139"] = {"검은영혼의 흉갑", "CRAFTING"}
        s["spell;created=446238"] = {"공허 동력 보호자의 완갑", "CRAFTING"}
        s["spell;created=23633"] = {"여명의 장갑", "CRAFTING"}
        s["spell;created=461671"] = {"강인한 악력의 건틀릿", "CRAFTING"}
        s["spell;created=23632"] = {"여명의 벨트", "CRAFTING"}
        s["quest;reward=5081"] = {"맥스웰의 임무", "검은바위 첨탑"}
        s["spell;created=19059"] = {"화산 다리보호구", "CRAFTING"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "동부 역병지대"}
        s["spell;created=461718"] = {"평온", "CRAFTING"}
        s["spell;created=21160"] = {"설퍼라스의 눈", "CRAFTING"}
        s["npc;drop=9039"] = {"운명의 문지기", "검은바위 나락"}
        s["npc;drop=9031"] = {"아눕쉬아", "검은바위 나락"}
        s["spell;created=20873"] = {"불타는 사슬 어깨보호구", "CRAFTING"}
        s["npc;drop=15305"] = {"군주 스퀄", "실리더스"}
        s["spell;created=461651"] = {"숨겨진 기술의 불꽃의 판금 건틀릿", "CRAFTING"}
        s["spell;created=27585"] = {"견고한 흑요석 허리띠", "CRAFTING"}
        s["spell;created=27829"] = {"티탄의 다리보호구", "CRAFTING"}
        s["spell;created=20876"] = {"검은무쇠 다리보호구", "CRAFTING"}
        s["quest;reward=8572"] = {"정예 용사의 전투장비", "실리더스"}
        s["spell;created=12906"] = {"노움 쌈닭", "CRAFTING"}
        s["spell;created=460460"] = {"설퍼론 망치", "CRAFTING"}
        s["spell;created=450409"] = {"술트라제의 부름", "CRAFTING"}
        s["npc;drop=8127"] = {"안투술 <술의 우두머리>", "줄파락"}
        s["spell;created=461714"] = {"모독", "CRAFTING"}
        s["npc;drop=227019"] = {"수색자 디아토루스", "악마벼락 협곡"}
        s["spell;created=16994"] = {"아케이나이트 도끼", "CRAFTING"}
        s["spell;created=23151"] = {"빛과 어둠의 균형", "CRAFTING"}
        s["npc;drop=14517"] = {"대여사제 제클릭", "줄구룹"}
        s["npc;drop=15816"] = {"퀴라지 부사령관 헤알리에", "버섯구름 봉우리"}
        s["quest;reward=9009"] = {"[Saving the Best for Last]", "오그리마"}
        s["npc;drop=11382"] = {"혈군주 만도키르", "줄구룹"}
        s["spell;created=18456"] = {"신앙의 예복", "CRAFTING"}
        s["npc;drop=11664"] = {"불꽃꼬리일족 정예병", "화산 심장부"}
        s["quest;reward=8909"] = {"진지한 제안", "아이언포지"}
        s["quest;reward=8940"] = {"[Just Compensation]", "오그리마"}
        s["npc;drop=14509"] = {"대사제 데칼", "줄구룹"}
        s["quest;reward=9019"] = {"[Anthion's Parting Words]", "검은바위 첨탑"}
        s["npc;drop=14887"] = {"이손드레", "그늘숲"}
        s["quest;reward=7504"] = {"성스러운 볼로냐: 빛이 알려주지 않는 것들", "혈투의 전장"}
        s["quest;reward=82111"] = {"[Blood of Morphaz]", "아즈샤라"}
        s["npc;drop=12459"] = {"검은날개 흑마법사", "검은날개 둥지"}
        s["object;contained=161495"] = {"비밀 금고", "검은바위 나락"}
        s["spell;created=463008"] = {"빛과 어둠의 균형", "CRAFTING"}
        s["spell;created=461708"] = {"강렬한 달빛매듭 로브", "CRAFTING"}
        s["quest;reward=84151"] = {"진지한 제안", "아이언포지"}
        s["spell;created=461752"] = {"강렬한 달빛매듭 다리보호구", "CRAFTING"}
        s["quest;reward=55"] = {"모벤트 펠", "그늘숲"}
        s["npc;drop=4366"] = {"스트라샤즈 수호병", "먼지진흙 습지대"}
        s["npc;drop=10423"] = {"진홍십자군 사제", "스트라솔름"}
        s["npc;drop=9818"] = {"검은손부대 소환사 <검은손 부대>", "검은바위 첨탑"}
        s["spell;created=446193"] = {"조각난 정신 견갑", "CRAFTING"}
        s["npc;drop=9219"] = {"뾰족바위일족 학살자", "검은바위 첨탑"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "저주받은 땅"}
        s["quest;reward=9225"] = {"영웅을 위한 전투 장비: 여명회에 매우 우호적", "동부 역병지대"}
        s["npc;drop=10425"] = {"진홍십자군 전투마법사", "스트라솔름"}
        s["npc;drop=10477"] = {"스칼로맨스 강령술사", "스칼로맨스"}
        s["npc;drop=8923"] = {"무적의 판저", "검은바위 나락"}
        s["npc;drop=10502"] = {"여군주 일루시아 바로브", "스칼로맨스"}
        s["quest;reward=9221"] = {"희귀한 전투 장비: 여명회에 약간 우호적", "동부 역병지대"}
        s["npc;drop=14327"] = {"레스텐드리스", "혈투의 전장"}
        s["spell;created=18436"] = {"겨울밤의 로브", "CRAFTING"}
        s["npc;drop=12457"] = {"검은날개 역술사", "검은날개 둥지"}
        s["quest;reward=8592"] = {"신탁의 티아라", "안퀴라즈"}
        s["quest;reward=8594"] = {"신탁의 어깨보호대", "안퀴라즈"}
        s["spell;created=18453"] = {"지옥매듭 어깨보호구", "CRAFTING"}
        s["quest;reward=8603"] = {"신탁의 의복", "안퀴라즈"}
        s["npc;drop=15247"] = {"퀴라지 세뇌관", "안퀴라즈"}
        s["spell;created=22867"] = {"지옥매듭 장갑", "CRAFTING"}
        s["npc;drop=10432"] = {"벡투스", "스칼로맨스"}
        s["spell;created=23041"] = {"저주의 지팡이 부르기", "CRAFTING"}
        s["npc;drop=14516"] = {"죽음의 기사 다크리버", "스칼로맨스"}
        s["spell;created=461962"] = {"저주의 지팡이 부르기", "CRAFTING"}
        s["npc;drop=1843"] = {"현장감독 제리스", "서부 역병지대"}
        s["npc;drop=12801"] = {"불가사의한 키메로크", "페랄라스"}
        s["npc;drop=228914"] = {"문지기 드루이드의 망령", "악마벼락 협곡"}
        s["npc;drop=10119"] = {"볼찬", "불타는 평원"}
        s["npc;drop=16154"] = {"부활한 죽음의 기사", "낙스라마스"}
        s["npc;drop=11469"] = {"엘드레스 군중", "혈투의 전장"}
        s["npc;drop=14506"] = {"군주 헬누라스", "혈투의 전장"}
        s["npc;drop=14473"] = {"라프리스", "실리더스"}
        s["npc;drop=15975"] = {"청소부 그물거미", "낙스라마스"}
        s["npc;drop=1838"] = {"붉은십자군 심문관", "서부 역병지대"}
        s["npc;drop=1851"] = {"허스크", "서부 역병지대"}
        s["npc;drop=7104"] = {"데시쿠스", "악령의 숲"}
        s["npc;drop=15757"] = {"퀴라지 사령관", "실리더스"}
        s["npc;drop=15390"] = {"부대장 수렘", "안퀴라즈 폐허"}
        s["npc;drop=10371"] = {"성난발톱혈족 우두머리", "검은바위 첨탑"}
        s["npc;drop=11896"] = {"피고름구더기", "동부 역병지대"}
        s["npc;drop=7459"] = {"맹렬한 얼음엉겅퀴설인", "여명의 설원"}
        s["npc;drop=10663"] = {"마나발톱", "여명의 설원"}
        s["spell;created=18442"] = {"지옥매듭 두건", "CRAFTING"}
        s["npc;drop=11143"] = {"우체국장 말로운", "스트라솔름"}
        s["spell;created=19794"] = {"최신형 주문증폭 고글", "CRAFTING"}
        s["npc;drop=11622"] = {"들창어금니", "스칼로맨스"}
        s["object;contained=181074"] = {"투기장 전리품", "검은바위 나락"}
        s["spell;created=18451"] = {"지옥매듭 로브", "CRAFTING"}
        s["npc;drop=9817"] = {"검은손부대 공포술사 <검은손 부대>", "검은바위 첨탑"}
        s["npc;drop=10372"] = {"성난발톱혈족 화염술사", "검은바위 첨탑"}
        s["npc;drop=11490"] = {"제브림 쏜후프", "혈투의 전장"}
        s["npc;drop=10901"] = {"현자 폴켈트", "스칼로맨스"}
        s["npc;drop=11467"] = {"츄지", "혈투의 전장"}
        s["spell;created=18454"] = {"주문 전문화 장갑", "CRAFTING"}
        s["spell;created=18419"] = {"지옥매듭 바지", "CRAFTING"}
        s["npc;drop=10436"] = {"남작부인 아나스타리", "스트라솔름"}
        s["npc;drop=10558"] = {"하스싱어 포레스턴", "스트라솔름"}
        s["npc;drop=9217"] = {"뾰족바위일족 마법사장", "검은바위 첨탑"}
        s["npc;drop=6228"] = {"검은무쇠단 사절", "놈리건"}
        s["npc;drop=6370"] = {"톱니발 마크리니마크루라", "아즈샤라"}
        s["quest;reward=9004"] = {"은혜의 보답", "아이언포지"}
        s["quest;reward=8956"] = {"안시온의 작별 인사", "아이언포지"}
        s["quest;reward=8910"] = {"진지한 제안", "아이언포지"}
        s["quest;reward=8941"] = {"정당한 보상", "오그리마"}
        s["quest;reward=8639"] = {"죽음의 선고자 투구", "안퀴라즈"}
        s["quest;reward=8641"] = {"죽음의 선고자 어깨갑옷", "안퀴라즈"}
        s["quest;reward=8638"] = {"죽음의 선고자 조끼", "안퀴라즈"}
        s["npc;drop=10505"] = {"조교 말리시아", "스칼로맨스"}
        s["quest;reward=8201"] = {"머리카락 수집", "가시덤불 골짜기"}
        s["npc;drop=9265"] = {"가시불꽃부족 어둠사냥꾼", "검은바위 첨탑"}
        s["quest;reward=8640"] = {"죽음의 선고자 다리보호구", "안퀴라즈"}
        s["quest;reward=8637"] = {"죽음의 선고자 장화", "안퀴라즈"}
        s["npc;drop=14507"] = {"대사제 베녹시스", "줄구룹"}
        s["quest;reward=7498"] = {"가로나: 은신과 기만에 대한 연구", "혈투의 전장"}
        s["quest;reward=7787"] = {"일어나라, 우레폭풍이여!", "실리더스"}
        s["npc;drop=203138"] = {"성난모루단 감독관", "검은바위 나락"}
        s["spell;created=461237"] = {"암흑불길 화살", "CRAFTING"}
        s["spell;created=19090"] = {"폭풍안개 어깨보호구", "CRAFTING"}
        s["spell;created=19079"] = {"폭풍안개 갑옷", "CRAFTING"}
        s["quest;reward=84152"] = {"진지한 제안", "아이언포지"}
        s["spell;created=26279"] = {"폭풍안개 장갑", "CRAFTING"}
        s["npc;drop=10318"] = {"검은손부대 암살자 <검은손 부대>", "검은바위 첨탑"}
        s["spell;created=19067"] = {"폭풍안개 바지", "CRAFTING"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "혈투의 전장"}
        s["npc;drop=15741"] = {"레갈 거대괴수", "실리더스"}
        s["npc;drop=14222"] = {"아라가", "알터랙 산맥"}
        s["quest;reward=53"] = {"달콤한 황색 맥주", "서부 몰락지대"}
        s["npc;drop=2601"] = {"뒤뚱발이", "아라시 고원"}
        s["npc;drop=2751"] = {"전투골렘", "황야의 땅"}
        s["spell;created=9201"] = {"거무스름한 팔보호구", "CRAFTING"}
        s["quest;reward=80455"] = {"때를 기다리다", "은빛소나무 숲"}
        s["npc;drop=15209"] = {"진홍 기사단 <심연의 의회>", "실리더스"}
        s["spell;created=23706"] = {"여명의 황금 어깨보호대", "CRAFTING"}
        s["spell;created=19068"] = {"전투곰 멜빵", "CRAFTING"}
        s["npc;drop=9237"] = {"대장군 부네", "검은바위 첨탑"}
        s["npc;drop=15817"] = {"퀴라지 전투사령관 팍슬리쉬", "실리더스"}
        s["quest;reward=8623"] = {"폭풍소환사의 머리관", "안퀴라즈"}
        s["quest;reward=9011"] = {"[Saving the Best for Last]", "오그리마"}
        s["quest;reward=7668"] = {"다크리버의 위협", "오그리마"}
        s["quest;reward=8602"] = {"폭풍소환사의 어깨갑옷", "안퀴라즈"}
        s["spell;created=16650"] = {"찔레가시 사슬갑옷", "CRAFTING"}
        s["quest;reward=8622"] = {"폭풍소환사의 갑옷", "안퀴라즈"}
        s["quest;reward=8918"] = {"진지한 제안", "오그리마"}
        s["npc;drop=14454"] = {"칼날바람", "실리더스"}
        s["quest;reward=8621"] = {"폭풍소환사의 경갑", "안퀴라즈"}
        s["npc;drop=11462"] = {"굽이나무정령", "혈투의 전장"}
        s["quest;reward=7505"] = {"냉기 충격과 주술", "혈투의 전장"}
        s["quest;reward=82113"] = {"부두교 마법", "알터랙 산맥"}
        s["spell;created=461735"] = {"무적의 사슬", "CRAFTING"}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", "오그리마"}
        s["npc;drop=11043"] = {"진홍십자군 수도사", "스트라솔름"}
        s["spell;created=461737"] = {"돌개바람 건틀릿", "CRAFTING"}
        s["npc;drop=10083"] = {"화염비늘 성난발톱용혈족", "검은바위 첨탑"}
        s["npc;drop=10814"] = {"오색용혈족 정예병", "검은바위 첨탑"}
        s["npc;drop=14323"] = {"경비병 슬립킥", "혈투의 전장"}
        s["spell;created=446186"] = {"불협화음의 사슬 어깨보호대", "CRAFTING"}
        s["spell;created=451706"] = {"절규하는 사슬 견갑", "CRAFTING"}
        s["npc;drop=9028"] = {"그리즐", "검은바위 나락"}
        s["spell;created=24138"] = {"붉은영혼의 건틀릿", "CRAFTING"}
        s["npc;drop=224257"] = {"아탈라이부족 노예", "아탈학카르 신전"}
        s["spell;created=435958"] = {"휘도는 진은 톱니장벽", "CRAFTING"}
        s["spell;created=19094"] = {"검은용비늘 어깨보호구", "CRAFTING"}
        s["spell;created=23708"] = {"오색 건틀릿", "CRAFTING"}
        s["spell;created=19107"] = {"검은용비늘 다리보호구", "CRAFTING"}
        s["spell;created=20855"] = {"검은용비늘 장화", "CRAFTING"}
        s["spell;created=23653"] = {"일몰", "CRAFTING"}
        s["npc;drop=6117"] = {"명가의 망령", "아즈샤라"}
        s["spell;created=19085"] = {"검은용비늘 흉갑", "CRAFTING"}
        s["npc;drop=10507"] = {"라베니안", "스칼로맨스"}
        s["spell;created=16991"] = {"파괴의 도끼", "CRAFTING"}
        s["npc;drop=12258"] = {"칼날채찍", "마라우돈"}
        s["npc;drop=7358"] = {"혹한의 암네나르", "가시덩굴 구릉"}
        s["quest;reward=79366"] = {"폭풍전야", "버섯구름 봉우리"}
        s["npc;drop=13596"] = {"썩은아귀", "마라우돈"}
        s["quest;reward=8624"] = {"폭풍소환사의 다리보호구", "안퀴라즈"}
        s["quest;reward=7488"] = {"레스텐드리스의 그물", "페랄라스"}
        s["quest;reward=5526"] = {"악령덩굴 조각", "달숲"}
        s["spell;created=8770"] = {"마력의 로브", "CRAFTING"}
        s["npc;drop=7357"] = {"불꽃눈 모드레쉬", "가시덩굴 구릉"}
        s["spell;created=24356"] = {"붉은덩굴 고글", "CRAFTING"}
        s["quest;reward=8662"] = {"파멸의 소환사 머리장식", "안퀴라즈"}
        s["quest;reward=9005"] = {"[Saving the Best for Last]", "아이언포지"}
        s["quest;reward=8664"] = {"파멸의 소환사 어깨보호대", "안퀴라즈"}
        s["quest;reward=8661"] = {"파멸의 소환사 로브", "안퀴라즈"}
        s["spell;created=18458"] = {"공허의 로브", "CRAFTING"}
        s["quest;reward=8936"] = {"[Just Compensation]", "아이언포지"}
        s["quest;reward=8381"] = {"전쟁 장비", "실리더스"}
        s["spell;created=24201"] = {"여명의 룬 생성", "CRAFTING"}
        s["quest;reward=7502"] = {"지배의 그림자", "혈투의 전장"}
        s["spell;created=461747"] = {"강렬한 달빛매듭 조끼", "CRAFTING"}
        s["quest;reward=84153"] = {"진지한 제안", "아이언포지"}
        s["spell;created=23662"] = {"나무구렁일족의 지혜", "CRAFTING"}
        s["spell;created=462282"] = {"수놓은 대마법사의 허리띠", "CRAFTING"}
        s["npc;drop=15220"] = {"서풍의 군주 <심연의 의회>", "실리더스"}
        s["spell;created=429351"] = {"다른 차원의 거미줄 장화", "CRAFTING"}
        s["npc;drop=15203"] = {"왕자 스칼레녹스", "실리더스"}
        s["spell;created=19830"] = {"아케이나이트 기계용", "CRAFTING"}
        s["spell;created=461743"] = {"대현자의 주문칼날", "CRAFTING"}
        s["spell;created=20848"] = {"화염핵 어깨보호대", "CRAFTING"}
        s["npc;drop=10376"] = {"수정 맹독거미", "검은바위 첨탑"}
        s["npc;drop=16058"] = {"볼리다", "검은바위 나락"}
        s["spell;created=446195"] = {"정신 이상의 어깨덧대", "CRAFTING"}
        s["spell;created=22870"] = {"수호의 망토", "CRAFTING"}
        s["npc;drop=9439"] = {"암흑의 문지기 우그젤", "검은바위 나락"}
        s["spell;created=19093"] = {"오닉시아 비늘 망토", "CRAFTING"}
        s["spell;created=20849"] = {"화염핵 장갑", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "오그리마"}
        s["quest;reward=5942"] = {"숨겨진 보물", "동부 역병지대"}
        s["npc;drop=5722"] = {"하자스", "아탈학카르 신전"}
        s["quest;reward=1560"] = {"길 잃은 투가", "타나리스"}
        s["npc;drop=15208"] = {"파편의 군주 <심연의 의회>", "실리더스"}
        s["spell;created=23666"] = {"화염핵 로브", "CRAFTING"}
        s["quest;reward=80141"] = {"노그의 반지 수리", "오그리마"}
        s["quest;reward=82107"] = {"[Voodoo Feathers]", "슬픔의 늪"}
        s["npc;drop=8762"] = {"그물나무그늘거미", "아즈샤라"}
        s["quest;reward=3129"] = {"영혼의 무기", "페랄라스"}
        s["quest;reward=84162"] = {"진지한 제안", "오그리마"}
        s["quest;reward=9006"] = {"[Saving the Best for Last]", "아이언포지"}
        s["npc;drop=14889"] = {"에메리스", "그늘숲"}
        s["quest;reward=8561"] = {"정복자의 왕관", "안퀴라즈"}
        s["quest;reward=8544"] = {"정복자의 어깨갑옷", "안퀴라즈"}
        s["quest;reward=8562"] = {"정복자의 흉갑", "안퀴라즈"}
        s["quest;reward=8937"] = {"[Just Compensation]", "아이언포지"}
        s["quest;reward=8560"] = {"정복자의 다리갑옷", "안퀴라즈"}
        s["quest;reward=8559"] = {"정복자의 경갑", "안퀴라즈"}
        s["quest;reward=9022"] = {"[Anthion's Parting Words]", "스칼로맨스"}
        s["quest;reward=8789"] = {"제국의 퀴라지 무기", "안퀴라즈"}
        s["spell;created=9954"] = {"진은 건틀릿", "CRAFTING"}
        s["quest;reward=3566"] = {"일어나라, 흑요암이여!", "이글거리는 협곡"}
        s["quest;reward=84550"] = {"방어의 고서", "혈투의 전장"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "검은날개 둥지"}
        s["spell;created=452433"] = {"글라시르 소환", "CRAFTING"}
        s["npc;drop=231494"] = {"왕자 썬더란 <바람추적자>", "수정 골짜기"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "스톰윈드"}
        s["spell;created=452434"] = {"레이라르 소환", "CRAFTING"}
        s["npc;drop=14510"] = {"대여사제 말리", "줄구룹"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "악마벼락 협곡"}
        s["spell;created=461710"] = {"불꽃의 정수 명사수 소총", "CRAFTING"}
        s["spell;created=466117"] = {"얼음의 지팡이 조율", "CRAFTING"}
        s["spell;created=465417"] = {"태세 변경", "CRAFTING"}
        s["spell;created=465418"] = {"태세 변경", "CRAFTING"}
        s["npc;drop=227939"] = {"화산 심장부", "화산 심장부"}
        s["npc;drop=15085"] = {"우슐레이", "줄구룹"}
        s["npc;drop=15083"] = {"하자라", "줄구룹"}
        s["spell;created=469201"] = {"불꽃 점화", "CRAFTING"}
        s["spell;created=468840"] = {"혼돈의 낫 결합", "CRAFTING"}
        s["npc;drop=15084"] = {"레나타키", "줄구룹"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "검은날개 둥지"}
        s["spell;created=467790"] = {"질서의 지팡이 결합", "CRAFTING"}
        s["npc;drop=16011"] = {"로데브", "낙스라마스"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "알터랙 산맥"}
        s["npc;drop=10184"] = {"오닉시아", "화산 심장부"}
        s["quest;reward=85454"] = {"[A Just Reward]", "저습지"}
        s["npc;drop=15369"] = {"사냥꾼 아야미스", "안퀴라즈 폐허"}
        s["quest;reward=86678"] = {"영웅의 전투장비", "실리더스"}
        s["spell;created=1216020"] = {"별의 분노의 우상", "CRAFTING"}
        s["spell;created=1213538"] = {"퀴라지 비단 망토", "CRAFTING"}
        s["npc;drop=15370"] = {"먹보 부루", "안퀴라즈 폐허"}
        s["npc;drop=235197"] = {"[Taerar]", "잿빛 골짜기"}
        s["npc;sold=15192"] = {"아나크로노스", "타나리스"}
        s["spell;created=1213595"] = {"꿈꾸는 자의 눈물", "CRAFTING"}
        s["spell;created=1213502"] = {"흑요석 폭풍망치", "CRAFTING"}
        s["npc;sold=15500"] = {"케일 스위프트클로", "실리더스"}
        s["spell;created=1216340"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1216022"] = {"표범의 야성의 우상", "CRAFTING"}
        s["npc;drop=228230"] = {"해리겐 <암거래상단>", "불타는 평원"}
        s["spell;created=1213536"] = {"퀴라지 비단 단망토", "CRAFTING"}
        s["quest;reward=86675"] = {"지원자의 전투장비", "실리더스"}
        s["spell;created=23704"] = {"나무구렁일족 장갑", "CRAFTING"}
        s["quest;reward=86676"] = {"정예 용사의 전투장비", "실리더스"}
        s["spell;created=1213593"] = {"신속의 돌", "CRAFTING"}
        s["spell;created=1216385"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213500"] = {"흑요석 파괴철퇴", "CRAFTING"}
        s["spell;created=1216024"] = {"곰의 힘의 우상", "CRAFTING"}
        s["spell;created=24121"] = {"원시 박쥐가죽 웃옷", "CRAFTING"}
        s["spell;created=1213738"] = {"가시나무 투구", "CRAFTING"}
        s["spell;created=1213736"] = {"가시나무 장화", "CRAFTING"}
        s["spell;created=1213598"] = {"응징의 자철석", "CRAFTING"}
        s["spell;created=1216366"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213521"] = {"서슬가시 수도두건", "CRAFTING"}
        s["spell;created=1213525"] = {"서슬가시 가죽갑옷", "CRAFTING"}
        s["spell;created=1213523"] = {"서슬가시 어깨덧대", "CRAFTING"}
        s["npc;drop=15348"] = {"쿠린낙스", "안퀴라즈 폐허"}
        s["npc;drop=15544"] = {"벰", "안퀴라즈"}
        s["spell;created=1213603"] = {"루비로 뒤덮인 브로치", "CRAFTING"}
        s["spell;created=1216319"] = {"공허의 손길", "CRAFTING"}
        s["quest;reward=86677"] = {"신념의 전투장비", "실리더스"}
        s["spell;created=1213635"] = {"마력 깃든 버섯", "CRAFTING"}
        s["spell;created=1213540"] = {"퀴라지 비단 외투", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "동부 내륙지"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "실리더스"}
        s["quest;reward=86674"] = {"[The Perfect Poison]", "실리더스"}
        s["spell;created=1216365"] = {"공허의 손길", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "운고로 분화구"}
        s["spell;created=24137"] = {"붉은영혼의 어깨보호구", "CRAFTING"}
        s["spell;created=1216384"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1216387"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1216327"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=466116"] = {"지옥불의 지팡이 조율", "CRAFTING"}
        s["spell;created=1213628"] = {"마력 깃든 기도서", "CRAFTING"}
        s["quest;reward=86672"] = {"제국의 퀴라지 무기", "검은날개 둥지"}
        s["spell;created=1216005"] = {"정의의 성서", "CRAFTING"}
        s["spell;created=1213481"] = {"칼가시 머리우리", "CRAFTING"}
        s["spell;created=1213484"] = {"칼가시 어깨철갑", "CRAFTING"}
        s["spell;created=1214884"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213588"] = {"조율된 마력장 원반", "CRAFTING"}
        s["spell;created=1214270"] = {"뾰족한 흑요석 방패", "CRAFTING"}
        s["spell;created=1213490"] = {"칼가시 전투판금", "CRAFTING"}
        s["spell;created=1213506"] = {"흑요석 방어 도끼", "CRAFTING"}
        s["spell;created=1216379"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1216007"] = {"퇴마사의 성서", "CRAFTING"}
        s["spell;created=1216382"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213534"] = {"퀴라지 비단 목도리", "CRAFTING"}
        s["spell;created=1216375"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213492"] = {"흑요석 약탈자", "CRAFTING"}
        s["spell;created=1216377"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213498"] = {"흑요석 용사의 검", "CRAFTING"}
        s["quest;reward=86671"] = {"제국의 퀴라지 표장", "검은날개 둥지"}
        s["npc;drop=234880"] = {"[Emeriss]", "그늘숲"}
        s["spell;created=1216354"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1216014"] = {"용암 천둥의 토템", "CRAFTING"}
        s["spell;created=1213742"] = {"숲의 관", "CRAFTING"}
        s["spell;created=1213740"] = {"숲의 어깨보호구", "CRAFTING"}
        s["spell;created=28210"] = {"가이아의 은총", "CRAFTING"}
        s["spell;created=1213744"] = {"숲의 조끼", "CRAFTING"}
        s["spell;created=1214306"] = {"꿈비늘 팔보호구", "CRAFTING"}
        s["spell;created=1214307"] = {"꿈비늘 반장갑", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "페랄라스"}
        s["quest;reward=9248"] = {"겸손한 제안", "실리더스"}
        s["quest;reward=86442"] = {"네파리우스의 타락", "검은날개 둥지"}
        s["spell;created=1213532"] = {"흡혈의 로브", "CRAFTING"}
        s["object;contained=495503"] = {"오색 비축품", "검은날개 둥지"}
        s["spell;created=1216372"] = {"공허의 손길", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "실리더스"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "안퀴라즈"}
        s["quest;reward=86760"] = {"[Darkmoon Beast Deck]", "엘윈 숲"}
        s["quest;reward=86762"] = {"[Darkmoon Elementals Deck]", "엘윈 숲"}
        s["quest;reward=86680"] = {"[Waking Legends]", "달숲"}
        s["spell;created=1214303"] = {"꿈비늘 킬트", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "여명의 설원"}
        s["npc;drop=3975"] = {"헤로드 <붉은십자군 용사>", "붉은십자군 수도원"}
        s["spell;created=1216364"] = {"공허의 손길", "CRAFTING"}
        s["spell;created=1213633"] = {"마력 깃든 토템", "CRAFTING"}
        s["spell;created=1216381"] = {"공허의 손길", "CRAFTING"}
        s["npc;sold=16135"] = {"레이네 <세나리온 의회>", "동부 역병지대"}
        s["npc;drop=16061"] = {"훈련교관 라주비어스", "낙스라마스"}
        s["quest;reward=87360"] = {"[The Fall of Kel'Thuzad]", "동부 역병지대"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "카라잔 납골당"}
        s["npc;drop=16143"] = {"파멸의 망령", "저주받은 땅"}
        s["npc;drop=16380"] = {"스컬지 해골마술사", "불타는 평원"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "동부 역병지대"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "카라잔 납골당"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "동부 역병지대"}
        s["npc;drop=16060"] = {"영혼의 착취자 고딕", "낙스라마스"}
        s["npc;drop=15936"] = {"부정의 헤이건", "낙스라마스"}
        s["npc;drop=15931"] = {"그라불루스", "낙스라마스"}
        s["npc;drop=15932"] = {"글루스", "낙스라마스"}
        s["npc;drop=15989"] = {"사피론", "낙스라마스"}
        s["npc;drop=14697"] = {"성큼걸이 누더기골렘", "불타는 평원"}
        s["npc;drop=237439"] = {"[Kharon]", "카라잔 납골당"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "동부 역병지대"}
        s["npc;drop=15928"] = {"타디우스", "낙스라마스"}
        s["npc;drop=15953"] = {"귀부인 팰리나", "낙스라마스"}
        s["npc;drop=15956"] = {"아눕레칸", "낙스라마스"}
        s["npc;drop=15954"] = {"역병술사 노스", "낙스라마스"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "카라잔 납골당"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "카라잔 납골당"}
        s["spell;created=1223762"] = {"빙하의 망토", "CRAFTING"}
        s["npc;drop=16028"] = {"패치워크", "낙스라마스"}
        s["npc;drop=238055"] = {"[Dark Rider]", "카라잔 납골당"}
        s["npc;drop=238560"] = {"[The Warden]", "카라잔 납골당"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "카라잔 납골당"}
        s["spell;created=24179"] = {"여명의 문장 생성", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "카라잔 납골당"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "동부 역병지대"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "카라잔 납골당"}
        s["npc;drop=16379"] = {"저주받은 자의 영혼", "불타는 평원"}
        s["npc;sold=16132"] = {"사냥꾼 레오폴드 <붉은 십자군>", "동부 역병지대"}
        s["quest;reward=87435"] = {"은빛 여명회 사슬 장갑", "동부 역병지대"}
        s["npc;sold=16116"] = {"대마법사 안젤라 도산토스 <빛의 결사단>", "동부 역병지대"}
        s["npc;sold=16115"] = {"사령관 엘리고르 돈브링어 <빛의 결사단>", "동부 역병지대"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "동부 역병지대"}
        s["spell;created=1223787"] = {"얼음막이 흉갑", "CRAFTING"}
        s["spell;created=1223791"] = {"얼음막이 팔보호구", "CRAFTING"}
        s["spell;created=1223789"] = {"얼음막이 건틀릿", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "동부 역병지대"}
        s["spell;created=1223780"] = {"북극의 튜닉", "CRAFTING"}
        s["spell;created=1223784"] = {"북극의 팔보호구", "CRAFTING"}
        s["spell;created=1223782"] = {"북극의 장갑", "CRAFTING"}
        s["quest;reward=86445"] = {"넵튤론의 분노", "타나리스"}
        s["npc;sold=16113"] = {"신부 이니고 몬토이 <빛의 결사단>", "동부 역병지대"}
        s["spell;created=1223760"] = {"빙하의 조끼", "CRAFTING"}
        s["spell;created=1223764"] = {"빙하의 장갑", "CRAFTING"}
        s["npc;sold=16131"] = {"암살자 로한 <붉은 십자군>", "동부 역병지대"}
        s["spell;created=1214137"] = {"흑요석 심장적출 단검", "CRAFTING"}
        s["npc;sold=16134"] = {"림블랫 어스쉐터 <속세의 고리회>", "동부 역병지대"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "카라잔 납골당"}
        s["spell;created=1223766"] = {"빙하의 손목보호대", "CRAFTING"}
        s["spell;created=1223772"] = {"싸늘한 손목보호구", "CRAFTING"}
        s["npc;sold=16133"] = {"분노의 마타우스 <붉은 십자군>", "동부 역병지대"}
        s["spell;created=1213504"] = {"흑요석 현자의 검", "CRAFTING"}
        s["spell;created=1213527"] = {"흡혈의 수도두건", "CRAFTING"}
        s["spell;created=1213530"] = {"흡혈의 어깨망토", "CRAFTING"}
        s["npc;sold=16112"] = {"빛의 용사 코팩스 <빛의 결사단>", "동부 역병지대"}
        s["spell;created=1214145"] = {"흑요석 산탄총", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "동부 역병지대"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "타나리스"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "스트라솔름"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "스트라솔름"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "타나리스"}
    end

    function SpecBisTooltip:TranslationptBR()
        s["npc;drop=12435"] = {"Violâminus, o Indomado", "Covil Asa Negra"}
        s["spell;created=24091"] = {"Colete Vinassangre", "CRAFTING"}
        s["npc;drop=12017"] = {"Prolemestre Flagelador", "Covil Asa Negra"}
        s["npc;drop=11380"] = {"Jin'do, o Bagateiro", "Zul'Gurub"}
        s["npc;drop=11983"] = {"Fogorja", "Covil Asa Negra"}
        s["spell;created=24092"] = {"Perneiras Vinassangre", "CRAFTING"}
        s["spell;created=24093"] = {"Botas Vinassangre", "CRAFTING"}
        s["npc;drop=12098"] = {"Emissário de Sulfuron", "Núcleo Derretido"}
        s["npc;drop=14601"] = {"Petrébano", "Covil Asa Negra"}
        s["quest;reward=8183"] = {"O coração de Hakkar", "Selva do Espinhaço"}
        s["npc;sold=13217"] = {"Tantaldis Cintilaneve <Oficial Intendente de Lançatroz>", "Montanhas de Alterac"}
        s["npc;drop=10435"] = {"Magistrado Barthilas", "Stratholme"}
        s["spell;created=12622"] = {"Lente Verde", "CRAFTING"}
        s["spell;created=12092"] = {"Diadema de Oniritrama", "CRAFTING"}
        s["npc;drop=11261"] = {"Doutor Theolen Krastinov <O Carniceiro>", "Scolomântia"}
        s["npc;sold=12777"] = {"Capitão Martelúgubre", "Bacia Arathi"}
        s["npc;sold=12792"] = {"Lady Palanseer", "Bacia Arathi"}
        s["npc;drop=9018"] = {"Suprema Interrogadora Gerstahn <Interrogador do Martelo do Crepúsculo>", "Abismo Rocha Negra"}
        s["npc;drop=14353"] = {"Mizzle, o Malandro", "Gládio Cruel"}
        s["npc;drop=10811"] = {"Arquivista Galford", "Stratholme"}
        s["npc;drop=9319"] = {"Mestre de Matilha Grebmar", "Abismo Rocha Negra"}
        s["npc;drop=11487"] = {"Magíster Kalendris", "Gládio Cruel"}
        s["npc;sold=13218"] = {"Gruunda Coração de Lobo <Oficial Intendente dos Lobo do Gelo>", "Vale Alterac"}
        s["quest;reward=7861"] = {"Procura-se: Sacerdotisa Torpe Bagata e seus lacaios", "Terras Agrestes"}
        s["npc;drop=12118"] = {"Lúcifron", "Núcleo Derretido"}
        s["npc;drop=11486"] = {"Príncipe Tortheldrin", "Gládio Cruel"}
        s["npc;drop=15815"] = {"Capitão Qiraji Ka'ark", "Mil Agulhas"}
        s["npc;drop=10508"] = {"Ras Friomúrmuro", "Scolomântia"}
        s["npc;sold=14753"] = {"Iliana Fulgiluna <Oficial Intendente da Asa de Prata>", "Vale Gris"}
        s["quest;reward=8574"] = {"Equipamento de batalha do impávido", "Silithus"}
        s["npc;drop=9017"] = {"Lorde Incendius", "Abismo Rocha Negra"}
        s["npc;drop=10516"] = {"O Imperdoável", "Stratholme"}
        s["npc;drop=14326"] = {"Guarda Mol'dar", "Gládio Cruel"}
        s["npc;drop=11662"] = {"Sacerdote Ardilante", "Núcleo Derretido"}
        s["npc;drop=12397"] = {"Lorde Kazzak", "Barreira do Inferno"}
        s["npc;drop=10584"] = {"Urok Uivo-da-ruína", "Pico da Rocha Negra"}
        s["npc;drop=14020"] = {"Cromaggus", "Covil Asa Negra"}
        s["npc;drop=9736"] = {"Intendente Zigris <Legião do Machado Sangrento>", "Pico da Rocha Negra"}
        s["quest;reward=8464"] = {"Atividade Invernosa", "Hibérnia"}
        s["spell;created=12067"] = {"Luvas de Oniritrama", "CRAFTING"}
        s["npc;drop=12056"] = {"Barão Geddon", "Núcleo Derretido"}
        s["npc;drop=9030"] = {"Ok'thor, o Quebrador", "Abismo Rocha Negra"}
        s["npc;sold=13219"] = {"Jekyll Fâmulo <Oficial Intendente dos Lobo do Gelo>", "Montanhas de Alterac"}
        s["spell;created=3864"] = {"Cinto das Estrelas", "CRAFTING"}
        s["npc;drop=12119"] = {"Protetor Ardilante", "Núcleo Derretido"}
        s["npc;drop=9196"] = {"Grão-lorde Omokk", "Pico da Rocha Negra"}
        s["spell;created=23667"] = {"Perneiras do Núcleo Flamífero", "CRAFTING"}
        s["npc;drop=7267"] = {"Chefe Ukorz Escalpareia", "Zul'Farrak"}
        s["npc;drop=8983"] = {"Lorde Golem Argelmach", "Abismo Rocha Negra"}
        s["npc;drop=15276"] = {"Imperador Vek'lor", "Ahn'Qiraj"}
        s["npc;drop=13280"] = {"Rebentágua", "Gládio Cruel"}
        s["npc;drop=10429"] = {"Chefe Guerreiro Laceral Mão Negra", "Pico da Rocha Negra"}
        s["npc;drop=10997"] = {"Mestre de Canhões Gualter", "Stratholme"}
        s["npc;drop=10812"] = {"Grão-Cruzado Dathrohan", "Stratholme"}
        s["npc;drop=15275"] = {"Imperador Vek'nilash", "Ahn'Qiraj"}
        s["npc;drop=15742"] = {"Colosso de Ashi", "Silithus"}
        s["npc;drop=16042"] = {"Lorde Valthalak", "Pico da Rocha Negra"}
        s["quest;reward=8802"] = {"O salvador de Kalimdor", "Ahn'Qiraj"}
        s["quest;reward=4363"] = {"A surpresa da Princesa", "Abismo Rocha Negra"}
        s["quest;reward=4004"] = {"A princesa foi resgatada?", "Abismo Rocha Negra"}
        s["quest;reward=7491"] = {"Para que todos vejam", "Orgrimmar"}
        s["npc;sold=14754"] = {"Kelm Hargunth", "Sertões"}
        s["npc;drop=10509"] = {"Jed Mirarruna <Legião da Mão Negra>", "Pico da Rocha Negra"}
        s["quest;reward=5102"] = {"O fim do General Drakkisath", "Estepes Ardentes"}
        s["npc;drop=9156"] = {"Embaixador Fogaçoite", "Abismo Rocha Negra"}
        s["npc;sold=12782"] = {"Capitão O'Neal", "Bacia Arathi"}
        s["npc;sold=14581"] = {"Sargento Chifre Troante", "Bacia Arathi"}
        s["npc;sold=15126"] = {"Rutherford Twing <Oficial Intendente dos Profanadores>", "Planalto Arathi"}
        s["npc;sold=15127"] = {"Samuel Hawke <Oficial Intendente da Liga de Arathor>", "Planalto Arathi"}
        s["npc;drop=12259"] = {"Geena", "Núcleo Derretido"}
        s["npc;drop=1853"] = {"Umbromestre Gandling", "Scolomântia"}
        s["npc;drop=10899"] = {"Goraluk Rachadastra <Ferreiro de Armaduras da Mão Negra>", "Pico da Rocha Negra"}
        s["npc;drop=11492"] = {"Azzin, o Selvamorfo", "Gládio Cruel"}
        s["quest;reward=8790"] = {"Paramentos Imperiais Qiraji", "Ahn'Qiraj"}
        s["npc;drop=11988"] = {"Golemagg, o Incinerador", "Núcleo Derretido"}
        s["npc;drop=2585"] = {"Vindicante de Stromgarde", "Planalto Arathi"}
        s["quest;reward=82112"] = {"[A Better Ingredient]", "Cratera Un'Goro"}
        s["npc;drop=7271"] = {"Mandingueiro Zum'rah", "Zul'Farrak"}
        s["npc;drop=8440"] = {"Vulto de Hakkar", "Templo de Atal'Hakkar"}
        s["npc;drop=5721"] = {"Darquimeros", "Templo de Atal'Hakkar"}
        s["object;contained=181083"] = {"Relíquias de Soeiro e Jil", "Stratholme"}
        s["quest;reward=7784"] = {"O senhor dos Rocha Negra", "Orgrimmar"}
        s["quest;reward=3962"] = {"É perigoso ir sozinho", "Cratera Un'Goro"}
        s["npc;drop=4543"] = {"Mago Sangrento Thalnos", "Monastério Escarlate"}
        s["npc;sold=227819"] = {"Duque Hidráxis", "Núcleo Derretido"}
        s["npc;drop=228435"] = {"Golemagg, o Incinerador", "Núcleo Derretido"}
        s["npc;drop=228438"] = {"[Ragnaros]", "Núcleo Derretido"}
        s["npc;sold=227853"] = {"Pix Xizzix <Comerciante da Inframina>", "Selva do Espinhaço"}
        s["spell;created=446192"] = {"Membrana da Neurose Sombria", "CRAFTING"}
        s["npc;drop=15205"] = {"Barão Kazum", "Silithus"}
        s["spell;created=461653"] = {"Manto Cromático Brilhante", "CRAFTING"}
        s["npc;sold=222413"] = {"Zalgo, o Explorador <Comerciante de Mercadorias Perdidas>", "Selva do Espinhaço"}
        s["quest;reward=84147"] = {"[An Earnest Proposition]", "Altaforja"}
        s["npc;drop=218819"] = {"[Festering Rotslime]", "Templo de Atal'Hakkar"}
        s["spell;created=429869"] = {"Manoplas de Couro Tocadas pelo Caos", "CRAFTING"}
        s["npc;drop=220833"] = {"[Dreamscythe]", "Templo de Atal'Hakkar"}
        s["npc;sold=222408"] = {"Emissária Caninegro", "Selva Maleva"}
        s["spell;created=461754"] = {"Cinturão da Percepção Arcana", "CRAFTING"}
        s["npc;drop=228433"] = {"Barão Geddon", "Núcleo Derretido"}
        s["object;contained=179703"] = {"Baú do Senhor do Fogo", "Núcleo Derretido"}
        s["npc;drop=228429"] = {"Lúcifron", "Núcleo Derretido"}
        s["npc;drop=226923"] = {"[Grimroot] <[The Mourning Guardian]>", "Cânion do Demônio Caído"}
        s["npc;drop=12201"] = {"Princesa Theradras", "Maraudon"}
        s["npc;drop=217280"] = {"[Grubbis]", "Gnomeregan"}
        s["spell;created=461647"] = {"Martelo Magistral da Tempestade do Piloto Aéreo", "CRAFTING"}
        s["npc;drop=4542"] = {"Alto-inquisidor Fairbanks", "Monastério Escarlate"}
        s["spell;created=12060"] = {"Calças de Magitrama Vermelhas", "CRAFTING"}
        s["spell;created=439105"] = {"Máscara do Grande Vodu", "CRAFTING"}
        s["npc;drop=6490"] = {"Ashir, o Insone", "Monastério Escarlate"}
        s["spell;created=439093"] = {"Omoplatas de Seda Carmesim", "CRAFTING"}
        s["quest;reward=82055"] = {"Baralho de dunas de Negraluna", "Floresta de Elwynn"}
        s["quest;reward=82057"] = {"Baralho de pestes de Negraluna", "Floresta de Elwynn"}
        s["npc;drop=221637"] = {"Talho", "Templo de Atal'Hakkar"}
        s["quest;reward=7940"] = {"1200 Cupons – Orbe de Negraluna", "Mulgore"}
        s["npc;drop=218721"] = {"[Jammal'an the Prophet]", "Templo de Atal'Hakkar"}
        s["spell;created=10621"] = {"Elmo Cabeça de Lobo", "CRAFTING"}
        s["npc;drop=9816"] = {"Piroguarda Mirabrasa", "Pico da Rocha Negra"}
        s["npc;drop=12467"] = {"Capitão Garra da Morte", "Covil Asa Negra"}
        s["spell;created=23710"] = {"Cinto Derretido", "CRAFTING"}
        s["npc;drop=11981"] = {"Flamagor", "Covil Asa Negra"}
        s["npc;drop=6229"] = {"Espanca-gente 9-60", "Gnomeregan"}
        s["npc;drop=15206"] = {"O Duque das Cinzas <Conselho Abissal>", "Silithus"}
        s["npc;drop=9041"] = {"Carcereiro Stilgiss", "Abismo Rocha Negra"}
        s["quest;reward=4261"] = {"Espírito antigo", "Selva Maleva"}
        s["npc;drop=10440"] = {"Barão Rivendare", "Stratholme"}
        s["npc;drop=15511"] = {"Lorde Kri", "Ahn'Qiraj"}
        s["quest;reward=5068"] = {"Peitoral da Sede de Sangue", "Hibérnia"}
        s["npc;drop=9019"] = {"Imperador Dagran Thaurissan", "Abismo Rocha Negra"}
        s["npc;drop=15516"] = {"Guarda de Batalha Sartura", "Ahn'Qiraj"}
        s["spell;created=19084"] = {"Manoplas de Demossauro", "CRAFTING"}
        s["npc;drop=11361"] = {"Tigre Zulian", "Zul'Gurub"}
        s["npc;drop=15323"] = {"Espreitareia Colme'Zara", "Ruínas de Ahn'Qiraj"}
        s["spell;created=19097"] = {"Perneiras de Demossauro", "CRAFTING"}
        s["object;contained=181366"] = {"[Four Horsemen Chest]", "Naxxramas"}
        s["npc;drop=10399"] = {"Acólito Thuzadin", "Stratholme"}
        s["npc;drop=8929"] = {"Princesa Moira Barbabronze <Princesa de Altaforja>", "Abismo Rocha Negra"}
        s["quest;reward=7981"] = {"1200 Cupons – Amuleto de Negraluna", "Mulgore"}
        s["npc;drop=15517"] = {"Ouroboros", "Ahn'Qiraj"}
        s["quest;reward=7862"] = {"Temos vagas: Capitão da Guarda da Aldeia Revatusco", "Terras Agrestes"}
        s["npc;drop=9568"] = {"Lorde Supremo Wyrmthalak", "Pico da Rocha Negra"}
        s["quest;reward=3321"] = {"Perdeu alguma coisa?", "Tanaris"}
        s["npc;sold=12805"] = {"Oficial Areyn <Intendente de Acessórios>", "Ventobravo"}
        s["npc;sold=12799"] = {"Sargento Ba'sha <Intendente de Acessórios>", "Orgrimmar"}
        s["npc;drop=12463"] = {"Flamescama Garra da Morte", "Covil Asa Negra"}
        s["quest;reward=7877"] = {"O tesouro de Shen'dralar", "Gládio Cruel"}
        s["npc;drop=9025"] = {"Lorde Pétror", "Abismo Rocha Negra"}
        s["npc;drop=2748"] = {"Arkhaedas", "Uldaman"}
        s["npc;drop=10503"] = {"Janice Barov", "Scolomântia"}
        s["spell;created=23707"] = {"Cinto de Lava", "CRAFTING"}
        s["npc;drop=228022"] = {"[The Destructor's Wraith]", "Cânion do Demônio Caído"}
        s["spell;created=460462"] = {"Olho de Sulfuras", "CRAFTING"}
        s["npc;drop=227028"] = {"[Hellscream's Phantom]", "Cânion do Demônio Caído"}
        s["npc;drop=15204"] = {"Grão-marechal Viráxis", "Silithus"}
        s["npc;drop=218624"] = {"Atal'alarion <Guardião do Ídolo>", "Templo de Atal'Hakkar"}
        s["spell;created=24123"] = {"Braçadeiras Primevas de Pele de Morcego", "CRAFTING"}
        s["spell;created=24122"] = {"Luvas Primevas de Pele de Morcego", "CRAFTING"}
        s["npc;drop=10422"] = {"Feiticeiro Carmesim", "Stratholme"}
        s["quest;reward=84561"] = {"[For All To See]", "Orgrimmar"}
        s["quest;reward=5944"] = {"No mundo dos sonhos", "Terras Pestilentas Ocidentais"}
        s["quest;reward=8949"] = {"A vendeta de Falrin", "Gládio Cruel"}
        s["npc;sold=12944"] = {"Lokhtos Umbrarganha <A Irmandade do Tório>", "Abismo Rocha Negra"}
        s["npc;drop=228436"] = {"Emissário de Sulfuron", "Núcleo Derretido"}
        s["spell;created=461712"] = {"Martelo dos Titãs Refinado", "CRAFTING"}
        s["spell;created=16988"] = {"Martelo dos Titãs", "CRAFTING"}
        s["npc;drop=7355"] = {"Tutan'kash", "Urzal dos Mortos"}
        s["spell;created=461722"] = {"Manoplas de Democerne", "CRAFTING"}
        s["spell;created=461724"] = {"Perneiras de Democerne", "CRAFTING"}
        s["quest;reward=84545"] = {"[A Hero's Reward]", "Azshara"}
        s["npc;drop=15510"] = {"Fankriss, o Obstinado", "Ahn'Qiraj"}
        s["npc;drop=10487"] = {"Protetor Reanimado", "Scolomântia"}
        s["npc;drop=5717"] = {"Mirran", "Templo de Atal'Hakkar"}
        s["npc;drop=15263"] = {"Profeta Skeram", "Ahn'Qiraj"}
        s["npc;drop=16449"] = {"Espírito de Naxxramas", "Naxxramas"}
        s["npc;drop=12460"] = {"Serpeguarda Garra da Morte", "Covil Asa Negra"}
        s["npc;drop=10430"] = {"A Fera", "Pico da Rocha Negra"}
        s["npc;drop=10500"] = {"Professor Espectral", "Scolomântia"}
        s["npc;drop=221407"] = {"Diabrete Sonumbra", "Feralas"}
        s["quest;reward=9120"] = {"A queda de Kel'Thuzad", "Terras Pestilentas Orientais"}
        s["spell;created=15596"] = {"Coração Fumegante da Montanha", "CRAFTING"}
        s["quest;reward=7067"] = {"As instruções do pária", "Desolação"}
        s["quest;reward=8573"] = {"Equipamento de batalha do campeão", "Silithus"}
        s["npc;drop=9547"] = {"Cliente Beberrrão", "Abismo Rocha Negra"}
        s["spell;created=461690"] = {"Manto Cambiante Feito com Maestria", "CRAFTING"}
        s["npc;drop=230302"] = {"Lorde Kazzak", "Rasgo Infecto"}
        s["spell;created=435904"] = {"Capucho Gneuroarticulado Luminescente", "CRAFTING"}
        s["spell;created=23703"] = {"Poder dos Presamatos", "CRAFTING"}
        s["spell;created=19080"] = {"Bermuda de Urso de Guerra", "CRAFTING"}
        s["npc;sold=10857"] = {"Intendente Argênteo Centelhuz <A Aurora Argêntea>", "Terras Pestilentas Ocidentais"}
        s["spell;created=23705"] = {"Botinas da Aurora", "CRAFTING"}
        s["npc;sold=13278"] = {"Duque Hidráxis", "Azshara"}
        s["npc;sold=218115"] = {"Mai'zin <Muda-sangue Gurubashi>", "Selva do Espinhaço"}
        s["quest;reward=80324"] = {"O rei louco", "Altaforja"}
        s["npc;drop=202699"] = {"Barão Aquanis", "Profundezas Negras"}
        s["npc;drop=8567"] = {"Glutão", "Urzal dos Mortos"}
        s["npc;drop=220007"] = {"[Viscous Fallout]", "Gnomeregan"}
        s["npc;sold=217689"] = {"[Ziri 'The Wrench' Littlesprocket] <[Gearhead]>", "Gnomeregan"}
        s["npc;drop=220072"] = {"Eletrocutor 6000", "Gnomeregan"}
        s["spell;created=429354"] = {"Luvas de Couro Tocadas pelo Caos", "CRAFTING"}
        s["quest;reward=824"] = {"Je'neu da Harmonia Telúrica", "Vale Gris"}
        s["quest;reward=80132"] = {"Guerra dos robôs", "Orgrimmar"}
        s["npc;drop=3669"] = {"Lorde Cobrahn <Lorde da Presa>", "Caverna Ululante"}
        s["npc;drop=215728"] = {"[Crowd Pummeler 9-60]", "Gnomeregan"}
        s["npc;drop=218537"] = {"Mecangenheiro Termaplugue", "Gnomeregan"}
        s["npc;drop=4295"] = {"Mirmidão Escarlate", "Monastério Escarlate"}
        s["quest;reward=7541"] = {"Serviço para a Horda", "Orgrimmar"}
        s["npc;drop=6489"] = {"Espinha de Ferro", "Monastério Escarlate"}
        s["quest;reward=78916"] = {"Âmago do caos", "Darnassus"}
        s["npc;drop=7584"] = {"Andarilho Errante da Floresta", "Feralas"}
        s["npc;drop=4389"] = {"Mangualama", "Pântano Vadeoso"}
        s["npc;drop=2433"] = {"Restos Mortais de Helcolar", "Contraforte de Eira dos Montes"}
        s["spell;created=6705"] = {"Braçadeiras de Escama de Murloc", "CRAFTING"}
        s["spell;created=3779"] = {"Cinto Barbaresco", "CRAFTING"}
        s["npc;drop=4845"] = {"Rufião de Umbraforja", "Ermos"}
        s["npc;drop=218242"] = {"[STX-04/BD]", "Gnomeregan"}
        s["quest;reward=2767"] = {"Resgate o OOX-22/FE!", "Feralas"}
        s["quest;reward=793"] = {"Alianças rompidas", "Ermos"}
        s["spell;created=435960"] = {"Faixa de Ouro Hipercondutora", "CRAFTING"}
        s["npc;drop=9033"] = {"General Forjaversa", "Abismo Rocha Negra"}
        s["npc;drop=12018"] = {"Senescal Executus", "Núcleo Derretido"}
        s["npc;drop=15509"] = {"Princesa Huhuran", "Ahn'Qiraj"}
        s["quest;reward=7506"] = {"O Sonho Esmeralda...", "Gládio Cruel"}
        s["npc;drop=15543"] = {"Princesa Yauj", "Ahn'Qiraj"}
        s["spell;created=22927"] = {"Pelego da Natureza", "CRAFTING"}
        s["npc;drop=11501"] = {"Rei Gordok", "Gládio Cruel"}
        s["npc;drop=10268"] = {"Gizrul, o Subjugador", "Pico da Rocha Negra"}
        s["spell;created=22759"] = {"Braceletes do Núcleo Flamífero", "CRAFTING"}
        s["npc;drop=15339"] = {"Ossirian, o Intocado", "Ruínas de Ahn'Qiraj"}
        s["spell;created=23709"] = {"Cinto do Cão do Núcleo", "CRAFTING"}
        s["npc;drop=13020"] = {"Vaelastrasz, o Corrupto", "Covil Asa Negra"}
        s["npc;drop=11488"] = {"Illyanna Corvalho", "Gládio Cruel"}
        s["npc;drop=9056"] = {"Fineous Forçanegra <Arquiteto-chefe>", "Abismo Rocha Negra"}
        s["npc;drop=10504"] = {"Lorde Alexei Barov", "Scolomântia"}
        s["npc;drop=14325"] = {"Capitão Kebrapaw", "Gládio Cruel"}
        s["npc;drop=10809"] = {"Petrespáduas", "Stratholme"}
        s["quest;reward=8791"] = {"A queda de Ossirian", "Silithus"}
        s["npc;drop=10439"] = {"Ramstein, o Devorador", "Stratholme"}
        s["quest;reward=7907"] = {"Baralho de Feras de Negraluna", "Floresta de Elwynn"}
        s["object;contained=169243"] = {"Baú dos Sete", "Abismo Rocha Negra"}
        s["npc;drop=14515"] = {"Alta-sacerdotisa Arlokk", "Zul'Gurub"}
        s["npc;drop=16080"] = {"Mor Casco Gris", "Pico da Rocha Negra"}
        s["spell;created=461750"] = {"Diadema de Lunatrama Incandescente", "CRAFTING"}
        s["spell;created=23665"] = {"Omoplatas Argênteas", "CRAFTING"}
        s["spell;created=446189"] = {"Ombreiras da Obsessão", "CRAFTING"}
        s["spell;created=19061"] = {"Omoplatas Vivas", "CRAFTING"}
        s["spell;created=446194"] = {"Manto da Insanidade", "CRAFTING"}
        s["npc;drop=221394"] = {"Avatar de Hakkar", "Templo de Atal'Hakkar"}
        s["npc;drop=228431"] = {"Geena", "Núcleo Derretido"}
        s["npc;drop=9236"] = {"Caçadora Sombria Vosh'gajin", "Pico da Rocha Negra"}
        s["spell;created=19435"] = {"Botas de Lunatrama", "CRAFTING"}
        s["npc;drop=218571"] = {"[Shade of Eranikus]", "Templo de Atal'Hakkar"}
        s["npc;drop=10506"] = {"Kirtonos, o Arauto", "Scolomântia"}
        s["quest;reward=80325"] = {"O rei louco", "Orgrimmar"}
        s["quest;reward=82081"] = {"Ritual interrompido", "Selva do Espinhaço"}
        s["quest;reward=82058"] = {"Baralho de selvas de Negraluna", "Floresta de Elwynn"}
        s["npc;drop=226922"] = {"[Zilbagob]", "Cânion do Demônio Caído"}
        s["npc;drop=3977"] = {"Alta-inquisidora Cristalba", "Monastério Escarlate"}
        s["npc;drop=14324"] = {"Ez'Magg, o Observador", "Gládio Cruel"}
        s["npc;drop=11661"] = {"Ardilante", "Núcleo Derretido"}
        s["npc;drop=11673"] = {"Cão-magma Ancião", "Núcleo Derretido"}
        s["quest;reward=9008"] = {"[Saving the Best for Last]", "Orgrimmar"}
        s["quest;reward=4024"] = {"O gosto das chamas", "Estepes Ardentes"}
        s["npc;drop=13276"] = {"Diabrete Criasselvagem", "Gládio Cruel"}
        s["npc;drop=9027"] = {"Gorosh, o Dervixe", "Abismo Rocha Negra"}
        s["npc;drop=10264"] = {"Solakar Chamarco", "Pico da Rocha Negra"}
        s["quest;reward=8906"] = {"Uma proposta honesta", "Altaforja"}
        s["quest;reward=8938"] = {"Recompensa justa", "Orgrimmar"}
        s["npc;drop=10393"] = {"Kranio", "Stratholme"}
        s["npc;drop=11489"] = {"Gavíneo Lenhatorta", "Gládio Cruel"}
        s["npc;drop=9596"] = {"Bannok Sinistracha <Campeão da Legião Temerária>", "Pico da Rocha Negra"}
        s["quest;reward=8952"] = {"[Anthion's Parting Words]", "Pico da Rocha Negra"}
        s["spell;created=22922"] = {"Botas do Mangusto", "CRAFTING"}
        s["quest;reward=5125"] = {"O ajuste de contas de Aurius", "Stratholme"}
        s["quest;reward=7503"] = {"A Grande Corrida dos Caçadores", "Gládio Cruel"}
        s["quest;reward=82108"] = {"O draco verde", "Templo de Atal'Hakkar"}
        s["npc;drop=10438"] = {"Malaki, o Pálido", "Stratholme"}
        s["npc;drop=221391"] = {"Slirena <Rainha das Harpias>", "Feralas"}
        s["npc;drop=15740"] = {"Colosso de Zora", "Silithus"}
        s["spell;created=462623"] = {"Formação de Rhok'delar", "CRAFTING"}
        s["quest;reward=82104"] = {"Jammal'an, o Profeta", "Terras Agrestes"}
        s["npc;drop=8908"] = {"Golem de Guerra Derretido", "Abismo Rocha Negra"}
        s["quest;reward=84148"] = {"[An Earnest Proposition]", "Altaforja"}
        s["spell;created=446237"] = {"Avambraços do Matador Energizados pelo Caos", "CRAFTING"}
        s["npc;drop=9029"] = {"Eviscerador", "Abismo Rocha Negra"}
        s["quest;reward=7029"] = {"A corrupção de Torpelíngua", "Desolação"}
        s["object;contained=179564"] = {"Homenagem a Gordok", "Gládio Cruel"}
        s["npc;drop=9445"] = {"Guarda Sombrio", "Abismo Rocha Negra"}
        s["spell;created=23639"] = {"Fúria Negra", "CRAFTING"}
        s["spell;created=461675"] = {"Retalhador de Arcanita Refinada", "CRAFTING"}
        s["npc;drop=222573"] = {"Ancestral Delirante", "Zul'Farrak"}
        s["quest;reward=8272"] = {"Herói dos Lobo do Gelo", "Montanhas de Alterac"}
        s["quest;reward=3636"] = {"Trazer a luz", "Ventobravo"}
        s["quest;reward=1364"] = {"A mando de Mazen", "Ventobravo"}
        s["npc;drop=7603"] = {"Assistente Leproso", "Gnomeregan"}
        s["npc;drop=2716"] = {"Caçador de Serpes Arrota-pó", "Ermos"}
        s["quest;reward=628"] = {"Excelsior", "Selva do Espinhaço"}
        s["quest;reward=7068"] = {"Fragmentos de lascanegra", "Orgrimmar"}
        s["quest;reward=2822"] = {"Marca de qualidade", "Feralas"}
        s["npc;drop=5860"] = {"Xamã Sombrio do Crepúsculo", "Garganta Abrasadora"}
        s["npc;drop=13601"] = {"Engenhoqueiro Bugitranca", "Maraudon"}
        s["quest;reward=1048"] = {"Adentrando o Monastério Escarlate", "Monastério Escarlate"}
        s["spell;created=435953"] = {"Capuz de Escamas com Resistência à Radiação", "CRAFTING"}
        s["spell;created=18457"] = {"Veste do Arquimago", "CRAFTING"}
        s["quest;reward=8632"] = {"Diadema Enigmático", "Ahn'Qiraj"}
        s["quest;reward=8625"] = {"Ombreiras Enigmáticas", "Ahn'Qiraj"}
        s["quest;reward=8633"] = {"Vestes enigmáticas", "Ahn'Qiraj"}
        s["quest;reward=8634"] = {"Botas Enigmáticas", "Ahn'Qiraj"}
        s["npc;drop=15236"] = {"Vespa Vekniss", "Ahn'Qiraj"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "Altaforja"}
        s["quest;reward=84157"] = {"Uma proposta honesta", "Orgrimmar"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "Gládio Cruel"}
        s["npc;drop=11480"] = {"Aberração Arcana", "Gládio Cruel"}
        s["quest;reward=84181"] = {"As últimas palavras de Anthion", "Stratholme"}
        s["npc;drop=10198"] = {"Kashoch, o Aniquilador", "Hibérnia"}
        s["quest;reward=84165"] = {"[Just Compensation]", "Altaforja"}
        s["spell;created=22868"] = {"Luvas Inferno", "CRAFTING"}
        s["quest;reward=82095"] = {"O deus Hakkar", "Tanaris"}
        s["quest;reward=8932"] = {"Recompensa justa", "Altaforja"}
        s["npc;drop=9024"] = {"Piromante Sábia Semente", "Abismo Rocha Negra"}
        s["quest;reward=617"] = {"Akiris aos montes", "Selva do Espinhaço"}
        s["npc;drop=6146"] = {"Rachador do Penhasco", "Azshara"}
        s["spell;created=446236"] = {"Avambraços do Evocador Energizados pelo Caos", "CRAFTING"}
        s["quest;reward=3907"] = {"Desarmonia do fogo", "Ermos"}
        s["spell;created=23663"] = {"Dragonas dos Presamatos", "CRAFTING"}
        s["npc;drop=4288"] = {"Senhor das Feras Escarlate", "Monastério Escarlate"}
        s["npc;drop=6487"] = {"Arcanista Doan", "Monastério Escarlate"}
        s["quest;reward=8366"] = {"Recadinho dos Mares do Sul", "Tanaris"}
        s["npc;drop=14446"] = {"Pinato", "Pântano das Mágoas"}
        s["spell;created=16724"] = {"Elmo da Alma Alva", "CRAFTING"}
        s["npc;drop=10339"] = {"Gyth <Montaria de Laceral Mão Negra>", "Pico da Rocha Negra"}
        s["spell;created=19054"] = {"Peitoral de Escama de Dragão Vermelha", "CRAFTING"}
        s["npc;drop=14321"] = {"Guarda Fengus", "Gládio Cruel"}
        s["npc;drop=14861"] = {"Governanta Sangrenta de Kirtonos", "Scolomântia"}
        s["quest;reward=7501"] = {"A Luz e Como Ativá-la", "Gládio Cruel"}
        s["spell;created=446191"] = {"Brafoneiras Perniciosas", "CRAFTING"}
        s["spell;created=446190"] = {"Manto da Corrente Uivante", "CRAFTING"}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", "Altaforja"}
        s["npc;drop=10464"] = {"Banshee Ululante", "Stratholme"}
        s["npc;drop=12203"] = {"Soterrador", "Maraudon"}
        s["spell;created=435906"] = {"Guarda-cérebro de Veraprata Refletor", "CRAFTING"}
        s["spell;created=435949"] = {"Coifa de Escama Hipercondutora Luminescente", "CRAFTING"}
        s["spell;created=435610"] = {"Monóculo Gneuroarticulado de Arcanofilamento", "CRAFTING"}
        s["npc;drop=14686"] = {"Lady Falter'essa", "Urzal dos Mortos"}
        s["npc;sold=222685"] = {"Intendente Kyleen", "Vale Gris"}
        s["spell;created=20874"] = {"Braçadeiras Ferro Negro", "CRAFTING"}
        s["spell;created=24399"] = {"Botas Ferro Negro", "CRAFTING"}
        s["quest;reward=80131"] = {"[Gnome Improvement]", "Altaforja"}
        s["npc;drop=2691"] = {"Vanguardeiro do Altovale", "Terras Agrestes"}
        s["npc;drop=10596"] = {"Mãe Queimateia", "Pico da Rocha Negra"}
        s["spell;created=461730"] = {"Guardafria Endurecida", "CRAFTING"}
        s["spell;created=23652"] = {"Guarda Negra", "CRAFTING"}
        s["spell;created=461669"] = {"Campeão de Arcanita Refinada", "CRAFTING"}
        s["spell;created=22797"] = {"Disco de Força Reativa", "CRAFTING"}
        s["npc;drop=3976"] = {"Comandante Escarlate Mograine", "Monastério Escarlate"}
        s["quest;reward=7065"] = {"Corrupção da terra e dos grãos", "Desolação"}
        s["spell;created=9952"] = {"Ombreiras Ornadas de Mithril", "CRAFTING"}
        s["npc;drop=5287"] = {"Uivador Longodente", "Feralas"}
        s["npc;drop=1884"] = {"Lenhador Escarlate", "Terras Pestilentas Ocidentais"}
        s["npc;drop=10418"] = {"Guarda Carmesim", "Stratholme"}
        s["npc;drop=10808"] = {"Tico, o Cruel", "Stratholme"}
        s["spell;created=16729"] = {"Elmo Coração de Leão", "CRAFTING"}
        s["spell;created=435908"] = {"Elmo Temperado com Cancelamento de Interferências", "CRAFTING"}
        s["spell;created=24141"] = {"Omoplatas Almanegra", "CRAFTING"}
        s["npc;drop=7524"] = {"Altaneiro Angustiado", "Hibérnia"}
        s["spell;created=19101"] = {"Omoplatas Vulcânicas", "CRAFTING"}
        s["spell;created=446179"] = {"Placa d'Ombros do Pavor", "CRAFTING"}
        s["quest;reward=5166"] = {"Peitoral da Revoada Cromática", "Terras Pestilentas Ocidentais"}
        s["spell;created=19076"] = {"Peitoral Vulcânico", "CRAFTING"}
        s["spell;created=24139"] = {"Peitoral Almanegra", "CRAFTING"}
        s["spell;created=446238"] = {"Avambraços do Protetor Energizados pelo Caos", "CRAFTING"}
        s["spell;created=23633"] = {"Luvas da Aurora", "CRAFTING"}
        s["spell;created=461671"] = {"Manoplas da Fortaleza Maior", "CRAFTING"}
        s["spell;created=23632"] = {"Cinturão da Aurora", "CRAFTING"}
        s["quest;reward=5081"] = {"A missão de Maxwell", "Pico da Rocha Negra"}
        s["spell;created=19059"] = {"Perneiras Vulcânicas", "CRAFTING"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "Terras Pestilentas Orientais"}
        s["spell;created=461718"] = {"Tranquilidade", "CRAFTING"}
        s["spell;created=21160"] = {"Olho de Sulfuras", "CRAFTING"}
        s["npc;drop=9039"] = {"Ruine'rel", "Abismo Rocha Negra"}
        s["spell;created=20873"] = {"Omoplatas Encadeadas Abrasadoras", "CRAFTING"}
        s["npc;drop=15305"] = {"Lorde Skwol", "Silithus"}
        s["spell;created=461651"] = {"Manoplas de Placa Abrasadoras da Técnica Oculta", "CRAFTING"}
        s["spell;created=27585"] = {"Cinto Pesado de Obsidiana", "CRAFTING"}
        s["spell;created=27829"] = {"Perneiras Titânicas", "CRAFTING"}
        s["spell;created=20876"] = {"Perneiras de Ferro Negro", "CRAFTING"}
        s["quest;reward=8572"] = {"Equipamento de batalha do veterano", "Silithus"}
        s["spell;created=12906"] = {"Frango de Batalha Gnômico", "CRAFTING"}
        s["spell;created=460460"] = {"Martelo de Sulfuron", "CRAFTING"}
        s["spell;created=450409"] = {"Chamado de Sul'Thraze", "CRAFTING"}
        s["npc;drop=8127"] = {"Antu'sul <Feitor de Sul>", "Zul'Farrak"}
        s["spell;created=461714"] = {"Profanação", "CRAFTING"}
        s["npc;drop=227019"] = {"[Diathorus the Seeker]", "Cânion do Demônio Caído"}
        s["spell;created=16994"] = {"Foice de Arcanita", "CRAFTING"}
        s["spell;created=23151"] = {"Equilíbrio entre Luz e Sombra", "CRAFTING"}
        s["npc;drop=14517"] = {"Alta-sacerdotisa Jeklik", "Zul'Gurub"}
        s["npc;drop=15816"] = {"Major Qiraji He'al-ie", "Mil Agulhas"}
        s["quest;reward=9009"] = {"Deixando o melhor para o final", "Orgrimmar"}
        s["npc;drop=11382"] = {"Sangrelorde Mandokir", "Zul'Gurub"}
        s["spell;created=18456"] = {"Vestimenta da Fé Verdadeira", "CRAFTING"}
        s["npc;drop=11664"] = {"Elite Ardilante", "Núcleo Derretido"}
        s["quest;reward=8909"] = {"Uma proposta honesta", "Altaforja"}
        s["quest;reward=8940"] = {"Recompensa justa", "Orgrimmar"}
        s["npc;drop=14509"] = {"Sumo Sacerdote Thekal", "Zul'Gurub"}
        s["quest;reward=9019"] = {"As últimas palavras de Anthion", "Pico da Rocha Negra"}
        s["npc;drop=14887"] = {"Ysondra", "Floresta do Crepúsculo"}
        s["quest;reward=7504"] = {"Caçarolas: O Que a Luz Não lhe Contará", "Gládio Cruel"}
        s["quest;reward=82111"] = {"Sangue de Morphaz", "Azshara"}
        s["npc;drop=12459"] = {"Bruxo Asa Negra", "Covil Asa Negra"}
        s["object;contained=161495"] = {"Cofre Secreto", "Abismo Rocha Negra"}
        s["spell;created=463008"] = {"Equilíbrio entre Luz e Sombra", "CRAFTING"}
        s["spell;created=461708"] = {"Veste de Lunatrama Incandescente", "CRAFTING"}
        s["quest;reward=84151"] = {"[An Earnest Proposition]", "Altaforja"}
        s["spell;created=461752"] = {"Perneiras de Lunatrama Incandescente", "CRAFTING"}
        s["quest;reward=55"] = {"Morbídio Vil", "Floresta do Crepúsculo"}
        s["npc;drop=4366"] = {"Guarda Viperino Strashaz", "Pântano Vadeoso"}
        s["npc;drop=10423"] = {"Sacerdote Carmesim", "Stratholme"}
        s["npc;drop=9818"] = {"Evocador da Mão Negra <Legião da Mão Negra>", "Pico da Rocha Negra"}
        s["spell;created=446193"] = {"Brafoneiras da Mente Fraturada", "CRAFTING"}
        s["npc;drop=9219"] = {"Carniceiro Agulhapétrea", "Pico da Rocha Negra"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "Barreira do Inferno"}
        s["quest;reward=9225"] = {"[Epic Armaments of Battle - Revered Amongst the Dawn]", "Terras Pestilentas Orientais"}
        s["npc;drop=10425"] = {"Mago de Batalha Carmesim", "Stratholme"}
        s["npc;drop=10477"] = {"Necromante de Scolomântia", "Scolomântia"}
        s["npc;drop=8923"] = {"Panzor, o Invencível", "Abismo Rocha Negra"}
        s["npc;drop=10502"] = {"Lady Ilúcia Barov", "Scolomântia"}
        s["quest;reward=9221"] = {"Armamentos de Batalha Superiores: Aliados da Aurora", "Terras Pestilentas Orientais"}
        s["npc;drop=14327"] = {"Letendris", "Gládio Cruel"}
        s["spell;created=18436"] = {"Veste da Noite de Inverno", "CRAFTING"}
        s["npc;drop=12457"] = {"Mesmerizador Asa Negra", "Covil Asa Negra"}
        s["quest;reward=8592"] = {"Tiara do Oráculo", "Ahn'Qiraj"}
        s["quest;reward=8594"] = {"Dragonas do Oráculo", "Ahn'Qiraj"}
        s["spell;created=18453"] = {"Omoplatas de Tecido Vil", "CRAFTING"}
        s["quest;reward=8603"] = {"Vestimenta do Oráculo", "Ahn'Qiraj"}
        s["npc;drop=15247"] = {"Lavamentes Qiraji", "Ahn'Qiraj"}
        s["spell;created=22867"] = {"Luvas de Tecido Vil", "CRAFTING"}
        s["spell;created=23041"] = {"Chamar Anátema", "CRAFTING"}
        s["npc;drop=14516"] = {"Cavaleiro da Morte Noctilatrus", "Scolomântia"}
        s["spell;created=461962"] = {"Chamar Anátema", "CRAFTING"}
        s["npc;drop=1843"] = {"Encarregado Jerris", "Terras Pestilentas Ocidentais"}
        s["npc;drop=12801"] = {"Quiméroco Arcano", "Feralas"}
        s["npc;drop=228914"] = {"[Severed Keeper]", "Cânion do Demônio Caído"}
        s["npc;drop=11469"] = {"Furiário Eldretiano", "Gládio Cruel"}
        s["npc;drop=14506"] = {"Lorde Hel'nurath", "Gládio Cruel"}
        s["npc;drop=15975"] = {"Tecelã Putrífaga", "Naxxramas"}
        s["npc;drop=1838"] = {"Interrogador Escarlate", "Terras Pestilentas Ocidentais"}
        s["npc;drop=1851"] = {"Cascabulho", "Terras Pestilentas Ocidentais"}
        s["npc;drop=7104"] = {"Áridus", "Selva Maleva"}
        s["npc;drop=15757"] = {"Tenente-general Qiraji", "Silithus"}
        s["npc;drop=15390"] = {"Capitão Xurrem", "Ruínas de Ahn'Qiraj"}
        s["npc;drop=10371"] = {"Capitão Garra Furiosa", "Pico da Rocha Negra"}
        s["npc;drop=11896"] = {"Brocassangre", "Terras Pestilentas Orientais"}
        s["npc;drop=7459"] = {"Matriarca Cardo de Gelo", "Hibérnia"}
        s["npc;drop=10663"] = {"Patamana", "Hibérnia"}
        s["spell;created=18442"] = {"Capuz de Tecido Vil", "CRAFTING"}
        s["npc;drop=11143"] = {"Chefe do Correio Malown", "Stratholme"}
        s["spell;created=19794"] = {"Óculos de Poder Mágico Xtremo Plus", "CRAFTING"}
        s["npc;drop=11622"] = {"Ossorrange", "Scolomântia"}
        s["object;contained=181074"] = {"Espólios de Arena", "Abismo Rocha Negra"}
        s["spell;created=18451"] = {"Veste de Tecido Vil", "CRAFTING"}
        s["npc;drop=9817"] = {"Terrorista da Mão Negra <Legião da Mão Negra>", "Pico da Rocha Negra"}
        s["npc;drop=10372"] = {"Língua de Fogo Garra Furiosa", "Pico da Rocha Negra"}
        s["npc;drop=11490"] = {"Zevrim Cascardo", "Gládio Cruel"}
        s["npc;drop=10901"] = {"Erudito Pulquério", "Scolomântia"}
        s["spell;created=18454"] = {"Luvas de Maestria em Feitiçaria", "CRAFTING"}
        s["spell;created=18419"] = {"Calças de Tecido Vil", "CRAFTING"}
        s["npc;drop=10436"] = {"Baronesa Anastari", "Stratholme"}
        s["npc;drop=10558"] = {"Cantalar Forresten", "Stratholme"}
        s["npc;drop=9217"] = {"Mestre Mago Agulhapétrea", "Pico da Rocha Negra"}
        s["npc;drop=6228"] = {"Embaixador Ferro Negro", "Gnomeregan"}
        s["npc;drop=6370"] = {"Pateante Makrinni", "Azshara"}
        s["quest;reward=9004"] = {"Deixando o melhor para o final", "Altaforja"}
        s["quest;reward=8956"] = {"As últimas palavras de Anthion", "Altaforja"}
        s["quest;reward=8910"] = {"Uma proposta honesta", "Altaforja"}
        s["quest;reward=8941"] = {"Recompensa justa", "Orgrimmar"}
        s["quest;reward=8639"] = {"Elmo do Causamortis", "Ahn'Qiraj"}
        s["quest;reward=8641"] = {"Espaldares do Causamortis", "Ahn'Qiraj"}
        s["quest;reward=8638"] = {"Colete do Causamortis", "Ahn'Qiraj"}
        s["npc;drop=10505"] = {"Instrutora Malícia", "Scolomântia"}
        s["quest;reward=8201"] = {"Uma coleção de cabeças", "Selva do Espinhaço"}
        s["npc;drop=9265"] = {"Caçador Sombrio Fumocardo", "Pico da Rocha Negra"}
        s["quest;reward=8640"] = {"Perneiras do Causamortis", "Ahn'Qiraj"}
        s["quest;reward=8637"] = {"Botas do Causamortis", "Ahn'Qiraj"}
        s["npc;drop=14507"] = {"Sumo Sacerdote Venoxis", "Zul'Gurub"}
        s["quest;reward=7498"] = {"Garona: Um Estudo sobre Furtividade e Traição", "Gládio Cruel"}
        s["quest;reward=7787"] = {"Erga-se, Tormentária!", "Silithus"}
        s["npc;drop=203138"] = {"Feitor Furiadastra", "Abismo Rocha Negra"}
        s["spell;created=461237"] = {"Caveira de Chama Sombria", "CRAFTING"}
        s["spell;created=19090"] = {"Omoplatas do Véu da Tempestade", "CRAFTING"}
        s["spell;created=19079"] = {"Armadura do Véu da Tempestade", "CRAFTING"}
        s["quest;reward=84152"] = {"[An Earnest Proposition]", "Altaforja"}
        s["spell;created=26279"] = {"Luvas do Véu da Tempestade", "CRAFTING"}
        s["npc;drop=10318"] = {"Assassino da Mão Negra <Legião da Mão Negra>", "Pico da Rocha Negra"}
        s["spell;created=19067"] = {"Calças do Véu da Tempestade", "CRAFTING"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "Gládio Cruel"}
        s["npc;drop=15741"] = {"Colosso de Régia", "Silithus"}
        s["quest;reward=53"] = {"Doce âmbar", "Cerro Oeste"}
        s["npc;drop=2601"] = {"Buchorrendo", "Planalto Arathi"}
        s["npc;drop=2751"] = {"Golem de Guerra", "Ermos"}
        s["spell;created=9201"] = {"Braçadeiras Crepusculares", "CRAFTING"}
        s["quest;reward=80455"] = {"Esperando a nossa hora", "Floresta de Pinhaprata"}
        s["npc;drop=15209"] = {"Templário Carmesim", "Silithus"}
        s["spell;created=23706"] = {"Dragonas Douradas da Aurora", "CRAFTING"}
        s["spell;created=19068"] = {"Arnês de Urso de Guerra", "CRAFTING"}
        s["npc;drop=9237"] = {"Senhor da Guerra Voone", "Pico da Rocha Negra"}
        s["npc;drop=15817"] = {"General de Brigada Qiraji Pax-lish", "Silithus"}
        s["quest;reward=8623"] = {"Diadema do Tempestário", "Ahn'Qiraj"}
        s["quest;reward=9011"] = {"Deixando o melhor para o final", "Orgrimmar"}
        s["quest;reward=7668"] = {"A ameaça de Noctilatrus", "Orgrimmar"}
        s["quest;reward=8602"] = {"Brafoneiras do Tempestário", "Ahn'Qiraj"}
        s["spell;created=16650"] = {"Cota de Malha Cardagreste", "CRAFTING"}
        s["quest;reward=8622"] = {"Cota do Tempestário", "Ahn'Qiraj"}
        s["quest;reward=8918"] = {"Uma proposta honesta", "Orgrimmar"}
        s["npc;drop=14454"] = {"O Teceventos", "Silithus"}
        s["quest;reward=8621"] = {"Guarda-pés do Tempestário", "Ahn'Qiraj"}
        s["npc;drop=11462"] = {"Arvoroso Lenhatorta", "Gládio Cruel"}
        s["quest;reward=7505"] = {"O Choque Gélido e Você", "Gládio Cruel"}
        s["quest;reward=82113"] = {"O vodu", "Montanhas de Alterac"}
        s["spell;created=461735"] = {"Malha Invencível", "CRAFTING"}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", "Orgrimmar"}
        s["npc;drop=11043"] = {"Monge Carmesim", "Stratholme"}
        s["spell;created=461737"] = {"Manoplas da Tormenta", "CRAFTING"}
        s["npc;drop=10083"] = {"Flamescama Garra Furiosa", "Pico da Rocha Negra"}
        s["npc;drop=10814"] = {"Guarda de Elite Cromático", "Pico da Rocha Negra"}
        s["npc;drop=14323"] = {"Guarda Kishutt", "Gládio Cruel"}
        s["spell;created=446186"] = {"Guarda-Ombros Encadeados Cacofônicos", "CRAFTING"}
        s["spell;created=451706"] = {"Brafoneiras Encadeadas Guinchantes", "CRAFTING"}
        s["npc;drop=9028"] = {"Resmungo", "Abismo Rocha Negra"}
        s["spell;created=24138"] = {"Manoplas Almassangre", "CRAFTING"}
        s["npc;drop=224257"] = {"[Atal'ai Slave]", "Templo de Atal'Hakkar"}
        s["spell;created=435958"] = {"Engrenomuralha de Veraprata Rodopiante", "CRAFTING"}
        s["spell;created=19094"] = {"Omoplatas de Escama de Dragão Preta", "CRAFTING"}
        s["spell;created=23708"] = {"Manoplas Cromáticas", "CRAFTING"}
        s["spell;created=19107"] = {"Perneiras de Escama de Dragão Preta", "CRAFTING"}
        s["spell;created=20855"] = {"Botas de Escama de Dragão Preta", "CRAFTING"}
        s["spell;created=23653"] = {"Martelo do Ocaso", "CRAFTING"}
        s["npc;drop=6117"] = {"Sub-lich Altaneiro", "Azshara"}
        s["spell;created=19085"] = {"Peitoral de Escama de Dragão Preta", "CRAFTING"}
        s["npc;drop=10507"] = {"O Corvino", "Scolomântia"}
        s["spell;created=16991"] = {"Aniquilador", "CRAFTING"}
        s["npc;drop=12258"] = {"Azorrague", "Maraudon"}
        s["npc;drop=7358"] = {"Amnennar, o Frigífero", "Urzal dos Mortos"}
        s["quest;reward=79366"] = {"A calmaria que precede a tempestade", "Mil Agulhas"}
        s["npc;drop=13596"] = {"Putrigarra", "Maraudon"}
        s["quest;reward=8624"] = {"Perneiras do Tempestário", "Ahn'Qiraj"}
        s["quest;reward=7488"] = {"A teia de Letendris", "Feralas"}
        s["quest;reward=5526"] = {"Pedaços de Vinhavil", "Clareira da Lua"}
        s["spell;created=8770"] = {"Veste do Poder", "CRAFTING"}
        s["npc;drop=7357"] = {"Mordresh Olho-de-Fogo", "Urzal dos Mortos"}
        s["spell;created=24356"] = {"Óculos Vinassangre", "CRAFTING"}
        s["quest;reward=8662"] = {"Diadema do Arauto da Ruína", "Ahn'Qiraj"}
        s["quest;reward=9005"] = {"[Saving the Best for Last]", "Altaforja"}
        s["quest;reward=8664"] = {"Dragonas do Arauto da Ruína", "Ahn'Qiraj"}
        s["quest;reward=8661"] = {"Vestes do Arauto da Ruína", "Ahn'Qiraj"}
        s["spell;created=18458"] = {"Veste do Caos", "CRAFTING"}
        s["quest;reward=8936"] = {"Recompensa justa", "Altaforja"}
        s["quest;reward=8381"] = {"Armamentos de Guerra", "Silithus"}
        s["spell;created=24201"] = {"Criar Runa da Aurora", "CRAFTING"}
        s["quest;reward=7502"] = {"Sombras Agrilhoantes", "Gládio Cruel"}
        s["spell;created=461747"] = {"Colete de Lunatrama Incandescente", "CRAFTING"}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", "Altaforja"}
        s["spell;created=23662"] = {"Sabedoria dos Presamatos", "CRAFTING"}
        s["spell;created=462282"] = {"Molde: Cinto Ornado do Arquimago", "CRAFTING"}
        s["npc;drop=15220"] = {"O Duque dos Zéfiros <Conselho Abissal>", "Silithus"}
        s["spell;created=429351"] = {"Botas de Sedaracna Extraplanares", "CRAFTING"}
        s["npc;drop=15203"] = {"Príncipe Skaldrenox", "Silithus"}
        s["spell;created=19830"] = {"Dragonete de Arcanita", "CRAFTING"}
        s["spell;created=461743"] = {"Lâmina do Sábio do Arquimago", "CRAFTING"}
        s["spell;created=20848"] = {"Dragonas do Núcleo Flamífero", "CRAFTING"}
        s["npc;drop=10376"] = {"Presa de Cristal", "Pico da Rocha Negra"}
        s["spell;created=446195"] = {"Ombreiras do Delírio", "CRAFTING"}
        s["spell;created=22870"] = {"Manto de Proteção", "CRAFTING"}
        s["npc;drop=9439"] = {"Guardião Sombrio Uggel", "Abismo Rocha Negra"}
        s["spell;created=19093"] = {"Manto de Escama da Onyxia", "CRAFTING"}
        s["spell;created=20849"] = {"Luvas do Núcleo Flamífero", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "Orgrimmar"}
        s["quest;reward=5942"] = {"Tesouros escondidos", "Terras Pestilentas Orientais"}
        s["quest;reward=1560"] = {"A missão de Tuga", "Tanaris"}
        s["npc;drop=15208"] = {"O Duque dos Estilhaços <Conselho Abissal>", "Silithus"}
        s["spell;created=23666"] = {"Veste do Núcleo Flamífero", "CRAFTING"}
        s["quest;reward=80141"] = {"[Nogg's Ring Redo]", "Orgrimmar"}
        s["quest;reward=82107"] = {"[Voodoo Feathers]", "Pântano das Mágoas"}
        s["npc;drop=8762"] = {"Reclusa Xilaracna", "Azshara"}
        s["quest;reward=3129"] = {"Armas de espírito", "Feralas"}
        s["quest;reward=84162"] = {"Uma proposta honesta", "Orgrimmar"}
        s["quest;reward=9006"] = {"Deixando o melhor para o final", "Altaforja"}
        s["quest;reward=8561"] = {"Coroa do Conquistador", "Ahn'Qiraj"}
        s["quest;reward=8544"] = {"Espaldares do Conquistador", "Ahn'Qiraj"}
        s["quest;reward=8562"] = {"Peitoral do Conquistador", "Ahn'Qiraj"}
        s["quest;reward=8937"] = {"Recompensa justa", "Altaforja"}
        s["quest;reward=8560"] = {"Guarda-pernas do Conquistador", "Ahn'Qiraj"}
        s["quest;reward=8559"] = {"Grevas do Conquistador", "Ahn'Qiraj"}
        s["quest;reward=9022"] = {"As últimas palavras de Anthion", "Scolomântia"}
        s["quest;reward=8789"] = {"Armamentos Imperiais Qiraji", "Ahn'Qiraj"}
        s["spell;created=9954"] = {"Manoplas Veraprata", "CRAFTING"}
        s["quest;reward=3566"] = {"Erga-se, Obsidião!", "Garganta Abrasadora"}
        s["quest;reward=84550"] = {"[Codex of Defense]", "Gládio Cruel"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "Covil Asa Negra"}
        s["spell;created=452433"] = {"Evocar Gla'sir", "CRAFTING"}
        s["npc;drop=231494"] = {"[Prince Thunderaan] <[The Wind Seeker]>", "Vale de Cristal"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "Ventobravo"}
        s["spell;created=452434"] = {"Evocar Rae'lar", "CRAFTING"}
        s["npc;drop=14510"] = {"Alta-sacerdotisa Mar'li", "Zul'Gurub"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "Cânion do Demônio Caído"}
        s["spell;created=461710"] = {"Rifle de Atirador de Elite do Núcleo de Fogo", "CRAFTING"}
        s["spell;created=466117"] = {"Harmonizar Cajado da Geada", "CRAFTING"}
        s["spell;created=465417"] = {"Alterar Postura", "CRAFTING"}
        s["spell;created=465418"] = {"Alterar Postura", "CRAFTING"}
        s["npc;drop=227939"] = {"[The Molten Core]", "Núcleo Derretido"}
        s["npc;drop=15085"] = {"Vuxulai", "Zul'Gurub"}
        s["spell;created=469201"] = {"Deflagrar Chamas", "CRAFTING"}
        s["spell;created=468840"] = {"Combinar Foice do Caos", "CRAFTING"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Covil Asa Negra"}
        s["spell;created=467790"] = {"Combinar Cajado da Ordem", "CRAFTING"}
        s["npc;drop=16011"] = {"Repugnaz", "Naxxramas"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "Montanhas de Alterac"}
        s["quest;reward=85454"] = {"[A Just Reward]", "Pantanal"}
        s["npc;drop=15369"] = {"Ayamiss, o Caçador", "Ruínas de Ahn'Qiraj"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "Silithus"}
        s["spell;created=1216020"] = {"Ídolo da Ira Sideral", "CRAFTING"}
        s["spell;created=1213538"] = {"Manto de Seda Qiraji", "CRAFTING"}
        s["npc;drop=15370"] = {"Buru, o Banqueteador", "Ruínas de Ahn'Qiraj"}
        s["npc;drop=235197"] = {"[Taerar]", "Vale Gris"}
        s["npc;sold=15192"] = {"Anacronos", "Tanaris"}
        s["spell;created=1213595"] = {"Lágrima da Sonhadora", "CRAFTING"}
        s["spell;created=1213502"] = {"Martelo da Tempestade Obsidiano", "CRAFTING"}
        s["npc;sold=15500"] = {"Keyl Garralesta", "Silithus"}
        s["spell;created=1216340"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1216022"] = {"Ídolo de Ferocidade Felina", "CRAFTING"}
        s["npc;drop=228230"] = {"Harolges <O Submercado>", "Estepes Ardentes"}
        s["spell;created=1213536"] = {"Capa de Seda Qiraji", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "Silithus"}
        s["spell;created=23704"] = {"Soqueiras dos Presamatos", "CRAFTING"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "Silithus"}
        s["spell;created=1213593"] = {"Pedracélere", "CRAFTING"}
        s["spell;created=1216385"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213500"] = {"Destruidor Obsidiano", "CRAFTING"}
        s["spell;created=1216024"] = {"Ídolo de Poder Ursino", "CRAFTING"}
        s["spell;created=24121"] = {"Gibão Primevo de Pele de Morcego", "CRAFTING"}
        s["spell;created=1213738"] = {"Elmo de Sarça", "CRAFTING"}
        s["spell;created=1213736"] = {"Botas de Sarça", "CRAFTING"}
        s["spell;created=1213598"] = {"Magnetita da Retaliação", "CRAFTING"}
        s["spell;created=1216366"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213521"] = {"Capucho de Espinheira-brava", "CRAFTING"}
        s["spell;created=1213525"] = {"Couros de Espinheira-brava", "CRAFTING"}
        s["spell;created=1213523"] = {"Ombreiras de Espinheira-brava", "CRAFTING"}
        s["npc;drop=15348"] = {"Korinnaxx", "Ruínas de Ahn'Qiraj"}
        s["npc;drop=15544"] = {"Veim", "Ahn'Qiraj"}
        s["spell;created=1213603"] = {"Broche Incrustado de Rubis", "CRAFTING"}
        s["spell;created=1216319"] = {"Tocado pelo Caos", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "Silithus"}
        s["spell;created=1213635"] = {"Cogumelo Encantado", "CRAFTING"}
        s["spell;created=1213540"] = {"Clâmide de Seda Qiraji", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "Terras Agrestes"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "Silithus"}
        s["quest;reward=86674"] = {"[The Perfect Poison]", "Silithus"}
        s["spell;created=1216365"] = {"Tocado pelo Caos", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Cratera Un'Goro"}
        s["spell;created=24137"] = {"Omoplatas Almassangre", "CRAFTING"}
        s["spell;created=1216384"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1216387"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1216327"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=466116"] = {"Harmonizar Cajado do Inferno", "CRAFTING"}
        s["spell;created=1213628"] = {"Tomo Encantado de Orações", "CRAFTING"}
        s["quest;reward=86672"] = {"[Imperial Qiraji Armaments]", "Covil Asa Negra"}
        s["spell;created=1216005"] = {"Incunábulo da Retidão", "CRAFTING"}
        s["spell;created=1213481"] = {"Jaula Craniana Aguilâmina", "CRAFTING"}
        s["spell;created=1213484"] = {"Placa d'Ombros Aguilâmina", "CRAFTING"}
        s["spell;created=1214884"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213588"] = {"Disco de Força Reativa Ajustado", "CRAFTING"}
        s["spell;created=1214270"] = {"Escudo Serrilhado Obsidiano", "CRAFTING"}
        s["spell;created=1213490"] = {"Loriga Aguilâmina", "CRAFTING"}
        s["spell;created=1213506"] = {"Defensor Obsidiano", "CRAFTING"}
        s["spell;created=1216379"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1216007"] = {"Incunábulo do Exorcista", "CRAFTING"}
        s["spell;created=1216382"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213534"] = {"Lenço de Seda Qiraji", "CRAFTING"}
        s["spell;created=1216375"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213492"] = {"Aniquilador Obsidiano", "CRAFTING"}
        s["spell;created=1216377"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213498"] = {"Campeão Obsidiano", "CRAFTING"}
        s["quest;reward=86671"] = {"[Imperial Qiraji Regalia]", "Covil Asa Negra"}
        s["npc;drop=234880"] = {"[Emeriss]", "Floresta do Crepúsculo"}
        s["spell;created=1216354"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1216014"] = {"Totem de Trovão Piroclástico", "CRAFTING"}
        s["spell;created=1213742"] = {"Coroa Silvestre", "CRAFTING"}
        s["spell;created=1213740"] = {"Omoplatas Silvestres", "CRAFTING"}
        s["spell;created=28210"] = {"Abraço de Gaia", "CRAFTING"}
        s["spell;created=1213744"] = {"Colete Silvestre", "CRAFTING"}
        s["spell;created=1214306"] = {"Braçadeiras de Escama de Sonhos", "CRAFTING"}
        s["spell;created=1214307"] = {"Luvetes de Escama de Sonhos", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "Feralas"}
        s["quest;reward=9248"] = {"Uma humilde oferenda", "Silithus"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "Covil Asa Negra"}
        s["spell;created=1213532"] = {"Veste Vampírica", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "Covil Asa Negra"}
        s["spell;created=1216372"] = {"Tocado pelo Caos", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "Silithus"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ahn'Qiraj"}
        s["quest;reward=86760"] = {"[Darkmoon Beast Deck]", "Floresta de Elwynn"}
        s["quest;reward=86762"] = {"[Darkmoon Elementals Deck]", "Floresta de Elwynn"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Clareira da Lua"}
        s["spell;created=1214303"] = {"Kilt de Escama de Sonhos", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "Hibérnia"}
        s["npc;drop=3975"] = {"Herodes <O Campeão Escarlate>", "Monastério Escarlate"}
        s["spell;created=1216364"] = {"Tocado pelo Caos", "CRAFTING"}
        s["spell;created=1213633"] = {"Totem Encantado", "CRAFTING"}
        s["spell;created=1216381"] = {"Tocado pelo Caos", "CRAFTING"}
        s["npc;sold=16135"] = {"Rayne", "Terras Pestilentas Orientais"}
        s["npc;drop=16061"] = {"Instrutor Razúvio", "Naxxramas"}
        s["quest;reward=87360"] = {"[The Fall of Kel'Thuzad]", "Terras Pestilentas Orientais"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "Criptas de Karazhan"}
        s["npc;drop=16143"] = {"Sombra da Perdição", "Barreira do Inferno"}
        s["npc;drop=16380"] = {"Bruxa dos Ossos", "Estepes Ardentes"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "Terras Pestilentas Orientais"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Terras Pestilentas Orientais"}
        s["npc;drop=16060"] = {"Gothik, o Ceifador", "Naxxramas"}
        s["npc;drop=15936"] = {"Heigan, o Sujo", "Naxxramas"}
        s["npc;drop=14697"] = {"Horror Claudicante", "Estepes Ardentes"}
        s["npc;drop=237439"] = {"[Kharon]", "Criptas de Karazhan"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "Terras Pestilentas Orientais"}
        s["npc;drop=15953"] = {"Grã-viúva Faerlina", "Naxxramas"}
        s["npc;drop=15954"] = {"Noth, o Pestífero", "Naxxramas"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "Criptas de Karazhan"}
        s["spell;created=1223762"] = {"Manto Glacial", "CRAFTING"}
        s["npc;drop=16028"] = {"Retalhoso", "Naxxramas"}
        s["npc;drop=238055"] = {"[Dark Rider]", "Criptas de Karazhan"}
        s["npc;drop=238560"] = {"[The Warden]", "Criptas de Karazhan"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "Criptas de Karazhan"}
        s["spell;created=24179"] = {"Criar Selo da Aurora", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "Criptas de Karazhan"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "Terras Pestilentas Orientais"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "Criptas de Karazhan"}
        s["npc;drop=16379"] = {"Espírito dos Malditos", "Estepes Ardentes"}
        s["npc;sold=16132"] = {"Guarda-caça Leopold", "Terras Pestilentas Orientais"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "Terras Pestilentas Orientais"}
        s["npc;sold=16116"] = {"Arquimaga Ângela Santoro", "Terras Pestilentas Orientais"}
        s["npc;sold=16115"] = {"Commander Eligor Dawnbringer", "Terras Pestilentas Orientais"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "Terras Pestilentas Orientais"}
        s["spell;created=1223787"] = {"Peitoral da Perdição Gélida", "CRAFTING"}
        s["spell;created=1223791"] = {"Braçadeiras da Perdição Gélida", "CRAFTING"}
        s["spell;created=1223789"] = {"Manoplas da Perdição Gélida", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Terras Pestilentas Orientais"}
        s["spell;created=1223780"] = {"Túnica Polar", "CRAFTING"}
        s["spell;created=1223784"] = {"Braçadeiras Polares", "CRAFTING"}
        s["spell;created=1223782"] = {"Luvas Polares", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "Tanaris"}
        s["npc;sold=16113"] = {"Padre Inigo Montoy", "Terras Pestilentas Orientais"}
        s["spell;created=1223760"] = {"Colete Glacial", "CRAFTING"}
        s["spell;created=1223764"] = {"Luvas Glaciais", "CRAFTING"}
        s["npc;sold=16131"] = {"Rohan, o Assassino", "Terras Pestilentas Orientais"}
        s["spell;created=1214137"] = {"Acerta-peito Obsidiano", "CRAFTING"}
        s["npc;sold=16134"] = {"Rimblat Quebraterra", "Terras Pestilentas Orientais"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "Criptas de Karazhan"}
        s["spell;created=1223766"] = {"Pulsos Glaciais", "CRAFTING"}
        s["spell;created=1223772"] = {"Pulsos Gélidos", "CRAFTING"}
        s["npc;sold=16133"] = {"Mataus, o Arauto da Ira", "Terras Pestilentas Orientais"}
        s["spell;created=1213504"] = {"Lâmina do Sábio Obsidiana", "CRAFTING"}
        s["spell;created=1213527"] = {"Capucho Vampírico", "CRAFTING"}
        s["spell;created=1213530"] = {"Xale Vampírico", "CRAFTING"}
        s["npc;sold=16112"] = {"Korfax, Champion of the Light", "Terras Pestilentas Orientais"}
        s["spell;created=1214145"] = {"Espingarda Obsidiana", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Terras Pestilentas Orientais"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Stratholme"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "Tanaris"}
    end

    function SpecBisTooltip:TranslationruRU()
        s["npc;drop=11583"] = {"Нефариан", "Логово Крыла Тьмы"}
        s["npc;drop=11502"] = {"Рагнарос", "Огненные Недра"}
        s["npc;drop=12435"] = {"Бритвосмерт Неукротимый", "Логово Крыла Тьмы"}
        s["npc;drop=14834"] = {"Хаккар", "Зул'Гуруб"}
        s["spell;created=24091"] = {"Жилет Кровавой Лозы", "CRAFTING"}
        s["npc;drop=12017"] = {"Предводитель драконов Разящий Бич", "Логово Крыла Тьмы"}
        s["npc;drop=11380"] = {"Джин'до Проклинатель", "Зул'Гуруб"}
        s["npc;drop=11983"] = {"Огнечрев", "Логово Крыла Тьмы"}
        s["spell;created=24092"] = {"Поножи Кровавой Лозы", "CRAFTING"}
        s["spell;created=24093"] = {"Сапоги Кровавой Лозы", "CRAFTING"}
        s["npc;drop=12098"] = {"Предвестник Сульфурон", "Огненные Недра"}
        s["npc;drop=14601"] = {"Черноскал", "Логово Крыла Тьмы"}
        s["quest;reward=8183"] = {"Сердце Хаккара", "Тернистая долина"}
        s["npc;sold=13217"] = {"Тантальдис Снегоблеск <Снабженец клана Грозовой Вершины>", "Альтеракские горы"}
        s["npc;drop=10363"] = {"Генерал Драккисат", "Вершина Черной горы"}
        s["npc;drop=10435"] = {"Мировой судья Бартилас", "Стратхольм"}
        s["spell;created=12622"] = {"Зеленая линза", "CRAFTING"}
        s["spell;created=12092"] = {"Венец из ткани Грез", "CRAFTING"}
        s["npc;drop=11261"] = {"Доктор Теолен Крастинов <Мясник>", "Некроситет"}
        s["npc;sold=12777"] = {"Капитан Сокрушающий Молот", "Альтеракская долина"}
        s["npc;sold=12792"] = {"Леди Палансиэр <Начальник снабжения доспехами>", "Альтеракская долина"}
        s["npc;drop=9018"] = {"Верховный дознаватель Герштан <Дознаватель культа Сумеречного Молота>", "Глубины Черной горы"}
        s["npc;drop=14353"] = {"Миззл Умелец", "Забытый Город"}
        s["npc;drop=10811"] = {"Архивариус Галфорд", "Стратхольм"}
        s["npc;drop=15727"] = {"К'Тун", "Ан'Кираж"}
        s["npc;drop=9319"] = {"Псарь Гребмар", "Глубины Черной горы"}
        s["npc;drop=11487"] = {"Магистр Календрис", "Забытый Город"}
        s["npc;sold=13218"] = {"Грюнда Волчье Сердце", "Альтеракская долина"}
        s["quest;reward=7861"] = {"Разыскивается: коварная жрица Ведьмиса и ее прислужники", "Внутренние земли"}
        s["npc;drop=12118"] = {"Люцифрон", "Огненные Недра"}
        s["npc;drop=11496"] = {"Бессмер'тер", "Забытый Город"}
        s["npc;drop=11486"] = {"Принц Тортелдрин", "Забытый Город"}
        s["npc;drop=15815"] = {"Киражский капитан Ка'арк", "Тысяча Игл"}
        s["npc;drop=10508"] = {"Рас Снегошепот", "Некроситет"}
        s["npc;sold=14753"] = {"Иллиана Лунное Сияние <Снабженец Среброкрылых>", "Ясеневый лес"}
        s["quest;reward=8574"] = {"Стойкая броня", "Силитус"}
        s["npc;drop=9017"] = {"Лорд Опалитель", "Глубины Черной горы"}
        s["npc;drop=10516"] = {"Непрощенный", "Стратхольм"}
        s["npc;drop=14326"] = {"Стражник Мол'дар", "Забытый Город"}
        s["npc;drop=11662"] = {"Поджигатель-жрец", "Огненные Недра"}
        s["npc;drop=12397"] = {"Владыка Каззак", "Выжженные земли"}
        s["npc;drop=10584"] = {"Аррок Смертный Вопль", "Вершина Черной горы"}
        s["npc;drop=14020"] = {"Хроммагус", "Логово Крыла Тьмы"}
        s["npc;drop=9736"] = {"Интендант Зигрис <Легион Кровавого Топора>", "Вершина Черной горы"}
        s["quest;reward=8464"] = {"Боевые действия в деревне Зимней Спячки", "Зимние Ключи"}
        s["npc;drop=5719"] = {"Морфаз", "Храм Атал'Хаккара"}
        s["spell;created=12067"] = {"Перчатки из ткани Грез", "CRAFTING"}
        s["npc;drop=12056"] = {"Барон Геддон", "Огненные Недра"}
        s["npc;drop=9030"] = {"Ок'тор Разрушитель", "Глубины Черной горы"}
        s["npc;sold=13219"] = {"Джекилл Флендринг <Снабженец клана Северного Волка>", "Альтеракские горы"}
        s["spell;created=3864"] = {"Звездный пояс", "CRAFTING"}
        s["npc;drop=10437"] = {"Неруб'энкан", "Стратхольм"}
        s["npc;drop=12119"] = {"Заступник-поджигатель", "Огненные Недра"}
        s["npc;drop=9196"] = {"Вождь Омокк", "Вершина Черной горы"}
        s["npc;drop=6109"] = {"Азурегос", "Азшара"}
        s["spell;created=23667"] = {"Поножи с сияющей сердцевиной", "CRAFTING"}
        s["npc;drop=7267"] = {"Вождь Укорз Песчаная Плешь", "Зул'Фаррак"}
        s["npc;drop=8983"] = {"Повелитель големов Аргелмах", "Глубины Черной горы"}
        s["npc;drop=15276"] = {"Император Век'лор", "Ан'Кираж"}
        s["npc;drop=13280"] = {"Гидротварь", "Забытый Город"}
        s["npc;drop=10429"] = {"Вождь Ренд Чернорук", "Вершина Черной горы"}
        s["npc;drop=10997"] = {"Мастер-канонир Вилли", "Стратхольм"}
        s["npc;drop=10812"] = {"Верховный рыцарь Датрохан", "Стратхольм"}
        s["npc;drop=15275"] = {"Император Век'нилаш", "Ан'Кираж"}
        s["npc;drop=15742"] = {"Колосс Аши", "Силитус"}
        s["npc;drop=16042"] = {"Лорд Вальтхалак", "Вершина Черной горы"}
        s["quest;reward=8802"] = {"Спаситель Калимдора", "Ан'Кираж"}
        s["quest;reward=4363"] = {"Королевский сюрприз", "Глубины Черной горы"}
        s["quest;reward=4004"] = {"Спасенная принцесса", "Глубины Черной горы"}
        s["quest;reward=7491"] = {"На виду у всех", "Оргриммар"}
        s["npc;sold=14754"] = {"Кельм Харгюнт <Снабженец Песни Войны>", "Степи"}
        s["npc;drop=11982"] = {"Магмадар", "Огненные Недра"}
        s["npc;drop=10509"] = {"Джед Руновед <Легион Чернорука>", "Вершина Черной горы"}
        s["quest;reward=5102"] = {"Кончина генерала Драккисата", "Пылающие степи"}
        s["npc;drop=9156"] = {"Посол Огнехлыст", "Глубины Черной горы"}
        s["npc;sold=12782"] = {"Капитан О'Нил", "Альтеракская долина"}
        s["npc;sold=14581"] = {"Сержант Громовой Рог <Начальник снабжения оружием>", "Альтеракская долина"}
        s["npc;sold=15126"] = {"Резерфорд Оттяжка <Снабженец Осквернителей>", "Нагорье Арати"}
        s["npc;sold=15127"] = {"Самуэль Хок <Снабженец Лиги Аратора>", "Нагорье Арати"}
        s["npc;drop=12057"] = {"Гарр", "Огненные Недра"}
        s["npc;drop=12259"] = {"Гееннас", "Огненные Недра"}
        s["npc;drop=1853"] = {"Темный магистр Гандлинг", "Некроситет"}
        s["npc;drop=10899"] = {"Горалук Треснувшая Наковальня <Бронник легиона Чернорука>", "Вершина Черной горы"}
        s["npc;drop=11492"] = {"Алззин Перевертень", "Забытый Город"}
        s["quest;reward=8790"] = {"Киражские императорские регалии", "Ан'Кираж"}
        s["npc;drop=11988"] = {"Големагг Испепелитель", "Огненные Недра"}
        s["npc;drop=2585"] = {"Стромгардский воздаятель", "Нагорье Арати"}
        s["quest;reward=82112"] = {"Лучший ингредиент", "Кратер Ун'Горо"}
        s["npc;drop=7271"] = {"Знахарь Зум'рах", "Зул'Фаррак"}
        s["npc;drop=8440"] = {"Тень Хаккара", "Храм Атал'Хаккара"}
        s["npc;drop=5721"] = {"Жнец Снов", "Храм Атал'Хаккара"}
        s["object;contained=181083"] = {"Наследие Сотоса и Джариена", "Стратхольм"}
        s["quest;reward=7784"] = {"Владыка Черной горы", "Оргриммар"}
        s["quest;reward=3962"] = {"Один в поле не воин", "Кратер Ун'Горо"}
        s["npc;drop=4543"] = {"Волшебник Крови Талнос", "Монастырь Алого ордена"}
        s["npc;sold=227819"] = {"Герцог Гидраксис", "Огненные Недра"}
        s["npc;drop=228435"] = {"[Golemagg the Incinerator]", "Огненные Недра"}
        s["npc;sold=230319"] = {"Делиана", "Стальгорн"}
        s["npc;drop=228438"] = {"[Ragnaros]", "Огненные Недра"}
        s["npc;drop=228432"] = {"Гарр", "Огненные Недра"}
        s["npc;sold=227853"] = {"Пикс Ксиззикс <Торговец из Нижней шахты>", "Тернистая долина"}
        s["spell;created=446192"] = {"Мембрана темного невроза", "CRAFTING"}
        s["npc;drop=15205"] = {"Барон Казум", "Силитус"}
        s["spell;created=461653"] = {"Сверкающий разноцветный плащ", "CRAFTING"}
        s["npc;drop=228434"] = {"[Shazzrah]", "Огненные Недра"}
        s["npc;sold=222413"] = {"Исследователь Залго <Поставщик затерянных диковин>", "Тернистая долина"}
        s["quest;reward=84147"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["npc;drop=218819"] = {"Гнойная гнилослизь", "Храм Атал'Хаккара"}
        s["spell;created=429869"] = {"Меченные Бездной кожаные рукавицы", "CRAFTING"}
        s["npc;drop=220833"] = {"Жнец Снов", "Храм Атал'Хаккара"}
        s["npc;sold=222408"] = {"Эмиссар племени Темнозубов", "Оскверненный лес"}
        s["spell;created=461754"] = {"Ремень чародейского прозрения", "CRAFTING"}
        s["npc;drop=228433"] = {"[Baron Geddon]", "Огненные Недра"}
        s["object;contained=179703"] = {"Тайник повелителя огня", "Огненные Недра"}
        s["npc;drop=228429"] = {"[Lucifron]", "Огненные Недра"}
        s["npc;drop=14890"] = {"Таэрар", "Сумеречный лес"}
        s["npc;drop=226923"] = {"Мрачнокорень <Скорбящий страж>", "Каньон Гибели Демона"}
        s["npc;drop=12201"] = {"Принцесса Терадрас", "Мародон"}
        s["npc;drop=217280"] = {"Грязнюк", "Гномреган"}
        s["spell;created=461647"] = {"Безупречный буремолот небесного наездника", "CRAFTING"}
        s["npc;drop=4542"] = {"Верховный инквизитор Фэйрбанкс", "Монастырь Алого ордена"}
        s["npc;drop=204068"] = {"Леди Саревесс", "Непроглядная Пучина"}
        s["spell;created=12060"] = {"Красные штаны из магической ткани", "CRAFTING"}
        s["npc;drop=213334"] = {"Аку'май", "Непроглядная Пучина"}
        s["spell;created=439105"] = {"Большая вудуистская маска", "CRAFTING"}
        s["npc;drop=6490"] = {"Азшир Неспящий", "Монастырь Алого ордена"}
        s["spell;created=439093"] = {"Багровые шелковые наплечники", "CRAFTING"}
        s["quest;reward=82055"] = {"Колода карт Новолуния: Дюны", "Элвиннский лес"}
        s["quest;reward=82057"] = {"Колода карт Новолуния: Чума", "Элвиннский лес"}
        s["npc;drop=221637"] = {"Ранокол", "Храм Атал'Хаккара"}
        s["quest;reward=7940"] = {"1200 билетов – сфера Новолуния", "Мулгор"}
        s["npc;drop=218721"] = {"Джаммал'ан Пророк", "Храм Атал'Хаккара"}
        s["npc;sold=11557"] = {"Мелиош", "Оскверненный лес"}
        s["spell;created=10621"] = {"Волкоголовый шлем", "CRAFTING"}
        s["npc;drop=9816"] = {"Пиростраж Созерцатель Углей", "Вершина Черной горы"}
        s["npc;drop=12467"] = {"Капитан Когтя Смерти", "Логово Крыла Тьмы"}
        s["spell;created=23710"] = {"Оплавленный пояс", "CRAFTING"}
        s["npc;drop=11981"] = {"Пламегор", "Логово Крыла Тьмы"}
        s["npc;drop=6229"] = {"Толпогон 9-60", "Гномреган"}
        s["npc;drop=15206"] = {"Герцог Пепла", "Силитус"}
        s["npc;drop=9041"] = {"Тюремщик Стилгисс", "Глубины Черной горы"}
        s["quest;reward=4261"] = {"Древний дух", "Оскверненный лес"}
        s["npc;drop=10440"] = {"Барон Ривендер", "Стратхольм"}
        s["npc;drop=15511"] = {"Лорд Кри", "Ан'Кираж"}
        s["quest;reward=5068"] = {"Кираса кровавой жажды", "Зимние Ключи"}
        s["npc;drop=9019"] = {"Император Дагран Тауриссан", "Глубины Черной горы"}
        s["npc;drop=15516"] = {"Боевой страж Сартура", "Ан'Кираж"}
        s["spell;created=19084"] = {"Рукавицы девизавра", "CRAFTING"}
        s["npc;drop=11361"] = {"Зулианский тигр", "Зул'Гуруб"}
        s["npc;drop=15323"] = {"Пескоброд из улья Зара", "Руины Ан'Киража"}
        s["spell;created=19097"] = {"Поножи девизавра", "CRAFTING"}
        s["object;contained=181366"] = {"Сундук Четырех Всадников", "Наксрамас"}
        s["npc;drop=10399"] = {"Тузадинский послушник", "Стратхольм"}
        s["npc;drop=16097"] = {"Изалиен", "Забытый Город"}
        s["npc;drop=8929"] = {"Принцесса Мойра Бронзобород <Принцесса Стальгорна>", "Глубины Черной горы"}
        s["quest;reward=7981"] = {"1200 билетов – амулет Новолуния", "Мулгор"}
        s["npc;drop=15114"] = {"Газ'ранка", "Зул'Гуруб"}
        s["npc;drop=15517"] = {"Оуро", "Ан'Кираж"}
        s["quest;reward=7862"] = {"Требуется: капитан стражи в деревню Сломанного Клыка", "Внутренние земли"}
        s["npc;drop=9568"] = {"Властитель Змейталак", "Вершина Черной горы"}
        s["quest;reward=3321"] = {"Не ее ли ищете?", "Танарис"}
        s["npc;sold=12805"] = {"Офицер Арейн <Начальник снабжения>", "Штормград"}
        s["npc;sold=12799"] = {"Сержант Ба'ша <Начальник снабжения>", "Оргриммар"}
        s["npc;drop=12463"] = {"Огнекож Когтя Смерти", "Логово Крыла Тьмы"}
        s["quest;reward=7877"] = {"Сокровище Шен'дралар", "Забытый Город"}
        s["npc;drop=9025"] = {"Лорд Роккор", "Глубины Черной горы"}
        s["npc;drop=2748"] = {"Аркедас <Древний Каменный Страж>", "Ульдаман"}
        s["npc;drop=10503"] = {"Джандис Баров", "Некроситет"}
        s["spell;created=23707"] = {"Лавовый пояс", "CRAFTING"}
        s["npc;drop=228022"] = {"Призрак Разрушителя", "Каньон Гибели Демона"}
        s["npc;drop=227140"] = {"Пиранис", "Каньон Гибели Демона"}
        s["spell;created=460462"] = {"Око Сульфураса", "CRAFTING"}
        s["npc;drop=227028"] = {"Фантом Адского Крика", "Каньон Гибели Демона"}
        s["npc;drop=15204"] = {"Верховный маршал Круговёрт", "Силитус"}
        s["npc;drop=218624"] = {"Атал'аларион <Страж идола>", "Храм Атал'Хаккара"}
        s["npc;drop=228430"] = {"[Magmadar]", "Огненные Недра"}
        s["spell;created=24123"] = {"Изначальные наручи из кожи летучей мыши", "CRAFTING"}
        s["spell;created=24122"] = {"Изначальные перчатки из кожи летучей мыши", "CRAFTING"}
        s["npc;drop=10422"] = {"Багровый колдун", "Стратхольм"}
        s["quest;reward=84561"] = {"[For All To See]", "Оргриммар"}
        s["quest;reward=5944"] = {"Во сне", "Западные Чумные земли"}
        s["quest;reward=8949"] = {"Кровная месть Фарлина", "Забытый Город"}
        s["npc;sold=12944"] = {"Локтос Зловещий Торговец <Братство Тория>", "Глубины Черной горы"}
        s["npc;drop=228436"] = {"[Sulfuron Harbinger]", "Огненные Недра"}
        s["spell;created=461712"] = {"Отполированный молот титанов", "CRAFTING"}
        s["spell;created=16988"] = {"Молот Титанов", "CRAFTING"}
        s["npc;drop=221943"] = {"Хаззас", "Храм Атал'Хаккара"}
        s["npc;drop=7355"] = {"Тутен'каш", "Курганы Иглошкурых"}
        s["spell;created=461722"] = {"Рукавицы дьявосердца", "CRAFTING"}
        s["spell;created=461724"] = {"Поножи дьявосердца", "CRAFTING"}
        s["quest;reward=84545"] = {"[A Hero's Reward]", "Азшара"}
        s["npc;drop=15510"] = {"Фанкрисс Непреклонный", "Ан'Кираж"}
        s["npc;drop=15341"] = {"Генерал Раджакс", "Руины Ан'Киража"}
        s["npc;drop=15340"] = {"Моам", "Руины Ан'Киража"}
        s["npc;drop=10487"] = {"Восставший заступник", "Некроситет"}
        s["npc;drop=5717"] = {"Миджан", "Храм Атал'Хаккара"}
        s["npc;drop=15263"] = {"Пророк Скерам", "Ан'Кираж"}
        s["npc;drop=16449"] = {"Дух Наксрамаса", "Наксрамас"}
        s["npc;drop=12460"] = {"Змеестраж Когтя Смерти", "Логово Крыла Тьмы"}
        s["npc;drop=10430"] = {"Зверь", "Вершина Черной горы"}
        s["npc;drop=10500"] = {"Призрачный учитель", "Некроситет"}
        s["npc;drop=221407"] = {"Бес теневого сна", "Фералас"}
        s["npc;drop=10220"] = {"Халикон", "Вершина Черной горы"}
        s["npc;drop=15990"] = {"Кел'Тузад", "Наксрамас"}
        s["npc;drop=12264"] = {"Шаззрах", "Огненные Недра"}
        s["npc;drop=15952"] = {"Мексна", "Наксрамас"}
        s["quest;reward=9120"] = {"Падение Кел'Тузада", "Восточные Чумные земли"}
        s["spell;created=15596"] = {"Дымящееся Сердце Горы", "CRAFTING"}
        s["quest;reward=7067"] = {"Инструкции кентавра-парии", "Пустоши"}
        s["quest;reward=8573"] = {"Броня Защитника", "Силитус"}
        s["npc;drop=9547"] = {"Голодный завсегдатай", "Глубины Черной горы"}
        s["spell;created=461690"] = {"Изменчивый плащ искусной работы", "CRAFTING"}
        s["npc;drop=230302"] = {"[Lord Kazzak]", "Гниющий Шрам"}
        s["spell;created=435904"] = {"Нейрогномский светящийся клобук", "CRAFTING"}
        s["spell;created=23703"] = {"Мощь Древобрюхов", "CRAFTING"}
        s["spell;created=19080"] = {"Короткие штаны боевого медведя", "CRAFTING"}
        s["npc;sold=10857"] = {"Интендант Искромет из ордена Серебряного Рассвета <Серебряный Рассвет>", "Западные Чумные земли"}
        s["spell;created=23705"] = {"Рассветные вибрамы", "CRAFTING"}
        s["npc;sold=13278"] = {"Герцог Гидраксис", "Азшара"}
        s["npc;sold=218115"] = {"Май'зин <Меняла крови из племени Гурубаши>", "Тернистая долина"}
        s["npc;drop=204921"] = {"Гелихаст", "Непроглядная Пучина"}
        s["quest;reward=80324"] = {"Безумный король", "Стальгорн"}
        s["npc;drop=202699"] = {"Барон Акванис", "Непроглядная Пучина"}
        s["npc;drop=8567"] = {"Обжора", "Курганы Иглошкурых"}
        s["npc;drop=220007"] = {"Липкая муть", "Гномреган"}
        s["npc;sold=217689"] = {"Зири 'Гаечный Ключ' Шестерец <Техник-энтузиаст>", "Гномреган"}
        s["npc;drop=201722"] = {"Гхаму-ра", "Непроглядная Пучина"}
        s["npc;drop=220072"] = {"Электрошокер 6000", "Гномреган"}
        s["spell;created=429354"] = {"Меченные Бездной кожаные перчатки", "CRAFTING"}
        s["quest;reward=824"] = {"Дже'неу из Служителей Земли", "Ясеневый лес"}
        s["quest;reward=80132"] = {"Техновойны", "Оргриммар"}
        s["npc;drop=3669"] = {"Лорд Кобран", "Пещеры Стенаний"}
        s["npc;drop=215728"] = {"'Толпогон 9-60'", "Гномреган"}
        s["npc;drop=218537"] = {"Анжинер Термоштепсель", "Гномреган"}
        s["npc;drop=4295"] = {"Мирмидон из Алого ордена", "Монастырь Алого ордена"}
        s["quest;reward=7541"] = {"Служба Орде", "Оргриммар"}
        s["npc;drop=6489"] = {"Железноспин", "Монастырь Алого ордена"}
        s["quest;reward=78916"] = {"Сердце Бездны", "Дарнасс"}
        s["npc;drop=207356"] = {"Лоргус Джетт", "Непроглядная Пучина"}
        s["npc;drop=7584"] = {"Бродячий лесной древень", "Фералас"}
        s["npc;drop=14491"] = {"Курмокк", "Тернистая долина"}
        s["npc;drop=4389"] = {"Черный крепкозуб", "Пылевые топи"}
        s["npc;drop=2433"] = {"Прах Хелькулара", "Предгорья Хилсбрада"}
        s["spell;created=6705"] = {"Наручи из чешуи морлока", "CRAFTING"}
        s["spell;created=3779"] = {"Варварский пояс", "CRAFTING"}
        s["npc;drop=4845"] = {"Тенегорнский бузотер", "Бесплодные земли"}
        s["quest;reward=2767"] = {"Спасти ККX-22/FE!", "Фералас"}
        s["quest;reward=793"] = {"Разорванные союзы", "Бесплодные земли"}
        s["spell;created=435960"] = {"Сверхпроводимый золотой ремень", "CRAFTING"}
        s["npc;drop=16118"] = {"Кормок", "Некроситет"}
        s["npc;drop=9033"] = {"Генерал Кузня Гнева", "Глубины Черной горы"}
        s["npc;drop=12018"] = {"Мажордом Экзекутус", "Огненные Недра"}
        s["npc;drop=15509"] = {"Принцесса Хухуран", "Ан'Кираж"}
        s["quest;reward=7506"] = {"Изумрудный сон", "Забытый Город"}
        s["npc;drop=15299"] = {"Нечистотон", "Ан'Кираж"}
        s["npc;drop=14888"] = {"Летон", "Сумеречный лес"}
        s["npc;drop=15543"] = {"Принцесса Яудж", "Ан'Кираж"}
        s["spell;created=22927"] = {"Палантин Леса", "CRAFTING"}
        s["npc;drop=11501"] = {"Король Гордок", "Забытый Город"}
        s["npc;drop=10268"] = {"Гизрул Поработитель", "Вершина Черной горы"}
        s["spell;created=22759"] = {"Напульсники с сияющей сердцевиной", "CRAFTING"}
        s["npc;drop=15339"] = {"Оссириан Неуязвимый", "Руины Ан'Киража"}
        s["npc;drop=5712"] = {"Золо", "Храм Атал'Хаккара"}
        s["spell;created=23709"] = {"Пояс пса Недр", "CRAFTING"}
        s["npc;drop=13020"] = {"Валестраз Порочный", "Логово Крыла Тьмы"}
        s["npc;drop=11488"] = {"Иллиана Воронья Ольха", "Забытый Город"}
        s["npc;drop=9056"] = {"Точень Темнострой <Главный архитектор>", "Глубины Черной горы"}
        s["npc;drop=10504"] = {"Лорд Алексей Баров", "Некроситет"}
        s["npc;drop=14325"] = {"Капитан Давигром", "Забытый Город"}
        s["npc;drop=10809"] = {"Каменный Гребень", "Стратхольм"}
        s["quest;reward=8791"] = {"Повергнутый Оссириан", "Силитус"}
        s["npc;drop=10439"] = {"Рамштайн Ненасытный", "Стратхольм"}
        s["quest;reward=7907"] = {"Карты Новолуния: Звери", "Элвиннский лес"}
        s["object;contained=169243"] = {"Сундук Семерых", "Глубины Черной горы"}
        s["npc;drop=14515"] = {"Верховная жрица Арлокк", "Зул'Гуруб"}
        s["npc;drop=16080"] = {"Мор Серое Копыто", "Вершина Черной горы"}
        s["spell;created=461750"] = {"Раскаленный венец из луноткани", "CRAFTING"}
        s["spell;created=23665"] = {"Серебристые наплечники", "CRAFTING"}
        s["spell;created=446189"] = {"Наплечные пластины одержимости", "CRAFTING"}
        s["spell;created=19061"] = {"Наплечники Живых", "CRAFTING"}
        s["spell;created=446194"] = {"Оплечье безумия", "CRAFTING"}
        s["npc;drop=221394"] = {"Аватара Хаккара", "Храм Атал'Хаккара"}
        s["npc;drop=228431"] = {"Гееннас", "Огненные Недра"}
        s["npc;drop=9236"] = {"Темная охотница Вос'гаджин", "Вершина Черной горы"}
        s["spell;created=19435"] = {"Сапоги из луноткани", "CRAFTING"}
        s["npc;drop=218571"] = {"Тень Эраникуса", "Храм Атал'Хаккара"}
        s["npc;drop=10506"] = {"Киртонос Глашатай", "Некроситет"}
        s["quest;reward=80325"] = {"Безумный король", "Оргриммар"}
        s["quest;reward=82081"] = {"Прерванный ритуал", "Тернистая долина"}
        s["quest;reward=82058"] = {"Колода карт Новолуния: Дикая природа", "Элвиннский лес"}
        s["npc;drop=226922"] = {"Зилбагоб", "Каньон Гибели Демона"}
        s["npc;drop=9938"] = {"Магмус", "Глубины Черной горы"}
        s["npc;drop=3977"] = {"Верховный инквизитор Вайтмейн", "Монастырь Алого ордена"}
        s["npc;drop=14324"] = {"Чо'Раш Наблюдатель", "Забытый Город"}
        s["npc;drop=11661"] = {"Поджигатель", "Огненные Недра"}
        s["npc;drop=11673"] = {"Древняя гончая бездны", "Огненные Недра"}
        s["quest;reward=9008"] = {"Лучшее – напоследок", "Оргриммар"}
        s["quest;reward=4024"] = {"Вкус пламени", "Пылающие степи"}
        s["npc;drop=13276"] = {"Дикий бес из племени Исчадий Природы", "Забытый Город"}
        s["npc;drop=9027"] = {"Горош Дервиш", "Глубины Черной горы"}
        s["npc;drop=10264"] = {"Солакарский огнечервь", "Вершина Черной горы"}
        s["quest;reward=8906"] = {"Серьезное предложение", "Стальгорн"}
        s["quest;reward=8938"] = {"Справедливое вознаграждение", "Оргриммар"}
        s["npc;drop=10393"] = {"Череп", "Стратхольм"}
        s["npc;drop=11489"] = {"Тендрис Криводрев", "Забытый Город"}
        s["npc;drop=9596"] = {"Баннок Люторез <Герой легиона Огненного Клейма>", "Вершина Черной горы"}
        s["quest;reward=8952"] = {"Прощальные слова Антиона", "Вершина Черной горы"}
        s["spell;created=22922"] = {"Мангустовые сапоги", "CRAFTING"}
        s["quest;reward=5125"] = {"Слова Аурия", "Стратхольм"}
        s["quest;reward=7503"] = {"Величайшая гонка охотников", "Забытый Город"}
        s["quest;reward=82108"] = {"[The Green Drake]", "Храм Атал'Хаккара"}
        s["npc;drop=10438"] = {"Малекай Бледный", "Стратхольм"}
        s["npc;drop=221391"] = {"Слирена <Королева гарпий>", "Фералас"}
        s["npc;drop=15740"] = {"Колосс Зоры", "Силитус"}
        s["spell;created=462623"] = {"Образование Рок-Делара", "CRAFTING"}
        s["quest;reward=82104"] = {"Пророк Джаммал'ан", "Внутренние земли"}
        s["npc;drop=8908"] = {"Оплавленный боевой голем", "Глубины Черной горы"}
        s["quest;reward=84148"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["spell;created=446237"] = {"Усиленные Бездной тяжелые наручи убийцы", "CRAFTING"}
        s["npc;drop=9029"] = {"Потрошитель", "Глубины Черной горы"}
        s["quest;reward=7029"] = {"Порча Злоязыкого", "Пустоши"}
        s["object;contained=179564"] = {"Приношения клана Гордок", "Забытый Город"}
        s["npc;drop=9445"] = {"Темный стражник", "Глубины Черной горы"}
        s["spell;created=23639"] = {"Черное неистовство", "CRAFTING"}
        s["spell;created=461675"] = {"Отполированный арканитовый жнец", "CRAFTING"}
        s["npc;drop=222573"] = {"Безумная древняя богиня", "Зул'Фаррак"}
        s["quest;reward=8272"] = {"Герой Северного Волка", "Альтеракские горы"}
        s["quest;reward=3636"] = {"Нести свет", "Штормград"}
        s["quest;reward=1364"] = {"Задание Мазена", "Штормград"}
        s["npc;drop=7603"] = {"Прокаженный ассистент", "Гномреган"}
        s["npc;drop=2716"] = {"Охотник на драконов из клана Гнилобрюхов", "Бесплодные земли"}
        s["quest;reward=628"] = {"Эксельзиор", "Тернистая долина"}
        s["npc;drop=6910"] = {"Ревелош", "Ульдаман"}
        s["quest;reward=7068"] = {"Фрагменты осколка сумрака", "Оргриммар"}
        s["quest;reward=2822"] = {"Знак качества", "Фералас"}
        s["npc;drop=5860"] = {"Темный шаман из культа Сумеречного Молота", "Тлеющее ущелье"}
        s["npc;drop=13601"] = {"Ремонтник Гизлок", "Мародон"}
        s["quest;reward=1048"] = {"В монастырь Алого ордена", "Монастырь Алого ордена"}
        s["spell;created=435953"] = {"Антирадиационный капюшон из чешуи", "CRAFTING"}
        s["spell;created=18457"] = {"Одеяние верховного мага", "CRAFTING"}
        s["quest;reward=8632"] = {"Венец Таинства", "Ан'Кираж"}
        s["quest;reward=8625"] = {"Наплечные щитки Таинства", "Ан'Кираж"}
        s["quest;reward=8633"] = {"Одеяния Таинства", "Ан'Кираж"}
        s["quest;reward=8634"] = {"Сапоги Таинства", "Ан'Кираж"}
        s["npc;drop=15236"] = {"Векнисская оса", "Ан'Кираж"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "Стальгорн"}
        s["quest;reward=84157"] = {"[An Earnest Proposition]", "Оргриммар"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "Забытый Город"}
        s["npc;drop=11480"] = {"Волшебная аберрация", "Забытый Город"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", "Стратхольм"}
        s["npc;drop=10198"] = {"Кашох Разоритель", "Зимние Ключи"}
        s["quest;reward=84165"] = {"[Just Compensation]", "Стальгорн"}
        s["spell;created=22868"] = {"Инфернальные перчатки", "CRAFTING"}
        s["npc;drop=14684"] = {"Балзафон", "Стратхольм"}
        s["quest;reward=82095"] = {"[The God Hakkar]", "Танарис"}
        s["quest;reward=8932"] = {"Справедливое вознаграждение", "Стальгорн"}
        s["npc;drop=9024"] = {"Пироман Зерно Мудрости", "Глубины Черной горы"}
        s["quest;reward=617"] = {"Кипы акириса", "Тернистая долина"}
        s["npc;drop=6146"] = {"Скальный разрушитель", "Азшара"}
        s["spell;created=446236"] = {"Усиленные Бездной тяжелые наручи заклинателя", "CRAFTING"}
        s["quest;reward=3907"] = {"Дисгармония пламени", "Бесплодные земли"}
        s["spell;created=23663"] = {"Оплечье Древобрюхов", "CRAFTING"}
        s["npc;drop=4288"] = {"Зверолов из Алого ордена", "Монастырь Алого ордена"}
        s["npc;drop=6487"] = {"Чародей Доан", "Монастырь Алого ордена"}
        s["quest;reward=8366"] = {"Покажи этим пиратам", "Танарис"}
        s["npc;drop=14446"] = {"Узкий Плавник", "Болото Печали"}
        s["spell;created=16724"] = {"Шлем Чистой души", "CRAFTING"}
        s["npc;drop=10339"] = {"Гит <Верховое животное Ренда Чернорука>", "Вершина Черной горы"}
        s["spell;created=19054"] = {"Кираса из чешуи красного дракона", "CRAFTING"}
        s["npc;drop=14321"] = {"Стражник Фенгус", "Забытый Город"}
        s["npc;drop=14861"] = {"Кровавая прислужница Киртоноса", "Некроситет"}
        s["quest;reward=7501"] = {"Свет и как его раскачать", "Забытый Город"}
        s["spell;created=446191"] = {"Губительное наплечье", "CRAFTING"}
        s["spell;created=446190"] = {"Воющее плетеное оплечье", "CRAFTING"}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["npc;drop=10464"] = {"Завывающая банши", "Стратхольм"}
        s["npc;drop=12203"] = {"Сель", "Мародон"}
        s["spell;created=435906"] = {"Отражающая клеть разума из истинного серебра", "CRAFTING"}
        s["spell;created=435949"] = {"Светящийся сверхпроводимый капюшон из чешуи", "CRAFTING"}
        s["spell;created=435610"] = {"Нейрогномский монокль из чароволокна", "CRAFTING"}
        s["npc;drop=14686"] = {"Леди Фалтер'есс", "Курганы Иглошкурых"}
        s["npc;sold=222685"] = {"Интендант Кайлин", "Ясеневый лес"}
        s["spell;created=20874"] = {"Наручи из черного железа", "CRAFTING"}
        s["spell;created=24399"] = {"Сапоги из черного железа", "CRAFTING"}
        s["npc;sold=3144"] = {"Эйтригг", "Оргриммар"}
        s["quest;reward=80131"] = {"Гномье усовершенствование", "Стальгорн"}
        s["npc;drop=2691"] = {"Гонец высокодолья", "Внутренние земли"}
        s["npc;drop=10596"] = {"Мать Дымная Паутина", "Вершина Черной горы"}
        s["spell;created=461730"] = {"Закаленный ледяной страж", "CRAFTING"}
        s["spell;created=23652"] = {"Черный страж", "CRAFTING"}
        s["spell;created=461669"] = {"Отполированный арканитовый защитник", "CRAFTING"}
        s["spell;created=22797"] = {"Реактивный диск Силы", "CRAFTING"}
        s["npc;drop=3976"] = {"Командир Могрейн из Алого ордена", "Монастырь Алого ордена"}
        s["quest;reward=7065"] = {"Яблочко от яблоньки...", "Пустоши"}
        s["spell;created=9952"] = {"Изысканный мифриловый наплечник", "CRAFTING"}
        s["npc;drop=5287"] = {"Длиннозубый ревун", "Фералас"}
        s["npc;drop=1884"] = {"Дровосек из Алого ордена", "Западные Чумные земли"}
        s["npc;drop=14690"] = {"Реваншион", "Забытый Город"}
        s["npc;drop=10418"] = {"Кровавый охранник", "Стратхольм"}
        s["npc;drop=10808"] = {"Тайлер", "Стратхольм"}
        s["spell;created=16729"] = {"Шлем Львиного Сердца", "CRAFTING"}
        s["spell;created=435908"] = {"Закаленный антипомеховый шлем", "CRAFTING"}
        s["spell;created=24141"] = {"Наплечники темного духа", "CRAFTING"}
        s["npc;drop=7524"] = {"Тоскующая высокорожденная", "Зимние Ключи"}
        s["spell;created=19101"] = {"Вулканические наплечники", "CRAFTING"}
        s["spell;created=446179"] = {"Латные наплечники ужаса", "CRAFTING"}
        s["quest;reward=5166"] = {"Кираса Всецветных драконов", "Западные Чумные земли"}
        s["spell;created=19076"] = {"Вулканическая кираса", "CRAFTING"}
        s["spell;created=24139"] = {"Кираса темного духа", "CRAFTING"}
        s["spell;created=446238"] = {"Усиленные Бездной тяжелые наручи защитника", "CRAFTING"}
        s["spell;created=23633"] = {"Перчатки Рассвета", "CRAFTING"}
        s["spell;created=461671"] = {"Рукавицы мощной цитадели", "CRAFTING"}
        s["spell;created=23632"] = {"Ремень Рассвета", "CRAFTING"}
        s["quest;reward=5081"] = {"Миссия Максвелла", "Вершина Черной горы"}
        s["spell;created=19059"] = {"Вулканические поножи", "CRAFTING"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "Восточные Чумные земли"}
        s["spell;created=461718"] = {"Спокойствие", "CRAFTING"}
        s["spell;created=21160"] = {"Глаз Сульфураса", "CRAFTING"}
        s["npc;drop=9039"] = {"Рок'рел", "Глубины Черной горы"}
        s["npc;drop=9031"] = {"Ануб'шиа", "Глубины Черной горы"}
        s["spell;created=20873"] = {"Пламенные плетеные наплечники", "CRAFTING"}
        s["npc;drop=15305"] = {"Лорд Сквол", "Силитус"}
        s["spell;created=461651"] = {"Огненные латные рукавицы тайной техники", "CRAFTING"}
        s["spell;created=27585"] = {"Тяжелый обсидиановый пояс", "CRAFTING"}
        s["spell;created=27829"] = {"Титановые поножи", "CRAFTING"}
        s["spell;created=20876"] = {"Поножи из черного железа", "CRAFTING"}
        s["quest;reward=8572"] = {"Броня ветерана", "Силитус"}
        s["spell;created=12906"] = {"Боевой цыпленок гномов", "CRAFTING"}
        s["spell;created=460460"] = {"Сульфуронский молот", "CRAFTING"}
        s["spell;created=450409"] = {"Зов Суль'траза", "CRAFTING"}
        s["npc;drop=8127"] = {"Анту'сул <Надсмотрщик Сула>", "Зул'Фаррак"}
        s["spell;created=461714"] = {"Осквернение", "CRAFTING"}
        s["npc;drop=227019"] = {"Диатор Ищейка", "Каньон Гибели Демона"}
        s["spell;created=16994"] = {"Арканитовый жнец", "CRAFTING"}
        s["spell;created=23151"] = {"Баланс Света и Тьмы", "CRAFTING"}
        s["npc;drop=14517"] = {"Верховная жрица Джеклик", "Зул'Гуруб"}
        s["npc;drop=15816"] = {"Киражский майор Хи'али", "Тысяча Игл"}
        s["quest;reward=9009"] = {"Лучшее – напоследок", "Оргриммар"}
        s["npc;drop=11382"] = {"Мандокир Повелитель Крови", "Зул'Гуруб"}
        s["spell;created=18456"] = {"Одеяние Истинной веры", "CRAFTING"}
        s["npc;drop=11664"] = {"Поджигатель-гвардеец", "Огненные Недра"}
        s["quest;reward=8909"] = {"Серьезное предложение", "Стальгорн"}
        s["quest;reward=8940"] = {"Справедливое вознаграждение", "Оргриммар"}
        s["npc;drop=14509"] = {"Верховный жрец Текал", "Зул'Гуруб"}
        s["quest;reward=9019"] = {"Прощальные слова Антиона", "Вершина Черной горы"}
        s["npc;drop=14887"] = {"Исондра", "Сумеречный лес"}
        s["quest;reward=7504"] = {"Святая Болонья: О чем не говорит Свет", "Забытый Город"}
        s["quest;reward=82111"] = {"[Blood of Morphaz]", "Азшара"}
        s["npc;drop=12459"] = {"Чернокнижник Крыла Тьмы", "Логово Крыла Тьмы"}
        s["object;contained=161495"] = {"Потайной сейф", "Глубины Черной горы"}
        s["spell;created=463008"] = {"Баланс Света и Тьмы", "CRAFTING"}
        s["spell;created=461708"] = {"Раскаленное одеяние из луноткани", "CRAFTING"}
        s["quest;reward=84151"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["spell;created=461752"] = {"Раскаленные поножи из луноткани", "CRAFTING"}
        s["quest;reward=55"] = {"Морбент Скверн", "Сумеречный лес"}
        s["npc;drop=4366"] = {"Змеестраж из клана Страшаз", "Пылевые топи"}
        s["npc;drop=10423"] = {"Жрец из Багрового Легиона", "Стратхольм"}
        s["npc;drop=9818"] = {"Призыватель из легиона Чернорука <Легион Чернорука>", "Вершина Черной горы"}
        s["spell;created=446193"] = {"Наплечье треснувшего рассудка", "CRAFTING"}
        s["npc;drop=9219"] = {"Мясник из клана Черной Вершины", "Вершина Черной горы"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "Выжженные земли"}
        s["quest;reward=9225"] = {"Легендарное боевое снаряжение – Чтимый Рассветом", "Восточные Чумные земли"}
        s["npc;drop=10425"] = {"Боевой маг из Багрового Легиона", "Стратхольм"}
        s["npc;drop=10477"] = {"Некромант Некроситета", "Некроситет"}
        s["npc;drop=8923"] = {"Панцер Непобедимый", "Глубины Черной горы"}
        s["npc;drop=10502"] = {"Леди Иллюсия Баров", "Некроситет"}
        s["quest;reward=9221"] = {"Превосходное боевое снаряжениее – Друг Рассвета", "Восточные Чумные земли"}
        s["npc;drop=14327"] = {"Лефтендрис", "Забытый Город"}
        s["spell;created=18436"] = {"Одеяние Зимней ночи", "CRAFTING"}
        s["npc;drop=12457"] = {"Чароплет Крыла Тьмы", "Логово Крыла Тьмы"}
        s["quest;reward=8592"] = {"Тиара Оракула", "Ан'Кираж"}
        s["quest;reward=8594"] = {"Оплечье Оракула", "Ан'Кираж"}
        s["spell;created=18453"] = {"Наплечники из ткани Скверны", "CRAFTING"}
        s["quest;reward=8603"] = {"Одеяние Оракула", "Ан'Кираж"}
        s["npc;drop=15247"] = {"Киражский опустошитель разума", "Ан'Кираж"}
        s["spell;created=22867"] = {"Перчатки из ткани Скверны", "CRAFTING"}
        s["npc;drop=10432"] = {"Вектус", "Некроситет"}
        s["spell;created=23041"] = {"Вызов Анафемы", "CRAFTING"}
        s["npc;drop=14516"] = {"Рыцарь смерти Темный Терзатель", "Некроситет"}
        s["spell;created=461962"] = {"Вызов Анафемы", "CRAFTING"}
        s["npc;drop=1843"] = {"Штейгер Джеррис", "Западные Чумные земли"}
        s["npc;drop=12801"] = {"Волшебный химерон", "Фералас"}
        s["npc;drop=228914"] = {"Покалеченный хранитель", "Каньон Гибели Демона"}
        s["npc;drop=10119"] = {"Волхан", "Пылающие степи"}
        s["npc;drop=16154"] = {"Восставший рыцарь смерти", "Наксрамас"}
        s["npc;drop=11469"] = {"Огнечар Элдрета", "Забытый Город"}
        s["npc;drop=14506"] = {"Лорд Хел'нурат", "Забытый Город"}
        s["npc;drop=14473"] = {"Лапресс", "Силитус"}
        s["npc;drop=15975"] = {"Ткач-падальщик", "Наксрамас"}
        s["npc;drop=1838"] = {"Дознаватель из Алого ордена", "Западные Чумные земли"}
        s["npc;drop=1851"] = {"Кикиморд", "Западные Чумные земли"}
        s["npc;drop=7104"] = {"Дессекус", "Оскверненный лес"}
        s["npc;drop=15757"] = {"Киражский генерал-лейтенант", "Силитус"}
        s["npc;drop=15390"] = {"Капитан Ксуррем", "Руины Ан'Киража"}
        s["npc;drop=10371"] = {"Капитан Яростного Когтя", "Вершина Черной горы"}
        s["npc;drop=11896"] = {"Мерзкослиз", "Восточные Чумные земли"}
        s["npc;drop=7459"] = {"Матриарх ледополохов", "Зимние Ключи"}
        s["npc;drop=10663"] = {"Коготь Маны", "Зимние Ключи"}
        s["spell;created=18442"] = {"Сквернотканевый капюшон", "CRAFTING"}
        s["npc;drop=11143"] = {"Почтальон Мэлоун", "Стратхольм"}
        s["spell;created=19794"] = {"Экстремальные очки магической силы", "CRAFTING"}
        s["npc;drop=11622"] = {"Громоклин", "Некроситет"}
        s["object;contained=181074"] = {"Трофеи Арены", "Глубины Черной горы"}
        s["spell;created=18451"] = {"Одеяние из ткани Скверны", "CRAFTING"}
        s["npc;drop=9817"] = {"Страхопряд легиона Чернорука <Легион Чернорука>", "Вершина Черной горы"}
        s["npc;drop=10372"] = {"Огнедышащая драконида Яростного Когтя", "Вершина Черной горы"}
        s["npc;drop=11490"] = {"Зеврим Терновое Копыто", "Забытый Город"}
        s["npc;drop=10901"] = {"Сказитель Полкелт", "Некроситет"}
        s["npc;drop=11467"] = {"Цу'зи", "Забытый Город"}
        s["spell;created=18454"] = {"Перчатки Волшебства", "CRAFTING"}
        s["spell;created=18419"] = {"Штаны из ткани Скверны", "CRAFTING"}
        s["npc;drop=10436"] = {"Баронесса Анастари", "Стратхольм"}
        s["npc;drop=10558"] = {"Певчий Форрестен", "Стратхольм"}
        s["npc;drop=9217"] = {"Лорд-волхв из клана Черной Вершины", "Вершина Черной горы"}
        s["npc;drop=6228"] = {"Посол из клана Черного Железа", "Гномреган"}
        s["npc;drop=6370"] = {"Клешнекоп макринни", "Азшара"}
        s["quest;reward=9004"] = {"Сладкое – на закуску", "Стальгорн"}
        s["quest;reward=8956"] = {"Прощальные слова Антиона", "Стальгорн"}
        s["quest;reward=8910"] = {"Серьезное предложение", "Стальгорн"}
        s["quest;reward=8941"] = {"Справедливое вознаграждение", "Оргриммар"}
        s["quest;reward=8639"] = {"Шлем Смертеторговца", "Ан'Кираж"}
        s["quest;reward=8641"] = {"Наплеч Смертеторговца", "Ан'Кираж"}
        s["quest;reward=8638"] = {"Жилет Смертеторговца", "Ан'Кираж"}
        s["npc;drop=10505"] = {"Инструктор Коварница", "Некроситет"}
        s["quest;reward=8201"] = {"Коллекция голов", "Тернистая долина"}
        s["npc;drop=9265"] = {"Темный охотник из племени Тлеющего Терновника", "Вершина Черной горы"}
        s["quest;reward=8640"] = {"Поножи Смертеторговца", "Ан'Кираж"}
        s["quest;reward=8637"] = {"Сапоги Смертеторговца", "Ан'Кираж"}
        s["npc;drop=14507"] = {"Верховный жрец Веноксис", "Зул'Гуруб"}
        s["quest;reward=7498"] = {"Гарона: Исследование уловок и предательства", "Забытый Город"}
        s["quest;reward=7787"] = {"Громовая ярость", "Силитус"}
        s["npc;drop=203138"] = {"Надзиратель из клана Ярости Горна", "Глубины Черной горы"}
        s["spell;created=461237"] = {"Череп пламени Тьмы", "CRAFTING"}
        s["spell;created=19090"] = {"Наплечники Грозового Покрова", "CRAFTING"}
        s["spell;created=19079"] = {"Доспех Грозового Покрова", "CRAFTING"}
        s["quest;reward=84152"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["spell;created=26279"] = {"Перчатки Грозового Покрова", "CRAFTING"}
        s["npc;drop=10318"] = {"Убийца из легиона Чернорука <Легион Чернорука>", "Вершина Черной горы"}
        s["spell;created=19067"] = {"Штаны Грозового Покрова", "CRAFTING"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "Забытый Город"}
        s["npc;drop=15741"] = {"Колосс Регала", "Силитус"}
        s["npc;drop=14222"] = {"Арага", "Альтеракские горы"}
        s["quest;reward=53"] = {"Янтарное сладкое", "Западный Край"}
        s["npc;drop=2601"] = {"Гнилобрюх", "Нагорье Арати"}
        s["npc;drop=2751"] = {"Боевой голем", "Бесплодные земли"}
        s["spell;created=9201"] = {"Мглистые наручи", "CRAFTING"}
        s["quest;reward=80455"] = {"[Biding Our Time]", "Серебряный бор"}
        s["npc;drop=15209"] = {"Багровый храмовник <Совет Бездны>", "Силитус"}
        s["spell;created=23706"] = {"Золотое оплечье Рассвета", "CRAFTING"}
        s["spell;created=19068"] = {"Портупея боевого медведя", "CRAFTING"}
        s["npc;drop=9237"] = {"Воевода Вун", "Вершина Черной горы"}
        s["npc;drop=15817"] = {"Киражский бригадный генерал Пакслиш", "Силитус"}
        s["quest;reward=8623"] = {"Диадема Зовущего бурю", "Ан'Кираж"}
        s["quest;reward=9011"] = {"Лучшее – напоследок", "Оргриммар"}
        s["quest;reward=7668"] = {"Угроза Темного Губителя", "Оргриммар"}
        s["quest;reward=8602"] = {"Наплечье Зовущего бурю", "Ан'Кираж"}
        s["spell;created=16650"] = {"Доспех Дикого терна", "CRAFTING"}
        s["quest;reward=8622"] = {"Хауберк Зовущего бурю", "Ан'Кираж"}
        s["quest;reward=8918"] = {"Серьезное предложение", "Оргриммар"}
        s["npc;drop=14454"] = {"Ветробой", "Силитус"}
        s["quest;reward=8621"] = {"Прочные ботинки Зовущего бурю", "Ан'Кираж"}
        s["npc;drop=11462"] = {"Древень-криводрев", "Забытый Город"}
        s["quest;reward=7505"] = {"Ледяной шок и вы", "Забытый Город"}
        s["quest;reward=82113"] = {"[Da Voodoo]", "Альтеракские горы"}
        s["spell;created=461735"] = {"Непробиваемая кольчуга", "CRAFTING"}
        s["quest;reward=84160"] = {"Серьезное предложение", "Оргриммар"}
        s["npc;drop=11043"] = {"Монах из Багрового Легиона", "Стратхольм"}
        s["spell;created=461737"] = {"Рукавицы урагана", "CRAFTING"}
        s["npc;drop=10083"] = {"Огнечешуйчатая драконида Яростного Когтя", "Вершина Черной горы"}
        s["npc;drop=10814"] = {"Хроматический элитный страж", "Вершина Черной горы"}
        s["npc;drop=14323"] = {"Стражник Слип'кик", "Забытый Город"}
        s["spell;created=446186"] = {"Плетеные наплечные щитки какофонии", "CRAFTING"}
        s["spell;created=451706"] = {"Кричащее кольчужное наплечье", "CRAFTING"}
        s["npc;drop=9028"] = {"Гриззл", "Глубины Черной горы"}
        s["spell;created=24138"] = {"Рукавицы кровавого духа", "CRAFTING"}
        s["npc;drop=224257"] = {"Раб племени Атал'ай", "Храм Атал'Хаккара"}
        s["spell;created=435958"] = {"Вращающаяся панель из истинного серебра", "CRAFTING"}
        s["spell;created=19094"] = {"Наплечники из чешуи черного дракона", "CRAFTING"}
        s["spell;created=23708"] = {"Разноцветные рукавицы", "CRAFTING"}
        s["spell;created=19107"] = {"Поножи из чешуи черного дракона", "CRAFTING"}
        s["spell;created=20855"] = {"Сапоги из чешуи черного дракона", "CRAFTING"}
        s["spell;created=23653"] = {"Сумерки", "CRAFTING"}
        s["npc;drop=6117"] = {"Призрак высокорожденного", "Азшара"}
        s["spell;created=19085"] = {"Кираса из чешуи черного дракона", "CRAFTING"}
        s["npc;drop=10507"] = {"Равениан", "Некроситет"}
        s["spell;created=16991"] = {"Аннигилятор", "CRAFTING"}
        s["npc;drop=12258"] = {"Бритвохлест", "Мародон"}
        s["npc;drop=7358"] = {"Амненнар Хладовей", "Курганы Иглошкурых"}
        s["quest;reward=79366"] = {"Затишье перед бурей", "Тысяча Игл"}
        s["npc;drop=13596"] = {"Гнилопасть", "Мародон"}
        s["quest;reward=8624"] = {"Поножи Зовущего Бурю", "Ан'Кираж"}
        s["quest;reward=7488"] = {"Сеть Лефтендрис", "Фералас"}
        s["quest;reward=5526"] = {"Осколки сквернита", "Лунная поляна"}
        s["spell;created=8770"] = {"Одеяние Могущества", "CRAFTING"}
        s["npc;drop=7357"] = {"Мордреш Огненный Глаз", "Курганы Иглошкурых"}
        s["spell;created=24356"] = {"Очки Кровавой Лозы", "CRAFTING"}
        s["quest;reward=8662"] = {"Венец Призывателя рока", "Ан'Кираж"}
        s["quest;reward=9005"] = {"Сладкое – на закуску", "Стальгорн"}
        s["quest;reward=8664"] = {"Оплечье Призывателя Рока", "Ан'Кираж"}
        s["quest;reward=8661"] = {"Одеяния Призывателя рока", "Ан'Кираж"}
        s["spell;created=18458"] = {"Одеяние Бездны", "CRAFTING"}
        s["quest;reward=8936"] = {"Справедливое вознаграждение", "Стальгорн"}
        s["quest;reward=8381"] = {"Оружие войны", "Силитус"}
        s["spell;created=24201"] = {"Создание руны Рассвета", "CRAFTING"}
        s["quest;reward=7502"] = {"Укрощая тени", "Забытый Город"}
        s["spell;created=461747"] = {"Раскаленный жилет из луноткани", "CRAFTING"}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", "Стальгорн"}
        s["spell;created=23662"] = {"Мудрость Древобрюхов", "CRAFTING"}
        s["spell;created=462282"] = {"Расшитый пояс верховного мага", "CRAFTING"}
        s["npc;drop=15220"] = {"Герцог Ветров", "Силитус"}
        s["spell;created=429351"] = {"Экстрапланарные сапоги из паучьего шелка", "CRAFTING"}
        s["npc;drop=15203"] = {"Принц Скальдренокс <Верховный совет Бездны>", "Силитус"}
        s["spell;created=19830"] = {"Арканитовый дракончик", "CRAFTING"}
        s["spell;created=461743"] = {"Клинок архимага", "CRAFTING"}
        s["spell;created=20848"] = {"Оплечье с сияющей сердцевиной", "CRAFTING"}
        s["npc;drop=10376"] = {"Хрустальный Клык", "Вершина Черной горы"}
        s["npc;drop=16058"] = {"Волида", "Глубины Черной горы"}
        s["spell;created=446195"] = {"Наплечные пластины помешательства", "CRAFTING"}
        s["spell;created=22870"] = {"Плащ Стражи", "CRAFTING"}
        s["npc;drop=9439"] = {"Темный хранитель Уггель", "Глубины Черной горы"}
        s["spell;created=19093"] = {"Плащ из чешуи Ониксии", "CRAFTING"}
        s["spell;created=20849"] = {"Перчатки с сияющей сердцевиной", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "Оргриммар"}
        s["quest;reward=5942"] = {"Спрятанные сокровища", "Восточные Чумные земли"}
        s["npc;drop=5722"] = {"Хаззас", "Храм Атал'Хаккара"}
        s["quest;reward=1560"] = {"Задание Тооги", "Танарис"}
        s["npc;drop=15208"] = {"Герцог Осколков", "Силитус"}
        s["spell;created=23666"] = {"Одеяние с сияющей сердцевиной", "CRAFTING"}
        s["quest;reward=80141"] = {"[Nogg's Ring Redo]", "Оргриммар"}
        s["quest;reward=82107"] = {"Вудуистские перья", "Болото Печали"}
        s["npc;drop=8762"] = {"Древесный отшельник", "Азшара"}
        s["quest;reward=3129"] = {"Оружие духа", "Фералас"}
        s["quest;reward=84162"] = {"Серьезное предложение", "Оргриммар"}
        s["quest;reward=9006"] = {"Сладкое – на закуску", "Стальгорн"}
        s["npc;drop=14889"] = {"Эмерисс", "Сумеречный лес"}
        s["quest;reward=8561"] = {"Корона Завоевателя", "Ан'Кираж"}
        s["quest;reward=8544"] = {"Наплеч Завоевателя", "Ан'Кираж"}
        s["quest;reward=8562"] = {"Кираса Завоевателя", "Ан'Кираж"}
        s["quest;reward=8937"] = {"Справедливое вознаграждение", "Стальгорн"}
        s["quest;reward=8560"] = {"Набедренники Завоевателя", "Ан'Кираж"}
        s["quest;reward=8559"] = {"Наголенники Завоевателя", "Ан'Кираж"}
        s["quest;reward=9022"] = {"Прощальные слова Антиона", "Некроситет"}
        s["quest;reward=8789"] = {"Киражское императорское оружие", "Ан'Кираж"}
        s["spell;created=9954"] = {"Рукавицы из истинного серебра", "CRAFTING"}
        s["quest;reward=3566"] = {"Восстань, Обсидион!", "Тлеющее ущелье"}
        s["quest;reward=84550"] = {"[Codex of Defense]", "Забытый Город"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "Логово Крыла Тьмы"}
        s["spell;created=452433"] = {"Призыв Глет'чера", "CRAFTING"}
        s["npc;drop=231494"] = {"[Prince Thunderaan] <[The Wind Seeker]>", "Долина Кристаллов"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "Штормград"}
        s["spell;created=452434"] = {"Призыв Рае'лара", "CRAFTING"}
        s["npc;drop=14510"] = {"Верховная жрица Мар'ли", "Зул'Гуруб"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "Каньон Гибели Демона"}
        s["spell;created=461710"] = {"Ружье стрелка с пламенным сердечником", "CRAFTING"}
        s["spell;created=466117"] = {"Настройка посоха инея", "CRAFTING"}
        s["spell;created=465417"] = {"Смена стойки", "CRAFTING"}
        s["spell;created=465418"] = {"Смена стойки", "CRAFTING"}
        s["npc;drop=227939"] = {"[The Molten Core]", "Огненные Недра"}
        s["npc;drop=15085"] = {"Вушулай", "Зул'Гуруб"}
        s["npc;drop=15083"] = {"Хазза'рах", "Зул'Гуруб"}
        s["spell;created=469201"] = {"Разжигание пламени", "CRAFTING"}
        s["spell;created=468840"] = {"Объединение косы Хаоса", "CRAFTING"}
        s["npc;drop=15084"] = {"Ренатаки", "Зул'Гуруб"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "Логово Крыла Тьмы"}
        s["spell;created=467790"] = {"Объединение посоха порядка", "CRAFTING"}
        s["npc;drop=16011"] = {"Мерзот", "Наксрамас"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "Альтеракские горы"}
        s["npc;drop=10184"] = {"Ониксия", "Огненные Недра"}
        s["quest;reward=85454"] = {"[A Just Reward]", "Болотина"}
        s["npc;drop=15369"] = {"Аямисса Охотница", "Руины Ан'Киража"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "Силитус"}
        s["spell;created=1216020"] = {"Идол сидерического гнева", "CRAFTING"}
        s["spell;created=1213538"] = {"Плащ из киражского шелка", "CRAFTING"}
        s["npc;drop=15370"] = {"Буру Ненасытный", "Руины Ан'Киража"}
        s["npc;drop=235197"] = {"[Taerar]", "Ясеневый лес"}
        s["npc;sold=15192"] = {"Анахронос", "Танарис"}
        s["spell;created=1213595"] = {"Слеза Дремлющей", "CRAFTING"}
        s["spell;created=1213502"] = {"Обсидиановый буремолот", "CRAFTING"}
        s["npc;sold=15500"] = {"Кейл Стремительный Коготь", "Силитус"}
        s["spell;created=1216340"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1216022"] = {"Идол кошачьей свирепости", "CRAFTING"}
        s["npc;drop=228230"] = {"Харриген <Черный рынок>", "Пылающие степи"}
        s["spell;created=1213536"] = {"Накидка из киражского шелка", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "Силитус"}
        s["spell;created=23704"] = {"Боевые перчатки Древобрюхов", "CRAFTING"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "Силитус"}
        s["spell;created=1213593"] = {"Быстрокамень", "CRAFTING"}
        s["spell;created=1216385"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213500"] = {"Обсидиановый разрушитель", "CRAFTING"}
        s["spell;created=1216024"] = {"Идол медвежьей силы", "CRAFTING"}
        s["spell;created=24121"] = {"Изначальный жакет из кожи летучей мыши", "CRAFTING"}
        s["spell;created=1213738"] = {"Ежевичный шлем", "CRAFTING"}
        s["spell;created=1213736"] = {"Ежевичные сапоги", "CRAFTING"}
        s["spell;created=1213598"] = {"Магнит воздаяния", "CRAFTING"}
        s["spell;created=1216366"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213521"] = {"Клобук бритвенного терна", "CRAFTING"}
        s["spell;created=1213525"] = {"Кожаная броня бритвенного терна", "CRAFTING"}
        s["spell;created=1213523"] = {"Наплечные пластины бритвенного терна", "CRAFTING"}
        s["npc;drop=15348"] = {"Куриннакс", "Руины Ан'Киража"}
        s["npc;drop=15544"] = {"Вем", "Ан'Кираж"}
        s["spell;created=1213603"] = {"Украшенная рубинами брошь", "CRAFTING"}
        s["spell;created=1216319"] = {"Метка Бездны", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "Силитус"}
        s["spell;created=1213635"] = {"Зачарованный гриб", "CRAFTING"}
        s["spell;created=1213540"] = {"Пелерина из киражского шелка", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "Внутренние земли"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "Силитус"}
        s["quest;reward=86674"] = {"[The Perfect Poison]", "Силитус"}
        s["spell;created=1216365"] = {"Метка Бездны", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "Кратер Ун'Горо"}
        s["spell;created=24137"] = {"Наплечники кровавого духа", "CRAFTING"}
        s["spell;created=1216384"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1216387"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1216327"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=466116"] = {"Настройка посоха адского пламени", "CRAFTING"}
        s["spell;created=1213628"] = {"Зачарованный молитвенник", "CRAFTING"}
        s["quest;reward=86672"] = {"[Imperial Qiraji Armaments]", "Логово Крыла Тьмы"}
        s["spell;created=1216005"] = {"Манускрипт праведности", "CRAFTING"}
        s["spell;created=1213481"] = {"Наголовник бритвенных шипов", "CRAFTING"}
        s["spell;created=1213484"] = {"Латные наплечники бритвенных шипов", "CRAFTING"}
        s["spell;created=1214884"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213588"] = {"Настроенный реактивный диск", "CRAFTING"}
        s["spell;created=1214270"] = {"Звездчатый обсидиановый щит", "CRAFTING"}
        s["spell;created=1213490"] = {"Боевой доспех бритвенных шипов", "CRAFTING"}
        s["spell;created=1213506"] = {"Обсидиановый страж", "CRAFTING"}
        s["spell;created=1216379"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1216007"] = {"Манускрипт экзорциста", "CRAFTING"}
        s["spell;created=1216382"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213534"] = {"Платок из киражского шелка", "CRAFTING"}
        s["spell;created=1216375"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213492"] = {"Обсидиановый разоритель", "CRAFTING"}
        s["spell;created=1216377"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213498"] = {"Обсидиановый защитник", "CRAFTING"}
        s["quest;reward=86671"] = {"[Imperial Qiraji Regalia]", "Логово Крыла Тьмы"}
        s["npc;drop=234880"] = {"[Emeriss]", "Сумеречный лес"}
        s["spell;created=1216354"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1216014"] = {"Тотем вулканического грома", "CRAFTING"}
        s["spell;created=1213742"] = {"Лесная корона", "CRAFTING"}
        s["spell;created=1213740"] = {"Лесные наплечники", "CRAFTING"}
        s["spell;created=28210"] = {"Облачение Геи", "CRAFTING"}
        s["spell;created=1213744"] = {"Лесной жилет", "CRAFTING"}
        s["spell;created=1214306"] = {"Наручи чешуи сна", "CRAFTING"}
        s["spell;created=1214307"] = {"Полуперчатки чешуи сна", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "Фералас"}
        s["quest;reward=9248"] = {"Скромный подарок", "Силитус"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "Логово Крыла Тьмы"}
        s["spell;created=1213532"] = {"Вампирское одеяние", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "Логово Крыла Тьмы"}
        s["spell;created=1216372"] = {"Метка Бездны", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "Силитус"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "Ан'Кираж"}
        s["quest;reward=86760"] = {"Карты Новолуния: Звери", "Элвиннский лес"}
        s["quest;reward=86762"] = {"Карты Новолуния: Элементали", "Элвиннский лес"}
        s["quest;reward=86680"] = {"[Waking Legends]", "Лунная поляна"}
        s["spell;created=1214303"] = {"Килт чешуи сна", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "Зимние Ключи"}
        s["npc;drop=3975"] = {"Герод <Герой Алого ордена>", "Монастырь Алого ордена"}
        s["spell;created=1216364"] = {"Метка Бездны", "CRAFTING"}
        s["spell;created=1213633"] = {"Зачарованный тотем", "CRAFTING"}
        s["spell;created=1216381"] = {"Метка Бездны", "CRAFTING"}
        s["npc;sold=16135"] = {"Райн <Круг Кенария>", "Восточные Чумные земли"}
        s["npc;drop=16061"] = {"Инструктор Разувиус", "Наксрамас"}
        s["quest;reward=87360"] = {"[The Fall of Kel'Thuzad]", "Восточные Чумные земли"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "Склепы Каражана"}
        s["npc;drop=16143"] = {"Тень Рока", "Выжженные земли"}
        s["npc;drop=16380"] = {"Костяной ведьмак", "Пылающие степи"}
        s["quest;reward=87438"] = {"[Argent Dawn Leather Gloves]", "Восточные Чумные земли"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "Склепы Каражана"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "Восточные Чумные земли"}
        s["npc;drop=16060"] = {"Готик Жнец", "Наксрамас"}
        s["npc;drop=15936"] = {"Хейган Нечестивый", "Наксрамас"}
        s["npc;drop=15931"] = {"Гроббулус", "Наксрамас"}
        s["npc;drop=15932"] = {"Глут", "Наксрамас"}
        s["npc;drop=15989"] = {"Сапфирон", "Наксрамас"}
        s["npc;drop=14697"] = {"Неуклюжий ужас", "Пылающие степи"}
        s["npc;drop=237439"] = {"[Kharon]", "Склепы Каражана"}
        s["quest;reward=87440"] = {"[Argent Dawn Cloth Gloves]", "Восточные Чумные земли"}
        s["npc;drop=15928"] = {"Таддиус", "Наксрамас"}
        s["npc;drop=15953"] = {"Великая вдова Фарлина", "Наксрамас"}
        s["npc;drop=15956"] = {"Ануб'Рекан", "Наксрамас"}
        s["npc;drop=15954"] = {"Нот Чумной", "Наксрамас"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "Склепы Каражана"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "Склепы Каражана"}
        s["spell;created=1223762"] = {"Ледовый плащ", "CRAFTING"}
        s["npc;drop=16028"] = {"Лоскутик", "Наксрамас"}
        s["npc;drop=238055"] = {"[Dark Rider]", "Склепы Каражана"}
        s["npc;drop=238560"] = {"[The Warden]", "Склепы Каражана"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "Склепы Каражана"}
        s["spell;created=24179"] = {"Создание печати Рассвета", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "Склепы Каражана"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "Восточные Чумные земли"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "Склепы Каражана"}
        s["npc;drop=16379"] = {"Дух проклятого", "Пылающие степи"}
        s["npc;sold=16132"] = {"Охотник Леопольд <Алый орден>", "Восточные Чумные земли"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "Восточные Чумные земли"}
        s["npc;sold=16116"] = {"Верховный маг Анджела Досантос <Братство Света>", "Восточные Чумные земли"}
        s["npc;sold=16115"] = {"Командир Элигор Утросвет <Братство Света>", "Восточные Чумные земли"}
        s["quest;reward=87434"] = {"[Argent Dawn Plate Gloves]", "Восточные Чумные земли"}
        s["spell;created=1223787"] = {"Кираса Ледяной погибели", "CRAFTING"}
        s["spell;created=1223791"] = {"Наручи Ледяной погибели", "CRAFTING"}
        s["spell;created=1223789"] = {"Рукавицы Ледяной погибели", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "Восточные Чумные земли"}
        s["spell;created=1223780"] = {"Снежный мундир", "CRAFTING"}
        s["spell;created=1223784"] = {"Снежные наручи", "CRAFTING"}
        s["spell;created=1223782"] = {"Снежные перчатки", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "Танарис"}
        s["npc;sold=16113"] = {"Отец Иниго Монтой <Братство Света>", "Восточные Чумные земли"}
        s["spell;created=1223760"] = {"Ледовый жилет", "CRAFTING"}
        s["spell;created=1223764"] = {"Ледовые перчатки", "CRAFTING"}
        s["npc;sold=16131"] = {"Роган Убийца <Алый орден>", "Восточные Чумные земли"}
        s["spell;created=1214137"] = {"Обсидиановый искатель сердец", "CRAFTING"}
        s["npc;sold=16134"] = {"Римблат Землекрушитель <Служители Земли>", "Восточные Чумные земли"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "Склепы Каражана"}
        s["spell;created=1223766"] = {"Ледовые накулачники", "CRAFTING"}
        s["spell;created=1223772"] = {"Морозные накулачники", "CRAFTING"}
        s["npc;sold=16133"] = {"Матеус Заклинатель Гнева <Алый орден>", "Восточные Чумные земли"}
        s["spell;created=1213504"] = {"Обсидиановый клинок мудреца", "CRAFTING"}
        s["spell;created=1213527"] = {"Вампирский клобук", "CRAFTING"}
        s["spell;created=1213530"] = {"Вампирский платок", "CRAFTING"}
        s["npc;sold=16112"] = {"Корфакс, Воитель Света <Братство Света>", "Восточные Чумные земли"}
        s["spell;created=1214145"] = {"Обсидиановый дробовик", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "Восточные Чумные земли"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "Танарис"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "Стратхольм"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "Стратхольм"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "Танарис"}
    end

    function SpecBisTooltip:TranslationzhCN()
        s["npc;drop=11583"] = {"奈法利安", "黑翼之巢"}
        s["npc;drop=11502"] = {"拉格纳罗斯", "熔火之心"}
        s["npc;drop=12435"] = {"狂野的拉佐格尔", "黑翼之巢"}
        s["npc;drop=14834"] = {"哈卡", "祖尔格拉布"}
        s["spell;created=24091"] = {"血藤外套", "CRAFTING"}
        s["npc;drop=12017"] = {"勒什雷尔", "黑翼之巢"}
        s["npc;drop=11380"] = {"妖术师金度", "祖尔格拉布"}
        s["npc;drop=11983"] = {"费尔默", "黑翼之巢"}
        s["spell;created=24092"] = {"血藤护腿", "CRAFTING"}
        s["spell;created=24093"] = {"血藤长靴", "CRAFTING"}
        s["npc;drop=12098"] = {"萨弗隆先驱者", "熔火之心"}
        s["npc;drop=14601"] = {"埃博诺克", "黑翼之巢"}
        s["quest;reward=8183"] = {"哈卡之心", "荆棘谷"}
        s["npc;sold=13217"] = {"塔萨迪斯·雪光 <雷矛军需官>", "奥特兰克山脉"}
        s["npc;drop=10363"] = {"达基萨斯将军", "黑石塔"}
        s["npc;drop=10435"] = {"巴瑟拉斯镇长", "斯坦索姆"}
        s["spell;created=12622"] = {"绿色透镜", "CRAFTING"}
        s["spell;created=12092"] = {"梦纹头饰", "CRAFTING"}
        s["npc;drop=11261"] = {"瑟尔林·卡斯迪诺夫教授 <屠夫>", "通灵学院"}
        s["npc;sold=12777"] = {"戴格哈默中尉", "奥特兰克山谷"}
        s["npc;sold=12792"] = {"帕兰蒂尔", "奥特兰克山谷"}
        s["npc;drop=9018"] = {"审讯官格斯塔恩 <暮光之锤审问者>", "黑石深渊"}
        s["npc;drop=14353"] = {"米兹勒", "厄运之槌"}
        s["npc;drop=10811"] = {"档案管理员加尔福特", "斯坦索姆"}
        s["npc;drop=15727"] = {"克苏恩", "安其拉"}
        s["npc;drop=9319"] = {"驯犬者格雷布玛尔", "黑石深渊"}
        s["npc;drop=11487"] = {"卡雷迪斯镇长", "厄运之槌"}
        s["npc;sold=13218"] = {"格伦达·狼心 <霜狼军需官>", "奥特兰克山谷"}
        s["quest;reward=7861"] = {"通缉：邪恶祭司海克斯和她的爪牙", "辛特兰"}
        s["npc;drop=12118"] = {"鲁西弗隆", "熔火之心"}
        s["npc;drop=11496"] = {"伊莫塔尔", "厄运之槌"}
        s["npc;drop=11486"] = {"托塞德林王子", "厄运之槌"}
        s["npc;drop=15815"] = {"其拉上尉卡尔克", "千针石林"}
        s["npc;drop=10508"] = {"莱斯·霜语", "通灵学院"}
        s["npc;sold=14753"] = {"艾蒂尔·月火 <银翼军需官>", "灰谷"}
        s["quest;reward=8574"] = {"忠诚者的装备", "希利苏斯"}
        s["npc;drop=9017"] = {"伊森迪奥斯", "黑石深渊"}
        s["npc;drop=10516"] = {"不可宽恕者", "斯坦索姆"}
        s["npc;drop=14326"] = {"卫兵摩尔达", "厄运之槌"}
        s["npc;drop=11662"] = {"烈焰行者祭司", "熔火之心"}
        s["npc;drop=12397"] = {"卡扎克", "诅咒之地"}
        s["npc;drop=10584"] = {"乌洛克", "黑石塔"}
        s["npc;drop=14020"] = {"克洛玛古斯", "黑翼之巢"}
        s["npc;drop=9736"] = {"军需官兹格雷斯 <血斧军团>", "黑石塔"}
        s["quest;reward=8464"] = {"冬泉熊怪的活动", "冬泉谷"}
        s["npc;drop=5719"] = {"摩弗拉斯", "阿塔哈卡神庙"}
        s["spell;created=12067"] = {"梦纹手套", "CRAFTING"}
        s["npc;drop=12056"] = {"迦顿男爵", "熔火之心"}
        s["npc;drop=9030"] = {"破坏者奥科索尔", "黑石深渊"}
        s["npc;sold=13219"] = {"耶克里·弗兰迪 <霜狼军需官>", "奥特兰克山脉"}
        s["spell;created=3864"] = {"星辰腰带", "CRAFTING"}
        s["npc;drop=10437"] = {"奈鲁布恩坎", "斯坦索姆"}
        s["npc;drop=12119"] = {"烈焰行者护卫", "熔火之心"}
        s["npc;drop=9196"] = {"欧莫克大王", "黑石塔"}
        s["npc;drop=6109"] = {"艾索雷葛斯", "艾萨拉"}
        s["spell;created=23667"] = {"光芒护腿", "CRAFTING"}
        s["npc;drop=7267"] = {"乌克兹·沙顶", "祖尔法拉克"}
        s["npc;drop=8983"] = {"傀儡统帅阿格曼奇", "黑石深渊"}
        s["npc;drop=15276"] = {"维克洛尔大帝", "安其拉"}
        s["npc;drop=13280"] = {"海多斯博恩", "厄运之槌"}
        s["npc;drop=10429"] = {"大酋长雷德·黑手", "黑石塔"}
        s["npc;drop=10997"] = {"炮手威利", "斯坦索姆"}
        s["npc;drop=10812"] = {"大十字军战士达索汉", "斯坦索姆"}
        s["npc;drop=15275"] = {"维克尼拉斯大帝", "安其拉"}
        s["npc;drop=15742"] = {"亚什巨甲虫", "希利苏斯"}
        s["npc;drop=16042"] = {"瓦塔拉克公爵", "黑石塔"}
        s["quest;reward=8802"] = {"卡利姆多的救世主", "安其拉"}
        s["quest;reward=4363"] = {"语出惊人的公主", "黑石深渊"}
        s["quest;reward=4004"] = {"拯救公主？", "黑石深渊"}
        s["quest;reward=7491"] = {"万众敬仰", "奥格瑞玛"}
        s["npc;sold=14754"] = {"凯尔姆·哈古斯", "贫瘠之地"}
        s["npc;drop=11982"] = {"玛格曼达", "熔火之心"}
        s["npc;drop=10509"] = {"杰德 <黑手军团>", "黑石塔"}
        s["quest;reward=5102"] = {"达基萨斯将军之死", "燃烧平原"}
        s["npc;drop=9156"] = {"弗莱拉斯大使", "黑石深渊"}
        s["npc;sold=12782"] = {"奥尼尔上尉", "奥特兰克山谷"}
        s["npc;sold=14581"] = {"军士霍斯·雷角", "奥特兰克山谷"}
        s["npc;sold=15126"] = {"卢瑟弗·图恩 <污染者军需官>", "阿拉希高地"}
        s["npc;sold=15127"] = {"萨缪尔·霍克 <阿拉索军需官>", "阿拉希高地"}
        s["npc;drop=12057"] = {"加尔", "熔火之心"}
        s["npc;drop=12259"] = {"基赫纳斯", "熔火之心"}
        s["npc;drop=1853"] = {"黑暗院长加丁", "通灵学院"}
        s["npc;drop=10899"] = {"古拉鲁克 <黑手军团铸甲师>", "黑石塔"}
        s["npc;drop=11492"] = {"奥兹恩", "厄运之槌"}
        s["quest;reward=8790"] = {"其拉帝王徽记", "安其拉"}
        s["npc;drop=11988"] = {"焚化者古雷曼格", "熔火之心"}
        s["npc;drop=2585"] = {"激流堡仲裁者", "阿拉希高地"}
        s["quest;reward=82112"] = {"[A Better Ingredient]", "安戈洛环形山"}
        s["npc;drop=7271"] = {"巫医祖穆拉恩", "祖尔法拉克"}
        s["npc;drop=8440"] = {"哈卡的阴影", "阿塔哈卡神庙"}
        s["npc;drop=5721"] = {"德姆塞卡尔", "阿塔哈卡神庙"}
        s["object;contained=181083"] = {"[Sothos and Jarien's Heirlooms]", "斯坦索姆"}
        s["quest;reward=7784"] = {"黑石之王", "奥格瑞玛"}
        s["quest;reward=3962"] = {"结伴而行", "安戈洛环形山"}
        s["npc;drop=4543"] = {"血法师萨尔诺斯", "血色修道院"}
        s["npc;sold=227819"] = {"海达克西斯公爵", "熔火之心"}
        s["npc;drop=228435"] = {"焚化者古雷曼格", "熔火之心"}
        s["npc;sold=230319"] = {"德莉亚娜", "铁炉堡"}
        s["npc;drop=228438"] = {"[Ragnaros]", "熔火之心"}
        s["npc;drop=228432"] = {"加尔", "熔火之心"}
        s["npc;sold=227853"] = {"皮克希·希基克斯 <安德麦商人>", "荆棘谷"}
        s["spell;created=446192"] = {"黑暗神经症之膜", "CRAFTING"}
        s["npc;drop=15205"] = {"卡苏姆男爵", "希利苏斯"}
        s["spell;created=461653"] = {"闪亮的多彩披风", "CRAFTING"}
        s["npc;drop=228434"] = {"沙斯拉尔", "熔火之心"}
        s["npc;sold=222413"] = {"探险家扎尔戈 <无主货物供应商>", "荆棘谷"}
        s["quest;reward=84147"] = {"热心的建议", "铁炉堡"}
        s["npc;drop=218819"] = {"腐溃烂泥", "阿塔哈卡神庙"}
        s["spell;created=429869"] = {"虚触皮质护手", "CRAFTING"}
        s["npc;drop=220833"] = {"德姆塞卡尔", "阿塔哈卡神庙"}
        s["npc;sold=222408"] = {"影齿大使", "费伍德森林"}
        s["spell;created=461754"] = {"奥法洞察束带", "CRAFTING"}
        s["npc;drop=228433"] = {"迦顿男爵", "熔火之心"}
        s["object;contained=179703"] = {"火焰之王的宝箱", "熔火之心"}
        s["npc;drop=228429"] = {"鲁西弗隆", "熔火之心"}
        s["npc;drop=14890"] = {"泰拉尔", "暮色森林"}
        s["npc;drop=226923"] = {"晦根 <哀念守护者>", "屠魔峡谷"}
        s["npc;drop=12201"] = {"瑟莱德丝公主", "玛拉顿"}
        s["npc;drop=217280"] = {"格鲁比斯", "诺莫瑞根"}
        s["spell;created=461647"] = {"驭天者的精工风暴战锤", "CRAFTING"}
        s["npc;drop=4542"] = {"大检察官法尔班克斯", "血色修道院"}
        s["npc;drop=204068"] = {"萨利维丝", "黑暗深渊"}
        s["spell;created=12060"] = {"红色魔纹短裤", "CRAFTING"}
        s["npc;drop=213334"] = {"阿库麦尔", "黑暗深渊"}
        s["spell;created=439105"] = {"巫毒面具", "CRAFTING"}
        s["npc;drop=6490"] = {"永醒的艾希尔", "血色修道院"}
        s["spell;created=439093"] = {"深红丝质护肩", "CRAFTING"}
        s["quest;reward=82055"] = {"暗月沙丘套牌", "艾尔文森林"}
        s["quest;reward=82057"] = {"暗月瘟疫套牌", "艾尔文森林"}
        s["npc;drop=221637"] = {"加什尔", "阿塔哈卡神庙"}
        s["quest;reward=7940"] = {"1200张奖券 - 暗月宝珠", "莫高雷"}
        s["npc;drop=218721"] = {"预言者迦玛兰", "阿塔哈卡神庙"}
        s["npc;sold=11557"] = {"梅罗什", "费伍德森林"}
        s["spell;created=10621"] = {"狼头之盔", "CRAFTING"}
        s["npc;drop=9816"] = {"烈焰卫士艾博希尔", "黑石塔"}
        s["npc;drop=12467"] = {"死爪龙人队长", "黑翼之巢"}
        s["spell;created=23710"] = {"熔火腰带", "CRAFTING"}
        s["npc;drop=11981"] = {"弗莱格尔", "黑翼之巢"}
        s["npc;drop=6229"] = {"群体打击者9-60", "诺莫瑞根"}
        s["npc;drop=15206"] = {"灰烬公爵 <深渊议会>", "希利苏斯"}
        s["npc;drop=9041"] = {"典狱官斯迪尔基斯", "黑石深渊"}
        s["quest;reward=4261"] = {"远古之灵", "费伍德森林"}
        s["npc;drop=10440"] = {"瑞文戴尔男爵", "斯坦索姆"}
        s["npc;drop=15511"] = {"克里勋爵", "安其拉"}
        s["quest;reward=5068"] = {"嗜血胸甲", "冬泉谷"}
        s["npc;drop=9019"] = {"达格兰·索瑞森大帝", "黑石深渊"}
        s["npc;drop=15516"] = {"沙尔图拉", "安其拉"}
        s["spell;created=19084"] = {"魔暴龙皮手套", "CRAFTING"}
        s["npc;drop=11361"] = {"祖利安猛虎", "祖尔格拉布"}
        s["npc;drop=15323"] = {"佐拉沙行者", "安其拉废墟"}
        s["spell;created=19097"] = {"魔暴龙皮护腿", "CRAFTING"}
        s["object;contained=181366"] = {"四骑士之箱", "纳克萨玛斯"}
        s["npc;drop=10399"] = {"图萨丁侍僧", "斯坦索姆"}
        s["npc;drop=16097"] = {"伊萨莉恩", "厄运之槌"}
        s["npc;drop=8929"] = {"铁炉堡公主茉艾拉·铜须 <铁炉堡公主>", "黑石深渊"}
        s["quest;reward=7981"] = {"1200张奖券 - 暗月护符", "莫高雷"}
        s["npc;drop=15114"] = {"加兹兰卡", "祖尔格拉布"}
        s["npc;drop=15517"] = {"奥罗", "安其拉"}
        s["quest;reward=7862"] = {"职位空缺：恶齿村卫兵队长", "辛特兰"}
        s["npc;drop=9568"] = {"维姆萨拉克", "黑石塔"}
        s["quest;reward=3321"] = {"秘银会的认可", "塔纳利斯"}
        s["npc;sold=12805"] = {"埃雷恩 <杂货军需官>", "暴风城"}
        s["npc;sold=12799"] = {"巴沙 <杂货军需官>", "奥格瑞玛"}
        s["npc;drop=12463"] = {"死爪火鳞龙人", "黑翼之巢"}
        s["quest;reward=7877"] = {"辛德拉的宝藏", "厄运之槌"}
        s["npc;drop=9025"] = {"洛考尔", "黑石深渊"}
        s["npc;drop=2748"] = {"阿扎达斯", "奥达曼"}
        s["npc;drop=10503"] = {"詹迪斯·巴罗夫", "通灵学院"}
        s["spell;created=23707"] = {"熔岩腰带", "CRAFTING"}
        s["npc;drop=228022"] = {"毁灭者的幻影", "屠魔峡谷"}
        s["npc;drop=227140"] = {"派拉尼斯", "屠魔峡谷"}
        s["spell;created=460462"] = {"萨弗拉斯之眼", "CRAFTING"}
        s["npc;drop=227028"] = {"地狱咆哮的幻灵", "屠魔峡谷"}
        s["npc;drop=15204"] = {"大元帅维拉希斯", "希利苏斯"}
        s["npc;drop=218624"] = {"阿塔拉利恩 <护卫者>", "阿塔哈卡神庙"}
        s["npc;drop=228430"] = {"玛格曼达", "熔火之心"}
        s["spell;created=24123"] = {"原始蝙蝠皮护腕", "CRAFTING"}
        s["spell;created=24122"] = {"原始蝙蝠皮手套", "CRAFTING"}
        s["npc;drop=10422"] = {"红衣法术师", "斯坦索姆"}
        s["quest;reward=84561"] = {"[For All To See]", "奥格瑞玛"}
        s["quest;reward=5944"] = {"在梦中", "西瘟疫之地"}
        s["quest;reward=8949"] = {"法尔林的复仇", "厄运之槌"}
        s["npc;sold=12944"] = {"罗克图斯·暗契 <瑟银兄弟会>", "黑石深渊"}
        s["npc;drop=228436"] = {"萨弗隆先驱者", "熔火之心"}
        s["spell;created=461712"] = {"精工泰坦之锤", "CRAFTING"}
        s["spell;created=16988"] = {"泰坦之锤", "CRAFTING"}
        s["npc;drop=221943"] = {"哈扎斯", "阿塔哈卡神庙"}
        s["npc;drop=7355"] = {"图特卡什", "剃刀高地"}
        s["spell;created=461722"] = {"恶魔之核护手", "CRAFTING"}
        s["spell;created=461724"] = {"恶魔之核护腿", "CRAFTING"}
        s["quest;reward=84545"] = {"英雄的奖赏", "艾萨拉"}
        s["npc;drop=15510"] = {"顽强的范克瑞斯", "安其拉"}
        s["npc;drop=15341"] = {"拉贾克斯将军", "安其拉废墟"}
        s["npc;drop=15340"] = {"莫阿姆", "安其拉废墟"}
        s["npc;drop=10487"] = {"复活的保卫者", "通灵学院"}
        s["npc;drop=5717"] = {"米杉", "阿塔哈卡神庙"}
        s["npc;drop=15263"] = {"预言者斯克拉姆", "安其拉"}
        s["npc;drop=16449"] = {"纳克萨玛斯之魂", "纳克萨玛斯"}
        s["npc;drop=12460"] = {"黑翼龙人护卫", "黑翼之巢"}
        s["npc;drop=10430"] = {"比斯巨兽", "黑石塔"}
        s["npc;drop=10500"] = {"鬼灵教师", "通灵学院"}
        s["npc;drop=221407"] = {"梦影小鬼", "菲拉斯"}
        s["npc;drop=10220"] = {"哈雷肯", "黑石塔"}
        s["npc;drop=15990"] = {"克尔苏加德", "纳克萨玛斯"}
        s["npc;drop=12264"] = {"沙斯拉尔", "熔火之心"}
        s["npc;drop=15952"] = {"迈克斯纳", "纳克萨玛斯"}
        s["quest;reward=9120"] = {"克尔苏加德的末日", "东瘟疫之地"}
        s["spell;created=15596"] = {"浓烟山脉之心", "CRAFTING"}
        s["quest;reward=7067"] = {"贱民的指引", "凄凉之地"}
        s["quest;reward=8573"] = {"勇士的装备", "希利苏斯"}
        s["npc;drop=9547"] = {"醉酒的奴隶主", "黑石深渊"}
        s["spell;created=461690"] = {"精工移形披风", "CRAFTING"}
        s["npc;drop=230302"] = {"卡扎克", "腐烂之痕"}
        s["spell;created=435904"] = {"微光侏儒神经链接兜帽", "CRAFTING"}
        s["spell;created=23703"] = {"木喉之力", "CRAFTING"}
        s["spell;created=19080"] = {"战熊热裤", "CRAFTING"}
        s["npc;sold=10857"] = {"银色黎明军需官莱斯巴克 <银色黎明>", "西瘟疫之地"}
        s["spell;created=23705"] = {"黎明皮靴", "CRAFTING"}
        s["npc;sold=13278"] = {"海达克西斯公爵", "艾萨拉"}
        s["npc;sold=218115"] = {"迈辛 <古拉巴什兑血者>", "荆棘谷"}
        s["npc;drop=204921"] = {"格里哈斯特", "黑暗深渊"}
        s["quest;reward=80324"] = {"疯王", "铁炉堡"}
        s["npc;drop=202699"] = {"阿奎尼斯男爵", "黑暗深渊"}
        s["npc;drop=8567"] = {"暴食者", "剃刀高地"}
        s["npc;drop=220007"] = {"粘性辐射尘", "诺莫瑞根"}
        s["npc;sold=217689"] = {"“扳手”兹里·微轮 <齿轮狂人>", "诺莫瑞根"}
        s["npc;drop=201722"] = {"加摩拉", "黑暗深渊"}
        s["npc;drop=220072"] = {"电刑器6000型", "诺莫瑞根"}
        s["spell;created=429354"] = {"虚空之触皮手套", "CRAFTING"}
        s["quest;reward=824"] = {"陶土议会的耶努萨克雷", "灰谷"}
        s["quest;reward=80132"] = {"[Rig Wars]", "奥格瑞玛"}
        s["npc;drop=3669"] = {"考布莱恩", "哀嚎洞穴"}
        s["npc;drop=215728"] = {"[Crowd Pummeler 9-60]", "诺莫瑞根"}
        s["npc;drop=218537"] = {"机械师瑟玛普拉格", "诺莫瑞根"}
        s["npc;drop=4295"] = {"血色仆从", "血色修道院"}
        s["quest;reward=7541"] = {"为部落效力", "奥格瑞玛"}
        s["npc;drop=6489"] = {"铁脊死灵", "血色修道院"}
        s["quest;reward=78916"] = {"虚空之心", "达纳苏斯"}
        s["npc;drop=207356"] = {"洛古斯·杰特", "黑暗深渊"}
        s["npc;drop=7584"] = {"森林漫游者", "菲拉斯"}
        s["npc;drop=14491"] = {"科尔摩克", "荆棘谷"}
        s["npc;drop=4389"] = {"黑色蛇颈龙", "尘泥沼泽"}
        s["npc;drop=2433"] = {"赫尔库拉的遗骸", "希尔斯布莱德丘陵"}
        s["spell;created=6705"] = {"鱼人鳞片护腕", "CRAFTING"}
        s["spell;created=3779"] = {"野人腰带", "CRAFTING"}
        s["npc;drop=4845"] = {"暗炉恶棍", "荒芜之地"}
        s["quest;reward=2767"] = {"拯救OOX-22/FE！", "菲拉斯"}
        s["quest;reward=793"] = {"破碎的联盟", "荒芜之地"}
        s["spell;created=435960"] = {"超导金链腰带", "CRAFTING"}
        s["npc;drop=16118"] = {"库尔莫克", "通灵学院"}
        s["npc;drop=9033"] = {"安格弗将军", "黑石深渊"}
        s["npc;drop=12018"] = {"管理者埃克索图斯", "熔火之心"}
        s["npc;drop=15509"] = {"哈霍兰公主", "安其拉"}
        s["quest;reward=7506"] = {"翡翠梦境……", "厄运之槌"}
        s["npc;drop=15299"] = {"维希度斯", "安其拉"}
        s["npc;drop=14888"] = {"莱索恩", "暮色森林"}
        s["npc;drop=15543"] = {"亚尔基公主", "安其拉"}
        s["spell;created=22927"] = {"野性之皮", "CRAFTING"}
        s["npc;drop=11501"] = {"戈多克大王", "厄运之槌"}
        s["npc;drop=10268"] = {"奴役者基兹鲁尔", "黑石塔"}
        s["spell;created=22759"] = {"光芒护腕", "CRAFTING"}
        s["npc;drop=15339"] = {"无疤者奥斯里安", "安其拉废墟"}
        s["npc;drop=5712"] = {"祖罗", "阿塔哈卡神庙"}
        s["spell;created=23709"] = {"熔火犬皮腰带", "CRAFTING"}
        s["npc;drop=13020"] = {"堕落的瓦拉斯塔兹", "黑翼之巢"}
        s["npc;drop=11488"] = {"伊琳娜·暗木", "厄运之槌"}
        s["npc;drop=9056"] = {"弗诺斯·达克维尔 <首席建筑师>", "黑石深渊"}
        s["npc;drop=10504"] = {"阿雷克斯·巴罗夫", "通灵学院"}
        s["npc;drop=14325"] = {"克罗卡斯", "厄运之槌"}
        s["npc;drop=10809"] = {"石脊", "斯坦索姆"}
        s["quest;reward=8791"] = {"奥斯里安之死", "希利苏斯"}
        s["npc;drop=10439"] = {"吞咽者拉姆斯登", "斯坦索姆"}
        s["quest;reward=7907"] = {"暗月野兽套牌", "艾尔文森林"}
        s["object;contained=169243"] = {"七贤之箱", "黑石深渊"}
        s["npc;drop=14515"] = {"高阶祭司娅尔罗", "祖尔格拉布"}
        s["npc;drop=16080"] = {"莫尔·灰蹄", "黑石塔"}
        s["spell;created=461750"] = {"炽火月布头饰", "CRAFTING"}
        s["spell;created=23665"] = {"银色护肩", "CRAFTING"}
        s["spell;created=446189"] = {"着迷沉醉护肩", "CRAFTING"}
        s["spell;created=19061"] = {"生命护肩", "CRAFTING"}
        s["spell;created=446194"] = {"失心披肩", "CRAFTING"}
        s["npc;drop=221394"] = {"哈卡的化身", "阿塔哈卡神庙"}
        s["npc;drop=228431"] = {"基赫纳斯", "熔火之心"}
        s["npc;drop=9236"] = {"暗影猎手沃什加斯", "黑石塔"}
        s["spell;created=19435"] = {"月布长靴", "CRAFTING"}
        s["npc;drop=218571"] = {"伊兰尼库斯的阴影", "阿塔哈卡神庙"}
        s["npc;drop=10506"] = {"传令官基尔图诺斯", "通灵学院"}
        s["quest;reward=80325"] = {"[The Mad King]", "奥格瑞玛"}
        s["quest;reward=82081"] = {"破碎的仪式", "荆棘谷"}
        s["quest;reward=82058"] = {"暗月荒野套牌", "艾尔文森林"}
        s["npc;drop=226922"] = {"吉尔巴格布", "屠魔峡谷"}
        s["npc;drop=9938"] = {"玛格姆斯", "黑石深渊"}
        s["npc;drop=3977"] = {"大检察官怀特迈恩", "血色修道院"}
        s["npc;drop=14324"] = {"观察者克鲁什", "厄运之槌"}
        s["npc;drop=11661"] = {"烈焰行者", "熔火之心"}
        s["npc;drop=11673"] = {"上古熔火恶犬", "熔火之心"}
        s["quest;reward=9008"] = {"最后的奖赏", "奥格瑞玛"}
        s["quest;reward=4024"] = {"烈焰精华", "燃烧平原"}
        s["npc;drop=13276"] = {"荒野小鬼", "厄运之槌"}
        s["npc;drop=9027"] = {"修行者高罗什", "黑石深渊"}
        s["npc;drop=10264"] = {"索拉卡·火冠", "黑石塔"}
        s["quest;reward=8906"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8938"] = {"小小的补偿", "奥格瑞玛"}
        s["npc;drop=10393"] = {"斯库尔", "斯坦索姆"}
        s["npc;drop=11489"] = {"特迪斯·扭木", "厄运之槌"}
        s["npc;drop=9596"] = {"班诺克·巨斧 <火印军团勇士>", "黑石塔"}
        s["quest;reward=8952"] = {"告别安泰恩", "黑石塔"}
        s["spell;created=22922"] = {"猫鼬长靴", "CRAFTING"}
        s["quest;reward=5125"] = {"奥里克斯的清算", "斯坦索姆"}
        s["quest;reward=7503"] = {"最伟大的猎手", "厄运之槌"}
        s["quest;reward=82108"] = {"神庙中的绿龙", "阿塔哈卡神庙"}
        s["npc;drop=10438"] = {"苍白的玛勒基", "斯坦索姆"}
        s["npc;drop=221391"] = {"[Slirena] <[Harpy Queen]>", "菲拉斯"}
        s["npc;drop=15740"] = {"佐拉巨甲虫", "希利苏斯"}
        s["spell;created=462623"] = {"合成伦鲁迪洛尔", "CRAFTING"}
        s["quest;reward=82104"] = {"预言者迦玛兰", "辛特兰"}
        s["npc;drop=8908"] = {"熔岩作战傀儡", "黑石深渊"}
        s["quest;reward=84148"] = {"热心的建议", "铁炉堡"}
        s["spell;created=446237"] = {"虚空强化的屠戮者腕铠", "CRAFTING"}
        s["npc;drop=9029"] = {"剜眼者", "黑石深渊"}
        s["quest;reward=7029"] = {"维利塔恩的污染", "凄凉之地"}
        s["object;contained=179564"] = {"戈多克贡品", "厄运之槌"}
        s["npc;drop=9445"] = {"黑暗卫兵", "黑石深渊"}
        s["spell;created=23639"] = {"黑色怒火", "CRAFTING"}
        s["spell;created=461675"] = {"精炼奥金斧", "CRAFTING"}
        s["npc;drop=222573"] = {"谵妄古魂", "祖尔法拉克"}
        s["quest;reward=8272"] = {"霜狼英雄", "奥特兰克山脉"}
        s["quest;reward=3636"] = {"与圣光同在", "暴风城"}
        s["quest;reward=1364"] = {"马森的请求", "暴风城"}
        s["npc;drop=7603"] = {"麻疯助手", "诺莫瑞根"}
        s["npc;drop=2716"] = {"火烟猎龙者", "荒芜之地"}
        s["quest;reward=628"] = {"刨花皮靴", "荆棘谷"}
        s["npc;drop=6910"] = {"鲁维罗什", "奥达曼"}
        s["quest;reward=7068"] = {"暗影残片", "奥格瑞玛"}
        s["quest;reward=2822"] = {"质量的保证", "菲拉斯"}
        s["npc;drop=5860"] = {"暮光黑暗萨满祭司", "灼热峡谷"}
        s["npc;drop=13601"] = {"工匠吉兹洛克", "玛拉顿"}
        s["quest;reward=1048"] = {"深入血色修道院", "血色修道院"}
        s["spell;created=435953"] = {"抗辐射缀鳞兜帽", "CRAFTING"}
        s["spell;created=18457"] = {"大法师之袍", "CRAFTING"}
        s["quest;reward=8632"] = {"神秘头饰", "安其拉"}
        s["quest;reward=8625"] = {"神秘肩垫", "安其拉"}
        s["quest;reward=8633"] = {"神秘长袍", "安其拉"}
        s["quest;reward=8634"] = {"神秘长靴", "安其拉"}
        s["npc;drop=15236"] = {"维克尼黄蜂", "安其拉"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "铁炉堡"}
        s["quest;reward=84157"] = {"[An Earnest Proposition]", "奥格瑞玛"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "厄运之槌"}
        s["npc;drop=11480"] = {"奥术畸兽", "厄运之槌"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", "斯坦索姆"}
        s["npc;drop=10198"] = {"劫掠者卡苏克", "冬泉谷"}
        s["quest;reward=84165"] = {"[Just Compensation]", "铁炉堡"}
        s["spell;created=22868"] = {"地狱火手套", "CRAFTING"}
        s["npc;drop=14684"] = {"巴尔萨冯", "斯坦索姆"}
        s["quest;reward=82095"] = {"神灵哈卡", "塔纳利斯"}
        s["quest;reward=8932"] = {"小小的补偿", "铁炉堡"}
        s["npc;drop=9024"] = {"控火师罗格雷恩", "黑石深渊"}
        s["quest;reward=617"] = {"一捆海蛇草", "荆棘谷"}
        s["npc;drop=6146"] = {"峭壁击碎者", "艾萨拉"}
        s["spell;created=446236"] = {"虚空强化的祈咒者腕铠", "CRAFTING"}
        s["quest;reward=3907"] = {"不和谐的火焰", "荒芜之地"}
        s["spell;created=23663"] = {"木喉衬肩", "CRAFTING"}
        s["npc;drop=4288"] = {"血色驯兽员", "血色修道院"}
        s["npc;drop=6487"] = {"奥法师杜安", "血色修道院"}
        s["quest;reward=8366"] = {"南海复仇", "塔纳利斯"}
        s["npc;drop=14446"] = {"芬加特", "悲伤沼泽"}
        s["spell;created=16724"] = {"白魂头盔", "CRAFTING"}
        s["npc;drop=10339"] = {"盖斯 <雷德·黑手的坐骑>", "黑石塔"}
        s["spell;created=19054"] = {"红龙鳞片胸甲", "CRAFTING"}
        s["npc;drop=14321"] = {"卫兵芬古斯", "厄运之槌"}
        s["npc;drop=14861"] = {"基尔图诺斯的卫士", "通灵学院"}
        s["quest;reward=7501"] = {"圣光之力", "厄运之槌"}
        s["spell;created=446191"] = {"灾劫肩甲", "CRAFTING"}
        s["spell;created=446190"] = {"哀嚎链甲披肩", "CRAFTING"}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", "铁炉堡"}
        s["npc;drop=10464"] = {"哀嚎的女妖", "斯坦索姆"}
        s["npc;drop=12203"] = {"兰斯利德", "玛拉顿"}
        s["spell;created=435906"] = {"反射性真银脑笼", "CRAFTING"}
        s["spell;created=435949"] = {"闪光超导缀鳞罩帽", "CRAFTING"}
        s["spell;created=435610"] = {"侏儒神经链接奥术丝线单片镜", "CRAFTING"}
        s["npc;drop=14686"] = {"法瑟蕾丝夫人", "剃刀高地"}
        s["npc;sold=222685"] = {"军需官基琳", "灰谷"}
        s["spell;created=20874"] = {"黑铁护腕", "CRAFTING"}
        s["spell;created=24399"] = {"黑铁长靴", "CRAFTING"}
        s["npc;sold=3144"] = {"伊崔格", "奥格瑞玛"}
        s["quest;reward=80131"] = {"[Gnome Improvement]", "铁炉堡"}
        s["npc;drop=2691"] = {"高原前锋", "辛特兰"}
        s["npc;drop=10596"] = {"烟网蛛后", "黑石塔"}
        s["spell;created=461730"] = {"加固寒冰护卫者", "CRAFTING"}
        s["spell;created=23652"] = {"黑色卫士", "CRAFTING"}
        s["spell;created=461669"] = {"精炼奥金勇士剑", "CRAFTING"}
        s["spell;created=22797"] = {"力反馈盾牌", "CRAFTING"}
        s["npc;drop=3976"] = {"血色十字军指挥官莫格莱尼", "血色修道院"}
        s["quest;reward=7065"] = {"大地的污染", "凄凉之地"}
        s["spell;created=9952"] = {"精制秘银护肩", "CRAFTING"}
        s["npc;drop=5287"] = {"长牙嚎叫者", "菲拉斯"}
        s["npc;drop=1884"] = {"血色伐木工", "西瘟疫之地"}
        s["npc;drop=14690"] = {"雷瓦克安", "厄运之槌"}
        s["npc;drop=10418"] = {"红衣卫兵", "斯坦索姆"}
        s["npc;drop=10808"] = {"悲惨的提米", "斯坦索姆"}
        s["spell;created=16729"] = {"狮心头盔", "CRAFTING"}
        s["spell;created=435908"] = {"淬火的抗干扰头盔", "CRAFTING"}
        s["spell;created=24141"] = {"黑暗之魂护肩", "CRAFTING"}
        s["npc;drop=7524"] = {"痛苦的上层精灵", "冬泉谷"}
        s["spell;created=19101"] = {"火山护肩", "CRAFTING"}
        s["spell;created=446179"] = {"恐惧惊魂肩铠", "CRAFTING"}
        s["quest;reward=5166"] = {"多彩巨龙胸甲", "西瘟疫之地"}
        s["spell;created=19076"] = {"火山胸甲", "CRAFTING"}
        s["spell;created=24139"] = {"黑暗之魂胸甲", "CRAFTING"}
        s["spell;created=446238"] = {"虚空强化的护卫者腕铠", "CRAFTING"}
        s["spell;created=23633"] = {"黎明手套", "CRAFTING"}
        s["spell;created=461671"] = {"要冲护手", "CRAFTING"}
        s["spell;created=23632"] = {"黎明束腰", "CRAFTING"}
        s["quest;reward=5081"] = {"麦克斯韦尔的任务", "黑石塔"}
        s["spell;created=19059"] = {"火山护腿", "CRAFTING"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "东瘟疫之地"}
        s["spell;created=461718"] = {"宁静", "CRAFTING"}
        s["spell;created=21160"] = {"萨弗拉斯之眼", "CRAFTING"}
        s["npc;drop=9039"] = {"杜姆雷尔", "黑石深渊"}
        s["npc;drop=9031"] = {"阿努希尔", "黑石深渊"}
        s["spell;created=20873"] = {"炽热链甲护肩", "CRAFTING"}
        s["npc;drop=15305"] = {"斯古恩男爵", "希利苏斯"}
        s["spell;created=461651"] = {"秘传技艺之炽热板甲护手", "CRAFTING"}
        s["spell;created=27585"] = {"重型黑曜石腰带", "CRAFTING"}
        s["spell;created=27829"] = {"泰坦护腿", "CRAFTING"}
        s["spell;created=20876"] = {"黑铁护腿", "CRAFTING"}
        s["quest;reward=8572"] = {"精兵的装备", "希利苏斯"}
        s["spell;created=12906"] = {"侏儒作战小鸡", "CRAFTING"}
        s["spell;created=460460"] = {"萨弗隆战锤", "CRAFTING"}
        s["spell;created=450409"] = {"苏萨斯的召唤", "CRAFTING"}
        s["npc;drop=8127"] = {"安图苏尔", "祖尔法拉克"}
        s["spell;created=461714"] = {"渎圣", "CRAFTING"}
        s["npc;drop=227019"] = {"搜寻者迪亚索鲁斯", "屠魔峡谷"}
        s["spell;created=16994"] = {"奥金斧", "CRAFTING"}
        s["spell;created=23151"] = {"平衡光与影", "CRAFTING"}
        s["npc;drop=14517"] = {"高阶祭司耶克里克", "祖尔格拉布"}
        s["npc;drop=15816"] = {"其拉少校赫拉雷", "千针石林"}
        s["quest;reward=9009"] = {"最后的奖赏", "奥格瑞玛"}
        s["npc;drop=11382"] = {"血领主曼多基尔", "祖尔格拉布"}
        s["spell;created=18456"] = {"信念外衣", "CRAFTING"}
        s["npc;drop=11664"] = {"烈焰行者精英", "熔火之心"}
        s["quest;reward=8909"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8940"] = {"小小的补偿", "奥格瑞玛"}
        s["npc;drop=14509"] = {"高阶祭司塞卡尔", "祖尔格拉布"}
        s["quest;reward=9019"] = {"告别安泰恩", "黑石塔"}
        s["npc;drop=14887"] = {"伊森德雷", "暮色森林"}
        s["quest;reward=7504"] = {"光明不会告诉你的事情", "厄运之槌"}
        s["quest;reward=82111"] = {"摩弗拉斯之血", "艾萨拉"}
        s["npc;drop=12459"] = {"黑翼管理者", "黑翼之巢"}
        s["object;contained=161495"] = {"秘密保险箱", "黑石深渊"}
        s["spell;created=463008"] = {"平衡光与影", "CRAFTING"}
        s["spell;created=461708"] = {"炽火月布长袍", "CRAFTING"}
        s["quest;reward=84151"] = {"热心的建议", "铁炉堡"}
        s["spell;created=461752"] = {"炽火月布护腿", "CRAFTING"}
        s["quest;reward=55"] = {"摩本特·费尔", "暮色森林"}
        s["npc;drop=4366"] = {"斯塔莎兹毒蛇守卫", "尘泥沼泽"}
        s["npc;drop=10423"] = {"红衣牧师", "斯坦索姆"}
        s["npc;drop=9818"] = {"黑手召唤师 <黑手军团>", "黑石塔"}
        s["spell;created=446193"] = {"心智破碎肩甲", "CRAFTING"}
        s["npc;drop=9219"] = {"尖石屠夫", "黑石塔"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "诅咒之地"}
        s["quest;reward=9225"] = {"史诗级的作战装备 - 银色黎明崇敬", "东瘟疫之地"}
        s["npc;drop=10425"] = {"红衣战斗法师", "斯坦索姆"}
        s["npc;drop=10477"] = {"通灵学院亡灵法师", "通灵学院"}
        s["npc;drop=8923"] = {"无敌的潘佐尔", "黑石深渊"}
        s["npc;drop=10502"] = {"伊露希亚·巴罗夫", "通灵学院"}
        s["quest;reward=9221"] = {"精良的作战装备 - 银色黎明友善", "东瘟疫之地"}
        s["npc;drop=14327"] = {"蕾瑟塔蒂丝", "厄运之槌"}
        s["spell;created=18436"] = {"冬夜法袍", "CRAFTING"}
        s["npc;drop=12457"] = {"黑翼缚法者", "黑翼之巢"}
        s["quest;reward=8592"] = {"神谕者的皇冠", "安其拉"}
        s["quest;reward=8594"] = {"神谕者的衬肩", "安其拉"}
        s["spell;created=18453"] = {"恶魔布护肩", "CRAFTING"}
        s["quest;reward=8603"] = {"神谕者的外套", "安其拉"}
        s["npc;drop=15247"] = {"其拉洗脑者", "安其拉"}
        s["spell;created=22867"] = {"恶魔布手套", "CRAFTING"}
        s["npc;drop=10432"] = {"维克图斯", "通灵学院"}
        s["spell;created=23041"] = {"召唤咒逐", "CRAFTING"}
        s["npc;drop=14516"] = {"死亡骑士达克雷尔", "通灵学院"}
        s["spell;created=461962"] = {"召唤咒逐", "CRAFTING"}
        s["npc;drop=1843"] = {"工头杰瑞斯", "西瘟疫之地"}
        s["npc;drop=12801"] = {"魔法奇美洛克", "菲拉斯"}
        s["npc;drop=228914"] = {"分离的守卫者", "屠魔峡谷"}
        s["npc;drop=10119"] = {"沃尔查", "燃烧平原"}
        s["npc;drop=16154"] = {"复活的死亡骑士", "纳克萨玛斯"}
        s["npc;drop=11469"] = {"艾德雷斯怨魂", "厄运之槌"}
        s["npc;drop=14506"] = {"赫尔努拉斯", "厄运之槌"}
        s["npc;drop=14473"] = {"拉普雷斯", "希利苏斯"}
        s["npc;drop=15975"] = {"腐肉织网者", "纳克萨玛斯"}
        s["npc;drop=1838"] = {"血色质问者", "西瘟疫之地"}
        s["npc;drop=1851"] = {"哈斯克", "西瘟疫之地"}
        s["npc;drop=7104"] = {"迪塞库斯", "费伍德森林"}
        s["npc;drop=15757"] = {"其拉中将", "希利苏斯"}
        s["npc;drop=15390"] = {"库雷姆上尉", "安其拉废墟"}
        s["npc;drop=10371"] = {"狂爪队长", "黑石塔"}
        s["npc;drop=11896"] = {"淤血虫", "东瘟疫之地"}
        s["npc;drop=7459"] = {"冰蓟雪人女王", "冬泉谷"}
        s["npc;drop=10663"] = {"魔法利爪", "冬泉谷"}
        s["spell;created=18442"] = {"恶魔布帽", "CRAFTING"}
        s["npc;drop=11143"] = {"邮差马龙", "斯坦索姆"}
        s["spell;created=19794"] = {"法术能量护目镜超级改良版", "CRAFTING"}
        s["npc;drop=11622"] = {"血骨傀儡", "通灵学院"}
        s["object;contained=181074"] = {"竞技场的泥土", "黑石深渊"}
        s["spell;created=18451"] = {"恶魔布袍", "CRAFTING"}
        s["npc;drop=9817"] = {"黑手恐法师 <黑手军团>", "黑石塔"}
        s["npc;drop=10372"] = {"狂爪火舌龙人", "黑石塔"}
        s["npc;drop=11490"] = {"瑟雷姆·刺蹄", "厄运之槌"}
        s["npc;drop=10901"] = {"博学者普克尔特", "通灵学院"}
        s["npc;drop=11467"] = {"苏斯", "厄运之槌"}
        s["spell;created=18454"] = {"法术掌握手套", "CRAFTING"}
        s["spell;created=18419"] = {"恶魔布短裤", "CRAFTING"}
        s["npc;drop=10436"] = {"安娜丝塔丽男爵夫人", "斯坦索姆"}
        s["npc;drop=10558"] = {"弗雷斯特恩", "斯坦索姆"}
        s["npc;drop=9217"] = {"尖石首席法师", "黑石塔"}
        s["npc;drop=6228"] = {"黑铁大师", "诺莫瑞根"}
        s["npc;drop=6370"] = {"玛科尼快钳龙虾人", "艾萨拉"}
        s["quest;reward=9004"] = {"最后的奖赏", "铁炉堡"}
        s["quest;reward=8956"] = {"告别安泰恩", "铁炉堡"}
        s["quest;reward=8910"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8941"] = {"小小的补偿", "奥格瑞玛"}
        s["quest;reward=8639"] = {"死亡执行者的头盔", "安其拉"}
        s["quest;reward=8641"] = {"死亡执行者的护肩", "安其拉"}
        s["quest;reward=8638"] = {"死亡执行者的胸甲", "安其拉"}
        s["npc;drop=10505"] = {"讲师玛丽希亚", "通灵学院"}
        s["quest;reward=8201"] = {"祭司的头颅", "荆棘谷"}
        s["npc;drop=9265"] = {"燃棘暗影猎手", "黑石塔"}
        s["quest;reward=8640"] = {"死亡执行者的护腿", "安其拉"}
        s["quest;reward=8637"] = {"死亡执行者的长靴", "安其拉"}
        s["npc;drop=14507"] = {"高阶祭司温诺希斯", "祖尔格拉布"}
        s["quest;reward=7498"] = {"迦罗娜：潜行与诡计研究", "厄运之槌"}
        s["quest;reward=7787"] = {"觉醒吧，雷霆之怒！", "希利苏斯"}
        s["npc;drop=203138"] = {"铁怒监军", "黑石深渊"}
        s["spell;created=461237"] = {"暗影烈焰之颅", "CRAFTING"}
        s["spell;created=19090"] = {"雷暴护肩", "CRAFTING"}
        s["spell;created=19079"] = {"雷暴", "CRAFTING"}
        s["quest;reward=84152"] = {"热心的建议", "铁炉堡"}
        s["spell;created=26279"] = {"雷暴手套", "CRAFTING"}
        s["npc;drop=10318"] = {"黑手刺客 <黑手军团>", "黑石塔"}
        s["spell;created=19067"] = {"雷暴短裤", "CRAFTING"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "厄运之槌"}
        s["npc;drop=15741"] = {"雷戈巨甲虫", "希利苏斯"}
        s["npc;drop=14222"] = {"阿拉加", "奥特兰克山脉"}
        s["quest;reward=53"] = {"琥珀酒", "西部荒野"}
        s["npc;drop=2601"] = {"弗尔伯利", "阿拉希高地"}
        s["npc;drop=2751"] = {"作战傀儡", "荒芜之地"}
        s["spell;created=9201"] = {"暗色护腕", "CRAFTING"}
        s["quest;reward=80455"] = {"[Biding Our Time]", "银松森林"}
        s["npc;drop=15209"] = {"赤红圣殿骑士 <深渊议会>", "希利苏斯"}
        s["spell;created=23706"] = {"金色黎明衬肩", "CRAFTING"}
        s["spell;created=19068"] = {"战熊背心", "CRAFTING"}
        s["npc;drop=9237"] = {"指挥官沃恩", "黑石塔"}
        s["npc;drop=15817"] = {"其拉准将帕克里斯", "希利苏斯"}
        s["quest;reward=8623"] = {"风暴召唤者的王冠", "安其拉"}
        s["quest;reward=9011"] = {"最后的奖赏", "奥格瑞玛"}
        s["quest;reward=7668"] = {"达克雷尔的威胁", "奥格瑞玛"}
        s["quest;reward=8602"] = {"风暴召唤者的肩甲", "安其拉"}
        s["spell;created=16650"] = {"野刺锁甲", "CRAFTING"}
        s["quest;reward=8622"] = {"风暴召唤者的护甲", "安其拉"}
        s["quest;reward=8918"] = {"热心的建议", "奥格瑞玛"}
        s["npc;drop=14454"] = {"烈风掠夺者", "希利苏斯"}
        s["quest;reward=8621"] = {"风暴召唤者的足甲", "安其拉"}
        s["npc;drop=11462"] = {"扭木树人", "厄运之槌"}
        s["quest;reward=7505"] = {"你与冰霜震击", "厄运之槌"}
        s["quest;reward=82113"] = {"[Da Voodoo]", "奥特兰克山脉"}
        s["spell;created=461735"] = {"无敌锁甲", "CRAFTING"}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", "奥格瑞玛"}
        s["npc;drop=11043"] = {"红衣僧侣", "斯坦索姆"}
        s["spell;created=461737"] = {"风暴护手", "CRAFTING"}
        s["npc;drop=10083"] = {"狂爪火鳞龙人", "黑石塔"}
        s["npc;drop=10814"] = {"多彩精英卫士", "黑石塔"}
        s["npc;drop=14323"] = {"卫兵斯里基克", "厄运之槌"}
        s["spell;created=446186"] = {"刺耳链甲肩铠", "CRAFTING"}
        s["spell;created=451706"] = {"尖啸链甲护肩", "CRAFTING"}
        s["npc;drop=9028"] = {"格里兹尔", "黑石深渊"}
        s["spell;created=24138"] = {"血魂护手", "CRAFTING"}
        s["npc;drop=224257"] = {"阿塔莱奴隶", "阿塔哈卡神庙"}
        s["spell;created=435958"] = {"回旋真银齿轮之壁", "CRAFTING"}
        s["spell;created=19094"] = {"黑色龙鳞护肩", "CRAFTING"}
        s["spell;created=23708"] = {"多彩护手", "CRAFTING"}
        s["spell;created=19107"] = {"黑色龙鳞护腿", "CRAFTING"}
        s["spell;created=20855"] = {"黑色龙鳞战靴", "CRAFTING"}
        s["spell;created=23653"] = {"夜幕", "CRAFTING"}
        s["npc;drop=6117"] = {"上层精灵鬼巫", "艾萨拉"}
        s["spell;created=19085"] = {"黑色龙鳞胸甲", "CRAFTING"}
        s["npc;drop=10507"] = {"拉文尼亚", "通灵学院"}
        s["spell;created=16991"] = {"歼灭者", "CRAFTING"}
        s["npc;drop=12258"] = {"锐刺鞭笞者", "玛拉顿"}
        s["npc;drop=7358"] = {"寒冰之王亚门纳尔", "剃刀高地"}
        s["quest;reward=79366"] = {"[Calm Before the Storm]", "千针石林"}
        s["npc;drop=13596"] = {"洛特格里普", "玛拉顿"}
        s["quest;reward=8624"] = {"风暴召唤者的护腿", "安其拉"}
        s["quest;reward=7488"] = {"蕾瑟塔蒂丝的网", "菲拉斯"}
        s["quest;reward=5526"] = {"魔藤碎片", "月光林地"}
        s["spell;created=8770"] = {"力量法袍", "CRAFTING"}
        s["npc;drop=7357"] = {"火眼莫德雷斯", "剃刀高地"}
        s["spell;created=24356"] = {"血藤护目镜", "CRAFTING"}
        s["quest;reward=8662"] = {"厄运召唤者的头饰", "安其拉"}
        s["quest;reward=9005"] = {"最后的奖赏", "铁炉堡"}
        s["quest;reward=8664"] = {"厄运召唤者的衬肩", "安其拉"}
        s["quest;reward=8661"] = {"厄运召唤者的长袍", "安其拉"}
        s["spell;created=18458"] = {"虚空法袍", "CRAFTING"}
        s["quest;reward=8936"] = {"小小的补偿", "铁炉堡"}
        s["quest;reward=8381"] = {"军备物资", "希利苏斯"}
        s["spell;created=24201"] = {"制作黎明符文", "CRAFTING"}
        s["quest;reward=7502"] = {"束缚之影", "厄运之槌"}
        s["spell;created=461747"] = {"炽火月布外衣", "CRAFTING"}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", "铁炉堡"}
        s["spell;created=23662"] = {"木喉之智", "CRAFTING"}
        s["spell;created=462282"] = {"刺绣大法师腰带", "CRAFTING"}
        s["npc;drop=15220"] = {"微风公爵", "希利苏斯"}
        s["spell;created=429351"] = {"超界蛛丝之靴", "CRAFTING"}
        s["npc;drop=15203"] = {"斯卡德诺克斯王子", "希利苏斯"}
        s["spell;created=19830"] = {"奥金幼龙", "CRAFTING"}
        s["spell;created=461743"] = {"魔法导师的贤明剑", "CRAFTING"}
        s["spell;created=20848"] = {"光芒衬肩", "CRAFTING"}
        s["npc;drop=10376"] = {"水晶之牙", "黑石塔"}
        s["npc;drop=16058"] = {"沃莉达", "黑石深渊"}
        s["spell;created=446195"] = {"错乱者肩甲", "CRAFTING"}
        s["spell;created=22870"] = {"护卫披风", "CRAFTING"}
        s["npc;drop=9439"] = {"黑暗守护者尤格尔", "黑石深渊"}
        s["spell;created=19093"] = {"奥妮克希亚鳞片披风", "CRAFTING"}
        s["spell;created=20849"] = {"光芒手套", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "奥格瑞玛"}
        s["quest;reward=5942"] = {"隐藏的宝藏", "东瘟疫之地"}
        s["npc;drop=5722"] = {"哈扎斯", "阿塔哈卡神庙"}
        s["quest;reward=1560"] = {"图加的任务", "塔纳利斯"}
        s["npc;drop=15208"] = {"碎石公爵 <深渊议会>", "希利苏斯"}
        s["spell;created=23666"] = {"光芒长袍", "CRAFTING"}
        s["quest;reward=80141"] = {"诺格的手艺", "奥格瑞玛"}
        s["quest;reward=82107"] = {"[Voodoo Feathers]", "悲伤沼泽"}
        s["npc;drop=8762"] = {"林木隐匿者", "艾萨拉"}
        s["quest;reward=3129"] = {"灵魂武器", "菲拉斯"}
        s["quest;reward=84162"] = {"热心的建议", "奥格瑞玛"}
        s["quest;reward=9006"] = {"最后的奖赏", "铁炉堡"}
        s["npc;drop=14889"] = {"艾莫莉丝", "暮色森林"}
        s["quest;reward=8561"] = {"征服者的皇冠", "安其拉"}
        s["quest;reward=8544"] = {"征服者的肩铠", "安其拉"}
        s["quest;reward=8562"] = {"征服者的胸甲", "安其拉"}
        s["quest;reward=8937"] = {"小小的补偿", "铁炉堡"}
        s["quest;reward=8560"] = {"征服者的腿铠", "安其拉"}
        s["quest;reward=8559"] = {"征服者的胫甲", "安其拉"}
        s["quest;reward=9022"] = {"告别安泰恩", "通灵学院"}
        s["quest;reward=8789"] = {"其拉帝王武器", "安其拉"}
        s["spell;created=9954"] = {"真银护手", "CRAFTING"}
        s["quest;reward=3566"] = {"奥比斯顿", "灼热峡谷"}
        s["quest;reward=84550"] = {"[Codex of Defense]", "厄运之槌"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "黑翼之巢"}
        s["spell;created=452433"] = {"召唤格拉希尔", "CRAFTING"}
        s["npc;drop=231494"] = {"桑德兰王子 <逐风者>", "水晶谷"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "暴风城"}
        s["spell;created=452434"] = {"召唤莱拉阿", "CRAFTING"}
        s["npc;drop=14510"] = {"高阶祭司玛尔里", "祖尔格拉布"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "屠魔峡谷"}
        s["spell;created=461710"] = {"炽热之核神射手步枪", "CRAFTING"}
        s["spell;created=466117"] = {"调谐霜凌法杖", "CRAFTING"}
        s["spell;created=465417"] = {"改变姿态", "CRAFTING"}
        s["spell;created=465418"] = {"改变姿态", "CRAFTING"}
        s["npc;drop=227939"] = {"[The Molten Core]", "熔火之心"}
        s["npc;drop=15085"] = {"乌苏雷", "祖尔格拉布"}
        s["npc;drop=15083"] = {"哈扎拉尔", "祖尔格拉布"}
        s["spell;created=469201"] = {"烈焰熊燃", "CRAFTING"}
        s["spell;created=468840"] = {"组合混乱之镰", "CRAFTING"}
        s["npc;drop=15084"] = {"雷纳塔基", "祖尔格拉布"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "黑翼之巢"}
        s["spell;created=467790"] = {"组合秩序法杖", "CRAFTING"}
        s["npc;drop=16011"] = {"洛欧塞布", "纳克萨玛斯"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "奥特兰克山脉"}
        s["npc;drop=10184"] = {"奥妮克希亚", "熔火之心"}
        s["quest;reward=85454"] = {"[A Just Reward]", "湿地"}
        s["npc;drop=15369"] = {"狩猎者阿亚米斯", "安其拉废墟"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "希利苏斯"}
        s["spell;created=1216020"] = {"星象愤怒神像", "CRAFTING"}
        s["spell;created=1213538"] = {"其拉丝质披风", "CRAFTING"}
        s["npc;drop=15370"] = {"吞咽者布鲁", "安其拉废墟"}
        s["npc;drop=235197"] = {"[Taerar]", "灰谷"}
        s["npc;sold=15192"] = {"阿纳克洛斯", "塔纳利斯"}
        s["spell;created=1213595"] = {"沉睡者之泪", "CRAFTING"}
        s["spell;created=1213502"] = {"黑曜石风暴战锤", "CRAFTING"}
        s["npc;sold=15500"] = {"凯伊·迅爪", "希利苏斯"}
        s["spell;created=1216340"] = {"虚触", "CRAFTING"}
        s["spell;created=1216022"] = {"灵猫凶猛神像", "CRAFTING"}
        s["npc;drop=228230"] = {"哈里根 <黑市>", "燃烧平原"}
        s["spell;created=1213536"] = {"其拉丝质斗篷", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "希利苏斯"}
        s["spell;created=23704"] = {"木喉作战手套", "CRAFTING"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "希利苏斯"}
        s["spell;created=1213593"] = {"神速石", "CRAFTING"}
        s["spell;created=1216385"] = {"虚触", "CRAFTING"}
        s["spell;created=1213500"] = {"黑曜石毁灭者", "CRAFTING"}
        s["spell;created=1216024"] = {"熊威宏力神像", "CRAFTING"}
        s["spell;created=24121"] = {"原始蝙蝠皮外套", "CRAFTING"}
        s["spell;created=1213738"] = {"荆木头盔", "CRAFTING"}
        s["spell;created=1213736"] = {"荆木长靴", "CRAFTING"}
        s["spell;created=1213598"] = {"报应磁石", "CRAFTING"}
        s["spell;created=1216366"] = {"虚触", "CRAFTING"}
        s["spell;created=1213521"] = {"锋芒棘刺风帽", "CRAFTING"}
        s["spell;created=1213525"] = {"锋芒棘刺皮甲", "CRAFTING"}
        s["spell;created=1213523"] = {"锋芒棘刺肩垫", "CRAFTING"}
        s["npc;drop=15348"] = {"库林纳克斯", "安其拉废墟"}
        s["npc;drop=15544"] = {"维姆", "安其拉"}
        s["spell;created=1213603"] = {"红宝石外壳胸针", "CRAFTING"}
        s["spell;created=1216319"] = {"虚触", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "希利苏斯"}
        s["spell;created=1213635"] = {"魔化菌菇", "CRAFTING"}
        s["spell;created=1213540"] = {"其拉丝质披肩", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "辛特兰"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "希利苏斯"}
        s["quest;reward=86674"] = {"完美的毒药", "希利苏斯"}
        s["spell;created=1216365"] = {"虚触", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "安戈洛环形山"}
        s["spell;created=24137"] = {"血魂护肩", "CRAFTING"}
        s["spell;created=1216384"] = {"虚触", "CRAFTING"}
        s["spell;created=1216387"] = {"虚触", "CRAFTING"}
        s["spell;created=1216327"] = {"虚触", "CRAFTING"}
        s["spell;created=466116"] = {"调谐狱火法杖", "CRAFTING"}
        s["spell;created=1213628"] = {"魔化祷言集", "CRAFTING"}
        s["quest;reward=86672"] = {"其拉帝王武器", "黑翼之巢"}
        s["spell;created=1216005"] = {"正义圣契", "CRAFTING"}
        s["spell;created=1213481"] = {"锋芒刺针头盔", "CRAFTING"}
        s["spell;created=1213484"] = {"锋芒刺针肩铠", "CRAFTING"}
        s["spell;created=1214884"] = {"虚触", "CRAFTING"}
        s["spell;created=1213588"] = {"调试的力反馈盾牌", "CRAFTING"}
        s["spell;created=1214270"] = {"碎裂黑曜石盾牌", "CRAFTING"}
        s["spell;created=1213490"] = {"锋芒刺针战铠", "CRAFTING"}
        s["spell;created=1213506"] = {"黑曜石防御者", "CRAFTING"}
        s["spell;created=1216379"] = {"虚触", "CRAFTING"}
        s["spell;created=1216007"] = {"驱魔圣契", "CRAFTING"}
        s["spell;created=1216382"] = {"虚触", "CRAFTING"}
        s["spell;created=1213534"] = {"其拉丝质头巾", "CRAFTING"}
        s["spell;created=1216375"] = {"虚触", "CRAFTING"}
        s["spell;created=1213492"] = {"黑曜石掠夺者", "CRAFTING"}
        s["spell;created=1216377"] = {"虚触", "CRAFTING"}
        s["spell;created=1213498"] = {"黑曜石圣剑", "CRAFTING"}
        s["quest;reward=86671"] = {"其拉帝王徽记", "黑翼之巢"}
        s["npc;drop=234880"] = {"[Emeriss]", "暮色森林"}
        s["spell;created=1216354"] = {"虚触", "CRAFTING"}
        s["spell;created=1216014"] = {"火岩惊雷图腾", "CRAFTING"}
        s["spell;created=1213742"] = {"林栖者头冠", "CRAFTING"}
        s["spell;created=1213740"] = {"林栖者护肩", "CRAFTING"}
        s["spell;created=28210"] = {"盖亚的拥抱", "CRAFTING"}
        s["spell;created=1213744"] = {"林栖者外套", "CRAFTING"}
        s["spell;created=1214306"] = {"梦幻龙鳞护腕", "CRAFTING"}
        s["spell;created=1214307"] = {"梦幻龙鳞手套", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "菲拉斯"}
        s["quest;reward=9248"] = {"谦卑的馈赠", "希利苏斯"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "黑翼之巢"}
        s["spell;created=1213532"] = {"吸血鬼长袍", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "黑翼之巢"}
        s["spell;created=1216372"] = {"虚触", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "希利苏斯"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "安其拉"}
        s["quest;reward=86760"] = {"暗月野兽套牌", "艾尔文森林"}
        s["quest;reward=86762"] = {"暗月元素套牌", "艾尔文森林"}
        s["quest;reward=86680"] = {"[Waking Legends]", "月光林地"}
        s["spell;created=1214303"] = {"梦幻龙鳞褶裙", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "冬泉谷"}
        s["npc;drop=3975"] = {"赫洛德 <血色十字军勇士>", "血色修道院"}
        s["spell;created=1216364"] = {"虚触", "CRAFTING"}
        s["spell;created=1213633"] = {"魔化图腾", "CRAFTING"}
        s["spell;created=1216381"] = {"虚触", "CRAFTING"}
        s["npc;sold=16135"] = {"莱茵 <塞纳里奥议会>", "东瘟疫之地"}
        s["npc;drop=16061"] = {"教官拉苏维奥斯", "纳克萨玛斯"}
        s["quest;reward=87360"] = {"克尔苏加德的末日", "东瘟疫之地"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "卡拉赞墓穴"}
        s["npc;drop=16143"] = {"末日之影", "诅咒之地"}
        s["npc;drop=16380"] = {"骨巫", "燃烧平原"}
        s["quest;reward=87438"] = {"银色黎明皮甲手套", "东瘟疫之地"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "东瘟疫之地"}
        s["npc;drop=16060"] = {"收割者戈提克", "纳克萨玛斯"}
        s["npc;drop=15936"] = {"肮脏的希尔盖", "纳克萨玛斯"}
        s["npc;drop=15931"] = {"格罗布鲁斯", "纳克萨玛斯"}
        s["npc;drop=15932"] = {"格拉斯", "纳克萨玛斯"}
        s["npc;drop=15989"] = {"萨菲隆", "纳克萨玛斯"}
        s["npc;drop=14697"] = {"笨拙的憎恶", "燃烧平原"}
        s["npc;drop=237439"] = {"[Kharon]", "卡拉赞墓穴"}
        s["quest;reward=87440"] = {"银色黎明布甲手套", "东瘟疫之地"}
        s["npc;drop=15928"] = {"塔迪乌斯", "纳克萨玛斯"}
        s["npc;drop=15953"] = {"黑女巫法琳娜", "纳克萨玛斯"}
        s["npc;drop=15956"] = {"阿努布雷坎", "纳克萨玛斯"}
        s["npc;drop=15954"] = {"瘟疫使者诺斯", "纳克萨玛斯"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "卡拉赞墓穴"}
        s["spell;created=1223762"] = {"冰川披风", "CRAFTING"}
        s["npc;drop=16028"] = {"帕奇维克", "纳克萨玛斯"}
        s["npc;drop=238055"] = {"[Dark Rider]", "卡拉赞墓穴"}
        s["npc;drop=238560"] = {"[The Warden]", "卡拉赞墓穴"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "卡拉赞墓穴"}
        s["spell;created=24179"] = {"制造黎明徽记", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "东瘟疫之地"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "卡拉赞墓穴"}
        s["npc;drop=16379"] = {"诅咒者之魂", "燃烧平原"}
        s["npc;sold=16132"] = {"猎手雷奥普德 <血色十字军>", "东瘟疫之地"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "东瘟疫之地"}
        s["npc;sold=16116"] = {"大法师安吉拉·杜萨图斯 <圣光兄弟会>", "东瘟疫之地"}
        s["npc;sold=16115"] = {"指挥官埃里戈尔·黎明使者 <圣光兄弟会>", "东瘟疫之地"}
        s["quest;reward=87434"] = {"银色黎明板甲手套", "东瘟疫之地"}
        s["spell;created=1223787"] = {"破冰胸甲", "CRAFTING"}
        s["spell;created=1223791"] = {"破冰护腕", "CRAFTING"}
        s["spell;created=1223789"] = {"破冰护手", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "东瘟疫之地"}
        s["spell;created=1223780"] = {"北极外套", "CRAFTING"}
        s["spell;created=1223784"] = {"北极护腕", "CRAFTING"}
        s["spell;created=1223782"] = {"北极手套", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "塔纳利斯"}
        s["npc;sold=16113"] = {"英尼戈·蒙托尔神父 <圣光兄弟会>", "东瘟疫之地"}
        s["spell;created=1223760"] = {"冰川外衣", "CRAFTING"}
        s["spell;created=1223764"] = {"冰川手套", "CRAFTING"}
        s["npc;sold=16131"] = {"杀手洛汗 <血色十字军>", "东瘟疫之地"}
        s["spell;created=1214137"] = {"黑曜石觅心者", "CRAFTING"}
        s["npc;sold=16134"] = {"雷布拉特·碎地者 <陶土议会>", "东瘟疫之地"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "卡拉赞墓穴"}
        s["spell;created=1223766"] = {"冰川护腕", "CRAFTING"}
        s["spell;created=1223772"] = {"冰霜护腕", "CRAFTING"}
        s["npc;sold=16133"] = {"愤怒者玛塔乌斯 <血色十字军>", "东瘟疫之地"}
        s["spell;created=1213504"] = {"黑曜石先知之刃", "CRAFTING"}
        s["spell;created=1213527"] = {"吸血鬼风帽", "CRAFTING"}
        s["spell;created=1213530"] = {"吸血鬼披巾", "CRAFTING"}
        s["npc;sold=16112"] = {"科尔法克斯，圣光之勇士 <圣光兄弟会>", "东瘟疫之地"}
        s["spell;created=1214145"] = {"黑曜石猎枪", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "东瘟疫之地"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "塔纳利斯"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "斯坦索姆"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "斯坦索姆"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "塔纳利斯"}
    end

    function SpecBisTooltip:TranslationzhTW()
        s["npc;drop=11583"] = {"奈法利安", "黑翼之巢"}
        s["npc;drop=11502"] = {"拉格纳罗斯", "熔火之心"}
        s["npc;drop=12435"] = {"狂野的拉佐格尔", "黑翼之巢"}
        s["npc;drop=14834"] = {"哈卡", "祖尔格拉布"}
        s["spell;created=24091"] = {"血藤外套", "CRAFTING"}
        s["npc;drop=12017"] = {"勒什雷尔", "黑翼之巢"}
        s["npc;drop=11380"] = {"妖术师金度", "祖尔格拉布"}
        s["npc;drop=11983"] = {"费尔默", "黑翼之巢"}
        s["spell;created=24092"] = {"血藤护腿", "CRAFTING"}
        s["spell;created=24093"] = {"血藤长靴", "CRAFTING"}
        s["npc;drop=12098"] = {"萨弗隆先驱者", "熔火之心"}
        s["npc;drop=14601"] = {"埃博诺克", "黑翼之巢"}
        s["quest;reward=8183"] = {"哈卡之心", "荆棘谷"}
        s["npc;sold=13217"] = {"塔萨迪斯·雪光 <雷矛军需官>", "奥特兰克山脉"}
        s["npc;drop=10363"] = {"达基萨斯将军", "黑石塔"}
        s["npc;drop=10435"] = {"巴瑟拉斯镇长", "斯坦索姆"}
        s["spell;created=12622"] = {"绿色透镜", "CRAFTING"}
        s["spell;created=12092"] = {"梦纹头饰", "CRAFTING"}
        s["npc;drop=11261"] = {"瑟尔林·卡斯迪诺夫教授 <屠夫>", "通灵学院"}
        s["npc;sold=12777"] = {"戴格哈默中尉", "奥特兰克山谷"}
        s["npc;sold=12792"] = {"帕兰蒂尔", "奥特兰克山谷"}
        s["npc;drop=9018"] = {"审讯官格斯塔恩 <暮光之锤审问者>", "黑石深渊"}
        s["npc;drop=14353"] = {"米兹勒", "厄运之槌"}
        s["npc;drop=10811"] = {"档案管理员加尔福特", "斯坦索姆"}
        s["npc;drop=15727"] = {"克苏恩", "安其拉"}
        s["npc;drop=9319"] = {"驯犬者格雷布玛尔", "黑石深渊"}
        s["npc;drop=11487"] = {"卡雷迪斯镇长", "厄运之槌"}
        s["npc;sold=13218"] = {"格伦达·狼心 <霜狼军需官>", "奥特兰克山谷"}
        s["quest;reward=7861"] = {"通缉：邪恶祭司海克斯和她的爪牙", "辛特兰"}
        s["npc;drop=12118"] = {"鲁西弗隆", "熔火之心"}
        s["npc;drop=11496"] = {"伊莫塔尔", "厄运之槌"}
        s["npc;drop=11486"] = {"托塞德林王子", "厄运之槌"}
        s["npc;drop=15815"] = {"其拉上尉卡尔克", "千针石林"}
        s["npc;drop=10508"] = {"莱斯·霜语", "通灵学院"}
        s["npc;sold=14753"] = {"艾蒂尔·月火 <银翼军需官>", "灰谷"}
        s["quest;reward=8574"] = {"忠诚者的装备", "希利苏斯"}
        s["npc;drop=9017"] = {"伊森迪奥斯", "黑石深渊"}
        s["npc;drop=10516"] = {"不可宽恕者", "斯坦索姆"}
        s["npc;drop=14326"] = {"卫兵摩尔达", "厄运之槌"}
        s["npc;drop=11662"] = {"烈焰行者祭司", "熔火之心"}
        s["npc;drop=12397"] = {"卡扎克", "诅咒之地"}
        s["npc;drop=10584"] = {"乌洛克", "黑石塔"}
        s["npc;drop=14020"] = {"克洛玛古斯", "黑翼之巢"}
        s["npc;drop=9736"] = {"军需官兹格雷斯 <血斧军团>", "黑石塔"}
        s["quest;reward=8464"] = {"冬泉熊怪的活动", "冬泉谷"}
        s["npc;drop=5719"] = {"摩弗拉斯", "阿塔哈卡神庙"}
        s["spell;created=12067"] = {"梦纹手套", "CRAFTING"}
        s["npc;drop=12056"] = {"迦顿男爵", "熔火之心"}
        s["npc;drop=9030"] = {"破坏者奥科索尔", "黑石深渊"}
        s["npc;sold=13219"] = {"耶克里·弗兰迪 <霜狼军需官>", "奥特兰克山脉"}
        s["spell;created=3864"] = {"星辰腰带", "CRAFTING"}
        s["npc;drop=10437"] = {"奈鲁布恩坎", "斯坦索姆"}
        s["npc;drop=12119"] = {"烈焰行者护卫", "熔火之心"}
        s["npc;drop=9196"] = {"欧莫克大王", "黑石塔"}
        s["npc;drop=6109"] = {"艾索雷葛斯", "艾萨拉"}
        s["spell;created=23667"] = {"光芒护腿", "CRAFTING"}
        s["npc;drop=7267"] = {"乌克兹·沙顶", "祖尔法拉克"}
        s["npc;drop=8983"] = {"傀儡统帅阿格曼奇", "黑石深渊"}
        s["npc;drop=15276"] = {"维克洛尔大帝", "安其拉"}
        s["npc;drop=13280"] = {"海多斯博恩", "厄运之槌"}
        s["npc;drop=10429"] = {"大酋长雷德·黑手", "黑石塔"}
        s["npc;drop=10997"] = {"炮手威利", "斯坦索姆"}
        s["npc;drop=10812"] = {"大十字军战士达索汉", "斯坦索姆"}
        s["npc;drop=15275"] = {"维克尼拉斯大帝", "安其拉"}
        s["npc;drop=15742"] = {"亚什巨甲虫", "希利苏斯"}
        s["npc;drop=16042"] = {"瓦塔拉克公爵", "黑石塔"}
        s["quest;reward=8802"] = {"卡利姆多的救世主", "安其拉"}
        s["quest;reward=4363"] = {"语出惊人的公主", "黑石深渊"}
        s["quest;reward=4004"] = {"拯救公主？", "黑石深渊"}
        s["quest;reward=7491"] = {"万众敬仰", "奥格瑞玛"}
        s["npc;sold=14754"] = {"凯尔姆·哈古斯", "贫瘠之地"}
        s["npc;drop=11982"] = {"玛格曼达", "熔火之心"}
        s["npc;drop=10509"] = {"杰德 <黑手军团>", "黑石塔"}
        s["quest;reward=5102"] = {"达基萨斯将军之死", "燃烧平原"}
        s["npc;drop=9156"] = {"弗莱拉斯大使", "黑石深渊"}
        s["npc;sold=12782"] = {"奥尼尔上尉", "奥特兰克山谷"}
        s["npc;sold=14581"] = {"军士霍斯·雷角", "奥特兰克山谷"}
        s["npc;sold=15126"] = {"卢瑟弗·图恩 <污染者军需官>", "阿拉希高地"}
        s["npc;sold=15127"] = {"萨缪尔·霍克 <阿拉索军需官>", "阿拉希高地"}
        s["npc;drop=12057"] = {"加尔", "熔火之心"}
        s["npc;drop=12259"] = {"基赫纳斯", "熔火之心"}
        s["npc;drop=1853"] = {"黑暗院长加丁", "通灵学院"}
        s["npc;drop=10899"] = {"古拉鲁克 <黑手军团铸甲师>", "黑石塔"}
        s["npc;drop=11492"] = {"奥兹恩", "厄运之槌"}
        s["quest;reward=8790"] = {"其拉帝王徽记", "安其拉"}
        s["npc;drop=11988"] = {"焚化者古雷曼格", "熔火之心"}
        s["npc;drop=2585"] = {"激流堡仲裁者", "阿拉希高地"}
        s["quest;reward=82112"] = {"[A Better Ingredient]", "安戈洛环形山"}
        s["npc;drop=7271"] = {"巫医祖穆拉恩", "祖尔法拉克"}
        s["npc;drop=8440"] = {"哈卡的阴影", "阿塔哈卡神庙"}
        s["npc;drop=5721"] = {"德姆塞卡尔", "阿塔哈卡神庙"}
        s["object;contained=181083"] = {"[Sothos and Jarien's Heirlooms]", "斯坦索姆"}
        s["quest;reward=7784"] = {"黑石之王", "奥格瑞玛"}
        s["quest;reward=3962"] = {"结伴而行", "安戈洛环形山"}
        s["npc;drop=4543"] = {"血法师萨尔诺斯", "血色修道院"}
        s["npc;sold=227819"] = {"海达克西斯公爵", "熔火之心"}
        s["npc;drop=228435"] = {"焚化者古雷曼格", "熔火之心"}
        s["npc;sold=230319"] = {"德莉亚娜", "铁炉堡"}
        s["npc;drop=228438"] = {"[Ragnaros]", "熔火之心"}
        s["npc;drop=228432"] = {"加尔", "熔火之心"}
        s["npc;sold=227853"] = {"皮克希·希基克斯 <安德麦商人>", "荆棘谷"}
        s["spell;created=446192"] = {"黑暗神经症之膜", "CRAFTING"}
        s["npc;drop=15205"] = {"卡苏姆男爵", "希利苏斯"}
        s["spell;created=461653"] = {"闪亮的多彩披风", "CRAFTING"}
        s["npc;drop=228434"] = {"沙斯拉尔", "熔火之心"}
        s["npc;sold=222413"] = {"探险家扎尔戈 <无主货物供应商>", "荆棘谷"}
        s["quest;reward=84147"] = {"热心的建议", "铁炉堡"}
        s["npc;drop=218819"] = {"腐溃烂泥", "阿塔哈卡神庙"}
        s["spell;created=429869"] = {"虚触皮质护手", "CRAFTING"}
        s["npc;drop=220833"] = {"德姆塞卡尔", "阿塔哈卡神庙"}
        s["npc;sold=222408"] = {"影齿大使", "费伍德森林"}
        s["spell;created=461754"] = {"奥法洞察束带", "CRAFTING"}
        s["npc;drop=228433"] = {"迦顿男爵", "熔火之心"}
        s["object;contained=179703"] = {"火焰之王的宝箱", "熔火之心"}
        s["npc;drop=228429"] = {"鲁西弗隆", "熔火之心"}
        s["npc;drop=14890"] = {"泰拉尔", "暮色森林"}
        s["npc;drop=226923"] = {"晦根 <哀念守护者>", "屠魔峡谷"}
        s["npc;drop=12201"] = {"瑟莱德丝公主", "玛拉顿"}
        s["npc;drop=217280"] = {"格鲁比斯", "诺莫瑞根"}
        s["spell;created=461647"] = {"驭天者的精工风暴战锤", "CRAFTING"}
        s["npc;drop=4542"] = {"大检察官法尔班克斯", "血色修道院"}
        s["npc;drop=204068"] = {"萨利维丝", "黑暗深渊"}
        s["spell;created=12060"] = {"红色魔纹短裤", "CRAFTING"}
        s["npc;drop=213334"] = {"阿库麦尔", "黑暗深渊"}
        s["spell;created=439105"] = {"巫毒面具", "CRAFTING"}
        s["npc;drop=6490"] = {"永醒的艾希尔", "血色修道院"}
        s["spell;created=439093"] = {"深红丝质护肩", "CRAFTING"}
        s["quest;reward=82055"] = {"暗月沙丘套牌", "艾尔文森林"}
        s["quest;reward=82057"] = {"暗月瘟疫套牌", "艾尔文森林"}
        s["npc;drop=221637"] = {"加什尔", "阿塔哈卡神庙"}
        s["quest;reward=7940"] = {"1200张奖券 - 暗月宝珠", "莫高雷"}
        s["npc;drop=218721"] = {"预言者迦玛兰", "阿塔哈卡神庙"}
        s["npc;sold=11557"] = {"梅罗什", "费伍德森林"}
        s["spell;created=10621"] = {"狼头之盔", "CRAFTING"}
        s["npc;drop=9816"] = {"烈焰卫士艾博希尔", "黑石塔"}
        s["npc;drop=12467"] = {"死爪龙人队长", "黑翼之巢"}
        s["spell;created=23710"] = {"熔火腰带", "CRAFTING"}
        s["npc;drop=11981"] = {"弗莱格尔", "黑翼之巢"}
        s["npc;drop=6229"] = {"群体打击者9-60", "诺莫瑞根"}
        s["npc;drop=15206"] = {"灰烬公爵 <深渊议会>", "希利苏斯"}
        s["npc;drop=9041"] = {"典狱官斯迪尔基斯", "黑石深渊"}
        s["quest;reward=4261"] = {"远古之灵", "费伍德森林"}
        s["npc;drop=10440"] = {"瑞文戴尔男爵", "斯坦索姆"}
        s["npc;drop=15511"] = {"克里勋爵", "安其拉"}
        s["quest;reward=5068"] = {"嗜血胸甲", "冬泉谷"}
        s["npc;drop=9019"] = {"达格兰·索瑞森大帝", "黑石深渊"}
        s["npc;drop=15516"] = {"沙尔图拉", "安其拉"}
        s["spell;created=19084"] = {"魔暴龙皮手套", "CRAFTING"}
        s["npc;drop=11361"] = {"祖利安猛虎", "祖尔格拉布"}
        s["npc;drop=15323"] = {"佐拉沙行者", "安其拉废墟"}
        s["spell;created=19097"] = {"魔暴龙皮护腿", "CRAFTING"}
        s["object;contained=181366"] = {"四骑士之箱", "纳克萨玛斯"}
        s["npc;drop=10399"] = {"图萨丁侍僧", "斯坦索姆"}
        s["npc;drop=16097"] = {"伊萨莉恩", "厄运之槌"}
        s["npc;drop=8929"] = {"铁炉堡公主茉艾拉·铜须 <铁炉堡公主>", "黑石深渊"}
        s["quest;reward=7981"] = {"1200张奖券 - 暗月护符", "莫高雷"}
        s["npc;drop=15114"] = {"加兹兰卡", "祖尔格拉布"}
        s["npc;drop=15517"] = {"奥罗", "安其拉"}
        s["quest;reward=7862"] = {"职位空缺：恶齿村卫兵队长", "辛特兰"}
        s["npc;drop=9568"] = {"维姆萨拉克", "黑石塔"}
        s["quest;reward=3321"] = {"秘银会的认可", "塔纳利斯"}
        s["npc;sold=12805"] = {"埃雷恩 <杂货军需官>", "暴风城"}
        s["npc;sold=12799"] = {"巴沙 <杂货军需官>", "奥格瑞玛"}
        s["npc;drop=12463"] = {"死爪火鳞龙人", "黑翼之巢"}
        s["quest;reward=7877"] = {"辛德拉的宝藏", "厄运之槌"}
        s["npc;drop=9025"] = {"洛考尔", "黑石深渊"}
        s["npc;drop=2748"] = {"阿扎达斯", "奥达曼"}
        s["npc;drop=10503"] = {"詹迪斯·巴罗夫", "通灵学院"}
        s["spell;created=23707"] = {"熔岩腰带", "CRAFTING"}
        s["npc;drop=228022"] = {"毁灭者的幻影", "屠魔峡谷"}
        s["npc;drop=227140"] = {"派拉尼斯", "屠魔峡谷"}
        s["spell;created=460462"] = {"萨弗拉斯之眼", "CRAFTING"}
        s["npc;drop=227028"] = {"地狱咆哮的幻灵", "屠魔峡谷"}
        s["npc;drop=15204"] = {"大元帅维拉希斯", "希利苏斯"}
        s["npc;drop=218624"] = {"阿塔拉利恩 <护卫者>", "阿塔哈卡神庙"}
        s["npc;drop=228430"] = {"玛格曼达", "熔火之心"}
        s["spell;created=24123"] = {"原始蝙蝠皮护腕", "CRAFTING"}
        s["spell;created=24122"] = {"原始蝙蝠皮手套", "CRAFTING"}
        s["npc;drop=10422"] = {"红衣法术师", "斯坦索姆"}
        s["quest;reward=84561"] = {"[For All To See]", "奥格瑞玛"}
        s["quest;reward=5944"] = {"在梦中", "西瘟疫之地"}
        s["quest;reward=8949"] = {"法尔林的复仇", "厄运之槌"}
        s["npc;sold=12944"] = {"罗克图斯·暗契 <瑟银兄弟会>", "黑石深渊"}
        s["npc;drop=228436"] = {"萨弗隆先驱者", "熔火之心"}
        s["spell;created=461712"] = {"精工泰坦之锤", "CRAFTING"}
        s["spell;created=16988"] = {"泰坦之锤", "CRAFTING"}
        s["npc;drop=221943"] = {"哈扎斯", "阿塔哈卡神庙"}
        s["npc;drop=7355"] = {"图特卡什", "剃刀高地"}
        s["spell;created=461722"] = {"恶魔之核护手", "CRAFTING"}
        s["spell;created=461724"] = {"恶魔之核护腿", "CRAFTING"}
        s["quest;reward=84545"] = {"英雄的奖赏", "艾萨拉"}
        s["npc;drop=15510"] = {"顽强的范克瑞斯", "安其拉"}
        s["npc;drop=15341"] = {"拉贾克斯将军", "安其拉废墟"}
        s["npc;drop=15340"] = {"莫阿姆", "安其拉废墟"}
        s["npc;drop=10487"] = {"复活的保卫者", "通灵学院"}
        s["npc;drop=5717"] = {"米杉", "阿塔哈卡神庙"}
        s["npc;drop=15263"] = {"预言者斯克拉姆", "安其拉"}
        s["npc;drop=16449"] = {"纳克萨玛斯之魂", "纳克萨玛斯"}
        s["npc;drop=12460"] = {"黑翼龙人护卫", "黑翼之巢"}
        s["npc;drop=10430"] = {"比斯巨兽", "黑石塔"}
        s["npc;drop=10500"] = {"鬼灵教师", "通灵学院"}
        s["npc;drop=221407"] = {"梦影小鬼", "菲拉斯"}
        s["npc;drop=10220"] = {"哈雷肯", "黑石塔"}
        s["npc;drop=15990"] = {"克尔苏加德", "纳克萨玛斯"}
        s["npc;drop=12264"] = {"沙斯拉尔", "熔火之心"}
        s["npc;drop=15952"] = {"迈克斯纳", "纳克萨玛斯"}
        s["quest;reward=9120"] = {"克尔苏加德的末日", "东瘟疫之地"}
        s["spell;created=15596"] = {"浓烟山脉之心", "CRAFTING"}
        s["quest;reward=7067"] = {"贱民的指引", "凄凉之地"}
        s["quest;reward=8573"] = {"勇士的装备", "希利苏斯"}
        s["npc;drop=9547"] = {"醉酒的奴隶主", "黑石深渊"}
        s["spell;created=461690"] = {"精工移形披风", "CRAFTING"}
        s["npc;drop=230302"] = {"卡扎克", "腐烂之痕"}
        s["spell;created=435904"] = {"微光侏儒神经链接兜帽", "CRAFTING"}
        s["spell;created=23703"] = {"木喉之力", "CRAFTING"}
        s["spell;created=19080"] = {"战熊热裤", "CRAFTING"}
        s["npc;sold=10857"] = {"银色黎明军需官莱斯巴克 <银色黎明>", "西瘟疫之地"}
        s["spell;created=23705"] = {"黎明皮靴", "CRAFTING"}
        s["npc;sold=13278"] = {"海达克西斯公爵", "艾萨拉"}
        s["npc;sold=218115"] = {"迈辛 <古拉巴什兑血者>", "荆棘谷"}
        s["npc;drop=204921"] = {"格里哈斯特", "黑暗深渊"}
        s["quest;reward=80324"] = {"疯王", "铁炉堡"}
        s["npc;drop=202699"] = {"阿奎尼斯男爵", "黑暗深渊"}
        s["npc;drop=8567"] = {"暴食者", "剃刀高地"}
        s["npc;drop=220007"] = {"粘性辐射尘", "诺莫瑞根"}
        s["npc;sold=217689"] = {"“扳手”兹里·微轮 <齿轮狂人>", "诺莫瑞根"}
        s["npc;drop=201722"] = {"加摩拉", "黑暗深渊"}
        s["npc;drop=220072"] = {"电刑器6000型", "诺莫瑞根"}
        s["spell;created=429354"] = {"虚空之触皮手套", "CRAFTING"}
        s["quest;reward=824"] = {"陶土议会的耶努萨克雷", "灰谷"}
        s["quest;reward=80132"] = {"[Rig Wars]", "奥格瑞玛"}
        s["npc;drop=3669"] = {"考布莱恩", "哀嚎洞穴"}
        s["npc;drop=215728"] = {"[Crowd Pummeler 9-60]", "诺莫瑞根"}
        s["npc;drop=218537"] = {"机械师瑟玛普拉格", "诺莫瑞根"}
        s["npc;drop=4295"] = {"血色仆从", "血色修道院"}
        s["quest;reward=7541"] = {"为部落效力", "奥格瑞玛"}
        s["npc;drop=6489"] = {"铁脊死灵", "血色修道院"}
        s["quest;reward=78916"] = {"虚空之心", "达纳苏斯"}
        s["npc;drop=207356"] = {"洛古斯·杰特", "黑暗深渊"}
        s["npc;drop=7584"] = {"森林漫游者", "菲拉斯"}
        s["npc;drop=14491"] = {"科尔摩克", "荆棘谷"}
        s["npc;drop=4389"] = {"黑色蛇颈龙", "尘泥沼泽"}
        s["npc;drop=2433"] = {"赫尔库拉的遗骸", "希尔斯布莱德丘陵"}
        s["spell;created=6705"] = {"鱼人鳞片护腕", "CRAFTING"}
        s["spell;created=3779"] = {"野人腰带", "CRAFTING"}
        s["npc;drop=4845"] = {"暗炉恶棍", "荒芜之地"}
        s["quest;reward=2767"] = {"拯救OOX-22/FE！", "菲拉斯"}
        s["quest;reward=793"] = {"破碎的联盟", "荒芜之地"}
        s["spell;created=435960"] = {"超导金链腰带", "CRAFTING"}
        s["npc;drop=16118"] = {"库尔莫克", "通灵学院"}
        s["npc;drop=9033"] = {"安格弗将军", "黑石深渊"}
        s["npc;drop=12018"] = {"管理者埃克索图斯", "熔火之心"}
        s["npc;drop=15509"] = {"哈霍兰公主", "安其拉"}
        s["quest;reward=7506"] = {"翡翠梦境……", "厄运之槌"}
        s["npc;drop=15299"] = {"维希度斯", "安其拉"}
        s["npc;drop=14888"] = {"莱索恩", "暮色森林"}
        s["npc;drop=15543"] = {"亚尔基公主", "安其拉"}
        s["spell;created=22927"] = {"野性之皮", "CRAFTING"}
        s["npc;drop=11501"] = {"戈多克大王", "厄运之槌"}
        s["npc;drop=10268"] = {"奴役者基兹鲁尔", "黑石塔"}
        s["spell;created=22759"] = {"光芒护腕", "CRAFTING"}
        s["npc;drop=15339"] = {"无疤者奥斯里安", "安其拉废墟"}
        s["npc;drop=5712"] = {"祖罗", "阿塔哈卡神庙"}
        s["spell;created=23709"] = {"熔火犬皮腰带", "CRAFTING"}
        s["npc;drop=13020"] = {"堕落的瓦拉斯塔兹", "黑翼之巢"}
        s["npc;drop=11488"] = {"伊琳娜·暗木", "厄运之槌"}
        s["npc;drop=9056"] = {"弗诺斯·达克维尔 <首席建筑师>", "黑石深渊"}
        s["npc;drop=10504"] = {"阿雷克斯·巴罗夫", "通灵学院"}
        s["npc;drop=14325"] = {"克罗卡斯", "厄运之槌"}
        s["npc;drop=10809"] = {"石脊", "斯坦索姆"}
        s["quest;reward=8791"] = {"奥斯里安之死", "希利苏斯"}
        s["npc;drop=10439"] = {"吞咽者拉姆斯登", "斯坦索姆"}
        s["quest;reward=7907"] = {"暗月野兽套牌", "艾尔文森林"}
        s["object;contained=169243"] = {"七贤之箱", "黑石深渊"}
        s["npc;drop=14515"] = {"高阶祭司娅尔罗", "祖尔格拉布"}
        s["npc;drop=16080"] = {"莫尔·灰蹄", "黑石塔"}
        s["spell;created=461750"] = {"炽火月布头饰", "CRAFTING"}
        s["spell;created=23665"] = {"银色护肩", "CRAFTING"}
        s["spell;created=446189"] = {"着迷沉醉护肩", "CRAFTING"}
        s["spell;created=19061"] = {"生命护肩", "CRAFTING"}
        s["spell;created=446194"] = {"失心披肩", "CRAFTING"}
        s["npc;drop=221394"] = {"哈卡的化身", "阿塔哈卡神庙"}
        s["npc;drop=228431"] = {"基赫纳斯", "熔火之心"}
        s["npc;drop=9236"] = {"暗影猎手沃什加斯", "黑石塔"}
        s["spell;created=19435"] = {"月布长靴", "CRAFTING"}
        s["npc;drop=218571"] = {"伊兰尼库斯的阴影", "阿塔哈卡神庙"}
        s["npc;drop=10506"] = {"传令官基尔图诺斯", "通灵学院"}
        s["quest;reward=80325"] = {"[The Mad King]", "奥格瑞玛"}
        s["quest;reward=82081"] = {"破碎的仪式", "荆棘谷"}
        s["quest;reward=82058"] = {"暗月荒野套牌", "艾尔文森林"}
        s["npc;drop=226922"] = {"吉尔巴格布", "屠魔峡谷"}
        s["npc;drop=9938"] = {"玛格姆斯", "黑石深渊"}
        s["npc;drop=3977"] = {"大检察官怀特迈恩", "血色修道院"}
        s["npc;drop=14324"] = {"观察者克鲁什", "厄运之槌"}
        s["npc;drop=11661"] = {"烈焰行者", "熔火之心"}
        s["npc;drop=11673"] = {"上古熔火恶犬", "熔火之心"}
        s["quest;reward=9008"] = {"最后的奖赏", "奥格瑞玛"}
        s["quest;reward=4024"] = {"烈焰精华", "燃烧平原"}
        s["npc;drop=13276"] = {"荒野小鬼", "厄运之槌"}
        s["npc;drop=9027"] = {"修行者高罗什", "黑石深渊"}
        s["npc;drop=10264"] = {"索拉卡·火冠", "黑石塔"}
        s["quest;reward=8906"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8938"] = {"小小的补偿", "奥格瑞玛"}
        s["npc;drop=10393"] = {"斯库尔", "斯坦索姆"}
        s["npc;drop=11489"] = {"特迪斯·扭木", "厄运之槌"}
        s["npc;drop=9596"] = {"班诺克·巨斧 <火印军团勇士>", "黑石塔"}
        s["quest;reward=8952"] = {"告别安泰恩", "黑石塔"}
        s["spell;created=22922"] = {"猫鼬长靴", "CRAFTING"}
        s["quest;reward=5125"] = {"奥里克斯的清算", "斯坦索姆"}
        s["quest;reward=7503"] = {"最伟大的猎手", "厄运之槌"}
        s["quest;reward=82108"] = {"神庙中的绿龙", "阿塔哈卡神庙"}
        s["npc;drop=10438"] = {"苍白的玛勒基", "斯坦索姆"}
        s["npc;drop=221391"] = {"[Slirena] <[Harpy Queen]>", "菲拉斯"}
        s["npc;drop=15740"] = {"佐拉巨甲虫", "希利苏斯"}
        s["spell;created=462623"] = {"合成伦鲁迪洛尔", "CRAFTING"}
        s["quest;reward=82104"] = {"预言者迦玛兰", "辛特兰"}
        s["npc;drop=8908"] = {"熔岩作战傀儡", "黑石深渊"}
        s["quest;reward=84148"] = {"热心的建议", "铁炉堡"}
        s["spell;created=446237"] = {"虚空强化的屠戮者腕铠", "CRAFTING"}
        s["npc;drop=9029"] = {"剜眼者", "黑石深渊"}
        s["quest;reward=7029"] = {"维利塔恩的污染", "凄凉之地"}
        s["object;contained=179564"] = {"戈多克贡品", "厄运之槌"}
        s["npc;drop=9445"] = {"黑暗卫兵", "黑石深渊"}
        s["spell;created=23639"] = {"黑色怒火", "CRAFTING"}
        s["spell;created=461675"] = {"精炼奥金斧", "CRAFTING"}
        s["npc;drop=222573"] = {"谵妄古魂", "祖尔法拉克"}
        s["quest;reward=8272"] = {"霜狼英雄", "奥特兰克山脉"}
        s["quest;reward=3636"] = {"与圣光同在", "暴风城"}
        s["quest;reward=1364"] = {"马森的请求", "暴风城"}
        s["npc;drop=7603"] = {"麻疯助手", "诺莫瑞根"}
        s["npc;drop=2716"] = {"火烟猎龙者", "荒芜之地"}
        s["quest;reward=628"] = {"刨花皮靴", "荆棘谷"}
        s["npc;drop=6910"] = {"鲁维罗什", "奥达曼"}
        s["quest;reward=7068"] = {"暗影残片", "奥格瑞玛"}
        s["quest;reward=2822"] = {"质量的保证", "菲拉斯"}
        s["npc;drop=5860"] = {"暮光黑暗萨满祭司", "灼热峡谷"}
        s["npc;drop=13601"] = {"工匠吉兹洛克", "玛拉顿"}
        s["quest;reward=1048"] = {"深入血色修道院", "血色修道院"}
        s["spell;created=435953"] = {"抗辐射缀鳞兜帽", "CRAFTING"}
        s["spell;created=18457"] = {"大法师之袍", "CRAFTING"}
        s["quest;reward=8632"] = {"神秘头饰", "安其拉"}
        s["quest;reward=8625"] = {"神秘肩垫", "安其拉"}
        s["quest;reward=8633"] = {"神秘长袍", "安其拉"}
        s["quest;reward=8634"] = {"神秘长靴", "安其拉"}
        s["npc;drop=15236"] = {"维克尼黄蜂", "安其拉"}
        s["quest;reward=84197"] = {"[Saving the Best for Last]", "铁炉堡"}
        s["quest;reward=84157"] = {"[An Earnest Proposition]", "奥格瑞玛"}
        s["quest;reward=84549"] = {"[The Arcanist's Cookbook]", "厄运之槌"}
        s["npc;drop=11480"] = {"奥术畸兽", "厄运之槌"}
        s["quest;reward=84181"] = {"[Anthion's Parting Words]", "斯坦索姆"}
        s["npc;drop=10198"] = {"劫掠者卡苏克", "冬泉谷"}
        s["quest;reward=84165"] = {"[Just Compensation]", "铁炉堡"}
        s["spell;created=22868"] = {"地狱火手套", "CRAFTING"}
        s["npc;drop=14684"] = {"巴尔萨冯", "斯坦索姆"}
        s["quest;reward=82095"] = {"神灵哈卡", "塔纳利斯"}
        s["quest;reward=8932"] = {"小小的补偿", "铁炉堡"}
        s["npc;drop=9024"] = {"控火师罗格雷恩", "黑石深渊"}
        s["quest;reward=617"] = {"一捆海蛇草", "荆棘谷"}
        s["npc;drop=6146"] = {"峭壁击碎者", "艾萨拉"}
        s["spell;created=446236"] = {"虚空强化的祈咒者腕铠", "CRAFTING"}
        s["quest;reward=3907"] = {"不和谐的火焰", "荒芜之地"}
        s["spell;created=23663"] = {"木喉衬肩", "CRAFTING"}
        s["npc;drop=4288"] = {"血色驯兽员", "血色修道院"}
        s["npc;drop=6487"] = {"奥法师杜安", "血色修道院"}
        s["quest;reward=8366"] = {"南海复仇", "塔纳利斯"}
        s["npc;drop=14446"] = {"芬加特", "悲伤沼泽"}
        s["spell;created=16724"] = {"白魂头盔", "CRAFTING"}
        s["npc;drop=10339"] = {"盖斯 <雷德·黑手的坐骑>", "黑石塔"}
        s["spell;created=19054"] = {"红龙鳞片胸甲", "CRAFTING"}
        s["npc;drop=14321"] = {"卫兵芬古斯", "厄运之槌"}
        s["npc;drop=14861"] = {"基尔图诺斯的卫士", "通灵学院"}
        s["quest;reward=7501"] = {"圣光之力", "厄运之槌"}
        s["spell;created=446191"] = {"灾劫肩甲", "CRAFTING"}
        s["spell;created=446190"] = {"哀嚎链甲披肩", "CRAFTING"}
        s["quest;reward=84150"] = {"[An Earnest Proposition]", "铁炉堡"}
        s["npc;drop=10464"] = {"哀嚎的女妖", "斯坦索姆"}
        s["npc;drop=12203"] = {"兰斯利德", "玛拉顿"}
        s["spell;created=435906"] = {"反射性真银脑笼", "CRAFTING"}
        s["spell;created=435949"] = {"闪光超导缀鳞罩帽", "CRAFTING"}
        s["spell;created=435610"] = {"侏儒神经链接奥术丝线单片镜", "CRAFTING"}
        s["npc;drop=14686"] = {"法瑟蕾丝夫人", "剃刀高地"}
        s["npc;sold=222685"] = {"军需官基琳", "灰谷"}
        s["spell;created=20874"] = {"黑铁护腕", "CRAFTING"}
        s["spell;created=24399"] = {"黑铁长靴", "CRAFTING"}
        s["npc;sold=3144"] = {"伊崔格", "奥格瑞玛"}
        s["quest;reward=80131"] = {"[Gnome Improvement]", "铁炉堡"}
        s["npc;drop=2691"] = {"高原前锋", "辛特兰"}
        s["npc;drop=10596"] = {"烟网蛛后", "黑石塔"}
        s["spell;created=461730"] = {"加固寒冰护卫者", "CRAFTING"}
        s["spell;created=23652"] = {"黑色卫士", "CRAFTING"}
        s["spell;created=461669"] = {"精炼奥金勇士剑", "CRAFTING"}
        s["spell;created=22797"] = {"力反馈盾牌", "CRAFTING"}
        s["npc;drop=3976"] = {"血色十字军指挥官莫格莱尼", "血色修道院"}
        s["quest;reward=7065"] = {"大地的污染", "凄凉之地"}
        s["spell;created=9952"] = {"精制秘银护肩", "CRAFTING"}
        s["npc;drop=5287"] = {"长牙嚎叫者", "菲拉斯"}
        s["npc;drop=1884"] = {"血色伐木工", "西瘟疫之地"}
        s["npc;drop=14690"] = {"雷瓦克安", "厄运之槌"}
        s["npc;drop=10418"] = {"红衣卫兵", "斯坦索姆"}
        s["npc;drop=10808"] = {"悲惨的提米", "斯坦索姆"}
        s["spell;created=16729"] = {"狮心头盔", "CRAFTING"}
        s["spell;created=435908"] = {"淬火的抗干扰头盔", "CRAFTING"}
        s["spell;created=24141"] = {"黑暗之魂护肩", "CRAFTING"}
        s["npc;drop=7524"] = {"痛苦的上层精灵", "冬泉谷"}
        s["spell;created=19101"] = {"火山护肩", "CRAFTING"}
        s["spell;created=446179"] = {"恐惧惊魂肩铠", "CRAFTING"}
        s["quest;reward=5166"] = {"多彩巨龙胸甲", "西瘟疫之地"}
        s["spell;created=19076"] = {"火山胸甲", "CRAFTING"}
        s["spell;created=24139"] = {"黑暗之魂胸甲", "CRAFTING"}
        s["spell;created=446238"] = {"虚空强化的护卫者腕铠", "CRAFTING"}
        s["spell;created=23633"] = {"黎明手套", "CRAFTING"}
        s["spell;created=461671"] = {"要冲护手", "CRAFTING"}
        s["spell;created=23632"] = {"黎明束腰", "CRAFTING"}
        s["quest;reward=5081"] = {"麦克斯韦尔的任务", "黑石塔"}
        s["spell;created=19059"] = {"火山护腿", "CRAFTING"}
        s["quest;reward=84332"] = {"[A Thane's Gratitude]", "东瘟疫之地"}
        s["spell;created=461718"] = {"宁静", "CRAFTING"}
        s["spell;created=21160"] = {"萨弗拉斯之眼", "CRAFTING"}
        s["npc;drop=9039"] = {"杜姆雷尔", "黑石深渊"}
        s["npc;drop=9031"] = {"阿努希尔", "黑石深渊"}
        s["spell;created=20873"] = {"炽热链甲护肩", "CRAFTING"}
        s["npc;drop=15305"] = {"斯古恩男爵", "希利苏斯"}
        s["spell;created=461651"] = {"秘传技艺之炽热板甲护手", "CRAFTING"}
        s["spell;created=27585"] = {"重型黑曜石腰带", "CRAFTING"}
        s["spell;created=27829"] = {"泰坦护腿", "CRAFTING"}
        s["spell;created=20876"] = {"黑铁护腿", "CRAFTING"}
        s["quest;reward=8572"] = {"精兵的装备", "希利苏斯"}
        s["spell;created=12906"] = {"侏儒作战小鸡", "CRAFTING"}
        s["spell;created=460460"] = {"萨弗隆战锤", "CRAFTING"}
        s["spell;created=450409"] = {"苏萨斯的召唤", "CRAFTING"}
        s["npc;drop=8127"] = {"安图苏尔", "祖尔法拉克"}
        s["spell;created=461714"] = {"渎圣", "CRAFTING"}
        s["npc;drop=227019"] = {"搜寻者迪亚索鲁斯", "屠魔峡谷"}
        s["spell;created=16994"] = {"奥金斧", "CRAFTING"}
        s["spell;created=23151"] = {"平衡光与影", "CRAFTING"}
        s["npc;drop=14517"] = {"高阶祭司耶克里克", "祖尔格拉布"}
        s["npc;drop=15816"] = {"其拉少校赫拉雷", "千针石林"}
        s["quest;reward=9009"] = {"最后的奖赏", "奥格瑞玛"}
        s["npc;drop=11382"] = {"血领主曼多基尔", "祖尔格拉布"}
        s["spell;created=18456"] = {"信念外衣", "CRAFTING"}
        s["npc;drop=11664"] = {"烈焰行者精英", "熔火之心"}
        s["quest;reward=8909"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8940"] = {"小小的补偿", "奥格瑞玛"}
        s["npc;drop=14509"] = {"高阶祭司塞卡尔", "祖尔格拉布"}
        s["quest;reward=9019"] = {"告别安泰恩", "黑石塔"}
        s["npc;drop=14887"] = {"伊森德雷", "暮色森林"}
        s["quest;reward=7504"] = {"光明不会告诉你的事情", "厄运之槌"}
        s["quest;reward=82111"] = {"摩弗拉斯之血", "艾萨拉"}
        s["npc;drop=12459"] = {"黑翼管理者", "黑翼之巢"}
        s["object;contained=161495"] = {"秘密保险箱", "黑石深渊"}
        s["spell;created=463008"] = {"平衡光与影", "CRAFTING"}
        s["spell;created=461708"] = {"炽火月布长袍", "CRAFTING"}
        s["quest;reward=84151"] = {"热心的建议", "铁炉堡"}
        s["spell;created=461752"] = {"炽火月布护腿", "CRAFTING"}
        s["quest;reward=55"] = {"摩本特·费尔", "暮色森林"}
        s["npc;drop=4366"] = {"斯塔莎兹毒蛇守卫", "尘泥沼泽"}
        s["npc;drop=10423"] = {"红衣牧师", "斯坦索姆"}
        s["npc;drop=9818"] = {"黑手召唤师 <黑手军团>", "黑石塔"}
        s["spell;created=446193"] = {"心智破碎肩甲", "CRAFTING"}
        s["npc;drop=9219"] = {"尖石屠夫", "黑石塔"}
        s["npc;drop=223544"] = {"[Fel Interloper]", "诅咒之地"}
        s["quest;reward=9225"] = {"史诗级的作战装备 - 银色黎明崇敬", "东瘟疫之地"}
        s["npc;drop=10425"] = {"红衣战斗法师", "斯坦索姆"}
        s["npc;drop=10477"] = {"通灵学院亡灵法师", "通灵学院"}
        s["npc;drop=8923"] = {"无敌的潘佐尔", "黑石深渊"}
        s["npc;drop=10502"] = {"伊露希亚·巴罗夫", "通灵学院"}
        s["quest;reward=9221"] = {"精良的作战装备 - 银色黎明友善", "东瘟疫之地"}
        s["npc;drop=14327"] = {"蕾瑟塔蒂丝", "厄运之槌"}
        s["spell;created=18436"] = {"冬夜法袍", "CRAFTING"}
        s["npc;drop=12457"] = {"黑翼缚法者", "黑翼之巢"}
        s["quest;reward=8592"] = {"神谕者的皇冠", "安其拉"}
        s["quest;reward=8594"] = {"神谕者的衬肩", "安其拉"}
        s["spell;created=18453"] = {"恶魔布护肩", "CRAFTING"}
        s["quest;reward=8603"] = {"神谕者的外套", "安其拉"}
        s["npc;drop=15247"] = {"其拉洗脑者", "安其拉"}
        s["spell;created=22867"] = {"恶魔布手套", "CRAFTING"}
        s["npc;drop=10432"] = {"维克图斯", "通灵学院"}
        s["spell;created=23041"] = {"召唤咒逐", "CRAFTING"}
        s["npc;drop=14516"] = {"死亡骑士达克雷尔", "通灵学院"}
        s["spell;created=461962"] = {"召唤咒逐", "CRAFTING"}
        s["npc;drop=1843"] = {"工头杰瑞斯", "西瘟疫之地"}
        s["npc;drop=12801"] = {"魔法奇美洛克", "菲拉斯"}
        s["npc;drop=228914"] = {"分离的守卫者", "屠魔峡谷"}
        s["npc;drop=10119"] = {"沃尔查", "燃烧平原"}
        s["npc;drop=16154"] = {"复活的死亡骑士", "纳克萨玛斯"}
        s["npc;drop=11469"] = {"艾德雷斯怨魂", "厄运之槌"}
        s["npc;drop=14506"] = {"赫尔努拉斯", "厄运之槌"}
        s["npc;drop=14473"] = {"拉普雷斯", "希利苏斯"}
        s["npc;drop=15975"] = {"腐肉织网者", "纳克萨玛斯"}
        s["npc;drop=1838"] = {"血色质问者", "西瘟疫之地"}
        s["npc;drop=1851"] = {"哈斯克", "西瘟疫之地"}
        s["npc;drop=7104"] = {"迪塞库斯", "费伍德森林"}
        s["npc;drop=15757"] = {"其拉中将", "希利苏斯"}
        s["npc;drop=15390"] = {"库雷姆上尉", "安其拉废墟"}
        s["npc;drop=10371"] = {"狂爪队长", "黑石塔"}
        s["npc;drop=11896"] = {"淤血虫", "东瘟疫之地"}
        s["npc;drop=7459"] = {"冰蓟雪人女王", "冬泉谷"}
        s["npc;drop=10663"] = {"魔法利爪", "冬泉谷"}
        s["spell;created=18442"] = {"恶魔布帽", "CRAFTING"}
        s["npc;drop=11143"] = {"邮差马龙", "斯坦索姆"}
        s["spell;created=19794"] = {"法术能量护目镜超级改良版", "CRAFTING"}
        s["npc;drop=11622"] = {"血骨傀儡", "通灵学院"}
        s["object;contained=181074"] = {"竞技场的泥土", "黑石深渊"}
        s["spell;created=18451"] = {"恶魔布袍", "CRAFTING"}
        s["npc;drop=9817"] = {"黑手恐法师 <黑手军团>", "黑石塔"}
        s["npc;drop=10372"] = {"狂爪火舌龙人", "黑石塔"}
        s["npc;drop=11490"] = {"瑟雷姆·刺蹄", "厄运之槌"}
        s["npc;drop=10901"] = {"博学者普克尔特", "通灵学院"}
        s["npc;drop=11467"] = {"苏斯", "厄运之槌"}
        s["spell;created=18454"] = {"法术掌握手套", "CRAFTING"}
        s["spell;created=18419"] = {"恶魔布短裤", "CRAFTING"}
        s["npc;drop=10436"] = {"安娜丝塔丽男爵夫人", "斯坦索姆"}
        s["npc;drop=10558"] = {"弗雷斯特恩", "斯坦索姆"}
        s["npc;drop=9217"] = {"尖石首席法师", "黑石塔"}
        s["npc;drop=6228"] = {"黑铁大师", "诺莫瑞根"}
        s["npc;drop=6370"] = {"玛科尼快钳龙虾人", "艾萨拉"}
        s["quest;reward=9004"] = {"最后的奖赏", "铁炉堡"}
        s["quest;reward=8956"] = {"告别安泰恩", "铁炉堡"}
        s["quest;reward=8910"] = {"热心的建议", "铁炉堡"}
        s["quest;reward=8941"] = {"小小的补偿", "奥格瑞玛"}
        s["quest;reward=8639"] = {"死亡执行者的头盔", "安其拉"}
        s["quest;reward=8641"] = {"死亡执行者的护肩", "安其拉"}
        s["quest;reward=8638"] = {"死亡执行者的胸甲", "安其拉"}
        s["npc;drop=10505"] = {"讲师玛丽希亚", "通灵学院"}
        s["quest;reward=8201"] = {"祭司的头颅", "荆棘谷"}
        s["npc;drop=9265"] = {"燃棘暗影猎手", "黑石塔"}
        s["quest;reward=8640"] = {"死亡执行者的护腿", "安其拉"}
        s["quest;reward=8637"] = {"死亡执行者的长靴", "安其拉"}
        s["npc;drop=14507"] = {"高阶祭司温诺希斯", "祖尔格拉布"}
        s["quest;reward=7498"] = {"迦罗娜：潜行与诡计研究", "厄运之槌"}
        s["quest;reward=7787"] = {"觉醒吧，雷霆之怒！", "希利苏斯"}
        s["npc;drop=203138"] = {"铁怒监军", "黑石深渊"}
        s["spell;created=461237"] = {"暗影烈焰之颅", "CRAFTING"}
        s["spell;created=19090"] = {"雷暴护肩", "CRAFTING"}
        s["spell;created=19079"] = {"雷暴", "CRAFTING"}
        s["quest;reward=84152"] = {"热心的建议", "铁炉堡"}
        s["spell;created=26279"] = {"雷暴手套", "CRAFTING"}
        s["npc;drop=10318"] = {"黑手刺客 <黑手军团>", "黑石塔"}
        s["spell;created=19067"] = {"雷暴短裤", "CRAFTING"}
        s["quest;reward=84548"] = {"[Garona: A Study on Stealth and Treachery]", "厄运之槌"}
        s["npc;drop=15741"] = {"雷戈巨甲虫", "希利苏斯"}
        s["npc;drop=14222"] = {"阿拉加", "奥特兰克山脉"}
        s["quest;reward=53"] = {"琥珀酒", "西部荒野"}
        s["npc;drop=2601"] = {"弗尔伯利", "阿拉希高地"}
        s["npc;drop=2751"] = {"作战傀儡", "荒芜之地"}
        s["spell;created=9201"] = {"暗色护腕", "CRAFTING"}
        s["quest;reward=80455"] = {"[Biding Our Time]", "银松森林"}
        s["npc;drop=15209"] = {"赤红圣殿骑士 <深渊议会>", "希利苏斯"}
        s["spell;created=23706"] = {"金色黎明衬肩", "CRAFTING"}
        s["spell;created=19068"] = {"战熊背心", "CRAFTING"}
        s["npc;drop=9237"] = {"指挥官沃恩", "黑石塔"}
        s["npc;drop=15817"] = {"其拉准将帕克里斯", "希利苏斯"}
        s["quest;reward=8623"] = {"风暴召唤者的王冠", "安其拉"}
        s["quest;reward=9011"] = {"最后的奖赏", "奥格瑞玛"}
        s["quest;reward=7668"] = {"达克雷尔的威胁", "奥格瑞玛"}
        s["quest;reward=8602"] = {"风暴召唤者的肩甲", "安其拉"}
        s["spell;created=16650"] = {"野刺锁甲", "CRAFTING"}
        s["quest;reward=8622"] = {"风暴召唤者的护甲", "安其拉"}
        s["quest;reward=8918"] = {"热心的建议", "奥格瑞玛"}
        s["npc;drop=14454"] = {"烈风掠夺者", "希利苏斯"}
        s["quest;reward=8621"] = {"风暴召唤者的足甲", "安其拉"}
        s["npc;drop=11462"] = {"扭木树人", "厄运之槌"}
        s["quest;reward=7505"] = {"你与冰霜震击", "厄运之槌"}
        s["quest;reward=82113"] = {"[Da Voodoo]", "奥特兰克山脉"}
        s["spell;created=461735"] = {"无敌锁甲", "CRAFTING"}
        s["quest;reward=84160"] = {"[An Earnest Proposition]", "奥格瑞玛"}
        s["npc;drop=11043"] = {"红衣僧侣", "斯坦索姆"}
        s["spell;created=461737"] = {"风暴护手", "CRAFTING"}
        s["npc;drop=10083"] = {"狂爪火鳞龙人", "黑石塔"}
        s["npc;drop=10814"] = {"多彩精英卫士", "黑石塔"}
        s["npc;drop=14323"] = {"卫兵斯里基克", "厄运之槌"}
        s["spell;created=446186"] = {"刺耳链甲肩铠", "CRAFTING"}
        s["spell;created=451706"] = {"尖啸链甲护肩", "CRAFTING"}
        s["npc;drop=9028"] = {"格里兹尔", "黑石深渊"}
        s["spell;created=24138"] = {"血魂护手", "CRAFTING"}
        s["npc;drop=224257"] = {"阿塔莱奴隶", "阿塔哈卡神庙"}
        s["spell;created=435958"] = {"回旋真银齿轮之壁", "CRAFTING"}
        s["spell;created=19094"] = {"黑色龙鳞护肩", "CRAFTING"}
        s["spell;created=23708"] = {"多彩护手", "CRAFTING"}
        s["spell;created=19107"] = {"黑色龙鳞护腿", "CRAFTING"}
        s["spell;created=20855"] = {"黑色龙鳞战靴", "CRAFTING"}
        s["spell;created=23653"] = {"夜幕", "CRAFTING"}
        s["npc;drop=6117"] = {"上层精灵鬼巫", "艾萨拉"}
        s["spell;created=19085"] = {"黑色龙鳞胸甲", "CRAFTING"}
        s["npc;drop=10507"] = {"拉文尼亚", "通灵学院"}
        s["spell;created=16991"] = {"歼灭者", "CRAFTING"}
        s["npc;drop=12258"] = {"锐刺鞭笞者", "玛拉顿"}
        s["npc;drop=7358"] = {"寒冰之王亚门纳尔", "剃刀高地"}
        s["quest;reward=79366"] = {"[Calm Before the Storm]", "千针石林"}
        s["npc;drop=13596"] = {"洛特格里普", "玛拉顿"}
        s["quest;reward=8624"] = {"风暴召唤者的护腿", "安其拉"}
        s["quest;reward=7488"] = {"蕾瑟塔蒂丝的网", "菲拉斯"}
        s["quest;reward=5526"] = {"魔藤碎片", "月光林地"}
        s["spell;created=8770"] = {"力量法袍", "CRAFTING"}
        s["npc;drop=7357"] = {"火眼莫德雷斯", "剃刀高地"}
        s["spell;created=24356"] = {"血藤护目镜", "CRAFTING"}
        s["quest;reward=8662"] = {"厄运召唤者的头饰", "安其拉"}
        s["quest;reward=9005"] = {"最后的奖赏", "铁炉堡"}
        s["quest;reward=8664"] = {"厄运召唤者的衬肩", "安其拉"}
        s["quest;reward=8661"] = {"厄运召唤者的长袍", "安其拉"}
        s["spell;created=18458"] = {"虚空法袍", "CRAFTING"}
        s["quest;reward=8936"] = {"小小的补偿", "铁炉堡"}
        s["quest;reward=8381"] = {"军备物资", "希利苏斯"}
        s["spell;created=24201"] = {"制作黎明符文", "CRAFTING"}
        s["quest;reward=7502"] = {"束缚之影", "厄运之槌"}
        s["spell;created=461747"] = {"炽火月布外衣", "CRAFTING"}
        s["quest;reward=84153"] = {"[An Earnest Proposition]", "铁炉堡"}
        s["spell;created=23662"] = {"木喉之智", "CRAFTING"}
        s["spell;created=462282"] = {"刺绣大法师腰带", "CRAFTING"}
        s["npc;drop=15220"] = {"微风公爵", "希利苏斯"}
        s["spell;created=429351"] = {"超界蛛丝之靴", "CRAFTING"}
        s["npc;drop=15203"] = {"斯卡德诺克斯王子", "希利苏斯"}
        s["spell;created=19830"] = {"奥金幼龙", "CRAFTING"}
        s["spell;created=461743"] = {"魔法导师的贤明剑", "CRAFTING"}
        s["spell;created=20848"] = {"光芒衬肩", "CRAFTING"}
        s["npc;drop=10376"] = {"水晶之牙", "黑石塔"}
        s["npc;drop=16058"] = {"沃莉达", "黑石深渊"}
        s["spell;created=446195"] = {"错乱者肩甲", "CRAFTING"}
        s["spell;created=22870"] = {"护卫披风", "CRAFTING"}
        s["npc;drop=9439"] = {"黑暗守护者尤格尔", "黑石深渊"}
        s["spell;created=19093"] = {"奥妮克希亚鳞片披风", "CRAFTING"}
        s["spell;created=20849"] = {"光芒手套", "CRAFTING"}
        s["quest;reward=84411"] = {"[Diplomat Ring]", "奥格瑞玛"}
        s["quest;reward=5942"] = {"隐藏的宝藏", "东瘟疫之地"}
        s["npc;drop=5722"] = {"哈扎斯", "阿塔哈卡神庙"}
        s["quest;reward=1560"] = {"图加的任务", "塔纳利斯"}
        s["npc;drop=15208"] = {"碎石公爵 <深渊议会>", "希利苏斯"}
        s["spell;created=23666"] = {"光芒长袍", "CRAFTING"}
        s["quest;reward=80141"] = {"诺格的手艺", "奥格瑞玛"}
        s["quest;reward=82107"] = {"[Voodoo Feathers]", "悲伤沼泽"}
        s["npc;drop=8762"] = {"林木隐匿者", "艾萨拉"}
        s["quest;reward=3129"] = {"灵魂武器", "菲拉斯"}
        s["quest;reward=84162"] = {"热心的建议", "奥格瑞玛"}
        s["quest;reward=9006"] = {"最后的奖赏", "铁炉堡"}
        s["npc;drop=14889"] = {"艾莫莉丝", "暮色森林"}
        s["quest;reward=8561"] = {"征服者的皇冠", "安其拉"}
        s["quest;reward=8544"] = {"征服者的肩铠", "安其拉"}
        s["quest;reward=8562"] = {"征服者的胸甲", "安其拉"}
        s["quest;reward=8937"] = {"小小的补偿", "铁炉堡"}
        s["quest;reward=8560"] = {"征服者的腿铠", "安其拉"}
        s["quest;reward=8559"] = {"征服者的胫甲", "安其拉"}
        s["quest;reward=9022"] = {"告别安泰恩", "通灵学院"}
        s["quest;reward=8789"] = {"其拉帝王武器", "安其拉"}
        s["spell;created=9954"] = {"真银护手", "CRAFTING"}
        s["quest;reward=3566"] = {"奥比斯顿", "灼热峡谷"}
        s["quest;reward=84550"] = {"[Codex of Defense]", "厄运之槌"}
        s["npc;sold=231711"] = {"[Victor Nefriendius]", "黑翼之巢"}
        s["spell;created=452433"] = {"召唤格拉希尔", "CRAFTING"}
        s["npc;drop=231494"] = {"桑德兰王子 <逐风者>", "水晶谷"}
        s["quest;reward=85643"] = {"[The Lord of Blackrock]", "暴风城"}
        s["spell;created=452434"] = {"召唤莱拉阿", "CRAFTING"}
        s["npc;drop=14510"] = {"高阶祭司玛尔里", "祖尔格拉布"}
        s["npc;drop=232632"] = {"[Azgaloth] <[Lord of the Pit]>", "屠魔峡谷"}
        s["spell;created=461710"] = {"炽热之核神射手步枪", "CRAFTING"}
        s["spell;created=466117"] = {"调谐霜凌法杖", "CRAFTING"}
        s["spell;created=465417"] = {"改变姿态", "CRAFTING"}
        s["spell;created=465418"] = {"改变姿态", "CRAFTING"}
        s["npc;drop=227939"] = {"[The Molten Core]", "熔火之心"}
        s["npc;drop=15085"] = {"乌苏雷", "祖尔格拉布"}
        s["npc;drop=15083"] = {"哈扎拉尔", "祖尔格拉布"}
        s["spell;created=469201"] = {"烈焰熊燃", "CRAFTING"}
        s["spell;created=468840"] = {"组合混乱之镰", "CRAFTING"}
        s["npc;drop=15084"] = {"雷纳塔基", "祖尔格拉布"}
        s["object;contained=495500"] = {"[Shadowflame Cache]", "黑翼之巢"}
        s["spell;created=467790"] = {"组合秩序法杖", "CRAFTING"}
        s["npc;drop=16011"] = {"洛欧塞布", "纳克萨玛斯"}
        s["quest;reward=84881"] = {"[Into the Hold of Shadows]", "奥特兰克山脉"}
        s["npc;drop=10184"] = {"奥妮克希亚", "熔火之心"}
        s["quest;reward=85454"] = {"[A Just Reward]", "湿地"}
        s["npc;drop=15369"] = {"狩猎者阿亚米斯", "安其拉废墟"}
        s["quest;reward=86678"] = {"[Champion's Battlegear]", "希利苏斯"}
        s["spell;created=1216020"] = {"星象愤怒神像", "CRAFTING"}
        s["spell;created=1213538"] = {"其拉丝质披风", "CRAFTING"}
        s["npc;drop=15370"] = {"吞咽者布鲁", "安其拉废墟"}
        s["npc;drop=235197"] = {"[Taerar]", "灰谷"}
        s["npc;sold=15192"] = {"阿纳克洛斯", "塔纳利斯"}
        s["spell;created=1213595"] = {"沉睡者之泪", "CRAFTING"}
        s["spell;created=1213502"] = {"黑曜石风暴战锤", "CRAFTING"}
        s["npc;sold=15500"] = {"凯伊·迅爪", "希利苏斯"}
        s["spell;created=1216340"] = {"虚触", "CRAFTING"}
        s["spell;created=1216022"] = {"灵猫凶猛神像", "CRAFTING"}
        s["npc;drop=228230"] = {"哈里根 <黑市>", "燃烧平原"}
        s["spell;created=1213536"] = {"其拉丝质斗篷", "CRAFTING"}
        s["quest;reward=86675"] = {"[Volunteer's Battlegear]", "希利苏斯"}
        s["spell;created=23704"] = {"木喉作战手套", "CRAFTING"}
        s["quest;reward=86676"] = {"[Veteran's Battlegear]", "希利苏斯"}
        s["spell;created=1213593"] = {"神速石", "CRAFTING"}
        s["spell;created=1216385"] = {"虚触", "CRAFTING"}
        s["spell;created=1213500"] = {"黑曜石毁灭者", "CRAFTING"}
        s["spell;created=1216024"] = {"熊威宏力神像", "CRAFTING"}
        s["spell;created=24121"] = {"原始蝙蝠皮外套", "CRAFTING"}
        s["spell;created=1213738"] = {"荆木头盔", "CRAFTING"}
        s["spell;created=1213736"] = {"荆木长靴", "CRAFTING"}
        s["spell;created=1213598"] = {"报应磁石", "CRAFTING"}
        s["spell;created=1216366"] = {"虚触", "CRAFTING"}
        s["spell;created=1213521"] = {"锋芒棘刺风帽", "CRAFTING"}
        s["spell;created=1213525"] = {"锋芒棘刺皮甲", "CRAFTING"}
        s["spell;created=1213523"] = {"锋芒棘刺肩垫", "CRAFTING"}
        s["npc;drop=15348"] = {"库林纳克斯", "安其拉废墟"}
        s["npc;drop=15544"] = {"维姆", "安其拉"}
        s["spell;created=1213603"] = {"红宝石外壳胸针", "CRAFTING"}
        s["spell;created=1216319"] = {"虚触", "CRAFTING"}
        s["quest;reward=86677"] = {"[Stalwart's Battlegear]", "希利苏斯"}
        s["spell;created=1213635"] = {"魔化菌菇", "CRAFTING"}
        s["spell;created=1213540"] = {"其拉丝质披肩", "CRAFTING"}
        s["npc;drop=235232"] = {"[Ysondre]", "辛特兰"}
        s["quest;reward=86449"] = {"[Treasure of the Timeless One]", "希利苏斯"}
        s["quest;reward=86674"] = {"完美的毒药", "希利苏斯"}
        s["spell;created=1216365"] = {"虚触", "CRAFTING"}
        s["quest;reward=85559"] = {"[Night Falls]", "安戈洛环形山"}
        s["spell;created=24137"] = {"血魂护肩", "CRAFTING"}
        s["spell;created=1216384"] = {"虚触", "CRAFTING"}
        s["spell;created=1216387"] = {"虚触", "CRAFTING"}
        s["spell;created=1216327"] = {"虚触", "CRAFTING"}
        s["spell;created=466116"] = {"调谐狱火法杖", "CRAFTING"}
        s["spell;created=1213628"] = {"魔化祷言集", "CRAFTING"}
        s["quest;reward=86672"] = {"其拉帝王武器", "黑翼之巢"}
        s["spell;created=1216005"] = {"正义圣契", "CRAFTING"}
        s["spell;created=1213481"] = {"锋芒刺针头盔", "CRAFTING"}
        s["spell;created=1213484"] = {"锋芒刺针肩铠", "CRAFTING"}
        s["spell;created=1214884"] = {"虚触", "CRAFTING"}
        s["spell;created=1213588"] = {"调试的力反馈盾牌", "CRAFTING"}
        s["spell;created=1214270"] = {"碎裂黑曜石盾牌", "CRAFTING"}
        s["spell;created=1213490"] = {"锋芒刺针战铠", "CRAFTING"}
        s["spell;created=1213506"] = {"黑曜石防御者", "CRAFTING"}
        s["spell;created=1216379"] = {"虚触", "CRAFTING"}
        s["spell;created=1216007"] = {"驱魔圣契", "CRAFTING"}
        s["spell;created=1216382"] = {"虚触", "CRAFTING"}
        s["spell;created=1213534"] = {"其拉丝质头巾", "CRAFTING"}
        s["spell;created=1216375"] = {"虚触", "CRAFTING"}
        s["spell;created=1213492"] = {"黑曜石掠夺者", "CRAFTING"}
        s["spell;created=1216377"] = {"虚触", "CRAFTING"}
        s["spell;created=1213498"] = {"黑曜石圣剑", "CRAFTING"}
        s["quest;reward=86671"] = {"其拉帝王徽记", "黑翼之巢"}
        s["npc;drop=234880"] = {"[Emeriss]", "暮色森林"}
        s["spell;created=1216354"] = {"虚触", "CRAFTING"}
        s["spell;created=1216014"] = {"火岩惊雷图腾", "CRAFTING"}
        s["spell;created=1213742"] = {"林栖者头冠", "CRAFTING"}
        s["spell;created=1213740"] = {"林栖者护肩", "CRAFTING"}
        s["spell;created=28210"] = {"盖亚的拥抱", "CRAFTING"}
        s["spell;created=1213744"] = {"林栖者外套", "CRAFTING"}
        s["spell;created=1214306"] = {"梦幻龙鳞护腕", "CRAFTING"}
        s["spell;created=1214307"] = {"梦幻龙鳞手套", "CRAFTING"}
        s["npc;drop=235180"] = {"[Lethon]", "菲拉斯"}
        s["quest;reward=9248"] = {"谦卑的馈赠", "希利苏斯"}
        s["quest;reward=86442"] = {"[Nefarius's Corruption]", "黑翼之巢"}
        s["spell;created=1213532"] = {"吸血鬼长袍", "CRAFTING"}
        s["object;contained=495503"] = {"[Chromatic Hoard]", "黑翼之巢"}
        s["spell;created=1216372"] = {"虚触", "CRAFTING"}
        s["quest;reward=86673"] = {"[The Fall of Ossirian]", "希利苏斯"}
        s["quest;reward=86670"] = {"[The Savior of Kalimdor]", "安其拉"}
        s["quest;reward=86760"] = {"暗月野兽套牌", "艾尔文森林"}
        s["quest;reward=86762"] = {"暗月元素套牌", "艾尔文森林"}
        s["quest;reward=86680"] = {"[Waking Legends]", "月光林地"}
        s["spell;created=1214303"] = {"梦幻龙鳞褶裙", "CRAFTING"}
        s["quest;reward=85063"] = {"[Culmination]", "冬泉谷"}
        s["npc;drop=3975"] = {"赫洛德 <血色十字军勇士>", "血色修道院"}
        s["spell;created=1216364"] = {"虚触", "CRAFTING"}
        s["spell;created=1213633"] = {"魔化图腾", "CRAFTING"}
        s["spell;created=1216381"] = {"虚触", "CRAFTING"}
        s["npc;sold=16135"] = {"莱茵 <塞纳里奥议会>", "东瘟疫之地"}
        s["npc;drop=16061"] = {"教官拉苏维奥斯", "纳克萨玛斯"}
        s["quest;reward=87360"] = {"克尔苏加德的末日", "东瘟疫之地"}
        s["npc;drop=237964"] = {"[Harbinger of Sin]", "卡拉赞墓穴"}
        s["npc;drop=16143"] = {"末日之影", "诅咒之地"}
        s["npc;drop=16380"] = {"骨巫", "燃烧平原"}
        s["quest;reward=87438"] = {"银色黎明皮甲手套", "东瘟疫之地"}
        s["npc;drop=238233"] = {"[Kaigy Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["quest;reward=88723"] = {"[Superior Armaments of Battle - Revered Amongst the Dawn]", "东瘟疫之地"}
        s["npc;drop=16060"] = {"收割者戈提克", "纳克萨玛斯"}
        s["npc;drop=15936"] = {"肮脏的希尔盖", "纳克萨玛斯"}
        s["npc;drop=15931"] = {"格罗布鲁斯", "纳克萨玛斯"}
        s["npc;drop=15932"] = {"格拉斯", "纳克萨玛斯"}
        s["npc;drop=15989"] = {"萨菲隆", "纳克萨玛斯"}
        s["npc;drop=14697"] = {"笨拙的憎恶", "燃烧平原"}
        s["npc;drop=237439"] = {"[Kharon]", "卡拉赞墓穴"}
        s["quest;reward=87440"] = {"银色黎明布甲手套", "东瘟疫之地"}
        s["npc;drop=15928"] = {"塔迪乌斯", "纳克萨玛斯"}
        s["npc;drop=15953"] = {"黑女巫法琳娜", "纳克萨玛斯"}
        s["npc;drop=15956"] = {"阿努布雷坎", "纳克萨玛斯"}
        s["npc;drop=15954"] = {"瘟疫使者诺斯", "纳克萨玛斯"}
        s["npc;drop=238234"] = {"[Barian Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["npc;drop=238024"] = {"[Creeping Malison]", "卡拉赞墓穴"}
        s["spell;created=1223762"] = {"冰川披风", "CRAFTING"}
        s["npc;drop=16028"] = {"帕奇维克", "纳克萨玛斯"}
        s["npc;drop=238055"] = {"[Dark Rider]", "卡拉赞墓穴"}
        s["npc;drop=238560"] = {"[The Warden]", "卡拉赞墓穴"}
        s["npc;drop=238638"] = {"[Echo of the Baroness]", "卡拉赞墓穴"}
        s["spell;created=24179"] = {"制造黎明徽记", "CRAFTING"}
        s["npc;drop=238213"] = {"[Sairuh Maryla] <[The Failed Apprentice]>", "卡拉赞墓穴"}
        s["quest;reward=88728"] = {"[Epic Armaments of Battle - Exalted Amongst the Dawn]", "东瘟疫之地"}
        s["npc;drop=238511"] = {"[The Gravekeeper]", "卡拉赞墓穴"}
        s["npc;drop=16379"] = {"诅咒者之魂", "燃烧平原"}
        s["npc;sold=16132"] = {"猎手雷奥普德 <血色十字军>", "东瘟疫之地"}
        s["quest;reward=87435"] = {"[Argent Dawn Mail Gloves]", "东瘟疫之地"}
        s["npc;sold=16116"] = {"大法师安吉拉·杜萨图斯 <圣光兄弟会>", "东瘟疫之地"}
        s["npc;sold=16115"] = {"指挥官埃里戈尔·黎明使者 <圣光兄弟会>", "东瘟疫之地"}
        s["quest;reward=87434"] = {"银色黎明板甲手套", "东瘟疫之地"}
        s["spell;created=1223787"] = {"破冰胸甲", "CRAFTING"}
        s["spell;created=1223791"] = {"破冰护腕", "CRAFTING"}
        s["spell;created=1223789"] = {"破冰护手", "CRAFTING"}
        s["quest;reward=88730"] = {"[The Only Song I Know...]", "东瘟疫之地"}
        s["spell;created=1223780"] = {"北极外套", "CRAFTING"}
        s["spell;created=1223784"] = {"北极护腕", "CRAFTING"}
        s["spell;created=1223782"] = {"北极手套", "CRAFTING"}
        s["quest;reward=86445"] = {"[The Wrath of Neptulon]", "塔纳利斯"}
        s["npc;sold=16113"] = {"英尼戈·蒙托尔神父 <圣光兄弟会>", "东瘟疫之地"}
        s["spell;created=1223760"] = {"冰川外衣", "CRAFTING"}
        s["spell;created=1223764"] = {"冰川手套", "CRAFTING"}
        s["npc;sold=16131"] = {"杀手洛汗 <血色十字军>", "东瘟疫之地"}
        s["spell;created=1214137"] = {"黑曜石觅心者", "CRAFTING"}
        s["npc;sold=16134"] = {"雷布拉特·碎地者 <陶土议会>", "东瘟疫之地"}
        s["npc;drop=238678"] = {"[Unk'omon] <[The Winged Sorrow]>", "卡拉赞墓穴"}
        s["spell;created=1223766"] = {"冰川护腕", "CRAFTING"}
        s["spell;created=1223772"] = {"冰霜护腕", "CRAFTING"}
        s["npc;sold=16133"] = {"愤怒者玛塔乌斯 <血色十字军>", "东瘟疫之地"}
        s["spell;created=1213504"] = {"黑曜石先知之刃", "CRAFTING"}
        s["spell;created=1213527"] = {"吸血鬼风帽", "CRAFTING"}
        s["spell;created=1213530"] = {"吸血鬼披巾", "CRAFTING"}
        s["npc;sold=16112"] = {"科尔法克斯，圣光之勇士 <圣光兄弟会>", "东瘟疫之地"}
        s["spell;created=1214145"] = {"黑曜石猎枪", "CRAFTING"}
        s["quest;reward=88729"] = {"[Ramaladni's Icy Grasp]", "东瘟疫之地"}
        s["quest;reward=87443"] = {"[Atiesh, Greatstaff of the Guardian]", "塔纳利斯"}
        s["quest;reward=87442"] = {"[Atiesh, Greatstaff of the Guardian]", "斯坦索姆"}
        s["quest;reward=87441"] = {"[Atiesh, Greatstaff of the Guardian]", "斯坦索姆"}
        s["quest;reward=87444"] = {"[Atiesh, Greatstaff of the Guardian]", "塔纳利斯"}
    end
end
