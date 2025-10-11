
Rematch5Settings = {
["UseMinimapButton"] = false,
["CompactPetList"] = false,
["HidePreferenceBadges"] = false,
["CurrentLayout"] = "3-teams",
["ColorPetNames"] = true,
["HideNotesBadges"] = false,
["AutoWinRecord"] = false,
["ResetSortWithFilters"] = false,
["ImportRememberOverride"] = false,
["PetMarkerNames"] = {
},
["DontSortByRelevance"] = false,
["DisableShare"] = false,
["ShowSpeciesID"] = false,
["UseDefaultJournal"] = false,
["HideTruncatedTooltips"] = false,
["PetCardForLinks"] = false,
["HideRarityBorders"] = false,
["LockPosition"] = false,
["QueueAutoLearn"] = false,
["PetCardAlwaysShowHPXPText"] = false,
["CollapseOnEsc"] = false,
["CustomScaleValue"] = 100,
["RandomAbilitiesToo"] = false,
["QueueActiveSort"] = false,
["MaximizedLayout"] = "3-teams",
["ExportIncludePreferences"] = false,
["DisplayUniqueTotal"] = false,
["SafariHatShine"] = false,
["TooltipBehavior"] = "Normal",
["HideTargetBadges"] = false,
["ShowNotesOnLoad"] = false,
["HideTeamBadges"] = false,
["InteractOnMouseover"] = 0,
["LastOpenJournal"] = true,
["PetCardFlipKey"] = "Alt",
["RandomPetRules"] = 2,
["PetCardAlwaysShowHPBar"] = false,
["ScriptFilters"] = {
{
"Unnamed Pets",
"-- Collected pets that still have their original name.\n\nreturn petInfo.isOwned and not petInfo.customName",
},
{
"Partially Leveled",
"-- Pets that have earned some xp in battle.\n\nreturn petInfo.xp and petInfo.xp>0",
},
{
"Pets Without Rares",
"-- Collected battle pets that have no rare version.\n\nif not rares then\n  rares = {}\n  for petID in AllPetIDs() do\n    if select(5,C_PetJournal.GetPetStats(petID))==4 then\n      rares[C_PetJournal.GetPetInfoByPetID(petID)]=true\n    end\n  end\nend\n\nif petInfo.canBattle and petInfo.isOwned and not rares[speciesID] then\n  return true\nend",
},
{
"Polished Pet Charms",
"-- Pets with Polished Pet Charms in their source.\n\nreturn (petInfo.sourceText or \"\"):match(\"item:163036\") and true",
},
},
["SpecialSlots"] = {
},
["BoringLoreFont"] = false,
["NotesWidth"] = 298.8333129882813,
["AlwaysUsePetSatchel"] = false,
["TypeBarTab"] = 1,
["PrioritizeBreedOnImport"] = false,
["CompactTeamList"] = false,
["ShowAbilityNumbers"] = false,
["HideMenuHelp"] = false,
["ShowLoadedTeamPreferences"] = false,
["ShowNotesInBattle"] = false,
["ExpandedTargets"] = {
["header:571"] = true,
},
["CustomScale"] = false,
["ExportIncludeNotes"] = false,
["BreedSource"] = false,
["LastSelectedGroup"] = "group:none",
["HideWinRecord"] = false,
["ToolbarDismiss"] = false,
["DefaultPreferences"] = {
},
["QueueAutoImport"] = true,
["ResetExceptSearch"] = false,
["ColorTeamNames"] = true,
["AbilityBackground"] = "Icon",
["DontConfirmCaging"] = true,
["AllowHiddenPets"] = false,
["ShowAfterBattle"] = false,
["PetCardNoMouseoverFlip"] = false,
["LevelingQueue"] = {
},
["Anchor"] = "BOTTOMRIGHT",
["LoadHealthiest"] = false,
["currentTeamID"] = "team:36",
["CompactQueueList"] = false,
["DontConfirmDeleteTeams"] = true,
["ColorTargetNames"] = true,
["NotesFont"] = "GameFontHighlight",
["KeepCompanion"] = false,
["NotesHeight"] = 507.9998168945313,
["HidePetToast"] = false,
["ExpandedOptionsHeaders"] = {
},
["ReverseToolbar"] = false,
["PetCardInBattle"] = false,
["BackupCount"] = 1,
["HideToolbarTooltips"] = false,
["HideLevelBubbles"] = false,
["LastOpenLayout"] = "3-teams",
["CompactTargetList"] = false,
["HideOptionTooltips"] = false,
["MousewheelSpeed"] = "Normal",
["PetCardShowExpansionStat"] = false,
["UseTypeBar"] = false,
["HideNotesButtonInBattle"] = false,
["ConvertedTeams"] = {
},
["NotesLeft"] = 1872.66650390625,
["PreferencesPaused"] = false,
["StickyNewPets"] = false,
["PetCardCompactCollected"] = false,
["ShowAbilityID"] = false,
["MinimapButtonPosition"] = -162,
["GroupOrder"] = {
"group:favorites",
"group:none",
},
["HideLevelingBadges"] = false,
["LastToastedPetID"] = "BattlePet-0-00002296EE8E",
["JournalLayout"] = "3-teams",
["QueueSortOrder"] = 1,
["CardBehavior"] = "Normal",
["Filters"] = {
["Other"] = {
},
["Stats"] = {
},
["Strong"] = {
},
["Marker"] = {
},
["Sources"] = {
},
["Sort"] = {
2,
1,
},
["Level"] = {
},
["Tough"] = {
},
["Types"] = {
true,
},
["Expansion"] = {
},
["Rarity"] = {
},
["RawSearchText"] = "ban",
["Similar"] = {
},
["Search"] = {
},
["Breed"] = {
},
["Script"] = {
},
["Collected"] = {
},
["Favorite"] = {
},
["Moveset"] = {
},
},
["ResetFilters"] = false,
["KeepNotesOnScreen"] = false,
["HideNonBattlePets"] = false,
["FavoriteFilters"] = {
},
["ImportConflictOverwrite"] = false,
["ExpandedGroups"] = {
["group:favorites"] = true,
["group:none"] = true,
},
["DontWarnMissing"] = false,
["HideMarkerBadges"] = false,
["LockWindow"] = false,
["HideTooltips"] = false,
["WarnWhenRandomNot25"] = false,
["NeverTeamTabs"] = false,
["SortByNickname"] = false,
["InteractOnTarget"] = 0,
["NotesBottom"] = 231.0002288818359,
["WasShownOnLogout"] = false,
["AlwaysTeamTabs"] = false,
["BreedFormat"] = 1,
["QueueSkipDead"] = false,
["LockNotesPosition"] = false,
["PetMarkers"] = {
},
["PetCardCanPin"] = false,
["InteractOnSoftInteract"] = 0,
["NoBackupReminder"] = false,
["ShowNewGroupTab"] = false,
["QueueRandomWhenEmpty"] = false,
["PetCardBackground"] = "Expansion",
["PetNotes"] = {
},
}
Rematch5SavedTeams = {
["team:13"] = {
["pets"] = {
"BattlePet-0-000018AA80BC",
"BattlePet-0-0000227F07DA",
0,
},
["notes"] = "Strategy added by WhyDaRumGone\nLevel pet damage is from magic (and doesn't allow for crits). You are also able to check the \"all magic/mechanical pets box allowed\" in rematch.Also max health of the level pet needs to be 1400 so it doesn't swap in to that\n\nTurn 1: Murder the Innocent\nMechanical Pandaren Dragonling comes in\nTurn 2: Bombing Run\nTurn 3: Flyby\nTurn 4: Explode\nCheck: : If Baa'l has more than 533HP (569HP for Baa'lial); Bring in your Level Pet. Otherwise skip this. \nTurn 5: Swap to your Baa'l\nTurn 6: Murder the Innocent\n",
["name"] = "Little Tommy Newcomer",
["tags"] = {
"020029G",
"2110QC",
"ZL",
},
["teamID"] = "team:13",
["groupID"] = "group:none",
["targets"] = {
73626,
},
["preferences"] = {
["minHP"] = 443,
["minXP"] = 5,
},
},
["team:12"] = {
["pets"] = {
"BattlePet-0-00002296EDE4",
"BattlePet-0-0000227F11FE",
"BattlePet-0-0000227F11AD",
},
["notes"] = "Strategy added by norng\n4 rounds.\n\nTurn 1: Illuminate\nTurn 2: Swap to your Netherspace Abyssal\nTurn 3: Explode\nBring in your Pet Bombling\nTurn 1: Explode\nBring in your Lunar Lantern\nTurn 1: Any standard attack will finish the fight\n",
["name"] = "Yu'la, Broodling of Yu'lon",
["tags"] = {
"0100AL",
"020016C",
"00202L",
},
["teamID"] = "team:12",
["groupID"] = "group:none",
["targets"] = {
72291,
},
},
["team:7"] = {
["pets"] = {
"BattlePet-0-0000227F0EA4",
"BattlePet-0-0000227EF799",
"BattlePet-0-0000227F0EC3",
},
["notes"] = "Strategy added by unknown\nScript thanks to Akéla\n\nTurn 1: Pump\nTurn 2: Water Jet\nTurn 3: Pump\nTurns 4+: Water Jet until Au dies (mostly not necessary)\nBanks comes in\nTurns 1+: Water Jet until Eternal Strider dies\nBring in your Teroclaw Hatchling\n\nTurn 1: Nature's Ward\nTurn 2: Hawk Eye\nTurn 3: Claw\nTurn 4: Claw\nTurn 5: Claw\n\nRepeat this rotation over and over until you won the fight.\nWith some bad luck your Hatchling dies at Lil'B. If so bring in your Dark Phoenix Hatchling and:\nTurn 1: Immolate\nTurn 2: Conflagrate\nTurns 3+: Burn until Lil'B dies\n",
["name"] = "Blingtron 4000",
["tags"] = {
"1020AK",
"12101C8",
"12205F",
},
["teamID"] = "team:7",
["groupID"] = "group:none",
["targets"] = {
71933,
},
},
["team:4"] = {
["pets"] = {
"BattlePet-0-0000227F07DA",
0,
0,
},
["notes"] = "Strategy added by unknown\nScript thanks to Wildcard\n\nTurn 1+: Breath until Pixiebell dies\nDoodle comes in\nTurn 1: Bombing Run\nTurn 2+: Breath until Tally dies. (Doodle swaps out and Tally swaps in sometime between your Breaths)\nDoodle comes back in\nTurn 1+: Breath until Doodle is below 560 health\nThen:: Explode - your leveling pets will get the full experience.\n",
["name"] = "Ashlei",
["tags"] = {
"1110QC",
"ZL",
"ZL",
},
["teamID"] = "team:4",
["groupID"] = "group:none",
["targets"] = {
87124,
},
},
["team:10"] = {
["pets"] = {
"BattlePet-0-0000227F115F",
"BattlePet-0-0000227F1161",
"random:0",
},
["notes"] = "Strategy added by unknown\nScript thanks to Suizidbombär\n\nTurn 1: Fel Immolate\nTurn 2: Call Lightning\nTurn 3: Swap to Zandalari Anklerender\nTurn 4: Black Claw\nTurn 5: Hunting Party - and watch Zao burn!\n",
["name"] = "Zao, Calfling of Niuzao",
["tags"] = {
"221014Q",
"222015R",
"ZR0",
},
["teamID"] = "team:10",
["targets"] = {
72290,
},
["groupID"] = "group:none",
},
["team:39"] = {
["pets"] = {
"BattlePet-0-0000227F0887",
"BattlePet-0-0000227EF78D",
"BattlePet-0-0000227F0680",
},
["notes"] = "Strategy added by Lukiwuki\nScript by \"DragonsAfterDark\"\n\nTurn 1: Swarm of Flies\nTurn 2: Bubble\nTurn 3: Swarm of Flies\nTurn 4: Water Jet\nTurn 5: Water Jet\nTurn 6: Water Jet\nTurn 7: Water Jet\nSir Pounce comes in\nTurn 1: Water Jet\nTurn 2: Swarm of Flies\nTurn 3: Water Jet\nBring in your Darkmoon Zeppelin\nTurn 1: Bombing Run\nTurn 2: Decoy\nTurn 3: Missile\nTurn 4: Missile\nTurn 5: Bombing Run\nTurn 6: Missile\nTurn 7: Missile\nTurn 1: Missile",
["name"] = "Miniature Army",
["tags"] = {
"12101SE",
"1120AJ",
"12101BB",
},
["teamID"] = "team:39",
["groupID"] = "group:none",
["targets"] = {
223442,
},
},
["team:16"] = {
["pets"] = {
"BattlePet-0-000022830213",
"BattlePet-0-00002283020E",
"BattlePet-0-000022830210",
},
["notes"] = "Strategy added by Refreshe#1641\nCute Face and Uncanny Luck both introduce some RNG on exact turn count/timing, It can get better or worse, listed is about average.\n\nTurn 1: Flyby\nTurns 2-4: Swarm\nTurn 5: Flurry\nSocks dies, Monte comes in\nTurn 6: Bring in your Larion Cub\nTurn 7: Prowl\nTurn 8: Bite\nTurn 9: Bite\nMonte dies, Rikki comes out\nTurn 10: Uncanny Luck\nTurn 11: Bring in your Shadefeather Hatchling\nTurn 12: Call Darkness\nTurn 13: Nocturnal Strike\nTurns 14-16: Murder\n",
["name"] = "Sully \"The Pickle\" McLeary",
["tags"] = {
"221037N",
"21202VO",
"22102FS",
},
["teamID"] = "team:16",
["groupID"] = "group:none",
["targets"] = {
71929,
},
},
["team:5"] = {
["pets"] = {
"BattlePet-0-0000227F0882",
"BattlePet-0-0000227F07DA",
0,
},
["notes"] = "Strategy added by Saintgabrial\nTurn 1+: Arcane Explosion until Chrominius dies\nBring in your Mechanical Pandaren Dragonling\nTurn 1: Breath\nTurn 2: Thunderbolt\nTurn 3+: Breath until Apexis Guardian resurrects\nThen:: Explode - your small pet gets the full experience points :-)\n",
["name"] = "Vesharr",
["tags"] = {
"2000140",
"1210QC",
"ZL",
},
["teamID"] = "team:5",
["groupID"] = "group:none",
["targets"] = {
87123,
},
},
["team:31"] = {
["pets"] = {
"BattlePet-0-00002283012A",
"BattlePet-0-0000227F1161",
0,
},
["notes"] = "Strategy added by WhyDaRumGone\nSuspect will be long but I know some like level pet strats;P/P and S/S are about 50% chance to be 7 rounds, others 8.Damage is from Mech, allows for crits and you can check magic/mech opt.Inspired by @Lazey / @DAD\n\nTurn 1: Blistering Cold\nTurn 2: Swap to your Zandalari Anklerender\nTurn 3: Swap to your Boneshard\nTurn 4: Chop\nBring in your Zandalari Anklerender\nTurn 5: Black Claw\nTurn 6: Leap, skip this step if you are faster\nTurn 7: Hunting Party\nIf you don't get the kill, your Level Pet comes back in\nTurn 8: Pass\n",
["name"] = "Drilling Down",
["tags"] = {
"11001TB",
"212015R",
"ZL",
},
["teamID"] = "team:31",
["preferences"] = {
["minHP"] = 601,
["minXP"] = 10,
},
["targets"] = {
237701,
},
["groupID"] = "group:none",
},
["team:20"] = {
["pets"] = {
"BattlePet-0-00002283012A",
"BattlePet-0-0000227F1163",
"random:0",
},
["notes"] = "Strategy added by DragonsAfterDark\nPrio 1: Blistering Cold\nPrio 2: Chop for the Bleed & as filler when Blistering Cold & BONESTORM!! are on CD\nPrio 3: BONESTORM!!\n~: Pass if stunned\nBring in your Ikky\nTurn 1: Black Claw\nTurns 2-4: Flock\n",
["name"] = "Robot Rumble",
["tags"] = {
"11201TB",
"01101FS",
"ZR0",
},
["teamID"] = "team:20",
["preferences"] = {
["minXP"] = 25,
},
["targets"] = {
223407,
},
["groupID"] = "group:none",
},
["team:24"] = {
["pets"] = {
"BattlePet-0-0000227F07DA",
"BattlePet-0-0000227F10A4",
0,
},
["notes"] = "Strategy added by GoldenBolger\nThis strategy is Hazelnuttygames 2 pet strategy, I have only tried to make the TD script for this.The strategy is shown in the video link. All credit to Hazelnuttygames for this excellent strategy.https://www.youtube.com/watch?v=iBqPDkNTaMYFor this you can use the Snail you want, as long it has the same abilitiesAbilities:Mechanical Pandaren Dragonling (MPD): 1 1 2 (Breath, Bombing Run, Decoy)Snail*: Absorb, Shell Shield, Dive\n\nTurn 1: Decoy and Breth until Arcanus is dead\nTurn 2: Change to Snail* \nTurn 3: Dive if not on cooldown\nTurn 4: Shell shiled if not on cooldown\nTurn 5: Absorb until Jadefire is dead\nTurn 6: Change in your leveling pet for one round\nTurn 7: Change back to MPD.\nTurn 8: Use Decoy , bombing run when possible.\nelse use Breath until Netherbite is dead\nIf MPD dies before Netherbite, the Snail* will be active to do the rest of the job.\n",
["name"] = "Bloodknight Antari",
["tags"] = {
"1120QC",
"221091",
"ZL",
},
["teamID"] = "team:24",
["preferences"] = {
["minXP"] = 5,
},
["groupID"] = "group:none",
["targets"] = {
66557,
},
},
["team:22"] = {
["pets"] = {
"BattlePet-0-000018AA80BC",
"BattlePet-0-0000228EF939",
"BattlePet-0-0000228EF744",
},
["notes"] = "Strategy added by Aranesh\nThanks to aikaterna from Wowhead: https://www.wowhead.com/npc=232048/jeremy-feasel#comments\n\nTurn 1: Scorched Earth\nTurn 2: Shadowflame\nTurn 3: Shadowflame\nTurn 4: Shadowflame - Baa'l dies\nBring in your Spyragos\nTurn 1: Deep Burn\nTurn 2: Deep Burn\nTurn 3: Deep Burn\nTurn 4: Deep Burn - Spyragos dies\nIf Spyragos does not manage to kill Honky-Tonk - chances are high you will have to restart the fight\nBring in your Snowclaw Cub\nTurn 1: Flash Freeze\nTurn 2: Deep Freeze\nTurn 3+: Bite until the fight is won\n",
["name"] = "Jeremy Feasel",
["tags"] = {
"112029G",
"122038E",
"121038V",
},
["teamID"] = "team:22",
["groupID"] = "group:none",
["targets"] = {
232048,
},
},
["team:25"] = {
["pets"] = {
"BattlePet-0-0000227EF799",
"BattlePet-0-0000227EF78A",
"BattlePet-0-0000227EFD16",
},
["name"] = "Morulu The Elder",
["tags"] = {
"21201C8",
"1110143",
"22201CI",
},
["teamID"] = "team:25",
["groupID"] = "group:none",
["targets"] = {
66553,
},
},
["team:8"] = {
["pets"] = {
"BattlePet-0-000018AA8063",
"BattlePet-0-0000227EF78D",
0,
},
["notes"] = "Strategy added by SebastianX#2242\noriginaly posted by [url=https://de.wowhead.com/user=daaani]daaani[/url] on [url=https://de.wowhead.com/npc=71930/schattenmeisterin-kiryn#english-comments]wowhead[/url]Script thanks to Berendain\n\nTurn 1: Magma Trap\nTurn 2: Magma Wave\nNairn will swap to Stormoen\nTurn 2+3: 2x Magma Wave (till Lightning Storm)\nTurn 3: Sons of the Flame\nTurn 4: Magma Wave\nStormoen dies\nNairn comes in\nTurn 1: Magma Trap\nTurn 2: Magma Wave\nNairn swaps with Summer\nTurn 1+2: 2x Magma Wave\nTurn 3: Swap to your Darkmoon Zeppelin\nTurn 4: Decoy\nTurn 5: Swap to your Level Pet\nTurn 6: Swap to your Darkmoon Zeppelin\nTurn 7-9: 3x Missile\nTurn 10: Bombing Run\nSummer dies\nNairn comes in\nTurn 1+2: 2x Missile\nTurn 3: Decoy\nTurn 4: Missile till Nairn dies\nNairn dies\n",
["name"] = "Shademaster Kiryn",
["tags"] = {
"212099",
"1120AJ",
"ZL",
},
["teamID"] = "team:8",
["preferences"] = {
["minHP"] = 541,
["minXP"] = 10,
},
["targets"] = {
71930,
},
["groupID"] = "group:none",
},
["team:26"] = {
["pets"] = {
"BattlePet-0-0000227EF78D",
"BattlePet-0-0000227F07DA",
"BattlePet-0-0000227EF79A",
},
["notes"] = "Strategy added by WhyDaRumGone\nUsing no alternatives ensures 5 rounds\n\nTurn 1: Thunderbolt\nTurn 2: Explode\nBring in your Crimson Spore\nTurn 3: Explode\nBring in your Rotten Little Helper\nTurn 4: Call Blizzard\nTurn 5+: Ice Lance",
["name"] = "Major Malfunction",
["tags"] = {
"0210AJ",
"0010QC",
"21003O",
},
["teamID"] = "team:26",
["groupID"] = "group:none",
["targets"] = {
222535,
},
},
["team:14"] = {
["pets"] = {
"BattlePet-0-00002282FF1A",
"BattlePet-0-0000227F07DA",
"BattlePet-0-0000227EF78A",
},
["notes"] = "Strategy added by unknown\nScript thanks to WildCard\n\nTurn 1: Moonfire\nTurns 2+: Arcane Blast until Wisdom is dead\nPatience comes in\nTurn 1: Life Exchange\nTurns 2+: Arcane Blast until Nether Faerie Dragon dies\nBring in your Mechanical Pandaren Dragonling\nTurns 1+: Breath until Patience dies\nKnowledge comes in\nTurn 1: Bombing Run\nTurn 2: Breath\nTurn 3: Decoy\nTurns 4+: Breath until Knowledge dies\n\nAnubisath is just backup. Should you need him, use Crush and nothing else.\n",
["name"] = "Lorewalker Cho",
["tags"] = {
"22102N",
"1120QC",
"1110143",
},
["teamID"] = "team:14",
["groupID"] = "group:none",
["targets"] = {
71926,
},
},
["team:18"] = {
["pets"] = {
"BattlePet-0-0000227EF794",
0,
"BattlePet-0-0000227EF799",
},
["notes"] = "Strategy added by Rebekha#21420\nTurn 1: Decoy\nTurn 2 & 3: Haywire\nTurn 4+: Alpha Strike until Tonsa dies\nChirps comes in\nBring in your Level Pet\nBring in your Teroclaw Hatchling\nTurn 1: Dodge\nTurn 2+: Claw until Chirps hp < 927\nTurn 3: Ravage until Chirps dies\nBrewly comes in\nTurn 1: Dodge when Brewly has the barrel throwing buff\nTurns 2-3: Ravage if Brewly hp < 619\nTurn 4: Claw until Brewly dies\nIf you have the world's worst RNG, bring back your Mech Axe to finish the job\n",
["name"] = "Chen Stormstout",
["tags"] = {
"12101BR",
"ZL",
"11201C8",
},
["teamID"] = "team:18",
["groupID"] = "group:none",
["targets"] = {
71927,
},
},
["team:28"] = {
["pets"] = {
0,
"BattlePet-0-0000227F0882",
"random:0",
},
["notes"] = "Strategy added by Saintgabrial\nTurn 1: Pass\nTurn 2: Swap to Chrominius\nTurn 3+: Spam Arcane Explosion until only bones is left on the enemy team.\nSurge of Power and you kill bones putting him in undead mode for one round.\nBones comes back and kills Chrominius\nBring in your extra pet to soak up bones last attack before he dies.\n1: Pass and Bones dies.\n",
["name"] = "Enbi'see, Mal, and Bones",
["tags"] = {
"ZL",
"2020140",
"ZR0",
},
["teamID"] = "team:28",
["preferences"] = {
["minXP"] = 15,
},
["targets"] = {
91015,
91362,
},
["groupID"] = "group:none",
},
["team:37"] = {
["pets"] = {
"BattlePet-0-0000228300FC",
"BattlePet-0-0000227EF788",
"BattlePet-0-000023225C71",
},
["notes"] = "Strategy added by WhyDaRumGone\nTurn 1: Poison Protocol\nTurn 2: Void Nova\nTurn 3: Swap to your Anomalus\nTurn 4: Poison Protocol\nTurn 5: Void Nova\nTurn 6+: Ooze Touch until Tickler is in Undead phase\nTurn 7: Swap to your River Calf\nTurn 8: Headbutt against Four-Legs only\nTurn 9+: Water Jet",
["name"] = "Ziriak",
["tags"] = {
"02102OQ",
"12102OQ",
"20201DD",
},
["teamID"] = "team:37",
["groupID"] = "group:none",
["targets"] = {
223443,
},
},
["team:9"] = {
["pets"] = {
"BattlePet-0-0000227F10A7",
"BattlePet-0-0000227F10E4",
"random:0",
},
["notes"] = "Strategy added by unknown\nTurn 1: Immolation\nTurn 2: Wild Magic\nTurn 3: Swap to your Rapana Whelk\nTurn 4: Acidic Goo\nTurn 5: Ooze Touch\nTurn 6: Ooze Touch\nTurns 7+8: Dive\n",
["name"] = "Chi-Chi, Hatchling of Chi-Ji",
["tags"] = {
"212013T",
"11102K9",
"ZR0",
},
["teamID"] = "team:9",
["targets"] = {
72285,
},
["groupID"] = "group:none",
},
["team:38"] = {
["pets"] = {
"BattlePet-0-00002283012A",
"BattlePet-0-0000227F1163",
"random:0",
},
["notes"] = "Strategy added by DragonsAfterDark\nPrio 1: Blistering Cold on CD\nPrio 2: Chop for the DoT & as filler when Blistering Cold & BONESTORM!! are on CD\nPrio 3: BONESTORM!!\nBring in your Ikky\nTurn 1: Black Claw\nTurns 2-4: Flock",
["name"] = "The Thing from the Swamp",
["tags"] = {
"11201TB",
"01101FS",
"ZR0",
},
["teamID"] = "team:38",
["targets"] = {
223409,
},
["groupID"] = "group:none",
["preferences"] = {
["minXP"] = 25,
},
},
["team:19"] = {
["pets"] = {
"BattlePet-0-000018AA808E",
"BattlePet-0-0000227EF78A",
"BattlePet-0-0000227EF792",
},
["notes"] = "Strategy added by unknown\nScript by DaR#1285\n\nTurn 1: Scratch\nTurn 2: Scratch\nTurn 3: Dodge\nTurns 4-6: Stampede\nTurns 7+: Scratch until Cindy is dead\nAlex comes in\nCheck the Ice Tomb debuff\nEither:: 2 Turns left: Scratch, Dodge\nOr:: 1 Turn left => Dodge\nThen:: Stampede until your Rabbit is dead\nBring in your Anubisath Idol\nTurn 1: Crush\nTurn 2: Crush\nIs Alex dead?\nYes:: Skip down to Dah'da\nNo:: Use Stoneskin and then Crush until Alex is dead\n\nDah'da comes in\nTurn 1: Crush\nTurn 2: Crush\nTurn 3: Deflection\nTurns 4+: Continue to use Crush until either Dah'da or Anubisath Idol is dead\n\nIf Anubisath Idol has died, bring in your Macabre Marionette\nTurns 1-3: Dead Man's Party\nTurns 2+: Macabre Maraca until Dah'da is dead\n",
["name"] = "Wrathion",
["tags"] = {
"1220EV",
"1210143",
"12101A7",
},
["teamID"] = "team:19",
["groupID"] = "group:none",
["targets"] = {
71924,
},
},
["team:30"] = {
["pets"] = {
"BattlePet-0-0000227F0851",
"BattlePet-0-0000227F04F2",
"BattlePet-0-000022BDEBBE",
},
["notes"] = "Strategy added by max988\nPrioritylist: \nif not active: Arcane Storm\nMana Surge\nLift-Off\nCall Darkness\nTail Sweep\n",
["name"] = "Loyal Crewmates",
["tags"] = {
"12201LP",
"22101B9",
"20101GR",
},
["teamID"] = "team:30",
["groupID"] = "group:none",
["targets"] = {
237712,
},
},
["team:35"] = {
["pets"] = {
"BattlePet-0-0000227F1163",
"BattlePet-0-0000227F1161",
"BattlePet-0-0000227F0882",
},
["notes"] = "Strategy added by DragonsAfterDark\n[url=https://youtu.be/CGgqlUwLqcQ?t=32]Video for Fight[/url]\n\nTurn 1: Black Claw\nTurns 2-4: Flock\nAn enemy pet comes in\nTurn 1: Black Claw\nTurns 2-4: Flock\nBring in your Zandalari Anklerender\nTurn 1+: Leap until Rusty Croach comes in\nAn enemy pet comes in\nTurn 1: Black Claw\nTurns 2-3: Hunting Party\nTurn 4: Leap until dead\nIf needed:\nBring in your Chrominius\nTurn 1: Bite\n",
["name"] = "Approach the Croach",
["tags"] = {
"01101FS",
"212015R",
"1000140",
},
["teamID"] = "team:35",
["groupID"] = "group:none",
["targets"] = {
237718,
},
},
["team:33"] = {
["pets"] = {
"BattlePet-0-000022C0A961",
0,
"BattlePet-0-0000227F0680",
},
["notes"] = "Strategy added by psofia\nUPDATE: This strategy by [url=https://www.wowhead.com/npc=85519/christoph-vonfeasel#comments:id=2476643]Rikade on Wowhead[/url] still works as of the Shadowlands pre-patch. As stated in the comments below if you have a P/S, P/P, P/B Starlette AND you get critted by Otto, you will die and have to start over. It doesn't happen very often from my experience with a P/B Starlette.DragonsAfterDark: 4 August 24, changes to strategy instructions and script have been made in OP's absence due to DoT changes for Toxic Smoke.\n\nTurn 1: Sweep\nOtto comes in\nTurn 1: Wind-Up [Just once, you will need it later]\nTurn 2: Swap to your Iron Starlette\nTurn 3: Wind-Up\nTurn 4: Supercharge\nTurn 5: Wind-Up - Otto dies\nSyd comes in\nTurn 1+: Toxic Smoke until Iron Starlette dies \nBring in your Level Pet\nTurn 1: Swap to your Enchanted Broom\n~: Batter once if Syd's Bubble is still up\nTurn 2: Sweep\nMr. Pointy comes in\nTurn 1: Wind-Up\nTurn 2: Wind-Up\nTurn 3: Wind-Up - Mr. Pointy dies\nSyd comes in\nTurn 1-2: Batter x2 - Syd dies\n",
["name"] = "Christoph VonFeasel",
["tags"] = {
"22206L",
"ZL",
"12101BB",
},
["teamID"] = "team:33",
["groupID"] = "group:none",
["targets"] = {
85519,
},
},
["team:27"] = {
["pets"] = {
"BattlePet-0-0000227F0882",
0,
1165,
},
["notes"] = "Strategy added by norng\nTurn 1+: Arcane Explosion until Chrominius dies. Do not kill Salad.\nBring in your Level Pet\nTurn 1: Swap to your Nexus Whelpling\nPriority 1: Arcane Storm\nPriority 2: Mana Surge\nPriority 3: Frost Breath\n",
["name"] = "Spores, Dusty, and Salad",
["tags"] = {
"2000140",
"ZL",
"222014D",
},
["teamID"] = "team:27",
["targets"] = {
90675,
91026,
},
["groupID"] = "group:none",
},
["team:32"] = {
["pets"] = {
"BattlePet-0-0000227F07DA",
0,
"BattlePet-0-0000227EF794",
},
["notes"] = "Strategy added by Evil\nTurn 1: Thunderbolt\nTurn 2: Decoy\nTurn 3+: Use Thunderbolt and Decoy on cooldown and otherwise Breath until both Judgment and Honky-Tonk die\nIf your Mechanical Pandaren Dragonling dies too early, bring in your Mechanical Axebeak and finish Honky-Tonk with Alpha Strike\nFezwick comes in\nTurn 1: Swap to your Level Pet\nTurn 2: Swap back to your Mechanical Axebeak\nTurn 3+4: Haywire\nTurn 5+: Alpha Strike until Fezwick is dead\n",
["name"] = "Jeremy Feasel (2)",
["tags"] = {
"1220QC",
"ZL",
"12001BR",
},
["teamID"] = "team:32",
["groupID"] = "group:none",
["targets"] = {
67370,
},
},
["team:3"] = {
["pets"] = {
"BattlePet-0-0000227F0680",
"BattlePet-0-0000227F0851",
0,
},
["notes"] = "Strategy added by kachooman\n11 turns total with P/P Iron starlette. Should work with any Iron Starlette but if they have any H in breed might last another round or so.\n\nTurn 1: Pass\nTurn 2: Wind-Up\nTurn 3: Supercharge\nTurn 4: Wind-Up\nGrace comes in\nTurn 5: Toxic Smoke\nTurn 6: Toxic Smoke Starlette dies before it lands\nBring in your Level Pet\nTurn 7: Swap to your Stormborne Whelpling\nTurn 8: Arcane Storm\nTurns 9: Mana Surge\nAtonement comes in\nTurns 10: Mana Surge continues\nTurn 11: Mana Surge continues\n",
["name"] = "Taralune",
["tags"] = {
"12101BB",
"22201LP",
"ZL",
},
["teamID"] = "team:3",
["groupID"] = "group:none",
["targets"] = {
87125,
},
},
["team:17"] = {
["pets"] = {
"BattlePet-0-0000227EF798",
"BattlePet-0-0000227EF78F",
"BattlePet-0-0000227EF788",
},
["notes"] = "Strategy added by DarDar#21108\nTurn 1: Call Lightning\nTurn 2: Pass\nTurn 3: Swap to your Infernal Pyreclaw\nTurn 4: Great Sting\nTurn 5: Cleave\nTurn 6: Cleave\nTurn 7: Cleave\nTurn 8: Pass\nTurn 9: Pass\nTurn 10: Great Sting\nTurn 11: Swap to your Anomalus\nTurn 12: Poison Protocol\nTurn 13: Void Nova\nTurn 14: Corrosion\n",
["name"] = "Taran Zhu",
["tags"] = {
"00202BH",
"0110219",
"22102OQ",
},
["teamID"] = "team:17",
["groupID"] = "group:none",
["targets"] = {
71931,
},
},
["team:11"] = {
["pets"] = {
"BattlePet-0-00002296EE05",
"BattlePet-0-0000227F11A9",
"BattlePet-0-0000227F11AF",
},
["notes"] = "Strategy added by norng\n4 rounds.\n\nTurn 1: Zap\nTurn 2: Explode\nBring in your Brilliant Spore\nTurn 1: Explode\nBring in your Brilliant Kaliri\nTurn 1: Predatory Strike - Xu-Fu, Cub of Xuen dies\n",
["name"] = "Xu-Fu, Cub of Xuen",
["tags"] = {
"11202L",
"11201G4",
"112023",
},
["teamID"] = "team:11",
["targets"] = {
72009,
},
["groupID"] = "group:none",
},
["team:21"] = {
["pets"] = {
"BattlePet-0-00002283012A",
"BattlePet-0-0000227F1163",
"random:0",
},
["notes"] = "Strategy added by DragonsAfterDark\nPrio 1: Blistering Cold on CD\nPrio 2: Chop until Zaedu is Bleeding, & as filler when Blistering Cold & BONESTORM!! are on CD\nPrio 3: BONESTORM!!\nBring in your Ikky\nTurn 1: Black Claw\nTurns 2-4: Flock\n",
["name"] = "One Hungry Worm",
["tags"] = {
"11201TB",
"01101FS",
"ZR0",
},
["teamID"] = "team:21",
["preferences"] = {
["minXP"] = 25,
},
["targets"] = {
223406,
},
["groupID"] = "group:none",
},
["team:2"] = {
["pets"] = {
"BattlePet-0-0000227EF788",
0,
"BattlePet-0-0000227F0A14",
},
["notes"] = "Strategy added by Mutanis\nTime: 01:25 (10 rounds)\n\nTurn 1: Corrosion (Gladiator Deathy comes in)\nTurn 2: Poison Protocol\nTurn 3: Void Nova\nTurn 4: Swap to your Level Pet (stunned)\nTurn 5: Swap to your Anomalus\nTurn 6: Corrosion\nBring in your Micromancer\nTurn 7: Raise Ally\nTurns 8-10: Dead Man's Party\n",
["name"] = "Tarr the Terrible",
["tags"] = {
"22102OQ",
"ZL",
"11102SF",
},
["teamID"] = "team:2",
["preferences"] = {
["minHP"] = 62,
},
["groupID"] = "group:none",
["targets"] = {
87110,
},
},
["team:23"] = {
["pets"] = {
0,
0,
"BattlePet-0-0000227F0851",
},
["notes"] = "Strategy added by 48laws\nTurn 1: Pass\nTurn 2: Bring in your Second Level Pet\nTurn 3: Swap to your Nexus Whelpling\nTurn 4: Arcane Storm\nTurn 5: Mana Surge\nCast Arcane Storm if necessary\n",
["name"] = "The Beakinator",
["tags"] = {
"ZL",
"ZL",
"12201LP",
},
["teamID"] = "team:23",
["groupID"] = "group:none",
["targets"] = {
85659,
},
["preferences"] = {
["minXP"] = 4,
},
},
["team:29"] = {
["pets"] = {
"BattlePet-0-0000227F0680",
"random:0",
"random:0",
},
["notes"] = "Strategy added by Remte\nIf possible, pick one additional pet that has any damaging spell that does more than 500 damage in one hit.\n\nTurn 1: Wind-Up\nTurn 2: Wind-Up\nTurn 3: Pass\nTurn 4: Wind-Up\nTurn 5: Supercharge\nTurn 6: Wind-Up\n",
["name"] = "Stitches Jr.",
["tags"] = {
"11101BB",
"ZR0",
"ZR0",
},
["teamID"] = "team:29",
["preferences"] = {
["minXP"] = 25,
},
["targets"] = {
85685,
},
["groupID"] = "group:none",
},
["team:1"] = {
["pets"] = {
"BattlePet-0-0000227F0887",
0,
"BattlePet-0-0000227F0882",
},
["name"] = "Training With Durian",
["tags"] = {
"11101SE",
"ZL",
"1120140",
},
["teamID"] = "team:1",
["targets"] = {
99035,
},
["groupID"] = "group:none",
},
["team:6"] = {
["pets"] = {
"BattlePet-0-0000227EF791",
"BattlePet-0-0000227EF797",
"random:0",
},
["notes"] = "Strategy added by unknown\nScript thanks to Eekwibble\n\nTurn 1: Make it Rain\nTurns 2-4: Inflation\nTurn 5: Blingtron Gift Package\nContinue from Turn 1 until Lil' Bling dies.\nHe will easily destroy Carpe Diem and Spirus. Sometimes taking a good chunk out of River as well.\n\nBring in Netherspawn, Spawn of Netherspawn \nTurns 1+: If you have a Whirlpool incoming, use Consume Magic. Otherwise use Creeping Ooze and Nether Blast as a filler.\n",
["name"] = "Wise Mari",
["tags"] = {
"2110198",
"11201FK",
"ZR0",
},
["teamID"] = "team:6",
["groupID"] = "group:none",
["targets"] = {
71932,
},
},
["team:15"] = {
["pets"] = {
"BattlePet-0-0000227F0882",
"BattlePet-0-000022830088",
"BattlePet-0-000022830084",
},
["notes"] = "Strategy added by Berendain\nBackground and explanation in the comments.In slot 3, you can use any pet with Ion Cannon, but note that the G0-R41-0N Ultratonk is the only one that doesn't have a 1-round standard attack, so in that sense it's worse than the other options.  It will still work though, and often you won't even need to use any attacks to get Trike low before using Ion Cannon, especially with him burning each round.\n\nTurn 1: Arcane Explosion\nTurn 2: Howl\nTurn 3: Surge of Power, Screamer dies\nChaos comes in\nTurn 1+: Arcane Explosion until Chrominius dies\nBring in your Fel Flame\nTurn 1: Flame Breath\nTurn 2: Scorched Earth\nTurn 3+: Flame Breath until Chaos dies\nTrike comes in\nTurn 1: Conflagrate\nTurn 2: Apply Flame Breath\nTurn 3: Scorched Earth\nTurn 4+: Spam Flame Breath until Fel Flame dies\nBring in your Microbot XD\nTurn 1: If needed, use any standard attack until Trike is low enough to be killed with Ion Cannon\nTurn 2: Ion Cannon, Trike dies\n",
["name"] = "Dr. Ion Goldbloom",
["tags"] = {
"2120140",
"221040",
"00202KT",
},
["teamID"] = "team:15",
["groupID"] = "group:none",
["targets"] = {
71934,
},
},
["team:34"] = {
["pets"] = {
"BattlePet-0-000022C0A961",
0,
"BattlePet-0-00002283012A",
},
["notes"] = "Strategy added by Maizou\nTurn 1: Sweep – Puzzle is forced in\nTurn 2: Swap to your Level Pet\nTurn 3: Swap to your Boneshard\nTurn 4: 10% BONESTORM (1st slot one)\nTurn 5: 30% BONESTORM (2nd slot one)\nTurn 6: 50% BONESTORM (3rd slot one)\nTurn 7: Pass – your Boneshard dies\nBring in your Enchanted Broom\nTurn 8-9: Wind-Up x2 – Puzzle dies\nDeebs comes in\nTurn 10: Batter – Deebs dies\nTyri comes in\nTurn 11: Batter – you win\n",
["name"] = "Deebs, Tyri and Puzzle",
["tags"] = {
"22206L",
"ZL",
"22201TB",
},
["teamID"] = "team:34",
["groupID"] = "group:none",
["targets"] = {
79179,
},
},
["team:36"] = {
["notes"] = "Strategy added by Ellimist#1605\nThanks to DragonsAfterDark for the script :)\n\nTurn 1: Wind-Up\nTurn 2: Supercharge\nTurn 3: Wind-Up\nRufus comes in\nTurn 4: Toxic Smoke\nBring in your Ikky\nTurn 5: Black Claw\nTurns 6-8: Flock\nBring in your Emmigosa\nTurn 9: Arcane Storm\nTurn 10: Breath\nTurn 11: Breath\nTurns 12-14: Surge of Power",
["tags"] = {
"12101BB",
"11101FS",
"21101LO",
},
["teamID"] = "team:36",
["homeID"] = "group:none",
["targets"] = {
223444,
},
["pets"] = {
"BattlePet-0-0000227F0680",
"BattlePet-0-0000227F1163",
"BattlePet-0-0000227F0862",
},
["name"] = "The Power of Friendship",
["favorite"] = true,
["groupID"] = "group:favorites",
},
}
Rematch5SavedGroups = {
["group:favorites"] = {
["sortMode"] = 1,
["name"] = "Favorite Teams",
["teams"] = {
"team:36",
},
["meta"] = true,
["groupID"] = "group:favorites",
["icon"] = "Interface\\Icons\\ACHIEVEMENT_GUILDPERK_MRPOPULARITY_RANK2",
["isExpanded"] = true,
},
["group:none"] = {
["sortMode"] = 1,
["name"] = "Ungrouped Teams",
["teams"] = {
"team:35",
"team:4",
"team:7",
"team:24",
"team:18",
"team:9",
"team:33",
"team:34",
"team:15",
"team:31",
"team:28",
"team:22",
"team:32",
"team:13",
"team:14",
"team:30",
"team:26",
"team:39",
"team:25",
"team:21",
"team:20",
"team:8",
"team:27",
"team:29",
"team:16",
"team:3",
"team:17",
"team:2",
"team:23",
"team:38",
"team:1",
"team:5",
"team:6",
"team:19",
"team:11",
"team:12",
"team:10",
"team:37",
},
["meta"] = true,
["groupID"] = "group:none",
["icon"] = "Interface\\Icons\\INV_Pet_BattlePetTraining",
["isExpanded"] = true,
},
}
Rematch5SavedTargets = {
[72285] = {
"team:9",
},
[85519] = {
"team:33",
},
[87110] = {
"team:2",
},
[71931] = {
"team:17",
},
[223407] = {
"team:20",
},
[85685] = {
"team:29",
},
[237701] = {
"team:31",
},
[66553] = {
"team:25",
},
[66557] = {
"team:24",
},
[71924] = {
"team:19",
},
[71932] = {
"team:6",
},
[223409] = {
"team:38",
},
[87123] = {
"team:5",
},
[90675] = {
"team:27",
},
[72291] = {
"team:12",
},
[223442] = {
"team:39",
},
[85659] = {
"team:23",
},
[71929] = {
"team:16",
},
[71933] = {
"team:7",
},
[91026] = {
"team:27",
},
[87124] = {
"team:4",
},
[99035] = {
"team:1",
},
[223443] = {
"team:37",
},
[237718] = {
"team:35",
},
[67370] = {
"team:32",
},
[222535] = {
"team:26",
},
[72290] = {
"team:10",
},
[79179] = {
"team:34",
},
[223444] = {
"team:36",
},
[71926] = {
"team:14",
},
[71930] = {
"team:8",
},
[71934] = {
"team:15",
},
[71927] = {
"team:18",
},
[87125] = {
"team:3",
},
[72009] = {
"team:11",
},
[232048] = {
"team:22",
},
[91015] = {
"team:28",
},
[91362] = {
"team:28",
},
[237712] = {
"team:30",
},
[223406] = {
"team:21",
},
[73626] = {
"team:13",
},
}
Rematch4Saved = nil
Rematch4Settings = nil
RematchSaved = nil
RematchSettings = nil
