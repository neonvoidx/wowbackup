DungeonJournal 2.0.3

CHANGES IN 2.0.3
- Dungeon Tracker on solo runs and grey mobs: the tracker now starts with
  the first kill of any mob, grey ones included. Inside a dungeon the game
  hides which mob died, and Forever has no "<mob> dies" chat lines at all, so
  a kill without XP used to go uncounted (and a solo run with only grey mobs
  never started). The kill event itself still says your group landed the
  killing blow, and that is now counted. A mob that also gives XP, or a boss,
  is still counted once.
- Dungeon Tracker after stepping out: a kill on a grey mob was thrown away
  at the next loading screen, so a run that had only those looked empty and
  the next trip outside deleted it (tracker gone, "/dj tracker" said it
  starts with the first kill). Those kills are kept now.
- Dungeon Tracker outside the dungeon (corpse run, vendor): the timer showed
  0:00 until you went back in. It keeps counting now.
- Dungeon Tracker reset button, right after the dungeon's name (the game's
  own refresh button, as on the Looking For Group panel). It asks first,
  then ends the run; the tracker stays on screen at 0 (time, XP, gold) with
  every boss alive, and the next kill starts the new run. /dj reset does the
  same. Use it when your group leader resets the dungeon: only the player
  who resets gets the game's "has been reset" line, so only their own run
  ends by itself.
- Options > Dungeon Tracker > Hide Tracker (at the top): closing the tracker
  with its X ticks it, and the tracker stays hidden for that run until
  "/dj tracker" (or Track on screen in the Character Logs) unticks it, or you
  untick it there. A new run unticks it by itself and the tracker works as
  usual. For players who missed the "/dj tracker" note.
- New installs: after the New Dungeon Tracker note, a second note with a
  yellow arrow points at the tracker's bosses: "Right-click bosses to see
  loot on tracker" (once per account, until OK or a boss is right-clicked).
- Not finished runs (reset, left, ended) show their time in the Character
  Logs instead of "-".
- Tracker boss portraits: the tooltip shows just the boss's name until it's
  killed (no more "not killed" and "Click: target it." lines), plus
  "Right-click to show loot": a right-click opens a line of the boss's loot
  right under its portrait (hover an item for its tooltip); right-click the
  boss again to close it, or keep the mouse off the tracker and the line for
  2 seconds. Left-click still targets the boss. At most 5 items to a row.
  Rares too (found or not): right-click shows their loot.
  Shift-click an item there to link it in chat. Patterns shared by several bosses are left out (patterns only
  that boss drops, and epic ones, are shown), and a quest item no longer
  shows once you have done its quest (repeatable quests like The Medallion
  of Faith keep theirs). The boss whose loot is open glows like the journal's
  emblems.
- Right-click > Hide on the Sleeping Bag and Character Logs icons (and
  Disable on the LFG eye) now opens Options at that line, highlighted: tick
  it there, so you know where to turn it back on.
- Tracker Options menu (right-click the tracker): opens right on the
  cursor and goes away as soon as the mouse leaves it.
- New shortcuts: /dj alcaz, /dj bmh (Blackmaw Hold), /dj krol, /dj shaper,
  /dj dc (The Drowned City).
- /dj tracker inside a dungeon now also shows how many kills, XP lines and
  boss kills the game reported this session (for bug reports).
- The "New Dungeon Tracker" note only shows on a new install (until you click
  OK). Updating the addon no longer shows it.
- Stratholme Living: Malor the Zealous now shows his Forever loot (Scarlet
  Malice, Plate of the Scarlet Bastion) next to the Medallion of Faith.
- Krol'dok Stronghold: Mugg's Crosser is now confirmed Overlord Mugg loot
  (drop confirmed by Meteora), no longer "probable".
- Dungeon names in every language for the nine Forever dungeons (Hall of
  Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The
  Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's
  Terrace), from Wowhead Forever's localized zone names. The last five had
  none yet. Italian shows these nine in English (there is no Italian client).
  Quest texts and quest giver lines use the new names too.
- Dungeon names for the 26 Classic dungeons and wings in German, French,
  Spanish, Portuguese, Russian, Korean and both Chinese, as the game client
  names them: e.g. Schwarzfelstiefen, Profondeurs de Rochenoire, Templo de
  Atal'Hakkar (Sunken Temple), Stratholme - Haupttor / Dienstboteneingang
  (Living / Undead), Düsterbruch - Ost. Portuguese Razorfen Kraul is now
  Urzal dos Tuscos (it had the Razorfen Downs name). Italian keeps its names.
  The world map's Scarlet Monastery wing buttons still show only the wing.
- Alcaz Prison loot: every boss now has its full loot, each item checked on
  Wowhead Forever as dropped by that boss. New: Katerina's Shanker, Zarla's
  Snack Pouch and Beastbond Robe. Grips of Control, Tidesong Wand and
  Cutthroat Chestguard have their real item IDs. Cloak of the Tidemistress,
  Sentimental Locket (Katerina) and Defias Enforcer's Legguards (Blazeroar)
  are confirmed. Blazeroar was empty. Quest items: Ca'zass's Head, Ornate
  Shackle Key and Zarla's Journal (hidden on the tracker once their quests
  are done). Trash: Defias Enforcer's Mask confirmed, Compound Gloves (cloth,
  from Defias Truthfinder) added, the Chest still probable.
- Old Fire-Eye (undead paladin): the chain now starts where the game starts
  it, with the six quests before The Debt: Diplomatic Incident (Danitha Morr,
  Bandarion Keep, Tirisfal Glades), A Curious Pair, A Grim Fate, Into Fenris
  Keep, Lumina Windsinger and The Windshaper's Wrath (reported on Discord by
  belpickle and xperl73).
- Scarlet Monastery Library: the mage quest Rituals of Power, with Hidden
  Secrets and Get the Scoop as its chain (reported on Discord by Phoen1x).
- Zul'Farrak: the mage quest A Lesson in Literacy (Farraki Papyrus from the
  zombies of the graves); the giver is your faction's: Garion Wendell in
  Stormwind or Owen Thadd in Undercity (reported on Discord by Vakos and
  Phoen1x). Clicking the quill or the resin marks where they drop on the map,
  as does the Fenris Isle Key on its Old Fire-Eye step.
- Shadowfang Keep: Blueprint: Tanning Rack from Razorclaw the Butcher
  (reported on Discord by KramS).
- Zul'Farrak: Mutilator from Dustwraith, Hydra Leather Legs from Gahz'rilla,
  Gutcutter Hatchet from Nekrum Gutchewer.
- Krol'dok Stronghold: Stretched Footpads in the trash drops, with the mobs
  that drop them (Twilight Grunt, Twilight Lieutenant, Redridge Prisoner).
- Alcaz Prison trash drops now name the mobs each piece drops from, with
  their portraits (Defias Enforcer's Prowlers and Mask, Compound Gloves).
- Dungeon Tracker, The Deadmines: Sneed's Shredder now counts as killed
  when Sneed dies (he comes out of it). On characters that get no XP from
  it, the Shredder stayed "not killed", so the run never completed
  (reported on Discord by Panda).
- Dungeon Tracker, Blackrock Depths: the Ring of Law is one entry (only one
  challenger comes per run). It shows the challenger once you target or kill
  it, and counts as killed when the fight ends. Princess Moira is no longer
  needed to complete a run (she can be saved); she shows up on the tracker
  only if she is killed.
- Dungeon Tracker, Dire Maul: West: Lord Hel'nurath (summoned by warlocks for
  their Dreadsteed) is no longer on the tracker and no longer needed, so a
  run now completes at Prince Tortheldrin. He stays in the journal.
- The Drowned City: Sword of Dismemberment in the trash drops (Risen Sentry,
  Champion of the Deep, Brinescale Sorceress, Makrura Snapper); Linken's
  Boots of Iron as shared loot of every boss (and the rare Gill); Umbral
  Scaled Belt (Umbra) and Viscera Spaulders (Deathless Marrow) confirmed.
