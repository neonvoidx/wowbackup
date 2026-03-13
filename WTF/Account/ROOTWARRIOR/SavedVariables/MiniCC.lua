
MiniCCDB = {
["Modules"] = {
["FriendlyIndicatorModule"] = {
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = true,
["World"] = true,
["PvE"] = true,
},
["Raid"] = {
["ExcludePlayer"] = false,
["Grow"] = "CENTER",
["ShowImportant"] = false,
["ShowDefensives"] = false,
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
["Icons"] = {
["MaxIcons"] = 1,
["Glow"] = false,
["ColorByDispelType"] = true,
["ReverseCooldown"] = false,
["Size"] = 40,
},
["ShowCC"] = false,
},
["Default"] = {
["ExcludePlayer"] = false,
["ShowDefensives"] = true,
["ShowImportant"] = true,
["Grow"] = "CENTER",
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
["Icons"] = {
["MaxIcons"] = 2,
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Size"] = 23,
},
["ShowCC"] = false,
},
},
["NameplatesModule"] = {
["Enabled"] = {
["BattleGrounds"] = true,
["Arena"] = true,
["World"] = true,
["PvE"] = true,
},
["ScaleWithNameplate"] = false,
["Friendly"] = {
["Combined"] = {
["Grow"] = "RIGHT",
["Enabled"] = false,
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
},
["Important"] = {
["Enabled"] = false,
["Grow"] = "LEFT",
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = -2,
},
},
["CC"] = {
["Enabled"] = true,
["Grow"] = "CENTER",
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = false,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 30,
},
["Offset"] = {
["Y"] = 49,
["X"] = 0,
},
},
["IgnorePets"] = true,
},
["Enemy"] = {
["Combined"] = {
["Grow"] = "RIGHT",
["Enabled"] = false,
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
},
["Important"] = {
["Enabled"] = true,
["Grow"] = "LEFT",
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 30,
},
["Offset"] = {
["Y"] = -5,
["X"] = 8,
},
},
["CC"] = {
["Enabled"] = true,
["Grow"] = "RIGHT",
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = false,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 32,
},
["Offset"] = {
["Y"] = -4,
["X"] = -8,
},
},
["IgnorePets"] = true,
},
},
["PetCCModule"] = {
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = false,
["World"] = false,
["PvE"] = false,
},
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
["Icons"] = {
["Glow"] = false,
["Count"] = 3,
["ReverseCooldown"] = false,
["ColorByDispelType"] = false,
["Size"] = 19,
},
["Grow"] = "CENTER",
},
["CCModule"] = {
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = true,
["World"] = true,
["PvE"] = true,
},
["Raid"] = {
["Grow"] = "CENTER",
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
["Icons"] = {
["Glow"] = false,
["ColorByDispelType"] = false,
["ReverseCooldown"] = false,
["Count"] = 3,
["Size"] = 26,
},
["ExcludePlayer"] = false,
},
["Default"] = {
["Grow"] = "LEFT",
["Offset"] = {
["Y"] = 0,
["X"] = 1,
},
["Icons"] = {
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Count"] = 2,
["Size"] = 48,
},
["ExcludePlayer"] = true,
},
},
["PortraitModule"] = {
["Enabled"] = {
["Always"] = true,
},
["ReverseCooldown"] = true,
},
["HealerCCModule"] = {
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = true,
["World"] = false,
["PvE"] = false,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["Icons"] = {
["Glow"] = true,
["ReverseCooldown"] = true,
["ColorByDispelType"] = true,
["Size"] = 72,
},
["ShowWarningText"] = true,
["Font"] = {
["Flags"] = "OUTLINE",
["File"] = "Fonts\\FRIZQT__.TTF",
["Size"] = 32,
},
["RelativePoint"] = "TOP",
["Sound"] = {
["Enabled"] = true,
["File"] = "Sonar.ogg",
["Channel"] = "Master",
},
["Offset"] = {
["Y"] = -200,
["X"] = 0,
},
},
["AlertsModule"] = {
["Offset"] = {
["Y"] = -100,
["X"] = 0,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["Icons"] = {
["Enabled"] = true,
["Glow"] = true,
["MaxIcons"] = 8,
["ReverseCooldown"] = false,
["ColorByClass"] = true,
["Size"] = 58,
},
["TargetFocusOnly"] = false,
["RelativePoint"] = "TOP",
["TTS"] = {
["VoiceID"] = 0,
["Volume"] = 100,
["Important"] = {
["Enabled"] = false,
},
["SpeechRate"] = 0,
["Defensive"] = {
["Enabled"] = false,
},
},
["IncludeDefensives"] = true,
["Sound"] = {
["Defensive"] = {
["Enabled"] = false,
["File"] = "AlertToastWarm.ogg",
["Channel"] = "Master",
},
["Important"] = {
["Enabled"] = false,
["File"] = "AirHorn.ogg",
["Channel"] = "Master",
},
},
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = true,
["World"] = false,
["PvE"] = false,
},
},
["KickTimerModule"] = {
["Offset"] = {
["Y"] = -111.7323150634766,
["X"] = -0.5333529114723206,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["RelativePoint"] = "CENTER",
["Icons"] = {
["Glow"] = false,
["ReverseCooldown"] = true,
["Size"] = 24,
},
["Enabled"] = {
["Always"] = false,
["Healer"] = true,
["Caster"] = true,
},
},
["TrinketsModule"] = {
["Enabled"] = {
["Always"] = true,
},
["Font"] = {
["File"] = "GameFontHighlightSmall",
},
["Point"] = "RIGHT",
["RelativePoint"] = "LEFT",
["ExcludePlayer"] = true,
["Icons"] = {
["Glow"] = false,
["ReverseCooldown"] = false,
["ShowText"] = true,
["Size"] = 20,
},
["Offset"] = {
["Y"] = 14,
["X"] = 22,
},
},
["PrecogGuesserModule"] = {
["Enabled"] = {
["Always"] = true,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["RelativePoint"] = "CENTER",
["Icons"] = {
["Glow"] = true,
["ReverseCooldown"] = true,
["Size"] = 55,
},
["Offset"] = {
["Y"] = 70,
["X"] = 0,
},
},
},
["Version"] = 33,
["NotifiedChanges"] = true,
["IconSpacing"] = 2,
["WhatsNew"] = {
},
["GlowType"] = "Proc Glow",
["FontScale"] = 1,
}
