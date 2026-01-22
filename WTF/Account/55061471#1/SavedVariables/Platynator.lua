
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
["friend"] = "_name-only",
["enemy"] = "_deer",
},
["cast_alpha"] = 1,
["target_scale"] = 1.2,
["show_friendly_in_instances_1"] = "always",
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "target",
["anchor"] = {
},
["scale"] = 1,
["layer"] = 0,
["asset"] = "arrows",
["width"] = 1,
},
{
["height"] = 1.2,
["anchor"] = {
},
["kind"] = "mouseover",
["scale"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0.9215686917304992,
["g"] = 0.3725490272045136,
["r"] = 0.6941176652908325,
},
["layer"] = 0,
["asset"] = "bold",
["width"] = 1.03,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "bold",
["width"] = 1.01,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.09411764705882351,
["b"] = 0.1529411764705883,
},
["channel"] = {
["a"] = 1,
["r"] = 0.0392156862745098,
["g"] = 0.2627450980392157,
["b"] = 1,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["height"] = 1.05,
["scale"] = 1,
},
},
["specialBars"] = {
},
["addon"] = "Platynator",
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["height"] = 1,
["textScale"] = 1,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
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
["dispelable"] = false,
["important"] = true,
},
["anchor"] = {
"LEFT",
-98,
0,
},
["height"] = 1,
["kind"] = "buffs",
["textScale"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["anchor"] = {
"RIGHT",
101,
0,
},
["height"] = 1,
["kind"] = "crowdControl",
["textScale"] = 1,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "Roboto Condensed Bold",
},
["version"] = 1,
["kind"] = "style",
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
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0.2274509966373444,
["g"] = 0.2431372702121735,
["r"] = 0.1607843190431595,
},
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
["transition"] = {
["b"] = 0,
["g"] = 0.6274509803921569,
["r"] = 1,
},
["safe"] = {
["b"] = 0.9019607843137256,
["g"] = 0.5882352941176471,
["r"] = 0.05882352941176471,
},
["offtank"] = {
["b"] = 0.7843137254901961,
["g"] = 0.6666666666666666,
["r"] = 0.05882352941176471,
},
},
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["neutral"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9254901960784314,
["b"] = 0.2901960784313726,
},
["hostile"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.4823529720306397,
["b"] = 0.3725490272045136,
},
["friendly"] = {
["a"] = 1,
["b"] = 0,
["g"] = 1,
["r"] = 0.8784313725490196,
},
},
["kind"] = "quest",
},
{
["kind"] = "eliteType",
["colors"] = {
["boss"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.9764706492424012,
},
["melee"] = {
["a"] = 1,
["b"] = 0.9882352941176472,
["g"] = 0.9882352941176472,
["r"] = 0.9882352941176472,
},
["caster"] = {
["a"] = 1,
["b"] = 0.7372549019607844,
["g"] = 0.4549019607843137,
["r"] = 0,
},
["trivial"] = {
["a"] = 1,
["b"] = 0.3333333333333333,
["g"] = 0.5568627450980392,
["r"] = 0.6980392156862745,
},
["miniboss"] = {
["a"] = 1,
["r"] = 0.4745098352432251,
["g"] = 0,
["b"] = 0.615686297416687,
},
},
["instancesOnly"] = true,
},
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
["colors"] = {
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
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
},
["kind"] = "reaction",
},
},
["anchor"] = {
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
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
["kind"] = "health",
["marker"] = {
["asset"] = "wide/glow",
},
},
{
["scale"] = 1,
["layer"] = 2,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0.2274509966373444,
["g"] = 0.2431372702121735,
["r"] = 0.1607843190431595,
},
["asset"] = "slight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["notReady"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["ready"] = {
["a"] = 1,
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.7647058823529411,
["g"] = 0.7529411764705882,
["r"] = 0.5137254901960784,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.5490196078431373,
["r"] = 0.9882352941176472,
},
["interrupted"] = {
["b"] = 0.8784313725490196,
["g"] = 0.211764705882353,
["r"] = 0.9882352941176472,
},
["channel"] = {
["a"] = 1,
["r"] = 0.5686274766921997,
["g"] = 0.7764706611633301,
["b"] = 0.3607843220233917,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["foreground"] = {
["asset"] = "wide/fade-bottom",
},
["anchor"] = {
"TOP",
0,
-9,
},
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
["kind"] = "cast",
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
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.3921568627450981,
},
["scale"] = 0.5,
["anchor"] = {
"TOPLEFT",
-60,
-11.5,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["layer"] = 3,
},
{
["openWorldOnly"] = true,
["scale"] = 0.8,
["kind"] = "elite",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "special/blizzard-elite-midnight",
["anchor"] = {
"LEFT",
-61,
0,
},
},
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 1,
["anchor"] = {
"BOTTOM",
0,
20,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
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
-78,
-10,
},
["layer"] = 3,
["asset"] = "normal/cast-icon",
["scale"] = 1,
},
{
["scale"] = 0.84,
["kind"] = "rare",
["includeElites"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-rare-midnight",
["anchor"] = {
"BOTTOMRIGHT",
70.5,
0,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["autoColors"] = {
},
["widthLimit"] = 124,
["anchor"] = {
"BOTTOM",
0,
8,
},
["kind"] = "creatureName",
["scale"] = 1.1,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["widthLimit"] = 0,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["significantFigures"] = 0,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
},
["kind"] = "health",
["displayTypes"] = {
"absolute",
},
["scale"] = 1.15,
},
{
["widthLimit"] = 63,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["colors"] = {
["npc"] = {
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
["tapped"] = {
["b"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["r"] = 0.4313725490196079,
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
},
},
["anchor"] = {
"TOPLEFT",
-49,
-12,
},
["kind"] = "castSpellName",
["scale"] = 0.93,
["align"] = "LEFT",
},
{
["widthLimit"] = 45,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castInterrupter",
["scale"] = 0.89,
["applyClassColors"] = true,
},
{
["widthLimit"] = 45,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
60,
-13,
},
["kind"] = "castTarget",
["scale"] = 0.89,
["applyClassColors"] = true,
},
},
},
},
["simplified_scale"] = 0.4,
["apply_cvars"] = true,
["not_target_alpha"] = 1,
["click_region_scale_x"] = 1,
["global_scale"] = 1,
["show_nameplates_only_needed"] = false,
["style"] = "_deer",
["click_region_scale_y"] = 1,
["stack_region_scale_x"] = 1.2,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["current_skin"] = "blizzard",
["show_nameplates"] = {
["player"] = true,
["npc"] = true,
["enemy"] = true,
},
},
},
}
