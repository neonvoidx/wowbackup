
PLATYNATOR_CONFIG = {
["CharacterSpecific"] = {
},
["Version"] = 1,
["Profiles"] = {
["Blizz+"] = {
["stack_region_scale_y"] = 1.4,
["design_all"] = {
},
["simplified_assigned_fallback"] = "Blizzard+ | Simplified",
["not_in_combat_alpha"] = 1,
["simplified_nameplates"] = {
["minor"] = true,
["minion"] = true,
["instancesNormal"] = false,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["obscured_combat_alpha"] = 0.4,
["blizzard_widget_scale"] = 1.2,
["show_friendly_in_instances_1"] = "always",
["not_target_alpha"] = 0.75,
["show_nameplates_only_needed"] = false,
["click_region_scale_x"] = 1,
["cast_alpha"] = 1,
["stack_region_scale_x"] = 1.2,
["design_assignments"] = {
{
["scale"] = 1,
["simplified"] = false,
["criteria"] = {
"cannot-attack",
},
["style"] = "Blizzard+ | | | Only Name",
},
{
["scale"] = 1,
["simplified"] = true,
["criteria"] = {
"can-attack",
"class-minor",
},
["style"] = "Blizzard+ | Simplified",
},
{
["scale"] = 1,
["simplified"] = true,
["criteria"] = {
"can-attack",
"minion",
},
["style"] = "Blizzard+ | Simplified",
},
{
["scale"] = 1,
["simplified"] = false,
["criteria"] = {
"can-attack",
},
["style"] = "Blizzard+ | Clean Health",
},
},
["mouseover_alpha"] = 1,
["closer_to_screen_edges"] = true,
["cast_scale"] = 1.1,
["out_of_range_alpha"] = 1,
["nameplate_position"] = "top",
["designs_assigned"] = {
["enemySimplifiedCombat"] = "_hare_simplified",
["enemyPvPPlayer"] = "_deer",
["enemyCombat"] = "_deer",
["friendCombat"] = "_name-only",
["friendPvPPlayer"] = "_name-only",
["enemySimplified"] = "Blizzard+ | Simplified",
["friend"] = "Blizzard+ | | | Only Name",
["enemy"] = "Blizzard+ | Modern",
},
["migration"] = 9,
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["height"] = 1.46,
["kind"] = "target",
["anchor"] = {
},
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
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
["sliced"] = true,
["height"] = 1.42,
["kind"] = "mouseover",
["anchor"] = {
},
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
["sliced"] = true,
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "automatic",
["height"] = 0.51,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["kind"] = "debuffs",
["height"] = 1,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["padding"] = 0.1,
["direction"] = "LEFT",
["showType"] = true,
["layer"] = 1,
["scale"] = 1,
["showSwipe"] = true,
["showCountdown"] = true,
["height"] = 1,
["showTooltips"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["limit"] = 30,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["anchor"] = {
"LEFT",
-94,
0,
},
["kind"] = "buffs",
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
},
{
["direction"] = "RIGHT",
["padding"] = 0.1,
["showType"] = false,
["scale"] = 1,
["showSwipe"] = true,
["showCountdown"] = true,
["layer"] = 1,
["showTooltips"] = true,
["height"] = 1,
["limit"] = 30,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["anchor"] = {
"LEFT",
68,
0,
},
["kind"] = "crowdControl",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["filters"] = {
["fromYou"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
10.03,
},
["autoSized"] = true,
["height"] = 1.82,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
7.66,
},
["autoSized"] = true,
["height"] = 1.51,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1.09,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
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
["combatOnly"] = true,
["colors"] = {
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = true,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
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
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
},
["kind"] = "reaction",
},
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
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["anchor"] = {
},
["kind"] = "health",
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
["scale"] = 0.9,
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 0.51,
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 0.984313725490196,
["b"] = 0.3215686274509804,
},
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
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
["channel"] = {
["r"] = 0.2431372549019608,
["g"] = 0.7764705882352941,
["b"] = 0.2156862745098039,
},
["interrupted"] = {
["r"] = 0.9882352941176472,
["g"] = 0.211764705882353,
["b"] = 0.8784313725490196,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["kind"] = "cast",
["anchor"] = {
"TOP",
0,
-8,
},
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
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
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
["kind"] = "quest",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.9,
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"TOPLEFT",
-81,
8.5,
},
},
{
["kind"] = "cannotInterrupt",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.5,
["layer"] = 3,
["asset"] = "normal/blizzard-shield",
["anchor"] = {
"TOPLEFT",
-68,
-6.5,
},
},
{
["kind"] = "raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
20,
},
},
{
["square"] = false,
["scale"] = 0.54,
["layer"] = 2,
["anchor"] = {
"TOPLEFT",
-67,
-15.5,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["openWorldOnly"] = false,
["scale"] = 0.66,
["layer"] = 3,
["anchor"] = {
"LEFT",
-74,
0,
},
["kind"] = "elite",
["asset"] = "special/blizzard-elite-midnight",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["align"] = "CENTER",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"RIGHT",
60.5,
0,
},
["kind"] = "health",
["scale"] = 0.8,
["truncate"] = false,
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
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.8,
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-57,
-16,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
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
["Blizzard+ | | | -----------------------"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
},
["autoSized"] = true,
["height"] = 0,
["width"] = 0,
},
["click"] = {
["anchor"] = {
},
["autoSized"] = true,
["height"] = 0,
["width"] = 0,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
},
["texts"] = {
},
},
["Blizzard+ | | | | -----------------------"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
},
["autoSized"] = true,
["height"] = 0,
["width"] = 0,
},
["click"] = {
["anchor"] = {
},
["autoSized"] = true,
["height"] = 0,
["width"] = 0,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
},
["texts"] = {
},
},
["Blizzard+ | | | Only Name (no guild)"] = {
["highlights"] = {
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["hostile"] = {
["a"] = 0.1484373658895493,
["b"] = 0,
["g"] = 0.6235294342041016,
["r"] = 1,
},
["neutral"] = {
["a"] = 0.1484373658895493,
["b"] = 0,
["g"] = 0.6235294342041016,
["r"] = 1,
},
["friendly"] = {
["a"] = 0.1484373658895493,
["b"] = 0,
["g"] = 0.6235294342041016,
["r"] = 1,
},
},
["kind"] = "quest",
},
},
["kind"] = "automatic",
["anchor"] = {
"TOP",
0,
30,
},
["sliced"] = false,
["height"] = 0.85,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
1.4,
},
["autoSized"] = true,
["height"] = 1.07,
["width"] = 1.65,
},
["click"] = {
["anchor"] = {
"TOP",
},
["autoSized"] = true,
["height"] = 0.89,
["width"] = 1.5,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "Friz Quadrata TT",
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["kind"] = "quest",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.9,
["layer"] = 4,
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"BOTTOM",
0,
2,
},
},
{
["kind"] = "raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1.4,
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
2,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["color"] = {
["b"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["r"] = 0.9686275124549866,
},
["layer"] = 2,
["maxWidth"] = 1.5,
["autoColors"] = {
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
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
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["anchor"] = {
"TOP",
0,
0,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["scale"] = 1.27,
},
},
},
["Blizzard+ | Thin Bars"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["height"] = 0.98,
["kind"] = "target",
["anchor"] = {
"TOP",
0,
3,
},
["color"] = {
["a"] = 1,
["r"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["b"] = 0.9058824181556702,
},
},
{
["color"] = {
["a"] = 0.5364580154418945,
["b"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["r"] = 0.6666666865348816,
},
["layer"] = 4,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["sliced"] = true,
["height"] = 0.9,
["kind"] = "mouseover",
["anchor"] = {
"TOP",
0,
2.5,
},
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["r"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["r"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
},
},
["kind"] = "importantCast",
},
},
["sliced"] = true,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["height"] = 0.51,
["scale"] = 1,
},
{
["color"] = {
["a"] = 0.3749999105930328,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["scale"] = 1,
["anchor"] = {
"TOP",
0,
0.5,
},
["kind"] = "focus",
["height"] = 0.61,
["sliced"] = false,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.15,
["kind"] = "target",
["anchor"] = {
"TOP",
0,
0,
},
["sliced"] = true,
["height"] = 0.61,
["scale"] = 1,
},
{
["color"] = {
["a"] = 0.4140620827674866,
["b"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["r"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["anchor"] = {
"TOP",
0,
2,
},
["sliced"] = true,
["height"] = 0.9,
["kind"] = "softTarget",
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["height"] = 0.5,
},
{
["color"] = {
["a"] = 0.2812498509883881,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.15,
["kind"] = "softTarget",
["anchor"] = {
"TOP",
0,
0,
},
["sliced"] = true,
["height"] = 0.61,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
"TOP",
0,
2.5,
},
["sliced"] = true,
["height"] = 0.98,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.15,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-82.5,
1.5,
},
["height"] = 1.19,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["anchor"] = {
"BOTTOMRIGHT",
62.5,
10.5,
},
["kind"] = "debuffs",
["height"] = 1,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
},
{
["padding"] = 0.1,
["direction"] = "LEFT",
["showType"] = true,
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["height"] = 1,
["showTooltips"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["limit"] = 30,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["anchor"] = {
"BOTTOMLEFT",
-61.5,
10.5,
},
["kind"] = "buffs",
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
},
{
["direction"] = "RIGHT",
["padding"] = 0.1,
["showType"] = false,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["layer"] = 1,
["showTooltips"] = true,
["height"] = 1,
["limit"] = 30,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["anchor"] = {
"TOPRIGHT",
91.5,
9.5,
},
["kind"] = "crowdControl",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["filters"] = {
["fromYou"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
12.93,
},
["height"] = 2.02,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
10.3,
},
["height"] = 1.68,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
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
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["height"] = 0.61,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 1,
["g"] = 0,
["r"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["b"] = 0.8588235974311829,
["g"] = 0.4392157196998596,
["r"] = 0.5764706134796143,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.8588235974311829,
["r"] = 0.8980392813682556,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.8901961445808411,
["r"] = 0,
},
["unfriendly"] = {
["r"] = 0.9058824181556702,
["g"] = 0.4549019932746887,
["b"] = 0.1294117718935013,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["anchor"] = {
"TOP",
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["scale"] = 0.9,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 0.51,
["color"] = {
["a"] = 0.5,
["b"] = 0.3215686274509804,
["g"] = 0.984313725490196,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.8980392813682556,
["r"] = 0.9843137860298156,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["b"] = 0.1882353127002716,
["g"] = 0.2313725650310516,
["r"] = 1,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
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
-8,
},
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
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["kind"] = "quest",
["scale"] = 0.9,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 4,
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"BOTTOM",
0,
9.5,
},
},
{
["kind"] = "cannotInterrupt",
["scale"] = 0.39,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-shield",
["anchor"] = {
"TOPLEFT",
-66.5,
-8.5,
},
},
{
["kind"] = "raid",
["scale"] = 1,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOMRIGHT",
39.5,
-3,
},
},
{
["square"] = false,
["scale"] = 1.3,
["layer"] = 2,
["anchor"] = {
"TOPLEFT",
-83,
2,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["align"] = "CENTER",
["anchor"] = {
"BOTTOMRIGHT",
62.5,
1.5,
},
["kind"] = "health",
["scale"] = 0.8,
["truncate"] = false,
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
"BOTTOMLEFT",
-62,
1.5,
},
["kind"] = "creatureName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-57,
-18,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.46,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"TOPRIGHT",
61.5,
-18,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
61.5,
-18,
},
["kind"] = "castInterrupter",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | Modern"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["height"] = 1.46,
["kind"] = "target",
["anchor"] = {
},
["color"] = {
["a"] = 1,
["r"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["b"] = 0.9058824181556702,
},
},
{
["color"] = {
["a"] = 0.5364580154418945,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["layer"] = 4,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["sliced"] = true,
["height"] = 1.42,
["kind"] = "mouseover",
["anchor"] = {
},
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["b"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["r"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["b"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
},
},
["kind"] = "importantCast",
},
},
["sliced"] = true,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["height"] = 0.51,
["scale"] = 1,
},
{
["color"] = {
["a"] = 0.3749999105930328,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "focus",
["height"] = 1,
["sliced"] = false,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1,
["scale"] = 1,
},
{
["color"] = {
["a"] = 0.4062497913837433,
["b"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["r"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "softTarget",
["height"] = 1.42,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["height"] = 0.5,
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "softTarget",
["height"] = 1,
["sliced"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.46,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.2,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-88.5,
9.5,
},
["height"] = 1.59,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["anchor"] = {
"BOTTOMRIGHT",
62.5,
10,
},
["kind"] = "debuffs",
["height"] = 1,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
},
{
["padding"] = 0.1,
["direction"] = "LEFT",
["showType"] = true,
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["height"] = 1,
["showTooltips"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["limit"] = 30,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["anchor"] = {
"BOTTOMLEFT",
-61.5,
10.5,
},
["kind"] = "buffs",
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
},
{
["direction"] = "RIGHT",
["padding"] = 0.1,
["showType"] = false,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["layer"] = 1,
["showTooltips"] = true,
["height"] = 1,
["limit"] = 30,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["anchor"] = {
"BOTTOMRIGHT",
91.5,
-12.5,
},
["kind"] = "crowdControl",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["filters"] = {
["fromYou"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
10.03,
},
["height"] = 1.82,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
7.66,
},
["height"] = 1.51,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
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
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["height"] = 1.09,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.8588235974311829,
["r"] = 0.8980392813682556,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.8901961445808411,
["r"] = 0,
},
["unfriendly"] = {
["b"] = 0.1294117718935013,
["g"] = 0.4549019932746887,
["r"] = 0.9058824181556702,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["scale"] = 0.9,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 0.51,
["color"] = {
["a"] = 0.5,
["b"] = 0.3215686274509804,
["g"] = 0.984313725490196,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["b"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.8980392813682556,
["r"] = 0.9843137860298156,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["b"] = 0.1882353127002716,
["g"] = 0.2313725650310516,
["r"] = 1,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
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
-8,
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 0.1764705926179886,
["g"] = 0.1764705926179886,
["b"] = 0.1764705926179886,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["kind"] = "quest",
["scale"] = 0.9,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 4,
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"BOTTOM",
0,
12.5,
},
},
{
["kind"] = "cannotInterrupt",
["scale"] = 0.46,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-shield",
["anchor"] = {
"TOPLEFT",
-68,
-7,
},
},
{
["kind"] = "raid",
["scale"] = 1,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
3.5,
},
},
{
["square"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["scale"] = 1.75,
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["anchor"] = {
"TOPLEFT",
-89.5,
10,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["align"] = "CENTER",
["anchor"] = {
"RIGHT",
60.5,
0,
},
["kind"] = "health",
["scale"] = 0.8,
["truncate"] = false,
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-59.5,
-17.5,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.46,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"TOPRIGHT",
60,
-17.5,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
60,
-17.5,
},
["kind"] = "castInterrupter",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | Blocky Cast"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
},
["height"] = 0.98,
["kind"] = "target",
["anchor"] = {
"TOP",
0,
3,
},
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.5364580154418945,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["layer"] = 4,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["height"] = 0.9,
["anchor"] = {
"TOP",
0,
2,
},
["kind"] = "mouseover",
["sliced"] = true,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["r"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.05,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["r"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-7,
},
["kind"] = "automatic",
["height"] = 1.22,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.3749999105930328,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["kind"] = "focus",
["anchor"] = {
"TOP",
0,
0.5,
},
["sliced"] = false,
["height"] = 0.61,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.15,
["scale"] = 1,
["anchor"] = {
"TOP",
0,
0,
},
["sliced"] = true,
["height"] = 0.61,
["kind"] = "target",
},
{
["color"] = {
["a"] = 0.4140620827674866,
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["anchor"] = {
"TOP",
0,
2,
},
["kind"] = "softTarget",
["height"] = 0.9,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1.03,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["height"] = 1,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["anchor"] = {
"TOP",
0,
-9,
},
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.15,
["scale"] = 1,
["anchor"] = {
"TOP",
0,
0,
},
["sliced"] = true,
["height"] = 0.61,
["kind"] = "softTarget",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
"TOP",
0,
2.5,
},
["sliced"] = true,
["height"] = 0.98,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.2,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-88.5,
1.5,
},
["height"] = 1.59,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMRIGHT",
62,
10,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["height"] = 1,
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["anchor"] = {
"BOTTOMLEFT",
-61.5,
10.5,
},
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["anchor"] = {
"TOPRIGHT",
91.5,
9,
},
["padding"] = 0.1,
["height"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
13.68,
},
["height"] = 2.59,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
10.3,
},
["height"] = 2.16,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["animate"] = false,
["scale"] = 0.9,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 0.61,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.8,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
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
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["neutral"] = {
["r"] = 0.8980392813682556,
["g"] = 0.8588235974311829,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 0.8901961445808411,
["b"] = 0,
},
["unfriendly"] = {
["b"] = 0.1294117718935013,
["g"] = 0.4549019932746887,
["r"] = 0.9058824181556702,
},
},
["kind"] = "reaction",
},
},
["marker"] = {
["asset"] = "none",
},
["kind"] = "health",
["anchor"] = {
"TOP",
},
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
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
["relativeTo"] = 0,
},
{
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 0.984313725490196,
["b"] = 0.3215686274509804,
},
["height"] = 0.99,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9843137860298156,
["g"] = 0.8980392813682556,
["b"] = 0,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["b"] = 0.1882353127002716,
["g"] = 0.2313725650310516,
["r"] = 1,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8,
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
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
["kind"] = "cast",
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 3,
["scale"] = 0.9,
["anchor"] = {
"BOTTOM",
0,
9.5,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["scale"] = 0.46,
["anchor"] = {
"TOPLEFT",
-68,
-12,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["scale"] = 1,
["anchor"] = {
"BOTTOMRIGHT",
40,
-3,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
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
-89.5,
2,
},
["layer"] = 2,
["asset"] = "normal/cast-icon",
["scale"] = 1.75,
},
},
["texts"] = {
{
["truncate"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"BOTTOMRIGHT",
63,
1.5,
},
["kind"] = "health",
["scale"] = 0.8,
["align"] = "CENTER",
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
"BOTTOMLEFT",
-62,
1.5,
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
["showInterrupted"] = true,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-59,
-13.5,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["align"] = "LEFT",
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
62.5,
-13.5,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
62.5,
-13.5,
},
["kind"] = "castInterrupter",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | Clean Health"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
},
["height"] = 1.46,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.5364580154418945,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["height"] = 1.42,
["anchor"] = {
},
["kind"] = "mouseover",
["sliced"] = true,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["r"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["r"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
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
["kind"] = "automatic",
["height"] = 0.51,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.3749999105930328,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = false,
["height"] = 1,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["b"] = 0.9058824181556702,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.4062497913837433,
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["anchor"] = {
},
["kind"] = "softTarget",
["height"] = 1.42,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["height"] = 0.5,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["anchor"] = {
"TOP",
0,
-8,
},
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["sliced"] = true,
["height"] = 1,
["kind"] = "softTarget",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.46,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.2,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-88.5,
9.5,
},
["height"] = 1.59,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMRIGHT",
62.5,
18,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["height"] = 1,
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["anchor"] = {
"BOTTOMLEFT",
-62.5,
18.5,
},
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["anchor"] = {
"RIGHT",
91.5,
0,
},
["padding"] = 0.1,
["height"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-19.35,
},
["height"] = 2.59,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"BOTTOM",
0,
-15.97,
},
["height"] = 2.16,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["animate"] = false,
["scale"] = 0.9,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 1.09,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
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
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
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
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 1,
["g"] = 0,
["r"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["b"] = 0.8588235974311829,
["g"] = 0.4392157196998596,
["r"] = 0.5764706134796143,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.8588235974311829,
["r"] = 0.8980392813682556,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.8901961445808411,
["r"] = 0,
},
["unfriendly"] = {
["b"] = 0.1294117718935013,
["g"] = 0.4549019932746887,
["r"] = 0.9058824181556702,
},
},
["kind"] = "reaction",
},
},
["marker"] = {
["asset"] = "none",
},
["kind"] = "health",
["anchor"] = {
},
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
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
["relativeTo"] = 0,
},
{
["marker"] = {
["asset"] = "none",
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
["uninterruptable"] = {
["b"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9843137860298156,
["g"] = 0.8980392813682556,
["b"] = 0,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["r"] = 1,
["g"] = 0.2313725650310516,
["b"] = 0.1882353127002716,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8,
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
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
["kind"] = "cast",
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 3,
["anchor"] = {
"BOTTOM",
0,
17.5,
},
["scale"] = 0.9,
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-68,
-7,
},
["scale"] = 0.46,
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["anchor"] = {
"BOTTOMRIGHT",
40,
4.5,
},
["scale"] = 1,
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
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
-89.5,
10,
},
["layer"] = 2,
["asset"] = "normal/cast-icon",
["scale"] = 1.75,
},
},
["texts"] = {
{
["truncate"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"BOTTOMRIGHT",
63,
9,
},
["kind"] = "health",
["scale"] = 0.8,
["align"] = "CENTER",
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
"BOTTOMLEFT",
-62,
9,
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
["showInterrupted"] = true,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-59.5,
-17,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["align"] = "LEFT",
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
59.5,
-17,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
59.5,
-17,
},
["kind"] = "castInterrupter",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | | Classic (power)"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.760784387588501,
["b"] = 0.2117647230625153,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Classic Level",
["width"] = 1,
["sliced"] = false,
["height"] = 1,
["kind"] = "fixed",
["scale"] = 1,
["anchor"] = {
"RIGHT",
84,
0,
},
},
{
["color"] = {
["a"] = 0.2968749105930329,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 0.97,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = false,
["height"] = 0.72,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.2117647230625153,
["g"] = 0.760784387588501,
["r"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
["autoColors"] = {
},
["kind"] = "automatic",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
{
["useSpecColors"] = true,
["scale"] = 0.6,
["layer"] = 3,
["anchor"] = {
"TOP",
0,
0,
},
["kind"] = "power",
["asset"] = "Platy: Gradient Circle",
["fixedColor"] = {
["b"] = 0,
["g"] = 0.788235294117647,
["r"] = 0.9411764705882353,
},
},
},
["scale"] = 0.8,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["kind"] = "debuffs",
["height"] = 1,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["padding"] = 0.1,
["direction"] = "LEFT",
["showType"] = true,
["layer"] = 1,
["scale"] = 0.9,
["showSwipe"] = true,
["showCountdown"] = true,
["anchor"] = {
"RIGHT",
-68,
0,
},
["showTooltips"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["limit"] = 30,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["height"] = 1,
["kind"] = "buffs",
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
},
{
["direction"] = "RIGHT",
["padding"] = 0.1,
["showType"] = false,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["layer"] = 1,
["showTooltips"] = true,
["anchor"] = {
"LEFT",
91,
0,
},
["limit"] = 30,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["height"] = 1,
["kind"] = "crowdControl",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["filters"] = {
["fromYou"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
24.36,
},
["autoSized"] = true,
["height"] = 3.35,
["width"] = 1.1,
},
["click"] = {
["anchor"] = {
"TOP",
0,
20,
},
["autoSized"] = true,
["height"] = 2.79,
["width"] = 1,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
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
["b"] = 0.2117647230625153,
["g"] = 0.760784387588501,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["warning"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.8000000715255737,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = true,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 1,
["g"] = 0,
["r"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["b"] = 0.8588235974311829,
["g"] = 0.4392157196998596,
["r"] = 0.5764706134796143,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["hostile"] = {
["r"] = 0.992156862745098,
["g"] = 0.1921568627450981,
["b"] = 0.196078431372549,
},
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["friendly"] = {
["r"] = 0.05490196078431373,
["g"] = 0.807843137254902,
["b"] = 0.00784313725490196,
},
["neutral"] = {
["r"] = 0.788235294117647,
["g"] = 0.7764705882352941,
["b"] = 0.06274509803921569,
},
},
["kind"] = "reaction",
},
},
["scale"] = 1,
["absorb"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
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
["kind"] = "health",
["anchor"] = {
},
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0.6666666666666666,
["g"] = 0.6666666666666666,
["r"] = 0.6666666666666666,
},
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4352941513061524,
["g"] = 0.4352941513061524,
["r"] = 0.4352941513061524,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.8980392813682556,
["r"] = 0.9843137860298156,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["b"] = 0.1882353127002716,
["g"] = 0.2313725650310516,
["r"] = 1,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
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
["asset"] = "Platy: Solid Grey",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["kind"] = "cast",
["anchor"] = {
"TOP",
0,
-8,
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["b"] = 0.03921568766236305,
["g"] = 1,
["r"] = 0,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 4,
["anchor"] = {
"BOTTOM",
0,
18.5,
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["scale"] = 0.9,
},
{
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-68,
-10,
},
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.392156862745098,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["scale"] = 0.53,
},
{
["openWorldOnly"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["anchor"] = {
"RIGHT",
92,
0,
},
["kind"] = "elite",
["asset"] = "special/blizzard-elite-around",
["scale"] = 1.25,
},
{
["layer"] = 3,
["anchor"] = {
"BOTTOM",
0,
20,
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["scale"] = 1,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.99,
["autoColors"] = {
},
["anchor"] = {
"BOTTOM",
0,
9,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["scale"] = 1,
},
{
["showInterrupted"] = true,
["truncate"] = false,
["scale"] = 0.95,
["layer"] = 2,
["maxWidth"] = 0,
["anchor"] = {
"TOP",
0,
-11,
},
["kind"] = "castSpellName",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["align"] = "CENTER",
},
{
["truncate"] = false,
["color"] = {
["b"] = 0,
["g"] = 1,
["r"] = 0.874509871006012,
},
["layer"] = 2,
["maxWidth"] = 0.16,
["autoColors"] = {
{
["colors"] = {
["impossible"] = {
["b"] = 0.1,
["g"] = 0.1,
["r"] = 1,
},
["standard"] = {
["b"] = 0.25,
["g"] = 0.75,
["r"] = 0.25,
},
["trivial"] = {
["b"] = 0.5,
["g"] = 0.5,
["r"] = 0.5,
},
["verydifficult"] = {
["b"] = 0.25,
["g"] = 0.5,
["r"] = 1,
},
["difficult"] = {
["b"] = 0,
["g"] = 0.82,
["r"] = 1,
},
},
["kind"] = "difficulty",
},
},
["showModifiers"] = false,
["anchor"] = {
"RIGHT",
83,
0,
},
["kind"] = "level",
["scale"] = 1,
["align"] = "CENTER",
},
},
},
["Blizzard+ | | | Only Name"] = {
["highlights"] = {
{
["color"] = {
["a"] = 0,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["hostile"] = {
["a"] = 0.1562496572732925,
["r"] = 1,
["g"] = 0.6235294342041016,
["b"] = 0,
},
["neutral"] = {
["a"] = 0.1562496572732925,
["b"] = 0,
["g"] = 0.6235294342041016,
["r"] = 1,
},
["friendly"] = {
["a"] = 0.1562496572732925,
["r"] = 1,
["g"] = 0.6235294342041016,
["b"] = 0,
},
},
["kind"] = "quest",
},
},
["scale"] = 1,
["anchor"] = {
"BOTTOM",
0,
-36,
},
["sliced"] = false,
["height"] = 0.85,
["kind"] = "automatic",
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-2.4,
},
["height"] = 1.07,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.65,
},
["click"] = {
["anchor"] = {
"BOTTOM",
0,
-1,
},
["height"] = 0.89,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.5,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "Friz Quadrata TT",
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["layer"] = 4,
["scale"] = 0.9,
["anchor"] = {
"BOTTOM",
0,
14,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["layer"] = 3,
["scale"] = 1.4,
["anchor"] = {
"BOTTOM",
0,
14,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["color"] = {
["r"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["b"] = 0.9686275124549866,
},
["layer"] = 2,
["maxWidth"] = 1.5,
["autoColors"] = {
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.4941176772117615,
["r"] = 1,
},
},
["kind"] = "quest",
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
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
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
["anchor"] = {
"BOTTOM",
0,
-1,
},
["kind"] = "creatureName",
["scale"] = 1.27,
["align"] = "CENTER",
},
{
["showWhenWowDoes"] = true,
["playerGuild"] = true,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 1.3,
["npcRole"] = true,
["autoColors"] = {
},
["truncate"] = false,
["anchor"] = {
"TOP",
0,
-2,
},
["kind"] = "guild",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.94,
},
},
},
["Blizzard+ | Simplified"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 0.74,
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
},
["height"] = 0.98,
["sliced"] = true,
["anchor"] = {
"TOP",
0,
3,
},
["kind"] = "target",
},
{
["color"] = {
["a"] = 0.5364580154418945,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["layer"] = 4,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 0.74,
["scale"] = 0.9,
["anchor"] = {
"TOP",
0,
2.5,
},
["height"] = 0.9,
["sliced"] = true,
["kind"] = "mouseover",
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["b"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 0.65,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["r"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["b"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["r"] = 0.4000000357627869,
["g"] = 1,
["b"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.7019608020782471,
["b"] = 0.4509804248809815,
},
["channel"] = {
["a"] = 1,
["r"] = 0.4000000357627869,
["g"] = 0.6000000238418579,
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
-8.5,
},
["sliced"] = true,
["height"] = 0.51,
["kind"] = "automatic",
},
{
["color"] = {
["a"] = 0.3749999105930328,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 0.65,
["sliced"] = false,
["anchor"] = {
"TOP",
0,
0.5,
},
["kind"] = "focus",
["height"] = 0.61,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 0.8,
["scale"] = 1,
["anchor"] = {
"TOP",
0,
0,
},
["kind"] = "target",
["height"] = 0.61,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.4140620827674866,
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 0.74,
["kind"] = "softTarget",
["anchor"] = {
"TOP",
0,
2,
},
["sliced"] = true,
["height"] = 0.9,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.65,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0.9843137860298156,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0.9843137860298156,
["r"] = 1,
},
},
["kind"] = "importantCast",
},
},
["height"] = 0.5,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 0.8,
["scale"] = 1,
["anchor"] = {
"TOP",
0,
0,
},
["kind"] = "softTarget",
["height"] = 0.61,
["sliced"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.3058823645114899,
["g"] = 0.572549045085907,
["r"] = 0.9294118285179138,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 0.74,
["scale"] = 0.9,
["anchor"] = {
"TOP",
0,
2.5,
},
["kind"] = "focus",
["height"] = 0.98,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.15,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-59,
2,
},
["height"] = 1.19,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showTooltips"] = true,
["scale"] = 0.8,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMRIGHT",
39,
11,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["anchor"] = {
"BOTTOMLEFT",
-39.5,
11,
},
["layer"] = 1,
["scale"] = 0.5,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["height"] = 1,
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["height"] = 1,
["padding"] = 0.1,
["anchor"] = {
"TOPRIGHT",
64.5,
7.5,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
12.21,
},
["height"] = 1.97,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 0.72,
},
["click"] = {
["anchor"] = {
"TOP",
0,
9.65,
},
["height"] = 1.64,
["kind"] = "click",
["autoSized"] = true,
["width"] = 0.65,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["height"] = 0.61,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 0.7,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
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
["warning"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.8,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["instancesOnly"] = false,
["useSafeColor"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0.7803922295570374,
["g"] = 0.6196078658103943,
["b"] = 0.3686274588108063,
},
["caster"] = {
["r"] = 0,
["g"] = 0.988235354423523,
["b"] = 0.988235354423523,
},
["trivial"] = {
["r"] = 0.5058823823928833,
["g"] = 0.5137255191802979,
["b"] = 0.5137255191802979,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["hostile"] = {
["r"] = 0.9137255549430848,
["g"] = 0,
["b"] = 0,
},
["unfriendly"] = {
["b"] = 0.1294117718935013,
["g"] = 0.4549019932746887,
["r"] = 0.9058824181556702,
},
["friendly"] = {
["r"] = 0,
["g"] = 0.8901961445808411,
["b"] = 0,
},
["neutral"] = {
["r"] = 0.8980392813682556,
["g"] = 0.8588235974311829,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["scale"] = 0.9,
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["kind"] = "health",
["anchor"] = {
"TOP",
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
["asset"] = "none",
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
["width"] = 0.65,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["b"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0.1372549086809158,
},
["channel"] = {
["r"] = 0.03921568766236305,
["g"] = 0.2627451121807098,
["b"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9843137860298156,
["g"] = 0.8980392813682556,
["b"] = 0,
},
["channel"] = {
["r"] = 0,
["g"] = 0.4470588564872742,
["b"] = 0.7764706611633301,
},
["interrupted"] = {
["r"] = 1,
["g"] = 0.2313725650310516,
["b"] = 0.1882353127002716,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
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
["r"] = 0.1764705926179886,
["g"] = 0.1764705926179886,
["b"] = 0.1764705926179886,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 4,
["anchor"] = {
"BOTTOM",
0,
9.5,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["scale"] = 0.9,
},
{
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-44,
-8.5,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["scale"] = 0.39,
},
{
["layer"] = 3,
["anchor"] = {
"BOTTOM",
0,
10.5,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["scale"] = 1,
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
-59.5,
2.5,
},
["layer"] = 2,
["asset"] = "normal/cast-icon",
["scale"] = 1.3,
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["align"] = "CENTER",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["truncate"] = false,
["anchor"] = {
"TOP",
0,
0.5,
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
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0.65,
["autoColors"] = {
},
["anchor"] = {
"BOTTOM",
0,
2.5,
},
["kind"] = "creatureName",
["scale"] = 0.65,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["showInterrupted"] = true,
["truncate"] = true,
["scale"] = 0.5,
["layer"] = 2,
["maxWidth"] = 0.24,
["anchor"] = {
"TOPLEFT",
-37.5,
-17.5,
},
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "LEFT",
},
{
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.35,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
38.5,
-17.5,
},
["kind"] = "castTarget",
["scale"] = 0.5,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.35,
["scale"] = 0.5,
["anchor"] = {
"TOPRIGHT",
38.5,
-17.5,
},
["kind"] = "castInterrupter",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | Clean Health Blocky Bars"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
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
["layer"] = 4,
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
["b"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["r"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.05,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["r"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-6.5,
},
["sliced"] = true,
["height"] = 1.22,
["kind"] = "automatic",
},
{
["color"] = {
["a"] = 0.3749999105930328,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["sliced"] = false,
["anchor"] = {
},
["kind"] = "focus",
["height"] = 1,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["b"] = 0.9058824181556702,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["sliced"] = true,
["height"] = 1,
["kind"] = "target",
},
{
["color"] = {
["a"] = 0.4062497913837433,
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.42,
["kind"] = "softTarget",
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1.03,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["height"] = 1,
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "softTarget",
["height"] = 1,
["sliced"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.46,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.26,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-96,
9.5,
},
["height"] = 2.1,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMRIGHT",
63,
18,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["anchor"] = {
"BOTTOMLEFT",
-62.5,
18.5,
},
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["height"] = 1,
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["height"] = 1,
["padding"] = 0.1,
["anchor"] = {
"RIGHT",
91.5,
0,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
21.88,
},
["height"] = 3.13,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
17.8,
},
["height"] = 2.61,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["animate"] = false,
["scale"] = 0.9,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 1.09,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 1,
["g"] = 0,
["r"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["b"] = 0.8588235974311829,
["g"] = 0.4392157196998596,
["r"] = 0.5764706134796143,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["neutral"] = {
["r"] = 0.8980392813682556,
["g"] = 0.8588235974311829,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 0.8901961445808411,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 0.9058824181556702,
["g"] = 0.4549019932746887,
["b"] = 0.1294117718935013,
},
},
["kind"] = "reaction",
},
},
["marker"] = {
["asset"] = "none",
},
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
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
["relativeTo"] = 0,
},
{
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 0.984313725490196,
["b"] = 0.3215686274509804,
},
["height"] = 0.99,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.8980392813682556,
["r"] = 0.9843137860298156,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["r"] = 1,
["g"] = 0.2313725650310516,
["b"] = 0.1882353127002716,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
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
-7.5,
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
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 4,
["anchor"] = {
"BOTTOM",
0,
17.5,
},
["scale"] = 0.9,
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-68,
-11,
},
["scale"] = 0.46,
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["anchor"] = {
"BOTTOMRIGHT",
40.5,
3.5,
},
["scale"] = 1,
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-97,
10,
},
["kind"] = "castIcon",
["scale"] = 2.3,
["layer"] = 2,
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["truncate"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"BOTTOMRIGHT",
63,
9,
},
["kind"] = "health",
["scale"] = 0.8,
["align"] = "CENTER",
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
"BOTTOMLEFT",
-62,
9,
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
["showInterrupted"] = true,
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-59,
-12.5,
},
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "LEFT",
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
62.5,
-12.5,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
62.5,
-12.5,
},
["kind"] = "castInterrupter",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | Blocky Bars"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["color"] = {
["a"] = 1,
["b"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["r"] = 0.9058824181556702,
},
["height"] = 1.46,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.5364580154418945,
["b"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["r"] = 0.6666666865348816,
},
["layer"] = 4,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["height"] = 1.42,
["anchor"] = {
},
["kind"] = "mouseover",
["sliced"] = true,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 0.9294118285179138,
["g"] = 0.9294118285179138,
["r"] = 0.9294118285179138,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.05,
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.6196078658103943,
["g"] = 0.6196078658103943,
["r"] = 0.6196078658103943,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["a"] = 1,
["b"] = 0.4000000357627869,
["g"] = 1,
["r"] = 0.4000000357627869,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.4509804248809815,
["g"] = 0.7019608020782471,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.6000000238418579,
["r"] = 0.4000000357627869,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-6.5,
},
["kind"] = "automatic",
["height"] = 1.22,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.3749999105930328,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 1.03,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = false,
["height"] = 1,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9058824181556702,
["g"] = 0.9058824181556702,
["b"] = 0.9058824181556702,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0.4062497913837433,
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.7490196228027344,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["anchor"] = {
},
["kind"] = "softTarget",
["height"] = 1.42,
["sliced"] = true,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1.03,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["scale"] = 1,
["height"] = 1,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["anchor"] = {
"TOP",
0,
-8.5,
},
},
{
["color"] = {
["a"] = 0.2812498509883881,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow",
["width"] = 1.22,
["scale"] = 1,
["anchor"] = {
},
["sliced"] = true,
["height"] = 1,
["kind"] = "softTarget",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.572549045085907,
["b"] = 0.3058823645114899,
},
["layer"] = 1,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.46,
["scale"] = 0.9,
},
{
["color"] = {
["a"] = 0,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 0.26,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
["channel"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.9843137860298156,
["b"] = 0,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOPLEFT",
-96,
9.5,
},
["height"] = 2.1,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMRIGHT",
63.5,
10,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["height"] = 1,
["layer"] = 1,
["scale"] = 0.7,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["anchor"] = {
"BOTTOMLEFT",
-61.5,
10.5,
},
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["anchor"] = {
"RIGHT",
91.5,
0,
},
["padding"] = 0.1,
["height"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
10.73,
},
["height"] = 2.35,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.11,
},
["click"] = {
["anchor"] = {
"TOP",
0,
7.66,
},
["height"] = 1.96,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.01,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
["marker"] = {
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 1.09,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
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
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
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
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 1,
["g"] = 0,
["r"] = 1,
},
["melee"] = {
["b"] = 0.3686274588108063,
["g"] = 0.6196078658103943,
["r"] = 0.7803922295570374,
},
["caster"] = {
["b"] = 0.988235354423523,
["g"] = 0.988235354423523,
["r"] = 0,
},
["trivial"] = {
["b"] = 0.5137255191802979,
["g"] = 0.5137255191802979,
["r"] = 0.5058823823928833,
},
["miniboss"] = {
["b"] = 0.8588235974311829,
["g"] = 0.4392157196998596,
["r"] = 0.5764706134796143,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0,
["r"] = 0.9137255549430848,
},
["unfriendly"] = {
["r"] = 0.9058824181556702,
["g"] = 0.4549019932746887,
["b"] = 0.1294117718935013,
},
["friendly"] = {
["r"] = 0,
["g"] = 0.8901961445808411,
["b"] = 0,
},
["neutral"] = {
["r"] = 0.8980392813682556,
["g"] = 0.8588235974311829,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["scale"] = 0.9,
["kind"] = "health",
["anchor"] = {
},
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
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
["asset"] = "none",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 0.984313725490196,
["b"] = 0.3215686274509804,
},
["height"] = 0.99,
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4352941513061523,
["g"] = 0.4352941513061523,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["b"] = 0.1372549086809158,
["g"] = 0.4941176772117615,
["r"] = 1,
},
["channel"] = {
["b"] = 1,
["g"] = 0.2627451121807098,
["r"] = 0.03921568766236305,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.8980392813682556,
["r"] = 0.9843137860298156,
},
["channel"] = {
["b"] = 0.7764706611633301,
["g"] = 0.4470588564872742,
["r"] = 0,
},
["interrupted"] = {
["r"] = 1,
["g"] = 0.2313725650310516,
["b"] = 0.1882353127002716,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["anchor"] = {
"TOP",
0,
-7.5,
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
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
["kind"] = "cast",
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["layer"] = 4,
["scale"] = 0.9,
["anchor"] = {
"BOTTOM",
0,
12.5,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["scale"] = 0.46,
["anchor"] = {
"TOPLEFT",
-68,
-11,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["layer"] = 3,
["scale"] = 1,
["anchor"] = {
"BOTTOM",
0,
3.5,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-97,
10,
},
["kind"] = "castIcon",
["scale"] = 2.3,
["layer"] = 2,
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"percentage",
},
["align"] = "CENTER",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
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
["showInterrupted"] = true,
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-59,
-12.5,
},
["kind"] = "castSpellName",
["scale"] = 0.7,
["align"] = "LEFT",
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
62.5,
-12.5,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 0.7,
["layer"] = 2,
["maxWidth"] = 0.46,
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
62.5,
-12.5,
},
["kind"] = "castInterrupter",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
["Blizzard+ | | Classic"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["b"] = 0.2117647230625153,
["g"] = 0.760784387588501,
["r"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Classic Level",
["width"] = 1,
["height"] = 1,
["anchor"] = {
"RIGHT",
84,
0,
},
["kind"] = "fixed",
["scale"] = 1,
["sliced"] = false,
},
{
["color"] = {
["a"] = 0.2968749105930329,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Striped",
["width"] = 0.97,
["scale"] = 1,
["anchor"] = {
},
["sliced"] = false,
["height"] = 0.72,
["kind"] = "focus",
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.760784387588501,
["b"] = 0.2117647230625153,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
["autoColors"] = {
},
["scale"] = 1,
["anchor"] = {
},
["sliced"] = true,
["height"] = 1,
["kind"] = "automatic",
},
},
["specialBars"] = {
},
["scale"] = 0.8,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["showType"] = false,
["height"] = 1,
["kind"] = "debuffs",
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["showType"] = true,
["direction"] = "LEFT",
["anchor"] = {
"RIGHT",
-68,
0,
},
["layer"] = 1,
["scale"] = 0.9,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["limit"] = 30,
["kind"] = "buffs",
["height"] = 1,
["padding"] = 0.1,
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
{
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["scale"] = 1.3,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["kind"] = "crowdControl",
["height"] = 1,
["padding"] = 0.1,
["anchor"] = {
"LEFT",
91,
0,
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
24.36,
},
["height"] = 3.35,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.1,
},
["click"] = {
["anchor"] = {
"TOP",
0,
20,
},
["height"] = 2.79,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
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
["g"] = 0.760784387588501,
["b"] = 0.2117647230625153,
},
["height"] = 1,
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["r"] = 0.8000000715255737,
["g"] = 0,
["b"] = 0,
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
["transition"] = {
["b"] = 0,
["g"] = 0.6274509803921569,
["r"] = 1,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["instancesOnly"] = false,
["useSafeColor"] = true,
},
{
["colors"] = {
["hostile"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0.7803922295570374,
["g"] = 0.6196078658103943,
["b"] = 0.3686274588108063,
},
["caster"] = {
["r"] = 0,
["g"] = 0.988235354423523,
["b"] = 0.988235354423523,
},
["trivial"] = {
["r"] = 0.5058823823928833,
["g"] = 0.5137255191802979,
["b"] = 0.5137255191802979,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0.196078431372549,
["g"] = 0.1921568627450981,
["r"] = 0.992156862745098,
},
["neutral"] = {
["b"] = 0.06274509803921569,
["g"] = 0.7764705882352941,
["r"] = 0.788235294117647,
},
["friendly"] = {
["b"] = 0.00784313725490196,
["g"] = 0.807843137254902,
["r"] = 0.05490196078431373,
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
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["anchor"] = {
},
["kind"] = "health",
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["scale"] = 1,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0.6666666666666666,
["g"] = 0.6666666666666666,
["b"] = 0.6666666666666666,
},
["height"] = 1,
["asset"] = "Platy: Blizzard Classic",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.4352941513061524,
["g"] = 0.4352941513061524,
["b"] = 0.4352941513061524,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["ready"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
},
["kind"] = "interruptReady",
},
{
["colors"] = {
["cast"] = {
["r"] = 1,
["g"] = 0.4941176772117615,
["b"] = 0.1372549086809158,
},
["channel"] = {
["r"] = 0.03921568766236305,
["g"] = 0.2627451121807098,
["b"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9843137860298156,
["g"] = 0.8980392813682556,
["b"] = 0,
},
["channel"] = {
["r"] = 0,
["g"] = 0.4470588564872742,
["b"] = 0.7764706611633301,
},
["interrupted"] = {
["r"] = 1,
["g"] = 0.2313725650310516,
["b"] = 0.1882353127002716,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
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
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 1,
["b"] = 0.03921568766236305,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["kind"] = "quest",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.9,
["layer"] = 4,
["asset"] = "normal/quest-blizzard",
["anchor"] = {
"BOTTOM",
0,
18.5,
},
},
{
["kind"] = "cannotInterrupt",
["color"] = {
["r"] = 0.392156862745098,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["scale"] = 0.53,
["layer"] = 3,
["asset"] = "normal/blizzard-shield",
["anchor"] = {
"TOPLEFT",
-68,
-10,
},
},
{
["openWorldOnly"] = false,
["scale"] = 1.25,
["kind"] = "elite",
["anchor"] = {
"RIGHT",
92,
0,
},
["layer"] = 3,
["asset"] = "special/blizzard-elite-around",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["kind"] = "raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
20,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.99,
["autoColors"] = {
},
["anchor"] = {
"BOTTOM",
0,
9,
},
["kind"] = "creatureName",
["scale"] = 1,
["align"] = "CENTER",
},
{
["showInterrupted"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0,
["anchor"] = {
"TOP",
0,
-11,
},
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.95,
},
{
["truncate"] = false,
["color"] = {
["r"] = 0.874509871006012,
["g"] = 1,
["b"] = 0,
},
["layer"] = 2,
["maxWidth"] = 0.16,
["autoColors"] = {
{
["colors"] = {
["impossible"] = {
["r"] = 1,
["g"] = 0.1,
["b"] = 0.1,
},
["standard"] = {
["r"] = 0.25,
["g"] = 0.75,
["b"] = 0.25,
},
["verydifficult"] = {
["r"] = 1,
["g"] = 0.5,
["b"] = 0.25,
},
["difficult"] = {
["r"] = 1,
["g"] = 0.82,
["b"] = 0,
},
["trivial"] = {
["r"] = 0.5,
["g"] = 0.5,
["b"] = 0.5,
},
},
["kind"] = "difficulty",
},
},
["showModifiers"] = false,
["anchor"] = {
"RIGHT",
83,
0,
},
["kind"] = "level",
["align"] = "CENTER",
["scale"] = 1,
},
},
},
["Blizzard+ | | -----------------------"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1.2,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
},
["height"] = 0,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 0,
},
["click"] = {
["anchor"] = {
},
["height"] = 0,
["kind"] = "click",
["autoSized"] = true,
["width"] = 0,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "FritzQuadrata",
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
},
["texts"] = {
},
},
},
["instances_name_only_size"] = 2,
["vertical_offset"] = 0,
["cast_interrupted_timeout"] = 0.3,
["style"] = "Blizzard+ | Clean Health",
["apply_cvars"] = true,
["current_skin"] = "blizzard",
["obscured_alpha"] = 0.5,
["global_scale"] = 1,
["designs_enabled"] = {
["pvpInstance"] = false,
["combat"] = false,
["pvpWorld"] = false,
},
["simplified_scale"] = 0.8,
["click_region_scale_y"] = 1,
["aura_filters"] = {
["crowdControl"] = {
["include"] = {
},
["exclude"] = {
},
},
[267] = {
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
},
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["target_scale"] = 1.2,
["show_nameplates"] = {
["friendlyMinion"] = false,
["friendlyMinionTotem"] = true,
["enemyMinionGuardian"] = true,
["friendlyNPC"] = true,
["enemyMinionTotem"] = true,
["friendlyMinionPet"] = true,
["enemyMinionPet"] = true,
["friendlyMinionGuardian"] = true,
["friendlyPlayer"] = true,
["enemyMinor"] = true,
["enemyMinion"] = true,
["enemy"] = true,
},
},
["DEFAULT"] = {
["stack_region_scale_y"] = 2.16,
["obscured_alpha"] = 1,
["migration"] = 9,
["not_in_combat_alpha"] = 1,
["simplified_nameplates"] = {
["minor"] = true,
["minion"] = true,
["instancesNormal"] = true,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["obscured_combat_alpha"] = 0.4,
["blizzard_widget_scale"] = 1.32,
["show_friendly_in_instances_1"] = "always",
["not_target_alpha"] = 0.7,
["style"] = "Luna",
["click_region_scale_x"] = 1,
["designs_enabled"] = {
["pvpInstance"] = true,
["combat"] = false,
["pvpWorld"] = true,
},
["stack_region_scale_x"] = 1,
["design_assignments"] = {
{
["scale"] = 1,
["simplified"] = false,
["criteria"] = {
"cannot-attack",
},
["style"] = "_deer",
},
{
["scale"] = 1,
["simplified"] = true,
["criteria"] = {
"can-attack",
"class-minor",
},
["style"] = "_hare_simplified",
},
{
["scale"] = 1,
["simplified"] = true,
["criteria"] = {
"can-attack",
"minion",
},
["style"] = "_hare_simplified",
},
{
["scale"] = 1,
["simplified"] = true,
["criteria"] = {
"can-attack",
"loc-dungeon",
"class-normal",
},
["style"] = "_hare_simplified",
},
{
["scale"] = 1,
["simplified"] = false,
["criteria"] = {
"can-attack",
},
["style"] = "Luna",
},
},
["mouseover_alpha"] = 1,
["closer_to_screen_edges"] = true,
["cast_scale"] = 1.1,
["aura_filters"] = {
["crowdControl"] = {
["include"] = {
},
["exclude"] = {
},
},
[267] = {
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
},
["nameplate_position"] = "top",
["designs_assigned"] = {
["enemySimplifiedCombat"] = "Simplified",
["enemyPvPPlayer"] = "DarkDevourer",
["enemyCombat"] = "DarkDevourer",
["friendCombat"] = "Friendly",
["friendPvPPlayer"] = "Friendly",
["friend"] = "FriendlyName",
["enemySimplified"] = "Simplified",
["enemy"] = "DarkDevourer",
},
["instances_name_only_size"] = 2,
["simplified_assigned_fallback"] = "Simplified",
["target_scale"] = 1.15,
["cast_alpha"] = 1,
["cast_interrupted_timeout"] = 0.3,
["design_all"] = {
},
["apply_cvars"] = true,
["current_skin"] = "blizzard",
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["sliced"] = true,
["height"] = 1.46,
["kind"] = "target",
["anchor"] = {
},
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["color"] = {
["a"] = 0.5364580154418945,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Midnight Selected",
["width"] = 1.16,
["scale"] = 0.9,
["sliced"] = true,
["height"] = 1.42,
["kind"] = "mouseover",
["anchor"] = {
},
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882351,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 0.1529411822557449,
["g"] = 0.0941176563501358,
["r"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["uninterruptable"] = {
["a"] = 1,
["b"] = 0.7647058823529411,
["g"] = 0.7529411764705882,
["r"] = 0.5137254901960784,
},
},
["kind"] = "uninterruptableCast",
},
},
["sliced"] = true,
["anchor"] = {
"TOP",
0,
-8,
},
["kind"] = "automatic",
["height"] = 0.51,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1.1,
["auras"] = {
{
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["direction"] = "RIGHT",
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["kind"] = "debuffs",
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
["showTooltips"] = true,
["showType"] = false,
["limit"] = 30,
["scale"] = 1,
["height"] = 1,
["padding"] = 0.1,
["layer"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1.17,
["showFractions"] = false,
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
},
},
},
{
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["direction"] = "LEFT",
["showSwipe"] = true,
["padding"] = 0.1,
["scale"] = 1,
["layer"] = 1,
["showCountdown"] = true,
["anchor"] = {
"LEFT",
-94,
0,
},
["showTooltips"] = true,
["showType"] = true,
["limit"] = 30,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["height"] = 1,
["kind"] = "buffs",
["showStealable"] = false,
["texts"] = {
["countdown"] = {
["visible"] = true,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1.17,
["showFractions"] = false,
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
},
},
},
{
["direction"] = "RIGHT",
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["scale"] = 1,
["layer"] = 1,
["showCountdown"] = true,
["padding"] = 0.1,
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["showType"] = false,
["anchor"] = {
"LEFT",
68,
0,
},
["kind"] = "crowdControl",
["showSwipe"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1.17,
["showFractions"] = false,
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
},
},
},
},
["regions"] = {
["click"] = {
["anchor"] = {
"TOP",
0,
7.66,
},
["height"] = 1.51,
["kind"] = "click",
["width"] = 1.01,
["autoSized"] = true,
},
["stack"] = {
["anchor"] = {
"TOP",
0,
10.03,
},
["height"] = 1.82,
["kind"] = "stack",
["width"] = 1.11,
["autoSized"] = true,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "FritzQuadrata",
["slug"] = true,
},
["version"] = 18,
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
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1.09,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Midnight",
["width"] = 1.12,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["tanksOnly"] = false,
["colors"] = {
["transition"] = {
["b"] = 0,
["g"] = 0.6274509803921569,
["r"] = 1,
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
["offtank"] = {
["b"] = 0.7843137254901961,
["g"] = 0.6666666666666666,
["r"] = 0.05882352941176471,
},
},
["useSafeColor"] = true,
["useOffTankColor"] = true,
["kind"] = "threat",
["combatOnly"] = true,
["instancesOnly"] = false,
},
{
["colors"] = {
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
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
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.2865839898586273,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["scale"] = 0.9,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 0.51,
["color"] = {
["a"] = 0.5,
["b"] = 0.3215686274509804,
["g"] = 0.984313725490196,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.5294117647058824,
["g"] = 0.5294117647058824,
["r"] = 0.5294117647058824,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["b"] = 0,
["g"] = 0.7411764705882353,
["r"] = 1,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["b"] = 0.8784313725490196,
["g"] = 0.211764705882353,
["r"] = 0.9882352941176472,
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
["asset"] = "wide/glow",
},
["kind"] = "cast",
["anchor"] = {
"TOP",
0,
-8,
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 0.1764705926179886,
["g"] = 0.1764705926179886,
["b"] = 0.1764705926179886,
},
["applyColor"] = false,
["asset"] = "Platy: Solid White",
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["interruptMarker"] = {
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "none",
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
["scale"] = 0.9,
["anchor"] = {
"TOPLEFT",
-81,
8.5,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["layer"] = 3,
},
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.5,
["anchor"] = {
"TOPLEFT",
-68,
-6.5,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/blizzard-shield",
["layer"] = 3,
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
["scale"] = 0.54,
["layer"] = 2,
["anchor"] = {
"TOPLEFT",
-67,
-15.5,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["openWorldOnly"] = false,
["scale"] = 0.66,
["layer"] = 3,
["anchor"] = {
"LEFT",
-74,
0,
},
["kind"] = "elite",
["asset"] = "special/blizzard-elite-midnight",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["truncate"] = false,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["align"] = "CENTER",
["scale"] = 0.8,
["anchor"] = {
"RIGHT",
60.5,
0,
},
["kind"] = "health",
["significantFigures"] = 0,
["displayTypes"] = {
"percentage",
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
},
{
["showInterrupted"] = true,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0.44,
["anchor"] = {
"TOPLEFT",
-57,
-16,
},
["kind"] = "castSpellName",
["align"] = "LEFT",
["scale"] = 0.7,
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.46,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
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
["DarkDevourer"] = {
["highlights"] = {
{
["scale"] = 0.9,
["layer"] = 0,
["asset"] = "Platy: Feathered",
["width"] = 1.2,
["sliced"] = true,
["height"] = 1.87,
["kind"] = "target",
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0,
["b"] = 0.615686297416687,
},
["anchor"] = {
},
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Feathered",
["width"] = 1.65,
["scale"] = 0.65,
["sliced"] = true,
["height"] = 2.35,
["kind"] = "mouseover",
["anchor"] = {
},
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Animated Dashes Long",
["width"] = 1.03,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882353,
["r"] = 1,
},
["channel"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.2627450980392157,
["r"] = 0.0392156862745098,
},
},
["kind"] = "importantCast",
},
},
["anchor"] = {
"TOP",
0,
-8,
},
["height"] = 0.91,
["kind"] = "animatedBorder",
["borderWidth"] = 1,
["scale"] = 1,
},
},
["specialBars"] = {
{
["useSpecColors"] = true,
["anchor"] = {
0,
-7,
},
["kind"] = "power",
["scale"] = 0.01,
["layer"] = 3,
["asset"] = "Platy: Soft Circle",
["fixedColor"] = {
["b"] = 0,
["g"] = 0.788235294117647,
["r"] = 0.9411764705882353,
},
},
},
["scale"] = 1.05,
["auras"] = {
{
["direction"] = "RIGHT",
["showPandemic"] = true,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"BOTTOMLEFT",
-62,
18.5,
},
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
["showType"] = false,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["scale"] = 1.29,
["height"] = 1,
["kind"] = "debuffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.78,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
},
["showFractions"] = false,
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.61,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
},
},
},
{
["direction"] = "LEFT",
["scale"] = 1.26,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"LEFT",
-91,
0,
},
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["showType"] = true,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["height"] = 1,
["padding"] = 0.1,
["kind"] = "buffs",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
},
["showFractions"] = false,
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
},
},
},
},
["regions"] = {
["click"] = {
["width"] = 1,
["anchor"] = {
"TOP",
0,
17.5,
},
["kind"] = "click",
["height"] = 2.58,
["autoSized"] = true,
},
["stack"] = {
["width"] = 1.1,
["anchor"] = {
"TOP",
0,
21.53,
},
["kind"] = "stack",
["height"] = 3.1,
["autoSized"] = true,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "1",
["slug"] = true,
},
["version"] = 18,
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
["b"] = 0,
["g"] = 0,
["r"] = 0,
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
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["b"] = 0.458823561668396,
["g"] = 0.4235294461250305,
["r"] = 0.9450981020927428,
},
["melee"] = {
["b"] = 0.007843137718737125,
["g"] = 0,
["r"] = 0.9803922176361084,
},
["caster"] = {
["b"] = 0.9764706492424012,
["g"] = 0.8196079134941101,
["r"] = 0.01568627543747425,
},
["trivial"] = {
["b"] = 0.4980392456054688,
["g"] = 0.7764706611633301,
["r"] = 0.9686275124549866,
},
["miniboss"] = {
["b"] = 0.9490196704864502,
["g"] = 0.5490196347236633,
["r"] = 0.6431372761726379,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
["instancesOnly"] = true,
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
["b"] = 0.1137254983186722,
["g"] = 0.1882353127002716,
["r"] = 0.7450980544090271,
},
["transition"] = {
["b"] = 0,
["g"] = 0.6745098233222961,
["r"] = 0.7450980544090271,
},
["offtank"] = {
["b"] = 1,
["g"] = 0.501960813999176,
["r"] = 0.501960813999176,
},
["warning"] = {
["b"] = 0,
["g"] = 0.4352941513061523,
["r"] = 0.8666667342185974,
},
},
["useSafeColor"] = true,
["useOffTankColor"] = true,
["kind"] = "threat",
["tanksOnly"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["neutral"] = {
["b"] = 0,
["g"] = 0.8588235974311829,
["r"] = 0.8980392813682556,
},
["hostile"] = {
["b"] = 0.1137254983186722,
["g"] = 0.1882353127002716,
["r"] = 0.7450980544090271,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.8901961445808411,
["r"] = 0,
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
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["anchor"] = {
},
["background"] = {
["color"] = {
["a"] = 0.6699999999999999,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Black",
},
["kind"] = "health",
["scale"] = 1,
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
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["asset"] = "Platy: Soft",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["b"] = 0.4431372880935669,
["g"] = 0.4470588564872742,
["r"] = 0.4352941513061523,
},
},
["kind"] = "uninterruptableCast",
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
["cast"] = {
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882351,
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
["cast"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["b"] = 0.3019607961177826,
["g"] = 0.3019607961177826,
["r"] = 0.8000000715255737,
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
["anchor"] = {
"TOP",
0,
-8,
},
["foreground"] = {
["asset"] = "Platy: Solid White",
},
["kind"] = "cast",
["background"] = {
["color"] = {
["a"] = 0.5,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Black",
},
["interruptMarker"] = {
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "none",
},
},
},
["markers"] = {
{
["scale"] = 0.9,
["layer"] = 3,
["anchor"] = {
"LEFT",
-72,
0,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["scale"] = 1,
["layer"] = 3,
["anchor"] = {
"BOTTOMRIGHT",
81.5,
10.5,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["square"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-62,
-22,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["scale"] = 1.14,
},
{
["scale"] = 0.5,
["layer"] = 3,
["color"] = {
["r"] = 0.392156862745098,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["kind"] = "cannotInterrupt",
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
["layer"] = 0,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "elite",
["asset"] = "special/blizzard-elite-midnight",
["anchor"] = {
"BOTTOMRIGHT",
65,
8.5,
},
},
{
["scale"] = 0.75,
["layer"] = 0,
["includeElites"] = true,
["anchor"] = {
"BOTTOMRIGHT",
52,
8,
},
["kind"] = "rare",
["asset"] = "normal/blizzard-rare-midnight",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["truncate"] = true,
["scale"] = 1,
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0.7,
["significantFigures"] = 0,
["displayTypes"] = {
"percentage",
},
["align"] = "RIGHT",
["anchor"] = {
"TOPRIGHT",
64,
4,
},
["kind"] = "health",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["showPercentSymbol"] = true,
},
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
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
["align"] = "LEFT",
["scale"] = 1,
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 1,
["anchor"] = {
"TOP",
0,
-11.5,
},
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
},
{
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
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
["scale"] = 1,
["align"] = "CENTER",
["layer"] = 2,
["truncate"] = false,
["anchor"] = {
"TOPRIGHT",
64,
-11.5,
},
["kind"] = "castTimeLeft",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["maxWidth"] = 0,
},
},
},
["FriendlyName"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["click"] = {
["anchor"] = {
"BOTTOM",
},
["width"] = 1.04,
["height"] = 0.7,
["autoSized"] = true,
},
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-1.1,
},
["width"] = 1.14,
["height"] = 0.84,
["autoSized"] = true,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "1",
["slug"] = true,
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["scale"] = 1.03,
["kind"] = "raid",
["anchor"] = {
"BOTTOM",
0,
11.5,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["color"] = {
["r"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["b"] = 0.9686275124549866,
},
["layer"] = 2,
["maxWidth"] = 1.04,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["neutral"] = {
["b"] = 0,
["g"] = 1,
["r"] = 1,
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
"BOTTOM",
0,
0,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["scale"] = 1,
},
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["scale"] = 0.69,
["layer"] = 2,
["maxWidth"] = 0.99,
["npcRole"] = true,
["autoColors"] = {
},
["align"] = "CENTER",
["anchor"] = {
"TOP",
0,
-2,
},
["kind"] = "guild",
["color"] = {
["a"] = 1,
["b"] = 0.07058823853731155,
["g"] = 1,
["r"] = 0.02745098248124123,
},
["playerGuild"] = true,
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
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.22,
["kind"] = "target",
},
{
["color"] = {
["a"] = 1,
["r"] = 0.6941176652908325,
["g"] = 0.3725490272045136,
["b"] = 0.9215686917304992,
},
["layer"] = 0,
["asset"] = "Platy: 7px",
["width"] = 1.03,
["scale"] = 1,
["anchor"] = {
},
["height"] = 1.24,
["sliced"] = true,
["kind"] = "mouseover",
["includeTarget"] = true,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["click"] = {
["anchor"] = {
"TOP",
0,
7.81,
},
["width"] = 1,
["height"] = 2.17,
["autoSized"] = true,
},
["stack"] = {
["anchor"] = {
"TOP",
0,
11.21,
},
["width"] = 1.1,
["height"] = 2.61,
["autoSized"] = true,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "RobotoCondensed-Bold",
["slug"] = true,
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["asset"] = "Platy: Absorb Wide",
},
["animate"] = false,
["scale"] = 1,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
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
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
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
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
},
["instancesOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["tanksOnly"] = false,
["useSafeColor"] = true,
},
{
["colors"] = {
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["anchor"] = {
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["kind"] = "health",
["marker"] = {
["asset"] = "wide/glow",
},
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["height"] = 1,
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["asset"] = "Platy: 7px",
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
["uninterruptable"] = {
["r"] = 0.5137254901960784,
["g"] = 0.7529411764705882,
["b"] = 0.7647058823529411,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.9882352941176471,
["g"] = 0.5490196078431373,
["b"] = 0,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["r"] = 0.9882352941176471,
["g"] = 0.2117647058823529,
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
["marker"] = {
["asset"] = "none",
},
["anchor"] = {
"TOP",
0,
-10.5,
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = false,
["asset"] = "Platy: Fade Bottom",
},
["kind"] = "cast",
["interruptMarker"] = {
["asset"] = "none",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
},
["markers"] = {
{
["scale"] = 1.6,
["kind"] = "raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
18,
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
-76.5,
-10,
},
["layer"] = 3,
["asset"] = "normal/cast-icon",
["scale"] = 1,
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
-62,
-12,
},
["layer"] = 3,
["asset"] = "normal/shield-soft",
["scale"] = 0.75,
},
},
["texts"] = {
{
["displayTypes"] = {
"absolute",
},
["scale"] = 3,
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["significantFigures"] = 0,
["align"] = "CENTER",
["truncate"] = false,
["anchor"] = {
},
["kind"] = "health",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showPercentSymbol"] = true,
},
{
["showInterrupted"] = true,
["truncate"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0,
["colors"] = {
["npc"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
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
},
},
["anchor"] = {
"TOPLEFT",
-45,
-13,
},
["kind"] = "castSpellName",
["align"] = "CENTER",
["scale"] = 1,
},
{
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1,
["kind"] = "castTimeLeft",
["truncate"] = false,
["anchor"] = {
"TOPRIGHT",
65,
-13,
},
["layer"] = 2,
["align"] = "CENTER",
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
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["direction"] = "RIGHT",
["textScale"] = 1,
["kind"] = "crowdControl",
["scale"] = 1.7,
["layer"] = 1,
["showCountdown"] = true,
["anchor"] = {
"BOTTOM",
0,
33.5,
},
["showTooltips"] = true,
["filters"] = {
["fromYou"] = false,
},
["limit"] = 30,
["showSwipe"] = true,
["height"] = 1,
["padding"] = 0.1,
["showType"] = false,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
},
["showFractions"] = false,
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
},
},
},
},
["regions"] = {
["click"] = {
["anchor"] = {
"BOTTOM",
0,
18,
},
["width"] = 0.59,
["height"] = 0.7,
["autoSized"] = true,
},
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
16.9,
},
["width"] = 0.65,
["height"] = 0.84,
["autoSized"] = true,
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["asset"] = "1",
["slug"] = true,
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["anchor"] = {
"BOTTOMLEFT",
-52,
13.5,
},
["layer"] = 3,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "CENTER",
},
},
},
["Luna"] = {
["highlights"] = {
{
["scale"] = 0.88,
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1.030070377479207,
["sliced"] = false,
["anchor"] = {
},
["kind"] = "target",
["height"] = 0.85,
["color"] = {
["a"] = 0.6113439798355103,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
},
{
["scale"] = 1,
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["sliced"] = false,
["anchor"] = {
},
["kind"] = "focus",
["height"] = 1,
["color"] = {
["a"] = 0.7521891593933105,
["b"] = 1,
["g"] = 0.9960784912109376,
["r"] = 0.4196078777313232,
},
},
},
["specialBars"] = {
{
["kind"] = "power",
["useSpecColors"] = true,
["scale"] = 0.6,
["anchor"] = {
"TOP",
0,
-2,
},
["layer"] = 3,
["asset"] = "Platy: Gradient Circle",
["fixedColor"] = {
["b"] = 0,
["g"] = 0.788235294117647,
["r"] = 0.9411764705882353,
},
},
},
["scale"] = 1,
["auras"] = {
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["showType"] = false,
["layer"] = 1,
["showPandemic"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["height"] = 1,
["showTooltips"] = true,
["scale"] = 1,
["limit"] = 30,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["kind"] = "debuffs",
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["layer"] = 1,
["scale"] = 0.9,
["showSwipe"] = true,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showTooltips"] = true,
["showType"] = false,
["limit"] = 30,
["height"] = 1,
["anchor"] = {
"RIGHT",
83,
0,
},
["kind"] = "crowdControl",
["filters"] = {
["fromYou"] = false,
},
},
{
["padding"] = 0.1,
["direction"] = "RIGHT",
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["showFractions"] = false,
["anchor"] = {
},
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
["stacks"] = {
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["visible"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 0.92,
},
},
["anchor"] = {
"RIGHT",
83,
0,
},
["showType"] = true,
["showSwipe"] = true,
["showCountdown"] = true,
["layer"] = 1,
["showTooltips"] = true,
["scale"] = 0.9,
["limit"] = 30,
["filters"] = {
["enrage"] = false,
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["height"] = 1,
["kind"] = "buffs",
["showStealable"] = false,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOMRIGHT",
120.88,
-21.88,
},
["height"] = 3,
["kind"] = "stack",
["autoSized"] = true,
["width"] = 1.91,
},
["click"] = {
["anchor"] = {
"BOTTOMRIGHT",
110,
-17.97,
},
["height"] = 2.5,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.74,
},
},
["font"] = {
["outline"] = false,
["shadow"] = true,
["slug"] = true,
["asset"] = "1",
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 0.8901961445808411,
["r"] = 0.6509804129600525,
},
["asset"] = "Platy: Absorb Narrow",
},
["animate"] = false,
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 1.17,
["color"] = {
["a"] = 1,
["b"] = 0.572549045085907,
["g"] = 0.572549045085907,
["r"] = 0.572549045085907,
},
["asset"] = "Platy: Blizzard Classic",
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
["colors"] = {
["hostile"] = {
["r"] = 0.9137255549430848,
["g"] = 0.615686297416687,
["b"] = 0.3450980484485626,
},
["neutral"] = {
["r"] = 0.9137255549430848,
["g"] = 0.615686297416687,
["b"] = 0.3450980484485626,
},
["friendly"] = {
["r"] = 0.9137255549430848,
["g"] = 0.615686297416687,
["b"] = 0.3450980484485626,
},
},
["kind"] = "quest",
},
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["r"] = 0.3019607961177826,
["g"] = 0.6941176652908325,
["b"] = 0.7529412508010864,
},
["safe"] = {
["r"] = 0.7333333492279053,
["g"] = 0.1843137294054031,
["b"] = 0.1647058874368668,
},
["offtank"] = {
["r"] = 0.4745098352432251,
["g"] = 0.3333333432674408,
["b"] = 0.7843137979507446,
},
["transition"] = {
["r"] = 0.9019608497619628,
["g"] = 0.4627451300621033,
["b"] = 0.1843137294054031,
},
},
["tanksOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["useSafeColor"] = true,
["instancesOnly"] = false,
},
{
["colors"] = {
["hostile"] = {
["r"] = 0.7333333492279053,
["g"] = 0.1843137294054031,
["b"] = 0.1647058874368668,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["friendly"] = {
["r"] = 0.1803921610116959,
["g"] = 0.6745098233222961,
["b"] = 0.2039215862751007,
},
["neutral"] = {
["r"] = 0.9647059440612792,
["g"] = 0.7686275243759155,
["b"] = 0.2588235437870026,
},
},
["kind"] = "reaction",
},
},
["scale"] = 1,
["relativeTo"] = 0,
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.65,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = false,
["asset"] = "Platy: Solid Black",
},
["foreground"] = {
["asset"] = "Platy: Fade Left",
},
},
{
["marker"] = {
["asset"] = "wide/glow",
},
["layer"] = 1,
["border"] = {
["height"] = 0.51,
["color"] = {
["a"] = 0.5,
["b"] = 0.3058823645114899,
["g"] = 0.8784314393997192,
["r"] = 1,
},
["asset"] = "Platy: Blizzard Cast Bar",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["b"] = 0.1529411764705883,
["g"] = 0.09411764705882351,
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
["b"] = 0,
["g"] = 0.7411764705882353,
["r"] = 1,
},
["empowered"] = {
["b"] = 0.4,
["g"] = 0.7764705882352941,
["r"] = 0.0196078431372549,
},
["interrupted"] = {
["r"] = 0.9882352941176472,
["g"] = 0.2117647058823529,
["b"] = 0.8784313725490196,
},
["channel"] = {
["b"] = 0,
["g"] = 0.7411764860153198,
["r"] = 1,
},
},
["kind"] = "cast",
},
},
["scale"] = 1,
["kind"] = "cast",
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["background"] = {
["color"] = {
["a"] = 0.65,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = false,
["asset"] = "Platy: Solid Black",
},
["anchor"] = {
"TOP",
0,
-10,
},
["interruptMarker"] = {
["asset"] = "none",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
},
["markers"] = {
{
["kind"] = "quest",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"LEFT",
-66,
0,
},
["layer"] = 4,
["asset"] = "normal/quest-blizzard",
["scale"] = 1,
},
{
["openWorldOnly"] = false,
["kind"] = "elite",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"LEFT",
-70,
0,
},
["layer"] = 2,
["asset"] = "special/blizzard-elite",
["scale"] = 1,
},
{
["kind"] = "cannotInterrupt",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPLEFT",
-65,
-9,
},
["layer"] = 3,
["asset"] = "normal/blizzard-shield",
["scale"] = 0.5,
},
{
["kind"] = "raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"LEFT",
-81,
0,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["scale"] = 1,
},
{
["anchor"] = {
"LEFT",
-69,
0,
},
["kind"] = "rare",
["includeElites"] = false,
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/blizzard-rare-silver-star",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
},
["texts"] = {
{
["displayTypes"] = {
"absolute",
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0.36,
["significantFigures"] = 0,
["showPercentSymbol"] = true,
["scale"] = 0.9,
["anchor"] = {
"TOPRIGHT",
58,
4,
},
["kind"] = "health",
["align"] = "RIGHT",
["truncate"] = false,
},
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["scale"] = 1.1,
["layer"] = 2,
["maxWidth"] = 1.74,
["autoColors"] = {
},
["anchor"] = {
"BOTTOMRIGHT",
110,
9,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.65,
["anchor"] = {
"TOPLEFT",
-59,
-18,
},
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
},
{
["truncate"] = true,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0.28,
["scale"] = 0.7,
["anchor"] = {
"TOPRIGHT",
62,
-19,
},
["kind"] = "castTarget",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
},
},
},
["global_scale"] = 1.4,
["show_nameplates_only_needed"] = false,
["simplified_scale"] = 0.78,
["click_region_scale_y"] = 1,
["out_of_range_alpha"] = 1,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["vertical_offset"] = 0,
["show_nameplates"] = {
["friendlyMinion"] = false,
["friendlyMinionTotem"] = true,
["enemyMinionGuardian"] = true,
["enemy"] = true,
["friendlyNPC"] = false,
["friendlyMinionPet"] = true,
["enemyMinionPet"] = true,
["friendlyMinionGuardian"] = true,
["friendlyPlayer"] = true,
["enemyMinor"] = true,
["enemyMinion"] = true,
["enemyMinionTotem"] = true,
},
},
["MF"] = {
["stack_region_scale_y"] = 2.05,
["design_all"] = {
},
["migration"] = 9,
["not_in_combat_alpha"] = 1,
["simplified_nameplates"] = {
["minor"] = false,
["minion"] = false,
["instancesNormal"] = false,
},
["stacking_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["obscured_combat_alpha"] = 0.4,
["blizzard_widget_scale"] = 1.2,
["show_friendly_in_instances_1"] = "name_only",
["not_target_alpha"] = 0.28,
["style"] = "MF Platynator",
["click_region_scale_x"] = 1.02,
["cast_alpha"] = 1,
["stack_region_scale_x"] = 1,
["design_assignments"] = {
{
["scale"] = 1,
["simplified"] = false,
["style"] = "MF Friendly",
["criteria"] = {
"cannot-attack",
},
},
{
["scale"] = 1,
["simplified"] = false,
["style"] = "MF Platynator",
["criteria"] = {
"can-attack",
},
},
},
["simplified_assigned_fallback"] = "MF Friendly",
["mouseover_alpha"] = 0.6599999999999999,
["closer_to_screen_edges"] = true,
["show_nameplates_only_needed"] = false,
["cast_scale"] = 1.1,
["instances_name_only_size"] = 2,
["nameplate_position"] = "top",
["designs_assigned"] = {
["enemySimplifiedCombat"] = "_hare_simplified",
["enemyPvPPlayer"] = "MF Platynator",
["enemySimplified"] = "MF Friendly",
["friendCombat"] = "_name-only",
["friendPvPPlayer"] = "_name-only",
["enemyCombat"] = "MF Platynator",
["friend"] = "MF Friendly",
["enemy"] = "MF Platynator",
},
["simplified_scale"] = 0.39,
["target_scale"] = 1.2,
["obscured_alpha"] = 0.4,
["out_of_range_alpha"] = 1,
["cast_interrupted_timeout"] = 0.3,
["apply_cvars"] = true,
["current_skin"] = "blizzard",
["vertical_offset"] = 0,
["designs"] = {
["_custom"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 0.1098039299249649,
["g"] = 0.8862745761871338,
["b"] = 0.9294118285179138,
},
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["sliced"] = false,
["anchor"] = {
"BOTTOM",
0,
-19,
},
["kind"] = "target",
["height"] = 1,
["scale"] = 0.56,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-1.4,
},
["autoSized"] = true,
["height"] = 1.07,
["width"] = 1.14,
},
["click"] = {
["anchor"] = {
"BOTTOM",
},
["autoSized"] = true,
["height"] = 0.89,
["width"] = 1.04,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "RobotoCondensed-Bold",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["anchor"] = {
"BOTTOMLEFT",
-82,
-7,
},
["scale"] = 0.9,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-boss-blizzard",
["layer"] = 3,
},
{
["anchor"] = {
"BOTTOM",
0,
25,
},
["scale"] = 1.45,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 1.04,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["anchor"] = {
"BOTTOM",
0,
0,
},
["kind"] = "creatureName",
["scale"] = 1.27,
["color"] = {
["r"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["b"] = 0.9686275124549866,
},
},
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0.99,
["npcRole"] = true,
["playerGuild"] = true,
["autoColors"] = {
},
["anchor"] = {
"TOP",
0,
-2,
},
["kind"] = "guild",
["scale"] = 0.91,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
},
["Friendlies"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["asset"] = "Platy: Arrow Solid",
["width"] = 1.27,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.36,
["scale"] = 1.57,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.6941176652908325,
["g"] = 0.3725490272045136,
["b"] = 0.9215686917304992,
},
["layer"] = 0,
["asset"] = "Platy: 7px",
["width"] = 1.03,
["scale"] = 1,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "mouseover",
["height"] = 1.2,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 4,
["asset"] = "Platy: Round Bold",
["width"] = 1.32,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.5,
["scale"] = 1.2,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 1,
["asset"] = "Platy: Glow",
["width"] = 0.75,
["sliced"] = false,
["anchor"] = {
},
["kind"] = "target",
["height"] = 0.71,
["scale"] = 1.48,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Animated Dashes Short",
["width"] = 1.49,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.847058892250061,
["b"] = 0.2784313857555389,
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
["borderWidth"] = 3.15,
["anchor"] = {
"TOP",
0,
-18.5,
},
["kind"] = "animatedBorder",
["height"] = 1.07,
["scale"] = 1.02,
},
},
["specialBars"] = {
{
["useSpecColors"] = true,
["layer"] = 6,
["anchor"] = {
"TOP",
0,
-5,
},
["scale"] = 0.79,
["kind"] = "power",
["asset"] = "Platy: Gradient Circle",
["fixedColor"] = {
["r"] = 0.9411764705882352,
["g"] = 0.788235294117647,
["b"] = 0,
},
},
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1.19,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"BOTTOMLEFT",
-100,
15,
},
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showType"] = false,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["showPandemic"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "debuffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
{
["direction"] = "LEFT",
["scale"] = 0.76,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"LEFT",
-96.5,
0,
},
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["showType"] = true,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "buffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
{
["showCountdown"] = true,
["direction"] = "RIGHT",
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["showSwipe"] = true,
["scale"] = 1.38,
["layer"] = 1,
["textScale"] = 1,
["showType"] = false,
["showTooltips"] = true,
["padding"] = 0.1,
["limit"] = 30,
["filters"] = {
["fromYou"] = false,
},
["anchor"] = {
"RIGHT",
157,
0,
},
["kind"] = "crowdControl",
["height"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
19,
},
["autoSized"] = true,
["height"] = 3.84,
["width"] = 1.74,
},
["click"] = {
["anchor"] = {
"TOP",
0,
13.99,
},
["autoSized"] = true,
["height"] = 3.2,
["width"] = 1.58,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "Oswald",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["asset"] = "Platy: Absorb Wide",
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["animate"] = false,
["scale"] = 1.41,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 1.27,
["asset"] = "Platy: Round Medium",
["width"] = 1.12,
},
["autoColors"] = {
{
["tanksOnly"] = false,
["colors"] = {
["transition"] = {
["r"] = 1,
["g"] = 0.6274509803921569,
["b"] = 0,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
},
["instancesOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["combatOnly"] = false,
["useSafeColor"] = false,
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 0.03529411926865578,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0,
["g"] = 0.988235354423523,
["b"] = 0.988235354423523,
},
["caster"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0.8196079134941101,
},
["trivial"] = {
["r"] = 0.5058823823928833,
["g"] = 0.5137255191802979,
["b"] = 0.5137255191802979,
},
["miniboss"] = {
["r"] = 0.6235294342041016,
["g"] = 0,
["b"] = 1,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 0.9254901960784314,
["b"] = 0.2901960784313726,
},
["hostile"] = {
["r"] = 1,
["g"] = 0.388235330581665,
["b"] = 0,
},
["friendly"] = {
["r"] = 0.8784313725490196,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Fade Top",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 0.2745098173618317,
["g"] = 0.2745098173618317,
["b"] = 0.2745098173618317,
},
["applyColor"] = true,
["asset"] = "Platy: Fade Left",
},
["marker"] = {
["asset"] = "wide/glow",
},
},
{
["scale"] = 1,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 1.22,
["asset"] = "Platy: Blizzard Health",
["width"] = 1.5,
},
["autoColors"] = {
{
["colors"] = {
["notReady"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
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
["cast"] = {
["r"] = 1,
["g"] = 0.3921568989753723,
["b"] = 0,
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
["uninterruptable"] = {
["r"] = 0.5098039507865906,
["g"] = 0.5137255191802979,
["b"] = 0.5098039507865906,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.988235354423523,
["g"] = 0.7960785031318665,
["b"] = 0,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["r"] = 0.988235354423523,
["g"] = 0,
["b"] = 0,
},
["channel"] = {
["r"] = 0,
["g"] = 0.4470588564872742,
["b"] = 0.7764706611633301,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["foreground"] = {
["asset"] = "Platy: Fade Left",
},
["anchor"] = {
"TOP",
0,
-17,
},
["kind"] = "cast",
["background"] = {
["color"] = {
["a"] = 0.7031246423721313,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["interruptMarker"] = {
["asset"] = "wide/glow",
["color"] = {
["a"] = 1,
["r"] = 0.1058823615312576,
["g"] = 1,
["b"] = 0,
},
},
},
},
["markers"] = {
{
["anchor"] = {
"TOPRIGHT",
106.5,
-20.5,
},
["scale"] = 0.68,
["color"] = {
["r"] = 0.3921568627450981,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["layer"] = 3,
},
{
["anchor"] = {
"BOTTOMRIGHT",
110.5,
2.5,
},
["scale"] = 1.58,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 6,
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-112.5,
-18,
},
["scale"] = 1.18,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["layer"] = 3,
},
{
["anchor"] = {
"RIGHT",
111.5,
0,
},
["scale"] = 1.33,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["align"] = "LEFT",
["layer"] = 3,
["maxWidth"] = 1.28,
["autoColors"] = {
},
["anchor"] = {
"LEFT",
-95,
0,
},
["kind"] = "creatureName",
["scale"] = 1.22,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["significantFigures"] = 0,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"RIGHT",
95,
0,
},
["kind"] = "health",
["scale"] = 1.06,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["showInterrupted"] = true,
["truncate"] = false,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 1.08,
["colors"] = {
["npc"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
},
["anchor"] = {
"TOPLEFT",
-91,
-21.5,
},
["kind"] = "castSpellName",
["scale"] = 0.99,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.74,
["color"] = {
["a"] = 1,
["r"] = 0.8156863451004028,
["g"] = 0.1098039299249649,
["b"] = 0,
},
["anchor"] = {
"TOPRIGHT",
92,
-21.5,
},
["kind"] = "castInterrupter",
["scale"] = 1.04,
["applyClassColors"] = true,
},
{
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
94,
-35.5,
},
["kind"] = "castTarget",
["scale"] = 1.1,
["applyClassColors"] = true,
},
{
["scale"] = 1.73,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"BOTTOMRIGHT",
116,
13.5,
},
["truncate"] = false,
["align"] = "CENTER",
["kind"] = "quest",
["layer"] = 5,
["maxWidth"] = 0,
},
},
},
["MF Platynator"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.7921569347381592,
["b"] = 0,
},
["layer"] = 0,
["asset"] = "Platy: Arrow Solid",
["width"] = 1.28,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.36,
["scale"] = 1.31,
},
{
["color"] = {
["a"] = 0.5989583730697632,
["r"] = 0.9686275124549866,
["g"] = 0.9960784912109376,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Feathered",
["width"] = 1.14,
["scale"] = 1.2,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "mouseover",
["height"] = 1.04,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.847058892250061,
["b"] = 0,
},
["layer"] = 4,
["asset"] = "Platy: Round Thin",
["width"] = 1.24,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.13,
["scale"] = 1.13,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.7529412508010864,
["b"] = 0,
},
["layer"] = 1,
["asset"] = "Platy: Feathered Holed",
["width"] = 0.8,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.21,
["scale"] = 1.78,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 5,
["asset"] = "Platy: Animated Dashes Short",
["width"] = 1.15,
["autoColors"] = {
{
["colors"] = {
["cast"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.847058892250061,
["b"] = 0.2784313857555389,
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
["borderWidth"] = 2.5,
["anchor"] = {
"TOP",
0,
-6.5,
},
["kind"] = "animatedBorder",
["height"] = 0.79,
["scale"] = 1.2,
},
{
["color"] = {
["a"] = 0.7161455750465393,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["layer"] = 2,
["asset"] = "Platy: Striped",
["width"] = 1.34,
["sliced"] = false,
["anchor"] = {
"LEFT",
-85,
0,
},
["kind"] = "focus",
["height"] = 0.84,
["scale"] = 1,
},
},
["specialBars"] = {
{
["useSpecColors"] = true,
["layer"] = 6,
["anchor"] = {
"TOP",
0,
-1.5,
},
["scale"] = 0.53,
["kind"] = "power",
["asset"] = "Platy: Gradient Circle",
["fixedColor"] = {
["r"] = 0.9411764705882352,
["g"] = 0.788235294117647,
["b"] = 0,
},
},
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1.05,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"BOTTOMLEFT",
-87,
10,
},
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showType"] = false,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["showPandemic"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "debuffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
"TOPRIGHT",
13,
-3.5,
},
["scale"] = 0.57,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"BOTTOMLEFT",
-8.5,
-6,
},
["scale"] = 1.19,
},
},
},
{
["direction"] = "LEFT",
["scale"] = 1.05,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"BOTTOMRIGHT",
86.5,
10,
},
["showStealable"] = true,
["filters"] = {
["enrage"] = false,
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["showType"] = true,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "buffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
{
["showCountdown"] = true,
["direction"] = "RIGHT",
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["showSwipe"] = true,
["scale"] = 1.38,
["layer"] = 1,
["textScale"] = 1,
["showType"] = false,
["showTooltips"] = true,
["padding"] = 0.1,
["limit"] = 30,
["filters"] = {
["fromYou"] = false,
},
["anchor"] = {
"RIGHT",
157,
0,
},
["kind"] = "crowdControl",
["height"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
},
["regions"] = {
["stack"] = {
["autoSized"] = false,
["anchor"] = {
"TOP",
0,
2.13,
},
["kind"] = "stack",
["height"] = 1.97,
["width"] = 1.64,
},
["click"] = {
["anchor"] = {
"TOP",
0,
9.27,
},
["height"] = 1.92,
["kind"] = "click",
["autoSized"] = true,
["width"] = 1.37,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "Expressway",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["asset"] = "Platy: Absorb Wide",
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["animate"] = false,
["scale"] = 0.86,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 1.38,
["asset"] = "Platy: Round Medium",
["width"] = 1.58,
},
["autoColors"] = {
{
["tanksOnly"] = false,
["colors"] = {
["transition"] = {
["r"] = 1,
["g"] = 0.6274509803921569,
["b"] = 0,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
},
["instancesOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["combatOnly"] = true,
["useSafeColor"] = false,
},
{
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 0.9254901960784314,
["b"] = 0.2901960784313726,
},
["hostile"] = {
["r"] = 1,
["g"] = 0.388235330581665,
["b"] = 0,
},
["friendly"] = {
["r"] = 0.8784313725490196,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0.2274509966373444,
["b"] = 1,
},
["melee"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0.9294118285179138,
["b"] = 0.988235354423523,
},
["caster"] = {
["a"] = 1,
["r"] = 0.7372549176216125,
["g"] = 0,
["b"] = 0.6745098233222961,
},
["trivial"] = {
["a"] = 1,
["r"] = 0.4862745404243469,
["g"] = 0.4784314036369324,
["b"] = 0.5098039507865906,
},
["miniboss"] = {
["a"] = 1,
["r"] = 0.4274510145187378,
["g"] = 0,
["b"] = 0.9215686917304992,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
["instancesOnly"] = true,
},
{
["colors"] = {
["execute"] = {
["r"] = 0.8196079134941101,
["g"] = 0.3568627536296845,
["b"] = 0.3725490272045136,
},
["inCombat"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
},
["kind"] = "execute",
},
{
["colors"] = {
},
["kind"] = "classColors",
},
{
["enabled"] = {
["elite"] = true,
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["rare"] = true,
},
["colors"] = {
["elite"] = {
["r"] = 0.3960784673690796,
["g"] = 0,
["b"] = 0.8705883026123047,
},
["boss"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0.125490203499794,
["b"] = 0.7372549176216125,
},
["melee"] = {
["r"] = 0,
["g"] = 0.988235354423523,
["b"] = 0.9137255549430848,
},
["caster"] = {
["r"] = 0.7372549176216125,
["g"] = 0,
["b"] = 0.5921568870544434,
},
["trivial"] = {
["a"] = 1,
["r"] = 0.4117647409439087,
["g"] = 0.3843137621879578,
["b"] = 0.3921568989753723,
},
["rare"] = {
["r"] = 0.4901961088180542,
["g"] = 0.3450980484485626,
["b"] = 0,
},
},
["delves"] = true,
["kind"] = "delveType",
["outsideInstances"] = false,
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
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Fade Top",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.6054688096046448,
["r"] = 0.1176470667123795,
["g"] = 0.1176470667123795,
["b"] = 0.1176470667123795,
},
["applyColor"] = false,
["asset"] = "Platy: Fade Left",
},
["marker"] = {
["asset"] = "wide/glow",
},
},
{
["scale"] = 1,
["layer"] = 5,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 0.81,
["asset"] = "Platy: Blizzard Health",
["width"] = 1.37,
},
["autoColors"] = {
{
["colors"] = {
["notReady"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
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
["cast"] = {
["r"] = 1,
["g"] = 0.3921568989753723,
["b"] = 0,
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
["uninterruptable"] = {
["r"] = 0.5098039507865906,
["g"] = 0.5137255191802979,
["b"] = 0.5098039507865906,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["cast"] = {
["r"] = 0.988235354423523,
["g"] = 0.7960785031318665,
["b"] = 0,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["r"] = 0.988235354423523,
["g"] = 0,
["b"] = 0,
},
["channel"] = {
["r"] = 0,
["g"] = 0.4470588564872742,
["b"] = 0.7764706611633301,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["foreground"] = {
["asset"] = "Platy: Fade Left",
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
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["applyColor"] = true,
["asset"] = "Platy: Solid Grey",
},
["interruptMarker"] = {
["asset"] = "wide/glow",
["color"] = {
["a"] = 1,
["r"] = 0.1058823615312576,
["g"] = 1,
["b"] = 0,
},
},
},
{
["powerTypes"] = {
["rage"] = true,
["mana"] = false,
["energy"] = true,
},
["scale"] = 0.82,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 1,
["asset"] = "Platy: 7px",
["width"] = 1.7,
},
["autoColors"] = {
{
["colors"] = {
["rage"] = {
["r"] = 1,
["g"] = 0.3333333333333333,
["b"] = 0,
},
["mana"] = {
["r"] = 0,
["g"] = 0.6666666666666666,
["b"] = 1,
},
["energy"] = {
["r"] = 1,
["g"] = 0.760784387588501,
["b"] = 0,
},
},
["kind"] = "energy",
},
},
["foreground"] = {
["asset"] = "Platy: Blizzard Cast Bar",
},
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = false,
["asset"] = "Blizzard Raid Bar",
},
["anchor"] = {
"TOPRIGHT",
88,
-8,
},
["kind"] = "energy",
["mobTypes"] = {
["miniboss"] = false,
["boss"] = true,
},
["marker"] = {
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["anchor"] = {
"TOPRIGHT",
99.5,
-10,
},
["scale"] = 0.68,
["color"] = {
["r"] = 0.3921568627450981,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["layer"] = 3,
},
{
["anchor"] = {
"BOTTOM",
0,
-3.5,
},
["scale"] = 1.86,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 6,
},
{
["anchor"] = {
"RIGHT",
133.5,
0,
},
["scale"] = 1.33,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-blizzard",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = false,
["align"] = "LEFT",
["layer"] = 3,
["maxWidth"] = 1.28,
["autoColors"] = {
},
["anchor"] = {
"LEFT",
-85,
0,
},
["kind"] = "creatureName",
["scale"] = 1.06,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["significantFigures"] = 0,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"TOPRIGHT",
85,
4.5,
},
["kind"] = "health",
["scale"] = 0.99,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["showInterrupted"] = true,
["truncate"] = false,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 1.08,
["colors"] = {
["npc"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
},
["anchor"] = {
"TOPLEFT",
-85.5,
-21.5,
},
["kind"] = "castSpellName",
["scale"] = 0.9,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 6,
["maxWidth"] = 0.74,
["color"] = {
["a"] = 1,
["r"] = 0.8156863451004028,
["g"] = 0.1098039299249649,
["b"] = 0,
},
["anchor"] = {
"TOPRIGHT",
85,
-21.5,
},
["kind"] = "castInterrupter",
["scale"] = 0.9,
["applyClassColors"] = true,
},
{
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 6,
["maxWidth"] = 0,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
85,
-10,
},
["kind"] = "castTarget",
["scale"] = 0.9,
["applyClassColors"] = true,
},
{
["scale"] = 1.26,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"BOTTOMRIGHT",
135.5,
11.5,
},
["truncate"] = false,
["align"] = "CENTER",
["kind"] = "quest",
["layer"] = 5,
["maxWidth"] = 0,
},
{
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 4,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["displayTypes"] = {
"percentage",
},
["anchor"] = {
"TOPLEFT",
-85.5,
-9.5,
},
["kind"] = "mythicPlusForces",
["scale"] = 1.06,
["color"] = {
["r"] = 1,
["g"] = 0.847058892250061,
["b"] = 0,
},
},
{
["powerTypes"] = {
["rage"] = true,
["mana"] = false,
["energy"] = true,
},
["align"] = "CENTER",
["layer"] = 3,
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["mobTypes"] = {
["miniboss"] = false,
["boss"] = true,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
9.5,
-10.5,
},
["kind"] = "energy",
["scale"] = 0.94,
["shorten"] = "NONE",
},
},
},
["My name"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 0.1098039299249649,
["g"] = 0.8862745761871338,
["b"] = 0.9294118285179138,
},
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["sliced"] = false,
["anchor"] = {
"BOTTOM",
0,
-19,
},
["kind"] = "target",
["height"] = 1,
["scale"] = 0.56,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-1.4,
},
["autoSized"] = true,
["height"] = 1.07,
["width"] = 1.14,
},
["click"] = {
["anchor"] = {
"BOTTOM",
},
["autoSized"] = true,
["height"] = 0.89,
["width"] = 1.04,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "RobotoCondensed-Bold",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["anchor"] = {
"BOTTOMLEFT",
-82,
-7,
},
["scale"] = 0.9,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "quest",
["asset"] = "normal/quest-boss-blizzard",
["layer"] = 3,
},
{
["anchor"] = {
"BOTTOM",
0,
25,
},
["scale"] = 1.45,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 1.04,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["anchor"] = {
"BOTTOM",
0,
0,
},
["kind"] = "creatureName",
["scale"] = 1.27,
["color"] = {
["r"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["b"] = 0.9686275124549866,
},
},
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 0.99,
["npcRole"] = true,
["playerGuild"] = true,
["autoColors"] = {
},
["anchor"] = {
"TOP",
0,
-2,
},
["kind"] = "guild",
["scale"] = 0.91,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
},
["Friendly"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: Arrow Double",
["width"] = 1.36,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.36,
["scale"] = 1.38,
},
{
["color"] = {
["a"] = 1,
["r"] = 0.6941176652908325,
["g"] = 0.3725490272045136,
["b"] = 0.9215686917304992,
},
["layer"] = 0,
["asset"] = "Platy: 7px",
["width"] = 1.03,
["scale"] = 1,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "mouseover",
["height"] = 1.2,
["includeTarget"] = true,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["asset"] = "Platy: 7px",
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
["sliced"] = true,
["anchor"] = {
"TOP",
0,
-8.5,
},
["kind"] = "automatic",
["height"] = 1.05,
["scale"] = 1,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: 7px",
["width"] = 1.07,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.26,
["scale"] = 1.21,
},
{
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 1,
["asset"] = "Platy: Feathered",
["width"] = 1.21,
["sliced"] = true,
["anchor"] = {
},
["kind"] = "target",
["height"] = 1.84,
["scale"] = 1.15,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "RIGHT",
["scale"] = 1,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
["showType"] = false,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["showPandemic"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "debuffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
{
["direction"] = "LEFT",
["scale"] = 1,
["showSwipe"] = true,
["textScale"] = 1,
["limit"] = 30,
["anchor"] = {
"LEFT",
-98,
0,
},
["showStealable"] = false,
["filters"] = {
["enrage"] = false,
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
["friendlyFromYou"] = true,
},
["showType"] = true,
["layer"] = 1,
["showCountdown"] = true,
["showTooltips"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["height"] = 1,
["kind"] = "buffs",
["padding"] = 0.1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
{
["showCountdown"] = true,
["direction"] = "RIGHT",
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["showSwipe"] = true,
["scale"] = 1,
["layer"] = 1,
["textScale"] = 1,
["showType"] = false,
["showTooltips"] = true,
["padding"] = 0.1,
["limit"] = 30,
["filters"] = {
["fromYou"] = false,
},
["anchor"] = {
"RIGHT",
119,
0,
},
["kind"] = "crowdControl",
["height"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["showFractions"] = false,
["anchor"] = {
},
["scale"] = 1.17,
},
["stacks"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["scale"] = 0.92,
},
},
},
},
["regions"] = {
["stack"] = {
["anchor"] = {
"TOP",
0,
16.01,
},
["autoSized"] = true,
["height"] = 2.91,
["width"] = 1.41,
},
["click"] = {
["anchor"] = {
"TOP",
0,
12.23,
},
["autoSized"] = true,
["height"] = 2.42,
["width"] = 1.28,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "Oswald",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
{
["absorb"] = {
["asset"] = "Platy: Absorb Wide",
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["animate"] = false,
["scale"] = 1.41,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0.1607843190431595,
["g"] = 0.2431372702121735,
["b"] = 0.2274509966373444,
},
["height"] = 1.11,
["asset"] = "Platy: Blizzard Health",
["width"] = 0.91,
},
["autoColors"] = {
{
["tanksOnly"] = false,
["colors"] = {
["transition"] = {
["r"] = 1,
["g"] = 0.6274509803921569,
["b"] = 0,
},
["warning"] = {
["r"] = 0.8,
["g"] = 0,
["b"] = 0,
},
["safe"] = {
["r"] = 0.05882352941176471,
["g"] = 0.5882352941176471,
["b"] = 0.9019607843137256,
},
["offtank"] = {
["r"] = 0.05882352941176471,
["g"] = 0.6666666666666666,
["b"] = 0.7843137254901961,
},
},
["instancesOnly"] = false,
["useOffTankColor"] = true,
["kind"] = "threat",
["combatOnly"] = true,
["useSafeColor"] = false,
},
{
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 0.9254901960784314,
["b"] = 0.2901960784313726,
},
["hostile"] = {
["r"] = 1,
["g"] = 0.4823529720306397,
["b"] = 0.3725490272045136,
},
["friendly"] = {
["r"] = 0.8784313725490196,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "quest",
},
{
["enabled"] = {
["boss"] = true,
["melee"] = true,
["caster"] = true,
["trivial"] = true,
["miniboss"] = true,
},
["colors"] = {
["boss"] = {
["r"] = 0.03529411926865578,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0,
["g"] = 0.988235354423523,
["b"] = 0.988235354423523,
},
["caster"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0.8196079134941101,
},
["trivial"] = {
["r"] = 0.5058823823928833,
["g"] = 0.5137255191802979,
["b"] = 0.5137255191802979,
},
["miniboss"] = {
["r"] = 0.6235294342041016,
["g"] = 0,
["b"] = 1,
},
},
["kind"] = "eliteType",
["applyCasterAlways"] = false,
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
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: Fade Top",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyColor"] = true,
["asset"] = "Platy: Fade Left",
},
["marker"] = {
["asset"] = "wide/glow",
},
},
{
["scale"] = 1,
["layer"] = 2,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0.1607843190431595,
["g"] = 0.2431372702121735,
["b"] = 0.2274509966373444,
},
["height"] = 1,
["asset"] = "Platy: 4px",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.5137254901960784,
["g"] = 0.7529411764705882,
["b"] = 0.7647058823529411,
},
},
["kind"] = "uninterruptableCast",
},
{
["colors"] = {
["notReady"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
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
["cast"] = {
["r"] = 0.988235354423523,
["g"] = 0.5490196347236633,
["b"] = 0,
},
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["interrupted"] = {
["r"] = 0.988235354423523,
["g"] = 0,
["b"] = 0,
},
["channel"] = {
["r"] = 0,
["g"] = 0.4470588564872742,
["b"] = 0.7764706611633301,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["foreground"] = {
["asset"] = "Platy: Fade Bottom",
},
["anchor"] = {
"TOP",
0,
-10,
},
["kind"] = "cast",
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
["anchor"] = {
"TOPLEFT",
-60,
-11.5,
},
["scale"] = 0.5,
["color"] = {
["r"] = 0.3921568627450981,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["layer"] = 3,
},
{
["anchor"] = {
"BOTTOM",
0,
20,
},
["scale"] = 1,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
},
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-78,
-10,
},
["scale"] = 1,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 3,
["maxWidth"] = 0.99,
["autoColors"] = {
},
["anchor"] = {
"LEFT",
-74.5,
0,
},
["kind"] = "creatureName",
["scale"] = 1.03,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = false,
["align"] = "RIGHT",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["significantFigures"] = 0,
["displayTypes"] = {
"absolute",
},
["anchor"] = {
"RIGHT",
74.5,
0,
},
["kind"] = "health",
["scale"] = 0.84,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["showInterrupted"] = true,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 2,
["maxWidth"] = 0.5,
["colors"] = {
["npc"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["tapped"] = {
["r"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["b"] = 0.4313725490196079,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.36,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
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
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.36,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
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
["MF Friendly"] = {
["highlights"] = {
{
["color"] = {
["a"] = 1,
["r"] = 0.9294118285179138,
["g"] = 0.01176470704376698,
["b"] = 0,
},
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1.56,
["sliced"] = false,
["anchor"] = {
"BOTTOM",
0,
-16,
},
["kind"] = "target",
["height"] = 1.13,
["scale"] = 0.56,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
},
["regions"] = {
["stack"] = {
["anchor"] = {
"BOTTOM",
0,
-2.07,
},
["autoSized"] = true,
["height"] = 1.59,
["width"] = 1.14,
},
["click"] = {
["anchor"] = {
"BOTTOM",
},
["autoSized"] = true,
["height"] = 1.32,
["width"] = 1.04,
},
},
["font"] = {
["outline"] = true,
["slug"] = true,
["asset"] = "RobotoCondensed-Bold",
["shadow"] = true,
},
["version"] = 18,
["bars"] = {
},
["markers"] = {
{
["anchor"] = {
"BOTTOM",
0,
25,
},
["scale"] = 1.99,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["layer"] = 3,
},
},
["texts"] = {
{
["showWhenWowDoes"] = true,
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["maxWidth"] = 1.04,
["autoColors"] = {
{
["colors"] = {
},
["kind"] = "classColors",
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
["colors"] = {
["neutral"] = {
["r"] = 1,
["g"] = 1,
["b"] = 0,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["hostile"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
["friendly"] = {
["r"] = 0,
["g"] = 1,
["b"] = 0,
},
},
["kind"] = "reaction",
},
},
["anchor"] = {
"BOTTOM",
0,
0,
},
["kind"] = "creatureName",
["scale"] = 1.88,
["color"] = {
["r"] = 0.9686275124549866,
["g"] = 0.9686275124549866,
["b"] = 0.9686275124549866,
},
},
},
},
},
["designs_enabled"] = {
["pvpWorld"] = false,
["combat"] = false,
["pvpInstance"] = false,
},
["click_region_scale_y"] = 1,
["aura_filters"] = {
[71] = {
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
[103] = {
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
[267] = {
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
[62] = {
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
["crowdControl"] = {
["include"] = {
},
["exclude"] = {
},
},
[0] = {
["buffs"] = {
["include"] = {
},
["exclude"] = {
},
},
["debuffs"] = {
["include"] = {
},
["exclude"] = {
},
},
},
},
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["global_scale"] = 1,
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["enemyMinionGuardian"] = true,
["enemy"] = true,
["friendlyMinionGuardian"] = true,
["friendlyMinionPet"] = true,
["enemyMinionPet"] = true,
["friendlyMinionTotem"] = true,
["friendlyPlayer"] = false,
["enemyMinionTotem"] = true,
["enemyMinion"] = true,
["friendlyNPC"] = false,
},
},
},
}
