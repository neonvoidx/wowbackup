
MiniCCDB = {
["Modules"] = {
["FriendlyIndicatorModule"] = {
["Enabled"] = {
["BattleGrounds"] = true,
["Arena"] = true,
["World"] = true,
["PvE"] = true,
},
["ShowDefensives"] = true,
["ShowImportant"] = true,
["Grow"] = "CENTER",
["ExcludePlayer"] = false,
["Icons"] = {
["MaxIcons"] = 1,
["Glow"] = true,
["ReverseCooldown"] = true,
["Size"] = 40,
},
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
},
["NameplatesModule"] = {
["Enabled"] = {
["BattleGrounds"] = true,
["Arena"] = true,
["World"] = true,
["PvE"] = true,
},
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
["Size"] = 28,
},
["Offset"] = {
["Y"] = 3,
["X"] = 6,
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
["Y"] = 3,
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
["Glow"] = true,
["Count"] = 3,
["ReverseCooldown"] = true,
["ColorByDispelType"] = true,
["Size"] = 19,
},
["Grow"] = "CENTER",
},
["CCModule"] = {
["Enabled"] = {
["BattleGrounds"] = true,
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
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Count"] = 3,
["Size"] = 32,
},
["ExcludePlayer"] = false,
},
["Default"] = {
["Grow"] = "RIGHT",
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
["Icons"] = {
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Count"] = 3,
["Size"] = 32,
},
["ExcludePlayer"] = false,
},
},
["PortraitModule"] = {
["Enabled"] = {
["Always"] = false,
},
["ReverseCooldown"] = false,
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
["Size"] = 70,
},
["Offset"] = {
["Y"] = 70,
["X"] = 0,
},
},
["KickTimerModule"] = {
["Offset"] = {
["Y"] = -300,
["X"] = 0,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["RelativePoint"] = "CENTER",
["Icons"] = {
["Glow"] = false,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Enabled"] = {
["Always"] = false,
["Healer"] = false,
["Caster"] = false,
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
["ExcludePlayer"] = false,
["Icons"] = {
["Glow"] = false,
["ReverseCooldown"] = false,
["ShowText"] = true,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = -2,
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
["IncludeBigDefensives"] = true,
["TTS"] = {
["SpeechRate"] = 0,
["Important"] = {
["Enabled"] = false,
},
["Defensive"] = {
["Enabled"] = false,
},
["Volume"] = 100,
},
["Enabled"] = {
["BattleGrounds"] = false,
["Arena"] = false,
["World"] = false,
["PvE"] = false,
},
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
["RelativePoint"] = "TOP",
},
},
["Version"] = 28,
["NotifiedChanges"] = true,
["IconSpacing"] = 2,
["WhatsNew"] = {
},
["GlowType"] = "Proc Glow",
["FontScale"] = 1,
}
