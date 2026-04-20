
PLATYNATOR_CONFIG = {
["CharacterSpecific"] = {
},
["Version"] = 1,
["Profiles"] = {
["Jaywi"] = {
["stack_region_scale_y"] = 1.2,
["obscured_alpha"] = 0.4,
["not_target_behaviour"] = "none",
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
["show_friendly_in_instances"] = true,
["blizzard_widget_scale"] = 1.2,
["show_friendly_in_instances_1"] = "never",
["stack_applies_to"] = {
["normal"] = true,
["minor"] = false,
["minion"] = false,
},
["not_target_alpha"] = 0.75,
["target_scale"] = 1.19,
["click_region_scale_x"] = 1,
["designs_enabled"] = {
["pvpInstance"] = false,
["combat"] = false,
["pvpWorld"] = false,
},
["stack_region_scale_x"] = 1.2,
["mouseover_alpha"] = 1,
["closer_to_screen_edges"] = false,
["cast_scale"] = 1.2,
["designs_assigned"] = {
["enemySimplifiedCombat"] = "_hare_simplified",
["enemyPvPPlayer"] = "_deer",
["enemyCombat"] = "_deer",
["friendCombat"] = "_name-only",
["friendPvPPlayer"] = "_name-only",
["friend"] = "_name-only",
["enemySimplified"] = "Enemy - Classic Castbar",
["enemy"] = "Enemy - Fill-style Castbar",
},
["cast_alpha"] = 1,
["show_nameplates_only_needed"] = false,
["design_all"] = {
},
["apply_cvars"] = true,
["current_skin"] = "blizzard",
["global_scale"] = 1.2,
["designs"] = {
["_custom"] = {
["highlights"] = {
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "RIGHT",
["layer"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["showType"] = false,
["showSwipe"] = true,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["anchor"] = {
"BOTTOMLEFT",
-63,
25,
},
["limit"] = 30,
["showPandemic"] = true,
["height"] = 1,
["kind"] = "debuffs",
["scale"] = 1,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["direction"] = "LEFT",
["layer"] = 1,
["scale"] = 1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = true,
["limit"] = 30,
["height"] = 1,
["anchor"] = {
"LEFT",
-101.5,
0,
},
["kind"] = "buffs",
["textScale"] = 1,
["filters"] = {
["dispelable"] = false,
["important"] = true,
["defensive"] = false,
},
},
{
["direction"] = "RIGHT",
["layer"] = 1,
["scale"] = 1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 1.17,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.92,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = false,
["limit"] = 30,
["height"] = 1,
["anchor"] = {
"LEFT",
68,
0,
},
["kind"] = "crowdControl",
["textScale"] = 1,
["filters"] = {
["fromYou"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = true,
["slug"] = true,
["asset"] = "GW2_UI",
},
["version"] = 1,
["bars"] = {
{
["absorb"] = {
["color"] = {
["a"] = 1,
["b"] = 0.3333333432674408,
["g"] = 0.8784314393997192,
["r"] = 0.917647123336792,
},
["asset"] = "Platy: GW2",
},
["animate"] = true,
["marker"] = {
["asset"] = "gw2",
},
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 0.4908923506736755,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 1.09,
["asset"] = "Platy: GW2",
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
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "Platy: GW2",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 0.5650312304496765,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyColor"] = false,
["asset"] = "Platy: GW2",
},
["scale"] = 0.9,
},
{
["scale"] = 1,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["height"] = 0.5,
["asset"] = "Platy: Transparent",
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
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
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
["cast"] = {
["r"] = 1,
["g"] = 0.7411764705882353,
["b"] = 0,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "gw2",
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
["asset"] = "Platy: GW2",
},
["foreground"] = {
["asset"] = "Platy: GW2",
},
["interruptMarker"] = {
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["kind"] = "quest",
["scale"] = 0.9,
["anchor"] = {
"TOPLEFT",
-81,
8.5,
},
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["kind"] = "cannotInterrupt",
["scale"] = 0.5,
["anchor"] = {
"TOPLEFT",
-68,
-6.5,
},
["layer"] = 3,
["asset"] = "normal/gw2-shield",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["kind"] = "raid",
["scale"] = 1,
["anchor"] = {
"BOTTOM",
0,
20,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["openWorldOnly"] = false,
["anchor"] = {
"LEFT",
-74,
0,
},
["layer"] = 3,
["scale"] = 0.66,
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
["truncate"] = false,
["align"] = "CENTER",
["layer"] = 2,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0,
["showPercentSymbol"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["significantFigures"] = 0,
["anchor"] = {
},
["kind"] = "health",
["scale"] = 0.8,
["displayTypes"] = {
"absolute",
"percentage",
},
},
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["scale"] = 0.9,
["layer"] = 2,
["maxWidth"] = 0.75,
["autoColors"] = {
},
["anchor"] = {
"BOTTOM",
0,
6.5,
},
["kind"] = "creatureName",
["align"] = "CENTER",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["anchor"] = {
"TOPLEFT",
-58.5,
-8,
},
["align"] = "LEFT",
["kind"] = "castSpellName",
["truncate"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["scale"] = 0.7,
["maxWidth"] = 0.44,
},
{
["truncate"] = true,
["align"] = "RIGHT",
["layer"] = 2,
["maxWidth"] = 0.46,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["anchor"] = {
"TOPRIGHT",
55,
-8,
},
["kind"] = "castTarget",
["scale"] = 0.7,
["applyClassColors"] = true,
},
{
["truncate"] = true,
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["maxWidth"] = 0,
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
["verydifficult"] = {
["r"] = 1,
["g"] = 0.5,
["b"] = 0.25,
},
},
["kind"] = "difficulty",
},
},
["anchor"] = {
"TOPLEFT",
-59.5,
-1.5,
},
["kind"] = "level",
["scale"] = 0.8,
["align"] = "CENTER",
},
},
},
["Enemy - Fill-style Castbar"] = {
["highlights"] = {
{
["scale"] = 1.2,
["layer"] = 3,
["asset"] = "Platy: 4px",
["width"] = 1,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["height"] = 0.75,
},
{
["color"] = {
["a"] = 0.5,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["layer"] = 2,
["asset"] = "Platy: Striped",
["width"] = 1,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = false,
["scale"] = 1.2,
["height"] = 0.8,
},
{
["scale"] = 1,
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1.01,
["color"] = {
["a"] = 0.5,
["b"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["r"] = 0.6666666865348816,
},
["kind"] = "mouseover",
["height"] = 0.92,
["sliced"] = false,
["anchor"] = {
},
["includeTarget"] = true,
},
{
["scale"] = 1.2,
["layer"] = 0,
["asset"] = "Platy: Arrow Solid",
["width"] = 1.3,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["height"] = 1.2,
},
{
["color"] = {
["a"] = 1,
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Arrows In Close",
["width"] = 1.2,
["sliced"] = false,
["anchor"] = {
},
["kind"] = "target",
["height"] = 0.8,
["scale"] = 1,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "LEFT",
["layer"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.93,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.73,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["showType"] = false,
["showSwipe"] = true,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["height"] = 0.75,
["limit"] = 30,
["showPandemic"] = true,
["anchor"] = {
"BOTTOMRIGHT",
76,
17,
},
["kind"] = "debuffs",
["scale"] = 1,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
},
{
["direction"] = "LEFT",
["layer"] = 1,
["scale"] = 1.1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.88,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.69,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = true,
["limit"] = 30,
["anchor"] = {
"LEFT",
-101.5,
0,
},
["height"] = 1,
["kind"] = "buffs",
["textScale"] = 1,
["filters"] = {
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
},
},
{
["direction"] = "RIGHT",
["layer"] = 1,
["scale"] = 1.1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.88,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.69,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = false,
["limit"] = 30,
["anchor"] = {
"RIGHT",
104,
0,
},
["height"] = 1,
["kind"] = "crowdControl",
["textScale"] = 1,
["filters"] = {
["fromYou"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = false,
["slug"] = true,
["asset"] = "Arial Narrow",
},
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
["layer"] = 0,
["border"] = {
["height"] = 0.75,
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["asset"] = "Platy: 2px",
["width"] = 1,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
["warning"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["safe"] = {
["b"] = 1,
["g"] = 0.1960784494876862,
["r"] = 0.7333333492279053,
},
["offtank"] = {
["r"] = 0.3803921937942505,
["g"] = 0.874509871006012,
["b"] = 0.2313725650310516,
},
["transition"] = {
["r"] = 1,
["g"] = 0.9333333969116212,
["b"] = 0.4313725829124451,
},
},
["useSafeColor"] = false,
["kind"] = "threat",
["tanksOnly"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["elite"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["caster"] = {
["r"] = 0,
["g"] = 0.7490196228027344,
["b"] = 1,
},
["trivial"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["rare"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
},
["delves"] = true,
["kind"] = "delveType",
["outsideInstances"] = false,
},
{
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["caster"] = {
["r"] = 0,
["g"] = 0.7490196228027344,
["b"] = 1,
},
["trivial"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
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
["colors"] = {
["rareElite"] = {
["r"] = 0.9372549653053284,
["g"] = 0.7490196228027344,
["b"] = 0.01568627543747425,
},
["rare"] = {
["r"] = 0.9372549653053284,
["g"] = 0.7490196228027344,
["b"] = 0.01568627543747425,
},
},
["kind"] = "rarity",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.3686274588108063,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.6509804129600525,
["r"] = 1,
},
["friendly"] = {
["b"] = 0,
["g"] = 0.6509804129600525,
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
["hostile"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["unfriendly"] = {
["r"] = 1,
["g"] = 0.5058823529411764,
["b"] = 0,
},
["friendly"] = {
["r"] = 0.3803921937942505,
["g"] = 0.874509871006012,
["b"] = 0.2313725650310516,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.9333333969116212,
["b"] = 0.4313725829124451,
},
},
["kind"] = "reaction",
},
},
["relativeTo"] = 0,
["foreground"] = {
["asset"] = "KMT07",
},
["anchor"] = {
},
["kind"] = "health",
["background"] = {
["color"] = {
["a"] = 1,
["r"] = 0.1333333402872086,
["g"] = 0.1529411822557449,
["b"] = 0.1333333402872086,
},
["applyColor"] = false,
["asset"] = "KMT07",
},
["scale"] = 1.2,
},
{
["scale"] = 1.2,
["layer"] = 1,
["border"] = {
["height"] = 0.75,
["color"] = {
["a"] = 1,
["b"] = 0.1333333402872086,
["g"] = 0.1529411822557449,
["r"] = 0.1333333402872086,
},
["asset"] = "Platy: 2px",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.9019608497619628,
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
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
["channel"] = {
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["channel"] = {
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
["interrupted"] = {
["b"] = 0.988235354423523,
["g"] = 0,
["r"] = 0,
},
["cast"] = {
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["kind"] = "cast",
["foreground"] = {
["asset"] = "KMT07",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 0.1333333402872086,
["g"] = 0.1529411822557449,
["r"] = 0.1333333402872086,
},
["applyColor"] = true,
["asset"] = "KMT07",
},
["anchor"] = {
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.3137255012989044,
["b"] = 0.9411765336990356,
},
["asset"] = "wide/glow",
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
"BOTTOMRIGHT",
90,
15,
},
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["scale"] = 1,
},
{
["kind"] = "raid",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["anchor"] = {
"BOTTOM",
0,
-5,
},
["layer"] = 3,
["asset"] = "normal/blizzard-raid",
["scale"] = 1.5,
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 3,
["maxWidth"] = 0.92,
["autoColors"] = {
{
["colors"] = {
["targeted"] = {
["b"] = 0,
["g"] = 0,
["r"] = 1,
},
},
["kind"] = "castTargetsYou",
},
},
["anchor"] = {
"BOTTOMLEFT",
-75,
2,
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
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["scale"] = 1.1,
["layer"] = 5,
["truncate"] = true,
["anchor"] = {
"TOP",
0,
-1.5,
},
["kind"] = "castSpellName",
["align"] = "RIGHT",
["maxWidth"] = 1.2,
},
{
["displayTypes"] = {
"percentage",
},
["scale"] = 1.1,
["layer"] = 3,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0.6,
["showPercentSymbol"] = true,
["truncate"] = false,
["significantFigures"] = 0,
["anchor"] = {
"BOTTOMRIGHT",
74.5,
2,
},
["kind"] = "health",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["align"] = "RIGHT",
},
{
["truncate"] = true,
["scale"] = 1.1,
["layer"] = 6,
["maxWidth"] = 0.5,
["align"] = "LEFT",
["anchor"] = {
"TOPLEFT",
-74.5,
-1.5,
},
["kind"] = "castTarget",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 1.1,
["layer"] = 6,
["maxWidth"] = 0.5,
["align"] = "LEFT",
["anchor"] = {
"TOPLEFT",
-74.5,
-1.5,
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
["Enemy - Classic Castbar"] = {
["highlights"] = {
{
["scale"] = 1.2,
["layer"] = 3,
["asset"] = "Platy: 4px",
["width"] = 1,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
["height"] = 0.75,
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["color"] = {
["a"] = 0.4895829260349274,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["layer"] = 2,
["asset"] = "Platy: Striped",
["width"] = 1.2,
["kind"] = "focus",
["anchor"] = {
},
["sliced"] = false,
["height"] = 0.8,
["scale"] = 1,
},
{
["scale"] = 1,
["layer"] = 0,
["asset"] = "Platy: Glow",
["width"] = 1,
["color"] = {
["a"] = 0.5,
["r"] = 0.6666666865348816,
["g"] = 0.6666666865348816,
["b"] = 0.6666666865348816,
},
["kind"] = "mouseover",
["height"] = 0.85,
["sliced"] = false,
["anchor"] = {
"LEFT",
-103.5,
0,
},
["includeTarget"] = true,
},
{
["scale"] = 1.2,
["layer"] = 0,
["asset"] = "Platy: Arrow Solid",
["width"] = 1.3,
["kind"] = "target",
["anchor"] = {
},
["sliced"] = true,
["height"] = 1.2,
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
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 2,
["asset"] = "Platy: Arrows In Close",
["width"] = 1.2,
["scale"] = 1,
["anchor"] = {
},
["kind"] = "target",
["height"] = 0.8,
["sliced"] = false,
},
},
["specialBars"] = {
},
["scale"] = 1,
["auras"] = {
{
["direction"] = "LEFT",
["layer"] = 1,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.93,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.73,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["showType"] = false,
["showSwipe"] = true,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["textScale"] = 1,
["anchor"] = {
"BOTTOMRIGHT",
76,
16.5,
},
["limit"] = 30,
["showPandemic"] = true,
["height"] = 0.75,
["kind"] = "debuffs",
["scale"] = 1,
["filters"] = {
["important"] = true,
["fromYou"] = true,
},
},
{
["direction"] = "LEFT",
["layer"] = 1,
["scale"] = 1.1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.88,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.69,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = true,
["limit"] = 30,
["anchor"] = {
"LEFT",
-101.5,
0,
},
["height"] = 1,
["kind"] = "buffs",
["textScale"] = 1,
["filters"] = {
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
},
},
{
["direction"] = "RIGHT",
["layer"] = 1,
["scale"] = 1.1,
["showSwipe"] = true,
["showCountdown"] = true,
["texts"] = {
["countdown"] = {
["visible"] = true,
["scale"] = 0.88,
["anchor"] = {
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
["stacks"] = {
["visible"] = true,
["scale"] = 0.69,
["anchor"] = {
"TOPRIGHT",
12,
-1,
},
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = false,
["limit"] = 30,
["anchor"] = {
"RIGHT",
104,
0,
},
["height"] = 1,
["kind"] = "crowdControl",
["textScale"] = 1,
["filters"] = {
["fromYou"] = false,
},
},
},
["font"] = {
["outline"] = true,
["shadow"] = false,
["slug"] = true,
["asset"] = "Arial Narrow",
},
["bars"] = {
{
["relativeTo"] = 0,
["animate"] = false,
["scale"] = 1.2,
["layer"] = 1,
["border"] = {
["color"] = {
["a"] = 1,
["r"] = 0,
["g"] = 0,
["b"] = 0,
},
["height"] = 0.75,
["asset"] = "Platy: 2px",
["width"] = 1,
},
["autoColors"] = {
{
["combatOnly"] = true,
["colors"] = {
["transition"] = {
["r"] = 1,
["g"] = 0.9333333969116212,
["b"] = 0.4313725829124451,
},
["safe"] = {
["r"] = 0.7333333492279053,
["g"] = 0.1960784494876862,
["b"] = 1,
},
["offtank"] = {
["r"] = 0.3803921937942505,
["g"] = 0.874509871006012,
["b"] = 0.2313725650310516,
},
["warning"] = {
["b"] = 0.3098039329051971,
["g"] = 0.2980392277240753,
["r"] = 0.9960784912109376,
},
},
["useSafeColor"] = false,
["kind"] = "threat",
["tanksOnly"] = false,
["instancesOnly"] = false,
},
{
["colors"] = {
["elite"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["caster"] = {
["r"] = 0,
["g"] = 0.7490196228027344,
["b"] = 1,
},
["trivial"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["rare"] = {
["r"] = 0.9372549653053284,
["g"] = 0.7490196228027344,
["b"] = 0.01568627543747425,
},
},
["delves"] = true,
["kind"] = "delveType",
["outsideInstances"] = false,
},
{
["colors"] = {
["boss"] = {
["r"] = 1,
["g"] = 0,
["b"] = 1,
},
["melee"] = {
["b"] = 0.3098039329051971,
["g"] = 0.2980392277240753,
["r"] = 0.9960784912109376,
},
["caster"] = {
["r"] = 0,
["g"] = 0.7490196228027344,
["b"] = 1,
},
["trivial"] = {
["b"] = 0.3098039329051971,
["g"] = 0.2980392277240753,
["r"] = 0.9960784912109376,
},
["miniboss"] = {
["r"] = 0.5764706134796143,
["g"] = 0.4392157196998596,
["b"] = 0.8588235974311829,
},
},
["kind"] = "eliteType",
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
["colors"] = {
["rareElite"] = {
["r"] = 0.9372549653053284,
["g"] = 0.7490196228027344,
["b"] = 0.01568627543747425,
},
["rare"] = {
["r"] = 0.9372549653053284,
["g"] = 0.7490196228027344,
["b"] = 0.01568627543747425,
},
},
["kind"] = "rarity",
},
{
["colors"] = {
["hostile"] = {
["b"] = 0,
["g"] = 0.3686274588108063,
["r"] = 1,
},
["neutral"] = {
["b"] = 0,
["g"] = 0.6509804129600525,
["r"] = 1,
},
["friendly"] = {
["r"] = 1,
["g"] = 0.6509804129600525,
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
["hostile"] = {
["r"] = 0.9960784912109376,
["g"] = 0.2980392277240753,
["b"] = 0.3098039329051971,
},
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
},
["friendly"] = {
["r"] = 0.3803921937942505,
["g"] = 0.874509871006012,
["b"] = 0.2313725650310516,
},
["neutral"] = {
["r"] = 1,
["g"] = 0.9333333969116212,
["b"] = 0.4313725829124451,
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
["anchor"] = {
},
["foreground"] = {
["asset"] = "KMT07",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 0.1333333402872086,
["g"] = 0.1529411822557449,
["r"] = 0.1333333402872086,
},
["applyColor"] = false,
["asset"] = "KMT07",
},
["kind"] = "health",
["marker"] = {
["asset"] = "none",
},
},
{
["scale"] = 1.2,
["layer"] = 3,
["border"] = {
["color"] = {
["a"] = 1,
["b"] = 0,
["g"] = 0,
["r"] = 0,
},
["height"] = 0.75,
["asset"] = "Platy: 2px",
["width"] = 1,
},
["autoColors"] = {
{
["colors"] = {
["uninterruptable"] = {
["r"] = 0.7490196228027344,
["g"] = 0.7490196228027344,
["b"] = 0.9019608497619628,
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
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
["channel"] = {
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
},
["kind"] = "importantCast",
},
{
["colors"] = {
["empowered"] = {
["r"] = 0.0196078431372549,
["g"] = 0.7764705882352941,
["b"] = 0.4,
},
["channel"] = {
["b"] = 0,
["g"] = 0.7490196228027344,
["r"] = 1,
},
["interrupted"] = {
["b"] = 0.988235354423523,
["g"] = 0,
["r"] = 0,
},
["cast"] = {
["r"] = 1,
["g"] = 0.7490196228027344,
["b"] = 0,
},
},
["kind"] = "cast",
},
},
["marker"] = {
["asset"] = "wide/glow",
},
["background"] = {
["color"] = {
["a"] = 1,
["b"] = 0.1333333402872086,
["g"] = 0.1529411822557449,
["r"] = 0.1333333402872086,
},
["applyColor"] = true,
["asset"] = "KMT07",
},
["anchor"] = {
"TOP",
0,
-3,
},
["kind"] = "cast",
["foreground"] = {
["asset"] = "KMT07",
},
["interruptMarker"] = {
["color"] = {
["a"] = 1,
["r"] = 1,
["g"] = 0.3137255012989044,
["b"] = 0.9411765336990356,
},
["asset"] = "wide/glow",
},
},
},
["markers"] = {
{
["kind"] = "quest",
["anchor"] = {
"BOTTOMRIGHT",
90,
15,
},
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/quest-blizzard",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["kind"] = "raid",
["anchor"] = {
"BOTTOM",
0,
-5,
},
["scale"] = 1.5,
["layer"] = 4,
["asset"] = "normal/blizzard-raid",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
},
["texts"] = {
{
["showWhenWowDoes"] = false,
["truncate"] = true,
["align"] = "LEFT",
["layer"] = 4,
["maxWidth"] = 1,
["autoColors"] = {
{
["colors"] = {
["targeted"] = {
["r"] = 1,
["g"] = 0,
["b"] = 0,
},
},
["kind"] = "castTargetsYou",
},
},
["anchor"] = {
"BOTTOMLEFT",
-75,
2,
},
["kind"] = "creatureName",
["scale"] = 1.1,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["align"] = "RIGHT",
["anchor"] = {
"TOP",
0,
-4.5,
},
["layer"] = 5,
["truncate"] = true,
["scale"] = 1.1,
["kind"] = "castSpellName",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["maxWidth"] = 1.2,
},
{
["truncate"] = false,
["align"] = "RIGHT",
["layer"] = 4,
["formatMultiple"] = "%s (%s)",
["maxWidth"] = 0.6,
["showPercentSymbol"] = true,
["displayTypes"] = {
"percentage",
},
["significantFigures"] = 0,
["anchor"] = {
"BOTTOMRIGHT",
74.5,
2,
},
["kind"] = "health",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 1.1,
},
{
["truncate"] = true,
["scale"] = 1.1,
["layer"] = 5,
["maxWidth"] = 0.5,
["align"] = "LEFT",
["anchor"] = {
"TOPLEFT",
-74,
-4.5,
},
["kind"] = "castTarget",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["applyClassColors"] = true,
},
{
["truncate"] = true,
["scale"] = 1.1,
["layer"] = 4,
["maxWidth"] = 0.5,
["align"] = "LEFT",
["anchor"] = {
"TOPLEFT",
-74,
-4.5,
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
},
["target_behaviour"] = "enlarge",
["style"] = "Enemy - Fill-style Castbar",
["click_region_scale_y"] = 1,
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["simplified_scale"] = 0.9,
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["friendlyPlayer"] = false,
["enemy"] = true,
["enemyMinion"] = true,
["friendlyNPC"] = false,
},
},
["DEFAULT"] = {
["stack_region_scale_y"] = 2.16,
["designs_enabled"] = {
["pvpInstance"] = true,
["combat"] = false,
["pvpWorld"] = true,
},
["design_all"] = {
},
["simplified_scale"] = 0.78,
["mouseover_alpha"] = 1,
["closer_to_screen_edges"] = true,
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
["obscured_combat_alpha"] = 0.4,
["stack_region_scale_x"] = 1,
["click_region_scale_y"] = 1,
["blizzard_widget_scale"] = 1.2,
["show_friendly_in_instances_1"] = "always",
["style"] = "DarkDevourer",
["designs"] = {
["_custom"] = {
["highlights"] = {
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
},
["markers"] = {
{
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["scale"] = 0.9,
["kind"] = "quest",
["asset"] = "normal/quest-boss-blizzard",
["anchor"] = {
"BOTTOMLEFT",
-82,
-7,
},
},
{
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["scale"] = 1.45,
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOM",
0,
25,
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
["b"] = 0.4313725490196079,
["g"] = 0.4313725490196079,
["r"] = 0.4313725490196079,
},
},
["kind"] = "tapped",
},
{
["colors"] = {
["unfriendly"] = {
["b"] = 0,
["g"] = 0.5058823529411764,
["r"] = 1,
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
["neutral"] = {
["r"] = 1,
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
["scale"] = 1,
["align"] = "CENTER",
},
{
["showWhenWowDoes"] = true,
["playerGuild"] = true,
["scale"] = 0.63,
["layer"] = 2,
["maxWidth"] = 0.99,
["npcRole"] = true,
["truncate"] = false,
["anchor"] = {
"TOP",
0,
-2,
},
["kind"] = "guild",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "CENTER",
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
["filled"] = "normal/soft-full",
["layer"] = 3,
["scale"] = 0.01,
["blank"] = "normal/soft-faded",
["kind"] = "power",
["anchor"] = {
0,
-7,
},
},
},
["scale"] = 1.05,
["auras"] = {
{
["direction"] = "RIGHT",
["textScale"] = 1,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["scale"] = 1.29,
["layer"] = 1,
["showCountdown"] = true,
["showPandemic"] = true,
["showType"] = false,
["height"] = 1,
["limit"] = 30,
["filters"] = {
["fromYou"] = true,
["important"] = true,
},
["anchor"] = {
"BOTTOMLEFT",
-62,
18.5,
},
["kind"] = "debuffs",
["showSwipe"] = true,
["texts"] = {
["countdown"] = {
["anchor"] = {
},
["scale"] = 0.78,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
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
["textScale"] = 1,
["scale"] = 1.26,
["layer"] = 1,
["showCountdown"] = true,
["sorting"] = {
["kind"] = "duration",
["reversed"] = false,
},
["showType"] = true,
["height"] = 1,
["limit"] = 30,
["filters"] = {
["dispelable"] = true,
["important"] = true,
["defensive"] = false,
},
["anchor"] = {
"LEFT",
-91,
0,
},
["kind"] = "buffs",
["showSwipe"] = true,
["texts"] = {
["countdown"] = {
["anchor"] = {
},
["scale"] = 1.17,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
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
["kind"] = "eliteType",
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
["anchor"] = {
"LEFT",
-72,
0,
},
["layer"] = 3,
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
["anchor"] = {
"BOTTOMRIGHT",
81.5,
10.5,
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
{
["square"] = false,
["anchor"] = {
"TOPLEFT",
-62,
-22,
},
["layer"] = 3,
["scale"] = 1.14,
["kind"] = "castIcon",
["asset"] = "normal/cast-icon",
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
},
{
["color"] = {
["r"] = 0.392156862745098,
["g"] = 0.4823529411764706,
["b"] = 0.4980392156862745,
},
["layer"] = 3,
["anchor"] = {
"TOPLEFT",
-63.5,
-10.5,
},
["kind"] = "cannotInterrupt",
["asset"] = "normal/shield-soft",
["scale"] = 0.5,
},
{
["openWorldOnly"] = false,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 0,
["anchor"] = {
"BOTTOMRIGHT",
65,
8.5,
},
["kind"] = "elite",
["asset"] = "special/blizzard-elite-midnight",
["scale"] = 0.81,
},
{
["anchor"] = {
"BOTTOMRIGHT",
52,
8,
},
["layer"] = 0,
["includeElites"] = true,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "rare",
["asset"] = "normal/blizzard-rare-midnight",
["scale"] = 0.75,
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["scale"] = 0.8,
["layer"] = 2,
["truncate"] = true,
["anchor"] = {
"TOP",
0,
-11.5,
},
["kind"] = "castSpellName",
["align"] = "CENTER",
["maxWidth"] = 1,
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
["anchor"] = {
"BOTTOM",
0,
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
["scale"] = 1.03,
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["kind"] = "raid",
["anchor"] = {
"BOTTOM",
0,
18,
},
["layer"] = 3,
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
["kind"] = "castIcon",
["scale"] = 1,
["layer"] = 3,
["asset"] = "normal/cast-icon",
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
},
{
["anchor"] = {
"TOPLEFT",
-62,
-12,
},
["kind"] = "cannotInterrupt",
["scale"] = 0.75,
["layer"] = 3,
["asset"] = "normal/shield-soft",
["color"] = {
["b"] = 0.4980392156862745,
["g"] = 0.4823529411764706,
["r"] = 0.392156862745098,
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
["direction"] = "RIGHT",
["textScale"] = 1,
["scale"] = 1.7,
["layer"] = 1,
["showCountdown"] = true,
["sorting"] = {
["reversed"] = false,
["kind"] = "duration",
},
["anchor"] = {
"BOTTOM",
0,
33.5,
},
["showType"] = false,
["limit"] = 30,
["filters"] = {
["fromYou"] = false,
},
["height"] = 1,
["kind"] = "crowdControl",
["showSwipe"] = true,
["texts"] = {
["countdown"] = {
["anchor"] = {
},
["scale"] = 1.17,
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["visible"] = true,
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
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["layer"] = 3,
["scale"] = 1,
["kind"] = "raid",
["asset"] = "normal/blizzard-raid",
["anchor"] = {
"BOTTOMLEFT",
-52,
13.5,
},
},
{
["color"] = {
["b"] = 1,
["g"] = 1,
["r"] = 1,
},
["kind"] = "class",
["anchor"] = {
"BOTTOM",
0,
34.5,
},
["layer"] = 1,
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
["color"] = {
["r"] = 1,
["g"] = 1,
["b"] = 1,
},
["align"] = "CENTER",
},
},
},
},
["apply_cvars"] = true,
["not_target_alpha"] = 0.7,
["target_scale"] = 1.15,
["global_scale"] = 1.4,
["current_skin"] = "blizzard",
["show_nameplates_only_needed"] = false,
["click_region_scale_x"] = 1,
["show_nameplates"] = {
["friendlyMinion"] = false,
["enemyMinor"] = true,
["friendlyPlayer"] = true,
["enemy"] = true,
["enemyMinion"] = true,
["friendlyNPC"] = false,
},
["clickable_nameplates"] = {
["friend"] = false,
["enemy"] = true,
},
["obscured_alpha"] = 1,
["cast_alpha"] = 1,
},
},
}
