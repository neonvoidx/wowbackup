
ForeverAurasSaved = {
["spellNames"] = {
["names"] = {
["Concentration Aura"] = {
19746,
},
["Aspect of the Cheetah"] = {
5118,
},
["Prayer of Spirit"] = {
27681,
},
["Aspect of the Monkey"] = {
13163,
},
["Greater Blessing of Kings"] = {
25898,
},
["Arcane Brilliance"] = {
23028,
},
["Aspect of the Pack"] = {
13159,
},
["Well-Rested"] = {
429959,
},
},
["build"] = "1.60.1:70862",
},
["editor_tab_spaces"] = 4,
["login_squelch_time"] = 10,
["minimap"] = {
["hide"] = true,
},
["historyCutoff"] = 730,
["dbVersion"] = 91,
["editor_theme"] = "Monokai",
["dynamicIconCache"] = {
},
["editor_font_size"] = 12,
["lastArchiveClear"] = 1794156516,
["lastUpgrade"] = 1794156518,
["migrationCutoff"] = 730,
["registered"] = {
},
["totemSpells"] = {
},
["displays"] = {
["Poisons"] = {
["grow"] = "HORIZONTAL",
["controlledChildren"] = {
"MH Poison",
"OH Poison",
},
["borderBackdrop"] = "Blizzard Tooltip",
["xOffset"] = -13.3331298828125,
["yOffset"] = 348.33349609375,
["anchorPoint"] = "CENTER",
["borderColor"] = {
0,
0,
0,
1,
},
["space"] = 5,
["actions"] = {
["start"] = {
},
["init"] = {
},
["finish"] = {
},
},
["triggers"] = {
{
["trigger"] = {
["type"] = "aura2",
["subeventSuffix"] = "_CAST_START",
["auraTracking"] = "readable",
["event"] = "Health",
["subeventPrefix"] = "SPELL",
["spellIds"] = {
},
["names"] = {
},
["unit"] = "player",
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
},
},
},
["columnSpace"] = 1,
["radius"] = 200,
["selfPoint"] = "CENTER",
["align"] = "CENTER",
["stagger"] = 0,
["limit"] = 5,
["subRegions"] = {
},
["borderInset"] = 1,
["borderPixelPerfect"] = true,
["load"] = {
["size"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["class"] = {
["multi"] = {
},
},
["talent"] = {
["multi"] = {
},
},
},
["animation"] = {
["start"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
["finish"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["backdropColor"] = {
1,
1,
1,
0.5,
},
["internalVersion"] = 91,
["animate"] = false,
["rotation"] = 0,
["scale"] = 1,
["centerType"] = "LR",
["border"] = false,
["borderEdge"] = "Square Full White",
["regionType"] = "dynamicgroup",
["borderSize"] = 2,
["sort"] = "none",
["useLimit"] = false,
["gridType"] = "RD",
["constantFactor"] = "RADIUS",
["arcLength"] = 360,
["borderOffset"] = 4,
["gridWidth"] = 5,
["rowSpace"] = 1,
["id"] = "Poisons",
["frameStrata"] = 1,
["alpha"] = 1,
["anchorFrameType"] = "SCREEN",
["uid"] = "dD2yhJ(bn5O",
["config"] = {
},
["stepAngle"] = 15,
["authorOptions"] = {
},
["conditions"] = {
},
["information"] = {
},
["fullCircle"] = true,
},
["OH Poison"] = {
["iconSource"] = 0,
["wagoID"] = "xjrlDXZbI",
["xOffset"] = 0,
["adjustedMax"] = "",
["adjustedMin"] = "",
["yOffset"] = 0,
["anchorPoint"] = "CENTER",
["cooldownSwipe"] = true,
["url"] = "https://wago.io/xjrlDXZbI/3",
["icon"] = true,
["triggers"] = {
{
["trigger"] = {
["type"] = "custom",
["custom_type"] = "status",
["custom_hide"] = "custom",
["subeventPrefix"] = "SPELL",
["event"] = "Status",
["unit"] = "player",
["onUpdateThrottle"] = 0.1,
["custom"] = "function(event)\n\nif type(InCombatLockdown)==\"function\" and InCombatLockdown() then return false end\n\nlocal _,cl=UnitClass(\"player\")\nif cl~=\"ROGUE\" or type(GetWeaponEnchantInfo)~=\"function\" then return false end\nlocal known=IsSpellKnown\nlocal hasSpell=false\nif type(known)==\"function\" then\n for _,id in ipairs({8681,2823,3408,5761}) do\n  local ok,res=true, known(id)\n  if ok and res then hasSpell=true break end\n end\nend\nif not hasSpell then return false end\nlocal ok,mh,_,_,_,oh=true, GetWeaponEnchantInfo()\nif not ok then return false end\nlocal slot=17\nif slot==17 then\n if type(GetInventoryItemID)==\"function\" and not GetInventoryItemID(\"player\",17) then return false end\n return not oh\nend\nif type(GetInventoryItemID)==\"function\" and not GetInventoryItemID(\"player\",16) then return false end\nreturn not mh\n\nend",
["spellIds"] = {
},
["events"] = "PLAYER_ENTERING_WORLD UNIT_INVENTORY_CHANGED PLAYER_EQUIPMENT_CHANGED UNIT_AURA PLAYER_REGEN_ENABLED",
["check"] = "event",
["names"] = {
},
["subeventSuffix"] = "_CAST_START",
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
["custom"] = "function() return true end",
},
},
["activeTriggerMode"] = 1,
},
["internalVersion"] = 91,
["keepAspectRatio"] = true,
["animation"] = {
["start"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["type"] = "preset",
["easeType"] = "none",
["duration_type"] = "seconds",
["preset"] = "alphaPulse",
["easeStrength"] = 3,
},
["finish"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["desaturate"] = false,
["version"] = 3,
["subRegions"] = {
{
["type"] = "subbackground",
},
{
["border_size"] = 1,
["border_alpha"] = 1,
["type"] = "subborder",
["border_color"] = {
0.85,
0.7,
0.3,
1,
},
["border_visible"] = true,
["border_edge"] = "Square Full White",
["border_offset"] = 0,
},
{
["text_shadowXOffset"] = 0,
["text_text"] = "OH P",
["text_shadowColor"] = {
0,
0,
0,
1,
},
["text_selfPoint"] = "AUTO",
["text_automaticWidth"] = "Auto",
["text_fixedWidth"] = 92,
["anchorYOffset"] = -2,
["text_justify"] = "CENTER",
["rotateText"] = "NONE",
["type"] = "subtext",
["text_color"] = {
0.94,
0.94,
0.94,
1,
},
["text_font"] = "1",
["text_shadowYOffset"] = 0,
["text_wordWrap"] = "NoWrap",
["text_fontType"] = "OUTLINE",
["text_alpha"] = 1,
["anchor_point"] = "OUTER_BOTTOM",
["text_fontSize"] = 13,
["anchorXOffset"] = 0,
["text_visible"] = true,
},
},
["height"] = 50,
["load"] = {
["use_combat"] = false,
["loadFlag"] = "anteb0123_class_ROGUE",
["talent"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["class"] = {
["multi"] = {
},
},
["use_loadFlag"] = true,
["size"] = {
["multi"] = {
},
},
},
["useAdjustededMax"] = false,
["width"] = 50,
["cooldownEdge"] = false,
["progressSource"] = {
-1,
"",
},
["color"] = {
1,
1,
1,
1,
},
["cooldown"] = false,
["useAdjustededMin"] = false,
["regionType"] = "icon",
["displayIcon"] = "Interface\\Icons\\Ability_Rogue_DualWeild",
["actions"] = {
["start"] = {
},
["init"] = {
["custom"] = "local stub = LibStub\nif not stub then return end\nlocal ok, media = true, stub(\"LibSharedMedia-3.0\", true)\nif not ok or not media or type(media.Register) ~= \"function\" then return end\nmedia:Register(\"font\", \"Anteb Polestar Inter Medium\", \"Interface\\\\AddOns\\\\ForeverAuras\\\\Media\\\\Fonts\\\\Inter-Medium.ttf\")\nmedia:Register(\"font\", \"Anteb Polestar Inter Semibold\", \"Interface\\\\AddOns\\\\ForeverAuras\\\\Media\\\\Fonts\\\\Inter-SemiBold.ttf\")",
["do_custom"] = true,
},
["finish"] = {
},
},
["preferToUpdate"] = false,
["config"] = {
},
["useCooldownModRate"] = true,
["authorOptions"] = {
},
["zoom"] = 0.12,
["semver"] = "1.0.2",
["tocversion"] = 16001,
["id"] = "OH Poison",
["cooldownTextDisabled"] = true,
["frameStrata"] = 1,
["anchorFrameType"] = "SCREEN",
["alpha"] = 1,
["uid"] = "antebe9a0bd511083",
["inverse"] = false,
["parent"] = "Poisons",
["conditions"] = {
},
["information"] = {
["showNilIsFalse"] = true,
["antebClassGate"] = "native Load Flag: player class ROGUE",
["forceEvents"] = true,
["ignoreOptionsEventErrors"] = true,
},
["selfPoint"] = "CENTER",
},
["MH Poison"] = {
["iconSource"] = 0,
["wagoID"] = "xjrlDXZbI",
["xOffset"] = 0,
["adjustedMax"] = "",
["adjustedMin"] = "",
["yOffset"] = 0,
["anchorPoint"] = "CENTER",
["cooldownSwipe"] = true,
["url"] = "https://wago.io/xjrlDXZbI/3",
["icon"] = true,
["triggers"] = {
{
["trigger"] = {
["type"] = "custom",
["custom_type"] = "status",
["custom_hide"] = "custom",
["subeventPrefix"] = "SPELL",
["event"] = "Status",
["unit"] = "player",
["onUpdateThrottle"] = 0.1,
["custom"] = "function(event)\n\nif type(InCombatLockdown)==\"function\" and InCombatLockdown() then return false end\n\nlocal _,cl=UnitClass(\"player\")\nif cl~=\"ROGUE\" or type(GetWeaponEnchantInfo)~=\"function\" then return false end\nlocal known=IsSpellKnown\nlocal hasSpell=false\nif type(known)==\"function\" then\n for _,id in ipairs({8681,2823,3408,5761}) do\n  local ok,res=true, known(id)\n  if ok and res then hasSpell=true break end\n end\nend\nif not hasSpell then return false end\nlocal ok,mh,_,_,_,oh=true, GetWeaponEnchantInfo()\nif not ok then return false end\nlocal slot=16\nif slot==17 then\n if type(GetInventoryItemID)==\"function\" and not GetInventoryItemID(\"player\",17) then return false end\n return not oh\nend\nif type(GetInventoryItemID)==\"function\" and not GetInventoryItemID(\"player\",16) then return false end\nreturn not mh\n\nend",
["spellIds"] = {
},
["events"] = "PLAYER_ENTERING_WORLD UNIT_INVENTORY_CHANGED PLAYER_EQUIPMENT_CHANGED UNIT_AURA PLAYER_REGEN_ENABLED",
["check"] = "event",
["names"] = {
},
["subeventSuffix"] = "_CAST_START",
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
["custom"] = "function() return true end",
},
},
["activeTriggerMode"] = 1,
},
["internalVersion"] = 91,
["keepAspectRatio"] = true,
["animation"] = {
["start"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["type"] = "preset",
["easeType"] = "none",
["duration_type"] = "seconds",
["preset"] = "alphaPulse",
["easeStrength"] = 3,
},
["finish"] = {
["type"] = "none",
["easeStrength"] = 3,
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["desaturate"] = false,
["version"] = 3,
["subRegions"] = {
{
["type"] = "subbackground",
},
{
["border_size"] = 1,
["border_alpha"] = 1,
["type"] = "subborder",
["border_color"] = {
0.85,
0.7,
0.3,
1,
},
["border_visible"] = true,
["border_edge"] = "Square Full White",
["border_offset"] = 0,
},
{
["text_shadowXOffset"] = 0,
["text_text"] = "MH P",
["text_shadowColor"] = {
0,
0,
0,
1,
},
["text_selfPoint"] = "AUTO",
["text_automaticWidth"] = "Auto",
["text_fixedWidth"] = 92,
["anchorYOffset"] = -2,
["text_justify"] = "CENTER",
["rotateText"] = "NONE",
["type"] = "subtext",
["text_color"] = {
0.94,
0.94,
0.94,
1,
},
["text_font"] = "1",
["text_shadowYOffset"] = 0,
["text_wordWrap"] = "NoWrap",
["text_fontType"] = "OUTLINE",
["text_alpha"] = 1,
["anchor_point"] = "OUTER_BOTTOM",
["text_fontSize"] = 13,
["anchorXOffset"] = 0,
["text_visible"] = true,
},
},
["height"] = 50,
["load"] = {
["use_combat"] = false,
["loadFlag"] = "anteb0123_class_ROGUE",
["talent"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["class"] = {
["multi"] = {
},
},
["use_loadFlag"] = true,
["size"] = {
["multi"] = {
},
},
},
["useAdjustededMax"] = false,
["width"] = 50,
["cooldownEdge"] = false,
["progressSource"] = {
-1,
"",
},
["color"] = {
1,
1,
1,
1,
},
["cooldown"] = false,
["useAdjustededMin"] = false,
["regionType"] = "icon",
["displayIcon"] = "Interface\\Icons\\Ability_Rogue_DualWeild",
["actions"] = {
["start"] = {
},
["init"] = {
["custom"] = "local stub = LibStub\nif not stub then return end\nlocal ok, media = true, stub(\"LibSharedMedia-3.0\", true)\nif not ok or not media or type(media.Register) ~= \"function\" then return end\nmedia:Register(\"font\", \"Anteb Polestar Inter Medium\", \"Interface\\\\AddOns\\\\ForeverAuras\\\\Media\\\\Fonts\\\\Inter-Medium.ttf\")\nmedia:Register(\"font\", \"Anteb Polestar Inter Semibold\", \"Interface\\\\AddOns\\\\ForeverAuras\\\\Media\\\\Fonts\\\\Inter-SemiBold.ttf\")",
["do_custom"] = true,
},
["finish"] = {
},
},
["preferToUpdate"] = false,
["config"] = {
},
["useCooldownModRate"] = true,
["authorOptions"] = {
},
["zoom"] = 0.12,
["semver"] = "1.0.2",
["tocversion"] = 16001,
["id"] = "MH Poison",
["cooldownTextDisabled"] = true,
["frameStrata"] = 1,
["anchorFrameType"] = "SCREEN",
["alpha"] = 1,
["uid"] = "anteb4fcc0e0b6fc5",
["inverse"] = false,
["parent"] = "Poisons",
["conditions"] = {
},
["information"] = {
["showNilIsFalse"] = true,
["antebClassGate"] = "native Load Flag: player class ROGUE",
["forceEvents"] = true,
["ignoreOptionsEventErrors"] = true,
},
["selfPoint"] = "CENTER",
},
},
["totemNames"] = {
},
["features"] = {
},
}