- Zul'Farrak: Ruuzlu is a boss of his own now, right before Chief Ukorz
  Sandscalp, with his own loot (Sandfury Guillotine, Peacekeeper Wand). On
  the Dungeon Tracker he is counted with the Chief's fight when his own death
  can't be seen (no XP at a high level). Sandarr Dunereaver's loot added
  (Sandarr's Shoulders, Bloodsand Belt).
- Blackmaw Hold: Octofinger Gauntlets added to the Tunnelweb Matriarch.
- Shaper's Terrace: Heartflame Gauntlets added to Vitrix's and Cinder's
  loot, Crownroar Chestplate to Snowtalon's (seen in Loot Rolls from them).
- Trash drop pages with mob portraits (Krol'dok Stronghold, Ruins of
  Lordaeron, Alcaz Prison) get the Compact view button too when the list is
  too long; compact rows leave the portraits out, the item's tooltip still
  names the mobs.
- Loot pages always open in the detailed view. Compact View is one click on
  the "N items" line, and it is remembered for that page only.
- The Cozy Sleeping Bag's quest page no longer has the < > dungeon arrows
  beside the Dungeons button (it isn't a dungeon).
- The Deadmines, Toxic Soil (Alliance): the journal entry is now Destruction
  in Deadmines, the quest you do inside the dungeon (plant the explosives at
  the forge), with the nine quests before it as its chain; "You have it"
  shows on it (reported on Discord by oriol600). The last step, using the
  detonator at the exit, is no longer listed.
- Maraudon, Shadowshard Fragments (Alliance): Show on Map pointed near
  Brackenwall Village; Archmage Tervosh is in the tower on Theramore Isle
  (reported on Discord by Nyby).
- Shaper's Terrace: all six quests. New for the Alliance: Panic at the
  Digsite, Mapping the Way Forward and Digestible Research. The Horde's The
  Dark Crystal and Essence of Seeping Slimes now have their real quest IDs,
  XP and reputation; Crystalline Elements, The Dark Crystal, Essence of
  Seeping Slimes and Panic at the Digsite can be shared. Who gives them
  (except Mayena Earthseeker) is not known yet.
- Quest titles use the game client's own title on non-English clients
  (Italian excluded), and the verified localization data
  (Localization/Content_Verified.lua, see LOCALIZATION-AUDIT.md) is included.
- Dungeon Tracker on non-English clients (reported on Discord by Krixx and
  Trinii, German client):
  - Bosses are matched by the game's encounter ID, the same number on every
    language, for all Classic and Forever dungeons. A boss kill counts even
    where the journal has no translation of its name, and the boss learns its
    local name (no more extra grey skulls for the same boss).
  - The Drowned City and Krol'dok Stronghold are recognised by their instance
    ID ("Die Versunkene Stadt" was not), so their runs complete.
  - Runs saved without their dungeon are fixed when you go back in.
  - German names for the three bosses with no encounter event (Obsidian
    Sentinel, Spirestone Battle Lord, Spirestone Lord Magus).
- Dungeon Tracker after a reset:
  - A boss that dies again after you left and came back means the dungeon
    was reset (for example by the group leader, whose reset message the rest
    of the group doesn't get): the old run ends and a new one starts.
  - A run whose bosses are all down is no longer resumed when you go back in.
- Boss and dungeon names from your own game client: on a non-English client
  the journal asks the game for every boss's and dungeon's name at login and
  uses those (also for the new Forever dungeons and bosses that had no
  translation). The tracker matches kills by them too.
- /dj tracker inside a dungeon before the first kill now says the tracker
  starts with the first kill.
- Stratholme Living: Malor the Zealous added after Timmy the Cruel (optional;
  Medallion of Faith from Malor's Strongbox).
  Postmaster Malown is optional too: Living runs never counted as complete
  unless he was summoned.
- Dungeon Tracker in Scarlet Monastery, Dire Maul, Stratholme and Blackrock
  Spire (reported on Discord by Leiv): after a corpse run, /reload or relog
  the tracker stayed hidden and /dj tracker said there was no run until the
  next kill. Coming back in now continues the run's wing.


CHANGES IN 2.0.37
- Razorfen Kraul: the level 20 Warrior armor chains were missing.
  - Alliance: Furen's Armor (Fire Hardened Hauberk). Steps: The Rethban
    Gauntlet, The Shieldsmith, Fire Hardened Mail.
  - Horde: Brutal Hauberk. Steps: Trial at the Field of Giants, Speak with
    Thun'grim, Brutal Armor.
  - Fire Hardened Mail and Brutal Armor need the Vial of Phlogiston from
    Roogug; every other material is listed with where it drops.
  - The optional follow-up pieces (Coif/Helm, Gauntlets, Leggings/
    Legguards) are shown under the note.
  - Roogug's loot shows the Vial of Phlogiston (quest item).

CHANGES IN 2.0.36
- Razorfen Kraul: the Shaman weapon chain (reported on Discord by
  kAldown: Elemental Aid was missing).
  - New Shaman entry The Tempest's Weapons (Alliance and Horde), like the
    other class chains: Elemental Aid is its Razorfen Kraul step, then
    Storm, Earth, and Fire (20 Twisted Totems; the Horde also has Eyes on
    the Sky) and the elite Heed My Call ritual in Thousand Needles.
  - Rewards: Rage of the Storm, Lightning's Grasp or Tidebringer's Claw;
    Alliance Shamans also get Elementalist's Guard.
  - Charlga Razorflank's loot shows the Tattered Note (quest item).
  - The Horde quest givers after the dungeon aren't confirmed yet; the
    entry says to follow the quest log.

CHANGES IN 2.0.35
- Dungeon Tracker on solo runs (reported on Discord by Zanth, Ragefire
  Chasm): the tracker only appeared at the first boss. Inside Forever
  dungeons the game hides what a mob is, so a trash kill counted only when
  it gave XP. Overlevelled or level-capped players get no XP, and their
  trash kills were ignored.
  - A trash death during a fight (yours or your party's, or up to 3 seconds
    after it ends) now counts, so the tracker starts on the first trash kill.
  - Common critters (rats, roaches, beetles, snakes...) still don't count.

CHANGES IN 2.0.34
- Blackrock Depths: Theldren is marked "0.5 Quest Event", like Lord
  Valthalak in Upper Blackrock Spire.

CHANGES IN 2.0.33
- Dungeon Tracker on non-English clients (reported on Discord, City of
  Dalaran in German): bosses killed under their German names showed up a
  second time as unknown skulls, and the run could never be completed.
  - German names added for 19 bosses of the Forever dungeons.
  - Bosses are also matched by their name in the game's own language: the
    one seen on the boss, and the one in the Encounter Journal (matched by
    model, so it works in every language).
  - Runs already recorded are repaired at login: the bosses get their
    journal names and a run with every boss down counts as completed.
  - As a last resort, a run completes once as many unknown-named boss kills
    as bosses still open are recorded.

CHANGES IN 2.0.32
- Blackmaw Hold quests checked against Forever's official list:
  - New: The Twin Bears (Lorekeeper Nok, Ursolan), Blackmaw Reclamation
    (Varrox Bleakhoof's head for Gatekeeper Rageroar, Ursolan), and the
    repeatable Feeding Time! and Blackmaw Pouches.
  - Blackmaw Pouches: its real quest ID, both factions, Timbermaw +150.
  - A Lost Memento: 11,300 XP.
- Sunken Temple:
  - Into the Depths and Secret of the Circle now start with The Sunken
    Temple (Angelas Moonbreeze for the Alliance, Witch Doctor Uzer'i for the
    Horde, both in Feralas), then The Stone Circle.
  - XP corrected to WoW Forever's values for every quest and chain step,
    class quests included (most showed Classic's, about half).

CHANGES IN 2.0.31
- Blackrock Depths: new Forever quest Fragment of the Firelands (Horde,
  Alaana Stormwalker on Skywatcher Plateau, Mulgore; 14,800 XP, 85s,
  Cenarion Circle +300). Reported by Snax on Discord.
- Blackrock Depths: The Challenge added (Banner of Provocation, Theldren),
  with its chain: Anthion's Old Friend, Falrin's Vendetta, The Instigator's
  Enchantment.
- Blackrock Depths: quest XP corrected to WoW Forever's values for every
  quest and chain step (most showed Classic's, about half).

CHANGES IN 2.0.30
- Blackrock Depths loot completed:
  - Lord Incendius: Incendic Bracers. Phalanx: Rockfist. Ambassador
    Flamelash: Circle of Flame. Emperor Dagran Thaurissan: Ironfoe.
  - The Seven (Chest of The Seven): The Hammer of Grace, Ghostshroud and
    Haunting Specter Leggings.
  - New: Theldren (Ring of Law, summoned with the Banner of Provocation;
    not on the Dungeon Tracker) with his and the Arena Spoils' loot.
  - New: Secret Safe (Black Vault, after Watchman Doomgrip) with its four
    items.
  - New: Trash Drops with the 13 Blackrock Depths zone drops.
- Maraudon: checked, nothing missing (the extra items some sites list are
  random world drops).

CHANGES IN 2.0.29
- Data Rescue: the punch card steps say "Obtain" instead of "Starts at".
- Dungeon Tracker: when the group resets a dungeon ("<Dungeon> has been
  reset."), an unfinished run of it ends and its tracker goes away. Corpse
  runs and vendor trips still continue the same run.
- Dungeon Tracker: entering a dungeon no longer shows another dungeon's
  unfinished run (wrong title and bosses) until the first kill.
- Dungeon Tracker, Stratholme: the run and its tracker now start with the
  first Crimson (Living) or Black Guard / Acolyte / Crypt / Bile Spewer /
  Venom Belcher (Undead) kill; before, only a boss kill or an English room
  name started them.

CHANGES IN 2.0.28
- Blackmaw Hold: Blackmaw Chain Belt added to Blackmaw Behemoth's loot.
- Blackrock Depths: Ribbly Screwspigot now also lists Wayfarer's Knapsack,
  Ribbly's Quiver and Ribbly's Bandolier.

CHANGES IN 2.0.27
- Gnomeregan, Data Rescue: the punch cards are no longer shown as a quest
  chain you need first. You take Data Rescue straight from Master Mechanic
  Castpipe; the cards are how you complete it.
  - Quest list: a small red Guide button replaces the chain icon and opens
    the punch card steps under the quest, as before.
  - Quest page: a How to complete button at the top replaces "Requires a
    quest chain first." and Show Quest Chain. It opens the step you are on
    (with a Yellow Punch Card in your bags it opens the Blue card step).
  - Step pages say "Guide: step 2 of 5" instead of "Required prerequisite".
  - Any quest can be switched to this in Data/QuestChains.lua with
    FDJ.QUEST_GUIDE_CHAINS[questID] = true.


CHANGES IN 2.0.26
- Uldaman and Zul'Farrak: every quest and chain step that asks for items now
  shows them as item cards with the count and where to get them (for
  example Lore for a Price: Silver Bar ×5).
- Scarab Shells: red note that Tran'rek must be handed in first if it is in
  your quest log, or you can't accept Scarab Shells (not even shared).

CHANGES IN 2.0.25
- Uldaman: the necklace quests now end where the game ends them:
  - Alliance: Restoring the Necklace (Talvash del Kissel) gives Talvash's
    Enhancing Necklace; the earlier steps are in its chain.
  - Horde: Deliver the Gems and Necklace Recovery, Take 3 added; Jarkal
    Mossmeld gives Jarkal's Enhancing Necklace at the end.
- Uldaman: The Platinum Discs (Alliance) ends with Dinita Stonemantle in the
  Vault of Ironforge, who gives the potion / Thawpelt Sack choice.
- Uldaman and Zul'Farrak: quest XP corrected to WoW Forever's values (most
  pay about twice their Classic XP).

CHANGES IN 2.0.24
- Razorfen Downs: new quest Agamaggan's Blood (Kog'thug the Brave, Bristleback
  Retreat in Shen'dralas), the end of Rot and Regret's chain, with how to get
  the blood (click a Cauldron of Agamaggan's Blood in the tents).
- Razorfen Downs: quest XP corrected to WoW Forever's values (A Host of Evil
  8,200, Extinguishing the Idol 10,100, Bring the End 9,050, Bring the Light
  10,200, An Unholy Alliance 7,350, The Coldbringer's Eye 8,600).
- Bring the End / Bring the Light: Vanquisher's Sword added to the reward
  choices, plus Undercity / Stormwind reputation. An Unholy Alliance:
  Cultist's Chestguard added to the reward choices.
- The Coldbringer's Eye (Alliance): real quest ID, level 41 (from 34), and
  Archmage Lan'dalock's exact spot at the Violet Hold entrance.

CHANGES IN 2.0.23
- Maraudon: Rot and Regret now shows how to unlock it. The Shen'dralas pylon
  quests (Strange Pylons, Fragments of the Pylons, Powering the Pylons, A
  Brief History Lesson, Meeting the Magister) open the area; Mithera then
  gives Word of the Woods, which leads to Woodwyrd. Every step has its NPC,
  map spot and tips.
- Rot and Regret: where the Vial of Earth Song Water is (the pools Rotgrip
  swims in) and how to finish it (use it on the burning tree next to
  Woodwyrd).
- Maraudon: quest XP corrected to WoW Forever's values (about twice the
  Classic amounts), plus Darkspear Trolls and Cenarion Circle reputation.

CHANGES IN 2.0.22
- Alcaz Prison: every quest now has its quest giver and real quest ID.
  - Horde: Eitrigg (Grommash Hold) > Nazeer Bloodspike (Brackenwall Village)
    > Sergeant Ulka on Alcaz Island, who gives No Orc Left Behind, A Little
    Payback and Blood Red Bandanas. Thrall Needs to Know shows the whole chain.
  - A Little Payback: given and taken back by Sergeant Ulka; its three
    reward choices added.
  - New Alliance quests: Somber News (with The Secret Prison in its chain)
    and A Bit of Wet Work, from Mathias Shaw (SI:7) and Sully McCleary in
    Theramore, with the Jaina disguise step explained.
  - New for both factions: More Valuable Than Gold (free Mason Connery with
    The Questioner's key, then find his treasure in Moonbrook). Warning:
    don't kill The Questioner before the last boss.
  - The Dragon's Journal: Archmage Lan'dalock at the Violet Hold entrance
    (15.4, 73.8) gives it and takes it back.
  - XP corrected to the current values.
- Krol'dok Stronghold (Horde): Show Them How It's Done added at the start of
  the chains (players' report).

CHANGES IN 2.0.21
- Quest item cards now show how many you need after the item's name (for
  example Key Ingredients: Thick Leather ×4, Iron Bar ×12).
- Krol'dok Stronghold:
  - Key Ingredients (both factions): red note at the top, "The key from this
    quest unlocks the upper side of the dungeon."
  - Alliance Eye of Mugg has its full chain: Scraps of Knowledge, The Western
    Front, No Soldier Left Behind, Carving a Path, Bring Me His Head, News to
    Farholde (then Demar Brant offers Eye of Mugg).
  - Twilight Mementos chain now starts with Saving Sunnyglade and goes
    through Sergeant Riftan's quests before Bring Me His Head.
  - Horde chains start with Encroaching Twilight and Clugfist's Decree; real
    givers and spots for The Wayward Warrior, Carving a Path, Rise Up! and
    It Is Time, Brother....
  - Map spots corrected: Demar Brant (66.6, 81.0), Tran'gul (59.4, 44.0),
    Sergeant Riftan (30.6, 49.0).

CHANGES IN 2.0.20
- Krol'dok Stronghold quests, checked against Wowhead Forever and players'
  reports on Discord:
  - Horde: Tome of Twilight comes from Tran'gul at Rog'mar and A Token of
    Vengeance from Da'grosh at the Twilight's Shroud. All three Horde dungeon
    quests now show their chain (The Wayward Warrior, Break Their Chains,
    Carving a Path, Rise Up!, Bring Me His Head; then It Is Time, Brother...
    for Eye of Mugg and Tome of Twilight).
  - Alliance: Sergeant Riftan gives and takes Twilight Mementos and gives
    Lingering Essence; Curios of Curiosity is confirmed as the last step and
    ends at Melanie Sable in Farholde Keep. Ashe Amberhall's spot is marked.
  - Key quests: the Krol'dok Moulding drops from Tunk, at the forge beside
    War Handler Ashka; Alphonse Dumas and Kreza Darkthorn are marked.
  - Quest XP set to the current values (Eye of Mugg 11,500, Tome of Twilight
    11,050, Twilight Mementos 10,200, A Token of Vengeance 8,200, Vengeance
    of the Highborne 11,500); Zalfan Moonshadow's whereabouts in the notes.
- Alcaz Prison: The Dragon's Journal starts from Archmage Lan'dalock at the
  Violet Hold entrance in Dalaran.

CHANGES IN 2.0.19
- Zul'Farrak: added Sandfury Pauldrons (item 274638) to Theka the Martyr's
  normal boss loot alongside Sacrificial Chain Vest.

CHANGES IN 2.0.18
- Dungeon Tracker / Character Logs: The Drowned City (and other newer dungeons)
  is recognised again, so the tracker lists all its bosses, not only the ones
  killed. Runs already recorded there get their dungeon back too.

CHANGES IN 2.0.17
- Blackrock Depths: fixed missing boss levels for all 26 boss entries.
- Lower Blackrock Spire: fixed missing boss levels for all 15 boss entries;
  aligned seven old level values with published Classic Era references.
- Upper Blackrock Spire: fixed missing boss levels for all 9 boss entries.
- Cause: three boss-level tables accidentally used the same Blackrock Depths
  dictionary key; LBRS/UBRS now have their own dungeon keys.
- No loot, quests, portraits, boss order, or other dungeons changed.
- Boss-level references are from Classic-era tables published on Forever
  reference sites; live Forever changes may differ.


CHANGES IN 2.0.16
- Alcaz Prison: Overseer Wrex now has a boss portrait. The boss entry uses
  NPC ID 255391 and creature display ID 7914 from Wowhead Forever. Both the
  list portrait and the boss-detail portrait use the existing live portrait
  renderer; no changes to loot or other bosses.

INSTALLATION
Exit WoW, then extract this ZIP so
Interface/AddOns/ForeverDungeonJournal/ForeverDungeonJournal.toc exists.
It replaces the previous version in the same folder.

SETTINGS
The addon folder, keybinding and saved-variable names are unchanged, so existing
preferences carry over. Character progress is read from the game.
Command: /dj.

CHANGES IN 2.0.5
- Blackmaw Hold: Plans: Breastplate of Salvation now appears in the separate
  Recipes & Patterns tab, sourced from Trash Drops. It is no longer displayed
  on the normal Trash Drops loot page.
- The recipe tab now collects recipes from trash pages as well as bosses and
  shows their source. Recipe search can also resolve trash-only recipes.

CHANGES IN 2.0.4
- Scholomance / Kirtonos the Herald: completed the nine-piece boss-specific
  loot list from https://www.wowhead.com/forever/npc=10506/kirtonos-the-herald.
- Added Stoneform Shoulders (#13955), Clutch of Andros (#13956), and
  Gravestone War Axe (#13983). The other six Kirtonos loot entries were
  already present and remain unchanged.
- Excluded generic world BoE drops, materials, and other non-boss-specific
  entries from the NPC's much larger aggregate drop list.
- Source caveat: the Forever loot table may change; in-game tooltips take
  precedence over older Classic item stats.

CHANGES IN 2.0.3
- Blackmaw Hold trash: Plans: Breastplate of Salvation (Blacksmithing 300),
  Grove Subjugator's Blade, and Tormented Cuffs. The plans are listed in
  the dungeon-wide Recipes & Patterns tab (source: Trash Drops).
- Blackmaw Hold bosses: Apprentice's Protective Treads (Gortek),
  Horns of Varrox (Varrox Bleakhoof), Cowl of Dark Ambition (Unbound Spirit).
- Removed Feathered Charm Necklace from the dungeon Trash Drops page pending
  drop-source confirmation. It remains the starting item for A Lost Memento
  on the Quests tab; the quest and its reward are unchanged.

CHANGES IN 2.0.2
- Blackmaw Hold: Den Champion's Binding (trash), Cloak of the Fleshborer
  (Withermaw), and Tuskblade Halberd (Bonesnout the Unbroken).
- Blackmaw Hold: level 55 rare elite Tunnelweb Matriarch with its
  Tunnelweb Pincer dagger.
- Blackmaw Hold: A Lost Memento, an item-start quest from Feathered Charm
  Necklace, with Nama's Cherished Necklace as the reward. Quest item also
  was initially in Trash Drops (removed in 2.0.3 pending drop verification).
  Exact loot mob, quest turn-in NPC, and quest level (provisional 57) await verification.

CHANGES IN 2.0.1
- City of Dalaran: Starving Arcane shows level 30, like An Alarming Request,
  the quest that must be done before it.

CHANGES IN 2.0
- The Drowned City: Serpentbane Crown confirmed for Min'loth the Serpent.
- Developer test commands removed.
- Character Logs: a Party button next to the dungeon name lists who did the
  run, in class colours (runs recorded from now on).
- Character Logs: run dates follow the game clock's settings (12/24-hour,
  realm or local time); English shows e.g. Nov 9  9:01 PM.
- Character Logs: Trash killed is now a plain count instead of a percentage.
- Character Logs: hovering an item no longer compares it with your gear;
  hold Shift to compare.
- /dj export: compressed FDJ3 character snapshots for permanent website links,
  including quest/RPG progress and the latest 100 Character Logs.
- Razorfen Downs: The Coldbringer's Eye (Horde) is given and taken back
  by Sutara Plainstalker, Skywatcher Plateau, Mulgore (map pin added).
- The first time the Dungeon Tracker shows up, a note with an arrow points
  at it: New Dungeon Tracker, "Right Click" to disable. It stays until OK
  is clicked; until then, right-clicking the note or the tracker opens
  Options > Dungeon Tracker with Never track dungeons highlighted.
- New Options page "RPG Mode": Enable (same switch as RPG Mode on the
  Dungeon list page), Hide Quest Achievement Popups, Hide Boss
  Achievement Popups, Mute Achievements, and an Achievement Popup sound
  slider (now 15% quieter by default: 85%).
- Blackfathom Deeps (Alliance): once Blackfathom Villainy is handed in
  without In Search of Thaelrid done, Thaelrid can't be done any more. It then no
  longer counts towards the dungeon's quests (so the dungeon can still show
  as completed), and its row is greyed out: "Unavailable, read quest
  warning" (still clickable).
- The first time you click the WoW Forever emblem (only Forever dungeons
  shown), a note with an arrow points at it: Switch back to full view.
- Quest items a boss drops (An Unsent Letter from Edwin VanCleef, and the
  like) now say where: "Looted from Edwin VanCleef, The Deadmines". Clicking
  the item opens that boss's loot with the item glowing (3 seconds, or until
  you hover it).
- The Drowned City: new Trash Drops page with Risen Sentry's Links (Legs,
  Mail), dropped by the Risen Sentry, shown with its portrait.
- Wailing Caverns: Lord Serpentis drops the Blueprint: Journeyman Campfire.
- The Drowned City: new level 38 rare, Umbra (a murloc), with Deep-Dweller's Grips as a
  confirmed drop (it was listed as a probable drop from Gill).
- Blackmaw Hold: new level 55 rare, Gortek the Apprentice, who drops Fist of
  Revelation. Elder Shaman Bloodmane drops Bloody Claws of Attack, and the
  Unbound Spirit drops the Flamebreak Talisman.
- Show Location: the entrance button now works for Krol'dok Stronghold,
  Alcaz Prison, Blackmaw Hold and Shaper's Terrace.
- No more "found the item ID of ..." lines in chat: the journal still learns
  item IDs on its own, silently (/dj newids lists them). Five learned IDs
  are now built in.
- Razorfen Downs: Plaguemaw the Rotting's loot is listed (Swine Fists,
  Plaguerot Sprig, and the new Decaying Flesh Bands).
- Razorfen Downs: Plaguemaw the Rotting is not a rare: he comes at the end of
  Extinguishing the Idol. He is listed after Tuten'kash, and his page says
  "Spawns at the end of ? Extinguishing the Idol" (click it for the quest).
- Krol'dok Stronghold: Slavecrusher Grox drops the Blueprint: Expert Campfire.
- Razorfen Downs: Ragglesnout's loot is listed (X'caliboar, Savage Boar's
  Guard, Boar Champion's Belt, Plans: Sentinel's Boots).
- Zul'Farrak: Witch Doctor Zum'rah also drops Jumanza Grips.
- More loot: Avenger's Armor (Razorfen Kraul trash); The Rockpounder and
  Stoneslayer (Archaedas, whose Archaedic Stone now shows "Random
  enchantment"); Blade of the Wretched and Eater of the Dead (Ogom the
  Wretched); Chloromesh Girdle and Brusslehide Leggings (Razorlash); Blade of
  Eternal Darkness (Princess Theradras).
- Sliverblade is listed with the Scarlet Monastery trash drops (very rare).
- The Looking For Group eye now finds The Stockade ("Stormwind Stockades" in
  the group list) and other dungeons whose list name differs a little.
- The Drowned City: Gill is level 38, and the Tidebound Dagger is a confirmed
  drop from Gill (it was listed as a probable drop).
- Krol'dok Stronghold: Bossman Toof drops the Band of Bossman (Finger).
- The Stockade: Kam Deepfury drops the Pattern: Trapper's Leather Helm.
- Krol'dok Stronghold: Nar'gurk drops the Krol'dok Warplate Helmet (it was a
  probable trash drop).
- The Drowned City: new level 38 rare elite, "Pyromancer" Braxton, with the
  Pyromancer's Baton (seen dropping) and the Flamestarter's Signet; both were
  listed as Gill's probable loot.
- The Drowned City: the Umbral Scaled Belt is now Umbra's probable loot
  (it was Gill's).
- Stratholme: Baroness Anastari drops Wail of the Banshee.
- Stratholme: Undead: Magistrate Barthilas is listed after Maleki the Pallid.
- Krol'dok Stronghold: War Handler Ashka is level 43, and War Handler's Gaze
  is a confirmed drop from him (it was listed as probable).
- Zul'Farrak: Dustwraith drops the Desertwalker Cane; Chief Ukorz Sandscalp
  also drops Ripsaw, Embrace of the Lycan and Jang'thraze the Protector;
  Antu'sul also drops the Lifeblood Amulet and Sang'thraze the Deflector.
- Zul'Farrak: Ruuzlu is no longer listed as a boss of his own (he is fought
  together with Chief Ukorz Sandscalp). In the Character Logs that fight
  counts as done once both of them are dead.
- New: Character Logs. Your character's portrait left of Favourites on the
  main page (or /dj log) opens a log of this character's dungeon runs, recorded on their
  own. Each run shows its time (first trash kill to last boss kill), deaths,
  how much of the trash was killed, the XP from mobs, every boss (killed or
  not) and every kind of trash killed with the XP it gave, the items you
  pressed Need on (won or lost), and the time spent outside. A run is one
  copy of the dungeon: a corpse run after releasing, or stepping out to a
  vendor and coming back, carries on the same run; a reset dungeon starts a
  new one. The red X on a run deletes it (after asking).
  While a run is going, "Track on screen" shows its time, XP and bosses in a
  small window you can drag anywhere by its top; bosses are shown by portrait, greyed
  out with an X once killed (the log's boss list uses the same portraits).
  Hover a killed boss (on screen or in the log) to see what it dropped and
  who got it, with the dice (Need) or coin (Greed) and the number they rolled.
  Won Need rolls in the log show the dice and your roll too.
  Each run's page has its dungeon's card art faintly behind it.
  Time outside: a Death Walk (released spirit, ghost run back) shows the
  Spirit Healer's portrait; Stepped out is a trip out alive.
  Right-click the portrait icon to hide it (Options: Hide Character Logs
  icon brings it back; /dj log still opens the log).
  The on-screen tracker has a size grip in its bottom right corner
  (right-click it for 100%).
  A run counts as completed (and its clock stops) only once every boss is
  dead, not just the last one; rares and bosses that need a quest or a
  summoning item to appear don't count.
  The tracker also opens by itself when you enter a dungeon in a group
  (close it with its X for that run). It shows the dungeon's rares too:
  faded until found; one found alive glows gold with a soft chime (at once,
  then 4, 8, 16... seconds apart). Click a rare's portrait to target it and
  mark it with a skull (that also stops the glow and the chime).
  Click a boss's portrait on the tracker to target it (no mark).
  At the level cap (no XP to earn), the tracker and the log show the gold
  and silver the run earned instead of the mobs' XP; below it the tracker
  shows Time, Mobs XP and Gold side by side. Each run's page shows the
  money it earned at the top right (gold and silver, or silver and copper
  below one gold).
  The tracker can always be moved, in combat too (the portraits' click
  areas catch up once the fight is over).
  Options > Dungeon Tracker: Never track dungeons (the tracker no longer
  opens by itself), Show Tracker for solo runs too, Hide Time, Hide Mobs XP, Hide Gold, Hide Bosses (and rares). Right-click the
  tracker for a menu with Options that opens that page.

CHANGES IN 1.7.4
- Quest tracker: in an opened quest chain, a step ready to hand in (Lost
  Relic Carry in Prehistoric Prism) shows the round ? after its name, like
  the other quests, instead of the small ? in front of it.
- Excavation Site: Wetlands map: the Highland Horror (Horrors in the
  Highland) is on the map, north of the Lost Dig Site, with the game's
  quest badge (the yellow !) on its portrait to show it is a quest target.
  Clicking it opens the quest.
- Dungeon maps: a quest spot shows ? when it is where a quest in your log is
  handed in or done, even if another quest also starts there (Daewyn
  Songblade in the Excavation Site: Wetlands). A spot with nothing for you
  right now (quests not taken yet, or already taken or done) is greyed out.
  Clicking a spot opens the quest in your log. The pins update as you take
  or hand in quests.
- The Stockade, The Color of Blood: Nikova Raskol's map pin is in Old Town
  (it was Classic's spot, north of Old Town on Forever's Stormwind map).
  She walks around, so the map shows her path as a loop, drawn like the
  travel routes, and her pin walks along it (it stops under the mouse).
  Pins for NPCs that walk around can now show their path this way.
- Boss loot is grouped by rarity (epic, rare, uncommon, common), with
  materials such as the Maker's Spark always at the bottom.
- No more small stutter a second after turning in a quest: the home page's
  dungeon cards were rebuilt even with the journal closed. They are now
  rebuilt only when the home page is on screen.
- Shaper's Terrace: the Talon of Tor'Rel is a confirmed drop from Izha'Rel
  and Tor'Rel (it was listed as a probable drop).
- Search bar: no more lag while typing (for example "dm w"). The search
  asked the game again for every item it had not loaded yet on each key
  press, and every answer ran the whole search again. Each item is now asked
  for once, and item answers redraw the journal once per burst. Results also
  show a little sooner after the last key.
- The Drowned City: the Dreadfrost Saber is a confirmed drop from Captain
  Dreadrise (it was listed as a probable drop).
- Summon items (Tome of Dalaran, Mallet of Zul'Farrak): the tooltip always
  shows the whole "How to get it" text. On the first hover the game was
  still loading the item and rebuilt the tooltip without it.
- "Summon with:" and the item name are written in the quest list's font.
- The Mallet of Zul'Farrak page has Bosses and Map buttons: they lead back
  to Zul'Farrak (Bosses opens on Gahz'rilla).
- Zul'Farrak: Gahz'rilla's page says "Summon with:" and the Mallet of
  Zul'Farrak (the real item, its tooltip saying "Click to show quest"); a
  click opens the mallet's quest chain. It replaces the red button. ("Summoned
  by:" reads "Summon with:" for Lyn the Ignored too.)
- Quest chain steps ready to hand in show the round ? in the chain list and
  in the quest tracker (after the step's name): a click shows where to hand
  it in.
- Quest tracker: the chain step under a quest shows its number ("1. The
  Greenwarden"). Clicking a turn-in ? also targets and marks the NPC when
  you are near, like Show on Map.
- Quest list: "Available from Level X" is shorter in French ("Ã€ partir du
  niveau"), Spanish, Portuguese and Italian, so it fits on one line and the
  chain and In Dungeon icons sit as in English, clear of the faction icons. A step's page shows "Show Turn In" whenever the turn-in NPC's spot
  is known (e.g. The Greenwarden: Rethiel in the Green Belt).
- Wailing Caverns map: the full original cave (from before patch 4.1 cut the
  eastern maze) instead of the game's cut-down map; Lord Pythas and Skum
  moved to their rooms in the east.
- Required and provided item cards on quest pages sit two to a row, like the
  rewards, instead of one under the other.
- Arrows either side of the Dungeons button go to the previous / next
  dungeon (in the home page's order) on the same page: Bosses, Quests or Map.
  They stop at the first and last dungeon (greyed out there).
- The Drowned City: Priestess Cloak drops from Var'Taka (not Primeval
  Elemental as guessed); Heart of the Primeval (Primeval Elemental) and Maw
  of Min'loth (Min'loth the Serpent) are confirmed drops now.
- The Drowned City: Knucklebone Ring drops from Deathless Marrow (it was
  guessed for Primeval Elemental).
- The Drowned City (Horde): A Tale Spun Around the Fire, Kin'weelay's
  follow-up (take the etchings to Master Gadrin in Sen'jin Village), is the
  quest's entry now, with The Drowned City as a step in its chain; its three
  reward choices are shown.
- Shaper's Terrace: Nanaya added as the last boss (Leggings of Curation,
  Maker's Spark). New drops: Titanosaur Scale Pendant (Titanosaur, with a
  "Can drop 2 items" note under his name), Spiderchitin Wrap (Venomridge),
  Dinofrill Casque (Thunderhoof), Tooth of the Matriarch (Direhorn
  Matriarch), and Shaper's Robe as a trash drop.
- Shaper's Terrace: Izha'Rel and Tor'Rel, two raptors fought together (not
  elite), added before Nanaya: Raptorscale Bulwark, Frostfang Mail Vest
  (Talon of Tor'Rel probable). Legplates of Reinforced Crystal confirmed from
  Nanaya.
- Zul'Farrak: Horde quest Zum'rah's Head (Mazu'kon, Skywatcher Plateau,
  Mulgore); The Witch Doctor's Head (Alliance) has its real quest ID now.
- Dire Maul West: Illyanna Ravenoak now after Magister Kalendris; Lord
  Hel'nurath says he is summoned by the Warlock epic mount quest.
  Tendris Warpwood drops Stoneflower Staff.
- Dire Maul East: Pusillin added as the first boss (Obsidian Bauble, Recipe:
  Runn Tum Tuber Surprise). Fervent Helm shows "<Random enchantment>" like on
  Wowhead (it drops as "of Frost Resistance" and so on). Venomvessel Ring (Venomridge), Nanaya's Control Spire (Nanaya).
  Real item IDs for the Shaper's Terrace drops (tooltips from the game now),
  and the rest of the dungeon's item batch listed as probable drops.
- Quest chains: a step done (even partly) inside the dungeon shows the In
  Dungeon icon after its Objective: its objective names the dungeon, or one
  of its items comes from there (e.g. Destruction in Deadmines, The Test of
  Righteousness, The Drowned City's rubbings).
- Alcaz Prison: Alliance quest The Dragon's Journal (Zarla's Journal from
  Blazeroar; starts in Dalaran, giver not known yet).
- Krol'dok Stronghold: the key quests for both factions (Krol'dok Moulding,
  then Key Ingredients for the Krol'dok Compound Key); Scraps of Knowledge
  and Curious Trinkets before A Small Favor in the Alliance Tome of Twilight
  chain; Bring Me His Head, Twilight Mementos, Lingering Essence and
  (probably) Curios of Curiosity as one Alliance chain.
- Blackmaw Hold quests: Get to the Roots of It (both factions, after
  Beneath Nordrassil), Blackmaw Magic (both factions; givers not known yet)
  and Claws That Rend, Tusks that Gore (Ogtinc, Azshara).
- Blackmaw Hold: Blackmaw Pouches (Ekkal, Ruins of Eldarath). Shaper's
  Terrace: Crystalline Elements (Mayena Earthseeker, Mulgore), Essence of
  Seeping Slimes and The Dark Crystal (givers not known yet), with their
  rewards. Seen by Horde players.
- Rewards (XP, money, reputation, items) for the new Blackmaw Hold, Alcaz
  and Krol'dok quests, from Wowhead Forever. Quests the server sends no data
  for now show their stored XP after a few seconds instead of nothing.
- Blackmaw Hold: Impaan the Imprisoner drops Flameslash Crescent. Boss list
  now starts Impaan, Bonesnout, Moontouched Wanderer. New drops: Lunarlight
  Robe (Moontouched Wanderer), Shamanic Wristguards (Elder Shaman Bloodmane),
  Trousers of the Ebon Giant (Blackmaw Behemoth), Scalding Flamehoof (Varrox
  Bleakhoof).
- Razorfen Downs: Glutton drops Abomination Chain and Plans: Justicar's
  Boots.
- Shaper's Terrace is open: its page has six bosses (Titanosaur,
  Venomridge, Thunderhoof, Direhorn Matriarch, Bolt, Vitrix; the order is
  not confirmed yet), their levels and the drops seen so far: Deeproar Cord
  and Gargantuan Wristguards (Titanosaur), Octoclaw Chain Boots
  (Venomridge), Deep Jungle Rifle (Thunderhoof), Scaleguard Scimitar
  (Direhorn Matriarch), Bolt's Charged Eyeball (Bolt). New card art (its
  loading screen).
- Zul'Farrak: a "How to get the Mallet" button on Gahz'rilla's boss page,
  under his name beside the portrait, opens the Mallet of Zul'Farrak chain: loot the Sacred Mallet from
  Qiaga the Keeper (Altar of Zul), then use it at the altar on top of
  Jintha'Alor (both in The Hinterlands). Each step has Show on Map and is
  ticked once you hold its item.
- Blackmaw Hold: Varrox Bleakhoof is the final boss (now last in the
  list). New drops: Veilpiercer Girdle (Elder Shaman Bloodmane), Behemoth
  Bones (Blackmaw Behemoth), Burnished Pridescales (Unbound Spirit), Bleak
  Eye Shoulderplates (Varrox Bleakhoof). Elder Shaman Bloodmane, Blackmaw
  Behemoth and Unbound Spirit are level 59.
- The Drowned City: Bloodslash Axe is a confirmed drop from Zul'Alai.
- Krol'dok Stronghold: Strongly Scented Hood drops from Overlord Mugg;
  Mugg's Crosser is listed as his probable drop.
- Blackfathom Deeps (Alliance): Blackfathom Villainy no longer says
  "Requires: In Search of Thaelrid" (Argent Guard Thaelrid gives it without
  it). In Search of Thaelrid warns in red above its Objective: if it is not
  handed in before you accept Blackfathom Villainy, it becomes unavailable.
  Blackfathom Villainy warns too: accept it after completing In Search of
  Thaelrid, or you will lose that quest.

CHANGES IN 1.7.3
- New option "Forever Dungeons Only" (Options > Dungeon List, off by
  default): the same switch as the WoW Forever emblem at the top left of the
  dungeon list. If the list only shows the Forever dungeons, untick it (or
  click the emblem again) to see every dungeon.
- Alcaz Prison and Blackmaw Hold: their Quests tab says "Full Quests TBD",
  and a faction with no quests listed yet reads "No Alliance quests known
  for this dungeon yet" (they are new and their quests are still being
  found).
- Alcaz Prison is open:
  - Its page has the five bosses in order (Overseer Wrex, The Questioner,
    Tidemistress Ca'zass, Katerina the Cleaner, Blazeroar), their levels,
    the drops seen so far and probable drops, a map with the entrance, and
    new card art (its loading screen).
  - Loot seen dropping: Grips of Control and Wrex's Pinky Ring (Overseer
    Wrex), Girdle of Extracted Answers, Fingerbreaker Stamp and Defias
    Enforcer's Shoulderpads (The Questioner), Tidesong Wand and Seascale
    Bracers (Tidemistress Ca'zass), Cutthroat Chestguard (Katerina the
    Cleaner), Defias Enforcer's Prowlers (trash). The Garb's Mask and Chest
    are listed as probable trash drops.
  - Horde quests: Thrall Needs to Know with its chain (No Orc Left Behind
    from Sergeant Ulka outside the prison, The Honor of the Kor'kron and Bad
    News for Folkar with Commander Folkar inside), handed in to Thrall for
    Fatebound Buckler, Courier's Clasp or Dustwallow Dirk. Blood Red
    Bandanas (8 from the Defias guards, to Eitrigg in Orgrimmar). A Little
    Payback (level 53: 15 Strashaz Soldiers, 8 Strashaz Enchantresses and
    Ca'zass's Head; who gives it is not known yet). Their quest IDs are not
    public yet: the journal learns them when you take the quests.
- Blackmaw Hold is open: its page has the seven bosses in order (Withermaw,
  Impaan the Imprisoner, Elder Shaman Bloodmane, Bonesnout the Unbroken,
  Varrox Bleakhoof, Blackmaw Behemoth, Unbound Spirit), the levels seen so
  far and the drops seen so far (Withering Grips, Impish Chain Hood, Lucky
  Shovelnose Tuft). The rare Moontouched Wanderer drops Claymore of Two
  Moons; Satyr's Touch is a trash drop from the Legashi Ritualists. New card
  art (its loading screen).
- Boss portraits of The Drowned City, Krol'dok Stronghold, Alcaz Prison and
  Blackmaw Hold no longer stay question marks: they are drawn at login with
  the other dungeons' (including Overseer Wrex, whose NPC ID is now known).
- The Drowned City:
  - New map, with the Eternal Amphitheater and the Abyssal Dais named.
  - Alliance quests are chains now: Findings for the Explorer's League and
    The Web of Magic show the whole chain. The Second Rebellion and Bad
    Medicine (Sergeant Yohwa, done together), Kurzen's Mystery, Troll
    Witchery, An Acquaintance in Southshore (Brother Nimetz, Rebel Camp),
    then Take Two With Water or Magics of the Drowned City (Loremaster
    Dibbs, Southshore), handed in to Historian Karnik in Ironforge or Abra
    Cadabra in Dalaran. Each step has its givers on the map; Kurzen's
    Mystery marks the four troll tablets.
  - Ancient Gurubashi Secrets is given by Archmage Timear, outside where the
    Violet Hold stood in Dalaran. Shady Saltseers and The Saltseer Captain:
    Krazek in Booty Bay.
  - Horde: The Only Good Brinescale... and Enemies in the Water are given
    and handed in by Commander Aggro'gosh at Grom'gol. Its chain shows the
    way there: The Vile Reef, The Gurubashi Legends of Old, Enemies in the
    Water, then Locating the Lost City.
  - Robe of the Drowned (Primeval Elemental), Harpoon of Command (Var'Taka)
    and Oathbound Bracers (Zul'Alai) are confirmed drops now.
- Krol'dok Stronghold:
  - Loot: Mugg's Jabber (Overlord Mugg), Krol'dok Warplate Chest (Nar'gurk),
    Slavecrusher Scepter (Slavecrusher Grox) and Bloodied Gutslicer (War
    Handler Ashka). Emblem of Slamming, Chain of Binding and Chain of the
    Corruptor now have their item IDs (real tooltips).
  - Vengeance of the Highborne is given and handed in by Ranath Nightstride,
    in the inn in Dalaran.
- City of Dalaran: Guardian's Emblem, from Fragmented Sentries (trash).
- Razorfen Downs: Coldbringer Spine (staff) drops from Amnennar the
  Coldbringer. The Coldbringer's Eye for the Horde (who gives it is not
  known yet); the Alliance one is confirmed from Archmage Lan'dalock in
  Dalaran.
- The Deadmines: Destruction in Deadmines now lists the storyline's final
  quest (use the detonator) with the dungeon step (plant the explosives at
  the forge) as step 10 of its chain, instead of the dungeon step repeating
  itself inside its own chain. Alba Fairmoon waits at the Deadmines exit for
  both Destruction in Deadmines quests (not at the Sentinel Hill inn).
- Gnomeregan: Rig Wars is listed as a quest of its own (it stays the first
  step of Gnomer-gooooone!), and its pin on the dungeon map opens Rig Wars.
  In Gnomer-gooooone!'s chain it reads "Rig Wars (accept only)": it only
  has to be in your quest log for Sovik to offer Chief Engineer Scooty.
- Scarlet Monastery: Into The Scarlet Monastery and In the Name of the Light
  are listed in the Library too (Houndmaster Loksey is one of their kills),
  not only in the Armory and the Cathedral.
- The Glowing Shard: the objective reads "0/1 Speak with Sputtervalve in
  Ratchet" (then "1/1 ...", greyed, once you have spoken to him), with a
  Show on Map button under it that marks Sputtervalve by the flight master
  in Ratchet. Falla Sagewind is still where it is handed in.
- Quests:
  - The turn-in ? (quest list, quest page, quest tracker) works for every
    quest whose hand-in place is known. NPCs in the world have their spots
    (Darnassus, Ironforge, Moonglade, Felwood, Azshara, Winterspring, Tarren
    Mill, Blackrock Mountain, Riverglades, Skywatcher Plateau...); quests
    handed in inside a dungeon open its map on the right level with the ? on
    the NPC or object; inside Lower/Upper Blackrock Spire and Scholomance
    (no map page yet), the dungeon's entrance on the world map. Detonation
    at a Distance is handed in to Jasper Fel (SI:7).
  - A quest ready to hand in shows only the big ? and "Turn in" in the quest
    list; the chain, In Dungeon, class and faction icons come back with the
    green tick once handed in.
  - Lead-in quests that end inside a dungeon work like In Search of Thaelrid
    > Blackfathom Villainy: the lead-in is its own entry with "Leads to" in
    its Notes, and the next quest starts inside the dungeon with "Requires:
    <lead-in>" and a button back to it. Songblade Search > Fallen in the Fen
    and Lost in the Thicket Things > Heartwoven (Excavation Site: Wetlands),
    Searching for the Lost Satchel > Returning the Lost Satchel (Ragefire
    Chasm), Operative Bijou > Bijou's Belongings (Lower Blackrock Spire),
    Legends of Maraudon > The Scepter of Celebras (Maraudon).
  - Quest tracker: clicking a ? or ! marks the NPC on the map and, when you
    are close, targets them too. The ! of a chain you have not started
    points to where its first step is picked up.
- Maps:
  - World map: a turn-in spot marked from the journal (Show Turn In, the
    tracker's ?) shows the game's own yellow ? quest button, bigger, instead
    of the X; quest givers keep the X. A pin you put on the map for a quest
    clears itself: a quest giver's once you pick the quest up, a turn-in ?
    once you hand it in, an objective pin once the objective is done.
  - Dungeon map: when the quest tracker, Turn in: Dungeon, the quest list's
    Turn in or an item opens the dungeon map for a quest, its ? or ! pulses
    for a few seconds. Its tooltip reads "NPC - Quest".
- Loot Filter:
  - The Armor drop-down also has Ring, Neck, Trinket and Cloak. Tick one (or
    more) to see only those items; combine them with an armor type (e.g.
    Cloth + Ring) or a weapon type (e.g. Trinket + Dagger).
  - Show results with stats ticked: an item the game had not loaded yet
    could be left out the first time (Old Serra'kis' Glowing Thresher Cape
    for Cloak + Healing). Such items are now read again a second later and
    the results update.
- Cozy Sleeping Bag arrow:
  - Knows Teldrassil is an island: in Darnassus it points to the portal west
    of the Temple Gardens ("Take the portal to Rut'theran Village"), then on
    to the hippogryph master or the boat to Auberdine, and the other way
    round.
  - Plans through as many boats, zeppelins and portals as the way takes, and
    on one continent too when a boat is quicker than the long walk. Boats
    and portals say where they land ("Take the boat to Auberdine").
  - Hearthstone: when it is ready and going from where it takes you is
    quicker, the arrow says so ("Hearth to Auberdine"). Where it takes you
    is learnt when you set it at an innkeeper or use it; until then from the
    flight point of that name or the capital's inn.
  - Flight points are only taken from a flight master's map (where you are,
    and where you can fly). The list kept so far is started again once: open
    the flight map at any flight master to fill it.
- RPG Mode: killing Rath'Mael unlocks Ruins of Lordaeron again. A final boss
  now also counts by name inside its own dungeon (when the game uses another
  NPC ID), when you see it die nearby (not only as your target), and as soon
  as it is found; a final boss you already killed whose dungeon did not
  unlock is unlocked at login.

CHANGES IN 1.7.2
- Krol'dok Stronghold: a full page now, with its loading screen. Its bosses
  (Slavecrusher Grox, Twilight Commander Zarmok, War Handler Ashka,
  Nar'gurk, Bossman Toof, Overlord Mugg) with their pictures, levels and
  the drops seen so far (among them Resistance Breaker Spaulder,
  Shadowlight Athame and Big-Belly Belt), and the rest of its known loot
  (War Handler's Gaze, the Krol'dok Warplate set) in a folded "Not
  confirmed, but probable drop" section. Its seven quests: Eye of Mugg,
  Tome of Twilight, A Token of Vengeance, Twilight Mementos and Vengeance
  of the Highborne, with Tome of Twilight's lead-in A Small Favor for the
  Alliance. RPG Mode unlocks it when Overlord Mugg dies or Eye of Mugg is
  handed in; the Alliance Tome of Twilight reveals Nar'gurk.
- The Drowned City: Gill is a rare and drops Gill's Gills; five more items
  of the same batch as probable drops. Two more quests, for both factions,
  from Krazek in Booty Bay: Shady Saltseers and The Saltseer Captain (in
  RPG Mode, handing it in counts as Captain Dreadrise killed). Zul'Alai,
  Captain Dreadrise and Gill with their real NPC IDs.
- Scarlet Monastery: Houndmaster Boomerang (Houndmaster Loksey), Library
  Walkers (Arcanist Doan), Band of Crimson Light (Herod).
- Quests done inside a dungeon: the In Dungeon icon now also sits next to
  Objective and Turn in when that part happens inside (Lost in the Thicket
  Things, Songblade Search, Deathstalkers in Shadowfang...). A quest where
  you only have to speak to someone inside the dungeon shows YOU HAVE IT
  until it is handed in there, not Turn in (also in the quest tracker). A
  chain step in your quest log that is handed in inside the dungeon says
  so at the top of its page: YOU HAVE IT and a "Turn in: Dungeon" button
  that opens the dungeon map where it is handed in.
- Excavation Site: Wetlands map: Ardin Grassman and Daewyn Songblade.
- Sleeping Bag arrow:
  - It only flies from and to flight points your character has found: open
    the flight map once at any flight master (it remembers per character);
    until then it walks. The flight it picks follows the zones (from the
    Field of Giants: Camp Taurajo, not Brackenwall over the mountains).
  - It knows the way where the straight line does not go. The Pocket
    Litter camp, worked out on real walking maps of Stonetalon: out of Sun
    Rock Retreat's east exit, up the road and along the hill path, point by
    point (also from the Barrens road, and for the Alliance from Stonetalon
    Peak); the Alliance go round Honor's Stand. At Thoradin's Wall it keeps
    to the fallen cart until you are actually on it (or up on the rubble
    behind it), then turns to the Messenger Bag.
  - In the air it counts the flight down from the length of its real path
    (the time it really took, after the first time).
  - A click on the arrow opens the world map on the objective; only the
    arrow itself can be dragged.
- /dj fakelog <questID>: shows a quest as if it were in your quest log (to
  look at its page; again to turn it off).

CHANGES IN 1.7.1
- Cozy Sleeping Bag (new): the bag's icon on the home page, next to the WoW
  Forever and Raids icons, opens its whole quest chain at the step you are
  on: where each step starts and is handed in (on the map, with
  coordinates), how to reach the spot and its rewards, for your faction.
  Track puts the chain in the quest tracker. Right-click the icon to hide it
  (also Options > UI: Hide Sleeping Bag quest); it hides by itself once you
  have the bag, and unticking the option always brings it back.
- Waypoint arrow (new, for the Sleeping Bag chain): Show on Map or Show Turn
  In on a step, or tracking the chain, puts an arrow on the screen with the
  quest's name and the distance, and it leads you through the chain step by
  step to the end. It points to the flight master first when flying saves
  enough of the way (and counts the flight down in the air), to the boat or
  zeppelin for another continent, and says when the spot is below ground or
  upstairs. Drag it anywhere, right-click to hide it; hidden in instances.
- RPG Mode: quests unlock one by one as you pick them up, with a "Dungeon
  Quest Unlocked" popup (e.g. 2/6). A dungeon's page opens partly with its
  first quest: bosses stay ??? until you kill them, quests you haven't
  picked up yet are ??? rows, and the Map, Trash Drops and Recipes &
  Patterns unlock after about 20% of its trash, with a "Dungeon Map
  Unlocked" popup. The final boss still unlocks everything. Quests you
  have already handed in count too: a quest that needed a boss dead (kill
  him, bring his head, an item only he drops) reveals that boss, and the
  final boss unlocks the page, even if you did it before turning RPG Mode
  on. The search shows only what you have unlocked. Bigger icons above the
  Journey bar.
- Dungeon maps: quest spots inside the dungeons, a ! where a quest starts
  and a ? where it is handed in or done (the Lorgalis Manuscript in
  Blackfathom Deeps, the Book of Ur in Shadowfang Keep, the prisoners in
  Blackrock Depths and more). Hover: what to do there; click: the quest.
  Every ! and ? has a thin black edge, easier to see.
- Quest list: a quest ready to hand in shows a bigger ? with "Turn in". The
  ? of a quest handed in inside a dungeon opens that dungeon's map.
- Dungeon cards: a quest counts as done only once it is handed in (also for
  hiding finished dungeons and RPG Mode's journey points).
- Quest tracker and quest pages: the objectives are in the journal's
  language when it differs from the game's.
- In Dungeon icon: also on quests whose chain starts with an item found in
  the dungeon (the Titan Relic, the Small Scroll from Charlga Razorflank).
- The Glowing Shard: the tracker shows Sputtervalve in Ratchet first, then
  Falla Sagewind above Wailing Caverns, where it is handed in.
- The Drowned City: boss levels, their drops with the real items, Primeval
  Elemental's own page, its loading screen, and the rest of its loot in a
  folded "Not confirmed, but probable drop" section.
- Dalaran: two Kirin Tor quests from Archmage Lan'dalock (Alliance), The
  Coldbringer's Eye and The Witch Doctor's Head. The Coldbringer's Eye
  drops from Amnennar the Coldbringer.

CHANGES IN 1.7.0
- Quest tracker (new): the Track button on a dungeon's quest list puts its
  quests in a small window framed like the game's Options panel. Each
  dungeon gets its own window, and each character tracks its own dungeons.
  - Quests are grouped: ready to hand in, in your log (with your progress),
    to pick up, too low a level, done. A quest with nothing to do but talk to
    someone counts as ready as soon as you have it.
  - Click the ! of a quest to pick up, or the ? of a quest to hand in, to see
    the NPC on the map (inside a dungeon: on that dungeon's map). Click a
    quest's name to open it in the journal.
  - A quest that needs a chain first shows a chain icon: click it to list the
    steps, with a tick on the ones done and a clickable ! or ? on the step
    you are on.
  - Once you loot an item that starts a quest, its icon replaces the !:
    click it to accept the quest. Quests picked up inside the dungeon, or
    started by an item that drops there, show the In Dungeon icon.
  - Drag the window anywhere (it stays on the screen and keeps its place),
    resize it from its corner, fold it down to its title bar.
- The Drowned City has its full page: six bosses, the Horde and Alliance
  quests with the chains before them, quest givers on the map and the
  entrance. No loot is known yet ("Items Data TBD").
- Journal: a quest ready to hand in shows a round ? instead of the green
  tick (in the list, on its page and on chain steps). Click it to see where
  to hand it in.
- Boss portraits show up at once: the ones the game draws itself (the WoW
  Forever dungeons) are prepared in the background after you log in, and a
  boss the game did not know yet is looked up again by itself.
- Horde paladins get the class quest Old Fire-Eye (Wolfsbane) in The
  Deadmines, Blackfathom Deeps and Shadowfang Keep. The paladin class quests
  say on each dungeon's page that they are a chain.
- Maps work on every game client: the journal brings its own copy of every
  classic dungeon map where the game has none.
- Loot Filter: cloaks no longer count as cloth.
- Knowledge in the Deeps needs level 18, as in WoW Forever.

CHANGES IN 1.6.8
- Show on Map in combat: if a quest page is open when a fight starts, Show on
  Map and Show Turn In open the map through the game's own map button. If the
  journal was opened during the fight, the button says to press M, and the
  map jumps to the marked spot when you do.

CHANGES IN 1.6.7
- RPG Mode explains itself. In the mode chooser at first login, RPG Mode's
  button is now "Enable in Options": it opens the options on the Dungeon
  list page (the RPG Mode box pulses gold) and you tick the box there, so you
  know where to switch modes later. The journal stays in Gamer Mode until
  then.
- The first time you open the journal in RPG Mode, a note over the dungeon
  cards says dungeons stay locked until you kill their final boss, with
  "Disable in Options" and "Keep RPG Mode". The new RPG Mode button in the
  dungeon list header (left of Favourites) opens it any time. The Journey bar
  now sits just under the header buttons.
- New Rogue class quests from C's Dead Drop near Pyrewood Village:
  The Horn of Xelthos (Shadowfang Keep) and The Eye of Bhossca (Scarlet
  Monastery: Graveyard and Library). Each page shows the whole chain, the
  route through the dungeon, where every key and tool comes from, and the
  rewards (Pyrewood Signet Ring, Ruby-Adorned Blade). Rogues see them (other
  classes too with "Show all class quests" on).
- The New Plague (Ruins of Lordaeron, Horde) now needs the whole A Recipe For
  Death chain first, and The Wrath of Rath'mael needs the Rear Guard Patrol
  chain first, as on live. Both chains show every step: who gives it, where
  to go, and the rewards.
- Quest chain steps: Show on Map for the quest giver, and Show Turn In when
  someone else takes the quest. YOU HAVE IT shows when a step is in your
  quest log. Click an item to mark where it is on the map (for example
  Berard's Journal); where items drop is in their tooltips.
- Less text on quest chain steps: the objective (with your progress), where
  to go, and who starts and takes the quest. Rewards you get on top of the
  one you choose are listed separately.
- Maps for three announced dungeons: The Drowned City, Krol'dok Stronghold
  and Shaper's Terrace. Click their Coming Soon card to open the map.
- Boss and trash portraits for the original dungeons load instantly, and
  portraits the journal looks up are remembered between sessions.
- Fixed: the new-version reminder could keep naming a version that isn't out.
- Everything new is translated into every supported language.

CHANGES IN 1.6.5
- New options panel in the style of the game's own Options window: Options
  and Discord tabs, General / Dungeon list pages, row highlights, and dragging the
  bottom-right corner scales the whole panel bigger or smaller. The Discord
  tab has the invite link (click it, then Ctrl+C).
- Options > AddOns > Dungeon Journal shows a page with an "Open Options"
  button.
- Home page: dungeon covers show your progress (for example 2/6 quests) once
  at least one quest there is done.
- Hiding dungeons is now per character instead of account-wide.
- Loot Filter: new MP5 stat (hover it for "Mana per 5 seconds"), a
  Resistances drop-down (only items with every ticked school), and a spell
  school drop-down next to Spell Damage (Fire, Frost, Nature, Shadow, Arcane,
  Holy). New icon on Show results.
- Matching loot page: no Quests tab and no "LV" line.
- City of Dalaran: three Violet Sorcerer's trash drops with the mobs that
  drop them; "Full Items Data TBD" removed.
- Quest pages: Show Quest Chain always comes before Show on Map. Researching
  the Corruption treats The Corruption Abroad as an optional breadcrumb.
- Show on Map added for more quest givers (Thom Filch, Afadra Dunwall,
  Earthseer Farsen, Varimathras for RFK); chat messages name the zone, e.g.
  "Thrall - Orgrimmar". The Corruption Abroad shows its reward.
- Maps: Viktor the Vile and Earthcaller Halmgar placed, Baron Aquanis has a
  portrait, and Razorfen Kraul shows how to reach Roogug (hover the ladders).
- Report button glows on hover.
- Fixed: the "Hide Dungeon Map" tick could not be unticked and hid the map
  for good; opening the options panel the first time after a reload blocked
  movement keys.

CHANGES IN 1.6.4
- Looking For Group button: an eye next to Show Location on every dungeon
  page. Click it to open the game's Looking For Group window and search for
  that dungeon. If the window opens on another page, a note points to the
  Group Browser tab. Clicking it again while the window is open just searches
  again. Right-click > Disable, or "Hide LFG Panel" in the options, hides it.
- Quests show the game's own objective text and, while the quest is in your
  log, your live progress (for example 5/7 Deviate Dreadfang slain). The
  journal learns this text from your quest log and quest givers.
- Dungeon maps: a "Boss icons" size control at the bottom left (100% down to
  0%, which hides them; 90% by default). Your size is remembered.
- New option "Hide Dungeon Map inside the dungeon": when ticked, pressing M
  inside a dungeon shows the game's normal map.
- Loot Filter: new Spell Hit stat.
- /dj shortcuts for the newer dungeons: /dj stocks, gnomer, rfk, dala, exca,
  smgy, smlib (they work in the search bar too).
- Fixed: City of Dalaran loot showed a "?" icon and the English name on
  non-English game clients. All Dalaran items now have their item IDs.
- Home page: hovering the green tick says "All quests completed"; the hover
  tooltip on dungeon covers was removed; the City of Dalaran cover no longer
  shows a black strip at the bottom.
- Wailing Caverns: Lord Pythas moved to his correct spot on the map.
- French: "Une requÃªte apeurÃ©e" quest name and objective corrected.
- Options: "Show all class quests" label matches the other options.

CHANGES IN 1.6.3
- Class quests (Warlock, Paladin, ...) only show for that class. "Show All
  Class Quests" in the options panel lists them for every class.
- Home page: a green tick in a small circle, with a soft glow, before the
  quest count of a dungeon whose quests you have all completed. It can be
  turned off in the options panel.
- Item tooltips in the journal (loot, quest rewards, search results) now use
  the game's normal tooltip, so tooltip addons such as Pawn show their scores
  and upgrade percentages there too. The tooltip keeps a solid background,
  and the item comparison only appears while Shift is held.
- Fixed: some items were shown with red names. That colour came from the
  "Retrieving item information" placeholder while an item was still loading.
- Fixed: the Favourites window now follows the journal's size when the
  journal is resized.
- Older dungeon maps on game clients that do not have their artwork (for
  example the Russian client) show a plain parchment with all boss pins and a
  short note instead of a black or green map.
- Look: new Map button icon with a thin black frame; the Horde crest on the
  Route button has a thin outline; class labels ("WARLOCK ONLY") have a light
  black edge and the class icon is centred under them.
- City of Dalaran:
  - Shade of the Archmage: Blueprint: Arcane Salvager.
  - Starving Arcane needs An Alarming Request first (Show Quest Chain).
- Blackfathom Deeps: The Orb of Soran'ruk (Warlock) added to the quests;
  Plans: Protector's Silvered Chain Leggings also drop from Lorgus Jett.
- Shadowfang Keep: Plans: Veteran's Silvered Chain Helm also drop from Fenrus
  the Devourer.
- Shared loot: Totemic Leather Helm can also drop from Azshir the Sleepless
  (Scarlet Monastery: Graveyard).

CHANGES IN 1.6.2
- City of Dalaran:
  - Boss "Mana Elemental" renamed to Arcanic Enigma, with its portrait.
  - Mana Wraith removed from the boss list.
  - Boss levels added: Mana Devourer 31, Arcanic Enigma 30.
  - Lyn the Ignored's page shows "Summoned by: Tome of Dalaran"; hover it to
    see how to get the tome.
  - New loot:
    - Atrexis the Grave Knight: Graveweave Bindings, Gravespike Repeater
      (moved from Trash Drops; that page is gone).
    - Arcane Anomaly: Mana-Warped Chain Shirt.
    - Unstable Sentinel: Unstable Crystalline Shoulderpads, Refractory
      Scaleguards, Blueprint: Spinning Wheel.
    - Fel Ancient: Blightleaf Rope, Garb of Fallen Felbark.
    - Mana Devourer: Manascale Treads.
    - Arcanic Enigma: Violet Sorcerer's Robes, Wand of Mana Concentration.
    - Lyn the Ignored: Bonepile Gaze, Cartilage Shapers, Tendonscraper Dagger.
  - Map: level 1 is now the Underbelly (where you enter), level 2 the city.
    New boss pins (Lyn, Mana Devourer, Fel Ancient, Unstable Sentinel,
    Arcanic Enigma) and moved pins (Arcane Anomaly on Krasus' Landing). The
    Underbelly ladder is at the end of the east pipe.
  - Quests:
    - Starving Arcane is shown for the Alliance.
    - Opportunistic Education starts inside the dungeon, near the sewer
      entrance.
    - The Image of Archmage Modera is shown next to the dungeon entrance on
      the map.
  - The red "Full Items Data TBD" note stays under the dungeon title only.
- The Stockade:
  - What Comes Around...: Guard Berton is pinned at Redridge 21.2, 46.6.
  - Bazil Thredd: Baros Alexston is pinned at Stormwind 57.7, 47.9.
- Dungeon map on the world map (M): zoom with the mouse wheel, then hold
  left-click to drag the map around.
- Items whose ID was not known yet now find it by themselves: the addon asks
  the server about the IDs near the dungeon's known items and also checks your
  bags and gear. /dj newids lists what was found and what is still missing.

CHANGES IN 1.6.1
- Item source on tooltips: an item that is in the journal gets one extra line
  at the bottom of its tooltip with the boss (or quest) and dungeon it comes
  from. This works when hovering gear while inspecting, in bags and on loot
  rolls, and on the window that opens when an item link in chat is clicked.
- Click that line on a chat-link window to open the journal on the boss or
  quest. For hover tooltips, bind "Open hovered item in Dungeon Journal" in the
  key bindings. /dj itemtip turns the line off.
- Options panel: right-click the minimap button (or type /dj options).
  UI: hide the journal line on item tooltips, hide the minimap button, and
  set a key to open the journal. Dungeon list: auto-hide dungeons you have
  outleveled, and dungeons whose quests you have all completed.
- Shared boss loot: the six shared leather helms (Brawler's, Trapper's,
  Defender's, Totemic, Stormrider's, Wisdom's) can drop from many bosses in
  Blackfathom Deeps, The Stockade, Razorfen Kraul and Scarlet Monastery:
  Graveyard. Those bosses get a folded "Show Shared Loot (N)" line below their
  loot; click it to see the helms.
- Boss loot lists too long to fit are shown in two columns, so far less scrolling
  is needed. Names too long for a column end in "...".
- Loot Filter: new Armor Filter button next to the minimum level. Tick one or
  more armor types (Cloth, Leather, Mail, Plate) to see only those; "All"
  clears the ticks. Weapons, shields, jewellery and cloaks always stay.
- Dungeon map: reopens on the floor you last looked at in each dungeon.
- Ruins of Lordaeron: Rotmender's Gloves added to Trash Drops (Stone Watcher).
- City of Dalaran loot: Bonebinder's Signet (Atrexis the Grave Knight), Ephemeral
  Grips and Runemender's Seal (Arcane Anomaly), Drape of Shifting Energy (Arcanic Enigma),
  Slitherwrap Girdle and Spine of the Devourer (Mana Devourer),
  Felbough Arm (Fel Ancient),
  Archmagister's Faceted Pendant and Violet Sorcerer's Mantle (Shade of the
  Archmage), and a new Trash Drops
  page with the Gravespike Repeater.
- Test of Lore (Parqual Fintallas, Undercity) shows the answer: Ner'zhul.
- Smaller download: the two City of Dalaran maps were reduced in resolution,
  roughly halving the size of the addon.
- Gnomeregan map: level 2 ladder moved to the corridor below the Launch Bay;
  new level 3 ladder on the level 4 map.
- World map: the Dungeon Map / World Map button moves aside instead of sitting
  on top of other addons' map buttons (such as Questie's).
- Quest rewards: an item shown as a reward button is no longer repeated as
  text underneath it.
- AddOn drawer: Dungeon Journal is listed in the addon list button by the
  minimap (like Leatrix), so the minimap button can be hidden safely.
  Left-click opens the journal, right-click opens the options.
- New items whose ID was not known yet fill in their icon and tooltip by
  themselves once you see the item in game (tooltip, loot, roll or chat link).
- The pop-up about the /dj command no longer appears at login.
- Spanish: dungeon names now match the game (SalÃ³n de los Feudales, Minas de
  la Muerte, Mazmorras de Ventormenta).

CHANGES IN 1.6.0
- Favourites: right-click any boss loot or quest item to add it to Favourites;
  the Favourites button on the home page opens the list, grouped by dungeon.
  Left-click a favourite to jump to its boss or quest, right-click to remove it.
- Favourites: quest items show the quest icon and the quest they come from.
- Favourites: an item you own (bags, bank or equipped) gets the green
  "completed" frame and tick.
- Favourites: item types follow the journal language; the window can be closed
  with its X in combat and stays above the journal.
- Scarlet Monastery: the dungeon map on the M key now opens in both wings. The
  wing is recognised from the entrance you walked through, and two buttons on
  the map (Graveyard / Library) switch it by hand. /dj wing graveyard or
  /dj wing library does the same.
- Boss portraits no longer flash black, or show through other windows, while
  they load.
- City of Dalaran: Heart of Disruption and An Alarming Request are available
  from level 30; An Alarming Request has a start location and Show on Map.

CHANGES IN 1.5.2
- Show on Map: the quest marker pulse is smoother and no longer blinks when it restarts.
- The Treaty of Understanding: the Stone Tablet that starts the quest is shown as a
  button; hover it to see where it is.
- Gnomeregan: Nogg's Ring Redo and Gnome Improvement show the In Dungeon icon.
- Gnomeregan: removed a redundant note from the Grime-Encrusted Ring step.

CHANGES IN 1.5.0
- New dungeon: Scarlet Monastery: Library (bosses, loot, quests, map).
- Dungeon map on the M key: inside a journal dungeon the big map shows the
  dungeon map with boss pins; a button switches back to the world map.
  /dj worldmap turns this off.
- The window can be resized by dragging its bottom-right corner (right-click
  the corner to reset).
- Report button next to the language box, with the Discord link.
- Quests can be shift-clicked into chat.
- Scarlet Monastery: Graveyard: more quests; Library: Final Passage with the
  full Test of Lore chain and its rewards.
- An Unholy Alliance now shows its final quest and rewards.
- Blackfathom Villainy lists both Horde starting points.
- Loot Filter: results can show recipe drops only; option renamed to
  "Show recipes/patterns drops".
- The journal reopens on the map if it was closed on the map, and changing
  language keeps the current page, quest faction and map floor.
- Language box: arrows replaced by a single drop-down arrow.
- Map fixes: world-map dungeon entrance positions; boss pins in Ruins of
  Lordaeron and Wailing Caverns; Arcanist Doan added to the Library map.
- Wailing Caverns map shows its original title and markings again.
- New card art for both Scarlet Monastery wings.
- Right-clicking the minimap button asks before hiding it.
- New Scarlet Monastery quests are translated in all languages.

CHANGES IN 1.4.4
- Includes eight currently recorded City of Dalaran quests, including the Horde attunement prerequisite chain.
- Power Overwhelming: target wording matches Arcanic Enigma; confirmed reward
  choices are Violet Sash or Runebound Gloves, plus 1 gold.
- The Fury Runs Deep: three reward choices, with rare Magistrate's Pantaloons;
  observed XP fallback updated to 5,750.
- Archmage Arugal: level corrected to 24.
- City of Dalaran: Alliance quest givers Shylamiir and High Sorcerer Andromath
  now show at their correct Stormwind positions on the map.
- Excavation Site: Elder Knowledge is no longer listed twice; it now appears only
  as the prerequisite step of Earthen Echo. Its turn-in and the Earthen Echo quest
  giver are Bashana Runetotem on Elder Rise, Thunder Bluff.
- Excavation Site: removed the red "Full Items Data TBD" note.
- Razorfen Kraul: Roogug added to the dungeon map.
- The Stockade: added Demolition Girdle (Kam Deepfury), Repurposed Rack (Hamhock),
  Graverobber's Shovel and Boneslicer (Dextren Ward); Kam's Walking Stick is rare,
  not epic. Removed the red "Full Items Data TBD" note.
- Boss levels: Mekgineer Thermaplugg 34; Fel Steed / Shadow Charger 19-21.
- Update alert: the addon tells you in chat when a guild or group member runs a
  newer version. Addons cannot check the internet, so this only works once
  another player with the newer version is in your guild, party or raid.
- Boss portraits for every dungeon now appear immediately on a fresh install
  instead of showing question marks while they load.
- Boss names are shown in the client language (German, French, Spanish,
  Portuguese, Russian, Korean, Simplified and Traditional Chinese).
- Shadowfang Keep map rebuilt on the four levels the game uses; Springvale,
  Razorclaw, Odo, Fenrus, Nandos and Arugal moved to their correct rooms.
- Added the paladin chain The Test of Righteousness (Verigan's Fist) to The
  Deadmines, Shadowfang Keep and Blackfathom Deeps, with all earlier steps.
- Scarlet Monastery: Graveyard: Trapper's Leather Helm now listed on both
  Interrogator Vishas and Fallen Champion.
- Fixed the quest page jumping back to the top while scrolled down to the
  rewards.
- Quest chain steps can list their required and provided items as item buttons;
  hovering one shows where it comes from (used by The Test of Righteousness).
- Trash drops: added a list for Ruins of Lordaeron (Death Bindings, Sword of the
  Fallen, Rotmender's Garb and Sash) and Razorfen Kraul, and filled in missing
  trash drops for The Deadmines and Scarlet Monastery: Graveyard.
- Trash drop lists now show rare and better items only.
- New dungeon: Scarlet Monastery: Library (Houndmaster Loksey, Arcanist Doan), with its quests.
- Boss loot now includes the profession recipes and blueprints they can drop.
- New Loot Filter button on the home page (left of Hide Dungeons): show or hide
  recipes (hidden by default), show only loot your class can use, or only items
  with the stats you tick.
  Its Show button lists every boss, in every dungeon, that drops matching loot.

PREVIOUS CHANGES
- Excavation: filled missing IDs, corrected quest levels, kill counts, item starts
  and turn-ins; added Lost in the Thicket Things, Fallen in the Fen,
  Prehistoric Prism and Earthen Echo with rewards and supported chain links.
- Added eight recorded City of Dalaran quests, including Horde attunement prerequisites. This does not assert dungeon access.
- Razorfen Kraul: added Sentinel's Boots, resolved Boar Signet's item ID,
  and added the guaranteed Quilboar Blaster reward for A Vengeful Fate.
- Stockade: filled Town Clerk's Mittens and Magistrate's Pantaloons rewards.
- Added Goblin Transponder as an item reward and corrected Edward's Knife spelling.
- Live XP now wins over stored rewards, including prerequisite quest pages.
  Superseded pre-hotfix multipliers use cached base XP offline. Recent observed
  Excavation values are retained only as offline fallbacks, not forced over live XP.

DATA LIMITS
Beta cache XP can differ from server turn-in XP and player-level adjustments.
Unverified quest givers and optional breadcrumbs are not presented as confirmed
required chains. Existing quests absent from the partial public cache are retained.
Two Opportunistic Education rewards resolve their names from the game by item ID.
New or corrected text without a translation falls back to English.
