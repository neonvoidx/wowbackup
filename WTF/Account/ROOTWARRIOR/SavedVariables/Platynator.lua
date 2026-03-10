
PLATYNATOR_CONFIG = {
["Version"] = 1,
["CharacterSpecific"] = {
},
["Profiles"] = {
["DEFAULT"] = {
["stack_region_scale_y"] = 1.1,
["design_all"] = {
},
["cast_alpha"] = 1,
["mouseover_alpha"] = 1,
["closer_to_screen_edges"] = true,
["obscured_alpha"] = 0.4,
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
["enemySimplifiedCombat"] = "_hare_simplified",
["enemyPvPPlayer"] = "_deer",
["enemy"] = "DarkDevourer",
["friendCombat"] = "_name-only",
["friendPvPPlayer"] = "_name-only",
["enemySimplified"] = "DarkDevourer",
["friend"] = "Friendly",
["enemyCombat"] = "_deer",
},
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["friendlyPlayer"] = true,
["friendlyNPC"] = false,
["enemyMinion"] = true,
["enemy"] = true,
},
["current_skin"] = "blizzard",
["blizzard_widget_scale"] = 1.2,
["show_friendly_in_instances_1"] = "always",
["click_region_scale_x"] = 1,
["show_nameplates_only_needed"] = false,
["apply_cvars"] = true,
["not_target_alpha"] = 1,
["target_scale"] = 1.15,
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 1.46,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
},
{
["color"] = {
["a"] = 0.5364580154418945,
["b"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["r"] = 0.6666666865348816,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["anchor"] = {
},
["height"] = 1.42,
["sliced"] = true,
["kind"] = "mouseover",
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
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
["r"] = 1,
["g"] = 0.0941176563501358,
["b"] = 0.1529411822557449,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["r"] = 0.5137254901960784,
["g"] = 0.7529411764705882,
["b"] = 0.7647058823529411,
},
},
["kind"] = "uninterruptableCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8,
},
["sliced"] = true,
["height"] = 0.51,
["kind"] = "automatic",
},
},
["specialBars"] = {
},
["scale"] = 1.1,
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showPandemic"] = true,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMLEFT",
-64,
9.5,
},
["height"] = 1,
["showDispel"] = {
},
["textScale"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "LEFT",
["scale"] = 1.19,
["showCountdown"] = true,
["filters"] = {
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
},
["textScale"] = 1,
["kind"] = "buffs",
["height"] = 1,
["showDispel"] = {
["enrage"] = true,
},
["anchor"] = {
"LEFT",
-93,
0,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["scale"] = 1.46,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["textScale"] = 1,
["kind"] = "crowdControl",
["height"] = 1,
["showDispel"] = {
},
["anchor"] = {
"RIGHT",
93,
0,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "FritzQuadrata",
["slug"] = true,
},
["version"] = 1,
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["height"] = 1.09,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
},
["autoColors"] = {
{
["kind"] = "eliteType",
["colors"] = {
["boss"] = {
["r"] = 0.7372549019607844,
["g"] = 0.1098039215686275,
["b"] = 0,
},
["melee"] = {
["r"] = 0.9882352941176471,
["g"] = 0.9882352941176471,
["b"] = 0.9882352941176471,
},
["caster"] = {
["a"] = 1,
["b"] = 0.9647059440612793,
["g"] = 0.8901961445808411,
["r"] = 0,
},
["trivial"] = {
["r"] = 0.6980392156862745,
["g"] = 0.5568627450980392,
["b"] = 0.3333333333333333,
},
["miniboss"] = {
["a"] = 1,
["b"] = 0.6980392336845398,
["g"] = 0.4470588564872742,
["r"] = 0.2274509966373444,
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
["combatOnly"] = true,
["colors"] = {
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["transition"] = {
["r"] = 1,
["g"] = 0.6274509803921569,
["b"] = 0,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
},
["kind"] = "threat",
["instancesOnly"] = false,
["useSafeColor"] = true,
},
{
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["scale"] = 0.9,
["background"] = {
["color"] = {
["a"] = 0.2865839898586273,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["kind"] = "health",
["anchor"] = {
},
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 0.984313725490196,
["b"] = 0.3215686274509804,
},
["height"] = 0.51,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 0.09411764705882353,
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
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.5294117647058824,
["g"] = 0.5294117647058824,
["b"] = 0.5294117647058824,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 0.7411764705882353,
["b"] = 0,
},
["interrupted"] = {
["r"] = 0.9882352941176472,
["g"] = 0.211764705882353,
["b"] = 0.8784313725490196,
},
["channel"] = {
["r"] = 0.2431372549019608,
["g"] = 0.7764705882352941,
["b"] = 0.2156862745098039,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "cast",
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 0.1764705926179886,
["g"] = 0.1764705926179886,
["r"] = 0.1764705926179886,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
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
["layer"] = 3,
["scale"] = 0.9,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"TOPLEFT",
-81,
8.5,
},
},
{
["layer"] = 3,
["scale"] = 0.5,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["anchor"] = {
"TOPLEFT",
-68,
-6.5,
},
},
{
["layer"] = 3,
["scale"] = 1,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOMRIGHT",
70,
0,
},
},
{
["square"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "castIcon",
["anchor"] = {
"TOPLEFT",
-67,
-15.5,
},
["layer"] = 2,
["asset"] = "normal/cast-icon",
["scale"] = 0.54,
},
{
["openWorldOnly"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "elite",
["anchor"] = {
"LEFT",
-74,
0,
},
["layer"] = 3,
["asset"] = "special/blizzard-elite-midnight",
["scale"] = 0.66,
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0,
["significantFigures"] = 0,
["truncate"] = false,
["anchor"] = {
"RIGHT",
60.5,
0,
},
["kind"] = "health",
["scale"] = 0.8,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.75,
["autoColors"] = {
},
["anchor"] = {
"LEFT",
-59,
0,
},
["kind"] = "creatureName",
["scale"] = 0.8,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "LEFT",
["kind"] = "castSpellName",
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["anchor"] = {
"TOPLEFT",
-57,
-16,
},
["maxWidth"] = 0.44,
},
{
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
61.5,
-16,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
},
},
["Simplified"] = {
["highlights"] = {
{
["scale"] = 1.03,
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.23,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.22,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9215686917304992,
["g"] = 0.3725490272045136,
["r"] = 0.6941176652908325,
},
["layer"] = 0,
["asset"] = "Platy: 7px",
["width"] = 1.03,
["scale"] = 1,
["kind"] = "mouseover",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.24,
["includeTarget"] = true,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "RobotoCondensed-Bold",
["slug"] = true,
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
["asset"] = "Platy: Absorb Wide",
},
["animate"] = false,
["scale"] = 1,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["height"] = 1,
["asset"] = "Platy: 2px",
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
["friendly"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
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
["marker"] = {
["asset"] = "wide/glow",
},
["kind"] = "health",
["anchor"] = {
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["relativeTo"] = 0,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["asset"] = "Platy: 7px",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882353,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627450980392157,
["r"] = 0.0392156862745098,
},
},
["kind"] = "importantCast",
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
["r"] = 0.9882352941176471,
},
["interrupted"] = {
["b"] = 0.8784313725490196,
["g"] = 0.2117647058823529,
["r"] = 0.9882352941176471,
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
["marker"] = {
["asset"] = "none",
},
["kind"] = "cast",
["anchor"] = {
"TOP",
0,
-10.5,
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = false,
["asset"] = "Platy: Fade Bottom",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["interruptMarker"] = {
["asset"] = "none",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
},
["markers"] = {
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["anchor"] = {
"BOTTOM",
0,
18,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["scale"] = 1.6,
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-76.5,
-10,
},
["layer"] = 3,
["scale"] = 1,
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["anchor"] = {
"TOPLEFT",
-62,
-12,
},
["layer"] = 3,
["scale"] = 0.75,
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["color"] = {
["r"] = 0.392156862745098,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"absolute",
},
["scale"] = 3,
["layer"] = 2,
["maxWidth"] = 0,
["significantFigures"] = 0,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
},
["kind"] = "health",
["truncate"] = false,
["align"] = "CENTER",
},
{
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0,
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
["friendly"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0,
},
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
},
},
["anchor"] = {
"TOPLEFT",
-45,
-13,
},
["kind"] = "castSpellName",
["scale"] = 1,
["align"] = "CENTER",
},
{
["scale"] = 1,
["align"] = "CENTER",
["layer"] = 2,
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castTimeLeft",
["anchor"] = {
"TOPRIGHT",
65,
-13,
},
["maxWidth"] = 0,
},
},
},
["DarkDevourer"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 0,
["asset"] = "Platy: Feathered",
["width"] = 1.2,
["anchor"] = {
},
["height"] = 1.87,
["sliced"] = true,
["color"] = {
["a"] = 1,
["b"] = 0.615686297416687,
["g"] = 0,
["r"] = 1,
},
["kind"] = "target",
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Feathered",
["width"] = 1.65,
["scale"] = 0.65,
["anchor"] = {
},
["height"] = 2.35,
["sliced"] = true,
["kind"] = "mouseover",
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1.03,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.09411764705882353,
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
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["height"] = 0.91,
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
["scale"] = 1.05,
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
["showDispel"] = {
},
["anchor"] = {
"BOTTOMLEFT",
-61.5,
10,
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
["scale"] = 1.26,
["showCountdown"] = true,
["filters"] = {
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
},
["height"] = 1,
["showDispel"] = {
["enrage"] = true,
},
["anchor"] = {
"LEFT",
-91,
0,
},
["kind"] = "buffs",
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
["asset"] = "1",
["slug"] = true,
},
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
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
["asset"] = "Platy: Soft",
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
["r"] = 0.9450981020927428,
["g"] = 0.4235294461250305,
["b"] = 0.458823561668396,
},
["melee"] = {
["r"] = 0.9803922176361084,
["g"] = 0,
["b"] = 0.007843137718737125,
},
["caster"] = {
["r"] = 0.01568627543747425,
["g"] = 0.8196079134941101,
["b"] = 0.9764706492424012,
},
["trivial"] = {
["r"] = 0.9686275124549866,
["g"] = 0.7764706611633301,
["b"] = 0.4980392456054688,
},
["miniboss"] = {
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
["asset"] = "Platy: Solid White",
},
["background"] = {
["color"] = {
["a"] = 0.6699999999999999,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Black",
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
["asset"] = "Platy: Absorb Wide",
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
["asset"] = "Platy: Soft",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
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
["asset"] = "Platy: Solid Black",
},
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "cast",
["foreground"] = {
["asset"] = "Platy: Solid White",
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
["anchor"] = {
"LEFT",
-72,
0,
},
["kind"] = "quest",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["scale"] = 0.9,
},
{
["anchor"] = {
"BOTTOMRIGHT",
81.5,
10.5,
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
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-62,
-22,
},
["kind"] = "castIcon",
["scale"] = 1.14,
["layer"] = 3,
["asset"] = "normal/cast-icon",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.392156862745098,
},
["kind"] = "cannotInterrupt",
["anchor"] = {
"TOPLEFT",
-63.5,
-10.5,
},
["layer"] = 3,
["asset"] = "normal/shield-soft",
["scale"] = 0.5,
},
{
["openWorldOnly"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "elite",
["anchor"] = {
"BOTTOMRIGHT",
65,
8.5,
},
["layer"] = 0,
["asset"] = "special/blizzard-elite-midnight",
["scale"] = 0.81,
},
{
["anchor"] = {
"BOTTOMRIGHT",
52,
8,
},
["kind"] = "rare",
["includeElites"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "normal/blizzard-rare-midnight",
["scale"] = 0.75,
},
},
["texts"] = {
{
["truncate"] = true,
["scale"] = 1,
["layer"] = 2,
["maxWidth"] = 0.7,
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
["maxWidth"] = 0.76,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
},
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
["scale"] = 0.8,
["align"] = "CENTER",
["kind"] = "castSpellName",
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["anchor"] = {
"TOP",
0,
-11.5,
},
["maxWidth"] = 1,
},
{
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["maxWidth"] = 1,
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
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "castTimeLeft",
["truncate"] = false,
["scale"] = 1,
["layer"] = 2,
["anchor"] = {
"TOPRIGHT",
64,
-11.5,
},
["maxWidth"] = 0,
},
},
},
["Friendly"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1.7,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = false,
},
["textScale"] = 1,
["showDispel"] = {
},
["anchor"] = {
"BOTTOM",
0,
33.5,
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
["slug"] = true,
},
["version"] = 1,
["bars"] = {
},
["markers"] = {
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "raid",
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOMLEFT",
-52,
13.5,
},
},
{
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 1,
["anchor"] = {
"BOTTOM",
0,
34.5,
},
["kind"] = "class",
["asset"] = "normal/class",
["scale"] = 1.35,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["scale"] = 1,
["layer"] = 2,
["maxWidth"] = 0.59,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
},
},
["anchor"] = {
"BOTTOM",
0,
18,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
},
},
["global_scale"] = 1.4,
["style"] = "DarkDevourer",
["click_region_scale_y"] = 1,
["stack_region_scale_x"] = 1.2,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["simplified_scale"] = 0.8,
["designs_enabled"] = {
["pvpInstance"] = false,
["combat"] = false,
["pvpWorld"] = false,
},
},
},
}
