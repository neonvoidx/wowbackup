
PLATYNATOR_CONFIG = {
["Version"] = 1,
["CharacterSpecific"] = {
},
["Profiles"] = {
["DEFAULT"] = {
["stack_region_scale_y"] = 1.1,
["design_all"] = {
},
["closer_to_screen_edges"] = true,
["cast_scale"] = 1.1,
["simplified_nameplates"] = {
["minor"] = true,
["minion"] = true,
["instancesNormal"] = true,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["designs_assigned"] = {
["enemySimplified"] = "_hare_simplified",
["friend"] = "Friendly",
["enemy"] = "DarkDevourer",
},
["cast_alpha"] = 1,
["simplified_scale"] = 0.4,
["show_friendly_in_instances_1"] = "never",
["not_target_alpha"] = 1,
["target_scale"] = 1.2,
["apply_cvars"] = true,
["current_skin"] = "blizzard",
["click_region_scale_x"] = 1,
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["height"] = 1,
["anchor"] = {
},
["layer"] = 0,
["scale"] = 1.03,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "target",
["asset"] = "arrows",
["width"] = 1,
},
{
["height"] = 1.24,
["scale"] = 1,
["layer"] = 0,
["color"] = {
["a"] = 1,
["b"] = 0.9215686917304992,
["g"] = 0.3725490272045136,
["r"] = 0.6941176652908325,
},
["anchor"] = {
},
["kind"] = "mouseover",
["asset"] = "bold",
["width"] = 1.03,
},
},
["specialBars"] = {
},
["addon"] = "Platynator",
["auras"] = {
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "RobotoCondensed-Bold",
},
["version"] = 1,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "wide/blizzard-absorb",
},
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["asset"] = "thin",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
{
["colors"] = {
["tapped"] = {
["b"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["r"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["combatOnly"] = false,
["colors"] = {
["safe"] = {
["b"] = 0.9019607843137256,
["g"] = 0.5882352941176471,
["r"] = 0.05882352941176471,
},
["transition"] = {
["b"] = 0,
["g"] = 0.6274509803921569,
["r"] = 1,
},
["offtank"] = {
["b"] = 0.7843137254901961,
["g"] = 0.6666666666666666,
["r"] = 0.05882352941176471,
},
["warning"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.8,
},
},
["kind"] = "threat",
["useSafeColor"] = true,
["instancesOnly"] = false,
},
{
["colors"] = {
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
},
["kind"] = "reaction",
},
},
["scale"] = 1,
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "grey",
},
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["kind"] = "health",
["anchor"] = {
},
["relativeTo"] = 0,
},
},
["kind"] = "style",
["markers"] = {
{
["scale"] = 1.6,
["layer"] = 3,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
18,
},
},
},
["texts"] = {
{
["widthLimit"] = 0,
["displayTypes"] = {
"absolute",
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["significantFigures"] = 0,
["scale"] = 3,
["anchor"] = {
},
["kind"] = "health",
["truncate"] = false,
["align"] = "CENTER",
},
},
},
["DarkDevourer"] = {
["highlights"] = {
{
["anchor"] = {
},
["height"] = 1.8,
["kind"] = "target",
["scale"] = 0.9,
["color"] = {
["a"] = 1,
["r"] = 0.4196078777313232,
["g"] = 0,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "soft-glow",
["width"] = 1.2,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.6666666666666666,
["g"] = 0.6666666666666666,
["b"] = 0.6666666666666666,
},
["height"] = 1,
["kind"] = "mouseover",
["anchor"] = {
},
["scale"] = 0.65,
["layer"] = 0,
["asset"] = "glow",
["width"] = 1,
},
},
["specialBars"] = {
{
["filled"] = "normal/soft-full",
["anchor"] = {
0,
-7,
},
["scale"] = 0.01,
["layer"] = 3,
["kind"] = "power",
["blank"] = "normal/soft-faded",
},
},
["texts"] = {
{
["widthLimit"] = 88,
["truncate"] = true,
["scale"] = 1,
["layer"] = 2,
["significantFigures"] = 0,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
64,
4,
},
["kind"] = "health",
["align"] = "RIGHT",
["displayTypes"] = {
"percentage",
},
},
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
},
["widthLimit"] = 96,
["anchor"] = {
"BOTTOMLEFT",
-62.5,
6.5,
},
["kind"] = "creatureName",
["scale"] = 1,
["align"] = "LEFT",
},
{
["align"] = "CENTER",
["anchor"] = {
"TOP",
0,
-11.5,
},
["widthLimit"] = 125,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castSpellName",
["layer"] = 2,
["scale"] = 0.8,
},
{
["widthLimit"] = 125,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["scale"] = 0.8,
["anchor"] = {
"TOPRIGHT",
83,
-26.5,
},
["kind"] = "castTarget",
["align"] = "LEFT",
["applyClassColors"] = true,
},
{
["align"] = "CENTER",
["scale"] = 1,
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castTimeLeft",
["layer"] = 2,
["anchor"] = {
"TOPRIGHT",
64,
-11.5,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "1",
},
["bars"] = {
{
["relativeTo"] = 0,
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["asset"] = "soft",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
{
["kind"] = "eliteType",
["colors"] = {
["boss"] = {
["a"] = 1,
["r"] = 0.9450981020927428,
["g"] = 0.4235294461250305,
["b"] = 0.458823561668396,
},
["melee"] = {
["a"] = 1,
["r"] = 0.9215686917304992,
["g"] = 0.9803922176361084,
["b"] = 0.9803922176361084,
},
["caster"] = {
["a"] = 1,
["r"] = 0.01568627543747425,
["g"] = 0.8196079134941101,
["b"] = 0.9764706492424012,
},
["trivial"] = {
["a"] = 1,
["r"] = 0.9686275124549866,
["g"] = 0.7764706611633301,
["b"] = 0.4980392456054688,
},
["miniboss"] = {
["a"] = 1,
["r"] = 0.6431372761726379,
["g"] = 0.5490196347236633,
["b"] = 0.9490196704864502,
},
},
["instancesOnly"] = true,
},
{
["colors"] = {
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["combatOnly"] = false,
["colors"] = {
["warning"] = {
["r"] = 0.8666667342185974,
["g"] = 0.4352941513061523,
["b"] = 0,
},
["transition"] = {
["r"] = 0.7450980544090271,
["g"] = 0.6745098233222961,
["b"] = 0,
},
["safe"] = {
["r"] = 0.7450980544090271,
["g"] = 0.1882353127002716,
["b"] = 0.1137254983186722,
},
["offtank"] = {
["r"] = 0.501960813999176,
["g"] = 0.501960813999176,
["b"] = 1,
},
},
["kind"] = "threat",
["instancesOnly"] = false,
["useSafeColor"] = true,
},
{
["colors"] = {
["neutral"] = {
["r"] = 0.8980392813682556,
["g"] = 0.8588235974311829,
["b"] = 0,
},
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["hostile"] = {
["r"] = 0.7450980544090271,
["g"] = 0.1882353127002716,
["b"] = 0.1137254983186722,
},
["friendly"] = {
["r"] = 0,
["g"] = 0.8901961445808411,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["scale"] = 1,
["kind"] = "health",
["foreground"] = {
["asset"] = "white",
},
["background"] = {
["color"] = {
["a"] = 0.6699999999999999,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "black",
},
["anchor"] = {
},
["absorb"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "wide/blizzard-absorb",
},
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 0.95,
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["asset"] = "soft",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["r"] = 0.4352941513061523,
["g"] = 0.4470588564872742,
["b"] = 0.4431372880935669,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 0.09411764705882351,
["b"] = 0.1529411764705883,
},
["channel"] = {
["r"] = 0.0392156862745098,
["g"] = 0.2627450980392157,
["b"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["interrupted"] = {
["r"] = 0.8000000715255737,
["g"] = 0.3019607961177826,
["b"] = 0.3019607961177826,
},
["channel"] = {
["b"] = 0.2156862745098039,
["g"] = 0.7764705882352941,
["r"] = 0.2431372549019608,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["background"] = {
["color"] = {
["a"] = 0.5,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "black",
},
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "cast",
["foreground"] = {
["asset"] = "white",
},
["interruptMarker"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "none",
},
},
},
["markers"] = {
{
["scale"] = 0.9,
["kind"] = "quest",
["anchor"] = {
"LEFT",
-72,
0,
},
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["scale"] = 1,
["kind"] = "raid",
["anchor"] = {
"BOTTOMRIGHT",
81.5,
10.5,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["square"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castIcon",
["anchor"] = {
"TOPLEFT",
-62,
-22,
},
["layer"] = 3,
["asset"] = "normal/cast-icon",
["scale"] = 1.14,
},
{
["scale"] = 0.5,
["kind"] = "cannotInterrupt",
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.392156862745098,
},
["layer"] = 3,
["asset"] = "normal/shield-soft",
["anchor"] = {
"TOPLEFT",
-63.5,
-10.5,
},
},
{
["openWorldOnly"] = false,
["scale"] = 0.81,
["kind"] = "elite",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "special/blizzard-elite-midnight",
["anchor"] = {
"BOTTOMRIGHT",
65,
8.5,
},
},
{
["scale"] = 0.75,
["kind"] = "rare",
["includeElites"] = true,
["anchor"] = {
"BOTTOMRIGHT",
52,
8,
},
["layer"] = 0,
["asset"] = "normal/blizzard-rare-midnight",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["textScale"] = 1,
["anchor"] = {
"BOTTOMLEFT",
-63,
14,
},
["height"] = 1,
["kind"] = "debuffs",
["showPandemic"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
{
["direction"] = "LEFT",
["scale"] = 1,
["showCountdown"] = true,
["filters"] = {
["dispelable"] = true,
["important"] = true,
},
["textScale"] = 1,
["anchor"] = {
"LEFT",
-86.5,
0,
},
["kind"] = "buffs",
["height"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
{
["direction"] = "RIGHT",
["scale"] = 1.4,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["textScale"] = 1,
["anchor"] = {
"RIGHT",
98,
0,
},
["kind"] = "crowdControl",
["height"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
},
},
["Friendly"] = {
["highlights"] = {
},
["specialBars"] = {
},
["addon"] = "Platynator",
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1.2,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["textScale"] = 1,
["anchor"] = {
"BOTTOM",
0,
26,
},
["kind"] = "crowdControl",
["height"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "1",
},
["version"] = 1,
["bars"] = {
},
["markers"] = {
{
["anchor"] = {
"BOTTOMLEFT",
-51,
11.5,
},
["kind"] = "raid",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["scale"] = 1,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["scale"] = 1,
["layer"] = 2,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
},
["align"] = "CENTER",
["anchor"] = {
"BOTTOM",
0,
16,
},
["kind"] = "creatureName",
["widthLimit"] = 74,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
},
},
["show_nameplates_only_needed"] = false,
["style"] = "DarkDevourer",
["click_region_scale_y"] = 1,
["global_scale"] = 1.4,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["stack_region_scale_x"] = 1.2,
["show_nameplates"] = {
["player"] = true,
["npc"] = false,
["enemy"] = true,
},
},
},
}
