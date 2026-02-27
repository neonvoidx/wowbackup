
MiniCCDB = {
["Modules"] = {
["FriendlyIndicatorModule"] = {
["Enabled"] = {
["Always"] = true,
["Arena"] = false,
["Raids"] = false,
["Dungeons"] = false,
},
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
["ShowImportant"] = true,
["Grow"] = "CENTER",
["ExcludePlayer"] = false,
["Icons"] = {
["MaxIcons"] = 1,
["Glow"] = true,
["ReverseCooldown"] = true,
["Size"] = 40,
},
["ShowDefensives"] = true,
},
["NameplatesModule"] = {
["Enabled"] = {
["Always"] = true,
["Arena"] = true,
["Raids"] = false,
["Dungeons"] = false,
},
["Friendly"] = {
["Combined"] = {
["Grow"] = "RIGHT",
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Enabled"] = false,
},
["Important"] = {
["Enabled"] = false,
["Offset"] = {
["Y"] = 0,
["X"] = -2,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Grow"] = "LEFT",
},
["CC"] = {
["Enabled"] = true,
["Offset"] = {
["Y"] = 49,
["X"] = 0,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = false,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 30,
},
["Grow"] = "CENTER",
},
["IgnorePets"] = true,
},
["Enemy"] = {
["Combined"] = {
["Grow"] = "RIGHT",
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 50,
},
["Enabled"] = false,
},
["Important"] = {
["Enabled"] = true,
["Offset"] = {
["Y"] = 0,
["X"] = -2,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = true,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 35,
},
["Grow"] = "LEFT",
},
["CC"] = {
["Enabled"] = true,
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
["Icons"] = {
["MaxIcons"] = 5,
["Glow"] = false,
["ColorByCategory"] = true,
["ReverseCooldown"] = true,
["Size"] = 35,
},
["Grow"] = "RIGHT",
},
["IgnorePets"] = true,
},
},
["PetCCModule"] = {
["Enabled"] = {
["Always"] = false,
["Arena"] = false,
["Raids"] = false,
["Dungeons"] = false,
},
["Grow"] = "CENTER",
["Icons"] = {
["Glow"] = true,
["Count"] = 3,
["ReverseCooldown"] = true,
["ColorByDispelType"] = true,
["Size"] = 30,
},
["Offset"] = {
["Y"] = 0,
["X"] = 0,
},
},
["CCModule"] = {
["Enabled"] = {
["Always"] = true,
["Arena"] = true,
["Raids"] = false,
["Dungeons"] = true,
},
["Raid"] = {
["Grow"] = "CENTER",
["ExcludePlayer"] = false,
["Icons"] = {
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Count"] = 3,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
},
["Default"] = {
["Grow"] = "RIGHT",
["ExcludePlayer"] = false,
["Icons"] = {
["Glow"] = true,
["ColorByDispelType"] = true,
["ReverseCooldown"] = true,
["Count"] = 3,
["Size"] = 50,
},
["Offset"] = {
["Y"] = 0,
["X"] = 2,
},
},
},
["PortraitModule"] = {
["Enabled"] = {
["Always"] = true,
},
["ReverseCooldown"] = false,
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
["ReverseCooldown"] = false,
["ColorByClass"] = true,
["Size"] = 58,
},
["IncludeBigDefensives"] = true,
["RelativePoint"] = "TOP",
["Enabled"] = {
["Always"] = false,
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
["TTS"] = {
["Important"] = {
["Enabled"] = false,
},
["Defensive"] = {
["Enabled"] = false,
},
["Volume"] = 100,
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
["Caster"] = false,
["Healer"] = false,
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
["Offset"] = {
["Y"] = 0,
["X"] = -2,
},
["Icons"] = {
["ReverseCooldown"] = false,
["Glow"] = false,
["ShowText"] = true,
["Size"] = 50,
},
["ExcludePlayer"] = false,
},
["HealerCCModule"] = {
["Enabled"] = {
["Always"] = true,
["Arena"] = true,
["Raids"] = false,
["Dungeons"] = false,
},
["RelativeTo"] = "UIParent",
["Point"] = "CENTER",
["Icons"] = {
["ReverseCooldown"] = true,
["Glow"] = true,
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
},
["Version"] = 24,
["NotifiedChanges"] = true,
["IconSpacing"] = 2,
["WhatsNew"] = {
},
["FontScale"] = 1,
["GlowType"] = "Proc Glow",
}
